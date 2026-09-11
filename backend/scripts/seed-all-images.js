import { pool } from '../src/config/db.js';
import cloudinary from '../src/config/cloudinary.js';
import https from 'https';
import http from 'http';

const TRACTOR_SEARCH = {
  'John Deere': 'john-deere-tractor',
  'New Holland': 'new-holland-tractor',
  'Massey Ferguson': 'massey-ferguson-tractor',
  'Kubota': 'kubota-tractor',
  'Caterpillar': 'caterpillar-tractor',
  'Ford': 'ford-tractor',
  'Case IH': 'case-ih-tractor',
  'Fiat': 'fiat-tractor',
  'Belarus': 'belarus-tractor',
  'default': 'agricultural-tractor',
};

const IMPLEMENT_SEARCH = {
  'Arado': 'plow-farming',
  'Rastra': 'harrow-farming',
  'Sembradora': 'seeder-agriculture',
  'Cosechadora': 'harvester-agriculture',
  'Pulverizadora': 'sprayer-agriculture',
  'Remolque': 'trailer-agriculture',
  'default': 'farm-equipment',
};

function getTractorQuery(brand) {
  return TRACTOR_SEARCH[brand] || TRACTOR_SEARCH['default'];
}

function getImplementQuery(type) {
  return IMPLEMENT_SEARCH[type] || IMPLEMENT_SEARCH['default'];
}

function fetchImage(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    client.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let redirectUrl = res.headers.location;
        if (!redirectUrl.startsWith('http')) {
           const baseUrl = new URL(url);
           redirectUrl = `${baseUrl.protocol}//${baseUrl.host}${redirectUrl}`;
        }
        return fetchImage(redirectUrl).then(resolve).catch(reject);
      }
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    }).on('error', reject);
  });
}

function uploadToCloudinary(buffer, folder, publicId) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        public_id: publicId,
        overwrite: true,
        transformation: [{ width: 800, height: 600, crop: 'limit' }],
      },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      }
    );
    stream.end(buffer);
  });
}

async function processItems() {
  if (!cloudinary) {
    console.error('Cloudinary not configured. Set CLOUD_NAME, CLOUD_KEY, CLOUD_SECRET in .env');
    process.exit(1);
  }

  let tractorsUpdated = 0;
  let implementsUpdated = 0;
  let failures = 0;

  try {
    // TRACTORS
    const tractorResult = await pool.query('SELECT tractor_id, name, brand, model, image_url FROM tractor ORDER BY tractor_id');
    const tractors = tractorResult.rows;
    console.log(`Found ${tractors.length} tractors\n`);

    for (const tractor of tractors) {
      if (tractor.image_url && !tractor.image_url.includes('mock_')) {
        console.log(`SKIP Tractor ${tractor.brand} ${tractor.model} — already has image`);
        continue;
      }

      const query = getTractorQuery(tractor.brand);
      let imageUrl = `https://source.unsplash.com/800x600/?${encodeURIComponent(query)}`;

      try {
        console.log(`Downloading image for Tractor ${tractor.brand} ${tractor.model}...`);
        let buffer = await fetchImage(imageUrl).catch(() => Buffer.from([]));
        
        if (buffer.length < 1000) {
          console.log(`  WARN: Unsplash failed, trying loremflickr...`);
          imageUrl = `https://loremflickr.com/800/600/${encodeURIComponent(query)}`;
          buffer = await fetchImage(imageUrl);
        }
        
        if (buffer.length < 1000) {
          console.log(`  WARN: Image too small (${buffer.length} bytes), skipping`);
          failures++;
          continue;
        }

        const publicId = `tractor-${tractor.tractor_id}-${tractor.brand.toLowerCase().replace(/\s+/g, '-')}`;
        const uploaded = await uploadToCloudinary(buffer, 'maqagr/tractors', publicId);

        await pool.query('UPDATE tractor SET image_url = $1 WHERE tractor_id = $2', [uploaded.secure_url, tractor.tractor_id]);

        console.log(`  OK ${uploaded.secure_url}`);
        tractorsUpdated++;
      } catch (err) {
        console.error(`  FAIL Tractor ${tractor.brand} ${tractor.model}: ${err.message}`);
        failures++;
      }
    }

    // IMPLEMENTS
    const implementResult = await pool.query('SELECT implement_id, implement_name, brand, implement_type, image_url FROM implement ORDER BY implement_id');
    const implementList = implementResult.rows;
    console.log(`\\nFound ${implementList.length} implements\\n`);

    for (const imp of implementList) {
      if (imp.image_url && !imp.image_url.includes('mock_')) {
        console.log(`SKIP Implement ${imp.brand} ${imp.implement_name} — already has image`);
        continue;
      }

      const query = getImplementQuery(imp.implement_type);
      let imageUrl = `https://source.unsplash.com/800x600/?${encodeURIComponent(query)}`;

      try {
        console.log(`Downloading image for Implement ${imp.brand} ${imp.implement_name}...`);
        let buffer = await fetchImage(imageUrl).catch(() => Buffer.from([]));
        
        if (buffer.length < 1000) {
          console.log(`  WARN: Unsplash failed, trying loremflickr...`);
          imageUrl = `https://loremflickr.com/800/600/${encodeURIComponent(query)}`;
          buffer = await fetchImage(imageUrl);
        }
        
        if (buffer.length < 1000) {
          console.log(`  WARN: Image too small (${buffer.length} bytes), skipping`);
          failures++;
          continue;
        }

        const safeBrand = (imp.brand || 'unknown').toLowerCase().replace(/\s+/g, '-');
        const publicId = `implement-${imp.implement_id}-${safeBrand}`;
        const uploaded = await uploadToCloudinary(buffer, 'maqagr/implements', publicId);

        await pool.query('UPDATE implement SET image_url = $1 WHERE implement_id = $2', [uploaded.secure_url, imp.implement_id]);

        console.log(`  OK ${uploaded.secure_url}`);
        implementsUpdated++;
      } catch (err) {
        console.error(`  FAIL Implement ${imp.brand} ${imp.implement_name}: ${err.message}`);
        failures++;
      }
    }

  } catch (err) {
    console.error('Fatal error:', err);
  } finally {
    await pool.end();
  }

  console.log('\\nDone!');
  console.log(`Tractors updated: ${tractorsUpdated}`);
  console.log(`Implements updated: ${implementsUpdated}`);
  console.log(`Failures: ${failures}`);
}

processItems();
