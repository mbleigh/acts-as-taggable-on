When upgrading

Re-run the migrations generator

    rake acts_as_taggable_on_engine:install:migrations

It will create any new migrations and skip existing ones


##Breaking changes:

  - ActsAsTaggableOn::Tag is not extend with ActsAsTaggableOn::Utils anymore.
    Please use ActsAsTaggableOn::Utils instead