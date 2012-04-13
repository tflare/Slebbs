#!/usr/local/bin/ruby -Ke
# $Id: index.cgi 157 2005-10-02 13:01:18Z taki $
# Copyright (C) 2004-2005 hiroyuki taki <taki@tflare.com>

begin

  BEGIN { STDOUT.binmode }
  $SAFE = 1

  require 'slebbs'
  require 'sleconfig'

  SleBbs::Distribute::new
rescue

  print "Content-Type: text/plain\n\n"
  exception = "#$! (#{$!.class})" + "\n" + 
        $!.backtrace.join("\n")
  puts exception

  open("#{SleBbs::Config[:dbpath]}/exception", "w") do |log|
    log.puts  exception
  end

end



