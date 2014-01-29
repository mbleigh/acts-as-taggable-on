Changes are below categorized as `Features, Fixes, or Misc`.

Each change should fall into categories that would affect whether the release is major (breaking changes), minor (new behavior), or patch (bug fix). See [semver](http://semver.org/) and [pessimistic versioning](http://guides.rubygems.org/patterns/#pessimistic_version_constraint)

As such, a _Feature_ would map to either major or minor. A _bug fix_ to a patch.  And _misc_ is either minor or patch, the difference being kind of fuzzy for the purposes of history.  Adding tests would be patch level.

### Master [changes](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.0.1...master)

* Breaking Changes
* Features
  * [@jamesburke-examtime #467 Add :order_by_matching_tag_count option](https://github.com/mbleigh/acts-as-taggable-on/pull/469)
* Fixes
  * [@rafael #406 Dirty attributes not correctly derived](https://github.com/mbleigh/acts-as-taggable-on/pull/406)
  * [@bzbnhang #440 Did not respect strict_case_match](https://github.com/mbleigh/acts-as-taggable-on/pull/440)
  * [@znz #456 Fix breaking encoding of tag](https://github.com/mbleigh/acts-as-taggable-on/pull/456)
  * [@rgould #417 Let '.count' work when tagged_with is accompanied by a group clause](https://github.com/mbleigh/acts-as-taggable-on/pull/417)
  * [@developer88 #461 Move 'Distinct' out of select string and use .uniq instead](https://github.com/mbleigh/acts-as-taggable-on/pull/461)
* Misc
  * [@billychan #463 Thread safe support](https://github.com/mbleigh/acts-as-taggable-on/pull/463)
  * [@billychan #386 Add parse:true instructions to README](https://github.com/mbleigh/acts-as-taggable-on/pull/386)
  * [@seuros #449 Improve README/UPGRADING/post install docs](https://github.com/mbleigh/acts-as-taggable-on/pull/449)
  * [@seuros #452 Remove I18n deprecation warning in specs](https://github.com/mbleigh/acts-as-taggable-on/pull/452)
  * [@seuros #453 Test against Ruby 2.1 on Travis CI](https://github.com/mbleigh/acts-as-taggable-on/pull/453)
  * [@takashi #454 Clarify example in docs](https://github.com/mbleigh/acts-as-taggable-on/pull/454)

### [3.0.1 / 2014-01-08](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.0.0...v3.0.1)

* Fixes
  * [@rafael #406 Dirty attributes not correctly derived](https://github.com/mbleigh/acts-as-taggable-on/pull/406)
  * [@bzbnhang #440 Did not respect strict_case_match](https://github.com/mbleigh/acts-as-taggable-on/pull/440)
  * [@znz #456 Fix breaking encoding of tag](https://github.com/mbleigh/acts-as-taggable-on/pull/456)
* Misc
  * [@billychan #386 Add parse:true instructions to README](https://github.com/mbleigh/acts-as-taggable-on/pull/386)
  * [@seuros #449 Improve README/UPGRADING/post install docs](https://github.com/mbleigh/acts-as-taggable-on/pull/449)
  * [@seuros #452 Remove I18n deprecation warning in specs](https://github.com/mbleigh/acts-as-taggable-on/pull/452)
  * [@seuros #453 Test against Ruby 2.1 on Travis CI](https://github.com/mbleigh/acts-as-taggable-on/pull/453)
  * [@takashi #454 Clarify example in docs](https://github.com/mbleigh/acts-as-taggable-on/pull/454)

### [3.0.0 / 2014-01-01](https://github.com/mbleigh/acts-as-taggable-on/compare/v2.4.1...v3.0.0)

* Breaking Changes
  * No longer supports Ruby 1.8.
* Features
  * Supports Rails 4.1.
* Misc (TODO: expand)
  * [zquest #359](https://github.com/mbleigh/acts-as-taggable-on/pull/359)
  * [rsl #367](https://github.com/mbleigh/acts-as-taggable-on/pull/367)
  * [ktdreyer #383](https://github.com/mbleigh/acts-as-taggable-on/pull/383)
  * [cwoodcox #346](https://github.com/mbleigh/acts-as-taggable-on/pull/346)
  * [mrb #421](https://github.com/mbleigh/acts-as-taggable-on/pull/421)
  * [bf4 #430](https://github.com/mbleigh/acts-as-taggable-on/pull/430)
  * [sanemat #368](https://github.com/mbleigh/acts-as-taggable-on/pull/368)
  * [bf4 #343](https://github.com/mbleigh/acts-as-taggable-on/pull/343)
  * [marclennox #429](https://github.com/mbleigh/acts-as-taggable-on/pull/429)
  * [shekibobo #403](https://github.com/mbleigh/acts-as-taggable-on/pull/403)
  * [ches ktdreyer #410](https://github.com/mbleigh/acts-as-taggable-on/pull/410)
  * [makaroni4 #371](https://github.com/mbleigh/acts-as-taggable-on/pull/371)
  * [kenzai dstosik awt #431](https://github.com/mbleigh/acts-as-taggable-on/pull/431)
  * [bf4 joelcogen shekibobo aaronchi #438](https://github.com/mbleigh/acts-as-taggable-on/pull/438)
  * [seuros #442](https://github.com/mbleigh/acts-as-taggable-on/pull/442)
  * [bf4 #445](https://github.com/mbleigh/acts-as-taggable-on/pull/445)
  * [eaglemt #446](https://github.com/mbleigh/acts-as-taggable-on/pull/446)

### 3.0.0.rc2 [changes](https://github.com/mbleigh/acts-as-taggable-on/compare/fork-v3.0.0.rc1...fork-v3.0.0.rc2)

### 3.0.0.rc1 [changes](https://github.com/mbleigh/acts-as-taggable-on/compare/v2.4.1...fork-v3.0.0.rc1)

### [2.4.1 / 2013-05-07](https://github.com/mbleigh/acts-as-taggable-on/compare/v2.4.0...v2.4.1)

* Features
* Fixes
* Misc
