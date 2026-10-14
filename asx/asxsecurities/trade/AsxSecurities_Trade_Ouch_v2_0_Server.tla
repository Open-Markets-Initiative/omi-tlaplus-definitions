--------------- MODULE AsxSecurities_Trade_Ouch_v2_0_Server ----------------
(***************************************************************************)
(* Australian Securities Exchange Asx Trade v2.0                           *)
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
(* Note: Match Attributes is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: a Server Soup Bin Tcp Packet that ends the session is the last of *)
(* its Server Packet: nothing may follow it.                               *)
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
(* Order Accepted Message: 173 bytes                                       *)
(***************************************************************************)

OrderAcceptedMessage ==
    [ timestampNanoseconds      : Sample(8),
      orderToken                : Sample(14),
      orderBookId               : Sample(4),
      side                      : Sample(1),
      orderId                   : Sample(8),
      quantity                  : Sample(8),
      price                     : Sample(4),
      timeInForce               : Sample(1),
      openClose                 : Sample(1),
      clientAccount             : Sample(10),
      orderState                : Sample(1),
      customerInfo              : Sample(15),
      exchangeInfo              : Sample(32),
      clearingParticipant       : Sample(1),
      crossingKey               : Sample(4),
      capacityOfParticipant     : Sample(1),
      directedWholesale         : Sample(1),
      executionVenue            : Sample(4),
      intermediaryId            : Sample(10),
      orderOrigin               : Sample(20),
      filler                    : Sample(8),
      ouchOrderType             : Sample(1),
      shortSellQuantity         : Sample(8),
      minimumAcceptableQuantity : Sample(8) ]

EncodeOrderAcceptedMessage(message) ==
    message.timestampNanoseconds
        \o message.orderToken
        \o message.orderBookId
        \o message.side
        \o message.orderId
        \o message.quantity
        \o message.price
        \o message.timeInForce
        \o message.openClose
        \o message.clientAccount
        \o message.orderState
        \o message.customerInfo
        \o message.exchangeInfo
        \o message.clearingParticipant
        \o message.crossingKey
        \o message.capacityOfParticipant
        \o message.directedWholesale
        \o message.executionVenue
        \o message.intermediaryId
        \o message.orderOrigin
        \o message.filler
        \o message.ouchOrderType
        \o message.shortSellQuantity
        \o message.minimumAcceptableQuantity

DecodeOrderAcceptedMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 8) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestampNanoseconds.rest, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderToken.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET openClose == ReadBytes(timeInForce.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccount == ReadBytes(openClose.rest, 10) IN IF ~clientAccount.ok THEN Fail ELSE
    LET orderState == ReadBytes(clientAccount.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET customerInfo == ReadBytes(orderState.rest, 15) IN IF ~customerInfo.ok THEN Fail ELSE
    LET exchangeInfo == ReadBytes(customerInfo.rest, 32) IN IF ~exchangeInfo.ok THEN Fail ELSE
    LET clearingParticipant == ReadBytes(exchangeInfo.rest, 1) IN IF ~clearingParticipant.ok THEN Fail ELSE
    LET crossingKey == ReadBytes(clearingParticipant.rest, 4) IN IF ~crossingKey.ok THEN Fail ELSE
    LET capacityOfParticipant == ReadBytes(crossingKey.rest, 1) IN IF ~capacityOfParticipant.ok THEN Fail ELSE
    LET directedWholesale == ReadBytes(capacityOfParticipant.rest, 1) IN IF ~directedWholesale.ok THEN Fail ELSE
    LET executionVenue == ReadBytes(directedWholesale.rest, 4) IN IF ~executionVenue.ok THEN Fail ELSE
    LET intermediaryId == ReadBytes(executionVenue.rest, 10) IN IF ~intermediaryId.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(intermediaryId.rest, 20) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET filler == ReadBytes(orderOrigin.rest, 8) IN IF ~filler.ok THEN Fail ELSE
    LET ouchOrderType == ReadBytes(filler.rest, 1) IN IF ~ouchOrderType.ok THEN Fail ELSE
    LET shortSellQuantity == ReadBytes(ouchOrderType.rest, 8) IN IF ~shortSellQuantity.ok THEN Fail ELSE
    LET minimumAcceptableQuantity == ReadBytes(shortSellQuantity.rest, 8) IN IF ~minimumAcceptableQuantity.ok THEN Fail ELSE
    Ok([ timestampNanoseconds      |-> timestampNanoseconds.value,
         orderToken                |-> orderToken.value,
         orderBookId               |-> orderBookId.value,
         side                      |-> side.value,
         orderId                   |-> orderId.value,
         quantity                  |-> quantity.value,
         price                     |-> price.value,
         timeInForce               |-> timeInForce.value,
         openClose                 |-> openClose.value,
         clientAccount             |-> clientAccount.value,
         orderState                |-> orderState.value,
         customerInfo              |-> customerInfo.value,
         exchangeInfo              |-> exchangeInfo.value,
         clearingParticipant       |-> clearingParticipant.value,
         crossingKey               |-> crossingKey.value,
         capacityOfParticipant     |-> capacityOfParticipant.value,
         directedWholesale         |-> directedWholesale.value,
         executionVenue            |-> executionVenue.value,
         intermediaryId            |-> intermediaryId.value,
         orderOrigin               |-> orderOrigin.value,
         filler                    |-> filler.value,
         ouchOrderType             |-> ouchOrderType.value,
         shortSellQuantity         |-> shortSellQuantity.value,
         minimumAcceptableQuantity |-> minimumAcceptableQuantity.value ], minimumAcceptableQuantity.rest)

ZeroOrderAcceptedMessage ==
    [ timestampNanoseconds      |-> [i \in 1 .. 8 |-> 0],
      orderToken                |-> [i \in 1 .. 14 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      quantity                  |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 4 |-> 0],
      timeInForce               |-> [i \in 1 .. 1 |-> 0],
      openClose                 |-> [i \in 1 .. 1 |-> 0],
      clientAccount             |-> [i \in 1 .. 10 |-> 0],
      orderState                |-> [i \in 1 .. 1 |-> 0],
      customerInfo              |-> [i \in 1 .. 15 |-> 0],
      exchangeInfo              |-> [i \in 1 .. 32 |-> 0],
      clearingParticipant       |-> [i \in 1 .. 1 |-> 0],
      crossingKey               |-> [i \in 1 .. 4 |-> 0],
      capacityOfParticipant     |-> [i \in 1 .. 1 |-> 0],
      directedWholesale         |-> [i \in 1 .. 1 |-> 0],
      executionVenue            |-> [i \in 1 .. 4 |-> 0],
      intermediaryId            |-> [i \in 1 .. 10 |-> 0],
      orderOrigin               |-> [i \in 1 .. 20 |-> 0],
      filler                    |-> [i \in 1 .. 8 |-> 0],
      ouchOrderType             |-> [i \in 1 .. 1 |-> 0],
      shortSellQuantity         |-> [i \in 1 .. 8 |-> 0],
      minimumAcceptableQuantity |-> [i \in 1 .. 8 |-> 0] ]

(* Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcceptedMessage ==
    { ZeroOrderAcceptedMessage }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.clientAccount = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.customerInfo = one] : one \in Sample(15) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.exchangeInfo = one] : one \in Sample(32) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.clearingParticipant = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.crossingKey = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.capacityOfParticipant = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.directedWholesale = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.executionVenue = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.intermediaryId = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderOrigin = one] : one \in Sample(20) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.filler = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.ouchOrderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.shortSellQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.minimumAcceptableQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Rejected Message: 26 bytes                                        *)
(***************************************************************************)

OrderRejectedMessage ==
    [ timestampNanoseconds : Sample(8),
      orderToken           : Sample(14),
      rejectCode           : Sample(4) ]

EncodeOrderRejectedMessage(message) ==
    message.timestampNanoseconds
        \o message.orderToken
        \o message.rejectCode

DecodeOrderRejectedMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 8) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestampNanoseconds.rest, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(orderToken.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderToken           |-> orderToken.value,
         rejectCode           |-> rejectCode.value ], rejectCode.rest)

ZeroOrderRejectedMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 8 |-> 0],
      orderToken           |-> [i \in 1 .. 14 |-> 0],
      rejectCode           |-> [i \in 1 .. 4 |-> 0] ]

(* Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectedMessage ==
    { ZeroOrderRejectedMessage }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroOrderRejectedMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Replaced Message: 187 bytes                                       *)
(***************************************************************************)

OrderReplacedMessage ==
    [ timestampNanoseconds      : Sample(8),
      replacementOrderToken     : Sample(14),
      previousOrderToken        : Sample(14),
      orderBookId               : Sample(4),
      side                      : Sample(1),
      orderId                   : Sample(8),
      quantity                  : Sample(8),
      price                     : Sample(4),
      timeInForce               : Sample(1),
      openClose                 : Sample(1),
      clientAccount             : Sample(10),
      orderState                : Sample(1),
      customerInfo              : Sample(15),
      exchangeInfo              : Sample(32),
      clearingParticipant       : Sample(1),
      crossingKey               : Sample(4),
      capacityOfParticipant     : Sample(1),
      directedWholesale         : Sample(1),
      executionVenue            : Sample(4),
      intermediaryId            : Sample(10),
      orderOrigin               : Sample(20),
      filler                    : Sample(8),
      ouchOrderType             : Sample(1),
      shortSellQuantity         : Sample(8),
      minimumAcceptableQuantity : Sample(8) ]

EncodeOrderReplacedMessage(message) ==
    message.timestampNanoseconds
        \o message.replacementOrderToken
        \o message.previousOrderToken
        \o message.orderBookId
        \o message.side
        \o message.orderId
        \o message.quantity
        \o message.price
        \o message.timeInForce
        \o message.openClose
        \o message.clientAccount
        \o message.orderState
        \o message.customerInfo
        \o message.exchangeInfo
        \o message.clearingParticipant
        \o message.crossingKey
        \o message.capacityOfParticipant
        \o message.directedWholesale
        \o message.executionVenue
        \o message.intermediaryId
        \o message.orderOrigin
        \o message.filler
        \o message.ouchOrderType
        \o message.shortSellQuantity
        \o message.minimumAcceptableQuantity

DecodeOrderReplacedMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 8) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET replacementOrderToken == ReadBytes(timestampNanoseconds.rest, 14) IN IF ~replacementOrderToken.ok THEN Fail ELSE
    LET previousOrderToken == ReadBytes(replacementOrderToken.rest, 14) IN IF ~previousOrderToken.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(previousOrderToken.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET openClose == ReadBytes(timeInForce.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET clientAccount == ReadBytes(openClose.rest, 10) IN IF ~clientAccount.ok THEN Fail ELSE
    LET orderState == ReadBytes(clientAccount.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET customerInfo == ReadBytes(orderState.rest, 15) IN IF ~customerInfo.ok THEN Fail ELSE
    LET exchangeInfo == ReadBytes(customerInfo.rest, 32) IN IF ~exchangeInfo.ok THEN Fail ELSE
    LET clearingParticipant == ReadBytes(exchangeInfo.rest, 1) IN IF ~clearingParticipant.ok THEN Fail ELSE
    LET crossingKey == ReadBytes(clearingParticipant.rest, 4) IN IF ~crossingKey.ok THEN Fail ELSE
    LET capacityOfParticipant == ReadBytes(crossingKey.rest, 1) IN IF ~capacityOfParticipant.ok THEN Fail ELSE
    LET directedWholesale == ReadBytes(capacityOfParticipant.rest, 1) IN IF ~directedWholesale.ok THEN Fail ELSE
    LET executionVenue == ReadBytes(directedWholesale.rest, 4) IN IF ~executionVenue.ok THEN Fail ELSE
    LET intermediaryId == ReadBytes(executionVenue.rest, 10) IN IF ~intermediaryId.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(intermediaryId.rest, 20) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET filler == ReadBytes(orderOrigin.rest, 8) IN IF ~filler.ok THEN Fail ELSE
    LET ouchOrderType == ReadBytes(filler.rest, 1) IN IF ~ouchOrderType.ok THEN Fail ELSE
    LET shortSellQuantity == ReadBytes(ouchOrderType.rest, 8) IN IF ~shortSellQuantity.ok THEN Fail ELSE
    LET minimumAcceptableQuantity == ReadBytes(shortSellQuantity.rest, 8) IN IF ~minimumAcceptableQuantity.ok THEN Fail ELSE
    Ok([ timestampNanoseconds      |-> timestampNanoseconds.value,
         replacementOrderToken     |-> replacementOrderToken.value,
         previousOrderToken        |-> previousOrderToken.value,
         orderBookId               |-> orderBookId.value,
         side                      |-> side.value,
         orderId                   |-> orderId.value,
         quantity                  |-> quantity.value,
         price                     |-> price.value,
         timeInForce               |-> timeInForce.value,
         openClose                 |-> openClose.value,
         clientAccount             |-> clientAccount.value,
         orderState                |-> orderState.value,
         customerInfo              |-> customerInfo.value,
         exchangeInfo              |-> exchangeInfo.value,
         clearingParticipant       |-> clearingParticipant.value,
         crossingKey               |-> crossingKey.value,
         capacityOfParticipant     |-> capacityOfParticipant.value,
         directedWholesale         |-> directedWholesale.value,
         executionVenue            |-> executionVenue.value,
         intermediaryId            |-> intermediaryId.value,
         orderOrigin               |-> orderOrigin.value,
         filler                    |-> filler.value,
         ouchOrderType             |-> ouchOrderType.value,
         shortSellQuantity         |-> shortSellQuantity.value,
         minimumAcceptableQuantity |-> minimumAcceptableQuantity.value ], minimumAcceptableQuantity.rest)

ZeroOrderReplacedMessage ==
    [ timestampNanoseconds      |-> [i \in 1 .. 8 |-> 0],
      replacementOrderToken     |-> [i \in 1 .. 14 |-> 0],
      previousOrderToken        |-> [i \in 1 .. 14 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      quantity                  |-> [i \in 1 .. 8 |-> 0],
      price                     |-> [i \in 1 .. 4 |-> 0],
      timeInForce               |-> [i \in 1 .. 1 |-> 0],
      openClose                 |-> [i \in 1 .. 1 |-> 0],
      clientAccount             |-> [i \in 1 .. 10 |-> 0],
      orderState                |-> [i \in 1 .. 1 |-> 0],
      customerInfo              |-> [i \in 1 .. 15 |-> 0],
      exchangeInfo              |-> [i \in 1 .. 32 |-> 0],
      clearingParticipant       |-> [i \in 1 .. 1 |-> 0],
      crossingKey               |-> [i \in 1 .. 4 |-> 0],
      capacityOfParticipant     |-> [i \in 1 .. 1 |-> 0],
      directedWholesale         |-> [i \in 1 .. 1 |-> 0],
      executionVenue            |-> [i \in 1 .. 4 |-> 0],
      intermediaryId            |-> [i \in 1 .. 10 |-> 0],
      orderOrigin               |-> [i \in 1 .. 20 |-> 0],
      filler                    |-> [i \in 1 .. 8 |-> 0],
      ouchOrderType             |-> [i \in 1 .. 1 |-> 0],
      shortSellQuantity         |-> [i \in 1 .. 8 |-> 0],
      minimumAcceptableQuantity |-> [i \in 1 .. 8 |-> 0] ]

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.replacementOrderToken = one] : one \in Sample(14) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.previousOrderToken = one] : one \in Sample(14) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.clientAccount = one] : one \in Sample(10) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.customerInfo = one] : one \in Sample(15) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.exchangeInfo = one] : one \in Sample(32) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.clearingParticipant = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.crossingKey = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.capacityOfParticipant = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.directedWholesale = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.executionVenue = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.intermediaryId = one] : one \in Sample(10) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderOrigin = one] : one \in Sample(20) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.filler = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.ouchOrderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.shortSellQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.minimumAcceptableQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancelled Message: 36 bytes                                       *)
(***************************************************************************)

OrderCancelledMessage ==
    [ timestampNanoseconds : Sample(8),
      orderToken           : Sample(14),
      orderBookId          : Sample(4),
      side                 : Sample(1),
      orderId              : Sample(8),
      reason               : Sample(1) ]

EncodeOrderCancelledMessage(message) ==
    message.timestampNanoseconds
        \o message.orderToken
        \o message.orderBookId
        \o message.side
        \o message.orderId
        \o message.reason

DecodeOrderCancelledMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 8) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestampNanoseconds.rest, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderToken.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderId == ReadBytes(side.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET reason == ReadBytes(orderId.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderToken           |-> orderToken.value,
         orderBookId          |-> orderBookId.value,
         side                 |-> side.value,
         orderId              |-> orderId.value,
         reason               |-> reason.value ], reason.rest)

ZeroOrderCancelledMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 8 |-> 0],
      orderToken           |-> [i \in 1 .. 14 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      reason               |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelledMessage ==
    { ZeroOrderCancelledMessage }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelledMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 53 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestampNanoseconds : Sample(8),
      orderToken           : Sample(14),
      orderBookId          : Sample(4),
      tradedQuantity       : Sample(8),
      tradePrice           : Sample(4),
      matchId              : Sample(12),
      dealSource           : Sample(2),
      matchAttributes      : Sample(1) ]

EncodeOrderExecutedMessage(message) ==
    message.timestampNanoseconds
        \o message.orderToken
        \o message.orderBookId
        \o message.tradedQuantity
        \o message.tradePrice
        \o message.matchId
        \o message.dealSource
        \o message.matchAttributes

DecodeOrderExecutedMessage(bytes) ==
    LET timestampNanoseconds == ReadBytes(bytes, 8) IN IF ~timestampNanoseconds.ok THEN Fail ELSE
    LET orderToken == ReadBytes(timestampNanoseconds.rest, 14) IN IF ~orderToken.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderToken.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tradedQuantity == ReadBytes(orderBookId.rest, 8) IN IF ~tradedQuantity.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradedQuantity.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET matchId == ReadBytes(tradePrice.rest, 12) IN IF ~matchId.ok THEN Fail ELSE
    LET dealSource == ReadBytes(matchId.rest, 2) IN IF ~dealSource.ok THEN Fail ELSE
    LET matchAttributes == ReadBytes(dealSource.rest, 1) IN IF ~matchAttributes.ok THEN Fail ELSE
    Ok([ timestampNanoseconds |-> timestampNanoseconds.value,
         orderToken           |-> orderToken.value,
         orderBookId          |-> orderBookId.value,
         tradedQuantity       |-> tradedQuantity.value,
         tradePrice           |-> tradePrice.value,
         matchId              |-> matchId.value,
         dealSource           |-> dealSource.value,
         matchAttributes      |-> matchAttributes.value ], matchAttributes.rest)

ZeroOrderExecutedMessage ==
    [ timestampNanoseconds |-> [i \in 1 .. 8 |-> 0],
      orderToken           |-> [i \in 1 .. 14 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      tradedQuantity       |-> [i \in 1 .. 8 |-> 0],
      tradePrice           |-> [i \in 1 .. 4 |-> 0],
      matchId              |-> [i \in 1 .. 12 |-> 0],
      dealSource           |-> [i \in 1 .. 2 |-> 0],
      matchAttributes      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestampNanoseconds = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderToken = one] : one \in Sample(14) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchId = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.dealSource = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchAttributes = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

OrderAcceptedMessageCode == 65  \* "A"
OrderRejectedMessageCode == 74  \* "J"
OrderReplacedMessageCode == 85  \* "U"
OrderCancelledMessageCode == 67  \* "C"
OrderExecutedMessageCode == 69  \* "E"

SequencedMessage ==
    [ tag : {OrderAcceptedMessageCode}, body : OrderAcceptedMessage ]
        \cup [ tag : {OrderRejectedMessageCode}, body : OrderRejectedMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {OrderCancelledMessageCode}, body : OrderCancelledMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = OrderAcceptedMessageCode -> EncodeOrderAcceptedMessage(message.body)
      [] message.tag = OrderRejectedMessageCode -> EncodeOrderRejectedMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = OrderCancelledMessageCode -> EncodeOrderCancelledMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = OrderAcceptedMessageCode -> DecodeOrderAcceptedMessage(bytes)
              [] tag = OrderRejectedMessageCode -> DecodeOrderRejectedMessage(bytes)
              [] tag = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] tag = OrderCancelledMessageCode -> DecodeOrderCancelledMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> OrderAcceptedMessageCode, body |-> ZeroOrderAcceptedMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> OrderAcceptedMessageCode, body |-> one] : one \in CheckedOrderAcceptedMessage }
        \cup { [tag |-> OrderRejectedMessageCode, body |-> one] : one \in CheckedOrderRejectedMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> OrderCancelledMessageCode, body |-> one] : one \in CheckedOrderCancelledMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
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

(* Does a Server Soup Bin Tcp Packet end the session? Nothing may follow one that does *)
EndsSessionServerSoupBinTcpPacket(message) == message.serverPayload.tag \in {EndOfSessionCode}

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
(* Only the last of them may end the session, so one that does with bytes left fails *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE IF EndsSessionServerSoupBinTcpPacket(one.value) /\ one.rest # << >> THEN Fail
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

(* The runs of Server Soup Bin Tcp Packet checked: none, one, two of a kind and each kind followed by *)
(* another, keeping those in which only the last may end the session *)
SampleServerSoupBinTcpPacketLists ==
    { run \in SampleLists(OneServerSoupBinTcpPacket) \cup { <<one, other>> : one \in OneServerSoupBinTcpPacket, other \in OneServerSoupBinTcpPacket } :
          \A at \in 1 .. Len(run) - 1 : ~EndsSessionServerSoupBinTcpPacket(run[at]) }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleServerSoupBinTcpPacketLists ]

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
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleServerSoupBinTcpPacketLists }

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

(* Every Order Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcceptedMessage ==
    \A message \in CheckedOrderAcceptedMessage :
        LET read == DecodeOrderAcceptedMessage(EncodeOrderAcceptedMessage(message))
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

(* Every Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedMessage ==
    \A message \in CheckedOrderReplacedMessage :
        LET read == DecodeOrderReplacedMessage(EncodeOrderReplacedMessage(message))
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

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
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

(* A Server Soup Bin Tcp Packet that ends the session is the last of its Server Packet: a run with one after it does not decode *)
EndsSessionLastServerSoupBinTcpPacket ==
    \A last \in { one \in OneServerSoupBinTcpPacket : EndsSessionServerSoupBinTcpPacket(one) } :
        \A after \in OneServerSoupBinTcpPacket :
            ~ReadServerSoupBinTcpPacketAll(EncodeServerSoupBinTcpPacketList(<<last, after>>)).ok

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
