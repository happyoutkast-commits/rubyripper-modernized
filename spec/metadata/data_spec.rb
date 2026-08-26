#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
#    Copyright (C) 2016 BleskoDev (bleskodev@gmail.com)
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

require 'rubyripper/metadata/data'

describe Metadata::Data do

  def makeData(artist, album, genre, year, discid, track1, track2=nil)
    md = Metadata::Data.new()
    md.artist = artist
    md.album = album 
    md.genre = genre
    md.year = year
    md.discid = discid
    md.setTrackname(1, track1)
    md.setTrackname(2, track2) if track2
    return md
  end

  def makeVarArtistData(album, genre, year, discid, 
                        artist1, track1, artist2=nil, track2=nil)
    md = Metadata::Data.new()
    md.artist = 'Various Artists' 
    md.album = album 
    md.genre = genre
    md.year = year
    md.discid = discid
    md.setVarArtist(1, artist1)
    md.setTrackname(1, track1)
    md.setVarArtist(2, artist2) if artist2
    md.setTrackname(2, track2) if track2
    return md
  end

  context "When the metadata provider is recorded" do
    it "should report whether a fallback provider was used" do
      metadata = Metadata::Data.new()
      metadata.preferred_metadata_source = 'musicbrainz'
      metadata.metadata_source = 'gnudb'

      expect(metadata.metadata_fallback?).to eq(true)
    end

    it "should not report a fallback when the preferred provider succeeded" do
      metadata = Metadata::Data.new()
      metadata.preferred_metadata_source = 'musicbrainz'
      metadata.metadata_source = 'musicbrainz'

      expect(metadata.metadata_fallback?).to eq(false)
    end

    it "should provide a readable name for the selected provider" do
      metadata = Metadata::Data.new()
      metadata.preferred_metadata_source = 'musicbrainz'
      metadata.metadata_source = 'musicbrainz'

      expect(metadata.metadata_source_description).to eq('MusicBrainz')
    end

    it "should include both provider names when a fallback was used" do
      metadata = Metadata::Data.new()
      metadata.preferred_metadata_source = 'musicbrainz'
      metadata.metadata_source = 'gnudb'

      expect(metadata.metadata_source_description).to eq(
        'GnuDB (fallback from MusicBrainz)'
      )
    end
  end
  
  context "When metadata for standard album is compared for equality" do

    it "should return true if equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      expect(md1 == md2).to eq(true)
    end

    it "should return false if artist is not equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('PacA','Alb','Jazz','1990','a332100','Song1','Song2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if album is not equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('Paco','AlC','Jazz','1990','a332100','Song1','Song2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if genre is not equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('Paco','Alb','Rock','1990','a332100','Song1','Song2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if year is not equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('Paco','Alb','Jazz','1991','a332100','Song1','Song2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if discid is not equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('Paco','Alb','Jazz','1990','a332101','Song1','Song2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if track count is not equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('Paco','Alb','Jazz','1990','a332100','Song1')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if track1 is not equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('Paco','Alb','Jazz','1990','a332100','Song0','Song2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if track2 is not equal" do
      md1 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song2')
      md2 = makeData('Paco','Alb','Jazz','1990','a332100','Song1','Song0')
      expect(md1 == md2).to eq(false)
    end

  end

  context "When metadata for various artists album is compared for equality" do

    it "should return true if equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      expect(md1 == md2).to eq(true)
    end

    it "should return false if album is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('AlC','Jazz','1990','a332100','A1','S1','A2','S2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if genre is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Rock','1990','a332100','A1','S1','A2','S2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if year is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Jazz','1991','a332100','A1','S1','A2','S2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if discid is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Jazz','1990','a332101','A1','S1','A2','S2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if track count is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if artist1 is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Jazz','1990','a332100','A0','S1','A2','S2')
      expect(md1 == md2).to eq(false)
    end
    
    it "should return false if track1 is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S0','A2','S2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if artist2 is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A0','S2')
      expect(md1 == md2).to eq(false)
    end

    it "should return false if track2 is not equal" do
      md1 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      md2 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S0')
      expect(md1 == md2).to eq(false)
    end

  end

  context "When metadata for various artists album is compared for equality with standard album" do

    it "should return false" do
      md1 = makeData('Various Artists', 'Alb','Jazz','1990','a332100','S1','S2')
      md2 = makeVarArtistData('Alb','Jazz','1990','a332100','A1','S1','A2','S2')
      expect(md1 == md2).to eq(false)
    end
    
  end
end
