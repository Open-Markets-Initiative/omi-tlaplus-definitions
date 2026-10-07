------------------- MODULE NtxEquities_Rash_v1_1_Server --------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Rash v1.1                                                      *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* System Event Message: 1 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ eventCode : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET eventCode == ReadBytes(bytes, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ eventCode |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ eventCode |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Accepted Order Message: 147 bytes                                       *)
(***************************************************************************)

AcceptedOrderMessage ==
    [ orderTokenClientOrderId     : Sample(14),
      side                        : Sample(1),
      sharesOrderQty              : Sample(6),
      stockSymbol                 : Sample(8),
      price                       : Sample(10),
      timeInForce                 : Sample(5),
      firmClientId                : Sample(4),
      display                     : Sample(1),
      orderReferenceNumber        : Sample(9),
      minQty                      : Sample(6),
      maxFloor                    : Sample(6),
      pegType                     : Sample(1),
      pegDifferenceSign           : Sample(1),
      pegDifference               : Sample(10),
      discretionPrice             : Sample(10),
      discretionPegType           : Sample(1),
      discretionPegDifferenceSign : Sample(1),
      discretionPegDifference     : Sample(10),
      capacityRule80AIndicator    : Sample(1),
      randomReserve               : Sample(6),
      routeDestExecBroker         : Sample(4),
      custTerminalIdSenderSubId   : Sample(32) ]

EncodeAcceptedOrderMessage(message) ==
    message.orderTokenClientOrderId
        \o message.side
        \o message.sharesOrderQty
        \o message.stockSymbol
        \o message.price
        \o message.timeInForce
        \o message.firmClientId
        \o message.display
        \o message.orderReferenceNumber
        \o message.minQty
        \o message.maxFloor
        \o message.pegType
        \o message.pegDifferenceSign
        \o message.pegDifference
        \o message.discretionPrice
        \o message.discretionPegType
        \o message.discretionPegDifferenceSign
        \o message.discretionPegDifference
        \o message.capacityRule80AIndicator
        \o message.randomReserve
        \o message.routeDestExecBroker
        \o message.custTerminalIdSenderSubId

DecodeAcceptedOrderMessage(bytes) ==
    LET orderTokenClientOrderId == ReadBytes(bytes, 14) IN IF ~orderTokenClientOrderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderTokenClientOrderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sharesOrderQty == ReadBytes(side.rest, 6) IN IF ~sharesOrderQty.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(sharesOrderQty.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET price == ReadBytes(stockSymbol.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 5) IN IF ~timeInForce.ok THEN Fail ELSE
    LET firmClientId == ReadBytes(timeInForce.rest, 4) IN IF ~firmClientId.ok THEN Fail ELSE
    LET display == ReadBytes(firmClientId.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(display.rest, 9) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderReferenceNumber.rest, 6) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 6) IN IF ~maxFloor.ok THEN Fail ELSE
    LET pegType == ReadBytes(maxFloor.rest, 1) IN IF ~pegType.ok THEN Fail ELSE
    LET pegDifferenceSign == ReadBytes(pegType.rest, 1) IN IF ~pegDifferenceSign.ok THEN Fail ELSE
    LET pegDifference == ReadBytes(pegDifferenceSign.rest, 10) IN IF ~pegDifference.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(pegDifference.rest, 10) IN IF ~discretionPrice.ok THEN Fail ELSE
    LET discretionPegType == ReadBytes(discretionPrice.rest, 1) IN IF ~discretionPegType.ok THEN Fail ELSE
    LET discretionPegDifferenceSign == ReadBytes(discretionPegType.rest, 1) IN IF ~discretionPegDifferenceSign.ok THEN Fail ELSE
    LET discretionPegDifference == ReadBytes(discretionPegDifferenceSign.rest, 10) IN IF ~discretionPegDifference.ok THEN Fail ELSE
    LET capacityRule80AIndicator == ReadBytes(discretionPegDifference.rest, 1) IN IF ~capacityRule80AIndicator.ok THEN Fail ELSE
    LET randomReserve == ReadBytes(capacityRule80AIndicator.rest, 6) IN IF ~randomReserve.ok THEN Fail ELSE
    LET routeDestExecBroker == ReadBytes(randomReserve.rest, 4) IN IF ~routeDestExecBroker.ok THEN Fail ELSE
    LET custTerminalIdSenderSubId == ReadBytes(routeDestExecBroker.rest, 32) IN IF ~custTerminalIdSenderSubId.ok THEN Fail ELSE
    Ok([ orderTokenClientOrderId     |-> orderTokenClientOrderId.value,
         side                        |-> side.value,
         sharesOrderQty              |-> sharesOrderQty.value,
         stockSymbol                 |-> stockSymbol.value,
         price                       |-> price.value,
         timeInForce                 |-> timeInForce.value,
         firmClientId                |-> firmClientId.value,
         display                     |-> display.value,
         orderReferenceNumber        |-> orderReferenceNumber.value,
         minQty                      |-> minQty.value,
         maxFloor                    |-> maxFloor.value,
         pegType                     |-> pegType.value,
         pegDifferenceSign           |-> pegDifferenceSign.value,
         pegDifference               |-> pegDifference.value,
         discretionPrice             |-> discretionPrice.value,
         discretionPegType           |-> discretionPegType.value,
         discretionPegDifferenceSign |-> discretionPegDifferenceSign.value,
         discretionPegDifference     |-> discretionPegDifference.value,
         capacityRule80AIndicator    |-> capacityRule80AIndicator.value,
         randomReserve               |-> randomReserve.value,
         routeDestExecBroker         |-> routeDestExecBroker.value,
         custTerminalIdSenderSubId   |-> custTerminalIdSenderSubId.value ], custTerminalIdSenderSubId.rest)

ZeroAcceptedOrderMessage ==
    [ orderTokenClientOrderId     |-> [i \in 1 .. 14 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      sharesOrderQty              |-> [i \in 1 .. 6 |-> 0],
      stockSymbol                 |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 10 |-> 0],
      timeInForce                 |-> [i \in 1 .. 5 |-> 0],
      firmClientId                |-> [i \in 1 .. 4 |-> 0],
      display                     |-> [i \in 1 .. 1 |-> 0],
      orderReferenceNumber        |-> [i \in 1 .. 9 |-> 0],
      minQty                      |-> [i \in 1 .. 6 |-> 0],
      maxFloor                    |-> [i \in 1 .. 6 |-> 0],
      pegType                     |-> [i \in 1 .. 1 |-> 0],
      pegDifferenceSign           |-> [i \in 1 .. 1 |-> 0],
      pegDifference               |-> [i \in 1 .. 10 |-> 0],
      discretionPrice             |-> [i \in 1 .. 10 |-> 0],
      discretionPegType           |-> [i \in 1 .. 1 |-> 0],
      discretionPegDifferenceSign |-> [i \in 1 .. 1 |-> 0],
      discretionPegDifference     |-> [i \in 1 .. 10 |-> 0],
      capacityRule80AIndicator    |-> [i \in 1 .. 1 |-> 0],
      randomReserve               |-> [i \in 1 .. 6 |-> 0],
      routeDestExecBroker         |-> [i \in 1 .. 4 |-> 0],
      custTerminalIdSenderSubId   |-> [i \in 1 .. 32 |-> 0] ]

(* Accepted Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAcceptedOrderMessage ==
    { ZeroAcceptedOrderMessage }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.orderTokenClientOrderId = one] : one \in Sample(14) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.sharesOrderQty = one] : one \in Sample(6) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(5) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.firmClientId = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.minQty = one] : one \in Sample(6) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.maxFloor = one] : one \in Sample(6) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.pegType = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.pegDifferenceSign = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.pegDifference = one] : one \in Sample(10) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.discretionPrice = one] : one \in Sample(10) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.discretionPegType = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.discretionPegDifferenceSign = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.discretionPegDifference = one] : one \in Sample(10) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.capacityRule80AIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.randomReserve = one] : one \in Sample(6) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.routeDestExecBroker = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedOrderMessage EXCEPT !.custTerminalIdSenderSubId = one] : one \in Sample(32) }

(***************************************************************************)
(* Accepted Order Message With Cross Functionality: 149 bytes              *)
(***************************************************************************)

AcceptedOrderMessageWithCrossFunctionality ==
    [ orderTokenClientOrderId     : Sample(14),
      side                        : Sample(1),
      sharesOrderQty              : Sample(6),
      stockSymbol                 : Sample(8),
      price                       : Sample(10),
      timeInForce                 : Sample(5),
      firmClientId                : Sample(4),
      display                     : Sample(1),
      orderReferenceNumber        : Sample(9),
      minQty                      : Sample(6),
      maxFloor                    : Sample(6),
      pegType                     : Sample(1),
      pegDifferenceSign           : Sample(1),
      pegDifference               : Sample(10),
      discretionPrice             : Sample(10),
      discretionPegType           : Sample(1),
      discretionPegDifferenceSign : Sample(1),
      discretionPegDifference     : Sample(10),
      capacityRule80AIndicator    : Sample(1),
      randomReserve               : Sample(6),
      routeDestExecBroker         : Sample(4),
      custTerminalIdSenderSubId   : Sample(32),
      intermarketSweepEligibility : Sample(1),
      crossType                   : Sample(1) ]

EncodeAcceptedOrderMessageWithCrossFunctionality(message) ==
    message.orderTokenClientOrderId
        \o message.side
        \o message.sharesOrderQty
        \o message.stockSymbol
        \o message.price
        \o message.timeInForce
        \o message.firmClientId
        \o message.display
        \o message.orderReferenceNumber
        \o message.minQty
        \o message.maxFloor
        \o message.pegType
        \o message.pegDifferenceSign
        \o message.pegDifference
        \o message.discretionPrice
        \o message.discretionPegType
        \o message.discretionPegDifferenceSign
        \o message.discretionPegDifference
        \o message.capacityRule80AIndicator
        \o message.randomReserve
        \o message.routeDestExecBroker
        \o message.custTerminalIdSenderSubId
        \o message.intermarketSweepEligibility
        \o message.crossType

DecodeAcceptedOrderMessageWithCrossFunctionality(bytes) ==
    LET orderTokenClientOrderId == ReadBytes(bytes, 14) IN IF ~orderTokenClientOrderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderTokenClientOrderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sharesOrderQty == ReadBytes(side.rest, 6) IN IF ~sharesOrderQty.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(sharesOrderQty.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET price == ReadBytes(stockSymbol.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 5) IN IF ~timeInForce.ok THEN Fail ELSE
    LET firmClientId == ReadBytes(timeInForce.rest, 4) IN IF ~firmClientId.ok THEN Fail ELSE
    LET display == ReadBytes(firmClientId.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(display.rest, 9) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET minQty == ReadBytes(orderReferenceNumber.rest, 6) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloor == ReadBytes(minQty.rest, 6) IN IF ~maxFloor.ok THEN Fail ELSE
    LET pegType == ReadBytes(maxFloor.rest, 1) IN IF ~pegType.ok THEN Fail ELSE
    LET pegDifferenceSign == ReadBytes(pegType.rest, 1) IN IF ~pegDifferenceSign.ok THEN Fail ELSE
    LET pegDifference == ReadBytes(pegDifferenceSign.rest, 10) IN IF ~pegDifference.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(pegDifference.rest, 10) IN IF ~discretionPrice.ok THEN Fail ELSE
    LET discretionPegType == ReadBytes(discretionPrice.rest, 1) IN IF ~discretionPegType.ok THEN Fail ELSE
    LET discretionPegDifferenceSign == ReadBytes(discretionPegType.rest, 1) IN IF ~discretionPegDifferenceSign.ok THEN Fail ELSE
    LET discretionPegDifference == ReadBytes(discretionPegDifferenceSign.rest, 10) IN IF ~discretionPegDifference.ok THEN Fail ELSE
    LET capacityRule80AIndicator == ReadBytes(discretionPegDifference.rest, 1) IN IF ~capacityRule80AIndicator.ok THEN Fail ELSE
    LET randomReserve == ReadBytes(capacityRule80AIndicator.rest, 6) IN IF ~randomReserve.ok THEN Fail ELSE
    LET routeDestExecBroker == ReadBytes(randomReserve.rest, 4) IN IF ~routeDestExecBroker.ok THEN Fail ELSE
    LET custTerminalIdSenderSubId == ReadBytes(routeDestExecBroker.rest, 32) IN IF ~custTerminalIdSenderSubId.ok THEN Fail ELSE
    LET intermarketSweepEligibility == ReadBytes(custTerminalIdSenderSubId.rest, 1) IN IF ~intermarketSweepEligibility.ok THEN Fail ELSE
    LET crossType == ReadBytes(intermarketSweepEligibility.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    Ok([ orderTokenClientOrderId     |-> orderTokenClientOrderId.value,
         side                        |-> side.value,
         sharesOrderQty              |-> sharesOrderQty.value,
         stockSymbol                 |-> stockSymbol.value,
         price                       |-> price.value,
         timeInForce                 |-> timeInForce.value,
         firmClientId                |-> firmClientId.value,
         display                     |-> display.value,
         orderReferenceNumber        |-> orderReferenceNumber.value,
         minQty                      |-> minQty.value,
         maxFloor                    |-> maxFloor.value,
         pegType                     |-> pegType.value,
         pegDifferenceSign           |-> pegDifferenceSign.value,
         pegDifference               |-> pegDifference.value,
         discretionPrice             |-> discretionPrice.value,
         discretionPegType           |-> discretionPegType.value,
         discretionPegDifferenceSign |-> discretionPegDifferenceSign.value,
         discretionPegDifference     |-> discretionPegDifference.value,
         capacityRule80AIndicator    |-> capacityRule80AIndicator.value,
         randomReserve               |-> randomReserve.value,
         routeDestExecBroker         |-> routeDestExecBroker.value,
         custTerminalIdSenderSubId   |-> custTerminalIdSenderSubId.value,
         intermarketSweepEligibility |-> intermarketSweepEligibility.value,
         crossType                   |-> crossType.value ], crossType.rest)

ZeroAcceptedOrderMessageWithCrossFunctionality ==
    [ orderTokenClientOrderId     |-> [i \in 1 .. 14 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      sharesOrderQty              |-> [i \in 1 .. 6 |-> 0],
      stockSymbol                 |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 10 |-> 0],
      timeInForce                 |-> [i \in 1 .. 5 |-> 0],
      firmClientId                |-> [i \in 1 .. 4 |-> 0],
      display                     |-> [i \in 1 .. 1 |-> 0],
      orderReferenceNumber        |-> [i \in 1 .. 9 |-> 0],
      minQty                      |-> [i \in 1 .. 6 |-> 0],
      maxFloor                    |-> [i \in 1 .. 6 |-> 0],
      pegType                     |-> [i \in 1 .. 1 |-> 0],
      pegDifferenceSign           |-> [i \in 1 .. 1 |-> 0],
      pegDifference               |-> [i \in 1 .. 10 |-> 0],
      discretionPrice             |-> [i \in 1 .. 10 |-> 0],
      discretionPegType           |-> [i \in 1 .. 1 |-> 0],
      discretionPegDifferenceSign |-> [i \in 1 .. 1 |-> 0],
      discretionPegDifference     |-> [i \in 1 .. 10 |-> 0],
      capacityRule80AIndicator    |-> [i \in 1 .. 1 |-> 0],
      randomReserve               |-> [i \in 1 .. 6 |-> 0],
      routeDestExecBroker         |-> [i \in 1 .. 4 |-> 0],
      custTerminalIdSenderSubId   |-> [i \in 1 .. 32 |-> 0],
      intermarketSweepEligibility |-> [i \in 1 .. 1 |-> 0],
      crossType                   |-> [i \in 1 .. 1 |-> 0] ]

(* Accepted Order Message With Cross Functionality at zero, then each field in turn at the values it is checked at *)
CheckedAcceptedOrderMessageWithCrossFunctionality ==
    { ZeroAcceptedOrderMessageWithCrossFunctionality }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.orderTokenClientOrderId = one] : one \in Sample(14) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.sharesOrderQty = one] : one \in Sample(6) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.timeInForce = one] : one \in Sample(5) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.firmClientId = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.orderReferenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.minQty = one] : one \in Sample(6) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.maxFloor = one] : one \in Sample(6) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.pegType = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.pegDifferenceSign = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.pegDifference = one] : one \in Sample(10) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.discretionPrice = one] : one \in Sample(10) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.discretionPegType = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.discretionPegDifferenceSign = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.discretionPegDifference = one] : one \in Sample(10) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.capacityRule80AIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.randomReserve = one] : one \in Sample(6) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.routeDestExecBroker = one] : one \in Sample(4) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.custTerminalIdSenderSubId = one] : one \in Sample(32) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.intermarketSweepEligibility = one] : one \in Sample(1) }
        \cup { [ZeroAcceptedOrderMessageWithCrossFunctionality EXCEPT !.crossType = one] : one \in Sample(1) }

(***************************************************************************)
(* Canceled Order Message: 21 bytes                                        *)
(***************************************************************************)

CanceledOrderMessage ==
    [ orderTokenClientOrderId : Sample(14),
      shares                  : Sample(6),
      cancelReason            : Sample(1) ]

EncodeCanceledOrderMessage(message) ==
    message.orderTokenClientOrderId
        \o message.shares
        \o message.cancelReason

DecodeCanceledOrderMessage(bytes) ==
    LET orderTokenClientOrderId == ReadBytes(bytes, 14) IN IF ~orderTokenClientOrderId.ok THEN Fail ELSE
    LET shares == ReadBytes(orderTokenClientOrderId.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(shares.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ orderTokenClientOrderId |-> orderTokenClientOrderId.value,
         shares                  |-> shares.value,
         cancelReason            |-> cancelReason.value ], cancelReason.rest)

ZeroCanceledOrderMessage ==
    [ orderTokenClientOrderId |-> [i \in 1 .. 14 |-> 0],
      shares                  |-> [i \in 1 .. 6 |-> 0],
      cancelReason            |-> [i \in 1 .. 1 |-> 0] ]

(* Canceled Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCanceledOrderMessage ==
    { ZeroCanceledOrderMessage }
        \cup { [ZeroCanceledOrderMessage EXCEPT !.orderTokenClientOrderId = one] : one \in Sample(14) }
        \cup { [ZeroCanceledOrderMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroCanceledOrderMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Rejected Order Message: 15 bytes                                        *)
(***************************************************************************)

RejectedOrderMessage ==
    [ orderTokenClientOrderId : Sample(14),
      rejectReason            : Sample(1) ]

EncodeRejectedOrderMessage(message) ==
    message.orderTokenClientOrderId
        \o message.rejectReason

DecodeRejectedOrderMessage(bytes) ==
    LET orderTokenClientOrderId == ReadBytes(bytes, 14) IN IF ~orderTokenClientOrderId.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(orderTokenClientOrderId.rest, 1) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ orderTokenClientOrderId |-> orderTokenClientOrderId.value,
         rejectReason            |-> rejectReason.value ], rejectReason.rest)

ZeroRejectedOrderMessage ==
    [ orderTokenClientOrderId |-> [i \in 1 .. 14 |-> 0],
      rejectReason            |-> [i \in 1 .. 1 |-> 0] ]

(* Rejected Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectedOrderMessage ==
    { ZeroRejectedOrderMessage }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.orderTokenClientOrderId = one] : one \in Sample(14) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.rejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Executed Order Message: 40 bytes                                        *)
(***************************************************************************)

ExecutedOrderMessage ==
    [ orderTokenClientOrderId : Sample(14),
      shares                  : Sample(6),
      price                   : Sample(10),
      liquidity               : Sample(1),
      matchNumber             : Sample(9) ]

EncodeExecutedOrderMessage(message) ==
    message.orderTokenClientOrderId
        \o message.shares
        \o message.price
        \o message.liquidity
        \o message.matchNumber

DecodeExecutedOrderMessage(bytes) ==
    LET orderTokenClientOrderId == ReadBytes(bytes, 14) IN IF ~orderTokenClientOrderId.ok THEN Fail ELSE
    LET shares == ReadBytes(orderTokenClientOrderId.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET liquidity == ReadBytes(price.rest, 1) IN IF ~liquidity.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(liquidity.rest, 9) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ orderTokenClientOrderId |-> orderTokenClientOrderId.value,
         shares                  |-> shares.value,
         price                   |-> price.value,
         liquidity               |-> liquidity.value,
         matchNumber             |-> matchNumber.value ], matchNumber.rest)

ZeroExecutedOrderMessage ==
    [ orderTokenClientOrderId |-> [i \in 1 .. 14 |-> 0],
      shares                  |-> [i \in 1 .. 6 |-> 0],
      price                   |-> [i \in 1 .. 10 |-> 0],
      liquidity               |-> [i \in 1 .. 1 |-> 0],
      matchNumber             |-> [i \in 1 .. 9 |-> 0] ]

(* Executed Order Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutedOrderMessage ==
    { ZeroExecutedOrderMessage }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.orderTokenClientOrderId = one] : one \in Sample(14) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.liquidity = one] : one \in Sample(1) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.matchNumber = one] : one \in Sample(9) }

(***************************************************************************)
(* Broken Trade Message: 24 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ orderToken        : Sample(14),
      matchNumber       : Sample(9),
      brokenTradeReason : Sample(1) ]

EncodeBrokenTradeMessage(message) ==
    message.orderToken
        \o message.matchNumber
        \o message.brokenTradeReason

DecodeBrokenTradeMessage(bytes) ==
    LET orderToken == ReadBytes(bytes, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(orderToken.rest, 9) IN IF ~matchNumber.ok THEN Fail ELSE
    LET brokenTradeReason == ReadBytes(matchNumber.rest, 1) IN IF ~brokenTradeReason.ok THEN Fail ELSE
    Ok([ orderToken        |-> orderToken.value,
         matchNumber       |-> matchNumber.value,
         brokenTradeReason |-> brokenTradeReason.value ], brokenTradeReason.rest)

ZeroBrokenTradeMessage ==
    [ orderToken        |-> [i \in 1 .. 14 |-> 0],
      matchNumber       |-> [i \in 1 .. 9 |-> 0],
      brokenTradeReason |-> [i \in 1 .. 1 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(9) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.brokenTradeReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
AcceptedOrderMessageCode == 65  \* "A"
AcceptedOrderMessageWithCrossFunctionalityCode == 82  \* "R"
CanceledOrderMessageCode == 67  \* "C"
RejectedOrderMessageCode == 74  \* "J"
ExecutedOrderMessageCode == 69  \* "E"
BrokenTradeMessageCode == 66  \* "B"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {AcceptedOrderMessageCode}, body : AcceptedOrderMessage ]
        \cup [ tag : {AcceptedOrderMessageWithCrossFunctionalityCode}, body : AcceptedOrderMessageWithCrossFunctionality ]
        \cup [ tag : {CanceledOrderMessageCode}, body : CanceledOrderMessage ]
        \cup [ tag : {RejectedOrderMessageCode}, body : RejectedOrderMessage ]
        \cup [ tag : {ExecutedOrderMessageCode}, body : ExecutedOrderMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = AcceptedOrderMessageCode -> EncodeAcceptedOrderMessage(message.body)
      [] message.tag = AcceptedOrderMessageWithCrossFunctionalityCode -> EncodeAcceptedOrderMessageWithCrossFunctionality(message.body)
      [] message.tag = CanceledOrderMessageCode -> EncodeCanceledOrderMessage(message.body)
      [] message.tag = RejectedOrderMessageCode -> EncodeRejectedOrderMessage(message.body)
      [] message.tag = ExecutedOrderMessageCode -> EncodeExecutedOrderMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = AcceptedOrderMessageCode -> DecodeAcceptedOrderMessage(bytes)
              [] tag = AcceptedOrderMessageWithCrossFunctionalityCode -> DecodeAcceptedOrderMessageWithCrossFunctionality(bytes)
              [] tag = CanceledOrderMessageCode -> DecodeCanceledOrderMessage(bytes)
              [] tag = RejectedOrderMessageCode -> DecodeRejectedOrderMessage(bytes)
              [] tag = ExecutedOrderMessageCode -> DecodeExecutedOrderMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> AcceptedOrderMessageCode, body |-> one] : one \in CheckedAcceptedOrderMessage }
        \cup { [tag |-> AcceptedOrderMessageWithCrossFunctionalityCode, body |-> one] : one \in CheckedAcceptedOrderMessageWithCrossFunctionality }
        \cup { [tag |-> CanceledOrderMessageCode, body |-> one] : one \in CheckedCanceledOrderMessage }
        \cup { [tag |-> RejectedOrderMessageCode, body |-> one] : one \in CheckedRejectedOrderMessage }
        \cup { [tag |-> ExecutedOrderMessageCode, body |-> one] : one \in CheckedExecutedOrderMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ timestamp        : Sample(8),
      sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    message.timestamp
        \o EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET sequencedMessageType == ReadUIntBE(timestamp.rest, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Accepted Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAcceptedOrderMessage ==
    \A message \in CheckedAcceptedOrderMessage :
        LET read == DecodeAcceptedOrderMessage(EncodeAcceptedOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Accepted Order Message With Cross Functionality decodes back to what was encoded, and leaves nothing over *)
RoundTripAcceptedOrderMessageWithCrossFunctionality ==
    \A message \in CheckedAcceptedOrderMessageWithCrossFunctionality :
        LET read == DecodeAcceptedOrderMessageWithCrossFunctionality(EncodeAcceptedOrderMessageWithCrossFunctionality(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Canceled Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCanceledOrderMessage ==
    \A message \in CheckedCanceledOrderMessage :
        LET read == DecodeCanceledOrderMessage(EncodeCanceledOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rejected Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectedOrderMessage ==
    \A message \in CheckedRejectedOrderMessage :
        LET read == DecodeRejectedOrderMessage(EncodeRejectedOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executed Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutedOrderMessage ==
    \A message \in CheckedExecutedOrderMessage :
        LET read == DecodeExecutedOrderMessage(EncodeExecutedOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
