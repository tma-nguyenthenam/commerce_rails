// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

import { CategoryDialog, ProductFormComponent, ProductDetailComponent } from "controllers/products_controller"
import { SliderComponent } from "controllers/store_controller";
import { DashboardComponent } from "admin/controllers/dashboard_controller";
import { ProductsController } from "admin/controllers/products_controller";

document.addEventListener('turbo:load', () => {
  // Find all elements with data-component attribute
  document.querySelectorAll('[data-component]').forEach(element => {
    const componentName = element.dataset.component;

    switch (componentName) {
      case 'category-dialog':
        new CategoryDialog(element);
        break;
      case 'slider':
        new SliderComponent(element);
        break;
      case 'product-form':
        new ProductFormComponent(element);
        break;
      case 'dashboard':
        new DashboardComponent(element);
      case 'product-detail':
        new ProductDetailComponent(element);
        break;
      case 'products-controller':
        new ProductsController(element);
        break;
    }
  });
});
