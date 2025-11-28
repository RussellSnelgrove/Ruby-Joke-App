class Joke < ApplicationRecord
  validates :joke, presence: true

  scope :recent, -> { order(created_at: :desc).limit(10) }
end
