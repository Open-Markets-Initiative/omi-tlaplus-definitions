-------------- MODULE C1Options_BinaryOrderEntry_v1_1_23_Firm --------------
(***************************************************************************)
(* Chicago Board Options Exchange Binary Order Entry v1.1.23               *)
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
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch ==
    { ZeroPreventMatch }
        \cup { [ZeroPreventMatch EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Message: 193 bytes                                            *)
(***************************************************************************)

NewOrderMessage ==
    [ clOrdId              : Sample(20),
      side                 : Sample(1),
      orderQty             : Sample(4),
      clearingFirm         : Sample(4),
      clearingAccount      : Sample(4),
      price                : Sample(8),
      execInst             : Sample(1),
      ordType              : Sample(1),
      timeInForce          : Sample(1),
      minQty               : Sample(4),
      maxFloor             : Sample(4),
      symbol               : Sample(8),
      capacity             : Sample(1),
      routingInst          : Sample(4),
      account              : Sample(16),
      displayIndicator     : Sample(1),
      preventMatch         : PreventMatch,
      expireTime           : Sample(8),
      maturityDate         : Sample(4),
      strikePrice          : Sample(8),
      putOrCall            : Sample(1),
      openClose            : Sample(1),
      cmtaNumber           : Sample(4),
      targetPartyId        : Sample(4),
      sessionEligibility   : Sample(1),
      attributedQuote      : Sample(1),
      displayRange         : Sample(4),
      stopPx               : Sample(8),
      routStrategy         : Sample(6),
      routeDeliveryMethod  : Sample(3),
      exDestination        : Sample(1),
      auctionId            : Sample(8),
      routingFirmId        : Sample(4),
      customGroupId        : Sample(2),
      clearingOptionalData : Sample(16),
      clientIdAttr         : Sample(4),
      frequentTraderId     : Sample(6),
      compression          : Sample(1),
      floorDestination     : Sample(4),
      floorRoutingInst     : Sample(1),
      orderOrigin          : Sample(3),
      orderRouterSubsidy   : Sample(1),
      priceType            : Sample(1),
      held                 : Sample(1),
      scratchPad           : Sample(2) ]

EncodeNewOrderMessage(message) ==
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
        \o EncodePreventMatch(message.preventMatch)
        \o message.expireTime
        \o message.maturityDate
        \o message.strikePrice
        \o message.putOrCall
        \o message.openClose
        \o message.cmtaNumber
        \o message.targetPartyId
        \o message.sessionEligibility
        \o message.attributedQuote
        \o message.displayRange
        \o message.stopPx
        \o message.routStrategy
        \o message.routeDeliveryMethod
        \o message.exDestination
        \o message.auctionId
        \o message.routingFirmId
        \o message.customGroupId
        \o message.clearingOptionalData
        \o message.clientIdAttr
        \o message.frequentTraderId
        \o message.compression
        \o message.floorDestination
        \o message.floorRoutingInst
        \o message.orderOrigin
        \o message.orderRouterSubsidy
        \o message.priceType
        \o message.held
        \o message.scratchPad

DecodeNewOrderMessage(bytes) ==
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
    LET preventMatch == DecodePreventMatch(displayIndicator.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET expireTime == ReadBytes(preventMatch.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(expireTime.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(maturityDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(strikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadBytes(putOrCall.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(openClose.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(cmtaNumber.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(targetPartyId.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(sessionEligibility.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET displayRange == ReadBytes(attributedQuote.rest, 4) IN IF ~displayRange.ok THEN Fail ELSE
    LET stopPx == ReadBytes(displayRange.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET routStrategy == ReadBytes(stopPx.rest, 6) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadBytes(routStrategy.rest, 3) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadBytes(routeDeliveryMethod.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET auctionId == ReadBytes(exDestination.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(auctionId.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(routingFirmId.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET clearingOptionalData == ReadBytes(customGroupId.rest, 16) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET clientIdAttr == ReadBytes(clearingOptionalData.rest, 4) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(clientIdAttr.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET compression == ReadBytes(frequentTraderId.rest, 1) IN IF ~compression.ok THEN Fail ELSE
    LET floorDestination == ReadBytes(compression.rest, 4) IN IF ~floorDestination.ok THEN Fail ELSE
    LET floorRoutingInst == ReadBytes(floorDestination.rest, 1) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(floorRoutingInst.rest, 3) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET orderRouterSubsidy == ReadBytes(orderOrigin.rest, 1) IN IF ~orderRouterSubsidy.ok THEN Fail ELSE
    LET priceType == ReadBytes(orderRouterSubsidy.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET held == ReadBytes(priceType.rest, 1) IN IF ~held.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(held.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ clOrdId              |-> clOrdId.value,
         side                 |-> side.value,
         orderQty             |-> orderQty.value,
         clearingFirm         |-> clearingFirm.value,
         clearingAccount      |-> clearingAccount.value,
         price                |-> price.value,
         execInst             |-> execInst.value,
         ordType              |-> ordType.value,
         timeInForce          |-> timeInForce.value,
         minQty               |-> minQty.value,
         maxFloor             |-> maxFloor.value,
         symbol               |-> symbol.value,
         capacity             |-> capacity.value,
         routingInst          |-> routingInst.value,
         account              |-> account.value,
         displayIndicator     |-> displayIndicator.value,
         preventMatch         |-> preventMatch.value,
         expireTime           |-> expireTime.value,
         maturityDate         |-> maturityDate.value,
         strikePrice          |-> strikePrice.value,
         putOrCall            |-> putOrCall.value,
         openClose            |-> openClose.value,
         cmtaNumber           |-> cmtaNumber.value,
         targetPartyId        |-> targetPartyId.value,
         sessionEligibility   |-> sessionEligibility.value,
         attributedQuote      |-> attributedQuote.value,
         displayRange         |-> displayRange.value,
         stopPx               |-> stopPx.value,
         routStrategy         |-> routStrategy.value,
         routeDeliveryMethod  |-> routeDeliveryMethod.value,
         exDestination        |-> exDestination.value,
         auctionId            |-> auctionId.value,
         routingFirmId        |-> routingFirmId.value,
         customGroupId        |-> customGroupId.value,
         clearingOptionalData |-> clearingOptionalData.value,
         clientIdAttr         |-> clientIdAttr.value,
         frequentTraderId     |-> frequentTraderId.value,
         compression          |-> compression.value,
         floorDestination     |-> floorDestination.value,
         floorRoutingInst     |-> floorRoutingInst.value,
         orderOrigin          |-> orderOrigin.value,
         orderRouterSubsidy   |-> orderRouterSubsidy.value,
         priceType            |-> priceType.value,
         held                 |-> held.value,
         scratchPad           |-> scratchPad.value ], scratchPad.rest)

ZeroNewOrderMessage ==
    [ clOrdId              |-> [i \in 1 .. 20 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      clearingAccount      |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      execInst             |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      minQty               |-> [i \in 1 .. 4 |-> 0],
      maxFloor             |-> [i \in 1 .. 4 |-> 0],
      symbol               |-> [i \in 1 .. 8 |-> 0],
      capacity             |-> [i \in 1 .. 1 |-> 0],
      routingInst          |-> [i \in 1 .. 4 |-> 0],
      account              |-> [i \in 1 .. 16 |-> 0],
      displayIndicator     |-> [i \in 1 .. 1 |-> 0],
      preventMatch         |-> ZeroPreventMatch,
      expireTime           |-> [i \in 1 .. 8 |-> 0],
      maturityDate         |-> [i \in 1 .. 4 |-> 0],
      strikePrice          |-> [i \in 1 .. 8 |-> 0],
      putOrCall            |-> [i \in 1 .. 1 |-> 0],
      openClose            |-> [i \in 1 .. 1 |-> 0],
      cmtaNumber           |-> [i \in 1 .. 4 |-> 0],
      targetPartyId        |-> [i \in 1 .. 4 |-> 0],
      sessionEligibility   |-> [i \in 1 .. 1 |-> 0],
      attributedQuote      |-> [i \in 1 .. 1 |-> 0],
      displayRange         |-> [i \in 1 .. 4 |-> 0],
      stopPx               |-> [i \in 1 .. 8 |-> 0],
      routStrategy         |-> [i \in 1 .. 6 |-> 0],
      routeDeliveryMethod  |-> [i \in 1 .. 3 |-> 0],
      exDestination        |-> [i \in 1 .. 1 |-> 0],
      auctionId            |-> [i \in 1 .. 8 |-> 0],
      routingFirmId        |-> [i \in 1 .. 4 |-> 0],
      customGroupId        |-> [i \in 1 .. 2 |-> 0],
      clearingOptionalData |-> [i \in 1 .. 16 |-> 0],
      clientIdAttr         |-> [i \in 1 .. 4 |-> 0],
      frequentTraderId     |-> [i \in 1 .. 6 |-> 0],
      compression          |-> [i \in 1 .. 1 |-> 0],
      floorDestination     |-> [i \in 1 .. 4 |-> 0],
      floorRoutingInst     |-> [i \in 1 .. 1 |-> 0],
      orderOrigin          |-> [i \in 1 .. 3 |-> 0],
      orderRouterSubsidy   |-> [i \in 1 .. 1 |-> 0],
      priceType            |-> [i \in 1 .. 1 |-> 0],
      held                 |-> [i \in 1 .. 1 |-> 0],
      scratchPad           |-> [i \in 1 .. 2 |-> 0] ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.routingInst = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderMessage EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch }
        \cup { [ZeroNewOrderMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.displayRange = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.routStrategy = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderMessage EXCEPT !.routeDeliveryMethod = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderMessage EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clearingOptionalData = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clientIdAttr = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderMessage EXCEPT !.compression = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.floorDestination = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.floorRoutingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderOrigin = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderRouterSubsidy = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.held = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch2 ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch2(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch2(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch2 ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch2 ==
    { ZeroPreventMatch2 }
        \cup { [ZeroPreventMatch2 EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch2 EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch2 EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Short Message: 117 bytes                                      *)
(***************************************************************************)

NewOrderShortMessage ==
    [ clOrdId            : Sample(20),
      side               : Sample(1),
      orderQty           : Sample(4),
      clearingFirm       : Sample(4),
      clearingAccount    : Sample(4),
      price              : Sample(8),
      execInst           : Sample(1),
      ordType            : Sample(1),
      timeInForce        : Sample(1),
      minQty             : Sample(4),
      maxFloor           : Sample(4),
      symbol             : Sample(8),
      capacity           : Sample(1),
      routingInst        : Sample(4),
      account            : Sample(16),
      displayIndicator   : Sample(1),
      preventMatch       : PreventMatch2,
      openClose          : Sample(1),
      cmtaNumber         : Sample(4),
      sessionEligibility : Sample(1),
      attributedQuote    : Sample(1),
      routStrategy       : Sample(6),
      exDestination      : Sample(1),
      auctionId          : Sample(8),
      customGroupId      : Sample(2),
      frequentTraderId   : Sample(6),
      scratchPad         : Sample(2) ]

EncodeNewOrderShortMessage(message) ==
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
        \o EncodePreventMatch2(message.preventMatch)
        \o message.openClose
        \o message.cmtaNumber
        \o message.sessionEligibility
        \o message.attributedQuote
        \o message.routStrategy
        \o message.exDestination
        \o message.auctionId
        \o message.customGroupId
        \o message.frequentTraderId
        \o message.scratchPad

DecodeNewOrderShortMessage(bytes) ==
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
    LET preventMatch == DecodePreventMatch2(displayIndicator.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET openClose == ReadBytes(preventMatch.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(openClose.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(cmtaNumber.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(sessionEligibility.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET routStrategy == ReadBytes(attributedQuote.rest, 6) IN IF ~routStrategy.ok THEN Fail ELSE
    LET exDestination == ReadBytes(routStrategy.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET auctionId == ReadBytes(exDestination.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(auctionId.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(customGroupId.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(frequentTraderId.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ clOrdId            |-> clOrdId.value,
         side               |-> side.value,
         orderQty           |-> orderQty.value,
         clearingFirm       |-> clearingFirm.value,
         clearingAccount    |-> clearingAccount.value,
         price              |-> price.value,
         execInst           |-> execInst.value,
         ordType            |-> ordType.value,
         timeInForce        |-> timeInForce.value,
         minQty             |-> minQty.value,
         maxFloor           |-> maxFloor.value,
         symbol             |-> symbol.value,
         capacity           |-> capacity.value,
         routingInst        |-> routingInst.value,
         account            |-> account.value,
         displayIndicator   |-> displayIndicator.value,
         preventMatch       |-> preventMatch.value,
         openClose          |-> openClose.value,
         cmtaNumber         |-> cmtaNumber.value,
         sessionEligibility |-> sessionEligibility.value,
         attributedQuote    |-> attributedQuote.value,
         routStrategy       |-> routStrategy.value,
         exDestination      |-> exDestination.value,
         auctionId          |-> auctionId.value,
         customGroupId      |-> customGroupId.value,
         frequentTraderId   |-> frequentTraderId.value,
         scratchPad         |-> scratchPad.value ], scratchPad.rest)

ZeroNewOrderShortMessage ==
    [ clOrdId            |-> [i \in 1 .. 20 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      execInst           |-> [i \in 1 .. 1 |-> 0],
      ordType            |-> [i \in 1 .. 1 |-> 0],
      timeInForce        |-> [i \in 1 .. 1 |-> 0],
      minQty             |-> [i \in 1 .. 4 |-> 0],
      maxFloor           |-> [i \in 1 .. 4 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      routingInst        |-> [i \in 1 .. 4 |-> 0],
      account            |-> [i \in 1 .. 16 |-> 0],
      displayIndicator   |-> [i \in 1 .. 1 |-> 0],
      preventMatch       |-> ZeroPreventMatch2,
      openClose          |-> [i \in 1 .. 1 |-> 0],
      cmtaNumber         |-> [i \in 1 .. 4 |-> 0],
      sessionEligibility |-> [i \in 1 .. 1 |-> 0],
      attributedQuote    |-> [i \in 1 .. 1 |-> 0],
      routStrategy       |-> [i \in 1 .. 6 |-> 0],
      exDestination      |-> [i \in 1 .. 1 |-> 0],
      auctionId          |-> [i \in 1 .. 8 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      frequentTraderId   |-> [i \in 1 .. 6 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0] ]

(* New Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderShortMessage ==
    { ZeroNewOrderShortMessage }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.routingInst = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch2 }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.routStrategy = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderShortMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch3 ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch3(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch3(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch3 ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch3 ==
    { ZeroPreventMatch3 }
        \cup { [ZeroPreventMatch3 EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch3 EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch3 EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* Allocation: 77 bytes                                                    *)
(***************************************************************************)

Allocation ==
    [ side                 : Sample(1),
      allocQty             : Sample(4),
      clOrdId              : Sample(20),
      capacity             : Sample(1),
      openClose            : Sample(1),
      giveUpFirmId         : Sample(4),
      account              : Sample(16),
      cmtaNumber           : Sample(4),
      clearingAccount      : Sample(4),
      clearingOptionalData : Sample(16),
      frequentTraderId     : Sample(6) ]

EncodeAllocation(message) ==
    message.side
        \o message.allocQty
        \o message.clOrdId
        \o message.capacity
        \o message.openClose
        \o message.giveUpFirmId
        \o message.account
        \o message.cmtaNumber
        \o message.clearingAccount
        \o message.clearingOptionalData
        \o message.frequentTraderId

DecodeAllocation(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET allocQty == ReadBytes(side.rest, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(allocQty.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET capacity == ReadBytes(clOrdId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET openClose == ReadBytes(capacity.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET giveUpFirmId == ReadBytes(openClose.rest, 4) IN IF ~giveUpFirmId.ok THEN Fail ELSE
    LET account == ReadBytes(giveUpFirmId.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(account.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(cmtaNumber.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET clearingOptionalData == ReadBytes(clearingAccount.rest, 16) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(clearingOptionalData.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    Ok([ side                 |-> side.value,
         allocQty             |-> allocQty.value,
         clOrdId              |-> clOrdId.value,
         capacity             |-> capacity.value,
         openClose            |-> openClose.value,
         giveUpFirmId         |-> giveUpFirmId.value,
         account              |-> account.value,
         cmtaNumber           |-> cmtaNumber.value,
         clearingAccount      |-> clearingAccount.value,
         clearingOptionalData |-> clearingOptionalData.value,
         frequentTraderId     |-> frequentTraderId.value ], frequentTraderId.rest)

ZeroAllocation ==
    [ side                 |-> [i \in 1 .. 1 |-> 0],
      allocQty             |-> [i \in 1 .. 4 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      capacity             |-> [i \in 1 .. 1 |-> 0],
      openClose            |-> [i \in 1 .. 1 |-> 0],
      giveUpFirmId         |-> [i \in 1 .. 4 |-> 0],
      account              |-> [i \in 1 .. 16 |-> 0],
      cmtaNumber           |-> [i \in 1 .. 4 |-> 0],
      clearingAccount      |-> [i \in 1 .. 4 |-> 0],
      clearingOptionalData |-> [i \in 1 .. 16 |-> 0],
      frequentTraderId     |-> [i \in 1 .. 6 |-> 0] ]

(* Allocation at zero, then each field in turn at the values it is checked at *)
CheckedAllocation ==
    { ZeroAllocation }
        \cup { [ZeroAllocation EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroAllocation EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroAllocation EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.giveUpFirmId = one] : one \in Sample(4) }
        \cup { [ZeroAllocation EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroAllocation EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroAllocation EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroAllocation EXCEPT !.clearingOptionalData = one] : one \in Sample(16) }
        \cup { [ZeroAllocation EXCEPT !.frequentTraderId = one] : one \in Sample(6) }

(* A run of Allocation, written one after another *)
RECURSIVE EncodeAllocationList(_)
EncodeAllocationList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAllocation(Head(messages)) \o EncodeAllocationList(Tail(messages))

(* As many Allocation as the field that counts them says *)
RECURSIVE ReadAllocationList(_, _)
ReadAllocationList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAllocation(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAllocationList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Allocation of each kind, for the lists that carry them *)
OneAllocation == { ZeroAllocation }

(***************************************************************************)
(* New Order Cross Message                                                 *)
(***************************************************************************)

NewOrderCrossMessage ==
    [ crossId                : Sample(20),
      crossType              : Sample(1),
      crossPrioritization    : Sample(1),
      price                  : Sample(8),
      orderQty               : Sample(4),
      symbol                 : Sample(8),
      maturityDate           : Sample(4),
      strikePrice            : Sample(8),
      putOrCall              : Sample(1),
      execInst               : Sample(1),
      attributedQuote        : Sample(1),
      targetPartyId          : Sample(4),
      preventMatch           : PreventMatch3,
      autoMatch              : Sample(1),
      autoMatchPrice         : Sample(8),
      lastPriority           : Sample(1),
      routingFirmId          : Sample(4),
      clientIdAttr           : Sample(4),
      equityTradePrice       : Sample(8),
      equityTradeSize        : Sample(4),
      equityTradeVenue       : Sample(1),
      equityTransactTime     : Sample(8),
      equityBuyClearingFirm  : Sample(4),
      equitySellClearingFirm : Sample(4),
      compression            : Sample(1),
      orderRouterSubsidy     : Sample(1),
      scratchPad             : Sample(2),
      allocation             : SampleLists(OneAllocation) ]

EncodeNewOrderCrossMessage(message) ==
    message.crossId
        \o message.crossType
        \o message.crossPrioritization
        \o message.price
        \o message.orderQty
        \o message.symbol
        \o message.maturityDate
        \o message.strikePrice
        \o message.putOrCall
        \o message.execInst
        \o message.attributedQuote
        \o message.targetPartyId
        \o EncodePreventMatch3(message.preventMatch)
        \o message.autoMatch
        \o message.autoMatchPrice
        \o message.lastPriority
        \o message.routingFirmId
        \o message.clientIdAttr
        \o message.equityTradePrice
        \o message.equityTradeSize
        \o message.equityTradeVenue
        \o message.equityTransactTime
        \o message.equityBuyClearingFirm
        \o message.equitySellClearingFirm
        \o message.compression
        \o message.orderRouterSubsidy
        \o message.scratchPad
        \o EncodeUIntLE(Len(message.allocation), 1)
        \o EncodeAllocationList(message.allocation)

DecodeNewOrderCrossMessage(bytes) ==
    LET crossId == ReadBytes(bytes, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET crossPrioritization == ReadBytes(crossType.rest, 1) IN IF ~crossPrioritization.ok THEN Fail ELSE
    LET price == ReadBytes(crossPrioritization.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderQty.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(symbol.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(maturityDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(strikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET execInst == ReadBytes(putOrCall.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(execInst.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(attributedQuote.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch3(targetPartyId.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET autoMatch == ReadBytes(preventMatch.rest, 1) IN IF ~autoMatch.ok THEN Fail ELSE
    LET autoMatchPrice == ReadBytes(autoMatch.rest, 8) IN IF ~autoMatchPrice.ok THEN Fail ELSE
    LET lastPriority == ReadBytes(autoMatchPrice.rest, 1) IN IF ~lastPriority.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(lastPriority.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET clientIdAttr == ReadBytes(routingFirmId.rest, 4) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET equityTradePrice == ReadBytes(clientIdAttr.rest, 8) IN IF ~equityTradePrice.ok THEN Fail ELSE
    LET equityTradeSize == ReadBytes(equityTradePrice.rest, 4) IN IF ~equityTradeSize.ok THEN Fail ELSE
    LET equityTradeVenue == ReadBytes(equityTradeSize.rest, 1) IN IF ~equityTradeVenue.ok THEN Fail ELSE
    LET equityTransactTime == ReadBytes(equityTradeVenue.rest, 8) IN IF ~equityTransactTime.ok THEN Fail ELSE
    LET equityBuyClearingFirm == ReadBytes(equityTransactTime.rest, 4) IN IF ~equityBuyClearingFirm.ok THEN Fail ELSE
    LET equitySellClearingFirm == ReadBytes(equityBuyClearingFirm.rest, 4) IN IF ~equitySellClearingFirm.ok THEN Fail ELSE
    LET compression == ReadBytes(equitySellClearingFirm.rest, 1) IN IF ~compression.ok THEN Fail ELSE
    LET orderRouterSubsidy == ReadBytes(compression.rest, 1) IN IF ~orderRouterSubsidy.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(orderRouterSubsidy.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET allocCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~allocCnt.ok THEN Fail ELSE
    LET allocation == ReadAllocationList(allocCnt.rest, allocCnt.value) IN IF ~allocation.ok THEN Fail ELSE
    Ok([ crossId                |-> crossId.value,
         crossType              |-> crossType.value,
         crossPrioritization    |-> crossPrioritization.value,
         price                  |-> price.value,
         orderQty               |-> orderQty.value,
         symbol                 |-> symbol.value,
         maturityDate           |-> maturityDate.value,
         strikePrice            |-> strikePrice.value,
         putOrCall              |-> putOrCall.value,
         execInst               |-> execInst.value,
         attributedQuote        |-> attributedQuote.value,
         targetPartyId          |-> targetPartyId.value,
         preventMatch           |-> preventMatch.value,
         autoMatch              |-> autoMatch.value,
         autoMatchPrice         |-> autoMatchPrice.value,
         lastPriority           |-> lastPriority.value,
         routingFirmId          |-> routingFirmId.value,
         clientIdAttr           |-> clientIdAttr.value,
         equityTradePrice       |-> equityTradePrice.value,
         equityTradeSize        |-> equityTradeSize.value,
         equityTradeVenue       |-> equityTradeVenue.value,
         equityTransactTime     |-> equityTransactTime.value,
         equityBuyClearingFirm  |-> equityBuyClearingFirm.value,
         equitySellClearingFirm |-> equitySellClearingFirm.value,
         compression            |-> compression.value,
         orderRouterSubsidy     |-> orderRouterSubsidy.value,
         scratchPad             |-> scratchPad.value,
         allocation             |-> allocation.value ], allocation.rest)

ZeroNewOrderCrossMessage ==
    [ crossId                |-> [i \in 1 .. 20 |-> 0],
      crossType              |-> [i \in 1 .. 1 |-> 0],
      crossPrioritization    |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      maturityDate           |-> [i \in 1 .. 4 |-> 0],
      strikePrice            |-> [i \in 1 .. 8 |-> 0],
      putOrCall              |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      attributedQuote        |-> [i \in 1 .. 1 |-> 0],
      targetPartyId          |-> [i \in 1 .. 4 |-> 0],
      preventMatch           |-> ZeroPreventMatch3,
      autoMatch              |-> [i \in 1 .. 1 |-> 0],
      autoMatchPrice         |-> [i \in 1 .. 8 |-> 0],
      lastPriority           |-> [i \in 1 .. 1 |-> 0],
      routingFirmId          |-> [i \in 1 .. 4 |-> 0],
      clientIdAttr           |-> [i \in 1 .. 4 |-> 0],
      equityTradePrice       |-> [i \in 1 .. 8 |-> 0],
      equityTradeSize        |-> [i \in 1 .. 4 |-> 0],
      equityTradeVenue       |-> [i \in 1 .. 1 |-> 0],
      equityTransactTime     |-> [i \in 1 .. 8 |-> 0],
      equityBuyClearingFirm  |-> [i \in 1 .. 4 |-> 0],
      equitySellClearingFirm |-> [i \in 1 .. 4 |-> 0],
      compression            |-> [i \in 1 .. 1 |-> 0],
      orderRouterSubsidy     |-> [i \in 1 .. 1 |-> 0],
      scratchPad             |-> [i \in 1 .. 2 |-> 0],
      allocation             |-> << >> ]

(* New Order Cross Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossMessage ==
    { ZeroNewOrderCrossMessage }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.crossPrioritization = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch3 }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.autoMatch = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.autoMatchPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.lastPriority = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.clientIdAttr = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.equityTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.equityTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.equityTradeVenue = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.equityTransactTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.equityBuyClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.equitySellClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.compression = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.orderRouterSubsidy = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossMessage EXCEPT !.allocation = one] : one \in SampleLists(OneAllocation) }

(***************************************************************************)
(* Complex Leg: 27 bytes                                                   *)
(***************************************************************************)

ComplexLeg ==
    [ symbol       : Sample(8),
      maturityDate : Sample(4),
      strikePrice  : Sample(8),
      cfiCode      : Sample(2),
      ratioQty     : Sample(4),
      side         : Sample(1) ]

EncodeComplexLeg(message) ==
    message.symbol
        \o message.maturityDate
        \o message.strikePrice
        \o message.cfiCode
        \o message.ratioQty
        \o message.side

DecodeComplexLeg(bytes) ==
    LET symbol == ReadBytes(bytes, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(symbol.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(maturityDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(strikePrice.rest, 2) IN IF ~cfiCode.ok THEN Fail ELSE
    LET ratioQty == ReadBytes(cfiCode.rest, 4) IN IF ~ratioQty.ok THEN Fail ELSE
    LET side == ReadBytes(ratioQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ symbol       |-> symbol.value,
         maturityDate |-> maturityDate.value,
         strikePrice  |-> strikePrice.value,
         cfiCode      |-> cfiCode.value,
         ratioQty     |-> ratioQty.value,
         side         |-> side.value ], side.rest)

ZeroComplexLeg ==
    [ symbol       |-> [i \in 1 .. 8 |-> 0],
      maturityDate |-> [i \in 1 .. 4 |-> 0],
      strikePrice  |-> [i \in 1 .. 8 |-> 0],
      cfiCode      |-> [i \in 1 .. 2 |-> 0],
      ratioQty     |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Leg at zero, then each field in turn at the values it is checked at *)
CheckedComplexLeg ==
    { ZeroComplexLeg }
        \cup { [ZeroComplexLeg EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroComplexLeg EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroComplexLeg EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroComplexLeg EXCEPT !.cfiCode = one] : one \in Sample(2) }
        \cup { [ZeroComplexLeg EXCEPT !.ratioQty = one] : one \in Sample(4) }
        \cup { [ZeroComplexLeg EXCEPT !.side = one] : one \in Sample(1) }

(* A run of Complex Leg, written one after another *)
RECURSIVE EncodeComplexLegList(_)
EncodeComplexLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexLeg(Head(messages)) \o EncodeComplexLegList(Tail(messages))

(* As many Complex Leg as the field that counts them says *)
RECURSIVE ReadComplexLegList(_, _)
ReadComplexLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Leg of each kind, for the lists that carry them *)
OneComplexLeg == { ZeroComplexLeg }

(***************************************************************************)
(* New Complex Instrument Message                                          *)
(***************************************************************************)

NewComplexInstrumentMessage ==
    [ clOrdId      : Sample(20),
      clearingFirm : Sample(4),
      scratchPad   : Sample(2),
      complexLeg   : SampleLists(OneComplexLeg) ]

EncodeNewComplexInstrumentMessage(message) ==
    message.clOrdId
        \o message.clearingFirm
        \o message.scratchPad
        \o EncodeUIntLE(Len(message.complexLeg), 1)
        \o EncodeComplexLegList(message.complexLeg)

DecodeNewComplexInstrumentMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(clearingFirm.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET complexLeg == ReadComplexLegList(legCnt.rest, legCnt.value) IN IF ~complexLeg.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         clearingFirm |-> clearingFirm.value,
         scratchPad   |-> scratchPad.value,
         complexLeg   |-> complexLeg.value ], complexLeg.rest)

ZeroNewComplexInstrumentMessage ==
    [ clOrdId      |-> [i \in 1 .. 20 |-> 0],
      clearingFirm |-> [i \in 1 .. 4 |-> 0],
      scratchPad   |-> [i \in 1 .. 2 |-> 0],
      complexLeg   |-> << >> ]

(* New Complex Instrument Message at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexInstrumentMessage ==
    { ZeroNewComplexInstrumentMessage }
        \cup { [ZeroNewComplexInstrumentMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexInstrumentMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexInstrumentMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexInstrumentMessage EXCEPT !.complexLeg = one] : one \in SampleLists(OneComplexLeg) }

(***************************************************************************)
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch4 ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch4(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch4(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch4 ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch4 ==
    { ZeroPreventMatch4 }
        \cup { [ZeroPreventMatch4 EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch4 EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch4 EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* New Complex Order Message: 184 bytes                                    *)
(***************************************************************************)

NewComplexOrderMessage ==
    [ clOrdId              : Sample(20),
      side                 : Sample(1),
      orderQty             : Sample(4),
      clearingFirm         : Sample(4),
      clearingAccount      : Sample(4),
      price                : Sample(8),
      execInst             : Sample(1),
      ordType              : Sample(1),
      timeInForce          : Sample(1),
      symbol               : Sample(8),
      capacity             : Sample(1),
      routingInst          : Sample(4),
      account              : Sample(16),
      preventMatch         : PreventMatch4,
      expireTime           : Sample(8),
      cmtaNumber           : Sample(4),
      targetPartyId        : Sample(4),
      attributedQuote      : Sample(1),
      auctionId            : Sample(8),
      routingFirmId        : Sample(4),
      drillThruProtection  : Sample(8),
      useDrillThruOverride : Sample(1),
      customGroupId        : Sample(2),
      equityPartyId        : Sample(4),
      clearingOptionalData : Sample(16),
      clientIdAttr         : Sample(4),
      frequentTraderId     : Sample(6),
      sessionEligibility   : Sample(1),
      maxFloor             : Sample(4),
      displayRange         : Sample(4),
      comboOrder           : Sample(1),
      compression          : Sample(1),
      equityExDestination  : Sample(1),
      equityLegShortSell   : Sample(1),
      floorDestination     : Sample(4),
      floorRoutingInst     : Sample(1),
      orderOrigin          : Sample(3),
      orderRouterSubsidy   : Sample(1),
      priceType            : Sample(1),
      strategyId           : Sample(1),
      tiedHedge            : Sample(1),
      held                 : Sample(1),
      crossInitiator       : Sample(4),
      crossOnBehalfOfId    : Sample(4),
      scratchPad           : Sample(2),
      legCnt               : 0 .. 255,
      legPositionEffect    : Sample(1) ]

EncodeNewComplexOrderMessage(message) ==
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
        \o message.routingInst
        \o message.account
        \o EncodePreventMatch4(message.preventMatch)
        \o message.expireTime
        \o message.cmtaNumber
        \o message.targetPartyId
        \o message.attributedQuote
        \o message.auctionId
        \o message.routingFirmId
        \o message.drillThruProtection
        \o message.useDrillThruOverride
        \o message.customGroupId
        \o message.equityPartyId
        \o message.clearingOptionalData
        \o message.clientIdAttr
        \o message.frequentTraderId
        \o message.sessionEligibility
        \o message.maxFloor
        \o message.displayRange
        \o message.comboOrder
        \o message.compression
        \o message.equityExDestination
        \o message.equityLegShortSell
        \o message.floorDestination
        \o message.floorRoutingInst
        \o message.orderOrigin
        \o message.orderRouterSubsidy
        \o message.priceType
        \o message.strategyId
        \o message.tiedHedge
        \o message.held
        \o message.crossInitiator
        \o message.crossOnBehalfOfId
        \o message.scratchPad
        \o EncodeUIntLE(message.legCnt, 1)
        \o message.legPositionEffect

DecodeNewComplexOrderMessage(bytes) ==
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
    LET routingInst == ReadBytes(capacity.rest, 4) IN IF ~routingInst.ok THEN Fail ELSE
    LET account == ReadBytes(routingInst.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch4(account.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET expireTime == ReadBytes(preventMatch.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(expireTime.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(cmtaNumber.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(targetPartyId.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET auctionId == ReadBytes(attributedQuote.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(auctionId.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET drillThruProtection == ReadBytes(routingFirmId.rest, 8) IN IF ~drillThruProtection.ok THEN Fail ELSE
    LET useDrillThruOverride == ReadBytes(drillThruProtection.rest, 1) IN IF ~useDrillThruOverride.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(useDrillThruOverride.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET equityPartyId == ReadBytes(customGroupId.rest, 4) IN IF ~equityPartyId.ok THEN Fail ELSE
    LET clearingOptionalData == ReadBytes(equityPartyId.rest, 16) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET clientIdAttr == ReadBytes(clearingOptionalData.rest, 4) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(clientIdAttr.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(frequentTraderId.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(sessionEligibility.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET displayRange == ReadBytes(maxFloor.rest, 4) IN IF ~displayRange.ok THEN Fail ELSE
    LET comboOrder == ReadBytes(displayRange.rest, 1) IN IF ~comboOrder.ok THEN Fail ELSE
    LET compression == ReadBytes(comboOrder.rest, 1) IN IF ~compression.ok THEN Fail ELSE
    LET equityExDestination == ReadBytes(compression.rest, 1) IN IF ~equityExDestination.ok THEN Fail ELSE
    LET equityLegShortSell == ReadBytes(equityExDestination.rest, 1) IN IF ~equityLegShortSell.ok THEN Fail ELSE
    LET floorDestination == ReadBytes(equityLegShortSell.rest, 4) IN IF ~floorDestination.ok THEN Fail ELSE
    LET floorRoutingInst == ReadBytes(floorDestination.rest, 1) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(floorRoutingInst.rest, 3) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET orderRouterSubsidy == ReadBytes(orderOrigin.rest, 1) IN IF ~orderRouterSubsidy.ok THEN Fail ELSE
    LET priceType == ReadBytes(orderRouterSubsidy.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET strategyId == ReadBytes(priceType.rest, 1) IN IF ~strategyId.ok THEN Fail ELSE
    LET tiedHedge == ReadBytes(strategyId.rest, 1) IN IF ~tiedHedge.ok THEN Fail ELSE
    LET held == ReadBytes(tiedHedge.rest, 1) IN IF ~held.ok THEN Fail ELSE
    LET crossInitiator == ReadBytes(held.rest, 4) IN IF ~crossInitiator.ok THEN Fail ELSE
    LET crossOnBehalfOfId == ReadBytes(crossInitiator.rest, 4) IN IF ~crossOnBehalfOfId.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(crossOnBehalfOfId.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legCnt.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    Ok([ clOrdId              |-> clOrdId.value,
         side                 |-> side.value,
         orderQty             |-> orderQty.value,
         clearingFirm         |-> clearingFirm.value,
         clearingAccount      |-> clearingAccount.value,
         price                |-> price.value,
         execInst             |-> execInst.value,
         ordType              |-> ordType.value,
         timeInForce          |-> timeInForce.value,
         symbol               |-> symbol.value,
         capacity             |-> capacity.value,
         routingInst          |-> routingInst.value,
         account              |-> account.value,
         preventMatch         |-> preventMatch.value,
         expireTime           |-> expireTime.value,
         cmtaNumber           |-> cmtaNumber.value,
         targetPartyId        |-> targetPartyId.value,
         attributedQuote      |-> attributedQuote.value,
         auctionId            |-> auctionId.value,
         routingFirmId        |-> routingFirmId.value,
         drillThruProtection  |-> drillThruProtection.value,
         useDrillThruOverride |-> useDrillThruOverride.value,
         customGroupId        |-> customGroupId.value,
         equityPartyId        |-> equityPartyId.value,
         clearingOptionalData |-> clearingOptionalData.value,
         clientIdAttr         |-> clientIdAttr.value,
         frequentTraderId     |-> frequentTraderId.value,
         sessionEligibility   |-> sessionEligibility.value,
         maxFloor             |-> maxFloor.value,
         displayRange         |-> displayRange.value,
         comboOrder           |-> comboOrder.value,
         compression          |-> compression.value,
         equityExDestination  |-> equityExDestination.value,
         equityLegShortSell   |-> equityLegShortSell.value,
         floorDestination     |-> floorDestination.value,
         floorRoutingInst     |-> floorRoutingInst.value,
         orderOrigin          |-> orderOrigin.value,
         orderRouterSubsidy   |-> orderRouterSubsidy.value,
         priceType            |-> priceType.value,
         strategyId           |-> strategyId.value,
         tiedHedge            |-> tiedHedge.value,
         held                 |-> held.value,
         crossInitiator       |-> crossInitiator.value,
         crossOnBehalfOfId    |-> crossOnBehalfOfId.value,
         scratchPad           |-> scratchPad.value,
         legCnt               |-> legCnt.value,
         legPositionEffect    |-> legPositionEffect.value ], legPositionEffect.rest)

ZeroNewComplexOrderMessage ==
    [ clOrdId              |-> [i \in 1 .. 20 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      clearingAccount      |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      execInst             |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      symbol               |-> [i \in 1 .. 8 |-> 0],
      capacity             |-> [i \in 1 .. 1 |-> 0],
      routingInst          |-> [i \in 1 .. 4 |-> 0],
      account              |-> [i \in 1 .. 16 |-> 0],
      preventMatch         |-> ZeroPreventMatch4,
      expireTime           |-> [i \in 1 .. 8 |-> 0],
      cmtaNumber           |-> [i \in 1 .. 4 |-> 0],
      targetPartyId        |-> [i \in 1 .. 4 |-> 0],
      attributedQuote      |-> [i \in 1 .. 1 |-> 0],
      auctionId            |-> [i \in 1 .. 8 |-> 0],
      routingFirmId        |-> [i \in 1 .. 4 |-> 0],
      drillThruProtection  |-> [i \in 1 .. 8 |-> 0],
      useDrillThruOverride |-> [i \in 1 .. 1 |-> 0],
      customGroupId        |-> [i \in 1 .. 2 |-> 0],
      equityPartyId        |-> [i \in 1 .. 4 |-> 0],
      clearingOptionalData |-> [i \in 1 .. 16 |-> 0],
      clientIdAttr         |-> [i \in 1 .. 4 |-> 0],
      frequentTraderId     |-> [i \in 1 .. 6 |-> 0],
      sessionEligibility   |-> [i \in 1 .. 1 |-> 0],
      maxFloor             |-> [i \in 1 .. 4 |-> 0],
      displayRange         |-> [i \in 1 .. 4 |-> 0],
      comboOrder           |-> [i \in 1 .. 1 |-> 0],
      compression          |-> [i \in 1 .. 1 |-> 0],
      equityExDestination  |-> [i \in 1 .. 1 |-> 0],
      equityLegShortSell   |-> [i \in 1 .. 1 |-> 0],
      floorDestination     |-> [i \in 1 .. 4 |-> 0],
      floorRoutingInst     |-> [i \in 1 .. 1 |-> 0],
      orderOrigin          |-> [i \in 1 .. 3 |-> 0],
      orderRouterSubsidy   |-> [i \in 1 .. 1 |-> 0],
      priceType            |-> [i \in 1 .. 1 |-> 0],
      strategyId           |-> [i \in 1 .. 1 |-> 0],
      tiedHedge            |-> [i \in 1 .. 1 |-> 0],
      held                 |-> [i \in 1 .. 1 |-> 0],
      crossInitiator       |-> [i \in 1 .. 4 |-> 0],
      crossOnBehalfOfId    |-> [i \in 1 .. 4 |-> 0],
      scratchPad           |-> [i \in 1 .. 2 |-> 0],
      legCnt               |-> 0,
      legPositionEffect    |-> [i \in 1 .. 1 |-> 0] ]

(* New Complex Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexOrderMessage ==
    { ZeroNewComplexOrderMessage }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.routingInst = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch4 }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.drillThruProtection = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.useDrillThruOverride = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.equityPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.clearingOptionalData = one] : one \in Sample(16) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.clientIdAttr = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.displayRange = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.comboOrder = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.compression = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.equityExDestination = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.equityLegShortSell = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.floorDestination = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.floorRoutingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.orderOrigin = one] : one \in Sample(3) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.orderRouterSubsidy = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.strategyId = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.tiedHedge = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.held = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.crossInitiator = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.crossOnBehalfOfId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.legCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroNewComplexOrderMessage EXCEPT !.legPositionEffect = one] : one \in Sample(1) }

(***************************************************************************)
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch5 ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch5(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch5(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch5 ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch5 ==
    { ZeroPreventMatch5 }
        \cup { [ZeroPreventMatch5 EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch5 EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch5 EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* New Complex Order V 2 Message: 193 bytes                                *)
(***************************************************************************)

NewComplexOrderV2Message ==
    [ clOrdId              : Sample(20),
      side                 : Sample(1),
      orderQty             : Sample(4),
      clearingFirm         : Sample(4),
      clearingAccount      : Sample(4),
      price                : Sample(8),
      execInst             : Sample(1),
      ordType              : Sample(1),
      timeInForce          : Sample(1),
      symbol               : Sample(8),
      capacity             : Sample(1),
      routingInst          : Sample(4),
      account              : Sample(16),
      preventMatch         : PreventMatch5,
      expireTime           : Sample(8),
      cmtaNumber           : Sample(4),
      targetPartyId        : Sample(4),
      attributedQuote      : Sample(1),
      auctionId            : Sample(8),
      routingFirmId        : Sample(4),
      drillThruProtection  : Sample(8),
      useDrillThruOverride : Sample(1),
      customGroupId        : Sample(2),
      equityPartyId        : Sample(4),
      clearingOptionalData : Sample(16),
      clientIdAttr         : Sample(4),
      frequentTraderId     : Sample(6),
      sessionEligibility   : Sample(1),
      maxFloor             : Sample(4),
      displayRange         : Sample(4),
      comboOrder           : Sample(1),
      compression          : Sample(1),
      equityExDestination  : Sample(1),
      equityLegShortSell   : Sample(1),
      floorDestination     : Sample(4),
      floorRoutingInst     : Sample(1),
      orderOrigin          : Sample(3),
      orderRouterSubsidy   : Sample(1),
      priceType            : Sample(1),
      strategyId           : Sample(1),
      tiedHedge            : Sample(1),
      held                 : Sample(1),
      crossInitiator       : Sample(4),
      crossOnBehalfOfId    : Sample(4),
      stopPx               : Sample(8),
      stopPxType           : Sample(1),
      scratchPad           : Sample(2),
      legCnt               : 0 .. 255,
      legPositionEffect    : Sample(1) ]

EncodeNewComplexOrderV2Message(message) ==
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
        \o message.routingInst
        \o message.account
        \o EncodePreventMatch5(message.preventMatch)
        \o message.expireTime
        \o message.cmtaNumber
        \o message.targetPartyId
        \o message.attributedQuote
        \o message.auctionId
        \o message.routingFirmId
        \o message.drillThruProtection
        \o message.useDrillThruOverride
        \o message.customGroupId
        \o message.equityPartyId
        \o message.clearingOptionalData
        \o message.clientIdAttr
        \o message.frequentTraderId
        \o message.sessionEligibility
        \o message.maxFloor
        \o message.displayRange
        \o message.comboOrder
        \o message.compression
        \o message.equityExDestination
        \o message.equityLegShortSell
        \o message.floorDestination
        \o message.floorRoutingInst
        \o message.orderOrigin
        \o message.orderRouterSubsidy
        \o message.priceType
        \o message.strategyId
        \o message.tiedHedge
        \o message.held
        \o message.crossInitiator
        \o message.crossOnBehalfOfId
        \o message.stopPx
        \o message.stopPxType
        \o message.scratchPad
        \o EncodeUIntLE(message.legCnt, 1)
        \o message.legPositionEffect

DecodeNewComplexOrderV2Message(bytes) ==
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
    LET routingInst == ReadBytes(capacity.rest, 4) IN IF ~routingInst.ok THEN Fail ELSE
    LET account == ReadBytes(routingInst.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch5(account.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET expireTime == ReadBytes(preventMatch.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(expireTime.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(cmtaNumber.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(targetPartyId.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET auctionId == ReadBytes(attributedQuote.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(auctionId.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET drillThruProtection == ReadBytes(routingFirmId.rest, 8) IN IF ~drillThruProtection.ok THEN Fail ELSE
    LET useDrillThruOverride == ReadBytes(drillThruProtection.rest, 1) IN IF ~useDrillThruOverride.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(useDrillThruOverride.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET equityPartyId == ReadBytes(customGroupId.rest, 4) IN IF ~equityPartyId.ok THEN Fail ELSE
    LET clearingOptionalData == ReadBytes(equityPartyId.rest, 16) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET clientIdAttr == ReadBytes(clearingOptionalData.rest, 4) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(clientIdAttr.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(frequentTraderId.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(sessionEligibility.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET displayRange == ReadBytes(maxFloor.rest, 4) IN IF ~displayRange.ok THEN Fail ELSE
    LET comboOrder == ReadBytes(displayRange.rest, 1) IN IF ~comboOrder.ok THEN Fail ELSE
    LET compression == ReadBytes(comboOrder.rest, 1) IN IF ~compression.ok THEN Fail ELSE
    LET equityExDestination == ReadBytes(compression.rest, 1) IN IF ~equityExDestination.ok THEN Fail ELSE
    LET equityLegShortSell == ReadBytes(equityExDestination.rest, 1) IN IF ~equityLegShortSell.ok THEN Fail ELSE
    LET floorDestination == ReadBytes(equityLegShortSell.rest, 4) IN IF ~floorDestination.ok THEN Fail ELSE
    LET floorRoutingInst == ReadBytes(floorDestination.rest, 1) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(floorRoutingInst.rest, 3) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET orderRouterSubsidy == ReadBytes(orderOrigin.rest, 1) IN IF ~orderRouterSubsidy.ok THEN Fail ELSE
    LET priceType == ReadBytes(orderRouterSubsidy.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET strategyId == ReadBytes(priceType.rest, 1) IN IF ~strategyId.ok THEN Fail ELSE
    LET tiedHedge == ReadBytes(strategyId.rest, 1) IN IF ~tiedHedge.ok THEN Fail ELSE
    LET held == ReadBytes(tiedHedge.rest, 1) IN IF ~held.ok THEN Fail ELSE
    LET crossInitiator == ReadBytes(held.rest, 4) IN IF ~crossInitiator.ok THEN Fail ELSE
    LET crossOnBehalfOfId == ReadBytes(crossInitiator.rest, 4) IN IF ~crossOnBehalfOfId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(crossOnBehalfOfId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET stopPxType == ReadBytes(stopPx.rest, 1) IN IF ~stopPxType.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(stopPxType.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legCnt.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    Ok([ clOrdId              |-> clOrdId.value,
         side                 |-> side.value,
         orderQty             |-> orderQty.value,
         clearingFirm         |-> clearingFirm.value,
         clearingAccount      |-> clearingAccount.value,
         price                |-> price.value,
         execInst             |-> execInst.value,
         ordType              |-> ordType.value,
         timeInForce          |-> timeInForce.value,
         symbol               |-> symbol.value,
         capacity             |-> capacity.value,
         routingInst          |-> routingInst.value,
         account              |-> account.value,
         preventMatch         |-> preventMatch.value,
         expireTime           |-> expireTime.value,
         cmtaNumber           |-> cmtaNumber.value,
         targetPartyId        |-> targetPartyId.value,
         attributedQuote      |-> attributedQuote.value,
         auctionId            |-> auctionId.value,
         routingFirmId        |-> routingFirmId.value,
         drillThruProtection  |-> drillThruProtection.value,
         useDrillThruOverride |-> useDrillThruOverride.value,
         customGroupId        |-> customGroupId.value,
         equityPartyId        |-> equityPartyId.value,
         clearingOptionalData |-> clearingOptionalData.value,
         clientIdAttr         |-> clientIdAttr.value,
         frequentTraderId     |-> frequentTraderId.value,
         sessionEligibility   |-> sessionEligibility.value,
         maxFloor             |-> maxFloor.value,
         displayRange         |-> displayRange.value,
         comboOrder           |-> comboOrder.value,
         compression          |-> compression.value,
         equityExDestination  |-> equityExDestination.value,
         equityLegShortSell   |-> equityLegShortSell.value,
         floorDestination     |-> floorDestination.value,
         floorRoutingInst     |-> floorRoutingInst.value,
         orderOrigin          |-> orderOrigin.value,
         orderRouterSubsidy   |-> orderRouterSubsidy.value,
         priceType            |-> priceType.value,
         strategyId           |-> strategyId.value,
         tiedHedge            |-> tiedHedge.value,
         held                 |-> held.value,
         crossInitiator       |-> crossInitiator.value,
         crossOnBehalfOfId    |-> crossOnBehalfOfId.value,
         stopPx               |-> stopPx.value,
         stopPxType           |-> stopPxType.value,
         scratchPad           |-> scratchPad.value,
         legCnt               |-> legCnt.value,
         legPositionEffect    |-> legPositionEffect.value ], legPositionEffect.rest)

ZeroNewComplexOrderV2Message ==
    [ clOrdId              |-> [i \in 1 .. 20 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      clearingAccount      |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      execInst             |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      symbol               |-> [i \in 1 .. 8 |-> 0],
      capacity             |-> [i \in 1 .. 1 |-> 0],
      routingInst          |-> [i \in 1 .. 4 |-> 0],
      account              |-> [i \in 1 .. 16 |-> 0],
      preventMatch         |-> ZeroPreventMatch5,
      expireTime           |-> [i \in 1 .. 8 |-> 0],
      cmtaNumber           |-> [i \in 1 .. 4 |-> 0],
      targetPartyId        |-> [i \in 1 .. 4 |-> 0],
      attributedQuote      |-> [i \in 1 .. 1 |-> 0],
      auctionId            |-> [i \in 1 .. 8 |-> 0],
      routingFirmId        |-> [i \in 1 .. 4 |-> 0],
      drillThruProtection  |-> [i \in 1 .. 8 |-> 0],
      useDrillThruOverride |-> [i \in 1 .. 1 |-> 0],
      customGroupId        |-> [i \in 1 .. 2 |-> 0],
      equityPartyId        |-> [i \in 1 .. 4 |-> 0],
      clearingOptionalData |-> [i \in 1 .. 16 |-> 0],
      clientIdAttr         |-> [i \in 1 .. 4 |-> 0],
      frequentTraderId     |-> [i \in 1 .. 6 |-> 0],
      sessionEligibility   |-> [i \in 1 .. 1 |-> 0],
      maxFloor             |-> [i \in 1 .. 4 |-> 0],
      displayRange         |-> [i \in 1 .. 4 |-> 0],
      comboOrder           |-> [i \in 1 .. 1 |-> 0],
      compression          |-> [i \in 1 .. 1 |-> 0],
      equityExDestination  |-> [i \in 1 .. 1 |-> 0],
      equityLegShortSell   |-> [i \in 1 .. 1 |-> 0],
      floorDestination     |-> [i \in 1 .. 4 |-> 0],
      floorRoutingInst     |-> [i \in 1 .. 1 |-> 0],
      orderOrigin          |-> [i \in 1 .. 3 |-> 0],
      orderRouterSubsidy   |-> [i \in 1 .. 1 |-> 0],
      priceType            |-> [i \in 1 .. 1 |-> 0],
      strategyId           |-> [i \in 1 .. 1 |-> 0],
      tiedHedge            |-> [i \in 1 .. 1 |-> 0],
      held                 |-> [i \in 1 .. 1 |-> 0],
      crossInitiator       |-> [i \in 1 .. 4 |-> 0],
      crossOnBehalfOfId    |-> [i \in 1 .. 4 |-> 0],
      stopPx               |-> [i \in 1 .. 8 |-> 0],
      stopPxType           |-> [i \in 1 .. 1 |-> 0],
      scratchPad           |-> [i \in 1 .. 2 |-> 0],
      legCnt               |-> 0,
      legPositionEffect    |-> [i \in 1 .. 1 |-> 0] ]

(* New Complex Order V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexOrderV2Message ==
    { ZeroNewComplexOrderV2Message }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.routingInst = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch5 }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.drillThruProtection = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.useDrillThruOverride = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.equityPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.clearingOptionalData = one] : one \in Sample(16) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.clientIdAttr = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.displayRange = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.comboOrder = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.compression = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.equityExDestination = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.equityLegShortSell = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.floorDestination = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.floorRoutingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.orderOrigin = one] : one \in Sample(3) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.orderRouterSubsidy = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.strategyId = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.tiedHedge = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.held = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.crossInitiator = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.crossOnBehalfOfId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.stopPxType = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.legCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroNewComplexOrderV2Message EXCEPT !.legPositionEffect = one] : one \in Sample(1) }

(***************************************************************************)
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch6 ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch6(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch6(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch6 ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch6 ==
    { ZeroPreventMatch6 }
        \cup { [ZeroPreventMatch6 EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch6 EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch6 EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* New Complex Order Short Message: 122 bytes                              *)
(***************************************************************************)

NewComplexOrderShortMessage ==
    [ clOrdId            : Sample(20),
      side               : Sample(1),
      orderQty           : Sample(4),
      clearingFirm       : Sample(4),
      clearingAccount    : Sample(4),
      price              : Sample(8),
      execInst           : Sample(1),
      ordType            : Sample(1),
      timeInForce        : Sample(1),
      symbol             : Sample(8),
      capacity           : Sample(1),
      routingInst        : Sample(4),
      account            : Sample(16),
      preventMatch       : PreventMatch6,
      cmtaNumber         : Sample(4),
      targetPartyId      : Sample(4),
      auctionId          : Sample(8),
      routingFirmId      : Sample(4),
      customGroupId      : Sample(2),
      equityPartyId      : Sample(4),
      frequentTraderId   : Sample(6),
      sessionEligibility : Sample(1),
      maxFloor           : Sample(4),
      floorDestination   : Sample(4),
      floorRoutingInst   : Sample(1),
      scratchPad         : Sample(2),
      legCnt             : 0 .. 255,
      legPositionEffect  : Sample(1) ]

EncodeNewComplexOrderShortMessage(message) ==
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
        \o message.routingInst
        \o message.account
        \o EncodePreventMatch6(message.preventMatch)
        \o message.cmtaNumber
        \o message.targetPartyId
        \o message.auctionId
        \o message.routingFirmId
        \o message.customGroupId
        \o message.equityPartyId
        \o message.frequentTraderId
        \o message.sessionEligibility
        \o message.maxFloor
        \o message.floorDestination
        \o message.floorRoutingInst
        \o message.scratchPad
        \o EncodeUIntLE(message.legCnt, 1)
        \o message.legPositionEffect

DecodeNewComplexOrderShortMessage(bytes) ==
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
    LET routingInst == ReadBytes(capacity.rest, 4) IN IF ~routingInst.ok THEN Fail ELSE
    LET account == ReadBytes(routingInst.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch6(account.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(preventMatch.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(cmtaNumber.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(targetPartyId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(auctionId.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(routingFirmId.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET equityPartyId == ReadBytes(customGroupId.rest, 4) IN IF ~equityPartyId.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(equityPartyId.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(frequentTraderId.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(sessionEligibility.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET floorDestination == ReadBytes(maxFloor.rest, 4) IN IF ~floorDestination.ok THEN Fail ELSE
    LET floorRoutingInst == ReadBytes(floorDestination.rest, 1) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(floorRoutingInst.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legCnt.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    Ok([ clOrdId            |-> clOrdId.value,
         side               |-> side.value,
         orderQty           |-> orderQty.value,
         clearingFirm       |-> clearingFirm.value,
         clearingAccount    |-> clearingAccount.value,
         price              |-> price.value,
         execInst           |-> execInst.value,
         ordType            |-> ordType.value,
         timeInForce        |-> timeInForce.value,
         symbol             |-> symbol.value,
         capacity           |-> capacity.value,
         routingInst        |-> routingInst.value,
         account            |-> account.value,
         preventMatch       |-> preventMatch.value,
         cmtaNumber         |-> cmtaNumber.value,
         targetPartyId      |-> targetPartyId.value,
         auctionId          |-> auctionId.value,
         routingFirmId      |-> routingFirmId.value,
         customGroupId      |-> customGroupId.value,
         equityPartyId      |-> equityPartyId.value,
         frequentTraderId   |-> frequentTraderId.value,
         sessionEligibility |-> sessionEligibility.value,
         maxFloor           |-> maxFloor.value,
         floorDestination   |-> floorDestination.value,
         floorRoutingInst   |-> floorRoutingInst.value,
         scratchPad         |-> scratchPad.value,
         legCnt             |-> legCnt.value,
         legPositionEffect  |-> legPositionEffect.value ], legPositionEffect.rest)

ZeroNewComplexOrderShortMessage ==
    [ clOrdId            |-> [i \in 1 .. 20 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      execInst           |-> [i \in 1 .. 1 |-> 0],
      ordType            |-> [i \in 1 .. 1 |-> 0],
      timeInForce        |-> [i \in 1 .. 1 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      routingInst        |-> [i \in 1 .. 4 |-> 0],
      account            |-> [i \in 1 .. 16 |-> 0],
      preventMatch       |-> ZeroPreventMatch6,
      cmtaNumber         |-> [i \in 1 .. 4 |-> 0],
      targetPartyId      |-> [i \in 1 .. 4 |-> 0],
      auctionId          |-> [i \in 1 .. 8 |-> 0],
      routingFirmId      |-> [i \in 1 .. 4 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      equityPartyId      |-> [i \in 1 .. 4 |-> 0],
      frequentTraderId   |-> [i \in 1 .. 6 |-> 0],
      sessionEligibility |-> [i \in 1 .. 1 |-> 0],
      maxFloor           |-> [i \in 1 .. 4 |-> 0],
      floorDestination   |-> [i \in 1 .. 4 |-> 0],
      floorRoutingInst   |-> [i \in 1 .. 1 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0],
      legCnt             |-> 0,
      legPositionEffect  |-> [i \in 1 .. 1 |-> 0] ]

(* New Complex Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexOrderShortMessage ==
    { ZeroNewComplexOrderShortMessage }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.routingInst = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch6 }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.equityPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.floorDestination = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.floorRoutingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.legCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroNewComplexOrderShortMessage EXCEPT !.legPositionEffect = one] : one \in Sample(1) }

(***************************************************************************)
(* Prevent Match: 3 bytes                                                  *)
(***************************************************************************)

PreventMatch7 ==
    [ mtpModifier    : Sample(1),
      uniqueIdLevel  : Sample(1),
      tradingGroupId : Sample(1) ]

EncodePreventMatch7(message) ==
    message.mtpModifier
        \o message.uniqueIdLevel
        \o message.tradingGroupId

DecodePreventMatch7(bytes) ==
    LET mtpModifier == ReadBytes(bytes, 1) IN IF ~mtpModifier.ok THEN Fail ELSE
    LET uniqueIdLevel == ReadBytes(mtpModifier.rest, 1) IN IF ~uniqueIdLevel.ok THEN Fail ELSE
    LET tradingGroupId == ReadBytes(uniqueIdLevel.rest, 1) IN IF ~tradingGroupId.ok THEN Fail ELSE
    Ok([ mtpModifier    |-> mtpModifier.value,
         uniqueIdLevel  |-> uniqueIdLevel.value,
         tradingGroupId |-> tradingGroupId.value ], tradingGroupId.rest)

ZeroPreventMatch7 ==
    [ mtpModifier    |-> [i \in 1 .. 1 |-> 0],
      uniqueIdLevel  |-> [i \in 1 .. 1 |-> 0],
      tradingGroupId |-> [i \in 1 .. 1 |-> 0] ]

(* Prevent Match at zero, then each field in turn at the values it is checked at *)
CheckedPreventMatch7 ==
    { ZeroPreventMatch7 }
        \cup { [ZeroPreventMatch7 EXCEPT !.mtpModifier = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch7 EXCEPT !.uniqueIdLevel = one] : one \in Sample(1) }
        \cup { [ZeroPreventMatch7 EXCEPT !.tradingGroupId = one] : one \in Sample(1) }

(***************************************************************************)
(* Multileg Allocation: 81 bytes                                           *)
(***************************************************************************)

MultilegAllocation ==
    [ side                 : Sample(1),
      allocQty             : Sample(4),
      clOrdId              : Sample(20),
      capacity             : Sample(1),
      giveUpFirmId         : Sample(4),
      account              : Sample(16),
      cmtaNumber           : Sample(4),
      clearingAccount      : Sample(4),
      clearingOptionalData : Sample(16),
      equityPartyId        : Sample(4),
      equityLegShortSell   : Sample(1),
      frequentTraderId     : Sample(6) ]

EncodeMultilegAllocation(message) ==
    message.side
        \o message.allocQty
        \o message.clOrdId
        \o message.capacity
        \o message.giveUpFirmId
        \o message.account
        \o message.cmtaNumber
        \o message.clearingAccount
        \o message.clearingOptionalData
        \o message.equityPartyId
        \o message.equityLegShortSell
        \o message.frequentTraderId

DecodeMultilegAllocation(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET allocQty == ReadBytes(side.rest, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(allocQty.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET capacity == ReadBytes(clOrdId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET giveUpFirmId == ReadBytes(capacity.rest, 4) IN IF ~giveUpFirmId.ok THEN Fail ELSE
    LET account == ReadBytes(giveUpFirmId.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(account.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(cmtaNumber.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET clearingOptionalData == ReadBytes(clearingAccount.rest, 16) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET equityPartyId == ReadBytes(clearingOptionalData.rest, 4) IN IF ~equityPartyId.ok THEN Fail ELSE
    LET equityLegShortSell == ReadBytes(equityPartyId.rest, 1) IN IF ~equityLegShortSell.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(equityLegShortSell.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    Ok([ side                 |-> side.value,
         allocQty             |-> allocQty.value,
         clOrdId              |-> clOrdId.value,
         capacity             |-> capacity.value,
         giveUpFirmId         |-> giveUpFirmId.value,
         account              |-> account.value,
         cmtaNumber           |-> cmtaNumber.value,
         clearingAccount      |-> clearingAccount.value,
         clearingOptionalData |-> clearingOptionalData.value,
         equityPartyId        |-> equityPartyId.value,
         equityLegShortSell   |-> equityLegShortSell.value,
         frequentTraderId     |-> frequentTraderId.value ], frequentTraderId.rest)

ZeroMultilegAllocation ==
    [ side                 |-> [i \in 1 .. 1 |-> 0],
      allocQty             |-> [i \in 1 .. 4 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      capacity             |-> [i \in 1 .. 1 |-> 0],
      giveUpFirmId         |-> [i \in 1 .. 4 |-> 0],
      account              |-> [i \in 1 .. 16 |-> 0],
      cmtaNumber           |-> [i \in 1 .. 4 |-> 0],
      clearingAccount      |-> [i \in 1 .. 4 |-> 0],
      clearingOptionalData |-> [i \in 1 .. 16 |-> 0],
      equityPartyId        |-> [i \in 1 .. 4 |-> 0],
      equityLegShortSell   |-> [i \in 1 .. 1 |-> 0],
      frequentTraderId     |-> [i \in 1 .. 6 |-> 0] ]

(* Multileg Allocation at zero, then each field in turn at the values it is checked at *)
CheckedMultilegAllocation ==
    { ZeroMultilegAllocation }
        \cup { [ZeroMultilegAllocation EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMultilegAllocation EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroMultilegAllocation EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroMultilegAllocation EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroMultilegAllocation EXCEPT !.giveUpFirmId = one] : one \in Sample(4) }
        \cup { [ZeroMultilegAllocation EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroMultilegAllocation EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroMultilegAllocation EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroMultilegAllocation EXCEPT !.clearingOptionalData = one] : one \in Sample(16) }
        \cup { [ZeroMultilegAllocation EXCEPT !.equityPartyId = one] : one \in Sample(4) }
        \cup { [ZeroMultilegAllocation EXCEPT !.equityLegShortSell = one] : one \in Sample(1) }
        \cup { [ZeroMultilegAllocation EXCEPT !.frequentTraderId = one] : one \in Sample(6) }

(* A run of Multileg Allocation, written one after another *)
RECURSIVE EncodeMultilegAllocationList(_)
EncodeMultilegAllocationList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMultilegAllocation(Head(messages)) \o EncodeMultilegAllocationList(Tail(messages))

(* As many Multileg Allocation as the field that counts them says *)
RECURSIVE ReadMultilegAllocationList(_, _)
ReadMultilegAllocationList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMultilegAllocation(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMultilegAllocationList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Multileg Allocation of each kind, for the lists that carry them *)
OneMultilegAllocation == { ZeroMultilegAllocation }

(***************************************************************************)
(* New Order Cross Multileg Message                                        *)
(***************************************************************************)

NewOrderCrossMultilegMessage ==
    [ crossId                : Sample(20),
      crossType              : Sample(1),
      crossPrioritization    : Sample(1),
      price                  : Sample(8),
      orderQty               : Sample(4),
      symbol                 : Sample(8),
      attributedQuote        : Sample(1),
      targetPartyId          : Sample(4),
      preventMatch           : PreventMatch7,
      autoMatch              : Sample(1),
      autoMatchPrice         : Sample(8),
      lastPriority           : Sample(1),
      routingFirmId          : Sample(4),
      clientIdAttr           : Sample(4),
      equityTradePrice       : Sample(8),
      equityTradeSize        : Sample(4),
      equityTradeVenue       : Sample(1),
      equityTransactTime     : Sample(8),
      equityBuyClearingFirm  : Sample(4),
      equitySellClearingFirm : Sample(4),
      drillThruProtection    : Sample(8),
      useDrillThruOverride   : Sample(1),
      equityExDestination    : Sample(1),
      compression            : Sample(1),
      orderRouterSubsidy     : Sample(1),
      crossInitiator         : Sample(4),
      crossOnBehalfOfId      : Sample(4),
      scratchPad             : Sample(2),
      allocLegCnt            : 0 .. 255,
      multilegAllocation     : SampleLists(OneMultilegAllocation),
      legPositionEffect      : Sample(1) ]

EncodeNewOrderCrossMultilegMessage(message) ==
    message.crossId
        \o message.crossType
        \o message.crossPrioritization
        \o message.price
        \o message.orderQty
        \o message.symbol
        \o message.attributedQuote
        \o message.targetPartyId
        \o EncodePreventMatch7(message.preventMatch)
        \o message.autoMatch
        \o message.autoMatchPrice
        \o message.lastPriority
        \o message.routingFirmId
        \o message.clientIdAttr
        \o message.equityTradePrice
        \o message.equityTradeSize
        \o message.equityTradeVenue
        \o message.equityTransactTime
        \o message.equityBuyClearingFirm
        \o message.equitySellClearingFirm
        \o message.drillThruProtection
        \o message.useDrillThruOverride
        \o message.equityExDestination
        \o message.compression
        \o message.orderRouterSubsidy
        \o message.crossInitiator
        \o message.crossOnBehalfOfId
        \o message.scratchPad
        \o EncodeUIntLE(Len(message.multilegAllocation), 1)
        \o EncodeUIntLE(message.allocLegCnt, 1)
        \o EncodeMultilegAllocationList(message.multilegAllocation)
        \o message.legPositionEffect

DecodeNewOrderCrossMultilegMessage(bytes) ==
    LET crossId == ReadBytes(bytes, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET crossPrioritization == ReadBytes(crossType.rest, 1) IN IF ~crossPrioritization.ok THEN Fail ELSE
    LET price == ReadBytes(crossPrioritization.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderQty.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(symbol.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(attributedQuote.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch7(targetPartyId.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET autoMatch == ReadBytes(preventMatch.rest, 1) IN IF ~autoMatch.ok THEN Fail ELSE
    LET autoMatchPrice == ReadBytes(autoMatch.rest, 8) IN IF ~autoMatchPrice.ok THEN Fail ELSE
    LET lastPriority == ReadBytes(autoMatchPrice.rest, 1) IN IF ~lastPriority.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(lastPriority.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET clientIdAttr == ReadBytes(routingFirmId.rest, 4) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET equityTradePrice == ReadBytes(clientIdAttr.rest, 8) IN IF ~equityTradePrice.ok THEN Fail ELSE
    LET equityTradeSize == ReadBytes(equityTradePrice.rest, 4) IN IF ~equityTradeSize.ok THEN Fail ELSE
    LET equityTradeVenue == ReadBytes(equityTradeSize.rest, 1) IN IF ~equityTradeVenue.ok THEN Fail ELSE
    LET equityTransactTime == ReadBytes(equityTradeVenue.rest, 8) IN IF ~equityTransactTime.ok THEN Fail ELSE
    LET equityBuyClearingFirm == ReadBytes(equityTransactTime.rest, 4) IN IF ~equityBuyClearingFirm.ok THEN Fail ELSE
    LET equitySellClearingFirm == ReadBytes(equityBuyClearingFirm.rest, 4) IN IF ~equitySellClearingFirm.ok THEN Fail ELSE
    LET drillThruProtection == ReadBytes(equitySellClearingFirm.rest, 8) IN IF ~drillThruProtection.ok THEN Fail ELSE
    LET useDrillThruOverride == ReadBytes(drillThruProtection.rest, 1) IN IF ~useDrillThruOverride.ok THEN Fail ELSE
    LET equityExDestination == ReadBytes(useDrillThruOverride.rest, 1) IN IF ~equityExDestination.ok THEN Fail ELSE
    LET compression == ReadBytes(equityExDestination.rest, 1) IN IF ~compression.ok THEN Fail ELSE
    LET orderRouterSubsidy == ReadBytes(compression.rest, 1) IN IF ~orderRouterSubsidy.ok THEN Fail ELSE
    LET crossInitiator == ReadBytes(orderRouterSubsidy.rest, 4) IN IF ~crossInitiator.ok THEN Fail ELSE
    LET crossOnBehalfOfId == ReadBytes(crossInitiator.rest, 4) IN IF ~crossOnBehalfOfId.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(crossOnBehalfOfId.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET allocCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~allocCnt.ok THEN Fail ELSE
    LET allocLegCnt == ReadUIntLE(allocCnt.rest, 1) IN IF ~allocLegCnt.ok THEN Fail ELSE
    LET multilegAllocation == ReadMultilegAllocationList(allocLegCnt.rest, allocCnt.value) IN IF ~multilegAllocation.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(multilegAllocation.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    Ok([ crossId                |-> crossId.value,
         crossType              |-> crossType.value,
         crossPrioritization    |-> crossPrioritization.value,
         price                  |-> price.value,
         orderQty               |-> orderQty.value,
         symbol                 |-> symbol.value,
         attributedQuote        |-> attributedQuote.value,
         targetPartyId          |-> targetPartyId.value,
         preventMatch           |-> preventMatch.value,
         autoMatch              |-> autoMatch.value,
         autoMatchPrice         |-> autoMatchPrice.value,
         lastPriority           |-> lastPriority.value,
         routingFirmId          |-> routingFirmId.value,
         clientIdAttr           |-> clientIdAttr.value,
         equityTradePrice       |-> equityTradePrice.value,
         equityTradeSize        |-> equityTradeSize.value,
         equityTradeVenue       |-> equityTradeVenue.value,
         equityTransactTime     |-> equityTransactTime.value,
         equityBuyClearingFirm  |-> equityBuyClearingFirm.value,
         equitySellClearingFirm |-> equitySellClearingFirm.value,
         drillThruProtection    |-> drillThruProtection.value,
         useDrillThruOverride   |-> useDrillThruOverride.value,
         equityExDestination    |-> equityExDestination.value,
         compression            |-> compression.value,
         orderRouterSubsidy     |-> orderRouterSubsidy.value,
         crossInitiator         |-> crossInitiator.value,
         crossOnBehalfOfId      |-> crossOnBehalfOfId.value,
         scratchPad             |-> scratchPad.value,
         allocLegCnt            |-> allocLegCnt.value,
         multilegAllocation     |-> multilegAllocation.value,
         legPositionEffect      |-> legPositionEffect.value ], legPositionEffect.rest)

ZeroNewOrderCrossMultilegMessage ==
    [ crossId                |-> [i \in 1 .. 20 |-> 0],
      crossType              |-> [i \in 1 .. 1 |-> 0],
      crossPrioritization    |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      attributedQuote        |-> [i \in 1 .. 1 |-> 0],
      targetPartyId          |-> [i \in 1 .. 4 |-> 0],
      preventMatch           |-> ZeroPreventMatch7,
      autoMatch              |-> [i \in 1 .. 1 |-> 0],
      autoMatchPrice         |-> [i \in 1 .. 8 |-> 0],
      lastPriority           |-> [i \in 1 .. 1 |-> 0],
      routingFirmId          |-> [i \in 1 .. 4 |-> 0],
      clientIdAttr           |-> [i \in 1 .. 4 |-> 0],
      equityTradePrice       |-> [i \in 1 .. 8 |-> 0],
      equityTradeSize        |-> [i \in 1 .. 4 |-> 0],
      equityTradeVenue       |-> [i \in 1 .. 1 |-> 0],
      equityTransactTime     |-> [i \in 1 .. 8 |-> 0],
      equityBuyClearingFirm  |-> [i \in 1 .. 4 |-> 0],
      equitySellClearingFirm |-> [i \in 1 .. 4 |-> 0],
      drillThruProtection    |-> [i \in 1 .. 8 |-> 0],
      useDrillThruOverride   |-> [i \in 1 .. 1 |-> 0],
      equityExDestination    |-> [i \in 1 .. 1 |-> 0],
      compression            |-> [i \in 1 .. 1 |-> 0],
      orderRouterSubsidy     |-> [i \in 1 .. 1 |-> 0],
      crossInitiator         |-> [i \in 1 .. 4 |-> 0],
      crossOnBehalfOfId      |-> [i \in 1 .. 4 |-> 0],
      scratchPad             |-> [i \in 1 .. 2 |-> 0],
      allocLegCnt            |-> 0,
      multilegAllocation     |-> << >>,
      legPositionEffect      |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Cross Multileg Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossMultilegMessage ==
    { ZeroNewOrderCrossMultilegMessage }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.crossPrioritization = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch7 }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.autoMatch = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.autoMatchPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.lastPriority = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.clientIdAttr = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.equityTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.equityTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.equityTradeVenue = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.equityTransactTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.equityBuyClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.equitySellClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.drillThruProtection = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.useDrillThruOverride = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.equityExDestination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.compression = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.orderRouterSubsidy = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.crossInitiator = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.crossOnBehalfOfId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.allocLegCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.multilegAllocation = one] : one \in SampleLists(OneMultilegAllocation) }
        \cup { [ZeroNewOrderCrossMultilegMessage EXCEPT !.legPositionEffect = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Order Message: 30 bytes                                          *)
(***************************************************************************)

CancelOrderMessage ==
    [ origClOrdId   : Sample(20),
      clearingFirm  : Sample(4),
      routingFirmId : Sample(4),
      scratchPad    : Sample(2) ]

EncodeCancelOrderMessage(message) ==
    message.origClOrdId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.scratchPad

DecodeCancelOrderMessage(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(origClOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(routingFirmId.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ origClOrdId   |-> origClOrdId.value,
         clearingFirm  |-> clearingFirm.value,
         routingFirmId |-> routingFirmId.value,
         scratchPad    |-> scratchPad.value ], scratchPad.rest)

ZeroCancelOrderMessage ==
    [ origClOrdId   |-> [i \in 1 .. 20 |-> 0],
      clearingFirm  |-> [i \in 1 .. 4 |-> 0],
      routingFirmId |-> [i \in 1 .. 4 |-> 0],
      scratchPad    |-> [i \in 1 .. 2 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Mass Cancel Inst: 8 bytes                                               *)
(***************************************************************************)

MassCancelInst ==
    [ clearingFirmFilter   : Sample(1),
      acknowledgementStyle : Sample(1),
      lockoutInstruction   : Sample(1),
      instrumentTypeFilter : Sample(1),
      gtcOrderFilter       : Sample(1),
      instructionDetails   : Sample(3) ]

EncodeMassCancelInst(message) ==
    message.clearingFirmFilter
        \o message.acknowledgementStyle
        \o message.lockoutInstruction
        \o message.instrumentTypeFilter
        \o message.gtcOrderFilter
        \o message.instructionDetails

DecodeMassCancelInst(bytes) ==
    LET clearingFirmFilter == ReadBytes(bytes, 1) IN IF ~clearingFirmFilter.ok THEN Fail ELSE
    LET acknowledgementStyle == ReadBytes(clearingFirmFilter.rest, 1) IN IF ~acknowledgementStyle.ok THEN Fail ELSE
    LET lockoutInstruction == ReadBytes(acknowledgementStyle.rest, 1) IN IF ~lockoutInstruction.ok THEN Fail ELSE
    LET instrumentTypeFilter == ReadBytes(lockoutInstruction.rest, 1) IN IF ~instrumentTypeFilter.ok THEN Fail ELSE
    LET gtcOrderFilter == ReadBytes(instrumentTypeFilter.rest, 1) IN IF ~gtcOrderFilter.ok THEN Fail ELSE
    LET instructionDetails == ReadBytes(gtcOrderFilter.rest, 3) IN IF ~instructionDetails.ok THEN Fail ELSE
    Ok([ clearingFirmFilter   |-> clearingFirmFilter.value,
         acknowledgementStyle |-> acknowledgementStyle.value,
         lockoutInstruction   |-> lockoutInstruction.value,
         instrumentTypeFilter |-> instrumentTypeFilter.value,
         gtcOrderFilter       |-> gtcOrderFilter.value,
         instructionDetails   |-> instructionDetails.value ], instructionDetails.rest)

ZeroMassCancelInst ==
    [ clearingFirmFilter   |-> [i \in 1 .. 1 |-> 0],
      acknowledgementStyle |-> [i \in 1 .. 1 |-> 0],
      lockoutInstruction   |-> [i \in 1 .. 1 |-> 0],
      instrumentTypeFilter |-> [i \in 1 .. 1 |-> 0],
      gtcOrderFilter       |-> [i \in 1 .. 1 |-> 0],
      instructionDetails   |-> [i \in 1 .. 3 |-> 0] ]

(* Mass Cancel Inst at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelInst ==
    { ZeroMassCancelInst }
        \cup { [ZeroMassCancelInst EXCEPT !.clearingFirmFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.acknowledgementStyle = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.lockoutInstruction = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.instrumentTypeFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.gtcOrderFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst EXCEPT !.instructionDetails = one] : one \in Sample(3) }

(***************************************************************************)
(* Mass Cancel Order Message: 52 bytes                                     *)
(***************************************************************************)

MassCancelOrderMessage ==
    [ massCancelId   : Sample(20),
      clearingFirm   : Sample(4),
      routingFirmId  : Sample(4),
      riskRoot       : Sample(6),
      massCancelInst : MassCancelInst,
      sendTime       : Sample(8),
      scratchPad     : Sample(2) ]

EncodeMassCancelOrderMessage(message) ==
    message.massCancelId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.riskRoot
        \o EncodeMassCancelInst(message.massCancelInst)
        \o message.sendTime
        \o message.scratchPad

DecodeMassCancelOrderMessage(bytes) ==
    LET massCancelId == ReadBytes(bytes, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(massCancelId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET riskRoot == ReadBytes(routingFirmId.rest, 6) IN IF ~riskRoot.ok THEN Fail ELSE
    LET massCancelInst == DecodeMassCancelInst(riskRoot.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET sendTime == ReadBytes(massCancelInst.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(sendTime.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ massCancelId   |-> massCancelId.value,
         clearingFirm   |-> clearingFirm.value,
         routingFirmId  |-> routingFirmId.value,
         riskRoot       |-> riskRoot.value,
         massCancelInst |-> massCancelInst.value,
         sendTime       |-> sendTime.value,
         scratchPad     |-> scratchPad.value ], scratchPad.rest)

ZeroMassCancelOrderMessage ==
    [ massCancelId   |-> [i \in 1 .. 20 |-> 0],
      clearingFirm   |-> [i \in 1 .. 4 |-> 0],
      routingFirmId  |-> [i \in 1 .. 4 |-> 0],
      riskRoot       |-> [i \in 1 .. 6 |-> 0],
      massCancelInst |-> ZeroMassCancelInst,
      sendTime       |-> [i \in 1 .. 8 |-> 0],
      scratchPad     |-> [i \in 1 .. 2 |-> 0] ]

(* Mass Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelOrderMessage ==
    { ZeroMassCancelOrderMessage }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.riskRoot = one] : one \in Sample(6) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.massCancelInst = one] : one \in CheckedMassCancelInst }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Modify Order Message: 117 bytes                                         *)
(***************************************************************************)

ModifyOrderMessage ==
    [ clOrdId            : Sample(20),
      origClOrdId        : Sample(20),
      clearingFirm       : Sample(4),
      routingFirmId      : Sample(4),
      orderQty           : Sample(4),
      price              : Sample(8),
      ordType            : Sample(1),
      maxFloor           : Sample(4),
      stopPx             : Sample(8),
      cancelOrigOnReject : Sample(1),
      reserved           : Sample(41),
      scratchPad         : Sample(2) ]

EncodeModifyOrderMessage(message) ==
    message.clOrdId
        \o message.origClOrdId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.orderQty
        \o message.price
        \o message.ordType
        \o message.maxFloor
        \o message.stopPx
        \o message.cancelOrigOnReject
        \o message.reserved
        \o message.scratchPad

DecodeModifyOrderMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(origClOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(routingFirmId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(ordType.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET stopPx == ReadBytes(maxFloor.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET cancelOrigOnReject == ReadBytes(stopPx.rest, 1) IN IF ~cancelOrigOnReject.ok THEN Fail ELSE
    LET reserved == ReadBytes(cancelOrigOnReject.rest, 41) IN IF ~reserved.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(reserved.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ clOrdId            |-> clOrdId.value,
         origClOrdId        |-> origClOrdId.value,
         clearingFirm       |-> clearingFirm.value,
         routingFirmId      |-> routingFirmId.value,
         orderQty           |-> orderQty.value,
         price              |-> price.value,
         ordType            |-> ordType.value,
         maxFloor           |-> maxFloor.value,
         stopPx             |-> stopPx.value,
         cancelOrigOnReject |-> cancelOrigOnReject.value,
         reserved           |-> reserved.value,
         scratchPad         |-> scratchPad.value ], scratchPad.rest)

ZeroModifyOrderMessage ==
    [ clOrdId            |-> [i \in 1 .. 20 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      routingFirmId      |-> [i \in 1 .. 4 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      ordType            |-> [i \in 1 .. 1 |-> 0],
      maxFloor           |-> [i \in 1 .. 4 |-> 0],
      stopPx             |-> [i \in 1 .. 8 |-> 0],
      cancelOrigOnReject |-> [i \in 1 .. 1 |-> 0],
      reserved           |-> [i \in 1 .. 41 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.cancelOrigOnReject = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.reserved = one] : one \in Sample(41) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote: 22 bytes                                                         *)
(***************************************************************************)

Quote ==
    [ quoteSymbol : Sample(6),
      side        : Sample(1),
      openClose   : Sample(1),
      price       : Sample(8),
      orderQty    : Sample(4),
      scratchPad  : Sample(2) ]

EncodeQuote(message) ==
    message.quoteSymbol
        \o message.side
        \o message.openClose
        \o message.price
        \o message.orderQty
        \o message.scratchPad

DecodeQuote(bytes) ==
    LET quoteSymbol == ReadBytes(bytes, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET price == ReadBytes(openClose.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(orderQty.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ quoteSymbol |-> quoteSymbol.value,
         side        |-> side.value,
         openClose   |-> openClose.value,
         price       |-> price.value,
         orderQty    |-> orderQty.value,
         scratchPad  |-> scratchPad.value ], scratchPad.rest)

ZeroQuote ==
    [ quoteSymbol |-> [i \in 1 .. 6 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      openClose   |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      orderQty    |-> [i \in 1 .. 4 |-> 0],
      scratchPad  |-> [i \in 1 .. 2 |-> 0] ]

(* Quote at zero, then each field in turn at the values it is checked at *)
CheckedQuote ==
    { ZeroQuote }
        \cup { [ZeroQuote EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuote EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuote EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuote EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuote EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroQuote EXCEPT !.scratchPad = one] : one \in Sample(2) }

(* A run of Quote, written one after another *)
RECURSIVE EncodeQuoteList(_)
EncodeQuoteList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuote(Head(messages)) \o EncodeQuoteList(Tail(messages))

(* As many Quote as the field that counts them says *)
RECURSIVE ReadQuoteList(_, _)
ReadQuoteList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuote(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote of each kind, for the lists that carry them *)
OneQuote == { ZeroQuote }

(***************************************************************************)
(* Quote Update Message                                                    *)
(***************************************************************************)

QuoteUpdateMessage ==
    [ quoteUpdateId      : Sample(16),
      clearingFirm       : Sample(4),
      clearingAccount    : Sample(4),
      cmtaNumber         : Sample(4),
      account            : Sample(16),
      customGroupId      : Sample(2),
      sendTime           : Sample(8),
      postingInstruction : Sample(1),
      sessionEligibility : Sample(1),
      sizeModifier       : Sample(1),
      scratchPad         : Sample(2),
      quote              : SampleLists(OneQuote) ]

EncodeQuoteUpdateMessage(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.cmtaNumber
        \o message.account
        \o message.customGroupId
        \o message.sendTime
        \o message.postingInstruction
        \o message.sessionEligibility
        \o message.sizeModifier
        \o message.scratchPad
        \o EncodeUIntLE(Len(message.quote), 1)
        \o EncodeQuoteList(message.quote)

DecodeQuoteUpdateMessage(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(clearingAccount.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET account == ReadBytes(cmtaNumber.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(account.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET sendTime == ReadBytes(customGroupId.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET postingInstruction == ReadBytes(sendTime.rest, 1) IN IF ~postingInstruction.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(postingInstruction.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET sizeModifier == ReadBytes(sessionEligibility.rest, 1) IN IF ~sizeModifier.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(sizeModifier.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quote == ReadQuoteList(quoteCnt.rest, quoteCnt.value) IN IF ~quote.ok THEN Fail ELSE
    Ok([ quoteUpdateId      |-> quoteUpdateId.value,
         clearingFirm       |-> clearingFirm.value,
         clearingAccount    |-> clearingAccount.value,
         cmtaNumber         |-> cmtaNumber.value,
         account            |-> account.value,
         customGroupId      |-> customGroupId.value,
         sendTime           |-> sendTime.value,
         postingInstruction |-> postingInstruction.value,
         sessionEligibility |-> sessionEligibility.value,
         sizeModifier       |-> sizeModifier.value,
         scratchPad         |-> scratchPad.value,
         quote              |-> quote.value ], quote.rest)

ZeroQuoteUpdateMessage ==
    [ quoteUpdateId      |-> [i \in 1 .. 16 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      cmtaNumber         |-> [i \in 1 .. 4 |-> 0],
      account            |-> [i \in 1 .. 16 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      sendTime           |-> [i \in 1 .. 8 |-> 0],
      postingInstruction |-> [i \in 1 .. 1 |-> 0],
      sessionEligibility |-> [i \in 1 .. 1 |-> 0],
      sizeModifier       |-> [i \in 1 .. 1 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0],
      quote              |-> << >> ]

(* Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateMessage ==
    { ZeroQuoteUpdateMessage }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.postingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.sizeModifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateMessage EXCEPT !.quote = one] : one \in SampleLists(OneQuote) }

(***************************************************************************)
(* Quote Short: 16 bytes                                                   *)
(***************************************************************************)

QuoteShort ==
    [ quoteSymbol   : Sample(6),
      side          : Sample(1),
      openClose     : Sample(1),
      priceShort    : Sample(4),
      orderQtyShort : Sample(2),
      scratchPad    : Sample(2) ]

EncodeQuoteShort(message) ==
    message.quoteSymbol
        \o message.side
        \o message.openClose
        \o message.priceShort
        \o message.orderQtyShort
        \o message.scratchPad

DecodeQuoteShort(bytes) ==
    LET quoteSymbol == ReadBytes(bytes, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET priceShort == ReadBytes(openClose.rest, 4) IN IF ~priceShort.ok THEN Fail ELSE
    LET orderQtyShort == ReadBytes(priceShort.rest, 2) IN IF ~orderQtyShort.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(orderQtyShort.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ quoteSymbol   |-> quoteSymbol.value,
         side          |-> side.value,
         openClose     |-> openClose.value,
         priceShort    |-> priceShort.value,
         orderQtyShort |-> orderQtyShort.value,
         scratchPad    |-> scratchPad.value ], scratchPad.rest)

ZeroQuoteShort ==
    [ quoteSymbol   |-> [i \in 1 .. 6 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      openClose     |-> [i \in 1 .. 1 |-> 0],
      priceShort    |-> [i \in 1 .. 4 |-> 0],
      orderQtyShort |-> [i \in 1 .. 2 |-> 0],
      scratchPad    |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Short at zero, then each field in turn at the values it is checked at *)
CheckedQuoteShort ==
    { ZeroQuoteShort }
        \cup { [ZeroQuoteShort EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteShort EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShort EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShort EXCEPT !.priceShort = one] : one \in Sample(4) }
        \cup { [ZeroQuoteShort EXCEPT !.orderQtyShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteShort EXCEPT !.scratchPad = one] : one \in Sample(2) }

(* A run of Quote Short, written one after another *)
RECURSIVE EncodeQuoteShortList(_)
EncodeQuoteShortList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteShort(Head(messages)) \o EncodeQuoteShortList(Tail(messages))

(* As many Quote Short as the field that counts them says *)
RECURSIVE ReadQuoteShortList(_, _)
ReadQuoteShortList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteShort(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteShortList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Short of each kind, for the lists that carry them *)
OneQuoteShort == { ZeroQuoteShort }

(***************************************************************************)
(* Quote Update Short Message                                              *)
(***************************************************************************)

QuoteUpdateShortMessage ==
    [ quoteUpdateId      : Sample(16),
      clearingFirm       : Sample(4),
      clearingAccount    : Sample(4),
      customGroupId      : Sample(2),
      sendTime           : Sample(8),
      postingInstruction : Sample(1),
      sessionEligibility : Sample(1),
      sizeModifier       : Sample(1),
      scratchPad         : Sample(2),
      quoteShort         : SampleLists(OneQuoteShort) ]

EncodeQuoteUpdateShortMessage(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.customGroupId
        \o message.sendTime
        \o message.postingInstruction
        \o message.sessionEligibility
        \o message.sizeModifier
        \o message.scratchPad
        \o EncodeUIntLE(Len(message.quoteShort), 1)
        \o EncodeQuoteShortList(message.quoteShort)

DecodeQuoteUpdateShortMessage(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(clearingAccount.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET sendTime == ReadBytes(customGroupId.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET postingInstruction == ReadBytes(sendTime.rest, 1) IN IF ~postingInstruction.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(postingInstruction.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET sizeModifier == ReadBytes(sessionEligibility.rest, 1) IN IF ~sizeModifier.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(sizeModifier.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quoteShort == ReadQuoteShortList(quoteCnt.rest, quoteCnt.value) IN IF ~quoteShort.ok THEN Fail ELSE
    Ok([ quoteUpdateId      |-> quoteUpdateId.value,
         clearingFirm       |-> clearingFirm.value,
         clearingAccount    |-> clearingAccount.value,
         customGroupId      |-> customGroupId.value,
         sendTime           |-> sendTime.value,
         postingInstruction |-> postingInstruction.value,
         sessionEligibility |-> sessionEligibility.value,
         sizeModifier       |-> sizeModifier.value,
         scratchPad         |-> scratchPad.value,
         quoteShort         |-> quoteShort.value ], quoteShort.rest)

ZeroQuoteUpdateShortMessage ==
    [ quoteUpdateId      |-> [i \in 1 .. 16 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      sendTime           |-> [i \in 1 .. 8 |-> 0],
      postingInstruction |-> [i \in 1 .. 1 |-> 0],
      sessionEligibility |-> [i \in 1 .. 1 |-> 0],
      sizeModifier       |-> [i \in 1 .. 1 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0],
      quoteShort         |-> << >> ]

(* Quote Update Short Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateShortMessage ==
    { ZeroQuoteUpdateShortMessage }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.postingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.sizeModifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateShortMessage EXCEPT !.quoteShort = one] : one \in SampleLists(OneQuoteShort) }

(***************************************************************************)
(* Quote: 22 bytes                                                         *)
(***************************************************************************)

Quote2 ==
    [ quoteSymbol : Sample(6),
      side        : Sample(1),
      openClose   : Sample(1),
      price       : Sample(8),
      orderQty    : Sample(4),
      scratchPad  : Sample(2) ]

EncodeQuote2(message) ==
    message.quoteSymbol
        \o message.side
        \o message.openClose
        \o message.price
        \o message.orderQty
        \o message.scratchPad

DecodeQuote2(bytes) ==
    LET quoteSymbol == ReadBytes(bytes, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET price == ReadBytes(openClose.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(orderQty.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ quoteSymbol |-> quoteSymbol.value,
         side        |-> side.value,
         openClose   |-> openClose.value,
         price       |-> price.value,
         orderQty    |-> orderQty.value,
         scratchPad  |-> scratchPad.value ], scratchPad.rest)

ZeroQuote2 ==
    [ quoteSymbol |-> [i \in 1 .. 6 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      openClose   |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      orderQty    |-> [i \in 1 .. 4 |-> 0],
      scratchPad  |-> [i \in 1 .. 2 |-> 0] ]

(* Quote at zero, then each field in turn at the values it is checked at *)
CheckedQuote2 ==
    { ZeroQuote2 }
        \cup { [ZeroQuote2 EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuote2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuote2 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuote2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuote2 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroQuote2 EXCEPT !.scratchPad = one] : one \in Sample(2) }

(* A run of Quote, written one after another *)
RECURSIVE EncodeQuote2List(_)
EncodeQuote2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuote2(Head(messages)) \o EncodeQuote2List(Tail(messages))

(* As many Quote as the field that counts them says *)
RECURSIVE ReadQuote2List(_, _)
ReadQuote2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuote2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuote2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote of each kind, for the lists that carry them *)
OneQuote2 == { ZeroQuote2 }

(***************************************************************************)
(* Complex Quote Update Message                                            *)
(***************************************************************************)

ComplexQuoteUpdateMessage ==
    [ quoteUpdateId      : Sample(16),
      clearingFirm       : Sample(4),
      clearingAccount    : Sample(4),
      cmtaNumber         : Sample(4),
      account            : Sample(16),
      customGroupId      : Sample(2),
      sendTime           : Sample(8),
      postingInstruction : Sample(1),
      sessionEligibility : Sample(1),
      sizeModifier       : Sample(1),
      scratchPad         : Sample(2),
      quote              : SampleLists(OneQuote2) ]

EncodeComplexQuoteUpdateMessage(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.cmtaNumber
        \o message.account
        \o message.customGroupId
        \o message.sendTime
        \o message.postingInstruction
        \o message.sessionEligibility
        \o message.sizeModifier
        \o message.scratchPad
        \o EncodeUIntLE(Len(message.quote), 1)
        \o EncodeQuote2List(message.quote)

DecodeComplexQuoteUpdateMessage(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(clearingAccount.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET account == ReadBytes(cmtaNumber.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(account.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET sendTime == ReadBytes(customGroupId.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET postingInstruction == ReadBytes(sendTime.rest, 1) IN IF ~postingInstruction.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(postingInstruction.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET sizeModifier == ReadBytes(sessionEligibility.rest, 1) IN IF ~sizeModifier.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(sizeModifier.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quote == ReadQuote2List(quoteCnt.rest, quoteCnt.value) IN IF ~quote.ok THEN Fail ELSE
    Ok([ quoteUpdateId      |-> quoteUpdateId.value,
         clearingFirm       |-> clearingFirm.value,
         clearingAccount    |-> clearingAccount.value,
         cmtaNumber         |-> cmtaNumber.value,
         account            |-> account.value,
         customGroupId      |-> customGroupId.value,
         sendTime           |-> sendTime.value,
         postingInstruction |-> postingInstruction.value,
         sessionEligibility |-> sessionEligibility.value,
         sizeModifier       |-> sizeModifier.value,
         scratchPad         |-> scratchPad.value,
         quote              |-> quote.value ], quote.rest)

ZeroComplexQuoteUpdateMessage ==
    [ quoteUpdateId      |-> [i \in 1 .. 16 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      cmtaNumber         |-> [i \in 1 .. 4 |-> 0],
      account            |-> [i \in 1 .. 16 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      sendTime           |-> [i \in 1 .. 8 |-> 0],
      postingInstruction |-> [i \in 1 .. 1 |-> 0],
      sessionEligibility |-> [i \in 1 .. 1 |-> 0],
      sizeModifier       |-> [i \in 1 .. 1 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0],
      quote              |-> << >> ]

(* Complex Quote Update Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuoteUpdateMessage ==
    { ZeroComplexQuoteUpdateMessage }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.postingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.sizeModifier = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroComplexQuoteUpdateMessage EXCEPT !.quote = one] : one \in SampleLists(OneQuote2) }

(***************************************************************************)
(* Quote Short: 16 bytes                                                   *)
(***************************************************************************)

QuoteShort2 ==
    [ quoteSymbol   : Sample(6),
      side          : Sample(1),
      openClose     : Sample(1),
      priceShort    : Sample(4),
      orderQtyShort : Sample(2),
      scratchPad    : Sample(2) ]

EncodeQuoteShort2(message) ==
    message.quoteSymbol
        \o message.side
        \o message.openClose
        \o message.priceShort
        \o message.orderQtyShort
        \o message.scratchPad

DecodeQuoteShort2(bytes) ==
    LET quoteSymbol == ReadBytes(bytes, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET openClose == ReadBytes(side.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET priceShort == ReadBytes(openClose.rest, 4) IN IF ~priceShort.ok THEN Fail ELSE
    LET orderQtyShort == ReadBytes(priceShort.rest, 2) IN IF ~orderQtyShort.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(orderQtyShort.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ quoteSymbol   |-> quoteSymbol.value,
         side          |-> side.value,
         openClose     |-> openClose.value,
         priceShort    |-> priceShort.value,
         orderQtyShort |-> orderQtyShort.value,
         scratchPad    |-> scratchPad.value ], scratchPad.rest)

ZeroQuoteShort2 ==
    [ quoteSymbol   |-> [i \in 1 .. 6 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      openClose     |-> [i \in 1 .. 1 |-> 0],
      priceShort    |-> [i \in 1 .. 4 |-> 0],
      orderQtyShort |-> [i \in 1 .. 2 |-> 0],
      scratchPad    |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Short at zero, then each field in turn at the values it is checked at *)
CheckedQuoteShort2 ==
    { ZeroQuoteShort2 }
        \cup { [ZeroQuoteShort2 EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteShort2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShort2 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroQuoteShort2 EXCEPT !.priceShort = one] : one \in Sample(4) }
        \cup { [ZeroQuoteShort2 EXCEPT !.orderQtyShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteShort2 EXCEPT !.scratchPad = one] : one \in Sample(2) }

(* A run of Quote Short, written one after another *)
RECURSIVE EncodeQuoteShort2List(_)
EncodeQuoteShort2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteShort2(Head(messages)) \o EncodeQuoteShort2List(Tail(messages))

(* As many Quote Short as the field that counts them says *)
RECURSIVE ReadQuoteShort2List(_, _)
ReadQuoteShort2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteShort2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteShort2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Short of each kind, for the lists that carry them *)
OneQuoteShort2 == { ZeroQuoteShort2 }

(***************************************************************************)
(* Complex Quote Update Short Message                                      *)
(***************************************************************************)

ComplexQuoteUpdateShortMessage ==
    [ quoteUpdateId      : Sample(16),
      clearingFirm       : Sample(4),
      clearingAccount    : Sample(4),
      customGroupId      : Sample(2),
      sendTime           : Sample(8),
      postingInstruction : Sample(1),
      sessionEligibility : Sample(1),
      sizeModifier       : Sample(1),
      scratchPad         : Sample(2),
      quoteShort         : SampleLists(OneQuoteShort2) ]

EncodeComplexQuoteUpdateShortMessage(message) ==
    message.quoteUpdateId
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.customGroupId
        \o message.sendTime
        \o message.postingInstruction
        \o message.sessionEligibility
        \o message.sizeModifier
        \o message.scratchPad
        \o EncodeUIntLE(Len(message.quoteShort), 1)
        \o EncodeQuoteShort2List(message.quoteShort)

DecodeComplexQuoteUpdateShortMessage(bytes) ==
    LET quoteUpdateId == ReadBytes(bytes, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteUpdateId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(clearingAccount.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET sendTime == ReadBytes(customGroupId.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET postingInstruction == ReadBytes(sendTime.rest, 1) IN IF ~postingInstruction.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(postingInstruction.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET sizeModifier == ReadBytes(sessionEligibility.rest, 1) IN IF ~sizeModifier.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(sizeModifier.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quoteShort == ReadQuoteShort2List(quoteCnt.rest, quoteCnt.value) IN IF ~quoteShort.ok THEN Fail ELSE
    Ok([ quoteUpdateId      |-> quoteUpdateId.value,
         clearingFirm       |-> clearingFirm.value,
         clearingAccount    |-> clearingAccount.value,
         customGroupId      |-> customGroupId.value,
         sendTime           |-> sendTime.value,
         postingInstruction |-> postingInstruction.value,
         sessionEligibility |-> sessionEligibility.value,
         sizeModifier       |-> sizeModifier.value,
         scratchPad         |-> scratchPad.value,
         quoteShort         |-> quoteShort.value ], quoteShort.rest)

ZeroComplexQuoteUpdateShortMessage ==
    [ quoteUpdateId      |-> [i \in 1 .. 16 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      sendTime           |-> [i \in 1 .. 8 |-> 0],
      postingInstruction |-> [i \in 1 .. 1 |-> 0],
      sessionEligibility |-> [i \in 1 .. 1 |-> 0],
      sizeModifier       |-> [i \in 1 .. 1 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0],
      quoteShort         |-> << >> ]

(* Complex Quote Update Short Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexQuoteUpdateShortMessage ==
    { ZeroComplexQuoteUpdateShortMessage }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.postingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.sizeModifier = one] : one \in Sample(1) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroComplexQuoteUpdateShortMessage EXCEPT !.quoteShort = one] : one \in SampleLists(OneQuoteShort2) }

(***************************************************************************)
(* Mass Cancel Inst: 8 bytes                                               *)
(***************************************************************************)

MassCancelInst2 ==
    [ clearingFirmFilter   : Sample(1),
      acknowledgementStyle : Sample(1),
      lockoutInstruction   : Sample(1),
      instrumentTypeFilter : Sample(1),
      gtcOrderFilter       : Sample(1),
      instructionDetails   : Sample(3) ]

EncodeMassCancelInst2(message) ==
    message.clearingFirmFilter
        \o message.acknowledgementStyle
        \o message.lockoutInstruction
        \o message.instrumentTypeFilter
        \o message.gtcOrderFilter
        \o message.instructionDetails

DecodeMassCancelInst2(bytes) ==
    LET clearingFirmFilter == ReadBytes(bytes, 1) IN IF ~clearingFirmFilter.ok THEN Fail ELSE
    LET acknowledgementStyle == ReadBytes(clearingFirmFilter.rest, 1) IN IF ~acknowledgementStyle.ok THEN Fail ELSE
    LET lockoutInstruction == ReadBytes(acknowledgementStyle.rest, 1) IN IF ~lockoutInstruction.ok THEN Fail ELSE
    LET instrumentTypeFilter == ReadBytes(lockoutInstruction.rest, 1) IN IF ~instrumentTypeFilter.ok THEN Fail ELSE
    LET gtcOrderFilter == ReadBytes(instrumentTypeFilter.rest, 1) IN IF ~gtcOrderFilter.ok THEN Fail ELSE
    LET instructionDetails == ReadBytes(gtcOrderFilter.rest, 3) IN IF ~instructionDetails.ok THEN Fail ELSE
    Ok([ clearingFirmFilter   |-> clearingFirmFilter.value,
         acknowledgementStyle |-> acknowledgementStyle.value,
         lockoutInstruction   |-> lockoutInstruction.value,
         instrumentTypeFilter |-> instrumentTypeFilter.value,
         gtcOrderFilter       |-> gtcOrderFilter.value,
         instructionDetails   |-> instructionDetails.value ], instructionDetails.rest)

ZeroMassCancelInst2 ==
    [ clearingFirmFilter   |-> [i \in 1 .. 1 |-> 0],
      acknowledgementStyle |-> [i \in 1 .. 1 |-> 0],
      lockoutInstruction   |-> [i \in 1 .. 1 |-> 0],
      instrumentTypeFilter |-> [i \in 1 .. 1 |-> 0],
      gtcOrderFilter       |-> [i \in 1 .. 1 |-> 0],
      instructionDetails   |-> [i \in 1 .. 3 |-> 0] ]

(* Mass Cancel Inst at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelInst2 ==
    { ZeroMassCancelInst2 }
        \cup { [ZeroMassCancelInst2 EXCEPT !.clearingFirmFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.acknowledgementStyle = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.lockoutInstruction = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.instrumentTypeFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.gtcOrderFilter = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelInst2 EXCEPT !.instructionDetails = one] : one \in Sample(3) }

(***************************************************************************)
(* Purge Orders V 2 Message: 56 bytes                                      *)
(***************************************************************************)

PurgeOrdersV2Message ==
    [ massCancelId       : Sample(20),
      clearingFirm       : Sample(4),
      routingFirmId      : Sample(4),
      riskRoot           : Sample(6),
      massCancelInst     : MassCancelInst2,
      sendTime           : Sample(8),
      targetMatchingUnit : Sample(1),
      scratchPad         : Sample(2),
      customGroupIdCnt   : 0 .. 255,
      customGroupId      : Sample(2) ]

EncodePurgeOrdersV2Message(message) ==
    message.massCancelId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.riskRoot
        \o EncodeMassCancelInst2(message.massCancelInst)
        \o message.sendTime
        \o message.targetMatchingUnit
        \o message.scratchPad
        \o EncodeUIntLE(message.customGroupIdCnt, 1)
        \o message.customGroupId

DecodePurgeOrdersV2Message(bytes) ==
    LET massCancelId == ReadBytes(bytes, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(massCancelId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET riskRoot == ReadBytes(routingFirmId.rest, 6) IN IF ~riskRoot.ok THEN Fail ELSE
    LET massCancelInst == DecodeMassCancelInst2(riskRoot.rest) IN IF ~massCancelInst.ok THEN Fail ELSE
    LET sendTime == ReadBytes(massCancelInst.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET targetMatchingUnit == ReadBytes(sendTime.rest, 1) IN IF ~targetMatchingUnit.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(targetMatchingUnit.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    LET customGroupIdCnt == ReadUIntLE(scratchPad.rest, 1) IN IF ~customGroupIdCnt.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(customGroupIdCnt.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    Ok([ massCancelId       |-> massCancelId.value,
         clearingFirm       |-> clearingFirm.value,
         routingFirmId      |-> routingFirmId.value,
         riskRoot           |-> riskRoot.value,
         massCancelInst     |-> massCancelInst.value,
         sendTime           |-> sendTime.value,
         targetMatchingUnit |-> targetMatchingUnit.value,
         scratchPad         |-> scratchPad.value,
         customGroupIdCnt   |-> customGroupIdCnt.value,
         customGroupId      |-> customGroupId.value ], customGroupId.rest)

ZeroPurgeOrdersV2Message ==
    [ massCancelId       |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      routingFirmId      |-> [i \in 1 .. 4 |-> 0],
      riskRoot           |-> [i \in 1 .. 6 |-> 0],
      massCancelInst     |-> ZeroMassCancelInst2,
      sendTime           |-> [i \in 1 .. 8 |-> 0],
      targetMatchingUnit |-> [i \in 1 .. 1 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0],
      customGroupIdCnt   |-> 0,
      customGroupId      |-> [i \in 1 .. 2 |-> 0] ]

(* Purge Orders V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeOrdersV2Message ==
    { ZeroPurgeOrdersV2Message }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.riskRoot = one] : one \in Sample(6) }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.massCancelInst = one] : one \in CheckedMassCancelInst2 }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.targetMatchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.scratchPad = one] : one \in Sample(2) }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.customGroupIdCnt = one] : one \in {0, 1, 255} }
        \cup { [ZeroPurgeOrdersV2Message EXCEPT !.customGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Reset Risk Message: 39 bytes                                            *)
(***************************************************************************)

ResetRiskMessage ==
    [ riskStatusId       : Sample(16),
      riskReset          : Sample(8),
      clearingFirm       : Sample(4),
      riskRoot           : Sample(6),
      targetMatchingUnit : Sample(1),
      customGroupId      : Sample(2),
      scratchPad         : Sample(2) ]

EncodeResetRiskMessage(message) ==
    message.riskStatusId
        \o message.riskReset
        \o message.clearingFirm
        \o message.riskRoot
        \o message.targetMatchingUnit
        \o message.customGroupId
        \o message.scratchPad

DecodeResetRiskMessage(bytes) ==
    LET riskStatusId == ReadBytes(bytes, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskReset == ReadBytes(riskStatusId.rest, 8) IN IF ~riskReset.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(riskReset.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET riskRoot == ReadBytes(clearingFirm.rest, 6) IN IF ~riskRoot.ok THEN Fail ELSE
    LET targetMatchingUnit == ReadBytes(riskRoot.rest, 1) IN IF ~targetMatchingUnit.ok THEN Fail ELSE
    LET customGroupId == ReadBytes(targetMatchingUnit.rest, 2) IN IF ~customGroupId.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(customGroupId.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ riskStatusId       |-> riskStatusId.value,
         riskReset          |-> riskReset.value,
         clearingFirm       |-> clearingFirm.value,
         riskRoot           |-> riskRoot.value,
         targetMatchingUnit |-> targetMatchingUnit.value,
         customGroupId      |-> customGroupId.value,
         scratchPad         |-> scratchPad.value ], scratchPad.rest)

ZeroResetRiskMessage ==
    [ riskStatusId       |-> [i \in 1 .. 16 |-> 0],
      riskReset          |-> [i \in 1 .. 8 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      riskRoot           |-> [i \in 1 .. 6 |-> 0],
      targetMatchingUnit |-> [i \in 1 .. 1 |-> 0],
      customGroupId      |-> [i \in 1 .. 2 |-> 0],
      scratchPad         |-> [i \in 1 .. 2 |-> 0] ]

(* Reset Risk Message at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskMessage ==
    { ZeroResetRiskMessage }
        \cup { [ZeroResetRiskMessage EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskMessage EXCEPT !.riskReset = one] : one \in Sample(8) }
        \cup { [ZeroResetRiskMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroResetRiskMessage EXCEPT !.riskRoot = one] : one \in Sample(6) }
        \cup { [ZeroResetRiskMessage EXCEPT !.targetMatchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroResetRiskMessage EXCEPT !.customGroupId = one] : one \in Sample(2) }
        \cup { [ZeroResetRiskMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Floor Trade Confirmation Message: 60 bytes                              *)
(***************************************************************************)

FloorTradeConfirmationMessage ==
    [ clOrdId      : Sample(20),
      execId       : Sample(8),
      symbol       : Sample(8),
      putOrCall    : Sample(1),
      strikePrice  : Sample(8),
      maturityDate : Sample(4),
      reportTime   : Sample(8),
      priceType    : Sample(1),
      scratchPad   : Sample(2) ]

EncodeFloorTradeConfirmationMessage(message) ==
    message.clOrdId
        \o message.execId
        \o message.symbol
        \o message.putOrCall
        \o message.strikePrice
        \o message.maturityDate
        \o message.reportTime
        \o message.priceType
        \o message.scratchPad

DecodeFloorTradeConfirmationMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET symbol == ReadBytes(execId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(symbol.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(strikePrice.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET reportTime == ReadBytes(maturityDate.rest, 8) IN IF ~reportTime.ok THEN Fail ELSE
    LET priceType == ReadBytes(reportTime.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(priceType.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         execId       |-> execId.value,
         symbol       |-> symbol.value,
         putOrCall    |-> putOrCall.value,
         strikePrice  |-> strikePrice.value,
         maturityDate |-> maturityDate.value,
         reportTime   |-> reportTime.value,
         priceType    |-> priceType.value,
         scratchPad   |-> scratchPad.value ], scratchPad.rest)

ZeroFloorTradeConfirmationMessage ==
    [ clOrdId      |-> [i \in 1 .. 20 |-> 0],
      execId       |-> [i \in 1 .. 8 |-> 0],
      symbol       |-> [i \in 1 .. 8 |-> 0],
      putOrCall    |-> [i \in 1 .. 1 |-> 0],
      strikePrice  |-> [i \in 1 .. 8 |-> 0],
      maturityDate |-> [i \in 1 .. 4 |-> 0],
      reportTime   |-> [i \in 1 .. 8 |-> 0],
      priceType    |-> [i \in 1 .. 1 |-> 0],
      scratchPad   |-> [i \in 1 .. 2 |-> 0] ]

(* Floor Trade Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedFloorTradeConfirmationMessage ==
    { ZeroFloorTradeConfirmationMessage }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.reportTime = one] : one \in Sample(8) }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroFloorTradeConfirmationMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Floor Trade Message: 123 bytes                                      *)
(***************************************************************************)

AddFloorTradeMessage ==
    [ clOrdId               : Sample(20),
      symbol                : Sample(8),
      putOrCall             : Sample(1),
      strikePrice           : Sample(8),
      maturityDate          : Sample(4),
      multilegReportingType : Sample(1),
      comboOrder            : Sample(1),
      account               : Sample(16),
      clearingOptionalData  : Sample(16),
      clearingAccount       : Sample(4),
      cmtaNumber            : Sample(4),
      floorTraderAcronym    : Sample(3),
      side                  : Sample(1),
      orderQty              : Sample(4),
      price                 : Sample(8),
      reportTime            : Sample(8),
      openClose             : Sample(1),
      floorTradeTime        : Sample(8),
      contraTrader          : Sample(4),
      priceType             : Sample(1),
      scratchPad            : Sample(2) ]

EncodeAddFloorTradeMessage(message) ==
    message.clOrdId
        \o message.symbol
        \o message.putOrCall
        \o message.strikePrice
        \o message.maturityDate
        \o message.multilegReportingType
        \o message.comboOrder
        \o message.account
        \o message.clearingOptionalData
        \o message.clearingAccount
        \o message.cmtaNumber
        \o message.floorTraderAcronym
        \o message.side
        \o message.orderQty
        \o message.price
        \o message.reportTime
        \o message.openClose
        \o message.floorTradeTime
        \o message.contraTrader
        \o message.priceType
        \o message.scratchPad

DecodeAddFloorTradeMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbol == ReadBytes(clOrdId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(symbol.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(strikePrice.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET multilegReportingType == ReadBytes(maturityDate.rest, 1) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET comboOrder == ReadBytes(multilegReportingType.rest, 1) IN IF ~comboOrder.ok THEN Fail ELSE
    LET account == ReadBytes(comboOrder.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clearingOptionalData == ReadBytes(account.rest, 16) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingOptionalData.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(clearingAccount.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET floorTraderAcronym == ReadBytes(cmtaNumber.rest, 3) IN IF ~floorTraderAcronym.ok THEN Fail ELSE
    LET side == ReadBytes(floorTraderAcronym.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reportTime == ReadBytes(price.rest, 8) IN IF ~reportTime.ok THEN Fail ELSE
    LET openClose == ReadBytes(reportTime.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET floorTradeTime == ReadBytes(openClose.rest, 8) IN IF ~floorTradeTime.ok THEN Fail ELSE
    LET contraTrader == ReadBytes(floorTradeTime.rest, 4) IN IF ~contraTrader.ok THEN Fail ELSE
    LET priceType == ReadBytes(contraTrader.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(priceType.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ clOrdId               |-> clOrdId.value,
         symbol                |-> symbol.value,
         putOrCall             |-> putOrCall.value,
         strikePrice           |-> strikePrice.value,
         maturityDate          |-> maturityDate.value,
         multilegReportingType |-> multilegReportingType.value,
         comboOrder            |-> comboOrder.value,
         account               |-> account.value,
         clearingOptionalData  |-> clearingOptionalData.value,
         clearingAccount       |-> clearingAccount.value,
         cmtaNumber            |-> cmtaNumber.value,
         floorTraderAcronym    |-> floorTraderAcronym.value,
         side                  |-> side.value,
         orderQty              |-> orderQty.value,
         price                 |-> price.value,
         reportTime            |-> reportTime.value,
         openClose             |-> openClose.value,
         floorTradeTime        |-> floorTradeTime.value,
         contraTrader          |-> contraTrader.value,
         priceType             |-> priceType.value,
         scratchPad            |-> scratchPad.value ], scratchPad.rest)

ZeroAddFloorTradeMessage ==
    [ clOrdId               |-> [i \in 1 .. 20 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0],
      putOrCall             |-> [i \in 1 .. 1 |-> 0],
      strikePrice           |-> [i \in 1 .. 8 |-> 0],
      maturityDate          |-> [i \in 1 .. 4 |-> 0],
      multilegReportingType |-> [i \in 1 .. 1 |-> 0],
      comboOrder            |-> [i \in 1 .. 1 |-> 0],
      account               |-> [i \in 1 .. 16 |-> 0],
      clearingOptionalData  |-> [i \in 1 .. 16 |-> 0],
      clearingAccount       |-> [i \in 1 .. 4 |-> 0],
      cmtaNumber            |-> [i \in 1 .. 4 |-> 0],
      floorTraderAcronym    |-> [i \in 1 .. 3 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      reportTime            |-> [i \in 1 .. 8 |-> 0],
      openClose             |-> [i \in 1 .. 1 |-> 0],
      floorTradeTime        |-> [i \in 1 .. 8 |-> 0],
      contraTrader          |-> [i \in 1 .. 4 |-> 0],
      priceType             |-> [i \in 1 .. 1 |-> 0],
      scratchPad            |-> [i \in 1 .. 2 |-> 0] ]

(* Add Floor Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAddFloorTradeMessage ==
    { ZeroAddFloorTradeMessage }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.comboOrder = one] : one \in Sample(1) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.clearingOptionalData = one] : one \in Sample(16) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.floorTraderAcronym = one] : one \in Sample(3) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.reportTime = one] : one \in Sample(8) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.floorTradeTime = one] : one \in Sample(8) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.contraTrader = one] : one \in Sample(4) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroAddFloorTradeMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Delete Floor Trade Message: 52 bytes                                    *)
(***************************************************************************)

DeleteFloorTradeMessage ==
    [ clOrdId      : Sample(20),
      execId       : Sample(8),
      symbol       : Sample(8),
      putOrCall    : Sample(1),
      strikePrice  : Sample(8),
      maturityDate : Sample(4),
      side         : Sample(1),
      scratchPad   : Sample(2) ]

EncodeDeleteFloorTradeMessage(message) ==
    message.clOrdId
        \o message.execId
        \o message.symbol
        \o message.putOrCall
        \o message.strikePrice
        \o message.maturityDate
        \o message.side
        \o message.scratchPad

DecodeDeleteFloorTradeMessage(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET symbol == ReadBytes(execId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(symbol.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(strikePrice.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET side == ReadBytes(maturityDate.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET scratchPad == ReadBytes(side.rest, 2) IN IF ~scratchPad.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         execId       |-> execId.value,
         symbol       |-> symbol.value,
         putOrCall    |-> putOrCall.value,
         strikePrice  |-> strikePrice.value,
         maturityDate |-> maturityDate.value,
         side         |-> side.value,
         scratchPad   |-> scratchPad.value ], scratchPad.rest)

ZeroDeleteFloorTradeMessage ==
    [ clOrdId      |-> [i \in 1 .. 20 |-> 0],
      execId       |-> [i \in 1 .. 8 |-> 0],
      symbol       |-> [i \in 1 .. 8 |-> 0],
      putOrCall    |-> [i \in 1 .. 1 |-> 0],
      strikePrice  |-> [i \in 1 .. 8 |-> 0],
      maturityDate |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      scratchPad   |-> [i \in 1 .. 2 |-> 0] ]

(* Delete Floor Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteFloorTradeMessage ==
    { ZeroDeleteFloorTradeMessage }
        \cup { [ZeroDeleteFloorTradeMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteFloorTradeMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteFloorTradeMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroDeleteFloorTradeMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroDeleteFloorTradeMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroDeleteFloorTradeMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroDeleteFloorTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteFloorTradeMessage EXCEPT !.scratchPad = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm Message, selected by Firm Message Type                             *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LogoutRequestCode == 2  \* 0x02
ClientHeartbeatCode == 3  \* 0x03
NewOrderMessageCode == 2001  \* 0x7d1
NewOrderShortMessageCode == 2002  \* 0x7d2
NewOrderCrossMessageCode == 2003  \* 0x7d3
NewComplexInstrumentMessageCode == 2005  \* 0x7d5
NewComplexOrderMessageCode == 2006  \* 0x7d6
NewComplexOrderV2MessageCode == 2023  \* 0x7e7
NewComplexOrderShortMessageCode == 2007  \* 0x7d7
NewOrderCrossMultilegMessageCode == 2008  \* 0x7d8
CancelOrderMessageCode == 2010  \* 0x7da
MassCancelOrderMessageCode == 2015  \* 0x7df
ModifyOrderMessageCode == 2011  \* 0x7db
QuoteUpdateMessageCode == 2012  \* 0x7dc
QuoteUpdateShortMessageCode == 2013  \* 0x7dd
ComplexQuoteUpdateMessageCode == 2017  \* 0x7e1
ComplexQuoteUpdateShortMessageCode == 2018  \* 0x7e2
PurgeOrdersV2MessageCode == 2021  \* 0x7e5
ResetRiskMessageCode == 2014  \* 0x7de
FloorTradeConfirmationMessageCode == 2020  \* 0x7e4
AddFloorTradeMessageCode == 2019  \* 0x7e3
DeleteFloorTradeMessageCode == 2022  \* 0x7e6

FirmMessage ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {NewOrderShortMessageCode}, body : NewOrderShortMessage ]
        \cup [ tag : {NewOrderCrossMessageCode}, body : NewOrderCrossMessage ]
        \cup [ tag : {NewComplexInstrumentMessageCode}, body : NewComplexInstrumentMessage ]
        \cup [ tag : {NewComplexOrderMessageCode}, body : NewComplexOrderMessage ]
        \cup [ tag : {NewComplexOrderV2MessageCode}, body : NewComplexOrderV2Message ]
        \cup [ tag : {NewComplexOrderShortMessageCode}, body : NewComplexOrderShortMessage ]
        \cup [ tag : {NewOrderCrossMultilegMessageCode}, body : NewOrderCrossMultilegMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {MassCancelOrderMessageCode}, body : MassCancelOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {QuoteUpdateMessageCode}, body : QuoteUpdateMessage ]
        \cup [ tag : {QuoteUpdateShortMessageCode}, body : QuoteUpdateShortMessage ]
        \cup [ tag : {ComplexQuoteUpdateMessageCode}, body : ComplexQuoteUpdateMessage ]
        \cup [ tag : {ComplexQuoteUpdateShortMessageCode}, body : ComplexQuoteUpdateShortMessage ]
        \cup [ tag : {PurgeOrdersV2MessageCode}, body : PurgeOrdersV2Message ]
        \cup [ tag : {ResetRiskMessageCode}, body : ResetRiskMessage ]
        \cup [ tag : {FloorTradeConfirmationMessageCode}, body : FloorTradeConfirmationMessage ]
        \cup [ tag : {AddFloorTradeMessageCode}, body : AddFloorTradeMessage ]
        \cup [ tag : {DeleteFloorTradeMessageCode}, body : DeleteFloorTradeMessage ]

EncodeFirmMessage(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LogoutRequestCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = NewOrderShortMessageCode -> EncodeNewOrderShortMessage(message.body)
      [] message.tag = NewOrderCrossMessageCode -> EncodeNewOrderCrossMessage(message.body)
      [] message.tag = NewComplexInstrumentMessageCode -> EncodeNewComplexInstrumentMessage(message.body)
      [] message.tag = NewComplexOrderMessageCode -> EncodeNewComplexOrderMessage(message.body)
      [] message.tag = NewComplexOrderV2MessageCode -> EncodeNewComplexOrderV2Message(message.body)
      [] message.tag = NewComplexOrderShortMessageCode -> EncodeNewComplexOrderShortMessage(message.body)
      [] message.tag = NewOrderCrossMultilegMessageCode -> EncodeNewOrderCrossMultilegMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = MassCancelOrderMessageCode -> EncodeMassCancelOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = QuoteUpdateMessageCode -> EncodeQuoteUpdateMessage(message.body)
      [] message.tag = QuoteUpdateShortMessageCode -> EncodeQuoteUpdateShortMessage(message.body)
      [] message.tag = ComplexQuoteUpdateMessageCode -> EncodeComplexQuoteUpdateMessage(message.body)
      [] message.tag = ComplexQuoteUpdateShortMessageCode -> EncodeComplexQuoteUpdateShortMessage(message.body)
      [] message.tag = PurgeOrdersV2MessageCode -> EncodePurgeOrdersV2Message(message.body)
      [] message.tag = ResetRiskMessageCode -> EncodeResetRiskMessage(message.body)
      [] message.tag = FloorTradeConfirmationMessageCode -> EncodeFloorTradeConfirmationMessage(message.body)
      [] message.tag = AddFloorTradeMessageCode -> EncodeAddFloorTradeMessage(message.body)
      [] message.tag = DeleteFloorTradeMessageCode -> EncodeDeleteFloorTradeMessage(message.body)

DecodeFirmMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = NewOrderShortMessageCode -> DecodeNewOrderShortMessage(bytes)
              [] tag = NewOrderCrossMessageCode -> DecodeNewOrderCrossMessage(bytes)
              [] tag = NewComplexInstrumentMessageCode -> DecodeNewComplexInstrumentMessage(bytes)
              [] tag = NewComplexOrderMessageCode -> DecodeNewComplexOrderMessage(bytes)
              [] tag = NewComplexOrderV2MessageCode -> DecodeNewComplexOrderV2Message(bytes)
              [] tag = NewComplexOrderShortMessageCode -> DecodeNewComplexOrderShortMessage(bytes)
              [] tag = NewOrderCrossMultilegMessageCode -> DecodeNewOrderCrossMultilegMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = MassCancelOrderMessageCode -> DecodeMassCancelOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = QuoteUpdateMessageCode -> DecodeQuoteUpdateMessage(bytes)
              [] tag = QuoteUpdateShortMessageCode -> DecodeQuoteUpdateShortMessage(bytes)
              [] tag = ComplexQuoteUpdateMessageCode -> DecodeComplexQuoteUpdateMessage(bytes)
              [] tag = ComplexQuoteUpdateShortMessageCode -> DecodeComplexQuoteUpdateShortMessage(bytes)
              [] tag = PurgeOrdersV2MessageCode -> DecodePurgeOrdersV2Message(bytes)
              [] tag = ResetRiskMessageCode -> DecodeResetRiskMessage(bytes)
              [] tag = FloorTradeConfirmationMessageCode -> DecodeFloorTradeConfirmationMessage(bytes)
              [] tag = AddFloorTradeMessageCode -> DecodeAddFloorTradeMessage(bytes)
              [] tag = DeleteFloorTradeMessageCode -> DecodeDeleteFloorTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroFirmMessage == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Firm Message in turn, at the values the message it names is checked at *)
CheckedFirmMessage ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> NewOrderShortMessageCode, body |-> one] : one \in CheckedNewOrderShortMessage }
        \cup { [tag |-> NewOrderCrossMessageCode, body |-> one] : one \in CheckedNewOrderCrossMessage }
        \cup { [tag |-> NewComplexInstrumentMessageCode, body |-> one] : one \in CheckedNewComplexInstrumentMessage }
        \cup { [tag |-> NewComplexOrderMessageCode, body |-> one] : one \in CheckedNewComplexOrderMessage }
        \cup { [tag |-> NewComplexOrderV2MessageCode, body |-> one] : one \in CheckedNewComplexOrderV2Message }
        \cup { [tag |-> NewComplexOrderShortMessageCode, body |-> one] : one \in CheckedNewComplexOrderShortMessage }
        \cup { [tag |-> NewOrderCrossMultilegMessageCode, body |-> one] : one \in CheckedNewOrderCrossMultilegMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> MassCancelOrderMessageCode, body |-> one] : one \in CheckedMassCancelOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> QuoteUpdateMessageCode, body |-> one] : one \in CheckedQuoteUpdateMessage }
        \cup { [tag |-> QuoteUpdateShortMessageCode, body |-> one] : one \in CheckedQuoteUpdateShortMessage }
        \cup { [tag |-> ComplexQuoteUpdateMessageCode, body |-> one] : one \in CheckedComplexQuoteUpdateMessage }
        \cup { [tag |-> ComplexQuoteUpdateShortMessageCode, body |-> one] : one \in CheckedComplexQuoteUpdateShortMessage }
        \cup { [tag |-> PurgeOrdersV2MessageCode, body |-> one] : one \in CheckedPurgeOrdersV2Message }
        \cup { [tag |-> ResetRiskMessageCode, body |-> one] : one \in CheckedResetRiskMessage }
        \cup { [tag |-> FloorTradeConfirmationMessageCode, body |-> one] : one \in CheckedFloorTradeConfirmationMessage }
        \cup { [tag |-> AddFloorTradeMessageCode, body |-> one] : one \in CheckedAddFloorTradeMessage }
        \cup { [tag |-> DeleteFloorTradeMessageCode, body |-> one] : one \in CheckedDeleteFloorTradeMessage }

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

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch ==
    \A message \in CheckedPreventMatch :
        LET read == DecodePreventMatch(EncodePreventMatch(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessage ==
    \A message \in CheckedNewOrderMessage :
        LET read == DecodeNewOrderMessage(EncodeNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch2 ==
    \A message \in CheckedPreventMatch2 :
        LET read == DecodePreventMatch2(EncodePreventMatch2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderShortMessage ==
    \A message \in CheckedNewOrderShortMessage :
        LET read == DecodeNewOrderShortMessage(EncodeNewOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch3 ==
    \A message \in CheckedPreventMatch3 :
        LET read == DecodePreventMatch3(EncodePreventMatch3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocation ==
    \A message \in CheckedAllocation :
        LET read == DecodeAllocation(EncodeAllocation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossMessage ==
    \A message \in CheckedNewOrderCrossMessage :
        LET read == DecodeNewOrderCrossMessage(EncodeNewOrderCrossMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexLeg ==
    \A message \in CheckedComplexLeg :
        LET read == DecodeComplexLeg(EncodeComplexLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Instrument Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexInstrumentMessage ==
    \A message \in CheckedNewComplexInstrumentMessage :
        LET read == DecodeNewComplexInstrumentMessage(EncodeNewComplexInstrumentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch4 ==
    \A message \in CheckedPreventMatch4 :
        LET read == DecodePreventMatch4(EncodePreventMatch4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexOrderMessage ==
    \A message \in CheckedNewComplexOrderMessage :
        LET read == DecodeNewComplexOrderMessage(EncodeNewComplexOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch5 ==
    \A message \in CheckedPreventMatch5 :
        LET read == DecodePreventMatch5(EncodePreventMatch5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Order V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexOrderV2Message ==
    \A message \in CheckedNewComplexOrderV2Message :
        LET read == DecodeNewComplexOrderV2Message(EncodeNewComplexOrderV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch6 ==
    \A message \in CheckedPreventMatch6 :
        LET read == DecodePreventMatch6(EncodePreventMatch6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexOrderShortMessage ==
    \A message \in CheckedNewComplexOrderShortMessage :
        LET read == DecodeNewComplexOrderShortMessage(EncodeNewComplexOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prevent Match decodes back to what was encoded, and leaves nothing over *)
RoundTripPreventMatch7 ==
    \A message \in CheckedPreventMatch7 :
        LET read == DecodePreventMatch7(EncodePreventMatch7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multileg Allocation decodes back to what was encoded, and leaves nothing over *)
RoundTripMultilegAllocation ==
    \A message \in CheckedMultilegAllocation :
        LET read == DecodeMultilegAllocation(EncodeMultilegAllocation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Multileg Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossMultilegMessage ==
    \A message \in CheckedNewOrderCrossMultilegMessage :
        LET read == DecodeNewOrderCrossMultilegMessage(EncodeNewOrderCrossMultilegMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderMessage ==
    \A message \in CheckedCancelOrderMessage :
        LET read == DecodeCancelOrderMessage(EncodeCancelOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Inst decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelInst ==
    \A message \in CheckedMassCancelInst :
        LET read == DecodeMassCancelInst(EncodeMassCancelInst(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelOrderMessage ==
    \A message \in CheckedMassCancelOrderMessage :
        LET read == DecodeMassCancelOrderMessage(EncodeMassCancelOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote ==
    \A message \in CheckedQuote :
        LET read == DecodeQuote(EncodeQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateMessage ==
    \A message \in CheckedQuoteUpdateMessage :
        LET read == DecodeQuoteUpdateMessage(EncodeQuoteUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Short decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteShort ==
    \A message \in CheckedQuoteShort :
        LET read == DecodeQuoteShort(EncodeQuoteShort(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateShortMessage ==
    \A message \in CheckedQuoteUpdateShortMessage :
        LET read == DecodeQuoteUpdateShortMessage(EncodeQuoteUpdateShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote2 ==
    \A message \in CheckedQuote2 :
        LET read == DecodeQuote2(EncodeQuote2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quote Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuoteUpdateMessage ==
    \A message \in CheckedComplexQuoteUpdateMessage :
        LET read == DecodeComplexQuoteUpdateMessage(EncodeComplexQuoteUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Short decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteShort2 ==
    \A message \in CheckedQuoteShort2 :
        LET read == DecodeQuoteShort2(EncodeQuoteShort2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Quote Update Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexQuoteUpdateShortMessage ==
    \A message \in CheckedComplexQuoteUpdateShortMessage :
        LET read == DecodeComplexQuoteUpdateShortMessage(EncodeComplexQuoteUpdateShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Inst decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelInst2 ==
    \A message \in CheckedMassCancelInst2 :
        LET read == DecodeMassCancelInst2(EncodeMassCancelInst2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Orders V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeOrdersV2Message ==
    \A message \in CheckedPurgeOrdersV2Message :
        LET read == DecodePurgeOrdersV2Message(EncodePurgeOrdersV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskMessage ==
    \A message \in CheckedResetRiskMessage :
        LET read == DecodeResetRiskMessage(EncodeResetRiskMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Floor Trade Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFloorTradeConfirmationMessage ==
    \A message \in CheckedFloorTradeConfirmationMessage :
        LET read == DecodeFloorTradeConfirmationMessage(EncodeFloorTradeConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Floor Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddFloorTradeMessage ==
    \A message \in CheckedAddFloorTradeMessage :
        LET read == DecodeAddFloorTradeMessage(EncodeAddFloorTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Floor Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteFloorTradeMessage ==
    \A message \in CheckedDeleteFloorTradeMessage :
        LET read == DecodeDeleteFloorTradeMessage(EncodeDeleteFloorTradeMessage(message))
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
