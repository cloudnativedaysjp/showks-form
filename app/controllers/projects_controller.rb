class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :destroy]

  def index
    @projects = Project.all
  end

  def show
    # TODO: Implement show API
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new

    respond_to do |format|
      if @project.save(project_params)
        format.html { redirect_to project_url(@project), notice: 'Project was successfully created.' }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project.destroy
    sleep(0.2)
    respond_to do |format|
      format.html { redirect_to "/projects/admin/list", notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # def create_demoaccount
  #   10.times do |i|
  #     project = Project.new()
  #     project.username = "demoaccount-#{i}"
  #     project.github_id = "demoaccount-#{i}"
  #     project.twitter_id = "demoaccount"
  #     project.comment = "generated"
  #     project.save
  #   end
  #
  #
  #   respond_to do |format|
  #     format.html { redirect_to projects_url, notice: 'Project was successfully created.' }
  #   end
  # end
  #
  # def destroy_demoaccount
  #   10.times do |i|
  #     project = Project.find_by_username("demoaccount-#{i}")
  #     project.destroy
  #   end
  #   respond_to do |format|
  #     format.html { redirect_to projects_url, notice: 'Project was successfully destroyed.' }
  #   end
  # end

  private
    def set_project
      # TODO: Implement project search
      @project = Project.find(params[:id])
    end

    def project_params
      params.require(:project).permit(:id, :password, :username, :github_id, :twitter_id, :comment).to_h
    end
end
