import os

# Tables directory path
TABLES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tables")

CURRENT_FILE = os.path.dirname(os.path.abspath(__file__))
CDM_STORAGE = f'{CURRENT_FILE}\\CDM_Storage'
CDM_CURRENT_DEFECTS_DIR = f'{CDM_STORAGE}\\CURRENT_DEFECTS'
CDM_ARCHIVED_DEFECTS_DIR = f'{CDM_STORAGE}\\ARCHIVED_DEFECTS'
CDM_NEW_DEFECTS_DIR = f'{CDM_STORAGE}\\NEW_DEFECTS'
CDM_RESOURCES = f'{CDM_STORAGE}\\RESOURCES'
JIRA_CACHE_PATH = f'{CURRENT_FILE}\\Jira\\Task-Details'
BITBUCKET_CACHE_PATH = f'{CURRENT_FILE}\\tool_bitbucket_retail\\BitBucket\\Bitbucket\\Run_Details'
BITBUCKET_CREDENTIALS_PATH = f'{CURRENT_FILE}\\tool_bitbucket_retail\\BitBucket\\Bitbucket\\src\\Data'
UTP_PACK_DETAILS_PATH = f'{CURRENT_FILE}\\utp_utility_data'
CREATE_OFS_TABLES_PATH = f'{CURRENT_FILE}\\tables'
MAIN_DASH_BOARD_PATH = f'{CURRENT_FILE}\\my_dash_board_storage'

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
        {"value": "ACCOUNTS-NEW-ARRANGEMENT", "label": "Accounts New Arrangement"},
        {"value": "LENDING-ACCRUE-PENALTYINT", "label": "Lending Accrue Penaltyint"}
    ]
}

AA_TABLES = [
    "AA_Account",
    "AA_Accounting",
    "AA_ActivityApi",
    "AA_ActivityCharges",
    "AA_ActivityMapping",
    "AA_ActivityMessaging",
    "AA_ActivityPresentation",
    "AA_ActivityRestriction",
    "AA_AgentCommission",
    "AA_Alerts",
    "AA_BalanceAvailability",
    "AA_BalanceMaintenance",
    "AA_BundleHierarchy",
    "AA_ChangeProduct",
    "AA_Chargeoff",
    "AA_ChargeOverride",
    "AA_Closure",
    "AA_Constraint",
    "AA_Customer",
    "AA_Dormancy",
    "AA_Eligibility",
    "AA_Evidence",
    "AA_ExchangeRate",
    "AA_Facility",
    "AA_Fees",
    "AA_Inheritance",
    "AA_Interest",
    "AA_InterestCompensation",
    "AA_Limit",
    "AA_NoticeWithdrawal",
    "AA_Officers",
    "AA_Overdue",
    "AA_Participant",
    "AA_PaymentHoliday",
    "AA_PaymentPriority",
    "AA_PaymentRules",
    "AA_PaymentSchedule",
    "AA_Payoff",
    "AA_PayoutRules",
    "AA_PeriodicCharges",
    "AA_PreferentialPricing",
    "AA_PreferentialPricingFx",
    "AA_PricingAdjustments",
    "AA_PricingGrid",
    "AA_PricingRules",
    "AA_ProductBundle",
    "AA_ProductCommission",
    "AA_PromotionRules",
    "AA_PropertyControl",
    "AA_Reporting",
    "AA_RestructureRules",
    "AA_SafeDepositBox",
    "AA_Settlement",
    "AA_ShareTransfer",
    "AA_SplitsMerges",
    "AA_Statement",
    "AA_SubArrangementCondition",
    "AA_SubArrangementRules",
    "AA_SubLimits",
    "AA_Swift",
    "AA_Tax",
    "AA_TermAmount",
    "AA_TransactionRules"
]


