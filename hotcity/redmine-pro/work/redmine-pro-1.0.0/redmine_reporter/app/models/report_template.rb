class ReportTemplate < ActiveRecord::Base
  include Redmine::SafeAttributes

  validates :name, presence: true
  validates :name, length: { maximum: 255 }

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name', 'description', 'content', 'project_id', 'autor_id'

  belongs_to :project
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  scope :in_project_and_global, lambda { |project|
    where("#{table_name}.project_id IS NULL OR #{table_name}.project_id = 0 OR #{table_name}.project_id = ?", project)
  }

  scope :live_search, lambda { |q| where("(LOWER(#{table_name}.name) LIKE LOWER(?))", "%#{q}%") }
  scope :sorted, ->() { order(:id) }
  scope :issue_templates, -> { where(type: ['IssueReportTemplate', 'IssueListReportTemplate']) }

  def self.available_types
    [IssueReportTemplate, IssueListReportTemplate, TimeEntriesReportTemplate]
  end

  def self.import(file, project, rewrite)
    attributes = YAML.load_file(file)
    report_template_model = attributes['type'].constantize
    report_template = report_template_model.find_by_name(attributes['name']) || report_template_model.new
    return false if rewrite.to_i.zero? && report_template.persisted?

    report_template.safe_attributes = attributes
    report_template.author = User.current
    report_template.project = project
    report_template.save
  rescue Exception
    return false
  end

  def self.public_link_params(objects, report_templates, query_id = nil)
    object_ids = objects.map(&:id)
    report_template_ids = report_templates.map(&:id)

    options = {
      report_template: { ids: report_template_ids },
      token: public_link_token(object_ids, report_template_ids, query_id)
    }

    if query_id
      options[:query_id] = query_id
    elsif objects.first.is_a?(Issue)
      options[:issue_ids] = object_ids
    elsif objects.first.is_a?(TimeEntry)
      options[:time_entries_ids] = object_ids
    end

    options
  end

  def self.public_link_token(object_ids, report_template_ids, query_id = nil)
    RedmineReporter.token(query_id ? ["Query##{query_id}"] : object_ids, report_template_ids)
  end

  def filename(extension = '.pdf', options = {}) "#{name}#{extension}" end

  def export_to_yaml
    attributes.except('id', 'author_id', 'project_id', 'created_at', 'updated_at').to_yaml
  end

  def generate_reports(object)
    raise NotImplementedError
  end

  def liquidize(object)
    raise NotImplementedError
  end

  protected

  def self.label
    raise NotImplementedError
  end
end
