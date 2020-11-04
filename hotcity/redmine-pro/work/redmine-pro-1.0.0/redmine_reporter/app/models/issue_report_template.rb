class IssueReportTemplate < ReportTemplate
  def self.label
    'label_reporter_report_issue'
  end

  def filename(extension = '.pdf', options = {})
    options[:issue].blank? ? super : "#{name}-#{options[:issue].id}#{extension}"
  end

  def example_report
    generate_reports([Issue.visible.first]).first
  end

  def generate_reports(issues, _query_id = nil)
    issues.map do |issue|
      Report.new(
        "#{name} (##{issue.id})",
        filename('.pdf', issue: issue),
        liquidize(issue),
        public_link_params(issue)
      )
    end
  end

  def liquidize(object)
    assigns = {}
    assigns['issue'] = RedmineCrm::Liquid::IssueDrop.new(object)
    assigns['now'] = Time.now.utc
    assigns['today'] = Date.today

    registers = { container: object }

    Liquid::Template.parse(content).render(Liquid::Context.new({}, assigns, registers)).html_safe
  rescue => e
    e.message
  end

  def public_link_params(issue)
    self.class.public_link_params([issue], [self])
  end
end
