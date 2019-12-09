# gitlab runner on openshift

It's a mess!

## Register new runner if ~/.gitlab-runner/config.toml do not exist

```shell
export REGISTRATION_TOKEN=xxxx
export CI_SERVER_URL=https://gitlab.com/
export RUNNER_EXECUTOR=kubernetes
export LISTEN_ADDRESS=127.0.0.1:5000
export RUNNER_TAG_LIST=ocp

gitlab-runner register --non-interactive
```

## How to check running gitlab runner

```
# Do not work with env variables!

# env -i /usr/local/bin/gitlab-runner verify
gitlab-runner verify || rm ~/.gitlab-runner/config.toml
```

## Liveness

```
# Do not work with env variables!
gitlab-runner verify
```