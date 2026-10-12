# frozen_string_literal: true

class Api::V1::Admin::ReportsController < ApplicationController
  before_action :load_quiz!

  def create
    authorize [:admin, @quiz], :download?
    SubmissionsReportJob.perform_async(@quiz.id, @current_user.id)
  end

  def show
    authorize [:admin, @quiz]
    if @quiz.report.attached?
      send_data @quiz.report.download, filename: pdf_file_name, type: "application/pdf", disposition: "attachment"
    else
      render_error(t("not_found", entity: "report"), :not_found) and return
    end
  end

  private

    def load_quiz!
      @quiz = Quiz.find(params[:quiz_id])
    end

    def pdf_file_name
      "report.pdf"
    end
end
