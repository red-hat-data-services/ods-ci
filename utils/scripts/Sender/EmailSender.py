from Sender import Sender
from typing import Any, List, Optional
import smtplib
from os.path import basename
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import COMMASPACE, formatdate


class EmailSender(Sender):

    def __init__(self):
        self._sender_address = None
        self._receiver_address = None
        self._subject = None
        self._server = "127.0.0.1"
        self._message = MIMEMultipart()

    def prepare_payload(self, text: str = "",
                        attachments: Optional[List[Any]] = None) -> None:
        self._message.attach(MIMEText(text))
        for filepath in attachments:
            with open(filepath, "rb") as file:
                part = MIMEApplication(
                    file.read(),
                    Name=basename(filepath)
                )
                part['Content-Disposition'] = 'attachment; filename="%s"' % basename(filepath)
                self._message.attach(part)

    def prepare_header(self):
        self._message['From'] = self._sender_address
        self._message['To'] = COMMASPACE.join(self._receiver_address)
        self._message['Date'] = formatdate(localtime=True)
        self._message['Subject'] = self._subject

    def send(self):
        smtp = smtplib.SMTP(self._server)
        smtp.sendmail(self._sender_address, self._receiver_address, self._message.as_string())
        smtp.close()

    def set_sender_address(self, sender_address: str) -> None:
        self._sender_address = sender_address

    def get_sender_address(self):
        return self._sender_address

    def set_receiver_address(self, receiver_address: str) -> None:
        self._receiver_address = receiver_address

    def get_receiver_address(self):
        return self._receiver_address

    def set_subject(self, subject: str) -> None:
        self._subject = subject

    def get_subject(self):
        return self._subject

    def set_server(self, server: str) -> None:
        self._server = server

    def get_server(self):
        return self._server

    def get_message(self):
        return self._message

