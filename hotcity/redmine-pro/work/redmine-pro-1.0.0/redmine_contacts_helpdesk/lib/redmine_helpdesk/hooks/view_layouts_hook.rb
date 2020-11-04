module RedmineHelpdesk
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_body_bottom, partial: 'common/helpdesk_select2_data'

      def view_layouts_base_html_head(_context = {})
        stylesheet_link_tag(:helpdesk, plugin: 'redmine_contacts_helpdesk')
      end
    end
  end
end
