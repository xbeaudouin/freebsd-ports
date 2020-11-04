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
                                                                                                                    :contacts_projects,
                                                                                                                    :tags,
                                                                                                                    :taggings])

  RedmineHelpdesk::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_helpdesk).directory + '/test/fixtures/', [:journal_messages,
                                                                                                                             :helpdesk_tickets,
                                                                                                                             :helpdesk_mail_rules])

  def setup
    RedmineHelpdesk::TestCase.prepare
    User.current = User.find(1)

    @conditions_hash = {
      RedmineHelpdesk::MailRules::Conditions::Contact => { field: 'contact', values: [], label_for: ['1', 'Ivan Ivanov'] },
      RedmineHelpdesk::MailRules::Conditions::ContactTags => { field: 'contact_tags', values: [], label_for: ['1', nil] },
      RedmineHelpdesk::MailRules::Conditions::FromAddress => { field: 'from_address', values: nil, label_for: ['1', nil] },
      RedmineHelpdesk::MailRules::Conditions::MessageBody => { field: 'message_body', values: nil, label_for: ['1', nil] },
      RedmineHelpdesk::MailRules::Conditions::MessageSubject => { field: 'message_subject', values: nil, label_for: ['1', nil] },
      RedmineHelpdesk::MailRules::Conditions::MessageType => { field: 'message_type', values: [[I18n.t(:label_helpdesk_mail_rule_condition_message_type_new), '0'], [I18n.t(:label_helpdesk_mail_rule_condition_message_type_response), '1']], label_for: ['1', 'Response'] },
    }

    @conditions_hash.merge(RedmineHelpdesk::MailRules::Conditions::Tags => { field: 'tags', values: nil, label_for: [1, nil] }) if Redmine::Plugin.installed?(:redmineup_tags)

    @container = HelpdeskMailContainer.new(raw_helpdesk_email('new_with_email_rule_text.eml'), {})
    @container.issue = Issue.find(1)
    @container.contact = Contact.find(1)
    @container.is_new_issue = true

    if Redmine::Plugin.installed?(:redmineup_tags)
      @container.issue.tag_list = ['one']
      @container.issue.save(validate: false)
    end
  end

  def test_field
    @conditions_hash.each do |action_class, data|
      assert_equal true, data[:field] == action_class.new.field
    end
  end

  def test_values
    @conditions_hash.each do |action_class, data|
      assert_equal true, data[:values] == action_class.new.values
    end
  end

  def test_label_for
    @conditions_hash.each do |action_class, data|
      assert_equal true, data[:label_for].last == action_class.new.label_for({ values: [data[:label_for].first] })
    end
  end

  def test_contact_check
    assert_equal Contact.find(1), @container.contact
    condition = RedmineHelpdesk::MailRules::Conditions::Contact.new

    check_collection = [
      ['=', [1], true],
      ['=', [2], false],
      ['!*', [1], false],
      ['*', [2], true]
    ]

    check_collection.each do |data_set|
      assert_equal condition.check(@container, data_set[0], data_set[1]), data_set[2]
    end
  end

  def test_contact_tags_check
    assert_equal ['main'], @container.contact.tag_list
    condition = RedmineHelpdesk::MailRules::Conditions::ContactTags.new

    check_collection = [
      ['=', ['main'], true],
      ['=', ['main, two'], false],
      ['~', ['main'], true],
      ['!', ['two'], true],
      ['!', ['main'], false],
      ['*', ['two'], true]
    ]

    check_collection.each do |data_set|
      assert_equal condition.check(@container, data_set[0], data_set[1]), data_set[2]
    end
  end

  def test_from_address_check
    assert_equal 'new_customer@somenet.foo', @container.from_addr
    condition = RedmineHelpdesk::MailRules::Conditions::FromAddress.new

    check_collection = [
      ['=', ['new_customer@somenet.foo'], true],
      ['=', ['foo@bar.com'], false],
      ['~', ['somenet.foo'], true],
      ['!', ['foo@bar.com'], true],
      ['!~', ['new_customer'], false],
      ['!*', [''], false],
      ['*', [''], true]
    ]

    check_collection.each do |data_set|
      assert_equal condition.check(@container, data_set[0], data_set[1]), data_set[2]
    end
  end

  def test_message_body_check
    assert_equal true, @container.text_body.size > 0
    condition = RedmineHelpdesk::MailRules::Conditions::MessageBody.new

    check_collection = [
      ['~', ['Lorem ipsum dolor'], true],
      ['!~', ['Lorem ipsum dolor'], false],
      ['!*', [''], false],
      ['*', [''], true]
    ]

    check_collection.each do |data_set|
      assert_equal condition.check(@container, data_set[0], data_set[1]), data_set[2]
    end
  end

  def test_message_subject_check
    assert_equal 'New support issue from email', @container.email.subject
    condition = RedmineHelpdesk::MailRules::Conditions::MessageSubject.new

    check_collection = [
      ['=', ['New support issue from email'], true],
      ['=', ['New support issue'], false],
      ['~', ['New support issue from email'], true],
      ['~', ['New support issue'], true],
      ['!', ['Lorem ipsum dolor'], true],
      ['!~', ['Lorem'], true],
      ['!~', ['New'], false],
      ['!*', [''], false],
      ['*', [''], true]
    ]

    check_collection.each do |data_set|
      assert_equal condition.check(@container, data_set[0], data_set[1]), data_set[2]
    end
  end

  def test_message_type_check
    assert_equal true, @container.is_new_issue
    condition = RedmineHelpdesk::MailRules::Conditions::MessageType.new

    check_collection = [
      ['=', ['0'], true],
      ['=', ['1'], false],
      ['~', ['0'], false]
    ]

    check_collection.each do |data_set|
      assert_equal condition.check(@container, data_set[0], data_set[1]), data_set[2]
    end
  end

  def test_tags_check
    assert_equal ['one'], @container.issue.tag_list
    condition = RedmineHelpdesk::MailRules::Conditions::Tags.new

    check_collection = [
      ['=', ['one'], true],
      ['=', ['one, two'], false],
      ['~', ['one'], true],
      ['!', ['two'], true],
      ['!', ['one'], false],
      ['*', ['two'], true]
    ]

    check_collection.each do |data_set|
      assert_equal condition.check(@container, data_set[0], data_set[1]), data_set[2]
    end
  end if Redmine::Plugin.installed?(:redmineup_tags)
end
