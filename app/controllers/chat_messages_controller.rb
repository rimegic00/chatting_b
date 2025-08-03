class ChatMessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat_room = ChatRoom.find(params[:chat_room_id])
    @chat_message = @chat_room.chat_messages.build(chat_message_params)
    @chat_message.user = current_user

    if @chat_message.save
      # Turbo Stream을 통해 메시지 실시간 전송
      respond_to do |format|
        format.html { redirect_to @chat_room }
        format.turbo_stream
      end
    else
      # 에러 처리 (예: 폼 다시 렌더링)
      redirect_to @chat_room, alert: "메시지 전송에 실패했습니다."
    end
  end

  private

  def chat_message_params
    params.require(:chat_message).permit(:content, :file)
  end
end