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
    # 【追加】開発環境で、かつログインしていないなら、自動でログインさせる
    if Rails.env.development? && !logged_in?
      auto_login_for_dev
    end

    # ログインしていなければ（開発環境以外、または自動ログイン失敗時）リダイレクト
    unless logged_in?
      redirect_to root_path, alert: "ログインが必要です"
    end
  end

  # 【追加】開発環境用の自動ログイン処理
  def auto_login_for_dev
    user = User.find_or_create_by!(email: "dev@example.com") do |u|
      u.name = "Auto Dev User"
      u.provider = "developer"
      u.uid = "dev-12345"
    end

    # 今のコードがクッキー（cookies.signed）を使っているので、それに合わせる
    cookies.signed[:user_id] = user.id
    @current_user = user
    logger.info "🔧 [Dev Mode] 自動ログインしました: #{user.email}"
  end
end
