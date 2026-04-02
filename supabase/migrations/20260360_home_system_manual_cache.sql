-- Cache manual/guide links on home_systems to avoid calling
-- the lookup-manual edge function on every system detail page load.
-- Format: JSONB array of {type, url, cached} objects.
ALTER TABLE home_systems ADD COLUMN IF NOT EXISTS cached_manual_links JSONB DEFAULT '[]';
