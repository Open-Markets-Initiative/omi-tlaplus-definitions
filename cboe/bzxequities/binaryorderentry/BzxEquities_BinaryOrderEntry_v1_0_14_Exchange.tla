----------- MODULE BzxEquities_BinaryOrderEntry_v1_0_14_Exchange -----------
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
(* Login Response Message                                                  *)
(***************************************************************************)

LoginResponseMessage ==
    [ loginResponseStatus : Sample(1),
      loginResponseText   : Sample(60),
      clientSequence      : Sample(4),
      unitSequence        : SampleLists(OneUnitSequence) ]

EncodeLoginResponseMessage(message) ==
    message.loginResponseStatus
        \o message.loginResponseText
        \o message.clientSequence
        \o EncodeUIntLE(Len(message.unitSequence), 1)
        \o EncodeUnitSequenceList(message.unitSequence)

DecodeLoginResponseMessage(bytes) ==
    LET loginResponseStatus == ReadBytes(bytes, 1) IN IF ~loginResponseStatus.ok THEN Fail ELSE
    LET loginResponseText == ReadBytes(loginResponseStatus.rest, 60) IN IF ~loginResponseText.ok THEN Fail ELSE
    LET clientSequence == ReadBytes(loginResponseText.rest, 4) IN IF ~clientSequence.ok THEN Fail ELSE
    LET numberOfUnits == ReadUIntLE(clientSequence.rest, 1) IN IF ~numberOfUnits.ok THEN Fail ELSE
    LET unitSequence == ReadUnitSequenceList(numberOfUnits.rest, numberOfUnits.value) IN IF ~unitSequence.ok THEN Fail ELSE
    Ok([ loginResponseStatus |-> loginResponseStatus.value,
         loginResponseText   |-> loginResponseText.value,
         clientSequence      |-> clientSequence.value,
         unitSequence        |-> unitSequence.value ], unitSequence.rest)

ZeroLoginResponseMessage ==
    [ loginResponseStatus |-> [i \in 1 .. 1 |-> 0],
      loginResponseText   |-> [i \in 1 .. 60 |-> 0],
      clientSequence      |-> [i \in 1 .. 4 |-> 0],
      unitSequence        |-> << >> ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginResponseText = one] : one \in Sample(60) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.clientSequence = one] : one \in Sample(4) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.unitSequence = one] : one \in SampleLists(OneUnitSequence) }

(***************************************************************************)
(* Logout Response Message: 61 bytes                                       *)
(***************************************************************************)

LogoutResponseMessage ==
    [ logoutReason     : Sample(1),
      logoutReasonText : Sample(60) ]

EncodeLogoutResponseMessage(message) ==
    message.logoutReason
        \o message.logoutReasonText

DecodeLogoutResponseMessage(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutReasonText == ReadBytes(logoutReason.rest, 60) IN IF ~logoutReasonText.ok THEN Fail ELSE
    Ok([ logoutReason     |-> logoutReason.value,
         logoutReasonText |-> logoutReasonText.value ], logoutReasonText.rest)

ZeroLogoutResponseMessage ==
    [ logoutReason     |-> [i \in 1 .. 1 |-> 0],
      logoutReasonText |-> [i \in 1 .. 60 |-> 0] ]

(* Logout Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutResponseMessage ==
    { ZeroLogoutResponseMessage }
        \cup { [ZeroLogoutResponseMessage EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutResponseMessage EXCEPT !.logoutReasonText = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Acknowledgement Us Equities V 1: 82 bytes                         *)
(***************************************************************************)

OrderAcknowledgementUsEquitiesV1 ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      side                   : Sample(1),
      price                  : Sample(8),
      ordType                : Sample(1),
      symbol                 : Sample(8),
      clearingFirm           : Sample(4),
      leavesQty              : Sample(4),
      displayPrice           : Sample(8),
      workingPrice           : Sample(8),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1) ]

EncodeOrderAcknowledgementUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.side
        \o message.price
        \o message.ordType
        \o message.symbol
        \o message.clearingFirm
        \o message.leavesQty
        \o message.displayPrice
        \o message.workingPrice
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator

DecodeOrderAcknowledgementUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET symbol == ReadBytes(ordType.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(symbol.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(clearingFirm.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET displayPrice == ReadBytes(leavesQty.rest, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(displayPrice.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         side                   |-> side.value,
         price                  |-> price.value,
         ordType                |-> ordType.value,
         symbol                 |-> symbol.value,
         clearingFirm           |-> clearingFirm.value,
         leavesQty              |-> leavesQty.value,
         displayPrice           |-> displayPrice.value,
         workingPrice           |-> workingPrice.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value ], subLiquidityIndicator.rest)

ZeroOrderAcknowledgementUsEquitiesV1 ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      displayPrice           |-> [i \in 1 .. 8 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Order Acknowledgement Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgementUsEquitiesV1 ==
    { ZeroOrderAcknowledgementUsEquitiesV1 }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementUsEquitiesV1 EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Rejected Us Equities V 1: 95 bytes                                *)
(***************************************************************************)

OrderRejectedUsEquitiesV1 ==
    [ inFlight          : Sample(2),
      transactionTime   : Sample(8),
      clOrdId           : Sample(20),
      clearingFirm      : Sample(4),
      orderRejectReason : Sample(1),
      text              : Sample(60) ]

EncodeOrderRejectedUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.orderRejectReason
        \o message.text

DecodeOrderRejectedUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(clearingFirm.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight          |-> inFlight.value,
         transactionTime   |-> transactionTime.value,
         clOrdId           |-> clOrdId.value,
         clearingFirm      |-> clearingFirm.value,
         orderRejectReason |-> orderRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroOrderRejectedUsEquitiesV1 ==
    [ inFlight          |-> [i \in 1 .. 2 |-> 0],
      transactionTime   |-> [i \in 1 .. 8 |-> 0],
      clOrdId           |-> [i \in 1 .. 20 |-> 0],
      clearingFirm      |-> [i \in 1 .. 4 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Order Rejected Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedUsEquitiesV1 ==
    { ZeroOrderRejectedUsEquitiesV1 }
        \cup { [ZeroOrderRejectedUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderRejectedUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectedUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRejectedUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderRejectedUsEquitiesV1 EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRejectedUsEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Modified Us Equities V 1: 125 bytes                               *)
(***************************************************************************)

OrderModifiedUsEquitiesV1 ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      origClOrdId            : Sample(20),
      orderId                : Sample(8),
      clearingFirm           : Sample(4),
      symbol                 : Sample(8),
      side                   : Sample(1),
      price                  : Sample(8),
      ordType                : Sample(1),
      maxFloor               : Sample(4),
      orderQty               : Sample(4),
      stopPx                 : Sample(8),
      leavesQty              : Sample(4),
      displayPrice           : Sample(8),
      workingPrice           : Sample(8),
      baseLiquidityIndicator : Sample(1),
      secondaryOrderId       : Sample(8) ]

EncodeOrderModifiedUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.origClOrdId
        \o message.orderId
        \o message.clearingFirm
        \o message.symbol
        \o message.side
        \o message.price
        \o message.ordType
        \o message.maxFloor
        \o message.orderQty
        \o message.stopPx
        \o message.leavesQty
        \o message.displayPrice
        \o message.workingPrice
        \o message.baseLiquidityIndicator
        \o message.secondaryOrderId

DecodeOrderModifiedUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(origClOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET symbol == ReadBytes(clearingFirm.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET side == ReadBytes(symbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(ordType.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQty == ReadBytes(maxFloor.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET stopPx == ReadBytes(orderQty.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(stopPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET displayPrice == ReadBytes(leavesQty.rest, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(displayPrice.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(baseLiquidityIndicator.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         orderId                |-> orderId.value,
         clearingFirm           |-> clearingFirm.value,
         symbol                 |-> symbol.value,
         side                   |-> side.value,
         price                  |-> price.value,
         ordType                |-> ordType.value,
         maxFloor               |-> maxFloor.value,
         orderQty               |-> orderQty.value,
         stopPx                 |-> stopPx.value,
         leavesQty              |-> leavesQty.value,
         displayPrice           |-> displayPrice.value,
         workingPrice           |-> workingPrice.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         secondaryOrderId       |-> secondaryOrderId.value ], secondaryOrderId.rest)

ZeroOrderModifiedUsEquitiesV1 ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      origClOrdId            |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      maxFloor               |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      displayPrice           |-> [i \in 1 .. 8 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modified Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedUsEquitiesV1 ==
    { ZeroOrderModifiedUsEquitiesV1 }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedUsEquitiesV1 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Restated Us Equities V 1: 108 bytes                               *)
(***************************************************************************)

OrderRestatedUsEquitiesV1 ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      clearingFirm           : Sample(4),
      symbol                 : Sample(8),
      orderRestatementReason : Sample(1),
      orderQty               : Sample(4),
      price                  : Sample(8),
      leavesQty              : Sample(4),
      displayPrice           : Sample(8),
      workingPrice           : Sample(8),
      baseLiquidityIndicator : Sample(1),
      secondaryOrderId       : Sample(8),
      lastShares             : Sample(4),
      lastPx                 : Sample(8),
      cmcMatchQty            : Sample(4) ]

EncodeOrderRestatedUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.clearingFirm
        \o message.symbol
        \o message.orderRestatementReason
        \o message.orderQty
        \o message.price
        \o message.leavesQty
        \o message.displayPrice
        \o message.workingPrice
        \o message.baseLiquidityIndicator
        \o message.secondaryOrderId
        \o message.lastShares
        \o message.lastPx
        \o message.cmcMatchQty

DecodeOrderRestatedUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET symbol == ReadBytes(clearingFirm.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderRestatementReason == ReadBytes(symbol.rest, 1) IN IF ~orderRestatementReason.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderRestatementReason.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(price.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET displayPrice == ReadBytes(leavesQty.rest, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(displayPrice.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(baseLiquidityIndicator.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(secondaryOrderId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET cmcMatchQty == ReadBytes(lastPx.rest, 4) IN IF ~cmcMatchQty.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         clearingFirm           |-> clearingFirm.value,
         symbol                 |-> symbol.value,
         orderRestatementReason |-> orderRestatementReason.value,
         orderQty               |-> orderQty.value,
         price                  |-> price.value,
         leavesQty              |-> leavesQty.value,
         displayPrice           |-> displayPrice.value,
         workingPrice           |-> workingPrice.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         cmcMatchQty            |-> cmcMatchQty.value ], cmcMatchQty.rest)

ZeroOrderRestatedUsEquitiesV1 ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      orderRestatementReason |-> [i \in 1 .. 1 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      displayPrice           |-> [i \in 1 .. 8 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      cmcMatchQty            |-> [i \in 1 .. 4 |-> 0] ]

(* Order Restated Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedUsEquitiesV1 ==
    { ZeroOrderRestatedUsEquitiesV1 }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.orderRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedUsEquitiesV1 EXCEPT !.cmcMatchQty = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Rejected Us Equities V 1: 115 bytes                              *)
(***************************************************************************)

ModifyRejectedUsEquitiesV1 ==
    [ inFlight           : Sample(2),
      transactionTime    : Sample(8),
      clearingFirm       : Sample(4),
      clOrdId            : Sample(20),
      origClOrdId        : Sample(20),
      modifyRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeModifyRejectedUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clearingFirm
        \o message.clOrdId
        \o message.origClOrdId
        \o message.modifyRejectReason
        \o message.text

DecodeModifyRejectedUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clearingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(origClOrdId.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(modifyRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight           |-> inFlight.value,
         transactionTime    |-> transactionTime.value,
         clearingFirm       |-> clearingFirm.value,
         clOrdId            |-> clOrdId.value,
         origClOrdId        |-> origClOrdId.value,
         modifyRejectReason |-> modifyRejectReason.value,
         text               |-> text.value ], text.rest)

ZeroModifyRejectedUsEquitiesV1 ==
    [ inFlight           |-> [i \in 1 .. 2 |-> 0],
      transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      modifyRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Modify Rejected Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedModifyRejectedUsEquitiesV1 ==
    { ZeroModifyRejectedUsEquitiesV1 }
        \cup { [ZeroModifyRejectedUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroModifyRejectedUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyRejectedUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyRejectedUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedUsEquitiesV1 EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedUsEquitiesV1 EXCEPT !.modifyRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroModifyRejectedUsEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Cancelled Us Equities V 1: 35 bytes                               *)
(***************************************************************************)

OrderCancelledUsEquitiesV1 ==
    [ inFlight        : Sample(2),
      transactionTime : Sample(8),
      clearingFirm    : Sample(4),
      clOrdId         : Sample(20),
      cancelReason    : Sample(1) ]

EncodeOrderCancelledUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clearingFirm
        \o message.clOrdId
        \o message.cancelReason

DecodeOrderCancelledUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clearingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ inFlight        |-> inFlight.value,
         transactionTime |-> transactionTime.value,
         clearingFirm    |-> clearingFirm.value,
         clOrdId         |-> clOrdId.value,
         cancelReason    |-> cancelReason.value ], cancelReason.rest)

ZeroOrderCancelledUsEquitiesV1 ==
    [ inFlight        |-> [i \in 1 .. 2 |-> 0],
      transactionTime |-> [i \in 1 .. 8 |-> 0],
      clearingFirm    |-> [i \in 1 .. 4 |-> 0],
      clOrdId         |-> [i \in 1 .. 20 |-> 0],
      cancelReason    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancelled Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledUsEquitiesV1 ==
    { ZeroOrderCancelledUsEquitiesV1 }
        \cup { [ZeroOrderCancelledUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelledUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelledUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelledUsEquitiesV1 EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Rejected Us Equities V 1: 95 bytes                               *)
(***************************************************************************)

CancelRejectedUsEquitiesV1 ==
    [ inFlight           : Sample(2),
      transactionTime    : Sample(8),
      clearingFirm       : Sample(4),
      clOrdId            : Sample(20),
      cancelRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeCancelRejectedUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clearingFirm
        \o message.clOrdId
        \o message.cancelRejectReason
        \o message.text

DecodeCancelRejectedUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clearingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(cancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight           |-> inFlight.value,
         transactionTime    |-> transactionTime.value,
         clearingFirm       |-> clearingFirm.value,
         clOrdId            |-> clOrdId.value,
         cancelRejectReason |-> cancelRejectReason.value,
         text               |-> text.value ], text.rest)

ZeroCancelRejectedUsEquitiesV1 ==
    [ inFlight           |-> [i \in 1 .. 2 |-> 0],
      transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      cancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Cancel Rejected Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedUsEquitiesV1 ==
    { ZeroCancelRejectedUsEquitiesV1 }
        \cup { [ZeroCancelRejectedUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroCancelRejectedUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectedUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelRejectedUsEquitiesV1 EXCEPT !.cancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelRejectedUsEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Execution Us Equities V 1: 83 bytes                               *)
(***************************************************************************)

OrderExecutionUsEquitiesV1 ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      clearingFirm           : Sample(4),
      clOrdId                : Sample(20),
      execId                 : Sample(8),
      lastShares             : Sample(4),
      lastPx                 : Sample(8),
      leavesQty              : Sample(4),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      contraBroker           : Sample(4),
      side                   : Sample(1),
      symbol                 : Sample(8),
      feeCode                : Sample(2),
      accessFee              : Sample(8) ]

EncodeOrderExecutionUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clearingFirm
        \o message.clOrdId
        \o message.execId
        \o message.lastShares
        \o message.lastPx
        \o message.leavesQty
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.contraBroker
        \o message.side
        \o message.symbol
        \o message.feeCode
        \o message.accessFee

DecodeOrderExecutionUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(transactionTime.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clearingFirm.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(execId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(subLiquidityIndicator.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET side == ReadBytes(contraBroker.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET feeCode == ReadBytes(symbol.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET accessFee == ReadBytes(feeCode.rest, 8) IN IF ~accessFee.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         clearingFirm           |-> clearingFirm.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         leavesQty              |-> leavesQty.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         contraBroker           |-> contraBroker.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         feeCode                |-> feeCode.value,
         accessFee              |-> accessFee.value ], accessFee.rest)

ZeroOrderExecutionUsEquitiesV1 ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      contraBroker           |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0],
      accessFee              |-> [i \in 1 .. 8 |-> 0] ]

(* Order Execution Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionUsEquitiesV1 ==
    { ZeroOrderExecutionUsEquitiesV1 }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionUsEquitiesV1 EXCEPT !.accessFee = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Cancel Correct Us Equities V 1: 94 bytes                          *)
(***************************************************************************)

TradeCancelCorrectUsEquitiesV1 ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      execRefId              : Sample(8),
      side                   : Sample(1),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      clearingFirm           : Sample(4),
      clearingAccount        : Sample(4),
      lastShares             : Sample(4),
      lastPx                 : Sample(8),
      correctedPrice         : Sample(8),
      origTime               : Sample(8),
      symbol                 : Sample(8),
      capacity               : Sample(1) ]

EncodeTradeCancelCorrectUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.execRefId
        \o message.side
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.lastShares
        \o message.lastPx
        \o message.correctedPrice
        \o message.origTime
        \o message.symbol
        \o message.capacity

DecodeTradeCancelCorrectUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execRefId == ReadBytes(orderId.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET side == ReadBytes(execRefId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(side.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(subLiquidityIndicator.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET lastShares == ReadBytes(clearingAccount.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET correctedPrice == ReadBytes(lastPx.rest, 8) IN IF ~correctedPrice.ok THEN Fail ELSE
    LET origTime == ReadBytes(correctedPrice.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET symbol == ReadBytes(origTime.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET capacity == ReadBytes(symbol.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         execRefId              |-> execRefId.value,
         side                   |-> side.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         clearingFirm           |-> clearingFirm.value,
         clearingAccount        |-> clearingAccount.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         correctedPrice         |-> correctedPrice.value,
         origTime               |-> origTime.value,
         symbol                 |-> symbol.value,
         capacity               |-> capacity.value ], capacity.rest)

ZeroTradeCancelCorrectUsEquitiesV1 ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      execRefId              |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      clearingAccount        |-> [i \in 1 .. 4 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      correctedPrice         |-> [i \in 1 .. 8 |-> 0],
      origTime               |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      capacity               |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Cancel Correct Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelCorrectUsEquitiesV1 ==
    { ZeroTradeCancelCorrectUsEquitiesV1 }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.correctedPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectUsEquitiesV1 EXCEPT !.capacity = one] : one \in Sample(1) }

(***************************************************************************)
(* Purge Rejected Us Equities V 1: 91 bytes                                *)
(***************************************************************************)

PurgeRejectedUsEquitiesV1 ==
    [ inFlight          : Sample(2),
      transactionTime   : Sample(8),
      massCancelId      : Sample(20),
      purgeRejectReason : Sample(1),
      text              : Sample(60) ]

EncodePurgeRejectedUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.massCancelId
        \o message.purgeRejectReason
        \o message.text

DecodePurgeRejectedUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET purgeRejectReason == ReadBytes(massCancelId.rest, 1) IN IF ~purgeRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(purgeRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight          |-> inFlight.value,
         transactionTime   |-> transactionTime.value,
         massCancelId      |-> massCancelId.value,
         purgeRejectReason |-> purgeRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroPurgeRejectedUsEquitiesV1 ==
    [ inFlight          |-> [i \in 1 .. 2 |-> 0],
      transactionTime   |-> [i \in 1 .. 8 |-> 0],
      massCancelId      |-> [i \in 1 .. 20 |-> 0],
      purgeRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Purge Rejected Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRejectedUsEquitiesV1 ==
    { ZeroPurgeRejectedUsEquitiesV1 }
        \cup { [ZeroPurgeRejectedUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroPurgeRejectedUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeRejectedUsEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeRejectedUsEquitiesV1 EXCEPT !.purgeRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRejectedUsEquitiesV1 EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Reset Risk Acknowledgement Us Equities V 1: 19 bytes                    *)
(***************************************************************************)

ResetRiskAcknowledgementUsEquitiesV1 ==
    [ inFlight        : Sample(2),
      riskStatusId    : Sample(16),
      riskResetResult : Sample(1) ]

EncodeResetRiskAcknowledgementUsEquitiesV1(message) ==
    message.inFlight
        \o message.riskStatusId
        \o message.riskResetResult

DecodeResetRiskAcknowledgementUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET riskStatusId == ReadBytes(inFlight.rest, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskResetResult == ReadBytes(riskStatusId.rest, 1) IN IF ~riskResetResult.ok THEN Fail ELSE
    Ok([ inFlight        |-> inFlight.value,
         riskStatusId    |-> riskStatusId.value,
         riskResetResult |-> riskResetResult.value ], riskResetResult.rest)

ZeroResetRiskAcknowledgementUsEquitiesV1 ==
    [ inFlight        |-> [i \in 1 .. 2 |-> 0],
      riskStatusId    |-> [i \in 1 .. 16 |-> 0],
      riskResetResult |-> [i \in 1 .. 1 |-> 0] ]

(* Reset Risk Acknowledgement Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskAcknowledgementUsEquitiesV1 ==
    { ZeroResetRiskAcknowledgementUsEquitiesV1 }
        \cup { [ZeroResetRiskAcknowledgementUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroResetRiskAcknowledgementUsEquitiesV1 EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskAcknowledgementUsEquitiesV1 EXCEPT !.riskResetResult = one] : one \in Sample(1) }

(***************************************************************************)
(* Purge Acknowledgement Us Equities V 1: 34 bytes                         *)
(***************************************************************************)

PurgeAcknowledgementUsEquitiesV1 ==
    [ inFlight            : Sample(2),
      transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4) ]

EncodePurgeAcknowledgementUsEquitiesV1(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount

DecodePurgeAcknowledgementUsEquitiesV1(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    Ok([ inFlight            |-> inFlight.value,
         transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value ], cancelledOrderCount.rest)

ZeroPurgeAcknowledgementUsEquitiesV1 ==
    [ inFlight            |-> [i \in 1 .. 2 |-> 0],
      transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0] ]

(* Purge Acknowledgement Us Equities V 1 at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAcknowledgementUsEquitiesV1 ==
    { ZeroPurgeAcknowledgementUsEquitiesV1 }
        \cup { [ZeroPurgeAcknowledgementUsEquitiesV1 EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroPurgeAcknowledgementUsEquitiesV1 EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeAcknowledgementUsEquitiesV1 EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeAcknowledgementUsEquitiesV1 EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Exchange Message, selected by Exchange Message Type                     *)
(***************************************************************************)

LoginResponseMessageCode == 501  \* 0x1f5
ReplayCompleteCode == 502  \* 0x1f6
LogoutResponseMessageCode == 503  \* 0x1f7
ServerHeartbeatCode == 504  \* 0x1f8
OrderAcknowledgementUsEquitiesV1Code == 4501  \* 0x1195
OrderRejectedUsEquitiesV1Code == 4502  \* 0x1196
OrderModifiedUsEquitiesV1Code == 4503  \* 0x1197
OrderRestatedUsEquitiesV1Code == 4505  \* 0x1199
ModifyRejectedUsEquitiesV1Code == 4504  \* 0x1198
OrderCancelledUsEquitiesV1Code == 4506  \* 0x119a
CancelRejectedUsEquitiesV1Code == 4507  \* 0x119b
OrderExecutionUsEquitiesV1Code == 4508  \* 0x119c
TradeCancelCorrectUsEquitiesV1Code == 4509  \* 0x119d
PurgeRejectedUsEquitiesV1Code == 4512  \* 0x11a0
ResetRiskAcknowledgementUsEquitiesV1Code == 4510  \* 0x119e
PurgeAcknowledgementUsEquitiesV1Code == 4511  \* 0x119f

ExchangeMessage ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAcknowledgementUsEquitiesV1Code}, body : OrderAcknowledgementUsEquitiesV1 ]
        \cup [ tag : {OrderRejectedUsEquitiesV1Code}, body : OrderRejectedUsEquitiesV1 ]
        \cup [ tag : {OrderModifiedUsEquitiesV1Code}, body : OrderModifiedUsEquitiesV1 ]
        \cup [ tag : {OrderRestatedUsEquitiesV1Code}, body : OrderRestatedUsEquitiesV1 ]
        \cup [ tag : {ModifyRejectedUsEquitiesV1Code}, body : ModifyRejectedUsEquitiesV1 ]
        \cup [ tag : {OrderCancelledUsEquitiesV1Code}, body : OrderCancelledUsEquitiesV1 ]
        \cup [ tag : {CancelRejectedUsEquitiesV1Code}, body : CancelRejectedUsEquitiesV1 ]
        \cup [ tag : {OrderExecutionUsEquitiesV1Code}, body : OrderExecutionUsEquitiesV1 ]
        \cup [ tag : {TradeCancelCorrectUsEquitiesV1Code}, body : TradeCancelCorrectUsEquitiesV1 ]
        \cup [ tag : {PurgeRejectedUsEquitiesV1Code}, body : PurgeRejectedUsEquitiesV1 ]
        \cup [ tag : {ResetRiskAcknowledgementUsEquitiesV1Code}, body : ResetRiskAcknowledgementUsEquitiesV1 ]
        \cup [ tag : {PurgeAcknowledgementUsEquitiesV1Code}, body : PurgeAcknowledgementUsEquitiesV1 ]

EncodeExchangeMessage(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayCompleteCode -> << >>
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = OrderAcknowledgementUsEquitiesV1Code -> EncodeOrderAcknowledgementUsEquitiesV1(message.body)
      [] message.tag = OrderRejectedUsEquitiesV1Code -> EncodeOrderRejectedUsEquitiesV1(message.body)
      [] message.tag = OrderModifiedUsEquitiesV1Code -> EncodeOrderModifiedUsEquitiesV1(message.body)
      [] message.tag = OrderRestatedUsEquitiesV1Code -> EncodeOrderRestatedUsEquitiesV1(message.body)
      [] message.tag = ModifyRejectedUsEquitiesV1Code -> EncodeModifyRejectedUsEquitiesV1(message.body)
      [] message.tag = OrderCancelledUsEquitiesV1Code -> EncodeOrderCancelledUsEquitiesV1(message.body)
      [] message.tag = CancelRejectedUsEquitiesV1Code -> EncodeCancelRejectedUsEquitiesV1(message.body)
      [] message.tag = OrderExecutionUsEquitiesV1Code -> EncodeOrderExecutionUsEquitiesV1(message.body)
      [] message.tag = TradeCancelCorrectUsEquitiesV1Code -> EncodeTradeCancelCorrectUsEquitiesV1(message.body)
      [] message.tag = PurgeRejectedUsEquitiesV1Code -> EncodePurgeRejectedUsEquitiesV1(message.body)
      [] message.tag = ResetRiskAcknowledgementUsEquitiesV1Code -> EncodeResetRiskAcknowledgementUsEquitiesV1(message.body)
      [] message.tag = PurgeAcknowledgementUsEquitiesV1Code -> EncodePurgeAcknowledgementUsEquitiesV1(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAcknowledgementUsEquitiesV1Code -> DecodeOrderAcknowledgementUsEquitiesV1(bytes)
              [] tag = OrderRejectedUsEquitiesV1Code -> DecodeOrderRejectedUsEquitiesV1(bytes)
              [] tag = OrderModifiedUsEquitiesV1Code -> DecodeOrderModifiedUsEquitiesV1(bytes)
              [] tag = OrderRestatedUsEquitiesV1Code -> DecodeOrderRestatedUsEquitiesV1(bytes)
              [] tag = ModifyRejectedUsEquitiesV1Code -> DecodeModifyRejectedUsEquitiesV1(bytes)
              [] tag = OrderCancelledUsEquitiesV1Code -> DecodeOrderCancelledUsEquitiesV1(bytes)
              [] tag = CancelRejectedUsEquitiesV1Code -> DecodeCancelRejectedUsEquitiesV1(bytes)
              [] tag = OrderExecutionUsEquitiesV1Code -> DecodeOrderExecutionUsEquitiesV1(bytes)
              [] tag = TradeCancelCorrectUsEquitiesV1Code -> DecodeTradeCancelCorrectUsEquitiesV1(bytes)
              [] tag = PurgeRejectedUsEquitiesV1Code -> DecodePurgeRejectedUsEquitiesV1(bytes)
              [] tag = ResetRiskAcknowledgementUsEquitiesV1Code -> DecodeResetRiskAcknowledgementUsEquitiesV1(bytes)
              [] tag = PurgeAcknowledgementUsEquitiesV1Code -> DecodePurgeAcknowledgementUsEquitiesV1(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAcknowledgementUsEquitiesV1Code, body |-> one] : one \in CheckedOrderAcknowledgementUsEquitiesV1 }
        \cup { [tag |-> OrderRejectedUsEquitiesV1Code, body |-> one] : one \in CheckedOrderRejectedUsEquitiesV1 }
        \cup { [tag |-> OrderModifiedUsEquitiesV1Code, body |-> one] : one \in CheckedOrderModifiedUsEquitiesV1 }
        \cup { [tag |-> OrderRestatedUsEquitiesV1Code, body |-> one] : one \in CheckedOrderRestatedUsEquitiesV1 }
        \cup { [tag |-> ModifyRejectedUsEquitiesV1Code, body |-> one] : one \in CheckedModifyRejectedUsEquitiesV1 }
        \cup { [tag |-> OrderCancelledUsEquitiesV1Code, body |-> one] : one \in CheckedOrderCancelledUsEquitiesV1 }
        \cup { [tag |-> CancelRejectedUsEquitiesV1Code, body |-> one] : one \in CheckedCancelRejectedUsEquitiesV1 }
        \cup { [tag |-> OrderExecutionUsEquitiesV1Code, body |-> one] : one \in CheckedOrderExecutionUsEquitiesV1 }
        \cup { [tag |-> TradeCancelCorrectUsEquitiesV1Code, body |-> one] : one \in CheckedTradeCancelCorrectUsEquitiesV1 }
        \cup { [tag |-> PurgeRejectedUsEquitiesV1Code, body |-> one] : one \in CheckedPurgeRejectedUsEquitiesV1 }
        \cup { [tag |-> ResetRiskAcknowledgementUsEquitiesV1Code, body |-> one] : one \in CheckedResetRiskAcknowledgementUsEquitiesV1 }
        \cup { [tag |-> PurgeAcknowledgementUsEquitiesV1Code, body |-> one] : one \in CheckedPurgeAcknowledgementUsEquitiesV1 }

(***************************************************************************)
(* Exchange Packet                                                         *)
(***************************************************************************)

ExchangePacket ==
    [ startOfMessage  : Sample(2),
      messageLength   : Sample(2),
      matchingUnit    : Sample(1),
      reservedField   : Sample(1),
      sequenceNumber  : Sample(4),
      exchangeMessage : ExchangeMessage ]

EncodeExchangePacket(message) ==
    message.startOfMessage
        \o message.messageLength
        \o EncodeUIntLE(message.exchangeMessage.tag, 2)
        \o message.matchingUnit
        \o message.reservedField
        \o message.sequenceNumber
        \o EncodeExchangeMessage(message.exchangeMessage)

DecodeExchangePacket(bytes) ==
    LET startOfMessage == ReadBytes(bytes, 2) IN IF ~startOfMessage.ok THEN Fail ELSE
    LET messageLength == ReadBytes(startOfMessage.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET exchangeMessageType == ReadUIntLE(messageLength.rest, 2) IN IF ~exchangeMessageType.ok THEN Fail ELSE
    LET matchingUnit == ReadBytes(exchangeMessageType.rest, 1) IN IF ~matchingUnit.ok THEN Fail ELSE
    LET reservedField == ReadBytes(matchingUnit.rest, 1) IN IF ~reservedField.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(reservedField.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET exchangeMessage == DecodeExchangeMessage(exchangeMessageType.value, sequenceNumber.rest) IN IF ~exchangeMessage.ok THEN Fail ELSE
    Ok([ startOfMessage  |-> startOfMessage.value,
         messageLength   |-> messageLength.value,
         matchingUnit    |-> matchingUnit.value,
         reservedField   |-> reservedField.value,
         sequenceNumber  |-> sequenceNumber.value,
         exchangeMessage |-> exchangeMessage.value ], exchangeMessage.rest)

ZeroExchangePacket ==
    [ startOfMessage  |-> [i \in 1 .. 2 |-> 0],
      messageLength   |-> [i \in 1 .. 2 |-> 0],
      matchingUnit    |-> [i \in 1 .. 1 |-> 0],
      reservedField   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      exchangeMessage |-> ZeroExchangeMessage ]

(* Exchange Packet at zero, then each field in turn at the values it is checked at *)
CheckedExchangePacket ==
    { ZeroExchangePacket }
        \cup { [ZeroExchangePacket EXCEPT !.startOfMessage = one] : one \in Sample(2) }
        \cup { [ZeroExchangePacket EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroExchangePacket EXCEPT !.matchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroExchangePacket EXCEPT !.reservedField = one] : one \in Sample(1) }
        \cup { [ZeroExchangePacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroExchangePacket EXCEPT !.exchangeMessage = one] : one \in CheckedExchangeMessage }

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

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutResponseMessage ==
    \A message \in CheckedLogoutResponseMessage :
        LET read == DecodeLogoutResponseMessage(EncodeLogoutResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Acknowledgement Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgementUsEquitiesV1 ==
    \A message \in CheckedOrderAcknowledgementUsEquitiesV1 :
        LET read == DecodeOrderAcknowledgementUsEquitiesV1(EncodeOrderAcknowledgementUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedUsEquitiesV1 ==
    \A message \in CheckedOrderRejectedUsEquitiesV1 :
        LET read == DecodeOrderRejectedUsEquitiesV1(EncodeOrderRejectedUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedUsEquitiesV1 ==
    \A message \in CheckedOrderModifiedUsEquitiesV1 :
        LET read == DecodeOrderModifiedUsEquitiesV1(EncodeOrderModifiedUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedUsEquitiesV1 ==
    \A message \in CheckedOrderRestatedUsEquitiesV1 :
        LET read == DecodeOrderRestatedUsEquitiesV1(EncodeOrderRestatedUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Rejected Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyRejectedUsEquitiesV1 ==
    \A message \in CheckedModifyRejectedUsEquitiesV1 :
        LET read == DecodeModifyRejectedUsEquitiesV1(EncodeModifyRejectedUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelledUsEquitiesV1 ==
    \A message \in CheckedOrderCancelledUsEquitiesV1 :
        LET read == DecodeOrderCancelledUsEquitiesV1(EncodeOrderCancelledUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedUsEquitiesV1 ==
    \A message \in CheckedCancelRejectedUsEquitiesV1 :
        LET read == DecodeCancelRejectedUsEquitiesV1(EncodeCancelRejectedUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionUsEquitiesV1 ==
    \A message \in CheckedOrderExecutionUsEquitiesV1 :
        LET read == DecodeOrderExecutionUsEquitiesV1(EncodeOrderExecutionUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Correct Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelCorrectUsEquitiesV1 ==
    \A message \in CheckedTradeCancelCorrectUsEquitiesV1 :
        LET read == DecodeTradeCancelCorrectUsEquitiesV1(EncodeTradeCancelCorrectUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Rejected Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRejectedUsEquitiesV1 ==
    \A message \in CheckedPurgeRejectedUsEquitiesV1 :
        LET read == DecodePurgeRejectedUsEquitiesV1(EncodePurgeRejectedUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Acknowledgement Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskAcknowledgementUsEquitiesV1 ==
    \A message \in CheckedResetRiskAcknowledgementUsEquitiesV1 :
        LET read == DecodeResetRiskAcknowledgementUsEquitiesV1(EncodeResetRiskAcknowledgementUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Acknowledgement Us Equities V 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAcknowledgementUsEquitiesV1 ==
    \A message \in CheckedPurgeAcknowledgementUsEquitiesV1 :
        LET read == DecodePurgeAcknowledgementUsEquitiesV1(EncodePurgeAcknowledgementUsEquitiesV1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exchange Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripExchangePacket ==
    \A message \in CheckedExchangePacket :
        LET read == DecodeExchangePacket(EncodeExchangePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Exchange Message is selected by the Exchange Message Type it is written under *)
SelectsExchangeMessage ==
    \A message \in CheckedExchangeMessage :
        LET read == DecodeExchangeMessage(message.tag, EncodeExchangeMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
