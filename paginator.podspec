Pod::Spec.new do |s|
  s.name         = "Paginator"
  s.version      = "1.0.0"
  s.summary      = "It's Paginator."
  s.description  = 'Paginator is a simple and customizable paginator.'
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author       = { "Vaibhav Parmar" => "vaibhav@nickelfox.com" }
  s.platform     = :ios
  s.platform     = :ios, "9.0"
  s.homepage	 = 'https://www.nickelfox.com'
  s.source     = { :git => "https://github.com/vaibhav-nickelfox/Paginator.git", :tag => "#{s.version}" }
  s.source_files = 'Paginator/**/*.{swift}'
  s.requires_arc = true
  
  # s.xcconfig   = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "PullToRefresh", :git => "git@github.com:vaibhav-nickelfox/SSPullToRefresh.git", :branch => "swift", :tag => "2.0.1"
  
  s.dependency "SSPullToRefresh", '~> 1.3' 

end
