SHELL=/bin/bash
# Edit tests/kube-versions.libsonnet to update the Kubernetes versions
# we run integration tests for.
-include Makefile.versions
#E2E_K3S_VERSIONS=$(shell jsonnet  -e 'std.join(" ",(import "kube-versions.libsonnet").k3sTags)'|xargs)
E2E_K8S_VERSIONS=$(shell jsonnet  -e 'std.join(" ",(import "kube-versions.libsonnet").kubeVersions)'|xargs)

JSONNET_FMT=

LIB_JSONNET=$(wildcard ../*.libsonnet)
# jsonnet manifests for kube-validate target, exercising `kubecfg validate ...`
# against a live Kube API endpoint
ALL_K8S_VALIDATE_JSONNET=$(wildcard *-validate.pass.jsonnet)

# Filenames provide expected testing result (pass|fail)
PASS_JSONNET=$(sort $(wildcard test*pass.jsonnet))
FAIL_JSONNET=$(sort $(wildcard test*fail.jsonnet))
UNIT_JSONNET=$(sort $(wildcard unittest*.jsonnet))

ALL_JSONNET=$(sort $(wildcard *.jsonnet))

# Phony %.diff and golden/*.json targets
PHONY_GOLDEN=$(patsubst %.jsonnet,golden/%.json,$(PASS_JSONNET))
PHONY_DIFF=$(patsubst %.jsonnet,%.diff,$(PASS_JSONNET))

# Phony %.eval-pass and %.eval-fail targets
PHONY_EVAL_PASS=$(patsubst %.jsonnet,%.eval-pass,$(PASS_JSONNET))
PHONY_EVAL_FAIL=$(patsubst %.jsonnet,%.eval-fail,$(FAIL_JSONNET))

## NOTE: below values need to be in-sync with docker-compose.yaml
##       (not automated to avoid over-engineering the manifests)
DOCKER_E2E=e2e-test
TMP_RANCHER=./tmp-rancher
PROJECT=kubelibsonnet

# All tests, run from docker-compose built docker containers,
# to (also) avoid the need for local tools install, see ./Dockerfile
tests: $(patsubst %,e2e-tests-%,$(E2E_K3S_VERSIONS))
	@echo "SUCCESS: verified Kubernetes versions:"
	@cat $(TMP_RANCHER)/report*.txt
	@test -n "$${GITHUB_STEP_SUMMARY}" || exit 0; cat $(TMP_RANCHER)/report*.txt >> "$${GITHUB_STEP_SUMMARY}"
	@rm -rf ./$(TMP_RANCHER)

update-versions:
	rm -f ../.github/workflows/ci-v*.yml
	jsonnet  -m ../.github/workflows -e '(import "kube-versions.libsonnet").ghWorkflowFiles'
	echo "E2E_K3S_VERSIONS=$$(jsonnet  -e 'std.join(" ",(import "kube-versions.libsonnet").k3sTags)'|xargs)" > Makefile.versions
	sed -E -i \
		-e '/^Tested Kubernetes versions:/s/:.*/: $(E2E_K8S_VERSIONS)/' \
		-e '/^Tested Kubernetes versions:/s,(v[0-9.]+),[![\1](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-\1.yml/badge.svg)](https://github.com/kube-libsonnet/kube-libsonnet/actions/workflows/ci-\1.yml),g' \
		../README.md

# These target is dynamically driven from e2e-test-% above, run as
# e.g. `e2e-tests-v1.17.2-k3s1`
e2e-tests-%: req-docker req-docker-compose
	install -d $(TMP_RANCHER)/root/etc && touch $(TMP_RANCHER)/root/etc/k3s.yaml
	env USERID=$$(id -u) K3S_VERSION=$(*) docker-compose -p $(PROJECT) up -d
	rc=$$(timeout 60s docker wait $(DOCKER_E2E)) || rc=255 ;\
	   test $$rc -ne 0 && docker logs k3s-api;\
	   docker logs $(DOCKER_E2E); \
	   exit $$rc
	@# Peek e2e test output for Kubernetes versions tested
	docker logs $(DOCKER_E2E)| egrep '^Server.Version.+' | sort -u >> $(TMP_RANCHER)/report.txt
	docker-compose -p $(PROJECT) down
	rm -rf ./$(TMP_RANCHER)/root

# Tests safe to run without a live Kube API endpoint,
# but still requiring local `jsonnet` install
local-tests: unittests lint assertion-tests golden-diff

# NB: unittest jsonnet files are also covered by eval-pass and diff targets,
#     called out here for convenience
unittests: req-jsonnet
	jsonnet $(UNIT_JSONNET)

lint: req-jsonnetfmt
	@set -e; errs=0; \
        for f in $(ALL_JSONNET) $(LIB_JSONNET); do \
	  if ! jsonnetfmt --test $(JSONNET_FMT) -- $$f; then \
	    echo "FAILED lint: $$f" >&2; \
	    errs=$$(( $$errs + 1 )); \
	  fi; \
	done; \
	if [ $$errs -gt 0 ]; then \
	  echo "NOTE: if the 'lint' target fails, run:"; \
	  echo "      $(MAKE) fix-lint lint"; \
	  exit 1; \
	fi

assertion-tests: req-jsonnet $(PHONY_EVAL_PASS) $(PHONY_EVAL_FAIL)

golden-diff: diff-help $(PHONY_DIFF)

# Used to initialize docker'ized KubeAPI via k3s
kube-init: req-kubectl req-kubecfg
	kubectl version --short | grep k3s # void falsely initializing live clusters
	kubecfg update init-kube.jsonnet && exit 0; rc=$$?; echo ERROR kubecfg; exit $$rc

kube-validate: req-kubectl req-kubecfg
	timeout 10 kubectl api-versions > /dev/null \
	|| { echo "WARNING: no usable runtime kube context, skipping."; exit 0 ;} \
	&& kubectl version --short && kubecfg version && kubecfg validate --ignore-unknown=false $(ALL_K8S_VALIDATE_JSONNET)

%.diff: %.jsonnet
	diff -u golden/$(*).json <(jsonnet $(<))

%.eval-pass: %.jsonnet
	@echo "INFO: must PASS: $(<)"
	@(jsonnet $(<) > /dev/null)
	@echo "OK[PASS]: $(<)"

%.eval-fail: %.jsonnet
	@echo "INFO: must FAIL: $(<)"
	@echo -n "| "; (jsonnet $(<) > /dev/null) 2>&1 | grep RUNTIME.ERROR
	@echo "OK[FAIL]: $(<)"


golden/%.json: %.jsonnet
	jsonnet $(<) > $(@)

diff-help:
	@echo "NOTE: if the 'golden-diff' target fails, review output and run:"
	@echo "      $(MAKE) gen-golden golden-diff"
	@echo

fix-lint: req-jsonnetfmt
	@set -e; \
	for f in $(ALL_JSONNET) $(LIB_JSONNET); do \
	  echo jsonnetfmt -i $(JSONNET_FMT) -- $$f; \
	  jsonnetfmt -i $(JSONNET_FMT) -- $$f; \
	done

req-%:
	@which $(*) >/dev/null && exit 0; echo "ERROR: '$(*)' is required in PATH"; exit 1

clean-golden:
	rm -f $(PHONY_GOLDEN)

gen-golden: clean-golden $(PHONY_GOLDEN)

.PHONY: unittests lint eval-pass eval-fail validate golden-diff %.eval-pass %.evail-fail %.diff golden/%.json diff-help fix-lint gen-golden clean-golden update-versions
