class HomeController < ApplicationController
  before_action :authenticate_user!, only: [:index]

  def index
    if user_signed_in?
      if params[:query].present?
        @search_results_users = User.where.not(id: current_user.id)
                                    .where("username LIKE ? OR email LIKE ?", "%#{params[:query]}%", "%#{params[:query]}%")
      else
        @chat_rooms = current_user.chat_rooms.includes(:users)
      end
    end
  end
end
