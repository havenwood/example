Rails.application.routes.draw do
  root to: redirect('customers?page=1')

  resources :customers, only: %i[show index]
end
