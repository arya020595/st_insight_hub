import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="sidebar"
// Handles sidebar toggle, navigation link clicks, and Turbo navigation
export default class extends Controller {
  static targets = ["sidebar"];
  static values = {
    collapsedClass: { type: String, default: "sidebar-collapsed" },
  };

  connect() {
    this.boundHandleDocumentClick = this.handleDocumentClick.bind(this);
    this.boundHandleTurboNavigation = this.handleTurboNavigation.bind(this);
    this.addEventListeners();
  }

  disconnect() {
    this.removeEventListeners();
  }

  // Public Actions
  toggle(event) {
    event?.preventDefault();
    this.sidebar?.classList.toggle(this.collapsedClassValue);
  }

  open() {
    this.sidebar?.classList.remove(this.collapsedClassValue);
  }

  close() {
    this.sidebar?.classList.add(this.collapsedClassValue);
  }

  // Event Listener Management
  addEventListeners() {
    document.addEventListener("click", this.boundHandleDocumentClick);
    document.addEventListener("turbo:load", this.boundHandleTurboNavigation);
    document.addEventListener("turbo:render", this.boundHandleTurboNavigation);
  }

  removeEventListeners() {
    document.removeEventListener("click", this.boundHandleDocumentClick);
    document.removeEventListener("turbo:load", this.boundHandleTurboNavigation);
    document.removeEventListener(
      "turbo:render",
      this.boundHandleTurboNavigation
    );
  }

  // Event Handlers
  handleDocumentClick(event) {
    if (this.isToggleButtonClick(event)) {
      this.toggle(event);
      return;
    }

    if (this.isSidebarNavigationLink(event)) {
      this.open();
    }
  }

  handleTurboNavigation() {
    this.open();
  }

  // Query Methods
  isToggleButtonClick(event) {
    return event.target.closest("#sidebarToggle") !== null;
  }

  isSidebarNavigationLink(event) {
    const link = event.target.closest("a");
    if (!link || !this.sidebar || !link.closest("#sidebar")) {
      return false;
    }

    // Exclude Bootstrap collapse toggles and placeholder links
    return !link.dataset.bsToggle && link.getAttribute("href") !== "#";
  }

  // Getters
  get sidebar() {
    return this.hasSidebarTarget
      ? this.sidebarTarget
      : document.getElementById("sidebar");
  }
}
