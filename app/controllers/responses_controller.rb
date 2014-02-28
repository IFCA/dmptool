class ResponsesController < ApplicationController
	before_action :set_response, only: [:show, :edit, :update, :destroy]

  # GET /responses
  # GET /responses.json
 def index
 	  @responses = Response.all
  end

  def new
  	@response = Response.new
  end

  def edit
  end

  def show
  end

  def create
  	@response = Response.new(response_params)
    @requirement_id = response_params[:requirement_id]
    @next_requirement_id = params[:next_requirement_id]
    respond_to do |format|
      if params[:save_and_next] || !params[:save_only]
        if @response.save
          plan_id = @response.plan_id
          @plan = Plan.find(plan_id)
          format.html { redirect_to details_plan_path(@plan, requirement_id: @next_requirement_id), notice: 'Response was successfully created.' }
          format.json { render action: 'show', status: :created, location: @response }
        else
          format.html { render 'new', notice: 'Problem in creating the Response.' }
          format.json { render json: @response.errors, status: :unprocessable_entity }
        end
      else
        if @response.save
          plan_id = @response.plan_id
          @plan = Plan.find(plan_id)
          format.html { redirect_to details_plan_path(@plan, requirement_id: @requirement_id), notice: 'Response was successfully created.' }
          format.json { render action: 'show', status: :created, location: @response }
        else
          format.html { render 'new', notice: 'Problem in creating the Response.' }
          format.json { render json: @response.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /responses/1
  # PATCH/PUT /responses/1.json
  def update
    respond_to do |format|
      @requirement_id = response_params[:requirement_id]
      @next_requirement_id = params[:next_requirement_id]
      if params[:save_and_next] || !params[:save_only]
        if @response.update(response_params)
        	@plan = @response.plan_id
          format.html { redirect_to details_plan_path(@plan, requirement_id: @next_requirement_id), notice: 'response was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { redirect_to details_plan_path(@plan), notice: 'There is an error in updating your response.' }
          format.json { render json: @response.errors, status: :unprocessable_entity }
        end
      else
        if @response.update(response_params)
          @plan = @response.plan_id
          format.html { redirect_to details_plan_path(@plan, requirement_id: @requirement_id), notice: 'response was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { redirect_to details_plan_path(@plan), notice: 'There is an error in updating your response.' }
          format.json { render json: @response.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /responses/1
  # DELETE /responses/1.json
  def destroy
    plan_id = @response.plan_id
    @response.destroy
    respond_to do |format|
      format.html { redirect_to details_plan_path(plan_id) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_response
      @response = Response.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def response_params
      params.require(:response).permit(:value, :plan_id, :requirement_id, :label_id)
    end
end

