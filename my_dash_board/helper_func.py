from common import CDM_ARCHIVED_DEFECTS_DIR, CDM_CURRENT_DEFECTS_DIR, CDM_BUSSINESS_PROCESS_RESULT, CDM_RESOURCES, UTP_PACK_DETAILS_PATH, CREATE_OFS_TABLES_PATH
import os
import json
import shutil
from UTP_utility import UTPConversion  # TODO: Add UTP_utility to path or move to my_dash_board
import logging
from tool_bitbucket_retail.BitBucket.Bitbucket.src.Main import Process_Bitbucket_Details
from Jira.src.CONTROLLER import process_jira_tasks
from pathlib import Path
import time
from fetch_opengrok import update_aaa_table

def safe_delete_folder(path, retries=3, delay=0.5):

    path = Path(path)

    for i in range(retries):
        try:
            shutil.rmtree(path)
            return True
        except PermissionError:
            time.sleep(delay)
    raise Exception("unable to delete")
    return

def delete_file(option, path):
    if os.path.exists(path):
        if option == "all":
            safe_delete_folder(path)
        elif option == "current":
            os.remove(path)
    return

def get_json_obj(json_rec):
    return_obj = []
    for lable in json_rec:
        return_obj.append({"label" : lable, "value" : json_rec[lable]})
    return return_obj

def CDM_create_dir(Dir):
    if not os.path.exists(Dir):
        os.makedirs(name=Dir, exist_ok=True)
    return

def write_json_file(file_path, rec):
    try:
        with open(file_path, "w") as f:
            json.dump(obj=rec, fp=f, indent=4)
    except Exception as e:
        print(f"Err on write : file : {file_path}")
        return False
    return True

def read_file(file_path, extn):
    rec = None
    if os.path.exists(file_path):
        try:
            with open(file_path, "r") as f:
                if extn == "json":
                    rec = json.load(f)
                else:
                    rec = f.read()
        except Exception as e:
            CDM_BUSSINESS_PROCESS_RESULT["err"] = str(e)
            print(f'Err on read file : {file_path}')
    else:
        if extn == "json":
            write_file = write_json_file(file_path, {})
            if write_file:
                return {}
    return rec

def CDM_get_required_dir(_type):
    if _type == "current":
        if not os.path.exists(CDM_CURRENT_DEFECTS_DIR):
            CDM_create_dir(CDM_CURRENT_DEFECTS_DIR)
        Dir = CDM_CURRENT_DEFECTS_DIR
    elif _type == "archived":
        if not os.path.exists(CDM_ARCHIVED_DEFECTS_DIR):
            CDM_create_dir(CDM_ARCHIVED_DEFECTS_DIR)
        Dir = CDM_ARCHIVED_DEFECTS_DIR
    elif _type == "resources":
        if not os.path.exists(CDM_RESOURCES):
            CDM_create_dir(CDM_RESOURCES)
        Dir = CDM_RESOURCES
    return Dir

def write_file(file_path, rec):
    try:
        with open(file_path, "w") as f:
            f.write(rec)
    except Exception as e:
        print(f"Err on write : file : {file_path}")
    return 

def delete_dir(option, dir):
    try:
        if not os.path.exists(dir):
            return True
        if option == "all":
            shutil.rmtree(dir)
        else:
            os.remove(dir)
    except Exception as e:
        return False
    return True

def CDM_create_defect_details(def_det):
    CDM_BUSSINESS_PROCESS_RESULT["err"] = ""
    current_defect_path = CDM_get_required_dir("current")
    defect_resources_dir = CDM_get_required_dir("resources")
    defect_details = read_file(f'{current_defect_path}\\defect_details.json', "json")
    if not defect_details:
        defect_details = {}
    for defect_id in def_det:
        if defect_id in defect_details:
            CDM_BUSSINESS_PROCESS_RESULT["err"] += f'{defect_id} already exists'
            continue
        jira_link = f'https://jira.temenos.com/browse/{defect_id}'
        resource_dir = f'{defect_resources_dir}\\{defect_id}'
        CDM_create_dir(resource_dir)
        log = f'{resource_dir}\\Log.txt'
        write_file(log, "")
        def_det[defect_id]["resource_dir"] = resource_dir.replace("\\", "//")
        def_det[defect_id]["log"] = log.replace("\\", "//")
        def_det[defect_id]["jira_link"] = jira_link
        defect_details[defect_id] = def_det[defect_id]
    write_json_file(f'{current_defect_path}\\defect_details.json', defect_details)

    return CDM_BUSSINESS_PROCESS_RESULT

def CDM_get_all_defect_details(view_type = None):
    CDM_BUSSINESS_PROCESS_RESULT["err"] = ""
    view_type = view_type if view_type else "current"
    defect_path = CDM_get_required_dir(view_type)
    CDM_BUSSINESS_PROCESS_RESULT["return_value"]  = read_file(f'{defect_path}\\defect_details.json', "json")
    return CDM_BUSSINESS_PROCESS_RESULT

def CDM_write_defect_details_file(key, vlaue):
    return

def CDM_update_defect_details(updated_defect_details, view_type):
    CDM_BUSSINESS_PROCESS_RESULT["err"] = ""
    CDM_BUSSINESS_PROCESS_RESULT["return_val"] = ""
    view_type = view_type if view_type else "current"
    current_defect_path = CDM_get_required_dir(view_type)
    defect_details = read_file(f'{current_defect_path}\\defect_details.json', "json")
    for defect_id in updated_defect_details:
        if defect_id not in defect_details:
            continue
        for field in updated_defect_details[defect_id]:
            defect_details[defect_id][field] = updated_defect_details[defect_id][field]
    write_json_file(f'{current_defect_path}\\defect_details.json', defect_details)
    return CDM_BUSSINESS_PROCESS_RESULT


def CDM_move_to_archive_defect_details(defects_ids, view_type):
    CDM_BUSSINESS_PROCESS_RESULT["err"] = ""
    current_defect_path = CDM_get_required_dir("current")
    archive_defect_path = CDM_get_required_dir("archived")
    current_defect_details = read_file(f'{current_defect_path}\\defect_details.json', "json")
    archive_defect_details = read_file(f'{archive_defect_path}\\defect_details.json', "json")
    for defect_id in defects_ids:
        archive_defect_details[defect_id] = current_defect_details[defect_id]
        if defect_id in current_defect_details:
            del current_defect_details[defect_id]
    write_json_file(f'{current_defect_path}\\defect_details.json', current_defect_details)
    write_json_file(f'{archive_defect_path}\\defect_details.json', archive_defect_details)
    return CDM_BUSSINESS_PROCESS_RESULT

def CDM_move_to_current_defect_details(defects_ids, view_type):
    CDM_BUSSINESS_PROCESS_RESULT["err"] = ""
    current_defect_path = CDM_get_required_dir("current")
    archive_defect_path = CDM_get_required_dir("archived")
    current_defect_details = read_file(f'{current_defect_path}\\defect_details.json', "json")
    archive_defect_details = read_file(f'{archive_defect_path}\\defect_details.json', "json")
    for defect_id in defects_ids:
        current_defect_details[defect_id] = archive_defect_details[defect_id]
        if defect_id in archive_defect_details:
            del archive_defect_details[defect_id]
    write_json_file(f'{current_defect_path}\\defect_details.json', current_defect_details)
    write_json_file(f'{archive_defect_path}\\defect_details.json', archive_defect_details)
    return CDM_BUSSINESS_PROCESS_RESULT

def CDM_delete_defect_details(defects_ids, view_type):
    print(defects_ids)
    CDM_BUSSINESS_PROCESS_RESULT["err"] = ""
    current_defect_path = CDM_get_required_dir(view_type)
    defect_resources_dir = CDM_get_required_dir("resources")
    defect_details = read_file(f'{current_defect_path}\\defect_details.json', "json")
    for defect_id in os.listdir(defect_resources_dir):
        if defect_id in defects_ids:
            defect_dir_deleted = delete_dir(option="all", dir=f'{defect_resources_dir}\\{defect_id}')
            if not defect_dir_deleted:
                continue
            del defect_details[defect_id]
    write_json_file(f'{current_defect_path}\\defect_details.json', defect_details)
    return CDM_BUSSINESS_PROCESS_RESULT

def manage_utp(file_path, Option, deployment_opt):
    current_path  = os.path.dirname(file_path)
    log_dir       = f'{current_path}\\Log'
    db_path       = f'{file_path}\\db\\h2'
    jboss_path    = f'{file_path}\\jboss'
    tafj_path     = f'{file_path}\\TAFJ'
    UTP_Setup = UTPConversion(file_path, jboss_path, db_path, tafj_path, log_dir)
    logger = logging.getLogger(__name__)   # <--- get a real logger object
    if not os.path.exists(UTP_Setup.log_dir):
        os.mkdir(UTP_Setup.log_dir)
    if not os.path.exists(f"{UTP_Setup.log_dir}\\Log.log"):
        open(f"{UTP_Setup.log_dir}\\Log.log", "w").close()
    logging.basicConfig(filename=f'{UTP_Setup.log_dir}\\Log.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    UTP_Setup.logger = logger
    if Option == 1:
        UTP_Setup.clear_logs()
        UTP_Setup.clear_cache()
        UTP_Setup.check_current_path_is_valid()
        UTP_Setup.check_db_variant()
        UTP_Setup.update_drivers()
        UTP_Setup.update_jars_in_file()
        UTP_Setup.update_mvcc_setup()
        UTP_Setup.Generate_Module_Xml()
    elif Option == 2:
        UTP_Setup.Generate_Module_Xml()
    elif Option == 3:
        UTP_Setup.clear_logs()
    elif Option == 4:
        UTP_Setup.clear_cache()
    elif Option == 5:
        UTP_Setup.clear_logs()
        UTP_Setup.clear_cache()
    elif Option == 6:
        UTP_Setup.Handle_Deployments(deployment_opt)
    print("check Logger For More info")
    UTP_Setup.logger.info(f"Process Done {'-'*100}")
    return ""

def get_available_run_tag(repo, project, list_of_tags):
    input_proj ,input_repos, list_of_tags, file_ptr = Process_Bitbucket_Details(project, repo, list_of_tags)
    return list_of_tags, file_ptr

def get_bitbucket_extracted_data(repo, project, list_of_tags):
    input_proj ,input_repos, list_of_tags, file_ptr = Process_Bitbucket_Details(project, repo, list_of_tags)
    return list_of_tags, file_ptr

def get_jira_extracted_data(jira_id):
    file_ptr = process_jira_tasks(jira_id)
    return file_ptr

def clear_cache_files_for_jiro_prod_lookup(path):
    delete_file(option="all", path=path)
    return True

def add_utp_pack_details(lable, path):
    data = read_file(f'{UTP_PACK_DETAILS_PATH}\\data.json', 'json')
    exists_utp_pack_details = data["utp_update_options"]
    add_utp_pack_det = True
    for utp_pack in exists_utp_pack_details:
        if lable == utp_pack['label']:
            add_utp_pack_det = False
    if add_utp_pack_det:
        exists_utp_pack_details.append({
                "label" : lable,
                "value" : path
        })
        data["utp_update_options"] = exists_utp_pack_details
        write_json_file(f'{UTP_PACK_DETAILS_PATH}\\data.json', data)
    else:
        raise Exception("invalid lable")
    return False


def update_available_all_table_for_create_ofs_module():
    update_aaa_table()
    return
