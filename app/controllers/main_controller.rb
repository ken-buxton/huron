class MainController < ApplicationController
  before_filter :authenticate
  
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  def help
    respond_to do |format|
      format.html # help.html.erb
    end
  end
end
