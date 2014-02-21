class FactFieldsController < ApplicationController
  before_filter :authenticate
  before_filter :is_admin?, :only => [:edit, :destroy, :new, :create]
  
  # GET /fact_fields
  # GET /fact_fields.json
  def index
    @fact_fields = FactField.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @fact_fields }
    end
  end

  # GET /fact_fields/1
  # GET /fact_fields/1.json
  def show
    @fact_field = FactField.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @fact_field }
    end
  end

  # GET /fact_fields/new
  # GET /fact_fields/new.json
  def new
    @fact_field = FactField.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @fact_field }
    end
  end

  # GET /fact_fields/1/edit
  def edit
    @fact_field = FactField.find(params[:id])
  end

  # POST /fact_fields
  # POST /fact_fields.json
  def create
    @fact_field = FactField.new(params[:fact_field])

    respond_to do |format|
      if @fact_field.save
        format.html { redirect_to @fact_field, notice: 'Fact field was successfully created.' }
        format.json { render json: @fact_field, status: :created, location: @fact_field }
      else
        format.html { render action: "new" }
        format.json { render json: @fact_field.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /fact_fields/1
  # PUT /fact_fields/1.json
  def update
    @fact_field = FactField.find(params[:id])

    respond_to do |format|
      if @fact_field.update_attributes(params[:fact_field])
        format.html { redirect_to @fact_field, notice: 'Fact field was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @fact_field.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fact_fields/1
  # DELETE /fact_fields/1.json
  def destroy
    @fact_field = FactField.find(params[:id])
    @fact_field.destroy

    respond_to do |format|
      format.html { redirect_to fact_fields_url }
      format.json { head :no_content }
    end
  end
end
