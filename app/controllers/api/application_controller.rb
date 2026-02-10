module Api
  class ApplicationController < ActionController::API
    # Authentication
    before_action :authenticate_agent_optional

    def current_agent_name
      @current_agent_name ||= begin
        if request.headers['Authorization'].present?
          token = request.headers['Authorization'].split(' ').last
          agent_token = AgentToken.find_by(token: token)
          if agent_token
            agent_token.update(last_used_at: Time.current)
            agent_token.agent_name
          end
        end
      end
    end

    def authenticate_agent!
      unless current_agent_name
        render_error(401, "UNAUTHORIZED", "Agent authentication required")
      end
    end

    def authenticate_agent_optional
      # Just to load current_agent_name if token is present
      current_agent_name
    end

    # V4.7: Identity Protection (Spoofing Prevention)
    def verify_agent_identity(claimed_name)
      return if claimed_name.blank?

      # 1. Check if name is claimed (Registered in AgentToken)
      if AgentToken.exists?(agent_name: claimed_name)
        # 2. If claimed, MUST match authenticated user
        unless current_agent_name == claimed_name
          render_error(401, "UNAUTHORIZED", "Identity Verification Failed", 
            ["The name '#{claimed_name}' is registered/protected.", 
             "You must provide a valid 'Authorization: Bearer <token>' header matching this name."])
        end
      else
        # 3. If unclaimed, currently allowing (Trust Mode)
        # Future: We might Auto-Claim or Warn here.
        response.set_header('X-Identity-Status', 'Unprotected')
      end
    end

    # V3.0: Standardized JSON Error Handling
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error

    def routing_error
      render_error(404, "NOT_FOUND", "No route matches this endpoint")
    end

    private
    
    def handle_standard_error(exception)
      render_error(500, "INTERNAL_SERVER_ERROR", exception.message)
    end

    def handle_not_found(exception)
      render_error(404, "NOT_FOUND", "Resource not found")
    end

    def handle_validation_error(exception)
      render_error(422, "VALIDATION_FAILED", exception.message, exception.record.errors.full_messages)
    end

    def render_error(status, type, message, details = nil)
      error_body = {
        success: false,
        error: {
          code: status,
          type: type,
          message: message
        }
      }
      error_body[:error][:details] = details if details.present?
      
      render json: error_body, status: status
    end


  end
end
