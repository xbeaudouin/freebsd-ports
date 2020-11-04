require_dependency 'application_helper'

module RedmineHelpdesk
  module Patches
    module JournalsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :render_private_notes_indicator_without_helpdesk, :render_private_notes_indicator
          alias_method :render_private_notes_indicator, :render_private_notes_indicator_with_helpdesk
        end
      end

      module InstanceMethods
        def render_private_notes_indicator_with_helpdesk(journal)
          private_notes = render_private_notes_indicator_without_helpdesk(journal)

          if User.current.allowed_to?(:view_helpdesk_tickets, @project) && journal_message = journal.journal_message
            incoming = journal_message.is_incoming?

            title_text = []
            title_text << "#{l(:label_helpdesk_cc)}: #{journal_message.cc_address.to_s.gsub(',', ', ')}" if journal_message.cc_address.present?
            title_text << "#{l(:label_helpdesk_bcc)}: #{journal_message.bcc_address.to_s.gsub(',', ', ')}" if journal_message.bcc_address.present?

            message_avatar = avatar_to(journal_message.contact, size: 24)

            message_delimeter = content_tag('span', '|', class: 'separator')

            message_icon =
            content_tag('span', class: "icon #{incoming ? 'icon-email' : 'icon-email-to'}", title: title_text.join(';')) do
              incoming ? l(:label_received_from) : l(:label_sent_to)
            end

            message_contact =
            content_tag('span', class: "contact lined-text") do
              if incoming
                content_tag('span', "#{contact_tag(journal_message.contact, type: 'plain')} (#{journal_message.from_address})".html_safe)
              else
                journal_message.contact.emails.include?(journal_message.to_address) ? "#{contact_tag(journal_message.contact)} (#{journal_message.to_address})".html_safe : journal_message.to_address
              end
            end

            message_file =
            if attachment = journal_message.message_file
              content_tag('span', class: 'attachment') do
                content = [link_to_attachment(attachment, text: l(:label_helpdesk_original), class: 'icon icon-attachment')]
                content << h(" - #{attachment.description}") unless attachment.description.blank?
                content << content_tag('span', "(#{number_to_human_size attachment.filesize})", class: 'size')
                content << content_tag('span', link_to_if_authorized(image_tag('magnifier.png', plugin: 'redmine_contacts_helpdesk'),
                                                                                                controller: 'helpdesk', action: 'show_original',
                                                                                                id: attachment, project_id: @project))
                content.join.html_safe
              end
            end

            message_date =
            if journal_message.viewed?
              content_tag('span', format_time(journal_message.message_date),
                                  class: ' helpdesk-message-date viewed',
                                  title: l(:label_helpdesk_viewed_on, viewed_on: format_time(journal_message.viewed_on)))
            else
              content_tag('span', format_time(journal_message.message_date), class: 'helpdesk-message-date')
            end

            message_script = content_tag('script', "$('#change-#{journal.id} h4.note-header').html($('#change-#{journal.id} h4.note-header span.note-message-head'))".html_safe)

            mesasge_data = [incoming ? message_avatar : message_delimeter, message_icon, message_contact, message_file, message_date]
            message_content = content_tag('span', (mesasge_data << private_notes).join.html_safe, class: 'note-message-head')

            incoming ? message_content + message_script : message_content
          end
        end
      end
    end
  end
end

if Redmine::VERSION.to_s > '3.4' && !JournalsHelper.included_modules.include?(RedmineHelpdesk::Patches::JournalsHelperPatch)
  JournalsHelper.send(:include, RedmineHelpdesk::Patches::JournalsHelperPatch)
end
