-- SeatBite initial multi-tenant schema
-- Apply in Supabase SQL Editor. Review and test policies before production.

create extension if not exists pgcrypto;

create type public.member_role as enum ('owner', 'manager', 'kitchen', 'staff');
create type public.order_status as enum ('pending_payment', 'confirmed', 'accepted', 'preparing', 'ready', 'delivered', 'cancelled', 'payment_failed');
create type public.payment_status as enum ('created', 'pending', 'succeeded', 'failed', 'refunded', 'partially_refunded');
create type public.payment_provider as enum ('phonepe');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  phone text,
  preferred_locale text not null default 'en' check (preferred_locale in ('en','te','hi')),
  created_at timestamptz not null default now()
);

create table public.theaters (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  city text not null,
  state text not null default 'Telangana',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.theater_members (
  theater_id uuid not null references public.theaters(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.member_role not null,
  created_at timestamptz not null default now(),
  primary key (theater_id, user_id)
);

create table public.screens (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null references public.theaters(id) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  unique (theater_id, name),
  unique (id, theater_id)
);

create table public.seats (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null,
  screen_id uuid not null,
  seat_label text not null,
  is_active boolean not null default true,
  foreign key (screen_id, theater_id) references public.screens(id, theater_id) on delete cascade,
  unique (screen_id, seat_label),
  unique (id, theater_id)
);

create table public.qr_codes (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null,
  seat_id uuid not null,
  token_hash text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  foreign key (seat_id, theater_id) references public.seats(id, theater_id) on delete cascade
);

create table public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null references public.theaters(id) on delete cascade,
  name_i18n jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  unique (id, theater_id)
);

create table public.menu_items (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null references public.theaters(id) on delete cascade,
  category_id uuid,
  name_i18n jsonb not null default '{}'::jsonb,
  description_i18n jsonb not null default '{}'::jsonb,
  price_paise integer not null check (price_paise >= 0),
  image_path text,
  is_available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  foreign key (category_id, theater_id) references public.menu_categories(id, theater_id)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null references public.theaters(id) on delete restrict,
  screen_id uuid not null,
  seat_id uuid not null,
  order_number bigint generated always as identity,
  customer_name text,
  customer_phone text,
  locale text not null default 'en' check (locale in ('en','te','hi')),
  status public.order_status not null default 'pending_payment',
  subtotal_paise integer not null check (subtotal_paise >= 0),
  tax_paise integer not null default 0 check (tax_paise >= 0),
  total_paise integer not null check (total_paise >= 0),
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (screen_id, theater_id) references public.screens(id, theater_id),
  foreign key (seat_id, theater_id) references public.seats(id, theater_id),
  unique (theater_id, idempotency_key),
  unique (theater_id, order_number),
  unique (id, theater_id)
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null,
  theater_id uuid not null,
  menu_item_id uuid,
  item_name_snapshot jsonb not null,
  unit_price_paise integer not null check (unit_price_paise >= 0),
  quantity integer not null check (quantity between 1 and 50),
  line_total_paise integer not null check (line_total_paise >= 0),
  foreign key (order_id, theater_id) references public.orders(id, theater_id) on delete cascade,
  foreign key (menu_item_id, theater_id) references public.menu_items(id, theater_id)
);

-- Only a non-secret reference/configuration label is stored here.
-- Store encrypted credentials in a dedicated secrets manager / approved server-side vault.
create table public.merchant_accounts (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null unique references public.theaters(id) on delete cascade,
  provider public.payment_provider not null default 'phonepe',
  merchant_reference text not null,
  environment text not null check (environment in ('sandbox','production')),
  onboarding_status text not null default 'pending',
  is_enabled boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null,
  order_id uuid not null,
  provider public.payment_provider not null default 'phonepe',
  provider_transaction_id text unique,
  merchant_reference text not null,
  amount_paise integer not null check (amount_paise >= 0),
  status public.payment_status not null default 'created',
  verified_at timestamptz,
  provider_response_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (order_id, theater_id) references public.orders(id, theater_id) on delete restrict,
  unique (id, theater_id)
);

create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null,
  payment_id uuid not null,
  amount_paise integer not null check (amount_paise > 0),
  status text not null default 'requested' check (status in ('requested','processing','succeeded','failed')),
  provider_refund_id text unique,
  created_at timestamptz not null default now(),
  foreign key (payment_id, theater_id) references public.payments(id, theater_id) on delete restrict
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  theater_id uuid not null unique references public.theaters(id) on delete cascade,
  plan_name text not null default 'pilot',
  status text not null default 'trial' check (status in ('trial','active','past_due','cancelled')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now()
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  theater_id uuid references public.theaters(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index orders_theater_created_idx on public.orders(theater_id, created_at desc);
create index orders_kitchen_queue_idx on public.orders(theater_id, status, created_at);
create index payments_theater_status_idx on public.payments(theater_id, status, created_at desc);
create index menu_items_theater_available_idx on public.menu_items(theater_id, is_available, sort_order);

create or replace function public.is_theater_member(target_theater uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.theater_members tm
    where tm.theater_id = target_theater and tm.user_id = auth.uid()
  );
$$;

create or replace function public.has_theater_role(target_theater uuid, allowed_roles public.member_role[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.theater_members tm
    where tm.theater_id = target_theater
      and tm.user_id = auth.uid()
      and tm.role = any(allowed_roles)
  );
$$;

alter table public.profiles enable row level security;
alter table public.theaters enable row level security;
alter table public.theater_members enable row level security;
alter table public.screens enable row level security;
alter table public.seats enable row level security;
alter table public.qr_codes enable row level security;
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.merchant_accounts enable row level security;
alter table public.payments enable row level security;
alter table public.refunds enable row level security;
alter table public.subscriptions enable row level security;
alter table public.audit_logs enable row level security;

create policy "profiles read self" on public.profiles for select to authenticated using (id = auth.uid());
create policy "profiles update self" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "theater members read own theaters" on public.theaters for select to authenticated using (public.is_theater_member(id));
create policy "members read own membership" on public.theater_members for select to authenticated using (user_id = auth.uid() or public.is_theater_member(theater_id));

create policy "members read screens" on public.screens for select to authenticated using (public.is_theater_member(theater_id));
create policy "managers manage screens" on public.screens for all to authenticated using (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[])) with check (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[]));

create policy "members read seats" on public.seats for select to authenticated using (public.is_theater_member(theater_id));
create policy "managers manage seats" on public.seats for all to authenticated using (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[])) with check (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[]));

create policy "members read qr" on public.qr_codes for select to authenticated using (public.is_theater_member(theater_id));
create policy "managers manage qr" on public.qr_codes for all to authenticated using (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[])) with check (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[]));

create policy "members read categories" on public.menu_categories for select to authenticated using (public.is_theater_member(theater_id));
create policy "managers manage categories" on public.menu_categories for all to authenticated using (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[])) with check (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[]));

create policy "members read menu" on public.menu_items for select to authenticated using (public.is_theater_member(theater_id));
create policy "managers manage menu" on public.menu_items for all to authenticated using (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[])) with check (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[]));

create policy "members read orders" on public.orders for select to authenticated using (public.is_theater_member(theater_id));
create policy "kitchen update order status" on public.orders for update to authenticated using (public.has_theater_role(theater_id, array['owner','manager','kitchen','staff']::public.member_role[])) with check (public.has_theater_role(theater_id, array['owner','manager','kitchen','staff']::public.member_role[]));

create policy "members read order items" on public.order_items for select to authenticated using (public.is_theater_member(theater_id));

create policy "owners read merchant account metadata" on public.merchant_accounts for select to authenticated using (public.has_theater_role(theater_id, array['owner']::public.member_role[]));
create policy "owners read payments" on public.payments for select to authenticated using (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[]));
create policy "owners read refunds" on public.refunds for select to authenticated using (public.has_theater_role(theater_id, array['owner','manager']::public.member_role[]));
create policy "owners read subscription" on public.subscriptions for select to authenticated using (public.has_theater_role(theater_id, array['owner']::public.member_role[]));
create policy "owners read audit logs" on public.audit_logs for select to authenticated using (public.has_theater_role(theater_id, array['owner']::public.member_role[]));

-- Intentionally no public INSERT/UPDATE policies on orders, payments, refunds, merchant_accounts.
-- Create these records through trusted server-side APIs / Supabase service role after validation.
-- Never ship the service-role key to the browser.
