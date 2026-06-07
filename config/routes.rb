Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "tournament#standings"

  resources :teams, except: :show
  resources :groups
  resources :group_matches, except: :show
  resources :knockout_matches, only: %i[index edit update]

  resource :tournament, only: [] do
    get :standings
    get :qualified
    get :champion
    post :generate_bracket
  end
end
