class Tag < ActiveRecord::Base
  
  attr_accessible :name
  
  ### ASSOCIATIONS:
  
  has_many :taggings, :dependent => :destroy
  
  ### VALIDATIONS:
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  ### NAMED SCOPES:
  
  named_scope :named, lambda { |name| { :conditions => ["name = ?", name] } }
  named_scope :named_like, lambda { |name| { :conditions => ["name LIKE ?", "%#{name}%"] } }
  named_scope :named_like_any, lambda { |list| { :conditions => list.map { |tag| sanitize_sql(["name LIKE ?", tag.to_s]) }.join(" OR ") } }
  
  ### METHODS:
  
  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(name)
    find(:first, :conditions => ["name LIKE ?", name]) || create(:name => name)
  end
  
  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def to_s
    name
  end
  
  def count
    read_attribute(:count).to_i
  end
end
