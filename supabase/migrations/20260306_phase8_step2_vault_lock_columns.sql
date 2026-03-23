-- Phase 8, Step 2: Add Vault Lock columns to documents table
ALTER TABLE documents ADD COLUMN vault_locked BOOLEAN DEFAULT false;
ALTER TABLE documents ADD COLUMN vault_lock_iv TEXT;  -- Initialization vector for client-side encryption
