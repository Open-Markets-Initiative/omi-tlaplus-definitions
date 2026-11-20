---------------------- MODULE NasdaqCanada_Basic_v1_6 ----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nasdaq Basic Canada v1.6                                       *)
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
(* Quotation Message: 58 bytes                                             *)
(***************************************************************************)

QuotationMessage ==
    [ timeStamp                : Sample(8),
      stockSymbol              : Sample(10),
      nasdaqCanadaBestBidPrice : Sample(8),
      nasdaqCanadaBestBidSize  : Sample(4),
      nasdaqCxcBestBidSize     : Sample(4),
      nasdaqCx2BestBidSize     : Sample(4),
      nasdaqCanadaBestAskPrice : Sample(8),
      nasdaqCanadaBestAskSize  : Sample(4),
      nasdaqCxcBestAskSize     : Sample(4),
      nasdaqCx2BestAskSize     : Sample(4) ]

EncodeQuotationMessage(message) ==
    message.timeStamp
        \o message.stockSymbol
        \o message.nasdaqCanadaBestBidPrice
        \o message.nasdaqCanadaBestBidSize
        \o message.nasdaqCxcBestBidSize
        \o message.nasdaqCx2BestBidSize
        \o message.nasdaqCanadaBestAskPrice
        \o message.nasdaqCanadaBestAskSize
        \o message.nasdaqCxcBestAskSize
        \o message.nasdaqCx2BestAskSize

DecodeQuotationMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(timeStamp.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET nasdaqCanadaBestBidPrice == ReadBytes(stockSymbol.rest, 8) IN IF ~nasdaqCanadaBestBidPrice.ok THEN Fail ELSE
    LET nasdaqCanadaBestBidSize == ReadBytes(nasdaqCanadaBestBidPrice.rest, 4) IN IF ~nasdaqCanadaBestBidSize.ok THEN Fail ELSE
    LET nasdaqCxcBestBidSize == ReadBytes(nasdaqCanadaBestBidSize.rest, 4) IN IF ~nasdaqCxcBestBidSize.ok THEN Fail ELSE
    LET nasdaqCx2BestBidSize == ReadBytes(nasdaqCxcBestBidSize.rest, 4) IN IF ~nasdaqCx2BestBidSize.ok THEN Fail ELSE
    LET nasdaqCanadaBestAskPrice == ReadBytes(nasdaqCx2BestBidSize.rest, 8) IN IF ~nasdaqCanadaBestAskPrice.ok THEN Fail ELSE
    LET nasdaqCanadaBestAskSize == ReadBytes(nasdaqCanadaBestAskPrice.rest, 4) IN IF ~nasdaqCanadaBestAskSize.ok THEN Fail ELSE
    LET nasdaqCxcBestAskSize == ReadBytes(nasdaqCanadaBestAskSize.rest, 4) IN IF ~nasdaqCxcBestAskSize.ok THEN Fail ELSE
    LET nasdaqCx2BestAskSize == ReadBytes(nasdaqCxcBestAskSize.rest, 4) IN IF ~nasdaqCx2BestAskSize.ok THEN Fail ELSE
    Ok([ timeStamp                |-> timeStamp.value,
         stockSymbol              |-> stockSymbol.value,
         nasdaqCanadaBestBidPrice |-> nasdaqCanadaBestBidPrice.value,
         nasdaqCanadaBestBidSize  |-> nasdaqCanadaBestBidSize.value,
         nasdaqCxcBestBidSize     |-> nasdaqCxcBestBidSize.value,
         nasdaqCx2BestBidSize     |-> nasdaqCx2BestBidSize.value,
         nasdaqCanadaBestAskPrice |-> nasdaqCanadaBestAskPrice.value,
         nasdaqCanadaBestAskSize  |-> nasdaqCanadaBestAskSize.value,
         nasdaqCxcBestAskSize     |-> nasdaqCxcBestAskSize.value,
         nasdaqCx2BestAskSize     |-> nasdaqCx2BestAskSize.value ], nasdaqCx2BestAskSize.rest)

ZeroQuotationMessage ==
    [ timeStamp                |-> [i \in 1 .. 8 |-> 0],
      stockSymbol              |-> [i \in 1 .. 10 |-> 0],
      nasdaqCanadaBestBidPrice |-> [i \in 1 .. 8 |-> 0],
      nasdaqCanadaBestBidSize  |-> [i \in 1 .. 4 |-> 0],
      nasdaqCxcBestBidSize     |-> [i \in 1 .. 4 |-> 0],
      nasdaqCx2BestBidSize     |-> [i \in 1 .. 4 |-> 0],
      nasdaqCanadaBestAskPrice |-> [i \in 1 .. 8 |-> 0],
      nasdaqCanadaBestAskSize  |-> [i \in 1 .. 4 |-> 0],
      nasdaqCxcBestAskSize     |-> [i \in 1 .. 4 |-> 0],
      nasdaqCx2BestAskSize     |-> [i \in 1 .. 4 |-> 0] ]

(* Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedQuotationMessage ==
    { ZeroQuotationMessage }
        \cup { [ZeroQuotationMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroQuotationMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroQuotationMessage EXCEPT !.nasdaqCanadaBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuotationMessage EXCEPT !.nasdaqCanadaBestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotationMessage EXCEPT !.nasdaqCxcBestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotationMessage EXCEPT !.nasdaqCx2BestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotationMessage EXCEPT !.nasdaqCanadaBestAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuotationMessage EXCEPT !.nasdaqCanadaBestAskSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotationMessage EXCEPT !.nasdaqCxcBestAskSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotationMessage EXCEPT !.nasdaqCx2BestAskSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Condition Modifier: 4 bytes                                        *)
(***************************************************************************)

SaleConditionModifier ==
    [ saleConditionModifierLevel1  : Sample(1),
      salesConditionModifierLevel2 : Sample(1),
      salesConditionModifierLevel3 : Sample(1),
      salesConditionModifierLevel4 : Sample(1) ]

EncodeSaleConditionModifier(message) ==
    message.saleConditionModifierLevel1
        \o message.salesConditionModifierLevel2
        \o message.salesConditionModifierLevel3
        \o message.salesConditionModifierLevel4

DecodeSaleConditionModifier(bytes) ==
    LET saleConditionModifierLevel1 == ReadBytes(bytes, 1) IN IF ~saleConditionModifierLevel1.ok THEN Fail ELSE
    LET salesConditionModifierLevel2 == ReadBytes(saleConditionModifierLevel1.rest, 1) IN IF ~salesConditionModifierLevel2.ok THEN Fail ELSE
    LET salesConditionModifierLevel3 == ReadBytes(salesConditionModifierLevel2.rest, 1) IN IF ~salesConditionModifierLevel3.ok THEN Fail ELSE
    LET salesConditionModifierLevel4 == ReadBytes(salesConditionModifierLevel3.rest, 1) IN IF ~salesConditionModifierLevel4.ok THEN Fail ELSE
    Ok([ saleConditionModifierLevel1  |-> saleConditionModifierLevel1.value,
         salesConditionModifierLevel2 |-> salesConditionModifierLevel2.value,
         salesConditionModifierLevel3 |-> salesConditionModifierLevel3.value,
         salesConditionModifierLevel4 |-> salesConditionModifierLevel4.value ], salesConditionModifierLevel4.rest)

ZeroSaleConditionModifier ==
    [ saleConditionModifierLevel1  |-> [i \in 1 .. 1 |-> 0],
      salesConditionModifierLevel2 |-> [i \in 1 .. 1 |-> 0],
      salesConditionModifierLevel3 |-> [i \in 1 .. 1 |-> 0],
      salesConditionModifierLevel4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition Modifier at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditionModifier ==
    { ZeroSaleConditionModifier }
        \cup { [ZeroSaleConditionModifier EXCEPT !.saleConditionModifierLevel1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier EXCEPT !.salesConditionModifierLevel2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier EXCEPT !.salesConditionModifierLevel3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditionModifier EXCEPT !.salesConditionModifierLevel4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Message: 53 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ timeStamp                         : Sample(8),
      originatingMarketCenterIdentifier : Sample(1),
      stockSymbol                       : Sample(10),
      tradeNumber                       : Sample(4),
      tradePrice                        : Sample(8),
      tradeSize                         : Sample(4),
      broker                            : Sample(3),
      contraBroker                      : Sample(3),
      saleConditionModifier             : SaleConditionModifier,
      consolidatedTradeVolume           : Sample(8) ]

EncodeTradeReportMessage(message) ==
    message.timeStamp
        \o message.originatingMarketCenterIdentifier
        \o message.stockSymbol
        \o message.tradeNumber
        \o message.tradePrice
        \o message.tradeSize
        \o message.broker
        \o message.contraBroker
        \o EncodeSaleConditionModifier(message.saleConditionModifier)
        \o message.consolidatedTradeVolume

DecodeTradeReportMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET originatingMarketCenterIdentifier == ReadBytes(timeStamp.rest, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(stockSymbol.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeNumber.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET broker == ReadBytes(tradeSize.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    LET saleConditionModifier == DecodeSaleConditionModifier(contraBroker.rest) IN IF ~saleConditionModifier.ok THEN Fail ELSE
    LET consolidatedTradeVolume == ReadBytes(saleConditionModifier.rest, 8) IN IF ~consolidatedTradeVolume.ok THEN Fail ELSE
    Ok([ timeStamp                         |-> timeStamp.value,
         originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         stockSymbol                       |-> stockSymbol.value,
         tradeNumber                       |-> tradeNumber.value,
         tradePrice                        |-> tradePrice.value,
         tradeSize                         |-> tradeSize.value,
         broker                            |-> broker.value,
         contraBroker                      |-> contraBroker.value,
         saleConditionModifier             |-> saleConditionModifier.value,
         consolidatedTradeVolume           |-> consolidatedTradeVolume.value ], consolidatedTradeVolume.rest)

ZeroTradeReportMessage ==
    [ timeStamp                         |-> [i \in 1 .. 8 |-> 0],
      originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      stockSymbol                       |-> [i \in 1 .. 10 |-> 0],
      tradeNumber                       |-> [i \in 1 .. 4 |-> 0],
      tradePrice                        |-> [i \in 1 .. 8 |-> 0],
      tradeSize                         |-> [i \in 1 .. 4 |-> 0],
      broker                            |-> [i \in 1 .. 3 |-> 0],
      contraBroker                      |-> [i \in 1 .. 3 |-> 0],
      saleConditionModifier             |-> ZeroSaleConditionModifier,
      consolidatedTradeVolume           |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroTradeReportMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionModifier = one] : one \in CheckedSaleConditionModifier }
        \cup { [ZeroTradeReportMessage EXCEPT !.consolidatedTradeVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Break Message: 13 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ timeStamp                         : Sample(8),
      tradeControlNumber                : Sample(4),
      originatingMarketCenterIdentifier : Sample(1) ]

EncodeTradeBreakMessage(message) ==
    message.timeStamp
        \o message.tradeControlNumber
        \o message.originatingMarketCenterIdentifier

DecodeTradeBreakMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET tradeControlNumber == ReadBytes(timeStamp.rest, 4) IN IF ~tradeControlNumber.ok THEN Fail ELSE
    LET originatingMarketCenterIdentifier == ReadBytes(tradeControlNumber.rest, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    Ok([ timeStamp                         |-> timeStamp.value,
         tradeControlNumber                |-> tradeControlNumber.value,
         originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value ], originatingMarketCenterIdentifier.rest)

ZeroTradeBreakMessage ==
    [ timeStamp                         |-> [i \in 1 .. 8 |-> 0],
      tradeControlNumber                |-> [i \in 1 .. 4 |-> 0],
      originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.tradeControlNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correction Message: 47 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ timeStamp                         : Sample(8),
      originatingMarketCenterIdentifier : Sample(1),
      stockSymbol                       : Sample(10),
      originalTradeNumber               : Sample(4),
      originalTradePrice                : Sample(8),
      originalTradeSize                 : Sample(4),
      correctedTradePrice               : Sample(8),
      correctedTradeSize                : Sample(4) ]

EncodeTradeCorrectionMessage(message) ==
    message.timeStamp
        \o message.originatingMarketCenterIdentifier
        \o message.stockSymbol
        \o message.originalTradeNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o message.correctedTradePrice
        \o message.correctedTradeSize

DecodeTradeCorrectionMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET originatingMarketCenterIdentifier == ReadBytes(timeStamp.rest, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET originalTradeNumber == ReadBytes(stockSymbol.rest, 4) IN IF ~originalTradeNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeNumber.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(originalTradeSize.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    Ok([ timeStamp                         |-> timeStamp.value,
         originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         stockSymbol                       |-> stockSymbol.value,
         originalTradeNumber               |-> originalTradeNumber.value,
         originalTradePrice                |-> originalTradePrice.value,
         originalTradeSize                 |-> originalTradeSize.value,
         correctedTradePrice               |-> correctedTradePrice.value,
         correctedTradeSize                |-> correctedTradeSize.value ], correctedTradeSize.rest)

ZeroTradeCorrectionMessage ==
    [ timeStamp                         |-> [i \in 1 .. 8 |-> 0],
      originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      stockSymbol                       |-> [i \in 1 .. 10 |-> 0],
      originalTradeNumber               |-> [i \in 1 .. 4 |-> 0],
      originalTradePrice                |-> [i \in 1 .. 8 |-> 0],
      originalTradeSize                 |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice               |-> [i \in 1 .. 8 |-> 0],
      correctedTradeSize                |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 10 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timeStamp                         : Sample(8),
      originatingMarketCenterIdentifier : Sample(1),
      eventCode                         : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timeStamp
        \o message.originatingMarketCenterIdentifier
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET originatingMarketCenterIdentifier == ReadBytes(timeStamp.rest, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET eventCode == ReadBytes(originatingMarketCenterIdentifier.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ timeStamp                         |-> timeStamp.value,
         originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         eventCode                         |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ timeStamp                         |-> [i \in 1 .. 8 |-> 0],
      originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      eventCode                         |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory Message: 64 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ timeStamp        : Sample(8),
      stockSymbol      : Sample(10),
      stockDisplayName : Sample(40),
      listingMarket    : Sample(1),
      boardLotSize     : Sample(4),
      currency         : Sample(1) ]

EncodeStockDirectoryMessage(message) ==
    message.timeStamp
        \o message.stockSymbol
        \o message.stockDisplayName
        \o message.listingMarket
        \o message.boardLotSize
        \o message.currency

DecodeStockDirectoryMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(timeStamp.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET stockDisplayName == ReadBytes(stockSymbol.rest, 40) IN IF ~stockDisplayName.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(stockDisplayName.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET boardLotSize == ReadBytes(listingMarket.rest, 4) IN IF ~boardLotSize.ok THEN Fail ELSE
    LET currency == ReadBytes(boardLotSize.rest, 1) IN IF ~currency.ok THEN Fail ELSE
    Ok([ timeStamp        |-> timeStamp.value,
         stockSymbol      |-> stockSymbol.value,
         stockDisplayName |-> stockDisplayName.value,
         listingMarket    |-> listingMarket.value,
         boardLotSize     |-> boardLotSize.value,
         currency         |-> currency.value ], currency.rest)

ZeroStockDirectoryMessage ==
    [ timeStamp        |-> [i \in 1 .. 8 |-> 0],
      stockSymbol      |-> [i \in 1 .. 10 |-> 0],
      stockDisplayName |-> [i \in 1 .. 40 |-> 0],
      listingMarket    |-> [i \in 1 .. 1 |-> 0],
      boardLotSize     |-> [i \in 1 .. 4 |-> 0],
      currency         |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stockDisplayName = one] : one \in Sample(40) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.boardLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.currency = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Status Message: 20 bytes                                          *)
(***************************************************************************)

StockStatusMessage ==
    [ timeStamp    : Sample(8),
      stockSymbol  : Sample(10),
      market       : Sample(1),
      systemStatus : Sample(1) ]

EncodeStockStatusMessage(message) ==
    message.timeStamp
        \o message.stockSymbol
        \o message.market
        \o message.systemStatus

DecodeStockStatusMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(timeStamp.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET market == ReadBytes(stockSymbol.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(market.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ timeStamp    |-> timeStamp.value,
         stockSymbol  |-> stockSymbol.value,
         market       |-> market.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroStockStatusMessage ==
    [ timeStamp    |-> [i \in 1 .. 8 |-> 0],
      stockSymbol  |-> [i \in 1 .. 10 |-> 0],
      market       |-> [i \in 1 .. 1 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Status Message at zero, then each field in turn at the values it is checked at *)
CheckedStockStatusMessage ==
    { ZeroStockStatusMessage }
        \cup { [ZeroStockStatusMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroStockStatusMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroStockStatusMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroStockStatusMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Day Trade Summary Message: 74 bytes                              *)
(***************************************************************************)

EndOfDayTradeSummaryMessage ==
    [ timeStamp               : Sample(8),
      stockSymbol             : Sample(10),
      consolidatedHighPrice   : Sample(8),
      consolidatedLowPrice    : Sample(8),
      consolidatedOpenPrice   : Sample(8),
      listingCenterOpenPrice  : Sample(8),
      consolidatedClosePrice  : Sample(8),
      listingCenterClosePrice : Sample(8),
      consolidatedVolume      : Sample(8) ]

EncodeEndOfDayTradeSummaryMessage(message) ==
    message.timeStamp
        \o message.stockSymbol
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedOpenPrice
        \o message.listingCenterOpenPrice
        \o message.consolidatedClosePrice
        \o message.listingCenterClosePrice
        \o message.consolidatedVolume

DecodeEndOfDayTradeSummaryMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(timeStamp.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(stockSymbol.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedOpenPrice == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedOpenPrice.ok THEN Fail ELSE
    LET listingCenterOpenPrice == ReadBytes(consolidatedOpenPrice.rest, 8) IN IF ~listingCenterOpenPrice.ok THEN Fail ELSE
    LET consolidatedClosePrice == ReadBytes(listingCenterOpenPrice.rest, 8) IN IF ~consolidatedClosePrice.ok THEN Fail ELSE
    LET listingCenterClosePrice == ReadBytes(consolidatedClosePrice.rest, 8) IN IF ~listingCenterClosePrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(listingCenterClosePrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ timeStamp               |-> timeStamp.value,
         stockSymbol             |-> stockSymbol.value,
         consolidatedHighPrice   |-> consolidatedHighPrice.value,
         consolidatedLowPrice    |-> consolidatedLowPrice.value,
         consolidatedOpenPrice   |-> consolidatedOpenPrice.value,
         listingCenterOpenPrice  |-> listingCenterOpenPrice.value,
         consolidatedClosePrice  |-> consolidatedClosePrice.value,
         listingCenterClosePrice |-> listingCenterClosePrice.value,
         consolidatedVolume      |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroEndOfDayTradeSummaryMessage ==
    [ timeStamp               |-> [i \in 1 .. 8 |-> 0],
      stockSymbol             |-> [i \in 1 .. 10 |-> 0],
      consolidatedHighPrice   |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice    |-> [i \in 1 .. 8 |-> 0],
      consolidatedOpenPrice   |-> [i \in 1 .. 8 |-> 0],
      listingCenterOpenPrice  |-> [i \in 1 .. 8 |-> 0],
      consolidatedClosePrice  |-> [i \in 1 .. 8 |-> 0],
      listingCenterClosePrice |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume      |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayTradeSummaryMessage ==
    { ZeroEndOfDayTradeSummaryMessage }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.listingCenterOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.listingCenterClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Adjusted Closing Price Message: 27 bytes                                *)
(***************************************************************************)

AdjustedClosingPriceMessage ==
    [ timeStamp            : Sample(8),
      issueSymbol          : Sample(10),
      securityClass        : Sample(1),
      adjustedClosingPrice : Sample(8) ]

EncodeAdjustedClosingPriceMessage(message) ==
    message.timeStamp
        \o message.issueSymbol
        \o message.securityClass
        \o message.adjustedClosingPrice

DecodeAdjustedClosingPriceMessage(bytes) ==
    LET timeStamp == ReadBytes(bytes, 8) IN IF ~timeStamp.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(timeStamp.rest, 10) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(securityClass.rest, 8) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    Ok([ timeStamp            |-> timeStamp.value,
         issueSymbol          |-> issueSymbol.value,
         securityClass        |-> securityClass.value,
         adjustedClosingPrice |-> adjustedClosingPrice.value ], adjustedClosingPrice.rest)

ZeroAdjustedClosingPriceMessage ==
    [ timeStamp            |-> [i \in 1 .. 8 |-> 0],
      issueSymbol          |-> [i \in 1 .. 10 |-> 0],
      securityClass        |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Adjusted Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedAdjustedClosingPriceMessage ==
    { ZeroAdjustedClosingPriceMessage }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.timeStamp = one] : one \in Sample(8) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.issueSymbol = one] : one \in Sample(10) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.adjustedClosingPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

QuotationMessageCode == 67  \* "C"
TradeReportMessageCode == 84  \* "T"
TradeBreakMessageCode == 88  \* "X"
TradeCorrectionMessageCode == 90  \* "Z"
SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
StockStatusMessageCode == 72  \* "H"
EndOfDayTradeSummaryMessageCode == 68  \* "D"
AdjustedClosingPriceMessageCode == 71  \* "G"

Payload ==
    [ tag : {QuotationMessageCode}, body : QuotationMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {StockStatusMessageCode}, body : StockStatusMessage ]
        \cup [ tag : {EndOfDayTradeSummaryMessageCode}, body : EndOfDayTradeSummaryMessage ]
        \cup [ tag : {AdjustedClosingPriceMessageCode}, body : AdjustedClosingPriceMessage ]

EncodePayload(message) ==
    CASE message.tag = QuotationMessageCode -> EncodeQuotationMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = StockStatusMessageCode -> EncodeStockStatusMessage(message.body)
      [] message.tag = EndOfDayTradeSummaryMessageCode -> EncodeEndOfDayTradeSummaryMessage(message.body)
      [] message.tag = AdjustedClosingPriceMessageCode -> EncodeAdjustedClosingPriceMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = QuotationMessageCode -> DecodeQuotationMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = StockStatusMessageCode -> DecodeStockStatusMessage(bytes)
              [] tag = EndOfDayTradeSummaryMessageCode -> DecodeEndOfDayTradeSummaryMessage(bytes)
              [] tag = AdjustedClosingPriceMessageCode -> DecodeAdjustedClosingPriceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> QuotationMessageCode, body |-> ZeroQuotationMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> QuotationMessageCode, body |-> one] : one \in CheckedQuotationMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> StockStatusMessageCode, body |-> one] : one \in CheckedStockStatusMessage }
        \cup { [tag |-> EndOfDayTradeSummaryMessageCode, body |-> one] : one \in CheckedEndOfDayTradeSummaryMessage }
        \cup { [tag |-> AdjustedClosingPriceMessageCode, body |-> one] : one \in CheckedAdjustedClosingPriceMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> QuotationMessageCode, body |-> ZeroQuotationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryMessageCode, body |-> ZeroStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockStatusMessageCode, body |-> ZeroStockStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfDayTradeSummaryMessageCode, body |-> ZeroEndOfDayTradeSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdjustedClosingPriceMessageCode, body |-> ZeroAdjustedClosingPriceMessage]] }

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

(* Every Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotationMessage ==
    \A message \in CheckedQuotationMessage :
        LET read == DecodeQuotationMessage(EncodeQuotationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition Modifier decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditionModifier ==
    \A message \in CheckedSaleConditionModifier :
        LET read == DecodeSaleConditionModifier(EncodeSaleConditionModifier(message))
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

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockStatusMessage ==
    \A message \in CheckedStockStatusMessage :
        LET read == DecodeStockStatusMessage(EncodeStockStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayTradeSummaryMessage ==
    \A message \in CheckedEndOfDayTradeSummaryMessage :
        LET read == DecodeEndOfDayTradeSummaryMessage(EncodeEndOfDayTradeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Adjusted Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdjustedClosingPriceMessage ==
    \A message \in CheckedAdjustedClosingPriceMessage :
        LET read == DecodeAdjustedClosingPriceMessage(EncodeAdjustedClosingPriceMessage(message))
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
