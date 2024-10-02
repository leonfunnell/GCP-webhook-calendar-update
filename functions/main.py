# functions/main.py
import json
import os
from googleapiclient.discovery import build
from google.oauth2 import service_account
from flask import Flask, request, jsonify

app = Flask(__name__)

def get_calendar_service():
    credentials = service_account.Credentials.from_service_account_info(
        json.loads(os.environ['GCP_SERVICE_ACCOUNT_SECRET']),
        scopes=['https://www.googleapis.com/auth/calendar']
    )
    return build('calendar', 'v3', credentials=credentials)

@app.route('/', methods=['POST'])
def webhook():
    if request.headers.get('x-webhook-source') != os.environ['HEADER_SOURCE_TO_PASS']:
        return "Unauthorized", 401

    data = request.json
    calendar_service = get_calendar_service()
    calendar_list = calendar_service.calendarList().list().execute()
    calendars = {cal['summary']: cal['id'] for cal in calendar_list['items']}
    
    central_calendar_id = os.environ['GOOGLE_DEFAULT_CALENDAR_ID']
    box_calendar_id = calendars.get(data[0]['box'])

    collect_calendar_id = None
    return_calendar_id = None
    box_cal_id = None

    for mode in ["Collect", "Return", "Box"]:
        event_name = f"{mode} Appointment - {data[0]['name']} - {data[0]['box']} - {data[0]['bars needed']} - {data[0]['car']}"
        event_description = f"""
        Name: {data[0]['name']}
        Box: {data[0]['box']}
        Status: {data[0]['status']}
        Collect Date: {data[0]['pick up date']}
        Collection Appointment: {data[0]['Collection Appointment']}
        Return Date: {data[0]['return date']}
        Return Appointment: {data[0]['Return Appointment']}
        Duration: {data[0]['duration']} days 
        Car: {data[0]['car']}
        Phone: {data[0]['phone']}
        Contact: {data[0]['contact']}
        Price: {data[0]['price']}
        Deposit: {data[0]['Deposit']}
        Price/day: {data[0]['price/day']}
        Bars: {data[0]['bars needed']}
        """

        if mode == "Box":
            if data[0]['status'] in ["Confirmed", "On Loan", "Returned"]:
                our_calendar_id = box_calendar_id
                calendar_entry_id = data[0].get('BoxCalID')
                all_day_event = "Yes"
                start_date = data[0]['pick up date']
                end_date = data[0]['return date']
                event_duration = ""
                event_reminders = ""
                box_cal_id = upsert_calendar_event(calendar_service, our_calendar_id, calendar_entry_id, event_name, event_description, start_date, end_date, all_day_event, event_duration, event_reminders)

        if mode in ["Collect", "Return"]:
            if data[0].get(f'{mode} Agreed') == "Y" and data[0]['status'] in ["Confirmed", "On Loan", "Returned"]:
                our_calendar_id = central_calendar_id
                calendar_entry_id = data[0].get(f'{mode}CalendarID')
                all_day_event = "No"
                event_duration = "24 hours"
                start_date = data[0][f'{mode} Appointment']
                end_date = ""
                event_duration = "00:30"
                event_reminders = """
                    Item 1:
                        Method: Pop-up
                        Minutes before: 180
                    Item 2:
                        Method: Pop-up
                        Minutes before: 30
                    Item 3:
                        Method: Email
                        Minutes before: 180
                    Show time as: busy
                """
                if mode == "Collect":
                    collect_calendar_id = upsert_calendar_event(calendar_service, our_calendar_id, calendar_entry_id, event_name, event_description, start_date, end_date, all_day_event, event_duration, event_reminders)
                elif mode == "Return":
                    return_calendar_id = upsert_calendar_event(calendar_service, our_calendar_id, calendar_entry_id, event_name, event_description, start_date, end_date, all_day_event, event_duration, event_reminders)

    return jsonify({
        "CollectCalendarID": collect_calendar_id,
        "ReturnCalendarID": return_calendar_id,
        "BoxCalID": box_cal_id
    }), 200

def upsert_calendar_event(service, calendar_id, event_id, summary, description, start, end, all_day, duration, reminders):
    event = {
        'summary': summary,
        'description': description,
        'start': {
            'dateTime': start,
            'timeZone': 'UTC',
        },
        'end': {
            'dateTime': end,
            'timeZone': 'UTC',
        },
        'reminders': {
            'useDefault': False,
            'overrides': [
                {'method': 'popup', 'minutes': 180},
                {'method': 'popup', 'minutes': 30},
                {'method': 'email', 'minutes': 180},
            ],
        },
    }

    if all_day == "Yes":
        event['start'] = {'date': start}
        event['end'] = {'date': end}

    if event_id:
        updated_event = service.events().update(calendarId=calendar_id, eventId=event_id, body=event).execute()
    else:
        updated_event = service.events().insert(calendarId=calendar_id, body=event).execute()

    return updated_event['id']

if __name__ == '__main__':
    app.run(debug=True)