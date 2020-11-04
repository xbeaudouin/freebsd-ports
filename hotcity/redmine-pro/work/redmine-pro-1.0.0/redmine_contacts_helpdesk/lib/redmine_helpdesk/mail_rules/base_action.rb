module RedmineHelpdesk
  module MailRules
    class BaseAction
      include Redmine::I18n

      def values(_rule_instance = nil)
        nil
      end

      def label_for(_action_options)
        nil
      end

      def stop_action?
        false
      end

      private

      def splitted_values(values)
        values.join.split(',')
      end
    end
  end
end
