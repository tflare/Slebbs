# $Id: host.rb 2 2004-03-27 02:39:22Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

#
# class CGI
#  enhanced CGI class.
#

class CGI
  def valid?(name)
    self.params[name] and self.params[name][0]
  end

  def escape_param(param)
    if param = self.params["#{param}"][0]
      CGI::escapeHTML(param)
    else
      nil
    end
  end
end

# utility
#
def erb(path)

  ERB::new(File::open("#{SleBbs::Config[:templatepath]}/" + path).read.untaint, nil , 2).result(binding)
end

def end_line(file)

  end_line = open(file.untaint, "r").read.scan(/^/).size
end


class Time

  def format_date
    youbi = %w(日 月 火 水 木 金 土)
    strftime("%Y/%m/%d(#{youbi[self.wday]}) %H:%M:%S JST")
  end
end

unless [].respond_to?(:sort_by) 
  class Array
    def sort_by
      self.collect {|i| [yield(i), i] }.
         sort {|a,b| a[0] <=> b[0] }.
         collect! {|i| i[1]}
    end
  end
end

module Host
  def Host.get
    if ENV['REMOTE_HOST'] == ENV['REMOTE_ADDR']
      remote_host = ENV['REMOTE_ADDR'].sub!(/\d+$/, '*')
    else
      remote_host = ENV['REMOTE_HOST'] or
                    ENV['REMOTE_ADDR'].sub(/\d+$/, '*')
    end
  end
end


=begin

  ISBN:400099997X と書くとアマゾンへのリンクに変換する。
  ISBN:4-000-99998-1 と'-'が入っていても可
  ISBN4-000-99999-5 と':'がなくても可

=end

module Isbn2link

  def Isbn2link.convert(str)
    regexp_isbn = %r!(?:ISBN|isbn):?\s?([04]-?(?:\d{8}|[-\d]{9})-?[\dXx])!

    str.gsub!(regexp_isbn){
      isbn = $1
      isbn.delete!('-')
      isbn.tr!('x', 'X')
      link = '<a href="http://www.amazon.co.jp/exec/obidos/ASIN/' + isbn + '/">amazon</a>'
    }

    str
  end
end

module Gzip

  def Gzip::exec?(cgi)
    if /gzip/ =~ cgi.accept_encoding and
      SleBbs::Config[:gzip_transfer]
        true
    else
        false
    end
  end

  def Gzip::write(cgi, page)

    begin
      require 'zlib'

      gz = Zlib::GzipWriter.new(STDOUT, Zlib::BEST_SPEED)
      gz.write page
      gz.close

    rescue
      print page
    end
  end
end


# class Textutil
#

class Textutil

  def initialize(text)
    @text = text
  end

  def convert(dbpath)

    clean_white_space
    res_target(dbpath)
    url_convert
    return @text
  end

private
  def clean_white_space
    @text.gsub!(/\r\n/, "<br>")
    @text.gsub!(/\r/, "<br>")
    @text.gsub!(/\n/, "<br>")
    z_space = "\241\241"   # 全角 スペース
    @text.gsub!(/<br>[ \t#{z_space}]+<br>/, "<br><br>")
    @text.gsub!(/(?:<br>)+$/, '') # 行末改行カット
    @text.gsub!(/(?:<br>){11,}/, "<br>" * 10) # 11行以上の改行は10行に切り詰める
  end

  def res_target(dbpath)  # >>1のような指定へのリンク追加

    /(\d{10})/ =~ dbpath
    referlink = "<a href=\"#{SleBbs::Config[:indexpath]}?act=view&amp;thread_id=#{$1}&amp;res_id=\\1\" target=\"_blank\">&gt;&gt;\\1</a>"
    @text.gsub!(/&gt;&gt;(\d+)/, referlink)
  end

  
  def url_convert

    http_url = %r{((?:https?|ftp)://[-!a-zA-Z0-9\.\/+#_?~&%=^\\@:;,'"*()]+)}

    @text.gsub!(http_url){%Q|<a href="#{$1}">#{$1}</a>|}
  end

public

  def length_cut(resnum, linenum, dbpath)

    if resnum.class == Range
      if resnum.first == resnum.last
        return @text
      end
    end

    if resnum.class == Integer
      return @text
    end

    line_sep = "<br>"
    if @text.scan(line_sep).size > SleBbs::Config[:res_max_line]

      texts  = @text.split(line_sep)

      @text = texts[0...SleBbs::Config[:res_max_line]].join(line_sep)

      end_markup_add()

      msg = "<br>行数が多いので省略されました。" << Textutil.new("&gt;&gt;#{linenum}").convert(dbpath) << "全文を読むにはこちらを参照してください。"
      @text << msg
    end
    @text
  end

  def end_markup_add
    befor_define = ["<a" , "<span"]
    after_define = ["</a>" , "</span>"]

    befor_define.length.times do |idx|
      b_times = @text.scan(befor_define[idx]).size
      a_times = @text.scan(after_define[idx]).size
      unless b_times  == a_times
        @text << after_define[idx]
      end
    end
  end
end


# module Filelock
#
module Filelock
  class FilelockError < StandardError; end

  def Filelock::lock(path)
    lockpath = path + 'lock'

    unless  File::exist?(lockpath)

      open(lockpath, "w").close

      if block_given?
        begin
          yield
        ensure
          Filelock::unlock(path)
        end
      end
    else

      10.times do
        unless  File::exist?(lockpath)
          Filelock::lock(lockpath)
        else
          sleep(0.5)
        end
      end

      raise Filelock::FilelockError
    end
  end

  def Filelock::unlock(path)
    lockpath = path + 'lock'
    File::delete(lockpath)
  end
end


module Trip

  def Trip::convert(name)

    trip_symbol = '◆'

    #もしトリップのふりをしようとしたら
    if name.include?(trip_symbol)
      return name.gsub!(/#{trip_symbol}/o,'#')
    end

    if /^(.+)#(.+)$/ =~ name
      name = $1
      key  = $2
      key  = key * 2 if key.size == 1
      key  = key.crypt(key)[-8,8]
      trip = name.crypt(key)[-8,8]

      name = name << trip_symbol << trip
    end
    return name
  end
end


module Markup

  def Markup.convert(text)

    Markup.define.each do |key, value|
      text.gsub!(value){"<span class=\"#{key}\">#{$1}<\/span>"}
    end

    return text
  end

private

  def Markup.define

    # {}で囲む ネストはできない。

    delimiter = '\{((?:(?!\{.*\}).)+?)\}'

  #  delimiter = '\{.+?\}'

    define = {
      'plusplus'   =>  %r|\+\+#{delimiter}|m,
      'minusminus' =>  %r|\-\-#{delimiter}|m,
      'plus'     =>  %r|\+#{delimiter}|m,
      'minus'    =>  %r|\-#{delimiter}|m,
    }
  end
end


module Auth
  class UnauthorizedError < StandardError; end;

  module_function

  def simple_auth(cgi)
    return true if SleBbs::Config[:auth] == false

    user, pass = user_pass(cgi)
    if user != nil and pass != nil

      require 'digest/sha2'

      if user == SleBbs::Config[:auth_user] and Digest::SHA256.hexdigest(pass) == SleBbs::Config[:auth_pass]
        user_regist(cgi, user, pass)
        return true
      end
    end

    user_regist_delete(cgi)
    raise UnauthorizedError

  end

  def user_pass(cgi)
    user = pass = ''

    begin
      session = CGI::Session.new(cgi, "session_key" => "SleBbs-auth",
                                 "new_session" => false
                                )
    rescue ArgumentError
      user = cgi.params['user'][0]
      pass = cgi.params['pass'][0]
    else
      if session['user'] == "" or session['pass'] == ""
        user = cgi.params['user'][0]
        pass = cgi.params['pass'][0]
      else
        user = session['user']
        pass = session['pass']
      end
      session.close
    end

    return user, pass
  end

  def user_regist(cgi, user, pass)

    File.umask(0066)

    session = CGI::Session.new(cgi, "session_key" => "SleBbs-auth",
                   "session_id" => "auth",
                   "new_session" => true,
                   "session_expires" => Time.now + 60 * 60 * 24 * 8) # 8 days

    session['user'] = user
    session['pass'] = pass

    session.close
  end

  def user_regist_delete(cgi)

    begin
      session = CGI::Session.new(cgi, "session_key" => "SleBbs-auth",
                                   "new_session" => false
                                  )
    rescue ArgumentError
    else
      session['user'] = ""
      session['pass'] = ""

      session.close
    end
  end

end
