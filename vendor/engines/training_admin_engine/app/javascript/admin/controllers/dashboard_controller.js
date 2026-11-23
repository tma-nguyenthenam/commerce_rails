import BaseComponent from 'components/base_component';

export class DashboardComponent extends BaseComponent {
  init() {
    console.log("=============== Init Dashboard ================");

    this.orderTableBody = document.getElementById("ordersBody");
    this.getDashboardStats();
    this.getRevenueBarChart();
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

  getRevenueBarChart() {
    /* ----- Revenue bar chart ----- */
    const months = [
      ["Jun", 62], ["Jul", 48], ["Aug", 74], ["Sep", 55],
      ["Oct", 83], ["Nov", 68], ["Dec", 92], ["Jan", 58],
      ["Feb", 71], ["Mar", 64], ["Apr", 88], ["May", 78]
    ];
    const chart = document.getElementById("chart");
    months.forEach(([m, v]) => {
      const col = document.createElement("div");
      col.className = "bar-col";
      col.innerHTML = '<div class="bar" data-val="$' + (v * 0.6).toFixed(1) + 'k" style="height:0"></div><span class="m">' + m + '</span>';
      chart.appendChild(col);
    });
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        document.querySelectorAll(".bar").forEach((b, i) => {
          b.style.height = months[i][1] + "%";
        });
      });
    });
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
