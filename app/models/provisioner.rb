require 'k8s-client'

class Provisioner
  attr_accessor :client, :config, :resource

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

  def provision(username, github_id)
    GitHub.new(@client).apply(username, github_id)
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