class User < ApplicationRecord
  has_many :chat_messages
  has_many :chat_room_members
  has_many :chat_rooms, through: :chat_room_members

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
