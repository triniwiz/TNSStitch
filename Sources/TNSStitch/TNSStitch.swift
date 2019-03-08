//
//  TNSStitch.swift
//  TNSStitch
//
//  Created by Osei Fortune on 3/6/19.
//  Copyright © 2019 Osei Fortune. All rights reserved.
//

import Foundation
import StitchCore
import bson
import StitchRemoteMongoDBService
import StitchLocalMongoDBService
import MongoSwift
@objcMembers
@objc(TNSStitch)
public class TNSStitch: NSObject {
    public static func initializeDefaultAppClient(_ id: String) throws -> TNSStitchAppClient {
        let client = try Stitch.initializeDefaultAppClient(withClientAppID: id)
        return TNSStitchAppClient(client: client)
    }
    
    public static func initializeAppClient(id: String) throws -> TNSStitchAppClient  {
        do {
            let client = try Stitch.initializeAppClient(withClientAppID: id)
            return TNSStitchAppClient(client: client)
        } catch {
            throw error
        }
    }
    
    public static func appClient(id: String) -> TNSStitchAppClient? {
        do {
            let client = try Stitch.appClient(forAppID: id)
            return TNSStitchAppClient(client: client)
        } catch {
            return nil
        }
    }
    
    
    public static var defaultAppClient: TNSStitchAppClient? {
        get {
            if (Stitch.defaultAppClient != nil) {
                return TNSStitchAppClient(client: Stitch.defaultAppClient!)
            }
            return nil
        }
    }
    
    public static func hasAppClient(id: String) -> Bool {
        do {
            let _ = try Stitch.appClient(forAppID: id)
            return true
        } catch {
            return false
        }
    }
}


@objcMembers
@objc(TNSStitchAppClient)
public class TNSStitchAppClient: NSObject {
    private var client: StitchAppClient
    public let auth: TNSStitchAuth
    
    public init(client: StitchAppClient) {
        self.client = client
        self.auth = TNSStitchAuth(auth: client.auth)
        super.init()
    }
    
    public func callFunction(_ name: String, args: [String], listener: @escaping (String?, String?) -> Void) {
        client.callFunction(withName: name, withArgs: args) { (result: StitchResult<String>) in
            switch (result) {
            case .success(let success):
                listener(nil, success)
            case .failure(let error):
                listener(error.localizedDescription, nil)
            }
        }
    }
    
    // TODO figure out a better way to do this
    public func getServiceClient(factory: AnyObject, serviceName: String) throws -> AnyObject {
        
        let instance = factory as! TNSNamedServiceClientFactory
        if((factory as? TNSRemoteMongoClient) != nil){
            let c =  try client.serviceClient(fromFactory: remoteMongoClientFactory , withName: serviceName)
            instance.instance = c as AnyObject
            return instance
        }
        return NSNull.init()
    }
    
     // TODO figure out a better way to do this
    public func getServiceClient(factory: AnyObject) throws -> AnyObject {
        let instance = factory as! TNSServiceClientFactory
        if((factory as? TNSLocalMongoClient) != nil){
            let c =  try client.serviceClient(fromFactory: mongoClientFactory)
            instance.instance = c as AnyObject
            return instance
        }
        return NSNull.init()
    }
    
    
    public func close() {
        
    }
}

@objcMembers
@objc(TNSNamedServiceClientFactory)
public class TNSNamedServiceClientFactory: NSObject {
    var instance: AnyObject?
    var nativeFactory: Any?
    
    public override init() {
        
    }
}

@objcMembers
@objc(TNSServiceClientFactory)
public class TNSServiceClientFactory: NSObject {
    var nativeClientFactory: Any?
    var instance: AnyObject?
    
    public override init() {
        
        
    }
}


@objcMembers
@objc(TNSLocalMongoClient)
public class TNSLocalMongoClient: TNSServiceClientFactory {
    
    public static func getfactory() -> AnyObject {
        let client = TNSLocalMongoClient()
        client.nativeClientFactory = mongoClientFactory
        return client as AnyObject
    }
    
    override init() {
    }
    
    public func db(name: String) -> TNSLocalMongoDatabase? {
        do {
            if instance == nil {
                return nil
            }
            let client = self.instance as! MongoClient
            return TNSLocalMongoDatabase(instance: try client.db(name))
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
}


@objcMembers
@objc(TNSLocalMongoDatabase)
public class TNSLocalMongoDatabase: NSObject {
    var instance: MongoDatabase
    
    init(instance: MongoDatabase) {
        self.instance = instance
    }
    
    public var name:String {
        get{
            return self.instance.name
        }
    }
    
    public func collection(name: String) -> TNSLocalMongoCollection? {
        do {
            return TNSLocalMongoCollection(instance: try self.instance.collection(name))
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}


@objcMembers
@objc(TNSLocalCountOptions)
public class TNSLocalCountOptions: NSObject {
    let instance: CountOptions
    
    public init(limit: Int64) {
        self.instance = CountOptions(collation: nil, hint: nil, limit:limit ,maxTimeMS: nil, readConcern: nil, readPreference: nil, skip: nil)
    }
    
    public var limit: Int64?{
        get{
            return self.instance.limit
        }
    }
}


@objcMembers
@objc(TNSLocalFindOptions)
public class TNSLocalFindOptions: NSObject {
    let instance: FindOptions
    private let _projection: NSDictionary?
    private let _sort: NSDictionary?
    
    public init(limit: AnyObject, projection: NSDictionary?, sort: NSDictionary?) {
        self._projection = projection
        self._sort = sort
        var p: Document? = nil
        var s: Document? = nil
        if(projection != nil){
            p = []
            let keys = projection!.allKeys
            for key in keys{
                p![key as! String] = projection!.value(forKey: key as! String) as? BSONValue
            }
        }
        
        if(sort != nil){
            s = []
            let keys = sort!.allKeys
            for key in keys{
                s![key as! String] = sort!.value(forKey: key as! String) as? BSONValue
            }
        }
        
        self.instance = FindOptions(allowPartialResults: nil, batchSize: nil, collation: nil, comment: nil, cursorType: nil, hint: nil, limit: limit as? Int64, max: nil, maxAwaitTimeMS: nil, maxScan: nil, maxTimeMS: nil, min: nil, noCursorTimeout: nil, projection: p, readConcern: nil, readPreference: nil, returnKey: nil, showRecordId: nil, skip: nil, sort: s)
    }
    
    public var limit: AnyObject {
        get{
            return self.instance.limit as AnyObject
        }
    }
    
    public var projection: NSDictionary? {
        get {
            return self._projection
        }
    }
    
    public var sort: NSDictionary? {
        get {
            return self._sort
        }
    }
}

@objcMembers
@objc(TNSLocalMongoCollection)
public class TNSLocalMongoCollection: NSObject {
    private var instance: MongoCollection<Document>
    public init(instance: MongoCollection<Document>){
        self.instance = instance
    }
    
    public var namespace:String {
        get{
            return self.instance.name
        }
    }
    
    @objc public func count(filter: String, options: TNSLocalCountOptions?) -> AnyObject{
        do {
            let document = try Document(fromJSON: filter)
            return try self.instance.count(document, options: options?.instance) as AnyObject
        } catch  {
            return NSNull.init()
        }
    }
    
    public func find(filter: String? ,
                     options: TNSLocalFindOptions?) -> TNSLocalMongoReadOperation? {
        var document = Document()
        do {
            if filter != nil {
                document = try Document(fromJSON: filter!)
            }
            
            return TNSLocalMongoReadOperation(instance: try self.instance.find(document, options: options?.instance))
        } catch  {
            print(error.localizedDescription)
            return nil
        }
        
    }
    
    public func findOne(
        filter: String?,
        options: TNSLocalFindOptions?) -> String? {
        do {
            var document = Document()
            if filter != nil {
                document = try Document(fromJSON: filter!)
            }
            let cursor = try self.instance.find(document, options: options?.instance)
            let first = cursor.next()
            if first != nil{
                return first!.canonicalExtendedJSON
            }
            return nil
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func aggregate(pipeline: [String]) -> TNSLocalMongoReadOperation? {
        var documents: [Document] = []
        do {
            for line in pipeline {
                documents.append(try Document(fromJSON: line))
            }
            return TNSLocalMongoReadOperation(instance: try self.instance.aggregate(documents))
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
    public func insertOne(document: String) -> TNSRemoteInsertOneResult? {
        do {
            let doc = try Document(fromJSON: document)
            let result = try self.instance.insertOne(doc)
            if result == nil { return nil}
            return TNSRemoteInsertOneResult(insertedId: result!.insertedId as AnyObject)
        } catch  {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func insertMany(documents: [String]) -> TNSRemoteInsertManyResult? {
        do {
            var docs:[Document] = []
            
            for doc in documents {
                let bsonDoc = try Document(fromJSON: doc)
                docs.append(bsonDoc)
            }
            let result = try self.instance.insertMany(docs)
            if result == nil { return nil}
            var insertedIds: [AnyObject] = []
            for value in result!.insertedIds {
                insertedIds.append(value.value as AnyObject)
            }
            return TNSRemoteInsertManyResult(insertedIds: insertedIds)
        } catch  {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func deleteOne(filter: String) -> TNSRemoteDeleteResult?{
        do {
            let document = try Document(fromJSON: filter)
            let result = try self.instance.deleteOne(document)
            if result == nil { return nil}
            return TNSRemoteDeleteResult(deletedCount: result!.deletedCount)
        } catch  {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func deleteMany(filter: String) -> TNSRemoteDeleteResult?{
        do {
            let document = try Document(fromJSON: filter)
            let result = try self.instance.deleteMany(document)
            if result == nil { return nil}
            return TNSRemoteDeleteResult(deletedCount: result!.deletedCount)
        } catch  {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func updateOne(
        filter: String,
        update: String,
        updateOptions: TNSRemoteUpdateOptions?) -> TNSRemoteUpdateResult?{
        
        do {
            let filter_document = try Document(fromJSON: filter)
            let update_document = try Document(fromJSON: update)
            let success = try self.instance.updateOne(filter: filter_document, update: update_document)
            if success == nil { return nil}
            let update_result = TNSRemoteUpdateResult()
            update_result.matchedCount = success!.matchedCount
            update_result.modifiedCount = success!.modifiedCount
            update_result.upsertedId = success!.upsertedId as AnyObject
            return update_result
        } catch  {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func updateMany(
        filter: String,
        update: String,
        updateOptions: TNSRemoteUpdateOptions?) -> TNSRemoteUpdateResult?{
        do {
            let filter_document = try Document(fromJSON: filter)
            let update_document = try Document(fromJSON: update)
            let success = try self.instance.updateMany(filter: filter_document, update: update_document)
            if success == nil { return nil}
            let update_result = TNSRemoteUpdateResult()
            update_result.matchedCount = success!.matchedCount
            update_result.modifiedCount = success!.modifiedCount
            update_result.upsertedId = success!.upsertedId as AnyObject
            return update_result
        } catch  {
            print(error.localizedDescription)
            return nil
        }
    }
}



@objcMembers
@objc(TNSLocalUpdateResult)
public class TNSLocalUpdateResult: NSObject {
    public var matchedCount: Int = 0
    public var modifiedCount: Int = 0
    public var upsertedId: AnyObject?
    public override init() {
        
    }
}

@objcMembers
@objc(TNSLocalUpdateOptions)
public class  TNSLocalUpdateOptions: NSObject {
    public var upsert: Bool
    public init(upsert: Bool){
        self.upsert = upsert
    }
}

@objcMembers
@objc(TNSLocalDeleteResult)
public class  TNSLocalDeleteResult: NSObject {
    public let deletedCount: Int
    public init(deletedCount: Int) {
        self.deletedCount = deletedCount
    }
}

@objcMembers
@objc(TNSLocalInsertManyResult)
public class  TNSLocalInsertManyResult: NSObject {
    public let insertedIds: [AnyObject]
    public init(insertedIds: [AnyObject]) {
        self.insertedIds = insertedIds
    }
}

@objcMembers
@objc(TNSLocalInsertOneResult)
public class  TNSLocalInsertOneResult: NSObject {
    public let insertedId: AnyObject
    public init(insertedId: AnyObject) {
        self.insertedId = insertedId
    }
    
}


@objcMembers
@objc( TNSLocalMongoReadOperation)
public class  TNSLocalMongoReadOperation: NSObject {
    private let instance: MongoCursor<Document>
    
    public init(instance: MongoCursor<Document>){
        self.instance = instance
    }
    
    public func first() -> String {
        let first = instance.prefix(0)
        let doc = first.shuffled()
        if doc.first != nil {
            return doc.first?.canonicalExtendedJSON ?? "{}"
        }
        return "{}"
    }
    
    
    public func toArray() -> [String] {
        var array: [String] = []
        instance.forEach { (doc:Document) in
            array.append(doc.canonicalExtendedJSON)
        }
        return array
    }
    
    public func iterator()-> TNSLocalMongoCursor{
        return TNSLocalMongoCursor(instance: self.instance)
    }
}

@objcMembers
@objc(TNSLocalMongoCursor)
public class TNSLocalMongoCursor: NSObject {
    private let instance: MongoCursor<Document>
    public init(instance: MongoCursor<Document>){
        self.instance = instance
    }
    
    public func next() -> String?{
        return self.instance.next()?.canonicalExtendedJSON
    }
    
    public func hasNext()-> Bool{
        // TODO
        if self.instance.error == nil {
            return true
        }
        return false
    }
}



// Local

// Remote



@objcMembers
@objc(TNSRemoteMongoClient)
public class TNSRemoteMongoClient: TNSNamedServiceClientFactory {
    
    public static func getfactory() -> AnyObject {
        let client = TNSRemoteMongoClient()
        client.nativeFactory = remoteMongoClientFactory
        return client as AnyObject
    }
    
    override init() {
    }
    
    public func db(name: String) -> TNSRemoteMongoDatabase? {
        if instance == nil {
            return nil
        }
        let client = self.instance as! RemoteMongoClient
        return TNSRemoteMongoDatabase(instance: client.db(name))
    }
    
}

@objcMembers
@objc(TNSRemoteMongoDatabase)
public class TNSRemoteMongoDatabase: NSObject {
    var instance: RemoteMongoDatabase
    
    init(instance: RemoteMongoDatabase) {
        self.instance = instance
    }
    
    public var name:String {
        get{
            return self.instance.name
        }
    }
    
    public func collection(name: String) -> TNSRemoteMongoCollection{
        return TNSRemoteMongoCollection(instance: self.instance.collection(name))
    }
}

@objcMembers
@objc(TNSRemoteCountOptions)
public class TNSRemoteCountOptions: NSObject {
    let instance: RemoteCountOptions
    
    public init(limit: Int64) {
        self.instance = RemoteCountOptions(limit: limit)
    }
    
    public var limit: Int64?{
        get{
            return self.instance.limit
        }
    }
}


@objcMembers
@objc(TNSRemoteFindOptions)
public class TNSRemoteFindOptions: NSObject {
    let instance: RemoteFindOptions
    private let _projection: NSDictionary?
    private let _sort: NSDictionary?
    
    public init(limit: AnyObject, projection: NSDictionary?, sort: NSDictionary?) {
        self._projection = projection
        self._sort = sort
        var p: Document? = nil
        var s: Document? = nil
        if(projection != nil){
            p = []
            let keys = projection!.allKeys
            for key in keys{
                p![key as! String] = projection!.value(forKey: key as! String) as? BSONValue
            }
        }
        
        if(sort != nil){
            s = []
            let keys = sort!.allKeys
            for key in keys{
                s![key as! String] = sort!.value(forKey: key as! String) as? BSONValue
            }
        }
        
        self.instance = RemoteFindOptions(limit: limit as? Int64, projection: p, sort: s)
    }
    
    public var limit: AnyObject {
        get{
            return self.instance.limit as AnyObject
        }
    }
    
    public var projection: NSDictionary? {
        get {
            return self._projection
        }
    }
    
    public var sort: NSDictionary? {
        get {
            return self._sort
        }
    }
}

@objcMembers
@objc(TNSRemoteMongoCollection)
public class TNSRemoteMongoCollection: NSObject {
    private var instance: RemoteMongoCollection<Document>
    public init(instance: RemoteMongoCollection<Document>){
        self.instance = instance
    }
    
    public var namespace:String {
        get{
            return self.instance.name
        }
    }
    
    @objc public func count(filter: String, options: TNSRemoteCountOptions?, listener : @escaping (String?, AnyObject?) -> Void){
        do {
            let document = try Document(fromJSON: filter)
            self.instance.count(document, options: options?.instance) { (result: StitchResult<Int>) in
                switch(result){
                case .success(let success):
                    listener(nil,success as AnyObject)
                case .failure(let error):
                    listener(error.description,nil)
                }
            }
        } catch  {
            listener(error.localizedDescription,nil)
        }
    }
    
    public func find(filter: String? ,
                     options: TNSRemoteFindOptions?) -> TNSRemoteMongoReadOperation{
        var document = Document()
        do {
            if filter != nil {
                document = try Document(fromJSON: filter!)
            }
        } catch  {
            print(error.localizedDescription)
        }
        return TNSRemoteMongoReadOperation(instance: self.instance.find(document, options: options?.instance))
    }
    
    public func findOne(
        filter: String?,
        options: TNSRemoteFindOptions?,
        listener: @escaping (String?,String?)->Void ) {
        
        do {
            var document = Document()
            if filter != nil {
                document = try Document(fromJSON: filter!)
            }
            let cursor = self.instance.find(document, options: options?.instance)
            cursor.first { (result: StitchResult<Document?>) in
                switch(result){
                case .success(let success):
                    listener(nil,success?.canonicalExtendedJSON ?? "{}")
                case .failure(let error):
                    listener(error.description,nil)
                }
            }
        } catch {
            listener(error.localizedDescription,nil)
        }
    }
    
    
    
    public func aggregate(pipeline: [String]) -> TNSRemoteMongoReadOperation {
        var documents: [Document] = []
        do {
            for line in pipeline {
                documents.append(try Document(fromJSON: line))
            }
        } catch {
            print(error.localizedDescription)
        }
        return TNSRemoteMongoReadOperation(instance: self.instance.aggregate(documents))
    }
    
    
    public func insertOne(document: String, listener: @escaping (String?,TNSRemoteInsertOneResult?)-> Void) {
        
        do {
            let doc = try Document(fromJSON: document)
            
            self.instance.insertOne(doc) { (result: StitchResult<RemoteInsertOneResult>) in
                switch(result){
                case .success(let success):
                    listener(nil,TNSRemoteInsertOneResult(insertedId: success.insertedId as AnyObject))
                case .failure(let error):
                    listener(error.description,nil)
                }
            }
            
        } catch  {
            listener(error.localizedDescription,nil)
        }
    }
    
    public func insertMany(documents: [String], listener: @escaping (String?,TNSRemoteInsertManyResult?)-> Void) {
        do {
            var docs:[Document] = []
            for doc in documents {
                let bsonDoc = try Document(fromJSON: doc)
                docs.append(bsonDoc)
            }
            self.instance.insertMany(docs) { (result: StitchResult<RemoteInsertManyResult>) in
                switch(result){
                case .success(let success):
                    var insertedIds: [AnyObject] = []
                    for value in success.insertedIds {
                        insertedIds.append(value.value as AnyObject)
                    }
                    listener(nil,TNSRemoteInsertManyResult(insertedIds: insertedIds))
                case .failure(let error):
                    listener(error.description,nil)
                }
            }
        } catch  {
            listener(error.localizedDescription,nil)
        }
    }
    
    public func deleteOne(filter: String, listener: @escaping (String?,TNSRemoteDeleteResult?)-> Void ){
        do {
            let document = try Document(fromJSON: filter)
            self.instance.deleteOne(document) { (result: StitchResult<RemoteDeleteResult>) in
                switch(result){
                case .success(let success):
                    listener(nil,TNSRemoteDeleteResult(deletedCount: success.deletedCount))
                case .failure(let error):
                    listener(error.description,nil)
                }
            }
        } catch  {
            listener(error.localizedDescription,nil)
        }
    }
    
    public func deleteMany(filter: String, listener: @escaping (String?,TNSRemoteDeleteResult?)-> Void ){
        do {
            let document = try Document(fromJSON: filter)
            self.instance.deleteMany(document) { (result: StitchResult<RemoteDeleteResult>) in
                switch(result){
                case .success(let success):
                    listener(nil,TNSRemoteDeleteResult(deletedCount: success.deletedCount))
                case .failure(let error):
                    listener(error.description,nil)
                }
            }
        } catch  {
            listener(error.localizedDescription,nil)
        }
    }
    
    public func updateOne(
        filter: String,
        update: String,
        updateOptions: TNSRemoteUpdateOptions?
        , listener: @escaping (String?,TNSRemoteUpdateResult?)-> Void
        ){
        
        do {
            let filter_document = try Document(fromJSON: filter)
            let update_document = try Document(fromJSON: update)
            self.instance.updateOne(filter: filter_document, update: update_document) { (result: StitchResult<RemoteUpdateResult>) in
                switch(result){
                case .success(let success):
                    let update_result = TNSRemoteUpdateResult()
                    update_result.matchedCount = success.matchedCount
                    update_result.modifiedCount = success.modifiedCount
                    update_result.upsertedId = success.upsertedId as AnyObject
                    listener(nil,update_result)
                case .failure(let error):
                    listener(error.description,nil)
                }
            }
        } catch  {
            listener(error.localizedDescription,nil)
        }
    }
    
    public func updateMany(
        filter: String,
        update: String,
        updateOptions: TNSRemoteUpdateOptions
        , listener: @escaping (String?,TNSRemoteUpdateResult?)-> Void
        ){
        do {
            let filter_document = try Document(fromJSON: filter)
            let update_document = try Document(fromJSON: update)
            self.instance.updateMany(filter: filter_document, update: update_document) { (result: StitchResult<RemoteUpdateResult>) in
                switch(result){
                case .success(let success):
                    let update_result = TNSRemoteUpdateResult()
                    update_result.matchedCount = success.matchedCount
                    update_result.modifiedCount = success.modifiedCount
                    update_result.upsertedId = success.upsertedId as AnyObject
                    listener(nil,update_result)
                case .failure(let error):
                    listener(error.description,nil)
                }
            }
        } catch  {
            listener(error.localizedDescription,nil)
        }
    }
}



@objcMembers
@objc(TNSRemoteUpdateResult)
public class TNSRemoteUpdateResult: NSObject {
    public var matchedCount: Int = 0
    public var modifiedCount: Int = 0
    public var upsertedId: AnyObject?
    public override init() {
        
    }
}

@objcMembers
@objc(TNSRemoteUpdateOptions)
public class TNSRemoteUpdateOptions: NSObject {
    public var upsert: Bool
    public init(upsert: Bool){
        self.upsert = upsert
    }
}

@objcMembers
@objc(TNSRemoteDeleteResult)
public class TNSRemoteDeleteResult: NSObject {
    public let deletedCount: Int
    public init(deletedCount: Int) {
        self.deletedCount = deletedCount
    }
}

@objcMembers
@objc(TNSRemoteInsertManyResult)
public class TNSRemoteInsertManyResult: NSObject {
    public let insertedIds: [AnyObject]
    public init(insertedIds: [AnyObject]) {
        self.insertedIds = insertedIds
    }
}

@objcMembers
@objc(TNSRemoteInsertOneResult)
public class TNSRemoteInsertOneResult: NSObject {
    public let insertedId: AnyObject
    public init(insertedId: AnyObject) {
        self.insertedId = insertedId
    }
    
}


@objcMembers
@objc(TNSRemoteMongoReadOperation)
public class TNSRemoteMongoReadOperation: NSObject {
    private let instance: RemoteMongoReadOperation<Document>
    
    public init(instance: RemoteMongoReadOperation<Document>){
        self.instance = instance
    }
    
    public func first(listener: @escaping (String?,String?)-> Void) {
        self.instance.first { (result:StitchResult<Document?>) in
            switch(result){
            case .success(let success):
                listener(nil,success?.canonicalExtendedJSON ?? "{}")
            case .failure(let error):
                listener(error.description,nil)
            }
        }
    }
    
    
    public func toArray(listener: @escaping (String?,[String]?)->Void) {
        self.instance.toArray { (result: StitchResult<[Document]>) in
            switch(result){
            case .success(let success):
                var documents: [String] = []
                for document in success {
                    documents.append(document.canonicalExtendedJSON)
                }
                listener(nil,documents)
            case .failure(let error):
                listener(error.description,nil)
            }
        }
    }
    
    public func iterator(listener: @escaping (String?, TNSRemoteMongoCursor?) -> Void){
        self.instance.iterator { (result:StitchResult<RemoteMongoCursor<Document>>) in
            switch(result){
            case .success(let success):
                listener(nil,TNSRemoteMongoCursor(instance: success))
            case .failure(let error):
                listener(error.description,nil)
            }
        }
    }
}

@objcMembers
@objc(TNSRemoteMongoCursor)
public class TNSRemoteMongoCursor: NSObject {
    private let instance: RemoteMongoCursor<Document>
    public init(instance: RemoteMongoCursor<Document>){
        self.instance = instance
    }
    
    public func next(listener: @escaping (String?,String?)->Void){
        self.instance.next { (result :StitchResult<Document?>) in
            switch(result){
            case .success(let success):
                listener(nil,success?.canonicalExtendedJSON ?? "{}")
            case .failure(let error):
                listener(error.description,nil)
            }
        }
    }
    
    public func hasNext(listener: @escaping (String?, Bool?)->Void){
        // TODO implement onced released
        listener("Not implemented",nil)
    }
}

@objcMembers
@objc(TNSStitchAuth)
public class TNSStitchAuth: NSObject {
    
    private var auth: StitchAuth
    
    public init(auth: StitchAuth) {
        self.auth = auth
        super.init()
    }
    
    public var isLoggedIn: Bool {
        return self.auth.isLoggedIn
    }
    
    public var user: TNSStitchUser? {
        if (auth.currentUser != nil) {
            return TNSStitchUser(instance: auth.currentUser!)
        }
        return nil
    }
    
    public func switchToUserWithId(userId: String, listener: @escaping (String?, TNSStitchUser?) -> Void) {
        // TODO implement when new pod is released
        listener("Not implemented",nil)
    }
    
    public var listUsers: [TNSStitchUser] {
        return []
    }
    
    public func logout(listener: @escaping (String?) -> Void) {
        auth.logout { (result: StitchResult<Void>) in
            switch(result){
            case .success( _):
                listener(nil)
            case .failure(let error):
                listener(error.description)
            }
            
        }
    }
    
    public func logoutUserWithId(userId: String, listener: @escaping (String?) -> Void) {
        // TODO implement when new pod is released
        listener("Not implemented")
    }
    
    public func removeUser(listener: @escaping (String?) -> Void) {
        // TODO implement when new pod is released
        listener("Not implemented")
    }
    
    public func removeUserWithId(userId: String, listener: @escaping (String?) -> Void) {
        // TODO implement when new pod is released
        listener("Not implemented")
    }
    
    
    public func loginWithCredential(credential: TNSStitchCredential, listener: @escaping (String?,TNSStitchUser?)->Void) {
        auth.login(withCredential: credential.instance as! StitchCredential) { (result: StitchResult<StitchUser>) in
            switch(result){
            case .success(let success):
                listener(nil,TNSStitchUser(instance: success))
            case .failure(let error):
                listener(error.description,nil)
            }
        }
    }
    
    public func addAuthListener(listener: () -> Void) {
        // TODO
    }
    
    public func removeAuthListener(listener: () -> Void) {
        // TODO
    }
    
}

@objc public protocol TNSStitchCredential {
    var instance: AnyObject { get }
}


@objcMembers
@objc(TNSAnonymousCredential)
public class TNSAnonymousCredential: NSObject, TNSStitchCredential {
    public var instance: AnyObject
    public override init() {
        instance = AnonymousCredential() as AnyObject
    }
}

@objcMembers
@objc(TNSUserPasswordCredential)
public class TNSUserPasswordCredential: NSObject, TNSStitchCredential {
    public var instance: AnyObject
    
    public init(username: String, password: String) {
        instance = UserPasswordCredential(withUsername: username, withPassword: password) as AnyObject
    }
}

@objcMembers
@objc(TNSGoogleCredential)
public class TNSGoogleCredential: NSObject, TNSStitchCredential {
    public var instance: AnyObject
    
    public init(authCode: String) {
        instance = GoogleCredential(withAuthCode: authCode) as AnyObject
    }
}

@objcMembers
@objc(TNSFacebookCredential)
public class TNSFacebookCredential: NSObject, TNSStitchCredential {
    public var instance: AnyObject
    
    public init(accessToken: String) {
        instance = FacebookCredential(withAccessToken: accessToken) as AnyObject
    }
}


@objcMembers
@objc(TNSServerApiKeyCredential)
public class TNSServerApiKeyCredential: NSObject, TNSStitchCredential {
    public var instance: AnyObject
    
    public init(key: String) {
        instance = ServerAPIKeyCredential(withKey: key) as AnyObject
    }
}


@objcMembers
@objc(TNSUserApiKeyCredential)
public class TNSUserApiKeyCredential: NSObject, TNSStitchCredential {
    public var instance: AnyObject
    
    public init(key: String) {
        instance = UserAPIKeyCredential(withKey: key) as AnyObject
        
    }
}


@objcMembers
@objc(TNSStitchUserIdentity)
public class TNSStitchUserIdentity: NSObject {
    private var instance: StitchUserIdentity
    
    
    public init(instance: StitchUserIdentity) {
        self.instance = instance
    }
    
    public var id: String {
        get{
            return self.instance.id
        }
    }
    
    public var providerType: String {
        get {
            return self.instance.providerType
        }
    }
}

@objcMembers
@objc(TNSStitchUserProfile)
public class TNSStitchUserProfile: NSObject {
    
    private var instance: StitchUserProfile
    
    public init(instance: StitchUserProfile){
        self.instance = instance
    }
    
    
    public var name : String?{
        get{
            return self.instance.name
        }
    }
    
    public var email : String?{
        get{
            return self.instance.email
        }
    }
    
    public var birthday : String?{
        get {
            return self.instance.birthday
        }
    }
    
    public var firstName : String?{
        get{
            return self.instance.firstName
        }
    }
    
    public var gender : String?{
        get{
            return self.instance.gender
        }
    }
    
    
    public var lastName : String?{
        get{
            return self.instance.lastName
        }
    }
    
    
    public var maxAge : String?{
        get{
            return self.instance.maxAge
        }
    }
    
    public var minAge : String?{
        get{
            return self.instance.minAge
        }
    }
    
    public var pictureUrl : String?{
        get{
            return self.instance.pictureURL
        }
    }
    
    
}
/*
 public enum UserType: {
 Normal = 'normal',
 Server = 'server',
 Unknown = 'unknown'
 }
 */

@objcMembers
@objc(TNSStitchUser)
public class TNSStitchUser: NSObject {
    private var instance: StitchUser
    
    public init(instance: StitchUser) {
        self.instance = instance
    }
    
    public var isLoggedIn: Bool {
        get{
            // Use offical getter or method after pod release
            if(self.instance.loggedInProviderType != AnonymousCredential.providerType){
                return true
            }
            return false
        }
    }
    
    public var id : String{
        get{
            return self.instance.id
        }
    }
    
    
    public var identities: [TNSStitchUserIdentity] {
        get {
            var identities: [TNSStitchUserIdentity] = []
            let nativeIdentities = self.instance.identities
            for identity in nativeIdentities {
                identities.append(TNSStitchUserIdentity(instance: identity))
            }
            return identities;
        }
    }
    
    public var profile: TNSStitchUserProfile {
        get {
            return TNSStitchUserProfile(instance: instance.profile)
        }
    }
    
    public var userType : String? {
        get {
            return self.instance.userType
        }
    }
    
    public var lastAuthActivity: Date {
        get{
            // TODO
            print("Not implemented")
            return Date(timeIntervalSinceNow: TimeInterval())
        }
    }
    
    public  var loggedInProviderType : String{
        get {
            return self.instance.loggedInProviderType.rawValue
        }
    }
    
    public var loggedInProviderName : String{
        get {
            return self.instance.loggedInProviderName
        }
    }
    
    public var deviceId : String{
        get {
            // TODO
            //return self.instance.deviceId
            print("Not implemented")
            return ""
        }
    }
    
    public func linkWithCredential(credential: TNSStitchCredential, listener: @escaping (String?, TNSStitchUser?) -> Void) {
        self.instance.link(withCredential: credential.instance as! StitchCredential) { (result: StitchResult<StitchUser>) in
            switch(result){
            case .success(let success):
                listener(nil,TNSStitchUser(instance: success))
            case .failure(let error):
                listener(error.description,nil)
            }
        }
    }
    
}

public protocol StitchAuthListener {
    
    func onAuthEvent(auth: TNSStitchAuth)
    
    /* onUserAdded?(auth: StitchAuth, addedUser: StitchUser);
     
     onUserLinked?(auth: StitchAuth, linkedUser: StitchUser);
     
     onUserLoggedIn?(auth: StitchAuth, loggedInUser: StitchUser);
     
     onUserLoggedOut?(auth: StitchAuth, loggedOutUser: StitchUser);
     
     onActiveUserChanged?(
     auth: StitchAuth,
     currentActiveUser: StitchUser | undefined,
     previousActiveUser: StitchUser | undefined
     );
     
     
     onUserRemoved?(auth: StitchAuth, removedUser: StitchUser);
     
     onListenerRegistered?(auth: StitchAuth);
     */
}
