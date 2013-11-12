RailsMastercoin::Application.routes.draw do
  get "charts/weekly"
  get "charts/yearly"
  get "charts/monthly"
  resources :homes

  resources :transactions
  resources :searches

  namespace "mastercoin_verify", defaults: {format: 'json'} do
    resources :addresses
    resources :transactions
  end

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :addresses do
        member do
          get :unspent
        end
      end

      resources :selling_offers do 
        collection do
          get :current
        end
      end
      resources :purchase_offers

      resources :transactions do
        collection do
          get :exodus
          get :simple_send
          get :invalid
        end
      end
    end
  end

  namespace :raw do
    resources :transactions
  end

  resources :advisors do 
    collection do 
      post :sell
    end
  end

  resources :selling_offers
  resources :purchase_offers
  resources :order_books
  resources :advisors
  resources :addresses

  get "help" => "homes#help"

  get "api_docs" => "homes#api_docs"

  root to: "homes#index"

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
