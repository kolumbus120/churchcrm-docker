import json
with open('/var/www/html/locale/locales.json', 'r') as f:
    data = json.load(f)
data['Slovak'] = {
    'poEditor': 'sk',
    'locale': 'sk_SK',
    'languageCode': 'sk',
    'countryCode': 'SK',
    'nativeName': 'Slovenčina',
    'region': 'Europe',
    'dataTables': 'Slovak',
    'fullCalendar': True,
    'fullCalendarLocale': 'sk',
    'datePicker': True,
    'momentLocale': 'sk',
    'isRTL': False
}
with open('/var/www/html/locale/locales.json', 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=4)
