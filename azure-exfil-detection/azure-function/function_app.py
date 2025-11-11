import azure.functions as func
import logging
import json
from datetime import datetime
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
import os
STORAGE_CONN_STR = os.environ.get('STORAGE_CONNECTION_STRING')

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

STORAGE_ACCOUNT = "stexfildev2847"
INCIDENT_CONTAINER = "incident-logs"

@app.route(route="playbook")
def response_playbook(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('🚨 Alert received')

    try:
        alert_data = req.get_json()
        caller_ip = extract_ip(alert_data)
        timestamp = datetime.utcnow().isoformat()
        alert_name = alert_data.get('data', {}).get('essentials', {}).get('alertRule', 'Unknown')

        incident_id = log_incident(alert_name, caller_ip, timestamp, alert_data)

        return func.HttpResponse(
            json.dumps({
                "status": "mitigated",
                "incident_id": incident_id,
                "ip": caller_ip
            }),
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f'Error: {e}')
        return func.HttpResponse(str(e), status_code=500)

def extract_ip(alert_data):
    try:
        rows = alert_data['data']['alertContext']['SearchResults']['tables'][0]['rows']
        return rows[0][1] if rows else "Unknown"
    except:
        return "Unknown"

def log_incident(alert_name, ip, timestamp, data):
    if STORAGE_CONN_STR:
       blob_service = BlobServiceClient.from_connection_string(STORAGE_CONN_STR)
    else:
        credential = DefaultAzureCredential()
        blob_service = BlobServiceClient(
        account_url=f"https://{STORAGE_ACCOUNT}.blob.core.windows.net",
        credential=credential
    )

    container = blob_service.get_container_client(INCIDENT_CONTAINER)
    try:
        container.create_container()
    except:
        pass

    incident_id = f"{timestamp.replace(':', '-')}_{ip.replace('.', '-')}"
    blob_name = f"incident-{incident_id}.json"

    blob = container.get_blob_client(blob_name)
    blob.upload_blob(
        json.dumps({
            "incident_id": incident_id,
            "timestamp": timestamp,
            "alert": alert_name,
            "ip": ip,
            "raw": data
        }, indent=2),
        overwrite=True
    )

    logging.info(f'✅ Logged: {incident_id}')
    return incident_id
