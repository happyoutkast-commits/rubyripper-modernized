#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software:
#    you can redistribute it and/or modify it under the terms of
#    the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

require File.expand_path('../../bin/rubyripper_gtk3', __dir__)

describe GraphicalUserInterface do
  let(:preferences) { double('Preferences') }
  let(:short_message) { double('ShortMessage') }
  let(:dependencies) { double('Dependencies') }
  let(:interface) do
    described_class.new(preferences, short_message, dependencies)
  end

  it 'waits for the user to request the first disc scan' do
    window = double('Window')
    interface.instance_variable_set(:@gtkWindow, window)

    expect(preferences).to receive(:load)
    expect(interface).to receive(:prepareMainWindow)
    expect(interface).to receive(:setupMainContainer)
    expect(interface).to receive(:showWelcomeMessage)
    expect(window).to receive(:show_all)
    expect(interface).to receive(:enableIdleControls)
    expect(interface).not_to receive(:scanDisc)
    expect(Gtk).to receive(:main)

    interface.start
  end

  it 'keeps ripping disabled while the interface is idle' do
    buttons = Array.new(5) { double('Button') }
    interface.instance_variable_set(:@buttons, buttons)

    buttons[0..2].each do |button|
      expect(button).to receive(:sensitive=).with(true)
    end
    expect(buttons[3]).to receive(:sensitive=).with(false)
    expect(buttons[4]).to receive(:sensitive=).with(true)

    interface.send(:enableIdleControls)
  end

  it 'returns from Preferences without starting a disc scan' do
    buttons = Array.new(5) { double('Button') }
    interface.instance_variable_set(:@buttons, buttons)
    interface.instance_variable_set(:@currentInstance, 'GtkPreferences')

    buttons.each do |button|
      expect(button).to receive(:sensitive=).with(false)
    end
    expect(interface).to receive(:showWelcomeMessage)
    expect(interface).to receive(:enableIdleControls)
    expect(interface).not_to receive(:refreshDisc)

    interface.send(:showDiscOrPreferences)
  end
end
