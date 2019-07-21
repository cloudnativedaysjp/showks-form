class GitHub

  def initialize(client)
    @client = client
  end

  def apply(username, github_id)
    p manifest(username, github_id)
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('githubrepositories').create_resource(manifest(username, github_id))
  end

  def destroy(username)
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('githubrepositories').delete_resource(manifest(username, "dummy"))
  end

  private
  def manifest(username, github_id)
    return K8s::Resource.new(
        apiVersion: "showks.cloudnativedays.jp/v1beta1",
        kind: "GitHubRepository",
        metadata: {
            name: username,
            namespace: ShowksForm::Application.config.default_namespace
        },
        spec: {
            org: "cloudnativedaysjp",
            name: "showks-canvas-" + username,
            template: {
                org: "cloudnativedaysjp",
                name: "showks-canvas",
                initialBranches:
                    [
                        "refs/heads/master:refs/heads/master",
                        "refs/heads/master:refs/heads/staging",
                        "refs/heads/master:refs/heads/feature"
                    ]
            },
            collaborators: [
                {name: github_id, permission: "push"}
            ],
            branchProtections: [{
                enforceAdmins: false,
                branchName: "master",
                requiredPullRequestReviews: {},
                requiredStatusChecks: {
                    strict: true,
                    contexts: [],
                },
                restrictions: {
                    users: [],
                    teams: ["showks-members"],
                },}],
            webhooks: [
                {
                    name: "stg",
                    config: {
                        url: "http://concourse.udcp.info/api/v1/teams/showks-pipelines/pipelines/" + username + "-stg/resources/app/check/webhook?webhook_token=" + ENV["WEBHOOK_TOKEN"],
                        contentType: "json"
                    },
                    events: ["push"],
                    active: true
                },
                {
                    name: "prod",
                    config: {
                        url: "http://concourse.udcp.info/api/v1/teams/showks-pipelines/pipelines/" + username + "-prod/resources/app/check/webhook?webhook_token=" + ENV["WEBHOOK_TOKEN"],
                        contentType: "json"
                    },
                    events: ["push"],
                    active: true
                }
            ]
        },
        )
  end
end