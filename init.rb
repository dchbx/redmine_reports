Redmine::Plugin.register :redmine_sla_dashboard do
  name 'Redmine Sla Dashboard plugin'
  author 'IdeaCrew, Inc'
  description 'Do you have any issues that are outside your SLA windows? Do you have any close to being outside your SLA?'
  version '0.0.1'
  url 'https://github.com/dchbx/redmine_sla_dashboard'
  author_url 'http://ideacrew.com'
  menu :top_menu, :sla_dashboard, { :controller => 'home', :action => 'index' }, :caption => 'SLA Dash'
  settings :default => {
  }, :partial => 'settings/sla_settings'
  requires_redmine :version_or_higher => '3.0'
end
