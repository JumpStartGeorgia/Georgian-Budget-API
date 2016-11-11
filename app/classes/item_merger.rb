class ItemMerger
  def initialize(receiver)
    @receiver = receiver
  end

  def merge(giver)
    unless receiver.class == giver.class
      raise "Merging #{giver.class} into #{receiver.class} is not allowed; types must be the same"
    end

    merge_priority(giver.priority)
    merge_codes(giver.codes)
    merge_names(giver.names)
    merge_spent_finances(giver.spent_finances)
    merge_planned_finances(giver.planned_finances)

    giver.reload.destroy
  end

  private

  attr_reader :receiver

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
    new_codes.each do |new_code|
      receiver.take_code(new_code)
    end
  end

  def merge_names(new_names)
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

    new_planned_finances.each do |new_planned_finance|
      receiver.take_planned_finance(new_planned_finance)
    end
  end
end
