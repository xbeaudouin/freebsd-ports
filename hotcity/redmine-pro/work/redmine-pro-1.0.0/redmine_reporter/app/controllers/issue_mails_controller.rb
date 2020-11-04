class IssueMailsController < ApplicationController
  menu_item :issues

  before_action :find_issue, :authorize
  before_action :find_report_templates, only: :new
  before_action :find_attachments, only: :send_mail

  def new
    reports = @report_templates.map { |template| template.generate_reports([@issue]) }.flatten
    reports.each { |report| apply_layout!(report.content, 'reports.pdf') }

    @issue_mail = IssueMail.new({
      from: User.current.mail,
      subject: @issue.subject,
      attachments: reports.map(&:create_attachment)
    })
  end

  def send_mail
    @issue_mail = IssueMail.new(params[:issue_mail])
    @issue_mail.attachments = @attachments

    render(:new) && return if @issue_mail.invalid?

    begin
      ReportsMailer.issue_reports(@issue_mail).deliver
    rescue Exception => e
      flash[:error] = l(:notice_email_error, e.message)
      render(:new) && return
    end

    flash[:notice] = l(:notice_email_sent, @issue_mail.to)
    redirect_to issue_path(@issue)
  end

  def preview
    @text = params[:issue_mail][:message]
    render partial: 'common/preview'
  end

  private

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
