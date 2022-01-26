PARTNER_BADGE_TITLE = "Partner managed"
SELF_BADGE_TITLE = "Self-managed"
RH_BADGE_TITLE = "Red Hat managed"
CMS_BADGE_TITLE = "Coming soon"
BETA_BADGE_TITLE = "Beta"


APPS_DICT = {
     "anaconda-ce": {
          "badges": [PARTNER_BADGE_TITLE],
          "provider": "by Anaconda",
          "title": "Anaconda Commercial Edition",
          "description": "Anaconda Commercial Edition is a popular open source package "
                         "distribution and management experience that is optimized for commercial use.",
          "image": "/images/anaconda-ce.svg",
          "sidebar_h1": "Anaconda Commercial Edition",
          "sidebar_links":  [  # link_title, link_url, partial_matching (Optional, True/False)
               ("Get started", "https://anaconda.cloud/register", "partial-matching"),
               ("https://www.anaconda.com/products/commercial-edition", "https://www.anaconda.com/products/commercial-edition"),
               ("https://anaconda.cloud/register", "https://anaconda.cloud/register?utm_source=redhat-rhods-summit")
          ],

     },
     "watson-studio": {
          "badges": [SELF_BADGE_TITLE],
          "provider": "by IBM",
          "title": "IBM Watson Studio",
          "description": "IBM Watson Studio is a platform for embedding AI and machine "
                         "learning into your business and creating custom models with your own data.",
          "image":  "/images/ibm.svg",
          "sidebar_h1": "IBM Watson Studio",
          "sidebar_links":  [
               ("Get started", "https://developer.ibm.com/series/cloud-pak-for-data-learning-path"),
               ("https://marketplace.redhat.com/en-us/products/ibm-watson-studio", "https://marketplace.redhat.com/en-us/products/ibm-watson-studio"),
               ("https://marketplace.redhat.com/en-us/documentation/operators", "https://marketplace.redhat.com/en-us/documentation/operators"),
          ],
     },
     "aikit": {
          "badges": [SELF_BADGE_TITLE],
          "provider": "by Intel®",
          "title": "Intel® oneAPI AI Analytics Toolkit Container",
          "description": "The AI Kit is a set of AI software tools to accelerate "
                         "end-to-end data science and analytics pipelines on Intel® architectures.",
          "image": "/images/oneapi.png",
          "sidebar_h1": "AI Kit",
          "sidebar_links": [
               ("Get started", "https://software.intel.com/content/www/us/en/develop/documentation/get-started-with-ai-linux/top.html"),
               ("Intel® oneAPI AI Analytics Toolkit", "https://software.intel.com/content/www/us/en/develop/tools/oneapi/ai-analytics-toolkit.html#gs.2zxkin"),
               ("https://marketplace.redhat.com/en-us/products/ai-analytics-toolkit", "https://marketplace.redhat.com/en-us/products/ai-analytics-toolkit"),
               ("https://marketplace.redhat.com/en-us/documentation/operators", "https://marketplace.redhat.com/en-us/documentation/operators"),
               ("AI Analytics Toolkit Website", "https://software.intel.com/oneapi/ai-kit"),
               ("AI Analytics Toolkit Code Samples", "https://github.com/oneapi-src/oneAPI-samples/tree/master/AI-and-Analytics"),
          ]
     },
     "jupyterhub": {
          "badges": [RH_BADGE_TITLE],
          "provider": "by Jupyter",
          "title": "JupyterHub",
          "description": "JupyterHub is a multi-user version of the notebook designed "
                         "for companies, classrooms, and research labs.",
          "image": "/images/jupyterhub.svg",
          "sidebar_h1": "JupyterHub",
          "sidebar_links": [
               ("Get started", "https://jupyterhub.readthedocs.io/en/stable/getting-started/index.html"),
               ("Python", "https://www.python.org/downloads/"),
               ("pip", "https://pip.pypa.io/en/stable/"),
               ("conda", "https://conda.io/docs/get-started.html"),
               ("nodejs/npm", "https://www.npmjs.com/"),
               ("Install nodejs/npm", "https://docs.npmjs.com/getting-started/installing-node"),
               ("nodejs/npm", "https://docs.npmjs.com/getting-started/installing-node"),
               ("pluggable authentication module (PAM)", "https://en.wikipedia.org/wiki/Pluggable_authentication_module"),
               ("default Authenticator", "getting-started/authenticators-users-basics.md", "partial-matching"),
               ("Jupyter Notebook", "https://jupyter.readthedocs.io/en/latest/install.html"),
               ("wiki", "https://github.com/jupyterhub/jupyterhub/wiki/Using-sudo-to-run-JupyterHub-without-root-privileges")
          ]
     },
     "rhoam": {
          "badges": [RH_BADGE_TITLE],
          "provider": "by Red Hat",
          "title": "OpenShift API Management",
          "description": "OpenShift API Management is a service that accelerates time-to-value "
                         "and reduces the cost of delivering API-first, microservices-based applications.",
          "image": "/images/red-hat.svg",
          "sidebar_h1": "Red Hat OpenShift API Management",
          "sidebar_links": [
               ("Get started", "https://console.redhat.com/openshift/details/", "partial-matching"),
               ("https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-api-management", "https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-api-management"),
               ("https://access.redhat.com/documentation/en-us/red_hat_openshift_api_management", "https://access.redhat.com/documentation/en-us/red_hat_openshift_api_management")
          ]
     },
     "rhosak": {
          "badges": [RH_BADGE_TITLE],
          "provider": "by Red Hat",
          "title": "OpenShift Streams for Apache Kafka",
          "description": "OpenShift Streams for Apache Kafka is a service for streaming data "
                         "that reduces the cost and complexity of delivering real-time applications.",
          "image": "/images/red-hat.svg",
          "sidebar_h1": "Red Hat OpenShift Streams for Apache Kafka",
          "sidebar_links": [
               ("Get started", "https://cloud.redhat.com/beta/application-services/streams/kafkas"),
               ("https://access.redhat.com/documentation/en-us/red_hat_openshift_streams_for_apache_kafka", "https://access.redhat.com/documentation/en-us/red_hat_openshift_streams_for_apache_kafka"),
               ("https://cloud.redhat.com/application-services/streams/kafkas", "https://cloud.redhat.com/beta/application-services/streams/kafkas")
          ]
     },
     "openvino": {
          "badges": [SELF_BADGE_TITLE],
          "provider": "by Intel",
          "title": "OpenVINO",
          "description": "OpenVINO is an open source toolkit to help optimize deep "
                         "learning performance and deploy using an inference engine onto Intel hardware.",
          "image": "/images/openvino.svg",
          "sidebar_h1": "OpenVINO Toolkit",
          "sidebar_links": [
               ("Get started", "https://github.com/openvinotoolkit/openvino_notebooks"),
               ("OpenVINO Toolkit", "https://software.intel.com/content/www/us/en/develop/tools/openvino-toolkit.html"),
               ("https://marketplace.redhat.com/en-us/products/openvino", "https://marketplace.redhat.com/en-us/products/openvino"),
               ("https://marketplace.redhat.com/en-us/documentation/operators", "https://marketplace.redhat.com/en-us/documentation/operators")
          ]
     },
     "pachyderm": {
          "badges": [SELF_BADGE_TITLE],
          "provider": "by Pachyderm",
          "title": "Pachyderm",
          "description": "Pachyderm is the data foundation for machine learning. "
                         "It provides industry-leading data versioning, "
                         "pipelines, and lineage for data science teams to automate "
                         "the machine learning lifecycle and optimize machine learning operations (MLOps).",
          "image": "/images/pachyderm.svg",
          "sidebar_h1": "Pachyderm",
          "sidebar_links": [
               ("Get started", "https://marketplace.redhat.com/en-us/products/pachyderm"),
               ("Pachyderm", "https://www.pachyderm.com/"),
               ("Case studies", "https://www.pachyderm.com/case-studies/"),
               ("main concepts", "https://docs.pachyderm.com/latest/concepts/"),
               ("Open CV", "https://docs.pachyderm.com/latest/getting_started/beginner_tutorial/"),
               ("Subscribe to the operator on Marketplace.", "https://marketplace.redhat.com/en-us/products/pachyderm"),
               ("Install the operator and validate.", "https://marketplace.redhat.com/en-us/documentation/operators"),
               ("tutorial", "https://docs.pachyderm.com/latest/getting_started/beginner_tutorial/"),
               ("Housing prices notebook", "https://github.com/pachyderm/examples/blob/master/housing-prices-intermediate/housing-prices.ipynb"),
               ("Pachyderm's python client", "https://python-pachyderm.readthedocs.io/en/stable/")
          ]

     },
     "perceptiLabs": {
          "badges": [CMS_BADGE_TITLE],
          "provider": "by PercetiLabs",
          "title": "PerceptiLabs",
          "description": "PerceptiLabs is a visual modeling tool for editing, managing, "
                         "and monitoring your machine learning models.",
          "image": "/images/percepti-labs.svg",
          "sidebar_h1": "PerceptiLabs",
          "sidebar_links": []

     },
     "seldon-deploy": {
          "badges": [SELF_BADGE_TITLE],
          "provider": "by Seldon",
          "title": "Seldon Deploy",
          "description": "Seldon Deploy is a set of tools to simplify and accelerate "
                         "the process of deploying and managing your machine learning models.",
          "image": "/images/seldon.svg",
          "sidebar_h1": "Seldon Deploy",
          "sidebar_links": [
               ("Get started", "https://deploy.seldon.io/en/latest/contents/getting-started/"),
               ("Seldon Deploy", "https://deploy.seldon.io/"),
               ("Seldon Core", "https://github.com/SeldonIO/seldon-core"),
               ("Seldon Core resources", "https://docs.seldon.io/projects/seldon-core/en/latest/workflow/overview.html"),
               ("https://deploy.seldon.io/en/v1.2/contents/getting-started/openshift-installation/index.html", "https://deploy.seldon.io/en/v1.2/contents/getting-started/openshift-installation/index.html"),
               ("https://marketplace.redhat.com/en-us/products/seldon-deploy", "https://marketplace.redhat.com/en-us/products/seldon-deploy"),
               ("https://marketplace.redhat.com/en-us/documentation/operators", "https://marketplace.redhat.com/en-us/documentation/operators")
          ]
     },
     "starburst": {
          "badges": [PARTNER_BADGE_TITLE, BETA_BADGE_TITLE],
          "provider": "by Starburst",
          "title": "Starburst Galaxy",
          "description": "Starburst Galaxy is a fully managed service to run high-performance "
                         "queries across your various data sources using SQL.",
          "image": "/images/starburst.svg",
          "sidebar_h1": "Starburst Galaxy",
          "sidebar_links": [
               ("Get started", "https://www.starburst.io/platform/starburst-galaxy/"),
               ("signing up for beta access.", "https://www.starburst.io/platform/starburst-galaxy/"),
               ("Starburst Galaxy", "https://docs.starburst.io/starburst-galaxy/"),
               ("signing up for beta access", "https://www.starburst.io/platform/starburst-galaxy/")
          ]
     },
}
