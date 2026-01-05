import os

# Tables directory path
TABLES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tables")

CURRENT_FILE = os.path.dirname(os.path.abspath(__file__))
CDM_STORAGE = f'{CURRENT_FILE}\\CDM_Storage'
CDM_CURRENT_DEFECTS_DIR = f'{CDM_STORAGE}\\CURRENT_DEFECTS'
CDM_ARCHIVED_DEFECTS_DIR = f'{CDM_STORAGE}\\ARCHIVED_DEFECTS'
CDM_RESOURCES = f'{CDM_STORAGE}\\RESOURCES'
JIRA_CACHE_PATH = f'{CURRENT_FILE}\\Jira\\Task-Details'
BITBUCKET_CACHE_PATH = f'{CURRENT_FILE}\\tool_bitbucket_retail\\BitBucket\\Bitbucket\\Run_Details'
UTP_PACK_DETAILS_PATH = f'{CURRENT_FILE}\\utp_utility_data'

CDM_BUSSINESS_PROCESS_RESULT = {
    "status":"",
    "err": "",
    "return_value" : ""
}
# Default dropdown options (fallback when DB is unavailable)
DEFAULT_OPTIONS = {
    "applications": [
        {"value": "AA.ARRANGEMENT.ACTIVITY", "label": "AAA"},
        {"value": "FUNDS.TRANSFER", "label": "FT"}
    ],
    "arrangements": [
        {"value": "NEW", "label": "NEW"}
    ],
    "products": [
        {"value": "MORTGAGE", "label": "Mortgage"},
        {"value": "NEGOTIABLE.LOAN", "label": "Negotiable Loan"},
        {"value": "NEGOTIABLE.ACCOUNT", "label": "Negotiable Account"},
        {"value": "SMALL.BUSSINESS.LOAN", "label": "Small Business Loan"},
        {"value": "WLB.LOANS", "label": "Wlb Loans"}
    ],
    "companies": [
        {"value": "GB0010001", "label": "Model - BNK"},
        {"value": "US0010001", "label": "Regression - BNK"}
    ],
    "currencies": [
        {"value": "USD", "label": "USD - US Dollar"},
        {"value": "EUR", "label": "EUR - Euro"},
        {"value": "GBP", "label": "GBP - British Pound"},
        {"value": "INR", "label": "INR - Indian Rupee"},
        {"value": "JPY", "label": "JPY - Japanese Yen"},
        {"value": "AUD", "label": "AUD - Australian Dollar"}
    ],
    "customers": [
        {"value": "100100", "label": "Model - 100100"},
        {"value": "11102", "label": "Regression - 11102"}
    ],
    "activities": [
        {"value": "LENDING-NEW-ARRANGEMENT", "label": "Lending New Arrangement"},
        {"value": "ACCOUNTS-NEW-ARRANGEMENT", "label": "Accounts New Arrangement"}
    ]
}