import smtplib
import ssl
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import COMMASPACE, formatdate
from os.path import basename
from typing import Any

from Sender import Sender


class EmailSender(Sender):
    def __init__(self):
        self._sender_address = None
        self._receiver_addresses = None
        self._subject = None
        self._server = "127.0.0.1"
        self._port = 587
        self._server_usr = ""
        self._server_pw = ""
        self._use_ssl = False
        self._use_unsecure = False
        self._message = MIMEMultipart()

    def prepare_payload(
        self, text: str = "", attachments: list[Any] | None = None
    ) -> None:
        self._message.attach(MIMEText(text))
        if attachments is not None:
            for filepath in attachments:
                with open(filepath, "rb") as file:
                    part = MIMEApplication(file.read(), Name=basename(filepath))
                    part["Content-Disposition"] = (
                        'attachment; filename="%s"' % basename(filepath)
                    )
                    self._message.attach(part)

    def prepare_header(self):
        self._message["From"] = self._sender_address
        self._message["To"] = COMMASPACE.join(self._receiver_addresses)
        self._message["Date"] = formatdate(localtime=True)
        self._message["Subject"] = self._subject

    def send(self):
        context = ssl.create_default_context()
        print("use SMTP with ssl: ", self._use_ssl)
        print("use unsecure SMTP (no encryption): ", self._use_unsecure)
        if self._use_unsecure:
            smtp = smtplib.SMTP(host=self._server, port=self._port)
        elif self._use_ssl:
            smtp = smtplib.SMTP_SSL(host=self._server, port=self._port, context=context)
        else:
            print("--> using SMTP with TLS")
            smtp = smtplib.SMTP(host=self._server, port=self._port)
            smtp.starttls(context=context)
        if self._server_usr and self._server_pw:
            smtp.login(self._server_usr, self._server_pw)
        smtp.sendmail(
            self._sender_address, self._receiver_addresses, self._message.as_string()
        )
        smtp.close()

    def set_sender_address(self, sender_address: str) -> None:
        self._sender_address = sender_address

    def get_sender_address(self) -> str:
        return self._sender_address

    def set_receiver_addresses(self, receiver_addresses: list) -> None:
        self._receiver_addresses = receiver_addresses

    def get_receiver_addresses(self) -> list:
        return self._receiver_addresses

    def set_subject(self, subject: str) -> None:
        self._subject = subject

    def get_subject(self) -> str:
        return self._subject

    def set_server(
        self, server: str, use_ssl: bool = False, use_unsecure: bool = False
    ) -> None:
        if ":" in server:
            server = server.split(":")
            self._server = server[0]
            self._port = server[1]
        else:
            self._server = server
        self._use_ssl = use_ssl
        self._use_unsecure = use_unsecure

    def set_server_auth(self, usr: str, pw: str) -> None:
        self._server_usr = usr
        self._server_pw = pw

    def get_server(self):
        return self._server

    def get_message(self):
        return self._message
