Pod::Spec.new do |s|
  s.name             = 'VTextView'
  s.version          = '1.0.0'
  s.summary          = 'Light & Powerful UITextView for TextEditor'

  s.description      = 'Light & Powerful UITextView powred by Vingle.inc'

  s.homepage         = 'https://github.com/Geektree0101/VTextView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Geektree0101' => 'h2s1880@gmail.com' }
  s.source           = { :git => 'https://github.com/Geektree0101/VTextView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'VTextView/Classes/**/*'
  
  s.dependency 'RxSwift', '~> 4.0'
  s.dependency 'RxCocoa', '~> 4.0'
end
