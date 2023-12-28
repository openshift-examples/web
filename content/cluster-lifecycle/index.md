---
title: Cluster lifecycle
linktitle: Cluster lifecycle
description: Cluster lifecycle
icon: material/folder-sync
hide: ['toc']
---

# Cluster lifecycle

## Content

{% set current_page_title = page.title %}
{% for n in navigation if n.title == current_page_title %}
{% for c in n.children if c.title != current_page_title %}
{% if c.abs_url is string %}

- [{{ c.title }}]({{c.abs_url}})

{% else %}

- **[{{ c.title }}]({{ c.children[0].abs_url }})**

{% endif %}
{% endfor %}
{% endfor %}
