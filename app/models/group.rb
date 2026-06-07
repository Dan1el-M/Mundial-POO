class Group < ApplicationRecord
  LETTERS = ("A".."L").to_a.freeze

  has_many :teams, -> { order(:name) }, dependent: :restrict_with_error, inverse_of: :group
  has_many :matches, -> { where(type: nil).order(:id) }, dependent: :restrict_with_error, inverse_of: :group

  validates :letter, presence: true, inclusion: { in: LETTERS }, uniqueness: true

  scope :ordered, -> { order(:letter) }

  def standings
    GroupStandingService.new(self).call
  end
end
