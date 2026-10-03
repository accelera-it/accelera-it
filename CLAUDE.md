# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Static, single-page marketing site for AcceleraIT LLC, deployed to `https://accelerait.us` (LiteSpeed/Apache host). **No build step, no dependencies, no tests, no linter.** Everything served lives in `site/`; deployment means uploading the contents of `site/` to the web root as-is (including the hidden `.htaccess`). `README.md`, `meet.txt`, `docker-compose.yml` and this file stay at the repo root and are not served.

Run locally (Apache with `.htaccess` active, so redirects/headers/file blocks match production):

```bash
docker compose up -d --build   # from repo root → http://localhost:8081
```

`site/Dockerfile` (`httpd:2.4-alpine`) enables rewrite/headers/expires/deflate and `AllowOverride All`. `docker-compose.yml` is at the repo root (`build: ./site`); it bind-mounts `site/` read-only (edits are live), writes Apache logs to `./logs/` (the Dockerfile redirects them from stdout, so `docker logs` is empty), and defines the healthcheck and the `accelerait-net` network. The `Dockerfile` lives inside `site/` but is excluded from the image by `site/.dockerignore` and denied by `.htaccess`, since `site/` is uploaded wholesale.

## Architecture

The page is `site/index.html`: `<head>` metadata, inline Tailwind config, a `<style>` block, the markup, and one inline `<script>` at the end.

- **Styling:** Tailwind v3 loaded from `cdn.tailwindcss.com` (compiled in-browser). Custom design tokens (`ink`, `brand`, `paper`, `hair`, `muted`, `dim`; fonts `display`/`sans`/`mono`; `max-w-shell`) are defined in the inline `tailwind.config` object — use those rather than raw hex values. Non-utility CSS (slide shell, entrance animation, hero/footer backdrops, progress bar, dot rail, reduced-motion overrides) is in the `<style>` block.
- **Slides:** six `<section class="slide">` elements with ids `s1`–`s6` (Hero, What we do, How we work, Engagement, Clients, Contact). Scroll-snap is enabled only at `min-width:1024px and min-height:760px`; smaller viewports scroll normally. Sections with `bg-ink` are dark — the rail script toggles `.on-dark` based on that class, so keep it on dark sections.
- **Script behaviours** (all keyed off DOM ids/attributes, so renaming markup breaks them):
  - IntersectionObserver adds `.in` to slides for entrance animations, and updates `#rail` dots (`data-go="sN"`, `aria-current`).
  - `#progress` bar width tracks scroll.
  - `[data-count]` elements animate to their number (e.g. the "6 disciplines" counter must match the number of discipline cards in `#s2`).
  - Phase tabs in `#s3`: `[role=tab]` buttons with `data-label`/`data-weeks` drive `#phaseIndex`, `#phaseTitle`, `#phaseWeeks` and show/hide `#panel-N`; arrow-key navigation included.
  - All motion respects `prefers-reduced-motion`.
- **Startups popup:** the hero's "Our new startups" button opens a native `<dialog id="startups">` that fetches `/projects.json` (array of `{name, link?, thumbnail?, icon?, description}`; the name links to `link` in a new tab) on first open and renders cards via `textContent`. `thumbnail` (the product's og-image) and `icon` are hotlinked absolute URLs on the products' own domains — not copied into `assets/`; a missing or broken thumbnail falls back to an initials panel, a broken icon is dropped. If the CSP is ever enabled, `img-src` must allow those domains. It needs an HTTP server; `file://` won't load the JSON.
- **Contact:** no form — the Contact slide links to a Cal.com booking page. `meet.txt` holds the company details and copy used for the Cal.com event.
- **Analytics:** Google Tag Manager container `GTM-MSNM2N35` (head script + `<noscript>` iframe).

## Things that must stay in sync

- Company facts appear in several places: JSON-LD (`ProfessionalService`) in `<head>`, visible Contact copy, and `meet.txt`.
- Canonical URL is the non-www `https://accelerait.us/`. It's referenced by `<link rel="canonical">`, `og:url`, `sitemap.xml`, `robots.txt`, and the www→non-www redirect in `.htaccess` section 5. Changing domain form means updating all of them.
- Update `<lastmod>` in `sitemap.xml` when the page content changes.
- `robots.txt` deliberately allows AI crawlers and blocks SEO crawlers (Semrush, Ahrefs, etc.) — see README for rationale.

## .htaccess notes

Numbered sections, each wrapped in `<IfModule>` so a missing module doesn't 500. Forces HTTPS (except for `localhost`, for the Docker preview), disables directory listing, sets security/cache/MIME headers, blocks sensitive files (all `.json` is denied except `projects.json` and `site.webmanifest` — add an exception for any new JSON the page fetches), and routes 404s to the landing page. The Content-Security-Policy (section 7) is commented out because the Tailwind CDN needs `unsafe-eval`; if you add any new external origin (script, font, image), it would need adding to that CSP line too.

## Known follow-ups (from README)

- Replace the Tailwind CDN with a compiled `assets/style.css` (Tailwind v3 CLI, move config to `tailwind.config.js`), then enable the CSP.
- Unconfirmed content: `foundingDate: "2005"` / "since 2005", "20+ years" framing, shortened client quotes.
