require 'digest/sha1'

class BbbController < ApplicationController
  before_filter :find_project, :authorize, :find_user

  def start
    # Check if key is correct
    salt = Bbb.salt
    id = params[:id]
    key = params[:key]
    if id and key and (Digest::SHA1.hexdigest(id + @project.identifier + salt)[-16,16] == key) then
        meetingID = id
        meeting_name = CGI.escape("Room number " + meetingID)
    else
        # Generate meetingID based on project id starting from 00000
        meetingID = Bbb.project_to_meetingID(@project)
        meeting_name = CGI.escape(@project.name)
    end

    bbb = Bbb.new(meetingID)
    bbb.getinfo

    ok_to_join = false
    if bbb.running
      ok_to_join = true
    else
      if @user.allowed_to?(:bigbluebutton_start, @project)
        bbb.create(meeting_name, request.referer.to_s)
        ok_to_join = true
      end
    end

    if ok_to_join
      password = @user.allowed_to?(:bigbluebutton_moderator, @project) ? bbb.moderatorPW : bbb.attendeePW
      fullName = CGI.escape(User.current.name)
      redirect_to bbb.join(password, fullName)
    else
      redirect_to bbb.back_url
    end
  end

  def new_room
    salt = Bbb.salt
    # Choose random meetingID, range 10000:99999 
    @id = (rand(90000) + 10000).to_s
    @key = Digest::SHA1.hexdigest(@id + @project.identifier + salt)[-16,16]
    render :action => 'new_room'
  end

  private

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
end
