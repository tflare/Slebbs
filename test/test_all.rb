#!/usr/local/bin/ruby -Ke
# $Id: test_all.rb 97 2004-10-13 14:14:30Z taki $

require 'test/unit'


exit Test::Unit::AutoRunner.run(false, File.dirname($0))
