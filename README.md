# AcceleraIT — deployment package

Two static sites, each uploaded as-is to its own web root, keeping this exact
folder structure. No build step, no dependencies.

- **`landing/`** → `accelerait.us` — the one-page company landing.
- **`website/`** → `accelerait.uz` — the "Our Project Journey" projects page,
  on a separate PHP host. The landing's "Our Project Journey" links point here,
  and the old `accelerait.us/projects.html` 301-redirects to it.

## Run locally with Docker

```bash
docker compose up -d --build    # from the repo root → landing http://localhost:8081, website http://localhost:8082
docker compose down
```

Apache (`httpd:2.4-alpine`) with `.htaccess` enabled, so the redirects,
headers and file blocks behave as in production. Each folder is mounted
read-only, so edits show without a rebuild; Apache's `access_log` and
`error_log` are written to `./logs/landing/` and `./logs/website/`
(git-ignored). Both containers run on the `accelerait-net` bridge network. The
HTTPS redirect skips `localhost`. `docker-compose.yml` is at the repo root and
builds from each folder's `Dockerfile`, which (with `.dockerignore`) is kept
out of the image and denied by `.htaccess` if uploaded.

```
landing/                           → accelerait.us
├── index.html                     the landing page
├── .htaccess                      server rules (see notes below)
├── robots.txt                     crawler policy
├── sitemap.xml                    edit <lastmod> when you change the page
├── favicon.ico                    16 / 32 / 48 / 64 px, multi-resolution
├── og-image.png                   1200 × 630, social + AI link previews
├── hero.png                       1200 × 500 hero / footer backdrop
└── logo.png                       539 × 130 "AcceleraIT" wordmark

website/                           → accelerait.uz (PHP host)
├── index.html                     "Our Project Journey" page, filterable by category
├── projects.json                  projects (startups, clients, open-source…) listed on it
├── projects/                      1200 × 630 PNG site screenshots, thumbnails
├── .htaccess, robots.txt, sitemap.xml
├── og-image.png                   1200 × 630 tech-team link preview (Bukhara backdrop)
├── hero.png                       1200 × 500 Bukhara header / footer backdrop
└── favicon.ico, logo.png          copies of the landing's
```

## Deploy

```bash
./upload.sh --dry-run      # both sites: website/ → accelerait.uz, then landing/ → accelerait.us
./upload.sh us --dry-run   # show what would change on accelerait.us (landing/)
./upload.sh us             # upload new/changed files from landing/ over FTPS (lftp)
./upload.sh uz             # same for website/ → accelerait.uz
./upload.sh uz --delete    # also remove remote files no longer in website/

`landing` and `website` work as aliases for `us` and `uz`.
```

Needs `lftp` (`brew install lftp`); without it (e.g. Git Bash on Windows) the script re-runs itself in an `alpine` Docker container that has it. Host, user, port and password
are read from `docs/ftp-us.txt` (landing) or `docs/ftp-uz.txt` (website,
same `FTP Username:` / `FTP server:` / `FTP & explicit FTPS port:` / `psw:`
lines); env vars `FTP_USER`, `FTP_HOST`, `FTP_PORT`,
`FTP_PASS` and `REMOTE_DIR` override them. The
`Dockerfile`, `.dockerignore` and `.DS_Store` files are never uploaded. Use
`--delete` after removing a thumbnail or page so the old file goes too. The
host's own files in the web root (`.ftpquota`, `.user.ini`, `php.ini`,
`error_log`, `.well-known/`, `cgi-bin/`, `home/`) are excluded, so `--delete`
never touches them.

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

- Submit `https://accelerait.us/sitemap.xml` and `https://accelerait.uz/sitemap.xml`
  in Google Search Console and Bing Webmaster Tools.
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

`website/index.html` renders the cards from `projects.json` in file order. Each
entry is `{id, name, link?, category?, year?, thumbnail?, description}`:

- **`year`** — the approximate year the team worked on the project. It isn't
  shown on the cards, but it drives the "Projects delivered" chart; keep the
  file sorted by it, oldest first.
- **`category`** — a string or a list. Filter chips are built from the data,
  with Startups, Clients and Open-source first.
- **`thumbnail`** — `/projects/<slug>.png`, a 1200 × 630 homepage
  screenshot taken with headless Chrome:

  ```bash
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
    --hide-scrollbars --window-size=1200,630 --virtual-time-budget=8000 \
    --screenshot=shot.png https://example.com/
  pngquant --quality=90-100 --output website/projects/<slug>.png shot.png
  oxipng -o max website/projects/<slug>.png
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
