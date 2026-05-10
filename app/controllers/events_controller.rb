class EventsController < ApplicationController
  # 全アクションでまずログインチェックをする
  before_action :authenticate_user!
  before_action :set_event, only: %i[edit update destroy]
  def new
    @event = Event.new

    # パラメータに日付があれば、開始時間の初期値としてセットする
    if params[:date].present?
      # Time.zone.parse を使って安全に日時に変換
      @event.start_time = Time.zone.parse(params[:date]).beginning_of_day
    end
  end
  def index
    @start_date = params.fetch(:start_date, Date.today).to_date.in_time_zone

    # カレンダーが表示する全期間（前後の月のはみ出し分を含む）を計算
    # beginning_of_month (月初) -> beginning_of_week (その週の月曜)
    # end_of_month (月末) -> end_of_week (その週の日曜)
    range = @start_date.beginning_of_month.beginning_of_week..@start_date.end_of_month.end_of_week

    @events = current_user.events.where(start_time: range)
  end

  def create
    @event = current_user.events.build(event_params)
    if @event.save
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
      # 更新したイベントの日付を維持
      redirect_to events_path(start_date: @event.start_time), notice: "予約を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 削除する前に日付を控えておく
    saved_date = @event.start_time
    @event.destroy
    # 控えていた日付の月へ戻る
    redirect_to events_path(start_date: saved_date), notice: "予約を削除しました", status: :see_other
  end

  private

  def set_event
    @event = current_user.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :start_time, :end_time, :content)
  end
end
