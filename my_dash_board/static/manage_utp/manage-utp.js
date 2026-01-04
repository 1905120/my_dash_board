// DOM Elements
const themeToggleBtn = document.getElementById('themeToggleBtn');
const valueSelect = document.getElementById('valueSelect');
const utpInput = document.getElementById('utpInput');
const operationSelect = document.getElementById('operationSelect');
const submitBtn = document.getElementById('submitBtn');
const resultSection = document.getElementById('resultSection');
const resultOutput = document.getElementById('resultOutput');
const loadingOverlay = document.getElementById('loadingOverlay');

// Deployment popup elements
const deploymentPopup = document.getElementById('deploymentPopup');
const deploymentOptions = document.getElementById('deploymentOptions');
const cancelDeploymentBtn = document.getElementById('cancelDeploymentBtn');
const selectedDeploymentDiv = document.getElementById('selectedDeployment');
const deploymentNameSpan = document.getElementById('deploymentName');
const changeDeploymentBtn = document.getElementById('changeDeploymentBtn');

// State
let selectedDeployment = null;
let deploymentData = null;

// Loading overlay functions
function showLoading() {
  loadingOverlay.classList.remove('hidden');
  setTimeout(() => loadingOverlay.classList.add('show'), 10);
}

function hideLoading() {
  loadingOverlay.classList.remove('show');
  setTimeout(() => loadingOverlay.classList.add('hidden'), 300);
}

// Initialize
async function init() {
  initTheme();
  await loadOptions();
  await loadDeploymentOptions();
  setupEventListeners();
}

// Theme toggle
function initTheme() {
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme === 'dark') {
    document.body.classList.add('dark-theme');
    themeToggleBtn.textContent = '☀️';
  }
}

themeToggleBtn.addEventListener('click', () => {
  document.body.classList.toggle('dark-theme');
  const isDark = document.body.classList.contains('dark-theme');
  themeToggleBtn.textContent = isDark ? '☀️' : '🌙';
  localStorage.setItem('theme', isDark ? 'dark' : 'light');
});

// Load options from API
async function loadOptions() {
  try {
    const response = await fetch('/api/manage-utp/options');
    const data = await response.json();
    
    if (response.ok) {
      if (data.operations) {
        populateOperations(data.operations);
      }
      if (data.values) {
        populateValues(data.values);
      }
    } else {
      showToast('Failed to load options', 'error');
    }
  } catch (err) {
    console.error('Error loading options:', err);
    showToast('Error loading options', 'error');
  }
}

// Load deployment options from JSON
async function loadDeploymentOptions() {
  try {
    const response = await fetch('/static/manage_utp/manage_deploy.json');
    deploymentData = await response.json();
  } catch (err) {
    console.error('Error loading deployment options:', err);
  }
}

// Populate operations dropdown
function populateOperations(operations) {
  operationSelect.innerHTML = '<option value="">-- Select an Operation --</option>';
  operations.forEach(op => {
    const option = document.createElement('option');
    option.value = op.value;
    option.textContent = `${op.value}. ${op.label}`;
    operationSelect.appendChild(option);
  });
}

// Populate values dropdown
function populateValues(values) {
  valueSelect.innerHTML = '<option value="">-- Select or type below --</option>';
  values.forEach(val => {
    const option = document.createElement('option');
    option.value = val.value;
    option.textContent = val.label;
    valueSelect.appendChild(option);
  });
}

// Setup event listeners
function setupEventListeners() {
  // When dropdown value changes, update the text input
  valueSelect.addEventListener('change', () => {
    if (valueSelect.value) {
      utpInput.value = valueSelect.value;
    }
    updateSubmitState();
  });
  
  // When text input changes, clear dropdown selection if different
  utpInput.addEventListener('input', () => {
    if (utpInput.value !== valueSelect.value) {
      valueSelect.value = '';
    }
    updateSubmitState();
  });
  
  // When operation changes, check if it's "Manage Deployments"
  operationSelect.addEventListener('change', () => {
    if (operationSelect.value === '6') {
      // Show deployment popup
      showDeploymentPopup();
    } else {
      // Hide deployment selection
      selectedDeploymentDiv.classList.add('hidden');
      selectedDeployment = null;
    }
    updateSubmitState();
  });
  
  // Cancel deployment popup
  cancelDeploymentBtn.addEventListener('click', () => {
    hideDeploymentPopup();
    // Reset operation if no deployment selected
    if (!selectedDeployment) {
      operationSelect.value = '';
    }
  });
  
  // Change deployment button
  changeDeploymentBtn.addEventListener('click', () => {
    showDeploymentPopup();
  });
  
  submitBtn.addEventListener('click', handleSubmit);
}

// Show deployment popup
function showDeploymentPopup() {
  if (!deploymentData || !deploymentData.deployments) {
    showToast('Deployment options not loaded', 'error');
    return;
  }
  
  // Populate deployment options
  deploymentOptions.innerHTML = '';
  deploymentData.deployments.forEach(dep => {
    const optionDiv = document.createElement('div');
    optionDiv.className = 'deployment-option';
    optionDiv.innerHTML = `
      <div class="option-name">${dep.name}</div>
      <div class="option-desc">${dep.description}</div>
    `;
    optionDiv.addEventListener('click', () => {
      selectDeployment(dep);
    });
    deploymentOptions.appendChild(optionDiv);
  });
  
  // Show popup
  deploymentPopup.classList.remove('hidden');
  setTimeout(() => deploymentPopup.classList.add('show'), 10);
}

// Hide deployment popup
function hideDeploymentPopup() {
  deploymentPopup.classList.remove('show');
  setTimeout(() => deploymentPopup.classList.add('hidden'), 300);
}

// Select a deployment option
function selectDeployment(deployment) {
  selectedDeployment = deployment;
  deploymentNameSpan.textContent = deployment.name;
  selectedDeploymentDiv.classList.remove('hidden');
  hideDeploymentPopup();
  updateSubmitState();
}

// Get the current value (from input or dropdown)
function getCurrentValue() {
  return utpInput.value.trim() || valueSelect.value;
}

// Update submit button state
function updateSubmitState() {
  const hasValue = getCurrentValue();
  const hasOperation = operationSelect.value;
  
  // For "Manage Deployments", also need a deployment selected
  if (operationSelect.value === '6') {
    submitBtn.disabled = !(hasValue && hasOperation && selectedDeployment);
  } else {
    submitBtn.disabled = !(hasValue && hasOperation);
  }
}

// Handle submit
async function handleSubmit() {
  const inputValue = getCurrentValue();
  const operation = operationSelect.value;
  
  if (!inputValue) {
    showToast('Please enter or select a value', 'warning');
    return;
  }

  if (!operation) {
    showToast('Please select an operation', 'warning');
    return;
  }

  // For Manage Deployments, check if deployment is selected
  if (operation === '6' && !selectedDeployment) {
    showToast('Please select a deployment option', 'warning');
    return;
  }

  // Show loading overlay
  showLoading();
  submitBtn.disabled = true;

  try {
    const payload = {
      value: inputValue,
      operation: operation
    };
    
    // Add deployment info if Manage Deployments is selected
    if (operation === '6' && selectedDeployment) {
      payload.deployment = {
        id: selectedDeployment.id,
        name: selectedDeployment.name
      };
    }

    const response = await fetch('/api/manage-utp/execute', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    const data = await response.json();

    // Hide loading overlay
    hideLoading();

    if (response.ok) {
      showToast('Operation executed successfully!', 'success');
      resultSection.classList.remove('hidden');
      resultOutput.textContent = data.result || JSON.stringify(data, null, 2);
    } else {
      showToast(data.message || 'Operation failed', 'error');
    }
  } catch (err) {
    console.error('Error:', err);
    hideLoading();
    showToast('Error executing operation', 'error');
  } finally {
    submitBtn.disabled = false;
    updateSubmitState();
  }
}

// Toast notification
function showToast(message, type = 'info') {
  const existingToast = document.querySelector('.toast-notification');
  if (existingToast) existingToast.remove();

  const toast = document.createElement('div');
  toast.className = `toast-notification toast-${type}`;
  
  const icons = { success: '✓', error: '✕', warning: '⚠', info: 'ℹ' };
  
  toast.innerHTML = `
    <span class="toast-icon">${icons[type] || icons.info}</span>
    <span class="toast-message">${message}</span>
    <button class="toast-close" onclick="this.parentElement.remove()">×</button>
  `;
  
  if (!document.querySelector('#toast-styles')) {
    const style = document.createElement('style');
    style.id = 'toast-styles';
    style.textContent = `
      .toast-notification { position: fixed; top: 20px; right: 20px; min-width: 300px; padding: 16px 20px;
        border-radius: 12px; display: flex; align-items: center; gap: 12px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.2); z-index: 9999;
        transform: translateX(120%); opacity: 0; transition: all 0.4s ease; }
      .toast-notification.show { transform: translateX(0); opacity: 1; }
      .toast-icon { width: 28px; height: 28px; border-radius: 50%; display: flex;
        align-items: center; justify-content: center; font-size: 14px; font-weight: bold; }
      .toast-message { flex: 1; font-size: 14px; font-weight: 500; }
      .toast-close { background: none; border: none; font-size: 20px; cursor: pointer; opacity: 0.6; }
      .toast-success { background: linear-gradient(135deg, #d1fae5, #a7f3d0); border: 1px solid #34d399; color: #065f46; }
      .toast-success .toast-icon { background: #10b981; color: white; }
      .toast-error { background: linear-gradient(135deg, #fee2e2, #fecaca); border: 1px solid #f87171; color: #991b1b; }
      .toast-error .toast-icon { background: #ef4444; color: white; }
      .toast-warning { background: linear-gradient(135deg, #fef3c7, #fde68a); border: 1px solid #fbbf24; color: #92400e; }
      .toast-warning .toast-icon { background: #f59e0b; color: white; }
    `;
    document.head.appendChild(style);
  }
  
  document.body.appendChild(toast);
  setTimeout(() => toast.classList.add('show'), 10);
  setTimeout(() => { toast.classList.remove('show'); setTimeout(() => toast.remove(), 300); }, 4000);
}

// Initialize on load
init();
