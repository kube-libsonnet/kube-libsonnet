[![Build Status](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci.yml)

# kube-libsonnet

This repository was originally forked from the
[kube-libsonnet](https://github.com/bitnami-labs/kube-libsonnet)
project.

Accordingly, above `kube-manifests` has been changed to use this repo as
a git submodule, i.e.:

    $ git submodule add https://github.com/bitnami-labs/kube-libsonnet
    $ cat .gitmodules
    [submodule "lib"]
    path = lib
    url = https://github.com/bitnami-labs/kube-libsonnet

## Testing

Unit and e2e-ish testing at tests/, needs usable `docker-compose`
setup at node, will run a `k3s` "dummy" container to serve Kube API,
"enough" to run `kubecfg validate` against it:

    make tests

If you don't want that full kube-api stack (will then use your "local"
kubernetes configured environment), you can run:

    make -C tests local-tests kube-validate
