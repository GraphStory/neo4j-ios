import UIKit
import Theo

let node = Node(labels: ["Pie"], properties: ["GoodForSundays": true])
let client = try BoltClient(hostname: "localhost", port: 7687, username: "neo4j", password: "<passcode>", encrypted: true)
let connectResult = client.connectSync()
let result = client.createNodeSync(node: node)
