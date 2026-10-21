------------------ MODULE NyseBonds_Trades_v1_07_a_Server ------------------
(***************************************************************************)
(* New York Stock Exchange Trades v1.07.a                                  *)
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
(* Last Sale Message: 64 bytes                                             *)
(***************************************************************************)

LastSaleMessage ==
    [ lastSaleTime         : Sample(4),
      sequenceNumber       : Sample(4),
      tradeReferenceNumber : Sample(4),
      quantity             : Sample(4),
      price                : Sample(4),
      priceScaleCode       : Sample(1),
      systemCode           : Sample(1),
      exchangeCode         : Sample(1),
      tradeCondition       : Sample(1),
      securityType         : Sample(1),
      nyseBondSymbol       : Sample(22),
      cusipIsin            : Sample(14),
      paddingAscii3        : Sample(3) ]

EncodeLastSaleMessage(message) ==
    message.lastSaleTime
        \o message.sequenceNumber
        \o message.tradeReferenceNumber
        \o message.quantity
        \o message.price
        \o message.priceScaleCode
        \o message.systemCode
        \o message.exchangeCode
        \o message.tradeCondition
        \o message.securityType
        \o message.nyseBondSymbol
        \o message.cusipIsin
        \o message.paddingAscii3

DecodeLastSaleMessage(bytes) ==
    LET lastSaleTime == ReadBytes(bytes, 4) IN IF ~lastSaleTime.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(lastSaleTime.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET tradeReferenceNumber == ReadBytes(sequenceNumber.rest, 4) IN IF ~tradeReferenceNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeReferenceNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(price.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET systemCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~systemCode.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(systemCode.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(exchangeCode.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET securityType == ReadBytes(tradeCondition.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET nyseBondSymbol == ReadBytes(securityType.rest, 22) IN IF ~nyseBondSymbol.ok THEN Fail ELSE
    LET cusipIsin == ReadBytes(nyseBondSymbol.rest, 14) IN IF ~cusipIsin.ok THEN Fail ELSE
    LET paddingAscii3 == ReadBytes(cusipIsin.rest, 3) IN IF ~paddingAscii3.ok THEN Fail ELSE
    Ok([ lastSaleTime         |-> lastSaleTime.value,
         sequenceNumber       |-> sequenceNumber.value,
         tradeReferenceNumber |-> tradeReferenceNumber.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         priceScaleCode       |-> priceScaleCode.value,
         systemCode           |-> systemCode.value,
         exchangeCode         |-> exchangeCode.value,
         tradeCondition       |-> tradeCondition.value,
         securityType         |-> securityType.value,
         nyseBondSymbol       |-> nyseBondSymbol.value,
         cusipIsin            |-> cusipIsin.value,
         paddingAscii3        |-> paddingAscii3.value ], paddingAscii3.rest)

ZeroLastSaleMessage ==
    [ lastSaleTime         |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      tradeReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      systemCode           |-> [i \in 1 .. 1 |-> 0],
      exchangeCode         |-> [i \in 1 .. 1 |-> 0],
      tradeCondition       |-> [i \in 1 .. 1 |-> 0],
      securityType         |-> [i \in 1 .. 1 |-> 0],
      nyseBondSymbol       |-> [i \in 1 .. 22 |-> 0],
      cusipIsin            |-> [i \in 1 .. 14 |-> 0],
      paddingAscii3        |-> [i \in 1 .. 3 |-> 0] ]

(* Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedLastSaleMessage ==
    { ZeroLastSaleMessage }
        \cup { [ZeroLastSaleMessage EXCEPT !.lastSaleTime = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.tradeReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroLastSaleMessage EXCEPT !.systemCode = one] : one \in Sample(1) }
        \cup { [ZeroLastSaleMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroLastSaleMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroLastSaleMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroLastSaleMessage EXCEPT !.nyseBondSymbol = one] : one \in Sample(22) }
        \cup { [ZeroLastSaleMessage EXCEPT !.cusipIsin = one] : one \in Sample(14) }
        \cup { [ZeroLastSaleMessage EXCEPT !.paddingAscii3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Trade Bust Or Correction Message: 64 bytes                              *)
(***************************************************************************)

TradeBustOrCorrectionMessage ==
    [ lastSaleTime         : Sample(4),
      sequenceNumber       : Sample(4),
      tradeReferenceNumber : Sample(4),
      quantity             : Sample(4),
      price                : Sample(4),
      priceScaleCode       : Sample(1),
      systemCode           : Sample(1),
      eventCode            : Sample(1),
      exchangeCode         : Sample(1),
      tradeCondition       : Sample(1),
      securityType         : Sample(1),
      nyseBondSymbol       : Sample(22),
      cusipIsin            : Sample(14),
      paddingAscii2        : Sample(2) ]

EncodeTradeBustOrCorrectionMessage(message) ==
    message.lastSaleTime
        \o message.sequenceNumber
        \o message.tradeReferenceNumber
        \o message.quantity
        \o message.price
        \o message.priceScaleCode
        \o message.systemCode
        \o message.eventCode
        \o message.exchangeCode
        \o message.tradeCondition
        \o message.securityType
        \o message.nyseBondSymbol
        \o message.cusipIsin
        \o message.paddingAscii2

DecodeTradeBustOrCorrectionMessage(bytes) ==
    LET lastSaleTime == ReadBytes(bytes, 4) IN IF ~lastSaleTime.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(lastSaleTime.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET tradeReferenceNumber == ReadBytes(sequenceNumber.rest, 4) IN IF ~tradeReferenceNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeReferenceNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(price.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET systemCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~systemCode.ok THEN Fail ELSE
    LET eventCode == ReadBytes(systemCode.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(eventCode.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(exchangeCode.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET securityType == ReadBytes(tradeCondition.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET nyseBondSymbol == ReadBytes(securityType.rest, 22) IN IF ~nyseBondSymbol.ok THEN Fail ELSE
    LET cusipIsin == ReadBytes(nyseBondSymbol.rest, 14) IN IF ~cusipIsin.ok THEN Fail ELSE
    LET paddingAscii2 == ReadBytes(cusipIsin.rest, 2) IN IF ~paddingAscii2.ok THEN Fail ELSE
    Ok([ lastSaleTime         |-> lastSaleTime.value,
         sequenceNumber       |-> sequenceNumber.value,
         tradeReferenceNumber |-> tradeReferenceNumber.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         priceScaleCode       |-> priceScaleCode.value,
         systemCode           |-> systemCode.value,
         eventCode            |-> eventCode.value,
         exchangeCode         |-> exchangeCode.value,
         tradeCondition       |-> tradeCondition.value,
         securityType         |-> securityType.value,
         nyseBondSymbol       |-> nyseBondSymbol.value,
         cusipIsin            |-> cusipIsin.value,
         paddingAscii2        |-> paddingAscii2.value ], paddingAscii2.rest)

ZeroTradeBustOrCorrectionMessage ==
    [ lastSaleTime         |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      tradeReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      systemCode           |-> [i \in 1 .. 1 |-> 0],
      eventCode            |-> [i \in 1 .. 1 |-> 0],
      exchangeCode         |-> [i \in 1 .. 1 |-> 0],
      tradeCondition       |-> [i \in 1 .. 1 |-> 0],
      securityType         |-> [i \in 1 .. 1 |-> 0],
      nyseBondSymbol       |-> [i \in 1 .. 22 |-> 0],
      cusipIsin            |-> [i \in 1 .. 14 |-> 0],
      paddingAscii2        |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Bust Or Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustOrCorrectionMessage ==
    { ZeroTradeBustOrCorrectionMessage }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.lastSaleTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.tradeReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.systemCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.nyseBondSymbol = one] : one \in Sample(22) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.cusipIsin = one] : one \in Sample(14) }
        \cup { [ZeroTradeBustOrCorrectionMessage EXCEPT !.paddingAscii2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Nyse Bond Closing Price Message: 64 bytes                               *)
(***************************************************************************)

NyseBondClosingPriceMessage ==
    [ closingTime          : Sample(4),
      sequenceNumber       : Sample(4),
      tradeReferenceNumber : Sample(4),
      quantity             : Sample(4),
      closingPrice         : Sample(4),
      priceScaleCode       : Sample(1),
      systemCode           : Sample(1),
      exchangeCode         : Sample(1),
      tradeCondition       : Sample(1),
      securityType         : Sample(1),
      nyseBondSymbol       : Sample(22),
      cusipIsin            : Sample(14),
      paddingAscii3        : Sample(3) ]

EncodeNyseBondClosingPriceMessage(message) ==
    message.closingTime
        \o message.sequenceNumber
        \o message.tradeReferenceNumber
        \o message.quantity
        \o message.closingPrice
        \o message.priceScaleCode
        \o message.systemCode
        \o message.exchangeCode
        \o message.tradeCondition
        \o message.securityType
        \o message.nyseBondSymbol
        \o message.cusipIsin
        \o message.paddingAscii3

DecodeNyseBondClosingPriceMessage(bytes) ==
    LET closingTime == ReadBytes(bytes, 4) IN IF ~closingTime.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(closingTime.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET tradeReferenceNumber == ReadBytes(sequenceNumber.rest, 4) IN IF ~tradeReferenceNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeReferenceNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(quantity.rest, 4) IN IF ~closingPrice.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(closingPrice.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET systemCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~systemCode.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(systemCode.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(exchangeCode.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET securityType == ReadBytes(tradeCondition.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET nyseBondSymbol == ReadBytes(securityType.rest, 22) IN IF ~nyseBondSymbol.ok THEN Fail ELSE
    LET cusipIsin == ReadBytes(nyseBondSymbol.rest, 14) IN IF ~cusipIsin.ok THEN Fail ELSE
    LET paddingAscii3 == ReadBytes(cusipIsin.rest, 3) IN IF ~paddingAscii3.ok THEN Fail ELSE
    Ok([ closingTime          |-> closingTime.value,
         sequenceNumber       |-> sequenceNumber.value,
         tradeReferenceNumber |-> tradeReferenceNumber.value,
         quantity             |-> quantity.value,
         closingPrice         |-> closingPrice.value,
         priceScaleCode       |-> priceScaleCode.value,
         systemCode           |-> systemCode.value,
         exchangeCode         |-> exchangeCode.value,
         tradeCondition       |-> tradeCondition.value,
         securityType         |-> securityType.value,
         nyseBondSymbol       |-> nyseBondSymbol.value,
         cusipIsin            |-> cusipIsin.value,
         paddingAscii3        |-> paddingAscii3.value ], paddingAscii3.rest)

ZeroNyseBondClosingPriceMessage ==
    [ closingTime          |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      tradeReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      closingPrice         |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      systemCode           |-> [i \in 1 .. 1 |-> 0],
      exchangeCode         |-> [i \in 1 .. 1 |-> 0],
      tradeCondition       |-> [i \in 1 .. 1 |-> 0],
      securityType         |-> [i \in 1 .. 1 |-> 0],
      nyseBondSymbol       |-> [i \in 1 .. 22 |-> 0],
      cusipIsin            |-> [i \in 1 .. 14 |-> 0],
      paddingAscii3        |-> [i \in 1 .. 3 |-> 0] ]

(* Nyse Bond Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedNyseBondClosingPriceMessage ==
    { ZeroNyseBondClosingPriceMessage }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.closingTime = one] : one \in Sample(4) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.tradeReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.closingPrice = one] : one \in Sample(4) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.systemCode = one] : one \in Sample(1) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.nyseBondSymbol = one] : one \in Sample(22) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.cusipIsin = one] : one \in Sample(14) }
        \cup { [ZeroNyseBondClosingPriceMessage EXCEPT !.paddingAscii3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginAcceptedMessageCode == 81  \* "Q"
LoginRejectedMessageCode == 82  \* "R"
HeartbeatMessageCode == 72  \* "H"
TestResponseMessageCode == 83  \* "S"
LastSaleMessageCode == 88  \* "X"
TradeBustOrCorrectionMessageCode == 85  \* "U"
NyseBondClosingPriceMessageCode == 90  \* "Z"

Payload ==
    [ tag : {LoginAcceptedMessageCode}, body : LoginAcceptedMessage ]
        \cup [ tag : {LoginRejectedMessageCode}, body : LoginRejectedMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestResponseMessageCode}, body : TestResponseMessage ]
        \cup [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {TradeBustOrCorrectionMessageCode}, body : TradeBustOrCorrectionMessage ]
        \cup [ tag : {NyseBondClosingPriceMessageCode}, body : NyseBondClosingPriceMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginAcceptedMessageCode -> EncodeLoginAcceptedMessage(message.body)
      [] message.tag = LoginRejectedMessageCode -> EncodeLoginRejectedMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = TestResponseMessageCode -> EncodeTestResponseMessage(message.body)
      [] message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = TradeBustOrCorrectionMessageCode -> EncodeTradeBustOrCorrectionMessage(message.body)
      [] message.tag = NyseBondClosingPriceMessageCode -> EncodeNyseBondClosingPriceMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginAcceptedMessageCode -> DecodeLoginAcceptedMessage(bytes)
              [] tag = LoginRejectedMessageCode -> DecodeLoginRejectedMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TestResponseMessageCode -> DecodeTestResponseMessage(bytes)
              [] tag = LastSaleMessageCode -> DecodeLastSaleMessage(bytes)
              [] tag = TradeBustOrCorrectionMessageCode -> DecodeTradeBustOrCorrectionMessage(bytes)
              [] tag = NyseBondClosingPriceMessageCode -> DecodeNyseBondClosingPriceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginAcceptedMessageCode, body |-> ZeroLoginAcceptedMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginAcceptedMessageCode, body |-> one] : one \in CheckedLoginAcceptedMessage }
        \cup { [tag |-> LoginRejectedMessageCode, body |-> one] : one \in CheckedLoginRejectedMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestResponseMessageCode, body |-> one] : one \in CheckedTestResponseMessage }
        \cup { [tag |-> LastSaleMessageCode, body |-> one] : one \in CheckedLastSaleMessage }
        \cup { [tag |-> TradeBustOrCorrectionMessageCode, body |-> one] : one \in CheckedTradeBustOrCorrectionMessage }
        \cup { [tag |-> NyseBondClosingPriceMessageCode, body |-> one] : one \in CheckedNyseBondClosingPriceMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> LastSaleMessageCode, body |-> ZeroLastSaleMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustOrCorrectionMessageCode, body |-> ZeroTradeBustOrCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NyseBondClosingPriceMessageCode, body |-> ZeroNyseBondClosingPriceMessage]] }

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

(* Every Last Sale Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastSaleMessage ==
    \A message \in CheckedLastSaleMessage :
        LET read == DecodeLastSaleMessage(EncodeLastSaleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Or Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustOrCorrectionMessage ==
    \A message \in CheckedTradeBustOrCorrectionMessage :
        LET read == DecodeTradeBustOrCorrectionMessage(EncodeTradeBustOrCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nyse Bond Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNyseBondClosingPriceMessage ==
    \A message \in CheckedNyseBondClosingPriceMessage :
        LET read == DecodeNyseBondClosingPriceMessage(EncodeNyseBondClosingPriceMessage(message))
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
