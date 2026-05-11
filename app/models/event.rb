class Event < ApplicationRecord
  belongs_to :user
  # 1. タイトルは必須（空だと「紙」に書き込めない）
  validates :title, presence: true, length: { maximum: 50 }

  # 2. 開始時間は必須
  validates :start_time, presence: true

  # 3. 独自のバリデーション（例：過去の日付で予約できないようにする）
  validate :start_time_cannot_be_in_the_past, on: :create
  validate :end_time_cannot_be_before_start_time

  private

  def start_time_cannot_be_in_the_past
    if start_time.present? && start_time < Time.zone.now
      errors.add(:start_time, "未来の時間にしてください")
    end
  end

  def end_time_cannot_be_before_start_time
    # 開始時間がないのに終了時間だけある場合
    if end_time.present? && start_time.blank?
      errors.add(:start_time, "先に選んでね")
    end

    # 終了時間が開始時間より前、または同じ場合
    if end_time.present? && start_time.present? && end_time <= start_time
      errors.add(:end_time, "開始よりあとの時間に！")
    end
  end
end
