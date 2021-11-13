public enum MatchMode {
  case wholeString
  case partialFromFront
}

public struct MatchResult {
  public var range: Range<String.Index>
  public var captures: Capture

  public var destructure: (
    matched: Range<String.Index>, captures: Capture
  ) {
    (range, captures)
  }

  public init(
    _ matched: Range<String.Index>, _ captures: Capture
  ) {
    self.range = matched
    self.captures = captures
  }
}

/// VMs load RECode and run over Strings.
public protocol VirtualMachine {
  /// Declare this VM's motto and general life philosophy
  static var motto: String { get }

  /// Load some RECode and prepare to match
  init(_: RECode)

  /// Match `input`
  func execute(input: String, in range: Range<String.Index>, _ mode: MatchMode) -> MatchResult?
}

extension VirtualMachine {
  /// Match `input`
  public func execute(
    input: String, _ mode: MatchMode = .wholeString
  ) -> MatchResult? {
    execute(input: input, in: input.startIndex..<input.endIndex, mode)
  }
}

import Util

extension RECode {
  /// A convenient VM thread "core" abstraction
  public struct ThreadCore {
    enum CaptureState {
      case started(String.Index)
      case ended

      var isEnded: Bool {
        guard case .ended = self else {
          return false
        }
        return true
      }

      mutating func start(at index: String.Index) {
        assert(isEnded, "Capture already started")
        self = .started(index)
      }

      mutating func end(at endIndex: String.Index) -> Range<String.Index> {
        guard case let .started(startIndex) = self else {
          fatalError("Capture already ended")
        }
        self = .ended
        return startIndex..<endIndex
      }
    }
    public var pc: InstructionAddress
    public let input: String

    var groups = Stack<[Capture]>()
    var topLevelCaptures: [Capture] = []
    var captureState: CaptureState = .ended

    public init(startingAt pc: InstructionAddress, input: String) {
      self.pc = pc
      self.input = input
    }

    public mutating func advance() { self.pc = self.pc + 1 }
    public mutating func go(to: InstructionAddress) { self.pc = to }

    public mutating func beginCapture(_ index: String.Index) {
      captureState.start(at: index)
    }

    public mutating func endCapture(_ endIndex: String.Index, transform: CaptureTransform?) {
      let range = captureState.end(at: endIndex)
      let substring = input[range]
      let value = transform?(substring) ?? substring
      topLevelCaptures.append(.atom(value))
    }

    public mutating func beginGroup() {
      groups.push(topLevelCaptures)
      topLevelCaptures = []
    }

    public mutating func endGroup() {
      assert(!groups.isEmpty)
      var top = groups.pop()
      if !topLevelCaptures.isEmpty {
        top.append(singleCapture())
      }
      topLevelCaptures = top
    }

    public mutating func captureNil() {
      topLevelCaptures = [.optional(nil)]
    }

    public mutating func captureSome() {
      topLevelCaptures = [.optional(.tupleOrAtom(topLevelCaptures))]
    }

    public mutating func captureArray() {
      topLevelCaptures = [.array(topLevelCaptures)]
    }

    public func singleCapture() -> Capture {
      .tupleOrAtom(topLevelCaptures)
    }
  }
}

public struct Stack<T> {
  public var stack: Array<T>

  public init() { self.stack = [] }
  public var isEmpty: Bool { return stack.isEmpty }

  public mutating func pop() -> T {
    guard !isEmpty else { fatalError("stack is empty") }
    return stack.popLast()!
  }
  public mutating func push(_ t: T) {
    stack.append(t)
  }
  public func peek() -> T {
    guard !isEmpty else { fatalError("stack is empty") }
    return stack.last!
  }
}