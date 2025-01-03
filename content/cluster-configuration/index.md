---
title: Cluster configuration
linktitle: Cluster configuration
description: Cluster configuration
icon: material/folder-wrench
hide: ['toc']
---
# Cluster configuration

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
