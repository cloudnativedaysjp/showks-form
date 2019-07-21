class Argocd

  def initialize(client)
    @client = client
  end

  def apply(username)
    @client.api('argoproj.io/v1alpha1').resource('applications').create_resource(manifest(username, "stg"))
    @client.api('argoproj.io/v1alpha1').resource('applications').create_resource(manifest(username, "prod"))
  end

  def destroy(username)
    @client.api('argoproj.io/v1alpha1').resource('applications').delete_resource(manifest(username, "stg"))
    @client.api('argoproj.io/v1alpha1').resource('applications').delete_resource(manifest(username, "prod"))
  end

  private
  def manifest(username, env)
    if env == "stg"
      destination = "https://35.187.202.212"
    elsif env == "prod"
      destination = "https://35.189.136.85"
    end
    return K8s::Resource.new(
        apiVersion: "argoproj.io/v1alpha1",
        kind: "Application",
        metadata: {
            name: "showks-" + username + "-" + env,
            namespace: "argocd"
        },
        spec: {
            project: "default",
            source: {
              repoURL: "https://github.com/" + ENV['GITHUB_ORG'] + "/showks-manifests-" + env + ".git",
              targetRevision: "HEAD",
              path: "manifests/showks-canvas-" + username,
            },
            syncPolicy: {
                automated: {}
            },
            destination: {
                server: destination,
                namespace: "showks"
            }
        },
        )
  end
end