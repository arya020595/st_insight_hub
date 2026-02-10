import { Controller } from "@hotwired/stimulus";

/**
 * IconToggleController
 *
 * Manages icon selection between Bootstrap Icons and Custom SVG uploads.
 * Provides live preview for Bootstrap icons and SVG file uploads.
 *
 * Targets:
 * - bootstrapRadio: Radio button for Bootstrap icon selection
 * - svgRadio: Radio button for custom SVG selection
 * - bootstrapSection: Container for Bootstrap icon input
 * - svgSection: Container for SVG file upload
 * - iconInput: Text input for Bootstrap icon class
 * - iconPreview: Element to display Bootstrap icon preview
 * - fileInput: File input for SVG upload
 * - svgPreview: Container for SVG file preview
 * - removeFileCheckbox: Checkbox to remove existing SVG
 * - iconTypeField: Hidden field to track selected icon type
 *
 * Values:
 * - hasExistingFile: Boolean indicating if project has existing SVG
 * - defaultIcon: Default Bootstrap icon class (default: "bi-folder")
 */
export default class extends Controller {
  static targets = [
    "bootstrapRadio",
    "svgRadio",
    "bootstrapSection",
    "svgSection",
    "iconInput",
    "iconPreview",
    "fileInput",
    "svgPreview",
    "removeFileCheckbox",
    "iconTypeField",
  ];

  static values = {
    hasExistingFile: { type: Boolean, default: false },
    defaultIcon: { type: String, default: "bi-folder" },
  };

  // Validation constants
  static MAX_FILE_SIZE = 100 * 1024; // 100KB
  static VALID_BOOTSTRAP_ICON_PATTERN = /^bi-[\w-]+$/;

  connect() {
    this.initializeState();
    this.previewBootstrapIcon();
  }

  // ============================================================================
  // State Initialization
  // ============================================================================

  initializeState() {
    if (this.hasExistingFileValue && this.hasSvgRadioTarget) {
      this.svgRadioTarget.checked = true;
      this.showSvgSection();
    } else if (this.hasBootstrapRadioTarget) {
      this.bootstrapRadioTarget.checked = true;
      this.showBootstrapSection();
    }
  }

  // ============================================================================
  // Section Toggle Actions
  // ============================================================================

  toggle(event) {
    const selectedValue = event?.target?.value || "bootstrap";
    this.updateIconTypeField(selectedValue);

    if (selectedValue === "bootstrap") {
      this.showBootstrapSection();
    } else {
      this.showSvgSection();
    }
  }

  showBootstrapSection() {
    this.setSectionVisibility(this.bootstrapSectionTarget, true);
    this.setSectionVisibility(this.svgSectionTarget, false);
  }

  showSvgSection() {
    this.setSectionVisibility(this.svgSectionTarget, true);
    this.setSectionVisibility(this.bootstrapSectionTarget, false);
  }

  // ============================================================================
  // Bootstrap Icon Preview
  // ============================================================================

  previewBootstrapIcon() {
    if (!this.hasIconPreviewTarget || !this.hasIconInputTarget) return;

    const iconClass = this.iconInputTarget.value.trim();
    const safeIcon = this.sanitizeBootstrapIcon(iconClass);

    this.updateIconPreview(safeIcon);
  }

  sanitizeBootstrapIcon(iconClass) {
    if (
      iconClass &&
      this.constructor.VALID_BOOTSTRAP_ICON_PATTERN.test(iconClass)
    ) {
      return iconClass;
    }
    return this.defaultIconValue;
  }

  updateIconPreview(iconClass) {
    const previewElement = this.iconPreviewTarget;
    previewElement.className = "";
    previewElement.classList.add("bi", iconClass);
    previewElement.style.fontSize = "1.25rem";
  }

  // ============================================================================
  // SVG File Preview
  // ============================================================================

  previewSvgFile(event) {
    const file = event.target.files[0];

    if (!file) {
      this.clearSvgPreview();
      return;
    }

    const validationError = this.validateSvgFile(file);
    if (validationError) {
      this.showPreviewError(validationError);
      event.target.value = "";
      return;
    }

    this.renderSvgPreview(file);
  }

  validateSvgFile(file) {
    if (!this.isValidSvgFile(file)) {
      return "Please select a valid SVG file.";
    }

    if (file.size > this.constructor.MAX_FILE_SIZE) {
      return "File size exceeds 100KB limit.";
    }

    return null;
  }

  isValidSvgFile(file) {
    return (
      file.type === "image/svg+xml" || file.name.toLowerCase().endsWith(".svg")
    );
  }

  renderSvgPreview(file) {
    const reader = new FileReader();

    reader.onload = (e) => {
      if (!this.hasSvgPreviewTarget) return;

      this.svgPreviewTarget.innerHTML = this.buildSvgPreviewHtml(
        e.target.result,
        file.name,
        file.size,
      );

      this.normalizeSvgSize();
    };

    reader.readAsText(file);
  }

  buildSvgPreviewHtml(svgContent, fileName, fileSize) {
    return `
      <div class="d-flex align-items-center gap-2 mt-2 p-2 border rounded bg-light">
        <div style="width: 32px; height: 32px;">${svgContent}</div>
        <span class="text-success small">
          <i class="bi bi-check-circle me-1"></i>
          ${this.escapeHtml(fileName)} (${this.formatFileSize(fileSize)})
        </span>
      </div>
    `;
  }

  normalizeSvgSize() {
    const svgElement = this.svgPreviewTarget.querySelector("svg");
    if (svgElement) {
      svgElement.style.width = "32px";
      svgElement.style.height = "32px";
    }
  }

  handleRemoveFileChange(event) {
    if (event.target.checked) {
      this.clearSvgPreview();
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  setSectionVisibility(target, visible) {
    if (target) {
      target.style.display = visible ? "block" : "none";
    }
  }

  updateIconTypeField(value) {
    if (this.hasIconTypeFieldTarget) {
      this.iconTypeFieldTarget.value = value;
    }
  }

  clearSvgPreview() {
    if (this.hasSvgPreviewTarget) {
      this.svgPreviewTarget.innerHTML = "";
    }
  }

  showPreviewError(message) {
    if (this.hasSvgPreviewTarget) {
      this.svgPreviewTarget.innerHTML = `
        <div class="alert alert-danger py-2 mt-2 small">
          <i class="bi bi-exclamation-triangle me-1"></i> ${this.escapeHtml(message)}
        </div>
      `;
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  formatFileSize(bytes) {
    if (bytes < 1024) return `${bytes} B`;
    return `${(bytes / 1024).toFixed(1)} KB`;
  }
}
