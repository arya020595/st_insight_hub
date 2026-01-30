import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["companySelect", "usersSelect"];

  async loadUsers(event) {
    const companyId = this.companySelectTarget.value;

    if (!companyId) {
      this.usersSelectTarget.innerHTML = "";
      return;
    }

    try {
      const response = await fetch(
        `/projects/company_users?company_id=${companyId}`,
      );
      const users = await response.json();

      this.usersSelectTarget.innerHTML = users
        .map(
          (user) =>
            `<option value="${user.id}">${user.name} (${user.email})</option>`,
        )
        .join("");
    } catch (error) {
      console.error("Error loading users:", error);
    }
  }
}
