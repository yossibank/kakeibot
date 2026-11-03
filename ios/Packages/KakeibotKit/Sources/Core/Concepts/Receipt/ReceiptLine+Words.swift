import Foundation

extension ReceiptLine {
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

    static let minMarkedAmount = 10

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
            ^[T1IL]/[O0]\s
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
}
