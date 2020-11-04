# encoding: utf-8
# include RedCloth

module HelpdeskMailerHelper
  def textile(text)
    Redmine::WikiFormatting.to_html(Setting.text_formatting, text)
  end

  def message_sender(email)
    return nil unless email
    sender = email.reply_to.try(:first) || email.from_addrs.try(:first)
    sender.to_s.strip[0, 255]
  end

  def contact_from_email(email, project, logger = nil)
    from = (email.header['reply-to'].to_s.present? ? email.header['reply-to'] : email.header['from']).to_s.strip[0, 255]
    addr, name = from, nil
    if match_result = from.match(/^"?(.+?)"?\s*<(.+@.+)>$/)
      addr, name = match_result[2], match_result[1]
    elsif match_result = from.match(/(\S+@\S+)/)
      addr = match_result[1]
    end
    HelpdeskMailSupport.create_contact_from_address(addr, name, project, logger)
  end
end
