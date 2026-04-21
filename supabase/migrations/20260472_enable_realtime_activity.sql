-- Phase 50: Enable Supabase Realtime on key tables for the
-- Dashboard Recent Activity feed. When documents are processed,
-- tasks get completed, or systems are added, the iOS client
-- receives change events and refreshes the activity feed without
-- manual pull-to-refresh.
--
-- This adds tables to the supabase_realtime publication. If a
-- table is already a member the ALTER is a no-op (Postgres ignores
-- duplicate ADD TABLE).

ALTER PUBLICATION supabase_realtime ADD TABLE documents;
ALTER PUBLICATION supabase_realtime ADD TABLE maintenance_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE home_systems;
ALTER PUBLICATION supabase_realtime ADD TABLE contractors;
