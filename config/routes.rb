Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    resources :users, only: %i[create]
    resources :sessions, only: %i[create destroy]
  end
  # NOTE: JSONを返すだけの場合などは、慣習的にAPIというnamespaceを切ってそのフォルダ以下作成することが多い。
end
