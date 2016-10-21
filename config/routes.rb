# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'reports', :to => 'dchbxreports#index'
get 'reports/sla', :to => 'dchbxreports#sla'
get 'reports/holdup', :to => 'dchbxreports#userHoldUp'
get 'reports/status', :to => 'dchbxreports#status'
#get 'reports/stakeholders', :to => 'dchbxreports#stakeholders'
get 'reports/duedates', :to => 'dchbxreports#duedates'
get 'reports/usersReturnForDef', :to => 'dchbxreports#usersReturnForDef'
get 'reports/velocity', :to => 'dchbxreports#velocity'
