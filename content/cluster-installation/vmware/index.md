---
title: Cluster installation on VMware/vSphere
linktitle: VMware/vSphere
description: Cluster installation on VMware/vSphere
icon: simple/vmware
hide: ['toc']
---

# Cluster installation on VMware/vSphere

## Permission-check

Please check-out <https://github.com/openshift-examples/vmware-permission-check>

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
