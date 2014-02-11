class DimensionFieldsController < ApplicationController
  before_filter :authenticate
  before_filter :is_admin, :only => [:edit, :destroy, :new, :create]
  
  # GET /dimension_fields
  # GET /dimension_fields.json
  def index
    @dimension_fields = DimensionField.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @dimension_fields }
    end
  end

  # GET /dimension_fields/1
  # GET /dimension_fields/1.json
  def show
    @dimension_field = DimensionField.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @dimension_field }
    end
  end

  # GET /dimension_fields/new
  # GET /dimension_fields/new.json
  def new
    @dimension_field = DimensionField.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @dimension_field }
    end
  end

  # GET /dimension_fields/1/edit
  def edit
    @dimension_field = DimensionField.find(params[:id])
  end

  # POST /dimension_fields
  # POST /dimension_fields.json
  def create
    @dimension_field = DimensionField.new(params[:dimension_field])

    respond_to do |format|
      if @dimension_field.save
        format.html { redirect_to @dimension_field, notice: 'Dimension field was successfully created.' }
        format.json { render json: @dimension_field, status: :created, location: @dimension_field }
      else
        format.html { render action: "new" }
        format.json { render json: @dimension_field.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /dimension_fields/1
  # PUT /dimension_fields/1.json
  def update
    @dimension_field = DimensionField.find(params[:id])

    respond_to do |format|
      if @dimension_field.update_attributes(params[:dimension_field])
        format.html { redirect_to @dimension_field, notice: 'Dimension field was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @dimension_field.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dimension_fields/1
  # DELETE /dimension_fields/1.json
  def destroy
    @dimension_field = DimensionField.find(params[:id])
    @dimension_field.destroy

    respond_to do |format|
      format.html { redirect_to dimension_fields_url }
      format.json { head :no_content }
    end
  end
end
