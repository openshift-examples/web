---
title: Live Migration
linktitle: Live Migration
description: Live Migration
tags: ['tagA','tagB','v4.17']
---
# Live Migration

## Content

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
