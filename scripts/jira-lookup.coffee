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
#   HUBOT_JIRA_LOOKUP_IGNORE_USERS (optional, format: "user1|user2", default is "jira|github")
#   HUBOT_JIRA_LOOKUP_INC_DESC
#   HUBOT_JIRA_LOOKUP_MAX_DESC_LEN
#   
#
# Commands:
#   None
#
# Author:
#   Matthew Finlayson <matthew.finlayson@jivesoftware.com> (http://www.jivesoftware.com)
#   Benjamin Sherman  <benjamin@jivesoftware.com> (http://www.jivesoftware.com)
#   Dustin Miller <dustin@sharepointexperts.com> (http://sharepointexperience.com)

module.exports = (robot) ->

  ignored_users = process.env.HUBOT_JIRA_LOOKUP_IGNORE_USERS
  if ignored_users == undefined
    ignored_users = "jira|github"

  console.log "Ignoore Users: #{ignored_users}"

  robot.hear /\b[a-zA-Z]{2,12}-[0-9]{1,10}\b/, (msg) ->

    console.log "User: #{msg.messages.user.name}";

    return if msg.message.user.name.match(new RegExp(ignored_users, "gi"))

    issue = msg.match[0]
    user = process.env.HUBOT_JIRA_LOOKUP_USERNAME
    pass = process.env.HUBOT_JIRA_LOOKUP_PASSWORD
    url = process.env.HUBOT_JIRA_LOOKUP_URL

    inc_desc = process.env.HUBOT_JIRA_LOOKUP_INC_DESC
    if inc_desc == undefined
       inc_desc = "Y"

    max_len = process.env.HUBOT_JIRA_LOOKUP_MAX_DESC_LEN

    auth = 'Basic ' + new Buffer(user + ':' + pass).toString('base64')
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
          if json.fields.description and inc_desc.toUpperCase() is "Y"
            json_description = "\n Description: "
            unless json.fields.description is null or json.fields.description.nil? or json.fields.description.empty?
              desc_array = json.fields.description.split("\n")
              for item in desc_array[0..2]
                json_description += item
              if max_len and json_description.length > max_len
                 json_description = json_description.substring(0,max_len) + "..."
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

          
          
          if process.env.HUBOT_SLACK_INCOMING_WEBHOOK?
            robot.emit 'slack.attachment',
              message: msg.message
              content:
                text: 'Issue details'
                fallback: 'Issue:       #{json.key}: #{json_summary}#{json_description}#{json_assignee}#{json_status}\n Link:        #{process.env.HUBOT_JIRA_LOOKUP_URL}/browse/#{json.key}\n'
                fields: [
                  {
                  title: 'Summary'
                  value: "#{json_summary}"
                  },
                  {
                  title: 'Description'
                  value: "#{json_description}"
                  },
                  {
                  title: 'Assignee'
                  value: "#{json_assignee}"
                  },
                  {
                  title: 'Status'
                  value: "#{json_status}"
                  },
                  {
                  title: 'Link'
                  value: "<#{process.env.HUBOT_JIRA_LOOKUP_URL}/browse/#{json.key}>"
                  }
                ]
          else
            msg.send "Issue:       #{json.key}: #{json_summary}#{json_description}#{json_assignee}#{json_status}\n Link:        #{process.env.HUBOT_JIRA_LOOKUP_URL}/browse/#{json.key}\n"
        catch error
          console.log "Issue #{json.key} not found"
