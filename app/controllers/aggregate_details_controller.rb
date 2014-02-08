class AggregateDetailsController < ApplicationController
  before_filter :authenticate
  
  # GET /aggregate_details
  # GET /aggregate_details.json
  def index
    @aggregate_details = AggregateDetail.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @aggregate_details }
    end
  end

  # GET /aggregate_details/1
  # GET /aggregate_details/1.json
  def show
    @aggregate_detail = AggregateDetail.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @aggregate_detail }
    end
  end

  # GET /aggregate_details/new
  # GET /aggregate_details/new.json
  def new
    @aggregate_detail = AggregateDetail.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @aggregate_detail }
    end
  end

  # GET /aggregate_details/1/edit
  def edit
    @aggregate_detail = AggregateDetail.find(params[:id])
  end

  # POST /aggregate_details
  # POST /aggregate_details.json
  def create
    @aggregate_detail = AggregateDetail.new(params[:aggregate_detail])

    respond_to do |format|
      if @aggregate_detail.save
        format.html { redirect_to @aggregate_detail, notice: 'Aggregate detail was successfully created.' }
        format.json { render json: @aggregate_detail, status: :created, location: @aggregate_detail }
      else
        format.html { render action: "new" }
        format.json { render json: @aggregate_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /aggregate_details/1
  # PUT /aggregate_details/1.json
  def update
    @aggregate_detail = AggregateDetail.find(params[:id])

    respond_to do |format|
      if @aggregate_detail.update_attributes(params[:aggregate_detail])
        format.html { redirect_to @aggregate_detail, notice: 'Aggregate detail was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @aggregate_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /aggregate_details/1
  # DELETE /aggregate_details/1.json
  def destroy
    @aggregate_detail = AggregateDetail.find(params[:id])
    @aggregate_detail.destroy

    respond_to do |format|
      format.html { redirect_to aggregate_details_url }
      format.json { head :no_content }
    end
  end
end
