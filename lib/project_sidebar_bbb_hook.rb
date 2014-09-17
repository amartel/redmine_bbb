# Provides a link to the issue age graph on the issue index page
require 'open-uri'
require 'rexml/document'

class ProjectSidebarBigBlueButtonHook < Redmine::Hook::ViewListener
  def view_projects_show_sidebar_bottom(context = { })
    @project = context[:project]
    output = ""
    begin
      if User.current.allowed_to?(:bigbluebutton_join, @project) || User.current.allowed_to?(:bigbluebutton_start, @project)
        url = Setting.plugin_redmine_bbb['bbb_help']
        link = url.empty? ? "" : "&nbsp;&nbsp;<a href='" + url + "' target='_blank' class='icon icon-help'>&nbsp;</a>"

        output << "<h3>#{l(:label_bigbluebutton)}#{link}</h3>"

        server = Setting.plugin_redmine_bbb['bbb_ip'].empty? ? Setting.plugin_redmine_bbb['bbb_server'] : Setting.plugin_redmine_bbb['bbb_ip']
        meeting_started=false
        #First, test if meeting room already exists
        moderatorPW=Digest::SHA1.hexdigest("root"+@project.identifier)
        data = callApi(server, "getMeetingInfo","meetingID=" + @project.identifier + "&password=" + moderatorPW, true)
	doc = REXML::Document.new(data)
	if doc.root.elements['returncode'].text == "FAILED"
            output << "#{l(:label_bigbluebutton_status)}: <b>#{l(:label_bigbluebutton_status_closed)}</b><br><br>"
        else
            meeting_started = true
            if Setting.plugin_redmine_bbb['bbb_popup'] != '1'
              output << link_to(l(:label_bigbluebutton_join), {:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true})
            else
              output << "<a href='' onclick='javascript:var wihe = \"width=\"+screen.availWidth+\",height=\"+screen.availHeight; open(\"" + url_for(:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true) + "\",\"Meeting\",\"directories=no,location=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,\" + wihe);return false;'>#{l(:label_bigbluebutton_join)}</a>"
            end
            output << "<br><br>"
            output << "#{l(:label_bigbluebutton_status)}: <b>#{l(:label_bigbluebutton_status_running)}</b>"
            output << "<br><i>#{l(:label_bigbluebutton_people)}:</i><br>"

	    doc.root.elements['attendees'].each do |attendee|
	       name=attendee.elements['fullName'].text
               output << "&nbsp;&nbsp;- #{name}<br>"
	    end
        end

        if !meeting_started
          if User.current.allowed_to?(:bigbluebutton_start, @project)
            if Setting.plugin_redmine_bbb['bbb_popup'] != '1'
              output << link_to(l(:label_bigbluebutton_start), {:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true})
            else
              output << "<a href='' onclick='javascript:var wihe = \"width=\"+screen.availWidth+\",height=\"+screen.availHeight; open(\"" + url_for(:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true) + "\",\"Meeting\",\"directories=no,location=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,\" + wihe);return false;'>#{l(:label_bigbluebutton_start)}</a>"
            end
            output << "<br><br>"
          end

        end

      end
    rescue
      output = "<h3>#{l(:label_bigbluebutton)}</h3>"
      output << "#{l(:label_bigbluebutton_error)}"
    end
    return output
  end

  private

  def each_xml_element(node, name)
    if node && node[name]
      if node[name].is_a?(Hash)
        yield node[name]
      else
        node[name].each do |element|
          yield element
        end
      end
    end
  end

  def callApi (server, api, param, getcontent)
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
