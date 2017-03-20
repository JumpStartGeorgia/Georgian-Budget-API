module Api
  module V1
    class LastUpdatedDateController < ApplicationController
      def index
        last_updated_date = Date.strptime(SpentFinance.maximum(:created_at).to_s)

        if (last_updated_date)
          render json: { last_updated_date: last_updated_date }, status: 200
        end
      end
    end
  end
end
