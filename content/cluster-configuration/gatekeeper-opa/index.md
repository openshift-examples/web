---
title: Gatekeeper / OPA
linktitle: Gatekeeper / OPA
description: OPA Gatekeeper examples for OpenShift cluster configuration.
tags: ['gatekeeper','opa','security']
---
# Gatekeeper / OPA

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
