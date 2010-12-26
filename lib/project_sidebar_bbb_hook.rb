# Provides a link to the issue age graph on the issue index page
require 'open-uri'

class ProjectSidebarBigBlueButtonHook < Redmine::Hook::ViewListener
  def view_projects_show_sidebar_bottom(context = { })
    @project = context[:project]
    output = ""
    begin
      if User.current.allowed_to?(:bigbluebutton_join, @project) || User.current.allowed_to?(:bigbluebutton_start, @project)
        output << "<h3>#{l(:label_bigbluebutton)}</h3>"

        server = Setting.plugin_redmine_bbb['bbb_ip']
        meeting_started=false
        #First, test if meeting room already exists
        moderatorPW=Digest::SHA1.hexdigest("root"+@project.identifier)
        data = callApi(server, "getMeetingInfo","meetingID=" + @project.identifier + "&password=" + moderatorPW, true)
        doc = ActiveSupport::XmlMini.parse(data)
        if doc && doc['response'] && doc['response']['running']
          if doc['response']['running']['__content__'] != "true"
            output << "#{l(:label_bigbluebutton_status)}: <b>#{l(:label_bigbluebutton_status_closed)}</b><br><br>"
          else
            meeting_started = true

            if Setting.plugin_redmine_bbb['bbb_popup'] != '1'
              output << link_to(l(:label_bigbluebutton_join), {:controller => 'bigbluebutton', :action => 'start', :project_id => context[:project], :only_path => true})
            else
              output << "<a href='' onclick='javascript:var wihe = \"width=\"+screen.availWidth+\",height=\"+screen.availHeight; open(\"" + url_for(:controller => 'bigbluebutton', :action => 'start', :project_id => context[:project], :only_path => true) + "\",\"Meeting\",\"directories=no,location=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,\" + wihe);return false;'>#{l(:label_bigbluebutton_join)}</a>"
            end
            output << "<br><br>"

            output << "#{l(:label_bigbluebutton_status)}: <b>#{l(:label_bigbluebutton_status_running)}</b>"
            output << "<br><i>#{l(:label_bigbluebutton_people)}:</i><br>"

            if doc['response']['attendees'] && doc['response']['attendees']['attendee']
              each_xml_element(doc['response']['attendees'], 'attendee') do |element|
                name=element['fullName']['__content__']
                output << "&nbsp;&nbsp;- #{name}<br>"
              end
            end
          end
        else
          output << "#{l(:label_bigbluebutton_status)}: <b>#{l(:label_bigbluebutton_status_closed)}</b><br><br>"
        end

        if !meeting_started
          if User.current.allowed_to?(:bigbluebutton_start, @project)
            if Setting.plugin_redmine_bbb['bbb_popup'] != '1'
              output << link_to(l(:label_bigbluebutton_start), {:controller => 'bigbluebutton', :action => 'start', :project_id => context[:project], :only_path => true})
            else
              output << "<a href='' onclick='javascript:var wihe = \"width=\"+screen.availWidth+\",height=\"+screen.availHeight; open(\"" + url_for(:controller => 'bigbluebutton', :action => 'start', :project_id => context[:project], :only_path => true) + "\",\"Meeting\",\"directories=no,location=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,\" + wihe);return false;'>#{l(:label_bigbluebutton_start)}</a>"
            end
            output << "<br><br>"
          end

        end

      end
    rescue
      output = ""
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
