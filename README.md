[![Build Status](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci.yml)

# kube-libsonnet

This repository was originally forked from Bitnami's
[kube-libsonnet](https://github.com/bitnami-labs/kube-libsonnet)
project on June/2023, in an effort to keep it up-to-date with the latest
Kubernetes releases.

## Tests

Unit and integration tests are run via Github workflows.

Tested Kubernetes versions: [![v1.22](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.22.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.22.yml) [![v1.23](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.23.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.23.yml) [![v1.24](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.24.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.24.yml) [![v1.25](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.25.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.25.yml) [![v1.26](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.26.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.26.yml) [![v1.27](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.27.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-v1.27.yml)

## Using this repository

### jsonnet-bundler

You can use [jb](https://github.com/jsonnet-bundler/jsonnet-bundler)
to include this project as a `vendor/`-ed folder:

1. Install https://github.com/jsonnet-bundler/jsonnet-bundler
2. Run:

```shell
$ jb init
$ jb install https://github.com/kube-libsonnet/kube-libsonnet
$ git add vendor/ jsonnetfile.json jsonnetfile.lock.json
```

3. Create your Kubernetes manifest, for example

```shell
$ cat nginx.jsonnet
local kube = import 'vendor/kube-libsonnet/kube.libsonnet';

local nginx_stack = {
  nginx_deploy: kube.Deployment('nginx') {
    spec+: {
      replicas: 3,
      template+: {
        spec+: {
          containers_+: {
            nginx: kube.Container('nginx') {
              image: 'bitnami/nginx:latest',  // NB: you shouldn't use latest in prod ;)
              resources: { requests: { cpu: '100m', memory: '100Mi' } },
              env_+: {
                NGINX_ENABLE_ABSOLUTE_REDIRECT: 'yes',
                NGINX_ENABLE_PORT_IN_REDIRECT: 'yes',
              },
              ports_+: { http: { containerPort: 8080 } },
            },
          },
        },
      },
    },
  },
  nginx_svc: kube.Service('nginx') {
    target_pod: $.nginx_deploy.spec.template,
  },
};

// Manifest a kubectl- ingestable JSON (kube.List is not part
// of the Kubernetes API itself, but rather a pseudo-object
// usable to host Kubernetes objects in its `items: [...]` array.
kube.List() {
  items_+: nginx_stack,
}

$ jsonnet nginx.jsonnet|kubeconform -verbose -
stdin - Service nginx is valid
stdin - Deployment nginx is valid
```

### git submodule
Accordingly, above `kube-manifests` has been changed to use this repo as
a git submodule, i.e.:

    $ git submodule add https://github.com/kube-libsonnet/kube-libsonnet
    $ cat .gitmodules
    [submodule "lib"]
    path = lib
    url = https://github.com/kube-libsonnet/kube-libsonnet

## Testing

Unit and e2e-ish testing at tests/, needs usable `docker-compose`
setup at node, will run a `k3s` "dummy" container to serve Kube API,
"enough" to run `kubecfg validate` against it:

    make tests

If you don't want that full kube-api stack (will then use your "local"
kubernetes configured environment), you can run:

    make -C tests update-versions local-tests kube-validate
