Redmine::Plugin.register :redmine_reports do
  name 'Redmine Reports plugin'
  author 'IdeaCrew, Inc'
  description ''
  version '0.0.1'
  url 'https://github.com/dchbx/redmine_reports'
  author_url 'http://ideacrew.com'
  menu :top_menu, :reports, { :controller => 'reports', :action => 'sla' }, :caption => 'Reports'
  settings :default => {
  }, :partial => 'settings/report_settings'
  requires_redmine :version_or_higher => '3.0'
end
