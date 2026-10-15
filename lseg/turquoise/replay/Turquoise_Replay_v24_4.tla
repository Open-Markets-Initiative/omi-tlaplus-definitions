---------------------- MODULE Turquoise_Replay_v24_4 -----------------------
(***************************************************************************)
(* London Stock Exchange Replay v24.4                                      *)
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
(* Note: Order Modify Flags is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Top Of Book Flags is a bit field set, checked as its 1 byte       *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
      priceBandTolerances             : Sample(8),
      dynamicCircuitBreakerTolerances : Sample(8),
      staticCircuitBreakerTolerances  : Sample(8),
      segment                         : Sample(6),
      reserved12                      : Sample(12),
      reserved11                      : Sample(11),
      currency                        : Sample(3),
      reserved1                       : Sample(1),
      reserved4                       : Sample(4),
      averageDailyTurnoverAdt         : Sample(8),
      reserved8                       : Sample(8),
      secondReserved1                 : Sample(1),
      secondReserved8                 : Sample(8),
      thirdReserved8                  : Sample(8) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.isin
        \o message.allowedBookTypes
        \o message.sourceVenue
        \o message.venueInstrumentId
        \o message.tickId
        \o message.priceBandTolerances
        \o message.dynamicCircuitBreakerTolerances
        \o message.staticCircuitBreakerTolerances
        \o message.segment
        \o message.reserved12
        \o message.reserved11
        \o message.currency
        \o message.reserved1
        \o message.reserved4
        \o message.averageDailyTurnoverAdt
        \o message.reserved8
        \o message.secondReserved1
        \o message.secondReserved8
        \o message.thirdReserved8

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET isin == ReadBytes(instrument.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET allowedBookTypes == ReadBytes(isin.rest, 1) IN IF ~allowedBookTypes.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(allowedBookTypes.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET venueInstrumentId == ReadBytes(sourceVenue.rest, 11) IN IF ~venueInstrumentId.ok THEN Fail ELSE
    LET tickId == ReadBytes(venueInstrumentId.rest, 2) IN IF ~tickId.ok THEN Fail ELSE
    LET priceBandTolerances == ReadBytes(tickId.rest, 8) IN IF ~priceBandTolerances.ok THEN Fail ELSE
    LET dynamicCircuitBreakerTolerances == ReadBytes(priceBandTolerances.rest, 8) IN IF ~dynamicCircuitBreakerTolerances.ok THEN Fail ELSE
    LET staticCircuitBreakerTolerances == ReadBytes(dynamicCircuitBreakerTolerances.rest, 8) IN IF ~staticCircuitBreakerTolerances.ok THEN Fail ELSE
    LET segment == ReadBytes(staticCircuitBreakerTolerances.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(segment.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    LET reserved11 == ReadBytes(reserved12.rest, 11) IN IF ~reserved11.ok THEN Fail ELSE
    LET currency == ReadBytes(reserved11.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(currency.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reserved1.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET averageDailyTurnoverAdt == ReadBytes(reserved4.rest, 8) IN IF ~averageDailyTurnoverAdt.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(averageDailyTurnoverAdt.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(reserved8.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(secondReserved1.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(secondReserved8.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    Ok([ timestamp                       |-> timestamp.value,
         instrument                      |-> instrument.value,
         isin                            |-> isin.value,
         allowedBookTypes                |-> allowedBookTypes.value,
         sourceVenue                     |-> sourceVenue.value,
         venueInstrumentId               |-> venueInstrumentId.value,
         tickId                          |-> tickId.value,
         priceBandTolerances             |-> priceBandTolerances.value,
         dynamicCircuitBreakerTolerances |-> dynamicCircuitBreakerTolerances.value,
         staticCircuitBreakerTolerances  |-> staticCircuitBreakerTolerances.value,
         segment                         |-> segment.value,
         reserved12                      |-> reserved12.value,
         reserved11                      |-> reserved11.value,
         currency                        |-> currency.value,
         reserved1                       |-> reserved1.value,
         reserved4                       |-> reserved4.value,
         averageDailyTurnoverAdt         |-> averageDailyTurnoverAdt.value,
         reserved8                       |-> reserved8.value,
         secondReserved1                 |-> secondReserved1.value,
         secondReserved8                 |-> secondReserved8.value,
         thirdReserved8                  |-> thirdReserved8.value ], thirdReserved8.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp                       |-> [i \in 1 .. 8 |-> 0],
      instrument                      |-> [i \in 1 .. 8 |-> 0],
      isin                            |-> [i \in 1 .. 12 |-> 0],
      allowedBookTypes                |-> [i \in 1 .. 1 |-> 0],
      sourceVenue                     |-> [i \in 1 .. 2 |-> 0],
      venueInstrumentId               |-> [i \in 1 .. 11 |-> 0],
      tickId                          |-> [i \in 1 .. 2 |-> 0],
      priceBandTolerances             |-> [i \in 1 .. 8 |-> 0],
      dynamicCircuitBreakerTolerances |-> [i \in 1 .. 8 |-> 0],
      staticCircuitBreakerTolerances  |-> [i \in 1 .. 8 |-> 0],
      segment                         |-> [i \in 1 .. 6 |-> 0],
      reserved12                      |-> [i \in 1 .. 12 |-> 0],
      reserved11                      |-> [i \in 1 .. 11 |-> 0],
      currency                        |-> [i \in 1 .. 3 |-> 0],
      reserved1                       |-> [i \in 1 .. 1 |-> 0],
      reserved4                       |-> [i \in 1 .. 4 |-> 0],
      averageDailyTurnoverAdt         |-> [i \in 1 .. 8 |-> 0],
      reserved8                       |-> [i \in 1 .. 8 |-> 0],
      secondReserved1                 |-> [i \in 1 .. 1 |-> 0],
      secondReserved8                 |-> [i \in 1 .. 8 |-> 0],
      thirdReserved8                  |-> [i \in 1 .. 8 |-> 0] ]

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
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.priceBandTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.dynamicCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.staticCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved11 = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.averageDailyTurnoverAdt = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }

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
(* Order Modify Message: 77 bytes                                          *)
(***************************************************************************)

OrderModifyMessage ==
    [ timestamp        : Sample(8),
      orderId          : Sample(8),
      instrument       : Sample(8),
      side             : Sample(1),
      orderModifyFlags : Sample(1),
      orderBookType    : Sample(1),
      newQuantity      : Sample(8),
      newPrice         : Sample(8),
      reserved8        : Sample(8),
      sourceVenue      : Sample(2),
      previousPrice    : Sample(8),
      previousQuantity : Sample(8),
      transactionTime  : Sample(8) ]

EncodeOrderModifyMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.instrument
        \o message.side
        \o message.orderModifyFlags
        \o message.orderBookType
        \o message.newQuantity
        \o message.newPrice
        \o message.reserved8
        \o message.sourceVenue
        \o message.previousPrice
        \o message.previousQuantity
        \o message.transactionTime

DecodeOrderModifyMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrument == ReadBytes(orderId.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET side == ReadBytes(instrument.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderModifyFlags == ReadBytes(side.rest, 1) IN IF ~orderModifyFlags.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(orderModifyFlags.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET newQuantity == ReadBytes(orderBookType.rest, 8) IN IF ~newQuantity.ok THEN Fail ELSE
    LET newPrice == ReadBytes(newQuantity.rest, 8) IN IF ~newPrice.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(newPrice.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(reserved8.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(sourceVenue.rest, 8) IN IF ~previousPrice.ok THEN Fail ELSE
    LET previousQuantity == ReadBytes(previousPrice.rest, 8) IN IF ~previousQuantity.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(previousQuantity.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         instrument       |-> instrument.value,
         side             |-> side.value,
         orderModifyFlags |-> orderModifyFlags.value,
         orderBookType    |-> orderBookType.value,
         newQuantity      |-> newQuantity.value,
         newPrice         |-> newPrice.value,
         reserved8        |-> reserved8.value,
         sourceVenue      |-> sourceVenue.value,
         previousPrice    |-> previousPrice.value,
         previousQuantity |-> previousQuantity.value,
         transactionTime  |-> transactionTime.value ], transactionTime.rest)

ZeroOrderModifyMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      instrument       |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      orderModifyFlags |-> [i \in 1 .. 1 |-> 0],
      orderBookType    |-> [i \in 1 .. 1 |-> 0],
      newQuantity      |-> [i \in 1 .. 8 |-> 0],
      newPrice         |-> [i \in 1 .. 8 |-> 0],
      reserved8        |-> [i \in 1 .. 8 |-> 0],
      sourceVenue      |-> [i \in 1 .. 2 |-> 0],
      previousPrice    |-> [i \in 1 .. 8 |-> 0],
      previousQuantity |-> [i \in 1 .. 8 |-> 0],
      transactionTime  |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyMessage ==
    { ZeroOrderModifyMessage }
        \cup { [ZeroOrderModifyMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderModifyFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.newQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.newPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.previousPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.previousQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Delete Message: 52 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ timestamp        : Sample(8),
      orderId          : Sample(8),
      instrument       : Sample(8),
      side             : Sample(1),
      orderBookType    : Sample(1),
      sourceVenue      : Sample(2),
      previousPrice    : Sample(8),
      previousQuantity : Sample(8),
      transactionTime  : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.instrument
        \o message.side
        \o message.orderBookType
        \o message.sourceVenue
        \o message.previousPrice
        \o message.previousQuantity
        \o message.transactionTime

DecodeOrderDeleteMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrument == ReadBytes(orderId.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET side == ReadBytes(instrument.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(side.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(orderBookType.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET previousPrice == ReadBytes(sourceVenue.rest, 8) IN IF ~previousPrice.ok THEN Fail ELSE
    LET previousQuantity == ReadBytes(previousPrice.rest, 8) IN IF ~previousQuantity.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(previousQuantity.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         instrument       |-> instrument.value,
         side             |-> side.value,
         orderBookType    |-> orderBookType.value,
         sourceVenue      |-> sourceVenue.value,
         previousPrice    |-> previousPrice.value,
         previousQuantity |-> previousQuantity.value,
         transactionTime  |-> transactionTime.value ], transactionTime.rest)

ZeroOrderDeleteMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      instrument       |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      orderBookType    |-> [i \in 1 .. 1 |-> 0],
      sourceVenue      |-> [i \in 1 .. 2 |-> 0],
      previousPrice    |-> [i \in 1 .. 8 |-> 0],
      previousQuantity |-> [i \in 1 .. 8 |-> 0],
      transactionTime  |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.previousPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.previousQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }

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
(* Trade Summary Message: 91 bytes                                         *)
(***************************************************************************)

TradeSummaryMessage ==
    [ timestamp                   : Sample(8),
      instrument                  : Sample(8),
      sourceVenue                 : Sample(2),
      transactionTime             : Sample(8),
      farPrice                    : Sample(8),
      totalExecutedQuantity       : Sample(8),
      totalHiddenExecutedQuantity : Sample(8),
      deletedOrderQuantity        : Sample(8),
      side                        : Sample(1),
      bestBidSize                 : Sample(8),
      bestBidPrice                : Sample(8),
      bestOfferSize               : Sample(8),
      bestOfferPrice              : Sample(8) ]

EncodeTradeSummaryMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.transactionTime
        \o message.farPrice
        \o message.totalExecutedQuantity
        \o message.totalHiddenExecutedQuantity
        \o message.deletedOrderQuantity
        \o message.side
        \o message.bestBidSize
        \o message.bestBidPrice
        \o message.bestOfferSize
        \o message.bestOfferPrice

DecodeTradeSummaryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET transactionTime == ReadBytes(sourceVenue.rest, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET farPrice == ReadBytes(transactionTime.rest, 8) IN IF ~farPrice.ok THEN Fail ELSE
    LET totalExecutedQuantity == ReadBytes(farPrice.rest, 8) IN IF ~totalExecutedQuantity.ok THEN Fail ELSE
    LET totalHiddenExecutedQuantity == ReadBytes(totalExecutedQuantity.rest, 8) IN IF ~totalHiddenExecutedQuantity.ok THEN Fail ELSE
    LET deletedOrderQuantity == ReadBytes(totalHiddenExecutedQuantity.rest, 8) IN IF ~deletedOrderQuantity.ok THEN Fail ELSE
    LET side == ReadBytes(deletedOrderQuantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(side.rest, 8) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(bestBidSize.rest, 8) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestOfferSize == ReadBytes(bestBidPrice.rest, 8) IN IF ~bestOfferSize.ok THEN Fail ELSE
    LET bestOfferPrice == ReadBytes(bestOfferSize.rest, 8) IN IF ~bestOfferPrice.ok THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         instrument                  |-> instrument.value,
         sourceVenue                 |-> sourceVenue.value,
         transactionTime             |-> transactionTime.value,
         farPrice                    |-> farPrice.value,
         totalExecutedQuantity       |-> totalExecutedQuantity.value,
         totalHiddenExecutedQuantity |-> totalHiddenExecutedQuantity.value,
         deletedOrderQuantity        |-> deletedOrderQuantity.value,
         side                        |-> side.value,
         bestBidSize                 |-> bestBidSize.value,
         bestBidPrice                |-> bestBidPrice.value,
         bestOfferSize               |-> bestOfferSize.value,
         bestOfferPrice              |-> bestOfferPrice.value ], bestOfferPrice.rest)

ZeroTradeSummaryMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      instrument                  |-> [i \in 1 .. 8 |-> 0],
      sourceVenue                 |-> [i \in 1 .. 2 |-> 0],
      transactionTime             |-> [i \in 1 .. 8 |-> 0],
      farPrice                    |-> [i \in 1 .. 8 |-> 0],
      totalExecutedQuantity       |-> [i \in 1 .. 8 |-> 0],
      totalHiddenExecutedQuantity |-> [i \in 1 .. 8 |-> 0],
      deletedOrderQuantity        |-> [i \in 1 .. 8 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      bestBidSize                 |-> [i \in 1 .. 8 |-> 0],
      bestBidPrice                |-> [i \in 1 .. 8 |-> 0],
      bestOfferSize               |-> [i \in 1 .. 8 |-> 0],
      bestOfferPrice              |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeSummaryMessage ==
    { ZeroTradeSummaryMessage }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.farPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.totalExecutedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.totalHiddenExecutedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.deletedOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.bestBidSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.bestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.bestOfferSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.bestOfferPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Analytics Message: 106 bytes                                            *)
(***************************************************************************)

AnalyticsMessage ==
    [ timestamp                    : Sample(8),
      instrument                   : Sample(8),
      sourceVenue                  : Sample(2),
      startTime                    : Sample(8),
      endTime                      : Sample(8),
      buyOrderCount                : Sample(4),
      sellOrderCount               : Sample(4),
      buyOrderSize                 : Sample(8),
      sellOrderSize                : Sample(8),
      buyOrderCancellations        : Sample(4),
      sellOrderCancellations       : Sample(4),
      buyLimitOrderCancellations   : Sample(4),
      buyMarketOrderCancellations  : Sample(4),
      sellLimitOrderCancellations  : Sample(4),
      sellMarketOrderCancellations : Sample(4),
      bidAskSpread                 : Sample(8),
      vwapBuy                      : Sample(8),
      vwapSell                     : Sample(8) ]

EncodeAnalyticsMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.startTime
        \o message.endTime
        \o message.buyOrderCount
        \o message.sellOrderCount
        \o message.buyOrderSize
        \o message.sellOrderSize
        \o message.buyOrderCancellations
        \o message.sellOrderCancellations
        \o message.buyLimitOrderCancellations
        \o message.buyMarketOrderCancellations
        \o message.sellLimitOrderCancellations
        \o message.sellMarketOrderCancellations
        \o message.bidAskSpread
        \o message.vwapBuy
        \o message.vwapSell

DecodeAnalyticsMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET startTime == ReadBytes(sourceVenue.rest, 8) IN IF ~startTime.ok THEN Fail ELSE
    LET endTime == ReadBytes(startTime.rest, 8) IN IF ~endTime.ok THEN Fail ELSE
    LET buyOrderCount == ReadBytes(endTime.rest, 4) IN IF ~buyOrderCount.ok THEN Fail ELSE
    LET sellOrderCount == ReadBytes(buyOrderCount.rest, 4) IN IF ~sellOrderCount.ok THEN Fail ELSE
    LET buyOrderSize == ReadBytes(sellOrderCount.rest, 8) IN IF ~buyOrderSize.ok THEN Fail ELSE
    LET sellOrderSize == ReadBytes(buyOrderSize.rest, 8) IN IF ~sellOrderSize.ok THEN Fail ELSE
    LET buyOrderCancellations == ReadBytes(sellOrderSize.rest, 4) IN IF ~buyOrderCancellations.ok THEN Fail ELSE
    LET sellOrderCancellations == ReadBytes(buyOrderCancellations.rest, 4) IN IF ~sellOrderCancellations.ok THEN Fail ELSE
    LET buyLimitOrderCancellations == ReadBytes(sellOrderCancellations.rest, 4) IN IF ~buyLimitOrderCancellations.ok THEN Fail ELSE
    LET buyMarketOrderCancellations == ReadBytes(buyLimitOrderCancellations.rest, 4) IN IF ~buyMarketOrderCancellations.ok THEN Fail ELSE
    LET sellLimitOrderCancellations == ReadBytes(buyMarketOrderCancellations.rest, 4) IN IF ~sellLimitOrderCancellations.ok THEN Fail ELSE
    LET sellMarketOrderCancellations == ReadBytes(sellLimitOrderCancellations.rest, 4) IN IF ~sellMarketOrderCancellations.ok THEN Fail ELSE
    LET bidAskSpread == ReadBytes(sellMarketOrderCancellations.rest, 8) IN IF ~bidAskSpread.ok THEN Fail ELSE
    LET vwapBuy == ReadBytes(bidAskSpread.rest, 8) IN IF ~vwapBuy.ok THEN Fail ELSE
    LET vwapSell == ReadBytes(vwapBuy.rest, 8) IN IF ~vwapSell.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         instrument                   |-> instrument.value,
         sourceVenue                  |-> sourceVenue.value,
         startTime                    |-> startTime.value,
         endTime                      |-> endTime.value,
         buyOrderCount                |-> buyOrderCount.value,
         sellOrderCount               |-> sellOrderCount.value,
         buyOrderSize                 |-> buyOrderSize.value,
         sellOrderSize                |-> sellOrderSize.value,
         buyOrderCancellations        |-> buyOrderCancellations.value,
         sellOrderCancellations       |-> sellOrderCancellations.value,
         buyLimitOrderCancellations   |-> buyLimitOrderCancellations.value,
         buyMarketOrderCancellations  |-> buyMarketOrderCancellations.value,
         sellLimitOrderCancellations  |-> sellLimitOrderCancellations.value,
         sellMarketOrderCancellations |-> sellMarketOrderCancellations.value,
         bidAskSpread                 |-> bidAskSpread.value,
         vwapBuy                      |-> vwapBuy.value,
         vwapSell                     |-> vwapSell.value ], vwapSell.rest)

ZeroAnalyticsMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      instrument                   |-> [i \in 1 .. 8 |-> 0],
      sourceVenue                  |-> [i \in 1 .. 2 |-> 0],
      startTime                    |-> [i \in 1 .. 8 |-> 0],
      endTime                      |-> [i \in 1 .. 8 |-> 0],
      buyOrderCount                |-> [i \in 1 .. 4 |-> 0],
      sellOrderCount               |-> [i \in 1 .. 4 |-> 0],
      buyOrderSize                 |-> [i \in 1 .. 8 |-> 0],
      sellOrderSize                |-> [i \in 1 .. 8 |-> 0],
      buyOrderCancellations        |-> [i \in 1 .. 4 |-> 0],
      sellOrderCancellations       |-> [i \in 1 .. 4 |-> 0],
      buyLimitOrderCancellations   |-> [i \in 1 .. 4 |-> 0],
      buyMarketOrderCancellations  |-> [i \in 1 .. 4 |-> 0],
      sellLimitOrderCancellations  |-> [i \in 1 .. 4 |-> 0],
      sellMarketOrderCancellations |-> [i \in 1 .. 4 |-> 0],
      bidAskSpread                 |-> [i \in 1 .. 8 |-> 0],
      vwapBuy                      |-> [i \in 1 .. 8 |-> 0],
      vwapSell                     |-> [i \in 1 .. 8 |-> 0] ]

(* Analytics Message at zero, then each field in turn at the values it is checked at *)
CheckedAnalyticsMessage ==
    { ZeroAnalyticsMessage }
        \cup { [ZeroAnalyticsMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.startTime = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.endTime = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyOrderSize = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellOrderSize = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyLimitOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyMarketOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellLimitOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellMarketOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.bidAskSpread = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.vwapBuy = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.vwapSell = one] : one \in Sample(8) }

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
AddOrderIncrementalMessageCode == 70  \* 0x46
OrderModifyMessageCode == 85  \* 0x55
OrderDeleteMessageCode == 68  \* 0x44
TopOfBookMessageCode == 105  \* 0x69
OrderBookClearMessageCode == 121  \* 0x79
TradeMessageCode == 80  \* 0x50
TradeCrossMessageCode == 113  \* 0x71
StatisticsMessageCode == 119  \* 0x77
StatisticsUpdateMessageCode == 106  \* 0x6a
MifidIiTradeMessageCode == 81  \* 0x51
MiFidIiTradeCrossMessageCode == 86  \* 0x56
TradeSummaryMessageCode == 87  \* 0x57
AnalyticsMessageCode == 97  \* 0x61

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayResponseMessageCode}, body : ReplayResponseMessage ]
        \cup [ tag : {ReplayAndRecoveryCompleteMessageCode}, body : ReplayAndRecoveryCompleteMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {InstrumentStatusMessageCode}, body : InstrumentStatusMessage ]
        \cup [ tag : {AddOrderIncrementalMessageCode}, body : AddOrderIncrementalMessage ]
        \cup [ tag : {OrderModifyMessageCode}, body : OrderModifyMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]
        \cup [ tag : {OrderBookClearMessageCode}, body : OrderBookClearMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeCrossMessageCode}, body : TradeCrossMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {StatisticsUpdateMessageCode}, body : StatisticsUpdateMessage ]
        \cup [ tag : {MifidIiTradeMessageCode}, body : MifidIiTradeMessage ]
        \cup [ tag : {MiFidIiTradeCrossMessageCode}, body : MiFidIiTradeCrossMessage ]
        \cup [ tag : {TradeSummaryMessageCode}, body : TradeSummaryMessage ]
        \cup [ tag : {AnalyticsMessageCode}, body : AnalyticsMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayResponseMessageCode -> EncodeReplayResponseMessage(message.body)
      [] message.tag = ReplayAndRecoveryCompleteMessageCode -> EncodeReplayAndRecoveryCompleteMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = InstrumentStatusMessageCode -> EncodeInstrumentStatusMessage(message.body)
      [] message.tag = AddOrderIncrementalMessageCode -> EncodeAddOrderIncrementalMessage(message.body)
      [] message.tag = OrderModifyMessageCode -> EncodeOrderModifyMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)
      [] message.tag = OrderBookClearMessageCode -> EncodeOrderBookClearMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeCrossMessageCode -> EncodeTradeCrossMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = StatisticsUpdateMessageCode -> EncodeStatisticsUpdateMessage(message.body)
      [] message.tag = MifidIiTradeMessageCode -> EncodeMifidIiTradeMessage(message.body)
      [] message.tag = MiFidIiTradeCrossMessageCode -> EncodeMiFidIiTradeCrossMessage(message.body)
      [] message.tag = TradeSummaryMessageCode -> EncodeTradeSummaryMessage(message.body)
      [] message.tag = AnalyticsMessageCode -> EncodeAnalyticsMessage(message.body)

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
              [] tag = AddOrderIncrementalMessageCode -> DecodeAddOrderIncrementalMessage(bytes)
              [] tag = OrderModifyMessageCode -> DecodeOrderModifyMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] tag = OrderBookClearMessageCode -> DecodeOrderBookClearMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeCrossMessageCode -> DecodeTradeCrossMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = StatisticsUpdateMessageCode -> DecodeStatisticsUpdateMessage(bytes)
              [] tag = MifidIiTradeMessageCode -> DecodeMifidIiTradeMessage(bytes)
              [] tag = MiFidIiTradeCrossMessageCode -> DecodeMiFidIiTradeCrossMessage(bytes)
              [] tag = TradeSummaryMessageCode -> DecodeTradeSummaryMessage(bytes)
              [] tag = AnalyticsMessageCode -> DecodeAnalyticsMessage(bytes)
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
        \cup { [tag |-> AddOrderIncrementalMessageCode, body |-> one] : one \in CheckedAddOrderIncrementalMessage }
        \cup { [tag |-> OrderModifyMessageCode, body |-> one] : one \in CheckedOrderModifyMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }
        \cup { [tag |-> OrderBookClearMessageCode, body |-> one] : one \in CheckedOrderBookClearMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeCrossMessageCode, body |-> one] : one \in CheckedTradeCrossMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> StatisticsUpdateMessageCode, body |-> one] : one \in CheckedStatisticsUpdateMessage }
        \cup { [tag |-> MifidIiTradeMessageCode, body |-> one] : one \in CheckedMifidIiTradeMessage }
        \cup { [tag |-> MiFidIiTradeCrossMessageCode, body |-> one] : one \in CheckedMiFidIiTradeCrossMessage }
        \cup { [tag |-> TradeSummaryMessageCode, body |-> one] : one \in CheckedTradeSummaryMessage }
        \cup { [tag |-> AnalyticsMessageCode, body |-> one] : one \in CheckedAnalyticsMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderIncrementalMessageCode, body |-> ZeroAddOrderIncrementalMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyMessageCode, body |-> ZeroOrderModifyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookClearMessageCode, body |-> ZeroOrderBookClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCrossMessageCode, body |-> ZeroTradeCrossMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsUpdateMessageCode, body |-> ZeroStatisticsUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MifidIiTradeMessageCode, body |-> ZeroMifidIiTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MiFidIiTradeCrossMessageCode, body |-> ZeroMiFidIiTradeCrossMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeSummaryMessageCode, body |-> ZeroTradeSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AnalyticsMessageCode, body |-> ZeroAnalyticsMessage]] }

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

(* Every Add Order Incremental Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderIncrementalMessage ==
    \A message \in CheckedAddOrderIncrementalMessage :
        LET read == DecodeAddOrderIncrementalMessage(EncodeAddOrderIncrementalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyMessage ==
    \A message \in CheckedOrderModifyMessage :
        LET read == DecodeOrderModifyMessage(EncodeOrderModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
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

(* Every Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSummaryMessage ==
    \A message \in CheckedTradeSummaryMessage :
        LET read == DecodeTradeSummaryMessage(EncodeTradeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Analytics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAnalyticsMessage ==
    \A message \in CheckedAnalyticsMessage :
        LET read == DecodeAnalyticsMessage(EncodeAnalyticsMessage(message))
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
