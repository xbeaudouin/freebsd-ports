namespace :redmine do
  namespace :invoices do

    desc <<-END_DESC
Generate and send recirrung invoices

  rake redmine:invoices:recurring RAILS_ENV="production"
END_DESC

    task :recurring => :environment do
      RecurringInvoicesService.new.process_invoices
    end
  end
end
