-- Add content hash and file size for duplicate detection
ALTER TABLE documents ADD COLUMN IF NOT EXISTS content_hash TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS file_size BIGINT;

-- Index for fast duplicate lookups by hash
CREATE INDEX IF NOT EXISTS idx_documents_content_hash ON documents(content_hash) WHERE content_hash IS NOT NULL AND deleted_at IS NULL;
