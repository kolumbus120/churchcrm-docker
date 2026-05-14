<?php
$file = '/var/www/html/locale/locales.json';
$data = json_decode(file_get_contents($file), true);
$data['Slovak'] = [
    'poEditor' => 'sk',
    'locale' => 'sk_SK',
    'languageCode' => 'sk',
    'countryCode' => 'SK',
    'nativeName' => 'Slovenčina',
    'region' => 'Europe',
    'dataTables' => 'sk',
    'fullCalendar' => true,
    'fullCalendarLocale' => 'sk',
    'datePicker' => true,
    'momentLocale' => 'sk',
    'isRTL' => false,
];
file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
