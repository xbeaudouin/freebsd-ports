# This file is a part of Redmine ZenEdit (redmine_zenedit) plugin,
# editing enhancement plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
# http://www.redmineup.com/
#
# redmine_zenedit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_zenedit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_zenedit.  If not, see <http://www.gnu.org/licenses/>.

module RedmineZenedit
  module Patches
    module IssuePatch
      def self.included(base)
        base.rcrm_acts_as_draftable parent: :project
        base.class_eval do
          include RedmineZenedit::Helper
          include InstanceMethods

          alias_method :notified_users_without_zen_mentions, :notified_users
          alias_method :notified_users, :notified_users_with_zen_mentions

          if Redmine::VERSION.to_s < '3.4'
            scope :like, lambda { |q|
              q = q.to_s
              if q.present?
                where("LOWER(#{table_name}.subject) LIKE LOWER(?)", "%#{q}%")
              end
            }
          end
        end
      end

      module InstanceMethods
        def notified_users_with_zen_mentions
          if current_journal
            text = current_journal.notes.to_s
            journal_detail = current_journal.details.last
            text += " #{journal_detail.value}" if journal_detail.try(:prop_key) == 'description'
          else
            text = description
          end

          mentioned_users = User.where(login: find_mentions(text)).to_a
          mentioned_users.reject! { |user| !visible?(user) } # Remove users that can not view the issue

          (notified_users_without_zen_mentions + mentioned_users).uniq
        end

        def dump_to_draft
          Marshal.dump(
            subject: subject,
            description: description,
            notes: current_journal.try(:notes)
          )
        end

        def load_from_draft(val)
          hsh = Marshal.load(val)

          assign_attributes(hsh)
          return self unless hsh[:notes]

          init_journal(User.current)
          self.notes = hsh[:notes]
          self
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineZenedit::Patches::IssuePatch)
  Issue.send(:include, RedmineZenedit::Patches::IssuePatch)
end
