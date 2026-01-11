import Foundation

extension String {
    
    var isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + trailing
    }
    
    var nilIfEmpty: String? {
        return isEmpty ? nil : self
    }
    
    var nilIfBlank: String? {
        return isBlank ? nil : self
    }
}
