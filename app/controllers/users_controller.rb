class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.where.not(id: current_user.id)
    if params[:query].present?
      @users = @users.where("username ILIKE ? OR email ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%")
    end
  end
end
