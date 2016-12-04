class SpentFinance < ApplicationRecord
  include TimePeriodable

  belongs_to :finance_spendable, polymorphic: true

  validates :finance_spendable, presence: true
  validates :end_date,
            uniqueness: {
              scope: [
                :finance_spendable_type,
                :finance_spendable_id,
                :start_date,
                :official
              ]
            }
  validates :primary, inclusion: { in: [true, false] }
  validates :official, inclusion: { in: [true, false] }

  before_validation :set_primary_default

  def parent
    finance_spendable
  end

  def parent=(new_parent)
    self.finance_spendable = new_parent
  end

  def self.before(date)
    where('end_date <= ?', date)
  end

  def self.after(date)
    where('start_date >= ?', date)
  end

  def self.total
    calculate(:sum, :amount)
  end

  def self.official
    where(official: true)
  end

  def self.unofficial
    where(official: false)
  end

  def self.prefer_official
    ids = self.find_by_sql(
      <<-STRING
        SELECT DISTINCT ON (finance_spendable_type,
                            finance_spendable_id,
                            start_date,
                            end_date)
                            id
        FROM spent_finances
        ORDER BY finance_spendable_type,
                 finance_spendable_id,
                 start_date,
                 end_date,
                 official DESC
      STRING
    )

    where(id: ids)
  end

  def amount_pretty
    ActionController::Base.helpers.number_with_delimiter(amount, delimiter: ',')
  end

  private

  def set_primary_default
    self.primary = false if primary.nil?
  end
end
