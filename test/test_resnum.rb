#!/usr/local/bin/ruby -Ke
# $Id: test_resnum.rb 85 2004-09-02 11:30:05Z taki $

$LOAD_PATH.unshift('../')
$LOAD_PATH.unshift('../lib')
Dir.chdir('../')

require 'test/unit'
require 'slebbs'

require 'lib/utility'
require 'csv'


class TC_getresnum < Test::Unit::TestCase
  def setup
    @path = "./test.txt"
    @range = (1..100)
    open(@path, "w+") do |file|
      for i in @range
        file.puts i
      end
    end
  end

  # def teardown
  #   File.delete(@path)
  # end

  def test_get_title_line
    title = SleBbs::GetResnum.new(@path, "1").resnum
    assert_equal("1..1", title.to_s.chomp)
  end

  def test_range_read

    page = SleBbs::GetResnum.new(@path, "2-2").resnum
    assert_equal("1..1" + "2..2", page.to_s)

    page = SleBbs::GetResnum.new(@path, "50-80").resnum
    assert_equal("1..1" + "50..80", page.to_s)

    page = SleBbs::GetResnum.new(@path, "150-80").resnum
    assert_equal("1..1" + "80..100", page.to_s)

    page = SleBbs::GetResnum.new(@path, "-80").resnum
    assert_equal((@range.first..80).to_s, page.to_s)

  end

  def test_last_read

    page = SleBbs::GetResnum.new(@path, "|5").resnum
    assert_equal("1..1"+(((@range.last-4)..@range.last).to_s), page.to_s)

    page = SleBbs::GetResnum.new(@path, "|250").resnum
    assert_equal(((@range.first)..@range.last).to_s, page.to_s)

  end

  def test_target_read

    page = SleBbs::GetResnum.new(@path, "2").resnum
    assert_equal("2..2", page.to_s)
  end

  def test_all_read
    page = SleBbs::GetResnum.new(@path, "all").resnum
    assert_equal(@range.to_s, page.to_s)
  end

end
