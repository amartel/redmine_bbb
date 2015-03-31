RedmineApp::Application.routes.draw do
  match 'bbb', :controller => :bbb, :action => :start
  get 'bbb/:action', :controller => :bbb
end
