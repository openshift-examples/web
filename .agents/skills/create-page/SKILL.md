---
name: create-page
description: >-
  Create a new documentation page/chapter in the OpenShift Examples site.
  Use when the user asks to create a new page, add a new chapter, add a new
  topic, or scaffold new content under content/.
disable-model-invocation: true
---

# Create a new documentation page

## Gather inputs

Ask the user (use AskQuestion when available):

1. **Title** — the page title (e.g. "Application Aware Quota").
2. **Parent section** — where in the nav tree it belongs (e.g. "Virtualization", "Deploy", "Cluster installation"). Offer existing top-level sections from `mkdocs.yml` as options.
3. **Tags** — topic tags and OCP version (e.g. `['aaq','cnv','v4.18']`).
4. **Description** — one-line summary.

Optional (infer sensible defaults if not provided):
- **Icon** — custom nav icon (default: omit).
- **Is index page** — whether this page will have sub-pages (default: no). If yes, include the child-page listing Jinja macro.

## Steps

### Step 1: Create the directory and index.md

Create `content/<section>/<slug>/index.md` where `<slug>` is a kebab-case version of the title.

Use the template from `new-page-template.md` as the base, filling in the gathered inputs:

```markdown
---
title: <Title>
linktitle: <Title>
description: <Description>
tags: [<tags>]
---
# <Title>

Official documentation:

Tested with:

|Component|Version|
|---|---|
|OpenShift|<version from tag>|
```

Only include the child-page listing macro if the page is an index page with sub-pages. Only include the "Tested with" table if the page documents a tested procedure. Only include the `icon` front matter field if the user provides one.

### Step 2: Add to mkdocs.yml nav

Add the new page to the `nav:` section in `mkdocs.yml` under the correct parent section. Follow the existing indentation and style. Use the path relative to `content/` (the `docs_dir`).

Example entry:
```yaml
- My New Page: section/my-new-page/index.md
```

### Step 3: Add to "Last updates" in content/README.md

Insert a new row at the **top** of the "Last updates" table in `content/README.md`. Use today's date and a link to the new page.

Format:
```markdown
|<YYYY-MM-DD>|[Added <title>](<section>/<slug>/)|
```

### Step 4: Verify

After all files are created/modified, list what was done:
1. Created `content/<section>/<slug>/index.md`
2. Added nav entry in `mkdocs.yml`
3. Added "Last updates" entry in `content/README.md`

Remind the user to run `./run-local-pre-commit.sh` before pushing.
