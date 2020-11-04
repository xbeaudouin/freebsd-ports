class HelpdeskReportsController < ApplicationController
  unloadable
  menu_item :issues

  helper :helpdesk
  helper :queries
  include QueriesHelper

  before_action :find_optional_project
  before_action :authorize_global
  before_action :find_query

  def show
    return render_404 unless @query

    if @query.valid?
      @collector = HelpdeskDataCollectorManager.new.collect_data(@query)
    end
  end

  private

  def find_query
    report_query_class =
      case params[:report]
      when 'first_response_time'
        HelpdeskReportsFirstResponseQuery
      when 'busiest_time_of_day'
        HelpdeskReportsBusiestTimeQuery
      when 'customer_satisfaction'
        HelpdeskReportsCustomerSatisfactionQuery
      end
    return unless report_query_class

    if params[:set_filter] || session["helpdesk_reports_#{params[:report]}"].blank?
      @query = report_query_class
                 .new(:name => params[:report], :project => @project)
                 .build_from_params(params)

      session["helpdesk_reports_#{params[:report]}"] = {
        :project_id => @query.project_id,
        :filters => @query.filters
      }
    else
      @query = report_query_class.new(
        :name => params[:report],
        :project => @project,
        :filters => session["helpdesk_reports_#{params[:report]}"][:filters])
    end
  end
end
