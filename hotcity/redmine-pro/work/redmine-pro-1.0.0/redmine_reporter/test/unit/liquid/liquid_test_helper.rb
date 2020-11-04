require File.expand_path('../../../test_helper', __FILE__)

class LiquidRender
  DATE_FORMAT = '%d.%m.%Y'.freeze

  def initialize(drops = {})
    @objects_hash = [
      { 'name' => 'one', "value" => 10 },
      { 'name' => 'two', "value" => 5 },
      { 'name' => 'three', "value" => 6 }
    ]
    @registers = {}
    @assigns = {}
    @assigns['objects_arr'] = @objects_hash
    @assigns['now'] = Time.now
    @assigns['today'] = Date.today.strftime(DATE_FORMAT)
    drops.each do |key, drop|
      @assigns[key] = drop
    end
  end

  def render(content)
    Liquid::Template.parse(content).render(Liquid::Context.new({}, @assigns, @registers)).html_safe
  rescue => e
    e.message
  end
end
