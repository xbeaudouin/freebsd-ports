require 'digest/md5'
class HelpdeskMailSupport < MailHandler
  URL_HELPER = Rails.application.routes.url_helpers

  class << self

    if Redmine::VERSION.to_s < '3.1'
      def html_body_to_text(html)

        # strip html tags and remove doctype directive
        html.gsub! %r{^[ ]+}, ''
        if RedmineHelpdesk.strip_tags?
          html.gsub! %r{<head>(?:.|\n|\r)+?<\/head>}, ''
          html.gsub! %r{<\/(li|ol|ul|h1|h2|h3|h4)>}, "\r\n"
          html.gsub! %r{<\/(p|div|pre)>}, "\r\n\r\n"
          html.gsub! %r{<li>}, '  - '
          html.gsub! %r{<br[^>]*>}, "\r\n"
          html.sub! %r{^<!DOCTYPE .*$}, ''
          html.strip
        end
      end

      def plain_text_body_to_text(text)
        text.gsub(/^ +(?![*#])/, '')
      end
    end

    def ignored_helpdesk_headers
      helpdesk_headers = {
        'X-Auto-Response-Suppress' => /\A(all|AutoReply|oof)/
      }
      ignored_emails_headers.merge(helpdesk_headers)
    end

    def options_for_check(project_id, options = {})
      [
        provider_options(project_id).merge(common_options(project_id)),
        options.merge(issue_options({}, project_id))
      ]
    end

    def issue_options(options, project_id)
      options = { :issue => {} } unless options[:issue]
      options[:issue][:project_id] = project_id
      options[:issue][:status_id] ||= HelpdeskSettings[:helpdesk_new_status, project_id]
      options[:issue][:assigned_to_id] ||= HelpdeskSettings[:helpdesk_assigned_to, project_id]
      options[:issue][:tracker_id] ||= HelpdeskSettings[:helpdesk_tracker, project_id]
      options[:issue][:priority_id] ||= HelpdeskSettings[:helpdesk_issue_priority, project_id]
      options[:issue][:due_date] ||= HelpdeskSettings[:helpdesk_issue_due_date, project_id]
      options[:issue][:reopen_status_id] ||= HelpdeskSettings[:helpdesk_reopen_status, project_id]
      options
    end

    def check_ignored_headers?(email, logger = nil)
      ignored_helpdesk_headers.each do |key, ignored_value|
        value = email.header[key].to_s.downcase
        next if value.blank?
        if (ignored_value.is_a?(Regexp) && value.match(ignored_value)) || value == ignored_value
          logger.try(:info, "#{email.message_id}: ignoring email with #{key}:#{value} header")
          return true
        end
      end
      false
    end

    def check_blacklist?(email, project)
      return false if HelpdeskSettings['helpdesk_blacklist', project].blank?
      cond = '(' + HelpdeskSettings['helpdesk_blacklist', project].split("\n").map { |u| u.strip if u.present? }.compact.join('|') + ')'
      !!email.match(cond)
    end

    def create_contact_from_address(addr, fullname, project, logger = nil)
      contacts = Contact.find_by_emails([addr])
      if contacts.present?
        contact = contacts.first
        if contact.projects.blank? || HelpdeskSettings['helpdesk_add_contact_to_project', project].to_i > 0
          contact.projects << project
          contact.save!
        end
        return contact
      end

      if HelpdeskSettings['helpdesk_is_not_create_contacts', project].to_i > 0
        logger.try(:error, "#{email.message_id}: can't find contact with email: #{addr} in whitelist. Not create new contacts option enable")
        nil
      else
        contact = contact_from_attributes(addr, fullname)
        contact.projects << project
        contact.tag_list = HelpdeskSettings['helpdesk_created_contact_tag', project] if HelpdeskSettings['helpdesk_created_contact_tag', project]

        if contact.save
          contact
        else
          logger.try(:error, "Helpdeks MailHandler: failed to create Contact: #{contact.errors.full_messages}")
          nil
        end
      end
    end

    def convert_to_utf8(str, encoding = 'UTF-8')
      return str if str.nil?
      if str.respond_to?(:force_encoding)
        begin
          cleaned = str.force_encoding('UTF-8')
          cleaned = cleaned.encode('UTF-8', encoding) if encoding.upcase == 'ISO-2022-JP'
          unless cleaned.valid_encoding?
            cleaned = str.encode('UTF-8', encoding, :invalid => :replace, :undef => :replace, :replace => '').chars.select { |i| i.valid_encoding? }.join
          end
          str = cleaned
        rescue EncodingError
          str.encode!('UTF-8', :invalid => :replace, :undef => :replace)
        end
      elsif RUBY_PLATFORM == 'java'
        begin
          ic = Iconv.new('UTF-8', encoding + '//IGNORE')
          str = ic.iconv(str)
        rescue
          str = str.gsub(%r{[^\r\n\t\x20-\x7e]}, '?')
        end
      else
        ic = Iconv.new('UTF-8', encoding + '//IGNORE')
        txtar = ''
        begin
          txtar += ic.iconv(str)
        rescue Iconv::IllegalSequence
          txtar += $!.success
          str = '?' + $!.failed[1, $!.failed.length]
          retry
        rescue
          txtar += $!.success
        end
        str = txtar
      end
      str
    end

    def escaped_cleaned_up_text_body(email)
      text_body = new.substitution_method(:cleaned_up_text_body, email)
      return text_body if (ActiveRecord::Base.connection.adapter_name =~ /mysql/i).blank?
      text_body.gsub(/./) { |c| c.bytesize == 4 ? ' ' : c }
    end

    def extract_from_text!(text, attr, user, format = nil)
      new.substitution_method(:extract_keyword!, nil, user, text, attr, format)
    end

    def attachment_digest(file_source)
      encoder = Redmine::VERSION.to_s >= '3.4' || RedmineContacts.unstable_branch? ? Digest::SHA256.new : Digest::MD5.new
      encoder.update(file_source)
      encoder.hexdigest
    end

    def attachment_acceptable?(attachment)
      new.send(:accept_attachment?, attachment)
    end

    def apply_text_macro(text, contact, issue, journal_user = nil)
      return '' if text.blank?
      text = text.gsub(/%%NAME%%|\{%contact.first_name%\}/, contact.first_name)
      text = text.gsub(/%%FULL_NAME%%|\{%contact.name%\}/, contact.name)
      text = text.gsub(/%%COMPANY%%|\{%contact.company%\}/, contact.company) if contact.company
      text = text.gsub(/%%LAST_NAME%%|\{%contact.last_name%\}/, contact.last_name.to_s)
      text = text.gsub(/%%MIDDLE_NAME%%|\{%contact.middle_name%\}/, contact.middle_name.to_s)
      text = text.gsub(/\{%contact.email%\}/, contact.primary_email.to_s)
      text = text.gsub(/%%DATE%%|\{%date%\}/, ApplicationHelper.format_date(Date.today))
      text = text.gsub(/%%ASSIGNEE%%|\{%ticket.assigned_to%\}/, issue.assigned_to.blank? ? '' : issue.assigned_to.name)
      text = text.gsub(/%%ISSUE_ID%%|\{%ticket.id%\}/, issue.id.to_s) if issue.id
      text = text.gsub(/%%ISSUE_TRACKER%%|\{%ticket.tracker%\}/, issue.tracker.name) if issue.tracker
      text = text.gsub(/%%QUOTED_ISSUE_DESCRIPTION%%|\{%ticket.quoted_description%\}/, issue.description.gsub(/^/, '> ')) if issue.description
      text = text.gsub(/%%PROJECT%%|\{%ticket.project%\}/, issue.project.name) if issue.project
      text = text.gsub(/%%SUBJECT%%|\{%ticket.subject%\}/, issue.subject) if issue.subject
      text = text.gsub(/%%NOTE_AUTHOR%%|\{%response.author%\}/, journal_user.name) if journal_user
      text = text.gsub(/%%NOTE_AUTHOR.FIRST_NAME%%|\{%response.author.first_name%\}/, journal_user.firstname) if journal_user
      text = text.gsub(/%%NOTE_AUTHOR.LAST_NAME%%|\{%response.author.last_name%\}/, journal_user.lastname) if journal_user
      text = text.gsub(/\{%ticket.status%\}/, issue.status.name) if issue.status
      text = text.gsub(/\{%ticket.priority%\}/, issue.priority.name) if issue.priority
      text = text.gsub(/\{%ticket.estimated_hours%\}/, issue.estimated_hours ? issue.estimated_hours.to_s : '')
      text = text.gsub(/\{%ticket.done_ratio%\}/, issue.done_ratio.to_s) if issue.done_ratio
      text = text.gsub(/\{%ticket.closed_on%\}/, issue.closed_on ? ApplicationHelper.format_date(issue.closed_on) : '') if issue.respond_to?(:closed_on)
      text = text.gsub(/\{%ticket.due_date%\}/, issue.due_date ? ApplicationHelper.format_date(issue.due_date) : '')
      text = text.gsub(/\{%ticket.start_date%\}/, issue.start_date ? ApplicationHelper.format_date(issue.start_date) : '')
      text = text.gsub(/\{%ticket.public_url%\}/, full_url(URL_HELPER.public_ticket_path(issue.helpdesk_ticket.id, issue.helpdesk_ticket.token))) if text.match(/\{%ticket.public_url%\}/) && issue.helpdesk_ticket
      if RedmineHelpdesk.vote_allow?
        text = text.gsub(/\{%ticket.voting%\}/, full_url(URL_HELPER.helpdesk_votes_show_path(issue.helpdesk_ticket.id, issue.helpdesk_ticket.token))) if text.match(/\{%ticket.voting%\}/)
        text = text.gsub(/\{%ticket.voting.good%\}/, full_url(URL_HELPER.helpdesk_votes_fast_vote_path(issue.helpdesk_ticket.id, 2, issue.helpdesk_ticket.token))) if text.match(/\{%ticket.voting.good%\}/)
        text = text.gsub(/\{%ticket.voting.okay%\}/, full_url(URL_HELPER.helpdesk_votes_fast_vote_path(issue.helpdesk_ticket.id, 1, issue.helpdesk_ticket.token))) if text.match(/\{%ticket.voting.okay%\}/)
        text = text.gsub(/\{%ticket.voting.bad%\}/, full_url(URL_HELPER.helpdesk_votes_fast_vote_path(issue.helpdesk_ticket.id, 0, issue.helpdesk_ticket.token))) if text.match(/\{%ticket.voting.bad%\}/)
      end

      if text =~ /\{%ticket.history%\}/
        ticket_history = ''
        journals = issue.journals.eager_load(:journal_message)
        unless User.current.allowed_to?(:view_private_notes, issue.project)
          journals = journals.select do |journal|
            !journal.private_notes? || journal.user == user
          end
        end
        journals.map(&:journal_message).compact.each do |journal_message|
          message_author = "*#{l(:label_crm_added_by)} #{journal_message.is_incoming? ? journal_message.from_address : journal_message.journal.user.name}, #{format_time(journal_message.message_date)}*"
          ticket_history = (message_author + "\n" + journal_message.journal.notes + "\n" + ticket_history).gsub(/^/, '> ')
        end
        text = text.gsub(/\{%ticket.history%\}/, ticket_history)
      end

      issue.custom_field_values.each do |value|
        text = text.gsub(/%%#{value.custom_field.name}%%/, value.value.to_s)
      end

      contact.custom_field_values.each do |value|
        text = text.gsub(/%%#{value.custom_field.name}%%/, value.value.to_s)
      end if contact.respond_to?('custom_field_values')

      journal_user.custom_field_values.each do |value|
        text = text.gsub(/\{%response.author.custom_field: #{value.custom_field.name}%\}/, value.value.to_s)
      end if journal_user

      text
    end

    def apply_attachment_macro(mail_attachments, text, issue)
      text.scan(/\{\{send_file\(([^%\}]+)\)\}\}/).flatten.each do |file_name|
        attachment = file_name.match(/^(\d)+$/) ? Attachment.where(:id => file_name).first : issue.attachments.where(:filename => file_name).first
        mail_attachments[attachment.filename] = { mime_type: attachment.content_type, content: File.open(attachment.diskfile, 'rb') { |io| io.read } } if attachment
      end
      text.gsub(/\{\{send_file\(([^%\}]+)\)\}\}/, '')
    end

    def apply_from_macro(text, journal_user = nil)
      return text unless text =~ /\A\{%.+%\}.*?<.+@.+\..{2,}>\z/
      text = text[/<.*>/] if journal_user.nil? || journal_user == User.anonymous
      text = text.gsub(/\{%response.author%\}/, journal_user.name) if text =~ /\{%response.author%\}/
      text = text.gsub(/\{%response.author.first_name%\}/, journal_user.firstname) if text =~ /\{%response.author.first_name%\}/
      text
    end

    private

    def provider_options(project_id)
      case HelpdeskSettings[:helpdesk_protocol, project_id]
      when 'gmail'
        { protocol: 'imap', host: 'imap.gmail.com', port: '993', ssl: '1', verify_ssl: false }
      when 'yahoo'
        { protocol: 'imap', host: 'imap.mail.yahoo.com', port: '993', ssl: '1' }
      when 'yandex'
        { protocol: 'imap', host: 'imap.yandex.ru', port: '993', ssl: '1' }
      else
        { protocol: HelpdeskSettings[:helpdesk_protocol, project_id],
          host: HelpdeskSettings[:helpdesk_host, project_id],
          port: HelpdeskSettings[:helpdesk_port, project_id],
          ssl:  HelpdeskSettings[:helpdesk_use_ssl, project_id] != '1' ? nil : '1' }
      end
    end

    def common_options(project_id)
      {
        apop: HelpdeskSettings[:helpdesk_apop, project_id],
        username: HelpdeskSettings[:helpdesk_username, project_id],
        password: HelpdeskSettings[:helpdesk_password, project_id],
        folder: HelpdeskSettings[:helpdesk_imap_folder, project_id],
        move_on_success: HelpdeskSettings[:helpdesk_move_on_success, project_id],
        move_on_failure: HelpdeskSettings[:helpdesk_move_on_failure, project_id],
        delete_unprocessed: HelpdeskSettings[:helpdesk_delete_unprocessed, project_id].to_i > 0
      }
    end

    def contact_from_attributes(email, fullname = nil)
      contact = Contact.new

      # Truncating the email address would result in an invalid format
      contact.email = email
      names = fullname.blank? ? email.gsub(/@.*$/, '').split('.') : fullname.split
      contact.first_name = names.shift.slice(0, 255)
      contact.last_name = names.join(' ').slice(0, 255)
      contact.company = email.downcase.slice(0, 255)
      contact.last_name = '-' if contact.last_name.blank?

      if contact.last_name =~ %r(\((.*)\))
        contact.last_name, contact.company = $`, $1
      end

      if contact.first_name =~ /,$/
        contact.first_name = contact.last_name
        contact.last_name = $` # everything before the match
      end
      contact
    end

    def full_url(path)
      [Setting.protocol, '://', Setting.host_name, path].join
    end
  end

  def plain_text_body
    return @plain_text_body unless @plain_text_body.nil?
    return '' if email.mime_type.starts_with? 'image/'
    part = email.html_part || email.text_part
    unless part
      return @plain_text_body = '' if email.parts.present? && email.parts.all? { |em_part| em_part.attachment? }
      part = email
    end

    part_charset = Mail::RubyVer.pick_encoding(part.charset).to_s rescue part.charset
    @plain_text_body = self.class.convert_to_utf8(part.body.decoded, part_charset)

    if email.mime_type == 'text/calendar'
      @plain_text_body = email.body.to_s.scan(/^DESCRIPTION:(.+)$/) && $1.to_s
    elsif (email.html_part.present? || email.mime_type == 'text/html' || ['multipart/related', 'multipart/alternative'].include?(email.mime_type))
      @plain_text_body = self.class.html_body_to_text(@plain_text_body)
    else
      @plain_text_body = self.class.plain_text_body_to_text(@plain_text_body)
    end
  rescue Exception => e
    HelpdeskLogger.error "#{email && email.message_id}: Message body processing error - #{e.message}"
    @plain_text_body = '(Unprocessable message body)'
  end
end
