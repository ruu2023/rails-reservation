require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sessions_new_url
    assert_response :success
  end

  test "should get create" do
    # 偽のGoogleレスポンスをセット
    mock_google_auth

    # Googleからのコールバックをシミュレート
    get "/auth/google_oauth2/callback"
    assert_redirected_to events_url
  end

  test "should get destroy" do
    get sessions_destroy_url
    assert_redirected_to root_url
  end
end
