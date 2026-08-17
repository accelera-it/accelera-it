# AcceleraIT — deployment package

Upload everything to the web root of `accelerait.us`, keeping this exact
folder structure. No build step, no dependencies.

```
/
├── index.html                     the landing page
├── .htaccess                      server rules (see notes below)
├── robots.txt                     crawler policy
├── sitemap.xml                    edit <lastmod> when you change the page
├── site.webmanifest               installable-icon metadata
├── favicon.ico                    16 / 32 / 48 / 64 px, multi-resolution
└── assets/
    ├── og-image.png               1200 × 630, social + AI link previews
    ├── og-image-preview.png       600 × 315, reference only — not linked
    ├── favicon.svg                modern browsers prefer this over .ico
    ├── apple-touch-icon.png       180 × 180, iOS home screen
    ├── icon-192.png               Android / PWA
    ├── icon-512.png               Android / PWA
    ├── icon-512-maskable.png      Android adaptive icon, 18% safe padding
    ├── logo-mark.svg              square mark on navy
    ├── logo-mark-transparent.svg  mark alone, for dark backgrounds
    ├── logo-wordmark.svg          "AcceleraIT" — outlines, no font needed
    └── logo-wordmark-white.svg    same, for dark backgrounds
```

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
6. **Contact** — details and form

A progress bar tracks scroll position; a dot rail on the right (desktop only)
jumps between slides.

## Content still to confirm

- **`foundingDate: "2005"`** in the JSON-LD and **"since 2005"** framing —
  replace with the real founding year.
- **"20+ years"** — if this is the team's combined experience rather than the
  company's age, reword it. A US client will check the LLC registration date.
- **"6 disciplines"** — the counter animates to 6; keep the card grid and this
  number in sync if you add or remove a discipline.
- **Client quotes** are shortened from the originals on the old site.
