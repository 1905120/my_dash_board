
import os
import colorful
import re
import common_var

def remove_white_space_fb(data):
    data = data.rstrip()
    data = data.lstrip()
    return data

def validate_int_input(value, input_limit):
    try:
        if value.isnumeric():
            value = int(value)
            if value <= input_limit and value >= 1:
                value -= 1
                return value
            else:
                raise 'Err'
        else:
            raise 'Err'
        
    except Exception as e:
        print(colorful.red('Err @I_O :'), 'Invalid Input!\n')
        exit()
    return

def get_user_selected_tag_idx(input_limit):

    
    range_val  = None
    from_range = None
    to_range   = None
    tag_idx    = []
    
    print(colorful.green('\n>'), colorful.yellow('For range inputs use "~" character to select from and to tag'))
    print(colorful.yellow('\t\t\t( OR )'))
    print(colorful.green('>'), colorful.yellow('Press Enter to receive tasks for upcoming acceptance'))
    print(colorful.yellow('\t\t\t( OR )'))
    print(colorful.green('>'), colorful.yellow('Select the Index of tag to receive details\n'))
    
    selected_tag_raw_input = input(colorful.green('Enter Your Option here : '))
    selected_tag = []

    multiple_process_flag = False

    update_run_tag        = False
    
    #validate input using regex
    flag1 = False
    flag2 = False
    flag3 = False
    flag4 = False

#------------------------------------------------------------------------------------------------------------------------------------------------------
    update_tag_details = False #update this flag ot add run details
#------------------------------------------------------------------------------------------------------------------------------------------------------    

    spl_char_validate = re.findall(common_var.spl_char_multi, selected_tag_raw_input)

    if len(spl_char_validate) > 2:
        print(colorful.red('Err I_O :'), 'Invalid Input ~\n')
        exit()

    strictly_multi_input = False
    if len(spl_char_validate) == 2:
        if not(len(re.findall(common_var.spl_char_single, selected_tag_raw_input))):
            print(colorful.red('Err I_O :'), 'Invalid Input ~\n')
            exit()
        else:
            strictly_multi_input = True
                                  
    if re.search(common_var.input_pattern_multi,  selected_tag_raw_input) or strictly_multi_input:
        flag1 = True
    elif re.search(common_var.input_pattern_single,  selected_tag_raw_input):
        if re.search(common_var.input_pattern_single_right, selected_tag_raw_input) or re.search(common_var.input_pattern_single_left, selected_tag_raw_input):
            flag2 = True
        else:
            print(colorful.red('Err :'), 'Invalid Input !\n')
            exit()
    elif re.search(common_var.unique_input_pattern,  selected_tag_raw_input):
        flag3 = True
    elif not(selected_tag_raw_input) or re.search(common_var.null_pattern, selected_tag_raw_input):
        flag4 = True
    else:
        print(colorful.red('Err :'), 'Invalid Input !\n')
        exit()
    
    #validate input
    if flag1:
        for input_val in selected_tag_raw_input.split('~~'):
            val = remove_white_space_fb(input_val)
            selected_tag.append(validate_int_input(val, input_limit))
        if len(selected_tag) != 2:
            print(colorful.red('Err :'), 'Invalid input !\n')
            exit()
        else:
            selected_tag.sort(reverse = True)
            from_range = selected_tag[0]
            to_range   = selected_tag[1]
            if from_range == to_range:
                return None, None, None, [from_range], multiple_process_flag, update_tag_details
            multiple_process_flag = True
    elif flag2:
        for input_val in selected_tag_raw_input.split('~'):
            val = remove_white_space_fb(input_val)
            if val.isalnum():
                selected_tag.append(val)

        update_tag_details = True
        
        if len(selected_tag) == 2 :
            from_range = validate_int_input(selected_tag[0], input_limit)
            to_range = validate_int_input(selected_tag[1], input_limit)
            if from_range < to_range:
                tmp = from_range
                from_range = to_range
                to_range = tmp
            elif from_range == to_range:
                return None, None, None, [from_range], multiple_process_flag, update_tag_details
            range_val = ( from_range - to_range ) + 1
                
        elif len(selected_tag) == 1:
            if re.search(r"^.*~.*[0-9]", selected_tag_raw_input):
                to_range = validate_int_input(selected_tag[0], input_limit)
                from_range = input_limit - 1
                range_val = ( from_range - to_range ) + 1
            else:
                from_range = validate_int_input(selected_tag[0], input_limit)
                tag_idx    = [-1]
                to_range   = 0
                range_val  = from_range
                
        else:
            #just call to throw error
            selected_tag = validate_int_input(selected_tag[0], input_limit)
        
    elif flag3:
        selected_tag = remove_white_space_fb(selected_tag_raw_input)
        tag_idx = [validate_int_input( selected_tag, input_limit )]
        
    elif flag4:
        tag_idx = [-1]

    return range_val, from_range, to_range, tag_idx, multiple_process_flag, update_tag_details

 
def get_projects_and_repo_from_input():

    print(colorful.green('Note : Enter below details with "," separated for multiple inputs>\n'))
    unformat_proj_data = None
    unformat_repo_data = None
    unformat_proj_data = input('Enter the Projects     :')
    unformat_repo_data = input('Enter the repositories :')
    os.system('cls')
    repo_list = []
    proj_list = []
    if unformat_repo_data and (re.search(common_var.valid_characters, unformat_repo_data)):
        repos = remove_white_space_fb(unformat_repo_data)
        if ',' in repos:
            for repo in repos.split(','):
                repo = remove_white_space_fb( repo )
                if not(re.search(common_var.null_pattern, repo)) and repo not in repo_list:
                    repo_list.append(repo)
        else:
            if not(re.search(common_var.null_pattern, repos)):
                repo_list.append(repos)

    if unformat_proj_data and (re.search(common_var.valid_characters, unformat_proj_data)):
        Proj = remove_white_space_fb(unformat_proj_data)
        if ',' in Proj:
            for proj in Proj.split(','):
                proj = remove_white_space_fb( proj )
                if not(re.search(common_var.null_pattern, proj)) and proj not in proj_list:
                    proj_list.append(proj)
        else:
            if not(re.search(common_var.null_pattern, Proj)):
                proj_list.append(Proj)

    return [proj_list, repo_list]
