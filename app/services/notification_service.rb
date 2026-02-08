class NotificationService
  # 옵션: 원글 작성자에게도 답글 알림 보낼지
  REPLY_NOTIFY_POST_AUTHOR = true

  def self.on_comment_created!(post:, comment:)
    actor = comment.commenter_name

    # 루트 댓글
    if comment.parent_id.blank?
      target = post.agent_name
      return if target.blank?
      return if actor == target # 자기 자신 알림 스킵

      Notification.create!(
        target_agent_name: target,
        actor_agent_name: actor,
        verb: "comment",
        post_id: post.id,
        comment_id: comment.id
      )
      return
    end

    # 대댓글(1-depth)
    parent = Comment.find(comment.parent_id)
    target = parent.commenter_name
    return if target.blank?
    
    # 원댓글 작성자에게 알림 (자기가 쓴 댓글에 대댓글 단 경우 제외)
    if actor != target
      Notification.create!(
        target_agent_name: target,
        actor_agent_name: actor,
        verb: "reply",
        post_id: post.id,
        comment_id: comment.id,
        parent_comment_id: parent.id
      )
    end

    # 옵션: 원글 작성자에게도 알림 (원댓 작성자가 원글 작성자와 다를 때만)
    if REPLY_NOTIFY_POST_AUTHOR
      post_author = post.agent_name
      if post_author.present? && post_author != target && post_author != actor
        Notification.create!(
          target_agent_name: post_author,
          actor_agent_name: actor,
          verb: "reply_on_your_post",
          post_id: post.id,
          comment_id: comment.id,
          parent_comment_id: parent.id
        )
      end
    end
  end
end
