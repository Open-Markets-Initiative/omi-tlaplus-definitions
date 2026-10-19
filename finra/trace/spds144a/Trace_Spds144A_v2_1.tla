------------------------ MODULE Trace_Spds144A_v2_1 ------------------------
(***************************************************************************)
(* Financial Industry Regulatory Authority Securitized Products            *)
(* Dissemination Service for 144A Transactions v2.1                        *)
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
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime ==
    { ZeroDatetime }
        \cup { [ZeroDatetime EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime ]

EncodeMessageHeader(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime(message.datetime)

DecodeMessageHeader(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader ==
    { ZeroMessageHeader }
        \cup { [ZeroMessageHeader EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader EXCEPT !.datetime = one] : one \in CheckedDatetime }

(***************************************************************************)
(* Label: 40 bytes                                                         *)
(***************************************************************************)

Label ==
    [ symbol         : Sample(14),
      cusip          : Sample(9),
      bsym           : Sample(12),
      subProductType : Sample(5) ]

EncodeLabel(message) ==
    message.symbol
        \o message.cusip
        \o message.bsym
        \o message.subProductType

DecodeLabel(bytes) ==
    LET symbol == ReadBytes(bytes, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 9) IN IF ~cusip.ok THEN Fail ELSE
    LET bsym == ReadBytes(cusip.rest, 12) IN IF ~bsym.ok THEN Fail ELSE
    LET subProductType == ReadBytes(bsym.rest, 5) IN IF ~subProductType.ok THEN Fail ELSE
    Ok([ symbol         |-> symbol.value,
         cusip          |-> cusip.value,
         bsym           |-> bsym.value,
         subProductType |-> subProductType.value ], subProductType.rest)

ZeroLabel ==
    [ symbol         |-> [i \in 1 .. 14 |-> 0],
      cusip          |-> [i \in 1 .. 9 |-> 0],
      bsym           |-> [i \in 1 .. 12 |-> 0],
      subProductType |-> [i \in 1 .. 5 |-> 0] ]

(* Label at zero, then each field in turn at the values it is checked at *)
CheckedLabel ==
    { ZeroLabel }
        \cup { [ZeroLabel EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroLabel EXCEPT !.cusip = one] : one \in Sample(9) }
        \cup { [ZeroLabel EXCEPT !.bsym = one] : one \in Sample(12) }
        \cup { [ZeroLabel EXCEPT !.subProductType = one] : one \in Sample(5) }

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
(* Execution Datetime: 14 bytes                                            *)
(***************************************************************************)

ExecutionDatetime ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeExecutionDatetime(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeExecutionDatetime(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroExecutionDatetime ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Datetime at zero, then each field in turn at the values it is checked at *)
CheckedExecutionDatetime ==
    { ZeroExecutionDatetime }
        \cup { [ZeroExecutionDatetime EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroExecutionDatetime EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Settlement Date: 8 bytes                                                *)
(***************************************************************************)

SettlementDate ==
    [ year  : Sample(4),
      month : Sample(2),
      day   : Sample(2) ]

EncodeSettlementDate(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSettlementDate(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSettlementDate ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 2 |-> 0],
      day   |-> [i \in 1 .. 2 |-> 0] ]

(* Settlement Date at zero, then each field in turn at the values it is checked at *)
CheckedSettlementDate ==
    { ZeroSettlementDate }
        \cup { [ZeroSettlementDate EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSettlementDate EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroSettlementDate EXCEPT !.day = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Information: 71 bytes                                             *)
(***************************************************************************)

TradeInformation ==
    [ quantityIndicator     : Sample(1),
      quantity              : Sample(14),
      price                 : Sample(11),
      remuneration          : Sample(1),
      specialPriceIndicator : Sample(1),
      side                  : Sample(1),
      asOfIndicator         : Sample(1),
      executionDatetime     : ExecutionDatetime,
      futureUse             : Sample(2),
      saleCondition3        : Sample(1),
      saleCondition4        : Sample(1),
      settlementDate        : SettlementDate,
      factor                : Sample(12),
      reportingPartyType    : Sample(1),
      contraPartyType       : Sample(1),
      atsIndicator          : Sample(1) ]

EncodeTradeInformation(message) ==
    message.quantityIndicator
        \o message.quantity
        \o message.price
        \o message.remuneration
        \o message.specialPriceIndicator
        \o message.side
        \o message.asOfIndicator
        \o EncodeExecutionDatetime(message.executionDatetime)
        \o message.futureUse
        \o message.saleCondition3
        \o message.saleCondition4
        \o EncodeSettlementDate(message.settlementDate)
        \o message.factor
        \o message.reportingPartyType
        \o message.contraPartyType
        \o message.atsIndicator

DecodeTradeInformation(bytes) ==
    LET quantityIndicator == ReadBytes(bytes, 1) IN IF ~quantityIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantityIndicator.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET remuneration == ReadBytes(price.rest, 1) IN IF ~remuneration.ok THEN Fail ELSE
    LET specialPriceIndicator == ReadBytes(remuneration.rest, 1) IN IF ~specialPriceIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(specialPriceIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET asOfIndicator == ReadBytes(side.rest, 1) IN IF ~asOfIndicator.ok THEN Fail ELSE
    LET executionDatetime == DecodeExecutionDatetime(asOfIndicator.rest) IN IF ~executionDatetime.ok THEN Fail ELSE
    LET futureUse == ReadBytes(executionDatetime.rest, 2) IN IF ~futureUse.ok THEN Fail ELSE
    LET saleCondition3 == ReadBytes(futureUse.rest, 1) IN IF ~saleCondition3.ok THEN Fail ELSE
    LET saleCondition4 == ReadBytes(saleCondition3.rest, 1) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET settlementDate == DecodeSettlementDate(saleCondition4.rest) IN IF ~settlementDate.ok THEN Fail ELSE
    LET factor == ReadBytes(settlementDate.rest, 12) IN IF ~factor.ok THEN Fail ELSE
    LET reportingPartyType == ReadBytes(factor.rest, 1) IN IF ~reportingPartyType.ok THEN Fail ELSE
    LET contraPartyType == ReadBytes(reportingPartyType.rest, 1) IN IF ~contraPartyType.ok THEN Fail ELSE
    LET atsIndicator == ReadBytes(contraPartyType.rest, 1) IN IF ~atsIndicator.ok THEN Fail ELSE
    Ok([ quantityIndicator     |-> quantityIndicator.value,
         quantity              |-> quantity.value,
         price                 |-> price.value,
         remuneration          |-> remuneration.value,
         specialPriceIndicator |-> specialPriceIndicator.value,
         side                  |-> side.value,
         asOfIndicator         |-> asOfIndicator.value,
         executionDatetime     |-> executionDatetime.value,
         futureUse             |-> futureUse.value,
         saleCondition3        |-> saleCondition3.value,
         saleCondition4        |-> saleCondition4.value,
         settlementDate        |-> settlementDate.value,
         factor                |-> factor.value,
         reportingPartyType    |-> reportingPartyType.value,
         contraPartyType       |-> contraPartyType.value,
         atsIndicator          |-> atsIndicator.value ], atsIndicator.rest)

ZeroTradeInformation ==
    [ quantityIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 14 |-> 0],
      price                 |-> [i \in 1 .. 11 |-> 0],
      remuneration          |-> [i \in 1 .. 1 |-> 0],
      specialPriceIndicator |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      asOfIndicator         |-> [i \in 1 .. 1 |-> 0],
      executionDatetime     |-> ZeroExecutionDatetime,
      futureUse             |-> [i \in 1 .. 2 |-> 0],
      saleCondition3        |-> [i \in 1 .. 1 |-> 0],
      saleCondition4        |-> [i \in 1 .. 1 |-> 0],
      settlementDate        |-> ZeroSettlementDate,
      factor                |-> [i \in 1 .. 12 |-> 0],
      reportingPartyType    |-> [i \in 1 .. 1 |-> 0],
      contraPartyType       |-> [i \in 1 .. 1 |-> 0],
      atsIndicator          |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Information at zero, then each field in turn at the values it is checked at *)
CheckedTradeInformation ==
    { ZeroTradeInformation }
        \cup { [ZeroTradeInformation EXCEPT !.quantityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroTradeInformation EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroTradeInformation EXCEPT !.remuneration = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.specialPriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.asOfIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.executionDatetime = one] : one \in CheckedExecutionDatetime }
        \cup { [ZeroTradeInformation EXCEPT !.futureUse = one] : one \in Sample(2) }
        \cup { [ZeroTradeInformation EXCEPT !.saleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.saleCondition4 = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.settlementDate = one] : one \in CheckedSettlementDate }
        \cup { [ZeroTradeInformation EXCEPT !.factor = one] : one \in Sample(12) }
        \cup { [ZeroTradeInformation EXCEPT !.reportingPartyType = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.contraPartyType = one] : one \in Sample(1) }
        \cup { [ZeroTradeInformation EXCEPT !.atsIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Message: 142 bytes                                         *)
(***************************************************************************)

TradeReportMessage ==
    [ messageHeader             : MessageHeader,
      label                     : Label,
      originalDisseminationDate : OriginalDisseminationDate,
      tradeInformation          : TradeInformation,
      changeIndicator           : Sample(1) ]

EncodeTradeReportMessage(message) ==
    EncodeMessageHeader(message.messageHeader)
        \o EncodeLabel(message.label)
        \o EncodeOriginalDisseminationDate(message.originalDisseminationDate)
        \o EncodeTradeInformation(message.tradeInformation)
        \o message.changeIndicator

DecodeTradeReportMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET label == DecodeLabel(messageHeader.rest) IN IF ~label.ok THEN Fail ELSE
    LET originalDisseminationDate == DecodeOriginalDisseminationDate(label.rest) IN IF ~originalDisseminationDate.ok THEN Fail ELSE
    LET tradeInformation == DecodeTradeInformation(originalDisseminationDate.rest) IN IF ~tradeInformation.ok THEN Fail ELSE
    LET changeIndicator == ReadBytes(tradeInformation.rest, 1) IN IF ~changeIndicator.ok THEN Fail ELSE
    Ok([ messageHeader             |-> messageHeader.value,
         label                     |-> label.value,
         originalDisseminationDate |-> originalDisseminationDate.value,
         tradeInformation          |-> tradeInformation.value,
         changeIndicator           |-> changeIndicator.value ], changeIndicator.rest)

ZeroTradeReportMessage ==
    [ messageHeader             |-> ZeroMessageHeader,
      label                     |-> ZeroLabel,
      originalDisseminationDate |-> ZeroOriginalDisseminationDate,
      tradeInformation          |-> ZeroTradeInformation,
      changeIndicator           |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader }
        \cup { [ZeroTradeReportMessage EXCEPT !.label = one] : one \in CheckedLabel }
        \cup { [ZeroTradeReportMessage EXCEPT !.originalDisseminationDate = one] : one \in CheckedOriginalDisseminationDate }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeInformation = one] : one \in CheckedTradeInformation }
        \cup { [ZeroTradeReportMessage EXCEPT !.changeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime2 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime2 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime2 ==
    { ZeroDatetime2 }
        \cup { [ZeroDatetime2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime2 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime2 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader2 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime2 ]

EncodeMessageHeader2(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime2(message.datetime)

DecodeMessageHeader2(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime2(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader2 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime2 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader2 ==
    { ZeroMessageHeader2 }
        \cup { [ZeroMessageHeader2 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader2 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader2 EXCEPT !.datetime = one] : one \in CheckedDatetime2 }

(***************************************************************************)
(* Label: 40 bytes                                                         *)
(***************************************************************************)

Label2 ==
    [ symbol         : Sample(14),
      cusip          : Sample(9),
      bsym           : Sample(12),
      subProductType : Sample(5) ]

EncodeLabel2(message) ==
    message.symbol
        \o message.cusip
        \o message.bsym
        \o message.subProductType

DecodeLabel2(bytes) ==
    LET symbol == ReadBytes(bytes, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 9) IN IF ~cusip.ok THEN Fail ELSE
    LET bsym == ReadBytes(cusip.rest, 12) IN IF ~bsym.ok THEN Fail ELSE
    LET subProductType == ReadBytes(bsym.rest, 5) IN IF ~subProductType.ok THEN Fail ELSE
    Ok([ symbol         |-> symbol.value,
         cusip          |-> cusip.value,
         bsym           |-> bsym.value,
         subProductType |-> subProductType.value ], subProductType.rest)

ZeroLabel2 ==
    [ symbol         |-> [i \in 1 .. 14 |-> 0],
      cusip          |-> [i \in 1 .. 9 |-> 0],
      bsym           |-> [i \in 1 .. 12 |-> 0],
      subProductType |-> [i \in 1 .. 5 |-> 0] ]

(* Label at zero, then each field in turn at the values it is checked at *)
CheckedLabel2 ==
    { ZeroLabel2 }
        \cup { [ZeroLabel2 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroLabel2 EXCEPT !.cusip = one] : one \in Sample(9) }
        \cup { [ZeroLabel2 EXCEPT !.bsym = one] : one \in Sample(12) }
        \cup { [ZeroLabel2 EXCEPT !.subProductType = one] : one \in Sample(5) }

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
(* Execution Datetime: 14 bytes                                            *)
(***************************************************************************)

ExecutionDatetime2 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeExecutionDatetime2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeExecutionDatetime2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroExecutionDatetime2 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Datetime at zero, then each field in turn at the values it is checked at *)
CheckedExecutionDatetime2 ==
    { ZeroExecutionDatetime2 }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime2 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Settlement Date: 8 bytes                                                *)
(***************************************************************************)

SettlementDate2 ==
    [ year  : Sample(4),
      month : Sample(2),
      day   : Sample(2) ]

EncodeSettlementDate2(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSettlementDate2(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSettlementDate2 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 2 |-> 0],
      day   |-> [i \in 1 .. 2 |-> 0] ]

(* Settlement Date at zero, then each field in turn at the values it is checked at *)
CheckedSettlementDate2 ==
    { ZeroSettlementDate2 }
        \cup { [ZeroSettlementDate2 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSettlementDate2 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroSettlementDate2 EXCEPT !.day = one] : one \in Sample(2) }

(***************************************************************************)
(* Original Trade Information: 71 bytes                                    *)
(***************************************************************************)

OriginalTradeInformation ==
    [ quantityIndicator     : Sample(1),
      quantity              : Sample(14),
      price                 : Sample(11),
      remuneration          : Sample(1),
      specialPriceIndicator : Sample(1),
      side                  : Sample(1),
      asOfIndicator         : Sample(1),
      executionDatetime     : ExecutionDatetime2,
      futureUse             : Sample(2),
      saleCondition3        : Sample(1),
      saleCondition4        : Sample(1),
      settlementDate        : SettlementDate2,
      factor                : Sample(12),
      reportingPartyType    : Sample(1),
      contraPartyType       : Sample(1),
      atsIndicator          : Sample(1) ]

EncodeOriginalTradeInformation(message) ==
    message.quantityIndicator
        \o message.quantity
        \o message.price
        \o message.remuneration
        \o message.specialPriceIndicator
        \o message.side
        \o message.asOfIndicator
        \o EncodeExecutionDatetime2(message.executionDatetime)
        \o message.futureUse
        \o message.saleCondition3
        \o message.saleCondition4
        \o EncodeSettlementDate2(message.settlementDate)
        \o message.factor
        \o message.reportingPartyType
        \o message.contraPartyType
        \o message.atsIndicator

DecodeOriginalTradeInformation(bytes) ==
    LET quantityIndicator == ReadBytes(bytes, 1) IN IF ~quantityIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantityIndicator.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET remuneration == ReadBytes(price.rest, 1) IN IF ~remuneration.ok THEN Fail ELSE
    LET specialPriceIndicator == ReadBytes(remuneration.rest, 1) IN IF ~specialPriceIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(specialPriceIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET asOfIndicator == ReadBytes(side.rest, 1) IN IF ~asOfIndicator.ok THEN Fail ELSE
    LET executionDatetime == DecodeExecutionDatetime2(asOfIndicator.rest) IN IF ~executionDatetime.ok THEN Fail ELSE
    LET futureUse == ReadBytes(executionDatetime.rest, 2) IN IF ~futureUse.ok THEN Fail ELSE
    LET saleCondition3 == ReadBytes(futureUse.rest, 1) IN IF ~saleCondition3.ok THEN Fail ELSE
    LET saleCondition4 == ReadBytes(saleCondition3.rest, 1) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET settlementDate == DecodeSettlementDate2(saleCondition4.rest) IN IF ~settlementDate.ok THEN Fail ELSE
    LET factor == ReadBytes(settlementDate.rest, 12) IN IF ~factor.ok THEN Fail ELSE
    LET reportingPartyType == ReadBytes(factor.rest, 1) IN IF ~reportingPartyType.ok THEN Fail ELSE
    LET contraPartyType == ReadBytes(reportingPartyType.rest, 1) IN IF ~contraPartyType.ok THEN Fail ELSE
    LET atsIndicator == ReadBytes(contraPartyType.rest, 1) IN IF ~atsIndicator.ok THEN Fail ELSE
    Ok([ quantityIndicator     |-> quantityIndicator.value,
         quantity              |-> quantity.value,
         price                 |-> price.value,
         remuneration          |-> remuneration.value,
         specialPriceIndicator |-> specialPriceIndicator.value,
         side                  |-> side.value,
         asOfIndicator         |-> asOfIndicator.value,
         executionDatetime     |-> executionDatetime.value,
         futureUse             |-> futureUse.value,
         saleCondition3        |-> saleCondition3.value,
         saleCondition4        |-> saleCondition4.value,
         settlementDate        |-> settlementDate.value,
         factor                |-> factor.value,
         reportingPartyType    |-> reportingPartyType.value,
         contraPartyType       |-> contraPartyType.value,
         atsIndicator          |-> atsIndicator.value ], atsIndicator.rest)

ZeroOriginalTradeInformation ==
    [ quantityIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 14 |-> 0],
      price                 |-> [i \in 1 .. 11 |-> 0],
      remuneration          |-> [i \in 1 .. 1 |-> 0],
      specialPriceIndicator |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      asOfIndicator         |-> [i \in 1 .. 1 |-> 0],
      executionDatetime     |-> ZeroExecutionDatetime2,
      futureUse             |-> [i \in 1 .. 2 |-> 0],
      saleCondition3        |-> [i \in 1 .. 1 |-> 0],
      saleCondition4        |-> [i \in 1 .. 1 |-> 0],
      settlementDate        |-> ZeroSettlementDate2,
      factor                |-> [i \in 1 .. 12 |-> 0],
      reportingPartyType    |-> [i \in 1 .. 1 |-> 0],
      contraPartyType       |-> [i \in 1 .. 1 |-> 0],
      atsIndicator          |-> [i \in 1 .. 1 |-> 0] ]

(* Original Trade Information at zero, then each field in turn at the values it is checked at *)
CheckedOriginalTradeInformation ==
    { ZeroOriginalTradeInformation }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.quantityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.remuneration = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.specialPriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.asOfIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.executionDatetime = one] : one \in CheckedExecutionDatetime2 }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.futureUse = one] : one \in Sample(2) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.saleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.saleCondition4 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.settlementDate = one] : one \in CheckedSettlementDate2 }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.factor = one] : one \in Sample(12) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.reportingPartyType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.contraPartyType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation EXCEPT !.atsIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Summary Information: 34 bytes                                     *)
(***************************************************************************)

TradeSummaryInformation ==
    [ highPrice       : Sample(11),
      lowPrice        : Sample(11),
      lastSalePrice   : Sample(11),
      changeIndicator : Sample(1) ]

EncodeTradeSummaryInformation(message) ==
    message.highPrice
        \o message.lowPrice
        \o message.lastSalePrice
        \o message.changeIndicator

DecodeTradeSummaryInformation(bytes) ==
    LET highPrice == ReadBytes(bytes, 11) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 11) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastSalePrice == ReadBytes(lowPrice.rest, 11) IN IF ~lastSalePrice.ok THEN Fail ELSE
    LET changeIndicator == ReadBytes(lastSalePrice.rest, 1) IN IF ~changeIndicator.ok THEN Fail ELSE
    Ok([ highPrice       |-> highPrice.value,
         lowPrice        |-> lowPrice.value,
         lastSalePrice   |-> lastSalePrice.value,
         changeIndicator |-> changeIndicator.value ], changeIndicator.rest)

ZeroTradeSummaryInformation ==
    [ highPrice       |-> [i \in 1 .. 11 |-> 0],
      lowPrice        |-> [i \in 1 .. 11 |-> 0],
      lastSalePrice   |-> [i \in 1 .. 11 |-> 0],
      changeIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Summary Information at zero, then each field in turn at the values it is checked at *)
CheckedTradeSummaryInformation ==
    { ZeroTradeSummaryInformation }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.highPrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.lowPrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.lastSalePrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeSummaryInformation EXCEPT !.changeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Message: 183 bytes                                         *)
(***************************************************************************)

TradeCancelMessage ==
    [ messageHeader             : MessageHeader2,
      label                     : Label2,
      originalDisseminationDate : OriginalDisseminationDate2,
      originalTradeIdentifier   : Sample(7),
      reportFunction            : Sample(1),
      originalTradeInformation  : OriginalTradeInformation,
      tradeSummaryInformation   : TradeSummaryInformation ]

EncodeTradeCancelMessage(message) ==
    EncodeMessageHeader2(message.messageHeader)
        \o EncodeLabel2(message.label)
        \o EncodeOriginalDisseminationDate2(message.originalDisseminationDate)
        \o message.originalTradeIdentifier
        \o message.reportFunction
        \o EncodeOriginalTradeInformation(message.originalTradeInformation)
        \o EncodeTradeSummaryInformation(message.tradeSummaryInformation)

DecodeTradeCancelMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader2(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET label == DecodeLabel2(messageHeader.rest) IN IF ~label.ok THEN Fail ELSE
    LET originalDisseminationDate == DecodeOriginalDisseminationDate2(label.rest) IN IF ~originalDisseminationDate.ok THEN Fail ELSE
    LET originalTradeIdentifier == ReadBytes(originalDisseminationDate.rest, 7) IN IF ~originalTradeIdentifier.ok THEN Fail ELSE
    LET reportFunction == ReadBytes(originalTradeIdentifier.rest, 1) IN IF ~reportFunction.ok THEN Fail ELSE
    LET originalTradeInformation == DecodeOriginalTradeInformation(reportFunction.rest) IN IF ~originalTradeInformation.ok THEN Fail ELSE
    LET tradeSummaryInformation == DecodeTradeSummaryInformation(originalTradeInformation.rest) IN IF ~tradeSummaryInformation.ok THEN Fail ELSE
    Ok([ messageHeader             |-> messageHeader.value,
         label                     |-> label.value,
         originalDisseminationDate |-> originalDisseminationDate.value,
         originalTradeIdentifier   |-> originalTradeIdentifier.value,
         reportFunction            |-> reportFunction.value,
         originalTradeInformation  |-> originalTradeInformation.value,
         tradeSummaryInformation   |-> tradeSummaryInformation.value ], tradeSummaryInformation.rest)

ZeroTradeCancelMessage ==
    [ messageHeader             |-> ZeroMessageHeader2,
      label                     |-> ZeroLabel2,
      originalDisseminationDate |-> ZeroOriginalDisseminationDate2,
      originalTradeIdentifier   |-> [i \in 1 .. 7 |-> 0],
      reportFunction            |-> [i \in 1 .. 1 |-> 0],
      originalTradeInformation  |-> ZeroOriginalTradeInformation,
      tradeSummaryInformation   |-> ZeroTradeSummaryInformation ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader2 }
        \cup { [ZeroTradeCancelMessage EXCEPT !.label = one] : one \in CheckedLabel2 }
        \cup { [ZeroTradeCancelMessage EXCEPT !.originalDisseminationDate = one] : one \in CheckedOriginalDisseminationDate2 }
        \cup { [ZeroTradeCancelMessage EXCEPT !.originalTradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.reportFunction = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.originalTradeInformation = one] : one \in CheckedOriginalTradeInformation }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeSummaryInformation = one] : one \in CheckedTradeSummaryInformation }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime3 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime3(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime3 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime3 ==
    { ZeroDatetime3 }
        \cup { [ZeroDatetime3 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime3 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime3 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader3 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime3 ]

EncodeMessageHeader3(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime3(message.datetime)

DecodeMessageHeader3(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime3(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader3 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime3 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader3 ==
    { ZeroMessageHeader3 }
        \cup { [ZeroMessageHeader3 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader3 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader3 EXCEPT !.datetime = one] : one \in CheckedDatetime3 }

(***************************************************************************)
(* Label: 40 bytes                                                         *)
(***************************************************************************)

Label3 ==
    [ symbol         : Sample(14),
      cusip          : Sample(9),
      bsym           : Sample(12),
      subProductType : Sample(5) ]

EncodeLabel3(message) ==
    message.symbol
        \o message.cusip
        \o message.bsym
        \o message.subProductType

DecodeLabel3(bytes) ==
    LET symbol == ReadBytes(bytes, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 9) IN IF ~cusip.ok THEN Fail ELSE
    LET bsym == ReadBytes(cusip.rest, 12) IN IF ~bsym.ok THEN Fail ELSE
    LET subProductType == ReadBytes(bsym.rest, 5) IN IF ~subProductType.ok THEN Fail ELSE
    Ok([ symbol         |-> symbol.value,
         cusip          |-> cusip.value,
         bsym           |-> bsym.value,
         subProductType |-> subProductType.value ], subProductType.rest)

ZeroLabel3 ==
    [ symbol         |-> [i \in 1 .. 14 |-> 0],
      cusip          |-> [i \in 1 .. 9 |-> 0],
      bsym           |-> [i \in 1 .. 12 |-> 0],
      subProductType |-> [i \in 1 .. 5 |-> 0] ]

(* Label at zero, then each field in turn at the values it is checked at *)
CheckedLabel3 ==
    { ZeroLabel3 }
        \cup { [ZeroLabel3 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroLabel3 EXCEPT !.cusip = one] : one \in Sample(9) }
        \cup { [ZeroLabel3 EXCEPT !.bsym = one] : one \in Sample(12) }
        \cup { [ZeroLabel3 EXCEPT !.subProductType = one] : one \in Sample(5) }

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
(* Execution Datetime: 14 bytes                                            *)
(***************************************************************************)

ExecutionDatetime3 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeExecutionDatetime3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeExecutionDatetime3(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroExecutionDatetime3 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Datetime at zero, then each field in turn at the values it is checked at *)
CheckedExecutionDatetime3 ==
    { ZeroExecutionDatetime3 }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime3 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Settlement Date: 8 bytes                                                *)
(***************************************************************************)

SettlementDate3 ==
    [ year  : Sample(4),
      month : Sample(2),
      day   : Sample(2) ]

EncodeSettlementDate3(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSettlementDate3(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSettlementDate3 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 2 |-> 0],
      day   |-> [i \in 1 .. 2 |-> 0] ]

(* Settlement Date at zero, then each field in turn at the values it is checked at *)
CheckedSettlementDate3 ==
    { ZeroSettlementDate3 }
        \cup { [ZeroSettlementDate3 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSettlementDate3 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroSettlementDate3 EXCEPT !.day = one] : one \in Sample(2) }

(***************************************************************************)
(* Original Trade Information: 71 bytes                                    *)
(***************************************************************************)

OriginalTradeInformation2 ==
    [ quantityIndicator     : Sample(1),
      quantity              : Sample(14),
      price                 : Sample(11),
      remuneration          : Sample(1),
      specialPriceIndicator : Sample(1),
      side                  : Sample(1),
      asOfIndicator         : Sample(1),
      executionDatetime     : ExecutionDatetime3,
      futureUse             : Sample(2),
      saleCondition3        : Sample(1),
      saleCondition4        : Sample(1),
      settlementDate        : SettlementDate3,
      factor                : Sample(12),
      reportingPartyType    : Sample(1),
      contraPartyType       : Sample(1),
      atsIndicator          : Sample(1) ]

EncodeOriginalTradeInformation2(message) ==
    message.quantityIndicator
        \o message.quantity
        \o message.price
        \o message.remuneration
        \o message.specialPriceIndicator
        \o message.side
        \o message.asOfIndicator
        \o EncodeExecutionDatetime3(message.executionDatetime)
        \o message.futureUse
        \o message.saleCondition3
        \o message.saleCondition4
        \o EncodeSettlementDate3(message.settlementDate)
        \o message.factor
        \o message.reportingPartyType
        \o message.contraPartyType
        \o message.atsIndicator

DecodeOriginalTradeInformation2(bytes) ==
    LET quantityIndicator == ReadBytes(bytes, 1) IN IF ~quantityIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantityIndicator.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET remuneration == ReadBytes(price.rest, 1) IN IF ~remuneration.ok THEN Fail ELSE
    LET specialPriceIndicator == ReadBytes(remuneration.rest, 1) IN IF ~specialPriceIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(specialPriceIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET asOfIndicator == ReadBytes(side.rest, 1) IN IF ~asOfIndicator.ok THEN Fail ELSE
    LET executionDatetime == DecodeExecutionDatetime3(asOfIndicator.rest) IN IF ~executionDatetime.ok THEN Fail ELSE
    LET futureUse == ReadBytes(executionDatetime.rest, 2) IN IF ~futureUse.ok THEN Fail ELSE
    LET saleCondition3 == ReadBytes(futureUse.rest, 1) IN IF ~saleCondition3.ok THEN Fail ELSE
    LET saleCondition4 == ReadBytes(saleCondition3.rest, 1) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET settlementDate == DecodeSettlementDate3(saleCondition4.rest) IN IF ~settlementDate.ok THEN Fail ELSE
    LET factor == ReadBytes(settlementDate.rest, 12) IN IF ~factor.ok THEN Fail ELSE
    LET reportingPartyType == ReadBytes(factor.rest, 1) IN IF ~reportingPartyType.ok THEN Fail ELSE
    LET contraPartyType == ReadBytes(reportingPartyType.rest, 1) IN IF ~contraPartyType.ok THEN Fail ELSE
    LET atsIndicator == ReadBytes(contraPartyType.rest, 1) IN IF ~atsIndicator.ok THEN Fail ELSE
    Ok([ quantityIndicator     |-> quantityIndicator.value,
         quantity              |-> quantity.value,
         price                 |-> price.value,
         remuneration          |-> remuneration.value,
         specialPriceIndicator |-> specialPriceIndicator.value,
         side                  |-> side.value,
         asOfIndicator         |-> asOfIndicator.value,
         executionDatetime     |-> executionDatetime.value,
         futureUse             |-> futureUse.value,
         saleCondition3        |-> saleCondition3.value,
         saleCondition4        |-> saleCondition4.value,
         settlementDate        |-> settlementDate.value,
         factor                |-> factor.value,
         reportingPartyType    |-> reportingPartyType.value,
         contraPartyType       |-> contraPartyType.value,
         atsIndicator          |-> atsIndicator.value ], atsIndicator.rest)

ZeroOriginalTradeInformation2 ==
    [ quantityIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 14 |-> 0],
      price                 |-> [i \in 1 .. 11 |-> 0],
      remuneration          |-> [i \in 1 .. 1 |-> 0],
      specialPriceIndicator |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      asOfIndicator         |-> [i \in 1 .. 1 |-> 0],
      executionDatetime     |-> ZeroExecutionDatetime3,
      futureUse             |-> [i \in 1 .. 2 |-> 0],
      saleCondition3        |-> [i \in 1 .. 1 |-> 0],
      saleCondition4        |-> [i \in 1 .. 1 |-> 0],
      settlementDate        |-> ZeroSettlementDate3,
      factor                |-> [i \in 1 .. 12 |-> 0],
      reportingPartyType    |-> [i \in 1 .. 1 |-> 0],
      contraPartyType       |-> [i \in 1 .. 1 |-> 0],
      atsIndicator          |-> [i \in 1 .. 1 |-> 0] ]

(* Original Trade Information at zero, then each field in turn at the values it is checked at *)
CheckedOriginalTradeInformation2 ==
    { ZeroOriginalTradeInformation2 }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.quantityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.remuneration = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.specialPriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.asOfIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.executionDatetime = one] : one \in CheckedExecutionDatetime3 }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.futureUse = one] : one \in Sample(2) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.saleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.saleCondition4 = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.settlementDate = one] : one \in CheckedSettlementDate3 }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.factor = one] : one \in Sample(12) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.reportingPartyType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.contraPartyType = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTradeInformation2 EXCEPT !.atsIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Datetime: 14 bytes                                            *)
(***************************************************************************)

ExecutionDatetime4 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeExecutionDatetime4(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeExecutionDatetime4(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroExecutionDatetime4 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Datetime at zero, then each field in turn at the values it is checked at *)
CheckedExecutionDatetime4 ==
    { ZeroExecutionDatetime4 }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroExecutionDatetime4 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Settlement Date: 8 bytes                                                *)
(***************************************************************************)

SettlementDate4 ==
    [ year  : Sample(4),
      month : Sample(2),
      day   : Sample(2) ]

EncodeSettlementDate4(message) ==
    message.year
        \o message.month
        \o message.day

DecodeSettlementDate4(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value ], day.rest)

ZeroSettlementDate4 ==
    [ year  |-> [i \in 1 .. 4 |-> 0],
      month |-> [i \in 1 .. 2 |-> 0],
      day   |-> [i \in 1 .. 2 |-> 0] ]

(* Settlement Date at zero, then each field in turn at the values it is checked at *)
CheckedSettlementDate4 ==
    { ZeroSettlementDate4 }
        \cup { [ZeroSettlementDate4 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroSettlementDate4 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroSettlementDate4 EXCEPT !.day = one] : one \in Sample(2) }

(***************************************************************************)
(* Correction Trade Information: 71 bytes                                  *)
(***************************************************************************)

CorrectionTradeInformation ==
    [ quantityIndicator     : Sample(1),
      quantity              : Sample(14),
      price                 : Sample(11),
      remuneration          : Sample(1),
      specialPriceIndicator : Sample(1),
      side                  : Sample(1),
      asOfIndicator         : Sample(1),
      executionDatetime     : ExecutionDatetime4,
      futureUse             : Sample(2),
      saleCondition3        : Sample(1),
      saleCondition4        : Sample(1),
      settlementDate        : SettlementDate4,
      factor                : Sample(12),
      reportingPartyType    : Sample(1),
      contraPartyType       : Sample(1),
      atsIndicator          : Sample(1) ]

EncodeCorrectionTradeInformation(message) ==
    message.quantityIndicator
        \o message.quantity
        \o message.price
        \o message.remuneration
        \o message.specialPriceIndicator
        \o message.side
        \o message.asOfIndicator
        \o EncodeExecutionDatetime4(message.executionDatetime)
        \o message.futureUse
        \o message.saleCondition3
        \o message.saleCondition4
        \o EncodeSettlementDate4(message.settlementDate)
        \o message.factor
        \o message.reportingPartyType
        \o message.contraPartyType
        \o message.atsIndicator

DecodeCorrectionTradeInformation(bytes) ==
    LET quantityIndicator == ReadBytes(bytes, 1) IN IF ~quantityIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(quantityIndicator.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET remuneration == ReadBytes(price.rest, 1) IN IF ~remuneration.ok THEN Fail ELSE
    LET specialPriceIndicator == ReadBytes(remuneration.rest, 1) IN IF ~specialPriceIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(specialPriceIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET asOfIndicator == ReadBytes(side.rest, 1) IN IF ~asOfIndicator.ok THEN Fail ELSE
    LET executionDatetime == DecodeExecutionDatetime4(asOfIndicator.rest) IN IF ~executionDatetime.ok THEN Fail ELSE
    LET futureUse == ReadBytes(executionDatetime.rest, 2) IN IF ~futureUse.ok THEN Fail ELSE
    LET saleCondition3 == ReadBytes(futureUse.rest, 1) IN IF ~saleCondition3.ok THEN Fail ELSE
    LET saleCondition4 == ReadBytes(saleCondition3.rest, 1) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET settlementDate == DecodeSettlementDate4(saleCondition4.rest) IN IF ~settlementDate.ok THEN Fail ELSE
    LET factor == ReadBytes(settlementDate.rest, 12) IN IF ~factor.ok THEN Fail ELSE
    LET reportingPartyType == ReadBytes(factor.rest, 1) IN IF ~reportingPartyType.ok THEN Fail ELSE
    LET contraPartyType == ReadBytes(reportingPartyType.rest, 1) IN IF ~contraPartyType.ok THEN Fail ELSE
    LET atsIndicator == ReadBytes(contraPartyType.rest, 1) IN IF ~atsIndicator.ok THEN Fail ELSE
    Ok([ quantityIndicator     |-> quantityIndicator.value,
         quantity              |-> quantity.value,
         price                 |-> price.value,
         remuneration          |-> remuneration.value,
         specialPriceIndicator |-> specialPriceIndicator.value,
         side                  |-> side.value,
         asOfIndicator         |-> asOfIndicator.value,
         executionDatetime     |-> executionDatetime.value,
         futureUse             |-> futureUse.value,
         saleCondition3        |-> saleCondition3.value,
         saleCondition4        |-> saleCondition4.value,
         settlementDate        |-> settlementDate.value,
         factor                |-> factor.value,
         reportingPartyType    |-> reportingPartyType.value,
         contraPartyType       |-> contraPartyType.value,
         atsIndicator          |-> atsIndicator.value ], atsIndicator.rest)

ZeroCorrectionTradeInformation ==
    [ quantityIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 14 |-> 0],
      price                 |-> [i \in 1 .. 11 |-> 0],
      remuneration          |-> [i \in 1 .. 1 |-> 0],
      specialPriceIndicator |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      asOfIndicator         |-> [i \in 1 .. 1 |-> 0],
      executionDatetime     |-> ZeroExecutionDatetime4,
      futureUse             |-> [i \in 1 .. 2 |-> 0],
      saleCondition3        |-> [i \in 1 .. 1 |-> 0],
      saleCondition4        |-> [i \in 1 .. 1 |-> 0],
      settlementDate        |-> ZeroSettlementDate4,
      factor                |-> [i \in 1 .. 12 |-> 0],
      reportingPartyType    |-> [i \in 1 .. 1 |-> 0],
      contraPartyType       |-> [i \in 1 .. 1 |-> 0],
      atsIndicator          |-> [i \in 1 .. 1 |-> 0] ]

(* Correction Trade Information at zero, then each field in turn at the values it is checked at *)
CheckedCorrectionTradeInformation ==
    { ZeroCorrectionTradeInformation }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.quantityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.remuneration = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.specialPriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.asOfIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.executionDatetime = one] : one \in CheckedExecutionDatetime4 }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.futureUse = one] : one \in Sample(2) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.saleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.saleCondition4 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.settlementDate = one] : one \in CheckedSettlementDate4 }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.factor = one] : one \in Sample(12) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.reportingPartyType = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.contraPartyType = one] : one \in Sample(1) }
        \cup { [ZeroCorrectionTradeInformation EXCEPT !.atsIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Summary Information: 34 bytes                                     *)
(***************************************************************************)

TradeSummaryInformation2 ==
    [ highPrice       : Sample(11),
      lowPrice        : Sample(11),
      lastSalePrice   : Sample(11),
      changeIndicator : Sample(1) ]

EncodeTradeSummaryInformation2(message) ==
    message.highPrice
        \o message.lowPrice
        \o message.lastSalePrice
        \o message.changeIndicator

DecodeTradeSummaryInformation2(bytes) ==
    LET highPrice == ReadBytes(bytes, 11) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 11) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastSalePrice == ReadBytes(lowPrice.rest, 11) IN IF ~lastSalePrice.ok THEN Fail ELSE
    LET changeIndicator == ReadBytes(lastSalePrice.rest, 1) IN IF ~changeIndicator.ok THEN Fail ELSE
    Ok([ highPrice       |-> highPrice.value,
         lowPrice        |-> lowPrice.value,
         lastSalePrice   |-> lastSalePrice.value,
         changeIndicator |-> changeIndicator.value ], changeIndicator.rest)

ZeroTradeSummaryInformation2 ==
    [ highPrice       |-> [i \in 1 .. 11 |-> 0],
      lowPrice        |-> [i \in 1 .. 11 |-> 0],
      lastSalePrice   |-> [i \in 1 .. 11 |-> 0],
      changeIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Summary Information at zero, then each field in turn at the values it is checked at *)
CheckedTradeSummaryInformation2 ==
    { ZeroTradeSummaryInformation2 }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.highPrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.lowPrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.lastSalePrice = one] : one \in Sample(11) }
        \cup { [ZeroTradeSummaryInformation2 EXCEPT !.changeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correction Message: 254 bytes                                     *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ messageHeader              : MessageHeader3,
      label                      : Label3,
      originalDisseminationDate  : OriginalDisseminationDate3,
      originalTradeIdentifier    : Sample(7),
      reportFunction             : Sample(1),
      originalTradeInformation   : OriginalTradeInformation2,
      correctionTradeInformation : CorrectionTradeInformation,
      tradeSummaryInformation    : TradeSummaryInformation2 ]

EncodeTradeCorrectionMessage(message) ==
    EncodeMessageHeader3(message.messageHeader)
        \o EncodeLabel3(message.label)
        \o EncodeOriginalDisseminationDate3(message.originalDisseminationDate)
        \o message.originalTradeIdentifier
        \o message.reportFunction
        \o EncodeOriginalTradeInformation2(message.originalTradeInformation)
        \o EncodeCorrectionTradeInformation(message.correctionTradeInformation)
        \o EncodeTradeSummaryInformation2(message.tradeSummaryInformation)

DecodeTradeCorrectionMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader3(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET label == DecodeLabel3(messageHeader.rest) IN IF ~label.ok THEN Fail ELSE
    LET originalDisseminationDate == DecodeOriginalDisseminationDate3(label.rest) IN IF ~originalDisseminationDate.ok THEN Fail ELSE
    LET originalTradeIdentifier == ReadBytes(originalDisseminationDate.rest, 7) IN IF ~originalTradeIdentifier.ok THEN Fail ELSE
    LET reportFunction == ReadBytes(originalTradeIdentifier.rest, 1) IN IF ~reportFunction.ok THEN Fail ELSE
    LET originalTradeInformation == DecodeOriginalTradeInformation2(reportFunction.rest) IN IF ~originalTradeInformation.ok THEN Fail ELSE
    LET correctionTradeInformation == DecodeCorrectionTradeInformation(originalTradeInformation.rest) IN IF ~correctionTradeInformation.ok THEN Fail ELSE
    LET tradeSummaryInformation == DecodeTradeSummaryInformation2(correctionTradeInformation.rest) IN IF ~tradeSummaryInformation.ok THEN Fail ELSE
    Ok([ messageHeader              |-> messageHeader.value,
         label                      |-> label.value,
         originalDisseminationDate  |-> originalDisseminationDate.value,
         originalTradeIdentifier    |-> originalTradeIdentifier.value,
         reportFunction             |-> reportFunction.value,
         originalTradeInformation   |-> originalTradeInformation.value,
         correctionTradeInformation |-> correctionTradeInformation.value,
         tradeSummaryInformation    |-> tradeSummaryInformation.value ], tradeSummaryInformation.rest)

ZeroTradeCorrectionMessage ==
    [ messageHeader              |-> ZeroMessageHeader3,
      label                      |-> ZeroLabel3,
      originalDisseminationDate  |-> ZeroOriginalDisseminationDate3,
      originalTradeIdentifier    |-> [i \in 1 .. 7 |-> 0],
      reportFunction             |-> [i \in 1 .. 1 |-> 0],
      originalTradeInformation   |-> ZeroOriginalTradeInformation2,
      correctionTradeInformation |-> ZeroCorrectionTradeInformation,
      tradeSummaryInformation    |-> ZeroTradeSummaryInformation2 ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader3 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.label = one] : one \in CheckedLabel3 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalDisseminationDate = one] : one \in CheckedOriginalDisseminationDate3 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.reportFunction = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeInformation = one] : one \in CheckedOriginalTradeInformation2 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctionTradeInformation = one] : one \in CheckedCorrectionTradeInformation }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeSummaryInformation = one] : one \in CheckedTradeSummaryInformation2 }

(***************************************************************************)
(* Trade Message Payload, selected by Trade Message Type                   *)
(***************************************************************************)

TradeReportMessageCode == 77  \* "M"
TradeCancelMessageCode == 78  \* "N"
TradeCorrectionMessageCode == 79  \* "O"

TradeMessagePayload ==
    [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]

EncodeTradeMessagePayload(message) ==
    CASE message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)

DecodeTradeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTradeMessagePayload == [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]

(* Each Trade Message Payload in turn, at the values the message it names is checked at *)
CheckedTradeMessagePayload ==
    { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }
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
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime4 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime4(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime4(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime4 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime4 ==
    { ZeroDatetime4 }
        \cup { [ZeroDatetime4 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime4 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime4 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader4 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime4 ]

EncodeMessageHeader4(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime4(message.datetime)

DecodeMessageHeader4(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime4(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader4 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime4 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader4 ==
    { ZeroMessageHeader4 }
        \cup { [ZeroMessageHeader4 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader4 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader4 EXCEPT !.datetime = one] : one \in CheckedDatetime4 }

(***************************************************************************)
(* Label: 40 bytes                                                         *)
(***************************************************************************)

Label4 ==
    [ symbol         : Sample(14),
      cusip          : Sample(9),
      bsym           : Sample(12),
      subProductType : Sample(5) ]

EncodeLabel4(message) ==
    message.symbol
        \o message.cusip
        \o message.bsym
        \o message.subProductType

DecodeLabel4(bytes) ==
    LET symbol == ReadBytes(bytes, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 9) IN IF ~cusip.ok THEN Fail ELSE
    LET bsym == ReadBytes(cusip.rest, 12) IN IF ~bsym.ok THEN Fail ELSE
    LET subProductType == ReadBytes(bsym.rest, 5) IN IF ~subProductType.ok THEN Fail ELSE
    Ok([ symbol         |-> symbol.value,
         cusip          |-> cusip.value,
         bsym           |-> bsym.value,
         subProductType |-> subProductType.value ], subProductType.rest)

ZeroLabel4 ==
    [ symbol         |-> [i \in 1 .. 14 |-> 0],
      cusip          |-> [i \in 1 .. 9 |-> 0],
      bsym           |-> [i \in 1 .. 12 |-> 0],
      subProductType |-> [i \in 1 .. 5 |-> 0] ]

(* Label at zero, then each field in turn at the values it is checked at *)
CheckedLabel4 ==
    { ZeroLabel4 }
        \cup { [ZeroLabel4 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroLabel4 EXCEPT !.cusip = one] : one \in Sample(9) }
        \cup { [ZeroLabel4 EXCEPT !.bsym = one] : one \in Sample(12) }
        \cup { [ZeroLabel4 EXCEPT !.subProductType = one] : one \in Sample(5) }

(***************************************************************************)
(* Daily Trade Summary Message: 95 bytes                                   *)
(***************************************************************************)

DailyTradeSummaryMessage ==
    [ messageHeader   : MessageHeader4,
      label           : Label4,
      dailyHighPrice  : Sample(11),
      dailyLowPrice   : Sample(11),
      dailyClosePrice : Sample(11) ]

EncodeDailyTradeSummaryMessage(message) ==
    EncodeMessageHeader4(message.messageHeader)
        \o EncodeLabel4(message.label)
        \o message.dailyHighPrice
        \o message.dailyLowPrice
        \o message.dailyClosePrice

DecodeDailyTradeSummaryMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader4(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET label == DecodeLabel4(messageHeader.rest) IN IF ~label.ok THEN Fail ELSE
    LET dailyHighPrice == ReadBytes(label.rest, 11) IN IF ~dailyHighPrice.ok THEN Fail ELSE
    LET dailyLowPrice == ReadBytes(dailyHighPrice.rest, 11) IN IF ~dailyLowPrice.ok THEN Fail ELSE
    LET dailyClosePrice == ReadBytes(dailyLowPrice.rest, 11) IN IF ~dailyClosePrice.ok THEN Fail ELSE
    Ok([ messageHeader   |-> messageHeader.value,
         label           |-> label.value,
         dailyHighPrice  |-> dailyHighPrice.value,
         dailyLowPrice   |-> dailyLowPrice.value,
         dailyClosePrice |-> dailyClosePrice.value ], dailyClosePrice.rest)

ZeroDailyTradeSummaryMessage ==
    [ messageHeader   |-> ZeroMessageHeader4,
      label           |-> ZeroLabel4,
      dailyHighPrice  |-> [i \in 1 .. 11 |-> 0],
      dailyLowPrice   |-> [i \in 1 .. 11 |-> 0],
      dailyClosePrice |-> [i \in 1 .. 11 |-> 0] ]

(* Daily Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedDailyTradeSummaryMessage ==
    { ZeroDailyTradeSummaryMessage }
        \cup { [ZeroDailyTradeSummaryMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader4 }
        \cup { [ZeroDailyTradeSummaryMessage EXCEPT !.label = one] : one \in CheckedLabel4 }
        \cup { [ZeroDailyTradeSummaryMessage EXCEPT !.dailyHighPrice = one] : one \in Sample(11) }
        \cup { [ZeroDailyTradeSummaryMessage EXCEPT !.dailyLowPrice = one] : one \in Sample(11) }
        \cup { [ZeroDailyTradeSummaryMessage EXCEPT !.dailyClosePrice = one] : one \in Sample(11) }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime5 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime5(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime5(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime5 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime5 ==
    { ZeroDatetime5 }
        \cup { [ZeroDatetime5 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime5 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime5 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader5 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime5 ]

EncodeMessageHeader5(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime5(message.datetime)

DecodeMessageHeader5(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime5(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader5 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime5 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader5 ==
    { ZeroMessageHeader5 }
        \cup { [ZeroMessageHeader5 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader5 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader5 EXCEPT !.datetime = one] : one \in CheckedDatetime5 }

(***************************************************************************)
(* Label: 40 bytes                                                         *)
(***************************************************************************)

Label5 ==
    [ symbol         : Sample(14),
      cusip          : Sample(9),
      bsym           : Sample(12),
      subProductType : Sample(5) ]

EncodeLabel5(message) ==
    message.symbol
        \o message.cusip
        \o message.bsym
        \o message.subProductType

DecodeLabel5(bytes) ==
    LET symbol == ReadBytes(bytes, 14) IN IF ~symbol.ok THEN Fail ELSE
    LET cusip == ReadBytes(symbol.rest, 9) IN IF ~cusip.ok THEN Fail ELSE
    LET bsym == ReadBytes(cusip.rest, 12) IN IF ~bsym.ok THEN Fail ELSE
    LET subProductType == ReadBytes(bsym.rest, 5) IN IF ~subProductType.ok THEN Fail ELSE
    Ok([ symbol         |-> symbol.value,
         cusip          |-> cusip.value,
         bsym           |-> bsym.value,
         subProductType |-> subProductType.value ], subProductType.rest)

ZeroLabel5 ==
    [ symbol         |-> [i \in 1 .. 14 |-> 0],
      cusip          |-> [i \in 1 .. 9 |-> 0],
      bsym           |-> [i \in 1 .. 12 |-> 0],
      subProductType |-> [i \in 1 .. 5 |-> 0] ]

(* Label at zero, then each field in turn at the values it is checked at *)
CheckedLabel5 ==
    { ZeroLabel5 }
        \cup { [ZeroLabel5 EXCEPT !.symbol = one] : one \in Sample(14) }
        \cup { [ZeroLabel5 EXCEPT !.cusip = one] : one \in Sample(9) }
        \cup { [ZeroLabel5 EXCEPT !.bsym = one] : one \in Sample(12) }
        \cup { [ZeroLabel5 EXCEPT !.subProductType = one] : one \in Sample(5) }

(***************************************************************************)
(* Action Datetime: 14 bytes                                               *)
(***************************************************************************)

ActionDatetime ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeActionDatetime(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeActionDatetime(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroActionDatetime ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Action Datetime at zero, then each field in turn at the values it is checked at *)
CheckedActionDatetime ==
    { ZeroActionDatetime }
        \cup { [ZeroActionDatetime EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroActionDatetime EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroActionDatetime EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Trading Halt Message: 111 bytes                                         *)
(***************************************************************************)

TradingHaltMessage ==
    [ messageHeader  : MessageHeader5,
      label          : Label5,
      issuer         : Sample(30),
      action         : Sample(1),
      actionDatetime : ActionDatetime,
      haltReason     : Sample(4) ]

EncodeTradingHaltMessage(message) ==
    EncodeMessageHeader5(message.messageHeader)
        \o EncodeLabel5(message.label)
        \o message.issuer
        \o message.action
        \o EncodeActionDatetime(message.actionDatetime)
        \o message.haltReason

DecodeTradingHaltMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader5(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET label == DecodeLabel5(messageHeader.rest) IN IF ~label.ok THEN Fail ELSE
    LET issuer == ReadBytes(label.rest, 30) IN IF ~issuer.ok THEN Fail ELSE
    LET action == ReadBytes(issuer.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET actionDatetime == DecodeActionDatetime(action.rest) IN IF ~actionDatetime.ok THEN Fail ELSE
    LET haltReason == ReadBytes(actionDatetime.rest, 4) IN IF ~haltReason.ok THEN Fail ELSE
    Ok([ messageHeader  |-> messageHeader.value,
         label          |-> label.value,
         issuer         |-> issuer.value,
         action         |-> action.value,
         actionDatetime |-> actionDatetime.value,
         haltReason     |-> haltReason.value ], haltReason.rest)

ZeroTradingHaltMessage ==
    [ messageHeader  |-> ZeroMessageHeader5,
      label          |-> ZeroLabel5,
      issuer         |-> [i \in 1 .. 30 |-> 0],
      action         |-> [i \in 1 .. 1 |-> 0],
      actionDatetime |-> ZeroActionDatetime,
      haltReason     |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Halt Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingHaltMessage ==
    { ZeroTradingHaltMessage }
        \cup { [ZeroTradingHaltMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader5 }
        \cup { [ZeroTradingHaltMessage EXCEPT !.label = one] : one \in CheckedLabel5 }
        \cup { [ZeroTradingHaltMessage EXCEPT !.issuer = one] : one \in Sample(30) }
        \cup { [ZeroTradingHaltMessage EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroTradingHaltMessage EXCEPT !.actionDatetime = one] : one \in CheckedActionDatetime }
        \cup { [ZeroTradingHaltMessage EXCEPT !.haltReason = one] : one \in Sample(4) }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime6 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime6(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime6(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime6 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime6 ==
    { ZeroDatetime6 }
        \cup { [ZeroDatetime6 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime6 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime6 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader6 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime6 ]

EncodeMessageHeader6(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime6(message.datetime)

DecodeMessageHeader6(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime6(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader6 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime6 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader6 ==
    { ZeroMessageHeader6 }
        \cup { [ZeroMessageHeader6 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader6 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader6 EXCEPT !.datetime = one] : one \in CheckedDatetime6 }

(***************************************************************************)
(* General Administrative Message                                          *)
(***************************************************************************)

GeneralAdministrativeMessage ==
    [ messageHeader : MessageHeader6,
      text          : SampleBytes ]

EncodeGeneralAdministrativeMessage(message) ==
    EncodeMessageHeader6(message.messageHeader)
        \o message.text

DecodeGeneralAdministrativeMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader6(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    LET text == Ok(messageHeader.rest, << >>) IN IF ~text.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value,
         text          |-> text.value ], text.rest)

ZeroGeneralAdministrativeMessage ==
    [ messageHeader |-> ZeroMessageHeader6,
      text          |-> << >> ]

(* General Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedGeneralAdministrativeMessage ==
    { ZeroGeneralAdministrativeMessage }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader6 }
        \cup { [ZeroGeneralAdministrativeMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

DailyTradeSummaryMessageCode == 69  \* "E"
TradingHaltMessageCode == 72  \* "H"
GeneralAdministrativeMessageCode == 65  \* "A"

AdministrativeMessagePayload ==
    [ tag : {DailyTradeSummaryMessageCode}, body : DailyTradeSummaryMessage ]
        \cup [ tag : {TradingHaltMessageCode}, body : TradingHaltMessage ]
        \cup [ tag : {GeneralAdministrativeMessageCode}, body : GeneralAdministrativeMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = DailyTradeSummaryMessageCode -> EncodeDailyTradeSummaryMessage(message.body)
      [] message.tag = TradingHaltMessageCode -> EncodeTradingHaltMessage(message.body)
      [] message.tag = GeneralAdministrativeMessageCode -> EncodeGeneralAdministrativeMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = DailyTradeSummaryMessageCode -> DecodeDailyTradeSummaryMessage(bytes)
              [] tag = TradingHaltMessageCode -> DecodeTradingHaltMessage(bytes)
              [] tag = GeneralAdministrativeMessageCode -> DecodeGeneralAdministrativeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> DailyTradeSummaryMessageCode, body |-> ZeroDailyTradeSummaryMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> DailyTradeSummaryMessageCode, body |-> one] : one \in CheckedDailyTradeSummaryMessage }
        \cup { [tag |-> TradingHaltMessageCode, body |-> one] : one \in CheckedTradingHaltMessage }
        \cup { [tag |-> GeneralAdministrativeMessageCode, body |-> one] : one \in CheckedGeneralAdministrativeMessage }

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
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime7 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime7(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime7(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime7 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime7 ==
    { ZeroDatetime7 }
        \cup { [ZeroDatetime7 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime7 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime7 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader7 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime7 ]

EncodeMessageHeader7(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime7(message.datetime)

DecodeMessageHeader7(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime7(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader7 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime7 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader7 ==
    { ZeroMessageHeader7 }
        \cup { [ZeroMessageHeader7 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader7 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader7 EXCEPT !.datetime = one] : one \in CheckedDatetime7 }

(***************************************************************************)
(* Start Of Day Message: 22 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ messageHeader : MessageHeader7 ]

EncodeStartOfDayMessage(message) ==
    EncodeMessageHeader7(message.messageHeader)

DecodeStartOfDayMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader7(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroStartOfDayMessage ==
    [ messageHeader |-> ZeroMessageHeader7 ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader7 }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime8 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime8(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime8(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime8 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime8 ==
    { ZeroDatetime8 }
        \cup { [ZeroDatetime8 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime8 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime8 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader8 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime8 ]

EncodeMessageHeader8(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime8(message.datetime)

DecodeMessageHeader8(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime8(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader8 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime8 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader8 ==
    { ZeroMessageHeader8 }
        \cup { [ZeroMessageHeader8 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader8 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader8 EXCEPT !.datetime = one] : one \in CheckedDatetime8 }

(***************************************************************************)
(* End Of Day Message: 22 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ messageHeader : MessageHeader8 ]

EncodeEndOfDayMessage(message) ==
    EncodeMessageHeader8(message.messageHeader)

DecodeEndOfDayMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader8(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroEndOfDayMessage ==
    [ messageHeader |-> ZeroMessageHeader8 ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader8 }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime9 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime9(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime9(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime9 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime9 ==
    { ZeroDatetime9 }
        \cup { [ZeroDatetime9 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime9 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime9 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader9 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime9 ]

EncodeMessageHeader9(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime9(message.datetime)

DecodeMessageHeader9(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime9(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader9 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime9 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader9 ==
    { ZeroMessageHeader9 }
        \cup { [ZeroMessageHeader9 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader9 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader9 EXCEPT !.datetime = one] : one \in CheckedDatetime9 }

(***************************************************************************)
(* Market Session Open Message: 22 bytes                                   *)
(***************************************************************************)

MarketSessionOpenMessage ==
    [ messageHeader : MessageHeader9 ]

EncodeMarketSessionOpenMessage(message) ==
    EncodeMessageHeader9(message.messageHeader)

DecodeMarketSessionOpenMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader9(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroMarketSessionOpenMessage ==
    [ messageHeader |-> ZeroMessageHeader9 ]

(* Market Session Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionOpenMessage ==
    { ZeroMarketSessionOpenMessage }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader9 }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime10 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime10(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime10(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime10 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime10 ==
    { ZeroDatetime10 }
        \cup { [ZeroDatetime10 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime10 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime10 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader10 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime10 ]

EncodeMessageHeader10(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime10(message.datetime)

DecodeMessageHeader10(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime10(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader10 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime10 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader10 ==
    { ZeroMessageHeader10 }
        \cup { [ZeroMessageHeader10 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader10 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader10 EXCEPT !.datetime = one] : one \in CheckedDatetime10 }

(***************************************************************************)
(* Market Session Close Message: 22 bytes                                  *)
(***************************************************************************)

MarketSessionCloseMessage ==
    [ messageHeader : MessageHeader10 ]

EncodeMarketSessionCloseMessage(message) ==
    EncodeMessageHeader10(message.messageHeader)

DecodeMarketSessionCloseMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader10(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroMarketSessionCloseMessage ==
    [ messageHeader |-> ZeroMessageHeader10 ]

(* Market Session Close Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionCloseMessage ==
    { ZeroMarketSessionCloseMessage }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader10 }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime11 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime11(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime11(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime11 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime11 ==
    { ZeroDatetime11 }
        \cup { [ZeroDatetime11 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime11 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime11 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader11 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime11 ]

EncodeMessageHeader11(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime11(message.datetime)

DecodeMessageHeader11(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime11(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader11 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime11 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader11 ==
    { ZeroMessageHeader11 }
        \cup { [ZeroMessageHeader11 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader11 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader11 EXCEPT !.datetime = one] : one \in CheckedDatetime11 }

(***************************************************************************)
(* End Of Trade Reporting Message: 22 bytes                                *)
(***************************************************************************)

EndOfTradeReportingMessage ==
    [ messageHeader : MessageHeader11 ]

EncodeEndOfTradeReportingMessage(message) ==
    EncodeMessageHeader11(message.messageHeader)

DecodeEndOfTradeReportingMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader11(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroEndOfTradeReportingMessage ==
    [ messageHeader |-> ZeroMessageHeader11 ]

(* End Of Trade Reporting Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTradeReportingMessage ==
    { ZeroEndOfTradeReportingMessage }
        \cup { [ZeroEndOfTradeReportingMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader11 }

(***************************************************************************)
(* Datetime: 14 bytes                                                      *)
(***************************************************************************)

Datetime12 ==
    [ year   : Sample(4),
      month  : Sample(2),
      day    : Sample(2),
      hour   : Sample(2),
      minute : Sample(2),
      second : Sample(2) ]

EncodeDatetime12(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.hour
        \o message.minute
        \o message.second

DecodeDatetime12(bytes) ==
    LET year == ReadBytes(bytes, 4) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET hour == ReadBytes(day.rest, 2) IN IF ~hour.ok THEN Fail ELSE
    LET minute == ReadBytes(hour.rest, 2) IN IF ~minute.ok THEN Fail ELSE
    LET second == ReadBytes(minute.rest, 2) IN IF ~second.ok THEN Fail ELSE
    Ok([ year   |-> year.value,
         month  |-> month.value,
         day    |-> day.value,
         hour   |-> hour.value,
         minute |-> minute.value,
         second |-> second.value ], second.rest)

ZeroDatetime12 ==
    [ year   |-> [i \in 1 .. 4 |-> 0],
      month  |-> [i \in 1 .. 2 |-> 0],
      day    |-> [i \in 1 .. 2 |-> 0],
      hour   |-> [i \in 1 .. 2 |-> 0],
      minute |-> [i \in 1 .. 2 |-> 0],
      second |-> [i \in 1 .. 2 |-> 0] ]

(* Datetime at zero, then each field in turn at the values it is checked at *)
CheckedDatetime12 ==
    { ZeroDatetime12 }
        \cup { [ZeroDatetime12 EXCEPT !.year = one] : one \in Sample(4) }
        \cup { [ZeroDatetime12 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.hour = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.minute = one] : one \in Sample(2) }
        \cup { [ZeroDatetime12 EXCEPT !.second = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Header: 22 bytes                                                *)
(***************************************************************************)

MessageHeader12 ==
    [ tradeIdentifier          : Sample(7),
      marketCenterOriginatorId : Sample(1),
      datetime                 : Datetime12 ]

EncodeMessageHeader12(message) ==
    message.tradeIdentifier
        \o message.marketCenterOriginatorId
        \o EncodeDatetime12(message.datetime)

DecodeMessageHeader12(bytes) ==
    LET tradeIdentifier == ReadBytes(bytes, 7) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET marketCenterOriginatorId == ReadBytes(tradeIdentifier.rest, 1) IN IF ~marketCenterOriginatorId.ok THEN Fail ELSE
    LET datetime == DecodeDatetime12(marketCenterOriginatorId.rest) IN IF ~datetime.ok THEN Fail ELSE
    Ok([ tradeIdentifier          |-> tradeIdentifier.value,
         marketCenterOriginatorId |-> marketCenterOriginatorId.value,
         datetime                 |-> datetime.value ], datetime.rest)

ZeroMessageHeader12 ==
    [ tradeIdentifier          |-> [i \in 1 .. 7 |-> 0],
      marketCenterOriginatorId |-> [i \in 1 .. 1 |-> 0],
      datetime                 |-> ZeroDatetime12 ]

(* Message Header at zero, then each field in turn at the values it is checked at *)
CheckedMessageHeader12 ==
    { ZeroMessageHeader12 }
        \cup { [ZeroMessageHeader12 EXCEPT !.tradeIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroMessageHeader12 EXCEPT !.marketCenterOriginatorId = one] : one \in Sample(1) }
        \cup { [ZeroMessageHeader12 EXCEPT !.datetime = one] : one \in CheckedDatetime12 }

(***************************************************************************)
(* End Of Transmissions Message: 22 bytes                                  *)
(***************************************************************************)

EndOfTransmissionsMessage ==
    [ messageHeader : MessageHeader12 ]

EncodeEndOfTransmissionsMessage(message) ==
    EncodeMessageHeader12(message.messageHeader)

DecodeEndOfTransmissionsMessage(bytes) ==
    LET messageHeader == DecodeMessageHeader12(bytes) IN IF ~messageHeader.ok THEN Fail ELSE
    Ok([ messageHeader |-> messageHeader.value ], messageHeader.rest)

ZeroEndOfTransmissionsMessage ==
    [ messageHeader |-> ZeroMessageHeader12 ]

(* End Of Transmissions Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionsMessage ==
    { ZeroEndOfTransmissionsMessage }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.messageHeader = one] : one \in CheckedMessageHeader12 }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 73  \* "I"
EndOfDayMessageCode == 74  \* "J"
MarketSessionOpenMessageCode == 79  \* "O"
MarketSessionCloseMessageCode == 67  \* "C"
EndOfTradeReportingMessageCode == 88  \* "X"
EndOfTransmissionsMessageCode == 90  \* "Z"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]
        \cup [ tag : {MarketSessionOpenMessageCode}, body : MarketSessionOpenMessage ]
        \cup [ tag : {MarketSessionCloseMessageCode}, body : MarketSessionCloseMessage ]
        \cup [ tag : {EndOfTradeReportingMessageCode}, body : EndOfTradeReportingMessage ]
        \cup [ tag : {EndOfTransmissionsMessageCode}, body : EndOfTransmissionsMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)
      [] message.tag = MarketSessionOpenMessageCode -> EncodeMarketSessionOpenMessage(message.body)
      [] message.tag = MarketSessionCloseMessageCode -> EncodeMarketSessionCloseMessage(message.body)
      [] message.tag = EndOfTradeReportingMessageCode -> EncodeEndOfTradeReportingMessage(message.body)
      [] message.tag = EndOfTransmissionsMessageCode -> EncodeEndOfTransmissionsMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] tag = MarketSessionOpenMessageCode -> DecodeMarketSessionOpenMessage(bytes)
              [] tag = MarketSessionCloseMessageCode -> DecodeMarketSessionCloseMessage(bytes)
              [] tag = EndOfTradeReportingMessageCode -> DecodeEndOfTradeReportingMessage(bytes)
              [] tag = EndOfTransmissionsMessageCode -> DecodeEndOfTransmissionsMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> EndOfDayMessageCode, body |-> one] : one \in CheckedEndOfDayMessage }
        \cup { [tag |-> MarketSessionOpenMessageCode, body |-> one] : one \in CheckedMarketSessionOpenMessage }
        \cup { [tag |-> MarketSessionCloseMessageCode, body |-> one] : one \in CheckedMarketSessionCloseMessage }
        \cup { [tag |-> EndOfTradeReportingMessageCode, body |-> one] : one \in CheckedEndOfTradeReportingMessage }
        \cup { [tag |-> EndOfTransmissionsMessageCode, body |-> one] : one \in CheckedEndOfTransmissionsMessage }

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

(* Every Label decodes back to what was encoded, and leaves nothing over *)
RoundTripLabel ==
    \A message \in CheckedLabel :
        LET read == DecodeLabel(EncodeLabel(message))
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

(* Every Settlement Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementDate ==
    \A message \in CheckedSettlementDate :
        LET read == DecodeSettlementDate(EncodeSettlementDate(message))
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

(* Every Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessage ==
    \A message \in CheckedTradeReportMessage :
        LET read == DecodeTradeReportMessage(EncodeTradeReportMessage(message))
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

(* Every Label decodes back to what was encoded, and leaves nothing over *)
RoundTripLabel2 ==
    \A message \in CheckedLabel2 :
        LET read == DecodeLabel2(EncodeLabel2(message))
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

(* Every Settlement Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementDate2 ==
    \A message \in CheckedSettlementDate2 :
        LET read == DecodeSettlementDate2(EncodeSettlementDate2(message))
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

(* Every Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelMessage ==
    \A message \in CheckedTradeCancelMessage :
        LET read == DecodeTradeCancelMessage(EncodeTradeCancelMessage(message))
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

(* Every Label decodes back to what was encoded, and leaves nothing over *)
RoundTripLabel3 ==
    \A message \in CheckedLabel3 :
        LET read == DecodeLabel3(EncodeLabel3(message))
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

(* Every Settlement Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementDate3 ==
    \A message \in CheckedSettlementDate3 :
        LET read == DecodeSettlementDate3(EncodeSettlementDate3(message))
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

(* Every Settlement Date decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementDate4 ==
    \A message \in CheckedSettlementDate4 :
        LET read == DecodeSettlementDate4(EncodeSettlementDate4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Correction Trade Information decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectionTradeInformation ==
    \A message \in CheckedCorrectionTradeInformation :
        LET read == DecodeCorrectionTradeInformation(EncodeCorrectionTradeInformation(message))
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

(* Every Label decodes back to what was encoded, and leaves nothing over *)
RoundTripLabel4 ==
    \A message \in CheckedLabel4 :
        LET read == DecodeLabel4(EncodeLabel4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Daily Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDailyTradeSummaryMessage ==
    \A message \in CheckedDailyTradeSummaryMessage :
        LET read == DecodeDailyTradeSummaryMessage(EncodeDailyTradeSummaryMessage(message))
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

(* Every Label decodes back to what was encoded, and leaves nothing over *)
RoundTripLabel5 ==
    \A message \in CheckedLabel5 :
        LET read == DecodeLabel5(EncodeLabel5(message))
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

(* Every Trading Halt Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingHaltMessage ==
    \A message \in CheckedTradingHaltMessage :
        LET read == DecodeTradingHaltMessage(EncodeTradingHaltMessage(message))
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

(* Every General Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGeneralAdministrativeMessage ==
    \A message \in CheckedGeneralAdministrativeMessage :
        LET read == DecodeGeneralAdministrativeMessage(EncodeGeneralAdministrativeMessage(message))
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

(* Every Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfDayMessage ==
    \A message \in CheckedStartOfDayMessage :
        LET read == DecodeStartOfDayMessage(EncodeStartOfDayMessage(message))
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

(* Every End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayMessage ==
    \A message \in CheckedEndOfDayMessage :
        LET read == DecodeEndOfDayMessage(EncodeEndOfDayMessage(message))
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

(* Every Market Session Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionOpenMessage ==
    \A message \in CheckedMarketSessionOpenMessage :
        LET read == DecodeMarketSessionOpenMessage(EncodeMarketSessionOpenMessage(message))
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

(* Every Market Session Close Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionCloseMessage ==
    \A message \in CheckedMarketSessionCloseMessage :
        LET read == DecodeMarketSessionCloseMessage(EncodeMarketSessionCloseMessage(message))
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

(* Every End Of Trade Reporting Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTradeReportingMessage ==
    \A message \in CheckedEndOfTradeReportingMessage :
        LET read == DecodeEndOfTradeReportingMessage(EncodeEndOfTradeReportingMessage(message))
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

(* Every End Of Transmissions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmissionsMessage ==
    \A message \in CheckedEndOfTransmissionsMessage :
        LET read == DecodeEndOfTransmissionsMessage(EncodeEndOfTransmissionsMessage(message))
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
