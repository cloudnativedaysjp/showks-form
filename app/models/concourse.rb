class Concourse

  def initialize(client)
    @client = client
  end

  def apply(username)
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('concourse').create_resource(manifest(username))
  end

  private
  def manifest(username)
    return K8s::Resource.new(
        apiVersion: "showks.cloudnativedays.jp/v1beta1",
        kind: "ConcourseCIPipeline",
        metadata: {
            name: username,
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

  end
end