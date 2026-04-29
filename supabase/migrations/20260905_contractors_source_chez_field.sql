BEGIN;

-- Chez Field provider adoption stamps `contractors.source = 'chez_field'`.
-- The original Phase 19k CHECK only allowed manual/quiz/find_vendor, so
-- homeowner-side provider adoption failed with `contractors_source_check`.
ALTER TABLE contractors
  DROP CONSTRAINT IF EXISTS contractors_source_check;

ALTER TABLE contractors
  ADD CONSTRAINT contractors_source_check
  CHECK (source IN ('manual', 'quiz', 'find_vendor', 'chez_field'));

COMMIT;
