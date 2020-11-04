# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class ContactsSetting
  def self.[](name, project_id)
    project_id = project_id.id if project_id.is_a?(Project)
    return settings[name.to_s].to_s unless project_id
    return settings['projects'][project_id][name.to_s].to_s if settings['projects'] && settings['projects'][project_id]
    ''
  end

  def self.[]=(name, project_id, value)
    assignee_settings = settings.stringify_keys
    project_id = project_id.id if project_id.is_a?(Project)
    if project_id
      assignee_settings['projects'] ||= {}
      assignee_settings['projects'][project_id] = { name.to_s => '' } unless assignee_settings['projects'][project_id]
      assignee_settings['projects'][project_id][name.to_s] = value
    else
      assignee_settings[name.to_s] = value
    end
    Setting.plugin_redmine_contacts = assignee_settings
  end

  def self.contact_name_format
    settings['name_format'] || :firstname_lastname
  end

  def self.vcard?
    Object.const_defined?(:Vcard)
  end

  def self.spreadsheet?
    Object.const_defined?(:Spreadsheet)
  end

  def self.monochrome_tags?
    settings['monochrome_tags'].to_i > 0
  end

  def self.contacts_show_in_top_menu?
    settings['contacts_show_in_top_menu'].to_i > 0
  end

  def self.contacts_show_in_app_menu?
    settings['contacts_show_in_app_menu'].to_i > 0
  end

  def self.default_country
    settings['default_country']
  end

  def self.cross_project_contacts?
    settings['cross_project_contacts'].to_i > 0
  end

  # Finance
  def self.default_currency
    RedmineCrm::Settings::Money.default_currency
  end

  def self.major_currencies
    RedmineCrm::Settings::Money.major_currencies
  end

  def self.default_tax
    RedmineCrm::Settings::Money.default_tax
  end

  def self.tax_type
    RedmineCrm::Settings::Money.tax_type
  end

  def self.tax_exclusive?
    RedmineCrm::Settings::Money.tax_exclusive?
  end

  def self.thousands_delimiter
    RedmineCrm::Settings::Money.thousands_delimiter || ' '
  end

  def self.decimal_separator
    RedmineCrm::Settings::Money.decimal_separator || '.'
  end

  def self.disable_taxes?
    RedmineCrm::Settings::Money.disable_taxes?
  end

  def self.post_address_format
    if settings['post_address_format'].present?
      settings['post_address_format'].to_s.strip
    else
      "%street1%\n%street2%\n%city%, %postcode%\n%region%\n%country%"
    end
  end
  def self.deals_show_in_top_menu?
    settings['deals_show_in_top_menu'].to_i > 0
  end

  def self.deals_show_in_app_menu?
    settings['deals_show_in_app_menu'].to_i > 0
  end

  private

  def self.settings
    RedmineContacts.settings
  end
end
