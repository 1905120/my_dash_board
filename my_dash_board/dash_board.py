from flask import Flask, jsonify, render_template, abort, request
import os, json
from common import DEFAULT_OPTIONS, TABLES_DIR, CURRENT_FILE,JIRA_CACHE_PATH, BITBUCKET_CACHE_PATH
from helper_func import CDM_get_all_defect_details, CDM_create_defect_details, CDM_delete_defect_details, CDM_update_defect_details, read_file, get_json_obj, get_available_run_tag, get_jira_extracted_data, clear_cache_files_for_jiro_prod_lookup, add_utp_pack_details, delete_utp_pack_details, update_available_all_table_for_create_ofs_module, CDM_move_defect_details, get_daily_quotes, update_bitbucket_login_credentials
import subprocess
import sys
import re

app = Flask(__name__, static_folder='static', static_url_path='/static')

def load_json(rel_path):
    path = os.path.join(app.root_path, rel_path)
    if not os.path.exists(path):
        return None
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

@app.route('/my_dashboard')
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/my_dashboard/api1/getTodayQuote', methods=["GET"])
def getTodayQuote():
    try:
        daily_qoute, day_count = get_daily_quotes()
        return jsonify({"status": "authorized", "message": daily_qoute, "dailyCount" : day_count}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e), "dailyCount" : 0}), 500

@app.route('/online-jira')
def login_page():
    return render_template('login.html')

@app.route('/api/online-jira/login', methods=['POST'])
def check_login():
    try:
        is_authorized = True
        
        if is_authorized:
            return jsonify({"status": "authorized", "message": "Login available"}), 200
        else:
            return jsonify({"status": "unauthorized", "message": "Login not available"}), 403
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/api/online-jira/actions', methods=['GET'])
def get_jira_actions():
    # Return the list of available actions
    actions = ["get_jira_details", "get_bitbucket_details"]
    return jsonify({"actions": actions}), 200

@app.route('/api/online-jira/hierarchy', methods=['POST'])
def get_jira_hierarchy():
    from urllib.parse import quote
    try:
        hierarchy = {}
        data = request.get_json()
        jira_ids = []

        if not data:
            return jsonify({"error": "Jira ID is required"}), 400

        for jira_det in data:
            jira_id = jira_det.get('jira_id', '')
            if not jira_id:
                return jsonify({"error": "Jira ID is required"}), 400
            jira_ids.append(jira_id)
        
        list_of_file_dir = get_jira_extracted_data(jira_ids)
        
        # Build download URLs for each file
        files_with_download = []
        for file_path in list_of_file_dir:
            file_name = os.path.basename(file_path)
            encoded_path = quote(file_path, safe='')
            files_with_download.append({
                "file_path": file_path,
                "file_name": file_name,
                "download_url": f"/api/online-jira/hierarchy/download?path={encoded_path}"
            })

        return jsonify({"list_of_file_dir": files_with_download}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/hierarchy/download', methods=['GET'])
def download_jira_hierarchy_file():
    from flask import send_file
    from urllib.parse import unquote
    try:
        file_path = unquote(request.args.get('path', ''))
        
        if not file_path:
            return jsonify({"error": "File path is required"}), 400
        
        if not os.path.exists(file_path):
            return jsonify({"error": f"File not found: {file_path}"}), 404
        
        file_name = os.path.basename(file_path)
        return send_file(file_path, as_attachment=True, download_name=file_name)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/credentials', methods=['POST'])
def save_jira_credentials():
    """Save Jira credentials to a file"""
    try:
        data = request.get_json()
        username = data.get('username', '')
        password = data.get('password', '')
        
        if not username or not password:
            return jsonify({"error": "Username and password are required"}), 400
        
        # Save credentials to Jira credentials file
        cred_path = os.path.join(app.root_path, 'Jira', 'src', 'Data', 'credentials.txt')
        os.makedirs(os.path.dirname(cred_path), exist_ok=True)
        with open(cred_path, 'w') as f:
            f.write(f'{username}\n{password}')
        
        return jsonify({"status": "success", "message": "Credentials saved"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/clear-cache', methods=['POST'])
def clear_jira_cache():
    """Clear Jira cache files"""
    import shutil
    try:
        response = clear_cache_files_for_jiro_prod_lookup(JIRA_CACHE_PATH)
        return jsonify({"status": "success", "message": "Cache cleared"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/bitbucket/credentials', methods=['POST'])
def save_bitbucket_credentials():
    """Save Bitbucket credentials to a file"""
    try:
        data = request.get_json()
        username = data.get('username', '')
        password = data.get('password', '')
        
        if not username or not password:
            return jsonify({"error": "Username and password are required"}), 400
        
        result, err = update_bitbucket_login_credentials(username, password)
        if err:
            raise Exception(err)
        else:
            return jsonify({"status": "success", "message": "Credentials saved"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/bitbucket/clear-cache', methods=['POST'])
def clear_bitbucket_cache():
    """Clear Bitbucket cache files"""
    try:
        response = clear_cache_files_for_jiro_prod_lookup(BITBUCKET_CACHE_PATH)
        return jsonify({"status": "success", "message": "Cache cleared"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/download', methods=['POST'])
def download_jira_file():
    from flask import send_file, Response
    import io
    
    try:
        data = request.get_json()
        jira_id = data.get('jira_id', '')
        
        if not jira_id:
            return jsonify({"error": "Jira ID is required"}), 400
        
        # Define the storage path for Jira files
        storage_path = os.path.join(app.root_path, 'jira_storage', f'{jira_id}.json')
        
        # Check if file exists in storage
        if os.path.exists(storage_path):
            return send_file(storage_path, as_attachment=True, download_name=f'{jira_id}_hierarchy.json')
        else:
            # If file doesn't exist, create a sample JSON and return it
            sample_data = {
                "jira_id": jira_id,
                "hierarchy": {
                    "epic": {"key": jira_id, "summary": f"Epic: {jira_id}"},
                    "stories": []
                },
                "generated": True
            }
            
            # Return as downloadable JSON
            json_str = json.dumps(sample_data, indent=2)
            return Response(
                json_str,
                mimetype='application/json',
                headers={'Content-Disposition': f'attachment;filename={jira_id}_hierarchy.json'}
            )
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/bitbucket/options', methods=['GET'])
def get_bitbucket_options():
    """Returns the list of available projects and repositories for Bitbucket"""
    try:
        # TODO: Replace with actual Bitbucket API call to fetch projects/repos
        # For now, return sample data

        rec = read_file(f'{CURRENT_FILE}\\tool_bitbucket_retail\\BitBucket\\Bitbucket\\src\\Data\\data.json', "json")

        projects = get_json_obj(rec["projects"])

        repos = get_json_obj(rec["repositories"])

        return jsonify({
            "status": "success",
            "projects": projects,
            "repos": repos
        }), 200
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e),
            "projects": [],
            "repos": []
        }), 500

@app.route('/api/online-jira/bitbucket', methods=['POST', "GET"])
def get_bitbucket_details():
    try:
        data = request.get_json()
        # Support both single and multiple values
        repos = data.get('repos', [])
        projects = data.get('projects', [])
        
        # Backward compatibility for single values
        if not repos and data.get('repo'):
            repos = [data.get('repo')]
        if not projects and data.get('project'):
            projects = [data.get('project')]
        
        # TODO: Replace with actual Bitbucket API call
        # For now, return sample list
        results, file_ptr = get_available_run_tag(repos, projects, [])
        
        return jsonify({
            "results": results,
            "selected_repos": repos,
            "selected_projects": projects
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/bitbucket/compare', methods=['POST'])
def compare_bitbucket_tags():
    from urllib.parse import quote
    try:
        data = request.get_json()
        repos = data.get('repos', [])
        projects = data.get('projects', [])
        from_tag = data.get('from_tag', '')
        to_tag = data.get('to_tag', '')
        
        if not from_tag or not to_tag:
            return jsonify({"error": "Both from_tag and to_tag are required"}), 400
        
        range_tag = [from_tag, to_tag]
        results, file_ptr = get_available_run_tag(repos, projects, [range_tag])
        
        # Get file path and name
        file_path = file_ptr.name if hasattr(file_ptr, 'name') else str(file_ptr)
        file_name = os.path.basename(file_path)
        
        # URL encode the path to handle special characters
        encoded_path = quote(file_path, safe='')
        
        # Return URL path for download endpoint
        return jsonify({
            "file_path": f"/api/online-jira/bitbucket/download-file?path={encoded_path}",
            "file_name": file_name
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/online-jira/bitbucket/download-file', methods=['GET'])
def download_bitbucket_file():
    from flask import send_file
    from urllib.parse import unquote
    try:
        file_path = unquote(request.args.get('path', ''))
        
        if not file_path or not os.path.exists(file_path):
            return jsonify({"error": f"File not found: {file_path}"}), 404
        
        file_name = os.path.basename(file_path)
        return send_file(file_path, as_attachment=True, download_name=file_name)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/CD_manager")
def client_defect():
    return render_template("client-defect.html")

@app.route("/manage-utp")
def manage_utp():
    return render_template("manage-utp.html")

@app.route('/api/manage-utp/options', methods=['GET'])
def get_utp_options():
    """Returns the list of available UTP operations and values"""
    try:
        data       = read_file(f'{CURRENT_FILE}\\utp_utility_data\\data.json', "json")
        operations     = data["Operation"]
        values = data["utp_update_options"]
        return jsonify({
            "status": "success",
            "operations": operations,
            "values": values
        }), 200
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e),
            "operations": [],
            "values": []
        }), 500
    
@app.route('/api/manage-utp/addUtpPackDetails', methods=["POST"])
def addUtpPackDetails():
    try:
        data = request.get_json()
        lable = data.get("UTP_Label")
        Path = data.get("Path")
        res = add_utp_pack_details(lable, Path)
        return jsonify({
                "status": "success",
                "message": "path added"
            }), 200
    except Exception as e:
        return jsonify({
                "status": "error",
                "message": str(e)
            }), 400

@app.route('/api/manage-utp/deleteUtpPack', methods=["POST"])
def deleteUtpPack():
    try:
        data = request.get_json()
        values = data.get("values", [])
        
        if not values:
            return jsonify({
                "status": "error",
                "message": "No UTP packs selected for deletion"
            }), 400
        
        deleted_count = delete_utp_pack_details(values)
        
        return jsonify({
            "status": "success",
            "message": f"Successfully deleted {deleted_count} UTP pack(s)",
            "deleted_count": deleted_count
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route('/api/manage-utp/execute', methods=['POST'])
def execute_utp_operation():
    from helper_func import manage_utp
    try:
        data = request.get_json()
        value = data.get('value', '')
        operation = int(data.get('operation', ''))
        deployment_details = data.get('deployment', None)  # For Manage Deployments option
        deployment_option = int(deployment_details.get("id")) if deployment_details else None
        if not value or not operation:
            return jsonify({
                "status": "error",
                "message": "Value and operation are required"
            }), 400
        
        result = manage_utp(value, operation, deployment_option)
        
        # Add deployment info if present
        if operation == 6 and deployment_option:
            result += f"\nDeployment ID: {deployment_details.get('id', 'N/A')}"
            result += f"\nDeployment Name: {deployment_details.get('name', 'N/A')}"
        
        result += "\nStatus: Executed successfully"
        
        # Build response data
        response_data = {
            "value": value,
            "operation": operation,
            "operation_name": ""
        }
        
        if deployment_option:
            response_data["deployment"] = deployment_details["name"]
        
        return jsonify({
            "status": "success",
            "message": "Operation executed",
            "result": result,
            "data": response_data
        }), 200
        
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route('/api/nav', methods=["GET"])
def api_nav():
    data = load_json('api/nav.json')
    print(data)
    if data is None:
        abort(404)
    return jsonify(data)

@app.route('/api/items')
def api_items():
    data = load_json('api/items.json')
    if data is None:
        abort(404)
    return jsonify(data)

@app.route("/api/defects")
def get_defect_list():
    view_type = request.args.get("type", "current")  # current is default
    result = CDM_get_all_defect_details(view_type)
    if result["err"]:
       return jsonify({
            "status": "error",
            "message": result["err"],
            "data": []
        }), 500
    else:
        return jsonify({
            "status": "success",
            "message": "Defect Created SuccessFully",
            "data": result["return_value"]}), 200

@app.route("/api/Createdefects", methods=["POST"])
def create_defect_list():
    view_type = "current"
    defect_det = json.loads(request.data)
    porcess_msg = CDM_create_defect_details(defect_det)
    if porcess_msg["err"]:
       return jsonify({
            "status": "error",
            "message": porcess_msg["err"],
            "data": []
        }), 500
    else:
        return jsonify({
            "status": "success",
            "message": "Defect Created SuccessFully",
            "data": []}), 200


@app.route('/api/cdm/delete_defect', methods=["POST"])
def CDM_delete_defects():
    data = json.loads(request.data)
    porcess_msg = CDM_delete_defect_details(data['ids'], data['viewType'])
    if porcess_msg["err"]:
       return jsonify({
            "status": "error",
            "message": porcess_msg["err"],
            "data": []
        }), 500
    else:
        return jsonify({
            "status": "success",
            "message": "Defect Created SuccessFully",
            "data": []}), 200

@app.route('/api/cdm/archive_defect', methods=["POST"])
def CDM_archive_defects():
    data = json.loads(request.data)
    porcess_msg = CDM_move_defect_details(data['ids'], data['viewType'], "archived")
    if porcess_msg["err"]:
       return jsonify({
            "status": "error",
            "message": porcess_msg["err"],
            "data": []
        }), 500
    else:
        return jsonify({
            "status": "success",
            "message": "Defect Created SuccessFully",
            "data": []}), 200

@app.route('/api/cdm/move_current', methods=["POST"])
def CDM_mode_current_defects():
    data = json.loads(request.data)
    porcess_msg = CDM_move_defect_details(data['ids'], data['viewType'], "current")
    if porcess_msg["err"]:
       return jsonify({
            "status": "error",
            "message": porcess_msg["err"],
            "data": []
        }), 500
    else:
        return jsonify({
            "status": "success",
            "message": "Defect Created SuccessFully",
            "data": []}), 200

@app.route('/api/cdm/move_to_new', methods=["POST"])
def CDM_move_to_new_defects():
    data = json.loads(request.data)
    porcess_msg = CDM_move_defect_details(data['ids'], data['viewType'], "new")
    if porcess_msg["err"]:
       return jsonify({
            "status": "error",
            "message": porcess_msg["err"],
            "data": []
        }), 500
    else:
        return jsonify({
            "status": "success",
            "message": "Defect Created SuccessFully",
            "data": []}), 200
    
@app.route('/api/cdm/edit_defect', methods=["POST"])
def CDM_edit_defects():
    data = json.loads(request.data)
    porcess_msg = CDM_update_defect_details(data['updatedDefects'], data['viewType'])
    if porcess_msg["err"]:
       return jsonify({
            "status": "error",
            "message": porcess_msg["err"],
            "data": []
        }), 500
    else:
        return jsonify({
            "status": "success",
            "message": "Defect Created SuccessFully",
            "data": []}), 200
    
@app.route("/open-file", methods=["POST"])
def open_log():
    try:
        path = request.json.get("path") if request.json else None

        if not path:
            return jsonify({"status": "error", "message": "No path provided"}), 400
        
        # Normalize the path
        path = os.path.normpath(path)
        
        if not os.path.exists(path):
            return jsonify({"status": "error", "message": f"File not found: {path}"}), 404

        if sys.platform.startswith("win"):
            os.startfile(path)
        elif sys.platform.startswith("darwin"):
            subprocess.run(["open", path])
        else:
            subprocess.run(["xdg-open", path])

        return jsonify({"status": "success", "message": "File opened"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/open-dir", methods=["POST"])
def open_dir():
    try:
        path = request.json.get("path") if request.json else None

        if not path:
            return jsonify({"status": "error", "message": "No path provided"}), 400
        
        # Normalize the path
        path = os.path.normpath(path)
        
        if not os.path.exists(path):
            return jsonify({"status": "error", "message": f"Path not found: {path}"}), 404

        # If it's a file, open its parent directory
        if os.path.isfile(path):
            path = os.path.dirname(path)

        if sys.platform.startswith("win"):
            os.startfile(path)
        elif sys.platform.startswith("darwin"):
            subprocess.run(["open", path])
        else:
            subprocess.run(["xdg-open", path])

        return jsonify({"status": "success", "message": "Directory opened"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

############################################# create ofs

@app.route('/CreateOfs')
def LoadCreateOfsPage():
    return render_template("create-ofs.html")


@app.route('/createOfs/api/options', methods=['GET'])
def get_options():
    """Fetch dropdown options for all fields - tries DB first, falls back to defaults"""
    try:
        # Try to fetch from database
        #db_options = fetch_all_options()
        
        # Merge DB results with defaults (use DB value if available, else default)
        result = {}
        for key in DEFAULT_OPTIONS:
            db_value = db_options.get(key) if db_options else None
            result[key] = db_value if db_value else DEFAULT_OPTIONS[key]
        
        return jsonify({
            "status": "success",
            "source": "database" if db_options and any(db_options.values()) else "default",
            "data": result
        })
    except Exception as e:
        # On error, return default options
        return jsonify({
            "status": "fallback",
            "message": str(e),
            "data": DEFAULT_OPTIONS
        })

@app.route('/createOfs/api/options/<field_name>', methods=['GET'])
def get_field_options(field_name):
    """Fetch dropdown options for a specific field"""
    try:
        if field_name in DEFAULT_OPTIONS:
            return jsonify({
                "status": "success",
                "data": DEFAULT_OPTIONS[field_name]
            })
        else:
            return jsonify({
                "status": "error",
                "message": f"Unknown field: {field_name}",
                "data": []
            }), 404
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e),
            "data": []
        }), 500
    
@app.route("/createOfs/api/updatedTables", methods = ["GET"])
def update_all_table():
    try:
        res = update_available_all_table_for_create_ofs_module()
        return jsonify({
                "status": "error",
                "message": res,
                "data": []
            }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e),
            "data": []
        }), 500

@app.route('/createOfs/api/property-classes/<app_type>', methods=['GET'])
def get_property_classes(app_type):
    """Fetch property class options from tables folder based on application type"""
    try:
        folder_path = os.path.join(TABLES_DIR, app_type)
        
        if not os.path.exists(folder_path):
            return jsonify({
                "status": "error",
                "message": f"Folder not found: {app_type}",
                "data": []
            }), 404
        
        # Get all files in the folder (without extension)
        files = []
        for filename in os.listdir(folder_path):
            file_path = os.path.join(folder_path, filename)
            if os.path.isfile(file_path):
                # Remove extension for display
                name_without_ext = os.path.splitext(filename)[0]
                files.append({
                    "value": name_without_ext,
                    "label": name_without_ext
                })
        return jsonify({
            "status": "success",
            "data": sorted(files, key=lambda x: x['label'])
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e),
            "data": []
        }), 500


@app.route('/createOfs/api/field-names/<app_type>/<property_class>', methods=['GET'])
def get_field_names(app_type, property_class):
    """Fetch field names from property class JSON file"""
    try:
        # Try different file extensions
        file_path = None
        for ext in ['.json', '.JSON', '']:
            test_path = os.path.join(TABLES_DIR, app_type, f"{property_class}{ext}")
            if os.path.exists(test_path):
                file_path = test_path
                break
        
        if not file_path:
            return jsonify({
                "status": "error",
                "message": f"File not found: {property_class}",
                "data": []
            }), 404
        
        # Read and parse JSON file
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Extract field names from the JSON
        field_names = []
        if isinstance(data, dict):
            # If there's a 'fieldnames' key, use it
            if 'fields' in data:
                fields = list(data['fields'].keys())
                if isinstance(fields, list):
                    #field_names = [{"value": f, "label": f} for f in fields]
                    for each_field_name in fields:
                        field_name = re.sub(r'.*(\([^)]+\))', r'\1', each_field_name)
                        field_name = field_name.replace("(", "")
                        field_name = field_name.replace(")", "")
                        first_occurence_dot = field_name.find(".")
                        second_occurence_dot = field_name.find(".", first_occurence_dot + 1)
                        if field_name:
                            field_names.append({"value": field_name[second_occurence_dot + 1:], "label": field_name[second_occurence_dot + 1:]})
                elif isinstance(fields, dict):
                    field_names = [{"value": k, "label": k} for k in fields.keys()]
            # Otherwise use all keys from the JSON
            else:
                field_names = [{"value": k, "label": k} for k in data.keys()]
        elif isinstance(data, list):
            # If it's a list of field names
            field_names = [{"value": f, "label": f} for f in data]
        
        return jsonify({
            "status": "success",
            "data": field_names
        })
    except json.JSONDecodeError as e:
        return jsonify({
            "status": "error",
            "message": f"Invalid JSON in file: {str(e)}",
            "data": []
        }), 500
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e),
            "data": []
        }), 500


@app.route('/createOfs/api/submit', methods=['POST'])
def submit_data():
    data = request.get_json()
    
    table_name = data.get('tableName')
    date = data.get('date')
    prod_id = data.get('productId')
    curr = data.get('currency')
    cust = data.get('customer')
    activity_id = data.get('activity')
    arrangement = data.get('arrangement')
    company_id = data.get('companyId')
    if table_name == "AA.ARRANGEMENT.ACTIVITY":
        ofs_data = f'{table_name},/I/PROCESS//0/,AUTHOR/123456/{company_id},,ARRANGEMENT:1:1={arrangement},ACTIVITY:1:1={activity_id},EFFECTIVE.DATE:1:1={date},CUSTOMER:1:1={cust},PRODUCT:1:1={prod_id},CURRENCY:1:1={curr},'
    elif table_name == "FUNDS.TRANSFER":
        ofs_data = f'{table_name},/I/PROCESS//0/,AUTHOR/123456/{company_id},,'
    prop_count = 0
    for prop in data.get('properties', []):
        prop_count += 1
        field_name_value_present = False
        if table_name == "AA.ARRANGEMENT.ACTIVITY":
            prop_str = f'PROPERTY:{prop_count}:1={prop['propertyName']},'
        elif table_name == "FUNDS.TRANSFER":
            prop_str = ""
        field_count = 0
        for field in prop.get('fields', []):
            field_count += 1
            field_name_value_present = True
            if table_name == "AA.ARRANGEMENT.ACTIVITY":
                prop_str += f'FIELD.NAME:{prop_count}:{field_count}={field['fieldName']},FIELD.VALUE:{prop_count}:{field_count}={field['fieldValue']},'
            elif table_name == "FUNDS.TRANSFER":
                prop_str += f'{field['fieldName']}={field['fieldValue']},'
        if field_name_value_present:
            ofs_data += f'{prop_str}'
        else:
            prop_count -= 1

    return jsonify({
        "status": "success",
        "message": "Data received successfully",
        "received": ofs_data
    })

############################################# create ofs

# Catch-all route for static files - MUST be at the end
@app.route('/<path:filename>')
def static_files(filename):
    from flask import send_from_directory
    # serve other static files (css/js/api json)
    full = os.path.join(app.root_path, filename)
    if os.path.exists(full) and os.path.isfile(full):
        return send_from_directory('.', filename)
    abort(404)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
