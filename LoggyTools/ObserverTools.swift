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
  var tokens: [Token] = []
  public init() { }
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
