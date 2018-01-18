use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or you later on).
config :hello_phoenix,
  api_key: System.get_env("GITHUB_API_KEY"),
  cb_user: System.get_env("CB_USER"),
  cb_pass: System.get_env("CB_PASS"),
  jenkins_user: System.get_env("JENKINS_USER"),
  jenkins_pass: System.get_env("JENKINS_PASS"),
  trello_key: System.get_env("TRELLO_KEY"),
  trello_token: System.get_env("TRELLO_TOKEN")
