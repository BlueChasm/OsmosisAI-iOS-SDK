Pod::Spec.new do |s|

  s.name         = "OsmosisAI-iOS-SDK"
  s.version      = "0.0.1"
  s.summary      = "iOS SDK for the OsmosisAI Platform"

  s.description  = <<-DESC
  We need to add a description here that is longer than the summary.
                   DESC

  s.homepage      = "https://osmosisai.com"
  # s.screenshots = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license       = { :type => 'MIT', :file => 'LICENSE' }
  s.author        = { "OsmosisAI" => "support@osmosisai.com" }
  s.platform      = :ios, "11.0"
  s.source        = { :git => "https://github.com/BlueChasm/OsmosisAI-iOS-SDK.git", :tag => "#{s.version}" }
  s.source_files  = 'OsmosisAI/**/*'
  s.swift_version = '4.0'
  
  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  s.resources = "OsmosisAI/Resources/*.*"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
