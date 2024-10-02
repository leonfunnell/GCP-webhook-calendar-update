# main.py
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

    response = {}
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
                event = {
                    'summary': event_name,
                    'description': event_description,
                    'start': {'date': data[0]['pick up date']},
                    'end': {'date': data[0]['return date']}
                }
                if data[0].get('BoxCalID'):
                    event = calendar_service.events().update(
                        calendarId=box_calendar_id,
                        eventId=data[0]['BoxCalID'],
                        body=event
                    ).execute()
                else:
                    event = calendar_service.events().insert(
                        calendarId=box_calendar_id,
                        body=event
                    ).execute()
                response['BoxCalID'] = event['id']

        if mode in ["Collect", "Return"] and data[0].get(f'{mode} Agreed') == "Y":
            event = {
                'summary': event_name,
                'description': event_description,
                'start': {'dateTime': data[0][f'{mode} Appointment']},
                'end': {'dateTime': data[0][f'{mode} Appointment']}
            }
            if data[0].get(f'{mode}CalendarID'):
                event = calendar_service.events().update(
                    calendarId=central_calendar_id,
                    eventId=data[0][f'{mode}CalendarID'],
                    body=event
                ).execute()
            else:
                event = calendar_service.events().insert(
                    calendarId=central_calendar_id,
                    body=event
                ).execute()
            response[f'{mode}CalendarID'] = event['id']

    return jsonify(response), 200

if __name__ == '__main__':
    app.run(debug=True)