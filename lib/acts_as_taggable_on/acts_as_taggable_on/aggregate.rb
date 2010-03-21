module ActsAsTaggableOn::Taggable
  module Aggregate
    def self.included(base)
      include InstanceMethods
      base.extend ClassMethods
    end
    
    module ClassMethods
    end
    
    module InstanceMethods
    end
  end
end