------------------- MODULE CixAts_CixAspen_Snapshot_v1_1 -------------------
(***************************************************************************)
(* CIX Trading Inc. CIX Tcp Snapshot v1.1                                  *)
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
(* Note: Binary Data Message fills what is left of the frame Length        *)
(* states, which is what it is read from.                                  *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Login Message: 46 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ user                : Sample(6),
      pass                : Sample(10),
      marketDayIdentifier : Sample(9),
      feedIdentifier      : Sample(1),
      requestedSequence   : Sample(20) ]

EncodeLoginMessage(message) ==
    message.user
        \o message.pass
        \o message.marketDayIdentifier
        \o message.feedIdentifier
        \o message.requestedSequence

DecodeLoginMessage(bytes) ==
    LET user == ReadBytes(bytes, 6) IN IF ~user.ok THEN Fail ELSE
    LET pass == ReadBytes(user.rest, 10) IN IF ~pass.ok THEN Fail ELSE
    LET marketDayIdentifier == ReadBytes(pass.rest, 9) IN IF ~marketDayIdentifier.ok THEN Fail ELSE
    LET feedIdentifier == ReadBytes(marketDayIdentifier.rest, 1) IN IF ~feedIdentifier.ok THEN Fail ELSE
    LET requestedSequence == ReadBytes(feedIdentifier.rest, 20) IN IF ~requestedSequence.ok THEN Fail ELSE
    Ok([ user                |-> user.value,
         pass                |-> pass.value,
         marketDayIdentifier |-> marketDayIdentifier.value,
         feedIdentifier      |-> feedIdentifier.value,
         requestedSequence   |-> requestedSequence.value ], requestedSequence.rest)

ZeroLoginMessage ==
    [ user                |-> [i \in 1 .. 6 |-> 0],
      pass                |-> [i \in 1 .. 10 |-> 0],
      marketDayIdentifier |-> [i \in 1 .. 9 |-> 0],
      feedIdentifier      |-> [i \in 1 .. 1 |-> 0],
      requestedSequence   |-> [i \in 1 .. 20 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.user = one] : one \in Sample(6) }
        \cup { [ZeroLoginMessage EXCEPT !.pass = one] : one \in Sample(10) }
        \cup { [ZeroLoginMessage EXCEPT !.marketDayIdentifier = one] : one \in Sample(9) }
        \cup { [ZeroLoginMessage EXCEPT !.feedIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroLoginMessage EXCEPT !.requestedSequence = one] : one \in Sample(20) }

(***************************************************************************)
(* Successful Login Message: 30 bytes                                      *)
(***************************************************************************)

SuccessfulLoginMessage ==
    [ marketDayIdentifier : Sample(9),
      feedIdentifier      : Sample(1),
      nextSequence        : Sample(20) ]

EncodeSuccessfulLoginMessage(message) ==
    message.marketDayIdentifier
        \o message.feedIdentifier
        \o message.nextSequence

DecodeSuccessfulLoginMessage(bytes) ==
    LET marketDayIdentifier == ReadBytes(bytes, 9) IN IF ~marketDayIdentifier.ok THEN Fail ELSE
    LET feedIdentifier == ReadBytes(marketDayIdentifier.rest, 1) IN IF ~feedIdentifier.ok THEN Fail ELSE
    LET nextSequence == ReadBytes(feedIdentifier.rest, 20) IN IF ~nextSequence.ok THEN Fail ELSE
    Ok([ marketDayIdentifier |-> marketDayIdentifier.value,
         feedIdentifier      |-> feedIdentifier.value,
         nextSequence        |-> nextSequence.value ], nextSequence.rest)

ZeroSuccessfulLoginMessage ==
    [ marketDayIdentifier |-> [i \in 1 .. 9 |-> 0],
      feedIdentifier      |-> [i \in 1 .. 1 |-> 0],
      nextSequence        |-> [i \in 1 .. 20 |-> 0] ]

(* Successful Login Message at zero, then each field in turn at the values it is checked at *)
CheckedSuccessfulLoginMessage ==
    { ZeroSuccessfulLoginMessage }
        \cup { [ZeroSuccessfulLoginMessage EXCEPT !.marketDayIdentifier = one] : one \in Sample(9) }
        \cup { [ZeroSuccessfulLoginMessage EXCEPT !.feedIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroSuccessfulLoginMessage EXCEPT !.nextSequence = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Reject Message: 1 bytes                                           *)
(***************************************************************************)

LoginRejectMessage ==
    [ reasonCode : Sample(1) ]

EncodeLoginRejectMessage(message) ==
    message.reasonCode

DecodeLoginRejectMessage(bytes) ==
    LET reasonCode == ReadBytes(bytes, 1) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ reasonCode |-> reasonCode.value ], reasonCode.rest)

ZeroLoginRejectMessage ==
    [ reasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectMessage ==
    { ZeroLoginRejectMessage }
        \cup { [ZeroLoginRejectMessage EXCEPT !.reasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Event Message: 11 bytes                                          *)
(***************************************************************************)

MarketEventMessage ==
    [ reserved2 : Sample(2),
      timestamp : Sample(8),
      event     : Sample(1) ]

EncodeMarketEventMessage(message) ==
    message.reserved2
        \o message.timestamp
        \o message.event

DecodeMarketEventMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET timestamp == ReadBytes(reserved2.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET event == ReadBytes(timestamp.rest, 1) IN IF ~event.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         timestamp |-> timestamp.value,
         event     |-> event.value ], event.rest)

ZeroMarketEventMessage ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      timestamp |-> [i \in 1 .. 8 |-> 0],
      event     |-> [i \in 1 .. 1 |-> 0] ]

(* Market Event Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketEventMessage ==
    { ZeroMarketEventMessage }
        \cup { [ZeroMarketEventMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroMarketEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketEventMessage EXCEPT !.event = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Information Message: 26 bytes                                    *)
(***************************************************************************)

SymbolInformationMessage ==
    [ timestamp     : Sample(8),
      symbolId      : Sample(2),
      symbol        : Sample(11),
      listingMarket : Sample(1),
      boardLotSize  : Sample(4) ]

EncodeSymbolInformationMessage(message) ==
    message.timestamp
        \o message.symbolId
        \o message.symbol
        \o message.listingMarket
        \o message.boardLotSize

DecodeSymbolInformationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolId == ReadBytes(timestamp.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET symbol == ReadBytes(symbolId.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(symbol.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET boardLotSize == ReadBytes(listingMarket.rest, 4) IN IF ~boardLotSize.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbolId      |-> symbolId.value,
         symbol        |-> symbol.value,
         listingMarket |-> listingMarket.value,
         boardLotSize  |-> boardLotSize.value ], boardLotSize.rest)

ZeroSymbolInformationMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbolId      |-> [i \in 1 .. 2 |-> 0],
      symbol        |-> [i \in 1 .. 11 |-> 0],
      listingMarket |-> [i \in 1 .. 1 |-> 0],
      boardLotSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Information Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolInformationMessage ==
    { ZeroSymbolInformationMessage }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroSymbolInformationMessage EXCEPT !.boardLotSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol State Message: 27 bytes                                          *)
(***************************************************************************)

SymbolStateMessage ==
    [ timestamp : Sample(8),
      symbolId  : Sample(2),
      symbol    : Sample(11),
      state     : Sample(1),
      reserved1 : Sample(1),
      info      : Sample(4) ]

EncodeSymbolStateMessage(message) ==
    message.timestamp
        \o message.symbolId
        \o message.symbol
        \o message.state
        \o message.reserved1
        \o message.info

DecodeSymbolStateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolId == ReadBytes(timestamp.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET symbol == ReadBytes(symbolId.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET state == ReadBytes(symbol.rest, 1) IN IF ~state.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(state.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET info == ReadBytes(reserved1.rest, 4) IN IF ~info.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         symbolId  |-> symbolId.value,
         symbol    |-> symbol.value,
         state     |-> state.value,
         reserved1 |-> reserved1.value,
         info      |-> info.value ], info.rest)

ZeroSymbolStateMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      symbolId  |-> [i \in 1 .. 2 |-> 0],
      symbol    |-> [i \in 1 .. 11 |-> 0],
      state     |-> [i \in 1 .. 1 |-> 0],
      reserved1 |-> [i \in 1 .. 1 |-> 0],
      info      |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol State Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStateMessage ==
    { ZeroSymbolStateMessage }
        \cup { [ZeroSymbolStateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.state = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStateMessage EXCEPT !.info = one] : one \in Sample(4) }

(***************************************************************************)
(* New Order Add Message: 50 bytes                                         *)
(***************************************************************************)

NewOrderAddMessage ==
    [ timestamp : Sample(8),
      symbolId  : Sample(2),
      orderId   : Sample(8),
      side      : Sample(1),
      quantity  : Sample(8),
      symbol    : Sample(11),
      price     : Sample(8),
      broker    : Sample(3),
      reserved1 : Sample(1) ]

EncodeNewOrderAddMessage(message) ==
    message.timestamp
        \o message.symbolId
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.symbol
        \o message.price
        \o message.broker
        \o message.reserved1

DecodeNewOrderAddMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbolId == ReadBytes(timestamp.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET broker == ReadBytes(price.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(broker.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         symbolId  |-> symbolId.value,
         orderId   |-> orderId.value,
         side      |-> side.value,
         quantity  |-> quantity.value,
         symbol    |-> symbol.value,
         price     |-> price.value,
         broker    |-> broker.value,
         reserved1 |-> reserved1.value ], reserved1.rest)

ZeroNewOrderAddMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      symbolId  |-> [i \in 1 .. 2 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      side      |-> [i \in 1 .. 1 |-> 0],
      quantity  |-> [i \in 1 .. 8 |-> 0],
      symbol    |-> [i \in 1 .. 11 |-> 0],
      price     |-> [i \in 1 .. 8 |-> 0],
      broker    |-> [i \in 1 .. 3 |-> 0],
      reserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderAddMessage ==
    { ZeroNewOrderAddMessage }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderAddMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Partial Cancel Message: 24 bytes                                  *)
(***************************************************************************)

OrderPartialCancelMessage ==
    [ timestamp        : Sample(8),
      orderId          : Sample(8),
      quantityCanceled : Sample(8) ]

EncodeOrderPartialCancelMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.quantityCanceled

DecodeOrderPartialCancelMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantityCanceled == ReadBytes(orderId.rest, 8) IN IF ~quantityCanceled.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         orderId          |-> orderId.value,
         quantityCanceled |-> quantityCanceled.value ], quantityCanceled.rest)

ZeroOrderPartialCancelMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      quantityCanceled |-> [i \in 1 .. 8 |-> 0] ]

(* Order Partial Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderPartialCancelMessage ==
    { ZeroOrderPartialCancelMessage }
        \cup { [ZeroOrderPartialCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderPartialCancelMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPartialCancelMessage EXCEPT !.quantityCanceled = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel All Message: 16 bytes                                      *)
(***************************************************************************)

OrderCancelAllMessage ==
    [ timestamp : Sample(8),
      orderId   : Sample(8) ]

EncodeOrderCancelAllMessage(message) ==
    message.timestamp
        \o message.orderId

DecodeOrderCancelAllMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         orderId   |-> orderId.value ], orderId.rest)

ZeroOrderCancelAllMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel All Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelAllMessage ==
    { ZeroOrderCancelAllMessage }
        \cup { [ZeroOrderCancelAllMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelAllMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed Message: 47 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp    : Sample(8),
      orderId      : Sample(8),
      quantity     : Sample(8),
      executionId  : Sample(8),
      side         : Sample(1),
      price        : Sample(8),
      broker       : Sample(3),
      contraBroker : Sample(3) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.orderId
        \o message.quantity
        \o message.executionId
        \o message.side
        \o message.price
        \o message.broker
        \o message.contraBroker

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderId == ReadBytes(timestamp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(quantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET side == ReadBytes(executionId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET broker == ReadBytes(price.rest, 3) IN IF ~broker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(broker.rest, 3) IN IF ~contraBroker.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         orderId      |-> orderId.value,
         quantity     |-> quantity.value,
         executionId  |-> executionId.value,
         side         |-> side.value,
         price        |-> price.value,
         broker       |-> broker.value,
         contraBroker |-> contraBroker.value ], contraBroker.rest)

ZeroOrderExecutedMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      quantity     |-> [i \in 1 .. 8 |-> 0],
      executionId  |-> [i \in 1 .. 8 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      broker       |-> [i \in 1 .. 3 |-> 0],
      contraBroker |-> [i \in 1 .. 3 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.broker = one] : one \in Sample(3) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.contraBroker = one] : one \in Sample(3) }

(***************************************************************************)
(* End Of Snapshot Message: 8 bytes                                        *)
(***************************************************************************)

EndOfSnapshotMessage ==
    [ sequence : Sample(8) ]

EncodeEndOfSnapshotMessage(message) ==
    message.sequence

DecodeEndOfSnapshotMessage(bytes) ==
    LET sequence == ReadBytes(bytes, 8) IN IF ~sequence.ok THEN Fail ELSE
    Ok([ sequence |-> sequence.value ], sequence.rest)

ZeroEndOfSnapshotMessage ==
    [ sequence |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSnapshotMessage ==
    { ZeroEndOfSnapshotMessage }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.sequence = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

MarketEventMessageCode == 65  \* "A"
SymbolInformationMessageCode == 66  \* "B"
SymbolStateMessageCode == 67  \* "C"
NewOrderAddMessageCode == 68  \* "D"
OrderPartialCancelMessageCode == 70  \* "F"
OrderCancelAllMessageCode == 71  \* "G"
OrderExecutedMessageCode == 74  \* "J"
EndOfSnapshotMessageCode == 88  \* "X"

Payload ==
    [ tag : {MarketEventMessageCode}, body : MarketEventMessage ]
        \cup [ tag : {SymbolInformationMessageCode}, body : SymbolInformationMessage ]
        \cup [ tag : {SymbolStateMessageCode}, body : SymbolStateMessage ]
        \cup [ tag : {NewOrderAddMessageCode}, body : NewOrderAddMessage ]
        \cup [ tag : {OrderPartialCancelMessageCode}, body : OrderPartialCancelMessage ]
        \cup [ tag : {OrderCancelAllMessageCode}, body : OrderCancelAllMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {EndOfSnapshotMessageCode}, body : EndOfSnapshotMessage ]

EncodePayload(message) ==
    CASE message.tag = MarketEventMessageCode -> EncodeMarketEventMessage(message.body)
      [] message.tag = SymbolInformationMessageCode -> EncodeSymbolInformationMessage(message.body)
      [] message.tag = SymbolStateMessageCode -> EncodeSymbolStateMessage(message.body)
      [] message.tag = NewOrderAddMessageCode -> EncodeNewOrderAddMessage(message.body)
      [] message.tag = OrderPartialCancelMessageCode -> EncodeOrderPartialCancelMessage(message.body)
      [] message.tag = OrderCancelAllMessageCode -> EncodeOrderCancelAllMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = EndOfSnapshotMessageCode -> EncodeEndOfSnapshotMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = MarketEventMessageCode -> DecodeMarketEventMessage(bytes)
              [] tag = SymbolInformationMessageCode -> DecodeSymbolInformationMessage(bytes)
              [] tag = SymbolStateMessageCode -> DecodeSymbolStateMessage(bytes)
              [] tag = NewOrderAddMessageCode -> DecodeNewOrderAddMessage(bytes)
              [] tag = OrderPartialCancelMessageCode -> DecodeOrderPartialCancelMessage(bytes)
              [] tag = OrderCancelAllMessageCode -> DecodeOrderCancelAllMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = EndOfSnapshotMessageCode -> DecodeEndOfSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> MarketEventMessageCode, body |-> ZeroMarketEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> MarketEventMessageCode, body |-> one] : one \in CheckedMarketEventMessage }
        \cup { [tag |-> SymbolInformationMessageCode, body |-> one] : one \in CheckedSymbolInformationMessage }
        \cup { [tag |-> SymbolStateMessageCode, body |-> one] : one \in CheckedSymbolStateMessage }
        \cup { [tag |-> NewOrderAddMessageCode, body |-> one] : one \in CheckedNewOrderAddMessage }
        \cup { [tag |-> OrderPartialCancelMessageCode, body |-> one] : one \in CheckedOrderPartialCancelMessage }
        \cup { [tag |-> OrderCancelAllMessageCode, body |-> one] : one \in CheckedOrderCancelAllMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> EndOfSnapshotMessageCode, body |-> one] : one \in CheckedEndOfSnapshotMessage }

(***************************************************************************)
(* Binary Data Message                                                     *)
(***************************************************************************)

BinaryDataMessage ==
    [ payload : Payload ]

EncodeBinaryDataMessage(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

DecodeBinaryDataMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

ZeroBinaryDataMessage ==
    [ payload |-> ZeroPayload ]

(* Binary Data Message at zero, then each field in turn at the values it is checked at *)
CheckedBinaryDataMessage ==
    { ZeroBinaryDataMessage }
        \cup { [ZeroBinaryDataMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Packet Payload, selected by Packet Type                                 *)
(***************************************************************************)

LoginMessageCode == 76  \* "L"
ClientHeartbeatMessageCode == 82  \* "R"
SuccessfulLoginMessageCode == 65  \* "A"
LoginRejectMessageCode == 74  \* "J"
ServerHeartbeatMessageCode == 72  \* "H"
BinaryDataMessageCode == 83  \* "S"

PacketPayload ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SuccessfulLoginMessageCode}, body : SuccessfulLoginMessage ]
        \cup [ tag : {LoginRejectMessageCode}, body : LoginRejectMessage ]
        \cup [ tag : {ServerHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {BinaryDataMessageCode}, body : BinaryDataMessage ]

EncodePacketPayload(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = SuccessfulLoginMessageCode -> EncodeSuccessfulLoginMessage(message.body)
      [] message.tag = LoginRejectMessageCode -> EncodeLoginRejectMessage(message.body)
      [] message.tag = ServerHeartbeatMessageCode -> << >>
      [] message.tag = BinaryDataMessageCode -> EncodeBinaryDataMessage(message.body)

DecodePacketPayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SuccessfulLoginMessageCode -> DecodeSuccessfulLoginMessage(bytes)
              [] tag = LoginRejectMessageCode -> DecodeLoginRejectMessage(bytes)
              [] tag = ServerHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = BinaryDataMessageCode -> DecodeBinaryDataMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPacketPayload == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Packet Payload in turn, at the values the message it names is checked at *)
CheckedPacketPayload ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SuccessfulLoginMessageCode, body |-> one] : one \in CheckedSuccessfulLoginMessage }
        \cup { [tag |-> LoginRejectMessageCode, body |-> one] : one \in CheckedLoginRejectMessage }
        \cup { [tag |-> ServerHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> BinaryDataMessageCode, body |-> one] : one \in CheckedBinaryDataMessage }

(***************************************************************************)
(* Tcp Packet, framed by Length                                            *)
(***************************************************************************)

TcpPacket ==
    [ packetPayload : PacketPayload ]

EncodeTcpPacketBody(message) ==
    EncodeUIntBE(message.packetPayload.tag, 1)
        \o EncodePacketPayload(message.packetPayload)

(* Length counts the bytes it frames, so it is written from them *)
EncodeTcpPacket(message) ==
    LET body == EncodeTcpPacketBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeTcpPacketBody(bytes) ==
    LET packetType == ReadUIntBE(bytes, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET packetPayload == DecodePacketPayload(packetType.value, packetType.rest) IN IF ~packetPayload.ok THEN Fail ELSE
    Ok([ packetPayload |-> packetPayload.value ], packetPayload.rest)

DecodeTcpPacket(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTcpPacket ==
    [ packetPayload |-> ZeroPacketPayload ]

(* Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedTcpPacket ==
    { ZeroTcpPacket }
        \cup { [ZeroTcpPacket EXCEPT !.packetPayload = one] : one \in CheckedPacketPayload }

(* A run of Tcp Packet, written one after another *)
RECURSIVE EncodeTcpPacketList(_)
EncodeTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTcpPacket(Head(messages)) \o EncodeTcpPacketList(Tail(messages))

(* As many Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTcpPacketAll(_)
ReadTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tcp Packet of each kind, for the lists that carry them *)
OneTcpPacket ==
    { [ZeroTcpPacket EXCEPT !.packetPayload = [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]],
      [ZeroTcpPacket EXCEPT !.packetPayload = [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroTcpPacket EXCEPT !.packetPayload = [tag |-> SuccessfulLoginMessageCode, body |-> ZeroSuccessfulLoginMessage]],
      [ZeroTcpPacket EXCEPT !.packetPayload = [tag |-> LoginRejectMessageCode, body |-> ZeroLoginRejectMessage]],
      [ZeroTcpPacket EXCEPT !.packetPayload = [tag |-> ServerHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroTcpPacket EXCEPT !.packetPayload = [tag |-> BinaryDataMessageCode, body |-> ZeroBinaryDataMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ tcpPacket : SampleLists(OneTcpPacket) ]

EncodePacket(message) ==
    EncodeTcpPacketList(message.tcpPacket)

DecodePacket(bytes) ==
    LET tcpPacket == ReadTcpPacketAll(bytes) IN IF ~tcpPacket.ok THEN Fail ELSE
    Ok([ tcpPacket |-> tcpPacket.value ], tcpPacket.rest)

ZeroPacket ==
    [ tcpPacket |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.tcpPacket = one] : one \in SampleLists(OneTcpPacket) }

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

(* Every Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET read == DecodeLoginMessage(EncodeLoginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Successful Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSuccessfulLoginMessage ==
    \A message \in CheckedSuccessfulLoginMessage :
        LET read == DecodeSuccessfulLoginMessage(EncodeSuccessfulLoginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectMessage ==
    \A message \in CheckedLoginRejectMessage :
        LET read == DecodeLoginRejectMessage(EncodeLoginRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketEventMessage ==
    \A message \in CheckedMarketEventMessage :
        LET read == DecodeMarketEventMessage(EncodeMarketEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolInformationMessage ==
    \A message \in CheckedSymbolInformationMessage :
        LET read == DecodeSymbolInformationMessage(EncodeSymbolInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStateMessage ==
    \A message \in CheckedSymbolStateMessage :
        LET read == DecodeSymbolStateMessage(EncodeSymbolStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderAddMessage ==
    \A message \in CheckedNewOrderAddMessage :
        LET read == DecodeNewOrderAddMessage(EncodeNewOrderAddMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Partial Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPartialCancelMessage ==
    \A message \in CheckedOrderPartialCancelMessage :
        LET read == DecodeOrderPartialCancelMessage(EncodeOrderPartialCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel All Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelAllMessage ==
    \A message \in CheckedOrderCancelAllMessage :
        LET read == DecodeOrderCancelAllMessage(EncodeOrderCancelAllMessage(message))
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

(* Every End Of Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSnapshotMessage ==
    \A message \in CheckedEndOfSnapshotMessage :
        LET read == DecodeEndOfSnapshotMessage(EncodeEndOfSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Binary Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBinaryDataMessage ==
    \A message \in CheckedBinaryDataMessage :
        LET read == DecodeBinaryDataMessage(EncodeBinaryDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpPacket ==
    \A message \in CheckedTcpPacket :
        LET read == DecodeTcpPacket(EncodeTcpPacket(message))
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

(* A Packet Payload is selected by the Packet Type it is written under *)
SelectsPacketPayload ==
    \A message \in CheckedPacketPayload :
        LET read == DecodePacketPayload(message.tag, EncodePacketPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Length is written from the bytes it frames *)
FramesTcpPacket ==
    \A message \in CheckedTcpPacket :
        LET bytes == EncodeTcpPacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
