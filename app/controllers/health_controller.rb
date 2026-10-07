# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :authenticate_user_using_x_auth_token

  def index
    render json: { status: "ok" }
  end
end
