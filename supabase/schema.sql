-- =========================================================
-- SCHEMA : Gestion de stock, facturation, bons de livraison
--          et bons de sortie — Supabase (PostgreSQL)
-- =========================================================
-- A exécuter dans l'éditeur SQL de Supabase (Project > SQL Editor).
-- Ce script est idempotent-friendly : il peut être rejoué après
-- correction (DROP ... IF EXISTS sur les objets qu'il crée).

create extension if not exists "uuid-ossp";

-- ========================= ENUMS =========================
do $$ begin
  create type role_utilisateur as enum ('admin','gestionnaire','vendeur');
exception when duplicate_object then null; end $$;

do $$ begin
  create type statut_facture as enum ('impayee','payee','annulee');
exception when duplicate_object then null; end $$;

do $$ begin
  create type type_mouvement as enum ('entree','sortie','livraison','correction');
exception when duplicate_object then null; end $$;

-- ========================= PROFILES =========================
-- Un profil par utilisateur Supabase Auth (auth.users), avec rôle métier.
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nom text not null,
  role role_utilisateur not null default 'vendeur',
  created_at timestamptz not null default now()
);

-- ========================= CATEGORIES =========================
create table if not exists categories (
  id uuid primary key default uuid_generate_v4(),
  nom text not null unique,
  created_at timestamptz not null default now()
);

-- ========================= ENTREPOTS =========================
create table if not exists entrepots (
  id uuid primary key default uuid_generate_v4(),
  nom text not null,
  adresse text,
  created_at timestamptz not null default now()
);

-- Entrepôt par défaut, créé une seule fois.
insert into entrepots (nom, adresse)
  select 'Entrepôt principal', null
  where not exists (select 1 from entrepots);

-- ========================= CLIENTS =========================
create table if not exists clients (
  id uuid primary key default uuid_generate_v4(),
  nom text not null,
  telephone text,
  adresse text,
  ice text,
  created_at timestamptz not null default now()
);

-- ========================= PRODUITS =========================
create table if not exists produits (
  id uuid primary key default uuid_generate_v4(),
  nom text not null,
  categorie_id uuid references categories(id) on delete set null,
  unite text not null default 'unité',
  prix_achat numeric(12,2) not null default 0,
  prix_vente numeric(12,2) not null default 0,
  seuil_alerte numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ========================= STOCKS (quantité par produit / entrepôt) =====
create table if not exists stocks (
  id uuid primary key default uuid_generate_v4(),
  produit_id uuid not null references produits(id) on delete cascade,
  entrepot_id uuid not null references entrepots(id) on delete cascade,
  quantite numeric(12,2) not null default 0,
  unique (produit_id, entrepot_id)
);

-- Vue pratique : quantité totale tous entrepôts confondus.
create or replace view v_produits_stock as
  select p.*,
         coalesce(sum(s.quantite), 0) as quantite_totale
  from produits p
  left join stocks s on s.produit_id = p.id
  group by p.id;

-- ========================= MOUVEMENTS DE STOCK (journal) =========================
create table if not exists mouvements_stock (
  id uuid primary key default uuid_generate_v4(),
  produit_id uuid not null references produits(id) on delete cascade,
  entrepot_id uuid not null references entrepots(id) on delete cascade,
  type type_mouvement not null,
  quantite numeric(12,2) not null,
  quantite_avant numeric(12,2) not null,
  quantite_apres numeric(12,2) not null,
  reference_type text,          -- 'facture' | 'bon_livraison' | 'bon_sortie' | 'manuel'
  reference_id uuid,
  motif text,
  user_id uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- ========================= COMPTEURS (numérotation FAC/BL/BS) =========================
-- 'facture' et 'bon_livraison' utilisent un compteur global (FAC-0001…).
-- 'bon_sortie' utilise un compteur annuel, une ligne par année étant créée
-- automatiquement par prochain_numero_annuel() (clé 'bon_sortie_<année>',
-- ex. BS-2026-0001).
create table if not exists compteurs_numerotation (
  cle text primary key,
  valeur integer not null default 0
);
insert into compteurs_numerotation (cle, valeur) values
  ('facture',0), ('bon_livraison',0)
on conflict (cle) do nothing;

create or replace function prochain_numero(p_cle text, p_prefixe text)
returns text language plpgsql as $$
declare v_valeur integer;
begin
  update compteurs_numerotation set valeur = valeur + 1
    where cle = p_cle returning valeur into v_valeur;
  return p_prefixe || '-' || lpad(v_valeur::text, 4, '0');
end; $$;

-- Numérotation annuelle, ex. BS-2026-0001. Le compteur repart à 1
-- chaque nouvelle année (une ligne par année dans compteurs_numerotation,
-- clé "<p_cle_base>_<année>").
create or replace function prochain_numero_annuel(p_cle_base text, p_prefixe text)
returns text language plpgsql as $$
declare
  v_annee integer := extract(year from current_date);
  v_cle text := p_cle_base || '_' || v_annee;
  v_valeur integer;
begin
  insert into compteurs_numerotation (cle, valeur) values (v_cle, 0)
    on conflict (cle) do nothing;
  update compteurs_numerotation set valeur = valeur + 1
    where cle = v_cle returning valeur into v_valeur;
  return p_prefixe || '-' || v_annee || '-' || lpad(v_valeur::text, 4, '0');
end; $$;

-- ========================= FACTURES =========================
create table if not exists factures (
  id uuid primary key default uuid_generate_v4(),
  numero text not null unique,
  client_id uuid references clients(id) on delete set null,
  date date not null default current_date,
  tva numeric(5,2) not null default 20,
  statut statut_facture not null default 'impayee',
  total_ht numeric(12,2) not null default 0,
  total_tva numeric(12,2) not null default 0,
  total_ttc numeric(12,2) not null default 0,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists lignes_facture (
  id uuid primary key default uuid_generate_v4(),
  facture_id uuid not null references factures(id) on delete cascade,
  produit_id uuid references produits(id) on delete set null,
  designation text not null,
  quantite numeric(12,2) not null,
  prix_unitaire numeric(12,2) not null,
  total numeric(12,2) generated always as (quantite * prix_unitaire) stored
);

-- ========================= BONS DE LIVRAISON =========================
create table if not exists bons_livraison (
  id uuid primary key default uuid_generate_v4(),
  numero text not null unique,
  client_id uuid references clients(id) on delete set null,
  entrepot_id uuid not null references entrepots(id),
  date date not null default current_date,
  transporteur text,
  adresse_livraison text,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists lignes_bl (
  id uuid primary key default uuid_generate_v4(),
  bon_livraison_id uuid not null references bons_livraison(id) on delete cascade,
  produit_id uuid references produits(id) on delete set null,
  designation text not null,
  quantite numeric(12,2) not null,
  prix_unitaire numeric(12,2) not null default 0
);

-- ========================= BONS DE SORTIE =========================
-- Sortie de marchandise transportée par un chauffeur / véhicule (pas de
-- facturation directe associée : pas de client, pas de prix unitaire).
create table if not exists bons_sortie (
  id uuid primary key default uuid_generate_v4(),
  numero text not null unique,               -- ex. BS-2026-0001
  entrepot_id uuid not null references entrepots(id),
  date date not null default current_date,
  chauffeur_nom text,
  chauffeur_cin text,
  vehicule_immatriculation text,
  motif text,
  observations text,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists lignes_bon_sortie (
  id uuid primary key default uuid_generate_v4(),
  bon_sortie_id uuid not null references bons_sortie(id) on delete cascade,
  produit_id uuid references produits(id) on delete set null,
  designation text not null,                 -- récupérée depuis le produit à la création
  quantite numeric(12,2) not null,
  unite text                                  -- récupérée depuis le produit à la création
);

-- ========================= TRAJETS (suivi GPS) =========================
do $$ begin
  create type statut_trajet as enum ('en_cours','termine','annule');
exception when duplicate_object then null; end $$;

-- Un trajet est rattaché à un bon de livraison OU un bon de sortie.
-- Comme un même id peut exister dans les deux tables, on ne peut pas
-- poser une clé étrangère directe : "type_bon" indique la table cible,
-- et un trigger (trg_trajets_valider_bon) vérifie que le bon existe
-- réellement avant d'accepter l'insertion/la mise à jour.
create table if not exists trajets (
  id uuid primary key default uuid_generate_v4(),
  bon_id uuid not null,
  type_bon text not null check (type_bon in ('livraison','sortie')),
  chauffeur_nom text,
  chauffeur_cin text,
  vehicule_immatriculation text,
  date_debut timestamptz not null default now(),
  date_fin timestamptz,
  statut statut_trajet not null default 'en_cours',
  distance_km numeric(10,2),
  duree_minutes integer,
  points jsonb not null default '[]'::jsonb,  -- [{latitude, longitude, timestamp}, ...]
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_trajets_bon on trajets (bon_id, type_bon);

-- Vérifie que bon_id existe bien dans la table correspondant à type_bon.
create or replace function trg_trajets_valider_bon() returns trigger
language plpgsql as $$
begin
  if new.type_bon = 'livraison' then
    if not exists (select 1 from bons_livraison where id = new.bon_id) then
      raise exception 'Aucun bon de livraison avec l''id %', new.bon_id;
    end if;
  elsif new.type_bon = 'sortie' then
    if not exists (select 1 from bons_sortie where id = new.bon_id) then
      raise exception 'Aucun bon de sortie avec l''id %', new.bon_id;
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists on_trajets_valider_bon on trajets;
create trigger on_trajets_valider_bon before insert or update on trajets
  for each row execute function trg_trajets_valider_bon();

-- Recalcule automatiquement la durée (minutes) dès que date_fin est renseignée.
create or replace function trg_trajets_calc_duree() returns trigger
language plpgsql as $$
begin
  if new.date_fin is not null and new.date_debut is not null then
    new.duree_minutes := round(extract(epoch from (new.date_fin - new.date_debut)) / 60);
  end if;
  return new;
end; $$;

drop trigger if exists on_trajets_calc_duree on trajets;
create trigger on_trajets_calc_duree before insert or update on trajets
  for each row execute function trg_trajets_calc_duree();

-- Ajoute atomiquement un point GPS {latitude, longitude, timestamp} au trajet.
create or replace function ajouter_point_trajet(
  p_trajet_id uuid, p_latitude numeric, p_longitude numeric, p_timestamp timestamptz default now()
) returns void language plpgsql as $$
begin
  update trajets set points = points || jsonb_build_array(jsonb_build_object(
    'latitude', p_latitude, 'longitude', p_longitude, 'timestamp', p_timestamp
  ))
  where id = p_trajet_id;
end; $$;

-- ========================= PARAMETRES ENTREPRISE (ligne unique) =========================
create table if not exists parametres_entreprise (
  id integer primary key default 1,
  nom text default '',
  adresse text default '',
  telephone text default '',
  ice text default '',
  devise text default 'DH',
  tva_defaut numeric(5,2) default 20,
  constraint parametres_singleton check (id = 1)
);
insert into parametres_entreprise (id) values (1) on conflict (id) do nothing;

-- =========================================================
-- FONCTIONS ET TRIGGERS : mouvements de stock automatiques
-- =========================================================

-- Ajuste la table stocks (upsert) et journalise dans mouvements_stock.
create or replace function ajuster_stock(
  p_produit_id uuid, p_entrepot_id uuid, p_delta numeric,
  p_type type_mouvement, p_reference_type text, p_reference_id uuid, p_motif text
) returns void language plpgsql as $$
declare v_avant numeric; v_apres numeric;
begin
  insert into stocks (produit_id, entrepot_id, quantite)
    values (p_produit_id, p_entrepot_id, 0)
    on conflict (produit_id, entrepot_id) do nothing;

  select quantite into v_avant from stocks
    where produit_id = p_produit_id and entrepot_id = p_entrepot_id
    for update;

  v_apres := v_avant + p_delta;

  update stocks set quantite = v_apres
    where produit_id = p_produit_id and entrepot_id = p_entrepot_id;

  insert into mouvements_stock
    (produit_id, entrepot_id, type, quantite, quantite_avant, quantite_apres,
     reference_type, reference_id, motif, user_id)
  values
    (p_produit_id, p_entrepot_id, p_type, p_delta, v_avant, v_apres,
     p_reference_type, p_reference_id, p_motif, auth.uid());
end; $$;

-- --- Bons de livraison : sortie de stock à la création d'une ligne ---
create or replace function trg_lignes_bl_insert() returns trigger
language plpgsql as $$
declare v_entrepot uuid;
begin
  select entrepot_id into v_entrepot from bons_livraison where id = new.bon_livraison_id;
  if new.produit_id is not null then
    perform ajuster_stock(new.produit_id, v_entrepot, -new.quantite, 'livraison',
      'bon_livraison', new.bon_livraison_id, 'Sortie sur bon de livraison');
  end if;
  return new;
end; $$;

drop trigger if exists on_lignes_bl_insert on lignes_bl;
create trigger on_lignes_bl_insert after insert on lignes_bl
  for each row execute function trg_lignes_bl_insert();

-- Suppression d'une ligne BL : on réintègre la quantité au stock.
create or replace function trg_lignes_bl_delete() returns trigger
language plpgsql as $$
declare v_entrepot uuid;
begin
  select entrepot_id into v_entrepot from bons_livraison where id = old.bon_livraison_id;
  if old.produit_id is not null then
    perform ajuster_stock(old.produit_id, v_entrepot, old.quantite, 'correction',
      'bon_livraison', old.bon_livraison_id, 'Annulation ligne bon de livraison');
  end if;
  return old;
end; $$;

drop trigger if exists on_lignes_bl_delete on lignes_bl;
create trigger on_lignes_bl_delete after delete on lignes_bl
  for each row execute function trg_lignes_bl_delete();

-- --- Bons de sortie : même logique ---
create or replace function trg_lignes_bon_sortie_insert() returns trigger
language plpgsql as $$
declare v_entrepot uuid;
begin
  select entrepot_id into v_entrepot from bons_sortie where id = new.bon_sortie_id;
  if new.produit_id is not null then
    perform ajuster_stock(new.produit_id, v_entrepot, -new.quantite, 'sortie',
      'bon_sortie', new.bon_sortie_id, 'Sortie de stock');
  end if;
  return new;
end; $$;

drop trigger if exists on_lignes_bon_sortie_insert on lignes_bon_sortie;
create trigger on_lignes_bon_sortie_insert after insert on lignes_bon_sortie
  for each row execute function trg_lignes_bon_sortie_insert();

create or replace function trg_lignes_bon_sortie_delete() returns trigger
language plpgsql as $$
declare v_entrepot uuid;
begin
  select entrepot_id into v_entrepot from bons_sortie where id = old.bon_sortie_id;
  if old.produit_id is not null then
    perform ajuster_stock(old.produit_id, v_entrepot, old.quantite, 'correction',
      'bon_sortie', old.bon_sortie_id, 'Annulation ligne bon de sortie');
  end if;
  return old;
end; $$;

drop trigger if exists on_lignes_bon_sortie_delete on lignes_bon_sortie;
create trigger on_lignes_bon_sortie_delete after delete on lignes_bon_sortie
  for each row execute function trg_lignes_bon_sortie_delete();

-- --- Recalcul automatique des totaux de facture ---
create or replace function trg_recalc_facture() returns trigger
language plpgsql as $$
declare v_facture_id uuid; v_ht numeric; v_tva numeric;
begin
  v_facture_id := coalesce(new.facture_id, old.facture_id);
  select coalesce(sum(quantite*prix_unitaire),0) into v_ht
    from lignes_facture where facture_id = v_facture_id;
  select tva into v_tva from factures where id = v_facture_id;
  update factures set
    total_ht = v_ht,
    total_tva = v_ht * v_tva / 100,
    total_ttc = v_ht + (v_ht * v_tva / 100)
  where id = v_facture_id;
  return null;
end; $$;

drop trigger if exists on_lignes_facture_change on lignes_facture;
create trigger on_lignes_facture_change
  after insert or update or delete on lignes_facture
  for each row execute function trg_recalc_facture();

-- =========================================================
-- ROW LEVEL SECURITY
-- =========================================================
alter table profiles enable row level security;
alter table categories enable row level security;
alter table entrepots enable row level security;
alter table clients enable row level security;
alter table produits enable row level security;
alter table stocks enable row level security;
alter table mouvements_stock enable row level security;
alter table factures enable row level security;
alter table lignes_facture enable row level security;
alter table bons_livraison enable row level security;
alter table lignes_bl enable row level security;
alter table bons_sortie enable row level security;
alter table lignes_bon_sortie enable row level security;
alter table trajets enable row level security;
alter table parametres_entreprise enable row level security;
alter table compteurs_numerotation enable row level security;

-- Règle simple pour l'ensemble de l'app : tout utilisateur authentifié
-- (donc ayant un profil) peut lire/écrire. La suppression sur les tables
-- sensibles (produits, clients, factures, bons) est réservée aux rôles
-- 'admin' et 'gestionnaire'. Ajustez selon vos besoins réels.

create or replace function is_authentifie() returns boolean
language sql stable as $$ select auth.uid() is not null; $$;

create or replace function est_admin_ou_gestionnaire() returns boolean
language sql stable as $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and role in ('admin','gestionnaire')
  );
$$;

-- profiles : chacun voit/Modifie son propre profil ; admin voit tout.
create policy profiles_select on profiles for select using (
  id = auth.uid() or est_admin_ou_gestionnaire()
);
create policy profiles_update_self on profiles for update using (id = auth.uid());
create policy profiles_insert_self on profiles for insert with check (id = auth.uid());

-- Tables de référence et opérationnelles : lecture pour tout authentifié.
create policy categories_all_read on categories for select using (is_authentifie());
create policy categories_write on categories for insert with check (is_authentifie());
create policy categories_update on categories for update using (is_authentifie());
create policy categories_delete on categories for delete using (est_admin_ou_gestionnaire());

create policy entrepots_read on entrepots for select using (is_authentifie());
create policy entrepots_write on entrepots for all using (est_admin_ou_gestionnaire());

create policy clients_read on clients for select using (is_authentifie());
create policy clients_insert on clients for insert with check (is_authentifie());
create policy clients_update on clients for update using (is_authentifie());
create policy clients_delete on clients for delete using (est_admin_ou_gestionnaire());

create policy produits_read on produits for select using (is_authentifie());
create policy produits_insert on produits for insert with check (is_authentifie());
create policy produits_update on produits for update using (is_authentifie());
create policy produits_delete on produits for delete using (est_admin_ou_gestionnaire());

create policy stocks_read on stocks for select using (is_authentifie());
create policy stocks_write on stocks for all using (is_authentifie());

create policy mouvements_read on mouvements_stock for select using (is_authentifie());
create policy mouvements_insert on mouvements_stock for insert with check (is_authentifie());

create policy factures_read on factures for select using (is_authentifie());
create policy factures_insert on factures for insert with check (is_authentifie());
create policy factures_update on factures for update using (is_authentifie());
create policy factures_delete on factures for delete using (est_admin_ou_gestionnaire());

create policy lignes_facture_read on lignes_facture for select using (is_authentifie());
create policy lignes_facture_write on lignes_facture for all using (is_authentifie());

create policy bl_read on bons_livraison for select using (is_authentifie());
create policy bl_insert on bons_livraison for insert with check (is_authentifie());
create policy bl_update on bons_livraison for update using (is_authentifie());
create policy bl_delete on bons_livraison for delete using (est_admin_ou_gestionnaire());

create policy lignes_bl_read on lignes_bl for select using (is_authentifie());
create policy lignes_bl_write on lignes_bl for all using (is_authentifie());

create policy bs_read on bons_sortie for select using (is_authentifie());
create policy bs_insert on bons_sortie for insert with check (is_authentifie());
create policy bs_update on bons_sortie for update using (is_authentifie());
create policy bs_delete on bons_sortie for delete using (est_admin_ou_gestionnaire());

create policy lignes_bon_sortie_read on lignes_bon_sortie for select using (is_authentifie());
create policy lignes_bon_sortie_write on lignes_bon_sortie for all using (is_authentifie());

create policy trajets_read on trajets for select using (is_authentifie());
create policy trajets_insert on trajets for insert with check (is_authentifie());
create policy trajets_update on trajets for update using (is_authentifie());
create policy trajets_delete on trajets for delete using (est_admin_ou_gestionnaire());

create policy parametres_read on parametres_entreprise for select using (is_authentifie());
create policy parametres_write on parametres_entreprise for update using (est_admin_ou_gestionnaire());

create policy compteurs_read on compteurs_numerotation for select using (is_authentifie());
create policy compteurs_write on compteurs_numerotation for update using (is_authentifie());

-- =========================================================
-- Fin du script. Pensez à créer un premier utilisateur via
-- Supabase Auth, puis à insérer sa ligne dans "profiles" avec
-- le rôle 'admin' :
--   insert into profiles (id, nom, role)
--   values ('<uuid-auth-user>', 'Administrateur', 'admin');
-- =========================================================
