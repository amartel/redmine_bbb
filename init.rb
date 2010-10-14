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
  version '0.1.0'

  settings :default => {'bbb_server' => ''}, :partial => 'settings/settings'
  settings :default => {'bbb_salt' => ''}, :partial => 'settings/settings'
  
  project_module :bigbluebutton do
    permission :bigbluebutton_access, :bigbluebutton => :start, :public => true
  end

end