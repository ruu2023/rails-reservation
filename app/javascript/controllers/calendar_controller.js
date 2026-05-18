// app/javascript/controllers/calendar_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // 🚀 変更点：holidays: Object を追加
  static values = {
    url: String,
    holidays: Object,
    releaseNoteUntil: String,
    releaseNoteMessage: String,
  };

  connect() {
    const calendarEl = this.element.querySelector("#calendar-root");
    if (!calendarEl) return;

    if (typeof window.FullCalendar === "undefined") return;

    const { Calendar } = window.FullCalendar;
    this.calendar = new Calendar(calendarEl, {
      initialView: "dayGridMonth",
      locale: "ja",
      events: this.urlValue,
      eventDisplay: "block",
      height: "100%",
      expandRows: true,
      dayMaxEvents: true,
      dayCellContent: (info) => {
        return info.dayNumberText.replace("日", "");
      },

      // 🚀 変更：月切り替え時のフックの中に、(i) ボタンの判定と生成を組み込みます
      datesSet: (info) => {
        const titleEl = document.querySelector(".fc-toolbar-title");
        if (titleEl) {
          const current = this.calendar.getDate();
          const month = current.getMonth() + 1;
          const year = current.getFullYear();

          // タイトルの文字をセット
          titleEl.innerHTML = `<span class="calendar-title-month">${month}月</span><span class="calendar-title-year">${year}</span>`;

          // 🚀 期間内であれば (i) ボタンを動的に作成してタイトルの後ろにペタッと貼る
          if (
            this.hasReleaseNoteUntilValue &&
            this.hasReleaseNoteMessageValue
          ) {
            const today = new Date();
            today.setHours(0, 0, 0, 0); // 時間をリセットして日付のみで比較

            const untilDate = new Date(this.releaseNoteUntilValue);
            untilDate.setHours(0, 0, 0, 0);

            // 今日が指定日付以下であればボタンを作る
            if (today <= untilDate) {
              const infoBtn = document.createElement("button");
              infoBtn.type = "button";
              infoBtn.innerHTML = "ⓘ";
              infoBtn.className = "calendar-info-btn";
              infoBtn.title = "リリースノートを見る"; // ホバー時のツールチップ

              // クリックイベントを安全にバインド
              infoBtn.addEventListener("click", () => {
                alert(this.releaseNoteMessageValue); // 🚀 シンプルにメッセージを表示
              });

              titleEl.appendChild(infoBtn);
            }
          }
        }
      },

      // 🚀 追加：「日」の文字を消して数字だけにする
      dayCellContent: (info) => {
        return info.dayNumberText.replace("日", "");
      },

      dateClick: (info) => {
        const newEventUrl = `/events/new?date=${info.dateStr}`;
        const modalFrame = document.getElementById("modal");
        if (modalFrame) {
          modalFrame.src = newEventUrl;
        }
      },

      // 🚀 追加：日付セルが組み立てられる時に祝日を判定してテキストを注入する
      dayCellDidMount: (info) => {
        const year = info.date.getFullYear();
        const month = String(info.date.getMonth() + 1).padStart(2, "0");
        const day = String(info.date.getDate()).padStart(2, "0");
        const dateStr = `${year}-${month}-${day}`;

        // Railsから送られた祝日ハッシュにこの日付があるか判定
        if (this.holidaysValue && this.holidaysValue[dateStr]) {
          const holidayName = this.holidaysValue[dateStr];

          // 祝日名を表示する用のスパン要素を作成
          const holidayLabel = document.createElement("span");
          holidayLabel.innerText = holidayName;
          holidayLabel.className = "calendar-holiday-name";

          // 日付の数字が置いてある右上エリアを取得
          const targetEl = info.el.querySelector(".fc-daygrid-day-top");
          if (targetEl) {
            // 数字と祝日テキストを左右に綺麗にセパレートするためのスタイル配置
            targetEl.style.display = "flex";
            targetEl.style.flexDirection = "row-reverse";
            targetEl.style.justifyContent = "space-between";
            targetEl.style.alignItems = "center";
            targetEl.style.padding = "0px 0px 0 4px";
            targetEl.appendChild(holidayLabel);
          }

          // 🚀 祝日の日の「日付の数字」を赤くするための専用クラスを付与
          const numberEl = info.el.querySelector(".fc-daygrid-day-number");
          if (numberEl) {
            numberEl.classList.add("text-red-active");
          }

          // 🚀 祝日のマスの背景も日曜日と同じ薄赤にするためのクラスを付与
          info.el.classList.add("is-holiday");
        }
      },

      eventClick: (info) => {
        info.jsEvent.preventDefault();
        const popoverCloseBtn = document.querySelector(".fc-popover-close");
        if (popoverCloseBtn) popoverCloseBtn.click();

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

  refresh(event) {
    const target = event.detail.newStream.getAttribute("target");
    if (target === "calendar-stream-container") {
      event.preventDefault();
      if (this.calendar) this.calendar.refetchEvents();
    }
  }

  disconnect() {
    if (this.calendar) this.calendar.destroy();
  }
}
