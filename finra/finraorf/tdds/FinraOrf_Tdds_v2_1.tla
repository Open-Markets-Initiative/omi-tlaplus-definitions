------------------------ MODULE FinraOrf_Tdds_v2_1 -------------------------
(***************************************************************************)
(* Financial Industry Regulatory Authority Trade Data Dissemination        *)
(* Service v2.1                                                            *)
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
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime ==
    { ZeroDatetime }
        \cup { [ZeroDatetime EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime ]

EncodeMessageHeader(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime(message.datetime)

DecodeMessageHeader(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader ==
    { ZeroMessageHeader }
        \cup { [ZeroMessageHeader EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader EXCEPT !.datetime = one] : one \in CheckedDatetime }

(***************************************************************************)
(* Trade Report Short Form Message: 53 bytes                               *)
(***************************************************************************)

TradeReportShortFormMessage ==
    [ messageHeader         : MessageHeader,
      securitySymbolShort   : Sample(5),
      saleConditionLevel1   : Sample(1),
      tradePriceDenominator : Sample(1),
      tradePriceShort       : Sample(6),
      reportVolumeShort     : Sample(6),
      priceChangeIndicator  : Sample(1) ]

EncodeTradeReportShortFormMessage(message) ==
    EncodeMessageHeader(message.messageHeader)
        \o message.securitySymbolShort
        \o message.saleConditionLevel1
        \o message.tradePriceDenominator
        \o message.tradePriceShort
        \o message.reportVolumeShort
        \o message.priceChangeIndicator

DecodeTradeReportShortFormMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET securitySymbolShort == ReadBytes(messageHeader.rest, 5) IN IF ~securitySymbolShort.ok THEN Fail ELSE
    LET saleConditionLevel1 == ReadBytes(securitySymbolShort.rest, 1) IN IF ~saleConditionLevel1.ok THEN Fail ELSE
    LET tradePriceDenominator == ReadBytes(saleConditionLevel1.rest, 1) IN IF ~tradePriceDenominator.ok THEN Fail ELSE
    LET tradePriceShort == ReadBytes(tradePriceDenominator.rest, 6) IN IF ~tradePriceShort.ok THEN Fail ELSE
    LET reportVolumeShort == ReadBytes(tradePriceShort.rest, 6) IN IF ~reportVolumeShort.ok THEN Fail ELSE
    LET priceChangeIndicator == ReadBytes(reportVolumeShort.rest, 1) IN IF ~priceChangeIndicator.ok THEN Fail ELSE
    Ok([ messageHeader         |-> messageHeader.value,
         securitySymbolShort   |-> securitySymbolShort.value,
         saleConditionLevel1   |-> saleConditionLevel1.value,
         tradePriceDenominator |-> tradePriceDenominator.value,
         tradePriceShort       |-> tradePriceShort.value,
         reportVolumeShort     |-> reportVolumeShort.value,
         priceChangeIndicator  |-> priceChangeIndicator.value ], priceChangeIndicator.rest)

ZeroTradeReportShortFormMessage ==
    [ messageHeader         |-> ZeroMessageHeader,
      securitySymbolShort   |-> [i \in 1 .. 5 |-> 0],
      saleConditionLevel1   |-> [i \in 1 .. 1 |-> 0],
      tradePriceDenominator |-> [i \in 1 .. 1 |-> 0],
      tradePriceShort       |-> [i \in 1 .. 6 |-> 0],
      reportVolumeShort     |-> [i \in 1 .. 6 |-> 0],
      priceChangeIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Report Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportShortFormMessage ==
    { ZeroTradeReportShortFormMessage }
        \cup { [ZeroTradeReportShortFormMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader }
        \cup { [ZeroTradeReportShortFormMessage EXCEPT !.securitySymbolShort = one] : one \in Sample(5) }
        \cup { [ZeroTradeReportShortFormMessage EXCEPT !.saleConditionLevel1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportShortFormMessage EXCEPT !.tradePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportShortFormMessage EXCEPT !.tradePriceShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeReportShortFormMessage EXCEPT !.reportVolumeShort = one] : one \in Sample(6) }
        \cup { [ZeroTradeReportShortFormMessage EXCEPT !.priceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime2 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime2 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime2 ==
    { ZeroDatetime2 }
        \cup { [ZeroDatetime2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime2 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader2 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime2 ]

EncodeMessageHeader2(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime2(message.datetime)

DecodeMessageHeader2(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime2(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader2 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime2 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader2 ==
    { ZeroMessageHeader2 }
        \cup { [ZeroMessageHeader2 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader2 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader2 EXCEPT !.datetime = one] : one \in CheckedDatetime2 }

(***************************************************************************)
(* Original Dissemination Date: 8 bytes                                    *)
(***************************************************************************)

OriginalDisseminationDate ==
    [ year  : Sample(4),
      month : Sample(2),
      day   : Sample(2) ]

EncodeOriginalDisseminationDate(message) ==
    message.year
        \o message.month
        \o message.day

DecodeOriginalDisseminationDate(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroOriginalDisseminationDate ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 2 |-> 0],
      day   |-> [i \in 1 .. 2 |-> 0] ]

(* Original Dissemination Date at zero, then each field in turn at the values it is checked at *)
CheckedOriginalDisseminationDate ==
    { ZeroOriginalDisseminationDate }
        \cup { [ZeroOriginalDisseminationDate EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroOriginalDisseminationDate EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroOriginalDisseminationDate EXCEPT !.day = one] : one \in Sample(2) }

(***************************************************************************)
(* Execution Datetime: 23 bytes                                            *)
(***************************************************************************)

ExecutionDatetime ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeExecutionDatetime(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeExecutionDatetime(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroExecutionDatetime ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Execution Datetime at zero, then each field in turn at the values it is checked at *)
CheckedExecutionDatetime ==
    { ZeroExecutionDatetime }
        \cup { [ZeroExecutionDatetime EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroExecutionDatetime EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Trade Information: 55 bytes                                             *)
(***************************************************************************)

TradeInformation ==
    [ reportVolume          : Sample(8),
      tradePriceDenominator : Sample(1),
      tradePrice            : Sample(12),
      currency              : Sample(3),
      asOfIndicator         : Sample(1),
      executionDatetime     : ExecutionDatetime,
      saleConditionLevel1   : Sample(1),
      saleConditionLevel2   : Sample(1),
      saleConditionLevel3   : Sample(1),
      saleConditionLevel4   : Sample(1),
      sellersSaleDays       : Sample(2),
      priceChangeIndicator  : Sample(1) ]

EncodeTradeInformation(message) ==
    message.reportVolume
        \o message.tradePriceDenominator
        \o message.tradePrice
        \o message.currency
        \o message.asOfIndicator
        \o EncodeExecutionDatetime(message.executionDatetime)
        \o message.saleConditionLevel1
        \o message.saleConditionLevel2
        \o message.saleConditionLevel3
        \o message.saleConditionLevel4
        \o message.sellersSaleDays
        \o message.priceChangeIndicator

DecodeTradeInformation(bytes) ==
    LET reportVolume == ReadBytes(bytes, 8) IN IF ~reportVolume.ok THEN Fail ELSE
    LET tradePriceDenominator == ReadBytes(reportVolume.rest, 1) IN IF ~tradePriceDenominator.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceDenominator.rest, 12) IN IF ~tradePrice.ok THEN Fail ELSE
    LET currency == ReadBytes(tradePrice.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET asOfIndicator == ReadBytes(currency.rest, 1) IN IF ~asOfIndicator.ok THEN Fail ELSE
    LET executionDatetime == DecodeExecutionDatetime(asOfIndicator.rest) IN IF ~executionDatetime.ok THEN Fail ELSE
    LET saleConditionLevel1 == ReadBytes(executionDatetime.rest, 1) IN IF ~saleConditionLevel1.ok THEN Fail ELSE
    LET saleConditionLevel2 == ReadBytes(saleConditionLevel1.rest, 1) IN IF ~saleConditionLevel2.ok THEN Fail ELSE
    LET saleConditionLevel3 == ReadBytes(saleConditionLevel2.rest, 1) IN IF ~saleConditionLevel3.ok THEN Fail ELSE
    LET saleConditionLevel4 == ReadBytes(saleConditionLevel3.rest, 1) IN IF ~saleConditionLevel4.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(saleConditionLevel4.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET priceChangeIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~priceChangeIndicator.ok THEN Fail ELSE
    Ok([ reportVolume          |-> reportVolume.value,
         tradePriceDenominator |-> tradePriceDenominator.value,
         tradePrice            |-> tradePrice.value,
         currency              |-> currency.value,
         asOfIndicator         |-> asOfIndicator.value,
         executionDatetime     |-> executionDatetime.value,
         saleConditionLevel1   |-> saleConditionLevel1.value,
         saleConditionLevel2   |-> saleConditionLevel2.value,
         saleConditionLevel3   |-> saleConditionLevel3.value,
         saleConditionLevel4   |-> saleConditionLevel4.value,
         sellersSaleDays       |-> sellersSaleDays.value,
         priceChangeIndicator  |-> priceChangeIndicator.value ], priceChangeIndicator.rest)

ZeroTradeInformation ==
    [ reportVolume          |-> [i \in 1 .. 8 |-> 0],
      tradePriceDenominator |-> [i \in 1 .. 1 |-> 0],
      tradePrice            |-> [i \in 1 .. 12 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      asOfIndicator         |-> [i \in 1 .. 1 |-> 0],
      executionDatetime     |-> ZeroExecutionDatetime,
      saleConditionLevel1   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel2   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel3   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel4   |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays       |-> [i \in 1 .. 2 |-> 0],
      priceChangeIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Information at zero, then each field in turn at the values it is checked at *)
CheckedTradeInformation ==
    { ZeroTradeInformation }
        \cup { [ZeroTradeInformation EXCEPT !.reportVolume = one] : one \in Sample(8) }
        \cup { [ZeroTradeInformation EXCEPT !.tradePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.tradePrice = one] : one \in Sample(12) }
        \cup { [ZeroTradeInformation EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroTradeInformation EXCEPT !.asOfIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.executionDatetime = one] : one \in CheckedExecutionDatetime }
        \cup { [ZeroTradeInformation EXCEPT !.saleConditionLevel1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.saleConditionLevel2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.saleConditionLevel3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.saleConditionLevel4 = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }
        \cup { [ZeroTradeInformation EXCEPT !.priceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Long Form Message: 110 bytes                               *)
(***************************************************************************)

TradeReportLongFormMessage ==
    [ messageHeader             : MessageHeader2,
      securitySymbol            : Sample(14),
      originalDisseminationDate : OriginalDisseminationDate,
      tradeInformation          : TradeInformation ]

EncodeTradeReportLongFormMessage(message) ==
    EncodeMessageHeader2(message.messageHeader)
        \o message.securitySymbol
        \o EncodeOriginalDisseminationDate(message.originalDisseminationDate)
        \o EncodeTradeInformation(message.tradeInformation)

DecodeTradeReportLongFormMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader2(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(messageHeader.rest, 14) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET originalDisseminationDate == DecodeOriginalDisseminationDate(securitySymbol.rest) IN IF ~originalDisseminationDate.ok THEN Fail ELSE
    LET tradeInformation == DecodeTradeInformation(originalDisseminationDate.rest) IN IF ~tradeInformation.ok THEN Fail ELSE
    Ok([ messageHeader             |-> messageHeader.value,
         securitySymbol            |-> securitySymbol.value,
         originalDisseminationDate |-> originalDisseminationDate.value,
         tradeInformation          |-> tradeInformation.value ], tradeInformation.rest)

ZeroTradeReportLongFormMessage ==
    [ messageHeader             |-> ZeroMessageHeader2,
      securitySymbol            |-> [i \in 1 .. 14 |-> 0],
      originalDisseminationDate |-> ZeroOriginalDisseminationDate,
      tradeInformation          |-> ZeroTradeInformation ]

(* Trade Report Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportLongFormMessage ==
    { ZeroTradeReportLongFormMessage }
        \cup { [ZeroTradeReportLongFormMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader2 }
        \cup { [ZeroTradeReportLongFormMessage EXCEPT !.securitySymbol = one] : one \in Sample(14) }
        \cup { [ZeroTradeReportLongFormMessage EXCEPT !.originalDisseminationDate = one] : one \in CheckedOriginalDisseminationDate }
        \cup { [ZeroTradeReportLongFormMessage EXCEPT !.tradeInformation = one] : one \in CheckedTradeInformation }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime3 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime3(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime3 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime3 ==
    { ZeroDatetime3 }
        \cup { [ZeroDatetime3 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime3 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader3 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime3 ]

EncodeMessageHeader3(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime3(message.datetime)

DecodeMessageHeader3(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime3(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader3 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime3 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader3 ==
    { ZeroMessageHeader3 }
        \cup { [ZeroMessageHeader3 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader3 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader3 EXCEPT !.datetime = one] : one \in CheckedDatetime3 }

(***************************************************************************)
(* Original Dissemination Date: 8 bytes                                    *)
(***************************************************************************)

OriginalDisseminationDate2 ==
    [ year  : Sample(4),
      month : Sample(2),
      day   : Sample(2) ]

EncodeOriginalDisseminationDate2(message) ==
    message.year
        \o message.month
        \o message.day

DecodeOriginalDisseminationDate2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroOriginalDisseminationDate2 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 2 |-> 0],
      day   |-> [i \in 1 .. 2 |-> 0] ]

(* Original Dissemination Date at zero, then each field in turn at the values it is checked at *)
CheckedOriginalDisseminationDate2 ==
    { ZeroOriginalDisseminationDate2 }
        \cup { [ZeroOriginalDisseminationDate2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroOriginalDisseminationDate2 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroOriginalDisseminationDate2 EXCEPT !.day = one] : one \in Sample(2) }

(***************************************************************************)
(* Execution Datetime: 23 bytes                                            *)
(***************************************************************************)

ExecutionDatetime2 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeExecutionDatetime2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeExecutionDatetime2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroExecutionDatetime2 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Execution Datetime at zero, then each field in turn at the values it is checked at *)
CheckedExecutionDatetime2 ==
    { ZeroExecutionDatetime2 }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Original Trade Information: 54 bytes                                    *)
(***************************************************************************)

OriginalTradeInformation ==
    [ reportVolume          : Sample(8),
      tradePriceDenominator : Sample(1),
      tradePrice            : Sample(12),
      currency              : Sample(3),
      asOfIndicator         : Sample(1),
      executionDatetime     : ExecutionDatetime2,
      saleConditionLevel1   : Sample(1),
      saleConditionLevel2   : Sample(1),
      saleConditionLevel3   : Sample(1),
      saleConditionLevel4   : Sample(1),
      sellersSaleDays       : Sample(2) ]

EncodeOriginalTradeInformation(message) ==
    message.reportVolume
        \o message.tradePriceDenominator
        \o message.tradePrice
        \o message.currency
        \o message.asOfIndicator
        \o EncodeExecutionDatetime2(message.executionDatetime)
        \o message.saleConditionLevel1
        \o message.saleConditionLevel2
        \o message.saleConditionLevel3
        \o message.saleConditionLevel4
        \o message.sellersSaleDays

DecodeOriginalTradeInformation(bytes) ==
    LET reportVolume == ReadBytes(bytes, 8) IN IF ~reportVolume.ok THEN Fail ELSE
    LET tradePriceDenominator == ReadBytes(reportVolume.rest, 1) IN IF ~tradePriceDenominator.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceDenominator.rest, 12) IN IF ~tradePrice.ok THEN Fail ELSE
    LET currency == ReadBytes(tradePrice.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET asOfIndicator == ReadBytes(currency.rest, 1) IN IF ~asOfIndicator.ok THEN Fail ELSE
    LET executionDatetime == DecodeExecutionDatetime2(asOfIndicator.rest) IN IF ~executionDatetime.ok THEN Fail ELSE
    LET saleConditionLevel1 == ReadBytes(executionDatetime.rest, 1) IN IF ~saleConditionLevel1.ok THEN Fail ELSE
    LET saleConditionLevel2 == ReadBytes(saleConditionLevel1.rest, 1) IN IF ~saleConditionLevel2.ok THEN Fail ELSE
    LET saleConditionLevel3 == ReadBytes(saleConditionLevel2.rest, 1) IN IF ~saleConditionLevel3.ok THEN Fail ELSE
    LET saleConditionLevel4 == ReadBytes(saleConditionLevel3.rest, 1) IN IF ~saleConditionLevel4.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(saleConditionLevel4.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    Ok([ reportVolume          |-> reportVolume.value,
         tradePriceDenominator |-> tradePriceDenominator.value,
         tradePrice            |-> tradePrice.value,
         currency              |-> currency.value,
         asOfIndicator         |-> asOfIndicator.value,
         executionDatetime     |-> executionDatetime.value,
         saleConditionLevel1   |-> saleConditionLevel1.value,
         saleConditionLevel2   |-> saleConditionLevel2.value,
         saleConditionLevel3   |-> saleConditionLevel3.value,
         saleConditionLevel4   |-> saleConditionLevel4.value,
         sellersSaleDays       |-> sellersSaleDays.value ], sellersSaleDays.rest)

ZeroOriginalTradeInformation ==
    [ reportVolume          |-> [i \in 1 .. 8 |-> 0],
      tradePriceDenominator |-> [i \in 1 .. 1 |-> 0],
      tradePrice            |-> [i \in 1 .. 12 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      asOfIndicator         |-> [i \in 1 .. 1 |-> 0],
      executionDatetime     |-> ZeroExecutionDatetime2,
      saleConditionLevel1   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel2   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel3   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel4   |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays       |-> [i \in 1 .. 2 |-> 0] ]

(* Original Trade Information at zero, then each field in turn at the values it is checked at *)
CheckedOriginalTradeInformation ==
    { ZeroOriginalTradeInformation }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.reportVolume = one] : one \in Sample(8) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.tradePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.tradePrice = one] : one \in Sample(12) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.asOfIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.executionDatetime = one] : one \in CheckedExecutionDatetime2 }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.saleConditionLevel1 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.saleConditionLevel2 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.saleConditionLevel3 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.saleConditionLevel4 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Summary Information: 52 bytes                                     *)
(***************************************************************************)

TradeSummaryInformation ==
    [ highPriceDenominator      : Sample(1),
      highPrice                 : Sample(12),
      lowPriceDenominator       : Sample(1),
      lowPrice                  : Sample(12),
      lastSalePriceDenominator  : Sample(1),
      lastSalePrice             : Sample(12),
      lastSalePriceMarketCenter : Sample(1),
      totalSecurityVolume       : Sample(11),
      priceChangeIndicator      : Sample(1) ]

EncodeTradeSummaryInformation(message) ==
    message.highPriceDenominator
        \o message.highPrice
        \o message.lowPriceDenominator
        \o message.lowPrice
        \o message.lastSalePriceDenominator
        \o message.lastSalePrice
        \o message.lastSalePriceMarketCenter
        \o message.totalSecurityVolume
        \o message.priceChangeIndicator

DecodeTradeSummaryInformation(bytes) ==
    LET highPriceDenominator == ReadBytes(bytes, 1) IN IF ~highPriceDenominator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(highPriceDenominator.rest, 12) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPriceDenominator == ReadBytes(highPrice.rest, 1) IN IF ~lowPriceDenominator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(lowPriceDenominator.rest, 12) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastSalePriceDenominator == ReadBytes(lowPrice.rest, 1) IN IF ~lastSalePriceDenominator.ok THEN Fail ELSE
    LET lastSalePrice == ReadBytes(lastSalePriceDenominator.rest, 12) IN IF ~lastSalePrice.ok THEN Fail ELSE
    LET lastSalePriceMarketCenter == ReadBytes(lastSalePrice.rest, 1) IN IF ~lastSalePriceMarketCenter.ok THEN Fail ELSE
    LET totalSecurityVolume == ReadBytes(lastSalePriceMarketCenter.rest, 11) IN IF ~totalSecurityVolume.ok THEN Fail ELSE
    LET priceChangeIndicator == ReadBytes(totalSecurityVolume.rest, 1) IN IF ~priceChangeIndicator.ok THEN Fail ELSE
    Ok([ highPriceDenominator      |-> highPriceDenominator.value,
         highPrice                 |-> highPrice.value,
         lowPriceDenominator       |-> lowPriceDenominator.value,
         lowPrice                  |-> lowPrice.value,
         lastSalePriceDenominator  |-> lastSalePriceDenominator.value,
         lastSalePrice             |-> lastSalePrice.value,
         lastSalePriceMarketCenter |-> lastSalePriceMarketCenter.value,
         totalSecurityVolume       |-> totalSecurityVolume.value,
         priceChangeIndicator      |-> priceChangeIndicator.value ], priceChangeIndicator.rest)

ZeroTradeSummaryInformation ==
    [ highPriceDenominator      |-> [i \in 1 .. 1 |-> 0],
      highPrice                 |-> [i \in 1 .. 12 |-> 0],
      lowPriceDenominator       |-> [i \in 1 .. 1 |-> 0],
      lowPrice                  |-> [i \in 1 .. 12 |-> 0],
      lastSalePriceDenominator  |-> [i \in 1 .. 1 |-> 0],
      lastSalePrice             |-> [i \in 1 .. 12 |-> 0],
      lastSalePriceMarketCenter |-> [i \in 1 .. 1 |-> 0],
      totalSecurityVolume       |-> [i \in 1 .. 11 |-> 0],
      priceChangeIndicator      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Summary Information at zero, then each field in turn at the values it is checked at *)
CheckedTradeSummaryInformation ==
    { ZeroTradeSummaryInformation }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.highPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.highPrice = one] : one \in Sample(12) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.lowPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.lowPrice = one] : one \in Sample(12) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.lastSalePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.lastSalePrice = one] : one \in Sample(12) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.lastSalePriceMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.totalSecurityVolume = one] : one \in Sample(11) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.priceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Error Message: 162 bytes                                   *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ messageHeader             : MessageHeader3,
      securitySymbol            : Sample(14),
      originalDisseminationDate : OriginalDisseminationDate2,
      reportFunction            : Sample(1),
      originalTradeInformation  : OriginalTradeInformation,
      tradeSummaryInformation   : TradeSummaryInformation ]

EncodeTradeCancelErrorMessage(message) ==
    EncodeMessageHeader3(message.messageHeader)
        \o message.securitySymbol
        \o EncodeOriginalDisseminationDate2(message.originalDisseminationDate)
        \o message.reportFunction
        \o EncodeOriginalTradeInformation(message.originalTradeInformation)
        \o EncodeTradeSummaryInformation(message.tradeSummaryInformation)

DecodeTradeCancelErrorMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader3(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(messageHeader.rest, 14) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET originalDisseminationDate == DecodeOriginalDisseminationDate2(securitySymbol.rest) IN IF ~originalDisseminationDate.ok THEN Fail ELSE
    LET reportFunction == ReadBytes(originalDisseminationDate.rest, 1) IN IF ~reportFunction.ok THEN Fail ELSE
    LET originalTradeInformation == DecodeOriginalTradeInformation(reportFunction.rest) IN IF ~originalTradeInformation.ok THEN Fail ELSE
    LET tradeSummaryInformation == DecodeTradeSummaryInformation(originalTradeInformation.rest) IN IF ~tradeSummaryInformation.ok THEN Fail ELSE
    Ok([ messageHeader             |-> messageHeader.value,
         securitySymbol            |-> securitySymbol.value,
         originalDisseminationDate |-> originalDisseminationDate.value,
         reportFunction            |-> reportFunction.value,
         originalTradeInformation  |-> originalTradeInformation.value,
         tradeSummaryInformation   |-> tradeSummaryInformation.value ], tradeSummaryInformation.rest)

ZeroTradeCancelErrorMessage ==
    [ messageHeader             |-> ZeroMessageHeader3,
      securitySymbol            |-> [i \in 1 .. 14 |-> 0],
      originalDisseminationDate |-> ZeroOriginalDisseminationDate2,
      reportFunction            |-> [i \in 1 .. 1 |-> 0],
      originalTradeInformation  |-> ZeroOriginalTradeInformation,
      tradeSummaryInformation   |-> ZeroTradeSummaryInformation ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader3 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(14) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalDisseminationDate = one] : one \in CheckedOriginalDisseminationDate2 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.reportFunction = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeInformation = one] : one \in CheckedOriginalTradeInformation }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeSummaryInformation = one] : one \in CheckedTradeSummaryInformation }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime4 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime4(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime4(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime4 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime4 ==
    { ZeroDatetime4 }
        \cup { [ZeroDatetime4 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime4 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader4 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime4 ]

EncodeMessageHeader4(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime4(message.datetime)

DecodeMessageHeader4(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime4(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader4 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime4 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader4 ==
    { ZeroMessageHeader4 }
        \cup { [ZeroMessageHeader4 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader4 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader4 EXCEPT !.datetime = one] : one \in CheckedDatetime4 }

(***************************************************************************)
(* Original Dissemination Date: 8 bytes                                    *)
(***************************************************************************)

OriginalDisseminationDate3 ==
    [ year  : Sample(4),
      month : Sample(2),
      day   : Sample(2) ]

EncodeOriginalDisseminationDate3(message) ==
    message.year
        \o message.month
        \o message.day

DecodeOriginalDisseminationDate3(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroOriginalDisseminationDate3 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 2 |-> 0],
      day   |-> [i \in 1 .. 2 |-> 0] ]

(* Original Dissemination Date at zero, then each field in turn at the values it is checked at *)
CheckedOriginalDisseminationDate3 ==
    { ZeroOriginalDisseminationDate3 }
        \cup { [ZeroOriginalDisseminationDate3 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroOriginalDisseminationDate3 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroOriginalDisseminationDate3 EXCEPT !.day = one] : one \in Sample(2) }

(***************************************************************************)
(* Execution Datetime: 23 bytes                                            *)
(***************************************************************************)

ExecutionDatetime3 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeExecutionDatetime3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeExecutionDatetime3(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroExecutionDatetime3 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Execution Datetime at zero, then each field in turn at the values it is checked at *)
CheckedExecutionDatetime3 ==
    { ZeroExecutionDatetime3 }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Original Trade Information: 54 bytes                                    *)
(***************************************************************************)

OriginalTradeInformation2 ==
    [ reportVolume          : Sample(8),
      tradePriceDenominator : Sample(1),
      tradePrice            : Sample(12),
      currency              : Sample(3),
      asOfIndicator         : Sample(1),
      executionDatetime     : ExecutionDatetime3,
      saleConditionLevel1   : Sample(1),
      saleConditionLevel2   : Sample(1),
      saleConditionLevel3   : Sample(1),
      saleConditionLevel4   : Sample(1),
      sellersSaleDays       : Sample(2) ]

EncodeOriginalTradeInformation2(message) ==
    message.reportVolume
        \o message.tradePriceDenominator
        \o message.tradePrice
        \o message.currency
        \o message.asOfIndicator
        \o EncodeExecutionDatetime3(message.executionDatetime)
        \o message.saleConditionLevel1
        \o message.saleConditionLevel2
        \o message.saleConditionLevel3
        \o message.saleConditionLevel4
        \o message.sellersSaleDays

DecodeOriginalTradeInformation2(bytes) ==
    LET reportVolume == ReadBytes(bytes, 8) IN IF ~reportVolume.ok THEN Fail ELSE
    LET tradePriceDenominator == ReadBytes(reportVolume.rest, 1) IN IF ~tradePriceDenominator.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceDenominator.rest, 12) IN IF ~tradePrice.ok THEN Fail ELSE
    LET currency == ReadBytes(tradePrice.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET asOfIndicator == ReadBytes(currency.rest, 1) IN IF ~asOfIndicator.ok THEN Fail ELSE
    LET executionDatetime == DecodeExecutionDatetime3(asOfIndicator.rest) IN IF ~executionDatetime.ok THEN Fail ELSE
    LET saleConditionLevel1 == ReadBytes(executionDatetime.rest, 1) IN IF ~saleConditionLevel1.ok THEN Fail ELSE
    LET saleConditionLevel2 == ReadBytes(saleConditionLevel1.rest, 1) IN IF ~saleConditionLevel2.ok THEN Fail ELSE
    LET saleConditionLevel3 == ReadBytes(saleConditionLevel2.rest, 1) IN IF ~saleConditionLevel3.ok THEN Fail ELSE
    LET saleConditionLevel4 == ReadBytes(saleConditionLevel3.rest, 1) IN IF ~saleConditionLevel4.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(saleConditionLevel4.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    Ok([ reportVolume          |-> reportVolume.value,
         tradePriceDenominator |-> tradePriceDenominator.value,
         tradePrice            |-> tradePrice.value,
         currency              |-> currency.value,
         asOfIndicator         |-> asOfIndicator.value,
         executionDatetime     |-> executionDatetime.value,
         saleConditionLevel1   |-> saleConditionLevel1.value,
         saleConditionLevel2   |-> saleConditionLevel2.value,
         saleConditionLevel3   |-> saleConditionLevel3.value,
         saleConditionLevel4   |-> saleConditionLevel4.value,
         sellersSaleDays       |-> sellersSaleDays.value ], sellersSaleDays.rest)

ZeroOriginalTradeInformation2 ==
    [ reportVolume          |-> [i \in 1 .. 8 |-> 0],
      tradePriceDenominator |-> [i \in 1 .. 1 |-> 0],
      tradePrice            |-> [i \in 1 .. 12 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      asOfIndicator         |-> [i \in 1 .. 1 |-> 0],
      executionDatetime     |-> ZeroExecutionDatetime3,
      saleConditionLevel1   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel2   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel3   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel4   |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays       |-> [i \in 1 .. 2 |-> 0] ]

(* Original Trade Information at zero, then each field in turn at the values it is checked at *)
CheckedOriginalTradeInformation2 ==
    { ZeroOriginalTradeInformation2 }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.reportVolume = one] : one \in Sample(8) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.tradePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.tradePrice = one] : one \in Sample(12) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.asOfIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.executionDatetime = one] : one \in CheckedExecutionDatetime3 }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.saleConditionLevel1 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.saleConditionLevel2 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.saleConditionLevel3 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.saleConditionLevel4 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }

(***************************************************************************)
(* Execution Datetime: 23 bytes                                            *)
(***************************************************************************)

ExecutionDatetime4 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeExecutionDatetime4(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeExecutionDatetime4(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroExecutionDatetime4 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Execution Datetime at zero, then each field in turn at the values it is checked at *)
CheckedExecutionDatetime4 ==
    { ZeroExecutionDatetime4 }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Corrected Trade Information: 54 bytes                                   *)
(***************************************************************************)

CorrectedTradeInformation ==
    [ reportVolume          : Sample(8),
      tradePriceDenominator : Sample(1),
      tradePrice            : Sample(12),
      currency              : Sample(3),
      asOfIndicator         : Sample(1),
      executionDatetime     : ExecutionDatetime4,
      saleConditionLevel1   : Sample(1),
      saleConditionLevel2   : Sample(1),
      saleConditionLevel3   : Sample(1),
      saleConditionLevel4   : Sample(1),
      sellersSaleDays       : Sample(2) ]

EncodeCorrectedTradeInformation(message) ==
    message.reportVolume
        \o message.tradePriceDenominator
        \o message.tradePrice
        \o message.currency
        \o message.asOfIndicator
        \o EncodeExecutionDatetime4(message.executionDatetime)
        \o message.saleConditionLevel1
        \o message.saleConditionLevel2
        \o message.saleConditionLevel3
        \o message.saleConditionLevel4
        \o message.sellersSaleDays

DecodeCorrectedTradeInformation(bytes) ==
    LET reportVolume == ReadBytes(bytes, 8) IN IF ~reportVolume.ok THEN Fail ELSE
    LET tradePriceDenominator == ReadBytes(reportVolume.rest, 1) IN IF ~tradePriceDenominator.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradePriceDenominator.rest, 12) IN IF ~tradePrice.ok THEN Fail ELSE
    LET currency == ReadBytes(tradePrice.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET asOfIndicator == ReadBytes(currency.rest, 1) IN IF ~asOfIndicator.ok THEN Fail ELSE
    LET executionDatetime == DecodeExecutionDatetime4(asOfIndicator.rest) IN IF ~executionDatetime.ok THEN Fail ELSE
    LET saleConditionLevel1 == ReadBytes(executionDatetime.rest, 1) IN IF ~saleConditionLevel1.ok THEN Fail ELSE
    LET saleConditionLevel2 == ReadBytes(saleConditionLevel1.rest, 1) IN IF ~saleConditionLevel2.ok THEN Fail ELSE
    LET saleConditionLevel3 == ReadBytes(saleConditionLevel2.rest, 1) IN IF ~saleConditionLevel3.ok THEN Fail ELSE
    LET saleConditionLevel4 == ReadBytes(saleConditionLevel3.rest, 1) IN IF ~saleConditionLevel4.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(saleConditionLevel4.rest, 2) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    Ok([ reportVolume          |-> reportVolume.value,
         tradePriceDenominator |-> tradePriceDenominator.value,
         tradePrice            |-> tradePrice.value,
         currency              |-> currency.value,
         asOfIndicator         |-> asOfIndicator.value,
         executionDatetime     |-> executionDatetime.value,
         saleConditionLevel1   |-> saleConditionLevel1.value,
         saleConditionLevel2   |-> saleConditionLevel2.value,
         saleConditionLevel3   |-> saleConditionLevel3.value,
         saleConditionLevel4   |-> saleConditionLevel4.value,
         sellersSaleDays       |-> sellersSaleDays.value ], sellersSaleDays.rest)

ZeroCorrectedTradeInformation ==
    [ reportVolume          |-> [i \in 1 .. 8 |-> 0],
      tradePriceDenominator |-> [i \in 1 .. 1 |-> 0],
      tradePrice            |-> [i \in 1 .. 12 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      asOfIndicator         |-> [i \in 1 .. 1 |-> 0],
      executionDatetime     |-> ZeroExecutionDatetime4,
      saleConditionLevel1   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel2   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel3   |-> [i \in 1 .. 1 |-> 0],
      saleConditionLevel4   |-> [i \in 1 .. 1 |-> 0],
      sellersSaleDays       |-> [i \in 1 .. 2 |-> 0] ]

(* Corrected Trade Information at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedTradeInformation ==
    { ZeroCorrectedTradeInformation }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.reportVolume = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.tradePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.tradePrice = one] : one \in Sample(12) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.asOfIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.executionDatetime = one] : one \in CheckedExecutionDatetime4 }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.saleConditionLevel1 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.saleConditionLevel2 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.saleConditionLevel3 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.saleConditionLevel4 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTradeInformation EXCEPT !.sellersSaleDays = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Summary Information: 52 bytes                                     *)
(***************************************************************************)

TradeSummaryInformation2 ==
    [ highPriceDenominator      : Sample(1),
      highPrice                 : Sample(12),
      lowPriceDenominator       : Sample(1),
      lowPrice                  : Sample(12),
      lastSalePriceDenominator  : Sample(1),
      lastSalePrice             : Sample(12),
      lastSalePriceMarketCenter : Sample(1),
      totalSecurityVolume       : Sample(11),
      priceChangeIndicator      : Sample(1) ]

EncodeTradeSummaryInformation2(message) ==
    message.highPriceDenominator
        \o message.highPrice
        \o message.lowPriceDenominator
        \o message.lowPrice
        \o message.lastSalePriceDenominator
        \o message.lastSalePrice
        \o message.lastSalePriceMarketCenter
        \o message.totalSecurityVolume
        \o message.priceChangeIndicator

DecodeTradeSummaryInformation2(bytes) ==
    LET highPriceDenominator == ReadBytes(bytes, 1) IN IF ~highPriceDenominator.ok THEN Fail ELSE
    LET highPrice == ReadBytes(highPriceDenominator.rest, 12) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPriceDenominator == ReadBytes(highPrice.rest, 1) IN IF ~lowPriceDenominator.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(lowPriceDenominator.rest, 12) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastSalePriceDenominator == ReadBytes(lowPrice.rest, 1) IN IF ~lastSalePriceDenominator.ok THEN Fail ELSE
    LET lastSalePrice == ReadBytes(lastSalePriceDenominator.rest, 12) IN IF ~lastSalePrice.ok THEN Fail ELSE
    LET lastSalePriceMarketCenter == ReadBytes(lastSalePrice.rest, 1) IN IF ~lastSalePriceMarketCenter.ok THEN Fail ELSE
    LET totalSecurityVolume == ReadBytes(lastSalePriceMarketCenter.rest, 11) IN IF ~totalSecurityVolume.ok THEN Fail ELSE
    LET priceChangeIndicator == ReadBytes(totalSecurityVolume.rest, 1) IN IF ~priceChangeIndicator.ok THEN Fail ELSE
    Ok([ highPriceDenominator      |-> highPriceDenominator.value,
         highPrice                 |-> highPrice.value,
         lowPriceDenominator       |-> lowPriceDenominator.value,
         lowPrice                  |-> lowPrice.value,
         lastSalePriceDenominator  |-> lastSalePriceDenominator.value,
         lastSalePrice             |-> lastSalePrice.value,
         lastSalePriceMarketCenter |-> lastSalePriceMarketCenter.value,
         totalSecurityVolume       |-> totalSecurityVolume.value,
         priceChangeIndicator      |-> priceChangeIndicator.value ], priceChangeIndicator.rest)

ZeroTradeSummaryInformation2 ==
    [ highPriceDenominator      |-> [i \in 1 .. 1 |-> 0],
      highPrice                 |-> [i \in 1 .. 12 |-> 0],
      lowPriceDenominator       |-> [i \in 1 .. 1 |-> 0],
      lowPrice                  |-> [i \in 1 .. 12 |-> 0],
      lastSalePriceDenominator  |-> [i \in 1 .. 1 |-> 0],
      lastSalePrice             |-> [i \in 1 .. 12 |-> 0],
      lastSalePriceMarketCenter |-> [i \in 1 .. 1 |-> 0],
      totalSecurityVolume       |-> [i \in 1 .. 11 |-> 0],
      priceChangeIndicator      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Summary Information at zero, then each field in turn at the values it is checked at *)
CheckedTradeSummaryInformation2 ==
    { ZeroTradeSummaryInformation2 }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.highPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.highPrice = one] : one \in Sample(12) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.lowPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.lowPrice = one] : one \in Sample(12) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.lastSalePriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.lastSalePrice = one] : one \in Sample(12) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.lastSalePriceMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.totalSecurityVolume = one] : one \in Sample(11) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.priceChangeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correction Message: 216 bytes                                     *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ messageHeader             : MessageHeader4,
      securitySymbol            : Sample(14),
      originalDisseminationDate : OriginalDisseminationDate3,
      reportFunction            : Sample(1),
      originalTradeInformation  : OriginalTradeInformation2,
      correctedTradeInformation : CorrectedTradeInformation,
      tradeSummaryInformation   : TradeSummaryInformation2 ]

EncodeTradeCorrectionMessage(message) ==
    EncodeMessageHeader4(message.messageHeader)
        \o message.securitySymbol
        \o EncodeOriginalDisseminationDate3(message.originalDisseminationDate)
        \o message.reportFunction
        \o EncodeOriginalTradeInformation2(message.originalTradeInformation)
        \o EncodeCorrectedTradeInformation(message.correctedTradeInformation)
        \o EncodeTradeSummaryInformation2(message.tradeSummaryInformation)

DecodeTradeCorrectionMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader4(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(messageHeader.rest, 14) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET originalDisseminationDate == DecodeOriginalDisseminationDate3(securitySymbol.rest) IN IF ~originalDisseminationDate.ok THEN Fail ELSE
    LET reportFunction == ReadBytes(originalDisseminationDate.rest, 1) IN IF ~reportFunction.ok THEN Fail ELSE
    LET originalTradeInformation == DecodeOriginalTradeInformation2(reportFunction.rest) IN IF ~originalTradeInformation.ok THEN Fail ELSE
    LET correctedTradeInformation == DecodeCorrectedTradeInformation(originalTradeInformation.rest) IN IF ~correctedTradeInformation.ok THEN Fail ELSE
    LET tradeSummaryInformation == DecodeTradeSummaryInformation2(correctedTradeInformation.rest) IN IF ~tradeSummaryInformation.ok THEN Fail ELSE
    Ok([ messageHeader             |-> messageHeader.value,
         securitySymbol            |-> securitySymbol.value,
         originalDisseminationDate |-> originalDisseminationDate.value,
         reportFunction            |-> reportFunction.value,
         originalTradeInformation  |-> originalTradeInformation.value,
         correctedTradeInformation |-> correctedTradeInformation.value,
         tradeSummaryInformation   |-> tradeSummaryInformation.value ], tradeSummaryInformation.rest)

ZeroTradeCorrectionMessage ==
    [ messageHeader             |-> ZeroMessageHeader4,
      securitySymbol            |-> [i \in 1 .. 14 |-> 0],
      originalDisseminationDate |-> ZeroOriginalDisseminationDate3,
      reportFunction            |-> [i \in 1 .. 1 |-> 0],
      originalTradeInformation  |-> ZeroOriginalTradeInformation2,
      correctedTradeInformation |-> ZeroCorrectedTradeInformation,
      tradeSummaryInformation   |-> ZeroTradeSummaryInformation2 ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader4 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(14) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalDisseminationDate = one] : one \in CheckedOriginalDisseminationDate3 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.reportFunction = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeInformation = one] : one \in CheckedOriginalTradeInformation2 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeInformation = one] : one \in CheckedCorrectedTradeInformation }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeSummaryInformation = one] : one \in CheckedTradeSummaryInformation2 }

(***************************************************************************)
(* Trade Message Payload, selected by Trade Message Type                   *)
(***************************************************************************)

TradeReportShortFormMessageCode == 53  \* "5"
TradeReportLongFormMessageCode == 54  \* "6"
TradeCancelErrorMessageCode == 55  \* "7"
TradeCorrectionMessageCode == 56  \* "8"

TradeMessagePayload ==
    [ tag : {TradeReportShortFormMessageCode}, body : TradeReportShortFormMessage ]
        \cup [ tag : {TradeReportLongFormMessageCode}, body : TradeReportLongFormMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]

EncodeTradeMessagePayload(message) ==
    CASE message.tag = TradeReportShortFormMessageCode -> EncodeTradeReportShortFormMessage(message.body)
      [] message.tag = TradeReportLongFormMessageCode -> EncodeTradeReportLongFormMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)

DecodeTradeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradeReportShortFormMessageCode -> DecodeTradeReportShortFormMessage(bytes)
              [] tag = TradeReportLongFormMessageCode -> DecodeTradeReportLongFormMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTradeMessagePayload == [tag |-> TradeReportShortFormMessageCode, body |-> ZeroTradeReportShortFormMessage]

(* Each Trade Message Payload in turn, at the values the message it names is checked at *)
CheckedTradeMessagePayload ==
    { [tag |-> TradeReportShortFormMessageCode, body |-> one] : one \in CheckedTradeReportShortFormMessage }
        \cup { [tag |-> TradeReportLongFormMessageCode, body |-> one] : one \in CheckedTradeReportLongFormMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }

(***************************************************************************)
(* Trade Message                                                           *)
(***************************************************************************)

TradeMessage ==
    [ tradeMessagePayload : TradeMessagePayload ]

EncodeTradeMessage(message) ==
    EncodeUIntBE(message.tradeMessagePayload.tag, 1)
        \o EncodeTradeMessagePayload(message.tradeMessagePayload)

DecodeTradeMessage(bytes) ==
    LET tradeMessageType == ReadUIntBE(bytes, 1) IN IF ~tradeMessageType.ok THEN Fail ELSE
    LET tradeMessagePayload == DecodeTradeMessagePayload(tradeMessageType.value, tradeMessageType.rest) IN IF ~tradeMessagePayload.ok THEN Fail ELSE
    Ok([ tradeMessagePayload |-> tradeMessagePayload.value ], tradeMessagePayload.rest)

ZeroTradeMessage ==
    [ tradeMessagePayload |-> ZeroTradeMessagePayload ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.tradeMessagePayload = one] : one \in CheckedTradeMessagePayload }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime5 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime5(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime5(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime5 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime5 ==
    { ZeroDatetime5 }
        \cup { [ZeroDatetime5 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime5 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader5 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime5 ]

EncodeMessageHeader5(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime5(message.datetime)

DecodeMessageHeader5(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime5(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader5 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime5 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader5 ==
    { ZeroMessageHeader5 }
        \cup { [ZeroMessageHeader5 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader5 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader5 EXCEPT !.datetime = one] : one \in CheckedDatetime5 }

(***************************************************************************)
(* General Administrative Message                                          *)
(***************************************************************************)

GeneralAdministrativeMessage ==
    [ messageHeader : MessageHeader5,
      text          : SampleBytes ]

EncodeGeneralAdministrativeMessage(message) ==
    EncodeMessageHeader5(message.messageHeader)
        \o message.text

DecodeGeneralAdministrativeMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader5(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET text == Ok(messageHeader.rest, << >>) IN IF ~text.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value,
         text          |-> text.value ], text.rest)

ZeroGeneralAdministrativeMessage ==
    [ messageHeader |-> ZeroMessageHeader5,
      text          |-> << >> ]

(* General Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralAdministrativeMessage ==
    { ZeroGeneralAdministrativeMessage }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader5 }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime6 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime6(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime6(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime6 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime6 ==
    { ZeroDatetime6 }
        \cup { [ZeroDatetime6 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime6 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader6 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime6 ]

EncodeMessageHeader6(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime6(message.datetime)

DecodeMessageHeader6(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime6(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader6 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime6 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader6 ==
    { ZeroMessageHeader6 }
        \cup { [ZeroMessageHeader6 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader6 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader6 EXCEPT !.datetime = one] : one \in CheckedDatetime6 }

(***************************************************************************)
(* Closing Trade Summary Report Message: 114 bytes                         *)
(***************************************************************************)

ClosingTradeSummaryReportMessage ==
    [ messageHeader             : MessageHeader6,
      securitySymbol            : Sample(14),
      dailyHighPriceDenominator : Sample(1),
      dailyHighPrice            : Sample(12),
      dailyLowPriceDenominator  : Sample(1),
      dailyLowPrice             : Sample(12),
      closingPriceMarketCenter  : Sample(1),
      closingPriceDenominator   : Sample(1),
      closingPrice              : Sample(12),
      reserved1                 : Sample(1),
      netChangeDenominator      : Sample(1),
      netChangeAmount           : Sample(10),
      netChangeDirection        : Sample(1),
      currency                  : Sample(3),
      totalSecurityVolume       : Sample(11) ]

EncodeClosingTradeSummaryReportMessage(message) ==
    EncodeMessageHeader6(message.messageHeader)
        \o message.securitySymbol
        \o message.dailyHighPriceDenominator
        \o message.dailyHighPrice
        \o message.dailyLowPriceDenominator
        \o message.dailyLowPrice
        \o message.closingPriceMarketCenter
        \o message.closingPriceDenominator
        \o message.closingPrice
        \o message.reserved1
        \o message.netChangeDenominator
        \o message.netChangeAmount
        \o message.netChangeDirection
        \o message.currency
        \o message.totalSecurityVolume

DecodeClosingTradeSummaryReportMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader6(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(messageHeader.rest, 14) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET dailyHighPriceDenominator == ReadBytes(securitySymbol.rest, 1) IN IF ~dailyHighPriceDenominator.ok THEN Fail ELSE
    LET dailyHighPrice == ReadBytes(dailyHighPriceDenominator.rest, 12) IN IF ~dailyHighPrice.ok THEN Fail ELSE
    LET dailyLowPriceDenominator == ReadBytes(dailyHighPrice.rest, 1) IN IF ~dailyLowPriceDenominator.ok THEN Fail ELSE
    LET dailyLowPrice == ReadBytes(dailyLowPriceDenominator.rest, 12) IN IF ~dailyLowPrice.ok THEN Fail ELSE
    LET closingPriceMarketCenter == ReadBytes(dailyLowPrice.rest, 1) IN IF ~closingPriceMarketCenter.ok THEN Fail ELSE
    LET closingPriceDenominator == ReadBytes(closingPriceMarketCenter.rest, 1) IN IF ~closingPriceDenominator.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(closingPriceDenominator.rest, 12) IN IF ~closingPrice.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(closingPrice.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET netChangeDenominator == ReadBytes(reserved1.rest, 1) IN IF ~netChangeDenominator.ok THEN Fail ELSE
    LET netChangeAmount == ReadBytes(netChangeDenominator.rest, 10) IN IF ~netChangeAmount.ok THEN Fail ELSE
    LET netChangeDirection == ReadBytes(netChangeAmount.rest, 1) IN IF ~netChangeDirection.ok THEN Fail ELSE
    LET currency == ReadBytes(netChangeDirection.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET totalSecurityVolume == ReadBytes(currency.rest, 11) IN IF ~totalSecurityVolume.ok THEN Fail ELSE
    Ok([ messageHeader             |-> messageHeader.value,
         securitySymbol            |-> securitySymbol.value,
         dailyHighPriceDenominator |-> dailyHighPriceDenominator.value,
         dailyHighPrice            |-> dailyHighPrice.value,
         dailyLowPriceDenominator  |-> dailyLowPriceDenominator.value,
         dailyLowPrice             |-> dailyLowPrice.value,
         closingPriceMarketCenter  |-> closingPriceMarketCenter.value,
         closingPriceDenominator   |-> closingPriceDenominator.value,
         closingPrice              |-> closingPrice.value,
         reserved1                 |-> reserved1.value,
         netChangeDenominator      |-> netChangeDenominator.value,
         netChangeAmount           |-> netChangeAmount.value,
         netChangeDirection        |-> netChangeDirection.value,
         currency                  |-> currency.value,
         totalSecurityVolume       |-> totalSecurityVolume.value ], totalSecurityVolume.rest)

ZeroClosingTradeSummaryReportMessage ==
    [ messageHeader             |-> ZeroMessageHeader6,
      securitySymbol            |-> [i \in 1 .. 14 |-> 0],
      dailyHighPriceDenominator |-> [i \in 1 .. 1 |-> 0],
      dailyHighPrice            |-> [i \in 1 .. 12 |-> 0],
      dailyLowPriceDenominator  |-> [i \in 1 .. 1 |-> 0],
      dailyLowPrice             |-> [i \in 1 .. 12 |-> 0],
      closingPriceMarketCenter  |-> [i \in 1 .. 1 |-> 0],
      closingPriceDenominator   |-> [i \in 1 .. 1 |-> 0],
      closingPrice              |-> [i \in 1 .. 12 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      netChangeDenominator      |-> [i \in 1 .. 1 |-> 0],
      netChangeAmount           |-> [i \in 1 .. 10 |-> 0],
      netChangeDirection        |-> [i \in 1 .. 1 |-> 0],
      currency                  |-> [i \in 1 .. 3 |-> 0],
      totalSecurityVolume       |-> [i \in 1 .. 11 |-> 0] ]

(* Closing Trade Summary Report Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingTradeSummaryReportMessage ==
    { ZeroClosingTradeSummaryReportMessage }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader6 }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.securitySymbol = one] : one \in Sample(14) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyHighPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyHighPrice = one] : one \in Sample(12) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyLowPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.dailyLowPrice = one] : one \in Sample(12) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.closingPriceMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.closingPriceDenominator = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.closingPrice = one] : one \in Sample(12) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.netChangeDenominator = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.netChangeAmount = one] : one \in Sample(10) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.netChangeDirection = one] : one \in Sample(1) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroClosingTradeSummaryReportMessage EXCEPT !.totalSecurityVolume = one] : one \in Sample(11) }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime7 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime7(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime7(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime7 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime7 ==
    { ZeroDatetime7 }
        \cup { [ZeroDatetime7 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime7 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader7 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime7 ]

EncodeMessageHeader7(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime7(message.datetime)

DecodeMessageHeader7(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime7(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader7 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime7 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader7 ==
    { ZeroMessageHeader7 }
        \cup { [ZeroMessageHeader7 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader7 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader7 EXCEPT !.datetime = one] : one \in CheckedDatetime7 }

(***************************************************************************)
(* Action Datetime: 23 bytes                                               *)
(***************************************************************************)

ActionDatetime ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeActionDatetime(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeActionDatetime(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroActionDatetime ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Action Datetime at zero, then each field in turn at the values it is checked at *)
CheckedActionDatetime ==
    { ZeroActionDatetime }
        \cup { [ZeroActionDatetime EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroActionDatetime EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Trading Action Message: 77 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ messageHeader           : MessageHeader7,
      securitySymbol          : Sample(14),
      action                  : Sample(1),
      actionDatetime          : ActionDatetime,
      tradingActionReasonCode : Sample(6) ]

EncodeTradingActionMessage(message) ==
    EncodeMessageHeader7(message.messageHeader)
        \o message.securitySymbol
        \o message.action
        \o EncodeActionDatetime(message.actionDatetime)
        \o message.tradingActionReasonCode

DecodeTradingActionMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader7(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(messageHeader.rest, 14) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET action == ReadBytes(securitySymbol.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET actionDatetime == DecodeActionDatetime(action.rest) IN IF ~actionDatetime.ok THEN Fail ELSE
    LET tradingActionReasonCode == ReadBytes(actionDatetime.rest, 6) IN IF ~tradingActionReasonCode.ok THEN Fail ELSE
    Ok([ messageHeader           |-> messageHeader.value,
         securitySymbol          |-> securitySymbol.value,
         action                  |-> action.value,
         actionDatetime          |-> actionDatetime.value,
         tradingActionReasonCode |-> tradingActionReasonCode.value ], tradingActionReasonCode.rest)

ZeroTradingActionMessage ==
    [ messageHeader           |-> ZeroMessageHeader7,
      securitySymbol          |-> [i \in 1 .. 14 |-> 0],
      action                  |-> [i \in 1 .. 1 |-> 0],
      actionDatetime          |-> ZeroActionDatetime,
      tradingActionReasonCode |-> [i \in 1 .. 6 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader7 }
        \cup { [ZeroTradingActionMessage EXCEPT !.securitySymbol = one] : one \in Sample(14) }
        \cup { [ZeroTradingActionMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionMessage EXCEPT !.actionDatetime = one] : one \in CheckedActionDatetime }
        \cup { [ZeroTradingActionMessage EXCEPT !.tradingActionReasonCode = one] : one \in Sample(6) }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime8 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime8(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime8(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime8 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime8 ==
    { ZeroDatetime8 }
        \cup { [ZeroDatetime8 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime8 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader8 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime8 ]

EncodeMessageHeader8(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime8(message.datetime)

DecodeMessageHeader8(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime8(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader8 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime8 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader8 ==
    { ZeroMessageHeader8 }
        \cup { [ZeroMessageHeader8 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader8 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader8 EXCEPT !.datetime = one] : one \in CheckedDatetime8 }

(***************************************************************************)
(* Action Datetime: 23 bytes                                               *)
(***************************************************************************)

ActionDatetime2 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeActionDatetime2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeActionDatetime2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroActionDatetime2 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Action Datetime at zero, then each field in turn at the values it is checked at *)
CheckedActionDatetime2 ==
    { ZeroActionDatetime2 }
        \cup { [ZeroActionDatetime2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroActionDatetime2 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime2 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime2 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime2 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime2 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime2 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Market Wide Circuit Breaker Event Message: 63 bytes                     *)
(***************************************************************************)

MarketWideCircuitBreakerEventMessage ==
    [ messageHeader                      : MessageHeader8,
      action                             : Sample(1),
      actionDatetime                     : ActionDatetime2,
      marketWideCircuitBreakerReasonCode : Sample(6) ]

EncodeMarketWideCircuitBreakerEventMessage(message) ==
    EncodeMessageHeader8(message.messageHeader)
        \o message.action
        \o EncodeActionDatetime2(message.actionDatetime)
        \o message.marketWideCircuitBreakerReasonCode

DecodeMarketWideCircuitBreakerEventMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader8(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET action == ReadBytes(messageHeader.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET actionDatetime == DecodeActionDatetime2(action.rest) IN IF ~actionDatetime.ok THEN Fail ELSE
    LET marketWideCircuitBreakerReasonCode == ReadBytes(actionDatetime.rest, 6) IN IF ~marketWideCircuitBreakerReasonCode.ok THEN Fail ELSE
    Ok([ messageHeader                      |-> messageHeader.value,
         action                             |-> action.value,
         actionDatetime                     |-> actionDatetime.value,
         marketWideCircuitBreakerReasonCode |-> marketWideCircuitBreakerReasonCode.value ], marketWideCircuitBreakerReasonCode.rest)

ZeroMarketWideCircuitBreakerEventMessage ==
    [ messageHeader                      |-> ZeroMessageHeader8,
      action                             |-> [i \in 1 .. 1 |-> 0],
      actionDatetime                     |-> ZeroActionDatetime2,
      marketWideCircuitBreakerReasonCode |-> [i \in 1 .. 6 |-> 0] ]

(* Market Wide Circuit Breaker Event Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerEventMessage ==
    { ZeroMarketWideCircuitBreakerEventMessage }
        \cup { [ZeroMarketWideCircuitBreakerEventMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader8 }
        \cup { [ZeroMarketWideCircuitBreakerEventMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerEventMessage EXCEPT !.actionDatetime = one] : one \in CheckedActionDatetime2 }
        \cup { [ZeroMarketWideCircuitBreakerEventMessage EXCEPT !.marketWideCircuitBreakerReasonCode = one] : one \in Sample(6) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

GeneralAdministrativeMessageCode == 65  \* "A"
ClosingTradeSummaryReportMessageCode == 50  \* "2"
TradingActionMessageCode == 72  \* "H"
MarketWideCircuitBreakerEventMessageCode == 77  \* "M"

AdministrativeMessagePayload ==
    [ tag : {GeneralAdministrativeMessageCode}, body : GeneralAdministrativeMessage ]
        \cup [ tag : {ClosingTradeSummaryReportMessageCode}, body : ClosingTradeSummaryReportMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {MarketWideCircuitBreakerEventMessageCode}, body : MarketWideCircuitBreakerEventMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = GeneralAdministrativeMessageCode -> EncodeGeneralAdministrativeMessage(message.body)
      [] message.tag = ClosingTradeSummaryReportMessageCode -> EncodeClosingTradeSummaryReportMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerEventMessageCode -> EncodeMarketWideCircuitBreakerEventMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = GeneralAdministrativeMessageCode -> DecodeGeneralAdministrativeMessage(bytes)
              [] tag = ClosingTradeSummaryReportMessageCode -> DecodeClosingTradeSummaryReportMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = MarketWideCircuitBreakerEventMessageCode -> DecodeMarketWideCircuitBreakerEventMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> GeneralAdministrativeMessageCode, body |-> ZeroGeneralAdministrativeMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> GeneralAdministrativeMessageCode, body |-> one] : one \in CheckedGeneralAdministrativeMessage }
        \cup { [tag |-> ClosingTradeSummaryReportMessageCode, body |-> one] : one \in CheckedClosingTradeSummaryReportMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> MarketWideCircuitBreakerEventMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerEventMessage }

(***************************************************************************)
(* Administrative Message                                                  *)
(***************************************************************************)

AdministrativeMessage ==
    [ administrativeMessagePayload : AdministrativeMessagePayload ]

EncodeAdministrativeMessage(message) ==
    EncodeUIntBE(message.administrativeMessagePayload.tag, 1)
        \o EncodeAdministrativeMessagePayload(message.administrativeMessagePayload)

DecodeAdministrativeMessage(bytes) ==
    LET administrativeMessageType == ReadUIntBE(bytes, 1) IN IF ~administrativeMessageType.ok THEN Fail ELSE
    LET administrativeMessagePayload == DecodeAdministrativeMessagePayload(administrativeMessageType.value, administrativeMessageType.rest) IN IF ~administrativeMessagePayload.ok THEN Fail ELSE
    Ok([ administrativeMessagePayload |-> administrativeMessagePayload.value ], administrativeMessagePayload.rest)

ZeroAdministrativeMessage ==
    [ administrativeMessagePayload |-> ZeroAdministrativeMessagePayload ]

(* Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedAdministrativeMessage ==
    { ZeroAdministrativeMessage }
        \cup { [ZeroAdministrativeMessage EXCEPT !.administrativeMessagePayload = one] : one \in CheckedAdministrativeMessagePayload }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime9 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime9(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime9(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime9 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime9 ==
    { ZeroDatetime9 }
        \cup { [ZeroDatetime9 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime9 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader9 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime9 ]

EncodeMessageHeader9(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime9(message.datetime)

DecodeMessageHeader9(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime9(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader9 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime9 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader9 ==
    { ZeroMessageHeader9 }
        \cup { [ZeroMessageHeader9 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader9 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader9 EXCEPT !.datetime = one] : one \in CheckedDatetime9 }

(***************************************************************************)
(* Start Of Day Message: 33 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ messageHeader : MessageHeader9 ]

EncodeStartOfDayMessage(message) ==
    EncodeMessageHeader9(message.messageHeader)

DecodeStartOfDayMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader9(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroStartOfDayMessage ==
    [ messageHeader |-> ZeroMessageHeader9 ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader9 }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime10 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime10(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime10(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime10 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime10 ==
    { ZeroDatetime10 }
        \cup { [ZeroDatetime10 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime10 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader10 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime10 ]

EncodeMessageHeader10(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime10(message.datetime)

DecodeMessageHeader10(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime10(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader10 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime10 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader10 ==
    { ZeroMessageHeader10 }
        \cup { [ZeroMessageHeader10 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader10 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader10 EXCEPT !.datetime = one] : one \in CheckedDatetime10 }

(***************************************************************************)
(* End Of Day Message: 33 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ messageHeader : MessageHeader10 ]

EncodeEndOfDayMessage(message) ==
    EncodeMessageHeader10(message.messageHeader)

DecodeEndOfDayMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader10(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroEndOfDayMessage ==
    [ messageHeader |-> ZeroMessageHeader10 ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader10 }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime11 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime11(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime11(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime11 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime11 ==
    { ZeroDatetime11 }
        \cup { [ZeroDatetime11 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime11 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader11 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime11 ]

EncodeMessageHeader11(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime11(message.datetime)

DecodeMessageHeader11(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime11(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader11 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime11 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader11 ==
    { ZeroMessageHeader11 }
        \cup { [ZeroMessageHeader11 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader11 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader11 EXCEPT !.datetime = one] : one \in CheckedDatetime11 }

(***************************************************************************)
(* Market Session Open Message: 33 bytes                                   *)
(***************************************************************************)

MarketSessionOpenMessage ==
    [ messageHeader : MessageHeader11 ]

EncodeMarketSessionOpenMessage(message) ==
    EncodeMessageHeader11(message.messageHeader)

DecodeMarketSessionOpenMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader11(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroMarketSessionOpenMessage ==
    [ messageHeader |-> ZeroMessageHeader11 ]

(* Market Session Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionOpenMessage ==
    { ZeroMarketSessionOpenMessage }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader11 }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime12 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime12(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime12(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime12 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime12 ==
    { ZeroDatetime12 }
        \cup { [ZeroDatetime12 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime12 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader12 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime12 ]

EncodeMessageHeader12(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime12(message.datetime)

DecodeMessageHeader12(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime12(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader12 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime12 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader12 ==
    { ZeroMessageHeader12 }
        \cup { [ZeroMessageHeader12 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader12 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader12 EXCEPT !.datetime = one] : one \in CheckedDatetime12 }

(***************************************************************************)
(* Market Session Close Message: 33 bytes                                  *)
(***************************************************************************)

MarketSessionCloseMessage ==
    [ messageHeader : MessageHeader12 ]

EncodeMarketSessionCloseMessage(message) ==
    EncodeMessageHeader12(message.messageHeader)

DecodeMarketSessionCloseMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader12(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroMarketSessionCloseMessage ==
    [ messageHeader |-> ZeroMessageHeader12 ]

(* Market Session Close Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionCloseMessage ==
    { ZeroMarketSessionCloseMessage }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader12 }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime13 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime13(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime13(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime13 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime13 ==
    { ZeroDatetime13 }
        \cup { [ZeroDatetime13 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime13 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime13 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime13 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime13 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime13 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime13 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader13 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime13 ]

EncodeMessageHeader13(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime13(message.datetime)

DecodeMessageHeader13(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime13(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader13 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime13 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader13 ==
    { ZeroMessageHeader13 }
        \cup { [ZeroMessageHeader13 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader13 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader13 EXCEPT !.datetime = one] : one \in CheckedDatetime13 }

(***************************************************************************)
(* End Of Retransmission Requests Message: 33 bytes                        *)
(***************************************************************************)

EndOfRetransmissionRequestsMessage ==
    [ messageHeader : MessageHeader13 ]

EncodeEndOfRetransmissionRequestsMessage(message) ==
    EncodeMessageHeader13(message.messageHeader)

DecodeEndOfRetransmissionRequestsMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader13(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroEndOfRetransmissionRequestsMessage ==
    [ messageHeader |-> ZeroMessageHeader13 ]

(* End Of Retransmission Requests Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfRetransmissionRequestsMessage ==
    { ZeroEndOfRetransmissionRequestsMessage }
        \cup { [ZeroEndOfRetransmissionRequestsMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader13 }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime14 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime14(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime14(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime14 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime14 ==
    { ZeroDatetime14 }
        \cup { [ZeroDatetime14 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime14 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime14 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime14 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime14 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime14 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime14 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader14 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime14 ]

EncodeMessageHeader14(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime14(message.datetime)

DecodeMessageHeader14(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime14(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader14 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime14 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader14 ==
    { ZeroMessageHeader14 }
        \cup { [ZeroMessageHeader14 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader14 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader14 EXCEPT !.datetime = one] : one \in CheckedDatetime14 }

(***************************************************************************)
(* End Of Transmissions Message: 33 bytes                                  *)
(***************************************************************************)

EndOfTransmissionsMessage ==
    [ messageHeader : MessageHeader14 ]

EncodeEndOfTransmissionsMessage(message) ==
    EncodeMessageHeader14(message.messageHeader)

DecodeEndOfTransmissionsMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader14(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroEndOfTransmissionsMessage ==
    [ messageHeader |-> ZeroMessageHeader14 ]

(* End Of Transmissions Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionsMessage ==
    { ZeroEndOfTransmissionsMessage }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader14 }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime15 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime15(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime15(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime15 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime15 ==
    { ZeroDatetime15 }
        \cup { [ZeroDatetime15 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime15 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime15 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime15 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime15 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime15 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime15 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader15 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime15 ]

EncodeMessageHeader15(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime15(message.datetime)

DecodeMessageHeader15(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime15(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader15 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime15 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader15 ==
    { ZeroMessageHeader15 }
        \cup { [ZeroMessageHeader15 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader15 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader15 EXCEPT !.datetime = one] : one \in CheckedDatetime15 }

(***************************************************************************)
(* Line Integrity Message: 33 bytes                                        *)
(***************************************************************************)

LineIntegrityMessage ==
    [ messageHeader : MessageHeader15 ]

EncodeLineIntegrityMessage(message) ==
    EncodeMessageHeader15(message.messageHeader)

DecodeLineIntegrityMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader15(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroLineIntegrityMessage ==
    [ messageHeader |-> ZeroMessageHeader15 ]

(* Line Integrity Message at zero, then each field in turn at the values it is checked at *)
CheckedLineIntegrityMessage ==
    { ZeroLineIntegrityMessage }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader15 }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime16 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime16(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime16(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime16 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime16 ==
    { ZeroDatetime16 }
        \cup { [ZeroDatetime16 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime16 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime16 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime16 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime16 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime16 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime16 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader16 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime16 ]

EncodeMessageHeader16(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime16(message.datetime)

DecodeMessageHeader16(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime16(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader16 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime16 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader16 ==
    { ZeroMessageHeader16 }
        \cup { [ZeroMessageHeader16 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader16 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader16 EXCEPT !.datetime = one] : one \in CheckedDatetime16 }

(***************************************************************************)
(* Sequence Number Reset Message: 33 bytes                                 *)
(***************************************************************************)

SequenceNumberResetMessage ==
    [ messageHeader : MessageHeader16 ]

EncodeSequenceNumberResetMessage(message) ==
    EncodeMessageHeader16(message.messageHeader)

DecodeSequenceNumberResetMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader16(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroSequenceNumberResetMessage ==
    [ messageHeader |-> ZeroMessageHeader16 ]

(* Sequence Number Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceNumberResetMessage ==
    { ZeroSequenceNumberResetMessage }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader16 }

(***************************************************************************)
(* Datetime: 23 bytes                                                      *)
(***************************************************************************)

Datetime17 ==
    [ year             : Sample(4),
      month            : Sample(2),
      day              : Sample(2),
      hour             : Sample(2),
      minute           : Sample(2),
      second           : Sample(2),
      fractionalSecond : Sample(9) ]

EncodeDatetime17(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second
        \o message.fractionalSecond

DecodeDatetime17(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    LET fractionalSecond == ReadBytes(second.rest, 9) IN IF ~fractionalSecond.ok THEN Fail ELSE
    Ok([ year             |-> year.value,
         month            |-> month.value,
         day              |-> day.value,
         hour             |-> hour.value,
         minute           |-> minute.value,
         second           |-> second.value,
         fractionalSecond |-> fractionalSecond.value ], fractionalSecond.rest)

ZeroDatetime17 ==
    [ year             |-> [i \in 1 .. 4 |-> 0],
      month            |-> [i \in 1 .. 2 |-> 0],
      day              |-> [i \in 1 .. 2 |-> 0],
      hour             |-> [i \in 1 .. 2 |-> 0],
      minute           |-> [i \in 1 .. 2 |-> 0],
      second           |-> [i \in 1 .. 2 |-> 0],
      fractionalSecond |-> [i \in 1 .. 9 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime17 ==
    { ZeroDatetime17 }
        \cup { [ZeroDatetime17 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime17 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime17 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime17 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime17 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime17 EXCEPT !.second = one] : one \in Sample(2) }
        \cup { [ZeroDatetime17 EXCEPT !.fractionalSecond = one] : one \in Sample(9) }

(***************************************************************************)
(* Message Header: 33 bytes                                                *)
(***************************************************************************)

MessageHeader17 ==
    [ tradeIdentifier          : Sample(8),
      marketCenterOriginatorId : Sample(2),
      datetime                 : Datetime17 ]

EncodeMessageHeader17(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime17(message.datetime)

DecodeMessageHeader17(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 8) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 2) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime17(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader17 ==
    [ tradeIdentifier          |-> [i \in 1 .. 8 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 2 |-> 0],
      datetime                 |-> ZeroDatetime17 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader17 ==
    { ZeroMessageHeader17 }
        \cup { [ZeroMessageHeader17 EXCEPT !.tradeIdentifier = one] : one \in Sample(8) }
        \cup { [ZeroMessageHeader17 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(2) }
        \cup { [ZeroMessageHeader17 EXCEPT !.datetime = one] : one \in CheckedDatetime17 }

(***************************************************************************)
(* End Of Trade Reporting Message: 33 bytes                                *)
(***************************************************************************)

EndOfTradeReportingMessage ==
    [ messageHeader : MessageHeader17 ]

EncodeEndOfTradeReportingMessage(message) ==
    EncodeMessageHeader17(message.messageHeader)

DecodeEndOfTradeReportingMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader17(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroEndOfTradeReportingMessage ==
    [ messageHeader |-> ZeroMessageHeader17 ]

(* End Of Trade Reporting Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTradeReportingMessage ==
    { ZeroEndOfTradeReportingMessage }
        \cup { [ZeroEndOfTradeReportingMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader17 }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 73  \* "I"
EndOfDayMessageCode == 74  \* "J"
MarketSessionOpenMessageCode == 79  \* "O"
MarketSessionCloseMessageCode == 67  \* "C"
EndOfRetransmissionRequestsMessageCode == 75  \* "K"
EndOfTransmissionsMessageCode == 90  \* "Z"
LineIntegrityMessageCode == 84  \* "T"
SequenceNumberResetMessageCode == 76  \* "L"
EndOfTradeReportingMessageCode == 88  \* "X"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]
        \cup [ tag : {MarketSessionOpenMessageCode}, body : MarketSessionOpenMessage ]
        \cup [ tag : {MarketSessionCloseMessageCode}, body : MarketSessionCloseMessage ]
        \cup [ tag : {EndOfRetransmissionRequestsMessageCode}, body : EndOfRetransmissionRequestsMessage ]
        \cup [ tag : {EndOfTransmissionsMessageCode}, body : EndOfTransmissionsMessage ]
        \cup [ tag : {LineIntegrityMessageCode}, body : LineIntegrityMessage ]
        \cup [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]
        \cup [ tag : {EndOfTradeReportingMessageCode}, body : EndOfTradeReportingMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)
      [] message.tag = MarketSessionOpenMessageCode -> EncodeMarketSessionOpenMessage(message.body)
      [] message.tag = MarketSessionCloseMessageCode -> EncodeMarketSessionCloseMessage(message.body)
      [] message.tag = EndOfRetransmissionRequestsMessageCode -> EncodeEndOfRetransmissionRequestsMessage(message.body)
      [] message.tag = EndOfTransmissionsMessageCode -> EncodeEndOfTransmissionsMessage(message.body)
      [] message.tag = LineIntegrityMessageCode -> EncodeLineIntegrityMessage(message.body)
      [] message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)
      [] message.tag = EndOfTradeReportingMessageCode -> EncodeEndOfTradeReportingMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] tag = MarketSessionOpenMessageCode -> DecodeMarketSessionOpenMessage(bytes)
              [] tag = MarketSessionCloseMessageCode -> DecodeMarketSessionCloseMessage(bytes)
              [] tag = EndOfRetransmissionRequestsMessageCode -> DecodeEndOfRetransmissionRequestsMessage(bytes)
              [] tag = EndOfTransmissionsMessageCode -> DecodeEndOfTransmissionsMessage(bytes)
              [] tag = LineIntegrityMessageCode -> DecodeLineIntegrityMessage(bytes)
              [] tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] tag = EndOfTradeReportingMessageCode -> DecodeEndOfTradeReportingMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> EndOfDayMessageCode, body |-> one] : one \in CheckedEndOfDayMessage }
        \cup { [tag |-> MarketSessionOpenMessageCode, body |-> one] : one \in CheckedMarketSessionOpenMessage }
        \cup { [tag |-> MarketSessionCloseMessageCode, body |-> one] : one \in CheckedMarketSessionCloseMessage }
        \cup { [tag |-> EndOfRetransmissionRequestsMessageCode, body |-> one] : one \in CheckedEndOfRetransmissionRequestsMessage }
        \cup { [tag |-> EndOfTransmissionsMessageCode, body |-> one] : one \in CheckedEndOfTransmissionsMessage }
        \cup { [tag |-> LineIntegrityMessageCode, body |-> one] : one \in CheckedLineIntegrityMessage }
        \cup { [tag |-> SequenceNumberResetMessageCode, body |-> one] : one \in CheckedSequenceNumberResetMessage }
        \cup { [tag |-> EndOfTradeReportingMessageCode, body |-> one] : one \in CheckedEndOfTradeReportingMessage }

(***************************************************************************)
(* Control Message                                                         *)
(***************************************************************************)

ControlMessage ==
    [ controlMessagePayload : ControlMessagePayload ]

EncodeControlMessage(message) ==
    EncodeUIntBE(message.controlMessagePayload.tag, 1)
        \o EncodeControlMessagePayload(message.controlMessagePayload)

DecodeControlMessage(bytes) ==
    LET controlMessageType == ReadUIntBE(bytes, 1) IN IF ~controlMessageType.ok THEN Fail ELSE
    LET controlMessagePayload == DecodeControlMessagePayload(controlMessageType.value, controlMessageType.rest) IN IF ~controlMessagePayload.ok THEN Fail ELSE
    Ok([ controlMessagePayload |-> controlMessagePayload.value ], controlMessagePayload.rest)

ZeroControlMessage ==
    [ controlMessagePayload |-> ZeroControlMessagePayload ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.controlMessagePayload = one] : one \in CheckedControlMessagePayload }

(***************************************************************************)
(* Payload, selected by Message Category                                   *)
(***************************************************************************)

TradeMessageCode == 84  \* "T"
AdministrativeMessageCode == 65  \* "A"
ControlMessageCode == 67  \* "C"

Payload ==
    [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodePayload(message) ==
    CASE message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }

(***************************************************************************)
(* Message, framed by Length                                               *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageCategory == ReadUIntBE(bytes, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET payload == DecodePayload(messageCategory.value, messageCategory.rest) IN IF ~payload.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session  : Sample(10),
      sequence : Sample(8),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET count == ReadUIntBE(sequence.rest, 2) IN IF ~count.ok THEN Fail ELSE
    LET message == ReadMessageList(count.rest, count.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session  |-> session.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ session  |-> [i \in 1 .. 10 |-> 0],
      sequence |-> [i \in 1 .. 8 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(8) }
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

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime ==
    \A message \in CheckedDatetime :
        LET read == DecodeDatetime(EncodeDatetime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader ==
    \A message \in CheckedMessageHeader :
        LET read == DecodeMessageHeader(EncodeMessageHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportShortFormMessage ==
    \A message \in CheckedTradeReportShortFormMessage :
        LET read == DecodeTradeReportShortFormMessage(EncodeTradeReportShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime2 ==
    \A message \in CheckedDatetime2 :
        LET read == DecodeDatetime2(EncodeDatetime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader2 ==
    \A message \in CheckedMessageHeader2 :
        LET read == DecodeMessageHeader2(EncodeMessageHeader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Dissemination Date decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalDisseminationDate ==
    \A message \in CheckedOriginalDisseminationDate :
        LET read == DecodeOriginalDisseminationDate(EncodeOriginalDisseminationDate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionDatetime ==
    \A message \in CheckedExecutionDatetime :
        LET read == DecodeExecutionDatetime(EncodeExecutionDatetime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Information decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeInformation ==
    \A message \in CheckedTradeInformation :
        LET read == DecodeTradeInformation(EncodeTradeInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportLongFormMessage ==
    \A message \in CheckedTradeReportLongFormMessage :
        LET read == DecodeTradeReportLongFormMessage(EncodeTradeReportLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime3 ==
    \A message \in CheckedDatetime3 :
        LET read == DecodeDatetime3(EncodeDatetime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader3 ==
    \A message \in CheckedMessageHeader3 :
        LET read == DecodeMessageHeader3(EncodeMessageHeader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Dissemination Date decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalDisseminationDate2 ==
    \A message \in CheckedOriginalDisseminationDate2 :
        LET read == DecodeOriginalDisseminationDate2(EncodeOriginalDisseminationDate2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionDatetime2 ==
    \A message \in CheckedExecutionDatetime2 :
        LET read == DecodeExecutionDatetime2(EncodeExecutionDatetime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Trade Information decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalTradeInformation ==
    \A message \in CheckedOriginalTradeInformation :
        LET read == DecodeOriginalTradeInformation(EncodeOriginalTradeInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Summary Information decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSummaryInformation ==
    \A message \in CheckedTradeSummaryInformation :
        LET read == DecodeTradeSummaryInformation(EncodeTradeSummaryInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorMessage ==
    \A message \in CheckedTradeCancelErrorMessage :
        LET read == DecodeTradeCancelErrorMessage(EncodeTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime4 ==
    \A message \in CheckedDatetime4 :
        LET read == DecodeDatetime4(EncodeDatetime4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader4 ==
    \A message \in CheckedMessageHeader4 :
        LET read == DecodeMessageHeader4(EncodeMessageHeader4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Dissemination Date decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalDisseminationDate3 ==
    \A message \in CheckedOriginalDisseminationDate3 :
        LET read == DecodeOriginalDisseminationDate3(EncodeOriginalDisseminationDate3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionDatetime3 ==
    \A message \in CheckedExecutionDatetime3 :
        LET read == DecodeExecutionDatetime3(EncodeExecutionDatetime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Trade Information decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalTradeInformation2 ==
    \A message \in CheckedOriginalTradeInformation2 :
        LET read == DecodeOriginalTradeInformation2(EncodeOriginalTradeInformation2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionDatetime4 ==
    \A message \in CheckedExecutionDatetime4 :
        LET read == DecodeExecutionDatetime4(EncodeExecutionDatetime4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Trade Information decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedTradeInformation ==
    \A message \in CheckedCorrectedTradeInformation :
        LET read == DecodeCorrectedTradeInformation(EncodeCorrectedTradeInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Summary Information decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSummaryInformation2 ==
    \A message \in CheckedTradeSummaryInformation2 :
        LET read == DecodeTradeSummaryInformation2(EncodeTradeSummaryInformation2(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime5 ==
    \A message \in CheckedDatetime5 :
        LET read == DecodeDatetime5(EncodeDatetime5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader5 ==
    \A message \in CheckedMessageHeader5 :
        LET read == DecodeMessageHeader5(EncodeMessageHeader5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every General Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralAdministrativeMessage ==
    \A message \in CheckedGeneralAdministrativeMessage :
        LET read == DecodeGeneralAdministrativeMessage(EncodeGeneralAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime6 ==
    \A message \in CheckedDatetime6 :
        LET read == DecodeDatetime6(EncodeDatetime6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader6 ==
    \A message \in CheckedMessageHeader6 :
        LET read == DecodeMessageHeader6(EncodeMessageHeader6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Closing Trade Summary Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClosingTradeSummaryReportMessage ==
    \A message \in CheckedClosingTradeSummaryReportMessage :
        LET read == DecodeClosingTradeSummaryReportMessage(EncodeClosingTradeSummaryReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime7 ==
    \A message \in CheckedDatetime7 :
        LET read == DecodeDatetime7(EncodeDatetime7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader7 ==
    \A message \in CheckedMessageHeader7 :
        LET read == DecodeMessageHeader7(EncodeMessageHeader7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Action Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripActionDatetime ==
    \A message \in CheckedActionDatetime :
        LET read == DecodeActionDatetime(EncodeActionDatetime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingActionMessage ==
    \A message \in CheckedTradingActionMessage :
        LET read == DecodeTradingActionMessage(EncodeTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime8 ==
    \A message \in CheckedDatetime8 :
        LET read == DecodeDatetime8(EncodeDatetime8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader8 ==
    \A message \in CheckedMessageHeader8 :
        LET read == DecodeMessageHeader8(EncodeMessageHeader8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Action Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripActionDatetime2 ==
    \A message \in CheckedActionDatetime2 :
        LET read == DecodeActionDatetime2(EncodeActionDatetime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerEventMessage ==
    \A message \in CheckedMarketWideCircuitBreakerEventMessage :
        LET read == DecodeMarketWideCircuitBreakerEventMessage(EncodeMarketWideCircuitBreakerEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdministrativeMessage ==
    \A message \in CheckedAdministrativeMessage :
        LET read == DecodeAdministrativeMessage(EncodeAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime9 ==
    \A message \in CheckedDatetime9 :
        LET read == DecodeDatetime9(EncodeDatetime9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader9 ==
    \A message \in CheckedMessageHeader9 :
        LET read == DecodeMessageHeader9(EncodeMessageHeader9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfDayMessage ==
    \A message \in CheckedStartOfDayMessage :
        LET read == DecodeStartOfDayMessage(EncodeStartOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime10 ==
    \A message \in CheckedDatetime10 :
        LET read == DecodeDatetime10(EncodeDatetime10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader10 ==
    \A message \in CheckedMessageHeader10 :
        LET read == DecodeMessageHeader10(EncodeMessageHeader10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayMessage ==
    \A message \in CheckedEndOfDayMessage :
        LET read == DecodeEndOfDayMessage(EncodeEndOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime11 ==
    \A message \in CheckedDatetime11 :
        LET read == DecodeDatetime11(EncodeDatetime11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader11 ==
    \A message \in CheckedMessageHeader11 :
        LET read == DecodeMessageHeader11(EncodeMessageHeader11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Session Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionOpenMessage ==
    \A message \in CheckedMarketSessionOpenMessage :
        LET read == DecodeMarketSessionOpenMessage(EncodeMarketSessionOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime12 ==
    \A message \in CheckedDatetime12 :
        LET read == DecodeDatetime12(EncodeDatetime12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader12 ==
    \A message \in CheckedMessageHeader12 :
        LET read == DecodeMessageHeader12(EncodeMessageHeader12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Session Close Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionCloseMessage ==
    \A message \in CheckedMarketSessionCloseMessage :
        LET read == DecodeMarketSessionCloseMessage(EncodeMarketSessionCloseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime13 ==
    \A message \in CheckedDatetime13 :
        LET read == DecodeDatetime13(EncodeDatetime13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader13 ==
    \A message \in CheckedMessageHeader13 :
        LET read == DecodeMessageHeader13(EncodeMessageHeader13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Retransmission Requests Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfRetransmissionRequestsMessage ==
    \A message \in CheckedEndOfRetransmissionRequestsMessage :
        LET read == DecodeEndOfRetransmissionRequestsMessage(EncodeEndOfRetransmissionRequestsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime14 ==
    \A message \in CheckedDatetime14 :
        LET read == DecodeDatetime14(EncodeDatetime14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader14 ==
    \A message \in CheckedMessageHeader14 :
        LET read == DecodeMessageHeader14(EncodeMessageHeader14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Transmissions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmissionsMessage ==
    \A message \in CheckedEndOfTransmissionsMessage :
        LET read == DecodeEndOfTransmissionsMessage(EncodeEndOfTransmissionsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime15 ==
    \A message \in CheckedDatetime15 :
        LET read == DecodeDatetime15(EncodeDatetime15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader15 ==
    \A message \in CheckedMessageHeader15 :
        LET read == DecodeMessageHeader15(EncodeMessageHeader15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Line Integrity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLineIntegrityMessage ==
    \A message \in CheckedLineIntegrityMessage :
        LET read == DecodeLineIntegrityMessage(EncodeLineIntegrityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime16 ==
    \A message \in CheckedDatetime16 :
        LET read == DecodeDatetime16(EncodeDatetime16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader16 ==
    \A message \in CheckedMessageHeader16 :
        LET read == DecodeMessageHeader16(EncodeMessageHeader16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Number Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceNumberResetMessage ==
    \A message \in CheckedSequenceNumberResetMessage :
        LET read == DecodeSequenceNumberResetMessage(EncodeSequenceNumberResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Datetime decodes back to what was encoded, and leaves nothing over *)
RoundTripDatetime17 ==
    \A message \in CheckedDatetime17 :
        LET read == DecodeDatetime17(EncodeDatetime17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageHeader17 ==
    \A message \in CheckedMessageHeader17 :
        LET read == DecodeMessageHeader17(EncodeMessageHeader17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Trade Reporting Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTradeReportingMessage ==
    \A message \in CheckedEndOfTradeReportingMessage :
        LET read == DecodeEndOfTradeReportingMessage(EncodeEndOfTradeReportingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripControlMessage ==
    \A message \in CheckedControlMessage :
        LET read == DecodeControlMessage(EncodeControlMessage(message))
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

(* A Trade Message Payload is selected by the Trade Message Type it is written under *)
SelectsTradeMessagePayload ==
    \A message \in CheckedTradeMessagePayload :
        LET read == DecodeTradeMessagePayload(message.tag, EncodeTradeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Administrative Message Payload is selected by the Administrative Message Type it is written under *)
SelectsAdministrativeMessagePayload ==
    \A message \in CheckedAdministrativeMessagePayload :
        LET read == DecodeAdministrativeMessagePayload(message.tag, EncodeAdministrativeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Control Message Payload is selected by the Control Message Type it is written under *)
SelectsControlMessagePayload ==
    \A message \in CheckedControlMessagePayload :
        LET read == DecodeControlMessagePayload(message.tag, EncodeControlMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Message Category it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Length is written from the bytes it frames *)
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
