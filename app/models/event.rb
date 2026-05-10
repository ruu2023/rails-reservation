class Event < ApplicationRecord
  belongs_to :user
  # 1. タイトルは必須（空だと「紙」に書き込めない）
  validates :title, presence: true, length: { maximum: 50 }

  # 2. 開始時間は必須
  validates :start_time, presence: true

  # 3. 独自のバリデーション（例：過去の日付で予約できないようにする）
  validate :start_time_cannot_be_in_the_past, on: :create

  private

  def start_time_cannot_be_in_the_past
    if start_time.present? && start_time < Time.zone.now
      errors.add(:start_time, "は現在より後の時間を選択してください")
    end
  end
end
