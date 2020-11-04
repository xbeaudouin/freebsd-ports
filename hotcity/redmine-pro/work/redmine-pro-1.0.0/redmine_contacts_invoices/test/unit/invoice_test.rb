# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class InvoiceTest < ActiveSupport::TestCase
  include RedmineInvoices::TestHelper
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects])

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts_invoices).directory + '/test/fixtures/', [:invoices,
                                                                                                                             :invoice_lines])

  RedmineInvoices::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_products).directory + '/test/fixtures/', [:products,
                                                                                                                    :order_statuses,
                                                                                                                    :orders,
                                                                                                                    :product_lines]) if InvoicesSettings.products_plugin_installed?

  def setup
    @admin_member = Member.create(user_id: 1, project_id: 1, roles: [Role.find(1)])
    @project_a = Project.create(:name => "Test_a", :identifier => "testa")
    @project_b = Project.create(:name => "Test_b", :identifier => "testb")

    @contact1 = Contact.create(:first_name => "Contact_1", :projects => [@project_a])
    @invoice1 = Invoice.create(:number => "INV/20121212-1", :contact => @contact1, :project => @project_a, :status_id => Invoice::DRAFT_INVOICE, :invoice_date => Time.now)

    @issue_1 = Issue.create(:project_id => 1, :tracker_id => 1, :author_id => 1,
                         :status_id => 1, :priority => IssuePriority.first,
                         :subject => 'Invoice Issue 1')
    @issue_2 = Issue.create(:project_id => 1, :tracker_id => 1, :author_id => 3,
                         :status_id => 1, :priority => IssuePriority.first,
                         :subject => 'Invoice Issue 2')

    @issue_3 = Issue.create(:project_id => 1, :tracker_id => 1, :author_id => 3,
                         :status_id => 1, :priority => IssuePriority.first,
                         :subject => 'Invoice Issue 3')

    @time_entrie_1 = @issue_1.time_entries.create(:spent_on => '2012-12-12',
                                :hours    => 10,
                                :user     => User.find(1),
                                :activity => TimeEntryActivity.first)
    @time_entrie_2 = @issue_1.time_entries.create(:spent_on => '2012-12-13',
                                :hours    => 5,
                                :user     => User.find(2),
                                :activity => TimeEntryActivity.first)
    @time_entrie_3 = @issue_2.time_entries.create(:spent_on => '2012-12-12',
                                :hours    => 12,
                                :user     => User.find(2),
                                :activity => TimeEntryActivity.first)

    @time_entrie_4 = @issue_3.time_entries.create(:spent_on => '2012-12-12',
                                :hours    => 5,
                                :user     => User.find(2),
                                :activity => TimeEntryActivity.first)
  end

  def test_should_calculate_amount
    @invoice1.lines.new(:description => "Line 1", :quantity => 1, :price => 10)
    @invoice1.lines.new(:description => "Line 2", :quantity => 2, :price => 20)
    @invoice1.calculate_amount
    # assert @invoice1.save!
    assert_equal 2, @invoice1.lines.size
    assert_equal 50, @invoice1.amount.to_i
  end

  def test_should_calculate_amount_before_save
    @invoice1.lines.new(:description => "Line 1", :quantity => 1, :price => 10)
    @invoice1.lines.new(:description => "Line 2", :quantity => 2, :price => 20)
    assert @invoice1.save
    assert_equal 2, @invoice1.lines.size
    assert_equal 50, @invoice1.amount.to_i
  end

  def test_should_calculate_amount_before_destroy_line
    @invoice1.lines.create(:description => "Line 1", :quantity => 1, :price => 10)
    @invoice1.lines.create(:description => "Line 2", :quantity => 2, :price => 20)
    assert @invoice1.save
    assert_equal 50, @invoice1.amount.to_i
    @invoice1.lines.last.destroy
    @invoice1.reload
    assert_equal 10, @invoice1.amount.to_i
  end

  def test_discount_after_tax
    with_invoice_settings 'invoices_discount_after_tax' => 1 do
      @invoice1.discount_type = 0 #percent
      @invoice1.discount = 10
      @invoice1.lines.new(:description => "Line 1", :quantity => 1, :price => 1000, :tax => 20)
      @invoice1.lines.new(:description => "Line 2", :quantity => 1, :price => 1000, :tax => 10)
      assert @invoice1.save
      assert_equal 2000.00, @invoice1.subtotal
      assert_equal 300.00, @invoice1.tax_amount
      assert_equal [100.00, 200.00], @invoice1.tax_groups.map{|t| t[1]}.sort
      assert_equal 230.00, @invoice1.discount_amount
      assert_equal 2070.00, @invoice1.amount
    end
  end

  def test_discount_after_tax_disbaled
    with_invoice_settings 'invoices_discount_after_tax' => 0 do
      @invoice1.discount_type = 0 #percent
      @invoice1.discount = 10
      @invoice1.lines.new(:description => "Line 1", :quantity => 1, :price => 1000, :tax => 20)
      @invoice1.lines.new(:description => "Line 2", :quantity => 1, :price => 1000, :tax => 10)
      assert @invoice1.save
      assert_equal 1800.00, @invoice1.subtotal
      assert_equal 270.00, @invoice1.tax_amount
      assert_equal [90.00, 180.00], @invoice1.tax_groups.map{|t| t[1]}.sort
      assert_equal 200.00, @invoice1.discount_amount
      assert_equal 2070.00, @invoice1.amount
    end
  end

  def test_copy_from_object
    if InvoicesSettings.products_plugin_installed?
      order = Order.find(1)
      invoice = Invoice.new
      invoice.copy_from_object(:object_type => 'order', :object_id => 1)
      assert_equal order.contact, invoice.contact
      assert_equal order.order_number, invoice.order_number
      assert_equal order.lines.size, invoice.lines.size
      assert_equal order.subject, invoice.subject
      assert_equal order.description, invoice.description

      invoice = Invoice.new
      invoice.copy_from_object(:object => order)
      assert_equal order.contact, invoice.contact
      assert_equal order.order_number, invoice.order_number
      assert_equal order.lines.size, invoice.lines.size
    end
  end
  def test_should_generate_lines_from_issues
    issue_ids = [@issue_1.id, @issue_2.id, @issue_3.id]

    # Grouping by issues
    invoice = Invoice.new
    invoice.lines_from_issues([@issue_1.id, @issue_2.id], 1)

    assert_equal 2, invoice.lines.size
    assert_equal 27, invoice.lines.map(&:quantity).sum.to_i

    # Grouping by users
    invoice = Invoice.new
    invoice.lines_from_issues(issue_ids, 2)
    assert_equal 2, invoice.lines.size
    assert_equal [
     # First line
     "#{User.find(1).name.humanize}", # \n
     " - ##{@issue_1.id} Invoice Issue 1 (10.00 hours)",
     # Second line
     "#{User.find(2).name.humanize}",
     " - ##{@issue_3.id} Invoice Issue 3 (5.00 hours)",
     " - ##{@issue_2.id} Invoice Issue 2 (12.00 hours)",
     " - ##{@issue_1.id} Invoice Issue 1 (5.00 hours)"].sort , invoice.lines.map{ |line| line.description.split("\n") }.flatten.sort

    # In one line
    invoice = Invoice.new
    invoice.lines_from_issues(issue_ids, 3)
    assert_equal 1, invoice.lines.size
    assert_equal 32.0, invoice.lines[0].quantity.to_f

    # By time entries
    invoice = Invoice.new
    invoice.lines_from_issues(issue_ids, 5)
    assert_equal 4, invoice.lines.size
    assert_equal [5.0, 5.0, 10.0, 12.0], invoice.lines.map{|t| t.quantity.to_f }.sort

    # By activity
    invoice = Invoice.new
    invoice.lines_from_issues(issue_ids)
    assert_equal 1, invoice.lines.size
    assert_equal 32.0, invoice.lines[0].quantity.to_f
  end

  def test_should_generate_lines_from_time_entries
    time_entrie_ids = [@time_entrie_1.id, @time_entrie_2.id, @time_entrie_3.id]

    # Grouping by issues
    invoice = Invoice.new
    invoice.lines_from_time_entries([@time_entrie_1.id, @time_entrie_3.id], 1)

    assert_equal 2, invoice.lines.size
    assert_equal 22, invoice.lines.map(&:quantity).sum.to_i

    invoice = Invoice.new
    invoice.lines_from_time_entries([@time_entrie_1.id, @time_entrie_2.id], 1)

    assert_equal 1, invoice.lines.size
    assert_equal 15, invoice.lines.map(&:quantity).sum.to_i

    # Grouping by users
    invoice = Invoice.new
    invoice.lines_from_time_entries(time_entrie_ids, 2)
    assert_equal 2, invoice.lines.size
    assert_equal [
     # First line
     "#{User.find(1).name.humanize}",
     " - ##{@issue_1.id} Invoice Issue 1 (10.00 hours)",
     # Second line
     "#{User.find(2).name.humanize}",
     " - ##{@issue_2.id} Invoice Issue 2 (12.00 hours)",
     " - ##{@issue_1.id} Invoice Issue 1 (5.00 hours)" ].sort, invoice.lines.map{ |line| line.description.split("\n") }.flatten.sort

    # In one line
    invoice = Invoice.new
    invoice.lines_from_time_entries(time_entrie_ids, 3)
    assert_equal 1, invoice.lines.size
    assert_equal 27.0, invoice.lines[0].quantity.to_f

    # By time entries
    invoice = Invoice.new
    invoice.lines_from_time_entries(time_entrie_ids, 5)
    assert_equal [5.0, 10.0, 12.0], invoice.lines.map{|t| t.quantity.to_f }.sort

    # By activity
    invoice = Invoice.new
    invoice.lines_from_time_entries(time_entrie_ids)
    assert_equal 1, invoice.lines.size
    assert_equal 27.0, invoice.lines[0].quantity.to_f
  end

  def test_should_check_recurring_references
    recurring_invoice = Invoice.find(4)
    recurring_instance = Invoice.find(5)

    assert_equal recurring_invoice.recurring_instance?, false
    assert_nil recurring_invoice.profile_recurring_period
    assert_equal recurring_invoice.recurring_instances, Invoice.where(:id => [5,6])
    assert_nil recurring_invoice.recurring_profile

    assert_equal recurring_instance.recurring_instance?, true
    assert_equal recurring_instance.profile_recurring_period, '1week'
    assert_equal recurring_instance.recurring_instances, []
    assert_equal recurring_instance.recurring_profile, recurring_invoice
  end

  def test_generate_invoice_number
    with_invoice_settings 'invoices_invoice_number_format' => '%%YEARLY_ID%%, %%MONTHLY_ID%%, %%DAILY_ID%%, %%ID%%, %%YEAR%%, %%MONTH%%, %%DAY%%' do
      invoice_number = Invoice.generate_invoice_number
      next_id = '%02d' % (Invoice.last.id + 1).to_s
      year_id = '%04d' % (Invoice.where(:invoice_date => Time.now.beginning_of_year.utc.change(:hour => 0, :min => 0)..Time.now.end_of_year.utc.change(:hour => 0, :min => 0)).count + 1).to_s
      daily   = '%02d' % (Invoice.where(:invoice_date => Time.now.to_time.utc.change(:hour => 0, :min => 0)).count + 1).to_s
      today   = Date.today
      year    = today.year.to_s
      month   = '%02d' % today.month.to_s
      day     = '%02d' % today.day.to_s
      m_count = '%03d' % (Invoice.where(:invoice_date => Time.now.beginning_of_month.utc.change(:hour => 0, :min => 0)..Time.now.end_of_month.utc.change(:hour => 0, :min => 0)).count + 1).to_s
      assert_equal "#{year_id}, #{m_count}, #{daily}, #{next_id}, #{year}, #{month}, #{day}", invoice_number
    end
  end

  def test_allowed_projects_returns_projects_with_add_invoices
    project = Project.find(1)
    project.enable_module!(:contacts_invoices)

    user = User.find(2)
    user.roles_for_project(project).first.add_permission!(:add_invoices)

    allowed_projects = Invoice.allowed_target_projects(user)

    assert_include project, allowed_projects
    assert_equal 1, allowed_projects.count
  end

  def test_allowed_projects_returns_projects_with_edit_invoices
    project = Project.find(1)
    project.enable_module!(:contacts_invoices)

    user = User.find(2)
    user.roles_for_project(project).first.add_permission!(:edit_invoices)

    allowed_projects = Invoice.allowed_target_projects(user)

    assert_include project, allowed_projects
    assert_equal 1, allowed_projects.count
  end
end
