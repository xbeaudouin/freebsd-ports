module RedmineHelpdesk
  module Patches
    module JournalsControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :new_without_helpdesk, :new
          alias_method :new, :new_with_helpdesk
        end
      end

      module InstanceMethods
        def new_with_helpdesk
          @journal = Journal.visible.find(params[:journal_id]) if params[:journal_id]
          if @journal
            user = @journal.user
            text = @journal.notes
            user = @journal.contact if user.anonymous? && @journal.contact
          else
            user = @issue.author
            text = @issue.description
            user = @issue.customer if user.anonymous? && @issue.customer
          end
          # Replaces pre blocks with [...]
          text = text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]')
          @content = "#{ll(Setting.default_language, :text_user_wrote, user)}\n> "
          @content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
        rescue ActiveRecord::RecordNotFound
          render_404
        end
      end
    end
  end
end

unless JournalsController.included_modules.include?(RedmineHelpdesk::Patches::JournalsControllerPatch)
  JournalsController.send(:include, RedmineHelpdesk::Patches::JournalsControllerPatch)
end
