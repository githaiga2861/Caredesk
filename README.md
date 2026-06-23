# The Precious Gift Adult Family Home

CareDesk Home system generated on 2026-06-23T12:17:39.943Z.
Client ID: `cd_home_3852`

This is a ready-to-deploy Adult Family Home management system.
The Supabase project URL and anon key are already injected into `index.html`.
**No build step is required.** Push and deploy.

## Deploy on Vercel (recommended — fastest, free)

1. Push this folder to a new GitHub repository.
2. Go to **vercel.com → New Project → Import** your repository.
3. Vercel auto-detects a static site. Click **Deploy** — no settings to change.
   (`vercel.json` is already included and handles all routing.)
4. Your app is live at `https://your-repo-name.vercel.app` in about 30 seconds.

## Deploy on GitHub Pages (alternative)

1. Push this folder to a new GitHub repository.
2. **Settings → Pages → Source: Deploy from branch `main` → root `/` → Save.**
3. Your app will be live at `https://username.github.io/repo-name` in ~1 minute.

## Supabase setup (required for both deploy options)

1. Open your Supabase project at **supabase.com**.
2. **SQL Editor → New query** → paste and run the CareDesk Home schema
   (copy from CareDesk Pro → Settings → Client schemas → CareDesk AFH Home).
3. The admin login credentials are already baked in from your onboarding answers.
4. Sign in at your deployment URL and verify all modules load.

## After deployment

5. Set up the Lemon Squeezy subscription for this client.
6. Update the **System URL** in the CareDesk Pro Client CRM.

## Files in this repo

| File | Purpose |
|------|---------|
| `index.html` | HTML shell — layout, modals, and page structure. |
| `app.css` | All styles — edit brand colours, fonts, and layout here. |
| `app.js` | All application logic — Supabase calls, forms, reports, charts. |
| `manifest.json` | PWA manifest — enables "Add to Home Screen" on mobile devices. |
| `vercel.json` | Vercel routing config — already set up, nothing to change. |
| `.gitignore` | Keeps secrets and OS files out of version control. |
| `onboarding.json` | Business details record from the onboarding wizard (no passwords). |
| `assets/logo.png` | Brand logo (replace with the real logo file before deploying). |

## Managed by

CareDesk Pro operator: Winnie Hinga · winniehinga2023@gmail.com
Billing: winniehinga2023@gmail.com