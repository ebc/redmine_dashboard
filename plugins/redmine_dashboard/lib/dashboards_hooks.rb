module DashboardsPlugin
  module Hooks
    class LayoutHook < Redmine::Hook::ViewListener

      def view_layouts_base_html_head(context={})
        return %{
          
        }
      end
    end
  end
end
