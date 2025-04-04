Pod::Spec.new do |s|
  s.name             = 'SpeechText'
  s.version          = '0.1.0'
  s.summary          = 'A lightweight library for speech-to-text and text-to-speech functionality.'  # 有意义的总结
  s.homepage         = 'https://github.com/zhanghuixinname/SpeechText'  # 确保 URL 可访问
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiaojiuwo' => '294408407@qq.com' }
  s.source           = { :git => 'https://github.com/zhanghuixinname/SpeechText.git', :tag => s.version.to_s }
 # 添加以下配置
  s.platform     = :ios, "12.0"
 # 新增这部分
  s.user_target_xcconfig = {
    'ARCHS' => 'arm64',
    'VALID_ARCHS' => 'arm64',
    'ONLY_ACTIVE_ARCH' => 'YES',
    'IPHONEOS_DEPLOYMENT_TARGET' => '12.0'
  }
   # 架构设置（关键修改点）
  s.pod_target_xcconfig = {
    'ARCHS[sdk=iphoneos*]' => 'arm64',
    'ARCHS[sdk=iphonesimulator*]' => 'x86_64 arm64',
    'EXCLUDED_ARCHS[sdk=iphoneos*]' => 'armv7 armv7s i386',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'armv7 armv7s',
    'IPHONEOS_DEPLOYMENT_TARGET' => '12.0',
    'SUPPORTS_MACCATALYST' => 'NO',
    'SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD' => 'NO'
  }

  
  s.ios.deployment_target = '12.0'  # 更新部署目标
  s.swift_versions = ['5.0']  # 根据你的实际 Swift 版本填写
s.static_framework = true  # 设置为静态 Framework
  s.source_files = 'SpeechText/Classes/**/*.{swift,h,m}'
  s.public_header_files = 'SpeechText/Classes/STSocketTool.h'  # 明确公开的头文件
s.private_header_files = 'SpeechText/Classes/Internal/**/*.h'
  s.header_mappings_dir = 'SpeechText/Classes'
 

s.pod_target_xcconfig = {
  'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',  # 模拟器不需要 arm64
  'EXCLUDED_ARCHS[sdk=iphoneos*]' => 'armv7 armv7s'   # 真机移除 armv7/armv7s
}
s.user_target_xcconfig = {
  'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
  'EXCLUDED_ARCHS[sdk=iphoneos*]' => 'armv7 armv7s'
}

  s.dependency 'AFNetworking', '~> 4.0'  # 确保使用最新版（支持 iOS 12+）
s.dependency 'SocketRocket', '~> 0.7.0'  # 检查是否有更新版本
end