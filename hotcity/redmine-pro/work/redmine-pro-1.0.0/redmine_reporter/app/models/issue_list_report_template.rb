class IssueListReportTemplate < ReportTemplate
  def self.label
    'label_reporter_report_issue_list'
  end

  def example_report
    generate_reports(Issue.visible.first(10)).first
  end

  def generate_reports(issues, query_id = nil)
    [Report.new(name, filename, liquidize(issues), public_link_params(issues, query_id))]
  end

  def liquidize(object)
    assigns = {}
    assigns['issues'] = RedmineCrm::Liquid::IssuesDrop.new(object)
    assigns['now'] = Time.now.utc
    assigns['today'] = Date.today

    registers = { container: object }

    Liquid::Template.parse(content).render(Liquid::Context.new({}, assigns, registers)).html_safe
  rescue => e
    e.message
  end

  def public_link_params(issues, query_id)
    self.class.public_link_params(issues, [self], query_id)
  end
end
