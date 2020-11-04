namespace :redmine do
  namespace :contacts do

    desc <<-END_DESC
Convert linked issues for deals and contacts to custom fields

  rake redmine:contacts:convert_links_to_custom_fields RAILS_ENV="production"
END_DESC

    task :convert_links_to_custom_fields => :environment do
      class DealsIssue < ActiveRecord::Base; end
      class ContactsIssue < ActiveRecord::Base; end

      deals_cf = CustomField.where(type: 'IssueCustomField', field_format: 'deal', name: 'Related deals (converted)')
                            .first_or_initialize
      deals_cf.safe_attributes = { is_for_all: true, multiple: true }

      contacts_cf = CustomField.where(type: 'IssueCustomField', field_format: 'contact', name: 'Related contacts (converted)')
                               .first_or_initialize
      contacts_cf.safe_attributes = { is_for_all: true, multiple: true }

      deals_cf.tracker_ids = Tracker.pluck(:id)
      contacts_cf.tracker_ids = Tracker.pluck(:id)
      deals_cf.save!
      contacts_cf.save!

      DealsIssue.where("1=1").each do |deal_issue|
        deals_cf.custom_values.create(customized_type: Issue,
                                      customized_id: deal_issue.issue_id,
                                      value: deal_issue.deal_id)
      end

      ContactsIssue.where("1=1").each do |contact_issue|
        contacts_cf.custom_values.create(customized_type: Issue,
                                         customized_id: contact_issue.issue_id,
                                         value: contact_issue.contact_id)
      end
    end
  end
end
