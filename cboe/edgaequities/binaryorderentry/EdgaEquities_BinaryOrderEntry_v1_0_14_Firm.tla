------------ MODULE EdgaEquities_BinaryOrderEntry_v1_0_14_Firm -------------
(***************************************************************************)
(* Chicago Board Options Exchange Binary Order Entry v1.0.14               *)
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
(* Unit Sequence: 5 bytes                                                  *)
(***************************************************************************)

UnitSequence ==
    [ unitNumber     : Sample(1),
      sequenceNumber : Sample(4) ]

EncodeUnitSequence(message) ==
    message.unitNumber
        \o message.sequenceNumber

DecodeUnitSequence(bytes) ==
    LET unitNumber == ReadBytes(bytes, 1) IN IF ~unitNumber.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(unitNumber.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ unitNumber     |-> unitNumber.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroUnitSequence ==
    [ unitNumber     |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Sequence at zero, then each field in turn at the values it is checked at *)
CheckedUnitSequence ==
    { ZeroUnitSequence }
        \cup { [ZeroUnitSequence EXCEPT !.unitNumber = one] : one \in Sample(1) }
        \cup { [ZeroUnitSequence EXCEPT !.sequenceNumber = one] : one \in Sample(4) }

(* A run of Unit Sequence, written one after another *)
RECURSIVE EncodeUnitSequenceList(_)
EncodeUnitSequenceList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnitSequence(Head(messages)) \o EncodeUnitSequenceList(Tail(messages))

(* As many Unit Sequence as the field that counts them says *)
RECURSIVE ReadUnitSequenceList(_, _)
ReadUnitSequenceList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnitSequence(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnitSequenceList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Unit Sequence of each kind, for the lists that carry them *)
OneUnitSequence == { ZeroUnitSequence }

(***************************************************************************)
(* Login Request Message                                                   *)
(***************************************************************************)

LoginRequestMessage ==
    [ sessionId         : Sample(4),
      sessionSubId      : Sample(4),
      password          : Sample(10),
      replayInstruction : Sample(1),
      unitSequence      : SampleLists(OneUnitSequence) ]

EncodeLoginRequestMessage(message) ==
    message.sessionId
        \o message.sessionSubId
        \o message.password
        \o message.replayInstruction
        \o EncodeUIntLE(Len(message.unitSequence), 1)
        \o EncodeUnitSequenceList(message.unitSequence)

DecodeLoginRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET sessionSubId == ReadBytes(sessionId.rest, 4) IN IF ~sessionSubId.ok THEN Fail ELSE
    LET password == ReadBytes(sessionSubId.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET replayInstruction == ReadBytes(password.rest, 1) IN IF ~replayInstruction.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntLE(replayInstruction.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequenceList(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ sessionId         |-> sessionId.value,
         sessionSubId      |-> sessionSubId.value,
         password          |-> password.value,
         replayInstruction |-> replayInstruction.value,
         unitSequence      |-> unitSequence.value ], unitSequence.rest)

ZeroLoginRequestMessage ==
    [ sessionId         |-> [i \in 1 .. 4 |-> 0],
      sessionSubId      |-> [i \in 1 .. 4 |-> 0],
      password          |-> [i \in 1 .. 10 |-> 0],
      replayInstruction |-> [i \in 1 .. 1 |-> 0],
      unitSequence      |-> << >> ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.sessionSubId = one] : one \in Sample(4) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.replayInstruction = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence) }

(***************************************************************************)
(* New Order Us Equities V 1: 141 bytes                                    *)
(***************************************************************************)

NewOrderUsEquitiesV1 ==
    [ clOrdId             : Sample(20),
      side                : Sample(1),
      orderQty            : Sample(4),
      clearingFirm        : Sample(4),
      clearingAccount     : Sample(4),
      price               : Sample(8),
      execInst            : Sample(1),
      ordType             : Sample(1),
      timeInForce         : Sample(1),
      minQty              : Sample(4),
      maxFloor            : Sample(4),
      symbol              : Sample(8),
      capacity            : Sample(1),
      routingInst         : Sample(4),
      account             : Sample(16),
      displayIndicator    : Sample(1),
      discretionAmount    : Sample(2),
      pegDifference       : Sample(8),
      preventMatch        : Sample(3),
      locateReqd          : Sample(1),
      expireTime          : Sample(8),
      attributedQuote     : Sample(1),
      extExecInst         : Sample(1),
      displayRange        : Sample(4),
      stopPx              : Sample(8),
      routStrategy        : Sample(6),
      routeDeliveryMethod : Sample(3),
      exDestination       : Sample(1),
      riskGroupId         : Sample(2),
      crossTradeFlag      : Sample(1),
      locateBroker        : Sample(4),
      stepUpAmount        : Sample(4),
      cmcSessions         : Sample(2) ]

EncodeNewOrderUsEquitiesV1(message) ==
    message.clOrdId
        \o message.side
        \o message.orderQty
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.price
        \o message.execInst
        \o message.ordType
        \o message.timeInForce
        \o message.minQty
        \o message.maxFloor
        \o message.symbol
        \o message.capacity
        \o message.routingInst
        \o message.account
        \o message.displayIndicator
        \o message.discretionAmount
        \o message.pegDifference
        \o message.preventMatch
        \o message.locateReqd
        \o message.expireTime
        \o message.attributedQuote
        \o message.extExecInst
        \o message.displayRange
        \o message.stopPx
        \o message.routStrategy
        \o message.routeDeliveryMethod
        \o message.exDestination
        \o message.riskGroupId
        \o message.crossTradeFlag
        \o message.locateBroker
        \o message.stepUpAmount
        \o message.cmcSessions

DecodeNewOrderUsEquitiesV1(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderQty.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET price == ReadBytes(clearingAccount.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadBytes(price.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadBytes(execInst.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadBytes(timeInForce.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET symbol == ReadBytes(maxFloor.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET capacity == ReadBytes(symbol.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET routingInst == ReadBytes(capacity.rest, 4) IN IF ~routingInst.ok THEN Fail ELSE
    LET account == ReadBytes(routingInst.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET displayIndicator == ReadBytes(account.rest, 1) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET discretionAmount == ReadBytes(displayIndicator.rest, 2) IN IF ~discretionAmount.ok THEN Fail ELSE
    LET pegDifference == ReadBytes(discretionAmount.rest, 8) IN IF ~pegDifference.ok THEN Fail ELSE
    LET preventMatch == ReadBytes(pegDifference.rest, 3) IN IF ~preventMatch.ok THEN Fail ELSE
    LET locateReqd == ReadBytes(preventMatch.rest, 1) IN IF ~locateReqd.ok THEN Fail ELSE
    LET expireTime == ReadBytes(locateReqd.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(expireTime.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET extExecInst == ReadBytes(attributedQuote.rest, 1) IN IF ~extExecInst.ok THEN Fail ELSE
    LET displayRange == ReadBytes(extExecInst.rest, 4) IN IF ~displayRange.ok THEN Fail ELSE
    LET stopPx == ReadBytes(displayRange.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET routStrategy == ReadBytes(stopPx.rest, 6) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadBytes(routStrategy.rest, 3) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadBytes(routeDeliveryMethod.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(exDestination.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET crossTradeFlag == ReadBytes(riskGroupId.rest, 1) IN IF ~crossTradeFlag.ok THEN Fail ELSE
    LET locateBroker == ReadBytes(crossTradeFlag.rest, 4) IN IF ~locateBroker.ok THEN Fail ELSE
    LET stepUpAmount == ReadBytes(locateBroker.rest, 4) IN IF ~stepUpAmount.ok THEN Fail ELSE
    LET cmcSessions == ReadBytes(stepUpAmount.rest, 2) IN IF ~cmcSessions.ok THEN Fail ELSE
    Ok([ clOrdId             |-> clOrdId.value,
         side                |-> side.value,
         orderQty            |-> orderQty.value,
         clearingFirm        |-> clearingFirm.value,
         clearingAccount     |-> clearingAccount.value,
         price               |-> price.value,
         execInst            |-> execInst.value,
         ordType             |-> ordType.value,
         timeInForce         |-> timeInForce.value,
         minQty              |-> minQty.value,
         maxFloor            |-> maxFloor.value,
         symbol              |-> symbol.value,
         capacity            |-> capacity.value,
         routingInst         |-> routingInst.value,
         account             |-> account.value,
         displayIndicator    |-> displayIndicator.value,
         discretionAmount    |-> discretionAmount.value,
         pegDifference       |-> pegDifference.value,
         preventMatch        |-> preventMatch.value,
         locateReqd          |-> locateReqd.value,
         expireTime          |-> expireTime.value,
         attributedQuote     |-> attributedQuote.value,
         extExecInst         |-> extExecInst.value,
         displayRange        |-> displayRange.value,
         stopPx              |-> stopPx.value,
         routStrategy        |-> routStrategy.value,
         routeDeliveryMethod |-> routeDeliveryMethod.value,
         exDestination       |-> exDestination.value,
         riskGroupId         |-> riskGroupId.value,
         crossTradeFlag      |-> crossTradeFlag.value,
         locateBroker        |-> locateBroker.value,
         stepUpAmount        |-> stepUpAmount.value,
         cmcSessions         |-> cmcSessions.value ], cmcSessions.rest)

ZeroNewOrderUsEquitiesV1 ==
    [ clOrdId             |-> [i \in 1 .. 20 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      orderQty            |-> [i \in 1 .. 4 |-> 0],
      clearingFirm        |-> [i \in 1 .. 4 |-> 0],
      clearingAccount     |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      execInst            |-> [i \in 1 .. 1 |-> 0],
      ordType             |-> [i \in 1 .. 1 |-> 0],
      timeInForce         |-> [i \in 1 .. 1 |-> 0],
      minQty              |-> [i \in 1 .. 4 |-> 0],
      maxFloor            |-> [i \in 1 .. 4 |-> 0],
      symbol              |-> [i \in 1 .. 8 |-> 0],
      capacity            |-> [i \in 1 .. 1 |-> 0],
      routingInst         |-> [i \in 1 .. 4 |-> 0],
      account             |-> [i \in 1 .. 16 |-> 0],
      displayIndicator    |-> [i \in 1 .. 1 |-> 0],
      discretionAmount    |-> [i \in 1 .. 2 |-> 0],
      pegDifference       |-> [i \in 1 .. 8 |-> 0],
      preventMatch        |-> [i \in 1 .. 3 |-> 0],
      locateReqd          |-> [i \in 1 .. 1 |-> 0],
      expireTime          |-> [i \in 1 .. 8 |-> 0],
      attributedQuote     |-> [i \in 1 .. 1 |-> 0],
      extExecInst         |-> [i \in 1 .. 1 |-> 0],
      displayRange        |-> [i \in 1 .. 4 |-> 0],
      stopPx              |-> [i \in 1 .. 8 |-> 0],
      routStrategy        |-> [i \in 1 .. 6 |-> 0],
      routeDeliveryMethod |-> [i \in 1 .. 3 |-> 0],
      exDestination       |-> [i \in 1 .. 1 |-> 0],
      riskGroupId         |-> [i \in 1 .. 2 |-> 0],
      crossTradeFlag      |-> [i \in 1 .. 1 |-> 0],
      locateBroker        |-> [i \in 1 .. 4 |-> 0],
      stepUpAmount        |-> [i \in 1 .. 4 |-> 0],
      cmcSessions         |-> [i \in 1 .. 2 |-> 0] ]

(* New Order Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderUsEquitiesV1 ==
    { ZeroNewOrderUsEquitiesV1 }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.routingInst = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.discretionAmount = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.pegDifference = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.preventMatch = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.locateReqd = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.extExecInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.displayRange = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.routStrategy = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.routeDeliveryMethod = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.crossTradeFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.locateBroker = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.stepUpAmount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderUsEquitiesV1 EXCEPT !.cmcSessions = one] : one \in Sample(2) }

(***************************************************************************)
(* New Order Short Us Equities V 1: 71 bytes                               *)
(***************************************************************************)

NewOrderShortUsEquitiesV1 ==
    [ clOrdId          : Sample(20),
      side             : Sample(1),
      orderQty         : Sample(4),
      clearingFirm     : Sample(4),
      clearingAccount  : Sample(4),
      price            : Sample(8),
      execInst         : Sample(1),
      ordType          : Sample(1),
      timeInForce      : Sample(1),
      symbol           : Sample(8),
      capacity         : Sample(1),
      shortRoutingInst : Sample(1),
      shortAccount     : Sample(10),
      displayIndicator : Sample(1),
      riskGroupId      : Sample(2),
      locateBroker     : Sample(4) ]

EncodeNewOrderShortUsEquitiesV1(message) ==
    message.clOrdId
        \o message.side
        \o message.orderQty
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.price
        \o message.execInst
        \o message.ordType
        \o message.timeInForce
        \o message.symbol
        \o message.capacity
        \o message.shortRoutingInst
        \o message.shortAccount
        \o message.displayIndicator
        \o message.riskGroupId
        \o message.locateBroker

DecodeNewOrderShortUsEquitiesV1(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET side == ReadBytes(clOrdId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderQty.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET price == ReadBytes(clearingAccount.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadBytes(price.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadBytes(execInst.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeInForce.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET capacity == ReadBytes(symbol.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET shortRoutingInst == ReadBytes(capacity.rest, 1) IN IF ~shortRoutingInst.ok THEN Fail ELSE
    LET shortAccount == ReadBytes(shortRoutingInst.rest, 10) IN IF ~shortAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadBytes(shortAccount.rest, 1) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(displayIndicator.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    LET locateBroker == ReadBytes(riskGroupId.rest, 4) IN IF ~locateBroker.ok THEN Fail ELSE
    Ok([ clOrdId          |-> clOrdId.value,
         side             |-> side.value,
         orderQty         |-> orderQty.value,
         clearingFirm     |-> clearingFirm.value,
         clearingAccount  |-> clearingAccount.value,
         price            |-> price.value,
         execInst         |-> execInst.value,
         ordType          |-> ordType.value,
         timeInForce      |-> timeInForce.value,
         symbol           |-> symbol.value,
         capacity         |-> capacity.value,
         shortRoutingInst |-> shortRoutingInst.value,
         shortAccount     |-> shortAccount.value,
         displayIndicator |-> displayIndicator.value,
         riskGroupId      |-> riskGroupId.value,
         locateBroker     |-> locateBroker.value ], locateBroker.rest)

ZeroNewOrderShortUsEquitiesV1 ==
    [ clOrdId          |-> [i \in 1 .. 20 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      orderQty         |-> [i \in 1 .. 4 |-> 0],
      clearingFirm     |-> [i \in 1 .. 4 |-> 0],
      clearingAccount  |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      execInst         |-> [i \in 1 .. 1 |-> 0],
      ordType          |-> [i \in 1 .. 1 |-> 0],
      timeInForce      |-> [i \in 1 .. 1 |-> 0],
      symbol           |-> [i \in 1 .. 8 |-> 0],
      capacity         |-> [i \in 1 .. 1 |-> 0],
      shortRoutingInst |-> [i \in 1 .. 1 |-> 0],
      shortAccount     |-> [i \in 1 .. 10 |-> 0],
      displayIndicator |-> [i \in 1 .. 1 |-> 0],
      riskGroupId      |-> [i \in 1 .. 2 |-> 0],
      locateBroker     |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Short Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderShortUsEquitiesV1 ==
    { ZeroNewOrderShortUsEquitiesV1 }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.shortRoutingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.shortAccount = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderShortUsEquitiesV1 EXCEPT !.locateBroker = one] : one \in Sample(4) }

(***************************************************************************)
(* Cancel Order Us Equities V 1: 24 bytes                                  *)
(***************************************************************************)

CancelOrderUsEquitiesV1 ==
    [ origClOrdId  : Sample(20),
      clearingFirm : Sample(4) ]

EncodeCancelOrderUsEquitiesV1(message) ==
    message.origClOrdId
        \o message.clearingFirm

DecodeCancelOrderUsEquitiesV1(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(origClOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    Ok([ origClOrdId  |-> origClOrdId.value,
         clearingFirm |-> clearingFirm.value ], clearingFirm.rest)

ZeroCancelOrderUsEquitiesV1 ==
    [ origClOrdId  |-> [i \in 1 .. 20 |-> 0],
      clearingFirm |-> [i \in 1 .. 4 |-> 0] ]

(* Cancel Order Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderUsEquitiesV1 ==
    { ZeroCancelOrderUsEquitiesV1 }
        \cup { [ZeroCancelOrderUsEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Us Equities V 1: 83 bytes                                  *)
(***************************************************************************)

ModifyOrderUsEquitiesV1 ==
    [ clOrdId            : Sample(20),
      origClOrdId        : Sample(20),
      clearingFirm       : Sample(4),
      symbol             : Sample(8),
      orderQty           : Sample(4),
      price              : Sample(8),
      ordType            : Sample(1),
      side               : Sample(1),
      maxFloor           : Sample(4),
      stopPx             : Sample(8),
      cancelOrigOnReject : Sample(1),
      locateBroker       : Sample(4) ]

EncodeModifyOrderUsEquitiesV1(message) ==
    message.clOrdId
        \o message.origClOrdId
        \o message.clearingFirm
        \o message.symbol
        \o message.orderQty
        \o message.price
        \o message.ordType
        \o message.side
        \o message.maxFloor
        \o message.stopPx
        \o message.cancelOrigOnReject
        \o message.locateBroker

DecodeModifyOrderUsEquitiesV1(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(origClOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET symbol == ReadBytes(clearingFirm.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderQty == ReadBytes(symbol.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET side == ReadBytes(ordType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(side.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET stopPx == ReadBytes(maxFloor.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadBytes(stopPx.rest, 1) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    LET locateBroker == ReadBytes(cancelOrigOnReject.rest, 4) IN IF ~locateBroker.ok THEN Fail ELSE
    Ok([ clOrdId            |-> clOrdId.value,
         origClOrdId        |-> origClOrdId.value,
         clearingFirm       |-> clearingFirm.value,
         symbol             |-> symbol.value,
         orderQty           |-> orderQty.value,
         price              |-> price.value,
         ordType            |-> ordType.value,
         side               |-> side.value,
         maxFloor           |-> maxFloor.value,
         stopPx             |-> stopPx.value,
         cancelOrigOnReject |-> cancelOrigOnReject.value,
         locateBroker       |-> locateBroker.value ], locateBroker.rest)

ZeroModifyOrderUsEquitiesV1 ==
    [ clOrdId            |-> [i \in 1 .. 20 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      ordType            |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      maxFloor           |-> [i \in 1 .. 4 |-> 0],
      stopPx             |-> [i \in 1 .. 8 |-> 0],
      cancelOrigOnReject |-> [i \in 1 .. 1 |-> 0],
      locateBroker       |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Order Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderUsEquitiesV1 ==
    { ZeroModifyOrderUsEquitiesV1 }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.cancelOrigOnReject = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderUsEquitiesV1 EXCEPT !.locateBroker = one] : one \in Sample(4) }

(***************************************************************************)
(* Purge Orders Us Equities V 1: 44 bytes                                  *)
(***************************************************************************)

PurgeOrdersUsEquitiesV1 ==
    [ massCancelId       : Sample(20),
      clearingFirm       : Sample(4),
      massCancelInst     : Sample(8),
      symbol             : Sample(8),
      targetMatchingUnit : Sample(1),
      riskGroupIdCnt     : 0 .. 255,
      riskGroupId        : Sample(2) ]

EncodePurgeOrdersUsEquitiesV1(message) ==
    message.massCancelId
        \o message.clearingFirm
        \o message.massCancelInst
        \o message.symbol
        \o message.targetMatchingUnit
        \o EncodeUIntLE(message.riskGroupIdCnt, 1)
        \o message.riskGroupId

DecodePurgeOrdersUsEquitiesV1(bytes) ==
    LET massCancelId == ReadBytes(bytes, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(massCancelId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET massCancelInst == ReadBytes(clearingFirm.rest, 8) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET symbol == ReadBytes(massCancelInst.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET targetMatchingUnit == ReadBytes(symbol.rest, 1) IN IF ~targetMatchingUnit.ok THEN Fail ELSE
    LET riskGroupIdCnt == ReadUIntLE(targetMatchingUnit.rest, 1) IN IF ~riskGroupIdCnt.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(riskGroupIdCnt.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    Ok([ massCancelId       |-> massCancelId.value,
         clearingFirm       |-> clearingFirm.value,
         massCancelInst     |-> massCancelInst.value,
         symbol             |-> symbol.value,
         targetMatchingUnit |-> targetMatchingUnit.value,
         riskGroupIdCnt     |-> riskGroupIdCnt.value,
         riskGroupId        |-> riskGroupId.value ], riskGroupId.rest)

ZeroPurgeOrdersUsEquitiesV1 ==
    [ massCancelId       |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      massCancelInst     |-> [i \in 1 .. 8 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      targetMatchingUnit |-> [i \in 1 .. 1 |-> 0],
      riskGroupIdCnt     |-> 0,
      riskGroupId        |-> [i \in 1 .. 2 |-> 0] ]

(* Purge Orders Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrdersUsEquitiesV1 ==
    { ZeroPurgeOrdersUsEquitiesV1 }
        \cup { [ZeroPurgeOrdersUsEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeOrdersUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroPurgeOrdersUsEquitiesV1 EXCEPT !.massCancelInst = one] : one \in Sample(8) }
        \cup { [ZeroPurgeOrdersUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroPurgeOrdersUsEquitiesV1 EXCEPT !.targetMatchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroPurgeOrdersUsEquitiesV1 EXCEPT !.riskGroupIdCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroPurgeOrdersUsEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Reset Risk Us Equities V 1: 39 bytes                                    *)
(***************************************************************************)

ResetRiskUsEquitiesV1 ==
    [ riskStatusId       : Sample(16),
      riskReset          : Sample(8),
      clearingFirm       : Sample(4),
      symbol             : Sample(8),
      targetMatchingUnit : Sample(1),
      riskGroupId        : Sample(2) ]

EncodeResetRiskUsEquitiesV1(message) ==
    message.riskStatusId
        \o message.riskReset
        \o message.clearingFirm
        \o message.symbol
        \o message.targetMatchingUnit
        \o message.riskGroupId

DecodeResetRiskUsEquitiesV1(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskReset == ReadBytes(riskStatusId.rest, 8) IN IF ~riskReset.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(riskReset.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET symbol == ReadBytes(clearingFirm.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET targetMatchingUnit == ReadBytes(symbol.rest, 1) IN IF ~targetMatchingUnit.ok THEN Fail ELSE
    LET riskGroupId == ReadBytes(targetMatchingUnit.rest, 2) IN IF ~riskGroupId.ok THEN Fail ELSE
    Ok([ riskStatusId       |-> riskStatusId.value,
         riskReset          |-> riskReset.value,
         clearingFirm       |-> clearingFirm.value,
         symbol             |-> symbol.value,
         targetMatchingUnit |-> targetMatchingUnit.value,
         riskGroupId        |-> riskGroupId.value ], riskGroupId.rest)

ZeroResetRiskUsEquitiesV1 ==
    [ riskStatusId       |-> [i \in 1 .. 16 |-> 0],
      riskReset          |-> [i \in 1 .. 8 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      targetMatchingUnit |-> [i \in 1 .. 1 |-> 0],
      riskGroupId        |-> [i \in 1 .. 2 |-> 0] ]

(* Reset Risk Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskUsEquitiesV1 ==
    { ZeroResetRiskUsEquitiesV1 }
        \cup { [ZeroResetRiskUsEquitiesV1 EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskUsEquitiesV1 EXCEPT !.riskReset = one] : one \in Sample(8) }
        \cup { [ZeroResetRiskUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroResetRiskUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroResetRiskUsEquitiesV1 EXCEPT !.targetMatchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroResetRiskUsEquitiesV1 EXCEPT !.riskGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm Message, selected by Firm Message Type                             *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LogoutRequestCode == 2  \* 0x02
ClientHeartbeatCode == 3  \* 0x03
NewOrderUsEquitiesV1Code == 4001  \* 0xfa1
NewOrderShortUsEquitiesV1Code == 4006  \* 0xfa6
CancelOrderUsEquitiesV1Code == 4003  \* 0xfa3
ModifyOrderUsEquitiesV1Code == 4002  \* 0xfa2
PurgeOrdersUsEquitiesV1Code == 4005  \* 0xfa5
ResetRiskUsEquitiesV1Code == 4004  \* 0xfa4

FirmMessage ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderUsEquitiesV1Code}, body : NewOrderUsEquitiesV1 ]
        \cup [ tag : {NewOrderShortUsEquitiesV1Code}, body : NewOrderShortUsEquitiesV1 ]
        \cup [ tag : {CancelOrderUsEquitiesV1Code}, body : CancelOrderUsEquitiesV1 ]
        \cup [ tag : {ModifyOrderUsEquitiesV1Code}, body : ModifyOrderUsEquitiesV1 ]
        \cup [ tag : {PurgeOrdersUsEquitiesV1Code}, body : PurgeOrdersUsEquitiesV1 ]
        \cup [ tag : {ResetRiskUsEquitiesV1Code}, body : ResetRiskUsEquitiesV1 ]

EncodeFirmMessage(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LogoutRequestCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = NewOrderUsEquitiesV1Code -> EncodeNewOrderUsEquitiesV1(message.body)
      [] message.tag = NewOrderShortUsEquitiesV1Code -> EncodeNewOrderShortUsEquitiesV1(message.body)
      [] message.tag = CancelOrderUsEquitiesV1Code -> EncodeCancelOrderUsEquitiesV1(message.body)
      [] message.tag = ModifyOrderUsEquitiesV1Code -> EncodeModifyOrderUsEquitiesV1(message.body)
      [] message.tag = PurgeOrdersUsEquitiesV1Code -> EncodePurgeOrdersUsEquitiesV1(message.body)
      [] message.tag = ResetRiskUsEquitiesV1Code -> EncodeResetRiskUsEquitiesV1(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderUsEquitiesV1Code -> DecodeNewOrderUsEquitiesV1(bytes)
              [] tag = NewOrderShortUsEquitiesV1Code -> DecodeNewOrderShortUsEquitiesV1(bytes)
              [] tag = CancelOrderUsEquitiesV1Code -> DecodeCancelOrderUsEquitiesV1(bytes)
              [] tag = ModifyOrderUsEquitiesV1Code -> DecodeModifyOrderUsEquitiesV1(bytes)
              [] tag = PurgeOrdersUsEquitiesV1Code -> DecodePurgeOrdersUsEquitiesV1(bytes)
              [] tag = ResetRiskUsEquitiesV1Code -> DecodeResetRiskUsEquitiesV1(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderUsEquitiesV1Code, body |-> one] : one \in CheckedNewOrderUsEquitiesV1 }
        \cup { [tag |-> NewOrderShortUsEquitiesV1Code, body |-> one] : one \in CheckedNewOrderShortUsEquitiesV1 }
        \cup { [tag |-> CancelOrderUsEquitiesV1Code, body |-> one] : one \in CheckedCancelOrderUsEquitiesV1 }
        \cup { [tag |-> ModifyOrderUsEquitiesV1Code, body |-> one] : one \in CheckedModifyOrderUsEquitiesV1 }
        \cup { [tag |-> PurgeOrdersUsEquitiesV1Code, body |-> one] : one \in CheckedPurgeOrdersUsEquitiesV1 }
        \cup { [tag |-> ResetRiskUsEquitiesV1Code, body |-> one] : one \in CheckedResetRiskUsEquitiesV1 }

(***************************************************************************)
(* Firm Packet                                                             *)
(***************************************************************************)

FirmPacket ==
    [ startOfMessage : Sample(2),
      messageLength  : Sample(2),
      matchingUnit   : Sample(1),
      reservedField  : Sample(1),
      sequenceNumber : Sample(4),
      firmMessage    : FirmMessage ]

EncodeFirmPacket(message) ==
    message.startOfMessage
        \o message.messageLength
        \o EncodeUIntLE(message.firmMessage.tag, 2)
        \o message.matchingUnit
        \o message.reservedField
        \o message.sequenceNumber
        \o EncodeFirmMessage(message.firmMessage)

DecodeFirmPacket(bytes) ==
    LET startOfMessage == ReadBytes(bytes, 2) IN IF ~startOfMessage.ok THEN Fail ELSE
    LET messageLength == ReadBytes(startOfMessage.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET firmMessageType == ReadUIntLE(messageLength.rest, 2) IN IF ~firmMessageType.ok THEN Fail ELSE
    LET matchingUnit == ReadBytes(firmMessageType.rest, 1) IN IF ~matchingUnit.ok THEN Fail ELSE
    LET reservedField == ReadBytes(matchingUnit.rest, 1) IN IF ~reservedField.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(reservedField.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET firmMessage == DecodeFirmMessage(firmMessageType.value, sequenceNumber.rest) IN IF ~firmMessage.ok THEN Fail ELSE
    Ok([ startOfMessage |-> startOfMessage.value,
         messageLength  |-> messageLength.value,
         matchingUnit   |-> matchingUnit.value,
         reservedField  |-> reservedField.value,
         sequenceNumber |-> sequenceNumber.value,
         firmMessage    |-> firmMessage.value ], firmMessage.rest)

ZeroFirmPacket ==
    [ startOfMessage |-> [i \in 1 .. 2 |-> 0],
      messageLength  |-> [i \in 1 .. 2 |-> 0],
      matchingUnit   |-> [i \in 1 .. 1 |-> 0],
      reservedField  |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      firmMessage    |-> ZeroFirmMessage ]

(* Firm Packet at zero, then each field in turn at the values it is checked at *)
CheckedFirmPacket ==
    { ZeroFirmPacket }
        \cup { [ZeroFirmPacket EXCEPT !.startOfMessage = one] : one \in Sample(2) }
        \cup { [ZeroFirmPacket EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroFirmPacket EXCEPT !.matchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroFirmPacket EXCEPT !.reservedField = one] : one \in Sample(1) }
        \cup { [ZeroFirmPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroFirmPacket EXCEPT !.firmMessage = one] : one \in CheckedFirmMessage }

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

(* Every Unit Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitSequence ==
    \A message \in CheckedUnitSequence :
        LET read == DecodeUnitSequence(EncodeUnitSequence(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderUsEquitiesV1 ==
    \A message \in CheckedNewOrderUsEquitiesV1 :
        LET read == DecodeNewOrderUsEquitiesV1(EncodeNewOrderUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Short Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderShortUsEquitiesV1 ==
    \A message \in CheckedNewOrderShortUsEquitiesV1 :
        LET read == DecodeNewOrderShortUsEquitiesV1(EncodeNewOrderShortUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderUsEquitiesV1 ==
    \A message \in CheckedCancelOrderUsEquitiesV1 :
        LET read == DecodeCancelOrderUsEquitiesV1(EncodeCancelOrderUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderUsEquitiesV1 ==
    \A message \in CheckedModifyOrderUsEquitiesV1 :
        LET read == DecodeModifyOrderUsEquitiesV1(EncodeModifyOrderUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Orders Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrdersUsEquitiesV1 ==
    \A message \in CheckedPurgeOrdersUsEquitiesV1 :
        LET read == DecodePurgeOrdersUsEquitiesV1(EncodePurgeOrdersUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskUsEquitiesV1 ==
    \A message \in CheckedResetRiskUsEquitiesV1 :
        LET read == DecodeResetRiskUsEquitiesV1(EncodeResetRiskUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmPacket ==
    \A message \in CheckedFirmPacket :
        LET read == DecodeFirmPacket(EncodeFirmPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Firm Message is selected by the Firm Message Type it is written under *)
SelectsFirmMessage ==
    \A message \in CheckedFirmMessage :
        LET read == DecodeFirmMessage(message.tag, EncodeFirmMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
