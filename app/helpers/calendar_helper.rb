module CalendarHelper
  def date_class(date)
    classes = []

    # 祝日判定
    classes << "bg-red-50 text-red-600 border-red-100" if HolidayJp.holiday?(date)

    # 土日の判定
    classes << "bg-red-50 text-red-600 border-red-100" if date.sunday?
    classes << "bg-blue-50 text-blue-600 border-blue-100" if date.saturday?

    classes.join(" ")
  end

  def holiday_name(date)
    # 祝日名を取得（マウスホバーで表示させたい場合など）
    HolidayJp.between(date, date).first&.name
  end
end
