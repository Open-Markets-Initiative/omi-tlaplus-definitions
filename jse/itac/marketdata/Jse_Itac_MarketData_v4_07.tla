--------------------- MODULE Jse_Itac_MarketData_v4_07 ---------------------
(***************************************************************************)
(* JSE Limited Market Data v4.07                                           *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: Leg 1 Symbol and what follows it are read only when the message   *)
(* runs on past what precedes them.                                        *)
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
(* Login Request Message: 16 bytes                                         *)
(***************************************************************************)

LoginRequestMessage ==
    [ username : Sample(6),
      password : Sample(10) ]

EncodeLoginRequestMessage(message) ==
    message.username
        \o message.password

DecodeLoginRequestMessage(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    Ok([ username |-> username.value,
         password |-> password.value ], password.rest)

ZeroLoginRequestMessage ==
    [ username |-> [i \in 1 .. 6 |-> 0],
      password |-> [i \in 1 .. 10 |-> 0] ]

(* Login Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestMessage ==
    { ZeroLoginRequestMessage }
        \cup { [ZeroLoginRequestMessage EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestMessage EXCEPT !.password = one] : one \in Sample(10) }

(***************************************************************************)
(* Replay Request Message: 7 bytes                                         *)
(***************************************************************************)

ReplayRequestMessage ==
    [ marketDataGroup : Sample(1),
      firstMessage    : Sample(4),
      count           : Sample(2) ]

EncodeReplayRequestMessage(message) ==
    message.marketDataGroup
        \o message.firstMessage
        \o message.count

DecodeReplayRequestMessage(bytes) ==
    LET marketDataGroup == ReadBytes(bytes, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET firstMessage == ReadBytes(marketDataGroup.rest, 4) IN IF ~firstMessage.ok THEN Fail ELSE
    LET count == ReadBytes(firstMessage.rest, 2) IN IF ~count.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         firstMessage    |-> firstMessage.value,
         count           |-> count.value ], count.rest)

ZeroReplayRequestMessage ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      firstMessage    |-> [i \in 1 .. 4 |-> 0],
      count           |-> [i \in 1 .. 2 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.firstMessage = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.count = one] : one \in Sample(2) }

(***************************************************************************)
(* Snapshot Request Message: 30 bytes                                      *)
(***************************************************************************)

SnapshotRequestMessage ==
    [ sequenceNumber  : Sample(4),
      segment         : Sample(6),
      instrumentId    : Sample(4),
      reservedA       : Sample(1),
      reservedB       : Sample(1),
      subBookFlags    : Sample(1),
      snapshotType    : Sample(1),
      recoverFromTime : Sample(8),
      requestId       : Sample(4) ]

EncodeSnapshotRequestMessage(message) ==
    message.sequenceNumber
        \o message.segment
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.subBookFlags
        \o message.snapshotType
        \o message.recoverFromTime
        \o message.requestId

DecodeSnapshotRequestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET segment == ReadBytes(sequenceNumber.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(segment.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET subBookFlags == ReadBytes(reservedB.rest, 1) IN IF ~subBookFlags.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(subBookFlags.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    LET recoverFromTime == ReadBytes(snapshotType.rest, 8) IN IF ~recoverFromTime.ok THEN Fail ELSE
    LET requestId == ReadBytes(recoverFromTime.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ sequenceNumber  |-> sequenceNumber.value,
         segment         |-> segment.value,
         instrumentId    |-> instrumentId.value,
         reservedA       |-> reservedA.value,
         reservedB       |-> reservedB.value,
         subBookFlags    |-> subBookFlags.value,
         snapshotType    |-> snapshotType.value,
         recoverFromTime |-> recoverFromTime.value,
         requestId       |-> requestId.value ], requestId.rest)

ZeroSnapshotRequestMessage ==
    [ sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      segment         |-> [i \in 1 .. 6 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      reservedA       |-> [i \in 1 .. 1 |-> 0],
      reservedB       |-> [i \in 1 .. 1 |-> 0],
      subBookFlags    |-> [i \in 1 .. 1 |-> 0],
      snapshotType    |-> [i \in 1 .. 1 |-> 0],
      recoverFromTime |-> [i \in 1 .. 8 |-> 0],
      requestId       |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRequestMessage ==
    { ZeroSnapshotRequestMessage }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.subBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.recoverFromTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }

(***************************************************************************)
(* Login Response Message: 1 bytes                                         *)
(***************************************************************************)

LoginResponseMessage ==
    [ status : Sample(1) ]

EncodeLoginResponseMessage(message) ==
    message.status

DecodeLoginResponseMessage(bytes) ==
    LET status == ReadBytes(bytes, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ status |-> status.value ], status.rest)

ZeroLoginResponseMessage ==
    [ status |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Replay Response Message: 8 bytes                                        *)
(***************************************************************************)

ReplayResponseMessage ==
    [ marketDataGroup : Sample(1),
      firstMessage    : Sample(4),
      count           : Sample(2),
      status          : Sample(1) ]

EncodeReplayResponseMessage(message) ==
    message.marketDataGroup
        \o message.firstMessage
        \o message.count
        \o message.status

DecodeReplayResponseMessage(bytes) ==
    LET marketDataGroup == ReadBytes(bytes, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET firstMessage == ReadBytes(marketDataGroup.rest, 4) IN IF ~firstMessage.ok THEN Fail ELSE
    LET count == ReadBytes(firstMessage.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET status == ReadBytes(count.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ marketDataGroup |-> marketDataGroup.value,
         firstMessage    |-> firstMessage.value,
         count           |-> count.value,
         status          |-> status.value ], status.rest)

ZeroReplayResponseMessage ==
    [ marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      firstMessage    |-> [i \in 1 .. 4 |-> 0],
      count           |-> [i \in 1 .. 2 |-> 0],
      status          |-> [i \in 1 .. 1 |-> 0] ]

(* Replay Response Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayResponseMessage ==
    { ZeroReplayResponseMessage }
        \cup { [ZeroReplayResponseMessage EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.firstMessage = one] : one \in Sample(4) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.count = one] : one \in Sample(2) }
        \cup { [ZeroReplayResponseMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Response Message: 14 bytes                                     *)
(***************************************************************************)

SnapshotResponseMessage ==
    [ sequenceNumber : Sample(4),
      orderCount     : Sample(4),
      status         : Sample(1),
      snapshotType   : Sample(1),
      requestId      : Sample(4) ]

EncodeSnapshotResponseMessage(message) ==
    message.sequenceNumber
        \o message.orderCount
        \o message.status
        \o message.snapshotType
        \o message.requestId

DecodeSnapshotResponseMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET orderCount == ReadBytes(sequenceNumber.rest, 4) IN IF ~orderCount.ok THEN Fail ELSE
    LET status == ReadBytes(orderCount.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(status.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    LET requestId == ReadBytes(snapshotType.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         orderCount     |-> orderCount.value,
         status         |-> status.value,
         snapshotType   |-> snapshotType.value,
         requestId      |-> requestId.value ], requestId.rest)

ZeroSnapshotResponseMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      orderCount     |-> [i \in 1 .. 4 |-> 0],
      status         |-> [i \in 1 .. 1 |-> 0],
      snapshotType   |-> [i \in 1 .. 1 |-> 0],
      requestId      |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotResponseMessage ==
    { ZeroSnapshotResponseMessage }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.orderCount = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.requestId = one] : one \in Sample(4) }

(***************************************************************************)
(* Snapshot Complete Message: 18 bytes                                     *)
(***************************************************************************)

SnapshotCompleteMessage ==
    [ sequenceNumber : Sample(4),
      segment        : Sample(6),
      instrumentId   : Sample(4),
      reservedA      : Sample(1),
      reservedB      : Sample(1),
      subBookFlags   : Sample(1),
      tradingStatus  : Sample(1) ]

EncodeSnapshotCompleteMessage(message) ==
    message.sequenceNumber
        \o message.segment
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.subBookFlags
        \o message.tradingStatus

DecodeSnapshotCompleteMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET segment == ReadBytes(sequenceNumber.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(segment.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET subBookFlags == ReadBytes(reservedB.rest, 1) IN IF ~subBookFlags.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(subBookFlags.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         segment        |-> segment.value,
         instrumentId   |-> instrumentId.value,
         reservedA      |-> reservedA.value,
         reservedB      |-> reservedB.value,
         subBookFlags   |-> subBookFlags.value,
         tradingStatus  |-> tradingStatus.value ], tradingStatus.rest)

ZeroSnapshotCompleteMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      segment        |-> [i \in 1 .. 6 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      reservedA      |-> [i \in 1 .. 1 |-> 0],
      reservedB      |-> [i \in 1 .. 1 |-> 0],
      subBookFlags   |-> [i \in 1 .. 1 |-> 0],
      tradingStatus  |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotCompleteMessage ==
    { ZeroSnapshotCompleteMessage }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.subBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Time Message: 4 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ seconds : Sample(4) ]

EncodeTimeMessage(message) ==
    message.seconds

DecodeTimeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroTimeMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 5 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanosecond : Sample(4),
      eventCode  : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.nanosecond
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanosecond.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ nanosecond |-> nanosecond.value,
         eventCode  |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ nanosecond |-> [i \in 1 .. 4 |-> 0],
      eventCode  |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Directory Message: 90 bytes                                      *)
(***************************************************************************)

SymbolDirectoryMessageTail ==
    [ leg1Symbol            : Sample(25),
      leg2Symbol            : Sample(25),
      contractMultiplier    : Sample(8),
      settlementMethod      : Sample(1),
      instrumentSubCategory : Sample(30),
      exerciseStyle         : Sample(1) ]

EncodeSymbolDirectoryMessageTail(message) ==
    message.leg1Symbol
        \o message.leg2Symbol
        \o message.contractMultiplier
        \o message.settlementMethod
        \o message.instrumentSubCategory
        \o message.exerciseStyle

DecodeSymbolDirectoryMessageTail(bytes) ==
    LET leg1Symbol == ReadBytes(bytes, 25) IN IF ~leg1Symbol.ok THEN Fail ELSE
    LET leg2Symbol == ReadBytes(leg1Symbol.rest, 25) IN IF ~leg2Symbol.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(leg2Symbol.rest, 8) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET settlementMethod == ReadBytes(contractMultiplier.rest, 1) IN IF ~settlementMethod.ok THEN Fail ELSE
    LET instrumentSubCategory == ReadBytes(settlementMethod.rest, 30) IN IF ~instrumentSubCategory.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(instrumentSubCategory.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    Ok([ leg1Symbol            |-> leg1Symbol.value,
         leg2Symbol            |-> leg2Symbol.value,
         contractMultiplier    |-> contractMultiplier.value,
         settlementMethod      |-> settlementMethod.value,
         instrumentSubCategory |-> instrumentSubCategory.value,
         exerciseStyle         |-> exerciseStyle.value ], exerciseStyle.rest)

ZeroSymbolDirectoryMessageTail ==
    [ leg1Symbol            |-> [i \in 1 .. 25 |-> 0],
      leg2Symbol            |-> [i \in 1 .. 25 |-> 0],
      contractMultiplier    |-> [i \in 1 .. 8 |-> 0],
      settlementMethod      |-> [i \in 1 .. 1 |-> 0],
      instrumentSubCategory |-> [i \in 1 .. 30 |-> 0],
      exerciseStyle         |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolDirectoryMessageTail ==
    { ZeroSymbolDirectoryMessageTail }
        \cup { [ZeroSymbolDirectoryMessageTail EXCEPT !.leg1Symbol = one] : one \in Sample(25) }
        \cup { [ZeroSymbolDirectoryMessageTail EXCEPT !.leg2Symbol = one] : one \in Sample(25) }
        \cup { [ZeroSymbolDirectoryMessageTail EXCEPT !.contractMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessageTail EXCEPT !.settlementMethod = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessageTail EXCEPT !.instrumentSubCategory = one] : one \in Sample(30) }
        \cup { [ZeroSymbolDirectoryMessageTail EXCEPT !.exerciseStyle = one] : one \in Sample(1) }

(* Symbol Directory Message runs on only when bytes remain, so it is there or it is not *)
WithoutSymbolDirectoryMessageTail == [there |-> FALSE, value |-> ZeroSymbolDirectoryMessageTail]

MaybeSymbolDirectoryMessageTail ==
    { WithoutSymbolDirectoryMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedSymbolDirectoryMessageTail }

ReadSymbolDirectoryMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutSymbolDirectoryMessageTail, << >>)
    ELSE LET one == DecodeSymbolDirectoryMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Symbol Directory Message                                                *)
(***************************************************************************)

SymbolDirectoryMessage ==
    [ nanosecond                 : Sample(4),
      instrumentId               : Sample(4),
      reservedA                  : Sample(1),
      reservedB                  : Sample(1),
      symbolStatus               : Sample(1),
      isin                       : Sample(12),
      symbol                     : Sample(25),
      tidm                       : Sample(12),
      segment                    : Sample(6),
      previousClosePrice         : Sample(8),
      expirationDate             : Sample(8),
      underlying                 : Sample(25),
      strikePrice                : Sample(8),
      optionType                 : Sample(1),
      issuer                     : Sample(6),
      issueDate                  : Sample(8),
      coupon                     : Sample(8),
      symbolDirectoryFlags       : Sample(1),
      subBookFlags               : Sample(1),
      corporateAction            : Sample(189),
      symbolDirectoryMessageTail : MaybeSymbolDirectoryMessageTail ]

EncodeSymbolDirectoryMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.symbolStatus
        \o message.isin
        \o message.symbol
        \o message.tidm
        \o message.segment
        \o message.previousClosePrice
        \o message.expirationDate
        \o message.underlying
        \o message.strikePrice
        \o message.optionType
        \o message.issuer
        \o message.issueDate
        \o message.coupon
        \o message.symbolDirectoryFlags
        \o message.subBookFlags
        \o message.corporateAction
        \o IF message.symbolDirectoryMessageTail.there THEN EncodeSymbolDirectoryMessageTail(message.symbolDirectoryMessageTail.value) ELSE << >>

DecodeSymbolDirectoryMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET symbolStatus == ReadBytes(reservedB.rest, 1) IN IF ~symbolStatus.ok THEN Fail ELSE
    LET isin == ReadBytes(symbolStatus.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET symbol == ReadBytes(isin.rest, 25) IN IF ~symbol.ok THEN Fail ELSE
    LET tidm == ReadBytes(symbol.rest, 12) IN IF ~tidm.ok THEN Fail ELSE
    LET segment == ReadBytes(tidm.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET previousClosePrice == ReadBytes(segment.rest, 8) IN IF ~previousClosePrice.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(previousClosePrice.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET underlying == ReadBytes(expirationDate.rest, 25) IN IF ~underlying.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(underlying.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET issuer == ReadBytes(optionType.rest, 6) IN IF ~issuer.ok THEN Fail ELSE
    LET issueDate == ReadBytes(issuer.rest, 8) IN IF ~issueDate.ok THEN Fail ELSE
    LET coupon == ReadBytes(issueDate.rest, 8) IN IF ~coupon.ok THEN Fail ELSE
    LET symbolDirectoryFlags == ReadBytes(coupon.rest, 1) IN IF ~symbolDirectoryFlags.ok THEN Fail ELSE
    LET subBookFlags == ReadBytes(symbolDirectoryFlags.rest, 1) IN IF ~subBookFlags.ok THEN Fail ELSE
    LET corporateAction == ReadBytes(subBookFlags.rest, 189) IN IF ~corporateAction.ok THEN Fail ELSE
    LET symbolDirectoryMessageTail == ReadSymbolDirectoryMessageTailMaybe(corporateAction.rest) IN IF ~symbolDirectoryMessageTail.ok THEN Fail ELSE
    Ok([ nanosecond                 |-> nanosecond.value,
         instrumentId               |-> instrumentId.value,
         reservedA                  |-> reservedA.value,
         reservedB                  |-> reservedB.value,
         symbolStatus               |-> symbolStatus.value,
         isin                       |-> isin.value,
         symbol                     |-> symbol.value,
         tidm                       |-> tidm.value,
         segment                    |-> segment.value,
         previousClosePrice         |-> previousClosePrice.value,
         expirationDate             |-> expirationDate.value,
         underlying                 |-> underlying.value,
         strikePrice                |-> strikePrice.value,
         optionType                 |-> optionType.value,
         issuer                     |-> issuer.value,
         issueDate                  |-> issueDate.value,
         coupon                     |-> coupon.value,
         symbolDirectoryFlags       |-> symbolDirectoryFlags.value,
         subBookFlags               |-> subBookFlags.value,
         corporateAction            |-> corporateAction.value,
         symbolDirectoryMessageTail |-> symbolDirectoryMessageTail.value ], symbolDirectoryMessageTail.rest)

ZeroSymbolDirectoryMessage ==
    [ nanosecond                 |-> [i \in 1 .. 4 |-> 0],
      instrumentId               |-> [i \in 1 .. 4 |-> 0],
      reservedA                  |-> [i \in 1 .. 1 |-> 0],
      reservedB                  |-> [i \in 1 .. 1 |-> 0],
      symbolStatus               |-> [i \in 1 .. 1 |-> 0],
      isin                       |-> [i \in 1 .. 12 |-> 0],
      symbol                     |-> [i \in 1 .. 25 |-> 0],
      tidm                       |-> [i \in 1 .. 12 |-> 0],
      segment                    |-> [i \in 1 .. 6 |-> 0],
      previousClosePrice         |-> [i \in 1 .. 8 |-> 0],
      expirationDate             |-> [i \in 1 .. 8 |-> 0],
      underlying                 |-> [i \in 1 .. 25 |-> 0],
      strikePrice                |-> [i \in 1 .. 8 |-> 0],
      optionType                 |-> [i \in 1 .. 1 |-> 0],
      issuer                     |-> [i \in 1 .. 6 |-> 0],
      issueDate                  |-> [i \in 1 .. 8 |-> 0],
      coupon                     |-> [i \in 1 .. 8 |-> 0],
      symbolDirectoryFlags       |-> [i \in 1 .. 1 |-> 0],
      subBookFlags               |-> [i \in 1 .. 1 |-> 0],
      corporateAction            |-> [i \in 1 .. 189 |-> 0],
      symbolDirectoryMessageTail |-> WithoutSymbolDirectoryMessageTail ]

(* Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolDirectoryMessage ==
    { ZeroSymbolDirectoryMessage }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbolStatus = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(25) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.tidm = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.previousClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.underlying = one] : one \in Sample(25) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.issuer = one] : one \in Sample(6) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.issueDate = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.coupon = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbolDirectoryFlags = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.subBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.corporateAction = one] : one \in Sample(189) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbolDirectoryMessageTail = one] : one \in MaybeSymbolDirectoryMessageTail }

(***************************************************************************)
(* Symbol Status Message: 30 bytes                                         *)
(***************************************************************************)

SymbolStatusMessage ==
    [ nanosecond          : Sample(4),
      instrumentId        : Sample(4),
      reservedA           : Sample(1),
      reservedB           : Sample(1),
      tradingStatus       : Sample(1),
      symbolStatusFlags   : Sample(1),
      reason              : Sample(4),
      sessionChangeReason : Sample(1),
      newEndTime          : Sample(12),
      bookType            : Sample(1) ]

EncodeSymbolStatusMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.tradingStatus
        \o message.symbolStatusFlags
        \o message.reason
        \o message.sessionChangeReason
        \o message.newEndTime
        \o message.bookType

DecodeSymbolStatusMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(reservedB.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET symbolStatusFlags == ReadBytes(tradingStatus.rest, 1) IN IF ~symbolStatusFlags.ok THEN Fail ELSE
    LET reason == ReadBytes(symbolStatusFlags.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    LET sessionChangeReason == ReadBytes(reason.rest, 1) IN IF ~sessionChangeReason.ok THEN Fail ELSE
    LET newEndTime == ReadBytes(sessionChangeReason.rest, 12) IN IF ~newEndTime.ok THEN Fail ELSE
    LET bookType == ReadBytes(newEndTime.rest, 1) IN IF ~bookType.ok THEN Fail ELSE
    Ok([ nanosecond          |-> nanosecond.value,
         instrumentId        |-> instrumentId.value,
         reservedA           |-> reservedA.value,
         reservedB           |-> reservedB.value,
         tradingStatus       |-> tradingStatus.value,
         symbolStatusFlags   |-> symbolStatusFlags.value,
         reason              |-> reason.value,
         sessionChangeReason |-> sessionChangeReason.value,
         newEndTime          |-> newEndTime.value,
         bookType            |-> bookType.value ], bookType.rest)

ZeroSymbolStatusMessage ==
    [ nanosecond          |-> [i \in 1 .. 4 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      reservedA           |-> [i \in 1 .. 1 |-> 0],
      reservedB           |-> [i \in 1 .. 1 |-> 0],
      tradingStatus       |-> [i \in 1 .. 1 |-> 0],
      symbolStatusFlags   |-> [i \in 1 .. 1 |-> 0],
      reason              |-> [i \in 1 .. 4 |-> 0],
      sessionChangeReason |-> [i \in 1 .. 1 |-> 0],
      newEndTime          |-> [i \in 1 .. 12 |-> 0],
      bookType            |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStatusMessage ==
    { ZeroSymbolStatusMessage }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.symbolStatusFlags = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.reason = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.sessionChangeReason = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.newEndTime = one] : one \in Sample(12) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.bookType = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 42 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ nanosecond    : Sample(4),
      orderId       : Sample(8),
      side          : Sample(1),
      quantity      : Sample(4),
      instrumentId  : Sample(4),
      reservedA     : Sample(1),
      reservedB     : Sample(1),
      price         : Sample(8),
      addOrderFlags : Sample(1),
      rfqId         : Sample(10) ]

EncodeAddOrderMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.addOrderFlags
        \o message.rfqId

DecodeAddOrderMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET addOrderFlags == ReadBytes(price.rest, 1) IN IF ~addOrderFlags.ok THEN Fail ELSE
    LET rfqId == ReadBytes(addOrderFlags.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    Ok([ nanosecond    |-> nanosecond.value,
         orderId       |-> orderId.value,
         side          |-> side.value,
         quantity      |-> quantity.value,
         instrumentId  |-> instrumentId.value,
         reservedA     |-> reservedA.value,
         reservedB     |-> reservedB.value,
         price         |-> price.value,
         addOrderFlags |-> addOrderFlags.value,
         rfqId         |-> rfqId.value ], rfqId.rest)

ZeroAddOrderMessage ==
    [ nanosecond    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      reservedA     |-> [i \in 1 .. 1 |-> 0],
      reservedB     |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      addOrderFlags |-> [i \in 1 .. 1 |-> 0],
      rfqId         |-> [i \in 1 .. 10 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.addOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.rfqId = one] : one \in Sample(10) }

(***************************************************************************)
(* Add Attributed Order Message: 41 bytes                                  *)
(***************************************************************************)

AddAttributedOrderMessage ==
    [ nanosecond              : Sample(4),
      orderId                 : Sample(8),
      side                    : Sample(1),
      quantity                : Sample(4),
      instrumentId            : Sample(4),
      price                   : Sample(8),
      attribution             : Sample(11),
      addAttributedOrderFlags : Sample(1) ]

EncodeAddAttributedOrderMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.instrumentId
        \o message.price
        \o message.attribution
        \o message.addAttributedOrderFlags

DecodeAddAttributedOrderMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET attribution == ReadBytes(price.rest, 11) IN IF ~attribution.ok THEN Fail ELSE
    LET addAttributedOrderFlags == ReadBytes(attribution.rest, 1) IN IF ~addAttributedOrderFlags.ok THEN Fail ELSE
    Ok([ nanosecond              |-> nanosecond.value,
         orderId                 |-> orderId.value,
         side                    |-> side.value,
         quantity                |-> quantity.value,
         instrumentId            |-> instrumentId.value,
         price                   |-> price.value,
         attribution             |-> attribution.value,
         addAttributedOrderFlags |-> addAttributedOrderFlags.value ], addAttributedOrderFlags.rest)

ZeroAddAttributedOrderMessage ==
    [ nanosecond              |-> [i \in 1 .. 4 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      quantity                |-> [i \in 1 .. 4 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      attribution             |-> [i \in 1 .. 11 |-> 0],
      addAttributedOrderFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Add Attributed Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddAttributedOrderMessage ==
    { ZeroAddAttributedOrderMessage }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.attribution = one] : one \in Sample(11) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.addAttributedOrderFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Deleted Message: 12 bytes                                         *)
(***************************************************************************)

OrderDeletedMessage ==
    [ nanosecond : Sample(4),
      orderId    : Sample(8) ]

EncodeOrderDeletedMessage(message) ==
    message.nanosecond
        \o message.orderId

DecodeOrderDeletedMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanosecond |-> nanosecond.value,
         orderId    |-> orderId.value ], orderId.rest)

ZeroOrderDeletedMessage ==
    [ nanosecond |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0] ]

(* Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeletedMessage ==
    { ZeroOrderDeletedMessage }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modified Message: 25 bytes                                        *)
(***************************************************************************)

OrderModifiedMessage ==
    [ nanosecond         : Sample(4),
      orderId            : Sample(8),
      newQuantity        : Sample(4),
      newPrice           : Sample(8),
      orderModifiedFlags : Sample(1) ]

EncodeOrderModifiedMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.newQuantity
        \o message.newPrice
        \o message.orderModifiedFlags

DecodeOrderModifiedMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET newQuantity == ReadBytes(orderId.rest, 4) IN IF ~newQuantity.ok THEN Fail ELSE
    LET newPrice == ReadBytes(newQuantity.rest, 8) IN IF ~newPrice.ok THEN Fail ELSE
    LET orderModifiedFlags == ReadBytes(newPrice.rest, 1) IN IF ~orderModifiedFlags.ok THEN Fail ELSE
    Ok([ nanosecond         |-> nanosecond.value,
         orderId            |-> orderId.value,
         newQuantity        |-> newQuantity.value,
         newPrice           |-> newPrice.value,
         orderModifiedFlags |-> orderModifiedFlags.value ], orderModifiedFlags.rest)

ZeroOrderModifiedMessage ==
    [ nanosecond         |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      newQuantity        |-> [i \in 1 .. 4 |-> 0],
      newPrice           |-> [i \in 1 .. 8 |-> 0],
      orderModifiedFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.newQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.newPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderModifiedFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Clear Message: 10 bytes                                      *)
(***************************************************************************)

OrderBookClearMessage ==
    [ nanosecond   : Sample(4),
      instrumentId : Sample(4),
      subBook      : Sample(1),
      bookLevel    : Sample(1) ]

EncodeOrderBookClearMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.subBook
        \o message.bookLevel

DecodeOrderBookClearMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET subBook == ReadBytes(instrumentId.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET bookLevel == ReadBytes(subBook.rest, 1) IN IF ~bookLevel.ok THEN Fail ELSE
    Ok([ nanosecond   |-> nanosecond.value,
         instrumentId |-> instrumentId.value,
         subBook      |-> subBook.value,
         bookLevel    |-> bookLevel.value ], bookLevel.rest)

ZeroOrderBookClearMessage ==
    [ nanosecond   |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      subBook      |-> [i \in 1 .. 1 |-> 0],
      bookLevel    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookClearMessage ==
    { ZeroOrderBookClearMessage }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.bookLevel = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 52 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanosecond               : Sample(4),
      orderId                  : Sample(8),
      executedQuantity         : Sample(4),
      tradeId                  : Sample(8),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8),
      venueOfExecution         : Sample(4) ]

EncodeOrderExecutedMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.executedQuantity
        \o message.tradeId
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice
        \o message.venueOfExecution

DecodeOrderExecutedMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(executedQuantity.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(tradeId.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(underlyingReferencePrice.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         orderId                  |-> orderId.value,
         executedQuantity         |-> executedQuantity.value,
         tradeId                  |-> tradeId.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value,
         venueOfExecution         |-> venueOfExecution.value ], venueOfExecution.rest)

ZeroOrderExecutedMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0],
      venueOfExecution         |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed With Price Size Message: 65 bytes                        *)
(***************************************************************************)

OrderExecutedWithPriceSizeMessage ==
    [ nanosecond               : Sample(4),
      orderId                  : Sample(8),
      executedQuantity         : Sample(4),
      displayQuantity          : Sample(4),
      tradeId                  : Sample(8),
      printable                : Sample(1),
      price                    : Sample(8),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8),
      venueOfExecution         : Sample(4) ]

EncodeOrderExecutedWithPriceSizeMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.executedQuantity
        \o message.displayQuantity
        \o message.tradeId
        \o message.printable
        \o message.price
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice
        \o message.venueOfExecution

DecodeOrderExecutedWithPriceSizeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET displayQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~displayQuantity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(displayQuantity.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET printable == ReadBytes(tradeId.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET price == ReadBytes(printable.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(price.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(underlyingReferencePrice.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         orderId                  |-> orderId.value,
         executedQuantity         |-> executedQuantity.value,
         displayQuantity          |-> displayQuantity.value,
         tradeId                  |-> tradeId.value,
         printable                |-> printable.value,
         price                    |-> price.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value,
         venueOfExecution         |-> venueOfExecution.value ], venueOfExecution.rest)

ZeroOrderExecutedWithPriceSizeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      displayQuantity          |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      printable                |-> [i \in 1 .. 1 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0],
      venueOfExecution         |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed With Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceSizeMessage ==
    { ZeroOrderExecutedWithPriceSizeMessage }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.displayQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Message: 72 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ nanosecond               : Sample(4),
      executedQuantity         : Sample(4),
      instrumentId             : Sample(4),
      reservedA                : Sample(1),
      reservedB                : Sample(1),
      price                    : Sample(8),
      tradeId                  : Sample(8),
      subBook                  : Sample(1),
      tradeFlags               : Sample(1),
      tradeSubType             : Sample(4),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8),
      venueOfExecution         : Sample(4),
      ptCancellationFlag       : Sample(4),
      ptAmendmentFlag          : Sample(4) ]

EncodeTradeMessage(message) ==
    message.nanosecond
        \o message.executedQuantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.tradeId
        \o message.subBook
        \o message.tradeFlags
        \o message.tradeSubType
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice
        \o message.venueOfExecution
        \o message.ptCancellationFlag
        \o message.ptAmendmentFlag

DecodeTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(executedQuantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET subBook == ReadBytes(tradeId.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(subBook.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    LET tradeSubType == ReadBytes(tradeFlags.rest, 4) IN IF ~tradeSubType.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(tradeSubType.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(underlyingReferencePrice.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    LET ptCancellationFlag == ReadBytes(venueOfExecution.rest, 4) IN IF ~ptCancellationFlag.ok THEN Fail ELSE
    LET ptAmendmentFlag == ReadBytes(ptCancellationFlag.rest, 4) IN IF ~ptAmendmentFlag.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         executedQuantity         |-> executedQuantity.value,
         instrumentId             |-> instrumentId.value,
         reservedA                |-> reservedA.value,
         reservedB                |-> reservedB.value,
         price                    |-> price.value,
         tradeId                  |-> tradeId.value,
         subBook                  |-> subBook.value,
         tradeFlags               |-> tradeFlags.value,
         tradeSubType             |-> tradeSubType.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value,
         venueOfExecution         |-> venueOfExecution.value,
         ptCancellationFlag       |-> ptCancellationFlag.value,
         ptAmendmentFlag          |-> ptAmendmentFlag.value ], ptAmendmentFlag.rest)

ZeroTradeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      instrumentId             |-> [i \in 1 .. 4 |-> 0],
      reservedA                |-> [i \in 1 .. 1 |-> 0],
      reservedB                |-> [i \in 1 .. 1 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      subBook                  |-> [i \in 1 .. 1 |-> 0],
      tradeFlags               |-> [i \in 1 .. 1 |-> 0],
      tradeSubType             |-> [i \in 1 .. 4 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0],
      venueOfExecution         |-> [i \in 1 .. 4 |-> 0],
      ptCancellationFlag       |-> [i \in 1 .. 4 |-> 0],
      ptAmendmentFlag          |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeSubType = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.ptCancellationFlag = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.ptAmendmentFlag = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Trade Message: 67 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ nanosecond               : Sample(4),
      quantity                 : Sample(4),
      instrumentId             : Sample(4),
      reservedA                : Sample(1),
      reservedB                : Sample(1),
      price                    : Sample(8),
      tradeId                  : Sample(8),
      auctionType              : Sample(1),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8),
      ptCancellationFlag       : Sample(4),
      ptAmendmentFlag          : Sample(4),
      venueOfExecution         : Sample(4) ]

EncodeAuctionTradeMessage(message) ==
    message.nanosecond
        \o message.quantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.tradeId
        \o message.auctionType
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice
        \o message.ptCancellationFlag
        \o message.ptAmendmentFlag
        \o message.venueOfExecution

DecodeAuctionTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET quantity == ReadBytes(nanosecond.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(quantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(tradeId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(auctionType.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    LET ptCancellationFlag == ReadBytes(underlyingReferencePrice.rest, 4) IN IF ~ptCancellationFlag.ok THEN Fail ELSE
    LET ptAmendmentFlag == ReadBytes(ptCancellationFlag.rest, 4) IN IF ~ptAmendmentFlag.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(ptAmendmentFlag.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         quantity                 |-> quantity.value,
         instrumentId             |-> instrumentId.value,
         reservedA                |-> reservedA.value,
         reservedB                |-> reservedB.value,
         price                    |-> price.value,
         tradeId                  |-> tradeId.value,
         auctionType              |-> auctionType.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value,
         ptCancellationFlag       |-> ptCancellationFlag.value,
         ptAmendmentFlag          |-> ptAmendmentFlag.value,
         venueOfExecution         |-> venueOfExecution.value ], venueOfExecution.rest)

ZeroAuctionTradeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      quantity                 |-> [i \in 1 .. 4 |-> 0],
      instrumentId             |-> [i \in 1 .. 4 |-> 0],
      reservedA                |-> [i \in 1 .. 1 |-> 0],
      reservedB                |-> [i \in 1 .. 1 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      auctionType              |-> [i \in 1 .. 1 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0],
      ptCancellationFlag       |-> [i \in 1 .. 4 |-> 0],
      ptAmendmentFlag          |-> [i \in 1 .. 4 |-> 0],
      venueOfExecution         |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.ptCancellationFlag = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.ptAmendmentFlag = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }

(***************************************************************************)
(* Off Book Trade Message: 78 bytes                                        *)
(***************************************************************************)

OffBookTradeMessage ==
    [ nanosecond               : Sample(4),
      executedQuantity         : Sample(4),
      instrumentId             : Sample(4),
      reservedA                : Sample(1),
      reservedB                : Sample(1),
      price                    : Sample(8),
      tradeId                  : Sample(8),
      offBookTradeType         : Sample(4),
      tradeTime                : Sample(8),
      tradeDate                : Sample(8),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8),
      ptCancellationFlag       : Sample(4) ]

EncodeOffBookTradeMessage(message) ==
    message.nanosecond
        \o message.executedQuantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.tradeId
        \o message.offBookTradeType
        \o message.tradeTime
        \o message.tradeDate
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice
        \o message.ptCancellationFlag

DecodeOffBookTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(executedQuantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET offBookTradeType == ReadBytes(tradeId.rest, 4) IN IF ~offBookTradeType.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(offBookTradeType.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradeTime.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(tradeDate.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    LET ptCancellationFlag == ReadBytes(underlyingReferencePrice.rest, 4) IN IF ~ptCancellationFlag.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         executedQuantity         |-> executedQuantity.value,
         instrumentId             |-> instrumentId.value,
         reservedA                |-> reservedA.value,
         reservedB                |-> reservedB.value,
         price                    |-> price.value,
         tradeId                  |-> tradeId.value,
         offBookTradeType         |-> offBookTradeType.value,
         tradeTime                |-> tradeTime.value,
         tradeDate                |-> tradeDate.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value,
         ptCancellationFlag       |-> ptCancellationFlag.value ], ptCancellationFlag.rest)

ZeroOffBookTradeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      instrumentId             |-> [i \in 1 .. 4 |-> 0],
      reservedA                |-> [i \in 1 .. 1 |-> 0],
      reservedB                |-> [i \in 1 .. 1 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      offBookTradeType         |-> [i \in 1 .. 4 |-> 0],
      tradeTime                |-> [i \in 1 .. 8 |-> 0],
      tradeDate                |-> [i \in 1 .. 8 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0],
      ptCancellationFlag       |-> [i \in 1 .. 4 |-> 0] ]

(* Off Book Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOffBookTradeMessage ==
    { ZeroOffBookTradeMessage }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.offBookTradeType = one] : one \in Sample(4) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.ptCancellationFlag = one] : one \in Sample(4) }

(***************************************************************************)
(* Recovery Trade Message: 90 bytes                                        *)
(***************************************************************************)

RecoveryTradeMessage ==
    [ nanosecond               : Sample(4),
      executedQuantity         : Sample(4),
      instrumentId             : Sample(4),
      reservedA                : Sample(1),
      reservedB                : Sample(1),
      price                    : Sample(8),
      tradeId                  : Sample(8),
      auctionType              : Sample(1),
      offBookRfqTradeType      : Sample(4),
      tradeTime                : Sample(8),
      tradeDate                : Sample(8),
      actionType               : Sample(1),
      subBook                  : Sample(1),
      recoveryTradeFlags       : Sample(1),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8),
      venueOfExecution         : Sample(4),
      ptCancellationFlag       : Sample(4),
      ptAmendmentFlag          : Sample(4) ]

EncodeRecoveryTradeMessage(message) ==
    message.nanosecond
        \o message.executedQuantity
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.tradeId
        \o message.auctionType
        \o message.offBookRfqTradeType
        \o message.tradeTime
        \o message.tradeDate
        \o message.actionType
        \o message.subBook
        \o message.recoveryTradeFlags
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice
        \o message.venueOfExecution
        \o message.ptCancellationFlag
        \o message.ptAmendmentFlag

DecodeRecoveryTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(executedQuantity.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(tradeId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET offBookRfqTradeType == ReadBytes(auctionType.rest, 4) IN IF ~offBookRfqTradeType.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(offBookRfqTradeType.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradeTime.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET actionType == ReadBytes(tradeDate.rest, 1) IN IF ~actionType.ok THEN Fail ELSE
    LET subBook == ReadBytes(actionType.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET recoveryTradeFlags == ReadBytes(subBook.rest, 1) IN IF ~recoveryTradeFlags.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(recoveryTradeFlags.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(underlyingReferencePrice.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    LET ptCancellationFlag == ReadBytes(venueOfExecution.rest, 4) IN IF ~ptCancellationFlag.ok THEN Fail ELSE
    LET ptAmendmentFlag == ReadBytes(ptCancellationFlag.rest, 4) IN IF ~ptAmendmentFlag.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         executedQuantity         |-> executedQuantity.value,
         instrumentId             |-> instrumentId.value,
         reservedA                |-> reservedA.value,
         reservedB                |-> reservedB.value,
         price                    |-> price.value,
         tradeId                  |-> tradeId.value,
         auctionType              |-> auctionType.value,
         offBookRfqTradeType      |-> offBookRfqTradeType.value,
         tradeTime                |-> tradeTime.value,
         tradeDate                |-> tradeDate.value,
         actionType               |-> actionType.value,
         subBook                  |-> subBook.value,
         recoveryTradeFlags       |-> recoveryTradeFlags.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value,
         venueOfExecution         |-> venueOfExecution.value,
         ptCancellationFlag       |-> ptCancellationFlag.value,
         ptAmendmentFlag          |-> ptAmendmentFlag.value ], ptAmendmentFlag.rest)

ZeroRecoveryTradeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      instrumentId             |-> [i \in 1 .. 4 |-> 0],
      reservedA                |-> [i \in 1 .. 1 |-> 0],
      reservedB                |-> [i \in 1 .. 1 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      auctionType              |-> [i \in 1 .. 1 |-> 0],
      offBookRfqTradeType      |-> [i \in 1 .. 4 |-> 0],
      tradeTime                |-> [i \in 1 .. 8 |-> 0],
      tradeDate                |-> [i \in 1 .. 8 |-> 0],
      actionType               |-> [i \in 1 .. 1 |-> 0],
      subBook                  |-> [i \in 1 .. 1 |-> 0],
      recoveryTradeFlags       |-> [i \in 1 .. 1 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0],
      venueOfExecution         |-> [i \in 1 .. 4 |-> 0],
      ptCancellationFlag       |-> [i \in 1 .. 4 |-> 0],
      ptAmendmentFlag          |-> [i \in 1 .. 4 |-> 0] ]

(* Recovery Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedRecoveryTradeMessage ==
    { ZeroRecoveryTradeMessage }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.offBookRfqTradeType = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.actionType = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.recoveryTradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.ptCancellationFlag = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.ptAmendmentFlag = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Info Message: 28 bytes                                          *)
(***************************************************************************)

AuctionInfoMessage ==
    [ nanosecond         : Sample(4),
      pairedQuantity     : Sample(4),
      reserved4          : Sample(4),
      imbalanceDirection : Sample(1),
      instrumentId       : Sample(4),
      reservedA          : Sample(1),
      reservedB          : Sample(1),
      price              : Sample(8),
      auctionType        : Sample(1) ]

EncodeAuctionInfoMessage(message) ==
    message.nanosecond
        \o message.pairedQuantity
        \o message.reserved4
        \o message.imbalanceDirection
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.price
        \o message.auctionType

DecodeAuctionInfoMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET pairedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~pairedQuantity.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(pairedQuantity.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(reserved4.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(imbalanceDirection.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET price == ReadBytes(reservedB.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET auctionType == ReadBytes(price.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    Ok([ nanosecond         |-> nanosecond.value,
         pairedQuantity     |-> pairedQuantity.value,
         reserved4          |-> reserved4.value,
         imbalanceDirection |-> imbalanceDirection.value,
         instrumentId       |-> instrumentId.value,
         reservedA          |-> reservedA.value,
         reservedB          |-> reservedB.value,
         price              |-> price.value,
         auctionType        |-> auctionType.value ], auctionType.rest)

ZeroAuctionInfoMessage ==
    [ nanosecond         |-> [i \in 1 .. 4 |-> 0],
      pairedQuantity     |-> [i \in 1 .. 4 |-> 0],
      reserved4          |-> [i \in 1 .. 4 |-> 0],
      imbalanceDirection |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      reservedA          |-> [i \in 1 .. 1 |-> 0],
      reservedB          |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      auctionType        |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Info Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionInfoMessage ==
    { ZeroAuctionInfoMessage }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.pairedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.auctionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Statistics Message: 21 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ nanosecond         : Sample(4),
      instrumentId       : Sample(4),
      reservedA          : Sample(1),
      reservedB          : Sample(1),
      statisticType      : Sample(1),
      price              : Sample(8),
      openCloseIndicator : Sample(1),
      subBook            : Sample(1) ]

EncodeStatisticsMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.reservedA
        \o message.reservedB
        \o message.statisticType
        \o message.price
        \o message.openCloseIndicator
        \o message.subBook

DecodeStatisticsMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reservedA == ReadBytes(instrumentId.rest, 1) IN IF ~reservedA.ok THEN Fail ELSE
    LET reservedB == ReadBytes(reservedA.rest, 1) IN IF ~reservedB.ok THEN Fail ELSE
    LET statisticType == ReadBytes(reservedB.rest, 1) IN IF ~statisticType.ok THEN Fail ELSE
    LET price == ReadBytes(statisticType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET openCloseIndicator == ReadBytes(price.rest, 1) IN IF ~openCloseIndicator.ok THEN Fail ELSE
    LET subBook == ReadBytes(openCloseIndicator.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    Ok([ nanosecond         |-> nanosecond.value,
         instrumentId       |-> instrumentId.value,
         reservedA          |-> reservedA.value,
         reservedB          |-> reservedB.value,
         statisticType      |-> statisticType.value,
         price              |-> price.value,
         openCloseIndicator |-> openCloseIndicator.value,
         subBook            |-> subBook.value ], subBook.rest)

ZeroStatisticsMessage ==
    [ nanosecond         |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      reservedA          |-> [i \in 1 .. 1 |-> 0],
      reservedB          |-> [i \in 1 .. 1 |-> 0],
      statisticType      |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      openCloseIndicator |-> [i \in 1 .. 1 |-> 0],
      subBook            |-> [i \in 1 .. 1 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.reservedA = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.reservedB = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.statisticType = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.openCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.subBook = one] : one \in Sample(1) }

(***************************************************************************)
(* Extended Statistics Message: 137 bytes                                  *)
(***************************************************************************)

ExtendedStatisticsMessage ==
    [ nanosecond            : Sample(4),
      instrumentId          : Sample(4),
      highPrice             : Sample(8),
      lowPrice              : Sample(8),
      vwap                  : Sample(8),
      volume                : Sample(4),
      turnover              : Sample(8),
      numberOfTrades        : Sample(4),
      reserved8             : Sample(8),
      subBook               : Sample(1),
      notionalExposure      : Sample(8),
      notionalDeltaExposure : Sample(8),
      openInterest          : Sample(8),
      theoreticalPrice      : Sample(8),
      delta                 : Sample(8),
      gamma                 : Sample(8),
      vega                  : Sample(8),
      theta                 : Sample(8),
      rho                   : Sample(8),
      volatility            : Sample(8) ]

EncodeExtendedStatisticsMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.highPrice
        \o message.lowPrice
        \o message.vwap
        \o message.volume
        \o message.turnover
        \o message.numberOfTrades
        \o message.reserved8
        \o message.subBook
        \o message.notionalExposure
        \o message.notionalDeltaExposure
        \o message.openInterest
        \o message.theoreticalPrice
        \o message.delta
        \o message.gamma
        \o message.vega
        \o message.theta
        \o message.rho
        \o message.volatility

DecodeExtendedStatisticsMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET highPrice == ReadBytes(instrumentId.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET vwap == ReadBytes(lowPrice.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET volume == ReadBytes(vwap.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET turnover == ReadBytes(volume.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET numberOfTrades == ReadBytes(turnover.rest, 4) IN IF ~numberOfTrades.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(numberOfTrades.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET subBook == ReadBytes(reserved8.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET notionalExposure == ReadBytes(subBook.rest, 8) IN IF ~notionalExposure.ok THEN Fail ELSE
    LET notionalDeltaExposure == ReadBytes(notionalExposure.rest, 8) IN IF ~notionalDeltaExposure.ok THEN Fail ELSE
    LET openInterest == ReadBytes(notionalDeltaExposure.rest, 8) IN IF ~openInterest.ok THEN Fail ELSE
    LET theoreticalPrice == ReadBytes(openInterest.rest, 8) IN IF ~theoreticalPrice.ok THEN Fail ELSE
    LET delta == ReadBytes(theoreticalPrice.rest, 8) IN IF ~delta.ok THEN Fail ELSE
    LET gamma == ReadBytes(delta.rest, 8) IN IF ~gamma.ok THEN Fail ELSE
    LET vega == ReadBytes(gamma.rest, 8) IN IF ~vega.ok THEN Fail ELSE
    LET theta == ReadBytes(vega.rest, 8) IN IF ~theta.ok THEN Fail ELSE
    LET rho == ReadBytes(theta.rest, 8) IN IF ~rho.ok THEN Fail ELSE
    LET volatility == ReadBytes(rho.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    Ok([ nanosecond            |-> nanosecond.value,
         instrumentId          |-> instrumentId.value,
         highPrice             |-> highPrice.value,
         lowPrice              |-> lowPrice.value,
         vwap                  |-> vwap.value,
         volume                |-> volume.value,
         turnover              |-> turnover.value,
         numberOfTrades        |-> numberOfTrades.value,
         reserved8             |-> reserved8.value,
         subBook               |-> subBook.value,
         notionalExposure      |-> notionalExposure.value,
         notionalDeltaExposure |-> notionalDeltaExposure.value,
         openInterest          |-> openInterest.value,
         theoreticalPrice      |-> theoreticalPrice.value,
         delta                 |-> delta.value,
         gamma                 |-> gamma.value,
         vega                  |-> vega.value,
         theta                 |-> theta.value,
         rho                   |-> rho.value,
         volatility            |-> volatility.value ], volatility.rest)

ZeroExtendedStatisticsMessage ==
    [ nanosecond            |-> [i \in 1 .. 4 |-> 0],
      instrumentId          |-> [i \in 1 .. 4 |-> 0],
      highPrice             |-> [i \in 1 .. 8 |-> 0],
      lowPrice              |-> [i \in 1 .. 8 |-> 0],
      vwap                  |-> [i \in 1 .. 8 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      turnover              |-> [i \in 1 .. 8 |-> 0],
      numberOfTrades        |-> [i \in 1 .. 4 |-> 0],
      reserved8             |-> [i \in 1 .. 8 |-> 0],
      subBook               |-> [i \in 1 .. 1 |-> 0],
      notionalExposure      |-> [i \in 1 .. 8 |-> 0],
      notionalDeltaExposure |-> [i \in 1 .. 8 |-> 0],
      openInterest          |-> [i \in 1 .. 8 |-> 0],
      theoreticalPrice      |-> [i \in 1 .. 8 |-> 0],
      delta                 |-> [i \in 1 .. 8 |-> 0],
      gamma                 |-> [i \in 1 .. 8 |-> 0],
      vega                  |-> [i \in 1 .. 8 |-> 0],
      theta                 |-> [i \in 1 .. 8 |-> 0],
      rho                   |-> [i \in 1 .. 8 |-> 0],
      volatility            |-> [i \in 1 .. 8 |-> 0] ]

(* Extended Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedStatisticsMessage ==
    { ZeroExtendedStatisticsMessage }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.numberOfTrades = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.notionalExposure = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.notionalDeltaExposure = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.openInterest = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.theoreticalPrice = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.delta = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.gamma = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.vega = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.theta = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.rho = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.volatility = one] : one \in Sample(8) }

(***************************************************************************)
(* News Message: 1063 bytes                                                *)
(***************************************************************************)

NewsMessage ==
    [ nanosecond  : Sample(4),
      time        : Sample(8),
      urgency     : Sample(1),
      headline    : Sample(100),
      text        : Sample(750),
      instruments : Sample(100),
      underlyings : Sample(100) ]

EncodeNewsMessage(message) ==
    message.nanosecond
        \o message.time
        \o message.urgency
        \o message.headline
        \o message.text
        \o message.instruments
        \o message.underlyings

DecodeNewsMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET time == ReadBytes(nanosecond.rest, 8) IN IF ~time.ok THEN Fail ELSE
    LET urgency == ReadBytes(time.rest, 1) IN IF ~urgency.ok THEN Fail ELSE
    LET headline == ReadBytes(urgency.rest, 100) IN IF ~headline.ok THEN Fail ELSE
    LET text == ReadBytes(headline.rest, 750) IN IF ~text.ok THEN Fail ELSE
    LET instruments == ReadBytes(text.rest, 100) IN IF ~instruments.ok THEN Fail ELSE
    LET underlyings == ReadBytes(instruments.rest, 100) IN IF ~underlyings.ok THEN Fail ELSE
    Ok([ nanosecond  |-> nanosecond.value,
         time        |-> time.value,
         urgency     |-> urgency.value,
         headline    |-> headline.value,
         text        |-> text.value,
         instruments |-> instruments.value,
         underlyings |-> underlyings.value ], underlyings.rest)

ZeroNewsMessage ==
    [ nanosecond  |-> [i \in 1 .. 4 |-> 0],
      time        |-> [i \in 1 .. 8 |-> 0],
      urgency     |-> [i \in 1 .. 1 |-> 0],
      headline    |-> [i \in 1 .. 100 |-> 0],
      text        |-> [i \in 1 .. 750 |-> 0],
      instruments |-> [i \in 1 .. 100 |-> 0],
      underlyings |-> [i \in 1 .. 100 |-> 0] ]

(* News Message at zero, then each field in turn at the values it is checked at *)
CheckedNewsMessage ==
    { ZeroNewsMessage }
        \cup { [ZeroNewsMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroNewsMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroNewsMessage EXCEPT !.urgency = one] : one \in Sample(1) }
        \cup { [ZeroNewsMessage EXCEPT !.headline = one] : one \in Sample(100) }
        \cup { [ZeroNewsMessage EXCEPT !.text = one] : one \in Sample(750) }
        \cup { [ZeroNewsMessage EXCEPT !.instruments = one] : one \in Sample(100) }
        \cup { [ZeroNewsMessage EXCEPT !.underlyings = one] : one \in Sample(100) }

(***************************************************************************)
(* Top Of Book Message: 35 bytes                                           *)
(***************************************************************************)

TopOfBookMessage ==
    [ nanosecond          : Sample(4),
      instrumentId        : Sample(4),
      reserveField        : Sample(2),
      subBookFlags        : Sample(1),
      action              : Sample(1),
      side                : Sample(1),
      price               : Sample(8),
      quantity            : Sample(4),
      marketOrderQuantity : Sample(4),
      reserved2           : Sample(2),
      splits              : Sample(4) ]

EncodeTopOfBookMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.reserveField
        \o message.subBookFlags
        \o message.action
        \o message.side
        \o message.price
        \o message.quantity
        \o message.marketOrderQuantity
        \o message.reserved2
        \o message.splits

DecodeTopOfBookMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reserveField == ReadBytes(instrumentId.rest, 2) IN IF ~reserveField.ok THEN Fail ELSE
    LET subBookFlags == ReadBytes(reserveField.rest, 1) IN IF ~subBookFlags.ok THEN Fail ELSE
    LET action == ReadBytes(subBookFlags.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET side == ReadBytes(action.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET marketOrderQuantity == ReadBytes(quantity.rest, 4) IN IF ~marketOrderQuantity.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(marketOrderQuantity.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET splits == ReadBytes(reserved2.rest, 4) IN IF ~splits.ok THEN Fail ELSE
    Ok([ nanosecond          |-> nanosecond.value,
         instrumentId        |-> instrumentId.value,
         reserveField        |-> reserveField.value,
         subBookFlags        |-> subBookFlags.value,
         action              |-> action.value,
         side                |-> side.value,
         price               |-> price.value,
         quantity            |-> quantity.value,
         marketOrderQuantity |-> marketOrderQuantity.value,
         reserved2           |-> reserved2.value,
         splits              |-> splits.value ], splits.rest)

ZeroTopOfBookMessage ==
    [ nanosecond          |-> [i \in 1 .. 4 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      reserveField        |-> [i \in 1 .. 2 |-> 0],
      subBookFlags        |-> [i \in 1 .. 1 |-> 0],
      action              |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      marketOrderQuantity |-> [i \in 1 .. 4 |-> 0],
      reserved2           |-> [i \in 1 .. 2 |-> 0],
      splits              |-> [i \in 1 .. 4 |-> 0] ]

(* Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBookMessage ==
    { ZeroTopOfBookMessage }
        \cup { [ZeroTopOfBookMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.reserveField = one] : one \in Sample(2) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.subBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.marketOrderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.splits = one] : one \in Sample(4) }

(***************************************************************************)
(* Indicative Quote Info Message: 34 bytes                                 *)
(***************************************************************************)

IndicativeQuoteInfoMessage ==
    [ nanosecond           : Sample(4),
      instrumentId         : Sample(4),
      rfqId                : Sample(10),
      indicativeBidPrice   : Sample(8),
      indicativeOfferPrice : Sample(8) ]

EncodeIndicativeQuoteInfoMessage(message) ==
    message.nanosecond
        \o message.instrumentId
        \o message.rfqId
        \o message.indicativeBidPrice
        \o message.indicativeOfferPrice

DecodeIndicativeQuoteInfoMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanosecond.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET rfqId == ReadBytes(instrumentId.rest, 10) IN IF ~rfqId.ok THEN Fail ELSE
    LET indicativeBidPrice == ReadBytes(rfqId.rest, 8) IN IF ~indicativeBidPrice.ok THEN Fail ELSE
    LET indicativeOfferPrice == ReadBytes(indicativeBidPrice.rest, 8) IN IF ~indicativeOfferPrice.ok THEN Fail ELSE
    Ok([ nanosecond           |-> nanosecond.value,
         instrumentId         |-> instrumentId.value,
         rfqId                |-> rfqId.value,
         indicativeBidPrice   |-> indicativeBidPrice.value,
         indicativeOfferPrice |-> indicativeOfferPrice.value ], indicativeOfferPrice.rest)

ZeroIndicativeQuoteInfoMessage ==
    [ nanosecond           |-> [i \in 1 .. 4 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      rfqId                |-> [i \in 1 .. 10 |-> 0],
      indicativeBidPrice   |-> [i \in 1 .. 8 |-> 0],
      indicativeOfferPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Indicative Quote Info Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicativeQuoteInfoMessage ==
    { ZeroIndicativeQuoteInfoMessage }
        \cup { [ZeroIndicativeQuoteInfoMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeQuoteInfoMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeQuoteInfoMessage EXCEPT !.rfqId = one] : one \in Sample(10) }
        \cup { [ZeroIndicativeQuoteInfoMessage EXCEPT !.indicativeBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicativeQuoteInfoMessage EXCEPT !.indicativeOfferPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
ReplayRequestMessageCode == 3  \* 0x03
SnapshotRequestMessageCode == 129  \* 0x81
LogoutRequestMessageCode == 5  \* 0x05
LoginResponseMessageCode == 2  \* 0x02
ReplayResponseMessageCode == 4  \* 0x04
SnapshotResponseMessageCode == 130  \* 0x82
SnapshotCompleteMessageCode == 131  \* 0x83
TimeMessageCode == 84  \* 0x54
SystemEventMessageCode == 83  \* 0x53
SymbolDirectoryMessageCode == 82  \* 0x52
SymbolStatusMessageCode == 72  \* 0x48
AddOrderMessageCode == 65  \* 0x41
AddAttributedOrderMessageCode == 70  \* 0x46
OrderDeletedMessageCode == 68  \* 0x44
OrderModifiedMessageCode == 85  \* 0x55
OrderBookClearMessageCode == 121  \* 0x79
OrderExecutedMessageCode == 69  \* 0x45
OrderExecutedWithPriceSizeMessageCode == 67  \* 0x43
TradeMessageCode == 80  \* 0x50
AuctionTradeMessageCode == 81  \* 0x51
OffBookTradeMessageCode == 120  \* 0x78
RecoveryTradeMessageCode == 118  \* 0x76
AuctionInfoMessageCode == 73  \* 0x49
StatisticsMessageCode == 119  \* 0x77
ExtendedStatisticsMessageCode == 128  \* 0x80
NewsMessageCode == 117  \* 0x75
TopOfBookMessageCode == 113  \* 0x71
IndicativeQuoteInfoMessageCode == 105  \* 0x69

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {SnapshotRequestMessageCode}, body : SnapshotRequestMessage ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {ReplayResponseMessageCode}, body : ReplayResponseMessage ]
        \cup [ tag : {SnapshotResponseMessageCode}, body : SnapshotResponseMessage ]
        \cup [ tag : {SnapshotCompleteMessageCode}, body : SnapshotCompleteMessage ]
        \cup [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {SymbolDirectoryMessageCode}, body : SymbolDirectoryMessage ]
        \cup [ tag : {SymbolStatusMessageCode}, body : SymbolStatusMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AddAttributedOrderMessageCode}, body : AddAttributedOrderMessage ]
        \cup [ tag : {OrderDeletedMessageCode}, body : OrderDeletedMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {OrderBookClearMessageCode}, body : OrderBookClearMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceSizeMessageCode}, body : OrderExecutedWithPriceSizeMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {AuctionTradeMessageCode}, body : AuctionTradeMessage ]
        \cup [ tag : {OffBookTradeMessageCode}, body : OffBookTradeMessage ]
        \cup [ tag : {RecoveryTradeMessageCode}, body : RecoveryTradeMessage ]
        \cup [ tag : {AuctionInfoMessageCode}, body : AuctionInfoMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {ExtendedStatisticsMessageCode}, body : ExtendedStatisticsMessage ]
        \cup [ tag : {NewsMessageCode}, body : NewsMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]
        \cup [ tag : {IndicativeQuoteInfoMessageCode}, body : IndicativeQuoteInfoMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = SnapshotRequestMessageCode -> EncodeSnapshotRequestMessage(message.body)
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = ReplayResponseMessageCode -> EncodeReplayResponseMessage(message.body)
      [] message.tag = SnapshotResponseMessageCode -> EncodeSnapshotResponseMessage(message.body)
      [] message.tag = SnapshotCompleteMessageCode -> EncodeSnapshotCompleteMessage(message.body)
      [] message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = SymbolDirectoryMessageCode -> EncodeSymbolDirectoryMessage(message.body)
      [] message.tag = SymbolStatusMessageCode -> EncodeSymbolStatusMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AddAttributedOrderMessageCode -> EncodeAddAttributedOrderMessage(message.body)
      [] message.tag = OrderDeletedMessageCode -> EncodeOrderDeletedMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = OrderBookClearMessageCode -> EncodeOrderBookClearMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceSizeMessageCode -> EncodeOrderExecutedWithPriceSizeMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = AuctionTradeMessageCode -> EncodeAuctionTradeMessage(message.body)
      [] message.tag = OffBookTradeMessageCode -> EncodeOffBookTradeMessage(message.body)
      [] message.tag = RecoveryTradeMessageCode -> EncodeRecoveryTradeMessage(message.body)
      [] message.tag = AuctionInfoMessageCode -> EncodeAuctionInfoMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = ExtendedStatisticsMessageCode -> EncodeExtendedStatisticsMessage(message.body)
      [] message.tag = NewsMessageCode -> EncodeNewsMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)
      [] message.tag = IndicativeQuoteInfoMessageCode -> EncodeIndicativeQuoteInfoMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = SnapshotRequestMessageCode -> DecodeSnapshotRequestMessage(bytes)
              [] tag = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = ReplayResponseMessageCode -> DecodeReplayResponseMessage(bytes)
              [] tag = SnapshotResponseMessageCode -> DecodeSnapshotResponseMessage(bytes)
              [] tag = SnapshotCompleteMessageCode -> DecodeSnapshotCompleteMessage(bytes)
              [] tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = SymbolDirectoryMessageCode -> DecodeSymbolDirectoryMessage(bytes)
              [] tag = SymbolStatusMessageCode -> DecodeSymbolStatusMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AddAttributedOrderMessageCode -> DecodeAddAttributedOrderMessage(bytes)
              [] tag = OrderDeletedMessageCode -> DecodeOrderDeletedMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = OrderBookClearMessageCode -> DecodeOrderBookClearMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceSizeMessageCode -> DecodeOrderExecutedWithPriceSizeMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = AuctionTradeMessageCode -> DecodeAuctionTradeMessage(bytes)
              [] tag = OffBookTradeMessageCode -> DecodeOffBookTradeMessage(bytes)
              [] tag = RecoveryTradeMessageCode -> DecodeRecoveryTradeMessage(bytes)
              [] tag = AuctionInfoMessageCode -> DecodeAuctionInfoMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = ExtendedStatisticsMessageCode -> DecodeExtendedStatisticsMessage(bytes)
              [] tag = NewsMessageCode -> DecodeNewsMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] tag = IndicativeQuoteInfoMessageCode -> DecodeIndicativeQuoteInfoMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> SnapshotRequestMessageCode, body |-> one] : one \in CheckedSnapshotRequestMessage }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> ReplayResponseMessageCode, body |-> one] : one \in CheckedReplayResponseMessage }
        \cup { [tag |-> SnapshotResponseMessageCode, body |-> one] : one \in CheckedSnapshotResponseMessage }
        \cup { [tag |-> SnapshotCompleteMessageCode, body |-> one] : one \in CheckedSnapshotCompleteMessage }
        \cup { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> SymbolDirectoryMessageCode, body |-> one] : one \in CheckedSymbolDirectoryMessage }
        \cup { [tag |-> SymbolStatusMessageCode, body |-> one] : one \in CheckedSymbolStatusMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AddAttributedOrderMessageCode, body |-> one] : one \in CheckedAddAttributedOrderMessage }
        \cup { [tag |-> OrderDeletedMessageCode, body |-> one] : one \in CheckedOrderDeletedMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> OrderBookClearMessageCode, body |-> one] : one \in CheckedOrderBookClearMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceSizeMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceSizeMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> AuctionTradeMessageCode, body |-> one] : one \in CheckedAuctionTradeMessage }
        \cup { [tag |-> OffBookTradeMessageCode, body |-> one] : one \in CheckedOffBookTradeMessage }
        \cup { [tag |-> RecoveryTradeMessageCode, body |-> one] : one \in CheckedRecoveryTradeMessage }
        \cup { [tag |-> AuctionInfoMessageCode, body |-> one] : one \in CheckedAuctionInfoMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> ExtendedStatisticsMessageCode, body |-> one] : one \in CheckedExtendedStatisticsMessage }
        \cup { [tag |-> NewsMessageCode, body |-> one] : one \in CheckedNewsMessage }
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }
        \cup { [tag |-> IndicativeQuoteInfoMessageCode, body |-> one] : one \in CheckedIndicativeQuoteInfoMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotRequestMessageCode, body |-> ZeroSnapshotRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayResponseMessageCode, body |-> ZeroReplayResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotResponseMessageCode, body |-> ZeroSnapshotResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotCompleteMessageCode, body |-> ZeroSnapshotCompleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolDirectoryMessageCode, body |-> ZeroSymbolDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolStatusMessageCode, body |-> ZeroSymbolStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddAttributedOrderMessageCode, body |-> ZeroAddAttributedOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeletedMessageCode, body |-> ZeroOrderDeletedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifiedMessageCode, body |-> ZeroOrderModifiedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookClearMessageCode, body |-> ZeroOrderBookClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceSizeMessageCode, body |-> ZeroOrderExecutedWithPriceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionTradeMessageCode, body |-> ZeroAuctionTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OffBookTradeMessageCode, body |-> ZeroOffBookTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RecoveryTradeMessageCode, body |-> ZeroRecoveryTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionInfoMessageCode, body |-> ZeroAuctionInfoMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExtendedStatisticsMessageCode, body |-> ZeroExtendedStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewsMessageCode, body |-> ZeroNewsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndicativeQuoteInfoMessageCode, body |-> ZeroIndicativeQuoteInfoMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length          : Sample(2),
      marketDataGroup : Sample(1),
      sequenceNumber  : Sample(4),
      message         : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.marketDataGroup
        \o message.sequenceNumber
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(messageCount.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(marketDataGroup.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET message == ReadMessageList(sequenceNumber.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length          |-> length.value,
         marketDataGroup |-> marketDataGroup.value,
         sequenceNumber  |-> sequenceNumber.value,
         message         |-> message.value ], message.rest)

ZeroPacket ==
    [ length          |-> [i \in 1 .. 2 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      message         |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Snapshot Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRequestMessage ==
    \A message \in CheckedSnapshotRequestMessage :
        LET read == DecodeSnapshotRequestMessage(EncodeSnapshotRequestMessage(message))
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

(* Every Snapshot Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotResponseMessage ==
    \A message \in CheckedSnapshotResponseMessage :
        LET read == DecodeSnapshotResponseMessage(EncodeSnapshotResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotCompleteMessage ==
    \A message \in CheckedSnapshotCompleteMessage :
        LET read == DecodeSnapshotCompleteMessage(EncodeSnapshotCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeMessage ==
    \A message \in CheckedTimeMessage :
        LET read == DecodeTimeMessage(EncodeTimeMessage(message))
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

(* Every Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolDirectoryMessageTail ==
    \A message \in CheckedSymbolDirectoryMessageTail :
        LET read == DecodeSymbolDirectoryMessageTail(EncodeSymbolDirectoryMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolDirectoryMessage ==
    \A message \in CheckedSymbolDirectoryMessage :
        LET read == DecodeSymbolDirectoryMessage(EncodeSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStatusMessage ==
    \A message \in CheckedSymbolStatusMessage :
        LET read == DecodeSymbolStatusMessage(EncodeSymbolStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Attributed Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddAttributedOrderMessage ==
    \A message \in CheckedAddAttributedOrderMessage :
        LET read == DecodeAddAttributedOrderMessage(EncodeAddAttributedOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Deleted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeletedMessage ==
    \A message \in CheckedOrderDeletedMessage :
        LET read == DecodeOrderDeletedMessage(EncodeOrderDeletedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedMessage ==
    \A message \in CheckedOrderModifiedMessage :
        LET read == DecodeOrderModifiedMessage(EncodeOrderModifiedMessage(message))
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

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed With Price Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceSizeMessage ==
    \A message \in CheckedOrderExecutedWithPriceSizeMessage :
        LET read == DecodeOrderExecutedWithPriceSizeMessage(EncodeOrderExecutedWithPriceSizeMessage(message))
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

(* Every Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradeMessage ==
    \A message \in CheckedAuctionTradeMessage :
        LET read == DecodeAuctionTradeMessage(EncodeAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Off Book Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOffBookTradeMessage ==
    \A message \in CheckedOffBookTradeMessage :
        LET read == DecodeOffBookTradeMessage(EncodeOffBookTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Recovery Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRecoveryTradeMessage ==
    \A message \in CheckedRecoveryTradeMessage :
        LET read == DecodeRecoveryTradeMessage(EncodeRecoveryTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionInfoMessage ==
    \A message \in CheckedAuctionInfoMessage :
        LET read == DecodeAuctionInfoMessage(EncodeAuctionInfoMessage(message))
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

(* Every Extended Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedStatisticsMessage ==
    \A message \in CheckedExtendedStatisticsMessage :
        LET read == DecodeExtendedStatisticsMessage(EncodeExtendedStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsMessage ==
    \A message \in CheckedNewsMessage :
        LET read == DecodeNewsMessage(EncodeNewsMessage(message))
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

(* Every Indicative Quote Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicativeQuoteInfoMessage ==
    \A message \in CheckedIndicativeQuoteInfoMessage :
        LET read == DecodeIndicativeQuoteInfoMessage(EncodeIndicativeQuoteInfoMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
