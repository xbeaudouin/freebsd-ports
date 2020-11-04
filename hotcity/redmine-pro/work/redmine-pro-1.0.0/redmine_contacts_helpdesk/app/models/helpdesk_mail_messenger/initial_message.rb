class HelpdeskMailMessenger::InitialMessage < HelpdeskMailMessenger
  def project
    object.project
  end

  def issue
    object
  end

  def build_email
    set_headers

    @email_stylesheet = HelpdeskSettings['helpdesk_helpdesk_css', project].to_s.html_safe
    @email_header = HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_emails_header', project], contact, issue, issue.author)
    @email_body = HelpdeskMailSupport.apply_text_macro(issue.description, contact, issue, issue.author)
    @email_body = HelpdeskMailSupport.apply_attachment_macro(attachments, @email_body, issue)
    @email_footer = HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_emails_footer', project], contact, issue, issue.author)
    @image_url = object.helpdesk_ticket.try(:view_id)

    validate

    add_attachments_to_mail(options[:attachments])

    mail from:    from_address.to_s,
         to:      to_address.to_s,
         subject: HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_first_answer_subject', project.try(:id)], contact, issue) || issue.subject do |format|
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
    raise MissingInformation.new(l(:text_helpdesk_message_contact_email_blank, contact_name: contact.name)) if contact.email.blank?
  end

  def add_attachments_to_mail(attachments_hash)
    return if attachments_hash.blank?
    attachments_hash.each_value do |mail_attachment|
      if file = mail_attachment['file']
        file.rewind
        attachments[file.original_filename] = file.read
      elsif token = mail_attachment['token']
        if token.to_s =~ /^(\d+)\.([0-9a-f]+)$/
          attachment_id, attachment_digest = $1, $2
          if a = Attachment.where(:id => attachment_id, :digest => attachment_digest).first
            attachments[a.filename] = File.open(a.diskfile, 'rb') { |io| io.read }
          end
        end
      end
    end
  end
end
