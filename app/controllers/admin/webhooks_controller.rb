module Admin
  class WebhooksController < ApplicationController
    before_action :authenticate_admin! # Assuming there is an admin check method or devise
    
    def index
      @webhooks = Webhook.order(created_at: :desc)
    end
    
    private
    
    def authenticate_admin!
      # Placeholder for actual admin check
      # redirect_to root_path unless current_user&.admin?
    end
  end
end
