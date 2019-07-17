require 'k8s-client'

class Provisioner
  include ActiveModel::Validations
  include ActiveModel::Model

  attr_accessor :username, :github_id, :twitter_id, :comment, :client, :config, :resource

  validates_with GitHubUserValidator
  validates :username, uniqueness: true, presence: true, format: { with: /\A[a-z0-9\-]+\z/}, length: { maximum: 30 }
  validates :github_id, uniqueness: true, presence: true, length: { maximum: 30 } #FIXME: need to check validation rule about github id
  validates :twitter_id, format: { with: /\A[a-zA-Z0-9\_]+\z/}, length: { maximum: 15 }
  validates :comment, length: { maximum: 100 }

  def initialize
    @client = K8s::Client.config(
        K8s::Config.load_file(
            File.expand_path 'kubeconfig'
        )
    )

    @client.apis.each { |a|
      puts a.api_version
      a.api_resources.each { |r|
        puts "  #{r.name}"
      }
    }
  end

  def provision(params)
    GitHub.new(@client).apply(username, github_id)
    Keycloak.new(@client).apply(username, password)
    Concourse.new(@client).apply(username)
  end

#  def deployment_resource
#    K8s::Resource.new(
#      apiVersion: 'apps/v1beta2',
#      kind: 'Deployment',
#      metadata: {
#        namespace: 'default',
#        name: 'nginx',
#      },
#      spec: {
#        selector: {
#          matchLabels: {
#            app: 'nginx'
#          }
#        },
#        replicas: 2,
#        template: {
#          metadata: {
#            labels: {app: 'nginx'}
#          },
#          spec: {
#            containers:
#            [
#              {
#                name: 'nginx',
#                image: 'nginx',
#                ports: [
#                  containerPort: 80
#                ]
#              }
#            ]
#          }
#        }
#      },
#    )
#  end
end