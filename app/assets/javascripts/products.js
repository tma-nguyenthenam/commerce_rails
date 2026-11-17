class CategoryDialog {
  constructor({ formUrl } = {}) {
    this.formUrl = formUrl;

    this.dialog = document.getElementById("category-dialog");
    this.openBtn = document.getElementById("open-category-dialog");
    this.cancelBtn = document.getElementById("cancel-category-dialog");
    this.form = document.getElementById("category-form");
    this.select = document.getElementById("product_category_id");
    this.errorBox = document.getElementById("category-errors");

    this._onOpen = this._onOpen.bind(this);
    this._onCancel = this._onCancel.bind(this);
    this._onSubmit = this._onSubmit.bind(this);
  }

  init() {
    if (!this.dialog || !this.openBtn) return; // guard if not on this page

    this.openBtn.addEventListener("click", this._onOpen);
    this.cancelBtn.addEventListener("click", this._onCancel);
    this.form.addEventListener("submit", this._onSubmit);
  }

  destroy() {
    this.openBtn.removeEventListener("click", this._onOpen);
    this.cancelBtn.removeEventListener("click", this._onCancel);
    this.form.removeEventListener("submit", this._onSubmit);
  }

  _onOpen() {
    this.form.reset();
    this._clearErrors();
    this.dialog.showModal();
  }

  _onCancel() {
    this.dialog.close();
  }

  async _onSubmit(e) {
    e.preventDefault();

    const formData = new FormData(this.form);

    try {
      const response = await fetch(this.formUrl, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json",
        },
        body: formData,
      });

      const data = await response.json();

      if (response.ok) {
        this._addOption(data);
        this.dialog.close();
      } else {
        this._showErrors(data.errors || ["Something went wrong"]);
      }
    } catch (err) {
      this._showErrors(["Network error: " + err.message]);
    }
  }

  _addOption({ id, name }) {
    const option = document.createElement("option");
    option.value = id;
    option.textContent = name;
    option.selected = true;
    this.select.appendChild(option);
  }

  _showErrors(errors) {
    this.errorBox.style.display = "block";
    this.errorBox.innerHTML =
      "<ul>" + errors.map((e) => `<li>${e}</li>`).join("") + "</ul>";
  }

  _clearErrors() {
    this.errorBox.style.display = "none";
    this.errorBox.innerHTML = "";
  }
}

document.addEventListener("DOMContentLoaded", () => {
  new CategoryDialog({
    formUrl: document.getElementById('categories_path').value,
  }).init();
});