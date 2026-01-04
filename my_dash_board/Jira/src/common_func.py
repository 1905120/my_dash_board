import var
from datetime import datetime
import calendar
import os
from pathlib import Path
import colorful
import requests
import json
def get_api_response(url, username, password):
        
        return json.loads(requests.request(
                                       var.jira_api_method,
                                       url,
                                       headers = var.headers,
                                       auth = (username, password)
                                           ).content)
    
def is_parent(list_of_keys):
    if 'parent' in list_of_keys:
        return True
    else:
        return False

def has_epic(val):
    if not(val[var.epic_field]):
        return False
    else:
        return True

def get_sub_tasks(task_det):
    sub_tasks = []
    for sub_task in task_det['fields']['subtasks']:
        sub_tasks.append([sub_task['key'] ,sub_task['id']])
    return sub_tasks

def remove_white_space_fb(data):
    data = data.rstrip()
    data = data.lstrip()
    return data


def run_output_dir():
    os.chdir(os.path.dirname(__file__))
    os.chdir('..')
    task_detail_dir = str(os.getcwd()) + '\\' + 'Task-Details'
    if not(os.path.isdir(task_detail_dir)):
        os.mkdir(task_detail_dir)
    return task_detail_dir

def close_output_file(output_file):
    try:
        output_file.close()
    except:
        print(colorful.red('Err @_common_func : '),'No file is opened')
    return

def open_output_file(output_file):
    try:
        fp = open(output_file, 'w', encoding = 'utf-8')
        return fp
    except Exception as e:
        print(e)
        print(colorful.red('Err @_common_func :'), 'File is opened or used by some other process pls close the file and try again ! \n')
        return 0

def add_file_sequence(fp, multi_threading_seq, prev_seq):
    if prev_seq:
        initial_seq = prev_seq + 1
    else:   
        if multi_threading_seq == None:
            initial_seq = 1
        else:
            initial_seq = multi_threading_seq
    file_not_found = 1
    while file_not_found:
        fp_path = fp
        seq = '#{}'.format(initial_seq)
        fp_path += seq
        fp_path += var.output_file_extn
        if Path(fp_path).is_file():
            initial_seq += 1
        else:
            file_not_found = 0
    return fp_path, initial_seq

def build_file_name(task_ref, task_type, multi_threading_seq, prev_file_seq):
    
    tmp           = str(datetime.today().strftime('%Y-%m-%d')).split('-')
    year          = tmp[0]
    month         = int(tmp[1])
    date          = tmp[2]
    formated_date = '{}-{}-{}'.format(date, calendar.month_name[month][0 : 3], year)
    if multi_threading_seq == None:
        output_file   = '{}_{}_{}'.format(task_ref, task_type, formated_date)
    else:
        output_file   = 'JiraTaskDetails_{}'.format(formated_date)
    output_file   = '{}\\{}'.format(run_output_dir(), output_file)
    output_file   = add_file_sequence(output_file, multi_threading_seq, prev_file_seq)
    return output_file

def get_code_changes(change_set):

    code_changes = []
    count = 0
    
    for code_component in change_set["values"]:
        #print(code_component["path"]['extension'])
        if 'extension' in code_component["path"].keys():
                if code_component["path"]['extension'] not in var.req_file_types:
                        continue
        code_changes.append(code_component["path"]["components"])
        count += 1
    return [ code_changes, count ]

def extract_from_det(pr):
        reviewers     = ''
        merge_dt      = None
        status_of_pr  = None
        from_ref      = None
        to_ref        = None
        for values in pr["values"]:
            for reviewer_data in values["reviewers"]:
                if reviewer_data["status"] == "APPROVED":
                    try:
                        reviewers += reviewer_data["user"]["displayName"]
                    except:
                        reviewers += reviewer_data["user"]["name"]
                    reviewers += var.reviewers_sep
            #merge_dt = self.format_date(values["updatedDate"])
            try:
                status_of_pr = values['state']
                from_ref     = values['fromRef']['displayId']
                to_ref       = values['toRef']['displayId']
            except Exception as e:
                print(e)
                pass
            
        reviewers = reviewers.rstrip(var.reviewers_sep)

        if not(reviewers):
            reviewers = None
            
        return status_of_pr, from_ref, to_ref, reviewers
        
def get_processed_details(tot_processed_tasks, tot_coding_or_scripting_tasks, tot_tasks_without_changes):
    
    if var.in_debug_mode:
        print(colorful.green('\nTotal processed tasks   :'), len(tot_processed_tasks))
        for idx, task in enumerate(tot_processed_tasks):
            print(idx + 1, task)
            
    if var.in_debug_mode:
        print(colorful.green('\nTasks with changeset    :'), len(tot_coding_or_scripting_tasks))
        for idx, task in enumerate(tot_coding_or_scripting_tasks):
            print(idx + 1, task)
            
    if var.in_debug_mode:
        print(colorful.green('\nTasks without chnageset :'), len(tot_tasks_without_changes))
        for idx, task in enumerate(tot_tasks_without_changes):
            print(idx + 1, colorful.red(task))
            
    return

def print_border():
    if var.in_debug_mode:
            print(colorful.yellow('-----------------------------------------------------------------------------------------------------'))
    return
