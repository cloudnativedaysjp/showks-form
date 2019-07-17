class Keycloak

  def initialize(client)
    @client = client
  end

  def apply(username, password)
    p manifest(username, password)
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('keycloakusers').create_resource(manifest(username, password))
  end

  private
  def manifest(username, password)
    return K8s::Resource.new(
        apiVersion: "showks.cloudnativedays.jp/v1beta1",
        kind: "KeyCloakUser",
        metadata: {
            name: username,
            labels: {
              "controller-tools.k8s.io": "1.0"
            },
            namespace: "default"
        },
        spec: {
            username: username,
            password: password,
            realm: "master"
        },
        )
  end
end