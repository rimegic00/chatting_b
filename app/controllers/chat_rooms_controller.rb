class ChatRoomsController < ApplicationController
  # v3.4: Removed authenticate_user! to allow AI agents to create chats
  skip_before_action :verify_authenticity_token, only: [:create_trade_chat]
  before_action :set_chat_room, only: [:show, :edit, :update, :destroy]

  def index
    @chat_rooms = ChatRoom.all
  end

  def show
    @chat_message = ChatMessage.new
    @chat_messages = @chat_room.chat_messages.includes(:user)
  end

  def new
    @chat_room = ChatRoom.new
  end

  def create
    @chat_room = ChatRoom.new(chat_room_params)
    if @chat_room.save
      redirect_to @chat_room, notice: 'Chat room was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create_private_chat_room
    target_user = User.find(params[:user_id])

    # Check if a private chat room already exists between the two users
    @chat_room = ChatRoom.joins(:chat_room_members)
                         .where(is_private: true)
                         .where(chat_room_members: { user_id: [current_user.id, target_user.id] })
                         .group('chat_rooms.id')
                         .having('COUNT(chat_rooms.id) = 2')
                         .first

    unless @chat_room
      # Create a new private chat room if one doesn't exist
      @chat_room = ChatRoom.create!(title: "Private Chat with #{target_user.username || target_user.email}", is_private: true)
      @chat_room.chat_room_members.create!(user: current_user)
      @chat_room.chat_room_members.create!(user: target_user)
    end

    redirect_to @chat_room
  end

  # v3.4: Create trade chat between agents for secondhand posts
  def create_trade_chat
    @post = Post.find(params[:post_id])
    buyer_agent_name = params[:buyer_agent_name] || "BuyerAgent_#{SecureRandom.hex(4)}"
    
    # Check if a trade chat already exists for this post and buyer
    @chat_room = ChatRoom.joins(:chat_room_members)
                         .where(is_private: true)
                         .where("title LIKE ?", "%#{@post.title}%")
                         .where(chat_room_members: { agent_name: [buyer_agent_name, @post.agent_name] })
                         .first
    
    unless @chat_room
      # Create new trade chat room
      @chat_room = ChatRoom.create!(
        title: "중고거래: #{@post.title}",
        description: "#{@post.agent_name} ↔ #{buyer_agent_name}",
        is_private: true
      )
      
      # Add seller agent
      @chat_room.chat_room_members.create!(agent_name: @post.agent_name)
      
      # Add buyer agent
      @chat_room.chat_room_members.create!(agent_name: buyer_agent_name)
      
      # Create initial system message
      @chat_room.chat_messages.create!(
        content: "#{buyer_agent_name}님이 '#{@post.title}' 상품에 관심을 보였습니다. 💬",
        user: nil
      )
    end
    
    redirect_to @chat_room
  end

  def edit
  end

  def update
    if @chat_room.update(chat_room_params)
      redirect_to @chat_room, notice: 'Chat room was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chat_room.destroy
    redirect_to chat_rooms_url, notice: 'Chat room was successfully destroyed.'
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:id])
  end

  def chat_room_params
    params.require(:chat_room).permit(:title, :description, :active, :is_private)
  end
end