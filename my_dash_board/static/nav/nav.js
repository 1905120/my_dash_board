// nav.js - Reusable Navigation Component

const navConfig = [
  { label: "Dashboard", link: "/" },
  { label: "CD Manager", link: "/CD_manager" },
  { label: "Generate Ofs", link: "/CreateOfs" },
  // { label: "LocalHost BWeb", link: "http://127.0.0.1:9089/BrowserWeb" },
  { label: "Jira", link: "/online-jira" },
  { label: "Manage UTP", link: "/manage-utp" }
];

// Initialize navigation - call this or it auto-runs on DOMContentLoaded
function initNavigation(logoText = "My Dashboard") {
  const navContainer = document.getElementById("nav-container");
  
  if (navContainer) {
    // Inject navigation HTML into the container
    navContainer.innerHTML = `
      <button class="menu-toggle" id="menuToggle">☰</button>
      <aside id="sidebar" class="sidebar">
        <h2 class="logo">${logoText}</h2>
        <nav id="sideNav"></nav>
      </aside>
    `;
  }

  const sideNav = document.getElementById("sideNav");
  const sidebar = document.getElementById("sidebar");
  const menuToggle = document.getElementById("menuToggle");

  if (!sideNav || !sidebar || !menuToggle) return;

  // Populate nav buttons
  navConfig.forEach(item => {
    const btn = document.createElement("button");
    btn.textContent = item.label;
    btn.onclick = () => window.location.href = item.link;
    sideNav.appendChild(btn);
  });

  // Toggle sidebar
  menuToggle.addEventListener("click", () => {
    sidebar.classList.toggle("active");
  });
}

// Auto-initialize when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  // Get logo text from data attribute if available
  const navContainer = document.getElementById("nav-container");
  const logoText = navContainer?.dataset?.logo || "My Dashboard";
  initNavigation(logoText);
});
