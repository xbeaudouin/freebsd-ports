module RedmineCrm
  module Liquid
    class IssuesDrop
      def spent_time_by_date
      	TimeEntry.where(issue_id: @issues.ids).order(:spent_on).group(:spent_on).sum(:hours)
      end
    end

    class IssueDrop
      def images
        @images ||= AttachmentImagesDrop.new(@issue.images)
      end

      def project_name
        @project_name ||= @issue.project && @issue.project.name  
      end


      def total_spent_time_by_date
      	total_spent_time_by_date ||= if @issue.leaf? 
      		@issue.time_entries.order(:spent_on).group(:spent_on).sum(:hours)
      	else
      		@issue.self_and_descendants.joins(:time_entries).group(:spent_on).sum("#{TimeEntry.table_name}.hours")
      	end
      end

      def available_statuses
      	@available_statuses ||= IssueStatus.all.inject({}){|memo, s| memo[s.id.to_s] = s.name;memo }
      end

      def time_in_status
      	@time_in_status = status_changes.each_with_index.map do |j, i| 
      		from_time = j.journal.created_on.localtime
      		to_time = (status_changes[i + 1].try(:journal).try(:created_on) || Time.now).localtime
      		duration_in_minutes = (([from_time, to_time].max - [from_time, to_time].min)/60.0).round
      		{"from_date" => from_time, 
      		 "to_date" => to_time, 
      		 "status" => available_statuses[j.value],
      		 "duration" => duration_in_minutes,
      		 "author" => UserDrop.new(j.journal.user)}
      	end

    		# first status should be calculated separatly
    		from_time = @issue.created_on.localtime
    		to_time = (status_changes.first.try(:journal).try(:created_on) || Time.now).localtime
    		first_status = available_statuses[status_changes.first.try(:old_value) || @issue.status_id.to_s]
    		duration_in_minutes = (([from_time, to_time].max - [from_time, to_time].min)/60.0).round
    		first_author = UserDrop.new(status_changes.first.try(:journal).try(:user) || @issue.author)
      	@time_in_status.
      		unshift({"from_date" => from_time, 
	      					 "to_date" => to_time,
	      					 "status" => first_status,
	      					 "duration" => duration_in_minutes,
	      					 "author" => first_author})

      end

      def total_time_in_status
      	@total_time_in_status ||= time_in_status.inject({}) do |mem, status_change|  
      		mem[status_change["status"]] = mem[status_change["status"]].to_f + status_change["duration"].to_f
      		mem
      	end
      end

      protected

      def status_changes
      	@status_changes ||= JournalDetail.
      		eager_load(:journal).
      		where(journals: {journalized_id: @issue.id}).
      		where(prop_key: 'status_id').order("#{Journal.table_name}.created_on")
      end



    end
  end
end
