module Api
  class AgentSessionsController < ApplicationController


    def create
      if params[:agent_name].blank?
        return render json: { error: "agent_name is required" }, status: :unprocessable_entity
      end

      token = AgentToken.create!(agent_name: params[:agent_name])
      
      render json: {
        success: true,
        agent_name: token.agent_name,
        token: token.token
      }
    rescue => e
      render json: { success: false, error: e.message }, status: :internal_server_error
    end
  end
end
