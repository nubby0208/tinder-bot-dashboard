class GoogleAccount < ApplicationRecord
  validates :password, :username, :phone_number_id, presence: true
  belongs_to :owner
  belongs_to :phone_number

  validates :phone_number, uniqueness: true
  validates :username, uniqueness: true
    # { scope: :year,
    # message: "should happen once per year" }

  def name
    username
  end
end
