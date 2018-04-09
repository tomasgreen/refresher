Pod::Spec.new do |s|
s.name             = "Refresher"
s.version          = "0.1.0"
s.summary          = "Refresher is a custom UIRefreshControl for UIScrollViews"
s.license          = { :type => 'Private', :file => 'LICENSE' }
s.author           = { "Tomas Green" => "tomas.green@gmail.com" }
s.source           = { :git => "https://github.com/tomasgreen/refresher.git", :tag => s.version,:branch => "master" }
s.homepage         = "https://github.com/tomasgreen/refresher"
s.platform         = :ios, '9.3'
s.requires_arc     = true
s.frameworks       = 'UIKit'
s.source_files     = '**/*.swift', '**/*.xib'
s.resources        = '**/ActivityIndicators.xcassets'
s.module_name      = 'Refresher'
end
