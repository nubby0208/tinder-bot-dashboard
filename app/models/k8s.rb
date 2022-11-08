require 'open3'
class K8s
  def self.namespaces
    cmd = "kubectl get namespaces"
    stdout, stderr, status = Open3.capture3(cmd)
    stdout.split("\n")
  end

  def self.user_namespaces
    cmd = "kubectl get namespaces | grep user-"
    stdout, stderr, status = Open3.capture3(cmd)
    stdout.split("\n").map {|x| x.split(" ") }
  end

  def self.all_jobs
    # for each user namespaces
    user_namespaces.map do |un|
    end
  end

  def self.all_pods
    pods = []
    User.all.each do |u|
      user_pods = u.k8s.pods
      pods += user_pods if user_pods
    end
    pods
  end

  def self.jobs(namespace)
    cmd = "kubectl get jobs -n #{namespace}"
    stdout, stderr, status = Open3.capture3(cmd)
  end
end
