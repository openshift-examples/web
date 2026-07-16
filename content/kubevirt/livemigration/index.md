---
title: Live Migration
linktitle: Live Migration
description: Live Migration
tags: ['tagA','tagB','v4.17']
---
# Live Migration

## Content

{% set section = page.parent %}
{% if section and section.children %}
{% for c in section.children if c.title != page.title %}
{% if c.abs_url is string %}

- [{{ c.title }}]({{ c.canonical_url }})

{% else %}

- **[{{ c.title }}]({{ c.children[0].canonical_url }})**

{% endif %}
{% endfor %}
{% endif %}
