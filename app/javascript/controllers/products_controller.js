import BaseComponent from 'components/base_component';

export class CategoryDialog extends BaseComponent {
  init() {
    this.formUrl = this.container.dataset.formUrl;

    this.dialog = document.getElementById("category-dialog");
    this.openBtn = document.getElementById("open-category-dialog");
    this.cancelBtn = document.getElementById("cancel-category-dialog");
    this.form = document.getElementById("category-form");
    this.select = document.getElementById("product_category_id");
    this.errorBox = document.getElementById("category-errors");

    this._onOpen = this._onOpen.bind(this);
    this._onCancel = this._onCancel.bind(this);
    this._onSubmit = this._onSubmit.bind(this);

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

export class ProductFormComponent extends BaseComponent {
  init() {
    this.form = this.container.querySelector("form") || this.container;

    // Color picker
    this.colorList = this.container.querySelector("#color-list");
    this.colorHidden = this.container.querySelector("#colors-hidden");
    this.addColorBtn = this.container.querySelector("#add-color");

    // Options JSON
    this.optionsArea = this.container.querySelector('textarea[name="product[options]"]');
    this.optionsError = this.container.querySelector("#options-error");

    this.addEventListeners();
    this.refreshColors();

    // Bind any colors already rendered by the server
    if (this.colorList) {
      this.colorList
        .querySelectorAll(".color-item")
        .forEach((row) => this.bindColorRow(row));
    }
  }

  addEventListeners() {
    // ----- Color picker -----
    if (this.addColorBtn) {
      this.addColorBtn.addEventListener("click", (event) => this.onAddColor(event));
    }

    if (this.colorList) {
      // Delegate: color/text input changes and remove button clicks
      this.colorList.addEventListener("input", (event) => this.onColorListInput(event));
      this.colorList.addEventListener("click", (event) => this.onColorListClick(event));
    }

    // ----- Options JSON -----
    if (this.optionsArea) {
      this.optionsArea.addEventListener("input", (event) => this.onOptionsInput(event));
    }

    // Prevent submit when JSON is invalid
    if (this.form) {
      this.form.addEventListener("submit", (event) => this.onFormSubmit(event));
    }
  }

  // ---------- Colors ----------
  onAddColor = () => {
    this.addColor("#000000");
  };

  onColorListClick = (event) => {
    if (event.target.classList.contains("remove-color")) {
      const row = event.target.closest(".color-item");
      if (row) row.remove();
      this.refreshColors();
    }
  };

  onColorListInput = (event) => {
    const row = event.target.closest(".color-item");
    if (!row) return;

    const swatch = row.querySelector(".color-input");
    const text = row.querySelector(".color-text");

    if (!swatch || !text) return;

    if (event.target === swatch) {
      text.value = swatch.value;
    } else if (event.target === text) {
      // Only sync swatch when the text is a valid hex
      if (/^#[0-9a-fA-F]{6}$/.test(text.value)) {
        swatch.value = text.value;
      }
    }

    this.refreshColors();
  };

  addColor(value) {
    if (!this.colorList) return;

    const row = document.createElement("div");
    row.className = "color-item";
    row.style.setProperty("--swatch", value);
    row.innerHTML = `
      <input type="color" class="color-input" value="${value}">
      <input type="text" class="color-text" value="${value}">
      <button type="button" class="btn btn-danger remove-color">×</button>
    `;
    this.colorList.appendChild(row);
    this.bindColorRow(row);
    this.refreshColors();
  }

  bindColorRow(row) {
    // Nothing to bind in delegation mode; kept for parity / server rows
    // (the delegated listeners in `addEventListeners` already handle them)
  }

  /**
   * Rebuild the hidden inputs so the form submits
   * product[colors][] = ["#ff0000", ...]
   */
  refreshColors() {
    if (!this.colorHidden || !this.colorList) return;

    this.colorHidden.innerHTML = "";
    this.colorList.querySelectorAll(".color-item").forEach((row) => {
      const text = row.querySelector(".color-text");
      if (!text || !text.value.trim()) return;

      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "product[colors][]";
      input.value = text.value.trim();
      this.colorHidden.appendChild(input);
    });
  }

  // ---------- Options JSON ----------
  onOptionsInput = () => {
    if (!this.optionsArea || !this.optionsError) return;

    try {
      JSON.parse(this.optionsArea.value || "{}");
      this.optionsError.style.display = "none";
      this.optionsArea.classList.remove("invalid");
    } catch (e) {
      this.optionsError.style.display = "block";
      this.optionsArea.classList.add("invalid");
    }
  };

  onFormSubmit = (event) => {
    // Ensure options is valid JSON before submit
    if (this.optionsArea && this.optionsError) {
      try {
        JSON.parse(this.optionsArea.value || "{}");
      } catch (e) {
        event.preventDefault();
        this.optionsError.style.display = "block";
        this.optionsArea.focus();
      }
    }
  };

  destroy() {
    if (this.addColorBtn) {
      this.addColorBtn.removeEventListener("click", this.onAddColor);
    }
    if (this.colorList) {
      this.colorList.removeEventListener("input", this.onColorListInput);
      this.colorList.removeEventListener("click", this.onColorListClick);
    }
    if (this.optionsArea) {
      this.optionsArea.removeEventListener("input", this.onOptionsInput);
    }
    if (this.form) {
      this.form.removeEventListener("submit", this.onFormSubmit);
    }
    super.destroy();
  }
}

export class ProductDetailComponent extends BaseComponent {
  init() {
    document.body.style.backgroundColor = '#fff';
    this.imageGallery();
    this.optionsEvent();
    window.toast = this.toast;
  }

  imageGallery() {
    // ---- Image gallery slider ----
    const jsonValue = document.getElementById("gallery_items")?.value;
    const galleryImages = JSON.parse(jsonValue) || [];

    const track = document.getElementById("galleryTrack");
    const dotsWrap = document.getElementById("galleryDots");
    let currentSlide = 0;

    function goToSlide(i) {
      currentSlide = Math.max(0, Math.min(galleryImages.length - 1, i));
      track.style.transform = `translateX(-${currentSlide * 100}%)`;
      dotsWrap.querySelectorAll(".dot").forEach((d, di) =>
        d.classList.toggle("active", di === currentSlide)
      );
    }

    dotsWrap.addEventListener("click", (e) => {
      const dot = e.target.closest(".dot");
      if (dot) goToSlide(Number(dot.dataset.index));
    });
    document.getElementById("galleryNext").addEventListener("click", () => goToSlide(currentSlide + 1));
    document.getElementById("galleryPrev").addEventListener("click", () => goToSlide(currentSlide - 1));
  }

  toast(msg) {
    const t = document.getElementById("toast");
    t.textContent = msg;
    t.classList.add("show");
    setTimeout(() => t.classList.remove("show"), 2200);
  }


  showToast(msg) {
    this.toast(`\u2713 ${msg} \u2014 ${config.size}, ${config.color}, ${config.storage}`);
  }

  optionsEvent() {
    const config = { color: "Black Titanium", size: "6.3-inch iPhone 16 Pro", storage: "128GB" };
    let totalUpgrade = 0;

    document.querySelectorAll(".options").forEach(group => {
      const block = group.closest(".config-block");
      const step = block.dataset.step;
      group.addEventListener("click", (e) => {
        const opt = e.target.closest(".option");
        if (!opt) return;
        group.querySelectorAll(".option").forEach(o => o.classList.remove("selected"));
        opt.classList.add("selected");
        config[step] = opt.dataset.name;

        // recompute total upgrades across all steps
        totalUpgrade = ["color", "size", "storage"].reduce((sum, s) => {
          const sel = document.querySelector(`.config-block[data-step="${s}"] .option.selected`);
          return sum + Number(sel?.dataset.upgrade || 0);
        }, 0);

        document.getElementById("barPrice").textContent = "From $" + (BASE_PRICE + totalUpgrade).toLocaleString();
      });
    });
  }
}