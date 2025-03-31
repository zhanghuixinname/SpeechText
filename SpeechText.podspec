Pod::Spec.new do |s|
  s.name             = 'SpeechText'
  s.version          = '0.1.0'
  s.summary          = 'A lightweight library for speech-to-text and text-to-speech functionality.'  # 有意义的总结
  s.homepage         = 'ssh://github.com/xiaojiuwo/SpeechText'  # 确保 URL 可访问
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'xiaojiuwo' => '294408407@qq.com' }
  s.source           = { :git => 'https://github.com/zhanghuixinname/SpeechText.git', :tag => s.version.to_s }
  s.ios.deployment_target = '12.0'  # 更新部署目标
  s.source_files = 'SpeechTextS/Classes/**/*'
 
  s.dependency 'SocketRocket'
  s.dependency 'AFNetworking'
end