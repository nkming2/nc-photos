Pod::Spec.new do |s|
  s.name             = 'NpIosCore'
  s.version          = '0.1.0'
  s.summary          = 'A short description of NpIosCore.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :type => 'GPLv3' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }

  s.ios.deployment_target = '12.0'

  s.source_files = 'NpIosCore/Classes/**/*'
  
  # s.resource_bundles = {
  #   'NpIosCore' => ['NpIosCore/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Flutter'
  s.dependency 'Logging'
end
