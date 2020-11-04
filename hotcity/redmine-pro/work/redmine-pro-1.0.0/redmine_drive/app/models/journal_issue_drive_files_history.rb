# This file is a part of Redmin Drive (redmine_drive) plugin,
# Filse storage plugin for redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_drive is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_drive is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_drive.  If not, see <http://www.gnu.org/licenses/>.

class JournalIssueDriveFilesHistory
  def initialize(was, became)
    @was = force_object was
    @became = force_object became
    @was_ids = @was.map(&:id).sort
    @became_ids = @became.map(&:id).sort

    @added_ids = @became_ids - @was_ids
    @removed_ids = @was_ids - @became_ids
  end

  def diff
    return if @became_ids == @was_ids

    { added: @became.select { |x| @added_ids.include? x.id },
      removed: @was.select { |x| @removed_ids.include? x.id } }
  end

  def journal_details(options = {})
    JournalDetail.new(options.merge({
      property: 'attr',
      prop_key: 'shared_files',
      old_value: files_to_json(@was),
      value: files_to_json(@became)
    }))
  end

  private

  def files_to_json(files)
    files.map { |file| { id: file.id, filename: file.filename } }.to_json
  end

  def force_object(object)
    if object.is_a?(String)
      JSON.parse(object).map { |x| OpenStruct.new(x) }
    else
      object.map { |x| OpenStruct.new(id: x.id, filename: x.filename) }
    end
  end
end
