class ApplicationController < ActionController::Base
  protect_from_forgery

  helper_method :current_user
  
  def log_event(log_text)
    Logs.create(log_when: Time.now, log_what: log_text)
  end
  
  protected
  def authenticate
    unless current_user
      flash[:error] = "You must be logged in to perform any actions."
      redirect_to new_user_session_path
      return false
    end
  end
  
  def is_admin?
    if current_user.nil? then
      return false;
    end
    id = current_user.id
    @user = User.find(id)
    @role = @user.role
    unless @user.role == 'admin'
      flash[:error] = "Can't perform action. You are not an admin."
      redirect_to main_index_path
      return false
    end
  end
  
  def user_role
    if current_user.nil? then
      return "user";
    end
    id = current_user.id
    @user = User.find(id)
    @role = @user.role
  end
  
  private
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end
end
