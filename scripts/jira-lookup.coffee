# Description:
#   Jira lookup when issues are heard
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JIRA_LOOKUP_USERNAME
#   HUBOT_JIRA_LOOKUP_PASSWORD
#   HUBOT_JIRA_LOOKUP_URL
#
# Commands:
#   None
#
# Author:
#   Matthew Finlayson <matthew.finlayson@jivesoftware.com> (http://www.jivesoftware.com)
#   Benjamin Sherman  <benjamin@jivesoftware.com> (http://www.jivesoftware.com)

module.exports = (robot) ->
  robot.hear /(?:^|\s)[a-zA-Z]{2,5}-[0-9]{1,5}(?:$|\s)/, (msg) ->
    issue = msg.match[0]
    user = process.env.HUBOT_JIRA_LOOKUP_USERNAME
    pass = process.env.HUBOT_JIRA_LOOKUP_PASSWORD
    url = process.env.HUBOT_JIRA_LOOKUP_URL
    auth = 'Basic ' + new Buffer(user + ':' + pass).toString('base64');
    robot.http("#{url}/rest/api/latest/issue/#{issue}")
      .headers(Authorization: auth, Accept: 'application/json')
      .get() (err, res, body) ->
        try
          json = JSON.parse(body)
          json_summary = ""
          if json.fields.summary
              unless json.fields.summary is null or json.fields.summary.nil? or json.fields.summary.empty?
                  json_summary = json.fields.summary
          json_description = ""
          if json.fields.description
              json_description = "\n Description: "
              unless json.fields.description is null or json.fields.description.nil? or json.fields.description.empty?
                  desc_array = json.fields.description.split("\n")
                  for item in desc_array[0..2]
                      json_description += item
          json_assignee = ""
          if json.fields.assignee
              json_assignee = "\n Assignee:    "
              unless json.fields.assignee is null or json.fields.assignee.nil? or json.fields.assignee.empty?
                  unless json.fields.assignee.name.nil? or json.fields.assignee.name.empty?
                      json_assignee += json.fields.assignee.name
          json_status = ""
          if json.fields.status
              json_status = "\n Status:      "
              unless json.fields.status is null or json.fields.status.nil? or json.fields.status.empty?
                  unless json.fields.status.name.nil? or json.fields.status.name.empty?
                      json_status += json.fields.status.name
          msg.send "Issue:       #{json.key}: #{json_summary}#{json_description}#{json_assignee}#{json_status}\n Link:        #{process.env.HUBOT_JIRA_LOOKUP_URL}/browse/#{json.key}\n"
        catch error
          msg.send "*sinister laugh*"
