#!/usr/bin/env python3
import os
import re
import sys

FOLDERS = [
    (os.path.join("ios", "Packages", "KakeibotApp", "Sources", "FeatureModels"), ".swift"),
    (os.path.join("android", "featuremodels", "src", "main"), ".kt"),
]
PART = re.compile(r"^\s*(?:(?:public|internal|private|fileprivate|final)\s+)*class\s+(?P<part>State|Input)\b")
DECLARATION = re.compile(
    r"^\s*(?P<modifiers>(?:@\w+(?:\([^)]*\))?\s+"
    r"|(?:public|internal|private|fileprivate|override|lateinit|nonisolated|weak|unowned)(?:\(set\))?\s+)*)"
    r"(?P<kind>var|let|val)\s+(?P<name>\w+)\s*(?::\s*(?P<type>[^={]+?))?\s*,?\s*(?P<rest>(?:=|by\b|\{).*)?$"
)
STRING = re.compile(r'"(?:\\.|[^"\\])*"')
WRAPPER = re.compile(r"^(?:Optional|Array|Set|List|MutableList|ImmutableList|PersistentList)<(.*)>$")
BARE = {
    "Bool", "Boolean", "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "Long", "Short", "Byte",
    "Double", "Float", "CGFloat", "Decimal", "BigDecimal", "String", "Character", "Char",
    "Date", "LocalDate", "LocalDateTime", "Instant", "YearMonth", "TimeInterval", "UUID",
}
ID_TYPE = re.compile(r"^(?:\w+\.)*ID$|^Identifier<.*>$")
LITERAL = re.compile(r'^(?:true|false|-?\d[\d_]*(?:\.\d+)?[LlFf]?|"")$')
PRIMITIVE_STATE = re.compile(r"^mutable(?:Int|Long|Float|Double)StateOf\(")
STATE_OF = re.compile(r"^mutableStateOf\((.*)\)$")
NOTICE_TYPE = re.compile(r"\b(?:ErrorNotice|UndoNotice)\b")
INPUT_MARK = re.compile(r"needs[A-Z]\w*|is(?:Refreshing|Starting|Stopping|Running|Working|Saving|Sending|Requesting|Pending)")
INPUT_HANDLE = re.compile(r"(?:^|[^\w.])(?:Task<|Job\b)")
INPUT_HANDLE_VALUE = re.compile(r"^(?:Task\s*[{(]|(?:\w+\.)*launch\b)")
ATTRIBUTES_ONLY = re.compile(r"(?:@\w+(?:\([^)]*\))?\s*)+")
FLAG = {"Bool", "Boolean"}
FLAG_VALUE = {"true", "false"}
SWIFT_OPEN = {"fields", "presented"}
SWIFT_SETTERS = ("private(set)", "internal(set)", "fileprivate(set)")
PRIVATE = ("private", "fileprivate")


def code(line):
    return STRING.sub('""', line).split("//")[0]


def depths(lines, start):
    braces = parens = 0
    opened = False

    for index in range(start, len(lines)):
        yield index, braces, parens
        text = code(lines[index])
        braces += text.count("{") - text.count("}")
        parens += text.count("(") - text.count(")")
        opened = opened or "{" in text

        if opened and braces <= 0:
            return


def bare(text):
    name = text.replace(" ", "")

    while True:
        unwrapped = name.rstrip("?!")

        if unwrapped.startswith("[") and unwrapped.endswith("]") and ":" not in unwrapped:
            unwrapped = unwrapped[1:-1]
        elif match := WRAPPER.match(unwrapped):
            unwrapped = match.group(1)

        if unwrapped == name:
            break

        name = unwrapped

    return name.split("Swift.")[-1] in BARE or bool(ID_TYPE.match(name))


def initial(rest):
    if not rest:
        return None

    value = rest[1:].strip() if rest.startswith("=") else rest[2:].strip() if rest.startswith("by") else None

    if value is None:
        return None

    if match := STATE_OF.match(value):
        return match.group(1).strip()

    return value


def bare_initial(rest):
    value = initial(rest)

    if value is None:
        return False

    return bool(LITERAL.match(value) or PRIMITIVE_STATE.match(value))


def is_flag(declared, rest):
    if declared:
        return declared.rstrip("?") in FLAG
    return initial(rest) in FLAG_VALUE


def input_error(name, declared, rest, attributes):
    """Input の直下の値のうち、外から来る値でない物を見分けて文を返す。当たらない時は None を返す。"""
    if INPUT_HANDLE.search(declared) or INPUT_HANDLE_VALUE.match(initial(rest) or ""):
        return "動いている Task と Job は Input に置かない（モデルの Runtime へ）"

    if is_flag(declared, rest) and (INPUT_MARK.fullmatch(name) or "@ObservationIgnored" in attributes):
        return "実行中の印と、走らせ直すための印は Input に置かない（task の鍵か、State の値の型へ）"

    return None


def check(path, relative, swift, errors):
    with open(path, encoding="utf-8") as file:
        lines = file.read().split("\n")

    for start, line in enumerate(lines):
        found = PART.match(code(line))

        if not found:
            continue

        part = found.group("part")

        rows = list(depths(lines, start))
        for position, (index, braces, parens) in enumerate(rows):
            member = (braces, parens) == (1, 0)
            constructor = not swift and (braces, parens) == (0, 1) and index != start

            if not (member or constructor):
                continue

            match = DECLARATION.match(code(lines[index]))

            if not match:
                continue

            end = position

            while end + 1 < len(rows) and rows[end + 1][1:] != (1, 0):
                end += 1

            following = lines[rows[end + 1][0]].strip() if end + 1 < len(rows) else ""
            rest = (match.group("rest") or "").strip()
            computed = rest.startswith("{") if swift else following.startswith("get(")

            if computed:
                continue

            name = match.group("name")
            kind = match.group("kind")
            declared = (match.group("type") or "").strip()
            modifiers = match.group("modifiers").split()

            def report(message):
                errors.append(f"{relative}:{index + 1}: error: {message}: {name}")

            if part == "Input":
                above = code(lines[index - 1]).strip()
                attributes = modifiers + (above.split() if ATTRIBUTES_ONLY.fullmatch(above) else [])

                if message := input_error(name, declared, rest, attributes):
                    report(message)

                continue

            if name == "errorNotice" or NOTICE_TYPE.search(declared) or NOTICE_TYPE.match(initial(rest) or ""):
                report("知らせは State の直下に置かず、notices に置く")
            elif bare(declared) if declared else bare_initial(rest):
                report("裸の値は State の直下に置かない（input・output・presented・fields・値の型へ）")

            if kind != "var" or any(modifier in PRIVATE for modifier in modifiers):
                continue

            if swift:
                restricted = name in SWIFT_OPEN or any(modifier in SWIFT_SETTERS for modifier in modifiers)
            else:
                restricted = member and following == "private set"

            if not restricted:
                setter = "private(set) か internal(set)" if swift else "private set"
                report(f"State の直下の var は、書けるのをモデルだけにする（{setter}）")



def main():
    root = sys.argv[sys.argv.index("--root") + 1] if "--root" in sys.argv else None
    root = root or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    errors = []

    for folder, extension in FOLDERS:
        for directory, _, files in sorted(os.walk(os.path.join(root, folder))):
            for name in sorted(files):
                if name.endswith(extension):
                    path = os.path.join(directory, name)
                    check(path, os.path.relpath(path, root), extension == ".swift", errors)

    print("\n".join(errors))
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
