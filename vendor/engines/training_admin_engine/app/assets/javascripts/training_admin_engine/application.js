/* ----- Sidebar collapse / expand ----- */
const sidebar = document.getElementById("sidebar");
document.getElementById("collapseBtn").addEventListener("click", () => {
  sidebar.classList.toggle("collapsed");
});

/* Nav active state */
const navItems = document.querySelectorAll(".nav-item");

function updateActiveNavItem() {
  const currentUrl = new URL(window.location.href);

  navItems.forEach(item => {
    const href = item.dataset.href;
    const isActive =
      href && new URL(href, window.location.href).pathname === currentUrl.pathname;

    item.classList.toggle("active", Boolean(isActive));
  });
}

navItems.forEach(item => {
  item.addEventListener("click", () => {
    const href = item.dataset.href;

    if (href) {
      window.location.href = href;
    }
  });
});

updateActiveNavItem();


/* Search filter on table */
document.getElementById("searchInput").addEventListener("input", e => {
  const q = e.target.value.toLowerCase();
  document.querySelectorAll("#ordersBody tr").forEach(tr => {
    tr.style.display = tr.textContent.toLowerCase().includes(q) ? "" : "none";
  });
});

function getTotalOrders() {
  const url = document.getElementById('api_v1_dashboard_api_total_orders_by_month_path')?.value;
  fetch(url)
    .then(r => r.json())
    .then(({ total_orders }) => {
      document.getElementById("total_order").textContent = total_orders;
    })
}

getTotalOrders();
