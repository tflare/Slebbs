#!/usr/local/bin/ruby -Ke
# $Id: test_markup.rb 114 2005-02-27 07:42:11Z taki $

$LOAD_PATH.unshift('../lib')

require 'utility'
require 'test/unit'

class TC_markup < Test::Unit::TestCase

  def test_basic
    input_text = '++{test}-{tt}+{yyy}--{rrr}'
    assert_equal(Markup.convert(input_text), %q|<span class="plusplus">test</span><span class="minus">tt</span><span class="plus">yyy</span><span class="minusminus">rrr</span>|)

  end

  def test_no
    input_text = '++{}'
    assert_equal(Markup.convert(input_text), %q|++{}|)
  end

  def test_minus2
    input_text = '-{{}}-{test}'
    assert_equal(Markup.convert(input_text), %q|-{{}}<span class="minus">test</span>|)
  end

  def test_plusplus2
    input_text = '{}{}++{test}'
    assert_equal(Markup.convert(input_text), %q|{}{}<span class="plusplus">test</span>|)
  end

#  def test_plusplus3
#    input_text = '+{kkk-{}}'
#    assert_equal(Markup.convert(input_text), %q|<span class="plus">kkk-{}</span>|)
#  end

end
