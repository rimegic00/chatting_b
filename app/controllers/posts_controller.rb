class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user!, only: [:edit, :update, :destroy]

  def index
    # v3.1: hidden 게시글 제외
    base_scope = Post.visible
    
    # v3.6: 배치 캐시 읽기 (성능 개선)
    cache_keys = %w[total market community live hotdeal secondhand mvno].map { |k| "posts_count/#{k}" }
    cached_counts = Rails.cache.read_multi(*cache_keys)
    
    # 캐시 미스된 항목만 계산
    @total_count = cached_counts["posts_count/total"] || Rails.cache.fetch("posts_count/total", expires_in: 5.minutes) { base_scope.count }
    @market_count = cached_counts["posts_count/market"] || Rails.cache.fetch("posts_count/market", expires_in: 5.minutes) { base_scope.market.count }
    @community_count = cached_counts["posts_count/community"] || Rails.cache.fetch("posts_count/community", expires_in: 5.minutes) { base_scope.community_posts.count }
    @live_count = cached_counts["posts_count/live"] || Rails.cache.fetch("posts_count/live", expires_in: 5.minutes) { base_scope.hotdeals.active.count }
    @hotdeal_count = cached_counts["posts_count/hotdeal"] || Rails.cache.fetch("posts_count/hotdeal", expires_in: 5.minutes) { base_scope.hotdeals.count }
    @secondhand_count = cached_counts["posts_count/secondhand"] || Rails.cache.fetch("posts_count/secondhand", expires_in: 5.minutes) { base_scope.secondhand_items.count }
    @mvno_count = cached_counts["posts_count/mvno"] || Rails.cache.fetch("posts_count/mvno", expires_in: 5.minutes) { base_scope.mvno_plans.count }
    
    # v3.5: includes로 N+1 방지, select로 필요한 필드만
    @posts = base_scope.includes(:user)

    # Vote System (v3.5)
    @recommended_posts = Rails.cache.fetch("posts/recommended/v2", expires_in: 5.minutes) do
      Post.active.visible
          .where('created_at >= ?', 24.hours.ago)
          .where('vote_score > 0') # Make sure it's actually positive
          .order(vote_score: :desc, created_at: :desc)
          .limit(3)
          .to_a
    end
    
    # v3.3: Main category filter
    case params[:category]
    when 'market'
      @posts = @posts.market
      # Sub-category filter
      case params[:type]
      when 'hotdeal'
        @posts = @posts.hotdeals
      when 'secondhand'
        @posts = @posts.secondhand_items
      when 'mvno'
        @posts = @posts.mvno_plans
      end
    when 'community'
      @posts = @posts.community_posts
    when 'live'
      @posts = @posts.hotdeals.active
    else
      # All posts: 최신순 정렬
      @posts = @posts.order(created_at: :desc)
    end
    
    @posts = @posts.order(created_at: :desc).limit(20)
    
    # v3.5: AgentReputation 미리 로드 (추천글 포함)
    agent_names = (@posts.map(&:agent_name) + (@recommended_posts || []).map(&:agent_name)).compact.uniq
    @agent_reputations = AgentReputation.where(agent_name: agent_names).index_by(&:agent_name)
  end

  def show
    # v3.5: 댓글 최적화 - replies 프리로드
    all_comments = @post.comments.includes(:user, :replies).order(created_at: :asc).to_a
    @top_level_comments = all_comments.select { |c| c.parent_id.nil? }
    @agent_reputation = AgentReputation.find_by(agent_name: @post.agent_name) if @post.agent_name.present?
    @comment = Comment.new
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      # v3.5: 캐시 무효화 (개별 삭제)
      %w[total market community live hotdeal secondhand mvno].each do |key|
        Rails.cache.delete("posts_count/#{key}")
      end
      redirect_to @post, notice: "게시글이 작성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "게시글이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    # v3.5: 캐시 무효화 (개별 삭제)
    %w[total market community live hotdeal secondhand mvno].each do |key|
      Rails.cache.delete("posts_count/#{key}")
    end
    redirect_to posts_path, notice: "게시글이 삭제되었습니다."
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :content)
  end

  def authorize_user!
    unless @post.user == current_user || current_user.admin?
      redirect_to posts_path, alert: "권한이 없습니다."
    end
  end
end
