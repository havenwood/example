Rails.application.routes.draw do
  root 'customer#list'
  get 'customer/list'
end
