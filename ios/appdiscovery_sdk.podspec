#
# AppDiscovery Flutter SDK, CocoaPods spec.
#
# The native iOS SDK (AppDiscoverySDK.xcframework) is vendored in ios/Frameworks/.
# It is placed there by scripts/fetch_ios_xcframework.sh (checksum pinned) when the
# release is assembled, so a git dependency on the release repository is complete.
#
pubspec = File.read(File.join(__dir__, '..', 'pubspec.yaml'))
plugin_version = pubspec[/^version:\s*(\S+)/, 1] || '0.0.0'

Pod::Spec.new do |s|
  s.name             = 'appdiscovery_sdk'
  s.version          = plugin_version
  s.summary          = 'AppDiscovery offerwall SDK for Flutter (iOS).'
  s.description      = <<-DESC
Flutter plugin that bridges the native AppDiscovery iOS SDK. The offerwall host is a required setting.
                       DESC
  s.homepage         = 'https://github.com/appdiscoverysdk/appdiscovery-flutter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'AppDiscovery SDK' => 'noreply@users.noreply.github.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,m,swift}'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'

  s.vendored_frameworks = 'Frameworks/AppDiscoverySDK.xcframework'
  s.preserve_paths      = 'Frameworks/**/*'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
