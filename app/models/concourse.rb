class Concourse

  def initialize(client)
    @client = client
  end

  def apply(username)
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('concoursecipipelines').create_resource(manifest(username))
  end

  def destroy(username)
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('concoursecipipelines').delete_resource(manifest(username))
  end

  private
  def manifest(username)
    return K8s::Resource.new(
        apiVersion: "showks.cloudnativedays.jp/v1beta1",
        kind: "ConcourseCIPipeline",
        metadata: {
            name: username,
            namespace: ShowksForm::Application.config.default_namespace,
            labels: {
                "controller-tools.k8s.io": "1.0"
            }
        },
        spec: {
            target: "main",
            pipeline: username,
            manifest: pipeline
        },
        )
  end

  def pipeline
<<EOF
resources:
- name: every-1m
  type: time
  source: {interval: 1m}

jobs:
- name: navi
  plan:
  - get: every-1m
    trigger: true
  - task: annoy
    config:
      platform: linux
      image_resource:
        type: docker-image
        source: {repository: alpine}
      run:
        path: echo
        args: ["Hey! Listen!"]
EOF
  end
end