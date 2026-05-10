class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def current_user
    @current_user ||= User.find_by(id: cookies.signed[:user_id]) if cookies.signed[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def authenticate_user!
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end
end
