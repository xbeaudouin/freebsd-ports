# <PRO>
namespace :redmine do
  namespace :contacts do

    desc <<-END_DESC
Send reminders about deals due in the next days.

Available options:
  * days     => number of days to remind about (defaults to 7)
  * project  => id or identifier of project (defaults to all projects)
  * users    => comma separated list of user/group ids who should be reminded

Example:
  rake redmine:contacts:send_reminders days=7 users="1,23, 56" project='foo' RAILS_ENV="production"
END_DESC

    task send_reminders: :environment do
      options = {}
      options[:days]    = ENV['days'].presence.try(:to_i)
      options[:project] = ENV['project'].presence
      options[:users]   = ENV['users'].presence
                                      .to_s
                                      .split(',')
                                      .each(&:strip!)

      ContactsMailer.with_synched_deliveries { ContactsMailer.deals_reminders(options) }
    end
  end
end
# </PRO>
