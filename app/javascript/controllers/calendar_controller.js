// app/javascript/controllers/calendar_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { url: String };

  connect() {
    const calendarEl = this.element.querySelector("#calendar-root");
    if (!calendarEl) return;

    if (typeof window.FullCalendar === "undefined") {
      console.error("FullCalendar is not loaded yet.");
      return;
    }

    const { Calendar } = window.FullCalendar;
    this.calendar = new Calendar(calendarEl, {
      initialView: "dayGridMonth",
      locale: "ja",
      events: this.urlValue,
      eventDisplay: "block",
      height: "100%",
      expandRows: true,
      dayMaxEvents: true,

      // 余白クリックでモーダルを開く処理（これは残します）
      dateClick: (info) => {
        const newEventUrl = `/events/new?date=${info.dateStr}`;
        const modalFrame = document.getElementById("modal");
        if (modalFrame) {
          modalFrame.src = newEventUrl;
        }
      },

      // 🚀 修正点：ここに書いてあった `dayCellDidMount` を丸ごと削除しました

      // 予定クリックで編集モーダルを開く処理（これも残します）
      eventClick: (info) => {
        info.jsEvent.preventDefault();

        // 🚀 追加：画面内にFullCalendarのポップアップの閉じるボタン（×）があれば、プログラムからクリックして閉じる
        const popoverCloseBtn = document.querySelector(".fc-popover-close");
        if (popoverCloseBtn) {
          popoverCloseBtn.click();
        }

        if (info.event.url) {
          const modalFrame = document.getElementById("modal");
          if (modalFrame) {
            modalFrame.src = info.event.url;
          }
        }
      },
    });

    this.calendar.render();
  }

  // WebSocket通知が来たらここが動く
  refresh(event) {
    // 🚀 サーバーから届いたストリームの「target」属性を取得
    const target = event.detail.newStream.getAttribute("target");

    // カレンダー更新用のコンテナ（calendar-stream-container）宛ての通知の時だけ処理する
    if (target === "calendar-stream-container") {
      // 空のdivが画面に変に挿入されるのを防止
      event.preventDefault();

      if (this.calendar) {
        this.calendar.refetchEvents(); // 👈 これでFullCalendarが最新のJSONをシュッと再取得します
      }
    }
    // target が "modal" などの場合は、何もせずRails（Turbo）本来の処理（モーダルを閉じる）に流します
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy();
    }
  }
}
