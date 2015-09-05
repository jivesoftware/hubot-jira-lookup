# Jira Issue lookup script for Hubot

## Installation

Add the package `hubot-jira-lookup` as a dependency in your Hubot `package.json` file.

	"dependencies": {
		"hubot-jira-lookup": "git://github.com/jivesoftware/hubot-jira-lookup.git"
	}

Run the following command to make sure the package is installed.

	$ npm install

To enable the script, add the `hubot-jira-lookup` entry to the `external-scripts.json` file (you may need to create this file, if it is not present or if you upgraded from Hubot < 2.4).

	["hubot-jira-lookup"]

## Configuration

You can run this script in simple mode, which will only return a link to JIRA issue. It's usable in cases like: your JIRA instance is behind company firewall and Hubot instance it's outside. Or you just want such kind of behaviour. To enable this mode just set `HUBOT_JIRA_LOOKUP_SIMPLE=true`. Please note, that due to the lack of real conection to the JIRA it won't check if issue really exists.

In other case - there are three configuration values required for full jira-lookup to work properly.

* `HUBOT_JIRA_LOOKUP_USERNAME`
* `HUBOT_JIRA_LOOKUP_PASSWORD`
* `HUBOT_JIRA_LOOKUP_URL`

There are also optional configuration values.

* `HUBOT_JIRA_LOOKUP_IGNORE_USERS` - allows you to ignore messages from pre-defined users. Default is to ignore from users named "jira" and "github", casing is ignored.
* `HUBOT_SLACK_INCOMING_WEBHOOK` - allows you to output responses formatted as [Slack Attachments](https://api.slack.com/docs/attachments).
