#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'rubyripper/rippingInfoAtStart'

describe RippingInfoAtStart do
  it 'uses the central release identity in the logfile header' do
    ripping_info = described_class.allocate
    ripping_info.instance_variable_set(:@logString, String.new)

    ripping_info.send(:showVersion)

    expect(ripping_info.instance_variable_get(:@logString)).to eq(
      "Rubyripper version #{Rubyripper::VERSION}\n" \
      "Website: #{Rubyripper::PROJECT_URL}\n\n"
    )
  end

  it 'prints the rip date without command-output formatting' do
    ripping_info = described_class.allocate
    ripping_info.instance_variable_set(:@logString, String.new)
    ripping_info.instance_variable_set(
      :@md,
      double(
        'Metadata',
        :artist => 'Tool',
        :album => 'Lateralus',
        :metadata_source_description => 'MusicBrainz'
      )
    )
    ripping_info.instance_variable_set(
      :@execute,
      double('Execute', :launch => ["Wed Aug 26 08:13:58 AM PDT 2026\r\n"])
    )

    ripping_info.send(:showBasicRipInfo)

    expect(ripping_info.instance_variable_get(:@logString)).to eq(
      "Rubyripper extraction logfile from:\n" \
      "Wed Aug 26 08:13:58 AM PDT 2026\n\n" \
      "Tool / Lateralus\n\n" \
      "Metadata source: MusicBrainz\n\n"
    )
  end
end
