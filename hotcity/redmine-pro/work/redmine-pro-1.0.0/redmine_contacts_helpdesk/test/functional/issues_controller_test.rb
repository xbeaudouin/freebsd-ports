require File.expand_path('../../test_helper', __FILE__)

# Re-raise errors caught by the controller.
# class HelpdeskMailerController; def rescue_action(e) raise e end; end

class IssuesControllerTest < ActionController::TestCase
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

  include RedmineHelpdesk::TestHelper

  def setup
    RedmineHelpdesk::TestCase.prepare
    ActionMailer::Base.deliveries.clear
    User.current = nil
  end

  def test_show_issue
    issue = Issue.find(1)
    assert_not_nil issue.helpdesk_ticket
    compatible_request :get, :show, :id => 1
    assert_response :success
  end

  def test_show_reply_to_for_issue_with_ticket
    @request.session[:user_id] = 1
    issue = Issue.find(1)
    assert_not_nil issue.helpdesk_ticket
    compatible_request :get, :show, :id => issue.id
    assert_response :success
    assert_equal response.body.match('Reply').size, 1
  end

  def test_show_reply_to_for_issue_without_ticket
    @request.session[:user_id] = 1
    issue = Issue.find(3)
    assert_nil issue.helpdesk_ticket
    compatible_request :get, :show, :id => issue.id
    assert_response :success
    assert_nil response.body.match('Reply')
  end

  def test_get_index_with_filters
    ticket = HelpdeskTicket.find(1)
    ticket.save

    @request.session[:user_id] = 1
    compatible_request :get, :index, :set_filter => '1', :f => ['ticket_reaction_time', ''], :op => { 'ticket_reaction_time' => '>=' },
                                     :v => { 'ticket_reaction_time' => ['10'] },
                                     :c => ['customer', 'ticket_source', 'customer_company', 'helpdesk_ticket', 'ticket_reaction_time', 'ticket_first_response_time', 'ticket_resolve_time'],
                                     :project_id => 'ecookbook'
    assert_response :success
  end

  def test_get_vote_issues
    ticket = HelpdeskTicket.find(1)
    ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')

    @request.session[:user_id] = 1
    compatible_request :get, :index, :set_filter => '1', :f => ['vote', ''], :op => { 'vote' => '*' }, :c => ['tracker', 'vote', 'vote_comment'],
                                     :project_id => 'ecookbook'
    assert_response :success
    assert_select 'table.list.issues td.vote span', /Just ok/
    assert_select 'table.list.issues td.vote_comment p', /Good/
  end

  def test_get_not_vote_issues
    ticket = HelpdeskTicket.find(1)
    ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')

    @request.session[:user_id] = 1
    compatible_request :get, :index, :set_filter => '1', :f => ['vote', ''], :op => { 'vote' => '!*' }, :c => ['tracker', 'vote', 'vote_comment'],
                                     :project_id => 'ecookbook'
    assert_response :success
    assert_select 'table.list.issues td.vote', ''
  end

  def test_get_only_bad_voted_issues
    ticket = HelpdeskTicket.find(1)
    ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')
    ticket = HelpdeskTicket.find(2)
    ticket.update_attributes(:vote => 0, :vote_comment => 'Bad!')

    @request.session[:user_id] = 1
    compatible_request :get, :index, :set_filter => '1', :f => ['vote', ''], :op => { 'vote' => '=' }, :v => { 'vote' => ['0'] }, :c => ['tracker', 'vote', 'vote_comment'],
                                   :project_id => 'ecookbook'
    assert_response :success
    assert_select 'table.list.issues td.vote span', /Not good/
    assert_select 'table.list.issues td.vote_comment p', /Bad/
    assert_select 'table.list.issues td.vote span' do |votes|
      votes.each do |vote|
        assert_match /^((?!Just ok).)*/, vote.to_s
      end
    end
  end

  def test_get_tickets_as_csv
    with_contacts_settings 'contact_name_format' => :lastname_firstname do
      ticket = HelpdeskTicket.find(1)
      ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')
      ticket = HelpdeskTicket.find(2)
      ticket.update_attributes(:vote => 0, :vote_comment => 'Bad!')

      @request.session[:user_id] = 1
      compatible_request :get, :index, :set_filter => '1', :f => ['vote', ''], :op => { 'vote' => '=' }, :v => { 'vote' => ['1', '0'] },
                                       :c => ['tracker', 'vote', 'vote_comment', 'last_message', 'last_message_date', 'customer', 'ticket_source', 'customer_company', 'helpdesk_ticket_relation', 'ticket_reaction_time', 'ticket_first_response_time', 'ticket_resolve_time'],
                                       :project_id => 'ecookbook',
                                       :format => 'csv'
      assert_response :success
      assert_not_nil issues_in_list
      assert_match 'text/csv', @response.content_type
      assert @response.body.starts_with?('#,')
      assert @response.body.include?('Ticket: ')
      assert @response.body.include?('Marat Aminov')
    end
  end

  def test_get_tickets_as_pdf
    ticket = HelpdeskTicket.find(1)
    ticket.update_attributes(:vote => 1, :vote_comment => 'Good!')
    ticket = HelpdeskTicket.find(2)
    ticket.update_attributes(:vote => 0, :vote_comment => 'Bad!')

    @request.session[:user_id] = 1
    compatible_request :get, :index, :set_filter => '1', :f => ['vote', ''], :op => { 'vote' => '=' }, :v => { 'vote' => ['1', '0'] },
                                     :c => ['tracker', 'vote', 'vote_comment', 'last_message', 'last_message_date', 'customer', 'ticket_source', 'customer_company', 'helpdesk_ticket_relation', 'ticket_reaction_time', 'ticket_first_response_time', 'ticket_resolve_time'],
                                     :project_id => 'ecookbook',
                                     :format => 'pdf'
    assert_response :success
    assert_not_nil issues_in_list
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
  end

  def test_should_send_note
    user = User.find(1)
    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 1 }, :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
  end

  def test_should_not_send_note_with_zero_param
    user = User.find(1)
    @request.session[:user_id] = 1
    notes = "Not send"
    # anonymous user
    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 0 }, :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'

    j = Journal.order('id DESC').first
    assert_equal "Not send", j.notes
    assert_equal nil, j.is_send_note
    assert_equal User.find(1), j.user

    assert last_ticket_mail.nil?
  end


  def test_should_calculate_metrics
    @request.session[:user_id] = 1

    issue = Issue.find(1)
    issue.journals.destroy_all

    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 1 }, :issue => { :notes => 'Response to customer' }

    issue.reload
    assert_not_nil issue.helpdesk_ticket.first_response_time
    assert_equal (issue.helpdesk_ticket.reaction_time - issue.helpdesk_ticket.first_response_time) < 100, true
  end

  def test_should_forward_note
    user = User.find(1)
    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 1 },
                                      :journal_message => { :to_address => ['jsmith@somenet.foo'] }, :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_match "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user
    assert_equal Contact.find(4), j.journal_message.contact

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal 'jsmith@somenet.foo', mail.to.first
  end

  def test_should_send_note_with_bcc
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                               :issue => issue,
                                               :from_address => contact.primary_email,
                                               :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 1 }, :journal_message => { :bcc_address => ['mail1@mail.com', 'mail2@mail.com'] },
                                      :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
    assert_equal ['mail1@mail.com', 'mail2@mail.com'].sort, mail.bcc.sort
  end

  def test_should_not_send_note_with_cc
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                               :issue => issue,
                                               :from_address => contact.primary_email,
                                               :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 1 }, :journal_message => { :cc_address => ['mail3@mail.com', 'mail4@mail.com'] },
                                      :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
    assert_equal ['mail3@mail.com', 'mail4@mail.com'].sort, mail.cc.sort
    assert mail.bcc.empty?, 'Bcc should be empty'
  end

  def test_should_send_note_with_attachments
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                               :issue => issue,
                                               :from_address => contact.primary_email,
                                               :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = user.id
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 1 }, :issue => { :notes => notes },
                                      :attachments => { '1' => { 'file' => helpdesk_uploaded_file('attachment.zip', 'application/octet-stream') } }
    mail = last_ticket_mail
    assert_not_nil mail.attachments
    assert_equal 3855, mail.attachments.first.decoded.size
  end

  def test_should_send_private_note_with_attachments
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                               :issue => issue,
                                               :from_address => contact.primary_email,
                                               :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = user.id
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 1 }, :issue => { :notes => notes, :private_notes => 1 },
                                      :attachments => { '1' => { 'file' => helpdesk_uploaded_file('attachment.zip', 'application/octet-stream') } }
    assert_equal issue.reload.journals.last.private_notes, true
    mail = last_ticket_mail
    assert_not_nil mail.attachments
    assert_equal 3855, mail.attachments.first.decoded.size
  end

  def test_should_send_note_issue_from_anonymous
    issue = Issue.find(1)
    issue.author_id = 6
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                               :issue => issue,
                                               :from_address => contact.primary_email,
                                               :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Hello, %%NAME%%\r\n Bye, %%NOTE_AUTHOR.FIRST_NAME%%"
    # anonymous user
    compatible_request :put, :update, :id => 1, :helpdesk => { :is_send_mail => 1 }, :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal "Hello, Ivan\r\n Bye, #{user.firstname}", j.notes
    assert_equal 0, j.details.size
    assert_equal User.find(1), j.user

    mail = last_ticket_mail
    assert_mail_body_match "Hello, Ivan\r\n Bye, #{user.firstname}", mail
    assert_equal Issue.find(1).customer.primary_email, mail.to.first
  end

  def test_should_create_ticket
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    contact = Contact.find(2)
    assert_difference 'HelpdeskTicket.count' do
      compatible_request :post, :create, issue: { tracker_id: 3, subject: 'test', status_id: 2, priority_id: 5,
                                                  helpdesk_ticket_attributes: { source: '0', ticket_date: '2013-01-01 01:01:01 +0400', contact_id: contact.id } },
                                         project_id: project
    end
    assert_redirected_to controller: 'issues', action: 'show', id: Issue.last.id
    assert_not_nil Issue.last.helpdesk_ticket
    assert_equal contact.emails.first, Issue.last.helpdesk_ticket.from_address
  end

  def test_should_create_ticket_for_non_primary_email
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    contact = Contact.find(2)
    assert_difference 'HelpdeskTicket.count' do
      compatible_request :post, :create, issue: { tracker_id: 3, subject: 'test', status_id: 2, priority_id: 5,
                                                  helpdesk_ticket_attributes: { source: '0', ticket_date: '2013-01-01 01:01:01 +0400' } },
                                         customer_address: contact.emails.last,
                                         project_id: project
    end
    assert_redirected_to controller: 'issues', action: 'show', id: Issue.last.id
    assert_not_nil Issue.last.helpdesk_ticket
    assert_not_equal contact.emails.last, contact.primary_email
    assert_equal contact.emails.last, Issue.last.helpdesk_ticket.from_address
  end

  def test_should_send_auto_answer
    @request.session[:user_id] = 1
    contact = Contact.find(1)
    assert_difference 'HelpdeskTicket.count' do
      compatible_request :post, :create, issue: { tracker_id: 3, subject: 'test', status_id: 2, priority_id: 5, description: 'test description',
                                                  helpdesk_ticket_attributes: { source: '0', ticket_date: '2013-01-01 01:01:01 +0400', contact_id: contact.id } },
                                         helpdesk_send_as: HelpdeskTicket::SEND_AS_NOTIFICATION,
                                         project_id: 1
    end
    mail = last_ticket_mail
    assert_mail_body_match 'We hereby confirm that we have received your message', mail
  end

  def test_should_send_initial_message
    with_helpdesk_settings('helpdesk_first_answer_subject' => 'Message for ticket id: #{%ticket.id%}') do
      @request.session[:user_id] = 1
      contact = Contact.find(1)
      assert_difference 'HelpdeskTicket.count' do
        compatible_request :post, :create, issue: { tracker_id: 3, subject: 'test', status_id: 2, priority_id: 5, description: 'test initial description',
                                                    helpdesk_ticket_attributes: { source: '0', ticket_date: '2013-01-01 01:01:01 +0400', contact_id: contact.id } },
                                           helpdesk_send_as: HelpdeskTicket::SEND_AS_MESSAGE,
                                           project_id: 1
      end
      mail = last_ticket_mail
      assert_mail_body_match 'test initial description', mail
      assert_equal mail.subject, "Message for ticket id: \##{Issue.maximum(:id)}"
      assert_equal HelpdeskTicket.order('id ASC').last.message_id, mail.message_id
      assert_equal false, HelpdeskTicket.order('id ASC').last.is_incoming
    end
  end

  def test_should_send_initial_message_to_second_email
    @request.session[:user_id] = 1
    contact = Contact.find(1)
    contact.update_attributes(email: contact.email + ',second@email.com')
    assert_difference 'HelpdeskTicket.count' do
      compatible_request :post, :create, issue: { tracker_id: 3, subject: 'test', status_id: 2, priority_id: 5, description: 'test initial description',
                                                  helpdesk_ticket_attributes: { source: '0', ticket_date: '2013-01-01 01:01:01 +0400', contact_id: contact.id } },
                                         helpdesk_send_as: HelpdeskTicket::SEND_AS_MESSAGE,
                                         customer_address: contact.emails.last,
                                         project_id: 1
    end
    mail = last_ticket_mail
    assert_mail_body_match 'test initial description', mail
    assert_equal HelpdeskTicket.order('id ASC').last.message_id, mail.message_id
    assert_equal ['second@email.com'], mail.to
  end

  def test_should_not_create_ticket_for_invalid_issue
    @request.session[:user_id] = 1
    ActionMailer::Base.deliveries.clear
    compatible_request :put, :update, id: 1, helpdesk: { is_send_mail: 1 }, issue: { notes: 'Test notes', subject: '' }
    assert_equal ActionMailer::Base.deliveries, []
  end

  def test_should_not_create_ticket_with_empty_customer
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    assert_no_difference 'HelpdeskTicket.count' do
      compatible_request :post, :create, issue: { tracker_id: 3, subject: 'Test subject', status_id: 2, priority_id: 5,
                                                  helpdesk_ticket_attributes: { source: '0', ticket_date: '2013-01-01 01:01:01 +0400' } },
                                         project_id: project
      if ActiveRecord::VERSION::MAJOR >= 4
        assert_select 'div#errorExplanation', /customer cannot be blank/i
      else
        assert_error_tag content: /helpdesk_ticket.customer can&#x27;t be blank/i
      end
    end
  end

  def test_put_update_form
    if ActiveRecord::VERSION::MAJOR < 4
      @request.session[:user_id] = 1
      issue = Issue.find(1)
      ContactsSetting['helpdesk_tracker', issue.project.id] = 2
      compatible_xhr_request :put, :update_form, issue: { tracker_id: 2, helpdesk_ticket_attributes: { contact_id: 3, source: HelpdeskTicket::HELPDESK_PHONE_SOURCE } },
                                                 helpdesk_send_as: HelpdeskTicket::SEND_AS_MESSAGE,
                                                 project_id: issue.project
      assert_response :success
      assert_equal 'text/javascript', response.content_type
      assert_template 'update_form'

      issue = assigns(:issue)
      assert_kind_of Issue, issue
      assert_equal 3, issue.helpdesk_ticket.customer.id
      assert_equal HelpdeskTicket::HELPDESK_PHONE_SOURCE, issue.helpdesk_ticket.source
    end
  end

  def test_should_set_from_field_for_ticket
    @request.session[:user_id] = 1
    project = Project.find('ecookbook')
    contact = Contact.find(1)
    assert_difference 'HelpdeskTicket.count' do
      compatible_request :post, :create, issue: { tracker_id: 3, subject: 'test_for_field', status_id: 2, priority_id: 5,
                                                  helpdesk_ticket_attributes: { contact_id: contact.id, source: '0', ticket_date: '2013-01-01 01:01:01 +0400' } },
                                         project_id: project
    end
    assert_not_nil Issue.last.helpdesk_ticket
    assert_equal Issue.last.helpdesk_ticket.from_address, contact.primary_email
  end

  def test_should_send_note_without_to
    issue = Issue.find(1)
    contact = Contact.find(1)
    user = User.find(1)
    issue.helpdesk_ticket = HelpdeskTicket.new(:customer => contact,
                                               :issue => issue,
                                               :from_address => contact.primary_email,
                                               :ticket_date => Time.now)
    issue.save!

    @request.session[:user_id] = 1
    notes = "Empty to-address"

    compatible_request :put, :update, id: 1, helpdesk: { is_send_mail: 1 }, journal_message: { to_address: [''],
                                                                                               cc_address: ['cc@mail.com'],
                                                                                               bcc_address: ['bcc@mail.com'] },
                                             issue: { notes: notes }
    mail = last_ticket_mail
    assert_mail_body_match "Empty to-address", mail
    assert_nil mail.to.first
    assert_equal ['cc@mail.com'], mail.cc
    assert_equal ['bcc@mail.com'], mail.bcc
  end

  def test_should_build_new_ticket_for_customer
    @request.session[:user_id] = 1
    contact = Contact.find(1)
    tracker = Tracker.find(1)
    project = Project.find('ecookbook')
    compatible_request :get, :new, project_id: project.id, customer_id: contact.id, tracker_id: tracker.id

    assert_response :success
    assert_match 'New issue', @response.body
  end

  def test_should_build_new_ticket_for_customer_without_tracket_attr
    @request.session[:user_id] = 1
    contact = Contact.find(1)
    tracker = Tracker.find(1)
    project = Project.find('ecookbook')
    compatible_request :get, :new, project_id: project.id, customer_id: contact.id

    assert_response :success
    assert_match 'New issue', @response.body
  end

  def test_should_create_contact_on_reply
    @request.session[:user_id] = 1
    notes = "Notes to another contact"
    compatible_request :put, :update, id: 1, helpdesk: { is_send_mail: 1 },
                                             journal_message: { to_address: ['not_exists@email.com'] },
                                             issue: { notes: notes }
    assert_redirected_to action: 'show', id: '1'
    last_journal = Journal.order('id DESC').first
    last_contact = Contact.order('id DESC').first
    assert_equal notes, last_journal.notes
    assert_equal last_contact, last_journal.contact
    assert_equal 'not_exists@email.com', last_contact.email

    mail = last_ticket_mail
    assert_mail_body_match notes, mail
    assert_equal 'not_exists@email.com', mail.to.first
  end

  private

  def last_ticket_mail
    ActionMailer::Base.deliveries.detect { |m| m['X-Redmine-Ticket-ID'] }
  end
end
