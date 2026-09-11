-- Local version: image_url as plain TEXT without CHECK constraint
-- (local paths like /uploads/tractors/... don't match ^https?://)

ALTER TABLE tractor
ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE implement
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- NOTE: CHECK constraints on image_url (tractor_image_url_valid, implement_image_url_valid)
-- are intentionally NOT added in the local version because local paths
-- (e.g. /uploads/tractors/abc.jpg) don't match the ^https?:// pattern.
