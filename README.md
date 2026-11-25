# Bubblercustomerlinks

Customer-facing multi-brand web links for the Bubbler platform.

Provides instant mobile-app experience in the browser for all Bubbler laundry brands (`domain.com/:brandname`).

## Features
- **Dynamic Multi-Brand Routing**: Direct clean path URLs (`domain.com/:brandname` e.g., `/Vclean`, `/Sparkle`) without hash routing or query params.
- **PWA (Progressive Web App)**: Installable to mobile home screen with native full-screen app experience.
- **Vercel Ready**: Configured with `vercel.json` for SPA rewrites and CDN edge caching.
- **Direct Bubbler API Integration**: Fetches brand profile, logos, branches, services, and live price list from `https://apibubbler.krackbot.com/api`.

## Deploy to Vercel
1. Import this repository in [Vercel](https://vercel.com/new).
2. Framework: **Other**
3. Output Directory: **`build/web`**
4. Deploy!
