------------------ MODULE NtxOptions_TopOfMarket_v2_2_Udp ------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Top Of Market v2.2                                             *)
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

(* The integer a rule depends on *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivative Directory Message: 86 bytes                                  *)
(***************************************************************************)

DerivativeDirectoryMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      instrumentId        : Sample(4),
      securitySymbol      : Sample(6),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDate      : Sample(1),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      underlyingSymbol    : Sample(13),
      closingType         : Sample(1),
      tradable            : Sample(1),
      mpv                 : Sample(1),
      isin                : Sample(12),
      tickSizeTableId     : Sample(2),
      priceNotation       : Sample(1),
      volumeNotation      : Sample(1),
      financialProduct    : Sample(2),
      marketSegmentId     : Sample(1),
      tradingCurrency     : Sample(3),
      mic                 : Sample(4),
      instrumentLongName  : Sample(16) ]

EncodeDerivativeDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDate
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.underlyingSymbol
        \o message.closingType
        \o message.tradable
        \o message.mpv
        \o message.isin
        \o message.tickSizeTableId
        \o message.priceNotation
        \o message.volumeNotation
        \o message.financialProduct
        \o message.marketSegmentId
        \o message.tradingCurrency
        \o message.mic
        \o message.instrumentLongName

DecodeDerivativeDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(instrumentId.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDate.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDate.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET closingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~closingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(closingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    LET isin == ReadBytes(mpv.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET tickSizeTableId == ReadBytes(isin.rest, 2) IN IF ~tickSizeTableId.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(tickSizeTableId.rest, 1) IN IF ~priceNotation.ok THEN Fail ELSE
    LET volumeNotation == ReadBytes(priceNotation.rest, 1) IN IF ~volumeNotation.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(volumeNotation.rest, 2) IN IF ~financialProduct.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(financialProduct.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(marketSegmentId.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET mic == ReadBytes(tradingCurrency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET instrumentLongName == ReadBytes(mic.rest, 16) IN IF ~instrumentLongName.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         instrumentId        |-> instrumentId.value,
         securitySymbol      |-> securitySymbol.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDate      |-> expirationDate.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         underlyingSymbol    |-> underlyingSymbol.value,
         closingType         |-> closingType.value,
         tradable            |-> tradable.value,
         mpv                 |-> mpv.value,
         isin                |-> isin.value,
         tickSizeTableId     |-> tickSizeTableId.value,
         priceNotation       |-> priceNotation.value,
         volumeNotation      |-> volumeNotation.value,
         financialProduct    |-> financialProduct.value,
         marketSegmentId     |-> marketSegmentId.value,
         tradingCurrency     |-> tradingCurrency.value,
         mic                 |-> mic.value,
         instrumentLongName  |-> instrumentLongName.value ], instrumentLongName.rest)

ZeroDerivativeDirectoryMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 6 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDate      |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol    |-> [i \in 1 .. 13 |-> 0],
      closingType         |-> [i \in 1 .. 1 |-> 0],
      tradable            |-> [i \in 1 .. 1 |-> 0],
      mpv                 |-> [i \in 1 .. 1 |-> 0],
      isin                |-> [i \in 1 .. 12 |-> 0],
      tickSizeTableId     |-> [i \in 1 .. 2 |-> 0],
      priceNotation       |-> [i \in 1 .. 1 |-> 0],
      volumeNotation      |-> [i \in 1 .. 1 |-> 0],
      financialProduct    |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId     |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency     |-> [i \in 1 .. 3 |-> 0],
      mic                 |-> [i \in 1 .. 4 |-> 0],
      instrumentLongName  |-> [i \in 1 .. 16 |-> 0] ]

(* Derivative Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativeDirectoryMessage ==
    { ZeroDerivativeDirectoryMessage }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationDate = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.closingType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.tickSizeTableId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.priceNotation = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.volumeNotation = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.financialProduct = one] : one \in Sample(2) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.instrumentLongName = one] : one \in Sample(16) }

(***************************************************************************)
(* Trading Action Message: 15 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      instrumentId        : Sample(4),
      currentTradingState : Sample(1) ]

EncodeTradingActionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.currentTradingState

DecodeTradingActionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(instrumentId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         instrumentId        |-> instrumentId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroTradingActionMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Best Bid And Ask Update Short Form Message: 35 bytes                    *)
(***************************************************************************)

BestBidAndAskUpdateShortFormMessage ==
    [ trackingNumber          : Sample(2),
      timestamp               : Sample(8),
      instrumentId            : Sample(4),
      quoteCondition          : Sample(1),
      bidMarketOrderSizeShort : Sample(2),
      bidPriceShort           : Sample(2),
      bidSizeShort            : Sample(2),
      bidCustSizeShort        : Sample(2),
      bidProcustSizeShort     : Sample(2),
      askMarketOrderSizeShort : Sample(2),
      askPriceShort           : Sample(2),
      askSizeShort            : Sample(2),
      askCustSizeShort        : Sample(2),
      askProcustSizeShort     : Sample(2) ]

EncodeBestBidAndAskUpdateShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.quoteCondition
        \o message.bidMarketOrderSizeShort
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.bidCustSizeShort
        \o message.bidProcustSizeShort
        \o message.askMarketOrderSizeShort
        \o message.askPriceShort
        \o message.askSizeShort
        \o message.askCustSizeShort
        \o message.askProcustSizeShort

DecodeBestBidAndAskUpdateShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(instrumentId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET bidMarketOrderSizeShort == ReadBytes(quoteCondition.rest, 2) IN IF ~bidMarketOrderSizeShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(bidMarketOrderSizeShort.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET bidCustSizeShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~bidCustSizeShort.ok THEN Fail ELSE
    LET bidProcustSizeShort == ReadBytes(bidCustSizeShort.rest, 2) IN IF ~bidProcustSizeShort.ok THEN Fail ELSE
    LET askMarketOrderSizeShort == ReadBytes(bidProcustSizeShort.rest, 2) IN IF ~askMarketOrderSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(askMarketOrderSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    LET askCustSizeShort == ReadBytes(askSizeShort.rest, 2) IN IF ~askCustSizeShort.ok THEN Fail ELSE
    LET askProcustSizeShort == ReadBytes(askCustSizeShort.rest, 2) IN IF ~askProcustSizeShort.ok THEN Fail ELSE
    Ok([ trackingNumber          |-> trackingNumber.value,
         timestamp               |-> timestamp.value,
         instrumentId            |-> instrumentId.value,
         quoteCondition          |-> quoteCondition.value,
         bidMarketOrderSizeShort |-> bidMarketOrderSizeShort.value,
         bidPriceShort           |-> bidPriceShort.value,
         bidSizeShort            |-> bidSizeShort.value,
         bidCustSizeShort        |-> bidCustSizeShort.value,
         bidProcustSizeShort     |-> bidProcustSizeShort.value,
         askMarketOrderSizeShort |-> askMarketOrderSizeShort.value,
         askPriceShort           |-> askPriceShort.value,
         askSizeShort            |-> askSizeShort.value,
         askCustSizeShort        |-> askCustSizeShort.value,
         askProcustSizeShort     |-> askProcustSizeShort.value ], askProcustSizeShort.rest)

ZeroBestBidAndAskUpdateShortFormMessage ==
    [ trackingNumber          |-> [i \in 1 .. 2 |-> 0],
      timestamp               |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      quoteCondition          |-> [i \in 1 .. 1 |-> 0],
      bidMarketOrderSizeShort |-> [i \in 1 .. 2 |-> 0],
      bidPriceShort           |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort            |-> [i \in 1 .. 2 |-> 0],
      bidCustSizeShort        |-> [i \in 1 .. 2 |-> 0],
      bidProcustSizeShort     |-> [i \in 1 .. 2 |-> 0],
      askMarketOrderSizeShort |-> [i \in 1 .. 2 |-> 0],
      askPriceShort           |-> [i \in 1 .. 2 |-> 0],
      askSizeShort            |-> [i \in 1 .. 2 |-> 0],
      askCustSizeShort        |-> [i \in 1 .. 2 |-> 0],
      askProcustSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* Best Bid And Ask Update Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidAndAskUpdateShortFormMessage ==
    { ZeroBestBidAndAskUpdateShortFormMessage }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.bidMarketOrderSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.bidCustSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.bidProcustSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.askMarketOrderSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.askCustSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateShortFormMessage EXCEPT !.askProcustSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Best Bid And Ask Update Long Form Message: 55 bytes                     *)
(***************************************************************************)

BestBidAndAskUpdateLongFormMessage ==
    [ trackingNumber         : Sample(2),
      timestamp              : Sample(8),
      instrumentId           : Sample(4),
      quoteCondition         : Sample(1),
      bidMarketOrderSizeLong : Sample(4),
      bidPriceLong           : Sample(4),
      bidSizeLong            : Sample(4),
      bidCustSizeLong        : Sample(4),
      bidProcustSizeLong     : Sample(4),
      askMarketOrderSizeLong : Sample(4),
      askPriceLong           : Sample(4),
      askSizeLong            : Sample(4),
      askCustSizeLong        : Sample(4),
      askProcustSizeLong     : Sample(4) ]

EncodeBestBidAndAskUpdateLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.quoteCondition
        \o message.bidMarketOrderSizeLong
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.bidCustSizeLong
        \o message.bidProcustSizeLong
        \o message.askMarketOrderSizeLong
        \o message.askPriceLong
        \o message.askSizeLong
        \o message.askCustSizeLong
        \o message.askProcustSizeLong

DecodeBestBidAndAskUpdateLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(instrumentId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET bidMarketOrderSizeLong == ReadBytes(quoteCondition.rest, 4) IN IF ~bidMarketOrderSizeLong.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(bidMarketOrderSizeLong.rest, 4) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET bidCustSizeLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~bidCustSizeLong.ok THEN Fail ELSE
    LET bidProcustSizeLong == ReadBytes(bidCustSizeLong.rest, 4) IN IF ~bidProcustSizeLong.ok THEN Fail ELSE
    LET askMarketOrderSizeLong == ReadBytes(bidProcustSizeLong.rest, 4) IN IF ~askMarketOrderSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(askMarketOrderSizeLong.rest, 4) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    LET askCustSizeLong == ReadBytes(askSizeLong.rest, 4) IN IF ~askCustSizeLong.ok THEN Fail ELSE
    LET askProcustSizeLong == ReadBytes(askCustSizeLong.rest, 4) IN IF ~askProcustSizeLong.ok THEN Fail ELSE
    Ok([ trackingNumber         |-> trackingNumber.value,
         timestamp              |-> timestamp.value,
         instrumentId           |-> instrumentId.value,
         quoteCondition         |-> quoteCondition.value,
         bidMarketOrderSizeLong |-> bidMarketOrderSizeLong.value,
         bidPriceLong           |-> bidPriceLong.value,
         bidSizeLong            |-> bidSizeLong.value,
         bidCustSizeLong        |-> bidCustSizeLong.value,
         bidProcustSizeLong     |-> bidProcustSizeLong.value,
         askMarketOrderSizeLong |-> askMarketOrderSizeLong.value,
         askPriceLong           |-> askPriceLong.value,
         askSizeLong            |-> askSizeLong.value,
         askCustSizeLong        |-> askCustSizeLong.value,
         askProcustSizeLong     |-> askProcustSizeLong.value ], askProcustSizeLong.rest)

ZeroBestBidAndAskUpdateLongFormMessage ==
    [ trackingNumber         |-> [i \in 1 .. 2 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      instrumentId           |-> [i \in 1 .. 4 |-> 0],
      quoteCondition         |-> [i \in 1 .. 1 |-> 0],
      bidMarketOrderSizeLong |-> [i \in 1 .. 4 |-> 0],
      bidPriceLong           |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong            |-> [i \in 1 .. 4 |-> 0],
      bidCustSizeLong        |-> [i \in 1 .. 4 |-> 0],
      bidProcustSizeLong     |-> [i \in 1 .. 4 |-> 0],
      askMarketOrderSizeLong |-> [i \in 1 .. 4 |-> 0],
      askPriceLong           |-> [i \in 1 .. 4 |-> 0],
      askSizeLong            |-> [i \in 1 .. 4 |-> 0],
      askCustSizeLong        |-> [i \in 1 .. 4 |-> 0],
      askProcustSizeLong     |-> [i \in 1 .. 4 |-> 0] ]

(* Best Bid And Ask Update Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidAndAskUpdateLongFormMessage ==
    { ZeroBestBidAndAskUpdateLongFormMessage }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.bidMarketOrderSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.bidCustSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.bidProcustSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.askMarketOrderSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.askPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.askCustSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidAndAskUpdateLongFormMessage EXCEPT !.askProcustSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Best Bid Or Ask Update Short Form Message: 25 bytes                     *)
(***************************************************************************)

BestBidOrAskUpdateShortFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      quoteCondition       : Sample(1),
      marketOrderSizeShort : Sample(2),
      priceShort           : Sample(2),
      sizeShort            : Sample(2),
      custSizeShort        : Sample(2),
      procustSizeShort     : Sample(2) ]

EncodeBestBidOrAskUpdateShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.quoteCondition
        \o message.marketOrderSizeShort
        \o message.priceShort
        \o message.sizeShort
        \o message.custSizeShort
        \o message.procustSizeShort

DecodeBestBidOrAskUpdateShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(instrumentId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET marketOrderSizeShort == ReadBytes(quoteCondition.rest, 2) IN IF ~marketOrderSizeShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(marketOrderSizeShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET sizeShort == ReadBytes(priceShort.rest, 2) IN IF ~sizeShort.ok THEN Fail ELSE
    LET custSizeShort == ReadBytes(sizeShort.rest, 2) IN IF ~custSizeShort.ok THEN Fail ELSE
    LET procustSizeShort == ReadBytes(custSizeShort.rest, 2) IN IF ~procustSizeShort.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         quoteCondition       |-> quoteCondition.value,
         marketOrderSizeShort |-> marketOrderSizeShort.value,
         priceShort           |-> priceShort.value,
         sizeShort            |-> sizeShort.value,
         custSizeShort        |-> custSizeShort.value,
         procustSizeShort     |-> procustSizeShort.value ], procustSizeShort.rest)

ZeroBestBidOrAskUpdateShortFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      quoteCondition       |-> [i \in 1 .. 1 |-> 0],
      marketOrderSizeShort |-> [i \in 1 .. 2 |-> 0],
      priceShort           |-> [i \in 1 .. 2 |-> 0],
      sizeShort            |-> [i \in 1 .. 2 |-> 0],
      custSizeShort        |-> [i \in 1 .. 2 |-> 0],
      procustSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* Best Bid Or Ask Update Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidOrAskUpdateShortFormMessage ==
    { ZeroBestBidOrAskUpdateShortFormMessage }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.marketOrderSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.sizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.custSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidOrAskUpdateShortFormMessage EXCEPT !.procustSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Best Bid Or Ask Update Long Form Message: 35 bytes                      *)
(***************************************************************************)

BestBidOrAskUpdateLongFormMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      instrumentId        : Sample(4),
      quoteCondition      : Sample(1),
      marketOrderSizeLong : Sample(4),
      priceLong           : Sample(4),
      sizeLong            : Sample(4),
      custSizeLong        : Sample(4),
      procustSizeLong     : Sample(4) ]

EncodeBestBidOrAskUpdateLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.quoteCondition
        \o message.marketOrderSizeLong
        \o message.priceLong
        \o message.sizeLong
        \o message.custSizeLong
        \o message.procustSizeLong

DecodeBestBidOrAskUpdateLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(instrumentId.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET marketOrderSizeLong == ReadBytes(quoteCondition.rest, 4) IN IF ~marketOrderSizeLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(marketOrderSizeLong.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET sizeLong == ReadBytes(priceLong.rest, 4) IN IF ~sizeLong.ok THEN Fail ELSE
    LET custSizeLong == ReadBytes(sizeLong.rest, 4) IN IF ~custSizeLong.ok THEN Fail ELSE
    LET procustSizeLong == ReadBytes(custSizeLong.rest, 4) IN IF ~procustSizeLong.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         instrumentId        |-> instrumentId.value,
         quoteCondition      |-> quoteCondition.value,
         marketOrderSizeLong |-> marketOrderSizeLong.value,
         priceLong           |-> priceLong.value,
         sizeLong            |-> sizeLong.value,
         custSizeLong        |-> custSizeLong.value,
         procustSizeLong     |-> procustSizeLong.value ], procustSizeLong.rest)

ZeroBestBidOrAskUpdateLongFormMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      quoteCondition      |-> [i \in 1 .. 1 |-> 0],
      marketOrderSizeLong |-> [i \in 1 .. 4 |-> 0],
      priceLong           |-> [i \in 1 .. 4 |-> 0],
      sizeLong            |-> [i \in 1 .. 4 |-> 0],
      custSizeLong        |-> [i \in 1 .. 4 |-> 0],
      procustSizeLong     |-> [i \in 1 .. 4 |-> 0] ]

(* Best Bid Or Ask Update Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidOrAskUpdateLongFormMessage ==
    { ZeroBestBidOrAskUpdateLongFormMessage }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.marketOrderSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.sizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.custSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOrAskUpdateLongFormMessage EXCEPT !.procustSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Report Message: 27 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      instrumentId   : Sample(4),
      crossId        : Sample(4),
      tradeCondition : Sample(1),
      priceLong      : Sample(4),
      volume         : Sample(4) ]

EncodeTradeReportMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.crossId
        \o message.tradeCondition
        \o message.priceLong
        \o message.volume

DecodeTradeReportMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET crossId == ReadBytes(instrumentId.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(crossId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET priceLong == ReadBytes(tradeCondition.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volume == ReadBytes(priceLong.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         crossId        |-> crossId.value,
         tradeCondition |-> tradeCondition.value,
         priceLong      |-> priceLong.value,
         volume         |-> volume.value ], volume.rest)

ZeroTradeReportMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      crossId        |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0],
      priceLong      |-> [i \in 1 .. 4 |-> 0],
      volume         |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Broken Trade Report Message: 26 bytes                                   *)
(***************************************************************************)

BrokenTradeReportMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(8),
      instrumentId    : Sample(4),
      originalCrossId : Sample(4),
      originalPrice   : Sample(4),
      originalVolume  : Sample(4) ]

EncodeBrokenTradeReportMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.originalCrossId
        \o message.originalPrice
        \o message.originalVolume

DecodeBrokenTradeReportMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET originalCrossId == ReadBytes(instrumentId.rest, 4) IN IF ~originalCrossId.ok THEN Fail ELSE
    LET originalPrice == ReadBytes(originalCrossId.rest, 4) IN IF ~originalPrice.ok THEN Fail ELSE
    LET originalVolume == ReadBytes(originalPrice.rest, 4) IN IF ~originalVolume.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         instrumentId    |-> instrumentId.value,
         originalCrossId |-> originalCrossId.value,
         originalPrice   |-> originalPrice.value,
         originalVolume  |-> originalVolume.value ], originalVolume.rest)

ZeroBrokenTradeReportMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      originalCrossId |-> [i \in 1 .. 4 |-> 0],
      originalPrice   |-> [i \in 1 .. 4 |-> 0],
      originalVolume  |-> [i \in 1 .. 4 |-> 0] ]

(* Broken Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeReportMessage ==
    { ZeroBrokenTradeReportMessage }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.originalCrossId = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.originalPrice = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeReportMessage EXCEPT !.originalVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Udp Payload, selected by Message Type                                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
DerivativeDirectoryMessageCode == 82  \* "R"
TradingActionMessageCode == 72  \* "H"
BestBidAndAskUpdateShortFormMessageCode == 113  \* "q"
BestBidAndAskUpdateLongFormMessageCode == 81  \* "Q"
BestBidOrAskUpdateShortFormMessageCode == 98  \* "b"
BestBidOrAskUpdateLongFormMessageCode == 66  \* "B"
TradeReportMessageCode == 84  \* "T"
BrokenTradeReportMessageCode == 88  \* "X"

UdpPayload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {DerivativeDirectoryMessageCode}, body : DerivativeDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {BestBidAndAskUpdateShortFormMessageCode}, body : BestBidAndAskUpdateShortFormMessage ]
        \cup [ tag : {BestBidAndAskUpdateLongFormMessageCode}, body : BestBidAndAskUpdateLongFormMessage ]
        \cup [ tag : {BestBidOrAskUpdateShortFormMessageCode}, body : BestBidOrAskUpdateShortFormMessage ]
        \cup [ tag : {BestBidOrAskUpdateLongFormMessageCode}, body : BestBidOrAskUpdateLongFormMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {BrokenTradeReportMessageCode}, body : BrokenTradeReportMessage ]

EncodeUdpPayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = DerivativeDirectoryMessageCode -> EncodeDerivativeDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = BestBidAndAskUpdateShortFormMessageCode -> EncodeBestBidAndAskUpdateShortFormMessage(message.body)
      [] message.tag = BestBidAndAskUpdateLongFormMessageCode -> EncodeBestBidAndAskUpdateLongFormMessage(message.body)
      [] message.tag = BestBidOrAskUpdateShortFormMessageCode -> EncodeBestBidOrAskUpdateShortFormMessage(message.body)
      [] message.tag = BestBidOrAskUpdateLongFormMessageCode -> EncodeBestBidOrAskUpdateLongFormMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = BrokenTradeReportMessageCode -> EncodeBrokenTradeReportMessage(message.body)

DecodeUdpPayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = DerivativeDirectoryMessageCode -> DecodeDerivativeDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = BestBidAndAskUpdateShortFormMessageCode -> DecodeBestBidAndAskUpdateShortFormMessage(bytes)
              [] tag = BestBidAndAskUpdateLongFormMessageCode -> DecodeBestBidAndAskUpdateLongFormMessage(bytes)
              [] tag = BestBidOrAskUpdateShortFormMessageCode -> DecodeBestBidOrAskUpdateShortFormMessage(bytes)
              [] tag = BestBidOrAskUpdateLongFormMessageCode -> DecodeBestBidOrAskUpdateLongFormMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = BrokenTradeReportMessageCode -> DecodeBrokenTradeReportMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUdpPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Udp Payload in turn, at the values the message it names is checked at *)
CheckedUdpPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> DerivativeDirectoryMessageCode, body |-> one] : one \in CheckedDerivativeDirectoryMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> BestBidAndAskUpdateShortFormMessageCode, body |-> one] : one \in CheckedBestBidAndAskUpdateShortFormMessage }
        \cup { [tag |-> BestBidAndAskUpdateLongFormMessageCode, body |-> one] : one \in CheckedBestBidAndAskUpdateLongFormMessage }
        \cup { [tag |-> BestBidOrAskUpdateShortFormMessageCode, body |-> one] : one \in CheckedBestBidOrAskUpdateShortFormMessage }
        \cup { [tag |-> BestBidOrAskUpdateLongFormMessageCode, body |-> one] : one \in CheckedBestBidOrAskUpdateLongFormMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> BrokenTradeReportMessageCode, body |-> one] : one \in CheckedBrokenTradeReportMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ udpPayload : UdpPayload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.udpPayload.tag, 1)
        \o EncodeUdpPayload(message.udpPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET udpPayload == DecodeUdpPayload(messageType.value, messageType.rest) IN IF ~udpPayload.ok THEN Fail ELSE
    Ok([ udpPayload |-> udpPayload.value ], udpPayload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ udpPayload |-> ZeroUdpPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.udpPayload = one] : one \in CheckedUdpPayload }

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
    { [ZeroMessage EXCEPT !.udpPayload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> DerivativeDirectoryMessageCode, body |-> ZeroDerivativeDirectoryMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> TradingActionMessageCode, body |-> ZeroTradingActionMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> BestBidAndAskUpdateShortFormMessageCode, body |-> ZeroBestBidAndAskUpdateShortFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> BestBidAndAskUpdateLongFormMessageCode, body |-> ZeroBestBidAndAskUpdateLongFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> BestBidOrAskUpdateShortFormMessageCode, body |-> ZeroBestBidOrAskUpdateShortFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> BestBidOrAskUpdateLongFormMessageCode, body |-> ZeroBestBidOrAskUpdateLongFormMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> BrokenTradeReportMessageCode, body |-> ZeroBrokenTradeReportMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ udpSession        : Sample(10),
      udpSequenceNumber : Sample(8),
      message           : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.udpSession
        \o message.udpSequenceNumber
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET udpSession == ReadBytes(bytes, 10) IN IF ~udpSession.ok THEN Fail ELSE
    LET udpSequenceNumber == ReadBytes(udpSession.rest, 8) IN IF ~udpSequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(udpSequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ udpSession        |-> udpSession.value,
         udpSequenceNumber |-> udpSequenceNumber.value,
         message           |-> message.value ], message.rest)

ZeroPacket ==
    [ udpSession        |-> [i \in 1 .. 10 |-> 0],
      udpSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message           |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.udpSession = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.udpSequenceNumber = one] : one \in Sample(8) }
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
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Derivative Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativeDirectoryMessage ==
    \A message \in CheckedDerivativeDirectoryMessage :
        LET read == DecodeDerivativeDirectoryMessage(EncodeDerivativeDirectoryMessage(message))
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

(* Every Best Bid And Ask Update Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidAndAskUpdateShortFormMessage ==
    \A message \in CheckedBestBidAndAskUpdateShortFormMessage :
        LET read == DecodeBestBidAndAskUpdateShortFormMessage(EncodeBestBidAndAskUpdateShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Bid And Ask Update Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidAndAskUpdateLongFormMessage ==
    \A message \in CheckedBestBidAndAskUpdateLongFormMessage :
        LET read == DecodeBestBidAndAskUpdateLongFormMessage(EncodeBestBidAndAskUpdateLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Bid Or Ask Update Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidOrAskUpdateShortFormMessage ==
    \A message \in CheckedBestBidOrAskUpdateShortFormMessage :
        LET read == DecodeBestBidOrAskUpdateShortFormMessage(EncodeBestBidOrAskUpdateShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Bid Or Ask Update Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidOrAskUpdateLongFormMessage ==
    \A message \in CheckedBestBidOrAskUpdateLongFormMessage :
        LET read == DecodeBestBidOrAskUpdateLongFormMessage(EncodeBestBidOrAskUpdateLongFormMessage(message))
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

(* Every Broken Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeReportMessage ==
    \A message \in CheckedBrokenTradeReportMessage :
        LET read == DecodeBrokenTradeReportMessage(EncodeBrokenTradeReportMessage(message))
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

(* A Udp Payload is selected by the Message Type it is written under *)
SelectsUdpPayload ==
    \A message \in UdpPayload :
        LET read == DecodeUdpPayload(message.tag, EncodeUdpPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in Message :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
