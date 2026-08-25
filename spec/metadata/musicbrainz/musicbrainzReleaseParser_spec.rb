#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2011  Ian Jacobi (pipian@pipian.com)
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

require 'rubyripper/metadata/musicbrainz/musicbrainzReleaseParser'
require 'rexml/document'

RELEASE_CACHE = {}

describe MusicBrainzReleaseParser do

  def readRelease(doc)
    if !RELEASE_CACHE.has_key?(doc)
      RELEASE_CACHE[doc] = REXML::XPath::first(REXML::Document.new(File.read(doc)), '//metadata/release', {''=>'http://musicbrainz.org/ns/mmd-2.0#'})
    end
    RELEASE_CACHE[doc]
  end

  let(:prefs) {double('Preferences').as_null_object}
  let(:http) {double('MusicBrainzWebService').as_null_object}
  let(:parser) {MusicBrainzReleaseParser.new(nil, http, prefs)}

  context "Before parsing the disc" do
    it "should set some default values" do
      expect(parser.md.artist).to eq('Unknown')
      expect(parser.md.album).to eq('Unknown')
      expect(parser.md.genre).to eq('Unknown')
      expect(parser.md.year).to eq('0')
      expect(parser.md.extraDiscInfo).to eq('')
      expect(parser.md.discid).to eq('')
      expect(parser.md.trackname(12)).to eq('Track 12')
      expect(parser.md.getVarArtist(12)).to eq('Unknown')
    end
  end

  context "When parsing a MusicBrainz release XML element" do
    before(:each) do
      allow(prefs).to receive(:useEarliestDate).and_return false
      allow(http).to receive(:get).and_return File.read('spec/metadata/musicbrainz/data/noTags.xml')
      allow(http).to receive(:path).and_return '/ws/2/'
    end

    it "should parse all standard info" do
      parser.parse(readRelease('spec/metadata/musicbrainz/data/standardRelease.xml'),
                   '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

      expect(parser.status).to eq('ok')
      expect(parser.md.discid).to eq('e50b3c11')
      expect(parser.md.artist).to eq('The Beatles')
      expect(parser.md.album).to eq('Abbey Road')
      expect(parser.md.year).to eq('2009')
      expect(parser.md.trackname(1)).to eq('Come Together')
      expect(parser.md.trackname(2)).to eq('Something')
    end

    it "should not crash when parsing incomplete standard info" do
      parser.parse(readRelease('spec/metadata/musicbrainz/data/standardRelease_incomplete.xml'),
                   '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

      expect(parser.status).to eq('ok')
      expect(parser.md.discid).to eq('e50b3c11')
      expect(parser.md.artist).to eq('')
      expect(parser.md.album).to eq('Unknown')
      expect(parser.md.year).to eq('0')
      expect(parser.md.trackname(1)).to eq('Unknown title')
      expect(parser.md.trackname(2)).to eq('Something')
    end

    it "should pick the correct disc of a multi-disc release" do
      parser.parse(readRelease('spec/metadata/musicbrainz/data/multiDiscRelease.xml'),
                   '0gLvTHxPtWugkT0Pf26t5Bjo0GQ-', 'b20b140d')

      expect(parser.status).to eq('ok')
      expect(parser.md.discid).to eq('b20b140d')
      expect(parser.md.artist).to eq('The Beatles')
      expect(parser.md.album).to eq('The Beatles')
      expect(parser.md.year).to eq('2009')
      expect(parser.md.trackname(1)).to eq('Birthday')
      expect(parser.md.trackname(2)).to eq('Yer Blues')
    end

    it "should use the earliest release date is useEarliestDate is set" do
      allow(prefs).to receive(:useEarliestDate).and_return true
      parser.parse(readRelease('spec/metadata/musicbrainz/data/standardRelease.xml'),
                   '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

      expect(parser.status).to eq('ok')
      expect(parser.md.year).to eq('1969')
    end

    it "should not crash if set to use the earliest release date but data is incomplete" do
      allow(prefs).to receive(:useEarliestDate).and_return true
      parser.parse(readRelease('spec/metadata/musicbrainz/data/standardRelease_incomplete.xml'),
                   '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

      expect(parser.status).to eq('ok')
      expect(parser.md.year).to eq('0')
    end

    it "should never behave like a various artists disc if there is only one (non-Various Artists) album artist" do
      parser.parse(readRelease('spec/metadata/musicbrainz/data/oneAlbumArtist.xml'),
                   'cm9L.BbeuJ_zNOwr0C_e.K0.D0E-', '86099d0c')

      expect(parser.status).to eq('ok')
      expect(parser.md.artist).to eq('David Bowie')
      expect(parser.md.various?).to eq(false)
    end

    context "when guessing the genre" do
      it "should guess the most popular artist tag which is also an ID3 genre name" do
        expect(http).to receive(:get).with('/ws/2/artist/b10bbbfc-cf9e-42e0-be17-e2c3e1d2600d?inc=tags').and_return File.read('spec/metadata/musicbrainz/data/artistTags.xml')
        parser.parse(readRelease('spec/metadata/musicbrainz/data/multiDiscRelease.xml'),
                     '0gLvTHxPtWugkT0Pf26t5Bjo0GQ-', 'b20b140d')

        expect(parser.md.genre).to eq('Rock')
      end

      it "should prefer release-group tags for genre over artist tags" do
        expect(http).to receive(:get).with('/ws/2/release-group/9162580e-5df4-32de-80cc-f45a8d8a9b1d?inc=tags').and_return File.read('spec/metadata/musicbrainz/data/releaseGroupTags.xml')
        parser.parse(readRelease('spec/metadata/musicbrainz/data/standardRelease.xml'),
                     '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

        expect(parser.md.genre).to eq('Rock')
      end

      it "should leave the default genre (Unknown) if no good tag is found" do
        # By default we return no tags
        parser.parse(readRelease('spec/metadata/musicbrainz/data/oneAlbumArtist.xml'),
                     'cm9L.BbeuJ_zNOwr0C_e.K0.D0E-', '86099d0c')

        expect(parser.md.genre).to eq('Unknown')
      end

      it "should keep release metadata when the tag service returns a non-XML error" do
        allow(prefs).to receive(:debug).and_return false
        expect(http).to receive(:get)
          .with('/ws/2/release-group/9162580e-5df4-32de-80cc-f45a8d8a9b1d?inc=tags')
          .and_return('{"error": "The MusicBrainz web server is currently busy. Please try again later."}')

        parser.parse(readRelease('spec/metadata/musicbrainz/data/standardRelease.xml'),
                     '4vi.H1hC7BRP18_a.7D4r4NOYL8-', 'e50b3c11')

        expect(parser.status).to eq('ok')
        expect(parser.md.artist).to eq('The Beatles')
        expect(parser.md.album).to eq('Abbey Road')
        expect(parser.md.genre).to eq('Unknown')
      end

      it "should map certain non-ID3-genre tags to ID3 genres" do
        expect(http).to receive(:get).with('/ws/2/artist/7dbac7e6-f351-42da-9dce-b0249ca2dd03?inc=tags').and_return File.read('spec/metadata/musicbrainz/data/mapTags.xml')
        parser.parse(readRelease('spec/metadata/musicbrainz/data/splitRelease.xml'),
                     'a2njxz76PKV7jgnudcTXDbV_OQs-', '79098308')

        # NOTE: Also shows capitalization
        expect(parser.md.genre).to eq('Folk/Rock')
      end
    end

    context "when a various artists release is encountered" do
      it "should correctly know the artist for each track" do
        parser.parse(readRelease('spec/metadata/musicbrainz/data/variousArtists.xml'),
                     'c.J3z3pava1oPzXD0K2e9q48lJc-', 'c70ecd0f')

        expect(parser.status).to eq('ok')
        expect(parser.md.artist).to eq('Various Artists')
        expect(parser.md.various?).to eq(true)
        expect(parser.md.getVarArtist(4)).to eq('Bon Iver')
        expect(parser.md.getVarArtist(5)).to eq('Grizzly Bear')
        expect(parser.md.trackname(4)).to eq('Brackett, WI')
        expect(parser.md.trackname(5)).to eq('Deep Blue Sea')
      end

      it "should automatically join artist splits according to the joinphrase" do
        parser.parse(readRelease('spec/metadata/musicbrainz/data/variousArtists.xml'),
                     'c.J3z3pava1oPzXD0K2e9q48lJc-', 'c70ecd0f')

        expect(parser.md.getVarArtist(3)).to eq('Feist and Ben Gibbard')
      end

      it "should automatically join artist splits with ' / ' if there's no joinphrase" do
        parser.parse(readRelease('spec/metadata/musicbrainz/data/variousArtists.xml'),
                     'c.J3z3pava1oPzXD0K2e9q48lJc-', 'c70ecd0f')

        expect(parser.md.getVarArtist(14)).to eq('Grizzly Bear / Feist')
      end

      it "should rely on the track artists to pick the genre" do
        expect(http).to receive(:get).with('/ws/2/artist/1270af14-9c17-4400-8ebb-3f0ac40dcfb0?inc=tags').and_return File.read('spec/metadata/musicbrainz/data/artistTags.xml')
        parser.parse(readRelease('spec/metadata/musicbrainz/data/variousArtists.xml'),
                     'c.J3z3pava1oPzXD0K2e9q48lJc-', 'c70ecd0f')

        expect(parser.md.genre).to eq('Rock')
      end
    end

    context "When a split artist release is encountered" do
      it "should automatically join album artist splits according to the joinphrase" do
        parser.parse(readRelease('spec/metadata/musicbrainz/data/splitReleaseOneArtist.xml'),
                     '7K8x8VRn_7QehSNMqHrzDhjZV_k-', 'b10df50d')

        expect(parser.status).to eq('ok')
        expect(parser.md.artist).to eq('Iron & Wine and Calexico')
      end

      it "should automatically join album artist splits with ' / ' if there's no joinphrase" do
        parser.parse(readRelease('spec/metadata/musicbrainz/data/splitRelease.xml'),
                     'a2njxz76PKV7jgnudcTXDbV_OQs-', '79098308')

        expect(parser.status).to eq('ok')
        # NOTE: also relies on name-credit rather than artist/name
        expect(parser.md.artist).to eq('Son, Ambulance / Bright Eyes')
      end

      it "should behave like a various artists disc" do
        parser.parse(readRelease('spec/metadata/musicbrainz/data/splitRelease.xml'),
                     'a2njxz76PKV7jgnudcTXDbV_OQs-', '79098308')

        expect(parser.md.various?).to eq(true)
        expect(parser.md.getVarArtist(3)).to eq('Son Ambulance')
        expect(parser.md.getVarArtist(4)).to eq('Bright Eyes')
        expect(parser.md.trackname(3)).to eq('The Invention of Beauty')
        expect(parser.md.trackname(4)).to eq('Oh, You Are the Roots That Sleep Beneath My Feet and Hold the Earth in Place')
      end

      it "should never behave like a various artists disc if all tracks have the same artist" do
        parser.parse(readRelease('spec/metadata/musicbrainz/data/splitReleaseOneArtist.xml'),
                     '7K8x8VRn_7QehSNMqHrzDhjZV_k-', 'b10df50d')

        expect(parser.md.various?).to eq(false)
      end

      it "should rely on the album artists to pick the genre" do
        expect(http).to receive(:get).with('/ws/2/artist/5e372a49-5672-4fb8-ba14-18c90780c4f9?inc=tags').and_return File.read('spec/metadata/musicbrainz/data/artistTags.xml')
        parser.parse(readRelease('spec/metadata/musicbrainz/data/splitReleaseOneArtist.xml'),
                     '7K8x8VRn_7QehSNMqHrzDhjZV_k-', 'b10df50d')

        expect(parser.md.genre).to eq('Rock')
      end
    end
  end
end
