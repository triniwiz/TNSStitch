Pod::Spec.new do |s|

    s.name         = "TNSStitch"

    s.version      = "0.0.1"

    s.summary      = "Mongodb Stitch sdk for objc"

    s.homepage     = "https://github.com/triniwiz/tns-mongo-stitch"


    s.license      = { :type => "MIT", :file => "LICENSE" }


    s.author             = { "Osei Fortune" => "fortune.osei@yahoo.com" }

    s.platform     = :ios, "11.0"

    s.source       = { :git => "https://github.com/triniwiz/fancy-webrtc-ios.git", :tag => "#{s.version}" }

    s.source_files  = "Sources/TNSStitch/*.{swift}"

    s.swift_version = '4.0'

    s.dependency 'StitchSDK' , '~> 5.0'

    s.dependency 'StitchRemoteMongoDBService' , '~> 5.0'

    s.dependency 'StitchLocalMongoDBService' , '~> 5.0'
  end
