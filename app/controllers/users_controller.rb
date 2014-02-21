class UsersController < ApplicationController
  before_filter :authenticate, :only => [:edit, :index, :destroy, :show]
  before_filter :is_admin?, :only => [:index, :destroy] # [:edit, :index, :destroy, :show]
  before_filter :no_edit_demo
  
  # GET /users
  # GET /users.json
  def index
    @user_role = user_role
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user_role = user_role
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user_role = user_role
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user_role = user_role
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user_role = user_role
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to :users, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user_role = user_role
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user_role = user_role
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to login_url }
      format.json { head :no_content }
    end
  end
  
  protected
  def no_edit_demo
    if not current_user.nil? then
      if current_user.login == "demo"
        flash[:error] = "Can't edit demo user profile."
        redirect_to main_index_path
        return false
      end
    end
    return true
  end
  
end
