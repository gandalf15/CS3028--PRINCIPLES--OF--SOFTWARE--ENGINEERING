Rails.application.routes.draw do

  get 'documents/new'

  get 'documents/index'

  get 'documents/show'

  get 'documents/edit'

  # Home page routes
  root 'home#index'
  get '/about', to: 'home#about'
  get '/contact', to: 'home#contact'

  # Documents routes
  get 'doc', to: "documents#index"
  get 'doc/new', to: "documents#new" # Must be accessible only from Admin
  get 'doc/edit', to: "documents#edit" # Must be accessible only from Admin
  get 'doc/(:id)', to: "documents#show"

  # Download routes
  get 'downloads/zipped'
  get 'downloads/img'
  get 'downloads/tr', to: 'donwloads#trancr'

  # Admin routes
  devise_scope :user do
    get "/admin" => "devise/sessions#new"
  end


  # resources :documents
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
