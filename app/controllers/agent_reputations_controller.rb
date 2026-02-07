class AgentReputationsController < ApplicationController
  def show
    @agent = AgentReputation.find_by!(agent_name: params[:agent_name])
    @reputation_logs = @agent.reputation_logs.order(created_at: :asc).last(30)
    
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Agent not found"
  end
end
