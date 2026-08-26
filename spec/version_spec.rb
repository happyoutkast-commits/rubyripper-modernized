#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <http://www.gnu.org/licenses/>.

require 'rubyripper/version'

describe Rubyripper do
  it 'defines the current application version' do
    expect(described_class::VERSION).to eq('0.8.0rc4')
  end

  it 'defines the current project URL' do
    expect(described_class::PROJECT_URL).to eq('https://github.com/bleskodev/rubyripper')
  end

  it 'rejects Ruby versions below the supported baseline' do
    expect(described_class.supported_ruby?('3.1.9')).to eq(false)
  end

  it 'accepts the minimum supported Ruby version' do
    expect(described_class.supported_ruby?('3.2.0')).to eq(true)
  end

  it 'accepts newer Ruby versions without relying on digit positions' do
    expect(described_class.supported_ruby?('3.10.0')).to eq(true)
    expect(described_class.supported_ruby?('4.0.0')).to eq(true)
  end

  it 'rejects malformed Ruby version strings' do
    expect(described_class.supported_ruby?('not-a-version')).to eq(false)
  end
end
