#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software:
#    you can redistribute it and/or modify it under the terms of
#    the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

require 'rubyripper/base'
require 'rubyripper/gtk3/gtkShortMessage'

describe ShortMessage do
  it 'invites the user to scan or review preferences on startup' do
    display = double('Display')
    message = described_class.allocate
    message.instance_variable_set(:@display, display)

    expected_text =
      "Welcome to rubyripper #{Rubyripper::VERSION}.\n\n" \
      "Insert a disc and press 'Scan drive' to scan it in preparation for ripping.\n\n" \
      "Alternatively, open 'Preferences' to choose your preferred options first."

    expect(display).to receive(:text=).with(expected_text)
    message.welcome
  end
end
