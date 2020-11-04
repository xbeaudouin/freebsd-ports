class HelpdeskMailProvider::Pop3 < HelpdeskMailProvider
  def check
    RedmineContacts::Mailer.check_pop3(self, mail_options, options)
  end
end
