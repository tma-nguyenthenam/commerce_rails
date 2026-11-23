import BaseComponent from "components/base_component";

export class ProductsController extends BaseComponent {
  init() {
    this.grid = null;
    this.wrapper = document.getElementById("wrapper");
    this.url = document.getElementById("api_v1_dashboard_api_products_path")?.value;
    this.columns = this.loadGrid();
  }

  loadGrid() {
    this.grid = new Grid({
      columns: [],
      server: {
        url: this.url,
        then: (data) =>
          data.results.map((movie) => [
            movie.title,
            movie.director,
            movie.producer,
          ]),
      },
    }).render(this.wrapper);
  }
}
