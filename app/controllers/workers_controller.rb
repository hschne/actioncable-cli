class WorkersController < ApplicationController
  def start
    Worker.perform_async(params[:client_id])
    head(:ok)
  end
end
