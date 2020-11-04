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

module InvoicesHelper
  include RedmineInvoices::InvoiceReports
  include Redmine::I18n

  def invoice_status_tag(invoice)
    status_tag = content_tag(:span, invoice_status_name(invoice.status_id))
    content_tag(:span, status_tag, :class => "tag-label-color invoice-status #{invoice_status_name(invoice.status_id, true).to_s}")
  end

  def invoice_status_url(status_id, options={})
    {:controller => 'invoices',
     :action => 'index',
     :set_filter => 1,
     :project_id => @project,
     :fields => [:status_id],
     :values => {:status_id => [status_id]},
     :operators => {:status_id => '='}}.merge(options)
  end

  def invoice_tag(invoice)
    invoice_title = "##{invoice.number} - #{format_date(invoice.invoice_date)}"
    s = ''
    if invoice.visible?
      s << link_to(invoice_title, invoice_path(invoice), :class => 'icon icon-invoice', :download => true)
      s << " " + link_to(image_tag('page_white_acrobat_context.png', :plugin => "redmine_contacts_invoices"), invoice_path(invoice, :format => 'pdf'))
      s << " " + content_tag(:span, content_tag(:strong, invoice.amount_to_s), :class => "amount")
    else
      s << content_tag(:span, invoice_title, :class => 'icon icon-invoice')
    end
    s << " - #{invoice.subject}" unless invoice.subject.blank?
    s << " " + content_tag(:span, '(' + invoice.contact.name + ')', :class => 'contact') if invoice.contact
    s
  end

  def group_invoice_tag(invoice)
    invoice_title = "##{invoice.number} - #{format_date(invoice.invoice_date)}"
    s =
      if invoice.visible?
        link_to(invoice_title, invoice_path(invoice), :class => 'icon icon-invoice')
      else
        content_tag(:span, invoice_title, :class => 'icon icon-invoice')
      end
    s.html_safe
  end

  def contact_custom_fields
    if "ContactCustomField".is_a_defined_class?
      ContactCustomField.where("#{ContactCustomField.table_name}.field_format = 'string' OR #{ContactCustomField.table_name}.field_format = 'text'").map{|f| [f.name, f.id.to_s]}
    else
      []
    end
  end

  def invoices_list_styles_for_select
    list_styles = [[l(:label_crm_list_excerpt), "list_excerpt"]]
    list_styles += [[l(:label_crm_list_list), "list"],
                    [l(:label_calendar), "crm_calendars/crm_calendar"]]
  end

  def invoices_list_style
    list_styles = invoices_list_styles_for_select.map(&:last)
    if params[:invoices_list_style].blank?
      list_style = list_styles.include?(session[:invoices_list_style]) ? session[:invoices_list_style] : InvoicesSettings.default_list_style
    else
      list_style = list_styles.include?(params[:invoices_list_style]) ? params[:invoices_list_style] : InvoicesSettings.default_list_style
    end
    session[:invoices_list_style] = list_style
  end

  def expenses_list_style
    list_styles = ['list_excerpt', 'list']
    if params[:expenses_list_style].blank?
      list_style = list_styles.include?(session[:expenses_list_style]) ? session[:expenses_list_style] : InvoicesSettings.default_list_style
    else
      list_style = list_styles.include?(params[:expenses_list_style]) ? params[:expenses_list_style] : InvoicesSettings.default_list_style
    end
    session[:expenses_list_style] = list_style

  end


  def invoice_lang_options_for_select(has_blank=true)
    (has_blank ? [["(auto)", ""]] : []) +
      RedmineInvoices.available_locales.collect{|lang| [ ll(lang.to_s, :general_lang_name), lang.to_s]}.sort{|x,y| x.last <=> y.last }
  end

  def invoice_avaliable_locales_hash
    Hash[*invoice_lang_options_for_select.collect{|k, v| [v.blank? ? "default" : v, k]}.flatten]
  end

  def collection_invoice_status_names
    [[:draft, Invoice::DRAFT_INVOICE],
     [:estimate, Invoice::ESTIMATE_INVOICE],
     [:sent, Invoice::SENT_INVOICE],
     [:paid, Invoice::PAID_INVOICE],
     [:canceled, Invoice::CANCELED_INVOICE]]
  end

  def invoice_number_format(number)
    ActionController::Base.helpers.number_with_delimiter(number,
        :separator => ContactsSetting.decimal_separator,
        :delimiter => ContactsSetting.thousands_delimiter)
  end

  def collection_invoice_statuses
    Invoice::STATUSES.map{|k, v| [l(v), k]}
  end

  def collection_invoice_statuses_for_select
    collection_invoice_statuses.select{|s| s[1] != Invoice::PAID_INVOICE}
  end

  def collection_invoice_statuses_for_filter(status_id=nil)
    collection = collection_invoice_statuses.map{|s| [s[0], s[1].to_s]}
    collection.push [l(:label_invoice_overdue), "d"]
    collection.insert 0, [l(:label_open_issues), "o"]
    collection.insert 0, [l(:label_all), ""]
    collection
  end

  def label_with_currency(label, currency)
    l(label).mb_chars.capitalize.to_s + (currency.blank? ? '' : " (#{currency})")
  end

  def invoice_status_name(status, code=false)
    return (code ? "draft" : l(:label_invoice_status_draft)) unless collection_invoice_statuses.map{|v| v[1]}.include?(status)

    status_data = collection_invoice_statuses.select{|s| s[1] == status }.first[0]
    status_name = collection_invoice_status_names.select{|s| s[1] == status}.first[0]
    return (code ? status_name : status_data)
  end

  def collection_for_discount_types_select
    [:percent, :amount].each_with_index.collect{|l, index| [l("label_invoice_#{l.to_s}".to_sym), index]}
  end

  def link_to_remove_invoice_fields(name, f, options={})
    f.hidden_field(:_destroy) + link_to_function(name, "remove_invoice_fields(this)", options)
  end

  def discount_label(invoice)
    "#{l(:field_invoice_discount)} (#{"%2.f" % invoice.discount}%)"
  end

  def link_to_add_invoice_fields(name, f, association, options={})
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, "add_invoice_fields(this, '#{association}', '#{escape_javascript(fields)}')", options={})
  end

  def retrieve_invoices_query
    # debugger
    # params.merge!(session[:invoices_query])
    # session[:invoices_query] = {:project_id => @project.id, :status_id => params[:status_id], :category_id => params[:category_id], :assigned_to_id => params[:assigned_to_id]}

    if  params[:status_id] || !params[:contact_id].blank? || !params[:assigned_to_id].blank? || !params[:period].blank?
      session[:invoices_query] = {:project_id => (@project ? @project.id : nil),
                                  :status_id => params[:status_id],
                                  :contact_id => params[:contact_id],
                                  :period => params[:period],
                                  :assigned_to_id => params[:assigned_to_id]}
    else
      if api_request? || params[:set_filter] || session[:invoices_query].nil? || session[:invoices_query][:project_id] != (@project ? @project.id : nil)
        session[:invoices_query] = {}
      else
        params.merge!(session[:invoices_query])
      end
    end
  end

  def is_no_filters
    (params[:status_id] == 'o' && params[:assigned_to_id].blank? && (params[:period].blank? || params[:period] == 'all') && (params[:paid_period].blank? || params[:paid_period] == 'all') && (params[:due_date].blank? || params[:due_date] == 'all') && params[:contact_id].blank?)
  end

  def is_date?(str)
    temp = str.gsub(/[-.\/]/, '')
    ['%m%d%Y','%m%d%y','%M%D%Y','%M%D%y'].each do |f|
      begin
        return true if Date.strptime(temp, f)
      rescue
           #do nothing
      end
    end
  end

  def due_days(invoice)
    return "" if invoice.due_date.blank? || invoice.status_id != Invoice::SENT_INVOICE
    if invoice.due_date.to_date >= Date.today
      content_tag(:span, " (#{l(:label_invoice_days_due, :days => (invoice.due_date.to_date - Date.today).to_s)})", :class => "due-days")
    else
      content_tag(:span, " (#{l(:label_invoice_days_late, :days => (Date.today - invoice.due_date.to_date).to_s)})", :class => "overdue-days")
    end
  end

  def get_contact_extra_field(contact)
    field_id = InvoicesSettings[:invoices_contact_extra_field, @project]
    return "" if field_id.blank?
    return "" unless contact.respond_to?(:custom_values)
    contact.custom_values.find_by_custom_field_id(field_id)
  end

  def invoice_to_pdf(invoice)
    if invoice.custom_template || @invoice_template
      invoice_to_pdf_wicked_pdf(invoice, @invoice_template)
    elsif [RedmineInvoices::TEMPLATE_CLASSIC, RedmineInvoices::TEMPLATE_MODERN, RedmineInvoices::TEMPLATE_MODERN_LEFT, RedmineInvoices::TEMPLATE_BLANK_HEADER].include?(InvoicesSettings.template(@project))
      RedmineInvoices::InvoiceReports.invoice_to_pdf_prawn(invoice, InvoicesSettings.template(@project))
    else
      RedmineInvoices::InvoiceReports.invoice_to_pdf_prawn(invoice, RedmineInvoices::TEMPLATE_CLASSIC)
    end

  end
  def invoice_custom_templates_options_for_select
    templates = [[l(:label_no_change_option), '']]
    templates += InvoiceTemplate.visible.in_project_and_global(@project).map{|t| [t.name, t.id, {:title => t.description}]}
  end

  def invoice_templates_options_for_select(selected=nil, options={})
    invoice_templates = InvoiceTemplate.visible.in_project_and_global(@project)
    default_templates = [[l(:label_invoice_template_classic), RedmineInvoices::TEMPLATE_CLASSIC ],
                         [l(:label_invoice_template_modern), RedmineInvoices::TEMPLATE_MODERN ],
                         [l(:label_invoice_template_left), RedmineInvoices::TEMPLATE_MODERN_LEFT ],
                         [l(:label_invoice_template_blank_header), RedmineInvoices::TEMPLATE_BLANK_HEADER ]]

    s = ''
    if options[:no_change]
      s << content_tag('option', l(:label_no_change_option), :value => '')
    end
    groups = ''
    default_templates.sort.each do |element|
      selected_attribute = ' selected="selected"' if option_value_selected?(element, selected) || element.last.to_s == selected.to_s
      s << %(<option value="#{element.last}"#{selected_attribute}>#{h element.first}</option>)
    end
    groups = ''
    invoice_templates.sort.each do |element|
      selected_attribute = ' selected="selected"' if option_value_selected?(element, selected) || element.id.to_s == selected.to_s
      groups << %(<option value="#{element.id}"#{selected_attribute} title="#{element.description}">#{h element.name}</option>)
    end

    unless groups.empty?
      s << %(<optgroup label="#{h(l(:label_invoice_template_custom_plural))}">#{groups}</optgroup>)
    end
    s.html_safe
  end

  def invoice_to_pdf_wicked_pdf(invoice, template = nil)
    unless Redmine::Configuration['wkhtmltopdf_exe_path'].blank?
      WickedPdf.config = { exe_path: Redmine::Configuration['wkhtmltopdf_exe_path'] }
    end
    wicked_pdf = WickedPdf.new
    content = render_to_string(plain: liquidize_invoice(invoice, template), layout: 'invoices.pdf')
    wicked_pdf.pdf_from_string(content, encoding: 'UTF-8',
                                        page_size: 'A4',
                                        lowquality: wicked_pdf.binary_version.to_s == '0.12.4',
                                        margin: { top:    20, # default 10 (mm)
                                                  bottom: 20,
                                                  left:   20,
                                                  right:  20 },
                                        footer: { left: invoice.number, right: '[page]/[topage]' })
  rescue Exception => e
    e.message
  end

  def liquidize_invoice(invoice, template = nil)
    content = template ? template.content : invoice.custom_template.content
    assigns = {}
    assigns['account'] = AccountDrop.new(@project)
    assigns['invoice'] = InvoiceDrop.new(invoice)
    assigns['now'] = Time.now.utc
    assigns['today'] = Date.today

    registers = {}
    registers[:container] = invoice

    content = begin
      Liquid::Template.parse(content).render(Liquid::Context.new({}, assigns, registers)).html_safe
    rescue => e
      e.message
    end
  end

  def invoices_to_csv(invoices)
    decimal_separator = l(:general_csv_decimal_separator)
    encoding = 'utf-8'
    export = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  'Invoice date',
                  'Due date',
                  'Contact',
                  'Currency',
                  'Amount*',
                  'Paid amount*',
                  'Amount due',
                  'Paid date*',
                  'Discount',
                  'Status',
                  'Subject',
                  'Created',
                  'Updated',
                  'Assignee',
                  'Language',
                  'Order number',
                  'Project',
                  'Author',
                  'Description'
                  ]
      custom_fields = InvoiceCustomField.all
      custom_fields.each {|f| headers << f.name}
      # Description in the last column
      csv << headers.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      # csv lines
      invoices.each do |invoice|
        fields = [invoice.number,
                  format_date(invoice.invoice_date),
                  format_date(invoice.due_date),
                  !invoice.contact.blank? ? invoice.contact.name : '',
                  invoice.currency,
                  invoice.amount,
                  invoice.balance,
                  invoice.amount - invoice.balance,
                  format_date(invoice.paid_date),
                  "#{invoice.discount.to_s}#{'%' if invoice.discount_type == 0}",
                  invoice.status,
                  invoice.subject,
                  format_date(invoice.created_at),
                  format_date(invoice.updated_at),
                  !invoice.assigned_to.blank? ? invoice.assigned_to.name : '',
                  invoice.language,
                  invoice.order_number,
                  invoice.project,
                  invoice.author,
                  invoice.description
                  ]
        invoice.custom_field_values.each {|custom_value| fields << RedmineContacts::CSVUtils.csv_custom_value(custom_value) }
        csv << fields.collect {|c| Redmine::CodesetUtil.from_utf8(c.to_s, encoding) }
      end
    end
    export
  end

  def invoice_textile(text)
    RedmineInvoices::InvoiceFormater.new(text).to_html
  end

  def invoice_textile_body(text, invoice)
    ret = RedmineInvoices::InvoiceFormater.new(text).to_html
    ret = ret.gsub(/\{%pay_online%\}/, paypal_code(invoice))
    ret
  end

  def paypal_code(invoice)
    url = "https://www.paypal.com/cgi-bin/webscr?business=#{InvoicesSettings['invoices_paypal_account', @project]}&cmd=_xclick&currency_code=#{invoice.currency}&amount=#{invoice.amount.to_f}&item_name=#{paypal_item_name(invoice)}"
    img_src = "https://www.paypalobjects.com/en_US/i/btn/btn_buynowCC_LG.gif"
    "<a href='#{url}'><img src='#{img_src}'></img></a>"
  end

  def paypal_item_name(invoice)
    ret = "#{invoice.contact.try(:first_name)} - #{l(:label_invoice)} - #{invoice.number}"
    if invoice.subject.present?
      ret += " - #{invoice.subject}"
    end
    ret
  end

  def invoice_mail_body_text(text)
    text.gsub(/\{%pay_online%\}/, '')
  end

  def invoice_mail_macro(invoice, message)
    message = message.gsub(/\{%contact.first_name%\}/, invoice.contact.try(:first_name).to_s)
    message = message.gsub(/\{%contact.last_name%\}/, invoice.contact.try(:last_name).to_s)
    message = message.gsub(/\{%contact.name%\}/, invoice.contact.try(:name).to_s)
    message = message.gsub(/\{%contact.company%\}/, invoice.contact.try(:company).to_s)
    message = message.gsub(/\{%invoice.number%\}/, invoice.number.to_s)
    message = message.gsub(/\{%invoice.invoice_date%\}/, format_date(invoice.invoice_date).to_s)
    message = message.gsub(/\{%invoice.due_date%\}/, format_date(invoice.due_date).to_s)
    message = message.gsub(/\{%invoice.public_link%\}/, client_view_invoice_url(invoice, :token => invoice.token))

    invoice.custom_field_values.each do |value|
      message = message.gsub(/\{%#{value.custom_field.name}%\}/, value.value.to_s)
    end
    message
  end

end
