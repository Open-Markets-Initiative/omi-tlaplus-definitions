------------------ MODULE EdgxOptions_AuctionFeed_v1_1_39 ------------------
(***************************************************************************)
(* Chicago Board Options Exchange Auction Feed v1.1.39                     *)
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
(* Time Message: 4 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ time : Sample(4) ]

EncodeTimeMessage(message) ==
    message.time

DecodeTimeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroTimeMessage ==
    [ time |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.time = one] : one \in Sample(4) }

(***************************************************************************)
(* Unit Clear Message: 4 bytes                                             *)
(***************************************************************************)

UnitClearMessage ==
    [ timeOffset : Sample(4) ]

EncodeUnitClearMessage(message) ==
    message.timeOffset

DecodeUnitClearMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroUnitClearMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedUnitClearMessage ==
    { ZeroUnitClearMessage }
        \cup { [ZeroUnitClearMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Notification Message: 45 bytes                                  *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ timeOffset        : Sample(4),
      symbol            : Sample(6),
      auctionId         : Sample(8),
      auctionType       : Sample(1),
      side              : Sample(1),
      price             : Sample(8),
      contracts         : Sample(4),
      customerIndicator : Sample(1),
      participantId     : Sample(4),
      auctionEndOffset  : Sample(4),
      clientId          : Sample(4) ]

EncodeAuctionNotificationMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.auctionId
        \o message.auctionType
        \o message.side
        \o message.price
        \o message.contracts
        \o message.customerIndicator
        \o message.participantId
        \o message.auctionEndOffset
        \o message.clientId

DecodeAuctionNotificationMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(symbol.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET side == ReadBytes(auctionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(contracts.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET participantId == ReadBytes(customerIndicator.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET auctionEndOffset == ReadBytes(participantId.rest, 4) IN IF ~auctionEndOffset.ok THEN Fail ELSE
    LET clientId == ReadBytes(auctionEndOffset.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         symbol            |-> symbol.value,
         auctionId         |-> auctionId.value,
         auctionType       |-> auctionType.value,
         side              |-> side.value,
         price             |-> price.value,
         contracts         |-> contracts.value,
         customerIndicator |-> customerIndicator.value,
         participantId     |-> participantId.value,
         auctionEndOffset  |-> auctionEndOffset.value,
         clientId          |-> clientId.value ], clientId.rest)

ZeroAuctionNotificationMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      symbol            |-> [i \in 1 .. 6 |-> 0],
      auctionId         |-> [i \in 1 .. 8 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      contracts         |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      auctionEndOffset  |-> [i \in 1 .. 4 |-> 0],
      clientId          |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionEndOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.clientId = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Cancel Message: 12 bytes                                        *)
(***************************************************************************)

AuctionCancelMessage ==
    [ timeOffset : Sample(4),
      auctionId  : Sample(8) ]

EncodeAuctionCancelMessage(message) ==
    message.timeOffset
        \o message.auctionId

DecodeAuctionCancelMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         auctionId  |-> auctionId.value ], auctionId.rest)

ZeroAuctionCancelMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      auctionId  |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCancelMessage ==
    { ZeroAuctionCancelMessage }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.auctionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Trade Message: 32 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ timeOffset  : Sample(4),
      auctionId   : Sample(8),
      executionId : Sample(8),
      price       : Sample(8),
      contracts   : Sample(4) ]

EncodeAuctionTradeMessage(message) ==
    message.timeOffset
        \o message.auctionId
        \o message.executionId
        \o message.price
        \o message.contracts

DecodeAuctionTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET executionId == ReadBytes(auctionId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET price == ReadBytes(executionId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         auctionId   |-> auctionId.value,
         executionId |-> executionId.value,
         price       |-> price.value,
         contracts   |-> contracts.value ], contracts.rest)

ZeroAuctionTradeMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      auctionId   |-> [i \in 1 .. 8 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      contracts   |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.contracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Auction Update Message: 62 bytes                                *)
(***************************************************************************)

OptionsAuctionUpdateMessage ==
    [ timeOffset                : Sample(4),
      expandedSymbol            : Sample(8),
      auctionType               : Sample(1),
      referencePrice            : Sample(8),
      buyContracts              : Sample(4),
      sellContracts             : Sample(4),
      indicativePrice           : Sample(8),
      auctionOnlyPrice          : Sample(8),
      openingCondition          : Sample(1),
      compositeMarketBidPrice   : Sample(8),
      compositeMarketOfferPrice : Sample(8) ]

EncodeOptionsAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.expandedSymbol
        \o message.auctionType
        \o message.referencePrice
        \o message.buyContracts
        \o message.sellContracts
        \o message.indicativePrice
        \o message.auctionOnlyPrice
        \o message.openingCondition
        \o message.compositeMarketBidPrice
        \o message.compositeMarketOfferPrice

DecodeOptionsAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(expandedSymbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET buyContracts == ReadBytes(referencePrice.rest, 4) IN IF ~buyContracts.ok THEN Fail ELSE
    LET sellContracts == ReadBytes(buyContracts.rest, 4) IN IF ~sellContracts.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellContracts.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    LET openingCondition == ReadBytes(auctionOnlyPrice.rest, 1) IN IF ~openingCondition.ok THEN Fail ELSE
    LET compositeMarketBidPrice == ReadBytes(openingCondition.rest, 8) IN IF ~compositeMarketBidPrice.ok THEN Fail ELSE
    LET compositeMarketOfferPrice == ReadBytes(compositeMarketBidPrice.rest, 8) IN IF ~compositeMarketOfferPrice.ok THEN Fail ELSE
    Ok([ timeOffset                |-> timeOffset.value,
         expandedSymbol            |-> expandedSymbol.value,
         auctionType               |-> auctionType.value,
         referencePrice            |-> referencePrice.value,
         buyContracts              |-> buyContracts.value,
         sellContracts             |-> sellContracts.value,
         indicativePrice           |-> indicativePrice.value,
         auctionOnlyPrice          |-> auctionOnlyPrice.value,
         openingCondition          |-> openingCondition.value,
         compositeMarketBidPrice   |-> compositeMarketBidPrice.value,
         compositeMarketOfferPrice |-> compositeMarketOfferPrice.value ], compositeMarketOfferPrice.rest)

ZeroOptionsAuctionUpdateMessage ==
    [ timeOffset                |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol            |-> [i \in 1 .. 8 |-> 0],
      auctionType               |-> [i \in 1 .. 1 |-> 0],
      referencePrice            |-> [i \in 1 .. 8 |-> 0],
      buyContracts              |-> [i \in 1 .. 4 |-> 0],
      sellContracts             |-> [i \in 1 .. 4 |-> 0],
      indicativePrice           |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice          |-> [i \in 1 .. 8 |-> 0],
      openingCondition          |-> [i \in 1 .. 1 |-> 0],
      compositeMarketBidPrice   |-> [i \in 1 .. 8 |-> 0],
      compositeMarketOfferPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Options Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsAuctionUpdateMessage ==
    { ZeroOptionsAuctionUpdateMessage }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.buyContracts = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.sellContracts = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.openingCondition = one] : one \in Sample(1) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.compositeMarketBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.compositeMarketOfferPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Summary Message: 25 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timeOffset     : Sample(4),
      expandedSymbol : Sample(8),
      auctionType    : Sample(1),
      price          : Sample(8),
      quantity       : Sample(4) ]

EncodeAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.expandedSymbol
        \o message.auctionType
        \o message.price
        \o message.quantity

DecodeAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(expandedSymbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         expandedSymbol |-> expandedSymbol.value,
         auctionType    |-> auctionType.value,
         price          |-> price.value,
         quantity       |-> quantity.value ], quantity.rest)

ZeroAuctionSummaryMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol |-> [i \in 1 .. 8 |-> 0],
      auctionType    |-> [i \in 1 .. 1 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Width Update Message: 17 bytes                                          *)
(***************************************************************************)

WidthUpdateMessage ==
    [ timeOffset : Sample(4),
      underlying : Sample(8),
      widthType  : Sample(1),
      multiplier : Sample(4) ]

EncodeWidthUpdateMessage(message) ==
    message.timeOffset
        \o message.underlying
        \o message.widthType
        \o message.multiplier

DecodeWidthUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET underlying == ReadBytes(timeOffset.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    LET widthType == ReadBytes(underlying.rest, 1) IN IF ~widthType.ok THEN Fail ELSE
    LET multiplier == ReadBytes(widthType.rest, 4) IN IF ~multiplier.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         underlying |-> underlying.value,
         widthType  |-> widthType.value,
         multiplier |-> multiplier.value ], multiplier.rest)

ZeroWidthUpdateMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      underlying |-> [i \in 1 .. 8 |-> 0],
      widthType  |-> [i \in 1 .. 1 |-> 0],
      multiplier |-> [i \in 1 .. 4 |-> 0] ]

(* Width Update Message at zero, then each field in turn at the values it is checked at *)
CheckedWidthUpdateMessage ==
    { ZeroWidthUpdateMessage }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.underlying = one] : one \in Sample(8) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.widthType = one] : one \in Sample(1) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.multiplier = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Mapping Message: 36 bytes                                        *)
(***************************************************************************)

SymbolMappingMessage ==
    [ feedSymbol      : Sample(6),
      osiSymbol       : Sample(21),
      symbolCondition : Sample(1),
      underlying      : Sample(8) ]

EncodeSymbolMappingMessage(message) ==
    message.feedSymbol
        \o message.osiSymbol
        \o message.symbolCondition
        \o message.underlying

DecodeSymbolMappingMessage(bytes) ==
    LET feedSymbol == ReadBytes(bytes, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(feedSymbol.rest, 21) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(osiSymbol.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    LET underlying == ReadBytes(symbolCondition.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    Ok([ feedSymbol      |-> feedSymbol.value,
         osiSymbol       |-> osiSymbol.value,
         symbolCondition |-> symbolCondition.value,
         underlying      |-> underlying.value ], underlying.rest)

ZeroSymbolMappingMessage ==
    [ feedSymbol      |-> [i \in 1 .. 6 |-> 0],
      osiSymbol       |-> [i \in 1 .. 21 |-> 0],
      symbolCondition |-> [i \in 1 .. 1 |-> 0],
      underlying      |-> [i \in 1 .. 8 |-> 0] ]

(* Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolMappingMessage ==
    { ZeroSymbolMappingMessage }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.osiSymbol = one] : one \in Sample(21) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.underlying = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ timestamp : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.timestamp

DecodeEndOfSessionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value ], timestamp.rest)

ZeroEndOfSessionMessage ==
    [ timestamp |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.timestamp = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 32  \* 0x20
UnitClearMessageCode == 151  \* 0x97
AuctionNotificationMessageCode == 173  \* 0xad
AuctionCancelMessageCode == 174  \* 0xae
AuctionTradeMessageCode == 175  \* 0xaf
OptionsAuctionUpdateMessageCode == 209  \* 0xd1
AuctionSummaryMessageCode == 150  \* 0x96
WidthUpdateMessageCode == 210  \* 0xd2
SymbolMappingMessageCode == 46  \* 0x2e
EndOfSessionMessageCode == 45  \* 0x2d

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]
        \cup [ tag : {AuctionCancelMessageCode}, body : AuctionCancelMessage ]
        \cup [ tag : {AuctionTradeMessageCode}, body : AuctionTradeMessage ]
        \cup [ tag : {OptionsAuctionUpdateMessageCode}, body : OptionsAuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {WidthUpdateMessageCode}, body : WidthUpdateMessage ]
        \cup [ tag : {SymbolMappingMessageCode}, body : SymbolMappingMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)
      [] message.tag = AuctionCancelMessageCode -> EncodeAuctionCancelMessage(message.body)
      [] message.tag = AuctionTradeMessageCode -> EncodeAuctionTradeMessage(message.body)
      [] message.tag = OptionsAuctionUpdateMessageCode -> EncodeOptionsAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = WidthUpdateMessageCode -> EncodeWidthUpdateMessage(message.body)
      [] message.tag = SymbolMappingMessageCode -> EncodeSymbolMappingMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] tag = AuctionCancelMessageCode -> DecodeAuctionCancelMessage(bytes)
              [] tag = AuctionTradeMessageCode -> DecodeAuctionTradeMessage(bytes)
              [] tag = OptionsAuctionUpdateMessageCode -> DecodeOptionsAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = WidthUpdateMessageCode -> DecodeWidthUpdateMessage(bytes)
              [] tag = SymbolMappingMessageCode -> DecodeSymbolMappingMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }
        \cup { [tag |-> AuctionCancelMessageCode, body |-> one] : one \in CheckedAuctionCancelMessage }
        \cup { [tag |-> AuctionTradeMessageCode, body |-> one] : one \in CheckedAuctionTradeMessage }
        \cup { [tag |-> OptionsAuctionUpdateMessageCode, body |-> one] : one \in CheckedOptionsAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> WidthUpdateMessageCode, body |-> one] : one \in CheckedWidthUpdateMessage }
        \cup { [tag |-> SymbolMappingMessageCode, body |-> one] : one \in CheckedSymbolMappingMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }

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
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionNotificationMessageCode, body |-> ZeroAuctionNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionCancelMessageCode, body |-> ZeroAuctionCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionTradeMessageCode, body |-> ZeroAuctionTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsAuctionUpdateMessageCode, body |-> ZeroOptionsAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> WidthUpdateMessageCode, body |-> ZeroWidthUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolMappingMessageCode, body |-> ZeroSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
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

(* Every Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeMessage ==
    \A message \in CheckedTimeMessage :
        LET read == DecodeTimeMessage(EncodeTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitClearMessage ==
    \A message \in CheckedUnitClearMessage :
        LET read == DecodeUnitClearMessage(EncodeUnitClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionNotificationMessage ==
    \A message \in CheckedAuctionNotificationMessage :
        LET read == DecodeAuctionNotificationMessage(EncodeAuctionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionCancelMessage ==
    \A message \in CheckedAuctionCancelMessage :
        LET read == DecodeAuctionCancelMessage(EncodeAuctionCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradeMessage ==
    \A message \in CheckedAuctionTradeMessage :
        LET read == DecodeAuctionTradeMessage(EncodeAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsAuctionUpdateMessage ==
    \A message \in CheckedOptionsAuctionUpdateMessage :
        LET read == DecodeOptionsAuctionUpdateMessage(EncodeOptionsAuctionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummaryMessage ==
    \A message \in CheckedAuctionSummaryMessage :
        LET read == DecodeAuctionSummaryMessage(EncodeAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Width Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWidthUpdateMessage ==
    \A message \in CheckedWidthUpdateMessage :
        LET read == DecodeWidthUpdateMessage(EncodeWidthUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolMappingMessage ==
    \A message \in CheckedSymbolMappingMessage :
        LET read == DecodeSymbolMappingMessage(EncodeSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSessionMessage ==
    \A message \in CheckedEndOfSessionMessage :
        LET read == DecodeEndOfSessionMessage(EncodeEndOfSessionMessage(message))
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
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
