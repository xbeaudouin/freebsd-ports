
require File.expand_path('../../../liquid/liquid_test_helper', __FILE__)

class IssuesDropTest < ActiveSupport::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles, :time_entries, 
           :journals, :journal_details, :issues, :issue_statuses, :issue_relations, :versions, 
           :trackers, :projects_trackers, :issue_categories, :attachments, :enumerations

  def setup
    @issue = Issue.find(2)
    @liquid_render = LiquidRender.new('issue' => RedmineCrm::Liquid::IssueDrop.new(@issue))
  end

  def test_issue_images_all
    liquid_template = @liquid_render.render('{% for image in issue.images.all %} {{ image.filename }} {% endfor %}')
    @issue.images.each { |image| assert_match image.filename, liquid_template }
  end

  def test_issue_images_size
    assert_equal @issue.images.size.to_s, @liquid_render.render('{{ issue.images.size }}')
  end

  def test_issue_available_statuses
    assert_equal @issue.project.name, @liquid_render.render('{{ issue.project_name }}')
    assert_equal IssueStatus.all.map{|s| [s.id, s.name]}.flatten.join(', '), @liquid_render.render('{{ issue.available_statuses | sort | join: ", "}}')
  end

  def test_issue_total_spent_time_by_date
    attributes = {
      issue: @issue,
      user: @issue.project.members.first.user,
      activity: @issue.project.activities.last,
      hours: 1,
      spent_on: Date.today
    }

    compatible_create_time_entry! attributes
    compatible_create_time_entry! attributes.merge(user: @issue.project.members.last.user, hours: 4.5)

    travel 1.year do
      @issue.init_journal(User.current)
      @issue.status = IssueStatus.last
      @issue.save
      @issue.reload
    end

    assert_equal '527040.0', @liquid_render.render("{{ issue.total_time_in_status['Rejected']}}")
    assert_equal '527040', @liquid_render.render("{{ issue.time_in_status[1]['duration'] }}")
    assert_equal '5.5', @liquid_render.render("{% for spent_date in issue.total_spent_time_by_date %}{{spent_date | last }}{% endfor %}")
  end if Rails::VERSION::STRING >= '4.1.18'

  private

  def compatible_create_time_entry!(attributes)
    if TimeEntry.columns_hash['author_id']
      TimeEntry.create! attributes.merge(author: attributes[:user])
    else
      TimeEntry.create! attributes
    end
  end
end
