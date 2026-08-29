#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'rubyripper/secureRip'
require 'fileutils'
require 'tmpdir'

describe SecureRip do
  AUDIO_SECTOR_BYTES = AudioCalculations::BYTES_AUDIO_FRAME
  WAVE_HEADER_BYTES = AudioCalculations::BYTES_WAV_CONTAINER

  let(:required_matches_all) { 1 }
  let(:required_matches_errors) { 1 }
  let(:maximum_trials) { 0 }
  let(:prefs) do
    double(
      'Preferences',
      :reqMatchesAll => required_matches_all,
      :reqMatchesErrors => required_matches_errors,
      :maxTries => maximum_trials
    )
  end
  let(:log) { double('Log').as_null_object }
  let(:disc) do
    # Unresolved sectors are reported with the track size and sector count.
    # Individual file-comparison tests replace getFileSize when needed.
    double(
      'Disc',
      :getFileSize => WAVE_HEADER_BYTES + AUDIO_SECTOR_BYTES,
      :getLengthSector => 1
    )
  end
  let(:file_scheme) { double('FileScheme') }
  let(:secure_rip) do
    described_class.new(
      [],
      disc,
      file_scheme,
      log,
      double('Encoding'),
      double('Dependencies'),
      double('Execute'),
      prefs
    )
  end

  around do |example|
    # Real temporary WAVE-shaped files keep these tests close to the data that
    # SecureRip reads while avoiding a CD drive or external ripper process.
    @temporary_directory = Dir.mktmpdir('rubyripper-secure-rip-spec')
    example.run
  ensure
    FileUtils.remove_entry(@temporary_directory) if @temporary_directory
  end

  def audio_sector(value)
    value * AUDIO_SECTOR_BYTES
  end

  def trial_filename(trial)
    File.join(@temporary_directory, "trial-#{trial}.wav")
  end

  def prepare_trials(*trials)
    allow(file_scheme).to receive(:getTempFile) do |_track, trial|
      trial_filename(trial)
    end

    trials.each_with_index do |sectors, index|
      # SecureRip skips the standard WAVE header before comparing CD sectors.
      wave_data = ("\0" * WAVE_HEADER_BYTES) + sectors.join
      File.binwrite(trial_filename(index + 1), wave_data)
    end

    audio_bytes = trials.first.sum(&:bytesize)
    allow(disc).to receive(:getFileSize)
      .and_return(WAVE_HEADER_BYTES + audio_bytes)
    secure_rip.instance_variable_set(:@errors, {})
  end

  def compare_prepared_trials
    secure_rip.compareSectors(1)
    secure_rip.instance_variable_get(:@errors)
  end

  def read_trial_sector(trial, sector_index = 0)
    File.binread(
      trial_filename(trial),
      AUDIO_SECTOR_BYTES,
      WAVE_HEADER_BYTES + (sector_index * AUDIO_SECTOR_BYTES)
    )
  end

  context 'when identifying mismatched sectors' do
    context 'with two initial trials' do
      let(:required_matches_all) { 2 }

      it 'retains a sector that differs between the two reads' do
        sector_a = audio_sector('A')
        sector_b = audio_sector('B')
        prepare_trials([sector_a], [sector_b])

        expect(compare_prepared_trials.keys).to eq([0])
      end
    end

    context 'with three initial trials' do
      let(:required_matches_all) { 3 }

      it 'ignores sectors that are identical in every trial' do
        matching_sector = audio_sector('A')
        prepare_trials(
          [matching_sector],
          [matching_sector],
          [matching_sector]
        )

        expect(compare_prepared_trials).to be_empty
      end

      it 'records only sectors that differ from the first trial' do
        sector_a = audio_sector('A')
        sector_b = audio_sector('B')
        sector_c = audio_sector('C')
        prepare_trials(
          [sector_a, sector_a, sector_a],
          [sector_b, sector_a, sector_c],
          [sector_b, sector_a, sector_c]
        )

        expect(compare_prepared_trials.keys.sort)
          .to eq([0, 2 * AUDIO_SECTOR_BYTES])
      end
    end
  end

  context 'when choosing the repeated sector data' do
    let(:required_matches_all) { 3 }
    let(:required_matches_errors) { 2 }

    it 'keeps trial 1 when another trial agrees with it' do
      sector_a = audio_sector('A')
      sector_b = audio_sector('B')
      prepare_trials([sector_a], [sector_a], [sector_b])

      compare_prepared_trials
      secure_rip.correctErrorPos(1)

      expect(read_trial_sector(1)).to eq(sector_a)
      expect(secure_rip.instance_variable_get(:@errors)).to be_empty
    end

    it 'replaces trial 1 when the later trials agree with each other' do
      sector_a = audio_sector('A')
      sector_b = audio_sector('B')
      prepare_trials([sector_a], [sector_b], [sector_b])

      compare_prepared_trials
      secure_rip.correctErrorPos(1)

      expect(read_trial_sector(1)).to eq(sector_b)
      expect(secure_rip.instance_variable_get(:@errors)).to be_empty
    end

    it 'leaves a three-way disagreement unresolved until another read agrees' do
      sector_a = audio_sector('A')
      sector_b = audio_sector('B')
      sector_c = audio_sector('C')
      prepare_trials([sector_a], [sector_b], [sector_c])

      errors = compare_prepared_trials
      secure_rip.correctErrorPos(1)
      expect(errors.keys).to eq([0])

      # A fourth read matching trial 2 gives B the required two votes.
      errors[0] << sector_b
      secure_rip.correctErrorPos(1)

      expect(read_trial_sector(1)).to eq(sector_b)
      expect(errors).to be_empty
    end
  end

  context 'when scheduling extra trials' do
    before do
      allow(secure_rip).to receive(:doNewTrial) do
        current_trial = secure_rip.instance_variable_get(:@trial)
        secure_rip.instance_variable_set(:@trial, current_trial + 1)
        true
      end
      allow(secure_rip).to receive(:analyzeFiles) do
        secure_rip.instance_variable_set(:@errors, { 0 => ['mismatch'] })
        secure_rip.instance_variable_set(:@crcs, ['TRIALCRC'])
        secure_rip.instance_variable_set(:@peakLevel, 100.0)
        secure_rip.instance_variable_set(:@digest, 'trial-one-md5')
      end
      allow(secure_rip).to receive(:readErrorPos)
      allow(secure_rip).to receive(:getCRC).and_return('CORRECTEDCRC')
    end

    context 'with four matches required for mismatched sectors' do
      let(:required_matches_all) { 3 }
      let(:required_matches_errors) { 4 }

      it 'attempts correction as soon as trial 4 has been read' do
        expect(secure_rip).to receive(:correctErrorPos).once do
          secure_rip.instance_variable_get(:@errors).clear
        end

        secure_rip.instance_variable_set(:@trial, 0)
        secure_rip.main(1)

        expect(secure_rip.instance_variable_get(:@trial)).to eq(4)
      end
    end

    context 'with a maximum of four trials' do
      let(:required_matches_all) { 3 }
      let(:required_matches_errors) { 99 }
      let(:maximum_trials) { 4 }

      it 'never starts a fifth trial' do
        allow(secure_rip).to receive(:correctErrorPos)

        secure_rip.instance_variable_set(:@trial, 0)
        secure_rip.main(1)

        expect(secure_rip.instance_variable_get(:@trial)).to eq(4)
      end
    end
  end

  it 'keeps the MD5 digest for trial 1 after calculating later CRCs' do
    trial_one_hash = double(
      'TrialOneHash',
      :md5 => 'trial-one-md5',
      :crc32 => 'CRC1'
    )
    trial_two_hash = double(
      'TrialTwoHash',
      :md5 => 'trial-two-md5',
      :crc32 => 'CRC2'
    )
    allow(trial_one_hash).to receive(:calculate)
    allow(trial_two_hash).to receive(:calculate)
    allow(FileHash).to receive(:new)
      .with('trial-1.wav').and_return(trial_one_hash)
    allow(FileHash).to receive(:new)
      .with('trial-2.wav').and_return(trial_two_hash)
    allow(file_scheme).to receive(:getTempFile)
      .with(1, 1).and_return('trial-1.wav')
    allow(file_scheme).to receive(:getTempFile)
      .with(1, 2).and_return('trial-2.wav')
    peak_calculator = double('PeakCalculator', :getPeakLevel => 100.0)
    secure_rip.instance_variable_set(:@calcPeakLevel, peak_calculator)

    secure_rip.getCRC(1, 1)
    secure_rip.getCRC(1, 2)

    expect(secure_rip.instance_variable_get(:@digest)).to eq('trial-one-md5')
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
