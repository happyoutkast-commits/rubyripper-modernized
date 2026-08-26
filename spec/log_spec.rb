#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'rubyripper/log'

describe Log do
  let(:disc) { double('Disc', :metadata => double('Metadata')) }
  let(:file_scheme) { double('FileScheme') }
  let(:user_interface) { double('UserInterface') }
  let(:file_and_dir) { double('FileAndDir') }
  let(:prefs) { double('Preferences', :codecs => ['flac', 'wav']) }

  let(:log) do
    described_class.new(
      disc,
      file_scheme,
      user_interface,
      {},
      prefs,
      file_and_dir
    )
  end

  before(:each) do
    allow(file_and_dir).to receive(:createDirForFile)
    allow(File).to receive(:open).and_return(double('Logfile'))
  end

  it 'opens a fresh shared logfile only once' do
    shared_logfile = '/music/Tool/Lateralus/ripping.log'
    allow(file_scheme).to receive(:getLogFile).and_return(shared_logfile)

    log.createLog

    expect(file_and_dir).to have_received(:createDirForFile)
      .once.with(shared_logfile)
    expect(File).to have_received(:open).once.with(shared_logfile, 'w')
  end

  it 'opens separate logfiles when codecs use separate directories' do
    allow(file_scheme).to receive(:getLogFile) do |codec|
      "/music/Tool/Lateralus/#{codec}/ripping.log"
    end

    log.createLog

    expect(File).to have_received(:open)
      .once.with('/music/Tool/Lateralus/flac/ripping.log', 'w')
    expect(File).to have_received(:open)
      .once.with('/music/Tool/Lateralus/wav/ripping.log', 'w')
  end
end
