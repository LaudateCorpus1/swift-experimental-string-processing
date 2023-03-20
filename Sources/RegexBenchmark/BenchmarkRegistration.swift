// This file has lines generated by createBenchmark.py
// Do not remove the start of registration or end of registration markers

extension BenchmarkRunner {
  static func makeRunner(
    _ samples: Int,
    _ quiet: Bool
  ) -> BenchmarkRunner {
    var benchmark = BenchmarkRunner("RegexBench", samples, quiet)
    // -- start of registrations --
    benchmark.addReluctantQuant()
    benchmark.addCSS()
    benchmark.addNotFound()
    benchmark.addGraphemeBreak()
    benchmark.addHangulSyllable()
    // benchmark.addHTML() // Disabled due to \b being unusably slow
    benchmark.addEmail()
    benchmark.addCustomCharacterClasses()
    benchmark.addBuiltinCC()
    benchmark.addUnicode()
    benchmark.addLiteralSearch()
    benchmark.addDiceNotation()
    benchmark.addErrorMessages()
    benchmark.addIpAddress()
    // -- end of registrations --
    return benchmark
  }
}