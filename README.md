## Theo
*Thomas Anderson is a computer programmer who maintains a double life as "Neo" the hacker. - Combination of Neo and Thomas*

## Summary

**Theo** is an open-source framework written in Swift that provides an interface for interacting with [Neo4j](http://neo4j.com/).

## Features

* CRUD operations for Nodes and Relationships
* Transaction statement execution
* Supports iOS, tvOS, macOS and Linux

## Requirements

* iOS 10.0 or higher / macOS 10.12 or higher / Ubuntu Linux 14.04 or higher 
* Xcode 9.0 or newer for iOS or macOS
* Swift 4.0

## Feedback

Because this framework is open source it is best for most situations to post on Stack Overflow and tag it **[Theo](http://stackoverflow.com/questions/tagged/theo)**. If you do 
find a bug please file an issue or issue a PR for any features or fixes.

## Installation
You can install Theo in a number of ways

### Swift Package Manager
Add the following line to your Package dependencies array:

```swift
.Package(url: "https://github.com/GraphStory/neo4j-ios.git”, majorVersion: 4, minor: 0)
```
Run `swift build` to build your project, now with Theo included and ready to be used from your source

### CococaPods
Add the following to your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, ‘10.0’
use_frameworks!

target '<Your Target Name>' do
  pod ‘Theo’
end
```
Run `pod install` to configure your updated workspace. Open the .xcworkspace generated, your project is now ready to use Theo

### Carthage
Add the following to your Cartfile:

```ogdl
github "GraphStory/neo4j-ios" ~> 4.0
```
Run `carthage update --platform iOS` to build the framework and drag the built `Theo.framework` into your Xcode project.

### git submodule

  1. Add it as a submodule to your existing project. `git submodule add git@github.com:GraphStory/neo4j-ios.git`
  2. Open the Theo folder, and drag Theo.xcodeproj into the file navigator of your Xcode project.
  3. In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
  4. In the tab bar at the top of that window, open the "Build Phases" panel.
  5. Expand the "Link Binary with Libraries" group, and add Theo.framework.
  6. Click on the + button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add Theo.framework.

## Usage

### Initalization

To get started, you need to set up a BoltClient with the connection information to your Neo4j instance. You could for instance load a JSON into a dictionary, and then pass any values that should overrid the defualts, like this:

```swift
let config = ["password": "<passcode>"]
let client = try BoltClient(JSONClientConfiguration(json: config))
```

Or you can provide your on ClientConfiguration-based class, or even set them all manually:

```swift
let client = try BoltClient(hostname: "localhost",
                                port: 6787,
                            username: "neo4j",
                            password: "<passcode>",
                           encrypted: true)
```


### Create and save a  node

```swift
// Create the node
let node = Node(label: "Character", properties: ["name": "Thomas Anderson", "alias": "Neo" ])

// Save the node
let result = client.createNodeSync(node: node)

// Verify the result of the save
switch result {
case let .failure(error):
  print(error.localizedDescription)
case .success(_):
  print("Node saved successfully")
}
```

createNodeSync() above has an async sibling createNode(), and they in turn have siblings that return the created node: createAndReturnNode() and creaetAndReturnNodeSync(). Finally, multiple nodes can be created at the same time, giving you the functions createNodes(), createNodesSync(), createAndReturnNodes() and createAndReturnNodesSync() to choose between.

### Fetch a node via id

```swift
client.nodeBy(id: 42) { result in
  switch result {
  case let .failure(error):
    print(error.localizedDescription)
  case let .success(foundNode):
    if let foundNode = foundNode {
	  print("Successfully found node \(foundNode)")
    } else {
	  print("There was no node with id 42")
	}
  }
}
```

So finding the node with id 42 is easy, but there is a little routine work in handling that there could be an error with connecting to the database, or there might not be a node with id 42.

Living dangerously and ignoring both error scenarios would look like this:

```swift
client.nodeBy(id: 42) { result in
  let foundNode = result.value!!
  print("Successfully found node \(foundNode)")
}
```

### Fetch nodes matching a labels and property values

```swift
let labels = ["Father", "Husband"]
let properties: [String:PackProtocol] = [
    "firstName": "Niklas",
    "age": 38
]

client.nodesWith(labels: labels, andProperties: properties) { result in
  print("Found \(result.value?.count ?? 0) nodes")
}

```

### Create a relationship

### Create a node

**Without Labels**

```swift
let node = Node()
let randomString: String = NSUUID().UUIDString

node.setProp("propertyKey_1", propertyValue: "propertyValue_1" + randomString)
node.setProp("propertyKey_2", propertyValue: "propertyValue_2" + randomString)

theo.createNode(node, completionBlock: {(node, error) in
    print("new node \(node)")
});
```

**With Labels**

```swift
let node = Node()
let randomString: String = NSUUID().UUIDString

node.setProp("propertyKey_1", propertyValue: "propertyValue_1" + randomString)
node.setProp("propertyKey_2", propertyValue: "propertyValue_2" + randomString)
node.addLabel("customLabelForNode_" + randomString)

theo.createNode(node, completionBlock: {(node, error) in
    print("new node \(node)")
});
```
*or*

```swift
let node = Node()
let randomString: String = NSUUID().UUIDString        

node.setProp("succesfullyAddNodeWithLabel_1", propertyValue: "succesfullyAddNodeWithLabel_1" + randomString)
node.setProp("succesfullyAddNodeWithLabel_2", propertyValue: "succesfullyAddNodeWithLabel_2" + randomString)
node.setProp("succesfullyAddNodeWithLabel_3", propertyValue: 123456)
node.addLabel("test_008_succesfullyAddNodeWithLabel_" + randomString)

theo.createNode(node, labels: node.labels, completionBlock: {(_, error) in
  print("new node \(node)")
})
```
### Update properties for a node

```swift
let updatedPropertiesDictionary: [String:String] = ["test_update_property_label_1": "test_update_property_lable_2"]

theo.updateNode(updateNode!, properties: updatedPropertiesDictionary,
    completionBlock: {(node, error) in
})
```

### Deleting a node

```swift
theo.deleteNode("IDForDeletion", completionBlock: {error in
    print("error \(error?.description)")
})
```

### Create a relationship

```swift
var relationship: Relationship = Relationship()

relationship.relate(parentNodeInstance, toNode: relatedNodeInstance, type: RelationshipType.KNOWS)

// setting properties is optional
relationship.setProp("my_relationship_property_name", propertyValue: "my_relationship_property_value")

theo.createRelationship(relationship, completionBlock: {(node, error) in
    print("meta in success \(node!.meta) node \(node) error \(error)")
})
```

### Delete a relationship

```swift
theo.fetchRelationshipsForNode("nodeIDWithRelationships", direction: RelationshipDirection.ALL, types: nil, completionBlock: {(relationships, error) in

    if let foundRelationship: Relationship = relationships[0] as Relationship! {
        
        if let relMeta: RelationshipMeta = foundRelationship.relationshipMeta {
relationshipIDToDelete = relMeta.relationshipID()
        }
        
        theo.deleteRelationship(relationshipIDToDelete!, completionBlock: {error in

        })
    }
})
```

### Update a relationship

```swift
let updatedProperties: Dictionary<String, AnyObject> = ["updatedRelationshipProperty" : "updatedRelationshipPropertyValue"]

theo.updateRelationship(foundRelationshipInstance, properties: updatedProperties, completionBlock: {(_, error) in

})

```

### Execute a transaction

```swift
let createStatement: String = "CREATE ( bike:Bike { weight: 10 } ) CREATE ( frontWheel:Wheel { spokes: 3 } ) CREATE ( backWheel:Wheel { spokes: 32 } ) CREATE p1 = bike -[:HAS { position: 1 } ]-> frontWheel CREATE p2 = bike -[:HAS { position: 2 } ]-> backWheel RETURN bike, p1, p2"        
let resultDataContents: Array<String> = ["row", "graph"]
let statement: Dictionary <String, AnyObject> = ["statement" : createStatement, "resultDataContents" : resultDataContents]
let statements: Array<Dictionary <String, AnyObject>> = [statement]

theo.executeTransaction(statements, completionBlock: {(response, error) in
    print("response \(response) and error \(error?.description")
})
```

### Execute a cypher query

```swift
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let cyperQuery: String = "MATCH (u:User {username: {user} }) WITH u MATCH (u)-[:FOLLOWS*0..1]->(f) WITH DISTINCT f,u MATCH (f)-[:LASTPOST]-(lp)-[:NEXTPOST*0..3]-(p) RETURN p.contentId as contentId, p.title as title, p.tagstr as tagstr, p.timestamp as timestamp, p.url as url, f.username as username, f=u as owner"
        let cyperParams: Dictionary<String, AnyObject> = ["user" : "ajordan"]

        theo.executeCypher(cyperQuery, params: cyperParams, completionBlock: {(cypher, error) in
println("response from cyper \(cypher)")
        })
```
## Integration Tests

### Setup

There is a file called, `TheoConfig.json.example` which you should copy to `TheoConfig.json`. You can add your `username`, `password` and `baseUrl` to this config and the test classes use these instead of having to modify any *actual* class files. `TheoConfig.json` is in the `.gitignore` so you don't have to worry about creds being committed.

### Execution

* Select the unit test target
* Hit `CMD-U`

## Authors

* [Niklas Saers](http://niklas.sasers.com/) ([@niklassaers](https://twitter.com/niklassaers))
* [Cory Wiles](http://www.corywiles.com/) ([@kwylez](https://twitter.com/kwylez))

