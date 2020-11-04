require File.expand_path('../../test_helper', __FILE__)
include RedmineHelpdesk::TestHelper

class HelpdeskTicketTest < ActiveSupport::TestCase
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

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages,
                                                                                                                             :helpdesk_tickets])

  def setup
    Setting.default_language = 'en'
    RedmineHelpdesk::TestCase.prepare

    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'
    Setting.plain_text_mail = '0'
  end

  def test_reaction_date
    agent = User.find(4)
    customer = Contact.find(1)

    ticket = HelpdeskTicket.where(:issue_id => 1).first
    ticket.customer = customer
    ticket.issue.journals = []

    journal = ticket.issue.journals.create(:user => agent, :notes => 'note')

    assert_equal journal.created_on.to_i, ticket.reaction_date.to_i
  end

  def test_reaction_date_is_calculated_from_the_first_journal
    agent = User.find(4)
    customer = Contact.find(1)

    ticket = HelpdeskTicket.where(:issue_id => 1).first
    ticket.customer = customer
    ticket.issue.journals = []

    first_journal = ticket.issue.journals.create(
      :user => agent,
      :notes => 'some note')
    second_journal = ticket.issue.journals.create(
      :user => agent,
      :notes => 'other note')

    assert_equal first_journal.created_on.to_i, ticket.reaction_date.to_i
  end

  def test_reaction_date_ignores_journals_from_customer
    agent = User.find(4)
    customer = Contact.find(1)

    customer_user = User.find(3)
    customer_user.mail = customer.email
    customer_user.save

    ticket = HelpdeskTicket.where(:issue_id => 1).first
    ticket.customer = customer
    ticket.issue.journals = []

    journal_from_customer = ticket.issue.journals.build(
      :user => customer.redmine_user,
      :notes => 'hello there')
    JournalMessage.create(
      :contact => customer,
      :journal => journal_from_customer,
      :message_date => journal_from_customer.created_on)

    journal_from_agent = ticket.issue.journals.create(
      :user => agent,
      :notes => 'hi')

    assert_equal journal_from_agent.created_on.to_i, ticket.reaction_date.to_i
  end

  def test_reaction_date_does_not_ignore_journals_without_notes
    agent = User.find(4)
    customer = Contact.find(1)

    ticket = HelpdeskTicket.where(:issue_id => 1).first
    ticket.customer = customer
    ticket.issue.journals = []

    journal_without_notes = ticket.issue.journals.build(:user => agent)
    journal_without_notes.details.build
    journal_without_notes.save

    journal_with_notes = ticket.issue.journals.create(
      :user => agent,
      :notes => 'some note')

    assert_equal journal_without_notes.created_on.to_i, ticket.reaction_date.to_i
  end

  def test_ticket_token
    helpdesk_ticket = HelpdeskTicket.find(1)
    first_user = User.find(1)
    second_user = User.find(2)
    second_user.pref['time_zone'] = 'Monterrey'

    User.current = first_user
    first_token = helpdesk_ticket.token
    User.current = second_user
    second_token = helpdesk_ticket.token

    assert_equal first_token, second_token
  end

  def test_should_change_default_destination_form_outgoing_email
    helpdesk_ticket = HelpdeskTicket.find(1)
    issue = helpdesk_ticket.issue
    other_contact = Contact.find(2)
    journal_message = issue.journals.order(:created_on).last.build_journal_message(:contact => other_contact,
                                                                                   :from_address => other_contact.primary_email,
                                                                                   :is_incoming => true,
                                                                                   :message_date => Time.now)
    journal_message.save
    helpdesk_ticket.reload

    assert_equal helpdesk_ticket.default_to_address, other_contact.primary_email

    journal_message = issue.journals.order(:created_on).last.build_journal_message(:contact => helpdesk_ticket.customer,
                                                                                   :from_address => helpdesk_ticket.customer.primary_email,
                                                                                   :is_incoming => true,
                                                                                   :message_date => Time.now)
    journal_message.save
    helpdesk_ticket.reload

    assert_equal helpdesk_ticket.default_to_address, helpdesk_ticket.customer.primary_email
  end

  def test_create_assigned_ticket
    user = User.find(2)
    contact = Contact.find(1)
    contact.assigned_to = user
    contact.save

    with_helpdesk_settings('helpdesk_assign_contact_user' => 1) do
      issue = submit_helpdesk_email('new_issue_to_contact.eml', :issue => { :project_id => 'onlinestore' })

      assert_not_nil issue
      assert_equal issue.is_private?, false
      assert_equal issue.assigned_to, user
    end
  end

  def test_create_private_assigned_ticket
    user = User.find(2)
    contact = Contact.find(1)
    contact.assigned_to = user
    contact.save

    with_helpdesk_settings('helpdesk_assign_contact_user' => 1, 'helpdesk_create_private_tickets' => 1) do
      issue = submit_helpdesk_email('new_issue_to_contact.eml', :issue => { :project_id => 'onlinestore' })

      assert_not_nil issue
      assert_equal issue.reload.is_private?, true
      assert_equal issue.reload.assigned_to, user
    end
  end

  def test_create_not_assigned_ticket_if_project_not_visible
    user = User.find(9)
    contact = Contact.find(2)
    contact.assigned_to = user
    contact.save

    with_helpdesk_settings('helpdesk_assign_contact_user' => 1, 'helpdesk_create_private_tickets' => 0) do
      issue = submit_helpdesk_email('new_issue_to_contact.eml', :issue => { :project_id => 'onlinestore' })

      assert_not_nil issue
      assert_equal issue.is_private?, false
      assert_nil issue.assigned_to
    end
  end

  def test_autoclose
    issue = Issue.find(1)
    initial_status = issue.status
    issue.status = IssueStatus.find(2)
    issue.created_on = issue.created_on - 2.hours
    issue.save!
    issue.reload
    status_to = IssueStatus.last
    with_helpdesk_settings('helpdesk_autoclose_tickets_after' => 1,
                           'helpdesk_autoclose_from_status' => issue.status_id,
                           'helpdesk_autoclose_to_status' => status_to.id,
                           'helpdesk_autoclose_tickets_time_unit' => 'hour',
                           'helpdesk_autoclose_subject' => 'Autoclose ticket with id: #{%ticket.id%}',
                           'helpdesk_autoclose_template' => 'Goodbye, {%contact.first_name%}') do
      HelpdeskTicket.autoclose(issue.project)
      issue.reload
      assert_equal status_to, issue.status

      mail = ActionMailer::Base.deliveries.detect { |m| m['X-Redmine-Ticket-ID'] }
      assert_equal mail.subject, "Autoclose ticket with id: ##{issue.id}"
      assert_mail_body_match "Goodbye, #{issue.customer.first_name}", mail
    end
  ensure
    issue.reload.update_attributes(status: initial_status)
  end

  def test_autoclose_for_journal_record
    issue = Issue.find(1)
    initial_status = issue.status
    second_status = IssueStatus.find(2)
    issue.status = second_status
    issue.created_on = issue.created_on - 2.hours
    issue.save!
    issue.reload
    journal = issue.journals.last
    initial_time = journal.created_on
    journal.created_on = Time.now - 0.5.hours
    journal.save!
    journal.reload
    status_to = IssueStatus.last
    with_helpdesk_settings('helpdesk_autoclose_tickets_after' => 1,
                           'helpdesk_autoclose_from_status' => second_status.id,
                           'helpdesk_autoclose_to_status' => status_to.id,
                           'helpdesk_autoclose_tickets_time_unit' => 'hour',
                           'helpdesk_autoclose_subject' => 'Autoclose ticket with id: #{%ticket.id%}',
                           'helpdesk_autoclose_template' => 'Goodbye, {%contact.first_name%}') do
      HelpdeskTicket.autoclose(issue.project)
      issue.reload
      assert_equal second_status, issue.status
    end
  ensure
    issue.update_attributes(:status => initial_status)
    journal.update_attributes(:created_on => initial_time)
  end

  def test_dont_autoclose_new_ticket
    issue = Issue.find(1).copy
    # change status
    issue.status = IssueStatus.find(2)
    issue.save!
    status_to = IssueStatus.last
    with_helpdesk_settings('helpdesk_autoclose_tickets_after' => 1,
                           'helpdesk_autoclose_from_status' => issue.status_id,
                           'helpdesk_autoclose_to_status' => status_to.id,
                           'helpdesk_autoclose_tickets_time_unit' => 'hour',
                           'helpdesk_autoclose_subject' => 'Autoclose ticket with id: #{%ticket.id%}',
                           'helpdesk_autoclose_template' => 'Goodbye, {%contact.first_name%}') do
      HelpdeskTicket.autoclose(issue.project)
      issue.reload
      assert status_to != issue.status
    end
  end

  def test_autoclose_off
    issue = Issue.find(1)
    initial_status = issue.status
    issue.status = IssueStatus.find(2)
    issue.save
    issue.reload
    status_to = IssueStatus.last
    with_helpdesk_settings('helpdesk_autoclose_tickets_after' => nil,
                           'helpdesk_autoclose_from_status' => issue.status_id,
                           'helpdesk_autoclose_to_status' => status_to.id,
                           'helpdesk_autoclose_tickets_time_unit' => 'hour',
                           'helpdesk_autoclose_subject' => 'Autoclose ticket with id: #{%ticket.id%}',
                           'helpdesk_autoclose_template' => 'Goodbye, {%contact.first_name%}') do
      HelpdeskTicket.autoclose(issue.project)
      issue.reload
      assert status_to != issue.status
    end
  ensure
    issue.update_attributes(:status => initial_status)
  end
end
