Rails.application.routes.draw do
  root to: "home#index"
  get "/edit", to: "home#edit"
  post "/edit", to: "home#update"
  post "/create", to: "home#create"
  delete "/home", to: "home#delete"
  get "home/new", to: "home#new"

  post "/shipping", to: "shipping#create"

  mount ShopifyApp::Engine, at: "/"
end
