-- House Quiz state per property.
--
-- Stores all quiz state in a single JSONB column on the properties row, scoped
-- by property because each property has its own systems / vehicles / utilities.
--
-- Schema:
-- {
--   "started_at": "2026-04-06T18:30:00Z",
--   "completed_at": null,
--   "answers": {
--     "<question_id>": {
--       "answer_id": "asphalt_shingle",
--       "custom": null,
--       "answered_at": "2026-04-06T18:31:12Z"
--     }
--   },
--   "saved_for_later": ["q14"],
--   "skipped": ["q21"]
-- }

ALTER TABLE properties
    ADD COLUMN IF NOT EXISTS house_quiz_state JSONB;

COMMENT ON COLUMN properties.house_quiz_state IS
    'House Quiz state per property. Tracks answered, saved-for-later, and skipped questions plus per-question payloads.';
