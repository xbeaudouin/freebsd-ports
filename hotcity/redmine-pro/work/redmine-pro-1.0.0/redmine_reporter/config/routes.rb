resources :report_templates, except: :index do
  member do
    get :preview
    get :export
  end

  collection do
    get :new_import
    post :import
  end
end

resources :issues_report_templates, only: [:new, :create] do
  collection do
    get :create
    get :autocomplete
    post :attach
    get :preview
  end
end

resources :time_entries_reports, only: [:new, :create] do
  collection do
    get :create
    get :autocomplete
    get :preview
  end
end

resources :issue_mails, only: :new do
  collection do
    post :send_mail
    post :preview
  end
end

get 'reporter_attachment_images/download/:id/:filename', to: 'reporter_attachment_images#download', id: /\d+/, filename: /.*/, as: 'download_reporter_attachment_image'
