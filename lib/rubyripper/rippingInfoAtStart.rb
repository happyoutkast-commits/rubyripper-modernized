#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010  Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/preferences/main'
require 'rubyripper/system/execute'
require 'rubyripper/modules/audioCalculations'
require 'rubyripper/version'

class RippingInfoAtStart
  include AudioCalculations
  include GetText
  GetText.bindtextdomain("rubyripper")
  
  def initialize(disc, log, trackSelection, prefs=nil, execute=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @disc = disc
    @log = log
    @tracks = trackSelection.length
    @md = disc.metadata
    @execute = execute ? execute : Execute.new()
    @logString = String.new
  end

  def show
    showVersion()
    showBasicRipInfo()
    showRippingPrefs()
    showEncodingPrefs()
    showDiscInfo()
    updateInterface()
  end

private

  def showVersion
    # Keep release information in one place. This prevents the logfile from
    # retaining an old version or project URL when a new release is prepared.
    @logString << _("Rubyripper version %s") % [Rubyripper::VERSION]
    @logString << _("\nWebsite:") + " #{Rubyripper::PROJECT_URL}\n\n"
  end

  def showBasicRipInfo
    # Execute returns command output as an array of lines. The logfile only
    # needs the first line, without terminal newline characters.
    rip_date = @execute.launch("date").first.to_s.strip

    @logString << _("Rubyripper extraction logfile from:\n%s\n\n") % [rip_date]
    @logString << "%s / %s\n\n" % [@md.artist, @md.album]
  end

  def showRippingPrefs
    @logString << _("Used drive") + '     : ' + @disc.devicename + '   '
    @logString << _("Device") + ': ' + @prefs.cdrom + "\n\n"
    
    @logString << _("Used ripper") + '    : ' + version('cdparanoia') + "\n"
    @logString << _("Selected options") + ' : ' + @prefs.rippersettings + "\n\n"
    
    @logString << _("Matches required for all chunks") + '       : ' + "#{@prefs.reqMatchesAll}\n"
    @logString << _("Matches required for erroneous chunks") + ' : ' + "#{@prefs.reqMatchesErrors}\n\n"

    @logString << _("Read offset correction") + '                      : ' + "#{@prefs.offset}\n"
    @logString << _("Overread into Lead-In and Lead-Out") + '          : ' + _("No") + "\n"
    @logString << _("Fill up missing offset samples with silence : %s\n") % [@prefs.padMissingSamples ? _("Yes") : _("No")]
    @logString << _("Null samples used in CRC calculations") + '       : ' + _("Yes") + "\n\n"
  end

  def showEncodingPrefs
    printEncoder('flac', @prefs.settingsFlac) if @prefs.flac
    printEncoder('oggenc', @prefs.settingsVorbis) if @prefs.vorbis
    printEncoder('lame', @prefs.settingsMp3) if @prefs.mp3

    if @prefs.wav
      @logString << _("Used output encoder : %s\n") % [_("Internal WAVE routines")]
      @logString << _("Sample format") + "       : 44,100 Hz; 16 Bit; Stereo\n\n"
    end
    if @prefs.other
      @logString << _("Used output encoder : %s\n") % [_("User defined encoder")]
      @logString << _("Command line") + "        : %s\n\n" % [@prefs.settingsOther]
    end
  end
  
  def printEncoder(executable, flags)
    @logString << _("Used output encoder : %s\n") % [version(executable)]
    @logString << _("Selected options") + "      : %s\n\n" % [flags]
  end

  def version(name)
    @execute.launch("#{name} --version")[0].strip()
  end

  def showDiscInfo
    @logString << _("TOC of the extracted CD\n\n")
    
    @logString << "     " + _("Track") + " |   " + _("Start") + "  |  "
    @logString << _("Length") + "  | " + _("Start sector") + " | " + _("End sector") + " \n"
    @logString << "    ---------------------------------------------------------\n"

    (1..@disc.audiotracks).each do |track|
      # TODO: Needs start sector of data tracks too.
      start = @disc.getStartSector(track)    
      length = @disc.getLengthSector(track)
      
      @logString << "       %2d  | %s | %s |    %6d    |   %6d   \n" % [track, toTime(start), toTime(length), start, start + length - 1]
    end
    @logString << "\n"
  end
  
  def updateInterface
    @log << @logString
    @logString = nil
  end
end
