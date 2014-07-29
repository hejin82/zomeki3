CmsCMS::Application.routes.draw do
  mod = "portal"

  ## admin
  scope "#{CmsCMS::ADMIN_URL_PREFIX}/#{mod}", :module => mod, :as => mod do
    resources :feeds,
      :controller  => "admin/feeds",
      :path        => ":content/feeds"
    resources :feed_entries,
      :controller  => "admin/feed_entries",
      :path        => ":content/:feed/feed_entries"
    resources :categories,
      :controller  => "admin/categories",
      :path        => ":content/:parent/categories"

    ## content
    resources :content_base,
      :controller => "admin/content/base"
    resources :content_settings,
      :controller  => "admin/content/settings",
      :path        => ":content/content_settings"

    ## node
    resources :node_feed_entries,
      :controller  => "admin/node/feed_entries",
      :path        => ":parent/node_feed_entries"
    resources :node_event_entries,
      :controller  => "admin/node/event_entries",
      :path        => ":parent/node_event_entries"
    resources :node_categories,
      :controller  => "admin/node/categories",
      :path        => ":parent/node_categories"

    ## piece
    resources :piece_feed_entries,
      :controller  => "admin/piece/feed_entries"
    resources :piece_feed_entry_conditions,
      :controller  => "admin/piece/feed_entry/conditions",
      :path        => ":piece/piece_feed_entry_conditions"
    resources :piece_recent_tabs,
      :controller  => "admin/piece/recent_tabs"
    resources :piece_recent_tab_tabs,
      :controller  => "admin/piece/recent_tab/tabs",
      :path        => ":piece/piece_recent_tab_tabs"
    resources :piece_calendars,
      :controller  => "admin/piece/calendars"
    resources :piece_categories,
      :controller  => "admin/piece/categories"
  end

  ## public
  scope "_public/#{mod}", :module => mod, :as => "" do
    get "node_feed_entries/index.:format"               => "public/node/feed_entries#index"
    get "node_event_entries/:year/:month/index.:format" => "public/node/event_entries#month"
    get "node_event_entries/index.:format"              => "public/node/event_entries#month"
    get "node_categories/:name/:file.:format"           => "public/node/categories#show"
    get "node_categories/index.:format"                 => "public/node/categories#index"
  end
end
