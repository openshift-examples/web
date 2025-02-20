---
title: New Page
linktitle: New Page
description: Some information
tags: ['tagA','tagB','v4.17']
---
# Some information

Official documentation:

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.17.14|
|OpenShift Virt|v4.17.4|

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
