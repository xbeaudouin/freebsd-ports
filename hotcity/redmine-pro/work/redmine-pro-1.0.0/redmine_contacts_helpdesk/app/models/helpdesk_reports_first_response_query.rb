class HelpdeskReportsFirstResponseQuery < HelpdeskReportsQuery

  def sql_for_report_date_period_field(_field, operator, value)
    sql_for_field('message_date', operator, value, queried_class.table_name, 'message_date')
  end
end
