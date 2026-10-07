------------------- MODULE PsxEquities_Rash_v1_1_Client --------------------
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
(* Note: Unsequenced Data Packet fills what is left of the frame Packet    *)
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
(* Login Request Packet: 46 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(20) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 20) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Enter Order Message: 140 bytes                                          *)
(***************************************************************************)

EnterOrderMessage ==
    [ orderTokenClientOrderId     : Sample(14),
      side                        : Sample(1),
      sharesOrderQty              : Sample(6),
      stockSymbol                 : Sample(8),
      price                       : Sample(10),
      timeInForce                 : Sample(5),
      firmClientId                : Sample(4),
      display                     : Sample(1),
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
      customerType                : Sample(1),
      tradeNow                    : Sample(1) ]

EncodeEnterOrderMessage(message) ==
    message.orderTokenClientOrderId
        \o message.side
        \o message.sharesOrderQty
        \o message.stockSymbol
        \o message.price
        \o message.timeInForce
        \o message.firmClientId
        \o message.display
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
        \o message.customerType
        \o message.tradeNow

DecodeEnterOrderMessage(bytes) ==
    LET orderTokenClientOrderId == ReadBytes(bytes, 14) IN IF ~orderTokenClientOrderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderTokenClientOrderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sharesOrderQty == ReadBytes(side.rest, 6) IN IF ~sharesOrderQty.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(sharesOrderQty.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET price == ReadBytes(stockSymbol.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 5) IN IF ~timeInForce.ok THEN Fail ELSE
    LET firmClientId == ReadBytes(timeInForce.rest, 4) IN IF ~firmClientId.ok THEN Fail ELSE
    LET display == ReadBytes(firmClientId.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET minQty == ReadBytes(display.rest, 6) IN IF ~minQty.ok THEN Fail ELSE
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
    LET customerType == ReadBytes(custTerminalIdSenderSubId.rest, 1) IN IF ~customerType.ok THEN Fail ELSE
    LET tradeNow == ReadBytes(customerType.rest, 1) IN IF ~tradeNow.ok THEN Fail ELSE
    Ok([ orderTokenClientOrderId     |-> orderTokenClientOrderId.value,
         side                        |-> side.value,
         sharesOrderQty              |-> sharesOrderQty.value,
         stockSymbol                 |-> stockSymbol.value,
         price                       |-> price.value,
         timeInForce                 |-> timeInForce.value,
         firmClientId                |-> firmClientId.value,
         display                     |-> display.value,
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
         customerType                |-> customerType.value,
         tradeNow                    |-> tradeNow.value ], tradeNow.rest)

ZeroEnterOrderMessage ==
    [ orderTokenClientOrderId     |-> [i \in 1 .. 14 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      sharesOrderQty              |-> [i \in 1 .. 6 |-> 0],
      stockSymbol                 |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 10 |-> 0],
      timeInForce                 |-> [i \in 1 .. 5 |-> 0],
      firmClientId                |-> [i \in 1 .. 4 |-> 0],
      display                     |-> [i \in 1 .. 1 |-> 0],
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
      customerType                |-> [i \in 1 .. 1 |-> 0],
      tradeNow                    |-> [i \in 1 .. 1 |-> 0] ]

(* Enter Order Message at zero, then each field in turn at the values it is checked at *)
CheckedEnterOrderMessage ==
    { ZeroEnterOrderMessage }
        \cup { [ZeroEnterOrderMessage EXCEPT !.orderTokenClientOrderId = one] : one \in Sample(14) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.sharesOrderQty = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(5) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.firmClientId = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.minQty = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.maxFloor = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.pegType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.pegDifferenceSign = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.pegDifference = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.discretionPrice = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.discretionPegType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.discretionPegDifferenceSign = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.discretionPegDifference = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.capacityRule80AIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.randomReserve = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.routeDestExecBroker = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.custTerminalIdSenderSubId = one] : one \in Sample(32) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.customerType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.tradeNow = one] : one \in Sample(1) }

(***************************************************************************)
(* Enter Order Message With Cross Functionality: 142 bytes                 *)
(***************************************************************************)

EnterOrderMessageWithCrossFunctionality ==
    [ orderTokenClientOrderId     : Sample(14),
      side                        : Sample(1),
      sharesOrderQty              : Sample(6),
      stockSymbol                 : Sample(8),
      price                       : Sample(10),
      timeInForce                 : Sample(5),
      firmClientId                : Sample(4),
      display                     : Sample(1),
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
      crossType                   : Sample(1),
      customerType                : Sample(1),
      tradeNow                    : Sample(1) ]

EncodeEnterOrderMessageWithCrossFunctionality(message) ==
    message.orderTokenClientOrderId
        \o message.side
        \o message.sharesOrderQty
        \o message.stockSymbol
        \o message.price
        \o message.timeInForce
        \o message.firmClientId
        \o message.display
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
        \o message.customerType
        \o message.tradeNow

DecodeEnterOrderMessageWithCrossFunctionality(bytes) ==
    LET orderTokenClientOrderId == ReadBytes(bytes, 14) IN IF ~orderTokenClientOrderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderTokenClientOrderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sharesOrderQty == ReadBytes(side.rest, 6) IN IF ~sharesOrderQty.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(sharesOrderQty.rest, 8) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET price == ReadBytes(stockSymbol.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 5) IN IF ~timeInForce.ok THEN Fail ELSE
    LET firmClientId == ReadBytes(timeInForce.rest, 4) IN IF ~firmClientId.ok THEN Fail ELSE
    LET display == ReadBytes(firmClientId.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET minQty == ReadBytes(display.rest, 6) IN IF ~minQty.ok THEN Fail ELSE
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
    LET customerType == ReadBytes(crossType.rest, 1) IN IF ~customerType.ok THEN Fail ELSE
    LET tradeNow == ReadBytes(customerType.rest, 1) IN IF ~tradeNow.ok THEN Fail ELSE
    Ok([ orderTokenClientOrderId     |-> orderTokenClientOrderId.value,
         side                        |-> side.value,
         sharesOrderQty              |-> sharesOrderQty.value,
         stockSymbol                 |-> stockSymbol.value,
         price                       |-> price.value,
         timeInForce                 |-> timeInForce.value,
         firmClientId                |-> firmClientId.value,
         display                     |-> display.value,
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
         crossType                   |-> crossType.value,
         customerType                |-> customerType.value,
         tradeNow                    |-> tradeNow.value ], tradeNow.rest)

ZeroEnterOrderMessageWithCrossFunctionality ==
    [ orderTokenClientOrderId     |-> [i \in 1 .. 14 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      sharesOrderQty              |-> [i \in 1 .. 6 |-> 0],
      stockSymbol                 |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 10 |-> 0],
      timeInForce                 |-> [i \in 1 .. 5 |-> 0],
      firmClientId                |-> [i \in 1 .. 4 |-> 0],
      display                     |-> [i \in 1 .. 1 |-> 0],
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
      crossType                   |-> [i \in 1 .. 1 |-> 0],
      customerType                |-> [i \in 1 .. 1 |-> 0],
      tradeNow                    |-> [i \in 1 .. 1 |-> 0] ]

(* Enter Order Message With Cross Functionality at zero, then each field in turn at the values it is checked at *)
CheckedEnterOrderMessageWithCrossFunctionality ==
    { ZeroEnterOrderMessageWithCrossFunctionality }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.orderTokenClientOrderId = one] : one \in Sample(14) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.sharesOrderQty = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.stockSymbol = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.timeInForce = one] : one \in Sample(5) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.firmClientId = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.minQty = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.maxFloor = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.pegType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.pegDifferenceSign = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.pegDifference = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.discretionPrice = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.discretionPegType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.discretionPegDifferenceSign = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.discretionPegDifference = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.capacityRule80AIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.randomReserve = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.routeDestExecBroker = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.custTerminalIdSenderSubId = one] : one \in Sample(32) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.intermarketSweepEligibility = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.customerType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessageWithCrossFunctionality EXCEPT !.tradeNow = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Order Message: 20 bytes                                          *)
(***************************************************************************)

CancelOrderMessage ==
    [ orderTokenClientOrderId : Sample(14),
      shares                  : Sample(6) ]

EncodeCancelOrderMessage(message) ==
    message.orderTokenClientOrderId
        \o message.shares

DecodeCancelOrderMessage(bytes) ==
    LET orderTokenClientOrderId == ReadBytes(bytes, 14) IN IF ~orderTokenClientOrderId.ok THEN Fail ELSE
    LET shares == ReadBytes(orderTokenClientOrderId.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    Ok([ orderTokenClientOrderId |-> orderTokenClientOrderId.value,
         shares                  |-> shares.value ], shares.rest)

ZeroCancelOrderMessage ==
    [ orderTokenClientOrderId |-> [i \in 1 .. 14 |-> 0],
      shares                  |-> [i \in 1 .. 6 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.orderTokenClientOrderId = one] : one \in Sample(14) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.shares = one] : one \in Sample(6) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

EnterOrderMessageCode == 79  \* "O"
EnterOrderMessageWithCrossFunctionalityCode == 81  \* "Q"
CancelOrderMessageCode == 88  \* "X"

UnsequencedMessage ==
    [ tag : {EnterOrderMessageCode}, body : EnterOrderMessage ]
        \cup [ tag : {EnterOrderMessageWithCrossFunctionalityCode}, body : EnterOrderMessageWithCrossFunctionality ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = EnterOrderMessageCode -> EncodeEnterOrderMessage(message.body)
      [] message.tag = EnterOrderMessageWithCrossFunctionalityCode -> EncodeEnterOrderMessageWithCrossFunctionality(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = EnterOrderMessageCode -> DecodeEnterOrderMessage(bytes)
              [] tag = EnterOrderMessageWithCrossFunctionalityCode -> DecodeEnterOrderMessageWithCrossFunctionality(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> EnterOrderMessageCode, body |-> ZeroEnterOrderMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> EnterOrderMessageCode, body |-> one] : one \in CheckedEnterOrderMessage }
        \cup { [tag |-> EnterOrderMessageWithCrossFunctionalityCode, body |-> one] : one \in CheckedEnterOrderMessageWithCrossFunctionality }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Payload, selected by Client Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"
ClientHeartbeatCode == 82  \* "R"
LogoutRequestCode == 79  \* "O"

ClientPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]

EncodeClientPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = LogoutRequestCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Client Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ClientSoupBinTcpPacket ==
    [ clientPayload : ClientPayload ]

EncodeClientSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSoupBinTcpPacket(message) ==
    LET body == EncodeClientSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeClientSoupBinTcpPacketBody(bytes) ==
    LET clientPacketType == ReadUIntBE(bytes, 1) IN IF ~clientPacketType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(clientPacketType.value, clientPacketType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSoupBinTcpPacket ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientSoupBinTcpPacket ==
    { ZeroClientSoupBinTcpPacket }
        \cup { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeClientSoupBinTcpPacketList(_)
EncodeClientSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSoupBinTcpPacket(Head(messages)) \o EncodeClientSoupBinTcpPacketList(Tail(messages))

(* As many Client Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSoupBinTcpPacketAll(_)
ReadClientSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneClientSoupBinTcpPacket ==
    { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSoupBinTcpPacket : SampleLists(OneClientSoupBinTcpPacket) ]

EncodeClientPacket(message) ==
    EncodeClientSoupBinTcpPacketList(message.clientSoupBinTcpPacket)

DecodeClientPacket(bytes) ==
    LET clientSoupBinTcpPacket == ReadClientSoupBinTcpPacketAll(bytes) IN IF ~clientSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ clientSoupBinTcpPacket |-> clientSoupBinTcpPacket.value ], clientSoupBinTcpPacket.rest)

ZeroClientPacket ==
    [ clientSoupBinTcpPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSoupBinTcpPacket = one] : one \in SampleLists(OneClientSoupBinTcpPacket) }

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

(* Every Login Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestPacket ==
    \A message \in CheckedLoginRequestPacket :
        LET read == DecodeLoginRequestPacket(EncodeLoginRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterOrderMessage ==
    \A message \in CheckedEnterOrderMessage :
        LET read == DecodeEnterOrderMessage(EncodeEnterOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Order Message With Cross Functionality decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterOrderMessageWithCrossFunctionality ==
    \A message \in CheckedEnterOrderMessageWithCrossFunctionality :
        LET read == DecodeEnterOrderMessageWithCrossFunctionality(EncodeEnterOrderMessageWithCrossFunctionality(message))
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

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET read == DecodeClientSoupBinTcpPacket(EncodeClientSoupBinTcpPacket(message))
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

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(message.tag, EncodeUnsequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Payload is selected by the Client Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET bytes == EncodeClientSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
