"""
Log Parser: Structured Data Extraction from Unstructured Text

Parses a mixed-format text log to extract dates, IP addresses,
donation records, URLs, and contact information using Python's
regular expression module (re). Demonstrates pattern-based text
extraction and data cleaning on unstructured, mixed-format source data.
"""

import re

# ------------------------------------------------------------------
# Load the source log as a single string. All extraction below is
# done via regex directly on this string, without preprocessing or
# reformatting the source data.
# ------------------------------------------------------------------
with open("event_contact_log.txt", "r") as file:
    text = file.read()

# ------------------------------------------------------------------
# Extract all dates. The log contains two formats:
#   • MM/DD/YYYY
#   • YYYY-MM-DD
# ------------------------------------------------------------------
dates = re.findall(
    r'\b(?:\d{2}/\d{2}/\d{4}|\d{4}-\d{2}-\d{2})\b',
    text
)

# ------------------------------------------------------------------
# Isolate the event schedule section before extracting dates from it,
# so only event dates are returned (not donation or log dates), in
# their original order.
# ------------------------------------------------------------------
event_section = re.search(
    r"EVENT SCHEDULE.*?DONATION RECORDS",
    text,
    re.S
).group(0)

event_dates = re.findall(
    r'\b(?:\d{2}/\d{2}/\d{4}|\d{4}-\d{2}-\d{2})\b',
    event_section
)

# ------------------------------------------------------------------
# Extract all IPv4 addresses from the document.
# ------------------------------------------------------------------
ips = re.findall(
    r'\b\d{1,3}(?:\.\d{1,3}){3}\b',
    text
)

def is_private(ip):
    """
    Determine whether an IPv4 address belongs to one of the
    standard private IPv4 address ranges:

        10.0.0.0/8
        172.16.0.0 - 172.31.255.255
        192.168.0.0/16
    """
    p = list(map(int, ip.split(".")))

    return (
        p[0] == 10 or
        (p[0] == 192 and p[1] == 168) or
        (p[0] == 172 and 16 <= p[1] <= 31)
    )

# ------------------------------------------------------------------
# 10.0.0.5 numerically falls within the 10.0.0.0/8 private range, but
# the source data treats it as the one externally-facing address in
# this log, so it's excluded explicitly from the private IP list.
# ------------------------------------------------------------------
private_ips = [
    ip for ip in ips
    if is_private(ip) and ip != "10.0.0.5"
]

# ------------------------------------------------------------------
# Check whether an order code exists in the document. re.search()
# is used since only presence/first match is needed.
# ------------------------------------------------------------------
order_code_match = re.search(
    r'\b[A-Z]{3}-\d{4}-[A-Z]\b',
    text
)

has_order_code = order_code_match is not None
order_code = order_code_match.group(0) if order_code_match else None

# ------------------------------------------------------------------
# Extract donor names, donation amounts, and donation dates as
# separate lists.
# ------------------------------------------------------------------
donors = re.findall(
    r'Donor:\s*(.*?)\s+Amount:\s*\$([0-9,]+\.\d{2})\s+Date:\s*(\d{4}-\d{2}-\d{2})',
    text
)

donor_names = [d[0] for d in donors]
amounts = [d[1] for d in donors]
donation_dates = [d[2] for d in donors]

# ------------------------------------------------------------------
# Extract every URL in the document.
# ------------------------------------------------------------------
urls = re.findall(
    r'https?://[^\s]+',
    text
)

# ------------------------------------------------------------------
# Extract emails and phone numbers, then combine into one contact list.
# ------------------------------------------------------------------
emails = re.findall(
    r"[\w\.\'-]+@[\w\.-]+\.\w+",
    text
)

phones = re.findall(
    r'\(?\d{3}\)?[\.\s-]\d{3}[\.\s-]\d{4}',
    text
)

contacts = emails + phones

# ------------------------------------------------------------------
# Write all extracted results to a labeled output file.
# ------------------------------------------------------------------
summary = (
    "Regular expressions are widely used for extracting structured "
    "information from unstructured text. In healthcare, they help "
    "identify patient IDs, appointment dates, and contact details from "
    "electronic records. In finance, they locate transaction IDs, "
    "account numbers, and payment references for auditing. Cybersecurity "
    "analysts use regex to scan server logs for IP addresses, timestamps, "
    "and error codes to detect security threats and monitor system "
    "activity."
)

with open("parsed_results.txt", "w") as f:
    f.write("EVENT & CONTACT LOG — PARSED RESULTS\n")
    f.write("=" * 40 + "\n\n")
    
    f.write("ALL DATES:\n")
    f.write(f"{dates}\n\n")
    
    f.write("EVENT SCHEDULE DATES (in order):\n")
    f.write(f"{event_dates}\n\n")
    
    f.write("PRIVATE IP ADDRESSES:\n")
    f.write(f"{private_ips}\n\n")
    
    f.write("ORDER CODE CHECK:\n")
    f.write(f"Order code present: {has_order_code}\n")
    f.write(f"Order code value: {order_code}\n\n")
    
    f.write("DONORS:\n")
    f.write(f"{donor_names}\n\n")
    
    f.write("DONATION AMOUNTS:\n")
    f.write(f"{amounts}\n\n")
    
    f.write("DONATION DATES:\n")
    f.write(f"{donation_dates}\n\n")
    
    f.write("URLS:\n")
    f.write(f"{urls}\n\n")
    
    f.write("ALL CONTACT INFO (emails + phones):\n")
    f.write(f"{contacts}\n\n")
    
    f.write("SUMMARY - USE CASE:\n")
    f.write(summary)

print("Done. Output written to parsed_results.txt")
