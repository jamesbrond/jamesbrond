"""How many vacation days still remain?"""

from datetime import datetime
import json

ABSENCE_VACATION = "Full-day leave"
ABSENCE_PAR = "Hour-based leave (PAR)"

# https://portal001.globalview.adp.com/gvservice/Philips/mytime/leaveRequest
def read_planned_vacation_file(filename):
    """read planned vacation from JSON file"""
    with open(filename, 'r', encoding="utf8") as jsonfile:
        data = json.load(jsonfile)
    return data.get("data")

# https://portal001.globalview.adp.com/gvservice/Philips/mytime/2022-07-12/ATTABS
def read_balance_file(filename):
    """read available vacation hours from JSON file"""
    with open(filename, 'r', encoding="utf8") as jsonfile:
        data = json.load(jsonfile)
    return data.get("balance")

def import_planned_vacation(data):
    """Import planned vacations"""
    par = 0.0
    vac = 0.0
    for i in data:
        absence_end_date, absence_type, absence_hours = (
            _todate(i.get("end_date")),
            i.get("time_type_text"),
            float(i.get("absence_hours"))
        )
        if _is_current_year(absence_end_date):
            if absence_type == ABSENCE_PAR:
                par += absence_hours
            elif absence_type == ABSENCE_VACATION:
                vac += absence_hours
    return (par, vac)

def import_balance(data):
    """Import available vacation hours"""
    par = 0.0
    vac = 0.0
    for i in data:
        balance_type, balance_hours = (
            i.get("timeTypeText"),
            float(i.get("entitle").replace(" Hours", "").replace(",","."))
        )
        # print(f"{balance_type}: {balance_hours}")
        if "PAR" in balance_type:
            par += balance_hours
        elif "Vacation" in balance_type:
            vac += balance_hours
    return (par, vac)

def _todate(text):
    return datetime.strptime(text, "%Y-%m-%d")

def _is_current_year(date):
    return date.year == datetime.today().year

def _to_string(num):
    return f"{'{0:.2f}'.format(num): >6} ({'{0:.2f}'.format(num/8): >5})"

def main():
    """main function"""
    par, vac = import_balance(read_balance_file("balance.json"))
    planned_par, planned_vac = import_planned_vacation(read_planned_vacation_file("cal.json"))

    print(f"     {'TOT': <16}{'PLANNED': <16}REMAINING")
    print(f"PAR  {_to_string(par): <16}{_to_string(planned_par): <16}{_to_string(par - planned_par)}")
    print(f"VAC  {_to_string(vac): <16}{_to_string(planned_vac): <16}{_to_string(vac - planned_vac)}")

if __name__ == "__main__":
    main()
