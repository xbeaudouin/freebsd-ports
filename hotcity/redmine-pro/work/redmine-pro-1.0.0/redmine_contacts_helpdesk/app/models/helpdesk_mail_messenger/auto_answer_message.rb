class HelpdeskMailMessenger::AutoAnswerMessage < HelpdeskMailMessenger
  def project
    object.project
  end

  def issue
    object
  end

  def build_email
    set_headers

    @email_stylesheet = HelpdeskSettings['helpdesk_helpdesk_css', project].to_s.html_safe
    @email_body = HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_first_answer_template', project], contact, issue)

    validate

    mail from:        from_address.to_s,
         to:          to_address.to_s,
         cc:          issue.helpdesk_ticket.try(:cc_address).to_s,
         subject:     HelpdeskMailSupport.apply_text_macro(HelpdeskSettings['helpdesk_first_answer_subject', project], contact, issue) || "Helpdesk auto answer [Case ##{issue.id}]",
         in_reply_to: issue.helpdesk_ticket.try(:message_id) do |format|
      format.text { render 'email_layout' }
      format.html { render 'email_layout' } unless RedmineHelpdesk.add_plain_text_mail?
    end
  end

  private

  def set_headers
    headers['X-Redmine-Ticket-ID'] = issue.id.to_s
    headers['X-Auto-Response-Suppress'] = 'oof'
  end
end
