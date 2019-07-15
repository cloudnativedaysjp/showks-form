class GitHub

  def initialize(client)
    @client = client
  end

  def apply(username, github_id)
    @client.api('showks.cloudnativedays.jp/v1beta1').resource('deployments').create_resource(github_resource(username, github_id))
  end

  private
  def github_resource(username, github_id)
    return K8s::Resource.new(
        apiVersion: "showks.cloudnativedays.jp/v1beta1",
        kind: "GithubRepository",
        metadata: {
            name: username,
        },
        spec: {
            org: "cloudnativedaysjp",
            name: "showks-canvas-" + username,
            repositoryTemplate: {
                org: "containerdaysjp",
                name: "showks-canvas",
                initialBranches:
                    [
                        "refs/heads/master:refs/heads/master",
                        "refs/heads/master:refs/heads/staging",
                        "refs/heads/master:refs/heads/feature"
                    ]
            },
            collaborators: [
                {name: github_id, permission: "admin"}
            ],
            branchProtection: {
                enforceAdmins: false,
                requiredPullRequestReviews: nil,
                requiredStatusChecks: {
                    strict: true,
                    contexts: [],
                },
                restrictions: {
                    users: [],
                    teams: ["showks-members"],
                },
            },
            webhooks: [
                {
                    name: "web",
                    config: {
                        url: "https://example.com",
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