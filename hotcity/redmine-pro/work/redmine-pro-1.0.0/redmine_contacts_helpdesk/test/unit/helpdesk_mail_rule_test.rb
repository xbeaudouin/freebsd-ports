require File.expand_path('../../test_helper', __FILE__)
include RedmineHelpdesk::TestHelper

class HelpdeskMailRuleTest < ActiveSupport::TestCase
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
                                                                                                                             :helpdesk_tickets,
                                                                                                                             :helpdesk_mail_rules])

  DEFAULT_CONDITIONS = %w[contact contact_tags from_address message_body message_subject message_type]
  DEFAULT_CONDITIONS << 'issue_tags' if Redmine::Plugin.installed?(:redmineup_tags)
  DEFAULT_ACTIONS = %w[assignee customer_tags issue_status priority project]

  def setup
    RedmineHelpdesk::TestCase.prepare

    ActionMailer::Base.deliveries.clear
    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'http'

    @mail_rule = HelpdeskMailRule.find(1)
    @subject_rule = HelpdeskMailRule.find(3)
    @assignee_rule = HelpdeskMailRule.find(4)
  end

  def test_available_conditions
    assert_equal [], DEFAULT_CONDITIONS - @mail_rule.reload.available_conditions.keys
  end

  def test_available_conditions_as_json
    assert_equal [], DEFAULT_CONDITIONS - @mail_rule.reload.available_conditions_as_json.keys
  end

  def test_available_actions
    assert_equal [], DEFAULT_ACTIONS - @mail_rule.reload.available_actions.keys
  end

  def available_actions_as_json
    assert_equal [], DEFAULT_ACTIONS - @mail_rule.reload.available_actions_as_json.keys
  end

  def test_apply_to_suitable_mail
    ActionMailer::Base.deliveries.clear
    old_bcc = Setting.bcc_recipients
    Setting.bcc_recipients = '0'

    container = HelpdeskMailContainer.new(raw_helpdesk_email('new_with_email_rule_text.eml'), {})
    container.issue = Issue.find(1)
    container.contact = Contact.find(1)

    # Initial values
    assert_nil container.issue.assigned_to
    assert_equal 'New', container.issue.status.name
    assert_equal 'Low', container.issue.priority.name

    @mail_rule.apply_to(container)

    # Updated values
    assert_equal User.find(3), container.issue.assigned_to
    assert_equal 'Closed', container.issue.status.name
    assert_equal 'High', container.issue.priority.name
    assert last_email.to.include?(User.find(3).mail)
  ensure
    Setting.bcc_recipients = old_bcc
  end

  def test_apply_to_not_suitable_mail
    container = HelpdeskMailContainer.new(raw_helpdesk_email('reply_from_mail.eml'), {})
    container.issue = Issue.find(1)
    container.contact = Contact.find(1)

    # Initial values
    assert_nil container.issue.assigned_to
    assert_equal 'New', container.issue.status.name
    assert_equal 'Low', container.issue.priority.name

    @mail_rule.apply_to(container)

    # Updated values
    assert_nil container.issue.assigned_to
    assert_equal 'New', container.issue.status.name
    assert_equal 'Low', container.issue.priority.name
  end

  def test_subject_rule_for_mail
    container = HelpdeskMailContainer.new(raw_helpdesk_email('new_with_subject_rule_text.eml'), {})
    container.issue = Issue.find(1)
    container.contact = Contact.find(1)

    # Initial values
    assert_equal Project.find(1), container.issue.project
    assert_equal Tracker.find(1), container.issue.tracker

    @subject_rule.apply_to(container)

    # Updated values
    assert_equal Project.find(3), container.issue.project
    assert_equal Tracker.find(2), container.issue.tracker
  end

  def test_assignee_round_for_mail
    container = HelpdeskMailContainer.new(raw_helpdesk_email('new_with_subject_rule_text.eml'), {})
    container.issue = Issue.find(1)
    container.contact = Contact.find(1)

    assert_equal Issue.open.where(assigned_to_id: ['1','2','3']).group(:assigned_to_id).count(:id), { 2 => 1, 3 => 2 }
    @assignee_rule.apply_to(container)
    assert_equal Issue.open.where(assigned_to_id: ['1','2','3']).group(:assigned_to_id).count(:id), { 1 => 1, 2 => 1, 3 => 2 }
  end

  def test_subject_rule_for_mail
    container = HelpdeskMailContainer.new(raw_helpdesk_email('new_with_subject_rule_text.eml'), {})
    container.issue = Issue.find(1)
    container.contact = Contact.find(1)

    # Initial values
    assert_equal Project.find(1), container.issue.project
    assert_equal Tracker.find(1), container.issue.tracker

    @subject_rule.apply_to(container)

    # Updated values
    assert_equal Project.find(3), container.issue.project
    assert_equal Tracker.find(2), container.issue.tracker
  end

  def test_for_all_rule_for_mail
    for_all_rule = HelpdeskMailRule.create(user: User.current,
                                           mail_type: 0,
                                           conditions: { },
                                           actions: { "project" => { :values => ["2"] } })
    container_one = HelpdeskMailContainer.new(raw_helpdesk_email('new_issue_new_contact.eml'), {})
    container_two = HelpdeskMailContainer.new(raw_helpdesk_email('new_with_subject_rule_text.eml'), {})
    container_one.issue = Issue.find(1)
    container_one.contact = Contact.find(1)
    container_two.issue = Issue.find(2)
    container_two.contact = Contact.find(1)

    # Initial values
    assert_equal Project.find(1), container_one.issue.project
    assert_equal Project.find(1), container_two.issue.project

    for_all_rule.apply_to(container_one)
    for_all_rule.apply_to(container_two)

    # Updated values
    assert_equal Project.find(2), container_one.issue.project
    assert_equal Project.find(2), container_two.issue.project
  ensure
    for_all_rule.destroy
  end

  def test_stop_rule_for_mail
    container = HelpdeskMailContainer.new(raw_helpdesk_email('new_with_subject_rule_text.eml'), {})
    container.issue = Issue.find(1)
    container.contact = Contact.find(1)

    stop_rule = HelpdeskMailRule.create(user: User.current,
                                        mail_type: 0,
                                        conditions: { "message_subject" => { :operator => "~", :values => ["LETTER"] } },
                                        actions: { "stop" => { :operator => nil, :values => [] },
                                                   "assignee" => { :operator => nil, :values => ["1"] } }, position: 900)
    after_stop_rule = HelpdeskMailRule.create(user: User.current,
                                        mail_type: 0,
                                        conditions: { "message_subject" => { :operator => "~", :values => ["LETTER"] } },
                                        actions: { "assignee" => { :operator => nil, :values => ["2"] } }, position: 901)

    # Initial values
    assert_equal Project.find(1), container.issue.project
    assert_equal nil, container.issue.assigned_to

    HelpdeskMailRule.apply_rules(:incoming, container)

    # Updated values (assigned not applied)
    assert_equal Project.find(3), container.issue.project
    assert_equal User.find(1), container.issue.assigned_to
  ensure
    [stop_rule, after_stop_rule].each(&:destroy)
  end

  def test_apply_rule_not_first_in_list
    first_rule = HelpdeskMailRule.create(user: User.current,
                                         mail_type: 0,
                                         conditions: { 'from_address' => { operator: '~', values: ['@mail.ru']} },
                                         actions: { 'project' => { :values => ["3"] } })
    second_rule = HelpdeskMailRule.create(user: User.current,
                                          mail_type: 0,
                                          conditions: { 'from_address' => { operator: '~', values: ['somenet.foo']} },
                                          actions: { 'project' => { :values => ["2"] } })
    third_rule = HelpdeskMailRule.create(user: User.current,
                                         mail_type: 0,
                                         conditions: { 'from_address' => { operator: '~', values: ['@gmail.com']} },
                                         actions: { 'project' => { :values => ["3"] } })
    container = HelpdeskMailContainer.new(raw_helpdesk_email('new_issue_new_contact.eml'), {})
    container.issue = Issue.find(1)
    container.contact = Contact.find(1)

    # Initial values
    assert_equal Project.find(1), container.issue.project

    HelpdeskMailRule.apply_rules(:incoming, container)

    # Updated values
    assert_equal Project.find(2), container.issue.project
  ensure
    [first_rule, second_rule, third_rule].each(&:destroy)
  end

end
