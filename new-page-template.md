---
title: New Page
linktitle: New Page
description: Some information
tags: ['tagA','tagB','v4.17']
icon: redhat/Technology_icon-Red_Hat-OpenShift_Virtualization-Standard-RGB
---
# Some information

Official documentation:

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.17.14|
|OpenShift Virt|v4.17.4|

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
