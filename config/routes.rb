Rails.application.routes.draw do
  root 'tokens#index'
  resources :tokens
end
