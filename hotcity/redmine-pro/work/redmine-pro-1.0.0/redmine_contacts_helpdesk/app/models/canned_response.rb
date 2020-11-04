class CannedResponse < ActiveRecord::Base
  include Redmine::SafeAttributes

  attr_accessor :deleted_attachment_ids

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name', 'content', 'is_public', 'deleted_attachment_ids'

  belongs_to :project
  belongs_to :user

  acts_as_attachable

  validates_presence_of :name, :content
  validates_length_of :name, :maximum => 255

  after_save :delete_selected_attachments

  scope :visible, lambda { |*args|
    user = args.shift || User.current
    base = Project.allowed_to_condition(user, :view_helpdesk_tickets, *args)
    user_id = user.logged? ? user.id : 0

    eager_load(:project).where("(#{CannedResponse.table_name}.project_id IS NULL OR (#{base})) AND (#{CannedResponse.table_name}.is_public = ? OR #{CannedResponse.table_name}.user_id = ?)", true, user_id)
  }

  scope :in_project_or_public, lambda {|project|
    where("(#{CannedResponse.table_name}.project_id IS NULL) OR #{CannedResponse.table_name}.project_id = ?", project)
  }

  # Returns true if the query is visible to +user+ or the current user.
  def visible?(user = User.current)
    (project.nil? || user.allowed_to?(:view_helpdesk_tickets, project)) && (is_public? || user_id == user.id)
  end

  def deleted_attachment_ids
    Array(@deleted_attachment_ids).map(&:to_i)
  end

  def delete_selected_attachments
    if deleted_attachment_ids.present?
      objects = attachments.where(id: deleted_attachment_ids.map(&:to_i))
      attachments.delete(objects)
    end
  end
end
