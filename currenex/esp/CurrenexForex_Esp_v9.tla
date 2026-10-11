----------------------- MODULE CurrenexForex_Esp_v9 ------------------------
(***************************************************************************)
(* Currenex Executable Streaming Prices v9                                 *)
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
(* Logon: 44 bytes                                                         *)
(***************************************************************************)

Logon ==
    [ userId    : Sample(20),
      password  : Sample(20),
      sessionId : Sample(4) ]

EncodeLogon(message) ==
    message.userId
        \o message.password
        \o message.sessionId

DecodeLogon(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET password == ReadBytes(userId.rest, 20) IN IF ~password.ok THEN Fail ELSE
    LET sessionId == ReadBytes(password.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ userId    |-> userId.value,
         password  |-> password.value,
         sessionId |-> sessionId.value ], sessionId.rest)

ZeroLogon ==
    [ userId    |-> [i \in 1 .. 20 |-> 0],
      password  |-> [i \in 1 .. 20 |-> 0],
      sessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Logon at zero, then each field in turn at the values it is checked at *)
CheckedLogon ==
    { ZeroLogon }
        \cup { [ZeroLogon EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogon EXCEPT !.password = one] : one \in Sample(20) }
        \cup { [ZeroLogon EXCEPT !.sessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout: 27 bytes                                                        *)
(***************************************************************************)

Logout ==
    [ userId    : Sample(20),
      sessionId : Sample(4),
      reason    : Sample(3) ]

EncodeLogout(message) ==
    message.userId
        \o message.sessionId
        \o message.reason

DecodeLogout(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(userId.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET reason == ReadBytes(sessionId.rest, 3) IN IF ~reason.ok THEN Fail ELSE
    Ok([ userId    |-> userId.value,
         sessionId |-> sessionId.value,
         reason    |-> reason.value ], reason.rest)

ZeroLogout ==
    [ userId    |-> [i \in 1 .. 20 |-> 0],
      sessionId |-> [i \in 1 .. 4 |-> 0],
      reason    |-> [i \in 1 .. 3 |-> 0] ]

(* Logout at zero, then each field in turn at the values it is checked at *)
CheckedLogout ==
    { ZeroLogout }
        \cup { [ZeroLogout EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogout EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroLogout EXCEPT !.reason = one] : one \in Sample(3) }

(***************************************************************************)
(* Heartbeat: 4 bytes                                                      *)
(***************************************************************************)

Heartbeat ==
    [ sessionId : Sample(4) ]

EncodeHeartbeat(message) ==
    message.sessionId

DecodeHeartbeat(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroHeartbeat ==
    [ sessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeat ==
    { ZeroHeartbeat }
        \cup { [ZeroHeartbeat EXCEPT !.sessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Info: 35 bytes                                               *)
(***************************************************************************)

InstrumentInfo ==
    [ sessionId       : Sample(4),
      instrumentIndex : Sample(2),
      instrumentType  : Sample(1),
      instrumentId    : Sample(20),
      settlementDate  : Sample(8) ]

EncodeInstrumentInfo(message) ==
    message.sessionId
        \o message.instrumentIndex
        \o message.instrumentType
        \o message.instrumentId
        \o message.settlementDate

DecodeInstrumentInfo(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(sessionId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(instrumentIndex.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentType.rest, 20) IN IF ~instrumentId.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(instrumentId.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         instrumentIndex |-> instrumentIndex.value,
         instrumentType  |-> instrumentType.value,
         instrumentId    |-> instrumentId.value,
         settlementDate  |-> settlementDate.value ], settlementDate.rest)

ZeroInstrumentInfo ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      instrumentType  |-> [i \in 1 .. 1 |-> 0],
      instrumentId    |-> [i \in 1 .. 20 |-> 0],
      settlementDate  |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Info at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfo ==
    { ZeroInstrumentInfo }
        \cup { [ZeroInstrumentInfo EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentId = one] : one \in Sample(20) }
        \cup { [ZeroInstrumentInfo EXCEPT !.settlementDate = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Info Ack: 6 bytes                                            *)
(***************************************************************************)

InstrumentInfoAck ==
    [ sessionId       : Sample(4),
      instrumentIndex : Sample(2) ]

EncodeInstrumentInfoAck(message) ==
    message.sessionId
        \o message.instrumentIndex

DecodeInstrumentInfoAck(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(sessionId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         instrumentIndex |-> instrumentIndex.value ], instrumentIndex.rest)

ZeroInstrumentInfoAck ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Info Ack at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfoAck ==
    { ZeroInstrumentInfoAck }
        \cup { [ZeroInstrumentInfoAck EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentInfoAck EXCEPT !.instrumentIndex = one] : one \in Sample(2) }

(***************************************************************************)
(* Subscription Request: 8 bytes                                           *)
(***************************************************************************)

SubscriptionRequest ==
    [ sessionId         : Sample(4),
      subscriptionType  : Sample(1),
      instrumentIndex   : Sample(2),
      subscribeToTicker : Sample(1) ]

EncodeSubscriptionRequest(message) ==
    message.sessionId
        \o message.subscriptionType
        \o message.instrumentIndex
        \o message.subscribeToTicker

DecodeSubscriptionRequest(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET subscriptionType == ReadBytes(sessionId.rest, 1) IN IF ~subscriptionType.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(subscriptionType.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET subscribeToTicker == ReadBytes(instrumentIndex.rest, 1) IN IF ~subscribeToTicker.ok THEN Fail ELSE
    Ok([ sessionId         |-> sessionId.value,
         subscriptionType  |-> subscriptionType.value,
         instrumentIndex   |-> instrumentIndex.value,
         subscribeToTicker |-> subscribeToTicker.value ], subscribeToTicker.rest)

ZeroSubscriptionRequest ==
    [ sessionId         |-> [i \in 1 .. 4 |-> 0],
      subscriptionType  |-> [i \in 1 .. 1 |-> 0],
      instrumentIndex   |-> [i \in 1 .. 2 |-> 0],
      subscribeToTicker |-> [i \in 1 .. 1 |-> 0] ]

(* Subscription Request at zero, then each field in turn at the values it is checked at *)
CheckedSubscriptionRequest ==
    { ZeroSubscriptionRequest }
        \cup { [ZeroSubscriptionRequest EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionRequest EXCEPT !.subscriptionType = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionRequest EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionRequest EXCEPT !.subscribeToTicker = one] : one \in Sample(1) }

(***************************************************************************)
(* Subscription Reply: 57 bytes                                            *)
(***************************************************************************)

SubscriptionReply ==
    [ sessionId       : Sample(4),
      instrumentIndex : Sample(2),
      replyType       : Sample(1),
      rejectReason    : Sample(50) ]

EncodeSubscriptionReply(message) ==
    message.sessionId
        \o message.instrumentIndex
        \o message.replyType
        \o message.rejectReason

DecodeSubscriptionReply(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(sessionId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET replyType == ReadBytes(instrumentIndex.rest, 1) IN IF ~replyType.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(replyType.rest, 50) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         instrumentIndex |-> instrumentIndex.value,
         replyType       |-> replyType.value,
         rejectReason    |-> rejectReason.value ], rejectReason.rest)

ZeroSubscriptionReply ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      replyType       |-> [i \in 1 .. 1 |-> 0],
      rejectReason    |-> [i \in 1 .. 50 |-> 0] ]

(* Subscription Reply at zero, then each field in turn at the values it is checked at *)
CheckedSubscriptionReply ==
    { ZeroSubscriptionReply }
        \cup { [ZeroSubscriptionReply EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionReply EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionReply EXCEPT !.replyType = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionReply EXCEPT !.rejectReason = one] : one \in Sample(50) }

(***************************************************************************)
(* Price Message: 29 bytes                                                 *)
(***************************************************************************)

PriceMessage ==
    [ instrumentIndex : Sample(2),
      priceId         : Sample(1),
      side            : Sample(1),
      maxAmount       : Sample(8),
      minAmount       : Sample(8),
      price           : Sample(4),
      attributed      : Sample(1),
      priceProvider   : Sample(4) ]

EncodePriceMessage(message) ==
    message.instrumentIndex
        \o message.priceId
        \o message.side
        \o message.maxAmount
        \o message.minAmount
        \o message.price
        \o message.attributed
        \o message.priceProvider

DecodePriceMessage(bytes) ==
    LET instrumentIndex == ReadBytes(bytes, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET priceId == ReadBytes(instrumentIndex.rest, 1) IN IF ~priceId.ok THEN Fail ELSE
    LET side == ReadBytes(priceId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET maxAmount == ReadBytes(side.rest, 8) IN IF ~maxAmount.ok THEN Fail ELSE
    LET minAmount == ReadBytes(maxAmount.rest, 8) IN IF ~minAmount.ok THEN Fail ELSE
    LET price == ReadBytes(minAmount.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET attributed == ReadBytes(price.rest, 1) IN IF ~attributed.ok THEN Fail ELSE
    LET priceProvider == ReadBytes(attributed.rest, 4) IN IF ~priceProvider.ok THEN Fail ELSE
    Ok([ instrumentIndex |-> instrumentIndex.value,
         priceId         |-> priceId.value,
         side            |-> side.value,
         maxAmount       |-> maxAmount.value,
         minAmount       |-> minAmount.value,
         price           |-> price.value,
         attributed      |-> attributed.value,
         priceProvider   |-> priceProvider.value ], priceProvider.rest)

ZeroPriceMessage ==
    [ instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      priceId         |-> [i \in 1 .. 1 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      maxAmount       |-> [i \in 1 .. 8 |-> 0],
      minAmount       |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      attributed      |-> [i \in 1 .. 1 |-> 0],
      priceProvider   |-> [i \in 1 .. 4 |-> 0] ]

(* Price Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceMessage ==
    { ZeroPriceMessage }
        \cup { [ZeroPriceMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroPriceMessage EXCEPT !.priceId = one] : one \in Sample(1) }
        \cup { [ZeroPriceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroPriceMessage EXCEPT !.maxAmount = one] : one \in Sample(8) }
        \cup { [ZeroPriceMessage EXCEPT !.minAmount = one] : one \in Sample(8) }
        \cup { [ZeroPriceMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroPriceMessage EXCEPT !.attributed = one] : one \in Sample(1) }
        \cup { [ZeroPriceMessage EXCEPT !.priceProvider = one] : one \in Sample(4) }

(***************************************************************************)
(* Price Cancel Message: 3 bytes                                           *)
(***************************************************************************)

PriceCancelMessage ==
    [ instrumentIndex : Sample(2),
      priceId         : Sample(1) ]

EncodePriceCancelMessage(message) ==
    message.instrumentIndex
        \o message.priceId

DecodePriceCancelMessage(bytes) ==
    LET instrumentIndex == ReadBytes(bytes, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET priceId == ReadBytes(instrumentIndex.rest, 1) IN IF ~priceId.ok THEN Fail ELSE
    Ok([ instrumentIndex |-> instrumentIndex.value,
         priceId         |-> priceId.value ], priceId.rest)

ZeroPriceCancelMessage ==
    [ instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      priceId         |-> [i \in 1 .. 1 |-> 0] ]

(* Price Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceCancelMessage ==
    { ZeroPriceCancelMessage }
        \cup { [ZeroPriceCancelMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroPriceCancelMessage EXCEPT !.priceId = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Ticker Message: 15 bytes                                          *)
(***************************************************************************)

TradeTickerMessage ==
    [ instrumentIndex : Sample(2),
      rate            : Sample(4),
      tickerType      : Sample(1),
      transactTime    : Sample(8) ]

EncodeTradeTickerMessage(message) ==
    message.instrumentIndex
        \o message.rate
        \o message.tickerType
        \o message.transactTime

DecodeTradeTickerMessage(bytes) ==
    LET instrumentIndex == ReadBytes(bytes, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET rate == ReadBytes(instrumentIndex.rest, 4) IN IF ~rate.ok THEN Fail ELSE
    LET tickerType == ReadBytes(rate.rest, 1) IN IF ~tickerType.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tickerType.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentIndex |-> instrumentIndex.value,
         rate            |-> rate.value,
         tickerType      |-> tickerType.value,
         transactTime    |-> transactTime.value ], transactTime.rest)

ZeroTradeTickerMessage ==
    [ instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      rate            |-> [i \in 1 .. 4 |-> 0],
      tickerType      |-> [i \in 1 .. 1 |-> 0],
      transactTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Ticker Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeTickerMessage ==
    { ZeroTradeTickerMessage }
        \cup { [ZeroTradeTickerMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.rate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.tickerType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Reject Message: 55 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ sessionId     : Sample(4),
      rejectMsgType : Sample(1),
      rejectReason  : Sample(50) ]

EncodeRejectMessage(message) ==
    message.sessionId
        \o message.rejectMsgType
        \o message.rejectReason

DecodeRejectMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET rejectMsgType == ReadBytes(sessionId.rest, 1) IN IF ~rejectMsgType.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(rejectMsgType.rest, 50) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ sessionId     |-> sessionId.value,
         rejectMsgType |-> rejectMsgType.value,
         rejectReason  |-> rejectReason.value ], rejectReason.rest)

ZeroRejectMessage ==
    [ sessionId     |-> [i \in 1 .. 4 |-> 0],
      rejectMsgType |-> [i \in 1 .. 1 |-> 0],
      rejectReason  |-> [i \in 1 .. 50 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectMsgType = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectReason = one] : one \in Sample(50) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

LogonCode == 65  \* "A"
LogoutCode == 66  \* "B"
HeartbeatCode == 67  \* "C"
InstrumentInfoCode == 68  \* "D"
InstrumentInfoAckCode == 69  \* "E"
SubscriptionRequestCode == 70  \* "F"
SubscriptionReplyCode == 71  \* "G"
PriceMessageCode == 72  \* "H"
PriceCancelMessageCode == 73  \* "I"
TradeTickerMessageCode == 74  \* "J"
RejectMessageCode == 75  \* "K"

MessageBody ==
    [ tag : {LogonCode}, body : Logon ]
        \cup [ tag : {LogoutCode}, body : Logout ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {InstrumentInfoCode}, body : InstrumentInfo ]
        \cup [ tag : {InstrumentInfoAckCode}, body : InstrumentInfoAck ]
        \cup [ tag : {SubscriptionRequestCode}, body : SubscriptionRequest ]
        \cup [ tag : {SubscriptionReplyCode}, body : SubscriptionReply ]
        \cup [ tag : {PriceMessageCode}, body : PriceMessage ]
        \cup [ tag : {PriceCancelMessageCode}, body : PriceCancelMessage ]
        \cup [ tag : {TradeTickerMessageCode}, body : TradeTickerMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = LogonCode -> EncodeLogon(message.body)
      [] message.tag = LogoutCode -> EncodeLogout(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = InstrumentInfoCode -> EncodeInstrumentInfo(message.body)
      [] message.tag = InstrumentInfoAckCode -> EncodeInstrumentInfoAck(message.body)
      [] message.tag = SubscriptionRequestCode -> EncodeSubscriptionRequest(message.body)
      [] message.tag = SubscriptionReplyCode -> EncodeSubscriptionReply(message.body)
      [] message.tag = PriceMessageCode -> EncodePriceMessage(message.body)
      [] message.tag = PriceCancelMessageCode -> EncodePriceCancelMessage(message.body)
      [] message.tag = TradeTickerMessageCode -> EncodeTradeTickerMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = LogonCode -> DecodeLogon(bytes)
              [] tag = LogoutCode -> DecodeLogout(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = InstrumentInfoCode -> DecodeInstrumentInfo(bytes)
              [] tag = InstrumentInfoAckCode -> DecodeInstrumentInfoAck(bytes)
              [] tag = SubscriptionRequestCode -> DecodeSubscriptionRequest(bytes)
              [] tag = SubscriptionReplyCode -> DecodeSubscriptionReply(bytes)
              [] tag = PriceMessageCode -> DecodePriceMessage(bytes)
              [] tag = PriceCancelMessageCode -> DecodePriceCancelMessage(bytes)
              [] tag = TradeTickerMessageCode -> DecodeTradeTickerMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> LogonCode, body |-> ZeroLogon]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> LogonCode, body |-> one] : one \in CheckedLogon }
        \cup { [tag |-> LogoutCode, body |-> one] : one \in CheckedLogout }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> InstrumentInfoCode, body |-> one] : one \in CheckedInstrumentInfo }
        \cup { [tag |-> InstrumentInfoAckCode, body |-> one] : one \in CheckedInstrumentInfoAck }
        \cup { [tag |-> SubscriptionRequestCode, body |-> one] : one \in CheckedSubscriptionRequest }
        \cup { [tag |-> SubscriptionReplyCode, body |-> one] : one \in CheckedSubscriptionReply }
        \cup { [tag |-> PriceMessageCode, body |-> one] : one \in CheckedPriceMessage }
        \cup { [tag |-> PriceCancelMessageCode, body |-> one] : one \in CheckedPriceCancelMessage }
        \cup { [tag |-> TradeTickerMessageCode, body |-> one] : one \in CheckedTradeTickerMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ itchSoh        : Sample(1),
      sequenceNumber : Sample(4),
      timestamp      : Sample(4),
      messageBody    : MessageBody,
      itchEtx        : Sample(1) ]

EncodePacket(message) ==
    message.itchSoh
        \o message.sequenceNumber
        \o message.timestamp
        \o EncodeUIntBE(message.messageBody.tag, 1)
        \o EncodeMessageBody(message.messageBody)
        \o message.itchEtx

DecodePacket(bytes) ==
    LET itchSoh == ReadBytes(bytes, 1) IN IF ~itchSoh.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(itchSoh.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sequenceNumber.rest, 4) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageBody == DecodeMessageBody(messageType.value, messageType.rest) IN IF ~messageBody.ok THEN Fail ELSE
    LET itchEtx == ReadBytes(messageBody.rest, 1) IN IF ~itchEtx.ok THEN Fail ELSE
    Ok([ itchSoh        |-> itchSoh.value,
         sequenceNumber |-> sequenceNumber.value,
         timestamp      |-> timestamp.value,
         messageBody    |-> messageBody.value,
         itchEtx        |-> itchEtx.value ], itchEtx.rest)

ZeroPacket ==
    [ itchSoh        |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      timestamp      |-> [i \in 1 .. 4 |-> 0],
      messageBody    |-> ZeroMessageBody,
      itchEtx        |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.itchSoh = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.timestamp = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroPacket EXCEPT !.itchEtx = one] : one \in Sample(1) }

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

(* Every Logon decodes back to what was encoded, and leaves nothing over *)
RoundTripLogon ==
    \A message \in CheckedLogon :
        LET read == DecodeLogon(EncodeLogon(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout decodes back to what was encoded, and leaves nothing over *)
RoundTripLogout ==
    \A message \in CheckedLogout :
        LET read == DecodeLogout(EncodeLogout(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET read == DecodeHeartbeat(EncodeHeartbeat(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfo ==
    \A message \in CheckedInstrumentInfo :
        LET read == DecodeInstrumentInfo(EncodeInstrumentInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfoAck ==
    \A message \in CheckedInstrumentInfoAck :
        LET read == DecodeInstrumentInfoAck(EncodeInstrumentInfoAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscription Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscriptionRequest ==
    \A message \in CheckedSubscriptionRequest :
        LET read == DecodeSubscriptionRequest(EncodeSubscriptionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscription Reply decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscriptionReply ==
    \A message \in CheckedSubscriptionReply :
        LET read == DecodeSubscriptionReply(EncodeSubscriptionReply(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceMessage ==
    \A message \in CheckedPriceMessage :
        LET read == DecodePriceMessage(EncodePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceCancelMessage ==
    \A message \in CheckedPriceCancelMessage :
        LET read == DecodePriceCancelMessage(EncodePriceCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Ticker Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeTickerMessage ==
    \A message \in CheckedTradeTickerMessage :
        LET read == DecodeTradeTickerMessage(EncodeTradeTickerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
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

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET read == DecodeMessageBody(message.tag, EncodeMessageBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
