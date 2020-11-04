# custom routes for this plugin
resources :helpdesk_tickets, only: [:index, :create, :show, :edit, :destroy, :update]
resources :journal_messages, only: [:create]

resources :projects do
  resources :canned_responses, :only => [:new, :create]
end

resources :canned_responses do
  collection do
    post :add
  end
end

resources :helpdesk_mail_rules
get '/helpdesk_mail_rules/condition', :to => 'helpdesk_mail_rules#condition', :as => 'helpdesk_mail_rules_condition' # TODO: check it
get '/helpdesk_mail_rules/action', :to => 'helpdesk_mail_rules#action', :as => 'helpdesk_mail_rules_action' # TODO: check it

match "helpdesk_mailer" => "helpdesk_mailer#index",:via => [:get, :post]
match "helpdesk_mailer/get_mail" => "helpdesk_mailer#get_mail", :via => [:get, :post, :put]
match "helpdesk/save_settings" => "helpdesk#save_settings", :via => [:get, :post, :put ]
match "helpdesk/get_mail" => "helpdesk#get_mail", :via => [:get, :post, :put]
match "helpdesk/update_customer_email" => "helpdesk#update_customer_email", :via => [:get], as: 'helpdesk_customer_email_update'
match "helpdesk/delete_spam" => "helpdesk#delete_spam", :via => [:delete]
match "helpdesk/email_note.:format" => "helpdesk#email_note", :via => [:get, :post]
match "helpdesk/create_ticket.:format" => "helpdesk#create_ticket", :via => [:get, :post]
match "helpdesk/show_original" => "helpdesk#show_original", :via => [:get, :post]

get '/helpdesk/reports/:report', :to => 'helpdesk_reports#show', :as => 'helpdesk_reports'
get '/projects/:project_id/helpdesk/reports/:report', :to => 'helpdesk_reports#show', :as => 'project_helpdesk_reports'

match 'helpdesk_widget/widget.:format' => 'helpdesk_widget#widget', :via => [:get], :constraints => { :only_ajax => true }
match 'helpdesk_widget/animation.:format' => 'helpdesk_widget#animation', :via => [:get], :constraints => { :only_ajax => true }
match 'helpdesk_widget/iframe.:format' => 'helpdesk_widget#iframe', :via => [:get], :constraints => { :only_ajax => true }
match 'helpdesk_widget/load_form.:format' => 'helpdesk_widget#load_form', :via => [:get], :constraints => { :only_ajax => true }
match 'helpdesk_widget/load_custom_fields' => 'helpdesk_widget#load_custom_fields', :via => [:get], :constraints => { :only_ajax => true }
match 'helpdesk_widget/avatar/:login' => 'helpdesk_widget#avatar', :via => [:get]
match 'helpdesk_widget/create_ticket' => 'helpdesk_widget#create_ticket', :via => [:post], :constraints => { :only_ajax => true }

get "mail_fetcher/receive_imap" => "mail_fetcher#receive_imap"
get "mail_fetcher/receive_pop3" => "mail_fetcher#receive_pop3"

match 'tickets/:id/:hash' => 'public_tickets#show', :as => :public_ticket, :via => [:get, :post]
match 'tickets/:id/add_comment/:hash' => 'public_tickets#add_comment', :as => :public_ticket_add_comment, :via => [:get, :post]

match 'vote/:id/:hash' => 'helpdesk_votes#show', :via => :get, :as => 'helpdesk_votes_show'
match 'vote/:id/:hash' => 'helpdesk_votes#vote', :via => :post, :as => 'helpdesk_votes_vote'
match 'vote/:id/:vote/:hash' => 'helpdesk_votes#fast_vote', :via => :get, :as => 'helpdesk_votes_fast_vote'

get 'attachments/:id/:ticket_id/:hash/:filename', :to => 'attachments#show', :id => /\d+/, :filename => /.*/, :as => 'hashed_named_attachment'
get 'attachments/download_hashed/:id/:ticket_id/:hash/:filename', :to => 'attachments#download', :id => /\d+/, :filename => /.*/, :as => 'hashed_download_named_attachment'

match 'auto_completes/assignee' => 'auto_completes#assignee', :via => :get, :as => 'auto_complete_assignee'

get 'mlnk/:vid', to: 'helpdesk#message_link', as: 'message_link'
