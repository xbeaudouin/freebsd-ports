class HelpdeskReportsCustomerSatisfactionQuery < HelpdeskReportsQuery
  include HelpdeskHelper

  self.queried_class = HelpdeskTicket

  def initialize_available_filters
    add_available_filter 'report_date_period', :type => :date_past, :name => l(:label_helpdesk_filter_time_interval)
    add_available_filter 'customer', type: :contact, name: l(:label_helpdesk_contact)
    add_available_filter 'customer_company', :type => :string, :name => l(:label_helpdesk_contact_company)
    add_available_filter 'source', :type => :list, :name => l(:label_helpdesk_ticket_source), :values => helpdesk_tickets_source_for_select

    if Redmine::Plugin.registered_plugins.keys.include?(:redmineup_tags)
      add_available_filter 'tags', :type => :list, :values => tags_values
    end

    add_available_filter 'assigned_to_id', :type => :list_optional, :values => assigned_to_values
    add_available_filter 'author_id', :type => :list, :values => author_values

    if project
      add_available_filter 'category_id', :type => :list_optional, :values => project.issue_categories.map { |c| [c.name, c.id.to_s] }
    end

    add_available_filter 'priority_id', :type => :list, :values => IssuePriority.all.map { |p| [p.name, p.id.to_s] }
    add_available_filter 'tracker_id', :type => :list, :values => trackers.map { |t| [t.name, t.id.to_s] }
  end

  def base_scope
    Issue.visible.joins(:project, :helpdesk_ticket)
  end

  def tickets(options = {})
    base_scope.where(statement).where(options[:conditions])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def tickets_with_votes_count
    @tickets_with_votes_count ||= tickets(:conditions => 'vote IS NOT NULL').count
  end

  def satisfaction_score
    awesome_percentage - not_good_percentage
  end

  def total_votes
    percentage(tickets_with_votes_count, tickets.count)
  end

  # Create _count and _percentage methods for votes
  %w(not_good just_ok awesome).each_with_index do |name, i|
    define_method "#{name}_count" do
      cached = instance_variable_get("@#{name}_count")
      return cached if cached
      instance_variable_set("@#{name}_count", tickets(:conditions => "vote = #{i}").count)
    end

    define_method "#{name}_percentage" do
      cached = instance_variable_get("@#{name}_percentage")
      return cached if cached
      instance_variable_set("@#{name}_percentage", percentage(send("#{name}_count"), tickets_with_votes_count))
    end
  end

  # Query issues table for the following fields, not helpdesk_tickets
  %w(assigned_to_id
     author_id
     category_id
     priority_id
     tracker_id).each do |field|
    define_method "sql_for_#{field}_field" do |f, op, val|
      sql_for_field(f, op, val, Issue.table_name, f)
    end
  end

  def sql_for_tags_field(_field, operator, value)
    operator = operator_for('tags').eql?('=') ? 'IN' : 'NOT IN'
    ids = Issue.tagged_with(value).map(&:id).join(',')
    "(#{Issue.table_name}.id #{operator} (#{ids}))"
  end

  def sql_for_customer_field(_field, operator, value)
    where_clause = ''

    if operator.in?(['=', '!'])
      where_clause = "WHERE #{HelpdeskTicket.table_name}.contact_id IN (#{value.join(',')})"
    end

    operator = operator.start_with?('!') ? 'NOT IN' : 'IN'
    ids = <<-SQL
      SELECT #{'DISTINCT' if where_clause.blank?}
        #{HelpdeskTicket.table_name}.issue_id
      FROM #{HelpdeskTicket.table_name}
      #{where_clause}
    SQL

    "(#{Issue.table_name}.id #{operator} (#{ids}))"
  end

  def sql_for_customer_company_field(_field, operator, value)
    like_statement =
      case operator
      when '='
        "LIKE '#{value.first.to_s.downcase}'"
      when '!*'
        "IS NULL OR #{Contact.table_name}.company = ''"
      when '*'
        "IS NOT NULL OR #{Contact.table_name}.company <> ''"
      when '~', '!~'
        "LIKE '%#{self.class.connection.quote_string(value.first.to_s.downcase)}%'"
      end

    operator = operator.start_with?('!') ? 'NOT IN' : 'IN'
    ids = <<-SQL
      SELECT #{HelpdeskTicket.table_name}.issue_id
      FROM #{HelpdeskTicket.table_name}
      WHERE #{HelpdeskTicket.table_name}.contact_id
            IN (SELECT #{Contact.table_name}.id
                FROM #{Contact.table_name}
                WHERE LOWER(#{Contact.table_name}.company) #{like_statement})
    SQL

    "(#{Issue.table_name}.id #{operator} (#{ids}))"
  end

  def sql_for_report_date_period_field(field, operator, value)
    sql_for_field(field, operator, value, queried_class.table_name, 'last_agent_response_at')
  end

  private

  def percentage(part, total)
    return 0 if total.zero?
    part / total.to_f * 100
  end

  def author_values
    return @author_values if @author_values

    @author_values = []
    @author_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
    Principal.where(:id => base_scope.pluck(:author_id).compact.uniq).sort.each { |p| @author_values << [p.name, p.id.to_s] }
    @author_values
  end

  def assigned_to_values
    return @assigned_to_values if @assigned_to_values

    @assigned_to_values = []
    @assigned_to_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
    Principal.where(:id => base_scope.pluck(:assigned_to_id).compact.uniq).sort.each { |p| @assigned_to_values << [p.name, p.id.to_s] }
    @assigned_to_values
  end

  def tags_values
    optional_project = project ? {:project => project} : {}
    Issue.available_tags(optional_project).map { |t| [t.name, t.name] }
  end
end
