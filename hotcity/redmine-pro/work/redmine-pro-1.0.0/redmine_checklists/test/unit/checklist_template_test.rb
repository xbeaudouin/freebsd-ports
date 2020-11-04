# encoding: utf-8
#
# This file is a part of Redmine Checklists (redmine_checklists) plugin,
# issue checklists management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_checklists is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_checklists is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_checklists.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class ChecklistTemplateTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  RedmineChecklists::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_checklists).directory + '/test/fixtures/', [:checklists])

  def test_save_with_category
    ch_temp_cat = ChecklistTemplateCategory.create(:name => 'Category 1', :position => 1)
    check_list_template = ChecklistTemplate.new(:name => 'name', :category_id => ch_temp_cat.id, :template_items => 's')
    check_list_template.save
    assert_equal ch_temp_cat.id, check_list_template.reload.category.id
  end

  def test_checklist_template_items
    checklist_template = ChecklistTemplate.create(name: 'name', template_items: "--New Section\r\nFirst item\r\nSecond item")
    checklists = checklist_template.checklists
    assert_equal checklists.size, 3
    assert_equal checklists.first.subject, 'New Section'
    assert checklists.first.is_section
    assert !checklists.second.is_section
  end

  def test_checklist_template_visibility
    public_template = ChecklistTemplate.create(name: 'public', template_items: "--test1\r\ntest2", project: Project.find(1), is_public: true)

    assert_equal ChecklistTemplate.visible(User.find(1)), [public_template]
    assert_equal ChecklistTemplate.visible(User.find(2)), []
  end
end
