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

require 'rubygems/version'

class Rubyripper
  VERSION = '0.9.1'
  PROJECT_URL = 'https://github.com/happyoutkast-commits/rubyripper-modernized'
  MINIMUM_RUBY_VERSION = '3.2.0'

  def self.supported_ruby?(version)
    Gem::Version.new(version) >= Gem::Version.new(MINIMUM_RUBY_VERSION)
  rescue ArgumentError, TypeError
    false
  end
end
