import Foundation


struct BoltConfig {
    let hostname: String
    let port: Int
    let username: String
    let password: String
    let encrypted: Bool

    init(pathToFile: String) {

        do {
            let filePathURL = URL(fileURLWithPath: pathToFile)
            let jsonData = try Data(contentsOf: filePathURL)
            let JSON = try JSONSerialization.jsonObject(with: jsonData, options: [])

            let jsonConfig = JSON as! [String:Any]

            self.username  = jsonConfig["username"] as! String
            self.password  = jsonConfig["password"] as! String
            self.hostname  = jsonConfig["hostname"] as! String
            self.port      = jsonConfig["port"] as! Int
            self.encrypted = jsonConfig["encrypted"] as! Bool

        } catch {

            self.username  = "neo4j"
            self.password  = "neo4j"
            self.hostname  = "localhost"
            self.port      = 7687
            self.encrypted = true

            print("Using default parameters as configuration parsing failed: \(error)")
        }
    }
}
