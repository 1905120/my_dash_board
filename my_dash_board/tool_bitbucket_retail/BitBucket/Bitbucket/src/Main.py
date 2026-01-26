# import __Bitbucket__
import sys
import os

# Add the src directory to Python path for local imports
_src_dir = os.path.dirname(os.path.abspath(__file__))
if _src_dir not in sys.path:
    sys.path.insert(0, _src_dir)

from Bitbucket import bitbucket
from datetime import datetime
import calendar
import colorful
import output_csv
import time
import __CONFIG__
import common_var
import socket
from response_handler import Response, check_continue_process

def build_file_name(bb, project, since_tag, until_tag, is_range):
    common_var.commits_file = '{}_commits details_{}_{}'
    tag = 'T24.DEV.{}.PRI'
    if until_tag == bb.dev_branch:
        tag = tag.format('CURRENT')
    else:
        tag = tag.format(until_tag.split('.')[2])
    tmp = str(datetime.today().strftime('%Y-%m-%d')).split('-')
    year = tmp[0]
    month = int(tmp[1])
    date = tmp[2]
    formated_date = '{}-{}-{}'.format(date, calendar.month_name[month][0 : 3], year)
    common_var.commits_file = common_var.commits_file.format(project, formated_date, tag)
    response = bb.run_output_dir()
    if not check_continue_process(response):
        return response
    else:
        response = bb.run_output_dir()
        common_var.commits_file = '{}\\{}'.format(response["data"], common_var.commits_file)
        #common_var.commits_file = bb.add_file_sequence(common_var.commits_file)
        response = bb.add_file_sequence(common_var.commits_file)
        if not check_continue_process(response):
            return response
        else:
            bb.file_ptr = common_var.commits_file = response["data"]
    return Response("INFO", ["File name built for the session"], response["data"])

def process_commit_details(bb, input_proj ,input_repos, list_of_tags):
    try:
        total_repo_to_check                  = []
        total_proj_to_check                  = []
        processed_repo                       = []
        total_repositories_in_all_proj       = []
        
        #input_proj ,input_repos = I_O.get_projects_and_repo_from_input()

        if not(input_repos) and not(input_proj):
            response = bb.read_repositories_from_file()
            if check_continue_process(response):
                total_repo_to_check.extend(bb.retail_modules)
            response = bb.read_projects_from_file()
            if check_continue_process(response):
                total_proj_to_check.extend(bb.projects)
        elif input_repos and not(input_proj):
            response = bb.read_projects_from_file()
            if check_continue_process(response):
                total_proj_to_check.extend(bb.projects)
            total_repo_to_check.extend(input_repos)
        elif not(input_repos) and input_proj:
            response = bb.read_repositories_from_file()
            if check_continue_process(response):
                total_repo_to_check.extend(bb.retail_modules)
            total_proj_to_check.extend(input_proj)
        else:
            total_repo_to_check.extend(input_repos)
            total_proj_to_check.extend(input_proj)

        #print(total_proj_to_check, '\n', total_repo_to_check)

        #get all projects from BB
        response = bb.get_project()
        if not check_continue_process(response):
            return Response("ERROR", [str(e), "Main"], [None, None, None, None])
        else:
            project_list = response["data"]

        c = 0

        #loop through the projects
        for project in project_list:
            #print(project)
            if total_proj_to_check:
                if project['key'] not in total_proj_to_check:
                    continue
            #print(project['key'])
            response = bb.get_repositories(project['key'])
            repo_list = response["data"]
            #print(len(repo_list))
            #print('---------------------Searching in : {}---------------------'.format(project['key']))
            bb.dev_tag          = ''
            bb.get_data_since   = '' 
            bb.get_data_until   = ''

            bb.list_of_tags = []
            #loop through the repositories
            for repo in repo_list:

                name = repo['name']
                
                total_repositories_in_all_proj.append(name)
                
                if total_repo_to_check:
                    if name not in total_repo_to_check:
                        continue
                
                if not list_of_tags:
                    response = bb.get_tag(project['key'], name, list_of_tags)
                    if not check_continue_process(response):
                        return Response("ERROR", ["Unable to fetch tags"], [None, None, [], None])
                    else:
                        return Response("INFO", ["Tags Fetched successfully"], [None, None, response["data"], None])
                    
                print_repo = True

                if c == 0:
                    
                    response = build_file_name(bb, project['key'], list_of_tags[0][0], list_of_tags[0][1], 0)
                    if not check_continue_process(response):
                        return Response("ERROR", [f'Unable to built file name for the session; {response["error"]}'], [None, None, None, None])
                    # os.system('cls')
                    # if not(bb.open_output_file()):
                    #     return
                        
                    output_csv.update_headers(bb.file_ptr, bb.add_repo, bb.update_pr_details, bb.add_code_changes, bb.add_parent_details, bb.mutiple_tag_process, bb.update_tag_details )

                #print('>',name)
                
                for tag_pair in list_of_tags:

                    if len(tag_pair) != 2:
                        return Response("ERROR", ['Missing TAG !!!', "Main"], [None, None, None, None])

                    since = tag_pair[0]
                    until = tag_pair[1]
                            
                    if not(since) or not(until):
                        print('Skiping Project : ', project['key'])
                        break
                    
                    #print(since, '-', until)
                    
                    if since and until:
                        response = bb.process_commit_pr_details(project['key'], name, since, until)
                        processed_repo.append(name)
                        
                c += 1
                        
                        
        # bb.close_output_file()
        if total_repo_to_check:
            return Response("INFO", ["request processed"], [total_repo_to_check, processed_repo, [], bb.file_ptr])
        else:
            return Response("INFO", ["request processed"], [total_repositories_in_all_proj, processed_repo, [], bb.file_ptr])
    except Exception as e:
        return Response("ERROR", [str(e), "Main"], None)

def get_missed_repo(total_repo, processed_repo):
    print_one_time = True
    c = 0
    for repo in total_repo:
        if repo not in processed_repo:
            c += 1
            if print_one_time:
                print('\nNot Yet processed >')
            print('{}. {}'.format(c, colorful.red(repo)))
            print_one_time = False
    return


def init_process(bb):
    bb.username, bb.password, bb.update_pr_details, bb.add_code_changes, bb.add_parent_details, bb.add_repo = __CONFIG__.read_credentials_file()
    bb.define_api_conn()
    return
############################################## process start ########################################################


def Process_Bitbucket_Details(input_proj ,input_repos, list_of_tags):

        try:
            start_time  = time.time()
            bb = bitbucket()
            init_process(bb)
            response = process_commit_details(bb, input_proj ,input_repos, list_of_tags)
            end_time = time.time()
            msg = "Your Request processed in {} mins".format(str(round((end_time - start_time) / 60 , 2)))
            is_passed = check_continue_process(response)
            if not is_passed:
                raise Exception(response["error"])
            else:
                total_repo, processed_repo, list_of_tags, file_ptr = response["data"]
            return Response("INFO", [msg], [list_of_tags, file_ptr])
        except socket.error as err:
            try:
                erro_Det = err.response.json()
            except:
                erro_Det = {}
                err_msg = ""
            if 'errors' in erro_Det:
                for idx, ele in enumerate(erro_Det):
                    err_msg += str(erro_Det[ele][idx]['message'])
                return Response("ERROR", [err_msg, "Main"], [None, None])
            else:
                print(colorful.red('Err @Main :'),)
                return Response("ERROR", ['Please Check you NETWORK/VPN connection and try again !', "Main"], [None, None])
            
        except Exception as err:
            return Response("ERROR", [str(err), "Main"], [None, None])
