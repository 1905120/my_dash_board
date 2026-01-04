let propertyCount = 0;
        let fieldCounts = {};

        function toggleNoteField() {
            const container = document.getElementById('noteInputContainer');
            const icon = document.getElementById('noteIcon');
            if (container.style.display === 'none') {
                container.style.display = 'flex';
                icon.textContent = '📝';
            } else {
                container.style.display = 'none';
            }
        }

        function clearNote() {
            document.getElementById('note-input').value = '';
            document.getElementById('noteInputContainer').style.display = 'none';
        }

        function getNoteValue() {
            const noteInput = document.getElementById('note-input');
            return noteInput ? noteInput.value.trim() : '';
        }

        function populateSelect(selectId, options, placeholder) {
            const select = document.getElementById(selectId);
            select.innerHTML = `<option value="">${placeholder}</option>`;
            options.forEach(opt => {
                const option = document.createElement('option');
                option.value = opt.value;
                option.textContent = opt.label;
                select.appendChild(option);
            });
        }

        async function loadOptions() {
            try {
                const response = await fetch('/createOfs/api/options');
                const result = await response.json();
                const data = result.data || defaultOptions;
                applyOptions(data);
            } catch (error) {
                console.log('Using default options:', error.message);
                applyOptions(defaultOptions);
            }
        }

        function applyOptions(data) {
            populateSelect('table-select', data.applications, '-- Select Application --');
            populateSelect('arrangement-select', data.arrangements, '-- Select Arrangement --');
            populateSelect('product-select', data.products, '-- Select Product --');
            populateSelect('companyId-select', data.companies, '-- Select company Id --');
            populateSelect('currency-select', data.currencies, '-- Select Currency --');
            populateSelect('customer-select', data.customers, '-- Select Customer --');
            populateSelect('activity-select', data.activities, '-- Select Activity --');
        }

        document.addEventListener('DOMContentLoaded', loadOptions);

        function syncToInput(selectId, inputId) {
            const select = document.getElementById(selectId);
            const input = document.getElementById(inputId);
            input.value = select.value;
        }
 
       function onApplicationChange() {
            const select = document.getElementById('table-select');
            const input = document.getElementById('table-input');
            input.value = select.value;
            
            const appValue = select.value;
            const aaaFields = document.getElementById('aaa-fields');
            const propertiesSection = document.getElementById('properties-section');
            const propertiesContainer = document.getElementById('properties-container');
            const propertiesLabel = document.getElementById('properties-label');
            const addPropertyBtn = document.getElementById('add-property-btn');
            
            propertiesContainer.innerHTML = '';
            propertyCount = 0;
            fieldCounts = {};
            
            if (!appValue) {
                aaaFields.style.display = 'none';
                propertiesSection.style.display = 'none';
            } else if (appValue === 'AA.ARRANGEMENT.ACTIVITY') {
                aaaFields.style.display = 'block';
                propertiesSection.style.display = 'block';
                propertiesLabel.textContent = 'Properties';
                addPropertyBtn.textContent = '+ Add Property';
            } else {
                aaaFields.style.display = 'none';
                propertiesSection.style.display = 'block';
                propertiesLabel.textContent = 'Fields';
                addPropertyBtn.textContent = '+ Add Field';
            }
        }

        function getValue(selectId, inputId) {
            const input = document.getElementById(inputId);
            const select = document.getElementById(selectId);
            return input.value.trim() || select.value;
        }

        function isAAAApplication() {
            const appType = getValue('table-select', 'table-input');
            if (!appType) return true;
            return appType === 'AA.ARRANGEMENT.ACTIVITY' || appType === 'AAA';
        }

        function addProperty() {
            const appType = getValue('table-select', 'table-input');
            if (!appType) {
                alert('Please select an Application first');
                return;
            }
            
            propertyCount++;
            fieldCounts[propertyCount] = 0;
            const container = document.getElementById('properties-container');
            const block = document.createElement('div');
            block.className = 'property-block';
            block.id = `property-block-${propertyCount}`;
            
            const isAAA = isAAAApplication();
            
            if (isAAA) {
                block.innerHTML = `
                    <div class="property-header">
                        <select class="property-class" onchange="selectPropertyClass(${propertyCount})">
                            <option value="">-- Select Property Class --</option>
                        </select>
                        <input type="text" placeholder="Property Name" class="property-name" oninput="checkPropertyName(${propertyCount})">
                        <button type="button" class="btn btn-add-field" id="add-field-btn-${propertyCount}" onclick="addFieldToProperty(${propertyCount})" disabled style="opacity: 0.5; cursor: not-allowed;">+ Add Field</button>
                        <button type="button" class="btn btn-remove" onclick="removeProperty(${propertyCount})">✕</button>
                    </div>
                    <div class="property-fields" id="property-fields-${propertyCount}"></div>
                `;
                container.appendChild(block);
                loadPropertyClasses(propertyCount);
            } else {
                block.innerHTML = `
                    <div class="property-header">
                        <span style="font-weight: 600; color: #444;">Fields</span>
                        <button type="button" class="btn btn-add-field" onclick="addFieldToPropertyManual(${propertyCount})">+ Add Field</button>
                        <button type="button" class="btn btn-remove" onclick="removeProperty(${propertyCount})">✕</button>
                    </div>
                    <div class="property-fields" id="property-fields-${propertyCount}"></div>
                `;
                container.appendChild(block);
                addFieldToPropertyManual(propertyCount);
            }
        }
      
  async function selectPropertyClass(propId) {
            const block = document.getElementById(`property-block-${propId}`);
            const select = block.querySelector('.property-class');
            if (!select.value) return;
            await loadFieldNames(propId, select.value);
        }

        function checkPropertyName(propId) {
            const block = document.getElementById(`property-block-${propId}`);
            const propertyNameInput = block.querySelector('.property-name');
            const addFieldBtn = document.getElementById(`add-field-btn-${propId}`);
            
            if (propertyNameInput.value.trim()) {
                addFieldBtn.disabled = false;
                addFieldBtn.style.opacity = '1';
                addFieldBtn.style.cursor = 'pointer';
            } else {
                addFieldBtn.disabled = true;
                addFieldBtn.style.opacity = '0.5';
                addFieldBtn.style.cursor = 'not-allowed';
            }
        }

        function addFieldToPropertyManual(propId) {
            fieldCounts[propId]++;
            const fieldId = fieldCounts[propId];
            const container = document.getElementById(`property-fields-${propId}`);
            const row = document.createElement('div');
            row.className = 'field-row';
            row.id = `field-row-${propId}-${fieldId}`;
            
            row.innerHTML = `
                <input type="text" placeholder="Field Name" class="field-name">
                <input type="text" placeholder="Field Value" class="field-value">
                <button type="button" class="btn btn-remove" onclick="removeFieldFromProperty(${propId}, ${fieldId})">✕</button>
            `;
            container.appendChild(row);
        }

        let propertyFieldNames = {};

        async function loadFieldNames(propId, propertyClass) {
            const appType = getValue('table-select', 'table-input');
            let folderName = 'AAA';
            if (appType === 'AA.ARRANGEMENT.ACTIVITY' || appType === 'AAA') {
                folderName = 'AAA';
            } else if (appType === 'FUNDS.TRANSFER' || appType === 'FT') {
                folderName = 'FT';
            }
            
            try {
                const response = await fetch(`/createOfs/api/field-names/${folderName}/${propertyClass}`);
                const result = await response.json();
                
                if (result.data && result.data.length > 0) {
                    propertyFieldNames[propId] = result.data;
                } else {
                    propertyFieldNames[propId] = [];
                }
            } catch (error) {
                console.log('Error loading field names:', error.message);
                propertyFieldNames[propId] = [];
            }
        }

        async function loadPropertyClasses(propId) {
            const appType = getValue('table-select', 'table-input');
            let folderName = 'AAA';
            if (appType === 'AA.ARRANGEMENT.ACTIVITY' || appType === 'AAA') {
                folderName = 'AAA';
            } else if (appType === 'FUNDS.TRANSFER' || appType === 'FT') {
                folderName = 'FT';
            }
            
            try {
                const response = await fetch(`/createOfs/api/property-classes/${folderName}`);
                const result = await response.json();
                
                const block = document.getElementById(`property-block-${propId}`);
                const select = block.querySelector('.property-class');
                
                select.innerHTML = '<option value="">-- Select Property Class --</option>';
                if (result.data && result.data.length > 0) {
                    result.data.forEach(opt => {
                        const option = document.createElement('option');
                        option.value = opt.value;
                        option.textContent = opt.label;
                        select.appendChild(option);
                    });
                }
            } catch (error) {
                console.log('Error loading property classes:', error.message);
            }
        }

        function removeProperty(propId) {
            const block = document.getElementById(`property-block-${propId}`);
            if (block) block.remove();
        }
      
  function addFieldToProperty(propId) {
            fieldCounts[propId]++;
            const fieldId = fieldCounts[propId];
            const container = document.getElementById(`property-fields-${propId}`);
            const row = document.createElement('div');
            row.className = 'field-row';
            row.id = `field-row-${propId}-${fieldId}`;
            
            let fieldNameOptions = '<option value="">-- Select Field --</option>';
            if (propertyFieldNames[propId] && propertyFieldNames[propId].length > 0) {
                propertyFieldNames[propId].forEach(opt => {
                    fieldNameOptions += `<option value="${opt.value}">${opt.label}</option>`;
                });
            }
            
            row.innerHTML = `
                <select class="field-name-select" onchange="syncFieldName(this)">
                    ${fieldNameOptions}
                </select>
                <input type="text" placeholder="Field Name" class="field-name">
                <input type="text" placeholder="Field Value" class="field-value">
                <button type="button" class="btn btn-remove" onclick="removeFieldFromProperty(${propId}, ${fieldId})">✕</button>
            `;
            container.appendChild(row);
        }

        function syncFieldName(selectElement) {
            const row = selectElement.closest('.field-row');
            const fieldNameInput = row.querySelector('.field-name');
            fieldNameInput.value = selectElement.value;
        }

        function removeFieldFromProperty(propId, fieldId) {
            const row = document.getElementById(`field-row-${propId}-${fieldId}`);
            if (row) row.remove();
        }

        async function submitData() {
            const tableName = getValue('table-select', 'table-input');
            const arrangement = getValue('arrangement-select', 'arrangement-input');
            const date = document.getElementById('date-input').value.trim() || document.getElementById('date-select').value;
            const productId = getValue('product-select', 'product-input');
            const currency = getValue('currency-select', 'currency-input');
            const customer = getValue('customer-select', 'customer-input');
            const activity = getValue('activity-select', 'activity-input');
            const companyId = getValue('companyId-select', 'companyId-input');
            
            const properties = [];
            const propertyBlocks = document.querySelectorAll('.property-block');
            
            propertyBlocks.forEach(block => {
                const propertyRawName = block.querySelector('.property-name');
                let propertyName = "";
                if (propertyRawName) {
                    propertyName = propertyRawName.value.trim();
                }
                const fieldRows = block.querySelectorAll('.field-row');
                const fields = [];
                fieldRows.forEach(row => {
                    const name = row.querySelector('.field-name').value.trim();
                    const value = row.querySelector('.field-value').value.trim();
                    if (name || value) {
                        fields.push({ fieldName: name, fieldValue: value });
                    }
                });

                if (tableName != "AA.ARRANGEMENT.ACTIVITY") {
                    propertyName = "tableFields";
                }
                
                if (propertyName || fields.length > 0) {
                    properties.push({ propertyName: propertyName, fields: fields });
                }
            });

            const result = {
                tableName: tableName,
                arrangement: arrangement,
                date: date,
                productId: productId,
                currency: currency,
                customer: customer,
                activity: activity,
                properties: properties,
                companyId: companyId,
                note: getNoteValue()
            };
   
         try {
                const response = await fetch('/createOfs/api/submit', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(result)
                });

                const data = await response.json();
                const ofsOutput = data["received"] || JSON.stringify(data, null, 2);
                const noteValue = result.note;
                
                const newTab = window.open('', '_blank');
                newTab.document.write(`
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>OFS Output</title>
                        <style>
                            body { font-family: 'Consolas', 'Monaco', monospace; background: #1a1a2e; color: #a7f3d0; padding: 40px; margin: 0; }
                            .container { max-width: 1200px; margin: 0 auto; }
                            h1 { color: #60a5fa; margin-bottom: 20px; }
                            .note-box { background: linear-gradient(135deg, #1e3a5f, #1e293b); border: 2px solid #3b82f6; border-radius: 12px; padding: 16px 20px; margin-bottom: 20px; display: ${noteValue ? 'block' : 'none'}; }
                            .note-label { color: #60a5fa; font-weight: bold; font-size: 14px; margin-bottom: 8px; }
                            .note-content { color: #fbbf24; font-size: 16px; font-style: italic; }
                            .output-box { background: #16213e; border: 1px solid #4a5568; border-radius: 12px; padding: 24px; white-space: pre-wrap; word-break: break-all; font-size: 14px; line-height: 1.6; }
                            .copy-btn { background: linear-gradient(135deg, #22c55e, #16a34a); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-size: 14px; cursor: pointer; margin-bottom: 20px; }
                            .copy-btn:hover { background: linear-gradient(135deg, #16a34a, #15803d); }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <h1>OFS Message Output</h1>
                            <div class="note-box"><div class="note-label">📝 Note:</div><div class="note-content">${noteValue}</div></div>
                            <button class="copy-btn" onclick="copyToClipboard()">📋 Copy to Clipboard</button>
                            <div class="output-box" id="ofsContent">${ofsOutput}</div>
                        </div>
                        <script>
                            function copyToClipboard() {
                                const text = document.getElementById('ofsContent').textContent;
                                navigator.clipboard.writeText(text).then(() => {
                                    const btn = document.querySelector('.copy-btn');
                                    btn.textContent = '✓ Copied!';
                                    setTimeout(() => btn.textContent = '📋 Copy to Clipboard', 2000);
                                });
                            }
                        <\/script>
                    </body>
                    </html>
                `);
                newTab.document.close();
            } catch (error) {
                const newTab = window.open('', '_blank');
                newTab.document.write(`
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>OFS Error</title>
                        <style>
                            body { font-family: 'Consolas', 'Monaco', monospace; background: #1a1a2e; color: #fecaca; padding: 40px; margin: 0; }
                            h1 { color: #ef4444; }
                            .output-box { background: #16213e; border: 1px solid #ef4444; border-radius: 12px; padding: 24px; white-space: pre-wrap; word-break: break-all; }
                        </style>
                    </head>
                    <body>
                        <h1>Error</h1>
                        <div class="output-box">Error: ${error.message}\n\nData:\n${JSON.stringify(result, null, 2)}</div>
                    </body>
                    </html>
                `);
                newTab.document.close();
            }
        }

        // Theme toggle
        const themeToggleBtn = document.getElementById("themeToggleBtn");
        function initTheme() {
            const savedTheme = localStorage.getItem("theme");
            if (savedTheme === "dark") {
                document.body.classList.add("dark-theme");
                themeToggleBtn.textContent = "☀️";
            }
        }
        themeToggleBtn.onclick = () => {
            document.body.classList.toggle("dark-theme");
            const isDark = document.body.classList.contains("dark-theme");
            themeToggleBtn.textContent = isDark ? "☀️" : "🌙";
            localStorage.setItem("theme", isDark ? "dark" : "light");
        };
        initTheme();