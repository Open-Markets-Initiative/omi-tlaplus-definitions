----------------- MODULE NordicEquities_TotalView_v3_04_X ------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nordic Equity TotalView v3.04.X                                *)
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
(*                                                                         *)
(* Note: Note Codes Bit Field 1 is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Note Codes Bit Field 2 is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Note Codes Bit Field 3 is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Note Codes Bit Field 4 is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Note Codes Bit Field 5 is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Note Codes Bit Field 6 is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Note Codes Bit Field 7 is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Note Codes Bit Field 8 is a bit field set, checked as its 1 byte  *)
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
    [ timestamp      : Sample(8),
      trackingNumber : Sample(2),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET eventCode == ReadBytes(trackingNumber.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         trackingNumber |-> trackingNumber.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Trading Action Message: 20 bytes                             *)
(***************************************************************************)

OrderBookTradingActionMessage ==
    [ timestamp      : Sample(8),
      trackingNumber : Sample(2),
      orderBook      : Sample(4),
      symbolState    : Sample(1),
      extension      : Sample(1),
      reason         : Sample(4) ]

EncodeOrderBookTradingActionMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderBook
        \o message.symbolState
        \o message.extension
        \o message.reason

DecodeOrderBookTradingActionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderBook == ReadBytes(trackingNumber.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET symbolState == ReadBytes(orderBook.rest, 1) IN IF ~symbolState.ok THEN Fail ELSE
    LET extension == ReadBytes(symbolState.rest, 1) IN IF ~extension.ok THEN Fail ELSE
    LET reason == ReadBytes(extension.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         trackingNumber |-> trackingNumber.value,
         orderBook      |-> orderBook.value,
         symbolState    |-> symbolState.value,
         extension      |-> extension.value,
         reason         |-> reason.value ], reason.rest)

ZeroOrderBookTradingActionMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      orderBook      |-> [i \in 1 .. 4 |-> 0],
      symbolState    |-> [i \in 1 .. 1 |-> 0],
      extension      |-> [i \in 1 .. 1 |-> 0],
      reason         |-> [i \in 1 .. 4 |-> 0] ]

(* Order Book Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookTradingActionMessage ==
    { ZeroOrderBookTradingActionMessage }
        \cup { [ZeroOrderBookTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookTradingActionMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookTradingActionMessage EXCEPT !.symbolState = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookTradingActionMessage EXCEPT !.extension = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Book Directory Message: 100 bytes                                 *)
(***************************************************************************)

OrderBookDirectoryMessage ==
    [ timestamp                                         : Sample(8),
      trackingNumber                                    : Sample(2),
      orderBook                                         : Sample(4),
      symbol                                            : Sample(16),
      isin                                              : Sample(12),
      financialProduct                                  : Sample(1),
      tradingCurrency                                   : Sample(3),
      mic                                               : Sample(4),
      marketSegmentId                                   : Sample(2),
      noteCodesBitField1                                : Sample(1),
      noteCodesBitField2                                : Sample(1),
      noteCodesBitField3                                : Sample(1),
      noteCodesBitField4                                : Sample(1),
      noteCodesBitField5                                : Sample(1),
      noteCodesBitField6                                : Sample(1),
      noteCodesBitField7                                : Sample(1),
      noteCodesBitField8                                : Sample(1),
      roundLotSize                                      : Sample(4),
      nordicMidMic                                      : Sample(4),
      aodMic                                            : Sample(4),
      notationOfQty                                     : Sample(4),
      notionalAmount                                    : Sample(8),
      currency                                          : Sample(3),
      priceNotation                                     : Sample(1),
      multiplierForCalculatingQuantityInMeasurementUnit : Sample(8),
      pureStreamMic                                     : Sample(4) ]

EncodeOrderBookDirectoryMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderBook
        \o message.symbol
        \o message.isin
        \o message.financialProduct
        \o message.tradingCurrency
        \o message.mic
        \o message.marketSegmentId
        \o message.noteCodesBitField1
        \o message.noteCodesBitField2
        \o message.noteCodesBitField3
        \o message.noteCodesBitField4
        \o message.noteCodesBitField5
        \o message.noteCodesBitField6
        \o message.noteCodesBitField7
        \o message.noteCodesBitField8
        \o message.roundLotSize
        \o message.nordicMidMic
        \o message.aodMic
        \o message.notationOfQty
        \o message.notionalAmount
        \o message.currency
        \o message.priceNotation
        \o message.multiplierForCalculatingQuantityInMeasurementUnit
        \o message.pureStreamMic

DecodeOrderBookDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderBook == ReadBytes(trackingNumber.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBook.rest, 16) IN IF ~symbol.ok THEN Fail ELSE
    LET isin == ReadBytes(symbol.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(isin.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(financialProduct.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET mic == ReadBytes(tradingCurrency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(mic.rest, 2) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET noteCodesBitField1 == ReadBytes(marketSegmentId.rest, 1) IN IF ~noteCodesBitField1.ok THEN Fail ELSE
    LET noteCodesBitField2 == ReadBytes(noteCodesBitField1.rest, 1) IN IF ~noteCodesBitField2.ok THEN Fail ELSE
    LET noteCodesBitField3 == ReadBytes(noteCodesBitField2.rest, 1) IN IF ~noteCodesBitField3.ok THEN Fail ELSE
    LET noteCodesBitField4 == ReadBytes(noteCodesBitField3.rest, 1) IN IF ~noteCodesBitField4.ok THEN Fail ELSE
    LET noteCodesBitField5 == ReadBytes(noteCodesBitField4.rest, 1) IN IF ~noteCodesBitField5.ok THEN Fail ELSE
    LET noteCodesBitField6 == ReadBytes(noteCodesBitField5.rest, 1) IN IF ~noteCodesBitField6.ok THEN Fail ELSE
    LET noteCodesBitField7 == ReadBytes(noteCodesBitField6.rest, 1) IN IF ~noteCodesBitField7.ok THEN Fail ELSE
    LET noteCodesBitField8 == ReadBytes(noteCodesBitField7.rest, 1) IN IF ~noteCodesBitField8.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(noteCodesBitField8.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET nordicMidMic == ReadBytes(roundLotSize.rest, 4) IN IF ~nordicMidMic.ok THEN Fail ELSE
    LET aodMic == ReadBytes(nordicMidMic.rest, 4) IN IF ~aodMic.ok THEN Fail ELSE
    LET notationOfQty == ReadBytes(aodMic.rest, 4) IN IF ~notationOfQty.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(notationOfQty.rest, 8) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET currency == ReadBytes(notionalAmount.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(currency.rest, 1) IN IF ~priceNotation.ok THEN Fail ELSE
    LET multiplierForCalculatingQuantityInMeasurementUnit == ReadBytes(priceNotation.rest, 8) IN IF ~multiplierForCalculatingQuantityInMeasurementUnit.ok THEN Fail ELSE
    LET pureStreamMic == ReadBytes(multiplierForCalculatingQuantityInMeasurementUnit.rest, 4) IN IF ~pureStreamMic.ok THEN Fail ELSE
    Ok([ timestamp                                         |-> timestamp.value,
         trackingNumber                                    |-> trackingNumber.value,
         orderBook                                         |-> orderBook.value,
         symbol                                            |-> symbol.value,
         isin                                              |-> isin.value,
         financialProduct                                  |-> financialProduct.value,
         tradingCurrency                                   |-> tradingCurrency.value,
         mic                                               |-> mic.value,
         marketSegmentId                                   |-> marketSegmentId.value,
         noteCodesBitField1                                |-> noteCodesBitField1.value,
         noteCodesBitField2                                |-> noteCodesBitField2.value,
         noteCodesBitField3                                |-> noteCodesBitField3.value,
         noteCodesBitField4                                |-> noteCodesBitField4.value,
         noteCodesBitField5                                |-> noteCodesBitField5.value,
         noteCodesBitField6                                |-> noteCodesBitField6.value,
         noteCodesBitField7                                |-> noteCodesBitField7.value,
         noteCodesBitField8                                |-> noteCodesBitField8.value,
         roundLotSize                                      |-> roundLotSize.value,
         nordicMidMic                                      |-> nordicMidMic.value,
         aodMic                                            |-> aodMic.value,
         notationOfQty                                     |-> notationOfQty.value,
         notionalAmount                                    |-> notionalAmount.value,
         currency                                          |-> currency.value,
         priceNotation                                     |-> priceNotation.value,
         multiplierForCalculatingQuantityInMeasurementUnit |-> multiplierForCalculatingQuantityInMeasurementUnit.value,
         pureStreamMic                                     |-> pureStreamMic.value ], pureStreamMic.rest)

ZeroOrderBookDirectoryMessage ==
    [ timestamp                                         |-> [i \in 1 .. 8 |-> 0],
      trackingNumber                                    |-> [i \in 1 .. 2 |-> 0],
      orderBook                                         |-> [i \in 1 .. 4 |-> 0],
      symbol                                            |-> [i \in 1 .. 16 |-> 0],
      isin                                              |-> [i \in 1 .. 12 |-> 0],
      financialProduct                                  |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                                   |-> [i \in 1 .. 3 |-> 0],
      mic                                               |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                                   |-> [i \in 1 .. 2 |-> 0],
      noteCodesBitField1                                |-> [i \in 1 .. 1 |-> 0],
      noteCodesBitField2                                |-> [i \in 1 .. 1 |-> 0],
      noteCodesBitField3                                |-> [i \in 1 .. 1 |-> 0],
      noteCodesBitField4                                |-> [i \in 1 .. 1 |-> 0],
      noteCodesBitField5                                |-> [i \in 1 .. 1 |-> 0],
      noteCodesBitField6                                |-> [i \in 1 .. 1 |-> 0],
      noteCodesBitField7                                |-> [i \in 1 .. 1 |-> 0],
      noteCodesBitField8                                |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                                      |-> [i \in 1 .. 4 |-> 0],
      nordicMidMic                                      |-> [i \in 1 .. 4 |-> 0],
      aodMic                                            |-> [i \in 1 .. 4 |-> 0],
      notationOfQty                                     |-> [i \in 1 .. 4 |-> 0],
      notionalAmount                                    |-> [i \in 1 .. 8 |-> 0],
      currency                                          |-> [i \in 1 .. 3 |-> 0],
      priceNotation                                     |-> [i \in 1 .. 1 |-> 0],
      multiplierForCalculatingQuantityInMeasurementUnit |-> [i \in 1 .. 8 |-> 0],
      pureStreamMic                                     |-> [i \in 1 .. 4 |-> 0] ]

(* Order Book Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookDirectoryMessage ==
    { ZeroOrderBookDirectoryMessage }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(16) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.marketSegmentId = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.noteCodesBitField1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.noteCodesBitField2 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.noteCodesBitField3 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.noteCodesBitField4 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.noteCodesBitField5 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.noteCodesBitField6 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.noteCodesBitField7 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.noteCodesBitField8 = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.nordicMidMic = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.aodMic = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.notationOfQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.notionalAmount = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.priceNotation = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.multiplierForCalculatingQuantityInMeasurementUnit = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.pureStreamMic = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Message: 31 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ timestamp            : Sample(8),
      trackingNumber       : Sample(2),
      orderReferenceNumber : Sample(8),
      buySellIndicator     : Sample(1),
      quantity             : Sample(4),
      orderBook            : Sample(4),
      price                : Sample(4) ]

EncodeAddOrderMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderReferenceNumber
        \o message.buySellIndicator
        \o message.quantity
        \o message.orderBook
        \o message.price

DecodeAddOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(trackingNumber.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(buySellIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderBook == ReadBytes(quantity.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET price == ReadBytes(orderBook.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         trackingNumber       |-> trackingNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         quantity             |-> quantity.value,
         orderBook            |-> orderBook.value,
         price                |-> price.value ], price.rest)

ZeroAddOrderMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      orderBook            |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Mpid Attribution Message: 35 bytes                            *)
(***************************************************************************)

AddOrderMpidAttributionMessage ==
    [ timestamp            : Sample(8),
      trackingNumber       : Sample(2),
      orderReferenceNumber : Sample(8),
      buySellIndicator     : Sample(1),
      quantity             : Sample(4),
      orderBook            : Sample(4),
      price                : Sample(4),
      attribution          : Sample(4) ]

EncodeAddOrderMpidAttributionMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderReferenceNumber
        \o message.buySellIndicator
        \o message.quantity
        \o message.orderBook
        \o message.price
        \o message.attribution

DecodeAddOrderMpidAttributionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(trackingNumber.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(buySellIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderBook == ReadBytes(quantity.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET price == ReadBytes(orderBook.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET attribution == ReadBytes(price.rest, 4) IN IF ~attribution.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         trackingNumber       |-> trackingNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         quantity             |-> quantity.value,
         orderBook            |-> orderBook.value,
         price                |-> price.value,
         attribution          |-> attribution.value ], attribution.rest)

ZeroAddOrderMpidAttributionMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      orderBook            |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      attribution          |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Mpid Attribution Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMpidAttributionMessage ==
    { ZeroAddOrderMpidAttributionMessage }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.attribution = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 34 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp            : Sample(8),
      trackingNumber       : Sample(2),
      orderReferenceNumber : Sample(8),
      executedQuantity     : Sample(4),
      matchNumber          : Sample(4),
      mpid                 : Sample(4),
      mpidCounterparty     : Sample(4) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderReferenceNumber
        \o message.executedQuantity
        \o message.matchNumber
        \o message.mpid
        \o message.mpidCounterparty

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(trackingNumber.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedQuantity.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchNumber.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET mpidCounterparty == ReadBytes(mpid.rest, 4) IN IF ~mpidCounterparty.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         trackingNumber       |-> trackingNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedQuantity     |-> executedQuantity.value,
         matchNumber          |-> matchNumber.value,
         mpid                 |-> mpid.value,
         mpidCounterparty     |-> mpidCounterparty.value ], mpidCounterparty.rest)

ZeroOrderExecutedMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedQuantity     |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      mpidCounterparty     |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.mpidCounterparty = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed With Price Message: 39 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ timestamp            : Sample(8),
      trackingNumber       : Sample(2),
      orderReferenceNumber : Sample(8),
      executedQuantity     : Sample(4),
      matchNumber          : Sample(4),
      printable            : Sample(1),
      tradePrice           : Sample(4),
      mpidOwner            : Sample(4),
      mpidCounterparty     : Sample(4) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderReferenceNumber
        \o message.executedQuantity
        \o message.matchNumber
        \o message.printable
        \o message.tradePrice
        \o message.mpidOwner
        \o message.mpidCounterparty

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(trackingNumber.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedQuantity.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(printable.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET mpidOwner == ReadBytes(tradePrice.rest, 4) IN IF ~mpidOwner.ok THEN Fail ELSE
    LET mpidCounterparty == ReadBytes(mpidOwner.rest, 4) IN IF ~mpidCounterparty.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         trackingNumber       |-> trackingNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedQuantity     |-> executedQuantity.value,
         matchNumber          |-> matchNumber.value,
         printable            |-> printable.value,
         tradePrice           |-> tradePrice.value,
         mpidOwner            |-> mpidOwner.value,
         mpidCounterparty     |-> mpidCounterparty.value ], mpidCounterparty.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedQuantity     |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0],
      tradePrice           |-> [i \in 1 .. 4 |-> 0],
      mpidOwner            |-> [i \in 1 .. 4 |-> 0],
      mpidCounterparty     |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.mpidOwner = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.mpidCounterparty = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 22 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ timestamp            : Sample(8),
      trackingNumber       : Sample(2),
      orderReferenceNumber : Sample(8),
      canceledQuantity     : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderReferenceNumber
        \o message.canceledQuantity

DecodeOrderCancelMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(trackingNumber.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET canceledQuantity == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~canceledQuantity.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         trackingNumber       |-> trackingNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         canceledQuantity     |-> canceledQuantity.value ], canceledQuantity.rest)

ZeroOrderCancelMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      canceledQuantity     |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.canceledQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Delete Message: 18 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ timestamp            : Sample(8),
      trackingNumber       : Sample(2),
      orderReferenceNumber : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderReferenceNumber

DecodeOrderDeleteMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(trackingNumber.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         trackingNumber       |-> trackingNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroOrderDeleteMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Book Flush Message: 14 bytes                                      *)
(***************************************************************************)

OrderBookFlushMessage ==
    [ timestamp      : Sample(8),
      trackingNumber : Sample(2),
      orderBook      : Sample(4) ]

EncodeOrderBookFlushMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderBook

DecodeOrderBookFlushMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderBook == ReadBytes(trackingNumber.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         trackingNumber |-> trackingNumber.value,
         orderBook      |-> orderBook.value ], orderBook.rest)

ZeroOrderBookFlushMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      orderBook      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Book Flush Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookFlushMessage ==
    { ZeroOrderBookFlushMessage }
        \cup { [ZeroOrderBookFlushMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookFlushMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookFlushMessage EXCEPT !.orderBook = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Replace Message: 34 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ timestamp                    : Sample(8),
      trackingNumber               : Sample(2),
      originalOrderReferenceNumber : Sample(8),
      newOrderReferenceNumber      : Sample(8),
      quantity                     : Sample(4),
      price                        : Sample(4) ]

EncodeOrderReplaceMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.originalOrderReferenceNumber
        \o message.newOrderReferenceNumber
        \o message.quantity
        \o message.price

DecodeOrderReplaceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET originalOrderReferenceNumber == ReadBytes(trackingNumber.rest, 8) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET newOrderReferenceNumber == ReadBytes(originalOrderReferenceNumber.rest, 8) IN IF ~newOrderReferenceNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(newOrderReferenceNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         trackingNumber               |-> trackingNumber.value,
         originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         newOrderReferenceNumber      |-> newOrderReferenceNumber.value,
         quantity                     |-> quantity.value,
         price                        |-> price.value ], price.rest)

ZeroOrderReplaceMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      trackingNumber               |-> [i \in 1 .. 2 |-> 0],
      originalOrderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newOrderReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      quantity                     |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Message: 43 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timestamp            : Sample(8),
      trackingNumber       : Sample(2),
      orderReferenceNumber : Sample(8),
      tradeType            : Sample(1),
      quantity             : Sample(4),
      orderBook            : Sample(4),
      matchNumber          : Sample(4),
      tradePrice           : Sample(4),
      participantIdBuyer   : Sample(4),
      participantIdSeller  : Sample(4) ]

EncodeTradeMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderReferenceNumber
        \o message.tradeType
        \o message.quantity
        \o message.orderBook
        \o message.matchNumber
        \o message.tradePrice
        \o message.participantIdBuyer
        \o message.participantIdSeller

DecodeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(trackingNumber.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET tradeType == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeType.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderBook == ReadBytes(quantity.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(orderBook.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(matchNumber.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET participantIdBuyer == ReadBytes(tradePrice.rest, 4) IN IF ~participantIdBuyer.ok THEN Fail ELSE
    LET participantIdSeller == ReadBytes(participantIdBuyer.rest, 4) IN IF ~participantIdSeller.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         trackingNumber       |-> trackingNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         tradeType            |-> tradeType.value,
         quantity             |-> quantity.value,
         orderBook            |-> orderBook.value,
         matchNumber          |-> matchNumber.value,
         tradePrice           |-> tradePrice.value,
         participantIdBuyer   |-> participantIdBuyer.value,
         participantIdSeller  |-> participantIdSeller.value ], participantIdSeller.rest)

ZeroTradeMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      tradeType            |-> [i \in 1 .. 1 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      orderBook            |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      tradePrice           |-> [i \in 1 .. 4 |-> 0],
      participantIdBuyer   |-> [i \in 1 .. 4 |-> 0],
      participantIdSeller  |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.participantIdBuyer = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.participantIdSeller = one] : one \in Sample(4) }

(***************************************************************************)
(* Cross Trade Message: 31 bytes                                           *)
(***************************************************************************)

CrossTradeMessage ==
    [ timestamp      : Sample(8),
      trackingNumber : Sample(2),
      quantity       : Sample(4),
      orderBook      : Sample(4),
      crossPrice     : Sample(4),
      matchNumber    : Sample(4),
      crossType      : Sample(1),
      numberOfTrades : Sample(4) ]

EncodeCrossTradeMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.quantity
        \o message.orderBook
        \o message.crossPrice
        \o message.matchNumber
        \o message.crossType
        \o message.numberOfTrades

DecodeCrossTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(trackingNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderBook == ReadBytes(quantity.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET crossPrice == ReadBytes(orderBook.rest, 4) IN IF ~crossPrice.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossPrice.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET crossType == ReadBytes(matchNumber.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET numberOfTrades == ReadBytes(crossType.rest, 4) IN IF ~numberOfTrades.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         trackingNumber |-> trackingNumber.value,
         quantity       |-> quantity.value,
         orderBook      |-> orderBook.value,
         crossPrice     |-> crossPrice.value,
         matchNumber    |-> matchNumber.value,
         crossType      |-> crossType.value,
         numberOfTrades |-> numberOfTrades.value ], numberOfTrades.rest)

ZeroCrossTradeMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0],
      orderBook      |-> [i \in 1 .. 4 |-> 0],
      crossPrice     |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0],
      crossType      |-> [i \in 1 .. 1 |-> 0],
      numberOfTrades |-> [i \in 1 .. 4 |-> 0] ]

(* Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossTradeMessage ==
    { ZeroCrossTradeMessage }
        \cup { [ZeroCrossTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossPrice = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.numberOfTrades = one] : one \in Sample(4) }

(***************************************************************************)
(* Broken Trade Message: 14 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestamp      : Sample(8),
      trackingNumber : Sample(2),
      matchNumber    : Sample(4) ]

EncodeBrokenTradeMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.matchNumber

DecodeBrokenTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(trackingNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         trackingNumber |-> trackingNumber.value,
         matchNumber    |-> matchNumber.value ], matchNumber.rest)

ZeroBrokenTradeMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Noii Message: 60 bytes                                                  *)
(***************************************************************************)

NoiiMessage ==
    [ timestamp          : Sample(8),
      trackingNumber     : Sample(2),
      pairedQuantity     : Sample(8),
      imbalanceQuantity  : Sample(8),
      imbalanceDirection : Sample(1),
      orderBook          : Sample(4),
      equilibriumPrice   : Sample(4),
      crossType          : Sample(1),
      bestBidPrice       : Sample(4),
      bestBidQuantity    : Sample(8),
      bestAskPrice       : Sample(4),
      bestAskQuantity    : Sample(8) ]

EncodeNoiiMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.pairedQuantity
        \o message.imbalanceQuantity
        \o message.imbalanceDirection
        \o message.orderBook
        \o message.equilibriumPrice
        \o message.crossType
        \o message.bestBidPrice
        \o message.bestBidQuantity
        \o message.bestAskPrice
        \o message.bestAskQuantity

DecodeNoiiMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET pairedQuantity == ReadBytes(trackingNumber.rest, 8) IN IF ~pairedQuantity.ok THEN Fail ELSE
    LET imbalanceQuantity == ReadBytes(pairedQuantity.rest, 8) IN IF ~imbalanceQuantity.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(imbalanceQuantity.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET orderBook == ReadBytes(imbalanceDirection.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(orderBook.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(equilibriumPrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(crossType.rest, 4) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestBidQuantity == ReadBytes(bestBidPrice.rest, 8) IN IF ~bestBidQuantity.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestBidQuantity.rest, 4) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestAskQuantity == ReadBytes(bestAskPrice.rest, 8) IN IF ~bestAskQuantity.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         trackingNumber     |-> trackingNumber.value,
         pairedQuantity     |-> pairedQuantity.value,
         imbalanceQuantity  |-> imbalanceQuantity.value,
         imbalanceDirection |-> imbalanceDirection.value,
         orderBook          |-> orderBook.value,
         equilibriumPrice   |-> equilibriumPrice.value,
         crossType          |-> crossType.value,
         bestBidPrice       |-> bestBidPrice.value,
         bestBidQuantity    |-> bestBidQuantity.value,
         bestAskPrice       |-> bestAskPrice.value,
         bestAskQuantity    |-> bestAskQuantity.value ], bestAskQuantity.rest)

ZeroNoiiMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      pairedQuantity     |-> [i \in 1 .. 8 |-> 0],
      imbalanceQuantity  |-> [i \in 1 .. 8 |-> 0],
      imbalanceDirection |-> [i \in 1 .. 1 |-> 0],
      orderBook          |-> [i \in 1 .. 4 |-> 0],
      equilibriumPrice   |-> [i \in 1 .. 4 |-> 0],
      crossType          |-> [i \in 1 .. 1 |-> 0],
      bestBidPrice       |-> [i \in 1 .. 4 |-> 0],
      bestBidQuantity    |-> [i \in 1 .. 8 |-> 0],
      bestAskPrice       |-> [i \in 1 .. 4 |-> 0],
      bestAskQuantity    |-> [i \in 1 .. 8 |-> 0] ]

(* Noii Message at zero, then each field in turn at the values it is checked at *)
CheckedNoiiMessage ==
    { ZeroNoiiMessage }
        \cup { [ZeroNoiiMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNoiiMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroNoiiMessage EXCEPT !.pairedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroNoiiMessage EXCEPT !.imbalanceQuantity = one] : one \in Sample(8) }
        \cup { [ZeroNoiiMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNoiiMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNoiiMessage EXCEPT !.bestBidPrice = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.bestBidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroNoiiMessage EXCEPT !.bestAskPrice = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.bestAskQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Moii Message: 28 bytes                                                  *)
(***************************************************************************)

MoiiMessage ==
    [ timestamp        : Sample(8),
      trackingNumber   : Sample(2),
      pairedQuantity   : Sample(8),
      orderBook        : Sample(4),
      equilibriumPrice : Sample(4),
      crossType        : Sample(1),
      crossLevel       : Sample(1) ]

EncodeMoiiMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.pairedQuantity
        \o message.orderBook
        \o message.equilibriumPrice
        \o message.crossType
        \o message.crossLevel

DecodeMoiiMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET pairedQuantity == ReadBytes(trackingNumber.rest, 8) IN IF ~pairedQuantity.ok THEN Fail ELSE
    LET orderBook == ReadBytes(pairedQuantity.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(orderBook.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(equilibriumPrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET crossLevel == ReadBytes(crossType.rest, 1) IN IF ~crossLevel.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         trackingNumber   |-> trackingNumber.value,
         pairedQuantity   |-> pairedQuantity.value,
         orderBook        |-> orderBook.value,
         equilibriumPrice |-> equilibriumPrice.value,
         crossType        |-> crossType.value,
         crossLevel       |-> crossLevel.value ], crossLevel.rest)

ZeroMoiiMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      trackingNumber   |-> [i \in 1 .. 2 |-> 0],
      pairedQuantity   |-> [i \in 1 .. 8 |-> 0],
      orderBook        |-> [i \in 1 .. 4 |-> 0],
      equilibriumPrice |-> [i \in 1 .. 4 |-> 0],
      crossType        |-> [i \in 1 .. 1 |-> 0],
      crossLevel       |-> [i \in 1 .. 1 |-> 0] ]

(* Moii Message at zero, then each field in turn at the values it is checked at *)
CheckedMoiiMessage ==
    { ZeroMoiiMessage }
        \cup { [ZeroMoiiMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMoiiMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMoiiMessage EXCEPT !.pairedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroMoiiMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroMoiiMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }
        \cup { [ZeroMoiiMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroMoiiMessage EXCEPT !.crossLevel = one] : one \in Sample(1) }

(***************************************************************************)
(* Execution Summary Message: 37 bytes                                     *)
(***************************************************************************)

ExecutionSummaryMessage ==
    [ timestamp             : Sample(8),
      trackingNumber        : Sample(2),
      orderBook             : Sample(4),
      aggressingSide        : Sample(1),
      quantity              : Sample(4),
      hiddenQuantity        : Sample(4),
      stpCancelQuantity     : Sample(4),
      farPrice              : Sample(4),
      addQuantity           : Sample(4),
      numberOfLitExecutions : Sample(2) ]

EncodeExecutionSummaryMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderBook
        \o message.aggressingSide
        \o message.quantity
        \o message.hiddenQuantity
        \o message.stpCancelQuantity
        \o message.farPrice
        \o message.addQuantity
        \o message.numberOfLitExecutions

DecodeExecutionSummaryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderBook == ReadBytes(trackingNumber.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET aggressingSide == ReadBytes(orderBook.rest, 1) IN IF ~aggressingSide.ok THEN Fail ELSE
    LET quantity == ReadBytes(aggressingSide.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET hiddenQuantity == ReadBytes(quantity.rest, 4) IN IF ~hiddenQuantity.ok THEN Fail ELSE
    LET stpCancelQuantity == ReadBytes(hiddenQuantity.rest, 4) IN IF ~stpCancelQuantity.ok THEN Fail ELSE
    LET farPrice == ReadBytes(stpCancelQuantity.rest, 4) IN IF ~farPrice.ok THEN Fail ELSE
    LET addQuantity == ReadBytes(farPrice.rest, 4) IN IF ~addQuantity.ok THEN Fail ELSE
    LET numberOfLitExecutions == ReadBytes(addQuantity.rest, 2) IN IF ~numberOfLitExecutions.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         trackingNumber        |-> trackingNumber.value,
         orderBook             |-> orderBook.value,
         aggressingSide        |-> aggressingSide.value,
         quantity              |-> quantity.value,
         hiddenQuantity        |-> hiddenQuantity.value,
         stpCancelQuantity     |-> stpCancelQuantity.value,
         farPrice              |-> farPrice.value,
         addQuantity           |-> addQuantity.value,
         numberOfLitExecutions |-> numberOfLitExecutions.value ], numberOfLitExecutions.rest)

ZeroExecutionSummaryMessage ==
    [ timestamp             |-> [i \in 1 .. 8 |-> 0],
      trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      orderBook             |-> [i \in 1 .. 4 |-> 0],
      aggressingSide        |-> [i \in 1 .. 1 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0],
      hiddenQuantity        |-> [i \in 1 .. 4 |-> 0],
      stpCancelQuantity     |-> [i \in 1 .. 4 |-> 0],
      farPrice              |-> [i \in 1 .. 4 |-> 0],
      addQuantity           |-> [i \in 1 .. 4 |-> 0],
      numberOfLitExecutions |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionSummaryMessage ==
    { ZeroExecutionSummaryMessage }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.aggressingSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.hiddenQuantity = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.stpCancelQuantity = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.farPrice = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.addQuantity = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.numberOfLitExecutions = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OrderBookTradingActionMessageCode == 72  \* "H"
OrderBookDirectoryMessageCode == 82  \* "R"
AddOrderMessageCode == 65  \* "A"
AddOrderMpidAttributionMessageCode == 70  \* "F"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderCancelMessageCode == 88  \* "X"
OrderDeleteMessageCode == 68  \* "D"
OrderBookFlushMessageCode == 89  \* "Y"
OrderReplaceMessageCode == 85  \* "U"
TradeMessageCode == 80  \* "P"
CrossTradeMessageCode == 81  \* "Q"
BrokenTradeMessageCode == 66  \* "B"
NoiiMessageCode == 73  \* "I"
MoiiMessageCode == 74  \* "J"
ExecutionSummaryMessageCode == 75  \* "K"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderBookTradingActionMessageCode}, body : OrderBookTradingActionMessage ]
        \cup [ tag : {OrderBookDirectoryMessageCode}, body : OrderBookDirectoryMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AddOrderMpidAttributionMessageCode}, body : AddOrderMpidAttributionMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderBookFlushMessageCode}, body : OrderBookFlushMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {CrossTradeMessageCode}, body : CrossTradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {NoiiMessageCode}, body : NoiiMessage ]
        \cup [ tag : {MoiiMessageCode}, body : MoiiMessage ]
        \cup [ tag : {ExecutionSummaryMessageCode}, body : ExecutionSummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderBookTradingActionMessageCode -> EncodeOrderBookTradingActionMessage(message.body)
      [] message.tag = OrderBookDirectoryMessageCode -> EncodeOrderBookDirectoryMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AddOrderMpidAttributionMessageCode -> EncodeAddOrderMpidAttributionMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderBookFlushMessageCode -> EncodeOrderBookFlushMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = CrossTradeMessageCode -> EncodeCrossTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = NoiiMessageCode -> EncodeNoiiMessage(message.body)
      [] message.tag = MoiiMessageCode -> EncodeMoiiMessage(message.body)
      [] message.tag = ExecutionSummaryMessageCode -> EncodeExecutionSummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderBookTradingActionMessageCode -> DecodeOrderBookTradingActionMessage(bytes)
              [] tag = OrderBookDirectoryMessageCode -> DecodeOrderBookDirectoryMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AddOrderMpidAttributionMessageCode -> DecodeAddOrderMpidAttributionMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderBookFlushMessageCode -> DecodeOrderBookFlushMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = CrossTradeMessageCode -> DecodeCrossTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = NoiiMessageCode -> DecodeNoiiMessage(bytes)
              [] tag = MoiiMessageCode -> DecodeMoiiMessage(bytes)
              [] tag = ExecutionSummaryMessageCode -> DecodeExecutionSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderBookTradingActionMessageCode, body |-> one] : one \in CheckedOrderBookTradingActionMessage }
        \cup { [tag |-> OrderBookDirectoryMessageCode, body |-> one] : one \in CheckedOrderBookDirectoryMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AddOrderMpidAttributionMessageCode, body |-> one] : one \in CheckedAddOrderMpidAttributionMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderBookFlushMessageCode, body |-> one] : one \in CheckedOrderBookFlushMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> CrossTradeMessageCode, body |-> one] : one \in CheckedCrossTradeMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> NoiiMessageCode, body |-> one] : one \in CheckedNoiiMessage }
        \cup { [tag |-> MoiiMessageCode, body |-> one] : one \in CheckedMoiiMessage }
        \cup { [tag |-> ExecutionSummaryMessageCode, body |-> one] : one \in CheckedExecutionSummaryMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookTradingActionMessageCode, body |-> ZeroOrderBookTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookDirectoryMessageCode, body |-> ZeroOrderBookDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMpidAttributionMessageCode, body |-> ZeroAddOrderMpidAttributionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceMessageCode, body |-> ZeroOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookFlushMessageCode, body |-> ZeroOrderBookFlushMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceMessageCode, body |-> ZeroOrderReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CrossTradeMessageCode, body |-> ZeroCrossTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokenTradeMessageCode, body |-> ZeroBrokenTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NoiiMessageCode, body |-> ZeroNoiiMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MoiiMessageCode, body |-> ZeroMoiiMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionSummaryMessageCode, body |-> ZeroExecutionSummaryMessage]] }

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
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
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
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookTradingActionMessage ==
    \A message \in CheckedOrderBookTradingActionMessage :
        LET read == DecodeOrderBookTradingActionMessage(EncodeOrderBookTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookDirectoryMessage ==
    \A message \in CheckedOrderBookDirectoryMessage :
        LET read == DecodeOrderBookDirectoryMessage(EncodeOrderBookDirectoryMessage(message))
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

(* Every Add Order Mpid Attribution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMpidAttributionMessage ==
    \A message \in CheckedAddOrderMpidAttributionMessage :
        LET read == DecodeAddOrderMpidAttributionMessage(EncodeAddOrderMpidAttributionMessage(message))
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

(* Every Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceMessage ==
    \A message \in CheckedOrderExecutedWithPriceMessage :
        LET read == DecodeOrderExecutedWithPriceMessage(EncodeOrderExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Flush Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookFlushMessage ==
    \A message \in CheckedOrderBookFlushMessage :
        LET read == DecodeOrderBookFlushMessage(EncodeOrderBookFlushMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceMessage ==
    \A message \in CheckedOrderReplaceMessage :
        LET read == DecodeOrderReplaceMessage(EncodeOrderReplaceMessage(message))
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

(* Every Cross Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossTradeMessage ==
    \A message \in CheckedCrossTradeMessage :
        LET read == DecodeCrossTradeMessage(EncodeCrossTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Noii Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNoiiMessage ==
    \A message \in CheckedNoiiMessage :
        LET read == DecodeNoiiMessage(EncodeNoiiMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Moii Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMoiiMessage ==
    \A message \in CheckedMoiiMessage :
        LET read == DecodeMoiiMessage(EncodeMoiiMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionSummaryMessage ==
    \A message \in CheckedExecutionSummaryMessage :
        LET read == DecodeExecutionSummaryMessage(EncodeExecutionSummaryMessage(message))
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
    \A message \in Payload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
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
