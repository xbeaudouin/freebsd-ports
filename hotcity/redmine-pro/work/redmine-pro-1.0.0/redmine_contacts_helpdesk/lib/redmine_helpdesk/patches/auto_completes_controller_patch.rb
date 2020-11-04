require_dependency 'auto_completes_controller'

module RedmineHelpdesk
  module Patches
    module AutoCompletesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
        end
      end

      module InstanceMethods
        def assignee
          assignee_classes = ['User']
          assignee_classes << 'Group' if Setting.issue_group_assignment?

          scope = Principal.where(type: assignee_classes).limit(100)
          scope = scope.member_of(@project) if @project.present?
          scope = Rails.version >= '5.1' ? scope.distinct : scope.uniq
          @assignee = scope.active.visible.sorted.like(params[:q]).to_a
          @assignee = @assignee.sort! { |x, y| x.name <=> y.name }
          render layout: false, partial: 'assignee'
        end
      end
    end
  end
end

unless AutoCompletesController.included_modules.include?(RedmineHelpdesk::Patches::AutoCompletesControllerPatch)
  AutoCompletesController.send(:include, RedmineHelpdesk::Patches::AutoCompletesControllerPatch)
end
