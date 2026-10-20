---------------------- MODULE Siac_Opra_Input_v5_0_i -----------------------
(***************************************************************************)
(* The Securities Industry Automation Corporation Input v5.0.i             *)
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
(* Note: Message Data Length states the length of Message Data, which is   *)
(* everything the bytes it frames hold, so Message Data is read as what is *)
(* left of them.                                                           *)
(*                                                                         *)
(* Note: Block Pad Byte pads to a 2 byte boundary: it is read as the bytes *)
(* left to the end of the frame, and the frame's length is trusted to keep *)
(* that boundary.                                                          *)
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
(* Block Timestamp: 8 bytes                                                *)
(***************************************************************************)

BlockTimestamp ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeBlockTimestamp(message) ==
    message.seconds
        \o message.nanoseconds

DecodeBlockTimestamp(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroBlockTimestamp ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Block Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedBlockTimestamp ==
    { ZeroBlockTimestamp }
        \cup { [ZeroBlockTimestamp EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroBlockTimestamp EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Expiration Block: 3 bytes                                               *)
(***************************************************************************)

ExpirationBlock ==
    [ expirationMonth : Sample(1),
      expirationDay   : Sample(1),
      expirationYear  : Sample(1) ]

EncodeExpirationBlock(message) ==
    message.expirationMonth
        \o message.expirationDay
        \o message.expirationYear

DecodeExpirationBlock(bytes) ==
    LET expirationMonth == ReadBytes(bytes, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(expirationDay.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    Ok([ expirationMonth |-> expirationMonth.value,
         expirationDay   |-> expirationDay.value,
         expirationYear  |-> expirationYear.value ], expirationYear.rest)

ZeroExpirationBlock ==
    [ expirationMonth |-> [i \in 1 .. 1 |-> 0],
      expirationDay   |-> [i \in 1 .. 1 |-> 0],
      expirationYear  |-> [i \in 1 .. 1 |-> 0] ]

(* Expiration Block at zero, then each field in turn at the values it is checked at *)
CheckedExpirationBlock ==
    { ZeroExpirationBlock }
        \cup { [ZeroExpirationBlock EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroExpirationBlock EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroExpirationBlock EXCEPT !.expirationYear = one] : one \in Sample(1) }

(***************************************************************************)
(* Equity And Index Last Sale Message: 36 bytes                            *)
(***************************************************************************)

EquityAndIndexLastSaleMessage ==
    [ sessionIndicator            : Sample(1),
      participantReferenceNumber  : Sample(4),
      securitySymbol              : Sample(5),
      reserved1                   : Sample(1),
      expirationBlock             : ExpirationBlock,
      strikePriceDenominatorCode  : Sample(1),
      strikePrice                 : Sample(4),
      volume                      : Sample(4),
      premiumPriceDenominatorCode : Sample(1),
      premiumPrice                : Sample(4),
      tradeIdentifier             : Sample(4),
      reserved4                   : Sample(4) ]

EncodeEquityAndIndexLastSaleMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.reserved1
        \o EncodeExpirationBlock(message.expirationBlock)
        \o message.strikePriceDenominatorCode
        \o message.strikePrice
        \o message.volume
        \o message.premiumPriceDenominatorCode
        \o message.premiumPrice
        \o message.tradeIdentifier
        \o message.reserved4

DecodeEquityAndIndexLastSaleMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(securitySymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET expirationBlock == DecodeExpirationBlock(reserved1.rest) IN IF ~expirationBlock.ok THEN Fail ELSE
    LET strikePriceDenominatorCode == ReadBytes(expirationBlock.rest, 1) IN IF ~strikePriceDenominatorCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(strikePriceDenominatorCode.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET volume == ReadBytes(strikePrice.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET premiumPriceDenominatorCode == ReadBytes(volume.rest, 1) IN IF ~premiumPriceDenominatorCode.ok THEN Fail ELSE
    LET premiumPrice == ReadBytes(premiumPriceDenominatorCode.rest, 4) IN IF ~premiumPrice.ok THEN Fail ELSE
    LET tradeIdentifier == ReadBytes(premiumPrice.rest, 4) IN IF ~tradeIdentifier.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(tradeIdentifier.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ sessionIndicator            |-> sessionIndicator.value,
         participantReferenceNumber  |-> participantReferenceNumber.value,
         securitySymbol              |-> securitySymbol.value,
         reserved1                   |-> reserved1.value,
         expirationBlock             |-> expirationBlock.value,
         strikePriceDenominatorCode  |-> strikePriceDenominatorCode.value,
         strikePrice                 |-> strikePrice.value,
         volume                      |-> volume.value,
         premiumPriceDenominatorCode |-> premiumPriceDenominatorCode.value,
         premiumPrice                |-> premiumPrice.value,
         tradeIdentifier             |-> tradeIdentifier.value,
         reserved4                   |-> reserved4.value ], reserved4.rest)

ZeroEquityAndIndexLastSaleMessage ==
    [ sessionIndicator            |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber  |-> [i \in 1 .. 4 |-> 0],
      securitySymbol              |-> [i \in 1 .. 5 |-> 0],
      reserved1                   |-> [i \in 1 .. 1 |-> 0],
      expirationBlock             |-> ZeroExpirationBlock,
      strikePriceDenominatorCode  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                 |-> [i \in 1 .. 4 |-> 0],
      volume                      |-> [i \in 1 .. 4 |-> 0],
      premiumPriceDenominatorCode |-> [i \in 1 .. 1 |-> 0],
      premiumPrice                |-> [i \in 1 .. 4 |-> 0],
      tradeIdentifier             |-> [i \in 1 .. 4 |-> 0],
      reserved4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Equity And Index Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedEquityAndIndexLastSaleMessage ==
    { ZeroEquityAndIndexLastSaleMessage }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.expirationBlock = one] : one \in CheckedExpirationBlock }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.strikePriceDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.premiumPriceDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.premiumPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.tradeIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexLastSaleMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Equity And Index Last Sale Message Payload, selected by Equity And      *)
(* Index Last Sale Message Type                                            *)
(***************************************************************************)

EquityAndIndexLastSaleMessageCode == 65  \* "A"

EquityAndIndexLastSaleMessagePayload ==
    [ tag : {EquityAndIndexLastSaleMessageCode}, body : EquityAndIndexLastSaleMessage ]

EncodeEquityAndIndexLastSaleMessagePayload(message) ==
    CASE message.tag = EquityAndIndexLastSaleMessageCode -> EncodeEquityAndIndexLastSaleMessage(message.body)

DecodeEquityAndIndexLastSaleMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = EquityAndIndexLastSaleMessageCode -> DecodeEquityAndIndexLastSaleMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroEquityAndIndexLastSaleMessagePayload == [tag |-> EquityAndIndexLastSaleMessageCode, body |-> ZeroEquityAndIndexLastSaleMessage]

(* Each Equity And Index Last Sale Message Payload in turn, at the values the message it names is checked at *)
CheckedEquityAndIndexLastSaleMessagePayload ==
    { [tag |-> EquityAndIndexLastSaleMessageCode, body |-> one] : one \in CheckedEquityAndIndexLastSaleMessage }

(***************************************************************************)
(* Equity And Index Last Sale Category                                     *)
(***************************************************************************)

EquityAndIndexLastSaleCategory ==
    [ equityAndIndexLastSaleMessagePayload : EquityAndIndexLastSaleMessagePayload ]

EncodeEquityAndIndexLastSaleCategory(message) ==
    EncodeUIntBE(message.equityAndIndexLastSaleMessagePayload.tag, 1)
        \o EncodeEquityAndIndexLastSaleMessagePayload(message.equityAndIndexLastSaleMessagePayload)

DecodeEquityAndIndexLastSaleCategory(bytes) ==
    LET equityAndIndexLastSaleMessageType == ReadUIntBE(bytes, 1) IN IF ~equityAndIndexLastSaleMessageType.ok THEN Fail ELSE
    LET equityAndIndexLastSaleMessagePayload == DecodeEquityAndIndexLastSaleMessagePayload(equityAndIndexLastSaleMessageType.value, equityAndIndexLastSaleMessageType.rest) IN IF ~equityAndIndexLastSaleMessagePayload.ok THEN Fail ELSE
    Ok([ equityAndIndexLastSaleMessagePayload |-> equityAndIndexLastSaleMessagePayload.value ], equityAndIndexLastSaleMessagePayload.rest)

ZeroEquityAndIndexLastSaleCategory ==
    [ equityAndIndexLastSaleMessagePayload |-> ZeroEquityAndIndexLastSaleMessagePayload ]

(* Equity And Index Last Sale Category at zero, then each field in turn at the values it is checked at *)
CheckedEquityAndIndexLastSaleCategory ==
    { ZeroEquityAndIndexLastSaleCategory }
        \cup { [ZeroEquityAndIndexLastSaleCategory EXCEPT !.equityAndIndexLastSaleMessagePayload = one] : one \in CheckedEquityAndIndexLastSaleMessagePayload }

(***************************************************************************)
(* Expiration Block: 3 bytes                                               *)
(***************************************************************************)

ExpirationBlock2 ==
    [ expirationMonth : Sample(1),
      expirationDay   : Sample(1),
      expirationYear  : Sample(1) ]

EncodeExpirationBlock2(message) ==
    message.expirationMonth
        \o message.expirationDay
        \o message.expirationYear

DecodeExpirationBlock2(bytes) ==
    LET expirationMonth == ReadBytes(bytes, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(expirationDay.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    Ok([ expirationMonth |-> expirationMonth.value,
         expirationDay   |-> expirationDay.value,
         expirationYear  |-> expirationYear.value ], expirationYear.rest)

ZeroExpirationBlock2 ==
    [ expirationMonth |-> [i \in 1 .. 1 |-> 0],
      expirationDay   |-> [i \in 1 .. 1 |-> 0],
      expirationYear  |-> [i \in 1 .. 1 |-> 0] ]

(* Expiration Block at zero, then each field in turn at the values it is checked at *)
CheckedExpirationBlock2 ==
    { ZeroExpirationBlock2 }
        \cup { [ZeroExpirationBlock2 EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroExpirationBlock2 EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroExpirationBlock2 EXCEPT !.expirationYear = one] : one \in Sample(1) }

(***************************************************************************)
(* Equity And Index End Of Day Summary Message: 65 bytes                   *)
(***************************************************************************)

EquityAndIndexEndOfDaySummaryMessage ==
    [ sessionIndicator               : Sample(1),
      participantReferenceNumber     : Sample(4),
      securitySymbol                 : Sample(5),
      reserved1                      : Sample(1),
      expirationBlock                : ExpirationBlock2,
      strikePriceDenominatorCode     : Sample(1),
      strikePrice                    : Sample(4),
      volume                         : Sample(4),
      openInterestVolume             : Sample(4),
      premiumPriceDenominatorCode    : Sample(1),
      openPrice                      : Sample(4),
      highPrice                      : Sample(4),
      lowPrice                       : Sample(4),
      lastPrice                      : Sample(4),
      netChange                      : Sample(4),
      underlyingPriceDenominatorCode : Sample(1),
      underlyingPrice                : Sample(8),
      bidPrice                       : Sample(4),
      offerPrice                     : Sample(4) ]

EncodeEquityAndIndexEndOfDaySummaryMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.reserved1
        \o EncodeExpirationBlock2(message.expirationBlock)
        \o message.strikePriceDenominatorCode
        \o message.strikePrice
        \o message.volume
        \o message.openInterestVolume
        \o message.premiumPriceDenominatorCode
        \o message.openPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.lastPrice
        \o message.netChange
        \o message.underlyingPriceDenominatorCode
        \o message.underlyingPrice
        \o message.bidPrice
        \o message.offerPrice

DecodeEquityAndIndexEndOfDaySummaryMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(securitySymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET expirationBlock == DecodeExpirationBlock2(reserved1.rest) IN IF ~expirationBlock.ok THEN Fail ELSE
    LET strikePriceDenominatorCode == ReadBytes(expirationBlock.rest, 1) IN IF ~strikePriceDenominatorCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(strikePriceDenominatorCode.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET volume == ReadBytes(strikePrice.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET openInterestVolume == ReadBytes(volume.rest, 4) IN IF ~openInterestVolume.ok THEN Fail ELSE
    LET premiumPriceDenominatorCode == ReadBytes(openInterestVolume.rest, 1) IN IF ~premiumPriceDenominatorCode.ok THEN Fail ELSE
    LET openPrice == ReadBytes(premiumPriceDenominatorCode.rest, 4) IN IF ~openPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPrice.rest, 4) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 4) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lowPrice.rest, 4) IN IF ~lastPrice.ok THEN Fail ELSE
    LET netChange == ReadBytes(lastPrice.rest, 4) IN IF ~netChange.ok THEN Fail ELSE
    LET underlyingPriceDenominatorCode == ReadBytes(netChange.rest, 1) IN IF ~underlyingPriceDenominatorCode.ok THEN Fail ELSE
    LET underlyingPrice == ReadBytes(underlyingPriceDenominatorCode.rest, 8) IN IF ~underlyingPrice.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(underlyingPrice.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidPrice.rest, 4) IN IF ~offerPrice.ok THEN Fail ELSE
    Ok([ sessionIndicator               |-> sessionIndicator.value,
         participantReferenceNumber     |-> participantReferenceNumber.value,
         securitySymbol                 |-> securitySymbol.value,
         reserved1                      |-> reserved1.value,
         expirationBlock                |-> expirationBlock.value,
         strikePriceDenominatorCode     |-> strikePriceDenominatorCode.value,
         strikePrice                    |-> strikePrice.value,
         volume                         |-> volume.value,
         openInterestVolume             |-> openInterestVolume.value,
         premiumPriceDenominatorCode    |-> premiumPriceDenominatorCode.value,
         openPrice                      |-> openPrice.value,
         highPrice                      |-> highPrice.value,
         lowPrice                       |-> lowPrice.value,
         lastPrice                      |-> lastPrice.value,
         netChange                      |-> netChange.value,
         underlyingPriceDenominatorCode |-> underlyingPriceDenominatorCode.value,
         underlyingPrice                |-> underlyingPrice.value,
         bidPrice                       |-> bidPrice.value,
         offerPrice                     |-> offerPrice.value ], offerPrice.rest)

ZeroEquityAndIndexEndOfDaySummaryMessage ==
    [ sessionIndicator               |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber     |-> [i \in 1 .. 4 |-> 0],
      securitySymbol                 |-> [i \in 1 .. 5 |-> 0],
      reserved1                      |-> [i \in 1 .. 1 |-> 0],
      expirationBlock                |-> ZeroExpirationBlock2,
      strikePriceDenominatorCode     |-> [i \in 1 .. 1 |-> 0],
      strikePrice                    |-> [i \in 1 .. 4 |-> 0],
      volume                         |-> [i \in 1 .. 4 |-> 0],
      openInterestVolume             |-> [i \in 1 .. 4 |-> 0],
      premiumPriceDenominatorCode    |-> [i \in 1 .. 1 |-> 0],
      openPrice                      |-> [i \in 1 .. 4 |-> 0],
      highPrice                      |-> [i \in 1 .. 4 |-> 0],
      lowPrice                       |-> [i \in 1 .. 4 |-> 0],
      lastPrice                      |-> [i \in 1 .. 4 |-> 0],
      netChange                      |-> [i \in 1 .. 4 |-> 0],
      underlyingPriceDenominatorCode |-> [i \in 1 .. 1 |-> 0],
      underlyingPrice                |-> [i \in 1 .. 8 |-> 0],
      bidPrice                       |-> [i \in 1 .. 4 |-> 0],
      offerPrice                     |-> [i \in 1 .. 4 |-> 0] ]

(* Equity And Index End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEquityAndIndexEndOfDaySummaryMessage ==
    { ZeroEquityAndIndexEndOfDaySummaryMessage }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.expirationBlock = one] : one \in CheckedExpirationBlock2 }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.strikePriceDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.openInterestVolume = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.premiumPriceDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.openPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.netChange = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.underlyingPriceDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.underlyingPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryMessage EXCEPT !.offerPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Equity And Index End Of Day Summary Message Payload, selected by Equity *)
(* And Index End Of Day Summary Message Type                               *)
(***************************************************************************)

EquityAndIndexEndOfDaySummaryMessageCode == 32  \* " "

EquityAndIndexEndOfDaySummaryMessagePayload ==
    [ tag : {EquityAndIndexEndOfDaySummaryMessageCode}, body : EquityAndIndexEndOfDaySummaryMessage ]

EncodeEquityAndIndexEndOfDaySummaryMessagePayload(message) ==
    CASE message.tag = EquityAndIndexEndOfDaySummaryMessageCode -> EncodeEquityAndIndexEndOfDaySummaryMessage(message.body)

DecodeEquityAndIndexEndOfDaySummaryMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = EquityAndIndexEndOfDaySummaryMessageCode -> DecodeEquityAndIndexEndOfDaySummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroEquityAndIndexEndOfDaySummaryMessagePayload == [tag |-> EquityAndIndexEndOfDaySummaryMessageCode, body |-> ZeroEquityAndIndexEndOfDaySummaryMessage]

(* Each Equity And Index End Of Day Summary Message Payload in turn, at the values the message it names is checked at *)
CheckedEquityAndIndexEndOfDaySummaryMessagePayload ==
    { [tag |-> EquityAndIndexEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedEquityAndIndexEndOfDaySummaryMessage }

(***************************************************************************)
(* Equity And Index End Of Day Summary Category                            *)
(***************************************************************************)

EquityAndIndexEndOfDaySummaryCategory ==
    [ equityAndIndexEndOfDaySummaryMessagePayload : EquityAndIndexEndOfDaySummaryMessagePayload ]

EncodeEquityAndIndexEndOfDaySummaryCategory(message) ==
    EncodeUIntBE(message.equityAndIndexEndOfDaySummaryMessagePayload.tag, 1)
        \o EncodeEquityAndIndexEndOfDaySummaryMessagePayload(message.equityAndIndexEndOfDaySummaryMessagePayload)

DecodeEquityAndIndexEndOfDaySummaryCategory(bytes) ==
    LET equityAndIndexEndOfDaySummaryMessageType == ReadUIntBE(bytes, 1) IN IF ~equityAndIndexEndOfDaySummaryMessageType.ok THEN Fail ELSE
    LET equityAndIndexEndOfDaySummaryMessagePayload == DecodeEquityAndIndexEndOfDaySummaryMessagePayload(equityAndIndexEndOfDaySummaryMessageType.value, equityAndIndexEndOfDaySummaryMessageType.rest) IN IF ~equityAndIndexEndOfDaySummaryMessagePayload.ok THEN Fail ELSE
    Ok([ equityAndIndexEndOfDaySummaryMessagePayload |-> equityAndIndexEndOfDaySummaryMessagePayload.value ], equityAndIndexEndOfDaySummaryMessagePayload.rest)

ZeroEquityAndIndexEndOfDaySummaryCategory ==
    [ equityAndIndexEndOfDaySummaryMessagePayload |-> ZeroEquityAndIndexEndOfDaySummaryMessagePayload ]

(* Equity And Index End Of Day Summary Category at zero, then each field in turn at the values it is checked at *)
CheckedEquityAndIndexEndOfDaySummaryCategory ==
    { ZeroEquityAndIndexEndOfDaySummaryCategory }
        \cup { [ZeroEquityAndIndexEndOfDaySummaryCategory EXCEPT !.equityAndIndexEndOfDaySummaryMessagePayload = one] : one \in CheckedEquityAndIndexEndOfDaySummaryMessagePayload }

(***************************************************************************)
(* Expiration Block: 3 bytes                                               *)
(***************************************************************************)

ExpirationBlock3 ==
    [ expirationMonth : Sample(1),
      expirationDay   : Sample(1),
      expirationYear  : Sample(1) ]

EncodeExpirationBlock3(message) ==
    message.expirationMonth
        \o message.expirationDay
        \o message.expirationYear

DecodeExpirationBlock3(bytes) ==
    LET expirationMonth == ReadBytes(bytes, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(expirationDay.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    Ok([ expirationMonth |-> expirationMonth.value,
         expirationDay   |-> expirationDay.value,
         expirationYear  |-> expirationYear.value ], expirationYear.rest)

ZeroExpirationBlock3 ==
    [ expirationMonth |-> [i \in 1 .. 1 |-> 0],
      expirationDay   |-> [i \in 1 .. 1 |-> 0],
      expirationYear  |-> [i \in 1 .. 1 |-> 0] ]

(* Expiration Block at zero, then each field in turn at the values it is checked at *)
CheckedExpirationBlock3 ==
    { ZeroExpirationBlock3 }
        \cup { [ZeroExpirationBlock3 EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroExpirationBlock3 EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroExpirationBlock3 EXCEPT !.expirationYear = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Equity And Index Quote Message: 36 bytes                           *)
(***************************************************************************)

LongEquityAndIndexQuoteMessage ==
    [ sessionIndicator            : Sample(1),
      participantReferenceNumber  : Sample(4),
      securitySymbol              : Sample(5),
      reserved1                   : Sample(1),
      expirationBlock             : ExpirationBlock3,
      strikePriceDenominatorCode  : Sample(1),
      strikePrice                 : Sample(4),
      premiumPriceDenominatorCode : Sample(1),
      bidPrice                    : Sample(4),
      bidSize                     : Sample(4),
      offerPrice                  : Sample(4),
      offerSize                   : Sample(4) ]

EncodeLongEquityAndIndexQuoteMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.reserved1
        \o EncodeExpirationBlock3(message.expirationBlock)
        \o message.strikePriceDenominatorCode
        \o message.strikePrice
        \o message.premiumPriceDenominatorCode
        \o message.bidPrice
        \o message.bidSize
        \o message.offerPrice
        \o message.offerSize

DecodeLongEquityAndIndexQuoteMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(securitySymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET expirationBlock == DecodeExpirationBlock3(reserved1.rest) IN IF ~expirationBlock.ok THEN Fail ELSE
    LET strikePriceDenominatorCode == ReadBytes(expirationBlock.rest, 1) IN IF ~strikePriceDenominatorCode.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(strikePriceDenominatorCode.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET premiumPriceDenominatorCode == ReadBytes(strikePrice.rest, 1) IN IF ~premiumPriceDenominatorCode.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(premiumPriceDenominatorCode.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidSize.rest, 4) IN IF ~offerPrice.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPrice.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    Ok([ sessionIndicator            |-> sessionIndicator.value,
         participantReferenceNumber  |-> participantReferenceNumber.value,
         securitySymbol              |-> securitySymbol.value,
         reserved1                   |-> reserved1.value,
         expirationBlock             |-> expirationBlock.value,
         strikePriceDenominatorCode  |-> strikePriceDenominatorCode.value,
         strikePrice                 |-> strikePrice.value,
         premiumPriceDenominatorCode |-> premiumPriceDenominatorCode.value,
         bidPrice                    |-> bidPrice.value,
         bidSize                     |-> bidSize.value,
         offerPrice                  |-> offerPrice.value,
         offerSize                   |-> offerSize.value ], offerSize.rest)

ZeroLongEquityAndIndexQuoteMessage ==
    [ sessionIndicator            |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber  |-> [i \in 1 .. 4 |-> 0],
      securitySymbol              |-> [i \in 1 .. 5 |-> 0],
      reserved1                   |-> [i \in 1 .. 1 |-> 0],
      expirationBlock             |-> ZeroExpirationBlock3,
      strikePriceDenominatorCode  |-> [i \in 1 .. 1 |-> 0],
      strikePrice                 |-> [i \in 1 .. 4 |-> 0],
      premiumPriceDenominatorCode |-> [i \in 1 .. 1 |-> 0],
      bidPrice                    |-> [i \in 1 .. 4 |-> 0],
      bidSize                     |-> [i \in 1 .. 4 |-> 0],
      offerPrice                  |-> [i \in 1 .. 4 |-> 0],
      offerSize                   |-> [i \in 1 .. 4 |-> 0] ]

(* Long Equity And Index Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedLongEquityAndIndexQuoteMessage ==
    { ZeroLongEquityAndIndexQuoteMessage }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.expirationBlock = one] : one \in CheckedExpirationBlock3 }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.strikePriceDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.premiumPriceDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.offerPrice = one] : one \in Sample(4) }
        \cup { [ZeroLongEquityAndIndexQuoteMessage EXCEPT !.offerSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Long Equity And Index Quote Message Payload, selected by Long Equity    *)
(* And Index Quote Message Type                                            *)
(***************************************************************************)

LongEquityAndIndexQuoteMessageCode == 32  \* " "

LongEquityAndIndexQuoteMessagePayload ==
    [ tag : {LongEquityAndIndexQuoteMessageCode}, body : LongEquityAndIndexQuoteMessage ]

EncodeLongEquityAndIndexQuoteMessagePayload(message) ==
    CASE message.tag = LongEquityAndIndexQuoteMessageCode -> EncodeLongEquityAndIndexQuoteMessage(message.body)

DecodeLongEquityAndIndexQuoteMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = LongEquityAndIndexQuoteMessageCode -> DecodeLongEquityAndIndexQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroLongEquityAndIndexQuoteMessagePayload == [tag |-> LongEquityAndIndexQuoteMessageCode, body |-> ZeroLongEquityAndIndexQuoteMessage]

(* Each Long Equity And Index Quote Message Payload in turn, at the values the message it names is checked at *)
CheckedLongEquityAndIndexQuoteMessagePayload ==
    { [tag |-> LongEquityAndIndexQuoteMessageCode, body |-> one] : one \in CheckedLongEquityAndIndexQuoteMessage }

(***************************************************************************)
(* Long Equity And Index Quote Category                                    *)
(***************************************************************************)

LongEquityAndIndexQuoteCategory ==
    [ longEquityAndIndexQuoteMessagePayload : LongEquityAndIndexQuoteMessagePayload ]

EncodeLongEquityAndIndexQuoteCategory(message) ==
    EncodeUIntBE(message.longEquityAndIndexQuoteMessagePayload.tag, 1)
        \o EncodeLongEquityAndIndexQuoteMessagePayload(message.longEquityAndIndexQuoteMessagePayload)

DecodeLongEquityAndIndexQuoteCategory(bytes) ==
    LET longEquityAndIndexQuoteMessageType == ReadUIntBE(bytes, 1) IN IF ~longEquityAndIndexQuoteMessageType.ok THEN Fail ELSE
    LET longEquityAndIndexQuoteMessagePayload == DecodeLongEquityAndIndexQuoteMessagePayload(longEquityAndIndexQuoteMessageType.value, longEquityAndIndexQuoteMessageType.rest) IN IF ~longEquityAndIndexQuoteMessagePayload.ok THEN Fail ELSE
    Ok([ longEquityAndIndexQuoteMessagePayload |-> longEquityAndIndexQuoteMessagePayload.value ], longEquityAndIndexQuoteMessagePayload.rest)

ZeroLongEquityAndIndexQuoteCategory ==
    [ longEquityAndIndexQuoteMessagePayload |-> ZeroLongEquityAndIndexQuoteMessagePayload ]

(* Long Equity And Index Quote Category at zero, then each field in turn at the values it is checked at *)
CheckedLongEquityAndIndexQuoteCategory ==
    { ZeroLongEquityAndIndexQuoteCategory }
        \cup { [ZeroLongEquityAndIndexQuoteCategory EXCEPT !.longEquityAndIndexQuoteMessagePayload = one] : one \in CheckedLongEquityAndIndexQuoteMessagePayload }

(***************************************************************************)
(* Expiration Block: 3 bytes                                               *)
(***************************************************************************)

ExpirationBlock4 ==
    [ expirationMonth : Sample(1),
      expirationDay   : Sample(1),
      expirationYear  : Sample(1) ]

EncodeExpirationBlock4(message) ==
    message.expirationMonth
        \o message.expirationDay
        \o message.expirationYear

DecodeExpirationBlock4(bytes) ==
    LET expirationMonth == ReadBytes(bytes, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(expirationDay.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    Ok([ expirationMonth |-> expirationMonth.value,
         expirationDay   |-> expirationDay.value,
         expirationYear  |-> expirationYear.value ], expirationYear.rest)

ZeroExpirationBlock4 ==
    [ expirationMonth |-> [i \in 1 .. 1 |-> 0],
      expirationDay   |-> [i \in 1 .. 1 |-> 0],
      expirationYear  |-> [i \in 1 .. 1 |-> 0] ]

(* Expiration Block at zero, then each field in turn at the values it is checked at *)
CheckedExpirationBlock4 ==
    { ZeroExpirationBlock4 }
        \cup { [ZeroExpirationBlock4 EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroExpirationBlock4 EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroExpirationBlock4 EXCEPT !.expirationYear = one] : one \in Sample(1) }

(***************************************************************************)
(* Short Equity And Index Quote Message: 22 bytes                          *)
(***************************************************************************)

ShortEquityAndIndexQuoteMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4),
      securitySymbolShort        : Sample(4),
      expirationBlock            : ExpirationBlock4,
      strikePriceShort           : Sample(2),
      bidPriceShort              : Sample(2),
      bidSizeShort               : Sample(2),
      offerPriceShort            : Sample(2),
      offerSizeShort             : Sample(2) ]

EncodeShortEquityAndIndexQuoteMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.securitySymbolShort
        \o EncodeExpirationBlock4(message.expirationBlock)
        \o message.strikePriceShort
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.offerPriceShort
        \o message.offerSizeShort

DecodeShortEquityAndIndexQuoteMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbolShort == ReadBytes(participantReferenceNumber.rest, 4) IN IF ~securitySymbolShort.ok THEN Fail ELSE
    LET expirationBlock == DecodeExpirationBlock4(securitySymbolShort.rest) IN IF ~expirationBlock.ok THEN Fail ELSE
    LET strikePriceShort == ReadBytes(expirationBlock.rest, 2) IN IF ~strikePriceShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(strikePriceShort.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET offerPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~offerPriceShort.ok THEN Fail ELSE
    LET offerSizeShort == ReadBytes(offerPriceShort.rest, 2) IN IF ~offerSizeShort.ok THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         securitySymbolShort        |-> securitySymbolShort.value,
         expirationBlock            |-> expirationBlock.value,
         strikePriceShort           |-> strikePriceShort.value,
         bidPriceShort              |-> bidPriceShort.value,
         bidSizeShort               |-> bidSizeShort.value,
         offerPriceShort            |-> offerPriceShort.value,
         offerSizeShort             |-> offerSizeShort.value ], offerSizeShort.rest)

ZeroShortEquityAndIndexQuoteMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      securitySymbolShort        |-> [i \in 1 .. 4 |-> 0],
      expirationBlock            |-> ZeroExpirationBlock4,
      strikePriceShort           |-> [i \in 1 .. 2 |-> 0],
      bidPriceShort              |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort               |-> [i \in 1 .. 2 |-> 0],
      offerPriceShort            |-> [i \in 1 .. 2 |-> 0],
      offerSizeShort             |-> [i \in 1 .. 2 |-> 0] ]

(* Short Equity And Index Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedShortEquityAndIndexQuoteMessage ==
    { ZeroShortEquityAndIndexQuoteMessage }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.securitySymbolShort = one] : one \in Sample(4) }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.expirationBlock = one] : one \in CheckedExpirationBlock4 }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.strikePriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortEquityAndIndexQuoteMessage EXCEPT !.offerSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Short Equity And Index Quote Message Payload, selected by Short Equity  *)
(* And Index Quote Message Type                                            *)
(***************************************************************************)

ShortEquityAndIndexQuoteMessageCode == 32  \* " "

ShortEquityAndIndexQuoteMessagePayload ==
    [ tag : {ShortEquityAndIndexQuoteMessageCode}, body : ShortEquityAndIndexQuoteMessage ]

EncodeShortEquityAndIndexQuoteMessagePayload(message) ==
    CASE message.tag = ShortEquityAndIndexQuoteMessageCode -> EncodeShortEquityAndIndexQuoteMessage(message.body)

DecodeShortEquityAndIndexQuoteMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = ShortEquityAndIndexQuoteMessageCode -> DecodeShortEquityAndIndexQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroShortEquityAndIndexQuoteMessagePayload == [tag |-> ShortEquityAndIndexQuoteMessageCode, body |-> ZeroShortEquityAndIndexQuoteMessage]

(* Each Short Equity And Index Quote Message Payload in turn, at the values the message it names is checked at *)
CheckedShortEquityAndIndexQuoteMessagePayload ==
    { [tag |-> ShortEquityAndIndexQuoteMessageCode, body |-> one] : one \in CheckedShortEquityAndIndexQuoteMessage }

(***************************************************************************)
(* Short Equity And Index Quote Category                                   *)
(***************************************************************************)

ShortEquityAndIndexQuoteCategory ==
    [ shortEquityAndIndexQuoteMessagePayload : ShortEquityAndIndexQuoteMessagePayload ]

EncodeShortEquityAndIndexQuoteCategory(message) ==
    EncodeUIntBE(message.shortEquityAndIndexQuoteMessagePayload.tag, 1)
        \o EncodeShortEquityAndIndexQuoteMessagePayload(message.shortEquityAndIndexQuoteMessagePayload)

DecodeShortEquityAndIndexQuoteCategory(bytes) ==
    LET shortEquityAndIndexQuoteMessageType == ReadUIntBE(bytes, 1) IN IF ~shortEquityAndIndexQuoteMessageType.ok THEN Fail ELSE
    LET shortEquityAndIndexQuoteMessagePayload == DecodeShortEquityAndIndexQuoteMessagePayload(shortEquityAndIndexQuoteMessageType.value, shortEquityAndIndexQuoteMessageType.rest) IN IF ~shortEquityAndIndexQuoteMessagePayload.ok THEN Fail ELSE
    Ok([ shortEquityAndIndexQuoteMessagePayload |-> shortEquityAndIndexQuoteMessagePayload.value ], shortEquityAndIndexQuoteMessagePayload.rest)

ZeroShortEquityAndIndexQuoteCategory ==
    [ shortEquityAndIndexQuoteMessagePayload |-> ZeroShortEquityAndIndexQuoteMessagePayload ]

(* Short Equity And Index Quote Category at zero, then each field in turn at the values it is checked at *)
CheckedShortEquityAndIndexQuoteCategory ==
    { ZeroShortEquityAndIndexQuoteCategory }
        \cup { [ZeroShortEquityAndIndexQuoteCategory EXCEPT !.shortEquityAndIndexQuoteMessagePayload = one] : one \in CheckedShortEquityAndIndexQuoteMessagePayload }

(***************************************************************************)
(* Administrative Message, framed by Message Data Length                   *)
(***************************************************************************)

AdministrativeMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4),
      messageData                : SampleBytes ]

EncodeAdministrativeMessageBody(message) ==
    message.messageData

(* Message Data Length counts the bytes it frames, so it is written from them *)
EncodeAdministrativeMessage(message) ==
    LET body == EncodeAdministrativeMessageBody(message)
    IN  message.sessionIndicator \o message.participantReferenceNumber \o EncodeUIntBE(Len(body), 2) \o body

DecodeAdministrativeMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET length == ReadUIntBE(participantReferenceNumber.rest, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
    IN
    LET messageData == Ok(framed, << >>) IN IF ~messageData.ok THEN Fail ELSE
    IF messageData.rest # << >> THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         messageData                |-> messageData.value ], beyond)

ZeroAdministrativeMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      messageData                |-> << >> ]

(* Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedAdministrativeMessage ==
    { ZeroAdministrativeMessage }
        \cup { [ZeroAdministrativeMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAdministrativeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAdministrativeMessage EXCEPT !.messageData = one] : one \in SampleBytes }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

AdministrativeMessageCode == 32  \* " "

AdministrativeMessagePayload ==
    [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }

(***************************************************************************)
(* Administrative Category                                                 *)
(***************************************************************************)

AdministrativeCategory ==
    [ administrativeMessagePayload : AdministrativeMessagePayload ]

EncodeAdministrativeCategory(message) ==
    EncodeUIntBE(message.administrativeMessagePayload.tag, 1)
        \o EncodeAdministrativeMessagePayload(message.administrativeMessagePayload)

DecodeAdministrativeCategory(bytes) ==
    LET administrativeMessageType == ReadUIntBE(bytes, 1) IN IF ~administrativeMessageType.ok THEN Fail ELSE
    LET administrativeMessagePayload == DecodeAdministrativeMessagePayload(administrativeMessageType.value, administrativeMessageType.rest) IN IF ~administrativeMessagePayload.ok THEN Fail ELSE
    Ok([ administrativeMessagePayload |-> administrativeMessagePayload.value ], administrativeMessagePayload.rest)

ZeroAdministrativeCategory ==
    [ administrativeMessagePayload |-> ZeroAdministrativeMessagePayload ]

(* Administrative Category at zero, then each field in turn at the values it is checked at *)
CheckedAdministrativeCategory ==
    { ZeroAdministrativeCategory }
        \cup { [ZeroAdministrativeCategory EXCEPT !.administrativeMessagePayload = one] : one \in CheckedAdministrativeMessagePayload }

(***************************************************************************)
(* Control Message: 5 bytes                                                *)
(***************************************************************************)

ControlMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4) ]

EncodeControlMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber

DecodeControlMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroControlMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

ControlMessageCode == 67  \* "C"

ControlMessagePayload ==
    [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> ControlMessageCode, body |-> ZeroControlMessage]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }

(***************************************************************************)
(* Control Category                                                        *)
(***************************************************************************)

ControlCategory ==
    [ controlMessagePayload : ControlMessagePayload ]

EncodeControlCategory(message) ==
    EncodeUIntBE(message.controlMessagePayload.tag, 1)
        \o EncodeControlMessagePayload(message.controlMessagePayload)

DecodeControlCategory(bytes) ==
    LET controlMessageType == ReadUIntBE(bytes, 1) IN IF ~controlMessageType.ok THEN Fail ELSE
    LET controlMessagePayload == DecodeControlMessagePayload(controlMessageType.value, controlMessageType.rest) IN IF ~controlMessagePayload.ok THEN Fail ELSE
    Ok([ controlMessagePayload |-> controlMessagePayload.value ], controlMessagePayload.rest)

ZeroControlCategory ==
    [ controlMessagePayload |-> ZeroControlMessagePayload ]

(* Control Category at zero, then each field in turn at the values it is checked at *)
CheckedControlCategory ==
    { ZeroControlCategory }
        \cup { [ZeroControlCategory EXCEPT !.controlMessagePayload = one] : one \in CheckedControlMessagePayload }

(***************************************************************************)
(* Block Sequence Number Status Inquiry Request Message: 13 bytes          *)
(***************************************************************************)

BlockSequenceNumberStatusInquiryRequestMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4),
      reserved4                  : Sample(4),
      secondReserved4            : Sample(4) ]

EncodeBlockSequenceNumberStatusInquiryRequestMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.reserved4
        \o message.secondReserved4

DecodeBlockSequenceNumberStatusInquiryRequestMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(participantReferenceNumber.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET secondReserved4 == ReadBytes(reserved4.rest, 4) IN IF ~secondReserved4.ok THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         reserved4                  |-> reserved4.value,
         secondReserved4            |-> secondReserved4.value ], secondReserved4.rest)

ZeroBlockSequenceNumberStatusInquiryRequestMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      reserved4                  |-> [i \in 1 .. 4 |-> 0],
      secondReserved4            |-> [i \in 1 .. 4 |-> 0] ]

(* Block Sequence Number Status Inquiry Request Message at zero, then each field in turn at the values it is checked at *)
CheckedBlockSequenceNumberStatusInquiryRequestMessage ==
    { ZeroBlockSequenceNumberStatusInquiryRequestMessage }
        \cup { [ZeroBlockSequenceNumberStatusInquiryRequestMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroBlockSequenceNumberStatusInquiryRequestMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroBlockSequenceNumberStatusInquiryRequestMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroBlockSequenceNumberStatusInquiryRequestMessage EXCEPT !.secondReserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Block Sequence Number Status Response Message: 13 bytes                 *)
(***************************************************************************)

BlockSequenceNumberStatusResponseMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4),
      blockSequenceNumber        : Sample(4),
      reserved4                  : Sample(4) ]

EncodeBlockSequenceNumberStatusResponseMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.blockSequenceNumber
        \o message.reserved4

DecodeBlockSequenceNumberStatusResponseMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(participantReferenceNumber.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(blockSequenceNumber.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         blockSequenceNumber        |-> blockSequenceNumber.value,
         reserved4                  |-> reserved4.value ], reserved4.rest)

ZeroBlockSequenceNumberStatusResponseMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      blockSequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      reserved4                  |-> [i \in 1 .. 4 |-> 0] ]

(* Block Sequence Number Status Response Message at zero, then each field in turn at the values it is checked at *)
CheckedBlockSequenceNumberStatusResponseMessage ==
    { ZeroBlockSequenceNumberStatusResponseMessage }
        \cup { [ZeroBlockSequenceNumberStatusResponseMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroBlockSequenceNumberStatusResponseMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroBlockSequenceNumberStatusResponseMessage EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroBlockSequenceNumberStatusResponseMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Message Count Status Inquiry Request Message: 13 bytes                  *)
(***************************************************************************)

MessageCountStatusInquiryRequestMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4),
      reserved8                  : Sample(8) ]

EncodeMessageCountStatusInquiryRequestMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.reserved8

DecodeMessageCountStatusInquiryRequestMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(participantReferenceNumber.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         reserved8                  |-> reserved8.value ], reserved8.rest)

ZeroMessageCountStatusInquiryRequestMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      reserved8                  |-> [i \in 1 .. 8 |-> 0] ]

(* Message Count Status Inquiry Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMessageCountStatusInquiryRequestMessage ==
    { ZeroMessageCountStatusInquiryRequestMessage }
        \cup { [ZeroMessageCountStatusInquiryRequestMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMessageCountStatusInquiryRequestMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroMessageCountStatusInquiryRequestMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Count Status Response Message: 13 bytes                         *)
(***************************************************************************)

MessageCountStatusResponseMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4),
      messageCount               : Sample(8) ]

EncodeMessageCountStatusResponseMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.messageCount

DecodeMessageCountStatusResponseMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadBytes(participantReferenceNumber.rest, 8) IN IF ~messageCount.ok THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         messageCount               |-> messageCount.value ], messageCount.rest)

ZeroMessageCountStatusResponseMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      messageCount               |-> [i \in 1 .. 8 |-> 0] ]

(* Message Count Status Response Message at zero, then each field in turn at the values it is checked at *)
CheckedMessageCountStatusResponseMessage ==
    { ZeroMessageCountStatusResponseMessage }
        \cup { [ZeroMessageCountStatusResponseMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMessageCountStatusResponseMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroMessageCountStatusResponseMessage EXCEPT !.messageCount = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequence Number Status Message Payload, selected by Sequence Number     *)
(* Status Message Type                                                     *)
(***************************************************************************)

BlockSequenceNumberStatusInquiryRequestMessageCode == 76  \* "L"
BlockSequenceNumberStatusResponseMessageCode == 77  \* "M"
MessageCountStatusInquiryRequestMessageCode == 82  \* "R"
MessageCountStatusResponseMessageCode == 83  \* "S"

SequenceNumberStatusMessagePayload ==
    [ tag : {BlockSequenceNumberStatusInquiryRequestMessageCode}, body : BlockSequenceNumberStatusInquiryRequestMessage ]
        \cup [ tag : {BlockSequenceNumberStatusResponseMessageCode}, body : BlockSequenceNumberStatusResponseMessage ]
        \cup [ tag : {MessageCountStatusInquiryRequestMessageCode}, body : MessageCountStatusInquiryRequestMessage ]
        \cup [ tag : {MessageCountStatusResponseMessageCode}, body : MessageCountStatusResponseMessage ]

EncodeSequenceNumberStatusMessagePayload(message) ==
    CASE message.tag = BlockSequenceNumberStatusInquiryRequestMessageCode -> EncodeBlockSequenceNumberStatusInquiryRequestMessage(message.body)
      [] message.tag = BlockSequenceNumberStatusResponseMessageCode -> EncodeBlockSequenceNumberStatusResponseMessage(message.body)
      [] message.tag = MessageCountStatusInquiryRequestMessageCode -> EncodeMessageCountStatusInquiryRequestMessage(message.body)
      [] message.tag = MessageCountStatusResponseMessageCode -> EncodeMessageCountStatusResponseMessage(message.body)

DecodeSequenceNumberStatusMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = BlockSequenceNumberStatusInquiryRequestMessageCode -> DecodeBlockSequenceNumberStatusInquiryRequestMessage(bytes)
              [] tag = BlockSequenceNumberStatusResponseMessageCode -> DecodeBlockSequenceNumberStatusResponseMessage(bytes)
              [] tag = MessageCountStatusInquiryRequestMessageCode -> DecodeMessageCountStatusInquiryRequestMessage(bytes)
              [] tag = MessageCountStatusResponseMessageCode -> DecodeMessageCountStatusResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequenceNumberStatusMessagePayload == [tag |-> BlockSequenceNumberStatusInquiryRequestMessageCode, body |-> ZeroBlockSequenceNumberStatusInquiryRequestMessage]

(* Each Sequence Number Status Message Payload in turn, at the values the message it names is checked at *)
CheckedSequenceNumberStatusMessagePayload ==
    { [tag |-> BlockSequenceNumberStatusInquiryRequestMessageCode, body |-> one] : one \in CheckedBlockSequenceNumberStatusInquiryRequestMessage }
        \cup { [tag |-> BlockSequenceNumberStatusResponseMessageCode, body |-> one] : one \in CheckedBlockSequenceNumberStatusResponseMessage }
        \cup { [tag |-> MessageCountStatusInquiryRequestMessageCode, body |-> one] : one \in CheckedMessageCountStatusInquiryRequestMessage }
        \cup { [tag |-> MessageCountStatusResponseMessageCode, body |-> one] : one \in CheckedMessageCountStatusResponseMessage }

(***************************************************************************)
(* Sequence Number Status Category                                         *)
(***************************************************************************)

SequenceNumberStatusCategory ==
    [ sequenceNumberStatusMessagePayload : SequenceNumberStatusMessagePayload ]

EncodeSequenceNumberStatusCategory(message) ==
    EncodeUIntBE(message.sequenceNumberStatusMessagePayload.tag, 1)
        \o EncodeSequenceNumberStatusMessagePayload(message.sequenceNumberStatusMessagePayload)

DecodeSequenceNumberStatusCategory(bytes) ==
    LET sequenceNumberStatusMessageType == ReadUIntBE(bytes, 1) IN IF ~sequenceNumberStatusMessageType.ok THEN Fail ELSE
    LET sequenceNumberStatusMessagePayload == DecodeSequenceNumberStatusMessagePayload(sequenceNumberStatusMessageType.value, sequenceNumberStatusMessageType.rest) IN IF ~sequenceNumberStatusMessagePayload.ok THEN Fail ELSE
    Ok([ sequenceNumberStatusMessagePayload |-> sequenceNumberStatusMessagePayload.value ], sequenceNumberStatusMessagePayload.rest)

ZeroSequenceNumberStatusCategory ==
    [ sequenceNumberStatusMessagePayload |-> ZeroSequenceNumberStatusMessagePayload ]

(* Sequence Number Status Category at zero, then each field in turn at the values it is checked at *)
CheckedSequenceNumberStatusCategory ==
    { ZeroSequenceNumberStatusCategory }
        \cup { [ZeroSequenceNumberStatusCategory EXCEPT !.sequenceNumberStatusMessagePayload = one] : one \in CheckedSequenceNumberStatusMessagePayload }

(***************************************************************************)
(* Underlying Value Last Sale Message: 20 bytes                            *)
(***************************************************************************)

UnderlyingValueLastSaleMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4),
      securitySymbol             : Sample(5),
      reserved1                  : Sample(1),
      indexValueDenominatorCode  : Sample(1),
      indexValue                 : Sample(4),
      reserved4                  : Sample(4) ]

EncodeUnderlyingValueLastSaleMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.reserved1
        \o message.indexValueDenominatorCode
        \o message.indexValue
        \o message.reserved4

DecodeUnderlyingValueLastSaleMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(securitySymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET indexValueDenominatorCode == ReadBytes(reserved1.rest, 1) IN IF ~indexValueDenominatorCode.ok THEN Fail ELSE
    LET indexValue == ReadBytes(indexValueDenominatorCode.rest, 4) IN IF ~indexValue.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(indexValue.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         securitySymbol             |-> securitySymbol.value,
         reserved1                  |-> reserved1.value,
         indexValueDenominatorCode  |-> indexValueDenominatorCode.value,
         indexValue                 |-> indexValue.value,
         reserved4                  |-> reserved4.value ], reserved4.rest)

ZeroUnderlyingValueLastSaleMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      securitySymbol             |-> [i \in 1 .. 5 |-> 0],
      reserved1                  |-> [i \in 1 .. 1 |-> 0],
      indexValueDenominatorCode  |-> [i \in 1 .. 1 |-> 0],
      indexValue                 |-> [i \in 1 .. 4 |-> 0],
      reserved4                  |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Value Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingValueLastSaleMessage ==
    { ZeroUnderlyingValueLastSaleMessage }
        \cup { [ZeroUnderlyingValueLastSaleMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingValueLastSaleMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingValueLastSaleMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroUnderlyingValueLastSaleMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingValueLastSaleMessage EXCEPT !.indexValueDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingValueLastSaleMessage EXCEPT !.indexValue = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingValueLastSaleMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Underlying Value Bid And Offer Message: 20 bytes                        *)
(***************************************************************************)

UnderlyingValueBidAndOfferMessage ==
    [ sessionIndicator           : Sample(1),
      participantReferenceNumber : Sample(4),
      securitySymbol             : Sample(5),
      reserved1                  : Sample(1),
      indexValueDenominatorCode  : Sample(1),
      bidIndexValue              : Sample(4),
      offerIndexValue            : Sample(4) ]

EncodeUnderlyingValueBidAndOfferMessage(message) ==
    message.sessionIndicator
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.reserved1
        \o message.indexValueDenominatorCode
        \o message.bidIndexValue
        \o message.offerIndexValue

DecodeUnderlyingValueBidAndOfferMessage(bytes) ==
    LET sessionIndicator == ReadBytes(bytes, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(sessionIndicator.rest, 4) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(securitySymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET indexValueDenominatorCode == ReadBytes(reserved1.rest, 1) IN IF ~indexValueDenominatorCode.ok THEN Fail ELSE
    LET bidIndexValue == ReadBytes(indexValueDenominatorCode.rest, 4) IN IF ~bidIndexValue.ok THEN Fail ELSE
    LET offerIndexValue == ReadBytes(bidIndexValue.rest, 4) IN IF ~offerIndexValue.ok THEN Fail ELSE
    Ok([ sessionIndicator           |-> sessionIndicator.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         securitySymbol             |-> securitySymbol.value,
         reserved1                  |-> reserved1.value,
         indexValueDenominatorCode  |-> indexValueDenominatorCode.value,
         bidIndexValue              |-> bidIndexValue.value,
         offerIndexValue            |-> offerIndexValue.value ], offerIndexValue.rest)

ZeroUnderlyingValueBidAndOfferMessage ==
    [ sessionIndicator           |-> [i \in 1 .. 1 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      securitySymbol             |-> [i \in 1 .. 5 |-> 0],
      reserved1                  |-> [i \in 1 .. 1 |-> 0],
      indexValueDenominatorCode  |-> [i \in 1 .. 1 |-> 0],
      bidIndexValue              |-> [i \in 1 .. 4 |-> 0],
      offerIndexValue            |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Value Bid And Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingValueBidAndOfferMessage ==
    { ZeroUnderlyingValueBidAndOfferMessage }
        \cup { [ZeroUnderlyingValueBidAndOfferMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingValueBidAndOfferMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingValueBidAndOfferMessage EXCEPT !.securitySymbol = one] : one \in Sample(5) }
        \cup { [ZeroUnderlyingValueBidAndOfferMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingValueBidAndOfferMessage EXCEPT !.indexValueDenominatorCode = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingValueBidAndOfferMessage EXCEPT !.bidIndexValue = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingValueBidAndOfferMessage EXCEPT !.offerIndexValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Underlying Value Message Message Payload, selected by Underlying Value  *)
(* Message Message Type                                                    *)
(***************************************************************************)

UnderlyingValueLastSaleMessageCode == 32  \* " "
UnderlyingValueBidAndOfferMessageCode == 73  \* "I"

UnderlyingValueMessageMessagePayload ==
    [ tag : {UnderlyingValueLastSaleMessageCode}, body : UnderlyingValueLastSaleMessage ]
        \cup [ tag : {UnderlyingValueBidAndOfferMessageCode}, body : UnderlyingValueBidAndOfferMessage ]

EncodeUnderlyingValueMessageMessagePayload(message) ==
    CASE message.tag = UnderlyingValueLastSaleMessageCode -> EncodeUnderlyingValueLastSaleMessage(message.body)
      [] message.tag = UnderlyingValueBidAndOfferMessageCode -> EncodeUnderlyingValueBidAndOfferMessage(message.body)

DecodeUnderlyingValueMessageMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = UnderlyingValueLastSaleMessageCode -> DecodeUnderlyingValueLastSaleMessage(bytes)
              [] tag = UnderlyingValueBidAndOfferMessageCode -> DecodeUnderlyingValueBidAndOfferMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnderlyingValueMessageMessagePayload == [tag |-> UnderlyingValueLastSaleMessageCode, body |-> ZeroUnderlyingValueLastSaleMessage]

(* Each Underlying Value Message Message Payload in turn, at the values the message it names is checked at *)
CheckedUnderlyingValueMessageMessagePayload ==
    { [tag |-> UnderlyingValueLastSaleMessageCode, body |-> one] : one \in CheckedUnderlyingValueLastSaleMessage }
        \cup { [tag |-> UnderlyingValueBidAndOfferMessageCode, body |-> one] : one \in CheckedUnderlyingValueBidAndOfferMessage }

(***************************************************************************)
(* Underlying Value Message Category                                       *)
(***************************************************************************)

UnderlyingValueMessageCategory ==
    [ underlyingValueMessageMessagePayload : UnderlyingValueMessageMessagePayload ]

EncodeUnderlyingValueMessageCategory(message) ==
    EncodeUIntBE(message.underlyingValueMessageMessagePayload.tag, 1)
        \o EncodeUnderlyingValueMessageMessagePayload(message.underlyingValueMessageMessagePayload)

DecodeUnderlyingValueMessageCategory(bytes) ==
    LET underlyingValueMessageMessageType == ReadUIntBE(bytes, 1) IN IF ~underlyingValueMessageMessageType.ok THEN Fail ELSE
    LET underlyingValueMessageMessagePayload == DecodeUnderlyingValueMessageMessagePayload(underlyingValueMessageMessageType.value, underlyingValueMessageMessageType.rest) IN IF ~underlyingValueMessageMessagePayload.ok THEN Fail ELSE
    Ok([ underlyingValueMessageMessagePayload |-> underlyingValueMessageMessagePayload.value ], underlyingValueMessageMessagePayload.rest)

ZeroUnderlyingValueMessageCategory ==
    [ underlyingValueMessageMessagePayload |-> ZeroUnderlyingValueMessageMessagePayload ]

(* Underlying Value Message Category at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingValueMessageCategory ==
    { ZeroUnderlyingValueMessageCategory }
        \cup { [ZeroUnderlyingValueMessageCategory EXCEPT !.underlyingValueMessageMessagePayload = one] : one \in CheckedUnderlyingValueMessageMessagePayload }

(***************************************************************************)
(* Payload, selected by Message Category                                   *)
(***************************************************************************)

EquityAndIndexLastSaleCategoryCode == 97  \* "a"
EquityAndIndexEndOfDaySummaryCategoryCode == 102  \* "f"
LongEquityAndIndexQuoteCategoryCode == 107  \* "k"
ShortEquityAndIndexQuoteCategoryCode == 113  \* "q"
AdministrativeCategoryCode == 67  \* "C"
ControlCategoryCode == 72  \* "H"
SequenceNumberStatusCategoryCode == 78  \* "N"
UnderlyingValueMessageCategoryCode == 89  \* "Y"

Payload ==
    [ tag : {EquityAndIndexLastSaleCategoryCode}, body : EquityAndIndexLastSaleCategory ]
        \cup [ tag : {EquityAndIndexEndOfDaySummaryCategoryCode}, body : EquityAndIndexEndOfDaySummaryCategory ]
        \cup [ tag : {LongEquityAndIndexQuoteCategoryCode}, body : LongEquityAndIndexQuoteCategory ]
        \cup [ tag : {ShortEquityAndIndexQuoteCategoryCode}, body : ShortEquityAndIndexQuoteCategory ]
        \cup [ tag : {AdministrativeCategoryCode}, body : AdministrativeCategory ]
        \cup [ tag : {ControlCategoryCode}, body : ControlCategory ]
        \cup [ tag : {SequenceNumberStatusCategoryCode}, body : SequenceNumberStatusCategory ]
        \cup [ tag : {UnderlyingValueMessageCategoryCode}, body : UnderlyingValueMessageCategory ]

EncodePayload(message) ==
    CASE message.tag = EquityAndIndexLastSaleCategoryCode -> EncodeEquityAndIndexLastSaleCategory(message.body)
      [] message.tag = EquityAndIndexEndOfDaySummaryCategoryCode -> EncodeEquityAndIndexEndOfDaySummaryCategory(message.body)
      [] message.tag = LongEquityAndIndexQuoteCategoryCode -> EncodeLongEquityAndIndexQuoteCategory(message.body)
      [] message.tag = ShortEquityAndIndexQuoteCategoryCode -> EncodeShortEquityAndIndexQuoteCategory(message.body)
      [] message.tag = AdministrativeCategoryCode -> EncodeAdministrativeCategory(message.body)
      [] message.tag = ControlCategoryCode -> EncodeControlCategory(message.body)
      [] message.tag = SequenceNumberStatusCategoryCode -> EncodeSequenceNumberStatusCategory(message.body)
      [] message.tag = UnderlyingValueMessageCategoryCode -> EncodeUnderlyingValueMessageCategory(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = EquityAndIndexLastSaleCategoryCode -> DecodeEquityAndIndexLastSaleCategory(bytes)
              [] tag = EquityAndIndexEndOfDaySummaryCategoryCode -> DecodeEquityAndIndexEndOfDaySummaryCategory(bytes)
              [] tag = LongEquityAndIndexQuoteCategoryCode -> DecodeLongEquityAndIndexQuoteCategory(bytes)
              [] tag = ShortEquityAndIndexQuoteCategoryCode -> DecodeShortEquityAndIndexQuoteCategory(bytes)
              [] tag = AdministrativeCategoryCode -> DecodeAdministrativeCategory(bytes)
              [] tag = ControlCategoryCode -> DecodeControlCategory(bytes)
              [] tag = SequenceNumberStatusCategoryCode -> DecodeSequenceNumberStatusCategory(bytes)
              [] tag = UnderlyingValueMessageCategoryCode -> DecodeUnderlyingValueMessageCategory(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> EquityAndIndexLastSaleCategoryCode, body |-> ZeroEquityAndIndexLastSaleCategory]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> EquityAndIndexLastSaleCategoryCode, body |-> one] : one \in CheckedEquityAndIndexLastSaleCategory }
        \cup { [tag |-> EquityAndIndexEndOfDaySummaryCategoryCode, body |-> one] : one \in CheckedEquityAndIndexEndOfDaySummaryCategory }
        \cup { [tag |-> LongEquityAndIndexQuoteCategoryCode, body |-> one] : one \in CheckedLongEquityAndIndexQuoteCategory }
        \cup { [tag |-> ShortEquityAndIndexQuoteCategoryCode, body |-> one] : one \in CheckedShortEquityAndIndexQuoteCategory }
        \cup { [tag |-> AdministrativeCategoryCode, body |-> one] : one \in CheckedAdministrativeCategory }
        \cup { [tag |-> ControlCategoryCode, body |-> one] : one \in CheckedControlCategory }
        \cup { [tag |-> SequenceNumberStatusCategoryCode, body |-> one] : one \in CheckedSequenceNumberStatusCategory }
        \cup { [tag |-> UnderlyingValueMessageCategoryCode, body |-> one] : one \in CheckedUnderlyingValueMessageCategory }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ participantId : Sample(1),
      payload       : Payload ]

EncodeMessage(message) ==
    message.participantId
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(participantId.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET payload == DecodePayload(messageCategory.value, messageCategory.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ participantId |-> participantId.value,
         payload       |-> payload.value ], payload.rest)

ZeroMessage ==
    [ participantId |-> [i \in 1 .. 1 |-> 0],
      payload       |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.participantId = one] : one \in Sample(1) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> EquityAndIndexLastSaleCategoryCode, body |-> ZeroEquityAndIndexLastSaleCategory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EquityAndIndexEndOfDaySummaryCategoryCode, body |-> ZeroEquityAndIndexEndOfDaySummaryCategory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongEquityAndIndexQuoteCategoryCode, body |-> ZeroLongEquityAndIndexQuoteCategory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ShortEquityAndIndexQuoteCategoryCode, body |-> ZeroShortEquityAndIndexQuoteCategory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdministrativeCategoryCode, body |-> ZeroAdministrativeCategory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ControlCategoryCode, body |-> ZeroControlCategory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceNumberStatusCategoryCode, body |-> ZeroSequenceNumberStatusCategory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnderlyingValueMessageCategoryCode, body |-> ZeroUnderlyingValueMessageCategory]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ blockSeparator      : Sample(2),
      version             : Sample(1),
      blockSize           : Sample(2),
      reserved            : Sample(1),
      secondReserved      : Sample(1),
      thirdReserved       : Sample(1),
      blockSequenceNumber : Sample(4),
      blockTimestamp      : BlockTimestamp,
      blockChecksum       : Sample(2),
      message             : SampleLists(OneMessage),
      blockPadByte        : SampleBytes ]

EncodePacket(message) ==
    message.blockSeparator
        \o message.version
        \o message.blockSize
        \o message.reserved
        \o message.secondReserved
        \o message.thirdReserved
        \o message.blockSequenceNumber
        \o EncodeUIntBE(Len(message.message), 1)
        \o EncodeBlockTimestamp(message.blockTimestamp)
        \o message.blockChecksum
        \o EncodeMessageList(message.message)
        \o message.blockPadByte

DecodePacket(bytes) ==
    LET blockSeparator == ReadBytes(bytes, 2) IN IF ~blockSeparator.ok THEN Fail ELSE
    LET version == ReadBytes(blockSeparator.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET blockSize == ReadBytes(version.rest, 2) IN IF ~blockSize.ok THEN Fail ELSE
    LET reserved == ReadBytes(blockSize.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET secondReserved == ReadBytes(reserved.rest, 1) IN IF ~secondReserved.ok THEN Fail ELSE
    LET thirdReserved == ReadBytes(secondReserved.rest, 1) IN IF ~thirdReserved.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(thirdReserved.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET messagesInBlock == ReadUIntBE(blockSequenceNumber.rest, 1) IN IF ~messagesInBlock.ok THEN Fail ELSE
    LET blockTimestamp == DecodeBlockTimestamp(messagesInBlock.rest) IN IF ~blockTimestamp.ok THEN Fail ELSE
    LET blockChecksum == ReadBytes(blockTimestamp.rest, 2) IN IF ~blockChecksum.ok THEN Fail ELSE
    LET message == ReadMessageList(blockChecksum.rest, messagesInBlock.value) IN IF ~message.ok THEN Fail ELSE
    LET blockPadByte == Ok(message.rest, << >>) IN IF ~blockPadByte.ok THEN Fail ELSE
    Ok([ blockSeparator      |-> blockSeparator.value,
         version             |-> version.value,
         blockSize           |-> blockSize.value,
         reserved            |-> reserved.value,
         secondReserved      |-> secondReserved.value,
         thirdReserved       |-> thirdReserved.value,
         blockSequenceNumber |-> blockSequenceNumber.value,
         blockTimestamp      |-> blockTimestamp.value,
         blockChecksum       |-> blockChecksum.value,
         message             |-> message.value,
         blockPadByte        |-> blockPadByte.value ], blockPadByte.rest)

ZeroPacket ==
    [ blockSeparator      |-> [i \in 1 .. 2 |-> 0],
      version             |-> [i \in 1 .. 1 |-> 0],
      blockSize           |-> [i \in 1 .. 2 |-> 0],
      reserved            |-> [i \in 1 .. 1 |-> 0],
      secondReserved      |-> [i \in 1 .. 1 |-> 0],
      thirdReserved       |-> [i \in 1 .. 1 |-> 0],
      blockSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      blockTimestamp      |-> ZeroBlockTimestamp,
      blockChecksum       |-> [i \in 1 .. 2 |-> 0],
      message             |-> << >>,
      blockPadByte        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.blockSeparator = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.secondReserved = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.thirdReserved = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.blockTimestamp = one] : one \in CheckedBlockTimestamp }
        \cup { [ZeroPacket EXCEPT !.blockChecksum = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }
        \cup { [ZeroPacket EXCEPT !.blockPadByte = one] : one \in SampleBytes }

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

(* Every Block Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripBlockTimestamp ==
    \A message \in CheckedBlockTimestamp :
        LET read == DecodeBlockTimestamp(EncodeBlockTimestamp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expiration Block decodes back to what was encoded, and leaves nothing over *)
RoundTripExpirationBlock ==
    \A message \in CheckedExpirationBlock :
        LET read == DecodeExpirationBlock(EncodeExpirationBlock(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equity And Index Last Sale Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityAndIndexLastSaleMessage ==
    \A message \in CheckedEquityAndIndexLastSaleMessage :
        LET read == DecodeEquityAndIndexLastSaleMessage(EncodeEquityAndIndexLastSaleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equity And Index Last Sale Category decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityAndIndexLastSaleCategory ==
    \A message \in CheckedEquityAndIndexLastSaleCategory :
        LET read == DecodeEquityAndIndexLastSaleCategory(EncodeEquityAndIndexLastSaleCategory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expiration Block decodes back to what was encoded, and leaves nothing over *)
RoundTripExpirationBlock2 ==
    \A message \in CheckedExpirationBlock2 :
        LET read == DecodeExpirationBlock2(EncodeExpirationBlock2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equity And Index End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityAndIndexEndOfDaySummaryMessage ==
    \A message \in CheckedEquityAndIndexEndOfDaySummaryMessage :
        LET read == DecodeEquityAndIndexEndOfDaySummaryMessage(EncodeEquityAndIndexEndOfDaySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equity And Index End Of Day Summary Category decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityAndIndexEndOfDaySummaryCategory ==
    \A message \in CheckedEquityAndIndexEndOfDaySummaryCategory :
        LET read == DecodeEquityAndIndexEndOfDaySummaryCategory(EncodeEquityAndIndexEndOfDaySummaryCategory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expiration Block decodes back to what was encoded, and leaves nothing over *)
RoundTripExpirationBlock3 ==
    \A message \in CheckedExpirationBlock3 :
        LET read == DecodeExpirationBlock3(EncodeExpirationBlock3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Equity And Index Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongEquityAndIndexQuoteMessage ==
    \A message \in CheckedLongEquityAndIndexQuoteMessage :
        LET read == DecodeLongEquityAndIndexQuoteMessage(EncodeLongEquityAndIndexQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Equity And Index Quote Category decodes back to what was encoded, and leaves nothing over *)
RoundTripLongEquityAndIndexQuoteCategory ==
    \A message \in CheckedLongEquityAndIndexQuoteCategory :
        LET read == DecodeLongEquityAndIndexQuoteCategory(EncodeLongEquityAndIndexQuoteCategory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expiration Block decodes back to what was encoded, and leaves nothing over *)
RoundTripExpirationBlock4 ==
    \A message \in CheckedExpirationBlock4 :
        LET read == DecodeExpirationBlock4(EncodeExpirationBlock4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Equity And Index Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortEquityAndIndexQuoteMessage ==
    \A message \in CheckedShortEquityAndIndexQuoteMessage :
        LET read == DecodeShortEquityAndIndexQuoteMessage(EncodeShortEquityAndIndexQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Equity And Index Quote Category decodes back to what was encoded, and leaves nothing over *)
RoundTripShortEquityAndIndexQuoteCategory ==
    \A message \in CheckedShortEquityAndIndexQuoteCategory :
        LET read == DecodeShortEquityAndIndexQuoteCategory(EncodeShortEquityAndIndexQuoteCategory(message))
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

(* Every Administrative Category decodes back to what was encoded, and leaves nothing over *)
RoundTripAdministrativeCategory ==
    \A message \in CheckedAdministrativeCategory :
        LET read == DecodeAdministrativeCategory(EncodeAdministrativeCategory(message))
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

(* Every Control Category decodes back to what was encoded, and leaves nothing over *)
RoundTripControlCategory ==
    \A message \in CheckedControlCategory :
        LET read == DecodeControlCategory(EncodeControlCategory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Block Sequence Number Status Inquiry Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBlockSequenceNumberStatusInquiryRequestMessage ==
    \A message \in CheckedBlockSequenceNumberStatusInquiryRequestMessage :
        LET read == DecodeBlockSequenceNumberStatusInquiryRequestMessage(EncodeBlockSequenceNumberStatusInquiryRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Block Sequence Number Status Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBlockSequenceNumberStatusResponseMessage ==
    \A message \in CheckedBlockSequenceNumberStatusResponseMessage :
        LET read == DecodeBlockSequenceNumberStatusResponseMessage(EncodeBlockSequenceNumberStatusResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Count Status Inquiry Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageCountStatusInquiryRequestMessage ==
    \A message \in CheckedMessageCountStatusInquiryRequestMessage :
        LET read == DecodeMessageCountStatusInquiryRequestMessage(EncodeMessageCountStatusInquiryRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Count Status Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageCountStatusResponseMessage ==
    \A message \in CheckedMessageCountStatusResponseMessage :
        LET read == DecodeMessageCountStatusResponseMessage(EncodeMessageCountStatusResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Number Status Category decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceNumberStatusCategory ==
    \A message \in CheckedSequenceNumberStatusCategory :
        LET read == DecodeSequenceNumberStatusCategory(EncodeSequenceNumberStatusCategory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Value Last Sale Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingValueLastSaleMessage ==
    \A message \in CheckedUnderlyingValueLastSaleMessage :
        LET read == DecodeUnderlyingValueLastSaleMessage(EncodeUnderlyingValueLastSaleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Value Bid And Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingValueBidAndOfferMessage ==
    \A message \in CheckedUnderlyingValueBidAndOfferMessage :
        LET read == DecodeUnderlyingValueBidAndOfferMessage(EncodeUnderlyingValueBidAndOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Value Message Category decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingValueMessageCategory ==
    \A message \in CheckedUnderlyingValueMessageCategory :
        LET read == DecodeUnderlyingValueMessageCategory(EncodeUnderlyingValueMessageCategory(message))
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

(* A Equity And Index Last Sale Message Payload is selected by the Equity And Index Last Sale Message Type it is written under *)
SelectsEquityAndIndexLastSaleMessagePayload ==
    \A message \in CheckedEquityAndIndexLastSaleMessagePayload :
        LET read == DecodeEquityAndIndexLastSaleMessagePayload(message.tag, EncodeEquityAndIndexLastSaleMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Equity And Index End Of Day Summary Message Payload is selected by the Equity And Index End Of Day Summary Message Type it is written under *)
SelectsEquityAndIndexEndOfDaySummaryMessagePayload ==
    \A message \in CheckedEquityAndIndexEndOfDaySummaryMessagePayload :
        LET read == DecodeEquityAndIndexEndOfDaySummaryMessagePayload(message.tag, EncodeEquityAndIndexEndOfDaySummaryMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Long Equity And Index Quote Message Payload is selected by the Long Equity And Index Quote Message Type it is written under *)
SelectsLongEquityAndIndexQuoteMessagePayload ==
    \A message \in CheckedLongEquityAndIndexQuoteMessagePayload :
        LET read == DecodeLongEquityAndIndexQuoteMessagePayload(message.tag, EncodeLongEquityAndIndexQuoteMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Short Equity And Index Quote Message Payload is selected by the Short Equity And Index Quote Message Type it is written under *)
SelectsShortEquityAndIndexQuoteMessagePayload ==
    \A message \in CheckedShortEquityAndIndexQuoteMessagePayload :
        LET read == DecodeShortEquityAndIndexQuoteMessagePayload(message.tag, EncodeShortEquityAndIndexQuoteMessagePayload(message))
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

(* A Sequence Number Status Message Payload is selected by the Sequence Number Status Message Type it is written under *)
SelectsSequenceNumberStatusMessagePayload ==
    \A message \in CheckedSequenceNumberStatusMessagePayload :
        LET read == DecodeSequenceNumberStatusMessagePayload(message.tag, EncodeSequenceNumberStatusMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Underlying Value Message Message Payload is selected by the Underlying Value Message Message Type it is written under *)
SelectsUnderlyingValueMessageMessagePayload ==
    \A message \in CheckedUnderlyingValueMessageMessagePayload :
        LET read == DecodeUnderlyingValueMessageMessagePayload(message.tag, EncodeUnderlyingValueMessageMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Message Category it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Data Length is written from the bytes it frames *)
FramesAdministrativeMessage ==
    \A message \in CheckedAdministrativeMessage :
        LET bytes == EncodeAdministrativeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 6, 7)) = Len(bytes) - 7

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
