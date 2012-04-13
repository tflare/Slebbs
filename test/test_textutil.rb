#!/usr/local/bin/ruby -Ke
# $Id: test_textutil.rb 134 2005-04-14 11:17:56Z taki $

$LOAD_PATH.unshift('../')
$LOAD_PATH.unshift('../lib')

require 'test/unit'
require 'utility'
require 'sleconfig'


class TC_resread < Test::Unit::TestCase

  def test_clean_white_space
    text = "\r\n"
    new_text = Textutil.new(text).convert(nil)
    assert_equal('', new_text)

    text = "\r"
    new_text = Textutil.new(text).convert(nil)
    assert_equal('', new_text)

    text = "\n"
    new_text = Textutil.new(text).convert(nil)
    assert_equal('', new_text)
  end

  def test_newline2

    z_space = "\241\241"

    text = "\n" * 11
    new_text = Textutil.new(text).convert(nil)
    assert_equal('', new_text)

    text = 'test' + "\n" * 11
    new_text = Textutil.new(text).convert(nil)
    assert_equal('test', new_text)

    text = 'test' + "\n" * 11 + 'test2'
    new_text = Textutil.new(text).convert(nil)
    assert_equal('test' + '<br>' * 10 + 'test2', new_text)

    text = 'test' + "\n" + ' ' + z_space + 'test2'
    new_text = Textutil.new(text).convert(nil)
    assert_equal("test<br> #{z_space}test2", new_text)

    text = 'test' + "\n" + ' ' + z_space + "\n"
    new_text = Textutil.new(text).convert(nil)
    assert_equal('test', new_text)

  end

  def test_res_target
    require 'cgi'
    text   = CGI::escapeHTML(">>1")
    dbpath = "1021254512"
    url  = Textutil.new(text).convert(dbpath)
    assert_equal(%Q|<a href=\"#{SleBbs::Config[:indexpath]}?act=view&amp;thread_id=#{dbpath}&amp;res_id=1\" target=\"_blank\">&gt;&gt;1</a>|, url)

  end

  def test_http_url_convert

    text = 'http://www.foo.com/'
    url  = Textutil.new(text).convert(nil)
    assert_equal(%Q|<a href="http://www.foo.com/">http://www.foo.com/</a>|, url)
  end

  def test_https_url_convert

    text = 'https://www.foo.com/'
    url  = Textutil.new(text).convert(nil)
    assert_equal(%Q|<a href="https://www.foo.com/">https://www.foo.com/</a>|, url)
  end

  def test_novalid_url_convert

    text = 'ttp://www.foo.com/'
    url  = Textutil.new(text).convert(nil)
    assert_equal('ttp://www.foo.com/', url)
  end

end
