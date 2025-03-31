Pod::Spec.new do |s|
  s.name             = 'SpeechText'
  s.version          = '0.1.0'
  s.summary          = 'A lightweight library for speech-to-text and text-to-speech functionality.'  # 有意义的总结
  s.homepage         = 'https://github.com/zhanghuixinname/SpeechText'  # 确保 URL 可访问
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiaojiuwo' => '294408407@qq.com' }
  s.source           = { :git => 'https://github.com/zhanghuixinname/SpeechText.git', :tag => s.version.to_s }

  s.static_framework = true  # 设置为静态 Framework
  s.ios.deployment_target = '12.0'  # 更新部署目标
  s.swift_versions = ['5.0']  # 根据你的实际 Swift 版本填写
  s.source_files = 'SpeechText/Classes/**/*.{swift,h,m}'
  s.public_header_files = 'SpeechText/Classes/STSocketTool.h'  # 明确公开的头文件
 
  s.dependency 'SocketRocket'
  s.dependency 'Alamofire'
end