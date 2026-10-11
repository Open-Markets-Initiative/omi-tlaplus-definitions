------------------ MODULE Cme_Globex_Settlements_v7_0_Tcp ------------------
(***************************************************************************)
(* CME Group Settlements v7.0                                              *)
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
(* Note: Settl Price Type is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
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
(* Technical Header: 14 bytes                                              *)
(***************************************************************************)

TechnicalHeader ==
    [ encodingType          : Sample(2),
      messageSequenceNumber : Sample(4),
      tcpSendingTime        : Sample(8) ]

EncodeTechnicalHeader(message) ==
    message.encodingType
        \o message.messageSequenceNumber
        \o message.tcpSendingTime

DecodeTechnicalHeader(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET messageSequenceNumber == ReadBytes(encodingType.rest, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET tcpSendingTime == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~tcpSendingTime.ok THEN Fail ELSE
    Ok([ encodingType          |-> encodingType.value,
         messageSequenceNumber |-> messageSequenceNumber.value,
         tcpSendingTime        |-> tcpSendingTime.value ], tcpSendingTime.rest)

ZeroTechnicalHeader ==
    [ encodingType          |-> [i \in 1 .. 2 |-> 0],
      messageSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      tcpSendingTime        |-> [i \in 1 .. 8 |-> 0] ]

(* Technical Header at zero, then each field in turn at the values it is checked at *)
CheckedTechnicalHeader ==
    { ZeroTechnicalHeader }
        \cup { [ZeroTechnicalHeader EXCEPT !.encodingType = one] : one \in Sample(2) }
        \cup { [ZeroTechnicalHeader EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTechnicalHeader EXCEPT !.tcpSendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear ==
    { ZeroMaturityMonthYear }
        \cup { [ZeroMaturityMonthYear EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Strike Price: 9 bytes                                                   *)
(***************************************************************************)

StrikePrice ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeStrikePrice(message) ==
    message.mantissa
        \o message.exponent

DecodeStrikePrice(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroStrikePrice ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Strike Price at zero, then each field in turn at the values it is checked at *)
CheckedStrikePrice ==
    { ZeroStrikePrice }
        \cup { [ZeroStrikePrice EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroStrikePrice EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Maturity Month Year: 5 bytes                                 *)
(***************************************************************************)

UnderlyingMaturityMonthYear ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeUnderlyingMaturityMonthYear(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeUnderlyingMaturityMonthYear(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroUnderlyingMaturityMonthYear ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingMaturityMonthYear ==
    { ZeroUnderlyingMaturityMonthYear }
        \cup { [ZeroUnderlyingMaturityMonthYear EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingMaturityMonthYear EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Formatted Last Px: 9 bytes                                              *)
(***************************************************************************)

FormattedLastPx ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeFormattedLastPx(message) ==
    message.mantissa
        \o message.exponent

DecodeFormattedLastPx(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroFormattedLastPx ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Formatted Last Px at zero, then each field in turn at the values it is checked at *)
CheckedFormattedLastPx ==
    { ZeroFormattedLastPx }
        \cup { [ZeroFormattedLastPx EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFormattedLastPx EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Incremental Refresh Settle Group: 182 bytes                             *)
(***************************************************************************)

IncrementalRefreshSettleGroup ==
    [ mdUpdateAction                : Sample(1),
      mdEntryType                   : Sample(1),
      productGuid                   : Sample(8),
      clearingProductCode           : Sample(12),
      securityType                  : Sample(6),
      securityExchange              : Sample(8),
      maturityMonthYear             : MaturityMonthYear,
      putOrCall                     : Sample(1),
      strikePrice                   : StrikePrice,
      underlyingProductGuid         : Sample(8),
      underlyingClearingProductCode : Sample(12),
      underlyingSecurityType        : Sample(6),
      underlyingSecurityExchange    : Sample(8),
      underlyingMaturityMonthYear   : UnderlyingMaturityMonthYear,
      symbol                        : Sample(20),
      instrumentGuid                : Sample(8),
      securityId                    : Sample(4),
      formattedLastPx               : FormattedLastPx,
      mdEntryPx                     : Sample(8),
      settlPriceType                : Sample(1),
      tradingReferenceDate          : Sample(2),
      mdStatisticDesc               : Sample(40) ]

EncodeIncrementalRefreshSettleGroup(message) ==
    message.mdUpdateAction
        \o message.mdEntryType
        \o message.productGuid
        \o message.clearingProductCode
        \o message.securityType
        \o message.securityExchange
        \o EncodeMaturityMonthYear(message.maturityMonthYear)
        \o message.putOrCall
        \o EncodeStrikePrice(message.strikePrice)
        \o message.underlyingProductGuid
        \o message.underlyingClearingProductCode
        \o message.underlyingSecurityType
        \o message.underlyingSecurityExchange
        \o EncodeUnderlyingMaturityMonthYear(message.underlyingMaturityMonthYear)
        \o message.symbol
        \o message.instrumentGuid
        \o message.securityId
        \o EncodeFormattedLastPx(message.formattedLastPx)
        \o message.mdEntryPx
        \o message.settlPriceType
        \o message.tradingReferenceDate
        \o message.mdStatisticDesc

DecodeIncrementalRefreshSettleGroup(bytes) ==
    LET mdUpdateAction == ReadBytes(bytes, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET productGuid == ReadBytes(mdEntryType.rest, 8) IN IF ~productGuid.ok THEN Fail ELSE
    LET clearingProductCode == ReadBytes(productGuid.rest, 12) IN IF ~clearingProductCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(clearingProductCode.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(securityType.rest, 8) IN IF ~securityExchange.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear(securityExchange.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(maturityMonthYear.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == DecodeStrikePrice(putOrCall.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET underlyingProductGuid == ReadBytes(strikePrice.rest, 8) IN IF ~underlyingProductGuid.ok THEN Fail ELSE
    LET underlyingClearingProductCode == ReadBytes(underlyingProductGuid.rest, 12) IN IF ~underlyingClearingProductCode.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingClearingProductCode.rest, 6) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingSecurityExchange == ReadBytes(underlyingSecurityType.rest, 8) IN IF ~underlyingSecurityExchange.ok THEN Fail ELSE
    LET underlyingMaturityMonthYear == DecodeUnderlyingMaturityMonthYear(underlyingSecurityExchange.rest) IN IF ~underlyingMaturityMonthYear.ok THEN Fail ELSE
    LET symbol == ReadBytes(underlyingMaturityMonthYear.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(symbol.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(instrumentGuid.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET formattedLastPx == DecodeFormattedLastPx(securityId.rest) IN IF ~formattedLastPx.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(formattedLastPx.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(mdEntryPx.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(settlPriceType.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET mdStatisticDesc == ReadBytes(tradingReferenceDate.rest, 40) IN IF ~mdStatisticDesc.ok THEN Fail ELSE
    Ok([ mdUpdateAction                |-> mdUpdateAction.value,
         mdEntryType                   |-> mdEntryType.value,
         productGuid                   |-> productGuid.value,
         clearingProductCode           |-> clearingProductCode.value,
         securityType                  |-> securityType.value,
         securityExchange              |-> securityExchange.value,
         maturityMonthYear             |-> maturityMonthYear.value,
         putOrCall                     |-> putOrCall.value,
         strikePrice                   |-> strikePrice.value,
         underlyingProductGuid         |-> underlyingProductGuid.value,
         underlyingClearingProductCode |-> underlyingClearingProductCode.value,
         underlyingSecurityType        |-> underlyingSecurityType.value,
         underlyingSecurityExchange    |-> underlyingSecurityExchange.value,
         underlyingMaturityMonthYear   |-> underlyingMaturityMonthYear.value,
         symbol                        |-> symbol.value,
         instrumentGuid                |-> instrumentGuid.value,
         securityId                    |-> securityId.value,
         formattedLastPx               |-> formattedLastPx.value,
         mdEntryPx                     |-> mdEntryPx.value,
         settlPriceType                |-> settlPriceType.value,
         tradingReferenceDate          |-> tradingReferenceDate.value,
         mdStatisticDesc               |-> mdStatisticDesc.value ], mdStatisticDesc.rest)

ZeroIncrementalRefreshSettleGroup ==
    [ mdUpdateAction                |-> [i \in 1 .. 1 |-> 0],
      mdEntryType                   |-> [i \in 1 .. 1 |-> 0],
      productGuid                   |-> [i \in 1 .. 8 |-> 0],
      clearingProductCode           |-> [i \in 1 .. 12 |-> 0],
      securityType                  |-> [i \in 1 .. 6 |-> 0],
      securityExchange              |-> [i \in 1 .. 8 |-> 0],
      maturityMonthYear             |-> ZeroMaturityMonthYear,
      putOrCall                     |-> [i \in 1 .. 1 |-> 0],
      strikePrice                   |-> ZeroStrikePrice,
      underlyingProductGuid         |-> [i \in 1 .. 8 |-> 0],
      underlyingClearingProductCode |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityType        |-> [i \in 1 .. 6 |-> 0],
      underlyingSecurityExchange    |-> [i \in 1 .. 8 |-> 0],
      underlyingMaturityMonthYear   |-> ZeroUnderlyingMaturityMonthYear,
      symbol                        |-> [i \in 1 .. 20 |-> 0],
      instrumentGuid                |-> [i \in 1 .. 8 |-> 0],
      securityId                    |-> [i \in 1 .. 4 |-> 0],
      formattedLastPx               |-> ZeroFormattedLastPx,
      mdEntryPx                     |-> [i \in 1 .. 8 |-> 0],
      settlPriceType                |-> [i \in 1 .. 1 |-> 0],
      tradingReferenceDate          |-> [i \in 1 .. 2 |-> 0],
      mdStatisticDesc               |-> [i \in 1 .. 40 |-> 0] ]

(* Incremental Refresh Settle Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshSettleGroup ==
    { ZeroIncrementalRefreshSettleGroup }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.productGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.clearingProductCode = one] : one \in Sample(12) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.securityExchange = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.strikePrice = one] : one \in CheckedStrikePrice }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.underlyingProductGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.underlyingClearingProductCode = one] : one \in Sample(12) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.underlyingSecurityType = one] : one \in Sample(6) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.underlyingSecurityExchange = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.underlyingMaturityMonthYear = one] : one \in CheckedUnderlyingMaturityMonthYear }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.formattedLastPx = one] : one \in CheckedFormattedLastPx }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.settlPriceType = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshSettleGroup EXCEPT !.mdStatisticDesc = one] : one \in Sample(40) }

(* A run of Incremental Refresh Settle Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshSettleGroupList(_)
EncodeIncrementalRefreshSettleGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshSettleGroup(Head(messages)) \o EncodeIncrementalRefreshSettleGroupList(Tail(messages))

(* As many Incremental Refresh Settle Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshSettleGroupList(_, _)
ReadIncrementalRefreshSettleGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshSettleGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshSettleGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Settle Group of each kind, for the lists that carry them *)
OneIncrementalRefreshSettleGroup == { ZeroIncrementalRefreshSettleGroup }

(***************************************************************************)
(* Incremental Refresh Settle Groups                                       *)
(***************************************************************************)

IncrementalRefreshSettleGroups ==
    [ blockLength                   : Sample(2),
      incrementalRefreshSettleGroup : SampleLists(OneIncrementalRefreshSettleGroup) ]

EncodeIncrementalRefreshSettleGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshSettleGroup), 1)
        \o EncodeIncrementalRefreshSettleGroupList(message.incrementalRefreshSettleGroup)

DecodeIncrementalRefreshSettleGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshSettleGroup == ReadIncrementalRefreshSettleGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshSettleGroup.ok THEN Fail ELSE
    Ok([ blockLength                   |-> blockLength.value,
         incrementalRefreshSettleGroup |-> incrementalRefreshSettleGroup.value ], incrementalRefreshSettleGroup.rest)

ZeroIncrementalRefreshSettleGroups ==
    [ blockLength                   |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshSettleGroup |-> << >> ]

(* Incremental Refresh Settle Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshSettleGroups ==
    { ZeroIncrementalRefreshSettleGroups }
        \cup { [ZeroIncrementalRefreshSettleGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshSettleGroups EXCEPT !.incrementalRefreshSettleGroup = one] : one \in SampleLists(OneIncrementalRefreshSettleGroup) }

(***************************************************************************)
(* Md Incremental Refresh Settle                                           *)
(***************************************************************************)

MdIncrementalRefreshSettle ==
    [ transactTime                   : Sample(8),
      incrementalRefreshSettleGroups : IncrementalRefreshSettleGroups ]

EncodeMdIncrementalRefreshSettle(message) ==
    message.transactTime
        \o EncodeIncrementalRefreshSettleGroups(message.incrementalRefreshSettleGroups)

DecodeMdIncrementalRefreshSettle(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET incrementalRefreshSettleGroups == DecodeIncrementalRefreshSettleGroups(transactTime.rest) IN IF ~incrementalRefreshSettleGroups.ok THEN Fail ELSE
    Ok([ transactTime                   |-> transactTime.value,
         incrementalRefreshSettleGroups |-> incrementalRefreshSettleGroups.value ], incrementalRefreshSettleGroups.rest)

ZeroMdIncrementalRefreshSettle ==
    [ transactTime                   |-> [i \in 1 .. 8 |-> 0],
      incrementalRefreshSettleGroups |-> ZeroIncrementalRefreshSettleGroups ]

(* Md Incremental Refresh Settle at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshSettle ==
    { ZeroMdIncrementalRefreshSettle }
        \cup { [ZeroMdIncrementalRefreshSettle EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshSettle EXCEPT !.incrementalRefreshSettleGroups = one] : one \in CheckedIncrementalRefreshSettleGroups }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear2 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear2(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear2 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear2 ==
    { ZeroMaturityMonthYear2 }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Strike Price: 9 bytes                                                   *)
(***************************************************************************)

StrikePrice2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeStrikePrice2(message) ==
    message.mantissa
        \o message.exponent

DecodeStrikePrice2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroStrikePrice2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Strike Price at zero, then each field in turn at the values it is checked at *)
CheckedStrikePrice2 ==
    { ZeroStrikePrice2 }
        \cup { [ZeroStrikePrice2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroStrikePrice2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Maturity Month Year: 5 bytes                                 *)
(***************************************************************************)

UnderlyingMaturityMonthYear2 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeUnderlyingMaturityMonthYear2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeUnderlyingMaturityMonthYear2(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroUnderlyingMaturityMonthYear2 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingMaturityMonthYear2 ==
    { ZeroUnderlyingMaturityMonthYear2 }
        \cup { [ZeroUnderlyingMaturityMonthYear2 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingMaturityMonthYear2 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear2 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear2 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Incremental Refresh Voi Group: 131 bytes                                *)
(***************************************************************************)

IncrementalRefreshVoiGroup ==
    [ productGuid                   : Sample(8),
      clearingProductCode           : Sample(12),
      securityType                  : Sample(6),
      securityExchange              : Sample(8),
      maturityMonthYear             : MaturityMonthYear2,
      putOrCall                     : Sample(1),
      strikePrice                   : StrikePrice2,
      underlyingProductGuid         : Sample(8),
      underlyingClearingProductCode : Sample(12),
      underlyingSecurityType        : Sample(6),
      underlyingSecurityExchange    : Sample(8),
      underlyingMaturityMonthYear   : UnderlyingMaturityMonthYear2,
      symbol                        : Sample(20),
      instrumentGuid                : Sample(8),
      securityId                    : Sample(4),
      clearedVolume                 : Sample(4),
      openInterestQty               : Sample(4),
      openCloseSettlFlag            : Sample(1),
      tradingReferenceDate          : Sample(2) ]

EncodeIncrementalRefreshVoiGroup(message) ==
    message.productGuid
        \o message.clearingProductCode
        \o message.securityType
        \o message.securityExchange
        \o EncodeMaturityMonthYear2(message.maturityMonthYear)
        \o message.putOrCall
        \o EncodeStrikePrice2(message.strikePrice)
        \o message.underlyingProductGuid
        \o message.underlyingClearingProductCode
        \o message.underlyingSecurityType
        \o message.underlyingSecurityExchange
        \o EncodeUnderlyingMaturityMonthYear2(message.underlyingMaturityMonthYear)
        \o message.symbol
        \o message.instrumentGuid
        \o message.securityId
        \o message.clearedVolume
        \o message.openInterestQty
        \o message.openCloseSettlFlag
        \o message.tradingReferenceDate

DecodeIncrementalRefreshVoiGroup(bytes) ==
    LET productGuid == ReadBytes(bytes, 8) IN IF ~productGuid.ok THEN Fail ELSE
    LET clearingProductCode == ReadBytes(productGuid.rest, 12) IN IF ~clearingProductCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(clearingProductCode.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(securityType.rest, 8) IN IF ~securityExchange.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear2(securityExchange.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(maturityMonthYear.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == DecodeStrikePrice2(putOrCall.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET underlyingProductGuid == ReadBytes(strikePrice.rest, 8) IN IF ~underlyingProductGuid.ok THEN Fail ELSE
    LET underlyingClearingProductCode == ReadBytes(underlyingProductGuid.rest, 12) IN IF ~underlyingClearingProductCode.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingClearingProductCode.rest, 6) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingSecurityExchange == ReadBytes(underlyingSecurityType.rest, 8) IN IF ~underlyingSecurityExchange.ok THEN Fail ELSE
    LET underlyingMaturityMonthYear == DecodeUnderlyingMaturityMonthYear2(underlyingSecurityExchange.rest) IN IF ~underlyingMaturityMonthYear.ok THEN Fail ELSE
    LET symbol == ReadBytes(underlyingMaturityMonthYear.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(symbol.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(instrumentGuid.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET clearedVolume == ReadBytes(securityId.rest, 4) IN IF ~clearedVolume.ok THEN Fail ELSE
    LET openInterestQty == ReadBytes(clearedVolume.rest, 4) IN IF ~openInterestQty.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(openInterestQty.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(openCloseSettlFlag.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    Ok([ productGuid                   |-> productGuid.value,
         clearingProductCode           |-> clearingProductCode.value,
         securityType                  |-> securityType.value,
         securityExchange              |-> securityExchange.value,
         maturityMonthYear             |-> maturityMonthYear.value,
         putOrCall                     |-> putOrCall.value,
         strikePrice                   |-> strikePrice.value,
         underlyingProductGuid         |-> underlyingProductGuid.value,
         underlyingClearingProductCode |-> underlyingClearingProductCode.value,
         underlyingSecurityType        |-> underlyingSecurityType.value,
         underlyingSecurityExchange    |-> underlyingSecurityExchange.value,
         underlyingMaturityMonthYear   |-> underlyingMaturityMonthYear.value,
         symbol                        |-> symbol.value,
         instrumentGuid                |-> instrumentGuid.value,
         securityId                    |-> securityId.value,
         clearedVolume                 |-> clearedVolume.value,
         openInterestQty               |-> openInterestQty.value,
         openCloseSettlFlag            |-> openCloseSettlFlag.value,
         tradingReferenceDate          |-> tradingReferenceDate.value ], tradingReferenceDate.rest)

ZeroIncrementalRefreshVoiGroup ==
    [ productGuid                   |-> [i \in 1 .. 8 |-> 0],
      clearingProductCode           |-> [i \in 1 .. 12 |-> 0],
      securityType                  |-> [i \in 1 .. 6 |-> 0],
      securityExchange              |-> [i \in 1 .. 8 |-> 0],
      maturityMonthYear             |-> ZeroMaturityMonthYear2,
      putOrCall                     |-> [i \in 1 .. 1 |-> 0],
      strikePrice                   |-> ZeroStrikePrice2,
      underlyingProductGuid         |-> [i \in 1 .. 8 |-> 0],
      underlyingClearingProductCode |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityType        |-> [i \in 1 .. 6 |-> 0],
      underlyingSecurityExchange    |-> [i \in 1 .. 8 |-> 0],
      underlyingMaturityMonthYear   |-> ZeroUnderlyingMaturityMonthYear2,
      symbol                        |-> [i \in 1 .. 20 |-> 0],
      instrumentGuid                |-> [i \in 1 .. 8 |-> 0],
      securityId                    |-> [i \in 1 .. 4 |-> 0],
      clearedVolume                 |-> [i \in 1 .. 4 |-> 0],
      openInterestQty               |-> [i \in 1 .. 4 |-> 0],
      openCloseSettlFlag            |-> [i \in 1 .. 1 |-> 0],
      tradingReferenceDate          |-> [i \in 1 .. 2 |-> 0] ]

(* Incremental Refresh Voi Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshVoiGroup ==
    { ZeroIncrementalRefreshVoiGroup }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.productGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.clearingProductCode = one] : one \in Sample(12) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.securityExchange = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear2 }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.strikePrice = one] : one \in CheckedStrikePrice2 }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.underlyingProductGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.underlyingClearingProductCode = one] : one \in Sample(12) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.underlyingSecurityType = one] : one \in Sample(6) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.underlyingSecurityExchange = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.underlyingMaturityMonthYear = one] : one \in CheckedUnderlyingMaturityMonthYear2 }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.clearedVolume = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.openInterestQty = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshVoiGroup EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }

(* A run of Incremental Refresh Voi Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshVoiGroupList(_)
EncodeIncrementalRefreshVoiGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshVoiGroup(Head(messages)) \o EncodeIncrementalRefreshVoiGroupList(Tail(messages))

(* As many Incremental Refresh Voi Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshVoiGroupList(_, _)
ReadIncrementalRefreshVoiGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshVoiGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshVoiGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Voi Group of each kind, for the lists that carry them *)
OneIncrementalRefreshVoiGroup == { ZeroIncrementalRefreshVoiGroup }

(***************************************************************************)
(* Incremental Refresh Voi Groups                                          *)
(***************************************************************************)

IncrementalRefreshVoiGroups ==
    [ blockLength                : Sample(2),
      incrementalRefreshVoiGroup : SampleLists(OneIncrementalRefreshVoiGroup) ]

EncodeIncrementalRefreshVoiGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshVoiGroup), 1)
        \o EncodeIncrementalRefreshVoiGroupList(message.incrementalRefreshVoiGroup)

DecodeIncrementalRefreshVoiGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshVoiGroup == ReadIncrementalRefreshVoiGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshVoiGroup.ok THEN Fail ELSE
    Ok([ blockLength                |-> blockLength.value,
         incrementalRefreshVoiGroup |-> incrementalRefreshVoiGroup.value ], incrementalRefreshVoiGroup.rest)

ZeroIncrementalRefreshVoiGroups ==
    [ blockLength                |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshVoiGroup |-> << >> ]

(* Incremental Refresh Voi Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshVoiGroups ==
    { ZeroIncrementalRefreshVoiGroups }
        \cup { [ZeroIncrementalRefreshVoiGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshVoiGroups EXCEPT !.incrementalRefreshVoiGroup = one] : one \in SampleLists(OneIncrementalRefreshVoiGroup) }

(***************************************************************************)
(* Md Incremental Refresh Voi                                              *)
(***************************************************************************)

MdIncrementalRefreshVoi ==
    [ transactTime                : Sample(8),
      incrementalRefreshVoiGroups : IncrementalRefreshVoiGroups ]

EncodeMdIncrementalRefreshVoi(message) ==
    message.transactTime
        \o EncodeIncrementalRefreshVoiGroups(message.incrementalRefreshVoiGroups)

DecodeMdIncrementalRefreshVoi(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET incrementalRefreshVoiGroups == DecodeIncrementalRefreshVoiGroups(transactTime.rest) IN IF ~incrementalRefreshVoiGroups.ok THEN Fail ELSE
    Ok([ transactTime                |-> transactTime.value,
         incrementalRefreshVoiGroups |-> incrementalRefreshVoiGroups.value ], incrementalRefreshVoiGroups.rest)

ZeroMdIncrementalRefreshVoi ==
    [ transactTime                |-> [i \in 1 .. 8 |-> 0],
      incrementalRefreshVoiGroups |-> ZeroIncrementalRefreshVoiGroups ]

(* Md Incremental Refresh Voi at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshVoi ==
    { ZeroMdIncrementalRefreshVoi }
        \cup { [ZeroMdIncrementalRefreshVoi EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshVoi EXCEPT !.incrementalRefreshVoiGroups = one] : one \in CheckedIncrementalRefreshVoiGroups }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear3 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear3(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear3 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear3 ==
    { ZeroMaturityMonthYear3 }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Strike Price: 9 bytes                                                   *)
(***************************************************************************)

StrikePrice3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeStrikePrice3(message) ==
    message.mantissa
        \o message.exponent

DecodeStrikePrice3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroStrikePrice3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Strike Price at zero, then each field in turn at the values it is checked at *)
CheckedStrikePrice3 ==
    { ZeroStrikePrice3 }
        \cup { [ZeroStrikePrice3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroStrikePrice3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Maturity Month Year: 5 bytes                                 *)
(***************************************************************************)

UnderlyingMaturityMonthYear3 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeUnderlyingMaturityMonthYear3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeUnderlyingMaturityMonthYear3(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroUnderlyingMaturityMonthYear3 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingMaturityMonthYear3 ==
    { ZeroUnderlyingMaturityMonthYear3 }
        \cup { [ZeroUnderlyingMaturityMonthYear3 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingMaturityMonthYear3 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear3 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear3 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Low Px: 9 bytes                                                         *)
(***************************************************************************)

LowPx ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeLowPx(message) ==
    message.mantissa
        \o message.exponent

DecodeLowPx(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroLowPx ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Low Px at zero, then each field in turn at the values it is checked at *)
CheckedLowPx ==
    { ZeroLowPx }
        \cup { [ZeroLowPx EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroLowPx EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* High Px: 9 bytes                                                        *)
(***************************************************************************)

HighPx ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeHighPx(message) ==
    message.mantissa
        \o message.exponent

DecodeHighPx(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroHighPx ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* High Px at zero, then each field in turn at the values it is checked at *)
CheckedHighPx ==
    { ZeroHighPx }
        \cup { [ZeroHighPx EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroHighPx EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Incremental Refresh High Low Group: 142 bytes                           *)
(***************************************************************************)

IncrementalRefreshHighLowGroup ==
    [ productGuid                   : Sample(8),
      clearingProductCode           : Sample(12),
      securityType                  : Sample(6),
      securityExchange              : Sample(8),
      maturityMonthYear             : MaturityMonthYear3,
      putOrCall                     : Sample(1),
      strikePrice                   : StrikePrice3,
      underlyingProductGuid         : Sample(8),
      underlyingClearingProductCode : Sample(12),
      underlyingSecurityType        : Sample(6),
      underlyingSecurityExchange    : Sample(8),
      underlyingMaturityMonthYear   : UnderlyingMaturityMonthYear3,
      symbol                        : Sample(20),
      instrumentGuid                : Sample(8),
      securityId                    : Sample(4),
      lowPx                         : LowPx,
      lowPxInd                      : Sample(1),
      highPx                        : HighPx,
      highPxInd                     : Sample(1),
      tradingReferenceDate          : Sample(2) ]

EncodeIncrementalRefreshHighLowGroup(message) ==
    message.productGuid
        \o message.clearingProductCode
        \o message.securityType
        \o message.securityExchange
        \o EncodeMaturityMonthYear3(message.maturityMonthYear)
        \o message.putOrCall
        \o EncodeStrikePrice3(message.strikePrice)
        \o message.underlyingProductGuid
        \o message.underlyingClearingProductCode
        \o message.underlyingSecurityType
        \o message.underlyingSecurityExchange
        \o EncodeUnderlyingMaturityMonthYear3(message.underlyingMaturityMonthYear)
        \o message.symbol
        \o message.instrumentGuid
        \o message.securityId
        \o EncodeLowPx(message.lowPx)
        \o message.lowPxInd
        \o EncodeHighPx(message.highPx)
        \o message.highPxInd
        \o message.tradingReferenceDate

DecodeIncrementalRefreshHighLowGroup(bytes) ==
    LET productGuid == ReadBytes(bytes, 8) IN IF ~productGuid.ok THEN Fail ELSE
    LET clearingProductCode == ReadBytes(productGuid.rest, 12) IN IF ~clearingProductCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(clearingProductCode.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(securityType.rest, 8) IN IF ~securityExchange.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear3(securityExchange.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(maturityMonthYear.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == DecodeStrikePrice3(putOrCall.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET underlyingProductGuid == ReadBytes(strikePrice.rest, 8) IN IF ~underlyingProductGuid.ok THEN Fail ELSE
    LET underlyingClearingProductCode == ReadBytes(underlyingProductGuid.rest, 12) IN IF ~underlyingClearingProductCode.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingClearingProductCode.rest, 6) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingSecurityExchange == ReadBytes(underlyingSecurityType.rest, 8) IN IF ~underlyingSecurityExchange.ok THEN Fail ELSE
    LET underlyingMaturityMonthYear == DecodeUnderlyingMaturityMonthYear3(underlyingSecurityExchange.rest) IN IF ~underlyingMaturityMonthYear.ok THEN Fail ELSE
    LET symbol == ReadBytes(underlyingMaturityMonthYear.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(symbol.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(instrumentGuid.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET lowPx == DecodeLowPx(securityId.rest) IN IF ~lowPx.ok THEN Fail ELSE
    LET lowPxInd == ReadBytes(lowPx.rest, 1) IN IF ~lowPxInd.ok THEN Fail ELSE
    LET highPx == DecodeHighPx(lowPxInd.rest) IN IF ~highPx.ok THEN Fail ELSE
    LET highPxInd == ReadBytes(highPx.rest, 1) IN IF ~highPxInd.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(highPxInd.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    Ok([ productGuid                   |-> productGuid.value,
         clearingProductCode           |-> clearingProductCode.value,
         securityType                  |-> securityType.value,
         securityExchange              |-> securityExchange.value,
         maturityMonthYear             |-> maturityMonthYear.value,
         putOrCall                     |-> putOrCall.value,
         strikePrice                   |-> strikePrice.value,
         underlyingProductGuid         |-> underlyingProductGuid.value,
         underlyingClearingProductCode |-> underlyingClearingProductCode.value,
         underlyingSecurityType        |-> underlyingSecurityType.value,
         underlyingSecurityExchange    |-> underlyingSecurityExchange.value,
         underlyingMaturityMonthYear   |-> underlyingMaturityMonthYear.value,
         symbol                        |-> symbol.value,
         instrumentGuid                |-> instrumentGuid.value,
         securityId                    |-> securityId.value,
         lowPx                         |-> lowPx.value,
         lowPxInd                      |-> lowPxInd.value,
         highPx                        |-> highPx.value,
         highPxInd                     |-> highPxInd.value,
         tradingReferenceDate          |-> tradingReferenceDate.value ], tradingReferenceDate.rest)

ZeroIncrementalRefreshHighLowGroup ==
    [ productGuid                   |-> [i \in 1 .. 8 |-> 0],
      clearingProductCode           |-> [i \in 1 .. 12 |-> 0],
      securityType                  |-> [i \in 1 .. 6 |-> 0],
      securityExchange              |-> [i \in 1 .. 8 |-> 0],
      maturityMonthYear             |-> ZeroMaturityMonthYear3,
      putOrCall                     |-> [i \in 1 .. 1 |-> 0],
      strikePrice                   |-> ZeroStrikePrice3,
      underlyingProductGuid         |-> [i \in 1 .. 8 |-> 0],
      underlyingClearingProductCode |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityType        |-> [i \in 1 .. 6 |-> 0],
      underlyingSecurityExchange    |-> [i \in 1 .. 8 |-> 0],
      underlyingMaturityMonthYear   |-> ZeroUnderlyingMaturityMonthYear3,
      symbol                        |-> [i \in 1 .. 20 |-> 0],
      instrumentGuid                |-> [i \in 1 .. 8 |-> 0],
      securityId                    |-> [i \in 1 .. 4 |-> 0],
      lowPx                         |-> ZeroLowPx,
      lowPxInd                      |-> [i \in 1 .. 1 |-> 0],
      highPx                        |-> ZeroHighPx,
      highPxInd                     |-> [i \in 1 .. 1 |-> 0],
      tradingReferenceDate          |-> [i \in 1 .. 2 |-> 0] ]

(* Incremental Refresh High Low Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshHighLowGroup ==
    { ZeroIncrementalRefreshHighLowGroup }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.productGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.clearingProductCode = one] : one \in Sample(12) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.securityExchange = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear3 }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.strikePrice = one] : one \in CheckedStrikePrice3 }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.underlyingProductGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.underlyingClearingProductCode = one] : one \in Sample(12) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.underlyingSecurityType = one] : one \in Sample(6) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.underlyingSecurityExchange = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.underlyingMaturityMonthYear = one] : one \in CheckedUnderlyingMaturityMonthYear3 }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.lowPx = one] : one \in CheckedLowPx }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.lowPxInd = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.highPx = one] : one \in CheckedHighPx }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.highPxInd = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshHighLowGroup EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }

(* A run of Incremental Refresh High Low Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshHighLowGroupList(_)
EncodeIncrementalRefreshHighLowGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshHighLowGroup(Head(messages)) \o EncodeIncrementalRefreshHighLowGroupList(Tail(messages))

(* As many Incremental Refresh High Low Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshHighLowGroupList(_, _)
ReadIncrementalRefreshHighLowGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshHighLowGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshHighLowGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh High Low Group of each kind, for the lists that carry them *)
OneIncrementalRefreshHighLowGroup == { ZeroIncrementalRefreshHighLowGroup }

(***************************************************************************)
(* Incremental Refresh High Low Groups                                     *)
(***************************************************************************)

IncrementalRefreshHighLowGroups ==
    [ blockLength                    : Sample(2),
      incrementalRefreshHighLowGroup : SampleLists(OneIncrementalRefreshHighLowGroup) ]

EncodeIncrementalRefreshHighLowGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshHighLowGroup), 1)
        \o EncodeIncrementalRefreshHighLowGroupList(message.incrementalRefreshHighLowGroup)

DecodeIncrementalRefreshHighLowGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshHighLowGroup == ReadIncrementalRefreshHighLowGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshHighLowGroup.ok THEN Fail ELSE
    Ok([ blockLength                    |-> blockLength.value,
         incrementalRefreshHighLowGroup |-> incrementalRefreshHighLowGroup.value ], incrementalRefreshHighLowGroup.rest)

ZeroIncrementalRefreshHighLowGroups ==
    [ blockLength                    |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshHighLowGroup |-> << >> ]

(* Incremental Refresh High Low Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshHighLowGroups ==
    { ZeroIncrementalRefreshHighLowGroups }
        \cup { [ZeroIncrementalRefreshHighLowGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshHighLowGroups EXCEPT !.incrementalRefreshHighLowGroup = one] : one \in SampleLists(OneIncrementalRefreshHighLowGroup) }

(***************************************************************************)
(* Md Incremental Refresh High Low                                         *)
(***************************************************************************)

MdIncrementalRefreshHighLow ==
    [ transactTime                    : Sample(8),
      incrementalRefreshHighLowGroups : IncrementalRefreshHighLowGroups ]

EncodeMdIncrementalRefreshHighLow(message) ==
    message.transactTime
        \o EncodeIncrementalRefreshHighLowGroups(message.incrementalRefreshHighLowGroups)

DecodeMdIncrementalRefreshHighLow(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET incrementalRefreshHighLowGroups == DecodeIncrementalRefreshHighLowGroups(transactTime.rest) IN IF ~incrementalRefreshHighLowGroups.ok THEN Fail ELSE
    Ok([ transactTime                    |-> transactTime.value,
         incrementalRefreshHighLowGroups |-> incrementalRefreshHighLowGroups.value ], incrementalRefreshHighLowGroups.rest)

ZeroMdIncrementalRefreshHighLow ==
    [ transactTime                    |-> [i \in 1 .. 8 |-> 0],
      incrementalRefreshHighLowGroups |-> ZeroIncrementalRefreshHighLowGroups ]

(* Md Incremental Refresh High Low at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshHighLow ==
    { ZeroMdIncrementalRefreshHighLow }
        \cup { [ZeroMdIncrementalRefreshHighLow EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshHighLow EXCEPT !.incrementalRefreshHighLowGroups = one] : one \in CheckedIncrementalRefreshHighLowGroups }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

MdIncrementalRefreshSettleCode == 401  \* 0x191
MdIncrementalRefreshVoiCode == 402  \* 0x192
MdIncrementalRefreshHighLowCode == 403  \* 0x193
AdminHeartbeatCode == 407  \* 0x197

Payload ==
    [ tag : {MdIncrementalRefreshSettleCode}, body : MdIncrementalRefreshSettle ]
        \cup [ tag : {MdIncrementalRefreshVoiCode}, body : MdIncrementalRefreshVoi ]
        \cup [ tag : {MdIncrementalRefreshHighLowCode}, body : MdIncrementalRefreshHighLow ]
        \cup [ tag : {AdminHeartbeatCode}, body : {[empty |-> 0]} ]

EncodePayload(message) ==
    CASE message.tag = MdIncrementalRefreshSettleCode -> EncodeMdIncrementalRefreshSettle(message.body)
      [] message.tag = MdIncrementalRefreshVoiCode -> EncodeMdIncrementalRefreshVoi(message.body)
      [] message.tag = MdIncrementalRefreshHighLowCode -> EncodeMdIncrementalRefreshHighLow(message.body)
      [] message.tag = AdminHeartbeatCode -> << >>

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = MdIncrementalRefreshSettleCode -> DecodeMdIncrementalRefreshSettle(bytes)
              [] tag = MdIncrementalRefreshVoiCode -> DecodeMdIncrementalRefreshVoi(bytes)
              [] tag = MdIncrementalRefreshHighLowCode -> DecodeMdIncrementalRefreshHighLow(bytes)
              [] tag = AdminHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> MdIncrementalRefreshSettleCode, body |-> ZeroMdIncrementalRefreshSettle]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> MdIncrementalRefreshSettleCode, body |-> one] : one \in CheckedMdIncrementalRefreshSettle }
        \cup { [tag |-> MdIncrementalRefreshVoiCode, body |-> one] : one \in CheckedMdIncrementalRefreshVoi }
        \cup { [tag |-> MdIncrementalRefreshHighLowCode, body |-> one] : one \in CheckedMdIncrementalRefreshHighLow }
        \cup { [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Tcp Message, framed by Tcp Message Size                                 *)
(***************************************************************************)

TcpMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeTcpMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Tcp Message Size counts the bytes it frames, so it is written from them *)
EncodeTcpMessage(message) ==
    LET body == EncodeTcpMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeTcpMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

DecodeTcpMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeTcpMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTcpMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Tcp Message at zero, then each field in turn at the values it is checked at *)
CheckedTcpMessage ==
    { ZeroTcpMessage }
        \cup { [ZeroTcpMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTcpMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroTcpMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroTcpMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Tcp Message, written one after another *)
RECURSIVE EncodeTcpMessageList(_)
EncodeTcpMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTcpMessage(Head(messages)) \o EncodeTcpMessageList(Tail(messages))

(* As many Tcp Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTcpMessageAll(_)
ReadTcpMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTcpMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTcpMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tcp Message of each kind, for the lists that carry them *)
OneTcpMessage ==
    { [ZeroTcpMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshSettleCode, body |-> ZeroMdIncrementalRefreshSettle]],
      [ZeroTcpMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshVoiCode, body |-> ZeroMdIncrementalRefreshVoi]],
      [ZeroTcpMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshHighLowCode, body |-> ZeroMdIncrementalRefreshHighLow]],
      [ZeroTcpMessage EXCEPT !.payload = [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Tcp Packet                                                              *)
(***************************************************************************)

TcpPacket ==
    [ technicalHeader : TechnicalHeader,
      tcpMessage      : SampleLists(OneTcpMessage) ]

EncodeTcpPacket(message) ==
    EncodeTechnicalHeader(message.technicalHeader)
        \o EncodeTcpMessageList(message.tcpMessage)

DecodeTcpPacket(bytes) ==
    LET technicalHeader == DecodeTechnicalHeader(bytes) IN IF ~technicalHeader.ok THEN Fail ELSE
    LET tcpMessage == ReadTcpMessageAll(technicalHeader.rest) IN IF ~tcpMessage.ok THEN Fail ELSE
    Ok([ technicalHeader |-> technicalHeader.value,
         tcpMessage      |-> tcpMessage.value ], tcpMessage.rest)

ZeroTcpPacket ==
    [ technicalHeader |-> ZeroTechnicalHeader,
      tcpMessage      |-> << >> ]

(* Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedTcpPacket ==
    { ZeroTcpPacket }
        \cup { [ZeroTcpPacket EXCEPT !.technicalHeader = one] : one \in CheckedTechnicalHeader }
        \cup { [ZeroTcpPacket EXCEPT !.tcpMessage = one] : one \in SampleLists(OneTcpMessage) }

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

(* Every Technical Header decodes back to what was encoded, and leaves nothing over *)
RoundTripTechnicalHeader ==
    \A message \in CheckedTechnicalHeader :
        LET read == DecodeTechnicalHeader(EncodeTechnicalHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear ==
    \A message \in CheckedMaturityMonthYear :
        LET read == DecodeMaturityMonthYear(EncodeMaturityMonthYear(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strike Price decodes back to what was encoded, and leaves nothing over *)
RoundTripStrikePrice ==
    \A message \in CheckedStrikePrice :
        LET read == DecodeStrikePrice(EncodeStrikePrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingMaturityMonthYear ==
    \A message \in CheckedUnderlyingMaturityMonthYear :
        LET read == DecodeUnderlyingMaturityMonthYear(EncodeUnderlyingMaturityMonthYear(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Formatted Last Px decodes back to what was encoded, and leaves nothing over *)
RoundTripFormattedLastPx ==
    \A message \in CheckedFormattedLastPx :
        LET read == DecodeFormattedLastPx(EncodeFormattedLastPx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Settle Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshSettleGroup ==
    \A message \in CheckedIncrementalRefreshSettleGroup :
        LET read == DecodeIncrementalRefreshSettleGroup(EncodeIncrementalRefreshSettleGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Settle Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshSettleGroups ==
    \A message \in CheckedIncrementalRefreshSettleGroups :
        LET read == DecodeIncrementalRefreshSettleGroups(EncodeIncrementalRefreshSettleGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Settle decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshSettle ==
    \A message \in CheckedMdIncrementalRefreshSettle :
        LET read == DecodeMdIncrementalRefreshSettle(EncodeMdIncrementalRefreshSettle(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear2 ==
    \A message \in CheckedMaturityMonthYear2 :
        LET read == DecodeMaturityMonthYear2(EncodeMaturityMonthYear2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strike Price decodes back to what was encoded, and leaves nothing over *)
RoundTripStrikePrice2 ==
    \A message \in CheckedStrikePrice2 :
        LET read == DecodeStrikePrice2(EncodeStrikePrice2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingMaturityMonthYear2 ==
    \A message \in CheckedUnderlyingMaturityMonthYear2 :
        LET read == DecodeUnderlyingMaturityMonthYear2(EncodeUnderlyingMaturityMonthYear2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Voi Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshVoiGroup ==
    \A message \in CheckedIncrementalRefreshVoiGroup :
        LET read == DecodeIncrementalRefreshVoiGroup(EncodeIncrementalRefreshVoiGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Voi Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshVoiGroups ==
    \A message \in CheckedIncrementalRefreshVoiGroups :
        LET read == DecodeIncrementalRefreshVoiGroups(EncodeIncrementalRefreshVoiGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Voi decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshVoi ==
    \A message \in CheckedMdIncrementalRefreshVoi :
        LET read == DecodeMdIncrementalRefreshVoi(EncodeMdIncrementalRefreshVoi(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear3 ==
    \A message \in CheckedMaturityMonthYear3 :
        LET read == DecodeMaturityMonthYear3(EncodeMaturityMonthYear3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strike Price decodes back to what was encoded, and leaves nothing over *)
RoundTripStrikePrice3 ==
    \A message \in CheckedStrikePrice3 :
        LET read == DecodeStrikePrice3(EncodeStrikePrice3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingMaturityMonthYear3 ==
    \A message \in CheckedUnderlyingMaturityMonthYear3 :
        LET read == DecodeUnderlyingMaturityMonthYear3(EncodeUnderlyingMaturityMonthYear3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Low Px decodes back to what was encoded, and leaves nothing over *)
RoundTripLowPx ==
    \A message \in CheckedLowPx :
        LET read == DecodeLowPx(EncodeLowPx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every High Px decodes back to what was encoded, and leaves nothing over *)
RoundTripHighPx ==
    \A message \in CheckedHighPx :
        LET read == DecodeHighPx(EncodeHighPx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh High Low Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshHighLowGroup ==
    \A message \in CheckedIncrementalRefreshHighLowGroup :
        LET read == DecodeIncrementalRefreshHighLowGroup(EncodeIncrementalRefreshHighLowGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh High Low Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshHighLowGroups ==
    \A message \in CheckedIncrementalRefreshHighLowGroups :
        LET read == DecodeIncrementalRefreshHighLowGroups(EncodeIncrementalRefreshHighLowGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh High Low decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshHighLow ==
    \A message \in CheckedMdIncrementalRefreshHighLow :
        LET read == DecodeMdIncrementalRefreshHighLow(EncodeMdIncrementalRefreshHighLow(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpMessage ==
    \A message \in CheckedTcpMessage :
        LET read == DecodeTcpMessage(EncodeTcpMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpPacket ==
    \A message \in CheckedTcpPacket :
        LET read == DecodeTcpPacket(EncodeTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Tcp Message Size is written from the bytes it frames *)
FramesTcpMessage ==
    \A message \in CheckedTcpMessage :
        LET bytes == EncodeTcpMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
