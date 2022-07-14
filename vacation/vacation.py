import json
from datetime import datetime

ABSENCE_VACATION = "Full-day leave"
ABSENCE_PAR = "Hour-based leave (PAR)"

# https://portal001.globalview.adp.com/gvservice/Philips/mytime/leaveRequest
def read_planned_vacation_file(filename):
	with open(filename, 'r', encoding="utf8") as f:
		data = json.load(f)
	return data.get("data")

# https://portal001.globalview.adp.com/gvservice/Philips/mytime/2022-07-12/ATTABS
def read_balance_file(filename):
	with open(filename, 'r', encoding="utf8") as f:
		data = json.load(f)
	return data.get("balance")

def import_planned_vacation(data):
	par = 0.0
	vac = 0.0
	for d in data:
		absence_end_date, absence_type, absence_hours = (_todate(d.get("end_date")), d.get("time_type_text"), float(d.get("absence_hours")))
		if _is_current_year(absence_end_date):
			if absence_type == ABSENCE_PAR:
				par += absence_hours
			elif absence_type == ABSENCE_VACATION:
				vac += absence_hours
	return (par, vac)

def import_balance(data):
	par = 0.0
	vac = 0.0
	for d in data:
		balance_type, balance_hours = (d.get("timeTypeText"), float(d.get("entitle").replace(" Hours", "").replace(",",".")))
		# print(f"{balance_type}: {balance_hours}")
		if "PAR" in balance_type:
			par += balance_hours
		elif "Vacation" in balance_type:
			vac += balance_hours
	return (par, vac)

def _todate(str):
	return datetime.strptime(str, "%Y-%m-%d")

def _is_current_year(date):
	return date.year == datetime.today().year

def _to_string(n):
	return f"{'{0:.2f}'.format(n): >6} ({'{0:.2f}'.format(n/8): >5})"

def main():
	par, vac = import_balance(read_balance_file("balance.json"))
	planned_par, planned_vac = import_planned_vacation(read_planned_vacation_file("cal.json"))

	print(f"     {'TOT': <16}{'PLANNED': <16}REMAINING")
	print(f"PAR  {_to_string(par): <16}{_to_string(planned_par): <16}{_to_string(par - planned_par)}")
	print(f"VAC  {_to_string(vac): <16}{_to_string(planned_vac): <16}{_to_string(vac - planned_vac)}")

if __name__ == "__main__":
	main()
