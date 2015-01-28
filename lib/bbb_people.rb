require 'open-uri'
require 'rexml/document'

class BBBPeople
  def self.people_online(project)
    @project = project
    people_online = 0
    begin
      if User.current.allowed_to?(:bigbluebutton_join, @project) || User.current.allowed_to?(:bigbluebutton_start, @project)
        server = Setting.plugin_redmine_bbb['bbb_ip'].empty? ? Setting.plugin_redmine_bbb['bbb_server'] : Setting.plugin_redmine_bbb['bbb_ip']
        moderatorPW=Digest::SHA1.hexdigest("root"+@project.identifier)
        data = callApi(server, "getMeetingInfo","meetingID=" + @project.identifier + "&password=" + moderatorPW, true)
        doc = REXML::Document.new(data)
        if doc.root.elements['returncode'].text != "FAILED"
            people_online = doc.root.elements['attendees'].size
        end
      end
    rescue
      people_online = -1
    end
    return people_online
  end

  private

  def self.callApi (server, api, param, getcontent)
    salt = Setting.plugin_redmine_bbb['bbb_salt']
    tmp = api + param + salt
    checksum = Digest::SHA1.hexdigest(tmp)
    url = server + "/bigbluebutton/api/" + api + "?" + param + "&checksum=" + checksum

    if getcontent
      connection = open(url)
      connection.read
    else
      url
    end

  end

end
