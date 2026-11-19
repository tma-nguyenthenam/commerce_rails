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

/* Search filter on table */
document.getElementById("searchInput").addEventListener("input", e => {
  const q = e.target.value.toLowerCase();
  document.querySelectorAll("#ordersBody tr").forEach(tr => {
    tr.style.display = tr.textContent.toLowerCase().includes(q) ? "" : "none";
  });
});