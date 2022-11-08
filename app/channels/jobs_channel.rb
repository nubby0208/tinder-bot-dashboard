

class JobsChannel < ApplicationCable::Channel
  def subscribed
    job = SwipeJob.find(params[:id])
    stream_for job
  end

  def unsubscribed
  end
end
