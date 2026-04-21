-- Phase 54E.4: Defensive unique index so concurrent writes can't
-- re-introduce the duplicates 20260605 just cleaned up.
--
-- Scope: top-level rows (parent_system_id IS NULL) per property,
-- keyed on normalized name + normalized subtype. Sub-systems are
-- excluded because siblings under the same parent legitimately share
-- a name ("Pool Pump" under two different Pool parents at two
-- properties would collide if we keyed cross-property, but we don't).
--
-- Subtype is included in the key so wood-vs-gas Chimney stay distinct
-- even though they share a name. COALESCE to '' so rows without a
-- subtype still collide on name.
--
-- Inserts that race on the same normalized key now fail with a unique
-- violation instead of silently creating a duplicate. Every current
-- iOS caller that writes home_systems wraps the insert in `try?` or a
-- try/catch, so the collision surfaces as a no-op rather than a crash.
create unique index if not exists uniq_home_systems_property_name_subtype
    on public.home_systems (
        property_id,
        lower(trim(name)),
        lower(coalesce(subtype, ''))
    )
    where parent_system_id is null;
