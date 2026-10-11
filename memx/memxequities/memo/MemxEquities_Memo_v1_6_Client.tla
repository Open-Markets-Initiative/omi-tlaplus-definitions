------------------- MODULE MemxEquities_Memo_v1_6_Client -------------------
(***************************************************************************)
(* The Members Exchange Members Orders v1.6                                *)
(*                                                                         *)
(* Generated from the binary model. A field is the bytes it occupies; an   *)
(* integer is read only where a rule depends on one - a length, a count, a *)
(* message type - which are the dependencies the parse rules run on.       *)
(*                                                                         *)
(* TLC checks that every record decodes back to what was encoded, that a   *)
(* dispatch selects the message its type names, and that a derived length  *)
(* or count is written from what it describes.                             *)
(*                                                                         *)
(* Note: TLC evaluates integers in 32 bits, so a field wider than that has *)
(* no range it can enumerate; every field is checked as its bytes, which   *)
(* is exact at any width.                                                  *)
(*                                                                         *)
(* Note: Exec Inst is a bit field set, checked as its 2 bytes rather than  *)
(* bit by bit.                                                             *)
(***************************************************************************)
EXTENDS Integers, Sequences

(***************************************************************************)
(* Wire primitives                                                         *)
(***************************************************************************)

Byte == 0 .. 255

(* An unsigned integer, least significant byte first. Read only where a rule *)
(* depends on the value: a length, a count, a message type. *)
RECURSIVE DecodeUIntLE(_)
DecodeUIntLE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE Head(bytes) + 256 * DecodeUIntLE(Tail(bytes))

RECURSIVE EncodeUIntLE(_, _)
EncodeUIntLE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE <<value % 256>> \o EncodeUIntLE(value \div 256, width - 1)

(* The same, most significant byte first, which is how a big endian protocol writes it *)
RECURSIVE DecodeUIntBE(_)
DecodeUIntBE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeUIntBE(SubSeq(bytes, 1, Len(bytes) - 1)) * 256 + bytes[Len(bytes)]

RECURSIVE EncodeUIntBE(_, _)
EncodeUIntBE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeUIntBE(value \div 256, width - 1) \o <<value % 256>>

(***************************************************************************)
(* A decoder yields the value it read and the bytes left, or fails         *)
(***************************************************************************)

Fail == [ok |-> FALSE]
Ok(value, rest) == [ok |-> TRUE, value |-> value, rest |-> rest]

(* The bytes a field of this width occupies, kept as they lie *)
ReadBytes(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(SubSeq(bytes, 1, width), SubSeq(bytes, width + 1, Len(bytes)))

(* The integer a rule depends on, in the byte order the field states *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

ReadUIntBE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntBE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The bytes a field of no width of its own is checked at: none, one, and a short run *)
SampleBytes == { << >>, <<0>>, <<32, 255>> }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* Login Request Message: 2 bytes                                          *)
(***************************************************************************)

LoginRequestMessage ==
    [ tokenType : Sample(1),
      token     : Sample(1) ]

EncodeLoginRequestMessage(message) ==
    message.tokenType
        \o message.token

DecodeLoginRequestMessage(bytes) ==
    LET tokenType == ReadBytes(bytes, 1) IN IF ~tokenType.ok THEN Fail ELSE
    LET token == ReadBytes(tokenType.rest, 1) IN IF ~token.ok THEN Fail ELSE
    Ok([ tokenType |-> tokenType.value,
         token     |-> token.value ], token.rest)

ZeroLoginRequestMessage ==
    [ tokenType |-> [i \in 1 .. 1 |-> 0],
      token     |-> [i \in 1 .. 1 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.tokenType = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.token = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Request Message: 20 bytes                                        *)
(***************************************************************************)

ReplayRequestMessage ==
    [ sessionId          : Sample(8),
      nextSequenceNumber : Sample(8),
      count              : Sample(4) ]

EncodeReplayRequestMessage(message) ==
    message.sessionId
        \o message.nextSequenceNumber
        \o message.count

DecodeReplayRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET count == ReadBytes(nextSequenceNumber.rest, 4) IN IF ~count.ok THEN Fail ELSE
    Ok([ sessionId          |-> sessionId.value,
         nextSequenceNumber |-> nextSequenceNumber.value,
         count              |-> count.value ], count.rest)

ZeroReplayRequestMessage ==
    [ sessionId          |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      count              |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.count = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay All Request Message: 8 bytes                                     *)
(***************************************************************************)

ReplayAllRequestMessage ==
    [ sessionId : Sample(8) ]

EncodeReplayAllRequestMessage(message) ==
    message.sessionId

DecodeReplayAllRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroReplayAllRequestMessage ==
    [ sessionId |-> [i \in 1 .. 8 |-> 0] ]

(* Replay All Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayAllRequestMessage ==
    { ZeroReplayAllRequestMessage }
        \cup { [ZeroReplayAllRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Stream Request Message: 16 bytes                                        *)
(***************************************************************************)

StreamRequestMessage ==
    [ sessionId          : Sample(8),
      nextSequenceNumber : Sample(8) ]

EncodeStreamRequestMessage(message) ==
    message.sessionId
        \o message.nextSequenceNumber

DecodeStreamRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    Ok([ sessionId          |-> sessionId.value,
         nextSequenceNumber |-> nextSequenceNumber.value ], nextSequenceNumber.rest)

ZeroStreamRequestMessage ==
    [ sessionId          |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Stream Request Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamRequestMessage ==
    { ZeroStreamRequestMessage }
        \cup { [ZeroStreamRequestMessage EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroStreamRequestMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* New Order Single Message: 92 bytes                                      *)
(***************************************************************************)

NewOrderSingleMessage ==
    [ clordid                : Sample(16),
      mpid                   : Sample(4),
      symbol                 : Sample(6),
      symbolSfx              : Sample(6),
      side                   : Sample(1),
      orderQty               : Sample(4),
      ordType                : Sample(1),
      price                  : Sample(8),
      timeInForce            : Sample(1),
      orderCapacity          : Sample(1),
      custOrderCapacity      : Sample(1),
      execInst               : Sample(2),
      pegOffsetValue         : Sample(8),
      pegPriceType           : Sample(1),
      expireTime             : Sample(8),
      minQty                 : Sample(4),
      displayQty             : Sample(4),
      displayMethod          : Sample(1),
      reserveReplenishTiming : Sample(1),
      displayMinIncr         : Sample(4),
      locateReqd             : Sample(1),
      repriceFrequency       : Sample(1),
      repriceBehavior        : Sample(1),
      cancelGroupId          : Sample(2),
      stpGroupId             : Sample(2),
      selfTradePrevention    : Sample(1),
      riskGroupId            : Sample(2) ]

EncodeNewOrderSingleMessage(message) ==
    message.clordid
        \o message.mpid
        \o message.symbol
        \o message.symbolSfx
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.price
        \o message.timeInForce
        \o message.orderCapacity
        \o message.custOrderCapacity
        \o message.execInst
        \o message.pegOffsetValue
        \o message.pegPriceType
        \o message.expireTime
        \o message.minQty
        \o message.displayQty
        \o message.displayMethod
        \o message.reserveReplenishTiming
        \o message.displayMinIncr
        \o message.locateReqd
        \o message.repriceFrequency
        \o message.repriceBehavior
        \o message.cancelGroupId
        \o message.stpGroupId
        \o message.selfTradePrevention
        \o message.riskGroupId

DecodeNewOrderSingleMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET mpid == ReadBytes(clordid.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET symbol == ReadBytes(mpid.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSfx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(timeInForce.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET custOrderCapacity == ReadBytes(orderCapacity.rest, 1) IN IF ~custOrderCapacity.ok THEN Fail ELSE
    LET execInst == ReadBytes(custOrderCapacity.rest, 2) IN IF ~execInst.ok THEN Fail ELSE
    LET pegOffsetValue == ReadBytes(execInst.rest, 8) IN IF ~pegOffsetValue.ok THEN Fail ELSE
    LET pegPriceType == ReadBytes(pegOffsetValue.rest, 1) IN IF ~pegPriceType.ok THEN Fail ELSE
    LET expireTime == ReadBytes(pegPriceType.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET minQty == ReadBytes(expireTime.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayMethod == ReadBytes(displayQty.rest, 1) IN IF ~displayMethod.ok THEN Fail ELSE
    LET reserveReplenishTiming == ReadBytes(displayMethod.rest, 1) IN IF ~reserveReplenishTiming.ok THEN Fail ELSE
    LET displayMinIncr == ReadBytes(reserveReplenishTiming.rest, 4) IN IF ~displayMinIncr.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(displayMinIncr.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    LET repriceFrequency == ReadBytes(locateReqd.rest, 1) IN IF ~repriceFrequency.ok THEN Fail ELSE
    LET repriceBehavior == ReadBytes(repriceFrequency.rest, 1) IN IF ~repriceBehavior.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(repriceBehavior.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    LET stpGroupId == ReadBytes(cancelGroupId.rest, 2) IN IF ~stpGroupId.ok THEN Fail ELSE
    LET selfTradePrevention == ReadBytes(stpGroupId.rest, 1) IN IF ~selfTradePrevention.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(selfTradePrevention.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    Ok([ clordid                |-> clordid.value,
         mpid                   |-> mpid.value,
         symbol                 |-> symbol.value,
         symbolSfx              |-> symbolSfx.value,
         side                   |-> side.value,
         orderQty               |-> orderQty.value,
         ordType                |-> ordType.value,
         price                  |-> price.value,
         timeInForce            |-> timeInForce.value,
         orderCapacity          |-> orderCapacity.value,
         custOrderCapacity      |-> custOrderCapacity.value,
         execInst               |-> execInst.value,
         pegOffsetValue         |-> pegOffsetValue.value,
         pegPriceType           |-> pegPriceType.value,
         expireTime             |-> expireTime.value,
         minQty                 |-> minQty.value,
         displayQty             |-> displayQty.value,
         displayMethod          |-> displayMethod.value,
         reserveReplenishTiming |-> reserveReplenishTiming.value,
         displayMinIncr         |-> displayMinIncr.value,
         locateReqd             |-> locateReqd.value,
         repriceFrequency       |-> repriceFrequency.value,
         repriceBehavior        |-> repriceBehavior.value,
         cancelGroupId          |-> cancelGroupId.value,
         stpGroupId             |-> stpGroupId.value,
         selfTradePrevention    |-> selfTradePrevention.value,
         riskGroupId            |-> riskGroupId.value ], riskGroupId.rest)

ZeroNewOrderSingleMessage ==
    [ clordid                |-> [i \in 1 .. 16 |-> 0],
      mpid                   |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 6 |-> 0],
      symbolSfx              |-> [i \in 1 .. 6 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      orderCapacity          |-> [i \in 1 .. 1 |-> 0],
      custOrderCapacity      |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 2 |-> 0],
      pegOffsetValue         |-> [i \in 1 .. 8 |-> 0],
      pegPriceType           |-> [i \in 1 .. 1 |-> 0],
      expireTime             |-> [i \in 1 .. 8 |-> 0],
      minQty                 |-> [i \in 1 .. 4 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      displayMethod          |-> [i \in 1 .. 1 |-> 0],
      reserveReplenishTiming |-> [i \in 1 .. 1 |-> 0],
      displayMinIncr         |-> [i \in 1 .. 4 |-> 0],
      locateReqd             |-> [i \in 1 .. 1 |-> 0],
      repriceFrequency       |-> [i \in 1 .. 1 |-> 0],
      repriceBehavior        |-> [i \in 1 .. 1 |-> 0],
      cancelGroupId          |-> [i \in 1 .. 2 |-> 0],
      stpGroupId             |-> [i \in 1 .. 2 |-> 0],
      selfTradePrevention    |-> [i \in 1 .. 1 |-> 0],
      riskGroupId            |-> [i \in 1 .. 2 |-> 0] ]

(* New Order Single Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleMessage ==
    { ZeroNewOrderSingleMessage }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.custOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.execInst = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.pegOffsetValue = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.pegPriceType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.displayMethod = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.reserveReplenishTiming = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.displayMinIncr = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.locateReqd = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.repriceFrequency = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.repriceBehavior = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.stpGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.selfTradePrevention = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleMessage EXCEPT !.riskGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Cancel Replace Request Message: 63 bytes                          *)
(***************************************************************************)

OrderCancelReplaceRequestMessage ==
    [ origclordid : Sample(16),
      clordid     : Sample(16),
      symbol      : Sample(6),
      symbolSfx   : Sample(6),
      side        : Sample(1),
      orderQty    : Sample(4),
      ordType     : Sample(1),
      price       : Sample(8),
      displayQty  : Sample(4),
      locateReqd  : Sample(1) ]

EncodeOrderCancelReplaceRequestMessage(message) ==
    message.origclordid
        \o message.clordid
        \o message.symbol
        \o message.symbolSfx
        \o message.side
        \o message.orderQty
        \o message.ordType
        \o message.price
        \o message.displayQty
        \o message.locateReqd

DecodeOrderCancelReplaceRequestMessage(bytes) ==
    LET origclordid == ReadBytes(bytes, 16) IN IF ~origclordid.ok THEN Fail ELSE
    LET clordid == ReadBytes(origclordid.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET symbol == ReadBytes(clordid.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET side == ReadBytes(symbolSfx.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderQty.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET price == ReadBytes(ordType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(displayQty.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    Ok([ origclordid |-> origclordid.value,
         clordid     |-> clordid.value,
         symbol      |-> symbol.value,
         symbolSfx   |-> symbolSfx.value,
         side        |-> side.value,
         orderQty    |-> orderQty.value,
         ordType     |-> ordType.value,
         price       |-> price.value,
         displayQty  |-> displayQty.value,
         locateReqd  |-> locateReqd.value ], locateReqd.rest)

ZeroOrderCancelReplaceRequestMessage ==
    [ origclordid |-> [i \in 1 .. 16 |-> 0],
      clordid     |-> [i \in 1 .. 16 |-> 0],
      symbol      |-> [i \in 1 .. 6 |-> 0],
      symbolSfx   |-> [i \in 1 .. 6 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      orderQty    |-> [i \in 1 .. 4 |-> 0],
      ordType     |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      displayQty  |-> [i \in 1 .. 4 |-> 0],
      locateReqd  |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancel Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReplaceRequestMessage ==
    { ZeroOrderCancelReplaceRequestMessage }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.origclordid = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.locateReqd = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancel Request Message: 52 bytes                                  *)
(***************************************************************************)

OrderCancelRequestMessage ==
    [ origclordid     : Sample(16),
      orderIdOptional : Sample(8),
      clordid         : Sample(16),
      symbol          : Sample(6),
      symbolSfx       : Sample(6) ]

EncodeOrderCancelRequestMessage(message) ==
    message.origclordid
        \o message.orderIdOptional
        \o message.clordid
        \o message.symbol
        \o message.symbolSfx

DecodeOrderCancelRequestMessage(bytes) ==
    LET origclordid == ReadBytes(bytes, 16) IN IF ~origclordid.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(origclordid.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderIdOptional.rest, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET symbol == ReadBytes(clordid.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    Ok([ origclordid     |-> origclordid.value,
         orderIdOptional |-> orderIdOptional.value,
         clordid         |-> clordid.value,
         symbol          |-> symbol.value,
         symbolSfx       |-> symbolSfx.value ], symbolSfx.rest)

ZeroOrderCancelRequestMessage ==
    [ origclordid     |-> [i \in 1 .. 16 |-> 0],
      orderIdOptional |-> [i \in 1 .. 8 |-> 0],
      clordid         |-> [i \in 1 .. 16 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      symbolSfx       |-> [i \in 1 .. 6 |-> 0] ]

(* Order Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequestMessage ==
    { ZeroOrderCancelRequestMessage }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.origclordid = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }

(***************************************************************************)
(* Mass Cancel Request Message: 47 bytes                                   *)
(***************************************************************************)

MassCancelRequestMessage ==
    [ clordid         : Sample(16),
      symbol          : Sample(6),
      symbolSfx       : Sample(6),
      sideOptional    : Sample(1),
      lowerThanPrice  : Sample(8),
      higherThanPrice : Sample(8),
      cancelGroupId   : Sample(2) ]

EncodeMassCancelRequestMessage(message) ==
    message.clordid
        \o message.symbol
        \o message.symbolSfx
        \o message.sideOptional
        \o message.lowerThanPrice
        \o message.higherThanPrice
        \o message.cancelGroupId

DecodeMassCancelRequestMessage(bytes) ==
    LET clordid == ReadBytes(bytes, 16) IN IF ~clordid.ok THEN Fail ELSE
    LET symbol == ReadBytes(clordid.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(symbolSfx.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET lowerThanPrice == ReadBytes(sideOptional.rest, 8) IN IF ~lowerThanPrice.ok THEN Fail ELSE
    LET higherThanPrice == ReadBytes(lowerThanPrice.rest, 8) IN IF ~higherThanPrice.ok THEN Fail ELSE
    LET cancelGroupId == ReadBytes(higherThanPrice.rest, 2) IN IF ~cancelGroupId.ok THEN Fail ELSE
    Ok([ clordid         |-> clordid.value,
         symbol          |-> symbol.value,
         symbolSfx       |-> symbolSfx.value,
         sideOptional    |-> sideOptional.value,
         lowerThanPrice  |-> lowerThanPrice.value,
         higherThanPrice |-> higherThanPrice.value,
         cancelGroupId   |-> cancelGroupId.value ], cancelGroupId.rest)

ZeroMassCancelRequestMessage ==
    [ clordid         |-> [i \in 1 .. 16 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      symbolSfx       |-> [i \in 1 .. 6 |-> 0],
      sideOptional    |-> [i \in 1 .. 1 |-> 0],
      lowerThanPrice  |-> [i \in 1 .. 8 |-> 0],
      higherThanPrice |-> [i \in 1 .. 8 |-> 0],
      cancelGroupId   |-> [i \in 1 .. 2 |-> 0] ]

(* Mass Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRequestMessage ==
    { ZeroMassCancelRequestMessage }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.clordid = one] : one \in Sample(16) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.lowerThanPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.higherThanPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.cancelGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

NewOrderSingleMessageCode == 1  \* 0x01
OrderCancelReplaceRequestMessageCode == 2  \* 0x02
OrderCancelRequestMessageCode == 3  \* 0x03
MassCancelRequestMessageCode == 4  \* 0x04

ClientPayload ==
    [ tag : {NewOrderSingleMessageCode}, body : NewOrderSingleMessage ]
        \cup [ tag : {OrderCancelReplaceRequestMessageCode}, body : OrderCancelReplaceRequestMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {MassCancelRequestMessageCode}, body : MassCancelRequestMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = NewOrderSingleMessageCode -> EncodeNewOrderSingleMessage(message.body)
      [] message.tag = OrderCancelReplaceRequestMessageCode -> EncodeOrderCancelReplaceRequestMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = MassCancelRequestMessageCode -> EncodeMassCancelRequestMessage(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderSingleMessageCode -> DecodeNewOrderSingleMessage(bytes)
              [] tag = OrderCancelReplaceRequestMessageCode -> DecodeOrderCancelReplaceRequestMessage(bytes)
              [] tag = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] tag = MassCancelRequestMessageCode -> DecodeMassCancelRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> NewOrderSingleMessageCode, body |-> ZeroNewOrderSingleMessage]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> NewOrderSingleMessageCode, body |-> one] : one \in CheckedNewOrderSingleMessage }
        \cup { [tag |-> OrderCancelReplaceRequestMessageCode, body |-> one] : one \in CheckedOrderCancelReplaceRequestMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> MassCancelRequestMessageCode, body |-> one] : one \in CheckedMassCancelRequestMessage }

(***************************************************************************)
(* Client Sbe Message                                                      *)
(***************************************************************************)

ClientSbeMessage ==
    [ blockLength   : Sample(2),
      schemaId      : Sample(1),
      version       : Sample(2),
      clientPayload : ClientPayload ]

EncodeClientSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntBE(message.clientPayload.tag, 1)
        \o message.schemaId
        \o message.version
        \o EncodeClientPayload(message.clientPayload)

DecodeClientSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntBE(blockLength.rest, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, version.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         schemaId      |-> schemaId.value,
         version       |-> version.value,
         clientPayload |-> clientPayload.value ], clientPayload.rest)

ZeroClientSbeMessage ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      schemaId      |-> [i \in 1 .. 1 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      clientPayload |-> ZeroClientPayload ]

(* Client Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedClientSbeMessage ==
    { ZeroClientSbeMessage }
        \cup { [ZeroClientSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.schemaId = one] : one \in Sample(1) }
        \cup { [ZeroClientSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientSbeMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(***************************************************************************)
(* Unsequenced Message                                                     *)
(***************************************************************************)

UnsequencedMessage ==
    [ clientSbeMessage : ClientSbeMessage ]

EncodeUnsequencedMessage(message) ==
    EncodeClientSbeMessage(message.clientSbeMessage)

DecodeUnsequencedMessage(bytes) ==
    LET clientSbeMessage == DecodeClientSbeMessage(bytes) IN IF ~clientSbeMessage.ok THEN Fail ELSE
    Ok([ clientSbeMessage |-> clientSbeMessage.value ], clientSbeMessage.rest)

ZeroUnsequencedMessage ==
    [ clientSbeMessage |-> ZeroClientSbeMessage ]

(* Unsequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedMessage ==
    { ZeroUnsequencedMessage }
        \cup { [ZeroUnsequencedMessage EXCEPT !.clientSbeMessage = one] : one \in CheckedClientSbeMessage }

(***************************************************************************)
(* Client Data, selected by Message Type                                   *)
(***************************************************************************)

LoginRequestMessageCode == 100  \* 0x64
ReplayRequestMessageCode == 101  \* 0x65
ReplayAllRequestMessageCode == 102  \* 0x66
StreamRequestMessageCode == 103  \* 0x67
UnsequencedMessageCode == 104  \* 0x68

ClientData ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {ReplayAllRequestMessageCode}, body : ReplayAllRequestMessage ]
        \cup [ tag : {StreamRequestMessageCode}, body : StreamRequestMessage ]
        \cup [ tag : {UnsequencedMessageCode}, body : UnsequencedMessage ]

EncodeClientData(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = ReplayAllRequestMessageCode -> EncodeReplayAllRequestMessage(message.body)
      [] message.tag = StreamRequestMessageCode -> EncodeStreamRequestMessage(message.body)
      [] message.tag = UnsequencedMessageCode -> EncodeUnsequencedMessage(message.body)

DecodeClientData(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = ReplayAllRequestMessageCode -> DecodeReplayAllRequestMessage(bytes)
              [] tag = StreamRequestMessageCode -> DecodeStreamRequestMessage(bytes)
              [] tag = UnsequencedMessageCode -> DecodeUnsequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientData == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Client Data in turn, at the values the message it names is checked at *)
CheckedClientData ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> ReplayAllRequestMessageCode, body |-> one] : one \in CheckedReplayAllRequestMessage }
        \cup { [tag |-> StreamRequestMessageCode, body |-> one] : one \in CheckedStreamRequestMessage }
        \cup { [tag |-> UnsequencedMessageCode, body |-> one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ messageLength : 0 .. 255,
      clientData    : ClientData ]

EncodeClientPacket(message) ==
    EncodeUIntBE(message.clientData.tag, 1)
        \o EncodeUIntBE(message.messageLength, 2)
        \o EncodeClientData(message.clientData)

DecodeClientPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageLength == ReadUIntBE(messageType.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET clientData == DecodeClientData(messageType.value, messageLength.rest) IN IF ~clientData.ok THEN Fail ELSE
    Ok([ messageLength |-> messageLength.value,
         clientData    |-> clientData.value ], clientData.rest)

ZeroClientPacket ==
    [ messageLength |-> 0,
      clientData    |-> ZeroClientData ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroClientPacket EXCEPT !.clientData = one] : one \in CheckedClientData }

(***************************************************************************)
(* What TLC checks                                                         *)
(***************************************************************************)

(* An integer a rule depends on writes its width and reads back what was written *)
RoundTripUIntLE ==
    \A width \in 1 .. 3 :
        \A value \in {0, 1, 255, 256, 65535} :
            (value < 256 ^ width) =>
                /\ Len(EncodeUIntLE(value, width)) = width
                /\ DecodeUIntLE(EncodeUIntLE(value, width)) = value
                /\ Len(EncodeUIntBE(value, width)) = width
                /\ DecodeUIntBE(EncodeUIntBE(value, width)) = value
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte
                /\ \A i \in 1 .. width : EncodeUIntBE(value, width)[i] \in Byte

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequestMessage ==
    \A message \in CheckedReplayRequestMessage :
        LET read == DecodeReplayRequestMessage(EncodeReplayRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay All Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayAllRequestMessage ==
    \A message \in CheckedReplayAllRequestMessage :
        LET read == DecodeReplayAllRequestMessage(EncodeReplayAllRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamRequestMessage ==
    \A message \in CheckedStreamRequestMessage :
        LET read == DecodeStreamRequestMessage(EncodeStreamRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Single Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingleMessage ==
    \A message \in CheckedNewOrderSingleMessage :
        LET read == DecodeNewOrderSingleMessage(EncodeNewOrderSingleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Replace Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelReplaceRequestMessage ==
    \A message \in CheckedOrderCancelReplaceRequestMessage :
        LET read == DecodeOrderCancelReplaceRequestMessage(EncodeOrderCancelReplaceRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequestMessage ==
    \A message \in CheckedOrderCancelRequestMessage :
        LET read == DecodeOrderCancelRequestMessage(EncodeOrderCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRequestMessage ==
    \A message \in CheckedMassCancelRequestMessage :
        LET read == DecodeMassCancelRequestMessage(EncodeMassCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSbeMessage ==
    \A message \in CheckedClientSbeMessage :
        LET read == DecodeClientSbeMessage(EncodeClientSbeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(EncodeUnsequencedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Client Payload is selected by the Template Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Data is selected by the Message Type it is written under *)
SelectsClientData ==
    \A message \in CheckedClientData :
        LET read == DecodeClientData(message.tag, EncodeClientData(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
