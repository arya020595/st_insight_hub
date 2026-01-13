import { Controller } from "@hotwired/stimulus";

/**
 * MultiSortController
 *
 * Enables additive multi-column sorting with Ransack without modifier keys.
 *
 * Usage:
 *   <div data-controller="multi-sort">
 *     <%= sort_link(@q, :column, 'Label') %>
 *   </div>
 *
 * Sort Cycle:
 *   All columns: asc → desc → remove
 */
export default class extends Controller {
  static SORT_LINK_SELECTOR = ".sort_link";
  static RANSACK_SORT_PARAM = "q[s]";
  static RANSACK_SORT_ARRAY_PARAM = "q[s][]";
  static DIRECTION_ASC = "asc";
  static DIRECTION_DESC = "desc";

  connect() {
    this.attachSortLinkListeners();
  }

  /**
   * Attach click event listeners to all sort links
   * @private
   */
  attachSortLinkListeners() {
    const sortLinks = this.element.querySelectorAll(
      this.constructor.SORT_LINK_SELECTOR
    );

    sortLinks.forEach((link) => {
      link.addEventListener("click", (event) => {
        event.preventDefault();
        this.handleSortClick(link);
      });
    });
  }

  /**
   * Handle sort link click event
   * @param {HTMLAnchorElement} link - The clicked sort link
   * @private
   */
  handleSortClick(link) {
    const sortColumn = this.extractSortColumn(link);
    if (!sortColumn) return;

    const currentDirection = this.extractSortDirection(link);
    const updatedSorts = this.calculateUpdatedSorts(
      sortColumn,
      currentDirection
    );
    this.navigateToSortedUrl(updatedSorts);
  }

  /**
   * Extract sort column name from link href
   * @param {HTMLAnchorElement} link - The sort link
   * @returns {string|null} Column name or null
   * @private
   */
  extractSortColumn(link) {
    const sortParam = new URL(link.href).searchParams.get(
      this.constructor.RANSACK_SORT_PARAM
    );
    return sortParam ? sortParam.split(" ")[0] : null;
  }

  /**
   * Extract current sort direction from link's CSS classes
   * Ransack adds 'asc' or 'desc' class to sorted links
   * @param {HTMLAnchorElement} link - The sort link
   * @returns {string|null} Current direction (asc/desc) or null if not sorted
   * @private
   */
  extractSortDirection(link) {
    if (link.classList.contains(this.constructor.DIRECTION_ASC)) {
      return this.constructor.DIRECTION_ASC;
    }
    if (link.classList.contains(this.constructor.DIRECTION_DESC)) {
      return this.constructor.DIRECTION_DESC;
    }
    return null;
  }

  /**
   * Calculate updated sort array based on current sorts and clicked column
   * @param {string} clickedColumn - The column that was clicked
   * @param {string|null} currentDirection - Current sort direction from link's class (asc/desc/null)
   * @returns {Array<string>} Updated sorts array
   * @private
   */
  calculateUpdatedSorts(clickedColumn, currentDirection) {
    const currentSorts = this.getCurrentSorts();
    const existingIndex = this.findSortIndex(currentSorts, clickedColumn);

    if (existingIndex !== -1) {
      // Column already in URL params - cycle it
      return this.cycleExistingSort(currentSorts, existingIndex, clickedColumn);
    }

    // Column not in URL params - check current direction from link's class
    if (currentDirection === this.constructor.DIRECTION_ASC) {
      // Currently asc (default sort) - cycle to desc
      return [
        ...currentSorts,
        `${clickedColumn} ${this.constructor.DIRECTION_DESC}`,
      ];
    } else if (currentDirection === this.constructor.DIRECTION_DESC) {
      // Currently desc - cycle to remove (don't add anything)
      return currentSorts;
    }

    // No current direction - add new sort with asc
    return this.addNewSort(currentSorts, clickedColumn);
  }

  /**
   * Get current sorts from URL
   * @returns {Array<string>} Current sorts array
   * @private
   */
  getCurrentSorts() {
    const currentUrl = new URL(window.location.href);
    return currentUrl.searchParams.getAll(
      this.constructor.RANSACK_SORT_ARRAY_PARAM
    );
  }

  /**
   * Find index of sort for given column
   * @param {Array<string>} sorts - Current sorts array
   * @param {string} column - Column to find
   * @returns {number} Index or -1 if not found
   * @private
   */
  findSortIndex(sorts, column) {
    return sorts.findIndex((sort) => sort.startsWith(`${column} `));
  }

  /**
   * Cycle existing sort through: asc → desc → remove
   * @param {Array<string>} sorts - Current sorts array
   * @param {number} index - Index of sort to cycle
   * @param {string} column - Column name
   * @returns {Array<string>} Updated sorts array
   * @private
   */
  cycleExistingSort(sorts, index, column) {
    const updatedSorts = [...sorts];
    const [, currentDirection] = sorts[index].split(" ");

    if (currentDirection === this.constructor.DIRECTION_ASC) {
      updatedSorts[index] = `${column} ${this.constructor.DIRECTION_DESC}`;
    } else {
      updatedSorts.splice(index, 1);
    }

    return updatedSorts;
  }

  /**
   * Add new sort with ascending direction
   * @param {Array<string>} sorts - Current sorts array
   * @param {string} column - Column to add
   * @returns {Array<string>} Updated sorts array
   * @private
   */
  addNewSort(sorts, column) {
    return [...sorts, `${column} ${this.constructor.DIRECTION_ASC}`];
  }

  /**
   * Navigate to URL with updated sorts
   * @param {Array<string>} sorts - Updated sorts array
   * @private
   */
  navigateToSortedUrl(sorts) {
    const url = this.buildSortedUrl(sorts);
    window.location.href = url.toString();
  }

  /**
   * Build URL with updated sort parameters
   * @param {Array<string>} sorts - Sorts array
   * @returns {URL} Updated URL object
   * @private
   */
  buildSortedUrl(sorts) {
    const url = new URL(window.location.href);

    // Clear existing sort parameters
    url.searchParams.delete(this.constructor.RANSACK_SORT_PARAM);
    url.searchParams.delete(this.constructor.RANSACK_SORT_ARRAY_PARAM);

    // Add updated sort parameters
    sorts.forEach((sort) => {
      url.searchParams.append(this.constructor.RANSACK_SORT_ARRAY_PARAM, sort);
    });

    return url;
  }
}
