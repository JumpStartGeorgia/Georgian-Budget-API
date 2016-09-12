require 'rails_helper'
require Rails.root.join('spec', 'models', 'concerns', 'nameable_spec')

RSpec.describe SpendingAgency, type: :model do
  it_behaves_like 'nameable'
  it_behaves_like 'FinanceSpendable'
end
