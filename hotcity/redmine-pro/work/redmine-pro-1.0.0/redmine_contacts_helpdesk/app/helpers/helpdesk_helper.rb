module HelpdeskHelper
  def helpdesk_ticket_source_icon(helpdesk_ticket)
    case helpdesk_ticket.source
    when HelpdeskTicket::HELPDESK_EMAIL_SOURCE
      'icon-email'
    when HelpdeskTicket::HELPDESK_PHONE_SOURCE
      'icon-call'
    when HelpdeskTicket::HELPDESK_WEB_SOURCE
      'icon-web'
    when HelpdeskTicket::HELPDESK_TWITTER_SOURCE
      'icon-twitter'
    else
      'icon-helpdesk'
    end
  end

  def helpdesk_tickets_source_for_select
    [[l(:label_helpdesk_tickets_email), HelpdeskTicket::HELPDESK_EMAIL_SOURCE.to_s],
     [l(:label_helpdesk_tickets_phone), HelpdeskTicket::HELPDESK_PHONE_SOURCE.to_s],
     [l(:label_helpdesk_tickets_web), HelpdeskTicket::HELPDESK_WEB_SOURCE.to_s],
     [l(:label_helpdesk_tickets_conversation), HelpdeskTicket::HELPDESK_CONVERSATION_SOURCE.to_s]
    ]
  end

  def helpdesk_send_as_for_select
    [[l(:label_helpdesk_not_send), ''],
     [l(:label_helpdesk_send_as_notification), HelpdeskTicket::SEND_AS_NOTIFICATION.to_s],
     [l(:label_helpdesk_send_as_message), HelpdeskTicket::SEND_AS_MESSAGE.to_s]
    ]
  end

  def show_customer_vote(vote, comment)
    case vote
    when 2
      generate_vote_link(vote, 'icon-awesome', comment)
    when 1
      generate_vote_link(vote, 'icon-justok', comment)
    when 0
      generate_vote_link(vote, 'icon-notgood', comment)
    end
  end

  def generate_vote_link(vote, vote_class, title)
    "<div class='icon #{vote_class}' title='#{title}'>#{HelpdeskTicket.vote_message(vote)}</div>".html_safe
  end

  def render_helpdesk_chart(report_name, issues_scope)
    render :partial => 'helpdesk_reports/chart', :locals => { :report => report_name, :issues_scope => issues_scope }
  end

  def helpdesk_time_label(seconds)
    hours, minutes = seconds.divmod(60).first.divmod(60)
    "#{hours}<span>#{l(:label_helpdesk_hour)}</span> #{minutes}<span>#{l(:label_helpdesk_minute)}</span>".html_safe
  end

  def slim_helpdesk_time_label(seconds)
    hours, minutes = seconds.divmod(60).first.divmod(60)
    "#{hours}#{l(:label_helpdesk_hour)} #{minutes}#{l(:label_helpdesk_minute)}".html_safe
  end

  def progress_in_percents(value)
    return '0%'.html_safe if value.zero?
    "<span class='caret #{value > 0 ? 'pos' : 'neg'}'></span>#{value}%".html_safe
  end

  def mirror_progress_in_percents(value)
    return '0%'.html_safe if value.zero?
    "<span class='caret #{value < 0 ? 'mirror_pos' : 'mirror_neg'}'></span>#{value}%".html_safe
  end

  def process_deviation(before, now, time = true)
    ["#{l(:label_helpdesk_report_previous)}: #{time ? slim_helpdesk_time_label(before) : before}",
     "#{l(:label_helpdesk_report_deviation)}: #{time ? slim_helpdesk_time_label(calculate_deviation(before, now)) : calculate_deviation(before, now)}"].join("\n").html_safe
  end

  def calculate_deviation(before, now)
    before > now ? before - now : now - before
  end

  def helpdesk_reply_link
    link_to l(:label_helpdesk_reply), edit_issue_path(@issue), :onclick => 'showAndScrollTo("update", "issue_notes"); showConfiguredSend("update", "issue_notes", true); return false',
                                                               :class => 'icon icon-helpdesk-reply'
  end

  def helpdesk_mail_rule_mail_types_for_select(selected = nil)
    mail_types_options = [
      [l(:label_helpdesk_mail_rule_mail_type_incoming), HelpdeskMailRule::INCOMING],
      [l(:label_helpdesk_mail_rule_mail_type_outgoing), HelpdeskMailRule::OUTGOING]
      # TODO: Manual rules
      # [l(:label_helpdesk_mail_rule_mail_type_manually), HelpdeskMailRule::MANUALLY]
    ]
    options_for_select(mail_types_options, selected)
  end

  def helpdesk_mail_rule_attrs_for_select(collection)
    elements = []
    collection.each do |element, element_options|
      elements << [element_options[:name], element]
    end
    options_for_select([[]] + elements)
  end

  def helpdesk_mail_rule_conditions_to_html(conditions)
    return content_tag('p', l(:label_helpdesk_mail_rule_condition_for_all), class: 'helpdesk_mail_rule_condition') unless conditions.any?

    conditions.map do |condition, options|
      next unless HelpdeskMailRule.available_conditions[condition]

      condition = HelpdeskMailRule.available_conditions[condition].new
      content_tag('p',
                  [
                    condition.options[:name],
                    l(Query.operators[options[:operator]]),
                    content_tag('b', condition.label_for(options) || options[:values].join(','))
                  ].join(' ').html_safe,
                  class: 'helpdesk_mail_rule_condition')
    end.join.html_safe
  end

  def helpdesk_mail_rule_actions_to_html(actions)
    actions.map do |action, options|
      rule = HelpdeskMailRule.available_actions[action].try(:new)
      next unless rule
      content_tag('p',
                  helpdesk_mail_rule_change_to_label(rule, options).html_safe,
                  class: "helpdesk_mail_rule_condition #{'red' if rule.is_a?(RedmineHelpdesk::MailRules::Actions::Stop)}")
    end.compact.join.html_safe
  end

  def helpdesk_mail_rule_change_to_label(rule, options)
    return rule.options[:name] if HelpdeskMailRule::NO_VALUES_ACTION_KEYS.include?(rule.field)

    [
      rule.options[:name],
      l(:label_helpdesk_mail_rule_action_change_to),
      content_tag('b', rule.label_for(options) || options[:values].join(','))
    ].join(' ')
  end

  def helpdesk_select_customer_tag(name, select_values = [], options = {})
    cross_project_contacts = ContactsSetting.cross_project_contacts? || !!options.delete(:cross_project_contacts)
    s = select2_tag(
      name,
      options_for_select(select_values, options[:selected]),
      url: auto_complete_contacts_path(project_id: (cross_project_contacts ? nil : @project), is_company: (options[:is_company] ? '1' : nil), multiaddress: options[:multiaddress]),
      placeholder: '',
      style: options[:style] || 'width: 60%',
      width: options[:width] || '60%',
      include_blank: true,
      format_state: (options[:multiaddress] ? 'formatStateWithMultiaddress' : 'formatStateWithAvatar'),
      format_selection: 'formatSelectionWithEmails',
      allow_clear: !!options[:include_blank]
    )

    if options[:add_contact] && @project.persisted?
      if authorize_for('contacts', 'new')
        s << link_to(
          image_tag('add.png', style: 'vertical-align: middle; margin-left: 5px;'),
          new_project_contact_path(@project, contact_field_name: name, contacts_is_company: !!options[:is_company]),
          remote: true,
          method: 'get',
          title: l(:label_crm_contact_new),
          id: "#{sanitize_to_id(name)}_add_link",
          tabindex: 200
        )
      end

      s << javascript_include_tag('attachments')
    end

    s.html_safe
  end

  def helpdesk_issue_contact_emails(issue)
    contact_emails = []
    ticket = issue.helpdesk_ticket
    ([ticket.from_address] + ticket.cc_address.to_s.split(',') + ticket.response_addresses).uniq.each do |email|
      contact_emails << [email, email]
    end
    (issue.contacts + [issue.customer]).uniq.each do |contact|
      contact.emails.each { |email| contact_emails << [contact.email_name, email] }
    end
    contact_emails.uniq(&:last)
  end

  def helpdesk_issue_customer_text_with_email(helpdesk_ticket)
    return '' unless helpdesk_ticket.customer
    return helpdesk_ticket.customer.name_with_company unless helpdesk_ticket.from_address
    "#{helpdesk_ticket.customer.name_with_company} <#{helpdesk_ticket.from_address}>"
  end
end
