from atlassian import Bitbucket
from atlassian import Jira
from datetime import datetime
from datetime import datetime as dt
from pathlib import Path
import xml.etree.ElementTree as ET
import calendar
import os
import re
import requests
import time
import colorful
import json
import output_csv
import __CONFIG__
from response_handler import Response
import common_var

class bitbucket:
    
    def __init__(self):
        
        self.bitbucket_url       = common_var.bitbucket_url
        self.jira_url            = common_var.jira_url
        self.dev_branch          = 'refs/heads/develop'
        self.username            = ''
        self.password            = ''
        self.commit_timestamp    = ''
        self.file_ptr            = ''
        self.username            = ''
        self.password            = ''
        self.update_pr_details   = ''
        self.add_code_changes    = ''
        self.add_parent_details  = ''
        self.add_repo            = False
        self.retail_modules_fpt  = ''
        self.retail_modules      = []
        self.projects            = []
        self.project_fpt         = ''
        self.split_char_for_rf   = ','
        self.get_data_since      = '' #start from tag
        self.get_data_until      = '' #end till tag/dev branch
        self.idx_for_tag         = -1
        self.url                 = self.bitbucket_url + 'rest/api/1.0/projects/{}/repos/{}/commits/{}/{}?limit=100000'
        self.get_commits         = []
        self.commit_file_path    = ''
        self.mutiple_tag_process = True
        self.recent_tags         = []
        self.list_of_tags        = []
        self.range_val           = ''
        self.from_range          = ''
        self.to_range            = ''
        self.tag_idx             = ''
        self.update_tag_details  = False
         
        return

    def define_api_conn(self):
        try:
            self.jira               = Jira(self.jira_url, self.username, self.password)
            self.bitbucket          = Bitbucket(self.bitbucket_url, self.username, self.password)
            return Response("INFO", ["connection defined"], None)
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], None)

    def add_file_sequence(self, fp):
        try:
            initial_seq = 1
            file_not_found = 1
            while file_not_found:
                fp_path = fp
                seq = '#{}'.format(initial_seq)
                fp_path += seq
                fp_path += common_var.file_extention
                if Path(fp_path).exists():
                    initial_seq += 1
                else:
                    file_not_found = 0
            return Response("INFO", [f"file sequences added; current sequence {seq}"], fp_path)
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], None)
    
    def run_output_dir(self):
        try:
            os.chdir(os.path.dirname(__file__))
            os.chdir('..')
            commit_dir = str(os.getcwd()) + '\\' + 'Run_Details'
            if not(os.path.isdir(commit_dir)):
                os.mkdir(commit_dir)
            return Response("INFO", [f"output directory found; Dir : {commit_dir}"], commit_dir)
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], None)
    
    def remove_white_space_fb(self,data):
        try:
            data = data.rstrip()
            data = data.lstrip()
            return data
        except Exception as e:
            return None
    
    def read_repositories_from_file(self):
        
        try:
            with open(common_var.retail_proj_repo_path, 'r') as f:
                self.retail_modules = list(json.load(f)["repositories"].keys())
            if len(self.retail_modules) > 0:
                return Response("INFO", [f"repositories read from dir : {common_var.retail_proj_repo_path}; success"], 1)
            else:
                return Response("INFO", ['No repositories.txt file exists .Action> continue with all repo\n'], 0)
        except Exception as e:
            return Response("ERROR", ['No repositories.txt file exists .Action> continue with all repo\n', "__Bitbucket__"], 0)
        
    def read_projects_from_file(self):
        try:
            with open(common_var.retail_proj_repo_path, 'r') as f:
                self.projects = list(json.load(f)["projects"].keys())
            if len(self.projects) > 0:
                return Response("INFO", [f"repositories read from dir : {common_var.retail_proj_repo_path}; success"], 1)
            else:
                return Response("INFO", ['No project.txt file exists .Action> continue with all projects\n'], 0)

        except Exception as e:
            return Response("ERROR", ['No repositories.txt file exists .Action> continue with all repo\n', "__Bitbucket__"], 0)
        
    def open_output_file(self):
        try:
            self.file_ptr = open(common_var.commits_file, 'w', encoding = 'utf-8')
            return Response("INFO", [f"csv file created for the session : {common_var.commits_file}; success"], 1)
        except Exception as e:
            return Response("ERROR", ['File is opened or used by some other process pls close the file and try again ! \n', "__Bitbucket__"], 0)
        

    def get_rest_api_response(self, project, repo, commit_id, command):
        try:
            url = self.url.format(project, repo, commit_id, command)
            response = requests.request(
                                        common_var.pr_method,
                                        url,
                                        headers = common_var.headers,
                                        auth = (self.username, self.password )
                                        )

            json_data = json.loads(response.content)
            return Response("INFO", ["api reponse fetched"], json_data)
        except Exception as e:
            return Response("ERROR", ['No repositories.txt file exists .Action> continue with all repo\n', "__Bitbucket__"], 0)

    
    def get_tag(self, project, repo, list_of_tags):
        try:
            if not(list_of_tags):
                list_of_tags = []
                all_tags = self.bitbucket.get_tags(project, repo, order_by = 'newest', filter='', limit=1000)
                
                option_tag_count = common_var.option_tag_count + 1

                self.recent_tags = []
                c = 0

                for tag_idx, tag in enumerate(all_tags):
                    tag_id = tag['displayId']
                    if re.search(common_var.dev_tag_re , tag_id):
                        c += 1
                        list_of_tags.append(tag_id)
                        option_tag_count -= 1
                    if not(option_tag_count):
                        break

                if list_of_tags:
                    list_of_tags.insert(0, self.dev_branch)
                return Response("INFO", ["required tags fetched successfully"], list_of_tags)
        except Exception as e:
            return Response("ERROR", ['No repositories.txt file exists .Action> continue with all repo\n', "__Bitbucket__"], [])
    
            
    def get_project(self):
        # if not(self.range_val) and not(self.from_range) and not(self.to_range) and not(self.tag_idx):
            # print(colorful.yellow('\n{}*** GETTING LATEST TAGS ***'.format('\t'*7)))
        #if the FLAG ( retail_specific ) enabled ,  avoid online data retreival
        try:
            if common_var.retail_specific:
                project_list = [{'key' : 'T24-PRODUCT-CORE'}, {'key' : 'T24-PRODUCT-SCRIPTS'}]
            else:
                project_list = self.bitbucket.project_list()
            return Response("INFO", ["projects list selected"], project_list)
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], None)
    
    
    def format_date(self, time_stamp):
        try:
            self.commit_timestamp   = datetime.fromtimestamp(time_stamp / 1000)
            timestamp               = str(self.commit_timestamp).split()
            date                    = str(timestamp[0]).split('-')[2]
            month                   = calendar.month_name[int(timestamp[0].split('-')[1])]
            year                    = str(timestamp[0]).split('-')[0]
            time                    = timestamp[1]
            use_ful_time            = '{}-{}-{}'.format(date, month, year)
            return use_ful_time
        except Exception as e:
            return None
    
    def get_repositories(self, project_key):
        try:
            if common_var.retail_specific:
                repo_list = []
                if project_key == "T24-PRODUCT-CORE":
                    repos = common_var.t24_product_core_repo
                elif project_key == "T24-PRODUCT-SCRIPTS":
                    repos = common_var.t24_product_scripts_repo
                for repo in repos.split(','):
                    val = self.remove_white_space_fb(repo)
                    repo_list.append({'name' : val})
            else:
                repo_list = self.bitbucket.repo_list(project_key)
            return Response("INFO", ["success"], repo_list)
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], [])

    def close_output_file(self):
        try:
            self.file_ptr.close()
            return Response("INFO", [f"{self.file_ptr} :file closed"], None)
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], None)
    
    def get_all_commits(self, project, repo, Since, Until):
        
        try:
            commits = list(self.bitbucket.get_commits(project, repo, merges='include', limit=1000, since=Since, until=Until))
            total_commit_current = 0
            for commit in commits:
                self.get_commits.append(commit['id'])
                total_commit_current += 1
            return Response("INFO", [f"commit on task fetched successfully; total commits {total_commit_current}"], commits)
        except Exception as e:
            return Response("ERROR", ['current tag not available', "__Bitbucket__"], [])

    def extract_from_det(self, pr, commit_id):
        try:
            reviewers = ''
            merge_dt  = ''
            for values in pr["values"]:
                for reviewer_data in values["reviewers"]:
                    if reviewer_data["status"] == "APPROVED":
                        try:
                            reviewers += reviewer_data["user"]["displayName"]
                        except:
                            reviewers += reviewer_data["user"]["name"]
                        reviewers += common_var.reviewers_sep
                merge_dt = self.format_date(values["updatedDate"])
            reviewers = reviewers.rstrip(common_var.reviewers_sep)
            return Response("INFO", [f"details parsed from pull request for commit {commit_id}"], [reviewers, merge_dt])
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], [])

    def get_code_changes(self, project, repo, commit_ref, change_set):
        try:
            code_changes = []
            count = 0
            pr_det = None
            for code_component in change_set["values"]:
                chg_set = code_component["path"]["components"]
                if len(chg_set) == 1:                                                                      # indicates there is no component present in the commit ( instead only file is changes file is present )
                    try:
                        pr_det = self.get_rest_api_response(project, repo, commit_ref, 'pull-requests')    # so need to call api to get component
                        if "values" in pr_det.keys():
                            chg_set.insert(0, pr_det["values"][0]["fromRef"]["repository"]["name"])
                    except Exception as e:
                        print(colorful.red('component missing in commit !'), 'exception on fetching component @PR', '\nActual MSG :', e)
                        pass
                #code_changes.append(chg_set)
                code_changes.append({'change_set' : chg_set, 'type' : code_component['type']})
                count += 1
            return Response("INFO", ["details parsed from pull request"], [ code_changes, count, pr_det])
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], [])
    
    def is_parent(self, list_of_keys):
        if 'parent' in list_of_keys:
            return True
        else:
            return False

    def has_epic(self, val):
        if not(val['customfield_10000']):
            return False
        else:
            return True

    def get_parent_type(self, task_ref, recurr_flag):
        
        current_ref = task_ref
        current_task_type = ''
        parent_ref = ''
        parent_task_type = ''
        immediate_parent = ''
            
        try:
            #get jira issue status
            jira = Jira(url=self.jira_url, username=self.username, password=self.password)
            task_details      = jira.issue(task_ref)
            current_task_type = task_details['fields']['issuetype']['name']
            try:
                if 'parent' in task_details['fields']:
                    parent_ref = task_details['fields']['parent']['key']
                    parent_task_data = jira.issue(parent_ref)
                    parent_task_type = parent_task_data['fields']['issuetype']['name']
                    if not(immediate_parent):
                        immediate_parent = parent_ref
                        immediate_parent_type = parent_task_type
                else:
                    if recurr_flag:
                        if task_details['fields']['customfield_10000']:
                            parent_ref = task_details['fields']['customfield_10000']
                            parent_task_data = jira.issue(parent_ref)
                            parent_task_type = parent_task_data['fields']['issuetype']['name']
                        else:
                            if not(parent_ref) or not(parent_task_type):
                                #when there is nor parent references or parent task type then determine that current reference will be the top on hierachy
                                #return current task details.
                                return current_ref, current_task_type
                if parent_task_type == "Internal Defect" or recurr_flag:
                    #recursive call to get top most parent
                    parent_ref, parent_task_type = self.get_parent_type(parent_ref, True)
                    
                    if immediate_parent:
                        parent_ref = immediate_parent
                        if parent_task_type == 'Epic':
                            parent_task_type = immediate_parent_type + ' - ' + parent_task_type
                    
            except Exception as e:
                pass

        except Exception as e:
            parent_ref = e
            pass

        return parent_ref, parent_task_type
    
    def process_commit_pr_details(self, project, repo, since, until):
        try:
            run_idx = ''
            if self.mutiple_tag_process or self.update_tag_details:
                if until == self.dev_branch:
                    run_idx = 'CURRENT.DEV.PRI'
                else:
                    run_idx = until
            
            commit_pr_details = {}
            tmp = {}
            response = self.get_all_commits(project, repo, since, until)
            all_commits = response["data"]
            for commit in all_commits:
                
                commit_id           = commit['displayId']
                try:
                    author          = commit['author']['displayName']
                except:
                    author          = commit['author']['name']
                committer           = commit['committer']['name']
                committerTimestamp  = commit['committerTimestamp']
                commiterTime        = self.format_date(committerTimestamp)
                commit_msg          = commit['message'].replace(',',';')
                authorTimestamp     = commit['authorTimestamp']
                auth_time           = self.format_date(authorTimestamp)
                parent_task_type    = ''
                parent_task_ref     = ''
                
                if 'properties' in commit.keys():
                    task_id = commit['properties']['jira-key'][0]
                    if self.add_parent_details:
                        parent_task_ref, parent_task_type = self.get_parent_type(task_id, False)
                else:
                    task_id = 'No properties Available'

                if task_id not in tmp:
                    tmp[task_id] = 0
                else:
                    tmp[task_id] += 1

                code_change = ''
                change_set_count = 0
                
                if self.add_code_changes:
                    response = self.get_rest_api_response(project, repo, commit['id'], 'changes')
                    change_set = response["data"]
                    response = self.get_code_changes(project, repo, commit['id'], change_set)
                    code_change, change_set_count, pr_det = response["data"]
                if code_change:
                    write_count = change_set_count
                commit_msg = commit_msg.replace('\n', '')

                reviewers = ''
                pr = ''
                if self.update_pr_details:
                    if self.add_code_changes:
                        if pr_det:
                            pr = pr_det
                    if not(pr):
                        response = self.get_rest_api_response(project, repo, commit['id'], 'pull-requests')
                        pr = response["data"]
                    response = self.extract_from_det(pr, commit['id'])
                    reviewers, pr_merge_time = response["data"]
                output_csv.write_output_file(self.file_ptr, self.update_tag_details, self.add_repo, self.add_parent_details, self.update_pr_details, self.mutiple_tag_process, self.add_code_changes, change_set_count, code_change, commit_id, task_id, parent_task_ref, parent_task_type, commit_msg, author, reviewers, pr_merge_time, run_idx, repo)
            return Response("INFO", ["required details parsed successfully"], None)
        except Exception as e:
            return Response("ERROR", [str(e), "__Bitbucket__"], None)
    
