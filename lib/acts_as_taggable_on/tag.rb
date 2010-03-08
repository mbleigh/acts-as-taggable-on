class Tag < ActiveRecord::Base
  
  attr_accessible :name
  
  ### ASSOCIATIONS:
  
  has_many :taggings, :dependent => :destroy
  
  ### VALIDATIONS:
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  ### NAMED SCOPES:
  
  named_scope :named, lambda { |name| { :conditions => ["name LIKE ?", name] } }
  named_scope :named_any, lambda { |list| { :conditions => list.map { |tag| sanitize_sql(["name LIKE ?", tag.to_s]) }.join(" OR ") } }
  named_scope :named_like, lambda { |name| { :conditions => ["name LIKE ?", "%#{name}%"] } }
  named_scope :named_like_any, lambda { |list| { :conditions => list.map { |tag| sanitize_sql(["name LIKE ?", "%#{tag.to_s}%"]) }.join(" OR ") } }
  
  ### CLASS METHODS:
  
  def self.find_or_create_with_like_by_name(name)
    named_like(name).first || create(:name => name)
  end
  
  def self.find_or_create_all_with_like_by_name(*list)
    list = [list].flatten
    
    return [] if list.empty?

    existing_tags = Tag.named_any(list).all
    new_tag_names = list.reject { |name| existing_tags.any? { |tag| tag.name.mb_chars.downcase == name.mb_chars.downcase } }
    created_tags  = new_tag_names.map { |name| Tag.create(:name => name) }
  
    existing_tags + created_tags    
  end
  
  ### INSTANCE METHODS:
  
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
