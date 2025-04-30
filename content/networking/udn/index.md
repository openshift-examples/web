---
title: User Defined Networks
linktitle: User Defined Networks
description: User Defined Networks (UDN)
tags: ['UDN','v4.18']
---
# User Defined Networks (UDN)

Official documentation:

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.18.8|
|OpenShift Virt|v4.18.2|

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
