## 2011-08-21
* escape _ and % for mysql and postgres (@tilsammans)
* Now depends on mysql2 gem
* tagged_with :any is chainable now (@jeffreyiacono)
* tagged_with(nil) returns scoped object
* Case-insensitivity for TaggedModel.tagged_with for PostgreSQL database
* tagged_with(' ') returns scoped object
* remove warning for rails 3.1 about class_inheritable_attribute
* use ActiveRecord migration_number to avoid clashs (@atd)

## 2010-02-17
* Converted the plugin to be compatible with Rails3

## 2009-12-02

* PostgreSQL is now supported (via morgoth)

## 2008-07-17

* Can now use a named_scope to find tags!

## 2008-06-23

* Can now find related objects of another class (tristanzdunn)
* Removed extraneous down migration cruft (azabaj)

## 2008-06-09

 * Added support for Single Table Inheritance
 * Adding gemspec and rails/init.rb for gemified plugin

## 2007-12-12

 * Added ability to use dynamic tag contexts
 * Fixed missing migration generator
