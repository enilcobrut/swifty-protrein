import Foundation

extension String {
    func substring(start: Int, length: Int) -> String {
        guard start >= 0 && length > 0 && start + length <= self.count else {
            return ""
        }
        let startIndex = self.index(self.startIndex, offsetBy: start)
        let endIndex = self.index(startIndex, offsetBy: length)
        return String(self[startIndex..<endIndex])
    }
}
