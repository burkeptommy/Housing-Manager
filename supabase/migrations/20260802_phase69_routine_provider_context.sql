alter table public.routines
add column if not exists source_utility_account_id uuid references public.utility_accounts(id) on delete set null;

create index if not exists routines_source_utility_account_idx
on public.routines(source_utility_account_id);
