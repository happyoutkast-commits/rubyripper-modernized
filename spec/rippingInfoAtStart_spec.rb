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
end
