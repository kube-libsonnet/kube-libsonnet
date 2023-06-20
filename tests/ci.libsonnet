{
  genCI(params):: {
    local sanitizedVersion = std.strReplace(params.kubeVersion, '.', '_'),
    name: 'CI kube-%(kubeVersion)s' % params,
    on: [
      'push',
      'pull_request',
    ],
    jobs: {
      ['kube-%s' % sanitizedVersion]: {
        'runs-on': 'ubuntu-latest',
        steps: [
          {
            name: 'Checkout code',
            uses: 'actions/checkout@v2',
          },
          {
            name: 'Setup Docker',
            uses: 'docker/setup-buildx-action@v1',
          },
          {
            name: 'Run %(kubeVersion)s integration tests via docker-compose using %(k3sTag)s image' % params,
            run: |||
              make -C tests e2e-tests-%(k3sTag)s
            ||| % params,
            id: 'make_tests',
          },
        ],
      },
    },
  },
}
