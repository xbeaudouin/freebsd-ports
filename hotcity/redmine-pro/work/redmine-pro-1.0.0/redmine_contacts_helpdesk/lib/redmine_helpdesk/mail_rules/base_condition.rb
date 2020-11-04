module RedmineHelpdesk
  module MailRules
    class BaseCondition
      include Redmine::I18n

      def values(_rule_instance = nil)
        nil
      end

      def label_for(_condition_options)
        nil
      end

      private

      def splitted_values(values)
        values.join.split(',')
      end
    end
  end
end
