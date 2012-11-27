#WebDav plugin for REDMINE
require 'redmine'
Dir::foreach(File.join(File.dirname(__FILE__), 'lib')) do |file|
  next unless /\.rb$/ =~ file
  require file
end

require_dependency 'redmine_bbb/hooks'

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