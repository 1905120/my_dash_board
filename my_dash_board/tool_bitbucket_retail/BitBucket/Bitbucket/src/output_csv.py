
import csv


def update_headers(file_ptr, add_repo, update_pr_details, add_code_changes, add_parent_details, mutiple_tag_process, update_tag_details):

    try:
        column_idx = ''
        column_idx_row = []

        if update_tag_details:

            column_idx += 'Run Tag,'
            column_idx_row.append('Run Tag')

        if add_repo:

            column_idx += 'Repo,'
            column_idx_row.append('Repo')

        column_idx += 'Commit Reference,'
        column_idx_row.append('Commit Reference')

        column_idx += 'Task Refrence,'
        column_idx_row.append('Task Refrence')

        if add_parent_details:
            
            column_idx += 'Parent Reference,'
            column_idx_row.append('Parent Reference')
            
            column_idx += 'Parent Type,'
            column_idx_row.append('Parent Type')

        column_idx += 'Description,'
        column_idx_row.append('Description')

        if add_code_changes:
        
            column_idx += 'Component,'
            column_idx_row.append('Component')

            column_idx += 'Artifacts,'
            column_idx_row.append('Artifacts')

        column_idx += 'Owner,'
        column_idx_row.append('Owner')

        if update_pr_details:

            column_idx += 'Reviewers,'
            column_idx_row.append('Reviewers')

            column_idx += 'Merge time,'
            column_idx_row.append('Merge time')
        
        with open(file_ptr, "a", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(column_idx_row)
        # file_ptr.write('{}\n'.format(column_idx))
    except Exception as e:
        print('Err @output_csv :', str(e))
    
    return


def write_output_file(file_ptr, update_tag_details, add_repo, add_parent_details, update_pr_details, mutiple_tag_process, add_code_changes, change_set_count, code_change, commit_id, task_id, parent_task_ref, parent_task_type, commit_msg, author, reviewers, pr_merge_dt, run_idx, repo):
    try:
        write_str1 = ''
        write_str1_list = []

        write_str2 = ''
        write_str2_list = []

        

        if update_tag_details:
            
            write_str1 += '{},'.format(run_idx)
            write_str1_list.append(run_idx)

        if add_repo:

            write_str1 += '{},'.format(repo)
            write_str1_list.append(repo)

        write_str1 += '{},'.format(commit_id)
        write_str1_list.append(commit_id)

        write_str1 += '{},'.format(task_id)
        write_str1_list.append(task_id)

        if add_parent_details:
            
            write_str1 += '{},'.format(parent_task_ref)
            write_str1_list.append(parent_task_ref)

            write_str1 += '{},'.format(parent_task_type)
            write_str1_list.append(parent_task_type)

        write_str1 += '{},'.format(commit_msg)
        write_str1_list.append(commit_msg)

        write_str2 += '{},'.format(author)
        write_str2_list.append(author)

        if update_pr_details:

            write_str2 += '{},'.format(reviewers)
            write_str2_list.append(reviewers)

            write_str2 += '{},'.format(pr_merge_dt)
            write_str2_list.append(pr_merge_dt)

        with open(file_ptr, "a", newline="") as f:
            writer = csv.writer(f)
            if add_code_changes:
                        
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
                    write_str_list = []
                    write_str_list.extend(write_str1_list)
                    write_str_list.append(component)
                    write_str_list.append(file)
                    write_str_list.extend(write_str2_list)

                    write_str = '{} {}, {}, {}\n'.format(write_str1, component, file, write_str2)
                    # write_str_list
                    # file_ptr.write(write_str)
                    writer.writerow(write_str_list)
                    change_set_count -= 1
            else:
                write_str_list = []
                write_str_list.extend(write_str1_list)
                write_str_list.extend(write_str2)
                write_str = '{} {}\n'.format(write_str1, write_str2)

                # with open(file_ptr, "a", newline="") as f:
                
                writer.writerow(write_str)
    except Exception as e:
        print('Err @output_csv :', str(e))
        
    return
