class ReporterAttachmentImage < Attachment
  IMAGE_FILE_EXTENSIONS = %w(bmp gif jpg jpe jpeg png)

  IMAGES_CONDITION = IMAGE_FILE_EXTENSIONS.map do |extension|
    "LOWER(#{table_name}.filename) LIKE LOWER('%.#{extension}')"
  end.join(' OR ')

  default_scope { where(IMAGES_CONDITION) }

  def public_link_token
    Digest::MD5.hexdigest("#{token}:#{Rails.application.config.secret_token}")
  end

  def public_url
    Rails.application.routes.url_helpers
      .download_reporter_attachment_image_path(self, filename, token: public_link_token)
  end

  def public_link_params
    { id: id, filename: filename, token: public_link_token }
  end

  def to_base64
    Base64.encode64(File.read(diskfile))
  end

  def asset_base64
    "data:#{content_type};base64,#{to_base64}"
  end
end
