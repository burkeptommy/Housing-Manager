-- Fix foreign key constraints on tables referencing users(id)
-- so that deleting a user cascades instead of blocking.

-- chat_messages: cascade delete when user is removed
ALTER TABLE chat_messages
    DROP CONSTRAINT chat_messages_user_id_fkey,
    ADD CONSTRAINT chat_messages_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- access_log: set null when user is removed (audit trail should survive)
ALTER TABLE access_log
    DROP CONSTRAINT access_log_user_id_fkey,
    ADD CONSTRAINT access_log_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
