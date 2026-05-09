# 既存のデータを削除（任意）
Event.destroy_all

# まとめて作成
Event.create!([
  { title: "Rails勉強会", start_time: Time.current, content: "Ruby on Rails 8について" },
  { title: "買い物", start_time: 1.day.from_now, content: "西友で夕食の買い出し" },
  { title: "旅行", start_time: 3.days.from_now, end_time: 5.days.from_now, content: "温泉旅行" }
])

puts "テストデータの作成が完了しました！"
