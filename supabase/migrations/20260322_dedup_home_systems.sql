-- One-time cleanup: remove duplicate home systems created by back-navigation bug.
-- Keeps the OLDEST system per (property_id, name) and deletes newer duplicates.
-- Maintenance tasks and warranties CASCADE-delete with their parent system.

-- Step 1: Delete duplicate home systems (keep the earliest created_at per property+name)
DELETE FROM home_systems
WHERE id IN (
    SELECT id FROM (
        SELECT
            id,
            ROW_NUMBER() OVER (
                PARTITION BY property_id, lower(name)
                ORDER BY created_at ASC
            ) AS rn
        FROM home_systems
    ) ranked
    WHERE rn > 1
);

-- Step 2: Also dedup maintenance tasks that may have been orphaned or duplicated
-- independently (same title + property + system after dedup)
DELETE FROM maintenance_tasks
WHERE id IN (
    SELECT id FROM (
        SELECT
            id,
            ROW_NUMBER() OVER (
                PARTITION BY property_id, COALESCE(system_id, '00000000-0000-0000-0000-000000000000'), lower(title)
                ORDER BY created_at ASC
            ) AS rn
        FROM maintenance_tasks
    ) ranked
    WHERE rn > 1
);
