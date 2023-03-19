# frozen_string_literal: true

class ConvertController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index; end

  def create
    options = {
      use_arel_helpers: convert_params.fetch(:use_arel_helpers, 'false') == 'true',
      use_arel_nodes_prefix: convert_params.fetch(:use_arel_nodes_prefix, 'true') == 'true'
    }

    if rails_version = convert_params[:use_rails_version]
      options[:use_rails_version] = rails_version
    end

    manager = AssociationCache.create_manager([])
    raw_arel = Scuttle.convert(convert_params.fetch(:sql, ""), options, manager)
    arel = Scuttle.colorize(Scuttle.beautify(raw_arel), :div)

    respond_to do |format|
      format.json { render json: { result: "succeeded", arel: arel } }
    end
  rescue Scuttle::ScuttleConversionError => e
    respond_to do |format|
      format.json { render json: { result: "failed", arel: nil, message: e.message } }
    end
  end

  private

  def convert_params
    params.require(:conversion).permit(:sql, :use_arel_helpers, :use_arel_nodes_prefix, :use_rails_version)
  end
end
