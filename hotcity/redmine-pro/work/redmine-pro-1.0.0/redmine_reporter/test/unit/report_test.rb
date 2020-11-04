require File.expand_path('../../test_helper', __FILE__)

class ReportTest < ActiveSupport::TestCase
  def setup
    @report = Report.new('', '', '', '')
  end

  def test_parse_methods
    check_parse_methods '', ''
    check_parse_methods '<h1>Issue images</h1>', '<h1>Issue images</h1>'

    check_parse_methods '<img src="http://webfonts.com/img_1.png">', '<img src="http://webfonts.com/img_1.png">'
    check_parse_methods '<img src="https://webfonts.com/img_1.png">', '<img src="https://webfonts.com/img_1.png">'
    check_parse_methods '<div> <img src="http://webfonts.com/img_1.png"> </div>', '<div> <img src="http://webfonts.com/img_1.png"> </div>'
    check_parse_methods '<img height="64" width="64" src="http://webfonts.com/img_1.png">', '<img height="64" width="64" src="http://webfonts.com/img_1.png">'
    check_parse_methods '<img src="img_1.png">', '<img src="http://localhost:3000/img_1.png">'
    check_parse_methods '<img src="/img_1.png">', '<img src="http://localhost:3000/img_1.png">'
    check_parse_methods '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUg">', '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUg">'

    check_parse_methods '<a href="http://ya.ru/test.png">test.png</a>', '<a href="http://ya.ru/test.png">test.png</a>'
    check_parse_methods '<div> <a href="https://www.ya.ru/test.png">test.png</a> </div>', '<div> <a href="https://www.ya.ru/test.png">test.png</a> </div>'
    check_parse_methods '<a href="test.png">test.png</a>', '<a href="http://localhost:3000/test.png">test.png</a>'
    check_parse_methods '<a style="" href="test.png">test.png</a>', '<a style="" href="http://localhost:3000/test.png">test.png</a>'
    check_parse_methods '<a href="/test.png">test.png</a>', '<a href="http://localhost:3000/test.png">test.png</a>'
  end

  private

  def check_parse_methods(text, expected_text)
    assert_equal expected_text, @report.send(:parse_with_nokogiri, text)
    assert_equal expected_text, @report.send(:parse_with_regexp, text)
  end
end
