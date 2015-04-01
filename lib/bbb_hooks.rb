class BbbHooks < Redmine::Hook::ViewListener
  def view_projects_show_sidebar_bottom(context = { })
    @project = context[:project]
    if User.current.allowed_to?(:bigbluebutton_join, @project) || User.current.allowed_to?(:bigbluebutton_start, @project)
      meetingID = Bbb.project_to_meetingID(@project)
      bbb = Bbb.new(meetingID)
      context[:controller].send(:render_to_string, {
        :partial => "hooks/view_projects_show_sidebar_bottom",
        :locals => {:project => @project, :bbb => bbb}
      })
    end
  end
end
