RSpec.configure do |config|

  config.before(:each, strict_case_match: true) do
    ActsAsTaggableOn.strict_case_match = true
  end

  config.after(:each, strict_case_match: true) do
    ActsAsTaggableOn.strict_case_match = false
  end

end
