Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/workouts', to: 'workouts#index'
  get '/workouts/:id', to: 'workouts#show'
  post '/workouts', to: 'workouts#create'
  delete '/workouts/:id', to: 'workouts#delete'
  put '/workouts/:id', to: 'workouts#update'
end
