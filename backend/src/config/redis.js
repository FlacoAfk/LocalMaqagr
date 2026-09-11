import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config({ quiet: true });

// Support REDIS_ENABLED flag — if not 'true', skip Redis entirely
const REDIS_ENABLED = process.env.REDIS_ENABLED === 'true';

let redisClient;

if (!REDIS_ENABLED) {
  // Redis disabled — export null client and log skip
  console.log('[REDIS] Redis is disabled (REDIS_ENABLED != "true"). Cache features will be unavailable.');
  redisClient = null;
} else if (process.env.REDIS_URL) {
  // Parse URL manually to avoid ioredis URL parsing issues
  // Format: rediss://default:PASSWORD@HOST:PORT
  const url = new URL(process.env.REDIS_URL);
  const redisConfig = {
    host: url.hostname,
    port: parseInt(url.port, 10) || 6379,
    password: url.password,
    tls: url.protocol === 'rediss:',
    lazyConnect: true,
    retryStrategy(times) {
      const delay = Math.min(times * 50, 2000);
      return delay;
    },
  };
  redisClient = new Redis(redisConfig);
} else {
  // Host/port/password connection (local development, Memorystore)
  const redisConfig = {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    lazyConnect: true,
    retryStrategy(times) {
      const delay = Math.min(times * 50, 2000);
      return delay;
    },
  };
  redisClient = new Redis(redisConfig);
}

if (redisClient) {
  redisClient.on('connect', () => {
    console.log('Redis client connected');
  });

  redisClient.on('error', (err) => {
    // Suppress error logging during tests if connection is expected to fail or be mocked
    if (process.env.NODE_ENV !== 'test') {
      console.error('Redis client error (Connection may be unavailable):', err.message);
    }
  });
}

export const connectRedis = async () => {
  if (!redisClient) return; // Skip if disabled
  if (redisClient.status === 'ready') return;
  try {
    await redisClient.connect();
    console.log('Redis connection verified');
  } catch (error) {
    console.warn('Failed to connect to Redis initially. The app will continue, but cache features will be unavailable.', error.message);
  }
};

export const disconnectRedis = async () => {
  if (redisClient) {
    try {
      await redisClient.quit();
    } catch(e) {}
    console.log('Redis client disconnected');
  }
};

export default redisClient;
