-- RLS policies for inbox-attachments storage bucket
-- The bucket was created in 2026032604_inbox_items_enhanced.sql but had no access policies,
-- so the app (using user auth tokens) could not read/write files — only service_role could.

CREATE POLICY "Users can view own household inbox attachments"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'inbox-attachments'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can upload to own household inbox attachments"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'inbox-attachments'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can update own household inbox attachments"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'inbox-attachments'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can delete own household inbox attachments"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'inbox-attachments'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );
