module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_authentication
  end
end
