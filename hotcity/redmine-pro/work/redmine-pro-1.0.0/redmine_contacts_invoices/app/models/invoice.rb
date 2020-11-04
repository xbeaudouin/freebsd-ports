# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# https://www.redmineup.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

class Invoice < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes

  ESTIMATE_INVOICE = 0
  DRAFT_INVOICE = 1
  SENT_INVOICE = 2
  PAID_INVOICE = 3
  CANCELED_INVOICE = 4

  belongs_to :contact
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :template, :class_name => 'InvoiceTemplate'
  belongs_to :recurring_profile, :class_name => 'Invoice', :foreign_key => 'recurring_profile_id'
  has_many :recurring_instances, :class_name => 'Invoice', :foreign_key => 'recurring_profile_id'
  has_many :lines, :class_name => 'InvoiceLine', :foreign_key => 'invoice_id', :order => 'position', :dependent => :delete_all
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => 'created_on'
  has_many :payments, :class_name => 'InvoicePayment', :dependent => :delete_all, :order => 'payment_date'

  scope :by_project, lambda { |project_id| where(["#{Invoice.table_name}.project_id = ?", project_id]) if project_id.present? }
  scope :visible, lambda { |*args| eager_load(:project).where(Project.allowed_to_condition(args.first || User.current, :view_invoices)) }
  scope :live_search, lambda { |search| where("(LOWER(#{Invoice.table_name}.number) LIKE :search_text OR
                                                LOWER(#{Invoice.table_name}.subject) LIKE :search_text OR
                                                LOWER(#{Invoice.table_name}.description) LIKE :search_text)",
                                                search_text: "%#{search.downcase}%") }

  scope :paid, lambda { where(:status_id => PAID_INVOICE) }
  scope :sent_or_paid, lambda { where(["#{Invoice.table_name}.status_id = ? OR #{Invoice.table_name}.status_id = ?", PAID_INVOICE, SENT_INVOICE]) }
  scope :open, lambda { where(["#{Invoice.table_name}.status_id <> ? AND #{Invoice.table_name}.status_id <> ?", PAID_INVOICE, CANCELED_INVOICE]) }
  scope :recurring, lambda { where(:is_recurring => true) }

  if ActiveRecord::VERSION::MAJOR >= 4
    acts_as_activity_provider :type => 'invoices',
                              :permission => :view_invoices,
                              :timestamp => "#{table_name}.created_at",
                              :author_key => :author_id,
                              :scope => joins(:project)

    acts_as_searchable :columns => ["#{table_name}.number"],
                       :scope => joins(:project),
                       :project_key => "#{Project.table_name}.id",
                       :permission => :view_invoices,
                       # sort by id so that limited eager loading doesn't break with postgresql
                       :date_column => 'number'
  else
    acts_as_activity_provider :type => 'invoices',
                              :permission => :view_invoices,
                              :timestamp => "#{table_name}.created_at",
                              :author_key => :author_id,
                              :find_options => { :include => :project }

    acts_as_searchable :columns => ["#{table_name}.number"],
                       :date_column => "#{table_name}.created_at",
                       :include => [:project],
                       :project_key => "#{Project.table_name}.id",
                       :permission => :view_invoices,
                       # sort by id so that limited eager loading doesn't break with postgresql
                       :order_column => "#{table_name}.number"
  end

  acts_as_event :datetime => :created_at,
                :url => Proc.new { |o| { :controller => 'invoices', :action => 'show', :id => o } },
                :type => 'icon icon-invoice',
                :title => Proc.new { |o| "#{l(:label_invoice_created)} ##{o.number} (#{o.status}): #{o.currency + ' ' if o.currency}#{o.amount}" },
                :description => Proc.new { |o| [o.number, o.contact ? o.contact.name : '', o.currency.to_s + ' ' + o.amount.to_s, o.description].join(' ') }
  acts_as_customizable

  acts_as_watchable
  acts_as_attachable
  acts_as_priceable :amount, :tax_amount, :discount_amount, :balance, :remaining_balance

  before_save :calculate_amount
  before_save :default_values

  validates_presence_of :number, :invoice_date, :project, :status_id
  validates_uniqueness_of :number
  validates_numericality_of :discount, :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 100.0, :allow_nil => true
  validate :validate_invoice

  accepts_nested_attributes_for :lines, :allow_destroy => true

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'number',
                  'subject',
                  'invoice_date',
                  'due_date',
                  'currency',
                  'language',
                  'discount',
                  'order_number',
                  'contact_id',
                  'status_id',
                  'assigned_to_id',
                  'project_id',
                  'description',
                  'is_recurring',
                  'recurring_period',
                  'recurring_occurrences',
                  'recurring_action',
                  'template_id',
                  'custom_field_values',
                  'custom_fields',
                  'lines_attributes',
                  :if => lambda { |order, user| order.new_record? || user.allowed_to?(:edit_invoices, order.project) }
  def self.recurring_periods
    [
      [I18n.t(:recurring_period_weekly), '1week'],
      [I18n.t(:recurring_period_2weeks), '2week'],
      [I18n.t(:recurring_period_monthly), '1month'],
      [I18n.t(:recurring_period_2months), '2month'],
      [I18n.t(:recurring_period_3months), '3month'],
      [I18n.t(:recurring_period_6months), '6month'],
      [I18n.t(:recurring_period_yearly), '1year']
    ]
  end

  def self.recurring_period_name
    Hash[recurring_periods.map(&:reverse)]
  end

  def self.recurring_interval_in_seconds
    { '1week' => 1.week.seconds,
      '2week' => 2.week.seconds,
      '1month' => 1.month.seconds,
      '2month' => 2.month.seconds,
      '3month' => 3.month.seconds,
      '6month' => 6.month.seconds,
      '1year' => 1.year.seconds }
  end

  def self.recurring_actions
    [
      [I18n.t(:recurring_action_create_draft), 0],
      [I18n.t(:recurring_action_send_to_client), 1]
    ]
  end

  def calculate_status
    calculate_balance
    if balance >= amount
      self.status_id = Invoice::PAID_INVOICE
      self.paid_date = payments.maximum(:payment_date)
    else
      self.status_id = Invoice::SENT_INVOICE
      self.paid_date = nil
    end
  end

  def calculate_balance
    payments_sum = payments.to_a.sum(&:amount)
    self.balance = payments_sum > amount ? amount : payments_sum
  end

  def calculate_amount
    self.amount = subtotal.round(2) + (ContactsSetting.tax_exclusive? ? tax_amount.round(2) : 0)
    self.amount -= discount_amount.round(2) if InvoicesSettings.discount_after_tax?
    self.amount.to_f
  end
  alias_method :calculate, :calculate_amount

  def tax_amount
    lines.inject(0){ |sum, x| sum + x.tax_amount * discount_rate }.to_f
  end

  def order
    if InvoicesSettings.products_plugin_installed? && !order_number.blank?
      Order.where(:number => order_number).first
    end
  end

  def subtotal
    if InvoicesSettings.discount_after_tax?
      lines.inject(0) { |sum, x| sum + x.total }.to_f
    else
      lines.inject(0) do |sum, x|
        sum + (x.total - (x.total * (discount / 100)).to_f)
      end.to_f
    end
  end

  def discount_amount
    if InvoicesSettings.discount_after_tax?
      lines.inject(0) { |sum, x| sum + x.total + x.tax_amount }.to_f * (discount / 100)
    else
      lines.inject(0) do |sum, x|
        sum + (x.total * (discount / 100)).to_f
      end.to_f
    end
  end

  def discount_rate
    InvoicesSettings.discount_after_tax? ? 1 : (1 - discount / 100)
  end

  def discount
    read_attribute(:discount).to_f
  end

  def tax_groups
    lines.select { |l| !l.tax.blank? && l.tax.to_f > 0 }
         .group_by { |l| l.tax }.map { |k, v| [k, v.sum { |l| l.tax_amount.to_f * discount_rate }] }
  end

  def visible?(usr = nil)
    (usr || User.current).allowed_to?(:view_invoices, project)
  end

  def editable_by?(usr, prj = nil)
    prj ||= @project || project
    usr && (usr.allowed_to?(:edit_invoices, prj) || (author == usr && usr.allowed_to?(:edit_own_invoices, prj)))
  end

  def destroyable_by?(usr, prj = nil)
    prj ||= @project || project
    usr && (usr.allowed_to?(:delete_invoices, prj) || (author == usr && usr.allowed_to?(:edit_own_invoices, prj)))
  end

  def commentable?(user=User.current)
    user.allowed_to?(:comment_invoices, project)
  end

  def total_with_tax?
    @total_with_tax ||= !InvoicesSettings.disable_taxes?(project) && InvoicesSettings.total_including_tax?
  end

  def copy_from(arg)
    invoice = arg.is_a?(Invoice) ? arg : Invoice.visible.find(arg)
    self.attributes = invoice.attributes.dup.except('id','number', 'created_at', 'updated_at')
    self.lines = invoice.lines.collect { |l| InvoiceLine.new(l.attributes.dup.except('id', 'created_at', 'updated_at')) }
    self.custom_field_values = invoice.custom_field_values.inject({}) { |h, v| h[v.custom_field_id] = v.value; h }
    self
  end

  def self.allowed_target_projects(user = User.current)
    conditions = []
    [:add_invoices,
     :edit_invoices,
     :edit_own_invoices].each do |perm|
      conditions << Project.allowed_to_condition(user, perm)
    end
    Project.where(conditions.join(' OR '))
  end

  STATUSES = {
    DRAFT_INVOICE => :label_invoice_status_draft,
    ESTIMATE_INVOICE => :label_invoice_status_estimate,
    SENT_INVOICE => :label_invoice_status_sent,
    PAID_INVOICE => :label_invoice_status_paid,
    CANCELED_INVOICE => :label_invoice_status_canceled
  }

  STATUSES_STRINGS = {
    DRAFT_INVOICE    => l(:label_invoice_status_draft),
    ESTIMATE_INVOICE => l(:label_invoice_status_estimate),
    SENT_INVOICE     => l(:label_invoice_status_sent),
    PAID_INVOICE     => l(:label_invoice_status_paid),
    CANCELED_INVOICE => l(:label_invoice_status_canceled)
  }

  def status
    l(STATUSES[status_id])
  end

  def set_status(stat)
    STATUSES.respond_to?(:key) ? STATUSES.key(stat) : STATUSES.index(stat)
  end

  def is_draft
    status_id == DRAFT_INVOICE || status_id.blank?
  end

  def is_sent?
    status_id == SENT_INVOICE
  end

  def is_paid?
    status_id == PAID_INVOICE
  end

  def is_canceled?
    status_id == CANCELED_INVOICE
  end

  def is_estimate?
    status_id == ESTIMATE_INVOICE
  end

  def is_open?
    ![PAID_INVOICE, CANCELED_INVOICE].include?(status_id)
  end

  def editable?(usr = nil)
    @editable ||= editable_by?(usr)
  end

  def remaining_balance
    self.amount - balance
  end

  def has_taxes?
    !lines.map(&:tax).all? { |t| t == 0 || t.blank? }
  end

  def has_units?
    !lines.map(&:units).all? { |t| t == 0 || t.blank? }
  end

  def self.generate_invoice_number(project = nil)
    result = ''
    format = InvoicesSettings[:invoices_invoice_number_format, project].to_s
    if format
      result = apply_invoice_macros(format)
    end
    result
  end

  def self.apply_invoice_macros(input, project=nil)
    result = input.to_s.gsub(/%%ID%%|{{id}}/, '%02d' % (Invoice.last.try(:id).to_i + 1).to_s)
    result = result.gsub(/%%YEAR%%|{{year}}/, Date.today.year.to_s)
    result = result.gsub(/%%MONTH%%|{{month}}/, '%02d' % Date.today.month.to_s)
    result = result.gsub(/{{month_name}}/, l('date.month_names')[Date.today.month])
    result = result.gsub(/{{month_short_name}}/,  l('date.abbr_month_names')[Date.today.month])
    result = result.gsub(/%%DAY%%|{{day}}/, '%02d' % Date.today.day.to_s)
    result = result.gsub(/%%DAILY_ID%%|{{daily_id}}/, '%02d' % (Invoice.where(:invoice_date => Time.now.to_time.utc.change(:hour => 0, :min => 0)).count + 1).to_s)
    result = result.gsub(/%%MONTHLY_ID%%|{{monthly_id}}/, '%03d' % (Invoice.where(:invoice_date => Time.now.beginning_of_month.utc.change(:hour => 0, :min => 0)..Time.now.end_of_month.utc.change(:hour => 0, :min => 0)).count + 1).to_s)
    result = result.gsub(/%%YEARLY_ID%%|{{yearly_id}}/, '%04d' % (Invoice.where(:invoice_date => Time.now.beginning_of_year.utc.change(:hour => 0, :min => 0)..Time.now.end_of_year.utc.change(:hour => 0, :min => 0)).count + 1).to_s)
    result = result.gsub(/%%MONTHLY_PROJECT_ID%%|{{monthly_project_id}}/, '%03d' % (Invoice.where(:project_id => project, :invoice_date => Time.now.beginning_of_month.utc.change(:hour => 0, :min => 0)..Time.now.end_of_month.utc.change(:hour => 0, :min => 0)).count + 1).to_s)
    result = result.gsub(/%%YEARLY_PROJECT_ID%%|{{yearly_project_id}}/, '%04d' % (Invoice.where(:project_id => project, :invoice_date => Time.now.beginning_of_year.utc.change(:hour => 0, :min => 0)..Time.now.end_of_year.utc.change(:hour => 0, :min => 0)).count + 1).to_s)
    return result
  end

  def filename
    "invoice-#{number}.pdf"
  end

  def self.sum_by_period(peroid, project, contact_id = nil)
    from, to = RedmineContacts::DateUtils.retrieve_date_range(peroid)
    scope = Invoice.where({})
    scope = scope.visible
    scope = scope.by_project(project.id) if project
    scope = scope.where("#{Invoice.table_name}.invoice_date >= ? AND #{Invoice.table_name}.invoice_date < ?", from, to)
    scope = scope.where("#{Invoice.table_name}.contact_id = ?", contact_id) if contact_id.present?
    scope = scope.sent_or_paid
    scope.group(:currency).sum(:amount)
  end

  def self.sum_by_status(status_id, project, contact_id=nil)
    scope = Invoice.where({})
    scope = scope.visible
    scope = scope.by_project(project.id) if project
    scope = scope.where("#{Invoice.table_name}.status_id = ?", status_id)
    scope = scope.where("#{Invoice.table_name}.contact_id = ?", contact_id) if contact_id.present?
    [scope.group(:currency).sum(:amount), scope.count(:number)]
  end

  def copy_from_object(copy_from_object, _options = {})
    return false if copy_from_object[:object].blank? && (copy_from_object[:object_type].blank? || copy_from_object[:object_id].blank?)
    klass = Object.const_get(copy_from_object[:object_type].camelcase) rescue nil if copy_from_object[:object_type].present?
    from_object = copy_from_object[:object] || klass.find(copy_from_object[:object_id])
    self.contact = from_object.contact if from_object.respond_to?(:contact)
    self.currency = from_object.currency if from_object.respond_to?(:currency)
    self.order_number = from_object.order_number if from_object.respond_to?(:order_number)
    self.subject = from_object.subject if from_object.respond_to?(:subject)
    self.description = from_object.description if from_object.respond_to?(:description)
    if from_object.respond_to?(:lines)
      from_object.lines.each do |line|
        new_line = lines.new
        new_line.position = line.position if line.respond_to?(:position) && line.position
        new_line.description = line.description if line.respond_to?(:description) && line.description.present?
        new_line.tax = line.tax if line.respond_to?(:tax) && line.tax
        new_line.quantity = line.quantity if line.respond_to?(:quantity) && line.quantity
        new_line.discount = line.discount if line.respond_to?(:discount) && line.discount
        new_line.price = line.price.to_f * (1 - new_line.discount.to_f / 100) if line.respond_to?(:price)
        new_line.product_id = line.product_id if line.respond_to?(:product_id) && line.product_id
      end
    end
  end
  def custom_template
    @custom_template ||= (InvoicesSettings.per_invoice_templates? && template) ||
                         InvoiceTemplate.where(:id => InvoicesSettings.template(project).to_i).first
  end

  def token
    Digest::MD5.hexdigest("#{number}:#{invoice_date.strftime('%d.%m.%Y %H:%M:%S')}:#{Rails.application.config.secret_token}")
  end

  def token_by(invoice_template_ids)
    str = "Invoice##{id}"
    str += invoice_template_ids.inject('') { |str, id| str + "InvoiceTemplate##{id}" }
    Digest::MD5.hexdigest("#{str}:#{Rails.application.config.secret_token}")
  end

  def public_link_params(invoice_templates)
    invoice_template_ids = invoice_templates.map(&:id)

    { invoice_id: id,
      invoice_template: { ids: invoice_template_ids },
      token: token_by(invoice_template_ids) }
  end

  def build_estimated_time_by_issues(issues_ids)
    total_time = Issue.where(:id => issues_ids).order(:subject).group(:id).sum(:estimated_hours)
    total_time.each do |k, v|
      issue = Issue.find(k.to_i)
      lines << InvoiceLine.new(:description => issue.to_s,
                               :units => l(:label_invoice_hours),
                               :quantity => "%.2f" % v.to_f)
    end
  end

  def build_estimated_time_by_project(issues_ids)
    total_time = TimeEntry.where(:issue_id => issues_ids).joins(:issue).group('issues.project_id').sum(:hours)
    total_time.each do |project_id, project_sum|
      issues = Issue.eager_load(:time_entries, :project).where(:id => issues_ids, :project_id => project_id).all
      lines << InvoiceLine.new(:description => Project.find(project_id).name + "\n" +
                               issues.map { |i| " - ##{i.id} #{i.subject} (#{l_hours(i.time_entries.sum(:hours))})" }.join("\n"),
                               :units => l(:label_invoice_hours),
                               :quantity => "%.2f" % project_sum.to_f)
    end
  end

  def build_estimated_time_by_tracker(issues_ids)
    total_time = TimeEntry.where(:issue_id => issues_ids).joins(:issue).group('issues.tracker_id').sum(:hours)
    total_time.each do |tracker_id, tracker_sum|
      issues = Issue.where(:id => issues_ids, :tracker_id => tracker_id).all
      lines << InvoiceLine.new(:description => Tracker.find(tracker_id).name + "\n" +
                               issues.map { |i| " - ##{i.id} #{i.subject} (#{l_hours(i.time_entries.sum(:hours))})" }.join("\n"),
                               :units => l(:label_invoice_hours),
                               :quantity => "%.2f" % tracker_sum.to_f)
    end
  end

  def lines_from_issues(issues_ids, grouping = nil, options = {})
    invoice_project = project || @project || options[:project]
    self.lines ||= []
    case grouping.to_i
    when 1 # By issues
      total_time = TimeEntry.where(:issue_id => issues_ids).group(:issue_id).sum(:hours)
      total_time.first
      total_time.each do |k, v|
        issue = Issue.find(k.to_i)
        self.lines << InvoiceLine.new(:description => issue.to_s,
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % v.to_f)
      end
    when 2 # By users
      total_time = TimeEntry.where(:issue_id => issues_ids).group(:user_id).sum(:hours)
      total_time.first
      total_time.each do |k, v|
        scope = Issue.eager_load(:time_entries).where("#{Issue.table_name}.id" => issues_ids)
        scope = scope.where("#{TimeEntry.table_name}.user_id = ?", k)
        issues = scope.all
        user = User.find(k)
        self.lines << InvoiceLine.new(:description => user.name.humanize + "\n" +
                                      issues.map { |i| " - ##{i.id} #{i.subject} (#{l_hours(i.time_entries.where(:user_id => k).sum(:hours))})" }.join("\n"),
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % v.to_f,
                                      :price => RedmineInvoices.default_user_rate(user, invoice_project))
      end
    when 3 # In one line
      total_time = TimeEntry.where(:issue_id => issues_ids).sum(:hours)
      scope = Issue.eager_load(:time_entries).where("#{Issue.table_name}.id" => issues_ids)
      scope = scope.where("#{TimeEntry.table_name}.hours > 0")
      issues = scope.all
      self.lines << InvoiceLine.new(:description => issues.map { |i| " - #{i.subject} (#{l_hours(i.spent_hours)})" }.join("\n"),
                                    :units => l(:label_invoice_hours),
                                    :quantity => "%.2f" % total_time.to_f)
    when 5 # by time entries
      scope = TimeEntry.eager_load([ { :issue => :tracker }, :activity, :user]).where("#{TimeEntry.table_name}.issue_id" => issues_ids)
      time_entries = scope.all
      time_entries.each do |time_entry|
        issue = time_entry.issue
        line_description = "#{time_entry.activity.name} - #{issue.tracker.name} ##{issue.id}: #{issue.subject} #{'- ' + time_entry.comments + ' ' unless time_entry.comments.blank?}"
        self.lines << InvoiceLine.new(:description => line_description,
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % time_entry.hours.to_f,
                                      :price => RedmineInvoices.default_user_rate(time_entry.user, invoice_project))
      end
    when 6 # by estimated time
      build_estimated_time_by_issues(issues_ids)
    when 7 # by estimated time
      build_estimated_time_by_project(issues_ids)
    when 8 # by estimated time
      build_estimated_time_by_tracker(issues_ids)
    else # by activity
      total_time = TimeEntry.where(:issue_id => issues_ids).group(:activity_id).sum(:hours)
      total_time.first
      total_time.each do |k, v|
        scope = Issue.eager_load(:time_entries).where("#{Issue.table_name}.id" => issues_ids)
        scope = scope.where("#{TimeEntry.table_name}.activity_id = ?", k)
        issues = scope.all
        self.lines << InvoiceLine.new(:description => Enumeration.find(k).name.humanize + "\n" +
                                      issues.map{|i| " - ##{i.id} #{i.subject} (#{l_hours(i.time_entries.where(:activity_id => k).sum(:hours))})" }.join("\n"),
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % v.to_f)
      end
    end
  end

  def lines_from_time_entries(time_entries_ids, grouping = nil, options = {})
    invoice_project = project || @project || options[:project]
    self.lines ||= []
    case grouping.to_i
    when 1 # By issues
      total_time = TimeEntry.where('time_entries.issue_id IS NOT NULL').where(:id => time_entries_ids).group(:issue_id).sum(:hours)
      total_time.first
      total_time.each do |k, _v|
        issue = Issue.find(k.to_i)
        self.lines << InvoiceLine.new(:description => issue.to_s,
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % total_time[k].to_f)
      end
      time_entries_without_issues = TimeEntry.where(:id => time_entries_ids).where(:issue_id => nil)
      time_entries_without_issues.each do |time_entry|
        self.lines << InvoiceLine.new(:description => time_entry.comments,
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % time_entry.hours)
      end
    when 2 # by users
      total_time = TimeEntry.where(:id => time_entries_ids).group(:user_id).sum(:hours)
      total_time.first
      total_time.each do |k, _v|
        scope = Issue.eager_load(:time_entries).where("#{TimeEntry.table_name}.id" => time_entries_ids)
        scope = scope.where("#{TimeEntry.table_name}.user_id = ?", k)
        issues = scope.all
        user = User.find(k)
        time_entries_without_issues = TimeEntry.where(:id => time_entries_ids).where(:issue_id => nil).where(:user_id => k)
        description = issues.map { |i| " - ##{i.id} #{i.subject} (#{l_hours(i.time_entries.where(:id => time_entries_ids).where(:user_id => k).sum(:hours))})" }.join("\n")
        description << (description.blank? ? '' : "\n") + time_entries_without_issues.map { |t| " - #{t.comments} (#{l_hours(t.hours)})"}.join("\n") unless time_entries_without_issues.blank?

        self.lines << InvoiceLine.new(:description => user.name.humanize +
                                        "\n" +
                                        description,
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % total_time[k].to_f,
                                      :price => RedmineInvoices.default_user_rate(user, invoice_project))
      end
    when 3 # in one line
      total_time = TimeEntry.where(:id => time_entries_ids).sum(:hours)
      scope = Issue.eager_load(:time_entries).where("#{TimeEntry.table_name}.id" => time_entries_ids)
      scope = scope.where("#{TimeEntry.table_name}.hours > 0")
      issues = scope.all
      time_entries_without_issues = TimeEntry.where(:id => time_entries_ids).where(:issue_id => nil)
      description = issues.map { |i| " - ##{i.id} #{i.subject} (#{l_hours(i.time_entries.where(:id => time_entries_ids).sum(:hours))})" }.join("\n")
      description << (description.blank? ? '' : "\n") + time_entries_without_issues.map { |t| " - #{t.comments} (#{l_hours(t.hours)})" }.join("\n") unless time_entries_without_issues.blank?
      self.lines << InvoiceLine.new(:description => description,
                                    :units => l(:label_invoice_hours),
                                    :quantity => total_time)
    when 5 # by time entries
      scope = TimeEntry.eager_load([ { :issue => :tracker }, :activity, :user]).where("#{TimeEntry.table_name}.id" => time_entries_ids)
      time_entries = scope.all
      time_entries.each do |time_entry|
        issue = time_entry.issue
        line_description = "#{time_entry.activity.name}#{' - ' + issue.to_s if issue} #{'- ' + time_entry.comments + ' ' unless time_entry.comments.blank?}"
        self.lines << InvoiceLine.new(:description => line_description,
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % time_entry.hours.to_f,
                                      :price => RedmineInvoices.default_user_rate(time_entry.user, invoice_project))
      end
    else # by activity
      total_time = TimeEntry.where(:id => time_entries_ids).group(:activity_id).sum(:hours)
      total_time.first
      total_time.each do |k, _v|
        scope = Issue.eager_load(:time_entries).where("#{TimeEntry.table_name}.id" => time_entries_ids)
        scope = scope.where("#{TimeEntry.table_name}.activity_id = ?", k)
        issues = scope.all

        time_entries_without_issues = TimeEntry.where(:id => time_entries_ids).where(:issue_id => nil).where(:activity_id => k)
        description = issues.map{|i| " - ##{i.id} #{i.subject} (#{l_hours(i.time_entries.where(:id => time_entries_ids).where(:activity_id => k).sum(:hours))})"}.join("\n")
        description << (description.blank? ? "" : "\n") + time_entries_without_issues.map{|t| " - #{t.comments} (#{l_hours(t.hours)})"}.join("\n") unless time_entries_without_issues.blank?

        self.lines << InvoiceLine.new(:description => Enumeration.find(k).name.humanize + "\n" +
                                      description,
                                      :units => l(:label_invoice_hours),
                                      :quantity => "%.2f" % total_time[k].to_f)
      end
    end
  end

  def overdue?
    is_sent? && due_date && (due_date <= Date.current)
  end

  def contact_country
    try(:contact).try(:address).try(:country)
  end

  def contact_city
    try(:contact).try(:address).try(:city)
  end
  def recurring_instance?
    recurring_profile.present?
  end

  def profile_recurring_period
    return nil unless recurring_instance?
    recurring_profile.recurring_period
  end

  def notified_users
    [author, assigned_to].reject(&:nil?)
  end

  def recurring_instances_sum
    return recurring_instances.sum(:amount) if is_recurring
    return recurring_profile.recurring_instances.sum(:amount) if recurring_instance?
    0
  end

  def recurring_instances_due_sum
    return recurring_instances.map(&:remaining_balance).sum if is_recurring
    return recurring_profile.recurring_instances.map(&:remaining_balance).sum if recurring_instance?
    0
  end

  def compatible_accounts
    return [] unless InvoicesSettings.finance_plugin_installed?
    @compatible_accounts ||= project.accounts.where(currency: currency)
  end

  private

  def default_values
    self.discount = 0 unless read_attribute(:discount)
  end

  def validate_invoice
    if (status_id != PAID_INVOICE && remaining_balance == 0 && balance > 0) || (status_id == PAID_INVOICE && remaining_balance > 0 && amount > 0)
      errors.add :status_id, :text_invoice_cant_change_status
    end
  end
end
