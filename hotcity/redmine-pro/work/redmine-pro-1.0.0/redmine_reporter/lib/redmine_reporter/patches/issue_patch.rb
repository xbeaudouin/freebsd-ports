module RedmineReporter
  module Patches
    module IssuePatch
      def self.included(base)
        base.class_eval do
          include InstanceMethods
        end
      end

      module InstanceMethods
        def images
          ReporterAttachmentImage.where(container_id: id)
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineReporter::Patches::IssuePatch)
  Issue.send(:include, RedmineReporter::Patches::IssuePatch)
end
