require File.expand_path('../../../liquid/liquid_test_helper', __FILE__)

class AttachmentImagesDropTest < ActiveSupport::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations, :versions, :trackers, :projects_trackers, :issue_categories, :attachments

  def setup
    @issue = Issue.find(14) # Attachments of Issue(14) exist on disk
    @images = @issue.images
    @image = @images.first
    @user = @image.author

    @liquid_render = LiquidRender.new(
      'user' => RedmineCrm::Liquid::UserDrop.new(@user),
      'image' => AttachmentImageDrop.new(@image),
      'images' => AttachmentImagesDrop.new(@images)
    )
  end

  def test_attachment_images_all
    liquid_template = @liquid_render.render('{% for image in images.all %} {{ image.filename }} {% endfor %}')
    @images.each { |image| assert_match image.filename, liquid_template }
  end

  def test_attachment_images_size
    assert_equal @images.size.to_s, @liquid_render.render('{{ images.size }}')
  end

  def test_attachment_image_author
    assert_equal @user.name, @liquid_render.render('{{ image.author.name }}')
  end

  def test_attachment_image_url
    assert_equal @image.public_url, @liquid_render.render('{{ image.url }}')
  end

  def test_attachment_image_asset_base64
    set_fixtures_attachments_directory
    assert_equal @image.asset_base64, @liquid_render.render('{{ image.asset_base64 }}')
  end

  def test_attachment_image_delegated_fields
    [:id, :filename, :filesize, :description, :created_on].each do |field|
      assert_equal @image.send(field).to_s, @liquid_render.render("{{ image.#{field} }}")
    end
  end
end
