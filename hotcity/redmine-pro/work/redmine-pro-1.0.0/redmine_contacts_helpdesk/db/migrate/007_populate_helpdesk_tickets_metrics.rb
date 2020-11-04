class PopulateHelpdeskTicketsMetrics < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    HelpdeskTicket.joins(:issue).readonly(false).each(&:save)
  end

  def down
    #none
  end
end
