-- Deduplicate maintenance tasks: keep only the earliest-created per (system_id, title)
DELETE FROM maintenance_tasks
WHERE id NOT IN (
    SELECT DISTINCT ON (system_id, title) id
    FROM maintenance_tasks
    ORDER BY system_id, title, created_at ASC
);
