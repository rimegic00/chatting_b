module Api
  class ChatRoomsController < ApplicationController

    before_action :authenticate_agent!

    # POST /api/chat_rooms/trade
    # Params: post_id, buyer_agent_name (optional, defaults to current_agent)
    def create_trade
      post = Post.find(params[:post_id])
      
      buyer_name = current_agent_name
      seller_name = post.agent_name.presence || post.user&.username || "UnknownSeller"
      
      # 1. Check if chat room already exists
      chat_room = ChatRoom.joins(:chat_room_members)
                          .where(is_private: true)
                          .where("title LIKE ?", "%#{post.title}%")
                          .where(chat_room_members: { agent_name: buyer_name })
                          .first
                          
      if chat_room
        render json: { success: true, chat_room_id: chat_room.id, status: "existing" }
        return
      end
      
      # 2. Create new chat room
      ActiveRecord::Base.transaction do
        chat_room = ChatRoom.create!(
          title: "중고거래: #{post.title}",
          description: "#{seller_name} ↔ #{buyer_name}",
          is_private: true
        )
        
        # Add members
        chat_room.chat_room_members.create!(agent_name: seller_name)
        chat_room.chat_room_members.create!(agent_name: buyer_name)
        
        # Initial Message
        chat_room.chat_messages.create!(
          content: "#{buyer_name}님이 '#{post.title}' 상품에 관심을 보였습니다. 💬",
          agent_name: "System"
        )
        
        render json: { success: true, chat_room_id: chat_room.id, status: "created" }
      end
    rescue => e
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end

    # POST /api/chat_rooms/:id/messages
    # Params: content
    def send_message
      chat_room = ChatRoom.find(params[:id])
      
      # Check membership
      unless chat_room.chat_room_members.exists?(agent_name: current_agent_name)
        render json: { error: "Forbidden", message: "You are not a member of this chat room" }, status: :forbidden
        return
      end

      message = chat_room.chat_messages.build(
        content: params[:content],
        agent_name: current_agent_name
      )
      
      if message.save
        render json: { success: true, message_id: message.id }
      else
        render json: { success: false, error: message.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /api/chat_rooms/:id/messages
    # Params: after_id (optional)
    def index_messages
      chat_room = ChatRoom.find(params[:id])
      
      # Check membership
      unless chat_room.chat_room_members.exists?(agent_name: current_agent_name)
        render json: { error: "Forbidden", message: "You are not a member of this chat room" }, status: :forbidden
        return
      end
      
      messages = chat_room.chat_messages.includes(:user)
      
      if params[:after_id].present?
        messages = messages.where("id > ?", params[:after_id])
      end
      
      messages = messages.order(created_at: :asc).limit(50)
      
      data = messages.map do |m|
        {
          id: m.id,
          content: m.content,
          sender: m.agent_name || m.user&.username || "Unknown",
          is_mine: (m.agent_name == current_agent_name),
          created_at: m.created_at
        }
      end
      
      render json: { success: true, messages: data }
    end
  end
end
