import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["companySelect", "usersSelect"];

  connect() {
    // Load users if a company is already selected (for edit mode)
    if (this.hasCompanySelectTarget && this.companySelectTarget.value) {
      this.loadUsers();
    }
  }

  async loadUsers(event) {
    const companyId = this.companySelectTarget.value;

    if (!companyId) {
      this.usersSelectTarget.innerHTML = "";
      return;
    }

    // Store currently selected user IDs to preserve selection
    const selectedUserIds = Array.from(
      this.usersSelectTarget.selectedOptions,
    ).map((option) => option.value);

    try {
      const response = await fetch(
        `/projects/company_users?company_id=${companyId}`,
      );
      const users = await response.json();

      this.usersSelectTarget.innerHTML = users
        .map((user) => {
          const isSelected = selectedUserIds.includes(String(user.id));
          return `<option value="${user.id}" ${isSelected ? "selected" : ""}>${user.name} (${user.email})</option>`;
        })
        .join("");
    } catch (error) {
      console.error("Error loading users:", error);
      this.usersSelectTarget.innerHTML =
        '<option value="" disabled>Error loading users</option>';
    }
  }
}
