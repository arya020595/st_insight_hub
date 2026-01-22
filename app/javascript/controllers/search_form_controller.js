import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

/**
 * SearchFormController
 *
 * Manages search form interactions with automatic submissions, pagination reset,
 * and focus persistence across page reloads for improved user experience.
 * Uses Turbo for smooth, refresh-free navigation.
 *
 * @class SearchFormController
 * @extends Controller
 *
 * @example
 * <%= search_form_for @q, html: { data: { controller: "search-form", action: "submit->search-form#resetPage" } } do |f| %>
 *   <%= f.text_field :name, data: { action: "input->search-form#autoSubmit" } %>
 *   <%= f.select :status, options, data: { action: "change->search-form#instantSubmit" } %>
 * <% end %>
 */
export default class extends Controller {
  // Constants
  static DEBOUNCE_DELAY = 600;
  static STORAGE_KEY = "searchFormFocusedInput";
  static PAGE_PARAM = "page";
  static FOCUSABLE_INPUT_TYPES = ["INPUT", "TEXTAREA", "SELECT"];

  /**
   * Lifecycle: Initialize controller and restore focus state
   */
  connect() {
    this.restoreFocusState();
  }

  /**
   * Lifecycle: Cleanup resources when controller is disconnected
   */
  disconnect() {
    this.clearDebounceTimeout();
  }

  /**
   * Debounced auto-submit for text search inputs
   * Waits for user to stop typing before submitting (600ms delay)
   * Use this ONLY for search text fields to prevent excessive submissions
   *
   * @param {Event} event - Input event
   * @public
   * @example data: { action: "input->search-form#autoSubmit" }
   */
  autoSubmit(event) {
    this.clearDebounceTimeout();
    this.timeout = setTimeout(() => {
      this.submitForm();
    }, this.constructor.DEBOUNCE_DELAY);
  }

  /**
   * Immediate form submission without debounce delay
   * Use this for filters like dropdowns, checkboxes, radio buttons
   * Submits instantly when user makes a selection
   *
   * @param {Event} event - Change event
   * @public
   * @example data: { action: "change->search-form#instantSubmit" }
   */
  instantSubmit(event) {
    this.submitForm();
  }

  /**
   * Reset pagination and rebuild URL on form submission
   * Stores focus state for restoration after page reload
   *
   * @param {Event} event - Submit event
   * @public
   */
  resetPage(event) {
    event.preventDefault();

    const form = event.target;
    if (!this.isValidForm(form)) {
      console.warn("Invalid form element");
      return;
    }

    this.saveFocusState(form);
    const targetUrl = this.buildSearchUrl(form);
    this.navigateToUrl(targetUrl);
  }

  // Private methods

  /**
   * Submit the form programmatically
   * @private
   */
  submitForm() {
    if (this.element && typeof this.element.requestSubmit === "function") {
      this.element.requestSubmit();
    }
  }

  /**
   * Clear any pending debounce timeout
   * @private
   */
  clearDebounceTimeout() {
    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
  }

  /**
   * Validate form element
   *
   * @param {HTMLElement} form - Form element to validate
   * @returns {boolean} True if valid form
   * @private
   */
  isValidForm(form) {
    return form && form.tagName === "FORM";
  }

  /**
   * Build search URL from form data, excluding pagination
   *
   * @param {HTMLFormElement} form - Form element
   * @returns {URL} Constructed URL object
   * @private
   */
  buildSearchUrl(form) {
    const url = new URL(form.action || window.location.href);
    const formData = new FormData(form);

    url.search = "";

    for (const [key, value] of formData.entries()) {
      if (this.shouldIncludeParam(value)) {
        url.searchParams.append(key, value);
      }
    }

    url.searchParams.delete(this.constructor.PAGE_PARAM);

    return url;
  }

  /**
   * Determine if parameter should be included in URL
   *
   * @param {string} value - Parameter value
   * @returns {boolean} True if parameter should be included
   * @private
   */
  shouldIncludeParam(value) {
    return value !== "" && value !== null && value !== undefined;
  }

  /**
   * Save currently focused input to session storage
   *
   * @param {HTMLFormElement} form - Form element
   * @private
   */
  saveFocusState(form) {
    const activeElement = document.activeElement;

    if (this.isFocusableInput(activeElement) && form.contains(activeElement)) {
      const identifier = this.getInputIdentifier(activeElement);
      if (identifier) {
        sessionStorage.setItem(this.constructor.STORAGE_KEY, identifier);
      }
    }
  }

  /**
   * Restore focus to previously focused input after page load
   * @private
   */
  restoreFocusState() {
    const focusedInputName = sessionStorage.getItem(
      this.constructor.STORAGE_KEY,
    );

    if (focusedInputName) {
      this.focusInputByName(focusedInputName);
      sessionStorage.removeItem(this.constructor.STORAGE_KEY);
    }
  }

  /**
   * Focus input by name and position cursor at end
   *
   * @param {string} inputName - Input name attribute
   * @private
   */
  focusInputByName(inputName) {
    const input = this.element.querySelector(
      `[name="${CSS.escape(inputName)}"]`,
    );

    if (input) {
      input.focus();
      this.moveCursorToEnd(input);
    }
  }

  /**
   * Move cursor to end of input value
   *
   * @param {HTMLInputElement|HTMLTextAreaElement} input - Input element
   * @private
   */
  moveCursorToEnd(input) {
    if (input.setSelectionRange && input.value) {
      const length = input.value.length;
      input.setSelectionRange(length, length);
    }
  }

  /**
   * Check if element is a focusable input type
   *
   * @param {HTMLElement} element - Element to check
   * @returns {boolean} True if element is focusable input
   * @private
   */
  isFocusableInput(element) {
    return (
      element &&
      this.constructor.FOCUSABLE_INPUT_TYPES.includes(element.tagName)
    );
  }

  /**
   * Get unique identifier for input element
   *
   * @param {HTMLElement} input - Input element
   * @returns {string|null} Input name or id
   * @private
   */
  getInputIdentifier(input) {
    return input.name || input.id || null;
  }

  /**
   * Navigate to URL using Turbo for smooth, refresh-free experience
   *
   * @param {URL} url - Target URL
   * @private
   */
  navigateToUrl(url) {
    Turbo.visit(url.toString(), { action: "replace" });
  }
}
