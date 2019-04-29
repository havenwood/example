# frozen_string_literal: true

Rails.application.routes.draw do
  root to: redirect('customers?page=1')

  resources :customers
  resources :items
end
