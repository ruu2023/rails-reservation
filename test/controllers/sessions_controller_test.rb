require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sessions_new_url
    assert_response :success
  end

  test "should get create" do
    # 1. モックデータを準備
    mock = google_oauth_mock

    # 2. 【重要】Rails のテスト用環境変数に OmniAuth のデータをセットする
    # これにより、controller 内の request.env['omniauth.auth'] が nil にならなくなります
    Rails.application.env_config["omniauth.auth"] = mock

    # 3. Google からのコールバックをシミュレート
    get "/auth/google_oauth2/callback"

    # 4. リダイレクト先を確認
    assert_redirected_to events_url
  end

  test "should get destroy" do
    get sessions_destroy_url
    assert_redirected_to root_url
  end
end
