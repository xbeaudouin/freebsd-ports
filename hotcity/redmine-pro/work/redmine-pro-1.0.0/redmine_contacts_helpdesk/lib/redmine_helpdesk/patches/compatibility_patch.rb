if Redmine::VERSION.to_s < '2.4'
  def accept_attachment?(_attachment)
    true
  end
end
