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
#   HUBOT_JIRA_LOOKUP_SIMPLE
#   HUBOI_JIRA_LOOKUP_TIMEOUT
#
# Commands:
#   hubot set jira_lookup_style [long|short]
#
# Author:
#   Matthew Finlayson <matthew.finlayson@jivesoftware.com> (http://www.jivesoftware.com)
#   Benjamin Sherman  <benjamin@jivesoftware.com> (http://www.jivesoftware.com)
#   Dustin Miller <dustin@sharepointexperts.com> (http://sharepointexperience.com)

## Prevent the bot sending the jira ticket details too often in any channel

## Store when a ticket was reported to a channel
# Key:   channelid-ticketid
# Value: timestamp
# 
LastHeard = {}

RecordLastHeard = (robot,channel,ticket) ->
  ts = new Date()
  key = "#{channel}-#{ticket}"
  LastHeard[key] = ts

CheckLastHeard = (robot,channel,ticket) ->
  now = new Date()
  key = "#{channel}-#{ticket}"
  last = LastHeard[key] || 0
  timeout =  process.env.HUBOT_JIRA_LOOKUP_TIMEOUT || 15
  limit = (1000 * 60 * timeout)
  diff = now - last

  robot.logger.debug "Check: #{key} #{diff} #{limit}"
  
  if diff < limit
    return yes
  no

StylePrefStore = {}

SetRoomStylePref = (robot, msg, pref) ->
  room  = msg.message.user.reply_to || msg.message.user.room
  StylePrefStore[room] = pref
  storePrefToBrain robot, room, pref
  msg.send "Jira Lookup Style Set To #{pref} For #{room}"

GetRoomStylePref = (robot, msg) ->
  room  = msg.message.user.reply_to || msg.message.user.room
  def_style = process.env.HUBOT_JIRA_LOOKUP_STYLE || "long"
  rm_style = StylePrefStore[room]
  if rm_style
    return rm_style
  def_style
  
storePrefToBrain = (robot, room, pref) ->
  robot.brain.data.jiralookupprefs[room] = pref

syncPrefs = (robot) ->
  nonCachedPrefs = difference(robot.brain.data.jiralookupprefs, StylePrefStore)
  for own room, pref of nonCachedPrefs
    StylePrefStore[room] = pref

  nonStoredPrefs = difference(StylePrefStore, robot.brain.data.jiralookupprefs)
  for own room, pref of nonStoredPrefs
    storePrefToBrain robot, room, pref

difference = (obj1, obj2) ->
  diff = {}
  for room, pref of obj1
    diff[room] = pref if room !of obj2
  return diff
  

  

module.exports = (robot) ->
  robot.brain.data.jiralookupprefs or= {}
  robot.brain.on 'loaded', =>
    syncPrefs robot
  
  ignored_users = process.env.HUBOT_JIRA_LOOKUP_IGNORE_USERS
  if ignored_users == undefined
    ignored_users = "jira|github"

  console.log "Ignore Users: #{ignored_users}"

  robot.respond /set jira_lookup_style (long|short)/, (msg) ->
    SetRoomStylePref robot, msg, msg.match[1]

  robot.hear /\b[a-zA-Z]{2,12}-[0-9]{1,10}\b/g, (msg) ->

    return if msg.message.user.name.match(new RegExp(ignored_users, "gi"))

    robot.logger.debug "Matched: "+msg.match.join(',')

    reportIssue robot, msg, issue for issue in msg.match


reportIssue = (robot, msg, issue) ->
  room  = msg.message.user.reply_to || msg.message.user.room
    
  robot.logger.debug "Issue: #{issue} in channel #{room}"

  return if CheckLastHeard(robot, room, issue)

  RecordLastHeard robot, room, issue

  if process.env.HUBOT_JIRA_LOOKUP_SIMPLE is "true"
    msg.send "Issue: #{issue} - #{process.env.HUBOT_JIRA_LOOKUP_URL}/browse/#{issue}"
  else
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

          data = {
            'key': {
              key: 'Key'
              value: issue
            }
            'summary': {
              key: 'Summary'
              value: json.fields.summary || null
            }
            'link': {
              key: 'Link'
              value: "#{process.env.HUBOT_JIRA_LOOKUP_URL}/browse/#{json.key}"
            }
            'description': {
              key: 'Description',
              value: json.fields.description || null
            }
            'assignee': {
              key: 'Assignee',
              value: (json.fields.assignee && json.fields.assignee.displayName) || 'Unassigned'
            }
            'reporter': {
              key: 'Reporter',
              value: (json.fields.reporter && json.fields.reporter.displayName) || null
            }
            'created': {
              key: 'Created',
              value: json.fields.created && (new Date(json.fields.created)).toLocaleString() || null
            }
            'status': {
              key: 'Status',
              value: (json.fields.status && json.fields.status.name) || null
            }
          }

          style = GetRoomStylePref robot, msg
            
          if style is "long"
            fallback = "Issue:\t #{data.key.value}: #{data.summary.value}\n"
            if data.description.value? and inc_desc.toUpperCase() is "Y"
              if max_len and data.description.value?.length > max_len
                fallback += "Description:\t #{data.description.value.substring(0,max_len)} ...\n"
              else
                fallback += "Description:\t #{data.description.value}\n"
            fallback += "Assignee:\t #{data.assignee.value}\nStatus:\t #{data.status.value}\nLink:\t #{data.link.value}\n"
          else
            fallback = "#{data.key.value}: #{data.summary.value} [status #{data.status.value}; assigned to #{data.assignee.value} ] #{data.link.value}"
            

          if process.env.HUBOT_SLACK_INCOMING_WEBHOOK?
            if style is "long"
              robot.emit 'slack.attachment',
                message: msg.message
                content:
                  fallback: fallback
                  title: "#{data.key.value}: #{data.summary.value}"
                  title_link: data.link.value
                  text: data.description.value
                  fields: [
                    {
                      title: data.reporter.key
                      value: data.reporter.value
                      short: true
                    }
                    {
                      title: data.assignee.key
                      value: data.assignee.value
                      short: true
                    }
                    {
                      title: data.status.key
                      value: data.status.value
                      short: true
                    }
                    {
                      title: data.created.key
                      value: data.created.value
                      short: true
                    }
                  ]
            else
              robot.emit 'slack.attachment',
                message: msg.message
                content:
                  fallback: fallback
                  title: "#{data.key.value}: #{data.summary.value}"
                  title_link: data.link.value
                  text: "Status: #{data.status.value}; Assigned: #{data.assignee.value}"
          else
            msg.send fallback
        catch error
          console.log error
