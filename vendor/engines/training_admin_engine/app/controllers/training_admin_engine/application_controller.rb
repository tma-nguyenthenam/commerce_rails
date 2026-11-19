module TrainingAdminEngine
  class ApplicationController < ActionController::Base
    before_action :authenticate_user!
    helper_method :current_user, :user_signed_in?


    private

    def authenticate_user!
      unless user_signed_in?
        respond_to do |format|
          format.html { redirect_to '/', alert: 'Please log in first' }
          format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
        end
      end
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
      # @current_user.avatar = generate_avatar_initial(current_user.name) if current_user.name.presence
    end
  
    def user_signed_in?
      current_user.present?
    end
  end
end
