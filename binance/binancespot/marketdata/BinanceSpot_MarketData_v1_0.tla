-------------------- MODULE BinanceSpot_MarketData_v1_0 --------------------
(***************************************************************************)
(* Binance Market Data v1.0                                                *)
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
(* Trades Stream Event Message trades Group: 25 bytes                      *)
(***************************************************************************)

TradesStreamEventMessageTradesGroup ==
    [ id           : Sample(8),
      price        : Sample(8),
      qty          : Sample(8),
      isBuyerMaker : Sample(1) ]

EncodeTradesStreamEventMessageTradesGroup(message) ==
    message.id
        \o message.price
        \o message.qty
        \o message.isBuyerMaker

DecodeTradesStreamEventMessageTradesGroup(bytes) ==
    LET id == ReadBytes(bytes, 8) IN IF ~id.ok THEN Fail ELSE
    LET price == ReadBytes(id.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 8) IN IF ~qty.ok THEN Fail ELSE
    LET isBuyerMaker == ReadBytes(qty.rest, 1) IN IF ~isBuyerMaker.ok THEN Fail ELSE
    Ok([ id           |-> id.value,
         price        |-> price.value,
         qty          |-> qty.value,
         isBuyerMaker |-> isBuyerMaker.value ], isBuyerMaker.rest)

ZeroTradesStreamEventMessageTradesGroup ==
    [ id           |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      qty          |-> [i \in 1 .. 8 |-> 0],
      isBuyerMaker |-> [i \in 1 .. 1 |-> 0] ]

(* Trades Stream Event Message trades Group at zero, then each field in turn at the values it is checked at *)
CheckedTradesStreamEventMessageTradesGroup ==
    { ZeroTradesStreamEventMessageTradesGroup }
        \cup { [ZeroTradesStreamEventMessageTradesGroup EXCEPT !.id = one] : one \in Sample(8) }
        \cup { [ZeroTradesStreamEventMessageTradesGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradesStreamEventMessageTradesGroup EXCEPT !.qty = one] : one \in Sample(8) }
        \cup { [ZeroTradesStreamEventMessageTradesGroup EXCEPT !.isBuyerMaker = one] : one \in Sample(1) }

(* A run of Trades Stream Event Message trades Group, written one after another *)
RECURSIVE EncodeTradesStreamEventMessageTradesGroupList(_)
EncodeTradesStreamEventMessageTradesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradesStreamEventMessageTradesGroup(Head(messages)) \o EncodeTradesStreamEventMessageTradesGroupList(Tail(messages))

(* As many Trades Stream Event Message trades Group as the field that counts them says *)
RECURSIVE ReadTradesStreamEventMessageTradesGroupList(_, _)
ReadTradesStreamEventMessageTradesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradesStreamEventMessageTradesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradesStreamEventMessageTradesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trades Stream Event Message trades Group of each kind, for the lists that carry them *)
OneTradesStreamEventMessageTradesGroup == { ZeroTradesStreamEventMessageTradesGroup }

(***************************************************************************)
(* Trades Stream Event Message trades Groups                               *)
(***************************************************************************)

TradesStreamEventMessageTradesGroups ==
    [ blockLength                         : Sample(2),
      tradesStreamEventMessageTradesGroup : SampleLists(OneTradesStreamEventMessageTradesGroup) ]

EncodeTradesStreamEventMessageTradesGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.tradesStreamEventMessageTradesGroup), 4)
        \o EncodeTradesStreamEventMessageTradesGroupList(message.tradesStreamEventMessageTradesGroup)

DecodeTradesStreamEventMessageTradesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint32 == ReadUIntLE(blockLength.rest, 4) IN IF ~numInGroupUint32.ok THEN Fail ELSE
    LET tradesStreamEventMessageTradesGroup == ReadTradesStreamEventMessageTradesGroupList(numInGroupUint32.rest, numInGroupUint32.value) IN IF ~tradesStreamEventMessageTradesGroup.ok THEN Fail ELSE
    Ok([ blockLength                         |-> blockLength.value,
         tradesStreamEventMessageTradesGroup |-> tradesStreamEventMessageTradesGroup.value ], tradesStreamEventMessageTradesGroup.rest)

ZeroTradesStreamEventMessageTradesGroups ==
    [ blockLength                         |-> [i \in 1 .. 2 |-> 0],
      tradesStreamEventMessageTradesGroup |-> << >> ]

(* Trades Stream Event Message trades Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradesStreamEventMessageTradesGroups ==
    { ZeroTradesStreamEventMessageTradesGroups }
        \cup { [ZeroTradesStreamEventMessageTradesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradesStreamEventMessageTradesGroups EXCEPT !.tradesStreamEventMessageTradesGroup = one] : one \in SampleLists(OneTradesStreamEventMessageTradesGroup) }

(***************************************************************************)
(* Symbol                                                                  *)
(***************************************************************************)

Symbol ==
    [ symbolData : SampleBytes ]

EncodeSymbol(message) ==
    EncodeUIntBE(Len(message.symbolData), 1)
        \o message.symbolData

DecodeSymbol(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolData == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolData.ok THEN Fail ELSE
    Ok([ symbolData |-> symbolData.value ], symbolData.rest)

ZeroSymbol ==
    [ symbolData |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol ==
    { ZeroSymbol }
        \cup { [ZeroSymbol EXCEPT !.symbolData = one] : one \in SampleBytes }

(***************************************************************************)
(* Trades Stream Event Message                                             *)
(***************************************************************************)

TradesStreamEventMessage ==
    [ eventTime                            : Sample(8),
      transactTime                         : Sample(8),
      priceExponent                        : Sample(1),
      qtyExponent                          : Sample(1),
      tradesStreamEventMessageTradesGroups : TradesStreamEventMessageTradesGroups,
      symbol                               : Symbol ]

EncodeTradesStreamEventMessage(message) ==
    message.eventTime
        \o message.transactTime
        \o message.priceExponent
        \o message.qtyExponent
        \o EncodeTradesStreamEventMessageTradesGroups(message.tradesStreamEventMessageTradesGroups)
        \o EncodeSymbol(message.symbol)

DecodeTradesStreamEventMessage(bytes) ==
    LET eventTime == ReadBytes(bytes, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(eventTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET priceExponent == ReadBytes(transactTime.rest, 1) IN IF ~priceExponent.ok THEN Fail ELSE
    LET qtyExponent == ReadBytes(priceExponent.rest, 1) IN IF ~qtyExponent.ok THEN Fail ELSE
    LET tradesStreamEventMessageTradesGroups == DecodeTradesStreamEventMessageTradesGroups(qtyExponent.rest) IN IF ~tradesStreamEventMessageTradesGroups.ok THEN Fail ELSE
    LET symbol == DecodeSymbol(tradesStreamEventMessageTradesGroups.rest) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ eventTime                            |-> eventTime.value,
         transactTime                         |-> transactTime.value,
         priceExponent                        |-> priceExponent.value,
         qtyExponent                          |-> qtyExponent.value,
         tradesStreamEventMessageTradesGroups |-> tradesStreamEventMessageTradesGroups.value,
         symbol                               |-> symbol.value ], symbol.rest)

ZeroTradesStreamEventMessage ==
    [ eventTime                            |-> [i \in 1 .. 8 |-> 0],
      transactTime                         |-> [i \in 1 .. 8 |-> 0],
      priceExponent                        |-> [i \in 1 .. 1 |-> 0],
      qtyExponent                          |-> [i \in 1 .. 1 |-> 0],
      tradesStreamEventMessageTradesGroups |-> ZeroTradesStreamEventMessageTradesGroups,
      symbol                               |-> ZeroSymbol ]

(* Trades Stream Event Message at zero, then each field in turn at the values it is checked at *)
CheckedTradesStreamEventMessage ==
    { ZeroTradesStreamEventMessage }
        \cup { [ZeroTradesStreamEventMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroTradesStreamEventMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradesStreamEventMessage EXCEPT !.priceExponent = one] : one \in Sample(1) }
        \cup { [ZeroTradesStreamEventMessage EXCEPT !.qtyExponent = one] : one \in Sample(1) }
        \cup { [ZeroTradesStreamEventMessage EXCEPT !.tradesStreamEventMessageTradesGroups = one] : one \in CheckedTradesStreamEventMessageTradesGroups }
        \cup { [ZeroTradesStreamEventMessage EXCEPT !.symbol = one] : one \in CheckedSymbol }

(***************************************************************************)
(* Symbol                                                                  *)
(***************************************************************************)

Symbol2 ==
    [ symbolData : SampleBytes ]

EncodeSymbol2(message) ==
    EncodeUIntBE(Len(message.symbolData), 1)
        \o message.symbolData

DecodeSymbol2(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolData == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolData.ok THEN Fail ELSE
    Ok([ symbolData |-> symbolData.value ], symbolData.rest)

ZeroSymbol2 ==
    [ symbolData |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol2 ==
    { ZeroSymbol2 }
        \cup { [ZeroSymbol2 EXCEPT !.symbolData = one] : one \in SampleBytes }

(***************************************************************************)
(* Best Bid Ask Stream Event Message                                       *)
(***************************************************************************)

BestBidAskStreamEventMessage ==
    [ eventTime     : Sample(8),
      bookUpdateId  : Sample(8),
      priceExponent : Sample(1),
      qtyExponent   : Sample(1),
      bidPrice      : Sample(8),
      bidQty        : Sample(8),
      askPrice      : Sample(8),
      askQty        : Sample(8),
      symbol        : Symbol2 ]

EncodeBestBidAskStreamEventMessage(message) ==
    message.eventTime
        \o message.bookUpdateId
        \o message.priceExponent
        \o message.qtyExponent
        \o message.bidPrice
        \o message.bidQty
        \o message.askPrice
        \o message.askQty
        \o EncodeSymbol2(message.symbol)

DecodeBestBidAskStreamEventMessage(bytes) ==
    LET eventTime == ReadBytes(bytes, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET bookUpdateId == ReadBytes(eventTime.rest, 8) IN IF ~bookUpdateId.ok THEN Fail ELSE
    LET priceExponent == ReadBytes(bookUpdateId.rest, 1) IN IF ~priceExponent.ok THEN Fail ELSE
    LET qtyExponent == ReadBytes(priceExponent.rest, 1) IN IF ~qtyExponent.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(qtyExponent.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidQty == ReadBytes(bidPrice.rest, 8) IN IF ~bidQty.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidQty.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askQty == ReadBytes(askPrice.rest, 8) IN IF ~askQty.ok THEN Fail ELSE
    LET symbol == DecodeSymbol2(askQty.rest) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ eventTime     |-> eventTime.value,
         bookUpdateId  |-> bookUpdateId.value,
         priceExponent |-> priceExponent.value,
         qtyExponent   |-> qtyExponent.value,
         bidPrice      |-> bidPrice.value,
         bidQty        |-> bidQty.value,
         askPrice      |-> askPrice.value,
         askQty        |-> askQty.value,
         symbol        |-> symbol.value ], symbol.rest)

ZeroBestBidAskStreamEventMessage ==
    [ eventTime     |-> [i \in 1 .. 8 |-> 0],
      bookUpdateId  |-> [i \in 1 .. 8 |-> 0],
      priceExponent |-> [i \in 1 .. 1 |-> 0],
      qtyExponent   |-> [i \in 1 .. 1 |-> 0],
      bidPrice      |-> [i \in 1 .. 8 |-> 0],
      bidQty        |-> [i \in 1 .. 8 |-> 0],
      askPrice      |-> [i \in 1 .. 8 |-> 0],
      askQty        |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> ZeroSymbol2 ]

(* Best Bid Ask Stream Event Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidAskStreamEventMessage ==
    { ZeroBestBidAskStreamEventMessage }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.bookUpdateId = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.priceExponent = one] : one \in Sample(1) }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.qtyExponent = one] : one \in Sample(1) }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.bidQty = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.askQty = one] : one \in Sample(8) }
        \cup { [ZeroBestBidAskStreamEventMessage EXCEPT !.symbol = one] : one \in CheckedSymbol2 }

(***************************************************************************)
(* Depth Snapshot Stream Event Message bids Group: 16 bytes                *)
(***************************************************************************)

DepthSnapshotStreamEventMessageBidsGroup ==
    [ price : Sample(8),
      qty   : Sample(8) ]

EncodeDepthSnapshotStreamEventMessageBidsGroup(message) ==
    message.price
        \o message.qty

DecodeDepthSnapshotStreamEventMessageBidsGroup(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 8) IN IF ~qty.ok THEN Fail ELSE
    Ok([ price |-> price.value,
         qty   |-> qty.value ], qty.rest)

ZeroDepthSnapshotStreamEventMessageBidsGroup ==
    [ price |-> [i \in 1 .. 8 |-> 0],
      qty   |-> [i \in 1 .. 8 |-> 0] ]

(* Depth Snapshot Stream Event Message bids Group at zero, then each field in turn at the values it is checked at *)
CheckedDepthSnapshotStreamEventMessageBidsGroup ==
    { ZeroDepthSnapshotStreamEventMessageBidsGroup }
        \cup { [ZeroDepthSnapshotStreamEventMessageBidsGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDepthSnapshotStreamEventMessageBidsGroup EXCEPT !.qty = one] : one \in Sample(8) }

(* A run of Depth Snapshot Stream Event Message bids Group, written one after another *)
RECURSIVE EncodeDepthSnapshotStreamEventMessageBidsGroupList(_)
EncodeDepthSnapshotStreamEventMessageBidsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDepthSnapshotStreamEventMessageBidsGroup(Head(messages)) \o EncodeDepthSnapshotStreamEventMessageBidsGroupList(Tail(messages))

(* As many Depth Snapshot Stream Event Message bids Group as the field that counts them says *)
RECURSIVE ReadDepthSnapshotStreamEventMessageBidsGroupList(_, _)
ReadDepthSnapshotStreamEventMessageBidsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDepthSnapshotStreamEventMessageBidsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDepthSnapshotStreamEventMessageBidsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Depth Snapshot Stream Event Message bids Group of each kind, for the lists that carry them *)
OneDepthSnapshotStreamEventMessageBidsGroup == { ZeroDepthSnapshotStreamEventMessageBidsGroup }

(***************************************************************************)
(* Depth Snapshot Stream Event Message bids Groups                         *)
(***************************************************************************)

DepthSnapshotStreamEventMessageBidsGroups ==
    [ blockLength                              : Sample(2),
      depthSnapshotStreamEventMessageBidsGroup : SampleLists(OneDepthSnapshotStreamEventMessageBidsGroup) ]

EncodeDepthSnapshotStreamEventMessageBidsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.depthSnapshotStreamEventMessageBidsGroup), 2)
        \o EncodeDepthSnapshotStreamEventMessageBidsGroupList(message.depthSnapshotStreamEventMessageBidsGroup)

DecodeDepthSnapshotStreamEventMessageBidsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint16 == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroupUint16.ok THEN Fail ELSE
    LET depthSnapshotStreamEventMessageBidsGroup == ReadDepthSnapshotStreamEventMessageBidsGroupList(numInGroupUint16.rest, numInGroupUint16.value) IN IF ~depthSnapshotStreamEventMessageBidsGroup.ok THEN Fail ELSE
    Ok([ blockLength                              |-> blockLength.value,
         depthSnapshotStreamEventMessageBidsGroup |-> depthSnapshotStreamEventMessageBidsGroup.value ], depthSnapshotStreamEventMessageBidsGroup.rest)

ZeroDepthSnapshotStreamEventMessageBidsGroups ==
    [ blockLength                              |-> [i \in 1 .. 2 |-> 0],
      depthSnapshotStreamEventMessageBidsGroup |-> << >> ]

(* Depth Snapshot Stream Event Message bids Groups at zero, then each field in turn at the values it is checked at *)
CheckedDepthSnapshotStreamEventMessageBidsGroups ==
    { ZeroDepthSnapshotStreamEventMessageBidsGroups }
        \cup { [ZeroDepthSnapshotStreamEventMessageBidsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroDepthSnapshotStreamEventMessageBidsGroups EXCEPT !.depthSnapshotStreamEventMessageBidsGroup = one] : one \in SampleLists(OneDepthSnapshotStreamEventMessageBidsGroup) }

(***************************************************************************)
(* Depth Snapshot Stream Event Message asks Group: 16 bytes                *)
(***************************************************************************)

DepthSnapshotStreamEventMessageAsksGroup ==
    [ price : Sample(8),
      qty   : Sample(8) ]

EncodeDepthSnapshotStreamEventMessageAsksGroup(message) ==
    message.price
        \o message.qty

DecodeDepthSnapshotStreamEventMessageAsksGroup(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 8) IN IF ~qty.ok THEN Fail ELSE
    Ok([ price |-> price.value,
         qty   |-> qty.value ], qty.rest)

ZeroDepthSnapshotStreamEventMessageAsksGroup ==
    [ price |-> [i \in 1 .. 8 |-> 0],
      qty   |-> [i \in 1 .. 8 |-> 0] ]

(* Depth Snapshot Stream Event Message asks Group at zero, then each field in turn at the values it is checked at *)
CheckedDepthSnapshotStreamEventMessageAsksGroup ==
    { ZeroDepthSnapshotStreamEventMessageAsksGroup }
        \cup { [ZeroDepthSnapshotStreamEventMessageAsksGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDepthSnapshotStreamEventMessageAsksGroup EXCEPT !.qty = one] : one \in Sample(8) }

(* A run of Depth Snapshot Stream Event Message asks Group, written one after another *)
RECURSIVE EncodeDepthSnapshotStreamEventMessageAsksGroupList(_)
EncodeDepthSnapshotStreamEventMessageAsksGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDepthSnapshotStreamEventMessageAsksGroup(Head(messages)) \o EncodeDepthSnapshotStreamEventMessageAsksGroupList(Tail(messages))

(* As many Depth Snapshot Stream Event Message asks Group as the field that counts them says *)
RECURSIVE ReadDepthSnapshotStreamEventMessageAsksGroupList(_, _)
ReadDepthSnapshotStreamEventMessageAsksGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDepthSnapshotStreamEventMessageAsksGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDepthSnapshotStreamEventMessageAsksGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Depth Snapshot Stream Event Message asks Group of each kind, for the lists that carry them *)
OneDepthSnapshotStreamEventMessageAsksGroup == { ZeroDepthSnapshotStreamEventMessageAsksGroup }

(***************************************************************************)
(* Depth Snapshot Stream Event Message asks Groups                         *)
(***************************************************************************)

DepthSnapshotStreamEventMessageAsksGroups ==
    [ blockLength                              : Sample(2),
      depthSnapshotStreamEventMessageAsksGroup : SampleLists(OneDepthSnapshotStreamEventMessageAsksGroup) ]

EncodeDepthSnapshotStreamEventMessageAsksGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.depthSnapshotStreamEventMessageAsksGroup), 2)
        \o EncodeDepthSnapshotStreamEventMessageAsksGroupList(message.depthSnapshotStreamEventMessageAsksGroup)

DecodeDepthSnapshotStreamEventMessageAsksGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint16 == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroupUint16.ok THEN Fail ELSE
    LET depthSnapshotStreamEventMessageAsksGroup == ReadDepthSnapshotStreamEventMessageAsksGroupList(numInGroupUint16.rest, numInGroupUint16.value) IN IF ~depthSnapshotStreamEventMessageAsksGroup.ok THEN Fail ELSE
    Ok([ blockLength                              |-> blockLength.value,
         depthSnapshotStreamEventMessageAsksGroup |-> depthSnapshotStreamEventMessageAsksGroup.value ], depthSnapshotStreamEventMessageAsksGroup.rest)

ZeroDepthSnapshotStreamEventMessageAsksGroups ==
    [ blockLength                              |-> [i \in 1 .. 2 |-> 0],
      depthSnapshotStreamEventMessageAsksGroup |-> << >> ]

(* Depth Snapshot Stream Event Message asks Groups at zero, then each field in turn at the values it is checked at *)
CheckedDepthSnapshotStreamEventMessageAsksGroups ==
    { ZeroDepthSnapshotStreamEventMessageAsksGroups }
        \cup { [ZeroDepthSnapshotStreamEventMessageAsksGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroDepthSnapshotStreamEventMessageAsksGroups EXCEPT !.depthSnapshotStreamEventMessageAsksGroup = one] : one \in SampleLists(OneDepthSnapshotStreamEventMessageAsksGroup) }

(***************************************************************************)
(* Symbol                                                                  *)
(***************************************************************************)

Symbol3 ==
    [ symbolData : SampleBytes ]

EncodeSymbol3(message) ==
    EncodeUIntBE(Len(message.symbolData), 1)
        \o message.symbolData

DecodeSymbol3(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolData == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolData.ok THEN Fail ELSE
    Ok([ symbolData |-> symbolData.value ], symbolData.rest)

ZeroSymbol3 ==
    [ symbolData |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol3 ==
    { ZeroSymbol3 }
        \cup { [ZeroSymbol3 EXCEPT !.symbolData = one] : one \in SampleBytes }

(***************************************************************************)
(* Depth Snapshot Stream Event Message                                     *)
(***************************************************************************)

DepthSnapshotStreamEventMessage ==
    [ eventTime                                 : Sample(8),
      bookUpdateId                              : Sample(8),
      priceExponent                             : Sample(1),
      qtyExponent                               : Sample(1),
      depthSnapshotStreamEventMessageBidsGroups : DepthSnapshotStreamEventMessageBidsGroups,
      depthSnapshotStreamEventMessageAsksGroups : DepthSnapshotStreamEventMessageAsksGroups,
      symbol                                    : Symbol3 ]

EncodeDepthSnapshotStreamEventMessage(message) ==
    message.eventTime
        \o message.bookUpdateId
        \o message.priceExponent
        \o message.qtyExponent
        \o EncodeDepthSnapshotStreamEventMessageBidsGroups(message.depthSnapshotStreamEventMessageBidsGroups)
        \o EncodeDepthSnapshotStreamEventMessageAsksGroups(message.depthSnapshotStreamEventMessageAsksGroups)
        \o EncodeSymbol3(message.symbol)

DecodeDepthSnapshotStreamEventMessage(bytes) ==
    LET eventTime == ReadBytes(bytes, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET bookUpdateId == ReadBytes(eventTime.rest, 8) IN IF ~bookUpdateId.ok THEN Fail ELSE
    LET priceExponent == ReadBytes(bookUpdateId.rest, 1) IN IF ~priceExponent.ok THEN Fail ELSE
    LET qtyExponent == ReadBytes(priceExponent.rest, 1) IN IF ~qtyExponent.ok THEN Fail ELSE
    LET depthSnapshotStreamEventMessageBidsGroups == DecodeDepthSnapshotStreamEventMessageBidsGroups(qtyExponent.rest) IN IF ~depthSnapshotStreamEventMessageBidsGroups.ok THEN Fail ELSE
    LET depthSnapshotStreamEventMessageAsksGroups == DecodeDepthSnapshotStreamEventMessageAsksGroups(depthSnapshotStreamEventMessageBidsGroups.rest) IN IF ~depthSnapshotStreamEventMessageAsksGroups.ok THEN Fail ELSE
    LET symbol == DecodeSymbol3(depthSnapshotStreamEventMessageAsksGroups.rest) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ eventTime                                 |-> eventTime.value,
         bookUpdateId                              |-> bookUpdateId.value,
         priceExponent                             |-> priceExponent.value,
         qtyExponent                               |-> qtyExponent.value,
         depthSnapshotStreamEventMessageBidsGroups |-> depthSnapshotStreamEventMessageBidsGroups.value,
         depthSnapshotStreamEventMessageAsksGroups |-> depthSnapshotStreamEventMessageAsksGroups.value,
         symbol                                    |-> symbol.value ], symbol.rest)

ZeroDepthSnapshotStreamEventMessage ==
    [ eventTime                                 |-> [i \in 1 .. 8 |-> 0],
      bookUpdateId                              |-> [i \in 1 .. 8 |-> 0],
      priceExponent                             |-> [i \in 1 .. 1 |-> 0],
      qtyExponent                               |-> [i \in 1 .. 1 |-> 0],
      depthSnapshotStreamEventMessageBidsGroups |-> ZeroDepthSnapshotStreamEventMessageBidsGroups,
      depthSnapshotStreamEventMessageAsksGroups |-> ZeroDepthSnapshotStreamEventMessageAsksGroups,
      symbol                                    |-> ZeroSymbol3 ]

(* Depth Snapshot Stream Event Message at zero, then each field in turn at the values it is checked at *)
CheckedDepthSnapshotStreamEventMessage ==
    { ZeroDepthSnapshotStreamEventMessage }
        \cup { [ZeroDepthSnapshotStreamEventMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroDepthSnapshotStreamEventMessage EXCEPT !.bookUpdateId = one] : one \in Sample(8) }
        \cup { [ZeroDepthSnapshotStreamEventMessage EXCEPT !.priceExponent = one] : one \in Sample(1) }
        \cup { [ZeroDepthSnapshotStreamEventMessage EXCEPT !.qtyExponent = one] : one \in Sample(1) }
        \cup { [ZeroDepthSnapshotStreamEventMessage EXCEPT !.depthSnapshotStreamEventMessageBidsGroups = one] : one \in CheckedDepthSnapshotStreamEventMessageBidsGroups }
        \cup { [ZeroDepthSnapshotStreamEventMessage EXCEPT !.depthSnapshotStreamEventMessageAsksGroups = one] : one \in CheckedDepthSnapshotStreamEventMessageAsksGroups }
        \cup { [ZeroDepthSnapshotStreamEventMessage EXCEPT !.symbol = one] : one \in CheckedSymbol3 }

(***************************************************************************)
(* Depth Diff Stream Event Message bids Group: 16 bytes                    *)
(***************************************************************************)

DepthDiffStreamEventMessageBidsGroup ==
    [ price : Sample(8),
      qty   : Sample(8) ]

EncodeDepthDiffStreamEventMessageBidsGroup(message) ==
    message.price
        \o message.qty

DecodeDepthDiffStreamEventMessageBidsGroup(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 8) IN IF ~qty.ok THEN Fail ELSE
    Ok([ price |-> price.value,
         qty   |-> qty.value ], qty.rest)

ZeroDepthDiffStreamEventMessageBidsGroup ==
    [ price |-> [i \in 1 .. 8 |-> 0],
      qty   |-> [i \in 1 .. 8 |-> 0] ]

(* Depth Diff Stream Event Message bids Group at zero, then each field in turn at the values it is checked at *)
CheckedDepthDiffStreamEventMessageBidsGroup ==
    { ZeroDepthDiffStreamEventMessageBidsGroup }
        \cup { [ZeroDepthDiffStreamEventMessageBidsGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDepthDiffStreamEventMessageBidsGroup EXCEPT !.qty = one] : one \in Sample(8) }

(* A run of Depth Diff Stream Event Message bids Group, written one after another *)
RECURSIVE EncodeDepthDiffStreamEventMessageBidsGroupList(_)
EncodeDepthDiffStreamEventMessageBidsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDepthDiffStreamEventMessageBidsGroup(Head(messages)) \o EncodeDepthDiffStreamEventMessageBidsGroupList(Tail(messages))

(* As many Depth Diff Stream Event Message bids Group as the field that counts them says *)
RECURSIVE ReadDepthDiffStreamEventMessageBidsGroupList(_, _)
ReadDepthDiffStreamEventMessageBidsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDepthDiffStreamEventMessageBidsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDepthDiffStreamEventMessageBidsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Depth Diff Stream Event Message bids Group of each kind, for the lists that carry them *)
OneDepthDiffStreamEventMessageBidsGroup == { ZeroDepthDiffStreamEventMessageBidsGroup }

(***************************************************************************)
(* Depth Diff Stream Event Message bids Groups                             *)
(***************************************************************************)

DepthDiffStreamEventMessageBidsGroups ==
    [ blockLength                          : Sample(2),
      depthDiffStreamEventMessageBidsGroup : SampleLists(OneDepthDiffStreamEventMessageBidsGroup) ]

EncodeDepthDiffStreamEventMessageBidsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.depthDiffStreamEventMessageBidsGroup), 2)
        \o EncodeDepthDiffStreamEventMessageBidsGroupList(message.depthDiffStreamEventMessageBidsGroup)

DecodeDepthDiffStreamEventMessageBidsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint16 == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroupUint16.ok THEN Fail ELSE
    LET depthDiffStreamEventMessageBidsGroup == ReadDepthDiffStreamEventMessageBidsGroupList(numInGroupUint16.rest, numInGroupUint16.value) IN IF ~depthDiffStreamEventMessageBidsGroup.ok THEN Fail ELSE
    Ok([ blockLength                          |-> blockLength.value,
         depthDiffStreamEventMessageBidsGroup |-> depthDiffStreamEventMessageBidsGroup.value ], depthDiffStreamEventMessageBidsGroup.rest)

ZeroDepthDiffStreamEventMessageBidsGroups ==
    [ blockLength                          |-> [i \in 1 .. 2 |-> 0],
      depthDiffStreamEventMessageBidsGroup |-> << >> ]

(* Depth Diff Stream Event Message bids Groups at zero, then each field in turn at the values it is checked at *)
CheckedDepthDiffStreamEventMessageBidsGroups ==
    { ZeroDepthDiffStreamEventMessageBidsGroups }
        \cup { [ZeroDepthDiffStreamEventMessageBidsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroDepthDiffStreamEventMessageBidsGroups EXCEPT !.depthDiffStreamEventMessageBidsGroup = one] : one \in SampleLists(OneDepthDiffStreamEventMessageBidsGroup) }

(***************************************************************************)
(* Depth Diff Stream Event Message asks Group: 16 bytes                    *)
(***************************************************************************)

DepthDiffStreamEventMessageAsksGroup ==
    [ price : Sample(8),
      qty   : Sample(8) ]

EncodeDepthDiffStreamEventMessageAsksGroup(message) ==
    message.price
        \o message.qty

DecodeDepthDiffStreamEventMessageAsksGroup(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 8) IN IF ~qty.ok THEN Fail ELSE
    Ok([ price |-> price.value,
         qty   |-> qty.value ], qty.rest)

ZeroDepthDiffStreamEventMessageAsksGroup ==
    [ price |-> [i \in 1 .. 8 |-> 0],
      qty   |-> [i \in 1 .. 8 |-> 0] ]

(* Depth Diff Stream Event Message asks Group at zero, then each field in turn at the values it is checked at *)
CheckedDepthDiffStreamEventMessageAsksGroup ==
    { ZeroDepthDiffStreamEventMessageAsksGroup }
        \cup { [ZeroDepthDiffStreamEventMessageAsksGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDepthDiffStreamEventMessageAsksGroup EXCEPT !.qty = one] : one \in Sample(8) }

(* A run of Depth Diff Stream Event Message asks Group, written one after another *)
RECURSIVE EncodeDepthDiffStreamEventMessageAsksGroupList(_)
EncodeDepthDiffStreamEventMessageAsksGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDepthDiffStreamEventMessageAsksGroup(Head(messages)) \o EncodeDepthDiffStreamEventMessageAsksGroupList(Tail(messages))

(* As many Depth Diff Stream Event Message asks Group as the field that counts them says *)
RECURSIVE ReadDepthDiffStreamEventMessageAsksGroupList(_, _)
ReadDepthDiffStreamEventMessageAsksGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDepthDiffStreamEventMessageAsksGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDepthDiffStreamEventMessageAsksGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Depth Diff Stream Event Message asks Group of each kind, for the lists that carry them *)
OneDepthDiffStreamEventMessageAsksGroup == { ZeroDepthDiffStreamEventMessageAsksGroup }

(***************************************************************************)
(* Depth Diff Stream Event Message asks Groups                             *)
(***************************************************************************)

DepthDiffStreamEventMessageAsksGroups ==
    [ blockLength                          : Sample(2),
      depthDiffStreamEventMessageAsksGroup : SampleLists(OneDepthDiffStreamEventMessageAsksGroup) ]

EncodeDepthDiffStreamEventMessageAsksGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.depthDiffStreamEventMessageAsksGroup), 2)
        \o EncodeDepthDiffStreamEventMessageAsksGroupList(message.depthDiffStreamEventMessageAsksGroup)

DecodeDepthDiffStreamEventMessageAsksGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint16 == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroupUint16.ok THEN Fail ELSE
    LET depthDiffStreamEventMessageAsksGroup == ReadDepthDiffStreamEventMessageAsksGroupList(numInGroupUint16.rest, numInGroupUint16.value) IN IF ~depthDiffStreamEventMessageAsksGroup.ok THEN Fail ELSE
    Ok([ blockLength                          |-> blockLength.value,
         depthDiffStreamEventMessageAsksGroup |-> depthDiffStreamEventMessageAsksGroup.value ], depthDiffStreamEventMessageAsksGroup.rest)

ZeroDepthDiffStreamEventMessageAsksGroups ==
    [ blockLength                          |-> [i \in 1 .. 2 |-> 0],
      depthDiffStreamEventMessageAsksGroup |-> << >> ]

(* Depth Diff Stream Event Message asks Groups at zero, then each field in turn at the values it is checked at *)
CheckedDepthDiffStreamEventMessageAsksGroups ==
    { ZeroDepthDiffStreamEventMessageAsksGroups }
        \cup { [ZeroDepthDiffStreamEventMessageAsksGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroDepthDiffStreamEventMessageAsksGroups EXCEPT !.depthDiffStreamEventMessageAsksGroup = one] : one \in SampleLists(OneDepthDiffStreamEventMessageAsksGroup) }

(***************************************************************************)
(* Symbol                                                                  *)
(***************************************************************************)

Symbol4 ==
    [ symbolData : SampleBytes ]

EncodeSymbol4(message) ==
    EncodeUIntBE(Len(message.symbolData), 1)
        \o message.symbolData

DecodeSymbol4(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolData == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolData.ok THEN Fail ELSE
    Ok([ symbolData |-> symbolData.value ], symbolData.rest)

ZeroSymbol4 ==
    [ symbolData |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol4 ==
    { ZeroSymbol4 }
        \cup { [ZeroSymbol4 EXCEPT !.symbolData = one] : one \in SampleBytes }

(***************************************************************************)
(* Depth Diff Stream Event Message                                         *)
(***************************************************************************)

DepthDiffStreamEventMessage ==
    [ eventTime                             : Sample(8),
      firstBookUpdateId                     : Sample(8),
      lastBookUpdateId                      : Sample(8),
      priceExponent                         : Sample(1),
      qtyExponent                           : Sample(1),
      depthDiffStreamEventMessageBidsGroups : DepthDiffStreamEventMessageBidsGroups,
      depthDiffStreamEventMessageAsksGroups : DepthDiffStreamEventMessageAsksGroups,
      symbol                                : Symbol4 ]

EncodeDepthDiffStreamEventMessage(message) ==
    message.eventTime
        \o message.firstBookUpdateId
        \o message.lastBookUpdateId
        \o message.priceExponent
        \o message.qtyExponent
        \o EncodeDepthDiffStreamEventMessageBidsGroups(message.depthDiffStreamEventMessageBidsGroups)
        \o EncodeDepthDiffStreamEventMessageAsksGroups(message.depthDiffStreamEventMessageAsksGroups)
        \o EncodeSymbol4(message.symbol)

DecodeDepthDiffStreamEventMessage(bytes) ==
    LET eventTime == ReadBytes(bytes, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET firstBookUpdateId == ReadBytes(eventTime.rest, 8) IN IF ~firstBookUpdateId.ok THEN Fail ELSE
    LET lastBookUpdateId == ReadBytes(firstBookUpdateId.rest, 8) IN IF ~lastBookUpdateId.ok THEN Fail ELSE
    LET priceExponent == ReadBytes(lastBookUpdateId.rest, 1) IN IF ~priceExponent.ok THEN Fail ELSE
    LET qtyExponent == ReadBytes(priceExponent.rest, 1) IN IF ~qtyExponent.ok THEN Fail ELSE
    LET depthDiffStreamEventMessageBidsGroups == DecodeDepthDiffStreamEventMessageBidsGroups(qtyExponent.rest) IN IF ~depthDiffStreamEventMessageBidsGroups.ok THEN Fail ELSE
    LET depthDiffStreamEventMessageAsksGroups == DecodeDepthDiffStreamEventMessageAsksGroups(depthDiffStreamEventMessageBidsGroups.rest) IN IF ~depthDiffStreamEventMessageAsksGroups.ok THEN Fail ELSE
    LET symbol == DecodeSymbol4(depthDiffStreamEventMessageAsksGroups.rest) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ eventTime                             |-> eventTime.value,
         firstBookUpdateId                     |-> firstBookUpdateId.value,
         lastBookUpdateId                      |-> lastBookUpdateId.value,
         priceExponent                         |-> priceExponent.value,
         qtyExponent                           |-> qtyExponent.value,
         depthDiffStreamEventMessageBidsGroups |-> depthDiffStreamEventMessageBidsGroups.value,
         depthDiffStreamEventMessageAsksGroups |-> depthDiffStreamEventMessageAsksGroups.value,
         symbol                                |-> symbol.value ], symbol.rest)

ZeroDepthDiffStreamEventMessage ==
    [ eventTime                             |-> [i \in 1 .. 8 |-> 0],
      firstBookUpdateId                     |-> [i \in 1 .. 8 |-> 0],
      lastBookUpdateId                      |-> [i \in 1 .. 8 |-> 0],
      priceExponent                         |-> [i \in 1 .. 1 |-> 0],
      qtyExponent                           |-> [i \in 1 .. 1 |-> 0],
      depthDiffStreamEventMessageBidsGroups |-> ZeroDepthDiffStreamEventMessageBidsGroups,
      depthDiffStreamEventMessageAsksGroups |-> ZeroDepthDiffStreamEventMessageAsksGroups,
      symbol                                |-> ZeroSymbol4 ]

(* Depth Diff Stream Event Message at zero, then each field in turn at the values it is checked at *)
CheckedDepthDiffStreamEventMessage ==
    { ZeroDepthDiffStreamEventMessage }
        \cup { [ZeroDepthDiffStreamEventMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroDepthDiffStreamEventMessage EXCEPT !.firstBookUpdateId = one] : one \in Sample(8) }
        \cup { [ZeroDepthDiffStreamEventMessage EXCEPT !.lastBookUpdateId = one] : one \in Sample(8) }
        \cup { [ZeroDepthDiffStreamEventMessage EXCEPT !.priceExponent = one] : one \in Sample(1) }
        \cup { [ZeroDepthDiffStreamEventMessage EXCEPT !.qtyExponent = one] : one \in Sample(1) }
        \cup { [ZeroDepthDiffStreamEventMessage EXCEPT !.depthDiffStreamEventMessageBidsGroups = one] : one \in CheckedDepthDiffStreamEventMessageBidsGroups }
        \cup { [ZeroDepthDiffStreamEventMessage EXCEPT !.depthDiffStreamEventMessageAsksGroups = one] : one \in CheckedDepthDiffStreamEventMessageAsksGroups }
        \cup { [ZeroDepthDiffStreamEventMessage EXCEPT !.symbol = one] : one \in CheckedSymbol4 }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

TradesStreamEventMessageCode == 10000  \* 0x2710
BestBidAskStreamEventMessageCode == 10001  \* 0x2711
DepthSnapshotStreamEventMessageCode == 10002  \* 0x2712
DepthDiffStreamEventMessageCode == 10003  \* 0x2713

Payload ==
    [ tag : {TradesStreamEventMessageCode}, body : TradesStreamEventMessage ]
        \cup [ tag : {BestBidAskStreamEventMessageCode}, body : BestBidAskStreamEventMessage ]
        \cup [ tag : {DepthSnapshotStreamEventMessageCode}, body : DepthSnapshotStreamEventMessage ]
        \cup [ tag : {DepthDiffStreamEventMessageCode}, body : DepthDiffStreamEventMessage ]

EncodePayload(message) ==
    CASE message.tag = TradesStreamEventMessageCode -> EncodeTradesStreamEventMessage(message.body)
      [] message.tag = BestBidAskStreamEventMessageCode -> EncodeBestBidAskStreamEventMessage(message.body)
      [] message.tag = DepthSnapshotStreamEventMessageCode -> EncodeDepthSnapshotStreamEventMessage(message.body)
      [] message.tag = DepthDiffStreamEventMessageCode -> EncodeDepthDiffStreamEventMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradesStreamEventMessageCode -> DecodeTradesStreamEventMessage(bytes)
              [] tag = BestBidAskStreamEventMessageCode -> DecodeBestBidAskStreamEventMessage(bytes)
              [] tag = DepthSnapshotStreamEventMessageCode -> DecodeDepthSnapshotStreamEventMessage(bytes)
              [] tag = DepthDiffStreamEventMessageCode -> DecodeDepthDiffStreamEventMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TradesStreamEventMessageCode, body |-> ZeroTradesStreamEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TradesStreamEventMessageCode, body |-> one] : one \in CheckedTradesStreamEventMessage }
        \cup { [tag |-> BestBidAskStreamEventMessageCode, body |-> one] : one \in CheckedBestBidAskStreamEventMessage }
        \cup { [tag |-> DepthSnapshotStreamEventMessageCode, body |-> one] : one \in CheckedDepthSnapshotStreamEventMessage }
        \cup { [tag |-> DepthDiffStreamEventMessageCode, body |-> one] : one \in CheckedDepthDiffStreamEventMessage }

(***************************************************************************)
(* Sbe Message                                                             *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Frame                                                                   *)
(***************************************************************************)

Frame ==
    [ sbeMessage : SbeMessage ]

EncodeFrame(message) ==
    EncodeSbeMessage(message.sbeMessage)

DecodeFrame(bytes) ==
    LET sbeMessage == DecodeSbeMessage(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroFrame ==
    [ sbeMessage |-> ZeroSbeMessage ]

(* Frame at zero, then each field in turn at the values it is checked at *)
CheckedFrame ==
    { ZeroFrame }
        \cup { [ZeroFrame EXCEPT !.sbeMessage = one] : one \in CheckedSbeMessage }

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

(* Every Trades Stream Event Message trades Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradesStreamEventMessageTradesGroup ==
    \A message \in CheckedTradesStreamEventMessageTradesGroup :
        LET read == DecodeTradesStreamEventMessageTradesGroup(EncodeTradesStreamEventMessageTradesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trades Stream Event Message trades Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradesStreamEventMessageTradesGroups ==
    \A message \in CheckedTradesStreamEventMessageTradesGroups :
        LET read == DecodeTradesStreamEventMessageTradesGroups(EncodeTradesStreamEventMessageTradesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol ==
    \A message \in CheckedSymbol :
        LET read == DecodeSymbol(EncodeSymbol(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trades Stream Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradesStreamEventMessage ==
    \A message \in CheckedTradesStreamEventMessage :
        LET read == DecodeTradesStreamEventMessage(EncodeTradesStreamEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol2 ==
    \A message \in CheckedSymbol2 :
        LET read == DecodeSymbol2(EncodeSymbol2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Bid Ask Stream Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidAskStreamEventMessage ==
    \A message \in CheckedBestBidAskStreamEventMessage :
        LET read == DecodeBestBidAskStreamEventMessage(EncodeBestBidAskStreamEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Snapshot Stream Event Message bids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthSnapshotStreamEventMessageBidsGroup ==
    \A message \in CheckedDepthSnapshotStreamEventMessageBidsGroup :
        LET read == DecodeDepthSnapshotStreamEventMessageBidsGroup(EncodeDepthSnapshotStreamEventMessageBidsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Snapshot Stream Event Message bids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthSnapshotStreamEventMessageBidsGroups ==
    \A message \in CheckedDepthSnapshotStreamEventMessageBidsGroups :
        LET read == DecodeDepthSnapshotStreamEventMessageBidsGroups(EncodeDepthSnapshotStreamEventMessageBidsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Snapshot Stream Event Message asks Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthSnapshotStreamEventMessageAsksGroup ==
    \A message \in CheckedDepthSnapshotStreamEventMessageAsksGroup :
        LET read == DecodeDepthSnapshotStreamEventMessageAsksGroup(EncodeDepthSnapshotStreamEventMessageAsksGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Snapshot Stream Event Message asks Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthSnapshotStreamEventMessageAsksGroups ==
    \A message \in CheckedDepthSnapshotStreamEventMessageAsksGroups :
        LET read == DecodeDepthSnapshotStreamEventMessageAsksGroups(EncodeDepthSnapshotStreamEventMessageAsksGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol3 ==
    \A message \in CheckedSymbol3 :
        LET read == DecodeSymbol3(EncodeSymbol3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Snapshot Stream Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthSnapshotStreamEventMessage ==
    \A message \in CheckedDepthSnapshotStreamEventMessage :
        LET read == DecodeDepthSnapshotStreamEventMessage(EncodeDepthSnapshotStreamEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Diff Stream Event Message bids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthDiffStreamEventMessageBidsGroup ==
    \A message \in CheckedDepthDiffStreamEventMessageBidsGroup :
        LET read == DecodeDepthDiffStreamEventMessageBidsGroup(EncodeDepthDiffStreamEventMessageBidsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Diff Stream Event Message bids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthDiffStreamEventMessageBidsGroups ==
    \A message \in CheckedDepthDiffStreamEventMessageBidsGroups :
        LET read == DecodeDepthDiffStreamEventMessageBidsGroups(EncodeDepthDiffStreamEventMessageBidsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Diff Stream Event Message asks Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthDiffStreamEventMessageAsksGroup ==
    \A message \in CheckedDepthDiffStreamEventMessageAsksGroup :
        LET read == DecodeDepthDiffStreamEventMessageAsksGroup(EncodeDepthDiffStreamEventMessageAsksGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Diff Stream Event Message asks Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthDiffStreamEventMessageAsksGroups ==
    \A message \in CheckedDepthDiffStreamEventMessageAsksGroups :
        LET read == DecodeDepthDiffStreamEventMessageAsksGroups(EncodeDepthDiffStreamEventMessageAsksGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol4 ==
    \A message \in CheckedSymbol4 :
        LET read == DecodeSymbol4(EncodeSymbol4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Diff Stream Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthDiffStreamEventMessage ==
    \A message \in CheckedDepthDiffStreamEventMessage :
        LET read == DecodeDepthDiffStreamEventMessage(EncodeDepthDiffStreamEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripFrame ==
    \A message \in CheckedFrame :
        LET read == DecodeFrame(EncodeFrame(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
