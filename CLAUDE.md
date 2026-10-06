# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Two static sites for AcceleraIT LLC. **No build step, no dependencies, no tests, no linter.**

- `landing/` → `https://accelerait.us` (LiteSpeed/Apache host): the single-page marketing landing.
- `website/` → `https://accelerait.uz` (a separate PHP host, Apache/LiteSpeed): the "Our Project Journey" projects page, served as its `index.html`.

Deployment means uploading the contents of each folder to its web root as-is (including the hidden `.htaccess`). `README.md`, `docker-compose.yml`, `upload.sh` and this file stay at the repo root (`docs/` alongside them) and are not served.

Run locally (Apache with `.htaccess` active, so redirects/headers/file blocks match production):

```bash
docker compose up -d --build   # from repo root → landing http://localhost:8081, website http://localhost:8082
```

Each folder has an identical `Dockerfile` (`httpd:2.4-alpine`) that enables rewrite/headers/expires/deflate and `AllowOverride All`. `docker-compose.yml` is at the repo root with services `landing` and `website`; each bind-mounts its folder read-only (edits are live), writes Apache logs to `./logs/<service>/` (the Dockerfile redirects them from stdout, so `docker logs` is empty), and shares the healthcheck and the `accelerait-net` network. The `Dockerfile` is excluded from the image by `.dockerignore` and denied by `.htaccess`, since each folder is uploaded wholesale.

## Architecture

- **Styling:** Tailwind v3 loaded from `cdn.tailwindcss.com` (compiled in-browser). Custom design tokens (`ink`, `brand`, `paper`, `hair`, `muted`, `dim`; fonts `display`/`sans`/`mono`; `max-w-shell`) are defined in the inline `tailwind.config` object — use those rather than raw hex values. Non-utility CSS (slide shell, entrance animation, hero/footer backdrops, progress bar, dot rail, reduced-motion overrides) is in the `<style>` block.
- **Slides:** six `<section class="slide">` elements with ids `s1`–`s6` (Hero, What we do, How we work, Engagement, Clients, Contact). Scroll-snap is enabled only at `min-width:1024px and min-height:760px`; smaller viewports scroll normally. Sections with `bg-ink` are dark — the rail script toggles `.on-dark` based on that class, so keep it on dark sections.
- **Script behaviours** (all keyed off DOM ids/attributes, so renaming markup breaks them):
  - IntersectionObserver adds `.in` to slides for entrance animations, and updates `#rail` dots (`data-go="sN"`, `aria-current`).
  - `#progress` bar width tracks scroll.
  - `[data-count]` elements animate to their number (e.g. the "6 disciplines" counter must match the number of discipline cards in `#s2`).
  - Phase tabs in `#s3`: `[role=tab]` buttons with `data-label`/`data-weeks` drive `#phaseIndex`, `#phaseTitle`, `#phaseWeeks` and show/hide `#panel-N`; arrow-key navigation included.
  - All motion respects `prefers-reduced-motion`.
- **Projects page:** `website/index.html` is the whole accelerait.uz site (the landing's "Our Project Journey" links go to `https://accelerait.uz/`; `/projects.html` on either site 301-redirects there, keeping `?category=`). It copies the `<head>` metadata, Tailwind config and footer from `landing/index.html` — keep the two configs identical — but has **no Google Tag Manager**, and its logo links back to `https://accelerait.us/`. `favicon.ico`, `logo.png`, `hero.png` and `og-image.png` are copies of the landing's; update both when one changes. It fetches `/projects.json` (array of `{name, link?, category?, year?, thumbnail?, description}`; `category` is a string or a list; `year` is the year the product's domain was registered (RDAP), not shown on the cards — keep the file sorted by it, oldest first, since the page renders in file order; the name links to `link` in a new tab) and renders cards via `textContent`. Category filter chips are built from the data with counts — Startups, Clients, Open-source first, then the rest A–Z; on phones they form one swipeable row; the selection is kept in `?category=<slug>` so filtered views can be shared. `thumbnail` is a local 1200×630 PNG homepage screenshot in `website/projects/<slug>.png`, compressed with `pngquant --quality=90-100` then `oxipng -o max` — if pngquant exits 99 (quality unreachable, typical for photo-heavy pages) use `oxipng` alone (taken with headless Chromium; where a site blocks that, its og-image is downloaded instead). Thumbnails are shown whole (`bg-contain`) at full opacity. A missing or broken thumbnail falls back to an initials panel. No product icons are shown, so every image is local; delete a thumbnail when its entry is removed or repointed. It needs an HTTP server; `file://` won't load the JSON.
- **Contact:** no form — the Contact slide links to a Cal.com booking page. `docs/meet.txt` holds the company details and copy used for the Cal.com event.
- **Deploy:** `./upload.sh landing|website` mirrors that folder to its host over FTPS with `lftp`, falling back to an Alpine Docker container when `lftp` is missing (`--dry-run` to preview, `--delete` to prune removed files); credentials come from `docs/ftp.txt` (landing) / `docs/ftp-website.txt` (website) or env vars. See README.
- **Analytics:** Google Tag Manager container `GTM-MSNM2N35` (head script + `<noscript>` iframe), on the landing only.

## Things that must stay in sync

- Company facts appear in several places: JSON-LD (`ProfessionalService`) in `<head>`, visible Contact copy, and `docs/meet.txt`.
- Canonical URLs are the non-www `https://accelerait.us/` (landing) and `https://accelerait.uz/` (website). Each is referenced by its folder's `<link rel="canonical">`, `og:url`, `sitemap.xml`, `robots.txt`, and the www→non-www redirect in `.htaccess` section 5. Changing domain form means updating all of them.
- Update `<lastmod>` in `sitemap.xml` when the page content changes.
- `robots.txt` deliberately allows AI crawlers and blocks SEO crawlers (Semrush, Ahrefs, etc.) — see README for rationale.

## .htaccess notes

`landing/.htaccess` and `website/.htaccess` are near-identical. Numbered sections, each wrapped in `<IfModule>` so a missing module doesn't 500. Forces HTTPS (except for `localhost`, for the Docker preview), disables directory listing, sets security/cache/MIME headers, blocks sensitive files (all `.json` is denied; `website/` re-allows `projects.json` — add an exception for any new JSON a page fetches), and routes 404s to each site's `index.html`. The Content-Security-Policy (section 7) is commented out because the Tailwind CDN needs `unsafe-eval`; if you add any new external origin (script, font, image), it would need adding to that CSP line too.

## Known follow-ups (from README)

- Replace the Tailwind CDN with a compiled `assets/style.css` (Tailwind v3 CLI, move config to `tailwind.config.js`), then enable the CSP.
- Unconfirmed content: `foundingDate: "2005"` / "since 2005", "20+ years" framing, shortened client quotes.
