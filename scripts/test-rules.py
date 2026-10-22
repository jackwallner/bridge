#!/usr/bin/env python3
"""Run the iOS trainer's Foundation-only engine/content XCTest suites on macOS."""

import os
from pathlib import Path
import re
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]
MODULE = 'Bridge'
TEST_FOLDER = 'BridgeTests'
APP_FOLDER = 'Bridge'
TEST_FILES = ["RulesAuditTests.swift", "ContentValidityTests.swift", "HandGeneratorTests.swift"] + []


def main() -> None:
    reference = REPO / TEST_FOLDER / "Resources/rules-reference.json"
    android = REPO / "android/app/src/test/resources/rules-reference.json"
    if reference.read_bytes() != android.read_bytes():
        raise SystemExit("Swift and Android rules-reference tables differ")
    developer = Path(subprocess.check_output(["xcode-select", "-p"], text=True).strip())
    platform = developer / "Platforms/MacOSX.platform/Developer"
    frameworks = str(platform / "Library/Frameworks")
    libraries = str(platform / "usr/lib")
    sources = sorted((REPO / "Shared/Models").glob("*.swift")) + sorted((REPO / "Shared/Content").glob("*.swift"))
    sources += [REPO / "Shared/Services/WhatsNew.swift", REPO / APP_FOLDER / "Utilities/ChoiceShuffle.swift"]
    tests = [REPO / TEST_FOLDER / name for name in TEST_FILES]
    tests += [REPO / TEST_FOLDER / name for name in []]
    with tempfile.TemporaryDirectory(prefix="trainer-rule-tests-") as temporary:
        work = Path(temporary)
        print(f"Compiling {MODULE} engine and content (Swift 6)", flush=True)
        subprocess.run(["xcrun", "swiftc", "-swift-version", "6", "-O", "-enable-testing", "-emit-library", "-emit-module",
                        "-module-name", MODULE, "-o", str(work / f"lib{MODULE}.dylib"), *map(str, sources)], cwd=work, check=True)
        compiled_tests: list[Path] = []
        classes: list[str] = []
        for test in tests:
            text = test.read_text()
            if "PracticeRunView" in text:
                text = re.sub(r"\n    func testTimeChallengeLastsNinetySeconds\(\) \{.*?\n    \}\n", "\n", text, flags=re.S)
                copy = work / test.name
                copy.write_text(text)
                compiled_tests.append(copy)
                classes += re.findall(r"final class (\w+)", text)
                continue
            if "@MainActor" in text:
                if "// MARK: - Mastery" in text:
                    text = text.split("// MARK: - Mastery")[0] + (text[text.index("    // MARK: - Helpers"):] if "    // MARK: - Helpers" in text else "}\n")
                else:
                    text = text.split("@MainActor")[0]
                copy = work / test.name
                copy.write_text(text)
                compiled_tests.append(copy)
            else:
                compiled_tests.append(test)
            classes += re.findall(r"final class (\w+)", text)
        runner = "import XCTest\nlet suite = XCTestSuite(name: \"Engine and content\")\n"
        runner += "\n".join(f"suite.addTest({name}.defaultTestSuite)" for name in classes)
        runner += "\nsuite.run()\nlet result = suite.testRun!\nexit(result.hasSucceeded && result.executionCount > 0 ? 0 : 1)\n"
        (work / "main.swift").write_text(runner)
        print(f"Compiling and running {', '.join(classes)}", flush=True)
        subprocess.run(["xcrun", "swiftc", "-swift-version", "6", "-I", str(work), "-L", str(work), "-l" + MODULE,
                        "-I", libraries, "-L", libraries, "-lXCTestSwiftSupport", "-F", frameworks, "-framework", "XCTest",
                        "-Xlinker", "-rpath", "-Xlinker", frameworks, *map(str, compiled_tests), str(work / "main.swift"),
                        "-o", str(work / "rules-tests")], cwd=work, check=True)
        environment = os.environ.copy()
        environment["DYLD_LIBRARY_PATH"] = str(work) + ":" + libraries
        subprocess.run([str(work / "rules-tests")], env=environment, check=True)


if __name__ == "__main__":
    main()
