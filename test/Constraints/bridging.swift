// RUN: rm -rf %t  &&  mkdir %t
// RUN: %target-swift-frontend %s -parse -verify

import Foundation

class BridgedClass : NSObject, NSCopying { 
  func copyWithZone(zone: NSZone) -> AnyObject! {
    return self
  }
}

class BridgedClassSub : BridgedClass { }

struct BridgedStruct : Hashable, _BridgedToObjectiveC {
  var hashValue: Int { return 0 }

  static func getObjectiveCType() -> Any.Type {
    return BridgedClass.self
  }

  func bridgeToObjectiveC() -> BridgedClass {
    return BridgedClass()
  }

  static func bridgeFromObjectiveC(x: BridgedClass) -> BridgedStruct {
    return BridgedStruct()
  }
}

func ==(x: BridgedStruct, y: BridgedStruct) -> Bool { return true }

struct NotBridgedStruct : Hashable { 
  var hashValue: Int { return 0 }
}

func ==(x: NotBridgedStruct, y: NotBridgedStruct) -> Bool { return true }

class OtherClass : Hashable { 
  var hashValue: Int { return 0 }
}
func ==(x: OtherClass, y: OtherClass) -> Bool { return true }

// Basic bridging
func bridgeToObjC(s: BridgedStruct) -> BridgedClass {
  return s
}

func bridgeToAnyObject(s: BridgedStruct) -> AnyObject {
  return s
}

func bridgeFromObjC(c: BridgedClass) -> BridgedStruct {
  return c
}

func bridgeFromObjCDerived(s: BridgedClassSub) -> BridgedStruct {
  return s
}

// Array -> NSArray
func arrayToNSArray() {
  var nsa: NSArray

  nsa = [AnyObject]()
  nsa = [BridgedClass]()
  nsa = [OtherClass]()
  nsa = [BridgedStruct]()
  nsa = [NotBridgedStruct]() // expected-error{{NotBridgedStruct' is not bridged to Objective-C}}
}

// NSArray -> Array
func nsArrayToArray(nsa: NSArray) {
  var arr1: [AnyObject] = nsa
  let arr2: [BridgedClass] = nsa // expected-error{{'BridgedClass' is not identical to 'AnyObject'}}
  let arr3: [OtherClass] = nsa  // expected-error{{'OtherClass' is not identical to 'AnyObject'}}
  let arr4: [BridgedStruct] = nsa  // expected-error{{'BridgedStruct' is not identical to 'AnyObject'}}
  let arr5: [NotBridgedStruct] = nsa  // expected-error{{'NotBridgedStruct' is not identical to 'AnyObject'}}

  var arr6: Array = nsa // infers [AnyObject].
  arr6 = arr1
  arr1 = arr6
}

func dictionaryToNSDictionary() {
  // FIXME: These diagnostics are awful.

  var nsd: NSDictionary

  nsd = [NSObject : AnyObject]()
  nsd = [NSObject : BridgedClass]()
  nsd = [NSObject : OtherClass]()
  nsd = [NSObject : BridgedStruct]()
  nsd = [NSObject : NotBridgedStruct]() // expected-error{{'NotBridgedStruct' is not bridged to Objective-C}}

  nsd = [NSObject : BridgedClass?]() // expected-error{{'BridgedClass?' is not bridged to Objective-C}}
  nsd = [NSObject : BridgedStruct?]()  // expected-error{{'BridgedStruct?' is not bridged to Objective-C}}

  nsd = [BridgedClass : AnyObject]()
  nsd = [OtherClass : AnyObject]()
  nsd = [BridgedStruct : AnyObject]()
  nsd = [NotBridgedStruct : AnyObject]()  // expected-error{{'NotBridgedStruct' is not bridged to Objective-C}}

  // <rdar://problem/17134986>
  var bcOpt: BridgedClass?
  nsd = [BridgedStruct() : bcOpt] // expected-error{{cannot convert the expression's type '()' to type 'BridgedStruct'}}
}

