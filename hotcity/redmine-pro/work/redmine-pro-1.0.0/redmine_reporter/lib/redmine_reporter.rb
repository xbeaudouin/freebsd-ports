require 'redmine_reporter/hooks/views_layouts_hook'
require 'redmine_reporter/hooks/view_issues_hook'
require 'redmine_reporter/hooks/views_context_menus_hook'

require 'redmine_reporter/patches/application_controller_patch'
require 'redmine_reporter/patches/issue_patch'
require 'redmine_reporter/patches/time_entry_patch'
require 'redmine_reporter/patches/application_helper_patch'
require 'redmine_reporter/patches/projects_helper_patch'

require 'redmine_reporter/liquid/liquid_filters'
require "redmine_reporter/liquid/drops/issues_drop"
require "redmine_reporter/liquid/drops/attachment_images_drop"

require 'zip'

module RedmineReporter
  SETTINGS_TABS = [
    { name: 'general', partial: 'settings/reporter/general', label: :label_general },
    { name: 'report_templates', partial: 'report_templates/index', label: :label_reporter_report_templates }
  ]

  def self.settings() Setting.plugin_redmine_reporter end

  def self.public_links?
    settings['public_links'] == '1'
  end

  def self.token(object_ids, report_template_ids)
    str = object_ids.inject('') { |str, id| str + "Object##{id}" }
    str += report_template_ids.inject('') { |str, id| str + "ReportTemplate##{id}" }
    Digest::MD5.hexdigest("#{str}:#{Rails.application.config.secret_token}")
  end

  def self.build_zip(reports)
    Zip::OutputStream.write_buffer do |zos|
      reports.each do |report|
        zos.put_next_entry report.filename
        zos.write report.to_pdf
      end
    end.string
  end
end
