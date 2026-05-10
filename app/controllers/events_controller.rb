class EventsController < ApplicationController
  def new
    @event = Event.new

    # パラメータに日付があれば、開始時間の初期値としてセットする
    if params[:date].present?
      # Time.zone.parse を使って安全に日時に変換
      @event.start_time = Time.zone.parse(params[:date]).beginning_of_day
    end
  end
  def index
    # @events = Event.all()
    # controllerで表示期間を制御
    @start_date = params.fetch(:start_date, Date.today).to_date
    @events = Event.where(start_time: @start_date.beginning_of_week..@start_date.advance(weeks: 2).end_of_week)
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to events_path, notice: "予約を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def event_params
    params.require(:event).permit(:title, :start_time, :end_time, :content)
  end
end
