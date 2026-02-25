import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

// Connects to data-controller="tom-select"
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "Select..." },
    maxItems: { type: Number, default: 0 },
  };

  connect() {
    this.tomSelect = new TomSelect(this.element, {
      plugins: ["remove_button"],
      placeholder: this.placeholderValue,
      maxItems: this.maxItemsValue || null,
      allowEmptyOption: true,
      closeAfterSelect: false,
      hidePlaceholder: true,
    });
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy();
    }
  }
}
