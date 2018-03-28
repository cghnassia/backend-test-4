FactoryGirl.define do
  factory :call do
    phone_number Faker::PhoneNumber
    phone_country "FR"
  end
end
