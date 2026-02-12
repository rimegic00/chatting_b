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
  # v3.8: Updated to support User-to-Agent and User-to-User trade chats
  def create_trade_chat
    @post = Post.find(params[:post_id])
    
    # Determined Buyer (User or Agent)
    if user_signed_in?
      buyer_user = current_user
      buyer_agent_name = current_user.username.presence || current_user.email.split('@').first
    else
      buyer_user = nil
      # v3.9: Support explicit agent_name param for establishing session
      if params[:agent_name].present?
        session[:agent_name] = params[:agent_name]
      end

      # v3.9.1: If buyer_agent_name is missing, use current_agent_name. 
      # If still missing (cold start), we MUST assign a guest name or use params.
      buyer_agent_name = current_agent_name || params[:buyer_agent_name] || params[:agent_name] || "Guest_#{SecureRandom.hex(4)}"
      
      # Persist to session for Web UI continuity
      session[:agent_name] = buyer_agent_name unless current_agent_name
    end

    # Determined Seller (User or Agent)
    seller_user = @post.user
    seller_agent_name = @post.agent_name.presence || (@post.user&.username || "UnknownSeller")
    
    # v3.9.1: Robust linking using post_id
    # We first try to find an existing room for this specific post and buyer.
    # Note: We rely on the migration adding post_id to chat_rooms.
    query = ChatRoom.where(post_id: @post.id).where(is_private: true)
    
    if buyer_user
      # If buyer is a user, strictly match the user
      query = query.joins(:chat_room_members).where(chat_room_members: { user_id: buyer_user.id })
    else
       # If buyer is an agent, strictly match the buyer_agent_name
       # Note: This means if a Guest session expires and they get a new Guest Name, they lose access.
       # Ideally for guests we might want to be looser, but for "Agents" strict is better.
       query = query.where(buyer_agent_name: buyer_agent_name)
    end
    
    @chat_room = query.first
    
    unless @chat_room
      # Create new trade chat room
      @chat_room = ChatRoom.create!(
        title: "중고거래: #{@post.title}",
        description: "#{seller_agent_name} ↔ #{buyer_agent_name}",
        is_private: true,
        buyer_agent_name: buyer_agent_name,
        seller_agent_name: seller_agent_name,
        post_id: @post.id
      )
      
      # Add seller agent/user
      if seller_user
         @chat_room.chat_room_members.create!(user: seller_user, agent_name: seller_agent_name)
      else
         @chat_room.chat_room_members.create!(agent_name: seller_agent_name)
      end
      
      # Add buyer agent/user
      if buyer_user
        @chat_room.chat_room_members.create!(user: buyer_user, agent_name: buyer_agent_name)
      else
        @chat_room.chat_room_members.create!(agent_name: buyer_agent_name)
      end
      
      # Create initial system message
      @chat_room.chat_messages.create!(
        content: "#{buyer_agent_name}님이 '#{@post.title}' 상품에 관심을 보였습니다. 💬",
        user: nil,
        agent_name: "System"
      )
      
      # 판매자에게 알림 생성
      NotificationService.on_trade_chat_created!(
        post: @post,
        chat_room: @chat_room,
        buyer_agent_name: buyer_agent_name
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