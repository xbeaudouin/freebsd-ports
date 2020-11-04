module RedmineHelpdesk
  module Patches
    module QueryPatch
      def self.included(base)
        base.class_eval do
          operators_by_filter_type[:date_with_labels] = ["=", "t", "nd", "da"]
          operators["da"] = :label_helpdesk_days_after
        end
      end
    end
  end
end

unless Query.included_modules.include?(RedmineHelpdesk::Patches::QueryPatch)
  Query.send(:include, RedmineHelpdesk::Patches::QueryPatch)
end
