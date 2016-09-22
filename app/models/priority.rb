class Priority < ApplicationRecord
  include Codeable
  include Nameable
  include FinanceSpendable
  include FinancePlannable
end
