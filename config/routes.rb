class CheckPath
  def self.set_pattern
    langs = Language.all.map{|e|e.locale} rescue []
    prefix = Rails.env == 'production' ? 'simulator' : ''
    /#{prefix}\/(#{langs.join('|')})(\/|)/
  end

  def self.matches?(request)
    @@pattern ||= self.set_pattern
    request.path !~ @@pattern
  end
end

class CheckNotLoggedIn
  def self.matches?(request)
    request.env['warden'].unauthenticated? :user
  end
end

Simulator::Application.routes.draw do |map|
  get "groups/index"
  get "groups/create"

  langs = Language.all.map{|e|e.locale} rescue []
  pattern = langs.join('|')

  match '/' => "redirector#to_login"

  # Redirect to /<locale>/users/login if only /<locale> was supplied and user is not logged in
  constraints(CheckNotLoggedIn) do
    langs.each {|l|
      match "/#{l}" => "redirector#to_login"
    }
  end

  # Redirect to English when no locale is specified
  constraints(CheckPath) do
    match '*path' => "redirector#to_locale"
  end

  scope '/(:locale)', :constraints => {:locale => /#{pattern}/}, :defaults => {:format => 'html'} do
    match 'ckeditor/images', :to => 'ckeditor#images'
    match 'ckeditor/files',  :to => 'ckeditor#files'
    match 'ckeditor/create/:kind', :to => 'ckeditor#create'

    root :to => 'home#index'
    match 'dashboard', :to => 'home#dashboard', :as => 'dashboard'

    devise_for :users,
      :path_names => {:sign_in => 'login', :sign_out => 'logout', :sign_up => 'register'},
      :controllers => {:registrations => "users/registrations", :confirmations => "users/confirmations"}
    match "users/confirmation/awaiting/:id/:confirmation_hash",
      :to => redirect("/simulator/%{locale}/users/confirmations/awaiting/%{id}/%{confirmation_hash}"), :as => "awaiting_confirmation"

    match 'login_help', :to => 'home#login_help', :as => 'login_help'
    
    resources :questionnaire_answers
    resources :profiles

    scope :module => "admin" do
      resources :reports
      resources :user_lists do
        post 'filtered(.:format)', :to => :index, :as=> 'filtered', :on => :collection
      end
      resources :users_groups
      resources :roles do
        get :autocomplete_user_email, :on => :collection
      end
      resources :basic_reports
      resources :attendance_reports

      resources :questionnaires do
        put :approve, :on => :member
        put :draft, :on => :member
      end

      get  'admin_tasks/admin_panel', :to => 'admin_tasks#index', :as => 'admin_panel'
      get  'admin_tasks/autocomplete_user_email', :to => 'admin_tasks#autocomplete_user_email', :as => 'autocomplete_user_email_admin_tasks'
      get  'admin_tasks/remove_user', :to => 'admin_tasks#remove_user', :as => 'remove_user'
      delete 'admin_tasks/remove_user_action', :to => 'admin_tasks#remove_user_action', :as => 'remove_user_action'
    end

    constraints(CheckNotLoggedIn) do
      match '*path', :to => 'redirector#to_login'
    end
    
    # When no route found - redirect to English Home-page
    match '*path', :to => 'redirector#to_dashboard'
  end

end
