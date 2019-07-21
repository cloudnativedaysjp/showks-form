# require 'open3'
# require 'json'
require 'k8s-client'
require 'github'

class GitHubUserValidator < ActiveModel::Validator
  def validate(record)
    if record.username.include?("demoaccount")
      return true
    end
    #client = Octokit::Client.new(login: Rails.application.credentials.github[:username], password: Rails.application.credentials.github[:password])
    begin
      client.user(record.github_id)
    rescue
      record.errors[:github_id] << 'GitHubのユーザー名が見つかりません'
    end
  end
end

class Project
  include ActiveModel::Validations
  include ActiveModel::Model
  include ActiveModel::Conversion

  attr_accessor :username, :github_id, :twitter_id, :comment, :client, :config, :resource, :id

  validates_with GitHubUserValidator
  # TODO: Implement uniqueness validator
  validates :username, presence: true, format: { with: /\A[a-z0-9\-]+\z/}, length: { maximum: 30 }
  validates :github_id, presence: true, length: { maximum: 30 } #FIXME: need to check validation rule about github id
  validates :twitter_id, format: { with: /\A[a-zA-Z0-9\_]+\z/}, length: { maximum: 15 }
  validates :comment, length: { maximum: 100 }

  def initialize
    # TODO: Consider how to configure k8s credentials.
  end

  def save(params)
    client = Project.create_client
    @id, @username, @github_id = params[:username], params[:username], params[:github_id]
    @twitter_id, @comment, @password = params[:twitter_id], params[:comment], params[:password]
    # FIXME: How to detect provisioning error?
    GitHub.new(client).apply(@username, @github_id)
    Keycloak.new(client).apply(@username, @password)
    Concourse.new(client).apply(@username)
    Argocd.new(client).apply(@username)
    # TODO: Implement tekton/argo
  end

  def destroy
    client = Project.create_client
    GitHub.new(client).destroy(@username)
    Keycloak.new(client).destroy(@username)
    Concourse.new(client).destroy(@username)
    Argocd.new(client).destroy(@username)
  end

  def self.create_client
    if ShowksForm::Application.config.in_cluster
      client = K8s::Client.in_cluster_config
    else
      client = K8s::Client.config(
          K8s::Config.load_file(
              File.expand_path 'kubeconfig'
          )
      )
    end
    client
  end

  def self.all
    projects = []
    Project.create_client.api('showks.cloudnativedays.jp/v1beta1')
      .resource('githubrepositories')
      .list(namespace: ShowksForm::Application.config.default_namespace)
      .each do |response|
        pr = Project.new
        pr.id = response.metadata[:name]
        pr.username = response.metadata[:name]
        projects.append(pr)
    end
    p projects
    projects
  end

  def self.find(username)
    pr = Project.new
    pr.id = username
    pr.username = username
    pr
  end


  def persisted?
    if @id
      true
    else
      false
    end
  end
end



# class Project < ApplicationRecord
#   include ActiveModel::Validations
#   validates_with GitHubUserValidator
#   validates :username, uniqueness: true, presence: true, format: { with: /\A[a-z0-9\-]+\z/}, length: { maximum: 30 }
#   validates :github_id, uniqueness: true, presence: true, length: { maximum: 30 } #FIXME: need to check validation rule about github id
#   validates :twitter_id, format: { with: /\A[a-zA-Z0-9\_]+\z/}, length: { maximum: 15 }
#   validates :comment, length: { maximum: 100 }
#
#   before_create :provision
#   before_destroy :cleanup
#
#   private
#   def provision
#     create_repository
#     create_webhook("staging")
#     create_webhook("production")
#     create_pr_webhook
#     commit_json
#     push_repository
#     add_collaborator
#     set_protected_branch
#     create_pipeline("staging")
#     create_pipeline("production")
#     create_pipeline("pr")
#     create_spin
#   end
#
#   def repository_name
#     "showks-canvas-#{self.username}"
#   end
#
#   def webhook_token
#     Rails.application.credentials[:webhook_token]
#   end
#
#   def pipeline_path(env)
#     "tmp/#{self.username}-#{env}.yaml"
#   end
#
#   def create_repository
#     @client = Octokit::Client.new(login: Rails.application.credentials.github[:username], password: Rails.application.credentials.github[:password])
#     if @client.repository?("containerdaysjp/#{repository_name}")
#       @repo = @client.repository("containerdaysjp/#{repository_name}")
#     else
#       @repo = @client.create_repository(repository_name,{organization: "containerdaysjp", team_id: 3013077})
#     end
#
#     @local_repo = Rugged::Repository.new("app/assets/showks-canvas")
#     @local_repo.config["user.name"]="showks-containerdaysjp"
#     @local_repo.config["user.email"]="showks-containerdaysjp@gmail.com"
#   end
#
#   def create_webhook(env)
#     @client.create_hook(
#         @repo.full_name,
#         "web",
#         {url: "https://concourse.showks.containerdays.jp/api/v1/teams/main/pipelines/#{self.username}-#{env}/resources/app/check/webhook?webhook_token=#{webhook_token}", content_type: "json"}, #TODO: Should be configurable.
#         {events: ["push"], active: true})
#   end
#
#   def create_pr_webhook
#     @client.create_hook(
#         @repo.full_name,
#         "web",
#         {url: "https://concourse.showks.containerdays.jp/api/v1/teams/main/pipelines/#{self.username}-pr/resources/showks-canvas-pr/check/webhook?webhook_token=#{webhook_token}", content_type: "json"}, #TODO: Should be configurable.
#         {events: ["pull_request"], active: true})
#   end
#
#   def commit_json
#     json = JSON.dump(
#         {
#             userName: self.username,
#             gitHubId: self.github_id,
#             twitterId: self.twitter_id,
#             comment: self.comment
#         }
#     )
#
#     File.open("app/assets/showks-canvas/src/data/author.json", "w") do |f|
#       f.puts(json)
#     end
#
#     @local_repo.create_branch(self.username, "refs/heads/master")
#     @local_repo.checkout("refs/heads/#{self.username}")
#
#     commit_author = { email: "showks-containerdaysjp@gmail.com", name: "showks-containerdaysjp", time: Time.now}
#
#     index = @local_repo.index
#     index.add("src/data/author.json")
#     commit_tree = index.write_tree(@local_repo)
#     index.write
#
#     Rugged::Commit.create(
#         @local_repo,
#         author: commit_author,
#         commiter: commit_author,
#         message: "Add",
#         parents: [@local_repo.head.target],
#         tree: commit_tree,
#         update_ref: "HEAD"
#     )
#   end
#
#   def push_repository
#     auth = Rugged::Credentials::UserPassword.new(username: Rails.application.credentials.github[:username], password: Rails.application.credentials.github[:password])
#     remote = @local_repo.remotes.create_anonymous(@repo.clone_url)
#     remote.push("refs/heads/#{self.username}:refs/heads/master", credentials: auth)
#     remote.push("refs/heads/#{self.username}:refs/heads/staging", credentials: auth)
#     remote.push("refs/heads/#{self.username}:refs/heads/feature", credentials: auth)
#     @local_repo.checkout("refs/heads/master")
#     @local_repo.branches.delete("#{self.username}")
#   end
#
#   def add_collaborator
#     unless self.username.include?("demoaccount")
#       @client.add_collaborator("containerdaysjp/#{repository_name}", self.github_id)
#     end
#   end
#
#   def set_protected_branch
#     options = {
#         enforce_admins: false,
#         required_pull_request_reviews: nil,
#         required_status_checks: {
#             strict: true,
#             contexts: []
#         },
#         restrictions: {
#             users: [],
#             teams: ["showks-members"]
#         }
#     }
#
#     @client.protect_branch("containerdaysjp/#{repository_name}", "master", options)
#     @client.protect_branch("containerdaysjp/#{repository_name}", "staging", options)
#   end
#
#   def create_pipeline(env)
#     logger.debug `fly -t form login -c #{Rails.application.credentials.concourse[:url]} \
#             -u #{Rails.application.credentials.concourse[:username]} \
#             -p #{Rails.application.credentials.concourse[:password]}`
#     logger.debug `cp app/assets/showks-concourse-pipelines/showks-canvas-USERNAME/#{env}.yaml #{pipeline_path(env)}`
#     logger.debug `sed -i '' -e 's/USERNAME/#{self.username}/' #{pipeline_path(env)}` #TODO: should replace to erb template
#     File.open("tmp/params.yaml", "w") do |f|
#       f.puts(Rails.application.credentials.concourse_params)
#     end
#     logger.debug `fly -t form set-pipeline -p #{self.username}-#{env} -c #{pipeline_path(env)} -l tmp/params.yaml -n`
#     logger.debug `fly -t form unpause-pipeline -p #{self.username}-#{env}`
#     logger.debug `fly -t form expose-pipeline -p #{self.username}-#{env}`
#   end
#
#   def create_spin
#     logger.debug Open3.capture3("./deploy-canvas-pipelines.sh #{self.username}",
#                                 chdir: "app/assets/showks-spinnaker-pipelines/showks-canvas")
#   end
#
#   def cleanup
#     delete_repository
#     destroy_pipeline
#     delete_spin
#   end
#
#   def delete_repository
#     client = Octokit::Client.new(login: Rails.application.credentials.github[:username], password: Rails.application.credentials.github[:password])
#     client.delete_repository("containerdaysjp/#{repository_name}")
#   end
#
#
#   def destroy_pipeline
#     logger.debug system("fly -t form login -c #{Rails.application.credentials.concourse[:url]} \
#             -u #{Rails.application.credentials.concourse[:username]} \
#             -p #{Rails.application.credentials.concourse[:password]}")
#     logger.debug `fly -t form destroy-pipeline -p #{self.username}-staging -n`
#     logger.debug `fly -t form destroy-pipeline -p #{self.username}-production -n`
#     logger.debug `fly -t form destroy-pipeline -p #{self.username}-pr -n`
#   end
#
#   def delete_spin
#     logger.debug Open3.capture3("./spin --config ./spinconfig application delete showks-canvas-#{self.username}",
#                                 chdir: "app/assets/showks-spinnaker-pipelines/showks-canvas")
#   end
#
#   def github_user_exists?(user)
#   end
