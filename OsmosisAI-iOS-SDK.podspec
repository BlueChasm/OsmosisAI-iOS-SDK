Pod::Spec.new do |s|

  s.name                      = "OsmosisAI-iOS-SDK"
  s.version                   = "0.0.1"
  s.summary                   = "iOS SDK for the OsmosisAI Platform"

  s.description               = <<-DESC
  We need to add a description here that is longer than the summary.
                   DESC

  s.homepage                  = "https://osmosisai.com"
  # s.screenshots             = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license                   = { :type => 'MIT', :file => 'LICENSE' }
  s.author                    = { "OsmosisAI" => "support@osmosisai.com" }
  s.platform                  = :ios, "11.0"
  s.source                    = { :git => "https://github.com/BlueChasm/OsmosisAI-iOS-SDK.git", :tag => "#{s.version}" }
  s.source_files              = 'OsmosisAI/**/*.{swift,mlmodel}'
  s.ios.vendored_frameworks   = 'TesseractOCR.framework'
  s.swift_version             = '4.2'

  s.resources                 = ['OsmosisAI/**/*.{txt,storyboard,sks,xib,xcassets}']
  s.dependency                'Alamofire'
  s.dependency                'AlamofireImage'
  s.dependency                'AlamofireObjectMapper'
  s.dependency                'ISMessages'
  s.dependency                'SDWebImage'
  s.dependency                'SVProgressHUD'
  
end
