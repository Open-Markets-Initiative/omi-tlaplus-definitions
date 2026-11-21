--------------------- MODULE Nasdaq_Index_Gids_v1_0_i ----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Global Index Data Service v1.0.i                               *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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
(* Timestamp Seconds Message: 4 bytes                                      *)
(***************************************************************************)

TimestampSecondsMessage ==
    [ second : Sample(4) ]

EncodeTimestampSecondsMessage(message) ==
    message.second

DecodeTimestampSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroTimestampSecondsMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedTimestampSecondsMessage ==
    { ZeroTimestampSecondsMessage }
        \cup { [ZeroTimestampSecondsMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 8 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanoseconds : Sample(4),
      eventCode   : Sample(1),
      schedule    : Sample(3) ]

EncodeSystemEventMessage(message) ==
    message.nanoseconds
        \o message.eventCode
        \o message.schedule

DecodeSystemEventMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanoseconds.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET schedule == ReadBytes(eventCode.rest, 3) IN IF ~schedule.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         eventCode   |-> eventCode.value,
         schedule    |-> schedule.value ], schedule.rest)

ZeroSystemEventMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0],
      schedule    |-> [i \in 1 .. 3 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.schedule = one] : one \in Sample(3) }

(***************************************************************************)
(* Index Directory Message                                                 *)
(***************************************************************************)

IndexDirectoryMessage ==
    [ nanoseconds                        : Sample(4),
      instrumentId                       : Sample(18),
      disseminationFlag                  : Sample(1),
      financialProductType               : Sample(1),
      brand                              : Sample(2),
      series                             : Sample(3),
      strategy                           : Sample(3),
      assetType                          : Sample(2),
      marketCapSize                      : Sample(1),
      currency                           : Sample(3),
      geography                          : Sample(4),
      indexSettlementType                : Sample(1),
      indexCalculationMethod             : Sample(3),
      state                              : Sample(1),
      indexUsage                         : Sample(1),
      schedule                           : Sample(3),
      frequency                          : Sample(4),
      numberOfIssueParticipationMessages : Sample(4),
      baseValue                          : Sample(8),
      baseDate                           : Sample(4),
      instrumentName                     : SampleBytes ]

EncodeIndexDirectoryMessage(message) ==
    message.nanoseconds
        \o message.instrumentId
        \o message.disseminationFlag
        \o message.financialProductType
        \o message.brand
        \o message.series
        \o message.strategy
        \o message.assetType
        \o message.marketCapSize
        \o message.currency
        \o message.geography
        \o message.indexSettlementType
        \o message.indexCalculationMethod
        \o message.state
        \o message.indexUsage
        \o message.schedule
        \o message.frequency
        \o message.numberOfIssueParticipationMessages
        \o message.baseValue
        \o message.baseDate
        \o EncodeUIntBE(Len(message.instrumentName), 2)
        \o message.instrumentName

DecodeIndexDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanoseconds.rest, 18) IN IF ~instrumentId.ok THEN Fail ELSE
    LET disseminationFlag == ReadBytes(instrumentId.rest, 1) IN IF ~disseminationFlag.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(disseminationFlag.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET brand == ReadBytes(financialProductType.rest, 2) IN IF ~brand.ok THEN Fail ELSE
    LET series == ReadBytes(brand.rest, 3) IN IF ~series.ok THEN Fail ELSE
    LET strategy == ReadBytes(series.rest, 3) IN IF ~strategy.ok THEN Fail ELSE
    LET assetType == ReadBytes(strategy.rest, 2) IN IF ~assetType.ok THEN Fail ELSE
    LET marketCapSize == ReadBytes(assetType.rest, 1) IN IF ~marketCapSize.ok THEN Fail ELSE
    LET currency == ReadBytes(marketCapSize.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET geography == ReadBytes(currency.rest, 4) IN IF ~geography.ok THEN Fail ELSE
    LET indexSettlementType == ReadBytes(geography.rest, 1) IN IF ~indexSettlementType.ok THEN Fail ELSE
    LET indexCalculationMethod == ReadBytes(indexSettlementType.rest, 3) IN IF ~indexCalculationMethod.ok THEN Fail ELSE
    LET state == ReadBytes(indexCalculationMethod.rest, 1) IN IF ~state.ok THEN Fail ELSE
    LET indexUsage == ReadBytes(state.rest, 1) IN IF ~indexUsage.ok THEN Fail ELSE
    LET schedule == ReadBytes(indexUsage.rest, 3) IN IF ~schedule.ok THEN Fail ELSE
    LET frequency == ReadBytes(schedule.rest, 4) IN IF ~frequency.ok THEN Fail ELSE
    LET numberOfIssueParticipationMessages == ReadBytes(frequency.rest, 4) IN IF ~numberOfIssueParticipationMessages.ok THEN Fail ELSE
    LET baseValue == ReadBytes(numberOfIssueParticipationMessages.rest, 8) IN IF ~baseValue.ok THEN Fail ELSE
    LET baseDate == ReadBytes(baseValue.rest, 4) IN IF ~baseDate.ok THEN Fail ELSE
    LET nameLength == ReadUIntBE(baseDate.rest, 2) IN IF ~nameLength.ok THEN Fail ELSE
    LET instrumentName == ReadBytes(nameLength.rest, nameLength.value) IN IF ~instrumentName.ok THEN Fail ELSE
    Ok([ nanoseconds                        |-> nanoseconds.value,
         instrumentId                       |-> instrumentId.value,
         disseminationFlag                  |-> disseminationFlag.value,
         financialProductType               |-> financialProductType.value,
         brand                              |-> brand.value,
         series                             |-> series.value,
         strategy                           |-> strategy.value,
         assetType                          |-> assetType.value,
         marketCapSize                      |-> marketCapSize.value,
         currency                           |-> currency.value,
         geography                          |-> geography.value,
         indexSettlementType                |-> indexSettlementType.value,
         indexCalculationMethod             |-> indexCalculationMethod.value,
         state                              |-> state.value,
         indexUsage                         |-> indexUsage.value,
         schedule                           |-> schedule.value,
         frequency                          |-> frequency.value,
         numberOfIssueParticipationMessages |-> numberOfIssueParticipationMessages.value,
         baseValue                          |-> baseValue.value,
         baseDate                           |-> baseDate.value,
         instrumentName                     |-> instrumentName.value ], instrumentName.rest)

ZeroIndexDirectoryMessage ==
    [ nanoseconds                        |-> [i \in 1 .. 4 |-> 0],
      instrumentId                       |-> [i \in 1 .. 18 |-> 0],
      disseminationFlag                  |-> [i \in 1 .. 1 |-> 0],
      financialProductType               |-> [i \in 1 .. 1 |-> 0],
      brand                              |-> [i \in 1 .. 2 |-> 0],
      series                             |-> [i \in 1 .. 3 |-> 0],
      strategy                           |-> [i \in 1 .. 3 |-> 0],
      assetType                          |-> [i \in 1 .. 2 |-> 0],
      marketCapSize                      |-> [i \in 1 .. 1 |-> 0],
      currency                           |-> [i \in 1 .. 3 |-> 0],
      geography                          |-> [i \in 1 .. 4 |-> 0],
      indexSettlementType                |-> [i \in 1 .. 1 |-> 0],
      indexCalculationMethod             |-> [i \in 1 .. 3 |-> 0],
      state                              |-> [i \in 1 .. 1 |-> 0],
      indexUsage                         |-> [i \in 1 .. 1 |-> 0],
      schedule                           |-> [i \in 1 .. 3 |-> 0],
      frequency                          |-> [i \in 1 .. 4 |-> 0],
      numberOfIssueParticipationMessages |-> [i \in 1 .. 4 |-> 0],
      baseValue                          |-> [i \in 1 .. 8 |-> 0],
      baseDate                           |-> [i \in 1 .. 4 |-> 0],
      instrumentName                     |-> << >> ]

(* Index Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexDirectoryMessage ==
    { ZeroIndexDirectoryMessage }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(18) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.disseminationFlag = one] : one \in Sample(1) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.brand = one] : one \in Sample(2) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.series = one] : one \in Sample(3) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.strategy = one] : one \in Sample(3) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.assetType = one] : one \in Sample(2) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.marketCapSize = one] : one \in Sample(1) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.geography = one] : one \in Sample(4) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.indexSettlementType = one] : one \in Sample(1) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.indexCalculationMethod = one] : one \in Sample(3) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.state = one] : one \in Sample(1) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.indexUsage = one] : one \in Sample(1) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.schedule = one] : one \in Sample(3) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.frequency = one] : one \in Sample(4) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.numberOfIssueParticipationMessages = one] : one \in Sample(4) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.baseValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.baseDate = one] : one \in Sample(4) }
        \cup { [ZeroIndexDirectoryMessage EXCEPT !.instrumentName = one] : one \in SampleBytes }

(***************************************************************************)
(* Issue Symbol Participation Message                                      *)
(***************************************************************************)

IssueSymbolParticipationMessage ==
    [ nanoseconds  : Sample(4),
      instrumentId : Sample(18),
      issueSymbol  : Sample(18),
      issueMic     : Sample(4),
      issueName    : SampleBytes ]

EncodeIssueSymbolParticipationMessage(message) ==
    message.nanoseconds
        \o message.instrumentId
        \o message.issueSymbol
        \o message.issueMic
        \o EncodeUIntBE(Len(message.issueName), 2)
        \o message.issueName

DecodeIssueSymbolParticipationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(nanoseconds.rest, 18) IN IF ~instrumentId.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(instrumentId.rest, 18) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET issueMic == ReadBytes(issueSymbol.rest, 4) IN IF ~issueMic.ok THEN Fail ELSE
    LET nameLength == ReadUIntBE(issueMic.rest, 2) IN IF ~nameLength.ok THEN Fail ELSE
    LET issueName == ReadBytes(nameLength.rest, nameLength.value) IN IF ~issueName.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         instrumentId |-> instrumentId.value,
         issueSymbol  |-> issueSymbol.value,
         issueMic     |-> issueMic.value,
         issueName    |-> issueName.value ], issueName.rest)

ZeroIssueSymbolParticipationMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 18 |-> 0],
      issueSymbol  |-> [i \in 1 .. 18 |-> 0],
      issueMic     |-> [i \in 1 .. 4 |-> 0],
      issueName    |-> << >> ]

(* Issue Symbol Participation Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueSymbolParticipationMessage ==
    { ZeroIssueSymbolParticipationMessage }
        \cup { [ZeroIssueSymbolParticipationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroIssueSymbolParticipationMessage EXCEPT !.instrumentId = one] : one \in Sample(18) }
        \cup { [ZeroIssueSymbolParticipationMessage EXCEPT !.issueSymbol = one] : one \in Sample(18) }
        \cup { [ZeroIssueSymbolParticipationMessage EXCEPT !.issueMic = one] : one \in Sample(4) }
        \cup { [ZeroIssueSymbolParticipationMessage EXCEPT !.issueName = one] : one \in SampleBytes }

(***************************************************************************)
(* Intraday Index Value Message: 40 bytes                                  *)
(***************************************************************************)

IntradayIndexValueMessage ==
    [ nanoseconds          : Sample(4),
      financialProductType : Sample(1),
      brand                : Sample(2),
      series               : Sample(3),
      instrumentId         : Sample(18),
      tickValue            : Sample(8),
      tickDirection        : Sample(1),
      currency             : Sample(3) ]

EncodeIntradayIndexValueMessage(message) ==
    message.nanoseconds
        \o message.financialProductType
        \o message.brand
        \o message.series
        \o message.instrumentId
        \o message.tickValue
        \o message.tickDirection
        \o message.currency

DecodeIntradayIndexValueMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(nanoseconds.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET brand == ReadBytes(financialProductType.rest, 2) IN IF ~brand.ok THEN Fail ELSE
    LET series == ReadBytes(brand.rest, 3) IN IF ~series.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(series.rest, 18) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tickValue == ReadBytes(instrumentId.rest, 8) IN IF ~tickValue.ok THEN Fail ELSE
    LET tickDirection == ReadBytes(tickValue.rest, 1) IN IF ~tickDirection.ok THEN Fail ELSE
    LET currency == ReadBytes(tickDirection.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         financialProductType |-> financialProductType.value,
         brand                |-> brand.value,
         series               |-> series.value,
         instrumentId         |-> instrumentId.value,
         tickValue            |-> tickValue.value,
         tickDirection        |-> tickDirection.value,
         currency             |-> currency.value ], currency.rest)

ZeroIntradayIndexValueMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      financialProductType |-> [i \in 1 .. 1 |-> 0],
      brand                |-> [i \in 1 .. 2 |-> 0],
      series               |-> [i \in 1 .. 3 |-> 0],
      instrumentId         |-> [i \in 1 .. 18 |-> 0],
      tickValue            |-> [i \in 1 .. 8 |-> 0],
      tickDirection        |-> [i \in 1 .. 1 |-> 0],
      currency             |-> [i \in 1 .. 3 |-> 0] ]

(* Intraday Index Value Message at zero, then each field in turn at the values it is checked at *)
CheckedIntradayIndexValueMessage ==
    { ZeroIntradayIndexValueMessage }
        \cup { [ZeroIntradayIndexValueMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroIntradayIndexValueMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroIntradayIndexValueMessage EXCEPT !.brand = one] : one \in Sample(2) }
        \cup { [ZeroIntradayIndexValueMessage EXCEPT !.series = one] : one \in Sample(3) }
        \cup { [ZeroIntradayIndexValueMessage EXCEPT !.instrumentId = one] : one \in Sample(18) }
        \cup { [ZeroIntradayIndexValueMessage EXCEPT !.tickValue = one] : one \in Sample(8) }
        \cup { [ZeroIntradayIndexValueMessage EXCEPT !.tickDirection = one] : one \in Sample(1) }
        \cup { [ZeroIntradayIndexValueMessage EXCEPT !.currency = one] : one \in Sample(3) }

(***************************************************************************)
(* Settlement Value Message: 40 bytes                                      *)
(***************************************************************************)

SettlementValueMessage ==
    [ nanoseconds          : Sample(4),
      financialProductType : Sample(1),
      brand                : Sample(2),
      series               : Sample(3),
      instrumentId         : Sample(18),
      settlementValue      : Sample(8),
      settlementType       : Sample(1),
      currency             : Sample(3) ]

EncodeSettlementValueMessage(message) ==
    message.nanoseconds
        \o message.financialProductType
        \o message.brand
        \o message.series
        \o message.instrumentId
        \o message.settlementValue
        \o message.settlementType
        \o message.currency

DecodeSettlementValueMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(nanoseconds.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET brand == ReadBytes(financialProductType.rest, 2) IN IF ~brand.ok THEN Fail ELSE
    LET series == ReadBytes(brand.rest, 3) IN IF ~series.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(series.rest, 18) IN IF ~instrumentId.ok THEN Fail ELSE
    LET settlementValue == ReadBytes(instrumentId.rest, 8) IN IF ~settlementValue.ok THEN Fail ELSE
    LET settlementType == ReadBytes(settlementValue.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET currency == ReadBytes(settlementType.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         financialProductType |-> financialProductType.value,
         brand                |-> brand.value,
         series               |-> series.value,
         instrumentId         |-> instrumentId.value,
         settlementValue      |-> settlementValue.value,
         settlementType       |-> settlementType.value,
         currency             |-> currency.value ], currency.rest)

ZeroSettlementValueMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      financialProductType |-> [i \in 1 .. 1 |-> 0],
      brand                |-> [i \in 1 .. 2 |-> 0],
      series               |-> [i \in 1 .. 3 |-> 0],
      instrumentId         |-> [i \in 1 .. 18 |-> 0],
      settlementValue      |-> [i \in 1 .. 8 |-> 0],
      settlementType       |-> [i \in 1 .. 1 |-> 0],
      currency             |-> [i \in 1 .. 3 |-> 0] ]

(* Settlement Value Message at zero, then each field in turn at the values it is checked at *)
CheckedSettlementValueMessage ==
    { ZeroSettlementValueMessage }
        \cup { [ZeroSettlementValueMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.brand = one] : one \in Sample(2) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.series = one] : one \in Sample(3) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.instrumentId = one] : one \in Sample(18) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.settlementValue = one] : one \in Sample(8) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.currency = one] : one \in Sample(3) }

(***************************************************************************)
(* Equities Summary Message: 78 bytes                                      *)
(***************************************************************************)

EquitiesSummaryMessage ==
    [ nanoseconds          : Sample(4),
      financialProductType : Sample(1),
      brand                : Sample(2),
      series               : Sample(3),
      instrumentId         : Sample(18),
      summaryType          : Sample(3),
      sodValue             : Sample(8),
      high                 : Sample(8),
      low                  : Sample(8),
      eodValue             : Sample(8),
      netChange            : Sample(8),
      effectiveDate        : Sample(4),
      currency             : Sample(3) ]

EncodeEquitiesSummaryMessage(message) ==
    message.nanoseconds
        \o message.financialProductType
        \o message.brand
        \o message.series
        \o message.instrumentId
        \o message.summaryType
        \o message.sodValue
        \o message.high
        \o message.low
        \o message.eodValue
        \o message.netChange
        \o message.effectiveDate
        \o message.currency

DecodeEquitiesSummaryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(nanoseconds.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET brand == ReadBytes(financialProductType.rest, 2) IN IF ~brand.ok THEN Fail ELSE
    LET series == ReadBytes(brand.rest, 3) IN IF ~series.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(series.rest, 18) IN IF ~instrumentId.ok THEN Fail ELSE
    LET summaryType == ReadBytes(instrumentId.rest, 3) IN IF ~summaryType.ok THEN Fail ELSE
    LET sodValue == ReadBytes(summaryType.rest, 8) IN IF ~sodValue.ok THEN Fail ELSE
    LET high == ReadBytes(sodValue.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET eodValue == ReadBytes(low.rest, 8) IN IF ~eodValue.ok THEN Fail ELSE
    LET netChange == ReadBytes(eodValue.rest, 8) IN IF ~netChange.ok THEN Fail ELSE
    LET effectiveDate == ReadBytes(netChange.rest, 4) IN IF ~effectiveDate.ok THEN Fail ELSE
    LET currency == ReadBytes(effectiveDate.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         financialProductType |-> financialProductType.value,
         brand                |-> brand.value,
         series               |-> series.value,
         instrumentId         |-> instrumentId.value,
         summaryType          |-> summaryType.value,
         sodValue             |-> sodValue.value,
         high                 |-> high.value,
         low                  |-> low.value,
         eodValue             |-> eodValue.value,
         netChange            |-> netChange.value,
         effectiveDate        |-> effectiveDate.value,
         currency             |-> currency.value ], currency.rest)

ZeroEquitiesSummaryMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      financialProductType |-> [i \in 1 .. 1 |-> 0],
      brand                |-> [i \in 1 .. 2 |-> 0],
      series               |-> [i \in 1 .. 3 |-> 0],
      instrumentId         |-> [i \in 1 .. 18 |-> 0],
      summaryType          |-> [i \in 1 .. 3 |-> 0],
      sodValue             |-> [i \in 1 .. 8 |-> 0],
      high                 |-> [i \in 1 .. 8 |-> 0],
      low                  |-> [i \in 1 .. 8 |-> 0],
      eodValue             |-> [i \in 1 .. 8 |-> 0],
      netChange            |-> [i \in 1 .. 8 |-> 0],
      effectiveDate        |-> [i \in 1 .. 4 |-> 0],
      currency             |-> [i \in 1 .. 3 |-> 0] ]

(* Equities Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEquitiesSummaryMessage ==
    { ZeroEquitiesSummaryMessage }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.brand = one] : one \in Sample(2) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.series = one] : one \in Sample(3) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.instrumentId = one] : one \in Sample(18) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.summaryType = one] : one \in Sample(3) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.sodValue = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.eodValue = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.netChange = one] : one \in Sample(8) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.effectiveDate = one] : one \in Sample(4) }
        \cup { [ZeroEquitiesSummaryMessage EXCEPT !.currency = one] : one \in Sample(3) }

(***************************************************************************)
(* Fixed Income Summary Message: 102 bytes                                 *)
(***************************************************************************)

FixedIncomeSummaryMessage ==
    [ nanoseconds          : Sample(4),
      financialProductType : Sample(1),
      brand                : Sample(2),
      series               : Sample(3),
      instrumentId         : Sample(18),
      summaryType          : Sample(3),
      sodValue             : Sample(8),
      high                 : Sample(8),
      low                  : Sample(8),
      eodValue             : Sample(8),
      netChange            : Sample(8),
      effectiveDate        : Sample(4),
      yield                : Sample(8),
      duration             : Sample(8),
      coupon               : Sample(8),
      currency             : Sample(3) ]

EncodeFixedIncomeSummaryMessage(message) ==
    message.nanoseconds
        \o message.financialProductType
        \o message.brand
        \o message.series
        \o message.instrumentId
        \o message.summaryType
        \o message.sodValue
        \o message.high
        \o message.low
        \o message.eodValue
        \o message.netChange
        \o message.effectiveDate
        \o message.yield
        \o message.duration
        \o message.coupon
        \o message.currency

DecodeFixedIncomeSummaryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(nanoseconds.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET brand == ReadBytes(financialProductType.rest, 2) IN IF ~brand.ok THEN Fail ELSE
    LET series == ReadBytes(brand.rest, 3) IN IF ~series.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(series.rest, 18) IN IF ~instrumentId.ok THEN Fail ELSE
    LET summaryType == ReadBytes(instrumentId.rest, 3) IN IF ~summaryType.ok THEN Fail ELSE
    LET sodValue == ReadBytes(summaryType.rest, 8) IN IF ~sodValue.ok THEN Fail ELSE
    LET high == ReadBytes(sodValue.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET eodValue == ReadBytes(low.rest, 8) IN IF ~eodValue.ok THEN Fail ELSE
    LET netChange == ReadBytes(eodValue.rest, 8) IN IF ~netChange.ok THEN Fail ELSE
    LET effectiveDate == ReadBytes(netChange.rest, 4) IN IF ~effectiveDate.ok THEN Fail ELSE
    LET yield == ReadBytes(effectiveDate.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET duration == ReadBytes(yield.rest, 8) IN IF ~duration.ok THEN Fail ELSE
    LET coupon == ReadBytes(duration.rest, 8) IN IF ~coupon.ok THEN Fail ELSE
    LET currency == ReadBytes(coupon.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         financialProductType |-> financialProductType.value,
         brand                |-> brand.value,
         series               |-> series.value,
         instrumentId         |-> instrumentId.value,
         summaryType          |-> summaryType.value,
         sodValue             |-> sodValue.value,
         high                 |-> high.value,
         low                  |-> low.value,
         eodValue             |-> eodValue.value,
         netChange            |-> netChange.value,
         effectiveDate        |-> effectiveDate.value,
         yield                |-> yield.value,
         duration             |-> duration.value,
         coupon               |-> coupon.value,
         currency             |-> currency.value ], currency.rest)

ZeroFixedIncomeSummaryMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      financialProductType |-> [i \in 1 .. 1 |-> 0],
      brand                |-> [i \in 1 .. 2 |-> 0],
      series               |-> [i \in 1 .. 3 |-> 0],
      instrumentId         |-> [i \in 1 .. 18 |-> 0],
      summaryType          |-> [i \in 1 .. 3 |-> 0],
      sodValue             |-> [i \in 1 .. 8 |-> 0],
      high                 |-> [i \in 1 .. 8 |-> 0],
      low                  |-> [i \in 1 .. 8 |-> 0],
      eodValue             |-> [i \in 1 .. 8 |-> 0],
      netChange            |-> [i \in 1 .. 8 |-> 0],
      effectiveDate        |-> [i \in 1 .. 4 |-> 0],
      yield                |-> [i \in 1 .. 8 |-> 0],
      duration             |-> [i \in 1 .. 8 |-> 0],
      coupon               |-> [i \in 1 .. 8 |-> 0],
      currency             |-> [i \in 1 .. 3 |-> 0] ]

(* Fixed Income Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFixedIncomeSummaryMessage ==
    { ZeroFixedIncomeSummaryMessage }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.brand = one] : one \in Sample(2) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.series = one] : one \in Sample(3) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.instrumentId = one] : one \in Sample(18) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.summaryType = one] : one \in Sample(3) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.sodValue = one] : one \in Sample(8) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.eodValue = one] : one \in Sample(8) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.netChange = one] : one \in Sample(8) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.effectiveDate = one] : one \in Sample(4) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.duration = one] : one \in Sample(8) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.coupon = one] : one \in Sample(8) }
        \cup { [ZeroFixedIncomeSummaryMessage EXCEPT !.currency = one] : one \in Sample(3) }

(***************************************************************************)
(* Commodity Summary Message: 78 bytes                                     *)
(***************************************************************************)

CommoditySummaryMessage ==
    [ nanoseconds          : Sample(4),
      financialProductType : Sample(1),
      brand                : Sample(2),
      series               : Sample(3),
      instrumentId         : Sample(18),
      summaryType          : Sample(3),
      sodValue             : Sample(8),
      high                 : Sample(8),
      low                  : Sample(8),
      eodValue             : Sample(8),
      netChange            : Sample(8),
      effectiveDate        : Sample(4),
      currency             : Sample(3) ]

EncodeCommoditySummaryMessage(message) ==
    message.nanoseconds
        \o message.financialProductType
        \o message.brand
        \o message.series
        \o message.instrumentId
        \o message.summaryType
        \o message.sodValue
        \o message.high
        \o message.low
        \o message.eodValue
        \o message.netChange
        \o message.effectiveDate
        \o message.currency

DecodeCommoditySummaryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(nanoseconds.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET brand == ReadBytes(financialProductType.rest, 2) IN IF ~brand.ok THEN Fail ELSE
    LET series == ReadBytes(brand.rest, 3) IN IF ~series.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(series.rest, 18) IN IF ~instrumentId.ok THEN Fail ELSE
    LET summaryType == ReadBytes(instrumentId.rest, 3) IN IF ~summaryType.ok THEN Fail ELSE
    LET sodValue == ReadBytes(summaryType.rest, 8) IN IF ~sodValue.ok THEN Fail ELSE
    LET high == ReadBytes(sodValue.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET eodValue == ReadBytes(low.rest, 8) IN IF ~eodValue.ok THEN Fail ELSE
    LET netChange == ReadBytes(eodValue.rest, 8) IN IF ~netChange.ok THEN Fail ELSE
    LET effectiveDate == ReadBytes(netChange.rest, 4) IN IF ~effectiveDate.ok THEN Fail ELSE
    LET currency == ReadBytes(effectiveDate.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         financialProductType |-> financialProductType.value,
         brand                |-> brand.value,
         series               |-> series.value,
         instrumentId         |-> instrumentId.value,
         summaryType          |-> summaryType.value,
         sodValue             |-> sodValue.value,
         high                 |-> high.value,
         low                  |-> low.value,
         eodValue             |-> eodValue.value,
         netChange            |-> netChange.value,
         effectiveDate        |-> effectiveDate.value,
         currency             |-> currency.value ], currency.rest)

ZeroCommoditySummaryMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      financialProductType |-> [i \in 1 .. 1 |-> 0],
      brand                |-> [i \in 1 .. 2 |-> 0],
      series               |-> [i \in 1 .. 3 |-> 0],
      instrumentId         |-> [i \in 1 .. 18 |-> 0],
      summaryType          |-> [i \in 1 .. 3 |-> 0],
      sodValue             |-> [i \in 1 .. 8 |-> 0],
      high                 |-> [i \in 1 .. 8 |-> 0],
      low                  |-> [i \in 1 .. 8 |-> 0],
      eodValue             |-> [i \in 1 .. 8 |-> 0],
      netChange            |-> [i \in 1 .. 8 |-> 0],
      effectiveDate        |-> [i \in 1 .. 4 |-> 0],
      currency             |-> [i \in 1 .. 3 |-> 0] ]

(* Commodity Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedCommoditySummaryMessage ==
    { ZeroCommoditySummaryMessage }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.brand = one] : one \in Sample(2) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.series = one] : one \in Sample(3) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.instrumentId = one] : one \in Sample(18) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.summaryType = one] : one \in Sample(3) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.sodValue = one] : one \in Sample(8) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.eodValue = one] : one \in Sample(8) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.netChange = one] : one \in Sample(8) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.effectiveDate = one] : one \in Sample(4) }
        \cup { [ZeroCommoditySummaryMessage EXCEPT !.currency = one] : one \in Sample(3) }

(***************************************************************************)
(* Etp Directory And Daily Valuation Message                               *)
(***************************************************************************)

EtpDirectoryAndDailyValuationMessage ==
    [ nanoseconds                 : Sample(4),
      financialProductType        : Sample(1),
      industryMic                 : Sample(4),
      etpTradingSymbol            : Sample(18),
      etpIpvSymbol                : Sample(18),
      schedule                    : Sample(3),
      frequency                   : Sample(4),
      state                       : Sample(1),
      navSymbol                   : Sample(18),
      nav                         : Sample(8),
      estimatedCashPerCuSymbol    : Sample(18),
      ecu                         : Sample(8),
      totalCashPerCuSymbol        : Sample(18),
      totalCashPerCu              : Sample(8),
      estimatedCashPerShareSymbol : Sample(18),
      ecs                         : Sample(8),
      tsoSymbol                   : Sample(18),
      tsoOutstanding              : Sample(8),
      effectiveDate               : Sample(4),
      yield                       : Sample(8),
      coupon                      : Sample(8),
      maturityDate                : Sample(4),
      currency                    : Sample(3),
      etpName                     : SampleBytes ]

EncodeEtpDirectoryAndDailyValuationMessage(message) ==
    message.nanoseconds
        \o message.financialProductType
        \o message.industryMic
        \o message.etpTradingSymbol
        \o message.etpIpvSymbol
        \o message.schedule
        \o message.frequency
        \o message.state
        \o message.navSymbol
        \o message.nav
        \o message.estimatedCashPerCuSymbol
        \o message.ecu
        \o message.totalCashPerCuSymbol
        \o message.totalCashPerCu
        \o message.estimatedCashPerShareSymbol
        \o message.ecs
        \o message.tsoSymbol
        \o message.tsoOutstanding
        \o message.effectiveDate
        \o message.yield
        \o message.coupon
        \o message.maturityDate
        \o message.currency
        \o EncodeUIntBE(Len(message.etpName), 2)
        \o message.etpName

DecodeEtpDirectoryAndDailyValuationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(nanoseconds.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET industryMic == ReadBytes(financialProductType.rest, 4) IN IF ~industryMic.ok THEN Fail ELSE
    LET etpTradingSymbol == ReadBytes(industryMic.rest, 18) IN IF ~etpTradingSymbol.ok THEN Fail ELSE
    LET etpIpvSymbol == ReadBytes(etpTradingSymbol.rest, 18) IN IF ~etpIpvSymbol.ok THEN Fail ELSE
    LET schedule == ReadBytes(etpIpvSymbol.rest, 3) IN IF ~schedule.ok THEN Fail ELSE
    LET frequency == ReadBytes(schedule.rest, 4) IN IF ~frequency.ok THEN Fail ELSE
    LET state == ReadBytes(frequency.rest, 1) IN IF ~state.ok THEN Fail ELSE
    LET navSymbol == ReadBytes(state.rest, 18) IN IF ~navSymbol.ok THEN Fail ELSE
    LET nav == ReadBytes(navSymbol.rest, 8) IN IF ~nav.ok THEN Fail ELSE
    LET estimatedCashPerCuSymbol == ReadBytes(nav.rest, 18) IN IF ~estimatedCashPerCuSymbol.ok THEN Fail ELSE
    LET ecu == ReadBytes(estimatedCashPerCuSymbol.rest, 8) IN IF ~ecu.ok THEN Fail ELSE
    LET totalCashPerCuSymbol == ReadBytes(ecu.rest, 18) IN IF ~totalCashPerCuSymbol.ok THEN Fail ELSE
    LET totalCashPerCu == ReadBytes(totalCashPerCuSymbol.rest, 8) IN IF ~totalCashPerCu.ok THEN Fail ELSE
    LET estimatedCashPerShareSymbol == ReadBytes(totalCashPerCu.rest, 18) IN IF ~estimatedCashPerShareSymbol.ok THEN Fail ELSE
    LET ecs == ReadBytes(estimatedCashPerShareSymbol.rest, 8) IN IF ~ecs.ok THEN Fail ELSE
    LET tsoSymbol == ReadBytes(ecs.rest, 18) IN IF ~tsoSymbol.ok THEN Fail ELSE
    LET tsoOutstanding == ReadBytes(tsoSymbol.rest, 8) IN IF ~tsoOutstanding.ok THEN Fail ELSE
    LET effectiveDate == ReadBytes(tsoOutstanding.rest, 4) IN IF ~effectiveDate.ok THEN Fail ELSE
    LET yield == ReadBytes(effectiveDate.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET coupon == ReadBytes(yield.rest, 8) IN IF ~coupon.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(coupon.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET currency == ReadBytes(maturityDate.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET etpNameLength == ReadUIntBE(currency.rest, 2) IN IF ~etpNameLength.ok THEN Fail ELSE
    LET etpName == ReadBytes(etpNameLength.rest, etpNameLength.value) IN IF ~etpName.ok THEN Fail ELSE
    Ok([ nanoseconds                 |-> nanoseconds.value,
         financialProductType        |-> financialProductType.value,
         industryMic                 |-> industryMic.value,
         etpTradingSymbol            |-> etpTradingSymbol.value,
         etpIpvSymbol                |-> etpIpvSymbol.value,
         schedule                    |-> schedule.value,
         frequency                   |-> frequency.value,
         state                       |-> state.value,
         navSymbol                   |-> navSymbol.value,
         nav                         |-> nav.value,
         estimatedCashPerCuSymbol    |-> estimatedCashPerCuSymbol.value,
         ecu                         |-> ecu.value,
         totalCashPerCuSymbol        |-> totalCashPerCuSymbol.value,
         totalCashPerCu              |-> totalCashPerCu.value,
         estimatedCashPerShareSymbol |-> estimatedCashPerShareSymbol.value,
         ecs                         |-> ecs.value,
         tsoSymbol                   |-> tsoSymbol.value,
         tsoOutstanding              |-> tsoOutstanding.value,
         effectiveDate               |-> effectiveDate.value,
         yield                       |-> yield.value,
         coupon                      |-> coupon.value,
         maturityDate                |-> maturityDate.value,
         currency                    |-> currency.value,
         etpName                     |-> etpName.value ], etpName.rest)

ZeroEtpDirectoryAndDailyValuationMessage ==
    [ nanoseconds                 |-> [i \in 1 .. 4 |-> 0],
      financialProductType        |-> [i \in 1 .. 1 |-> 0],
      industryMic                 |-> [i \in 1 .. 4 |-> 0],
      etpTradingSymbol            |-> [i \in 1 .. 18 |-> 0],
      etpIpvSymbol                |-> [i \in 1 .. 18 |-> 0],
      schedule                    |-> [i \in 1 .. 3 |-> 0],
      frequency                   |-> [i \in 1 .. 4 |-> 0],
      state                       |-> [i \in 1 .. 1 |-> 0],
      navSymbol                   |-> [i \in 1 .. 18 |-> 0],
      nav                         |-> [i \in 1 .. 8 |-> 0],
      estimatedCashPerCuSymbol    |-> [i \in 1 .. 18 |-> 0],
      ecu                         |-> [i \in 1 .. 8 |-> 0],
      totalCashPerCuSymbol        |-> [i \in 1 .. 18 |-> 0],
      totalCashPerCu              |-> [i \in 1 .. 8 |-> 0],
      estimatedCashPerShareSymbol |-> [i \in 1 .. 18 |-> 0],
      ecs                         |-> [i \in 1 .. 8 |-> 0],
      tsoSymbol                   |-> [i \in 1 .. 18 |-> 0],
      tsoOutstanding              |-> [i \in 1 .. 8 |-> 0],
      effectiveDate               |-> [i \in 1 .. 4 |-> 0],
      yield                       |-> [i \in 1 .. 8 |-> 0],
      coupon                      |-> [i \in 1 .. 8 |-> 0],
      maturityDate                |-> [i \in 1 .. 4 |-> 0],
      currency                    |-> [i \in 1 .. 3 |-> 0],
      etpName                     |-> << >> ]

(* Etp Directory And Daily Valuation Message at zero, then each field in turn at the values it is checked at *)
CheckedEtpDirectoryAndDailyValuationMessage ==
    { ZeroEtpDirectoryAndDailyValuationMessage }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.industryMic = one] : one \in Sample(4) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.etpTradingSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.etpIpvSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.schedule = one] : one \in Sample(3) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.frequency = one] : one \in Sample(4) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.state = one] : one \in Sample(1) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.navSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.nav = one] : one \in Sample(8) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.estimatedCashPerCuSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.ecu = one] : one \in Sample(8) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.totalCashPerCuSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.totalCashPerCu = one] : one \in Sample(8) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.estimatedCashPerShareSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.ecs = one] : one \in Sample(8) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.tsoSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.tsoOutstanding = one] : one \in Sample(8) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.effectiveDate = one] : one \in Sample(4) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.coupon = one] : one \in Sample(8) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroEtpDirectoryAndDailyValuationMessage EXCEPT !.etpName = one] : one \in SampleBytes }

(***************************************************************************)
(* Etp Intra Day Valuation Message: 34 bytes                               *)
(***************************************************************************)

EtpIntraDayValuationMessage ==
    [ nanoseconds          : Sample(4),
      financialProductType : Sample(1),
      ipvSymbol            : Sample(18),
      ipvValue             : Sample(8),
      currency             : Sample(3) ]

EncodeEtpIntraDayValuationMessage(message) ==
    message.nanoseconds
        \o message.financialProductType
        \o message.ipvSymbol
        \o message.ipvValue
        \o message.currency

DecodeEtpIntraDayValuationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(nanoseconds.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET ipvSymbol == ReadBytes(financialProductType.rest, 18) IN IF ~ipvSymbol.ok THEN Fail ELSE
    LET ipvValue == ReadBytes(ipvSymbol.rest, 8) IN IF ~ipvValue.ok THEN Fail ELSE
    LET currency == ReadBytes(ipvValue.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         financialProductType |-> financialProductType.value,
         ipvSymbol            |-> ipvSymbol.value,
         ipvValue             |-> ipvValue.value,
         currency             |-> currency.value ], currency.rest)

ZeroEtpIntraDayValuationMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      financialProductType |-> [i \in 1 .. 1 |-> 0],
      ipvSymbol            |-> [i \in 1 .. 18 |-> 0],
      ipvValue             |-> [i \in 1 .. 8 |-> 0],
      currency             |-> [i \in 1 .. 3 |-> 0] ]

(* Etp Intra Day Valuation Message at zero, then each field in turn at the values it is checked at *)
CheckedEtpIntraDayValuationMessage ==
    { ZeroEtpIntraDayValuationMessage }
        \cup { [ZeroEtpIntraDayValuationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEtpIntraDayValuationMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroEtpIntraDayValuationMessage EXCEPT !.ipvSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpIntraDayValuationMessage EXCEPT !.ipvValue = one] : one \in Sample(8) }
        \cup { [ZeroEtpIntraDayValuationMessage EXCEPT !.currency = one] : one \in Sample(3) }

(***************************************************************************)
(* Etp Summary Message: 73 bytes                                           *)
(***************************************************************************)

EtpSummaryMessage ==
    [ nanoseconds          : Sample(4),
      financialProductType : Sample(1),
      summaryType          : Sample(3),
      ipvOrIivSymbol       : Sample(18),
      sodValue             : Sample(8),
      high                 : Sample(8),
      low                  : Sample(8),
      eodValue             : Sample(8),
      netChange            : Sample(8),
      effectiveDate        : Sample(4),
      currency             : Sample(3) ]

EncodeEtpSummaryMessage(message) ==
    message.nanoseconds
        \o message.financialProductType
        \o message.summaryType
        \o message.ipvOrIivSymbol
        \o message.sodValue
        \o message.high
        \o message.low
        \o message.eodValue
        \o message.netChange
        \o message.effectiveDate
        \o message.currency

DecodeEtpSummaryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET financialProductType == ReadBytes(nanoseconds.rest, 1) IN IF ~financialProductType.ok THEN Fail ELSE
    LET summaryType == ReadBytes(financialProductType.rest, 3) IN IF ~summaryType.ok THEN Fail ELSE
    LET ipvOrIivSymbol == ReadBytes(summaryType.rest, 18) IN IF ~ipvOrIivSymbol.ok THEN Fail ELSE
    LET sodValue == ReadBytes(ipvOrIivSymbol.rest, 8) IN IF ~sodValue.ok THEN Fail ELSE
    LET high == ReadBytes(sodValue.rest, 8) IN IF ~high.ok THEN Fail ELSE
    LET low == ReadBytes(high.rest, 8) IN IF ~low.ok THEN Fail ELSE
    LET eodValue == ReadBytes(low.rest, 8) IN IF ~eodValue.ok THEN Fail ELSE
    LET netChange == ReadBytes(eodValue.rest, 8) IN IF ~netChange.ok THEN Fail ELSE
    LET effectiveDate == ReadBytes(netChange.rest, 4) IN IF ~effectiveDate.ok THEN Fail ELSE
    LET currency == ReadBytes(effectiveDate.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         financialProductType |-> financialProductType.value,
         summaryType          |-> summaryType.value,
         ipvOrIivSymbol       |-> ipvOrIivSymbol.value,
         sodValue             |-> sodValue.value,
         high                 |-> high.value,
         low                  |-> low.value,
         eodValue             |-> eodValue.value,
         netChange            |-> netChange.value,
         effectiveDate        |-> effectiveDate.value,
         currency             |-> currency.value ], currency.rest)

ZeroEtpSummaryMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      financialProductType |-> [i \in 1 .. 1 |-> 0],
      summaryType          |-> [i \in 1 .. 3 |-> 0],
      ipvOrIivSymbol       |-> [i \in 1 .. 18 |-> 0],
      sodValue             |-> [i \in 1 .. 8 |-> 0],
      high                 |-> [i \in 1 .. 8 |-> 0],
      low                  |-> [i \in 1 .. 8 |-> 0],
      eodValue             |-> [i \in 1 .. 8 |-> 0],
      netChange            |-> [i \in 1 .. 8 |-> 0],
      effectiveDate        |-> [i \in 1 .. 4 |-> 0],
      currency             |-> [i \in 1 .. 3 |-> 0] ]

(* Etp Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEtpSummaryMessage ==
    { ZeroEtpSummaryMessage }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.financialProductType = one] : one \in Sample(1) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.summaryType = one] : one \in Sample(3) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.ipvOrIivSymbol = one] : one \in Sample(18) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.sodValue = one] : one \in Sample(8) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.high = one] : one \in Sample(8) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.low = one] : one \in Sample(8) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.eodValue = one] : one \in Sample(8) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.netChange = one] : one \in Sample(8) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.effectiveDate = one] : one \in Sample(4) }
        \cup { [ZeroEtpSummaryMessage EXCEPT !.currency = one] : one \in Sample(3) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimestampSecondsMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
IndexDirectoryMessageCode == 82  \* "R"
IssueSymbolParticipationMessageCode == 80  \* "P"
IntradayIndexValueMessageCode == 73  \* "I"
SettlementValueMessageCode == 65  \* "A"
EquitiesSummaryMessageCode == 70  \* "F"
FixedIncomeSummaryMessageCode == 66  \* "B"
CommoditySummaryMessageCode == 67  \* "C"
EtpDirectoryAndDailyValuationMessageCode == 68  \* "D"
EtpIntraDayValuationMessageCode == 69  \* "E"
EtpSummaryMessageCode == 86  \* "V"

Payload ==
    [ tag : {TimestampSecondsMessageCode}, body : TimestampSecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {IndexDirectoryMessageCode}, body : IndexDirectoryMessage ]
        \cup [ tag : {IssueSymbolParticipationMessageCode}, body : IssueSymbolParticipationMessage ]
        \cup [ tag : {IntradayIndexValueMessageCode}, body : IntradayIndexValueMessage ]
        \cup [ tag : {SettlementValueMessageCode}, body : SettlementValueMessage ]
        \cup [ tag : {EquitiesSummaryMessageCode}, body : EquitiesSummaryMessage ]
        \cup [ tag : {FixedIncomeSummaryMessageCode}, body : FixedIncomeSummaryMessage ]
        \cup [ tag : {CommoditySummaryMessageCode}, body : CommoditySummaryMessage ]
        \cup [ tag : {EtpDirectoryAndDailyValuationMessageCode}, body : EtpDirectoryAndDailyValuationMessage ]
        \cup [ tag : {EtpIntraDayValuationMessageCode}, body : EtpIntraDayValuationMessage ]
        \cup [ tag : {EtpSummaryMessageCode}, body : EtpSummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = TimestampSecondsMessageCode -> EncodeTimestampSecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = IndexDirectoryMessageCode -> EncodeIndexDirectoryMessage(message.body)
      [] message.tag = IssueSymbolParticipationMessageCode -> EncodeIssueSymbolParticipationMessage(message.body)
      [] message.tag = IntradayIndexValueMessageCode -> EncodeIntradayIndexValueMessage(message.body)
      [] message.tag = SettlementValueMessageCode -> EncodeSettlementValueMessage(message.body)
      [] message.tag = EquitiesSummaryMessageCode -> EncodeEquitiesSummaryMessage(message.body)
      [] message.tag = FixedIncomeSummaryMessageCode -> EncodeFixedIncomeSummaryMessage(message.body)
      [] message.tag = CommoditySummaryMessageCode -> EncodeCommoditySummaryMessage(message.body)
      [] message.tag = EtpDirectoryAndDailyValuationMessageCode -> EncodeEtpDirectoryAndDailyValuationMessage(message.body)
      [] message.tag = EtpIntraDayValuationMessageCode -> EncodeEtpIntraDayValuationMessage(message.body)
      [] message.tag = EtpSummaryMessageCode -> EncodeEtpSummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimestampSecondsMessageCode -> DecodeTimestampSecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = IndexDirectoryMessageCode -> DecodeIndexDirectoryMessage(bytes)
              [] tag = IssueSymbolParticipationMessageCode -> DecodeIssueSymbolParticipationMessage(bytes)
              [] tag = IntradayIndexValueMessageCode -> DecodeIntradayIndexValueMessage(bytes)
              [] tag = SettlementValueMessageCode -> DecodeSettlementValueMessage(bytes)
              [] tag = EquitiesSummaryMessageCode -> DecodeEquitiesSummaryMessage(bytes)
              [] tag = FixedIncomeSummaryMessageCode -> DecodeFixedIncomeSummaryMessage(bytes)
              [] tag = CommoditySummaryMessageCode -> DecodeCommoditySummaryMessage(bytes)
              [] tag = EtpDirectoryAndDailyValuationMessageCode -> DecodeEtpDirectoryAndDailyValuationMessage(bytes)
              [] tag = EtpIntraDayValuationMessageCode -> DecodeEtpIntraDayValuationMessage(bytes)
              [] tag = EtpSummaryMessageCode -> DecodeEtpSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimestampSecondsMessageCode, body |-> ZeroTimestampSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimestampSecondsMessageCode, body |-> one] : one \in CheckedTimestampSecondsMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> IndexDirectoryMessageCode, body |-> one] : one \in CheckedIndexDirectoryMessage }
        \cup { [tag |-> IssueSymbolParticipationMessageCode, body |-> one] : one \in CheckedIssueSymbolParticipationMessage }
        \cup { [tag |-> IntradayIndexValueMessageCode, body |-> one] : one \in CheckedIntradayIndexValueMessage }
        \cup { [tag |-> SettlementValueMessageCode, body |-> one] : one \in CheckedSettlementValueMessage }
        \cup { [tag |-> EquitiesSummaryMessageCode, body |-> one] : one \in CheckedEquitiesSummaryMessage }
        \cup { [tag |-> FixedIncomeSummaryMessageCode, body |-> one] : one \in CheckedFixedIncomeSummaryMessage }
        \cup { [tag |-> CommoditySummaryMessageCode, body |-> one] : one \in CheckedCommoditySummaryMessage }
        \cup { [tag |-> EtpDirectoryAndDailyValuationMessageCode, body |-> one] : one \in CheckedEtpDirectoryAndDailyValuationMessage }
        \cup { [tag |-> EtpIntraDayValuationMessageCode, body |-> one] : one \in CheckedEtpIntraDayValuationMessage }
        \cup { [tag |-> EtpSummaryMessageCode, body |-> one] : one \in CheckedEtpSummaryMessage }

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
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimestampSecondsMessageCode, body |-> ZeroTimestampSecondsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexDirectoryMessageCode, body |-> ZeroIndexDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IssueSymbolParticipationMessageCode, body |-> ZeroIssueSymbolParticipationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IntradayIndexValueMessageCode, body |-> ZeroIntradayIndexValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SettlementValueMessageCode, body |-> ZeroSettlementValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EquitiesSummaryMessageCode, body |-> ZeroEquitiesSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FixedIncomeSummaryMessageCode, body |-> ZeroFixedIncomeSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CommoditySummaryMessageCode, body |-> ZeroCommoditySummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EtpDirectoryAndDailyValuationMessageCode, body |-> ZeroEtpDirectoryAndDailyValuationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EtpIntraDayValuationMessageCode, body |-> ZeroEtpIntraDayValuationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EtpSummaryMessageCode, body |-> ZeroEtpSummaryMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
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

(* Every Timestamp Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestampSecondsMessage ==
    \A message \in CheckedTimestampSecondsMessage :
        LET read == DecodeTimestampSecondsMessage(EncodeTimestampSecondsMessage(message))
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

(* Every Index Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexDirectoryMessage ==
    \A message \in CheckedIndexDirectoryMessage :
        LET read == DecodeIndexDirectoryMessage(EncodeIndexDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issue Symbol Participation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueSymbolParticipationMessage ==
    \A message \in CheckedIssueSymbolParticipationMessage :
        LET read == DecodeIssueSymbolParticipationMessage(EncodeIssueSymbolParticipationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Intraday Index Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIntradayIndexValueMessage ==
    \A message \in CheckedIntradayIndexValueMessage :
        LET read == DecodeIntradayIndexValueMessage(EncodeIntradayIndexValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Settlement Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementValueMessage ==
    \A message \in CheckedSettlementValueMessage :
        LET read == DecodeSettlementValueMessage(EncodeSettlementValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equities Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquitiesSummaryMessage ==
    \A message \in CheckedEquitiesSummaryMessage :
        LET read == DecodeEquitiesSummaryMessage(EncodeEquitiesSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fixed Income Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFixedIncomeSummaryMessage ==
    \A message \in CheckedFixedIncomeSummaryMessage :
        LET read == DecodeFixedIncomeSummaryMessage(EncodeFixedIncomeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Commodity Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCommoditySummaryMessage ==
    \A message \in CheckedCommoditySummaryMessage :
        LET read == DecodeCommoditySummaryMessage(EncodeCommoditySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etp Directory And Daily Valuation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtpDirectoryAndDailyValuationMessage ==
    \A message \in CheckedEtpDirectoryAndDailyValuationMessage :
        LET read == DecodeEtpDirectoryAndDailyValuationMessage(EncodeEtpDirectoryAndDailyValuationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etp Intra Day Valuation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtpIntraDayValuationMessage ==
    \A message \in CheckedEtpIntraDayValuationMessage :
        LET read == DecodeEtpIntraDayValuationMessage(EncodeEtpIntraDayValuationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Etp Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEtpSummaryMessage ==
    \A message \in CheckedEtpSummaryMessage :
        LET read == DecodeEtpSummaryMessage(EncodeEtpSummaryMessage(message))
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
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
