# frozen_string_literal: true

require "test_helper"

class Api::V1::QuestionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create(:organization)
    @category = create(:category, organization: @organization)
    @quiz = create(:quiz, category: @category, name: "sample quiz", organization: @organization)
    create_questions_with_options(@quiz)
  end

  def create_questions_with_options(quiz)
    @question1 = create(:question, quiz: quiz)
    @question2 = create(:question, quiz: quiz)
  end

  # def test_should_return_all_questions_with_options_without_is_correct
  #   get api_v1_quiz_questions_path(@quiz.slug), as: :json

  #   assert_response :success
  #   body = response.parsed_body

  #   assert_equal 2, body["questions"].size
  # end
end
