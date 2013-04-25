# ActsAsTaggableOn
[![Build Status](https://secure.travis-ci.org/mbleigh/acts-as-taggable-on.png)](http://travis-ci.org/mbleigh/acts-as-taggable-on)

This plugin was originally based on Acts as Taggable on Steroids by Jonathan Viney.
It has evolved substantially since that point, but all credit goes to him for the
initial tagging functionality that so many people have used.

For instance, in a social network, a user might have tags that are called skills,
interests, sports, and more. There is no real way to differentiate between tags and
so an implementation of this type is not possible with acts as taggable on steroids.

Enter Acts as Taggable On. Rather than tying functionality to a specific keyword
(namely `tags`), acts as taggable on allows you to specify an arbitrary number of
tag "contexts" that can be used locally or in combination in the same way steroids
was used.

## Compatibility

Versions 2.x are compatible with Ruby 1.8.7+ and Rails 3.

Versions 2.4.1 and up are compatible with Rails 4 too (thanks to arabonradar and cwoodcox).

Versions 3.x (currently unreleased) are compatible with Ruby 1.9.3+ and Rails 3 and 4.

For an up-to-date roadmap, see https://github.com/mbleigh/acts-as-taggable-on/issues/milestones

## Installation

To use it, add it to your Gemfile:

```ruby
gem 'acts-as-taggable-on'
```

and bundle:

```ruby
bundle
```

#### Post Installation

```shell
rails generate acts_as_taggable_on:migration
rake db:migrate
```

## Testing

Acts As Taggable On uses RSpec for its test coverage. Inside the gem
directory, you can run the specs with:

```shell
bundle
rake spec
```

If you want, add a `.ruby-version` file in the project root (and use rbenv or RVM) to work on a specific version of Ruby.

## Usage

```ruby
class User < ActiveRecord::Base
  # Alias for acts_as_taggable_on :tags
  acts_as_taggable
  acts_as_taggable_on :skills, :interests
end

@user = User.new(:name => "Bobby")
@user.tag_list = "awesome, slick, hefty"      # this should be familiar
@user.skill_list = "joking, clowning, boxing" # but you can do it for any context!

@user.tags                                    # => [<Tag name:"awesome">,<Tag name:"slick">,<Tag name:"hefty">]
@user.skills                                  # => [<Tag name:"joking">,<Tag name:"clowning">,<Tag name:"boxing">]
@user.skill_list                              # => ["joking","clowning","boxing"] as TagList

@user.tag_list.remove("awesome")              # remove a single tag
@user.tag_list.remove("awesome, slick")       # works with arrays too
@user.tag_list.add("awesomer")                # add a single tag. alias for <<
@user.tag_list.add("awesomer, slicker")       # also works with arrays

User.skill_counts                             # => [<Tag name="joking" count=2>,<Tag name="clowning" count=1>...]
```

To preserve the order in which tags are created use `acts_as_ordered_taggable`:

```ruby
class User < ActiveRecord::Base
  # Alias for acts_as_ordered_taggable_on :tags
  acts_as_ordered_taggable
  acts_as_ordered_taggable_on :skills, :interests
end

@user = User.new(:name => "Bobby")
@user.tag_list = "east, south"
@user.save

@user.tag_list = "north, east, south, west"
@user.save

@user.reload
@user.tag_list # => ["north", "east", "south", "west"]
```

### Finding Tagged Objects

Acts As Taggable On uses scopes to create an association for tags.
This way you can mix and match to filter down your results.

```ruby
class User < ActiveRecord::Base
  acts_as_taggable_on :tags, :skills
  scope :by_join_date, order("created_at DESC")
end

User.tagged_with("awesome").by_join_date
User.tagged_with("awesome").by_join_date.paginate(:page => params[:page], :per_page => 20)

# Find a user with matching all tags, not just one
User.tagged_with(["awesome", "cool"], :match_all => true)

# Find a user with any of the tags:
User.tagged_with(["awesome", "cool"], :any => true)

# Find a user that not tags with awesome or cool:
User.tagged_with(["awesome", "cool"], :exclude => true)

# Find a user with any of tags based on context:
User.tagged_with(['awesome, cool'], :on => :tags, :any => true).tagged_with(['smart', 'shy'], :on => :skills, :any => true)
```

You can also use `:wild => true` option along with `:any` or `:exclude` option. It will looking for `%awesome%` and `%cool%` in sql.

__Tip:__ `User.tagged_with([])` or '' will return `[]`, but not all records.

### Relationships

You can find objects of the same type based on similar tags on certain contexts.
Also, objects will be returned in descending order based on the total number of
matched tags.

```ruby
@bobby = User.find_by_name("Bobby")
@bobby.skill_list # => ["jogging", "diving"]

@frankie = User.find_by_name("Frankie")
@frankie.skill_list # => ["hacking"]

@tom = User.find_by_name("Tom")
@tom.skill_list # => ["hacking", "jogging", "diving"]

@tom.find_related_skills # => [<User name="Bobby">,<User name="Frankie">]
@bobby.find_related_skills # => [<User name="Tom">]
@frankie.find_related_skills # => [<User name="Tom">]
```

### Dynamic Tag Contexts

In addition to the generated tag contexts in the definition, it is also possible
to allow for dynamic tag contexts (this could be user generated tag contexts!)

```ruby
@user = User.new(:name => "Bobby")
@user.set_tag_list_on(:customs, "same, as, tag, list")
@user.tag_list_on(:customs) # => ["same","as","tag","list"]
@user.save
@user.tags_on(:customs) # => [<Tag name='same'>,...]
@user.tag_counts_on(:customs)
User.tagged_with("same", :on => :customs) # => [@user]
```

### Tag Ownership

Tags can have owners:

```ruby
class User < ActiveRecord::Base
  acts_as_tagger
end

class Photo < ActiveRecord::Base
  acts_as_taggable_on :locations
end

@some_user.tag(@some_photo, :with => "paris, normandy", :on => :locations)
@some_user.owned_taggings
@some_user.owned_tags
Photo.tagged_with("paris", :on => :locations, :owned_by => @some_user)
@some_photo.locations_from(@some_user) # => ["paris", "normandy"]
@some_photo.owner_tags_on(@some_user, :locations) # => [#<ActsAsTaggableOn::Tag id: 1, name: "paris">...]
@some_photo.owner_tags_on(nil, :locations) # => Ownerships equivalent to saying @some_photo.locations
@some_user.tag(@some_photo, :with => "paris, normandy", :on => :locations, :skip_save => true) #won't save @some_photo object
```

### Dirty objects

```ruby
@bobby = User.find_by_name("Bobby")
@bobby.skill_list # => ["jogging", "diving"]

@bobby.skill_list_changed? #=> false
@bobby.changes #=> {}

@bobby.skill_list = "swimming"
@bobby.changes.should == {"skill_list"=>["jogging, diving", ["swimming"]]}
@bobby.skill_list_changed? #=> true

@bobby.skill_list_change.should == ["jogging, diving", ["swimming"]]
```

### Tag cloud calculations

To construct tag clouds, the frequency of each tag needs to be calculated.
Because we specified `acts_as_taggable_on` on the `User` class, we can
get a calculation of all the tag counts by using `User.tag_counts_on(:customs)`. But what if we wanted a tag count for
an single user's posts? To achieve this we call tag_counts on the association:

```ruby
User.find(:first).posts.tag_counts_on(:tags)
```

A helper is included to assist with generating tag clouds.

Here is an example that generates a tag cloud.

Helper:

```ruby
module PostsHelper
  include ActsAsTaggableOn::TagsHelper
end
```

Controller:

```ruby
class PostController < ApplicationController
  def tag_cloud
    @tags = Post.tag_counts_on(:tags)
  end
end
```

View:

```erb
<% tag_cloud(@tags, %w(css1 css2 css3 css4)) do |tag, css_class| %>
  <%= link_to tag.name, { :action => :tag, :id => tag.name }, :class => css_class %>
<% end %>
```

CSS:

```css
.css1 { font-size: 1.0em; }
.css2 { font-size: 1.2em; }
.css3 { font-size: 1.4em; }
.css4 { font-size: 1.6em; }
```

## Configuration

If you would like to remove unused tag objects after removing taggings, add:

```ruby
ActsAsTaggableOn.remove_unused_tags = true
```

If you want force tags to be saved downcased:

```ruby
ActsAsTaggableOn.force_lowercase = true
```

If you want tags to be saved parametrized (you can redefine to_param as well):

```ruby
ActsAsTaggableOn.force_parameterize = true
```

If you would like tags to be case-sensitive and not use LIKE queries for creation:

```ruby
ActsAsTaggableOn.strict_case_match = true
```

If you want to change the default delimiter (it defaults to ','). You can also pass in an array of delimiters such as ([',', '|']):

```ruby
ActsAsTaggableOn.delimiter = ','
```

## Contributors

We have a long list of valued contributors. [Check them all](https://github.com/mbleigh/acts-as-taggable-on/contributors)

## Maintainer

* [Joost Baaij](https://github.com/tilsammans)

## License

See [LICENSE](https://github.com/mbleigh/acts-as-taggable-on/blob/master/LICENSE.md)
