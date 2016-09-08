//
//  ComplexSpec.swift
//  SwiftCheck
//
//  Created by Robert Widmann on 9/2/15.
//  Copyright © 2016 Typelift. All rights reserved.
//

import SwiftCheck
import XCTest

let upper : Gen<Character>= Gen<Character>.fromElementsIn("A"..."Z")
let lower : Gen<Character> = Gen<Character>.fromElementsIn("a"..."z")
let numeric : Gen<Character> = Gen<Character>.fromElementsIn("0"..."9")
let special : Gen<Character> = Gen<Character>.fromElementsOf(["!", "#", "$", "%", "&", "'", "*", "+", "-", "/", "=", "?", "^", "_", "`", "{", "|", "}", "~", "."])
let hexDigits = Gen<Character>.oneOf([
	Gen<Character>.fromElementsIn("A"..."F"),
	numeric,
])

class ComplexSpec : XCTestCase {
	func testEmailAddressProperties() {
		let localEmail = Gen<Character>.oneOf([
			upper,
			lower,
			numeric,
			special,
		]).proliferateNonEmpty.suchThat({ $0[$0.endIndex.predecessor()] != "." }).map(String.init)

		let hostname = Gen<Character>.oneOf([
			lower,
			numeric,
			Gen.pure("-"),
		]).proliferateNonEmpty.map(String.init)

		let tld = lower.proliferateNonEmpty.suchThat({ $0.count > 1 }).map(String.init)

		let emailGen = glue([localEmail, Gen.pure("@"), hostname, Gen.pure("."), tld])

		let args = CheckerArguments(maxTestCaseSize: 10)
		
		property("Generated email addresses contain 1 @", arguments: args) <- forAll(emailGen) { (e : String) in
			return e.characters.filter({ $0 == "@" }).count == 1
		}.once
	}

	func testIPv6Properties() {
		let ipHexDigits = Gen<String>.oneOf([
			hexDigits.proliferateSized(1).map{ String.init($0) + ":" },
			hexDigits.proliferateSized(2).map{ String.init($0) + ":" },
			hexDigits.proliferateSized(3).map{ String.init($0) + ":" },
			hexDigits.proliferateSized(4).map{ String.init($0) + ":" },
		])

		let ipGen = { $0.initial } <^> glue([ipHexDigits, ipHexDigits, ipHexDigits, ipHexDigits])

		property("Generated IPs contain 3 sections") <- forAll(ipGen) { (e : String) in
			return e.characters.filter({ $0 == ":" }).count == 3
		}
	}
}

// MARK: String Conveniences

func glue(parts : [Gen<String>]) -> Gen<String> {
	return sequence(parts).map { $0.reduce("", combine: +) }
}

extension String {
	private var initial : String {
		return self[self.startIndex..<self.endIndex.predecessor()]
	}
}
