--------------- MODULE HkexSecurities_CombinedRetrans_v1_44 ----------------
(***************************************************************************)
(* Hong Kong Exchanges and Clearing Orion Market Data Cash Combined        *)
(* Retransmission v1.44                                                    *)
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
(* Add Odd Lot Order Message: 24 bytes                                     *)
(***************************************************************************)

AddOddLotOrderMessage ==
    [ securityCode : Sample(4),
      orderId      : Sample(8),
      price        : Sample(4),
      quantity     : Sample(4),
      brokerId     : Sample(2),
      side         : Sample(2) ]

EncodeAddOddLotOrderMessage(message) ==
    message.securityCode
        \o message.orderId
        \o message.price
        \o message.quantity
        \o message.brokerId
        \o message.side

DecodeAddOddLotOrderMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET brokerId == ReadBytes(quantity.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET side == ReadBytes(brokerId.rest, 2) IN IF ~side.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         orderId      |-> orderId.value,
         price        |-> price.value,
         quantity     |-> quantity.value,
         brokerId     |-> brokerId.value,
         side         |-> side.value ], side.rest)

ZeroAddOddLotOrderMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      quantity     |-> [i \in 1 .. 4 |-> 0],
      brokerId     |-> [i \in 1 .. 2 |-> 0],
      side         |-> [i \in 1 .. 2 |-> 0] ]

(* Add Odd Lot Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOddLotOrderMessage ==
    { ZeroAddOddLotOrderMessage }
        \cup { [ZeroAddOddLotOrderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroAddOddLotOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOddLotOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOddLotOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOddLotOrderMessage EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroAddOddLotOrderMessage EXCEPT !.side = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Order Message: 28 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ securityCode      : Sample(4),
      orderId           : Sample(8),
      price             : Sample(4),
      quantity          : Sample(4),
      side              : Sample(2),
      orderType         : Sample(1),
      filler1           : Sample(1),
      orderBookPosition : Sample(4) ]

EncodeAddOrderMessage(message) ==
    message.securityCode
        \o message.orderId
        \o message.price
        \o message.quantity
        \o message.side
        \o message.orderType
        \o message.filler1
        \o message.orderBookPosition

DecodeAddOrderMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 2) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET filler1 == ReadBytes(orderType.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(filler1.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    Ok([ securityCode      |-> securityCode.value,
         orderId           |-> orderId.value,
         price             |-> price.value,
         quantity          |-> quantity.value,
         side              |-> side.value,
         orderType         |-> orderType.value,
         filler1           |-> filler1.value,
         orderBookPosition |-> orderBookPosition.value ], orderBookPosition.rest)

ZeroAddOrderMessage ==
    [ securityCode      |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 2 |-> 0],
      orderType         |-> [i \in 1 .. 1 |-> 0],
      filler1           |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderBookPosition = one] : one \in Sample(4) }

(***************************************************************************)
(* Book Entry: 24 bytes                                                    *)
(***************************************************************************)

BookEntry ==
    [ aggregateQuantity : Sample(8),
      price             : Sample(4),
      numberOfOrders    : Sample(4),
      side              : Sample(2),
      priceLevel        : Sample(1),
      updateAction      : Sample(1),
      filler4           : Sample(4) ]

EncodeBookEntry(message) ==
    message.aggregateQuantity
        \o message.price
        \o message.numberOfOrders
        \o message.side
        \o message.priceLevel
        \o message.updateAction
        \o message.filler4

DecodeBookEntry(bytes) ==
    LET aggregateQuantity == ReadBytes(bytes, 8) IN IF ~aggregateQuantity.ok THEN Fail ELSE
    LET price == ReadBytes(aggregateQuantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(price.rest, 4) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET side == ReadBytes(numberOfOrders.rest, 2) IN IF ~side.ok THEN Fail ELSE
    LET priceLevel == ReadBytes(side.rest, 1) IN IF ~priceLevel.ok THEN Fail ELSE
    LET updateAction == ReadBytes(priceLevel.rest, 1) IN IF ~updateAction.ok THEN Fail ELSE
    LET filler4 == ReadBytes(updateAction.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    Ok([ aggregateQuantity |-> aggregateQuantity.value,
         price             |-> price.value,
         numberOfOrders    |-> numberOfOrders.value,
         side              |-> side.value,
         priceLevel        |-> priceLevel.value,
         updateAction      |-> updateAction.value,
         filler4           |-> filler4.value ], filler4.rest)

ZeroBookEntry ==
    [ aggregateQuantity |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      numberOfOrders    |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 2 |-> 0],
      priceLevel        |-> [i \in 1 .. 1 |-> 0],
      updateAction      |-> [i \in 1 .. 1 |-> 0],
      filler4           |-> [i \in 1 .. 4 |-> 0] ]

(* Book Entry at zero, then each field in turn at the values it is checked at *)
CheckedBookEntry ==
    { ZeroBookEntry }
        \cup { [ZeroBookEntry EXCEPT !.aggregateQuantity = one] : one \in Sample(8) }
        \cup { [ZeroBookEntry EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroBookEntry EXCEPT !.numberOfOrders = one] : one \in Sample(4) }
        \cup { [ZeroBookEntry EXCEPT !.side = one] : one \in Sample(2) }
        \cup { [ZeroBookEntry EXCEPT !.priceLevel = one] : one \in Sample(1) }
        \cup { [ZeroBookEntry EXCEPT !.updateAction = one] : one \in Sample(1) }
        \cup { [ZeroBookEntry EXCEPT !.filler4 = one] : one \in Sample(4) }

(* A run of Book Entry, written one after another *)
RECURSIVE EncodeBookEntryList(_)
EncodeBookEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBookEntry(Head(messages)) \o EncodeBookEntryList(Tail(messages))

(* As many Book Entry as the field that counts them says *)
RECURSIVE ReadBookEntryList(_, _)
ReadBookEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBookEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBookEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Book Entry of each kind, for the lists that carry them *)
OneBookEntry == { ZeroBookEntry }

(***************************************************************************)
(* Aggregate Order Book Update Message                                     *)
(***************************************************************************)

AggregateOrderBookUpdateMessage ==
    [ securityCode : Sample(4),
      filler3      : Sample(3),
      bookEntry    : SampleLists(OneBookEntry) ]

EncodeAggregateOrderBookUpdateMessage(message) ==
    message.securityCode
        \o message.filler3
        \o EncodeUIntLE(Len(message.bookEntry), 1)
        \o EncodeBookEntryList(message.bookEntry)

DecodeAggregateOrderBookUpdateMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET filler3 == ReadBytes(securityCode.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    LET noEntries == ReadUIntLE(filler3.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET bookEntry == ReadBookEntryList(noEntries.rest, noEntries.value) IN IF ~bookEntry.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         filler3      |-> filler3.value,
         bookEntry    |-> bookEntry.value ], bookEntry.rest)

ZeroAggregateOrderBookUpdateMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      filler3      |-> [i \in 1 .. 3 |-> 0],
      bookEntry    |-> << >> ]

(* Aggregate Order Book Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAggregateOrderBookUpdateMessage ==
    { ZeroAggregateOrderBookUpdateMessage }
        \cup { [ZeroAggregateOrderBookUpdateMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroAggregateOrderBookUpdateMessage EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroAggregateOrderBookUpdateMessage EXCEPT !.bookEntry = one] : one \in SampleLists(OneBookEntry) }

(***************************************************************************)
(* Bq Item: 4 bytes                                                        *)
(***************************************************************************)

BqItem ==
    [ item    : Sample(2),
      type    : Sample(1),
      filler1 : Sample(1) ]

EncodeBqItem(message) ==
    message.item
        \o message.type
        \o message.filler1

DecodeBqItem(bytes) ==
    LET item == ReadBytes(bytes, 2) IN IF ~item.ok THEN Fail ELSE
    LET type == ReadBytes(item.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET filler1 == ReadBytes(type.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ item    |-> item.value,
         type    |-> type.value,
         filler1 |-> filler1.value ], filler1.rest)

ZeroBqItem ==
    [ item    |-> [i \in 1 .. 2 |-> 0],
      type    |-> [i \in 1 .. 1 |-> 0],
      filler1 |-> [i \in 1 .. 1 |-> 0] ]

(* Bq Item at zero, then each field in turn at the values it is checked at *)
CheckedBqItem ==
    { ZeroBqItem }
        \cup { [ZeroBqItem EXCEPT !.item = one] : one \in Sample(2) }
        \cup { [ZeroBqItem EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroBqItem EXCEPT !.filler1 = one] : one \in Sample(1) }

(* A run of Bq Item, written one after another *)
RECURSIVE EncodeBqItemList(_)
EncodeBqItemList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBqItem(Head(messages)) \o EncodeBqItemList(Tail(messages))

(* As many Bq Item as the field that counts them says *)
RECURSIVE ReadBqItemList(_, _)
ReadBqItemList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBqItem(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBqItemList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bq Item of each kind, for the lists that carry them *)
OneBqItem == { ZeroBqItem }

(***************************************************************************)
(* Broker Queue Message                                                    *)
(***************************************************************************)

BrokerQueueMessage ==
    [ securityCode : Sample(4),
      brokerSide   : Sample(2),
      bqMoreFlag   : Sample(1),
      bqItem       : SampleLists(OneBqItem) ]

EncodeBrokerQueueMessage(message) ==
    message.securityCode
        \o EncodeUIntLE(Len(message.bqItem), 1)
        \o message.brokerSide
        \o message.bqMoreFlag
        \o EncodeBqItemList(message.bqItem)

DecodeBrokerQueueMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET itemCount == ReadUIntLE(securityCode.rest, 1) IN IF ~itemCount.ok THEN Fail ELSE
    LET brokerSide == ReadBytes(itemCount.rest, 2) IN IF ~brokerSide.ok THEN Fail ELSE
    LET bqMoreFlag == ReadBytes(brokerSide.rest, 1) IN IF ~bqMoreFlag.ok THEN Fail ELSE
    LET bqItem == ReadBqItemList(bqMoreFlag.rest, itemCount.value) IN IF ~bqItem.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         brokerSide   |-> brokerSide.value,
         bqMoreFlag   |-> bqMoreFlag.value,
         bqItem       |-> bqItem.value ], bqItem.rest)

ZeroBrokerQueueMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      brokerSide   |-> [i \in 1 .. 2 |-> 0],
      bqMoreFlag   |-> [i \in 1 .. 1 |-> 0],
      bqItem       |-> << >> ]

(* Broker Queue Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokerQueueMessage ==
    { ZeroBrokerQueueMessage }
        \cup { [ZeroBrokerQueueMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroBrokerQueueMessage EXCEPT !.brokerSide = one] : one \in Sample(2) }
        \cup { [ZeroBrokerQueueMessage EXCEPT !.bqMoreFlag = one] : one \in Sample(1) }
        \cup { [ZeroBrokerQueueMessage EXCEPT !.bqItem = one] : one \in SampleLists(OneBqItem) }

(***************************************************************************)
(* Closing Price Message: 12 bytes                                         *)
(***************************************************************************)

ClosingPriceMessage ==
    [ securityCode   : Sample(4),
      closingPrice   : Sample(4),
      numberOfTrades : Sample(4) ]

EncodeClosingPriceMessage(message) ==
    message.securityCode
        \o message.closingPrice
        \o message.numberOfTrades

DecodeClosingPriceMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(securityCode.rest, 4) IN IF ~closingPrice.ok THEN Fail ELSE
    LET numberOfTrades == ReadBytes(closingPrice.rest, 4) IN IF ~numberOfTrades.ok THEN Fail ELSE
    Ok([ securityCode   |-> securityCode.value,
         closingPrice   |-> closingPrice.value,
         numberOfTrades |-> numberOfTrades.value ], numberOfTrades.rest)

ZeroClosingPriceMessage ==
    [ securityCode   |-> [i \in 1 .. 4 |-> 0],
      closingPrice   |-> [i \in 1 .. 4 |-> 0],
      numberOfTrades |-> [i \in 1 .. 4 |-> 0] ]

(* Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingPriceMessage ==
    { ZeroClosingPriceMessage }
        \cup { [ZeroClosingPriceMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroClosingPriceMessage EXCEPT !.closingPrice = one] : one \in Sample(4) }
        \cup { [ZeroClosingPriceMessage EXCEPT !.numberOfTrades = one] : one \in Sample(4) }

(***************************************************************************)
(* Sequence Reset Message: 4 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Disaster Recovery Signal Message: 4 bytes                               *)
(***************************************************************************)

DisasterRecoverySignalMessage ==
    [ drStatus : Sample(4) ]

EncodeDisasterRecoverySignalMessage(message) ==
    message.drStatus

DecodeDisasterRecoverySignalMessage(bytes) ==
    LET drStatus == ReadBytes(bytes, 4) IN IF ~drStatus.ok THEN Fail ELSE
    Ok([ drStatus |-> drStatus.value ], drStatus.rest)

ZeroDisasterRecoverySignalMessage ==
    [ drStatus |-> [i \in 1 .. 4 |-> 0] ]

(* Disaster Recovery Signal Message at zero, then each field in turn at the values it is checked at *)
CheckedDisasterRecoverySignalMessage ==
    { ZeroDisasterRecoverySignalMessage }
        \cup { [ZeroDisasterRecoverySignalMessage EXCEPT !.drStatus = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Odd Lot Order Message: 16 bytes                                  *)
(***************************************************************************)

DeleteOddLotOrderMessage ==
    [ securityCode : Sample(4),
      orderId      : Sample(8),
      brokerId     : Sample(2),
      side         : Sample(2) ]

EncodeDeleteOddLotOrderMessage(message) ==
    message.securityCode
        \o message.orderId
        \o message.brokerId
        \o message.side

DecodeDeleteOddLotOrderMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(orderId.rest, 2) IN IF ~brokerId.ok THEN Fail ELSE
    LET side == ReadBytes(brokerId.rest, 2) IN IF ~side.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         orderId      |-> orderId.value,
         brokerId     |-> brokerId.value,
         side         |-> side.value ], side.rest)

ZeroDeleteOddLotOrderMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      brokerId     |-> [i \in 1 .. 2 |-> 0],
      side         |-> [i \in 1 .. 2 |-> 0] ]

(* Delete Odd Lot Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOddLotOrderMessage ==
    { ZeroDeleteOddLotOrderMessage }
        \cup { [ZeroDeleteOddLotOrderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOddLotOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOddLotOrderMessage EXCEPT !.brokerId = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOddLotOrderMessage EXCEPT !.side = one] : one \in Sample(2) }

(***************************************************************************)
(* Delete Order Message: 16 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ securityCode : Sample(4),
      orderId      : Sample(8),
      side         : Sample(2),
      filler2      : Sample(2) ]

EncodeDeleteOrderMessage(message) ==
    message.securityCode
        \o message.orderId
        \o message.side
        \o message.filler2

DecodeDeleteOrderMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 2) IN IF ~side.ok THEN Fail ELSE
    LET filler2 == ReadBytes(side.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         orderId      |-> orderId.value,
         side         |-> side.value,
         filler2      |-> filler2.value ], filler2.rest)

ZeroDeleteOrderMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      side         |-> [i \in 1 .. 2 |-> 0],
      filler2      |-> [i \in 1 .. 2 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.side = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.filler2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Index Definition Message: 16 bytes                                      *)
(***************************************************************************)

IndexDefinitionMessage ==
    [ indexCode    : Sample(11),
      indexSource  : Sample(1),
      currencyCode : Sample(3),
      filler1      : Sample(1) ]

EncodeIndexDefinitionMessage(message) ==
    message.indexCode
        \o message.indexSource
        \o message.currencyCode
        \o message.filler1

DecodeIndexDefinitionMessage(bytes) ==
    LET indexCode == ReadBytes(bytes, 11) IN IF ~indexCode.ok THEN Fail ELSE
    LET indexSource == ReadBytes(indexCode.rest, 1) IN IF ~indexSource.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(indexSource.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(currencyCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ indexCode    |-> indexCode.value,
         indexSource  |-> indexSource.value,
         currencyCode |-> currencyCode.value,
         filler1      |-> filler1.value ], filler1.rest)

ZeroIndexDefinitionMessage ==
    [ indexCode    |-> [i \in 1 .. 11 |-> 0],
      indexSource  |-> [i \in 1 .. 1 |-> 0],
      currencyCode |-> [i \in 1 .. 3 |-> 0],
      filler1      |-> [i \in 1 .. 1 |-> 0] ]

(* Index Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexDefinitionMessage ==
    { ZeroIndexDefinitionMessage }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.indexCode = one] : one \in Sample(11) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.indexSource = one] : one \in Sample(1) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Data Message: 108 bytes                                           *)
(***************************************************************************)

IndexDataMessage ==
    [ indexCode        : Sample(11),
      indexStatus      : Sample(1),
      indexTime        : Sample(8),
      indexValue       : Sample(8),
      netChgPrevDay    : Sample(8),
      highValue        : Sample(8),
      lowValue         : Sample(8),
      easValue         : Sample(8),
      indexTurnover    : Sample(8),
      openingValue     : Sample(8),
      closingValue     : Sample(8),
      previousSesClose : Sample(8),
      indexVolume      : Sample(8),
      netChgPrevDayPct : Sample(4),
      exception        : Sample(1),
      filler3          : Sample(3) ]

EncodeIndexDataMessage(message) ==
    message.indexCode
        \o message.indexStatus
        \o message.indexTime
        \o message.indexValue
        \o message.netChgPrevDay
        \o message.highValue
        \o message.lowValue
        \o message.easValue
        \o message.indexTurnover
        \o message.openingValue
        \o message.closingValue
        \o message.previousSesClose
        \o message.indexVolume
        \o message.netChgPrevDayPct
        \o message.exception
        \o message.filler3

DecodeIndexDataMessage(bytes) ==
    LET indexCode == ReadBytes(bytes, 11) IN IF ~indexCode.ok THEN Fail ELSE
    LET indexStatus == ReadBytes(indexCode.rest, 1) IN IF ~indexStatus.ok THEN Fail ELSE
    LET indexTime == ReadBytes(indexStatus.rest, 8) IN IF ~indexTime.ok THEN Fail ELSE
    LET indexValue == ReadBytes(indexTime.rest, 8) IN IF ~indexValue.ok THEN Fail ELSE
    LET netChgPrevDay == ReadBytes(indexValue.rest, 8) IN IF ~netChgPrevDay.ok THEN Fail ELSE
    LET highValue == ReadBytes(netChgPrevDay.rest, 8) IN IF ~highValue.ok THEN Fail ELSE
    LET lowValue == ReadBytes(highValue.rest, 8) IN IF ~lowValue.ok THEN Fail ELSE
    LET easValue == ReadBytes(lowValue.rest, 8) IN IF ~easValue.ok THEN Fail ELSE
    LET indexTurnover == ReadBytes(easValue.rest, 8) IN IF ~indexTurnover.ok THEN Fail ELSE
    LET openingValue == ReadBytes(indexTurnover.rest, 8) IN IF ~openingValue.ok THEN Fail ELSE
    LET closingValue == ReadBytes(openingValue.rest, 8) IN IF ~closingValue.ok THEN Fail ELSE
    LET previousSesClose == ReadBytes(closingValue.rest, 8) IN IF ~previousSesClose.ok THEN Fail ELSE
    LET indexVolume == ReadBytes(previousSesClose.rest, 8) IN IF ~indexVolume.ok THEN Fail ELSE
    LET netChgPrevDayPct == ReadBytes(indexVolume.rest, 4) IN IF ~netChgPrevDayPct.ok THEN Fail ELSE
    LET exception == ReadBytes(netChgPrevDayPct.rest, 1) IN IF ~exception.ok THEN Fail ELSE
    LET filler3 == ReadBytes(exception.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ indexCode        |-> indexCode.value,
         indexStatus      |-> indexStatus.value,
         indexTime        |-> indexTime.value,
         indexValue       |-> indexValue.value,
         netChgPrevDay    |-> netChgPrevDay.value,
         highValue        |-> highValue.value,
         lowValue         |-> lowValue.value,
         easValue         |-> easValue.value,
         indexTurnover    |-> indexTurnover.value,
         openingValue     |-> openingValue.value,
         closingValue     |-> closingValue.value,
         previousSesClose |-> previousSesClose.value,
         indexVolume      |-> indexVolume.value,
         netChgPrevDayPct |-> netChgPrevDayPct.value,
         exception        |-> exception.value,
         filler3          |-> filler3.value ], filler3.rest)

ZeroIndexDataMessage ==
    [ indexCode        |-> [i \in 1 .. 11 |-> 0],
      indexStatus      |-> [i \in 1 .. 1 |-> 0],
      indexTime        |-> [i \in 1 .. 8 |-> 0],
      indexValue       |-> [i \in 1 .. 8 |-> 0],
      netChgPrevDay    |-> [i \in 1 .. 8 |-> 0],
      highValue        |-> [i \in 1 .. 8 |-> 0],
      lowValue         |-> [i \in 1 .. 8 |-> 0],
      easValue         |-> [i \in 1 .. 8 |-> 0],
      indexTurnover    |-> [i \in 1 .. 8 |-> 0],
      openingValue     |-> [i \in 1 .. 8 |-> 0],
      closingValue     |-> [i \in 1 .. 8 |-> 0],
      previousSesClose |-> [i \in 1 .. 8 |-> 0],
      indexVolume      |-> [i \in 1 .. 8 |-> 0],
      netChgPrevDayPct |-> [i \in 1 .. 4 |-> 0],
      exception        |-> [i \in 1 .. 1 |-> 0],
      filler3          |-> [i \in 1 .. 3 |-> 0] ]

(* Index Data Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexDataMessage ==
    { ZeroIndexDataMessage }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexCode = one] : one \in Sample(11) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexStatus = one] : one \in Sample(1) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.netChgPrevDay = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.highValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.lowValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.easValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexTurnover = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.openingValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.closingValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.previousSesClose = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexVolume = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.netChgPrevDayPct = one] : one \in Sample(4) }
        \cup { [ZeroIndexDataMessage EXCEPT !.exception = one] : one \in Sample(1) }
        \cup { [ZeroIndexDataMessage EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Indicative Equilibrium Price Message: 16 bytes                          *)
(***************************************************************************)

IndicativeEquilibriumPriceMessage ==
    [ securityCode      : Sample(4),
      price             : Sample(4),
      aggregateQuantity : Sample(8) ]

EncodeIndicativeEquilibriumPriceMessage(message) ==
    message.securityCode
        \o message.price
        \o message.aggregateQuantity

DecodeIndicativeEquilibriumPriceMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET price == ReadBytes(securityCode.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET aggregateQuantity == ReadBytes(price.rest, 8) IN IF ~aggregateQuantity.ok THEN Fail ELSE
    Ok([ securityCode      |-> securityCode.value,
         price             |-> price.value,
         aggregateQuantity |-> aggregateQuantity.value ], aggregateQuantity.rest)

ZeroIndicativeEquilibriumPriceMessage ==
    [ securityCode      |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      aggregateQuantity |-> [i \in 1 .. 8 |-> 0] ]

(* Indicative Equilibrium Price Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicativeEquilibriumPriceMessage ==
    { ZeroIndicativeEquilibriumPriceMessage }
        \cup { [ZeroIndicativeEquilibriumPriceMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeEquilibriumPriceMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeEquilibriumPriceMessage EXCEPT !.aggregateQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Order Message: 24 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
    [ securityCode      : Sample(4),
      orderId           : Sample(8),
      quantity          : Sample(4),
      side              : Sample(2),
      filler2           : Sample(2),
      orderBookPosition : Sample(4) ]

EncodeModifyOrderMessage(message) ==
    message.securityCode
        \o message.orderId
        \o message.quantity
        \o message.side
        \o message.filler2
        \o message.orderBookPosition

DecodeModifyOrderMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 2) IN IF ~side.ok THEN Fail ELSE
    LET filler2 == ReadBytes(side.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(filler2.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    Ok([ securityCode      |-> securityCode.value,
         orderId           |-> orderId.value,
         quantity          |-> quantity.value,
         side              |-> side.value,
         filler2           |-> filler2.value,
         orderBookPosition |-> orderBookPosition.value ], orderBookPosition.rest)

ZeroModifyOrderMessage ==
    [ securityCode      |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 2 |-> 0],
      filler2           |-> [i \in 1 .. 2 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.side = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderBookPosition = one] : one \in Sample(4) }

(***************************************************************************)
(* News Market: 4 bytes                                                    *)
(***************************************************************************)

NewsMarket ==
    [ marketCode : Sample(4) ]

EncodeNewsMarket(message) ==
    message.marketCode

DecodeNewsMarket(bytes) ==
    LET marketCode == ReadBytes(bytes, 4) IN IF ~marketCode.ok THEN Fail ELSE
    Ok([ marketCode |-> marketCode.value ], marketCode.rest)

ZeroNewsMarket ==
    [ marketCode |-> [i \in 1 .. 4 |-> 0] ]

(* News Market at zero, then each field in turn at the values it is checked at *)
CheckedNewsMarket ==
    { ZeroNewsMarket }
        \cup { [ZeroNewsMarket EXCEPT !.marketCode = one] : one \in Sample(4) }

(* A run of News Market, written one after another *)
RECURSIVE EncodeNewsMarketList(_)
EncodeNewsMarketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewsMarket(Head(messages)) \o EncodeNewsMarketList(Tail(messages))

(* As many News Market as the field that counts them says *)
RECURSIVE ReadNewsMarketList(_, _)
ReadNewsMarketList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewsMarket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewsMarketList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One News Market of each kind, for the lists that carry them *)
OneNewsMarket == { ZeroNewsMarket }

(***************************************************************************)
(* News Security: 4 bytes                                                  *)
(***************************************************************************)

NewsSecurity ==
    [ securityCode : Sample(4) ]

EncodeNewsSecurity(message) ==
    message.securityCode

DecodeNewsSecurity(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value ], securityCode.rest)

ZeroNewsSecurity ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0] ]

(* News Security at zero, then each field in turn at the values it is checked at *)
CheckedNewsSecurity ==
    { ZeroNewsSecurity }
        \cup { [ZeroNewsSecurity EXCEPT !.securityCode = one] : one \in Sample(4) }

(* A run of News Security, written one after another *)
RECURSIVE EncodeNewsSecurityList(_)
EncodeNewsSecurityList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewsSecurity(Head(messages)) \o EncodeNewsSecurityList(Tail(messages))

(* As many News Security as the field that counts them says *)
RECURSIVE ReadNewsSecurityList(_, _)
ReadNewsSecurityList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewsSecurity(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewsSecurityList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One News Security of each kind, for the lists that carry them *)
OneNewsSecurity == { ZeroNewsSecurity }

(***************************************************************************)
(* News Line Item: 160 bytes                                               *)
(***************************************************************************)

NewsLineItem ==
    [ newsLine : Sample(160) ]

EncodeNewsLineItem(message) ==
    message.newsLine

DecodeNewsLineItem(bytes) ==
    LET newsLine == ReadBytes(bytes, 160) IN IF ~newsLine.ok THEN Fail ELSE
    Ok([ newsLine |-> newsLine.value ], newsLine.rest)

ZeroNewsLineItem ==
    [ newsLine |-> [i \in 1 .. 160 |-> 0] ]

(* News Line Item at zero, then each field in turn at the values it is checked at *)
CheckedNewsLineItem ==
    { ZeroNewsLineItem }
        \cup { [ZeroNewsLineItem EXCEPT !.newsLine = one] : one \in Sample(160) }

(* A run of News Line Item, written one after another *)
RECURSIVE EncodeNewsLineItemList(_)
EncodeNewsLineItemList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewsLineItem(Head(messages)) \o EncodeNewsLineItemList(Tail(messages))

(* As many News Line Item as the field that counts them says *)
RECURSIVE ReadNewsLineItemList(_, _)
ReadNewsLineItemList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewsLineItem(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewsLineItemList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One News Line Item of each kind, for the lists that carry them *)
OneNewsLineItem == { ZeroNewsLineItem }

(***************************************************************************)
(* News Message                                                            *)
(***************************************************************************)

NewsMessage ==
    [ newsType      : Sample(3),
      newsId        : Sample(3),
      headline      : Sample(320),
      cancelFlag    : Sample(1),
      lastFragment  : Sample(1),
      filler4       : Sample(4),
      releaseTime   : Sample(8),
      filler2       : Sample(2),
      newsMarket    : SampleLists(OneNewsMarket),
      secondFiller2 : Sample(2),
      newsSecurity  : SampleLists(OneNewsSecurity),
      thirdFiller2  : Sample(2),
      newsLineItem  : SampleLists(OneNewsLineItem) ]

EncodeNewsMessage(message) ==
    message.newsType
        \o message.newsId
        \o message.headline
        \o message.cancelFlag
        \o message.lastFragment
        \o message.filler4
        \o message.releaseTime
        \o message.filler2
        \o EncodeUIntLE(Len(message.newsMarket), 2)
        \o EncodeNewsMarketList(message.newsMarket)
        \o message.secondFiller2
        \o EncodeUIntLE(Len(message.newsSecurity), 2)
        \o EncodeNewsSecurityList(message.newsSecurity)
        \o message.thirdFiller2
        \o EncodeUIntLE(Len(message.newsLineItem), 2)
        \o EncodeNewsLineItemList(message.newsLineItem)

DecodeNewsMessage(bytes) ==
    LET newsType == ReadBytes(bytes, 3) IN IF ~newsType.ok THEN Fail ELSE
    LET newsId == ReadBytes(newsType.rest, 3) IN IF ~newsId.ok THEN Fail ELSE
    LET headline == ReadBytes(newsId.rest, 320) IN IF ~headline.ok THEN Fail ELSE
    LET cancelFlag == ReadBytes(headline.rest, 1) IN IF ~cancelFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(cancelFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET filler4 == ReadBytes(lastFragment.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET releaseTime == ReadBytes(filler4.rest, 8) IN IF ~releaseTime.ok THEN Fail ELSE
    LET filler2 == ReadBytes(releaseTime.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET noMarketCodes == ReadUIntLE(filler2.rest, 2) IN IF ~noMarketCodes.ok THEN Fail ELSE
    LET newsMarket == ReadNewsMarketList(noMarketCodes.rest, noMarketCodes.value) IN IF ~newsMarket.ok THEN Fail ELSE
    LET secondFiller2 == ReadBytes(newsMarket.rest, 2) IN IF ~secondFiller2.ok THEN Fail ELSE
    LET noSecurityCodes == ReadUIntLE(secondFiller2.rest, 2) IN IF ~noSecurityCodes.ok THEN Fail ELSE
    LET newsSecurity == ReadNewsSecurityList(noSecurityCodes.rest, noSecurityCodes.value) IN IF ~newsSecurity.ok THEN Fail ELSE
    LET thirdFiller2 == ReadBytes(newsSecurity.rest, 2) IN IF ~thirdFiller2.ok THEN Fail ELSE
    LET noNewsLines == ReadUIntLE(thirdFiller2.rest, 2) IN IF ~noNewsLines.ok THEN Fail ELSE
    LET newsLineItem == ReadNewsLineItemList(noNewsLines.rest, noNewsLines.value) IN IF ~newsLineItem.ok THEN Fail ELSE
    Ok([ newsType      |-> newsType.value,
         newsId        |-> newsId.value,
         headline      |-> headline.value,
         cancelFlag    |-> cancelFlag.value,
         lastFragment  |-> lastFragment.value,
         filler4       |-> filler4.value,
         releaseTime   |-> releaseTime.value,
         filler2       |-> filler2.value,
         newsMarket    |-> newsMarket.value,
         secondFiller2 |-> secondFiller2.value,
         newsSecurity  |-> newsSecurity.value,
         thirdFiller2  |-> thirdFiller2.value,
         newsLineItem  |-> newsLineItem.value ], newsLineItem.rest)

ZeroNewsMessage ==
    [ newsType      |-> [i \in 1 .. 3 |-> 0],
      newsId        |-> [i \in 1 .. 3 |-> 0],
      headline      |-> [i \in 1 .. 320 |-> 0],
      cancelFlag    |-> [i \in 1 .. 1 |-> 0],
      lastFragment  |-> [i \in 1 .. 1 |-> 0],
      filler4       |-> [i \in 1 .. 4 |-> 0],
      releaseTime   |-> [i \in 1 .. 8 |-> 0],
      filler2       |-> [i \in 1 .. 2 |-> 0],
      newsMarket    |-> << >>,
      secondFiller2 |-> [i \in 1 .. 2 |-> 0],
      newsSecurity  |-> << >>,
      thirdFiller2  |-> [i \in 1 .. 2 |-> 0],
      newsLineItem  |-> << >> ]

(* News Message at zero, then each field in turn at the values it is checked at *)
CheckedNewsMessage ==
    { ZeroNewsMessage }
        \cup { [ZeroNewsMessage EXCEPT !.newsType = one] : one \in Sample(3) }
        \cup { [ZeroNewsMessage EXCEPT !.newsId = one] : one \in Sample(3) }
        \cup { [ZeroNewsMessage EXCEPT !.headline = one] : one \in Sample(320) }
        \cup { [ZeroNewsMessage EXCEPT !.cancelFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewsMessage EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNewsMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroNewsMessage EXCEPT !.releaseTime = one] : one \in Sample(8) }
        \cup { [ZeroNewsMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroNewsMessage EXCEPT !.newsMarket = one] : one \in SampleLists(OneNewsMarket) }
        \cup { [ZeroNewsMessage EXCEPT !.secondFiller2 = one] : one \in Sample(2) }
        \cup { [ZeroNewsMessage EXCEPT !.newsSecurity = one] : one \in SampleLists(OneNewsSecurity) }
        \cup { [ZeroNewsMessage EXCEPT !.thirdFiller2 = one] : one \in Sample(2) }
        \cup { [ZeroNewsMessage EXCEPT !.newsLineItem = one] : one \in SampleLists(OneNewsLineItem) }

(***************************************************************************)
(* Nominal Price Message: 8 bytes                                          *)
(***************************************************************************)

NominalPriceMessage ==
    [ securityCode : Sample(4),
      nominalPrice : Sample(4) ]

EncodeNominalPriceMessage(message) ==
    message.securityCode
        \o message.nominalPrice

DecodeNominalPriceMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET nominalPrice == ReadBytes(securityCode.rest, 4) IN IF ~nominalPrice.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         nominalPrice |-> nominalPrice.value ], nominalPrice.rest)

ZeroNominalPriceMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      nominalPrice |-> [i \in 1 .. 4 |-> 0] ]

(* Nominal Price Message at zero, then each field in turn at the values it is checked at *)
CheckedNominalPriceMessage ==
    { ZeroNominalPriceMessage }
        \cup { [ZeroNominalPriceMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroNominalPriceMessage EXCEPT !.nominalPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Imbalance Message: 16 bytes                                       *)
(***************************************************************************)

OrderImbalanceMessage ==
    [ securityCode            : Sample(4),
      orderImbalanceDirection : Sample(1),
      filler1                 : Sample(1),
      orderImbalanceQuantity  : Sample(8),
      filler2                 : Sample(2) ]

EncodeOrderImbalanceMessage(message) ==
    message.securityCode
        \o message.orderImbalanceDirection
        \o message.filler1
        \o message.orderImbalanceQuantity
        \o message.filler2

DecodeOrderImbalanceMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderImbalanceDirection == ReadBytes(securityCode.rest, 1) IN IF ~orderImbalanceDirection.ok THEN Fail ELSE
    LET filler1 == ReadBytes(orderImbalanceDirection.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET orderImbalanceQuantity == ReadBytes(filler1.rest, 8) IN IF ~orderImbalanceQuantity.ok THEN Fail ELSE
    LET filler2 == ReadBytes(orderImbalanceQuantity.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    Ok([ securityCode            |-> securityCode.value,
         orderImbalanceDirection |-> orderImbalanceDirection.value,
         filler1                 |-> filler1.value,
         orderImbalanceQuantity  |-> orderImbalanceQuantity.value,
         filler2                 |-> filler2.value ], filler2.rest)

ZeroOrderImbalanceMessage ==
    [ securityCode            |-> [i \in 1 .. 4 |-> 0],
      orderImbalanceDirection |-> [i \in 1 .. 1 |-> 0],
      filler1                 |-> [i \in 1 .. 1 |-> 0],
      orderImbalanceQuantity  |-> [i \in 1 .. 8 |-> 0],
      filler2                 |-> [i \in 1 .. 2 |-> 0] ]

(* Order Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderImbalanceMessage ==
    { ZeroOrderImbalanceMessage }
        \cup { [ZeroOrderImbalanceMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderImbalanceMessage EXCEPT !.orderImbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroOrderImbalanceMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderImbalanceMessage EXCEPT !.orderImbalanceQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderImbalanceMessage EXCEPT !.filler2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Definition Message: 36 bytes                                     *)
(***************************************************************************)

MarketDefinitionMessage ==
    [ marketCode         : Sample(4),
      marketName         : Sample(25),
      currencyCode       : Sample(3),
      numberOfSecurities : Sample(4) ]

EncodeMarketDefinitionMessage(message) ==
    message.marketCode
        \o message.marketName
        \o message.currencyCode
        \o message.numberOfSecurities

DecodeMarketDefinitionMessage(bytes) ==
    LET marketCode == ReadBytes(bytes, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET marketName == ReadBytes(marketCode.rest, 25) IN IF ~marketName.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(marketName.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET numberOfSecurities == ReadBytes(currencyCode.rest, 4) IN IF ~numberOfSecurities.ok THEN Fail ELSE
    Ok([ marketCode         |-> marketCode.value,
         marketName         |-> marketName.value,
         currencyCode       |-> currencyCode.value,
         numberOfSecurities |-> numberOfSecurities.value ], numberOfSecurities.rest)

ZeroMarketDefinitionMessage ==
    [ marketCode         |-> [i \in 1 .. 4 |-> 0],
      marketName         |-> [i \in 1 .. 25 |-> 0],
      currencyCode       |-> [i \in 1 .. 3 |-> 0],
      numberOfSecurities |-> [i \in 1 .. 4 |-> 0] ]

(* Market Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketDefinitionMessage ==
    { ZeroMarketDefinitionMessage }
        \cup { [ZeroMarketDefinitionMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroMarketDefinitionMessage EXCEPT !.marketName = one] : one \in Sample(25) }
        \cup { [ZeroMarketDefinitionMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroMarketDefinitionMessage EXCEPT !.numberOfSecurities = one] : one \in Sample(4) }

(***************************************************************************)
(* Underlying Security: 8 bytes                                            *)
(***************************************************************************)

UnderlyingSecurity ==
    [ underlyingSecurityCode : Sample(4),
      filler4                : Sample(4) ]

EncodeUnderlyingSecurity(message) ==
    message.underlyingSecurityCode
        \o message.filler4

DecodeUnderlyingSecurity(bytes) ==
    LET underlyingSecurityCode == ReadBytes(bytes, 4) IN IF ~underlyingSecurityCode.ok THEN Fail ELSE
    LET filler4 == ReadBytes(underlyingSecurityCode.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    Ok([ underlyingSecurityCode |-> underlyingSecurityCode.value,
         filler4                |-> filler4.value ], filler4.rest)

ZeroUnderlyingSecurity ==
    [ underlyingSecurityCode |-> [i \in 1 .. 4 |-> 0],
      filler4                |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Security at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingSecurity ==
    { ZeroUnderlyingSecurity }
        \cup { [ZeroUnderlyingSecurity EXCEPT !.underlyingSecurityCode = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingSecurity EXCEPT !.filler4 = one] : one \in Sample(4) }

(* A run of Underlying Security, written one after another *)
RECURSIVE EncodeUnderlyingSecurityList(_)
EncodeUnderlyingSecurityList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnderlyingSecurity(Head(messages)) \o EncodeUnderlyingSecurityList(Tail(messages))

(* As many Underlying Security as the field that counts them says *)
RECURSIVE ReadUnderlyingSecurityList(_, _)
ReadUnderlyingSecurityList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnderlyingSecurity(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnderlyingSecurityList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Underlying Security of each kind, for the lists that carry them *)
OneUnderlyingSecurity == { ZeroUnderlyingSecurity }

(***************************************************************************)
(* Security Definition Message                                             *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ securityCode             : Sample(4),
      marketCode               : Sample(4),
      isinCode                 : Sample(12),
      instrumentType           : Sample(4),
      productType              : Sample(1),
      filler1                  : Sample(1),
      spreadTableCode          : Sample(2),
      securityShortName        : Sample(40),
      currencyCode             : Sample(3),
      securityNameGccs         : Sample(60),
      securityNameGb           : Sample(60),
      lotSize                  : Sample(4),
      filler4                  : Sample(4),
      previousClosingPrice     : Sample(4),
      vcmFlag                  : Sample(1),
      shortSellFlag            : Sample(1),
      casFlag                  : Sample(1),
      ccassFlag                : Sample(1),
      dummySecurityFlag        : Sample(1),
      secondFiller1            : Sample(1),
      stampDutyFlag            : Sample(1),
      thirdFiller1             : Sample(1),
      listingDate              : Sample(4),
      delistingDate            : Sample(4),
      freeText                 : Sample(38),
      filler62                 : Sample(62),
      posFlag                  : Sample(1),
      posUpperLimit            : Sample(4),
      posLowerLimit            : Sample(4),
      domainStmtSecurityCode   : Sample(4),
      filler37                 : Sample(37),
      efnFlag                  : Sample(1),
      accruedInterest          : Sample(4),
      couponRate               : Sample(4),
      fourthFiller1            : Sample(1),
      faceValue                : Sample(8),
      decimalsInFaceValue      : Sample(1),
      faceValueCurrency        : Sample(3),
      bondMaturityDate         : Sample(4),
      investorType             : Sample(1),
      filler44                 : Sample(44),
      conversionRatio          : Sample(4),
      strikePrice1             : Sample(4),
      strikePrice2             : Sample(4),
      warrantMaturityDate      : Sample(4),
      callPutFlag              : Sample(1),
      style                    : Sample(1),
      filler2                  : Sample(2),
      warrantType              : Sample(1),
      callPrice                : Sample(4),
      decimalsInCallPrice      : Sample(1),
      entitlement              : Sample(4),
      decimalsInEntitlement    : Sample(1),
      noWarrantsPerEntitlement : Sample(4),
      filler63                 : Sample(63),
      underlyingSecurity       : SampleLists(OneUnderlyingSecurity) ]

EncodeSecurityDefinitionMessage(message) ==
    message.securityCode
        \o message.marketCode
        \o message.isinCode
        \o message.instrumentType
        \o message.productType
        \o message.filler1
        \o message.spreadTableCode
        \o message.securityShortName
        \o message.currencyCode
        \o message.securityNameGccs
        \o message.securityNameGb
        \o message.lotSize
        \o message.filler4
        \o message.previousClosingPrice
        \o message.vcmFlag
        \o message.shortSellFlag
        \o message.casFlag
        \o message.ccassFlag
        \o message.dummySecurityFlag
        \o message.secondFiller1
        \o message.stampDutyFlag
        \o message.thirdFiller1
        \o message.listingDate
        \o message.delistingDate
        \o message.freeText
        \o message.filler62
        \o message.posFlag
        \o message.posUpperLimit
        \o message.posLowerLimit
        \o message.domainStmtSecurityCode
        \o message.filler37
        \o message.efnFlag
        \o message.accruedInterest
        \o message.couponRate
        \o message.fourthFiller1
        \o message.faceValue
        \o message.decimalsInFaceValue
        \o message.faceValueCurrency
        \o message.bondMaturityDate
        \o message.investorType
        \o message.filler44
        \o message.conversionRatio
        \o message.strikePrice1
        \o message.strikePrice2
        \o message.warrantMaturityDate
        \o message.callPutFlag
        \o message.style
        \o message.filler2
        \o message.warrantType
        \o message.callPrice
        \o message.decimalsInCallPrice
        \o message.entitlement
        \o message.decimalsInEntitlement
        \o message.noWarrantsPerEntitlement
        \o message.filler63
        \o EncodeUIntLE(Len(message.underlyingSecurity), 2)
        \o EncodeUnderlyingSecurityList(message.underlyingSecurity)

DecodeSecurityDefinitionMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET marketCode == ReadBytes(securityCode.rest, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET isinCode == ReadBytes(marketCode.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(isinCode.rest, 4) IN IF ~instrumentType.ok THEN Fail ELSE
    LET productType == ReadBytes(instrumentType.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET filler1 == ReadBytes(productType.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET spreadTableCode == ReadBytes(filler1.rest, 2) IN IF ~spreadTableCode.ok THEN Fail ELSE
    LET securityShortName == ReadBytes(spreadTableCode.rest, 40) IN IF ~securityShortName.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(securityShortName.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET securityNameGccs == ReadBytes(currencyCode.rest, 60) IN IF ~securityNameGccs.ok THEN Fail ELSE
    LET securityNameGb == ReadBytes(securityNameGccs.rest, 60) IN IF ~securityNameGb.ok THEN Fail ELSE
    LET lotSize == ReadBytes(securityNameGb.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET filler4 == ReadBytes(lotSize.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET previousClosingPrice == ReadBytes(filler4.rest, 4) IN IF ~previousClosingPrice.ok THEN Fail ELSE
    LET vcmFlag == ReadBytes(previousClosingPrice.rest, 1) IN IF ~vcmFlag.ok THEN Fail ELSE
    LET shortSellFlag == ReadBytes(vcmFlag.rest, 1) IN IF ~shortSellFlag.ok THEN Fail ELSE
    LET casFlag == ReadBytes(shortSellFlag.rest, 1) IN IF ~casFlag.ok THEN Fail ELSE
    LET ccassFlag == ReadBytes(casFlag.rest, 1) IN IF ~ccassFlag.ok THEN Fail ELSE
    LET dummySecurityFlag == ReadBytes(ccassFlag.rest, 1) IN IF ~dummySecurityFlag.ok THEN Fail ELSE
    LET secondFiller1 == ReadBytes(dummySecurityFlag.rest, 1) IN IF ~secondFiller1.ok THEN Fail ELSE
    LET stampDutyFlag == ReadBytes(secondFiller1.rest, 1) IN IF ~stampDutyFlag.ok THEN Fail ELSE
    LET thirdFiller1 == ReadBytes(stampDutyFlag.rest, 1) IN IF ~thirdFiller1.ok THEN Fail ELSE
    LET listingDate == ReadBytes(thirdFiller1.rest, 4) IN IF ~listingDate.ok THEN Fail ELSE
    LET delistingDate == ReadBytes(listingDate.rest, 4) IN IF ~delistingDate.ok THEN Fail ELSE
    LET freeText == ReadBytes(delistingDate.rest, 38) IN IF ~freeText.ok THEN Fail ELSE
    LET filler62 == ReadBytes(freeText.rest, 62) IN IF ~filler62.ok THEN Fail ELSE
    LET posFlag == ReadBytes(filler62.rest, 1) IN IF ~posFlag.ok THEN Fail ELSE
    LET posUpperLimit == ReadBytes(posFlag.rest, 4) IN IF ~posUpperLimit.ok THEN Fail ELSE
    LET posLowerLimit == ReadBytes(posUpperLimit.rest, 4) IN IF ~posLowerLimit.ok THEN Fail ELSE
    LET domainStmtSecurityCode == ReadBytes(posLowerLimit.rest, 4) IN IF ~domainStmtSecurityCode.ok THEN Fail ELSE
    LET filler37 == ReadBytes(domainStmtSecurityCode.rest, 37) IN IF ~filler37.ok THEN Fail ELSE
    LET efnFlag == ReadBytes(filler37.rest, 1) IN IF ~efnFlag.ok THEN Fail ELSE
    LET accruedInterest == ReadBytes(efnFlag.rest, 4) IN IF ~accruedInterest.ok THEN Fail ELSE
    LET couponRate == ReadBytes(accruedInterest.rest, 4) IN IF ~couponRate.ok THEN Fail ELSE
    LET fourthFiller1 == ReadBytes(couponRate.rest, 1) IN IF ~fourthFiller1.ok THEN Fail ELSE
    LET faceValue == ReadBytes(fourthFiller1.rest, 8) IN IF ~faceValue.ok THEN Fail ELSE
    LET decimalsInFaceValue == ReadBytes(faceValue.rest, 1) IN IF ~decimalsInFaceValue.ok THEN Fail ELSE
    LET faceValueCurrency == ReadBytes(decimalsInFaceValue.rest, 3) IN IF ~faceValueCurrency.ok THEN Fail ELSE
    LET bondMaturityDate == ReadBytes(faceValueCurrency.rest, 4) IN IF ~bondMaturityDate.ok THEN Fail ELSE
    LET investorType == ReadBytes(bondMaturityDate.rest, 1) IN IF ~investorType.ok THEN Fail ELSE
    LET filler44 == ReadBytes(investorType.rest, 44) IN IF ~filler44.ok THEN Fail ELSE
    LET conversionRatio == ReadBytes(filler44.rest, 4) IN IF ~conversionRatio.ok THEN Fail ELSE
    LET strikePrice1 == ReadBytes(conversionRatio.rest, 4) IN IF ~strikePrice1.ok THEN Fail ELSE
    LET strikePrice2 == ReadBytes(strikePrice1.rest, 4) IN IF ~strikePrice2.ok THEN Fail ELSE
    LET warrantMaturityDate == ReadBytes(strikePrice2.rest, 4) IN IF ~warrantMaturityDate.ok THEN Fail ELSE
    LET callPutFlag == ReadBytes(warrantMaturityDate.rest, 1) IN IF ~callPutFlag.ok THEN Fail ELSE
    LET style == ReadBytes(callPutFlag.rest, 1) IN IF ~style.ok THEN Fail ELSE
    LET filler2 == ReadBytes(style.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET warrantType == ReadBytes(filler2.rest, 1) IN IF ~warrantType.ok THEN Fail ELSE
    LET callPrice == ReadBytes(warrantType.rest, 4) IN IF ~callPrice.ok THEN Fail ELSE
    LET decimalsInCallPrice == ReadBytes(callPrice.rest, 1) IN IF ~decimalsInCallPrice.ok THEN Fail ELSE
    LET entitlement == ReadBytes(decimalsInCallPrice.rest, 4) IN IF ~entitlement.ok THEN Fail ELSE
    LET decimalsInEntitlement == ReadBytes(entitlement.rest, 1) IN IF ~decimalsInEntitlement.ok THEN Fail ELSE
    LET noWarrantsPerEntitlement == ReadBytes(decimalsInEntitlement.rest, 4) IN IF ~noWarrantsPerEntitlement.ok THEN Fail ELSE
    LET filler63 == ReadBytes(noWarrantsPerEntitlement.rest, 63) IN IF ~filler63.ok THEN Fail ELSE
    LET noUnderlyingSecurities == ReadUIntLE(filler63.rest, 2) IN IF ~noUnderlyingSecurities.ok THEN Fail ELSE
    LET underlyingSecurity == ReadUnderlyingSecurityList(noUnderlyingSecurities.rest, noUnderlyingSecurities.value) IN IF ~underlyingSecurity.ok THEN Fail ELSE
    Ok([ securityCode             |-> securityCode.value,
         marketCode               |-> marketCode.value,
         isinCode                 |-> isinCode.value,
         instrumentType           |-> instrumentType.value,
         productType              |-> productType.value,
         filler1                  |-> filler1.value,
         spreadTableCode          |-> spreadTableCode.value,
         securityShortName        |-> securityShortName.value,
         currencyCode             |-> currencyCode.value,
         securityNameGccs         |-> securityNameGccs.value,
         securityNameGb           |-> securityNameGb.value,
         lotSize                  |-> lotSize.value,
         filler4                  |-> filler4.value,
         previousClosingPrice     |-> previousClosingPrice.value,
         vcmFlag                  |-> vcmFlag.value,
         shortSellFlag            |-> shortSellFlag.value,
         casFlag                  |-> casFlag.value,
         ccassFlag                |-> ccassFlag.value,
         dummySecurityFlag        |-> dummySecurityFlag.value,
         secondFiller1            |-> secondFiller1.value,
         stampDutyFlag            |-> stampDutyFlag.value,
         thirdFiller1             |-> thirdFiller1.value,
         listingDate              |-> listingDate.value,
         delistingDate            |-> delistingDate.value,
         freeText                 |-> freeText.value,
         filler62                 |-> filler62.value,
         posFlag                  |-> posFlag.value,
         posUpperLimit            |-> posUpperLimit.value,
         posLowerLimit            |-> posLowerLimit.value,
         domainStmtSecurityCode   |-> domainStmtSecurityCode.value,
         filler37                 |-> filler37.value,
         efnFlag                  |-> efnFlag.value,
         accruedInterest          |-> accruedInterest.value,
         couponRate               |-> couponRate.value,
         fourthFiller1            |-> fourthFiller1.value,
         faceValue                |-> faceValue.value,
         decimalsInFaceValue      |-> decimalsInFaceValue.value,
         faceValueCurrency        |-> faceValueCurrency.value,
         bondMaturityDate         |-> bondMaturityDate.value,
         investorType             |-> investorType.value,
         filler44                 |-> filler44.value,
         conversionRatio          |-> conversionRatio.value,
         strikePrice1             |-> strikePrice1.value,
         strikePrice2             |-> strikePrice2.value,
         warrantMaturityDate      |-> warrantMaturityDate.value,
         callPutFlag              |-> callPutFlag.value,
         style                    |-> style.value,
         filler2                  |-> filler2.value,
         warrantType              |-> warrantType.value,
         callPrice                |-> callPrice.value,
         decimalsInCallPrice      |-> decimalsInCallPrice.value,
         entitlement              |-> entitlement.value,
         decimalsInEntitlement    |-> decimalsInEntitlement.value,
         noWarrantsPerEntitlement |-> noWarrantsPerEntitlement.value,
         filler63                 |-> filler63.value,
         underlyingSecurity       |-> underlyingSecurity.value ], underlyingSecurity.rest)

ZeroSecurityDefinitionMessage ==
    [ securityCode             |-> [i \in 1 .. 4 |-> 0],
      marketCode               |-> [i \in 1 .. 4 |-> 0],
      isinCode                 |-> [i \in 1 .. 12 |-> 0],
      instrumentType           |-> [i \in 1 .. 4 |-> 0],
      productType              |-> [i \in 1 .. 1 |-> 0],
      filler1                  |-> [i \in 1 .. 1 |-> 0],
      spreadTableCode          |-> [i \in 1 .. 2 |-> 0],
      securityShortName        |-> [i \in 1 .. 40 |-> 0],
      currencyCode             |-> [i \in 1 .. 3 |-> 0],
      securityNameGccs         |-> [i \in 1 .. 60 |-> 0],
      securityNameGb           |-> [i \in 1 .. 60 |-> 0],
      lotSize                  |-> [i \in 1 .. 4 |-> 0],
      filler4                  |-> [i \in 1 .. 4 |-> 0],
      previousClosingPrice     |-> [i \in 1 .. 4 |-> 0],
      vcmFlag                  |-> [i \in 1 .. 1 |-> 0],
      shortSellFlag            |-> [i \in 1 .. 1 |-> 0],
      casFlag                  |-> [i \in 1 .. 1 |-> 0],
      ccassFlag                |-> [i \in 1 .. 1 |-> 0],
      dummySecurityFlag        |-> [i \in 1 .. 1 |-> 0],
      secondFiller1            |-> [i \in 1 .. 1 |-> 0],
      stampDutyFlag            |-> [i \in 1 .. 1 |-> 0],
      thirdFiller1             |-> [i \in 1 .. 1 |-> 0],
      listingDate              |-> [i \in 1 .. 4 |-> 0],
      delistingDate            |-> [i \in 1 .. 4 |-> 0],
      freeText                 |-> [i \in 1 .. 38 |-> 0],
      filler62                 |-> [i \in 1 .. 62 |-> 0],
      posFlag                  |-> [i \in 1 .. 1 |-> 0],
      posUpperLimit            |-> [i \in 1 .. 4 |-> 0],
      posLowerLimit            |-> [i \in 1 .. 4 |-> 0],
      domainStmtSecurityCode   |-> [i \in 1 .. 4 |-> 0],
      filler37                 |-> [i \in 1 .. 37 |-> 0],
      efnFlag                  |-> [i \in 1 .. 1 |-> 0],
      accruedInterest          |-> [i \in 1 .. 4 |-> 0],
      couponRate               |-> [i \in 1 .. 4 |-> 0],
      fourthFiller1            |-> [i \in 1 .. 1 |-> 0],
      faceValue                |-> [i \in 1 .. 8 |-> 0],
      decimalsInFaceValue      |-> [i \in 1 .. 1 |-> 0],
      faceValueCurrency        |-> [i \in 1 .. 3 |-> 0],
      bondMaturityDate         |-> [i \in 1 .. 4 |-> 0],
      investorType             |-> [i \in 1 .. 1 |-> 0],
      filler44                 |-> [i \in 1 .. 44 |-> 0],
      conversionRatio          |-> [i \in 1 .. 4 |-> 0],
      strikePrice1             |-> [i \in 1 .. 4 |-> 0],
      strikePrice2             |-> [i \in 1 .. 4 |-> 0],
      warrantMaturityDate      |-> [i \in 1 .. 4 |-> 0],
      callPutFlag              |-> [i \in 1 .. 1 |-> 0],
      style                    |-> [i \in 1 .. 1 |-> 0],
      filler2                  |-> [i \in 1 .. 2 |-> 0],
      warrantType              |-> [i \in 1 .. 1 |-> 0],
      callPrice                |-> [i \in 1 .. 4 |-> 0],
      decimalsInCallPrice      |-> [i \in 1 .. 1 |-> 0],
      entitlement              |-> [i \in 1 .. 4 |-> 0],
      decimalsInEntitlement    |-> [i \in 1 .. 1 |-> 0],
      noWarrantsPerEntitlement |-> [i \in 1 .. 4 |-> 0],
      filler63                 |-> [i \in 1 .. 63 |-> 0],
      underlyingSecurity       |-> << >> ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.instrumentType = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.spreadTableCode = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityShortName = one] : one \in Sample(40) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityNameGccs = one] : one \in Sample(60) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityNameGb = one] : one \in Sample(60) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.previousClosingPrice = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.vcmFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.shortSellFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.casFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.ccassFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.dummySecurityFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.secondFiller1 = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.stampDutyFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.thirdFiller1 = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.listingDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.delistingDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.freeText = one] : one \in Sample(38) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler62 = one] : one \in Sample(62) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.posFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.posUpperLimit = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.posLowerLimit = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.domainStmtSecurityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler37 = one] : one \in Sample(37) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.efnFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.accruedInterest = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.couponRate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.fourthFiller1 = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.faceValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.decimalsInFaceValue = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.faceValueCurrency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.bondMaturityDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.investorType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler44 = one] : one \in Sample(44) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.conversionRatio = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.strikePrice1 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.strikePrice2 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.warrantMaturityDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.callPutFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.style = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.warrantType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.callPrice = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.decimalsInCallPrice = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.entitlement = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.decimalsInEntitlement = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.noWarrantsPerEntitlement = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler63 = one] : one \in Sample(63) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.underlyingSecurity = one] : one \in SampleLists(OneUnderlyingSecurity) }

(***************************************************************************)
(* Liquidity Provider: 2 bytes                                             *)
(***************************************************************************)

LiquidityProvider ==
    [ lpBrokerNumber : Sample(2) ]

EncodeLiquidityProvider(message) ==
    message.lpBrokerNumber

DecodeLiquidityProvider(bytes) ==
    LET lpBrokerNumber == ReadBytes(bytes, 2) IN IF ~lpBrokerNumber.ok THEN Fail ELSE
    Ok([ lpBrokerNumber |-> lpBrokerNumber.value ], lpBrokerNumber.rest)

ZeroLiquidityProvider ==
    [ lpBrokerNumber |-> [i \in 1 .. 2 |-> 0] ]

(* Liquidity Provider at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProvider ==
    { ZeroLiquidityProvider }
        \cup { [ZeroLiquidityProvider EXCEPT !.lpBrokerNumber = one] : one \in Sample(2) }

(* A run of Liquidity Provider, written one after another *)
RECURSIVE EncodeLiquidityProviderList(_)
EncodeLiquidityProviderList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLiquidityProvider(Head(messages)) \o EncodeLiquidityProviderList(Tail(messages))

(* As many Liquidity Provider as the field that counts them says *)
RECURSIVE ReadLiquidityProviderList(_, _)
ReadLiquidityProviderList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLiquidityProvider(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLiquidityProviderList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Liquidity Provider of each kind, for the lists that carry them *)
OneLiquidityProvider == { ZeroLiquidityProvider }

(***************************************************************************)
(* Liquidity Provider Message                                              *)
(***************************************************************************)

LiquidityProviderMessage ==
    [ securityCode      : Sample(4),
      liquidityProvider : SampleLists(OneLiquidityProvider) ]

EncodeLiquidityProviderMessage(message) ==
    message.securityCode
        \o EncodeUIntLE(Len(message.liquidityProvider), 2)
        \o EncodeLiquidityProviderList(message.liquidityProvider)

DecodeLiquidityProviderMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET noLiquidityProviders == ReadUIntLE(securityCode.rest, 2) IN IF ~noLiquidityProviders.ok THEN Fail ELSE
    LET liquidityProvider == ReadLiquidityProviderList(noLiquidityProviders.rest, noLiquidityProviders.value) IN IF ~liquidityProvider.ok THEN Fail ELSE
    Ok([ securityCode      |-> securityCode.value,
         liquidityProvider |-> liquidityProvider.value ], liquidityProvider.rest)

ZeroLiquidityProviderMessage ==
    [ securityCode      |-> [i \in 1 .. 4 |-> 0],
      liquidityProvider |-> << >> ]

(* Liquidity Provider Message at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProviderMessage ==
    { ZeroLiquidityProviderMessage }
        \cup { [ZeroLiquidityProviderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProviderMessage EXCEPT !.liquidityProvider = one] : one \in SampleLists(OneLiquidityProvider) }

(***************************************************************************)
(* Currency Rate Message: 12 bytes                                         *)
(***************************************************************************)

CurrencyRateMessage ==
    [ currencyCode   : Sample(3),
      filler1        : Sample(1),
      currencyFactor : Sample(2),
      filler2        : Sample(2),
      currencyRate   : Sample(4) ]

EncodeCurrencyRateMessage(message) ==
    message.currencyCode
        \o message.filler1
        \o message.currencyFactor
        \o message.filler2
        \o message.currencyRate

DecodeCurrencyRateMessage(bytes) ==
    LET currencyCode == ReadBytes(bytes, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(currencyCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET currencyFactor == ReadBytes(filler1.rest, 2) IN IF ~currencyFactor.ok THEN Fail ELSE
    LET filler2 == ReadBytes(currencyFactor.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET currencyRate == ReadBytes(filler2.rest, 4) IN IF ~currencyRate.ok THEN Fail ELSE
    Ok([ currencyCode   |-> currencyCode.value,
         filler1        |-> filler1.value,
         currencyFactor |-> currencyFactor.value,
         filler2        |-> filler2.value,
         currencyRate   |-> currencyRate.value ], currencyRate.rest)

ZeroCurrencyRateMessage ==
    [ currencyCode   |-> [i \in 1 .. 3 |-> 0],
      filler1        |-> [i \in 1 .. 1 |-> 0],
      currencyFactor |-> [i \in 1 .. 2 |-> 0],
      filler2        |-> [i \in 1 .. 2 |-> 0],
      currencyRate   |-> [i \in 1 .. 4 |-> 0] ]

(* Currency Rate Message at zero, then each field in turn at the values it is checked at *)
CheckedCurrencyRateMessage ==
    { ZeroCurrencyRateMessage }
        \cup { [ZeroCurrencyRateMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroCurrencyRateMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroCurrencyRateMessage EXCEPT !.currencyFactor = one] : one \in Sample(2) }
        \cup { [ZeroCurrencyRateMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroCurrencyRateMessage EXCEPT !.currencyRate = one] : one \in Sample(4) }

(***************************************************************************)
(* Reference Price Message: 16 bytes                                       *)
(***************************************************************************)

ReferencePriceMessage ==
    [ securityCode   : Sample(4),
      referencePrice : Sample(4),
      lowerPrice     : Sample(4),
      upperPrice     : Sample(4) ]

EncodeReferencePriceMessage(message) ==
    message.securityCode
        \o message.referencePrice
        \o message.lowerPrice
        \o message.upperPrice

DecodeReferencePriceMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(securityCode.rest, 4) IN IF ~referencePrice.ok THEN Fail ELSE
    LET lowerPrice == ReadBytes(referencePrice.rest, 4) IN IF ~lowerPrice.ok THEN Fail ELSE
    LET upperPrice == ReadBytes(lowerPrice.rest, 4) IN IF ~upperPrice.ok THEN Fail ELSE
    Ok([ securityCode   |-> securityCode.value,
         referencePrice |-> referencePrice.value,
         lowerPrice     |-> lowerPrice.value,
         upperPrice     |-> upperPrice.value ], upperPrice.rest)

ZeroReferencePriceMessage ==
    [ securityCode   |-> [i \in 1 .. 4 |-> 0],
      referencePrice |-> [i \in 1 .. 4 |-> 0],
      lowerPrice     |-> [i \in 1 .. 4 |-> 0],
      upperPrice     |-> [i \in 1 .. 4 |-> 0] ]

(* Reference Price Message at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceMessage ==
    { ZeroReferencePriceMessage }
        \cup { [ZeroReferencePriceMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.referencePrice = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.lowerPrice = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceMessage EXCEPT !.upperPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Refresh Complete Message: 4 bytes                                       *)
(***************************************************************************)

RefreshCompleteMessage ==
    [ lastSeqNum : Sample(4) ]

EncodeRefreshCompleteMessage(message) ==
    message.lastSeqNum

DecodeRefreshCompleteMessage(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroRefreshCompleteMessage ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Refresh Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshCompleteMessage ==
    { ZeroRefreshCompleteMessage }
        \cup { [ZeroRefreshCompleteMessage EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Message: 12 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ username : Sample(12) ]

EncodeLogonMessage(message) ==
    message.username

DecodeLogonMessage(bytes) ==
    LET username == ReadBytes(bytes, 12) IN IF ~username.ok THEN Fail ELSE
    Ok([ username |-> username.value ], username.rest)

ZeroLogonMessage ==
    [ username |-> [i \in 1 .. 12 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.username = one] : one \in Sample(12) }

(***************************************************************************)
(* Logon Response Message: 4 bytes                                         *)
(***************************************************************************)

LogonResponseMessage ==
    [ sessionStatus : Sample(1),
      filler3       : Sample(3) ]

EncodeLogonResponseMessage(message) ==
    message.sessionStatus
        \o message.filler3

DecodeLogonResponseMessage(bytes) ==
    LET sessionStatus == ReadBytes(bytes, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET filler3 == ReadBytes(sessionStatus.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ sessionStatus |-> sessionStatus.value,
         filler3       |-> filler3.value ], filler3.rest)

ZeroLogonResponseMessage ==
    [ sessionStatus |-> [i \in 1 .. 1 |-> 0],
      filler3       |-> [i \in 1 .. 3 |-> 0] ]

(* Logon Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponseMessage ==
    { ZeroLogonResponseMessage }
        \cup { [ZeroLogonResponseMessage EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Retransmission Request Message: 12 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ channelId   : Sample(2),
      filler2     : Sample(2),
      beginSeqNum : Sample(4),
      endSeqNum   : Sample(4) ]

EncodeRetransmissionRequestMessage(message) ==
    message.channelId
        \o message.filler2
        \o message.beginSeqNum
        \o message.endSeqNum

DecodeRetransmissionRequestMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET filler2 == ReadBytes(channelId.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(filler2.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ channelId   |-> channelId.value,
         filler2     |-> filler2.value,
         beginSeqNum |-> beginSeqNum.value,
         endSeqNum   |-> endSeqNum.value ], endSeqNum.rest)

ZeroRetransmissionRequestMessage ==
    [ channelId   |-> [i \in 1 .. 2 |-> 0],
      filler2     |-> [i \in 1 .. 2 |-> 0],
      beginSeqNum |-> [i \in 1 .. 4 |-> 0],
      endSeqNum   |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmission Response Message: 12 bytes                               *)
(***************************************************************************)

RetransmissionResponseMessage ==
    [ channelId     : Sample(2),
      retransStatus : Sample(1),
      filler1       : Sample(1),
      beginSeqNum   : Sample(4),
      endSeqNum     : Sample(4) ]

EncodeRetransmissionResponseMessage(message) ==
    message.channelId
        \o message.retransStatus
        \o message.filler1
        \o message.beginSeqNum
        \o message.endSeqNum

DecodeRetransmissionResponseMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET retransStatus == ReadBytes(channelId.rest, 1) IN IF ~retransStatus.ok THEN Fail ELSE
    LET filler1 == ReadBytes(retransStatus.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(filler1.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ channelId     |-> channelId.value,
         retransStatus |-> retransStatus.value,
         filler1       |-> filler1.value,
         beginSeqNum   |-> beginSeqNum.value,
         endSeqNum     |-> endSeqNum.value ], endSeqNum.rest)

ZeroRetransmissionResponseMessage ==
    [ channelId     |-> [i \in 1 .. 2 |-> 0],
      retransStatus |-> [i \in 1 .. 1 |-> 0],
      filler1       |-> [i \in 1 .. 1 |-> 0],
      beginSeqNum   |-> [i \in 1 .. 4 |-> 0],
      endSeqNum     |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionResponseMessage ==
    { ZeroRetransmissionResponseMessage }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.retransStatus = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Statistics Message: 48 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ securityCode          : Sample(4),
      sharesTraded          : Sample(8),
      turnover              : Sample(8),
      highPrice             : Sample(4),
      lowPrice              : Sample(4),
      lastPrice             : Sample(4),
      vwap                  : Sample(4),
      shortSellSharesTraded : Sample(4),
      shortSellTurnover     : Sample(8) ]

EncodeStatisticsMessage(message) ==
    message.securityCode
        \o message.sharesTraded
        \o message.turnover
        \o message.highPrice
        \o message.lowPrice
        \o message.lastPrice
        \o message.vwap
        \o message.shortSellSharesTraded
        \o message.shortSellTurnover

DecodeStatisticsMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET sharesTraded == ReadBytes(securityCode.rest, 8) IN IF ~sharesTraded.ok THEN Fail ELSE
    LET turnover == ReadBytes(sharesTraded.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET highPrice == ReadBytes(turnover.rest, 4) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 4) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lowPrice.rest, 4) IN IF ~lastPrice.ok THEN Fail ELSE
    LET vwap == ReadBytes(lastPrice.rest, 4) IN IF ~vwap.ok THEN Fail ELSE
    LET shortSellSharesTraded == ReadBytes(vwap.rest, 4) IN IF ~shortSellSharesTraded.ok THEN Fail ELSE
    LET shortSellTurnover == ReadBytes(shortSellSharesTraded.rest, 8) IN IF ~shortSellTurnover.ok THEN Fail ELSE
    Ok([ securityCode          |-> securityCode.value,
         sharesTraded          |-> sharesTraded.value,
         turnover              |-> turnover.value,
         highPrice             |-> highPrice.value,
         lowPrice              |-> lowPrice.value,
         lastPrice             |-> lastPrice.value,
         vwap                  |-> vwap.value,
         shortSellSharesTraded |-> shortSellSharesTraded.value,
         shortSellTurnover     |-> shortSellTurnover.value ], shortSellTurnover.rest)

ZeroStatisticsMessage ==
    [ securityCode          |-> [i \in 1 .. 4 |-> 0],
      sharesTraded          |-> [i \in 1 .. 8 |-> 0],
      turnover              |-> [i \in 1 .. 8 |-> 0],
      highPrice             |-> [i \in 1 .. 4 |-> 0],
      lowPrice              |-> [i \in 1 .. 4 |-> 0],
      lastPrice             |-> [i \in 1 .. 4 |-> 0],
      vwap                  |-> [i \in 1 .. 4 |-> 0],
      shortSellSharesTraded |-> [i \in 1 .. 4 |-> 0],
      shortSellTurnover     |-> [i \in 1 .. 8 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.sharesTraded = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.highPrice = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.lowPrice = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.vwap = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.shortSellSharesTraded = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.shortSellTurnover = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Turnover Message: 16 bytes                                       *)
(***************************************************************************)

MarketTurnoverMessage ==
    [ marketCode   : Sample(4),
      currencyCode : Sample(3),
      filler1      : Sample(1),
      turnover     : Sample(8) ]

EncodeMarketTurnoverMessage(message) ==
    message.marketCode
        \o message.currencyCode
        \o message.filler1
        \o message.turnover

DecodeMarketTurnoverMessage(bytes) ==
    LET marketCode == ReadBytes(bytes, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(marketCode.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(currencyCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET turnover == ReadBytes(filler1.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    Ok([ marketCode   |-> marketCode.value,
         currencyCode |-> currencyCode.value,
         filler1      |-> filler1.value,
         turnover     |-> turnover.value ], turnover.rest)

ZeroMarketTurnoverMessage ==
    [ marketCode   |-> [i \in 1 .. 4 |-> 0],
      currencyCode |-> [i \in 1 .. 3 |-> 0],
      filler1      |-> [i \in 1 .. 1 |-> 0],
      turnover     |-> [i \in 1 .. 8 |-> 0] ]

(* Market Turnover Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketTurnoverMessage ==
    { ZeroMarketTurnoverMessage }
        \cup { [ZeroMarketTurnoverMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroMarketTurnoverMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroMarketTurnoverMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroMarketTurnoverMessage EXCEPT !.turnover = one] : one \in Sample(8) }

(***************************************************************************)
(* Yield Message: 8 bytes                                                  *)
(***************************************************************************)

YieldMessage ==
    [ securityCode : Sample(4),
      yield        : Sample(4) ]

EncodeYieldMessage(message) ==
    message.securityCode
        \o message.yield

DecodeYieldMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET yield == ReadBytes(securityCode.rest, 4) IN IF ~yield.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         yield        |-> yield.value ], yield.rest)

ZeroYieldMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      yield        |-> [i \in 1 .. 4 |-> 0] ]

(* Yield Message at zero, then each field in turn at the values it is checked at *)
CheckedYieldMessage ==
    { ZeroYieldMessage }
        \cup { [ZeroYieldMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroYieldMessage EXCEPT !.yield = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Session Status Message: 28 bytes                                *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ marketCode            : Sample(4),
      filler1               : Sample(1),
      tradingSessionSubId   : Sample(1),
      tradingSesStatus      : Sample(1),
      tradingSesControlFlag : Sample(1),
      filler4               : Sample(4),
      startDateTime         : Sample(8),
      endDateTime           : Sample(8) ]

EncodeTradingSessionStatusMessage(message) ==
    message.marketCode
        \o message.filler1
        \o message.tradingSessionSubId
        \o message.tradingSesStatus
        \o message.tradingSesControlFlag
        \o message.filler4
        \o message.startDateTime
        \o message.endDateTime

DecodeTradingSessionStatusMessage(bytes) ==
    LET marketCode == ReadBytes(bytes, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(marketCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(filler1.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradingSesStatus == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradingSesStatus.ok THEN Fail ELSE
    LET tradingSesControlFlag == ReadBytes(tradingSesStatus.rest, 1) IN IF ~tradingSesControlFlag.ok THEN Fail ELSE
    LET filler4 == ReadBytes(tradingSesControlFlag.rest, 4) IN IF ~filler4.ok THEN Fail ELSE
    LET startDateTime == ReadBytes(filler4.rest, 8) IN IF ~startDateTime.ok THEN Fail ELSE
    LET endDateTime == ReadBytes(startDateTime.rest, 8) IN IF ~endDateTime.ok THEN Fail ELSE
    Ok([ marketCode            |-> marketCode.value,
         filler1               |-> filler1.value,
         tradingSessionSubId   |-> tradingSessionSubId.value,
         tradingSesStatus      |-> tradingSesStatus.value,
         tradingSesControlFlag |-> tradingSesControlFlag.value,
         filler4               |-> filler4.value,
         startDateTime         |-> startDateTime.value,
         endDateTime           |-> endDateTime.value ], endDateTime.rest)

ZeroTradingSessionStatusMessage ==
    [ marketCode            |-> [i \in 1 .. 4 |-> 0],
      filler1               |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId   |-> [i \in 1 .. 1 |-> 0],
      tradingSesStatus      |-> [i \in 1 .. 1 |-> 0],
      tradingSesControlFlag |-> [i \in 1 .. 1 |-> 0],
      filler4               |-> [i \in 1 .. 4 |-> 0],
      startDateTime         |-> [i \in 1 .. 8 |-> 0],
      endDateTime           |-> [i \in 1 .. 8 |-> 0] ]

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSesStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSesControlFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.filler4 = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.startDateTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.endDateTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Status Message: 8 bytes                                        *)
(***************************************************************************)

SecurityStatusMessage ==
    [ securityCode        : Sample(4),
      suspensionIndicator : Sample(1),
      filler3             : Sample(3) ]

EncodeSecurityStatusMessage(message) ==
    message.securityCode
        \o message.suspensionIndicator
        \o message.filler3

DecodeSecurityStatusMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET suspensionIndicator == ReadBytes(securityCode.rest, 1) IN IF ~suspensionIndicator.ok THEN Fail ELSE
    LET filler3 == ReadBytes(suspensionIndicator.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ securityCode        |-> securityCode.value,
         suspensionIndicator |-> suspensionIndicator.value,
         filler3             |-> filler3.value ], filler3.rest)

ZeroSecurityStatusMessage ==
    [ securityCode        |-> [i \in 1 .. 4 |-> 0],
      suspensionIndicator |-> [i \in 1 .. 1 |-> 0],
      filler3             |-> [i \in 1 .. 3 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.suspensionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Stock Connect Daily Quota Balance Message: 20 bytes                     *)
(***************************************************************************)

StockConnectDailyQuotaBalanceMessage ==
    [ stockConnectMarket    : Sample(2),
      tradingDirection      : Sample(2),
      dailyQuotaBalance     : Sample(8),
      dailyQuotaBalanceTime : Sample(8) ]

EncodeStockConnectDailyQuotaBalanceMessage(message) ==
    message.stockConnectMarket
        \o message.tradingDirection
        \o message.dailyQuotaBalance
        \o message.dailyQuotaBalanceTime

DecodeStockConnectDailyQuotaBalanceMessage(bytes) ==
    LET stockConnectMarket == ReadBytes(bytes, 2) IN IF ~stockConnectMarket.ok THEN Fail ELSE
    LET tradingDirection == ReadBytes(stockConnectMarket.rest, 2) IN IF ~tradingDirection.ok THEN Fail ELSE
    LET dailyQuotaBalance == ReadBytes(tradingDirection.rest, 8) IN IF ~dailyQuotaBalance.ok THEN Fail ELSE
    LET dailyQuotaBalanceTime == ReadBytes(dailyQuotaBalance.rest, 8) IN IF ~dailyQuotaBalanceTime.ok THEN Fail ELSE
    Ok([ stockConnectMarket    |-> stockConnectMarket.value,
         tradingDirection      |-> tradingDirection.value,
         dailyQuotaBalance     |-> dailyQuotaBalance.value,
         dailyQuotaBalanceTime |-> dailyQuotaBalanceTime.value ], dailyQuotaBalanceTime.rest)

ZeroStockConnectDailyQuotaBalanceMessage ==
    [ stockConnectMarket    |-> [i \in 1 .. 2 |-> 0],
      tradingDirection      |-> [i \in 1 .. 2 |-> 0],
      dailyQuotaBalance     |-> [i \in 1 .. 8 |-> 0],
      dailyQuotaBalanceTime |-> [i \in 1 .. 8 |-> 0] ]

(* Stock Connect Daily Quota Balance Message at zero, then each field in turn at the values it is checked at *)
CheckedStockConnectDailyQuotaBalanceMessage ==
    { ZeroStockConnectDailyQuotaBalanceMessage }
        \cup { [ZeroStockConnectDailyQuotaBalanceMessage EXCEPT !.stockConnectMarket = one] : one \in Sample(2) }
        \cup { [ZeroStockConnectDailyQuotaBalanceMessage EXCEPT !.tradingDirection = one] : one \in Sample(2) }
        \cup { [ZeroStockConnectDailyQuotaBalanceMessage EXCEPT !.dailyQuotaBalance = one] : one \in Sample(8) }
        \cup { [ZeroStockConnectDailyQuotaBalanceMessage EXCEPT !.dailyQuotaBalanceTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Stock Connect Market Turnover Message: 28 bytes                         *)
(***************************************************************************)

StockConnectMarketTurnoverMessage ==
    [ stockConnectMarket : Sample(2),
      tradingDirection   : Sample(2),
      buyTurnover        : Sample(8),
      sellTurnover       : Sample(8),
      buySellTurnover    : Sample(8) ]

EncodeStockConnectMarketTurnoverMessage(message) ==
    message.stockConnectMarket
        \o message.tradingDirection
        \o message.buyTurnover
        \o message.sellTurnover
        \o message.buySellTurnover

DecodeStockConnectMarketTurnoverMessage(bytes) ==
    LET stockConnectMarket == ReadBytes(bytes, 2) IN IF ~stockConnectMarket.ok THEN Fail ELSE
    LET tradingDirection == ReadBytes(stockConnectMarket.rest, 2) IN IF ~tradingDirection.ok THEN Fail ELSE
    LET buyTurnover == ReadBytes(tradingDirection.rest, 8) IN IF ~buyTurnover.ok THEN Fail ELSE
    LET sellTurnover == ReadBytes(buyTurnover.rest, 8) IN IF ~sellTurnover.ok THEN Fail ELSE
    LET buySellTurnover == ReadBytes(sellTurnover.rest, 8) IN IF ~buySellTurnover.ok THEN Fail ELSE
    Ok([ stockConnectMarket |-> stockConnectMarket.value,
         tradingDirection   |-> tradingDirection.value,
         buyTurnover        |-> buyTurnover.value,
         sellTurnover       |-> sellTurnover.value,
         buySellTurnover    |-> buySellTurnover.value ], buySellTurnover.rest)

ZeroStockConnectMarketTurnoverMessage ==
    [ stockConnectMarket |-> [i \in 1 .. 2 |-> 0],
      tradingDirection   |-> [i \in 1 .. 2 |-> 0],
      buyTurnover        |-> [i \in 1 .. 8 |-> 0],
      sellTurnover       |-> [i \in 1 .. 8 |-> 0],
      buySellTurnover    |-> [i \in 1 .. 8 |-> 0] ]

(* Stock Connect Market Turnover Message at zero, then each field in turn at the values it is checked at *)
CheckedStockConnectMarketTurnoverMessage ==
    { ZeroStockConnectMarketTurnoverMessage }
        \cup { [ZeroStockConnectMarketTurnoverMessage EXCEPT !.stockConnectMarket = one] : one \in Sample(2) }
        \cup { [ZeroStockConnectMarketTurnoverMessage EXCEPT !.tradingDirection = one] : one \in Sample(2) }
        \cup { [ZeroStockConnectMarketTurnoverMessage EXCEPT !.buyTurnover = one] : one \in Sample(8) }
        \cup { [ZeroStockConnectMarketTurnoverMessage EXCEPT !.sellTurnover = one] : one \in Sample(8) }
        \cup { [ZeroStockConnectMarketTurnoverMessage EXCEPT !.buySellTurnover = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 28 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ securityCode : Sample(4),
      tradeId      : Sample(4),
      price        : Sample(4),
      quantity     : Sample(4),
      trdType      : Sample(2),
      filler2      : Sample(2),
      tradeTime    : Sample(8) ]

EncodeTradeMessage(message) ==
    message.securityCode
        \o message.tradeId
        \o message.price
        \o message.quantity
        \o message.trdType
        \o message.filler2
        \o message.tradeTime

DecodeTradeMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET tradeId == ReadBytes(securityCode.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET trdType == ReadBytes(quantity.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET filler2 == ReadBytes(trdType.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(filler2.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         tradeId      |-> tradeId.value,
         price        |-> price.value,
         quantity     |-> quantity.value,
         trdType      |-> trdType.value,
         filler2      |-> filler2.value,
         tradeTime    |-> tradeTime.value ], tradeTime.rest)

ZeroTradeMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 4 |-> 0],
      quantity     |-> [i \in 1 .. 4 |-> 0],
      trdType      |-> [i \in 1 .. 2 |-> 0],
      filler2      |-> [i \in 1 .. 2 |-> 0],
      tradeTime    |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Cancel Message: 8 bytes                                           *)
(***************************************************************************)

TradeCancelMessage ==
    [ securityCode : Sample(4),
      tradeId      : Sample(4) ]

EncodeTradeCancelMessage(message) ==
    message.securityCode
        \o message.tradeId

DecodeTradeCancelMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET tradeId == ReadBytes(securityCode.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         tradeId      |-> tradeId.value ], tradeId.rest)

ZeroTradeCancelMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeId = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Ticker Message: 32 bytes                                          *)
(***************************************************************************)

TradeTickerMessage ==
    [ securityCode      : Sample(4),
      tickerId          : Sample(4),
      price             : Sample(4),
      aggregateQuantity : Sample(8),
      tradeTime         : Sample(8),
      trdType           : Sample(2),
      trdCancelFlag     : Sample(1),
      filler1           : Sample(1) ]

EncodeTradeTickerMessage(message) ==
    message.securityCode
        \o message.tickerId
        \o message.price
        \o message.aggregateQuantity
        \o message.tradeTime
        \o message.trdType
        \o message.trdCancelFlag
        \o message.filler1

DecodeTradeTickerMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET tickerId == ReadBytes(securityCode.rest, 4) IN IF ~tickerId.ok THEN Fail ELSE
    LET price == ReadBytes(tickerId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET aggregateQuantity == ReadBytes(price.rest, 8) IN IF ~aggregateQuantity.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(aggregateQuantity.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET trdType == ReadBytes(tradeTime.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdCancelFlag == ReadBytes(trdType.rest, 1) IN IF ~trdCancelFlag.ok THEN Fail ELSE
    LET filler1 == ReadBytes(trdCancelFlag.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ securityCode      |-> securityCode.value,
         tickerId          |-> tickerId.value,
         price             |-> price.value,
         aggregateQuantity |-> aggregateQuantity.value,
         tradeTime         |-> tradeTime.value,
         trdType           |-> trdType.value,
         trdCancelFlag     |-> trdCancelFlag.value,
         filler1           |-> filler1.value ], filler1.rest)

ZeroTradeTickerMessage ==
    [ securityCode      |-> [i \in 1 .. 4 |-> 0],
      tickerId          |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      aggregateQuantity |-> [i \in 1 .. 8 |-> 0],
      tradeTime         |-> [i \in 1 .. 8 |-> 0],
      trdType           |-> [i \in 1 .. 2 |-> 0],
      trdCancelFlag     |-> [i \in 1 .. 1 |-> 0],
      filler1           |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Ticker Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeTickerMessage ==
    { ZeroTradeTickerMessage }
        \cup { [ZeroTradeTickerMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.tickerId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.aggregateQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.trdCancelFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTickerMessage EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Vcm Trigger Message: 32 bytes                                           *)
(***************************************************************************)

VcmTriggerMessage ==
    [ securityCode        : Sample(4),
      coolingOffStartTime : Sample(8),
      coolingOffEndTime   : Sample(8),
      vcmReferencePrice   : Sample(4),
      vcmLowerPrice       : Sample(4),
      vcmUpperPrice       : Sample(4) ]

EncodeVcmTriggerMessage(message) ==
    message.securityCode
        \o message.coolingOffStartTime
        \o message.coolingOffEndTime
        \o message.vcmReferencePrice
        \o message.vcmLowerPrice
        \o message.vcmUpperPrice

DecodeVcmTriggerMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET coolingOffStartTime == ReadBytes(securityCode.rest, 8) IN IF ~coolingOffStartTime.ok THEN Fail ELSE
    LET coolingOffEndTime == ReadBytes(coolingOffStartTime.rest, 8) IN IF ~coolingOffEndTime.ok THEN Fail ELSE
    LET vcmReferencePrice == ReadBytes(coolingOffEndTime.rest, 4) IN IF ~vcmReferencePrice.ok THEN Fail ELSE
    LET vcmLowerPrice == ReadBytes(vcmReferencePrice.rest, 4) IN IF ~vcmLowerPrice.ok THEN Fail ELSE
    LET vcmUpperPrice == ReadBytes(vcmLowerPrice.rest, 4) IN IF ~vcmUpperPrice.ok THEN Fail ELSE
    Ok([ securityCode        |-> securityCode.value,
         coolingOffStartTime |-> coolingOffStartTime.value,
         coolingOffEndTime   |-> coolingOffEndTime.value,
         vcmReferencePrice   |-> vcmReferencePrice.value,
         vcmLowerPrice       |-> vcmLowerPrice.value,
         vcmUpperPrice       |-> vcmUpperPrice.value ], vcmUpperPrice.rest)

ZeroVcmTriggerMessage ==
    [ securityCode        |-> [i \in 1 .. 4 |-> 0],
      coolingOffStartTime |-> [i \in 1 .. 8 |-> 0],
      coolingOffEndTime   |-> [i \in 1 .. 8 |-> 0],
      vcmReferencePrice   |-> [i \in 1 .. 4 |-> 0],
      vcmLowerPrice       |-> [i \in 1 .. 4 |-> 0],
      vcmUpperPrice       |-> [i \in 1 .. 4 |-> 0] ]

(* Vcm Trigger Message at zero, then each field in turn at the values it is checked at *)
CheckedVcmTriggerMessage ==
    { ZeroVcmTriggerMessage }
        \cup { [ZeroVcmTriggerMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroVcmTriggerMessage EXCEPT !.coolingOffStartTime = one] : one \in Sample(8) }
        \cup { [ZeroVcmTriggerMessage EXCEPT !.coolingOffEndTime = one] : one \in Sample(8) }
        \cup { [ZeroVcmTriggerMessage EXCEPT !.vcmReferencePrice = one] : one \in Sample(4) }
        \cup { [ZeroVcmTriggerMessage EXCEPT !.vcmLowerPrice = one] : one \in Sample(4) }
        \cup { [ZeroVcmTriggerMessage EXCEPT !.vcmUpperPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

AddOddLotOrderMessageCode == 33  \* 0x21
AddOrderMessageCode == 30  \* 0x1e
AggregateOrderBookUpdateMessageCode == 53  \* 0x35
BrokerQueueMessageCode == 54  \* 0x36
ClosingPriceMessageCode == 62  \* 0x3e
SequenceResetMessageCode == 100  \* 0x64
DisasterRecoverySignalMessageCode == 105  \* 0x69
DeleteOddLotOrderMessageCode == 34  \* 0x22
DeleteOrderMessageCode == 32  \* 0x20
IndexDefinitionMessageCode == 70  \* 0x46
IndexDataMessageCode == 71  \* 0x47
IndicativeEquilibriumPriceMessageCode == 41  \* 0x29
ModifyOrderMessageCode == 31  \* 0x1f
NewsMessageCode == 22  \* 0x16
NominalPriceMessageCode == 40  \* 0x28
OrderImbalanceMessageCode == 56  \* 0x38
MarketDefinitionMessageCode == 10  \* 0x0a
SecurityDefinitionMessageCode == 11  \* 0x0b
LiquidityProviderMessageCode == 13  \* 0x0d
CurrencyRateMessageCode == 14  \* 0x0e
ReferencePriceMessageCode == 43  \* 0x2b
RefreshCompleteMessageCode == 203  \* 0xcb
LogonMessageCode == 101  \* 0x65
LogonResponseMessageCode == 102  \* 0x66
RetransmissionRequestMessageCode == 201  \* 0xc9
RetransmissionResponseMessageCode == 202  \* 0xca
StatisticsMessageCode == 60  \* 0x3c
MarketTurnoverMessageCode == 61  \* 0x3d
YieldMessageCode == 44  \* 0x2c
TradingSessionStatusMessageCode == 20  \* 0x14
SecurityStatusMessageCode == 21  \* 0x15
StockConnectDailyQuotaBalanceMessageCode == 80  \* 0x50
StockConnectMarketTurnoverMessageCode == 81  \* 0x51
TradeMessageCode == 50  \* 0x32
TradeCancelMessageCode == 51  \* 0x33
TradeTickerMessageCode == 52  \* 0x34
VcmTriggerMessageCode == 23  \* 0x17

Payload ==
    [ tag : {AddOddLotOrderMessageCode}, body : AddOddLotOrderMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AggregateOrderBookUpdateMessageCode}, body : AggregateOrderBookUpdateMessage ]
        \cup [ tag : {BrokerQueueMessageCode}, body : BrokerQueueMessage ]
        \cup [ tag : {ClosingPriceMessageCode}, body : ClosingPriceMessage ]
        \cup [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {DisasterRecoverySignalMessageCode}, body : DisasterRecoverySignalMessage ]
        \cup [ tag : {DeleteOddLotOrderMessageCode}, body : DeleteOddLotOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {IndexDefinitionMessageCode}, body : IndexDefinitionMessage ]
        \cup [ tag : {IndexDataMessageCode}, body : IndexDataMessage ]
        \cup [ tag : {IndicativeEquilibriumPriceMessageCode}, body : IndicativeEquilibriumPriceMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {NewsMessageCode}, body : NewsMessage ]
        \cup [ tag : {NominalPriceMessageCode}, body : NominalPriceMessage ]
        \cup [ tag : {OrderImbalanceMessageCode}, body : OrderImbalanceMessage ]
        \cup [ tag : {MarketDefinitionMessageCode}, body : MarketDefinitionMessage ]
        \cup [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {LiquidityProviderMessageCode}, body : LiquidityProviderMessage ]
        \cup [ tag : {CurrencyRateMessageCode}, body : CurrencyRateMessage ]
        \cup [ tag : {ReferencePriceMessageCode}, body : ReferencePriceMessage ]
        \cup [ tag : {RefreshCompleteMessageCode}, body : RefreshCompleteMessage ]
        \cup [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {RetransmissionResponseMessageCode}, body : RetransmissionResponseMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {MarketTurnoverMessageCode}, body : MarketTurnoverMessage ]
        \cup [ tag : {YieldMessageCode}, body : YieldMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {StockConnectDailyQuotaBalanceMessageCode}, body : StockConnectDailyQuotaBalanceMessage ]
        \cup [ tag : {StockConnectMarketTurnoverMessageCode}, body : StockConnectMarketTurnoverMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {TradeTickerMessageCode}, body : TradeTickerMessage ]
        \cup [ tag : {VcmTriggerMessageCode}, body : VcmTriggerMessage ]

EncodePayload(message) ==
    CASE message.tag = AddOddLotOrderMessageCode -> EncodeAddOddLotOrderMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AggregateOrderBookUpdateMessageCode -> EncodeAggregateOrderBookUpdateMessage(message.body)
      [] message.tag = BrokerQueueMessageCode -> EncodeBrokerQueueMessage(message.body)
      [] message.tag = ClosingPriceMessageCode -> EncodeClosingPriceMessage(message.body)
      [] message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = DisasterRecoverySignalMessageCode -> EncodeDisasterRecoverySignalMessage(message.body)
      [] message.tag = DeleteOddLotOrderMessageCode -> EncodeDeleteOddLotOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = IndexDefinitionMessageCode -> EncodeIndexDefinitionMessage(message.body)
      [] message.tag = IndexDataMessageCode -> EncodeIndexDataMessage(message.body)
      [] message.tag = IndicativeEquilibriumPriceMessageCode -> EncodeIndicativeEquilibriumPriceMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = NewsMessageCode -> EncodeNewsMessage(message.body)
      [] message.tag = NominalPriceMessageCode -> EncodeNominalPriceMessage(message.body)
      [] message.tag = OrderImbalanceMessageCode -> EncodeOrderImbalanceMessage(message.body)
      [] message.tag = MarketDefinitionMessageCode -> EncodeMarketDefinitionMessage(message.body)
      [] message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = LiquidityProviderMessageCode -> EncodeLiquidityProviderMessage(message.body)
      [] message.tag = CurrencyRateMessageCode -> EncodeCurrencyRateMessage(message.body)
      [] message.tag = ReferencePriceMessageCode -> EncodeReferencePriceMessage(message.body)
      [] message.tag = RefreshCompleteMessageCode -> EncodeRefreshCompleteMessage(message.body)
      [] message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = RetransmissionResponseMessageCode -> EncodeRetransmissionResponseMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = MarketTurnoverMessageCode -> EncodeMarketTurnoverMessage(message.body)
      [] message.tag = YieldMessageCode -> EncodeYieldMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = StockConnectDailyQuotaBalanceMessageCode -> EncodeStockConnectDailyQuotaBalanceMessage(message.body)
      [] message.tag = StockConnectMarketTurnoverMessageCode -> EncodeStockConnectMarketTurnoverMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = TradeTickerMessageCode -> EncodeTradeTickerMessage(message.body)
      [] message.tag = VcmTriggerMessageCode -> EncodeVcmTriggerMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AddOddLotOrderMessageCode -> DecodeAddOddLotOrderMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AggregateOrderBookUpdateMessageCode -> DecodeAggregateOrderBookUpdateMessage(bytes)
              [] tag = BrokerQueueMessageCode -> DecodeBrokerQueueMessage(bytes)
              [] tag = ClosingPriceMessageCode -> DecodeClosingPriceMessage(bytes)
              [] tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = DisasterRecoverySignalMessageCode -> DecodeDisasterRecoverySignalMessage(bytes)
              [] tag = DeleteOddLotOrderMessageCode -> DecodeDeleteOddLotOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = IndexDefinitionMessageCode -> DecodeIndexDefinitionMessage(bytes)
              [] tag = IndexDataMessageCode -> DecodeIndexDataMessage(bytes)
              [] tag = IndicativeEquilibriumPriceMessageCode -> DecodeIndicativeEquilibriumPriceMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = NewsMessageCode -> DecodeNewsMessage(bytes)
              [] tag = NominalPriceMessageCode -> DecodeNominalPriceMessage(bytes)
              [] tag = OrderImbalanceMessageCode -> DecodeOrderImbalanceMessage(bytes)
              [] tag = MarketDefinitionMessageCode -> DecodeMarketDefinitionMessage(bytes)
              [] tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = LiquidityProviderMessageCode -> DecodeLiquidityProviderMessage(bytes)
              [] tag = CurrencyRateMessageCode -> DecodeCurrencyRateMessage(bytes)
              [] tag = ReferencePriceMessageCode -> DecodeReferencePriceMessage(bytes)
              [] tag = RefreshCompleteMessageCode -> DecodeRefreshCompleteMessage(bytes)
              [] tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = RetransmissionResponseMessageCode -> DecodeRetransmissionResponseMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = MarketTurnoverMessageCode -> DecodeMarketTurnoverMessage(bytes)
              [] tag = YieldMessageCode -> DecodeYieldMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = StockConnectDailyQuotaBalanceMessageCode -> DecodeStockConnectDailyQuotaBalanceMessage(bytes)
              [] tag = StockConnectMarketTurnoverMessageCode -> DecodeStockConnectMarketTurnoverMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = TradeTickerMessageCode -> DecodeTradeTickerMessage(bytes)
              [] tag = VcmTriggerMessageCode -> DecodeVcmTriggerMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AddOddLotOrderMessageCode, body |-> ZeroAddOddLotOrderMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AddOddLotOrderMessageCode, body |-> one] : one \in CheckedAddOddLotOrderMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AggregateOrderBookUpdateMessageCode, body |-> one] : one \in CheckedAggregateOrderBookUpdateMessage }
        \cup { [tag |-> BrokerQueueMessageCode, body |-> one] : one \in CheckedBrokerQueueMessage }
        \cup { [tag |-> ClosingPriceMessageCode, body |-> one] : one \in CheckedClosingPriceMessage }
        \cup { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> DisasterRecoverySignalMessageCode, body |-> one] : one \in CheckedDisasterRecoverySignalMessage }
        \cup { [tag |-> DeleteOddLotOrderMessageCode, body |-> one] : one \in CheckedDeleteOddLotOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> IndexDefinitionMessageCode, body |-> one] : one \in CheckedIndexDefinitionMessage }
        \cup { [tag |-> IndexDataMessageCode, body |-> one] : one \in CheckedIndexDataMessage }
        \cup { [tag |-> IndicativeEquilibriumPriceMessageCode, body |-> one] : one \in CheckedIndicativeEquilibriumPriceMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> NewsMessageCode, body |-> one] : one \in CheckedNewsMessage }
        \cup { [tag |-> NominalPriceMessageCode, body |-> one] : one \in CheckedNominalPriceMessage }
        \cup { [tag |-> OrderImbalanceMessageCode, body |-> one] : one \in CheckedOrderImbalanceMessage }
        \cup { [tag |-> MarketDefinitionMessageCode, body |-> one] : one \in CheckedMarketDefinitionMessage }
        \cup { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> LiquidityProviderMessageCode, body |-> one] : one \in CheckedLiquidityProviderMessage }
        \cup { [tag |-> CurrencyRateMessageCode, body |-> one] : one \in CheckedCurrencyRateMessage }
        \cup { [tag |-> ReferencePriceMessageCode, body |-> one] : one \in CheckedReferencePriceMessage }
        \cup { [tag |-> RefreshCompleteMessageCode, body |-> one] : one \in CheckedRefreshCompleteMessage }
        \cup { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> RetransmissionResponseMessageCode, body |-> one] : one \in CheckedRetransmissionResponseMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> MarketTurnoverMessageCode, body |-> one] : one \in CheckedMarketTurnoverMessage }
        \cup { [tag |-> YieldMessageCode, body |-> one] : one \in CheckedYieldMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> StockConnectDailyQuotaBalanceMessageCode, body |-> one] : one \in CheckedStockConnectDailyQuotaBalanceMessage }
        \cup { [tag |-> StockConnectMarketTurnoverMessageCode, body |-> one] : one \in CheckedStockConnectMarketTurnoverMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }
        \cup { [tag |-> TradeTickerMessageCode, body |-> one] : one \in CheckedTradeTickerMessage }
        \cup { [tag |-> VcmTriggerMessageCode, body |-> one] : one \in CheckedVcmTriggerMessage }

(***************************************************************************)
(* Message, framed by Msg Size                                             *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Msg Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AddOddLotOrderMessageCode, body |-> ZeroAddOddLotOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AggregateOrderBookUpdateMessageCode, body |-> ZeroAggregateOrderBookUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BrokerQueueMessageCode, body |-> ZeroBrokerQueueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClosingPriceMessageCode, body |-> ZeroClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DisasterRecoverySignalMessageCode, body |-> ZeroDisasterRecoverySignalMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOddLotOrderMessageCode, body |-> ZeroDeleteOddLotOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexDefinitionMessageCode, body |-> ZeroIndexDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexDataMessageCode, body |-> ZeroIndexDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndicativeEquilibriumPriceMessageCode, body |-> ZeroIndicativeEquilibriumPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderMessageCode, body |-> ZeroModifyOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewsMessageCode, body |-> ZeroNewsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NominalPriceMessageCode, body |-> ZeroNominalPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderImbalanceMessageCode, body |-> ZeroOrderImbalanceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketDefinitionMessageCode, body |-> ZeroMarketDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LiquidityProviderMessageCode, body |-> ZeroLiquidityProviderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CurrencyRateMessageCode, body |-> ZeroCurrencyRateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReferencePriceMessageCode, body |-> ZeroReferencePriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshCompleteMessageCode, body |-> ZeroRefreshCompleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionResponseMessageCode, body |-> ZeroRetransmissionResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketTurnoverMessageCode, body |-> ZeroMarketTurnoverMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> YieldMessageCode, body |-> ZeroYieldMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingSessionStatusMessageCode, body |-> ZeroTradingSessionStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockConnectDailyQuotaBalanceMessageCode, body |-> ZeroStockConnectDailyQuotaBalanceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockConnectMarketTurnoverMessageCode, body |-> ZeroStockConnectMarketTurnoverMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancelMessageCode, body |-> ZeroTradeCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeTickerMessageCode, body |-> ZeroTradeTickerMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> VcmTriggerMessageCode, body |-> ZeroVcmTriggerMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize  : Sample(2),
      filler   : Sample(1),
      seqNum   : Sample(4),
      sendTime : Sample(8),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.filler
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET filler == ReadBytes(msgCount.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET seqNum == ReadBytes(filler.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sendTime.rest, msgCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ pktSize  |-> pktSize.value,
         filler   |-> filler.value,
         seqNum   |-> seqNum.value,
         sendTime |-> sendTime.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ pktSize  |-> [i \in 1 .. 2 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0],
      seqNum   |-> [i \in 1 .. 4 |-> 0],
      sendTime |-> [i \in 1 .. 8 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
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

(* Every Add Odd Lot Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOddLotOrderMessage ==
    \A message \in CheckedAddOddLotOrderMessage :
        LET read == DecodeAddOddLotOrderMessage(EncodeAddOddLotOrderMessage(message))
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

(* Every Book Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripBookEntry ==
    \A message \in CheckedBookEntry :
        LET read == DecodeBookEntry(EncodeBookEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aggregate Order Book Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAggregateOrderBookUpdateMessage ==
    \A message \in CheckedAggregateOrderBookUpdateMessage :
        LET read == DecodeAggregateOrderBookUpdateMessage(EncodeAggregateOrderBookUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bq Item decodes back to what was encoded, and leaves nothing over *)
RoundTripBqItem ==
    \A message \in CheckedBqItem :
        LET read == DecodeBqItem(EncodeBqItem(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broker Queue Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokerQueueMessage ==
    \A message \in CheckedBrokerQueueMessage :
        LET read == DecodeBrokerQueueMessage(EncodeBrokerQueueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClosingPriceMessage ==
    \A message \in CheckedClosingPriceMessage :
        LET read == DecodeClosingPriceMessage(EncodeClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disaster Recovery Signal Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDisasterRecoverySignalMessage ==
    \A message \in CheckedDisasterRecoverySignalMessage :
        LET read == DecodeDisasterRecoverySignalMessage(EncodeDisasterRecoverySignalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Odd Lot Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOddLotOrderMessage ==
    \A message \in CheckedDeleteOddLotOrderMessage :
        LET read == DecodeDeleteOddLotOrderMessage(EncodeDeleteOddLotOrderMessage(message))
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

(* Every Index Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexDefinitionMessage ==
    \A message \in CheckedIndexDefinitionMessage :
        LET read == DecodeIndexDefinitionMessage(EncodeIndexDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexDataMessage ==
    \A message \in CheckedIndexDataMessage :
        LET read == DecodeIndexDataMessage(EncodeIndexDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indicative Equilibrium Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicativeEquilibriumPriceMessage ==
    \A message \in CheckedIndicativeEquilibriumPriceMessage :
        LET read == DecodeIndicativeEquilibriumPriceMessage(EncodeIndicativeEquilibriumPriceMessage(message))
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

(* Every News Market decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsMarket ==
    \A message \in CheckedNewsMarket :
        LET read == DecodeNewsMarket(EncodeNewsMarket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Security decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsSecurity ==
    \A message \in CheckedNewsSecurity :
        LET read == DecodeNewsSecurity(EncodeNewsSecurity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Line Item decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsLineItem ==
    \A message \in CheckedNewsLineItem :
        LET read == DecodeNewsLineItem(EncodeNewsLineItem(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsMessage ==
    \A message \in CheckedNewsMessage :
        LET read == DecodeNewsMessage(EncodeNewsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nominal Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNominalPriceMessage ==
    \A message \in CheckedNominalPriceMessage :
        LET read == DecodeNominalPriceMessage(EncodeNominalPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderImbalanceMessage ==
    \A message \in CheckedOrderImbalanceMessage :
        LET read == DecodeOrderImbalanceMessage(EncodeOrderImbalanceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDefinitionMessage ==
    \A message \in CheckedMarketDefinitionMessage :
        LET read == DecodeMarketDefinitionMessage(EncodeMarketDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Security decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingSecurity ==
    \A message \in CheckedUnderlyingSecurity :
        LET read == DecodeUnderlyingSecurity(EncodeUnderlyingSecurity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessage ==
    \A message \in CheckedSecurityDefinitionMessage :
        LET read == DecodeSecurityDefinitionMessage(EncodeSecurityDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Provider decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProvider ==
    \A message \in CheckedLiquidityProvider :
        LET read == DecodeLiquidityProvider(EncodeLiquidityProvider(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Provider Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProviderMessage ==
    \A message \in CheckedLiquidityProviderMessage :
        LET read == DecodeLiquidityProviderMessage(EncodeLiquidityProviderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Currency Rate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCurrencyRateMessage ==
    \A message \in CheckedCurrencyRateMessage :
        LET read == DecodeCurrencyRateMessage(EncodeCurrencyRateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferencePriceMessage ==
    \A message \in CheckedReferencePriceMessage :
        LET read == DecodeReferencePriceMessage(EncodeReferencePriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshCompleteMessage ==
    \A message \in CheckedRefreshCompleteMessage :
        LET read == DecodeRefreshCompleteMessage(EncodeRefreshCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonResponseMessage ==
    \A message \in CheckedLogonResponseMessage :
        LET read == DecodeLogonResponseMessage(EncodeLogonResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionResponseMessage ==
    \A message \in CheckedRetransmissionResponseMessage :
        LET read == DecodeRetransmissionResponseMessage(EncodeRetransmissionResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsMessage ==
    \A message \in CheckedStatisticsMessage :
        LET read == DecodeStatisticsMessage(EncodeStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Turnover Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketTurnoverMessage ==
    \A message \in CheckedMarketTurnoverMessage :
        LET read == DecodeMarketTurnoverMessage(EncodeMarketTurnoverMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Yield Message decodes back to what was encoded, and leaves nothing over *)
RoundTripYieldMessage ==
    \A message \in CheckedYieldMessage :
        LET read == DecodeYieldMessage(EncodeYieldMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusMessage ==
    \A message \in CheckedTradingSessionStatusMessage :
        LET read == DecodeTradingSessionStatusMessage(EncodeTradingSessionStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusMessage ==
    \A message \in CheckedSecurityStatusMessage :
        LET read == DecodeSecurityStatusMessage(EncodeSecurityStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Connect Daily Quota Balance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockConnectDailyQuotaBalanceMessage ==
    \A message \in CheckedStockConnectDailyQuotaBalanceMessage :
        LET read == DecodeStockConnectDailyQuotaBalanceMessage(EncodeStockConnectDailyQuotaBalanceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Connect Market Turnover Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockConnectMarketTurnoverMessage ==
    \A message \in CheckedStockConnectMarketTurnoverMessage :
        LET read == DecodeStockConnectMarketTurnoverMessage(EncodeStockConnectMarketTurnoverMessage(message))
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

(* Every Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelMessage ==
    \A message \in CheckedTradeCancelMessage :
        LET read == DecodeTradeCancelMessage(EncodeTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Ticker Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeTickerMessage ==
    \A message \in CheckedTradeTickerMessage :
        LET read == DecodeTradeTickerMessage(EncodeTradeTickerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Vcm Trigger Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVcmTriggerMessage ==
    \A message \in CheckedVcmTriggerMessage :
        LET read == DecodeVcmTriggerMessage(EncodeVcmTriggerMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
