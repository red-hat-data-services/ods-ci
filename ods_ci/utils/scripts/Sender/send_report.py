import argparse

from EmailSender import EmailSender


def send_email_report(
    sender,
    receiver,
    subject,
    text,
    attachments,
    server,
    server_user,
    server_pw,
    ssl,
    unsecure,
):
    print("Composing your email...")
    print("Sender:", sender)
    print("Receiver:", receiver)
    print("Server:", server)

    if ssl is None:
        ssl = False
    elif ssl.lower() == "true":
        ssl = True
    else:
        ssl = False

    if unsecure is None:
        unsecure = False
    elif unsecure.lower() == "true":
        unsecure = True
    else:
        unsecure = False

    if server_user.lower() == "none":
        server_user = None
    if server_pw.lower() == "none":
        server_pw = None

    reporter = EmailSender()
    reporter.set_sender_address(sender_address=sender)
    reporter.set_receiver_addresses(receiver_addresses=receiver)
    reporter.set_subject(subject=subject)
    reporter.set_server(server=server, use_ssl=ssl, use_unsecure=unsecure)
    reporter.set_server_auth(usr=server_user, pw=server_pw)
    reporter.prepare_header()
    reporter.prepare_payload(text=text, attachments=attachments)
    reporter.send()
    print("email sent to: ", receiver)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Script to publish ods-ci results",
    )

    subparsers = parser.add_subparsers(title="Available sub commands", help="sub-command help")

    # Argument parsers for sending report by email
    email_sender_parser = subparsers.add_parser(
        "send_email_report",
        help="Send RF report of results by email",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    args_email_sender_parser = email_sender_parser.add_argument_group("arguments")

    args_email_sender_parser.add_argument(
        "-s", "--sender-address", help="Send email from", action="store", required=True
    )

    args_email_sender_parser.add_argument("-r", "--receiver-addresses", help="Send email to", nargs="+", required=True)

    args_email_sender_parser.add_argument(
        "-b",
        "--subject",
        help="Email subject",
        action="store",
        default="ods-ci Test Execution Report",
        required=False,
    )

    args_email_sender_parser.add_argument(
        "-t",
        "--text",
        help="Email text content",
        action="store",
        default="You are getting this email because this email address has been set as "
        "receiver for ods-ci (i.e., RHODS testing suite) execution results",
        required=False,
    )

    args_email_sender_parser.add_argument(
        "-a",
        "--attachments",
        help="Files to attach to the email",
        nargs="+",
        required=False,
    )

    args_email_sender_parser.add_argument(
        "-v",
        "--server",
        help="SMTP server",
        action="store",
        default="localhost:587",
        required=False,
    )
    args_email_sender_parser.add_argument(
        "-u",
        "--server-user",
        help="SMTP server user",
        action="store",
        default="None",
        required=False,
    )
    args_email_sender_parser.add_argument(
        "-p",
        "--server-pw",
        help="SMTP server pw",
        action="store",
        default="None",
        required=False,
    )
    args_email_sender_parser.add_argument(
        "-l",
        "--ssl",
        help="Use SSL SMTP server",
        action="store",
        default="false",
        required=False,
    )
    args_email_sender_parser.add_argument(
        "-d",
        "--unsecure",
        help="Use unsecure SMTP server (no encryption)",
        action="store",
        default="false",
        required=False,
    )

    args = parser.parse_args()

    send_email_report(
        args.sender_address,
        args.receiver_addresses,
        args.subject,
        args.text,
        args.attachments,
        args.server,
        args.server_user,
        args.server_pw,
        args.ssl,
        args.unsecure,
    )
