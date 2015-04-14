## Theo
*Thomas Anderson is a computer programmer who maintains a double life as "Neo" the hacker. - Combination of Neo and Thomas*

## Summary

**Theo** is an open-source framework written in Swift that provides an interface for interacting with [Neo4j](http://neo4j.com/).

## Features

* CRUD operations for Nodes and Relationships
* Transaction statement execution

## Requirements

* iOS8+
* Xcode 6.3
* Swift 1.2

## Feedback

Because this framework is open source it is best for most situations to post on Stack Overflow and tag it **Theo**. If you do 
find a bug please file an issue or issue a PR for any features or fixes.

## Installation

  1. Add it as a submodule to your existing project. `git submodule add git@github.com:GraphStory/neo4j-ios.git`
  2. Open the Theo folder, and drag Theo.xcodeproj into the file navigator of your Xcode project.
  3. In Xcode, navigate to the target configuration window by clicking on the blue project icon, and selecting the application target under the "Targets" heading in the sidebar.
  4. In the tab bar at the top of that window, open the "Build Phases" panel.
  5. Expand the "Link Binary with Libraries" group, and add Theo.framework.
  6. Click on the + button at the top left of the panel and select "New Copy Files Phase". Rename this new phase to "Copy Frameworks", set the "Destination" to "Frameworks", and add Theo.framework.

## Usage

### Initalization

**Without authentication**

```Swift
let theo: Client = Client(baseURL: "hostname.com")
```

**With authentication**

```Swift
let theo: Client = Client(baseURL: "hostname.com", user: "username", pass: "password")
```

### Fetch meta for a graph

```Swift
theo.metaDescription({(meta, error) in
    println("meta in success \(meta) error \(error)")
})
```

### Fetch a node via id

```Swift
theo.fetchNode("IDToFetch", completionBlock: {(node, error) in    
    println("meta in success \(node!.meta) node \(node) error \(error)")
})
```

### Create a node

**Without Labels**

```Swift
let node = Node()
let randomString: String = NSUUID.UUID().UUIDString

node.setProp("propertyKey_1", propertyValue: "propertyValue_1" + randomString)
node.setProp("propertyKey_2", propertyValue: "propertyValue_2" + randomString)

theo.createNode(node, completionBlock: {(node, error) in
    println("new node \(node)")
});
```

**With Labels**

```Swift
let node = Node()
let randomString: String = NSUUID.UUID().UUIDString

node.setProp("propertyKey_1", propertyValue: "propertyValue_1" + randomString)
node.setProp("propertyKey_2", propertyValue: "propertyValue_2" + randomString)
node.addLabel("customLabelForNode_" + randomString)

theo.createNode(node, completionBlock: {(node, error) in
    println("new node \(node)")
});
```

### Update properties for a node

```Swift
let updatedPropertiesDictionary: [String:String] = ["test_update_property_label_1": "test_update_property_lable_2"]

theo.updateNode(updateNode!, properties: updatedPropertiesDictionary,
    completionBlock: {(node, error) in
})
```

### Deleting a node

```Swift
theo.deleteNode("IDForDeletion", completionBlock: {error in
    println("error \(error?.description)")
})
```

### Create a relationship

```Swift
var relationship: Relationship = Relationship()

relationship.relate(parentNodeInstance, toNode: relatedNodeInstance, type: RelationshipType.KNOWS)

// setting properties is optional
relationship.setProp("my_relationship_property_name", propertyValue: "my_relationship_property_value")

theo.createRelationship(relationship, completionBlock: {(node, error) in
    println("meta in success \(node!.meta) node \(node) error \(error)")
})
```

### Delete a relationship

```Swift
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

```Swift
let updatedProperties: Dictionary<String, AnyObject> = ["updatedRelationshipProperty" : "updatedRelationshipPropertyValue"]

theo.updateRelationship(foundRelationshipInstance, properties: updatedProperties, completionBlock: {(_, error) in

})

```

### Execute a transaction

```Swift
let createStatement: String = "CREATE ( bike:Bike { weight: 10 } ) CREATE ( frontWheel:Wheel { spokes: 3 } ) CREATE ( backWheel:Wheel { spokes: 32 } ) CREATE p1 = bike -[:HAS { position: 1 } ]-> frontWheel CREATE p2 = bike -[:HAS { position: 2 } ]-> backWheel RETURN bike, p1, p2"        
let resultDataContents: Array<String> = ["row", "graph"]
let statement: Dictionary <String, AnyObject> = ["statement" : createStatement, "resultDataContents" : resultDataContents]
let statements: Array<Dictionary <String, AnyObject>> = [statement]

theo.executeTransaction(statements, completionBlock: {(response, error) in
    println("response \(response) and error \(error?.description")
})
```

### Execute a cypher query

```Swift
        let theo: Client = Client(baseURL: configuration.host, user: configuration.username, pass: configuration.password)
        let cyperQuery: String = "MATCH (u:User {username: {user} }) WITH u MATCH (u)-[:FOLLOWS*0..1]->f WITH DISTINCT f,u MATCH f-[:LASTPOST]-lp-[:NEXTPOST*0..3]-p RETURN p.contentId as contentId, p.title as title, p.tagstr as tagstr, p.timestamp as timestamp, p.url as url, f.username as username, f=u as owner"
        let cyperParams: Dictionary<String, AnyObject> = ["user" : "ajordan"]

        theo.executeCypher(cyperQuery, params: cyperParams, completionBlock: {(cypher, error) in
            println("response from cyper \(cypher)")
        })
```
## Unit Tests

### Setup

There is a file called, `TheoConfig.json.example` which you should copy to `TheoConfig.json`. You can add your `username`, `password` and `baseUrl` to this config and the test classes use these instead of having to modify any *actual* class files. `TheoConfig.json` is in the `.gitignore` so you don't have to worry about creds being committed.

### Execution

* Select the unit test target
* Hit `CMD-U`

## Creator

[Cory Wiles](http://www.corywiles.com/) ([@kwylez](https://twitter.com/kwylez))

