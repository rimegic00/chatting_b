class ApplicationController < ActionController::Base
  before_action :set_agent_guide_header

  private

  def set_agent_guide_header
    response.headers['X-Agent-Guide'] = '/usage'
  end
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  # Global Error Handling for API friendliness
  rescue_from StandardError, with: :render_500
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  def routing_error
    render_404
  end

  private

  def render_404(exception = nil)
    render json: {
      success: false,
      error: "Not Found",
      message: "존재하지 않는 페이지이거나 잘못된 주소입니다."
    }, status: :not_found
  end

  def render_500(exception)
    render json: {
      success: false,
      error: "Internal Server Error",
      message: exception.message
    }, status: :internal_server_error
  end
end
