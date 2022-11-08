# class JobsController < ApplicationController
#   def logs
#     job = SwipeJob.find(params[:id])
#     @id = job.id
#     JobsChannel.broadcast_to(job,"connected")
#     render layout: false
#   end
# end

require 'faraday'
require 'json'

class JobsController < ApplicationController
    def logs       
      job = SwipeJob.find(params[:id])
      @id = job.id            
      @msTime= params[:ms_time]      
    # url = "https://jsonplaceholder.typicode.com/todos/#{@id}/#{@msTime}"
      # url = "http://localhost:64102/api/Bots/RunBots/#{@id}/#{@msTime}"
      # response = Faraday.get(url, {a: 1}, {'Accept' => 'application/json'})
      # joke_object = JSON.parse(response.body, symbolize_names: true)
      # render json: joke_object
      render false
    end
end
