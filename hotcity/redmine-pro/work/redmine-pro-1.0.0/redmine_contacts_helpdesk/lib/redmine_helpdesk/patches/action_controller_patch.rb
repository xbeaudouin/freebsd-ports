module RedmineHelpdesk
  module Patches
    module ActionControllerPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do
        end
      end

      module ClassMethods
        def after_action(*filters, &block)
          after_filter(*filters, &block)
        end
      end
    end
  end
end

unless ActionController::Base.methods.include?(:after_action)
  ActionController::Base.send(:include, RedmineHelpdesk::Patches::ActionControllerPatch)
end
