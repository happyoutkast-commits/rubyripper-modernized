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

# GtkFileExists asks how to handle exact output-file collisions.
class GtkFileExists
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display

  def initialize(gui, rubyripper, filenames)
    @label = Gtk::Label.new(message(filenames))
    @label.wrap = true
    @label.selectable = true
    @image = Gtk::Image.new(:stock => Gtk::Stock::DIALOG_QUESTION, :size => Gtk::IconSize::DIALOG)

    @infobox = Gtk::Box.new(:horizontal)
    @infobox.add(@image)
    @infobox.add(@label)
    @separator = Gtk::Separator.new(:horizontal)

    @buttons = [Gtk::Button.new, Gtk::Button.new, Gtk::Button.new]
    @labels = [
      Gtk::Label.new(_("Cancel rip")),
      Gtk::Label.new(_("Overwrite conflicting\nfile(s)")),
      Gtk::Label.new(_("Auto rename new\nfile(s)"))
    ]
    @images = [
      Gtk::Image.new(:stock => Gtk::Stock::CANCEL, :size => Gtk::IconSize::LARGE_TOOLBAR),
      Gtk::Image.new(:stock => Gtk::Stock::CLEAR, :size => Gtk::IconSize::LARGE_TOOLBAR),
      Gtk::Image.new(:stock => Gtk::Stock::OK, :size => Gtk::IconSize::LARGE_TOOLBAR)
    ]
    @hboxes = [Gtk::Box.new(:horizontal), Gtk::Box.new(:horizontal), Gtk::Box.new(:horizontal)]
    @buttonbox = Gtk::Box.new(:horizontal)

    3.times do |index|
      @hboxes[index].pack_start(@images[index], :expand => false, :fill => false)
      @hboxes[index].pack_start(@labels[index], :expand => false, :fill => false)
      @buttons[index].add(@hboxes[index])
      @buttonbox.pack_start(@buttons[index], :expand => false, :fill => false, :padding => 10)
    end

    @buttons[0].signal_connect("released") { gui.showDisc() }
    @buttons[1].signal_connect("released") do
      rubyripper.overwriteFiles()
      gui.continueRip()
    end
    @buttons[2].signal_connect("released") do
      rubyripper.postfixFiles()
      gui.continueRip()
    end

    @vbox = Gtk::Box.new(:vertical)
    @vbox.border_width = 10
    [@infobox, @separator, @buttonbox].each do |object|
      @vbox.pack_start(object, :expand => false, :fill => false, :padding => 10)
    end

    @display = Gtk::Frame.new(_("Output file already exists"))
    @display.set_shadow_type(Gtk::ShadowType::ETCHED_IN)
    @display.border_width = 5
    @display.add(@vbox)
  end

  private

  def message(filenames)
    shown = filenames.first(5)
    paths = shown.join("\n")
    paths += _("\n…and %s more.") % [filenames.length - shown.length] if filenames.length > shown.length

    if filenames.length == 1
      _("The following output file already exists:\n\n%s\n\nWhat should Rubyripper do?") % [paths]
    else
      _("%s output files already exist:\n\n%s\n\nWhat should Rubyripper do?") %
        [filenames.length, paths]
    end
  end
end
