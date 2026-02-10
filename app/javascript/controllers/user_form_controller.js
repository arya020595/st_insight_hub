import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["roleSelect", "companyField"];

  connect() {
    // Initially toggle on load
    this.toggleCompanyField();
  }

  toggleCompanyField() {
    const roleSelect = this.roleSelectTarget;
    const selectedOption = roleSelect.options[roleSelect.selectedIndex];
    const roleName = selectedOption.text.trim();

    // Show company field only if role is "Client"
    if (roleName === "Client") {
      this.companyFieldTarget.style.display = "block";
      this.setCompanyRequired(true);
    } else {
      this.companyFieldTarget.style.display = "none";
      this.setCompanyRequired(false);
    }
  }

  setCompanyRequired(required) {
    const companySelect = this.companyFieldTarget.querySelector("select");
    if (companySelect) {
      if (required) {
        companySelect.setAttribute("required", "required");
      } else {
        companySelect.removeAttribute("required");
      }
    }
  }
}
