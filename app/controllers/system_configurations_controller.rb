class SystemConfigurationsController < ApplicationController
  before_filter :authenticate
  before_filter :is_admin
  
  # GET /system_configurations
  # GET /system_configurations.json
  def index
    @system_configurations = SystemConfiguration.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @system_configurations }
    end
  end

  # GET /system_configurations/1
  # GET /system_configurations/1.json
  def show
    @system_configuration = SystemConfiguration.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @system_configuration }
    end
  end

  # GET /system_configurations/new
  # GET /system_configurations/new.json
  def new
    @system_configuration = SystemConfiguration.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @system_configuration }
    end
  end

  # GET /system_configurations/1/edit
  def edit
    @system_configuration = SystemConfiguration.find(params[:id])
  end

  # POST /system_configurations
  # POST /system_configurations.json
  def create
    @system_configuration = SystemConfiguration.new(params[:system_configuration])

    respond_to do |format|
      if @system_configuration.save
        format.html { redirect_to @system_configuration, notice: 'System configuration was successfully created.' }
        format.json { render json: @system_configuration, status: :created, location: @system_configuration }
      else
        format.html { render action: "new" }
        format.json { render json: @system_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /system_configurations/1
  # PUT /system_configurations/1.json
  def update
    @system_configuration = SystemConfiguration.find(params[:id])

    respond_to do |format|
      if @system_configuration.update_attributes(params[:system_configuration])
        format.html { redirect_to @system_configuration, notice: 'System configuration was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @system_configuration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_configurations/1
  # DELETE /system_configurations/1.json
  def destroy
    @system_configuration = SystemConfiguration.find(params[:id])
    @system_configuration.destroy

    respond_to do |format|
      format.html { redirect_to system_configurations_url }
      format.json { head :no_content }
    end
  end
end
