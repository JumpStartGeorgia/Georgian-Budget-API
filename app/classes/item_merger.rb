class ItemMerger
  def initialize(receiver)
    @receiver = receiver
  end

  def merge(giver)
    unless receiver.class == giver.class
      raise "Merging #{giver.class} into #{receiver.class} is not allowed; types must be the same"
    end

    if receiver_after_giver?(giver)
      raise "Cannot merge earlier item into later item; receiver must start before giver"
    end

    merge_priority(giver.priority) if receiver.respond_to?(:priority)
    merge_codes(giver.codes) if receiver.respond_to?(:take_code)
    merge_names(giver.names) if receiver.respond_to?(:take_name)
    merge_spent_finances(giver.spent_finances)
    merge_planned_finances(giver.all_planned_finances)

    if receiver.respond_to?(:save_possible_duplicates)
      merge_possible_duplicates(giver.possible_duplicates)
    end

    giver.reload.destroy
  end

  private

  attr_reader :receiver

  def receiver_after_giver?(giver)
    receiver.respond_to?(:start_date) &&
    giver.respond_to?(:start_date) &&
    receiver.start_date.present? &&
    giver.start_date.present? &&
    receiver.start_date > giver.start_date
  end

  def merge_priority(new_priority)
    return if new_priority.nil?

    if receiver.priority == nil
      receiver.priority = new_priority
      receiver.save!
    else
      raise 'Cannot merge object with different priority' if receiver.priority != new_priority
    end
  end

  def merge_codes(new_codes)
    return if new_codes.blank?

    new_codes.each do |new_code|
      receiver.take_code(new_code)
    end
  end

  def merge_names(new_names)
    return if new_names.blank?

    new_names.each do |new_name|
      receiver.take_name(new_name)
    end
  end

  def merge_spent_finances(new_spent_finances)
    return if new_spent_finances.blank?

    cumulative_within_year = [new_spent_finances.monthly.first]

    new_spent_finances.each do |new_spent_finance|
      calculate_cumulative = cumulative_within_year.include?(new_spent_finance)

      receiver.take_spent_finance(
        new_spent_finance,
        cumulative_within: calculate_cumulative ? Year : nil
      )
    end
  end

  def merge_planned_finances(new_planned_finances)
    return if new_planned_finances.blank?

    first_new_quarter_plan = new_planned_finances.quarterly.first

    cumulative_within_year = first_new_quarter_plan.blank? ? []
      : new_planned_finances.with_time_period(first_new_quarter_plan.time_period)

    new_planned_finances.each do |new_planned_finance|
      calculate_cumulative = cumulative_within_year.include?(new_planned_finance)

      receiver.take_planned_finance(
        new_planned_finance,
        cumulative_within: calculate_cumulative ? Year : nil
      )
    end
  end

  def merge_possible_duplicates(new_possible_duplicates)
    return if new_possible_duplicates.blank?

    receiver.save_possible_duplicates(new_possible_duplicates)
  end
end