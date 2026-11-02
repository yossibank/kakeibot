import Foundation

struct ReceiptLine {
    let text: String
    let kind: Kind
    let date: LocalDate?
    let amount: Amount?
    let quantity: Quantity?

    init(_ text: String) {
        let normalized = Self.normalized(text)
        let date = Self.date(in: normalized)

        self.text = normalized
        self.kind = date == nil ? Self.kind(of: normalized) : .skip
        self.date = date
        self.amount = Self.price(in: normalized) ?? Self.amount(in: normalized)
        self.quantity = Self.quantity(in: normalized)
    }
}

extension ReceiptLine {
    enum Kind: Equatable {
        case heading(isTitle: Bool)
        case code(isReduced: Bool)
        case item(Amount)
        case quantity(Quantity)
        case discount(name: String, amount: Int)
        case subtotal(Int)
        case taxBase(rate: EntryItem.TaxRate, amount: Int)
        case tax(Int, isExclusive: Bool)
        case total(Int)
        case stop
        case text(String)
        case skip
    }

    struct Quantity: Equatable {
        let count: Int
        let unit: Int
        let isUnitFirst: Bool
    }

    struct Amount: Equatable {
        var name: String
        let value: Int
        var count = 1
        var isReduced = false
        var isIncluded = false
    }

    var isHeading: Bool {
        if case .heading = kind {
            return true
        }

        return false
    }

    var isNamed: Bool {
        guard case let .text(text) = kind else {
            return false
        }

        return text.filter(\.isLetter).count >= 2
            && text.firstMatch(of: Self.codePattern) == nil
            && text.firstMatch(of: Self.phonePattern) == nil
    }

    var isStoreLike: Bool {
        isNamed && !Self.addressWords.contains(where: text.contains)
    }

    var isEnd: Bool {
        switch kind {
        case .total, .stop:
            true
        default:
            false
        }
    }

    var isItemLike: Bool {
        switch kind {
        case let .item(amount):
            amount.value > 0
        case .heading(isTitle: false):
            (amount?.value ?? 0) > 0
        default:
            false
        }
    }

    var isDiscountLike: Bool {
        if case .discount = kind {
            return true
        }

        return (amount?.value ?? 0) < 0
    }

    var isReducedCode: Bool {
        kind == .code(isReduced: true)
    }

    static func itemName(_ text: String) -> String {
        var name = text
            .replacing(Self.taxNotePattern, with: "")
            .replacing(Self.leadingMarkPattern, with: "")
            .trimmingCharacters(in: Self.nameTrimmed)

        name = String(name.map { halfwidthKana[$0] ?? $0 })
            .replacing(takeOutPattern, with: "T/O ")

        return name.replacing(#/\s{2,}/#, with: " ")
    }

    static func isNameLike(_ name: String) -> Bool {
        let letters = name.filter(\.isLetter)

        return letters.count >= 2 || letters.contains { !$0.isASCII }
    }

    static func storeName(_ text: String) -> String {
        text
            .replacing(#/[（(]\s*[)）]/#, with: "")
            .replacing(#/\s{2,}/#, with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

private extension ReceiptLine {
    static let titleWords = ["receipt", "レシート", "領収書", "領収証"]
    static let headingWords = ["明細"]
    static let totalWords = ["合計", "お会計", "ご請求", "お支払金額", "お支払い金額", "支払金額", "お買上計", "お買上げ計"]
    static let subtotalWords = ["小計", "お買上高"]
    static let discountWords = ["値引", "割引", "歩引", "クーポン", "優待"]
    static let stopWords = ["お預", "預り", "お釣", "釣銭", "現金", "お支払内訳", "残高", "ポイント"]
    static let itemWords = ["レジ袋"]
    static let addressWords = ["県", "都", "府", "丁目", "番地", "階"]

    static let skipWords = [
        "小計", "消費税", "外税", "内税", "税率", "対象", "クレジット", "点数", "TEL", "電話",
        "領収", "レジ", "No.", "ありがとう", "登録番号", "担当", "通番", "番号", "伝票", "端末"
    ]

    static let amountBlockers: Set<Character> = ["#"]

    static let maxDigits = 7

    static let misreadMarks: Set<Character> = ["0", "6"]

    static let reducedMarks: Set<Character> = ["※", "*", "軽"]

    static let numberJoints: Set<Character> = [":", "-", "/", "."]

    static let nameTrimmed = CharacterSet(charactersIn: "※*").union(.whitespaces)

    static let halfwidth: [Character: Character] = [
        "０": "0", "１": "1", "２": "2", "３": "3", "４": "4",
        "５": "5", "６": "6", "７": "7", "８": "8", "９": "9",
        "，": ",", "￥": "¥", "－": "-", "−": "-", "＊": "*", "×": "x", "✕": "x",
        "＠": "@", "　": " ", "．": ".", "／": "/", "：": ":", "％": "%", "＃": "#"
    ]

    static let halfwidthKana: [Character: Character] = {
        let half = Array("ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ")
        let full = Array("ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン")

        return Dictionary(uniqueKeysWithValues: zip(half, full))
    }()

    static var amountPattern: Regex<(
        Substring,
        sign: Substring?,
        number: Substring,
        mark: Substring
    )> {
        #/
            (?<sign>[-△▲])?\s*¥?\s*(?<number>\d{1,3}(?:,\d{3})+|\d+)\s*円?\s*(?<mark>[※*軽外内非A-Za-z]{0,2})\s*$
        /#
    }

    static var pricePattern: Regex<(
        Substring,
        prefix: Substring?,
        unit: Substring,
        count: Substring?,
        amount: Substring?
    )> {
        #/
            ^(?<prefix>外|内税|内\S?)?\s*¥?(?<unit>\d{1,3}(?:,\d{3})+|\d+)(?:(?:\s+(?<count>\d{1,3})\s*点?)?\s+¥?(?<amount>\d{1,3}(?:,\d{3})+|\d+))?\s*$
        /#
    }

    static var quantityPattern: Regex<(Substring, count: Substring, unit: Substring)> {
        #/
            ^(?<count>\d+)\s*(?:コ|個|点|ｺ)?\s*[xX*]\s*(?:単|@)?\s*¥?\s*(?<unit>\d{1,3}(?:,\d{3})+|\d+)
            (?:\s+¥?\s*(?:\d{1,3}(?:,\d{3})+|\d+)\s*円?)?\s*$
        /#
    }

    static var unitFirstPattern: Regex<(Substring, unit: Substring, count: Substring)> {
        #/
            ^@\s*¥?\s*(?<unit>\d{1,3}(?:,\d{3})+|\d+)\s*[xX*]\s*(?<count>\d+)\s*(?:コ|個|点|ｺ)?
            (?:\s+¥?\s*(?:\d{1,3}(?:,\d{3})+|\d+)\s*円?)?\s*$
        /#
    }

    static var columnsPattern: Regex<(
        Substring,
        name: Substring,
        count: Substring,
        unit: Substring
    )> {
        #/
            ^(?<name>.*?\S)\s+(?<count>\d{1,3})\s*(?:コ|個|点)?\s*[@*x]?\s*¥?\s*(?<unit>\d{1,3}(?:,\d{3})+|\d+)$
        /#
    }

    static var taxBasePattern: Regex<(Substring, rate: Substring, base: Substring)> {
        #/
            (?<rate>10|8)\s*[%8]?\s*(?:対象|課税)[^\d¥]*¥?\s*(?<base>\d{1,3}(?:,\d{3})+|\d+)
        /#
    }

    static var countTokenPattern: Regex<(Substring, Substring)> {
        #/
            ^(\d{1,3})(?:コ|個|点)?$
        /#
    }

    static var takeOutPattern: Regex<Substring> {
        #/
            ^[T1I]/[O0]\s
        /#
    }

    static var codePattern: Regex<Substring> {
        #/
            ^[\#A-Za-z]?\d{3,}(?:-\d+)+|\d{8,}
        /#
    }

    static var serialPattern: Regex<Substring> {
        #/
            ^No\.?\s*\d{4,}
        /#
    }

    static var phonePattern: Regex<Substring> {
        #/
            ^[(（]?0\d{1,4}[)）-]
        /#
    }

    static var taxNotePattern: Regex<Substring> {
        #/
            [（(]\s*(?:内税|外税|税込|税抜|\d+)\s*[)）]
        /#
    }

    static var leadingMarkPattern: Regex<Substring> {
        #/
            ^\s*[A-Z]?[*※]+\s*
        /#
    }

    static var datePattern: Regex<(Substring, year: Substring, month: Substring, day: Substring)> {
        #/
            (?<year>20\d{2})\s*[年/\-.]\s*(?<month>\d{1,2})\s*[月/\-.]\s*(?<day>\d{1,2})
        /#
    }

    static func normalized(_ text: String) -> String {
        let characters = text.map { halfwidth[$0] ?? $0 }

        return String(characters)
            .replacing(#/(\d)\.(\d{3})(?!\d)/#) { "\($0.output.1),\($0.output.2)" }
            .trimmingCharacters(in: .whitespaces)
    }

    static func kind(of text: String) -> Kind {
        let words = text.filter { !$0.isWhitespace }
        let letters = text.lowercased().filter(\.isLetter)

        if let price = price(in: text) {
            return .item(price)
        }

        if letters.isEmpty, let amount = amount(in: text), amount.value < 0 {
            return .discount(name: "", amount: amount.value)
        }

        if letters.isEmpty || titleWords.contains(where: { letters == $0 }) {
            return .heading(isTitle: !letters.isEmpty)
        }

        if headingWords.contains(where: letters.contains), amount(in: text) == nil {
            return .heading(isTitle: false)
        }

        if text.firstMatch(of: serialPattern) != nil {
            return .skip
        }

        if text.firstMatch(of: codePattern) != nil, amount(in: text) == nil {
            return .code(isReduced: text.contains(where: reducedMarks.contains))
        }

        guard words.contains(where: { !$0.isNumber && !numberJoints.contains($0) }) else {
            return .skip
        }

        if let quantity = quantity(in: text) {
            return quantity.unit > 0 ? .quantity(quantity) : .skip
        }

        let amount = amount(in: text)

        if totalWords.contains(where: words.contains), !words.contains("小計"),
           !words.contains("点数") {
            return amount.map { .total($0.value) } ?? .skip
        }

        if subtotalWords.contains(where: words.contains) {
            return amount.map { .subtotal($0.value) } ?? .skip
        }

        if let base = text.firstMatch(of: taxBasePattern),
           let rate = EntryItem.TaxRate(rawValue: Int(base.rate) ?? 0),
           let value = Int(base.base.filter(\.isNumber)) {
            return .taxBase(rate: rate, amount: value)
        }

        if let amount, isTax(words) {
            return .tax(
                amount.value,
                isExclusive: !["内", "うち", "(", "（"].contains(where: words.contains)
            )
        }

        if stopWords.contains(where: words.contains) {
            return .stop
        }

        let bare = itemWords.reduce(text.replacing(taxNotePattern, with: "")) {
            $0.replacing($1, with: "")
        }

        guard !skipWords.contains(where: bare.filter { !$0.isWhitespace }.contains) else {
            return .skip
        }

        guard let amount else {
            return .text(text)
        }

        if discountWords.contains(where: words.contains) || amount.value < 0 {
            return .discount(name: itemName(amount.name), amount: -abs(amount.value))
        }

        guard isNameLike(itemName(amount.name)) else {
            return .skip
        }

        return .item(amount)
    }

    static func isTax(_ words: String) -> Bool {
        words.contains("消費税") || words.contains("税額") || words.contains("外税")
            || (words.contains("外") && words.contains("%"))
    }

    static func price(in text: String) -> Amount? {
        guard
            let match = text.firstMatch(of: pricePattern),
            let unit = Int(match.unit.filter(\.isNumber))
        else {
            return nil
        }

        let total = match.amount.flatMap { Int($0.filter(\.isNumber)) }
        let count = match.count.flatMap { Int($0) } ?? 1

        guard
            match.prefix != nil || total != nil,
            unit > 0
        else {
            return nil
        }

        let value = total ?? unit
        let isCounted = count > 0 && unit * count == value

        guard isCounted || total == nil || unit == value else {
            return nil
        }

        return Amount(
            name: "",
            value: value,
            count: isCounted ? count : 1,
            isIncluded: match.prefix?.hasPrefix("内") ?? false
        )
    }

    static func amount(in text: String) -> Amount? {
        guard let match = text.firstMatch(of: amountPattern) else {
            return nil
        }

        let start = match.sign?.startIndex ?? match.number.startIndex
        let before = start > text.startIndex ? text[text.index(before: start)] : nil
        let digits = match.number.filter(\.isNumber)

        guard
            !(before?.isNumber ?? false),
            !numberJoints.contains(before ?? " "),
            !amountBlockers.contains(before ?? " "),
            !(before.map { $0.isASCII && $0.isLetter } ?? false),
            digits.count <= maxDigits,
            let number = Int(digits)
        else {
            return nil
        }

        let name = text[..<match.range.lowerBound].trimmingCharacters(in: .whitespaces)
        let value = match.sign == nil ? number : -number
        var amount = columns(of: name, value: value) ?? Amount(name: name, value: value)

        amount.isReduced = match.mark.contains(where: reducedMarks.contains)
            || name.firstMatch(of: leadingMarkPattern) != nil

        return amount
    }

    static func columns(
        of name: String,
        value: Int
    ) -> Amount? {
        if let match = name.firstMatch(of: columnsPattern),
           let count = Int(match.count),
           let unit = Int(match.unit.filter(\.isNumber)),
           count > 0,
           count * unit == value {
            return Amount(
                name: String(match.name).trimmingCharacters(in: .whitespaces),
                value: value,
                count: count
            )
        }

        return misreadColumns(of: name, value: value)
    }

    static func misreadColumns(
        of name: String,
        value: Int
    ) -> Amount? {
        var tokens = name.split(separator: " ").map(String.init)

        guard
            value > 0,
            let unitToken = tokens.popLast()
        else {
            return nil
        }

        let countToken = tokens.last.flatMap { token in
            token.firstMatch(of: countTokenPattern).flatMap { Int($0.output.1) }
        }

        let count = countToken ?? 1

        guard
            count > 0,
            value % count == 0,
            unitCandidates(of: unitToken).contains(value / count)
        else {
            return nil
        }

        if countToken != nil {
            tokens.removeLast()
        }

        let rest = tokens.joined(separator: " ")

        guard isNameLike(itemName(rest)) else {
            return nil
        }

        return Amount(name: rest, value: value, count: count)
    }

    static func unitCandidates(of token: String) -> [Int] {
        let digits = String(token.drop { !$0.isNumber }).replacing(",", with: "")

        guard
            digits.allSatisfy(\.isNumber),
            let unit = Int(digits)
        else {
            return []
        }

        let isMisreadMark = digits.count > 1 && misreadMarks.contains(digits.first ?? " ")

        return isMisreadMark ? [unit, Int(digits.dropFirst()) ?? unit] : [unit]
    }

    static func quantity(in text: String) -> Quantity? {
        if let match = text.firstMatch(of: unitFirstPattern),
           let count = Int(match.count),
           let unit = Int(match.unit.filter(\.isNumber)),
           count > 0 {
            return Quantity(count: count, unit: unit, isUnitFirst: true)
        }

        if let match = text.firstMatch(of: quantityPattern),
           let count = Int(match.count),
           let unit = Int(match.unit.filter(\.isNumber)),
           count > 0 {
            return Quantity(count: count, unit: unit, isUnitFirst: false)
        }

        return nil
    }

    static func date(in text: String) -> LocalDate? {
        guard
            let match = text.firstMatch(of: datePattern),
            let year = Int(match.year),
            let month = Int(match.month),
            let day = Int(match.day)
        else {
            return nil
        }

        return LocalDate(year: year, month: month, day: day)
    }
}
