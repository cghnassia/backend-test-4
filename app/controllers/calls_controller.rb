class CallsController < ApplicationController
  def index
    @calls = Call.all
  end

  def show
    @call = Call.find_by(id: params[:id])
  end
end
