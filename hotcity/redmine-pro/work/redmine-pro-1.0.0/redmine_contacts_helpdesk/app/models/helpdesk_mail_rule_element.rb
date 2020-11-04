class HelpdeskMailRuleElement
  include Redmine::I18n

  def initialize(field, options)
    @field = field.to_s
    @options = options
    @options[:name] ||= l(options[:label] || "field_#{field}".gsub(/_id$/, ''))
    # Consider filters with a Proc for values as remote by default
    @remote = options.key?(:remote) ? options[:remote] : options[:values].is_a?(Proc)
  end

  def [](arg)
    if arg == :values
      values
    else
      @options[arg]
    end
  end

  def values
    @values ||= begin
      values = @options[:values]
      if values.is_a?(Proc)
        values = values.call
      end
      values
    end
  end

  def remote
    @remote
  end
end
