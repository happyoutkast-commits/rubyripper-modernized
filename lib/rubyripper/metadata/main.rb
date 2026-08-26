#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/disc/disc'
require 'rubyripper/preferences/main'

module Metadata
  class Main
    def initialize(disc, prefs=nil, musicbrainz=nil, freedb=nil, no_provider=nil)
      @disc = disc
      @prefs = prefs ? prefs : Preferences::Main.instance
      @musicbrainz = musicbrainz
      @freedb = freedb
      @no_provider = no_provider
    end
    
    # decide which metadataprovider is active
    # fall back to other metadata provider if no matches
    def get
      setProvidersPriority()
      selected_provider = nil

      @providers.each do |provider|
        startup(provider)
        selected_provider = provider
        break if provider == 'none' || @provider.status == 'ok' || @provider.status == 'multipleRecords'
      end

      record_metadata_source(selected_provider)
      return @provider
    end
    
    private
    
    def setProvidersPriority
      @providers = [@prefs.metadataProvider]
      @providers << 'musicbrainz' if @prefs.metadataProvider != 'musicbrainz'
      @providers << 'gnudb' if @prefs.metadataProvider != 'gnudb'
      @providers << 'none' if @prefs.metadataProvider != 'none'
    end
    
    def startup(provider)
      case provider
        when 'musicbrainz' then musicbrainz()
        when 'gnudb' then freedb()
        when 'none' then none()
      end
    end

    # Preserve both provider names so the interfaces can clearly report when
    # Rubyripper used a fallback instead of the user's preferred provider.
    def record_metadata_source(selected_provider)
      @provider.metadata_source = selected_provider
      @provider.preferred_metadata_source = @prefs.metadataProvider
    end
    
    def musicbrainz
      require 'rubyripper/metadata/musicbrainz'
      @provider = @musicbrainz ? @musicbrainz : MusicBrainz.new(@disc)
      @provider.get()
    end
    
    def freedb
      require 'rubyripper/metadata/freedb'
      @provider = @freedb ? @freedb : Freedb.new(@disc)
      @provider.get()
    end
    
    def none
      require 'rubyripper/metadata/noProvider'
      @provider = @no_provider ? @no_provider : NoProvider.new(@disc)
      @provider.get()
    end
  end
end
