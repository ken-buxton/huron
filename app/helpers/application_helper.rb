module ApplicationHelper
  def get_pg_conn_hash
    {:host => "localhost", :port => 5434, :dbname => "huron", :user => "huron", :password => "huron"}
  end
end
