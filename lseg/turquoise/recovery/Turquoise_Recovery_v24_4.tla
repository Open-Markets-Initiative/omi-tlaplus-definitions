--------------------- MODULE Turquoise_Recovery_v24_4 ----------------------
(***************************************************************************)
(* London Stock Exchange Recovery v24.4                                    *)
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
(* Note: Top Of Book Flags is a bit field set, checked as its 1 byte       *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Trade Flags is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Allowed Book Types is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
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
(* Login Request Message: 8 bytes                                          *)
(***************************************************************************)

LoginRequestMessage ==
    [ username : Sample(8) ]

EncodeLoginRequestMessage(message) ==
    message.username

DecodeLoginRequestMessage(bytes) ==
    LET username == ReadBytes(bytes, 8) IN IF ~username.ok THEN Fail ELSE
    Ok([ username |-> username.value ], username.rest)

ZeroLoginRequestMessage ==
    [ username |-> [i \in 1 .. 8 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.username = one] : one \in Sample(8) }

(***************************************************************************)
(* Recovery Request Message: 27 bytes                                      *)
(***************************************************************************)

RecoveryRequestMessage ==
    [ requestLevel         : Sample(1),
      instrument           : Sample(8),
      groupId              : Sample(6),
      requestOrderBookType : Sample(1),
      sourceVenue          : Sample(2),
      recoveryType         : Sample(1),
      sequenceNumber       : Sample(4),
      requestId            : Sample(4) ]

EncodeRecoveryRequestMessage(message) ==
    message.requestLevel
        \o message.instrument
        \o message.groupId
        \o message.requestOrderBookType
        \o message.sourceVenue
        \o message.recoveryType
        \o message.sequenceNumber
        \o message.requestId

DecodeRecoveryRequestMessage(bytes) ==
    LET requestLevel == ReadBytes(bytes, 1) IN IF ~requestLevel.ok THEN Fail ELSE
    LET instrument == ReadBytes(requestLevel.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET groupId == ReadBytes(instrument.rest, 6) IN IF ~groupId.ok THEN Fail ELSE
    LET requestOrderBookType == ReadBytes(groupId.rest, 1) IN IF ~requestOrderBookType.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(requestOrderBookType.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET recoveryType == ReadBytes(sourceVenue.rest, 1) IN IF ~recoveryType.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(recoveryType.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET requestId == ReadBytes(sequenceNumber.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ requestLevel         |-> requestLevel.value,
         instrument           |-> instrument.value,
         groupId              |-> groupId.value,
         requestOrderBookType |-> requestOrderBookType.value,
         sourceVenue          |-> sourceVenue.value,
         recoveryType         |-> recoveryType.value,
         sequenceNumber       |-> sequenceNumber.value,
         requestId            |-> requestId.value ], requestId.rest)

ZeroRecoveryRequestMessage ==
    [ requestLevel         |-> [i \in 1 .. 1 |-> 0],
      instrument           |-> [i \in 1 .. 8 |-> 0],
      groupId              |-> [i \in 1 .. 6 |-> 0],
      requestOrderBookType |-> [i \in 1 .. 1 |-> 0],
      sourceVenue          |-> [i \in 1 .. 2 |-> 0],
      recoveryType         |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      requestId            |-> [i \in 1 .. 4 |-> 0] ]

(* Recovery Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRecoveryRequestMessage ==
    { ZeroRecoveryRequestMessage }
        \cup { [ZeroRecoveryRequestMessage EXCEPT !.requestLevel = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryRequestMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryRequestMessage EXCEPT !.groupId = one] : one \in Sample(6) }
        \cup { [ZeroRecoveryRequestMessage EXCEPT !.requestOrderBookType = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryRequestMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroRecoveryRequestMessage EXCEPT !.recoveryType = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }

(***************************************************************************)
(* Login Response Message: 1 bytes                                         *)
(***************************************************************************)

LoginResponseMessage ==
    [ loginStatus : Sample(1) ]

EncodeLoginResponseMessage(message) ==
    message.loginStatus

DecodeLoginResponseMessage(bytes) ==
    LET loginStatus == ReadBytes(bytes, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    Ok([ loginStatus |-> loginStatus.value ], loginStatus.rest)

ZeroLoginResponseMessage ==
    [ loginStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.loginStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Recovery Response Message: 13 bytes                                     *)
(***************************************************************************)

RecoveryResponseMessage ==
    [ sequenceNumber : Sample(4),
      count          : Sample(4),
      recoveryStatus : Sample(1),
      requestId      : Sample(4) ]

EncodeRecoveryResponseMessage(message) ==
    message.sequenceNumber
        \o message.count
        \o message.recoveryStatus
        \o message.requestId

DecodeRecoveryResponseMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET count == ReadBytes(sequenceNumber.rest, 4) IN IF ~count.ok THEN Fail ELSE
    LET recoveryStatus == ReadBytes(count.rest, 1) IN IF ~recoveryStatus.ok THEN Fail ELSE
    LET requestId == ReadBytes(recoveryStatus.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         count          |-> count.value,
         recoveryStatus |-> recoveryStatus.value,
         requestId      |-> requestId.value ], requestId.rest)

ZeroRecoveryResponseMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      count          |-> [i \in 1 .. 4 |-> 0],
      recoveryStatus |-> [i \in 1 .. 1 |-> 0],
      requestId      |-> [i \in 1 .. 4 |-> 0] ]

(* Recovery Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRecoveryResponseMessage ==
    { ZeroRecoveryResponseMessage }
        \cup { [ZeroRecoveryResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryResponseMessage EXCEPT !.count = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryResponseMessage EXCEPT !.recoveryStatus = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryResponseMessage EXCEPT !.requestId = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay And Recovery Complete Message: 5 bytes                           *)
(***************************************************************************)

ReplayAndRecoveryCompleteMessage ==
    [ requestId     : Sample(4),
      tradingStatus : Sample(1) ]

EncodeReplayAndRecoveryCompleteMessage(message) ==
    message.requestId
        \o message.tradingStatus

DecodeReplayAndRecoveryCompleteMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(requestId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    Ok([ requestId     |-> requestId.value,
         tradingStatus |-> tradingStatus.value ], tradingStatus.rest)

ZeroReplayAndRecoveryCompleteMessage ==
    [ requestId     |-> [i \in 1 .. 4 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Replay And Recovery Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayAndRecoveryCompleteMessage ==
    { ZeroReplayAndRecoveryCompleteMessage }
        \cup { [ZeroReplayAndRecoveryCompleteMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroReplayAndRecoveryCompleteMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp   : Sample(8),
      eventCode   : Sample(1),
      sourceVenue : Sample(2) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode
        \o message.sourceVenue

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(eventCode.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         eventCode   |-> eventCode.value,
         sourceVenue |-> sourceVenue.value ], sourceVenue.rest)

ZeroSystemEventMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0],
      sourceVenue |-> [i \in 1 .. 2 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument Status Message: 27 bytes                                     *)
(***************************************************************************)

InstrumentStatusMessage ==
    [ timestamp           : Sample(8),
      instrument          : Sample(8),
      sourceVenue         : Sample(2),
      tradingStatus       : Sample(1),
      sessionChangeReason : Sample(1),
      newEndTime          : Sample(6),
      orderBookType       : Sample(1) ]

EncodeInstrumentStatusMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.tradingStatus
        \o message.sessionChangeReason
        \o message.newEndTime
        \o message.orderBookType

DecodeInstrumentStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(sourceVenue.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET sessionChangeReason == ReadBytes(tradingStatus.rest, 1) IN IF ~sessionChangeReason.ok THEN Fail ELSE
    LET newEndTime == ReadBytes(sessionChangeReason.rest, 6) IN IF ~newEndTime.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(newEndTime.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         instrument          |-> instrument.value,
         sourceVenue         |-> sourceVenue.value,
         tradingStatus       |-> tradingStatus.value,
         sessionChangeReason |-> sessionChangeReason.value,
         newEndTime          |-> newEndTime.value,
         orderBookType       |-> orderBookType.value ], orderBookType.rest)

ZeroInstrumentStatusMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrument          |-> [i \in 1 .. 8 |-> 0],
      sourceVenue         |-> [i \in 1 .. 2 |-> 0],
      tradingStatus       |-> [i \in 1 .. 1 |-> 0],
      sessionChangeReason |-> [i \in 1 .. 1 |-> 0],
      newEndTime          |-> [i \in 1 .. 6 |-> 0],
      orderBookType       |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Status Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStatusMessage ==
    { ZeroInstrumentStatusMessage }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.sessionChangeReason = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.newEndTime = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Incremental Message: 74 bytes                                 *)
(***************************************************************************)

AddOrderIncrementalMessage ==
    [ timestamp       : Sample(8),
      orderId         : Sample(8),
      side            : Sample(1),
      size            : Sample(8),
      instrument      : Sample(8),
      price           : Sample(8),
      transactionTime : Sample(8),
      sourceVenue     : Sample(2),
      orderBookType   : Sample(1),
      participant     : Sample(11),
      orderType       : Sample(1),
      rfqId           : Sample(10) ]

EncodeAddOrderIncrementalMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.side
        \o message.size
        \o message.instrument
        \o message.price
        \o message.transactionTime
        \o message.sourceVenue
        \o message.orderBookType
        \o message.participant
        \o message.orderType
        \o message.rfqId

DecodeAddOrderIncrementalMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET size == ReadBytes(side.rest, 8) IN IF ~size.ok THEN Fail ELSE
    LET instrument == ReadBytes(size.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET price == ReadBytes(instrument.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(price.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(transactionTime.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(sourceVenue.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET participant == ReadBytes(orderBookType.rest, 11) IN IF ~participant.ok THEN Fail ELSE
    LET orderType == ReadBytes(participant.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET rfqId == ReadBytes(orderType.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         orderId         |-> orderId.value,
         side            |-> side.value,
         size            |-> size.value,
         instrument      |-> instrument.value,
         price           |-> price.value,
         transactionTime |-> transactionTime.value,
         sourceVenue     |-> sourceVenue.value,
         orderBookType   |-> orderBookType.value,
         participant     |-> participant.value,
         orderType       |-> orderType.value,
         rfqId           |-> rfqId.value ], rfqId.rest)

ZeroAddOrderIncrementalMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      size            |-> [i \in 1 .. 8 |-> 0],
      instrument      |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      transactionTime |-> [i \in 1 .. 8 |-> 0],
      sourceVenue     |-> [i \in 1 .. 2 |-> 0],
      orderBookType   |-> [i \in 1 .. 1 |-> 0],
      participant     |-> [i \in 1 .. 11 |-> 0],
      orderType       |-> [i \in 1 .. 1 |-> 0],
      rfqId           |-> [i \in 1 .. 10 |-> 0] ]

(* Add Order Incremental Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderIncrementalMessage ==
    { ZeroAddOrderIncrementalMessage }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.size = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.participant = one] : one \in Sample(11) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderIncrementalMessage EXCEPT !.rfqId = one] : one \in Sample(10) }

(***************************************************************************)
(* Top Of Book Message: 84 bytes                                           *)
(***************************************************************************)

TopOfBookMessage ==
    [ timestamp       : Sample(8),
      instrument      : Sample(8),
      sourceVenue     : Sample(2),
      bidMarketSize   : Sample(8),
      bidLimitPrice   : Sample(8),
      reserved8       : Sample(8),
      bidLimitSize    : Sample(8),
      offerMarketSize : Sample(8),
      offerLimitPrice : Sample(8),
      secondReserved8 : Sample(8),
      offerLimitSize  : Sample(8),
      orderBookType   : Sample(1),
      topOfBookFlags  : Sample(1) ]

EncodeTopOfBookMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.bidMarketSize
        \o message.bidLimitPrice
        \o message.reserved8
        \o message.bidLimitSize
        \o message.offerMarketSize
        \o message.offerLimitPrice
        \o message.secondReserved8
        \o message.offerLimitSize
        \o message.orderBookType
        \o message.topOfBookFlags

DecodeTopOfBookMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET bidMarketSize == ReadBytes(sourceVenue.rest, 8) IN IF ~bidMarketSize.ok THEN Fail ELSE
    LET bidLimitPrice == ReadBytes(bidMarketSize.rest, 8) IN IF ~bidLimitPrice.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(bidLimitPrice.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET bidLimitSize == ReadBytes(reserved8.rest, 8) IN IF ~bidLimitSize.ok THEN Fail ELSE
    LET offerMarketSize == ReadBytes(bidLimitSize.rest, 8) IN IF ~offerMarketSize.ok THEN Fail ELSE
    LET offerLimitPrice == ReadBytes(offerMarketSize.rest, 8) IN IF ~offerLimitPrice.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(offerLimitPrice.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET offerLimitSize == ReadBytes(secondReserved8.rest, 8) IN IF ~offerLimitSize.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(offerLimitSize.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET topOfBookFlags == ReadBytes(orderBookType.rest, 1) IN IF ~topOfBookFlags.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         instrument      |-> instrument.value,
         sourceVenue     |-> sourceVenue.value,
         bidMarketSize   |-> bidMarketSize.value,
         bidLimitPrice   |-> bidLimitPrice.value,
         reserved8       |-> reserved8.value,
         bidLimitSize    |-> bidLimitSize.value,
         offerMarketSize |-> offerMarketSize.value,
         offerLimitPrice |-> offerLimitPrice.value,
         secondReserved8 |-> secondReserved8.value,
         offerLimitSize  |-> offerLimitSize.value,
         orderBookType   |-> orderBookType.value,
         topOfBookFlags  |-> topOfBookFlags.value ], topOfBookFlags.rest)

ZeroTopOfBookMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      instrument      |-> [i \in 1 .. 8 |-> 0],
      sourceVenue     |-> [i \in 1 .. 2 |-> 0],
      bidMarketSize   |-> [i \in 1 .. 8 |-> 0],
      bidLimitPrice   |-> [i \in 1 .. 8 |-> 0],
      reserved8       |-> [i \in 1 .. 8 |-> 0],
      bidLimitSize    |-> [i \in 1 .. 8 |-> 0],
      offerMarketSize |-> [i \in 1 .. 8 |-> 0],
      offerLimitPrice |-> [i \in 1 .. 8 |-> 0],
      secondReserved8 |-> [i \in 1 .. 8 |-> 0],
      offerLimitSize  |-> [i \in 1 .. 8 |-> 0],
      orderBookType   |-> [i \in 1 .. 1 |-> 0],
      topOfBookFlags  |-> [i \in 1 .. 1 |-> 0] ]

(* Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBookMessage ==
    { ZeroTopOfBookMessage }
        \cup { [ZeroTopOfBookMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidMarketSize = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidLimitSize = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.offerMarketSize = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.offerLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.offerLimitSize = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.topOfBookFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Clear Message: 19 bytes                                      *)
(***************************************************************************)

OrderBookClearMessage ==
    [ timestamp     : Sample(8),
      sourceVenue   : Sample(2),
      instrument    : Sample(8),
      orderBookType : Sample(1) ]

EncodeOrderBookClearMessage(message) ==
    message.timestamp
        \o message.sourceVenue
        \o message.instrument
        \o message.orderBookType

DecodeOrderBookClearMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(timestamp.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET instrument == ReadBytes(sourceVenue.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(instrument.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         sourceVenue   |-> sourceVenue.value,
         instrument    |-> instrument.value,
         orderBookType |-> orderBookType.value ], orderBookType.rest)

ZeroOrderBookClearMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      sourceVenue   |-> [i \in 1 .. 2 |-> 0],
      instrument    |-> [i \in 1 .. 8 |-> 0],
      orderBookType |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookClearMessage ==
    { ZeroOrderBookClearMessage }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 63 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timestamp                : Sample(8),
      transactionTime          : Sample(8),
      sourceVenue              : Sample(2),
      executedSize             : Sample(8),
      instrument               : Sample(8),
      price                    : Sample(8),
      reserved8                : Sample(8),
      tradeId                  : Sample(8),
      tradeType                : Sample(1),
      auctionType              : Sample(1),
      tradeFlags               : Sample(1),
      hiddenExecutionIndicator : Sample(1),
      tradeQualifier           : Sample(1) ]

EncodeTradeMessage(message) ==
    message.timestamp
        \o message.transactionTime
        \o message.sourceVenue
        \o message.executedSize
        \o message.instrument
        \o message.price
        \o message.reserved8
        \o message.tradeId
        \o message.tradeType
        \o message.auctionType
        \o message.tradeFlags
        \o message.hiddenExecutionIndicator
        \o message.tradeQualifier

DecodeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(timestamp.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(transactionTime.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET executedSize == ReadBytes(sourceVenue.rest, 8) IN IF ~executedSize.ok THEN Fail ELSE
    LET instrument == ReadBytes(executedSize.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET price == ReadBytes(instrument.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(price.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET tradeId == ReadBytes(reserved8.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradeId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET auctionType == ReadBytes(tradeType.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(auctionType.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    LET hiddenExecutionIndicator == ReadBytes(tradeFlags.rest, 1) IN IF ~hiddenExecutionIndicator.ok THEN Fail ELSE
    LET tradeQualifier == ReadBytes(hiddenExecutionIndicator.rest, 1) IN IF ~tradeQualifier.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         transactionTime          |-> transactionTime.value,
         sourceVenue              |-> sourceVenue.value,
         executedSize             |-> executedSize.value,
         instrument               |-> instrument.value,
         price                    |-> price.value,
         reserved8                |-> reserved8.value,
         tradeId                  |-> tradeId.value,
         tradeType                |-> tradeType.value,
         auctionType              |-> auctionType.value,
         tradeFlags               |-> tradeFlags.value,
         hiddenExecutionIndicator |-> hiddenExecutionIndicator.value,
         tradeQualifier           |-> tradeQualifier.value ], tradeQualifier.rest)

ZeroTradeMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      transactionTime          |-> [i \in 1 .. 8 |-> 0],
      sourceVenue              |-> [i \in 1 .. 2 |-> 0],
      executedSize             |-> [i \in 1 .. 8 |-> 0],
      instrument               |-> [i \in 1 .. 8 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      reserved8                |-> [i \in 1 .. 8 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      tradeType                |-> [i \in 1 .. 1 |-> 0],
      auctionType              |-> [i \in 1 .. 1 |-> 0],
      tradeFlags               |-> [i \in 1 .. 1 |-> 0],
      hiddenExecutionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeQualifier           |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.executedSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.hiddenExecutionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeQualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cross Message: 80 bytes                                           *)
(***************************************************************************)

TradeCrossMessage ==
    [ timestamp       : Sample(8),
      transactionTime : Sample(8),
      sourceVenue     : Sample(2),
      executedSize    : Sample(8),
      instrument      : Sample(8),
      price           : Sample(8),
      reserved8       : Sample(8),
      tradeId         : Sample(8),
      crossId         : Sample(20),
      crossType       : Sample(1),
      tradeFlags      : Sample(1) ]

EncodeTradeCrossMessage(message) ==
    message.timestamp
        \o message.transactionTime
        \o message.sourceVenue
        \o message.executedSize
        \o message.instrument
        \o message.price
        \o message.reserved8
        \o message.tradeId
        \o message.crossId
        \o message.crossType
        \o message.tradeFlags

DecodeTradeCrossMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(timestamp.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(transactionTime.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET executedSize == ReadBytes(sourceVenue.rest, 8) IN IF ~executedSize.ok THEN Fail ELSE
    LET instrument == ReadBytes(executedSize.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET price == ReadBytes(instrument.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(price.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET tradeId == ReadBytes(reserved8.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET crossId == ReadBytes(tradeId.rest, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(crossType.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         transactionTime |-> transactionTime.value,
         sourceVenue     |-> sourceVenue.value,
         executedSize    |-> executedSize.value,
         instrument      |-> instrument.value,
         price           |-> price.value,
         reserved8       |-> reserved8.value,
         tradeId         |-> tradeId.value,
         crossId         |-> crossId.value,
         crossType       |-> crossType.value,
         tradeFlags      |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeCrossMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      transactionTime |-> [i \in 1 .. 8 |-> 0],
      sourceVenue     |-> [i \in 1 .. 2 |-> 0],
      executedSize    |-> [i \in 1 .. 8 |-> 0],
      instrument      |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      reserved8       |-> [i \in 1 .. 8 |-> 0],
      tradeId         |-> [i \in 1 .. 8 |-> 0],
      crossId         |-> [i \in 1 .. 20 |-> 0],
      crossType       |-> [i \in 1 .. 1 |-> 0],
      tradeFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Cross Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCrossMessage ==
    { ZeroTradeCrossMessage }
        \cup { [ZeroTradeCrossMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.executedSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCrossMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Ii Trade Message: 283 bytes                                       *)
(***************************************************************************)

MifidIiTradeMessage ==
    [ timestamp                        : Sample(8),
      sourceVenue                      : Sample(2),
      instrument                       : Sample(8),
      transactionIdentificationCode    : Sample(52),
      tradeType                        : Sample(1),
      auctionType                      : Sample(1),
      miFidPrice                       : Sample(20),
      miFidQuantity                    : Sample(20),
      tradingDateAndTime               : Sample(27),
      instrumentIdentificationCodeType : Sample(4),
      instrumentIdentificationCode     : Sample(12),
      priceNotation                    : Sample(4),
      priceMajorCurrency               : Sample(3),
      notionalAmount                   : Sample(20),
      notionalCurrency                 : Sample(3),
      venueOfExecution                 : Sample(4),
      publicationDateAndTime           : Sample(27),
      ptRefPriceWaiverFlag             : Sample(4),
      reserved4                        : Sample(4),
      marketClosingPriceFlag           : Sample(4),
      ptAlgoTrade                      : Sample(4),
      ptCancellationFlag               : Sample(4),
      ptAmendmentFlag                  : Sample(4),
      reserved1                        : Sample(1),
      reserved3                        : Sample(3),
      reserved20                       : Sample(20),
      secondReserved4                  : Sample(4),
      tradeQualifier                   : Sample(1),
      marketMechanism                  : Sample(1),
      tradingMode                      : Sample(1),
      transactionCategory              : Sample(1),
      negotiationIndicator             : Sample(1),
      agencyCrossIndicator             : Sample(1),
      modificationIndicator            : Sample(1),
      referencePriceIndicator          : Sample(1),
      specialDividendIndicator         : Sample(1),
      offBookAutomatedIndicator        : Sample(1),
      priceFormationIndicator          : Sample(1),
      algorithmicIndicator             : Sample(1),
      postTradeDeferralReason          : Sample(1),
      deferralEnrichmentType           : Sample(1),
      duplicativeIndicator             : Sample(1) ]

EncodeMifidIiTradeMessage(message) ==
    message.timestamp
        \o message.sourceVenue
        \o message.instrument
        \o message.transactionIdentificationCode
        \o message.tradeType
        \o message.auctionType
        \o message.miFidPrice
        \o message.miFidQuantity
        \o message.tradingDateAndTime
        \o message.instrumentIdentificationCodeType
        \o message.instrumentIdentificationCode
        \o message.priceNotation
        \o message.priceMajorCurrency
        \o message.notionalAmount
        \o message.notionalCurrency
        \o message.venueOfExecution
        \o message.publicationDateAndTime
        \o message.ptRefPriceWaiverFlag
        \o message.reserved4
        \o message.marketClosingPriceFlag
        \o message.ptAlgoTrade
        \o message.ptCancellationFlag
        \o message.ptAmendmentFlag
        \o message.reserved1
        \o message.reserved3
        \o message.reserved20
        \o message.secondReserved4
        \o message.tradeQualifier
        \o message.marketMechanism
        \o message.tradingMode
        \o message.transactionCategory
        \o message.negotiationIndicator
        \o message.agencyCrossIndicator
        \o message.modificationIndicator
        \o message.referencePriceIndicator
        \o message.specialDividendIndicator
        \o message.offBookAutomatedIndicator
        \o message.priceFormationIndicator
        \o message.algorithmicIndicator
        \o message.postTradeDeferralReason
        \o message.deferralEnrichmentType
        \o message.duplicativeIndicator

DecodeMifidIiTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(timestamp.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET instrument == ReadBytes(sourceVenue.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET transactionIdentificationCode == ReadBytes(instrument.rest, 52) IN IF ~transactionIdentificationCode.ok THEN Fail ELSE
    LET tradeType == ReadBytes(transactionIdentificationCode.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET auctionType == ReadBytes(tradeType.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET miFidPrice == ReadBytes(auctionType.rest, 20) IN IF ~miFidPrice.ok THEN Fail ELSE
    LET miFidQuantity == ReadBytes(miFidPrice.rest, 20) IN IF ~miFidQuantity.ok THEN Fail ELSE
    LET tradingDateAndTime == ReadBytes(miFidQuantity.rest, 27) IN IF ~tradingDateAndTime.ok THEN Fail ELSE
    LET instrumentIdentificationCodeType == ReadBytes(tradingDateAndTime.rest, 4) IN IF ~instrumentIdentificationCodeType.ok THEN Fail ELSE
    LET instrumentIdentificationCode == ReadBytes(instrumentIdentificationCodeType.rest, 12) IN IF ~instrumentIdentificationCode.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(instrumentIdentificationCode.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET priceMajorCurrency == ReadBytes(priceNotation.rest, 3) IN IF ~priceMajorCurrency.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(priceMajorCurrency.rest, 20) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(notionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(notionalCurrency.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    LET publicationDateAndTime == ReadBytes(venueOfExecution.rest, 27) IN IF ~publicationDateAndTime.ok THEN Fail ELSE
    LET ptRefPriceWaiverFlag == ReadBytes(publicationDateAndTime.rest, 4) IN IF ~ptRefPriceWaiverFlag.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(ptRefPriceWaiverFlag.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET marketClosingPriceFlag == ReadBytes(reserved4.rest, 4) IN IF ~marketClosingPriceFlag.ok THEN Fail ELSE
    LET ptAlgoTrade == ReadBytes(marketClosingPriceFlag.rest, 4) IN IF ~ptAlgoTrade.ok THEN Fail ELSE
    LET ptCancellationFlag == ReadBytes(ptAlgoTrade.rest, 4) IN IF ~ptCancellationFlag.ok THEN Fail ELSE
    LET ptAmendmentFlag == ReadBytes(ptCancellationFlag.rest, 4) IN IF ~ptAmendmentFlag.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(ptAmendmentFlag.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(reserved1.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    LET reserved20 == ReadBytes(reserved3.rest, 20) IN IF ~reserved20.ok THEN Fail ELSE
    LET secondReserved4 == ReadBytes(reserved20.rest, 4) IN IF ~secondReserved4.ok THEN Fail ELSE
    LET tradeQualifier == ReadBytes(secondReserved4.rest, 1) IN IF ~tradeQualifier.ok THEN Fail ELSE
    LET marketMechanism == ReadBytes(tradeQualifier.rest, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET negotiationIndicator == ReadBytes(transactionCategory.rest, 1) IN IF ~negotiationIndicator.ok THEN Fail ELSE
    LET agencyCrossIndicator == ReadBytes(negotiationIndicator.rest, 1) IN IF ~agencyCrossIndicator.ok THEN Fail ELSE
    LET modificationIndicator == ReadBytes(agencyCrossIndicator.rest, 1) IN IF ~modificationIndicator.ok THEN Fail ELSE
    LET referencePriceIndicator == ReadBytes(modificationIndicator.rest, 1) IN IF ~referencePriceIndicator.ok THEN Fail ELSE
    LET specialDividendIndicator == ReadBytes(referencePriceIndicator.rest, 1) IN IF ~specialDividendIndicator.ok THEN Fail ELSE
    LET offBookAutomatedIndicator == ReadBytes(specialDividendIndicator.rest, 1) IN IF ~offBookAutomatedIndicator.ok THEN Fail ELSE
    LET priceFormationIndicator == ReadBytes(offBookAutomatedIndicator.rest, 1) IN IF ~priceFormationIndicator.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadBytes(priceFormationIndicator.rest, 1) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET postTradeDeferralReason == ReadBytes(algorithmicIndicator.rest, 1) IN IF ~postTradeDeferralReason.ok THEN Fail ELSE
    LET deferralEnrichmentType == ReadBytes(postTradeDeferralReason.rest, 1) IN IF ~deferralEnrichmentType.ok THEN Fail ELSE
    LET duplicativeIndicator == ReadBytes(deferralEnrichmentType.rest, 1) IN IF ~duplicativeIndicator.ok THEN Fail ELSE
    Ok([ timestamp                        |-> timestamp.value,
         sourceVenue                      |-> sourceVenue.value,
         instrument                       |-> instrument.value,
         transactionIdentificationCode    |-> transactionIdentificationCode.value,
         tradeType                        |-> tradeType.value,
         auctionType                      |-> auctionType.value,
         miFidPrice                       |-> miFidPrice.value,
         miFidQuantity                    |-> miFidQuantity.value,
         tradingDateAndTime               |-> tradingDateAndTime.value,
         instrumentIdentificationCodeType |-> instrumentIdentificationCodeType.value,
         instrumentIdentificationCode     |-> instrumentIdentificationCode.value,
         priceNotation                    |-> priceNotation.value,
         priceMajorCurrency               |-> priceMajorCurrency.value,
         notionalAmount                   |-> notionalAmount.value,
         notionalCurrency                 |-> notionalCurrency.value,
         venueOfExecution                 |-> venueOfExecution.value,
         publicationDateAndTime           |-> publicationDateAndTime.value,
         ptRefPriceWaiverFlag             |-> ptRefPriceWaiverFlag.value,
         reserved4                        |-> reserved4.value,
         marketClosingPriceFlag           |-> marketClosingPriceFlag.value,
         ptAlgoTrade                      |-> ptAlgoTrade.value,
         ptCancellationFlag               |-> ptCancellationFlag.value,
         ptAmendmentFlag                  |-> ptAmendmentFlag.value,
         reserved1                        |-> reserved1.value,
         reserved3                        |-> reserved3.value,
         reserved20                       |-> reserved20.value,
         secondReserved4                  |-> secondReserved4.value,
         tradeQualifier                   |-> tradeQualifier.value,
         marketMechanism                  |-> marketMechanism.value,
         tradingMode                      |-> tradingMode.value,
         transactionCategory              |-> transactionCategory.value,
         negotiationIndicator             |-> negotiationIndicator.value,
         agencyCrossIndicator             |-> agencyCrossIndicator.value,
         modificationIndicator            |-> modificationIndicator.value,
         referencePriceIndicator          |-> referencePriceIndicator.value,
         specialDividendIndicator         |-> specialDividendIndicator.value,
         offBookAutomatedIndicator        |-> offBookAutomatedIndicator.value,
         priceFormationIndicator          |-> priceFormationIndicator.value,
         algorithmicIndicator             |-> algorithmicIndicator.value,
         postTradeDeferralReason          |-> postTradeDeferralReason.value,
         deferralEnrichmentType           |-> deferralEnrichmentType.value,
         duplicativeIndicator             |-> duplicativeIndicator.value ], duplicativeIndicator.rest)

ZeroMifidIiTradeMessage ==
    [ timestamp                        |-> [i \in 1 .. 8 |-> 0],
      sourceVenue                      |-> [i \in 1 .. 2 |-> 0],
      instrument                       |-> [i \in 1 .. 8 |-> 0],
      transactionIdentificationCode    |-> [i \in 1 .. 52 |-> 0],
      tradeType                        |-> [i \in 1 .. 1 |-> 0],
      auctionType                      |-> [i \in 1 .. 1 |-> 0],
      miFidPrice                       |-> [i \in 1 .. 20 |-> 0],
      miFidQuantity                    |-> [i \in 1 .. 20 |-> 0],
      tradingDateAndTime               |-> [i \in 1 .. 27 |-> 0],
      instrumentIdentificationCodeType |-> [i \in 1 .. 4 |-> 0],
      instrumentIdentificationCode     |-> [i \in 1 .. 12 |-> 0],
      priceNotation                    |-> [i \in 1 .. 4 |-> 0],
      priceMajorCurrency               |-> [i \in 1 .. 3 |-> 0],
      notionalAmount                   |-> [i \in 1 .. 20 |-> 0],
      notionalCurrency                 |-> [i \in 1 .. 3 |-> 0],
      venueOfExecution                 |-> [i \in 1 .. 4 |-> 0],
      publicationDateAndTime           |-> [i \in 1 .. 27 |-> 0],
      ptRefPriceWaiverFlag             |-> [i \in 1 .. 4 |-> 0],
      reserved4                        |-> [i \in 1 .. 4 |-> 0],
      marketClosingPriceFlag           |-> [i \in 1 .. 4 |-> 0],
      ptAlgoTrade                      |-> [i \in 1 .. 4 |-> 0],
      ptCancellationFlag               |-> [i \in 1 .. 4 |-> 0],
      ptAmendmentFlag                  |-> [i \in 1 .. 4 |-> 0],
      reserved1                        |-> [i \in 1 .. 1 |-> 0],
      reserved3                        |-> [i \in 1 .. 3 |-> 0],
      reserved20                       |-> [i \in 1 .. 20 |-> 0],
      secondReserved4                  |-> [i \in 1 .. 4 |-> 0],
      tradeQualifier                   |-> [i \in 1 .. 1 |-> 0],
      marketMechanism                  |-> [i \in 1 .. 1 |-> 0],
      tradingMode                      |-> [i \in 1 .. 1 |-> 0],
      transactionCategory              |-> [i \in 1 .. 1 |-> 0],
      negotiationIndicator             |-> [i \in 1 .. 1 |-> 0],
      agencyCrossIndicator             |-> [i \in 1 .. 1 |-> 0],
      modificationIndicator            |-> [i \in 1 .. 1 |-> 0],
      referencePriceIndicator          |-> [i \in 1 .. 1 |-> 0],
      specialDividendIndicator         |-> [i \in 1 .. 1 |-> 0],
      offBookAutomatedIndicator        |-> [i \in 1 .. 1 |-> 0],
      priceFormationIndicator          |-> [i \in 1 .. 1 |-> 0],
      algorithmicIndicator             |-> [i \in 1 .. 1 |-> 0],
      postTradeDeferralReason          |-> [i \in 1 .. 1 |-> 0],
      deferralEnrichmentType           |-> [i \in 1 .. 1 |-> 0],
      duplicativeIndicator             |-> [i \in 1 .. 1 |-> 0] ]

(* Mifid Ii Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedMifidIiTradeMessage ==
    { ZeroMifidIiTradeMessage }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.transactionIdentificationCode = one] : one \in Sample(52) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.miFidPrice = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.miFidQuantity = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.tradingDateAndTime = one] : one \in Sample(27) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.instrumentIdentificationCodeType = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.instrumentIdentificationCode = one] : one \in Sample(12) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.priceMajorCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.notionalAmount = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.publicationDateAndTime = one] : one \in Sample(27) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.ptRefPriceWaiverFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.marketClosingPriceFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.ptAlgoTrade = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.ptCancellationFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.ptAmendmentFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.reserved20 = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.secondReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.tradeQualifier = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.negotiationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.agencyCrossIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.modificationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.referencePriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.specialDividendIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.offBookAutomatedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.priceFormationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.algorithmicIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.postTradeDeferralReason = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.deferralEnrichmentType = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeMessage EXCEPT !.duplicativeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Mi Fid Ii Trade Cross Message: 301 bytes                                *)
(***************************************************************************)

MiFidIiTradeCrossMessage ==
    [ timestamp                        : Sample(8),
      sourceVenue                      : Sample(2),
      instrument                       : Sample(8),
      transactionIdentificationCode    : Sample(52),
      crossId                          : Sample(20),
      crossType                        : Sample(1),
      miFidPrice                       : Sample(20),
      miFidQuantity                    : Sample(20),
      tradingDateAndTime               : Sample(27),
      instrumentIdentificationCodeType : Sample(4),
      instrumentIdentificationCode     : Sample(12),
      priceNotation                    : Sample(4),
      priceMajorCurrency               : Sample(3),
      notionalAmount                   : Sample(20),
      notionalCurrency                 : Sample(3),
      venueOfExecution                 : Sample(4),
      publicationDateAndTime           : Sample(27),
      reserved4                        : Sample(4),
      ntPreTradeWaiverFlag             : Sample(4),
      ptAlgoTrade                      : Sample(4),
      secondReserved4                  : Sample(4),
      ptCancellationFlag               : Sample(4),
      ptAmendmentFlag                  : Sample(4),
      reserved1                        : Sample(1),
      reserved3                        : Sample(3),
      reserved20                       : Sample(20),
      thirdReserved4                   : Sample(4),
      marketMechanism                  : Sample(1),
      tradingMode                      : Sample(1),
      transactionCategory              : Sample(1),
      negotiationIndicator             : Sample(1),
      agencyCrossIndicator             : Sample(1),
      modificationIndicator            : Sample(1),
      referencePriceIndicator          : Sample(1),
      specialDividendIndicator         : Sample(1),
      offBookAutomatedIndicator        : Sample(1),
      priceFormationIndicator          : Sample(1),
      algorithmicIndicator             : Sample(1),
      postTradeDeferralReason          : Sample(1),
      deferralEnrichmentType           : Sample(1),
      duplicativeIndicator             : Sample(1) ]

EncodeMiFidIiTradeCrossMessage(message) ==
    message.timestamp
        \o message.sourceVenue
        \o message.instrument
        \o message.transactionIdentificationCode
        \o message.crossId
        \o message.crossType
        \o message.miFidPrice
        \o message.miFidQuantity
        \o message.tradingDateAndTime
        \o message.instrumentIdentificationCodeType
        \o message.instrumentIdentificationCode
        \o message.priceNotation
        \o message.priceMajorCurrency
        \o message.notionalAmount
        \o message.notionalCurrency
        \o message.venueOfExecution
        \o message.publicationDateAndTime
        \o message.reserved4
        \o message.ntPreTradeWaiverFlag
        \o message.ptAlgoTrade
        \o message.secondReserved4
        \o message.ptCancellationFlag
        \o message.ptAmendmentFlag
        \o message.reserved1
        \o message.reserved3
        \o message.reserved20
        \o message.thirdReserved4
        \o message.marketMechanism
        \o message.tradingMode
        \o message.transactionCategory
        \o message.negotiationIndicator
        \o message.agencyCrossIndicator
        \o message.modificationIndicator
        \o message.referencePriceIndicator
        \o message.specialDividendIndicator
        \o message.offBookAutomatedIndicator
        \o message.priceFormationIndicator
        \o message.algorithmicIndicator
        \o message.postTradeDeferralReason
        \o message.deferralEnrichmentType
        \o message.duplicativeIndicator

DecodeMiFidIiTradeCrossMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(timestamp.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET instrument == ReadBytes(sourceVenue.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET transactionIdentificationCode == ReadBytes(instrument.rest, 52) IN IF ~transactionIdentificationCode.ok THEN Fail ELSE
    LET crossId == ReadBytes(transactionIdentificationCode.rest, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET miFidPrice == ReadBytes(crossType.rest, 20) IN IF ~miFidPrice.ok THEN Fail ELSE
    LET miFidQuantity == ReadBytes(miFidPrice.rest, 20) IN IF ~miFidQuantity.ok THEN Fail ELSE
    LET tradingDateAndTime == ReadBytes(miFidQuantity.rest, 27) IN IF ~tradingDateAndTime.ok THEN Fail ELSE
    LET instrumentIdentificationCodeType == ReadBytes(tradingDateAndTime.rest, 4) IN IF ~instrumentIdentificationCodeType.ok THEN Fail ELSE
    LET instrumentIdentificationCode == ReadBytes(instrumentIdentificationCodeType.rest, 12) IN IF ~instrumentIdentificationCode.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(instrumentIdentificationCode.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET priceMajorCurrency == ReadBytes(priceNotation.rest, 3) IN IF ~priceMajorCurrency.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(priceMajorCurrency.rest, 20) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(notionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(notionalCurrency.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    LET publicationDateAndTime == ReadBytes(venueOfExecution.rest, 27) IN IF ~publicationDateAndTime.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(publicationDateAndTime.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET ntPreTradeWaiverFlag == ReadBytes(reserved4.rest, 4) IN IF ~ntPreTradeWaiverFlag.ok THEN Fail ELSE
    LET ptAlgoTrade == ReadBytes(ntPreTradeWaiverFlag.rest, 4) IN IF ~ptAlgoTrade.ok THEN Fail ELSE
    LET secondReserved4 == ReadBytes(ptAlgoTrade.rest, 4) IN IF ~secondReserved4.ok THEN Fail ELSE
    LET ptCancellationFlag == ReadBytes(secondReserved4.rest, 4) IN IF ~ptCancellationFlag.ok THEN Fail ELSE
    LET ptAmendmentFlag == ReadBytes(ptCancellationFlag.rest, 4) IN IF ~ptAmendmentFlag.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(ptAmendmentFlag.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(reserved1.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    LET reserved20 == ReadBytes(reserved3.rest, 20) IN IF ~reserved20.ok THEN Fail ELSE
    LET thirdReserved4 == ReadBytes(reserved20.rest, 4) IN IF ~thirdReserved4.ok THEN Fail ELSE
    LET marketMechanism == ReadBytes(thirdReserved4.rest, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET negotiationIndicator == ReadBytes(transactionCategory.rest, 1) IN IF ~negotiationIndicator.ok THEN Fail ELSE
    LET agencyCrossIndicator == ReadBytes(negotiationIndicator.rest, 1) IN IF ~agencyCrossIndicator.ok THEN Fail ELSE
    LET modificationIndicator == ReadBytes(agencyCrossIndicator.rest, 1) IN IF ~modificationIndicator.ok THEN Fail ELSE
    LET referencePriceIndicator == ReadBytes(modificationIndicator.rest, 1) IN IF ~referencePriceIndicator.ok THEN Fail ELSE
    LET specialDividendIndicator == ReadBytes(referencePriceIndicator.rest, 1) IN IF ~specialDividendIndicator.ok THEN Fail ELSE
    LET offBookAutomatedIndicator == ReadBytes(specialDividendIndicator.rest, 1) IN IF ~offBookAutomatedIndicator.ok THEN Fail ELSE
    LET priceFormationIndicator == ReadBytes(offBookAutomatedIndicator.rest, 1) IN IF ~priceFormationIndicator.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadBytes(priceFormationIndicator.rest, 1) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET postTradeDeferralReason == ReadBytes(algorithmicIndicator.rest, 1) IN IF ~postTradeDeferralReason.ok THEN Fail ELSE
    LET deferralEnrichmentType == ReadBytes(postTradeDeferralReason.rest, 1) IN IF ~deferralEnrichmentType.ok THEN Fail ELSE
    LET duplicativeIndicator == ReadBytes(deferralEnrichmentType.rest, 1) IN IF ~duplicativeIndicator.ok THEN Fail ELSE
    Ok([ timestamp                        |-> timestamp.value,
         sourceVenue                      |-> sourceVenue.value,
         instrument                       |-> instrument.value,
         transactionIdentificationCode    |-> transactionIdentificationCode.value,
         crossId                          |-> crossId.value,
         crossType                        |-> crossType.value,
         miFidPrice                       |-> miFidPrice.value,
         miFidQuantity                    |-> miFidQuantity.value,
         tradingDateAndTime               |-> tradingDateAndTime.value,
         instrumentIdentificationCodeType |-> instrumentIdentificationCodeType.value,
         instrumentIdentificationCode     |-> instrumentIdentificationCode.value,
         priceNotation                    |-> priceNotation.value,
         priceMajorCurrency               |-> priceMajorCurrency.value,
         notionalAmount                   |-> notionalAmount.value,
         notionalCurrency                 |-> notionalCurrency.value,
         venueOfExecution                 |-> venueOfExecution.value,
         publicationDateAndTime           |-> publicationDateAndTime.value,
         reserved4                        |-> reserved4.value,
         ntPreTradeWaiverFlag             |-> ntPreTradeWaiverFlag.value,
         ptAlgoTrade                      |-> ptAlgoTrade.value,
         secondReserved4                  |-> secondReserved4.value,
         ptCancellationFlag               |-> ptCancellationFlag.value,
         ptAmendmentFlag                  |-> ptAmendmentFlag.value,
         reserved1                        |-> reserved1.value,
         reserved3                        |-> reserved3.value,
         reserved20                       |-> reserved20.value,
         thirdReserved4                   |-> thirdReserved4.value,
         marketMechanism                  |-> marketMechanism.value,
         tradingMode                      |-> tradingMode.value,
         transactionCategory              |-> transactionCategory.value,
         negotiationIndicator             |-> negotiationIndicator.value,
         agencyCrossIndicator             |-> agencyCrossIndicator.value,
         modificationIndicator            |-> modificationIndicator.value,
         referencePriceIndicator          |-> referencePriceIndicator.value,
         specialDividendIndicator         |-> specialDividendIndicator.value,
         offBookAutomatedIndicator        |-> offBookAutomatedIndicator.value,
         priceFormationIndicator          |-> priceFormationIndicator.value,
         algorithmicIndicator             |-> algorithmicIndicator.value,
         postTradeDeferralReason          |-> postTradeDeferralReason.value,
         deferralEnrichmentType           |-> deferralEnrichmentType.value,
         duplicativeIndicator             |-> duplicativeIndicator.value ], duplicativeIndicator.rest)

ZeroMiFidIiTradeCrossMessage ==
    [ timestamp                        |-> [i \in 1 .. 8 |-> 0],
      sourceVenue                      |-> [i \in 1 .. 2 |-> 0],
      instrument                       |-> [i \in 1 .. 8 |-> 0],
      transactionIdentificationCode    |-> [i \in 1 .. 52 |-> 0],
      crossId                          |-> [i \in 1 .. 20 |-> 0],
      crossType                        |-> [i \in 1 .. 1 |-> 0],
      miFidPrice                       |-> [i \in 1 .. 20 |-> 0],
      miFidQuantity                    |-> [i \in 1 .. 20 |-> 0],
      tradingDateAndTime               |-> [i \in 1 .. 27 |-> 0],
      instrumentIdentificationCodeType |-> [i \in 1 .. 4 |-> 0],
      instrumentIdentificationCode     |-> [i \in 1 .. 12 |-> 0],
      priceNotation                    |-> [i \in 1 .. 4 |-> 0],
      priceMajorCurrency               |-> [i \in 1 .. 3 |-> 0],
      notionalAmount                   |-> [i \in 1 .. 20 |-> 0],
      notionalCurrency                 |-> [i \in 1 .. 3 |-> 0],
      venueOfExecution                 |-> [i \in 1 .. 4 |-> 0],
      publicationDateAndTime           |-> [i \in 1 .. 27 |-> 0],
      reserved4                        |-> [i \in 1 .. 4 |-> 0],
      ntPreTradeWaiverFlag             |-> [i \in 1 .. 4 |-> 0],
      ptAlgoTrade                      |-> [i \in 1 .. 4 |-> 0],
      secondReserved4                  |-> [i \in 1 .. 4 |-> 0],
      ptCancellationFlag               |-> [i \in 1 .. 4 |-> 0],
      ptAmendmentFlag                  |-> [i \in 1 .. 4 |-> 0],
      reserved1                        |-> [i \in 1 .. 1 |-> 0],
      reserved3                        |-> [i \in 1 .. 3 |-> 0],
      reserved20                       |-> [i \in 1 .. 20 |-> 0],
      thirdReserved4                   |-> [i \in 1 .. 4 |-> 0],
      marketMechanism                  |-> [i \in 1 .. 1 |-> 0],
      tradingMode                      |-> [i \in 1 .. 1 |-> 0],
      transactionCategory              |-> [i \in 1 .. 1 |-> 0],
      negotiationIndicator             |-> [i \in 1 .. 1 |-> 0],
      agencyCrossIndicator             |-> [i \in 1 .. 1 |-> 0],
      modificationIndicator            |-> [i \in 1 .. 1 |-> 0],
      referencePriceIndicator          |-> [i \in 1 .. 1 |-> 0],
      specialDividendIndicator         |-> [i \in 1 .. 1 |-> 0],
      offBookAutomatedIndicator        |-> [i \in 1 .. 1 |-> 0],
      priceFormationIndicator          |-> [i \in 1 .. 1 |-> 0],
      algorithmicIndicator             |-> [i \in 1 .. 1 |-> 0],
      postTradeDeferralReason          |-> [i \in 1 .. 1 |-> 0],
      deferralEnrichmentType           |-> [i \in 1 .. 1 |-> 0],
      duplicativeIndicator             |-> [i \in 1 .. 1 |-> 0] ]

(* Mi Fid Ii Trade Cross Message at zero, then each field in turn at the values it is checked at *)
CheckedMiFidIiTradeCrossMessage ==
    { ZeroMiFidIiTradeCrossMessage }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.transactionIdentificationCode = one] : one \in Sample(52) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.miFidPrice = one] : one \in Sample(20) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.miFidQuantity = one] : one \in Sample(20) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.tradingDateAndTime = one] : one \in Sample(27) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.instrumentIdentificationCodeType = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.instrumentIdentificationCode = one] : one \in Sample(12) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.priceMajorCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.notionalAmount = one] : one \in Sample(20) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.publicationDateAndTime = one] : one \in Sample(27) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.ntPreTradeWaiverFlag = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.ptAlgoTrade = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.secondReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.ptCancellationFlag = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.ptAmendmentFlag = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.reserved20 = one] : one \in Sample(20) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.thirdReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.negotiationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.agencyCrossIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.modificationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.referencePriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.specialDividendIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.offBookAutomatedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.priceFormationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.algorithmicIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.postTradeDeferralReason = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.deferralEnrichmentType = one] : one \in Sample(1) }
        \cup { [ZeroMiFidIiTradeCrossMessage EXCEPT !.duplicativeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Directory Equities Message: 310 bytes                        *)
(***************************************************************************)

InstrumentDirectoryEquitiesMessage ==
    [ timestamp                       : Sample(8),
      instrument                      : Sample(8),
      isin                            : Sample(12),
      sedol                           : Sample(8),
      allowedBookTypes                : Sample(1),
      sourceVenue                     : Sample(2),
      venueInstrumentId               : Sample(11),
      segment                         : Sample(6),
      currency                        : Sample(3),
      tickId                          : Sample(2),
      previousDaysClosingPrice        : Sample(8),
      reserved8                       : Sample(8),
      dynamicCircuitBreakerTolerances : Sample(8),
      staticCircuitBreakerTolerances  : Sample(8),
      firstReserved1                  : Sample(1),
      secondReserved1                 : Sample(1),
      expirationDate                  : Sample(8),
      listingStartDate                : Sample(8),
      listingEndDate                  : Sample(8),
      minimumLotMinimumExecutionSize  : Sample(8),
      lastPriceInPrecedingSession     : Sample(8),
      lastPriceInPrecedingSessionDate : Sample(8),
      thirdReserved1                  : Sample(1),
      secondReserved8                 : Sample(8),
      thirdReserved8                  : Sample(8),
      exMarkerCode                    : Sample(2),
      securityType                    : Sample(1),
      countryOfRegister               : Sample(3),
      exchangeMarketSize              : Sample(8),
      minimumPeakSizeMultiplier       : Sample(8),
      securityMaximumSpread           : Sample(8),
      clearingType                    : Sample(1),
      strikePrice                     : Sample(8),
      securityExchange                : Sample(11),
      reserved12                      : Sample(12),
      fourthReserved1                 : Sample(1),
      fourthReserved8                 : Sample(8),
      fifthReserved8                  : Sample(8),
      reserved1                       : Sample(1),
      sixthReserved8                  : Sample(8),
      seventhReserved8                : Sample(8),
      reserved4                       : Sample(4),
      reserved2                       : Sample(2),
      symbol                          : Sample(8),
      description                     : Sample(40) ]

EncodeInstrumentDirectoryEquitiesMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.isin
        \o message.sedol
        \o message.allowedBookTypes
        \o message.sourceVenue
        \o message.venueInstrumentId
        \o message.segment
        \o message.currency
        \o message.tickId
        \o message.previousDaysClosingPrice
        \o message.reserved8
        \o message.dynamicCircuitBreakerTolerances
        \o message.staticCircuitBreakerTolerances
        \o message.firstReserved1
        \o message.secondReserved1
        \o message.expirationDate
        \o message.listingStartDate
        \o message.listingEndDate
        \o message.minimumLotMinimumExecutionSize
        \o message.lastPriceInPrecedingSession
        \o message.lastPriceInPrecedingSessionDate
        \o message.thirdReserved1
        \o message.secondReserved8
        \o message.thirdReserved8
        \o message.exMarkerCode
        \o message.securityType
        \o message.countryOfRegister
        \o message.exchangeMarketSize
        \o message.minimumPeakSizeMultiplier
        \o message.securityMaximumSpread
        \o message.clearingType
        \o message.strikePrice
        \o message.securityExchange
        \o message.reserved12
        \o message.fourthReserved1
        \o message.fourthReserved8
        \o message.fifthReserved8
        \o message.reserved1
        \o message.sixthReserved8
        \o message.seventhReserved8
        \o message.reserved4
        \o message.reserved2
        \o message.symbol
        \o message.description

DecodeInstrumentDirectoryEquitiesMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET isin == ReadBytes(instrument.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET sedol == ReadBytes(isin.rest, 8) IN IF ~sedol.ok THEN Fail ELSE
    LET allowedBookTypes == ReadBytes(sedol.rest, 1) IN IF ~allowedBookTypes.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(allowedBookTypes.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET venueInstrumentId == ReadBytes(sourceVenue.rest, 11) IN IF ~venueInstrumentId.ok THEN Fail ELSE
    LET segment == ReadBytes(venueInstrumentId.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET currency == ReadBytes(segment.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET tickId == ReadBytes(currency.rest, 2) IN IF ~tickId.ok THEN Fail ELSE
    LET previousDaysClosingPrice == ReadBytes(tickId.rest, 8) IN IF ~previousDaysClosingPrice.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(previousDaysClosingPrice.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET dynamicCircuitBreakerTolerances == ReadBytes(reserved8.rest, 8) IN IF ~dynamicCircuitBreakerTolerances.ok THEN Fail ELSE
    LET staticCircuitBreakerTolerances == ReadBytes(dynamicCircuitBreakerTolerances.rest, 8) IN IF ~staticCircuitBreakerTolerances.ok THEN Fail ELSE
    LET firstReserved1 == ReadBytes(staticCircuitBreakerTolerances.rest, 1) IN IF ~firstReserved1.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(firstReserved1.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(secondReserved1.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET listingStartDate == ReadBytes(expirationDate.rest, 8) IN IF ~listingStartDate.ok THEN Fail ELSE
    LET listingEndDate == ReadBytes(listingStartDate.rest, 8) IN IF ~listingEndDate.ok THEN Fail ELSE
    LET minimumLotMinimumExecutionSize == ReadBytes(listingEndDate.rest, 8) IN IF ~minimumLotMinimumExecutionSize.ok THEN Fail ELSE
    LET lastPriceInPrecedingSession == ReadBytes(minimumLotMinimumExecutionSize.rest, 8) IN IF ~lastPriceInPrecedingSession.ok THEN Fail ELSE
    LET lastPriceInPrecedingSessionDate == ReadBytes(lastPriceInPrecedingSession.rest, 8) IN IF ~lastPriceInPrecedingSessionDate.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(lastPriceInPrecedingSessionDate.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(thirdReserved1.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(secondReserved8.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    LET exMarkerCode == ReadBytes(thirdReserved8.rest, 2) IN IF ~exMarkerCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(exMarkerCode.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET countryOfRegister == ReadBytes(securityType.rest, 3) IN IF ~countryOfRegister.ok THEN Fail ELSE
    LET exchangeMarketSize == ReadBytes(countryOfRegister.rest, 8) IN IF ~exchangeMarketSize.ok THEN Fail ELSE
    LET minimumPeakSizeMultiplier == ReadBytes(exchangeMarketSize.rest, 8) IN IF ~minimumPeakSizeMultiplier.ok THEN Fail ELSE
    LET securityMaximumSpread == ReadBytes(minimumPeakSizeMultiplier.rest, 8) IN IF ~securityMaximumSpread.ok THEN Fail ELSE
    LET clearingType == ReadBytes(securityMaximumSpread.rest, 1) IN IF ~clearingType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(clearingType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(strikePrice.rest, 11) IN IF ~securityExchange.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(securityExchange.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(reserved12.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET fourthReserved8 == ReadBytes(fourthReserved1.rest, 8) IN IF ~fourthReserved8.ok THEN Fail ELSE
    LET fifthReserved8 == ReadBytes(fourthReserved8.rest, 8) IN IF ~fifthReserved8.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(fifthReserved8.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET sixthReserved8 == ReadBytes(reserved1.rest, 8) IN IF ~sixthReserved8.ok THEN Fail ELSE
    LET seventhReserved8 == ReadBytes(sixthReserved8.rest, 8) IN IF ~seventhReserved8.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(seventhReserved8.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved4.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET symbol == ReadBytes(reserved2.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET description == ReadBytes(symbol.rest, 40) IN IF ~description.ok THEN Fail ELSE
    Ok([ timestamp                       |-> timestamp.value,
         instrument                      |-> instrument.value,
         isin                            |-> isin.value,
         sedol                           |-> sedol.value,
         allowedBookTypes                |-> allowedBookTypes.value,
         sourceVenue                     |-> sourceVenue.value,
         venueInstrumentId               |-> venueInstrumentId.value,
         segment                         |-> segment.value,
         currency                        |-> currency.value,
         tickId                          |-> tickId.value,
         previousDaysClosingPrice        |-> previousDaysClosingPrice.value,
         reserved8                       |-> reserved8.value,
         dynamicCircuitBreakerTolerances |-> dynamicCircuitBreakerTolerances.value,
         staticCircuitBreakerTolerances  |-> staticCircuitBreakerTolerances.value,
         firstReserved1                  |-> firstReserved1.value,
         secondReserved1                 |-> secondReserved1.value,
         expirationDate                  |-> expirationDate.value,
         listingStartDate                |-> listingStartDate.value,
         listingEndDate                  |-> listingEndDate.value,
         minimumLotMinimumExecutionSize  |-> minimumLotMinimumExecutionSize.value,
         lastPriceInPrecedingSession     |-> lastPriceInPrecedingSession.value,
         lastPriceInPrecedingSessionDate |-> lastPriceInPrecedingSessionDate.value,
         thirdReserved1                  |-> thirdReserved1.value,
         secondReserved8                 |-> secondReserved8.value,
         thirdReserved8                  |-> thirdReserved8.value,
         exMarkerCode                    |-> exMarkerCode.value,
         securityType                    |-> securityType.value,
         countryOfRegister               |-> countryOfRegister.value,
         exchangeMarketSize              |-> exchangeMarketSize.value,
         minimumPeakSizeMultiplier       |-> minimumPeakSizeMultiplier.value,
         securityMaximumSpread           |-> securityMaximumSpread.value,
         clearingType                    |-> clearingType.value,
         strikePrice                     |-> strikePrice.value,
         securityExchange                |-> securityExchange.value,
         reserved12                      |-> reserved12.value,
         fourthReserved1                 |-> fourthReserved1.value,
         fourthReserved8                 |-> fourthReserved8.value,
         fifthReserved8                  |-> fifthReserved8.value,
         reserved1                       |-> reserved1.value,
         sixthReserved8                  |-> sixthReserved8.value,
         seventhReserved8                |-> seventhReserved8.value,
         reserved4                       |-> reserved4.value,
         reserved2                       |-> reserved2.value,
         symbol                          |-> symbol.value,
         description                     |-> description.value ], description.rest)

ZeroInstrumentDirectoryEquitiesMessage ==
    [ timestamp                       |-> [i \in 1 .. 8 |-> 0],
      instrument                      |-> [i \in 1 .. 8 |-> 0],
      isin                            |-> [i \in 1 .. 12 |-> 0],
      sedol                           |-> [i \in 1 .. 8 |-> 0],
      allowedBookTypes                |-> [i \in 1 .. 1 |-> 0],
      sourceVenue                     |-> [i \in 1 .. 2 |-> 0],
      venueInstrumentId               |-> [i \in 1 .. 11 |-> 0],
      segment                         |-> [i \in 1 .. 6 |-> 0],
      currency                        |-> [i \in 1 .. 3 |-> 0],
      tickId                          |-> [i \in 1 .. 2 |-> 0],
      previousDaysClosingPrice        |-> [i \in 1 .. 8 |-> 0],
      reserved8                       |-> [i \in 1 .. 8 |-> 0],
      dynamicCircuitBreakerTolerances |-> [i \in 1 .. 8 |-> 0],
      staticCircuitBreakerTolerances  |-> [i \in 1 .. 8 |-> 0],
      firstReserved1                  |-> [i \in 1 .. 1 |-> 0],
      secondReserved1                 |-> [i \in 1 .. 1 |-> 0],
      expirationDate                  |-> [i \in 1 .. 8 |-> 0],
      listingStartDate                |-> [i \in 1 .. 8 |-> 0],
      listingEndDate                  |-> [i \in 1 .. 8 |-> 0],
      minimumLotMinimumExecutionSize  |-> [i \in 1 .. 8 |-> 0],
      lastPriceInPrecedingSession     |-> [i \in 1 .. 8 |-> 0],
      lastPriceInPrecedingSessionDate |-> [i \in 1 .. 8 |-> 0],
      thirdReserved1                  |-> [i \in 1 .. 1 |-> 0],
      secondReserved8                 |-> [i \in 1 .. 8 |-> 0],
      thirdReserved8                  |-> [i \in 1 .. 8 |-> 0],
      exMarkerCode                    |-> [i \in 1 .. 2 |-> 0],
      securityType                    |-> [i \in 1 .. 1 |-> 0],
      countryOfRegister               |-> [i \in 1 .. 3 |-> 0],
      exchangeMarketSize              |-> [i \in 1 .. 8 |-> 0],
      minimumPeakSizeMultiplier       |-> [i \in 1 .. 8 |-> 0],
      securityMaximumSpread           |-> [i \in 1 .. 8 |-> 0],
      clearingType                    |-> [i \in 1 .. 1 |-> 0],
      strikePrice                     |-> [i \in 1 .. 8 |-> 0],
      securityExchange                |-> [i \in 1 .. 11 |-> 0],
      reserved12                      |-> [i \in 1 .. 12 |-> 0],
      fourthReserved1                 |-> [i \in 1 .. 1 |-> 0],
      fourthReserved8                 |-> [i \in 1 .. 8 |-> 0],
      fifthReserved8                  |-> [i \in 1 .. 8 |-> 0],
      reserved1                       |-> [i \in 1 .. 1 |-> 0],
      sixthReserved8                  |-> [i \in 1 .. 8 |-> 0],
      seventhReserved8                |-> [i \in 1 .. 8 |-> 0],
      reserved4                       |-> [i \in 1 .. 4 |-> 0],
      reserved2                       |-> [i \in 1 .. 2 |-> 0],
      symbol                          |-> [i \in 1 .. 8 |-> 0],
      description                     |-> [i \in 1 .. 40 |-> 0] ]

(* Instrument Directory Equities Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryEquitiesMessage ==
    { ZeroInstrumentDirectoryEquitiesMessage }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.sedol = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.allowedBookTypes = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.venueInstrumentId = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.tickId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.previousDaysClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.dynamicCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.staticCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.firstReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.listingStartDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.listingEndDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.minimumLotMinimumExecutionSize = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.lastPriceInPrecedingSession = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.lastPriceInPrecedingSessionDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.exMarkerCode = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.countryOfRegister = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.exchangeMarketSize = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.minimumPeakSizeMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.securityMaximumSpread = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.clearingType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.securityExchange = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.fourthReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.fifthReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.sixthReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.seventhReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryEquitiesMessage EXCEPT !.description = one] : one \in Sample(40) }

(***************************************************************************)
(* Statistics Snapshot Message: 270 bytes                                  *)
(***************************************************************************)

StatisticsSnapshotMessage ==
    [ timestamp                : Sample(8),
      instrument               : Sample(8),
      sourceVenue              : Sample(2),
      volume                   : Sample(8),
      volumeOnBookOnly         : Sample(8),
      vwap                     : Sample(8),
      vwapOnBookOnly           : Sample(8),
      numberOfTrades           : Sample(4),
      numberOfTradesOnBookOnly : Sample(4),
      turnover                 : Sample(8),
      turnoverOnBookOnly       : Sample(8),
      officialOpeningPrice     : Sample(8),
      officialClosingPrice     : Sample(8),
      tradeHighOnBookOnly      : Sample(8),
      tradeLowOnBookOnly       : Sample(8),
      tradeHigh                : Sample(8),
      tradeLow                 : Sample(8),
      fiftyTwoWeekTradeHigh    : Sample(8),
      fiftyTwoWeekTradeLow     : Sample(8),
      openingPriceIndicator    : Sample(1),
      closingPriceIndicator    : Sample(1),
      iauPrice                 : Sample(8),
      iauPairedSize            : Sample(8),
      imbalanceQuantity        : Sample(8),
      imbalanceDirection       : Sample(1),
      bestClosingBidPrice      : Sample(8),
      bestClosingAskPrice      : Sample(8),
      bestClosingBidSize       : Sample(8),
      bestClosingAskSize       : Sample(8),
      reserved8                : Sample(8),
      secondReserved8          : Sample(8),
      thirdReserved8           : Sample(8),
      fourthReserved8          : Sample(8),
      auctionType              : Sample(1),
      lastTradePrice           : Sample(8),
      lastTradeQuantity        : Sample(8),
      lastTradeTime            : Sample(8),
      staticReferencePrice     : Sample(8),
      dynamicReferencePrice    : Sample(8) ]

EncodeStatisticsSnapshotMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.volume
        \o message.volumeOnBookOnly
        \o message.vwap
        \o message.vwapOnBookOnly
        \o message.numberOfTrades
        \o message.numberOfTradesOnBookOnly
        \o message.turnover
        \o message.turnoverOnBookOnly
        \o message.officialOpeningPrice
        \o message.officialClosingPrice
        \o message.tradeHighOnBookOnly
        \o message.tradeLowOnBookOnly
        \o message.tradeHigh
        \o message.tradeLow
        \o message.fiftyTwoWeekTradeHigh
        \o message.fiftyTwoWeekTradeLow
        \o message.openingPriceIndicator
        \o message.closingPriceIndicator
        \o message.iauPrice
        \o message.iauPairedSize
        \o message.imbalanceQuantity
        \o message.imbalanceDirection
        \o message.bestClosingBidPrice
        \o message.bestClosingAskPrice
        \o message.bestClosingBidSize
        \o message.bestClosingAskSize
        \o message.reserved8
        \o message.secondReserved8
        \o message.thirdReserved8
        \o message.fourthReserved8
        \o message.auctionType
        \o message.lastTradePrice
        \o message.lastTradeQuantity
        \o message.lastTradeTime
        \o message.staticReferencePrice
        \o message.dynamicReferencePrice

DecodeStatisticsSnapshotMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET volume == ReadBytes(sourceVenue.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET volumeOnBookOnly == ReadBytes(volume.rest, 8) IN IF ~volumeOnBookOnly.ok THEN Fail ELSE
    LET vwap == ReadBytes(volumeOnBookOnly.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET vwapOnBookOnly == ReadBytes(vwap.rest, 8) IN IF ~vwapOnBookOnly.ok THEN Fail ELSE
    LET numberOfTrades == ReadBytes(vwapOnBookOnly.rest, 4) IN IF ~numberOfTrades.ok THEN Fail ELSE
    LET numberOfTradesOnBookOnly == ReadBytes(numberOfTrades.rest, 4) IN IF ~numberOfTradesOnBookOnly.ok THEN Fail ELSE
    LET turnover == ReadBytes(numberOfTradesOnBookOnly.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET turnoverOnBookOnly == ReadBytes(turnover.rest, 8) IN IF ~turnoverOnBookOnly.ok THEN Fail ELSE
    LET officialOpeningPrice == ReadBytes(turnoverOnBookOnly.rest, 8) IN IF ~officialOpeningPrice.ok THEN Fail ELSE
    LET officialClosingPrice == ReadBytes(officialOpeningPrice.rest, 8) IN IF ~officialClosingPrice.ok THEN Fail ELSE
    LET tradeHighOnBookOnly == ReadBytes(officialClosingPrice.rest, 8) IN IF ~tradeHighOnBookOnly.ok THEN Fail ELSE
    LET tradeLowOnBookOnly == ReadBytes(tradeHighOnBookOnly.rest, 8) IN IF ~tradeLowOnBookOnly.ok THEN Fail ELSE
    LET tradeHigh == ReadBytes(tradeLowOnBookOnly.rest, 8) IN IF ~tradeHigh.ok THEN Fail ELSE
    LET tradeLow == ReadBytes(tradeHigh.rest, 8) IN IF ~tradeLow.ok THEN Fail ELSE
    LET fiftyTwoWeekTradeHigh == ReadBytes(tradeLow.rest, 8) IN IF ~fiftyTwoWeekTradeHigh.ok THEN Fail ELSE
    LET fiftyTwoWeekTradeLow == ReadBytes(fiftyTwoWeekTradeHigh.rest, 8) IN IF ~fiftyTwoWeekTradeLow.ok THEN Fail ELSE
    LET openingPriceIndicator == ReadBytes(fiftyTwoWeekTradeLow.rest, 1) IN IF ~openingPriceIndicator.ok THEN Fail ELSE
    LET closingPriceIndicator == ReadBytes(openingPriceIndicator.rest, 1) IN IF ~closingPriceIndicator.ok THEN Fail ELSE
    LET iauPrice == ReadBytes(closingPriceIndicator.rest, 8) IN IF ~iauPrice.ok THEN Fail ELSE
    LET iauPairedSize == ReadBytes(iauPrice.rest, 8) IN IF ~iauPairedSize.ok THEN Fail ELSE
    LET imbalanceQuantity == ReadBytes(iauPairedSize.rest, 8) IN IF ~imbalanceQuantity.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(imbalanceQuantity.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET bestClosingBidPrice == ReadBytes(imbalanceDirection.rest, 8) IN IF ~bestClosingBidPrice.ok THEN Fail ELSE
    LET bestClosingAskPrice == ReadBytes(bestClosingBidPrice.rest, 8) IN IF ~bestClosingAskPrice.ok THEN Fail ELSE
    LET bestClosingBidSize == ReadBytes(bestClosingAskPrice.rest, 8) IN IF ~bestClosingBidSize.ok THEN Fail ELSE
    LET bestClosingAskSize == ReadBytes(bestClosingBidSize.rest, 8) IN IF ~bestClosingAskSize.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(bestClosingAskSize.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(reserved8.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(secondReserved8.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    LET fourthReserved8 == ReadBytes(thirdReserved8.rest, 8) IN IF ~fourthReserved8.ok THEN Fail ELSE
    LET auctionType == ReadBytes(fourthReserved8.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(auctionType.rest, 8) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET lastTradeQuantity == ReadBytes(lastTradePrice.rest, 8) IN IF ~lastTradeQuantity.ok THEN Fail ELSE
    LET lastTradeTime == ReadBytes(lastTradeQuantity.rest, 8) IN IF ~lastTradeTime.ok THEN Fail ELSE
    LET staticReferencePrice == ReadBytes(lastTradeTime.rest, 8) IN IF ~staticReferencePrice.ok THEN Fail ELSE
    LET dynamicReferencePrice == ReadBytes(staticReferencePrice.rest, 8) IN IF ~dynamicReferencePrice.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         instrument               |-> instrument.value,
         sourceVenue              |-> sourceVenue.value,
         volume                   |-> volume.value,
         volumeOnBookOnly         |-> volumeOnBookOnly.value,
         vwap                     |-> vwap.value,
         vwapOnBookOnly           |-> vwapOnBookOnly.value,
         numberOfTrades           |-> numberOfTrades.value,
         numberOfTradesOnBookOnly |-> numberOfTradesOnBookOnly.value,
         turnover                 |-> turnover.value,
         turnoverOnBookOnly       |-> turnoverOnBookOnly.value,
         officialOpeningPrice     |-> officialOpeningPrice.value,
         officialClosingPrice     |-> officialClosingPrice.value,
         tradeHighOnBookOnly      |-> tradeHighOnBookOnly.value,
         tradeLowOnBookOnly       |-> tradeLowOnBookOnly.value,
         tradeHigh                |-> tradeHigh.value,
         tradeLow                 |-> tradeLow.value,
         fiftyTwoWeekTradeHigh    |-> fiftyTwoWeekTradeHigh.value,
         fiftyTwoWeekTradeLow     |-> fiftyTwoWeekTradeLow.value,
         openingPriceIndicator    |-> openingPriceIndicator.value,
         closingPriceIndicator    |-> closingPriceIndicator.value,
         iauPrice                 |-> iauPrice.value,
         iauPairedSize            |-> iauPairedSize.value,
         imbalanceQuantity        |-> imbalanceQuantity.value,
         imbalanceDirection       |-> imbalanceDirection.value,
         bestClosingBidPrice      |-> bestClosingBidPrice.value,
         bestClosingAskPrice      |-> bestClosingAskPrice.value,
         bestClosingBidSize       |-> bestClosingBidSize.value,
         bestClosingAskSize       |-> bestClosingAskSize.value,
         reserved8                |-> reserved8.value,
         secondReserved8          |-> secondReserved8.value,
         thirdReserved8           |-> thirdReserved8.value,
         fourthReserved8          |-> fourthReserved8.value,
         auctionType              |-> auctionType.value,
         lastTradePrice           |-> lastTradePrice.value,
         lastTradeQuantity        |-> lastTradeQuantity.value,
         lastTradeTime            |-> lastTradeTime.value,
         staticReferencePrice     |-> staticReferencePrice.value,
         dynamicReferencePrice    |-> dynamicReferencePrice.value ], dynamicReferencePrice.rest)

ZeroStatisticsSnapshotMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      instrument               |-> [i \in 1 .. 8 |-> 0],
      sourceVenue              |-> [i \in 1 .. 2 |-> 0],
      volume                   |-> [i \in 1 .. 8 |-> 0],
      volumeOnBookOnly         |-> [i \in 1 .. 8 |-> 0],
      vwap                     |-> [i \in 1 .. 8 |-> 0],
      vwapOnBookOnly           |-> [i \in 1 .. 8 |-> 0],
      numberOfTrades           |-> [i \in 1 .. 4 |-> 0],
      numberOfTradesOnBookOnly |-> [i \in 1 .. 4 |-> 0],
      turnover                 |-> [i \in 1 .. 8 |-> 0],
      turnoverOnBookOnly       |-> [i \in 1 .. 8 |-> 0],
      officialOpeningPrice     |-> [i \in 1 .. 8 |-> 0],
      officialClosingPrice     |-> [i \in 1 .. 8 |-> 0],
      tradeHighOnBookOnly      |-> [i \in 1 .. 8 |-> 0],
      tradeLowOnBookOnly       |-> [i \in 1 .. 8 |-> 0],
      tradeHigh                |-> [i \in 1 .. 8 |-> 0],
      tradeLow                 |-> [i \in 1 .. 8 |-> 0],
      fiftyTwoWeekTradeHigh    |-> [i \in 1 .. 8 |-> 0],
      fiftyTwoWeekTradeLow     |-> [i \in 1 .. 8 |-> 0],
      openingPriceIndicator    |-> [i \in 1 .. 1 |-> 0],
      closingPriceIndicator    |-> [i \in 1 .. 1 |-> 0],
      iauPrice                 |-> [i \in 1 .. 8 |-> 0],
      iauPairedSize            |-> [i \in 1 .. 8 |-> 0],
      imbalanceQuantity        |-> [i \in 1 .. 8 |-> 0],
      imbalanceDirection       |-> [i \in 1 .. 1 |-> 0],
      bestClosingBidPrice      |-> [i \in 1 .. 8 |-> 0],
      bestClosingAskPrice      |-> [i \in 1 .. 8 |-> 0],
      bestClosingBidSize       |-> [i \in 1 .. 8 |-> 0],
      bestClosingAskSize       |-> [i \in 1 .. 8 |-> 0],
      reserved8                |-> [i \in 1 .. 8 |-> 0],
      secondReserved8          |-> [i \in 1 .. 8 |-> 0],
      thirdReserved8           |-> [i \in 1 .. 8 |-> 0],
      fourthReserved8          |-> [i \in 1 .. 8 |-> 0],
      auctionType              |-> [i \in 1 .. 1 |-> 0],
      lastTradePrice           |-> [i \in 1 .. 8 |-> 0],
      lastTradeQuantity        |-> [i \in 1 .. 8 |-> 0],
      lastTradeTime            |-> [i \in 1 .. 8 |-> 0],
      staticReferencePrice     |-> [i \in 1 .. 8 |-> 0],
      dynamicReferencePrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Statistics Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsSnapshotMessage ==
    { ZeroStatisticsSnapshotMessage }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.volumeOnBookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.vwapOnBookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.numberOfTrades = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.numberOfTradesOnBookOnly = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.turnoverOnBookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.officialOpeningPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.officialClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.tradeHighOnBookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.tradeLowOnBookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.tradeHigh = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.tradeLow = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.fiftyTwoWeekTradeHigh = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.fiftyTwoWeekTradeLow = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.openingPriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.closingPriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.iauPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.iauPairedSize = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.imbalanceQuantity = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.bestClosingBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.bestClosingAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.bestClosingBidSize = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.bestClosingAskSize = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.fourthReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.lastTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.lastTradeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.lastTradeTime = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.staticReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.dynamicReferencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
RecoveryRequestMessageCode == 129  \* 0x81
LoginResponseMessageCode == 2  \* 0x02
RecoveryResponseMessageCode == 130  \* 0x82
ReplayAndRecoveryCompleteMessageCode == 131  \* 0x83
SystemEventMessageCode == 83  \* 0x53
InstrumentStatusMessageCode == 72  \* 0x48
AddOrderIncrementalMessageCode == 70  \* 0x46
TopOfBookMessageCode == 105  \* 0x69
OrderBookClearMessageCode == 121  \* 0x79
TradeMessageCode == 80  \* 0x50
TradeCrossMessageCode == 113  \* 0x71
MifidIiTradeMessageCode == 81  \* 0x51
MiFidIiTradeCrossMessageCode == 86  \* 0x56
InstrumentDirectoryEquitiesMessageCode == 82  \* 0x52
StatisticsSnapshotMessageCode == 107  \* 0x6b

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {RecoveryRequestMessageCode}, body : RecoveryRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {RecoveryResponseMessageCode}, body : RecoveryResponseMessage ]
        \cup [ tag : {ReplayAndRecoveryCompleteMessageCode}, body : ReplayAndRecoveryCompleteMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {InstrumentStatusMessageCode}, body : InstrumentStatusMessage ]
        \cup [ tag : {AddOrderIncrementalMessageCode}, body : AddOrderIncrementalMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]
        \cup [ tag : {OrderBookClearMessageCode}, body : OrderBookClearMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeCrossMessageCode}, body : TradeCrossMessage ]
        \cup [ tag : {MifidIiTradeMessageCode}, body : MifidIiTradeMessage ]
        \cup [ tag : {MiFidIiTradeCrossMessageCode}, body : MiFidIiTradeCrossMessage ]
        \cup [ tag : {InstrumentDirectoryEquitiesMessageCode}, body : InstrumentDirectoryEquitiesMessage ]
        \cup [ tag : {StatisticsSnapshotMessageCode}, body : StatisticsSnapshotMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = RecoveryRequestMessageCode -> EncodeRecoveryRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = RecoveryResponseMessageCode -> EncodeRecoveryResponseMessage(message.body)
      [] message.tag = ReplayAndRecoveryCompleteMessageCode -> EncodeReplayAndRecoveryCompleteMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = InstrumentStatusMessageCode -> EncodeInstrumentStatusMessage(message.body)
      [] message.tag = AddOrderIncrementalMessageCode -> EncodeAddOrderIncrementalMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)
      [] message.tag = OrderBookClearMessageCode -> EncodeOrderBookClearMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeCrossMessageCode -> EncodeTradeCrossMessage(message.body)
      [] message.tag = MifidIiTradeMessageCode -> EncodeMifidIiTradeMessage(message.body)
      [] message.tag = MiFidIiTradeCrossMessageCode -> EncodeMiFidIiTradeCrossMessage(message.body)
      [] message.tag = InstrumentDirectoryEquitiesMessageCode -> EncodeInstrumentDirectoryEquitiesMessage(message.body)
      [] message.tag = StatisticsSnapshotMessageCode -> EncodeStatisticsSnapshotMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = RecoveryRequestMessageCode -> DecodeRecoveryRequestMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = RecoveryResponseMessageCode -> DecodeRecoveryResponseMessage(bytes)
              [] tag = ReplayAndRecoveryCompleteMessageCode -> DecodeReplayAndRecoveryCompleteMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = InstrumentStatusMessageCode -> DecodeInstrumentStatusMessage(bytes)
              [] tag = AddOrderIncrementalMessageCode -> DecodeAddOrderIncrementalMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] tag = OrderBookClearMessageCode -> DecodeOrderBookClearMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeCrossMessageCode -> DecodeTradeCrossMessage(bytes)
              [] tag = MifidIiTradeMessageCode -> DecodeMifidIiTradeMessage(bytes)
              [] tag = MiFidIiTradeCrossMessageCode -> DecodeMiFidIiTradeCrossMessage(bytes)
              [] tag = InstrumentDirectoryEquitiesMessageCode -> DecodeInstrumentDirectoryEquitiesMessage(bytes)
              [] tag = StatisticsSnapshotMessageCode -> DecodeStatisticsSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> RecoveryRequestMessageCode, body |-> one] : one \in CheckedRecoveryRequestMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> RecoveryResponseMessageCode, body |-> one] : one \in CheckedRecoveryResponseMessage }
        \cup { [tag |-> ReplayAndRecoveryCompleteMessageCode, body |-> one] : one \in CheckedReplayAndRecoveryCompleteMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> InstrumentStatusMessageCode, body |-> one] : one \in CheckedInstrumentStatusMessage }
        \cup { [tag |-> AddOrderIncrementalMessageCode, body |-> one] : one \in CheckedAddOrderIncrementalMessage }
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }
        \cup { [tag |-> OrderBookClearMessageCode, body |-> one] : one \in CheckedOrderBookClearMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeCrossMessageCode, body |-> one] : one \in CheckedTradeCrossMessage }
        \cup { [tag |-> MifidIiTradeMessageCode, body |-> one] : one \in CheckedMifidIiTradeMessage }
        \cup { [tag |-> MiFidIiTradeCrossMessageCode, body |-> one] : one \in CheckedMiFidIiTradeCrossMessage }
        \cup { [tag |-> InstrumentDirectoryEquitiesMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryEquitiesMessage }
        \cup { [tag |-> StatisticsSnapshotMessageCode, body |-> one] : one \in CheckedStatisticsSnapshotMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RecoveryRequestMessageCode, body |-> ZeroRecoveryRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RecoveryResponseMessageCode, body |-> ZeroRecoveryResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayAndRecoveryCompleteMessageCode, body |-> ZeroReplayAndRecoveryCompleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStatusMessageCode, body |-> ZeroInstrumentStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderIncrementalMessageCode, body |-> ZeroAddOrderIncrementalMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookClearMessageCode, body |-> ZeroOrderBookClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCrossMessageCode, body |-> ZeroTradeCrossMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MifidIiTradeMessageCode, body |-> ZeroMifidIiTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MiFidIiTradeCrossMessageCode, body |-> ZeroMiFidIiTradeCrossMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDirectoryEquitiesMessageCode, body |-> ZeroInstrumentDirectoryEquitiesMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsSnapshotMessageCode, body |-> ZeroStatisticsSnapshotMessage]] }

(***************************************************************************)
(* Tcp Unit, framed by Length                                              *)
(***************************************************************************)

TcpUnit ==
    [ marketDataGroup : Sample(1),
      sequenceNumber  : Sample(4),
      message         : SampleLists(OneMessage) ]

EncodeTcpUnitBody(message) ==
    EncodeUIntLE(Len(message.message), 1)
        \o message.marketDataGroup
        \o message.sequenceNumber
        \o EncodeMessageList(message.message)

(* Length counts the bytes it frames, so it is written from them *)
EncodeTcpUnit(message) ==
    LET body == EncodeTcpUnitBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeTcpUnitBody(bytes) ==
    LET messageCount == ReadUIntLE(bytes, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(messageCount.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(marketDataGroup.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET message == ReadMessageList(sequenceNumber.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         sequenceNumber  |-> sequenceNumber.value,
         message         |-> message.value ], message.rest)

DecodeTcpUnit(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeTcpUnitBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTcpUnit ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      message         |-> << >> ]

(* Tcp Unit at zero, then each field in turn at the values it is checked at *)
CheckedTcpUnit ==
    { ZeroTcpUnit }
        \cup { [ZeroTcpUnit EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroTcpUnit EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTcpUnit EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

(* A run of Tcp Unit, written one after another *)
RECURSIVE EncodeTcpUnitList(_)
EncodeTcpUnitList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTcpUnit(Head(messages)) \o EncodeTcpUnitList(Tail(messages))

(* As many Tcp Unit as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTcpUnitAll(_)
ReadTcpUnitAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTcpUnit(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTcpUnitAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tcp Unit of each kind, for the lists that carry them *)
OneTcpUnit == { ZeroTcpUnit }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ tcpUnit : SampleLists(OneTcpUnit) ]

EncodePacket(message) ==
    EncodeTcpUnitList(message.tcpUnit)

DecodePacket(bytes) ==
    LET tcpUnit == ReadTcpUnitAll(bytes) IN IF ~tcpUnit.ok THEN Fail ELSE
    Ok([ tcpUnit |-> tcpUnit.value ], tcpUnit.rest)

ZeroPacket ==
    [ tcpUnit |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.tcpUnit = one] : one \in SampleLists(OneTcpUnit) }

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

(* Every Login Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestMessage ==
    \A message \in CheckedLoginRequestMessage :
        LET read == DecodeLoginRequestMessage(EncodeLoginRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Recovery Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRecoveryRequestMessage ==
    \A message \in CheckedRecoveryRequestMessage :
        LET read == DecodeRecoveryRequestMessage(EncodeRecoveryRequestMessage(message))
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

(* Every Recovery Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRecoveryResponseMessage ==
    \A message \in CheckedRecoveryResponseMessage :
        LET read == DecodeRecoveryResponseMessage(EncodeRecoveryResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay And Recovery Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayAndRecoveryCompleteMessage ==
    \A message \in CheckedReplayAndRecoveryCompleteMessage :
        LET read == DecodeReplayAndRecoveryCompleteMessage(EncodeReplayAndRecoveryCompleteMessage(message))
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

(* Every Instrument Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStatusMessage ==
    \A message \in CheckedInstrumentStatusMessage :
        LET read == DecodeInstrumentStatusMessage(EncodeInstrumentStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Incremental Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderIncrementalMessage ==
    \A message \in CheckedAddOrderIncrementalMessage :
        LET read == DecodeAddOrderIncrementalMessage(EncodeAddOrderIncrementalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Of Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfBookMessage ==
    \A message \in CheckedTopOfBookMessage :
        LET read == DecodeTopOfBookMessage(EncodeTopOfBookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookClearMessage ==
    \A message \in CheckedOrderBookClearMessage :
        LET read == DecodeOrderBookClearMessage(EncodeOrderBookClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cross Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCrossMessage ==
    \A message \in CheckedTradeCrossMessage :
        LET read == DecodeTradeCrossMessage(EncodeTradeCrossMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Ii Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidIiTradeMessage ==
    \A message \in CheckedMifidIiTradeMessage :
        LET read == DecodeMifidIiTradeMessage(EncodeMifidIiTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mi Fid Ii Trade Cross Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMiFidIiTradeCrossMessage ==
    \A message \in CheckedMiFidIiTradeCrossMessage :
        LET read == DecodeMiFidIiTradeCrossMessage(EncodeMiFidIiTradeCrossMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Directory Equities Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDirectoryEquitiesMessage ==
    \A message \in CheckedInstrumentDirectoryEquitiesMessage :
        LET read == DecodeInstrumentDirectoryEquitiesMessage(EncodeInstrumentDirectoryEquitiesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Statistics Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsSnapshotMessage ==
    \A message \in CheckedStatisticsSnapshotMessage :
        LET read == DecodeStatisticsSnapshotMessage(EncodeStatisticsSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Unit decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpUnit ==
    \A message \in CheckedTcpUnit :
        LET read == DecodeTcpUnit(EncodeTcpUnit(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Length is written from the bytes it frames *)
FramesTcpUnit ==
    \A message \in CheckedTcpUnit :
        LET bytes == EncodeTcpUnit(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
