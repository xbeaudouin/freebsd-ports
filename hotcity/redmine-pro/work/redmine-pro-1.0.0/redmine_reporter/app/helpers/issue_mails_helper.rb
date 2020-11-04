module IssueMailsHelper
  def human_readable_address(mail)
    user = User.find_by_mail(mail)
    user.blank? ? "<#{mail}>" : "#{user.name} <#{mail}>"
  end
end
