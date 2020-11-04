module RedmineHelpdesk
  module Patches
    module SettingsControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          helper :helpdesk
        end
      end

      module InstanceMethods
      end
    end
  end
end

unless SettingsController.included_modules.include?(RedmineHelpdesk::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineHelpdesk::Patches::SettingsControllerPatch)
end
