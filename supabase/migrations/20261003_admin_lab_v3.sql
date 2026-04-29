-- Admin Lab v3 — adds the lock-anchor for live (Swift-baked) entities.
-- The admin_content_items table holds curated drafts AND lock anchors for
-- live entities. live_entity_id is the stable cross-rebuild identifier
-- (q3_heating_fuel, "Roofing:Annual roof inspection", "HVAC", etc.) so
-- the lock survives Swift refactors that don't change the entity ID.

alter table public.admin_content_items
  add column if not exists live_entity_id text;

-- Unique per (item_type, live_entity_id) when live_entity_id is set so
-- locking the same entity twice updates rather than dupes.
create unique index if not exists uniq_admin_items_live_entity
  on public.admin_content_items(item_type, live_entity_id)
  where live_entity_id is not null;

create index if not exists idx_admin_items_launch_status_live
  on public.admin_content_items(launch_status, item_type)
  where live_entity_id is not null;
