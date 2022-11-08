Rails.application.routes.draw do
  mount ActionCable.server => "/cable"
  devise_for :users
  # get 'jobs/:id/:ms_time/logs', to: 'jobs#logs'
  mount RailsAdmin::Engine => '/', as: 'rails_admin'
end
