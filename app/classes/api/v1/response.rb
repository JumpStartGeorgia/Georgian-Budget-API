class API::V1::Response
  def initialize(params)
    @errors = []
    @params = params

    filters = params['filters']

    if filters.present?
      @budget_item_type = filters['budget_item_type'] if filters['budget_item_type'].present?
      @time_period_type = validate_time_period_type(filters['time_period_type']) if filters['time_period_type'].present?
    end

    @budget_item_fields = validate_budget_item_fields(params['budget_item_fields']) if params['budget_item_fields'].present?
    @budget_item_ids = params['budget_item_ids'] if params['budget_item_ids'].present?
  end

  def to_hash
    response = {}
    response[:errors] = errors

    response[:budget_items] = budget_items if budget_items
    return response
  rescue API::V1::InvalidQueryError => e
    add_error("Failed to process the request: #{e.message}")
    response[:budget_items] = []
    return response
  end

  def add_error(text)
    self.errors = errors.push({
      text: text
    })
  end

  private

  attr_accessor :errors

  attr_reader :budget_item_ids,
              :time_period_type,
              :budget_item_fields,
              :budget_item_type,
              :params

  def budget_items
    @budget_items ||= get_budget_items
  end

  def get_budget_items
    unless budget_item_fields.present?
      raise API::V1::InvalidQueryError, 'budgetItemFields must be supplied in query'
    end

    if budget_item_ids.present?
      budget_items = budget_item_ids.map do |perma_id|
        item = BudgetItem.find_by_perma_id(perma_id)
        unless item.present?
          raise API::V1::InvalidQueryError, "budget item with id #{perma_id} does not exist"
        end

        item
      end
    elsif budget_item_type.present?
      budget_items = budget_type_class.all.with_most_recent_names
    else
      raise API::V1::InvalidQueryError, 'budgetItemIds or budgetItemType filter must be supplied in query'
    end

    return budget_items.map do |budget_item|
      budget_item_hash(budget_item)
    end
  end

  def budget_item_hash(budget_item)
    API::V1::BudgetItemHash.new(
      budget_item,
      fields: budget_item_fields,
      time_period_type: time_period_type
    ).to_hash
  end

  def validate_time_period_type(time_period_type)
    return nil unless time_period_type.present? && time_period_type.is_a?(String)

    unless time_period_type_permitted_fields.include? time_period_type
      raise API::V1::InvalidQueryError, "Time period type \"#{time_period_type}\" not permitted. Allowed values: #{time_period_type_permitted_fields.join(',')}"
    end

    time_period_type
  end

  def time_period_type_permitted_fields
    [
      'year',
      'quarter',
      'month'
    ]
  end

  def validate_budget_item_fields(fields)
    return nil unless fields.present? && fields.is_a?(String)
    fields.split(',').select do |field|
      valid = budget_item_permitted_fields.include? field
      unless valid
        raise API::V1::InvalidQueryError, "Budget item field \"#{field}\" not permitted. Allowed values: #{budget_item_permitted_fields.join(',')}"
      end
      valid
    end
  end

  def budget_item_permitted_fields
    [
      'id',
      'code',
      'type',
      'name',
      'spent_finances',
      'planned_finances'
    ]
  end

  def budget_type_class
    camelized = budget_item_type.camelize

    unless allowed_budget_item_types.include? camelized
      raise API::V1::InvalidQueryError, "Budget item type #{budget_item_type} is not available"
    end

    Object.const_get(camelized)
  end

  def allowed_budget_item_types
    ['Program', 'SpendingAgency', 'Priority', 'Total']
  end
end
