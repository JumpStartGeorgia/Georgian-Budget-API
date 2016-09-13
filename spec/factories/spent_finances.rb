FactoryGirl.define do
  factory :spent_finance do
    sequence :amount do |n|
      n * 99
    end

    start_date Date.new(2015, 1, 1)
    end_date Date.new(2015, 1, 31)
    finance_spendable FactoryGirl.create(:program)
  end
end