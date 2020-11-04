class HelpdeskMailRule < ActiveRecord::Base
  include Redmine::SafeAttributes
  include Redmine::I18n

  NO_VALUES_ACTION_KEYS = %w[stop]

  INCOMING = 0
  OUTGOING = 1
  MANUALLY = 2

  validate :presence_actions
  validate :validate_conditions_and_actions

  belongs_to :user
  serialize :conditions
  serialize :actions

  cattr_accessor :available_conditions
  cattr_accessor :available_actions

  rcrm_acts_as_list

  safe_attributes 'mail_type', 'conditions', 'actions', 'move_to', 'position'

  scope :by_position, -> { order(:position) }
  scope :incoming, -> { where(mail_type: INCOMING) }
  scope :outgoing, -> { where(mail_type: OUTGOING) }
  scope :manually, -> { where(mail_type: MANUALLY) }

  def self.add_condition(condition_class)
    self.available_conditions ||= {}
    self.available_conditions[condition_class.new.field] = condition_class
    true
  end

  def self.add_action(action_class)
    self.available_actions ||= {}
    self.available_actions[action_class.new.field] = action_class
    true
  end

  def self.apply_rules(direction, container)
    return unless [:incoming, :outgoing, :manually].include?(direction)
    with_initialized_journal(container) do
      send(direction).by_position.find_each { |rule| break unless rule.apply_to(container) }
    end
  end

  def self.with_initialized_journal(container)
    rule_changes_journal = Journal.new(journalized: container.issue,
                                       user: container.from_user,
                                       notes: l(:label_helpdesk_email_rules_changes))
    yield
    rule_changes_journal.save if rule_changes_journal.details.any?
  end

  def apply_to(container)
    return true unless suitable_conditions?(container)
    result = apply_actions(container)
    actions.keys.include?(RedmineHelpdesk::MailRules::Actions::Stop.new.field) ? false : result
  end

  def available_conditions
    return @available_conditions if @available_conditions
    @available_conditions = ActiveSupport::OrderedHash.new
    Hash[self.class.available_conditions.sort].each_value do |condition_class|
      condition = condition_class.new
      @available_conditions[condition.field] = HelpdeskMailRuleElement.new(condition.field, condition.options.merge(values: condition.values(self)))
    end
    @available_conditions
  end

  def available_actions
    return @available_actions if @available_actions
    @available_actions = ActiveSupport::OrderedHash.new
    Hash[self.class.available_actions.sort].each_value do |action_class|
      action = action_class.new
      @available_actions[action.field] = HelpdeskMailRuleElement.new(action.field, action.options.merge(values: action.values(self)))
    end
    @available_actions
  end

  def available_conditions_as_json
    json = {}
    available_conditions.each do |field, condition|
      options = { type: condition[:type], name: condition[:name] }
      options[:remote] = true if condition.remote

      if has_condition?(field) || !condition.remote
        options[:values] = condition.values
        if options[:values] && condition_values_for(field)
          missing = Array(condition_values_for(field)).select(&:present?) - options[:values].map(&:last)
          if missing.any? && respond_to?(method = "find_#{field}_filter_values")
            options[:values] += send(method, missing)
          end
        end
      end
      json[field] = options.stringify_keys
    end
    json
  end

  def available_actions_as_json
    json = {}
    available_actions.each do |field, action|
      options = { type: action[:type], name: action[:name] }
      options[:remote] = true if action.remote

      if has_action?(field) || !action.remote
        options[:values] = action.values
        if options[:values] && action_values_for(field)
          missing = Array(action_values_for(field)).select(&:present?) - options[:values].map(&:last)
          if missing.any? && respond_to?(method = "find_#{field}_filter_values")
            options[:values] += send(method, missing)
          end
        end
      end
      json[field] = options.stringify_keys
    end
    json
  end

  def conditions
    super || {}
  end

  def actions
    super || {}
  end

  def condition_values_for(field)
    has_condition?(field) ? conditions[field][:values] : []
  end

  def action_values_for(field)
    has_action?(field) ? actions[field][:values] : []
  end

  def operator_for_condition(field)
    has_condition?(field) ? conditions[field][:operator] : nil
  end

  def operator_for_action(field)
    has_action?(field) ? actions[field][:operator] : nil
  end

  private

  def presence_actions
    errors.add(:base, l(:mail_rule_should_have_action)) unless actions.any?
  end

  def validate_conditions_and_actions
    check_condition_values
    check_action_values
  end

  def has_condition?(field)
    conditions && conditions[field]
  end

  def has_action?(field)
    actions && actions[field]
  end

  def suitable_conditions?(container)
    return true if conditions.empty?

    begin
      constions_result = conditions.map do |condition, options|
        condition_class = self.class.available_conditions[condition]
        next unless condition_class
        condition_class.new.check(container, options[:operator], options[:values])
      end
      constions_result.all?
    rescue Exception => e
      HelpdeskLogger.try(:error, "Rule condition error: #{[e.message, e.backtrace.first].join("\n")}")
      false
    end
  end

  def apply_actions(container)
    actions.each do |action, options|
      action_class = self.class.available_actions[action]
      next unless action_class
      begin
        action_class.new.apply(container, options[:operator], options[:values])
      rescue Exception => e
        HelpdeskLogger.try(:error, "Rule action applying error: #{[e.message, e.backtrace.first].join("\n")}")
        next
      end
    end
  end

  def check_condition_values
    conditions.each do |key, opt|
      add_error(key, :blank) if ['~', '=', '!~', '!'].include?(opt[:operator]) && (opt[:values].blank? || opt[:values].first.blank?)
    end
  end

  def check_action_values
    actions.except(*NO_VALUES_ACTION_KEYS).each do |key, opt|
      add_error(key, :blank) if [nil, '~', '=', '!~', '!'].include?(opt[:operator]) && (opt[:values].blank? || opt[:values].first.blank?)
    end
  end

  def add_error(elem, message)
    errors.add(:base, elem.upcase + ' ' + l(message, :scope => 'activerecord.errors.messages'))
  end
end
