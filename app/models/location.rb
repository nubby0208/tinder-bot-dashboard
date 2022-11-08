class Location < ApplicationRecord
  include ActionView::Helpers
  belongs_to :user
  has_many :tinder_accounts, dependent: :nullify
  # rails_admin do
  #   list do
  #     sort_by :population
  #   end
  # end

  def custom_label_method
    "#{name} #{number_with_delimiter(population,delimiter: ",") }"
  end
end
