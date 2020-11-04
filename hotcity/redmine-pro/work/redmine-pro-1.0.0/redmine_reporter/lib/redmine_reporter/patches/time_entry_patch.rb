module RedmineReporter
  module Patches
    module TimeEntryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        # Returns true if user or current user is allowed to view the time entry
        def visible?(user = nil)
          (user || User.current).allowed_to?(:view_time_entries, self.project)
        end unless TimeEntry.public_instance_methods.include?(:visible?)
      end
    end
  end
end

unless TimeEntry.included_modules.include?(RedmineReporter::Patches::TimeEntryPatch)
  TimeEntry.send(:include, RedmineReporter::Patches::TimeEntryPatch)
end
