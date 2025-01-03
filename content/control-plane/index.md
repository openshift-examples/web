---
title: Control plane
linktitle: Control plane
description: Control plane
tags: ['control-plane']
icon: material/folder-cog
---
# Control plane

## Content

{% set current_page_title = page.title %}
{% for n in navigation if n.title == current_page_title %}
{% for c in n.children if c.title != current_page_title %}
{% if c.canonical_url is string %}

- [{{ c.title }}]({{c.canonical_url}})

{% else %}
{% if c.children[0] and c.children[0].canonical_url %}

- **[{{ c.title }}]({{ c.children[0].canonical_url }})**

{% else %}
{% endif %}
{% endif %}
{% endfor %}
{% endfor %}
