# $Id: mixti.rb 133 2005-04-14 08:41:47Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

#
# module SleBbs
#
module SleBbs

  VERSION = '0.2.7'

  require 'cgi'
  require 'cgi/session'
  require 'erb'

  require 'lib/utility'

  begin
    require 'csv'
  rescue LoadError
    require 'lib/csv'
  end

  #
  # class Res
  #  definition a Res.
  #

  class Res

    def initialize(cgi = CGI.new)

      @cgi = cgi
    end

    def write(thread_id)
      input_replace
      Write.new(@cgi, Config[:dbpath] + "/#{thread_id}#{Config[:dbextname]}").write
    end

    def generate(thread_id, readnum)
      Html.new(@cgi, read(thread_id, readnum))
    end

    def read(thread_id, readnum)
      dbpath = Config[:dbpath] + "/#{thread_id}#{Config[:dbextname]}"
      ResHtmlread.new(dbpath, readnum).read
    end

    def search(string)
      require 'lib/search'
      Html.new(@cgi, Search.new.search(string))
    end

    def input_replace

    # It finds into which form the value was inputted.
      idx = catch(:exit) {
        @cgi.params['thread_id'].each_with_index do |thread_id, idx|
          if  @cgi.valid?(thread_id)
            throw :exit, idx
          end
        end
        idx = 0
      }

    # A value is replaced.
      if  idx != 0
        @cgi.keys.each do |key|
          @cgi.params["#{key}"][0] = @cgi.params["#{key}"][idx]
        end
      end
    end
  end

  # class Resread
  #  definition a Resread
  #

  class Resread

    def initialize(dbpath, readnum)

      @dbpath  = dbpath
      @readnum = readnum
    end

    def read

      @resnum = GetResnum.new(@dbpath, @readnum).resnum
      if @resnum.class == Array
        resnum, lines   = GetRes.new(@dbpath).get_res(@resnum.first)
        resnum2, lines2 = GetRes.new(@dbpath).get_res(@resnum.last)
        @resnum = [resnum, resnum2]
        @lines  = lines + lines2
      else
        @resnum, @lines = GetRes.new(@dbpath).get_res(@resnum)
      end
      return @lines
    end
  end

  class ResHtmlread < Resread

    def read
      super
      html = ResHtml.new(@dbpath, @lines, @resnum).resout
    end
  end

  class GetResnum
    def initialize(dbpath, readnum)

      @dbpath   = dbpath
      @readnum  = readnum
      @resnum   = nil
      @end_line = end_line(@dbpath)
    end

    def resnum

      range_num
      last_num
      target_num
      all_num

      if @resnum == nil
        @readnum = "all"
        all_num
      end
      return @resnum
    end

  private

    def title_line_num

      linenum = (1..1)
    end

    def target_num
      #usage 5
      if  /^(\d+)$/  =~ @readnum
        readnum = $1.to_i
        @resnum = (readnum..readnum)
      end
    end

    def all_num
      #usage all or All
      if  @readnum == "all" or  @readnum == "All"
        @resnum = (1..@end_line)
      end
    end

    def range_num
      #usage 5-5 or -5
      if  /^(\d+)?\-(\d+)$/  =~ @readnum
        if  $1 == nil
          start_res = 1
        else
          start_res = $1.to_i
        end

        end_res = $2.to_i

        if  end_res - start_res  <  0
          end_res, start_res = start_res, end_res
        end

        if  end_res > @end_line and start_res <= @end_line
          end_res = @end_line
        end

        addition_title_num(start_res, end_res)
      end
    end

    def last_num
      #usage |5
      #It specifies from the last.
      if  /^\|(\d+)$/  =~ @readnum
        end_res   = @end_line
        start_res = end_res + 1 - $1.to_i
        if  start_res <= 0
          start_res = 1
        end

        addition_title_num(start_res, end_res)
      end
    end

    def addition_title_num(start_res, end_res)

      if start_res != 1
        @resnum = [title_line_num, (start_res..end_res)]
      else
        @resnum = (start_res..end_res)
      end
    end
  end

  class GetRes

    def initialize(dbpath)

      @dbpath   = dbpath
    end

    def get_res(resnum)

      begin
        idx = resnum_to_idx(resnum)

        lines = get_lines(@dbpath, idx)

        if  lines == nil
          @res  = ''
          resnum = (1..end_line(@dbpath))
          resnum, lines = get_res(resnum)
        end

        return resnum, lines

      rescue Errno::ENOENT
        Html.new(CGI.new, Msg["no_logfile"])
        exit
      end
    end

    def get_lines(filename, index)

      array = get_filedata(filename)
      array[index]
    end

    private
    def get_filedata(filename)
      open(filename, "r") do |file|
        return file.readlines
      end
    end

    private
    def resnum_to_idx(resnum)

      if resnum.class == Range
        first = (resnum.first - 1)
        last  = (resnum.last - 1)
        idx   = (first..last)
        return idx
      end

      if resnum.class == Integer
        idx = resnum - 1
        return idx
      end
    end  
  end

  # class Resdata
  #  definition a Resdata
  #

  class Resdata

    def initialize(data=nil)
      if data != nil
        @name, @mail, @time, @ip, @ua, @title, @visible, @text = CSV.parse_line(data.chomp)
      end
    end

    def set(hash)
      hash.each{|key, value| send("#{key}=", value) }
    end

    def row
      row = [@name, @mail, @time, @ip, @ua, @title, @visible, @text]
    end

    def db
      CSV.generate_line(row)
    end

    def to_s
      row.to_s
    end

    attr_accessor :name, :mail, :time, :ip, :ua, :title, :visible, :text
    alias :inspect :to_s
  end


  # class ResHtml
  #  definition a ResHtml.
  #

  class ResHtml

    def initialize(dbpath, lines, readnum)

      @dbpath  = dbpath
      @lines   = lines
      @readnum = readnum
    end

    def resout

      body = ''
      body << %Q[<h2>#{Thread.title(@dbpath)}</h2>\n]

      @lines.each_with_index do |line, idx|

        @name, @mail, @time, @ip, @ua, @title, @visible, @text = Resdata.new(line).row

        visible()
        mail()

        @linenum = linenum(idx)

        if Config[:res_max_line]
          @text = Textutil.new(@text).length_cut(@readnum, @linenum, @dbpath)
        end

        body << erb("res.rhtml")
        if  @linenum == 1
          body << erb("resconvoy.rhtml")
        end
      end

      body << erb("resconvoy.rhtml") unless end_line(@dbpath) == 1
      body << resform

      return body
    end

  private
    def resform
      if  @linenum < Config[:max_res]
        erb("resform.rhtml") +
        erb("formsub.rhtml")
      else

        Msg["max_res"]
      end
    end

    def mail

      if  @mail == nil
        @mail = @name
      else
        @mail = %Q[<b><a href="mailto:#{@mail}">#{@name}</a></b>]
      end
    end

    def linenum(idx)
      if @readnum.class == Array
        readnum1, readnum2 = @readnum
        if idx == 0
          linenum = readnum1.first
        else
          linenum = readnum2.first + idx - (readnum1.last - readnum1.first + 1)
        end
      else
        linenum = @readnum.first + idx
      end
    end

    def visible
      if @visible == "false"
        @name = @time = @ip = @ua = @text = Config[:delete_display]
      end
    end
  end


  module Resedit

    def Resedit.delete(path, edit_line, line)
      line = Resread.new(path, (edit_line+1).to_s).read.to_s.chomp
      resdata = Resdata.new(line)
      resdata.visible = "false"
      Resedit.edit(path, edit_line, resdata.db)
    end

    def Resedit.edit(path, edit_line, data)
      temp = ''

      begin
        Filelock::lock(path) do

          File.open(path, "r+"){|file|
            edit_line.times{
              if line = file.gets
                temp << line
              end
            }
            temp << data << "\n"

            trush = file.gets #seek 1 line

            if line = file.gets
              temp << line
            end

            file.rewind
            file.print temp
            file.flush
            file.truncate(file.pos)

          }
        end
      rescue Filelock::FilelockError

        Html.new(CGI.new, Msg["lock"])
        exit
      end
    end
  end


  #
  # class Thread
  #  definition a Thread.
  #

  class Thread

    def initialize(cgi)

      @cgi = cgi
    end

    def form
      erb("threadform.rhtml") +
      erb("formsub.rhtml")
    end

    def write
      Write.new(@cgi, Config[:dbpath] + "/#{Time::now.to_i.to_s}#{Config[:dbextname]}").write
    end


    def read
      Threadread.new.read
    end

    def index

      Html.new(@cgi, read)
    end

    def generate

      Html.new(@cgi, form)
    end

    def Thread.title(dbpath)
      line = Resread.new(dbpath, "1").read.to_s
      Resdata.new(line).title
    end

    def Thread.path
      Dir.glob("#{Config[:dbpath]}/*#{Config[:dbextname]}")
    end

    def Thread.index

      Thread.path.each do |filename|
        yield filename
      end
    end

    def Thread.mtime_index

      # A file is sorted in the new order of updating time.
      Thread.path.sort_by{|f| File.mtime(f.untaint).to_i }.reverse.
        each_with_index do |filename, filecount|

        yield filename, filecount
      end
    end

    def Thread.last_mtime(cgi)
      thread_id = cgi.escape_param('thread_id')

      if thread_id
        f = "#{Config[:dbpath]}/#{thread_id}#{Config[:dbextname]}"
        last_mtime = File.mtime(f.untaint)
      else
        last_mtime = Thread.path.collect{|f| File.mtime(f.untaint)}.max
      end

      if last_mtime == nil
         last_mtime = Time.at(0)
      end
      last_mtime
    end
  end

  # class Threadread
  #  definition a Threadread

  class Threadread

    def read

      index = ''
      index  << erb("top.rhtml")
      index  << thread
      index  << "</table>"
      index  << erb("newthread.rhtml")
      index  << body
    end

    def thread

      thread = ""
      thread_list do |name, time, num, title|

        thread_id = File::basename(@filename, Config[:dbextname])

        thread << %Q[<tr>\n]
        thread << %Q[<td><a href="#{Config[:indexpath]}?act=view&amp;thread_id=#{thread_id}&amp;res_id=%7C50">#{@filecount}</a></td>\n]
        thread << %Q[<td><a href="#{Config[:indexpath]}##{@filecount}">#{title}</a></td>\n]
        thread << %Q[<td>#{name}</td><td align="right">#{num}</td><td>#{time}</td>]
        thread << %Q[</tr>\n]

        if block_given?
          thread << yield(thread_id)
        end
      end

      return thread
    end

    def body

      body = ""
      thread_list do |name, time, num, title|

        l_body = ResHtmlread.new(@filename, Config[:start_display_res]).read.to_s.chomp
        body   << l_body.gsub(/<h2>(.*)<\/h2>/){"<h2>[1:#{end_line(@filename)}]<a name=\"#{@filecount}\">#{$1}</a><\/h2>"}

      end


      return body
    end


    def thread_list

      SleBbs::Thread.mtime_index do |file, filecount|

        @filename, @filecount =  file, filecount + 1
        yield element
      end
    end

    private

    def element
      resdata = Resdata.new(Resread.new(@filename, "1").read.to_s)
      element = [resdata.name, File.mtime(@filename).format_date, end_line(@filename), resdata.title]
    end

  end

  #
  # class Write
  #  definition a Write.
  #

  class Write
    def initialize(cgi, dbpath)

      @cgi  = cgi
      @dbpath = dbpath.untaint
    end

    private

    def text

      text = @cgi.escape_param('text')

      text = Textutil.new(text).convert(@dbpath)

      if  text == ''
        Html.new(@cgi, Msg["text_empty"])
        exit
      end

      text = Markup.convert(text)
      text = Isbn2link.convert(text)

      if  @cgi.valid?('title')
        title = @cgi.escape_param('title')
        title_repeat_check(title)
      else
        text_repeat_check(text)
      end

      return text
    end

    def title_repeat_check(title)
      Thread.index do |path|
        if title == Thread.title(path)
          Html.new(@cgi, Msg["title_repeat"])
          exit
        end
      end
    end

    def text_repeat_check(text)
      line = Resread.new(@dbpath, end_line(@dbpath).to_s).read.to_s
      prevtext = Resdata.new(line).text

      if  prevtext == text
        Html.new(@cgi, Msg["text_repeat"])
        exit
      end
    end

    def name(trip = "yes")

      name = @cgi.escape_param('name')

      return  name = Config[:noname]  if  name == ''
      return  Trip::convert(name)     if  trip == "yes"
      return  name                    if  trip == "no"
    end

    def mail
      mail = @cgi.escape_param('mail')
      return  mail = nil if  mail == ''
      return  mail.sub(/@/,"&#64;") #mail bot measure
    end

    def session
      return nil unless Config[:session]
      if @cgi.escape_param('save_cookie') != "on"

        session = CGI::Session.new(@cgi, "session_key" => "SleBbs",
                         "session_id"  => "user")
        if session == nil
          user = pass = ''
        else

          session['name'] = ''
          session['mail'] = ''
          session.close
        end
        return nil
      end
      File.umask(0066)

      session = CGI::Session.new(@cgi, "session_key" => "SleBbs",
                     "session_id" => "user",
                     "session_expires" => Time.now + 60 * 60 * 24 * 8) # 8 days

      session['name'] = name(trip = "no")
      session['mail'] = mail

      session.close

    end

    def title
      if  @cgi.valid?('title')
        if @cgi.escape_param('title') == ''
          Html.new(@cgi, Msg["title_empty"])
          exit
        else
          title = @cgi.escape_param('title')
        end
      else
        title = ''
      end
    end

    def visible
      visible = "true"
    end

    def host
      if  Config[:host]
        Host::get
      else
        host = ''
      end
    end

    def user_agent
      if  Config[:ua]
        @cgi.user_agent
      else
        ua = ''
      end
    end

    def resdata

      resdata = Resdata.new

      resdata.set({
        :name  => name(),
        :mail  => mail(),
        :time  => Time::now.format_date,
        :ip    => host(),
        :ua    => user_agent(),
        :title   => title(),
        :visible => visible(),
        :text  => text(),

      })

      resdata.db
    end

    ######
    public
    ######

    def write

      session

      dbline = resdata()
      begin
        Filelock::lock(@dbpath) do

          open(@dbpath, "a") do |db|
            db.puts  dbline
          end
        end

      rescue Filelock::FilelockError
        Html.new(@cgi, Msg["lock"])
        exit
      end
    end
  end

  #
  # class Html
  #  definition a Html.
  #

  class Html

    def initialize(cgi, body)
      @cgi = cgi
      make(body)
    end

  private
    def make(body)
      html = ''
      html <<  erb("header.rhtml")
      html <<  body
      html <<  erb("footer.rhtml")

      send(html)
    end

    def last_mtime
      Thread.last_mtime(@cgi)
    end

    def head

      head = {
          'charset'     => 'euc-jp',
          'language'    => 'ja',
          'Last-Modified' => CGI.rfc1123_date(last_mtime),
          'Cache-Control' => 'no-cache',
          'Pragma'    => 'no-cache',
      }

      if Gzip::exec?(@cgi)
        gzip_head = {'Content-Encoding' => 'gzip'}
        head.update(gzip_head)
      end

      return head
    end


    def send(page)

      if Gzip::exec?(@cgi)
        print @cgi.header(head())
        Gzip::write(@cgi, page)
      else
        @cgi.out(head()){page}
      end
    end

  end

  #
  # class Distribute
  #  definition a Distribute.
  #

  class Distribute

    def initialize
      @cgi = CGI.new

      @thread_id = @cgi.escape_param('thread_id')

      Initial.new(@cgi, @thread_id)
      Backup.new

      if  @cgi.escape_param('act')
        __send__(@cgi.escape_param('act'))
      else
        Thread::new(@cgi).index
      end
    end

  private
    def res

      Res::new(@cgi).write(@thread_id)
      Thread::new(@cgi).index
    end

    def view

      if  @cgi.valid?('res_id')
        viewnum = @cgi.escape_param('res_id')
      else
        viewnum = "all"
      end

      Res::new.generate(@thread_id, viewnum)
    end

    def thread
      Thread::new(@cgi).generate
    end

    def make_thread

      thread = Thread::new(@cgi)
      thread.write
      thread.index
    end

    def search
      Res::new(@cgi).search(@cgi.escape_param('string'))
    end

    def method_missing(message)
      Html.new(@cgi, Msg["method_missing"] + message.to_s)
      exit
    end

  end

  #
  # class Initial
  #  definition a Initial.
  #

  class Initial

    def initialize(cgi, thread_id)

      @cgi = cgi
      maintenance_check
      path_traversal_check(thread_id)
    end

    def maintenance_check
      if Config[:maintenance_mode]
        Html.new(@cgi, Msg["maintenance"])
        exit
      end
    end

    def path_traversal_check(thread_id)

      if  thread_id
        unless  /\d{10}/ =~ thread_id
          Html.new(@cgi, Msg["path_traversal"])
          exit
        end
      end
    end

  end


  #
  # class Backup
  #  definition a Backup.
  #

  class Backup

    def initialize
      @backup_dir  = "#{Config[:dbpath]}"
      @backup_time_f = "#{@backup_dir}/backuptime"
      @interval    = Config[:backup_interval]

      backup
    end


    def backup

      if timing_check?
        require 'ftools'

        Thread.index do |path|
          path = path.untaint
          File.copy(path, path + ".bak")
        end
        write_backup_time(Time.now.to_i.to_s)
      end
    end


    def timing_check?

      if  Time.now > read_backup_time() + @interval
        true
      else
        false
      end
    end

    def read_backup_time

      begin
        open(@backup_time_f, "r") do |file|

          backup_time = Time.at(file.read.chomp.to_i)
        end
      rescue Errno::ENOENT

        backup_time = Time.at(0)
      rescue
        raise
      end
    end

    def write_backup_time(time)

      open(@backup_time_f, "w") do |file|
        file.puts  time
      end
    end
  end

  #
  # module Msg
  #  definition a Msg.
  #
  module Msg

    DEFINE = {}

    File::open("./msg_j.cfg"){|file|
      file.read.each_line do |line|
        next if /^#/   =~ line
        defkey, value  =  line.chomp.split(/\s+/)
        DEFINE[defkey] =  value
      end
    }

    def self.[](key)

      DEFINE[key] ||= DEFINE["msg_no_define"] + key
    end
  end
end
