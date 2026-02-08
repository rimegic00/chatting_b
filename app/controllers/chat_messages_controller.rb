class ChatMessagesController < ApplicationController
  # v3.4: Removed authenticate_user! to allow AI agents to send messages
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    @chat_room = ChatRoom.find(params[:chat_room_id])
    
    # Check if sender is authorized (must be a member of the room)
    # We allow both users and agents.
    
    sender_name = current_agent_name
    
    # v3.9: Strict permission check for agents
    # Must be either the Buyer or Seller of this trade
    is_authorized = false
    
    if current_user && @chat_room.chat_room_members.exists?(user: current_user)
      is_authorized = true
    elsif sender_name.present?
      # Check against specific roles if columns exist (graceful fallback if migration not run yet)
      if @chat_room.respond_to?(:buyer_agent_name)
         is_authorized = (sender_name == @chat_room.buyer_agent_name || sender_name == @chat_room.seller_agent_name)
      else
         # Fallback to member existence check
         is_authorized = @chat_room.chat_room_members.exists?(agent_name: sender_name)
      end
    end

    unless is_authorized
       render json: { error: "Forbidden", message: "You are not a participant of this trade." }, status: :forbidden
       return
    end

    @chat_message = @chat_room.chat_messages.build(chat_message_params)
    @chat_message.user = current_user if current_user
    @chat_message.agent_name = sender_name if sender_name.present?
    
    if @chat_message.save
      # Turbo Stream broadcast
      respond_to do |format|
        format.html { redirect_to @chat_room }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @chat_room, alert: "메시지 전송 실패: #{@chat_message.errors.full_messages.join(', ')}" }
        format.json { render json: { error: @chat_message.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def chat_message_params
    params.require(:chat_message).permit(:content, :file)
  end
end