class ReporterAttachmentImagesController < ApplicationController
  before_action :find_reporter_attachment_image, :authorize_by_token

  skip_before_action :check_if_login_required

  def download
    send_file @reporter_attachment_image.diskfile,
              filename: filename_for_content_disposition(@reporter_attachment_image.filename),
              type: @reporter_attachment_image.content_type
  end

  private

  def find_reporter_attachment_image
    @reporter_attachment_image = ReporterAttachmentImage.find(params[:id])
    # Show 404 if the filename in the url is wrong
    raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @reporter_attachment_image.filename
    @project = @reporter_attachment_image.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_by_token
    (@reporter_attachment_image.public_link_token == params[:token]) || deny_access
  end
end
