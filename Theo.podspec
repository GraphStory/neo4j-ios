Pod::Spec.new do |s|
  s.name         = "Theo"
  s.version      = "5.0.0b1"
  s.summary      = "Open Source Neo4j library for iOS"

  s.description  = <<-DESC
    Theo is an open-source framework written in Swift that provides an interface for interacting with Neo4j.

    Features:
    - CRUD operations for Nodes and Relationships
    - Transaction statement execution
    - Bolt support
DESC

  s.homepage     = "https://github.com/Neo4j-Swift/Neo4j-Swift"
  s.license      = { :type => "MIT", :file => "LICENSE" }


  s.authors             = { "Niklas Saers" => "niklas@saers.com",
                            "Cory Wiles" => "corywiles@icloud.com" }

  s.source       = { :git => "https://github.com/Neo4j-Swift/Neo4j-Swift.git", :commit => "34930332aa778a71dc5c9f35ac58d5c9043daedd" }
  #:tag => "#{s.version}" 

  s.source_files  = "Classes", "Sources/**/*.swift"
  
  s.ios.deployment_target = "12.2"
  s.osx.deployment_target = "10.14"
  s.tvos.deployment_target = "12.2"
  
  s.dependency 'BoltProtocol', '~> 5.0'
  s.dependency 'Result', '~> 4.1.0'
end
