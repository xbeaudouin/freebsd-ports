require File.expand_path('../../test_helper', __FILE__)
include RedmineHelpdesk::TestHelper

class HelpdeskMailRuleActionsTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :journals,
           :journal_details,
           :queries

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages,
                                                                                                                             :helpdesk_tickets,
                                                                                                                             :helpdesk_mail_rules])

  def setup
    RedmineHelpdesk::TestCase.prepare
    User.current = User.find(1)

    @actions_hash = {
      RedmineHelpdesk::MailRules::Actions::Assignee => { field: 'assignee', values: [], label_for: [1, 'Redmine Admin'] },
      RedmineHelpdesk::MailRules::Actions::CustomerTags => { field: 'customer_tags', values: [], label_for: [1, nil] },
      RedmineHelpdesk::MailRules::Actions::IssuePriority => { field: 'priority', values: IssuePriority.all.map { |priority| [priority.name, priority.id.to_s] }, label_for: ['6', 'High'] },
      RedmineHelpdesk::MailRules::Actions::IssueStatus => { field: 'issue_status', values: IssueStatus.all.map { |status| [status.name, status.id.to_s] }, label_for: ['2', 'Assigned'] },
      RedmineHelpdesk::MailRules::Actions::Project => { field: 'project', values: Project.visible.has_module('contacts_helpdesk').map { |project| [project.name, project.id.to_s] }, label_for: ['1', 'eCookbook'] }
    }

    @actions_hash.merge(RedmineHelpdesk::MailRules::Actions::Tags => { field: 'tags', values: nil, label_for: [1, nil] }) if Redmine::Plugin.installed?(:redmineup_tags)

    @container = HelpdeskMailContainer.new(raw_helpdesk_email('new_with_email_rule_text.eml'), {})
    @container.issue = Issue.find(1)
    @container.contact = Contact.find(1)
  end

  def test_field
    @actions_hash.each do |action_class, data|
      assert_equal data[:field], action_class.new.field
    end
  end

  def test_values
    @actions_hash.each do |action_class, data|
      assert_equal data[:values], action_class.new.values
    end
  end

  def test_label_for
    @actions_hash.each do |action_class, data|
      assert_equal data[:label_for].last, action_class.new.label_for({ values: [data[:label_for].first] })
    end
  end

  def test_assignee_apply
    assert_not_equal @container.issue.assigned_to, User.find(2)
    RedmineHelpdesk::MailRules::Actions::Assignee.new.apply(@container, '', ['2'])
    assert_equal @container.issue.assigned_to, User.find(2)
  end

  def test_contact_tags_apply
    assert_not_equal @container.contact.tags.pluck(:name).sort, ['test_tag', 'another']
    RedmineHelpdesk::MailRules::Actions::CustomerTags.new.apply(@container, '', ['test_tag, another'])
    assert_equal true, ['another', 'test_tag'].all? { |tag| @container.contact.tags.pluck(:name).include?(tag) }
  end

  def test_priority_apply
    assert_not_equal @container.issue.priority, IssuePriority.find(6)
    RedmineHelpdesk::MailRules::Actions::IssuePriority.new.apply(@container, '', ['6'])
    assert_equal @container.issue.priority, IssuePriority.find(6)
  end

  def test_issue_status_apply
    assert_not_equal @container.issue.status, IssueStatus.find(2)
    RedmineHelpdesk::MailRules::Actions::IssueStatus.new.apply(@container, '', ['2'])
    assert_equal @container.issue.status, IssueStatus.find(2)
  end

  def test_contact_tags_apply
    assert_not_equal @container.issue.tags.pluck(:name).sort, ['test_tag', 'another']
    RedmineHelpdesk::MailRules::Actions::Tags.new.apply(@container, '', ['test_tag, another'])
    assert_equal true, ['another', 'test_tag'].all? { |tag| @container.issue.tags.pluck(:name).include?(tag) }
  end if Redmine::Plugin.installed?(:redmineup_tags)

  def test_due_date_apply
    actions_due_date_operators_hash = {
      '=' => ['2019-09-20', Date.parse('2019-09-20')],
      't' => ['', Date.today],
      'nd' => ['', Date.tomorrow],
      'da' => ['3', Date.today + 3.days]
    }

    actions_due_date_operators_hash.each do |operator, data|
      assert_not_equal @container.issue.due_date, data.last
      RedmineHelpdesk::MailRules::Actions::DueDate.new.apply(@container, operator, [data.first])
      assert_equal @container.issue.due_date, data.last
    end
  end

  def test_issue_tracker_apply
    assert_not_equal @container.issue.tracker, Tracker.find(2)
    RedmineHelpdesk::MailRules::Actions::IssueTracker.new.apply(@container, '', ['2'])
    assert_equal @container.issue.tracker, Tracker.find(2)
  end

  def test_stop_apply
    assert_equal false, RedmineHelpdesk::MailRules::Actions::Stop.new.apply(@container, '', [''])
  end

  def test_issue_watchers_apply
    assert_equal [], @container.issue.watchers
    RedmineHelpdesk::MailRules::Actions::Watchers.new.apply(@container, '', ['1', '2'])
    assert_equal [1, 2], @container.issue.watcher_users.map(&:id).sort
  end
end
