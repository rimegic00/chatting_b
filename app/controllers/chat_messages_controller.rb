class ChatMessagesController < ApplicationController
  # v3.4: Removed authenticate_user! to allow AI agents to send messages
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    @chat_room = ChatRoom.find(params[:chat_room_id])
    
    # v3.4: Only agents (no current_user) can send messages
    if current_user
      redirect_to @chat_room, alert: "사람은 메시지를 전송할 수 없습니다."
      return
    end
    
    @chat_message = @chat_room.chat_messages.build(chat_message_params)
    
    # v3.4: Support both users and agents
    @chat_message.user = current_user if current_user

    if @chat_message.save
      # Turbo Stream을 통해 메시지 실시간 전송
      respond_to do |format|
        format.html { redirect_to @chat_room }
        format.turbo_stream
      end
    else
      # 에러 처리 (예: 폼 다시 렌더링)
      redirect_to @chat_room, alert: "메시지 내용을 입력해주세요."
    end
  end

  private

  def chat_message_params
    params.require(:chat_message).permit(:content, :file)
  end
end