-- Batch Ledger database. Paste all of this into Supabase > SQL Editor > Run.
create table if not exists public.docs (
  col text not null,
  id text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (col, id)
);
alter table public.docs enable row level security;

drop policy if exists "team read" on public.docs;
drop policy if exists "team insert" on public.docs;
drop policy if exists "team update" on public.docs;
drop policy if exists "team delete" on public.docs;
create policy "team read" on public.docs for select to authenticated using (true);
create policy "team insert" on public.docs for insert to authenticated with check (true);
create policy "team update" on public.docs for update to authenticated using (true) with check (true);
create policy "team delete" on public.docs for delete to authenticated using (true);

create or replace function public.merge_doc(p_col text, p_id text, p_patch jsonb)
returns void language sql security invoker as $$
  insert into public.docs(col, id, data) values (p_col, p_id, p_patch)
  on conflict (col, id) do update set data = public.docs.data || excluded.data, updated_at = now();
$$;

do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;
