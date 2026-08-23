# CMS DG Joomla Migration Report

Generated: 2026-08-18T18:45:08+03:00

## Joomla inventory

- Joomla 6.1.2, table prefix `a0h8n_`.
- 176 non-trashed content records: 175 published and 1 unpublished.
- 11 content categories, 1 used content author, 16 content menu items, 313 redirect rows and 171 sitemap URLs.
- The Joomla tree contains 2343 images (137 MB); it was treated as a read-only source and was not copied wholesale.

## Joomla fields

Used article data: id, title, alias, introtext, fulltext, state, category, author, created/modified/publish dates, images JSON, Helix main image, ordering, meta keywords/description, robots metadata, featured, access and language. HTML structure is retained. Joomla tags and custom fields have no populated article relations/values in this dump.

## Mapping

- `content` → `Article`; `introtext` → `excerpt`; `fulltext` → `body`; `alias` → `slug`.
- `categories` → existing/new `Category` records by alias, retaining hierarchy and legacy identity.
- Joomla content user → separate `Author` (authentication hashes and sessions were not imported).
- image intro/fulltext/Helix and HTML image references → `MediaAsset` + Active Storage; article image roles keep their own alt/caption fields.
- Joomla state 1 → published, 0 → draft, 2 → archived; -2 is excluded.
- sitemap/category paths → `legacy_url`; legacy redirect rows → `LegacyRedirect` (301).

## CMS changes

Added an additive database migration; `Author`, `MediaAsset` and `LegacyRedirect`; structured Article legacy/author/status/featured/date/SEO/media fields; Category legacy/SEO fields; media ingestion; public legacy URL/media controllers; editor fields; and `legacy:analyze`, `legacy:import`, `legacy:verify`, `legacy:report` tasks. The importer is transaction-protected, PostgreSQL advisory-locked and idempotent by `(legacy_source, legacy_id)` or source path.

## Imported

- 176 articles (175 published), 11 categories and 1 author.
- 856 media records and 235 usable permanent redirects.
- Verification result: all source/import counts match, no duplicate article legacy IDs, no empty attachments, and no remaining local old-site image URLs.

## Transformed

Relative/absolute local image URLs were rewritten to stable `/media/:id/:filename` paths. Raster JPEG/PNG/TIFF/BMP files were optimized to WebP when readable; GIF/SVG/WebP are retained when transformation is not appropriate. Existing CMS categories with matching aliases were reused rather than duplicated.

## Skipped

Joomla sessions, cache, ACL assets, extension/plugin/template configuration, logs, workflow internals, credentials, password hashes and unused filesystem files were skipped. Tags and custom fields were skipped because the concrete dump has no article tag mappings and no populated custom-field rows. 78 redirect rows were skipped because they were empty, external, self-referential or not safely representable as local redirects.

## Media

- Archive images: 2343; referenced unique paths: 872; imported: 856; missing: 16; external: 0.
- Formats after import: gif=2, webp=854.
- Converted to WebP: 771; retained in source format: 85.
- Referenced source size: 59 MB; stored size: 43.7 MB; saving: 15.3 MB (25.9%).
- Full per-file old/new paths, roles, dimensions and sizes: `migration_reports/media_manifest.json`.

## Missing media

- `images/blog/myreviews-review-analytics.webp` — articles 295 (html:fulltext:src)
- `images/blog/myreviews-review-feedback-form.webp` — articles 295 (html:fulltext:src)
- `images/blog/myreviews-review-integrations.webp` — articles 295 (html:fulltext:src)
- `images/blog/myreviews-review-pricing-cabinet.webp` — articles 295 (html:fulltext:src)
- `images/blog/myreviews-review-roles-access.webp` — articles 295 (html:fulltext:src)
- `images/blog/myreviews-review-sources.webp` — articles 295 (html:fulltext:src)
- `images/blog/myreviews-review-widget-code.webp` — articles 295 (html:fulltext:src)
- `images/ssh-klienty-windows/bitvise-ssh-client.jpg` — articles 290 (html:fulltext:src)
- `images/ssh-klienty-windows/mobaxterm-interface.jpg` — articles 290 (html:fulltext:src)
- `images/ssh-klienty-windows/openssh-windows-terminal.jpg` — articles 290 (html:fulltext:src)
- `images/ssh-klienty-windows/putty-interface.jpg` — articles 290 (html:fulltext:src)
- `images/ssh-klienty-windows/solar-putty-interface.jpg` — articles 290 (html:fulltext:src)
- `images/ssh-klienty-windows/ssh-client-windows-main.jpg` — articles 290 (html:fulltext:src)
- `images/ssh-klienty-windows/tera-term-interface.jpg` — articles 290 (html:fulltext:src)
- `images/ssh-klienty-windows/termius-windows-interface.jpg` — articles 290 (html:fulltext:src)
- `images/ssh-klienty-windows/xshell-interface.jpg` — articles 290 (html:fulltext:src)

## External media

None.

## Broken links

- Article 133: `index.php?option=com_content&view=article&id=51:besplatnyj-sposob-poiska-klientov-kotorym-malo-kto-polzuetsya&catid=9:freelance&Itemid=117`
- Article 158: `lp/joomshop`
- Article 174: `lp/joomla-po-vzroslomu`
- Article 207: `index.php?option=com_content&view=article&id=57:sloi-kak-i-zachem-ispolzovat-sloi-v-sp-page-builder-4&catid=14:uroki-po-joomla&Itemid=137`
- Article 219: `lp/ostrov`
- Article 221: `lp/ostrov`
- Article 223: `/lp/ostrov`
- Article 229: `index.php?option=com_content&view=article&id=1:kakoj-khosting-vybrat-dlya-sajta-v-2022-godu&catid=8:sozdanie-sajtov&Itemid=116`
- Article 242: `index.php?option=com_content&view=article&id=53:obnovlyaem-joomla-3-do-joomla-4-pravilnaya-migratsiya-praktika&catid=14:uroki-po-joomla&Itemid=137`
- Article 254: `index.php?option=com_content&view=article&id=60:kak-sozdat-megamenyu-s-pomoshchyu-helix-ultimate-v-joomla&catid=14:uroki-po-joomla&Itemid=137`
- Article 257: `/files/joomla/Progress-bar.zip`
- Article 293: `vps/registraciya-hostinga-timeweb#video-versiya-stati`
- Article 222: `/files/joomla/plg_jst_snow_v1.0.0_j3_j4.zip`
- Article 292: `/files/Sozdanie_oblozhek_dlia_sotcsetei.zip`
- Article 292: `lp/ai-prompt.html`

## URL changes

No imported article URL was intentionally changed: `legacy_url` is served directly. The five non-sitemap records use their category/alias-derived Joomla path.

## Redirects

235 valid local Joomla redirects were imported as permanent 301 redirects. The catch-all public route first resolves preserved Article/Category legacy paths, then the redirect table, avoiding duplicate indexable content URLs.

## Warnings

16 referenced files are absent from the supplied Joomla filesystem; no placeholders were created. Public rendering sanitizes dangerous HTML while retaining article formatting, tables, images, embeds and useful attributes.

## Errors

None after final `legacy:verify`.
