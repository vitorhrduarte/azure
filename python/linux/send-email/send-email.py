import smtplib

from email.message import EmailMessage

def email():
    '''Function to send  MAIL'''
    print("Email process Started...")
    Subject = "Test Mail" 
    Body = "Hi,\n\nThis is a test mail.\n\n "
    try:
        server = smtplib.SMTP('mail-srv.snotfcp.local',port=25)
        server.ehlo()
        msg = EmailMessage()
        msg['From'] = "amail"
        msg['To'] = "bmail,"
        msg['Subject'] = Subject
        msg.set_type('text/html')
        msg.set_content(Body)
        server.send_message(msg)
        print("Email Sent Successfully.. !")
        server.quit()
    except Exception as e:
        print(e)
if __name__ == "__main__":
    email()
