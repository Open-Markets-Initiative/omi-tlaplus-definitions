----------- MODULE EdgxOptions_BinaryOrderEntry_v1_0_10_Exchange -----------
(***************************************************************************)
(* Chicago Board Options Exchange Binary Order Entry v1.0.10               *)
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
(* Order Acknowledgement Message: 93 bytes                                 *)
(***************************************************************************)

OrderAcknowledgementMessage ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      side                   : Sample(1),
      price                  : Sample(8),
      symbol                 : Sample(8),
      clearingFirm           : Sample(4),
      leavesQty              : Sample(4),
      displayPrice           : Sample(8),
      workingPrice           : Sample(8),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      routingFirmId          : Sample(4),
      requestReceivedTime    : Sample(8) ]

EncodeOrderAcknowledgementMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.side
        \o message.price
        \o message.symbol
        \o message.clearingFirm
        \o message.leavesQty
        \o message.displayPrice
        \o message.workingPrice
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.routingFirmId
        \o message.requestReceivedTime

DecodeOrderAcknowledgementMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET symbol == ReadBytes(price.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(symbol.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(clearingFirm.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET displayPrice == ReadBytes(leavesQty.rest, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(displayPrice.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(subLiquidityIndicator.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(routingFirmId.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         side                   |-> side.value,
         price                  |-> price.value,
         symbol                 |-> symbol.value,
         clearingFirm           |-> clearingFirm.value,
         leavesQty              |-> leavesQty.value,
         displayPrice           |-> displayPrice.value,
         workingPrice           |-> workingPrice.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         routingFirmId          |-> routingFirmId.value,
         requestReceivedTime    |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroOrderAcknowledgementMessage ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      displayPrice           |-> [i \in 1 .. 8 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      routingFirmId          |-> [i \in 1 .. 4 |-> 0],
      requestReceivedTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Order Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcknowledgementMessage ==
    { ZeroOrderAcknowledgementMessage }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Acknowledgement Allocation: 37 bytes                                    *)
(***************************************************************************)

AcknowledgementAllocation ==
    [ clOrdId      : Sample(20),
      orderId      : Sample(8),
      side         : Sample(1),
      allocQty     : Sample(4),
      giveUpFirmId : Sample(4) ]

EncodeAcknowledgementAllocation(message) ==
    message.clOrdId
        \o message.orderId
        \o message.side
        \o message.allocQty
        \o message.giveUpFirmId

DecodeAcknowledgementAllocation(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET allocQty == ReadBytes(side.rest, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET giveUpFirmId == ReadBytes(allocQty.rest, 4) IN IF ~giveUpFirmId.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         orderId      |-> orderId.value,
         side         |-> side.value,
         allocQty     |-> allocQty.value,
         giveUpFirmId |-> giveUpFirmId.value ], giveUpFirmId.rest)

ZeroAcknowledgementAllocation ==
    [ clOrdId      |-> [i \in 1 .. 20 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      allocQty     |-> [i \in 1 .. 4 |-> 0],
      giveUpFirmId |-> [i \in 1 .. 4 |-> 0] ]

(* Acknowledgement Allocation at zero, then each field in turn at the values it is checked at *)
CheckedAcknowledgementAllocation ==
    { ZeroAcknowledgementAllocation }
        \cup { [ZeroAcknowledgementAllocation EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroAcknowledgementAllocation EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAcknowledgementAllocation EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAcknowledgementAllocation EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroAcknowledgementAllocation EXCEPT !.giveUpFirmId = one] : one \in Sample(4) }

(* A run of Acknowledgement Allocation, written one after another *)
RECURSIVE EncodeAcknowledgementAllocationList(_)
EncodeAcknowledgementAllocationList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAcknowledgementAllocation(Head(messages)) \o EncodeAcknowledgementAllocationList(Tail(messages))

(* As many Acknowledgement Allocation as the field that counts them says *)
RECURSIVE ReadAcknowledgementAllocationList(_, _)
ReadAcknowledgementAllocationList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAcknowledgementAllocation(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAcknowledgementAllocationList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Acknowledgement Allocation of each kind, for the lists that carry them *)
OneAcknowledgementAllocation == { ZeroAcknowledgementAllocation }

(***************************************************************************)
(* Cross Order Acknowledgment Message                                      *)
(***************************************************************************)

CrossOrderAcknowledgmentMessage ==
    [ inFlight                  : Sample(2),
      transactionTime           : Sample(8),
      crossId                   : Sample(20),
      auctionId                 : Sample(8),
      price                     : Sample(8),
      symbol                    : Sample(8),
      orderQty                  : Sample(4),
      routingFirmId             : Sample(4),
      requestReceivedTime       : Sample(8),
      acknowledgementAllocation : SampleLists(OneAcknowledgementAllocation) ]

EncodeCrossOrderAcknowledgmentMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.crossId
        \o message.auctionId
        \o message.price
        \o message.symbol
        \o message.orderQty
        \o message.routingFirmId
        \o message.requestReceivedTime
        \o EncodeUIntLE(Len(message.acknowledgementAllocation), 1)
        \o EncodeAcknowledgementAllocationList(message.acknowledgementAllocation)

DecodeCrossOrderAcknowledgmentMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET crossId == ReadBytes(transactionTime.rest, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(crossId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET price == ReadBytes(auctionId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET symbol == ReadBytes(price.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderQty == ReadBytes(symbol.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(orderQty.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(routingFirmId.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    LET allocCnt == ReadUIntLE(requestReceivedTime.rest, 1) IN IF ~allocCnt.ok THEN Fail ELSE
    LET acknowledgementAllocation == ReadAcknowledgementAllocationList(allocCnt.rest, allocCnt.value) IN IF ~acknowledgementAllocation.ok THEN Fail ELSE
    Ok([ inFlight                  |-> inFlight.value,
         transactionTime           |-> transactionTime.value,
         crossId                   |-> crossId.value,
         auctionId                 |-> auctionId.value,
         price                     |-> price.value,
         symbol                    |-> symbol.value,
         orderQty                  |-> orderQty.value,
         routingFirmId             |-> routingFirmId.value,
         requestReceivedTime       |-> requestReceivedTime.value,
         acknowledgementAllocation |-> acknowledgementAllocation.value ], acknowledgementAllocation.rest)

ZeroCrossOrderAcknowledgmentMessage ==
    [ inFlight                  |-> [i \in 1 .. 2 |-> 0],
      transactionTime           |-> [i \in 1 .. 8 |-> 0],
      crossId                   |-> [i \in 1 .. 20 |-> 0],
      auctionId                 |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      symbol                    |-> [i \in 1 .. 8 |-> 0],
      orderQty                  |-> [i \in 1 .. 4 |-> 0],
      routingFirmId             |-> [i \in 1 .. 4 |-> 0],
      requestReceivedTime       |-> [i \in 1 .. 8 |-> 0],
      acknowledgementAllocation |-> << >> ]

(* Cross Order Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossOrderAcknowledgmentMessage ==
    { ZeroCrossOrderAcknowledgmentMessage }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcknowledgmentMessage EXCEPT !.acknowledgementAllocation = one] : one \in SampleLists(OneAcknowledgementAllocation) }

(***************************************************************************)
(* Quote Acknowledgement: 11 bytes                                         *)
(***************************************************************************)

QuoteAcknowledgement ==
    [ orderId               : Sample(8),
      quoteResult           : Sample(1),
      subLiquidityIndicator : Sample(1),
      quoteRejectSubReason  : Sample(1) ]

EncodeQuoteAcknowledgement(message) ==
    message.orderId
        \o message.quoteResult
        \o message.subLiquidityIndicator
        \o message.quoteRejectSubReason

DecodeQuoteAcknowledgement(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quoteResult == ReadBytes(orderId.rest, 1) IN IF ~quoteResult.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(quoteResult.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET quoteRejectSubReason == ReadBytes(subLiquidityIndicator.rest, 1) IN IF ~quoteRejectSubReason.ok THEN Fail ELSE
    Ok([ orderId               |-> orderId.value,
         quoteResult           |-> quoteResult.value,
         subLiquidityIndicator |-> subLiquidityIndicator.value,
         quoteRejectSubReason  |-> quoteRejectSubReason.value ], quoteRejectSubReason.rest)

ZeroQuoteAcknowledgement ==
    [ orderId               |-> [i \in 1 .. 8 |-> 0],
      quoteResult           |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      quoteRejectSubReason  |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAcknowledgement ==
    { ZeroQuoteAcknowledgement }
        \cup { [ZeroQuoteAcknowledgement EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAcknowledgement EXCEPT !.quoteResult = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAcknowledgement EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAcknowledgement EXCEPT !.quoteRejectSubReason = one] : one \in Sample(1) }

(* A run of Quote Acknowledgement, written one after another *)
RECURSIVE EncodeQuoteAcknowledgementList(_)
EncodeQuoteAcknowledgementList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteAcknowledgement(Head(messages)) \o EncodeQuoteAcknowledgementList(Tail(messages))

(* As many Quote Acknowledgement as the field that counts them says *)
RECURSIVE ReadQuoteAcknowledgementList(_, _)
ReadQuoteAcknowledgementList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteAcknowledgement(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteAcknowledgementList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Acknowledgement of each kind, for the lists that carry them *)
OneQuoteAcknowledgement == { ZeroQuoteAcknowledgement }

(***************************************************************************)
(* Quote Update Acknowledgement Message                                    *)
(***************************************************************************)

QuoteUpdateAcknowledgementMessage ==
    [ inFlight             : Sample(2),
      transactionTime      : Sample(8),
      quoteUpdateId        : Sample(16),
      requestReceivedTime  : Sample(8),
      quoteAcknowledgement : SampleLists(OneQuoteAcknowledgement) ]

EncodeQuoteUpdateAcknowledgementMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.quoteUpdateId
        \o message.requestReceivedTime
        \o EncodeUIntLE(Len(message.quoteAcknowledgement), 1)
        \o EncodeQuoteAcknowledgementList(message.quoteAcknowledgement)

DecodeQuoteUpdateAcknowledgementMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(quoteUpdateId.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    LET quoteCnt == ReadUIntLE(requestReceivedTime.rest, 1) IN IF ~quoteCnt.ok THEN Fail ELSE
    LET quoteAcknowledgement == ReadQuoteAcknowledgementList(quoteCnt.rest, quoteCnt.value) IN IF ~quoteAcknowledgement.ok THEN Fail ELSE
    Ok([ inFlight             |-> inFlight.value,
         transactionTime      |-> transactionTime.value,
         quoteUpdateId        |-> quoteUpdateId.value,
         requestReceivedTime  |-> requestReceivedTime.value,
         quoteAcknowledgement |-> quoteAcknowledgement.value ], quoteAcknowledgement.rest)

ZeroQuoteUpdateAcknowledgementMessage ==
    [ inFlight             |-> [i \in 1 .. 2 |-> 0],
      transactionTime      |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId        |-> [i \in 1 .. 16 |-> 0],
      requestReceivedTime  |-> [i \in 1 .. 8 |-> 0],
      quoteAcknowledgement |-> << >> ]

(* Quote Update Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateAcknowledgementMessage ==
    { ZeroQuoteUpdateAcknowledgementMessage }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateAcknowledgementMessage EXCEPT !.quoteAcknowledgement = one] : one \in SampleLists(OneQuoteAcknowledgement) }

(***************************************************************************)
(* Order Rejected Message: 99 bytes                                        *)
(***************************************************************************)

OrderRejectedMessage ==
    [ inFlight          : Sample(2),
      transactionTime   : Sample(8),
      clOrdId           : Sample(20),
      clearingFirm      : Sample(4),
      routingFirmId     : Sample(4),
      orderRejectReason : Sample(1),
      text              : Sample(60) ]

EncodeOrderRejectedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.orderRejectReason
        \o message.text

DecodeOrderRejectedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(routingFirmId.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight          |-> inFlight.value,
         transactionTime   |-> transactionTime.value,
         clOrdId           |-> clOrdId.value,
         clearingFirm      |-> clearingFirm.value,
         routingFirmId     |-> routingFirmId.value,
         orderRejectReason |-> orderRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroOrderRejectedMessage ==
    [ inFlight          |-> [i \in 1 .. 2 |-> 0],
      transactionTime   |-> [i \in 1 .. 8 |-> 0],
      clOrdId           |-> [i \in 1 .. 20 |-> 0],
      clearingFirm      |-> [i \in 1 .. 4 |-> 0],
      routingFirmId     |-> [i \in 1 .. 4 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedMessage ==
    { ZeroOrderRejectedMessage }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Cross Order Rejected Message: 95 bytes                                  *)
(***************************************************************************)

CrossOrderRejectedMessage ==
    [ inFlight          : Sample(2),
      transactionTime   : Sample(8),
      crossId           : Sample(20),
      routingFirmId     : Sample(4),
      orderRejectReason : Sample(1),
      text              : Sample(60) ]

EncodeCrossOrderRejectedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.crossId
        \o message.routingFirmId
        \o message.orderRejectReason
        \o message.text

DecodeCrossOrderRejectedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET crossId == ReadBytes(transactionTime.rest, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(crossId.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(routingFirmId.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight          |-> inFlight.value,
         transactionTime   |-> transactionTime.value,
         crossId           |-> crossId.value,
         routingFirmId     |-> routingFirmId.value,
         orderRejectReason |-> orderRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroCrossOrderRejectedMessage ==
    [ inFlight          |-> [i \in 1 .. 2 |-> 0],
      transactionTime   |-> [i \in 1 .. 8 |-> 0],
      crossId           |-> [i \in 1 .. 20 |-> 0],
      routingFirmId     |-> [i \in 1 .. 4 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Cross Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossOrderRejectedMessage ==
    { ZeroCrossOrderRejectedMessage }
        \cup { [ZeroCrossOrderRejectedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroCrossOrderRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderRejectedMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroCrossOrderRejectedMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderRejectedMessage EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Quote Update Rejected Message: 27 bytes                                 *)
(***************************************************************************)

QuoteUpdateRejectedMessage ==
    [ inFlight          : Sample(2),
      transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      quoteRejectReason : Sample(1) ]

EncodeQuoteUpdateRejectedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.quoteUpdateId
        \o message.quoteRejectReason

DecodeQuoteUpdateRejectedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteUpdateId.rest, 1) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    Ok([ inFlight          |-> inFlight.value,
         transactionTime   |-> transactionTime.value,
         quoteUpdateId     |-> quoteUpdateId.value,
         quoteRejectReason |-> quoteRejectReason.value ], quoteRejectReason.rest)

ZeroQuoteUpdateRejectedMessage ==
    [ inFlight          |-> [i \in 1 .. 2 |-> 0],
      transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      quoteRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Update Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateRejectedMessage ==
    { ZeroQuoteUpdateRejectedMessage }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteUpdateRejectedMessage EXCEPT !.quoteRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Modified Message: 136 bytes                                       *)
(***************************************************************************)

OrderModifiedMessage ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      origClOrdId            : Sample(20),
      orderId                : Sample(8),
      clearingFirm           : Sample(4),
      routingFirmId          : Sample(4),
      symbol                 : Sample(8),
      orderQty               : Sample(4),
      price                  : Sample(8),
      ordType                : Sample(1),
      maxFloor               : Sample(4),
      stopPx                 : Sample(8),
      leavesQty              : Sample(4),
      displayPrice           : Sample(8),
      workingPrice           : Sample(8),
      baseLiquidityIndicator : Sample(1),
      secondaryOrderId       : Sample(8),
      requestReceivedTime    : Sample(8) ]

EncodeOrderModifiedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.origClOrdId
        \o message.orderId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.symbol
        \o message.orderQty
        \o message.price
        \o message.ordType
        \o message.maxFloor
        \o message.stopPx
        \o message.leavesQty
        \o message.displayPrice
        \o message.workingPrice
        \o message.baseLiquidityIndicator
        \o message.secondaryOrderId
        \o message.requestReceivedTime

DecodeOrderModifiedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(origClOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET symbol == ReadBytes(routingFirmId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderQty == ReadBytes(symbol.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET ordType == ReadBytes(price.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(ordType.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET stopPx == ReadBytes(maxFloor.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(stopPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET displayPrice == ReadBytes(leavesQty.rest, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(displayPrice.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(baseLiquidityIndicator.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(secondaryOrderId.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         orderId                |-> orderId.value,
         clearingFirm           |-> clearingFirm.value,
         routingFirmId          |-> routingFirmId.value,
         symbol                 |-> symbol.value,
         orderQty               |-> orderQty.value,
         price                  |-> price.value,
         ordType                |-> ordType.value,
         maxFloor               |-> maxFloor.value,
         stopPx                 |-> stopPx.value,
         leavesQty              |-> leavesQty.value,
         displayPrice           |-> displayPrice.value,
         workingPrice           |-> workingPrice.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         requestReceivedTime    |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroOrderModifiedMessage ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      origClOrdId            |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      routingFirmId          |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      maxFloor               |-> [i \in 1 .. 4 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      displayPrice           |-> [i \in 1 .. 8 |-> 0],
      workingPrice           |-> [i \in 1 .. 8 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 8 |-> 0],
      requestReceivedTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Restated Message: 108 bytes                                       *)
(***************************************************************************)

OrderRestatedMessage ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      clOrdId                : Sample(20),
      orderId                : Sample(8),
      clearingFirm           : Sample(4),
      routingFirmId          : Sample(4),
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
      lastPx                 : Sample(8) ]

EncodeOrderRestatedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.clearingFirm
        \o message.routingFirmId
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

DecodeOrderRestatedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(orderId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET symbol == ReadBytes(routingFirmId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
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
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         clOrdId                |-> clOrdId.value,
         orderId                |-> orderId.value,
         clearingFirm           |-> clearingFirm.value,
         routingFirmId          |-> routingFirmId.value,
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
         lastPx                 |-> lastPx.value ], lastPx.rest)

ZeroOrderRestatedMessage ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 20 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      routingFirmId          |-> [i \in 1 .. 4 |-> 0],
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
      lastPx                 |-> [i \in 1 .. 8 |-> 0] ]

(* Order Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedMessage ==
    { ZeroOrderRestatedMessage }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.orderRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.lastPx = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Restated Message: 54 bytes                                        *)
(***************************************************************************)

QuoteRestatedMessage ==
    [ inFlight          : Sample(2),
      transactionTime   : Sample(8),
      quoteUpdateId     : Sample(16),
      orderId           : Sample(8),
      leavesQty         : Sample(4),
      workingPrice      : Sample(8),
      quoteSymbol       : Sample(6),
      side              : Sample(1),
      restatementReason : Sample(1) ]

EncodeQuoteRestatedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.leavesQty
        \o message.workingPrice
        \o message.quoteSymbol
        \o message.side
        \o message.restatementReason

DecodeQuoteRestatedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(leavesQty.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET quoteSymbol == ReadBytes(workingPrice.rest, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(side.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    Ok([ inFlight          |-> inFlight.value,
         transactionTime   |-> transactionTime.value,
         quoteUpdateId     |-> quoteUpdateId.value,
         orderId           |-> orderId.value,
         leavesQty         |-> leavesQty.value,
         workingPrice      |-> workingPrice.value,
         quoteSymbol       |-> quoteSymbol.value,
         side              |-> side.value,
         restatementReason |-> restatementReason.value ], restatementReason.rest)

ZeroQuoteRestatedMessage ==
    [ inFlight          |-> [i \in 1 .. 2 |-> 0],
      transactionTime   |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId     |-> [i \in 1 .. 16 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      leavesQty         |-> [i \in 1 .. 4 |-> 0],
      workingPrice      |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol       |-> [i \in 1 .. 6 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      restatementReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRestatedMessage ==
    { ZeroQuoteRestatedMessage }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRestatedMessage EXCEPT !.restatementReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Rejected Message: 119 bytes                                      *)
(***************************************************************************)

ModifyRejectedMessage ==
    [ inFlight           : Sample(2),
      transactionTime    : Sample(8),
      clOrdId            : Sample(20),
      clearingFirm       : Sample(4),
      routingFirmId      : Sample(4),
      origClOrdId        : Sample(20),
      modifyRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeModifyRejectedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.origClOrdId
        \o message.modifyRejectReason
        \o message.text

DecodeModifyRejectedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(routingFirmId.rest, 20) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET modifyRejectReason == ReadBytes(origClOrdId.rest, 1) IN IF ~modifyRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(modifyRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight           |-> inFlight.value,
         transactionTime    |-> transactionTime.value,
         clOrdId            |-> clOrdId.value,
         clearingFirm       |-> clearingFirm.value,
         routingFirmId      |-> routingFirmId.value,
         origClOrdId        |-> origClOrdId.value,
         modifyRejectReason |-> modifyRejectReason.value,
         text               |-> text.value ], text.rest)

ZeroModifyRejectedMessage ==
    [ inFlight           |-> [i \in 1 .. 2 |-> 0],
      transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      routingFirmId      |-> [i \in 1 .. 4 |-> 0],
      origClOrdId        |-> [i \in 1 .. 20 |-> 0],
      modifyRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Modify Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyRejectedMessage ==
    { ZeroModifyRejectedMessage }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.origClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.modifyRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroModifyRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Cancelled Message: 56 bytes                                       *)
(***************************************************************************)

OrderCancelledMessage ==
    [ inFlight            : Sample(2),
      transactionTime     : Sample(8),
      clOrdId             : Sample(20),
      cancelReason        : Sample(1),
      cancelSubReason     : Sample(1),
      clearingFirm        : Sample(4),
      routingFirmId       : Sample(4),
      symbol              : Sample(8),
      requestReceivedTime : Sample(8) ]

EncodeOrderCancelledMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.cancelReason
        \o message.cancelSubReason
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.symbol
        \o message.requestReceivedTime

DecodeOrderCancelledMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET cancelSubReason == ReadBytes(cancelReason.rest, 1) IN IF ~cancelSubReason.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(cancelSubReason.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET symbol == ReadBytes(routingFirmId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(symbol.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ inFlight            |-> inFlight.value,
         transactionTime     |-> transactionTime.value,
         clOrdId             |-> clOrdId.value,
         cancelReason        |-> cancelReason.value,
         cancelSubReason     |-> cancelSubReason.value,
         clearingFirm        |-> clearingFirm.value,
         routingFirmId       |-> routingFirmId.value,
         symbol              |-> symbol.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroOrderCancelledMessage ==
    [ inFlight            |-> [i \in 1 .. 2 |-> 0],
      transactionTime     |-> [i \in 1 .. 8 |-> 0],
      clOrdId             |-> [i \in 1 .. 20 |-> 0],
      cancelReason        |-> [i \in 1 .. 1 |-> 0],
      cancelSubReason     |-> [i \in 1 .. 1 |-> 0],
      clearingFirm        |-> [i \in 1 .. 4 |-> 0],
      routingFirmId       |-> [i \in 1 .. 4 |-> 0],
      symbol              |-> [i \in 1 .. 8 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledMessage ==
    { ZeroOrderCancelledMessage }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.cancelSubReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Cancelled Message: 43 bytes                                       *)
(***************************************************************************)

QuoteCancelledMessage ==
    [ inFlight        : Sample(2),
      transactionTime : Sample(8),
      quoteUpdateId   : Sample(16),
      orderId         : Sample(8),
      quoteSymbol     : Sample(6),
      side            : Sample(1),
      cancelReason    : Sample(1),
      cancelSubReason : Sample(1) ]

EncodeQuoteCancelledMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.quoteSymbol
        \o message.side
        \o message.cancelReason
        \o message.cancelSubReason

DecodeQuoteCancelledMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quoteSymbol == ReadBytes(orderId.rest, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(quoteSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(side.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET cancelSubReason == ReadBytes(cancelReason.rest, 1) IN IF ~cancelSubReason.ok THEN Fail ELSE
    Ok([ inFlight        |-> inFlight.value,
         transactionTime |-> transactionTime.value,
         quoteUpdateId   |-> quoteUpdateId.value,
         orderId         |-> orderId.value,
         quoteSymbol     |-> quoteSymbol.value,
         side            |-> side.value,
         cancelReason    |-> cancelReason.value,
         cancelSubReason |-> cancelSubReason.value ], cancelSubReason.rest)

ZeroQuoteCancelledMessage ==
    [ inFlight        |-> [i \in 1 .. 2 |-> 0],
      transactionTime |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId   |-> [i \in 1 .. 16 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol     |-> [i \in 1 .. 6 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      cancelReason    |-> [i \in 1 .. 1 |-> 0],
      cancelSubReason |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelledMessage ==
    { ZeroQuoteCancelledMessage }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelledMessage EXCEPT !.cancelSubReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Allocation Cancelled: 24 bytes                                          *)
(***************************************************************************)

AllocationCancelled ==
    [ clOrdId      : Sample(20),
      giveUpFirmId : Sample(4) ]

EncodeAllocationCancelled(message) ==
    message.clOrdId
        \o message.giveUpFirmId

DecodeAllocationCancelled(bytes) ==
    LET clOrdId == ReadBytes(bytes, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET giveUpFirmId == ReadBytes(clOrdId.rest, 4) IN IF ~giveUpFirmId.ok THEN Fail ELSE
    Ok([ clOrdId      |-> clOrdId.value,
         giveUpFirmId |-> giveUpFirmId.value ], giveUpFirmId.rest)

ZeroAllocationCancelled ==
    [ clOrdId      |-> [i \in 1 .. 20 |-> 0],
      giveUpFirmId |-> [i \in 1 .. 4 |-> 0] ]

(* Allocation Cancelled at zero, then each field in turn at the values it is checked at *)
CheckedAllocationCancelled ==
    { ZeroAllocationCancelled }
        \cup { [ZeroAllocationCancelled EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroAllocationCancelled EXCEPT !.giveUpFirmId = one] : one \in Sample(4) }

(* A run of Allocation Cancelled, written one after another *)
RECURSIVE EncodeAllocationCancelledList(_)
EncodeAllocationCancelledList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAllocationCancelled(Head(messages)) \o EncodeAllocationCancelledList(Tail(messages))

(* As many Allocation Cancelled as the field that counts them says *)
RECURSIVE ReadAllocationCancelledList(_, _)
ReadAllocationCancelledList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAllocationCancelled(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAllocationCancelledList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Allocation Cancelled of each kind, for the lists that carry them *)
OneAllocationCancelled == { ZeroAllocationCancelled }

(***************************************************************************)
(* Cross Order Cancelled Message                                           *)
(***************************************************************************)

CrossOrderCancelledMessage ==
    [ inFlight            : Sample(2),
      transactionTime     : Sample(8),
      crossId             : Sample(20),
      routingFirmId       : Sample(4),
      cancelReason        : Sample(1),
      allocationCancelled : SampleLists(OneAllocationCancelled) ]

EncodeCrossOrderCancelledMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.crossId
        \o message.routingFirmId
        \o message.cancelReason
        \o EncodeUIntLE(Len(message.allocationCancelled), 1)
        \o EncodeAllocationCancelledList(message.allocationCancelled)

DecodeCrossOrderCancelledMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET crossId == ReadBytes(transactionTime.rest, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(crossId.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(routingFirmId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET allocCnt == ReadUIntLE(cancelReason.rest, 1) IN IF ~allocCnt.ok THEN Fail ELSE
    LET allocationCancelled == ReadAllocationCancelledList(allocCnt.rest, allocCnt.value) IN IF ~allocationCancelled.ok THEN Fail ELSE
    Ok([ inFlight            |-> inFlight.value,
         transactionTime     |-> transactionTime.value,
         crossId             |-> crossId.value,
         routingFirmId       |-> routingFirmId.value,
         cancelReason        |-> cancelReason.value,
         allocationCancelled |-> allocationCancelled.value ], allocationCancelled.rest)

ZeroCrossOrderCancelledMessage ==
    [ inFlight            |-> [i \in 1 .. 2 |-> 0],
      transactionTime     |-> [i \in 1 .. 8 |-> 0],
      crossId             |-> [i \in 1 .. 20 |-> 0],
      routingFirmId       |-> [i \in 1 .. 4 |-> 0],
      cancelReason        |-> [i \in 1 .. 1 |-> 0],
      allocationCancelled |-> << >> ]

(* Cross Order Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossOrderCancelledMessage ==
    { ZeroCrossOrderCancelledMessage }
        \cup { [ZeroCrossOrderCancelledMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroCrossOrderCancelledMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderCancelledMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroCrossOrderCancelledMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderCancelledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderCancelledMessage EXCEPT !.allocationCancelled = one] : one \in SampleLists(OneAllocationCancelled) }

(***************************************************************************)
(* Cancel Rejected Message: 99 bytes                                       *)
(***************************************************************************)

CancelRejectedMessage ==
    [ inFlight           : Sample(2),
      transactionTime    : Sample(8),
      clOrdId            : Sample(20),
      clearingFirm       : Sample(4),
      routingFirmId      : Sample(4),
      cancelRejectReason : Sample(1),
      text               : Sample(60) ]

EncodeCancelRejectedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.cancelRejectReason
        \o message.text

DecodeCancelRejectedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(routingFirmId.rest, 1) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(cancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight           |-> inFlight.value,
         transactionTime    |-> transactionTime.value,
         clOrdId            |-> clOrdId.value,
         clearingFirm       |-> clearingFirm.value,
         routingFirmId      |-> routingFirmId.value,
         cancelRejectReason |-> cancelRejectReason.value,
         text               |-> text.value ], text.rest)

ZeroCancelRejectedMessage ==
    [ inFlight           |-> [i \in 1 .. 2 |-> 0],
      transactionTime    |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 20 |-> 0],
      clearingFirm       |-> [i \in 1 .. 4 |-> 0],
      routingFirmId      |-> [i \in 1 .. 4 |-> 0],
      cancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      text               |-> [i \in 1 .. 60 |-> 0] ]

(* Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedMessage ==
    { ZeroCancelRejectedMessage }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.cancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Order Execution Message: 116 bytes                                      *)
(***************************************************************************)

OrderExecutionMessage ==
    [ inFlight                : Sample(2),
      transactionTime         : Sample(8),
      clOrdId                 : Sample(20),
      execId                  : Sample(8),
      lastShares              : Sample(4),
      lastPx                  : Sample(8),
      leavesQty               : Sample(4),
      baseLiquidityIndicator  : Sample(1),
      subLiquidityIndicator   : Sample(1),
      contraBroker            : Sample(4),
      side                    : Sample(1),
      symbol                  : Sample(8),
      contraTrader            : Sample(4),
      clearingFirm            : Sample(4),
      contraCapacity          : Sample(1),
      feeCode                 : Sample(2),
      marketingFeeCode        : Sample(2),
      routingFirmId           : Sample(4),
      crossExclusionIndicator : Sample(1),
      tradeDate               : Sample(4),
      multilegReportingType   : Sample(1),
      secondaryExecId         : Sample(8),
      priceType               : Sample(1),
      tradeThroughAlertType   : Sample(1),
      senderLocationId        : Sample(1),
      floorTraderAcronym      : Sample(3),
      floorTradeTime          : Sample(8),
      exDestination           : Sample(1),
      equityExDestination     : Sample(1) ]

EncodeOrderExecutionMessage(message) ==
    message.inFlight
        \o message.transactionTime
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
        \o message.contraTrader
        \o message.clearingFirm
        \o message.contraCapacity
        \o message.feeCode
        \o message.marketingFeeCode
        \o message.routingFirmId
        \o message.crossExclusionIndicator
        \o message.tradeDate
        \o message.multilegReportingType
        \o message.secondaryExecId
        \o message.priceType
        \o message.tradeThroughAlertType
        \o message.senderLocationId
        \o message.floorTraderAcronym
        \o message.floorTradeTime
        \o message.exDestination
        \o message.equityExDestination

DecodeOrderExecutionMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(execId.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(subLiquidityIndicator.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET side == ReadBytes(contraBroker.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET contraTrader == ReadBytes(symbol.rest, 4) IN IF ~contraTrader.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(contraTrader.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET contraCapacity == ReadBytes(clearingFirm.rest, 1) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET feeCode == ReadBytes(contraCapacity.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET marketingFeeCode == ReadBytes(feeCode.rest, 2) IN IF ~marketingFeeCode.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(marketingFeeCode.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET crossExclusionIndicator == ReadBytes(routingFirmId.rest, 1) IN IF ~crossExclusionIndicator.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(crossExclusionIndicator.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET multilegReportingType == ReadBytes(tradeDate.rest, 1) IN IF ~multilegReportingType.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(multilegReportingType.rest, 8) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET priceType == ReadBytes(secondaryExecId.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeThroughAlertType == ReadBytes(priceType.rest, 1) IN IF ~tradeThroughAlertType.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(tradeThroughAlertType.rest, 1) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET floorTraderAcronym == ReadBytes(senderLocationId.rest, 3) IN IF ~floorTraderAcronym.ok THEN Fail ELSE
    LET floorTradeTime == ReadBytes(floorTraderAcronym.rest, 8) IN IF ~floorTradeTime.ok THEN Fail ELSE
    LET exDestination == ReadBytes(floorTradeTime.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET equityExDestination == ReadBytes(exDestination.rest, 1) IN IF ~equityExDestination.ok THEN Fail ELSE
    Ok([ inFlight                |-> inFlight.value,
         transactionTime         |-> transactionTime.value,
         clOrdId                 |-> clOrdId.value,
         execId                  |-> execId.value,
         lastShares              |-> lastShares.value,
         lastPx                  |-> lastPx.value,
         leavesQty               |-> leavesQty.value,
         baseLiquidityIndicator  |-> baseLiquidityIndicator.value,
         subLiquidityIndicator   |-> subLiquidityIndicator.value,
         contraBroker            |-> contraBroker.value,
         side                    |-> side.value,
         symbol                  |-> symbol.value,
         contraTrader            |-> contraTrader.value,
         clearingFirm            |-> clearingFirm.value,
         contraCapacity          |-> contraCapacity.value,
         feeCode                 |-> feeCode.value,
         marketingFeeCode        |-> marketingFeeCode.value,
         routingFirmId           |-> routingFirmId.value,
         crossExclusionIndicator |-> crossExclusionIndicator.value,
         tradeDate               |-> tradeDate.value,
         multilegReportingType   |-> multilegReportingType.value,
         secondaryExecId         |-> secondaryExecId.value,
         priceType               |-> priceType.value,
         tradeThroughAlertType   |-> tradeThroughAlertType.value,
         senderLocationId        |-> senderLocationId.value,
         floorTraderAcronym      |-> floorTraderAcronym.value,
         floorTradeTime          |-> floorTradeTime.value,
         exDestination           |-> exDestination.value,
         equityExDestination     |-> equityExDestination.value ], equityExDestination.rest)

ZeroOrderExecutionMessage ==
    [ inFlight                |-> [i \in 1 .. 2 |-> 0],
      transactionTime         |-> [i \in 1 .. 8 |-> 0],
      clOrdId                 |-> [i \in 1 .. 20 |-> 0],
      execId                  |-> [i \in 1 .. 8 |-> 0],
      lastShares              |-> [i \in 1 .. 4 |-> 0],
      lastPx                  |-> [i \in 1 .. 8 |-> 0],
      leavesQty               |-> [i \in 1 .. 4 |-> 0],
      baseLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator   |-> [i \in 1 .. 1 |-> 0],
      contraBroker            |-> [i \in 1 .. 4 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      symbol                  |-> [i \in 1 .. 8 |-> 0],
      contraTrader            |-> [i \in 1 .. 4 |-> 0],
      clearingFirm            |-> [i \in 1 .. 4 |-> 0],
      contraCapacity          |-> [i \in 1 .. 1 |-> 0],
      feeCode                 |-> [i \in 1 .. 2 |-> 0],
      marketingFeeCode        |-> [i \in 1 .. 2 |-> 0],
      routingFirmId           |-> [i \in 1 .. 4 |-> 0],
      crossExclusionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeDate               |-> [i \in 1 .. 4 |-> 0],
      multilegReportingType   |-> [i \in 1 .. 1 |-> 0],
      secondaryExecId         |-> [i \in 1 .. 8 |-> 0],
      priceType               |-> [i \in 1 .. 1 |-> 0],
      tradeThroughAlertType   |-> [i \in 1 .. 1 |-> 0],
      senderLocationId        |-> [i \in 1 .. 1 |-> 0],
      floorTraderAcronym      |-> [i \in 1 .. 3 |-> 0],
      floorTradeTime          |-> [i \in 1 .. 8 |-> 0],
      exDestination           |-> [i \in 1 .. 1 |-> 0],
      equityExDestination     |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.contraTrader = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.contraCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.marketingFeeCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.crossExclusionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.multilegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.secondaryExecId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeThroughAlertType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.senderLocationId = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.floorTraderAcronym = one] : one \in Sample(3) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.floorTradeTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.equityExDestination = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Execution Message: 84 bytes                                       *)
(***************************************************************************)

QuoteExecutionMessage ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      quoteUpdateId          : Sample(16),
      orderId                : Sample(8),
      execId                 : Sample(8),
      quoteSymbol            : Sample(6),
      clearingFirm           : Sample(4),
      lastShares             : Sample(4),
      lastPx                 : Sample(8),
      leavesQty              : Sample(4),
      contraTrader           : Sample(4),
      contraCapacity         : Sample(1),
      side                   : Sample(1),
      baseLiquidityIndicator : Sample(1),
      subLiquidityIndicator  : Sample(1),
      feeCode                : Sample(2),
      marketingFeeCode       : Sample(2),
      tradeDate              : Sample(4) ]

EncodeQuoteExecutionMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.quoteUpdateId
        \o message.orderId
        \o message.execId
        \o message.quoteSymbol
        \o message.clearingFirm
        \o message.lastShares
        \o message.lastPx
        \o message.leavesQty
        \o message.contraTrader
        \o message.contraCapacity
        \o message.side
        \o message.baseLiquidityIndicator
        \o message.subLiquidityIndicator
        \o message.feeCode
        \o message.marketingFeeCode
        \o message.tradeDate

DecodeQuoteExecutionMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET quoteUpdateId == ReadBytes(transactionTime.rest, 16) IN IF ~quoteUpdateId.ok THEN Fail ELSE
    LET orderId == ReadBytes(quoteUpdateId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execId == ReadBytes(orderId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET quoteSymbol == ReadBytes(execId.rest, 6) IN IF ~quoteSymbol.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(quoteSymbol.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET lastShares == ReadBytes(clearingFirm.rest, 4) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastShares.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET contraTrader == ReadBytes(leavesQty.rest, 4) IN IF ~contraTrader.ok THEN Fail ELSE
    LET contraCapacity == ReadBytes(contraTrader.rest, 1) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET side == ReadBytes(contraCapacity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET baseLiquidityIndicator == ReadBytes(side.rest, 1) IN IF ~baseLiquidityIndicator.ok THEN Fail ELSE
    LET subLiquidityIndicator == ReadBytes(baseLiquidityIndicator.rest, 1) IN IF ~subLiquidityIndicator.ok THEN Fail ELSE
    LET feeCode == ReadBytes(subLiquidityIndicator.rest, 2) IN IF ~feeCode.ok THEN Fail ELSE
    LET marketingFeeCode == ReadBytes(feeCode.rest, 2) IN IF ~marketingFeeCode.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(marketingFeeCode.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         quoteUpdateId          |-> quoteUpdateId.value,
         orderId                |-> orderId.value,
         execId                 |-> execId.value,
         quoteSymbol            |-> quoteSymbol.value,
         clearingFirm           |-> clearingFirm.value,
         lastShares             |-> lastShares.value,
         lastPx                 |-> lastPx.value,
         leavesQty              |-> leavesQty.value,
         contraTrader           |-> contraTrader.value,
         contraCapacity         |-> contraCapacity.value,
         side                   |-> side.value,
         baseLiquidityIndicator |-> baseLiquidityIndicator.value,
         subLiquidityIndicator  |-> subLiquidityIndicator.value,
         feeCode                |-> feeCode.value,
         marketingFeeCode       |-> marketingFeeCode.value,
         tradeDate              |-> tradeDate.value ], tradeDate.rest)

ZeroQuoteExecutionMessage ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateId          |-> [i \in 1 .. 16 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      quoteSymbol            |-> [i \in 1 .. 6 |-> 0],
      clearingFirm           |-> [i \in 1 .. 4 |-> 0],
      lastShares             |-> [i \in 1 .. 4 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      contraTrader           |-> [i \in 1 .. 4 |-> 0],
      contraCapacity         |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      baseLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      subLiquidityIndicator  |-> [i \in 1 .. 1 |-> 0],
      feeCode                |-> [i \in 1 .. 2 |-> 0],
      marketingFeeCode       |-> [i \in 1 .. 2 |-> 0],
      tradeDate              |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteExecutionMessage ==
    { ZeroQuoteExecutionMessage }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.quoteUpdateId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.quoteSymbol = one] : one \in Sample(6) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.contraTrader = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.contraCapacity = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.feeCode = one] : one \in Sample(2) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.marketingFeeCode = one] : one \in Sample(2) }
        \cup { [ZeroQuoteExecutionMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Cancel Correct Message: 122 bytes                                 *)
(***************************************************************************)

TradeCancelCorrectMessage ==
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
      correctedSize          : Sample(4),
      origTime               : Sample(8),
      symbol                 : Sample(8),
      maturityDate           : Sample(4),
      strikePrice            : Sample(8),
      putOrCall              : Sample(1),
      capacity               : Sample(1),
      openClose              : Sample(1),
      marketingFeeCode       : Sample(2),
      targetPartyId          : Sample(4),
      cmtaNumber             : Sample(4) ]

EncodeTradeCancelCorrectMessage(message) ==
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
        \o message.correctedSize
        \o message.origTime
        \o message.symbol
        \o message.maturityDate
        \o message.strikePrice
        \o message.putOrCall
        \o message.capacity
        \o message.openClose
        \o message.marketingFeeCode
        \o message.targetPartyId
        \o message.cmtaNumber

DecodeTradeCancelCorrectMessage(bytes) ==
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
    LET correctedSize == ReadBytes(correctedPrice.rest, 4) IN IF ~correctedSize.ok THEN Fail ELSE
    LET origTime == ReadBytes(correctedSize.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET symbol == ReadBytes(origTime.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(symbol.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(maturityDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(strikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET capacity == ReadBytes(putOrCall.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET openClose == ReadBytes(capacity.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET marketingFeeCode == ReadBytes(openClose.rest, 2) IN IF ~marketingFeeCode.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(marketingFeeCode.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(targetPartyId.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
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
         correctedSize          |-> correctedSize.value,
         origTime               |-> origTime.value,
         symbol                 |-> symbol.value,
         maturityDate           |-> maturityDate.value,
         strikePrice            |-> strikePrice.value,
         putOrCall              |-> putOrCall.value,
         capacity               |-> capacity.value,
         openClose              |-> openClose.value,
         marketingFeeCode       |-> marketingFeeCode.value,
         targetPartyId          |-> targetPartyId.value,
         cmtaNumber             |-> cmtaNumber.value ], cmtaNumber.rest)

ZeroTradeCancelCorrectMessage ==
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
      correctedSize          |-> [i \in 1 .. 4 |-> 0],
      origTime               |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      maturityDate           |-> [i \in 1 .. 4 |-> 0],
      strikePrice            |-> [i \in 1 .. 8 |-> 0],
      putOrCall              |-> [i \in 1 .. 1 |-> 0],
      capacity               |-> [i \in 1 .. 1 |-> 0],
      openClose              |-> [i \in 1 .. 1 |-> 0],
      marketingFeeCode       |-> [i \in 1 .. 2 |-> 0],
      targetPartyId          |-> [i \in 1 .. 4 |-> 0],
      cmtaNumber             |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Correct Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelCorrectMessage ==
    { ZeroTradeCancelCorrectMessage }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.baseLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.subLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.lastShares = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.correctedPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.correctedSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.marketingFeeCode = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelCorrectMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Purge Rejected Message: 91 bytes                                        *)
(***************************************************************************)

PurgeRejectedMessage ==
    [ inFlight          : Sample(2),
      transactionTime   : Sample(8),
      massCancelId      : Sample(20),
      purgeRejectReason : Sample(1),
      text              : Sample(60) ]

EncodePurgeRejectedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.massCancelId
        \o message.purgeRejectReason
        \o message.text

DecodePurgeRejectedMessage(bytes) ==
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

ZeroPurgeRejectedMessage ==
    [ inFlight          |-> [i \in 1 .. 2 |-> 0],
      transactionTime   |-> [i \in 1 .. 8 |-> 0],
      massCancelId      |-> [i \in 1 .. 20 |-> 0],
      purgeRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* Purge Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeRejectedMessage ==
    { ZeroPurgeRejectedMessage }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.purgeRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroPurgeRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Reset Risk Acknowledgement Message: 27 bytes                            *)
(***************************************************************************)

ResetRiskAcknowledgementMessage ==
    [ inFlight            : Sample(2),
      riskStatusId        : Sample(16),
      riskResetResult     : Sample(1),
      requestReceivedTime : Sample(8) ]

EncodeResetRiskAcknowledgementMessage(message) ==
    message.inFlight
        \o message.riskStatusId
        \o message.riskResetResult
        \o message.requestReceivedTime

DecodeResetRiskAcknowledgementMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET riskStatusId == ReadBytes(inFlight.rest, 16) IN IF ~riskStatusId.ok THEN Fail ELSE
    LET riskResetResult == ReadBytes(riskStatusId.rest, 1) IN IF ~riskResetResult.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(riskResetResult.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ inFlight            |-> inFlight.value,
         riskStatusId        |-> riskStatusId.value,
         riskResetResult     |-> riskResetResult.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroResetRiskAcknowledgementMessage ==
    [ inFlight            |-> [i \in 1 .. 2 |-> 0],
      riskStatusId        |-> [i \in 1 .. 16 |-> 0],
      riskResetResult     |-> [i \in 1 .. 1 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Reset Risk Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedResetRiskAcknowledgementMessage ==
    { ZeroResetRiskAcknowledgementMessage }
        \cup { [ZeroResetRiskAcknowledgementMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroResetRiskAcknowledgementMessage EXCEPT !.riskStatusId = one] : one \in Sample(16) }
        \cup { [ZeroResetRiskAcknowledgementMessage EXCEPT !.riskResetResult = one] : one \in Sample(1) }
        \cup { [ZeroResetRiskAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Cancel Acknowledgment Message: 42 bytes                            *)
(***************************************************************************)

MassCancelAcknowledgmentMessage ==
    [ inFlight            : Sample(2),
      transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4),
      requestReceivedTime : Sample(8) ]

EncodeMassCancelAcknowledgmentMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount
        \o message.requestReceivedTime

DecodeMassCancelAcknowledgmentMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(cancelledOrderCount.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ inFlight            |-> inFlight.value,
         transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroMassCancelAcknowledgmentMessage ==
    [ inFlight            |-> [i \in 1 .. 2 |-> 0],
      transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Cancel Acknowledgment Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelAcknowledgmentMessage ==
    { ZeroMassCancelAcknowledgmentMessage }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAcknowledgmentMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Cancel Rejected Message: 91 bytes                                  *)
(***************************************************************************)

MassCancelRejectedMessage ==
    [ inFlight               : Sample(2),
      transactionTime        : Sample(8),
      massCancelId           : Sample(20),
      massCancelRejectReason : Sample(1),
      text                   : Sample(60) ]

EncodeMassCancelRejectedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.massCancelId
        \o message.massCancelRejectReason
        \o message.text

DecodeMassCancelRejectedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(massCancelId.rest, 1) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(massCancelRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight               |-> inFlight.value,
         transactionTime        |-> transactionTime.value,
         massCancelId           |-> massCancelId.value,
         massCancelRejectReason |-> massCancelRejectReason.value,
         text                   |-> text.value ], text.rest)

ZeroMassCancelRejectedMessage ==
    [ inFlight               |-> [i \in 1 .. 2 |-> 0],
      transactionTime        |-> [i \in 1 .. 8 |-> 0],
      massCancelId           |-> [i \in 1 .. 20 |-> 0],
      massCancelRejectReason |-> [i \in 1 .. 1 |-> 0],
      text                   |-> [i \in 1 .. 60 |-> 0] ]

(* Mass Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRejectedMessage ==
    { ZeroMassCancelRejectedMessage }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

(***************************************************************************)
(* Purge Acknowledgement Message: 43 bytes                                 *)
(***************************************************************************)

PurgeAcknowledgementMessage ==
    [ inFlight            : Sample(2),
      transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4),
      sourceMatchingUnit  : Sample(1),
      requestReceivedTime : Sample(8) ]

EncodePurgeAcknowledgementMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount
        \o message.sourceMatchingUnit
        \o message.requestReceivedTime

DecodePurgeAcknowledgementMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    LET sourceMatchingUnit == ReadBytes(cancelledOrderCount.rest, 1) IN IF ~sourceMatchingUnit.ok THEN Fail ELSE
    LET requestReceivedTime == ReadBytes(sourceMatchingUnit.rest, 8) IN IF ~requestReceivedTime.ok THEN Fail ELSE
    Ok([ inFlight            |-> inFlight.value,
         transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value,
         sourceMatchingUnit  |-> sourceMatchingUnit.value,
         requestReceivedTime |-> requestReceivedTime.value ], requestReceivedTime.rest)

ZeroPurgeAcknowledgementMessage ==
    [ inFlight            |-> [i \in 1 .. 2 |-> 0],
      transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0],
      sourceMatchingUnit  |-> [i \in 1 .. 1 |-> 0],
      requestReceivedTime |-> [i \in 1 .. 8 |-> 0] ]

(* Purge Acknowledgement Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeAcknowledgementMessage ==
    { ZeroPurgeAcknowledgementMessage }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.sourceMatchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroPurgeAcknowledgementMessage EXCEPT !.requestReceivedTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Purge Notification Message: 46 bytes                                    *)
(***************************************************************************)

PurgeNotificationMessage ==
    [ inFlight            : Sample(2),
      transactionTime     : Sample(8),
      massCancelId        : Sample(20),
      cancelledOrderCount : Sample(4),
      sourceMatchingUnit  : Sample(1),
      clearingFirm        : Sample(4),
      riskRoot            : Sample(6),
      massCancelLockout   : Sample(1) ]

EncodePurgeNotificationMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.massCancelId
        \o message.cancelledOrderCount
        \o message.sourceMatchingUnit
        \o message.clearingFirm
        \o message.riskRoot
        \o message.massCancelLockout

DecodePurgeNotificationMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(transactionTime.rest, 20) IN IF ~massCancelId.ok THEN Fail ELSE
    LET cancelledOrderCount == ReadBytes(massCancelId.rest, 4) IN IF ~cancelledOrderCount.ok THEN Fail ELSE
    LET sourceMatchingUnit == ReadBytes(cancelledOrderCount.rest, 1) IN IF ~sourceMatchingUnit.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(sourceMatchingUnit.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET riskRoot == ReadBytes(clearingFirm.rest, 6) IN IF ~riskRoot.ok THEN Fail ELSE
    LET massCancelLockout == ReadBytes(riskRoot.rest, 1) IN IF ~massCancelLockout.ok THEN Fail ELSE
    Ok([ inFlight            |-> inFlight.value,
         transactionTime     |-> transactionTime.value,
         massCancelId        |-> massCancelId.value,
         cancelledOrderCount |-> cancelledOrderCount.value,
         sourceMatchingUnit  |-> sourceMatchingUnit.value,
         clearingFirm        |-> clearingFirm.value,
         riskRoot            |-> riskRoot.value,
         massCancelLockout   |-> massCancelLockout.value ], massCancelLockout.rest)

ZeroPurgeNotificationMessage ==
    [ inFlight            |-> [i \in 1 .. 2 |-> 0],
      transactionTime     |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 20 |-> 0],
      cancelledOrderCount |-> [i \in 1 .. 4 |-> 0],
      sourceMatchingUnit  |-> [i \in 1 .. 1 |-> 0],
      clearingFirm        |-> [i \in 1 .. 4 |-> 0],
      riskRoot            |-> [i \in 1 .. 6 |-> 0],
      massCancelLockout   |-> [i \in 1 .. 1 |-> 0] ]

(* Purge Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedPurgeNotificationMessage ==
    { ZeroPurgeNotificationMessage }
        \cup { [ZeroPurgeNotificationMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroPurgeNotificationMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroPurgeNotificationMessage EXCEPT !.massCancelId = one] : one \in Sample(20) }
        \cup { [ZeroPurgeNotificationMessage EXCEPT !.cancelledOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroPurgeNotificationMessage EXCEPT !.sourceMatchingUnit = one] : one \in Sample(1) }
        \cup { [ZeroPurgeNotificationMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroPurgeNotificationMessage EXCEPT !.riskRoot = one] : one \in Sample(6) }
        \cup { [ZeroPurgeNotificationMessage EXCEPT !.massCancelLockout = one] : one \in Sample(1) }

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
(* New Complex Instrument Accepted Message                                 *)
(***************************************************************************)

NewComplexInstrumentAcceptedMessage ==
    [ inFlight        : Sample(2),
      transactionTime : Sample(8),
      clOrdId         : Sample(20),
      symbol          : Sample(8),
      noOfSecurities  : Sample(4),
      complexLeg      : SampleLists(OneComplexLeg) ]

EncodeNewComplexInstrumentAcceptedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.symbol
        \o message.noOfSecurities
        \o EncodeUIntLE(Len(message.complexLeg), 1)
        \o EncodeComplexLegList(message.complexLeg)

DecodeNewComplexInstrumentAcceptedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbol == ReadBytes(clOrdId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET noOfSecurities == ReadBytes(symbol.rest, 4) IN IF ~noOfSecurities.ok THEN Fail ELSE
    LET legCnt == ReadUIntLE(noOfSecurities.rest, 1) IN IF ~legCnt.ok THEN Fail ELSE
    LET complexLeg == ReadComplexLegList(legCnt.rest, legCnt.value) IN IF ~complexLeg.ok THEN Fail ELSE
    Ok([ inFlight        |-> inFlight.value,
         transactionTime |-> transactionTime.value,
         clOrdId         |-> clOrdId.value,
         symbol          |-> symbol.value,
         noOfSecurities  |-> noOfSecurities.value,
         complexLeg      |-> complexLeg.value ], complexLeg.rest)

ZeroNewComplexInstrumentAcceptedMessage ==
    [ inFlight        |-> [i \in 1 .. 2 |-> 0],
      transactionTime |-> [i \in 1 .. 8 |-> 0],
      clOrdId         |-> [i \in 1 .. 20 |-> 0],
      symbol          |-> [i \in 1 .. 8 |-> 0],
      noOfSecurities  |-> [i \in 1 .. 4 |-> 0],
      complexLeg      |-> << >> ]

(* New Complex Instrument Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexInstrumentAcceptedMessage ==
    { ZeroNewComplexInstrumentAcceptedMessage }
        \cup { [ZeroNewComplexInstrumentAcceptedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexInstrumentAcceptedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexInstrumentAcceptedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexInstrumentAcceptedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexInstrumentAcceptedMessage EXCEPT !.noOfSecurities = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexInstrumentAcceptedMessage EXCEPT !.complexLeg = one] : one \in SampleLists(OneComplexLeg) }

(***************************************************************************)
(* New Complex Instrument Rejected Message: 95 bytes                       *)
(***************************************************************************)

NewComplexInstrumentRejectedMessage ==
    [ inFlight          : Sample(2),
      transactionTime   : Sample(8),
      clOrdId           : Sample(20),
      noOfSecurities    : Sample(4),
      orderRejectReason : Sample(1),
      text              : Sample(60) ]

EncodeNewComplexInstrumentRejectedMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.noOfSecurities
        \o message.orderRejectReason
        \o message.text

DecodeNewComplexInstrumentRejectedMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET noOfSecurities == ReadBytes(clOrdId.rest, 4) IN IF ~noOfSecurities.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(noOfSecurities.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(orderRejectReason.rest, 60) IN IF ~text.ok THEN Fail ELSE
    Ok([ inFlight          |-> inFlight.value,
         transactionTime   |-> transactionTime.value,
         clOrdId           |-> clOrdId.value,
         noOfSecurities    |-> noOfSecurities.value,
         orderRejectReason |-> orderRejectReason.value,
         text              |-> text.value ], text.rest)

ZeroNewComplexInstrumentRejectedMessage ==
    [ inFlight          |-> [i \in 1 .. 2 |-> 0],
      transactionTime   |-> [i \in 1 .. 8 |-> 0],
      clOrdId           |-> [i \in 1 .. 20 |-> 0],
      noOfSecurities    |-> [i \in 1 .. 4 |-> 0],
      orderRejectReason |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 60 |-> 0] ]

(* New Complex Instrument Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedNewComplexInstrumentRejectedMessage ==
    { ZeroNewComplexInstrumentRejectedMessage }
        \cup { [ZeroNewComplexInstrumentRejectedMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroNewComplexInstrumentRejectedMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroNewComplexInstrumentRejectedMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewComplexInstrumentRejectedMessage EXCEPT !.noOfSecurities = one] : one \in Sample(4) }
        \cup { [ZeroNewComplexInstrumentRejectedMessage EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroNewComplexInstrumentRejectedMessage EXCEPT !.text = one] : one \in Sample(60) }

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
(* Carried Restatement Message: 240 bytes                                  *)
(***************************************************************************)

CarriedRestatementMessage ==
    [ inFlight             : Sample(2),
      transactionTime      : Sample(8),
      clOrdId              : Sample(20),
      orderId              : Sample(8),
      side                 : Sample(1),
      price                : Sample(8),
      execInst             : Sample(1),
      ordType              : Sample(1),
      timeInForce          : Sample(1),
      minQty               : Sample(4),
      symbol               : Sample(8),
      capacity             : Sample(1),
      account              : Sample(16),
      clearingFirm         : Sample(4),
      clearingAccount      : Sample(4),
      displayIndicator     : Sample(1),
      maxFloor             : Sample(4),
      orderQty             : Sample(4),
      preventMatch         : PreventMatch,
      maturityDate         : Sample(4),
      strikePrice          : Sample(8),
      putOrCall            : Sample(1),
      openClose            : Sample(1),
      leavesQty            : Sample(4),
      displayPrice         : Sample(8),
      workingPrice         : Sample(8),
      expireTime           : Sample(8),
      attributedQuote      : Sample(1),
      stopPx               : Sample(8),
      routingInst          : Sample(4),
      routStrategy         : Sample(6),
      routeDeliveryMethod  : Sample(3),
      exDestination        : Sample(1),
      targetPartyId        : Sample(4),
      auctionId            : Sample(8),
      cmtaNumber           : Sample(4),
      routingFirmId        : Sample(4),
      clearingOptionalData : Sample(16),
      cumQty               : Sample(4),
      drillThruProtection  : Sample(8),
      equityPartyId        : Sample(4),
      clientIdAttr         : Sample(4),
      frequentTraderId     : Sample(6),
      sessionEligibility   : Sample(1),
      comboOrder           : Sample(1),
      compression          : Sample(1),
      floorDestination     : Sample(4),
      floorRoutingInst     : Sample(1),
      orderOrigin          : Sample(3),
      priceType            : Sample(1),
      strategyId           : Sample(1),
      held                 : Sample(1) ]

EncodeCarriedRestatementMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.orderId
        \o message.side
        \o message.price
        \o message.execInst
        \o message.ordType
        \o message.timeInForce
        \o message.minQty
        \o message.symbol
        \o message.capacity
        \o message.account
        \o message.clearingFirm
        \o message.clearingAccount
        \o message.displayIndicator
        \o message.maxFloor
        \o message.orderQty
        \o EncodePreventMatch(message.preventMatch)
        \o message.maturityDate
        \o message.strikePrice
        \o message.putOrCall
        \o message.openClose
        \o message.leavesQty
        \o message.displayPrice
        \o message.workingPrice
        \o message.expireTime
        \o message.attributedQuote
        \o message.stopPx
        \o message.routingInst
        \o message.routStrategy
        \o message.routeDeliveryMethod
        \o message.exDestination
        \o message.targetPartyId
        \o message.auctionId
        \o message.cmtaNumber
        \o message.routingFirmId
        \o message.clearingOptionalData
        \o message.cumQty
        \o message.drillThruProtection
        \o message.equityPartyId
        \o message.clientIdAttr
        \o message.frequentTraderId
        \o message.sessionEligibility
        \o message.comboOrder
        \o message.compression
        \o message.floorDestination
        \o message.floorRoutingInst
        \o message.orderOrigin
        \o message.priceType
        \o message.strategyId
        \o message.held

DecodeCarriedRestatementMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET execInst == ReadBytes(price.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET ordType == ReadBytes(execInst.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET minQty == ReadBytes(timeInForce.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET symbol == ReadBytes(minQty.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET capacity == ReadBytes(symbol.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(account.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirm.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET displayIndicator == ReadBytes(clearingAccount.rest, 1) IN IF ~displayIndicator.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(displayIndicator.rest, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    LET orderQty == ReadBytes(maxFloor.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET preventMatch == DecodePreventMatch(orderQty.rest) IN IF ~preventMatch.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(preventMatch.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(maturityDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(strikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET openClose == ReadBytes(putOrCall.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(openClose.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET displayPrice == ReadBytes(leavesQty.rest, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(displayPrice.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET expireTime == ReadBytes(workingPrice.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET attributedQuote == ReadBytes(expireTime.rest, 1) IN IF ~attributedQuote.ok THEN Fail ELSE
    LET stopPx == ReadBytes(attributedQuote.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET routingInst == ReadBytes(stopPx.rest, 4) IN IF ~routingInst.ok THEN Fail ELSE
    LET routStrategy == ReadBytes(routingInst.rest, 6) IN IF ~routStrategy.ok THEN Fail ELSE
    LET routeDeliveryMethod == ReadBytes(routStrategy.rest, 3) IN IF ~routeDeliveryMethod.ok THEN Fail ELSE
    LET exDestination == ReadBytes(routeDeliveryMethod.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(exDestination.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(targetPartyId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET cmtaNumber == ReadBytes(auctionId.rest, 4) IN IF ~cmtaNumber.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(cmtaNumber.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET clearingOptionalData == ReadBytes(routingFirmId.rest, 16) IN IF ~clearingOptionalData.ok THEN Fail ELSE
    LET cumQty == ReadBytes(clearingOptionalData.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET drillThruProtection == ReadBytes(cumQty.rest, 8) IN IF ~drillThruProtection.ok THEN Fail ELSE
    LET equityPartyId == ReadBytes(drillThruProtection.rest, 4) IN IF ~equityPartyId.ok THEN Fail ELSE
    LET clientIdAttr == ReadBytes(equityPartyId.rest, 4) IN IF ~clientIdAttr.ok THEN Fail ELSE
    LET frequentTraderId == ReadBytes(clientIdAttr.rest, 6) IN IF ~frequentTraderId.ok THEN Fail ELSE
    LET sessionEligibility == ReadBytes(frequentTraderId.rest, 1) IN IF ~sessionEligibility.ok THEN Fail ELSE
    LET comboOrder == ReadBytes(sessionEligibility.rest, 1) IN IF ~comboOrder.ok THEN Fail ELSE
    LET compression == ReadBytes(comboOrder.rest, 1) IN IF ~compression.ok THEN Fail ELSE
    LET floorDestination == ReadBytes(compression.rest, 4) IN IF ~floorDestination.ok THEN Fail ELSE
    LET floorRoutingInst == ReadBytes(floorDestination.rest, 1) IN IF ~floorRoutingInst.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(floorRoutingInst.rest, 3) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET priceType == ReadBytes(orderOrigin.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET strategyId == ReadBytes(priceType.rest, 1) IN IF ~strategyId.ok THEN Fail ELSE
    LET held == ReadBytes(strategyId.rest, 1) IN IF ~held.ok THEN Fail ELSE
    Ok([ inFlight             |-> inFlight.value,
         transactionTime      |-> transactionTime.value,
         clOrdId              |-> clOrdId.value,
         orderId              |-> orderId.value,
         side                 |-> side.value,
         price                |-> price.value,
         execInst             |-> execInst.value,
         ordType              |-> ordType.value,
         timeInForce          |-> timeInForce.value,
         minQty               |-> minQty.value,
         symbol               |-> symbol.value,
         capacity             |-> capacity.value,
         account              |-> account.value,
         clearingFirm         |-> clearingFirm.value,
         clearingAccount      |-> clearingAccount.value,
         displayIndicator     |-> displayIndicator.value,
         maxFloor             |-> maxFloor.value,
         orderQty             |-> orderQty.value,
         preventMatch         |-> preventMatch.value,
         maturityDate         |-> maturityDate.value,
         strikePrice          |-> strikePrice.value,
         putOrCall            |-> putOrCall.value,
         openClose            |-> openClose.value,
         leavesQty            |-> leavesQty.value,
         displayPrice         |-> displayPrice.value,
         workingPrice         |-> workingPrice.value,
         expireTime           |-> expireTime.value,
         attributedQuote      |-> attributedQuote.value,
         stopPx               |-> stopPx.value,
         routingInst          |-> routingInst.value,
         routStrategy         |-> routStrategy.value,
         routeDeliveryMethod  |-> routeDeliveryMethod.value,
         exDestination        |-> exDestination.value,
         targetPartyId        |-> targetPartyId.value,
         auctionId            |-> auctionId.value,
         cmtaNumber           |-> cmtaNumber.value,
         routingFirmId        |-> routingFirmId.value,
         clearingOptionalData |-> clearingOptionalData.value,
         cumQty               |-> cumQty.value,
         drillThruProtection  |-> drillThruProtection.value,
         equityPartyId        |-> equityPartyId.value,
         clientIdAttr         |-> clientIdAttr.value,
         frequentTraderId     |-> frequentTraderId.value,
         sessionEligibility   |-> sessionEligibility.value,
         comboOrder           |-> comboOrder.value,
         compression          |-> compression.value,
         floorDestination     |-> floorDestination.value,
         floorRoutingInst     |-> floorRoutingInst.value,
         orderOrigin          |-> orderOrigin.value,
         priceType            |-> priceType.value,
         strategyId           |-> strategyId.value,
         held                 |-> held.value ], held.rest)

ZeroCarriedRestatementMessage ==
    [ inFlight             |-> [i \in 1 .. 2 |-> 0],
      transactionTime      |-> [i \in 1 .. 8 |-> 0],
      clOrdId              |-> [i \in 1 .. 20 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      execInst             |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      minQty               |-> [i \in 1 .. 4 |-> 0],
      symbol               |-> [i \in 1 .. 8 |-> 0],
      capacity             |-> [i \in 1 .. 1 |-> 0],
      account              |-> [i \in 1 .. 16 |-> 0],
      clearingFirm         |-> [i \in 1 .. 4 |-> 0],
      clearingAccount      |-> [i \in 1 .. 4 |-> 0],
      displayIndicator     |-> [i \in 1 .. 1 |-> 0],
      maxFloor             |-> [i \in 1 .. 4 |-> 0],
      orderQty             |-> [i \in 1 .. 4 |-> 0],
      preventMatch         |-> ZeroPreventMatch,
      maturityDate         |-> [i \in 1 .. 4 |-> 0],
      strikePrice          |-> [i \in 1 .. 8 |-> 0],
      putOrCall            |-> [i \in 1 .. 1 |-> 0],
      openClose            |-> [i \in 1 .. 1 |-> 0],
      leavesQty            |-> [i \in 1 .. 4 |-> 0],
      displayPrice         |-> [i \in 1 .. 8 |-> 0],
      workingPrice         |-> [i \in 1 .. 8 |-> 0],
      expireTime           |-> [i \in 1 .. 8 |-> 0],
      attributedQuote      |-> [i \in 1 .. 1 |-> 0],
      stopPx               |-> [i \in 1 .. 8 |-> 0],
      routingInst          |-> [i \in 1 .. 4 |-> 0],
      routStrategy         |-> [i \in 1 .. 6 |-> 0],
      routeDeliveryMethod  |-> [i \in 1 .. 3 |-> 0],
      exDestination        |-> [i \in 1 .. 1 |-> 0],
      targetPartyId        |-> [i \in 1 .. 4 |-> 0],
      auctionId            |-> [i \in 1 .. 8 |-> 0],
      cmtaNumber           |-> [i \in 1 .. 4 |-> 0],
      routingFirmId        |-> [i \in 1 .. 4 |-> 0],
      clearingOptionalData |-> [i \in 1 .. 16 |-> 0],
      cumQty               |-> [i \in 1 .. 4 |-> 0],
      drillThruProtection  |-> [i \in 1 .. 8 |-> 0],
      equityPartyId        |-> [i \in 1 .. 4 |-> 0],
      clientIdAttr         |-> [i \in 1 .. 4 |-> 0],
      frequentTraderId     |-> [i \in 1 .. 6 |-> 0],
      sessionEligibility   |-> [i \in 1 .. 1 |-> 0],
      comboOrder           |-> [i \in 1 .. 1 |-> 0],
      compression          |-> [i \in 1 .. 1 |-> 0],
      floorDestination     |-> [i \in 1 .. 4 |-> 0],
      floorRoutingInst     |-> [i \in 1 .. 1 |-> 0],
      orderOrigin          |-> [i \in 1 .. 3 |-> 0],
      priceType            |-> [i \in 1 .. 1 |-> 0],
      strategyId           |-> [i \in 1 .. 1 |-> 0],
      held                 |-> [i \in 1 .. 1 |-> 0] ]

(* Carried Restatement Message at zero, then each field in turn at the values it is checked at *)
CheckedCarriedRestatementMessage ==
    { ZeroCarriedRestatementMessage }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.displayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.maxFloor = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.preventMatch = one] : one \in CheckedPreventMatch }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.displayPrice = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.attributedQuote = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.routingInst = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.routStrategy = one] : one \in Sample(6) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.routeDeliveryMethod = one] : one \in Sample(3) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.cmtaNumber = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.clearingOptionalData = one] : one \in Sample(16) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.drillThruProtection = one] : one \in Sample(8) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.equityPartyId = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.clientIdAttr = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.frequentTraderId = one] : one \in Sample(6) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.sessionEligibility = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.comboOrder = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.compression = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.floorDestination = one] : one \in Sample(4) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.floorRoutingInst = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.orderOrigin = one] : one \in Sample(3) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.strategyId = one] : one \in Sample(1) }
        \cup { [ZeroCarriedRestatementMessage EXCEPT !.held = one] : one \in Sample(1) }

(***************************************************************************)
(* Done For Day Message: 46 bytes                                          *)
(***************************************************************************)

DoneForDayMessage ==
    [ inFlight        : Sample(2),
      transactionTime : Sample(8),
      clOrdId         : Sample(20),
      clearingFirm    : Sample(4),
      routingFirmId   : Sample(4),
      symbol          : Sample(8) ]

EncodeDoneForDayMessage(message) ==
    message.inFlight
        \o message.transactionTime
        \o message.clOrdId
        \o message.clearingFirm
        \o message.routingFirmId
        \o message.symbol

DecodeDoneForDayMessage(bytes) ==
    LET inFlight == ReadBytes(bytes, 2) IN IF ~inFlight.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(inFlight.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactionTime.rest, 20) IN IF ~clOrdId.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET routingFirmId == ReadBytes(clearingFirm.rest, 4) IN IF ~routingFirmId.ok THEN Fail ELSE
    LET symbol == ReadBytes(routingFirmId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ inFlight        |-> inFlight.value,
         transactionTime |-> transactionTime.value,
         clOrdId         |-> clOrdId.value,
         clearingFirm    |-> clearingFirm.value,
         routingFirmId   |-> routingFirmId.value,
         symbol          |-> symbol.value ], symbol.rest)

ZeroDoneForDayMessage ==
    [ inFlight        |-> [i \in 1 .. 2 |-> 0],
      transactionTime |-> [i \in 1 .. 8 |-> 0],
      clOrdId         |-> [i \in 1 .. 20 |-> 0],
      clearingFirm    |-> [i \in 1 .. 4 |-> 0],
      routingFirmId   |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 8 |-> 0] ]

(* Done For Day Message at zero, then each field in turn at the values it is checked at *)
CheckedDoneForDayMessage ==
    { ZeroDoneForDayMessage }
        \cup { [ZeroDoneForDayMessage EXCEPT !.inFlight = one] : one \in Sample(2) }
        \cup { [ZeroDoneForDayMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroDoneForDayMessage EXCEPT !.clOrdId = one] : one \in Sample(20) }
        \cup { [ZeroDoneForDayMessage EXCEPT !.clearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroDoneForDayMessage EXCEPT !.routingFirmId = one] : one \in Sample(4) }
        \cup { [ZeroDoneForDayMessage EXCEPT !.symbol = one] : one \in Sample(8) }

(***************************************************************************)
(* Exchange Message, selected by Exchange Message Type                     *)
(***************************************************************************)

LoginResponseMessageCode == 501  \* 0x1f5
ReplayCompleteCode == 502  \* 0x1f6
LogoutResponseMessageCode == 503  \* 0x1f7
ServerHeartbeatCode == 504  \* 0x1f8
OrderAcknowledgementMessageCode == 2501  \* 0x9c5
CrossOrderAcknowledgmentMessageCode == 2502  \* 0x9c6
QuoteUpdateAcknowledgementMessageCode == 2517  \* 0x9d5
OrderRejectedMessageCode == 2503  \* 0x9c7
CrossOrderRejectedMessageCode == 2504  \* 0x9c8
QuoteUpdateRejectedMessageCode == 2518  \* 0x9d6
OrderModifiedMessageCode == 2507  \* 0x9cb
OrderRestatedMessageCode == 2509  \* 0x9cd
QuoteRestatedMessageCode == 2521  \* 0x9d9
ModifyRejectedMessageCode == 2508  \* 0x9cc
OrderCancelledMessageCode == 2512  \* 0x9d0
QuoteCancelledMessageCode == 2519  \* 0x9d7
CrossOrderCancelledMessageCode == 2513  \* 0x9d1
CancelRejectedMessageCode == 2514  \* 0x9d2
OrderExecutionMessageCode == 2515  \* 0x9d3
QuoteExecutionMessageCode == 2520  \* 0x9d8
TradeCancelCorrectMessageCode == 2516  \* 0x9d4
PurgeRejectedMessageCode == 2526  \* 0x9de
ResetRiskAcknowledgementMessageCode == 2522  \* 0x9da
MassCancelAcknowledgmentMessageCode == 2523  \* 0x9db
MassCancelRejectedMessageCode == 2524  \* 0x9dc
PurgeAcknowledgementMessageCode == 2525  \* 0x9dd
PurgeNotificationMessageCode == 2527  \* 0x9df
NewComplexInstrumentAcceptedMessageCode == 2505  \* 0x9c9
NewComplexInstrumentRejectedMessageCode == 2506  \* 0x9ca
CarriedRestatementMessageCode == 2510  \* 0x9ce
DoneForDayMessageCode == 2511  \* 0x9cf

ExchangeMessage ==
    [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAcknowledgementMessageCode}, body : OrderAcknowledgementMessage ]
        \cup [ tag : {CrossOrderAcknowledgmentMessageCode}, body : CrossOrderAcknowledgmentMessage ]
        \cup [ tag : {QuoteUpdateAcknowledgementMessageCode}, body : QuoteUpdateAcknowledgementMessage ]
        \cup [ tag : {OrderRejectedMessageCode}, body : OrderRejectedMessage ]
        \cup [ tag : {CrossOrderRejectedMessageCode}, body : CrossOrderRejectedMessage ]
        \cup [ tag : {QuoteUpdateRejectedMessageCode}, body : QuoteUpdateRejectedMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {OrderRestatedMessageCode}, body : OrderRestatedMessage ]
        \cup [ tag : {QuoteRestatedMessageCode}, body : QuoteRestatedMessage ]
        \cup [ tag : {ModifyRejectedMessageCode}, body : ModifyRejectedMessage ]
        \cup [ tag : {OrderCancelledMessageCode}, body : OrderCancelledMessage ]
        \cup [ tag : {QuoteCancelledMessageCode}, body : QuoteCancelledMessage ]
        \cup [ tag : {CrossOrderCancelledMessageCode}, body : CrossOrderCancelledMessage ]
        \cup [ tag : {CancelRejectedMessageCode}, body : CancelRejectedMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {QuoteExecutionMessageCode}, body : QuoteExecutionMessage ]
        \cup [ tag : {TradeCancelCorrectMessageCode}, body : TradeCancelCorrectMessage ]
        \cup [ tag : {PurgeRejectedMessageCode}, body : PurgeRejectedMessage ]
        \cup [ tag : {ResetRiskAcknowledgementMessageCode}, body : ResetRiskAcknowledgementMessage ]
        \cup [ tag : {MassCancelAcknowledgmentMessageCode}, body : MassCancelAcknowledgmentMessage ]
        \cup [ tag : {MassCancelRejectedMessageCode}, body : MassCancelRejectedMessage ]
        \cup [ tag : {PurgeAcknowledgementMessageCode}, body : PurgeAcknowledgementMessage ]
        \cup [ tag : {PurgeNotificationMessageCode}, body : PurgeNotificationMessage ]
        \cup [ tag : {NewComplexInstrumentAcceptedMessageCode}, body : NewComplexInstrumentAcceptedMessage ]
        \cup [ tag : {NewComplexInstrumentRejectedMessageCode}, body : NewComplexInstrumentRejectedMessage ]
        \cup [ tag : {CarriedRestatementMessageCode}, body : CarriedRestatementMessage ]
        \cup [ tag : {DoneForDayMessageCode}, body : DoneForDayMessage ]

EncodeExchangeMessage(message) ==
    CASE message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayCompleteCode -> << >>
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = OrderAcknowledgementMessageCode -> EncodeOrderAcknowledgementMessage(message.body)
      [] message.tag = CrossOrderAcknowledgmentMessageCode -> EncodeCrossOrderAcknowledgmentMessage(message.body)
      [] message.tag = QuoteUpdateAcknowledgementMessageCode -> EncodeQuoteUpdateAcknowledgementMessage(message.body)
      [] message.tag = OrderRejectedMessageCode -> EncodeOrderRejectedMessage(message.body)
      [] message.tag = CrossOrderRejectedMessageCode -> EncodeCrossOrderRejectedMessage(message.body)
      [] message.tag = QuoteUpdateRejectedMessageCode -> EncodeQuoteUpdateRejectedMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = OrderRestatedMessageCode -> EncodeOrderRestatedMessage(message.body)
      [] message.tag = QuoteRestatedMessageCode -> EncodeQuoteRestatedMessage(message.body)
      [] message.tag = ModifyRejectedMessageCode -> EncodeModifyRejectedMessage(message.body)
      [] message.tag = OrderCancelledMessageCode -> EncodeOrderCancelledMessage(message.body)
      [] message.tag = QuoteCancelledMessageCode -> EncodeQuoteCancelledMessage(message.body)
      [] message.tag = CrossOrderCancelledMessageCode -> EncodeCrossOrderCancelledMessage(message.body)
      [] message.tag = CancelRejectedMessageCode -> EncodeCancelRejectedMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = QuoteExecutionMessageCode -> EncodeQuoteExecutionMessage(message.body)
      [] message.tag = TradeCancelCorrectMessageCode -> EncodeTradeCancelCorrectMessage(message.body)
      [] message.tag = PurgeRejectedMessageCode -> EncodePurgeRejectedMessage(message.body)
      [] message.tag = ResetRiskAcknowledgementMessageCode -> EncodeResetRiskAcknowledgementMessage(message.body)
      [] message.tag = MassCancelAcknowledgmentMessageCode -> EncodeMassCancelAcknowledgmentMessage(message.body)
      [] message.tag = MassCancelRejectedMessageCode -> EncodeMassCancelRejectedMessage(message.body)
      [] message.tag = PurgeAcknowledgementMessageCode -> EncodePurgeAcknowledgementMessage(message.body)
      [] message.tag = PurgeNotificationMessageCode -> EncodePurgeNotificationMessage(message.body)
      [] message.tag = NewComplexInstrumentAcceptedMessageCode -> EncodeNewComplexInstrumentAcceptedMessage(message.body)
      [] message.tag = NewComplexInstrumentRejectedMessageCode -> EncodeNewComplexInstrumentRejectedMessage(message.body)
      [] message.tag = CarriedRestatementMessageCode -> EncodeCarriedRestatementMessage(message.body)
      [] message.tag = DoneForDayMessageCode -> EncodeDoneForDayMessage(message.body)

DecodeExchangeMessage(tag, bytes) ==
    LET read ==
            CASE tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAcknowledgementMessageCode -> DecodeOrderAcknowledgementMessage(bytes)
              [] tag = CrossOrderAcknowledgmentMessageCode -> DecodeCrossOrderAcknowledgmentMessage(bytes)
              [] tag = QuoteUpdateAcknowledgementMessageCode -> DecodeQuoteUpdateAcknowledgementMessage(bytes)
              [] tag = OrderRejectedMessageCode -> DecodeOrderRejectedMessage(bytes)
              [] tag = CrossOrderRejectedMessageCode -> DecodeCrossOrderRejectedMessage(bytes)
              [] tag = QuoteUpdateRejectedMessageCode -> DecodeQuoteUpdateRejectedMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = OrderRestatedMessageCode -> DecodeOrderRestatedMessage(bytes)
              [] tag = QuoteRestatedMessageCode -> DecodeQuoteRestatedMessage(bytes)
              [] tag = ModifyRejectedMessageCode -> DecodeModifyRejectedMessage(bytes)
              [] tag = OrderCancelledMessageCode -> DecodeOrderCancelledMessage(bytes)
              [] tag = QuoteCancelledMessageCode -> DecodeQuoteCancelledMessage(bytes)
              [] tag = CrossOrderCancelledMessageCode -> DecodeCrossOrderCancelledMessage(bytes)
              [] tag = CancelRejectedMessageCode -> DecodeCancelRejectedMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = QuoteExecutionMessageCode -> DecodeQuoteExecutionMessage(bytes)
              [] tag = TradeCancelCorrectMessageCode -> DecodeTradeCancelCorrectMessage(bytes)
              [] tag = PurgeRejectedMessageCode -> DecodePurgeRejectedMessage(bytes)
              [] tag = ResetRiskAcknowledgementMessageCode -> DecodeResetRiskAcknowledgementMessage(bytes)
              [] tag = MassCancelAcknowledgmentMessageCode -> DecodeMassCancelAcknowledgmentMessage(bytes)
              [] tag = MassCancelRejectedMessageCode -> DecodeMassCancelRejectedMessage(bytes)
              [] tag = PurgeAcknowledgementMessageCode -> DecodePurgeAcknowledgementMessage(bytes)
              [] tag = PurgeNotificationMessageCode -> DecodePurgeNotificationMessage(bytes)
              [] tag = NewComplexInstrumentAcceptedMessageCode -> DecodeNewComplexInstrumentAcceptedMessage(bytes)
              [] tag = NewComplexInstrumentRejectedMessageCode -> DecodeNewComplexInstrumentRejectedMessage(bytes)
              [] tag = CarriedRestatementMessageCode -> DecodeCarriedRestatementMessage(bytes)
              [] tag = DoneForDayMessageCode -> DecodeDoneForDayMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroExchangeMessage == [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]

(* Each Exchange Message in turn, at the values the message it names is checked at *)
CheckedExchangeMessage ==
    { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAcknowledgementMessageCode, body |-> one] : one \in CheckedOrderAcknowledgementMessage }
        \cup { [tag |-> CrossOrderAcknowledgmentMessageCode, body |-> one] : one \in CheckedCrossOrderAcknowledgmentMessage }
        \cup { [tag |-> QuoteUpdateAcknowledgementMessageCode, body |-> one] : one \in CheckedQuoteUpdateAcknowledgementMessage }
        \cup { [tag |-> OrderRejectedMessageCode, body |-> one] : one \in CheckedOrderRejectedMessage }
        \cup { [tag |-> CrossOrderRejectedMessageCode, body |-> one] : one \in CheckedCrossOrderRejectedMessage }
        \cup { [tag |-> QuoteUpdateRejectedMessageCode, body |-> one] : one \in CheckedQuoteUpdateRejectedMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> OrderRestatedMessageCode, body |-> one] : one \in CheckedOrderRestatedMessage }
        \cup { [tag |-> QuoteRestatedMessageCode, body |-> one] : one \in CheckedQuoteRestatedMessage }
        \cup { [tag |-> ModifyRejectedMessageCode, body |-> one] : one \in CheckedModifyRejectedMessage }
        \cup { [tag |-> OrderCancelledMessageCode, body |-> one] : one \in CheckedOrderCancelledMessage }
        \cup { [tag |-> QuoteCancelledMessageCode, body |-> one] : one \in CheckedQuoteCancelledMessage }
        \cup { [tag |-> CrossOrderCancelledMessageCode, body |-> one] : one \in CheckedCrossOrderCancelledMessage }
        \cup { [tag |-> CancelRejectedMessageCode, body |-> one] : one \in CheckedCancelRejectedMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> QuoteExecutionMessageCode, body |-> one] : one \in CheckedQuoteExecutionMessage }
        \cup { [tag |-> TradeCancelCorrectMessageCode, body |-> one] : one \in CheckedTradeCancelCorrectMessage }
        \cup { [tag |-> PurgeRejectedMessageCode, body |-> one] : one \in CheckedPurgeRejectedMessage }
        \cup { [tag |-> ResetRiskAcknowledgementMessageCode, body |-> one] : one \in CheckedResetRiskAcknowledgementMessage }
        \cup { [tag |-> MassCancelAcknowledgmentMessageCode, body |-> one] : one \in CheckedMassCancelAcknowledgmentMessage }
        \cup { [tag |-> MassCancelRejectedMessageCode, body |-> one] : one \in CheckedMassCancelRejectedMessage }
        \cup { [tag |-> PurgeAcknowledgementMessageCode, body |-> one] : one \in CheckedPurgeAcknowledgementMessage }
        \cup { [tag |-> PurgeNotificationMessageCode, body |-> one] : one \in CheckedPurgeNotificationMessage }
        \cup { [tag |-> NewComplexInstrumentAcceptedMessageCode, body |-> one] : one \in CheckedNewComplexInstrumentAcceptedMessage }
        \cup { [tag |-> NewComplexInstrumentRejectedMessageCode, body |-> one] : one \in CheckedNewComplexInstrumentRejectedMessage }
        \cup { [tag |-> CarriedRestatementMessageCode, body |-> one] : one \in CheckedCarriedRestatementMessage }
        \cup { [tag |-> DoneForDayMessageCode, body |-> one] : one \in CheckedDoneForDayMessage }

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

(* Every Order Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcknowledgementMessage ==
    \A message \in CheckedOrderAcknowledgementMessage :
        LET read == DecodeOrderAcknowledgementMessage(EncodeOrderAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Acknowledgement Allocation decodes back to what was encoded, and leaves nothing over *)
RoundTripAcknowledgementAllocation ==
    \A message \in CheckedAcknowledgementAllocation :
        LET read == DecodeAcknowledgementAllocation(EncodeAcknowledgementAllocation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Order Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossOrderAcknowledgmentMessage ==
    \A message \in CheckedCrossOrderAcknowledgmentMessage :
        LET read == DecodeCrossOrderAcknowledgmentMessage(EncodeCrossOrderAcknowledgmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAcknowledgement ==
    \A message \in CheckedQuoteAcknowledgement :
        LET read == DecodeQuoteAcknowledgement(EncodeQuoteAcknowledgement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateAcknowledgementMessage ==
    \A message \in CheckedQuoteUpdateAcknowledgementMessage :
        LET read == DecodeQuoteUpdateAcknowledgementMessage(EncodeQuoteUpdateAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectedMessage ==
    \A message \in CheckedOrderRejectedMessage :
        LET read == DecodeOrderRejectedMessage(EncodeOrderRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossOrderRejectedMessage ==
    \A message \in CheckedCrossOrderRejectedMessage :
        LET read == DecodeCrossOrderRejectedMessage(EncodeCrossOrderRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateRejectedMessage ==
    \A message \in CheckedQuoteUpdateRejectedMessage :
        LET read == DecodeQuoteUpdateRejectedMessage(EncodeQuoteUpdateRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedMessage ==
    \A message \in CheckedOrderModifiedMessage :
        LET read == DecodeOrderModifiedMessage(EncodeOrderModifiedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedMessage ==
    \A message \in CheckedOrderRestatedMessage :
        LET read == DecodeOrderRestatedMessage(EncodeOrderRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRestatedMessage ==
    \A message \in CheckedQuoteRestatedMessage :
        LET read == DecodeQuoteRestatedMessage(EncodeQuoteRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyRejectedMessage ==
    \A message \in CheckedModifyRejectedMessage :
        LET read == DecodeModifyRejectedMessage(EncodeModifyRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelledMessage ==
    \A message \in CheckedOrderCancelledMessage :
        LET read == DecodeOrderCancelledMessage(EncodeOrderCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelledMessage ==
    \A message \in CheckedQuoteCancelledMessage :
        LET read == DecodeQuoteCancelledMessage(EncodeQuoteCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Cancelled decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationCancelled ==
    \A message \in CheckedAllocationCancelled :
        LET read == DecodeAllocationCancelled(EncodeAllocationCancelled(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Order Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossOrderCancelledMessage ==
    \A message \in CheckedCrossOrderCancelledMessage :
        LET read == DecodeCrossOrderCancelledMessage(EncodeCrossOrderCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedMessage ==
    \A message \in CheckedCancelRejectedMessage :
        LET read == DecodeCancelRejectedMessage(EncodeCancelRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteExecutionMessage ==
    \A message \in CheckedQuoteExecutionMessage :
        LET read == DecodeQuoteExecutionMessage(EncodeQuoteExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Correct Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelCorrectMessage ==
    \A message \in CheckedTradeCancelCorrectMessage :
        LET read == DecodeTradeCancelCorrectMessage(EncodeTradeCancelCorrectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeRejectedMessage ==
    \A message \in CheckedPurgeRejectedMessage :
        LET read == DecodePurgeRejectedMessage(EncodePurgeRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Risk Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetRiskAcknowledgementMessage ==
    \A message \in CheckedResetRiskAcknowledgementMessage :
        LET read == DecodeResetRiskAcknowledgementMessage(EncodeResetRiskAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Acknowledgment Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelAcknowledgmentMessage ==
    \A message \in CheckedMassCancelAcknowledgmentMessage :
        LET read == DecodeMassCancelAcknowledgmentMessage(EncodeMassCancelAcknowledgmentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRejectedMessage ==
    \A message \in CheckedMassCancelRejectedMessage :
        LET read == DecodeMassCancelRejectedMessage(EncodeMassCancelRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Acknowledgement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeAcknowledgementMessage ==
    \A message \in CheckedPurgeAcknowledgementMessage :
        LET read == DecodePurgeAcknowledgementMessage(EncodePurgeAcknowledgementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Purge Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPurgeNotificationMessage ==
    \A message \in CheckedPurgeNotificationMessage :
        LET read == DecodePurgeNotificationMessage(EncodePurgeNotificationMessage(message))
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

(* Every New Complex Instrument Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexInstrumentAcceptedMessage ==
    \A message \in CheckedNewComplexInstrumentAcceptedMessage :
        LET read == DecodeNewComplexInstrumentAcceptedMessage(EncodeNewComplexInstrumentAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Complex Instrument Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewComplexInstrumentRejectedMessage ==
    \A message \in CheckedNewComplexInstrumentRejectedMessage :
        LET read == DecodeNewComplexInstrumentRejectedMessage(EncodeNewComplexInstrumentRejectedMessage(message))
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

(* Every Carried Restatement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCarriedRestatementMessage ==
    \A message \in CheckedCarriedRestatementMessage :
        LET read == DecodeCarriedRestatementMessage(EncodeCarriedRestatementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Done For Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDoneForDayMessage ==
    \A message \in CheckedDoneForDayMessage :
        LET read == DecodeDoneForDayMessage(EncodeDoneForDayMessage(message))
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
