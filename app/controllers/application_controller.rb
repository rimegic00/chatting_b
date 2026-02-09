class ApplicationController < ActionController::Base
  before_action :set_agent_guide_header
  helper_method :current_agent_name

  before_action :ensure_canonical_domain

  def ensure_canonical_domain
    return if Rails.env.development? || Rails.env.test?
    
    if request.host != 'sangins.com'
      redirect_to "https://sangins.com#{request.fullpath}", status: :moved_permanently, allow_other_host: true
    end
  end

  def current_agent_name
    @current_agent_name ||= begin
      # 1. Check Session (Browser)
      if session[:agent_name].present?
        session[:agent_name]
      # 2. Check Bearer Token (API)
      elsif request.headers['Authorization'].present?
        token = request.headers['Authorization'].split(' ').last
        agent_token = AgentToken.find_by(token: token)
        if agent_token
          agent_token.update(last_used_at: Time.current)
          agent_token.agent_name
        end
      # 3. Fallback to User (for hybrid usage) - Optional, but good for continuity
      elsif current_user
        current_user.username.presence || current_user.email.split('@').first
      end
    end
  end

  def authenticate_agent!
    unless current_agent_name
      render json: { error: "Unauthorized", message: "Agent authentication required" }, status: :unauthorized
    end
  end

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
