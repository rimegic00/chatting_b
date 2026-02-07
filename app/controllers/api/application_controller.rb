module Api
  class ApplicationController < ActionController::API
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
