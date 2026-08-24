#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2013 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/fileScheme'

describe FileScheme do
  let(:file) { double('FileAndDir') }
  let(:prefs) { double('Preferences', :codecs => ['flac'], :image => false) }
  let(:scheme) { FileScheme.allocate }

  before(:each) do
    scheme.instance_variable_set(:@file, file)
    scheme.instance_variable_set(:@prefs, prefs)
    scheme.instance_variable_set(:@trackSelection, [2, 3])
    scheme.instance_variable_set(:@dir, {'flac' => '/music/Tool/Lateralus'})
    scheme.instance_variable_set(
      :@files,
      {'flac' => {2 => '02 - Eon Blue Apocalypse.flac', 3 => '03 - The Patient.flac'}}
    )
    scheme.instance_variable_set(:@image, {})
  end

  it 'allows an existing album directory when selected output files are new' do
    expect(file).to receive(:exist?)
      .with('/music/Tool/Lateralus/02 - Eon Blue Apocalypse.flac')
      .and_return(false)
    expect(file).to receive(:exist?)
      .with('/music/Tool/Lateralus/03 - The Patient.flac')
      .and_return(false)

    expect(scheme.conflictingFiles).to eq([])
  end

  it 'returns only exact selected output files that already exist' do
    allow(file).to receive(:exist?) do |path|
      path.end_with?('02 - Eon Blue Apocalypse.flac')
    end

    expect(scheme.conflictingFiles).to eq(
      ['/music/Tool/Lateralus/02 - Eon Blue Apocalypse.flac']
    )
  end

  it 'overwrites only conflicting files and never removes the album directory' do
    allow(file).to receive(:exist?) do |path|
      path.end_with?('02 - Eon Blue Apocalypse.flac')
    end
    expect(file).to receive(:removeFile)
      .with('/music/Tool/Lateralus/02 - Eon Blue Apocalypse.flac')
    expect(file).not_to receive(:removeDir)
    expect(file).not_to receive(:remove)

    scheme.overwriteFiles
  end

  it 'auto-renames only conflicting output files' do
    existing = [
      '/music/Tool/Lateralus/02 - Eon Blue Apocalypse.flac',
      '/music/Tool/Lateralus/02 - Eon Blue Apocalypse #1.flac'
    ]
    allow(file).to receive(:exist?) { |path| existing.include?(path) }

    scheme.postfixFiles

    expect(scheme.getFile('flac', 2)).to eq(
      '/music/Tool/Lateralus/02 - Eon Blue Apocalypse #2.flac'
    )
    expect(scheme.getFile('flac', 3)).to eq(
      '/music/Tool/Lateralus/03 - The Patient.flac'
    )
  end
end
