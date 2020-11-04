class HelpdeskMailMessenger::AutocloseMessage < HelpdeskMailMessenger
  def project
    object.project
  end

  def issue
    object
  end

  def build_email
    set_headers

    @email_stylesheet = HelpdeskSettings['helpdesk_helpdesk_css', project].to_s.html_safe
    @email_body = HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_autoclose_template', project], contact, issue)
    @email_body = I18n.t('label_helpdesk_autoclosed_ticket') unless @email_body.present?

    validate

    mail from:        from_address.to_s,
         to:          to_address.to_s,
         cc:          issue.helpdesk_ticket.try(:cc_address).to_s,
         subject:     HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_autoclose_subject', project], contact, issue) || "Helpdesk autoclose message [Case ##{issue.id}]",
         in_reply_to: issue.helpdesk_ticket.try(:message_id) do |format|
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
end
