import Quick
import Nimble
import SourceKittenFramework
@testable import Insanity

func build(_ source: String) -> [String: SourceKitRepresentable]? {
    return Structure(file: File(contents: source)).dictionary
}

class ParserSpec: QuickSpec {
    override func spec() {
        describe("Parser") {
            var sut: Parser?

            beforeEach {
                sut = Parser()
            }

            afterEach {
                sut = nil
            }

            describe("parseVariable") {
                func parse(_ code: String) -> Variable? {
                    let code = build(code)
                    guard let substructures = code?[SwiftDocKey.substructure.rawValue] as? [SourceKitRepresentable],
                          let src = substructures.first as? [String: SourceKitRepresentable] else {
                        fail()
                        return nil
                    }
                    return sut?.parseVariable(src)
                }

                it("extracts standard property correctly") {
                    expect(parse("var name: String")).to(equal(Variable(name: "name", type: "String", accessLevel: (read: .internal, write: .internal), isComputed: false)))
                }

                it("extracts standard let property correctly") {
                    let r = parse("let name: String")
                    expect(r).to(equal(Variable(name: "name", type: "String", accessLevel: (read: .internal, write: .none), isComputed: false)))
                }

                it("extracts computed property correctly") {
                    expect(parse("var name: Int { return 2 }")).to(equal(Variable(name: "name", type: "Int", accessLevel: (read: .internal, write: .none), isComputed: true)))
                }

                it("extracts generic property correctly") {
                    expect(parse("let name: Observable<Int>")).to(equal(Variable(name: "name", type: "Observable<Int>", accessLevel: (read: .internal, write: .none), isComputed: false)))
                }

                it("extracts property with didSet correctly") {
                    expect(parse(
                            "var name: Int? {\n" +
                                    "didSet { _ = 2 }\n" +
                                    "willSet { _ = 4 }\n" +
                                    "}")).to(equal(Variable(name: "name", type: "Int?", accessLevel: (read: .internal, write: .internal), isComputed: false)))
                }
            }

            describe("parseTypes") {
                func parse(_ code: String, existingTypes: [Type] = []) -> [Type] {
                    let types = sut?.parseContents(code, existingTypes: existingTypes) ?? []
                    return sut?.uniqueTypes(types) ?? []
                }

                context("given struct") {
                    it("extracts properly") {
                        expect(parse("struct Foo { }"))
                                .to(equal([
                                        Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [])
                                ]))
                    }

                    it("extracts instance variables properly") {
                        expect(parse("struct Foo { var x: Int }"))
                                .to(equal([
                                                  Struct(name: "Foo", accessLevel: .internal, isExtension: false, variables: [Variable.init(name: "x", type: "Int", accessLevel: (read: .internal, write: .internal), isComputed: false)])
                                          ]))
                    }

                    it("extracts class variables properly") {
                        expect(parse("struct Foo { static var x: Int { return 2 } }"))
                                .to(equal([
                                                  Struct(name: "Foo", accessLevel: .internal, isExtension: false, staticVariables: [Variable.init(name: "x", type: "Int", accessLevel: (read: .internal, write: .none), isComputed: true, isStatic: true)])
                                          ]))
                    }

                    context("given nested struct") {
                        it("extracts properly") {
                            let innerType = Struct(name: "Bar", accessLevel: .internal, isExtension: false, variables: [])

                            expect(parse("public struct Foo { struct Bar { } }"))
                                    .to(equal([
                                            Struct(name: "Foo", accessLevel: .public, isExtension: false, variables: [], containedTypes: [innerType]),
                                            innerType
                                    ]))
                        }
                    }
                }

                context("given class") {
                    it("extracts extensions properly") {
                        expect(parse("class Foo { }; extension Foo { var x: Int }"))
                                .to(equal([
                                        Type(name: "Foo", accessLevel: .internal, isExtension: false, variables: [Variable.init(name: "x", type: "Int", accessLevel: (read: .internal, write: .internal), isComputed: false)])
                                ]))
                    }

                    it("extracts inherited types properly") {
                        expect(parse("class Foo: TestProtocol { }"))
                                .to(equal([
                                        Type(name: "Foo", accessLevel: .internal, isExtension: false, variables: [], inheritedTypes: ["TestProtocol"])
                                ]))
                    }
                }

                context("given enum") {
                    it("extracts empty enum properly") {
                        expect(parse("enum Foo { }"))
                                .to(equal([
                                        Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [])
                                ]))
                    }

                    it("extracts cases properly") {
                        expect(parse("enum Foo { case optionA; case optionB }"))
                                .to(equal([
                                        Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [Enum.Case(name: "optionA"), Enum.Case(name: "optionB")])
                                ]))
                    }

                    it("extracts variables properly") {
                        expect(parse("enum Foo { var x: Int { return 1 } }"))
                                .to(equal([
                                        Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [], variables: [Variable(name: "x", type: "Int", accessLevel: (.internal, .none), isComputed: true)])
                                ]))
                    }

                    it("extracts cases properly") {
                        expect(parse("enum Foo { case optionA }"))
                                .to(equal([
                                        Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases: [Enum.Case(name: "optionA")])
                                ]))
                    }

                    it("extracts enums with raw type") {
                        expect(parse("enum Foo: String { case optionA }"))
                                .to(equal([
                                                  Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [Enum.Case(name: "optionA")])
                                          ]))
                    }

                    it("extracts enums with raw type and custom values") {
                        expect(parse("enum Foo: String { case optionA = \"Value\" }"))
                                .to(equal([
                                                  Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: ["String"], cases: [Enum.Case(name: "optionA", rawValue: "Value")])
                                          ]))
                    }

                    it("extracts enums with associated types") {
                        expect(parse("enum Foo { case optionA(Observable<Int>); case optionB(named: Float) }"))
                                .to(equal([
                                    Enum(name: "Foo", accessLevel: .internal, isExtension: false, inheritedTypes: [], cases:
                                        [
                                            Enum.Case(name: "optionA", associatedValues: [Enum.Case.AssociatedValue(name: nil, type: "Observable<Int>")]),
                                            Enum.Case(name: "optionB", associatedValues: [Enum.Case.AssociatedValue(name: "named", type: "Float")])
                                        ])
                                ]))
                    }
                }

                context("given protocol") {
                    it("extracts empty protocol properly") {
                        expect(parse("protocol Foo { }"))
                            .to(equal([
                                Protocol(name: "Foo")
                                ]))
                    }
                }

                context("given existing types") {
                    let existingType = Type(name: "Bar", accessLevel: .internal, isExtension: false, variables: [], inheritedTypes: ["TestProtocol"])

                    it("combines properly") {
                        expect(parse("struct Foo { }", existingTypes: [existingType]))
                                .to(equal([existingType, Struct(name: "Foo")]))
                    }
                }
            }
        }
    }
}
