----------- MODULE CxaEquities_MulticastTopOfBook_Pitch_v1_0_10 ------------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Top Of Book v1.0.10            *)
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
(* Note: Flags is a bit field set, checked as its 1 byte rather than bit   *)
(* by bit.                                                                 *)
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
(* Unit Clear Message: 4 bytes                                             *)
(***************************************************************************)

UnitClearMessage ==
    [ reserved4 : Sample(4) ]

EncodeUnitClearMessage(message) ==
    message.reserved4

DecodeUnitClearMessage(bytes) ==
    LET reserved4 == ReadBytes(bytes, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ reserved4 |-> reserved4.value ], reserved4.rest)

ZeroUnitClearMessage ==
    [ reserved4 |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedUnitClearMessage ==
    { ZeroUnitClearMessage }
        \cup { [ZeroUnitClearMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 20 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timestamp     : Sample(8),
      symbol        : Sample(6),
      tradingStatus : Sample(1),
      marketIdCode  : Sample(4),
      reserved1     : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.tradingStatus
        \o message.marketIdCode
        \o message.reserved1

DecodeTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(symbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketIdCode == ReadBytes(tradingStatus.rest, 4) IN IF ~marketIdCode.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(marketIdCode.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbol        |-> symbol.value,
         tradingStatus |-> tradingStatus.value,
         marketIdCode  |-> marketIdCode.value,
         reserved1     |-> reserved1.value ], reserved1.rest)

ZeroTradingStatusMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> [i \in 1 .. 6 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketIdCode  |-> [i \in 1 .. 4 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.marketIdCode = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Single Side Update Message: 28 bytes                                    *)
(***************************************************************************)

SingleSideUpdateMessage ==
    [ timestamp : Sample(8),
      symbol    : Sample(6),
      side      : Sample(1),
      price     : Sample(8),
      quantity  : Sample(4),
      reserved1 : Sample(1) ]

EncodeSingleSideUpdateMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.side
        \o message.price
        \o message.quantity
        \o message.reserved1

DecodeSingleSideUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET side == ReadBytes(symbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(quantity.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         symbol    |-> symbol.value,
         side      |-> side.value,
         price     |-> price.value,
         quantity  |-> quantity.value,
         reserved1 |-> reserved1.value ], reserved1.rest)

ZeroSingleSideUpdateMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      symbol    |-> [i \in 1 .. 6 |-> 0],
      side      |-> [i \in 1 .. 1 |-> 0],
      price     |-> [i \in 1 .. 8 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0],
      reserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* Single Side Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideUpdateMessage ==
    { ZeroSingleSideUpdateMessage }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Two Side Update Message: 40 bytes                                       *)
(***************************************************************************)

TwoSideUpdateMessage ==
    [ timestamp       : Sample(8),
      symbol          : Sample(6),
      bidPrice        : Sample(8),
      bidQuantity     : Sample(4),
      reserved1       : Sample(1),
      askPrice        : Sample(8),
      askQuantity     : Sample(4),
      secondReserved1 : Sample(1) ]

EncodeTwoSideUpdateMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.bidPrice
        \o message.bidQuantity
        \o message.reserved1
        \o message.askPrice
        \o message.askQuantity
        \o message.secondReserved1

DecodeTwoSideUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(symbol.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidQuantity == ReadBytes(bidPrice.rest, 4) IN IF ~bidQuantity.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(bidQuantity.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET askPrice == ReadBytes(reserved1.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askQuantity == ReadBytes(askPrice.rest, 4) IN IF ~askQuantity.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(askQuantity.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         symbol          |-> symbol.value,
         bidPrice        |-> bidPrice.value,
         bidQuantity     |-> bidQuantity.value,
         reserved1       |-> reserved1.value,
         askPrice        |-> askPrice.value,
         askQuantity     |-> askQuantity.value,
         secondReserved1 |-> secondReserved1.value ], secondReserved1.rest)

ZeroTwoSideUpdateMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      bidPrice        |-> [i \in 1 .. 8 |-> 0],
      bidQuantity     |-> [i \in 1 .. 4 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0],
      askPrice        |-> [i \in 1 .. 8 |-> 0],
      askQuantity     |-> [i \in 1 .. 4 |-> 0],
      secondReserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* Two Side Update Message at zero, then each field in turn at the values it is checked at *)
CheckedTwoSideUpdateMessage ==
    { ZeroTwoSideUpdateMessage }
        \cup { [ZeroTwoSideUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTwoSideUpdateMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTwoSideUpdateMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroTwoSideUpdateMessage EXCEPT !.bidQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTwoSideUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTwoSideUpdateMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroTwoSideUpdateMessage EXCEPT !.askQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTwoSideUpdateMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Top Trade Message: 58 bytes                                             *)
(***************************************************************************)

TopTradeMessage ==
    [ timestamp            : Sample(8),
      symbol               : Sample(6),
      quantity             : Sample(4),
      price                : Sample(8),
      executionId          : Sample(8),
      totalVolume          : Sample(4),
      pid                  : Sample(4),
      contraPid            : Sample(4),
      tradeType            : Sample(1),
      tradeDesignation     : Sample(1),
      tradeReportType      : Sample(1),
      tradeTransactionTime : Sample(8),
      flags                : Sample(1) ]

EncodeTopTradeMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.quantity
        \o message.price
        \o message.executionId
        \o message.totalVolume
        \o message.pid
        \o message.contraPid
        \o message.tradeType
        \o message.tradeDesignation
        \o message.tradeReportType
        \o message.tradeTransactionTime
        \o message.flags

DecodeTopTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET quantity == ReadBytes(symbol.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(executionId.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    LET pid == ReadBytes(totalVolume.rest, 4) IN IF ~pid.ok THEN Fail ELSE
    LET contraPid == ReadBytes(pid.rest, 4) IN IF ~contraPid.ok THEN Fail ELSE
    LET tradeType == ReadBytes(contraPid.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeDesignation == ReadBytes(tradeType.rest, 1) IN IF ~tradeDesignation.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeDesignation.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeTransactionTime == ReadBytes(tradeReportType.rest, 8) IN IF ~tradeTransactionTime.ok THEN Fail ELSE
    LET flags == ReadBytes(tradeTransactionTime.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         symbol               |-> symbol.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         executionId          |-> executionId.value,
         totalVolume          |-> totalVolume.value,
         pid                  |-> pid.value,
         contraPid            |-> contraPid.value,
         tradeType            |-> tradeType.value,
         tradeDesignation     |-> tradeDesignation.value,
         tradeReportType      |-> tradeReportType.value,
         tradeTransactionTime |-> tradeTransactionTime.value,
         flags                |-> flags.value ], flags.rest)

ZeroTopTradeMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      symbol               |-> [i \in 1 .. 6 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      executionId          |-> [i \in 1 .. 8 |-> 0],
      totalVolume          |-> [i \in 1 .. 4 |-> 0],
      pid                  |-> [i \in 1 .. 4 |-> 0],
      contraPid            |-> [i \in 1 .. 4 |-> 0],
      tradeType            |-> [i \in 1 .. 1 |-> 0],
      tradeDesignation     |-> [i \in 1 .. 1 |-> 0],
      tradeReportType      |-> [i \in 1 .. 1 |-> 0],
      tradeTransactionTime |-> [i \in 1 .. 8 |-> 0],
      flags                |-> [i \in 1 .. 1 |-> 0] ]

(* Top Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTopTradeMessage ==
    { ZeroTopTradeMessage }
        \cup { [ZeroTopTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTopTradeMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTopTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTopTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTopTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTopTradeMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTopTradeMessage EXCEPT !.pid = one] : one \in Sample(4) }
        \cup { [ZeroTopTradeMessage EXCEPT !.contraPid = one] : one \in Sample(4) }
        \cup { [ZeroTopTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTopTradeMessage EXCEPT !.tradeDesignation = one] : one \in Sample(1) }
        \cup { [ZeroTopTradeMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTopTradeMessage EXCEPT !.tradeTransactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTopTradeMessage EXCEPT !.flags = one] : one \in Sample(1) }

(***************************************************************************)
(* Calculated Value Message: 31 bytes                                      *)
(***************************************************************************)

CalculatedValueMessage ==
    [ timestamp      : Sample(8),
      symbol         : Sample(6),
      valueCategory  : Sample(1),
      value          : Sample(8),
      valueTimestamp : Sample(8) ]

EncodeCalculatedValueMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.valueCategory
        \o message.value
        \o message.valueTimestamp

DecodeCalculatedValueMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET valueCategory == ReadBytes(symbol.rest, 1) IN IF ~valueCategory.ok THEN Fail ELSE
    LET value == ReadBytes(valueCategory.rest, 8) IN IF ~value.ok THEN Fail ELSE
    LET valueTimestamp == ReadBytes(value.rest, 8) IN IF ~valueTimestamp.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         symbol         |-> symbol.value,
         valueCategory  |-> valueCategory.value,
         value          |-> value.value,
         valueTimestamp |-> valueTimestamp.value ], valueTimestamp.rest)

ZeroCalculatedValueMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      valueCategory  |-> [i \in 1 .. 1 |-> 0],
      value          |-> [i \in 1 .. 8 |-> 0],
      valueTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Calculated Value Message at zero, then each field in turn at the values it is checked at *)
CheckedCalculatedValueMessage ==
    { ZeroCalculatedValueMessage }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.valueCategory = one] : one \in Sample(1) }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.value = one] : one \in Sample(8) }
        \cup { [ZeroCalculatedValueMessage EXCEPT !.valueTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ reserved4 : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.reserved4

DecodeEndOfSessionMessage(bytes) ==
    LET reserved4 == ReadBytes(bytes, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ reserved4 |-> reserved4.value ], reserved4.rest)

ZeroEndOfSessionMessage ==
    [ reserved4 |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Update Message: 32 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ timestamp       : Sample(8),
      symbol          : Sample(6),
      auctionType     : Sample(1),
      buyShares       : Sample(4),
      sellShares      : Sample(4),
      indicativePrice : Sample(8),
      reserved1       : Sample(1) ]

EncodeAuctionUpdateMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.auctionType
        \o message.buyShares
        \o message.sellShares
        \o message.indicativePrice
        \o message.reserved1

DecodeAuctionUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET buyShares == ReadBytes(auctionType.rest, 4) IN IF ~buyShares.ok THEN Fail ELSE
    LET sellShares == ReadBytes(buyShares.rest, 4) IN IF ~sellShares.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellShares.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(indicativePrice.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         symbol          |-> symbol.value,
         auctionType     |-> auctionType.value,
         buyShares       |-> buyShares.value,
         sellShares      |-> sellShares.value,
         indicativePrice |-> indicativePrice.value,
         reserved1       |-> reserved1.value ], reserved1.rest)

ZeroAuctionUpdateMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      buyShares       |-> [i \in 1 .. 4 |-> 0],
      sellShares      |-> [i \in 1 .. 4 |-> 0],
      indicativePrice |-> [i \in 1 .. 8 |-> 0],
      reserved1       |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdateMessage ==
    { ZeroAuctionUpdateMessage }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.buyShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.sellShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Summary Message: 28 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timestamp   : Sample(8),
      symbol      : Sample(6),
      auctionType : Sample(1),
      price       : Sample(8),
      shares      : Sample(4),
      reserved1   : Sample(1) ]

EncodeAuctionSummaryMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.auctionType
        \o message.price
        \o message.shares
        \o message.reserved1

DecodeAuctionSummaryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET shares == ReadBytes(price.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(shares.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         symbol      |-> symbol.value,
         auctionType |-> auctionType.value,
         price       |-> price.value,
         shares      |-> shares.value,
         reserved1   |-> reserved1.value ], reserved1.rest)

ZeroAuctionSummaryMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      symbol      |-> [i \in 1 .. 6 |-> 0],
      auctionType |-> [i \in 1 .. 1 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      shares      |-> [i \in 1 .. 4 |-> 0],
      reserved1   |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

UnitClearMessageCode == 151  \* 0x97
TradingStatusMessageCode == 59  \* 0x3b
SingleSideUpdateMessageCode == 228  \* 0xe4
TwoSideUpdateMessageCode == 229  \* 0xe5
TopTradeMessageCode == 230  \* 0xe6
CalculatedValueMessageCode == 227  \* 0xe3
EndOfSessionMessageCode == 45  \* 0x2d
AuctionUpdateMessageCode == 149  \* 0x95
AuctionSummaryMessageCode == 150  \* 0x96

Payload ==
    [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {SingleSideUpdateMessageCode}, body : SingleSideUpdateMessage ]
        \cup [ tag : {TwoSideUpdateMessageCode}, body : TwoSideUpdateMessage ]
        \cup [ tag : {TopTradeMessageCode}, body : TopTradeMessage ]
        \cup [ tag : {CalculatedValueMessageCode}, body : CalculatedValueMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = SingleSideUpdateMessageCode -> EncodeSingleSideUpdateMessage(message.body)
      [] message.tag = TwoSideUpdateMessageCode -> EncodeTwoSideUpdateMessage(message.body)
      [] message.tag = TopTradeMessageCode -> EncodeTopTradeMessage(message.body)
      [] message.tag = CalculatedValueMessageCode -> EncodeCalculatedValueMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = SingleSideUpdateMessageCode -> DecodeSingleSideUpdateMessage(bytes)
              [] tag = TwoSideUpdateMessageCode -> DecodeTwoSideUpdateMessage(bytes)
              [] tag = TopTradeMessageCode -> DecodeTopTradeMessage(bytes)
              [] tag = CalculatedValueMessageCode -> DecodeCalculatedValueMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> SingleSideUpdateMessageCode, body |-> one] : one \in CheckedSingleSideUpdateMessage }
        \cup { [tag |-> TwoSideUpdateMessageCode, body |-> one] : one \in CheckedTwoSideUpdateMessage }
        \cup { [tag |-> TopTradeMessageCode, body |-> one] : one \in CheckedTopTradeMessage }
        \cup { [tag |-> CalculatedValueMessageCode, body |-> one] : one \in CheckedCalculatedValueMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideUpdateMessageCode, body |-> ZeroSingleSideUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TwoSideUpdateMessageCode, body |-> ZeroTwoSideUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopTradeMessageCode, body |-> ZeroTopTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CalculatedValueMessageCode, body |-> ZeroCalculatedValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionUpdateMessageCode, body |-> ZeroAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]] }

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

(* Every Unit Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitClearMessage ==
    \A message \in CheckedUnitClearMessage :
        LET read == DecodeUnitClearMessage(EncodeUnitClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideUpdateMessage ==
    \A message \in CheckedSingleSideUpdateMessage :
        LET read == DecodeSingleSideUpdateMessage(EncodeSingleSideUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Two Side Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTwoSideUpdateMessage ==
    \A message \in CheckedTwoSideUpdateMessage :
        LET read == DecodeTwoSideUpdateMessage(EncodeTwoSideUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopTradeMessage ==
    \A message \in CheckedTopTradeMessage :
        LET read == DecodeTopTradeMessage(EncodeTopTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Calculated Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCalculatedValueMessage ==
    \A message \in CheckedCalculatedValueMessage :
        LET read == DecodeCalculatedValueMessage(EncodeCalculatedValueMessage(message))
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

(* Every Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionUpdateMessage ==
    \A message \in CheckedAuctionUpdateMessage :
        LET read == DecodeAuctionUpdateMessage(EncodeAuctionUpdateMessage(message))
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
