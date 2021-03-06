module Codeable
  extend ActiveSupport::Concern

  included do
    has_many :codes, -> { order :start_date }, as: :codeable, dependent: :destroy
  end

  module ClassMethods
    def with_code_in_history(code_number)
      joins(:codes).where(codes: { number: code_number })
    end
  end

  def add_code(code_attributes, args = {})
    transaction do
      code_attributes[:codeable] = self
      new_code = Code.create!(code_attributes)

      update_with_new_code(new_code)

      args[:return_code] ? new_code : self
    end
  end

  def take_code(new_code, args = {})
    transaction do
      new_code.update_attributes!(codeable: self)

      update_with_new_code(new_code)

      args[:return_code] ? new_code : self
    end
  end

  def code_on_date(date)
    codes.where('start_date <= ?', date).last
  end

  private

  def update_with_new_code(new_code)
    DatesUpdater.new(self, new_code).update
    new_code = merge_new_code(new_code)

    unless code == codes.last.number
      update_column(:code, codes.last.number)
      ProgramAncestorsUpdater.new(self).update if self.is_a?(Program)
    end
  end

  def merge_new_code(new_code)
    codes.reload
    return if codes.length == 1

    new_code_index = codes.to_a.index do |sibling|
      sibling.id == new_code.id
    end

    more_recent_sibling = codes[new_code_index + 1]

    if more_recent_sibling.present? && more_recent_sibling.number == new_code.number
      new_code = merge_code_siblings(new_code, more_recent_sibling)
    end

    earlier_sibling = codes[new_code_index - 1]

    if new_code_index > 0 && earlier_sibling.number == new_code.number
      new_code = merge_code_siblings(new_code, earlier_sibling)
    end

    new_code
  end

  def merge_code_siblings(code1, code2)
    if code1.start_date <= code2.start_date
      code2.destroy
      return code1
    else
      code1.destroy
      return code2
    end
  end
end
