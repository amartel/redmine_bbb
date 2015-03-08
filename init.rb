#WebDav plugin for REDMINE
require 'redmine'
Dir::foreach(File.join(File.dirname(__FILE__), 'lib')) do |file|
  next unless /\.rb$/ =~ file
  require file
end

require_dependency 'project_sidebar_bbb_hook'

Redmine::Plugin.register :redmine_bbb do
  name 'BigBlueButton plugin'
  author 'Arnaud Martel'
  description 'Interface with BigBlueButton server'
  version '0.1.2'

  settings :default => {'bbb_server' => '', 'bbb_salt' => ''}, :partial => 'settings-bbb/settings'

  project_module :bigbluebutton do
    permission :bigbluebutton_join, :bbb => :start
    permission :bigbluebutton_start, {}
    permission :bigbluebutton_moderator, {}
  end
end

Redmine::WikiFormatting::Macros.register do
  desc "Insert the link to the BigBlueButton room. Examples: \n\n <pre>{{bbb}}\n{{bbb(project_id)}}\n{{bbb(project_id, 1)}} - show the number of users online</pre>"
  macro :bbb do |obj, args|
    if args[0] and !args[0].empty?
      project_identifier = args[0].strip
      project = Project.find_by_identifier(project_identifier)
      return nil unless project
    end
    if args[1] and !args[1].empty?
      people_online_show = args[1]
    end
    project = @project unless project
    return nil unless project
    return nil unless project.module_enabled?("bigbluebutton")
    project_id = project.identifier
    project_name = project.name
    people_online_string = ""
    if people_online_show == "1"
      people_online = BBBPeople.people_online(project)
      if people_online < 0
         people_online_string = " " + "(no connection)"
      elsif people_online != 0
        people_online_string = " " + "(" + people_online.to_s + " " + "online" +")"
      end
    end
    link_name = project.name + " - " + "meeting room"
    h(link_to(link_name, {:controller => 'bbb', :action => 'start', :project_id => project_id}) + people_online_string)
  end
end
