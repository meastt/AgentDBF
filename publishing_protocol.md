# Publishing Protocol — Site Content Production

## Core Rule
**Never split image generation from HTML wiring into separate subagents or parallel tasks.**
All images must be generated, saved, committed, and verified BEFORE any HTML file that references them is touched.

## Newsletter Images Rule (CRITICAL)
**Every newsletter edition MUST include at least one image.**
- Generate and host images via Buttondown API (POST /v1/images) BEFORE drafting
- Include the featured image in the draft markdown body using the Buttondown image URL
- Image should be 16:9 aspect ratio, 1200×675px minimum
- Never publish a newsletter with zero images

## Pre-Commit Validation Checklist
Before every commit, verify ALL of the following:

### Images
- [ ] Every `<img src="...">` in the file points to a path that EXISTS in the repo
- [ ] No external placeholder URLs (picsum.photos, placeholder.com, etc.) remain in any HTML file
- [ ] All image alt text is descriptive and matches the image content (not generic)
- [ ] Images are branded (logo, caption with article URL, or domain watermark)
- [ ] Featured image is 16:9, 1200×675px minimum
- [ ] All images are under 200KB

### Meta & Schema
- [ ] Title tag unique and under 60 chars
- [ ] Meta description unique and under 160 chars
- [ ] Canonical URL present and correct (no missing or wrong)
- [ ] og:title, og:description, og:url, og:image, og:type present
- [ ] twitter:card, twitter:title, twitter:description, twitter:image present
- [ ] JSON-LD schema valid and matches page content type
- [ ] No placeholder text in any tag (e.g., `_placeholder_`, `_excerpt_`)

### Content
- [ ] Humanized (run through Humanizer skill before publishing)
- [ ] No internal links to pages that don't exist yet
- [ ] No external links to placeholder URLs
- [ ] H1 present (exactly one per page)
- [ ] Internal links to at least 2 other site pages
- [ ] External links to authoritative sources (OpenClaw docs, research, etc.)

### Structure
- [ ] `<h1>` not a `<div class="hero-title">`
- [ ] Footer present with links to /, /blog, /lead, /privacy
- [ ] sitemap.xml updated with new page entry
- [ ] robots.txt unchanged (unless new routes require it)

## Presentation Standards

### Single Source of Truth
- All shared layout, components, and design tokens live ONLY in `index.css`
- No parallel `:root` blocks in page-level `<style>` tags
- No page-level resets unless there is a documented exception
- When adding new shared styles, add them to `index.css` — not inline or per-page

### Design Tokens
- Site colors and spacing are defined under `:root` in `index.css`
- Pages must use existing CSS variables (e.g., `var(--accent-cyan)`) and classes
- Do NOT duplicate design tokens elsewhere in the codebase

### Article CTA Pattern
- End-of-article CTA must follow the pattern in `blog/what-is-agentic-ai.html`:
  ```html
  <hr>
  <p><em>Want a faster path to a fully configured agent? <a href="/lead">Download the OpenClaw Starter Kit</a>.</em></p>
  ```
- Do NOT ship large inline `linear-gradient` promo boxes in article bodies
- Keep article CTAs minimal: `<hr>` + short italic line + single link

### Homepage Value Grid
- `index.html` grid-3 section must contain only unique cards — no copy-paste duplicates
- If fewer than 3 distinct content pieces exist, reduce the column count instead of repeating cards
- Each card must have distinct title and copy

### Dead CSS Rule
- When markup changes (e.g., form → mailto), remove all orphaned CSS rules
- Move any remaining page-specific rules to `index.css` with a clear scope class (e.g., `.submit-page`)
- Never leave unused `.class` blocks or orphaned `<style>` sections in HTML files

### Link-in-Bio Page
- Use `body.bio-page` and `.bio-*` classes as defined in `index.css`
- Keep the HTML file to structure and content only — no embedded CSS or duplicate token definitions

### FAQ Blocks in Articles
- Use `<section class="faq">` + `<details>` + `<summary>` + answer paragraphs
- Styling is under `.article-content .faq` in `index.css`
- Do not use nested `<h2>` inside FAQ sections — the `.faq h2` is already scoped
- Example structure:
  ```html
  <section class="faq">
    <h2>Frequently Asked Questions</h2>
    <details>
      <summary>Question here</summary>
      <p>Answer here</p>
    </details>
  </section>
  ```

### Code Blocks in Articles
- Wrap all code snippets in `<pre><code>` inside `.article-content`
- This ensures existing `pre / code` CSS rules in `index.css` apply correctly
- Do not ship raw unstyled `<code>` blocks outside of `<pre>` wrappers

## Subagent Tasking Rule
When spawning subagents for content production:
1. Generate all images FIRST and commit them
2. Verify images exist in repo before spawning HTML subagents
3. Never have an HTML subagent reference images it can't verify exist
4. If images are generated in parallel, wait for all to complete and verify before wiring into HTML

## Site Page Checklist (Per Page)
For every new page or post added to the site:
- [ ] Featured image (16:9, branded, stored in /images/)
- [ ] In-content images (at least 1 per major section, branded)
- [ ] Infographic if topic warrants (stored in /images/, embed code with linkback)
- [ ] All meta tags (title, description, canonical, OG, Twitter)
- [ ] JSON-LD schema (Article/TechArticle + FAQPage if applicable)
- [ ] BreadcrumbList schema if nested
- [ ] Internal links (2+)
- [ ] External links (authoritative)
- [ ] Humanized content
- [ ] sitemap.xml updated
- [ ] Repo file exists and committed
- [ ] Vercel deployment confirmed

## Image Naming Convention
Format: `{topic}-{type}-{descriptor}.jpg`
Examples:
- `agentic-ai-featured.jpg`
- `agentic-ai-infographic.jpg`
- `agentic-ai-how-it-works.jpg`
- `home-featured.jpg`
- `lead-featured.jpg`

## Lead Magnet Page Rule
The lead page must ALWAYS have real content before publishing — never a placeholder. If the offer isn't defined, the page stays uncommitted until it is.

## Contact Form Rule
- Never add Formspree or third-party form endpoints to any page
- Use `mailto:` links for contact/submission forms instead
- Example: `<a href="mailto:newsletter@agentdebrief.com">Send us a story</a>`

## Sitemap Rule
- Blog URLs in sitemap.xml must be extensionless (matching canonical URL pattern)
- Correct: `/blog/what-is-agentic-ai`
- Incorrect: `/blog/what-is-agentic-ai.html`
