class TimeEntriesReportTemplate < ReportTemplate
  def self.label
    'label_reporter_report_time_entries'
  end

  def example_report
    generate_reports(TimeEntry.visible.first(10)).first
  end

  def generate_reports(time_entries, query_id = nil)
    [Report.new(name, filename, liquidize(time_entries), public_link_params(time_entries, query_id))]
  end

  def liquidize(object)
    assigns = {}
    assigns['time_entries'] = RedmineCrm::Liquid::TimeEntriesDrop.new(object)
    assigns['issues'] = RedmineCrm::Liquid::IssuesDrop.new(object.map(&:issue).compact.uniq)
    assigns['now'] = Time.now.utc
    assigns['today'] = Date.today

    registers = { container: object }

    Liquid::Template.parse(content).render(Liquid::Context.new({}, assigns, registers)).html_safe
  rescue => e
    e.message
  end

  def public_link_params(time_entries_ids, query_id)
    self.class.public_link_params(time_entries_ids, [self], query_id)
  end
end
