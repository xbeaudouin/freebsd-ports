class HelpdeskDataCollectorManager
  def collect_data(query)
    case query.name
    when 'first_response_time'
      HelpdeskDataCollectorFirstResponse.new(query)
    when 'busiest_time_of_day'
      HelpdeskDataCollectorBusiestTime.new(query)
    end
  end
end
