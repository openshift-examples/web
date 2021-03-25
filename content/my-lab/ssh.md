# X-Forward

## Server

 * X11Forwarding enabled?
 * xauth installed?


```
grep X11Forwarding /etc/ssh/sshd_config
X11Forwarding yes

# type xauth
xauth is /usr/bin/xauth

```
## Client


# SSH Agent

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

