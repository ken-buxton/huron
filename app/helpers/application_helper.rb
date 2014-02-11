module ApplicationHelper
  def get_pg_conn_hash
    {:host => "localhost", :port => 5434, :dbname => "huron", :user => "huron", :password => "huron"}
  end
  
  def user_role
    id = current_user.id
    @user = User.find(id)
    @user.role
  end
  
  def user_name
    id = current_user.id
    @user = User.find(id)
    @user.login
  end
  
  def is_admin_role
    id = current_user.id
    @user = User.find(id)
    if @user.role == "admin" then
      true
    else
      false
    end
  end
  
end
