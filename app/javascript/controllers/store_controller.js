import BaseComponent from 'components/base_component';

export class SliderComponent extends BaseComponent {
  init() {
    this.slider = this.container.querySelector(".slider")
    this.card = this.container.querySelector(".card");
    this.prevBtn = document.getElementById("prevBtn");
    this.nextBtn = document.getElementById("nextBtn");
    this.addEventListeners();
  }

  step() {
    return this.card ? this.card.offsetWidth + 18 : 280;
  }

  updateArrows() {
    prevBtn.disabled = this.slider.scrollLeft <= 2;
    nextBtn.disabled = this.slider.scrollLeft + this.slider.clientWidth >= this.slider.scrollWidth - 2;
  }

  addEventListeners() {
    this.nextBtn.addEventListener("click", () => {
      this.slider.scrollBy({ left: this.step(), behavior: "smooth" });
    });
    this.prevBtn.addEventListener("click", () => {
      this.slider.scrollBy({ left: -this.step(), behavior: "smooth" });
    });
    this.updateArrows();
  }
}