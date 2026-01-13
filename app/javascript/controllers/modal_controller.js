import { Controller } from "@hotwired/stimulus";

// Shared/Generic Modal Controller (SOLID Refactored)
// ===================================================
// Single Responsibility: Manages modal lifecycle and size configuration
// Open/Closed: Easy to extend via data attributes without modifying controller
// Liskov Substitution: Works with any Bootstrap modal implementation
// Dependency Inversion: Depends on abstractions (data attributes) not concrete implementations
//
// Usage: data-controller="modal"
// Works with any Turbo Frame - just specify the frame ID via data-modal-frame-id-value
// Best practice: keep modal container persistent in DOM; load content via <turbo-frame>
//
// Modal size can be dynamically overridden by adding data-modal-size to triggering links:
//   <%= link_to "Edit", edit_path(record), **modal_link_data(size: "modal-xl") %>
export default class extends Controller {
  static values = {
    frameId: { type: String, default: "modal" },
    focusSelector: {
      type: String,
      default: "input:not([type=hidden]), select, textarea",
    },
  };

  // Valid Bootstrap modal size classes
  static VALID_SIZES = [
    "modal-sm",
    "modal-md",
    "modal-lg",
    "modal-xl",
    "modal-fullscreen",
  ];

  connect() {
    // Prefer Bootstrap UMD global when using importmap pin to bootstrap.min.js
    this.BootstrapModal = (window.bootstrap && window.bootstrap.Modal) || null;

    if (!this.BootstrapModal) {
      // As a fallback, try to resolve from ESM import if environment provides it
      // (We avoid direct import to keep compatibility with UMD build.)
      console.warn(
        "Bootstrap Modal not found on window.bootstrap. Ensure 'import \"bootstrap\"' is present in application.js and importmap pins bootstrap.min.js"
      );
    }

    // Bind handlers once so we can remove them later
    this._clearHandler = this.clearFrame.bind(this);
    this._submitHandler = this.formSubmitted.bind(this);

    // Get modal options from data attributes (allows customization per modal)
    const backdrop = this.element.dataset.bsBackdrop || "static";
    const keyboard = this.element.dataset.bsKeyboard === "true";

    // Create Bootstrap Modal instance
    if (this.BootstrapModal) {
      this.modal = new this.BootstrapModal(this.element, {
        backdrop: backdrop,
        keyboard: keyboard,
      });
    }

    // Hide/clear behaviors
    this.element.addEventListener("hidden.bs.modal", this._clearHandler);
    // Close on successful submit (201/200)
    this.element.addEventListener("turbo:submit-end", this._submitHandler);
    // Ensure modal is hidden before caching the page (back/forward nav)
    this.element.addEventListener("turbo:before-cache", () => {
      if (this.modal) this.modal.hide();
    });

    // Focus first input when shown
    this.element.addEventListener("shown.bs.modal", () =>
      this.focusFirstField()
    );
  }

  /**
   * Show modal and apply dynamic size from trigger link
   * Follows Open/Closed Principle: size can be changed via data attributes
   * without modifying this method
   */
  show(event) {
    // Ensure Bootstrap modal exists
    if (!this.modal && this.BootstrapModal) {
      const backdrop = this.element.dataset.bsBackdrop || "static";
      const keyboard = this.element.dataset.bsKeyboard === "true";

      this.modal = new this.BootstrapModal(this.element, {
        backdrop: backdrop,
        keyboard: keyboard,
      });
    }

    // Apply dynamic modal size based on clicked link
    this.applyDynamicSize();

    // Actually show the modal
    this.modal.show();
  }

  /**
   * Applies modal size from the triggering link's data-modal-size attribute
   * This allows each link to specify its preferred modal size
   * Single Responsibility: Only handles size application
   */
  applyDynamicSize() {
    const modalDialog = this.element.querySelector(".modal-dialog");
    if (!modalDialog) return;

    // Remove all previous size classes
    this.constructor.VALID_SIZES.forEach((size) => {
      modalDialog.classList.remove(size);
    });

    // Get the last clicked modal trigger (set by application.js)
    const trigger = window.lastModalTrigger;

    // Apply the requested size if valid
    if (trigger?.dataset?.modalSize) {
      const requestedSize = trigger.dataset.modalSize;

      if (this.constructor.VALID_SIZES.includes(requestedSize)) {
        modalDialog.classList.add(requestedSize);
      } else {
        console.warn(
          `Invalid modal size "${requestedSize}". Valid sizes: ${this.constructor.VALID_SIZES.join(
            ", "
          )}`
        );
      }
    }
  }

  /**
   * Handle form submission
   * Close modal on successful submission (200/201)
   * Keep modal open on validation errors (422) to show error messages
   */
  formSubmitted(event) {
    const { success } = event.detail;
    // If validation failed (422), keep modal open to show errors
    if (success) {
      this.modal.hide();
    }
  }

  /**
   * Clear the turbo frame content when modal is hidden
   * This ensures fresh content on next modal open
   */
  clearFrame() {
    const frame = this.element.querySelector(
      `turbo-frame#${this.frameIdValue}`
    );
    if (frame) frame.innerHTML = "";
  }

  /**
   * Focus the first interactive field in the modal for better UX
   * Improves keyboard navigation and accessibility
   */
  focusFirstField() {
    const frame = this.element.querySelector(
      `turbo-frame#${this.frameIdValue}`
    );
    if (!frame) return;
    const el = frame.querySelector(this.focusSelectorValue);
    if (el && typeof el.focus === "function") el.focus();
  }

  /**
   * Cleanup when controller is disconnected
   * Follows good memory management practices
   */
  disconnect() {
    this.element.removeEventListener("hidden.bs.modal", this._clearHandler);
    this.element.removeEventListener("turbo:submit-end", this._submitHandler);

    if (this.modal) this.modal.dispose();
  }
}
