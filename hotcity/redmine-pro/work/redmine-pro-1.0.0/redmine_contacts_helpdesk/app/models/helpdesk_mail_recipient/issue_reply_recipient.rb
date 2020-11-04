class HelpdeskMailRecipient::IssueReplyRecipient < HelpdeskMailRecipient
  def receive(issue_id)
    issue = Issue.where(id: issue_id).first
    return unless issue
    return receive_new_issue if HelpdeskSettings['helpdesk_lifetime', project].to_i > 0 && lifetime_expired?(issue)

    journal = issue.init_journal(container.from_user)
    journal.notes = container.text_body
    journal_message = JournalMessage.create(from_address: slice_emails(container.from_addr.downcase),
                                            to_address: slice_emails(email.to_addrs.join(',').downcase),
                                            bcc_address: slice_emails(email.bcc_addrs.join(',').downcase),
                                            cc_address: slice_emails(email.cc_addrs.join(',').downcase),
                                            message_id: email.message_id,
                                            is_incoming: true,
                                            message_date: email.date || Time.now,
                                            contact: contact,
                                            journal: journal)

    add_attachments(issue)
    save_email_as_calendar(issue)
    save_email_as_attachment(journal_message, "reply-#{DateTime.now.strftime('%d.%m.%y-%H.%M.%S')}.eml")
    issue.status_id = reopen_status_id if reopen_status_id

    issue.save!(:validate => false)
    container.issue = issue
    HelpdeskMailRule.apply_rules(:incoming, container)

    logger.try(:info, "#{email.message_id}: issue ##{issue.id} updated by #{container.from_user}")
    journal
  end

  private

  def receive_new_issue
    email.subject = email.subject.to_s.gsub(MailHandler::ISSUE_REPLY_SUBJECT_RE, '')
    HelpdeskMailRecipient::IssueRecipient.new(container).receive
  end

  def reopen_status_id
    IssueStatus.named(get_keyword(:reopen_status)).first.try(:id) || IssueStatus.where(id: get_keyword(:reopen_status_id)).first.try(:id)
  end

  def lifetime_expired?(issue)
    issue.journals.last && (Date.today - issue.journals.last.created_on.to_date > HelpdeskSettings['helpdesk_lifetime', project].to_i)
  end
end
