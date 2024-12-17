---
title: My Lab notes
linktitle: My Lab notes
description: My Lab notes
icon: material/folder-home
hide: ['toc']
---

# My Lab notes

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
