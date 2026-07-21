# OpenShift Examples — examples.openshift.pub

MkDocs Material documentation site collecting practical OpenShift / Kubernetes
examples and lab notes. Author: Robert Bohne.

## Tech stack

- **Static site generator**: MkDocs with Material theme
- **Extensions**: pymdownx (highlight, superfences, tabbed, snippets, tasklist, details, emoji), admonition, attr_list, meta, toc
- **Plugins**: search, git-revision-date-localized, git-authors, tags, macros (Jinja), glightbox, drawio, mike, privacy
- **Custom hook**: `hooks/sha256_filter.py` — adds a `sha256` Jinja filter
- **Linting**: markdownlint (`.mdl_style.rb`) + yamllint (`.yamllint`) via pre-commit
- **Build**: Containerfile-based (`builder.Containerfile`), deployed via ArgoCD (`.argocd/`) and Tekton (`.tekton/`)

## Repository layout

```text
content/          — all documentation pages (docs_dir in mkdocs.yml)
overrides/        — Material theme overrides and custom icons
assets/           — extra CSS (powered-by.css)
hooks/            — MkDocs Python hooks
deploy/           — Helm chart / deployment manifests
.argocd/          — ArgoCD app definition
.tekton/          — Tekton pipeline definitions
mkdocs.yml        — site config, nav tree, plugins, extensions
new-page-template.md — canonical template for new content pages
```

## Development workflow

1. Create a feature branch — never commit directly to `main`.
2. Make changes.
3. **MANDATORY**: Run `./run-local-pre-commit.sh` before pushing. It executes markdownlint and yamllint via pre-commit. Fix any issues before pushing. Never skip this step.
4. Push the branch and open a PR against `main`.
5. GitHub Actions (`.github/workflows/`) run linting and a preview deployment.
6. Another person reviews using the preview deployment.
7. After approval, merge into `main`.

## Key conventions

- Navigation is defined manually in the `nav:` section of `mkdocs.yml`.
- Content pages use YAML front matter (`title`, `linktitle`, `description`, `tags`).
- External files (YAML, JSON, etc.) are embedded via pymdownx snippets (`--8<--`).
- Companion files sit next to the markdown page that references them.
- Run locally with `./run-local.sh` (podman container on port 8080).
- Pre-commit checks: `./run-local-pre-commit.sh`.

## Content authoring conventions

### Front matter (required)

Every page starts with YAML front matter:

```yaml
---
title: Short Title
linktitle: Short Title
description: One-line summary
tags: ['topic','v4.18']
---
```

Optional: `icon:` for custom nav icons (e.g. `redhat/Technology_icon-Red_Hat-OpenShift_Virtualization-Standard-RGB`).

### Tested-with table

When a page documents a tested procedure, add a version table early on:

```markdown
|Component|Version|
|---|---|
|OpenShift|v4.18.19|
```

### Embedding external files (snippets)

Use pymdownx snippets to include companion YAML, JSON, or config files that sit next to the page:

```markdown
--8<-- "content/path/to/file.yaml"
```

### Download + source tab pattern

Pair a "Download" tab with a source tab so readers can both fetch and view the file:

````markdown
=== "Download: my-resource.yaml"

    ```shell
    curl -L -O {{ page.canonical_url }}my-resource.yaml
    ```

=== "my-resource.yaml"

    ```yaml
    --8<-- "content/section/my-resource.yaml"
    ```
````

### Admonitions

Use MkDocs Material admonitions:

- `!!! info` / `!!! warning` — always-open callouts
- `???+ note "Title"` — collapsible, open by default
- `??? quote "Title"` — collapsible, closed by default

### Code blocks

- Use `shell` as the language for terminal commands and output.
- Use `hl_lines` to highlight important output lines, e.g. add `hl_lines="3 4"` after the language tag.
- Code blocks with more than 4 lines must have a `title=""` attribute.
- Include `%` prompt prefix only when mixing commands with output.

### Child-page listing (index pages)

Index pages use this Jinja macro to auto-list children:

```jinja
{% set current_page_title = page.title %}
{% for n in navigation if n.title == current_page_title %}
{% for c in n.children if c.title != current_page_title %}
{% if c.abs_url is string %}
- [{{ c.title }}]({{c.canonical_url}})
{% else %}
- **[{{ c.title }}]({{ c.children[0].canonical_url }})**
{% endif %}
{% endfor %}
{% endfor %}
```

### Creating a new page (checklist)

1. **Add to nav** — add the page entry in the `nav:` section of `mkdocs.yml`.
2. **Add to Last updates** — insert a row at the top of the "Last updates" table in `content/README.md` with the date and a link (format: `|YYYY-MM-DD|[Headline](relative/path/)|`).
3. **Create directory and file** — create a new directory under `content/` and add an `index.md` based on `new-page-template.md`.

All three steps are required. The nav tree is maintained manually — pages not listed in `mkdocs.yml` will not appear in navigation.

### Heading style

Use ATX-style headings (`# H1`, `## H2`, etc.). Each page should have exactly one `# H1` matching the `title` front matter field.

## YAML conventions

### yamllint rules (from .yamllint)

- Max line length: 180 characters (warning level).
- Document start marker (`---`) is not required.
- Comments indentation check is disabled.
- Truthy values: use `true`, `false`, `yes`, `no` only.
- Braces: at most 1 space inside (warning level).

### Kubernetes / OpenShift resources

Manifests should include `apiVersion`, `kind`, and `metadata` fields in that order.
Use standard label conventions (`app`, `app.kubernetes.io/*`).

### Snippet compatibility

Many YAML files in `content/` are embedded into documentation pages via pymdownx snippets (`--8<-- "content/path/to/file.yaml"`). Keep them self-contained and readable — they are displayed verbatim in the rendered site.
