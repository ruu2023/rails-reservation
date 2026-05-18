class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: %i[edit update destroy]

  def new
    @event = Event.new

    if params[:date].present?
      @event.start_time = Time.zone.parse(params[:date]).beginning_of_day.change(hour: 10)
      @event.end_time = Time.zone.parse(params[:date]).beginning_of_day.change(hour: 11)
    end
  end
  def index
    if params[:start].present? && params[:end].present?
      range_start = Time.zone.parse(params[:start])
      range_end = Time.zone.parse(params[:end])
    else
      @start_date = params.fetch(:start_date, Date.today).to_date.in_time_zone
      range_start = @start_date.beginning_of_month.beginning_of_week
      range_end = @start_date.end_of_month.end_of_week
    end

    # ユーザー自身の予定だけをシンプルに取得
    @events = current_user.events.where(
      "start_time <= ? AND end_time >= ?", range_end, range_start
    )

    respond_to do |format|
      format.html
      format.json {
        render json: @events.map { |event|
          {
            id: event.id,
            title: event.title,
            start: event.start_time.iso8601,
            end: event.end_time&.iso8601,
            url: edit_event_path(event)
          }
        }
      }
    end
  end

  def create
    @event = current_user.events.build(event_params)

    respond_to do |format|
      if @event.save
        broadcast_calendar_refresh(@event)

        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.append("calendar-stream-container", ""),

            # 🚀 修正：枠（turbo-frame）自体は残し、中身の子要素だけを完全に「空」に更新する
            turbo_stream.update("modal", "")
          ]
        }
        format.html { redirect_to events_path(start_date: @event.start_time) }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("modal", partial: "events/modal_form", locals: { title: "予定の追加", show_delete: false }) }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @event.update(event_params)
        broadcast_calendar_refresh(@event)

        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.append("calendar-stream-container", ""),

            # 🚀 修正：ここも update で空にする
            turbo_stream.update("modal", "")
          ]
        }
        format.html { redirect_to events_path(start_date: @event.start_time) }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("modal", partial: "events/modal_form", locals: { title: "予定の編集", show_delete: true }) }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    event_clone = @event.dup
    @event.destroy

    broadcast_calendar_refresh(event_clone)

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.append("calendar-stream-container", ""),

          # 🚀 修正：ここも update で空にする
          turbo_stream.update("modal", "")
        ]
      }
      format.html { redirect_to events_path(start_date: event_clone.start_time), status: :see_other }
    end
  end

  private

  def broadcast_calendar_refresh(event)
    Turbo::StreamsChannel.broadcast_append_to(
      "events_user_#{event.user_id}",
      target: "calendar-stream-container",
      html: "<div data-refresh-at='#{Time.current.to_f}'></div>"
    )
  end

  def set_event
    @event = current_user.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :start_time, :end_time, :content)
  end
end
