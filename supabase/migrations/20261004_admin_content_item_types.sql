-- Phase 5j — admin_content_items.item_type check constraint widened.
-- The original constraint (20261001) only allowed question/search/routine/
-- vendor/task/system/category. The lab now also locks live entities of
-- types handyman, vehicle, and prompt, so the constraint blocks any
-- attempt to lock-as-approved for those.

alter table public.admin_content_items
  drop constraint if exists admin_content_items_item_type_check;

alter table public.admin_content_items
  add constraint admin_content_items_item_type_check
  check (
    item_type in (
      'question',
      'search',
      'routine',
      'vendor',
      'task',
      'system',
      'category',
      'handyman',
      'vehicle',
      'prompt'
    )
  );

-- Mirror the change on the published-content RLS policy so anon clients
-- can still SELECT public-facing rows for these new types if/when needed.
drop policy if exists "published admin content select" on public.admin_content_items;

create policy "published admin content select"
  on public.admin_content_items
  for select
  to anon, authenticated
  using (
    status in ('active', 'cut')
    and item_type in (
      'question',
      'search',
      'routine',
      'vendor',
      'task',
      'system',
      'category',
      'handyman',
      'vehicle',
      'prompt'
    )
  );
