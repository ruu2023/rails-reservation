class SchedulesController < ApplicationController
  def new
    @event = Event.new

    # パラメータに日付があれば、開始時間の初期値としてセットする
    if params[:date].present?
      # Time.zone.parse を使って安全に日時に変換
      @event.start_time = Time.zone.parse(params[:date]).beginning_of_day
    end
  end
  def index
    @events = Event.all()
  end

  def create
    @event = Event.new(event_params)
    if @event.save
      redirect_to schedules_path, notice: "予約を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def event_params
    params.require(:event).permit(:title, :start_time, :end_time, :content)
  end
end
