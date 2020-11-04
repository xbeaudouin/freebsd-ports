class HelpdeskMailMessenger::IssueResponseMessage < HelpdeskMailMessenger
  def project
    object.project
  end

  def issue
    object.issue
  end

  def build_email
    set_headers

    @email_stylesheet = HelpdeskSettings[:helpdesk_helpdesk_css, project].to_s.html_safe
    @email_header = HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_emails_header', project], contact, issue, object.user)
    @email_body = HelpdeskMailSupport.apply_text_macro(object.notes, contact, issue, object.user)
    @email_body = HelpdeskMailSupport.apply_attachment_macro(attachments, @email_body, issue)
    @email_footer = HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_emails_footer', project], contact, issue, object.user)
    @image_url = object.journal_message.try(:calculate_view_id)

    validate

    subject_macro = HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_answer_subject', project], contact, issue)

    add_attachments_to_mail(object)

    if object.details.blank? && object.private_notes? && object.notes.present?
      details_journal = object.class.where('id != ?', object.id).where(:created_on => object.created_on).first
      add_attachments_to_mail(details_journal) if details_journal
    end

    mail :from => from_address(object.user),
         :to => to_address.to_s,
         :cc => cc_address.to_s,
         :bcc => bcc_address.to_s,
         :in_reply_to => in_reply_to.to_s,
         :subject => (subject_macro.blank? ? issue.subject + " [#{issue.tracker} ##{issue.id}]" : subject_macro) do |format|
      format.text { render 'email_layout' }
      format.html { render 'email_layout' } unless RedmineHelpdesk.add_plain_text_mail?
    end
  end

  private

  def set_headers
    headers['X-Redmine-Ticket-ID'] = issue.id.to_s
  end

  def validate
    raise MissingInformation.new(l(:text_helpdesk_message_body_cant_be_blank)) if @email_body.blank?
    raise MissingInformation.new(l(:text_helpdesk_from_address_cant_be_blank)) if from_address.blank?
    raise MissingInformation.new(l(:text_helpdesk_recipients_cant_be_blank)) if to_address.blank? && cc_address.blank? && bcc_address.blank?
  end

  def to_address
    options[:to_address] || (object.journal_message && object.journal_message.to_address) || contact.primary_email
  end

  def cc_address
    options[:cc_address] || (object.journal_message && object.journal_message.cc_address)
  end

  def bcc_address
    options[:bcc_address] || (object.journal_message && object.journal_message.bcc_address)
  end

  def in_reply_to
    options[:in_reply_to] || (issue.helpdesk_ticket.blank? || issue.helpdesk_ticket.message_id.blank?) ? '' : "<#{issue.helpdesk_ticket.message_id}>"
  end

  def add_attachments_to_mail(journal)
    journal.details.where(:property => 'attachment').each do |attachment_detail|
      if attach = Attachment.where(:id => attachment_detail.prop_key).first
        attachments[attach.filename] = File.open(attach.diskfile, 'rb') { |io| io.read }
      end
    end
  end
end
