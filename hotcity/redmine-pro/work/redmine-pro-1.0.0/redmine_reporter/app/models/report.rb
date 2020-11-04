class Report
  attr_accessor :report_name, :filename, :content, :public_link_params

  def initialize(report_name, filename, text, public_link_params)
    @report_name = report_name
    @filename = filename
    @content = build_content(text)
    @public_link_params = public_link_params
  end

  def to_pdf
    unless Redmine::Configuration['wkhtmltopdf_exe_path'].blank?
      WickedPdf.config = { exe_path: Redmine::Configuration['wkhtmltopdf_exe_path'] }
    end
    wicked_pdf = WickedPdf.new
    wicked_pdf.pdf_from_string(
      @content,
      encoding: 'UTF-8',
      page_size: 'A4',
      lowquality: wicked_pdf.binary_version.to_s == "0.12.4",
      margin: { top: 20, bottom: 20, left: 20, right: 20 },
      footer: { right: '[page]/[topage]' }
    )
  rescue Exception => e
    e.message
  end

  def create_attachment
    Attachment.create(file: to_pdf, author: User.current, filename: @filename, content_type: 'application/pdf')
  end

  private

  def host_path
    "#{Setting.protocol}://#{Setting.host_name}"
  end

  def asset_base64?(src)
    !!src.match(/\Adata:.*;base64,.*/)
  end

  def absolute_url?(url)
    uri = URI.parse(url) rescue false
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  end

  def valid_source?(src)
    asset_base64?(src) || absolute_url?(src)
  end

  def build_content(text)
    # Nokogiri always present in the test environment
    if Object.const_defined?(:Nokogiri) && Redmine::VERSION.to_s >= '3.0'
      parse_with_nokogiri(text)
    else
      parse_with_regexp(text)
    end
  end

  def parse_with_regexp(text)
    text = text.gsub(/<img[^>]*/i) do |img_tag|
      img_tag.gsub(/src\s*=(["'])([^"']+)\1/i) do |match|
        src = $2
        valid_source?(src) ? match : %(src="#{prepend_host_path(src)}")
      end
    end

    text.gsub(/<a[^>]*/i) do |img_tag|
      img_tag.gsub(/href\s*=(["'])([^"']+)\1/i) do |match|
        href = $2
        absolute_url?(href) ? match : %(href="#{prepend_host_path(href)}")
      end
    end.html_safe
  end

  def parse_with_nokogiri(text)
    doc_fragment = Nokogiri::HTML::fragment(text)

    doc_fragment.css('img').each do |img|
      img['src'] = prepend_host_path(img['src']) unless valid_source?(img['src'])
    end

    doc_fragment.css('a').each do |a|
      a['href'] = prepend_host_path(a['href']) unless absolute_url?(a['href'])
    end

    doc_fragment.to_html.html_safe
  end

  def prepend_host_path(value)
    "#{host_path}#{value[0] == '/' ? '' : '/'}#{value}"
  end
end
