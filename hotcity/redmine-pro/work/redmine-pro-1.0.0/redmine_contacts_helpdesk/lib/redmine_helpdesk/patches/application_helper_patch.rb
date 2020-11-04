require_dependency 'application_helper'

module RedmineHelpdesk
  module Patches
    module ApplicationHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          # TODO: Remove second condsition block after release 4.0.4
          if Gem::Version.new(Redmine::VERSION.to_s.gsub(/\.#{Redmine::VERSION::BRANCH}[\.\d]*$/, '')) < Gem::Version.new('4.0.4') ||
             Gem::Version.new(Redmine::VERSION.to_s.gsub(/\.#{Redmine::VERSION::BRANCH}[\.\d]*$/, '')) == Gem::Version.new('4.0.4') && Redmine::VERSION::BRANCH != 'devel'
            alias_method :avatar_without_helpdesk, :avatar
            alias_method :avatar, :avatar_with_helpdesk
          end

          alias_method :link_to_user_without_helpdesk, :link_to_user
          alias_method :link_to_user, :link_to_user_with_helpdesk
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

        def link_to_user_with_helpdesk(user, options = {})
          if user.is_a?(Contact)
            link_to_source(user, options)
          else
            link_to_user_without_helpdesk(user, options)
          end
        end
      end
    end
  end
end

unless ApplicationHelper.included_modules.include?(RedmineHelpdesk::Patches::ApplicationHelperPatch)
  ApplicationHelper.send(:include, RedmineHelpdesk::Patches::ApplicationHelperPatch)
end
