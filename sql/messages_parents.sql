-- Messages aux parents (onglet « Messages ») — à exécuter une seule fois
-- dans Supabase : SQL Editor → coller tout ce texte → Run.
-- Les envois sont faits par le directeur ou le secrétariat.

create or replace function public.msg_est_bureau()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profils p
                where p.id = auth.uid() and p.actif and p.role in ('directeur','secretariat'));
$$;
revoke all on function public.msg_est_bureau() from public;
grant execute on function public.msg_est_bureau() to authenticated;

-- Notes de devoir envoyées (une ligne par élève et par devoir)
create table if not exists public.envois_devoirs(
  evaluation_id uuid not null references public.evaluations(id) on delete cascade,
  eleve_id uuid not null references public.eleves(id) on delete cascade,
  le timestamptz not null default now(),
  par uuid default auth.uid(),
  primary key (evaluation_id, eleve_id)
);
alter table public.envois_devoirs enable row level security;
drop policy if exists msg_bureau_envois_devoirs on public.envois_devoirs;
create policy msg_bureau_envois_devoirs on public.envois_devoirs for all to authenticated
  using (public.msg_est_bureau()) with check (public.msg_est_bureau());
grant select, insert, update, delete on public.envois_devoirs to authenticated;

-- Résultats du trimestre envoyés, et messages de suivi / félicitations
drop policy if exists msg_bureau_envois_bulletins on public.envois_bulletins;
create policy msg_bureau_envois_bulletins on public.envois_bulletins for all to authenticated
  using (public.msg_est_bureau()) with check (public.msg_est_bureau());
grant select, insert, update, delete on public.envois_bulletins to authenticated;

drop policy if exists msg_bureau_suivis on public.suivis;
create policy msg_bureau_suivis on public.suivis for all to authenticated
  using (public.msg_est_bureau()) with check (public.msg_est_bureau());
grant select, insert, update, delete on public.suivis to authenticated;

-- Supprimer un élève efface aussi ses envois
alter table public.envois_bulletins drop constraint if exists envois_bulletins_eleve_id_fkey;
alter table public.envois_bulletins add constraint envois_bulletins_eleve_id_fkey
  foreign key (eleve_id) references public.eleves(id) on delete cascade;
alter table public.suivis drop constraint if exists suivis_eleve_id_fkey;
alter table public.suivis add constraint suivis_eleve_id_fkey
  foreign key (eleve_id) references public.eleves(id) on delete cascade;

select 'Messages aux parents : prêt' as resultat;
