class WorkoutsController < ApplicationController
  # index route
  def index
    render json: Workout.all
  end

  #show route
  def show
    render json: Workout.find(params["id"])
  end

  # create route
  def create
    render json: Workout.create(params["workout"])
  end

  # delete route
  def delete
    render json: Workout.delete(params["id"])
  end

  # update route
  def update
    render json: Workout.update(params["id"], params["workout"])
  end
end
