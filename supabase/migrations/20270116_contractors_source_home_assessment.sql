-- Wave 2 (Chez service rebuild) — allow 'home_assessment' as a
-- contractors.source value.
--
-- The assessment ingestion has always stamped source='home_assessment'
-- on vendors captured during a visit, but the CHECK constraint never
-- allowed it, so every contractor insert from an assessment silently
-- failed (supabase-js errors were unchecked). Found by the Wave 2
-- onboarding end-to-end test; the constraint now matches the code's
-- long-standing intent.
ALTER TABLE public.contractors
    DROP CONSTRAINT IF EXISTS contractors_source_check;

ALTER TABLE public.contractors
    ADD CONSTRAINT contractors_source_check
    CHECK (source = ANY (ARRAY[
        'manual'::text,
        'quiz'::text,
        'find_vendor'::text,
        'chez_field'::text,
        'chez_recommendation'::text,
        'home_assessment'::text
    ]));
