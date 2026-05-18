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

      buttonText: {
        today: "今日",
        month: "月",
      },
      dayHeaderFormat: { weekday: "short" },

      // 🚀 1. 各日付の「＋」ボタンの挙動を修正
      dayCellDidMount: (info) => {
        const year = info.date.getFullYear();
        const month = String(info.date.getMonth() + 1).padStart(2, "0");
        const day = String(info.date.getDate()).padStart(2, "0");
        const dateStr = `${year}-${month}-${day}`;
        const newEventUrl = `/events/new?date=${dateStr}`;

        const addButton = document.createElement("a");
        addButton.href = newEventUrl;
        addButton.innerText = "＋";
        addButton.className = "calendar-add-btn";
        addButton.style.float = "right";
        addButton.style.textDecoration = "none";
        addButton.style.color = "#9aa0a6";
        addButton.style.fontSize = "12px";
        addButton.style.padding = "2px 4px";

        // 🚀 通常遷移を絶対に防ぎ、Turbo FrameにURLを流し込む
        addButton.addEventListener("click", (e) => {
          e.preventDefault();
          const modalFrame = document.getElementById("modal");
          if (modalFrame) {
            modalFrame.src = newEventUrl; // これで画面をリロードせず、枠の中だけにフォームをロードする
          }
        });

        const targetEl = info.el.querySelector(".fc-daygrid-day-top");
        if (targetEl) {
          targetEl.appendChild(addButton);
        }
      },

      // 🚀 2. 既存の予定をクリック（編集）したときの挙動を修正
      eventClick: (info) => {
        info.jsEvent.preventDefault(); // 👈 window.location.href による通常遷移を絶対に防止！

        if (info.event.url) {
          const modalFrame = document.getElementById("modal");
          if (modalFrame) {
            modalFrame.src = info.event.url; // 👈 画面をリロードせず、枠の中に編集フォームをロードする
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
        console.log("カレンダーのリアルタイム更新を実行します✨");
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
