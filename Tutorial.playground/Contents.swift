import Foundation

/*:
 # Theo tutorial
 Welcome to the Theo tutorial. In this playground, we'll go through setting up Theo and how to use it.

 First of all, we need to import Theo:
 */
import Theo
/*:

 Then we need to initialize a client. Theo 4 supports only a single client, and it uses the Bolt protocol to connect to Neo4j. To initialize it, we create an object conforming to ClientConfigurationProtocol. We can instantiate a JSON-based JSONClientConfiguration that takes a JSON object [String:Any] that can override the keys hostname, port, username, password and encrypted.

 ```
 let config = ["password": "<passcode>"]
 let client = try BoltClient(JSONClientConfiguration(json: config))
```

 Alternatively, we can create our own class that overrides the properties we need.

```
 class CustomConfig: ClientConfigurationProtocol {
   var password = "<passcode>"
 }

 let client = try BoltClient(CustomConfig())
```

 Below you can experiment with your configuration:
 */

class CustomConfig: ClientConfigurationProtocol {
    var password = "<passcode>"
}

let client = try BoltClient(CustomConfig())

/*:
 Now we need to set up the connection. We can connect either asynchronously:

 ```
 client.connect() { connectResult in
     switch connectResult {
     case let .failure(error):
         print("Failed to connect with error: \(error.localizedDescription)")
     case let .success(wasSuccessful):
         if wasSuccessful {
             print("Connection established successfully")
         } else {
             print("Error connecting")
         }
     }
 }
 ```

 Or we can connect synchronously:
*/

let connectResult = client.connectSync()
switch connectResult {
case let .failure(error):
    print("Failed to connect with error: \(error.localizedDescription)")
case let .success(wasSuccessful):
    if wasSuccessful {
        print("Connection established successfully")
    } else {
        print("Error connecting")
    }
}

/*:
 Having connected successfully, we can execute our transaction.

 In the transaction below, we'll create an apple pie that contains the apple ingredient. Having created those two nodes, we'll relate the newly created nodes in the *contains* relationship, to which we'll set the "amount" property to 3.

 */

try client.executeAsTransaction { tx in

    let applePie = Node(labels: ["Pie"], properties: ["GoodForSundays": true])
    let apple = Node(labels: ["Fruit"], properties: [:])

    let result = client.createAndReturnNodesSync(nodes: [applePie, apple])
    let theApplePie = result.value![0]
    let theApple = result.value![1]

    client.relateSync(node: theApplePie, to: theApple, name: "contains", properties: ["amount": 3])

    tx.markAsFailed()
}

/*:
 So now that we know transactions, nodes and relationships, lets have a deeper look at nodes.
 */

var apple = Node(labels: ["Fruit"], properties: [:])
apple["pits"] = 4
apple["color"] = "green"
apple["variety"] = "McIntosh"
let createResult = client.createAndReturnNodeSync(node: apple)

/*:
 Sweet, we have a nice API for setting our properties and creating the apple. Notice how we get the created node back from Neo4j as part of the successful createResult. Let's continue with that node, by first updating it.
 */

apple = createResult.value!
apple["juicy"] = true
let updateResult = client.updateNodeSync(node: apple)

/*:
 While the update was a success, by now we're not that interested in apples anymore, so let's get rid of it
 */
let deleteResult = client.deleteNodeSync(node: apple)

/*:
 Until now we have called many functions with sync. All functions can be called both synchronously and asynchronously. We choose the synchronous version here simply because it reads better. In practice, you probably often want to go for the async one.
 
 Also, notice that most methods have both a version that will return the node or relationship in question or not.
 
 Finally, most methods have an option to take multiple of the same kind.
 
 For Create Node, this means that you have the following options:
  - createNode
  - createNodes
  - createNodeSync
  - createNodesSync
  - createAndReturnNode
  - createAndReturnNodes
  - createAndReturnNodeSync
  - createAndReturnNodesSync
 
 In other words, there should be plenty of opportunity for you to express your code in an easy-to-read yet consise way
 */

 /*:
 Now, moving on, let's load a dataset of Belgian beers. Thanks to Rik Van Bruggen for making that example available
 */

let query =
"""
CREATE INDEX ON :BeerBrand(name);
CREATE INDEX ON :Brewery(name);
CREATE INDEX ON :BeerType(name);
CREATE INDEX ON :AlcoholPercentage(value);

LOAD CSV WITH HEADERS FROM "https://docs.google.com/spreadsheets/d/1FwWxlgnOhOtrUELIzLupDFW7euqXfeh8x3BeiEY_sbI/export?format=csv&id=1FwWxlgnOhOtrUELIzLupDFW7euqXfeh8x3BeiEY_sbI&gid=0" AS CSV
WITH CSV AS beercsv
WHERE beercsv.BeerType IS not NULL
MERGE (b:BeerType {name: beercsv.BeerType})
WITH beercsv
WHERE beercsv.BeerBrand IS not NULL
MERGE (b:BeerBrand {name: beercsv.BeerBrand})
WITH beercsv
WHERE beercsv.Brewery IS not NULL
MERGE (b:Brewery {name: beercsv.Brewery})
WITH beercsv
WHERE beercsv.AlcoholPercentage IS not NULL
MERGE (b:AlcoholPercentage {value:
tofloat(replace(replace(beercsv.AlcoholPercentage,'%',''),',','.'))})
WITH beercsv
MATCH (ap:AlcoholPercentage {value:
tofloat(replace(replace(beercsv.AlcoholPercentage,'%',''),',','.'))}),
(br:Brewery {name: beercsv.Brewery}),
(bb:BeerBrand {name: beercsv.BeerBrand}),
(bt:BeerType {name: beercsv.BeerType})
CREATE (bb)-[:HAS_ALCOHOLPERCENTAGE]->(ap),
(bb)-[:IS_A]->(bt),
(bb)<-[:BREWS]-(br);
"""

client.executeCypherSync(query)

