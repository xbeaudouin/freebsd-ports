namespace :redmine do
  namespace :plugins do
    namespace :invoices do
      desc <<-END_DESC
Migrate custom templates

Examples:

  rake redmine:plugins:invoices:migrate_templates RAILS_ENV="production"
END_DESC

      task :migrate_templates => :environment do

        if global_template = InvoicesSettings.custom_template(nil)
          InvoiceTemplate.create(:name => "Redmine", :content => global_template)
          puts "Global custom template migrated"
        end

        ContactsSetting.where(:name => "invoices_custom_template").each do |cs|
          InvoiceTemplate.create(:name => cs.project.name, :content => cs.value, :project_id => cs.project_id)
          puts "#{cs.project.name} custom template migrated"
        end

      end


    end
  end
end
