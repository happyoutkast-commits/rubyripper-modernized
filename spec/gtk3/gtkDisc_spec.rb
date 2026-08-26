#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'rubyripper/gtk3/gtkDisc'

describe GtkDisc do
  let(:gtk_disc) { described_class.allocate }

  it 'shows the provider that supplied the metadata' do
    metadata = double(
      'Metadata',
      :metadata_source => 'musicbrainz',
      :metadata_fallback? => false
    )
    gtk_disc.instance_variable_set(:@md, metadata)

    expect(gtk_disc.send(:metadata_source_text)).to eq('MusicBrainz')
  end

  it 'shows when metadata came from a fallback provider' do
    metadata = double(
      'Metadata',
      :metadata_source => 'gnudb',
      :preferred_metadata_source => 'musicbrainz',
      :metadata_fallback? => true
    )
    gtk_disc.instance_variable_set(:@md, metadata)

    expect(gtk_disc.send(:metadata_source_text)).to eq(
      'GnuDB (fallback from MusicBrainz)'
    )
  end
end
