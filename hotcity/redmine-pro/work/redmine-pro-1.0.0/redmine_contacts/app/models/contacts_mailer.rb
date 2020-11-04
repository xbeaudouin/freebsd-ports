# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

class ContactsMailer < Mailer
  DEFAULT_DEAL_REMINDER_PERIOD = 7

  # Sends reminders to deal assignees
  # Available options:
  # * :days     => how many days in the future to remind about (defaults to 7)
  # * :project  => id or identifier of project to process (defaults to all projects)
  # * :users    => array of user/group ids who should be reminded
  # Based on Mailer.reminders
  def self.deals_reminders(options = {})
    days     = options[:days] || DEFAULT_DEAL_REMINDER_PERIOD
    project  = Project.find(options[:project]) if options[:project]
    user_ids = options[:users]

    scope = Deal.eager_load(:assigned_to, :project)
                .open
                .where('assigned_to_id IS NOT NULL')
                .where(projects: { status: Project::STATUS_ACTIVE })
                .where("#{Deal.table_name}.due_date <= ?", days.day.from_now.to_date)
    scope = scope.where(assigned_to_id: user_ids) if user_ids.present?
    scope = scope.where(project_id: project.id)   if project
    deals_by_assignee = scope.group_by(&:assigned_to)

    deals_by_assignee.keys.each do |assignee|
      next unless assignee.is_a?(Group)

      assignee.users.each do |user|
        deals_by_assignee[user] ||= []
        deals_by_assignee[user] += deals_by_assignee[assignee]
      end
    end

    deals_by_assignee.each do |assignee, deals|
      next unless assignee.is_a?(User) && assignee.active?

      visible_deals = deals.select { |deal| deal.visible?(assignee) }
      next if visible_deals.blank?

      visible_deals.sort! { |a, b| (a.due_date <=> b.due_date).nonzero? || (a.id <=> b.id) }
      deal_reminder(assignee, visible_deals, days).deliver
    end
  end

  def crm_note_add(_user, note)
    redmine_headers 'Project' => note.source.project.identifier,
                    'X-Notable-Id' => note.source.id,
                    'X-Note-Id' => note.id
    @author = note.author
    message_id note
    recipients = note.source.recipients
    cc = (note.source.respond_to?(:all_watcher_recepients) ? note.source.all_watcher_recepients : note.source.watcher_recipients) - recipients
    @note = note
    @note_url = url_for(:controller => 'notes', :action => 'show', :id => note.id)
    mail :to => recipients,
         :cc => cc,
         :subject => "[#{note.source.project.name}] - #{l(:label_crm_note_for)} #{note.source.name}"
  end

  def crm_contact_add(_user, contact)
    redmine_headers 'Project' => contact.project.identifier,
                    'X-Contact-Id' => contact.id
    @author = contact.author
    message_id contact
    recipients = contact.recipients
    cc = contact.watcher_recipients - recipients
    @contact = contact
    @contact_url = url_for(:controller => 'contacts', :action => 'show', :id => contact.id)
    mail :to => recipients,
         :cc => cc,
         :subject => "[#{contact.project.name} - #{l(:label_contact)} ##{contact.id}] #{contact.name}"
  end
  def crm_deal_add(_user, deal)
    redmine_headers 'Project' => deal.project.identifier,
                    'X-Deal-Id' => deal.id
    @author = deal.author
    message_id deal
    recipients = deal.recipients
    cc = deal.watcher_recipients - recipients
    @deal = deal
    @deal_url = url_for(:controller => 'deals', :action => 'show', :id => deal.id)
    mail :to => recipients,
         :cc => cc,
         :subject => "[#{deal.project.name} - #{l(:label_deal)} ##{deal.id}] #{deal.full_name}"
  end

  def crm_deal_updated(_user, deal_process)
    @deal = deal_process.deal
    redmine_headers 'Project' => @deal.project.identifier,
                    'X-Deal-Id' => @deal.id
    @author = deal_process.author
    recipients = deal_process.recipients
    cc = @deal.watcher_recipients - recipients
    @status_was = deal_process.from
    @status = deal_process.to
    @deal_url = url_for(:controller => 'deals', :action => 'show', :id => @deal.id)
    mail :to => recipients,
         :cc => cc,
         :subject => "[#{@deal.project.name} - #{l(:label_deal)} ##{@deal.id}] #{@deal.full_name}"
  end

  # Builds a reminder mail to user about deals that are due in the next days.
  # Based on Mailer#reminder
  def deal_reminder(user, deals, days)
    @deals       = deals
    @deals_count = deals.size
    @deal_urls   = deals.map { |deal| url_for(controller: 'deals', action: 'show', id: deal.id) }
    @days        = days
    @deals_url   = deals_reminder_url
    mail to:      user.mail,
         subject: l(:mail_subject_deal_reminder, count: @deals_count, days: days)
  end

  private

  def deals_reminder_url
    url_for(
      controller:     'deals',
      action:         'index',
      set_filter:     1,
      assigned_to_id: 'me',
      sort:           'due_date:asc'
    )
  end
end
