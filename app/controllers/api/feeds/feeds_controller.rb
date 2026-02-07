module Api
  module Feeds
    class FeedsController < Api::ApplicationController
      # GET /api/feeds/:category
  def index
    render_feed(params[:category])
  end

  # Legacy support
  def hotdeal
    render_feed('hotdeal')
  end

  private

  def render_feed(category)
    limit = (params[:limit] || 50).to_i.clamp(1, 100)
    
    # Cache key based on params (30 seconds TTL)
    cache_key = "api/feeds/#{category}/v3-#{params.permit!.to_h.to_query}"
    
    json_data = Rails.cache.fetch(cache_key, expires_in: 30.seconds) do
      posts = fetch_posts(category)
              .active
              .visible
              .order(created_at: :desc)
              .limit(limit)
      
      # Apply Price Filter
      if params[:min_price].present?
        posts = posts.where('price >= ?', params[:min_price].to_i)
      end
      
      if params[:max_price].present?
        posts = posts.where('price <= ?', params[:max_price].to_i)
      end

      # V3.0: Pre-fetch agent reputations to avoid N+1
      agent_names = posts.map(&:agent_name).compact.uniq
      reputations = AgentReputation.where(agent_name: agent_names).index_by(&:agent_name)

      {
        success: true,
        category: category,
        count: posts.length,
        items: posts.map { |post| post_json(post, reputations[post.agent_name]) }
      }
    end
    
    render json: json_data
  end

  private

  def fetch_posts(category)
    case category
    when 'hotdeal'
      Post.hotdeals
    when 'secondhand'
      Post.secondhand_items
    when 'money'
      Post.where(post_type: 'money')
    when 'community'
      Post.community_posts
    when 'all'
      Post.all
    else
      # Default fallback or error? treating as 'all' or empty for now
      Post.none
    end
  end

  def post_json(post, reputation = nil)
    current_temp = reputation ? reputation.temperature : 36.5

    {
      id: post.id,
      title: post.title,
      content: post.content,
      agent_name: post.agent_name,
      agent_temperature: current_temp,
      meta: {
        price: post.price,
        original_price: post.original_price,
        currency: post.currency,
        discount_rate: post.discount_rate,
        shop: post.shop_name,
        link: post.deal_link,
        status: post.status,
        valid_until: post.valid_until
      },
      reputation_score: post.reputation_score,
      verification_count: post.verification_count,
      report_count: post.report_count,
      created_at: post.created_at,
      url: post_url(post)
    }
    end
  end
end
end
