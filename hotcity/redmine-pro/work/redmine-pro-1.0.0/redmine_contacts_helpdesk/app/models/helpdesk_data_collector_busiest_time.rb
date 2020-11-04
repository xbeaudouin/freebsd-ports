class HelpdeskDataCollectorBusiestTime
  MAX_WEIGHT = 200

  RESPONSE_INTERVALS = {'6_8h' => [6, 8],
                        '8_10h' => [8, 10],
                        '10_12h' => [10, 12],
                        '12_14h' => [12, 14],
                        '14_16h' => [14, 16],
                        '16_18h' => [16, 18],
                        '18_20h' => [18, 20],
                        '20_22h' => [20, 22],
                        '22_0h' => [22, 0],
                        '0_2h' => [0, 2],
                        '2_4h' => [2, 4],
                        '4_6h' => [4, 6]}

  def columns
    @columns ||= collect_columns
  end

  def issue_weight
    @issue_weight ||= (MAX_WEIGHT.to_f / columns.map { |column| column[:issues_count] }.sort.last).ceil
  end

  # New tickets
  def new_issues_count
    return @new_issues_count if @new_issues_count
    condition = @query.send('sql_for_field', nil, @query.filters['report_date_period'][:operator], nil, 'issues', 'created_on')
    @new_issues_count ||= @issues.where(condition).count
  end

  def previous_new_issues_count
    return @previous_new_issues_count if @previous_new_issues_count
    condition = previous_query.send('sql_for_field', nil, previous_query.filters['report_date_period'][:operator], nil, 'issues', 'created_on')
    @previous_new_issues_count ||= @previous_issues.where(condition).count
  end

  def new_issue_count_progress
    return 0 if previous_new_issues_count.zero?
    calculate_progress(previous_new_issues_count, new_issues_count)
  end

  # New contacts
  def contacts_count
    contacts.count
  end

  def previous_contacts_count
    previous_contacts.count
  end

  def total_contacts_count_progress
    return 0 if previous_contacts_count.zero?
    calculate_progress(previous_contacts_count, contacts_count)
  end

  # Total incoming
  def issues_count
    @issues_count ||= @issues.count + @journal_messages.count
  end

  def previous_issues_count
    @previous_issues_count ||= @previous_issues.count + @previous_journal_messages.count
  end

  def issue_count_progress
    return 0 if previous_issues_count.zero?
    calculate_progress(previous_issues_count, issues_count)
  end

  private

  def initialize(query)
    @query = query
    @issues = with_created_issues(@query)
    @journal_messages = JournalMessage.where(:is_incoming => true).
                                       where(@query.send('sql_for_field', nil, @query.filters['report_date_period'][:operator], nil, 'journal_messages', 'message_date'))
    @previous_issues = with_created_issues(previous_query)
    @previous_journal_messages = JournalMessage.where(:is_incoming => true).
                                               where(previous_query.send('sql_for_field', nil, @query.filters['report_date_period'][:operator], nil, 'journal_messages', 'message_date'))
  end

  def collect_columns
    columns = []
    RESPONSE_INTERVALS.each do |interval_name, interval_hours|
      interval_objects_count = find_incoming_objects_count(interval_hours)
      columns << { :name => interval_name, :issues_count => interval_objects_count,
                   :issues_percent => ((interval_objects_count.to_f / issues_count.to_f) * 100).round(2) }
    end
    columns
  end

  def find_incoming_objects_count(interval)
    interval_start = interval.first
    interval_end = interval.last - 1 < 0 ? 23 : interval.last - 1
    interval_issues = @issues.each.select do |issue|
      issue_time = timezone ? issue.created_on.in_time_zone(timezone) : issue.created_on.localtime
      interval_start <= issue_time.hour && issue_time.hour <= interval_end
    end
    interval_messages = @journal_messages.each.select do |message|
      message_time = timezone ? message.message_date.in_time_zone(timezone) : message.message_date.localtime
      interval_start <= message_time.hour && message_time.hour <= interval_end
    end
    interval_issues.count + interval_messages.count
  end

  def timezone
    @timezone ||= User.current.time_zone
  end

  def previous_query
    return if @query[:filters].nil? || @query[:filters]['report_date_period'].nil? || @query[:filters]['report_date_period'][:operator].nil?
    return @previous_query if @previous_query

    previous_operator = ['pre_', @query[:filters]['report_date_period'][:operator]].join
    previous_filters = @query[:filters].merge('report_date_period' => { :operator => previous_operator, :values => [Date.today.to_s] })
    @previous_query = HelpdeskReportsBusiestTimeQuery.new(:name => '_', :project => @query.project, :filters => previous_filters)
    @previous_query
  end

  def with_created_issues(query)
    condition = query.send('sql_for_field', nil, query.filters['report_date_period'][:operator], nil, 'issues', 'created_on')
    created_ids = Issue.joins(:project).visible.where(:project_id => query.project).where(condition).pluck(:id)
    Issue.where(:id => query.issues.pluck(:id) | created_ids).joins(:helpdesk_ticket)
  end

  def contacts
    return @contacts if @contacts
    condition = @query.send('sql_for_field', nil, @query.filters['report_date_period'][:operator], nil, 'contacts', 'created_on')
    @contacts = Contact.where(:id => @issues.joins(:customer).map(&:customer).map(&:id).uniq).where(condition)
  end

  def previous_contacts
    return @previous_contacts if @previous_contacts
    condition = @query.send('sql_for_field', nil, @previous_query.filters['report_date_period'][:operator], nil, 'contacts', 'created_on')
    @previous_contacts = Contact.where(:id => @previous_issues.joins(:customer).map(&:customer).map(&:id).uniq).where(condition)
  end

  def calculate_progress(before, now)
    progress =
      if before.to_f > now.to_f
        100 - (now.to_f * 100 / before.to_f)
      else
        (100 - (before.to_f * 100 / now.to_f)) * -1
      end
    progress.round
  end
end
