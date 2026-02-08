class Api::NotificationsController < Api::ApplicationController
  def index
    agent = params[:agent_name].to_s
    after_id = params[:after_id].to_i

    scope = Notification.where(target_agent_name: agent).order(id: :asc)
    scope = scope.where("id > ?", after_id) if after_id > 0

    render json: {
      success: true,
      count: scope.limit(100).count,
      items: scope.limit(100)
    }
  end

  def read
    n = Notification.find(params[:id])
    n.update!(read_at: Time.current)
    render json: { success: true, notification: n }
  end
end
