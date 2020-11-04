#!/usr/bin/ruby

require "fileutils"
require "date"

GPL2_HEADER = "# This file is a part of Redmine Resources (redmine_resources) plugin,
# resource allocation and management for Redmine
#
# Copyright (C) 2011-#{Date.today.year} RedmineUP
# http://www.redmineup.com/
#
# redmine_resources is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_resources is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_resources.  If not, see <http://www.gnu.org/licenses/>.

".freeze

PROPRIETARY_HEADER = "/*
This file is a part of Redmine Resources (redmine_resources) plugin,
resource allocation and management for Redmine

Copyright (C) 2011-#{Date.today.year} RedmineUP
http://www.redmineup.com/

This file is covering by RedmineUP Proprietary Use License as any images,
cascading stylesheets, manuals and JavaScript files in any extensions
produced and/or distributed by redmineup.com. These files are copyrighted by
redmineup.com (RedmineUP) and cannot be redistributed in any form
without prior consent from redmineup.com (RedmineUP)

*/
".freeze

def pro_version(text)
  text.force_encoding('utf-8') if text.respond_to?(:force_encoding)
  without_lht = text.gsub(/(\s*(#|<!\-\-|\/\/)[ ]*<[\/]?PRO>[^\n\r]*(\-\->)*)|(\s*(#|<!\-\-)\s*<LIGHT>\s.*?<\/LIGHT>[ ]*(\-\->)?)|(#\s<LIGHT\s?\/>(.*?)\n{1})/m, "")
end

def light_version(text)
  text.force_encoding('utf-8') if text.respond_to?(:force_encoding)
  reg_light_block = /((#|<!--)\s(<LIGHT\/>|<LIGHT>|<LIGHT\s\/>)\s#?.*?((<\/LIGHT>)[ ]*(-->)?))/m
  reg_pro_block = /\s*(#|<!--|\/\/)[ ]*<PRO>.*?[ ]*<\/PRO>[ ]*(-->)*/m
  without_pro = text.gsub(reg_pro_block, "")
  light_text = without_pro[reg_light_block]
  if light_text
    light_text.gsub!(/((#\s+)|(<LIGHT\/>)}|(<LIGHT>)|(<!\-\-)|(\-\->)|(<\/LIGHT>))/m, "")
    without_pro.gsub!(reg_light_block, light_text)
  end
  #remove one line LIGHT tag
  without_pro.gsub(/(#\s<LIGHT\s?\/>\s?)/, "")
end

def add_gpl2_license_header(files)
  files.each do |file_name|
    file_content = File.read(file_name)
    file_content = (file_name.match(/.*\.(js|css)/) ? PROPRIETARY_HEADER : GPL2_HEADER) + file_content
    file_content = "# encoding: utf-8\n#\n" + file_content if file_name.match(/.*_(test|helper)\.rb/)
    File.open(file_name, "w") {|file| file.puts file_content}
  end
end

plugin_dir = File.expand_path('../', File.dirname(__FILE__))

Dir["#{plugin_dir}/**/*.rb",
    "#{plugin_dir}/**/*.erb",
    "#{plugin_dir}/**/*.js",
    "#{plugin_dir}/**/*.api.rsb",
    "#{plugin_dir}/Gemfile"].each do |file_name|
  text = File.read(file_name)

  if ARGV && ARGV[0] == 'light'
    patched_file = light_version(text)
  else
    patched_file = pro_version(text)
  end

  File.open(file_name, "w") {|file| file.puts patched_file}
end

if ARGV && ARGV[0] == 'light'
  FileUtils.rm_r Dir["#{plugin_dir}/**/*week*",
                     "#{plugin_dir}/**/*my*"],
                 force: true
end

add_gpl2_license_header(Dir["#{plugin_dir}/**/*.js"])
add_gpl2_license_header(Dir["#{plugin_dir}/**/*.css"])
add_gpl2_license_header(Dir["#{plugin_dir}/**/*.rb"])

FileUtils.rm_r Dir["#{plugin_dir}/.drone.jsonnet"], force: true
