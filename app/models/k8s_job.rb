require 'open3'
class K8sJob
  def initialize(swipe_job)
    @swipe_job = swipe_job
  end

  def user
    @swipe_job.owner
  end

  def namespace
    "user-#{user.id}-#{user.name.downcase}"
  end

  def name
    "swipejob-#{@swipe_job.job_type.gsub("_","")}-#{@swipe_job.id}"
  end

  def running?
  end

  def create_service
    SwipeJob.where(user_id: user).update(port: nil)
    # delete any existing services
    puts "deleting all services first"
    # cmd = "kubectl delete svc -n #{namespace} --all"
    # puts "running cmd: `#{cmd}`"
    # stdout, stderr, status = Open3.capture3(cmd)

    port = Port.find_by(user: user)
    @swipe_job.update!(port: port)

    cmd = "NODEPORT=#{port.port} JOBID=#{@swipe_job.id} NAMESPACE=#{namespace} envsubst < ../k8s/job_svc.yml | kubectl apply -f -"
    stdout, stderr, status = Open3.capture3(cmd)
    stdout
  end

  def create
    # cmd = "kubectl apply -f -n #{namespace}"
    # cmd = "NODEPORT=#{@swipe_job.port.port} JOBID=#{@swipe_job.id} NAMESPACE=#{namespace} envsubst < ../k8s/job.yml | kubectl apply -f -"
    cmd = "JOBTYPE=#{@swipe_job.job_type.gsub("_","")} JOBID=#{@swipe_job.id} NAMESPACE=#{namespace} envsubst < ../k8s/job.yml | kubectl apply -f -"
    stdout, stderr, status = Open3.capture3(cmd)
  end

  def delete
    cmd = "kubectl delete job -n #{namespace} #{name}"
    stdout, stderr, status = Open3.capture3(cmd)
  end

  def status
    cmd = "kubectl get jobs -n #{namespace} #{name}"
    stdout, stderr, status = Open3.capture3(cmd)
  end
end
