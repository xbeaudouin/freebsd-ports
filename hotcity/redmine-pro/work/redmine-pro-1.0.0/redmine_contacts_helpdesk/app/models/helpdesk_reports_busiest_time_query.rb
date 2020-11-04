class HelpdeskReportsBusiestTimeQuery < HelpdeskReportsQuery

  def sql_for_staff_field(_field, operator, value)
    issue_table = Issue.table_name
    compare = operator == '=' ? 'IN' : 'NOT IN'
    staff_ids = value.join(',')
    "#{issue_table}.id IN(SELECT #{issue_table}.id FROM #{issue_table} WHERE (#{issue_table}.assigned_to_id #{compare} (#{staff_ids})))"
  end

  def sql_for_report_date_period_field(_field, operator, value)
    sql_for_field('message_date', operator, value, queried_class.table_name, 'message_date')
  end

  private

  def answered_user_ids
    @answered_user_ids ||= begin
      scope = Issue.visible.joins(:project)
                .where("#{Issue.table_name}.assigned_to_id IS NOT NULL")

      scope = Rails.version >= '5.1' ? scope.distinct : scope.uniq
      scope.pluck(:assigned_to_id)
    end
  end
end
