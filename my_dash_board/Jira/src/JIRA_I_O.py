import var
import colorful
import os
import re
import common_func
import xml.etree.ElementTree as ET
import requests
from requests.auth import HTTPBasicAuth
import json
from var import credential_validation, jira_url

def read_ref_file():
    
    data = []
    ref_file = os.path.dirname(__file__) + '\\Data\\Reference.txt'
    if not(os.path.exists(ref_file)):
        return data
    with open(ref_file, 'r', encoding='UTF-8') as fp:
        tmp_data = fp.read().split('\n')
        fp.close()
    for task in tmp_data:
        if task:
            data.append(task)

    return data

def get_input_from_user(jira_id):
    # jira_id = input(colorful.green('Enter Jira Key :'))

    #os.system('cls')

    find_parent = False
    
    if len(jira_id.split('~')) <= 1:
        if not(re.search(var.input_regex_0, jira_id)):
            print(colorful.red('Err @I_O :'), 'Invalid Input')
            return None, None
        jira_id = common_func.remove_white_space_fb(jira_id)
        
    else:
        if not(re.search(var.input_regex_1, jira_id)):
            print(colorful.red('Err @I_O :'), 'Invalid Input')
            return None, None

        jira_task   = jira_id.split('~')[0]

        resolve_hierachy = jira_id.split('~')[1]
        
        jira_id = common_func.remove_white_space_fb(jira_task)
        
        resolve_hierachy = common_func.remove_white_space_fb(resolve_hierachy)

        if resolve_hierachy == 'SEARCH.PARENT':
            find_parent = True
            
    return jira_id, find_parent

def update_headers(file_ptr):

    column_idx = ''

    column_idx += 'Task Reference,'

    column_idx += 'Commit Rference,'

    column_idx += 'Component,'

    column_idx += 'Artifacts,'

    column_idx += 'State,'

    #column_idx += 'From Ref,'

    column_idx += 'Release,'

    column_idx += 'Code Reviewers'
    
    file_ptr.write('{}\n'.format(column_idx))
    
    return


def write_output_file(file_ptr, Task_Ref, Commit_Ref, code_change, change_set_count, pr_status, from_ref, to_Ref, code_reviewers):

    write_str = ''
    
    while change_set_count:
                    
        component = 'unable to fetch component'
        if len(code_change[change_set_count - 1]) > 1:
            component = code_change[change_set_count - 1][0]
        path = ''
                    
        if len(code_change[change_set_count - 1]) > 2:
            for ele in code_change[change_set_count - 1][1 : len(code_change[change_set_count - 1]) - 1]:
                path += ele
                path += '/'
            path = path.rstrip('/')

        if not(path):
            path = 'path missing'
                
        file = code_change[change_set_count - 1][-1].replace(',', ';')

        write_str = '{}, {}, {}, {}, {}, {}, {}\n'.format(Task_Ref, Commit_Ref, component, file, pr_status, to_Ref, code_reviewers)
                
        file_ptr.write(write_str)
        
        change_set_count -= 1
            
    return



def create_new_configurations_file():
        try:
            print(colorful.yellow('Enter Your Valid Jira login credentials >\n'))
            root = ET.Element('configurations')

            UserName = ET.SubElement(root, 'UserName')
            UserName.text = ''
            tmp = input('Enter User name :')
            if tmp:
                UserName.text = common_func.remove_white_space_fb(tmp)

            Password = ET.SubElement(root, 'Password')
            Password.text = ''
            tmp = input('Enter Password  :')
            if tmp:
                Password.text = common_func.remove_white_space_fb(tmp)
            #print(UserName.text, Password.text)
            if not(UserName.text) or not(Password.text):
                print(colorful.red('\nErr @__CONFIG : Invalid Credentials !!!\n'))
                exit()
                
            tree = ET.ElementTree(root)
            os.system('cls')

            save_loc = os.getcwd()
            os.chdir(os.path.dirname(__file__) + '\\Data')
            tree.write('Configurations.xml')
            os.chdir(save_loc)
            
        except Exception as e:
            print(colorful.red('\nErr @__CONFIG :'),'Problem occured while creating the file !!!')
            print(e, '\n')
            exit()
        return

def validate_credentials(username, password):

    url = f"{jira_url.rstrip('/')}/rest/api/1.0/users/{username}"

    try:
        response = requests.get(
            url,
            auth=HTTPBasicAuth(username, password),
            timeout=10
        )

        if response.status_code != 200:
             err_msg = ""
             err_dets = json.loads(response.text)
             if 'errors' in err_dets:
                for err_det in err_dets['errors']:
                    err_msg += f'{err_det["message"]}\n'
             raise Exception(err_msg)

        return True, None

    except Exception as e:
        return False, str(e)

def jira_create_new_configurations_file_browser_version(u_name, password):
        try:
            print(colorful.yellow('Updating Jira login credentials >\n'))
            root = ET.Element('configurations')

            UserName = ET.SubElement(root, 'UserName')
            UserName.text = ''
            tmp = u_name
            if tmp:
                UserName.text = common_func.remove_white_space_fb(tmp)

            Password = ET.SubElement(root, 'Password')
            Password.text = ''
            tmp = password
            if tmp:
                Password.text = common_func.remove_white_space_fb(tmp)
            #print(UserName.text, Password.text)
            if not(UserName.text) or not(Password.text):
                print(colorful.red('\nErr @__CONFIG : Invalid Credentials !!!\n'))
                exit()
            else:
                credentials_check, err_msg = validate_credentials(UserName.text, Password.text)
                if err_msg and credential_validation:
                    return False, err_msg
                
            tree = ET.ElementTree(root)
            os.system('cls')

            save_loc = os.getcwd()
            os.chdir(os.path.dirname(__file__) + '\\Data')
            tree.write('Configurations.xml')
            os.chdir(save_loc)
            
        except Exception as e:
            print(colorful.red('\nErr @__CONFIG :'),'Problem occured while creating the file !!!')
            print(e, '\n')
            exit()
        return

def read_credentials_file():

        if not(os.path.isdir(os.path.dirname(__file__) + '\\Data')):
            os.mkdir(os.path.dirname(__file__) + '\\Data')
            
        configurations_file = os.path.dirname(__file__) + '\\Data\\Configurations.xml'
        if not(os.path.exists(configurations_file)):
            create_new_configurations_file()
            
        #tree = ET.parse('Configurations.xml')
        tree = ET.parse(configurations_file)

        if not(len(list(tree.getroot())) == 2):
            os.remove(configurations_file)
            create_new_configurations_file()
            #tree = ET.parse('Configurations.xml')
            tree = ET.parse(configurations_file)
        
        metadata = {}

        temp_str = ''
        #print(list(tree.getroot()))
        for ele in list(tree.getroot()):
            #print(ele)
            data = common_func.remove_white_space_fb(ele.text)
            metadata[ele.tag] = data

        username = ''
        password = ''
        try:
            username = metadata['UserName']
            password = metadata['Password']
        except:
            if not(os.path.exists(configurations_file)):
                os.remove(configurations_file)
            print('try again !!!')
            exit()

        return username, password

