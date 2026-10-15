-------------- MODULE TradeEcho_Mifid2PostTradeRecovery_v24_4 --------------
(***************************************************************************)
(* London Stock Exchange MiFID II Post Trade Recovery v24.4                *)
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
      averageDailyTurnover            : Sample(8),
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
        \o message.averageDailyTurnover
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
    LET averageDailyTurnover == ReadBytes(reserved4.rest, 8) IN IF ~averageDailyTurnover.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(averageDailyTurnover.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
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
         averageDailyTurnover            |-> averageDailyTurnover.value,
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
      averageDailyTurnover            |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.averageDailyTurnover = one] : one \in Sample(8) }
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
(* Statistics Snapshot Message: 270 bytes                                  *)
(***************************************************************************)

StatisticsSnapshotMessage ==
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
      turnoverOnbookOnly       : Sample(8),
      officialOpeningPrice     : Sample(8),
      officialClosingPrice     : Sample(8),
      tradeHighOnbookOnly      : Sample(8),
      tradeLowOnbookOnly       : Sample(8),
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
      tradeHighOffBook         : Sample(8),
      tradeLowOffBook          : Sample(8),
      reserved8                : Sample(8),
      secondReserved8          : Sample(8),
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
        \o message.volumeOnbookOnly
        \o message.vwap
        \o message.vwapOnbookOnly
        \o message.numberOfTrades
        \o message.numberOfTradesOnbookOnly
        \o message.turnover
        \o message.turnoverOnbookOnly
        \o message.officialOpeningPrice
        \o message.officialClosingPrice
        \o message.tradeHighOnbookOnly
        \o message.tradeLowOnbookOnly
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
        \o message.tradeHighOffBook
        \o message.tradeLowOffBook
        \o message.reserved8
        \o message.secondReserved8
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
    LET volumeOnbookOnly == ReadBytes(volume.rest, 8) IN IF ~volumeOnbookOnly.ok THEN Fail ELSE
    LET vwap == ReadBytes(volumeOnbookOnly.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET vwapOnbookOnly == ReadBytes(vwap.rest, 8) IN IF ~vwapOnbookOnly.ok THEN Fail ELSE
    LET numberOfTrades == ReadBytes(vwapOnbookOnly.rest, 4) IN IF ~numberOfTrades.ok THEN Fail ELSE
    LET numberOfTradesOnbookOnly == ReadBytes(numberOfTrades.rest, 4) IN IF ~numberOfTradesOnbookOnly.ok THEN Fail ELSE
    LET turnover == ReadBytes(numberOfTradesOnbookOnly.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET turnoverOnbookOnly == ReadBytes(turnover.rest, 8) IN IF ~turnoverOnbookOnly.ok THEN Fail ELSE
    LET officialOpeningPrice == ReadBytes(turnoverOnbookOnly.rest, 8) IN IF ~officialOpeningPrice.ok THEN Fail ELSE
    LET officialClosingPrice == ReadBytes(officialOpeningPrice.rest, 8) IN IF ~officialClosingPrice.ok THEN Fail ELSE
    LET tradeHighOnbookOnly == ReadBytes(officialClosingPrice.rest, 8) IN IF ~tradeHighOnbookOnly.ok THEN Fail ELSE
    LET tradeLowOnbookOnly == ReadBytes(tradeHighOnbookOnly.rest, 8) IN IF ~tradeLowOnbookOnly.ok THEN Fail ELSE
    LET tradeHigh == ReadBytes(tradeLowOnbookOnly.rest, 8) IN IF ~tradeHigh.ok THEN Fail ELSE
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
    LET tradeHighOffBook == ReadBytes(bestClosingAskSize.rest, 8) IN IF ~tradeHighOffBook.ok THEN Fail ELSE
    LET tradeLowOffBook == ReadBytes(tradeHighOffBook.rest, 8) IN IF ~tradeLowOffBook.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(tradeLowOffBook.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(reserved8.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET auctionType == ReadBytes(secondReserved8.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(auctionType.rest, 8) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET lastTradeQuantity == ReadBytes(lastTradePrice.rest, 8) IN IF ~lastTradeQuantity.ok THEN Fail ELSE
    LET lastTradeTime == ReadBytes(lastTradeQuantity.rest, 8) IN IF ~lastTradeTime.ok THEN Fail ELSE
    LET staticReferencePrice == ReadBytes(lastTradeTime.rest, 8) IN IF ~staticReferencePrice.ok THEN Fail ELSE
    LET dynamicReferencePrice == ReadBytes(staticReferencePrice.rest, 8) IN IF ~dynamicReferencePrice.ok THEN Fail ELSE
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
         turnoverOnbookOnly       |-> turnoverOnbookOnly.value,
         officialOpeningPrice     |-> officialOpeningPrice.value,
         officialClosingPrice     |-> officialClosingPrice.value,
         tradeHighOnbookOnly      |-> tradeHighOnbookOnly.value,
         tradeLowOnbookOnly       |-> tradeLowOnbookOnly.value,
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
         tradeHighOffBook         |-> tradeHighOffBook.value,
         tradeLowOffBook          |-> tradeLowOffBook.value,
         reserved8                |-> reserved8.value,
         secondReserved8          |-> secondReserved8.value,
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
      volumeOnbookOnly         |-> [i \in 1 .. 8 |-> 0],
      vwap                     |-> [i \in 1 .. 8 |-> 0],
      vwapOnbookOnly           |-> [i \in 1 .. 8 |-> 0],
      numberOfTrades           |-> [i \in 1 .. 4 |-> 0],
      numberOfTradesOnbookOnly |-> [i \in 1 .. 4 |-> 0],
      turnover                 |-> [i \in 1 .. 8 |-> 0],
      turnoverOnbookOnly       |-> [i \in 1 .. 8 |-> 0],
      officialOpeningPrice     |-> [i \in 1 .. 8 |-> 0],
      officialClosingPrice     |-> [i \in 1 .. 8 |-> 0],
      tradeHighOnbookOnly      |-> [i \in 1 .. 8 |-> 0],
      tradeLowOnbookOnly       |-> [i \in 1 .. 8 |-> 0],
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
      tradeHighOffBook         |-> [i \in 1 .. 8 |-> 0],
      tradeLowOffBook          |-> [i \in 1 .. 8 |-> 0],
      reserved8                |-> [i \in 1 .. 8 |-> 0],
      secondReserved8          |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.volumeOnbookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.vwapOnbookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.numberOfTrades = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.numberOfTradesOnbookOnly = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.turnoverOnbookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.officialOpeningPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.officialClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.tradeHighOnbookOnly = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.tradeLowOnbookOnly = one] : one \in Sample(8) }
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
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.tradeHighOffBook = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.tradeLowOffBook = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.lastTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.lastTradeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.lastTradeTime = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.staticReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsSnapshotMessage EXCEPT !.dynamicReferencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Mifid Ii Trade Report Message: 433 bytes                                *)
(***************************************************************************)

MifidIiTradeReportMessage ==
    [ timestamp                           : Sample(8),
      instrument                          : Sample(8),
      transactionIdentificationCode       : Sample(52),
      totalNumberOfTransactions           : Sample(4),
      reserved8                           : Sample(8),
      sourceVenue                         : Sample(2),
      miFidPrice                          : Sample(20),
      miFidQuantity                       : Sample(20),
      miFidTradingDateAndTime             : Sample(27),
      instrumentIdentificationCodeType    : Sample(4),
      instrumentIdentificationCode        : Sample(12),
      priceNotation                       : Sample(4),
      priceCurrency                       : Sample(3),
      notionalAmount                      : Sample(20),
      notionalCurrency                    : Sample(3),
      venueOfExecution                    : Sample(4),
      publicationDateAndTime              : Sample(27),
      benchmarkTransactionFlag            : Sample(4),
      agencyCrossTradeFlag                : Sample(4),
      nonPriceFormingTransactionsFlag     : Sample(4),
      nonPriceContributionToDiscovery     : Sample(4),
      specialDividendFlag                 : Sample(4),
      ptDeferralReasonFlag                : Sample(4),
      referencePriceTransactionFlag       : Sample(4),
      ntLiquidityFlag                     : Sample(4),
      ntPriceConditionsFlag               : Sample(4),
      algoTransactionFlag                 : Sample(4),
      ptIlliquidFlag                      : Sample(4),
      priceImprovementFlag                : Sample(4),
      cancellationFlag                    : Sample(4),
      amendmentFlag                       : Sample(4),
      duplicateFlag                       : Sample(4),
      exchangeForPhysicalsFlag            : Sample(4),
      limitedDetailsFlag                  : Sample(4),
      ldFullDetailsFlag                   : Sample(4),
      dailyAggregatedTransactionFlag      : Sample(4),
      daFullDetailsFlag                   : Sample(4),
      volumeOmissionFlag                  : Sample(4),
      voFullDetailsFlag                   : Sample(4),
      fourWeeksAggregationFlag            : Sample(4),
      faFullDetailsFlag                   : Sample(4),
      indefiniteAggregationFlag           : Sample(4),
      volumeOmissionForSovereignDebtFlag  : Sample(4),
      consecutiveAggregationFlag          : Sample(4),
      reserved1                           : Sample(1),
      venueType                           : Sample(1),
      venueBookDefinitionId               : Sample(1),
      venueMeasurementUnitNotation        : Sample(25),
      quantityInMeasurementUnit           : Sample(20),
      transactionToBeCleared              : Sample(1),
      emissionAllowanceType               : Sample(4),
      venueOfPublication                  : Sample(4),
      marketMechanism                     : Sample(1),
      tradingMode                         : Sample(1),
      transactionCategory                 : Sample(1),
      negotiationIndicator                : Sample(1),
      agencyCrossIndicator                : Sample(1),
      modificationIndicator               : Sample(1),
      referencePriceIndicator             : Sample(1),
      specialDividendIndicator            : Sample(1),
      offBookAutomatedIndicator           : Sample(1),
      priceFormationIndicator             : Sample(1),
      algorithmicIndicator                : Sample(1),
      postTradeDeferralReason             : Sample(1),
      deferralEnrichmentType              : Sample(1),
      duplicativeIndicator                : Sample(1),
      thirdcountryTradingVenueOfExecution : Sample(4),
      portfolioTransactionFlag            : Sample(4),
      contingentTransactionFlag           : Sample(4),
      priceConditions                     : Sample(4),
      marketClosingPriceFlag              : Sample(4),
      ntLargeInScaleFlag                  : Sample(4),
      ntPreTradeTransparencyFlag          : Sample(4) ]

EncodeMifidIiTradeReportMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.transactionIdentificationCode
        \o message.totalNumberOfTransactions
        \o message.reserved8
        \o message.sourceVenue
        \o message.miFidPrice
        \o message.miFidQuantity
        \o message.miFidTradingDateAndTime
        \o message.instrumentIdentificationCodeType
        \o message.instrumentIdentificationCode
        \o message.priceNotation
        \o message.priceCurrency
        \o message.notionalAmount
        \o message.notionalCurrency
        \o message.venueOfExecution
        \o message.publicationDateAndTime
        \o message.benchmarkTransactionFlag
        \o message.agencyCrossTradeFlag
        \o message.nonPriceFormingTransactionsFlag
        \o message.nonPriceContributionToDiscovery
        \o message.specialDividendFlag
        \o message.ptDeferralReasonFlag
        \o message.referencePriceTransactionFlag
        \o message.ntLiquidityFlag
        \o message.ntPriceConditionsFlag
        \o message.algoTransactionFlag
        \o message.ptIlliquidFlag
        \o message.priceImprovementFlag
        \o message.cancellationFlag
        \o message.amendmentFlag
        \o message.duplicateFlag
        \o message.exchangeForPhysicalsFlag
        \o message.limitedDetailsFlag
        \o message.ldFullDetailsFlag
        \o message.dailyAggregatedTransactionFlag
        \o message.daFullDetailsFlag
        \o message.volumeOmissionFlag
        \o message.voFullDetailsFlag
        \o message.fourWeeksAggregationFlag
        \o message.faFullDetailsFlag
        \o message.indefiniteAggregationFlag
        \o message.volumeOmissionForSovereignDebtFlag
        \o message.consecutiveAggregationFlag
        \o message.reserved1
        \o message.venueType
        \o message.venueBookDefinitionId
        \o message.venueMeasurementUnitNotation
        \o message.quantityInMeasurementUnit
        \o message.transactionToBeCleared
        \o message.emissionAllowanceType
        \o message.venueOfPublication
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
        \o message.thirdcountryTradingVenueOfExecution
        \o message.portfolioTransactionFlag
        \o message.contingentTransactionFlag
        \o message.priceConditions
        \o message.marketClosingPriceFlag
        \o message.ntLargeInScaleFlag
        \o message.ntPreTradeTransparencyFlag

DecodeMifidIiTradeReportMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET transactionIdentificationCode == ReadBytes(instrument.rest, 52) IN IF ~transactionIdentificationCode.ok THEN Fail ELSE
    LET totalNumberOfTransactions == ReadBytes(transactionIdentificationCode.rest, 4) IN IF ~totalNumberOfTransactions.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(totalNumberOfTransactions.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(reserved8.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET miFidPrice == ReadBytes(sourceVenue.rest, 20) IN IF ~miFidPrice.ok THEN Fail ELSE
    LET miFidQuantity == ReadBytes(miFidPrice.rest, 20) IN IF ~miFidQuantity.ok THEN Fail ELSE
    LET miFidTradingDateAndTime == ReadBytes(miFidQuantity.rest, 27) IN IF ~miFidTradingDateAndTime.ok THEN Fail ELSE
    LET instrumentIdentificationCodeType == ReadBytes(miFidTradingDateAndTime.rest, 4) IN IF ~instrumentIdentificationCodeType.ok THEN Fail ELSE
    LET instrumentIdentificationCode == ReadBytes(instrumentIdentificationCodeType.rest, 12) IN IF ~instrumentIdentificationCode.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(instrumentIdentificationCode.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET priceCurrency == ReadBytes(priceNotation.rest, 3) IN IF ~priceCurrency.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(priceCurrency.rest, 20) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(notionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(notionalCurrency.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    LET publicationDateAndTime == ReadBytes(venueOfExecution.rest, 27) IN IF ~publicationDateAndTime.ok THEN Fail ELSE
    LET benchmarkTransactionFlag == ReadBytes(publicationDateAndTime.rest, 4) IN IF ~benchmarkTransactionFlag.ok THEN Fail ELSE
    LET agencyCrossTradeFlag == ReadBytes(benchmarkTransactionFlag.rest, 4) IN IF ~agencyCrossTradeFlag.ok THEN Fail ELSE
    LET nonPriceFormingTransactionsFlag == ReadBytes(agencyCrossTradeFlag.rest, 4) IN IF ~nonPriceFormingTransactionsFlag.ok THEN Fail ELSE
    LET nonPriceContributionToDiscovery == ReadBytes(nonPriceFormingTransactionsFlag.rest, 4) IN IF ~nonPriceContributionToDiscovery.ok THEN Fail ELSE
    LET specialDividendFlag == ReadBytes(nonPriceContributionToDiscovery.rest, 4) IN IF ~specialDividendFlag.ok THEN Fail ELSE
    LET ptDeferralReasonFlag == ReadBytes(specialDividendFlag.rest, 4) IN IF ~ptDeferralReasonFlag.ok THEN Fail ELSE
    LET referencePriceTransactionFlag == ReadBytes(ptDeferralReasonFlag.rest, 4) IN IF ~referencePriceTransactionFlag.ok THEN Fail ELSE
    LET ntLiquidityFlag == ReadBytes(referencePriceTransactionFlag.rest, 4) IN IF ~ntLiquidityFlag.ok THEN Fail ELSE
    LET ntPriceConditionsFlag == ReadBytes(ntLiquidityFlag.rest, 4) IN IF ~ntPriceConditionsFlag.ok THEN Fail ELSE
    LET algoTransactionFlag == ReadBytes(ntPriceConditionsFlag.rest, 4) IN IF ~algoTransactionFlag.ok THEN Fail ELSE
    LET ptIlliquidFlag == ReadBytes(algoTransactionFlag.rest, 4) IN IF ~ptIlliquidFlag.ok THEN Fail ELSE
    LET priceImprovementFlag == ReadBytes(ptIlliquidFlag.rest, 4) IN IF ~priceImprovementFlag.ok THEN Fail ELSE
    LET cancellationFlag == ReadBytes(priceImprovementFlag.rest, 4) IN IF ~cancellationFlag.ok THEN Fail ELSE
    LET amendmentFlag == ReadBytes(cancellationFlag.rest, 4) IN IF ~amendmentFlag.ok THEN Fail ELSE
    LET duplicateFlag == ReadBytes(amendmentFlag.rest, 4) IN IF ~duplicateFlag.ok THEN Fail ELSE
    LET exchangeForPhysicalsFlag == ReadBytes(duplicateFlag.rest, 4) IN IF ~exchangeForPhysicalsFlag.ok THEN Fail ELSE
    LET limitedDetailsFlag == ReadBytes(exchangeForPhysicalsFlag.rest, 4) IN IF ~limitedDetailsFlag.ok THEN Fail ELSE
    LET ldFullDetailsFlag == ReadBytes(limitedDetailsFlag.rest, 4) IN IF ~ldFullDetailsFlag.ok THEN Fail ELSE
    LET dailyAggregatedTransactionFlag == ReadBytes(ldFullDetailsFlag.rest, 4) IN IF ~dailyAggregatedTransactionFlag.ok THEN Fail ELSE
    LET daFullDetailsFlag == ReadBytes(dailyAggregatedTransactionFlag.rest, 4) IN IF ~daFullDetailsFlag.ok THEN Fail ELSE
    LET volumeOmissionFlag == ReadBytes(daFullDetailsFlag.rest, 4) IN IF ~volumeOmissionFlag.ok THEN Fail ELSE
    LET voFullDetailsFlag == ReadBytes(volumeOmissionFlag.rest, 4) IN IF ~voFullDetailsFlag.ok THEN Fail ELSE
    LET fourWeeksAggregationFlag == ReadBytes(voFullDetailsFlag.rest, 4) IN IF ~fourWeeksAggregationFlag.ok THEN Fail ELSE
    LET faFullDetailsFlag == ReadBytes(fourWeeksAggregationFlag.rest, 4) IN IF ~faFullDetailsFlag.ok THEN Fail ELSE
    LET indefiniteAggregationFlag == ReadBytes(faFullDetailsFlag.rest, 4) IN IF ~indefiniteAggregationFlag.ok THEN Fail ELSE
    LET volumeOmissionForSovereignDebtFlag == ReadBytes(indefiniteAggregationFlag.rest, 4) IN IF ~volumeOmissionForSovereignDebtFlag.ok THEN Fail ELSE
    LET consecutiveAggregationFlag == ReadBytes(volumeOmissionForSovereignDebtFlag.rest, 4) IN IF ~consecutiveAggregationFlag.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(consecutiveAggregationFlag.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET venueType == ReadBytes(reserved1.rest, 1) IN IF ~venueType.ok THEN Fail ELSE
    LET venueBookDefinitionId == ReadBytes(venueType.rest, 1) IN IF ~venueBookDefinitionId.ok THEN Fail ELSE
    LET venueMeasurementUnitNotation == ReadBytes(venueBookDefinitionId.rest, 25) IN IF ~venueMeasurementUnitNotation.ok THEN Fail ELSE
    LET quantityInMeasurementUnit == ReadBytes(venueMeasurementUnitNotation.rest, 20) IN IF ~quantityInMeasurementUnit.ok THEN Fail ELSE
    LET transactionToBeCleared == ReadBytes(quantityInMeasurementUnit.rest, 1) IN IF ~transactionToBeCleared.ok THEN Fail ELSE
    LET emissionAllowanceType == ReadBytes(transactionToBeCleared.rest, 4) IN IF ~emissionAllowanceType.ok THEN Fail ELSE
    LET venueOfPublication == ReadBytes(emissionAllowanceType.rest, 4) IN IF ~venueOfPublication.ok THEN Fail ELSE
    LET marketMechanism == ReadBytes(venueOfPublication.rest, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
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
    LET thirdcountryTradingVenueOfExecution == ReadBytes(duplicativeIndicator.rest, 4) IN IF ~thirdcountryTradingVenueOfExecution.ok THEN Fail ELSE
    LET portfolioTransactionFlag == ReadBytes(thirdcountryTradingVenueOfExecution.rest, 4) IN IF ~portfolioTransactionFlag.ok THEN Fail ELSE
    LET contingentTransactionFlag == ReadBytes(portfolioTransactionFlag.rest, 4) IN IF ~contingentTransactionFlag.ok THEN Fail ELSE
    LET priceConditions == ReadBytes(contingentTransactionFlag.rest, 4) IN IF ~priceConditions.ok THEN Fail ELSE
    LET marketClosingPriceFlag == ReadBytes(priceConditions.rest, 4) IN IF ~marketClosingPriceFlag.ok THEN Fail ELSE
    LET ntLargeInScaleFlag == ReadBytes(marketClosingPriceFlag.rest, 4) IN IF ~ntLargeInScaleFlag.ok THEN Fail ELSE
    LET ntPreTradeTransparencyFlag == ReadBytes(ntLargeInScaleFlag.rest, 4) IN IF ~ntPreTradeTransparencyFlag.ok THEN Fail ELSE
    Ok([ timestamp                           |-> timestamp.value,
         instrument                          |-> instrument.value,
         transactionIdentificationCode       |-> transactionIdentificationCode.value,
         totalNumberOfTransactions           |-> totalNumberOfTransactions.value,
         reserved8                           |-> reserved8.value,
         sourceVenue                         |-> sourceVenue.value,
         miFidPrice                          |-> miFidPrice.value,
         miFidQuantity                       |-> miFidQuantity.value,
         miFidTradingDateAndTime             |-> miFidTradingDateAndTime.value,
         instrumentIdentificationCodeType    |-> instrumentIdentificationCodeType.value,
         instrumentIdentificationCode        |-> instrumentIdentificationCode.value,
         priceNotation                       |-> priceNotation.value,
         priceCurrency                       |-> priceCurrency.value,
         notionalAmount                      |-> notionalAmount.value,
         notionalCurrency                    |-> notionalCurrency.value,
         venueOfExecution                    |-> venueOfExecution.value,
         publicationDateAndTime              |-> publicationDateAndTime.value,
         benchmarkTransactionFlag            |-> benchmarkTransactionFlag.value,
         agencyCrossTradeFlag                |-> agencyCrossTradeFlag.value,
         nonPriceFormingTransactionsFlag     |-> nonPriceFormingTransactionsFlag.value,
         nonPriceContributionToDiscovery     |-> nonPriceContributionToDiscovery.value,
         specialDividendFlag                 |-> specialDividendFlag.value,
         ptDeferralReasonFlag                |-> ptDeferralReasonFlag.value,
         referencePriceTransactionFlag       |-> referencePriceTransactionFlag.value,
         ntLiquidityFlag                     |-> ntLiquidityFlag.value,
         ntPriceConditionsFlag               |-> ntPriceConditionsFlag.value,
         algoTransactionFlag                 |-> algoTransactionFlag.value,
         ptIlliquidFlag                      |-> ptIlliquidFlag.value,
         priceImprovementFlag                |-> priceImprovementFlag.value,
         cancellationFlag                    |-> cancellationFlag.value,
         amendmentFlag                       |-> amendmentFlag.value,
         duplicateFlag                       |-> duplicateFlag.value,
         exchangeForPhysicalsFlag            |-> exchangeForPhysicalsFlag.value,
         limitedDetailsFlag                  |-> limitedDetailsFlag.value,
         ldFullDetailsFlag                   |-> ldFullDetailsFlag.value,
         dailyAggregatedTransactionFlag      |-> dailyAggregatedTransactionFlag.value,
         daFullDetailsFlag                   |-> daFullDetailsFlag.value,
         volumeOmissionFlag                  |-> volumeOmissionFlag.value,
         voFullDetailsFlag                   |-> voFullDetailsFlag.value,
         fourWeeksAggregationFlag            |-> fourWeeksAggregationFlag.value,
         faFullDetailsFlag                   |-> faFullDetailsFlag.value,
         indefiniteAggregationFlag           |-> indefiniteAggregationFlag.value,
         volumeOmissionForSovereignDebtFlag  |-> volumeOmissionForSovereignDebtFlag.value,
         consecutiveAggregationFlag          |-> consecutiveAggregationFlag.value,
         reserved1                           |-> reserved1.value,
         venueType                           |-> venueType.value,
         venueBookDefinitionId               |-> venueBookDefinitionId.value,
         venueMeasurementUnitNotation        |-> venueMeasurementUnitNotation.value,
         quantityInMeasurementUnit           |-> quantityInMeasurementUnit.value,
         transactionToBeCleared              |-> transactionToBeCleared.value,
         emissionAllowanceType               |-> emissionAllowanceType.value,
         venueOfPublication                  |-> venueOfPublication.value,
         marketMechanism                     |-> marketMechanism.value,
         tradingMode                         |-> tradingMode.value,
         transactionCategory                 |-> transactionCategory.value,
         negotiationIndicator                |-> negotiationIndicator.value,
         agencyCrossIndicator                |-> agencyCrossIndicator.value,
         modificationIndicator               |-> modificationIndicator.value,
         referencePriceIndicator             |-> referencePriceIndicator.value,
         specialDividendIndicator            |-> specialDividendIndicator.value,
         offBookAutomatedIndicator           |-> offBookAutomatedIndicator.value,
         priceFormationIndicator             |-> priceFormationIndicator.value,
         algorithmicIndicator                |-> algorithmicIndicator.value,
         postTradeDeferralReason             |-> postTradeDeferralReason.value,
         deferralEnrichmentType              |-> deferralEnrichmentType.value,
         duplicativeIndicator                |-> duplicativeIndicator.value,
         thirdcountryTradingVenueOfExecution |-> thirdcountryTradingVenueOfExecution.value,
         portfolioTransactionFlag            |-> portfolioTransactionFlag.value,
         contingentTransactionFlag           |-> contingentTransactionFlag.value,
         priceConditions                     |-> priceConditions.value,
         marketClosingPriceFlag              |-> marketClosingPriceFlag.value,
         ntLargeInScaleFlag                  |-> ntLargeInScaleFlag.value,
         ntPreTradeTransparencyFlag          |-> ntPreTradeTransparencyFlag.value ], ntPreTradeTransparencyFlag.rest)

ZeroMifidIiTradeReportMessage ==
    [ timestamp                           |-> [i \in 1 .. 8 |-> 0],
      instrument                          |-> [i \in 1 .. 8 |-> 0],
      transactionIdentificationCode       |-> [i \in 1 .. 52 |-> 0],
      totalNumberOfTransactions           |-> [i \in 1 .. 4 |-> 0],
      reserved8                           |-> [i \in 1 .. 8 |-> 0],
      sourceVenue                         |-> [i \in 1 .. 2 |-> 0],
      miFidPrice                          |-> [i \in 1 .. 20 |-> 0],
      miFidQuantity                       |-> [i \in 1 .. 20 |-> 0],
      miFidTradingDateAndTime             |-> [i \in 1 .. 27 |-> 0],
      instrumentIdentificationCodeType    |-> [i \in 1 .. 4 |-> 0],
      instrumentIdentificationCode        |-> [i \in 1 .. 12 |-> 0],
      priceNotation                       |-> [i \in 1 .. 4 |-> 0],
      priceCurrency                       |-> [i \in 1 .. 3 |-> 0],
      notionalAmount                      |-> [i \in 1 .. 20 |-> 0],
      notionalCurrency                    |-> [i \in 1 .. 3 |-> 0],
      venueOfExecution                    |-> [i \in 1 .. 4 |-> 0],
      publicationDateAndTime              |-> [i \in 1 .. 27 |-> 0],
      benchmarkTransactionFlag            |-> [i \in 1 .. 4 |-> 0],
      agencyCrossTradeFlag                |-> [i \in 1 .. 4 |-> 0],
      nonPriceFormingTransactionsFlag     |-> [i \in 1 .. 4 |-> 0],
      nonPriceContributionToDiscovery     |-> [i \in 1 .. 4 |-> 0],
      specialDividendFlag                 |-> [i \in 1 .. 4 |-> 0],
      ptDeferralReasonFlag                |-> [i \in 1 .. 4 |-> 0],
      referencePriceTransactionFlag       |-> [i \in 1 .. 4 |-> 0],
      ntLiquidityFlag                     |-> [i \in 1 .. 4 |-> 0],
      ntPriceConditionsFlag               |-> [i \in 1 .. 4 |-> 0],
      algoTransactionFlag                 |-> [i \in 1 .. 4 |-> 0],
      ptIlliquidFlag                      |-> [i \in 1 .. 4 |-> 0],
      priceImprovementFlag                |-> [i \in 1 .. 4 |-> 0],
      cancellationFlag                    |-> [i \in 1 .. 4 |-> 0],
      amendmentFlag                       |-> [i \in 1 .. 4 |-> 0],
      duplicateFlag                       |-> [i \in 1 .. 4 |-> 0],
      exchangeForPhysicalsFlag            |-> [i \in 1 .. 4 |-> 0],
      limitedDetailsFlag                  |-> [i \in 1 .. 4 |-> 0],
      ldFullDetailsFlag                   |-> [i \in 1 .. 4 |-> 0],
      dailyAggregatedTransactionFlag      |-> [i \in 1 .. 4 |-> 0],
      daFullDetailsFlag                   |-> [i \in 1 .. 4 |-> 0],
      volumeOmissionFlag                  |-> [i \in 1 .. 4 |-> 0],
      voFullDetailsFlag                   |-> [i \in 1 .. 4 |-> 0],
      fourWeeksAggregationFlag            |-> [i \in 1 .. 4 |-> 0],
      faFullDetailsFlag                   |-> [i \in 1 .. 4 |-> 0],
      indefiniteAggregationFlag           |-> [i \in 1 .. 4 |-> 0],
      volumeOmissionForSovereignDebtFlag  |-> [i \in 1 .. 4 |-> 0],
      consecutiveAggregationFlag          |-> [i \in 1 .. 4 |-> 0],
      reserved1                           |-> [i \in 1 .. 1 |-> 0],
      venueType                           |-> [i \in 1 .. 1 |-> 0],
      venueBookDefinitionId               |-> [i \in 1 .. 1 |-> 0],
      venueMeasurementUnitNotation        |-> [i \in 1 .. 25 |-> 0],
      quantityInMeasurementUnit           |-> [i \in 1 .. 20 |-> 0],
      transactionToBeCleared              |-> [i \in 1 .. 1 |-> 0],
      emissionAllowanceType               |-> [i \in 1 .. 4 |-> 0],
      venueOfPublication                  |-> [i \in 1 .. 4 |-> 0],
      marketMechanism                     |-> [i \in 1 .. 1 |-> 0],
      tradingMode                         |-> [i \in 1 .. 1 |-> 0],
      transactionCategory                 |-> [i \in 1 .. 1 |-> 0],
      negotiationIndicator                |-> [i \in 1 .. 1 |-> 0],
      agencyCrossIndicator                |-> [i \in 1 .. 1 |-> 0],
      modificationIndicator               |-> [i \in 1 .. 1 |-> 0],
      referencePriceIndicator             |-> [i \in 1 .. 1 |-> 0],
      specialDividendIndicator            |-> [i \in 1 .. 1 |-> 0],
      offBookAutomatedIndicator           |-> [i \in 1 .. 1 |-> 0],
      priceFormationIndicator             |-> [i \in 1 .. 1 |-> 0],
      algorithmicIndicator                |-> [i \in 1 .. 1 |-> 0],
      postTradeDeferralReason             |-> [i \in 1 .. 1 |-> 0],
      deferralEnrichmentType              |-> [i \in 1 .. 1 |-> 0],
      duplicativeIndicator                |-> [i \in 1 .. 1 |-> 0],
      thirdcountryTradingVenueOfExecution |-> [i \in 1 .. 4 |-> 0],
      portfolioTransactionFlag            |-> [i \in 1 .. 4 |-> 0],
      contingentTransactionFlag           |-> [i \in 1 .. 4 |-> 0],
      priceConditions                     |-> [i \in 1 .. 4 |-> 0],
      marketClosingPriceFlag              |-> [i \in 1 .. 4 |-> 0],
      ntLargeInScaleFlag                  |-> [i \in 1 .. 4 |-> 0],
      ntPreTradeTransparencyFlag          |-> [i \in 1 .. 4 |-> 0] ]

(* Mifid Ii Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedMifidIiTradeReportMessage ==
    { ZeroMifidIiTradeReportMessage }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.transactionIdentificationCode = one] : one \in Sample(52) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.totalNumberOfTransactions = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.miFidPrice = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.miFidQuantity = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.miFidTradingDateAndTime = one] : one \in Sample(27) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.instrumentIdentificationCodeType = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.instrumentIdentificationCode = one] : one \in Sample(12) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.priceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.notionalAmount = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.publicationDateAndTime = one] : one \in Sample(27) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.benchmarkTransactionFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.agencyCrossTradeFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.nonPriceFormingTransactionsFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.nonPriceContributionToDiscovery = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.specialDividendFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.ptDeferralReasonFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.referencePriceTransactionFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.ntLiquidityFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.ntPriceConditionsFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.algoTransactionFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.ptIlliquidFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.priceImprovementFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.cancellationFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.amendmentFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.duplicateFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.exchangeForPhysicalsFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.limitedDetailsFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.ldFullDetailsFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.dailyAggregatedTransactionFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.daFullDetailsFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.volumeOmissionFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.voFullDetailsFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.fourWeeksAggregationFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.faFullDetailsFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.indefiniteAggregationFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.volumeOmissionForSovereignDebtFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.consecutiveAggregationFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.venueType = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.venueBookDefinitionId = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.venueMeasurementUnitNotation = one] : one \in Sample(25) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.quantityInMeasurementUnit = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.transactionToBeCleared = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.emissionAllowanceType = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.venueOfPublication = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.negotiationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.agencyCrossIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.modificationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.referencePriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.specialDividendIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.offBookAutomatedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.priceFormationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.algorithmicIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.postTradeDeferralReason = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.deferralEnrichmentType = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.duplicativeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.thirdcountryTradingVenueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.portfolioTransactionFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.contingentTransactionFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.priceConditions = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.marketClosingPriceFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.ntLargeInScaleFlag = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiTradeReportMessage EXCEPT !.ntPreTradeTransparencyFlag = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
RecoveryRequestMessageCode == 129  \* 0x81
LoginResponseMessageCode == 2  \* 0x02
RecoveryResponseMessageCode == 130  \* 0x82
ReplayAndRecoveryCompleteMessageCode == 131  \* 0x83
SystemEventMessageCode == 83  \* 0x53
InstrumentDirectoryMessageCode == 112  \* 0x70
InstrumentStatusMessageCode == 72  \* 0x48
StatisticsSnapshotMessageCode == 107  \* 0x6b
MifidIiTradeReportMessageCode == 84  \* 0x54

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {RecoveryRequestMessageCode}, body : RecoveryRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {RecoveryResponseMessageCode}, body : RecoveryResponseMessage ]
        \cup [ tag : {ReplayAndRecoveryCompleteMessageCode}, body : ReplayAndRecoveryCompleteMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {InstrumentStatusMessageCode}, body : InstrumentStatusMessage ]
        \cup [ tag : {StatisticsSnapshotMessageCode}, body : StatisticsSnapshotMessage ]
        \cup [ tag : {MifidIiTradeReportMessageCode}, body : MifidIiTradeReportMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = RecoveryRequestMessageCode -> EncodeRecoveryRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = RecoveryResponseMessageCode -> EncodeRecoveryResponseMessage(message.body)
      [] message.tag = ReplayAndRecoveryCompleteMessageCode -> EncodeReplayAndRecoveryCompleteMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = InstrumentStatusMessageCode -> EncodeInstrumentStatusMessage(message.body)
      [] message.tag = StatisticsSnapshotMessageCode -> EncodeStatisticsSnapshotMessage(message.body)
      [] message.tag = MifidIiTradeReportMessageCode -> EncodeMifidIiTradeReportMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = RecoveryRequestMessageCode -> DecodeRecoveryRequestMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = RecoveryResponseMessageCode -> DecodeRecoveryResponseMessage(bytes)
              [] tag = ReplayAndRecoveryCompleteMessageCode -> DecodeReplayAndRecoveryCompleteMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = InstrumentStatusMessageCode -> DecodeInstrumentStatusMessage(bytes)
              [] tag = StatisticsSnapshotMessageCode -> DecodeStatisticsSnapshotMessage(bytes)
              [] tag = MifidIiTradeReportMessageCode -> DecodeMifidIiTradeReportMessage(bytes)
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
        \cup { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> InstrumentStatusMessageCode, body |-> one] : one \in CheckedInstrumentStatusMessage }
        \cup { [tag |-> StatisticsSnapshotMessageCode, body |-> one] : one \in CheckedStatisticsSnapshotMessage }
        \cup { [tag |-> MifidIiTradeReportMessageCode, body |-> one] : one \in CheckedMifidIiTradeReportMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStatusMessageCode, body |-> ZeroInstrumentStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsSnapshotMessageCode, body |-> ZeroStatisticsSnapshotMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MifidIiTradeReportMessageCode, body |-> ZeroMifidIiTradeReportMessage]] }

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

(* Every Statistics Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsSnapshotMessage ==
    \A message \in CheckedStatisticsSnapshotMessage :
        LET read == DecodeStatisticsSnapshotMessage(EncodeStatisticsSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Ii Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidIiTradeReportMessage ==
    \A message \in CheckedMifidIiTradeReportMessage :
        LET read == DecodeMifidIiTradeReportMessage(EncodeMifidIiTradeReportMessage(message))
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
