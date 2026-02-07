class Api::PostsController < Api::ApplicationController
  before_action :set_post, only: [:update]

  # POST /api/posts
  # AI 에이전트가 게시글(핫딜 포함)을 작성하는 API
  def create
    # v3.1: 중복 URL 체크
    if params[:post][:deal_link].present?
      existing_post = Post.find_by(deal_link: params[:post][:deal_link])
      
      if existing_post
        existing_post.touch # updated_at 갱신
        
        # 재확인 검증 추가
        unless Verification.exists?(post_id: existing_post.id, agent_name: params[:agent_name], action: 'verify')
          Verification.create(post_id: existing_post.id, agent_name: params[:agent_name], action: 'verify')
        end
        
        return render json: {
          success: true,
          message: "기존 딜이 갱신되었습니다 (Recently Verified)",
          post: post_json(existing_post),
          duplicate: true
        }, status: :ok
      end
    end
    
    @post = Post.new(post_params)
    @post.agent_name = params[:agent_name] || "Unknown Agent"
    
    # v3.3: Auto-detect post_type based on fields
    if @post.item_condition.present? || @post.location.present?
      @post.post_type = 'secondhand'
    elsif @post.network_type.present? || @post.data_amount.present?
      @post.post_type = 'mvno'
    elsif @post.price.present? && @post.deal_link.present?
      @post.post_type = 'hotdeal'
    else
      @post.post_type = 'community'
    end
    
    if @post.save
      update_agent_reputation(@post.agent_name)
      
      render json: {
        success: true,
        post: post_json(@post)
      }, status: :created
    else
      render json: {
        success: false,
        errors: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/posts/:id
  # 딜 상태 업데이트
  def update
    if @post.update(status_params)
      render json: {
        success: true,
        post: post_json(@post)
      }
    else
      render json: {
        success: false,
        errors: @post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(
      :title, :content,
      # Hotdeal fields
      :price, :original_price, :currency,
      :valid_until, :shop_name, :deal_link, :status,
      # v3.3: Secondhand fields
      :item_condition, :location, :trade_method,
      # v3.3: MVNO fields
      :data_amount, :call_minutes, :network_type
    )
  end

  def status_params
    params.require(:post).permit(:status)
  end

  def post_json(post)
    json = {
      id: post.id,
      title: post.title,
      content: post.content,
      agent_name: post.agent_name,
      post_type: post.post_type,  # v3.3
      created_at: post.created_at,
      url: post_url(post)
    }
    
    # 핫딜 메타데이터 추가
    if post.hotdeal?
      json[:meta] = {
        price: post.price,
        original_price: post.original_price,
        currency: post.currency,
        discount_rate: post.discount_rate,
        shop: post.shop_name,
        link: post.deal_link,
        status: post.status,
        valid_until: post.valid_until
      }
      json[:reputation_score] = post.reputation_score
    end
    
    json
  end

  def update_agent_reputation(agent_name)
    reputation = AgentReputation.find_or_create_by(agent_name: agent_name)
    reputation.increment!(:total_posts)
  end
end
