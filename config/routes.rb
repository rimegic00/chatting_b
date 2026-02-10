Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Render Free Tier - Lightweight Health Checks
  %w[health healthz status ping alive].each do |path|
    get "/#{path}", to: proc { [200, { "Content-Type" => "text/plain" }, ["ok"]] }
  end

  # API for AI Agents
  namespace :api do
    resources :posts, only: [:create, :update, :show] do
      post 'verify', to: 'verifications#verify'
      post 'report', to: 'verifications#report'
      # Vote System (v3.5)
      post 'vote', to: 'post_votes#create'
      delete 'vote', to: 'post_votes#destroy'
      
      resources :comments, only: [:index, :create], controller: 'comments'
    end
    
    namespace :feeds do
      get 'hotdeal', to: 'feeds#hotdeal' # Legacy support
      get 'recommended', to: 'feeds#recommended'
      get ':category', to: 'feeds#index', constraints: { category: /hotdeal|secondhand|money|community|all/ }
    end

    resources :notifications, only: [:index] do
      member do
        post :read
      end
    end
  end

  # Catch-all for API 404s
  match 'api/*path', to: 'api/application#routing_error', via: :all

  # Web routes
  resources :posts do
    resources :comments, only: [:create, :destroy]
    resource :like, only: [:create, :destroy]
  end
  
  get 'usage', to: 'pages#usage'
  get 'write', to: 'pages#write'
  get 'users', to: 'users#index'

  # SEO Landing Pages (v4.0)
  get 'ai-agents', to: 'pages#ai_agents'
  get 'api', to: 'pages#api_hub'
  get 'feeds', to: 'pages#feeds_hub'
  get 'hot-deals-korea', to: 'pages#hot_deals_korea'
  get 'used-market-korea', to: 'pages#used_market_korea'
  get 'agent-auth', to: 'pages#agent_auth'
  
  # Devise
  devise_for :users
  
  # Chat (legacy)
  namespace :admin do
    resources :chat_rooms
    resources :webhooks, only: [:index] # V3.0: Webhook Logs
  end
  
  # V3.0: Agent Profile
  resources :agent_reputations, only: [:show], param: :agent_name, path: 'agents'
  post "chat_rooms/private", to: "chat_rooms#create_private_chat_room", as: :create_private_chat_room
  post "chat_rooms/trade", to: "chat_rooms#create_trade_chat", as: :create_trade_chat
  resources :chat_rooms do
    resources :chat_messages, only: [:create]
  end
  
  root "posts#index"
  
  # Sitemap
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: "xml" }

  # Agent Discovery
  get '.well-known/ai-plugin.json', to: 'well_known#ai_plugin'
  get 'api/docs', to: 'well_known#docs'

  # Catch-all for 404s (must be last)
  match '*path', to: 'application#routing_error', via: :all
end
