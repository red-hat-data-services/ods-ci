# Arguments for ODS-CI run script
* ```--skip-oclogin``` (default: false): script does not perform login using OC CLI
* ```--service-account``` (default: ""): if assigned, ODS-CI will try to log into the cluster using the given service account.
            ODS-CI automatically creates SERVICE_ACCOUNT.NAME and SERVICE_ACCOUNT.FULL_NAME global variables to be used in tests.
    * ```--sa-namespace``` (default: "default"): the namespace where the service account is created
* ```--set-urls-variables``` (default: false): script gets automatically the cluster URLs (i.e., OCP Console, RHODS Dashboard, OCP API Server)
* ```--include```: run only test cases with the given tags (e.g., ```--include Smoke```--include XYZ)
* ```--exclude```: do not run the test cases with the given tag (e.g., ```--exclude LongLastingTC```)
* ```--test-variable```: set a global RF variable
* ```--test-variables-file``` (default: ods_ci/test-variables.yml): set the RF file containing global variables to use in TCs
* ```--test-case``` (default: ods_ci/tests/Tests): run only the test cases from the given robot file
* ```--test-artifact-dir``` (default: ods_ci/test-output): set the RF output directory to store log files
* ```--extra-robot-args```: it can contain any of ```robot``` arguments (e.g., ```--dryrun```)
* ```--skip-install``` (default: 0): it skips preparing the python (poetry) virtual environment, assuming you already have all the needed dependency installed
* ```--email-report``` (default: false): send the test run artifacts via email
    * ```--email-from```: (mandatory if email report is true) set the sender email address
    * ```--email-to```: (mandatory if email report is true) set the email address which will receive the result artifacts
    * ```--email-server``` (default: localhost): set the smtp server to use, e.g., smtp.gmail.com:465 (the port specification is not mandatory, the default value is 587)
    * ```--email-server-user```: (optional, depending on the smtp server) username to access smtp server
    * ```--email-server-pw```: (optional, depending on the smtp server) password to access smtp server
    * ```--email-server-ssl```* (default: false): if true, it forces the usage of encrypted connection (TLS)
    * ```--email-server-unsecure```* (default: false): no encryption applied, using SMTP unsecure connection
* ```--open-report``` (default: false): If not `false`, then it opens reports in local browser after the tests run. If set to `true`, then default browser `firefox` is used. You can override the default browser by specifying your own command as a value (e.g.: `--open-report nautilus`).

\* The container uses STARTTLS protocol by default if ```--email-server-ssl and ```--email-server-unsecure are set to false