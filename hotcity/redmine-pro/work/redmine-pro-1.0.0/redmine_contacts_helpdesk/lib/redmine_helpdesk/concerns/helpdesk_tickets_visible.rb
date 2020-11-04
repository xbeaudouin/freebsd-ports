module RedmineHelpdesk
  module Concerns
    module HelpdeskTicketsVisible
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          scope :visible, lambda { |*args| joins(joined_model).where(HelpdeskTicket.visible_condition(args.shift || User.current, *args)) }
        end
      end

      module ClassMethods
        def joined_model
          raise 'Implement this method in model'
        end

        def visible_condition(consumer, options = {})
          Project.allowed_to_condition(consumer, :view_helpdesk_tickets, options) do |role, user|
            sql = if user.id && user.logged?
                    case role.issues_visibility
                    when 'all'
                      '1=1'
                    when 'default'
                      user_ids = [user.id] + user.groups.map(&:id).compact
                      "(issues.is_private = #{connection.quoted_false} OR issues.author_id = #{user.id} OR issues.assigned_to_id IN (#{user_ids.join(',')}))"
                    when 'own'
                      user_ids = [user.id] + user.groups.map(&:id).compact
                      "(issues.author_id = #{user.id} OR issues.assigned_to_id IN (#{user_ids.join(',')}))"
                    else
                      '1=0'
                    end
                  else
                    "(issues.is_private = #{connection.quoted_false})"
                  end
            unless role.permissions_all_trackers?(:view_helpdesk_tickets)
              tracker_ids = role.permissions_tracker_ids(:view_helpdesk_tickets)
              sql = tracker_ids.any? ? "(#{sql} AND issues.tracker_id IN (#{tracker_ids.join(',')}))" : '1=0'
            end
            sql
          end
        end
      end
    end
  end
end
