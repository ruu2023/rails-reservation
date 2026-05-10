class EventsController < ApplicationController
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
    # 表示基準日（なければ今日）
    @start_date = params.fetch(:start_date, Date.today).to_date

    # 表示している月の「月初」から「月末」までをDBから取ってくる
    # all_month を使うと Rails がよしなに範囲を作ってくれます
    @events = Event.where(start_time: @start_date.all_month)
  end

  def create
    @event = Event.new(event_params)
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
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :start_time, :end_time, :content)
  end
end
