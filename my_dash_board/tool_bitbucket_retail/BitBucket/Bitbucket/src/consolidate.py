import os

current_path = os.path.dirname(__file__)

os.chdir(current_path)

os.chdir('..')

run_details_path = os.getcwd() + '\\Run_Details'

output_file_name = run_details_path + '\\consolidated.csv'

if os.path.exists(output_file_name):
    os.remove(output_file_name)

if os.path.isdir(run_details_path):

    os.chdir(run_details_path)
    
    path = os.getcwd()
    
    write_file = open( output_file_name , 'w', encoding = 'utf-8' )

    write_file.write('Run Tag,Commit Reference,Task Refrence,Parent Reference,Parent Type,Description,Component,Artifacts,Owner,Reviewers\n')
    
    file_path = os.listdir( path )

    copy = False
    
    for file in file_path:

        if file != 'consolidated.csv':
            
            print('copying from :', file)
            
            fpt = open(path + '\\' + file, encoding='utf-8')

            file_rec = fpt.read().split('\n')

            copy = True
            
            for idx, ele in enumerate(file_rec):        
                if idx != 0 and ele:
                    write_file.write(ele)
                    write_file.write('\n')

    if not(copy):
        print('No file found', '\n')
        exit()
    write_file.close()


else:
    print('No Directory found in name "Run_Details"', '\n')
    exit()

