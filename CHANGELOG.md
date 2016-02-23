Changes are below categorized as `Features, Fixes, or Misc`.

Each change should fall into categories that would affect whether the release is major (breaking changes), minor (new behavior), or patch (bug fix). See [semver](http://semver.org/) and [pessimistic versioning](http://guides.rubygems.org/patterns/#pessimistic_version_constraint)

As such, a _Feature_ would map to either major or minor. A _bug fix_ to a patch.  And _misc_ is either minor or patch, the difference being kind of fuzzy for the purposes of history.  Adding tests would be patch level.

### [3.5.0 / 2015-03-03](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.4...v3.5.0)

  * Fixes
   * [@rikettsie Fixed collation for MySql via rake rule or config parameter](https://github.com/mbleigh/acts-as-taggable-on/pull/634)
  *Misc
   * [@pcupueran Add rspec test for tagging_spec completeness]()

### [3.4.4 / 2015-02-11](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.3...v3.4.4)

  * Fixes
   * [@d4rky-pl Add context constraint to find_related_* methods](https://github.com/mbleigh/acts-as-taggable-on/pull/629)


### [3.4.3 / 2014-09-26](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.2...v3.4.3)

  * Fixes
   * [@warp  clears column cache on reset_column_information resolves](https://github.com/mbleigh/acts-as-taggable-on/pull/621)

### [3.4.2 / 2014-09-26](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.1...v3.4.2)

  * Fixes
   	* [@stiff    fixed tagged_with :any in postgresql](https://github.com/mbleigh/acts-as-taggable-on/pull/570)
   	* [@jerefrer fixed encoding in mysql](https://github.com/mbleigh/acts-as-taggable-on/pull/588)
   	* [@markedmondson 	Ensure taggings context aliases are maintained when joining multiple taggables](https://github.com/mbleigh/acts-as-taggable-on/pull/589)

### [3.4.1 / 2014-09-01](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.4.0...v3.4.1)
  * Fixes
    * [@konukhov fix owned ordered taggable bug](https://github.com/mbleigh/acts-as-taggable-on/pull/585)

### [3.4.0 / 2014-08-29](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.3.0...v3.4.0)

  * Features
    * [@ProGM Support for custom parsers for tags](https://github.com/mbleigh/acts-as-taggable-on/pull/579)
    * [@damzcodes #577 Popular feature](https://github.com/mbleigh/acts-as-taggable-on/pull/577)
  * Fixes
    * [@twalpole Update for rails edge (4.2)](https://github.com/mbleigh/acts-as-taggable-on/pull/583)
  * Performance
    * [@dontfidget #587 Use pluck instead of select](https://github.com/mbleigh/acts-as-taggable-on/pull/587)

### [3.3.0 / 2014-07-08](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.6...v3.3.0)

* Features
  * [@felipeclopes #488 Support for `start_at` and `end_at` restrictions when selecting tags](https://github.com/mbleigh/acts-as-taggable-on/pull/488)

* Fixes
  * [@tonytonyjan #560 Fix for `ActsAsTaggableOn.remove_unused_tags` doesn't work](https://github.com/mbleigh/acts-as-taggable-on/pull/560)
  * [@ThearkInn #555 Fix for `tag_cloud` helper to generate correct css tags](https://github.com/mbleigh/acts-as-taggable-on/pull/555)

* Performance
  * [@pcai #556 Add back taggables index in the taggins table](https://github.com/mbleigh/acts-as-taggable-on/pull/556)


### [3.2.6 / 2014-05-28](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.5...v3.2.6)

* Fixes
  * [@seuros #548 Fix dirty marking when tags are not ordered](https://github.com/mbleigh/acts-as-taggable-on/issues/548)

* Misc
  * [@seuros Remove actionpack dependency](https://github.com/mbleigh/acts-as-taggable-on/commit/5d20e0486c892fbe21af42fdcd79d0b6ebe87ed4)
  * [@seuros #547 Add tests for update_attributes](https://github.com/mbleigh/acts-as-taggable-on/issues/547)


### [3.2.5 / 2014-05-25](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.4...v3.2.5)

* Fixes
  * [@seuros #546 Fix autoload bug. Now require engine file instead of autoloading it](https://github.com/mbleigh/acts-as-taggable-on/issues/546)


### [3.2.4 / 2014-05-24](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.3...v3.2.4)

* Fixes
  * [@seuros #544 Fix incorrect query generation related to `GROUP BY` SQL statement](https://github.com/mbleigh/acts-as-taggable-on/issues/544)

* Misc
  * [@seuros #545 Remove `ammeter` development dependency](https://github.com/mbleigh/acts-as-taggable-on/pull/545)
  * [@seuros #545 Deprecate `TagList.from` in favor of `TagListParser.parse`](https://github.com/mbleigh/acts-as-taggable-on/pull/545)
  * [@seuros #543 Introduce lazy loading](https://github.com/mbleigh/acts-as-taggable-on/pull/543)
  * [@seuros #541 Deprecate ActsAsTaggableOn::Utils](https://github.com/mbleigh/acts-as-taggable-on/pull/541)


### [3.2.3 / 2014-05-16](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.2...v3.2.3)

* Fixes
  * [@seuros #540 Fix for tags removal (it was affecting all records with the same tag)](https://github.com/mbleigh/acts-as-taggable-on/pull/540)
  * [@akcho8 #535 Fix for `options` Hash passed to methods from being deleted by those methods](https://github.com/mbleigh/acts-as-taggable-on/pull/535)


### [3.2.2 / 2014-05-07](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.1...v3.2.2)

* Breaking Changes
  * [@seuros #526 Taggable models are not extended with ActsAsTaggableOn::Utils anymore](https://github.com/mbleigh/acts-as-taggable-on/pull/526)

* Fixes
  * [@seuros #536 Add explicit conversion of tags to strings (when assigning tags)](https://github.com/mbleigh/acts-as-taggable-on/pull/536)

* Misc
  * [@seuros #526 Delete outdated benchmark script](https://github.com/mbleigh/acts-as-taggable-on/pull/526)
  * [@seuros #525 Fix tests so that they pass with MySQL](https://github.com/mbleigh/acts-as-taggable-on/pull/525)


### [3.2.1 / 2014-05-06](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.2.0...v3.2.1)

* Misc
  * [@seuros #523 Run tests loading only ActiveRecord (without the full Rails stack)](https://github.com/mbleigh/acts-as-taggable-on/pull/523)
  * [@seuros #523 Remove activesupport dependency](https://github.com/mbleigh/acts-as-taggable-on/pull/523)
  * [@seuros #523 Introduce database_cleaner in specs](https://github.com/mbleigh/acts-as-taggable-on/pull/523)
  * [@seuros #520 Tag_list cleanup](https://github.com/mbleigh/acts-as-taggable-on/pull/520)


### [3.2.0 / 2014-05-01](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.1.1...v3.2.0)

 * Breaking Changes
   * ActsAsTaggableOn::Tag is not extend with ActsAsTaggableOn::Utils anymore
 * Features
   * [@chess #413 Hook to support STI subclasses of Tag in save_tags](https://github.com/mbleigh/acts-as-taggable-on/pull/413)
 * Fixes
   * [@jdelStrother #515 Rename Compatibility methods to reduce chance of conflicts ](https://github.com/mbleigh/acts-as-taggable-on/pull/515)
   * [@seuros #512 fix for << method](https://github.com/mbleigh/acts-as-taggable-on/pull/512)
   * [@sonots #510 fix IN subquery error for mysql](https://github.com/mbleigh/acts-as-taggable-on/pull/510)
   * [@jonseaberg #499 fix for race condition when multiple processes try to add the same tag](https://github.com/mbleigh/acts-as-taggable-on/pull/499)
   * [@leklund #496 Fix for distinct and postgresql json columns errors](https://github.com/mbleigh/acts-as-taggable-on/pull/496)
   * [@thatbettina & @plexus #394 Multiple quoted tags](https://github.com/mbleigh/acts-as-taggable-on/pull/496)
 * Performance
 * Misc
   * [@seuros #511 Rspec 3](https://github.com/mbleigh/acts-as-taggable-on/pull/511)

### [3.1.0 / 2014-03-31](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.0.1...v3.1.0)

* Fixes
  * [@mikehale #487 Match_all respects context](https://github.com/mbleigh/acts-as-taggable-on/pull/487)
* Performance
  * [@dgilperez #390 Add taggings counter cache](https://github.com/mbleigh/acts-as-taggable-on/pull/390)
* Misc
 * [@jonseaberg Add missing indexes to schema used in specs #474](https://github.com/mbleigh/acts-as-taggable-on/pull/474)
 * [@seuros Specify Ruby >= 1.9.3 required in gemspec](https://github.com/mbleigh/acts-as-taggable-on/pull/502)
 * [@kiasaki Add missing quotes to code example](https://github.com/mbleigh/acts-as-taggable-on/pull/501)

### [3.1.0.rc1 / 2014-02-26](https://github.com/mbleigh/acts-as-taggable-on/compare/v3.0.1...v3.1.0.rc1)

* Features
  * [@jamesburke-examtime #467 Add :order_by_matching_tag_count option](https://github.com/mbleigh/acts-as-taggable-on/pull/469)
* Fixes
  * [@rafael #406 Dirty attributes not correctly derived](https://github.com/mbleigh/acts-as-taggable-on/pull/406)
  * [@bzbnhang #440 Did not respect strict_case_match](https://github.com/mbleigh/acts-as-taggable-on/pull/440)
  * [@znz #456 Fix breaking encoding of tag](https://github.com/mbleigh/acts-as-taggable-on/pull/456)
  * [@rgould #417 Let '.count' work when tagged_with is accompanied by a group clause](https://github.com/mbleigh/acts-as-taggable-on/pull/417)
  * [@developer88 #461 Move 'Distinct' out of select string and use .uniq instead](https://github.com/mbleigh/acts-as-taggable-on/pull/461)
  * [@gerard-leijdekkers #473 Fixed down migration index name](https://github.com/mbleigh/acts-as-taggable-on/pull/473)
  * [@leo-souza #498 Use database's lower function for case-insensitive match](https://github.com/mbleigh/acts-as-taggable-on/pull/498)
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
