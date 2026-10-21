--------------- MODULE NyseBonds_DepthOfBook_v4_01_b_Server ----------------
(***************************************************************************)
(* New York Stock Exchange DepthOfBook v4.01.b                             *)
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
(* Login Accepted Message: 6 bytes                                         *)
(***************************************************************************)

LoginAcceptedMessage ==
    [ versionId     : Sample(5),
      paddingAscii1 : Sample(1) ]

EncodeLoginAcceptedMessage(message) ==
    message.versionId
        \o message.paddingAscii1

DecodeLoginAcceptedMessage(bytes) ==
    LET versionId == ReadBytes(bytes, 5) IN IF ~versionId.ok THEN Fail ELSE
    LET paddingAscii1 == ReadBytes(versionId.rest, 1) IN IF ~paddingAscii1.ok THEN Fail ELSE
    Ok([ versionId     |-> versionId.value,
         paddingAscii1 |-> paddingAscii1.value ], paddingAscii1.rest)

ZeroLoginAcceptedMessage ==
    [ versionId     |-> [i \in 1 .. 5 |-> 0],
      paddingAscii1 |-> [i \in 1 .. 1 |-> 0] ]

(* Login Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedMessage ==
    { ZeroLoginAcceptedMessage }
        \cup { [ZeroLoginAcceptedMessage EXCEPT !.versionId = one] : one \in Sample(5) }
        \cup { [ZeroLoginAcceptedMessage EXCEPT !.paddingAscii1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Rejected Message: 2 bytes                                         *)
(***************************************************************************)

LoginRejectedMessage ==
    [ rejectCode    : Sample(1),
      paddingAscii1 : Sample(1) ]

EncodeLoginRejectedMessage(message) ==
    message.rejectCode
        \o message.paddingAscii1

DecodeLoginRejectedMessage(bytes) ==
    LET rejectCode == ReadBytes(bytes, 1) IN IF ~rejectCode.ok THEN Fail ELSE
    LET paddingAscii1 == ReadBytes(rejectCode.rest, 1) IN IF ~paddingAscii1.ok THEN Fail ELSE
    Ok([ rejectCode    |-> rejectCode.value,
         paddingAscii1 |-> paddingAscii1.value ], paddingAscii1.rest)

ZeroLoginRejectedMessage ==
    [ rejectCode    |-> [i \in 1 .. 1 |-> 0],
      paddingAscii1 |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedMessage ==
    { ZeroLoginRejectedMessage }
        \cup { [ZeroLoginRejectedMessage EXCEPT !.rejectCode = one] : one \in Sample(1) }
        \cup { [ZeroLoginRejectedMessage EXCEPT !.paddingAscii1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Test Response Message: 20 bytes                                         *)
(***************************************************************************)

TestResponseMessage ==
    [ testMessage : Sample(20) ]

EncodeTestResponseMessage(message) ==
    message.testMessage

DecodeTestResponseMessage(bytes) ==
    LET testMessage == ReadBytes(bytes, 20) IN IF ~testMessage.ok THEN Fail ELSE
    Ok([ testMessage |-> testMessage.value ], testMessage.rest)

ZeroTestResponseMessage ==
    [ testMessage |-> [i \in 1 .. 20 |-> 0] ]

(* Test Response Message at zero, then each field in turn at the values it is checked at *)
CheckedTestResponseMessage ==
    { ZeroTestResponseMessage }
        \cup { [ZeroTestResponseMessage EXCEPT !.testMessage = one] : one \in Sample(20) }

(***************************************************************************)
(* Add Order Message: 76 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ time                 : Sample(4),
      sequenceNumber       : Sample(4),
      orderReferenceNumber : Sample(4),
      quantity             : Sample(4),
      price                : Sample(4),
      priceScaleCode       : Sample(1),
      exchangeCode         : Sample(1),
      systemCode           : Sample(1),
      buySellIndicator     : Sample(1),
      flatPricing          : Sample(1),
      tradingAction        : Sample(1),
      securityType         : Sample(1),
      orderType            : Sample(1),
      nyseBondSymbol       : Sample(22),
      cusipIsin            : Sample(14),
      quoteId              : Sample(5),
      paddingAscii3        : Sample(3),
      minimumQuantity      : Sample(4) ]

EncodeAddOrderMessage(message) ==
    message.time
        \o message.sequenceNumber
        \o message.orderReferenceNumber
        \o message.quantity
        \o message.price
        \o message.priceScaleCode
        \o message.exchangeCode
        \o message.systemCode
        \o message.buySellIndicator
        \o message.flatPricing
        \o message.tradingAction
        \o message.securityType
        \o message.orderType
        \o message.nyseBondSymbol
        \o message.cusipIsin
        \o message.quoteId
        \o message.paddingAscii3
        \o message.minimumQuantity

DecodeAddOrderMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(time.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(sequenceNumber.rest, 4) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(price.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET systemCode == ReadBytes(exchangeCode.rest, 1) IN IF ~systemCode.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(systemCode.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET flatPricing == ReadBytes(buySellIndicator.rest, 1) IN IF ~flatPricing.ok THEN Fail ELSE
    LET tradingAction == ReadBytes(flatPricing.rest, 1) IN IF ~tradingAction.ok THEN Fail ELSE
    LET securityType == ReadBytes(tradingAction.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET orderType == ReadBytes(securityType.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET nyseBondSymbol == ReadBytes(orderType.rest, 22) IN IF ~nyseBondSymbol.ok THEN Fail ELSE
    LET cusipIsin == ReadBytes(nyseBondSymbol.rest, 14) IN IF ~cusipIsin.ok THEN Fail ELSE
    LET quoteId == ReadBytes(cusipIsin.rest, 5) IN IF ~quoteId.ok THEN Fail ELSE
    LET paddingAscii3 == ReadBytes(quoteId.rest, 3) IN IF ~paddingAscii3.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(paddingAscii3.rest, 4) IN IF ~minimumQuantity.ok THEN Fail ELSE
    Ok([ time                 |-> time.value,
         sequenceNumber       |-> sequenceNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         priceScaleCode       |-> priceScaleCode.value,
         exchangeCode         |-> exchangeCode.value,
         systemCode           |-> systemCode.value,
         buySellIndicator     |-> buySellIndicator.value,
         flatPricing          |-> flatPricing.value,
         tradingAction        |-> tradingAction.value,
         securityType         |-> securityType.value,
         orderType            |-> orderType.value,
         nyseBondSymbol       |-> nyseBondSymbol.value,
         cusipIsin            |-> cusipIsin.value,
         quoteId              |-> quoteId.value,
         paddingAscii3        |-> paddingAscii3.value,
         minimumQuantity      |-> minimumQuantity.value ], minimumQuantity.rest)

ZeroAddOrderMessage ==
    [ time                 |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      exchangeCode         |-> [i \in 1 .. 1 |-> 0],
      systemCode           |-> [i \in 1 .. 1 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      flatPricing          |-> [i \in 1 .. 1 |-> 0],
      tradingAction        |-> [i \in 1 .. 1 |-> 0],
      securityType         |-> [i \in 1 .. 1 |-> 0],
      orderType            |-> [i \in 1 .. 1 |-> 0],
      nyseBondSymbol       |-> [i \in 1 .. 22 |-> 0],
      cusipIsin            |-> [i \in 1 .. 14 |-> 0],
      quoteId              |-> [i \in 1 .. 5 |-> 0],
      paddingAscii3        |-> [i \in 1 .. 3 |-> 0],
      minimumQuantity      |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.systemCode = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.flatPricing = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.tradingAction = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.nyseBondSymbol = one] : one \in Sample(22) }
        \cup { [ZeroAddOrderMessage EXCEPT !.cusipIsin = one] : one \in Sample(14) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quoteId = one] : one \in Sample(5) }
        \cup { [ZeroAddOrderMessage EXCEPT !.paddingAscii3 = one] : one \in Sample(3) }
        \cup { [ZeroAddOrderMessage EXCEPT !.minimumQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Message: 76 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
    [ time                 : Sample(4),
      sequenceNumber       : Sample(4),
      orderReferenceNumber : Sample(4),
      quantity             : Sample(4),
      price                : Sample(4),
      priceScaleCode       : Sample(1),
      exchangeCode         : Sample(1),
      systemCode           : Sample(1),
      buySellIndicator     : Sample(1),
      flatPricing          : Sample(1),
      tradingAction        : Sample(1),
      securityType         : Sample(1),
      orderType            : Sample(1),
      nyseBondSymbol       : Sample(22),
      cusipIsin            : Sample(14),
      quoteId              : Sample(5),
      paddingAscii3        : Sample(3),
      minimumQuantity      : Sample(4) ]

EncodeModifyOrderMessage(message) ==
    message.time
        \o message.sequenceNumber
        \o message.orderReferenceNumber
        \o message.quantity
        \o message.price
        \o message.priceScaleCode
        \o message.exchangeCode
        \o message.systemCode
        \o message.buySellIndicator
        \o message.flatPricing
        \o message.tradingAction
        \o message.securityType
        \o message.orderType
        \o message.nyseBondSymbol
        \o message.cusipIsin
        \o message.quoteId
        \o message.paddingAscii3
        \o message.minimumQuantity

DecodeModifyOrderMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(time.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(sequenceNumber.rest, 4) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(price.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET systemCode == ReadBytes(exchangeCode.rest, 1) IN IF ~systemCode.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(systemCode.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET flatPricing == ReadBytes(buySellIndicator.rest, 1) IN IF ~flatPricing.ok THEN Fail ELSE
    LET tradingAction == ReadBytes(flatPricing.rest, 1) IN IF ~tradingAction.ok THEN Fail ELSE
    LET securityType == ReadBytes(tradingAction.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET orderType == ReadBytes(securityType.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET nyseBondSymbol == ReadBytes(orderType.rest, 22) IN IF ~nyseBondSymbol.ok THEN Fail ELSE
    LET cusipIsin == ReadBytes(nyseBondSymbol.rest, 14) IN IF ~cusipIsin.ok THEN Fail ELSE
    LET quoteId == ReadBytes(cusipIsin.rest, 5) IN IF ~quoteId.ok THEN Fail ELSE
    LET paddingAscii3 == ReadBytes(quoteId.rest, 3) IN IF ~paddingAscii3.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(paddingAscii3.rest, 4) IN IF ~minimumQuantity.ok THEN Fail ELSE
    Ok([ time                 |-> time.value,
         sequenceNumber       |-> sequenceNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         priceScaleCode       |-> priceScaleCode.value,
         exchangeCode         |-> exchangeCode.value,
         systemCode           |-> systemCode.value,
         buySellIndicator     |-> buySellIndicator.value,
         flatPricing          |-> flatPricing.value,
         tradingAction        |-> tradingAction.value,
         securityType         |-> securityType.value,
         orderType            |-> orderType.value,
         nyseBondSymbol       |-> nyseBondSymbol.value,
         cusipIsin            |-> cusipIsin.value,
         quoteId              |-> quoteId.value,
         paddingAscii3        |-> paddingAscii3.value,
         minimumQuantity      |-> minimumQuantity.value ], minimumQuantity.rest)

ZeroModifyOrderMessage ==
    [ time                 |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      exchangeCode         |-> [i \in 1 .. 1 |-> 0],
      systemCode           |-> [i \in 1 .. 1 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      flatPricing          |-> [i \in 1 .. 1 |-> 0],
      tradingAction        |-> [i \in 1 .. 1 |-> 0],
      securityType         |-> [i \in 1 .. 1 |-> 0],
      orderType            |-> [i \in 1 .. 1 |-> 0],
      nyseBondSymbol       |-> [i \in 1 .. 22 |-> 0],
      cusipIsin            |-> [i \in 1 .. 14 |-> 0],
      quoteId              |-> [i \in 1 .. 5 |-> 0],
      paddingAscii3        |-> [i \in 1 .. 3 |-> 0],
      minimumQuantity      |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.systemCode = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.flatPricing = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.tradingAction = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.nyseBondSymbol = one] : one \in Sample(22) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.cusipIsin = one] : one \in Sample(14) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.quoteId = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.paddingAscii3 = one] : one \in Sample(3) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.minimumQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Order Message: 60 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ time                 : Sample(4),
      sequenceNumber       : Sample(4),
      orderReferenceNumber : Sample(4),
      exchangeCode         : Sample(1),
      systemCode           : Sample(1),
      buySellIndicator     : Sample(1),
      flatPricing          : Sample(1),
      tradingAction        : Sample(1),
      securityType         : Sample(1),
      orderType            : Sample(1),
      nyseBondSymbol       : Sample(22),
      cusipIsin            : Sample(14),
      quoteId              : Sample(5) ]

EncodeDeleteOrderMessage(message) ==
    message.time
        \o message.sequenceNumber
        \o message.orderReferenceNumber
        \o message.exchangeCode
        \o message.systemCode
        \o message.buySellIndicator
        \o message.flatPricing
        \o message.tradingAction
        \o message.securityType
        \o message.orderType
        \o message.nyseBondSymbol
        \o message.cusipIsin
        \o message.quoteId

DecodeDeleteOrderMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(time.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(sequenceNumber.rest, 4) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET systemCode == ReadBytes(exchangeCode.rest, 1) IN IF ~systemCode.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(systemCode.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET flatPricing == ReadBytes(buySellIndicator.rest, 1) IN IF ~flatPricing.ok THEN Fail ELSE
    LET tradingAction == ReadBytes(flatPricing.rest, 1) IN IF ~tradingAction.ok THEN Fail ELSE
    LET securityType == ReadBytes(tradingAction.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET orderType == ReadBytes(securityType.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET nyseBondSymbol == ReadBytes(orderType.rest, 22) IN IF ~nyseBondSymbol.ok THEN Fail ELSE
    LET cusipIsin == ReadBytes(nyseBondSymbol.rest, 14) IN IF ~cusipIsin.ok THEN Fail ELSE
    LET quoteId == ReadBytes(cusipIsin.rest, 5) IN IF ~quoteId.ok THEN Fail ELSE
    Ok([ time                 |-> time.value,
         sequenceNumber       |-> sequenceNumber.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         exchangeCode         |-> exchangeCode.value,
         systemCode           |-> systemCode.value,
         buySellIndicator     |-> buySellIndicator.value,
         flatPricing          |-> flatPricing.value,
         tradingAction        |-> tradingAction.value,
         securityType         |-> securityType.value,
         orderType            |-> orderType.value,
         nyseBondSymbol       |-> nyseBondSymbol.value,
         cusipIsin            |-> cusipIsin.value,
         quoteId              |-> quoteId.value ], quoteId.rest)

ZeroDeleteOrderMessage ==
    [ time                 |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      exchangeCode         |-> [i \in 1 .. 1 |-> 0],
      systemCode           |-> [i \in 1 .. 1 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      flatPricing          |-> [i \in 1 .. 1 |-> 0],
      tradingAction        |-> [i \in 1 .. 1 |-> 0],
      securityType         |-> [i \in 1 .. 1 |-> 0],
      orderType            |-> [i \in 1 .. 1 |-> 0],
      nyseBondSymbol       |-> [i \in 1 .. 22 |-> 0],
      cusipIsin            |-> [i \in 1 .. 14 |-> 0],
      quoteId              |-> [i \in 1 .. 5 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.systemCode = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.flatPricing = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.tradingAction = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.nyseBondSymbol = one] : one \in Sample(22) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.cusipIsin = one] : one \in Sample(14) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.quoteId = one] : one \in Sample(5) }

(***************************************************************************)
(* Imbalance Message: 72 bytes                                             *)
(***************************************************************************)

ImbalanceMessage ==
    [ time            : Sample(4),
      sequenceNumber  : Sample(4),
      matchQuantity   : Sample(4),
      totalImbalance  : Sample(4),
      marketImbalance : Sample(4),
      price           : Sample(4),
      priceScaleCode  : Sample(1),
      exchangeCode    : Sample(1),
      systemCode      : Sample(1),
      auctionType     : Sample(1),
      flatPricing     : Sample(1),
      tradingAction   : Sample(1),
      securityType    : Sample(1),
      quoteCondition  : Sample(1),
      nyseBondSymbol  : Sample(22),
      cusipIsin       : Sample(14),
      auctionTime     : Sample(4) ]

EncodeImbalanceMessage(message) ==
    message.time
        \o message.sequenceNumber
        \o message.matchQuantity
        \o message.totalImbalance
        \o message.marketImbalance
        \o message.price
        \o message.priceScaleCode
        \o message.exchangeCode
        \o message.systemCode
        \o message.auctionType
        \o message.flatPricing
        \o message.tradingAction
        \o message.securityType
        \o message.quoteCondition
        \o message.nyseBondSymbol
        \o message.cusipIsin
        \o message.auctionTime

DecodeImbalanceMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(time.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET matchQuantity == ReadBytes(sequenceNumber.rest, 4) IN IF ~matchQuantity.ok THEN Fail ELSE
    LET totalImbalance == ReadBytes(matchQuantity.rest, 4) IN IF ~totalImbalance.ok THEN Fail ELSE
    LET marketImbalance == ReadBytes(totalImbalance.rest, 4) IN IF ~marketImbalance.ok THEN Fail ELSE
    LET price == ReadBytes(marketImbalance.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(price.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET systemCode == ReadBytes(exchangeCode.rest, 1) IN IF ~systemCode.ok THEN Fail ELSE
    LET auctionType == ReadBytes(systemCode.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET flatPricing == ReadBytes(auctionType.rest, 1) IN IF ~flatPricing.ok THEN Fail ELSE
    LET tradingAction == ReadBytes(flatPricing.rest, 1) IN IF ~tradingAction.ok THEN Fail ELSE
    LET securityType == ReadBytes(tradingAction.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(securityType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET nyseBondSymbol == ReadBytes(quoteCondition.rest, 22) IN IF ~nyseBondSymbol.ok THEN Fail ELSE
    LET cusipIsin == ReadBytes(nyseBondSymbol.rest, 14) IN IF ~cusipIsin.ok THEN Fail ELSE
    LET auctionTime == ReadBytes(cusipIsin.rest, 4) IN IF ~auctionTime.ok THEN Fail ELSE
    Ok([ time            |-> time.value,
         sequenceNumber  |-> sequenceNumber.value,
         matchQuantity   |-> matchQuantity.value,
         totalImbalance  |-> totalImbalance.value,
         marketImbalance |-> marketImbalance.value,
         price           |-> price.value,
         priceScaleCode  |-> priceScaleCode.value,
         exchangeCode    |-> exchangeCode.value,
         systemCode      |-> systemCode.value,
         auctionType     |-> auctionType.value,
         flatPricing     |-> flatPricing.value,
         tradingAction   |-> tradingAction.value,
         securityType    |-> securityType.value,
         quoteCondition  |-> quoteCondition.value,
         nyseBondSymbol  |-> nyseBondSymbol.value,
         cusipIsin       |-> cusipIsin.value,
         auctionTime     |-> auctionTime.value ], auctionTime.rest)

ZeroImbalanceMessage ==
    [ time            |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      matchQuantity   |-> [i \in 1 .. 4 |-> 0],
      totalImbalance  |-> [i \in 1 .. 4 |-> 0],
      marketImbalance |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode  |-> [i \in 1 .. 1 |-> 0],
      exchangeCode    |-> [i \in 1 .. 1 |-> 0],
      systemCode      |-> [i \in 1 .. 1 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      flatPricing     |-> [i \in 1 .. 1 |-> 0],
      tradingAction   |-> [i \in 1 .. 1 |-> 0],
      securityType    |-> [i \in 1 .. 1 |-> 0],
      quoteCondition  |-> [i \in 1 .. 1 |-> 0],
      nyseBondSymbol  |-> [i \in 1 .. 22 |-> 0],
      cusipIsin       |-> [i \in 1 .. 14 |-> 0],
      auctionTime     |-> [i \in 1 .. 4 |-> 0] ]

(* Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedImbalanceMessage ==
    { ZeroImbalanceMessage }
        \cup { [ZeroImbalanceMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.matchQuantity = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.totalImbalance = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.marketImbalance = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroImbalanceMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.systemCode = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.flatPricing = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.tradingAction = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroImbalanceMessage EXCEPT !.nyseBondSymbol = one] : one \in Sample(22) }
        \cup { [ZeroImbalanceMessage EXCEPT !.cusipIsin = one] : one \in Sample(14) }
        \cup { [ZeroImbalanceMessage EXCEPT !.auctionTime = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 52 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ time                       : Sample(4),
      sequenceNumber             : Sample(4),
      nextExpectedSequenceNumber : Sample(4),
      eventCode                  : Sample(1),
      systemCode                 : Sample(1),
      nyseBondSymbol             : Sample(22),
      cusipIsin                  : Sample(14),
      paddingAscii2              : Sample(2) ]

EncodeSystemEventMessage(message) ==
    message.time
        \o message.sequenceNumber
        \o message.nextExpectedSequenceNumber
        \o message.eventCode
        \o message.systemCode
        \o message.nyseBondSymbol
        \o message.cusipIsin
        \o message.paddingAscii2

DecodeSystemEventMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(time.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET nextExpectedSequenceNumber == ReadBytes(sequenceNumber.rest, 4) IN IF ~nextExpectedSequenceNumber.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nextExpectedSequenceNumber.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET systemCode == ReadBytes(eventCode.rest, 1) IN IF ~systemCode.ok THEN Fail ELSE
    LET nyseBondSymbol == ReadBytes(systemCode.rest, 22) IN IF ~nyseBondSymbol.ok THEN Fail ELSE
    LET cusipIsin == ReadBytes(nyseBondSymbol.rest, 14) IN IF ~cusipIsin.ok THEN Fail ELSE
    LET paddingAscii2 == ReadBytes(cusipIsin.rest, 2) IN IF ~paddingAscii2.ok THEN Fail ELSE
    Ok([ time                       |-> time.value,
         sequenceNumber             |-> sequenceNumber.value,
         nextExpectedSequenceNumber |-> nextExpectedSequenceNumber.value,
         eventCode                  |-> eventCode.value,
         systemCode                 |-> systemCode.value,
         nyseBondSymbol             |-> nyseBondSymbol.value,
         cusipIsin                  |-> cusipIsin.value,
         paddingAscii2              |-> paddingAscii2.value ], paddingAscii2.rest)

ZeroSystemEventMessage ==
    [ time                       |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber             |-> [i \in 1 .. 4 |-> 0],
      nextExpectedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      eventCode                  |-> [i \in 1 .. 1 |-> 0],
      systemCode                 |-> [i \in 1 .. 1 |-> 0],
      nyseBondSymbol             |-> [i \in 1 .. 22 |-> 0],
      cusipIsin                  |-> [i \in 1 .. 14 |-> 0],
      paddingAscii2              |-> [i \in 1 .. 2 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.nextExpectedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.systemCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.nyseBondSymbol = one] : one \in Sample(22) }
        \cup { [ZeroSystemEventMessage EXCEPT !.cusipIsin = one] : one \in Sample(14) }
        \cup { [ZeroSystemEventMessage EXCEPT !.paddingAscii2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginAcceptedMessageCode == 81  \* "Q"
LoginRejectedMessageCode == 82  \* "R"
HeartbeatMessageCode == 72  \* "H"
TestResponseMessageCode == 83  \* "S"
AddOrderMessageCode == 78  \* "N"
ModifyOrderMessageCode == 67  \* "C"
DeleteOrderMessageCode == 75  \* "K"
ImbalanceMessageCode == 87  \* "W"
SystemEventMessageCode == 89  \* "Y"

Payload ==
    [ tag : {LoginAcceptedMessageCode}, body : LoginAcceptedMessage ]
        \cup [ tag : {LoginRejectedMessageCode}, body : LoginRejectedMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestResponseMessageCode}, body : TestResponseMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {ImbalanceMessageCode}, body : ImbalanceMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginAcceptedMessageCode -> EncodeLoginAcceptedMessage(message.body)
      [] message.tag = LoginRejectedMessageCode -> EncodeLoginRejectedMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = TestResponseMessageCode -> EncodeTestResponseMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = ImbalanceMessageCode -> EncodeImbalanceMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginAcceptedMessageCode -> DecodeLoginAcceptedMessage(bytes)
              [] tag = LoginRejectedMessageCode -> DecodeLoginRejectedMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TestResponseMessageCode -> DecodeTestResponseMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = ImbalanceMessageCode -> DecodeImbalanceMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginAcceptedMessageCode, body |-> ZeroLoginAcceptedMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginAcceptedMessageCode, body |-> one] : one \in CheckedLoginAcceptedMessage }
        \cup { [tag |-> LoginRejectedMessageCode, body |-> one] : one \in CheckedLoginRejectedMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestResponseMessageCode, body |-> one] : one \in CheckedTestResponseMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> ImbalanceMessageCode, body |-> one] : one \in CheckedImbalanceMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }

(***************************************************************************)
(* Message, framed by Message Body Length                                  *)
(***************************************************************************)

Message ==
    [ padding : Sample(1),
      payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o message.padding
        \o EncodePayload(message.payload)

(* Message Body Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body) - 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET padding == ReadBytes(messageType.rest, 1) IN IF ~padding.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, padding.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ padding |-> padding.value,
         payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ padding |-> [i \in 1 .. 1 |-> 0],
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.padding = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> LoginAcceptedMessageCode, body |-> ZeroLoginAcceptedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginRejectedMessageCode, body |-> ZeroLoginRejectedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TestResponseMessageCode, body |-> ZeroTestResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderMessageCode, body |-> ZeroModifyOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ImbalanceMessageCode, body |-> ZeroImbalanceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ message : SampleLists(OneMessage) ]

EncodeServerPacket(message) ==
    EncodeMessageList(message.message)

DecodeServerPacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroServerPacket ==
    [ message |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Login Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedMessage ==
    \A message \in CheckedLoginAcceptedMessage :
        LET read == DecodeLoginAcceptedMessage(EncodeLoginAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedMessage ==
    \A message \in CheckedLoginRejectedMessage :
        LET read == DecodeLoginRejectedMessage(EncodeLoginRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTestResponseMessage ==
    \A message \in CheckedTestResponseMessage :
        LET read == DecodeTestResponseMessage(EncodeTestResponseMessage(message))
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

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMessage ==
    \A message \in CheckedDeleteOrderMessage :
        LET read == DecodeDeleteOrderMessage(EncodeDeleteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripImbalanceMessage ==
    \A message \in CheckedImbalanceMessage :
        LET read == DecodeImbalanceMessage(EncodeImbalanceMessage(message))
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

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Body Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 4

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
