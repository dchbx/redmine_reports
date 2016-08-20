Redmine::Plugin.register :redmine_sla_dashboard do
  name 'Redmine Reports plugin'
  author 'IdeaCrew, Inc'
  description 'Do you have any issues that are outside your SLA windows? Do you have any close to being outside your SLA?'
  version '0.0.1'
  url 'https://github.com/dchbx/redmine_report'
  author_url 'http://ideacrew.com'
  menu :top_menu, :reports, { :controller => 'home', :action => 'index' }, :caption => 'Reports'
  settings :default => {
    :SLAs => [
      {
        :type => "tracker",
        :name => "Hot Fix",
        :secToComplete => 2*24*60*60
      },
      {
        :type => "priority",
        :name => "Immediate",
        :secToComplete => 2*24*60*60
      },
      {
        :type => "priority",
        :name => "Urgent",
        :secToComplete => 5*24*60*60,
      },
      {
        :type => "priority",
        :name => "High",
        :secToComplete => 10*24*60*60,
      },
    }
  }, :partial => 'settings/report_settings'
  requires_redmine :version_or_higher => '3.0'
end
