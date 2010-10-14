require 'digest/sha1'
#require 'net/http'
require 'open-uri'
require 'openssl'
require 'base64'

class BigbluebuttonController < ApplicationController

  before_filter :find_project, :authorize, :find_user

  def start
      back_url = Setting.plugin_redmine_bbb['bbb_url'].empty? ? request.referer : Setting.plugin_redmine_bbb['bbb_url']
    #First, test if meeting room already exists
    server = Setting.plugin_redmine_bbb['bbb_ip']
    moderatorPW=Digest::SHA1.hexdigest("root"+@project.identifier)
    data = callApi(server, "getMeetingInfo","meetingID=" + @project.identifier + "&password=" + moderatorPW, true)
    doc = ActiveSupport::XmlMini.parse(data)
    if !doc || !doc['response'] || !doc['response']['running']
      #If not, we created it...
      bridge = "77777" + @project.id.to_s
      bridge = bridge[-5,5]
      data = callApi(server, "create","name=" + CGI.escape(@project.name) + "&meetingID=" + @project.identifier + "&attendeePW=" + Digest::SHA1.hexdigest("guest"+@project.identifier) + "&moderatorPW=" + moderatorPW + "&logoutURL=" + back_url + "&voiceBridge=" + bridge, true)
    else
      moderatorPW = doc['response']['moderatorPW']['__content__']
    end
    #Now, join meeting...
    server = Setting.plugin_redmine_bbb['bbb_server']
    url = callApi(server, "join", "meetingID=" + @project.identifier + "&password="+ moderatorPW + "&fullName=" + CGI.escape(User.current.name), false)

    redirect_to url


  end
  
  private
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
