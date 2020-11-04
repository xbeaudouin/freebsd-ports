class HelpdeskMailRecipient
  attr_reader :container
  delegate :email, to: :container
  delegate :logger, to: :container
  delegate :get_keyword, to: :container
  delegate :contact, to: :container

  def initialize(mail_container)
    @container = mail_container
  end

  def receive
    raise 'Implement this method in inherited class'
  end

  private

  def project
    container.target_project
  end

  def cc_contacts
    email[:cc].to_s
    email.cc_addrs.each_with_index.map do |cc_addr, index|
      cc_name = email[:cc].display_names[index]
      HelpdeskMailSupport.create_contact_from_address(cc_addr, cc_name, project, logger)
    end.compact
  end

  def save_email_as_attachment(object, filename = 'message.eml')
    Attachment.create(container: object,
                      file: email.raw_source.to_s,
                      author: container.from_user,
                      filename: filename,
                      content_type: 'message/rfc822')
  end

  def save_email_as_calendar(object, filename = 'calendar_event.ics')
    return unless email.mime_type == 'text/calendar'

    Attachment.create(container: object,
                      file: email.body.to_s,
                      author: container.from_user,
                      filename: filename,
                      content_type: 'text/calendar')
  end

  def add_attachments(obj)
    email_attachments = []
    email_attachments << Mail::Part.new(container.email) if container.email.mime_type.starts_with? 'image/'

    fwd_attachments = email.parts.map do |part|
      if part.content_type =~ /message\/rfc822/
        Mail.new(part.body).attachments
      elsif part.parts.empty?
        part if part.attachment?
      else
        part.attachments
      end
    end
    fwd_attachments = fwd_attachments.flatten.compact

    email_attachments |= fwd_attachments | email.attachments

    return if email_attachments.blank?
    email_attachments.each do |attachment|
      attachment_filename = HelpdeskMailSupport.convert_to_utf8(attachment.filename, 'binary')
      attachment_filename = [attachment_filename, '.', attachment.mime_type.split('/').last].join if attachment.inline? && attachment_filename.exclude?('.')
      new_attachment = Attachment.new(container: obj,
                                      file: (attachment.decoded rescue nil) || (attachment.decode_body rescue nil) || attachment.raw_source,
                                      filename: attachment_filename,
                                      author: container.from_user,
                                      content_type: attachment.mime_type)
      if valid_attachment?(obj, attachment.body, new_attachment)
        obj.attachments << new_attachment
        logger.try(:info, "#{email.message_id}: attachment #{attachment_filename} added to ticket: '#{obj.subject}'")
      end
    end
  end

  def valid_attachment?(obj, body, new_attachment)
    obj.attachments.where(digest: HelpdeskMailSupport.attachment_digest(body.to_s)).empty? &&
      HelpdeskMailSupport.attachment_acceptable?(new_attachment)
  end

  def slice_emails(emails_string)
    return emails_string if emails_string.size <= 255

    sliced_string = emails_string.slice(0, 255)
    sliced_string.slice(0, sliced_string.rindex(',').to_i)
  end
end
