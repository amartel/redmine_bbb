require 'redmine'
require_dependency 'bbb_hooks'
require_dependency 'bbb_macro'

Redmine::Plugin.register :redmine_bbb do
  name 'BigBlueButton plugin'
  author 'Arnaud Martel'
  description 'Interface with BigBlueButton server'
  version '0.2.1'

  settings :default => {'bbb_server' => '', 'bbb_salt' => ''}, :partial => 'settings/bbb_settings'

  project_module :bigbluebutton do
    permission :bigbluebutton_join, :bbb => :start
    permission :bigbluebutton_start, :bbb => :new_room
    permission :bigbluebutton_moderator, {}
  end
end
