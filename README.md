# AcceleraIT — deployment package

Everything that is served lives in `site/`. Upload the **contents** of `site/`
to the web root of `accelerait.us`, keeping this exact folder structure. No
build step, no dependencies.

## Run locally with Docker

```bash
docker compose up -d --build    # from the repo root → http://localhost:8081
docker compose down
```

Apache (`httpd:2.4-alpine`) with `.htaccess` enabled, so the redirects,
headers and file blocks behave as in production. `site/` is mounted read-only,
so edits show without a rebuild; Apache's `access_log` and `error_log` are
written to `./logs/` (git-ignored). The container runs on its own
`accelerait-net` bridge network. The HTTPS redirect skips `localhost`.
`docker-compose.yml` is at the repo root and builds from `site/Dockerfile`.
The `Dockerfile` and `.dockerignore` sit in `site/` but are kept out of the
image and denied by `.htaccess` if uploaded.

```
site/
├── index.html                     the landing page
├── projects.html                  "Our Project Journey" page, filterable by category
├── projects.json                  projects (startups, clients, open-source…) listed on projects.html
├── .htaccess                      server rules (see notes below)
├── robots.txt                     crawler policy
├── sitemap.xml                    edit <lastmod> when you change the page
├── site.webmanifest               installable-icon metadata
├── favicon.ico                    16 / 32 / 48 / 64 px, multi-resolution
└── assets/
    ├── og-image.png               1200 × 630, social + AI link previews
    ├── favicon.svg                modern browsers prefer this over .ico
    ├── apple-touch-icon.png       180 × 180, iOS home screen
    ├── icon-192.png               Android / PWA
    ├── icon-512.png               Android / PWA
    ├── icon-512-maskable.png      Android adaptive icon, 18% safe padding
    ├── logo-wordmark.svg          "AcceleraIT" — outlines, no font needed
    └── projects/                  1200 × 630 PNG site screenshots, thumbnails on projects.html
```

## Deploy

```bash
./upload.sh --dry-run   # show what would change on the server
./upload.sh             # upload new/changed files from site/ over FTPS (lftp)
./upload.sh --delete    # also remove remote files no longer in site/
```

Needs `lftp` (`brew install lftp`). Host, user, port, password and web root
are read from `docs/ftp.txt`, which is git-ignored — create it locally, never
commit it. Env vars `FTP_USER`, `FTP_HOST`, `FTP_PORT`, `FTP_PASS` and
`REMOTE_DIR` override it. The
`Dockerfile`, `.dockerignore` and `.DS_Store` files are never uploaded. Use
`--delete` after removing a thumbnail or page so the old file goes too.

## Upload checklist

1. **`.htaccess` is a hidden file.** Most FTP clients hide it by default —
   turn on "show hidden files" or it will silently not upload.
2. **Closes your open directory listing.** `accelerait.us` currently serves a
   browsable `Index of /` page. `Options -Indexes` in `.htaccess` stops that.
3. **Confirm HTTPS works first.** The file force-redirects to HTTPS. If the
   certificate is not live yet, visitors hit a redirect loop.
4. **www vs non-www.** It redirects `www.accelerait.us` → `accelerait.us`, to
   match the `<link rel="canonical">` in the page. If you prefer www, swap the
   two blocks in section 5 of `.htaccess` *and* update the canonical tag,
   `og:url`, `sitemap.xml` and `robots.txt`.

## After it is live

- Submit `https://accelerait.us/sitemap.xml` in Google Search Console and
  Bing Webmaster Tools.
- Test the link preview: paste the URL into LinkedIn's Post Inspector,
  Facebook's Sharing Debugger, and a Slack message.
- Verify the crawler policy loads at `https://accelerait.us/robots.txt`.

## About robots.txt

The file explicitly **allows** AI crawlers — GPTBot, ClaudeBot, PerplexityBot,
Google-Extended, Applebot-Extended and others. That is what makes the company
quotable inside AI assistants when someone asks for a development partner.

If you later want to stay visible in AI *search* while opting out of model
*training*, disallow `GPTBot`, `ClaudeBot`, `Google-Extended` and
`Applebot-Extended`, but keep `OAI-SearchBot`, `Claude-SearchBot`,
`ChatGPT-User`, `Claude-User` and `Perplexity-User` allowed.

SEO crawlers with no upside for you — Semrush, Ahrefs, MJ12, DotBot, PetalBot —
are blocked. They consume bandwidth and mainly help competitors study you.

## Known limitation

The page loads Tailwind from `cdn.tailwindcss.com`, which compiles CSS in the
browser on every visit. It works, but it costs roughly 100–300 ms per page load
and logs a production warning in the browser console.

To remove that cost, compile the stylesheet once:

```bash
npm install -D tailwindcss@3
npx tailwindcss -i input.css -o assets/style.css --minify
```

Move the `tailwind.config` object from `index.html` into `tailwind.config.js`,
delete both `<script>` tags in the head, and link `assets/style.css` instead.
Then the Content-Security-Policy line in `.htaccess` section 7 can be enabled.

## Page structure

Six full-height slides, each snapping into place on tall desktop screens and
scrolling normally on laptops, tablets and phones:

1. **Hero** — twenty years, six disciplines, animated counters
2. **What we do** — software, web, mobile, AI, data & BI, cloud
3. **How we work** — the interactive four-phase, eight-week timeline
4. **Engagement** — fixed scope, dedicated team, support
5. **Clients** — two references
6. **Contact** — details and a Cal.com booking link

A progress bar tracks scroll position; a dot rail on the right (desktop only)
jumps between slides.

## Projects page

`projects.html` renders the cards from `projects.json` in file order. Each
entry is `{name, link?, category?, year?, thumbnail?, description}`:

- **`year`** — the year the linked domain was registered (look it up via
  RDAP / `whois`). It isn't shown on the cards, but keep the file sorted by it,
  oldest first.
- **`category`** — a string or a list. Filter chips are built from the data,
  with Startups, Clients and Open-source first.
- **`thumbnail`** — `/assets/projects/<slug>.png`, a 1200 × 630 homepage
  screenshot taken with headless Chrome:

  ```bash
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
    --hide-scrollbars --window-size=1200,630 --virtual-time-budget=8000 \
    --screenshot=shot.png https://example.com/
  pngquant --quality=90-100 --output site/assets/projects/<slug>.png shot.png
  oxipng -o max site/assets/projects/<slug>.png
  ```

  If `pngquant` can't reach that quality (exit code 99, common with photo-heavy
  pages), copy the original and run only `oxipng`. When a site blocks headless
  browsers, download its og-image instead. Delete the PNG when you remove or
  repoint an entry.

The page fetches the JSON, so open it through a server (Docker above), not
`file://`. `.htaccess` blocks every other `.json` file.

## Content still to confirm

- **`foundingDate: "2005"`** in the JSON-LD and **"since 2005"** framing —
  replace with the real founding year.
- **"20+ years"** — if this is the team's combined experience rather than the
  company's age, reword it. A US client will check the LLC registration date.
- **"6 disciplines"** — the counter animates to 6; keep the card grid and this
  number in sync if you add or remove a discipline.
- **Client quotes** are shortened from the originals on the old site.
