#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'rubyripper/secureRip'

describe SecureRip do
  let(:prefs) do
    double(
      'Preferences',
      :reqMatchesAll => 1,
      :reqMatchesErrors => 1,
      :maxTries => 0
    )
  end
  let(:log) { double('Log').as_null_object }
  let(:secure_rip) do
    described_class.new(
      [],
      double('Disc'),
      double('FileScheme'),
      log,
      double('Encoding'),
      double('Dependencies'),
      double('Execute'),
      prefs
    )
  end

  it 'does not carry a corrected CRC into the next track' do
    analysis_number = 0

    allow(secure_rip).to receive(:doNewTrial) do
      trial = secure_rip.instance_variable_get(:@trial) + 1
      secure_rip.instance_variable_set(:@trial, trial)
      true
    end

    allow(secure_rip).to receive(:analyzeFiles) do
      analysis_number += 1
      errors = analysis_number == 1 ? { 0 => ['mismatch'] } : {}
      secure_rip.instance_variable_set(:@errors, errors)
      secure_rip.instance_variable_set(:@crcs, ['TRIALCRC'])
      secure_rip.instance_variable_set(:@peakLevel, 100.0)
      secure_rip.instance_variable_set(:@digest, 'md5')
    end

    allow(secure_rip).to receive(:readErrorPos)
    allow(secure_rip).to receive(:correctErrorPos) do
      secure_rip.instance_variable_get(:@errors).clear
    end
    allow(secure_rip).to receive(:getCRC).and_return('CORRECTEDCRC')

    expect(log).to receive(:finishTrack)
      .with(100.0, ['TRIALCRC'], 'Copy OK', 'CORRECTEDCRC').ordered
    expect(log).to receive(:finishTrack)
      .with(100.0, ['TRIALCRC'], 'Copy OK', nil).ordered

    secure_rip.instance_variable_set(:@trial, 0)
    secure_rip.main(12)

    secure_rip.instance_variable_set(:@trial, 0)
    secure_rip.main(13)
  end
end
