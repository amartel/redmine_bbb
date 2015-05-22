module BbbMacro
  Redmine::WikiFormatting::Macros.register do
    desc "Insert the link to the BigBlueButton room. Examples: \n\n <pre>{{bbb}}\n{{bbb(project_id)}}\n{{bbb(project_id, 1)}} - show the number of users online\n{{bbb(project_id, 2)}} - private room link</pre>"
    macro :bbb do |obj, args|
      # Check first argument
      if args[0] and !args[0].empty?
        project_identifier = args[0].strip
        project = Project.find_by_identifier(project_identifier)
        return nil unless project
      end

      # Check if project exists, bigbluebutton module is enabled and user has permissions
      project = @project || (obj && obj.project) unless project
      return nil unless project
      return nil unless project.module_enabled?("bigbluebutton")

      # Check second argument
      if args[1] and !args[1].empty?
        case args[1]
          when "1"
            people_online_show = true
          when "2"
            new_room = true
        end
      end

      # Check people online
      people_online_string = ""
      if people_online_show
        meetingID = Bbb.project_to_meetingID(project)
        bbb = Bbb.new(meetingID)
        people_online = bbb.getinfo ? bbb.attendees.size : -1
        if people_online < 0
           people_online_string = " " + "(no connection)"
        elsif people_online != 0
          people_online_string = " " + "(" + people_online.to_s + " " + "online" +")"
        end
      end

      # Show the link
      def self.show_link(name, action, project)
        if User.current.allowed_to?(:bigbluebutton_join, project) and User.current.allowed_to?(:bigbluebutton_start, project)
          url = url_for(:controller => 'bbb', :action => action, :project_id => project.identifier, :only_path => @only_path)
          link_to(name, url)
        else
          name
        end
      end
      if new_room
        link_name = project.name + " - " + "private room"
        h(show_link(link_name, 'new_room', project))
      else
        link_name = project.name + " - " + "meeting room"
        h(show_link(link_name, 'start', project) + people_online_string)
      end
    end
  end
end
