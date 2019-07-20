class Argocd

  def initialize(client)
    @client = client
  end

  def apply(username)
    @client.api('argoproj.io/v1alpha1').resource('applications').create_resource(manifest(username))
  end

  def destroy(username)
    @client.api('argoproj.io/v1alpha1').resource('applications').delete_resource(manifest(username))
  end

  private
  def manifest(username)
    return K8s::Resource.new(
        apiVersion: "argoproj.io/v1alpha1",
        kind: "Application",
        metadata: {
            name: "showks-" + username,
            namespace: "argocd"
        },
        spec: {
            project: "default",
            source: {
              repoURL: "https://github.com/" + ENV['GITHUB_ORG'] + "/showks-manifests-stg.git",
              targetRevision: "HEAD",
              path: "manifests/showks-canvas-" + username,
            },
            syncPolicy: {
                automated: {}
            },
            destination: {
                server: "https://kubernetes.default.svc",
                namespace: "showks"
            }
        },
        )
  end
end