import __jira__
import JIRA_I_O as I_O
import re
import var
import common_func
import time
import colorful
import os
import sys

def Main_process(J, job_track, task_ref, process_parent, fp, c, tot_no_of_tasks, job_index, multi_thread_process):

    tmp_dic = {}
    
    prev_seq = 0 #track file sequence

    while True:

        task_details = J.get_task_details(task_ref)
        tmp_dic[task_ref] = task_details
        if not(common_func.is_parent(task_details['fields'].keys())) and not(common_func.has_epic(task_details['fields'])) or not(process_parent): #when the task id does not have a parent and epic reference then consider that as a parent
            parent_task_type = task_details['fields']['issuetype']['name']

            if multi_thread_process:
                job_track[job_index] = [ round( ( c / tot_no_of_tasks ) * 100 ), fp ]
                #print('> Job : {} progress : {} | {}'.format(job_index, c, task_ref))
            else:
                print('current Reference : ', task_ref)
                print('Refrence Type     : ', parent_task_type, '\n')

            if not(multi_thread_process):
                fname, prev_seq= common_func.build_file_name(task_ref, parent_task_type, None, prev_seq)
                fp = common_func.open_output_file(fname)

            if c == 1 or not(multi_thread_process):
                I_O.update_headers(fp)
            
            if parent_task_type == var.type_list[0]:
                J.process_internal_defect(task_ref, task_details, parent_task_type, fp)
            elif parent_task_type == var.type_list[1]:
                J.process_epic(task_ref, task_details, parent_task_type, fp)
            elif parent_task_type == var.type_list[2]:
                J.process_client_defect(task_ref, task_details, parent_task_type, fp)
            elif parent_task_type == var.type_list[3] or parent_task_type == var.type_list[4]:
                J.process_task(task_ref, task_details, parent_task_type, fp)
            elif parent_task_type == var.type_list[5]:
                J.process_sub_task(task_ref, '', task_details, parent_task_type, fp)
            else:
                print('Invalid Type!!! :', task_ref)
                exit()

            if not(multi_thread_process):
                common_func.close_output_file(fp)
                
            return fp, J.tot_processed_tasks, J.tot_coding_or_scripting_tasks, J.tot_tasks_without_changes
                
        else:
            
            if var.in_debug_mode:
                print('current ref is not a parent :', task_ref)
                
            if 'parent' in task_details['fields'].keys():
                task_ref = task_details['fields']['parent']['key']
            else:
                task_ref = task_details['fields'][var.epic_field]

    return None, None, None, None

def space(current_val, max_value):
    a = len(str(current_val))
    b = len(str(max_value))
    temp = [a, b]
    temp.sort()
    space_val = ( temp[1] - temp[0] ) + 1
    return space_val

def main(job_track, job_index, fname, list_of_tasks, find_parent, u_name, password):
    
    J = __jira__.jira(u_name, password)

    if job_index:
        multi_thread_process = True
        fp = common_func.open_output_file(fname)
        process_in_thread      = []
        coding_tasks_found     = []
        task_without_changeset = []
    else:
        multi_thread_process = False
        fp = fname #it is None
        
    c = 1
    
    for task_ref in list_of_tasks:
        fp, tot_processed_tasks, tot_coding_or_scripting_tasks, tot_tasks_without_changes = Main_process(J, job_track, task_ref, find_parent, fp, c, len(list_of_tasks), job_index, multi_thread_process)
        if multi_thread_process:
            process_in_thread.extend(tot_processed_tasks)
            coding_tasks_found.extend(tot_coding_or_scripting_tasks)
            task_without_changeset.extend(tot_tasks_without_changes)
            #trace
            trace_data = ''
            os.system('cls')
            job_id_list = list(job_track.keys())
            job_id_list.sort()
            for job in job_id_list:
                trace_data += '> Job : {}{}| progress : {} % \n'.format(job, " "*space( job, job_id_list[-1]), job_track[job][0])
            print(trace_data, flush=True)
        c += 1

    if multi_thread_process:
        common_func.close_output_file(fp)

    if multi_thread_process:
        return fp, job_index, process_in_thread, coding_tasks_found, task_without_changeset
    else:
        return fp, tot_processed_tasks, tot_coding_or_scripting_tasks, tot_tasks_without_changes
        


            
        
    
    


