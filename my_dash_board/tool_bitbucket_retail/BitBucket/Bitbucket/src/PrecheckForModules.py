import os
import importlib.util

def check_module_exists():
    current_path = os.path.abspath(__file__)
    current_path = os.path.abspath(os.path.join(current_path, ".."))
    data_file_path = current_path
    for i in range(2):
        data_file_path = os.path.abspath(os.path.join(data_file_path, ".."))  # Move one directory up
    data_file_path += "\\installation\\requirements"
    path_dir = {"current_file_path" : current_path,"data_file_path" : data_file_path}
    with open("{}\\requirements.txt".format(path_dir["data_file_path"]), "r") as file_object:
        modules = file_object.read().split(",\n")
    result = {}
    missing_module_found = False
    for module in modules:
        spam_spec = importlib.util.find_spec(module)
        found = spam_spec is not False
        status = "Success"
        if not(found):
            try:
                os.system('pip install {}'.format(module))
            except Exception as e:
                status = "Err -> {0}".format(e)
        result[module] = [found, {"status" : status}]
    print(result)
    return result

