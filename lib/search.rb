# $Id: search.rb 141 2005-05-01 00:52:51Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

# class Search
#  definition a Search
#
class Search
  class FilereadError < StandardError; end

  def search(string)
    result = SleBbs::Msg["serch_result"]
    match_flag = false
    SleBbs::Thread.index do |filename|

      text = ''
      text << SleBbs::Resread.new(filename, "all").read.to_s

      begin
        null   = %r!^.*#{string}.*$!
      rescue RegexpError
        string = Regexp.escape(string)
      end

      text.scan(/^.*#{string}.*/).each do |match|
        result << "<p>"
        result << "<h2>" << SleBbs::Thread.title(filename) << "</h2>"
        result << match.gsub(/(#{string})/, "<span class=\"plusplus\">\\1<\/span>")
        result << "</p>"
        match_flag = true
      end
    end

    unless match_flag
       result << SleBbs::Msg["no_match"]
    end

    return result
  end
end
