# Add the src directory to Python path for local imports
import os, sys
_src_dir = os.path.dirname(os.path.abspath(__file__))
if _src_dir not in sys.path:
    sys.path.insert(0, _src_dir)

import time
import threading
import JIRA_I_O as I_O
import JIRA_Main as Main
import var
import queue
import colorful
import common_func
import __jira__
import var



class main:

    def __init__(self):
        self.job_count = 0
        self.current_process_list = []
        self.current_fp = None
        self.uname = None
        self.password = None
        return

    def job(self):
        job_id = self.job_count
        fp, job_id, tot_processed_tasks, tot_coding_or_scripting_tasks, tot_tasks_without_changes = Main.main(job_track, job_id, self.current_fp, self.current_process_list, True, self.uname, self.password)
        return

    def validate_mandatory_data(self):
        u_name, password = I_O.read_credentials_file()
        if not(password) or not(u_name):
            print('Invalid credentials !!!')
            exit()
        self.uname = u_name
        self.password = password
        return

    def worker(self, worker_id, task_queue):
        while True:
            try:
                task = task_queue.get()   # ⏳ blocks until item is available
                if task is None:
                    break                 # 🛑 shutdown signal
                print(f"Worker {worker_id} processing: {task}")
                time.sleep(1)             # simulate work
            finally:
                task_queue.task_done()

    def start_workers(self, num_threads, task_queue):
        threads = []
        for i in range(num_threads):
            t = threading.Thread(target=self.worker, args=(i, task_queue), daemon=True)
            t.start()
            threads.append(t)
        return threads

    def initiate_threads(self, task_queue, data):
        
        no_of_tasks_per_process = var.multi_tasking_trigger_limit
        print('total task to process     : {}'.format(len(data)))
        total_job = len(data) / no_of_tasks_per_process
        if len(data) % no_of_tasks_per_process and round(total_job) < total_job:
            total_job = round(total_job) + 1
        else:
            total_job = round(total_job)
        print('spliting into sub process : ', total_job)
        self.start_workers(total_job, task_queue)
        return total_job, no_of_tasks_per_process

    def pre_process(self, data):
        task_queue = queue.Queue()
        total_job, no_of_tasks_per_process = self.initiate_threads(task_queue, data)
        list_of_fp = []
        prev_file_seq = 0
        jira_count = 0
        start_idx = 0
        while total_job:
            end_idx = start_idx + no_of_tasks_per_process
            if end_idx > len(data):
                end_idx = len(data)
            file_pointer, prev_file_seq = common_func.build_file_name(None, None,  static_count - total_job, prev_file_seq)
            list_of_fp.append(file_pointer)
            total_job -= 1
            jira_count += 1
            task_to_process_in_the_thread = data[start_idx : end_idx]
            start_idx = end_idx
        return list_of_fp, task_queue
    
    def triggred_multi_thread_job(self, fp, total_task, job_func):
        self.job_count += 1
        self.current_process_list = total_task
        self.current_fp = fp
        job_thread = threading.Thread(target=job_func)
        job_thread.start()
        return job_thread

    def create_new_fp(self):
        return

    def post_process(self):
        return


def multi_tasking(main_job, data):
    global job_track
    job_track = {}
    list_of_fp, total_task, total_job = main_job.pre_process(data)
    var.in_debug_mode = False
    idx = 0
    threads = []
    while total_job:
        thread = main_job.triggred_multi_thread_job(list_of_fp[idx], total_task[idx], main_job.job)
        threads.append(thread)
        total_job -= 1
        idx += 1
        
    return list_of_fp, threads


def process_jira_tasks(data):
    #determine multi tasking or not.
    #------------------PROCESS STARTS---------------------
    start_time  = time.time()
    
    obj =  main()
    obj.validate_mandatory_data()
    if not data:
        data = I_O.read_ref_file()
    multi_threading_mode = False
    if len(data) and var.multi_thread_process:
        multi_threading_mode = var.multi_thread_process
        list_of_files, threads = multi_tasking(obj, data)
        for thread in threads:
            temp = thread.join()
            print(temp)
    else:
        file_ptr = []
        for task_id in data:
            task_id, find_parent = I_O.get_input_from_user(task_id)
            fp, tot_processed_tasks, tot_coding_or_scripting_tasks, tot_tasks_without_changes = Main.main(None, None, None, [task_id], find_parent, obj.uname, obj.password)
            file_ptr.append(fp.name)
    end_time = time.time()
    #------------------PROCESS ENDS-----------------------

    #common_func.get_processed_details(tot_processed_tasks, tot_coding_or_scripting_tasks, tot_tasks_without_changes)
    if not(var.in_debug_mode):
        os.system('cls')
    if not(multi_threading_mode):
        print(colorful.green('\nReport generated as :'),  fp.name)
    else:
        print(colorful.green('\nReport generated in following files :'))
        for data in job_track:
            print(' > {}'.format(job_track[data][1].name))
    print("\n--- Your Request processed in {} mins ---\n".format( colorful.green(str(round((end_time - start_time) / 60 , 2 ))) ))
    return file_ptr
