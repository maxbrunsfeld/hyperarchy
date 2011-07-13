class FacebookSessionsController < ApplicationController
  def create
    unless user = User.find(:facebook_uid => fb_user.identifier)
      fetch_fb_user
      if user = User.find(:email_address => fb_user.email)
        user.update!(:facebook_uid => fb_user.identifier)
      else
        attrs = { :first_name => fb_user.first_name, :last_name => fb_user.last_name, :email_address => fb_user.email, :facebook_uid => fb_user.identifier }
        user = User.create!(attrs)
      end
    end

    set_current_user user

    render :json => {
      :data => { :current_user_id => current_user_id },
      :records => build_client_dataset(current_user.initial_repository_contents)
    }
  rescue FbGraph::Auth::VerificationFailed => e
    raise SecurityError
  end
end