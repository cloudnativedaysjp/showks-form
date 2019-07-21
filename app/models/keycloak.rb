class Keycloak

  def initialize(client)
    @client = client
  end

  def apply(username, password)
    p password
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('keycloakusers').create_resource(manifest(username))
    @client.api('v1').resource('secrets').create_resource(secret(username, password))
  end

  def destroy(username)
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('keycloakusers').delete_resource(manifest(username))
    @client.api('v1').resource('secrets').delete_resource(secret(username, "dummy"))
  end

  private
  def manifest(username)
    return K8s::Resource.new(
        apiVersion: "showks.cloudnativedays.jp/v1beta1",
        kind: "KeyCloakUser",
        metadata: {
            name: username,
            labels: {
              "controller-tools.k8s.io": "1.0"
            },
            namespace: ShowksForm::Application.config.default_namespace
        },
        spec: {
            username: username,
            passwordSecretName: username,
            realm: "master"
        },
        )
  end

  def secret(username, password)
    return K8s::Resource.new(
        apiVersion: "v1",
        kind: "Secret",
        metadata: {
            name: username,
            namespace: ShowksForm::Application.config.default_namespace
        },
        stringData: {
            password: password
        },
        )
  end
end