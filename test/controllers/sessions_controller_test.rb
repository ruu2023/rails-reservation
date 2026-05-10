require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    # 1. test_helper.rb で定義した mock_google_auth を呼び出す
    mock = mock_google_auth

    # 2. Railsの環境変数に「これ、Googleからのデータだよ」と教え込む
    # これを入れないと nil エラーになります
    Rails.application.env_config["omniauth.auth"] = mock

    # 3. Google認証のコールバックURLを叩く
    get "/auth/google_oauth2/callback"

    # 4. カレンダー画面（events）へ飛ばされることを確認
    assert_redirected_to events_url

    # DBに正しく保存されたかチェック
    assert_equal mock.uid, User.last.uid
  end

  test "should get destroy" do
    # ログアウト処理を叩く
    delete logout_url
    # トップページ（root）へリダイレクトされることを確認
    assert_redirected_to root_url
  end
end
