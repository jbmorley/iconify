// Copyright (c) 2022-2023 InSeven Limited
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Combine
import SwiftUI

enum SymbolIdentifier: String, Codable {
    case sfSymbols = "sf-symbols"
    case materialDesign = "material-design"
    case emoji = "emoji"
}

extension SymbolIdentifier {

    var name: String {
        switch self {
        case .sfSymbols:
            return "SF Symbols"
        case .materialDesign:
            return "Material Design"
        case .emoji:
            return "Emoji"
        }
    }

}

struct Symbol: Identifiable, Equatable, Codable {

    var id: String {
        return "\(set.rawValue)-\(name)"
    }

    let set: SymbolIdentifier
    let name: String

}

protocol Filterable {

    func matches(_ filter: String) -> Bool

}

extension Array where Element: Filterable {

    func filter(_ filter: String) -> [Element] {
        if filter.isEmpty {
            return self
        }
        return self.filter { $0.matches(filter) }
    }

}

extension Symbol: Filterable {

    func matches(_ filter: String) -> Bool {
        return name.localizedCaseInsensitiveContains(filter)
    }

}

class SymbolPickerModel: ObservableObject {

    struct Section: Identifiable {
        let id: SymbolIdentifier
        let symbols: [Symbol]
    }

    @Published var filteredSymbols: [Section] = []
    @Published var filter: String = ""

    var cancellables: Set<AnyCancellable> = []

    @MainActor func start() {
        $filter
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .map { filter in
                return [
                    Section(id: .materialDesign, symbols: MaterialDesign.allSymbols.filter(filter)),
                    Section(id: .sfSymbols, symbols: SFSymbols.allSymbols.filter(filter)),
                ].filter { !$0.symbols.isEmpty }
            }
            .receive(on: DispatchQueue.main)
            .sink { filteredSymbols in
                self.filteredSymbols = filteredSymbols
            }
            .store(in: &cancellables)
    }

    @MainActor func stop() {
        cancellables.removeAll()
    }

}
