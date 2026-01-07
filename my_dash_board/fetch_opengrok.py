from bs4 import BeautifulSoup
import requests
from requests.auth import HTTPBasicAuth
import json
from common import AA_TABLES, CREATE_OFS_TABLES_PATH
import re
import os

USERNAME = "temenosgrok"
PASSWORD = "temenosgrok"

urls = ["http://10.93.15.53:8081/OpenGrokCMB/xref/T24-DEV/ukisa1/UKISA1_Reporting/Data/Public/",
        "http://10.93.15.53:8081/OpenGrokCMB/xref/T24-DEV/ukisa1/UKISA1_Reporting/Data/Model/"]


def find_file_inside(data):
    try:
        for val in data:
            if val.string:
                if val.string.split(".")[-1] in ["json", "b", "d", "tut", "component"]:
                    return True
    except Exception as e:
        exit()
        print(f"program stops due to : {e}")
    return False

def extract_tables(soup):

    pre = soup.find("div", id="src").find("pre")
    texts = pre.get_text().replace(" ", "")
    texts = texts.split("\n")
    cleaned_table_data = []
    table_dictionary = {}
    
    table_dictionary["fields"] = {}
    add_data = False
    t24_table_name = ''

    for text in texts:
        match = re.search(r"\d+([A-Za-z].*)", text)
        if match:
            extracted_text = match.group(1)
            if 't24:' in extracted_text:
                t24_table_name = extracted_text.split(":")[-1]
            if add_data:
                cleaned_table_data.append(extracted_text)
            if 'fields:' in extracted_text:
                add_data = True
    table_dictionary["t24"] = t24_table_name
    for idx in cleaned_table_data:
        field_name = idx.split('=')[0]
        field_value = idx.split('=')[-1]
        table_dictionary["fields"][field_name] = field_value

    return table_dictionary


def extract_links(soup):
    """Extract all links from HTML"""
    links = []
    for link in soup.find_all('a', href=True):
        links.append({
            "text": link.get_text(strip=True),
            "href": link['href']
        })
    return links


def extract_headers(soup):
    """Extract all headers (h1-h6) from HTML"""
    headers = []
    for i in range(1, 7):
        for header in soup.find_all(f'h{i}'):
            headers.append({
                "level": i,
                "text": header.get_text(strip=True)
            })
    return headers

def get_enquiry_data(extracted_data):
    #text file
    data = ""
    for file in extracted_data["actual_files"]:
        if file.split("!")[0] == "F.ENQUIRY":
            filename = file.split("!")[-1]
            filename = filename.replace(".json", "")
            data += f'{filename}\n'

    #print(data)
    return data
    #with open("enquires.txt", "w") as f:

enquiry_data = []

def get_table_url(table_name):

    return f'http://10.93.15.53:8081/OpenGrokCMB/xref/T24-DEV/aa/{table_name}/Definition/{table_name.split('_')[-1]}.table'

def validate_aaa_dir():
    if not os.path.exists(CREATE_OFS_TABLES_PATH):
        os.makedirs(CREATE_OFS_TABLES_PATH, exist_ok=True)

    if not os.path.exists(f'{CREATE_OFS_TABLES_PATH}\\AAA'):
        os.makedirs(f'{CREATE_OFS_TABLES_PATH}\\AAA', exist_ok=True)

    return

def update_aaa_table():

    validate_aaa_dir()

    for table_name in AA_TABLES:
        try:
            url = get_table_url(table_name=table_name)
            
            response = requests.get(url, auth=HTTPBasicAuth(USERNAME, PASSWORD), timeout=30)

            soup = BeautifulSoup(response.text, 'html.parser')
            
            extracted_data = extract_tables(soup)
            
            with open(f'{CREATE_OFS_TABLES_PATH}\\AAA\\{table_name}.json', 'w', encoding="utf-8") as f:
                json.dump(extracted_data, f, indent=4)
            print(f'table {table_name} update done ')

        except Exception as e:
            print(f'table {table_name} update failed (cause : {e})')

    return



