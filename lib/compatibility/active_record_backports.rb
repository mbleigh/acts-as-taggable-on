module ActsAsTaggableOn
  module ActiveRecord
    module Backports
      def self.included(base)
        base.class_eval do
          named_scope :where,    lambda { |conditions| { :conditions => conditions } }  
          named_scope :joins,    lambda { |joins|      { :joins => joins } }
          named_scope :group,    lambda { |group|      { :group => group } }
          named_scope :order,    lambda { |order|      { :order => order } }
          named_scope :select,   lambda { |select|     { :select => select } }
          named_scope :limit,    lambda { |limit|      { :limit => limit } }
          named_scope :readonly, lambda { |readonly|   { :readonly => readonly } }
          
          def self.to_sql
            construct_finder_sql({})
          end
        end
      end
    end
  end
end