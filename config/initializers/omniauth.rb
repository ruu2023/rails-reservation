Rails.application.config.middleware.use OmniAuth::Builder do
  # credentials.google が存在するときだけ読み込み、なければ nil を渡す
  google_creds = Rails.application.credentials.google

  if google_creds
    provider :google_oauth2,
             google_creds[:client_id],
             google_creds[:client_secret]
  else
    # テスト環境などでキーがない場合に、アプリ自体が落ちるのを防ぐ
    puts "Warning: Google OAuth credentials not found. OAuth will not work."
  end
end
