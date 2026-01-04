const sidebar = document.getElementById("sidebar");
const menuToggle = document.getElementById("menuToggle");
const sideNav = document.getElementById("sideNav");
const defectBody = document.getElementById("defectBody");
const defectDetails = document.getElementById("defectDetails");
const themeToggleBtn = document.getElementById("themeToggleBtn");
const viewSelector = document.getElementById("viewSelector");

let openDetailRow = null;
let openMainRow = null;
let allDefectsData = null;

// ===============================
// Toast Notification System
// ===============================
function showToast(message, type = 'info') {
  // Remove existing toast if any
  const existingToast = document.querySelector('.toast-notification');
  if (existingToast) {
    existingToast.remove();
  }

  const toast = document.createElement('div');
  toast.className = `toast-notification toast-${type}`;
  
  const icons = {
    success: '✓',
    error: '✕',
    warning: '⚠',
    info: 'ℹ'
  };
  
  toast.innerHTML = `
    <span class="toast-icon">${icons[type] || icons.info}</span>
    <span class="toast-message">${message}</span>
    <button class="toast-close" onclick="this.parentElement.remove()">×</button>
  `;
  
  document.body.appendChild(toast);
  
  // Trigger animation
  setTimeout(() => toast.classList.add('show'), 10);
  
  // Auto remove after 4 seconds
  setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// ===============================
// Hover Tooltip for Action Buttons
// ===============================
function setupHoverTooltips(container) {
  const tooltipButtons = container.querySelectorAll('.hover-tooltip');
  
  tooltipButtons.forEach(btn => {
    let hoverTimeout;
    let tooltip;
    
    btn.addEventListener('mouseenter', () => {
      // Get the link from the detail-key's name attribute
      const detailRow = btn.closest('.detail-row');
      const detailKey = detailRow ? detailRow.querySelector('.detail-key') : null;
      const path = detailKey ? detailKey.getAttribute('name') : '';
      
      if (!path || path === '' || path === 'undefined') return;
      
      hoverTimeout = setTimeout(() => {
        // Create tooltip
        tooltip = document.createElement('div');
        tooltip.className = 'path-tooltip';
        
        // Create clickable link
        const link = document.createElement('a');
        link.href = path;
        link.textContent = path;
        link.target = '_blank';
        link.onclick = (e) => {
          e.stopPropagation();
        };
        
        tooltip.appendChild(link);
        document.body.appendChild(tooltip);
        
        // Position tooltip
        const rect = btn.getBoundingClientRect();
        tooltip.style.left = `${rect.left}px`;
        tooltip.style.top = `${rect.bottom + 8}px`;
        
        // Trigger animation
        setTimeout(() => tooltip.classList.add('show'), 10);
      }, 2000); // 2 seconds delay
    });
    
    btn.addEventListener('mouseleave', () => {
      clearTimeout(hoverTimeout);
      if (tooltip) {
        tooltip.classList.remove('show');
        setTimeout(() => {
          if (tooltip && tooltip.parentElement) {
            tooltip.remove();
          }
        }, 200);
        tooltip = null;
      }
    });
  });
}

// Toggle sidebar
if (menuToggle) {
  menuToggle.onclick = () => {
    sidebar.classList.toggle("active");
  };
}

// Theme toggle
function initTheme() {
  const savedTheme = localStorage.getItem("theme");
  if (savedTheme === "dark") {
    document.body.classList.add("dark-theme");
    if (themeToggleBtn) themeToggleBtn.textContent = "☀️";
  }
}

if (themeToggleBtn) {
  themeToggleBtn.onclick = () => {
    document.body.classList.toggle("dark-theme");
    const isDark = document.body.classList.contains("dark-theme");
    themeToggleBtn.textContent = isDark ? "☀️" : "🌙";
    localStorage.setItem("theme", isDark ? "dark" : "light");
  };
}

initTheme();


  function openLog(path) {
    console.log("Opening log:", path);
    if (!path || path === 'undefined' || path === '') {
      showToast("No log path configured", "warning");
      return;
    }
    fetch('/open-file', {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({path})
    }).then(res => {
      if (!res.ok) {
        showToast("Failed to open file", "error");
      }
    }).catch(err => {
      showToast("Error opening file", "error");
    });
  }

  function openDir(path) {
    console.log("Opening dir:", path);
    if (!path || path === 'undefined' || path === '') {
      showToast("No directory path configured", "warning");
      return;
    }
    fetch('/open-dir', {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({path})
    }).then(res => {
      if (!res.ok) {
        showToast("Failed to open directory", "error");
      }
    }).catch(err => {
      showToast("Error opening directory", "error");
    });
  }


function toggleDetails(mainRow, defectId, defect) {
  if (openMainRow === mainRow) {
    openDetailRow.remove();
    openDetailRow = null;
    openMainRow = null;
    return;
  }

  if (openDetailRow) {
    openDetailRow.remove();
    openDetailRow = null;
    openMainRow = null;
  }

  const detailRow = document.createElement("tr");
  detailRow.classList.add("detail-row");

  const detailCell = document.createElement("td");
  detailCell.colSpan = 4;

  detailCell.innerHTML = `
    <div class="detail-container">
      <div class="detail-header" style="display:flex; justify-content:space-between; align-items:center;">
        <h4>Defect Details</h4>
        <button class="edit-btn" style="background-color:red; color:white;">Edit</button>
        <div class="action-buttons" style="display:none; gap:10px; margin-top:10px;">
        <button class="save-btn">Save</button>
        <button class="cancel-btn">Cancel</button>
      </div>
      </div>
      
      <!-- Grid layout for compact fields -->
      <div class="detail-grid">
        <div class="detail-row"><div class="detail-key" name="CD_id">Defect ID</div><div class="detail-value">${defectId}</div></div>
        <div class="detail-row"><div class="detail-key" name="client_name">Client Name</div><div class="detail-value">${defect[defectId].client_name || ""}</div></div>
        <div class="detail-row"><div class="detail-key" name="status">Status</div><div class="detail-value">${defect[defectId].status || ""}</div></div>
        <div class="detail-row"><div class="detail-key" name="resource_dir">Resource Dir</div><div class="detail-value"><button class="action-btn folder-btn hover-tooltip" onclick="openDir('${defect[defectId].resource_dir}')">📁 Open Folder</button></div></div>
        <div class="detail-row"><div class="detail-key" name="log">Log</div><div class="detail-value"><button class="action-btn log-btn hover-tooltip" onclick="openLog('${defect[defectId].log}')">📄 View Log</button></div></div>
        <div class="detail-row"><div class="detail-key" name="ira_link">Look in Jira</div><div class="detail-value"><button class="action-btn jira-btn hover-tooltip" onclick="window.open('${defect[defectId].jira_link}', '_blank')">🔗 Open Jira</button></div></div>
        <div class="detail-row"><div class="detail-key" name="time_spent">Time Spent</div><div class="detail-value">${defect[defectId].time_spent || ""}</div></div>
        <div class="detail-row"><div class="detail-key" name="release">Release</div><div class="detail-value">${defect[defectId].release || ""}</div></div>
      </div>
      
      <!-- Full width rows for editable fields -->
      <div class="detail-table">
        <div class="detail-row full-width"><div class="detail-key" name="comments">Comments</div><div class="detail-value">${defect[defectId].comments || ""}</div></div>
        <div class="detail-row full-width"><div class="detail-key" name="today_plan">Today Plan</div><div class="detail-value">${defect[defectId].today_plan || ""}</div></div>
        <div class="detail-row full-width"><div class="detail-key" name="missed_plan">Missed Plan</div><div class="detail-value">${defect[defectId].missed_plan || ""}</div></div>
      </div>
      
    </div>
  `;
console.log(detailCell.innerHTML)
function updateValue(el) {
  
  const row = el.closest(".detail-row");
  const keyEl = row.querySelector(".detail-key");

  const key = keyEl.getAttribute("name");
  const value = el.innerText;

  // 🔁 Update existing innerHTML (no replacement)
  el.innerHTML = value;

  console.log("Updated:", key, value);
}
  detailRow.appendChild(detailCell);
  mainRow.after(detailRow);

  openDetailRow = detailRow;
  openMainRow = mainRow;

  // Event listeners
  const editBtn = detailCell.querySelector(".edit-btn");
  const edit_saveBtn = detailCell.querySelector(".save-btn");
  const edit_cancelBtn = detailCell.querySelector(".cancel-btn");

  editBtn.addEventListener("click", () => {
  editBtn.style.display = "none";
  detailCell.querySelector(".action-buttons").style.display = "flex";

  const rows = detailCell.querySelectorAll(".detail-row");
  rows.forEach(row => {
    const key = row.querySelector(".detail-key").textContent.trim();
    const valueDiv = row.querySelector(".detail-value");

    if (key === "Defect ID" || key === "Look in Jira") {
      // Keep read-only
      return;
    } else if (key === "Status") {
      const select = document.createElement("select");
      ["analysis","coding","code review","testing","regression","secondary","rejected", "completed"].forEach(opt => {
        const option = document.createElement("option");
        option.value = opt;
        option.textContent = opt;
        if (opt.toLowerCase() === valueDiv.textContent.toLowerCase()) option.selected = true;
        select.appendChild(option);
      });
      select.dataset.originalValue = valueDiv.textContent;
      valueDiv.replaceWith(select);
    } else if (key === "Resource Dir") {
      const button = valueDiv.querySelector(".resource-btn");
      button.disabled = false;
    } else {
      // Make editable for all other fields including Client Name and Log
      if (key != "Client Name" && key != "Log") {
      const input = document.createElement("input");
      input.type = "text";
      input.value = valueDiv.textContent;
      input.classList.add("edit-input");
      input.dataset.originalValue = valueDiv.textContent;
      valueDiv.replaceWith(input);
      }
      
    }
  });
});


  edit_cancelBtn.addEventListener("click", () => {
    const rows = detailCell.querySelectorAll(".detail-row");
    rows.forEach(row => {
      const key = row.querySelector(".detail-key").textContent.trim();
      const valueDiv = row.querySelector(".edit-input") || row.querySelector("select") || row.querySelector(".detail-value");
      if (!valueDiv) return;

      if (key === "Status" && valueDiv.tagName === "SELECT") {
        const span = document.createElement("div");
        span.classList.add("detail-value");
        span.textContent = valueDiv.dataset.originalValue;
        valueDiv.replaceWith(span);
      } else if (key === "Resource Dir") {
        const button = row.querySelector(".resource-btn");
        button.disabled = false;
      } else if (key !== "Defect ID" && valueDiv.tagName === "INPUT") {
        const span = document.createElement("div");
        span.classList.add("detail-value");
        span.textContent = valueDiv.dataset.originalValue || valueDiv.value;
        valueDiv.replaceWith(span);
      }
    });

    editBtn.style.display = "block";
    detailCell.querySelector(".action-buttons").style.display = "none";
  });

  edit_saveBtn.addEventListener("click", async function (e)  {
    const container = e.target.closest(".detail-container");
    const dataArray = {};
    const edit_defect_details = {}
    let edited_defect_id = "defect_id"
    container.querySelectorAll(".detail-row").forEach(row => {
      const keyEl = row.querySelector(".detail-key");
      const key = keyEl.getAttribute("name");

      // Get value from input, select, or detail-value (whichever exists)
      let value = "";
      const inputEl = row.querySelector(".edit-input");
      const selectEl = row.querySelector("select");
      const valueEl = row.querySelector(".detail-value");

      if (inputEl) {
        value = inputEl.value.trim();
      } else if (selectEl) {
        value = selectEl.value.trim();
      } else if (valueEl) {
        // For fields with links, extract the href instead of text
        const linkEl = valueEl.querySelector("a");
        if (linkEl && (key === "resource_dir" || key === "log" || key === "jira_link")) {
          if (key === "jira_link") {
            value = linkEl.getAttribute("href") || "";
          } else {
            // For resource_dir and log, extract path from onclick attribute
            const onclickAttr = linkEl.getAttribute("onclick") || "";
            const match = onclickAttr.match(/'([^']+)'/);
            value = match ? match[1] : "";
          }
        } else {
          value = valueEl.innerText.trim();
        }
      }

      if (value === undefined || value === "undefined") {
        value = "";
      }

      if (key && key != "CD_id") {
        edit_defect_details[key] = value;
      } else if (key == "CD_id") {
        edited_defect_id = value;
      }
    });
      
      dataArray[edited_defect_id] = edit_defect_details;
      console.log(dataArray);
    try {
      const res = await fetch("/api/cdm/edit_defect", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({viewType : viewSelector.value, updatedDefects : dataArray})
      });

      if (res.ok) {
        showToast("Defect updated successfully!", "success");
        openDetailRow.remove();
        openDetailRow = null;
        openMainRow = null;
        fetchDefects(viewSelector.value);
      } else {
        showToast("Failed to update defect.", "error");
      }
    } catch(err) {
      console.error(err);
      showToast("Error updating defect.", "error");
    }
  });
}









// Fetch defects from server
async function fetchDefects(viewType) {
  try {
    const res = await fetch(`/api/defects?type=${viewType}`);
    const data = await res.json();
    renderDefects(data.data);
  } catch (err) {
    console.error("Failed to fetch defects:", err);
  }
}

// Toggle expand/collapse for a single row
function toggleRowExpand(mainRow, defectId, defects, expandBtn) {
  const nextRow = mainRow.nextElementSibling;
  
  // If already expanded, collapse it with animation
  if (nextRow && nextRow.classList.contains("detail-row")) {
    nextRow.classList.add("collapsing");
    expandBtn.textContent = "Expand";
    expandBtn.classList.remove("expanded");
    setTimeout(() => {
      nextRow.remove();
    }, 280);
    return;
  }
  
  // Close any other expanded row first with animation
  const existingDetailRow = document.querySelector("tr.detail-row");
  if (existingDetailRow) {
    // Find the expand button of the previously expanded row and reset it
    const prevMainRow = existingDetailRow.previousElementSibling;
    if (prevMainRow) {
      const prevExpandBtn = prevMainRow.querySelector(".expand-btn");
      if (prevExpandBtn) {
        prevExpandBtn.textContent = "Expand";
        prevExpandBtn.classList.remove("expanded");
      }
    }
    existingDetailRow.classList.add("collapsing");
    setTimeout(() => {
      existingDetailRow.remove();
    }, 280);
  }
  
  // Expand the row
  const detailRow = document.createElement("tr");
  detailRow.classList.add("detail-row");

  const detailCell = document.createElement("td");
  detailCell.colSpan = 4;

  detailCell.innerHTML = `
    <div class="detail-container">
      <div class="detail-header" style="display:flex; justify-content:space-between; align-items:center;">
        <h4>Defect Details</h4>
        <button class="edit-btn" style="background-color:red; color:white;">Edit</button>
        <div class="action-buttons" style="display:none; gap:10px; margin-top:10px;">
          <button class="save-btn">Save</button>
          <button class="cancel-btn">Cancel</button>
        </div>
      </div>
      <div class="detail-grid">
        <div class="detail-row"><div class="detail-key" name="CD_id">Defect ID</div><div class="detail-value">${defectId}</div></div>
        <div class="detail-row"><div class="detail-key" name="client_name">Client Name</div><div class="detail-value">${defects[defectId].client_name || ""}</div></div>
        <div class="detail-row"><div class="detail-key" name="status">Status</div><div class="detail-value">${defects[defectId].status || ""}</div></div>
        <div class="detail-row"><div class="detail-key" name="resource_dir">Resource Dir</div><div class="detail-value"><button class="action-btn folder-btn hover-tooltip" onclick="openDir('${defects[defectId].resource_dir}')">📁 Open Folder</button></div></div>
        <div class="detail-row"><div class="detail-key" name="log">Log</div><div class="detail-value"><button class="action-btn log-btn hover-tooltip" onclick="openLog('${defects[defectId].log}')">📄 View Log</button></div></div>
        <div class="detail-row"><div class="detail-key" name="jira_link">Look in Jira</div><div class="detail-value"><button class="action-btn jira-btn hover-tooltip" onclick="window.open('${defects[defectId].jira_link}', '_blank')">🔗 Open Jira</button></div></div>
        <div class="detail-row"><div class="detail-key" name="time_spent">Time Spent</div><div class="detail-value">${defects[defectId].time_spent || ""}</div></div>
        <div class="detail-row"><div class="detail-key" name="release">Release</div><div class="detail-value">${defects[defectId].release || ""}</div></div>
      </div>
      <div class="detail-table">
        <div class="detail-row full-width"><div class="detail-key" name="comments">Comments</div><div class="detail-value">${defects[defectId].comments || ""}</div></div>
        <div class="detail-row full-width"><div class="detail-key" name="today_plan">Today Plan</div><div class="detail-value">${defects[defectId].today_plan || ""}</div></div>
        <div class="detail-row full-width"><div class="detail-key" name="missed_plan">Missed Plan</div><div class="detail-value">${defects[defectId].missed_plan || ""}</div></div>
      </div>
    </div>
  `;
  console.log(detailCell)
  detailRow.appendChild(detailCell);
  mainRow.after(detailRow);
  expandBtn.textContent = "Collapse";
  expandBtn.classList.add("expanded");
  
  // Setup hover tooltips for action buttons
  setupHoverTooltips(detailCell);
  
  // Add edit functionality
  setupEditHandlers(detailCell, defectId, defects);
}

// Setup edit button handlers for a detail cell
function setupEditHandlers(detailCell, defectId, defects) {
  const editBtn = detailCell.querySelector(".edit-btn");
  const edit_saveBtn = detailCell.querySelector(".save-btn");
  const edit_cancelBtn = detailCell.querySelector(".cancel-btn");

  editBtn.addEventListener("click", () => {
    editBtn.style.display = "none";
    detailCell.querySelector(".action-buttons").style.display = "flex";

    // Handle grid fields (Status)
    const gridRows = detailCell.querySelectorAll(".detail-grid .detail-row");
    gridRows.forEach(row => {
      const keyEl = row.querySelector(".detail-key");
      const key = keyEl ? keyEl.textContent.trim() : "";
      const valueDiv = row.querySelector(".detail-value");
      if (!valueDiv) return;

      if (key === "Status") {
        const select = document.createElement("select");
        ["new","analysis","coding","code review","testing","regression","secondary","rejected"].forEach(opt => {
          const option = document.createElement("option");
          option.value = opt;
          option.textContent = opt;
          if (opt.toLowerCase() === valueDiv.textContent.toLowerCase()) option.selected = true;
          select.appendChild(option);
        });
        select.dataset.originalValue = valueDiv.textContent;
        valueDiv.replaceWith(select);
      }
    });

    // Handle table fields (Comments, Today Plan, Missed Plan)
    const rows = detailCell.querySelectorAll(".detail-table .detail-row");
    rows.forEach(row => {
      const key = row.querySelector(".detail-key").textContent.trim();
      const valueDiv = row.querySelector(".detail-value");

      if (key === "Defect ID" || key === "Look in Jira") {
        return;
      } else if (key !== "Client Name" && key !== "Log" && key !== "Resource Dir") {
        const input = document.createElement("input");
        input.type = "text";
        input.value = valueDiv.textContent;
        input.classList.add("edit-input");
        input.dataset.originalValue = valueDiv.textContent;
        valueDiv.replaceWith(input);
      }
    });
  });

  edit_cancelBtn.addEventListener("click", () => {
    // Restore grid fields
    const gridRows = detailCell.querySelectorAll(".detail-grid .detail-row");
    gridRows.forEach(row => {
      const keyEl = row.querySelector(".detail-key");
      const key = keyEl ? keyEl.textContent.trim() : "";
      const selectEl = row.querySelector("select");
      
      if (key === "Status" && selectEl) {
        const span = document.createElement("div");
        span.classList.add("detail-value");
        span.textContent = selectEl.dataset.originalValue;
        selectEl.replaceWith(span);
      }
    });

    // Restore table fields
    const rows = detailCell.querySelectorAll(".detail-table .detail-row");
    rows.forEach(row => {
      const key = row.querySelector(".detail-key").textContent.trim();
      const valueDiv = row.querySelector(".edit-input") || row.querySelector(".detail-value");
      if (!valueDiv) return;

      if (valueDiv.tagName === "INPUT") {
        const span = document.createElement("div");
        span.classList.add("detail-value");
        span.textContent = valueDiv.dataset.originalValue || valueDiv.value;
        valueDiv.replaceWith(span);
      }
    });

    editBtn.style.display = "block";
    detailCell.querySelector(".action-buttons").style.display = "none";
  });

  edit_saveBtn.addEventListener("click", async function (e) {
    const container = e.target.closest(".detail-container");

    const dataArray = {};
    const edit_defect_details = {};
    let edited_defect_id = defectId;
    
    // Get values from grid
    container.querySelectorAll(".detail-grid .detail-row").forEach(row => {
      const keyEl = row.querySelector(".detail-key");
      const key = keyEl.getAttribute("name");
      let value = "";
      const valueEl = row.querySelector(".detail-value");
      const selectEl = row.querySelector("select");

      if (selectEl) {
        value = selectEl.value.trim();
      } else if (valueEl) {
        const linkEl = valueEl.querySelector("a");
        const btnEl = valueEl.querySelector(".action-btn");
        if (btnEl && (key === "resource_dir" || key === "log" || key === "jira_link")) {
          const onclickAttr = btnEl.getAttribute("onclick") || "";
          if (key === "jira_link") {
            const match = onclickAttr.match(/'([^']+)'/);
            value = match ? match[1] : "";
          } else {
            const match = onclickAttr.match(/'([^']+)'/);
            value = match ? match[1] : "";
          }
        } else {
          value = valueEl.innerText.trim();
        }
      }

      if (value === undefined || value === "undefined") value = "";
      if (key && key != "CD_id") {
        edit_defect_details[key] = value;
      }
    });
    
    // Get values from table (editable fields)
    container.querySelectorAll(".detail-table .detail-row").forEach(row => {
      const keyEl = row.querySelector(".detail-key");
      const key = keyEl.getAttribute("name");
      let value = "";
      const inputEl = row.querySelector(".edit-input");
      const selectEl = row.querySelector("select");
      const valueEl = row.querySelector(".detail-value");

      if (inputEl) {
        value = inputEl.value.trim();
      } else if (selectEl) {
        value = selectEl.value.trim();
      } else if (valueEl) {
        value = valueEl.innerText.trim();
      }

      if (value === undefined || value === "undefined") value = "";
      if (key) {
        edit_defect_details[key] = value;
      }
    });

    dataArray[edited_defect_id] = edit_defect_details;
    
    try {
      const res = await fetch("/api/cdm/edit_defect", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({viewType: viewSelector.value, updatedDefects: dataArray})
      });

      if (res.ok) {
        showToast("Defect updated successfully!", "success");
        fetchDefects(viewSelector.value);
      } else {
        showToast("Failed to update defect.", "error");
      }
    } catch(err) {
      console.error(err);
      showToast("Error updating defect.", "error");
    }
  });
}

// Render table rows

function renderDefects(defects) {
  defectBody.innerHTML = "";
  openDetailRow = null;
  openMainRow = null;
  allDefectsData = defects;
  
  // Get amend button reference
  const amendBtn = document.getElementById("amendDefectBtn");
  
  // Check if defects exist and has at least one entry
  const hasDefects = defects && Object.keys(defects).length > 0;
  
  // Show/hide amend button based on defect count
  if (amendBtn) {
    if (hasDefects) {
      amendBtn.style.display = "";
    } else {
      amendBtn.style.display = "none";
    }
  }
  
  if (!defects){
    return;
  }

  let rowIndex = 0;
  for (const defectId in defects) {
  if (defects.hasOwnProperty(defectId)) {
    const trimmedId = defectId.trim();
    const status = defects[defectId].status || 'new';
    const statusClass = `status-${status.toLowerCase().replace(/\s+/g, '-')}`;
    const mainRow = document.createElement("tr");
    mainRow.classList.add("defect-row");
    mainRow.style.animation = `rowFadeIn 0.3s ease-out ${rowIndex * 0.05}s both`;

    mainRow.innerHTML = `
      <td class="row-select hidden">
        <input type="checkbox" class="row-checkbox" data-id="${trimmedId}">
      </td>
      <td class="defect-id-cell">
        <span class="defect-id-badge">${trimmedId}</span>
      </td>
      <td>
        <span class="status-badge ${statusClass}">${status}</span>
      </td>
      <td class="col-action-cell">
        <button class="expand-btn" title="Expand">Expand</button>
      </td>
    `;
    
    // Add click handler for expand button
    const expandBtn = mainRow.querySelector(".expand-btn");
    expandBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      toggleRowExpand(mainRow, trimmedId, defects, expandBtn);
    });
    
    defectBody.appendChild(mainRow);
    rowIndex++;

  }
}

  // defects.forEach(defect => {
  //   const mainRow = document.createElement("tr");
  //   mainRow.classList.add("defect-row");

  //   mainRow.innerHTML = `
  //     <td class="row-select hidden">
  //       <input type="checkbox" class="row-checkbox" data-id="${defect.id}">
  //     </td>
  //     <td>${defect.id}</td>
  //     <td>${defect.id.status}</td>
  //   `;

  //   mainRow.addEventListener("click", () => toggleDetails(mainRow, defect));
  //   defectBody.appendChild(mainRow);
  // });
}

// Toggle dropdown details for a row
// function toggleDetails(mainRow, defect) {
//   if (openMainRow === mainRow) {
//     openDetailRow.remove();
//     openDetailRow = null;
//     openMainRow = null;
//     return;
//   }

//   if (openDetailRow) {
//     openDetailRow.remove();
//     openDetailRow = null;
//     openMainRow = null;
//   }

//   const detailRow = document.createElement("tr");
//   detailRow.classList.add("detail-row");

//   const detailCell = document.createElement("td");
//   detailCell.colSpan = 2;

//   detailCell.innerHTML = `
//     <div class="detail-grid">
//       <div class="detail-item"><span>Client:</span> ${defect.client}</div>
//       <div class="detail-item"><span>Priority:</span> ${defect.priority}</div>
//       <div class="detail-item"><span>Description:</span> ${defect.description}</div>
//       <div class="detail-item"><span>Reported By:</span> ${defect.reportedBy}</div>
//       <div class="detail-item"><span>Created On:</span> ${defect.createdOn}</div>
//     </div>
//   `;

//   detailRow.appendChild(detailCell);
//   mainRow.after(detailRow);
//   openDetailRow = detailRow;
//   openMainRow = mainRow;
// }

// Update table on dropdown change
viewSelector.addEventListener("change", () => {
  fetchDefects(viewSelector.value);
});

// Initial load
fetchDefects(viewSelector.value);


const popup = document.getElementById("defectPopup");
const createBtn = document.getElementById("createDefectBtn");
const saveBtn = document.getElementById("saveDefectBtn");
const cancelBtn = document.getElementById("cancelDefectBtn");

// OPEN POPUP
createBtn.addEventListener("click", () => {
  popup.classList.remove("hidden");
  // Trigger reflow for animation
  popup.offsetHeight;
  popup.classList.add("show");
});

// CANCEL
cancelBtn.addEventListener("click", () => {
  popup.classList.remove("show");
  setTimeout(() => {
    popup.classList.add("hidden");
    clearForm();
  }, 300);
});

// SAVE → POST API
saveBtn.addEventListener("click", async () => {
  let defect_id = document.getElementById("cd_id").value;
  if (!defect_id){
    showToast("Defect Id is mandatory!", "warning");
    return
  }
  defect_id = defect_id.trim()
  const defect = {
  [defect_id]: {
    client_name: document.getElementById("client_name").value,
    status: document.getElementById("status").value,
    time_spent: document.getElementById("time_spent").value,
    release: document.getElementById("release").value,
    comments: document.getElementById("comments").value,
    today_plan: document.getElementById("today_plan").value,
    missed_plan: document.getElementById("missed_plan").value,
    // resource_dir: document.getElementById("resource_dir").value,
    // log: document.getElementById("log").value,
    // jira_link: document.getElementById("jira_link").value
  }
};
  console.log(defect);
  const res = await fetch("/api/Createdefects", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(defect)
  });

  if (res.ok) {
    showToast("Defect created successfully!", "success");
    popup.classList.remove("show");
    setTimeout(() => {
      popup.classList.add("hidden");
      clearForm();
      reloadDefectList();
    }, 300);
  } else {
    showToast("Failed to create defect", "error");
  }
});

function clearForm() {
  document.querySelectorAll("#defectPopup input").forEach(i => i.value = "");
}

function showRowCheckboxes() {
  document.querySelectorAll(".row-select").forEach(cell => {
    cell.classList.remove("hidden");
    cell.classList.add("visible");
  });
}
const amendDefectBtn = document.getElementById("amendDefectBtn");
const cancelAmendBtn = document.querySelector(".cancenlAmend");
const deleteDefectBtn = document.querySelector(".deleteDefectBtn");
const archiveDefectBtn = document.querySelector(".archiveDefectBtn");
const moveCurrentBtn = document.querySelector(".moveCurrentBtn");
const container = document.getElementById("defectListContainer");

amendDefectBtn.addEventListener("click", () => {

  // Collapse any expanded detail row first
  const expandedDetailRow = document.querySelector("tr.detail-row");
  if (expandedDetailRow) {
    const prevMainRow = expandedDetailRow.previousElementSibling;
    if (prevMainRow) {
      const prevExpandBtn = prevMainRow.querySelector(".expand-btn");
      if (prevExpandBtn) {
        prevExpandBtn.textContent = "Expand";
        prevExpandBtn.classList.remove("expanded");
      }
    }
    expandedDetailRow.classList.add("collapsing");
    setTimeout(() => {
      expandedDetailRow.remove();
    }, 280);
  }

  showRowCheckboxes();

  deleteDefectBtn.classList.remove("hidden");
  
  // Show Archive only when viewing Current, show Move Current only when viewing Archived
  if (viewSelector.value === "current") {
    archiveDefectBtn.classList.remove("hidden");
    moveCurrentBtn.classList.add("hidden");
  } else {
    archiveDefectBtn.classList.add("hidden");
    moveCurrentBtn.classList.remove("hidden");
  }
  
  cancelAmendBtn.classList.remove("hidden");
  amendDefectBtn.classList.add("hidden");
  createDefectBtn.classList.add("hidden");
  viewSelector.classList.add("hidden");
  
  // Hide expand buttons in amend mode
  document.querySelectorAll(".expand-btn").forEach(btn => btn.classList.add("hidden"));

});


cancelAmendBtn.addEventListener("click", () => {

  document.querySelectorAll(".row-select").forEach(cell => {
    cell.classList.add("hidden");
    cell.classList.remove("visible");
    deleteDefectBtn.classList.add("hidden");
    archiveDefectBtn.classList.add("hidden");
    moveCurrentBtn.classList.add("hidden");
    cancelAmendBtn.classList.add("hidden");
    amendDefectBtn.classList.remove("hidden");
    createDefectBtn.classList.remove("hidden");
    viewSelector.classList.remove("hidden");
  });
  
  // Show expand buttons again
  document.querySelectorAll(".expand-btn").forEach(btn => btn.classList.remove("hidden"));

});

archiveDefectBtn.addEventListener("click", async () => {
  const selectedIds = Array.from(document.querySelectorAll(".row-checkbox:checked")).map(cb => cb.dataset.id.trim());
  if (selectedIds.length === 0) {
    showToast("No defects selected for Archive", "warning");
    return;
  }

  const res = await fetch("/api/cdm/archive_defect", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ 
      viewType: viewSelector.value,
      ids: selectedIds 
    })
  });

  if (res.ok) {
    showToast("Defects archived successfully", "success");
  } else {
    showToast("Failed to archive defects", "error");
  }
  reloadDefectList();
});


moveCurrentBtn.addEventListener("click", async () => {
  const selectedIds = Array.from(document.querySelectorAll(".row-checkbox:checked")).map(cb => cb.dataset.id.trim());
  if (selectedIds.length === 0) {
    showToast("No defects selected to move", "warning");
    return;
  }

  const res = await fetch("/api/cdm/move_current", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ 
      viewType: viewSelector.value,
      ids: selectedIds 
    })
  });

  if (res.ok) {
    showToast("Defects moved to current successfully", "success");
  } else {
    showToast("Failed to move defects", "error");
  }
  reloadDefectList();
});


deleteDefectBtn.addEventListener("click", async () => {
  const selectedIds = Array.from(document.querySelectorAll(".row-checkbox:checked")).map(cb => cb.dataset.id.trim());

  if (selectedIds.length === 0) {
    showToast("No defects selected for deletion", "warning");
    return;
  }
  
  // Show confirmation dialog
  showDeleteConfirmDialog(selectedIds);
});

// Delete confirmation dialog
function showDeleteConfirmDialog(selectedIds) {
  // Remove existing dialog if any
  const existingDialog = document.getElementById('deleteConfirmDialog');
  if (existingDialog) existingDialog.remove();
  
  const dialog = document.createElement('div');
  dialog.id = 'deleteConfirmDialog';
  dialog.className = 'confirm-dialog-overlay';
  dialog.innerHTML = `
    <div class="confirm-dialog">
      <div class="confirm-dialog-icon">⚠️</div>
      <h3>Confirm Permanent Deletion</h3>
      <p class="confirm-dialog-warning">This action is <strong>irreversible</strong>!</p>
      <p>You are about to permanently delete <strong>${selectedIds.length}</strong> defect(s):</p>
      <ul class="confirm-dialog-list">
        ${selectedIds.map(id => `<li>${id}</li>`).join('')}
      </ul>
      <p class="confirm-dialog-note">Your files will be deleted permanently and cannot be recovered.</p>
      <div class="confirm-dialog-actions">
        <button class="confirm-dialog-cancel" onclick="closeDeleteConfirmDialog()">Cancel</button>
        <button class="confirm-dialog-delete" onclick="confirmDelete()">Delete Permanently</button>
      </div>
    </div>
  `;
  
  document.body.appendChild(dialog);
  
  // Store selected IDs for later use
  dialog.dataset.selectedIds = JSON.stringify(selectedIds);
  
  // Trigger animation
  setTimeout(() => dialog.classList.add('show'), 10);
}

function closeDeleteConfirmDialog() {
  const dialog = document.getElementById('deleteConfirmDialog');
  if (dialog) {
    dialog.classList.remove('show');
    setTimeout(() => dialog.remove(), 300);
  }
}

async function confirmDelete() {
  const dialog = document.getElementById('deleteConfirmDialog');
  const selectedIds = JSON.parse(dialog.dataset.selectedIds);
  
  closeDeleteConfirmDialog();
  
  const res = await fetch("/api/cdm/delete_defect", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ 
      viewType: viewSelector.value,
      ids: selectedIds 
    })
  });

  if (res.ok) {
    showToast("Defects deleted permanently", "success");
  } else {
    showToast("Failed to delete defects", "error");
  }
  reloadDefectList();
}

async function reloadDefectList() {


  window.location.reload();

  // alert("Defect list refreshed");
}
