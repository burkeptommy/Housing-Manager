-- Phase 78: backfill punch items from existing handyman visit notes
--
-- Walks every maintenance_tasks row whose template_id starts with
-- 'Handyman:' and whose notes contain a "What's included:" or "Punch list:"
-- bullet block. Parses each bullet into a handyman_punch_items row linked
-- to the visit via assigned_visit_task_id, then trims the bullet block
-- out of notes so the visit stops carrying frozen text.
--
-- Idempotent — skips visits that already have backfill rows linked.
--
-- Run-once after the Phase 78 schema migration lands. Logged here so the
-- one-shot stays in version control with the surrounding migrations.

CREATE OR REPLACE FUNCTION public.backfill_punch_items_from_visit_notes()
RETURNS TABLE (
  task_id uuid,
  items_inserted int,
  notes_trimmed boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  visit_row record;
  raw_line text;
  cleaned_line text;
  parsed_title text;
  parsed_minutes int;
  duration_match text[];
  inserted_count int;
  template_match uuid;
  system_match uuid;
  trimmed_notes text;
BEGIN
  FOR visit_row IN
    -- Match any maintenance_task with a punch-list block in notes.
    -- Originally filtered to template_id LIKE 'Handyman:%' but ad-hoc
    -- visits (created via create_ad_hoc_visit) have template_id=NULL
    -- and were getting skipped. The notes-content check + idempotency
    -- guard already protect against false positives.
    SELECT id, household_id, property_id, notes, created_at, system_id AS task_system_id
      FROM public.maintenance_tasks
     WHERE notes IS NOT NULL
       AND (notes ILIKE '%what''s included%' OR notes ILIKE '%punch list%')
       AND archived_at IS NULL
       -- Idempotency guard — skip visits that already have backfilled items.
       AND NOT EXISTS (
         SELECT 1 FROM public.handyman_punch_items pi
          WHERE pi.assigned_visit_task_id = maintenance_tasks.id
            AND pi.source = 'backfill_from_notes'
       )
  LOOP
    inserted_count := 0;

    FOREACH raw_line IN ARRAY regexp_split_to_array(visit_row.notes, E'\n')
    LOOP
      cleaned_line := trim(raw_line);

      -- Skip empty lines, header lines, plain prose
      IF cleaned_line = '' THEN CONTINUE; END IF;
      IF cleaned_line ILIKE 'what''s included%' THEN CONTINUE; END IF;
      IF cleaned_line ILIKE 'punch list%' THEN CONTINUE; END IF;
      IF cleaned_line ILIKE 'tasks:%' THEN CONTINUE; END IF;
      IF cleaned_line ~ ':$' THEN CONTINUE; END IF;

      -- Strip leading bullet markers ("- ", "• ", "* ", "1. ", "1) ")
      IF cleaned_line LIKE '- %' THEN
        cleaned_line := substring(cleaned_line FROM 3);
      ELSIF cleaned_line LIKE '• %' THEN
        cleaned_line := substring(cleaned_line FROM 4);
      ELSIF cleaned_line LIKE '* %' THEN
        cleaned_line := substring(cleaned_line FROM 3);
      ELSIF cleaned_line ~ '^\d+[.)]\s' THEN
        cleaned_line := regexp_replace(cleaned_line, '^\d+[.)]\s+', '');
      ELSE
        -- Non-bullet line — probably prose ("The handyman will work
        -- through this visit's punch list."). Skip.
        CONTINUE;
      END IF;

      -- Skip the literal "Spring handyman visit" / "Fall handyman visit"
      -- placeholder bullet emitted by some bundles before any real items
      -- have been added — leaving an empty visit shouldn't insert phantom
      -- punch items.
      IF cleaned_line ILIKE 'spring handyman visit%'
         OR cleaned_line ILIKE 'fall handyman visit%'
         OR cleaned_line ILIKE 'handyman visit%' THEN
        CONTINUE;
      END IF;

      -- Extract trailing duration: "(~15 min)", "~15 min", "(15 min)", "15 min"
      duration_match := regexp_match(
        cleaned_line,
        '\s*[\(\s~·•\-]?\s*(\d+)\s*min\)?\s*$',
        'i'
      );
      IF duration_match IS NOT NULL THEN
        parsed_minutes := duration_match[1]::int;
        cleaned_line := regexp_replace(
          cleaned_line,
          '\s*[\(\s~·•\-]?\s*\d+\s*min\)?\s*$',
          '',
          'i'
        );
      ELSE
        parsed_minutes := NULL;
      END IF;

      parsed_title := trim(cleaned_line);
      IF length(parsed_title) < 3 THEN CONTINUE; END IF;

      -- Resolve template by exact (case-insensitive) title match
      SELECT id INTO template_match
        FROM public.punch_list_templates
       WHERE archived_at IS NULL
         AND lower(title) = lower(parsed_title)
       LIMIT 1;

      -- Resolve system_id when the matched template carries a category
      -- and the property has a single home_systems row in that category.
      system_match := NULL;
      IF template_match IS NOT NULL AND visit_row.property_id IS NOT NULL THEN
        SELECT id INTO system_match
          FROM public.home_systems
         WHERE property_id = visit_row.property_id
           AND archived_at IS NULL
           AND lower(category) = lower(
             (SELECT system_category FROM public.punch_list_templates WHERE id = template_match)
           )
         ORDER BY created_at ASC
         LIMIT 1;
      END IF;

      INSERT INTO public.handyman_punch_items (
        household_id,
        property_id,
        title,
        source,
        assigned_visit_task_id,
        system_id,
        system_label_snapshot,
        template_id,
        status,
        priority,
        estimated_minutes,
        proposed_by_role,
        proposed_at,
        proposal_status,
        accepted_at,
        created_at,
        updated_at
      )
      VALUES (
        visit_row.household_id,
        visit_row.property_id,
        parsed_title,
        'backfill_from_notes',
        visit_row.id,
        system_match,
        (SELECT name FROM public.home_systems WHERE id = system_match),
        template_match,
        'pending',
        'medium',
        parsed_minutes,
        'homeowner',
        visit_row.created_at,
        'accepted',
        visit_row.created_at,
        visit_row.created_at,
        now()
      );

      inserted_count := inserted_count + 1;
    END LOOP;

    -- Trim the bullet block out of notes if we inserted anything. Keeps
    -- any prose that lived above "What's included:" intact.
    IF inserted_count > 0 THEN
      trimmed_notes := regexp_replace(
        visit_row.notes,
        E'(?is)\\s*(what''s included|punch list):.*$',
        '',
        'g'
      );
      trimmed_notes := trim(trimmed_notes);
      IF trimmed_notes = '' THEN
        UPDATE public.maintenance_tasks
           SET notes = NULL
         WHERE id = visit_row.id;
      ELSE
        UPDATE public.maintenance_tasks
           SET notes = trimmed_notes
         WHERE id = visit_row.id;
      END IF;
    END IF;

    task_id := visit_row.id;
    items_inserted := inserted_count;
    notes_trimmed := inserted_count > 0;
    RETURN NEXT;
  END LOOP;
END;
$$;

-- Run the backfill once. Function is idempotent so re-running is a no-op
-- (it skips visits already touched).
SELECT * FROM public.backfill_punch_items_from_visit_notes();

-- Keep the function around as a reusable utility — handy if a future
-- bundle creator accidentally writes notes-bullets again, or for
-- diagnostics. Comment, don't drop.
COMMENT ON FUNCTION public.backfill_punch_items_from_visit_notes() IS
  'Phase 78 one-shot backfill. Idempotent — skips visits already converted. Returns (task_id, items_inserted, notes_trimmed) per visit processed.';
