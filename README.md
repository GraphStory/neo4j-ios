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

So, finding the node with id 42 is easy, but there is a little routine work in handling that there could be an error with connecting to the database, or there might not be a node with id 42.

Living dangerously and ignoring both error scenarios would look like this:

```swift
client.nodeBy(id: 42) { result in
  let foundNode = result.value!!
  print("Successfully found node \(foundNode)")
}
```

### Updating a node
Given the variable 'node' with an existing node, we might want to update it. Let's add a label:

```swift
node.add(label: "AnotherLabel")
```

or add a few properties:
```swift
node["age"] = 42
node["color"] = "white"
```

and then


```swift
let result = client.updateNodeSync(node: node)
switch result {
case let .failure(error):
  print(error.localizedDescription)
case .success(_):
  print("Node updated successfully")
}
```

### Deleting a node

Likewise, given the variable 'node' with an existing node, when we no longer want the data,
we might want to delete it all together:

```swift
let result = client.deleteNodeSync(node: node)
switch result {
case let .failure(error):
  print(error.localizedDescription)
case .success(_):
  print("Node deleted successfully")
}
```

Note that in Neo4j, to delete a node all relationships this node participates in should be deleted first. However, you can force a delete by calling "DETACH DELETE", and it will then remove all the relationships the node participates in as well. Since this is an exception to the rule, there is no helper function for this. But with Theo, running an arbitrary Cypher statement is easy:

```swift
guard let id = node.id else { return }
let query = """
            MATCH (n) WHERE id(n) = {id} DETACH DELETE n
            """
if client.executeCypherSync(query, params: [ "id": Int64(id)] ).isSuccess {
  print("Node deleted successfully")
} else {
  print("Something went wrong while deleting the node")
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
Given two nodes reader and writer, making a relationship named "follows" is easy as

```swift
let result = client.relateSync(node: reader, to: writer, name: "follows")
if result.isSuccess {
  print("Relationship successfully created")
}
```

Again, there is an async version of relateSync() called relate() that takes the same parameters and a callback block with the same result as relateSync returned

You can also make a relationship directly and create that:

```swift
let relationship = Relationship(fromNode: from, toNode: to, name: "Married to")
client.createAndReturnRelationship(relationship: relationship) { result in
  switch result {
  case let .failure(error):
    print(error.localizedDescription)
  case let .success(relationship):
    print("Successfully created relationship \(relationship)")
  }
}
```

Do note that if one or both of the nodes in a relationship have not been created in advance, they will be created together with the relationship

### Updating properties on a relationship

Having fetched a relationship as part of a query, you can now edit properties on that relationship:

```swift
relationship["someKey"] = "someValue"
relationship["otherKey"] = 42
let result = client.updateAndReturnRelationshipSync(relationship: relationship)
switch result {
case let .failure(error):
  print(error.localizedDescription)
case let .success(relationship):
  print("Successfully updated relationship \(relationship)")
}
```

### Deleting a relationship

And finally, you can remove the relationship alltogether:

```swift
let result = client.deleteRelationshipSync(relationship: relationship)
switch result {
case let .failure(error):
  print(error.localizedDescription)
case .success(_):
  print("Successfully deleted the relationship")
}
```

### Execute a transaction
It is easy to make a transaction, and to roll it back if you are not happy with its results. Simply call executeAsTransaction() and pass in a block. This block has a parameter, tx in the example below, where you can invalidate the transaction at any point. If it has not been invalidated, it is considered successful and committed at the end of the transaction block.

```swift
try client.executeAsTransaction() { tx in
  _ = client.executeCypherSync("MATCH (n) SET n.abra = \"kadabra\"")
  _ = client.executeCypherSync("MATCH (n:Person) WHERE n.name = 'Guy' SET n.likeable = true")
  let finalResult = client.executeCypherSync("MATCH (n:Person) WHERE n.name = 'Guy' AND n.abra='kadabra' SET n.starRating = 5")
  if (finalResult.value?.stats.propertiesSetCount ?? 0) == 0 {
	tx.markAsFailed()
  }
}
```

### Execute a cypher query
In the example above, we already executed a few cypher queries. In the following example, we execute a longer cypher example with named parameters, where we'll supply the parameters along side the query:

```swift
let query = """
			MATCH (u:User {username: {user} }) WITH u 
			MATCH (u)-[:FOLLOWS*0..1]->(f) WITH DISTINCT f,u 
			MATCH (f)-[:LASTPOST]-(lp)-[:NEXTPOST*0..3]-(p) 
			RETURN p.contentId as contentId, p.title as title, p.tagstr as tagstr, p.timestamp as timestamp, p.url as url, f.username as username, f=u as owner
			"""
let params: [String:PackProtocol] = ["user": "ajordan"]
let result = client.executeCypherSync(query, params: params)
if result.isSuccess {
  print("Successfully ran query")
} else {
  print("Got an error")
}
```

## Integration Tests

### Setup

There is a file called, `TheoBoltConfig.json.example` which you should copy to `TheoBoltConfig.json`. You can edit this configuration with connection settings to your Neo4j instance, and the test classes using these instead of having to modify any *actual* class files. `TheoBoltConfig.json` is in the `.gitignore` so you don't have to worry about creds being committed.

### Execution

* Select the unit test target
* Hit `CMD-U`

## Authors

* [Niklas Saers](http://niklas.sasers.com/) ([@niklassaers](https://twitter.com/niklassaers))
* [Cory Wiles](http://www.corywiles.com/) ([@kwylez](https://twitter.com/kwylez))

