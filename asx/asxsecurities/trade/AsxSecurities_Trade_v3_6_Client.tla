------------------ MODULE AsxSecurities_Trade_v3_6_Client ------------------
(***************************************************************************)
(* Australian Securities Exchange Asx Trade v3.6                           *)
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
(* Regulatory Data: 44 bytes                                               *)
(***************************************************************************)

RegulatoryData ==
    [ capacityOfParticipant : Sample(1),
      directedWholesale     : Sample(1),
      executionVenue        : Sample(4),
      intermediaryId        : Sample(10),
      orderOrigin           : Sample(20),
      filler                : Sample(8) ]

EncodeRegulatoryData(message) ==
    message.capacityOfParticipant
        \o message.directedWholesale
        \o message.executionVenue
        \o message.intermediaryId
        \o message.orderOrigin
        \o message.filler

DecodeRegulatoryData(bytes) ==
    LET capacityOfParticipant == ReadBytes(bytes, 1) IN IF ~capacityOfParticipant.ok THEN Fail ELSE
    LET directedWholesale == ReadBytes(capacityOfParticipant.rest, 1) IN IF ~directedWholesale.ok THEN Fail ELSE
    LET executionVenue == ReadBytes(directedWholesale.rest, 4) IN IF ~executionVenue.ok THEN Fail ELSE
    LET intermediaryId == ReadBytes(executionVenue.rest, 10) IN IF ~intermediaryId.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(intermediaryId.rest, 20) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET filler == ReadBytes(orderOrigin.rest, 8) IN IF ~filler.ok THEN Fail ELSE
    Ok([ capacityOfParticipant |-> capacityOfParticipant.value,
         directedWholesale     |-> directedWholesale.value,
         executionVenue        |-> executionVenue.value,
         intermediaryId        |-> intermediaryId.value,
         orderOrigin           |-> orderOrigin.value,
         filler                |-> filler.value ], filler.rest)

ZeroRegulatoryData ==
    [ capacityOfParticipant |-> [i \in 1 .. 1 |-> 0],
      directedWholesale     |-> [i \in 1 .. 1 |-> 0],
      executionVenue        |-> [i \in 1 .. 4 |-> 0],
      intermediaryId        |-> [i \in 1 .. 10 |-> 0],
      orderOrigin           |-> [i \in 1 .. 20 |-> 0],
      filler                |-> [i \in 1 .. 8 |-> 0] ]

(* Regulatory Data at zero, then each field in turn at the values it is checked at *)
CheckedRegulatoryData ==
    { ZeroRegulatoryData }
        \cup { [ZeroRegulatoryData EXCEPT !.capacityOfParticipant = one] : one \in Sample(1) }
        \cup { [ZeroRegulatoryData EXCEPT !.directedWholesale = one] : one \in Sample(1) }
        \cup { [ZeroRegulatoryData EXCEPT !.executionVenue = one] : one \in Sample(4) }
        \cup { [ZeroRegulatoryData EXCEPT !.intermediaryId = one] : one \in Sample(10) }
        \cup { [ZeroRegulatoryData EXCEPT !.orderOrigin = one] : one \in Sample(20) }
        \cup { [ZeroRegulatoryData EXCEPT !.filler = one] : one \in Sample(8) }

(***************************************************************************)
(* Enter Order Message: 156 bytes                                          *)
(***************************************************************************)

EnterOrderMessage ==
    [ orderToken                : Sample(14),
      orderBookId               : Sample(4),
      side                      : Sample(1),
      quantity                  : Sample(8),
      price                     : Sample(4),
      timeInForce               : Sample(1),
      openClose                 : Sample(1),
      clientAccount             : Sample(10),
      customerInfo              : Sample(15),
      exchangeInfo              : Sample(32),
      clearingParticipant       : Sample(1),
      crossingKey               : Sample(4),
      regulatoryData            : RegulatoryData,
      ouchOrderType             : Sample(1),
      shortSellQuantity         : Sample(8),
      minimumAcceptableQuantity : Sample(8) ]

EncodeEnterOrderMessage(message) ==
    message.orderToken
        \o message.orderBookId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.timeInForce
        \o message.openClose
        \o message.clientAccount
        \o message.customerInfo
        \o message.exchangeInfo
        \o message.clearingParticipant
        \o message.crossingKey
        \o EncodeRegulatoryData(message.regulatoryData)
        \o message.ouchOrderType
        \o message.shortSellQuantity
        \o message.minimumAcceptableQuantity

DecodeEnterOrderMessage(bytes) ==
    LET orderToken == ReadBytes(bytes, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderToken.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET openClose == ReadBytes(timeInForce.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccount == ReadBytes(openClose.rest, 10) IN IF ~clientAccount.ok THEN Fail ELSE
    LET customerInfo == ReadBytes(clientAccount.rest, 15) IN IF ~customerInfo.ok THEN Fail ELSE
    LET exchangeInfo == ReadBytes(customerInfo.rest, 32) IN IF ~exchangeInfo.ok THEN Fail ELSE
    LET clearingParticipant == ReadBytes(exchangeInfo.rest, 1) IN IF ~clearingParticipant.ok THEN Fail ELSE
    LET crossingKey == ReadBytes(clearingParticipant.rest, 4) IN IF ~crossingKey.ok THEN Fail ELSE
    LET regulatoryData == DecodeRegulatoryData(crossingKey.rest) IN IF ~regulatoryData.ok THEN Fail ELSE
    LET ouchOrderType == ReadBytes(regulatoryData.rest, 1) IN IF ~ouchOrderType.ok THEN Fail ELSE
    LET shortSellQuantity == ReadBytes(ouchOrderType.rest, 8) IN IF ~shortSellQuantity.ok THEN Fail ELSE
    LET minimumAcceptableQuantity == ReadBytes(shortSellQuantity.rest, 8) IN IF ~minimumAcceptableQuantity.ok THEN Fail ELSE
    Ok([ orderToken                |-> orderToken.value,
         orderBookId               |-> orderBookId.value,
         side                      |-> side.value,
         quantity                  |-> quantity.value,
         price                     |-> price.value,
         timeInForce               |-> timeInForce.value,
         openClose                 |-> openClose.value,
         clientAccount             |-> clientAccount.value,
         customerInfo              |-> customerInfo.value,
         exchangeInfo              |-> exchangeInfo.value,
         clearingParticipant       |-> clearingParticipant.value,
         crossingKey               |-> crossingKey.value,
         regulatoryData            |-> regulatoryData.value,
         ouchOrderType             |-> ouchOrderType.value,
         shortSellQuantity         |-> shortSellQuantity.value,
         minimumAcceptableQuantity |-> minimumAcceptableQuantity.value ], minimumAcceptableQuantity.rest)

ZeroEnterOrderMessage ==
    [ orderToken                |-> [i \in 1 .. 14 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      quantity                  |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 4 |-> 0],
      timeInForce               |-> [i \in 1 .. 1 |-> 0],
      openClose                 |-> [i \in 1 .. 1 |-> 0],
      clientAccount             |-> [i \in 1 .. 10 |-> 0],
      customerInfo              |-> [i \in 1 .. 15 |-> 0],
      exchangeInfo              |-> [i \in 1 .. 32 |-> 0],
      clearingParticipant       |-> [i \in 1 .. 1 |-> 0],
      crossingKey               |-> [i \in 1 .. 4 |-> 0],
      regulatoryData            |-> ZeroRegulatoryData,
      ouchOrderType             |-> [i \in 1 .. 1 |-> 0],
      shortSellQuantity         |-> [i \in 1 .. 8 |-> 0],
      minimumAcceptableQuantity |-> [i \in 1 .. 8 |-> 0] ]

(* Enter Order Message at zero, then each field in turn at the values it is checked at *)
CheckedEnterOrderMessage ==
    { ZeroEnterOrderMessage }
        \cup { [ZeroEnterOrderMessage EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.clientAccount = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.customerInfo = one] : one \in Sample(15) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.exchangeInfo = one] : one \in Sample(32) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.clearingParticipant = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.crossingKey = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.regulatoryData = one] : one \in CheckedRegulatoryData }
        \cup { [ZeroEnterOrderMessage EXCEPT !.ouchOrderType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.shortSellQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.minimumAcceptableQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Regulatory Data: 44 bytes                                               *)
(***************************************************************************)

RegulatoryData2 ==
    [ capacityOfParticipant : Sample(1),
      directedWholesale     : Sample(1),
      executionVenue        : Sample(4),
      intermediaryId        : Sample(10),
      orderOrigin           : Sample(20),
      filler                : Sample(8) ]

EncodeRegulatoryData2(message) ==
    message.capacityOfParticipant
        \o message.directedWholesale
        \o message.executionVenue
        \o message.intermediaryId
        \o message.orderOrigin
        \o message.filler

DecodeRegulatoryData2(bytes) ==
    LET capacityOfParticipant == ReadBytes(bytes, 1) IN IF ~capacityOfParticipant.ok THEN Fail ELSE
    LET directedWholesale == ReadBytes(capacityOfParticipant.rest, 1) IN IF ~directedWholesale.ok THEN Fail ELSE
    LET executionVenue == ReadBytes(directedWholesale.rest, 4) IN IF ~executionVenue.ok THEN Fail ELSE
    LET intermediaryId == ReadBytes(executionVenue.rest, 10) IN IF ~intermediaryId.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(intermediaryId.rest, 20) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET filler == ReadBytes(orderOrigin.rest, 8) IN IF ~filler.ok THEN Fail ELSE
    Ok([ capacityOfParticipant |-> capacityOfParticipant.value,
         directedWholesale     |-> directedWholesale.value,
         executionVenue        |-> executionVenue.value,
         intermediaryId        |-> intermediaryId.value,
         orderOrigin           |-> orderOrigin.value,
         filler                |-> filler.value ], filler.rest)

ZeroRegulatoryData2 ==
    [ capacityOfParticipant |-> [i \in 1 .. 1 |-> 0],
      directedWholesale     |-> [i \in 1 .. 1 |-> 0],
      executionVenue        |-> [i \in 1 .. 4 |-> 0],
      intermediaryId        |-> [i \in 1 .. 10 |-> 0],
      orderOrigin           |-> [i \in 1 .. 20 |-> 0],
      filler                |-> [i \in 1 .. 8 |-> 0] ]

(* Regulatory Data at zero, then each field in turn at the values it is checked at *)
CheckedRegulatoryData2 ==
    { ZeroRegulatoryData2 }
        \cup { [ZeroRegulatoryData2 EXCEPT !.capacityOfParticipant = one] : one \in Sample(1) }
        \cup { [ZeroRegulatoryData2 EXCEPT !.directedWholesale = one] : one \in Sample(1) }
        \cup { [ZeroRegulatoryData2 EXCEPT !.executionVenue = one] : one \in Sample(4) }
        \cup { [ZeroRegulatoryData2 EXCEPT !.intermediaryId = one] : one \in Sample(10) }
        \cup { [ZeroRegulatoryData2 EXCEPT !.orderOrigin = one] : one \in Sample(20) }
        \cup { [ZeroRegulatoryData2 EXCEPT !.filler = one] : one \in Sample(8) }

(***************************************************************************)
(* Replace Order Message: 158 bytes                                        *)
(***************************************************************************)

ReplaceOrderMessage ==
    [ existingOrderToken        : Sample(14),
      replacementOrderToken     : Sample(14),
      quantity                  : Sample(8),
      price                     : Sample(4),
      openClose                 : Sample(1),
      clientAccount             : Sample(10),
      customerInfo              : Sample(15),
      exchangeInfo              : Sample(32),
      regulatoryData            : RegulatoryData2,
      shortSellQuantity         : Sample(8),
      minimumAcceptableQuantity : Sample(8) ]

EncodeReplaceOrderMessage(message) ==
    message.existingOrderToken
        \o message.replacementOrderToken
        \o message.quantity
        \o message.price
        \o message.openClose
        \o message.clientAccount
        \o message.customerInfo
        \o message.exchangeInfo
        \o EncodeRegulatoryData2(message.regulatoryData)
        \o message.shortSellQuantity
        \o message.minimumAcceptableQuantity

DecodeReplaceOrderMessage(bytes) ==
    LET existingOrderToken == ReadBytes(bytes, 14) IN IF ~existingOrderToken.ok THEN Fail ELSE
    LET replacementOrderToken == ReadBytes(existingOrderToken.rest, 14) IN IF ~replacementOrderToken.ok THEN Fail ELSE
    LET quantity == ReadBytes(replacementOrderToken.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET openClose == ReadBytes(price.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccount == ReadBytes(openClose.rest, 10) IN IF ~clientAccount.ok THEN Fail ELSE
    LET customerInfo == ReadBytes(clientAccount.rest, 15) IN IF ~customerInfo.ok THEN Fail ELSE
    LET exchangeInfo == ReadBytes(customerInfo.rest, 32) IN IF ~exchangeInfo.ok THEN Fail ELSE
    LET regulatoryData == DecodeRegulatoryData2(exchangeInfo.rest) IN IF ~regulatoryData.ok THEN Fail ELSE
    LET shortSellQuantity == ReadBytes(regulatoryData.rest, 8) IN IF ~shortSellQuantity.ok THEN Fail ELSE
    LET minimumAcceptableQuantity == ReadBytes(shortSellQuantity.rest, 8) IN IF ~minimumAcceptableQuantity.ok THEN Fail ELSE
    Ok([ existingOrderToken        |-> existingOrderToken.value,
         replacementOrderToken     |-> replacementOrderToken.value,
         quantity                  |-> quantity.value,
         price                     |-> price.value,
         openClose                 |-> openClose.value,
         clientAccount             |-> clientAccount.value,
         customerInfo              |-> customerInfo.value,
         exchangeInfo              |-> exchangeInfo.value,
         regulatoryData            |-> regulatoryData.value,
         shortSellQuantity         |-> shortSellQuantity.value,
         minimumAcceptableQuantity |-> minimumAcceptableQuantity.value ], minimumAcceptableQuantity.rest)

ZeroReplaceOrderMessage ==
    [ existingOrderToken        |-> [i \in 1 .. 14 |-> 0],
      replacementOrderToken     |-> [i \in 1 .. 14 |-> 0],
      quantity                  |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 4 |-> 0],
      openClose                 |-> [i \in 1 .. 1 |-> 0],
      clientAccount             |-> [i \in 1 .. 10 |-> 0],
      customerInfo              |-> [i \in 1 .. 15 |-> 0],
      exchangeInfo              |-> [i \in 1 .. 32 |-> 0],
      regulatoryData            |-> ZeroRegulatoryData2,
      shortSellQuantity         |-> [i \in 1 .. 8 |-> 0],
      minimumAcceptableQuantity |-> [i \in 1 .. 8 |-> 0] ]

(* Replace Order Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderMessage ==
    { ZeroReplaceOrderMessage }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.existingOrderToken = one] : one \in Sample(14) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.replacementOrderToken = one] : one \in Sample(14) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.clientAccount = one] : one \in Sample(10) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.customerInfo = one] : one \in Sample(15) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.exchangeInfo = one] : one \in Sample(32) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.regulatoryData = one] : one \in CheckedRegulatoryData2 }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.shortSellQuantity = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.minimumAcceptableQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Order Message: 14 bytes                                          *)
(***************************************************************************)

CancelOrderMessage ==
    [ orderToken : Sample(14) ]

EncodeCancelOrderMessage(message) ==
    message.orderToken

DecodeCancelOrderMessage(bytes) ==
    LET orderToken == ReadBytes(bytes, 14) IN IF ~orderToken.ok THEN Fail ELSE
    Ok([ orderToken |-> orderToken.value ], orderToken.rest)

ZeroCancelOrderMessage ==
    [ orderToken |-> [i \in 1 .. 14 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.orderToken = one] : one \in Sample(14) }

(***************************************************************************)
(* Cancel By Order Id Message: 13 bytes                                    *)
(***************************************************************************)

CancelByOrderIdMessage ==
    [ orderBookId : Sample(4),
      side        : Sample(1),
      orderId     : Sample(8) ]

EncodeCancelByOrderIdMessage(message) ==
    message.orderBookId
        \o message.side
        \o message.orderId

DecodeCancelByOrderIdMessage(bytes) ==
    LET orderBookId == ReadBytes(bytes, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ orderBookId |-> orderBookId.value,
         side        |-> side.value,
         orderId     |-> orderId.value ], orderId.rest)

ZeroCancelByOrderIdMessage ==
    [ orderBookId |-> [i \in 1 .. 4 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel By Order Id Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelByOrderIdMessage ==
    { ZeroCancelByOrderIdMessage }
        \cup { [ZeroCancelByOrderIdMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCancelByOrderIdMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCancelByOrderIdMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

EnterOrderMessageCode == 79  \* "O"
ReplaceOrderMessageCode == 85  \* "U"
CancelOrderMessageCode == 88  \* "X"
CancelByOrderIdMessageCode == 89  \* "Y"

UnsequencedMessage ==
    [ tag : {EnterOrderMessageCode}, body : EnterOrderMessage ]
        \cup [ tag : {ReplaceOrderMessageCode}, body : ReplaceOrderMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {CancelByOrderIdMessageCode}, body : CancelByOrderIdMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = EnterOrderMessageCode -> EncodeEnterOrderMessage(message.body)
      [] message.tag = ReplaceOrderMessageCode -> EncodeReplaceOrderMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = CancelByOrderIdMessageCode -> EncodeCancelByOrderIdMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = EnterOrderMessageCode -> DecodeEnterOrderMessage(bytes)
              [] tag = ReplaceOrderMessageCode -> DecodeReplaceOrderMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = CancelByOrderIdMessageCode -> DecodeCancelByOrderIdMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> EnterOrderMessageCode, body |-> ZeroEnterOrderMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> EnterOrderMessageCode, body |-> one] : one \in CheckedEnterOrderMessage }
        \cup { [tag |-> ReplaceOrderMessageCode, body |-> one] : one \in CheckedReplaceOrderMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> CancelByOrderIdMessageCode, body |-> one] : one \in CheckedCancelByOrderIdMessage }

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

(* Every Regulatory Data decodes back to what was encoded, and leaves nothing over *)
RoundTripRegulatoryData ==
    \A message \in CheckedRegulatoryData :
        LET read == DecodeRegulatoryData(EncodeRegulatoryData(message))
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

(* Every Regulatory Data decodes back to what was encoded, and leaves nothing over *)
RoundTripRegulatoryData2 ==
    \A message \in CheckedRegulatoryData2 :
        LET read == DecodeRegulatoryData2(EncodeRegulatoryData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replace Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrderMessage ==
    \A message \in CheckedReplaceOrderMessage :
        LET read == DecodeReplaceOrderMessage(EncodeReplaceOrderMessage(message))
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

(* Every Cancel By Order Id Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelByOrderIdMessage ==
    \A message \in CheckedCancelByOrderIdMessage :
        LET read == DecodeCancelByOrderIdMessage(EncodeCancelByOrderIdMessage(message))
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
