------------------ MODULE NairobiEquities_Snapshot_v1_22 -------------------
(***************************************************************************)
(* Nairobi Securities Exchange Nairobi Equities Snapshot v1.22             *)
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
(* Snapshot Request Message: 36 bytes                                      *)
(***************************************************************************)

SnapshotRequestMessage ==
    [ sequenceNumber  : Sample(4),
      segment         : Sample(6),
      symbol          : Sample(12),
      subBookFlags    : Sample(1),
      snapshotType    : Sample(1),
      recoverFromTime : Sample(8),
      requestId       : Sample(4) ]

EncodeSnapshotRequestMessage(message) ==
    message.sequenceNumber
        \o message.segment
        \o message.symbol
        \o message.subBookFlags
        \o message.snapshotType
        \o message.recoverFromTime
        \o message.requestId

DecodeSnapshotRequestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET segment == ReadBytes(sequenceNumber.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET symbol == ReadBytes(segment.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET subBookFlags == ReadBytes(symbol.rest, 1) IN IF ~subBookFlags.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(subBookFlags.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    LET recoverFromTime == ReadBytes(snapshotType.rest, 8) IN IF ~recoverFromTime.ok THEN Fail ELSE
    LET requestId == ReadBytes(recoverFromTime.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ sequenceNumber  |-> sequenceNumber.value,
         segment         |-> segment.value,
         symbol          |-> symbol.value,
         subBookFlags    |-> subBookFlags.value,
         snapshotType    |-> snapshotType.value,
         recoverFromTime |-> recoverFromTime.value,
         requestId       |-> requestId.value ], requestId.rest)

ZeroSnapshotRequestMessage ==
    [ sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      segment         |-> [i \in 1 .. 6 |-> 0],
      symbol          |-> [i \in 1 .. 12 |-> 0],
      subBookFlags    |-> [i \in 1 .. 1 |-> 0],
      snapshotType    |-> [i \in 1 .. 1 |-> 0],
      recoverFromTime |-> [i \in 1 .. 8 |-> 0],
      requestId       |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRequestMessage ==
    { ZeroSnapshotRequestMessage }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.subBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.recoverFromTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }

(***************************************************************************)
(* Snapshot Response Message: 14 bytes                                     *)
(***************************************************************************)

SnapshotResponseMessage ==
    [ sequenceNumber : Sample(4),
      orderCount     : Sample(4),
      snapshotStatus : Sample(1),
      snapshotType   : Sample(1),
      requestId      : Sample(4) ]

EncodeSnapshotResponseMessage(message) ==
    message.sequenceNumber
        \o message.orderCount
        \o message.snapshotStatus
        \o message.snapshotType
        \o message.requestId

DecodeSnapshotResponseMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET orderCount == ReadBytes(sequenceNumber.rest, 4) IN IF ~orderCount.ok THEN Fail ELSE
    LET snapshotStatus == ReadBytes(orderCount.rest, 1) IN IF ~snapshotStatus.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(snapshotStatus.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    LET requestId == ReadBytes(snapshotType.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         orderCount     |-> orderCount.value,
         snapshotStatus |-> snapshotStatus.value,
         snapshotType   |-> snapshotType.value,
         requestId      |-> requestId.value ], requestId.rest)

ZeroSnapshotResponseMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      orderCount     |-> [i \in 1 .. 4 |-> 0],
      snapshotStatus |-> [i \in 1 .. 1 |-> 0],
      snapshotType   |-> [i \in 1 .. 1 |-> 0],
      requestId      |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotResponseMessage ==
    { ZeroSnapshotResponseMessage }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.orderCount = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.snapshotStatus = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotResponseMessage EXCEPT !.requestId = one] : one \in Sample(4) }

(***************************************************************************)
(* Snapshot Complete Message: 29 bytes                                     *)
(***************************************************************************)

SnapshotCompleteMessage ==
    [ sequenceNumber : Sample(4),
      segment        : Sample(6),
      symbol         : Sample(12),
      subBookFlags   : Sample(1),
      tradingStatus  : Sample(1),
      snapshotType   : Sample(1),
      requestId      : Sample(4) ]

EncodeSnapshotCompleteMessage(message) ==
    message.sequenceNumber
        \o message.segment
        \o message.symbol
        \o message.subBookFlags
        \o message.tradingStatus
        \o message.snapshotType
        \o message.requestId

DecodeSnapshotCompleteMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET segment == ReadBytes(sequenceNumber.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET symbol == ReadBytes(segment.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET subBookFlags == ReadBytes(symbol.rest, 1) IN IF ~subBookFlags.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(subBookFlags.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET snapshotType == ReadBytes(tradingStatus.rest, 1) IN IF ~snapshotType.ok THEN Fail ELSE
    LET requestId == ReadBytes(snapshotType.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         segment        |-> segment.value,
         symbol         |-> symbol.value,
         subBookFlags   |-> subBookFlags.value,
         tradingStatus  |-> tradingStatus.value,
         snapshotType   |-> snapshotType.value,
         requestId      |-> requestId.value ], requestId.rest)

ZeroSnapshotCompleteMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      segment        |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 12 |-> 0],
      subBookFlags   |-> [i \in 1 .. 1 |-> 0],
      tradingStatus  |-> [i \in 1 .. 1 |-> 0],
      snapshotType   |-> [i \in 1 .. 1 |-> 0],
      requestId      |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotCompleteMessage ==
    { ZeroSnapshotCompleteMessage }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.subBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.snapshotType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.requestId = one] : one \in Sample(4) }

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
(* Symbol Directory Message: 87 bytes                                      *)
(***************************************************************************)

SymbolDirectoryMessage ==
    [ nanosecond           : Sample(4),
      symbol               : Sample(12),
      symbolStatus         : Sample(1),
      identificationNumber : Sample(12),
      segment              : Sample(6),
      expirationDate       : Sample(8),
      underlying           : Sample(6),
      strikePrice          : Sample(4),
      optionType           : Sample(1),
      issuer               : Sample(6),
      issueDate            : Sample(8),
      coupon               : Sample(4),
      symbolDirectoryFlags : Sample(1),
      subBookFlags         : Sample(1),
      corporateAction      : Sample(5),
      issuedQuantity       : Sample(8) ]

EncodeSymbolDirectoryMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.symbolStatus
        \o message.identificationNumber
        \o message.segment
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
        \o message.issuedQuantity

DecodeSymbolDirectoryMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolStatus == ReadBytes(symbol.rest, 1) IN IF ~symbolStatus.ok THEN Fail ELSE
    LET identificationNumber == ReadBytes(symbolStatus.rest, 12) IN IF ~identificationNumber.ok THEN Fail ELSE
    LET segment == ReadBytes(identificationNumber.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(segment.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET underlying == ReadBytes(expirationDate.rest, 6) IN IF ~underlying.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(underlying.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET issuer == ReadBytes(optionType.rest, 6) IN IF ~issuer.ok THEN Fail ELSE
    LET issueDate == ReadBytes(issuer.rest, 8) IN IF ~issueDate.ok THEN Fail ELSE
    LET coupon == ReadBytes(issueDate.rest, 4) IN IF ~coupon.ok THEN Fail ELSE
    LET symbolDirectoryFlags == ReadBytes(coupon.rest, 1) IN IF ~symbolDirectoryFlags.ok THEN Fail ELSE
    LET subBookFlags == ReadBytes(symbolDirectoryFlags.rest, 1) IN IF ~subBookFlags.ok THEN Fail ELSE
    LET corporateAction == ReadBytes(subBookFlags.rest, 5) IN IF ~corporateAction.ok THEN Fail ELSE
    LET issuedQuantity == ReadBytes(corporateAction.rest, 8) IN IF ~issuedQuantity.ok THEN Fail ELSE
    Ok([ nanosecond           |-> nanosecond.value,
         symbol               |-> symbol.value,
         symbolStatus         |-> symbolStatus.value,
         identificationNumber |-> identificationNumber.value,
         segment              |-> segment.value,
         expirationDate       |-> expirationDate.value,
         underlying           |-> underlying.value,
         strikePrice          |-> strikePrice.value,
         optionType           |-> optionType.value,
         issuer               |-> issuer.value,
         issueDate            |-> issueDate.value,
         coupon               |-> coupon.value,
         symbolDirectoryFlags |-> symbolDirectoryFlags.value,
         subBookFlags         |-> subBookFlags.value,
         corporateAction      |-> corporateAction.value,
         issuedQuantity       |-> issuedQuantity.value ], issuedQuantity.rest)

ZeroSymbolDirectoryMessage ==
    [ nanosecond           |-> [i \in 1 .. 4 |-> 0],
      symbol               |-> [i \in 1 .. 12 |-> 0],
      symbolStatus         |-> [i \in 1 .. 1 |-> 0],
      identificationNumber |-> [i \in 1 .. 12 |-> 0],
      segment              |-> [i \in 1 .. 6 |-> 0],
      expirationDate       |-> [i \in 1 .. 8 |-> 0],
      underlying           |-> [i \in 1 .. 6 |-> 0],
      strikePrice          |-> [i \in 1 .. 4 |-> 0],
      optionType           |-> [i \in 1 .. 1 |-> 0],
      issuer               |-> [i \in 1 .. 6 |-> 0],
      issueDate            |-> [i \in 1 .. 8 |-> 0],
      coupon               |-> [i \in 1 .. 4 |-> 0],
      symbolDirectoryFlags |-> [i \in 1 .. 1 |-> 0],
      subBookFlags         |-> [i \in 1 .. 1 |-> 0],
      corporateAction      |-> [i \in 1 .. 5 |-> 0],
      issuedQuantity       |-> [i \in 1 .. 8 |-> 0] ]

(* Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolDirectoryMessage ==
    { ZeroSymbolDirectoryMessage }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbolStatus = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.identificationNumber = one] : one \in Sample(12) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.underlying = one] : one \in Sample(6) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.issuer = one] : one \in Sample(6) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.issueDate = one] : one \in Sample(8) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.coupon = one] : one \in Sample(4) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.symbolDirectoryFlags = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.subBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.corporateAction = one] : one \in Sample(5) }
        \cup { [ZeroSymbolDirectoryMessage EXCEPT !.issuedQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Symbol Status Message: 32 bytes                                         *)
(***************************************************************************)

SymbolStatusMessage ==
    [ nanosecond          : Sample(4),
      symbol              : Sample(12),
      tradingStatus       : Sample(1),
      symbolStatusFlags   : Sample(1),
      haltReason          : Sample(4),
      sessionChangeReason : Sample(1),
      newEndTime          : Sample(8),
      subBook             : Sample(1) ]

EncodeSymbolStatusMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.tradingStatus
        \o message.symbolStatusFlags
        \o message.haltReason
        \o message.sessionChangeReason
        \o message.newEndTime
        \o message.subBook

DecodeSymbolStatusMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(symbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET symbolStatusFlags == ReadBytes(tradingStatus.rest, 1) IN IF ~symbolStatusFlags.ok THEN Fail ELSE
    LET haltReason == ReadBytes(symbolStatusFlags.rest, 4) IN IF ~haltReason.ok THEN Fail ELSE
    LET sessionChangeReason == ReadBytes(haltReason.rest, 1) IN IF ~sessionChangeReason.ok THEN Fail ELSE
    LET newEndTime == ReadBytes(sessionChangeReason.rest, 8) IN IF ~newEndTime.ok THEN Fail ELSE
    LET subBook == ReadBytes(newEndTime.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    Ok([ nanosecond          |-> nanosecond.value,
         symbol              |-> symbol.value,
         tradingStatus       |-> tradingStatus.value,
         symbolStatusFlags   |-> symbolStatusFlags.value,
         haltReason          |-> haltReason.value,
         sessionChangeReason |-> sessionChangeReason.value,
         newEndTime          |-> newEndTime.value,
         subBook             |-> subBook.value ], subBook.rest)

ZeroSymbolStatusMessage ==
    [ nanosecond          |-> [i \in 1 .. 4 |-> 0],
      symbol              |-> [i \in 1 .. 12 |-> 0],
      tradingStatus       |-> [i \in 1 .. 1 |-> 0],
      symbolStatusFlags   |-> [i \in 1 .. 1 |-> 0],
      haltReason          |-> [i \in 1 .. 4 |-> 0],
      sessionChangeReason |-> [i \in 1 .. 1 |-> 0],
      newEndTime          |-> [i \in 1 .. 8 |-> 0],
      subBook             |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStatusMessage ==
    { ZeroSymbolStatusMessage }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.symbolStatusFlags = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.haltReason = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.sessionChangeReason = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.newEndTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.subBook = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 41 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ nanosecond     : Sample(4),
      orderId        : Sample(8),
      side           : Sample(1),
      quantity       : Sample(4),
      symbol         : Sample(12),
      price          : Sample(4),
      addOrderFlags  : Sample(1),
      subBook        : Sample(1),
      settlementType : Sample(1),
      interestRate   : Sample(4),
      term           : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.addOrderFlags
        \o message.subBook
        \o message.settlementType
        \o message.interestRate
        \o message.term

DecodeAddOrderMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET addOrderFlags == ReadBytes(price.rest, 1) IN IF ~addOrderFlags.ok THEN Fail ELSE
    LET subBook == ReadBytes(addOrderFlags.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET settlementType == ReadBytes(subBook.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET interestRate == ReadBytes(settlementType.rest, 4) IN IF ~interestRate.ok THEN Fail ELSE
    LET term == ReadBytes(interestRate.rest, 1) IN IF ~term.ok THEN Fail ELSE
    Ok([ nanosecond     |-> nanosecond.value,
         orderId        |-> orderId.value,
         side           |-> side.value,
         quantity       |-> quantity.value,
         symbol         |-> symbol.value,
         price          |-> price.value,
         addOrderFlags  |-> addOrderFlags.value,
         subBook        |-> subBook.value,
         settlementType |-> settlementType.value,
         interestRate   |-> interestRate.value,
         term           |-> term.value ], term.rest)

ZeroAddOrderMessage ==
    [ nanosecond     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0],
      symbol         |-> [i \in 1 .. 12 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      addOrderFlags  |-> [i \in 1 .. 1 |-> 0],
      subBook        |-> [i \in 1 .. 1 |-> 0],
      settlementType |-> [i \in 1 .. 1 |-> 0],
      interestRate   |-> [i \in 1 .. 4 |-> 0],
      term           |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.addOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.interestRate = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.term = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Attributed Order Message: 41 bytes                                  *)
(***************************************************************************)

AddAttributedOrderMessage ==
    [ nanosecond              : Sample(4),
      orderId                 : Sample(8),
      side                    : Sample(1),
      quantity                : Sample(4),
      symbol                  : Sample(12),
      price                   : Sample(4),
      attribution             : Sample(6),
      addAttributedOrderFlags : Sample(1),
      subBook                 : Sample(1) ]

EncodeAddAttributedOrderMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.attribution
        \o message.addAttributedOrderFlags
        \o message.subBook

DecodeAddAttributedOrderMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET attribution == ReadBytes(price.rest, 6) IN IF ~attribution.ok THEN Fail ELSE
    LET addAttributedOrderFlags == ReadBytes(attribution.rest, 1) IN IF ~addAttributedOrderFlags.ok THEN Fail ELSE
    LET subBook == ReadBytes(addAttributedOrderFlags.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    Ok([ nanosecond              |-> nanosecond.value,
         orderId                 |-> orderId.value,
         side                    |-> side.value,
         quantity                |-> quantity.value,
         symbol                  |-> symbol.value,
         price                   |-> price.value,
         attribution             |-> attribution.value,
         addAttributedOrderFlags |-> addAttributedOrderFlags.value,
         subBook                 |-> subBook.value ], subBook.rest)

ZeroAddAttributedOrderMessage ==
    [ nanosecond              |-> [i \in 1 .. 4 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      quantity                |-> [i \in 1 .. 4 |-> 0],
      symbol                  |-> [i \in 1 .. 12 |-> 0],
      price                   |-> [i \in 1 .. 4 |-> 0],
      attribution             |-> [i \in 1 .. 6 |-> 0],
      addAttributedOrderFlags |-> [i \in 1 .. 1 |-> 0],
      subBook                 |-> [i \in 1 .. 1 |-> 0] ]

(* Add Attributed Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddAttributedOrderMessage ==
    { ZeroAddAttributedOrderMessage }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.attribution = one] : one \in Sample(6) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.addAttributedOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroAddAttributedOrderMessage EXCEPT !.subBook = one] : one \in Sample(1) }

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
(* Order Modified Message: 27 bytes                                        *)
(***************************************************************************)

OrderModifiedMessage ==
    [ nanosecond         : Sample(4),
      orderId            : Sample(8),
      newQuantity        : Sample(4),
      newPrice           : Sample(4),
      orderModifiedFlags : Sample(1),
      settlementType     : Sample(1),
      interestRate       : Sample(4),
      term               : Sample(1) ]

EncodeOrderModifiedMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.newQuantity
        \o message.newPrice
        \o message.orderModifiedFlags
        \o message.settlementType
        \o message.interestRate
        \o message.term

DecodeOrderModifiedMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET newQuantity == ReadBytes(orderId.rest, 4) IN IF ~newQuantity.ok THEN Fail ELSE
    LET newPrice == ReadBytes(newQuantity.rest, 4) IN IF ~newPrice.ok THEN Fail ELSE
    LET orderModifiedFlags == ReadBytes(newPrice.rest, 1) IN IF ~orderModifiedFlags.ok THEN Fail ELSE
    LET settlementType == ReadBytes(orderModifiedFlags.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET interestRate == ReadBytes(settlementType.rest, 4) IN IF ~interestRate.ok THEN Fail ELSE
    LET term == ReadBytes(interestRate.rest, 1) IN IF ~term.ok THEN Fail ELSE
    Ok([ nanosecond         |-> nanosecond.value,
         orderId            |-> orderId.value,
         newQuantity        |-> newQuantity.value,
         newPrice           |-> newPrice.value,
         orderModifiedFlags |-> orderModifiedFlags.value,
         settlementType     |-> settlementType.value,
         interestRate       |-> interestRate.value,
         term               |-> term.value ], term.rest)

ZeroOrderModifiedMessage ==
    [ nanosecond         |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      newQuantity        |-> [i \in 1 .. 4 |-> 0],
      newPrice           |-> [i \in 1 .. 4 |-> 0],
      orderModifiedFlags |-> [i \in 1 .. 1 |-> 0],
      settlementType     |-> [i \in 1 .. 1 |-> 0],
      interestRate       |-> [i \in 1 .. 4 |-> 0],
      term               |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.newQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.newPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderModifiedFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.interestRate = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.term = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Clear Message: 18 bytes                                      *)
(***************************************************************************)

OrderBookClearMessage ==
    [ nanosecond : Sample(4),
      symbol     : Sample(12),
      subBook    : Sample(1),
      bookType   : Sample(1) ]

EncodeOrderBookClearMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.subBook
        \o message.bookType

DecodeOrderBookClearMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET subBook == ReadBytes(symbol.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET bookType == ReadBytes(subBook.rest, 1) IN IF ~bookType.ok THEN Fail ELSE
    Ok([ nanosecond |-> nanosecond.value,
         symbol     |-> symbol.value,
         subBook    |-> subBook.value,
         bookType   |-> bookType.value ], bookType.rest)

ZeroOrderBookClearMessage ==
    [ nanosecond |-> [i \in 1 .. 4 |-> 0],
      symbol     |-> [i \in 1 .. 12 |-> 0],
      subBook    |-> [i \in 1 .. 1 |-> 0],
      bookType   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookClearMessage ==
    { ZeroOrderBookClearMessage }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.bookType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 60 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanosecond               : Sample(4),
      orderId                  : Sample(8),
      executedQuantity         : Sample(4),
      tradeId                  : Sample(8),
      buyFirm                  : Sample(6),
      sellFirm                 : Sample(6),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.executedQuantity
        \o message.tradeId
        \o message.buyFirm
        \o message.sellFirm
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice

DecodeOrderExecutedMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(executedQuantity.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET buyFirm == ReadBytes(tradeId.rest, 6) IN IF ~buyFirm.ok THEN Fail ELSE
    LET sellFirm == ReadBytes(buyFirm.rest, 6) IN IF ~sellFirm.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(sellFirm.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         orderId                  |-> orderId.value,
         executedQuantity         |-> executedQuantity.value,
         tradeId                  |-> tradeId.value,
         buyFirm                  |-> buyFirm.value,
         sellFirm                 |-> sellFirm.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value ], underlyingReferencePrice.rest)

ZeroOrderExecutedMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      buyFirm                  |-> [i \in 1 .. 6 |-> 0],
      sellFirm                 |-> [i \in 1 .. 6 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.buyFirm = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.sellFirm = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed With Price Size Message: 69 bytes                        *)
(***************************************************************************)

OrderExecutedWithPriceSizeMessage ==
    [ nanosecond               : Sample(4),
      orderId                  : Sample(8),
      executedQuantity         : Sample(4),
      displayQuantity          : Sample(4),
      tradeId                  : Sample(8),
      printable                : Sample(1),
      price                    : Sample(4),
      buyFirm                  : Sample(6),
      sellFirm                 : Sample(6),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8) ]

EncodeOrderExecutedWithPriceSizeMessage(message) ==
    message.nanosecond
        \o message.orderId
        \o message.executedQuantity
        \o message.displayQuantity
        \o message.tradeId
        \o message.printable
        \o message.price
        \o message.buyFirm
        \o message.sellFirm
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice

DecodeOrderExecutedWithPriceSizeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanosecond.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET displayQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~displayQuantity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(displayQuantity.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET printable == ReadBytes(tradeId.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET price == ReadBytes(printable.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET buyFirm == ReadBytes(price.rest, 6) IN IF ~buyFirm.ok THEN Fail ELSE
    LET sellFirm == ReadBytes(buyFirm.rest, 6) IN IF ~sellFirm.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(sellFirm.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         orderId                  |-> orderId.value,
         executedQuantity         |-> executedQuantity.value,
         displayQuantity          |-> displayQuantity.value,
         tradeId                  |-> tradeId.value,
         printable                |-> printable.value,
         price                    |-> price.value,
         buyFirm                  |-> buyFirm.value,
         sellFirm                 |-> sellFirm.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value ], underlyingReferencePrice.rest)

ZeroOrderExecutedWithPriceSizeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      displayQuantity          |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      printable                |-> [i \in 1 .. 1 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      buyFirm                  |-> [i \in 1 .. 6 |-> 0],
      sellFirm                 |-> [i \in 1 .. 6 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed With Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceSizeMessage ==
    { ZeroOrderExecutedWithPriceSizeMessage }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.displayQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.buyFirm = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.sellFirm = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceSizeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 69 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ nanosecond               : Sample(4),
      executedQuantity         : Sample(4),
      symbol                   : Sample(12),
      price                    : Sample(4),
      tradeId                  : Sample(8),
      subBook                  : Sample(1),
      buyFirm                  : Sample(6),
      sellFirm                 : Sample(6),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8) ]

EncodeTradeMessage(message) ==
    message.nanosecond
        \o message.executedQuantity
        \o message.symbol
        \o message.price
        \o message.tradeId
        \o message.subBook
        \o message.buyFirm
        \o message.sellFirm
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice

DecodeTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(executedQuantity.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET subBook == ReadBytes(tradeId.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET buyFirm == ReadBytes(subBook.rest, 6) IN IF ~buyFirm.ok THEN Fail ELSE
    LET sellFirm == ReadBytes(buyFirm.rest, 6) IN IF ~sellFirm.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(sellFirm.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         executedQuantity         |-> executedQuantity.value,
         symbol                   |-> symbol.value,
         price                    |-> price.value,
         tradeId                  |-> tradeId.value,
         subBook                  |-> subBook.value,
         buyFirm                  |-> buyFirm.value,
         sellFirm                 |-> sellFirm.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value ], underlyingReferencePrice.rest)

ZeroTradeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      symbol                   |-> [i \in 1 .. 12 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      subBook                  |-> [i \in 1 .. 1 |-> 0],
      buyFirm                  |-> [i \in 1 .. 6 |-> 0],
      sellFirm                 |-> [i \in 1 .. 6 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.buyFirm = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.sellFirm = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Trade Message: 57 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ nanosecond               : Sample(4),
      executedQuantity         : Sample(4),
      symbol                   : Sample(12),
      price                    : Sample(4),
      tradeId                  : Sample(8),
      auctionType              : Sample(1),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8) ]

EncodeAuctionTradeMessage(message) ==
    message.nanosecond
        \o message.executedQuantity
        \o message.symbol
        \o message.price
        \o message.tradeId
        \o message.auctionType
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice

DecodeAuctionTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(executedQuantity.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(tradeId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(auctionType.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         executedQuantity         |-> executedQuantity.value,
         symbol                   |-> symbol.value,
         price                    |-> price.value,
         tradeId                  |-> tradeId.value,
         auctionType              |-> auctionType.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value ], underlyingReferencePrice.rest)

ZeroAuctionTradeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      symbol                   |-> [i \in 1 .. 12 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      auctionType              |-> [i \in 1 .. 1 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Off Book Trade Message: 76 bytes                                        *)
(***************************************************************************)

OffBookTradeMessage ==
    [ nanosecond               : Sample(4),
      executedQuantity         : Sample(4),
      symbol                   : Sample(12),
      price                    : Sample(4),
      tradeId                  : Sample(8),
      offBookTradeType         : Sample(4),
      tradeTime                : Sample(8),
      tradeDate                : Sample(8),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8) ]

EncodeOffBookTradeMessage(message) ==
    message.nanosecond
        \o message.executedQuantity
        \o message.symbol
        \o message.price
        \o message.tradeId
        \o message.offBookTradeType
        \o message.tradeTime
        \o message.tradeDate
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice

DecodeOffBookTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(executedQuantity.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET offBookTradeType == ReadBytes(tradeId.rest, 4) IN IF ~offBookTradeType.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(offBookTradeType.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradeTime.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(tradeDate.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         executedQuantity         |-> executedQuantity.value,
         symbol                   |-> symbol.value,
         price                    |-> price.value,
         tradeId                  |-> tradeId.value,
         offBookTradeType         |-> offBookTradeType.value,
         tradeTime                |-> tradeTime.value,
         tradeDate                |-> tradeDate.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value ], underlyingReferencePrice.rest)

ZeroOffBookTradeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      symbol                   |-> [i \in 1 .. 12 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      offBookTradeType         |-> [i \in 1 .. 4 |-> 0],
      tradeTime                |-> [i \in 1 .. 8 |-> 0],
      tradeDate                |-> [i \in 1 .. 8 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Off Book Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOffBookTradeMessage ==
    { ZeroOffBookTradeMessage }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.offBookTradeType = one] : one \in Sample(4) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroOffBookTradeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Break Message: 13 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ nanosecond : Sample(4),
      tradeId    : Sample(8),
      tradeType  : Sample(1) ]

EncodeTradeBreakMessage(message) ==
    message.nanosecond
        \o message.tradeId
        \o message.tradeType

DecodeTradeBreakMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET tradeId == ReadBytes(nanosecond.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradeId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    Ok([ nanosecond |-> nanosecond.value,
         tradeId    |-> tradeId.value,
         tradeType  |-> tradeType.value ], tradeType.rest)

ZeroTradeBreakMessage ==
    [ nanosecond |-> [i \in 1 .. 4 |-> 0],
      tradeId    |-> [i \in 1 .. 8 |-> 0],
      tradeType  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.tradeType = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correction Message: 45 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ nanosecond : Sample(4),
      tradeId    : Sample(8),
      symbol     : Sample(12),
      price      : Sample(4),
      quantity   : Sample(4),
      subBook    : Sample(1),
      buyFirm    : Sample(6),
      sellFirm   : Sample(6) ]

EncodeTradeCorrectionMessage(message) ==
    message.nanosecond
        \o message.tradeId
        \o message.symbol
        \o message.price
        \o message.quantity
        \o message.subBook
        \o message.buyFirm
        \o message.sellFirm

DecodeTradeCorrectionMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET tradeId == ReadBytes(nanosecond.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(tradeId.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET subBook == ReadBytes(quantity.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET buyFirm == ReadBytes(subBook.rest, 6) IN IF ~buyFirm.ok THEN Fail ELSE
    LET sellFirm == ReadBytes(buyFirm.rest, 6) IN IF ~sellFirm.ok THEN Fail ELSE
    Ok([ nanosecond |-> nanosecond.value,
         tradeId    |-> tradeId.value,
         symbol     |-> symbol.value,
         price      |-> price.value,
         quantity   |-> quantity.value,
         subBook    |-> subBook.value,
         buyFirm    |-> buyFirm.value,
         sellFirm   |-> sellFirm.value ], sellFirm.rest)

ZeroTradeCorrectionMessage ==
    [ nanosecond |-> [i \in 1 .. 4 |-> 0],
      tradeId    |-> [i \in 1 .. 8 |-> 0],
      symbol     |-> [i \in 1 .. 12 |-> 0],
      price      |-> [i \in 1 .. 4 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      subBook    |-> [i \in 1 .. 1 |-> 0],
      buyFirm    |-> [i \in 1 .. 6 |-> 0],
      sellFirm   |-> [i \in 1 .. 6 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.buyFirm = one] : one \in Sample(6) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.sellFirm = one] : one \in Sample(6) }

(***************************************************************************)
(* Recovery Trade Message: 92 bytes                                        *)
(***************************************************************************)

RecoveryTradeMessage ==
    [ nanosecond               : Sample(4),
      executedQuantity         : Sample(4),
      symbol                   : Sample(12),
      price                    : Sample(4),
      tradeId                  : Sample(8),
      auctionType              : Sample(1),
      offBookTradeType         : Sample(4),
      tradeTime                : Sample(8),
      tradeDate                : Sample(8),
      actionType               : Sample(1),
      subBook                  : Sample(1),
      buyFirm                  : Sample(6),
      sellFirm                 : Sample(6),
      lastOptPx                : Sample(8),
      volatility               : Sample(8),
      underlyingReferencePrice : Sample(8),
      auctionTradeType         : Sample(1) ]

EncodeRecoveryTradeMessage(message) ==
    message.nanosecond
        \o message.executedQuantity
        \o message.symbol
        \o message.price
        \o message.tradeId
        \o message.auctionType
        \o message.offBookTradeType
        \o message.tradeTime
        \o message.tradeDate
        \o message.actionType
        \o message.subBook
        \o message.buyFirm
        \o message.sellFirm
        \o message.lastOptPx
        \o message.volatility
        \o message.underlyingReferencePrice
        \o message.auctionTradeType

DecodeRecoveryTradeMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(executedQuantity.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(tradeId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET offBookTradeType == ReadBytes(auctionType.rest, 4) IN IF ~offBookTradeType.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(offBookTradeType.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradeTime.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET actionType == ReadBytes(tradeDate.rest, 1) IN IF ~actionType.ok THEN Fail ELSE
    LET subBook == ReadBytes(actionType.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET buyFirm == ReadBytes(subBook.rest, 6) IN IF ~buyFirm.ok THEN Fail ELSE
    LET sellFirm == ReadBytes(buyFirm.rest, 6) IN IF ~sellFirm.ok THEN Fail ELSE
    LET lastOptPx == ReadBytes(sellFirm.rest, 8) IN IF ~lastOptPx.ok THEN Fail ELSE
    LET volatility == ReadBytes(lastOptPx.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET underlyingReferencePrice == ReadBytes(volatility.rest, 8) IN IF ~underlyingReferencePrice.ok THEN Fail ELSE
    LET auctionTradeType == ReadBytes(underlyingReferencePrice.rest, 1) IN IF ~auctionTradeType.ok THEN Fail ELSE
    Ok([ nanosecond               |-> nanosecond.value,
         executedQuantity         |-> executedQuantity.value,
         symbol                   |-> symbol.value,
         price                    |-> price.value,
         tradeId                  |-> tradeId.value,
         auctionType              |-> auctionType.value,
         offBookTradeType         |-> offBookTradeType.value,
         tradeTime                |-> tradeTime.value,
         tradeDate                |-> tradeDate.value,
         actionType               |-> actionType.value,
         subBook                  |-> subBook.value,
         buyFirm                  |-> buyFirm.value,
         sellFirm                 |-> sellFirm.value,
         lastOptPx                |-> lastOptPx.value,
         volatility               |-> volatility.value,
         underlyingReferencePrice |-> underlyingReferencePrice.value,
         auctionTradeType         |-> auctionTradeType.value ], auctionTradeType.rest)

ZeroRecoveryTradeMessage ==
    [ nanosecond               |-> [i \in 1 .. 4 |-> 0],
      executedQuantity         |-> [i \in 1 .. 4 |-> 0],
      symbol                   |-> [i \in 1 .. 12 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      auctionType              |-> [i \in 1 .. 1 |-> 0],
      offBookTradeType         |-> [i \in 1 .. 4 |-> 0],
      tradeTime                |-> [i \in 1 .. 8 |-> 0],
      tradeDate                |-> [i \in 1 .. 8 |-> 0],
      actionType               |-> [i \in 1 .. 1 |-> 0],
      subBook                  |-> [i \in 1 .. 1 |-> 0],
      buyFirm                  |-> [i \in 1 .. 6 |-> 0],
      sellFirm                 |-> [i \in 1 .. 6 |-> 0],
      lastOptPx                |-> [i \in 1 .. 8 |-> 0],
      volatility               |-> [i \in 1 .. 8 |-> 0],
      underlyingReferencePrice |-> [i \in 1 .. 8 |-> 0],
      auctionTradeType         |-> [i \in 1 .. 1 |-> 0] ]

(* Recovery Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedRecoveryTradeMessage ==
    { ZeroRecoveryTradeMessage }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.offBookTradeType = one] : one \in Sample(4) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.actionType = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.buyFirm = one] : one \in Sample(6) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.sellFirm = one] : one \in Sample(6) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.lastOptPx = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.underlyingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroRecoveryTradeMessage EXCEPT !.auctionTradeType = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Info Message: 30 bytes                                          *)
(***************************************************************************)

AuctionInfoMessage ==
    [ nanosecond         : Sample(4),
      pairedQuantity     : Sample(4),
      imbalanceQuantity  : Sample(4),
      imbalanceDirection : Sample(1),
      symbol             : Sample(12),
      price              : Sample(4),
      auctionType        : Sample(1) ]

EncodeAuctionInfoMessage(message) ==
    message.nanosecond
        \o message.pairedQuantity
        \o message.imbalanceQuantity
        \o message.imbalanceDirection
        \o message.symbol
        \o message.price
        \o message.auctionType

DecodeAuctionInfoMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET pairedQuantity == ReadBytes(nanosecond.rest, 4) IN IF ~pairedQuantity.ok THEN Fail ELSE
    LET imbalanceQuantity == ReadBytes(pairedQuantity.rest, 4) IN IF ~imbalanceQuantity.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(imbalanceQuantity.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET symbol == ReadBytes(imbalanceDirection.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET auctionType == ReadBytes(price.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    Ok([ nanosecond         |-> nanosecond.value,
         pairedQuantity     |-> pairedQuantity.value,
         imbalanceQuantity  |-> imbalanceQuantity.value,
         imbalanceDirection |-> imbalanceDirection.value,
         symbol             |-> symbol.value,
         price              |-> price.value,
         auctionType        |-> auctionType.value ], auctionType.rest)

ZeroAuctionInfoMessage ==
    [ nanosecond         |-> [i \in 1 .. 4 |-> 0],
      pairedQuantity     |-> [i \in 1 .. 4 |-> 0],
      imbalanceQuantity  |-> [i \in 1 .. 4 |-> 0],
      imbalanceDirection |-> [i \in 1 .. 1 |-> 0],
      symbol             |-> [i \in 1 .. 12 |-> 0],
      price              |-> [i \in 1 .. 4 |-> 0],
      auctionType        |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Info Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionInfoMessage ==
    { ZeroAuctionInfoMessage }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.pairedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.imbalanceQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInfoMessage EXCEPT !.auctionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Statistics Message: 23 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ nanosecond         : Sample(4),
      symbol             : Sample(12),
      statisticType      : Sample(1),
      price              : Sample(4),
      openCloseIndicator : Sample(1),
      subBook            : Sample(1) ]

EncodeStatisticsMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.statisticType
        \o message.price
        \o message.openCloseIndicator
        \o message.subBook

DecodeStatisticsMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET statisticType == ReadBytes(symbol.rest, 1) IN IF ~statisticType.ok THEN Fail ELSE
    LET price == ReadBytes(statisticType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET openCloseIndicator == ReadBytes(price.rest, 1) IN IF ~openCloseIndicator.ok THEN Fail ELSE
    LET subBook == ReadBytes(openCloseIndicator.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    Ok([ nanosecond         |-> nanosecond.value,
         symbol             |-> symbol.value,
         statisticType      |-> statisticType.value,
         price              |-> price.value,
         openCloseIndicator |-> openCloseIndicator.value,
         subBook            |-> subBook.value ], subBook.rest)

ZeroStatisticsMessage ==
    [ nanosecond         |-> [i \in 1 .. 4 |-> 0],
      symbol             |-> [i \in 1 .. 12 |-> 0],
      statisticType      |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 4 |-> 0],
      openCloseIndicator |-> [i \in 1 .. 1 |-> 0],
      subBook            |-> [i \in 1 .. 1 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroStatisticsMessage EXCEPT !.statisticType = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.openCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.subBook = one] : one \in Sample(1) }

(***************************************************************************)
(* Extended Statistics Message: 93 bytes                                   *)
(***************************************************************************)

ExtendedStatisticsMessage ==
    [ nanosecond            : Sample(4),
      symbol                : Sample(12),
      highPrice             : Sample(4),
      lowPrice              : Sample(4),
      vwap                  : Sample(4),
      volume                : Sample(4),
      turnover              : Sample(8),
      trades                : Sample(4),
      reserved8             : Sample(8),
      subBook               : Sample(1),
      notionalExposure      : Sample(8),
      notionalDeltaExposure : Sample(8),
      dailyForeignBuyValue  : Sample(8),
      dailyForeignSellValue : Sample(8),
      marketCapitalization  : Sample(8) ]

EncodeExtendedStatisticsMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.highPrice
        \o message.lowPrice
        \o message.vwap
        \o message.volume
        \o message.turnover
        \o message.trades
        \o message.reserved8
        \o message.subBook
        \o message.notionalExposure
        \o message.notionalDeltaExposure
        \o message.dailyForeignBuyValue
        \o message.dailyForeignSellValue
        \o message.marketCapitalization

DecodeExtendedStatisticsMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET highPrice == ReadBytes(symbol.rest, 4) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 4) IN IF ~lowPrice.ok THEN Fail ELSE
    LET vwap == ReadBytes(lowPrice.rest, 4) IN IF ~vwap.ok THEN Fail ELSE
    LET volume == ReadBytes(vwap.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET turnover == ReadBytes(volume.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET trades == ReadBytes(turnover.rest, 4) IN IF ~trades.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(trades.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET subBook == ReadBytes(reserved8.rest, 1) IN IF ~subBook.ok THEN Fail ELSE
    LET notionalExposure == ReadBytes(subBook.rest, 8) IN IF ~notionalExposure.ok THEN Fail ELSE
    LET notionalDeltaExposure == ReadBytes(notionalExposure.rest, 8) IN IF ~notionalDeltaExposure.ok THEN Fail ELSE
    LET dailyForeignBuyValue == ReadBytes(notionalDeltaExposure.rest, 8) IN IF ~dailyForeignBuyValue.ok THEN Fail ELSE
    LET dailyForeignSellValue == ReadBytes(dailyForeignBuyValue.rest, 8) IN IF ~dailyForeignSellValue.ok THEN Fail ELSE
    LET marketCapitalization == ReadBytes(dailyForeignSellValue.rest, 8) IN IF ~marketCapitalization.ok THEN Fail ELSE
    Ok([ nanosecond            |-> nanosecond.value,
         symbol                |-> symbol.value,
         highPrice             |-> highPrice.value,
         lowPrice              |-> lowPrice.value,
         vwap                  |-> vwap.value,
         volume                |-> volume.value,
         turnover              |-> turnover.value,
         trades                |-> trades.value,
         reserved8             |-> reserved8.value,
         subBook               |-> subBook.value,
         notionalExposure      |-> notionalExposure.value,
         notionalDeltaExposure |-> notionalDeltaExposure.value,
         dailyForeignBuyValue  |-> dailyForeignBuyValue.value,
         dailyForeignSellValue |-> dailyForeignSellValue.value,
         marketCapitalization  |-> marketCapitalization.value ], marketCapitalization.rest)

ZeroExtendedStatisticsMessage ==
    [ nanosecond            |-> [i \in 1 .. 4 |-> 0],
      symbol                |-> [i \in 1 .. 12 |-> 0],
      highPrice             |-> [i \in 1 .. 4 |-> 0],
      lowPrice              |-> [i \in 1 .. 4 |-> 0],
      vwap                  |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      turnover              |-> [i \in 1 .. 8 |-> 0],
      trades                |-> [i \in 1 .. 4 |-> 0],
      reserved8             |-> [i \in 1 .. 8 |-> 0],
      subBook               |-> [i \in 1 .. 1 |-> 0],
      notionalExposure      |-> [i \in 1 .. 8 |-> 0],
      notionalDeltaExposure |-> [i \in 1 .. 8 |-> 0],
      dailyForeignBuyValue  |-> [i \in 1 .. 8 |-> 0],
      dailyForeignSellValue |-> [i \in 1 .. 8 |-> 0],
      marketCapitalization  |-> [i \in 1 .. 8 |-> 0] ]

(* Extended Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedStatisticsMessage ==
    { ZeroExtendedStatisticsMessage }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.highPrice = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.lowPrice = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.vwap = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.trades = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.subBook = one] : one \in Sample(1) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.notionalExposure = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.notionalDeltaExposure = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.dailyForeignBuyValue = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.dailyForeignSellValue = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStatisticsMessage EXCEPT !.marketCapitalization = one] : one \in Sample(8) }

(***************************************************************************)
(* Consolidated Statistics Message: 57 bytes                               *)
(***************************************************************************)

ConsolidatedStatisticsMessage ==
    [ nanosecond            : Sample(4),
      statisticsType        : Sample(1),
      symbol                : Sample(12),
      volume                : Sample(4),
      turnover              : Sample(8),
      trades                : Sample(4),
      dailyForeignBuyValue  : Sample(8),
      dailyForeignSellValue : Sample(8),
      marketCapitalization  : Sample(8) ]

EncodeConsolidatedStatisticsMessage(message) ==
    message.nanosecond
        \o message.statisticsType
        \o message.symbol
        \o message.volume
        \o message.turnover
        \o message.trades
        \o message.dailyForeignBuyValue
        \o message.dailyForeignSellValue
        \o message.marketCapitalization

DecodeConsolidatedStatisticsMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET statisticsType == ReadBytes(nanosecond.rest, 1) IN IF ~statisticsType.ok THEN Fail ELSE
    LET symbol == ReadBytes(statisticsType.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET turnover == ReadBytes(volume.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET trades == ReadBytes(turnover.rest, 4) IN IF ~trades.ok THEN Fail ELSE
    LET dailyForeignBuyValue == ReadBytes(trades.rest, 8) IN IF ~dailyForeignBuyValue.ok THEN Fail ELSE
    LET dailyForeignSellValue == ReadBytes(dailyForeignBuyValue.rest, 8) IN IF ~dailyForeignSellValue.ok THEN Fail ELSE
    LET marketCapitalization == ReadBytes(dailyForeignSellValue.rest, 8) IN IF ~marketCapitalization.ok THEN Fail ELSE
    Ok([ nanosecond            |-> nanosecond.value,
         statisticsType        |-> statisticsType.value,
         symbol                |-> symbol.value,
         volume                |-> volume.value,
         turnover              |-> turnover.value,
         trades                |-> trades.value,
         dailyForeignBuyValue  |-> dailyForeignBuyValue.value,
         dailyForeignSellValue |-> dailyForeignSellValue.value,
         marketCapitalization  |-> marketCapitalization.value ], marketCapitalization.rest)

ZeroConsolidatedStatisticsMessage ==
    [ nanosecond            |-> [i \in 1 .. 4 |-> 0],
      statisticsType        |-> [i \in 1 .. 1 |-> 0],
      symbol                |-> [i \in 1 .. 12 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      turnover              |-> [i \in 1 .. 8 |-> 0],
      trades                |-> [i \in 1 .. 4 |-> 0],
      dailyForeignBuyValue  |-> [i \in 1 .. 8 |-> 0],
      dailyForeignSellValue |-> [i \in 1 .. 8 |-> 0],
      marketCapitalization  |-> [i \in 1 .. 8 |-> 0] ]

(* Consolidated Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedStatisticsMessage ==
    { ZeroConsolidatedStatisticsMessage }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.statisticsType = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.trades = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.dailyForeignBuyValue = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.dailyForeignSellValue = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedStatisticsMessage EXCEPT !.marketCapitalization = one] : one \in Sample(8) }

(***************************************************************************)
(* Index Message: 25 bytes                                                 *)
(***************************************************************************)

IndexMessage ==
    [ nanosecond            : Sample(4),
      symbol                : Sample(12),
      indexValue            : Sample(4),
      updateType            : Sample(1),
      perctgDiffFromClosing : Sample(4) ]

EncodeIndexMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.indexValue
        \o message.updateType
        \o message.perctgDiffFromClosing

DecodeIndexMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET indexValue == ReadBytes(symbol.rest, 4) IN IF ~indexValue.ok THEN Fail ELSE
    LET updateType == ReadBytes(indexValue.rest, 1) IN IF ~updateType.ok THEN Fail ELSE
    LET perctgDiffFromClosing == ReadBytes(updateType.rest, 4) IN IF ~perctgDiffFromClosing.ok THEN Fail ELSE
    Ok([ nanosecond            |-> nanosecond.value,
         symbol                |-> symbol.value,
         indexValue            |-> indexValue.value,
         updateType            |-> updateType.value,
         perctgDiffFromClosing |-> perctgDiffFromClosing.value ], perctgDiffFromClosing.rest)

ZeroIndexMessage ==
    [ nanosecond            |-> [i \in 1 .. 4 |-> 0],
      symbol                |-> [i \in 1 .. 12 |-> 0],
      indexValue            |-> [i \in 1 .. 4 |-> 0],
      updateType            |-> [i \in 1 .. 1 |-> 0],
      perctgDiffFromClosing |-> [i \in 1 .. 4 |-> 0] ]

(* Index Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexMessage ==
    { ZeroIndexMessage }
        \cup { [ZeroIndexMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroIndexMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroIndexMessage EXCEPT !.indexValue = one] : one \in Sample(4) }
        \cup { [ZeroIndexMessage EXCEPT !.updateType = one] : one \in Sample(1) }
        \cup { [ZeroIndexMessage EXCEPT !.perctgDiffFromClosing = one] : one \in Sample(4) }

(***************************************************************************)
(* Aon Info Message: 34 bytes                                              *)
(***************************************************************************)

AonInfoMessage ==
    [ nanosecond : Sample(4),
      symbol     : Sample(12),
      price      : Sample(4),
      side       : Sample(1),
      quantity   : Sample(4),
      aonStatus  : Sample(1),
      date       : Sample(8) ]

EncodeAonInfoMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.price
        \o message.side
        \o message.quantity
        \o message.aonStatus
        \o message.date

DecodeAonInfoMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET aonStatus == ReadBytes(quantity.rest, 1) IN IF ~aonStatus.ok THEN Fail ELSE
    LET date == ReadBytes(aonStatus.rest, 8) IN IF ~date.ok THEN Fail ELSE
    Ok([ nanosecond |-> nanosecond.value,
         symbol     |-> symbol.value,
         price      |-> price.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         aonStatus  |-> aonStatus.value,
         date       |-> date.value ], date.rest)

ZeroAonInfoMessage ==
    [ nanosecond |-> [i \in 1 .. 4 |-> 0],
      symbol     |-> [i \in 1 .. 12 |-> 0],
      price      |-> [i \in 1 .. 4 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      aonStatus  |-> [i \in 1 .. 1 |-> 0],
      date       |-> [i \in 1 .. 8 |-> 0] ]

(* Aon Info Message at zero, then each field in turn at the values it is checked at *)
CheckedAonInfoMessage ==
    { ZeroAonInfoMessage }
        \cup { [ZeroAonInfoMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroAonInfoMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroAonInfoMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAonInfoMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAonInfoMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAonInfoMessage EXCEPT !.aonStatus = one] : one \in Sample(1) }
        \cup { [ZeroAonInfoMessage EXCEPT !.date = one] : one \in Sample(8) }

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
(* Update Price Point Message: 34 bytes                                    *)
(***************************************************************************)

UpdatePricePointMessage ==
    [ nanosecond             : Sample(4),
      symbol                 : Sample(12),
      pricePointSubBookFlags : Sample(1),
      pricePointAction       : Sample(1),
      side                   : Sample(1),
      priceLevel             : Sample(1),
      price                  : Sample(4),
      quantity               : Sample(4),
      splits                 : Sample(4),
      updatePricePointFlags  : Sample(1),
      reserved1              : Sample(1) ]

EncodeUpdatePricePointMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.pricePointSubBookFlags
        \o message.pricePointAction
        \o message.side
        \o message.priceLevel
        \o message.price
        \o message.quantity
        \o message.splits
        \o message.updatePricePointFlags
        \o message.reserved1

DecodeUpdatePricePointMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET pricePointSubBookFlags == ReadBytes(symbol.rest, 1) IN IF ~pricePointSubBookFlags.ok THEN Fail ELSE
    LET pricePointAction == ReadBytes(pricePointSubBookFlags.rest, 1) IN IF ~pricePointAction.ok THEN Fail ELSE
    LET side == ReadBytes(pricePointAction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLevel == ReadBytes(side.rest, 1) IN IF ~priceLevel.ok THEN Fail ELSE
    LET price == ReadBytes(priceLevel.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET splits == ReadBytes(quantity.rest, 4) IN IF ~splits.ok THEN Fail ELSE
    LET updatePricePointFlags == ReadBytes(splits.rest, 1) IN IF ~updatePricePointFlags.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(updatePricePointFlags.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ nanosecond             |-> nanosecond.value,
         symbol                 |-> symbol.value,
         pricePointSubBookFlags |-> pricePointSubBookFlags.value,
         pricePointAction       |-> pricePointAction.value,
         side                   |-> side.value,
         priceLevel             |-> priceLevel.value,
         price                  |-> price.value,
         quantity               |-> quantity.value,
         splits                 |-> splits.value,
         updatePricePointFlags  |-> updatePricePointFlags.value,
         reserved1              |-> reserved1.value ], reserved1.rest)

ZeroUpdatePricePointMessage ==
    [ nanosecond             |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 12 |-> 0],
      pricePointSubBookFlags |-> [i \in 1 .. 1 |-> 0],
      pricePointAction       |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      priceLevel             |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 4 |-> 0],
      splits                 |-> [i \in 1 .. 4 |-> 0],
      updatePricePointFlags  |-> [i \in 1 .. 1 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0] ]

(* Update Price Point Message at zero, then each field in turn at the values it is checked at *)
CheckedUpdatePricePointMessage ==
    { ZeroUpdatePricePointMessage }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.pricePointSubBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.pricePointAction = one] : one \in Sample(1) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.priceLevel = one] : one \in Sample(1) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.splits = one] : one \in Sample(4) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.updatePricePointFlags = one] : one \in Sample(1) }
        \cup { [ZeroUpdatePricePointMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Price Point Message: 20 bytes                                    *)
(***************************************************************************)

DeletePricePointMessage ==
    [ nanosecond             : Sample(4),
      symbol                 : Sample(12),
      pricePointSubBookFlags : Sample(1),
      side                   : Sample(1),
      priceLevel             : Sample(1),
      reserved1              : Sample(1) ]

EncodeDeletePricePointMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.pricePointSubBookFlags
        \o message.side
        \o message.priceLevel
        \o message.reserved1

DecodeDeletePricePointMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET pricePointSubBookFlags == ReadBytes(symbol.rest, 1) IN IF ~pricePointSubBookFlags.ok THEN Fail ELSE
    LET side == ReadBytes(pricePointSubBookFlags.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLevel == ReadBytes(side.rest, 1) IN IF ~priceLevel.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(priceLevel.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ nanosecond             |-> nanosecond.value,
         symbol                 |-> symbol.value,
         pricePointSubBookFlags |-> pricePointSubBookFlags.value,
         side                   |-> side.value,
         priceLevel             |-> priceLevel.value,
         reserved1              |-> reserved1.value ], reserved1.rest)

ZeroDeletePricePointMessage ==
    [ nanosecond             |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 12 |-> 0],
      pricePointSubBookFlags |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      priceLevel             |-> [i \in 1 .. 1 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0] ]

(* Delete Price Point Message at zero, then each field in turn at the values it is checked at *)
CheckedDeletePricePointMessage ==
    { ZeroDeletePricePointMessage }
        \cup { [ZeroDeletePricePointMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroDeletePricePointMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroDeletePricePointMessage EXCEPT !.pricePointSubBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroDeletePricePointMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeletePricePointMessage EXCEPT !.priceLevel = one] : one \in Sample(1) }
        \cup { [ZeroDeletePricePointMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Top Of Book Message: 33 bytes                                           *)
(***************************************************************************)

TopOfBookMessage ==
    [ nanosecond             : Sample(4),
      symbol                 : Sample(12),
      pricePointSubBookFlags : Sample(1),
      topOfBookAction        : Sample(1),
      side                   : Sample(1),
      price                  : Sample(4),
      quantity               : Sample(4),
      marketOrderQuantity    : Sample(4),
      reserved2              : Sample(2) ]

EncodeTopOfBookMessage(message) ==
    message.nanosecond
        \o message.symbol
        \o message.pricePointSubBookFlags
        \o message.topOfBookAction
        \o message.side
        \o message.price
        \o message.quantity
        \o message.marketOrderQuantity
        \o message.reserved2

DecodeTopOfBookMessage(bytes) ==
    LET nanosecond == ReadBytes(bytes, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    LET symbol == ReadBytes(nanosecond.rest, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET pricePointSubBookFlags == ReadBytes(symbol.rest, 1) IN IF ~pricePointSubBookFlags.ok THEN Fail ELSE
    LET topOfBookAction == ReadBytes(pricePointSubBookFlags.rest, 1) IN IF ~topOfBookAction.ok THEN Fail ELSE
    LET side == ReadBytes(topOfBookAction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET marketOrderQuantity == ReadBytes(quantity.rest, 4) IN IF ~marketOrderQuantity.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(marketOrderQuantity.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ nanosecond             |-> nanosecond.value,
         symbol                 |-> symbol.value,
         pricePointSubBookFlags |-> pricePointSubBookFlags.value,
         topOfBookAction        |-> topOfBookAction.value,
         side                   |-> side.value,
         price                  |-> price.value,
         quantity               |-> quantity.value,
         marketOrderQuantity    |-> marketOrderQuantity.value,
         reserved2              |-> reserved2.value ], reserved2.rest)

ZeroTopOfBookMessage ==
    [ nanosecond             |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 12 |-> 0],
      pricePointSubBookFlags |-> [i \in 1 .. 1 |-> 0],
      topOfBookAction        |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      price                  |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 4 |-> 0],
      marketOrderQuantity    |-> [i \in 1 .. 4 |-> 0],
      reserved2              |-> [i \in 1 .. 2 |-> 0] ]

(* Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBookMessage ==
    { ZeroTopOfBookMessage }
        \cup { [ZeroTopOfBookMessage EXCEPT !.nanosecond = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.pricePointSubBookFlags = one] : one \in Sample(1) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.topOfBookAction = one] : one \in Sample(1) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.marketOrderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginRequestMessageCode == 1  \* 0x01
LoginResponseMessageCode == 2  \* 0x02
SnapshotRequestMessageCode == 129  \* 0x81
SnapshotResponseMessageCode == 130  \* 0x82
SnapshotCompleteMessageCode == 131  \* 0x83
LogoutRequestMessageCode == 5  \* 0x05
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
TradeBreakMessageCode == 66  \* 0x42
TradeCorrectionMessageCode == 96  \* 0x60
RecoveryTradeMessageCode == 118  \* 0x76
AuctionInfoMessageCode == 73  \* 0x49
StatisticsMessageCode == 119  \* 0x77
ExtendedStatisticsMessageCode == 128  \* 0x80
ConsolidatedStatisticsMessageCode == 100  \* 0x64
IndexMessageCode == 98  \* 0x62
AonInfoMessageCode == 101  \* 0x65
NewsMessageCode == 117  \* 0x75
UpdatePricePointMessageCode == 115  \* 0x73
DeletePricePointMessageCode == 114  \* 0x72
TopOfBookMessageCode == 113  \* 0x71

Payload ==
    [ tag : {LoginRequestMessageCode}, body : LoginRequestMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {SnapshotRequestMessageCode}, body : SnapshotRequestMessage ]
        \cup [ tag : {SnapshotResponseMessageCode}, body : SnapshotResponseMessage ]
        \cup [ tag : {SnapshotCompleteMessageCode}, body : SnapshotCompleteMessage ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
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
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {RecoveryTradeMessageCode}, body : RecoveryTradeMessage ]
        \cup [ tag : {AuctionInfoMessageCode}, body : AuctionInfoMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {ExtendedStatisticsMessageCode}, body : ExtendedStatisticsMessage ]
        \cup [ tag : {ConsolidatedStatisticsMessageCode}, body : ConsolidatedStatisticsMessage ]
        \cup [ tag : {IndexMessageCode}, body : IndexMessage ]
        \cup [ tag : {AonInfoMessageCode}, body : AonInfoMessage ]
        \cup [ tag : {NewsMessageCode}, body : NewsMessage ]
        \cup [ tag : {UpdatePricePointMessageCode}, body : UpdatePricePointMessage ]
        \cup [ tag : {DeletePricePointMessageCode}, body : DeletePricePointMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginRequestMessageCode -> EncodeLoginRequestMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = SnapshotRequestMessageCode -> EncodeSnapshotRequestMessage(message.body)
      [] message.tag = SnapshotResponseMessageCode -> EncodeSnapshotResponseMessage(message.body)
      [] message.tag = SnapshotCompleteMessageCode -> EncodeSnapshotCompleteMessage(message.body)
      [] message.tag = LogoutRequestMessageCode -> << >>
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
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = RecoveryTradeMessageCode -> EncodeRecoveryTradeMessage(message.body)
      [] message.tag = AuctionInfoMessageCode -> EncodeAuctionInfoMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = ExtendedStatisticsMessageCode -> EncodeExtendedStatisticsMessage(message.body)
      [] message.tag = ConsolidatedStatisticsMessageCode -> EncodeConsolidatedStatisticsMessage(message.body)
      [] message.tag = IndexMessageCode -> EncodeIndexMessage(message.body)
      [] message.tag = AonInfoMessageCode -> EncodeAonInfoMessage(message.body)
      [] message.tag = NewsMessageCode -> EncodeNewsMessage(message.body)
      [] message.tag = UpdatePricePointMessageCode -> EncodeUpdatePricePointMessage(message.body)
      [] message.tag = DeletePricePointMessageCode -> EncodeDeletePricePointMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginRequestMessageCode -> DecodeLoginRequestMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = SnapshotRequestMessageCode -> DecodeSnapshotRequestMessage(bytes)
              [] tag = SnapshotResponseMessageCode -> DecodeSnapshotResponseMessage(bytes)
              [] tag = SnapshotCompleteMessageCode -> DecodeSnapshotCompleteMessage(bytes)
              [] tag = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
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
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = RecoveryTradeMessageCode -> DecodeRecoveryTradeMessage(bytes)
              [] tag = AuctionInfoMessageCode -> DecodeAuctionInfoMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = ExtendedStatisticsMessageCode -> DecodeExtendedStatisticsMessage(bytes)
              [] tag = ConsolidatedStatisticsMessageCode -> DecodeConsolidatedStatisticsMessage(bytes)
              [] tag = IndexMessageCode -> DecodeIndexMessage(bytes)
              [] tag = AonInfoMessageCode -> DecodeAonInfoMessage(bytes)
              [] tag = NewsMessageCode -> DecodeNewsMessage(bytes)
              [] tag = UpdatePricePointMessageCode -> DecodeUpdatePricePointMessage(bytes)
              [] tag = DeletePricePointMessageCode -> DecodeDeletePricePointMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginRequestMessageCode, body |-> ZeroLoginRequestMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginRequestMessageCode, body |-> one] : one \in CheckedLoginRequestMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> SnapshotRequestMessageCode, body |-> one] : one \in CheckedSnapshotRequestMessage }
        \cup { [tag |-> SnapshotResponseMessageCode, body |-> one] : one \in CheckedSnapshotResponseMessage }
        \cup { [tag |-> SnapshotCompleteMessageCode, body |-> one] : one \in CheckedSnapshotCompleteMessage }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]] }
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
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> RecoveryTradeMessageCode, body |-> one] : one \in CheckedRecoveryTradeMessage }
        \cup { [tag |-> AuctionInfoMessageCode, body |-> one] : one \in CheckedAuctionInfoMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> ExtendedStatisticsMessageCode, body |-> one] : one \in CheckedExtendedStatisticsMessage }
        \cup { [tag |-> ConsolidatedStatisticsMessageCode, body |-> one] : one \in CheckedConsolidatedStatisticsMessage }
        \cup { [tag |-> IndexMessageCode, body |-> one] : one \in CheckedIndexMessage }
        \cup { [tag |-> AonInfoMessageCode, body |-> one] : one \in CheckedAonInfoMessage }
        \cup { [tag |-> NewsMessageCode, body |-> one] : one \in CheckedNewsMessage }
        \cup { [tag |-> UpdatePricePointMessageCode, body |-> one] : one \in CheckedUpdatePricePointMessage }
        \cup { [tag |-> DeletePricePointMessageCode, body |-> one] : one \in CheckedDeletePricePointMessage }
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotRequestMessageCode, body |-> ZeroSnapshotRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotResponseMessageCode, body |-> ZeroSnapshotResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotCompleteMessageCode, body |-> ZeroSnapshotCompleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]]],
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
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RecoveryTradeMessageCode, body |-> ZeroRecoveryTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionInfoMessageCode, body |-> ZeroAuctionInfoMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExtendedStatisticsMessageCode, body |-> ZeroExtendedStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ConsolidatedStatisticsMessageCode, body |-> ZeroConsolidatedStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexMessageCode, body |-> ZeroIndexMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AonInfoMessageCode, body |-> ZeroAonInfoMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewsMessageCode, body |-> ZeroNewsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UpdatePricePointMessageCode, body |-> ZeroUpdatePricePointMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeletePricePointMessageCode, body |-> ZeroDeletePricePointMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]] }

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

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
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

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
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

(* Every Consolidated Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedStatisticsMessage ==
    \A message \in CheckedConsolidatedStatisticsMessage :
        LET read == DecodeConsolidatedStatisticsMessage(EncodeConsolidatedStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMessage ==
    \A message \in CheckedIndexMessage :
        LET read == DecodeIndexMessage(EncodeIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aon Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAonInfoMessage ==
    \A message \in CheckedAonInfoMessage :
        LET read == DecodeAonInfoMessage(EncodeAonInfoMessage(message))
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

(* Every Update Price Point Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUpdatePricePointMessage ==
    \A message \in CheckedUpdatePricePointMessage :
        LET read == DecodeUpdatePricePointMessage(EncodeUpdatePricePointMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Price Point Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeletePricePointMessage ==
    \A message \in CheckedDeletePricePointMessage :
        LET read == DecodeDeletePricePointMessage(EncodeDeletePricePointMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
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
