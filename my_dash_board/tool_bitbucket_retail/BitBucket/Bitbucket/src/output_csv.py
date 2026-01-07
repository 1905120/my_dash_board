
import csv


def update_headers(file_ptr, add_repo, update_pr_details, add_code_changes, add_parent_details, mutiple_tag_process, update_tag_details):
    try:
        column_idx = ''
        column_idx_row = []
        if update_tag_details:
            column_idx_row.append('Run Tag')
        if add_repo:
            column_idx_row.append('Repo')
        column_idx_row.append('Commit Reference')
        column_idx_row.append('Task Refrence')
        if add_parent_details:
            column_idx_row.append('Parent Reference')
            column_idx_row.append('Parent Type')
            column_idx_row.append('Art')
        column_idx_row.append('Description')
        if add_code_changes:
            column_idx_row.append('Component')
            column_idx_row.append('Artifacts')
            column_idx_row.append('Artifacts Extn')
            column_idx_row.append('Updated As')
        column_idx_row.append('Owner')
        if update_pr_details:
            column_idx_row.append('Reviewers')
            column_idx_row.append('Merge time')
        with open(file_ptr, "a", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(column_idx_row)
    except Exception as e:
        print('Err @output_csv :', str(e))
    
    return


def write_output_file(file_ptr, update_tag_details, add_repo, add_parent_details, update_pr_details, mutiple_tag_process, add_code_changes, change_set_count, changetset_details, commit_id, task_id, parent_task_ref, parent_task_type, commit_msg, author, reviewers, pr_merge_dt, run_idx, repo):
    try:
        write_str1_list = []
        write_str2_list = []
        if update_tag_details:
            write_str1_list.append(run_idx)
        if add_repo:
            write_str1_list.append(repo)
        write_str1_list.append(commit_id)
        write_str1_list.append(task_id)
        if add_parent_details:
            write_str1_list.append(parent_task_ref)
            write_str1_list.append(parent_task_type)
            write_str1_list.append(parent_task_ref.split("-")[0])
        write_str1_list.append(commit_msg)
        write_str2_list.append(author)
        if update_pr_details:
            write_str2_list.append(reviewers)
            write_str2_list.append(pr_merge_dt)
        with open(file_ptr, "a", newline="") as f:
            writer = csv.writer(f)
            if add_code_changes:
                while change_set_count:
                    code_change = changetset_details[change_set_count - 1]["change_set"]
                    updated_as = changetset_details[change_set_count - 1]["type"]
                    component = 'unable to fetch component'
                    if len(code_change) > 1:
                        component = code_change[0]
                    path = ''
                            
                    if len(code_change) > 2:
                        for ele in code_change[1 : len(code_change) - 1]:
                            path += ele
                            path += '/'
                        path = path.rstrip('/')

                    if not(path):
                        path = 'path missing'
                        
                    file = code_change[-1].replace(',', ';')
                    file_extn = 'COMMON' if file.startswith("I_") else file.split(".")[-1]
                    write_str_list = []
                    write_str_list.extend(write_str1_list)
                    write_str_list.append(component)
                    write_str_list.append(file)
                    write_str_list.append(file_extn)
                    write_str_list.append(updated_as)
                    write_str_list.extend(write_str2_list)

                    writer.writerow(write_str_list)
                    change_set_count -= 1
            else:
                write_str_list = []
                write_str_list.extend(write_str1_list)
                write_str_list.extend(write_str2_list)
                writer.writerow(write_str_list)
    except Exception as e:
        print('Err @output_csv :', str(e))
        
    return