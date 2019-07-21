Rails.application.routes.draw do
  patch 'projects/:id', to: 'projects#create'
  resources :projects, only: [:new, :create, :destroy, :show, :update] do
    collection do
      get 'create_demoaccount'  #for test
      get 'destroy_demoaccount'
      get 'admin/list', to: 'projects#index'
    end
  end
  root to: "projects#new"
  # resources :projects, only: [:new] do
  #   resources :admin, only: [:index]
  # end
end
