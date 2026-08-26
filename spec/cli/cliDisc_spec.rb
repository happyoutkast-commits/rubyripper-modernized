#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'stringio'
require 'rubyripper/cli/cliDisc'

describe CliDisc do
  it 'shows the provider that supplied the displayed metadata' do
    output = StringIO.new
    metadata = double(
      'Metadata',
      :artist => 'Tool',
      :album => 'Lateralus',
      :genre => 'Progressive Rock',
      :year => '2001',
      :extraDiscInfo => '',
      :various? => false,
      :metadata_source_description => 'MusicBrainz'
    )
    cli_disc = described_class.allocate
    cli_disc.instance_variable_set(:@out, output)
    cli_disc.instance_variable_set(:@md, metadata)

    cli_disc.send(:showDiscInfo)

    expect(output.string).to include("Metadata source: MusicBrainz\n")
  end

  it 'shows when the metadata came from a fallback provider' do
    output = StringIO.new
    metadata = double(
      'Metadata',
      :artist => 'Tool',
      :album => 'Lateralus',
      :genre => 'Progressive Rock',
      :year => '2001',
      :extraDiscInfo => '',
      :various? => false,
      :metadata_source_description => 'GnuDB (fallback from MusicBrainz)'
    )
    cli_disc = described_class.allocate
    cli_disc.instance_variable_set(:@out, output)
    cli_disc.instance_variable_set(:@md, metadata)

    cli_disc.send(:showDiscInfo)

    expect(output.string).to include(
      "Metadata source: GnuDB (fallback from MusicBrainz)\n"
    )
  end
end
