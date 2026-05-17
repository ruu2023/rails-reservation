class EventsController < ApplicationController
  # 全アクションでまずログインチェックをする
  before_action :authenticate_user!
  before_action :set_event, only: %i[edit update destroy]
  def new
    @event = Event.new

    # パラメータに日付があれば、開始時間の初期値としてセットする
    if params[:date].present?
      # Time.zone.parse を使って安全に日時に変換
      @event.start_time = Time.zone.parse(params[:date]).beginning_of_day.change(hour: 10)
      @event.end_time = Time.zone.parse(params[:date]).beginning_of_day.change(hour: 11)
    end
  end
  def index
    @start_date = params.fetch(:start_date, Date.today).to_date.in_time_zone

    range = @start_date.beginning_of_month.beginning_of_week..@start_date.end_of_month.end_of_week

    # 🚀 修正: start_time だけでなく、期間が重なるものを全て取得する
    @events = current_user.events.where(
      "start_time <= ? AND end_time >= ?", range.end, range.begin
    )
  end

  def create
    @event = current_user.events.build(event_params)
    if @event.save
      # 🚀 修正: 引数を @event に変更
      broadcast_calendar_refresh(@event)
      # 登録したイベントの開始日を start_date パラメータとして渡す
      redirect_to events_path(start_date: @event.start_time), notice: "予約を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      # 🚀 修正: 引数を @event に変更
      broadcast_calendar_refresh(@event)
      # 更新したイベントの日付を維持
      redirect_to events_path(start_date: @event.start_time), notice: "予約を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 🚀 変更注意: 削除すると @event のデータが消えてしまうので、
    # 判定用に一瞬だけ dup (複製) して値を控えておく
    event_clone = @event.dup
    @event.destroy

    # 🚀 修正: 控えておいたクローンを渡す
    broadcast_calendar_refresh(event_clone)

    redirect_to events_path(start_date: event_clone.start_time), notice: "予約を削除しました", status: :see_other
  end

  private

  def broadcast_calendar_refresh(event)
    # イベントの開始日・終了日（基本の2ヶ月）
    start_month = event.start_time.to_date.beginning_of_month
    end_month   = (event.end_time.present? ? event.end_time.to_date : start_month).beginning_of_month

    # 🚀 強化：イベントが月の境界（1日前後や月末）にある場合、
    # 前後の月を見ているカレンダー画面（はみ出し表示中）にも確実に届くよう、前後1ヶ月も対象に加える
    target_months = [
      start_month.prev_month,
      start_month,
      end_month,
      end_month.next_month
    ].uniq

    target_months.each do |month_date|
      start_date = month_date.in_time_zone
      range = start_date.beginning_of_month.beginning_of_week..start_date.end_of_month.end_of_week

      events = current_user.events.where(
        "start_time <= ? AND end_time >= ?", range.end, range.begin
      )

      stream_name = "events_user_#{current_user.id}_month_#{start_date.strftime('%Y-%m')}"

      renderer = ApplicationController.renderer.new(
        http_host: "localhost:3000",
        https: Rails.env.production?
      )

      Turbo::StreamsChannel.broadcast_replace_to(
        stream_name,
        target: "realtime_calendar",
        html: renderer.render(
          partial: "events/calendar",
          locals: { events: events },
          assigns: { _routes: Rails.application.routes },
          extra_chunks: [],
          routes: Rails.application.routes
        )
      )
    end
  end
  def set_event
    @event = current_user.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :start_time, :end_time, :content)
  end
end
