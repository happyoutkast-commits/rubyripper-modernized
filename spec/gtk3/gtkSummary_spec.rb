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

require 'rubyripper/gtk3/gtkSummary'

describe GtkSummary do
  let(:summary) { GtkSummary.allocate }
  let(:deps) { double('Dependency') }
  let(:prefs) { double('Preferences', :filemanager => 'dolphin') }

  before(:each) do
    summary.instance_variable_set(:@deps, deps)
    summary.instance_variable_set(:@prefs, prefs)
  end

  it 'uses xdg-open once for each unique output directory' do
    allow(deps).to receive(:installed?).with('xdg-open').and_return(true)

    commands = summary.send(
      :commandsFor,
      ['/music/Tool/Lateralus', '/music/Tool/Lateralus', '/music/Tool/WAV files'],
      prefs.filemanager
    )

    expect(commands).to eq(
      [
        ['xdg-open', '/music/Tool/Lateralus'],
        ['xdg-open', '/music/Tool/WAV files']
      ]
    )
  end

  it 'falls back to the configured application when xdg-open is unavailable' do
    allow(deps).to receive(:installed?).with('xdg-open').and_return(false)

    commands = summary.send(:commandsFor, ['/music/Tool/Lateralus'], prefs.filemanager)

    expect(commands).to eq([['dolphin', '/music/Tool/Lateralus']])
  end

  it 'launches the desktop opener without the PTY command wrapper' do
    allow(deps).to receive(:installed?).with('xdg-open').and_return(true)
    allow(Process).to receive(:spawn).and_return(4321)
    allow(Process).to receive(:detach)

    summary.send(:launchPaths, ['/music/Tool/WAV files'], prefs.filemanager)

    expect(Process).to have_received(:spawn).with('xdg-open', '/music/Tool/WAV files')
    expect(Process).to have_received(:detach).with(4321)
  end
end
