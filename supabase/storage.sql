-- Haven Storage Buckets
-- Phase 3: Supabase Backend
-- Run this in the Supabase SQL Editor after schema.sql

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Documents bucket — encrypted document files organized by category
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);

-- Property images bucket — property and system photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('property-images', 'property-images', false);

-- Service records bucket — before/after photos for service work
INSERT INTO storage.buckets (id, name, public)
VALUES ('service-records', 'service-records', false);

-- ============================================================================
-- STORAGE RLS POLICIES
-- All policies enforce household-level access: the first path segment must
-- match the authenticated user's household_id.
-- Path pattern: {household_id}/...
-- ============================================================================

-- ----------------------------------------------------------------------------
-- documents bucket
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own household documents"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'documents'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can upload to own household documents"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'documents'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can update own household documents"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'documents'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can delete own household documents"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'documents'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

-- ----------------------------------------------------------------------------
-- property-images bucket
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own household property images"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'property-images'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can upload own household property images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'property-images'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can update own household property images"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'property-images'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can delete own household property images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'property-images'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

-- ----------------------------------------------------------------------------
-- service-records bucket
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own household service record images"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'service-records'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can upload own household service record images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'service-records'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can update own household service record images"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'service-records'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );

CREATE POLICY "Users can delete own household service record images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'service-records'
        AND (storage.foldername(name))[1] = (SELECT household_id::text FROM users WHERE id = auth.uid())
    );
