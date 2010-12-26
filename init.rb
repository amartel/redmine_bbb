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
  version '0.1.1'

  settings :default => {'bbb_server' => ''}, :partial => 'settings-bbb/settings'
  settings :default => {'bbb_salt' => ''}, :partial => 'settings-bbb/settings'
  
  project_module :bigbluebutton do
    permission :bigbluebutton_join, :bigbluebutton => :start
    permission :bigbluebutton_start, {}
    permission :bigbluebutton_moderator, {}
  end

end