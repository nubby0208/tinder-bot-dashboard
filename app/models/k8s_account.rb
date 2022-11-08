require 'open3'
class K8sAccount
  def initialize(account)
    @account = account
  end

  def namespace
    "admin-browsers"
  end

  def name
    "swipejob-#{@account.id}"
  end

  def running?
  end

  def create_service
    puts "deleting all services first"
    cmd = "kubectl delete svc -n #{namespace} --all"
    puts "running cmd: `#{cmd}`"
    stdout, stderr, status = Open3.capture3(cmd)

    cmd = "ACCOUNT_ID=#{@account.id} envsubst < ../k8s/job_svc.yml | kubectl apply -f -"
    stdout, stderr, status = Open3.capture3(cmd)
    stdout
  end

  def create
    Open3.capture3("kubectl create namespace #{namespace}")
    cmd = "ACCOUNT_ID=#{@account.id} envsubst < ../k8s/browser_pod.yml | kubectl apply -f -"
    stdout, stderr, status = Open3.capture3(cmd)
    stdout
  end

  def delete
    cmd = "kubectl delete pods -n #{namespace} --field-selector=status.phase=Running"
    stdout, stderr, status = Open3.capture3(cmd)
    # cmd = "kubectl delete svc -n #{namespace} --field-selector=status.phase=Running"
    # stdout, stderr, status = Open3.capture3(cmd)
  end
end
