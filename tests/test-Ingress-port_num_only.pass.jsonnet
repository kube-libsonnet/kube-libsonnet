local bitnami = import '../bitnami.libsonnet';
local kube = import '../kube.libsonnet';

local stack = {
  name:: 'test-Ingress-pass',
  pod: kube.Pod($.name + '-pod') {
    spec+: {
      containers_+: {
        foo_cont: kube.Container($.name) {
          image: 'nginx:1.12',
          ports_+: {
            http: { containerPort: 80 },
            metrics: { containerPort: 9099 },
          },
        },
      },
    },
  },
  deploy: kube.Deployment($.name + '-deploy') {
    local this = self,
    spec+: {
      template+: {
        spec+: $.pod.spec {
        },
      },
    },
  },
  service: kube.Service($.name + '-svc') {
    local this = self,
    target_pod: $.deploy.spec.template,
    name_port+:: {
      // Force port to _only_ be below number (note no `+::` construct)
      port_spec:: { number: 4242 },
    },
  },
  ingress: bitnami.Ingress($.name + '-ingress') {
    host: 'foo.g.dev.bitnami.net',
    target_svc: $.service,
  },
};

stack {
  // Assert we got expected port number for Ingress
  assert (stack.ingress.spec.rules[0].http.paths[0].backend.service.port == { number: 4242 }),
}
