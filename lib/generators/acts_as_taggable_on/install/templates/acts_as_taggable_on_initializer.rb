ActsAsTaggableOn.setup do |config|
  # The delimiter can be set as a single string or an array or strings.
  # If an array is set, any of the strings in the array can be used to separate
  # tags, but the first item in the array will be used as the default when
  # displaying tag lists. The default is ','.
  # config.delimiter = [',', ';']

  # Setting +force_lowercase+ to true will downcase tag names when saved.
  # Default is false.
  # config.force_lowercase = true

  # Set to true if you would like to remove unused tag objects after removing
  # taggings. Default is false.
  # config.remove_unused_tags = true

  # Set to true to parameterize tags before saving them. Default is false.
  # config.force_parameterize = true

  # Set to true if tags should be case-sensitive, i.e. they will not use LIKE
  # queries for creation. Default is false.
  # config.strict_case_match = true
end
