class HelpdeskMailRecipient::IssueRecipient < HelpdeskMailRecipient
  def receive
    issue = Issue.new
    issue.author = container.from_user
    issue.project = project
    issue.safe_attributes = helpdesk_issue_attributes(issue)
    issue.safe_attributes = { 'custom_field_values' => helpdesk_custom_field_values(issue) }
    issue.tracker_id = tracker_id(issue)
    issue.subject = cleaned_up_subject(email)
    issue.subject = '(no subject)' if issue.subject.blank?
    issue.description = container.text_body
    issue.start_date ||= Date.today if Setting.default_issue_start_date_to_creation_date?
    issue.assigned_to = contact.find_assigned_user(project, issue.assigned_to_id || HelpdeskSettings['helpdesk_assigned_to', project])

    helpdesk_ticket = HelpdeskTicket.new(from_address: slice_emails(container.from_addr.downcase.to_s),
                                         to_address: slice_emails(email.to_addrs.join(',').downcase.to_s),
                                         cc_address: slice_emails(email.cc_addrs.join(',').downcase.to_s),
                                         ticket_date: email.date || Time.now,
                                         message_id: email.message_id.to_s.slice(0, 255),
                                         is_incoming: true,
                                         customer: contact,
                                         issue: issue,
                                         source: HelpdeskTicket::HELPDESK_EMAIL_SOURCE)
    issue.helpdesk_ticket = helpdesk_ticket

    add_attachments(issue)
    save_email_as_calendar(issue)
    save_email_as_attachment(helpdesk_ticket)

    Redmine::Hook.call_hook(:helpdesk_mailer_receive_issue_before_save, { issue: issue, contact: contact, helpdesk_ticket: helpdesk_ticket, email: email })

    ActiveRecord::Base.transaction do
      issue.save!(validate: false)
      container.issue = issue
      HelpdeskMailRule.apply_rules(:incoming, container)

      add_contact_note(issue) && send_auto_answer(issue)

      logger.try(:info, "#{email.message_id}: issue ##{issue.id} created by #{container.from_user} for #{contact.name}")
      issue
    end
  end

  private

  def add_contact_note(issue)
    return true if HelpdeskSettings['helpdesk_add_contact_notes', project].to_i == 0
    ContactNote.create(content: "*#{issue.subject}* [#{issue.tracker.name} - ##{issue.id}]\n\n" + issue.description,
                       type_id: Note.note_types[:email],
                       source: contact,
                       author_id: issue.author_id)
  end

  def send_auto_answer(issue)
    return true if HelpdeskSettings['helpdesk_send_notification', project].to_i == 0
    notification = HelpdeskMailer.auto_answer(contact, issue)
    logger.try(:info, "#{email.message_id}: notification was sent to #{notification.to_addrs.first}") if notification
  rescue Exception => e
    logger.try(:error, "#{email.message_id}: notification was not sent #{e.message}")
  end

  def helpdesk_issue_attributes(issue)
    attrs = {
      'status_id' => status_id,
      'priority_id' => priority_id,
      'category_id' => category_id(issue),
      'assigned_to_id' => assigned_to_id,
      'fixed_version_id' => version_id(issue),
      'start_date' => start_date,
      'due_date' => due_date,
      'estimated_hours' => estimated_hours,
      'done_ratio' => done_ratio
    }.delete_if { |_k, v| v.blank? }
    attrs
  end

  def helpdesk_custom_field_values(customized)
    customized.custom_field_values.inject({}) do |h, v|
      if value = get_keyword(v.custom_field.name, :override => true)
        h[v.custom_field.id.to_s] = value
      end
      h
    end
  end

  def tracker_id(issue)
    issue.project.trackers.named(get_keyword(:tracker)).map(&:id).first ||
      issue.project.trackers.where(id: get_keyword(:tracker_id)).first.try(:id) ||
      issue.project.trackers.first.try(:id)
  end

  def status_id
    IssueStatus.named(get_keyword(:status)).map(&:id).first || IssueStatus.where(id: get_keyword(:status_id)).first.try(:id)
  end

  def priority_id
    IssuePriority.named(get_keyword(:priority)).map(&:id).first || IssuePriority.where(id: get_keyword(:priority_id)).first.try(:id)
  end

  def category_id(issue)
    get_keyword(:category) && issue.project.issue_categories.named(k).map(&:id).first
  end

  def assigned_to_id
    key = get_keyword(:assigned_to_id, :override => true)
    assigned = User.where(id: key).first || Group.where(id: key).first if key
    return assigned.id if assigned
    key = get_keyword(:assigned_to, :override => true)
    assigned = User.find_by_mail(key) || User.find_by_login(key) if key
    if container.from_user.nil? && key.match(/ /)
      firstname, lastname = *(key.split) # "First Last Throwaway"
      assigned = User.where(firstname: firstname, lastname: lastname).first
    end
    assigned.try(:id)
  end

  def version_id(issue)
    issue.project.shared_versions.named(get_keyword(:fixed_version, :override => true)).map(&:id).first
  end

  def start_date
    get_keyword(:start_date, :override => true, :format => '\d{4}-\d{2}-\d{2}')
  end

  def due_date
    get_keyword(:due_date, :override => true, :format => '\d{4}-\d{2}-\d{2}')
  end

  def estimated_hours
    get_keyword(:estimated_hours, :override => true)
  end

  def done_ratio
    get_keyword(:done_ratio, :override => true, :format => '(\d|10)?0')
  end

  def cleaned_up_subject(email)
    return '' if email[:subject].blank?
    subject = decode_subject(email[:subject].respond_to?(:unparsed_value) ? email[:subject].unparsed_value : email[:subject].value)
    subject = HelpdeskMailSupport.convert_to_utf8(subject)
    subject.gsub!(/./) { |c| c.bytesize == 4 ? '' : c }
    subject.strip[0, 255]
  rescue Exception => e
    logger.try(:error, "#{email.message_id}: Message subject processing error - #{e.message}")
    '(Unprocessable subject)'
  end

  def decode_subject(str)
    # Optimization: If there's no encoded-words in the string, just return it
    return str unless str.index('=?')

    str = str.gsub(/\?=(\s*)=\?/, '?=????=?') # Replace whitespaces between 'encoded-word's on special symbols
    str.split('????').map do |text|
      if text.index('=?') .nil?
        text
      else
        text.gsub!(/[\r\n]/, '')
        text.gsub(/\=\?.+?\?[qQbB]\?.+?\?\=/) do |part|
          if part.index(/\=\?.+\?[Bb]\?.+\?\=/m)
            part.gsub(/\=\?.+\?[Bb]\?.+\?=/m) { |substr| Mail::Encodings.b_value_decode(substr) }
          elsif part.index(/\=\?.+\?[Qq]\?.+\?\=/m)
            part.gsub(/\=\?.+\?[Qq]\?.+\?\=/m) { |substr| Mail::Encodings.q_value_decode(substr) }
          end
        end
      end
    end.join('')
  end
end
