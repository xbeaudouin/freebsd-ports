require 'redmine'

Redmine::Plugin.register :redmine_contacts_helpdesk do
  name "Redmine Helpdesk plugin (PRO version)"
  author 'RedmineUP'
  description 'This is a Helpdesk plugin for Redmine'
  version '4.1.10'
  url 'https://www.redmineup.com/pages/plugins/helpdesk'
  author_url 'mailto:support@redmineup.com'

  requires_redmine :version_or_higher => '2.6'

  begin
    requires_redmine_plugin :redmine_contacts, version_or_higher: '4.3.0'
  rescue Redmine::PluginNotFound  => e
    raise "Please install redmine_contacts plugin"
  end

  settings :default => {
    "helpdesk_answer_from" => '',
    "helpdesk_add_contact_notes" => '1',
    "helpdesk_answer_subject" => 'Re: {%ticket.subject%} [{%ticket.tracker%} #{%ticket.id%}]',
    "helpdesk_first_answer_subject" => '{%ticket.project%} support message [{%ticket.tracker%} #{%ticket.id%}]',
    "helpdesk_first_answer_template" => "Hello, {%contact.first_name%}\n\nWe hereby confirm that we have received your message.\n\nWe will handle your request and get back to you as soon as possible.\n\nYour request has been assigned the following case ID #\{%ticket.id%}.",
    "helpdesk_assign_contact_user" => 0,
    "helpdesk_create_private_tickets" => 0,
    "helpdesk_autoclose_tickets_time_unit" => 'day'
  }, :partial => 'settings/helpdesk'

  project_module :contacts_helpdesk do
     permission :view_helpdesk_tickets, :helpdesk => [:show_original],
                                        :canned_responses => [:add],
                                        :helpdesk_tickets => [:index, :show]
     permission :view_helpdesk_reports, :helpdesk_reports => [:show, :render_chart]
     permission :send_response, :issues => [:send_helpdesk_response, :email_note],
                                :helpdesk => [:show_original, :create_ticket, :delete_spam],
                                :journal_messages => [:create]
     permission :edit_helpdesk_settings, :helpdesk => [:save_settings, :get_mail]
     permission :edit_helpdesk_tickets, :helpdesk_tickets => [:create, :update, :edit, :destroy],
                                        :journal_messages => [:create]
     # Canned responses
     permission :manage_public_canned_responses, {:canned_responses => [:new, :create, :edit, :update, :destroy]}, :require => :member
     permission :manage_canned_responses, {:canned_responses => [:new, :create, :edit, :update, :destroy]}, :require => :loggedin
  end

  menu :admin_menu, :helpdesk, {:controller => 'settings', :action => 'plugin', :id => "redmine_contacts_helpdesk"}, :caption => :label_helpdesk, :param => :project_id, :html => {:class => 'icon'}

  activity_provider :helpdesk_tickets, :default => false, :class_name => ['HelpdeskTicket', 'JournalMessage']

end

require 'redmine_helpdesk'
