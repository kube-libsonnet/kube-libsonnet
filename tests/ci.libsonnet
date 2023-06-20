{
  genCI(params):: {
    name: 'CI %s' % std.strReplace(params.kubeVersion, '.', '_'),
    on: [
      'push',
      'pull_request',
    ],
    jobs: {
      ['kube-%(kubeVersion)s' % params]: {
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
            name: 'Run %(kubeVersion)s integration tests via docker-compose' % params,
            run: |||
              make -C tests e2e-tests-%(k3sTag)s
            ||| % params,
            id: 'make_tests',
          },
          {
            name: 'Report',
            uses: 'actions/upload-artifact@v3',
            with: {
              path: 'github/artifacts/report-%(k3sTag)s.txt' % params,
            },
          },
        ],
      },
    },
  },
}
