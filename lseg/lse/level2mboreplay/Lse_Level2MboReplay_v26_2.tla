--------------------- MODULE Lse_Level2MboReplay_v26_2 ---------------------
(***************************************************************************)
(* London Stock Exchange Level 2 MBO Replay v26.2                          *)
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
(* Note: Allowed Book Types is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Trade Flags is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
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
(* Replay Request Message: 12 bytes                                        *)
(***************************************************************************)

ReplayRequestMessage ==
    [ firstMessage : Sample(4),
      count        : Sample(4),
      requestId    : Sample(4) ]

EncodeReplayRequestMessage(message) ==
    message.firstMessage
        \o message.count
        \o message.requestId

DecodeReplayRequestMessage(bytes) ==
    LET firstMessage == ReadBytes(bytes, 4) IN IF ~firstMessage.ok THEN Fail ELSE
    LET count == ReadBytes(firstMessage.rest, 4) IN IF ~count.ok THEN Fail ELSE
    LET requestId == ReadBytes(count.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ firstMessage |-> firstMessage.value,
         count        |-> count.value,
         requestId    |-> requestId.value ], requestId.rest)

ZeroReplayRequestMessage ==
    [ firstMessage |-> [i \in 1 .. 4 |-> 0],
      count        |-> [i \in 1 .. 4 |-> 0],
      requestId    |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.firstMessage = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.count = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }

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
(* Replay Response Message: 13 bytes                                       *)
(***************************************************************************)

ReplayResponseMessage ==
    [ firstMessage : Sample(4),
      count        : Sample(4),
      replayStatus : Sample(1),
      requestId    : Sample(4) ]

EncodeReplayResponseMessage(message) ==
    message.firstMessage
        \o message.count
        \o message.replayStatus
        \o message.requestId

DecodeReplayResponseMessage(bytes) ==
    LET firstMessage == ReadBytes(bytes, 4) IN IF ~firstMessage.ok THEN Fail ELSE
    LET count == ReadBytes(firstMessage.rest, 4) IN IF ~count.ok THEN Fail ELSE
    LET replayStatus == ReadBytes(count.rest, 1) IN IF ~replayStatus.ok THEN Fail ELSE
    LET requestId == ReadBytes(replayStatus.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ firstMessage |-> firstMessage.value,
         count        |-> count.value,
         replayStatus |-> replayStatus.value,
         requestId    |-> requestId.value ], requestId.rest)

ZeroReplayResponseMessage ==
    [ firstMessage |-> [i \in 1 .. 4 |-> 0],
      count        |-> [i \in 1 .. 4 |-> 0],
      replayStatus |-> [i \in 1 .. 1 |-> 0],
      requestId    |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Response Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayResponseMessage ==
    { ZeroReplayResponseMessage }
        \cup { [ZeroReplayResponseMessage EXCEPT !.firstMessage = one] : one \in Sample(4) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.count = one] : one \in Sample(4) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.replayStatus = one] : one \in Sample(1) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.requestId = one] : one \in Sample(4) }

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
(* Instrument Directory Message: 138 bytes                                 *)
(***************************************************************************)

InstrumentDirectoryMessage ==
    [ timestamp                       : Sample(8),
      instrument                      : Sample(8),
      isin                            : Sample(12),
      allowedBookTypes                : Sample(1),
      sourceVenue                     : Sample(2),
      venueInstrumentId               : Sample(11),
      tickId                          : Sample(2),
      reserved8                       : Sample(8),
      dynamicCircuitBreakerTolerances : Sample(8),
      staticCircuitBreakerTolerances  : Sample(8),
      segment                         : Sample(6),
      reserved12                      : Sample(12),
      reserved11                      : Sample(11),
      currency                        : Sample(3),
      partitionId                     : Sample(1),
      reserved4                       : Sample(4),
      averageDailyTurnoverAdt         : Sample(8),
      secondReserved8                 : Sample(8),
      reserved1                       : Sample(1),
      thirdReserved8                  : Sample(8),
      fourthReserved8                 : Sample(8) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.isin
        \o message.allowedBookTypes
        \o message.sourceVenue
        \o message.venueInstrumentId
        \o message.tickId
        \o message.reserved8
        \o message.dynamicCircuitBreakerTolerances
        \o message.staticCircuitBreakerTolerances
        \o message.segment
        \o message.reserved12
        \o message.reserved11
        \o message.currency
        \o message.partitionId
        \o message.reserved4
        \o message.averageDailyTurnoverAdt
        \o message.secondReserved8
        \o message.reserved1
        \o message.thirdReserved8
        \o message.fourthReserved8

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET isin == ReadBytes(instrument.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET allowedBookTypes == ReadBytes(isin.rest, 1) IN IF ~allowedBookTypes.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(allowedBookTypes.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET venueInstrumentId == ReadBytes(sourceVenue.rest, 11) IN IF ~venueInstrumentId.ok THEN Fail ELSE
    LET tickId == ReadBytes(venueInstrumentId.rest, 2) IN IF ~tickId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(tickId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET dynamicCircuitBreakerTolerances == ReadBytes(reserved8.rest, 8) IN IF ~dynamicCircuitBreakerTolerances.ok THEN Fail ELSE
    LET staticCircuitBreakerTolerances == ReadBytes(dynamicCircuitBreakerTolerances.rest, 8) IN IF ~staticCircuitBreakerTolerances.ok THEN Fail ELSE
    LET segment == ReadBytes(staticCircuitBreakerTolerances.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(segment.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    LET reserved11 == ReadBytes(reserved12.rest, 11) IN IF ~reserved11.ok THEN Fail ELSE
    LET currency == ReadBytes(reserved11.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET partitionId == ReadBytes(currency.rest, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(partitionId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET averageDailyTurnoverAdt == ReadBytes(reserved4.rest, 8) IN IF ~averageDailyTurnoverAdt.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(averageDailyTurnoverAdt.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(secondReserved8.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(reserved1.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    LET fourthReserved8 == ReadBytes(thirdReserved8.rest, 8) IN IF ~fourthReserved8.ok THEN Fail ELSE
    Ok([ timestamp                       |-> timestamp.value,
         instrument                      |-> instrument.value,
         isin                            |-> isin.value,
         allowedBookTypes                |-> allowedBookTypes.value,
         sourceVenue                     |-> sourceVenue.value,
         venueInstrumentId               |-> venueInstrumentId.value,
         tickId                          |-> tickId.value,
         reserved8                       |-> reserved8.value,
         dynamicCircuitBreakerTolerances |-> dynamicCircuitBreakerTolerances.value,
         staticCircuitBreakerTolerances  |-> staticCircuitBreakerTolerances.value,
         segment                         |-> segment.value,
         reserved12                      |-> reserved12.value,
         reserved11                      |-> reserved11.value,
         currency                        |-> currency.value,
         partitionId                     |-> partitionId.value,
         reserved4                       |-> reserved4.value,
         averageDailyTurnoverAdt         |-> averageDailyTurnoverAdt.value,
         secondReserved8                 |-> secondReserved8.value,
         reserved1                       |-> reserved1.value,
         thirdReserved8                  |-> thirdReserved8.value,
         fourthReserved8                 |-> fourthReserved8.value ], fourthReserved8.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp                       |-> [i \in 1 .. 8 |-> 0],
      instrument                      |-> [i \in 1 .. 8 |-> 0],
      isin                            |-> [i \in 1 .. 12 |-> 0],
      allowedBookTypes                |-> [i \in 1 .. 1 |-> 0],
      sourceVenue                     |-> [i \in 1 .. 2 |-> 0],
      venueInstrumentId               |-> [i \in 1 .. 11 |-> 0],
      tickId                          |-> [i \in 1 .. 2 |-> 0],
      reserved8                       |-> [i \in 1 .. 8 |-> 0],
      dynamicCircuitBreakerTolerances |-> [i \in 1 .. 8 |-> 0],
      staticCircuitBreakerTolerances  |-> [i \in 1 .. 8 |-> 0],
      segment                         |-> [i \in 1 .. 6 |-> 0],
      reserved12                      |-> [i \in 1 .. 12 |-> 0],
      reserved11                      |-> [i \in 1 .. 11 |-> 0],
      currency                        |-> [i \in 1 .. 3 |-> 0],
      partitionId                     |-> [i \in 1 .. 1 |-> 0],
      reserved4                       |-> [i \in 1 .. 4 |-> 0],
      averageDailyTurnoverAdt         |-> [i \in 1 .. 8 |-> 0],
      secondReserved8                 |-> [i \in 1 .. 8 |-> 0],
      reserved1                       |-> [i \in 1 .. 1 |-> 0],
      thirdReserved8                  |-> [i \in 1 .. 8 |-> 0],
      fourthReserved8                 |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryMessage ==
    { ZeroInstrumentDirectoryMessage }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.allowedBookTypes = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.venueInstrumentId = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.tickId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.dynamicCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.staticCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved11 = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.averageDailyTurnoverAdt = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.fourthReserved8 = one] : one \in Sample(8) }

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
(* Add Order Mbo Message: 64 bytes                                         *)
(***************************************************************************)

AddOrderMboMessage ==
    [ timestamp     : Sample(8),
      orderId       : Sample(8),
      side          : Sample(1),
      size          : Sample(8),
      instrument    : Sample(8),
      price         : Sample(8),
      reserved8     : Sample(8),
      sourceVenue   : Sample(2),
      orderBookType : Sample(1),
      participant   : Sample(11),
      depth         : Sample(1) ]

EncodeAddOrderMboMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.side
        \o message.size
        \o message.instrument
        \o message.price
        \o message.reserved8
        \o message.sourceVenue
        \o message.orderBookType
        \o message.participant
        \o message.depth

DecodeAddOrderMboMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET size == ReadBytes(side.rest, 8) IN IF ~size.ok THEN Fail ELSE
    LET instrument == ReadBytes(size.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET price == ReadBytes(instrument.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(price.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(reserved8.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(sourceVenue.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET participant == ReadBytes(orderBookType.rest, 11) IN IF ~participant.ok THEN Fail ELSE
    LET depth == ReadBytes(participant.rest, 1) IN IF ~depth.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         orderId       |-> orderId.value,
         side          |-> side.value,
         size          |-> size.value,
         instrument    |-> instrument.value,
         price         |-> price.value,
         reserved8     |-> reserved8.value,
         sourceVenue   |-> sourceVenue.value,
         orderBookType |-> orderBookType.value,
         participant   |-> participant.value,
         depth         |-> depth.value ], depth.rest)

ZeroAddOrderMboMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      size          |-> [i \in 1 .. 8 |-> 0],
      instrument    |-> [i \in 1 .. 8 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      reserved8     |-> [i \in 1 .. 8 |-> 0],
      sourceVenue   |-> [i \in 1 .. 2 |-> 0],
      orderBookType |-> [i \in 1 .. 1 |-> 0],
      participant   |-> [i \in 1 .. 11 |-> 0],
      depth         |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Mbo Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMboMessage ==
    { ZeroAddOrderMboMessage }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.size = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.participant = one] : one \in Sample(11) }
        \cup { [ZeroAddOrderMboMessage EXCEPT !.depth = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Mbo Message: 43 bytes                                   *)
(***************************************************************************)

AddOrderShortMboMessage ==
    [ orderId     : Sample(8),
      size        : Sample(8),
      price       : Sample(8),
      reserved8   : Sample(8),
      participant : Sample(11) ]

EncodeAddOrderShortMboMessage(message) ==
    message.orderId
        \o message.size
        \o message.price
        \o message.reserved8
        \o message.participant

DecodeAddOrderShortMboMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET size == ReadBytes(orderId.rest, 8) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(price.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET participant == ReadBytes(reserved8.rest, 11) IN IF ~participant.ok THEN Fail ELSE
    Ok([ orderId     |-> orderId.value,
         size        |-> size.value,
         price       |-> price.value,
         reserved8   |-> reserved8.value,
         participant |-> participant.value ], participant.rest)

ZeroAddOrderShortMboMessage ==
    [ orderId     |-> [i \in 1 .. 8 |-> 0],
      size        |-> [i \in 1 .. 8 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      reserved8   |-> [i \in 1 .. 8 |-> 0],
      participant |-> [i \in 1 .. 11 |-> 0] ]

(* Add Order Short Mbo Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMboMessage ==
    { ZeroAddOrderShortMboMessage }
        \cup { [ZeroAddOrderShortMboMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMboMessage EXCEPT !.size = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMboMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMboMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMboMessage EXCEPT !.participant = one] : one \in Sample(11) }

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
(* Statistics Message: 74 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ timestamp                : Sample(8),
      instrument               : Sample(8),
      sourceVenue              : Sample(2),
      volume                   : Sample(8),
      volumeOnbookOnly         : Sample(8),
      vwap                     : Sample(8),
      vwapOnbookOnly           : Sample(8),
      numberOfTrades           : Sample(4),
      numberOfTradesOnbookOnly : Sample(4),
      turnover                 : Sample(8),
      turnoverOnbookOnly       : Sample(8) ]

EncodeStatisticsMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.volume
        \o message.volumeOnbookOnly
        \o message.vwap
        \o message.vwapOnbookOnly
        \o message.numberOfTrades
        \o message.numberOfTradesOnbookOnly
        \o message.turnover
        \o message.turnoverOnbookOnly

DecodeStatisticsMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET volume == ReadBytes(sourceVenue.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET volumeOnbookOnly == ReadBytes(volume.rest, 8) IN IF ~volumeOnbookOnly.ok THEN Fail ELSE
    LET vwap == ReadBytes(volumeOnbookOnly.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET vwapOnbookOnly == ReadBytes(vwap.rest, 8) IN IF ~vwapOnbookOnly.ok THEN Fail ELSE
    LET numberOfTrades == ReadBytes(vwapOnbookOnly.rest, 4) IN IF ~numberOfTrades.ok THEN Fail ELSE
    LET numberOfTradesOnbookOnly == ReadBytes(numberOfTrades.rest, 4) IN IF ~numberOfTradesOnbookOnly.ok THEN Fail ELSE
    LET turnover == ReadBytes(numberOfTradesOnbookOnly.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET turnoverOnbookOnly == ReadBytes(turnover.rest, 8) IN IF ~turnoverOnbookOnly.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         instrument               |-> instrument.value,
         sourceVenue              |-> sourceVenue.value,
         volume                   |-> volume.value,
         volumeOnbookOnly         |-> volumeOnbookOnly.value,
         vwap                     |-> vwap.value,
         vwapOnbookOnly           |-> vwapOnbookOnly.value,
         numberOfTrades           |-> numberOfTrades.value,
         numberOfTradesOnbookOnly |-> numberOfTradesOnbookOnly.value,
         turnover                 |-> turnover.value,
         turnoverOnbookOnly       |-> turnoverOnbookOnly.value ], turnoverOnbookOnly.rest)

ZeroStatisticsMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      instrument               |-> [i \in 1 .. 8 |-> 0],
      sourceVenue              |-> [i \in 1 .. 2 |-> 0],
      volume                   |-> [i \in 1 .. 8 |-> 0],
      volumeOnbookOnly         |-> [i \in 1 .. 8 |-> 0],
      vwap                     |-> [i \in 1 .. 8 |-> 0],
      vwapOnbookOnly           |-> [i \in 1 .. 8 |-> 0],
      numberOfTrades           |-> [i \in 1 .. 4 |-> 0],
      numberOfTradesOnbookOnly |-> [i \in 1 .. 4 |-> 0],
      turnover                 |-> [i \in 1 .. 8 |-> 0],
      turnoverOnbookOnly       |-> [i \in 1 .. 8 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroStatisticsMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.volumeOnbookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.vwapOnbookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.numberOfTrades = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.numberOfTradesOnbookOnly = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.turnoverOnbookOnly = one] : one \in Sample(8) }

(***************************************************************************)
(* Statistics Update Message: 47 bytes                                     *)
(***************************************************************************)

StatisticsUpdateMessage ==
    [ timestamp                    : Sample(8),
      instrument                   : Sample(8),
      sourceVenue                  : Sample(2),
      statisticType                : Sample(2),
      statisticPrice               : Sample(8),
      statisticSize                : Sample(8),
      auctionType                  : Sample(1),
      imbalanceQuantity            : Sample(8),
      auctionInfo                  : Sample(1),
      openingClosingPriceIndicator : Sample(1) ]

EncodeStatisticsUpdateMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.statisticType
        \o message.statisticPrice
        \o message.statisticSize
        \o message.auctionType
        \o message.imbalanceQuantity
        \o message.auctionInfo
        \o message.openingClosingPriceIndicator

DecodeStatisticsUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET statisticType == ReadBytes(sourceVenue.rest, 2) IN IF ~statisticType.ok THEN Fail ELSE
    LET statisticPrice == ReadBytes(statisticType.rest, 8) IN IF ~statisticPrice.ok THEN Fail ELSE
    LET statisticSize == ReadBytes(statisticPrice.rest, 8) IN IF ~statisticSize.ok THEN Fail ELSE
    LET auctionType == ReadBytes(statisticSize.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET imbalanceQuantity == ReadBytes(auctionType.rest, 8) IN IF ~imbalanceQuantity.ok THEN Fail ELSE
    LET auctionInfo == ReadBytes(imbalanceQuantity.rest, 1) IN IF ~auctionInfo.ok THEN Fail ELSE
    LET openingClosingPriceIndicator == ReadBytes(auctionInfo.rest, 1) IN IF ~openingClosingPriceIndicator.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         instrument                   |-> instrument.value,
         sourceVenue                  |-> sourceVenue.value,
         statisticType                |-> statisticType.value,
         statisticPrice               |-> statisticPrice.value,
         statisticSize                |-> statisticSize.value,
         auctionType                  |-> auctionType.value,
         imbalanceQuantity            |-> imbalanceQuantity.value,
         auctionInfo                  |-> auctionInfo.value,
         openingClosingPriceIndicator |-> openingClosingPriceIndicator.value ], openingClosingPriceIndicator.rest)

ZeroStatisticsUpdateMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      instrument                   |-> [i \in 1 .. 8 |-> 0],
      sourceVenue                  |-> [i \in 1 .. 2 |-> 0],
      statisticType                |-> [i \in 1 .. 2 |-> 0],
      statisticPrice               |-> [i \in 1 .. 8 |-> 0],
      statisticSize                |-> [i \in 1 .. 8 |-> 0],
      auctionType                  |-> [i \in 1 .. 1 |-> 0],
      imbalanceQuantity            |-> [i \in 1 .. 8 |-> 0],
      auctionInfo                  |-> [i \in 1 .. 1 |-> 0],
      openingClosingPriceIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Statistics Update Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsUpdateMessage ==
    { ZeroStatisticsUpdateMessage }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.statisticType = one] : one \in Sample(2) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.statisticPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.statisticSize = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.imbalanceQuantity = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.auctionInfo = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsUpdateMessage EXCEPT !.openingClosingPriceIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
ReplayRequestMessageCode == 3  \* 0x03
LoginResponseMessageCode == 2  \* 0x02
ReplayResponseMessageCode == 4  \* 0x04
ReplayAndRecoveryCompleteMessageCode == 131  \* 0x83
SystemEventMessageCode == 83  \* 0x53
InstrumentDirectoryMessageCode == 112  \* 0x70
InstrumentStatusMessageCode == 72  \* 0x48
AddOrderMboMessageCode == 65  \* 0x41
AddOrderShortMboMessageCode == 101  \* 0x65
OrderBookClearMessageCode == 121  \* 0x79
TradeMessageCode == 80  \* 0x50
StatisticsMessageCode == 119  \* 0x77
StatisticsUpdateMessageCode == 106  \* 0x6a

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayResponseMessageCode}, body : ReplayResponseMessage ]
        \cup [ tag : {ReplayAndRecoveryCompleteMessageCode}, body : ReplayAndRecoveryCompleteMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {InstrumentStatusMessageCode}, body : InstrumentStatusMessage ]
        \cup [ tag : {AddOrderMboMessageCode}, body : AddOrderMboMessage ]
        \cup [ tag : {AddOrderShortMboMessageCode}, body : AddOrderShortMboMessage ]
        \cup [ tag : {OrderBookClearMessageCode}, body : OrderBookClearMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {StatisticsUpdateMessageCode}, body : StatisticsUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayResponseMessageCode -> EncodeReplayResponseMessage(message.body)
      [] message.tag = ReplayAndRecoveryCompleteMessageCode -> EncodeReplayAndRecoveryCompleteMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = InstrumentStatusMessageCode -> EncodeInstrumentStatusMessage(message.body)
      [] message.tag = AddOrderMboMessageCode -> EncodeAddOrderMboMessage(message.body)
      [] message.tag = AddOrderShortMboMessageCode -> EncodeAddOrderShortMboMessage(message.body)
      [] message.tag = OrderBookClearMessageCode -> EncodeOrderBookClearMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = StatisticsUpdateMessageCode -> EncodeStatisticsUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayResponseMessageCode -> DecodeReplayResponseMessage(bytes)
              [] tag = ReplayAndRecoveryCompleteMessageCode -> DecodeReplayAndRecoveryCompleteMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = InstrumentStatusMessageCode -> DecodeInstrumentStatusMessage(bytes)
              [] tag = AddOrderMboMessageCode -> DecodeAddOrderMboMessage(bytes)
              [] tag = AddOrderShortMboMessageCode -> DecodeAddOrderShortMboMessage(bytes)
              [] tag = OrderBookClearMessageCode -> DecodeOrderBookClearMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = StatisticsUpdateMessageCode -> DecodeStatisticsUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayResponseMessageCode, body |-> one] : one \in CheckedReplayResponseMessage }
        \cup { [tag |-> ReplayAndRecoveryCompleteMessageCode, body |-> one] : one \in CheckedReplayAndRecoveryCompleteMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> InstrumentStatusMessageCode, body |-> one] : one \in CheckedInstrumentStatusMessage }
        \cup { [tag |-> AddOrderMboMessageCode, body |-> one] : one \in CheckedAddOrderMboMessage }
        \cup { [tag |-> AddOrderShortMboMessageCode, body |-> one] : one \in CheckedAddOrderShortMboMessage }
        \cup { [tag |-> OrderBookClearMessageCode, body |-> one] : one \in CheckedOrderBookClearMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> StatisticsUpdateMessageCode, body |-> one] : one \in CheckedStatisticsUpdateMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayRequestMessageCode, body |-> ZeroReplayRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayResponseMessageCode, body |-> ZeroReplayResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayAndRecoveryCompleteMessageCode, body |-> ZeroReplayAndRecoveryCompleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStatusMessageCode, body |-> ZeroInstrumentStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMboMessageCode, body |-> ZeroAddOrderMboMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderShortMboMessageCode, body |-> ZeroAddOrderShortMboMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookClearMessageCode, body |-> ZeroOrderBookClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsUpdateMessageCode, body |-> ZeroStatisticsUpdateMessage]] }

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

(* Every Replay Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequestMessage ==
    \A message \in CheckedReplayRequestMessage :
        LET read == DecodeReplayRequestMessage(EncodeReplayRequestMessage(message))
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

(* Every Replay Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayResponseMessage ==
    \A message \in CheckedReplayResponseMessage :
        LET read == DecodeReplayResponseMessage(EncodeReplayResponseMessage(message))
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

(* Every Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDirectoryMessage ==
    \A message \in CheckedInstrumentDirectoryMessage :
        LET read == DecodeInstrumentDirectoryMessage(EncodeInstrumentDirectoryMessage(message))
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

(* Every Add Order Mbo Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMboMessage ==
    \A message \in CheckedAddOrderMboMessage :
        LET read == DecodeAddOrderMboMessage(EncodeAddOrderMboMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Short Mbo Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderShortMboMessage ==
    \A message \in CheckedAddOrderShortMboMessage :
        LET read == DecodeAddOrderShortMboMessage(EncodeAddOrderShortMboMessage(message))
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

(* Every Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsMessage ==
    \A message \in CheckedStatisticsMessage :
        LET read == DecodeStatisticsMessage(EncodeStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Statistics Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsUpdateMessage ==
    \A message \in CheckedStatisticsUpdateMessage :
        LET read == DecodeStatisticsUpdateMessage(EncodeStatisticsUpdateMessage(message))
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
