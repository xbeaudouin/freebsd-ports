require_dependency 'query'

module RedmineHelpdesk
  module Patches
    module ContactQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.send(:include, HelpdeskHelper)

        base.class_eval do
          unloadable

          alias_method :available_filters_without_helpdesk, :available_filters
          alias_method :available_filters, :available_filters_with_helpdesk

          alias_method :available_columns_without_helpdesk, :available_columns
          alias_method :available_columns, :available_columns_with_helpdesk
        end
      end

      module InstanceMethods
        def sql_for_number_of_tickets_field(_, operator, value)
          sql_value = case operator
                      when '=', '<=', '>='
                        value.first.to_i
                      when '><'
                        value = value.map.with_index { |elem, ind| (elem.blank? ? value[ind - 1] : elem).to_i }
                      when '!*', '*'
                        0
                      end
          sql = case operator
                when '='
                  sql_value != 0 ? in_condition_sql(operator, sql_value) : not_condition_sql
                when '>='
                  sql_value > 0 ? in_condition_sql(operator, sql_value) : '(1=1)'
                when '<='
                  if sql_value > 0
                    "(#{in_condition_sql(operator, sql_value, false)} OR #{not_condition_sql(false)})"
                  else
                    sql_value == 0 ? not_condition_sql : '(1=0)'
                  end
                when '><'
                  if sql_value.all? { |val| val > 0 }
                    in_condition_sql('BETWEEN', sql_value.join(' AND '))
                  else
                    if sql_value.all? { |val| val < 0 }
                      '(1=0)'
                    else
                      "(#{in_condition_sql('BETWEEN', sql_value.join(' AND '), false)} OR #{not_condition_sql(false)})"
                    end
                  end
                when '!*'
                  not_condition_sql
                when '*'
                  "#{Contact.table_name}.id IN (SELECT DISTINCT(#{HelpdeskTicket.table_name}.contact_id) FROM #{HelpdeskTicket.table_name})"
                end
          sql
        end

        def in_condition_sql(operator, value, brackets = true)
          htn = HelpdeskTicket.table_name
          in_sql = "#{Contact.table_name}.id IN (SELECT #{htn}.contact_id FROM #{htn} GROUP BY #{htn}.contact_id HAVING count(#{htn}.contact_id) #{operator} #{value})"
          return "(#{in_sql})" if brackets
          in_sql
        end

        def not_condition_sql(brackets = true)
          htn = HelpdeskTicket.table_name
          not_sql = "#{Contact.table_name}.id NOT IN (SELECT DISTINCT(#{htn}.contact_id) FROM #{htn})"
          return "(#{not_sql})" if brackets
          not_sql
        end

        def sql_for_open_tickets_field(_, operator, value)
          value = value.first
          in_cond = if (operator == '!' && value == '0') || (operator == '=' && value == '1')
                      'IN'
                    else
                      'NOT IN'
                    end
          "(#{Contact.table_name}.id #{in_cond} (SELECT #{HelpdeskTicket.table_name}.contact_id
            FROM #{HelpdeskTicket.table_name}
            INNER JOIN #{Issue.table_name} on #{Issue.table_name}.id = #{HelpdeskTicket.table_name}.issue_id
            INNER JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id
            WHERE (#{IssueStatus.table_name}.is_closed = #{ActiveRecord::Base.connection.quoted_false})
            ))"
        end

        def available_filters_with_helpdesk
          if @available_filters.blank? && User.current.allowed_to?(:view_helpdesk_tickets, project, :global => true)

            add_available_filter('number_of_tickets', :type => :integer, :name => l(:label_helpdesk_number_of_tickets)) unless available_filters_without_helpdesk.key?('number_of_tickets')
            add_available_filter('open_tickets', :type => :list, :name => l(:label_helpdesk_open_tickets), :values => [[l(:general_text_yes), '1'], [l(:general_text_no), '0']]) unless available_filters_without_helpdesk.key?('open_tickets')
          else
            available_filters_without_helpdesk
          end
          @available_filters
        end

        def available_columns_with_helpdesk
          if @available_columns.blank? && User.current.allowed_to?(:view_helpdesk_tickets, project, :global => true)
            @available_columns = available_columns_without_helpdesk
            @available_columns << QueryColumn.new(:tickets_count, :caption => :label_helpdesk_number_of_tickets)
          else
            available_columns_without_helpdesk
          end
          @available_columns
        end
      end
    end
  end
end

unless ContactQuery.included_modules.include?(RedmineHelpdesk::Patches::ContactQueryPatch)
  ContactQuery.send(:include, RedmineHelpdesk::Patches::ContactQueryPatch)
end
