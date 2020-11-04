class TimeEntriesReportsController < ApplicationController
  before_action :authorize_global, except: [:create, :preview]
  before_action :set_preview_url_options, only: :new
  before_action :find_time_entries, :find_report_templates, only: [:create, :preview]
  before_action :authorize_public, only: [:create, :preview]

  skip_before_action :check_if_login_required, only: [:create, :preview], if: :public_request?

  def new
    @report_templates = TimeEntriesReportTemplate.all
  end

  def create
    reports = @report_templates.map { |t| t.generate_reports(@time_entries, params[:query_id]) }.flatten
    reports.each { |report| apply_layout!(report.content, 'reports.pdf') }

    if reports.size > 1
      send_data RedmineReporter.build_zip(reports), type: 'application/zip', filename: 'time entries reports.zip'
    else
      report = reports.first
      send_data report.to_pdf, type: 'application/pdf', filename: report.filename
    end
  end

  def autocomplete
    scope = TimeEntriesReportTemplate.where({})
    scope = scope.live_search(params[:q]) if params[:q].present?
    @report_templates = scope.to_a
    render layout: false
  end

  def preview
    @reports = @report_templates.map { |t| t.generate_reports(@time_entries, params[:query_id]) }.flatten

    options = TimeEntriesReportTemplate.public_link_params(@time_entries, @report_templates, params[:query_id])
    @public_link_url = preview_time_entries_reports_path(options)
    @download_url = time_entries_reports_path(options.merge(token: params[:token]))

    render layout: 'reports.pdf'
  end

  private

  def set_preview_url_options
    @preview_url_options =
      if params[:query_id]
        { query_id: params[:query_id] }
      else
        { time_entries_ids: params[:time_entries_ids] }
      end
  end

  def find_time_entries
    @time_entries =
      if params[:query_id]
        TimeEntryQuery.find(params[:query_id]).results_scope
      else
        TimeEntry.where(id: params[:time_entries_ids])
      end

    raise ActiveRecord::RecordNotFound if @time_entries.empty?
    raise Unauthorized if !params[:token] && !@time_entries.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_report_templates
    @report_templates = []
    if params[:report_template] && params[:report_template][:ids].present?
      @report_templates = TimeEntriesReportTemplate.find(params[:report_template][:ids])
    end

    if @report_templates.blank?
      flash[:error] = l(:label_reporter_templates_no_selected)
      redirect_to_referer_or { render html: l(:label_reporter_templates_no_selected), status: 200, layout: true }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_public
    return authorize_global unless params[:token]
    RedmineReporter.public_links? && valid_token? || render_403
  end

  def valid_token?
    params[:token] ==
      ReportTemplate.public_link_token(@time_entries.map(&:id), @report_templates.map(&:id), params[:query_id])
  end

  def public_request?
    params[:token].present?
  end
end
