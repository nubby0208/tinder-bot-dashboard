class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  impersonates :user
end
