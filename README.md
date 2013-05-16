# Jira Issue lookup script for Hubot

## Installation

Add the package `hubot-jira-lookup` as a dependency in your Hubot `package.json file.

	"dependencies": {
		"hubot-jira-lookup": "git://github.com/jivesoftware/hubot-jira-lookup.git"
	}

Run the following command to make sure the package is installed.

	$ npm install

To enable the script, add the `hubot-jira-lookup` entry to the `external-scripts.json` file (you may need to create this file, if it is not present or if you upgraded from Hubot < 2.4).

	["hubot-jira-lookup"]
