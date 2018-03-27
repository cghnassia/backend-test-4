Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post 'webhook' => 'webhook#default'
  post 'webhook/digit/:id' => 'webhook#digit'
  post 'webhook/hangup/:id' => 'webhook#hangup'

  get 'calls' => 'calls#index'
  get 'calls/:id' => 'calls#show'
end
