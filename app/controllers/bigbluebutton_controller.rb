require 'digest/sha1'
#require 'net/http'
require 'open-uri'

class BigbluebuttonController < ApplicationController

  before_filter :find_project, :authorize, :find_user

  def start
    server = Setting.plugin_redmine_bbb['bbb_server']
      back_url = Setting.plugin_redmine_bbb['bbb_url'].empty? ? request.referer : Setting.plugin_redmine_bbb['bbb_url']
#    RAILS_DEFAULT_LOGGER.info "referer: #{request.referer}"
    #First, test if meeting room already exists
#    data = callApi(server, "isMeetingRunning","RunningmeetingID=" + @project.identifier, true)
    data = callApi(server, "getMeetingInfo","meetingID=" + @project.identifier + "&password=" + Digest::SHA1.hexdigest("root"+@project.identifier), true)
    doc = ActiveSupport::XmlMini.parse(data)
    if !doc || !doc['response'] || !doc['response']['running']
      #If not, we created it...
      bridge = "0000" + @project.id.to_s
      bridge = bridge[-5,5]
#      data = callApi(server, "create","name=" + @project.name.sub(/ /, '+') + "&meetingID=" + @project.identifier + "&attendeePW=" + Digest::SHA1.hexdigest("guest"+@project.identifier) + "&moderatorPW=" + Digest::SHA1.hexdigest("root"+@project.identifier)+ "&logoutURL=" + request.referer + "&voiceBridge=" + bridge, true)
      data = callApi(server, "create","name=" + @project.name.sub(/ /, '+') + "&meetingID=" + @project.identifier + "&attendeePW=" + Digest::SHA1.hexdigest("guest"+@project.identifier) + "&moderatorPW=" + Digest::SHA1.hexdigest("root"+@project.identifier)+ "&logoutURL=" + back_url + "&voiceBridge=" + bridge, true)
    end
    #Now, join meeting...
    url = callApi(server, "join", "meetingID=" + @project.identifier + "&password="+ Digest::SHA1.hexdigest("root"+@project.identifier) + "&fullName=" + User.current.name.sub(/ /, '+'), false)
    redirect_to URI.escape(url)


  end
  
  private
  def callApi (server, api, arg, getcontent)
#    param = URI.escape(arg)
    param = arg
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

  def find_project
    # @project variable must be set before calling the authorize filter
    if params[:project_id]
       @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_user
    User.current = find_current_user
    @user = User.current
  end

  # Authorize the user for the requested action
  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    case action
    when "rootwebdav", "webdavnf"
      allowed = true
    else
      allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project, :global => global)
    end
    allowed ? true : deny_access
  end
    
end
