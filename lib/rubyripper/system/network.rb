#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'rubyripper/system/dependency'
require 'rubyripper/preferences/main'
require 'net/http' #automatically loads the 'uri' library
require 'cgi'#for translating characters to HTTP codes, space = %20 for instance

# This class handles all connectivity with a http server
class Network
  OPEN_TIMEOUT_SECONDS = 10
  READ_TIMEOUT_SECONDS = 20
  HTTP_RETRIES = 0

  attr_reader :path

  def initialize(prefs=nil, deps=nil, uri=nil, http=nil, cgi=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance()
    @uri = uri ? uri : URI
    @http = http ? http : Net::HTTP
    @cgi = cgi ? cgi : CGI
  end
  
  # website is the base URL without the subpath
  # example website is: http://freedb.freedb.org/~cddb/cddb.cgi
  def startCgiConnection(website)
    configureCgiConnection(website)
  end

  # fire up a CGI command to the server
  def get(query)
    puts "DEBUG: CGI query: #{@url.scheme + '://' +  @url.host + query}" if @prefs.debug
    begin
      @connection.request(configureGetRequest(query)).body
    rescue Exception => e
      puts "DEBUG: CGI query failed! #{e.message}" if @prefs.debug
      return ""
    end
  end
  
  # encode for a specific protocol in order to escape certain characters
  def encode(string)
    @cgi.escape(string)
  end

  # configure correctly user agent field of the GET request header
  def configureGetRequest(query)
    request = Net::HTTP::Get.new(query)
    request['User-Agent'] = "rubyripper/#{$rr_version} (#{$rr_url})"
    return request
  end

private
  # first configure the connection (with proxy if needed)
  def configureCgiConnection(website)
    @url = @uri.parse(website)
    @path = @url.path

    if @deps.env('http_proxy')
      proxy = @uri.parse(@deps.env('http_proxy'))
      @connection = @http.new(@url.host, @url.port, proxy.host,
      proxy.port, proxy.user, proxy.password ? @cgi.unescape(proxy.password) : '')
    else
      @connection = @http.new(@url.host, @url.port)
    end

    # Ruby's one-minute defaults make provider fallback feel like a frozen
    # application. These limits still allow for a slow connection while making
    # an unavailable metadata service fail promptly. Rubyripper performs its
    # own fallback by trying the other provider, so Net::HTTP should not repeat
    # the same failed request first.
    @connection.open_timeout = OPEN_TIMEOUT_SECONDS
    @connection.read_timeout = READ_TIMEOUT_SECONDS
    @connection.max_retries = HTTP_RETRIES
    @connection.use_ssl = @url.scheme == 'https'
  end
end
