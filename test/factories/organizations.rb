FactoryBot.define do
  factory :organization do
    association :team
    name { "MyString" }
  end
end
