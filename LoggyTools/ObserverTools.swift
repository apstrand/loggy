//
//  ObserverTools.swift
//  Loggy
//
//  Created by Peter Strand on 2017-07-05.
//  Copyright © 2017 Peter Strand. All rights reserved.
//

import Foundation

public class Token {
}

public class TokenRegs {
  fileprivate var tokens: [Token] = []
  public init() { }
  public func release() {
    tokens.removeAll()
  }
}

public func +=(regs: inout TokenRegs, token: Token) {
  regs.tokens.append(token)
}


class TokenImpl: Token {
  typealias Remover = (() -> Void)
  let remover: Remover
  init(_ remover: @escaping Remover) {
    self.remover = remover
  }
  deinit {
    remover()
  }
}

/*
class TokenImplList<T> : Token where T : MutableCollection {
  var list : T
  let removeId : Int
  init(_ list: T, removeId: Int) {
    self.list = list
    self.removeId = removeId
  }
  deinit {
    for ix in self.list.indices {
      if self.list[ix].0 == self.removeId {
        self.list.remove(at: ix)
        break
      }
    }
  }
}
*/
