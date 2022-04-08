import argparse
from EmailSender import EmailSender


def send_email_report(sender, receiver, subject, text, attachments
                      ):
    print("Composing your email...")
    reporter = EmailSender()
    reporter.set_sender_address(sender_address=sender)
    reporter.set_receiver_addresses(receiver_addresses=receiver)
    reporter.set_subject(subject=subject)
    reporter.prepare_header()
    reporter.prepare_payload(text=text,
                             attachments=attachments)
    reporter.send()
    print("email sent to: ", receiver)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Script to publish ods-ci results')

    subparsers = parser.add_subparsers(title='Available sub commands',
                                       help='sub-command help')

    # Argument parsers for sending report by email
    email_sender_parser = subparsers.add_parser(
        'send_email_report',
        help="Send RF report of results by email",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    args_email_sender_parser = email_sender_parser.add_argument_group('arguments')

    args_email_sender_parser.add_argument("-s", "--sender-address",
                                              help="Send email from",
                                              action="store",
                                              required=True)

    args_email_sender_parser.add_argument("-r", "--receiver-addresses",
                                              help="Send email to",
                                              nargs="+",
                                              required=True)

    args_email_sender_parser.add_argument("-b", "--subject",
                                              help="Email subject",
                                              action="store",
                                              default="ods-ci Test Execution Report",
                                              required=False)
    args_email_sender_parser.add_argument("-t", "--text",
                                              help="Email text content",
                                              action="store",
                                              default="You are getting this email because this email address has been set as "\
                                                      "receiver for ods-ci (i.e., RHODS testing suite) execution results",
                                              required=False)
    args_email_sender_parser.add_argument("-a", "--attachments",
                                              help="Files to attach to the email",
                                              nargs="+",
                                              required=False)

    args = parser.parse_args(None)

    send_email_report(args.sender_address,
                      args.receiver_addresses,
                      args.subject,
                      args.text,
                      args.attachments
                      )

