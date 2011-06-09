class ApplicationController < ActionController::Base
  include GuidGeneration
  include HttpClient

  layout false
  protect_from_forgery unless Rails.env.jasmine?
  helper_method :current_user, :current_user_id, :build_client_dataset, :make_guid
  before_filter :no_internet_explorer
  around_filter :manage_session

  protected

  rescue_from SecurityError do
    render :status => :forbidden, :text => "That's not allowed"
  end

  def manage_session
    Prequel.session.current_user = current_user if current_user
    yield
  ensure
    Prequel.clear_session
  end

  def set_current_user(user)
    session[:current_user_id] = user.id
    Prequel.session.current_user = user
  end

  def clear_current_user
    session[:current_user_id] = nil
    Prequel.session.current_user = nil
  end

  def current_user_id
    session[:current_user_id] || User.default_guest.id
  end

  def current_user
    User.find(current_user_id) || begin
      clear_current_user
      User.default_guest
    end
  end

  def require_authentication
    if current_user && !current_user.guest?
      true
    else
      raise SecurityError if request.xhr?
      clear_current_user
      session[:after_login_path] = request.path_info
      redirect_to login_url
      false
    end
  end

  def render_success_json(data=nil, dataset=[])
    render :json => {
      :successful => true,
      :data => data,
      :dataset => build_client_dataset(*dataset)
    }
  end

  def render_failure_json(data)
    render :json => {
      :successful => false,
      :data => data,
    }
  end

  def build_client_dataset(*records_or_relations)
    (Hash.new {|h,k| h[k] = {}}).tap do |dataset|
      Array(records_or_relations).flatten.each do |r|
        r.add_to_client_dataset(dataset)
      end
    end
  end

  def no_internet_explorer
    if user_agent =~ /MSIE/ && user_agent !~ /chromeframe/
      render :template => '/home/no_internet_explorer'
      false
    else
      true
    end
  end

  def user_agent
    request.env["HTTP_USER_AGENT"]
  end
end
