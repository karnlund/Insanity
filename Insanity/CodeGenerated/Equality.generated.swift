//  Code Generated by Insanity

import Foundation

extension Enum {
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Enum else { return false }
        if self.cases != rhs.cases { return false }
        if self.rawType != rhs.rawType { return false }

        return super.isEqual(rhs)

    }
}

extension Enum.Case {
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Enum.Case else { return false }
        if self.name != rhs.name { return false }
        if self.rawValue != rhs.rawValue { return false }
        if self.associatedValues != rhs.associatedValues { return false }

        return true

    }
}

extension Enum.Case.AssociatedValue {
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Enum.Case.AssociatedValue else { return false }
        if self.name != rhs.name { return false }
        if self.type != rhs.type { return false }

        return true

    }
}

extension Type {
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Type else { return false }
        if self.isExtension != rhs.isExtension { return false }
        if self.accessLevel != rhs.accessLevel { return false }
        if self.localName != rhs.localName { return false }
        if self.staticVariables != rhs.staticVariables { return false }
        if self.variables != rhs.variables { return false }
        if self.inheritedTypes != rhs.inheritedTypes { return false }
        if self.containedTypes != rhs.containedTypes { return false }
        if self.parentName != rhs.parentName { return false }

        return true

    }
}

extension Variable {
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Variable else { return false }
        if self.name != rhs.name { return false }
        if self.type != rhs.type { return false }
        if self.isComputed != rhs.isComputed { return false }
        if self.isStatic != rhs.isStatic { return false }
        if self.readAccess != rhs.readAccess { return false }
        if self.writeAccess != rhs.writeAccess { return false }

        return true

    }
}