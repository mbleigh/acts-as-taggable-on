$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'logger'

require File.expand_path('../../lib/acts-as-taggable-on', __FILE__)
I18n.enforce_available_locales = true
require 'ammeter/init'
require 'barrier'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }
