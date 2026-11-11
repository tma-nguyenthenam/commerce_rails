class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    # Find or create user based on provider and uid
    user = User.find_or_create_by!(provider: auth["provider"], uid: auth["uid"]) do |u|
      u.email = auth.dig("info", "email")
      u.name = auth.dig("info", "name")
    end
    reset_session          # Prevent session fixation attacks
    session[:user_id] = user.id
    redirect_to root_path
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end
end
