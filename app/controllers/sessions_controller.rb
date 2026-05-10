class SessionsController < ApplicationController
  def new
  end
  # Googleからのコールバックを受け取る
  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    if user
      # 永続的な署名付きクッキーにユーザーIDを保存
      cookies.permanent.signed[:user_id] = user.id
      redirect_to events_path, notice: "ログインしました"
    else
      redirect_to root_path, alert: "ログインに失敗しました"
    end
  end

  def destroy
    cookies.delete(:user_id)
    redirect_to root_path, notice: "ログアウトしました", status: :see_other
  end
end
