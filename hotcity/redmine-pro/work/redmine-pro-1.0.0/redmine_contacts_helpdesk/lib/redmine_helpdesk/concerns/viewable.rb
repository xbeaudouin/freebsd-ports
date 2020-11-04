module RedmineHelpdesk
  module Concerns
    module Viewable
      extend ActiveSupport::Concern

      included do
        before_create :calculate_view_id

        scope :not_viewed, -> { where(viewed_on: nil) }
      end

      def viewed?
        RedmineHelpdesk.add_readmark? && viewed_on.present?
      end

      def calculate_view_id
        return view_id if view_id
        loop do
          self.view_id = SecureRandom.urlsafe_base64(16, false)
          break if self.class.where(view_id: view_id).empty?
        end
        view_id
      end
    end
  end
end
