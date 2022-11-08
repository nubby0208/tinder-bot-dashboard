require 'open3'
include ActionView::Helpers::DateHelper

class K8sUser
  MAX_JOBS = 20

  def initialize(user)
    @user = user
  end

  def log(msg)
    puts "#{msg}"
  end

  def create_namespace
    # cmd = "kubectl apply -f -n #{namespace}"
    cmd = "NAMESPACE=#{namespace} envsubst < ../k8s/user.yml | kubectl apply -f -"
    stdout, stderr, status = Open3.capture3(cmd)
  end

  def delete_all_jobs(cancel=false)
    job_status = cancel ? 'cancelled' : 'pending'
    jobs_names.map do |jobname|
      log "deleting #{jobname}"
      sj = SwipeJob.find(jobname.split("-")[2])
      # log "updating sj #{sj.id} #{sj.status} to cancelled"
      sj.update!(status: job_status)
    end
    SwipeJob.where(
      user: @user,
      status: 'running'
    ).update_all(status: job_status)
  end

  def sync_jobs
    # set scheduled jobs to pending
    SwipeJob
      .where(status: 'scheduled')
      .where("scheduled_at < ?", Time.zone.now)
      .update(status: 'pending')

    puts Time.zone.now

    SwipeJob
      .where(job_type: 'limit_of_likes')
      .where.not(status: 'pending')
      .where.not(status: 'running')
      .where("scheduled_at < ?", Time.zone.now)
      .update(status: 'pending')

    puts "sync time"
    true
  end

  # running job is a job that has a pod
  # (a job that has a non-nil duration)
  def jobs_ids_running
    jobs_status.select { |j| j['AGE'] }.reject {|j| j['COMPLETIONS'] == "1/1" }.map {|j| j['NAME'].split("-")[2].to_i }
  end

  # queued job is a job that does not have a pod
  # (a job that has a nil duration)
  def jobs_ids_queued
    jobs_status.reject { |j| j['AGE'] }.map {|j| j['NAME'].split("-")[2].to_i }
  end

  def pods_status
    convert_to_hash(pods_raw[0])
  end

  def jobs_status
    convert_to_hash(jobs_raw[0])
  end

  def convert_to_hash(stdout)
    output = stdout.split("\n")
    return {} if output[0].nil?
    cols = output[0].split(" ")
    result = []
    output[1..].map do |line|
      values = line.split(" ")
      job = {}
      cols.each_with_index { |col, i| job[col] = values[i] }
      job
    end
  end

  def sync_limit_of_like
    SwipeJob
      .where(job_type: 'limit_of_likes')
      .update(status: 'ran_limit_of_likes')
  end

  def namespace
    "user-#{@user.id}-#{@user.name.downcase}"
  end

  def jobs
    cmd = "kubectl get jobs -n #{namespace}"
    stdout, stderr, status = Open3.capture3(cmd)
    # convert_to_hash(stdout)
    stdout.split("\n").map {|x| x.split(" ") }[1..]
  end

  def pods
    cmd = "kubectl get pods -n #{namespace}"
    stdout, stderr, status = Open3.capture3(cmd)
    # convert_to_hash(stdout)
    stdout.split("\n").map {|x| x.split(" ") }[1..]
  end

  def pods_raw
    cmd = "kubectl get pods -n #{namespace}"
    stdout, stderr, status = Open3.capture3(cmd)
  end

  def pods_names
    raw = pods_raw[0]
    return [] if raw == ""
    raw.split("\n")[1..].map {|l| l.split(" ")[0] }
  end

  def pods_ids
    pods_names.map {|j| j.split("-")[2].to_i }
  end

  def jobs_raw
    cmd = "kubectl get jobs -n #{namespace}"
    # log cmd
    stdout, stderr, status = Open3.capture3(cmd)
    #.split(" ")[0]
    # case stdout
    # when ""
    #   nil
    # else
    #   nil
    # end
  end

  def jobs_names
    raw = jobs_raw[0]
    return [] if raw == ""
    raw.split("\n")[1..].map {|l| l.split(" ")[0] }
  end

  def jobs_ids
    jobs_names.map {|j| j.split("-")[2].to_i }
  end
end
