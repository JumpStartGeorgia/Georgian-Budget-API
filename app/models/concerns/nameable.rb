module Nameable
  extend ActiveSupport::Concern

  included do
    has_many :names, -> { order 'names.start_date' }, as: :nameable, dependent: :destroy
  end

  module ClassMethods
    def with_name_in_history(name)
      joins(names: :translations)
      .where('name_translations.text = ?', name)
    end

    def with_most_recent_names
      most_recent_name_entries =
      Name.select('id')
      .where(is_most_recent: true)

      includes(names: :translations)
      .where(names: { id: most_recent_name_entries })
    end
  end

  # text of most recent name
  def name
    return nil unless recent_name_object.present?

    text = recent_name_object.text
    return text if text.present?

    translations = recent_name_object.translations

    return nil unless translations.present?
    return translations[0].text
  end

  def name_ka
    return nil if recent_name_object.blank?
    recent_name_object.text_ka
  end

  def name_en
    return nil if recent_name_object.blank?
    recent_name_object.text_en
  end

  def name_on_date(date)
    names.where('start_date <= ?', date).last
  end

  def add_name(name_attributes, args = {})
    transaction do
      name_attributes[:nameable] = self
      new_name = Name.create!(name_attributes)

      update_with_new_name(new_name)

      args[:return_name] ? new_name : self
    end
  end

  def take_name(new_name, args = {})
    transaction do
      new_name.update_attributes!(nameable: self)

      update_with_new_name(new_name)

      args[:return_name] ? new_name : self
    end
  end

  # most recent name
  def recent_name_object
    names.last
  end

  private

  def update_with_new_name(new_name)
    merge_new_name(new_name)
    update_names_is_most_recent
    DatesUpdater.new(self, new_name).update
  end

  def update_names_is_most_recent
    names.reload
    names.update_all(is_most_recent: false)
    recent_name_object.update_column(:is_most_recent, true)

    return true
  end

  def merge_new_name(new_name)
    names.reload
    return if names.length == 1

    new_name_index = names.to_a.index do |sibling|
      sibling.id == new_name.id
    end

    more_recent_sibling = names[new_name_index + 1]

    if more_recent_sibling.present? && more_recent_sibling.text == new_name.text
      merge_name_siblings(new_name, more_recent_sibling)
    end

    earlier_sibling = names[new_name_index - 1]

    if new_name_index > 0 && earlier_sibling.text == new_name.text
      merge_name_siblings(new_name, earlier_sibling)
    end
  end

  def merge_name_siblings(name1, name2)
    if name1.start_date < name2.start_date
      name2.destroy
    else
      name1.destroy
    end
  end
end
