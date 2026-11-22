# CareDesk

One repo, one master Supabase project, three parts:

| Folder / file | What it is | Hosted on |
|---|---|---|
| `site/` | Joseph Githaiga's portfolio website (websites & care systems for facilities) | **Vercel** (Root Directory = `site`) |
| `caredesk-pro.html` + `templates/` | CareDesk Pro operator command center and the client system templates | GitHub Pages |
| `outreach/` | Facility Outreach: contacts, email templates, and one-click Gmail drafts sent from jose.githaiga.njoroge@gmail.com | GitHub Pages (`/outreach/`), linked from the CareDesk Pro sidebar |

## Portfolio website on Vercel
1. In Vercel, go to **Add New → Project**, import `githaiga2861/Caredesk`.
2. Set **Root Directory** to `site`, Framework Preset **Other**, then click **Deploy**. Only the website is published there.
3. Copy the URL Vercel gives you (for example `https://caredesk-portfolio.vercel.app`) and paste it into **Facility Outreach → Settings → Portfolio website**. Every email links to it.

To show client reviews, open `site/main.js`, find `REVIEWS`, and paste each client's own words (with their OK) into `quote`. Cards with an empty quote stay hidden.

## Facility Outreach
1. Open the master Supabase project (the one CareDesk Pro → Settings uses). In **SQL Editor**, run `outreach/sql/setup.sql`. It creates the `outreach_*` tables, loads 138 facility contacts and 8 email templates, and is safe to run again.
2. In **Authentication → Users → Add user**, create your login (tick Auto Confirm).
3. Open CareDesk Pro and click **Facility Outreach** in the sidebar, or go to `/outreach/`. It reuses the Supabase connection saved in CareDesk Pro on the same browser. If none is saved, it asks for the URL and anon key once.

The outreach tables accept signed-in users only, because the master anon key ships inside every generated client system.
