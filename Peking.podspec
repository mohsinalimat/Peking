Pod::Spec.new do |s|
  s.name             = "Peking"
  s.version          = "1.0.1"
  s.summary          = "An image picker for iOS"
  s.homepage         = "https://github.com/Meniny/Peking"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Elias Abel" => "Meniny@qq.com" }
  s.source           = { :git => "https://github.com/Meniny/Peking.git", :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios, '8.0'
  s.frameworks   = 'Foundation', 'UIKit', 'Photos', 'AVFoundation', 'CoreMotion'
  s.source_files = 'Peking/**/*.swift'
  s.resources    = [
    'Peking/Resources/Assets.xcassets',
    'Peking/Resources/**/*.xib'
  ]
end
