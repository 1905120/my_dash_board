import requests
import var
from atlassian import Jira
import requests
import json
import common_func
import JIRA_I_O as I_O
import colorful
import re

class jira:
    
    def __init__(self, u_name, Password):
        self.username = u_name
        self.password = Password
        self.jira = Jira(url=var.jira_url, username=self.username, password=self.password)
        self.tot_processed_tasks = []
        self.tot_coding_or_scripting_tasks = []
        self.tot_tasks_without_changes = []
        return
    #-----core functions--------------------------------------------------------------------

    def process_client_defect(self, task_ref, task_details, parent_task_type, fp):
        if var.in_debug_mode:
            print('processing {}'.format(parent_task_type))
        self.process_task(task_ref, task_details, None, fp)
        return

    def process_epic(self, epic_key, task_details, parent_task_type, fp):
        if var.in_debug_mode:
            print('processing {}'.format(parent_task_type))
            
        key_id = {}
        key_id[epic_key] = {}
        issue_id, epic_tasks = self.get_issues_for_epic(epic_key, task_details)

        #check code files under a epic...
        common_func.print_border()
        list_of_files = self.process_files_under_a_task(epic_key, issue_id, fp)
        
        if epic_tasks:
            for i in range(len(epic_tasks)):
                key_id[epic_key][epic_tasks[i][0]] = {}

                #check code files under a epic's task...
                common_func.print_border()
                issue_id = epic_tasks[i][1]
                list_of_files = self.process_files_under_a_task(epic_tasks[i][0], issue_id, fp)
                
                for task_det in self.get_task_details(epic_tasks[i][0])['fields']['subtasks']:
                    key_id[epic_key][epic_tasks[i][0]][task_det['key']] = task_det['id']
                    
                    #check code files under a epic's task...
                    issue_id = task_det['id']
                    common_func.print_border()
                    list_of_files = self.process_files_under_a_task(task_det['key'], issue_id, fp)
        else:
            if var.in_debug_mode:
                print('no tasks under epic')
        return

    def process_internal_defect(self, task_ref, task_details, parent_task_type,fp):
        if var.in_debug_mode:
            print('processing {}'.format(parent_task_type))
        self.process_task(task_ref, task_details, None, fp)
        return

    def process_sub_task(self, task_ref, issue_id, task_details, parent_task_type, fp):
        common_func.print_border()
        if var.in_debug_mode:
            print(colorful.green('processing {}          : {}'.format('sub task', task_ref)))
        list_of_files = self.process_files_under_a_task(task_ref, issue_id, fp)
        return

    def process_task(self, task_ref, task_details, parent_task_type, fp):
        
        if parent_task_type and var.in_debug_mode:
            print('processing {}'.format(parent_task_type))
            
        if not(task_details):
            task_details = self.get_task_details(task_ref)

        sub_tasks = common_func.get_sub_tasks(task_details)

        if not(sub_tasks) and var.in_debug_mode:
            print('No sub tasks found !!!')
            exit()

        for sub_task in sub_tasks:
            #process each sub tasks...
            self.process_sub_task(sub_task[0], sub_task[1], None, 'Sub Task', fp)
        
        return
    
    #-----core functions--------------------------------------------------------------------
    
    def process_files_under_a_task(self, task_ref, issue_id, file_ptr):

        #get issue id if it not there
        if var.in_debug_mode:
            print('Getting files for task ref   :', task_ref)
            
        if not(issue_id.isnumeric()) or not(issue_id):
            task_det = self.get_task_details(task_ref)
            issue_id = task_det['self'].split('/')[-1]
            if var.in_debug_mode:
                print(colorful.red('Invalid Id found !!!'))
                print('Getting correct issue id     :', issue_id)
                
        if var.in_debug_mode:
            print('valid id                     :', issue_id)
        #get files under task
        
        url = var.url_for_commits_by_task_ref.format(issue_id)
        
        try:
            commit_data_for_a_task = common_func.get_api_response(url, self.username, self.password)
        except Exception as e:
            print(e)
            exit()

        self.process_list_of_files(file_ptr, commit_data_for_a_task, task_ref)

        self.tot_processed_tasks.append(task_ref)

        #if not(var.in_debug_mode):
            #print('{}{}'.format(colorful.blue('>'), task_ref))
            
        return 

    def get_issues_for_epic(self, epic_key, task_details):
        issue_data = []

        #get sub_tasks also...
        if 'subtasks' in task_details['fields'].keys():
            for sub_task in task_details['fields']['subtasks']:
                issue_data.append([sub_task['key'], sub_task['id']])
        
        query = "'{}' = {}".format(var.epic_query, epic_key)
        
        try:
            data     = self.jira.jql(jql=query, limit=var.max_limit)
            issue_id = self.get_task_details(epic_key)['self'].split('/')[-1]
            
        except Exception as e:
            print(e)
            pass

        for idx, issue in enumerate(data['issues']):
            issue_data.append([data['issues'][idx]['key'] ,data['issues'][idx]['self'].split('/')[-1]])
            
        return issue_id, issue_data
    
    def get_task_details(self, task_ref):
        try:
            task_details = self.jira.issue(task_ref)
        except Exception as e:
            print(colorful.red('Err @__jira__ :'), e, '\n')
            return []
        return task_details

    def process_list_of_files(self, file_ptr, commit_data_for_a_task, task_ref):
        
        for data in commit_data_for_a_task["detail"]:
            
            if data['repositories']:
                
                if var.in_debug_mode:
                    
                    print('Chnage set found for task    : {}'.format(colorful.blue(task_ref)))
                
                if task_ref not in self.tot_coding_or_scripting_tasks:
                    self.tot_coding_or_scripting_tasks.append(task_ref)
                    
                for req_data in data['repositories']:
                    
                    for file_data in req_data['commits']:
                        
                        #print('commit reference :', file_data['displayId'])
                        #print(file_data)
                        commit_reference = file_data['id']
                        
                        if var.in_debug_mode:
                            print(colorful.yellow('total file count             :'), file_data['fileCount'])
                            print(colorful.yellow('Commit Reference             :'), commit_reference)
                                                        
                        url_data = re.sub(var.url_filter_re_left_regex, '', file_data['url'])
                        url_data = re.sub(var.url_filter_re_middle, ',', url_data)
                        url_data = re.sub(var.url_filter_re_right_regex, '', url_data)
                        url_data = url_data.split(',')

                        project = url_data[0]
                        repo    = url_data[-1]

                        change_set_url = var.change_set_from_commit.format(project, repo, commit_reference, 'changes')

                        pr_url         = var.change_set_from_commit.format(project, repo, commit_reference, 'pull-requests')

                        change_set = common_func.get_api_response(change_set_url, self.username, self.password)

                        code_change, change_set_count = common_func.get_code_changes(change_set)
                        if not(change_set_count):
                            continue

                        pr_det     = common_func.get_api_response(pr_url, self.username, self.password)

                        pr_status, from_ref, to_Ref, code_reviewers = common_func.extract_from_det(pr_det)
                        
                        if var.in_debug_mode:
                            if not(to_Ref) and not(from_ref) and not(to_Ref):
                                print(colorful.purple('No PR Found !!!'))
                            else:
                                print(colorful.purple('PR DET --->'), '( Pr status :', pr_status, ')', '( from ref :', from_ref, ')', '( to Ref :', to_Ref, ')')
                            for IDX, file in enumerate(change_set["values"]):
                                component    = file["path"]["components"][0]
                                changes_file = file["path"]["components"][-1]
                                print(IDX, component, changes_file)
                                
                        I_O.write_output_file(file_ptr, task_ref, commit_reference, code_change, change_set_count, pr_status, from_ref, to_Ref, code_reviewers)

            else:
                if var.in_debug_mode:
                    print('No Chnage set found for task : {}'.format(colorful.red(task_ref)))
                if task_ref not in self.tot_tasks_without_changes:
                    self.tot_tasks_without_changes.append(task_ref)
                    
            
        return 
    
    
    
