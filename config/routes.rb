Rails.application.routes.draw do
  resources :participants
  resources :assistants
  resources :deals do
    collection do
      post :fabricate
    end
    member do
      get :pick_status_of
    end
  end
  root :to => 'home#landing'
  devise_for :agents
  resources :agents, :only => [:edit, :update]
end
