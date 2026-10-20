---------------- MODULE CoinbaseDerivatives_OrdersApi_v1_5 -----------------
(***************************************************************************)
(* Coinbase Orders Api v1.5                                                *)
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
(* Note: Flags is a bit field set, checked as its 1 byte rather than bit   *)
(* by bit.                                                                 *)
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
(* Logon Message: 49 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ username    : Sample(16),
      password    : Sample(32),
      resetSeqNum : Sample(1) ]

EncodeLogonMessage(message) ==
    message.username
        \o message.password
        \o message.resetSeqNum

DecodeLogonMessage(bytes) ==
    LET username == ReadBytes(bytes, 16) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET resetSeqNum == ReadBytes(password.rest, 1) IN IF ~resetSeqNum.ok THEN Fail ELSE
    Ok([ username    |-> username.value,
         password    |-> password.value,
         resetSeqNum |-> resetSeqNum.value ], resetSeqNum.rest)

ZeroLogonMessage ==
    [ username    |-> [i \in 1 .. 16 |-> 0],
      password    |-> [i \in 1 .. 32 |-> 0],
      resetSeqNum |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.username = one] : one \in Sample(16) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroLogonMessage EXCEPT !.resetSeqNum = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Conf Message: 4 bytes                                             *)
(***************************************************************************)

LogonConfMessage ==
    [ heartbeatIntervalSeconds : Sample(4) ]

EncodeLogonConfMessage(message) ==
    message.heartbeatIntervalSeconds

DecodeLogonConfMessage(bytes) ==
    LET heartbeatIntervalSeconds == ReadBytes(bytes, 4) IN IF ~heartbeatIntervalSeconds.ok THEN Fail ELSE
    Ok([ heartbeatIntervalSeconds |-> heartbeatIntervalSeconds.value ], heartbeatIntervalSeconds.rest)

ZeroLogonConfMessage ==
    [ heartbeatIntervalSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Conf Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonConfMessage ==
    { ZeroLogonConfMessage }
        \cup { [ZeroLogonConfMessage EXCEPT !.heartbeatIntervalSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Message: 64 bytes                                                *)
(***************************************************************************)

LogoutMessage ==
    [ reason : Sample(64) ]

EncodeLogoutMessage(message) ==
    message.reason

DecodeLogoutMessage(bytes) ==
    LET reason == ReadBytes(bytes, 64) IN IF ~reason.ok THEN Fail ELSE
    Ok([ reason |-> reason.value ], reason.rest)

ZeroLogoutMessage ==
    [ reason |-> [i \in 1 .. 64 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.reason = one] : one \in Sample(64) }

(***************************************************************************)
(* Logged Out Message: 64 bytes                                            *)
(***************************************************************************)

LoggedOutMessage ==
    [ reason : Sample(64) ]

EncodeLoggedOutMessage(message) ==
    message.reason

DecodeLoggedOutMessage(bytes) ==
    LET reason == ReadBytes(bytes, 64) IN IF ~reason.ok THEN Fail ELSE
    Ok([ reason |-> reason.value ], reason.rest)

ZeroLoggedOutMessage ==
    [ reason |-> [i \in 1 .. 64 |-> 0] ]

(* Logged Out Message at zero, then each field in turn at the values it is checked at *)
CheckedLoggedOutMessage ==
    { ZeroLoggedOutMessage }
        \cup { [ZeroLoggedOutMessage EXCEPT !.reason = one] : one \in Sample(64) }

(***************************************************************************)
(* Heartbeat Message: 8 bytes                                              *)
(***************************************************************************)

HeartbeatMessage ==
    [ correlationId : Sample(8) ]

EncodeHeartbeatMessage(message) ==
    message.correlationId

DecodeHeartbeatMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroHeartbeatMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatMessage ==
    { ZeroHeartbeatMessage }
        \cup { [ZeroHeartbeatMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Test Request Message: 8 bytes                                           *)
(***************************************************************************)

TestRequestMessage ==
    [ correlationId : Sample(8) ]

EncodeTestRequestMessage(message) ==
    message.correlationId

DecodeTestRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroTestRequestMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Test Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTestRequestMessage ==
    { ZeroTestRequestMessage }
        \cup { [ZeroTestRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Resend Request Message: 8 bytes                                         *)
(***************************************************************************)

ResendRequestMessage ==
    [ fromSequenceNumber : Sample(4),
      toSequenceNumber   : Sample(4) ]

EncodeResendRequestMessage(message) ==
    message.fromSequenceNumber
        \o message.toSequenceNumber

DecodeResendRequestMessage(bytes) ==
    LET fromSequenceNumber == ReadBytes(bytes, 4) IN IF ~fromSequenceNumber.ok THEN Fail ELSE
    LET toSequenceNumber == ReadBytes(fromSequenceNumber.rest, 4) IN IF ~toSequenceNumber.ok THEN Fail ELSE
    Ok([ fromSequenceNumber |-> fromSequenceNumber.value,
         toSequenceNumber   |-> toSequenceNumber.value ], toSequenceNumber.rest)

ZeroResendRequestMessage ==
    [ fromSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      toSequenceNumber   |-> [i \in 1 .. 4 |-> 0] ]

(* Resend Request Message at zero, then each field in turn at the values it is checked at *)
CheckedResendRequestMessage ==
    { ZeroResendRequestMessage }
        \cup { [ZeroResendRequestMessage EXCEPT !.fromSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroResendRequestMessage EXCEPT !.toSequenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Gap Fill Message: 8 bytes                                               *)
(***************************************************************************)

GapFillMessage ==
    [ newSequenceNumber : Sample(4),
      gapFillPadding    : Sample(4) ]

EncodeGapFillMessage(message) ==
    message.newSequenceNumber
        \o message.gapFillPadding

DecodeGapFillMessage(bytes) ==
    LET newSequenceNumber == ReadBytes(bytes, 4) IN IF ~newSequenceNumber.ok THEN Fail ELSE
    LET gapFillPadding == ReadBytes(newSequenceNumber.rest, 4) IN IF ~gapFillPadding.ok THEN Fail ELSE
    Ok([ newSequenceNumber |-> newSequenceNumber.value,
         gapFillPadding    |-> gapFillPadding.value ], gapFillPadding.rest)

ZeroGapFillMessage ==
    [ newSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      gapFillPadding    |-> [i \in 1 .. 4 |-> 0] ]

(* Gap Fill Message at zero, then each field in turn at the values it is checked at *)
CheckedGapFillMessage ==
    { ZeroGapFillMessage }
        \cup { [ZeroGapFillMessage EXCEPT !.newSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroGapFillMessage EXCEPT !.gapFillPadding = one] : one \in Sample(4) }

(***************************************************************************)
(* Data                                                                    *)
(***************************************************************************)

Data ==
    [ dataValue : SampleBytes ]

EncodeData(message) ==
    EncodeUIntBE(Len(message.dataValue), 1)
        \o message.dataValue

DecodeData(bytes) ==
    LET dataLength == ReadUIntBE(bytes, 1) IN IF ~dataLength.ok THEN Fail ELSE
    LET dataValue == ReadBytes(dataLength.rest, dataLength.value) IN IF ~dataValue.ok THEN Fail ELSE
    Ok([ dataValue |-> dataValue.value ], dataValue.rest)

ZeroData ==
    [ dataValue |-> << >> ]

(* Data at zero, then each field in turn at the values it is checked at *)
CheckedData ==
    { ZeroData }
        \cup { [ZeroData EXCEPT !.dataValue = one] : one \in SampleBytes }

(***************************************************************************)
(* Ping Message                                                            *)
(***************************************************************************)

PingMessage ==
    [ correlationId : Sample(8),
      requestTime   : Sample(8),
      data          : Data ]

EncodePingMessage(message) ==
    message.correlationId
        \o message.requestTime
        \o EncodeData(message.data)

DecodePingMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET requestTime == ReadBytes(correlationId.rest, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET data == DecodeData(requestTime.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value,
         requestTime   |-> requestTime.value,
         data          |-> data.value ], data.rest)

ZeroPingMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0],
      requestTime   |-> [i \in 1 .. 8 |-> 0],
      data          |-> ZeroData ]

(* Ping Message at zero, then each field in turn at the values it is checked at *)
CheckedPingMessage ==
    { ZeroPingMessage }
        \cup { [ZeroPingMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroPingMessage EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroPingMessage EXCEPT !.data = one] : one \in CheckedData }

(***************************************************************************)
(* Data                                                                    *)
(***************************************************************************)

Data2 ==
    [ dataValue : SampleBytes ]

EncodeData2(message) ==
    EncodeUIntBE(Len(message.dataValue), 1)
        \o message.dataValue

DecodeData2(bytes) ==
    LET dataLength == ReadUIntBE(bytes, 1) IN IF ~dataLength.ok THEN Fail ELSE
    LET dataValue == ReadBytes(dataLength.rest, dataLength.value) IN IF ~dataValue.ok THEN Fail ELSE
    Ok([ dataValue |-> dataValue.value ], dataValue.rest)

ZeroData2 ==
    [ dataValue |-> << >> ]

(* Data at zero, then each field in turn at the values it is checked at *)
CheckedData2 ==
    { ZeroData2 }
        \cup { [ZeroData2 EXCEPT !.dataValue = one] : one \in SampleBytes }

(***************************************************************************)
(* Pong Message                                                            *)
(***************************************************************************)

PongMessage ==
    [ correlationId           : Sample(8),
      requestTime             : Sample(8),
      serverTime              : Sample(8),
      tradingInstrumentStatus : Sample(1),
      data                    : Data2 ]

EncodePongMessage(message) ==
    message.correlationId
        \o message.requestTime
        \o message.serverTime
        \o message.tradingInstrumentStatus
        \o EncodeData2(message.data)

DecodePongMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET requestTime == ReadBytes(correlationId.rest, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET serverTime == ReadBytes(requestTime.rest, 8) IN IF ~serverTime.ok THEN Fail ELSE
    LET tradingInstrumentStatus == ReadBytes(serverTime.rest, 1) IN IF ~tradingInstrumentStatus.ok THEN Fail ELSE
    LET data == DecodeData2(tradingInstrumentStatus.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ correlationId           |-> correlationId.value,
         requestTime             |-> requestTime.value,
         serverTime              |-> serverTime.value,
         tradingInstrumentStatus |-> tradingInstrumentStatus.value,
         data                    |-> data.value ], data.rest)

ZeroPongMessage ==
    [ correlationId           |-> [i \in 1 .. 8 |-> 0],
      requestTime             |-> [i \in 1 .. 8 |-> 0],
      serverTime              |-> [i \in 1 .. 8 |-> 0],
      tradingInstrumentStatus |-> [i \in 1 .. 1 |-> 0],
      data                    |-> ZeroData2 ]

(* Pong Message at zero, then each field in turn at the values it is checked at *)
CheckedPongMessage ==
    { ZeroPongMessage }
        \cup { [ZeroPongMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroPongMessage EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroPongMessage EXCEPT !.serverTime = one] : one \in Sample(8) }
        \cup { [ZeroPongMessage EXCEPT !.tradingInstrumentStatus = one] : one \in Sample(1) }
        \cup { [ZeroPongMessage EXCEPT !.data = one] : one \in CheckedData2 }

(***************************************************************************)
(* Instrument Info Request Message: 8 bytes                                *)
(***************************************************************************)

InstrumentInfoRequestMessage ==
    [ correlationId : Sample(8) ]

EncodeInstrumentInfoRequestMessage(message) ==
    message.correlationId

DecodeInstrumentInfoRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroInstrumentInfoRequestMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Info Request Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfoRequestMessage ==
    { ZeroInstrumentInfoRequestMessage }
        \cup { [ZeroInstrumentInfoRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Info Message: 48 bytes                                       *)
(***************************************************************************)

InstrumentInfoMessage ==
    [ correlationId    : Sample(8),
      instrumentId     : Sample(4),
      securityType     : Sample(1),
      instrumentStatus : Sample(1),
      isLastMessage    : Sample(1),
      reservedByte     : Sample(1),
      symbol           : Sample(32) ]

EncodeInstrumentInfoMessage(message) ==
    message.correlationId
        \o message.instrumentId
        \o message.securityType
        \o message.instrumentStatus
        \o message.isLastMessage
        \o message.reservedByte
        \o message.symbol

DecodeInstrumentInfoMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(correlationId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET securityType == ReadBytes(instrumentId.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET instrumentStatus == ReadBytes(securityType.rest, 1) IN IF ~instrumentStatus.ok THEN Fail ELSE
    LET isLastMessage == ReadBytes(instrumentStatus.rest, 1) IN IF ~isLastMessage.ok THEN Fail ELSE
    LET reservedByte == ReadBytes(isLastMessage.rest, 1) IN IF ~reservedByte.ok THEN Fail ELSE
    LET symbol == ReadBytes(reservedByte.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ correlationId    |-> correlationId.value,
         instrumentId     |-> instrumentId.value,
         securityType     |-> securityType.value,
         instrumentStatus |-> instrumentStatus.value,
         isLastMessage    |-> isLastMessage.value,
         reservedByte     |-> reservedByte.value,
         symbol           |-> symbol.value ], symbol.rest)

ZeroInstrumentInfoMessage ==
    [ correlationId    |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      securityType     |-> [i \in 1 .. 1 |-> 0],
      instrumentStatus |-> [i \in 1 .. 1 |-> 0],
      isLastMessage    |-> [i \in 1 .. 1 |-> 0],
      reservedByte     |-> [i \in 1 .. 1 |-> 0],
      symbol           |-> [i \in 1 .. 32 |-> 0] ]

(* Instrument Info Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfoMessage ==
    { ZeroInstrumentInfoMessage }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.instrumentStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.isLastMessage = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.reservedByte = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.symbol = one] : one \in Sample(32) }

(***************************************************************************)
(* Set Account Message: 24 bytes                                           *)
(***************************************************************************)

SetAccountMessage ==
    [ correlationId : Sample(8),
      account       : Sample(16) ]

EncodeSetAccountMessage(message) ==
    message.correlationId
        \o message.account

DecodeSetAccountMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET account == ReadBytes(correlationId.rest, 16) IN IF ~account.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value,
         account       |-> account.value ], account.rest)

ZeroSetAccountMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0],
      account       |-> [i \in 1 .. 16 |-> 0] ]

(* Set Account Message at zero, then each field in turn at the values it is checked at *)
CheckedSetAccountMessage ==
    { ZeroSetAccountMessage }
        \cup { [ZeroSetAccountMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroSetAccountMessage EXCEPT !.account = one] : one \in Sample(16) }

(***************************************************************************)
(* Set Trader Message: 24 bytes                                            *)
(***************************************************************************)

SetTraderMessage ==
    [ correlationId : Sample(8),
      trader        : Sample(16) ]

EncodeSetTraderMessage(message) ==
    message.correlationId
        \o message.trader

DecodeSetTraderMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET trader == ReadBytes(correlationId.rest, 16) IN IF ~trader.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value,
         trader        |-> trader.value ], trader.rest)

ZeroSetTraderMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0],
      trader        |-> [i \in 1 .. 16 |-> 0] ]

(* Set Trader Message at zero, then each field in turn at the values it is checked at *)
CheckedSetTraderMessage ==
    { ZeroSetTraderMessage }
        \cup { [ZeroSetTraderMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroSetTraderMessage EXCEPT !.trader = one] : one \in Sample(16) }

(***************************************************************************)
(* Set Ack Message: 8 bytes                                                *)
(***************************************************************************)

SetAckMessage ==
    [ correlationId : Sample(8) ]

EncodeSetAckMessage(message) ==
    message.correlationId

DecodeSetAckMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroSetAckMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Set Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedSetAckMessage ==
    { ZeroSetAckMessage }
        \cup { [ZeroSetAckMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* New Order Message: 33 bytes                                             *)
(***************************************************************************)

NewOrderMessage ==
    [ clientOrderId : Sample(8),
      correlationId : Sample(8),
      limitPrice    : Sample(8),
      quantity      : Sample(4),
      instrumentId  : Sample(4),
      side          : Sample(1) ]

EncodeNewOrderMessage(message) ==
    message.clientOrderId
        \o message.correlationId
        \o message.limitPrice
        \o message.quantity
        \o message.instrumentId
        \o message.side

DecodeNewOrderMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(correlationId.rest, 8) IN IF ~limitPrice.ok THEN Fail ELSE
    LET quantity == ReadBytes(limitPrice.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         limitPrice    |-> limitPrice.value,
         quantity      |-> quantity.value,
         instrumentId  |-> instrumentId.value,
         side          |-> side.value ], side.rest)

ZeroNewOrderMessage ==
    [ clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      limitPrice    |-> [i \in 1 .. 8 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.limitPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Entered Message: 48 bytes                                         *)
(***************************************************************************)

OrderEnteredMessage ==
    [ timestamp     : Sample(8),
      execId        : Sample(8),
      clientOrderId : Sample(8),
      correlationId : Sample(8),
      orderId       : Sample(8),
      receiveTime   : Sample(8) ]

EncodeOrderEnteredMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.receiveTime

DecodeOrderEnteredMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET receiveTime == ReadBytes(orderId.rest, 8) IN IF ~receiveTime.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         execId        |-> execId.value,
         clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         orderId       |-> orderId.value,
         receiveTime   |-> receiveTime.value ], receiveTime.rest)

ZeroOrderEnteredMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      receiveTime   |-> [i \in 1 .. 8 |-> 0] ]

(* Order Entered Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderEnteredMessage ==
    { ZeroOrderEnteredMessage }
        \cup { [ZeroOrderEnteredMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderEnteredMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderEnteredMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderEnteredMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroOrderEnteredMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderEnteredMessage EXCEPT !.receiveTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Replace Order Message: 32 bytes                                         *)
(***************************************************************************)

ReplaceOrderMessage ==
    [ clientOrderId : Sample(8),
      correlationId : Sample(8),
      newLimitPrice : Sample(8),
      newQuantity   : Sample(4),
      instrumentId  : Sample(4) ]

EncodeReplaceOrderMessage(message) ==
    message.clientOrderId
        \o message.correlationId
        \o message.newLimitPrice
        \o message.newQuantity
        \o message.instrumentId

DecodeReplaceOrderMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET newLimitPrice == ReadBytes(correlationId.rest, 8) IN IF ~newLimitPrice.ok THEN Fail ELSE
    LET newQuantity == ReadBytes(newLimitPrice.rest, 4) IN IF ~newQuantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(newQuantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         newLimitPrice |-> newLimitPrice.value,
         newQuantity   |-> newQuantity.value,
         instrumentId  |-> instrumentId.value ], instrumentId.rest)

ZeroReplaceOrderMessage ==
    [ clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      newLimitPrice |-> [i \in 1 .. 8 |-> 0],
      newQuantity   |-> [i \in 1 .. 4 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0] ]

(* Replace Order Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderMessage ==
    { ZeroReplaceOrderMessage }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.newLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.newQuantity = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Stream Order Message: 41 bytes                                          *)
(***************************************************************************)

StreamOrderMessage ==
    [ clientOrderId       : Sample(8),
      correlationId       : Sample(8),
      lastProcessedFillId : Sample(8),
      limitPrice          : Sample(8),
      quantity            : Sample(4),
      instrumentId        : Sample(4),
      side                : Sample(1) ]

EncodeStreamOrderMessage(message) ==
    message.clientOrderId
        \o message.correlationId
        \o message.lastProcessedFillId
        \o message.limitPrice
        \o message.quantity
        \o message.instrumentId
        \o message.side

DecodeStreamOrderMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET lastProcessedFillId == ReadBytes(correlationId.rest, 8) IN IF ~lastProcessedFillId.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(lastProcessedFillId.rest, 8) IN IF ~limitPrice.ok THEN Fail ELSE
    LET quantity == ReadBytes(limitPrice.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ clientOrderId       |-> clientOrderId.value,
         correlationId       |-> correlationId.value,
         lastProcessedFillId |-> lastProcessedFillId.value,
         limitPrice          |-> limitPrice.value,
         quantity            |-> quantity.value,
         instrumentId        |-> instrumentId.value,
         side                |-> side.value ], side.rest)

ZeroStreamOrderMessage ==
    [ clientOrderId       |-> [i \in 1 .. 8 |-> 0],
      correlationId       |-> [i \in 1 .. 8 |-> 0],
      lastProcessedFillId |-> [i \in 1 .. 8 |-> 0],
      limitPrice          |-> [i \in 1 .. 8 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0] ]

(* Stream Order Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamOrderMessage ==
    { ZeroStreamOrderMessage }
        \cup { [ZeroStreamOrderMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroStreamOrderMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroStreamOrderMessage EXCEPT !.lastProcessedFillId = one] : one \in Sample(8) }
        \cup { [ZeroStreamOrderMessage EXCEPT !.limitPrice = one] : one \in Sample(8) }
        \cup { [ZeroStreamOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroStreamOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroStreamOrderMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Reject Message: 80 bytes                                          *)
(***************************************************************************)

OrderRejectMessage ==
    [ timestamp          : Sample(8),
      clientOrderId      : Sample(8),
      correlationId      : Sample(8),
      orderIdOptional    : Sample(8),
      orderRejectReason  : Sample(1),
      orderRejectDetails : Sample(47) ]

EncodeOrderRejectMessage(message) ==
    message.timestamp
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderIdOptional
        \o message.orderRejectReason
        \o message.orderRejectDetails

DecodeOrderRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(timestamp.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(correlationId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET orderRejectReason == ReadBytes(orderIdOptional.rest, 1) IN IF ~orderRejectReason.ok THEN Fail ELSE
    LET orderRejectDetails == ReadBytes(orderRejectReason.rest, 47) IN IF ~orderRejectDetails.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         clientOrderId      |-> clientOrderId.value,
         correlationId      |-> correlationId.value,
         orderIdOptional    |-> orderIdOptional.value,
         orderRejectReason  |-> orderRejectReason.value,
         orderRejectDetails |-> orderRejectDetails.value ], orderRejectDetails.rest)

ZeroOrderRejectMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      clientOrderId      |-> [i \in 1 .. 8 |-> 0],
      correlationId      |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional    |-> [i \in 1 .. 8 |-> 0],
      orderRejectReason  |-> [i \in 1 .. 1 |-> 0],
      orderRejectDetails |-> [i \in 1 .. 47 |-> 0] ]

(* Order Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRejectMessage ==
    { ZeroOrderRejectMessage }
        \cup { [ZeroOrderRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderRejectMessage EXCEPT !.orderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRejectMessage EXCEPT !.orderRejectDetails = one] : one \in Sample(47) }

(***************************************************************************)
(* Order Replaced Message: 60 bytes                                        *)
(***************************************************************************)

OrderReplacedMessage ==
    [ timestamp     : Sample(8),
      execId        : Sample(8),
      clientOrderId : Sample(8),
      correlationId : Sample(8),
      orderId       : Sample(8),
      receiveTime   : Sample(8),
      totalFilled   : Sample(4),
      availableQty  : Sample(4),
      instrumentId  : Sample(4) ]

EncodeOrderReplacedMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.receiveTime
        \o message.totalFilled
        \o message.availableQty
        \o message.instrumentId

DecodeOrderReplacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET receiveTime == ReadBytes(orderId.rest, 8) IN IF ~receiveTime.ok THEN Fail ELSE
    LET totalFilled == ReadBytes(receiveTime.rest, 4) IN IF ~totalFilled.ok THEN Fail ELSE
    LET availableQty == ReadBytes(totalFilled.rest, 4) IN IF ~availableQty.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(availableQty.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         execId        |-> execId.value,
         clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         orderId       |-> orderId.value,
         receiveTime   |-> receiveTime.value,
         totalFilled   |-> totalFilled.value,
         availableQty  |-> availableQty.value,
         instrumentId  |-> instrumentId.value ], instrumentId.rest)

ZeroOrderReplacedMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      receiveTime   |-> [i \in 1 .. 8 |-> 0],
      totalFilled   |-> [i \in 1 .. 4 |-> 0],
      availableQty  |-> [i \in 1 .. 4 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.receiveTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.totalFilled = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.availableQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Cancel Order Message: 20 bytes                                          *)
(***************************************************************************)

CancelOrderMessage ==
    [ clientOrderId : Sample(8),
      correlationId : Sample(8),
      instrumentId  : Sample(4) ]

EncodeCancelOrderMessage(message) ==
    message.clientOrderId
        \o message.correlationId
        \o message.instrumentId

DecodeCancelOrderMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(correlationId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         instrumentId  |-> instrumentId.value ], instrumentId.rest)

ZeroCancelOrderMessage ==
    [ clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Canceled Message: 57 bytes                                        *)
(***************************************************************************)

OrderCanceledMessage ==
    [ timestamp     : Sample(8),
      execId        : Sample(8),
      clientOrderId : Sample(8),
      correlationId : Sample(8),
      orderId       : Sample(8),
      receiveTime   : Sample(8),
      totalFilled   : Sample(4),
      instrumentId  : Sample(4),
      cancelReason  : Sample(1) ]

EncodeOrderCanceledMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.receiveTime
        \o message.totalFilled
        \o message.instrumentId
        \o message.cancelReason

DecodeOrderCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET receiveTime == ReadBytes(orderId.rest, 8) IN IF ~receiveTime.ok THEN Fail ELSE
    LET totalFilled == ReadBytes(receiveTime.rest, 4) IN IF ~totalFilled.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(totalFilled.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(instrumentId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         execId        |-> execId.value,
         clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         orderId       |-> orderId.value,
         receiveTime   |-> receiveTime.value,
         totalFilled   |-> totalFilled.value,
         instrumentId  |-> instrumentId.value,
         cancelReason  |-> cancelReason.value ], cancelReason.rest)

ZeroOrderCanceledMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      receiveTime   |-> [i \in 1 .. 8 |-> 0],
      totalFilled   |-> [i \in 1 .. 4 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      cancelReason  |-> [i \in 1 .. 1 |-> 0] ]

(* Order Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCanceledMessage ==
    { ZeroOrderCanceledMessage }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.receiveTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.totalFilled = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Order Reject Message: 64 bytes                                   *)
(***************************************************************************)

CancelOrderRejectMessage ==
    [ timestamp                : Sample(8),
      clientOrderId            : Sample(8),
      correlationId            : Sample(8),
      orderIdOptional          : Sample(8),
      cancelOrderRejectReason  : Sample(1),
      cancelOrderRejectDetails : Sample(31) ]

EncodeCancelOrderRejectMessage(message) ==
    message.timestamp
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderIdOptional
        \o message.cancelOrderRejectReason
        \o message.cancelOrderRejectDetails

DecodeCancelOrderRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(timestamp.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(correlationId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET cancelOrderRejectReason == ReadBytes(orderIdOptional.rest, 1) IN IF ~cancelOrderRejectReason.ok THEN Fail ELSE
    LET cancelOrderRejectDetails == ReadBytes(cancelOrderRejectReason.rest, 31) IN IF ~cancelOrderRejectDetails.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         clientOrderId            |-> clientOrderId.value,
         correlationId            |-> correlationId.value,
         orderIdOptional          |-> orderIdOptional.value,
         cancelOrderRejectReason  |-> cancelOrderRejectReason.value,
         cancelOrderRejectDetails |-> cancelOrderRejectDetails.value ], cancelOrderRejectDetails.rest)

ZeroCancelOrderRejectMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      clientOrderId            |-> [i \in 1 .. 8 |-> 0],
      correlationId            |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional          |-> [i \in 1 .. 8 |-> 0],
      cancelOrderRejectReason  |-> [i \in 1 .. 1 |-> 0],
      cancelOrderRejectDetails |-> [i \in 1 .. 31 |-> 0] ]

(* Cancel Order Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderRejectMessage ==
    { ZeroCancelOrderRejectMessage }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.cancelOrderRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelOrderRejectMessage EXCEPT !.cancelOrderRejectDetails = one] : one \in Sample(31) }

(***************************************************************************)
(* Mass Cancel Order Message: 23 bytes                                     *)
(***************************************************************************)

MassCancelOrderMessage ==
    [ correlationId      : Sample(8),
      limitPrice         : Sample(8),
      instrumentId       : Sample(4),
      side               : Sample(1),
      currentSessionOnly : Sample(1),
      requestTradingLock : Sample(1) ]

EncodeMassCancelOrderMessage(message) ==
    message.correlationId
        \o message.limitPrice
        \o message.instrumentId
        \o message.side
        \o message.currentSessionOnly
        \o message.requestTradingLock

DecodeMassCancelOrderMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(correlationId.rest, 8) IN IF ~limitPrice.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(limitPrice.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET currentSessionOnly == ReadBytes(side.rest, 1) IN IF ~currentSessionOnly.ok THEN Fail ELSE
    LET requestTradingLock == ReadBytes(currentSessionOnly.rest, 1) IN IF ~requestTradingLock.ok THEN Fail ELSE
    Ok([ correlationId      |-> correlationId.value,
         limitPrice         |-> limitPrice.value,
         instrumentId       |-> instrumentId.value,
         side               |-> side.value,
         currentSessionOnly |-> currentSessionOnly.value,
         requestTradingLock |-> requestTradingLock.value ], requestTradingLock.rest)

ZeroMassCancelOrderMessage ==
    [ correlationId      |-> [i \in 1 .. 8 |-> 0],
      limitPrice         |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      currentSessionOnly |-> [i \in 1 .. 1 |-> 0],
      requestTradingLock |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelOrderMessage ==
    { ZeroMassCancelOrderMessage }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.limitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.currentSessionOnly = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelOrderMessage EXCEPT !.requestTradingLock = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Order Ack Message: 30 bytes                                 *)
(***************************************************************************)

MassCancelOrderAckMessage ==
    [ timestamp          : Sample(8),
      execId             : Sample(8),
      correlationId      : Sample(8),
      canceledCount      : Sample(4),
      onlyCurrentSession : Sample(1),
      tradingLockApplied : Sample(1) ]

EncodeMassCancelOrderAckMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.correlationId
        \o message.canceledCount
        \o message.onlyCurrentSession
        \o message.tradingLockApplied

DecodeMassCancelOrderAckMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(execId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET canceledCount == ReadBytes(correlationId.rest, 4) IN IF ~canceledCount.ok THEN Fail ELSE
    LET onlyCurrentSession == ReadBytes(canceledCount.rest, 1) IN IF ~onlyCurrentSession.ok THEN Fail ELSE
    LET tradingLockApplied == ReadBytes(onlyCurrentSession.rest, 1) IN IF ~tradingLockApplied.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         execId             |-> execId.value,
         correlationId      |-> correlationId.value,
         canceledCount      |-> canceledCount.value,
         onlyCurrentSession |-> onlyCurrentSession.value,
         tradingLockApplied |-> tradingLockApplied.value ], tradingLockApplied.rest)

ZeroMassCancelOrderAckMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      execId             |-> [i \in 1 .. 8 |-> 0],
      correlationId      |-> [i \in 1 .. 8 |-> 0],
      canceledCount      |-> [i \in 1 .. 4 |-> 0],
      onlyCurrentSession |-> [i \in 1 .. 1 |-> 0],
      tradingLockApplied |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Cancel Order Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelOrderAckMessage ==
    { ZeroMassCancelOrderAckMessage }
        \cup { [ZeroMassCancelOrderAckMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelOrderAckMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelOrderAckMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelOrderAckMessage EXCEPT !.canceledCount = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelOrderAckMessage EXCEPT !.onlyCurrentSession = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelOrderAckMessage EXCEPT !.tradingLockApplied = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Order Reject Message: 48 bytes                              *)
(***************************************************************************)

MassCancelOrderRejectMessage ==
    [ timestamp     : Sample(8),
      correlationId : Sample(8),
      errorMessage  : Sample(32) ]

EncodeMassCancelOrderRejectMessage(message) ==
    message.timestamp
        \o message.correlationId
        \o message.errorMessage

DecodeMassCancelOrderRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET correlationId == ReadBytes(timestamp.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET errorMessage == ReadBytes(correlationId.rest, 32) IN IF ~errorMessage.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         correlationId |-> correlationId.value,
         errorMessage  |-> errorMessage.value ], errorMessage.rest)

ZeroMassCancelOrderRejectMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      errorMessage  |-> [i \in 1 .. 32 |-> 0] ]

(* Mass Cancel Order Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelOrderRejectMessage ==
    { ZeroMassCancelOrderRejectMessage }
        \cup { [ZeroMassCancelOrderRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelOrderRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelOrderRejectMessage EXCEPT !.errorMessage = one] : one \in Sample(32) }

(***************************************************************************)
(* Unlock Trading Message: 9 bytes                                         *)
(***************************************************************************)

UnlockTradingMessage ==
    [ correlationId      : Sample(8),
      currentSessionOnly : Sample(1) ]

EncodeUnlockTradingMessage(message) ==
    message.correlationId
        \o message.currentSessionOnly

DecodeUnlockTradingMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET currentSessionOnly == ReadBytes(correlationId.rest, 1) IN IF ~currentSessionOnly.ok THEN Fail ELSE
    Ok([ correlationId      |-> correlationId.value,
         currentSessionOnly |-> currentSessionOnly.value ], currentSessionOnly.rest)

ZeroUnlockTradingMessage ==
    [ correlationId      |-> [i \in 1 .. 8 |-> 0],
      currentSessionOnly |-> [i \in 1 .. 1 |-> 0] ]

(* Unlock Trading Message at zero, then each field in turn at the values it is checked at *)
CheckedUnlockTradingMessage ==
    { ZeroUnlockTradingMessage }
        \cup { [ZeroUnlockTradingMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroUnlockTradingMessage EXCEPT !.currentSessionOnly = one] : one \in Sample(1) }

(***************************************************************************)
(* Unlock Trading Ack Message: 20 bytes                                    *)
(***************************************************************************)

UnlockTradingAckMessage ==
    [ timestamp        : Sample(8),
      correlationId    : Sample(8),
      numUsersAffected : Sample(4) ]

EncodeUnlockTradingAckMessage(message) ==
    message.timestamp
        \o message.correlationId
        \o message.numUsersAffected

DecodeUnlockTradingAckMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET correlationId == ReadBytes(timestamp.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET numUsersAffected == ReadBytes(correlationId.rest, 4) IN IF ~numUsersAffected.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         correlationId    |-> correlationId.value,
         numUsersAffected |-> numUsersAffected.value ], numUsersAffected.rest)

ZeroUnlockTradingAckMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      correlationId    |-> [i \in 1 .. 8 |-> 0],
      numUsersAffected |-> [i \in 1 .. 4 |-> 0] ]

(* Unlock Trading Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedUnlockTradingAckMessage ==
    { ZeroUnlockTradingAckMessage }
        \cup { [ZeroUnlockTradingAckMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroUnlockTradingAckMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroUnlockTradingAckMessage EXCEPT !.numUsersAffected = one] : one \in Sample(4) }

(***************************************************************************)
(* Unlock Trading Reject Message: 48 bytes                                 *)
(***************************************************************************)

UnlockTradingRejectMessage ==
    [ timestamp     : Sample(8),
      correlationId : Sample(8),
      errorMessage  : Sample(32) ]

EncodeUnlockTradingRejectMessage(message) ==
    message.timestamp
        \o message.correlationId
        \o message.errorMessage

DecodeUnlockTradingRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET correlationId == ReadBytes(timestamp.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET errorMessage == ReadBytes(correlationId.rest, 32) IN IF ~errorMessage.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         correlationId |-> correlationId.value,
         errorMessage  |-> errorMessage.value ], errorMessage.rest)

ZeroUnlockTradingRejectMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      errorMessage  |-> [i \in 1 .. 32 |-> 0] ]

(* Unlock Trading Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedUnlockTradingRejectMessage ==
    { ZeroUnlockTradingRejectMessage }
        \cup { [ZeroUnlockTradingRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroUnlockTradingRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroUnlockTradingRejectMessage EXCEPT !.errorMessage = one] : one \in Sample(32) }

(***************************************************************************)
(* Order Filled Message: 81 bytes                                          *)
(***************************************************************************)

OrderFilledMessage ==
    [ timestamp     : Sample(8),
      execId        : Sample(8),
      matchId       : Sample(8),
      clientOrderId : Sample(8),
      correlationId : Sample(8),
      orderId       : Sample(8),
      filledVwap    : Sample(8),
      totalFilled   : Sample(4),
      availableQty  : Sample(4),
      fillPrice     : Sample(8),
      fillQty       : Sample(4),
      instrumentId  : Sample(4),
      isAggressor   : Sample(1) ]

EncodeOrderFilledMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.matchId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.filledVwap
        \o message.totalFilled
        \o message.availableQty
        \o message.fillPrice
        \o message.fillQty
        \o message.instrumentId
        \o message.isAggressor

DecodeOrderFilledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET matchId == ReadBytes(execId.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(matchId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET filledVwap == ReadBytes(orderId.rest, 8) IN IF ~filledVwap.ok THEN Fail ELSE
    LET totalFilled == ReadBytes(filledVwap.rest, 4) IN IF ~totalFilled.ok THEN Fail ELSE
    LET availableQty == ReadBytes(totalFilled.rest, 4) IN IF ~availableQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(availableQty.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPrice.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(fillQty.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET isAggressor == ReadBytes(instrumentId.rest, 1) IN IF ~isAggressor.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         execId        |-> execId.value,
         matchId       |-> matchId.value,
         clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         orderId       |-> orderId.value,
         filledVwap    |-> filledVwap.value,
         totalFilled   |-> totalFilled.value,
         availableQty  |-> availableQty.value,
         fillPrice     |-> fillPrice.value,
         fillQty       |-> fillQty.value,
         instrumentId  |-> instrumentId.value,
         isAggressor   |-> isAggressor.value ], isAggressor.rest)

ZeroOrderFilledMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      matchId       |-> [i \in 1 .. 8 |-> 0],
      clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      filledVwap    |-> [i \in 1 .. 8 |-> 0],
      totalFilled   |-> [i \in 1 .. 4 |-> 0],
      availableQty  |-> [i \in 1 .. 4 |-> 0],
      fillPrice     |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> [i \in 1 .. 4 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      isAggressor   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderFilledMessage ==
    { ZeroOrderFilledMessage }
        \cup { [ZeroOrderFilledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.filledVwap = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.totalFilled = one] : one \in Sample(4) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.availableQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderFilledMessage EXCEPT !.isAggressor = one] : one \in Sample(1) }

(***************************************************************************)
(* Spread Order Filled Message: 97 bytes                                   *)
(***************************************************************************)

SpreadOrderFilledMessage ==
    [ timestamp     : Sample(8),
      execId        : Sample(8),
      matchId       : Sample(8),
      clientOrderId : Sample(8),
      correlationId : Sample(8),
      orderId       : Sample(8),
      filledVwap    : Sample(8),
      totalFilled   : Sample(4),
      availableQty  : Sample(4),
      fillPrice     : Sample(8),
      leg1FillPrice : Sample(8),
      leg2FillPrice : Sample(8),
      fillQty       : Sample(4),
      instrumentId  : Sample(4),
      isAggressor   : Sample(1) ]

EncodeSpreadOrderFilledMessage(message) ==
    message.timestamp
        \o message.execId
        \o message.matchId
        \o message.clientOrderId
        \o message.correlationId
        \o message.orderId
        \o message.filledVwap
        \o message.totalFilled
        \o message.availableQty
        \o message.fillPrice
        \o message.leg1FillPrice
        \o message.leg2FillPrice
        \o message.fillQty
        \o message.instrumentId
        \o message.isAggressor

DecodeSpreadOrderFilledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(timestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET matchId == ReadBytes(execId.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(matchId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(clientOrderId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET orderId == ReadBytes(correlationId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET filledVwap == ReadBytes(orderId.rest, 8) IN IF ~filledVwap.ok THEN Fail ELSE
    LET totalFilled == ReadBytes(filledVwap.rest, 4) IN IF ~totalFilled.ok THEN Fail ELSE
    LET availableQty == ReadBytes(totalFilled.rest, 4) IN IF ~availableQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(availableQty.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET leg1FillPrice == ReadBytes(fillPrice.rest, 8) IN IF ~leg1FillPrice.ok THEN Fail ELSE
    LET leg2FillPrice == ReadBytes(leg1FillPrice.rest, 8) IN IF ~leg2FillPrice.ok THEN Fail ELSE
    LET fillQty == ReadBytes(leg2FillPrice.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(fillQty.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET isAggressor == ReadBytes(instrumentId.rest, 1) IN IF ~isAggressor.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         execId        |-> execId.value,
         matchId       |-> matchId.value,
         clientOrderId |-> clientOrderId.value,
         correlationId |-> correlationId.value,
         orderId       |-> orderId.value,
         filledVwap    |-> filledVwap.value,
         totalFilled   |-> totalFilled.value,
         availableQty  |-> availableQty.value,
         fillPrice     |-> fillPrice.value,
         leg1FillPrice |-> leg1FillPrice.value,
         leg2FillPrice |-> leg2FillPrice.value,
         fillQty       |-> fillQty.value,
         instrumentId  |-> instrumentId.value,
         isAggressor   |-> isAggressor.value ], isAggressor.rest)

ZeroSpreadOrderFilledMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0],
      matchId       |-> [i \in 1 .. 8 |-> 0],
      clientOrderId |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      filledVwap    |-> [i \in 1 .. 8 |-> 0],
      totalFilled   |-> [i \in 1 .. 4 |-> 0],
      availableQty  |-> [i \in 1 .. 4 |-> 0],
      fillPrice     |-> [i \in 1 .. 8 |-> 0],
      leg1FillPrice |-> [i \in 1 .. 8 |-> 0],
      leg2FillPrice |-> [i \in 1 .. 8 |-> 0],
      fillQty       |-> [i \in 1 .. 4 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      isAggressor   |-> [i \in 1 .. 1 |-> 0] ]

(* Spread Order Filled Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadOrderFilledMessage ==
    { ZeroSpreadOrderFilledMessage }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.filledVwap = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.totalFilled = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.availableQty = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.leg1FillPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.leg2FillPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderFilledMessage EXCEPT !.isAggressor = one] : one \in Sample(1) }

(***************************************************************************)
(* Last Exec Id Request Message: 8 bytes                                   *)
(***************************************************************************)

LastExecIdRequestMessage ==
    [ correlationId : Sample(8) ]

EncodeLastExecIdRequestMessage(message) ==
    message.correlationId

DecodeLastExecIdRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value ], correlationId.rest)

ZeroLastExecIdRequestMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Last Exec Id Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLastExecIdRequestMessage ==
    { ZeroLastExecIdRequestMessage }
        \cup { [ZeroLastExecIdRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Last Exec Id Message: 24 bytes                                          *)
(***************************************************************************)

LastExecIdMessage ==
    [ timestamp     : Sample(8),
      lastExecId    : Sample(8),
      correlationId : Sample(8) ]

EncodeLastExecIdMessage(message) ==
    message.timestamp
        \o message.lastExecId
        \o message.correlationId

DecodeLastExecIdMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET lastExecId == ReadBytes(timestamp.rest, 8) IN IF ~lastExecId.ok THEN Fail ELSE
    LET correlationId == ReadBytes(lastExecId.rest, 8) IN IF ~correlationId.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         lastExecId    |-> lastExecId.value,
         correlationId |-> correlationId.value ], correlationId.rest)

ZeroLastExecIdMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      lastExecId    |-> [i \in 1 .. 8 |-> 0],
      correlationId |-> [i \in 1 .. 8 |-> 0] ]

(* Last Exec Id Message at zero, then each field in turn at the values it is checked at *)
CheckedLastExecIdMessage ==
    { ZeroLastExecIdMessage }
        \cup { [ZeroLastExecIdMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroLastExecIdMessage EXCEPT !.lastExecId = one] : one \in Sample(8) }
        \cup { [ZeroLastExecIdMessage EXCEPT !.correlationId = one] : one \in Sample(8) }

(***************************************************************************)
(* Event Resend Request Message: 24 bytes                                  *)
(***************************************************************************)

EventResendRequestMessage ==
    [ correlationId : Sample(8),
      beginExecId   : Sample(8),
      endExecId     : Sample(8) ]

EncodeEventResendRequestMessage(message) ==
    message.correlationId
        \o message.beginExecId
        \o message.endExecId

DecodeEventResendRequestMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET beginExecId == ReadBytes(correlationId.rest, 8) IN IF ~beginExecId.ok THEN Fail ELSE
    LET endExecId == ReadBytes(beginExecId.rest, 8) IN IF ~endExecId.ok THEN Fail ELSE
    Ok([ correlationId |-> correlationId.value,
         beginExecId   |-> beginExecId.value,
         endExecId     |-> endExecId.value ], endExecId.rest)

ZeroEventResendRequestMessage ==
    [ correlationId |-> [i \in 1 .. 8 |-> 0],
      beginExecId   |-> [i \in 1 .. 8 |-> 0],
      endExecId     |-> [i \in 1 .. 8 |-> 0] ]

(* Event Resend Request Message at zero, then each field in turn at the values it is checked at *)
CheckedEventResendRequestMessage ==
    { ZeroEventResendRequestMessage }
        \cup { [ZeroEventResendRequestMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroEventResendRequestMessage EXCEPT !.beginExecId = one] : one \in Sample(8) }
        \cup { [ZeroEventResendRequestMessage EXCEPT !.endExecId = one] : one \in Sample(8) }

(***************************************************************************)
(* Event Resend Complete Message: 12 bytes                                 *)
(***************************************************************************)

EventResendCompleteMessage ==
    [ correlationId    : Sample(8),
      resentEventCount : Sample(4) ]

EncodeEventResendCompleteMessage(message) ==
    message.correlationId
        \o message.resentEventCount

DecodeEventResendCompleteMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET resentEventCount == ReadBytes(correlationId.rest, 4) IN IF ~resentEventCount.ok THEN Fail ELSE
    Ok([ correlationId    |-> correlationId.value,
         resentEventCount |-> resentEventCount.value ], resentEventCount.rest)

ZeroEventResendCompleteMessage ==
    [ correlationId    |-> [i \in 1 .. 8 |-> 0],
      resentEventCount |-> [i \in 1 .. 4 |-> 0] ]

(* Event Resend Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedEventResendCompleteMessage ==
    { ZeroEventResendCompleteMessage }
        \cup { [ZeroEventResendCompleteMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroEventResendCompleteMessage EXCEPT !.resentEventCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Event Resend Reject Message: 32 bytes                                   *)
(***************************************************************************)

EventResendRejectMessage ==
    [ correlationId            : Sample(8),
      resendRejectReason       : Sample(1),
      eventResendRejectDetails : Sample(23) ]

EncodeEventResendRejectMessage(message) ==
    message.correlationId
        \o message.resendRejectReason
        \o message.eventResendRejectDetails

DecodeEventResendRejectMessage(bytes) ==
    LET correlationId == ReadBytes(bytes, 8) IN IF ~correlationId.ok THEN Fail ELSE
    LET resendRejectReason == ReadBytes(correlationId.rest, 1) IN IF ~resendRejectReason.ok THEN Fail ELSE
    LET eventResendRejectDetails == ReadBytes(resendRejectReason.rest, 23) IN IF ~eventResendRejectDetails.ok THEN Fail ELSE
    Ok([ correlationId            |-> correlationId.value,
         resendRejectReason       |-> resendRejectReason.value,
         eventResendRejectDetails |-> eventResendRejectDetails.value ], eventResendRejectDetails.rest)

ZeroEventResendRejectMessage ==
    [ correlationId            |-> [i \in 1 .. 8 |-> 0],
      resendRejectReason       |-> [i \in 1 .. 1 |-> 0],
      eventResendRejectDetails |-> [i \in 1 .. 23 |-> 0] ]

(* Event Resend Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedEventResendRejectMessage ==
    { ZeroEventResendRejectMessage }
        \cup { [ZeroEventResendRejectMessage EXCEPT !.correlationId = one] : one \in Sample(8) }
        \cup { [ZeroEventResendRejectMessage EXCEPT !.resendRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroEventResendRejectMessage EXCEPT !.eventResendRejectDetails = one] : one \in Sample(23) }

(***************************************************************************)
(* Payload, selected by Schema Id and Template Id                          *)
(***************************************************************************)

LogonMessageCode == <<1100, 100>>  \* 0x44c, 0x64
LogonConfMessageCode == <<1100, 200>>  \* 0x44c, 0xc8
LogoutMessageCode == <<1100, 101>>  \* 0x44c, 0x65
LoggedOutMessageCode == <<1100, 201>>  \* 0x44c, 0xc9
HeartbeatMessageCode == <<1100, 10>>  \* 0x44c, 0x0a
TestRequestMessageCode == <<1100, 11>>  \* 0x44c, 0x0b
ResendRequestMessageCode == <<1100, 102>>  \* 0x44c, 0x66
GapFillMessageCode == <<1100, 202>>  \* 0x44c, 0xca
PingMessageCode == <<1101, 102>>  \* 0x44d, 0x66
PongMessageCode == <<1101, 202>>  \* 0x44d, 0xca
InstrumentInfoRequestMessageCode == <<1101, 103>>  \* 0x44d, 0x67
InstrumentInfoMessageCode == <<1101, 203>>  \* 0x44d, 0xcb
SetAccountMessageCode == <<1101, 105>>  \* 0x44d, 0x69
SetTraderMessageCode == <<1101, 106>>  \* 0x44d, 0x6a
SetAckMessageCode == <<1101, 205>>  \* 0x44d, 0xcd
NewOrderMessageCode == <<1101, 110>>  \* 0x44d, 0x6e
OrderEnteredMessageCode == <<1101, 210>>  \* 0x44d, 0xd2
ReplaceOrderMessageCode == <<1101, 120>>  \* 0x44d, 0x78
StreamOrderMessageCode == <<1101, 121>>  \* 0x44d, 0x79
OrderRejectMessageCode == <<1101, 221>>  \* 0x44d, 0xdd
OrderReplacedMessageCode == <<1101, 220>>  \* 0x44d, 0xdc
CancelOrderMessageCode == <<1101, 130>>  \* 0x44d, 0x82
OrderCanceledMessageCode == <<1101, 230>>  \* 0x44d, 0xe6
CancelOrderRejectMessageCode == <<1101, 233>>  \* 0x44d, 0xe9
MassCancelOrderMessageCode == <<1101, 131>>  \* 0x44d, 0x83
MassCancelOrderAckMessageCode == <<1101, 231>>  \* 0x44d, 0xe7
MassCancelOrderRejectMessageCode == <<1101, 232>>  \* 0x44d, 0xe8
UnlockTradingMessageCode == <<1101, 132>>  \* 0x44d, 0x84
UnlockTradingAckMessageCode == <<1101, 234>>  \* 0x44d, 0xea
UnlockTradingRejectMessageCode == <<1101, 235>>  \* 0x44d, 0xeb
OrderFilledMessageCode == <<1101, 240>>  \* 0x44d, 0xf0
SpreadOrderFilledMessageCode == <<1101, 241>>  \* 0x44d, 0xf1
LastExecIdRequestMessageCode == <<1101, 150>>  \* 0x44d, 0x96
LastExecIdMessageCode == <<1101, 250>>  \* 0x44d, 0xfa
EventResendRequestMessageCode == <<1101, 152>>  \* 0x44d, 0x98
EventResendCompleteMessageCode == <<1101, 252>>  \* 0x44d, 0xfc
EventResendRejectMessageCode == <<1101, 253>>  \* 0x44d, 0xfd

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonConfMessageCode}, body : LogonConfMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {LoggedOutMessageCode}, body : LoggedOutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {TestRequestMessageCode}, body : TestRequestMessage ]
        \cup [ tag : {ResendRequestMessageCode}, body : ResendRequestMessage ]
        \cup [ tag : {GapFillMessageCode}, body : GapFillMessage ]
        \cup [ tag : {PingMessageCode}, body : PingMessage ]
        \cup [ tag : {PongMessageCode}, body : PongMessage ]
        \cup [ tag : {InstrumentInfoRequestMessageCode}, body : InstrumentInfoRequestMessage ]
        \cup [ tag : {InstrumentInfoMessageCode}, body : InstrumentInfoMessage ]
        \cup [ tag : {SetAccountMessageCode}, body : SetAccountMessage ]
        \cup [ tag : {SetTraderMessageCode}, body : SetTraderMessage ]
        \cup [ tag : {SetAckMessageCode}, body : SetAckMessage ]
        \cup [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {OrderEnteredMessageCode}, body : OrderEnteredMessage ]
        \cup [ tag : {ReplaceOrderMessageCode}, body : ReplaceOrderMessage ]
        \cup [ tag : {StreamOrderMessageCode}, body : StreamOrderMessage ]
        \cup [ tag : {OrderRejectMessageCode}, body : OrderRejectMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {OrderCanceledMessageCode}, body : OrderCanceledMessage ]
        \cup [ tag : {CancelOrderRejectMessageCode}, body : CancelOrderRejectMessage ]
        \cup [ tag : {MassCancelOrderMessageCode}, body : MassCancelOrderMessage ]
        \cup [ tag : {MassCancelOrderAckMessageCode}, body : MassCancelOrderAckMessage ]
        \cup [ tag : {MassCancelOrderRejectMessageCode}, body : MassCancelOrderRejectMessage ]
        \cup [ tag : {UnlockTradingMessageCode}, body : UnlockTradingMessage ]
        \cup [ tag : {UnlockTradingAckMessageCode}, body : UnlockTradingAckMessage ]
        \cup [ tag : {UnlockTradingRejectMessageCode}, body : UnlockTradingRejectMessage ]
        \cup [ tag : {OrderFilledMessageCode}, body : OrderFilledMessage ]
        \cup [ tag : {SpreadOrderFilledMessageCode}, body : SpreadOrderFilledMessage ]
        \cup [ tag : {LastExecIdRequestMessageCode}, body : LastExecIdRequestMessage ]
        \cup [ tag : {LastExecIdMessageCode}, body : LastExecIdMessage ]
        \cup [ tag : {EventResendRequestMessageCode}, body : EventResendRequestMessage ]
        \cup [ tag : {EventResendCompleteMessageCode}, body : EventResendCompleteMessage ]
        \cup [ tag : {EventResendRejectMessageCode}, body : EventResendRejectMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonConfMessageCode -> EncodeLogonConfMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = LoggedOutMessageCode -> EncodeLoggedOutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = TestRequestMessageCode -> EncodeTestRequestMessage(message.body)
      [] message.tag = ResendRequestMessageCode -> EncodeResendRequestMessage(message.body)
      [] message.tag = GapFillMessageCode -> EncodeGapFillMessage(message.body)
      [] message.tag = PingMessageCode -> EncodePingMessage(message.body)
      [] message.tag = PongMessageCode -> EncodePongMessage(message.body)
      [] message.tag = InstrumentInfoRequestMessageCode -> EncodeInstrumentInfoRequestMessage(message.body)
      [] message.tag = InstrumentInfoMessageCode -> EncodeInstrumentInfoMessage(message.body)
      [] message.tag = SetAccountMessageCode -> EncodeSetAccountMessage(message.body)
      [] message.tag = SetTraderMessageCode -> EncodeSetTraderMessage(message.body)
      [] message.tag = SetAckMessageCode -> EncodeSetAckMessage(message.body)
      [] message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = OrderEnteredMessageCode -> EncodeOrderEnteredMessage(message.body)
      [] message.tag = ReplaceOrderMessageCode -> EncodeReplaceOrderMessage(message.body)
      [] message.tag = StreamOrderMessageCode -> EncodeStreamOrderMessage(message.body)
      [] message.tag = OrderRejectMessageCode -> EncodeOrderRejectMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = OrderCanceledMessageCode -> EncodeOrderCanceledMessage(message.body)
      [] message.tag = CancelOrderRejectMessageCode -> EncodeCancelOrderRejectMessage(message.body)
      [] message.tag = MassCancelOrderMessageCode -> EncodeMassCancelOrderMessage(message.body)
      [] message.tag = MassCancelOrderAckMessageCode -> EncodeMassCancelOrderAckMessage(message.body)
      [] message.tag = MassCancelOrderRejectMessageCode -> EncodeMassCancelOrderRejectMessage(message.body)
      [] message.tag = UnlockTradingMessageCode -> EncodeUnlockTradingMessage(message.body)
      [] message.tag = UnlockTradingAckMessageCode -> EncodeUnlockTradingAckMessage(message.body)
      [] message.tag = UnlockTradingRejectMessageCode -> EncodeUnlockTradingRejectMessage(message.body)
      [] message.tag = OrderFilledMessageCode -> EncodeOrderFilledMessage(message.body)
      [] message.tag = SpreadOrderFilledMessageCode -> EncodeSpreadOrderFilledMessage(message.body)
      [] message.tag = LastExecIdRequestMessageCode -> EncodeLastExecIdRequestMessage(message.body)
      [] message.tag = LastExecIdMessageCode -> EncodeLastExecIdMessage(message.body)
      [] message.tag = EventResendRequestMessageCode -> EncodeEventResendRequestMessage(message.body)
      [] message.tag = EventResendCompleteMessageCode -> EncodeEventResendCompleteMessage(message.body)
      [] message.tag = EventResendRejectMessageCode -> EncodeEventResendRejectMessage(message.body)

DecodePayload(schemaId, templateId, bytes) ==
    LET read ==
            CASE <<schemaId, templateId>> = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] <<schemaId, templateId>> = LogonConfMessageCode -> DecodeLogonConfMessage(bytes)
              [] <<schemaId, templateId>> = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] <<schemaId, templateId>> = LoggedOutMessageCode -> DecodeLoggedOutMessage(bytes)
              [] <<schemaId, templateId>> = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] <<schemaId, templateId>> = TestRequestMessageCode -> DecodeTestRequestMessage(bytes)
              [] <<schemaId, templateId>> = ResendRequestMessageCode -> DecodeResendRequestMessage(bytes)
              [] <<schemaId, templateId>> = GapFillMessageCode -> DecodeGapFillMessage(bytes)
              [] <<schemaId, templateId>> = PingMessageCode -> DecodePingMessage(bytes)
              [] <<schemaId, templateId>> = PongMessageCode -> DecodePongMessage(bytes)
              [] <<schemaId, templateId>> = InstrumentInfoRequestMessageCode -> DecodeInstrumentInfoRequestMessage(bytes)
              [] <<schemaId, templateId>> = InstrumentInfoMessageCode -> DecodeInstrumentInfoMessage(bytes)
              [] <<schemaId, templateId>> = SetAccountMessageCode -> DecodeSetAccountMessage(bytes)
              [] <<schemaId, templateId>> = SetTraderMessageCode -> DecodeSetTraderMessage(bytes)
              [] <<schemaId, templateId>> = SetAckMessageCode -> DecodeSetAckMessage(bytes)
              [] <<schemaId, templateId>> = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] <<schemaId, templateId>> = OrderEnteredMessageCode -> DecodeOrderEnteredMessage(bytes)
              [] <<schemaId, templateId>> = ReplaceOrderMessageCode -> DecodeReplaceOrderMessage(bytes)
              [] <<schemaId, templateId>> = StreamOrderMessageCode -> DecodeStreamOrderMessage(bytes)
              [] <<schemaId, templateId>> = OrderRejectMessageCode -> DecodeOrderRejectMessage(bytes)
              [] <<schemaId, templateId>> = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] <<schemaId, templateId>> = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] <<schemaId, templateId>> = OrderCanceledMessageCode -> DecodeOrderCanceledMessage(bytes)
              [] <<schemaId, templateId>> = CancelOrderRejectMessageCode -> DecodeCancelOrderRejectMessage(bytes)
              [] <<schemaId, templateId>> = MassCancelOrderMessageCode -> DecodeMassCancelOrderMessage(bytes)
              [] <<schemaId, templateId>> = MassCancelOrderAckMessageCode -> DecodeMassCancelOrderAckMessage(bytes)
              [] <<schemaId, templateId>> = MassCancelOrderRejectMessageCode -> DecodeMassCancelOrderRejectMessage(bytes)
              [] <<schemaId, templateId>> = UnlockTradingMessageCode -> DecodeUnlockTradingMessage(bytes)
              [] <<schemaId, templateId>> = UnlockTradingAckMessageCode -> DecodeUnlockTradingAckMessage(bytes)
              [] <<schemaId, templateId>> = UnlockTradingRejectMessageCode -> DecodeUnlockTradingRejectMessage(bytes)
              [] <<schemaId, templateId>> = OrderFilledMessageCode -> DecodeOrderFilledMessage(bytes)
              [] <<schemaId, templateId>> = SpreadOrderFilledMessageCode -> DecodeSpreadOrderFilledMessage(bytes)
              [] <<schemaId, templateId>> = LastExecIdRequestMessageCode -> DecodeLastExecIdRequestMessage(bytes)
              [] <<schemaId, templateId>> = LastExecIdMessageCode -> DecodeLastExecIdMessage(bytes)
              [] <<schemaId, templateId>> = EventResendRequestMessageCode -> DecodeEventResendRequestMessage(bytes)
              [] <<schemaId, templateId>> = EventResendCompleteMessageCode -> DecodeEventResendCompleteMessage(bytes)
              [] <<schemaId, templateId>> = EventResendRejectMessageCode -> DecodeEventResendRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> <<schemaId, templateId>>, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonConfMessageCode, body |-> one] : one \in CheckedLogonConfMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> LoggedOutMessageCode, body |-> one] : one \in CheckedLoggedOutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }
        \cup { [tag |-> TestRequestMessageCode, body |-> one] : one \in CheckedTestRequestMessage }
        \cup { [tag |-> ResendRequestMessageCode, body |-> one] : one \in CheckedResendRequestMessage }
        \cup { [tag |-> GapFillMessageCode, body |-> one] : one \in CheckedGapFillMessage }
        \cup { [tag |-> PingMessageCode, body |-> one] : one \in CheckedPingMessage }
        \cup { [tag |-> PongMessageCode, body |-> one] : one \in CheckedPongMessage }
        \cup { [tag |-> InstrumentInfoRequestMessageCode, body |-> one] : one \in CheckedInstrumentInfoRequestMessage }
        \cup { [tag |-> InstrumentInfoMessageCode, body |-> one] : one \in CheckedInstrumentInfoMessage }
        \cup { [tag |-> SetAccountMessageCode, body |-> one] : one \in CheckedSetAccountMessage }
        \cup { [tag |-> SetTraderMessageCode, body |-> one] : one \in CheckedSetTraderMessage }
        \cup { [tag |-> SetAckMessageCode, body |-> one] : one \in CheckedSetAckMessage }
        \cup { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> OrderEnteredMessageCode, body |-> one] : one \in CheckedOrderEnteredMessage }
        \cup { [tag |-> ReplaceOrderMessageCode, body |-> one] : one \in CheckedReplaceOrderMessage }
        \cup { [tag |-> StreamOrderMessageCode, body |-> one] : one \in CheckedStreamOrderMessage }
        \cup { [tag |-> OrderRejectMessageCode, body |-> one] : one \in CheckedOrderRejectMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> OrderCanceledMessageCode, body |-> one] : one \in CheckedOrderCanceledMessage }
        \cup { [tag |-> CancelOrderRejectMessageCode, body |-> one] : one \in CheckedCancelOrderRejectMessage }
        \cup { [tag |-> MassCancelOrderMessageCode, body |-> one] : one \in CheckedMassCancelOrderMessage }
        \cup { [tag |-> MassCancelOrderAckMessageCode, body |-> one] : one \in CheckedMassCancelOrderAckMessage }
        \cup { [tag |-> MassCancelOrderRejectMessageCode, body |-> one] : one \in CheckedMassCancelOrderRejectMessage }
        \cup { [tag |-> UnlockTradingMessageCode, body |-> one] : one \in CheckedUnlockTradingMessage }
        \cup { [tag |-> UnlockTradingAckMessageCode, body |-> one] : one \in CheckedUnlockTradingAckMessage }
        \cup { [tag |-> UnlockTradingRejectMessageCode, body |-> one] : one \in CheckedUnlockTradingRejectMessage }
        \cup { [tag |-> OrderFilledMessageCode, body |-> one] : one \in CheckedOrderFilledMessage }
        \cup { [tag |-> SpreadOrderFilledMessageCode, body |-> one] : one \in CheckedSpreadOrderFilledMessage }
        \cup { [tag |-> LastExecIdRequestMessageCode, body |-> one] : one \in CheckedLastExecIdRequestMessage }
        \cup { [tag |-> LastExecIdMessageCode, body |-> one] : one \in CheckedLastExecIdMessage }
        \cup { [tag |-> EventResendRequestMessageCode, body |-> one] : one \in CheckedEventResendRequestMessage }
        \cup { [tag |-> EventResendCompleteMessageCode, body |-> one] : one \in CheckedEventResendCompleteMessage }
        \cup { [tag |-> EventResendRejectMessageCode, body |-> one] : one \in CheckedEventResendRejectMessage }

(***************************************************************************)
(* Sbe Message, framed by Message Length                                   *)
(***************************************************************************)

SbeMessage ==
    [ protocolId         : Sample(1),
      flags              : Sample(1),
      sequenceNumber     : Sample(4),
      lastProcessedSeqNo : Sample(4),
      reserved           : Sample(4),
      sendTimeEpochNanos : Sample(8),
      blockLength        : Sample(2),
      version            : Sample(2),
      payload            : Payload,
      padding            : SampleBytes ]

EncodeSbeMessageBody(message) ==
    message.sequenceNumber
        \o message.lastProcessedSeqNo
        \o message.reserved
        \o message.sendTimeEpochNanos
        \o message.blockLength
        \o EncodeUIntLE(message.payload.tag[2], 2)
        \o EncodeUIntLE(message.payload.tag[1], 2)
        \o message.version
        \o EncodePayload(message.payload)
        \o message.padding

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  message.protocolId \o message.flags \o EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeSbeMessage(bytes) ==
    LET protocolId == ReadBytes(bytes, 1) IN IF ~protocolId.ok THEN Fail ELSE
    LET flags == ReadBytes(protocolId.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET length == ReadUIntLE(flags.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET sequenceNumber == ReadBytes(framed, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET lastProcessedSeqNo == ReadBytes(sequenceNumber.rest, 4) IN IF ~lastProcessedSeqNo.ok THEN Fail ELSE
    LET reserved == ReadBytes(lastProcessedSeqNo.rest, 4) IN IF ~reserved.ok THEN Fail ELSE
    LET sendTimeEpochNanos == ReadBytes(reserved.rest, 8) IN IF ~sendTimeEpochNanos.ok THEN Fail ELSE
    LET blockLength == ReadBytes(sendTimeEpochNanos.rest, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadUIntLE(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(schemaId.value, templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    LET padding == Ok(payload.rest, << >>) IN IF ~padding.ok THEN Fail ELSE
    IF padding.rest # << >> THEN Fail ELSE
    Ok([ protocolId         |-> protocolId.value,
         flags              |-> flags.value,
         sequenceNumber     |-> sequenceNumber.value,
         lastProcessedSeqNo |-> lastProcessedSeqNo.value,
         reserved           |-> reserved.value,
         sendTimeEpochNanos |-> sendTimeEpochNanos.value,
         blockLength        |-> blockLength.value,
         version            |-> version.value,
         payload            |-> payload.value,
         padding            |-> padding.value ], beyond)

ZeroSbeMessage ==
    [ protocolId         |-> [i \in 1 .. 1 |-> 0],
      flags              |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber     |-> [i \in 1 .. 4 |-> 0],
      lastProcessedSeqNo |-> [i \in 1 .. 4 |-> 0],
      reserved           |-> [i \in 1 .. 4 |-> 0],
      sendTimeEpochNanos |-> [i \in 1 .. 8 |-> 0],
      blockLength        |-> [i \in 1 .. 2 |-> 0],
      version            |-> [i \in 1 .. 2 |-> 0],
      payload            |-> ZeroPayload,
      padding            |-> << >> ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.protocolId = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSbeMessage EXCEPT !.lastProcessedSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSbeMessage EXCEPT !.reserved = one] : one \in Sample(4) }
        \cup { [ZeroSbeMessage EXCEPT !.sendTimeEpochNanos = one] : one \in Sample(8) }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroSbeMessage EXCEPT !.padding = one] : one \in SampleBytes }

(* A run of Sbe Message, written one after another *)
RECURSIVE EncodeSbeMessageList(_)
EncodeSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSbeMessage(Head(messages)) \o EncodeSbeMessageList(Tail(messages))

(* As many Sbe Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSbeMessageAll(_)
ReadSbeMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSbeMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sbe Message of each kind, for the lists that carry them *)
OneSbeMessage ==
    { [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogonConfMessageCode, body |-> ZeroLogonConfMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LoggedOutMessageCode, body |-> ZeroLoggedOutMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> ZeroHeartbeatMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TestRequestMessageCode, body |-> ZeroTestRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ResendRequestMessageCode, body |-> ZeroResendRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> GapFillMessageCode, body |-> ZeroGapFillMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> PingMessageCode, body |-> ZeroPingMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> PongMessageCode, body |-> ZeroPongMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> InstrumentInfoRequestMessageCode, body |-> ZeroInstrumentInfoRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> InstrumentInfoMessageCode, body |-> ZeroInstrumentInfoMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SetAccountMessageCode, body |-> ZeroSetAccountMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SetTraderMessageCode, body |-> ZeroSetTraderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SetAckMessageCode, body |-> ZeroSetAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> NewOrderMessageCode, body |-> ZeroNewOrderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderEnteredMessageCode, body |-> ZeroOrderEnteredMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ReplaceOrderMessageCode, body |-> ZeroReplaceOrderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> StreamOrderMessageCode, body |-> ZeroStreamOrderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderRejectMessageCode, body |-> ZeroOrderRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderReplacedMessageCode, body |-> ZeroOrderReplacedMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> CancelOrderMessageCode, body |-> ZeroCancelOrderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderCanceledMessageCode, body |-> ZeroOrderCanceledMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> CancelOrderRejectMessageCode, body |-> ZeroCancelOrderRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassCancelOrderMessageCode, body |-> ZeroMassCancelOrderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassCancelOrderAckMessageCode, body |-> ZeroMassCancelOrderAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MassCancelOrderRejectMessageCode, body |-> ZeroMassCancelOrderRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> UnlockTradingMessageCode, body |-> ZeroUnlockTradingMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> UnlockTradingAckMessageCode, body |-> ZeroUnlockTradingAckMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> UnlockTradingRejectMessageCode, body |-> ZeroUnlockTradingRejectMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderFilledMessageCode, body |-> ZeroOrderFilledMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SpreadOrderFilledMessageCode, body |-> ZeroSpreadOrderFilledMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LastExecIdRequestMessageCode, body |-> ZeroLastExecIdRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LastExecIdMessageCode, body |-> ZeroLastExecIdMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> EventResendRequestMessageCode, body |-> ZeroEventResendRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> EventResendCompleteMessageCode, body |-> ZeroEventResendCompleteMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> EventResendRejectMessageCode, body |-> ZeroEventResendRejectMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sbeMessage : SampleLists(OneSbeMessage) ]

EncodePacket(message) ==
    EncodeSbeMessageList(message.sbeMessage)

DecodePacket(bytes) ==
    LET sbeMessage == ReadSbeMessageAll(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroPacket ==
    [ sbeMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sbeMessage = one] : one \in SampleLists(OneSbeMessage) }

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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Conf Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonConfMessage ==
    \A message \in CheckedLogonConfMessage :
        LET read == DecodeLogonConfMessage(EncodeLogonConfMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logged Out Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoggedOutMessage ==
    \A message \in CheckedLoggedOutMessage :
        LET read == DecodeLoggedOutMessage(EncodeLoggedOutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatMessage ==
    \A message \in CheckedHeartbeatMessage :
        LET read == DecodeHeartbeatMessage(EncodeHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTestRequestMessage ==
    \A message \in CheckedTestRequestMessage :
        LET read == DecodeTestRequestMessage(EncodeTestRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Resend Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResendRequestMessage ==
    \A message \in CheckedResendRequestMessage :
        LET read == DecodeResendRequestMessage(EncodeResendRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gap Fill Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGapFillMessage ==
    \A message \in CheckedGapFillMessage :
        LET read == DecodeGapFillMessage(EncodeGapFillMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Data decodes back to what was encoded, and leaves nothing over *)
RoundTripData ==
    \A message \in CheckedData :
        LET read == DecodeData(EncodeData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPingMessage ==
    \A message \in CheckedPingMessage :
        LET read == DecodePingMessage(EncodePingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Data decodes back to what was encoded, and leaves nothing over *)
RoundTripData2 ==
    \A message \in CheckedData2 :
        LET read == DecodeData2(EncodeData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pong Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPongMessage ==
    \A message \in CheckedPongMessage :
        LET read == DecodePongMessage(EncodePongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfoRequestMessage ==
    \A message \in CheckedInstrumentInfoRequestMessage :
        LET read == DecodeInstrumentInfoRequestMessage(EncodeInstrumentInfoRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfoMessage ==
    \A message \in CheckedInstrumentInfoMessage :
        LET read == DecodeInstrumentInfoMessage(EncodeInstrumentInfoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Set Account Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSetAccountMessage ==
    \A message \in CheckedSetAccountMessage :
        LET read == DecodeSetAccountMessage(EncodeSetAccountMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Set Trader Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSetTraderMessage ==
    \A message \in CheckedSetTraderMessage :
        LET read == DecodeSetTraderMessage(EncodeSetTraderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Set Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSetAckMessage ==
    \A message \in CheckedSetAckMessage :
        LET read == DecodeSetAckMessage(EncodeSetAckMessage(message))
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

(* Every Order Entered Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEnteredMessage ==
    \A message \in CheckedOrderEnteredMessage :
        LET read == DecodeOrderEnteredMessage(EncodeOrderEnteredMessage(message))
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

(* Every Stream Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamOrderMessage ==
    \A message \in CheckedStreamOrderMessage :
        LET read == DecodeStreamOrderMessage(EncodeStreamOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRejectMessage ==
    \A message \in CheckedOrderRejectMessage :
        LET read == DecodeOrderRejectMessage(EncodeOrderRejectMessage(message))
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

(* Every Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderMessage ==
    \A message \in CheckedCancelOrderMessage :
        LET read == DecodeCancelOrderMessage(EncodeCancelOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCanceledMessage ==
    \A message \in CheckedOrderCanceledMessage :
        LET read == DecodeOrderCanceledMessage(EncodeOrderCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderRejectMessage ==
    \A message \in CheckedCancelOrderRejectMessage :
        LET read == DecodeCancelOrderRejectMessage(EncodeCancelOrderRejectMessage(message))
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

(* Every Mass Cancel Order Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelOrderAckMessage ==
    \A message \in CheckedMassCancelOrderAckMessage :
        LET read == DecodeMassCancelOrderAckMessage(EncodeMassCancelOrderAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Order Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelOrderRejectMessage ==
    \A message \in CheckedMassCancelOrderRejectMessage :
        LET read == DecodeMassCancelOrderRejectMessage(EncodeMassCancelOrderRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unlock Trading Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnlockTradingMessage ==
    \A message \in CheckedUnlockTradingMessage :
        LET read == DecodeUnlockTradingMessage(EncodeUnlockTradingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unlock Trading Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnlockTradingAckMessage ==
    \A message \in CheckedUnlockTradingAckMessage :
        LET read == DecodeUnlockTradingAckMessage(EncodeUnlockTradingAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unlock Trading Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnlockTradingRejectMessage ==
    \A message \in CheckedUnlockTradingRejectMessage :
        LET read == DecodeUnlockTradingRejectMessage(EncodeUnlockTradingRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderFilledMessage ==
    \A message \in CheckedOrderFilledMessage :
        LET read == DecodeOrderFilledMessage(EncodeOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Order Filled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadOrderFilledMessage ==
    \A message \in CheckedSpreadOrderFilledMessage :
        LET read == DecodeSpreadOrderFilledMessage(EncodeSpreadOrderFilledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Last Exec Id Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastExecIdRequestMessage ==
    \A message \in CheckedLastExecIdRequestMessage :
        LET read == DecodeLastExecIdRequestMessage(EncodeLastExecIdRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Last Exec Id Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastExecIdMessage ==
    \A message \in CheckedLastExecIdMessage :
        LET read == DecodeLastExecIdMessage(EncodeLastExecIdMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Event Resend Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEventResendRequestMessage ==
    \A message \in CheckedEventResendRequestMessage :
        LET read == DecodeEventResendRequestMessage(EncodeEventResendRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Event Resend Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEventResendCompleteMessage ==
    \A message \in CheckedEventResendCompleteMessage :
        LET read == DecodeEventResendCompleteMessage(EncodeEventResendCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Event Resend Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEventResendRejectMessage ==
    \A message \in CheckedEventResendRejectMessage :
        LET read == DecodeEventResendRejectMessage(EncodeEventResendRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Schema Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag[1], message.tag[2], EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 3, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
