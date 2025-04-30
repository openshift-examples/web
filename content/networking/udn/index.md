---
title: User-defined networks
linktitle: User-defined networks
description: User-defined networks (UDN)
tags: ['UDN','v4.18']
---
# User-defined networks (UDN)

Official documentation:

  * [16.2.1. About user-defined networks ](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/networking/multiple-networks#about-user-defined-networks)

Resources:

 * https://github.com/maiqueb/fosdem2025-p-udn/tree/main
 * https://asciinema.org/a/699323
 * `203.0.113.0/24` - [IANA IPv4 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml)


Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.18.8|
|OpenShift Virt|v4.18.2|

## DrawIO testing

![](overview.drawio)

## Namespaces

|Namespace|UDN or CUDN|P-UDN IP Range|
|---|---|---|
|red|UDN|`192.0.2.0/24`|
|blue|UDN|`198.51.100.0/24`|
|green|CUDN|`203.0.113.0/24`|
|yellow|CUDN|`203.0.113.0/24`|


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
