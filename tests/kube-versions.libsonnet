local ci = import 'ci.libsonnet';
{
  // From https://hub.docker.com/r/rancher/k3s/tags
  versions:: {
    'v1.22': 'v1.22.2-k3s1',
    'v1.23': 'v1.23.17-k3s1',
    'v1.24': 'v1.24.14-k3s1',
    'v1.25': 'v1.25.10-k3s1',
    'v1.26': 'v1.26.5-k3s1',
    'v1.27': 'v1.27.2-k3s1',
  },
  kubeVersions:: std.objectFields($.versions),
  k3sTags:: std.objectValues($.versions),
  ghWorkflowFiles:: {
    ['ci-%s.yml' % version]: ci.genCI(params={
      kubeVersion: version,
      k3sTag: $.versions[version],
    })
    for version in $.kubeVersions
  },
}
