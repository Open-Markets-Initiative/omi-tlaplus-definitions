-------------- MODULE NordicEquities_TotalView_v3_00_1_Server --------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nordic Equity TotalView v3.00.1                                *)
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
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

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
(* Order Book Directory Message: 96 bytes                                  *)
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
      multiplierForCalculatingQuantityInMeasurementUnit : Sample(8) ]

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
         multiplierForCalculatingQuantityInMeasurementUnit |-> multiplierForCalculatingQuantityInMeasurementUnit.value ], multiplierForCalculatingQuantityInMeasurementUnit.rest)

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
      multiplierForCalculatingQuantityInMeasurementUnit |-> [i \in 1 .. 8 |-> 0] ]

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
(* End Of Snapshot Message: 20 bytes                                       *)
(***************************************************************************)

EndOfSnapshotMessage ==
    [ sequenceNumber : Sample(20) ]

EncodeEndOfSnapshotMessage(message) ==
    message.sequenceNumber

DecodeEndOfSnapshotMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 20) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroEndOfSnapshotMessage ==
    [ sequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* End Of Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSnapshotMessage ==
    { ZeroEndOfSnapshotMessage }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.sequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OrderBookTradingActionMessageCode == 72  \* "H"
OrderBookDirectoryMessageCode == 82  \* "R"
AddOrderMessageCode == 65  \* "A"
AddOrderMpidAttributionMessageCode == 70  \* "F"
EndOfSnapshotMessageCode == 71  \* "G"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderBookTradingActionMessageCode}, body : OrderBookTradingActionMessage ]
        \cup [ tag : {OrderBookDirectoryMessageCode}, body : OrderBookDirectoryMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AddOrderMpidAttributionMessageCode}, body : AddOrderMpidAttributionMessage ]
        \cup [ tag : {EndOfSnapshotMessageCode}, body : EndOfSnapshotMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderBookTradingActionMessageCode -> EncodeOrderBookTradingActionMessage(message.body)
      [] message.tag = OrderBookDirectoryMessageCode -> EncodeOrderBookDirectoryMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AddOrderMpidAttributionMessageCode -> EncodeAddOrderMpidAttributionMessage(message.body)
      [] message.tag = EndOfSnapshotMessageCode -> EncodeEndOfSnapshotMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderBookTradingActionMessageCode -> DecodeOrderBookTradingActionMessage(bytes)
              [] tag = OrderBookDirectoryMessageCode -> DecodeOrderBookDirectoryMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AddOrderMpidAttributionMessageCode -> DecodeAddOrderMpidAttributionMessage(bytes)
              [] tag = EndOfSnapshotMessageCode -> DecodeEndOfSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderBookTradingActionMessageCode, body |-> one] : one \in CheckedOrderBookTradingActionMessage }
        \cup { [tag |-> OrderBookDirectoryMessageCode, body |-> one] : one \in CheckedOrderBookDirectoryMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AddOrderMpidAttributionMessageCode, body |-> one] : one \in CheckedAddOrderMpidAttributionMessage }
        \cup { [tag |-> EndOfSnapshotMessageCode, body |-> one] : one \in CheckedEndOfSnapshotMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
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

(* Every End Of Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSnapshotMessage ==
    \A message \in CheckedEndOfSnapshotMessage :
        LET read == DecodeEndOfSnapshotMessage(EncodeEndOfSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
