--------------- MODULE PearlEquities_TopOfMarket_v1_1_c_Udp ----------------
(***************************************************************************)
(* Miami International Holdings Top Of Market v1.1.c                       *)
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
(* Note: Flags is a bit field set, checked as its 1 byte rather than bit   *)
(* by bit.                                                                 *)
(*                                                                         *)
(* Note: Application Message fills what is left of the frame Mach Packet   *)
(* Length states, which is what it is read from.                           *)
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
(* System Time Message: 4 bytes                                            *)
(***************************************************************************)

SystemTimeMessage ==
    [ seconds : Sample(4) ]

EncodeSystemTimeMessage(message) ==
    message.seconds

DecodeSystemTimeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroSystemTimeMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* System Time Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemTimeMessage ==
    { ZeroSystemTimeMessage }
        \cup { [ZeroSystemTimeMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Update Message: 41 bytes                                         *)
(***************************************************************************)

SymbolUpdateMessage ==
    [ nanoseconds           : Sample(4),
      symbolId              : Sample(4),
      tickerSymbol          : Sample(11),
      reserved1             : Sample(1),
      testSecurityIndicator : Sample(1),
      secondReserved1       : Sample(1),
      lotSize               : Sample(2),
      openingTime           : Sample(8),
      closingTime           : Sample(8),
      primaryMarketCode     : Sample(1) ]

EncodeSymbolUpdateMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.tickerSymbol
        \o message.reserved1
        \o message.testSecurityIndicator
        \o message.secondReserved1
        \o message.lotSize
        \o message.openingTime
        \o message.closingTime
        \o message.primaryMarketCode

DecodeSymbolUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tickerSymbol == ReadBytes(symbolId.rest, 11) IN IF ~tickerSymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tickerSymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET testSecurityIndicator == ReadBytes(reserved1.rest, 1) IN IF ~testSecurityIndicator.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(testSecurityIndicator.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET lotSize == ReadBytes(secondReserved1.rest, 2) IN IF ~lotSize.ok THEN Fail ELSE
    LET openingTime == ReadBytes(lotSize.rest, 8) IN IF ~openingTime.ok THEN Fail ELSE
    LET closingTime == ReadBytes(openingTime.rest, 8) IN IF ~closingTime.ok THEN Fail ELSE
    LET primaryMarketCode == ReadBytes(closingTime.rest, 1) IN IF ~primaryMarketCode.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         symbolId              |-> symbolId.value,
         tickerSymbol          |-> tickerSymbol.value,
         reserved1             |-> reserved1.value,
         testSecurityIndicator |-> testSecurityIndicator.value,
         secondReserved1       |-> secondReserved1.value,
         lotSize               |-> lotSize.value,
         openingTime           |-> openingTime.value,
         closingTime           |-> closingTime.value,
         primaryMarketCode     |-> primaryMarketCode.value ], primaryMarketCode.rest)

ZeroSymbolUpdateMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      tickerSymbol          |-> [i \in 1 .. 11 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      testSecurityIndicator |-> [i \in 1 .. 1 |-> 0],
      secondReserved1       |-> [i \in 1 .. 1 |-> 0],
      lotSize               |-> [i \in 1 .. 2 |-> 0],
      openingTime           |-> [i \in 1 .. 8 |-> 0],
      closingTime           |-> [i \in 1 .. 8 |-> 0],
      primaryMarketCode     |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolUpdateMessage ==
    { ZeroSymbolUpdateMessage }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.tickerSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.testSecurityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.lotSize = one] : one \in Sample(2) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.primaryMarketCode = one] : one \in Sample(1) }

(***************************************************************************)
(* System State Message: 14 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ nanoseconds  : Sample(4),
      toMVersion   : Sample(8),
      sessionId    : Sample(1),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.nanoseconds
        \o message.toMVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET toMVersion == ReadBytes(nanoseconds.rest, 8) IN IF ~toMVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(toMVersion.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         toMVersion   |-> toMVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      toMVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 1 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.toMVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Trading Status Notification Message: 11 bytes                  *)
(***************************************************************************)

SecurityTradingStatusNotificationMessage ==
    [ nanoseconds          : Sample(4),
      symbolId             : Sample(4),
      tradingStatus        : Sample(1),
      marketState          : Sample(1),
      shortSaleRestriction : Sample(1) ]

EncodeSecurityTradingStatusNotificationMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.tradingStatus
        \o message.marketState
        \o message.shortSaleRestriction

DecodeSecurityTradingStatusNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(symbolId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketState == ReadBytes(tradingStatus.rest, 1) IN IF ~marketState.ok THEN Fail ELSE
    LET shortSaleRestriction == ReadBytes(marketState.rest, 1) IN IF ~shortSaleRestriction.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         symbolId             |-> symbolId.value,
         tradingStatus        |-> tradingStatus.value,
         marketState          |-> marketState.value,
         shortSaleRestriction |-> shortSaleRestriction.value ], shortSaleRestriction.rest)

ZeroSecurityTradingStatusNotificationMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      symbolId             |-> [i \in 1 .. 4 |-> 0],
      tradingStatus        |-> [i \in 1 .. 1 |-> 0],
      marketState          |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestriction |-> [i \in 1 .. 1 |-> 0] ]

(* Security Trading Status Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityTradingStatusNotificationMessage ==
    { ZeroSecurityTradingStatusNotificationMessage }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.marketState = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.shortSaleRestriction = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Top Of Market Best Bid And Offer Message: 16 bytes              *)
(***************************************************************************)

CompactTopOfMarketBestBidAndOfferMessage ==
    [ nanoseconds     : Sample(4),
      symbolId        : Sample(4),
      bidPriceShort   : Sample(2),
      bidSizeShort    : Sample(2),
      offerPriceShort : Sample(2),
      offerSizeShort  : Sample(2) ]

EncodeCompactTopOfMarketBestBidAndOfferMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.offerPriceShort
        \o message.offerSizeShort

DecodeCompactTopOfMarketBestBidAndOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(symbolId.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET offerPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~offerPriceShort.ok THEN Fail ELSE
    LET offerSizeShort == ReadBytes(offerPriceShort.rest, 2) IN IF ~offerSizeShort.ok THEN Fail ELSE
    Ok([ nanoseconds     |-> nanoseconds.value,
         symbolId        |-> symbolId.value,
         bidPriceShort   |-> bidPriceShort.value,
         bidSizeShort    |-> bidSizeShort.value,
         offerPriceShort |-> offerPriceShort.value,
         offerSizeShort  |-> offerSizeShort.value ], offerSizeShort.rest)

ZeroCompactTopOfMarketBestBidAndOfferMessage ==
    [ nanoseconds     |-> [i \in 1 .. 4 |-> 0],
      symbolId        |-> [i \in 1 .. 4 |-> 0],
      bidPriceShort   |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort    |-> [i \in 1 .. 2 |-> 0],
      offerPriceShort |-> [i \in 1 .. 2 |-> 0],
      offerSizeShort  |-> [i \in 1 .. 2 |-> 0] ]

(* Compact Top Of Market Best Bid And Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedCompactTopOfMarketBestBidAndOfferMessage ==
    { ZeroCompactTopOfMarketBestBidAndOfferMessage }
        \cup { [ZeroCompactTopOfMarketBestBidAndOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCompactTopOfMarketBestBidAndOfferMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCompactTopOfMarketBestBidAndOfferMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBestBidAndOfferMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBestBidAndOfferMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBestBidAndOfferMessage EXCEPT !.offerSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Wide Top Of Market Best Bid And Offer Message: 32 bytes                 *)
(***************************************************************************)

WideTopOfMarketBestBidAndOfferMessage ==
    [ nanoseconds    : Sample(4),
      symbolId       : Sample(4),
      bidPriceLong   : Sample(8),
      bidSizeLong    : Sample(4),
      offerPriceLong : Sample(8),
      offerSizeLong  : Sample(4) ]

EncodeWideTopOfMarketBestBidAndOfferMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.offerPriceLong
        \o message.offerSizeLong

DecodeWideTopOfMarketBestBidAndOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(symbolId.rest, 8) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET offerPriceLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~offerPriceLong.ok THEN Fail ELSE
    LET offerSizeLong == ReadBytes(offerPriceLong.rest, 4) IN IF ~offerSizeLong.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         symbolId       |-> symbolId.value,
         bidPriceLong   |-> bidPriceLong.value,
         bidSizeLong    |-> bidSizeLong.value,
         offerPriceLong |-> offerPriceLong.value,
         offerSizeLong  |-> offerSizeLong.value ], offerSizeLong.rest)

ZeroWideTopOfMarketBestBidAndOfferMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      symbolId       |-> [i \in 1 .. 4 |-> 0],
      bidPriceLong   |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong    |-> [i \in 1 .. 4 |-> 0],
      offerPriceLong |-> [i \in 1 .. 8 |-> 0],
      offerSizeLong  |-> [i \in 1 .. 4 |-> 0] ]

(* Wide Top Of Market Best Bid And Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedWideTopOfMarketBestBidAndOfferMessage ==
    { ZeroWideTopOfMarketBestBidAndOfferMessage }
        \cup { [ZeroWideTopOfMarketBestBidAndOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestBidAndOfferMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestBidAndOfferMessage EXCEPT !.bidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroWideTopOfMarketBestBidAndOfferMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestBidAndOfferMessage EXCEPT !.offerPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroWideTopOfMarketBestBidAndOfferMessage EXCEPT !.offerSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Last Sale Message: 30 bytes                                             *)
(***************************************************************************)

LastSaleMessage ==
    [ nanoseconds      : Sample(4),
      symbolId         : Sample(4),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4),
      flags            : Sample(1) ]

EncodeLastSaleMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size
        \o message.flags

DecodeLastSaleMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET flags == ReadBytes(size.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         symbolId         |-> symbolId.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value,
         flags            |-> flags.value ], flags.rest)

ZeroLastSaleMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      symbolId         |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      flags            |-> [i \in 1 .. 1 |-> 0] ]

(* Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedLastSaleMessage ==
    { ZeroLastSaleMessage }
        \cup { [ZeroLastSaleMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroLastSaleMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroLastSaleMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.flags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Message: 29 bytes                                          *)
(***************************************************************************)

TradeCancelMessage ==
    [ nanoseconds      : Sample(4),
      symbolId         : Sample(4),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4) ]

EncodeTradeCancelMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size

DecodeTradeCancelMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         symbolId         |-> symbolId.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value ], size.rest)

ZeroTradeCancelMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      symbolId         |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.size = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* 0x31
SymbolUpdateMessageCode == 1  \* 0x01
SystemStateMessageCode == 83  \* 0x53
SecurityTradingStatusNotificationMessageCode == 4  \* 0x04
CompactTopOfMarketBestBidAndOfferMessageCode == 2  \* 0x02
WideTopOfMarketBestBidAndOfferMessageCode == 3  \* 0x03
LastSaleMessageCode == 10  \* 0x0a
TradeCancelMessageCode == 11  \* 0x0b

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SymbolUpdateMessageCode}, body : SymbolUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {SecurityTradingStatusNotificationMessageCode}, body : SecurityTradingStatusNotificationMessage ]
        \cup [ tag : {CompactTopOfMarketBestBidAndOfferMessageCode}, body : CompactTopOfMarketBestBidAndOfferMessage ]
        \cup [ tag : {WideTopOfMarketBestBidAndOfferMessageCode}, body : WideTopOfMarketBestBidAndOfferMessage ]
        \cup [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SymbolUpdateMessageCode -> EncodeSymbolUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = SecurityTradingStatusNotificationMessageCode -> EncodeSecurityTradingStatusNotificationMessage(message.body)
      [] message.tag = CompactTopOfMarketBestBidAndOfferMessageCode -> EncodeCompactTopOfMarketBestBidAndOfferMessage(message.body)
      [] message.tag = WideTopOfMarketBestBidAndOfferMessageCode -> EncodeWideTopOfMarketBestBidAndOfferMessage(message.body)
      [] message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SymbolUpdateMessageCode -> DecodeSymbolUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = SecurityTradingStatusNotificationMessageCode -> DecodeSecurityTradingStatusNotificationMessage(bytes)
              [] tag = CompactTopOfMarketBestBidAndOfferMessageCode -> DecodeCompactTopOfMarketBestBidAndOfferMessage(bytes)
              [] tag = WideTopOfMarketBestBidAndOfferMessageCode -> DecodeWideTopOfMarketBestBidAndOfferMessage(bytes)
              [] tag = LastSaleMessageCode -> DecodeLastSaleMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SymbolUpdateMessageCode, body |-> one] : one \in CheckedSymbolUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> SecurityTradingStatusNotificationMessageCode, body |-> one] : one \in CheckedSecurityTradingStatusNotificationMessage }
        \cup { [tag |-> CompactTopOfMarketBestBidAndOfferMessageCode, body |-> one] : one \in CheckedCompactTopOfMarketBestBidAndOfferMessage }
        \cup { [tag |-> WideTopOfMarketBestBidAndOfferMessageCode, body |-> one] : one \in CheckedWideTopOfMarketBestBidAndOfferMessage }
        \cup { [tag |-> LastSaleMessageCode, body |-> one] : one \in CheckedLastSaleMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }

(***************************************************************************)
(* Application Message                                                     *)
(***************************************************************************)

ApplicationMessage ==
    [ data : Data ]

EncodeApplicationMessage(message) ==
    EncodeUIntBE(message.data.tag, 1)
        \o EncodeData(message.data)

DecodeApplicationMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET data == DecodeData(messageType.value, messageType.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroApplicationMessage ==
    [ data |-> ZeroData ]

(* Application Message at zero, then each field in turn at the values it is checked at *)
CheckedApplicationMessage ==
    { ZeroApplicationMessage }
        \cup { [ZeroApplicationMessage EXCEPT !.data = one] : one \in CheckedData }

(***************************************************************************)
(* Payload, selected by Mach Packet Type                                   *)
(***************************************************************************)

HeartbeatCode == 0  \* 0x00
StartOfSessionCode == 1  \* 0x01
EndOfSessionCode == 2  \* 0x02
ApplicationMessageCode == 3  \* 0x03

Payload ==
    [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {StartOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ApplicationMessageCode}, body : ApplicationMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatCode -> << >>
      [] message.tag = StartOfSessionCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ApplicationMessageCode -> EncodeApplicationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = StartOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = ApplicationMessageCode -> DecodeApplicationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> StartOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ApplicationMessageCode, body |-> one] : one \in CheckedApplicationMessage }

(***************************************************************************)
(* Mach Message, framed by Mach Packet Length                              *)
(***************************************************************************)

MachMessage ==
    [ sequenceNumber : Sample(8),
      sessionNumber  : Sample(1),
      payload        : Payload ]

EncodeMachMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o message.sessionNumber
        \o EncodePayload(message.payload)

(* Mach Packet Length counts the bytes it frames, so it is written from them *)
EncodeMachMessage(message) ==
    LET body == EncodeMachMessageBody(message)
    IN  message.sequenceNumber \o EncodeUIntLE(Len(body) + 10, 2) \o body

DecodeMachMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET length == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 10 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET machPacketType == ReadUIntLE(framed, 1) IN IF ~machPacketType.ok THEN Fail ELSE
    LET sessionNumber == ReadBytes(machPacketType.rest, 1) IN IF ~sessionNumber.ok THEN Fail ELSE
    LET payload == DecodePayload(machPacketType.value, sessionNumber.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         sessionNumber  |-> sessionNumber.value,
         payload        |-> payload.value ], beyond)

ZeroMachMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sessionNumber  |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Mach Message at zero, then each field in turn at the values it is checked at *)
CheckedMachMessage ==
    { ZeroMachMessage }
        \cup { [ZeroMachMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMachMessage EXCEPT !.sessionNumber = one] : one \in Sample(1) }
        \cup { [ZeroMachMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Mach Message, written one after another *)
RECURSIVE EncodeMachMessageList(_)
EncodeMachMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMachMessage(Head(messages)) \o EncodeMachMessageList(Tail(messages))

(* As many Mach Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMachMessageAll(_)
ReadMachMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMachMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMachMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mach Message of each kind, for the lists that carry them *)
OneMachMessage ==
    { [ZeroMachMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> StartOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ machMessage : SampleLists(OneMachMessage) ]

EncodeUdpPacket(message) ==
    EncodeMachMessageList(message.machMessage)

DecodeUdpPacket(bytes) ==
    LET machMessage == ReadMachMessageAll(bytes) IN IF ~machMessage.ok THEN Fail ELSE
    Ok([ machMessage |-> machMessage.value ], machMessage.rest)

ZeroUdpPacket ==
    [ machMessage |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.machMessage = one] : one \in SampleLists(OneMachMessage) }

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

(* Every System Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemTimeMessage ==
    \A message \in CheckedSystemTimeMessage :
        LET read == DecodeSystemTimeMessage(EncodeSystemTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolUpdateMessage ==
    \A message \in CheckedSymbolUpdateMessage :
        LET read == DecodeSymbolUpdateMessage(EncodeSymbolUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateMessage ==
    \A message \in CheckedSystemStateMessage :
        LET read == DecodeSystemStateMessage(EncodeSystemStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Trading Status Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityTradingStatusNotificationMessage ==
    \A message \in CheckedSecurityTradingStatusNotificationMessage :
        LET read == DecodeSecurityTradingStatusNotificationMessage(EncodeSecurityTradingStatusNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Compact Top Of Market Best Bid And Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactTopOfMarketBestBidAndOfferMessage ==
    \A message \in CheckedCompactTopOfMarketBestBidAndOfferMessage :
        LET read == DecodeCompactTopOfMarketBestBidAndOfferMessage(EncodeCompactTopOfMarketBestBidAndOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Top Of Market Best Bid And Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWideTopOfMarketBestBidAndOfferMessage ==
    \A message \in CheckedWideTopOfMarketBestBidAndOfferMessage :
        LET read == DecodeWideTopOfMarketBestBidAndOfferMessage(EncodeWideTopOfMarketBestBidAndOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Last Sale Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastSaleMessage ==
    \A message \in CheckedLastSaleMessage :
        LET read == DecodeLastSaleMessage(EncodeLastSaleMessage(message))
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

(* Every Application Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApplicationMessage ==
    \A message \in CheckedApplicationMessage :
        LET read == DecodeApplicationMessage(EncodeApplicationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMachMessage ==
    \A message \in CheckedMachMessage :
        LET read == DecodeMachMessage(EncodeMachMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Data is selected by the Message Type it is written under *)
SelectsData ==
    \A message \in CheckedData :
        LET read == DecodeData(message.tag, EncodeData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Mach Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Mach Packet Length is written from the bytes it frames *)
FramesMachMessage ==
    \A message \in CheckedMachMessage :
        LET bytes == EncodeMachMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 9, 10)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
