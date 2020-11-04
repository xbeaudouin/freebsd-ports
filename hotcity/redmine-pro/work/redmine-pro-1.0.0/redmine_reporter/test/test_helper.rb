require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def redmine_reporter_fixture_files_path
  "#{Rails.root}/plugins/redmine_reporter/test/fixtures/files/"
end

def compatible_request(type, action, parameters = {})
  Rails.version < '5.1' ? send(type, action, parameters) : send(type, action, params: parameters)
end

def compatible_xhr_request(type, action, parameters = {})
  Rails.version < '5.1' ? xhr(type, action, parameters) : send(type, action, params: parameters, xhr: true)
end

def create_fixtures(fixtures_directory, table_names, class_names = {})
  if ActiveRecord::VERSION::MAJOR >= 4
    ActiveRecord::FixtureSet.create_fixtures(fixtures_directory, table_names, class_names = {})
  else
    ActiveRecord::Fixtures.create_fixtures(fixtures_directory, table_names, class_names = {})
  end
end
