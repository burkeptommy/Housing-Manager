-- Add unique constraint on document_content.document_id for upsert support
ALTER TABLE document_content ADD CONSTRAINT document_content_document_id_key UNIQUE (document_id);
