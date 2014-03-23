#TODO replace with database_cleaner gem

def clean_database!
  models = [ActsAsTaggableOn::Tag, ActsAsTaggableOn::Tagging, TaggableModel, OtherTaggableModel, InheritingTaggableModel,
            AlteredInheritingTaggableModel, User, UntaggableModel, OrderedTaggableModel]
  models.each do |model|
    ActiveRecord::Base.connection.execute "DELETE FROM #{model.table_name}"
  end
end

clean_database!
