-- =====================================================================
-- CareDesk · Facility Outreach — full setup
-- Run in your CareDesk MASTER Supabase project (the one CareDesk Pro uses):
--   Dashboard → SQL Editor → New query → paste all of this → Run.
-- Safe to run more than once. Every table starts with "outreach_" so nothing
-- in CareDesk Pro (caredesk_*) or the client systems is touched.
-- =====================================================================

create table if not exists public.outreach_contacts (
  id               bigint generated always as identity primary key,
  facility         text not null,
  category         text not null check (category in ('hospital','snf','rehab','memory_care','afh')),
  county           text,
  city             text,
  contact_name     text,
  role             text,
  email            text,
  email_note       text,
  phone            text,
  source           text,
  campaign         text,
  status           text not null default 'not_contacted'
                   check (status in ('not_contacted','in_sequence','replied','meeting','partner','do_not_contact')),
  last_contacted_at timestamptz,
  notes            text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table if not exists public.outreach_templates (
  id          bigint generated always as identity primary key,
  code        text unique,
  name        text not null,
  stage       int  not null default 1,
  categories  text[] not null default '{}',
  subject     text not null,
  body        text not null,
  sort_order  int  not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.outreach_email_log (
  id          bigint generated always as identity primary key,
  contact_id  bigint references public.outreach_contacts(id) on delete cascade,
  template_id bigint references public.outreach_templates(id) on delete set null,
  to_email    text not null,
  subject     text not null,
  body        text not null,
  image_url   text,
  opened_at   timestamptz not null default now()
);

create table if not exists public.outreach_settings (
  key   text primary key,
  value text
);

create table if not exists public.outreach_images (
  id          bigint generated always as identity primary key,
  name        text not null,
  caption     text,
  path        text not null,
  url         text not null,
  created_at  timestamptz not null default now()
);

create or replace function public.outreach_touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists outreach_contacts_touch on public.outreach_contacts;
create trigger outreach_contacts_touch before update on public.outreach_contacts
  for each row execute function public.outreach_touch_updated_at();
drop trigger if exists outreach_templates_touch on public.outreach_templates;
create trigger outreach_templates_touch before update on public.outreach_templates
  for each row execute function public.outreach_touch_updated_at();

-- ---------- Security ----------
-- The master anon key is shipped inside every client system CareDesk Pro generates,
-- so these tables are locked to SIGNED-IN users only (no anon access at all).
alter table public.outreach_contacts  enable row level security;
alter table public.outreach_templates enable row level security;
alter table public.outreach_email_log enable row level security;
alter table public.outreach_settings  enable row level security;
alter table public.outreach_images    enable row level security;

drop policy if exists "outreach auth contacts"  on public.outreach_contacts;
drop policy if exists "outreach auth templates" on public.outreach_templates;
drop policy if exists "outreach auth log"       on public.outreach_email_log;
drop policy if exists "outreach auth settings"  on public.outreach_settings;
drop policy if exists "outreach auth images"    on public.outreach_images;
create policy "outreach auth contacts"  on public.outreach_contacts  for all to authenticated using (true) with check (true);
create policy "outreach auth templates" on public.outreach_templates for all to authenticated using (true) with check (true);
create policy "outreach auth log"       on public.outreach_email_log for all to authenticated using (true) with check (true);
create policy "outreach auth settings"  on public.outreach_settings  for all to authenticated using (true) with check (true);
create policy "outreach auth images"    on public.outreach_images    for all to authenticated using (true) with check (true);

revoke all on public.outreach_contacts, public.outreach_templates, public.outreach_email_log,
              public.outreach_settings, public.outreach_images from anon;
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.outreach_contacts, public.outreach_templates,
  public.outreach_email_log, public.outreach_settings, public.outreach_images to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- ---------- Image bucket (public links so facilities can open shared pictures) ----------
insert into storage.buckets (id, name, public)
values ('outreach-images', 'outreach-images', true)
on conflict (id) do update set public = true;

drop policy if exists "outreach images: auth insert" on storage.objects;
drop policy if exists "outreach images: auth update" on storage.objects;
drop policy if exists "outreach images: auth delete" on storage.objects;
drop policy if exists "outreach images: auth select" on storage.objects;
create policy "outreach images: auth insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'outreach-images');
create policy "outreach images: auth update" on storage.objects
  for update to authenticated using (bucket_id = 'outreach-images') with check (bucket_id = 'outreach-images');
create policy "outreach images: auth delete" on storage.objects
  for delete to authenticated using (bucket_id = 'outreach-images');
create policy "outreach images: auth select" on storage.objects
  for select to authenticated using (bucket_id = 'outreach-images');

-- ---------- Sender settings (edit later in the app's Settings tab) ----------
insert into public.outreach_settings (key, value) values
  ('sender_name',   'Joseph Githaiga'),
  ('sender_title',  'Web Designer & Systems Builder for Care Facilities'),
  ('direct_line',   '+254 115 446 363'),
  ('gmail_account', 'jose.githaiga.njoroge@gmail.com'),
  ('portfolio_url', 'https://caredesk-site-one.vercel.app')
on conflict (key) do nothing;

-- make sure the live portfolio address is set even if settings already existed
update public.outreach_settings set value = 'https://caredesk-site-one.vercel.app'
where key = 'portfolio_url' and coalesce(value, '') = '';

-- ---------- Facility contacts (same list as the Golden Years referral system) ----------
-- Only seeds when the contacts table is empty, so re-running never duplicates.
insert into public.outreach_contacts (facility, category, county, city, contact_name, role, email, email_note, phone, source)
select * from (values
('Olympic View Post Acute', 'snf', 'Clallam', 'Port Angeles', 'Victor Odiakosa', 'Administrator: Victor Odiakosa (ask for Admissions / Social Services)', 'vodiakosa@olympicviewpa.com', null, '360-452-9206', 'whca.org/facility-finder/olympic-view-post-acute/; olympicviewpa.com/contact-us/ (email)'),
('Avamere Olympic Rehabilitation of Sequim', 'snf', 'Clallam', 'Sequim', null, 'Admissions', null, null, '360-582-3900', 'whca.org/facility-finder/avamere-olympic-rehabilitation-of-sequim/'),
('Sequim Bay Post Acute', 'snf', 'Clallam', 'Sequim', null, 'Admissions / facility contact (email listed on facility site)', 'ddeangelo@sequimbaypa.com', null, '360-582-2400', 'whca.org/facility-finder/sequim-bay-post-acute/; sequimbaypa.com/contact-us/ (email)'),
('Life Care Center of Port Townsend', 'snf', 'Jefferson', 'Port Townsend', 'Angela Cerna', 'Admissions (Exec. Director: Angela Cerna)', null, null, '360-385-3555', 'lcca.com/locations/wa/ ; WHCA Facility Finder (whca.org/facility-finder)'),
('Auburn Post Acute', 'snf', 'King', 'Auburn', 'Paul Foltz', 'Admissions (Administrator: Paul Foltz)', null, null, '253-833-1740', 'whca.org/facility-finder/auburn-post-acute/'),
('Canterbury House', 'snf', 'King', 'Auburn', 'Robert Wright', 'Admissions (Exec. Director: Robert Wright)', null, null, '253-939-0090', 'whca.org/facility-finder/canterbury-house/'),
('North Auburn Rehab & Health Center', 'snf', 'King', 'Auburn', 'Sinforosa Jumawan', 'Admissions (Administrator: Sinforosa Jumawan)', 'info@northauburncare.com', null, '253-561-8100', 'whca.org/facility-finder/north-auburn-rehab-health-center/; calderacare.com North Auburn page (email)'),
('Enumclaw Health and Rehabilitation Center', 'snf', 'King', 'Enumclaw', null, 'Admissions', 'info@empres.com', 'Empres corporate inbox', '360-825-2541', 'whca.org/facility-finder/enumclaw-health-and-rehabilitation-center/ (email in listing)'),
('Benson Heights Rehabilitation Center', 'snf', 'King', 'Kent', null, 'Admissions', null, null, '253-852-7755', 'whca.org/facility-finder/benson-heights-rehabilitation-center/'),
('Sharon Care Center', 'snf', 'Lewis', 'Centralia', 'Jonathan Blood', 'Admissions (Administrator: Jonathan Blood)', null, null, '360-736-0112', 'whca.org/facility-finder/sharon-care-center/'),
('South Creek Post Acute', 'snf', 'Lewis', 'Centralia', 'Andrea Harris', 'Admissions (Administrator: Andrea Harris)', null, null, '360-736-9384', 'whca.org/facility-finder/south-creek-post-acute/'),
('Three Rivers Care', 'snf', 'Lewis', 'Centralia', null, 'Admissions', 'info@threerivers.care', null, '360-736-2823', 'whca.org/facility-finder/three-rivers-care/; calderacare.com/?facility=three-rivers-care (email)'),
('Willapa Harbor Care', 'snf', 'Pacific', 'Raymond', null, 'Admissions', 'winfo@willapaharborcare.com', 'as listed on WHCA – confirm spelling', '360-942-2424', 'whca.org/facility-finder/willapa-harbor-care/ (email in listing)'),
('Cottesmore of Life Care', 'snf', 'Pierce', 'Gig Harbor', 'Ryan Lockwood', 'Admissions (Exec. Director: Ryan Lockwood)', null, null, '253-851-5433', 'lcca.com/locations/wa/ ; WHCA Facility Finder (whca.org/facility-finder)'),
('Gig Harbor Health and Rehabilitation', 'snf', 'Pierce', 'Gig Harbor', 'Christine Miller', 'Admissions (Administrator: Christine Miller)', null, null, '253-858-8688', 'whca.org/facility-finder/gig-harbor-health-and-rehabilitation/'),
('Alaska Gardens Health and Rehab', 'snf', 'Pierce', 'Tacoma', null, 'Admissions', null, null, '253-476-5300', 'WHCA Facility Finder (whca.org/facility-finder)'),
('Avalon Healthcare – Tacoma', 'snf', 'Pierce', 'Tacoma', null, 'Admissions', null, null, '253-474-8456', 'whca.org/facility-finder/avalon-healthcare-tacoma/'),
('Avamere Transitional Care of Puget Sound', 'snf', 'Pierce', 'Tacoma', 'Ike Ologi', 'Admissions (Administrator: Ike Ologi)', null, null, '253-671-7300', 'whca.org/facility-finder/avamere-transitional-care-of-puget-sound/'),
('Avamere at Pacific Ridge', 'snf', 'Pierce', 'Tacoma', null, 'Admissions', null, null, '253-475-2507', 'WHCA Facility Finder (whca.org/facility-finder)'),
('Birch Creek Post Acute and Rehabilitation', 'snf', 'Pierce', 'Tacoma', 'Sharon Holmes', 'Admissions (Administrator: Sharon Holmes)', null, null, '253-474-8421', 'whca.org/facility-finder/birch-creek-post-acute-and-rehabilitation/; facility site'),
('Heartwood Extended Health Care', 'snf', 'Pierce', 'Tacoma', 'Yaya Ly', 'Admissions (Administrator: Yaya Ly)', null, null, '253-472-9027', 'whca.org/facility-finder/heartwood-extended-health-care/'),
('Orchard Park Health Care Center', 'snf', 'Pierce', 'Tacoma', 'Kimberly Harris', 'Admissions (Administrator: Kimberly Harris)', null, null, '253-475-4611', 'whca.org/facility-finder/orchard-park-health-care-center/'),
('Park Rose Care Center', 'snf', 'Pierce', 'Tacoma', 'Teresa Andree', 'Admissions (Exec. Director: Teresa Andree)', null, null, '253-752-5677', 'whca.org/facility-finder/park-rose-care-center/'),
('Tacoma Nursing and Rehabilitation Center', 'snf', 'Pierce', 'Tacoma', 'Damen Diaz', 'Admissions (Administrator: Damen Diaz)', null, null, '253-581-2514', 'whca.org/facility-finder/tacoma-nursing-and-rehabilitation-center/'),
('Agility Health and Rehab', 'snf', 'Pierce', 'University Place', 'Lawrence Shurman', 'Admissions (Administrator: Lawrence Shurman)', null, null, '253-566-7166', 'whca.org/facility-finder/agility-health-and-rehab/'),
('Crystal Cove Post Acute', 'snf', 'Thurston', 'Lacey', 'Emeka Nwankwo', 'Admissions (Administrator: Emeka Nwankwo)', null, null, '360-491-1765', 'whca.org/facility-finder/crystal-cove-post-acute/'),
('Lacey Post Acute and Rehabilitation', 'snf', 'Thurston', 'Lacey', 'Elizabeth Fachting', 'Admissions (Administrator: Elizabeth Fachting)', null, null, '360-491-9890', 'whca.org/facility-finder/lacey-post-acute-and-rehabilitation/'),
('Olympia Transitional Care and Rehabilitation', 'snf', 'Thurston', 'Olympia', null, 'Admissions', 'contact-Olympia@ensignservices.net', null, '360-491-9700', 'whca.org/facility-finder/olympia-transitional-care-and-rehabilitation/ (email in listing)'),
('Puget Sound Health Care Center (Puget Sound Care)', 'snf', 'Thurston', 'Olympia', null, 'Admissions', 'info@pugetsound.care', null, '360-754-9792', 'whca.org/facility-finder/puget-sound-health-care-center/; calderacare.com/?facility=puget-sound-care (email)'),
('Regency Olympia Rehabilitation & Nursing Center', 'snf', 'Thurston', 'Olympia', 'Brittany Nwankwo', 'Admissions (Administrator: Brittany Nwankwo)', null, null, '360-943-0910', 'whca.org/facility-finder/regency-olympia/'),
('Woodard Creek Health & Rehabilitation', 'snf', 'Thurston', 'Olympia', 'Austin Hoeft', 'Admissions (Administrator: Austin Hoeft)', null, null, '360-493-4900', 'whca.org/facility-finder/woodard-creek-health-rehabilitation/; facility site'),
('Laurel Place AL & Memory Care (Caring Places)', 'memory_care', 'Clallam', 'Port Angeles', null, 'Admissions / Administrator', 'laurelplace@caringplaces.com', null, '360-452-7201', 'caringplaces.com/communities/laurel-place/'),
('Dungeness Courte Memory Care', 'memory_care', 'Clallam', 'Sequim', 'Andrea Magill', 'Executive Director: Andrea Magill', null, null, '360-582-9309', 'northwestcare.com; whca.org/facility-finder/dungeness-courte-alzheimers-community/'),
('Fifth Avenue (Sherwood family – assisted living; memory care not confirmed)', 'memory_care', 'Clallam', 'Sequim', null, 'Admissions', 'info@thefifthavenue.com', null, '360-683-3345', 'sherwoodassistedliving.com/contact-us/'),
('Sherwood Assisted Living (memory care)', 'memory_care', 'Clallam', 'Sequim', null, 'Admissions', 'info@sherwoodassistedliving.com', null, '360-683-3348', 'sherwoodassistedliving.com/contact-us/'),
('The Lodge at Sherwood Village (Sherwood family – assisted living; memory care not confirmed)', 'memory_care', 'Clallam', 'Sequim', null, 'Admissions', 'info@thelodgeatsherwood.com', null, '360-681-3100', 'sherwoodassistedliving.com/contact-us/'),
('San Juan Villa Memory Care', 'memory_care', 'Jefferson', 'Port Townsend', null, 'Admissions', 'sanjuanvilla@caringplaces.com', null, '360-344-3114', 'caringplaces.com/communities/san-juan-villa/'),
('Cascade Place AL & Memory Care (Caring Places)', 'memory_care', 'King', 'Enumclaw', null, 'Admissions / Administrator', 'cascadeplace@caringplaces.com', null, '360-802-0177', 'caringplaces.com/communities/cascade-place/'),
('Brookdale Foundation House (Clare Bridge)', 'memory_care', 'King', 'Federal Way', null, 'Sales / Admissions', null, null, '253-838-8823', 'brookdale.com community page'),
('Centralia Point Assisted Living and Memory Care', 'memory_care', 'Lewis', 'Centralia', 'Jeremiah Rosellini', 'Executive Director: Jeremiah Rosellini', null, null, '360-330-2010', 'whca.org/facility-finder/centralia-point-assisted-living-and-memory-care/'),
('Heritage House Morton AL & Memory Care (Caring Places)', 'memory_care', 'Lewis', 'Morton', null, 'Admissions / Administrator', 'heritagehousemorton@caringplaces.com', null, '360-496-6699', 'caringplaces.com/communities/heritage-house-morton/'),
('Heritage House Buckley AL & Memory Care (Caring Places)', 'memory_care', 'Pierce', 'Buckley', null, 'Admissions / Administrator', 'heritagehousebuckley@caringplaces.com', null, '360-829-5292', 'caringplaces.com/communities/heritage-house-buckley/'),
('Gig Harbor Court (Pegasus Senior Living)', 'memory_care', 'Pierce', 'Gig Harbor', null, 'Community Relations / Admissions', null, null, '253-858-5300', 'pegasusseniorliving.com'),
('Greenlake Senior Living – Gig Harbor Memory Care', 'memory_care', 'Pierce', 'Gig Harbor', null, 'Executive Director', 'ed.gigharbor@greenlakeseniorliving.com', null, '253-851-5306', 'greenlakeseniorliving.com/communities/gig-harbor/'),
('Bonaventure of Puyallup', 'memory_care', 'Pierce', 'Puyallup', null, 'Community Relations / Admissions', 'info@bonaventuresenior.com', 'company-wide', '253-387-8166', 'bonaventuresenior.com'),
('Brookdale Puyallup South (Clare Bridge)', 'memory_care', 'Pierce', 'Puyallup', null, 'Sales / Admissions', null, null, '253-445-1300', 'brookdale.com community page'),
('Deer Ridge (Koelsch Communities)', 'memory_care', 'Pierce', 'Puyallup', 'Shawn Brooks', 'Executive Director: Shawn Brooks', null, null, '253-446-7892', 'koelschseniorcommunities.com (Deer Ridge page)'),
('Fieldstone Memory Care of Puyallup', 'memory_care', 'Pierce', 'Puyallup', null, 'Community Relations / Admissions', null, null, '253-447-5506', 'fieldstonecommunities.com/puyallupmemorycare (via LeadingAge WA whereyoulivematters.org)'),
('The Rivers at Puyallup (Pegasus Senior Living)', 'memory_care', 'Pierce', 'Puyallup', null, 'Community Relations / Admissions', null, null, '253-848-1234', 'pegasusseniorliving.com'),
('Memory Haven', 'memory_care', 'Pierce', 'Sumner', null, 'Admissions', null, null, '253-750-0552', 'memoryhavensumner.com'),
('Franke Tobey Jones Care Center (memory care)', 'memory_care', 'Pierce', 'Tacoma', 'Michelle Olafson', 'Admissions: Michelle Olafson', 'chall@franketobeyjones.com', 'listed ''Email Us'' contact', '253-756-6251 (admissions); main 253-752-6621', 'franketobeyjones.com/contact/request-info/'),
('Spring Ridge Assisted Living & Memory Care', 'memory_care', 'Pierce', 'Tacoma', null, 'Community Liaison', 'communityliaison@springridgealmc.com', null, '253-474-1093', 'springridgealmc.com/contact-us-spring-ridge/'),
('The Village Senior Living', 'memory_care', 'Pierce', 'Tacoma', null, 'Admissions', null, null, '253-302-8277', 'thevillage-tacoma.com'),
('Hearthside Manor Memory Care (Caring Places)', 'memory_care', 'Pierce', 'University Place', null, 'Admissions / Administrator', 'hearthsidemanor@caringplaces.com', null, '253-460-3330', 'caringplaces.com/communities/hearthside-manor/'),
('Greenlake Senior Living – Lacey Memory Care', 'memory_care', 'Thurston', 'Lacey', null, 'Executive Director / Community Relations Director', 'ed.lacey@greenlakeseniorliving.com', 'Executive Director', '564-669-7060', 'greenlakeseniorliving.com/communities/lacey/ (1420 Carpenter Rd SE)'),
('Brookdale Olympia West (Clare Bridge)', 'memory_care', 'Thurston', 'Olympia', null, 'Sales / Admissions', null, null, '360-236-1400', 'brookdale.com community page'),
('Garden Courte Memory Care', 'memory_care', 'Thurston', 'Olympia', null, 'Community Relations Director', 'Crd@gardencourtemc.com', 'Community Relations Director); also ed@gardencourtemc.com (Executive Director', '360-491-4435', 'gardencourtemc.com/contact-us-garden-courte-memory-care/ (626 Lilly Rd NE)'),
('Easthaven Villa AL & Memory Care (Caring Places)', 'memory_care', 'Thurston', 'Yelm', null, 'Admissions / Administrator', 'easthavenvilla@caringplaces.com', null, '360-458-2800', 'caringplaces.com/communities/easthaven-villa'),
('Connecting Links Adult Family Home', 'afh', 'Clallam', 'Forks', null, 'Provider / Owner', null, null, '360-374-2044', 'Adult Family Home Council directory, DSHS lic. #464000 (adultfamilyhomecouncil.org/home-finder/464000-connecting-links-adult-family-home)'),
('Asis Adult Family Home', 'afh', 'Clallam', 'Sequim', null, 'Provider / Owner', null, null, '360-477-4391', 'Adult Family Home Council directory, DSHS lic. #754652 (adultfamilyhomecouncil.org/home-finder/754652-asis)'),
('Robin''s Nest Adult Family Home (physician-owned)', 'afh', 'Clallam', 'Sequim', null, 'Provider / Owner', 'KrohsNestAFH@gmail.com', null, '360-477-2772', 'robinsnestafh.com (home''s own site)'),
('Angels of Joy Adult Family Home', 'afh', 'King', 'Auburn', null, 'Provider / Owner', 'angelsofjoyllc@gmail.com', null, '253-802-3453', 'angelsofjoyadultfamilyhome.com/contact-us (home''s own website; confirm license in DSHS AFH Locator)'),
('Aliceville Adult Family Homes (Auburn + Federal Way)', 'afh', 'King', 'Auburn / Federal Way', null, 'Provider / Owner', 'alicevilleafh@gmail.com', null, '206-335-1351', 'alicevilleadultfamilyhomes.com/contact (home''s own website; confirm license in DSHS AFH Locator)'),
('ABINAT Adult Family Home', 'afh', 'King', 'Covington', null, 'Provider / Owner', 'abinatcare@gmail.com', null, '206-859-7903', 'abinatafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('AAA Loving Care Adult Family Home LLC', 'afh', 'King', 'Des Moines', null, 'Provider / Owner', null, null, '206-335-9142', 'Adult Family Home Council directory, DSHS lic. #753655 (adultfamilyhomecouncil.org/home-finder/753655-aaa-loving-care-adult-family-home-llc)'),
('Angel Wings Senior Care Homes (3 homes)', 'afh', 'King', 'Des Moines', null, 'Provider / Owner', 'info@angelwingshome.com', null, '206-407-8137', 'angelwingshome.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Acclaimed Care AFH LLC (2 homes)', 'afh', 'King', 'Federal Way', null, 'Provider / Owner', 'provider@acafh.com', null, '253-350-3104', 'acafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Evolving Grace Adult Family Home', 'afh', 'King', 'Federal Way', null, 'Provider / Owner', 'info@evolvinggraceafh.com', null, '253-987-6451', 'evolvinggraceafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Golden Hearts Adult Family Home', 'afh', 'King', 'Federal Way', null, 'Provider / Owner', 'goldenheartsadultfamilyhome@gmail.com', null, '206-799-6341', 'goldenheartsafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Lourdes Loving Care AFH LLC', 'afh', 'King', 'Federal Way', null, 'Provider / Owner', null, null, '253-839-1369', 'Adult Family Home Council directory, DSHS lic. #753737 (adultfamilyhomecouncil.org/home-finder/753737-lourdes-loving-care-afh-llc)'),
('Miles Adult Family Home', 'afh', 'King', 'Federal Way', null, 'Provider / Owner', null, null, '253-737-8605', 'Adult Family Home Council directory, DSHS lic. #750457 (adultfamilyhomecouncil.org/home-finder/750457-miles-adult-family-home)'),
('Woodridge Adult Family Home LLC', 'afh', 'King', 'Federal Way', null, 'Provider / Owner', null, null, '253-517-7769', 'Adult Family Home Council directory, DSHS lic. #755941 (adultfamilyhomecouncil.org/home-finder/755941-woodridge-adult-family-home-llc)'),
('Himalayan Comfort AFH LLC', 'afh', 'King', 'Kent', null, 'Provider / Owner', 'himalayancomfortafhllc@gmail.com', null, '253-277-1310', 'himalayancomfortafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Lumeracare AFH LLC', 'afh', 'King', 'Kent', null, 'Provider / Owner', null, null, '206-291-0915', 'Adult Family Home Council directory, DSHS lic. #759090 (adultfamilyhomecouncil.org/home-finder/759090-lumeracare-afh-llc)'),
('Pristine House AFH (Kent + Renton)', 'afh', 'King', 'Kent / Renton', null, 'Provider / Owner', 'info@pristinehouseafh.com', null, '425-496-4238', 'pristinehouseafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Beloved AFH', 'afh', 'Lewis', 'Centralia', null, 'Provider / Owner', null, null, '360-669-0806', 'Adult Family Home Council directory, DSHS lic. #756436 (adultfamilyhomecouncil.org/home-finder/756436-beloved-afh)'),
('A Curtis Hill Estate Senior Living LLC', 'afh', 'Lewis', 'Chehalis', null, 'Provider / Owner', null, null, '360-789-5773', 'Adult Family Home Council directory, DSHS lic. #759241 (adultfamilyhomecouncil.org/home-finder/759241-a-curtis-hill-estate-senior-living-llc)'),
('Silver Acres LLC (nurse/EMT-owned)', 'afh', 'Lewis', 'Chehalis', null, 'Provider / Owner', null, null, '360-206-0861', 'Adult Family Home Council directory, DSHS lic. #754409 (adultfamilyhomecouncil.org/home-finder/754409-silver-acres-llc)'),
('Bonney Lake Palace', 'afh', 'Pierce', 'Bonney Lake', null, 'Provider / Owner', null, null, '515-770-1626', 'Adult Family Home Council directory, DSHS lic. #756585 (adultfamilyhomecouncil.org/home-finder/756585-bonney-lake-palace)'),
('Favorite Adult Family Home', 'afh', 'Pierce', 'Bonney Lake', null, 'Provider / Owner', 'favoriteafh@gmail.com', null, '206-657-6121', 'favoriteafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Islandview Adult Family Home LLC', 'afh', 'Pierce', 'Gig Harbor', null, 'Provider / Owner', null, null, '206-556-5391', 'Adult Family Home Council directory, DSHS lic. #756331 (adultfamilyhomecouncil.org/home-finder/756331-islandview-adult-family-home-llc)'),
('Affordable Oakbrook (senior care home)', 'afh', 'Pierce', 'Lakewood', null, 'Provider / Owner', 'affordableoakbrook@gmail.com', null, '253-238-6218', 'affordableoakbrook.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Angel of Mercy Adult Family Home LLC', 'afh', 'Pierce', 'Lakewood', null, 'Provider / Owner', null, null, '253-212-1919', 'Adult Family Home Council directory, DSHS lic. #753907 (adultfamilyhomecouncil.org/home-finder/753907-angel-of-mercy-adult-family-home-llc)'),
('Family Love Adult Family Home LLC', 'afh', 'Pierce', 'Lakewood', null, 'Provider / Owner', null, null, '253-678-2630', 'Adult Family Home Council directory, DSHS lic. #753977 (adultfamilyhomecouncil.org/home-finder/753977-family-love-adult-family-home-llc)'),
('The Young House Adult Family Home (Lakewood/Tacoma + Spanaway)', 'afh', 'Pierce', 'Lakewood / Spanaway', null, 'Provider / Owner', 'theyounghouseafh@gmail.com', null, '360-910-8919', 'theyounghouseafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('A Loving Home Adult Family Home and Hospice LLC', 'afh', 'Pierce', 'Puyallup', null, 'Provider / Owner', 'alovinghomeafh@gmail.com', null, '253-268-0598', 'alovinghomeafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Home Life Care Adult Family Home', 'afh', 'Pierce', 'Puyallup', null, 'Provider / Owner', 'info@homelifecareafh.com', null, '253-678-0583', 'homelifecareafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Reimagine Adult Family Home Puyallup', 'afh', 'Pierce', 'Puyallup', null, 'Provider / Owner', null, null, '253-848-4842', 'Adult Family Home Council directory, DSHS lic. #758121 (adultfamilyhomecouncil.org/home-finder/758121-reimagine-adult-family-home-puyallup)'),
('Silver Creek Adult Family Home', 'afh', 'Pierce', 'Puyallup', null, 'Provider / Owner', 'silvercreekafh@gmail.com', null, '253-258-5432', 'silvercreekafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('A Heart and Soul AFH LLC', 'afh', 'Pierce', 'Puyallup (South Hill)', null, 'Provider / Owner', 'aheartandsoulafh@yahoo.com', null, '253-446-6707 (office); 210-693-4081 (cell)', 'aheartandsoulafh.com; AFH Council lic. #756917'),
('Senior Care Inn Adult Family Homes (5 homes: Puyallup x3, Bonney Lake, Kent)', 'afh', 'Pierce', 'Puyallup / Bonney Lake (+ King – Kent)', null, 'Owner / Main office', 'seniorcareinn@gmail.com', null, '253-486-8866 (main)', 'seniorcareafh.com/contact-us (home''s own website; confirm license in DSHS AFH Locator)'),
('Caring Arms Adult Family Homes (multi-site: Bonney Lake, Sumner, Puyallup, Federal Way, Kent, Des Moines)', 'afh', 'Pierce', 'Sumner / Bonney Lake / Puyallup (+ King)', null, 'Owner / Main office', 'caringarmsadultfamilyhomes@gmail.com', null, '253-334-5383', 'caringarmsadultfamilyhomes.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Grateful Hearts Care Home LLC', 'afh', 'Pierce', 'Tacoma', null, 'Provider / Owner', null, null, '206-347-6080', 'Adult Family Home Council directory, DSHS lic. #755415 (adultfamilyhomecouncil.org/home-finder/755415-grateful-hearts-care-home-llc)'),
('The Arbor Rose Adult Family Homes (2 homes)', 'afh', 'Pierce', 'Tacoma', null, 'Provider / Owner', 'tstimach@comcast.net', null, '206-355-5643', 'aradultfamilyhomes.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Good Neighborhood AFH 2', 'afh', 'Pierce', 'University Place', null, 'Provider / Owner', 'goodneighborhoodafh@gmail.com', null, '253-201-1565', 'goodneighborhoodafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Alexandy AFH', 'afh', 'Thurston', 'Lacey', null, 'Provider / Owner', null, null, '564-250-6226', 'Adult Family Home Council directory, DSHS lic. #759157 (adultfamilyhomecouncil.org/home-finder/759157-alexandy-afh)'),
('Quality Care Adult Family Home – Olympia Inc', 'afh', 'Thurston', 'Lacey', null, 'Provider / Owner', null, null, '360-357-9842', 'Adult Family Home Council directory, DSHS lic. #751304 (adultfamilyhomecouncil.org/home-finder/751304-quality-care-adult-family-home-olympia-inc)'),
('Triumphant AFH LLC', 'afh', 'Thurston', 'Lacey', null, 'Provider / Owner', null, null, '360-915-6308', 'Adult Family Home Council directory, DSHS lic. #759254 (adultfamilyhomecouncil.org/home-finder/759254-triumphant-afh-llc)'),
('Attentive Senior Care of St. Catherine', 'afh', 'Thurston', 'Olympia', null, 'Provider / Owner', null, null, '808-216-8105', 'Adult Family Home Council directory, DSHS lic. #759038 (adultfamilyhomecouncil.org/home-finder/759038-attentive-senior-care-of-st-catherine)'),
('Bethany Adult Family Home', 'afh', 'Thurston', 'Olympia', null, 'Provider / Owner', 'bethanyafh@yahoo.com', 'also garyweston11@yahoo.com', '360-866-3935', 'bethanyadultfamilyhome.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Evergreen Haven Adult Family Home', 'afh', 'Thurston', 'Olympia', null, 'Provider / Owner', 'evergreenhavenafh@gmail.com', null, '360-791-5277', 'evergreenhavenafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Olympia Adult Family Home LLC', 'afh', 'Thurston', 'Olympia', null, 'Provider / Owner', null, null, '240-423-9346', 'Adult Family Home Council directory, DSHS lic. #756114 (adultfamilyhomecouncil.org/home-finder/756114-olympia-adult-family-home-llc)'),
('Olympia Senior Care', 'afh', 'Thurston', 'Olympia', null, 'Provider / Owner', 'hello@olympiaseniorcarehome.com', null, '360-968-9752', 'olympiaseniorcarehome.com (DSHS lic. #759298 shown on site)'),
('Radiant Living Family Care LLC', 'afh', 'Thurston', 'Olympia', null, 'Provider / Owner', null, null, '360-915-6947', 'Adult Family Home Council directory, DSHS lic. #758117 (adultfamilyhomecouncil.org/home-finder/758117-radiant-living-family-care-llc)'),
('Elite Homes for Senior Living (Olympia x2, Tumwater, Chehalis)', 'afh', 'Thurston', 'Olympia (+ Lewis – Chehalis)', null, 'Owner', 'info@elitehomesforseniorliving.com', null, '314-814-0674', 'elitehomesforseniorliving.com (home''s own website; confirm license in DSHS AFH Locator)'),
('The Dada''s Adult Family Homes (8 homes, Olympia & Lacey)', 'afh', 'Thurston', 'Olympia / Lacey', null, 'Owner', 'joycejohn16@yahoo.com', null, '269-823-2827', 'thedadasafh.com (home''s own website; confirm license in DSHS AFH Locator)'),
('Olympic Medical Center', 'hospital', 'Clallam', 'Port Angeles', null, 'Case Management – no direct line published; ask operator for Care Management / Case Management', null, null, '360-417-7000 (main)', 'olympicmedical.org/provider-resources/'),
('Jefferson Healthcare', 'hospital', 'Jefferson', 'Port Townsend', null, 'Social Services – ask operator (per hospital site)', null, null, '360-385-2200 (main)', 'jeffersonhealthcare.org'),
('MultiCare Auburn Medical Center', 'hospital', 'King', 'Auburn', null, 'Social Work', null, null, '253-545-2535 (Social Work); main 253-833-7711', 'multicare.org Auburn Medical Center phone directory'),
('St. Elizabeth Hospital (VMFH)', 'hospital', 'King', 'Enumclaw', null, 'Care Management / Social Work – no direct line published; ask operator for Care Management / Case Management', null, null, '360-802-8800 (main)', 'vmfh.org/our-hospitals/st-elizabeth-hospital'),
('St. Francis Hospital (VMFH)', 'hospital', 'King', 'Federal Way', null, 'Care Management / Social Work – no direct line published; ask operator for Care Management / Case Management', null, null, '253-944-8100 (main); Admitting 253-944-7969', 'vmfh.org/our-hospitals/st-francis-hospital/contact-us'),
('Valley Medical Center (UW Medicine)', 'hospital', 'King', 'Renton', null, 'Case Management – no direct line published; ask operator for Care Management / Case Management', null, null, '425-690-1000 (main)', 'valleymed.org'),
('Swedish First Hill (Providence Swedish)', 'hospital', 'King', 'Seattle', null, 'Case Management – no direct line published; ask operator for Care Management / Case Management', null, null, '206-386-6000 (main)', 'swedish.org/locations/first-hill-campus'),
('Virginia Mason Medical Center (VMFH)', 'hospital', 'King', 'Seattle', null, 'Care Management – no direct line published; ask operator for Care Management / Case Management', null, 'Only published address is an HIE Direct (secure clinical) address, VMMC_WA_Clinician_Referral_Team@direct.commonspirit.org, which is not for marketing email; call instead', '206-624-1144 (main)', 'vmfh.org/our-hospitals/virginia-mason-medical-center; vmfh.org/resources/refer-a-patient'),
('Providence Centralia Hospital', 'hospital', 'Lewis', 'Centralia', null, 'Case Management / Social Services – no direct line published; ask operator for Care Management / Case Management', null, null, '360-736-2803 (main)', 'providence.org/locations/wa/centralia-hospital'),
('Ocean Beach Health (Ocean Beach Hospital)', 'hospital', 'Pacific', 'Ilwaco', null, 'Case Management – no direct line published; ask operator for Care Management / Case Management', 'customer.service@oceanbeachhospital.com', 'general inbox', '360-642-3181 (main)', 'oceanbeachhealth.com'),
('Willapa Harbor Hospital', 'hospital', 'Pacific', 'South Bend', null, 'Case Management – no direct line published; ask operator for Care Management / Case Management', null, null, '360-875-5526 (main)', 'turquoise.health listing – VERIFY on willapaharborhospital.com before calling'),
('St. Anthony Hospital (VMFH)', 'hospital', 'Pierce', 'Gig Harbor', null, 'Care Management / Social Work – no direct line published; ask operator for Care Management / Case Management', null, null, '253-530-2000 (main)', 'vmfh.org/our-hospitals/st-anthony-hospital'),
('St. Clare Hospital (VMFH)', 'hospital', 'Pierce', 'Lakewood', null, 'Care Management / Social Work – no direct line published; ask operator for Care Management / Case Management', null, null, '253-985-1711 (main); Admitting 253-985-6966', 'vmfh.org/our-hospitals/st-clare-hospital/contact-us'),
('MultiCare Good Samaritan Hospital', 'hospital', 'Pierce', 'Puyallup', null, 'Social Work', null, null, '253-697-1517 (Social Work); main 253-697-4000', 'multicare.org Good Samaritan phone directory'),
('MultiCare Allenmore Hospital', 'hospital', 'Pierce', 'Tacoma', null, 'Social Work', null, null, '253-403-1126 (Social Work, shared w/ Tacoma General); main 253-459-6200', 'multicare.org Allenmore phone directory'),
('MultiCare Tacoma General Hospital', 'hospital', 'Pierce', 'Tacoma', null, 'Social Work', null, null, '253-403-1126 (Social Work); main 253-403-1000', 'multicare.org Tacoma General phone directory'),
('St. Joseph Medical Center (Virginia Mason Franciscan Health)', 'hospital', 'Pierce', 'Tacoma', null, 'Care Management / Social Work – no direct line published; ask operator for Care Management / Case Management', null, null, '253-426-4101 (main); Admitting 253-426-6676', 'vmfh.org/our-hospitals/st-joseph-medical-center/contact-us'),
('MultiCare Capital Medical Center', 'hospital', 'Thurston', 'Olympia', null, 'Case Management / Social Work – no direct line published; ask operator for Care Management / Case Management', null, null, '360-754-5858 (main)', 'multicare.org Capital Medical Center phone directory'),
('Providence St. Peter Hospital', 'hospital', 'Thurston', 'Olympia', null, 'Case Management / Social Services – no direct line published; ask operator for Care Management / Case Management', null, null, '360-491-9480 (main)', 'providence.org/locations/wa/st-peter-hospital/contact-us'),
('Avalon Care Center – Federal Way', 'rehab', 'King', 'Federal Way', 'Samantha Wachowski', 'Social Services Director / Admissions (no named social worker published – ask by title) – Administrator: Samantha Wachowski', null, null, '253-835-7453', 'whca.org/facility-finder/avalon-care-center-federal-way/'),
('Garden Terrace Healthcare Center of Federal Way', 'rehab', 'King', 'Federal Way', 'Megan Larson', 'Social Services Director / Admissions (no named social worker published – ask by title) – Exec. Director: Megan Larson', null, null, '253-661-2226 (fax 253-661-2327)', 'whca.org/facility-finder/garden-terrace-healthcare-center-snf/; lcca.com'),
('Hallmark Manor', 'rehab', 'King', 'Federal Way', 'Rosie Velasco', 'Social Services Director / Admissions (no named social worker published – ask by title) – Exec. Director: Rosie Velasco', null, null, '253-874-3580 (fax 253-661-8501)', 'whca.org/facility-finder/hallmark-manor/'),
('Life Care Center of Federal Way', 'rehab', 'King', 'Federal Way', null, 'Social Services Director / Admissions (no named social worker published – ask by title)', null, null, '253-946-2273 (fax 253-946-8673)', 'lcca.com/locations/wa/federal-way/'),
('The Oaks at Lakewood', 'rehab', 'Pierce', 'Lakewood (near St. Clare)', 'Mindy Bradley', 'Social Services Director / Admissions (no named social worker published – ask by title) – Exec. Director: Mindy Bradley', 'contact-OaksLakewood@ensignservices.net', null, '253-581-9002', 'oakslakewood.com; whca.org/facility-finder/the-oaks-at-lakewood/'),
('Good Samaritan Inpatient Rehabilitation Center (MultiCare)', 'rehab', 'Pierce', 'Puyallup', null, 'Inpatient rehab unit – ask for unit social worker / case manager', null, null, '253-697-5192 (fax 253-697-5188)', 'multicare.org/services/rehabilitation/inpatient-service/gs/'),
('Life Care Center of Puyallup', 'rehab', 'Pierce', 'Puyallup', 'Moussa Compaore', 'Social Services Director / Admissions (no named social worker published – ask by title) – Exec. Director: Moussa Compaore', null, null, '253-845-7566 (fax 253-845-3386)', 'lcca.com/locations/wa/puyallup/'),
('Life Care Center of South Hill', 'rehab', 'Pierce', 'Puyallup', null, 'Social Services Director / Admissions (no named social worker published – ask by title)', null, null, '253-841-6600', 'lcca.com/locations/wa/ ; WHCA Facility Finder (whca.org/facility-finder)'),
('Linden Grove Health Care Center', 'rehab', 'Pierce', 'Puyallup', 'Bob Rowe', 'Social Services Director / Admissions (no named social worker published – ask by title) – Administrator: Bob Rowe', null, null, '253-840-4400 (fax 253-840-6733)', 'whca.org/facility-finder/linden-grove-center/; facility site'),
('Puyallup Post Acute', 'rehab', 'Pierce', 'Puyallup', 'William Jenkins', 'Social Services Director / Admissions (no named social worker published – ask by title) – Administrator: William Jenkins', null, null, '253-845-6631 (fax 253-770-1945)', 'whca.org/facility-finder/puyallup-post-acute/'),
('Rainier Rehabilitation', 'rehab', 'Pierce', 'Puyallup', 'Brett Watson', 'Social Services Director / Admissions (no named social worker published – ask by title) – Exec. Director: Brett Watson', 'contact-Rainier@ensignservices.net', null, '253-841-3422 (fax 253-848-3937)', 'whca.org/facility-finder/rainier-rehabilitation/; rainierrehabilitation.com/contact-us/ (email)'),
('Virginia Mason Franciscan Health Rehabilitation Hospital', 'rehab', 'Pierce', 'Tacoma (serves St. Joseph/St. Clare/St. Francis)', null, 'Admissions / Clinical Liaison; ask for case management', null, null, '253-444-3320', 'vmfhrehabhospital.com')) as v(facility, category, county, city, contact_name, role, email, email_note, phone, source)
where not exists (select 1 from public.outreach_contacts);

-- Only facilities with an email address are used for outreach
delete from public.outreach_contacts where coalesce(trim(email), '') = '';


-- ---------- Email templates: website & systems outreach ----------
-- Placeholders filled automatically per facility: {first_name} {facility} {city} {county}
-- {client_noun} {category_line} {portfolio_link} {portfolio_url} {whatsapp} {whatsapp_link} {signature} {previous_subject}
-- {portfolio_link} / {whatsapp_link} become the clickable words "Portfolio" / "WhatsApp" when you paste the email into Gmail.
-- Anything else in {braces} becomes a fill-in box before you send (e.g. {day_option_1}).
insert into public.outreach_templates (code, name, stage, categories, subject, body, sort_order) values

('1A', 'Introduction – website & systems', 1, '{hospital,snf,rehab,memory_care}',
$s$A modern website for {facility}$s$,
$b$Hi {first_name},

My name is Joseph Githaiga. I design websites and build management systems for care facilities, and I work remotely with clients across the US, including several in Washington State.

Recently I built the websites and the home care management system for Golden Years Home Care and Golden Years Home Health in Sumner, and the website for Harmony Living House, an adult family home in Chehalis. I'd like to do the same for {facility}.

{category_line}

Click my {portfolio_link} to see the live projects.

Would you be open to a 15-minute call to talk it through? I schedule calls on Pacific time, and if it's easier you can message me on {whatsapp_link} at {whatsapp}.

Best regards,

{signature}
$b$, 1),

('1B', 'Introduction – adult family homes (care system)', 1, '{afh}',
$s$Less paperwork at {facility}$s$,
$b$Hi {first_name},

My name is Joseph Githaiga. I build websites and care-management systems for adult family homes, and I work remotely with care homes across the US.

The system I've built for AFHs keeps resident records, progress notes, vitals, medications, incident reports and caregiver credentials in one place. Caregivers can chart from a phone, and you can print DSHS-style forms and reports whenever you need them. I also built the RN management system Golden Years Home Health uses for nurse delegation, and the website for Harmony Living House in Chehalis.

Click my {portfolio_link} to see the work.

Would a short demo be useful? I'm happy to show you on a 15-minute video call, or you can message me on {whatsapp_link} at {whatsapp}.

Best regards,

{signature}
$b$, 2),

('2A', 'Value follow-up – free homepage sketch (day 4)', 2, '{}',
$s$Re: {previous_subject}$s$,
$b$Hi {first_name},

Following up on my note from earlier this week. When families and discharge planners look at a facility online, three things usually decide whether they call:

1. They can tell in a few seconds what care you provide and who you accept.
2. There's a simple way to send a referral or book a tour, not only a phone number.
3. The site works properly on a phone.

If it helps, I'd be glad to sketch a free homepage design for {facility} so you can see what it could look like. There's no cost and no obligation; just reply "yes" and I'll send it within three business days.

Click my {portfolio_link} for examples of my work.

Best regards,

{signature}
$b$, 1),

('3A', 'Meeting offer (day 10)', 3, '{}',
$s$15 minutes this week?$s$,
$b$Hi {first_name},

I'd love to show you what a modern website or a simple care-management system could look like for {facility}. A short call is usually enough to see whether it's a fit.

Would either of these work (Pacific time)?
• {day_option_1}
• {day_option_2}

If neither suits, reply with a time that does, or message me on {whatsapp_link} at {whatsapp}.

Click my {portfolio_link} to see recent projects.

Best regards,

{signature}
$b$, 1),

('4A', 'Final follow-up (day 21)', 4, '{}',
$s$Closing the loop$s$,
$b$Hi {first_name},

I don't want to fill your inbox, so this will be my last note for now.

If a new website, an online referral form, or a simpler way to manage records and staff credentials ever becomes a priority for {facility}, I'd be glad to help. Whenever you'd like a look at my work, click my {portfolio_link}.

Thank you for your time, and all the best to you and your team.

Best regards,

{signature}
$b$, 1),

('5A', 'After a reply – next steps', 5, '{}',
$s$Re: {previous_subject}$s$,
$b$Hi {first_name},

Thank you for getting back to me. I'm glad to help.

To put together a clear proposal for {facility}, it would help to know:

1. Do you have a website today? If so, what's the address?
2. What matters most right now: more referrals, easier admissions, or less paperwork for staff?
3. Who else should be involved in the decision?

We can cover this on a short call at {meeting_time} (Pacific time), or on {whatsapp_link} at {whatsapp}.

Best regards,

{signature}
$b$, 1),

('5B', 'After a call – proposal follow-up', 5, '{}',
$s$Your proposal for {facility}$s$,
$b$Hi {first_name},

Thank you for your time today. As promised, here's a summary of what we discussed for {facility}:

{project_summary}

I'll send the full proposal with the timeline and pricing by {proposal_date}. In the meantime, click my {portfolio_link} to see similar projects.

If any questions come up, the quickest way to reach me is {whatsapp_link}.

Best regards,

{signature}
$b$, 2),

('U1', 'Website upgrade – introduction', 7, '{}',
$s$Upgrading {facility}'s website$s$,
$b$Hi {first_name},

My name is Joseph Githaiga. I design premium websites and build management systems for care facilities, and I work remotely with clients across the US.

Since {facility} already has a website, I'm not suggesting starting over. I help facilities get more out of the site they have:

• A faster, modern design that works well on a phone, where most families and discharge planners look first
• Online referral, tour and waitlist forms that land straight in your inbox
• Clear pages for the care you provide, admissions and payment options
• Simple editing, so your team can keep it up to date without calling a developer

Click my {portfolio_link} to see recent work, including Golden Years Home Care and Harmony Living House.

If you'd like, I'll review your current website for free and send you three specific upgrades. Just reply "yes", or message me on {whatsapp_link} at {whatsapp}.

Best regards,

{signature}
$b$, 1),

('U2', 'Website upgrade – free review follow-up (day 5)', 7, '{}',
$s$Re: {previous_subject}$s$,
$b$Hi {first_name},

Following up on my note about {facility}'s website. My free review is short and practical. I look at:

1. How the site looks and loads on a phone
2. How easy it is for a family or discharge planner to send a referral or book a tour
3. How clearly it explains the care you provide and who you accept
4. How it shows up when people in {city} search for care

You'd get a one-page summary with three upgrades I'd recommend, whether or not we work together. Just reply "yes".

You can see examples of my work on my {portfolio_link}.

Best regards,

{signature}
$b$, 2),

('U3', 'Website upgrade – final follow-up (day 14)', 7, '{}',
$s$Closing the loop on {facility}'s website$s$,
$b$Hi {first_name},

This will be my last note for now. If refreshing {facility}'s website or adding online referral and tour forms becomes a priority, I'd be glad to help, and the free review offer stands.

My work is on my {portfolio_link}, and the quickest way to reach me is {whatsapp_link}.

Thank you for your time, and all the best to you and your team.

Best regards,

{signature}
$b$, 3),

('QP1', 'Quick pitch – short note', 6, '{}',
$s$Website & systems for {facility}$s$,
$b$Hi {first_name},

I'm Joseph, a web designer who works remotely with care facilities across the US. I build modern websites, referral forms and care-management systems, including the ones Golden Years Home Care and Harmony Living House use today.

Click my {portfolio_link} to see my work.

Would you be open to a quick call or a chat on {whatsapp_link}?

Best regards,

{signature}
$b$, 1)

on conflict (code) do update set name = excluded.name, stage = excluded.stage, categories = excluded.categories,
  subject = excluded.subject, body = excluded.body, sort_order = excluded.sort_order;

-- Check: should list 53 contacts (all with email) and 11 templates
select (select count(*) from public.outreach_contacts) as contacts,
       (select count(*) from public.outreach_templates) as templates,
       (select count(*) from public.outreach_contacts where email is not null) as with_email;
