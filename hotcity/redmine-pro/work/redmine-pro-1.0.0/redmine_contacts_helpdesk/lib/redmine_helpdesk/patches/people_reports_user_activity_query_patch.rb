if Redmine::Plugin.installed?(:redmine_people) && Redmine::Plugin.find(:redmine_people).version >= '1.4.1' && PEOPLE_VERSION_TYPE == 'PRO version'
  module RedmineHelpdesk
    module Patches
      module PeopleReportsUserActivityQueryPatch
        def self.included(base)
          base.send(:include, InstanceMethods)

          base.class_eval do
            alias_method :activity_types_without_helpdesk, :activity_types
            alias_method :activity_types, :activity_types_with_helpdesk
          end
        end

        module InstanceMethods
          def activity_types_with_helpdesk
            activity_types_without_helpdesk << [l(:label_helpdesk_activity_type_customer_answer), :answer_to_customer]
          end

          def filter_journals_by_activity_type(params, relation)
            case params[:values].first
            when 'update_issue'
              params[:operator] == '=' ? relation.joins(journals_without_messages) : relation.joins(:journal_message)
            when 'answer_to_customer'
              params[:operator] == '=' ? relation.joins(:journal_message) : relation.joins(journals_without_messages)
            else
              relation
            end
          end

          def journals_without_messages
            Journal.arel_table.join(JournalMessage.arel_table, Arel::Nodes::OuterJoin)
                   .on(JournalMessage.arel_table[:journal_id].eq(Journal.arel_table[:id]))
                   .where(JournalMessage.arel_table[:id].eq(nil))
                   .project(Arel.sql('*'))
                   .join_sources
          end
        end
      end
    end
  end

  unless PeopleReportsUserActivityQuery.included_modules.include?(RedmineHelpdesk::Patches::PeopleReportsUserActivityQueryPatch)
    PeopleReportsUserActivityQuery.send(:include, RedmineHelpdesk::Patches::PeopleReportsUserActivityQueryPatch)
  end
end
