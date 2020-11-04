class HelpdeskMailProvider::Imap < HelpdeskMailProvider
  def check
    RedmineContacts::Mailer.check_imap(self, mail_options, options)
  end
end
