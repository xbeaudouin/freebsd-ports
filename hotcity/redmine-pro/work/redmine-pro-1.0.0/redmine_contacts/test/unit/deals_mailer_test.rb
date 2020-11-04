# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class ContactsMailerTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions if Rails.version >= '4.2'

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
           :queries,
           :deals

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineContacts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deal_processes,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/contacts_mail_handler'

  def setup
    RedmineContacts::TestCase.prepare
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = Redmine::Notifiable.all.collect(&:name)
  end

  def test_crm_note_add
    note = Note.find(1)
    assert ContactsMailer.crm_note_add(User.current, note).deliver
    assert_match 'Note 1', last_email.text_part.to_s
  end

  def test_crm_note_add_to_company
    note = Note.find(4)
    assert ContactsMailer.crm_note_add(User.current, note).deliver
    assert_match 'Note 4', last_email.text_part.to_s
  end

  def test_crm_contact_add
    contact = Contact.find(1)
    assert ContactsMailer.crm_contact_add(User.current, contact).deliver
    assert_match 'Contact #1: Ivan Ivanov', last_email.text_part.to_s
  end
  def test_crm_note_add_to_deal
    note = Note.find(5)
    assert ContactsMailer.crm_note_add(User.current, note).deliver
    assert_match 'Note 5', last_email.text_part.to_s
  end

  def test_crm_deal_add
    deal = Deal.find(1)
    assert ContactsMailer.crm_deal_add(User.current, deal).deliver
    assert_match 'Deal #1', last_email.text_part.to_s
  end

  def test_crm_deal_updated
    deal_process = DealProcess.last
    deal_process.author = User.find(2)
    deal_process.save
    assert ContactsMailer.crm_deal_updated(User.current, deal_process).deliver
    assert_match 'John Smith', last_email.text_part.to_s
  end

  def test_deals_reminders
    ContactsMailer.deals_reminders
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = last_email
    assert_equal           ['admin@somenet.foo'],                                    mail.bcc
    assert_equal           '2 deal(s) due in the next 7 days',                       mail.subject
    assert_mail_body_match 'eCookbook #1: First deal with contacts (Due in 0 days)', mail
    assert_mail_body_match 'View all deals (2 open)',                                mail
    if Rails.version >= '4.2'
      assert_select_email do
        assert_select 'a[href=?]',
                      'http://mydomain.foo/deals?assigned_to_id=me&set_filter=1&sort=due_date%3Aasc',
                      text: 'View all deals'
        assert_select '/p:nth-last-of-type(1)',
                      text: 'View all deals (2 open)'
      end
    end
  end

  def test_deals_reminders_language_auto
    with_settings default_language: 'ru' do
      User.update(1, language: '')
      ContactsMailer.deals_reminders
      assert_equal 1, ActionMailer::Base.deliveries.size
      mail = last_email
      assert_equal ['admin@somenet.foo'],                                   mail.bcc
      assert_equal '2 назначенных на Вас сделок в ближайшие 7 дней',        mail.subject
      assert_match 'eCookbook #1: First deal with contacts (В срок 0 дня)', decoded_base64_body
    end
  end

  def test_deals_reminders_should_not_include_closed_deals
    deals(:deal_001).update_attributes(status: DealStatus.closed.first)
    ContactsMailer.deals_reminders
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = last_email
    assert_equal           ['admin@somenet.foo'],                      mail.bcc
    assert_equal           '1 deal(s) due in the next 7 days',         mail.subject
    assert_mail_body_match 'eCookbook #6: 10First deal with contacts', mail
    assert_mail_body_match 'View all deals (1 open)',                  mail
    if Rails.version >= '4.2'
      assert_select_email do
        assert_select '/p:nth-last-of-type(1)',
                      text: 'View all deals (1 open)'
      end
    end
  end

  def test_deals_reminders_for_users
    ContactsMailer.deals_reminders(users: [non_assignee_id])
    assert_equal 0, ActionMailer::Base.deliveries.size
    ContactsMailer.deals_reminders(users: [1])
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = last_email
    assert_equal           ['admin@somenet.foo'],                    mail.bcc
    assert_equal           '2 deal(s) due in the next 7 days',       mail.subject
    assert_mail_body_match 'eCookbook #1: First deal with contacts', mail
  end

  def test_deals_reminder_should_include_deals_assigned_to_groups
    with_settings issue_group_assignment: '1' do
      group = Group.generate!
      Member.create!(project_id: 2, principal: group, role_ids: [1])
      group.users += [users(:users_001), users(:users_008)]
      Deal.update_all(assigned_to_id: nil)
      assign_deal! deals(:deal_004), group.id

      ActionMailer::Base.deliveries.clear

      ContactsMailer.deals_reminders
      assert_equal 2, ActionMailer::Base.deliveries.size
      assert_equal %w(admin@somenet.foo miscuser8@foo.bar), recipients
      mail = ActionMailer::Base.deliveries.detect { |m| m.bcc == ['miscuser8@foo.bar'] }
      assert_equal           '1 deal(s) due in the next 7 days',     mail.subject
      assert_mail_body_match 'OnlineStore #4: Deal without contact', mail
    end
  end

  def test_deals_reminders_for_project
    ContactsMailer.deals_reminders(project: 'onlinestore')
    assert_equal 0, ActionMailer::Base.deliveries.size

    assign_deal! deals(:deal_004), 1
    ContactsMailer.deals_reminders(project: 'onlinestore')
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = last_email
    assert_equal           '1 deal(s) due in the next 7 days',     mail.subject
    assert_mail_body_match 'OnlineStore #4: Deal without contact', mail
  end

  def test_deals_reminders_by_due_days
    deals(:deal_001).update_attributes(due_date: 3.days.from_now)
    ContactsMailer.deals_reminders(days: 2)
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = last_email
    assert_equal              '1 deal(s) due in the next 2 days',         mail.subject
    assert_mail_body_no_match 'eCookbook #1: First deal with contacts',   mail
    assert_mail_body_match    'eCookbook #6: 10First deal with contacts', mail
  end

  def test_deals_reminders_should_only_include_deals_the_user_can_see
    user_id        = 8
    visible_deal   = deals(:deal_004)
    invisible_deal = deals(:deal_001)

    assign_deal! visible_deal, user_id
    member = Member.create!(project_id: 1, user_id: user_id, role_ids: [1])
    assign_deal! invisible_deal, user_id

    ContactsMailer.deals_reminders(users: [user_id])
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = last_email
    assert_mail_body_match 'eCookbook #1: First deal with contacts', mail
    assert_mail_body_match 'OnlineStore #4: Deal without contact',   mail

    ActionMailer::Base.deliveries.clear

    member.destroy
    ContactsMailer.deals_reminders(users: [user_id])
    assert_equal 1, ActionMailer::Base.deliveries.size
    mail = last_email
    assert_mail_body_no_match 'eCookbook #1: First deal with contacts', mail
    assert_mail_body_match    'OnlineStore #4: Deal without contact',   mail
  end

  def test_deals_reminders_should_sort_deals_by_due_date
    deals(:deal_004).update_attributes(assigned_to_id: 1)
    shuffled_deals = shuffle_open_deals!
    ContactsMailer.deals_reminders
    assert_equal 1, ActionMailer::Base.deliveries.size
    if Rails.version >= '4.2'
      assert_select_email do
        assert_select 'li', 3
        shuffled_deals.each_with_index do |deal, idx|
          assert_select "li:nth-child(#{idx + 1})",
                        "#{deal.name} (Due in #{idx} #{idx == 1 ? 'day' : 'days'})"
        end
      end
    else
      parsed_body = Nokogiri::HTML(html_part.to_s)
      lis = parsed_body.css('li')
      assert_equal 3, lis.size
      shuffled_deals.each_with_index do |deal, idx|
        li = lis[idx]
        assert_equal li.children[1].children.to_s, deal.name
        assert_equal li.children[2].to_s.strip,    "(Due in #{idx} #{idx == 1 ? 'day' : 'days'})"
      end
    end
  end

  private

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

  def text_part
    last_email.parts.detect { |part| part.content_type.include?('text/plain') }
  end

  def html_part
    last_email.parts.detect { |part| part.content_type.include?('text/html') }
  end
  def recipients
    ActionMailer::Base.deliveries
                      .map(&:bcc)
                      .flatten
                      .sort
  end

  def decoded_base64_body
    encoded_part = text_part.to_s
                            .match(/Content-Transfer-Encoding: base64\r\n\r\n(.*)/m)[1]
    Base64.decode64(encoded_part)
          .force_encoding('UTF-8')
  end

  def non_assignee_id
    Principal.pluck(:id)
             .tap { |ids| ids.delete(1) }
             .sample
             .to_s
  end

  def assign_deal!(deal, assignee_id)
    deal.update_attributes(
      assigned_to_id: assignee_id,
      due_date:       rand(0...ContactsMailer::DEFAULT_DEAL_REMINDER_PERIOD).days.from_now
    )
  end

  # NOTE: `Deal.open` forces instances to be readonly in ruby 1.9.3
  def shuffle_open_deals!
    open_statuses = DealStatus.open.pluck(:id)
    Deal.where(status_id: open_statuses)
        .shuffle
        .each_with_index do |deal, idx|
          deal.update_attributes(due_date: idx.days.from_now)
        end
  end
end
