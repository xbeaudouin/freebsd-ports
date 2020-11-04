# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

class PeopleReportsUserActivityQuery < PeopleReportsQuery

  def initialize_available_filters
    add_available_filter 'activity_type', type: :list, name: l(:label_people_filter_activity_type),
                                          values: activity_types

    add_available_filter 'report_date_period', type: :time_interval, name: l(:label_people_filter_time_interval)
    add_available_filter 'assignee', type: :list, name: l(:field_assigned_to), values: extracted_values(activity_users)
    add_available_filter 'group', type: :list, name: l(:field_member_of_group), values: extracted_values(activity_groups)
    add_available_filter 'tracker', type: :list, name: l(:field_tracker), values: extracted_values(activity_project_trackers)
    add_available_filter 'tag', type: :issue_tags, name: l(:tags), values: [] if Redmine::Plugin.installed? 'redmineup_tags'

    add_contacts_filter
    add_companies_filter
  end

  def available_filters
    avl_filters = super
    if filters['tag'].present?
      avl_filters['tag'][:values] = Issue.all_tags(open_only: RedmineupTags.settings['issues_open_only'].to_i == 1)
                                         .where(name: filters['tag'][:values]).map { |c| [c.name, c.name] }
    end
    avl_filters
  end

  def filtered_issues
    @filtered_issues ||= apply_filters_to(issues)
  end

  def filtered_journals
    @filtered_journals ||= apply_filters_to(journals)
  end

  def filtered_time_entries
    @filtered_time_entries ||= apply_filters_to(time_entries)
  end

  def filtered_previous_issues(users_involved)
    @filtered_previous_issues ||= apply_filters_to_past(issues.where(author_id: users_involved))
  end

  def filtered_previous_journals(users_involved)
    @filtered_previous_journals ||= apply_filters_to_past(journals.where(user_id: users_involved))
  end

  def filtered_previous_time_entries(users_involved)
    @filtered_previous_time_entries ||= apply_filters_to_past(time_entries.where(user_id: users_involved))
  end

  def activity_principal_ids
    @activity_principals ||= activity_users.pluck(:id) + activity_groups.pluck(:id)
  end

  private

  def projects
    return [] unless project

    @projecs ||= Project.where(id: project.children.active.pluck(:id) << project.id)
  end

  def issues
    return @issues if @issues
    @issues = Issue.visible
    @issues = @issues.where(project: projects) if projects.any?
    @issues
  end

  def journals
    @journals ||= Journal.where(journalized: issues).visible
  end

  def time_entries
    return @time_entries if @time_entries
    @time_entries = TimeEntry.visible
    @time_entries = @time_entries.where(project: projects) if projects.any?
    @time_entries
  end

  def extracted_values(collection)
    collection.map { |principal| [principal.name, principal.id.to_s] }
  end

  def activity_types
    [[l(:label_activity_type_issue_create), :create_issue],
     [l(:label_activity_type_issue_update), :update_issue],
     [l(:label_activity_type_spent_time_added), :add_spent_time]]
  end

  def activity_users
    return @activity_users if @activity_users
    user_ids = Member.active.where("users.type = 'User'")
    user_ids = user_ids.where(project_id: projects) if projects.any?
    @activity_users = Principal.where(id: user_ids.pluck(:user_id).uniq).order(:firstname, :lastname)
  end

  def activity_groups
    return @activity_groups if @activity_groups
    group_ids = Member.active.where("users.type = 'Group'")
    group_ids = group_ids.where(project_id: projects) if projects.any?
    @activity_groups = Principal.where(id: group_ids.pluck(:user_id).uniq).order(:firstname, :lastname)
  end

  def activity_project_trackers
    return @activity_project_trackers if @activity_project_trackers
    @activity_project_trackers = Project.preload(:trackers)
    @activity_project_trackers = @activity_project_trackers.where(id: projects) if projects.any?
    @activity_project_trackers = @activity_project_trackers.map(&:trackers).flatten.uniq
  end

  def add_contacts_filter
    return if available_filters.key?('contacts') || project.nil? || !User.current.allowed_to?(:view_contacts, project)

    filter_values = filters['contacts'].nil? ? [] : extracted_values(Contact.where(id: filters['contacts'][:values]))
    add_available_filter('contacts', type: :list, name: l(:field_contacts), field_format: 'contact', values: filter_values)
  end

  def add_companies_filter
    return if available_filters.key?('companies') || project.nil? || User.current.allowed_to?(:view_contacts, project)

    filter_values = filters['companies'].nil? ? [] : extracted_values(Contact.where(id: filters['companies'][:values]))
    add_available_filter('companies', type: :list, name: l(:field_companies), field_format: 'company', values: filter_values)
  end

  def tags_values
    projects.collect { |project| Issue.available_tags(project: project) }.flatten.uniq
  end

  def apply_filters_to(relation)
    filters.each do |filter_name, filter_params|
      relation = apply_filter(filter_name, filter_params, relation)
    end
    relation
  end

  def apply_filters_to_past(relation)
    filters.each do |filter_name, filter_params|
      filter_params = filter_params.merge(operator: ['pre_', filter_params[:operator].join]) if filter_name == 'message_date'
      relation = apply_filter(filter_name, filter_params, relation)
    end
    relation
  end

  def apply_filter(filter_name, filter_params, relation)
    method_name = ['filter_' + relation.table_name + '_by_' + filter_name].join
    relation = send(method_name, filter_params, relation) if respond_to?(method_name, true)
    relation
  end

  def filter_issues_by_report_date_period(params, relation)
    relation.where(sql_for_field(:message_date, params[:operator], params[:values], Issue.table_name, 'created_on'))
  end

  def filter_journals_by_report_date_period(params, relation)
    relation.where(sql_for_field(:message_date, params[:operator], params[:values], Journal.table_name, 'created_on'))
  end

  def filter_time_entries_by_report_date_period(params, relation)
    relation.where(sql_for_field(:message_date, params[:operator], params[:values], TimeEntry.table_name, 'spent_on'))
  end

  def filter_issues_by_assignee(params, relation)
    assignee_id = params[:values].first
    case params[:operator].first
    when '='
      relation.where(assigned_to_id: assignee_id, author_id: assignee_id)
    when '!'
      relation.where.not(assigned_to_id: assignee_id)
    end
  end

  def filter_journals_by_assignee(params, relation)
    assignee_id = params[:values].first
    case params[:operator].first
    when '='
      relation.joins(:issue).merge(issues.where(assigned_to_id: assignee_id)).where(user_id: assignee_id)
    when '!'
      relation.joins(:issue).merge(issues.where.not(assigned_to_id: assignee_id))
    end
  end

  def filter_time_entries_by_assignee(params, relation)
    assignee_id = params[:values].first
    case params[:operator].first
    when '='
      relation.joins(:issue).merge(issues.where(assigned_to_id: assignee_id)).where(user_id: assignee_id)
    when '!'
      relation.joins(:issue).merge(issues.where.not(assigned_to_id: assignee_id))
    end
  end

  def filter_issues_by_group(params, relation)
    join_table = "#{User.table_name_prefix}groups_users#{User.table_name_suffix}"
    group_id = params[:values].first
    case params[:operator].first
    when '='
      relation.joins("INNER JOIN #{join_table} ON #{join_table}.user_id = #{Issue.table_name}.author_id").where("#{join_table}.group_id = ?", group_id)
    when '!'
      relation.joins("INNER JOIN #{join_table} ON #{join_table}.user_id = #{Issue.table_name}.author_id").where("#{join_table}.group_id <> ?", group_id)
    end
  end

  def filter_journals_by_group(params, relation)
    join_table = "#{User.table_name_prefix}groups_users#{User.table_name_suffix}"
    group_id = params[:values].first
    case params[:operator].first
    when '='
      relation.joins("INNER JOIN #{join_table} ON #{join_table}.user_id = #{Journal.table_name}.user_id").where("#{join_table}.group_id = ?", group_id)
    when '!'
      relation.joins("INNER JOIN #{join_table} ON #{join_table}.user_id = #{Journal.table_name}.user_id").where("#{join_table}.group_id <> ?", group_id)
    end
  end

  def filter_time_entries_by_group(params, relation)
    join_table = "#{User.table_name_prefix}groups_users#{User.table_name_suffix}"
    group_id = params[:values].first
    case params[:operator].first
    when '='
      relation.joins("INNER JOIN #{join_table} ON #{join_table}.user_id = #{TimeEntry.table_name}.user_id").where("#{join_table}.group_id = ?", group_id)
    when '!'
      relation.joins("INNER JOIN #{join_table} ON #{join_table}.user_id = #{TimeEntry.table_name}.user_id").where("#{join_table}.group_id <> ?", group_id)
    end
  end

  def filter_issues_by_tracker(params, relation)
    tracker_id = params[:values].first
    params[:operator].first == '=' ? relation.where(tracker_id: tracker_id) : relation.where.not(tracker_id: tracker_id)
  end

  def filter_journals_by_tracker(params, relation)
    tracker_id = params[:values].first
    case params[:operator].first
    when '='
      relation.joins(:issue).merge(issues.where(tracker_id: tracker_id))
    when '!'
      relation.joins(:issue).merge(issues.where.not(tracker_id: tracker_id))
    end
  end

  def filter_time_entries_by_tracker(params, relation)
    case params[:operator].first
    when '='
      relation.joins(:issue).merge(issues.where(tracker_id: params[:values].first))
    when '!'
      relation.joins(:issue).merge(issues.where.not(tracker_id: params[:values].first))
    end
  end

  def filter_issues_by_contact(params, relation)
    case params[:operator].first
    when '='
      relation.where(id: issues_related_to_contact_ids(params[:values]))
    when '!'
      relation.where.not(id: issues_related_to_contact_ids(params[:values]))
    end
  end

  def filter_journals_by_contact(params, relation)
    case params[:operator].first
    when '='
      relation.where(journalized: issues.where(id: issues_related_to_contact_ids(params[:values])))
    when '!'
      relation.where.not(journalized: issues.where(id: issues_related_to_contact_ids(params[:values])))
    end
  end

  def filter_time_entries_by_contact(params, relation)
    case params[:operator].first
    when '='
      relation.where(issue: issues.where(id: issues_related_to_contact_ids(params[:values])))
    when '!'
      relation.where.not(issue: issues.where(id: issues_related_to_contact_ids(params[:values])))
    end
  end

  def filter_issues_by_company(params, relation)
    case params[:operator].first
    when '='
      relation.where(id: issues_related_to_company_ids(params[:values]))
    when '!'
      relation.where.not(id: issues_related_to_company_ids(params[:values]))
    end
  end

  def filter_journals_by_company(params, relation)
    case params[:operator].first
    when '='
      relation.where(journalized: issues.where(id: issues_related_to_company_ids(params[:values])))
    when '!'
      relation.where.not(journalized: issues.where(id: issues_related_to_company_ids(params[:values])))
    end
  end

  def filter_time_entries_by_company(params, relation)
    case params[:operator].first
    when '='
      relation.where(issue: issues.where(id: issues_related_to_company_ids(params[:values])))
    when '!'
      relation.where.not(issue: issues.where(id: issues_related_to_company_ids(params[:values])))
    end
  end

  def filter_issues_by_tag(params, relation)
    case params[:operator].first
    when '='
      relation.joins(:tags).merge(RedmineCrm::ActsAsTaggable::Tag.where(name: params[:values]))
    when '!'
      relation.joins(issues_without_tag(params[:values])).where(RedmineCrm::ActsAsTaggable::Tagging.arel_table[:id].eq(nil))
    when '!*'
      relation.joins(issues_without_tag(params[:values]))
    when '*'
      relation.joins(:tags)
    end
  end

  def filter_journals_by_tag(params, relation)
    case params[:operator].first
    when '='
      relation.where(journalized_type: 'Issue').joins(issue: :tags).merge(RedmineCrm::ActsAsTaggable::Tag.where(name: params[:values]))
    when '!'
      relation.where(journalized_type: 'Issue').joins(:issue).joins(issues_without_tag(params[:values]))
              .where(RedmineCrm::ActsAsTaggable::Tagging.arel_table[:id].eq(nil))
    when '!*'
      relation.where(journalized_type: 'Issue').joins(:issue).joins(issues_without_tag(params[:values]))
    when '*'
      relation.where(journalized_type: 'Issue').joins(issue: :tags)
    end
  end

  def filter_time_entries_by_tag(params, relation)
    case params[:operator].first
    when '='
      relation.joins(issue: :tags).merge(RedmineCrm::ActsAsTaggable::Tag.where(name: params[:values]))
    when '!'
      relation.joins(:issue).joins(issues_without_tag(params[:values]))
              .where(RedmineCrm::ActsAsTaggable::Tagging.arel_table[:id].eq(nil))
    when '!*'
      relation.joins(:issue).joins(issues_without_tag(params[:values]))
    when '*'
      relation.joins(issue: :tags)
    end
  end

  def issues_related_to_contact_ids(contact_ids)
    (ContactsIssue.where(contact_id: contact_ids).pluck(:issue_id) +
     Issue.joins(:helpdesk_ticket).merge(HelpdeskTicket.where(contact_id: contact_ids)).pluck(:id)).compact.uniq
  end

  def issues_related_to_company_ids(company_name)
    company_contact_ids = Contact.where(company: company_name).pluck(:id)
    company_id = Contact.where(is_company: true, first_name: company_name).pluck(:id)
    contact_ids = company_contact_ids + company_id
    (ContactsIssue.where(contact_id: contact_ids).pluck(:issue_id) +
     Issue.joins(:helpdesk_ticket).merge(HelpdeskTicket.where(contact_id: contact_ids)).pluck(:id)).compact.uniq
  end

  def issues_without_tag(tag_values)
    tag_ids = RedmineCrm::ActsAsTaggable::Tag.where(name: tag_values).pluck(:id)
    Issue.arel_table.join(RedmineCrm::ActsAsTaggable::Tagging.arel_table, Arel::Nodes::OuterJoin)
         .on(RedmineCrm::ActsAsTaggable::Tagging.arel_table[:taggable_id].eq(Issue.arel_table[:id])
         .and(RedmineCrm::ActsAsTaggable::Tagging.arel_table[:taggable_type].eq('Issue')
         .and(RedmineCrm::ActsAsTaggable::Tagging.arel_table[:tag_id].eq(tag_ids))))
         .project(Arel.sql('*'))
         .join_sources
  end
end
