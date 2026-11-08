# Sources: what counts, how to save, how to cite

## Kinds of source

Docs should mix kinds. Each kind supports different statements and appears differently
on a page.

| Kind | Examples | Supports | On a page |
|---|---|---|---|
| 📜 Primary / authoritative | Official docs, specs, standards, guidelines, textbooks, government or professional bodies | Facts, definitions, how things work | Footnoted prose |
| 🔬 Research | Peer-reviewed papers, systematic reviews, registered trials, preprints (always say "preprint") | Findings, with their design and size | Footnoted prose; `> [!example] 🔬 Study spotlight` for one worth a closer look |
| 📰 Secondary | Quality journalism, explainers by named experts, lectures, podcasts and videos with transcripts | Context, history, framing; facts only when no primary exists (say so) | Footnoted prose, or `> [!info] 📰 In the news` |
| 🗣️ First-person | Reddit, forums, personal blogs, patient or practitioner stories, interviews | What people report experiencing, never general facts | `> [!quote] 🗣️ Lived experience` boxes only |

Reject: SEO content farms, unsourced listicles, AI-generated pages, marketing and sales
pages, anonymous pages with no traceable claims, and anything you can't trace to who
wrote it. Old or superseded material isn't automatically rejected: keep it when it
explains how understanding changed, and say it's superseded.

A topic add-on can tighten these rules.

## Finding sources
- Start with the primary layer: official docs, guidelines, standards, review papers.
  Then fill specific claims, then secondary context, then first-person.
- **Search more than one engine.** Each engine surfaces different sources, so for every
  research area run the built-in `web_search` *and* DuckDuckGo *and* Google, then merge
  and dedupe. DuckDuckGo honors `site:` (use it for Reddit); Google tends to surface
  organizations, patient groups, and PDFs. Both need a **visible** managed browser
  (never the relay):
  ```js
  const ENGINES = {
    ddg: [q => "https://duckduckgo.com/?q=" + encodeURIComponent(q), 'a[data-testid="result-title-a"]'],
    google: [q => "https://www.google.com/search?hl=en&q=" + encodeURIComponent(q), "#search a:has(h3)"],
  };
  async function search(engine, q, n = 8) {
    const [url, sel] = ENGINES[engine];
    const tab = await browser.open({ name: "search-" + engine, url: url(q), headed: true,
      app: { tern: false, relay: false }, timeout: 60 });
    let hits = [];
    try {
      await tab.waitForSelector(sel, { timeout: 15000 });
      hits = await tab.evaluate(`[...document.querySelectorAll(${JSON.stringify(sel)})].slice(0, ${n})
        .map(a => ({ title: (a.innerText.split("\\n")[0] || "").trim(), href: a.href }))`);
      for (const h of hits) {   // Google wraps result links; unwrap from the query string
        const u = new URL(h.href);
        if (u.hostname.endsWith("google.com") && (u.pathname === "/url" || u.pathname.startsWith("/goto"))) {
          const target = u.searchParams.get("q") || u.searchParams.get("url");
          if (target?.startsWith("http")) { h.href = target; continue; }
          try { await tab.goto(h.href, { timeout: 10000 }); h.href = await tab.url(); } catch {}
        }
      }
    } finally { await tab.close().catch(() => {}); }   // close can throw harmlessly
    return hits;
  }
  ```
  If an engine shows a consent page or CAPTCHA, skip it for that query and say so.
  For papers, resolve DOI/PMID/PMCID through the PubMed, Europe PMC, and Crossref APIs
  and prefer the PMC or publisher open-access full text.
- **Web pages: fetch with Defuddle**, the extraction engine behind Obsidian Web Clipper
  ([github.com/kepano/defuddle](https://github.com/kepano/defuddle)), so saved pages
  match what Saje gets when she clips them herself:
  ```bash
  npx -y defuddle@0.19.6 parse '<url>' --markdown --json
  ```
  The JSON has `title`, `author`, `published`, `site`, `domain`, and `content` (clean
  markdown). Use `content` as the saved text and the metadata for frontmatter. Add
  `-l <lang>` to prefer a language version when a site offers several. If it returns
  little or no content (JavaScript-rendered page, or a 403), retry with
  `-u 'Mozilla/5.0'`, then fall back to `read <url>`.
- **Saje's own Web Clipper clips count as sources.** When dedupe finds a clip of the same
  URL, use it in place: add the About box, frontmatter keys, and passage IDs, and leave
  the clipped text as it is.
- **Other languages:** save the original text, and after each original paragraph its
  English translation as a paragraph starting `*EN:*`. Mark passage IDs on the
  translation paragraphs and cite those; the footnote says "translated from <language>".
  The reviewer checks each cited translation against the original paragraph above it.
- **Reddit:** find threads with `web_search` (`site:reddit.com <topic> <angle>`).
  Reddit blocks `curl`, `read`, `.json` endpoints, and headless browsers; open the
  thread in a **visible** managed browser and read the DOM (eval, JavaScript):
  ```js
  const url = THREAD_URL.replace(/^https?:\/\/(old|np)\.reddit\.com/, "https://www.reddit.com");
  const tab = await browser.open({ name: "reddit", url, headed: true,
    app: { tern: false, relay: false }, timeout: 60 });
  let thread;
  try {
    await tab.waitForSelector("shreddit-post", { timeout: 20000 });
    await tab.waitForSelector("shreddit-comment", { timeout: 5000 }).catch(() => {});  // loads late
    thread = await tab.evaluate(() => {
      const p = document.querySelector("shreddit-post");
      return { title: p.getAttribute("post-title"), sub: p.getAttribute("subreddit-prefixed-name"),
        created: p.getAttribute("created-timestamp"), url: location.href,
        body: p.querySelector('[slot="text-body"]')?.innerText ?? "",
        comments: [...document.querySelectorAll("shreddit-comment")].map(c => ({
          depth: c.getAttribute("depth"), score: c.getAttribute("score"),
          text: c.querySelector('[slot="comment"]')?.innerText ?? "" })) };
    });
  } finally { await tab.close().catch(() => {}); }
  ```
  Never use the relay (Saje's own logged-in Chrome) for this. Prefer detailed posts
  about a specific experience over one-liners.
- Other forums and blogs: `read <url>`.

## Saving a source note
Format: the `📘 Docs Source` template. One note per source, in `Sources/`, named
`<emoji><Title> -by- <Author>.md`. Emojis: 📜 documentation/guideline, 🔬 research,
📰 article/news, 📖 book, 🎥 video/podcast, 🗣️ first-person, 🕸️ other website.
In filenames, replace `/` and `:` with ` - ` and drop `\ * ? " < > | # ^ [ ]`: Obsidian
can't sync names containing them. For Reddit and forum posts, `<Author>` (in the filename
and in `author:`) is a group label such as `r-<sub> member` or `<forum> member`, never
the poster's username or handle.

**Dedupe first:** search the vault for the URL (without `utm_*`), DOI, PMID, or Reddit
post id in frontmatter and body. Reuse an existing note: add any missing frontmatter
and passages, don't replace its body.

Every source note opens with an **About this source** callout (format in the
`📘 Docs Source` template): what it is, who made it, kind and strength, size/population when it
applies, limits, and why the docs use it. Write it from the source itself, not memory;
the reviewer checks it.

What goes in the note:
- **Web pages and open-access papers:** the full text (Defuddle markdown), with
  navigation, ads, and comment sections removed. Very long pages: save the full sections
  you use and set `excerpt: true` with the sections listed.
- **PDFs:** download to the attachments folder with
  `curl -fL --proto '=https' -A 'Mozilla/5.0' -o "<attachments>/<slug>.pdf" '<https-url>'`,
  then check the file is really a PDF (`head -c 5` prints `%PDF-`; hosts sometimes return
  an HTML page instead). Embed it with `![[<slug>.pdf]]`, and also save its extracted text
  (`read <file>.pdf`) in the note.
- **Paywalled:** metadata, abstract, and link; `access: paywalled`. Cite it only for
  what the abstract says.
- **Video/podcast:** the transcript when one is available; otherwise metadata only and
  cite nothing from it.
- **First-person (Reddit/forums):** a paraphrase of what the person describes, plus only
  the short verbatim quotes you'll cite (from the post or the comments you use). Replace
  usernames with `OP`, `Commenter A`, `Commenter B`, and redact inline `u/...` or
  `@...` handles. Keep public writers' bylines (bloggers, journalists, named
  interviewees). Never save whole threads or whole posts.

**Mark passages:** every passage a page cites gets an Obsidian block ID at the end of
its paragraph: ` ^q1`, ` ^q2`, ... (unique within the note; continue numbering when
extending). Headings and list items take the ID on their own line ending. When you mark
list items, also save and mark the list's lead-in sentence ("Do not offer people with
ME/CFS:"); without it a list item can read as the opposite of what the source says.

**Escape Templater syntax:** saved text must not contain `<%`. Templater runs `<% %>`
code in any new note that has content. Insert a zero-width space (U+200B) between `<`
and `%` in every occurrence (in Python: `text.replace("<%", "<\u200b%")`) and set
`templater_escaped: true`.

## Citing with footnotes
Every factual claim ends with a **named** footnote. Names are stable labels
(`[^<source-key>]` or `[^<source-key>-<point>]`, lowercase, hyphens); Obsidian displays
them as numbers. Define each footnote once per page, at the bottom, and reuse the name
when the same passage supports another claim. A footnote cites one source note, and can
link one or more `^q` passages within it; put two footnotes on a claim backed by two
sources.

Footnote text explains the source in one or two lines, then links the passage:

```markdown
Claim sentence.[^keller-cpet]

[^keller-cpet]: **Keller 2024**, observational, n=84 ME/CFS (CCC, PEM required) vs 71
    controls. <The caveat from the paper that matters for this claim.>
    [[🔬Cardiopulmonary and metabolic responses… -by- Betsy Keller#^q2|passage]]
```

- Bold label: author or org and year.
- Then: kind (guideline, RCT, review, official docs, news, first-person, …), and for
  research the design, n, and population, plus the caveat that matters for this claim.
- Then the passage link `[[<Source note>#^qN|passage]]`. Continuation lines are indented
  four spaces.
- **Inside callouts, use citation chips, not footnotes.** Obsidian renders each callout
  on its own in Live Preview, so a footnote there shows as its bare label run into the
  text. Cite with a link to the passage, labelled like the footnote would be:
  `[[<Source note>#^qN|IOM 2015]]`. For more passages from the same source, add one chip
  each labelled with the ID: `[[<Source note>#^q3|q3]]`. The vault's `learn-citations`
  CSS snippet styles links to `^q` passages as small superscript chips; if the docs vault
  lacks it, copy `.obsidian/snippets/learn-citations.css` from Tech-2 and enable it in
  `appearance.json` (`enabledCssSnippets`). Chips carry no description, so keep callout
  claims to ones the box's own text explains, or that the page body footnotes too.
- First-person box:
  ```markdown
  > [!quote] 🗣️ Lived experience: r/<sub>, <year>
  > What this person describes (citing the note's paraphrase), with "short quotes" copied exactly.[[<Source note>#^q2|r/<sub> <year>]]
  ```
  Introduce it with what it illustrates. One account is an anecdote: never generalize
  from it ("many people" needs a source that counts).
- Never cite a source you haven't saved, and never cite beyond its marked passage.
- **Cite source text only.** A note's own summary sections (About box, Summary,
  Findings, Limitations written by whoever saved it) are commentary, not the source.
  They can inform a footnote's description, but a prose claim needs a passage from the
  source itself. If a needed fact appears only in commentary, fetch the source text that
  states it and add it as a marked passage.
- **Figures and tables:** numbers that appear only in figure images can't be cited.
  Say only what the text states (e.g. "the difference was significant for X") rather than
  inferring the rest from a summary.
