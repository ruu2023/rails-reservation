import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["start", "end"];

  sync() {
    if (!this.startTarget.value) return;

    const startDate = new Date(this.startTarget.value);
    // 1時間加算
    startDate.setHours(startDate.getHours() + 1);

    // YYYY-MM-DDTHH:mm 形式に整形
    const year = startDate.getFullYear();
    const month = String(startDate.getMonth() + 1).padStart(2, "0");
    const day = String(startDate.getDate()).padStart(2, "0");
    const hours = String(startDate.getHours()).padStart(2, "0");
    const minutes = String(startDate.getMinutes()).padStart(2, "0");

    this.endTarget.value = `${year}-${month}-${day}T${hours}:${minutes}`;
  }
}
