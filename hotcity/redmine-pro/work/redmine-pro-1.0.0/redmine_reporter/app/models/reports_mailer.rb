class ReportsMailer < ActionMailer::Base
  def issue_reports(issue_mail)
    options = issue_mail.to_h
    if options[:attachments].present?
      options[:attachments].each { |a| attachments[a.filename] = File.read(a.diskfile) }
    end
    @message_content = options[:message]
    mail options.slice(:to, :from, :cc, :bcc, :subject)
  end
end
