
import xml.etree.ElementTree as ET
import os
import colorful

def remove_white_space_fb(data):
    data = data.rstrip()
    data = data.lstrip()
    return data

def create_new_configurations_file():
        try:
            print(colorful.yellow('Enter Your Valid Bitbucket login credentials >\n'))
            root = ET.Element('configurations')

            UserName = ET.SubElement(root, 'UserName')
            UserName.text = ''
            tmp = input('Enter User name :')
            if tmp:
                UserName.text = remove_white_space_fb(tmp)

            Password = ET.SubElement(root, 'Password')
            Password.text = ''
            tmp = input('Enter Password  :')
            if tmp:
                Password.text = remove_white_space_fb(tmp)
            #print(UserName.text, Password.text)
            if not(UserName.text) or not(Password.text):
                print(colorful.red('\nErr @__CONFIG : Invalid Credentials !!!\n'))
                exit()
            AddReviewers = ET.SubElement(root, 'AddReviewers')
            AddReviewers.text = 'YES'
            AddCodeChanges = ET.SubElement(root, 'AddCodeChanges')
            AddCodeChanges.text = 'YES'
            AddCodeChanges = ET.SubElement(root, 'AddParentTaskDetails')
            AddCodeChanges.text = 'YES'

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

        configurations_file = os.path.dirname(__file__) + '\\Data\\Configurations.xml'
        if not(os.path.exists(configurations_file)):
            create_new_configurations_file()
            
        #tree = ET.parse('Configurations.xml')
        tree = ET.parse(configurations_file)

        if not(len(list(tree.getroot())) == 5):
            os.remove(configurations_file)
            create_new_configurations_file()
            #tree = ET.parse('Configurations.xml')
            tree = ET.parse(configurations_file)
        
        metadata = {}

        temp_str = ''
        #print(list(tree.getroot()))
        for ele in list(tree.getroot()):
            #print(ele)
            data = remove_white_space_fb(ele.text)
            metadata[ele.tag] = data

        username = ''
        password = ''
        try:
            username = metadata['UserName']
            password = metadata['Password']
        except:
            if not(os.path.exists(configurations_file)):
                os.remove(configurations_file)
        update_pr_details = True
        add_code_changes  = True
        add_parent_task_info = True
        add_repo_det = False
        
        try:
            if metadata['AddReviewers'].lower() == 'no' or (metadata['AddReviewers'].lower()) == 'n' :
                    update_pr_details = False
                    
            if metadata['AddCodeChanges'].lower() == 'no' or (metadata['AddCodeChanges'].lower()) == 'n':
                    add_code_changes = False
                    #add_repo_det     = True

            if metadata['AddParentTaskDetails'].lower() == 'no' or metadata['AddParentTaskDetails'].lower() == 'n':
                    add_parent_task_info = False

            #print(self.update_pr_details, self.update_pr_details)
        except Exception as e:
            pass
        #print(metadata)
        #exit()
                
        return username, password, True, True, True, True
