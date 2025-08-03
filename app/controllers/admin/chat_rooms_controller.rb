class Admin::ChatRoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!
  before_action :set_chat_room, only: [:edit, :update, :destroy]

  def index
    @chat_rooms = ChatRoom.all
  end

  def new
    @chat_room = ChatRoom.new
  end

  def create
    @chat_room = ChatRoom.new(chat_room_params)
    if @chat_room.save
      redirect_to admin_chat_rooms_path, notice: 'Chat room was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chat_room.update(chat_room_params)
      redirect_to admin_chat_rooms_path, notice: 'Chat room was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chat_room.destroy
    redirect_to admin_chat_rooms_url, notice: 'Chat room was successfully destroyed.'
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:id])
  end

  def chat_room_params
    params.require(:chat_room).permit(:title, :description, :active)
  end

  def authenticate_admin!
    unless current_user && current_user.admin?
      redirect_to root_path, alert: "관리자 권한이 없습니다."
    end
  end
end