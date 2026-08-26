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

require 'rubyripper/system/network'

describe Network do

  let(:prefs) {double('Preferences').as_null_object}
  let(:deps) {double('Dependency').as_null_object}
  let(:uri) {double('URI').as_null_object}
  let(:url) {double('URL').as_null_object}
  let(:proxy) {double('Proxy').as_null_object}
  let(:http) {double('NetHttp').as_null_object}
  let(:connection) {double('HTTP connection').as_null_object}
  let(:cgi) {double('CGI').as_null_object}
  let(:network) {Network.new(prefs, deps, uri, http, cgi)}

  context "When setting up a CGI connection" do
    before(:each) do
      allow(prefs).to receive(:debug).and_return false
      expect(url).to receive(:host).once.and_return 1
      expect(url).to receive(:port).once.and_return 2
      expect(url).to receive(:path).once.and_return 3
      expect(url).to receive(:scheme).once.and_return 'http'

      expect(connection).to receive(:open_timeout=)
        .with(Network::OPEN_TIMEOUT_SECONDS)
      expect(connection).to receive(:read_timeout=)
        .with(Network::READ_TIMEOUT_SECONDS)
      expect(connection).to receive(:max_retries=)
        .with(Network::HTTP_RETRIES)
      expect(connection).to receive(:use_ssl=).with(false)
    end
    
    it "should be able to do so without a proxy" do
      expect(deps).to receive(:env).with('http_proxy').once().and_return nil
      expect(uri).to receive(:parse).once.and_return(url)
      expect(http).to receive(:new).with(1, 2).and_return(connection)
      
      network.startCgiConnection('http://freedb.freedb.org/~cddb/cddb.cgi')
      expect(network.path).to eq(3)
    end
    
    it "should be able to do so with a proxy with no password" do
      expect(deps).to receive(:env).with('http_proxy').twice().and_return 4
      expect(uri).to receive(:parse).once.and_return(url)
      expect(proxy).to receive(:host).and_return 5
      expect(proxy).to receive(:port).and_return 6
      expect(proxy).to receive(:user).and_return 7
      expect(proxy).to receive(:password).and_return false
      expect(uri).to receive(:parse).with(4).and_return proxy
      expect(http).to receive(:new).with(1, 2, 5, 6, 7, '')
        .and_return(connection)
      
      network.startCgiConnection('http://freedb.freedb.org/~cddb/cddb.cgi')
      expect(network.path).to eq(3)
    end
  end

  context "When setting up a CGI query" do
    it "should correctly setup User-Agent header field" do
      query = 'http://freedb.freedb.org/~cddb/cddb.cgi'
      request = network.configureGetRequest(query)
      expect(request['User-Agent']).to eq("rubyripper/#{$rr_version} (#{$rr_url})")
    end

    it "should return an empty result when the provider times out" do
      allow(prefs).to receive(:debug).and_return false
      network.instance_variable_set(:@connection, connection)
      expect(connection).to receive(:request).and_raise(Net::ReadTimeout)

      expect(network.get('/lookup')).to eq('')
    end
  end
end
