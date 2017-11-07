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

