# import libraries
import os
import sendgrid
from sendgrid.helpers.mail import *
from helpers import env_vars

# list of secret keys stored in the gcp secret manager 
env_keys = env_vars.access_secret_version()

TEMPLATE_ID = env_keys["SENDGRID_TEMPLATE_ID"]
SENDGRID_API_KEY = env_keys["SENDGRID_API_KEY"]
FROM_EMAIL = env_keys["FROM_EMAIL"]


# Configuration file to send emails
def sendEmail(designer_email, designer_name):
    text = '''Estimado {},
    Cordialmente le informamos que el archivo 
    ya se encuentra disponible.
    Feliz día.'''.format(designer_name)

    message.template_id = TEMPLATE_ID

    sg = sendgrid.SendGridAPIClient(api_key=SENDGRID_API_KEY)
    from_email = Email(FROM_EMAIL)
    to_email = To(designer_email)
    subject = "Nuevo diseño recibido."
    content = Content("text/plain", text)
    mail = Mail(from_email, to_email, subject, content)
    response = sg.client.mail.send.post(request_body=mail.get())
    print(response.status_code)
    print(response.body)
    print(response.headers)