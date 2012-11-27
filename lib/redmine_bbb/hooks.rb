# Provides a link to the issue age graph on the issue index page
require 'open-uri'
require 'rexml/document'
module RedmineBbb

class ProjectSidebarBigBlueButtonHook < Redmine::Hook::ViewListener
  def view_projects_show_sidebar_bottom(context = {})
    @project = context[:project]
    output = ""
    begin
      if(User.current.allowed_to?(:bigbluebutton_join, @project) || User.current.allowed_to?(:bigbluebutton_start, @project))
        url = Setting.plugin_redmine_bbb['bbb_help']
        link = url.empty? ? "" : "&nbsp;&nbsp;<a href='" + url + "' target='_blank' class='icon icon-help'>&nbsp;</a>"

        server = Setting.plugin_redmine_bbb['bbb_ip'].empty? ? Setting.plugin_redmine_bbb['bbb_server'] : Setting.plugin_redmine_bbb['bbb_ip']
        meeting_started=false
        #First, test if meeting room already exists
        moderatorPW=Digest::SHA1.hexdigest("root"+@project.identifier)
        data = callapi(server, "getMeetingInfo","meetingID=" + @project.identifier + "&password=" + moderatorPW, true)
        
        doc = REXML::Document.new(data)
	      if doc.root.elements['returncode'].text == "FAILED"
            output << "<div class=\"status\">(#{l(:label_bigbluebutton_status_closed)})</div>"
            output << "<h4 style=\"margin-bottom:0px\">#{l(:label_bigbluebutton)}#{link}</h4>"
        else
            meeting_started = true
            output << "<div class=\"status\">(#{l(:label_bigbluebutton_status_running)})</div>"
            output << "<h4 style=\"margin-bottom:0px\">#{l(:label_bigbluebutton)}#{link}</h4>"
            if Setting.plugin_redmine_bbb['bbb_popup'] != '1'
              output << "<ul style=\"padding-top:0px\"><li>"
              output << link_to(l(:label_bigbluebutton_join), {:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true})
              output << "</li></ul>"
            else
              output << "<ul style=\"padding-top:0px\"><li><a href='' onclick='javascript:var wihe = \"width=\"+screen.availWidth+\",height=\"+screen.availHeight; open(\"" + url_for(:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true) + "\",\"Meeting\",\"directories=no,location=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,\" + wihe);return false;'>#{l(:label_bigbluebutton_join)}</a></li></ul>"
            end
            output << "<div class=\"people\">#{l(:label_bigbluebutton_people)}:<br><ul>"

	          doc.root.elements['attendees'].each do |attendee|
	            name=attendee.elements['fullName'].text
              output << "<li>#{name}</li>"
	          end
	          output << "</ul></div>"
        end

         if !meeting_started
           if User.current.allowed_to?(:bigbluebutton_start, @project)
             if Setting.plugin_redmine_bbb['bbb_popup'] != '1'
               output << "<ul><li>"
               output << link_to(l(:label_bigbluebutton_start), {:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true})
               output << "</li></ul>"
             else
               output << "<ul><li><a href='' onclick='javascript:var wihe = \"width=\"+screen.availWidth+\",height=\"+screen.availHeight; open(\"" + url_for(:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true) + "\",\"Meeting\",\"directories=no,location=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,\" + wihe);return false;'>#{l(:label_bigbluebutton_start)}</a></li></ul>"
             end
           end

         end
       end
    rescue Exception => e
      config.logger.error(e.message)
      config.logger.error(e.backtrace.inspect)
      #output = ""
      output = "<h4>#{l(:label_bigbluebutton)}</h4>"
      output << "<p>#{l(:label_bigbluebutton_error)}</p>"
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

  def callapi (server, api, param, getcontent)
    salt = Setting.plugin_redmine_bbb['bbb_salt']
    tmp = api + param + salt
    checksum = Digest::SHA1.hexdigest(tmp)
    url = server + "/bigbluebutton/api/" + api + "?" + param + "&checksum=" + checksum
    if getcontent
      connection = open(url)
      return connection.read
    else
      return url
    end
  end

end
end
