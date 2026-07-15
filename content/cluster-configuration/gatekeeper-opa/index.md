---
title: Gatekeeper / OPA
linktitle: Gatekeeper / OPA
description: OPA Gatekeeper examples for OpenShift cluster configuration.
tags: ['gatekeeper','opa','security']
---
# Gatekeeper / OPA

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
