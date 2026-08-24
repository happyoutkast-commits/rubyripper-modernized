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

require 'rubyripper/disc/permissionDrive'
require 'rubyripper/errors'

describe PermissionDrive do
  let(:prefs) {double('Preferences', :testdisc => false)}
  let(:deps) {double('Dependency', :platform => 'linux')}
  let(:permissions) {PermissionDrive.new(prefs, deps)}

  before(:each) do
    allow(File).to receive(:symlink?).and_return(false)
  end

  it "reports a helpful error when no optical drive is detected" do
    expect(File).to receive(:blockdev?).with('unknown').and_return(false)
    expect(File).not_to receive(:readable?)
    expect(File).not_to receive(:writable?)

    expect(permissions.problems?('unknown')).to eq(true)
    expect(permissions.error).to eq([:noOpticalDrive])
    expect(Errors.noOpticalDrive).to eq(
      "Error: No optical drive was detected.\n" \
      "Make sure the drive is connected and powered on, then try again."
    )
  end

  it "keeps the configured path when the device doesn't exist" do
    expect(File).to receive(:blockdev?).with('/dev/missing').and_return(false)
    expect(File).not_to receive(:readable?)
    expect(File).not_to receive(:writable?)

    expect(permissions.problems?('/dev/missing')).to eq(true)
    expect(permissions.error).to eq([:unknownDrive, '/dev/missing'])
  end

  it "keeps the read-permission error without replacing it" do
    allow(File).to receive(:blockdev?).with('/dev/sr0').and_return(true)
    expect(File).to receive(:readable?).with('/dev/sr0').and_return(false)
    expect(File).not_to receive(:writable?)

    expect(permissions.problems?('/dev/sr0')).to eq(true)
    expect(permissions.error).to eq([:noReadPermissionsForDrive, '/dev/sr0'])
  end

  it "reports a write-permission error for a readable drive" do
    allow(File).to receive(:blockdev?).with('/dev/sr0').and_return(true)
    allow(File).to receive(:readable?).with('/dev/sr0').and_return(true)
    expect(File).to receive(:writable?).with('/dev/sr0').and_return(false)

    expect(permissions.problems?('/dev/sr0')).to eq(true)
    expect(permissions.error).to eq([:noWritePermissionsForDrive, '/dev/sr0'])
  end

  it "clears an earlier error before checking the drive again" do
    allow(File).to receive(:blockdev?).with('/dev/sr0').and_return(false, true)
    allow(File).to receive(:readable?).with('/dev/sr0').and_return(true)
    allow(File).to receive(:writable?).with('/dev/sr0').and_return(true)

    expect(permissions.problems?('/dev/sr0')).to eq(true)
    expect(permissions.problems?('/dev/sr0')).to eq(false)
    expect(permissions.error).to eq(nil)
  end
end
