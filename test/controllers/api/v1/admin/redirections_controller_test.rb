# frozen_string_literal: true

require "test_helper"

class Api::V1::Admin::RedirectionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create(:organization)
    @admin = create(:user, role: :admin_user, organization: @organization)
    @standard_user = create(:user, role: :standard_user, organization: @organization)
    @admin_headers = headers(@admin)
    @standard_user_headers = headers(@standard_user)
    @redirection = create(:redirection, organization: @organization, from: "/old", to: "/new")
  end

  # def test_should_create_redirection_with_valid_params
  #   assert_difference("Redirection.count", 1) do
  #     post api_v1_admin_redirections_url,
  #       params: { redirection: { from: "/old-path", to: "/new-path" } },
  #       headers: @admin_headers,
  #       as: :json
  #   end
  #   assert_response :success

  #   redirection = Redirection.last
  #   assert_equal "/old-path", redirection.from
  #   assert_equal "/new-path", redirection.to
  # end

  def test_should_not_create_redirection_with_duplicate_from_for_same_organization
    create(:redirection, from: "/duplicate-path", to: "/new-path", organization: @organization)

    assert_no_difference("Redirection.count") do
      post api_v1_admin_redirections_url,
        params: { redirection: { from: "/duplicate-path", to: "/another-path" } },
        headers: @admin_headers,
        as: :json
    end
    assert_response :unprocessable_entity

    response_json = response.parsed_body
    assert_includes response_json["error"], "has already been taken"
  end

  def test_should_update_redirection
    patch api_v1_admin_redirection_path(@redirection),
      params: { redirection: { from: "/updated", to: "/new-path" } },
      headers: @admin_headers,
      as: :json

    assert_response :success
    @redirection.reload
    assert_equal "/updated", @redirection.from
    assert_equal "/new-path", @redirection.to
  end

  def test_should_destroy_redirection
    assert_difference("Redirection.count", -1) do
      delete api_v1_admin_redirection_path(@redirection), headers: @admin_headers, as: :json
    end

    assert_response :success
  end

  def test_should_list_redirections
    redirection2 = create(:redirection, organization: @organization, from: "/another-old", to: "/another-new")

    get api_v1_admin_redirections_url, headers: @admin_headers, as: :json

    assert_response :success

    response_json = response.parsed_body
    returned_paths = response_json.map { |r| r["from"] }

    assert_includes returned_paths, @redirection.from
    assert_includes returned_paths, redirection2.from
  end
end
