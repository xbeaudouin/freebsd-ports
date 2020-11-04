module RedmineHelpdesk
  module Patches
    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          # before_filter :apply_helpdesk_macro, :only => :update
          after_action :flash_helpdesk, :only => :update
          after_action :send_auto_answer, :only => :create

          alias_method :build_new_issue_from_params_without_helpdesk, :build_new_issue_from_params
          alias_method :build_new_issue_from_params, :build_new_issue_from_params_with_helpdesk
          alias_method :update_issue_from_params_without_helpdesk, :update_issue_from_params
          alias_method :update_issue_from_params, :update_issue_from_params_with_helpdesk
          helper :helpdesk
        end
      end

      module InstanceMethods
        def flash_helpdesk
          if @issue.current_journal.is_send_note
            render_send_note_warning_if_needed(@issue.current_journal)
            flash[:notice] = flash[:notice].to_s + ' ' + l(:notice_email_sent, "<span class='icon icon-email'>" + @issue.current_journal.journal_message.to_address + '</span>') if @issue.current_journal.send_note_errors.blank?
          end
        end

        def send_auto_answer
          return unless @issue && @issue.customer && User.current.allowed_to?(:send_response, @project)
          case params[:helpdesk_send_as].to_i
          when HelpdeskTicket::SEND_AS_NOTIFICATION
            msg = HelpdeskMailer.auto_answer(@issue.customer, @issue, params.merge(to_address: @issue.helpdesk_ticket.from_address))
          when HelpdeskTicket::SEND_AS_MESSAGE
            if msg = HelpdeskMailer.initial_message(@issue.customer, @issue, params.merge(to_address: @issue.helpdesk_ticket.from_address))
              @issue.helpdesk_ticket.message_id = msg.message_id
              @issue.helpdesk_ticket.is_incoming = false
              @issue.helpdesk_ticket.from_address = @issue.helpdesk_ticket.from_address || @issue.customer.primary_email
              @issue.helpdesk_ticket.save
            end
          end
          flash[:notice].blank? ? flash[:notice] = l(:notice_email_sent, "<span class='icon icon-email'>" + msg.to_addrs.first + '</span>') : flash[:notice] << ' ' + l(:notice_email_sent, "<span class='icon icon-email'>" + msg.to_addrs.first + '</span>') if msg
        rescue Exception => e
          flash[:error].blank? ? flash[:error] = e.message : flash[:error] << ' ' + e.message
        end

        def update_issue_from_params_with_helpdesk
          is_updated = update_issue_from_params_without_helpdesk
          return false unless is_updated
          if params[:helpdesk] && params[:helpdesk][:is_send_mail].to_i > 0 && User.current.allowed_to?(:send_response, @project) && @issue.customer
            @issue.helpdesk_ticket.is_send_mail = params[:helpdesk][:is_send_mail]
            @issue.current_journal.build_journal_message
            if params[:journal_message]
              message_params = params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash['journal_message'] : params[:journal_message]
              journal_params = message_params.merge(Hash[message_params.slice('to_address', 'cc_address', 'bcc_address').map { |k, v| [k, v.join(',')] }])
              @issue.current_journal.journal_message.safe_attributes = journal_params
              @issue.current_journal.journal_message.save
            end
            @issue.current_journal.journal_message.to_address ||= @issue.customer.primary_email
            @issue.current_journal.is_send_note = true
            @issue.current_journal.notes = HelpdeskMailSupport.apply_text_macro(@issue.current_journal.notes, @issue.customer, @issue, User.current)
          end
          is_updated
        end

        def build_new_issue_from_params_with_helpdesk
          build_new_issue_from_params_without_helpdesk
          assign_customer_to_helpdesk_ticket
          return if @issue.blank? || params[:customer_id].blank?

          contact = Contact.visible.find_by_id(params[:customer_id])
          @issue.build_helpdesk_ticket unless @issue.helpdesk_ticket
          @issue.helpdesk_ticket.customer = contact if contact
          @issue.helpdesk_ticket.source = params[:source] if params[:source]
        end

        def render_send_note_warning_if_needed(journal)
          return false if journal.blank? || journal.journal_message.blank?
          flash[:warning] = flash[:warning].to_s + ' ' + l(:label_helpdesk_email_sending_problems) + ': ' + journal.send_note_errors unless journal.send_note_errors.blank?
        end

        def assign_customer_to_helpdesk_ticket
          return if @issue.try(:helpdesk_ticket).blank? || params[:customer_address].blank?
          @issue.helpdesk_ticket.customer = HelpdeskMailSupport.create_contact_from_address(params[:customer_address],
                                                                                            params[:customer_address],
                                                                                            @project) if params[:customer_id].blank?
          @issue.helpdesk_ticket.from_address = params[:customer_address] if params[:customer_address].include?('@')
        end
      end
    end
  end
end

unless IssuesController.included_modules.include?(RedmineHelpdesk::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineHelpdesk::Patches::IssuesControllerPatch)
end
