require 'spec_helper'

# Generators are not automatically loaded by Rails
require 'generators/acts_as_taggable_on/migration/migration_generator'

describe ActsAsTaggableOn::MigrationGenerator do
  # Tell the generator where to put its output (what it thinks of as Rails.root)
  destination File.expand_path("../../../../../tmp", __FILE__)

  before do
    prepare_destination
    Rails::Generators.options[:rails][:orm] = :active_record
  end
  describe 'no arguments' do
    before { run_generator  }

    describe 'db/migrate/acts_as_taggable_on_migration.rb' do
      subject { file('db/migrate/acts_as_taggable_on_migration.rb') }
      it { should be_a_migration }
    end
  end
end
