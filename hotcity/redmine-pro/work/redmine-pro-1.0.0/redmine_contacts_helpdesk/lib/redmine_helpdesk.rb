dispatcher = Rails.version < '5.1' ? ActionDispatch::Callbacks : ActiveSupport::Reloader
dispatcher.to_prepare do
  require 'redmine_helpdesk/patches/action_controller_patch'
  require 'redmine_helpdesk/patches/issues_controller_patch'
  require 'redmine_helpdesk/patches/journals_controller_patch'
  require 'redmine_helpdesk/patches/attachments_controller_patch'
  require 'redmine_helpdesk/patches/issue_patch'
  require 'redmine_helpdesk/patches/journal_patch'
  require 'redmine_helpdesk/patches/contact_patch'
  require 'redmine_helpdesk/patches/issue_query_patch'
  require 'redmine_helpdesk/patches/time_report_patch'
  require 'redmine_helpdesk/patches/queries_helper_patch'
  require 'redmine_helpdesk/patches/projects_helper_patch'
  require 'redmine_helpdesk/patches/contacts_helper_patch'
  require 'redmine_helpdesk/patches/application_helper_patch'
  require 'redmine_helpdesk/patches/mail_handler_patch'
  require 'redmine_helpdesk/patches/compatibility_patch'
  require 'redmine_helpdesk/patches/contact_query_patch'
  require 'redmine_helpdesk/patches/settings_controller_patch'
  require 'redmine_helpdesk/patches/avatars_helper_patch'
  require 'redmine_helpdesk/patches/query_patch'
  require 'redmine_helpdesk/patches/journals_helper_patch'

  require 'redmine_helpdesk/hooks/view_layouts_hook'
  require 'redmine_helpdesk/hooks/view_issues_hook'
  require 'redmine_helpdesk/hooks/view_projects_hook'
  require 'redmine_helpdesk/hooks/view_contacts_hook'
  require 'redmine_helpdesk/hooks/view_journals_hook'
  require 'redmine_helpdesk/hooks/controller_contacts_duplicates_hook'
  require 'redmine_helpdesk/hooks/helper_issues_hook'
  require 'redmine_helpdesk/hooks/issues_controller_hook'

  require 'redmine_helpdesk/wiki_macros/helpdesk_wiki_macro'

  require 'redmine_helpdesk/patches/auto_completes_controller_patch'
  require 'redmine_helpdesk/patches/people_reports_user_activity_query_patch.rb'

  require 'redmine_helpdesk/patches/issues_helper_patch'

  Dir[File.dirname(__FILE__) + '/redmine_helpdesk/mail_rules/**/*.rb'].each { |f| require f }
end

class HelpdeskLogFormatter < Logger::Formatter
  def call(severity, time, _progname, msg)
    "[%s] - %s - %s\n" % [severity, time.to_s(:short), msg2str(msg)] unless msg2str(msg).blank?
  end
end

HelpdeskLogger = Logger.new(Rails.root.join('log/redmine_helpdesk.log'))
HelpdeskLogger.formatter = HelpdeskLogFormatter.new

class HelpdeskSettings
  MACRO_LIST = %w({%contact.first_name%} {%contact.name%} {%contact.company%} {%contact.last_name%}
                  {%contact.middle_name%} {%date%} {%ticket.assigned_to%} {%ticket.id%} {%ticket.tracker%}
                  {%ticket.project%} {%ticket.subject%} {%ticket.quoted_description%} {%ticket.history%} {%ticket.status%}
                  {%ticket.priority%} {%ticket.estimated_hours%} {%ticket.done_ratio%} {%ticket.public_url%} {%ticket.closed_on%} {%ticket.due_date%}
                  {%ticket.start_date%} {%ticket.voting%} {%ticket.voting.good%} {%ticket.voting.okay%} {%ticket.voting.bad%}
                  {%response.author%} {%response.author.first_name%} {%response.author.last_name%})

  FROM_MACRO_LIST = %w({%response.author%} {%response.author.first_name%})

  # Returns the value of the setting named name
  def self.[](name, project_id)
    project_id = project_id.id if project_id.is_a?(Project)
    project_id = project_id.to_i
    ContactsSetting[name.to_s, project_id].present? ? ContactsSetting[name.to_s, project_id] : RedmineHelpdesk.settings[name.to_s]
  end
end

module RedmineHelpdesk
  module ContactUserMethods
    def name(formatter = nil)
      f = self.class.name_formatter(formatter)
      if formatter
        eval('"' + f[:string] + '"')
      else
        @name ||= eval('"' + f[:string] + '"')
      end
    end
  end

  def self.settings() Setting['plugin_redmine_contacts_helpdesk'] ? Setting['plugin_redmine_contacts_helpdesk'] : {} end

  def self.settings=(options)
    Setting['plugin_redmine_contacts_helpdesk'] = settings.merge(options)
  end

  def self.public_title
    universal_setting('helpdesk_public_title')
  end

  def self.public_tickets?
    universal_setting('helpdesk_public_tickets').to_i > 0
  end

  def self.vote_allow?
    universal_setting('helpdesk_vote_accept').to_i > 0
  end
  def self.vote_comment_allow?
    universal_setting('helpdesk_vote_comment_accept').to_i > 0
  end

  def self.strip_tags?
    universal_setting('helpdesk_do_not_strip_tags').to_i <= 0
  end

  def self.public_comments?
    universal_setting('helpdesk_public_comments').to_i > 0
  end

  def self.public_spent_time?
    universal_setting('helpdesk_public_show_spent_time').to_i > 0
  end

  def self.save_log?
    universal_setting('helpdesk_vote_save_log').to_i > 0
  end

  def self.add_readmark?
    universal_setting('helpdesk_hide_read_marks').to_i == 0
  end

  def self.autoclose_tickets_after
    universal_setting('helpdesk_autoclose_tickets_after').to_i.abs
  end

  def self.autoclose_from_status
    universal_setting('helpdesk_autoclose_from_status').to_i
  end

  def self.autoclose_to_status
    universal_setting('helpdesk_autoclose_to_status').to_i
  end

  def self.autoclose_time_unit
    universal_setting('helpdesk_autoclose_tickets_time_unit')
  end

  def self.autoclose_time_unit_is?(value)
    autoclose_time_unit == value
  end

  def self.autoclose_time_interval
    case autoclose_time_unit
    when 'day'
      1.day * autoclose_tickets_after
    when 'hour'
      1.hour * autoclose_tickets_after
    else
      -1
    end
  end

  def self.add_widget_privacy_policy_checkbox?
    universal_setting('helpdesk_widget_add_privacy_policy_checkbox').to_i > 0
  end

  def self.widget_privacy_policy_checkbox_text
    universal_setting('helpdesk_widget_privacy_policy_checkbox_text').to_s
  end

  def self.add_plain_text_mail?
    universal_setting('plain_text_mail').to_i > 0
  end

  def self.create_private_tickets?
    universal_setting('helpdesk_create_private_tickets').to_i > 0
  end

  def self.show_contact_card?
    universal_setting('show_contact_card').to_i > 0
  end

  def self.last_message_count
    universal_setting('last_message_count').to_i
  end

  def self.answer_from
    universal_setting('helpdesk_answer_from').to_s
  end

  def self.assign_contact_user?
    universal_setting('helpdesk_assign_contact_user').to_i > 0
  end

  def self.universal_setting(setting)
    [settings[setting.to_sym], settings[setting.to_s]].compact.first
  end
end
