import { Controller } from "@hotwired/stimulus";

/**
 * IconToggleController
 *
 * Manages icon selection between Bootstrap Icons and Custom Icon uploads.
 * Supports SVG, PNG, JPEG, WEBP, and GIF uploads with live preview.
 *
 * Targets:
 * - bootstrapRadio: Radio button for Bootstrap icon selection
 * - customRadio: Radio button for custom icon selection
 * - bootstrapSection: Container for Bootstrap icon input
 * - customSection: Container for icon file upload
 * - iconInput: Text input for Bootstrap icon class
 * - iconPreview: Element to display Bootstrap icon preview
 * - fileInput: File input for icon upload
 * - iconPreviewArea: Container for icon file preview
 * - removeFileCheckbox: Checkbox to remove existing icon
 * - iconTypeField: Hidden field to track selected icon type
 *
 * Values:
 * - hasExistingFile: Boolean indicating if project has existing icon
 * - defaultIcon: Default Bootstrap icon class (default: "bi-folder")
 */
export default class extends Controller {
  static targets = [
    "bootstrapRadio",
    "customRadio",
    "bootstrapSection",
    "customSection",
    "iconInput",
    "iconPreview",
    "fileInput",
    "iconPreviewArea",
    "removeFileCheckbox",
    "iconTypeField",
  ];

  static values = {
    hasExistingFile: { type: Boolean, default: false },
    defaultIcon: { type: String, default: "bi-folder" },
  };

  // Validation constants
  static MAX_FILE_SIZE = 500 * 1024; // 500KB
  static VALID_IMAGE_TYPES = [
    "image/svg+xml",
    "image/png",
    "image/jpeg",
    "image/webp",
    "image/gif",
  ];
  static VALID_IMAGE_EXTENSIONS = [
    ".svg",
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".gif",
  ];
  static VALID_BOOTSTRAP_ICON_PATTERN = /^bi-[\w-]+$/;

  connect() {
    this.initializeState();
    this.previewBootstrapIcon();
  }

  // ============================================================================
  // State Initialization
  // ============================================================================

  initializeState() {
    if (this.hasExistingFileValue && this.hasCustomRadioTarget) {
      this.customRadioTarget.checked = true;
      this.showCustomSection();
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
      this.showCustomSection();
    }
  }

  showBootstrapSection() {
    this.setSectionVisibility(this.bootstrapSectionTarget, true);
    this.setSectionVisibility(this.customSectionTarget, false);
  }

  showCustomSection() {
    this.setSectionVisibility(this.customSectionTarget, true);
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
  // Icon File Preview (SVG, PNG, JPEG, WEBP, GIF)
  // ============================================================================

  previewIconFile(event) {
    const file = event.target.files[0];

    if (!file) {
      this.clearIconPreview();
      return;
    }

    const validationError = this.validateIconFile(file);
    if (validationError) {
      this.showPreviewError(validationError);
      event.target.value = "";
      return;
    }

    if (this.isSvgFile(file)) {
      this.renderSvgPreview(file);
    } else {
      this.renderRasterPreview(file);
    }
  }

  validateIconFile(file) {
    if (!this.isValidImageFile(file)) {
      return "Please select a valid image file (SVG, PNG, JPEG, WEBP, or GIF).";
    }

    if (file.size > this.constructor.MAX_FILE_SIZE) {
      const maxKB = this.constructor.MAX_FILE_SIZE / 1024;
      return `File size exceeds ${maxKB}KB limit.`;
    }

    return null;
  }

  isValidImageFile(file) {
    const validType = this.constructor.VALID_IMAGE_TYPES.includes(file.type);
    const validExt = this.constructor.VALID_IMAGE_EXTENSIONS.some((ext) =>
      file.name.toLowerCase().endsWith(ext),
    );
    return validType || validExt;
  }

  isSvgFile(file) {
    return (
      file.type === "image/svg+xml" || file.name.toLowerCase().endsWith(".svg")
    );
  }

  // ---- SVG preview (rendered inline) ----

  renderSvgPreview(file) {
    const reader = new FileReader();

    reader.onload = (e) => {
      if (!this.hasIconPreviewAreaTarget) return;

      this.iconPreviewAreaTarget.innerHTML = this.buildSvgPreviewHtml(
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
    const svgElement = this.iconPreviewAreaTarget.querySelector("svg");
    if (svgElement) {
      svgElement.style.width = "32px";
      svgElement.style.height = "32px";
    }
  }

  // ---- Raster image preview (PNG, JPEG, WEBP, GIF via dataURL) ----

  renderRasterPreview(file) {
    const reader = new FileReader();

    reader.onload = (e) => {
      if (!this.hasIconPreviewAreaTarget) return;

      this.iconPreviewAreaTarget.innerHTML = this.buildRasterPreviewHtml(
        e.target.result,
        file.name,
        file.size,
      );
    };

    reader.readAsDataURL(file);
  }

  buildRasterPreviewHtml(dataUrl, fileName, fileSize) {
    return `
      <div class="d-flex align-items-center gap-2 mt-2 p-2 border rounded bg-light">
        <div style="width: 32px; height: 32px;">
          <img src="${dataUrl}" alt="Icon preview"
               style="width: 100%; height: 100%; object-fit: contain; border-radius: 4px;" />
        </div>
        <span class="text-success small">
          <i class="bi bi-check-circle me-1"></i>
          ${this.escapeHtml(fileName)} (${this.formatFileSize(fileSize)})
        </span>
      </div>
    `;
  }

  // ---- Legacy alias (in case old views still reference previewSvgFile) ----

  previewSvgFile(event) {
    this.previewIconFile(event);
  }

  handleRemoveFileChange(event) {
    if (event.target.checked) {
      this.clearIconPreview();
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

  clearIconPreview() {
    if (this.hasIconPreviewAreaTarget) {
      this.iconPreviewAreaTarget.innerHTML = "";
    }
  }

  showPreviewError(message) {
    if (this.hasIconPreviewAreaTarget) {
      this.iconPreviewAreaTarget.innerHTML = `
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
