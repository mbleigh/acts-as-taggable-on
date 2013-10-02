module ActsAsTaggableOn
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)
      desc "Creates the ActsAsTaggableOn initializer for your application"

      def copy_initializer
        template "acts_as_taggable_on_initializer.rb", "config/initializers/acts_as_taggable_on.rb"

        puts 'Install completed. Configure ActsAsTaggableOn in config/initializers/acts_as_taggable_on.rb'
      end
    end
  end
end
