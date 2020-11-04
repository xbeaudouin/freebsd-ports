# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class HelpdeskMailerTest < ActiveSupport::TestCase
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

  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages,
                                                                                                                             :helpdesk_tickets])

  include RedmineHelpdesk::TestHelper

  def setup
    RedmineHelpdesk::TestCase.prepare

    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'

    Setting.notified_events = Redmine::Notifiable.all.collect(&:name)

    @heldesk_container = HelpdeskMailContainer.new(raw_helpdesk_email('new_issue_new_contact.eml'), {})
  end

  def test_should_not_change_perfom_delivery_state
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.perform_deliveries = false
      HelpdeskMailer.send(:with_performed_delivery) do
        true
      end
      assert_equal false, ActionMailer::Base.perform_deliveries

      ActionMailer::Base.perform_deliveries = true
      HelpdeskMailer.send(:with_performed_delivery) do
        true
      end
      assert_equal true, ActionMailer::Base.perform_deliveries
    end
  end

  def test_should_add_issue_and_contact
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      @project = Project.find('ecookbook')
      ContactsSetting['helpdesk_created_contact_tag', @project.id] = 'test,main'
      ContactsSetting['helpdesk_answer_from', @project.id] = 'test@email.from'
      ContactsSetting['helpdesk_send_notification', @project.id] = 1
      ContactsSetting['helpdesk_add_contact_notes', @project.id] = 0
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.find_by_subject('New support issue from email')
      contact = issue.customer

      assert_not_nil issue.helpdesk_ticket.ticket_date
      assert_equal 'support@somenet.foo', issue.helpdesk_ticket.to_address
      assert_equal 'new_customer@somenet.foo', issue.helpdesk_ticket.from_address
      assert_equal 'New', contact.first_name
      assert_equal 'Customer-Name', contact.last_name
      assert_equal 'new_customer@somenet.foo', contact.company
      assert contact.tag_list.include?('test')
      assert contact.tag_list.include?('main')
      assert_equal 'ecookbook', contact.project.identifier
      assert_equal 'new_customer@somenet.foo', contact.email
      assert last_email.from.include?('test@email.from')
      assert last_email.to.include?(contact.emails.first)
      assert !last_email.parts.first.body.to_s.blank?
    end
  end

  def test_should_add_with_all_tracker
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook', :tracker_id => 'all' })
      assert_equal Issue, issue.class
      issue.reload
      assert_equal issue, Issue.order(:id).last
      assert_equal issue.tracker, Project.find('ecookbook').trackers.first
      assert_not_nil issue.helpdesk_ticket.ticket_date
    end
  end

  def test_should_assign_to_duplicated_contact
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      Contact.create(:first_name => 'New',
                     :last_name => 'Customer-Name',
                     :company => 'Somenet.foo',
                     :email => 'customer@somenet.foo',
                     :projects => [Project.find('ecookbook')])

      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      contact = issue.customer

      assert_not_nil issue.helpdesk_ticket.ticket_date
      assert_equal 'support@somenet.foo', issue.helpdesk_ticket.to_address
      assert_equal 'new_customer@somenet.foo', issue.helpdesk_ticket.from_address
      assert_equal 'New', contact.first_name
      assert_equal 'Customer-Name', contact.last_name
      assert_equal 'new_customer@somenet.foo', contact.company
      assert_equal 'ecookbook', contact.project.identifier
      assert_match 'new_customer@somenet.foo', contact.email
    end
  end

  def test_should_add_duplicated_contact
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      duplicate = Contact.create(:first_name => 'new_customer',
                                 :last_name => '-',
                                 :company => 'Somenet.foo',
                                 :email => 'customer@somenet.foo',
                                 :projects => [Project.find('ecookbook')])

      issue = submit_helpdesk_email('ticket_without_name.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      contact = issue.customer

      assert_not_nil issue.helpdesk_ticket.ticket_date
      assert_equal 'support@somenet.foo', issue.helpdesk_ticket.to_address
      assert_equal 'new_customer@somenet.foo', issue.helpdesk_ticket.from_address
      assert_equal 'new_customer', contact.first_name
      assert_equal '-', contact.last_name
      assert_equal 'new_customer@somenet.foo', contact.company
      assert_equal 'ecookbook', contact.project.identifier
      assert_match 'new_customer@somenet.foo', contact.email
    end
  end

  test 'Should assign ticket to group' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      group = Group.find(11)
      ContactsSetting['helpdesk_answer_from', Project.find('onlinestore').id] = 'test@email.from'
      with_settings :issue_group_assignment => '1' do
        issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'onlinestore', :assigned_to_id => group.id })
        assert_equal Issue, issue.class
        assert !issue.new_record?
        issue.reload
        assert_equal group, issue.assigned_to
      end
    end
  end

  test 'Should assign ticket to user' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      user = User.find(2)
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook', :assigned_to_id => user.id })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal user, issue.assigned_to
    end
  end

  test 'Should set author from redmine user' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      user = User.find(2)
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      issue = submit_helpdesk_email('ticket_from_redmine_user.eml', :issue => { :project_id => 'ecookbook', :assigned_to_id => user.id })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal user, issue.author
    end
  end

  test 'Should recieve ticket without to address' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_with_empty_to.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.find_by_subject('New support issue from email')
      contact = issue.customer

      assert_not_nil issue.helpdesk_ticket.ticket_date
      assert_equal 'new_customer@somenet.foo', issue.helpdesk_ticket.from_address
      assert_equal '', issue.helpdesk_ticket.to_address
      assert_equal 'New', contact.first_name
      assert_equal 'Customer-Name', contact.last_name
    end
  end

  test 'Should not recieve ticket without from address' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_with_empty_from.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal false, issue
    end
  end

  test 'Should add contact with bad name' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_contact_bad_name.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.find_by_subject('New support issue from email')
      contact = issue.customer
      assert_equal "New\"", contact.first_name
      assert_equal "\"Customer\"", contact.last_name
      assert_equal 'new_customer@somenet.foo', contact.email
      assert last_email.from.include?('test@email.from')
      assert last_email.to.include?(contact.emails.first)
      assert !last_email.parts.first.body.to_s.blank?
    end
  end

  test 'Should add contact with unicode name' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_contact_unicode_name.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.find_by_subject('New support issue from email')
      contact = issue.customer
      assert_equal 'Кирилл', contact.first_name
      assert_equal 'Безруков', contact.last_name
      assert_equal 'new_customer@somenet.foo', contact.email
      assert last_email.from.include?('test@email.from')
      assert last_email.to.include?(contact.emails.first)
      assert !last_email.parts.first.body.to_s.blank?
    end
  end

  def test_should_add_new_issue_and_contact_with_encoded_name
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_issue_new_contact_encode.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.find_by_subject('Проверка') if RUBY_VERSION > '1.9'
      contact = issue.customer
      assert_equal 'Кирилл', contact.first_name
      assert_equal 'Безруков', contact.last_name
      assert_equal 'aminov1982@gmail.com', contact.email
      assert last_email.from.include?('test@email.from')
      assert last_email.to.include?(contact.emails.first)
      assert !last_email.parts.first.body.to_s.blank?
    end
  end

  def test_should_add_new_issue_from_html_only_body
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_html_only.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload

      assert_match "Header one\r\n", issue.description
      assert_match " one\r\n", issue.description
      assert_match "one with line breaks,\r\nparagraph number", issue.description
    end
  end

  def test_should_add_new_issue_to_contact_without_subject
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_no_subject.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert_equal '(no subject)', issue.subject
    end
  end

  def test_should_add_issue_with_rus_attachment
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_created_contact_tag', Project.find('ecookbook').id] = 'test,main'
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('ticket_with_rus_attachment.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload

      assert_equal 'Русская тема Apple Mail', issue.subject
      assert_match 'В этом письме аттач с русским названием', issue.description
      attachment = issue.attachments.last
      assert_not_nil attachment
      assert_equal 'Аттач номер один.rtf', attachment.filename
      assert File.size?(attachment.diskfile) > 0
      assert File.size?(issue.attachments.last.diskfile) > 0
    end
  end

  def test_should_add_issue_and_contact_ru
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_created_contact_tag', Project.find('ecookbook').id] = 'test,main'
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_issue_new_contact_ru.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      # assert_equal issue, Issue.find_by_subject('New support issue from email')
      contact = issue.customer
      assert_equal 'результаты турнира', issue.subject
      assert_equal 'Динара', contact.first_name
      assert_equal 'Кремчеева', contact.last_name
      assert contact.tag_list.include?('test')
      assert contact.tag_list.include?('main')
      assert_equal 'ecookbook', contact.project.identifier
      assert_equal 'kr.dinara@mail.ru', contact.email
      assert last_email.from.include?('test@email.from')
      assert last_email.to.include?(contact.emails.first)
      assert !last_email.parts.first.body.to_s.blank?
      attachment = issue.attachments.last
      assert_equal 'восходящие звезды 2012 6 тур.xml', attachment.filename
      assert_not_nil attachment
      assert File.size?(attachment.diskfile) > 0
      assert File.size?(issue.attachments.last.diskfile) > 0
    end
  end

  def test_should_add_issue_and_contact_ru_2
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_created_contact_tag', Project.find('ecookbook').id] = 'test,main'
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_issue_new_contact_ru_2.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      # assert_equal issue, Issue.find_by_subject('New support issue from email')
      contact = issue.customer
      assert_equal "FW: результаты \"Кубка Кремля\"", issue.subject
      assert_equal 'Valeria', contact.first_name
      assert_match 'Лера, извини', issue.description
      attachment = issue.attachments.last
      assert_not_nil attachment
      assert_equal '131012.xml', attachment.filename
      assert File.size?(attachment.diskfile) > 0
      assert File.size?(issue.attachments.last.diskfile) > 0
    end
  end

  def test_should_add_issue_and_contact_ru_4
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_new_contact_ru_4.eml', :issue => { :project_id => 'ecookbook' })
      issue.reload
      assert_equal Issue, issue.class
      assert_equal '(no subject)', issue.subject
      attachment = issue.attachments.last
      assert_equal 'Кубок Осени - 2012.xml', attachment.filename
      assert File.size?(attachment.diskfile) > 0
    end
  end

  def test_should_add_issue_and_contact_ru_5
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_new_contact_ru_5.eml', :issue => { :project_id => 'ecookbook' })
      issue.reload
      assert_equal Issue, issue.class
      assert_equal 'Fwd: Турнир 14 октября 2012 Калининград', issue.subject
      attachment = issue.attachments.last
      assert_equal 'Kaliningrad 14102012.xml', attachment.filename
      assert File.size?(attachment.diskfile) > 0
    end
  end

  def test_should_add_issue_and_contact_in_japanese
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_with_japanese.eml', :issue => { :project_id => 'ecookbook' })
      issue.reload
      assert_equal Issue, issue.class
      assert_equal 'お問い合わせ', issue.subject if RUBY_VERSION > '1.9'
      assert_match 'いつも楽しく使わせ', issue.description
    end
  end

  def test_should_create_from_quoted_body
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_with_quotes.eml', :issue => { :project_id => 'ecookbook' })
      issue.reload
      contact = Contact.last
      assert_equal Issue, issue.class
      assert_equal 'Максим', contact.first_name
      assert_equal 'Скворцов', contact.last_name
      assert_match 'не помещается название номера', issue.description
    end
  end

  def test_should_create_from_koi8_r_body
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_in_koi8_r.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      issue.reload
      contact = Contact.last
      assert_equal Issue, issue.class
      assert_equal 'Шипиев', contact.first_name
      assert_equal 'Роман', contact.last_name
      assert_match 'Речь идет про плагин', issue.description
    end
  end

  def test_should_create_from_win1251_body
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_in_win1251.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      issue.reload
      contact = Contact.last
      assert_equal Issue, issue.class
      assert_equal 'RDSU', contact.first_name
      if RUBY_VERSION > '1.9'
        assert_match /(no subject|Unprocessable subject)/, issue.subject
      else
        assert_match '??????', issue.subject
      end
      assert_match 'Танцевальный ринг', issue.description
    end
  end

  def test_should_create_with_encoded_attachment
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_with_encoded_attachment.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      issue.reload
      contact = Contact.last
      assert_equal Issue, issue.class
      assert_equal 'Alexander', contact.first_name
      assert_match 'asdf', issue.subject
      assert_match 'This ticket is for testing purposes.', issue.description
      assert_match /Müller\.png|Mller\.png/, issue.attachments.last.filename
    end
  end

  def test_should_create_from_bq_encoded_body
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_with_bq_encoding.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      issue.reload
      contact = Contact.last
      assert_equal Issue, issue.class
      assert_equal 'Плетнёв', contact.first_name
      assert_equal 'Алексей', contact.last_name
      assert_match 'Ответ на письмо', issue.description
    end
  end

  def test_should_create_with_encoding_iso_8859_15
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      return true unless 'str'.respond_to?(:force_encoding)
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_in_iso_8859_15.eml', :issue => { :project_id => 'ecookbook' })
      issue.reload
      contact = Contact.last
      assert_equal Issue, issue.class
      assert_equal 'Joachim', contact.first_name
      assert_equal 'Höhl', contact.last_name
      assert_match 'Mit freundlichen Grüßen', issue.description
    end
  end

  def test_do_not_add_same_attachment
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      Attachment.create(:container => Issue.find(5),
                        :file => helpdesk_uploaded_file('attachment.zip', 'text/plain'),
                        :author => User.find(1))

      ActionMailer::Base.deliveries.clear
      issue = Issue.find(5)
      journal = submit_helpdesk_email('reply_with_duplicated_attachment.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => 'Feedback')
      assert_equal Journal, journal.class

      journal.reload
      issue = journal.issue

      assert_equal 1, issue.attachments.count
      assert_equal 'attachment.zip', issue.attachments.last.filename
      assert_match 'два одинаковых вложения', journal.notes
    end
  end

  test 'Should add issue and contact with French symbols' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_french.eml', :issue => { :project_id => 'ecookbook' })
      issue.reload
      assert_equal Issue, issue.class
      assert_equal "email test ok'ok", issue.subject
      attachment = issue.attachments.last
      assert_equal 'image001.jpg', attachment.filename
      assert_match 'the bug ishere', issue.description
      assert File.size?(attachment.diskfile) > 0
    end
  end

  def test_ticket_with_multiline_subject
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('ticket_with_multiline_subject.eml', :issue => { :project_id => 'ecookbook' })
      issue.reload
      assert_equal Issue, issue.class
      assert_equal 'Проверка (не открывайте это письмо)', issue.subject
    end
  end

  test 'Should not add contact' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_is_not_create_contacts', Project.find('ecookbook').id] = '1'
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal false, issue
      ContactsSetting['helpdesk_is_not_create_contacts', Project.find('ecookbook').id] = '0'
    end
  end

  test 'Should not add contact from blacklist' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_blacklist', Project.find('ecookbook').id] = 'new_customer@somenet.foo'
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal false, issue
      ContactsSetting['helpdesk_blacklist', Project.find('ecookbook').id] = ''
    end
  end

  test 'Should not add contact from blacklist by regexp' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_blacklist', Project.find('ecookbook').id] = "new_.*\.foo"
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal false, issue
      ContactsSetting['helpdesk_blacklist', Project.find('ecookbook').id] = ''
    end
  end

  test 'Should add issue to contact' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_issue_to_contact.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.find_by_subject('New support issue to Ivan')
      contact = issue.customer
      assert_equal 'Ivan', contact.first_name
      assert last_email.to.include?(contact.emails.first)
    end
  end

  def test_should_add_project_to_existing_contact
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      onlinestore_project = Project.find_by_identifier('onlinestore')
      ContactsSetting['helpdesk_answer_from', onlinestore_project.id] = 'test@email.from'
      ContactsSetting[:helpdesk_add_contact_to_project, onlinestore_project.id] = '1'
      issue = submit_helpdesk_email('new_issue_to_contact.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload

      contact = issue.customer
      assert contact.projects.include?(onlinestore_project)
    end
  end

  def test_should_attach_mail_to_issue
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal 'message.eml', issue.helpdesk_ticket.message_file.filename
      assert issue.helpdesk_ticket.message_file.filesize > 0
    end
  end

  def test_should_add_issue_to_contact_with_params
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_answer_from', Project.find('ecookbook').id] = 'test@email.from'
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_issue_to_contact.eml', :issue => { :project_id => 'ecookbook',
                                                                            :priority => 'Urgent',
                                                                            :status => 'Resolved',
                                                                            :tracker => 'Support request',
                                                                            :due_date => Date.today + 20,
                                                                            :assigned_to => 'jsmith' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.find_by_subject('New support issue to Ivan')
      assert_equal 'Urgent', issue.priority.name
      # assert_equal 'Assigned', issue.status.name
      assert_equal 'Support request', issue.tracker.name
      assert_equal 'jsmith', issue.assigned_to.login
      assert_equal Date.today + 20, issue.due_date
      contact = issue.customer
      assert_equal 'Ivan', contact.first_name
      assert last_email.to.include?(contact.emails.first)
    end
  end

  def test_should_reply_to_issue_to_contact
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear

      issue = Issue.find(5)
      contact = Contact.find(1)

      assert_not_equal 'Feedback', issue.status.name

      journal = submit_helpdesk_email('reply_from_contact.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => 'Feedback')
      assert_equal Journal, journal.class
      assert !journal.new_record?

      journal.reload
      issue.reload
      contact = journal.issue.customer

      assert_not_nil journal.journal_message.message_date
      assert_equal 'support@somenet.foo', journal.journal_message.to_address
      assert_equal 'ivan@mail.com', journal.journal_message.from_address
      assert_equal 'bcc@somenet.foo', journal.journal_message.bcc_address
      assert_equal 'cc@somenet.foo', journal.journal_message.cc_address
      assert_equal 1, journal.contact.id
      assert_equal issue.customer, journal.contact
      assert_equal issue, journal.issue
      assert_equal 'subproject1', journal.issue.project.identifier
      assert_equal 'Ivan', contact.first_name
      assert_equal 'Feedback', issue.status.name
    end
  end

  def test_should_reply_to_issue_to_contact_with_attachment
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear

      issue = Issue.find(5)

      assert_not_equal 'Feedback', issue.status.name

      journal = submit_helpdesk_email('reply_with_attachment.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => 'Feedback')
      assert_equal Journal, journal.class
      assert !journal.new_record?

      journal.reload
      issue.reload
      contact = journal.issue.customer

      assert_equal 1, journal.contact.id
      assert_equal issue.customer, journal.contact
      assert_equal issue, journal.issue
      assert_equal 'subproject1', journal.issue.project.identifier
      assert_equal 'Ivan', contact.first_name
      assert_equal 'Feedback', issue.status.name
      attachment = issue.attachments.find_by_filename('Paella.jpg')
      assert_not_nil attachment
      assert File.size?(attachment.diskfile) > 0
      assert File.size?(issue.attachments.last.diskfile) > 0
    end
  end

  test 'Should attach email to reply' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear

      issue = Issue.find(5)

      assert_not_equal 'Feedback', issue.status.name

      journal = submit_helpdesk_email('reply_from_contact.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => 'Feedback')
      assert_equal Journal, journal.class
      assert !journal.new_record?

      journal.reload
      issue.reload
      contact = journal.issue.customer

      assert_equal 1, journal.contact.id
      assert_equal issue.customer, journal.contact
      assert_equal issue, journal.issue
      assert_equal "reply-#{DateTime.now.strftime('%d.%m.%y-%H.%M.%S')}.eml".truncate(20), journal.journal_message.message_file.filename.truncate(20)
      assert File.size?(journal.journal_message.message_file.diskfile) > 0
    end
  end

  test 'Should deliver received request confirmation' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = Issue.find(4)
      contact = Contact.find(1)
      assert HelpdeskMailer.auto_answer(contact, issue)
      assert last_email.to.include?(contact.emails.first)
      assert !last_email.parts.first.body.to_s.blank?
    end
  end

  def test_should_ignore_auto_answer
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear

      journal = submit_helpdesk_email('auto_answer.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => 'Feedback')
      assert_equal false, journal, "Should not accept X-Auto-Response-Suppress: oof"

      journal = submit_helpdesk_email('auto_answer_exchange.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => 'Feedback')
      assert_equal false, journal, "Should not accept X-Auto-Response-Suppress: all"
    end
  end

  # test "Should delete spaces" do
  #   ActionMailer::Base.deliveries.clear
  #   issue = submit_helpdesk_email('ticket_with_leading_spaces_to.eml', :issue => {:project_id => 'ecookbook'})
  #   assert_equal Issue, issue.class
  #   assert !issue.new_record?
  #   issue.reload
  #   assert_equal "", issue.description
  #   assert_match /^[^ ]+.*/, issue.description
  # end

  def test_should_deliver_response
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = Issue.find(1)
      contact = Contact.find(1)
      issue.journals.last.build_journal_message
      assert HelpdeskMailer.issue_response(contact, issue.journals.last)
      assert last_email.to.include?(contact.emails.first)
      assert_equal "Re: #{issue.subject} [#{issue.tracker.name} ##{issue.id}]", last_email.subject
    end
  end

  def test_should_replace_macro
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      helpdesk_settings = {
        'helpdesk_emails_header' => "Hello old, %%NAME%%\r\nHello new, {%contact.first_name%}",
        'helpdesk_emails_footer' => "Regards old, %%NOTE_AUTHOR.FIRST_NAME%%\r\nRegards new, {%response.author.first_name%}",
        'helpdesk_vote_accept' => 1,
      }

      with_contacts_settings 'name_format' => :firstname_lastname do
        with_helpdesk_settings helpdesk_settings do
          issue = Issue.find(1)
          issue.assigned_to = User.find(3)
          issue.estimated_hours = 12
          issue.done_ratio = 50
          issue.status = IssueStatus.where(:name => 'Rejected').first
          issue.due_date = Date.today + 20
          issue.save!

          attachment = Attachment.create!(:container => HelpdeskTicket.find(1),
                                          :file => uploaded_file('new_issue_new_contact_ru_2.eml', 'message/rfc822'),
                                          :author => User.find(1))

          user_cf = UserCustomField.create(:name => 'Test custom field', :is_filter => true, :field_format => 'string')
          journal_user = User.find(2)
          journal_user.custom_field_values = { user_cf.id => 'This is custom значение' }
          journal_user.save

          contact = Contact.find(1)
          journal = issue.journals.last
          journal.notes = "Full name old: %%FULL_NAME%%\r\n" +
                          "Company old: %%COMPANY%%\r\n" +
                          "Last name old: %%LAST_NAME%%\r\n" +
                          "Middle name old: %%MIDDLE_NAME%%\r\n" +
                          "Date old: %%DATE%%\r\n" +
                          "Assignee old: %%ASSIGNEE%%\r\n" +
                          "Issue ID old: %%ISSUE_ID%%\r\n" +
                          "Issue tracker old: %%ISSUE_TRACKER%%\r\n" +
                          "Issue description old: %%QUOTED_ISSUE_DESCRIPTION%%\r\n" +
                          "Project old: %%PROJECT%%\r\n" +
                          "Subject old: %%SUBJECT%%\r\n" +
                          "Note author old: %%NOTE_AUTHOR%%\r\n" +
                          "Note author first name old: %%NOTE_AUTHOR.FIRST_NAME%%\r\n" +
                          "Note author last name old: %%NOTE_AUTHOR.LAST_NAME%%\r\n" +
                          '====================' +
                          "Full name new: {%contact.name%}\r\n" +
                          "Company new: {%contact.company%}\r\n" +
                          "Last name new: {%contact.last_name%}\r\n" +
                          "Middle name new: {%contact.middle_name%}\r\n" +
                          "Email: {%contact.email%}\r\n" +
                          "Date new: {%date%}\r\n" +
                          "Assignee new: {%ticket.assigned_to%}\r\n" +
                          "Issue ID new: {%ticket.id%}\r\n" +
                          "Issue tracker new: {%ticket.tracker%}\r\n" +
                          "Issue description new: {%ticket.quoted_description%}\r\n" +
                          "Project new: {%ticket.project%}\r\n" +
                          "Subject new: {%ticket.subject%}\r\n" +
                          "Note author new: {%response.author%}\r\n" +
                          "Note author first name new: {%response.author.first_name%}\r\n" +
                          "Note author last name new: {%response.author.last_name%}\r\n" +
                          "Issue closed on: {%ticket.closed_on%}\r\n" +
                          "Issue start date: {%ticket.start_date%}\r\n" +
                          "Issue due date: {%ticket.due_date%}\r\n" +
                          "Issue Status: {%ticket.status%}\r\n" +
                          "Issue Priority: {%ticket.priority%}\r\n" +
                          "Issue public url: {%ticket.public_url%}\r\n" +
                          "Issue Estimated hours: {%ticket.estimated_hours%}\r\n" +
                          "Issue Done ratio: {%ticket.done_ratio%}\r\n" +
                          "=================\r\n" +
                          "User custom field: {%response.author.custom_field: Test custom field%}\r\n"+
                          "Issue vote url: {%ticket.voting%}\r\n"+
                          "Issue good vote url: {%ticket.voting.good%}\r\n"+
                          "Issue okay vote url: {%ticket.voting.okay%}\r\n"+
                          "Issue bad vote url: {%ticket.voting.bad%}\r\n"+
                          "{{send_file(#{attachment.id})}}"

          journal.save!
          User.current = User.find(4)

          assert HelpdeskMailer.issue_response(contact, journal)
          mail_body = last_email.text_part.body.to_s
          assert_match /Hello old, Ivan/, mail_body
          assert_match /Full name old: Ivan Ivanov/, mail_body
          assert_match /Company old: Domoway/, mail_body
          assert_match /Last name old: Ivanov/, mail_body
          assert_match /Middle name old: Ivanovich/, mail_body
          assert_match /Assignee old: Dave Lopper/, mail_body
          assert_match /Issue ID old: 1/, mail_body
          assert_match /Issue tracker old: Bug/, mail_body
          assert_match /Issue description old: > Unable to print recipes/, mail_body
          assert_match /Project old: eCookbook/, mail_body
          if Redmine::VERSION.to_s >= '3.0'
            assert_match /Subject new: Cannot print recipes/, mail_body
            assert_match /Subject new: Cannot print recipes/, mail_body
          else
            assert_match /Subject new: Can't print recipes/, mail_body
            assert_match /Subject new: Can't print recipes/, mail_body
          end
          assert_match /Note author old: John Smith/, mail_body
          assert_match /Note author first name old: John/, mail_body
          assert_match /Note author last name old: Smith/, mail_body
          assert_match /Regards old, John/, mail_body

          assert_match /Hello new, Ivan/, mail_body
          assert_match /Full name new: Ivan Ivanov/, mail_body
          assert_match /Company new: Domoway/, mail_body
          assert_match /Last name new: Ivanov/, mail_body
          assert_match /Middle name new: Ivanovich/, mail_body
          assert_match /Email: ivan@mail.com/, mail_body
          assert_match /Assignee new: Dave Lopper/, mail_body
          assert_match /Issue ID new: 1/, mail_body
          assert_match /Issue tracker new: Bug/, mail_body
          assert_match /Issue description new: > Unable to print recipes/, mail_body
          assert_match /Project new: eCookbook/, mail_body
          assert_match /Note author new: John Smith/, mail_body
          assert_match /Note author first name new: John/, mail_body
          assert_match /Note author last name new: Smith/, mail_body
          assert_match /Regards new, John/, mail_body
          assert_match "Issue closed on: #{ApplicationHelper.format_date(issue.closed_on)}", mail_body if Redmine::VERSION.to_s > '2.3'
          assert_match 'Issue start date: ', mail_body
          assert_match "Issue due date: #{ApplicationHelper.format_date(issue.due_date)}", mail_body
          assert_match /Issue Status: Rejected/, mail_body
          assert_match /Issue Priority: Low/, mail_body

          assert_match "Issue public url: http:\/\/mydomain.foo\/tickets\/1\/#{issue.helpdesk_ticket.token}", mail_body
          assert_match /Issue Estimated hours: 12.0/, mail_body
          assert_match /Issue Done ratio: 50/, mail_body

          assert_match /User custom field: This is custom значение/, mail_body

          assert_match "Issue vote url: http:\/\/mydomain.foo\/vote\/1\/#{issue.helpdesk_ticket.token}", mail_body
          assert_match "Issue good vote url: http:\/\/mydomain.foo\/vote\/1\/2/#{issue.helpdesk_ticket.token}", mail_body
          assert_match "Issue okay vote url: http:\/\/mydomain.foo\/vote\/1\/1/#{issue.helpdesk_ticket.token}", mail_body
          assert_match "Issue bad vote url: http:\/\/mydomain.foo\/vote\/1\/0/#{issue.helpdesk_ticket.token}", mail_body

          assert_equal 1, last_email.attachments.count
          assert_equal true, last_email.attachments.first.present?
        end
      end
    end
  end

  def test_should_replace_from_macro
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      assert_equal '<test@email.from>', HelpdeskMailSupport.apply_from_macro('{%response.author%} <test@email.from>', User.anonymous)
      assert_equal '<test@email.from>', HelpdeskMailSupport.apply_from_macro('{%response.author%} something text <test@email.from>', User.anonymous)
      assert_equal '<test@email.from>', HelpdeskMailSupport.apply_from_macro('{%response.author.first_name%} <test@email.from>', User.anonymous)
      assert_equal 'Robert Hill <test@email.from>', HelpdeskMailSupport.apply_from_macro('{%response.author%} <test@email.from>', User.find(4))
      assert_equal 'Robert <test@email.from>', HelpdeskMailSupport.apply_from_macro('{%response.author.first_name%} <test@email.from>', User.find(4))
      assert_equal 'Robert Hill from RedmineUP <test@email.from>', HelpdeskMailSupport.apply_from_macro('{%response.author%} from RedmineUP <test@email.from>', User.find(4))
      assert_equal 'Robert something text <test@email.from>', HelpdeskMailSupport.apply_from_macro('{%response.author.first_name%} something text <test@email.from>', User.find(4))
      assert_equal 'test@email.from', HelpdeskMailSupport.apply_from_macro('test@email.from', User.find(4))
    end
  end

  def test_should_send_from_changed_address
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = Issue.find(1)
      contact = Contact.find(1)
      ContactsSetting['helpdesk_answer_from', issue.project.id] = 'newfrom@mail.com'

      assert HelpdeskMailer.issue_response(contact, issue.journals.last, _params = {})
      assert last_email.to.include?(contact.emails.first)
      assert last_email.subject.include?("[#{issue.tracker} ##{issue.id}]")
      assert_equal 'newfrom@mail.com', last_email.from.first.to_s
    end
  end

  def test_should_send_to_changed_address
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = Issue.find(1)
      contact = Contact.find(1)

      assert HelpdeskMailer.issue_response(contact, issue.journals.last, _params = { :to_address => 'to_address@mail.com' })
      assert_equal 'to_address@mail.com', last_email.to_addrs.first.to_s
    end
  end

  test 'Should find issue by in_reply_to' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = Issue.find(1)
      journal = issue.journals.last
      contact = Contact.find(1)
      journal.journal_message = JournalMessage.new(:contact => contact,
                                                   :journal => issue.journals.last,
                                                   :from_address => contact.primary_email,
                                                   :message_date => Time.now,
                                                   :message_id => '123456789@mail.com')
      journal.save!
      response_journal = submit_helpdesk_email('ticket_with_in_reply_to.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => 'Feedback')
      assert_equal Journal, response_journal.class
      assert_equal response_journal.issue, journal.issue
    end
  end

  test 'Should add journal with empty status settings' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = Issue.find(1)
      journal = issue.journals.last
      contact = Contact.find(1)
      journal.journal_message = JournalMessage.new(:contact => contact,
                                                   :journal => issue.journals.last,
                                                   :from_address => contact.primary_email,
                                                   :message_date => Time.now,
                                                   :message_id => '123456789@mail.com')
      journal.save!
      response_journal = submit_helpdesk_email('ticket_with_in_reply_to.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => '')
      assert_equal Journal, response_journal.class
      assert_equal response_journal.issue, journal.issue
      assert_equal issue.status_id, response_journal.issue.status_id
    end
  end

  test 'Should add issue reply by references' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = Issue.find(1)
      journal = issue.journals.last
      contact = Contact.find(1)
      journal.journal_message = JournalMessage.new(:contact => contact,
                                                   :journal => issue.journals.last,
                                                   :from_address => contact.primary_email,
                                                   :message_date => Time.now,
                                                   :message_id => '123456789@mail.com')
      journal.save!
      response_journal = submit_helpdesk_email('ticket_with_references.eml', :issue => {:project_id => 'ecookbook'}, :reopen_status => 'Feedback')
      assert_equal Journal, response_journal.class
      assert_equal response_journal.issue, journal.issue
    end
  end

  test 'should correctly decode email subject' do
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      text_subject   = 'incidencia caracteres comentarios'
      iso_subject    = '=?iso-8859-1?Q?M=C1S_MODIFICACIONES_NO_SOLICITADAS_EN_EL_DISE=D1O_DE_LA_F?==?iso-8859-1?Q?ACTURA?='
      koi8r_subject  = '=?koi8-r?B?7sUgz9TQ0sHXzNHA1NPRIMbBy9PZIM7BIM7PzcXSINcg/sXSzs/Hz9LJySAr?==?koi8-r?Q?38220225702//_=F4=F4_125590?='
      koi8r_subject2 = '=?koi8-r?Q?=F2=D5=D3=D3=CB=C1=D1_=D4=C5=CD=C1_Apple_Mail?='
      mailer = HelpdeskMailRecipient::IssueRecipient.new(@heldesk_container)

      assert_equal mailer.send(:decode_subject, text_subject),   'incidencia caracteres comentarios'
      assert_equal mailer.send(:decode_subject, iso_subject),    'MÁS MODIFICACIONES NO SOLICITADAS EN EL DISEÑO DE LA FACTURA'
      assert_equal mailer.send(:decode_subject, koi8r_subject),  'Не отправляются факсы на номер в Черногории +38220225702// ТТ 125590'
      assert_equal mailer.send(:decode_subject, koi8r_subject2), 'Русская тема Apple Mail'
    end
  end

  def test_vote_text_in_mail_correct
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = Issue.find(1)
      contact = Contact.find(1)
      journal = issue.journals.last
      journal.details << JournalDetail.create(:property => 'attr',
                                              :prop_key => 'vote',
                                              :old_value => '1',
                                              :value => '2')
      journal.save!

      if Redmine::VERSION.to_s > '3.5'
        [User.find(1), User.find(2)].each do |user|
          Mailer.issue_edit(user, journal).deliver
        end
      else
        if Redmine::VERSION.to_s >= '2.4'
          assert Mailer.issue_edit(journal, [User.find(1)], [User.find(2)]).deliver
        else
          assert Mailer.issue_edit(journal).deliver
        end
      end
      assert_match /changed from Just ok to Awesome/, last_email.text_part.body.to_s
    end
  end

  def test_should_override_params_from_allow_override
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook' },
                                                                 :allow_override => 'project, tracker')
      assert_equal Issue, issue.class
      issue.reload
      assert_equal issue, Issue.order(:id).last
      assert_equal issue.tracker, Tracker.where(:name => 'Support request').first
      assert_equal issue.project, Project.where(:name => 'OnlineStore').first
      assert_not_nil issue.helpdesk_ticket.ticket_date
    end
  end

  def test_hould_receive_letter_with_id_or_name_in_project_params
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_contact_unicode_name.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.where(:subject => 'New support issue from email').last

      issue2 = submit_helpdesk_email('new_contact_unicode_name.eml', :issue => { :project_id => '1' })
      assert_equal Issue, issue2.class
      assert !issue2.new_record?
      issue2.reload
      assert_equal issue2, Issue.where(:subject => 'New support issue from email').last
    end
  end

  def test_should_use_reply_to_field_if_its_present
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('reply_to_mail.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      issue.reload
      assert_equal issue, Issue.order(:id).last
      assert_equal 'foo@bar.com', issue.helpdesk_ticket.from_address
    end
  end

  def test_should_add_issue_and_contact_with_require_fields
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      IssueCustomField.create!(:name => 'Issue require field', :is_required => true, :is_for_all => true, :field_format => 'string')
      issue = submit_helpdesk_email('new_issue_new_contact.eml', :issue => { :project_id => 'ecookbook' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal issue, Issue.find_by_subject('New support issue from email')
      assert_not_nil issue.helpdesk_ticket.ticket_date
      assert_equal 'support@somenet.foo', issue.helpdesk_ticket.to_address
      assert_equal 'new_customer@somenet.foo', issue.helpdesk_ticket.from_address
      assert_equal 'New', issue.customer.first_name
      assert_equal 'Customer-Name', issue.customer.last_name
    end
  end

  def test_should_reply_to_issue_to_contact_with_require_fields
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      IssueCustomField.create!(:name => 'Issue require field', :is_required => true, :is_for_all => true, :field_format => 'string')
      issue = Issue.find(5)
      contact = Contact.find(1)
      journal = submit_helpdesk_email('reply_from_contact.eml', :issue => { :project_id => 'ecookbook' }, :reopen_status => 'Feedback')
      assert_equal Journal, journal.class
      assert !journal.new_record?
      journal.reload
      issue.reload
      contact = journal.issue.customer
      assert_equal 'support@somenet.foo', journal.journal_message.to_address
      assert_equal 'ivan@mail.com', journal.journal_message.from_address
      assert_equal 1, journal.contact.id
      assert_equal issue.customer, journal.contact
      assert_equal issue, journal.issue
    end
  end

  def test_receive_ticket_without_text_with_attachment
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_without_text_with_attachment.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal 1, issue.attachments.count
      assert_equal '', issue.description
    end
  end

  def test_should_decode_encoded_subject
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_encoded_subject.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal '170203 Изменение курсов валют в УС', issue.subject
    end
  end

  def test_should_decode_partly_encoded_subject
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_partly_encoded_subject.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal 'Not encoded part of subject - 170203 Изменение курсов валют в УС - another part', issue.subject
    end
  end

  def test_should_ignore_blacklisted_attachment
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      with_settings :mail_handler_excluded_filenames => '*.png' do
        issue = submit_helpdesk_email('ticket_with_encoded_attachment.eml', :issue => { :project_id => 'ecookbook' })
        assert_equal Issue, issue.class
        issue.reload
        assert_equal 0, issue.attachments.count
      end if Redmine::VERSION.to_s >= '2.4'
    end
  end

  def test_should_replace_emoji
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      ContactsSetting['helpdesk_send_notification', Project.find('ecookbook').id] = 1
      issue = submit_helpdesk_email('emoji_message.eml', :issue => { :project_id => 'ecookbook', :tracker_id => 'all' })
      assert_equal Issue, issue.class
      issue.reload
      assert_equal issue, Issue.order(:id).last
      assert_equal issue.subject, 'Emoji'
    end
  end

  def test_create_from_email_with_image_body
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      issue = submit_helpdesk_email('image-body.eml', :issue => { :project_id => 'ecookbook' })
      assert_not_empty issue.attachments
      attachment = issue.attachments.first
      assert_equal attachment.filename, 'image.png'
      assert_empty issue.description
    end
  end

  def test_should_decode_partly_encoded_subject
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_with_html_encoding.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_match "\r\n\r\n\t\t", issue.description
      assert_match "Thanks for using Chat", issue.description
    end
  end

  def test_should_decode_base64_body_not_one_line
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_with_encoded_body.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_match "\r\n", issue.description
      assert_match "One line", issue.description
    end
  end

  def test_should_save_calendar_event_for_calendar_email
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_with_calendar.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_match "Testing helpdesk calendar", issue.description
      assert issue.attachments.where(content_type: 'text/calendar').first
    end
  end

  def test_should_decode_relative_parted_email
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issues_with_related_parts.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_match "Test text in the email body", issue.description
      assert issue.attachments.where(content_type: 'image/jpeg').first
    end
  end

  def test_should_decode_mixed_parted_email
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_with_mixed_encoding.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_match "html часть письма", issue.description
      assert issue.attachments.where(content_type: 'image/png').first
    end
  end

  def test_should_decode_inline_boundary_email
    with_helpdesk_settings('helpdesk_vote_accept' => 1) do
      ActionMailer::Base.deliveries.clear
      issue = submit_helpdesk_email('new_issue_with_inline_boundary_image.eml', :issue => { :project_id => 'onlinestore' })
      assert_equal Issue, issue.class
      assert !issue.new_record?
      issue.reload
      assert_equal ['24745661.png', 'Email.png'], issue.attachments.where(content_type: 'image/png').map(&:filename)
    end
  end

  private

  def uploaded_file(filename, mime)
    fixture_file_upload("../../plugins/redmine_contacts_helpdesk/test/fixtures/helpdesk_mailer/#{filename}", mime, true)
  end
end
