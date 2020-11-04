class IssuesReportTemplatesController < ApplicationController
  before_action :authorize_global, except: [:create, :preview]
  before_action :set_report_type, only: [:new, :autocomplete]
  before_action :set_issue_ids, :set_preview_url_options, only: :new
  before_action :find_issues, :find_report_templates, only: [:create, :attach, :preview]
  before_action :authorize_public, only: [:create, :preview]

  skip_before_action :check_if_login_required, only: [:create, :preview], if: :public_request?

  def new
    @issue = Issue.find(params[:issue_id]) if params[:issue_id].present?
    @report_templates = issue_report_templates
  end

  def create
    reports = @report_templates.map { |t| t.generate_reports(@issues, params[:query_id]) }.flatten
    reports.each { |report| apply_layout!(report.content, 'reports.pdf') }

    if reports.size > 1
      send_data RedmineReporter.build_zip(reports), type: 'application/zip', filename: 'issues reports.zip'
    else
      report = reports.first
      send_data report.to_pdf, type: 'application/pdf', filename: report.filename
    end
  end

  def autocomplete
    @report_templates = issue_report_templates
    render layout: false
  end

  def attach
    issue = @issues.first
    issue.init_journal(User.current)

    reports = @report_templates.map { |template| template.generate_reports([issue]) }.flatten
    reports.each { |report| apply_layout!(report.content, 'reports.pdf') }

    attachments = reports.map { |report| { 'token' => report.create_attachment.token } }
    issue.save_attachments(attachments)
    issue.save

    flash[:notice] = l(:notice_successful_update) unless issue.current_journal.new_record?
    render_attachment_warning_if_needed(issue)
    redirect_to_referer_or { render html: l(:notice_successful_update), status: 200, layout: true }
  end

  def preview
    @reports = @report_templates.map { |t| t.generate_reports(@issues, params[:query_id]) }.flatten

    options = ReportTemplate.public_link_params(@issues, @report_templates, params[:query_id])
    @public_link_url = preview_issues_report_templates_path(options)

    if @issues.size == 1 && User.current.allowed_to?(:send_issues, nil, global: true)
      @send_email_url = new_issue_mail_path issue_id: @issues.first.id, report_template: { ids: @report_templates.map(&:id) }
    end
    @download_url = issues_report_templates_path(options.merge(token: params[:token]))

    render layout: 'reports.pdf'
  end

  private

  def issue_report_templates
    scope = @report_type.issue_templates
    scope = scope.live_search(params[:q]) if params[:q].present?
    scope.to_a
  end

  def set_report_type
    @report_type = params[:issue_id].blank? ? ReportTemplate : IssueReportTemplate
  end

  def set_issue_ids
    @issue_ids = params[:issue_ids] || [params[:issue_id]]
  end

  def set_preview_url_options
    @preview_url_options =
      if params[:query_id]
        { query_id: params[:query_id] }
      else
        { issue_ids: params[:issue_ids] || [params[:issue_id]] }
      end
  end

  def find_issues
    @issues =
      if params[:query_id]
        IssueQuery.find(params[:query_id]).issues
      else
        Issue.where(id: params[:issue_ids])
      end

    raise ActiveRecord::RecordNotFound if @issues.empty?
    raise Unauthorized if !params[:token] && !@issues.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_public
    return authorize_global unless params[:token]
    RedmineReporter.public_links? && valid_token? || render_403
  end

  def valid_token?
    params[:token] ==
      ReportTemplate.public_link_token(@issues.map(&:id), @report_templates.map(&:id), params[:query_id])
  end

  def public_request?
    params[:token].present?
  end
end
