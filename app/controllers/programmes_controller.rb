# frozen_string_literal: true

class ProgrammesController < ApplicationController
  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes = programmes
  end

  def show
  end

  def sessions
    @scheduled_sessions = @programme.sessions.scheduled
    @completed_sessions = @programme.sessions.completed
  end

  private

  def programmes
    @programmes ||= policy_scope(Programme)
  end

  def set_programme
    @programme = programmes.find(params[:id])
  end
end
