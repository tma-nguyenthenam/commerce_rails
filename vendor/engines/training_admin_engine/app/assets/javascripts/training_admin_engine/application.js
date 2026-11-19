/* ----- Sidebar collapse / expand ----- */
const sidebar = document.getElementById("sidebar");
document.getElementById("collapseBtn").addEventListener("click", () => {
  sidebar.classList.toggle("collapsed");
});

/* Nav active state */
document.querySelectorAll(".nav-item").forEach(item => {
  item.addEventListener("click", () => {
    document.querySelectorAll(".nav-item").forEach(i => i.classList.remove("active"));
    item.classList.add("active");
  });
});

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

/* ----- Recent orders table ----- */
const products = [
  ["iPhone 15 Pro", "📱", "#eef2ff"], ["Hoodie Grey", "👕", "#ecfdf5"],
  ["Coffee Maker", "☕", "#fffbeb"], ["Desk Chair", "🪑", "#fef2f2"],
  ["Smart Watch", "⌚", "#f5f3ff"]
];
const statuses = ["completed", "pending", "cancelled"];
const orders = [
  ["#10245", "Mai Nguyen", 0, "Nov 18, 2026", "$1,199.00", "completed"],
  ["#10244", "John Carter", 1, "Nov 18, 2026", "$64.00", "pending"],
  ["#10243", "Lan Pham", 2, "Nov 17, 2026", "$89.50", "completed"],
  ["#10242", "David Lee", 3, "Nov 17, 2026", "$249.00", "cancelled"],
  ["#10241", "Sarah Kim", 4, "Nov 16, 2026", "$399.00", "completed"],
  ["#10240", "An Tran", 0, "Nov 15, 2026", "$1,199.00", "pending"]
];
const body = document.getElementById("ordersBody");
function renderOrders() {
  body.innerHTML = orders.map(o => {
    const p = products[o[2]];
    const pill = o[5];
    return '<tr>' +
      '<td style="font-weight:600">' + o[0] + '</td>' +
      '<td>' + o[1] + '</td>' +
      '<td><span class="thumb" style="background:' + p[2] + '">' + p[1] + '</span>' + p[0] + '</td>' +
      '<td style="color:var(--muted)">' + o[3] + '</td>' +
      '<td style="font-weight:600">' + o[4] + '</td>' +
      '<td><span class="pill ' + pill + '">' + pill.charAt(0).toUpperCase() + pill.slice(1) + '</span></td>' +
    '</tr>';
  }).join("");
}
renderOrders();

/* Add sample row */
document.getElementById("addRowBtn").addEventListener("click", () => {
  const n = orders.length ? parseInt(orders[0][0].slice(1)) + 1 : 10245;
  orders.unshift([
    "#" + n,
    "New Customer",
    Math.floor(Math.random() * products.length),
    "Nov 19, 2026",
    "$" + (Math.random() * 900 + 50).toFixed(2),
    statuses[Math.floor(Math.random() * statuses.length)]
  ]);
  if (orders.length > 8) orders.pop();
  renderOrders();
});

/* Search filter on table */
document.getElementById("searchInput").addEventListener("input", e => {
  const q = e.target.value.toLowerCase();
  document.querySelectorAll("#ordersBody tr").forEach(tr => {
    tr.style.display = tr.textContent.toLowerCase().includes(q) ? "" : "none";
  });
});