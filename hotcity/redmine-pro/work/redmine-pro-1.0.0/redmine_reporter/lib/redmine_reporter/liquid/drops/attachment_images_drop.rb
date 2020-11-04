class AttachmentImagesDrop < Liquid::Drop
  def initialize(attachments)
    @attachments = attachments
  end

  def before_method(id)
    AttachmentImageDrop.new(@attachments.where(id: id).first || ReporterAttachmentImage.new)
  end

  def all
    @all ||= @attachments.map { |attachment| AttachmentImageDrop.new(attachment) }
  end

  def each(&block)
    all.each(&block)
  end

  def size
    @attachments.size
  end
end

class AttachmentImageDrop < Liquid::Drop
  include ActionView::Helpers::UrlHelper

  delegate :id, :filename, :filesize, :description, :created_on, :asset_base64, to: :@attachment

  def initialize(attachment)
    @attachment = attachment
  end

  def author
    @user ||= RedmineCrm::Liquid::UserDrop.new(@attachment.author)
  end

  def link
    link_to @attachment.filename, self.url
  end

  def url
    @attachment.public_url
  end
end
