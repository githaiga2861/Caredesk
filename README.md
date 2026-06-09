# CareDesk Pro — Operator Command Center

> **Private operator tool.** Keep this repository private.  
> It contains your master Supabase credentials in `localStorage` (never in code), your client list, and the RN system template used to generate client deployments.

---

## What this repo is

| File / Folder | Purpose |
|---|---|
| `caredesk-pro.html` | The operator dashboard — your command center. Open via GitHub Pages. |
| `templates/rn-system.html` | The CareDesk RN product template. Fetched at generation time and injected with client data. |
| `supabase-master-schema.sql` | Run once in **your** master Supabase project. |
| `supabase-rn-client-schema.sql` | Run once in **each client's** Supabase project (also bundled in every generated zip). |
| `.github/workflows/deploy.yml` | Auto-deploys to GitHub Pages on every push to `main`. |

---

## First-time setup

### 1. Push the repo and enable GitHub Pages

```bash
git init
git add .
git commit -m "Initial CareDesk Pro setup"
git remote add origin https://github.com/YOUR_USERNAME/caredesk-pro.git
git push -u origin main
```

Then in GitHub: **Settings → Pages → Source: GitHub Actions**. The workflow will deploy automatically.

Your operator URL will be: `https://YOUR_USERNAME.github.io/caredesk-pro/caredesk-pro.html`

### 2. Set up your master Supabase project

1. Create a new Supabase project at [supabase.com](https://supabase.com).
2. Go to **SQL Editor → New query**.
3. Paste the contents of `supabase-master-schema.sql` and click **Run**.
4. Copy your project URL and `anon` key from **Project Settings → API**.

### 3. Connect CareDesk Pro to master Supabase

1. Open `caredesk-pro.html` via your GitHub Pages URL.
2. Go to **Settings** in the sidebar.
3. Paste your master Supabase URL and anon key.
4. Click **Save & reconnect master Supabase**.

The status bar at the bottom should turn green: *Master Supabase: connected*.

---

## Onboarding a new RN client

1. Open CareDesk Pro → **System Creator**.
2. Pick **CareDesk RN — $29.99/mo**.
3. Fill in identity, branding, and Supabase details for the client.
4. Click **Generate system** — a zip downloads automatically.
5. Follow the steps on the success screen:
   - Create a new GitHub repo for the client.
   - Push the zip contents.
   - Enable Pages on that repo.
   - Run `supabase-schema.sql` in the client's Supabase.
   - Create the admin user in Supabase → Authentication → Users.
6. The client is automatically registered in your master CRM.

---

## Updating the RN template

Edit `templates/rn-system.html` and push to `main`. All **future** generated zips will use the new version. Existing deployed client repos are unaffected.

---

## Important notes

- **Never commit secrets.** API keys belong in the browser's `localStorage` via the Settings panel, not in any file.
- **Keep this repo private** on GitHub — it contains the template for all client systems.
- The `caredesk-pro.html` file must be served over `https://` (GitHub Pages) for `fetch()` of the template to work. Opening it as a local `file://` will fail the template fetch.
- The Supabase anon key in generated client systems is intentionally public — Supabase's RLS policies ensure each user can only access their own data.

---

*Built by Joseph · CareDesk Pro v1.0 · Serving Washington State, USA*
