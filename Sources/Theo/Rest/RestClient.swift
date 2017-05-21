import Foundation
#if os(Linux)
    import Dispatch
#endif

open class RestClient {

    // MARK: Public properties

    open let baseURL: String
    open let username: String?
    open let password: String?

    lazy open var parsingQueue: DispatchQueue = {
        if let underlyingQueue = RestSession.sharedInstance.sessionDelegateQueue.underlyingQueue {
            return underlyingQueue
        } else {
            print("Warning, missing Session's underlying queue, creating one")
            let queue = DispatchQueue(label: TheoParsingQueueName, attributes: DispatchQueue.Attributes.concurrent)
            return queue
        }
    }()



    lazy fileprivate var operationQueue = RestSession.sharedInstance.sessionDelegateQueue

    // MARK: Lazy properties

    lazy fileprivate var credentials: (username: String, password: String)? = {

        guard let username = self.username,
              let password = self.password else {
                return nil
        }

        return (username: username, password: password)
    }()

    // MARK: Constructors

    /// Designated initializer
    ///
    /// An expection will be thrown if the baseURL isn't passed in
    /// - parameter String: baseURL
    /// - parameter String?: user
    /// - parameter String?: pass
    /// - returns: RestClient

    // TODO: Move the user/password to a tuple since you can't have one w/o the other
    required public init(baseURL: String, user: String?, pass: String?) {

        assert(!baseURL.isEmpty, "Base url must be set")

        if let user = user {

            self.username = user

        } else {

            print("Something went wrong initializing username")
            self.username = ""
        }

        if let pass = pass {

            self.password = pass

        } else {

            print("Something went wrong initializing password")
            self.password = ""
        }

        self.baseURL = baseURL
    }

    /// Convenience initializer
    ///
    /// user and pass are nil
    ///
    /// - parameter String: baseURL
    /// - returns: RestClient
    convenience public init(baseURL: String) {
        self.init(baseURL: baseURL, user: nil, pass: nil)
    }

    /// Convenience initializer
    ///
    /// baseURL, user and pass are nil thus throwing an exception
    ///
    /// - parameter String: baseURL
    /// :throws: Exception
    convenience public init() {
        self.init(baseURL: "", user: nil, pass: nil)
    }

    // MARK: Public Methods

    /// Fetches meta information for the Neo4j instance
    ///
    /// - parameter ClientProtocol.TheoMetaDataCompletionBlock?: completionBlock
    /// - returns: Void
    open func metaDescription(_ completionBlock: ClientProtocol.TheoMetaDataCompletionBlock? = nil) -> Void {

        let metaResource = self.baseURL + "/db/data/"
        let metaURL: URL = URL(string: metaResource)!
        let metaRequest:RestRequest = RestRequest(url: metaURL, credentials: self.credentials)

        metaRequest.getResource({data, response in

            if let responseData: Data = data {

                self.parsingQueue.async(execute: {

                    do {

                        let JSON: Any = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments) as Any

                        guard let JSONAsDictionaryAny: [String: Any] = JSON as? [String: Any] else {

                            completionBlock?(nil, self.unknownEmptyResponseBodyError(response))
                            return
                        }

                        let meta: DBMeta?
                        do {
                            meta = try DBMeta(JSONAsDictionaryAny as Dictionary<String, Any>!)
                        } catch {
                            meta = nil
                        }

                        completionBlock?(meta, nil)

                    } catch {

                        completionBlock?(nil, self.unknownEmptyResponseBodyError(response))
                    }
                })

            } else {

                completionBlock?(nil, self.unknownEmptyResponseBodyError(response))
            }

       }, errorBlock: {error, response in

            completionBlock?(nil, error)
       })
    }

    /// Fetches node for a given ID
    ///
    /// - parameter String: nodeID
    /// - parameter ClientProtocol.TheoMetaDataCompletionBlock?: completionBlock
    /// - returns: Void
    open func fetchNode(_ nodeID: String, completionBlock: ClientProtocol.TheoNodeRequestCompletionBlock? = nil) -> Void {

        let nodeResource = self.baseURL + "/db/data/node/" + nodeID
        let nodeURL: URL = URL(string: nodeResource)!
        let nodeRequest:RestRequest = RestRequest(url: nodeURL, credentials: self.credentials)

        nodeRequest.getResource({(data, response) in

                if let completionBlock = completionBlock {

                    if let responseData: Data = data {

                        self.parsingQueue.async(execute: {

                            let JSON = try? JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments)
                            let jsonAsDictionary: [String:Any]! = JSON as! [String:Any]
                            let node: Node = Node(data: jsonAsDictionary)

                            completionBlock(node, nil)
                        })

                    } else {

                        completionBlock(nil, self.unknownEmptyResponseBodyError(response))
                    }
                }

            }, errorBlock: {(error, response) in

                if let completionBlock = completionBlock {
                    completionBlock(nil, error)
                }
        })
    }

    /// Saves a new node instance that doesn't have labels
    ///
    /// - parameter Node: node
    /// - parameter ClientProtocol.TheoMetaDataCompletionBlock?: completionBlock
    /// - returns: Void
    open func createNode(_ node: Node, completionBlock: ClientProtocol.TheoNodeRequestCompletionBlock? = nil) -> Void {

        let nodeResource: String = self.baseURL + "/db/data/node"
        let nodeURL: URL = URL(string: nodeResource)!
        let nodeRequest:RestRequest = RestRequest(url: nodeURL, credentials: self.credentials)

        nodeRequest.postResource(node.nodeData as Any, forUpdate: false, successBlock: {(data, response) in

            if let completionBlock = completionBlock {

                if let responseData: Data = data {

                    self.parsingQueue.async(execute: {

                        let JSON: Any? = (try? JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments)) as Any!

                        if let JSONObject: Any = JSON {

                            let jsonAsDictionary: [String:Any] = JSONObject as! [String:Any]
                            let node: Node = Node(data:jsonAsDictionary)

                            completionBlock(node, nil)

                        } else {

                            completionBlock(nil, nil)
                        }
                    })

                } else {

                    completionBlock(nil, self.unknownEmptyResponseBodyError(response))
                }
            }

            }, errorBlock: {(error, response) in

                if let completionBlock = completionBlock {
                    completionBlock(nil, error)
                }
            })
    }

    /// Saves a new node instance with labels
    ///
    /// You have to call this method explicitly or else you'll get a recursion
    /// of the saveNode.
    ///
    /// - parameter Node: node
    /// - parameter Array<String>: labels
    /// - parameter ClientProtocol.TheoMetaDataCompletionBlock?: completionBlock
    /// - returns: Void
    open func createNode(_ node: Node, labels: Array<String>, completionBlock: ClientProtocol.TheoNodeRequestCompletionBlock? = nil) -> Void {

        /// Node creation returns node http://neo4j.com/docs/2.3.2/rest-api-nodes.html#rest-api-create-node
        /// However, creating labels doesn't return anything http://neo4j.com/docs/2.3.2/rest-api-node-labels.html#rest-api-adding-a-label-to-a-node in the response, so in the completion block
        /// we append the labels param values to the returned node

        var createdNodeWithoutLabels: Node?
        let nodeSaveOperationQueue = RestSession.sharedInstance.sessionDelegateQueue

        let createNodeOperation: BlockOperation = BlockOperation(block: {

            self.createNode(node, completionBlock: {(node, error) in

                self.operationQueue.addOperation({

                    if let returnedNode: Node = node {

                        createdNodeWithoutLabels = returnedNode

                        if var nodeWithLabels: Node = createdNodeWithoutLabels {

                            let nodeID: String = "\(returnedNode.id)"
                            let nodeResource: String = self.baseURL + "/db/data/node/" + nodeID + "/labels"
                            let nodeURL: URL = URL(string: nodeResource)!
                            let nodeRequest:RestRequest = RestRequest(url: nodeURL, credentials: self.credentials)

                            nodeRequest.postResource(labels as Any, forUpdate: false,
                                successBlock: {(data, response) in

                                    self.operationQueue.addOperation({

                                        if let completionBlock = completionBlock {

                                            nodeWithLabels.addLabels(labels)

                                            completionBlock(nodeWithLabels, nil)
                                        }
                                    })
                                },
                                errorBlock: {(error, response) in

                                    self.operationQueue.addOperation({

                                        if let completionBlock = completionBlock {
                                            completionBlock(nil, error)
                                        }
                                    })
                            })

                        } else {

                            self.operationQueue.addOperation({

                                // If the labels were sucessfully created then
                                // the response is a 204, BUT the resposne is empty.
                                // If the error block is called then we need
                                // notify the completionBlock

                                let localizedErrorString: String = "There was an error adding labels to the node"
                                let errorDictionary: [String:String] = ["NSLocalizedDescriptionKey" : localizedErrorString, "TheoResponse" : "The expected response is 204 but that is NOT what was received"]
                                let requestResponseError: NSError = {
                                    return NSError(domain: TheoNetworkErrorDomain, code: NSURLErrorUnknown, userInfo: errorDictionary)
                                }()

                                if let completionBlock = completionBlock {
                                    completionBlock(nil, requestResponseError)
                                }
                            })
                        }

                    } else {

                        self.operationQueue.addOperation({

                            if let completionBlock = completionBlock {
                                completionBlock(nil, nil)
                            }
                        })
                    }
                })
            })
        })

        nodeSaveOperationQueue.addOperation(createNodeOperation)
    }

    /// Update a node for a given set of properties
    ///
    /// - parameter Node: node
    /// - parameter Dictionary<String,String>: properties
    /// - parameter ClientProtocol.TheoMetaDataCompletionBlock?: completionBlock
    /// - returns: Void
    open func updateNode(_ node: Node, properties: Dictionary<String,Any>, completionBlock: ClientProtocol.TheoNodeRequestCompletionBlock? = nil) -> Void {

        let nodeID: String = "\(node.id)"
        let nodeResource: String = self.baseURL + "/db/data/node/" + nodeID + "/properties"
        let nodeURL: URL = URL(string: nodeResource)!
        let nodeRequest:RestRequest = RestRequest(url: nodeURL, credentials: self.credentials)

        nodeRequest.postResource(properties as Any, forUpdate: true, successBlock: {(data, response) in

                if let completionBlock = completionBlock {

                    if let responseData: Data = data {

                        self.parsingQueue.async(execute: {

                            let JSON: Any? = (try? JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments)) as Any!

                            if let JSONObject: Any = JSON {

                                let jsonAsDictionary: [String:Any] = JSONObject as! [String:Any]
                                let node: Node = Node(data:jsonAsDictionary)

                                completionBlock(node, nil)

                            } else {

                                completionBlock(nil, nil)
                            }
                        })

                    } else {

                        completionBlock(nil, self.unknownEmptyResponseBodyError(response))
                    }
                }
            },
            errorBlock: {(error, response) in

                if let completionBlock = completionBlock {
                    completionBlock(nil, error)
                }
        })
    }

    //TODO: Need to add in check for relationships

    /// Delete node instance. This will fail if there is a set relationship
    ///
    /// - parameter Node: nodeID
    /// - parameter ClientProtocol.TheoNodeRequestDeleteCompletionBlock?: completionBlock
    /// - returns: Void
    open func deleteNode(_ nodeID: String, completionBlock: ClientProtocol.TheoNodeRequestDeleteCompletionBlock? = nil) -> Void {

        let nodeResource: String = self.baseURL + "/db/data/node/" + nodeID
        let nodeURL: URL = URL(string: nodeResource)!
        let nodeRequest:RestRequest = RestRequest(url: nodeURL, credentials: self.credentials)

        nodeRequest.deleteResource({(data, response) in

                if let completionBlock = completionBlock {

                    if let _: Data = data {
                        completionBlock(nil)
                    }
                }

            }, errorBlock: {(error, response) in

                if let completionBlock = completionBlock {
                    completionBlock(error)
                }
        })
    }

    /// Fetches the relationships for a a node
    ///
    /// - parameter String: nodeID
    /// - parameter String?: direction
    /// - parameter Array<String>?: types
    /// - parameter ClientProtocol.TheoRelationshipRequestCompletionBlock?: completionBlock
    /// - returns: Void
    open func fetchRelationshipsForNode(_ nodeID: String, direction: String? = nil, types: Array<String>? = nil, completionBlock: ClientProtocol.TheoRelationshipRequestCompletionBlock? = nil) -> Void {

        var relationshipResource: String = self.baseURL + "/db/data/node/" + nodeID

        if let relationshipQuery: String = direction {

            relationshipResource += "/relationships/" + relationshipQuery

            if let relationshipTypes: [String] = types {

                if (relationshipTypes.count == 1) {

                    relationshipResource += "/" + relationshipTypes[0]

                } else {

                    for (index, relationship) in relationshipTypes.enumerated() {
                        relationshipResource += index == 0 ? "/" + relationshipTypes[0] : "&" + relationship
                    }
                }
            }

        } else {

            relationshipResource += "/relationships/" + RelationshipDirection.ALL
        }

        let relationshipURL: URL = URL(string: relationshipResource)!

        let relationshipRequest:RestRequest = RestRequest(url: relationshipURL, credentials: self.credentials)

        relationshipRequest.getResource({(data, response) in

                if let completionBlock = completionBlock {

                    var relationshipsForNode: [Relationship] = [Relationship]()

                    self.parsingQueue.async(execute: {

                        let JSON: Any? = (try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)) as Any!
                        let jsonAsArray: [[String:Any]]! = JSON as! [[String:Any]]

                        for relationshipDictionary: [String:Any] in jsonAsArray {
                            let newRelationship = Relationship(data: relationshipDictionary)
                            relationshipsForNode.append(newRelationship)
                        }

                        completionBlock(relationshipsForNode, nil)
                    })
                }

            }, errorBlock: {(error, response) in

                if let completionBlock = completionBlock {
                    completionBlock([Relationship](), error)
                }
            })
    }

    /// Creates a relationship instance
    ///
    /// - parameter Relationship: relationship
    /// - parameter ClientProtocol..TheoNodeRequestRelationshipCompletionBlock?: completionBlock
    /// - returns: Void
    open func createRelationship(_ relationship: Relationship, completionBlock: ClientProtocol.TheoNodeRequestRelationshipCompletionBlock? = nil) -> Void {

        var relationship = relationship
        let fromNode = relationship.fromNode
        let relationshipResource = "\(self.baseURL)/db/data/node/\(fromNode)/relationships"
        let relationshipURL: URL = URL(string: relationshipResource)!
        let relationshipRequest:RestRequest = RestRequest(url: relationshipURL, credentials: self.credentials)

        relationshipRequest.postResource(relationship.relationshipInfo as Any, forUpdate: false,
                                         successBlock: {(data, response) in

                                            if let completionBlock = completionBlock {

                                                if let responseData: Data = data {

                                                    self.parsingQueue.async(execute: {

                                                        let JSON: Any? = (try? JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments)) as Any!
                                                        let jsonAsDictionary: [String:Any]! = JSON as! [String:Any]
                                                        let relationship: Relationship = Relationship(data: jsonAsDictionary)

                                                        completionBlock(relationship, nil)
                                                    })

                                                } else {
                                                    completionBlock(nil, self.unknownEmptyResponseBodyError(response))
                                                }
                                            }

                                         }, errorBlock: {(error, response) in

                                                if let completionBlock = completionBlock {
                                                    completionBlock(nil, error)
                                                }
                                         })
    }

    /// Updates a relationship instance with a set of properties
    ///
    /// - parameter Relationship: relationship
    /// - parameter Dictionary<String,Any>: properties
    /// - parameter ClientProtocol.TheoNodeRequestRelationshipCompletionBlock?: completionBlock
    /// - returns: Void
    open func updateRelationship(_ relationship: Relationship, properties: Dictionary<String,Any>, completionBlock: ClientProtocol.TheoNodeRequestRelationshipCompletionBlock? = nil) -> Void {

        let relationshipResource: String = self.baseURL + "/db/data/relationship/\(relationship.id)/properties"
        let relationshipURL: URL = URL(string: relationshipResource)!
        let relationshipRequest:RestRequest = RestRequest(url: relationshipURL, credentials: self.credentials)

        var relationship = relationship
        relationship.updatingProperties = true

        for (name, value) in properties {
            relationship.setProp(name, propertyValue: value)
        }

        relationshipRequest.postResource(properties as Any, forUpdate: true,
            successBlock: {(data, response) in

                if let completionBlock = completionBlock {

                    // If the update is successfull then you'll
                    // receive a 204 with an empty body
                    completionBlock(nil, nil)
                }

            }, errorBlock: {(error, response) in

                if let completionBlock = completionBlock {
                    completionBlock(nil, error)
                }
        })
    }

    /// Deletes a relationship instance for a given ID
    ///
    /// - parameter String: relationshipID
    /// - parameter ClientProtocol.TheoNodeRequestDeleteCompletionBlock?: completionBlock
    /// - returns: Void
    open func deleteRelationship(_ relationshipID: String, completionBlock: ClientProtocol.TheoNodeRequestDeleteCompletionBlock? = nil) -> Void {

        let relationshipResource = self.baseURL + "/db/data/relationship/" + relationshipID
        let relationshipURL: URL = URL(string: relationshipResource)!
        let relationshipRequest:RestRequest = RestRequest(url: relationshipURL, credentials: self.credentials)

        relationshipRequest.deleteResource({(data, response) in

                                            if let completionBlock = completionBlock {

                                                if let _: Data = data {

                                                    completionBlock(nil)

                                                } else {

                                                    completionBlock(self.unknownEmptyResponseBodyError(response))
                                                }
                                            }

                                           },
                                           errorBlock: {(error, response) in

                                               if let completionBlock = completionBlock {
                                                  completionBlock(error)
                                               }
                                           })
    }

    /// Executes raw Neo4j statements
    ///
    /// - parameter Array<Dictionary<String,: Any>> statements
    /// - parameter ClientProtocol.TheoTransactionCompletionBlock?: completionBlock
    /// - returns: Void
    open func executeTransaction(_ statements: Array<Dictionary<String, Any>>, completionBlock: ClientProtocol.TheoTransactionCompletionBlock? = nil) -> Void {

        let transactionPayload: Dictionary<String, Array<Any>> = ["statements" : statements as Array<Any>]
        let transactionResource = self.baseURL + "/db/data/transaction/commit"
        let transactionURL: URL = URL(string: transactionResource)!
        let transactionRequest:RestRequest = RestRequest(url: transactionURL, credentials: self.credentials)

        transactionRequest.postResource(transactionPayload as Any, forUpdate: false, successBlock: {(data, response) in

            if let completionBlock = completionBlock {

                if let responseData: Data = data {

                    self.parsingQueue.async(execute: {

                        let JSON: Any? = (try? JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments)) as Any!
                        let jsonAsDictionary: [String:Any]! = JSON as! [String:Any]

                        completionBlock(jsonAsDictionary, nil)
                    })

                } else {

                    completionBlock([String:Any](), self.unknownEmptyResponseBodyError(response))
                }
            }

            }, errorBlock: {(error, response) in

                if let completionBlock = completionBlock {
                    completionBlock([String:Any](), error)
                }
        })
    }

    /// Executes a get request for a given endpoint
    ///
    /// - parameter String: uri
    /// - parameter TheoRawRequestCompletionBlock?: completionBlock
    /// - returns: Void
    open func executeRequest(_ uri: String, completionBlock: ClientProtocol.TheoRawRequestCompletionBlock? = nil) -> Void {

        let queryResource: String = self.baseURL + "/db/data" + uri
        let queryURL: URL = URL(string: queryResource)!
        let queryRequest:RestRequest = RestRequest(url: queryURL, credentials: self.credentials)

        queryRequest.getResource({(data, response) in

                    if let completionBlock = completionBlock {

                        if let responseData: Data = data {

                            self.parsingQueue.async(execute: {

                                let JSON: Any? = try! JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments) as Any?

                                completionBlock(JSON, nil)
                            })

                        } else {

                            completionBlock(nil, self.unknownEmptyResponseBodyError(response))
                        }
                    }

                }, errorBlock: {(error, response) in

                    if let completionBlock = completionBlock {
                        completionBlock(nil, error)
                    }
            })
    }

    /// Executes a cypher query
    ///
    /// - parameter String: query
    /// - parameter Dictionary<String,Any>: params
    /// - parameter TheoRawRequestCompletionBlock: completionBlock
    /// - returns: Void
    open func executeCypher(_ query: String, params: Dictionary<String,Any>? = nil, completionBlock: ClientProtocol.TheoCypherQueryCompletionBlock? = nil) -> Void {

        // TODO: need to move this over to use transation http://docs.neo4j.org/chunked/stable/rest-api-cypher.html

        var cypherPayload: Dictionary<String, Any> = ["query" : query]

        if let unwrappedParams: Dictionary<String, Any> = params {
           cypherPayload["params"] = unwrappedParams
        }

        let cypherResource: String = self.baseURL + "/db/data/cypher" //TODO: This is deprecated, please transition to using the transactional HTTP endpoint
        let cypherURL: URL = URL(string: cypherResource)!
        let cypherRequest:RestRequest = RestRequest(url: cypherURL, credentials: self.credentials)

        cypherRequest.postResource(cypherPayload as Any, forUpdate: false, successBlock: {(data, response) in

            if let completionBlock = completionBlock {

                if let responseData: Data = data {

                    self.parsingQueue.async(execute: {

                        let JSON = try? JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.allowFragments)

                        let jsonAsDictionary = JSON as! [String:[Any]]
                        let cypher: Cypher = Cypher(metaData: jsonAsDictionary)

                        completionBlock(cypher, nil)
                    })

                } else {
                    //TRAVIS EDIT: UNNECESSARY?
                    //completionBlock(cypher: nil, error: self.unknownEmptyResponseBodyError(response))
                }
            }

        }, errorBlock: {(error, response) in

                if let completionBlock = completionBlock {
                    completionBlock(nil, error)
                }
        })
    }

    // MARK: Private Methods

    /// Creates NSError object for a given response.
    /// This used when there should be a response body, but there isn't and for
    /// some reason the user gets back a non error code.
    ///
    /// - parameter NSURLResponse: response
    /// - returns: NSError
    fileprivate func unknownEmptyResponseBodyError(_ response: URLResponse) -> NSError {

        let statusCode: Int = {
            let httpResponse: HTTPURLResponse = response as! HTTPURLResponse
            return httpResponse.statusCode
            }()
        let localizedErrorString: String = "The response was empty, but you received at valid response code"
        let errorDictionary: [String:String] = ["NSLocalizedDescriptionKey" : localizedErrorString, "TheoResponseCode" : "\(statusCode)", "TheoResponse" : response.description]

        return NSError(domain: TheoNetworkErrorDomain, code: NSURLErrorBadServerResponse, userInfo: errorDictionary)
    }
}
