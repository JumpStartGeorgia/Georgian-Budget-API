module Api
  module V1
    class BudgetItemsController < ApplicationController
      def show
        budget_item = BudgetItem.find_by_perma_id(api_params[:id])

        if budget_item.present?
          budget_item_object = API::V1::BudgetItemHash.new(
            budget_item,
            fields: API::V1::BudgetItemFields.validate(api_params[:budget_item_fields]),
            time_period_type: api_params['time_period_type']
          ).to_hash

          render json: { errors: [], budget_item: budget_item_object },
                 status: 200
        end
      end

      def programs
        render json: API::V1::Response.new(Program, api_params).to_hash,
               status: 200
      end

      def spending_agencies
        render json: API::V1::Response.new(SpendingAgency, api_params).to_hash,
               status: 200
      end

      def priorities
        render json: API::V1::Response.new(Priority, api_params).to_hash,
               status: 200
      end

      private

      def api_params
        snake_case_params.permit(
          :id,
          :version,
          :locale,
          :budget_item_fields,
          :filters,
          filters: [
            :time_period_type
          ]
        )
      end

      def snake_case_params
        new_params = params.to_unsafe_h.deep_transform_keys!(&:underscore)

        if new_params[:filters].present? && new_params[:filters].is_a?(String)
          new_params[:filters] = JSON.parse(params[:filters].to_s).deep_transform_keys!(&:underscore)
        end

        ActionController::Parameters.new(new_params)
      end
    end
  end
end
