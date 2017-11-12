import Foundation

public class JSONClientConfiguration: ClientConfigurationProtocol {

    let json: [String:Any]

    public init(json: [String:Any]) {
        self.json = json
    }

    public var hostname: String {
        get {
            return json["hostname"] as? String ?? "localhost"
        }
    }

    public var port: Int {
        get {
            return json["port"] as? Int ?? 7687
        }
    }

    public var username: String {
        get {
            return json["username"] as? String ?? "neo4j"
        }
    }

    public var password: String {
        get {
            return json["password"] as? String ?? "neo4j"
        }
    }

    public var encrypted: Bool {
        get {
            return json["encrypted"] as? Bool ?? true
        }
    }

}
