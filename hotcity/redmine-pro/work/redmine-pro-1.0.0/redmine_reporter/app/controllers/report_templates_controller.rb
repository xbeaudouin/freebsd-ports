class ReportTemplatesController < ApplicationController
  before_action :set_project, only: [:new, :create, :edit, :update, :destroy, :new_import, :import]
  before_action :authorize_global
  before_action :find_report_template, only: [:edit, :update, :destroy, :preview, :export]

  def new
    @report_template = IssueReportTemplate.new
    @report_template.project = @project
    @report_template.author = User.current
  end

  def create
    @report_template = params[:report_template][:type].constantize.new
    @report_template.safe_attributes = params[:report_template]
    @report_template.project = params[:report_template_is_for_all] ? nil : @project
    @report_template.author = User.current

    if @report_template.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_report_templates_tab
    else
      render :new
    end
  end

  def edit
  end

  def update
    @report_template.safe_attributes = params[:report_template]
    @report_template.type = params[:report_template][:type]
    @report_template.project = nil if params[:report_template_is_for_all]

    if @report_template.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_report_templates_tab
    else
      render :edit
    end
  end

  def destroy
    @report_template.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to_report_templates_tab
  end

  def preview
    report = @report_template.example_report
    apply_layout!(report.content, 'reports.pdf')
    send_data report.to_pdf, type: 'application/pdf', filename: 'report-preview.pdf', disposition: 'inline'
  end

  def export
    send_data @report_template.export_to_yaml, type: 'text/yaml; header=present', filename: @report_template.filename('.yml')
  end

  def new_import
  end

  def import
    if params[:file] && ReportTemplate.import(params[:file].tempfile, @project, params[:rewrite])
      flash[:notice] = l(:notice_reporter_import_success)
      redirect_to_report_templates_tab
    else
      flash.now[:error] = l(:error_reporter_can_not_import_file)
      render :new_import
    end
  end

  private

  def set_project
    find_project_by_project_id unless params[:project_id].blank?
  end

  def redirect_to_report_templates_tab
    if @project
      redirect_to settings_project_path(@project, tab: 'report_templates')
    else
      redirect_to plugin_settings_path(Redmine::Plugin.find(:redmine_reporter), tab: 'report_templates')
    end
  end

  def find_report_template
    @report_template = ReportTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
