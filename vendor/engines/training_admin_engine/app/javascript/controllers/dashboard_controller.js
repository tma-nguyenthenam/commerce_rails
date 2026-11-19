import BaseComponent from 'components/base_component';

export class DashboardComponent extends BaseComponent {
  init() {
    console.log("=============== Init Dashboard ================");

    this.orderTableBody = document.getElementById("ordersBody");
    this.getDashboardStats();
    this.getRecentOrdersTable();
  }

  getDashboardStats() {
    const url = document.getElementById('api_v1_dashboard_stats_path')?.value;
    this.orderTableBody.innerHTML = 'Loading...';
    fetch(url)
      .then(r => r.json())
      .then(({ stats }) => {
        stats.forEach(s => {
          const arrow = s.direction === 'up' ? '▲' : '▼';
          document.querySelector(`[data-stat="${s.label}"] .value`).textContent = s.value;
          document.querySelector(`[data-stat="${s.label}"] .trend`)
            .className = `trend ${s.direction}`;
          document.querySelector(`[data-stat="${s.label}"] .trend`).textContent =
            `${arrow} ${s.change}%`;
        });
      })
  }

  getRecentOrdersTable() {
    const url = document.getElementById('api_v1_dashboard_orders_path')?.value;
    fetch(url)
      .then(r => r.json())
      .then(({ rows }) => {
        this.renderOrders(rows);
      })
  }

  renderOrders(orders) {
    this.orderTableBody.innerHTML = orders.map(o => {
      return '<tr>' +
        '<td style="font-weight:600">#' + o.order_id + '</td>' +
        '<td>' + o.customer_name + '</td>' +
        '<td>' + o.product_name + '</td>' +
        '<td style="color:var(--muted)">' + o.created_at + '</td>' +
        '<td style="font-weight:600">' + o.order_total + '</td>' +
        '<td><span class="pill ' + o.order_status + '">' + o.order_status.charAt(0).toUpperCase() + o.order_status.slice(1) + '</span></td>' +
        '</tr>';
    }).join("");
  }
}
