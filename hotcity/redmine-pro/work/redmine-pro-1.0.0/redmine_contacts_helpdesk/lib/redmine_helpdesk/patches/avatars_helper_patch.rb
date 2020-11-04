require_dependency 'application_helper'

module RedmineHelpdesk
  module Patches
    module AvatarsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method :avatar_without_helpdesk, :avatar
          alias_method :avatar, :avatar_with_helpdesk
        end
      end

      module InstanceMethods
        def avatar_with_helpdesk(user, options = {})
          if user.is_a?(Contact)
            avatar_to(user, options)
          else
            avatar_without_helpdesk(user, options)
          end
        end
      end
    end
  end
end

if Object.const_defined?('AvatarsHelper') && !AvatarsHelper.included_modules.include?(RedmineHelpdesk::Patches::AvatarsHelperPatch)
  AvatarsHelper.send(:include, RedmineHelpdesk::Patches::AvatarsHelperPatch)
end
