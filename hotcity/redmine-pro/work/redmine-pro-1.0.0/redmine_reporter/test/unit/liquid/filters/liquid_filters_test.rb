require File.expand_path('../../../liquid/liquid_test_helper', __FILE__)

class ReporterLiquidFiltersTest < ActiveSupport::TestCase
  fixtures :projects, :users, :user_preferences, :roles, :members, :member_roles, :time_entries, 
           :journals, :journal_details, :issues, :issue_statuses, :issue_relations, :versions, 
           :trackers, :projects_trackers, :issue_categories, :attachments, :enumerations,
           :custom_fields, :custom_values, :custom_fields_projects, :custom_fields_trackers

  def setup
    @issue = Issue.find(2)
    @issues = Issue.find(1, 2, 3, 5, 7)

    @liquid_render = LiquidRender.new(
      'issue' => RedmineCrm::Liquid::IssueDrop.new(@issue),
      'issues' => RedmineCrm::Liquid::IssuesDrop.new(@issues)
    )
  end

  def test_avg
    assert_equal '2.0', @liquid_render.render("{{ '1,2,3' | split: ',' | avg }}")
  end

  def test_sum
    assert_equal '6.0', @liquid_render.render("{{ '1,2,3' | split: ',' | sum }}")
  end

  def test_max
    assert_equal '6.0', @liquid_render.render("{{ '1,2,3,3,4,5,6,3,4,5' | split: ',' | max }}")
  end

  def test_min
    assert_equal '1.0', @liquid_render.render("{{ '1,2,3,3,4,5,6,3,4,5' | split: ',' | min }}")
  end

  def test_duration
    assert_equal 'about 5 hours', @liquid_render.render("{{ '300' | duration }}")
  end

  def test_median
    assert_equal '3.0', @liquid_render.render("{{ '1,2,6,7,3' | split: ',' | median }}")
    assert_equal '2.5', @liquid_render.render("{{ '1,2,3,4' | split: ',' | median }}")
  end

  def test_where_custom_field_for_text_format
    assert_equal '1, 3', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '125' | map: 'id' | sort | join: ', ' }}")
    assert_equal '2, 5, 7', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '125', '<>' | map: 'id' | sort | join: ', ' }}")
    assert_equal '7', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', 'abc', '>' | map: 'id' }}")
    assert_equal '1, 2, 3, 5', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', 'abc', '<' | map: 'id' | sort | join: ', ' }}")
    assert_equal '1, 3', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '25', 'match' | map: 'id' | sort | join: ', ' }}")

    assert_equal '1, 3', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '125', 'all' | map: 'id' | sort | join: ', ' }}")
    assert_equal '', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '7,5,125', 'all' }}")

    assert_equal '1, 3', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '125', 'any' | map: 'id' | sort | join: ', ' }}")
    assert_equal '1, 3', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '7,5,125', 'any' | map: 'id' | sort | join: ', ' }}")

    assert_equal '2, 5, 7', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '125', 'exclude' | map: 'id' | sort | join: ', ' }}")
    assert_equal '2, 5', @liquid_render.render("{{ issues.all | where_custom_field: 'Searchable field', '125,this is a stringforcustomfield search', 'exclude' | map: 'id' | sort | join: ', ' }}")
  end

  def test_where_custom_field_for_float_format
    assert_equal '5', @liquid_render.render("{{ issues.all | where_custom_field: 'Float field', '-7.6' | map: 'id' }}")
  end

  def test_where_custom_field_for_multi_value_format
    IssueCustomField.find(1).update_attribute(:multiple, true)
    issue = Issue.find(1)
    issue.custom_field_values = { 1 => %w[MySQL Oracle] }
    issue.save!

    issue = Issue.find(7)
    issue.custom_field_values = { 1 => %w[PostgreSQL] }
    issue.save!

    assert_equal '1, 3', @liquid_render.render("{{ issues.all | where_custom_field: 'Database', 'MySQL', 'all' | map: 'id' | sort | join: ', ' }}")
    assert_equal '1', @liquid_render.render("{{ issues.all | where_custom_field: 'Database', 'Oracle', 'all' | map: 'id' }}")
    assert_equal '7', @liquid_render.render("{{ issues.all | where_custom_field: 'Database', 'PostgreSQL', 'all' | map: 'id' }}")
    assert_equal '1', @liquid_render.render("{{ issues.all | where_custom_field: 'Database', 'MySQL,Oracle', 'all' | map: 'id' }}")

    assert_equal '1, 3, 7', @liquid_render.render("{{ issues.all | where_custom_field: 'Database', 'MySQL,PostgreSQL', 'any' | map: 'id' | sort | join: ', ' }}")
    assert_equal '2, 5', @liquid_render.render("{{ issues.all | where_custom_field: 'Database', 'MySQL,PostgreSQL', 'exclude' | map: 'id' | sort | join: ', ' }}")
  end

  def test_where_custom_field_for_user_format
    cf = IssueCustomField.create!(name: 'User', is_for_all: true, tracker_ids: [1,2,3], field_format: 'user')
    CustomValue.create!(custom_field: cf, customized: @issue, value: '2')
    assert_equal '2', @liquid_render.render("{{ issues.all | where_custom_field: 'User', 'John Smith', | map: 'id' }}")
  end

  def test_group_by_custom_field
    # Different versions of Redmine use the default value of a custom field differently
    custom_value = Issue.find(5).custom_field_values.detect { |cfv| cfv.custom_field.name == 'Searchable field' }

    expected_value =
      if custom_value.try(:value)
        [
          '  name: 125 | ids: 1, 3 | size: 2',
          '  name:  | ids: 2 | size: 1',
          '  name: Default string | ids: 5 | size: 1',
          '  name: this is a stringforcustomfield search | ids: 7 | size: 1 <br> '
        ].join(' <br>')
      else
        [
          '  name: 125 | ids: 1, 3 | size: 2',
          '  name:  | ids: 2, 5 | size: 2',
          '  name: this is a stringforcustomfield search | ids: 7 | size: 1 <br> '
        ].join(' <br>')
      end

    assert_equal expected_value, @liquid_render.render(<<-LIQUID.squish)
      {% assign issues_by_custom_field = issues.all | group_by_custom_field: 'Searchable field' %}
      {% for group_item in issues_by_custom_field %}
         name: {{ group_item.name }} |
         ids: {{ group_item.items | map: 'id' | join: ', ' }} |
         size: {{ group_item.size }}
         <br>
      {% endfor %}
    LIQUID
  end
end
