class TaggableModelWithUuidPrimaryKey < ActiveRecord::Base
  self.primary_key = 'id'
  acts_as_taggable
  acts_as_taggable_on :languages
  acts_as_taggable_on :skills
  acts_as_taggable_on :needs, :offerings
  has_many :untaggable_models

  before_create :assign_uuid

  private

  def assign_uuid
    self.id = SecureRandom.uuid
  end
end
