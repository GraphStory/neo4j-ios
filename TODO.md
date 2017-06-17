Changes for 3.2
===============
Remove long-running tests
Mark HTTP client as will be deprecated in 4.0

Make use of Result type instead of all that "throws"
Try to reduce instances of PackStream and Bolt-swift leaking into the class using Theo
 - although it should only depend on Theo, proper Query, Relationship etc will come with 4.0 through Codable
