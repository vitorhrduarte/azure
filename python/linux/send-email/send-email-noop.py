from smtplib import SMTP

with SMTP ("10.3.100.4") as smtp:
  smtp.noop()
