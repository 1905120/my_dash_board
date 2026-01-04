
import re

max_limit                   = 99999
jira_url                    = 'https://jira.temenos.com/'
unwanted_fields_re          = 'customfield.*'
unwanted_fields_pattern     = re.compile(unwanted_fields_re)
required_field              = 'fields'
epic_field                  = 'customfield_10000'
type_list                   = ['Internal Defect', 'Epic', 'Client Defect', 'Task', 'Story', 'Sub-task']
epic_query                  = 'Epic Link'
#url_for_pr_by_task_ref     = 'https://jira.temenos.com/rest/dev-status/latest/issue/detail?issueId={}&applicationType=stash&dataType=pullrequest'
url_for_commits_by_task_ref = 'https://jira.temenos.com/rest/dev-status/latest/issue/detail?issueId={}&applicationType=stash&dataType=repository'
headers                     = {"Accept": "application/json"}
jira_api_method             = 'GET'
input_re_0                  = '\\s*[A-Z]*-[0-9]+\\s*'
input_regex_0               = re.compile(input_re_0)
input_re_1                  = '\\s*[A-Z]*-[0-9]+\\s*~\\s*SEARCH.PARENT\\s*'
input_regex_1               = re.compile(input_re_1)
find_parent                 = False
in_debug_mode               = True
output_file                 = ''
output_file_extn            = '.csv'
url_filter_re_left          = '.*projects/'
url_filter_re_right         = '/commits.*'
url_filter_re_middle        = '/repos/'
url_filter_re_left_regex    = re.compile(url_filter_re_left)
url_filter_re_middle        = re.compile(url_filter_re_middle)
url_filter_re_right_regex   = re.compile(url_filter_re_right)
change_set_from_commit      = 'https://bitbucket.temenos.com/rest/api/1.0/projects/{}/repos/{}/commits/{}/{}?limit=' + str(max_limit)
reviewers_sep               = ' \\ '
multi_tasking_trigger_limit = 10
multi_thread_process        = False
req_file_types              = ['b', 'tut', 'd', 'json', 'component']
#req_file_types              = ['b']


