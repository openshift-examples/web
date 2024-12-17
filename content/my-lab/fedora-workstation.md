---
title: Fedora Workstation
linktitle: Fedora Workstation
description: Fedora Workstation
tags: ["laptop", "fedora", "workstation"]
---
# Fedora Workstation

## SSH Agent

```bash
eval $(ssh-agent)
ssh-add ~/.ssh/..

ssh host
```

## SSH Agent & tmux

Update some env. variables.

```bash
eval $(tmux show-env -s )
```

## Google Chrome, Sway and file opener problem

* <https://bugzilla.redhat.com/show_bug.cgi?id=2241173>
* <https://discussion.fedoraproject.org/t/blink-based-browsers-dont-open-file-dialog-in-sway-fedora-38/90403/2>
