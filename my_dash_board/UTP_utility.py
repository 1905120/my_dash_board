import sys
import subprocess
import sys
import os
import pathlib
import logging
import shutil
from alive_progress import alive_bar

# # Dependency checker - checks and installs missing packages
# def check_and_install_dependencies():
#     """Check if required packages are installed, install if missing"""
#     required_packages = {
#         'os': None,        # Built-in, no pip name
#         'pathlib': None,   # Built-in, no pip name
#         'logging': None,   # Built-in, no pip name
#         'shutil': None     # Built-in, no pip name
#     }
    
#     missing_packages = []
    
#     for package, pip_name in required_packages.items():
#         try:
#             __import__(package)
#         except ImportError:
#             if pip_name:  # Only add if it has a pip package name
#                 missing_packages.append(pip_name)
    
#     if missing_packages:
#         print(f"Missing packages detected: {', '.join(missing_packages)}")
#         print("Attempting to install missing packages...")
        
#         # Check if pip is available
#         try:
#             subprocess.check_call([sys.executable, '-m', 'pip', '--version'], 
#                                 stdout=subprocess.DEVNULL, 
#                                 stderr=subprocess.DEVNULL)
#             pip_available = True
#         except (subprocess.CalledProcessError, FileNotFoundError):
#             pip_available = False
        
#         if pip_available:
#             for package in missing_packages:
#                 try:
#                     print(f"Installing {package}...")
#                     subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
#                     print(f"Successfully installed {package}")
#                 except subprocess.CalledProcessError as e:
#                     print(f"Failed to install {package}: {e}")
#                     sys.exit(1)
#         else:
#             print("ERROR: pip is not available in the environment.")
#             print("Please install pip or manually install the required packages:")
#             print(f"  {', '.join(missing_packages)}")
#             sys.exit(1)
    
#     return True

# # Run dependency check before importing
# check_and_install_dependencies()

class UTPConversion:

    #################################################################
    current_working_property = None #Current working tafj property (add the tafj property in your workspace)
    #################################################################

    def __init__(self, current_path, jboss_path, db_path, tafj_path, log_dir)-> None:
        self.current_path                  = current_path
        self.log_dir                       = log_dir
        self.jboss_path                    = jboss_path
        self.db_path                       = db_path
        self.tafj_path                     = tafj_path
        self.jboss_path                    = jboss_path
        self.log_directories               = log_dir
        self.db_variant = None
        self.log_directories               = [f'{self.current_path}\\log',
                                              f'{self.current_path}\\TAFJ\\log',
                                              f'{self.current_path}\\TAFJ\\log_T24']
        self.dump_files_to_clear           = [f'{self.jboss_path}\\standalone\\data',
                                              f'{self.jboss_path}\\standalone\\tmp',
                                              f'{self.jboss_path}\\standalone\\deployments']
        self.t24lib_parent_dir             = '{}\\modules\\com\\temenos\\t24\\main'.format(self.jboss_path)
        self.t24lib                        = '{}\\modules\\com\\temenos\\t24\\main\\t24lib'.format(self.jboss_path)
        self.Jar_Path                      = '{}\\t24home\\default\\JARS'.format(self.current_path)
        self.Command_Window                = '{}\\bin'.format(self.tafj_path)
        self.Command_To_Gen_Module_Xml     = 'jbosstools com.temenos.t24 {} {} -tafjdep'.format(self.t24lib_parent_dir, self.t24lib_parent_dir)
        self.h2_1_3_161_jar                = 'h2-1.3.161.jar'
        self.h2_1_4_200_jar                = 'h2-1.4.200.jar'
        self.h2_1_3_161_jar_Dir            = '{}\\TAFJ\\dbdrivers\\h2-1.3.161'.format(self.current_path)
        self.h2_1_4_200_jar_Dir            = '{}\\TAFJ\\dbdrivers\\h2-1.4.200'.format(self.current_path)
        self.path_need_driver_replacement  =[f'{self.db_path}\\bin', 
                                            f'{self.jboss_path}\\modules\\com\\temenos\\tafj\\main\\ext', 
                                            f'{self.jboss_path}\\modules\\system\\layers\\base\\com\\h2database\\h2\\main',
                                            f'{self.tafj_path}\\ext']
        self.files_need_mvcc_update        = [f'{self.current_path}\\setenv.bat',
                                              f'{self.jboss_path}\\standalone\\configuration\\standalone.xml',
                                              f'{self.jboss_path}\\standalone\\configuration\\standalone-utp.xml',
                                              f'{self.jboss_path}\\standalone\\configuration\\T24.xml'
                                              # f'{self.jboss_path}\\standalone\\configuration\\module.xml'
                                            ]
        self.files_need_jars_update        = [f'{self.db_path}\\bin\\h2.bat', 
                                              # f'{self.db_path}\\bin\\h2.sh', 
                                              f'{self.db_path}\\bin\\h2w.bat', 
                                              f'{self.db_path}\\bin\\WStartH2.bat', 
                                              f'{self.db_path}\\bin\\WStopH2.bat',
                                              f'{self.current_path}\\setenv.bat',
                                              f'{self.jboss_path}\\modules\\com\\temenos\\tafj\\main\\module.xml',
                                              f'{self.jboss_path}\\modules\\system\\layers\\base\\com\\h2database\\h2\\main\\module.xml']
        self.logger                        = None
        return
    
    
    def check_current_path_is_valid(self):
        try:
            if self.current_path.split("\\")[-1] == "Temenos":
                self.logger.info(f"Current Working Directory : {self.current_path}")
                return True
            raise Exception("File Placed in Wrong Dir!. Keep it in <UTP_NAME>/Temenos/ path")
        except Exception as e:
            self.logger.error(f"Current Working Directory : {self.current_path} is not valid")
            raise Exception(str(e))
            return False
    
    def check_db_variant(self)-> str:
        try:
            loaded_db_files = [str(File.name) for File in pathlib.Path(self.db_path).iterdir()  if str(File.name).split(".")[-1] == 'db']
            if len(loaded_db_files) > 1:
                self.logger.error(f"Don't place more than 1 db File in  {self.db_path}")
                raise Exception(f"Don't place more than 1 db File in  {self.db_path}")
            elif not loaded_db_files:
                self.logger.error(f"DB Missing in {self.db_path}")
                raise Exception(f"DB Missing in {self.db_path}")
            if len(loaded_db_files[0].split('.')) == 3:
                if loaded_db_files[0].split('.')[1] == "mv":
                    self.db_variant = "mv"
                    self.logger.info(f"Starting MV setup")
                elif loaded_db_files[0].split('.')[1] == "h2":
                    self.db_variant = "h2"
                    self.logger.info(f"Staring H2 setup")
                else:
                    self.logger.error("Invalid DB!!!")
                    raise Exception("Invalid DB!!!")
            else:
                self.logger.error("Invalid DB!!!")
                raise Exception("Invalid DB!!!")
        except Exception as e:
           raise Exception(str(e))
        return self.db_variant
    
    def update_drivers(self):
        try:
            if self.db_variant == "h2":
                #replace from self.h2_1_3_161_jar_Dir to self.h2_1_4_200_jar_Dir
                current_driver = self.h2_1_4_200_jar
                replace_driver = f'{self.h2_1_3_161_jar_Dir}\\{self.h2_1_3_161_jar}'
                replaced_jar   = self.h2_1_3_161_jar
            elif self.db_variant == "mv":
                #replace from self.h2_1_4_200_jar_Dir to self.h2_1_3_161_jar_Dir
                replace_driver = f'{self.h2_1_4_200_jar_Dir}\\{self.h2_1_4_200_jar}'
                current_driver = self.h2_1_3_161_jar
                replaced_jar   = self.h2_1_4_200_jar
            self.logger.info(f"String Updation on DB drivers from {current_driver} to {replace_driver}")
            is_replace_done_in_directories = False
            for each_path in self.path_need_driver_replacement:
                try:
                    test = not os.path.exists(replace_driver)
                    if (os.path.exists(replace_driver) and os.path.exists(each_path) and os.path.exists(f'{each_path}\\{current_driver}')) or (not os.path.exists(f'{each_path}\\{current_driver}')):
                        shutil.copy(replace_driver, each_path)
                        try:
                            os.remove(f'{each_path}\\{current_driver}')
                        except Exception as e:
                            self.logger.info(f"{current_driver} not found in Dir : {each_path}")
                        is_replace_done_in_directories = True
                        self.logger.info(f"driver replaced to {replaced_jar} in Dir : {each_path}")
                except Exception as e:
                    self.logger.error({str(e)})
                    raise Exception(str(e))
            if not is_replace_done_in_directories:
                self.logger.info(f"No Updation on DB drivers from {current_driver} to {replace_driver}")
        except Exception as e:
            self.logger.error({str(e)})
            raise Exception(str(e))
        return
    
    def update_jars_in_file(self):
        try:
            if self.db_variant == "mv":
                current_jar_id = self.h2_1_3_161_jar
                replace_jar_id = self.h2_1_4_200_jar
            elif self.db_variant == "h2":
                current_jar_id = self.h2_1_4_200_jar
                replace_jar_id = self.h2_1_3_161_jar
            for File in self.files_need_jars_update:
                if os.path.exists(File):
                    text = pathlib.Path(File).read_text()
                    text = text.replace(current_jar_id, replace_jar_id)
                    pathlib.Path(File).write_text(text)
                    self.logger.info(f"driver map done for {File}")
                else:
                    self.logger.error(f"cannot find the path {File} while mapping dbdriver")
                    raise Exception(str(e))
        except Exception as e:
            self.logger.error({str(e)})
            raise Exception(str(e))
        return
    
    def update_mvcc_setup(self):
        try:
            check_file = []
            text = pathlib.Path(f'{self.tafj_path}\\conf\\.default').read_text()
            if text:
                text = text.split("\n")[0]
            default_tafj_properties_path = f'{self.tafj_path}\\conf\\{text}'
            self.files_need_mvcc_update.append(default_tafj_properties_path)
            self.files_need_mvcc_update.append(self.current_working_property)
            for File in self.files_need_mvcc_update:
                if not File or File in check_file:
                    continue
                if os.path.exists(File):
                    if self.db_variant == "mv":
                        text = pathlib.Path(File).read_text()
                        text = text.replace(";MVCC=TRUE", "")
                        pathlib.Path(File).write_text(text)
                        check_file.append(File)
                    elif self.db_variant == "h2":
                        text = pathlib.Path(File).read_text()
                        text = text.replace("TRACE_LEVEL_SYSTEM_OUT=0;", "TRACE_LEVEL_SYSTEM_OUT=0;MVCC=TRUE;")
                        pathlib.Path(File).write_text(text)
                        check_file.append(File)
                    self.logger.info(f"MVCC update done for {File}")
                else:
                    self.logger.error(f"System cannot find the path {File} while updating MVCC configuration")
                    raise Exception(str(e))
            # try:
            #     pass
            # except Exception as e:
            #     self.logger.error({str(e)})
            #     print(f"ERROR - {str(e)}")
        except Exception as e:
            self.logger.error({str(e)})
            raise Exception(str(e))
        return
    
    def Generate_Module_Xml(self):

        Current_File_Dir = self.current_path
        if not(Current_File_Dir):
                Current_File_Dir            = '{}\\Temenos'.format(os.path.dirname(os.getcwd()))
                print('\nCWD :', Current_File_Dir)
        
        Jars_In_t24Lib                      = '{}\\jboss\\modules\\com\\temenos\\t24\\main\\t24lib'.format(Current_File_Dir)
        T24_Lib_Path                        = '{}\\jboss\\modules\\com\\temenos\\t24\\main'.format(Current_File_Dir)
        Jar_Path                            = '{}\\t24home\\default\\JARS'.format(Current_File_Dir)
        Jars                                = pathlib.Path(Jar_Path)
        TAFJ_Path                           = '{}\\TAFJ'.format(Current_File_Dir)
        Command_Window                      = '{}\\bin'.format(TAFJ_Path)
        if not(os.path.exists('{}\\jbosstools'.format(Command_Window))):
                sys.stdout.write('Err Msg : Missing Jbosstools!!!')
                if not(input()):
                        pass
                exit()
        Command_To_Gen_Module_Xml           = 'jbosstools com.temenos.t24 {} {} -tafjdep'.format(T24_Lib_Path, T24_Lib_Path)
        #clear t24lib first ...
        print('\nClearing t24lib ... ')
        
        if os.path.isdir(Jars_In_t24Lib):
            list_of_dir = os.listdir(Jars_In_t24Lib)
            with alive_bar(len(list_of_dir), bar='classic', spinner='classic') as bar:
                for Jar in list_of_dir:
                   _file = f'{Jars_In_t24Lib}\\{Jar}'
                   os.chmod(_file, 0o777)
                   os.remove(_file)
                   bar()
        else:
            os.chdir(T24_Lib_Path)
            os.mkdir(Jars_In_t24Lib)
        #os.system('cls')
        print('\nCopying From JARS to t24lib ... ')
        list_of_dir = os.listdir(Jar_Path)
        with alive_bar(len(list_of_dir), bar='classic', spinner='classic') as bar:
          for Jar in list_of_dir:
            if os.path.isfile(f'{Jar_Path}\\{Jar}'):
                shutil.copy(f'{Jar_Path}\\{Jar}', Jars_In_t24Lib)
            bar()
        os.chdir(Command_Window)
        os.system(Command_To_Gen_Module_Xml)
        return
    
    def clean_directory(self, root_dir):
        root = pathlib.Path(root_dir)
        for item in root.rglob("*"):
            if item.is_file():
                if root.name == "deployments":
                    if item.suffix not in ['.dodeploy', ".isdeploying", ".failed", ".deployed"]:
                        continue
                try:
                    item.unlink()
                    print(f"Deleted: {item}")
                except PermissionError:
                    try:
                        with open(item, "w") as f:
                            f.truncate()
                        print(f"Truncated (locked): {item}")
                    except Exception as e:
                        print(f"Failed to truncate {item}: {e}")

            elif item.is_dir():
                try:
                    item.rmdir()
                    print(f"Removed empty directory: {item}")
                except OSError:
                    pass
        for item in sorted(root.rglob("*"), key=lambda p: len(str(p)), reverse=True):
            if item.is_dir():
                try:
                    item.rmdir()
                    print(f"Removed empty directory: {item}")
                except OSError:
                    pass
        return
    
    def clear_logs(self):
        try:
            for log_dir in self.log_directories:
                self.clean_directory(log_dir)
                self.logger.info(f'Log cleard in {log_dir}')
            return True
        except Exception as e:
            self.logger.error(f'error while clearing logs in {log_dir}')
            raise Exception(str(e))
            return False
        
    def clear_cache(self):
        try:
            for cache_dir in self.dump_files_to_clear:
                self.clean_directory(cache_dir)
                self.logger.info(f'cache cleard in {cache_dir}')
                # os.remove(cache_dir)
            return True
        except Exception as e:
            self.logger.error(f'error while clearing cache in {cache_dir} : {str(e)}')
            raise Exception(str(e))
            return False
        

    def Handle_Deployments(self, user_choice):

        Current_File_Dir = self.current_path

        unwanted_files_to_move = ['.DEPLOY', '.FAILED', 'ISDEPLOYING', '.UNDEPLOY', '.DODEPLOY']

        #Deployments Enough for New Browser testing
        list_of_req_zip_files0 = "Authenticator.war axis2.war Browser.war BrowserWeb.war dsf-iris.war dsf-uxp.war irf-provider-container.war irf-publisher-container.war irf-test-jwt.war irf-test-web.war irf-web-client.war ms-outbox-mdb-packager.ear t24interactiontests-iris.war TAFJSpoolerPlugins.rar irf-rp-services.war irf-t24catalog-services.war ResourceServer.war t24-EB_AuthenticationService-ejb.jar t24-EB_CatalogService-ejb.jar t24-EB_OFSConnectorService-ejb.jar t24-EB_ResourceProviderService-ejb.jar t24-IF_IntegrationFrameworkService-ejb.jar TAFJJEE_EAR.ear TemnKafka.rar"

        #Deployments Enough for API testing
        list_of_req_zip_files1 = "irf-provider-container.war BrowserWeb.war TemnKafka.rar TAFJJEE_EAR.ear TAFJSpoolerPlugins.rar"

        #Deployments Enough for Old browser / OFS testing
        list_of_req_zip_files2 = ["BrowserWeb.war"]

        list_of_req_zip_files = None
        if user_choice == 1:
                list_of_req_zip_files = list_of_req_zip_files0.split(" ")
        elif user_choice == 2:
                list_of_req_zip_files = list_of_req_zip_files1.split(" ")
        elif user_choice == 3:
                list_of_req_zip_files = list_of_req_zip_files2
        if not list_of_req_zip_files:
                return "Invalid selection"
        
        print('----------------{ Total Required Deployments }----------------')
        for c, _file in enumerate(list_of_req_zip_files):
            print('{}. {}'.format(c, _file))
        print('--------------------------------------------------------------')
        
        if not(Current_File_Dir):
            Current_File_Dir            = '{}\\Temenos'.format(os.path.dirname(os.getcwd()))
            print('\nCWD :', Current_File_Dir)
        
        deployment_folder                     = '{}\\jboss\\standalone\\deployments'.format(Current_File_Dir)
        
        

        #create new backup folder...
        Deployments_Backup_folder = Current_File_Dir + '\\jboss\\standalone\\Deployments_Backup'

        availale_files = os.listdir(deployment_folder)

        # cont = input('Press Enter to continue ...')
        # if cont:
            # exit(1)
            
        if os.path.isdir(Deployments_Backup_folder):
            print('Already Backup Path Found...\nRemoving existing Backup folder data')
            #Deployments_Backup_folder = self.add_file_sequence(Deployments_Backup_folder)
            print(Deployments_Backup_folder)
        else:
            #Creating New backup folder
            os.mkdir(Deployments_Backup_folder)
            for backup_file in availale_files:
                try:
                    shutil.copy(f'{deployment_folder}\\{backup_file}', Deployments_Backup_folder)
                except Exception as e:
                    pass

        #files_in_deployment_folder = files = os.listdir(deployment_folder)
        files_in_deployments_Backup_folder = os.listdir(Deployments_Backup_folder)

        #take a backup

        print('--------------------------------------------------------------')
        print('SRC    PATH : ', deployment_folder )
        print('BACKUP PATH : ', Deployments_Backup_folder )
        print('--------------------------------------------------------------')

        
        founded_unwanted_files = []
        for _file in files_in_deployments_Backup_folder:
            if _file in list_of_req_zip_files :
                print('moving file :', _file)
                shutil.copy(Deployments_Backup_folder + '\\' + _file, deployment_folder)
            else:
                try:
                    os.remove(deployment_folder + '\\' + _file)
                    founded_unwanted_files.append(_file)
                except Exception as e:
                    pass

        return



# print("1. Modify Current UTP pack")
# print("2. Generate Module")
# print("3. Cleat Logs (clear Temenos/log, Temenos/TAFJ/log, Temenos/TAFJ/logT24)")
# print("4. Clear Cache (clear Temenos/jboss/standalone/data, Temenos/jboss/standalone/tmp)")
# print("5. Clear Environment (Execute Oper 3 and 4)")
# print("6. Manage Deployments")
    
# Option = str(input("please select one of the option above : ")).strip()

# if not Option.isdigit():
#     print("Invalid Selection X")
#     exit()
# else :
#     Option = int(Option)
#     if Option < 1 or Option > 6:
#         print("Invalid Selection X")
#         exit()

# os.system("cls")


        

