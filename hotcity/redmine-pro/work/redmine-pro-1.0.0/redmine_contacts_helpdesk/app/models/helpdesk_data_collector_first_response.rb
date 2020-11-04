class HelpdeskDataCollectorFirstResponse
  MAX_WEIGHT = 200

  RESPONSE_INTERVALS = { '0_1h' => [0, 1],
                         '1_2h' => [1, 2],
                         '2_4h' => [2, 4],
                         '4_8h' => [4, 8],
                         '8_12h' => [8, 12],
                         '12_24h' => [12, 24],
                         '24_48h' => [24, 48],
                         '48_0h' => [48, 0] }
  attr_reader :issues
  attr_reader :previous_issues

  def columns
    @columns ||= collect_columns
  end

  def issue_weight
    @issue_weight ||= (MAX_WEIGHT.to_f / columns.map { |column| column[:issues_count] }.sort.last).ceil
  end

  # First response time
  def average_response_time
    @average_response_time ||= median(HelpdeskTicket.where(:issue_id => issues.pluck(:id)).pluck(:first_response_time))
  end

  def previous_average_response_time
    return 0 if previous_issues_count.zero?
    @previous_average_response_time ||= median(HelpdeskTicket.where(:issue_id => previous_issues.pluck(:id)).pluck(:first_response_time))
  end

  def average_response_time_progress
    return 0 if previous_issues_count.zero?
    calculate_progress(previous_average_response_time, average_response_time)
  end

  # Time to close
  def average_close_time
    return @average_close_time if @average_close_time
    closed_issue_ids = issues.joins(:status).where("#{IssueStatus.table_name}.is_closed = ?", true).pluck(:id)
    return 0 if closed_issue_ids.empty?
    @average_close_time = median(HelpdeskTicket.where(:issue_id => closed_issue_ids).pluck(:resolve_time))
  end

  def previous_average_close_time
    return @previous_average_close_time if @previous_average_close_time.present?
    closed_issue_ids = previous_issues.joins(:status).where("#{IssueStatus.table_name}.is_closed = ?", true).pluck(:id)
    return 0 if closed_issue_ids.empty?
    @previous_average_close_time ||= median(HelpdeskTicket.where(:issue_id => closed_issue_ids).pluck(:resolve_time))
  end

  def average_close_time_progress
    closed_issue_ids = previous_issues.joins(:status).where("#{IssueStatus.table_name}.is_closed = ?", true).pluck(:id)
    return 0 if closed_issue_ids.empty?
    calculate_progress(previous_average_close_time, average_close_time)
  end

  # Average responses count
  def average_response_count
    return @average_response_count if @average_response_count
    closed_issue_ids = issues.joins(:status).where("#{IssueStatus.table_name}.is_closed = ?", true).pluck(:id)
    return @average_response_count = 0 if closed_issue_ids.empty?
    journal_ids = JournalMessage.joins(:journal).where("journals.journalized_type = 'Issue'").
                                                 where(journal_message_date_condition(@query)).
                                                 where("journals.journalized_id IN (#{closed_issue_ids.join(',')})").pluck(:journal_id)
    @average_response_count = median(Journal.where(:id => journal_ids).group(:journalized_id).count(:id).values)
  end

  def previous_average_response_count
    return 0 if previous_issues_count.zero?
    return @previous_average_response_count if @previous_average_response_count
    closed_issue_ids = previous_issues.joins(:status).where("#{IssueStatus.table_name}.is_closed = ?", true).pluck(:id)
    return @previous_average_response_count = 0 if closed_issue_ids.empty?
    journal_ids = JournalMessage.joins(:journal).where("journals.journalized_type = 'Issue'").
                                                 where(journal_message_date_condition(previous_query)).
                                                 where("journals.journalized_id IN (#{closed_issue_ids.join(',')})").pluck(:journal_id)

    @previous_average_response_count = median(Journal.where(:id => journal_ids).group(:journalized_id).count(:id).values)
  end

  def average_response_count_progress
    return 0 if previous_average_response_count.zero?
    calculate_progress(previous_average_response_count, average_response_count)
  end

  # Total replies
  def total_response_count
    return @total_response_count if @total_response_count
    @total_response_count = JournalMessage.joins(:journal).where("journals.journalized_type = 'Issue'").
                                           where(journal_message_date_condition(@query)).
                                           where("journals.journalized_id IN (#{issues.pluck(:id).join(',')})").
                                           count
  end

  def previous_total_response_count
    return 0 if previous_issues_count.zero?
    return @previous_total_response_count if @previous_total_response_count
    @previous_total_response_count ||= JournalMessage.joins(:journal).where("journals.journalized_type = 'Issue'").
                                                      where(journal_message_date_condition(previous_query)).
                                                      where("journals.journalized_id IN (#{previous_issues.pluck(:id).join(',')})").
                                                      count
  end

  def total_response_count_progress
    return 0 if previous_total_response_count.zero?
    calculate_progress(previous_total_response_count, total_response_count)
  end

  def issues_count
    @issues_count ||= issues.count
  end

  def previous_issues_count
    @previous_issues_count ||= previous_issues.count
  end

  private

  def initialize(query)
    @query = query
    @issues = @query.issues.joins(:helpdesk_ticket).where('helpdesk_tickets.first_response_time > 0')
    @issues = Rails.version >= '5.1' ? @issues.distinct : @issues.uniq
    @previous_issues = previous_query.issues.joins(:helpdesk_ticket).where('helpdesk_tickets.first_response_time > 0')
    @previous_issues = Rails.version >= '5.1' ? @previous_issues.distinct : @previous_issues.uniq
  end

  def collect_columns
    columns = []
    RESPONSE_INTERVALS.each do |interval_name, interval_hours|
      interval_issues_count = find_issues_count(interval_hours)
      columns << { :name => interval_name, :issues_count => interval_issues_count,
                   :issues_percent => ((interval_issues_count.to_f / issues_count.to_f) * 100).round(2) }
    end
    columns
  end

  def find_issues_count(interval)
    interval_start = (interval.first.hours + 1).to_i
    interval_end = interval.last.hours.to_i
    interval_issues =
      if interval.last > 0
        issues.joins(:helpdesk_ticket).where('helpdesk_tickets.first_response_time BETWEEN ? AND ?', interval_start, interval_end)
      else
        issues.joins(:helpdesk_ticket).where('helpdesk_tickets.first_response_time > ?', interval_start)
      end
    interval_issues.count
  end

  def previous_query
    return if @query[:filters].nil? || @query[:filters]['report_date_period'].nil? || @query[:filters]['report_date_period'][:operator].nil?
    return @previous_query if @previous_query

    previous_operator = ['pre_', @query[:filters]['report_date_period'][:operator]].join
    previous_filters = @query[:filters].merge('report_date_period' => { :operator => previous_operator, :values => [Date.today.to_s] })
    @previous_query = HelpdeskReportsFirstResponseQuery.new(:name => '_', :project => @query.project, :filters => previous_filters)
    @previous_query
  end

  def journal_message_date_condition(query)
    query.send('sql_for_field', nil, query.filters['report_date_period'][:operator], nil, 'journal_messages', 'message_date')
  end

  def median(array)
    return 0 if array.compact.empty?
    range = array.compact.sort.reverse
    middle = range.count / 2
    (range.count % 2).zero? ? (range[middle - 1] + range[middle]) / 2 : range[middle]
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
