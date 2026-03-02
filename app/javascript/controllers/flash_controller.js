import { Controller } from "@hotwired/stimulus";

// Automatically dismisses Bootstrap alert flash messages after a timeout.
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 4000 },
  };

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.delayValue);
  }

  disconnect() {
    clearTimeout(this.timer);
  }

  dismiss() {
    this.element.classList.remove("show");
    this.element.addEventListener(
      "transitionend",
      () => this.element.remove(),
      { once: true },
    );
  }
}
