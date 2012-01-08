require "rails"

module ActsAsTaggableOn
  class Engine < Rails::Engine
    
    initializer 'ActsAsTaggableOn ActiveRecord' do |app|
      ActiveRecord::Base.extend ActsAsTaggableOn::Taggable
      ActiveRecord::Base.send :include, ActsAsTaggableOn::Tagger
    end
    
    initializer 'ActsAsTaggableOn AcrtionView' do |app|
      ActiveSupport.on_load(:action_view) do
        include ActsAsTaggableOn::TagsHelper
      end
    end
    
  end
end
