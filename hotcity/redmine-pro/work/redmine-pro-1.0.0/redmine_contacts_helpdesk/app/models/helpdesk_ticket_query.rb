class HelpdeskTicketQuery < Query
  self.queried_class = HelpdeskTicket
  self.view_permission = :view_helpdesk_tickets

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { }
  end

  def initialize_available_filters
    add_available_filter "ticket_date", :type => :date_past
  end

  def build_from_params(params, defaults={})
    super
    @params = params
    self
  end

  def tickets(options = {})
    scope = base_scope
    scope = scope.joins(issue: { journals: :journal_message }) if @params[:include] && (%w[journals] & @params[:include].split(',')).any?
    scope = scope.where("contact_id IN ?", @params[:contact_id].split(',')) if @params[:contact_id]
    scope = scope.where("issue_id IN ?", @params[:issue_id].split(',')) if @params[:issue_id]
    scope = scope.where("source = ?", @params[:source]) if @params[:source]
    scope = scope.where("from_address = ?", @params[:from_address]) if @params[:from_address]
    scope = scope.where("message_id = ?", @params[:message_id]) if @params[:message_id]
    scope.limit(options[:limit])
         .offset(options[:offset])
  end

  def tickets_count
    tickets.count
  end

  private

  def base_scope
    HelpdeskTicket.where(statement)
  end
end
