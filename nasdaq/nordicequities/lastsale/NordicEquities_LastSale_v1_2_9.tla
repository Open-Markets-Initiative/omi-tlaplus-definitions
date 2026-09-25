------------------ MODULE NordicEquities_LastSale_v1_2_9 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nordic Equity Last Sale v1.2.9                                 *)
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
(* Adjusted Closing Price Message: 22 bytes                                *)
(***************************************************************************)

AdjustedClosingPriceMessage ==
    [ timestamp            : Sample(8),
      trackingNumber       : Sample(2),
      orderBook            : Sample(4),
      adjustedClosingPrice : Sample(8) ]

EncodeAdjustedClosingPriceMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderBook
        \o message.adjustedClosingPrice

DecodeAdjustedClosingPriceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderBook == ReadBytes(trackingNumber.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(orderBook.rest, 8) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         trackingNumber       |-> trackingNumber.value,
         orderBook            |-> orderBook.value,
         adjustedClosingPrice |-> adjustedClosingPrice.value ], adjustedClosingPrice.rest)

ZeroAdjustedClosingPriceMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      orderBook            |-> [i \in 1 .. 4 |-> 0],
      adjustedClosingPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Adjusted Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedAdjustedClosingPriceMessage ==
    { ZeroAdjustedClosingPriceMessage }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.adjustedClosingPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* On Exchange Trade Message: 92 bytes                                     *)
(***************************************************************************)

OnExchangeTradeMessage ==
    [ timestamp                 : Sample(8),
      trackingNumber            : Sample(2),
      orderBook                 : Sample(4),
      executionDate             : Sample(4),
      executionTime             : Sample(8),
      agreementDate             : Sample(4),
      agreementTime             : Sample(8),
      priceOnExchange           : Sample(8),
      quantity                  : Sample(8),
      venueOfExecution          : Sample(4),
      transactionIdentifierCode : Sample(10),
      mmtTradeFlags             : Sample(14),
      tradeType                 : Sample(1),
      mpidBuyer                 : Sample(4),
      mpidSeller                : Sample(4),
      transactionToBeCleared    : Sample(1) ]

EncodeOnExchangeTradeMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.orderBook
        \o message.executionDate
        \o message.executionTime
        \o message.agreementDate
        \o message.agreementTime
        \o message.priceOnExchange
        \o message.quantity
        \o message.venueOfExecution
        \o message.transactionIdentifierCode
        \o message.mmtTradeFlags
        \o message.tradeType
        \o message.mpidBuyer
        \o message.mpidSeller
        \o message.transactionToBeCleared

DecodeOnExchangeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET orderBook == ReadBytes(trackingNumber.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET executionDate == ReadBytes(orderBook.rest, 4) IN IF ~executionDate.ok THEN Fail ELSE
    LET executionTime == ReadBytes(executionDate.rest, 8) IN IF ~executionTime.ok THEN Fail ELSE
    LET agreementDate == ReadBytes(executionTime.rest, 4) IN IF ~agreementDate.ok THEN Fail ELSE
    LET agreementTime == ReadBytes(agreementDate.rest, 8) IN IF ~agreementTime.ok THEN Fail ELSE
    LET priceOnExchange == ReadBytes(agreementTime.rest, 8) IN IF ~priceOnExchange.ok THEN Fail ELSE
    LET quantity == ReadBytes(priceOnExchange.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(quantity.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    LET transactionIdentifierCode == ReadBytes(venueOfExecution.rest, 10) IN IF ~transactionIdentifierCode.ok THEN Fail ELSE
    LET mmtTradeFlags == ReadBytes(transactionIdentifierCode.rest, 14) IN IF ~mmtTradeFlags.ok THEN Fail ELSE
    LET tradeType == ReadBytes(mmtTradeFlags.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET mpidBuyer == ReadBytes(tradeType.rest, 4) IN IF ~mpidBuyer.ok THEN Fail ELSE
    LET mpidSeller == ReadBytes(mpidBuyer.rest, 4) IN IF ~mpidSeller.ok THEN Fail ELSE
    LET transactionToBeCleared == ReadBytes(mpidSeller.rest, 1) IN IF ~transactionToBeCleared.ok THEN Fail ELSE
    Ok([ timestamp                 |-> timestamp.value,
         trackingNumber            |-> trackingNumber.value,
         orderBook                 |-> orderBook.value,
         executionDate             |-> executionDate.value,
         executionTime             |-> executionTime.value,
         agreementDate             |-> agreementDate.value,
         agreementTime             |-> agreementTime.value,
         priceOnExchange           |-> priceOnExchange.value,
         quantity                  |-> quantity.value,
         venueOfExecution          |-> venueOfExecution.value,
         transactionIdentifierCode |-> transactionIdentifierCode.value,
         mmtTradeFlags             |-> mmtTradeFlags.value,
         tradeType                 |-> tradeType.value,
         mpidBuyer                 |-> mpidBuyer.value,
         mpidSeller                |-> mpidSeller.value,
         transactionToBeCleared    |-> transactionToBeCleared.value ], transactionToBeCleared.rest)

ZeroOnExchangeTradeMessage ==
    [ timestamp                 |-> [i \in 1 .. 8 |-> 0],
      trackingNumber            |-> [i \in 1 .. 2 |-> 0],
      orderBook                 |-> [i \in 1 .. 4 |-> 0],
      executionDate             |-> [i \in 1 .. 4 |-> 0],
      executionTime             |-> [i \in 1 .. 8 |-> 0],
      agreementDate             |-> [i \in 1 .. 4 |-> 0],
      agreementTime             |-> [i \in 1 .. 8 |-> 0],
      priceOnExchange           |-> [i \in 1 .. 8 |-> 0],
      quantity                  |-> [i \in 1 .. 8 |-> 0],
      venueOfExecution          |-> [i \in 1 .. 4 |-> 0],
      transactionIdentifierCode |-> [i \in 1 .. 10 |-> 0],
      mmtTradeFlags             |-> [i \in 1 .. 14 |-> 0],
      tradeType                 |-> [i \in 1 .. 1 |-> 0],
      mpidBuyer                 |-> [i \in 1 .. 4 |-> 0],
      mpidSeller                |-> [i \in 1 .. 4 |-> 0],
      transactionToBeCleared    |-> [i \in 1 .. 1 |-> 0] ]

(* On Exchange Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOnExchangeTradeMessage ==
    { ZeroOnExchangeTradeMessage }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.executionDate = one] : one \in Sample(4) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.executionTime = one] : one \in Sample(8) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.agreementDate = one] : one \in Sample(4) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.agreementTime = one] : one \in Sample(8) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.priceOnExchange = one] : one \in Sample(8) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.transactionIdentifierCode = one] : one \in Sample(10) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.mmtTradeFlags = one] : one \in Sample(14) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.mpidBuyer = one] : one \in Sample(4) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.mpidSeller = one] : one \in Sample(4) }
        \cup { [ZeroOnExchangeTradeMessage EXCEPT !.transactionToBeCleared = one] : one \in Sample(1) }

(***************************************************************************)
(* Otc Trade Message: 147 bytes                                            *)
(***************************************************************************)

OtcTradeMessage ==
    [ timestamp                              : Sample(8),
      trackingNumber                         : Sample(2),
      instrumentIdentificationCodeType       : Sample(4),
      instrumentIdentificationCode           : Sample(12),
      agreementDate                          : Sample(4),
      agreementTime                          : Sample(8),
      priceOtc                               : Sample(8),
      priceFraction                          : Sample(1),
      priceNotation                          : Sample(4),
      priceCurrency                          : Sample(3),
      quantity                               : Sample(8),
      quantityFraction                       : Sample(1),
      notationOfTheQuantityInMeasurementUnit : Sample(25),
      quantityInMeasurementUnit              : Sample(8),
      quantityInMeasurementUnitFraction      : Sample(1),
      venueOfExecution                       : Sample(4),
      notionalAmount                         : Sample(8),
      notionalAmountFraction                 : Sample(1),
      notionalCurrency                       : Sample(3),
      type                                   : Sample(4),
      transactionIdentifierCode              : Sample(10),
      mmtTradeFlags                          : Sample(14),
      transactionToBeCleared                 : Sample(1),
      tradeType                              : Sample(1),
      thirdCountryTradingVenueOfExecution    : Sample(4) ]

EncodeOtcTradeMessage(message) ==
    message.timestamp
        \o message.trackingNumber
        \o message.instrumentIdentificationCodeType
        \o message.instrumentIdentificationCode
        \o message.agreementDate
        \o message.agreementTime
        \o message.priceOtc
        \o message.priceFraction
        \o message.priceNotation
        \o message.priceCurrency
        \o message.quantity
        \o message.quantityFraction
        \o message.notationOfTheQuantityInMeasurementUnit
        \o message.quantityInMeasurementUnit
        \o message.quantityInMeasurementUnitFraction
        \o message.venueOfExecution
        \o message.notionalAmount
        \o message.notionalAmountFraction
        \o message.notionalCurrency
        \o message.type
        \o message.transactionIdentifierCode
        \o message.mmtTradeFlags
        \o message.transactionToBeCleared
        \o message.tradeType
        \o message.thirdCountryTradingVenueOfExecution

DecodeOtcTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(timestamp.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET instrumentIdentificationCodeType == ReadBytes(trackingNumber.rest, 4) IN IF ~instrumentIdentificationCodeType.ok THEN Fail ELSE
    LET instrumentIdentificationCode == ReadBytes(instrumentIdentificationCodeType.rest, 12) IN IF ~instrumentIdentificationCode.ok THEN Fail ELSE
    LET agreementDate == ReadBytes(instrumentIdentificationCode.rest, 4) IN IF ~agreementDate.ok THEN Fail ELSE
    LET agreementTime == ReadBytes(agreementDate.rest, 8) IN IF ~agreementTime.ok THEN Fail ELSE
    LET priceOtc == ReadBytes(agreementTime.rest, 8) IN IF ~priceOtc.ok THEN Fail ELSE
    LET priceFraction == ReadBytes(priceOtc.rest, 1) IN IF ~priceFraction.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(priceFraction.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET priceCurrency == ReadBytes(priceNotation.rest, 3) IN IF ~priceCurrency.ok THEN Fail ELSE
    LET quantity == ReadBytes(priceCurrency.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET quantityFraction == ReadBytes(quantity.rest, 1) IN IF ~quantityFraction.ok THEN Fail ELSE
    LET notationOfTheQuantityInMeasurementUnit == ReadBytes(quantityFraction.rest, 25) IN IF ~notationOfTheQuantityInMeasurementUnit.ok THEN Fail ELSE
    LET quantityInMeasurementUnit == ReadBytes(notationOfTheQuantityInMeasurementUnit.rest, 8) IN IF ~quantityInMeasurementUnit.ok THEN Fail ELSE
    LET quantityInMeasurementUnitFraction == ReadBytes(quantityInMeasurementUnit.rest, 1) IN IF ~quantityInMeasurementUnitFraction.ok THEN Fail ELSE
    LET venueOfExecution == ReadBytes(quantityInMeasurementUnitFraction.rest, 4) IN IF ~venueOfExecution.ok THEN Fail ELSE
    LET notionalAmount == ReadBytes(venueOfExecution.rest, 8) IN IF ~notionalAmount.ok THEN Fail ELSE
    LET notionalAmountFraction == ReadBytes(notionalAmount.rest, 1) IN IF ~notionalAmountFraction.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(notionalAmountFraction.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET type == ReadBytes(notionalCurrency.rest, 4) IN IF ~type.ok THEN Fail ELSE
    LET transactionIdentifierCode == ReadBytes(type.rest, 10) IN IF ~transactionIdentifierCode.ok THEN Fail ELSE
    LET mmtTradeFlags == ReadBytes(transactionIdentifierCode.rest, 14) IN IF ~mmtTradeFlags.ok THEN Fail ELSE
    LET transactionToBeCleared == ReadBytes(mmtTradeFlags.rest, 1) IN IF ~transactionToBeCleared.ok THEN Fail ELSE
    LET tradeType == ReadBytes(transactionToBeCleared.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET thirdCountryTradingVenueOfExecution == ReadBytes(tradeType.rest, 4) IN IF ~thirdCountryTradingVenueOfExecution.ok THEN Fail ELSE
    Ok([ timestamp                              |-> timestamp.value,
         trackingNumber                         |-> trackingNumber.value,
         instrumentIdentificationCodeType       |-> instrumentIdentificationCodeType.value,
         instrumentIdentificationCode           |-> instrumentIdentificationCode.value,
         agreementDate                          |-> agreementDate.value,
         agreementTime                          |-> agreementTime.value,
         priceOtc                               |-> priceOtc.value,
         priceFraction                          |-> priceFraction.value,
         priceNotation                          |-> priceNotation.value,
         priceCurrency                          |-> priceCurrency.value,
         quantity                               |-> quantity.value,
         quantityFraction                       |-> quantityFraction.value,
         notationOfTheQuantityInMeasurementUnit |-> notationOfTheQuantityInMeasurementUnit.value,
         quantityInMeasurementUnit              |-> quantityInMeasurementUnit.value,
         quantityInMeasurementUnitFraction      |-> quantityInMeasurementUnitFraction.value,
         venueOfExecution                       |-> venueOfExecution.value,
         notionalAmount                         |-> notionalAmount.value,
         notionalAmountFraction                 |-> notionalAmountFraction.value,
         notionalCurrency                       |-> notionalCurrency.value,
         type                                   |-> type.value,
         transactionIdentifierCode              |-> transactionIdentifierCode.value,
         mmtTradeFlags                          |-> mmtTradeFlags.value,
         transactionToBeCleared                 |-> transactionToBeCleared.value,
         tradeType                              |-> tradeType.value,
         thirdCountryTradingVenueOfExecution    |-> thirdCountryTradingVenueOfExecution.value ], thirdCountryTradingVenueOfExecution.rest)

ZeroOtcTradeMessage ==
    [ timestamp                              |-> [i \in 1 .. 8 |-> 0],
      trackingNumber                         |-> [i \in 1 .. 2 |-> 0],
      instrumentIdentificationCodeType       |-> [i \in 1 .. 4 |-> 0],
      instrumentIdentificationCode           |-> [i \in 1 .. 12 |-> 0],
      agreementDate                          |-> [i \in 1 .. 4 |-> 0],
      agreementTime                          |-> [i \in 1 .. 8 |-> 0],
      priceOtc                               |-> [i \in 1 .. 8 |-> 0],
      priceFraction                          |-> [i \in 1 .. 1 |-> 0],
      priceNotation                          |-> [i \in 1 .. 4 |-> 0],
      priceCurrency                          |-> [i \in 1 .. 3 |-> 0],
      quantity                               |-> [i \in 1 .. 8 |-> 0],
      quantityFraction                       |-> [i \in 1 .. 1 |-> 0],
      notationOfTheQuantityInMeasurementUnit |-> [i \in 1 .. 25 |-> 0],
      quantityInMeasurementUnit              |-> [i \in 1 .. 8 |-> 0],
      quantityInMeasurementUnitFraction      |-> [i \in 1 .. 1 |-> 0],
      venueOfExecution                       |-> [i \in 1 .. 4 |-> 0],
      notionalAmount                         |-> [i \in 1 .. 8 |-> 0],
      notionalAmountFraction                 |-> [i \in 1 .. 1 |-> 0],
      notionalCurrency                       |-> [i \in 1 .. 3 |-> 0],
      type                                   |-> [i \in 1 .. 4 |-> 0],
      transactionIdentifierCode              |-> [i \in 1 .. 10 |-> 0],
      mmtTradeFlags                          |-> [i \in 1 .. 14 |-> 0],
      transactionToBeCleared                 |-> [i \in 1 .. 1 |-> 0],
      tradeType                              |-> [i \in 1 .. 1 |-> 0],
      thirdCountryTradingVenueOfExecution    |-> [i \in 1 .. 4 |-> 0] ]

(* Otc Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOtcTradeMessage ==
    { ZeroOtcTradeMessage }
        \cup { [ZeroOtcTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.instrumentIdentificationCodeType = one] : one \in Sample(4) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.instrumentIdentificationCode = one] : one \in Sample(12) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.agreementDate = one] : one \in Sample(4) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.agreementTime = one] : one \in Sample(8) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.priceOtc = one] : one \in Sample(8) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.priceFraction = one] : one \in Sample(1) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.priceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.quantityFraction = one] : one \in Sample(1) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.notationOfTheQuantityInMeasurementUnit = one] : one \in Sample(25) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.quantityInMeasurementUnit = one] : one \in Sample(8) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.quantityInMeasurementUnitFraction = one] : one \in Sample(1) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.venueOfExecution = one] : one \in Sample(4) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.notionalAmount = one] : one \in Sample(8) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.notionalAmountFraction = one] : one \in Sample(1) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.type = one] : one \in Sample(4) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.transactionIdentifierCode = one] : one \in Sample(10) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.mmtTradeFlags = one] : one \in Sample(14) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.transactionToBeCleared = one] : one \in Sample(1) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroOtcTradeMessage EXCEPT !.thirdCountryTradingVenueOfExecution = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

AdjustedClosingPriceMessageCode == 71  \* "G"
OnExchangeTradeMessageCode == 84  \* "T"
OtcTradeMessageCode == 90  \* "Z"

Payload ==
    [ tag : {AdjustedClosingPriceMessageCode}, body : AdjustedClosingPriceMessage ]
        \cup [ tag : {OnExchangeTradeMessageCode}, body : OnExchangeTradeMessage ]
        \cup [ tag : {OtcTradeMessageCode}, body : OtcTradeMessage ]

EncodePayload(message) ==
    CASE message.tag = AdjustedClosingPriceMessageCode -> EncodeAdjustedClosingPriceMessage(message.body)
      [] message.tag = OnExchangeTradeMessageCode -> EncodeOnExchangeTradeMessage(message.body)
      [] message.tag = OtcTradeMessageCode -> EncodeOtcTradeMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AdjustedClosingPriceMessageCode -> DecodeAdjustedClosingPriceMessage(bytes)
              [] tag = OnExchangeTradeMessageCode -> DecodeOnExchangeTradeMessage(bytes)
              [] tag = OtcTradeMessageCode -> DecodeOtcTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AdjustedClosingPriceMessageCode, body |-> ZeroAdjustedClosingPriceMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AdjustedClosingPriceMessageCode, body |-> one] : one \in CheckedAdjustedClosingPriceMessage }
        \cup { [tag |-> OnExchangeTradeMessageCode, body |-> one] : one \in CheckedOnExchangeTradeMessage }
        \cup { [tag |-> OtcTradeMessageCode, body |-> one] : one \in CheckedOtcTradeMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AdjustedClosingPriceMessageCode, body |-> ZeroAdjustedClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OnExchangeTradeMessageCode, body |-> ZeroOnExchangeTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OtcTradeMessageCode, body |-> ZeroOtcTradeMessage]] }

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

(* Every Adjusted Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdjustedClosingPriceMessage ==
    \A message \in CheckedAdjustedClosingPriceMessage :
        LET read == DecodeAdjustedClosingPriceMessage(EncodeAdjustedClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every On Exchange Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOnExchangeTradeMessage ==
    \A message \in CheckedOnExchangeTradeMessage :
        LET read == DecodeOnExchangeTradeMessage(EncodeOnExchangeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcTradeMessage ==
    \A message \in CheckedOtcTradeMessage :
        LET read == DecodeOtcTradeMessage(EncodeOtcTradeMessage(message))
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
