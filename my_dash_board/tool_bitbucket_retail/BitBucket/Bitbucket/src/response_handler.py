from common_var import return_response, server_trace_enabled
from typing import Any, List
import os
import sys
import colorful
_src_dir = os.path.dirname(os.path.abspath(__file__))
if _src_dir not in sys.path:
    sys.path.insert(0, _src_dir)

def get_response_structure(option: str)-> dict:
    if option == "NEW":
        return_response["msg"] = None
        return_response["error"] = None
        return_response["data"] = None
    else:
        return  return_response

    return return_response

def Response(categ: str, 
            response: List,
            data: Any)-> dict:
    return_response = get_response_structure("NEW")
    response[0] = str(response[0]) if not isinstance(response[0], str) else response[0]
    #response[1] will hold the module that raised the error
    match categ:
        case "INFO":
            return_response["msg"] = response[0]
            return_response["error"] = False
            return_response["data"] = data
        case "ERROR":
            return_response["msg"] = response[0]
            return_response["error"] = True
        case _:
            return_response["msg"] = "invalid response category"
            return_response["error"] = True
    if server_trace_enabled:
        match categ:
            case "INFO":
                print(f'{colorful.yellow(categ)} :: {return_response["msg"]}')
            case "ERROR":
                print(f'{colorful.red(categ)} :: {return_response["msg"]}')
            case _:
                print(f'{colorful.red(categ)} :: {return_response["msg"]}')
    return return_response


def check_continue_process(return_response: dict):
    #determine whether continuing the process or exit from
    _continue = True
    if  return_response["error"]:
        _continue = False
    return _continue

