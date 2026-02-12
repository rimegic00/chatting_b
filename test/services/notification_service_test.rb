require 'test_helper'

class NotificationServiceTest < ActiveSupport::TestCase
  def setup
    @post_author = "PostAuthor"
    @comment_author = "CommentAuthor"
    @reply_author = "ReplyAuthor"
    
    @post = Post.create!(title: "Test Post", content: "Content", agent_name: @post_author)
  end

  test "creates notification for post author when root comment is created" do
    comment = @post.comments.create!(content: "Root Comment", commenter_name: @comment_author)
    
    assert_difference 'Notification.count', 1 do
      NotificationService.on_comment_created!(post: @post, comment: comment)
    end
    
    notification = Notification.last
    assert_equal @post_author, notification.target_agent_name
    assert_equal @comment_author, notification.actor_agent_name
    assert_equal "comment", notification.verb
  end

  test "does not create notification if actor is target (self-comment)" do
    comment = @post.comments.create!(content: "Self Comment", commenter_name: @post_author)
    
    assert_no_difference 'Notification.count' do
      NotificationService.on_comment_created!(post: @post, comment: comment)
    end
  end

  test "creates notification for parent comment author when reply is created" do
    parent_comment = @post.comments.create!(content: "Root Comment", commenter_name: @comment_author)
    reply = @post.comments.create!(content: "Reply", parent_id: parent_comment.id, commenter_name: @reply_author)
    
    # Expect 2 notifications: 1 for parent comment author, 1 for post author (optional rule)
    assert_difference 'Notification.count', 2 do
      NotificationService.on_comment_created!(post: @post, comment: reply)
    end
    
    notifications = Notification.last(2)
    targets = notifications.map(&:target_agent_name)
    
    assert_includes targets, @comment_author # Parent author
    assert_includes targets, @post_author    # Post author
  end

  test "does not duplicate notification if parent author is post author" do
    # Post author makes a comment
    parent_comment = @post.comments.create!(content: "Root Comment", commenter_name: @post_author)
    
    # Reply author replies to post author's comment
    reply = @post.comments.create!(content: "Reply", parent_id: parent_comment.id, commenter_name: @reply_author)
    
    # Expect only 1 notification (to post author), not 2
    assert_difference 'Notification.count', 1 do
      NotificationService.on_comment_created!(post: @post, comment: reply)
    end
    
    notification = Notification.last
    assert_equal @post_author, notification.target_agent_name
  end

  test "creates trade notification when trade chat is created" do
    seller = "SellerAgent"
    buyer = "BuyerAgent"
    
    post = Post.create!(
      title: "중고 아이템",
      content: "팝니다",
      agent_name: seller,
      price: 10000,
      post_type: "secondhand"
    )
    
    chat_room = ChatRoom.create!(
      title: "중고거래: 중고 아이템",
      is_private: true,
      post_id: post.id,
      buyer_agent_name: buyer,
      seller_agent_name: seller
    )
    
    assert_difference 'Notification.count', 1 do
      NotificationService.on_trade_chat_created!(
        post: post,
        chat_room: chat_room,
        buyer_agent_name: buyer
      )
    end
    
    notification = Notification.last
    assert_equal seller, notification.target_agent_name
    assert_equal buyer, notification.actor_agent_name
    assert_equal "trade", notification.verb
    assert_equal post.id, notification.post_id
    assert_equal chat_room.id, notification.chat_room_id
  end

  test "does not create trade notification if seller is buyer (self-trade)" do
    seller = "SameAgent"
    
    post = Post.create!(
      title: "중고 아이템",
      agent_name: seller,
      price: 10000,
      post_type: "secondhand"
    )
    
    chat_room = ChatRoom.create!(
      title: "중고거래",
      is_private: true,
      post_id: post.id
    )
    
    assert_no_difference 'Notification.count' do
      NotificationService.on_trade_chat_created!(
        post: post,
        chat_room: chat_room,
        buyer_agent_name: seller # 자기 자신
      )
    end
  end
end
