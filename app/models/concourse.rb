class Concourse

  def initialize(client)
    @client = client
  end

  def apply(username)
    set_pipeline("stg", username)
    set_pipeline("prod", username)
    set_pipeline("pr", username)
  end

  def destroy(username)
    @client.api('showks.cloudnativedays.jp/v1beta1')
        .resource('concoursecipipelines')
        .delete_resource(manifest(username, "stg", ""))
    @client.api('showks.cloudnativedays.jp/v1beta1')
        .resource('concoursecipipelines')
        .delete_resource(manifest(username, "prod",""))
    @client.api('showks.cloudnativedays.jp/v1beta1')
        .resource('concoursecipipelines')
        .delete_resource(manifest(username, "pr", ""))
  end

  def load_yaml(env)
    YAML.load_file("app/assets/concourse-pipeline-templates/" + env + ".yaml")
  end

  def set_pipeline(env, username)
    y = load_yaml(env)

    if env == "stg" || env == "prod"
      y["resources"].select {|n| n["name"] == "app"}[0]["webhook_token"] = ENV['WEBHOOK_TOKEN']
      y["resources"].select {|n| n["name"] == "container-image"}[0]["source"]["username"] = ENV['REGISTRY_USERNAME']
      y["resources"].select {|n| n["name"] == "container-image"}[0]["source"]["password"] = ENV['REGISTRY_PASSWORD']
      y["resources"].select {|n| n["name"] == "container-image"}[0]["source"]["repository"] = ENV['REGISTRY_URL'] + "-USERNAME"
      y["jobs"].select{|n| n["name"] == "upload-manifest"}[0]["plan"]
          .select{|n| n["task"] == "update-manifest"}[0]["params"]["AWS_ACCESS_KEY_ID"] = ENV['STORAGE_ACCESS_KEY']
      y["jobs"].select{|n| n["name"] == "upload-manifest"}[0]["plan"]
          .select{|n| n["task"] == "update-manifest"}[0]["params"]["AWS_SECRET_ACCESS_KEY"] = ENV['STORAGE_SECRET_KEY']
    elsif env == "pr"
      y["resources"].select {|n| n["name"] == "showks-canvas-pr"}[0]["webhook_token"] = ENV['WEBHOOK_TOKEN']
      y["resources"].select {|n| n["name"] == "showks-canvas-pr"}[0]["source"]["access_token"] = ENV['GITHUB_ACCESS_TOKEN']
      y["resources"].select {|n| n["name"] == "showks-canvas-pr"}[0]["source"]["github_key"] = ENV['GITHUB_PRIVATE_KEY']
      y["resources"].select {|n| n["name"] == "showks-canvas-pr"}[0]["source"]["repo"] = ENV['REGISTRY_URL'] + "-USERNAME"
    end

    pipeline = YAML.dump(y).gsub("USERNAME", username).gsub("GITHUB_PRIVATE_KEY", + '"' + ENV["GITHUB_PRIVATE_KEY"] + '"')
    @client.api('showks.cloudnativedays.jp/v1beta1')
        .resource('concoursecipipelines')
        .create_resource(manifest(username, env, pipeline))
  end

  private
  def manifest(username, env, pipeline)
    return K8s::Resource.new(
        apiVersion: "showks.cloudnativedays.jp/v1beta1",
        kind: "ConcourseCIPipeline",
        metadata: {
            name: username + "-" + env,
            namespace: ShowksForm::Application.config.default_namespace,
            labels: {
                "controller-tools.k8s.io": "1.0"
            }
        },
        spec: {
            target: "main",
            pipeline: username + "-" + env,
            manifest: pipeline
        },
        )
  end
end