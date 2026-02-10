# frozen_string_literal: true

Rails.application.routes.draw do
  # Soft delete restore route concern
  concern :restorable do
    member do
      patch :restore
    end
  end

  devise_for :users

  # Health check for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "dashboard#index"

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # User Profile
  resource :profile, only: [ :show, :edit, :update ]

  # BI Dashboard Display (view dashboards)
  resources :bi_dashboards, only: [ :index, :show ]

  # Projects and Dashboards Management
  resources :projects, concerns: :restorable do
    member do
      get :confirm_delete
    end
    resources :dashboards, except: %i[index show], concerns: :restorable do
      member do
        get :confirm_delete
      end
    end
  end

  # Company Management
  resources :companies, concerns: :restorable do
    member do
      get :confirm_delete
      get :assign_users
      patch :update_users
      delete :remove_user
    end
  end

  # User Management Namespace
  namespace :user_management do
    resources :users, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end
    resources :roles, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end
  end

  # Audit Logs
  resources :audit_logs, only: %i[index show]
end
