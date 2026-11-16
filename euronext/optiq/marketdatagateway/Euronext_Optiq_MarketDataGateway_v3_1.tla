--------------- MODULE Euronext_Optiq_MarketDataGateway_v3_1 ---------------
(***************************************************************************)
(* Euronext Market Data Gateway v3.1                                       *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: a Compression of any value but 1 says nothing transformed Optiq   *)
(* Message, which is then read as it stands.                               *)
(*                                                                         *)
(* Note: Compression is one bit of Packet Flags, which is read as the      *)
(* number it is: the bit says whether Optiq Message was transformed, so it *)
(* is the choice's own, and the record keeps the rest of the bits. The     *)
(* byte is written from the two together, so every bit of it is stated     *)
(* once.                                                                   *)
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
(* Optiq Message                                                           *)
(***************************************************************************)

OptiqMessageLz4 ==
    [ transformed : SampleBytes ]

EncodeOptiqMessageLz4(message) ==
    message.transformed

DecodeOptiqMessageLz4(bytes) ==
    LET transformed == Ok(bytes, << >>) IN IF ~transformed.ok THEN Fail ELSE
    Ok([ transformed |-> transformed.value ], transformed.rest)

ZeroOptiqMessageLz4 ==
    [ transformed |-> << >> ]

(* Optiq Message at zero, then each field in turn at the values it is checked at *)
CheckedOptiqMessageLz4 ==
    { ZeroOptiqMessageLz4 }
        \cup { [ZeroOptiqMessageLz4 EXCEPT !.transformed = one] : one \in SampleBytes }

(***************************************************************************)
(* Start Of Day Message: 10 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ mdSeqNum          : Sample(8),
      sessionTradingDay : Sample(2) ]

EncodeStartOfDayMessage(message) ==
    message.mdSeqNum
        \o message.sessionTradingDay

DecodeStartOfDayMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET sessionTradingDay == ReadBytes(mdSeqNum.rest, 2) IN IF ~sessionTradingDay.ok THEN Fail ELSE
    Ok([ mdSeqNum          |-> mdSeqNum.value,
         sessionTradingDay |-> sessionTradingDay.value ], sessionTradingDay.rest)

ZeroStartOfDayMessage ==
    [ mdSeqNum          |-> [i \in 1 .. 8 |-> 0],
      sessionTradingDay |-> [i \in 1 .. 2 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.sessionTradingDay = one] : one \in Sample(2) }

(***************************************************************************)
(* End Of Day Message: 10 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ mdSeqNum          : Sample(8),
      sessionTradingDay : Sample(2) ]

EncodeEndOfDayMessage(message) ==
    message.mdSeqNum
        \o message.sessionTradingDay

DecodeEndOfDayMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET sessionTradingDay == ReadBytes(mdSeqNum.rest, 2) IN IF ~sessionTradingDay.ok THEN Fail ELSE
    Ok([ mdSeqNum          |-> mdSeqNum.value,
         sessionTradingDay |-> sessionTradingDay.value ], sessionTradingDay.rest)

ZeroEndOfDayMessage ==
    [ mdSeqNum          |-> [i \in 1 .. 8 |-> 0],
      sessionTradingDay |-> [i \in 1 .. 2 |-> 0] ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.sessionTradingDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Health Status Message: 16 bytes                                         *)
(***************************************************************************)

HealthStatusMessage ==
    [ mdSeqNum  : Sample(8),
      eventTime : Sample(8) ]

EncodeHealthStatusMessage(message) ==
    message.mdSeqNum
        \o message.eventTime

DecodeHealthStatusMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET eventTime == ReadBytes(mdSeqNum.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    Ok([ mdSeqNum  |-> mdSeqNum.value,
         eventTime |-> eventTime.value ], eventTime.rest)

ZeroHealthStatusMessage ==
    [ mdSeqNum  |-> [i \in 1 .. 8 |-> 0],
      eventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Health Status Message at zero, then each field in turn at the values it is checked at *)
CheckedHealthStatusMessage ==
    { ZeroHealthStatusMessage }
        \cup { [ZeroHealthStatusMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroHealthStatusMessage EXCEPT !.eventTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Technical Notification Message: 30 bytes                                *)
(***************************************************************************)

TechnicalNotificationMessage ==
    [ mdSeqNumOptional          : Sample(8),
      technicalNotificationType : Sample(1),
      rebroadcastIndicator      : Sample(1),
      retransmissionStartTime   : Sample(8),
      retransmissionEndTime     : Sample(8),
      symbolIndexOptional       : Sample(4) ]

EncodeTechnicalNotificationMessage(message) ==
    message.mdSeqNumOptional
        \o message.technicalNotificationType
        \o message.rebroadcastIndicator
        \o message.retransmissionStartTime
        \o message.retransmissionEndTime
        \o message.symbolIndexOptional

DecodeTechnicalNotificationMessage(bytes) ==
    LET mdSeqNumOptional == ReadBytes(bytes, 8) IN IF ~mdSeqNumOptional.ok THEN Fail ELSE
    LET technicalNotificationType == ReadBytes(mdSeqNumOptional.rest, 1) IN IF ~technicalNotificationType.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(technicalNotificationType.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET retransmissionStartTime == ReadBytes(rebroadcastIndicator.rest, 8) IN IF ~retransmissionStartTime.ok THEN Fail ELSE
    LET retransmissionEndTime == ReadBytes(retransmissionStartTime.rest, 8) IN IF ~retransmissionEndTime.ok THEN Fail ELSE
    LET symbolIndexOptional == ReadBytes(retransmissionEndTime.rest, 4) IN IF ~symbolIndexOptional.ok THEN Fail ELSE
    Ok([ mdSeqNumOptional          |-> mdSeqNumOptional.value,
         technicalNotificationType |-> technicalNotificationType.value,
         rebroadcastIndicator      |-> rebroadcastIndicator.value,
         retransmissionStartTime   |-> retransmissionStartTime.value,
         retransmissionEndTime     |-> retransmissionEndTime.value,
         symbolIndexOptional       |-> symbolIndexOptional.value ], symbolIndexOptional.rest)

ZeroTechnicalNotificationMessage ==
    [ mdSeqNumOptional          |-> [i \in 1 .. 8 |-> 0],
      technicalNotificationType |-> [i \in 1 .. 1 |-> 0],
      rebroadcastIndicator      |-> [i \in 1 .. 1 |-> 0],
      retransmissionStartTime   |-> [i \in 1 .. 8 |-> 0],
      retransmissionEndTime     |-> [i \in 1 .. 8 |-> 0],
      symbolIndexOptional       |-> [i \in 1 .. 4 |-> 0] ]

(* Technical Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedTechnicalNotificationMessage ==
    { ZeroTechnicalNotificationMessage }
        \cup { [ZeroTechnicalNotificationMessage EXCEPT !.mdSeqNumOptional = one] : one \in Sample(8) }
        \cup { [ZeroTechnicalNotificationMessage EXCEPT !.technicalNotificationType = one] : one \in Sample(1) }
        \cup { [ZeroTechnicalNotificationMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTechnicalNotificationMessage EXCEPT !.retransmissionStartTime = one] : one \in Sample(8) }
        \cup { [ZeroTechnicalNotificationMessage EXCEPT !.retransmissionEndTime = one] : one \in Sample(8) }
        \cup { [ZeroTechnicalNotificationMessage EXCEPT !.symbolIndexOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Updates Group: 23 bytes                                          *)
(***************************************************************************)

MarketUpdatesGroup ==
    [ updateType     : Sample(1),
      symbolIndex    : Sample(4),
      numberOfOrders : Sample(2),
      price          : Sample(8),
      quantity       : Sample(8) ]

EncodeMarketUpdatesGroup(message) ==
    message.updateType
        \o message.symbolIndex
        \o message.numberOfOrders
        \o message.price
        \o message.quantity

DecodeMarketUpdatesGroup(bytes) ==
    LET updateType == ReadBytes(bytes, 1) IN IF ~updateType.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(updateType.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(symbolIndex.rest, 2) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET price == ReadBytes(numberOfOrders.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ updateType     |-> updateType.value,
         symbolIndex    |-> symbolIndex.value,
         numberOfOrders |-> numberOfOrders.value,
         price          |-> price.value,
         quantity       |-> quantity.value ], quantity.rest)

ZeroMarketUpdatesGroup ==
    [ updateType     |-> [i \in 1 .. 1 |-> 0],
      symbolIndex    |-> [i \in 1 .. 4 |-> 0],
      numberOfOrders |-> [i \in 1 .. 2 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      quantity       |-> [i \in 1 .. 8 |-> 0] ]

(* Market Updates Group at zero, then each field in turn at the values it is checked at *)
CheckedMarketUpdatesGroup ==
    { ZeroMarketUpdatesGroup }
        \cup { [ZeroMarketUpdatesGroup EXCEPT !.updateType = one] : one \in Sample(1) }
        \cup { [ZeroMarketUpdatesGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroMarketUpdatesGroup EXCEPT !.numberOfOrders = one] : one \in Sample(2) }
        \cup { [ZeroMarketUpdatesGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMarketUpdatesGroup EXCEPT !.quantity = one] : one \in Sample(8) }

(* A run of Market Updates Group, written one after another *)
RECURSIVE EncodeMarketUpdatesGroupList(_)
EncodeMarketUpdatesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketUpdatesGroup(Head(messages)) \o EncodeMarketUpdatesGroupList(Tail(messages))

(* As many Market Updates Group as the field that counts them says *)
RECURSIVE ReadMarketUpdatesGroupList(_, _)
ReadMarketUpdatesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketUpdatesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketUpdatesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Updates Group of each kind, for the lists that carry them *)
OneMarketUpdatesGroup == { ZeroMarketUpdatesGroup }

(***************************************************************************)
(* Market Updates Groups                                                   *)
(***************************************************************************)

MarketUpdatesGroups ==
    [ blockLengthShort   : Sample(1),
      marketUpdatesGroup : SampleLists(OneMarketUpdatesGroup) ]

EncodeMarketUpdatesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.marketUpdatesGroup), 1)
        \o EncodeMarketUpdatesGroupList(message.marketUpdatesGroup)

DecodeMarketUpdatesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET marketUpdatesGroup == ReadMarketUpdatesGroupList(numInGroup.rest, numInGroup.value) IN IF ~marketUpdatesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort   |-> blockLengthShort.value,
         marketUpdatesGroup |-> marketUpdatesGroup.value ], marketUpdatesGroup.rest)

ZeroMarketUpdatesGroups ==
    [ blockLengthShort   |-> [i \in 1 .. 1 |-> 0],
      marketUpdatesGroup |-> << >> ]

(* Market Updates Groups at zero, then each field in turn at the values it is checked at *)
CheckedMarketUpdatesGroups ==
    { ZeroMarketUpdatesGroups }
        \cup { [ZeroMarketUpdatesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMarketUpdatesGroups EXCEPT !.marketUpdatesGroup = one] : one \in SampleLists(OneMarketUpdatesGroup) }

(***************************************************************************)
(* Market Update Message                                                   *)
(***************************************************************************)

MarketUpdateMessage ==
    [ mdSeqNum             : Sample(8),
      rebroadcastIndicator : Sample(1),
      emm                  : Sample(1),
      eventTime            : Sample(8),
      marketUpdatesGroups  : MarketUpdatesGroups ]

EncodeMarketUpdateMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.eventTime
        \o EncodeMarketUpdatesGroups(message.marketUpdatesGroups)

DecodeMarketUpdateMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventTime == ReadBytes(emm.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET marketUpdatesGroups == DecodeMarketUpdatesGroups(eventTime.rest) IN IF ~marketUpdatesGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum             |-> mdSeqNum.value,
         rebroadcastIndicator |-> rebroadcastIndicator.value,
         emm                  |-> emm.value,
         eventTime            |-> eventTime.value,
         marketUpdatesGroups  |-> marketUpdatesGroups.value ], marketUpdatesGroups.rest)

ZeroMarketUpdateMessage ==
    [ mdSeqNum             |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator |-> [i \in 1 .. 1 |-> 0],
      emm                  |-> [i \in 1 .. 1 |-> 0],
      eventTime            |-> [i \in 1 .. 8 |-> 0],
      marketUpdatesGroups  |-> ZeroMarketUpdatesGroups ]

(* Market Update Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketUpdateMessage ==
    { ZeroMarketUpdateMessage }
        \cup { [ZeroMarketUpdateMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroMarketUpdateMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketUpdateMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroMarketUpdateMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketUpdateMessage EXCEPT !.marketUpdatesGroups = one] : one \in CheckedMarketUpdatesGroups }

(***************************************************************************)
(* Order Updates Group: 40 bytes                                           *)
(***************************************************************************)

OrderUpdatesGroup ==
    [ symbolIndex      : Sample(4),
      actionType       : Sample(1),
      orderPriority    : Sample(8),
      previousPriority : Sample(8),
      orderType        : Sample(1),
      orderPx          : Sample(8),
      orderSide        : Sample(1),
      orderQuantity    : Sample(8),
      pegOffset        : Sample(1) ]

EncodeOrderUpdatesGroup(message) ==
    message.symbolIndex
        \o message.actionType
        \o message.orderPriority
        \o message.previousPriority
        \o message.orderType
        \o message.orderPx
        \o message.orderSide
        \o message.orderQuantity
        \o message.pegOffset

DecodeOrderUpdatesGroup(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET actionType == ReadBytes(symbolIndex.rest, 1) IN IF ~actionType.ok THEN Fail ELSE
    LET orderPriority == ReadBytes(actionType.rest, 8) IN IF ~orderPriority.ok THEN Fail ELSE
    LET previousPriority == ReadBytes(orderPriority.rest, 8) IN IF ~previousPriority.ok THEN Fail ELSE
    LET orderType == ReadBytes(previousPriority.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderPx == ReadBytes(orderType.rest, 8) IN IF ~orderPx.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderPx.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(orderSide.rest, 8) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET pegOffset == ReadBytes(orderQuantity.rest, 1) IN IF ~pegOffset.ok THEN Fail ELSE
    Ok([ symbolIndex      |-> symbolIndex.value,
         actionType       |-> actionType.value,
         orderPriority    |-> orderPriority.value,
         previousPriority |-> previousPriority.value,
         orderType        |-> orderType.value,
         orderPx          |-> orderPx.value,
         orderSide        |-> orderSide.value,
         orderQuantity    |-> orderQuantity.value,
         pegOffset        |-> pegOffset.value ], pegOffset.rest)

ZeroOrderUpdatesGroup ==
    [ symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      actionType       |-> [i \in 1 .. 1 |-> 0],
      orderPriority    |-> [i \in 1 .. 8 |-> 0],
      previousPriority |-> [i \in 1 .. 8 |-> 0],
      orderType        |-> [i \in 1 .. 1 |-> 0],
      orderPx          |-> [i \in 1 .. 8 |-> 0],
      orderSide        |-> [i \in 1 .. 1 |-> 0],
      orderQuantity    |-> [i \in 1 .. 8 |-> 0],
      pegOffset        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Updates Group at zero, then each field in turn at the values it is checked at *)
CheckedOrderUpdatesGroup ==
    { ZeroOrderUpdatesGroup }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.actionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.orderPriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.previousPriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.orderPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.orderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdatesGroup EXCEPT !.pegOffset = one] : one \in Sample(1) }

(* A run of Order Updates Group, written one after another *)
RECURSIVE EncodeOrderUpdatesGroupList(_)
EncodeOrderUpdatesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderUpdatesGroup(Head(messages)) \o EncodeOrderUpdatesGroupList(Tail(messages))

(* As many Order Updates Group as the field that counts them says *)
RECURSIVE ReadOrderUpdatesGroupList(_, _)
ReadOrderUpdatesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderUpdatesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderUpdatesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Updates Group of each kind, for the lists that carry them *)
OneOrderUpdatesGroup == { ZeroOrderUpdatesGroup }

(***************************************************************************)
(* Order Updates Groups                                                    *)
(***************************************************************************)

OrderUpdatesGroups ==
    [ blockLengthShort  : Sample(1),
      orderUpdatesGroup : SampleLists(OneOrderUpdatesGroup) ]

EncodeOrderUpdatesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.orderUpdatesGroup), 1)
        \o EncodeOrderUpdatesGroupList(message.orderUpdatesGroup)

DecodeOrderUpdatesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET orderUpdatesGroup == ReadOrderUpdatesGroupList(numInGroup.rest, numInGroup.value) IN IF ~orderUpdatesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort  |-> blockLengthShort.value,
         orderUpdatesGroup |-> orderUpdatesGroup.value ], orderUpdatesGroup.rest)

ZeroOrderUpdatesGroups ==
    [ blockLengthShort  |-> [i \in 1 .. 1 |-> 0],
      orderUpdatesGroup |-> << >> ]

(* Order Updates Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrderUpdatesGroups ==
    { ZeroOrderUpdatesGroups }
        \cup { [ZeroOrderUpdatesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdatesGroups EXCEPT !.orderUpdatesGroup = one] : one \in SampleLists(OneOrderUpdatesGroup) }

(***************************************************************************)
(* Order Update Message                                                    *)
(***************************************************************************)

OrderUpdateMessage ==
    [ mdSeqNum             : Sample(8),
      rebroadcastIndicator : Sample(1),
      emm                  : Sample(1),
      eventTime            : Sample(8),
      orderUpdatesGroups   : OrderUpdatesGroups ]

EncodeOrderUpdateMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.eventTime
        \o EncodeOrderUpdatesGroups(message.orderUpdatesGroups)

DecodeOrderUpdateMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventTime == ReadBytes(emm.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET orderUpdatesGroups == DecodeOrderUpdatesGroups(eventTime.rest) IN IF ~orderUpdatesGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum             |-> mdSeqNum.value,
         rebroadcastIndicator |-> rebroadcastIndicator.value,
         emm                  |-> emm.value,
         eventTime            |-> eventTime.value,
         orderUpdatesGroups   |-> orderUpdatesGroups.value ], orderUpdatesGroups.rest)

ZeroOrderUpdateMessage ==
    [ mdSeqNum             |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator |-> [i \in 1 .. 1 |-> 0],
      emm                  |-> [i \in 1 .. 1 |-> 0],
      eventTime            |-> [i \in 1 .. 8 |-> 0],
      orderUpdatesGroups   |-> ZeroOrderUpdatesGroups ]

(* Order Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderUpdateMessage ==
    { ZeroOrderUpdateMessage }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.orderUpdatesGroups = one] : one \in CheckedOrderUpdatesGroups }

(***************************************************************************)
(* Price Updates Group: 30 bytes                                           *)
(***************************************************************************)

PriceUpdatesGroup ==
    [ priceType        : Sample(1),
      symbolIndex      : Sample(4),
      price            : Sample(8),
      quantity         : Sample(8),
      imbalanceQty     : Sample(8),
      imbalanceQtySide : Sample(1) ]

EncodePriceUpdatesGroup(message) ==
    message.priceType
        \o message.symbolIndex
        \o message.price
        \o message.quantity
        \o message.imbalanceQty
        \o message.imbalanceQtySide

DecodePriceUpdatesGroup(bytes) ==
    LET priceType == ReadBytes(bytes, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(priceType.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET price == ReadBytes(symbolIndex.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET imbalanceQty == ReadBytes(quantity.rest, 8) IN IF ~imbalanceQty.ok THEN Fail ELSE
    LET imbalanceQtySide == ReadBytes(imbalanceQty.rest, 1) IN IF ~imbalanceQtySide.ok THEN Fail ELSE
    Ok([ priceType        |-> priceType.value,
         symbolIndex      |-> symbolIndex.value,
         price            |-> price.value,
         quantity         |-> quantity.value,
         imbalanceQty     |-> imbalanceQty.value,
         imbalanceQtySide |-> imbalanceQtySide.value ], imbalanceQtySide.rest)

ZeroPriceUpdatesGroup ==
    [ priceType        |-> [i \in 1 .. 1 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      quantity         |-> [i \in 1 .. 8 |-> 0],
      imbalanceQty     |-> [i \in 1 .. 8 |-> 0],
      imbalanceQtySide |-> [i \in 1 .. 1 |-> 0] ]

(* Price Updates Group at zero, then each field in turn at the values it is checked at *)
CheckedPriceUpdatesGroup ==
    { ZeroPriceUpdatesGroup }
        \cup { [ZeroPriceUpdatesGroup EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroPriceUpdatesGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdatesGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroPriceUpdatesGroup EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroPriceUpdatesGroup EXCEPT !.imbalanceQty = one] : one \in Sample(8) }
        \cup { [ZeroPriceUpdatesGroup EXCEPT !.imbalanceQtySide = one] : one \in Sample(1) }

(* A run of Price Updates Group, written one after another *)
RECURSIVE EncodePriceUpdatesGroupList(_)
EncodePriceUpdatesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePriceUpdatesGroup(Head(messages)) \o EncodePriceUpdatesGroupList(Tail(messages))

(* As many Price Updates Group as the field that counts them says *)
RECURSIVE ReadPriceUpdatesGroupList(_, _)
ReadPriceUpdatesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePriceUpdatesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPriceUpdatesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Price Updates Group of each kind, for the lists that carry them *)
OnePriceUpdatesGroup == { ZeroPriceUpdatesGroup }

(***************************************************************************)
(* Price Updates Groups                                                    *)
(***************************************************************************)

PriceUpdatesGroups ==
    [ blockLengthShort  : Sample(1),
      priceUpdatesGroup : SampleLists(OnePriceUpdatesGroup) ]

EncodePriceUpdatesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.priceUpdatesGroup), 1)
        \o EncodePriceUpdatesGroupList(message.priceUpdatesGroup)

DecodePriceUpdatesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET priceUpdatesGroup == ReadPriceUpdatesGroupList(numInGroup.rest, numInGroup.value) IN IF ~priceUpdatesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort  |-> blockLengthShort.value,
         priceUpdatesGroup |-> priceUpdatesGroup.value ], priceUpdatesGroup.rest)

ZeroPriceUpdatesGroups ==
    [ blockLengthShort  |-> [i \in 1 .. 1 |-> 0],
      priceUpdatesGroup |-> << >> ]

(* Price Updates Groups at zero, then each field in turn at the values it is checked at *)
CheckedPriceUpdatesGroups ==
    { ZeroPriceUpdatesGroups }
        \cup { [ZeroPriceUpdatesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPriceUpdatesGroups EXCEPT !.priceUpdatesGroup = one] : one \in SampleLists(OnePriceUpdatesGroup) }

(***************************************************************************)
(* Price Update Message                                                    *)
(***************************************************************************)

PriceUpdateMessage ==
    [ mdSeqNum             : Sample(8),
      rebroadcastIndicator : Sample(1),
      emm                  : Sample(1),
      eventTime            : Sample(8),
      priceUpdatesGroups   : PriceUpdatesGroups ]

EncodePriceUpdateMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.eventTime
        \o EncodePriceUpdatesGroups(message.priceUpdatesGroups)

DecodePriceUpdateMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventTime == ReadBytes(emm.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET priceUpdatesGroups == DecodePriceUpdatesGroups(eventTime.rest) IN IF ~priceUpdatesGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum             |-> mdSeqNum.value,
         rebroadcastIndicator |-> rebroadcastIndicator.value,
         emm                  |-> emm.value,
         eventTime            |-> eventTime.value,
         priceUpdatesGroups   |-> priceUpdatesGroups.value ], priceUpdatesGroups.rest)

ZeroPriceUpdateMessage ==
    [ mdSeqNum             |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator |-> [i \in 1 .. 1 |-> 0],
      emm                  |-> [i \in 1 .. 1 |-> 0],
      eventTime            |-> [i \in 1 .. 8 |-> 0],
      priceUpdatesGroups   |-> ZeroPriceUpdatesGroups ]

(* Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceUpdateMessage ==
    { ZeroPriceUpdateMessage }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.priceUpdatesGroups = one] : one \in CheckedPriceUpdatesGroups }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups ==
    { ZeroNotUsedGroups }
        \cup { [ZeroNotUsedGroups EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Full Trade Information Message: 402 bytes                               *)
(***************************************************************************)

FullTradeInformationMessage ==
    [ mdSeqNum                      : Sample(8),
      rebroadcastIndicator          : Sample(1),
      emm                           : Sample(1),
      eventTime                     : Sample(8),
      symbolIndexOptional           : Sample(4),
      tradingDateTime               : Sample(27),
      publicationDateTime           : Sample(27),
      tradeType                     : Sample(1),
      mifidInstrumentIdTypeOptional : Sample(4),
      mifidInstrumentIdOptional     : Sample(12),
      mifidExecutionId              : Sample(52),
      mifidPriceOptional            : Sample(20),
      mifidQuantity                 : Sample(20),
      mifidPriceNotation            : Sample(4),
      mifidCurrency                 : Sample(3),
      mifidQtyInMsrmtUnitNotation   : Sample(25),
      mifidQuantityMeasurementUnit  : Sample(20),
      mifidNotionalAmount           : Sample(20),
      notionalCurrency              : Sample(3),
      mifidClearingFlag             : Sample(5),
      mmtMarketMechanism            : Sample(1),
      mmtTradingMode                : Sample(1),
      mmtTransactionCategory        : Sample(4),
      mmtNegotiationIndicator       : Sample(4),
      mmtAgencyCrossTradeIndicator  : Sample(4),
      mmtModificationIndicator      : Sample(4),
      mmtBenchmarkIndicator         : Sample(4),
      mmtSpecialDividendIndicator   : Sample(4),
      mmtOffBookAutomatedIndicator  : Sample(1),
      mmtContributiontoPrice        : Sample(4),
      mmtAlgorithmicIndicator       : Sample(4),
      mmtPublicationMode            : Sample(4),
      mmtPostTradeDeferral          : Sample(4),
      mmtDuplicativeIndicator       : Sample(4),
      tradeQualifier                : Sample(1),
      transactionType               : Sample(1),
      effectiveDateIndicator        : Sample(1),
      blockTradeCode                : Sample(1),
      tradeReference                : Sample(30),
      originalReportTimestamp       : Sample(8),
      transparencyIndicator         : Sample(1),
      currencyCoefficient           : Sample(4),
      priceMultiplier               : Sample(4),
      priceMultiplierDecimals       : Sample(1),
      venue                         : Sample(11),
      startTimeVwap                 : Sample(4),
      endTimeVwap                   : Sample(4),
      mifidEmissionAllowanceType    : Sample(4),
      marketOfReferenceMic          : Sample(4),
      evaluatedPrice                : Sample(8),
      messagePriceNotation          : Sample(1),
      notUsedGroups                 : NotUsedGroups ]

EncodeFullTradeInformationMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.eventTime
        \o message.symbolIndexOptional
        \o message.tradingDateTime
        \o message.publicationDateTime
        \o message.tradeType
        \o message.mifidInstrumentIdTypeOptional
        \o message.mifidInstrumentIdOptional
        \o message.mifidExecutionId
        \o message.mifidPriceOptional
        \o message.mifidQuantity
        \o message.mifidPriceNotation
        \o message.mifidCurrency
        \o message.mifidQtyInMsrmtUnitNotation
        \o message.mifidQuantityMeasurementUnit
        \o message.mifidNotionalAmount
        \o message.notionalCurrency
        \o message.mifidClearingFlag
        \o message.mmtMarketMechanism
        \o message.mmtTradingMode
        \o message.mmtTransactionCategory
        \o message.mmtNegotiationIndicator
        \o message.mmtAgencyCrossTradeIndicator
        \o message.mmtModificationIndicator
        \o message.mmtBenchmarkIndicator
        \o message.mmtSpecialDividendIndicator
        \o message.mmtOffBookAutomatedIndicator
        \o message.mmtContributiontoPrice
        \o message.mmtAlgorithmicIndicator
        \o message.mmtPublicationMode
        \o message.mmtPostTradeDeferral
        \o message.mmtDuplicativeIndicator
        \o message.tradeQualifier
        \o message.transactionType
        \o message.effectiveDateIndicator
        \o message.blockTradeCode
        \o message.tradeReference
        \o message.originalReportTimestamp
        \o message.transparencyIndicator
        \o message.currencyCoefficient
        \o message.priceMultiplier
        \o message.priceMultiplierDecimals
        \o message.venue
        \o message.startTimeVwap
        \o message.endTimeVwap
        \o message.mifidEmissionAllowanceType
        \o message.marketOfReferenceMic
        \o message.evaluatedPrice
        \o message.messagePriceNotation
        \o EncodeNotUsedGroups(message.notUsedGroups)

DecodeFullTradeInformationMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventTime == ReadBytes(emm.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET symbolIndexOptional == ReadBytes(eventTime.rest, 4) IN IF ~symbolIndexOptional.ok THEN Fail ELSE
    LET tradingDateTime == ReadBytes(symbolIndexOptional.rest, 27) IN IF ~tradingDateTime.ok THEN Fail ELSE
    LET publicationDateTime == ReadBytes(tradingDateTime.rest, 27) IN IF ~publicationDateTime.ok THEN Fail ELSE
    LET tradeType == ReadBytes(publicationDateTime.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET mifidInstrumentIdTypeOptional == ReadBytes(tradeType.rest, 4) IN IF ~mifidInstrumentIdTypeOptional.ok THEN Fail ELSE
    LET mifidInstrumentIdOptional == ReadBytes(mifidInstrumentIdTypeOptional.rest, 12) IN IF ~mifidInstrumentIdOptional.ok THEN Fail ELSE
    LET mifidExecutionId == ReadBytes(mifidInstrumentIdOptional.rest, 52) IN IF ~mifidExecutionId.ok THEN Fail ELSE
    LET mifidPriceOptional == ReadBytes(mifidExecutionId.rest, 20) IN IF ~mifidPriceOptional.ok THEN Fail ELSE
    LET mifidQuantity == ReadBytes(mifidPriceOptional.rest, 20) IN IF ~mifidQuantity.ok THEN Fail ELSE
    LET mifidPriceNotation == ReadBytes(mifidQuantity.rest, 4) IN IF ~mifidPriceNotation.ok THEN Fail ELSE
    LET mifidCurrency == ReadBytes(mifidPriceNotation.rest, 3) IN IF ~mifidCurrency.ok THEN Fail ELSE
    LET mifidQtyInMsrmtUnitNotation == ReadBytes(mifidCurrency.rest, 25) IN IF ~mifidQtyInMsrmtUnitNotation.ok THEN Fail ELSE
    LET mifidQuantityMeasurementUnit == ReadBytes(mifidQtyInMsrmtUnitNotation.rest, 20) IN IF ~mifidQuantityMeasurementUnit.ok THEN Fail ELSE
    LET mifidNotionalAmount == ReadBytes(mifidQuantityMeasurementUnit.rest, 20) IN IF ~mifidNotionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(mifidNotionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET mifidClearingFlag == ReadBytes(notionalCurrency.rest, 5) IN IF ~mifidClearingFlag.ok THEN Fail ELSE
    LET mmtMarketMechanism == ReadBytes(mifidClearingFlag.rest, 1) IN IF ~mmtMarketMechanism.ok THEN Fail ELSE
    LET mmtTradingMode == ReadBytes(mmtMarketMechanism.rest, 1) IN IF ~mmtTradingMode.ok THEN Fail ELSE
    LET mmtTransactionCategory == ReadBytes(mmtTradingMode.rest, 4) IN IF ~mmtTransactionCategory.ok THEN Fail ELSE
    LET mmtNegotiationIndicator == ReadBytes(mmtTransactionCategory.rest, 4) IN IF ~mmtNegotiationIndicator.ok THEN Fail ELSE
    LET mmtAgencyCrossTradeIndicator == ReadBytes(mmtNegotiationIndicator.rest, 4) IN IF ~mmtAgencyCrossTradeIndicator.ok THEN Fail ELSE
    LET mmtModificationIndicator == ReadBytes(mmtAgencyCrossTradeIndicator.rest, 4) IN IF ~mmtModificationIndicator.ok THEN Fail ELSE
    LET mmtBenchmarkIndicator == ReadBytes(mmtModificationIndicator.rest, 4) IN IF ~mmtBenchmarkIndicator.ok THEN Fail ELSE
    LET mmtSpecialDividendIndicator == ReadBytes(mmtBenchmarkIndicator.rest, 4) IN IF ~mmtSpecialDividendIndicator.ok THEN Fail ELSE
    LET mmtOffBookAutomatedIndicator == ReadBytes(mmtSpecialDividendIndicator.rest, 1) IN IF ~mmtOffBookAutomatedIndicator.ok THEN Fail ELSE
    LET mmtContributiontoPrice == ReadBytes(mmtOffBookAutomatedIndicator.rest, 4) IN IF ~mmtContributiontoPrice.ok THEN Fail ELSE
    LET mmtAlgorithmicIndicator == ReadBytes(mmtContributiontoPrice.rest, 4) IN IF ~mmtAlgorithmicIndicator.ok THEN Fail ELSE
    LET mmtPublicationMode == ReadBytes(mmtAlgorithmicIndicator.rest, 4) IN IF ~mmtPublicationMode.ok THEN Fail ELSE
    LET mmtPostTradeDeferral == ReadBytes(mmtPublicationMode.rest, 4) IN IF ~mmtPostTradeDeferral.ok THEN Fail ELSE
    LET mmtDuplicativeIndicator == ReadBytes(mmtPostTradeDeferral.rest, 4) IN IF ~mmtDuplicativeIndicator.ok THEN Fail ELSE
    LET tradeQualifier == ReadBytes(mmtDuplicativeIndicator.rest, 1) IN IF ~tradeQualifier.ok THEN Fail ELSE
    LET transactionType == ReadBytes(tradeQualifier.rest, 1) IN IF ~transactionType.ok THEN Fail ELSE
    LET effectiveDateIndicator == ReadBytes(transactionType.rest, 1) IN IF ~effectiveDateIndicator.ok THEN Fail ELSE
    LET blockTradeCode == ReadBytes(effectiveDateIndicator.rest, 1) IN IF ~blockTradeCode.ok THEN Fail ELSE
    LET tradeReference == ReadBytes(blockTradeCode.rest, 30) IN IF ~tradeReference.ok THEN Fail ELSE
    LET originalReportTimestamp == ReadBytes(tradeReference.rest, 8) IN IF ~originalReportTimestamp.ok THEN Fail ELSE
    LET transparencyIndicator == ReadBytes(originalReportTimestamp.rest, 1) IN IF ~transparencyIndicator.ok THEN Fail ELSE
    LET currencyCoefficient == ReadBytes(transparencyIndicator.rest, 4) IN IF ~currencyCoefficient.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(currencyCoefficient.rest, 4) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET priceMultiplierDecimals == ReadBytes(priceMultiplier.rest, 1) IN IF ~priceMultiplierDecimals.ok THEN Fail ELSE
    LET venue == ReadBytes(priceMultiplierDecimals.rest, 11) IN IF ~venue.ok THEN Fail ELSE
    LET startTimeVwap == ReadBytes(venue.rest, 4) IN IF ~startTimeVwap.ok THEN Fail ELSE
    LET endTimeVwap == ReadBytes(startTimeVwap.rest, 4) IN IF ~endTimeVwap.ok THEN Fail ELSE
    LET mifidEmissionAllowanceType == ReadBytes(endTimeVwap.rest, 4) IN IF ~mifidEmissionAllowanceType.ok THEN Fail ELSE
    LET marketOfReferenceMic == ReadBytes(mifidEmissionAllowanceType.rest, 4) IN IF ~marketOfReferenceMic.ok THEN Fail ELSE
    LET evaluatedPrice == ReadBytes(marketOfReferenceMic.rest, 8) IN IF ~evaluatedPrice.ok THEN Fail ELSE
    LET messagePriceNotation == ReadBytes(evaluatedPrice.rest, 1) IN IF ~messagePriceNotation.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups(messagePriceNotation.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum                      |-> mdSeqNum.value,
         rebroadcastIndicator          |-> rebroadcastIndicator.value,
         emm                           |-> emm.value,
         eventTime                     |-> eventTime.value,
         symbolIndexOptional           |-> symbolIndexOptional.value,
         tradingDateTime               |-> tradingDateTime.value,
         publicationDateTime           |-> publicationDateTime.value,
         tradeType                     |-> tradeType.value,
         mifidInstrumentIdTypeOptional |-> mifidInstrumentIdTypeOptional.value,
         mifidInstrumentIdOptional     |-> mifidInstrumentIdOptional.value,
         mifidExecutionId              |-> mifidExecutionId.value,
         mifidPriceOptional            |-> mifidPriceOptional.value,
         mifidQuantity                 |-> mifidQuantity.value,
         mifidPriceNotation            |-> mifidPriceNotation.value,
         mifidCurrency                 |-> mifidCurrency.value,
         mifidQtyInMsrmtUnitNotation   |-> mifidQtyInMsrmtUnitNotation.value,
         mifidQuantityMeasurementUnit  |-> mifidQuantityMeasurementUnit.value,
         mifidNotionalAmount           |-> mifidNotionalAmount.value,
         notionalCurrency              |-> notionalCurrency.value,
         mifidClearingFlag             |-> mifidClearingFlag.value,
         mmtMarketMechanism            |-> mmtMarketMechanism.value,
         mmtTradingMode                |-> mmtTradingMode.value,
         mmtTransactionCategory        |-> mmtTransactionCategory.value,
         mmtNegotiationIndicator       |-> mmtNegotiationIndicator.value,
         mmtAgencyCrossTradeIndicator  |-> mmtAgencyCrossTradeIndicator.value,
         mmtModificationIndicator      |-> mmtModificationIndicator.value,
         mmtBenchmarkIndicator         |-> mmtBenchmarkIndicator.value,
         mmtSpecialDividendIndicator   |-> mmtSpecialDividendIndicator.value,
         mmtOffBookAutomatedIndicator  |-> mmtOffBookAutomatedIndicator.value,
         mmtContributiontoPrice        |-> mmtContributiontoPrice.value,
         mmtAlgorithmicIndicator       |-> mmtAlgorithmicIndicator.value,
         mmtPublicationMode            |-> mmtPublicationMode.value,
         mmtPostTradeDeferral          |-> mmtPostTradeDeferral.value,
         mmtDuplicativeIndicator       |-> mmtDuplicativeIndicator.value,
         tradeQualifier                |-> tradeQualifier.value,
         transactionType               |-> transactionType.value,
         effectiveDateIndicator        |-> effectiveDateIndicator.value,
         blockTradeCode                |-> blockTradeCode.value,
         tradeReference                |-> tradeReference.value,
         originalReportTimestamp       |-> originalReportTimestamp.value,
         transparencyIndicator         |-> transparencyIndicator.value,
         currencyCoefficient           |-> currencyCoefficient.value,
         priceMultiplier               |-> priceMultiplier.value,
         priceMultiplierDecimals       |-> priceMultiplierDecimals.value,
         venue                         |-> venue.value,
         startTimeVwap                 |-> startTimeVwap.value,
         endTimeVwap                   |-> endTimeVwap.value,
         mifidEmissionAllowanceType    |-> mifidEmissionAllowanceType.value,
         marketOfReferenceMic          |-> marketOfReferenceMic.value,
         evaluatedPrice                |-> evaluatedPrice.value,
         messagePriceNotation          |-> messagePriceNotation.value,
         notUsedGroups                 |-> notUsedGroups.value ], notUsedGroups.rest)

ZeroFullTradeInformationMessage ==
    [ mdSeqNum                      |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator          |-> [i \in 1 .. 1 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      eventTime                     |-> [i \in 1 .. 8 |-> 0],
      symbolIndexOptional           |-> [i \in 1 .. 4 |-> 0],
      tradingDateTime               |-> [i \in 1 .. 27 |-> 0],
      publicationDateTime           |-> [i \in 1 .. 27 |-> 0],
      tradeType                     |-> [i \in 1 .. 1 |-> 0],
      mifidInstrumentIdTypeOptional |-> [i \in 1 .. 4 |-> 0],
      mifidInstrumentIdOptional     |-> [i \in 1 .. 12 |-> 0],
      mifidExecutionId              |-> [i \in 1 .. 52 |-> 0],
      mifidPriceOptional            |-> [i \in 1 .. 20 |-> 0],
      mifidQuantity                 |-> [i \in 1 .. 20 |-> 0],
      mifidPriceNotation            |-> [i \in 1 .. 4 |-> 0],
      mifidCurrency                 |-> [i \in 1 .. 3 |-> 0],
      mifidQtyInMsrmtUnitNotation   |-> [i \in 1 .. 25 |-> 0],
      mifidQuantityMeasurementUnit  |-> [i \in 1 .. 20 |-> 0],
      mifidNotionalAmount           |-> [i \in 1 .. 20 |-> 0],
      notionalCurrency              |-> [i \in 1 .. 3 |-> 0],
      mifidClearingFlag             |-> [i \in 1 .. 5 |-> 0],
      mmtMarketMechanism            |-> [i \in 1 .. 1 |-> 0],
      mmtTradingMode                |-> [i \in 1 .. 1 |-> 0],
      mmtTransactionCategory        |-> [i \in 1 .. 4 |-> 0],
      mmtNegotiationIndicator       |-> [i \in 1 .. 4 |-> 0],
      mmtAgencyCrossTradeIndicator  |-> [i \in 1 .. 4 |-> 0],
      mmtModificationIndicator      |-> [i \in 1 .. 4 |-> 0],
      mmtBenchmarkIndicator         |-> [i \in 1 .. 4 |-> 0],
      mmtSpecialDividendIndicator   |-> [i \in 1 .. 4 |-> 0],
      mmtOffBookAutomatedIndicator  |-> [i \in 1 .. 1 |-> 0],
      mmtContributiontoPrice        |-> [i \in 1 .. 4 |-> 0],
      mmtAlgorithmicIndicator       |-> [i \in 1 .. 4 |-> 0],
      mmtPublicationMode            |-> [i \in 1 .. 4 |-> 0],
      mmtPostTradeDeferral          |-> [i \in 1 .. 4 |-> 0],
      mmtDuplicativeIndicator       |-> [i \in 1 .. 4 |-> 0],
      tradeQualifier                |-> [i \in 1 .. 1 |-> 0],
      transactionType               |-> [i \in 1 .. 1 |-> 0],
      effectiveDateIndicator        |-> [i \in 1 .. 1 |-> 0],
      blockTradeCode                |-> [i \in 1 .. 1 |-> 0],
      tradeReference                |-> [i \in 1 .. 30 |-> 0],
      originalReportTimestamp       |-> [i \in 1 .. 8 |-> 0],
      transparencyIndicator         |-> [i \in 1 .. 1 |-> 0],
      currencyCoefficient           |-> [i \in 1 .. 4 |-> 0],
      priceMultiplier               |-> [i \in 1 .. 4 |-> 0],
      priceMultiplierDecimals       |-> [i \in 1 .. 1 |-> 0],
      venue                         |-> [i \in 1 .. 11 |-> 0],
      startTimeVwap                 |-> [i \in 1 .. 4 |-> 0],
      endTimeVwap                   |-> [i \in 1 .. 4 |-> 0],
      mifidEmissionAllowanceType    |-> [i \in 1 .. 4 |-> 0],
      marketOfReferenceMic          |-> [i \in 1 .. 4 |-> 0],
      evaluatedPrice                |-> [i \in 1 .. 8 |-> 0],
      messagePriceNotation          |-> [i \in 1 .. 1 |-> 0],
      notUsedGroups                 |-> ZeroNotUsedGroups ]

(* Full Trade Information Message at zero, then each field in turn at the values it is checked at *)
CheckedFullTradeInformationMessage ==
    { ZeroFullTradeInformationMessage }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.symbolIndexOptional = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.tradingDateTime = one] : one \in Sample(27) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.publicationDateTime = one] : one \in Sample(27) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidInstrumentIdTypeOptional = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidInstrumentIdOptional = one] : one \in Sample(12) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidExecutionId = one] : one \in Sample(52) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidPriceOptional = one] : one \in Sample(20) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidQuantity = one] : one \in Sample(20) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidPriceNotation = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidCurrency = one] : one \in Sample(3) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidQtyInMsrmtUnitNotation = one] : one \in Sample(25) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidQuantityMeasurementUnit = one] : one \in Sample(20) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidNotionalAmount = one] : one \in Sample(20) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidClearingFlag = one] : one \in Sample(5) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtMarketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtTradingMode = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtTransactionCategory = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtNegotiationIndicator = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtAgencyCrossTradeIndicator = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtModificationIndicator = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtBenchmarkIndicator = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtSpecialDividendIndicator = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtOffBookAutomatedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtContributiontoPrice = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtAlgorithmicIndicator = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtPublicationMode = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtPostTradeDeferral = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mmtDuplicativeIndicator = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.tradeQualifier = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.transactionType = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.effectiveDateIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.blockTradeCode = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.tradeReference = one] : one \in Sample(30) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.originalReportTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.transparencyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.currencyCoefficient = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.priceMultiplier = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.priceMultiplierDecimals = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.venue = one] : one \in Sample(11) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.startTimeVwap = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.endTimeVwap = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.mifidEmissionAllowanceType = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.marketOfReferenceMic = one] : one \in Sample(4) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.evaluatedPrice = one] : one \in Sample(8) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.messagePriceNotation = one] : one \in Sample(1) }
        \cup { [ZeroFullTradeInformationMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups }

(***************************************************************************)
(* Market States Group: 33 bytes                                           *)
(***************************************************************************)

MarketStatesGroup ==
    [ changeType            : Sample(1),
      symbolIndex           : Sample(4),
      eventTime             : Sample(8),
      bookState             : Sample(1),
      statusReason          : Sample(1),
      phaseQualifier        : Sample(2),
      tradingPeriodOptional : Sample(1),
      tradingSide           : Sample(1),
      priceLimits           : Sample(1),
      quoteSpreadMultiplier : Sample(1),
      orderEntryQualifier   : Sample(1),
      session               : Sample(1),
      scheduledEvent        : Sample(1),
      scheduledEventTime    : Sample(8),
      instrumentState       : Sample(1) ]

EncodeMarketStatesGroup(message) ==
    message.changeType
        \o message.symbolIndex
        \o message.eventTime
        \o message.bookState
        \o message.statusReason
        \o message.phaseQualifier
        \o message.tradingPeriodOptional
        \o message.tradingSide
        \o message.priceLimits
        \o message.quoteSpreadMultiplier
        \o message.orderEntryQualifier
        \o message.session
        \o message.scheduledEvent
        \o message.scheduledEventTime
        \o message.instrumentState

DecodeMarketStatesGroup(bytes) ==
    LET changeType == ReadBytes(bytes, 1) IN IF ~changeType.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(changeType.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET eventTime == ReadBytes(symbolIndex.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET bookState == ReadBytes(eventTime.rest, 1) IN IF ~bookState.ok THEN Fail ELSE
    LET statusReason == ReadBytes(bookState.rest, 1) IN IF ~statusReason.ok THEN Fail ELSE
    LET phaseQualifier == ReadBytes(statusReason.rest, 2) IN IF ~phaseQualifier.ok THEN Fail ELSE
    LET tradingPeriodOptional == ReadBytes(phaseQualifier.rest, 1) IN IF ~tradingPeriodOptional.ok THEN Fail ELSE
    LET tradingSide == ReadBytes(tradingPeriodOptional.rest, 1) IN IF ~tradingSide.ok THEN Fail ELSE
    LET priceLimits == ReadBytes(tradingSide.rest, 1) IN IF ~priceLimits.ok THEN Fail ELSE
    LET quoteSpreadMultiplier == ReadBytes(priceLimits.rest, 1) IN IF ~quoteSpreadMultiplier.ok THEN Fail ELSE
    LET orderEntryQualifier == ReadBytes(quoteSpreadMultiplier.rest, 1) IN IF ~orderEntryQualifier.ok THEN Fail ELSE
    LET session == ReadBytes(orderEntryQualifier.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET scheduledEvent == ReadBytes(session.rest, 1) IN IF ~scheduledEvent.ok THEN Fail ELSE
    LET scheduledEventTime == ReadBytes(scheduledEvent.rest, 8) IN IF ~scheduledEventTime.ok THEN Fail ELSE
    LET instrumentState == ReadBytes(scheduledEventTime.rest, 1) IN IF ~instrumentState.ok THEN Fail ELSE
    Ok([ changeType            |-> changeType.value,
         symbolIndex           |-> symbolIndex.value,
         eventTime             |-> eventTime.value,
         bookState             |-> bookState.value,
         statusReason          |-> statusReason.value,
         phaseQualifier        |-> phaseQualifier.value,
         tradingPeriodOptional |-> tradingPeriodOptional.value,
         tradingSide           |-> tradingSide.value,
         priceLimits           |-> priceLimits.value,
         quoteSpreadMultiplier |-> quoteSpreadMultiplier.value,
         orderEntryQualifier   |-> orderEntryQualifier.value,
         session               |-> session.value,
         scheduledEvent        |-> scheduledEvent.value,
         scheduledEventTime    |-> scheduledEventTime.value,
         instrumentState       |-> instrumentState.value ], instrumentState.rest)

ZeroMarketStatesGroup ==
    [ changeType            |-> [i \in 1 .. 1 |-> 0],
      symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      eventTime             |-> [i \in 1 .. 8 |-> 0],
      bookState             |-> [i \in 1 .. 1 |-> 0],
      statusReason          |-> [i \in 1 .. 1 |-> 0],
      phaseQualifier        |-> [i \in 1 .. 2 |-> 0],
      tradingPeriodOptional |-> [i \in 1 .. 1 |-> 0],
      tradingSide           |-> [i \in 1 .. 1 |-> 0],
      priceLimits           |-> [i \in 1 .. 1 |-> 0],
      quoteSpreadMultiplier |-> [i \in 1 .. 1 |-> 0],
      orderEntryQualifier   |-> [i \in 1 .. 1 |-> 0],
      session               |-> [i \in 1 .. 1 |-> 0],
      scheduledEvent        |-> [i \in 1 .. 1 |-> 0],
      scheduledEventTime    |-> [i \in 1 .. 8 |-> 0],
      instrumentState       |-> [i \in 1 .. 1 |-> 0] ]

(* Market States Group at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatesGroup ==
    { ZeroMarketStatesGroup }
        \cup { [ZeroMarketStatesGroup EXCEPT !.changeType = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.bookState = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.statusReason = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.phaseQualifier = one] : one \in Sample(2) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.tradingPeriodOptional = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.tradingSide = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.priceLimits = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.quoteSpreadMultiplier = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.orderEntryQualifier = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.scheduledEvent = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.scheduledEventTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatesGroup EXCEPT !.instrumentState = one] : one \in Sample(1) }

(* A run of Market States Group, written one after another *)
RECURSIVE EncodeMarketStatesGroupList(_)
EncodeMarketStatesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketStatesGroup(Head(messages)) \o EncodeMarketStatesGroupList(Tail(messages))

(* As many Market States Group as the field that counts them says *)
RECURSIVE ReadMarketStatesGroupList(_, _)
ReadMarketStatesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketStatesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketStatesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market States Group of each kind, for the lists that carry them *)
OneMarketStatesGroup == { ZeroMarketStatesGroup }

(***************************************************************************)
(* Market States Groups                                                    *)
(***************************************************************************)

MarketStatesGroups ==
    [ blockLengthShort  : Sample(1),
      marketStatesGroup : SampleLists(OneMarketStatesGroup) ]

EncodeMarketStatesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.marketStatesGroup), 1)
        \o EncodeMarketStatesGroupList(message.marketStatesGroup)

DecodeMarketStatesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET marketStatesGroup == ReadMarketStatesGroupList(numInGroup.rest, numInGroup.value) IN IF ~marketStatesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort  |-> blockLengthShort.value,
         marketStatesGroup |-> marketStatesGroup.value ], marketStatesGroup.rest)

ZeroMarketStatesGroups ==
    [ blockLengthShort  |-> [i \in 1 .. 1 |-> 0],
      marketStatesGroup |-> << >> ]

(* Market States Groups at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatesGroups ==
    { ZeroMarketStatesGroups }
        \cup { [ZeroMarketStatesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatesGroups EXCEPT !.marketStatesGroup = one] : one \in SampleLists(OneMarketStatesGroup) }

(***************************************************************************)
(* Market Status Change Message                                            *)
(***************************************************************************)

MarketStatusChangeMessage ==
    [ mdSeqNum             : Sample(8),
      rebroadcastIndicator : Sample(1),
      emm                  : Sample(1),
      marketStatesGroups   : MarketStatesGroups ]

EncodeMarketStatusChangeMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o EncodeMarketStatesGroups(message.marketStatesGroups)

DecodeMarketStatusChangeMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET marketStatesGroups == DecodeMarketStatesGroups(emm.rest) IN IF ~marketStatesGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum             |-> mdSeqNum.value,
         rebroadcastIndicator |-> rebroadcastIndicator.value,
         emm                  |-> emm.value,
         marketStatesGroups   |-> marketStatesGroups.value ], marketStatesGroups.rest)

ZeroMarketStatusChangeMessage ==
    [ mdSeqNum             |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator |-> [i \in 1 .. 1 |-> 0],
      emm                  |-> [i \in 1 .. 1 |-> 0],
      marketStatesGroups   |-> ZeroMarketStatesGroups ]

(* Market Status Change Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatusChangeMessage ==
    { ZeroMarketStatusChangeMessage }
        \cup { [ZeroMarketStatusChangeMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatusChangeMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatusChangeMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroMarketStatusChangeMessage EXCEPT !.marketStatesGroups = one] : one \in CheckedMarketStatesGroups }

(***************************************************************************)
(* Timetables Group: 15 bytes                                              *)
(***************************************************************************)

TimetablesGroup ==
    [ phaseTime           : Sample(8),
      phaseId             : Sample(1),
      phaseQualifier      : Sample(2),
      tradingPeriod       : Sample(1),
      orderEntryQualifier : Sample(1),
      session             : Sample(1),
      scheduledEvent      : Sample(1) ]

EncodeTimetablesGroup(message) ==
    message.phaseTime
        \o message.phaseId
        \o message.phaseQualifier
        \o message.tradingPeriod
        \o message.orderEntryQualifier
        \o message.session
        \o message.scheduledEvent

DecodeTimetablesGroup(bytes) ==
    LET phaseTime == ReadBytes(bytes, 8) IN IF ~phaseTime.ok THEN Fail ELSE
    LET phaseId == ReadBytes(phaseTime.rest, 1) IN IF ~phaseId.ok THEN Fail ELSE
    LET phaseQualifier == ReadBytes(phaseId.rest, 2) IN IF ~phaseQualifier.ok THEN Fail ELSE
    LET tradingPeriod == ReadBytes(phaseQualifier.rest, 1) IN IF ~tradingPeriod.ok THEN Fail ELSE
    LET orderEntryQualifier == ReadBytes(tradingPeriod.rest, 1) IN IF ~orderEntryQualifier.ok THEN Fail ELSE
    LET session == ReadBytes(orderEntryQualifier.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET scheduledEvent == ReadBytes(session.rest, 1) IN IF ~scheduledEvent.ok THEN Fail ELSE
    Ok([ phaseTime           |-> phaseTime.value,
         phaseId             |-> phaseId.value,
         phaseQualifier      |-> phaseQualifier.value,
         tradingPeriod       |-> tradingPeriod.value,
         orderEntryQualifier |-> orderEntryQualifier.value,
         session             |-> session.value,
         scheduledEvent      |-> scheduledEvent.value ], scheduledEvent.rest)

ZeroTimetablesGroup ==
    [ phaseTime           |-> [i \in 1 .. 8 |-> 0],
      phaseId             |-> [i \in 1 .. 1 |-> 0],
      phaseQualifier      |-> [i \in 1 .. 2 |-> 0],
      tradingPeriod       |-> [i \in 1 .. 1 |-> 0],
      orderEntryQualifier |-> [i \in 1 .. 1 |-> 0],
      session             |-> [i \in 1 .. 1 |-> 0],
      scheduledEvent      |-> [i \in 1 .. 1 |-> 0] ]

(* Timetables Group at zero, then each field in turn at the values it is checked at *)
CheckedTimetablesGroup ==
    { ZeroTimetablesGroup }
        \cup { [ZeroTimetablesGroup EXCEPT !.phaseTime = one] : one \in Sample(8) }
        \cup { [ZeroTimetablesGroup EXCEPT !.phaseId = one] : one \in Sample(1) }
        \cup { [ZeroTimetablesGroup EXCEPT !.phaseQualifier = one] : one \in Sample(2) }
        \cup { [ZeroTimetablesGroup EXCEPT !.tradingPeriod = one] : one \in Sample(1) }
        \cup { [ZeroTimetablesGroup EXCEPT !.orderEntryQualifier = one] : one \in Sample(1) }
        \cup { [ZeroTimetablesGroup EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroTimetablesGroup EXCEPT !.scheduledEvent = one] : one \in Sample(1) }

(* A run of Timetables Group, written one after another *)
RECURSIVE EncodeTimetablesGroupList(_)
EncodeTimetablesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTimetablesGroup(Head(messages)) \o EncodeTimetablesGroupList(Tail(messages))

(* As many Timetables Group as the field that counts them says *)
RECURSIVE ReadTimetablesGroupList(_, _)
ReadTimetablesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTimetablesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTimetablesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Timetables Group of each kind, for the lists that carry them *)
OneTimetablesGroup == { ZeroTimetablesGroup }

(***************************************************************************)
(* Timetables Groups                                                       *)
(***************************************************************************)

TimetablesGroups ==
    [ blockLengthShort : Sample(1),
      timetablesGroup  : SampleLists(OneTimetablesGroup) ]

EncodeTimetablesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.timetablesGroup), 1)
        \o EncodeTimetablesGroupList(message.timetablesGroup)

DecodeTimetablesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET timetablesGroup == ReadTimetablesGroupList(numInGroup.rest, numInGroup.value) IN IF ~timetablesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         timetablesGroup  |-> timetablesGroup.value ], timetablesGroup.rest)

ZeroTimetablesGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      timetablesGroup  |-> << >> ]

(* Timetables Groups at zero, then each field in turn at the values it is checked at *)
CheckedTimetablesGroups ==
    { ZeroTimetablesGroups }
        \cup { [ZeroTimetablesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroTimetablesGroups EXCEPT !.timetablesGroup = one] : one \in SampleLists(OneTimetablesGroup) }

(***************************************************************************)
(* Timetable Message                                                       *)
(***************************************************************************)

TimetableMessage ==
    [ mdSeqNum             : Sample(8),
      rebroadcastIndicator : Sample(1),
      emmOptional          : Sample(1),
      patternId            : Sample(2),
      symbolIndexOptional  : Sample(4),
      timetablesGroups     : TimetablesGroups ]

EncodeTimetableMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emmOptional
        \o message.patternId
        \o message.symbolIndexOptional
        \o EncodeTimetablesGroups(message.timetablesGroups)

DecodeTimetableMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emmOptional == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emmOptional.ok THEN Fail ELSE
    LET patternId == ReadBytes(emmOptional.rest, 2) IN IF ~patternId.ok THEN Fail ELSE
    LET symbolIndexOptional == ReadBytes(patternId.rest, 4) IN IF ~symbolIndexOptional.ok THEN Fail ELSE
    LET timetablesGroups == DecodeTimetablesGroups(symbolIndexOptional.rest) IN IF ~timetablesGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum             |-> mdSeqNum.value,
         rebroadcastIndicator |-> rebroadcastIndicator.value,
         emmOptional          |-> emmOptional.value,
         patternId            |-> patternId.value,
         symbolIndexOptional  |-> symbolIndexOptional.value,
         timetablesGroups     |-> timetablesGroups.value ], timetablesGroups.rest)

ZeroTimetableMessage ==
    [ mdSeqNum             |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator |-> [i \in 1 .. 1 |-> 0],
      emmOptional          |-> [i \in 1 .. 1 |-> 0],
      patternId            |-> [i \in 1 .. 2 |-> 0],
      symbolIndexOptional  |-> [i \in 1 .. 4 |-> 0],
      timetablesGroups     |-> ZeroTimetablesGroups ]

(* Timetable Message at zero, then each field in turn at the values it is checked at *)
CheckedTimetableMessage ==
    { ZeroTimetableMessage }
        \cup { [ZeroTimetableMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTimetableMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTimetableMessage EXCEPT !.emmOptional = one] : one \in Sample(1) }
        \cup { [ZeroTimetableMessage EXCEPT !.patternId = one] : one \in Sample(2) }
        \cup { [ZeroTimetableMessage EXCEPT !.symbolIndexOptional = one] : one \in Sample(4) }
        \cup { [ZeroTimetableMessage EXCEPT !.timetablesGroups = one] : one \in CheckedTimetablesGroups }

(***************************************************************************)
(* Emm Pattern Rep Group: 15 bytes                                         *)
(***************************************************************************)

EmmPatternRepGroup ==
    [ emm             : Sample(1),
      patternId       : Sample(2),
      tickSizeIndexId : Sample(2),
      marketModel     : Sample(1),
      lotSizeOptional : Sample(8),
      instUnitExp     : Sample(1) ]

EncodeEmmPatternRepGroup(message) ==
    message.emm
        \o message.patternId
        \o message.tickSizeIndexId
        \o message.marketModel
        \o message.lotSizeOptional
        \o message.instUnitExp

DecodeEmmPatternRepGroup(bytes) ==
    LET emm == ReadBytes(bytes, 1) IN IF ~emm.ok THEN Fail ELSE
    LET patternId == ReadBytes(emm.rest, 2) IN IF ~patternId.ok THEN Fail ELSE
    LET tickSizeIndexId == ReadBytes(patternId.rest, 2) IN IF ~tickSizeIndexId.ok THEN Fail ELSE
    LET marketModel == ReadBytes(tickSizeIndexId.rest, 1) IN IF ~marketModel.ok THEN Fail ELSE
    LET lotSizeOptional == ReadBytes(marketModel.rest, 8) IN IF ~lotSizeOptional.ok THEN Fail ELSE
    LET instUnitExp == ReadBytes(lotSizeOptional.rest, 1) IN IF ~instUnitExp.ok THEN Fail ELSE
    Ok([ emm             |-> emm.value,
         patternId       |-> patternId.value,
         tickSizeIndexId |-> tickSizeIndexId.value,
         marketModel     |-> marketModel.value,
         lotSizeOptional |-> lotSizeOptional.value,
         instUnitExp     |-> instUnitExp.value ], instUnitExp.rest)

ZeroEmmPatternRepGroup ==
    [ emm             |-> [i \in 1 .. 1 |-> 0],
      patternId       |-> [i \in 1 .. 2 |-> 0],
      tickSizeIndexId |-> [i \in 1 .. 2 |-> 0],
      marketModel     |-> [i \in 1 .. 1 |-> 0],
      lotSizeOptional |-> [i \in 1 .. 8 |-> 0],
      instUnitExp     |-> [i \in 1 .. 1 |-> 0] ]

(* Emm Pattern Rep Group at zero, then each field in turn at the values it is checked at *)
CheckedEmmPatternRepGroup ==
    { ZeroEmmPatternRepGroup }
        \cup { [ZeroEmmPatternRepGroup EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroEmmPatternRepGroup EXCEPT !.patternId = one] : one \in Sample(2) }
        \cup { [ZeroEmmPatternRepGroup EXCEPT !.tickSizeIndexId = one] : one \in Sample(2) }
        \cup { [ZeroEmmPatternRepGroup EXCEPT !.marketModel = one] : one \in Sample(1) }
        \cup { [ZeroEmmPatternRepGroup EXCEPT !.lotSizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroEmmPatternRepGroup EXCEPT !.instUnitExp = one] : one \in Sample(1) }

(* A run of Emm Pattern Rep Group, written one after another *)
RECURSIVE EncodeEmmPatternRepGroupList(_)
EncodeEmmPatternRepGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEmmPatternRepGroup(Head(messages)) \o EncodeEmmPatternRepGroupList(Tail(messages))

(* As many Emm Pattern Rep Group as the field that counts them says *)
RECURSIVE ReadEmmPatternRepGroupList(_, _)
ReadEmmPatternRepGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEmmPatternRepGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEmmPatternRepGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Emm Pattern Rep Group of each kind, for the lists that carry them *)
OneEmmPatternRepGroup == { ZeroEmmPatternRepGroup }

(***************************************************************************)
(* Emm Pattern Rep Groups                                                  *)
(***************************************************************************)

EmmPatternRepGroups ==
    [ blockLengthShort   : Sample(1),
      emmPatternRepGroup : SampleLists(OneEmmPatternRepGroup) ]

EncodeEmmPatternRepGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.emmPatternRepGroup), 1)
        \o EncodeEmmPatternRepGroupList(message.emmPatternRepGroup)

DecodeEmmPatternRepGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET emmPatternRepGroup == ReadEmmPatternRepGroupList(numInGroup.rest, numInGroup.value) IN IF ~emmPatternRepGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort   |-> blockLengthShort.value,
         emmPatternRepGroup |-> emmPatternRepGroup.value ], emmPatternRepGroup.rest)

ZeroEmmPatternRepGroups ==
    [ blockLengthShort   |-> [i \in 1 .. 1 |-> 0],
      emmPatternRepGroup |-> << >> ]

(* Emm Pattern Rep Groups at zero, then each field in turn at the values it is checked at *)
CheckedEmmPatternRepGroups ==
    { ZeroEmmPatternRepGroups }
        \cup { [ZeroEmmPatternRepGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroEmmPatternRepGroups EXCEPT !.emmPatternRepGroup = one] : one \in SampleLists(OneEmmPatternRepGroup) }

(***************************************************************************)
(* Standing Data Message                                                   *)
(***************************************************************************)

StandingDataMessage ==
    [ mdSeqNum                    : Sample(8),
      rebroadcastIndicator        : Sample(1),
      symbolIndex                 : Sample(4),
      optiqSegment                : Sample(1),
      partitionId                 : Sample(2),
      fullInstrumentName          : Sample(102),
      instrumentName              : Sample(18),
      instrumentTradingCode       : Sample(15),
      instrumentGroupCode         : Sample(2),
      isinCode                    : Sample(12),
      priceDecimals               : Sample(1),
      quantityDecimals            : Sample(1),
      amountDecimals              : Sample(1),
      ratioDecimals               : Sample(1),
      cfi                         : Sample(6),
      instrumentEventDate         : Sample(2),
      strikePrice                 : Sample(8),
      darkEligibility             : Sample(1),
      darkLisThreshold            : Sample(8),
      darkMinQuantity             : Sample(4),
      dateOfLastTrade             : Sample(2),
      depositaryList              : Sample(20),
      mainDepositary              : Sample(5),
      firstSettlementDate         : Sample(2),
      guaranteeIndicator          : Sample(1),
      icb                         : Sample(16),
      issuingCountry              : Sample(3),
      lastAdjustedClosingPrice    : Sample(8),
      lotSizeOptional             : Sample(8),
      maturityDateOptional        : Sample(8),
      maximumDecimalsInQuantity   : Sample(1),
      mic                         : Sample(4),
      micList                     : Sample(20),
      countryOfExchangeOptional   : Sample(3),
      mnemonic                    : Sample(5),
      underlyingMic               : Sample(4),
      underlyingIsinCode          : Sample(12),
      tradingCurrencyOptional     : Sample(3),
      currencyCoefficient         : Sample(4),
      tradingCurrencyIndicator    : Sample(1),
      strikeCurrencyIndicator     : Sample(1),
      numberInstrumentCirculating : Sample(8),
      parValue                    : Sample(8),
      quantityNotation            : Sample(3),
      instUnitExp                 : Sample(1),
      settlementDelay             : Sample(2),
      strikeCurrency              : Sample(3),
      taxCode                     : Sample(1),
      typeOfCorporateEvent        : Sample(2),
      typeOfMarketAdmission       : Sample(1),
      repoIndicator               : Sample(1),
      issuePrice                  : Sample(8),
      nominalCurrency             : Sample(3),
      issuePriceDecimals          : Sample(1),
      strikePriceDecimals         : Sample(1),
      liquidInstrumentIndicator   : Sample(1),
      marketOfReferenceMic        : Sample(4),
      icbCode                     : Sample(8),
      thresholdLisPostTrade60mn   : Sample(8),
      thresholdLisPostTrade120mn  : Sample(8),
      thresholdLisPostTradeEod    : Sample(8),
      emmPatternRepGroups         : EmmPatternRepGroups ]

EncodeStandingDataMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.symbolIndex
        \o message.optiqSegment
        \o message.partitionId
        \o message.fullInstrumentName
        \o message.instrumentName
        \o message.instrumentTradingCode
        \o message.instrumentGroupCode
        \o message.isinCode
        \o message.priceDecimals
        \o message.quantityDecimals
        \o message.amountDecimals
        \o message.ratioDecimals
        \o message.cfi
        \o message.instrumentEventDate
        \o message.strikePrice
        \o message.darkEligibility
        \o message.darkLisThreshold
        \o message.darkMinQuantity
        \o message.dateOfLastTrade
        \o message.depositaryList
        \o message.mainDepositary
        \o message.firstSettlementDate
        \o message.guaranteeIndicator
        \o message.icb
        \o message.issuingCountry
        \o message.lastAdjustedClosingPrice
        \o message.lotSizeOptional
        \o message.maturityDateOptional
        \o message.maximumDecimalsInQuantity
        \o message.mic
        \o message.micList
        \o message.countryOfExchangeOptional
        \o message.mnemonic
        \o message.underlyingMic
        \o message.underlyingIsinCode
        \o message.tradingCurrencyOptional
        \o message.currencyCoefficient
        \o message.tradingCurrencyIndicator
        \o message.strikeCurrencyIndicator
        \o message.numberInstrumentCirculating
        \o message.parValue
        \o message.quantityNotation
        \o message.instUnitExp
        \o message.settlementDelay
        \o message.strikeCurrency
        \o message.taxCode
        \o message.typeOfCorporateEvent
        \o message.typeOfMarketAdmission
        \o message.repoIndicator
        \o message.issuePrice
        \o message.nominalCurrency
        \o message.issuePriceDecimals
        \o message.strikePriceDecimals
        \o message.liquidInstrumentIndicator
        \o message.marketOfReferenceMic
        \o message.icbCode
        \o message.thresholdLisPostTrade60mn
        \o message.thresholdLisPostTrade120mn
        \o message.thresholdLisPostTradeEod
        \o EncodeEmmPatternRepGroups(message.emmPatternRepGroups)

DecodeStandingDataMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(rebroadcastIndicator.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET optiqSegment == ReadBytes(symbolIndex.rest, 1) IN IF ~optiqSegment.ok THEN Fail ELSE
    LET partitionId == ReadBytes(optiqSegment.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET fullInstrumentName == ReadBytes(partitionId.rest, 102) IN IF ~fullInstrumentName.ok THEN Fail ELSE
    LET instrumentName == ReadBytes(fullInstrumentName.rest, 18) IN IF ~instrumentName.ok THEN Fail ELSE
    LET instrumentTradingCode == ReadBytes(instrumentName.rest, 15) IN IF ~instrumentTradingCode.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(instrumentTradingCode.rest, 2) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET isinCode == ReadBytes(instrumentGroupCode.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET priceDecimals == ReadBytes(isinCode.rest, 1) IN IF ~priceDecimals.ok THEN Fail ELSE
    LET quantityDecimals == ReadBytes(priceDecimals.rest, 1) IN IF ~quantityDecimals.ok THEN Fail ELSE
    LET amountDecimals == ReadBytes(quantityDecimals.rest, 1) IN IF ~amountDecimals.ok THEN Fail ELSE
    LET ratioDecimals == ReadBytes(amountDecimals.rest, 1) IN IF ~ratioDecimals.ok THEN Fail ELSE
    LET cfi == ReadBytes(ratioDecimals.rest, 6) IN IF ~cfi.ok THEN Fail ELSE
    LET instrumentEventDate == ReadBytes(cfi.rest, 2) IN IF ~instrumentEventDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(instrumentEventDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET darkEligibility == ReadBytes(strikePrice.rest, 1) IN IF ~darkEligibility.ok THEN Fail ELSE
    LET darkLisThreshold == ReadBytes(darkEligibility.rest, 8) IN IF ~darkLisThreshold.ok THEN Fail ELSE
    LET darkMinQuantity == ReadBytes(darkLisThreshold.rest, 4) IN IF ~darkMinQuantity.ok THEN Fail ELSE
    LET dateOfLastTrade == ReadBytes(darkMinQuantity.rest, 2) IN IF ~dateOfLastTrade.ok THEN Fail ELSE
    LET depositaryList == ReadBytes(dateOfLastTrade.rest, 20) IN IF ~depositaryList.ok THEN Fail ELSE
    LET mainDepositary == ReadBytes(depositaryList.rest, 5) IN IF ~mainDepositary.ok THEN Fail ELSE
    LET firstSettlementDate == ReadBytes(mainDepositary.rest, 2) IN IF ~firstSettlementDate.ok THEN Fail ELSE
    LET guaranteeIndicator == ReadBytes(firstSettlementDate.rest, 1) IN IF ~guaranteeIndicator.ok THEN Fail ELSE
    LET icb == ReadBytes(guaranteeIndicator.rest, 16) IN IF ~icb.ok THEN Fail ELSE
    LET issuingCountry == ReadBytes(icb.rest, 3) IN IF ~issuingCountry.ok THEN Fail ELSE
    LET lastAdjustedClosingPrice == ReadBytes(issuingCountry.rest, 8) IN IF ~lastAdjustedClosingPrice.ok THEN Fail ELSE
    LET lotSizeOptional == ReadBytes(lastAdjustedClosingPrice.rest, 8) IN IF ~lotSizeOptional.ok THEN Fail ELSE
    LET maturityDateOptional == ReadBytes(lotSizeOptional.rest, 8) IN IF ~maturityDateOptional.ok THEN Fail ELSE
    LET maximumDecimalsInQuantity == ReadBytes(maturityDateOptional.rest, 1) IN IF ~maximumDecimalsInQuantity.ok THEN Fail ELSE
    LET mic == ReadBytes(maximumDecimalsInQuantity.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET micList == ReadBytes(mic.rest, 20) IN IF ~micList.ok THEN Fail ELSE
    LET countryOfExchangeOptional == ReadBytes(micList.rest, 3) IN IF ~countryOfExchangeOptional.ok THEN Fail ELSE
    LET mnemonic == ReadBytes(countryOfExchangeOptional.rest, 5) IN IF ~mnemonic.ok THEN Fail ELSE
    LET underlyingMic == ReadBytes(mnemonic.rest, 4) IN IF ~underlyingMic.ok THEN Fail ELSE
    LET underlyingIsinCode == ReadBytes(underlyingMic.rest, 12) IN IF ~underlyingIsinCode.ok THEN Fail ELSE
    LET tradingCurrencyOptional == ReadBytes(underlyingIsinCode.rest, 3) IN IF ~tradingCurrencyOptional.ok THEN Fail ELSE
    LET currencyCoefficient == ReadBytes(tradingCurrencyOptional.rest, 4) IN IF ~currencyCoefficient.ok THEN Fail ELSE
    LET tradingCurrencyIndicator == ReadBytes(currencyCoefficient.rest, 1) IN IF ~tradingCurrencyIndicator.ok THEN Fail ELSE
    LET strikeCurrencyIndicator == ReadBytes(tradingCurrencyIndicator.rest, 1) IN IF ~strikeCurrencyIndicator.ok THEN Fail ELSE
    LET numberInstrumentCirculating == ReadBytes(strikeCurrencyIndicator.rest, 8) IN IF ~numberInstrumentCirculating.ok THEN Fail ELSE
    LET parValue == ReadBytes(numberInstrumentCirculating.rest, 8) IN IF ~parValue.ok THEN Fail ELSE
    LET quantityNotation == ReadBytes(parValue.rest, 3) IN IF ~quantityNotation.ok THEN Fail ELSE
    LET instUnitExp == ReadBytes(quantityNotation.rest, 1) IN IF ~instUnitExp.ok THEN Fail ELSE
    LET settlementDelay == ReadBytes(instUnitExp.rest, 2) IN IF ~settlementDelay.ok THEN Fail ELSE
    LET strikeCurrency == ReadBytes(settlementDelay.rest, 3) IN IF ~strikeCurrency.ok THEN Fail ELSE
    LET taxCode == ReadBytes(strikeCurrency.rest, 1) IN IF ~taxCode.ok THEN Fail ELSE
    LET typeOfCorporateEvent == ReadBytes(taxCode.rest, 2) IN IF ~typeOfCorporateEvent.ok THEN Fail ELSE
    LET typeOfMarketAdmission == ReadBytes(typeOfCorporateEvent.rest, 1) IN IF ~typeOfMarketAdmission.ok THEN Fail ELSE
    LET repoIndicator == ReadBytes(typeOfMarketAdmission.rest, 1) IN IF ~repoIndicator.ok THEN Fail ELSE
    LET issuePrice == ReadBytes(repoIndicator.rest, 8) IN IF ~issuePrice.ok THEN Fail ELSE
    LET nominalCurrency == ReadBytes(issuePrice.rest, 3) IN IF ~nominalCurrency.ok THEN Fail ELSE
    LET issuePriceDecimals == ReadBytes(nominalCurrency.rest, 1) IN IF ~issuePriceDecimals.ok THEN Fail ELSE
    LET strikePriceDecimals == ReadBytes(issuePriceDecimals.rest, 1) IN IF ~strikePriceDecimals.ok THEN Fail ELSE
    LET liquidInstrumentIndicator == ReadBytes(strikePriceDecimals.rest, 1) IN IF ~liquidInstrumentIndicator.ok THEN Fail ELSE
    LET marketOfReferenceMic == ReadBytes(liquidInstrumentIndicator.rest, 4) IN IF ~marketOfReferenceMic.ok THEN Fail ELSE
    LET icbCode == ReadBytes(marketOfReferenceMic.rest, 8) IN IF ~icbCode.ok THEN Fail ELSE
    LET thresholdLisPostTrade60mn == ReadBytes(icbCode.rest, 8) IN IF ~thresholdLisPostTrade60mn.ok THEN Fail ELSE
    LET thresholdLisPostTrade120mn == ReadBytes(thresholdLisPostTrade60mn.rest, 8) IN IF ~thresholdLisPostTrade120mn.ok THEN Fail ELSE
    LET thresholdLisPostTradeEod == ReadBytes(thresholdLisPostTrade120mn.rest, 8) IN IF ~thresholdLisPostTradeEod.ok THEN Fail ELSE
    LET emmPatternRepGroups == DecodeEmmPatternRepGroups(thresholdLisPostTradeEod.rest) IN IF ~emmPatternRepGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum                    |-> mdSeqNum.value,
         rebroadcastIndicator        |-> rebroadcastIndicator.value,
         symbolIndex                 |-> symbolIndex.value,
         optiqSegment                |-> optiqSegment.value,
         partitionId                 |-> partitionId.value,
         fullInstrumentName          |-> fullInstrumentName.value,
         instrumentName              |-> instrumentName.value,
         instrumentTradingCode       |-> instrumentTradingCode.value,
         instrumentGroupCode         |-> instrumentGroupCode.value,
         isinCode                    |-> isinCode.value,
         priceDecimals               |-> priceDecimals.value,
         quantityDecimals            |-> quantityDecimals.value,
         amountDecimals              |-> amountDecimals.value,
         ratioDecimals               |-> ratioDecimals.value,
         cfi                         |-> cfi.value,
         instrumentEventDate         |-> instrumentEventDate.value,
         strikePrice                 |-> strikePrice.value,
         darkEligibility             |-> darkEligibility.value,
         darkLisThreshold            |-> darkLisThreshold.value,
         darkMinQuantity             |-> darkMinQuantity.value,
         dateOfLastTrade             |-> dateOfLastTrade.value,
         depositaryList              |-> depositaryList.value,
         mainDepositary              |-> mainDepositary.value,
         firstSettlementDate         |-> firstSettlementDate.value,
         guaranteeIndicator          |-> guaranteeIndicator.value,
         icb                         |-> icb.value,
         issuingCountry              |-> issuingCountry.value,
         lastAdjustedClosingPrice    |-> lastAdjustedClosingPrice.value,
         lotSizeOptional             |-> lotSizeOptional.value,
         maturityDateOptional        |-> maturityDateOptional.value,
         maximumDecimalsInQuantity   |-> maximumDecimalsInQuantity.value,
         mic                         |-> mic.value,
         micList                     |-> micList.value,
         countryOfExchangeOptional   |-> countryOfExchangeOptional.value,
         mnemonic                    |-> mnemonic.value,
         underlyingMic               |-> underlyingMic.value,
         underlyingIsinCode          |-> underlyingIsinCode.value,
         tradingCurrencyOptional     |-> tradingCurrencyOptional.value,
         currencyCoefficient         |-> currencyCoefficient.value,
         tradingCurrencyIndicator    |-> tradingCurrencyIndicator.value,
         strikeCurrencyIndicator     |-> strikeCurrencyIndicator.value,
         numberInstrumentCirculating |-> numberInstrumentCirculating.value,
         parValue                    |-> parValue.value,
         quantityNotation            |-> quantityNotation.value,
         instUnitExp                 |-> instUnitExp.value,
         settlementDelay             |-> settlementDelay.value,
         strikeCurrency              |-> strikeCurrency.value,
         taxCode                     |-> taxCode.value,
         typeOfCorporateEvent        |-> typeOfCorporateEvent.value,
         typeOfMarketAdmission       |-> typeOfMarketAdmission.value,
         repoIndicator               |-> repoIndicator.value,
         issuePrice                  |-> issuePrice.value,
         nominalCurrency             |-> nominalCurrency.value,
         issuePriceDecimals          |-> issuePriceDecimals.value,
         strikePriceDecimals         |-> strikePriceDecimals.value,
         liquidInstrumentIndicator   |-> liquidInstrumentIndicator.value,
         marketOfReferenceMic        |-> marketOfReferenceMic.value,
         icbCode                     |-> icbCode.value,
         thresholdLisPostTrade60mn   |-> thresholdLisPostTrade60mn.value,
         thresholdLisPostTrade120mn  |-> thresholdLisPostTrade120mn.value,
         thresholdLisPostTradeEod    |-> thresholdLisPostTradeEod.value,
         emmPatternRepGroups         |-> emmPatternRepGroups.value ], emmPatternRepGroups.rest)

ZeroStandingDataMessage ==
    [ mdSeqNum                    |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator        |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                 |-> [i \in 1 .. 4 |-> 0],
      optiqSegment                |-> [i \in 1 .. 1 |-> 0],
      partitionId                 |-> [i \in 1 .. 2 |-> 0],
      fullInstrumentName          |-> [i \in 1 .. 102 |-> 0],
      instrumentName              |-> [i \in 1 .. 18 |-> 0],
      instrumentTradingCode       |-> [i \in 1 .. 15 |-> 0],
      instrumentGroupCode         |-> [i \in 1 .. 2 |-> 0],
      isinCode                    |-> [i \in 1 .. 12 |-> 0],
      priceDecimals               |-> [i \in 1 .. 1 |-> 0],
      quantityDecimals            |-> [i \in 1 .. 1 |-> 0],
      amountDecimals              |-> [i \in 1 .. 1 |-> 0],
      ratioDecimals               |-> [i \in 1 .. 1 |-> 0],
      cfi                         |-> [i \in 1 .. 6 |-> 0],
      instrumentEventDate         |-> [i \in 1 .. 2 |-> 0],
      strikePrice                 |-> [i \in 1 .. 8 |-> 0],
      darkEligibility             |-> [i \in 1 .. 1 |-> 0],
      darkLisThreshold            |-> [i \in 1 .. 8 |-> 0],
      darkMinQuantity             |-> [i \in 1 .. 4 |-> 0],
      dateOfLastTrade             |-> [i \in 1 .. 2 |-> 0],
      depositaryList              |-> [i \in 1 .. 20 |-> 0],
      mainDepositary              |-> [i \in 1 .. 5 |-> 0],
      firstSettlementDate         |-> [i \in 1 .. 2 |-> 0],
      guaranteeIndicator          |-> [i \in 1 .. 1 |-> 0],
      icb                         |-> [i \in 1 .. 16 |-> 0],
      issuingCountry              |-> [i \in 1 .. 3 |-> 0],
      lastAdjustedClosingPrice    |-> [i \in 1 .. 8 |-> 0],
      lotSizeOptional             |-> [i \in 1 .. 8 |-> 0],
      maturityDateOptional        |-> [i \in 1 .. 8 |-> 0],
      maximumDecimalsInQuantity   |-> [i \in 1 .. 1 |-> 0],
      mic                         |-> [i \in 1 .. 4 |-> 0],
      micList                     |-> [i \in 1 .. 20 |-> 0],
      countryOfExchangeOptional   |-> [i \in 1 .. 3 |-> 0],
      mnemonic                    |-> [i \in 1 .. 5 |-> 0],
      underlyingMic               |-> [i \in 1 .. 4 |-> 0],
      underlyingIsinCode          |-> [i \in 1 .. 12 |-> 0],
      tradingCurrencyOptional     |-> [i \in 1 .. 3 |-> 0],
      currencyCoefficient         |-> [i \in 1 .. 4 |-> 0],
      tradingCurrencyIndicator    |-> [i \in 1 .. 1 |-> 0],
      strikeCurrencyIndicator     |-> [i \in 1 .. 1 |-> 0],
      numberInstrumentCirculating |-> [i \in 1 .. 8 |-> 0],
      parValue                    |-> [i \in 1 .. 8 |-> 0],
      quantityNotation            |-> [i \in 1 .. 3 |-> 0],
      instUnitExp                 |-> [i \in 1 .. 1 |-> 0],
      settlementDelay             |-> [i \in 1 .. 2 |-> 0],
      strikeCurrency              |-> [i \in 1 .. 3 |-> 0],
      taxCode                     |-> [i \in 1 .. 1 |-> 0],
      typeOfCorporateEvent        |-> [i \in 1 .. 2 |-> 0],
      typeOfMarketAdmission       |-> [i \in 1 .. 1 |-> 0],
      repoIndicator               |-> [i \in 1 .. 1 |-> 0],
      issuePrice                  |-> [i \in 1 .. 8 |-> 0],
      nominalCurrency             |-> [i \in 1 .. 3 |-> 0],
      issuePriceDecimals          |-> [i \in 1 .. 1 |-> 0],
      strikePriceDecimals         |-> [i \in 1 .. 1 |-> 0],
      liquidInstrumentIndicator   |-> [i \in 1 .. 1 |-> 0],
      marketOfReferenceMic        |-> [i \in 1 .. 4 |-> 0],
      icbCode                     |-> [i \in 1 .. 8 |-> 0],
      thresholdLisPostTrade60mn   |-> [i \in 1 .. 8 |-> 0],
      thresholdLisPostTrade120mn  |-> [i \in 1 .. 8 |-> 0],
      thresholdLisPostTradeEod    |-> [i \in 1 .. 8 |-> 0],
      emmPatternRepGroups         |-> ZeroEmmPatternRepGroups ]

(* Standing Data Message at zero, then each field in turn at the values it is checked at *)
CheckedStandingDataMessage ==
    { ZeroStandingDataMessage }
        \cup { [ZeroStandingDataMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroStandingDataMessage EXCEPT !.optiqSegment = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroStandingDataMessage EXCEPT !.fullInstrumentName = one] : one \in Sample(102) }
        \cup { [ZeroStandingDataMessage EXCEPT !.instrumentName = one] : one \in Sample(18) }
        \cup { [ZeroStandingDataMessage EXCEPT !.instrumentTradingCode = one] : one \in Sample(15) }
        \cup { [ZeroStandingDataMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(2) }
        \cup { [ZeroStandingDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroStandingDataMessage EXCEPT !.priceDecimals = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.quantityDecimals = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.amountDecimals = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.ratioDecimals = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.cfi = one] : one \in Sample(6) }
        \cup { [ZeroStandingDataMessage EXCEPT !.instrumentEventDate = one] : one \in Sample(2) }
        \cup { [ZeroStandingDataMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.darkEligibility = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.darkLisThreshold = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.darkMinQuantity = one] : one \in Sample(4) }
        \cup { [ZeroStandingDataMessage EXCEPT !.dateOfLastTrade = one] : one \in Sample(2) }
        \cup { [ZeroStandingDataMessage EXCEPT !.depositaryList = one] : one \in Sample(20) }
        \cup { [ZeroStandingDataMessage EXCEPT !.mainDepositary = one] : one \in Sample(5) }
        \cup { [ZeroStandingDataMessage EXCEPT !.firstSettlementDate = one] : one \in Sample(2) }
        \cup { [ZeroStandingDataMessage EXCEPT !.guaranteeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.icb = one] : one \in Sample(16) }
        \cup { [ZeroStandingDataMessage EXCEPT !.issuingCountry = one] : one \in Sample(3) }
        \cup { [ZeroStandingDataMessage EXCEPT !.lastAdjustedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.lotSizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.maturityDateOptional = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.maximumDecimalsInQuantity = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroStandingDataMessage EXCEPT !.micList = one] : one \in Sample(20) }
        \cup { [ZeroStandingDataMessage EXCEPT !.countryOfExchangeOptional = one] : one \in Sample(3) }
        \cup { [ZeroStandingDataMessage EXCEPT !.mnemonic = one] : one \in Sample(5) }
        \cup { [ZeroStandingDataMessage EXCEPT !.underlyingMic = one] : one \in Sample(4) }
        \cup { [ZeroStandingDataMessage EXCEPT !.underlyingIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroStandingDataMessage EXCEPT !.tradingCurrencyOptional = one] : one \in Sample(3) }
        \cup { [ZeroStandingDataMessage EXCEPT !.currencyCoefficient = one] : one \in Sample(4) }
        \cup { [ZeroStandingDataMessage EXCEPT !.tradingCurrencyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.strikeCurrencyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.numberInstrumentCirculating = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.parValue = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.quantityNotation = one] : one \in Sample(3) }
        \cup { [ZeroStandingDataMessage EXCEPT !.instUnitExp = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.settlementDelay = one] : one \in Sample(2) }
        \cup { [ZeroStandingDataMessage EXCEPT !.strikeCurrency = one] : one \in Sample(3) }
        \cup { [ZeroStandingDataMessage EXCEPT !.taxCode = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.typeOfCorporateEvent = one] : one \in Sample(2) }
        \cup { [ZeroStandingDataMessage EXCEPT !.typeOfMarketAdmission = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.repoIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.issuePrice = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.nominalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroStandingDataMessage EXCEPT !.issuePriceDecimals = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.strikePriceDecimals = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.liquidInstrumentIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStandingDataMessage EXCEPT !.marketOfReferenceMic = one] : one \in Sample(4) }
        \cup { [ZeroStandingDataMessage EXCEPT !.icbCode = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.thresholdLisPostTrade60mn = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.thresholdLisPostTrade120mn = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.thresholdLisPostTradeEod = one] : one \in Sample(8) }
        \cup { [ZeroStandingDataMessage EXCEPT !.emmPatternRepGroups = one] : one \in CheckedEmmPatternRepGroups }

(***************************************************************************)
(* Real Time Index Message: 50 bytes                                       *)
(***************************************************************************)

RealTimeIndexMessage ==
    [ mdSeqNum             : Sample(8),
      rebroadcastIndicator : Sample(1),
      emm                  : Sample(1),
      eventTime            : Sample(8),
      symbolIndex          : Sample(4),
      indexLevel           : Sample(8),
      pctgOfCapitalization : Sample(8),
      prctVarfromPrevClose : Sample(8),
      numTradedInstruments : Sample(2),
      indexLevelType       : Sample(1),
      indexPriceCode       : Sample(1) ]

EncodeRealTimeIndexMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.eventTime
        \o message.symbolIndex
        \o message.indexLevel
        \o message.pctgOfCapitalization
        \o message.prctVarfromPrevClose
        \o message.numTradedInstruments
        \o message.indexLevelType
        \o message.indexPriceCode

DecodeRealTimeIndexMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventTime == ReadBytes(emm.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(eventTime.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET indexLevel == ReadBytes(symbolIndex.rest, 8) IN IF ~indexLevel.ok THEN Fail ELSE
    LET pctgOfCapitalization == ReadBytes(indexLevel.rest, 8) IN IF ~pctgOfCapitalization.ok THEN Fail ELSE
    LET prctVarfromPrevClose == ReadBytes(pctgOfCapitalization.rest, 8) IN IF ~prctVarfromPrevClose.ok THEN Fail ELSE
    LET numTradedInstruments == ReadBytes(prctVarfromPrevClose.rest, 2) IN IF ~numTradedInstruments.ok THEN Fail ELSE
    LET indexLevelType == ReadBytes(numTradedInstruments.rest, 1) IN IF ~indexLevelType.ok THEN Fail ELSE
    LET indexPriceCode == ReadBytes(indexLevelType.rest, 1) IN IF ~indexPriceCode.ok THEN Fail ELSE
    Ok([ mdSeqNum             |-> mdSeqNum.value,
         rebroadcastIndicator |-> rebroadcastIndicator.value,
         emm                  |-> emm.value,
         eventTime            |-> eventTime.value,
         symbolIndex          |-> symbolIndex.value,
         indexLevel           |-> indexLevel.value,
         pctgOfCapitalization |-> pctgOfCapitalization.value,
         prctVarfromPrevClose |-> prctVarfromPrevClose.value,
         numTradedInstruments |-> numTradedInstruments.value,
         indexLevelType       |-> indexLevelType.value,
         indexPriceCode       |-> indexPriceCode.value ], indexPriceCode.rest)

ZeroRealTimeIndexMessage ==
    [ mdSeqNum             |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator |-> [i \in 1 .. 1 |-> 0],
      emm                  |-> [i \in 1 .. 1 |-> 0],
      eventTime            |-> [i \in 1 .. 8 |-> 0],
      symbolIndex          |-> [i \in 1 .. 4 |-> 0],
      indexLevel           |-> [i \in 1 .. 8 |-> 0],
      pctgOfCapitalization |-> [i \in 1 .. 8 |-> 0],
      prctVarfromPrevClose |-> [i \in 1 .. 8 |-> 0],
      numTradedInstruments |-> [i \in 1 .. 2 |-> 0],
      indexLevelType       |-> [i \in 1 .. 1 |-> 0],
      indexPriceCode       |-> [i \in 1 .. 1 |-> 0] ]

(* Real Time Index Message at zero, then each field in turn at the values it is checked at *)
CheckedRealTimeIndexMessage ==
    { ZeroRealTimeIndexMessage }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexLevel = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.pctgOfCapitalization = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.prctVarfromPrevClose = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.numTradedInstruments = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexLevelType = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexPriceCode = one] : one \in Sample(1) }

(***************************************************************************)
(* New Stats Group: 9 bytes                                                *)
(***************************************************************************)

NewStatsGroup ==
    [ statsUpdateType  : Sample(1),
      statsUpdateValue : Sample(8) ]

EncodeNewStatsGroup(message) ==
    message.statsUpdateType
        \o message.statsUpdateValue

DecodeNewStatsGroup(bytes) ==
    LET statsUpdateType == ReadBytes(bytes, 1) IN IF ~statsUpdateType.ok THEN Fail ELSE
    LET statsUpdateValue == ReadBytes(statsUpdateType.rest, 8) IN IF ~statsUpdateValue.ok THEN Fail ELSE
    Ok([ statsUpdateType  |-> statsUpdateType.value,
         statsUpdateValue |-> statsUpdateValue.value ], statsUpdateValue.rest)

ZeroNewStatsGroup ==
    [ statsUpdateType  |-> [i \in 1 .. 1 |-> 0],
      statsUpdateValue |-> [i \in 1 .. 8 |-> 0] ]

(* New Stats Group at zero, then each field in turn at the values it is checked at *)
CheckedNewStatsGroup ==
    { ZeroNewStatsGroup }
        \cup { [ZeroNewStatsGroup EXCEPT !.statsUpdateType = one] : one \in Sample(1) }
        \cup { [ZeroNewStatsGroup EXCEPT !.statsUpdateValue = one] : one \in Sample(8) }

(* A run of New Stats Group, written one after another *)
RECURSIVE EncodeNewStatsGroupList(_)
EncodeNewStatsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewStatsGroup(Head(messages)) \o EncodeNewStatsGroupList(Tail(messages))

(* As many New Stats Group as the field that counts them says *)
RECURSIVE ReadNewStatsGroupList(_, _)
ReadNewStatsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewStatsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewStatsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Stats Group of each kind, for the lists that carry them *)
OneNewStatsGroup == { ZeroNewStatsGroup }

(***************************************************************************)
(* New Stats Groups                                                        *)
(***************************************************************************)

NewStatsGroups ==
    [ blockLengthShort : Sample(1),
      newStatsGroup    : SampleLists(OneNewStatsGroup) ]

EncodeNewStatsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.newStatsGroup), 1)
        \o EncodeNewStatsGroupList(message.newStatsGroup)

DecodeNewStatsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newStatsGroup == ReadNewStatsGroupList(numInGroup.rest, numInGroup.value) IN IF ~newStatsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         newStatsGroup    |-> newStatsGroup.value ], newStatsGroup.rest)

ZeroNewStatsGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      newStatsGroup    |-> << >> ]

(* New Stats Groups at zero, then each field in turn at the values it is checked at *)
CheckedNewStatsGroups ==
    { ZeroNewStatsGroups }
        \cup { [ZeroNewStatsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroNewStatsGroups EXCEPT !.newStatsGroup = one] : one \in SampleLists(OneNewStatsGroup) }

(***************************************************************************)
(* Statistics Message                                                      *)
(***************************************************************************)

StatisticsMessage ==
    [ mdSeqNum             : Sample(8),
      rebroadcastIndicator : Sample(1),
      symbolIndex          : Sample(4),
      newStatsGroups       : NewStatsGroups ]

EncodeStatisticsMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.symbolIndex
        \o EncodeNewStatsGroups(message.newStatsGroups)

DecodeStatisticsMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(rebroadcastIndicator.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET newStatsGroups == DecodeNewStatsGroups(symbolIndex.rest) IN IF ~newStatsGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum             |-> mdSeqNum.value,
         rebroadcastIndicator |-> rebroadcastIndicator.value,
         symbolIndex          |-> symbolIndex.value,
         newStatsGroups       |-> newStatsGroups.value ], newStatsGroups.rest)

ZeroStatisticsMessage ==
    [ mdSeqNum             |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator |-> [i \in 1 .. 1 |-> 0],
      symbolIndex          |-> [i \in 1 .. 4 |-> 0],
      newStatsGroups       |-> ZeroNewStatsGroups ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.newStatsGroups = one] : one \in CheckedNewStatsGroups }

(***************************************************************************)
(* Index Summary Message: 126 bytes                                        *)
(***************************************************************************)

IndexSummaryMessage ==
    [ mdSeqNum                : Sample(8),
      rebroadcastIndicator    : Sample(1),
      emm                     : Sample(1),
      eventTime               : Sample(8),
      symbolIndex             : Sample(4),
      openingLevel            : Sample(8),
      openingTime             : Sample(8),
      confirmedReferenceLevel : Sample(8),
      confirmedReferenceTime  : Sample(8),
      closingReferenceLevel   : Sample(8),
      closingReferenceTime    : Sample(8),
      prctVarfromPrevClose    : Sample(8),
      highLevel               : Sample(8),
      highTime                : Sample(8),
      lowLevel                : Sample(8),
      lowTime                 : Sample(8),
      liquidationLevel        : Sample(8),
      liquidationTime         : Sample(8) ]

EncodeIndexSummaryMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.eventTime
        \o message.symbolIndex
        \o message.openingLevel
        \o message.openingTime
        \o message.confirmedReferenceLevel
        \o message.confirmedReferenceTime
        \o message.closingReferenceLevel
        \o message.closingReferenceTime
        \o message.prctVarfromPrevClose
        \o message.highLevel
        \o message.highTime
        \o message.lowLevel
        \o message.lowTime
        \o message.liquidationLevel
        \o message.liquidationTime

DecodeIndexSummaryMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventTime == ReadBytes(emm.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(eventTime.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET openingLevel == ReadBytes(symbolIndex.rest, 8) IN IF ~openingLevel.ok THEN Fail ELSE
    LET openingTime == ReadBytes(openingLevel.rest, 8) IN IF ~openingTime.ok THEN Fail ELSE
    LET confirmedReferenceLevel == ReadBytes(openingTime.rest, 8) IN IF ~confirmedReferenceLevel.ok THEN Fail ELSE
    LET confirmedReferenceTime == ReadBytes(confirmedReferenceLevel.rest, 8) IN IF ~confirmedReferenceTime.ok THEN Fail ELSE
    LET closingReferenceLevel == ReadBytes(confirmedReferenceTime.rest, 8) IN IF ~closingReferenceLevel.ok THEN Fail ELSE
    LET closingReferenceTime == ReadBytes(closingReferenceLevel.rest, 8) IN IF ~closingReferenceTime.ok THEN Fail ELSE
    LET prctVarfromPrevClose == ReadBytes(closingReferenceTime.rest, 8) IN IF ~prctVarfromPrevClose.ok THEN Fail ELSE
    LET highLevel == ReadBytes(prctVarfromPrevClose.rest, 8) IN IF ~highLevel.ok THEN Fail ELSE
    LET highTime == ReadBytes(highLevel.rest, 8) IN IF ~highTime.ok THEN Fail ELSE
    LET lowLevel == ReadBytes(highTime.rest, 8) IN IF ~lowLevel.ok THEN Fail ELSE
    LET lowTime == ReadBytes(lowLevel.rest, 8) IN IF ~lowTime.ok THEN Fail ELSE
    LET liquidationLevel == ReadBytes(lowTime.rest, 8) IN IF ~liquidationLevel.ok THEN Fail ELSE
    LET liquidationTime == ReadBytes(liquidationLevel.rest, 8) IN IF ~liquidationTime.ok THEN Fail ELSE
    Ok([ mdSeqNum                |-> mdSeqNum.value,
         rebroadcastIndicator    |-> rebroadcastIndicator.value,
         emm                     |-> emm.value,
         eventTime               |-> eventTime.value,
         symbolIndex             |-> symbolIndex.value,
         openingLevel            |-> openingLevel.value,
         openingTime             |-> openingTime.value,
         confirmedReferenceLevel |-> confirmedReferenceLevel.value,
         confirmedReferenceTime  |-> confirmedReferenceTime.value,
         closingReferenceLevel   |-> closingReferenceLevel.value,
         closingReferenceTime    |-> closingReferenceTime.value,
         prctVarfromPrevClose    |-> prctVarfromPrevClose.value,
         highLevel               |-> highLevel.value,
         highTime                |-> highTime.value,
         lowLevel                |-> lowLevel.value,
         lowTime                 |-> lowTime.value,
         liquidationLevel        |-> liquidationLevel.value,
         liquidationTime         |-> liquidationTime.value ], liquidationTime.rest)

ZeroIndexSummaryMessage ==
    [ mdSeqNum                |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator    |-> [i \in 1 .. 1 |-> 0],
      emm                     |-> [i \in 1 .. 1 |-> 0],
      eventTime               |-> [i \in 1 .. 8 |-> 0],
      symbolIndex             |-> [i \in 1 .. 4 |-> 0],
      openingLevel            |-> [i \in 1 .. 8 |-> 0],
      openingTime             |-> [i \in 1 .. 8 |-> 0],
      confirmedReferenceLevel |-> [i \in 1 .. 8 |-> 0],
      confirmedReferenceTime  |-> [i \in 1 .. 8 |-> 0],
      closingReferenceLevel   |-> [i \in 1 .. 8 |-> 0],
      closingReferenceTime    |-> [i \in 1 .. 8 |-> 0],
      prctVarfromPrevClose    |-> [i \in 1 .. 8 |-> 0],
      highLevel               |-> [i \in 1 .. 8 |-> 0],
      highTime                |-> [i \in 1 .. 8 |-> 0],
      lowLevel                |-> [i \in 1 .. 8 |-> 0],
      lowTime                 |-> [i \in 1 .. 8 |-> 0],
      liquidationLevel        |-> [i \in 1 .. 8 |-> 0],
      liquidationTime         |-> [i \in 1 .. 8 |-> 0] ]

(* Index Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexSummaryMessage ==
    { ZeroIndexSummaryMessage }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.openingLevel = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.confirmedReferenceLevel = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.confirmedReferenceTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.closingReferenceLevel = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.closingReferenceTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.prctVarfromPrevClose = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.highLevel = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.highTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.lowLevel = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.lowTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.liquidationLevel = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.liquidationTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Strategy Standing Data Group: 17 bytes                                  *)
(***************************************************************************)

StrategyStandingDataGroup ==
    [ legSymbolIndex : Sample(4),
      legPrice       : Sample(8),
      legRatio       : Sample(4),
      legBuySell     : Sample(1) ]

EncodeStrategyStandingDataGroup(message) ==
    message.legSymbolIndex
        \o message.legPrice
        \o message.legRatio
        \o message.legBuySell

DecodeStrategyStandingDataGroup(bytes) ==
    LET legSymbolIndex == ReadBytes(bytes, 4) IN IF ~legSymbolIndex.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSymbolIndex.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legPrice.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legBuySell == ReadBytes(legRatio.rest, 1) IN IF ~legBuySell.ok THEN Fail ELSE
    Ok([ legSymbolIndex |-> legSymbolIndex.value,
         legPrice       |-> legPrice.value,
         legRatio       |-> legRatio.value,
         legBuySell     |-> legBuySell.value ], legBuySell.rest)

ZeroStrategyStandingDataGroup ==
    [ legSymbolIndex |-> [i \in 1 .. 4 |-> 0],
      legPrice       |-> [i \in 1 .. 8 |-> 0],
      legRatio       |-> [i \in 1 .. 4 |-> 0],
      legBuySell     |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Standing Data Group at zero, then each field in turn at the values it is checked at *)
CheckedStrategyStandingDataGroup ==
    { ZeroStrategyStandingDataGroup }
        \cup { [ZeroStrategyStandingDataGroup EXCEPT !.legSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroStrategyStandingDataGroup EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroStrategyStandingDataGroup EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroStrategyStandingDataGroup EXCEPT !.legBuySell = one] : one \in Sample(1) }

(* A run of Strategy Standing Data Group, written one after another *)
RECURSIVE EncodeStrategyStandingDataGroupList(_)
EncodeStrategyStandingDataGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyStandingDataGroup(Head(messages)) \o EncodeStrategyStandingDataGroupList(Tail(messages))

(* As many Strategy Standing Data Group as the field that counts them says *)
RECURSIVE ReadStrategyStandingDataGroupList(_, _)
ReadStrategyStandingDataGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyStandingDataGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyStandingDataGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Standing Data Group of each kind, for the lists that carry them *)
OneStrategyStandingDataGroup == { ZeroStrategyStandingDataGroup }

(***************************************************************************)
(* Strategy Standing Data Groups                                           *)
(***************************************************************************)

StrategyStandingDataGroups ==
    [ blockLengthShort          : Sample(1),
      strategyStandingDataGroup : SampleLists(OneStrategyStandingDataGroup) ]

EncodeStrategyStandingDataGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.strategyStandingDataGroup), 1)
        \o EncodeStrategyStandingDataGroupList(message.strategyStandingDataGroup)

DecodeStrategyStandingDataGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET strategyStandingDataGroup == ReadStrategyStandingDataGroupList(numInGroup.rest, numInGroup.value) IN IF ~strategyStandingDataGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort          |-> blockLengthShort.value,
         strategyStandingDataGroup |-> strategyStandingDataGroup.value ], strategyStandingDataGroup.rest)

ZeroStrategyStandingDataGroups ==
    [ blockLengthShort          |-> [i \in 1 .. 1 |-> 0],
      strategyStandingDataGroup |-> << >> ]

(* Strategy Standing Data Groups at zero, then each field in turn at the values it is checked at *)
CheckedStrategyStandingDataGroups ==
    { ZeroStrategyStandingDataGroups }
        \cup { [ZeroStrategyStandingDataGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroStrategyStandingDataGroups EXCEPT !.strategyStandingDataGroup = one] : one \in SampleLists(OneStrategyStandingDataGroup) }

(***************************************************************************)
(* Strategy Standing Data Message                                          *)
(***************************************************************************)

StrategyStandingDataMessage ==
    [ mdSeqNum                         : Sample(8),
      rebroadcastIndicator             : Sample(1),
      emm                              : Sample(1),
      symbolIndex                      : Sample(4),
      derivativesInstrumentTradingCode : Sample(18),
      exchangeCode                     : Sample(1),
      maturityDate                     : Sample(8),
      strategyCode                     : Sample(1),
      contractSymbolIndex              : Sample(4),
      cfiOptional                      : Sample(6),
      strategyStandingDataGroups       : StrategyStandingDataGroups ]

EncodeStrategyStandingDataMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.symbolIndex
        \o message.derivativesInstrumentTradingCode
        \o message.exchangeCode
        \o message.maturityDate
        \o message.strategyCode
        \o message.contractSymbolIndex
        \o message.cfiOptional
        \o EncodeStrategyStandingDataGroups(message.strategyStandingDataGroups)

DecodeStrategyStandingDataMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(emm.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET derivativesInstrumentTradingCode == ReadBytes(symbolIndex.rest, 18) IN IF ~derivativesInstrumentTradingCode.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(derivativesInstrumentTradingCode.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(exchangeCode.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strategyCode == ReadBytes(maturityDate.rest, 1) IN IF ~strategyCode.ok THEN Fail ELSE
    LET contractSymbolIndex == ReadBytes(strategyCode.rest, 4) IN IF ~contractSymbolIndex.ok THEN Fail ELSE
    LET cfiOptional == ReadBytes(contractSymbolIndex.rest, 6) IN IF ~cfiOptional.ok THEN Fail ELSE
    LET strategyStandingDataGroups == DecodeStrategyStandingDataGroups(cfiOptional.rest) IN IF ~strategyStandingDataGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum                         |-> mdSeqNum.value,
         rebroadcastIndicator             |-> rebroadcastIndicator.value,
         emm                              |-> emm.value,
         symbolIndex                      |-> symbolIndex.value,
         derivativesInstrumentTradingCode |-> derivativesInstrumentTradingCode.value,
         exchangeCode                     |-> exchangeCode.value,
         maturityDate                     |-> maturityDate.value,
         strategyCode                     |-> strategyCode.value,
         contractSymbolIndex              |-> contractSymbolIndex.value,
         cfiOptional                      |-> cfiOptional.value,
         strategyStandingDataGroups       |-> strategyStandingDataGroups.value ], strategyStandingDataGroups.rest)

ZeroStrategyStandingDataMessage ==
    [ mdSeqNum                         |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator             |-> [i \in 1 .. 1 |-> 0],
      emm                              |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                      |-> [i \in 1 .. 4 |-> 0],
      derivativesInstrumentTradingCode |-> [i \in 1 .. 18 |-> 0],
      exchangeCode                     |-> [i \in 1 .. 1 |-> 0],
      maturityDate                     |-> [i \in 1 .. 8 |-> 0],
      strategyCode                     |-> [i \in 1 .. 1 |-> 0],
      contractSymbolIndex              |-> [i \in 1 .. 4 |-> 0],
      cfiOptional                      |-> [i \in 1 .. 6 |-> 0],
      strategyStandingDataGroups       |-> ZeroStrategyStandingDataGroups ]

(* Strategy Standing Data Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyStandingDataMessage ==
    { ZeroStrategyStandingDataMessage }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.derivativesInstrumentTradingCode = one] : one \in Sample(18) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.strategyCode = one] : one \in Sample(1) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.contractSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.cfiOptional = one] : one \in Sample(6) }
        \cup { [ZeroStrategyStandingDataMessage EXCEPT !.strategyStandingDataGroups = one] : one \in CheckedStrategyStandingDataGroups }

(***************************************************************************)
(* Contract Emm Properties Group: 27 bytes                                 *)
(***************************************************************************)

ContractEmmPropertiesGroup ==
    [ emmOptional        : Sample(1),
      tickSizeIndexId    : Sample(2),
      patternId          : Sample(2),
      lotSizeOptional    : Sample(8),
      strategyAuthorized : Sample(8),
      dynamicCollarLogic : Sample(1),
      collarMaxUnhaltNb  : Sample(1),
      collarUnhaltDelay  : Sample(4) ]

EncodeContractEmmPropertiesGroup(message) ==
    message.emmOptional
        \o message.tickSizeIndexId
        \o message.patternId
        \o message.lotSizeOptional
        \o message.strategyAuthorized
        \o message.dynamicCollarLogic
        \o message.collarMaxUnhaltNb
        \o message.collarUnhaltDelay

DecodeContractEmmPropertiesGroup(bytes) ==
    LET emmOptional == ReadBytes(bytes, 1) IN IF ~emmOptional.ok THEN Fail ELSE
    LET tickSizeIndexId == ReadBytes(emmOptional.rest, 2) IN IF ~tickSizeIndexId.ok THEN Fail ELSE
    LET patternId == ReadBytes(tickSizeIndexId.rest, 2) IN IF ~patternId.ok THEN Fail ELSE
    LET lotSizeOptional == ReadBytes(patternId.rest, 8) IN IF ~lotSizeOptional.ok THEN Fail ELSE
    LET strategyAuthorized == ReadBytes(lotSizeOptional.rest, 8) IN IF ~strategyAuthorized.ok THEN Fail ELSE
    LET dynamicCollarLogic == ReadBytes(strategyAuthorized.rest, 1) IN IF ~dynamicCollarLogic.ok THEN Fail ELSE
    LET collarMaxUnhaltNb == ReadBytes(dynamicCollarLogic.rest, 1) IN IF ~collarMaxUnhaltNb.ok THEN Fail ELSE
    LET collarUnhaltDelay == ReadBytes(collarMaxUnhaltNb.rest, 4) IN IF ~collarUnhaltDelay.ok THEN Fail ELSE
    Ok([ emmOptional        |-> emmOptional.value,
         tickSizeIndexId    |-> tickSizeIndexId.value,
         patternId          |-> patternId.value,
         lotSizeOptional    |-> lotSizeOptional.value,
         strategyAuthorized |-> strategyAuthorized.value,
         dynamicCollarLogic |-> dynamicCollarLogic.value,
         collarMaxUnhaltNb  |-> collarMaxUnhaltNb.value,
         collarUnhaltDelay  |-> collarUnhaltDelay.value ], collarUnhaltDelay.rest)

ZeroContractEmmPropertiesGroup ==
    [ emmOptional        |-> [i \in 1 .. 1 |-> 0],
      tickSizeIndexId    |-> [i \in 1 .. 2 |-> 0],
      patternId          |-> [i \in 1 .. 2 |-> 0],
      lotSizeOptional    |-> [i \in 1 .. 8 |-> 0],
      strategyAuthorized |-> [i \in 1 .. 8 |-> 0],
      dynamicCollarLogic |-> [i \in 1 .. 1 |-> 0],
      collarMaxUnhaltNb  |-> [i \in 1 .. 1 |-> 0],
      collarUnhaltDelay  |-> [i \in 1 .. 4 |-> 0] ]

(* Contract Emm Properties Group at zero, then each field in turn at the values it is checked at *)
CheckedContractEmmPropertiesGroup ==
    { ZeroContractEmmPropertiesGroup }
        \cup { [ZeroContractEmmPropertiesGroup EXCEPT !.emmOptional = one] : one \in Sample(1) }
        \cup { [ZeroContractEmmPropertiesGroup EXCEPT !.tickSizeIndexId = one] : one \in Sample(2) }
        \cup { [ZeroContractEmmPropertiesGroup EXCEPT !.patternId = one] : one \in Sample(2) }
        \cup { [ZeroContractEmmPropertiesGroup EXCEPT !.lotSizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroContractEmmPropertiesGroup EXCEPT !.strategyAuthorized = one] : one \in Sample(8) }
        \cup { [ZeroContractEmmPropertiesGroup EXCEPT !.dynamicCollarLogic = one] : one \in Sample(1) }
        \cup { [ZeroContractEmmPropertiesGroup EXCEPT !.collarMaxUnhaltNb = one] : one \in Sample(1) }
        \cup { [ZeroContractEmmPropertiesGroup EXCEPT !.collarUnhaltDelay = one] : one \in Sample(4) }

(* A run of Contract Emm Properties Group, written one after another *)
RECURSIVE EncodeContractEmmPropertiesGroupList(_)
EncodeContractEmmPropertiesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeContractEmmPropertiesGroup(Head(messages)) \o EncodeContractEmmPropertiesGroupList(Tail(messages))

(* As many Contract Emm Properties Group as the field that counts them says *)
RECURSIVE ReadContractEmmPropertiesGroupList(_, _)
ReadContractEmmPropertiesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeContractEmmPropertiesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadContractEmmPropertiesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Contract Emm Properties Group of each kind, for the lists that carry them *)
OneContractEmmPropertiesGroup == { ZeroContractEmmPropertiesGroup }

(***************************************************************************)
(* Contract Emm Properties Groups                                          *)
(***************************************************************************)

ContractEmmPropertiesGroups ==
    [ blockLengthShort           : Sample(1),
      contractEmmPropertiesGroup : SampleLists(OneContractEmmPropertiesGroup) ]

EncodeContractEmmPropertiesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.contractEmmPropertiesGroup), 1)
        \o EncodeContractEmmPropertiesGroupList(message.contractEmmPropertiesGroup)

DecodeContractEmmPropertiesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET contractEmmPropertiesGroup == ReadContractEmmPropertiesGroupList(numInGroup.rest, numInGroup.value) IN IF ~contractEmmPropertiesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort           |-> blockLengthShort.value,
         contractEmmPropertiesGroup |-> contractEmmPropertiesGroup.value ], contractEmmPropertiesGroup.rest)

ZeroContractEmmPropertiesGroups ==
    [ blockLengthShort           |-> [i \in 1 .. 1 |-> 0],
      contractEmmPropertiesGroup |-> << >> ]

(* Contract Emm Properties Groups at zero, then each field in turn at the values it is checked at *)
CheckedContractEmmPropertiesGroups ==
    { ZeroContractEmmPropertiesGroups }
        \cup { [ZeroContractEmmPropertiesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroContractEmmPropertiesGroups EXCEPT !.contractEmmPropertiesGroup = one] : one \in SampleLists(OneContractEmmPropertiesGroup) }

(***************************************************************************)
(* Contract Standing Data Message                                          *)
(***************************************************************************)

ContractStandingDataMessage ==
    [ mdSeqNum                                  : Sample(8),
      rebroadcastIndicator                      : Sample(1),
      symbolIndex                               : Sample(4),
      optiqSegment                              : Sample(1),
      partitionId                               : Sample(2),
      contractEventDate                         : Sample(2),
      exchangeCode                              : Sample(1),
      exerStyle                                 : Sample(1),
      contractName                              : Sample(60),
      contractType                              : Sample(1),
      underlyingType                            : Sample(1),
      priceDecimalsOptional                     : Sample(1),
      quantityDecimals                          : Sample(1),
      amountDecimals                            : Sample(1),
      ratioDecimalsOptional                     : Sample(1),
      mainDepositary                            : Sample(5),
      mic                                       : Sample(4),
      countryOfExchange                         : Sample(3),
      productCode                               : Sample(4),
      underlyingMic                             : Sample(4),
      underlyingIsinCode                        : Sample(12),
      underlyingExpiry                          : Sample(4),
      orderTypeRules                            : Sample(2),
      settlementMethod                          : Sample(1),
      tradingCurrency                           : Sample(3),
      strikePriceDecimalsRatio                  : Sample(1),
      mmProtections                             : Sample(1),
      contractTradingType                       : Sample(1),
      instUnitExp                               : Sample(1),
      underlyingSubtype                         : Sample(1),
      motherStockIsin                           : Sample(12),
      settlementTickSize                        : Sample(8),
      edspTickSize                              : Sample(8),
      underlyingSymbolIndex                     : Sample(4),
      tradingPolicy                             : Sample(1),
      referenceSpreadTableId                    : Sample(2),
      derivativesMarketModel                    : Sample(1),
      tradingUnit                               : Sample(8),
      referencePriceOriginInOpeningCall         : Sample(1),
      referencePriceOriginInContinuous          : Sample(1),
      referencePriceOriginInTradingInterruption : Sample(1),
      collarExpansionFactor                     : Sample(1),
      mifidiiLiquidFlag                         : Sample(1),
      pricingAlgorithm                          : Sample(1),
      contractEmmPropertiesGroups               : ContractEmmPropertiesGroups ]

EncodeContractStandingDataMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.symbolIndex
        \o message.optiqSegment
        \o message.partitionId
        \o message.contractEventDate
        \o message.exchangeCode
        \o message.exerStyle
        \o message.contractName
        \o message.contractType
        \o message.underlyingType
        \o message.priceDecimalsOptional
        \o message.quantityDecimals
        \o message.amountDecimals
        \o message.ratioDecimalsOptional
        \o message.mainDepositary
        \o message.mic
        \o message.countryOfExchange
        \o message.productCode
        \o message.underlyingMic
        \o message.underlyingIsinCode
        \o message.underlyingExpiry
        \o message.orderTypeRules
        \o message.settlementMethod
        \o message.tradingCurrency
        \o message.strikePriceDecimalsRatio
        \o message.mmProtections
        \o message.contractTradingType
        \o message.instUnitExp
        \o message.underlyingSubtype
        \o message.motherStockIsin
        \o message.settlementTickSize
        \o message.edspTickSize
        \o message.underlyingSymbolIndex
        \o message.tradingPolicy
        \o message.referenceSpreadTableId
        \o message.derivativesMarketModel
        \o message.tradingUnit
        \o message.referencePriceOriginInOpeningCall
        \o message.referencePriceOriginInContinuous
        \o message.referencePriceOriginInTradingInterruption
        \o message.collarExpansionFactor
        \o message.mifidiiLiquidFlag
        \o message.pricingAlgorithm
        \o EncodeContractEmmPropertiesGroups(message.contractEmmPropertiesGroups)

DecodeContractStandingDataMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(rebroadcastIndicator.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET optiqSegment == ReadBytes(symbolIndex.rest, 1) IN IF ~optiqSegment.ok THEN Fail ELSE
    LET partitionId == ReadBytes(optiqSegment.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET contractEventDate == ReadBytes(partitionId.rest, 2) IN IF ~contractEventDate.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(contractEventDate.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET exerStyle == ReadBytes(exchangeCode.rest, 1) IN IF ~exerStyle.ok THEN Fail ELSE
    LET contractName == ReadBytes(exerStyle.rest, 60) IN IF ~contractName.ok THEN Fail ELSE
    LET contractType == ReadBytes(contractName.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET underlyingType == ReadBytes(contractType.rest, 1) IN IF ~underlyingType.ok THEN Fail ELSE
    LET priceDecimalsOptional == ReadBytes(underlyingType.rest, 1) IN IF ~priceDecimalsOptional.ok THEN Fail ELSE
    LET quantityDecimals == ReadBytes(priceDecimalsOptional.rest, 1) IN IF ~quantityDecimals.ok THEN Fail ELSE
    LET amountDecimals == ReadBytes(quantityDecimals.rest, 1) IN IF ~amountDecimals.ok THEN Fail ELSE
    LET ratioDecimalsOptional == ReadBytes(amountDecimals.rest, 1) IN IF ~ratioDecimalsOptional.ok THEN Fail ELSE
    LET mainDepositary == ReadBytes(ratioDecimalsOptional.rest, 5) IN IF ~mainDepositary.ok THEN Fail ELSE
    LET mic == ReadBytes(mainDepositary.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET countryOfExchange == ReadBytes(mic.rest, 3) IN IF ~countryOfExchange.ok THEN Fail ELSE
    LET productCode == ReadBytes(countryOfExchange.rest, 4) IN IF ~productCode.ok THEN Fail ELSE
    LET underlyingMic == ReadBytes(productCode.rest, 4) IN IF ~underlyingMic.ok THEN Fail ELSE
    LET underlyingIsinCode == ReadBytes(underlyingMic.rest, 12) IN IF ~underlyingIsinCode.ok THEN Fail ELSE
    LET underlyingExpiry == ReadBytes(underlyingIsinCode.rest, 4) IN IF ~underlyingExpiry.ok THEN Fail ELSE
    LET orderTypeRules == ReadBytes(underlyingExpiry.rest, 2) IN IF ~orderTypeRules.ok THEN Fail ELSE
    LET settlementMethod == ReadBytes(orderTypeRules.rest, 1) IN IF ~settlementMethod.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(settlementMethod.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET strikePriceDecimalsRatio == ReadBytes(tradingCurrency.rest, 1) IN IF ~strikePriceDecimalsRatio.ok THEN Fail ELSE
    LET mmProtections == ReadBytes(strikePriceDecimalsRatio.rest, 1) IN IF ~mmProtections.ok THEN Fail ELSE
    LET contractTradingType == ReadBytes(mmProtections.rest, 1) IN IF ~contractTradingType.ok THEN Fail ELSE
    LET instUnitExp == ReadBytes(contractTradingType.rest, 1) IN IF ~instUnitExp.ok THEN Fail ELSE
    LET underlyingSubtype == ReadBytes(instUnitExp.rest, 1) IN IF ~underlyingSubtype.ok THEN Fail ELSE
    LET motherStockIsin == ReadBytes(underlyingSubtype.rest, 12) IN IF ~motherStockIsin.ok THEN Fail ELSE
    LET settlementTickSize == ReadBytes(motherStockIsin.rest, 8) IN IF ~settlementTickSize.ok THEN Fail ELSE
    LET edspTickSize == ReadBytes(settlementTickSize.rest, 8) IN IF ~edspTickSize.ok THEN Fail ELSE
    LET underlyingSymbolIndex == ReadBytes(edspTickSize.rest, 4) IN IF ~underlyingSymbolIndex.ok THEN Fail ELSE
    LET tradingPolicy == ReadBytes(underlyingSymbolIndex.rest, 1) IN IF ~tradingPolicy.ok THEN Fail ELSE
    LET referenceSpreadTableId == ReadBytes(tradingPolicy.rest, 2) IN IF ~referenceSpreadTableId.ok THEN Fail ELSE
    LET derivativesMarketModel == ReadBytes(referenceSpreadTableId.rest, 1) IN IF ~derivativesMarketModel.ok THEN Fail ELSE
    LET tradingUnit == ReadBytes(derivativesMarketModel.rest, 8) IN IF ~tradingUnit.ok THEN Fail ELSE
    LET referencePriceOriginInOpeningCall == ReadBytes(tradingUnit.rest, 1) IN IF ~referencePriceOriginInOpeningCall.ok THEN Fail ELSE
    LET referencePriceOriginInContinuous == ReadBytes(referencePriceOriginInOpeningCall.rest, 1) IN IF ~referencePriceOriginInContinuous.ok THEN Fail ELSE
    LET referencePriceOriginInTradingInterruption == ReadBytes(referencePriceOriginInContinuous.rest, 1) IN IF ~referencePriceOriginInTradingInterruption.ok THEN Fail ELSE
    LET collarExpansionFactor == ReadBytes(referencePriceOriginInTradingInterruption.rest, 1) IN IF ~collarExpansionFactor.ok THEN Fail ELSE
    LET mifidiiLiquidFlag == ReadBytes(collarExpansionFactor.rest, 1) IN IF ~mifidiiLiquidFlag.ok THEN Fail ELSE
    LET pricingAlgorithm == ReadBytes(mifidiiLiquidFlag.rest, 1) IN IF ~pricingAlgorithm.ok THEN Fail ELSE
    LET contractEmmPropertiesGroups == DecodeContractEmmPropertiesGroups(pricingAlgorithm.rest) IN IF ~contractEmmPropertiesGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum                                  |-> mdSeqNum.value,
         rebroadcastIndicator                      |-> rebroadcastIndicator.value,
         symbolIndex                               |-> symbolIndex.value,
         optiqSegment                              |-> optiqSegment.value,
         partitionId                               |-> partitionId.value,
         contractEventDate                         |-> contractEventDate.value,
         exchangeCode                              |-> exchangeCode.value,
         exerStyle                                 |-> exerStyle.value,
         contractName                              |-> contractName.value,
         contractType                              |-> contractType.value,
         underlyingType                            |-> underlyingType.value,
         priceDecimalsOptional                     |-> priceDecimalsOptional.value,
         quantityDecimals                          |-> quantityDecimals.value,
         amountDecimals                            |-> amountDecimals.value,
         ratioDecimalsOptional                     |-> ratioDecimalsOptional.value,
         mainDepositary                            |-> mainDepositary.value,
         mic                                       |-> mic.value,
         countryOfExchange                         |-> countryOfExchange.value,
         productCode                               |-> productCode.value,
         underlyingMic                             |-> underlyingMic.value,
         underlyingIsinCode                        |-> underlyingIsinCode.value,
         underlyingExpiry                          |-> underlyingExpiry.value,
         orderTypeRules                            |-> orderTypeRules.value,
         settlementMethod                          |-> settlementMethod.value,
         tradingCurrency                           |-> tradingCurrency.value,
         strikePriceDecimalsRatio                  |-> strikePriceDecimalsRatio.value,
         mmProtections                             |-> mmProtections.value,
         contractTradingType                       |-> contractTradingType.value,
         instUnitExp                               |-> instUnitExp.value,
         underlyingSubtype                         |-> underlyingSubtype.value,
         motherStockIsin                           |-> motherStockIsin.value,
         settlementTickSize                        |-> settlementTickSize.value,
         edspTickSize                              |-> edspTickSize.value,
         underlyingSymbolIndex                     |-> underlyingSymbolIndex.value,
         tradingPolicy                             |-> tradingPolicy.value,
         referenceSpreadTableId                    |-> referenceSpreadTableId.value,
         derivativesMarketModel                    |-> derivativesMarketModel.value,
         tradingUnit                               |-> tradingUnit.value,
         referencePriceOriginInOpeningCall         |-> referencePriceOriginInOpeningCall.value,
         referencePriceOriginInContinuous          |-> referencePriceOriginInContinuous.value,
         referencePriceOriginInTradingInterruption |-> referencePriceOriginInTradingInterruption.value,
         collarExpansionFactor                     |-> collarExpansionFactor.value,
         mifidiiLiquidFlag                         |-> mifidiiLiquidFlag.value,
         pricingAlgorithm                          |-> pricingAlgorithm.value,
         contractEmmPropertiesGroups               |-> contractEmmPropertiesGroups.value ], contractEmmPropertiesGroups.rest)

ZeroContractStandingDataMessage ==
    [ mdSeqNum                                  |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator                      |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                               |-> [i \in 1 .. 4 |-> 0],
      optiqSegment                              |-> [i \in 1 .. 1 |-> 0],
      partitionId                               |-> [i \in 1 .. 2 |-> 0],
      contractEventDate                         |-> [i \in 1 .. 2 |-> 0],
      exchangeCode                              |-> [i \in 1 .. 1 |-> 0],
      exerStyle                                 |-> [i \in 1 .. 1 |-> 0],
      contractName                              |-> [i \in 1 .. 60 |-> 0],
      contractType                              |-> [i \in 1 .. 1 |-> 0],
      underlyingType                            |-> [i \in 1 .. 1 |-> 0],
      priceDecimalsOptional                     |-> [i \in 1 .. 1 |-> 0],
      quantityDecimals                          |-> [i \in 1 .. 1 |-> 0],
      amountDecimals                            |-> [i \in 1 .. 1 |-> 0],
      ratioDecimalsOptional                     |-> [i \in 1 .. 1 |-> 0],
      mainDepositary                            |-> [i \in 1 .. 5 |-> 0],
      mic                                       |-> [i \in 1 .. 4 |-> 0],
      countryOfExchange                         |-> [i \in 1 .. 3 |-> 0],
      productCode                               |-> [i \in 1 .. 4 |-> 0],
      underlyingMic                             |-> [i \in 1 .. 4 |-> 0],
      underlyingIsinCode                        |-> [i \in 1 .. 12 |-> 0],
      underlyingExpiry                          |-> [i \in 1 .. 4 |-> 0],
      orderTypeRules                            |-> [i \in 1 .. 2 |-> 0],
      settlementMethod                          |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                           |-> [i \in 1 .. 3 |-> 0],
      strikePriceDecimalsRatio                  |-> [i \in 1 .. 1 |-> 0],
      mmProtections                             |-> [i \in 1 .. 1 |-> 0],
      contractTradingType                       |-> [i \in 1 .. 1 |-> 0],
      instUnitExp                               |-> [i \in 1 .. 1 |-> 0],
      underlyingSubtype                         |-> [i \in 1 .. 1 |-> 0],
      motherStockIsin                           |-> [i \in 1 .. 12 |-> 0],
      settlementTickSize                        |-> [i \in 1 .. 8 |-> 0],
      edspTickSize                              |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbolIndex                     |-> [i \in 1 .. 4 |-> 0],
      tradingPolicy                             |-> [i \in 1 .. 1 |-> 0],
      referenceSpreadTableId                    |-> [i \in 1 .. 2 |-> 0],
      derivativesMarketModel                    |-> [i \in 1 .. 1 |-> 0],
      tradingUnit                               |-> [i \in 1 .. 8 |-> 0],
      referencePriceOriginInOpeningCall         |-> [i \in 1 .. 1 |-> 0],
      referencePriceOriginInContinuous          |-> [i \in 1 .. 1 |-> 0],
      referencePriceOriginInTradingInterruption |-> [i \in 1 .. 1 |-> 0],
      collarExpansionFactor                     |-> [i \in 1 .. 1 |-> 0],
      mifidiiLiquidFlag                         |-> [i \in 1 .. 1 |-> 0],
      pricingAlgorithm                          |-> [i \in 1 .. 1 |-> 0],
      contractEmmPropertiesGroups               |-> ZeroContractEmmPropertiesGroups ]

(* Contract Standing Data Message at zero, then each field in turn at the values it is checked at *)
CheckedContractStandingDataMessage ==
    { ZeroContractStandingDataMessage }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.optiqSegment = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.contractEventDate = one] : one \in Sample(2) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.exerStyle = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.contractName = one] : one \in Sample(60) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.underlyingType = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.priceDecimalsOptional = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.quantityDecimals = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.amountDecimals = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.ratioDecimalsOptional = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.mainDepositary = one] : one \in Sample(5) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.countryOfExchange = one] : one \in Sample(3) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.productCode = one] : one \in Sample(4) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.underlyingMic = one] : one \in Sample(4) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.underlyingIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.underlyingExpiry = one] : one \in Sample(4) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.orderTypeRules = one] : one \in Sample(2) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.settlementMethod = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.strikePriceDecimalsRatio = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.mmProtections = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.contractTradingType = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.instUnitExp = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.underlyingSubtype = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.motherStockIsin = one] : one \in Sample(12) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.settlementTickSize = one] : one \in Sample(8) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.edspTickSize = one] : one \in Sample(8) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.underlyingSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.tradingPolicy = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.referenceSpreadTableId = one] : one \in Sample(2) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.derivativesMarketModel = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.tradingUnit = one] : one \in Sample(8) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.referencePriceOriginInOpeningCall = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.referencePriceOriginInContinuous = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.referencePriceOriginInTradingInterruption = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.collarExpansionFactor = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.mifidiiLiquidFlag = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.pricingAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroContractStandingDataMessage EXCEPT !.contractEmmPropertiesGroups = one] : one \in CheckedContractEmmPropertiesGroups }

(***************************************************************************)
(* Outright Rep Group: 1 bytes                                             *)
(***************************************************************************)

OutrightRepGroup ==
    [ emm : Sample(1) ]

EncodeOutrightRepGroup(message) ==
    message.emm

DecodeOutrightRepGroup(bytes) ==
    LET emm == ReadBytes(bytes, 1) IN IF ~emm.ok THEN Fail ELSE
    Ok([ emm |-> emm.value ], emm.rest)

ZeroOutrightRepGroup ==
    [ emm |-> [i \in 1 .. 1 |-> 0] ]

(* Outright Rep Group at zero, then each field in turn at the values it is checked at *)
CheckedOutrightRepGroup ==
    { ZeroOutrightRepGroup }
        \cup { [ZeroOutrightRepGroup EXCEPT !.emm = one] : one \in Sample(1) }

(* A run of Outright Rep Group, written one after another *)
RECURSIVE EncodeOutrightRepGroupList(_)
EncodeOutrightRepGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOutrightRepGroup(Head(messages)) \o EncodeOutrightRepGroupList(Tail(messages))

(* As many Outright Rep Group as the field that counts them says *)
RECURSIVE ReadOutrightRepGroupList(_, _)
ReadOutrightRepGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOutrightRepGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOutrightRepGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Outright Rep Group of each kind, for the lists that carry them *)
OneOutrightRepGroup == { ZeroOutrightRepGroup }

(***************************************************************************)
(* Outright Rep Groups                                                     *)
(***************************************************************************)

OutrightRepGroups ==
    [ blockLengthShort : Sample(1),
      outrightRepGroup : SampleLists(OneOutrightRepGroup) ]

EncodeOutrightRepGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.outrightRepGroup), 1)
        \o EncodeOutrightRepGroupList(message.outrightRepGroup)

DecodeOutrightRepGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET outrightRepGroup == ReadOutrightRepGroupList(numInGroup.rest, numInGroup.value) IN IF ~outrightRepGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         outrightRepGroup |-> outrightRepGroup.value ], outrightRepGroup.rest)

ZeroOutrightRepGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      outrightRepGroup |-> << >> ]

(* Outright Rep Groups at zero, then each field in turn at the values it is checked at *)
CheckedOutrightRepGroups ==
    { ZeroOutrightRepGroups }
        \cup { [ZeroOutrightRepGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroOutrightRepGroups EXCEPT !.outrightRepGroup = one] : one \in SampleLists(OneOutrightRepGroup) }

(***************************************************************************)
(* Outright Standing Data Message                                          *)
(***************************************************************************)

OutrightStandingDataMessage ==
    [ mdSeqNum                                   : Sample(8),
      rebroadcastIndicator                       : Sample(1),
      symbolIndex                                : Sample(4),
      contractSymbolIndex                        : Sample(4),
      instrumentEventDate                        : Sample(2),
      isinCode                                   : Sample(12),
      cfiOptional                                : Sample(6),
      maturityDate                               : Sample(8),
      lotSize                                    : Sample(8),
      strikePrice                                : Sample(8),
      lastTradingDate                            : Sample(2),
      daysToExpiry                               : Sample(2),
      derivativesInstrumentTradingCodeOptional   : Sample(18),
      derivativesInstrumentType                  : Sample(1),
      expiryCycleType                            : Sample(1),
      underlyingDerivativesInstrumentTradingCode : Sample(18),
      underlyingSymbolIndex                      : Sample(4),
      tradingUnit                                : Sample(8),
      outrightRepGroups                          : OutrightRepGroups ]

EncodeOutrightStandingDataMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.symbolIndex
        \o message.contractSymbolIndex
        \o message.instrumentEventDate
        \o message.isinCode
        \o message.cfiOptional
        \o message.maturityDate
        \o message.lotSize
        \o message.strikePrice
        \o message.lastTradingDate
        \o message.daysToExpiry
        \o message.derivativesInstrumentTradingCodeOptional
        \o message.derivativesInstrumentType
        \o message.expiryCycleType
        \o message.underlyingDerivativesInstrumentTradingCode
        \o message.underlyingSymbolIndex
        \o message.tradingUnit
        \o EncodeOutrightRepGroups(message.outrightRepGroups)

DecodeOutrightStandingDataMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(rebroadcastIndicator.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET contractSymbolIndex == ReadBytes(symbolIndex.rest, 4) IN IF ~contractSymbolIndex.ok THEN Fail ELSE
    LET instrumentEventDate == ReadBytes(contractSymbolIndex.rest, 2) IN IF ~instrumentEventDate.ok THEN Fail ELSE
    LET isinCode == ReadBytes(instrumentEventDate.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET cfiOptional == ReadBytes(isinCode.rest, 6) IN IF ~cfiOptional.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(cfiOptional.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET lotSize == ReadBytes(maturityDate.rest, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(lotSize.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(strikePrice.rest, 2) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET daysToExpiry == ReadBytes(lastTradingDate.rest, 2) IN IF ~daysToExpiry.ok THEN Fail ELSE
    LET derivativesInstrumentTradingCodeOptional == ReadBytes(daysToExpiry.rest, 18) IN IF ~derivativesInstrumentTradingCodeOptional.ok THEN Fail ELSE
    LET derivativesInstrumentType == ReadBytes(derivativesInstrumentTradingCodeOptional.rest, 1) IN IF ~derivativesInstrumentType.ok THEN Fail ELSE
    LET expiryCycleType == ReadBytes(derivativesInstrumentType.rest, 1) IN IF ~expiryCycleType.ok THEN Fail ELSE
    LET underlyingDerivativesInstrumentTradingCode == ReadBytes(expiryCycleType.rest, 18) IN IF ~underlyingDerivativesInstrumentTradingCode.ok THEN Fail ELSE
    LET underlyingSymbolIndex == ReadBytes(underlyingDerivativesInstrumentTradingCode.rest, 4) IN IF ~underlyingSymbolIndex.ok THEN Fail ELSE
    LET tradingUnit == ReadBytes(underlyingSymbolIndex.rest, 8) IN IF ~tradingUnit.ok THEN Fail ELSE
    LET outrightRepGroups == DecodeOutrightRepGroups(tradingUnit.rest) IN IF ~outrightRepGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum                                   |-> mdSeqNum.value,
         rebroadcastIndicator                       |-> rebroadcastIndicator.value,
         symbolIndex                                |-> symbolIndex.value,
         contractSymbolIndex                        |-> contractSymbolIndex.value,
         instrumentEventDate                        |-> instrumentEventDate.value,
         isinCode                                   |-> isinCode.value,
         cfiOptional                                |-> cfiOptional.value,
         maturityDate                               |-> maturityDate.value,
         lotSize                                    |-> lotSize.value,
         strikePrice                                |-> strikePrice.value,
         lastTradingDate                            |-> lastTradingDate.value,
         daysToExpiry                               |-> daysToExpiry.value,
         derivativesInstrumentTradingCodeOptional   |-> derivativesInstrumentTradingCodeOptional.value,
         derivativesInstrumentType                  |-> derivativesInstrumentType.value,
         expiryCycleType                            |-> expiryCycleType.value,
         underlyingDerivativesInstrumentTradingCode |-> underlyingDerivativesInstrumentTradingCode.value,
         underlyingSymbolIndex                      |-> underlyingSymbolIndex.value,
         tradingUnit                                |-> tradingUnit.value,
         outrightRepGroups                          |-> outrightRepGroups.value ], outrightRepGroups.rest)

ZeroOutrightStandingDataMessage ==
    [ mdSeqNum                                   |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator                       |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                                |-> [i \in 1 .. 4 |-> 0],
      contractSymbolIndex                        |-> [i \in 1 .. 4 |-> 0],
      instrumentEventDate                        |-> [i \in 1 .. 2 |-> 0],
      isinCode                                   |-> [i \in 1 .. 12 |-> 0],
      cfiOptional                                |-> [i \in 1 .. 6 |-> 0],
      maturityDate                               |-> [i \in 1 .. 8 |-> 0],
      lotSize                                    |-> [i \in 1 .. 8 |-> 0],
      strikePrice                                |-> [i \in 1 .. 8 |-> 0],
      lastTradingDate                            |-> [i \in 1 .. 2 |-> 0],
      daysToExpiry                               |-> [i \in 1 .. 2 |-> 0],
      derivativesInstrumentTradingCodeOptional   |-> [i \in 1 .. 18 |-> 0],
      derivativesInstrumentType                  |-> [i \in 1 .. 1 |-> 0],
      expiryCycleType                            |-> [i \in 1 .. 1 |-> 0],
      underlyingDerivativesInstrumentTradingCode |-> [i \in 1 .. 18 |-> 0],
      underlyingSymbolIndex                      |-> [i \in 1 .. 4 |-> 0],
      tradingUnit                                |-> [i \in 1 .. 8 |-> 0],
      outrightRepGroups                          |-> ZeroOutrightRepGroups ]

(* Outright Standing Data Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightStandingDataMessage ==
    { ZeroOutrightStandingDataMessage }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.contractSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.instrumentEventDate = one] : one \in Sample(2) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.cfiOptional = one] : one \in Sample(6) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.lastTradingDate = one] : one \in Sample(2) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.daysToExpiry = one] : one \in Sample(2) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.derivativesInstrumentTradingCodeOptional = one] : one \in Sample(18) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.derivativesInstrumentType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.expiryCycleType = one] : one \in Sample(1) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.underlyingDerivativesInstrumentTradingCode = one] : one \in Sample(18) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.underlyingSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.tradingUnit = one] : one \in Sample(8) }
        \cup { [ZeroOutrightStandingDataMessage EXCEPT !.outrightRepGroups = one] : one \in CheckedOutrightRepGroups }

(***************************************************************************)
(* Package Components Group: 8 bytes                                       *)
(***************************************************************************)

PackageComponentsGroup ==
    [ legSymbolIndex : Sample(4),
      legRatio       : Sample(4) ]

EncodePackageComponentsGroup(message) ==
    message.legSymbolIndex
        \o message.legRatio

DecodePackageComponentsGroup(bytes) ==
    LET legSymbolIndex == ReadBytes(bytes, 4) IN IF ~legSymbolIndex.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSymbolIndex.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legSymbolIndex |-> legSymbolIndex.value,
         legRatio       |-> legRatio.value ], legRatio.rest)

ZeroPackageComponentsGroup ==
    [ legSymbolIndex |-> [i \in 1 .. 4 |-> 0],
      legRatio       |-> [i \in 1 .. 4 |-> 0] ]

(* Package Components Group at zero, then each field in turn at the values it is checked at *)
CheckedPackageComponentsGroup ==
    { ZeroPackageComponentsGroup }
        \cup { [ZeroPackageComponentsGroup EXCEPT !.legSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroPackageComponentsGroup EXCEPT !.legRatio = one] : one \in Sample(4) }

(* A run of Package Components Group, written one after another *)
RECURSIVE EncodePackageComponentsGroupList(_)
EncodePackageComponentsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePackageComponentsGroup(Head(messages)) \o EncodePackageComponentsGroupList(Tail(messages))

(* As many Package Components Group as the field that counts them says *)
RECURSIVE ReadPackageComponentsGroupList(_, _)
ReadPackageComponentsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePackageComponentsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPackageComponentsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Package Components Group of each kind, for the lists that carry them *)
OnePackageComponentsGroup == { ZeroPackageComponentsGroup }

(***************************************************************************)
(* Package Components Groups                                               *)
(***************************************************************************)

PackageComponentsGroups ==
    [ blockLengthShort       : Sample(1),
      packageComponentsGroup : SampleLists(OnePackageComponentsGroup) ]

EncodePackageComponentsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.packageComponentsGroup), 1)
        \o EncodePackageComponentsGroupList(message.packageComponentsGroup)

DecodePackageComponentsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET packageComponentsGroup == ReadPackageComponentsGroupList(numInGroup.rest, numInGroup.value) IN IF ~packageComponentsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort       |-> blockLengthShort.value,
         packageComponentsGroup |-> packageComponentsGroup.value ], packageComponentsGroup.rest)

ZeroPackageComponentsGroups ==
    [ blockLengthShort       |-> [i \in 1 .. 1 |-> 0],
      packageComponentsGroup |-> << >> ]

(* Package Components Groups at zero, then each field in turn at the values it is checked at *)
CheckedPackageComponentsGroups ==
    { ZeroPackageComponentsGroups }
        \cup { [ZeroPackageComponentsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroPackageComponentsGroups EXCEPT !.packageComponentsGroup = one] : one \in SampleLists(OnePackageComponentsGroup) }

(***************************************************************************)
(* Lis Package Structure Message                                           *)
(***************************************************************************)

LisPackageStructureMessage ==
    [ mdSeqNum                : Sample(8),
      rebroadcastIndicator    : Sample(1),
      emm                     : Sample(1),
      eventTime               : Sample(8),
      contractSymbolIndex     : Sample(4),
      mifidExecutionId        : Sample(52),
      strategyCode            : Sample(1),
      packageComponentsGroups : PackageComponentsGroups ]

EncodeLisPackageStructureMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.eventTime
        \o message.contractSymbolIndex
        \o message.mifidExecutionId
        \o message.strategyCode
        \o EncodePackageComponentsGroups(message.packageComponentsGroups)

DecodeLisPackageStructureMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventTime == ReadBytes(emm.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET contractSymbolIndex == ReadBytes(eventTime.rest, 4) IN IF ~contractSymbolIndex.ok THEN Fail ELSE
    LET mifidExecutionId == ReadBytes(contractSymbolIndex.rest, 52) IN IF ~mifidExecutionId.ok THEN Fail ELSE
    LET strategyCode == ReadBytes(mifidExecutionId.rest, 1) IN IF ~strategyCode.ok THEN Fail ELSE
    LET packageComponentsGroups == DecodePackageComponentsGroups(strategyCode.rest) IN IF ~packageComponentsGroups.ok THEN Fail ELSE
    Ok([ mdSeqNum                |-> mdSeqNum.value,
         rebroadcastIndicator    |-> rebroadcastIndicator.value,
         emm                     |-> emm.value,
         eventTime               |-> eventTime.value,
         contractSymbolIndex     |-> contractSymbolIndex.value,
         mifidExecutionId        |-> mifidExecutionId.value,
         strategyCode            |-> strategyCode.value,
         packageComponentsGroups |-> packageComponentsGroups.value ], packageComponentsGroups.rest)

ZeroLisPackageStructureMessage ==
    [ mdSeqNum                |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator    |-> [i \in 1 .. 1 |-> 0],
      emm                     |-> [i \in 1 .. 1 |-> 0],
      eventTime               |-> [i \in 1 .. 8 |-> 0],
      contractSymbolIndex     |-> [i \in 1 .. 4 |-> 0],
      mifidExecutionId        |-> [i \in 1 .. 52 |-> 0],
      strategyCode            |-> [i \in 1 .. 1 |-> 0],
      packageComponentsGroups |-> ZeroPackageComponentsGroups ]

(* Lis Package Structure Message at zero, then each field in turn at the values it is checked at *)
CheckedLisPackageStructureMessage ==
    { ZeroLisPackageStructureMessage }
        \cup { [ZeroLisPackageStructureMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroLisPackageStructureMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLisPackageStructureMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroLisPackageStructureMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroLisPackageStructureMessage EXCEPT !.contractSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroLisPackageStructureMessage EXCEPT !.mifidExecutionId = one] : one \in Sample(52) }
        \cup { [ZeroLisPackageStructureMessage EXCEPT !.strategyCode = one] : one \in Sample(1) }
        \cup { [ZeroLisPackageStructureMessage EXCEPT !.packageComponentsGroups = one] : one \in CheckedPackageComponentsGroups }

(***************************************************************************)
(* Apa Quotes Message: 101 bytes                                           *)
(***************************************************************************)

ApaQuotesMessage ==
    [ mdSeqNumOptional      : Sample(8),
      rebroadcastIndicator  : Sample(1),
      mifidInstrumentIdType : Sample(4),
      mifidInstrumentId     : Sample(12),
      mic                   : Sample(4),
      currency              : Sample(3),
      leiCode               : Sample(20),
      eventTime             : Sample(8),
      quoteUpdateType       : Sample(1),
      mifidPrice            : Sample(20),
      mifidQuantity         : Sample(20) ]

EncodeApaQuotesMessage(message) ==
    message.mdSeqNumOptional
        \o message.rebroadcastIndicator
        \o message.mifidInstrumentIdType
        \o message.mifidInstrumentId
        \o message.mic
        \o message.currency
        \o message.leiCode
        \o message.eventTime
        \o message.quoteUpdateType
        \o message.mifidPrice
        \o message.mifidQuantity

DecodeApaQuotesMessage(bytes) ==
    LET mdSeqNumOptional == ReadBytes(bytes, 8) IN IF ~mdSeqNumOptional.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNumOptional.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET mifidInstrumentIdType == ReadBytes(rebroadcastIndicator.rest, 4) IN IF ~mifidInstrumentIdType.ok THEN Fail ELSE
    LET mifidInstrumentId == ReadBytes(mifidInstrumentIdType.rest, 12) IN IF ~mifidInstrumentId.ok THEN Fail ELSE
    LET mic == ReadBytes(mifidInstrumentId.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET currency == ReadBytes(mic.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET leiCode == ReadBytes(currency.rest, 20) IN IF ~leiCode.ok THEN Fail ELSE
    LET eventTime == ReadBytes(leiCode.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET quoteUpdateType == ReadBytes(eventTime.rest, 1) IN IF ~quoteUpdateType.ok THEN Fail ELSE
    LET mifidPrice == ReadBytes(quoteUpdateType.rest, 20) IN IF ~mifidPrice.ok THEN Fail ELSE
    LET mifidQuantity == ReadBytes(mifidPrice.rest, 20) IN IF ~mifidQuantity.ok THEN Fail ELSE
    Ok([ mdSeqNumOptional      |-> mdSeqNumOptional.value,
         rebroadcastIndicator  |-> rebroadcastIndicator.value,
         mifidInstrumentIdType |-> mifidInstrumentIdType.value,
         mifidInstrumentId     |-> mifidInstrumentId.value,
         mic                   |-> mic.value,
         currency              |-> currency.value,
         leiCode               |-> leiCode.value,
         eventTime             |-> eventTime.value,
         quoteUpdateType       |-> quoteUpdateType.value,
         mifidPrice            |-> mifidPrice.value,
         mifidQuantity         |-> mifidQuantity.value ], mifidQuantity.rest)

ZeroApaQuotesMessage ==
    [ mdSeqNumOptional      |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator  |-> [i \in 1 .. 1 |-> 0],
      mifidInstrumentIdType |-> [i \in 1 .. 4 |-> 0],
      mifidInstrumentId     |-> [i \in 1 .. 12 |-> 0],
      mic                   |-> [i \in 1 .. 4 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      leiCode               |-> [i \in 1 .. 20 |-> 0],
      eventTime             |-> [i \in 1 .. 8 |-> 0],
      quoteUpdateType       |-> [i \in 1 .. 1 |-> 0],
      mifidPrice            |-> [i \in 1 .. 20 |-> 0],
      mifidQuantity         |-> [i \in 1 .. 20 |-> 0] ]

(* Apa Quotes Message at zero, then each field in turn at the values it is checked at *)
CheckedApaQuotesMessage ==
    { ZeroApaQuotesMessage }
        \cup { [ZeroApaQuotesMessage EXCEPT !.mdSeqNumOptional = one] : one \in Sample(8) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.mifidInstrumentIdType = one] : one \in Sample(4) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.mifidInstrumentId = one] : one \in Sample(12) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.leiCode = one] : one \in Sample(20) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.quoteUpdateType = one] : one \in Sample(1) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.mifidPrice = one] : one \in Sample(20) }
        \cup { [ZeroApaQuotesMessage EXCEPT !.mifidQuantity = one] : one \in Sample(20) }

(***************************************************************************)
(* Apa Standing Data Message: 217 bytes                                    *)
(***************************************************************************)

ApaStandingDataMessage ==
    [ mdSeqNumOptional        : Sample(8),
      rebroadcastIndicator    : Sample(1),
      mifidInstrumentIdType   : Sample(4),
      mifidInstrumentId       : Sample(12),
      fullInstrumentName      : Sample(102),
      cfiOptional             : Sample(6),
      notionalCurrency        : Sample(3),
      secondNotionalCurrency  : Sample(3),
      priceMultiplier         : Sample(4),
      priceMultiplierDecimals : Sample(1),
      underlyingIsinCode      : Sample(12),
      underlyingIndexName     : Sample(25),
      underlyingIndexTerm     : Sample(8),
      optionType              : Sample(1),
      strikePrice             : Sample(8),
      strikePriceDecimals     : Sample(1),
      exerStyle               : Sample(1),
      maturityDateOptional    : Sample(8),
      expiryDate              : Sample(8),
      settlementMethod        : Sample(1) ]

EncodeApaStandingDataMessage(message) ==
    message.mdSeqNumOptional
        \o message.rebroadcastIndicator
        \o message.mifidInstrumentIdType
        \o message.mifidInstrumentId
        \o message.fullInstrumentName
        \o message.cfiOptional
        \o message.notionalCurrency
        \o message.secondNotionalCurrency
        \o message.priceMultiplier
        \o message.priceMultiplierDecimals
        \o message.underlyingIsinCode
        \o message.underlyingIndexName
        \o message.underlyingIndexTerm
        \o message.optionType
        \o message.strikePrice
        \o message.strikePriceDecimals
        \o message.exerStyle
        \o message.maturityDateOptional
        \o message.expiryDate
        \o message.settlementMethod

DecodeApaStandingDataMessage(bytes) ==
    LET mdSeqNumOptional == ReadBytes(bytes, 8) IN IF ~mdSeqNumOptional.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNumOptional.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET mifidInstrumentIdType == ReadBytes(rebroadcastIndicator.rest, 4) IN IF ~mifidInstrumentIdType.ok THEN Fail ELSE
    LET mifidInstrumentId == ReadBytes(mifidInstrumentIdType.rest, 12) IN IF ~mifidInstrumentId.ok THEN Fail ELSE
    LET fullInstrumentName == ReadBytes(mifidInstrumentId.rest, 102) IN IF ~fullInstrumentName.ok THEN Fail ELSE
    LET cfiOptional == ReadBytes(fullInstrumentName.rest, 6) IN IF ~cfiOptional.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(cfiOptional.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET secondNotionalCurrency == ReadBytes(notionalCurrency.rest, 3) IN IF ~secondNotionalCurrency.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(secondNotionalCurrency.rest, 4) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET priceMultiplierDecimals == ReadBytes(priceMultiplier.rest, 1) IN IF ~priceMultiplierDecimals.ok THEN Fail ELSE
    LET underlyingIsinCode == ReadBytes(priceMultiplierDecimals.rest, 12) IN IF ~underlyingIsinCode.ok THEN Fail ELSE
    LET underlyingIndexName == ReadBytes(underlyingIsinCode.rest, 25) IN IF ~underlyingIndexName.ok THEN Fail ELSE
    LET underlyingIndexTerm == ReadBytes(underlyingIndexName.rest, 8) IN IF ~underlyingIndexTerm.ok THEN Fail ELSE
    LET optionType == ReadBytes(underlyingIndexTerm.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(optionType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceDecimals == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceDecimals.ok THEN Fail ELSE
    LET exerStyle == ReadBytes(strikePriceDecimals.rest, 1) IN IF ~exerStyle.ok THEN Fail ELSE
    LET maturityDateOptional == ReadBytes(exerStyle.rest, 8) IN IF ~maturityDateOptional.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(maturityDateOptional.rest, 8) IN IF ~expiryDate.ok THEN Fail ELSE
    LET settlementMethod == ReadBytes(expiryDate.rest, 1) IN IF ~settlementMethod.ok THEN Fail ELSE
    Ok([ mdSeqNumOptional        |-> mdSeqNumOptional.value,
         rebroadcastIndicator    |-> rebroadcastIndicator.value,
         mifidInstrumentIdType   |-> mifidInstrumentIdType.value,
         mifidInstrumentId       |-> mifidInstrumentId.value,
         fullInstrumentName      |-> fullInstrumentName.value,
         cfiOptional             |-> cfiOptional.value,
         notionalCurrency        |-> notionalCurrency.value,
         secondNotionalCurrency  |-> secondNotionalCurrency.value,
         priceMultiplier         |-> priceMultiplier.value,
         priceMultiplierDecimals |-> priceMultiplierDecimals.value,
         underlyingIsinCode      |-> underlyingIsinCode.value,
         underlyingIndexName     |-> underlyingIndexName.value,
         underlyingIndexTerm     |-> underlyingIndexTerm.value,
         optionType              |-> optionType.value,
         strikePrice             |-> strikePrice.value,
         strikePriceDecimals     |-> strikePriceDecimals.value,
         exerStyle               |-> exerStyle.value,
         maturityDateOptional    |-> maturityDateOptional.value,
         expiryDate              |-> expiryDate.value,
         settlementMethod        |-> settlementMethod.value ], settlementMethod.rest)

ZeroApaStandingDataMessage ==
    [ mdSeqNumOptional        |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator    |-> [i \in 1 .. 1 |-> 0],
      mifidInstrumentIdType   |-> [i \in 1 .. 4 |-> 0],
      mifidInstrumentId       |-> [i \in 1 .. 12 |-> 0],
      fullInstrumentName      |-> [i \in 1 .. 102 |-> 0],
      cfiOptional             |-> [i \in 1 .. 6 |-> 0],
      notionalCurrency        |-> [i \in 1 .. 3 |-> 0],
      secondNotionalCurrency  |-> [i \in 1 .. 3 |-> 0],
      priceMultiplier         |-> [i \in 1 .. 4 |-> 0],
      priceMultiplierDecimals |-> [i \in 1 .. 1 |-> 0],
      underlyingIsinCode      |-> [i \in 1 .. 12 |-> 0],
      underlyingIndexName     |-> [i \in 1 .. 25 |-> 0],
      underlyingIndexTerm     |-> [i \in 1 .. 8 |-> 0],
      optionType              |-> [i \in 1 .. 1 |-> 0],
      strikePrice             |-> [i \in 1 .. 8 |-> 0],
      strikePriceDecimals     |-> [i \in 1 .. 1 |-> 0],
      exerStyle               |-> [i \in 1 .. 1 |-> 0],
      maturityDateOptional    |-> [i \in 1 .. 8 |-> 0],
      expiryDate              |-> [i \in 1 .. 8 |-> 0],
      settlementMethod        |-> [i \in 1 .. 1 |-> 0] ]

(* Apa Standing Data Message at zero, then each field in turn at the values it is checked at *)
CheckedApaStandingDataMessage ==
    { ZeroApaStandingDataMessage }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.mdSeqNumOptional = one] : one \in Sample(8) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.mifidInstrumentIdType = one] : one \in Sample(4) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.mifidInstrumentId = one] : one \in Sample(12) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.fullInstrumentName = one] : one \in Sample(102) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.cfiOptional = one] : one \in Sample(6) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.secondNotionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.priceMultiplier = one] : one \in Sample(4) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.priceMultiplierDecimals = one] : one \in Sample(1) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.underlyingIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.underlyingIndexName = one] : one \in Sample(25) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.underlyingIndexTerm = one] : one \in Sample(8) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.strikePriceDecimals = one] : one \in Sample(1) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.exerStyle = one] : one \in Sample(1) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.maturityDateOptional = one] : one \in Sample(8) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.expiryDate = one] : one \in Sample(8) }
        \cup { [ZeroApaStandingDataMessage EXCEPT !.settlementMethod = one] : one \in Sample(1) }

(***************************************************************************)
(* Apa Full Trade Information Message: 333 bytes                           *)
(***************************************************************************)

ApaFullTradeInformationMessage ==
    [ mdSeqNum                              : Sample(8),
      rebroadcastIndicator                  : Sample(1),
      emm                                   : Sample(1),
      eventTime                             : Sample(8),
      tradingDateTime                       : Sample(27),
      publicationDateTime                   : Sample(27),
      tradeType                             : Sample(1),
      mifidInstrumentIdTypeOptional         : Sample(4),
      mifidInstrumentIdOptional             : Sample(12),
      mifidTransactionId                    : Sample(52),
      mifidPriceOptional                    : Sample(20),
      mifidQuantity                         : Sample(20),
      mifidPriceNotation                    : Sample(4),
      mifidCurrency                         : Sample(3),
      mifidQtyInMsrmtUnitNotation           : Sample(25),
      mifidQuantityMeasurementUnit          : Sample(20),
      mifidNotionalAmount                   : Sample(20),
      notionalCurrency                      : Sample(3),
      mifidClearingFlag                     : Sample(5),
      efficientMmtMarketMechanism           : Sample(1),
      efficientMmtTradingMode               : Sample(1),
      efficientMmtTransactionCategory       : Sample(1),
      efficientMmtNegotiationIndicator      : Sample(1),
      efficientMmtAgencyCrossTradeIndicator : Sample(1),
      efficientMmtModificationIndicator     : Sample(1),
      efficientMmtBenchmarkIndicator        : Sample(1),
      efficientMmtSpecialDividendIndicator  : Sample(1),
      efficientMmtOffBookAutomatedIndicator : Sample(1),
      efficientMmtContributiontoPrice       : Sample(1),
      efficientMmtAlgorithmicIndicator      : Sample(1),
      efficientMmtPublicationMode           : Sample(1),
      efficientMmtPostTradeDeferral         : Sample(1),
      efficientMmtDuplicativeIndicator      : Sample(1),
      tradeReference                        : Sample(30),
      originalReportTimestamp               : Sample(8),
      priceMultiplier                       : Sample(4),
      priceMultiplierDecimals               : Sample(1),
      venue                                 : Sample(11),
      mifidEmissionAllowanceType            : Sample(4) ]

EncodeApaFullTradeInformationMessage(message) ==
    message.mdSeqNum
        \o message.rebroadcastIndicator
        \o message.emm
        \o message.eventTime
        \o message.tradingDateTime
        \o message.publicationDateTime
        \o message.tradeType
        \o message.mifidInstrumentIdTypeOptional
        \o message.mifidInstrumentIdOptional
        \o message.mifidTransactionId
        \o message.mifidPriceOptional
        \o message.mifidQuantity
        \o message.mifidPriceNotation
        \o message.mifidCurrency
        \o message.mifidQtyInMsrmtUnitNotation
        \o message.mifidQuantityMeasurementUnit
        \o message.mifidNotionalAmount
        \o message.notionalCurrency
        \o message.mifidClearingFlag
        \o message.efficientMmtMarketMechanism
        \o message.efficientMmtTradingMode
        \o message.efficientMmtTransactionCategory
        \o message.efficientMmtNegotiationIndicator
        \o message.efficientMmtAgencyCrossTradeIndicator
        \o message.efficientMmtModificationIndicator
        \o message.efficientMmtBenchmarkIndicator
        \o message.efficientMmtSpecialDividendIndicator
        \o message.efficientMmtOffBookAutomatedIndicator
        \o message.efficientMmtContributiontoPrice
        \o message.efficientMmtAlgorithmicIndicator
        \o message.efficientMmtPublicationMode
        \o message.efficientMmtPostTradeDeferral
        \o message.efficientMmtDuplicativeIndicator
        \o message.tradeReference
        \o message.originalReportTimestamp
        \o message.priceMultiplier
        \o message.priceMultiplierDecimals
        \o message.venue
        \o message.mifidEmissionAllowanceType

DecodeApaFullTradeInformationMessage(bytes) ==
    LET mdSeqNum == ReadBytes(bytes, 8) IN IF ~mdSeqNum.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(mdSeqNum.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET emm == ReadBytes(rebroadcastIndicator.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventTime == ReadBytes(emm.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET tradingDateTime == ReadBytes(eventTime.rest, 27) IN IF ~tradingDateTime.ok THEN Fail ELSE
    LET publicationDateTime == ReadBytes(tradingDateTime.rest, 27) IN IF ~publicationDateTime.ok THEN Fail ELSE
    LET tradeType == ReadBytes(publicationDateTime.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET mifidInstrumentIdTypeOptional == ReadBytes(tradeType.rest, 4) IN IF ~mifidInstrumentIdTypeOptional.ok THEN Fail ELSE
    LET mifidInstrumentIdOptional == ReadBytes(mifidInstrumentIdTypeOptional.rest, 12) IN IF ~mifidInstrumentIdOptional.ok THEN Fail ELSE
    LET mifidTransactionId == ReadBytes(mifidInstrumentIdOptional.rest, 52) IN IF ~mifidTransactionId.ok THEN Fail ELSE
    LET mifidPriceOptional == ReadBytes(mifidTransactionId.rest, 20) IN IF ~mifidPriceOptional.ok THEN Fail ELSE
    LET mifidQuantity == ReadBytes(mifidPriceOptional.rest, 20) IN IF ~mifidQuantity.ok THEN Fail ELSE
    LET mifidPriceNotation == ReadBytes(mifidQuantity.rest, 4) IN IF ~mifidPriceNotation.ok THEN Fail ELSE
    LET mifidCurrency == ReadBytes(mifidPriceNotation.rest, 3) IN IF ~mifidCurrency.ok THEN Fail ELSE
    LET mifidQtyInMsrmtUnitNotation == ReadBytes(mifidCurrency.rest, 25) IN IF ~mifidQtyInMsrmtUnitNotation.ok THEN Fail ELSE
    LET mifidQuantityMeasurementUnit == ReadBytes(mifidQtyInMsrmtUnitNotation.rest, 20) IN IF ~mifidQuantityMeasurementUnit.ok THEN Fail ELSE
    LET mifidNotionalAmount == ReadBytes(mifidQuantityMeasurementUnit.rest, 20) IN IF ~mifidNotionalAmount.ok THEN Fail ELSE
    LET notionalCurrency == ReadBytes(mifidNotionalAmount.rest, 3) IN IF ~notionalCurrency.ok THEN Fail ELSE
    LET mifidClearingFlag == ReadBytes(notionalCurrency.rest, 5) IN IF ~mifidClearingFlag.ok THEN Fail ELSE
    LET efficientMmtMarketMechanism == ReadBytes(mifidClearingFlag.rest, 1) IN IF ~efficientMmtMarketMechanism.ok THEN Fail ELSE
    LET efficientMmtTradingMode == ReadBytes(efficientMmtMarketMechanism.rest, 1) IN IF ~efficientMmtTradingMode.ok THEN Fail ELSE
    LET efficientMmtTransactionCategory == ReadBytes(efficientMmtTradingMode.rest, 1) IN IF ~efficientMmtTransactionCategory.ok THEN Fail ELSE
    LET efficientMmtNegotiationIndicator == ReadBytes(efficientMmtTransactionCategory.rest, 1) IN IF ~efficientMmtNegotiationIndicator.ok THEN Fail ELSE
    LET efficientMmtAgencyCrossTradeIndicator == ReadBytes(efficientMmtNegotiationIndicator.rest, 1) IN IF ~efficientMmtAgencyCrossTradeIndicator.ok THEN Fail ELSE
    LET efficientMmtModificationIndicator == ReadBytes(efficientMmtAgencyCrossTradeIndicator.rest, 1) IN IF ~efficientMmtModificationIndicator.ok THEN Fail ELSE
    LET efficientMmtBenchmarkIndicator == ReadBytes(efficientMmtModificationIndicator.rest, 1) IN IF ~efficientMmtBenchmarkIndicator.ok THEN Fail ELSE
    LET efficientMmtSpecialDividendIndicator == ReadBytes(efficientMmtBenchmarkIndicator.rest, 1) IN IF ~efficientMmtSpecialDividendIndicator.ok THEN Fail ELSE
    LET efficientMmtOffBookAutomatedIndicator == ReadBytes(efficientMmtSpecialDividendIndicator.rest, 1) IN IF ~efficientMmtOffBookAutomatedIndicator.ok THEN Fail ELSE
    LET efficientMmtContributiontoPrice == ReadBytes(efficientMmtOffBookAutomatedIndicator.rest, 1) IN IF ~efficientMmtContributiontoPrice.ok THEN Fail ELSE
    LET efficientMmtAlgorithmicIndicator == ReadBytes(efficientMmtContributiontoPrice.rest, 1) IN IF ~efficientMmtAlgorithmicIndicator.ok THEN Fail ELSE
    LET efficientMmtPublicationMode == ReadBytes(efficientMmtAlgorithmicIndicator.rest, 1) IN IF ~efficientMmtPublicationMode.ok THEN Fail ELSE
    LET efficientMmtPostTradeDeferral == ReadBytes(efficientMmtPublicationMode.rest, 1) IN IF ~efficientMmtPostTradeDeferral.ok THEN Fail ELSE
    LET efficientMmtDuplicativeIndicator == ReadBytes(efficientMmtPostTradeDeferral.rest, 1) IN IF ~efficientMmtDuplicativeIndicator.ok THEN Fail ELSE
    LET tradeReference == ReadBytes(efficientMmtDuplicativeIndicator.rest, 30) IN IF ~tradeReference.ok THEN Fail ELSE
    LET originalReportTimestamp == ReadBytes(tradeReference.rest, 8) IN IF ~originalReportTimestamp.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(originalReportTimestamp.rest, 4) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET priceMultiplierDecimals == ReadBytes(priceMultiplier.rest, 1) IN IF ~priceMultiplierDecimals.ok THEN Fail ELSE
    LET venue == ReadBytes(priceMultiplierDecimals.rest, 11) IN IF ~venue.ok THEN Fail ELSE
    LET mifidEmissionAllowanceType == ReadBytes(venue.rest, 4) IN IF ~mifidEmissionAllowanceType.ok THEN Fail ELSE
    Ok([ mdSeqNum                              |-> mdSeqNum.value,
         rebroadcastIndicator                  |-> rebroadcastIndicator.value,
         emm                                   |-> emm.value,
         eventTime                             |-> eventTime.value,
         tradingDateTime                       |-> tradingDateTime.value,
         publicationDateTime                   |-> publicationDateTime.value,
         tradeType                             |-> tradeType.value,
         mifidInstrumentIdTypeOptional         |-> mifidInstrumentIdTypeOptional.value,
         mifidInstrumentIdOptional             |-> mifidInstrumentIdOptional.value,
         mifidTransactionId                    |-> mifidTransactionId.value,
         mifidPriceOptional                    |-> mifidPriceOptional.value,
         mifidQuantity                         |-> mifidQuantity.value,
         mifidPriceNotation                    |-> mifidPriceNotation.value,
         mifidCurrency                         |-> mifidCurrency.value,
         mifidQtyInMsrmtUnitNotation           |-> mifidQtyInMsrmtUnitNotation.value,
         mifidQuantityMeasurementUnit          |-> mifidQuantityMeasurementUnit.value,
         mifidNotionalAmount                   |-> mifidNotionalAmount.value,
         notionalCurrency                      |-> notionalCurrency.value,
         mifidClearingFlag                     |-> mifidClearingFlag.value,
         efficientMmtMarketMechanism           |-> efficientMmtMarketMechanism.value,
         efficientMmtTradingMode               |-> efficientMmtTradingMode.value,
         efficientMmtTransactionCategory       |-> efficientMmtTransactionCategory.value,
         efficientMmtNegotiationIndicator      |-> efficientMmtNegotiationIndicator.value,
         efficientMmtAgencyCrossTradeIndicator |-> efficientMmtAgencyCrossTradeIndicator.value,
         efficientMmtModificationIndicator     |-> efficientMmtModificationIndicator.value,
         efficientMmtBenchmarkIndicator        |-> efficientMmtBenchmarkIndicator.value,
         efficientMmtSpecialDividendIndicator  |-> efficientMmtSpecialDividendIndicator.value,
         efficientMmtOffBookAutomatedIndicator |-> efficientMmtOffBookAutomatedIndicator.value,
         efficientMmtContributiontoPrice       |-> efficientMmtContributiontoPrice.value,
         efficientMmtAlgorithmicIndicator      |-> efficientMmtAlgorithmicIndicator.value,
         efficientMmtPublicationMode           |-> efficientMmtPublicationMode.value,
         efficientMmtPostTradeDeferral         |-> efficientMmtPostTradeDeferral.value,
         efficientMmtDuplicativeIndicator      |-> efficientMmtDuplicativeIndicator.value,
         tradeReference                        |-> tradeReference.value,
         originalReportTimestamp               |-> originalReportTimestamp.value,
         priceMultiplier                       |-> priceMultiplier.value,
         priceMultiplierDecimals               |-> priceMultiplierDecimals.value,
         venue                                 |-> venue.value,
         mifidEmissionAllowanceType            |-> mifidEmissionAllowanceType.value ], mifidEmissionAllowanceType.rest)

ZeroApaFullTradeInformationMessage ==
    [ mdSeqNum                              |-> [i \in 1 .. 8 |-> 0],
      rebroadcastIndicator                  |-> [i \in 1 .. 1 |-> 0],
      emm                                   |-> [i \in 1 .. 1 |-> 0],
      eventTime                             |-> [i \in 1 .. 8 |-> 0],
      tradingDateTime                       |-> [i \in 1 .. 27 |-> 0],
      publicationDateTime                   |-> [i \in 1 .. 27 |-> 0],
      tradeType                             |-> [i \in 1 .. 1 |-> 0],
      mifidInstrumentIdTypeOptional         |-> [i \in 1 .. 4 |-> 0],
      mifidInstrumentIdOptional             |-> [i \in 1 .. 12 |-> 0],
      mifidTransactionId                    |-> [i \in 1 .. 52 |-> 0],
      mifidPriceOptional                    |-> [i \in 1 .. 20 |-> 0],
      mifidQuantity                         |-> [i \in 1 .. 20 |-> 0],
      mifidPriceNotation                    |-> [i \in 1 .. 4 |-> 0],
      mifidCurrency                         |-> [i \in 1 .. 3 |-> 0],
      mifidQtyInMsrmtUnitNotation           |-> [i \in 1 .. 25 |-> 0],
      mifidQuantityMeasurementUnit          |-> [i \in 1 .. 20 |-> 0],
      mifidNotionalAmount                   |-> [i \in 1 .. 20 |-> 0],
      notionalCurrency                      |-> [i \in 1 .. 3 |-> 0],
      mifidClearingFlag                     |-> [i \in 1 .. 5 |-> 0],
      efficientMmtMarketMechanism           |-> [i \in 1 .. 1 |-> 0],
      efficientMmtTradingMode               |-> [i \in 1 .. 1 |-> 0],
      efficientMmtTransactionCategory       |-> [i \in 1 .. 1 |-> 0],
      efficientMmtNegotiationIndicator      |-> [i \in 1 .. 1 |-> 0],
      efficientMmtAgencyCrossTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      efficientMmtModificationIndicator     |-> [i \in 1 .. 1 |-> 0],
      efficientMmtBenchmarkIndicator        |-> [i \in 1 .. 1 |-> 0],
      efficientMmtSpecialDividendIndicator  |-> [i \in 1 .. 1 |-> 0],
      efficientMmtOffBookAutomatedIndicator |-> [i \in 1 .. 1 |-> 0],
      efficientMmtContributiontoPrice       |-> [i \in 1 .. 1 |-> 0],
      efficientMmtAlgorithmicIndicator      |-> [i \in 1 .. 1 |-> 0],
      efficientMmtPublicationMode           |-> [i \in 1 .. 1 |-> 0],
      efficientMmtPostTradeDeferral         |-> [i \in 1 .. 1 |-> 0],
      efficientMmtDuplicativeIndicator      |-> [i \in 1 .. 1 |-> 0],
      tradeReference                        |-> [i \in 1 .. 30 |-> 0],
      originalReportTimestamp               |-> [i \in 1 .. 8 |-> 0],
      priceMultiplier                       |-> [i \in 1 .. 4 |-> 0],
      priceMultiplierDecimals               |-> [i \in 1 .. 1 |-> 0],
      venue                                 |-> [i \in 1 .. 11 |-> 0],
      mifidEmissionAllowanceType            |-> [i \in 1 .. 4 |-> 0] ]

(* Apa Full Trade Information Message at zero, then each field in turn at the values it is checked at *)
CheckedApaFullTradeInformationMessage ==
    { ZeroApaFullTradeInformationMessage }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.tradingDateTime = one] : one \in Sample(27) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.publicationDateTime = one] : one \in Sample(27) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidInstrumentIdTypeOptional = one] : one \in Sample(4) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidInstrumentIdOptional = one] : one \in Sample(12) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidTransactionId = one] : one \in Sample(52) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidPriceOptional = one] : one \in Sample(20) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidQuantity = one] : one \in Sample(20) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidPriceNotation = one] : one \in Sample(4) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidQtyInMsrmtUnitNotation = one] : one \in Sample(25) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidQuantityMeasurementUnit = one] : one \in Sample(20) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidNotionalAmount = one] : one \in Sample(20) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.notionalCurrency = one] : one \in Sample(3) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidClearingFlag = one] : one \in Sample(5) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtMarketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtTradingMode = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtTransactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtNegotiationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtAgencyCrossTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtModificationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtBenchmarkIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtSpecialDividendIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtOffBookAutomatedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtContributiontoPrice = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtAlgorithmicIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtPublicationMode = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtPostTradeDeferral = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.efficientMmtDuplicativeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.tradeReference = one] : one \in Sample(30) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.originalReportTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.priceMultiplier = one] : one \in Sample(4) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.priceMultiplierDecimals = one] : one \in Sample(1) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.venue = one] : one \in Sample(11) }
        \cup { [ZeroApaFullTradeInformationMessage EXCEPT !.mifidEmissionAllowanceType = one] : one \in Sample(4) }

(***************************************************************************)
(* Start Of Snapshot Message: 16 bytes                                     *)
(***************************************************************************)

StartOfSnapshotMessage ==
    [ lastMdSeqNum : Sample(8),
      snapshotTime : Sample(8) ]

EncodeStartOfSnapshotMessage(message) ==
    message.lastMdSeqNum
        \o message.snapshotTime

DecodeStartOfSnapshotMessage(bytes) ==
    LET lastMdSeqNum == ReadBytes(bytes, 8) IN IF ~lastMdSeqNum.ok THEN Fail ELSE
    LET snapshotTime == ReadBytes(lastMdSeqNum.rest, 8) IN IF ~snapshotTime.ok THEN Fail ELSE
    Ok([ lastMdSeqNum |-> lastMdSeqNum.value,
         snapshotTime |-> snapshotTime.value ], snapshotTime.rest)

ZeroStartOfSnapshotMessage ==
    [ lastMdSeqNum |-> [i \in 1 .. 8 |-> 0],
      snapshotTime |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfSnapshotMessage ==
    { ZeroStartOfSnapshotMessage }
        \cup { [ZeroStartOfSnapshotMessage EXCEPT !.lastMdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroStartOfSnapshotMessage EXCEPT !.snapshotTime = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Snapshot Message: 16 bytes                                       *)
(***************************************************************************)

EndOfSnapshotMessage ==
    [ lastMdSeqNum : Sample(8),
      snapshotTime : Sample(8) ]

EncodeEndOfSnapshotMessage(message) ==
    message.lastMdSeqNum
        \o message.snapshotTime

DecodeEndOfSnapshotMessage(bytes) ==
    LET lastMdSeqNum == ReadBytes(bytes, 8) IN IF ~lastMdSeqNum.ok THEN Fail ELSE
    LET snapshotTime == ReadBytes(lastMdSeqNum.rest, 8) IN IF ~snapshotTime.ok THEN Fail ELSE
    Ok([ lastMdSeqNum |-> lastMdSeqNum.value,
         snapshotTime |-> snapshotTime.value ], snapshotTime.rest)

ZeroEndOfSnapshotMessage ==
    [ lastMdSeqNum |-> [i \in 1 .. 8 |-> 0],
      snapshotTime |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSnapshotMessage ==
    { ZeroEndOfSnapshotMessage }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.lastMdSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.snapshotTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

StartOfDayMessageCode == 1101  \* 0x44d
EndOfDayMessageCode == 1102  \* 0x44e
HealthStatusMessageCode == 1103  \* 0x44f
TechnicalNotificationMessageCode == 1106  \* 0x452
MarketUpdateMessageCode == 1001  \* 0x3e9
OrderUpdateMessageCode == 1002  \* 0x3ea
PriceUpdateMessageCode == 1003  \* 0x3eb
FullTradeInformationMessageCode == 1004  \* 0x3ec
MarketStatusChangeMessageCode == 1005  \* 0x3ed
TimetableMessageCode == 1006  \* 0x3ee
StandingDataMessageCode == 1007  \* 0x3ef
RealTimeIndexMessageCode == 1008  \* 0x3f0
StatisticsMessageCode == 1009  \* 0x3f1
IndexSummaryMessageCode == 1011  \* 0x3f3
StrategyStandingDataMessageCode == 1012  \* 0x3f4
ContractStandingDataMessageCode == 1013  \* 0x3f5
OutrightStandingDataMessageCode == 1014  \* 0x3f6
LisPackageStructureMessageCode == 1016  \* 0x3f8
ApaQuotesMessageCode == 1026  \* 0x402
ApaStandingDataMessageCode == 1027  \* 0x403
ApaFullTradeInformationMessageCode == 1028  \* 0x404
StartOfSnapshotMessageCode == 2101  \* 0x835
EndOfSnapshotMessageCode == 2102  \* 0x836

Payload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]
        \cup [ tag : {HealthStatusMessageCode}, body : HealthStatusMessage ]
        \cup [ tag : {TechnicalNotificationMessageCode}, body : TechnicalNotificationMessage ]
        \cup [ tag : {MarketUpdateMessageCode}, body : MarketUpdateMessage ]
        \cup [ tag : {OrderUpdateMessageCode}, body : OrderUpdateMessage ]
        \cup [ tag : {PriceUpdateMessageCode}, body : PriceUpdateMessage ]
        \cup [ tag : {FullTradeInformationMessageCode}, body : FullTradeInformationMessage ]
        \cup [ tag : {MarketStatusChangeMessageCode}, body : MarketStatusChangeMessage ]
        \cup [ tag : {TimetableMessageCode}, body : TimetableMessage ]
        \cup [ tag : {StandingDataMessageCode}, body : StandingDataMessage ]
        \cup [ tag : {RealTimeIndexMessageCode}, body : RealTimeIndexMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {IndexSummaryMessageCode}, body : IndexSummaryMessage ]
        \cup [ tag : {StrategyStandingDataMessageCode}, body : StrategyStandingDataMessage ]
        \cup [ tag : {ContractStandingDataMessageCode}, body : ContractStandingDataMessage ]
        \cup [ tag : {OutrightStandingDataMessageCode}, body : OutrightStandingDataMessage ]
        \cup [ tag : {LisPackageStructureMessageCode}, body : LisPackageStructureMessage ]
        \cup [ tag : {ApaQuotesMessageCode}, body : ApaQuotesMessage ]
        \cup [ tag : {ApaStandingDataMessageCode}, body : ApaStandingDataMessage ]
        \cup [ tag : {ApaFullTradeInformationMessageCode}, body : ApaFullTradeInformationMessage ]
        \cup [ tag : {StartOfSnapshotMessageCode}, body : StartOfSnapshotMessage ]
        \cup [ tag : {EndOfSnapshotMessageCode}, body : EndOfSnapshotMessage ]

EncodePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)
      [] message.tag = HealthStatusMessageCode -> EncodeHealthStatusMessage(message.body)
      [] message.tag = TechnicalNotificationMessageCode -> EncodeTechnicalNotificationMessage(message.body)
      [] message.tag = MarketUpdateMessageCode -> EncodeMarketUpdateMessage(message.body)
      [] message.tag = OrderUpdateMessageCode -> EncodeOrderUpdateMessage(message.body)
      [] message.tag = PriceUpdateMessageCode -> EncodePriceUpdateMessage(message.body)
      [] message.tag = FullTradeInformationMessageCode -> EncodeFullTradeInformationMessage(message.body)
      [] message.tag = MarketStatusChangeMessageCode -> EncodeMarketStatusChangeMessage(message.body)
      [] message.tag = TimetableMessageCode -> EncodeTimetableMessage(message.body)
      [] message.tag = StandingDataMessageCode -> EncodeStandingDataMessage(message.body)
      [] message.tag = RealTimeIndexMessageCode -> EncodeRealTimeIndexMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = IndexSummaryMessageCode -> EncodeIndexSummaryMessage(message.body)
      [] message.tag = StrategyStandingDataMessageCode -> EncodeStrategyStandingDataMessage(message.body)
      [] message.tag = ContractStandingDataMessageCode -> EncodeContractStandingDataMessage(message.body)
      [] message.tag = OutrightStandingDataMessageCode -> EncodeOutrightStandingDataMessage(message.body)
      [] message.tag = LisPackageStructureMessageCode -> EncodeLisPackageStructureMessage(message.body)
      [] message.tag = ApaQuotesMessageCode -> EncodeApaQuotesMessage(message.body)
      [] message.tag = ApaStandingDataMessageCode -> EncodeApaStandingDataMessage(message.body)
      [] message.tag = ApaFullTradeInformationMessageCode -> EncodeApaFullTradeInformationMessage(message.body)
      [] message.tag = StartOfSnapshotMessageCode -> EncodeStartOfSnapshotMessage(message.body)
      [] message.tag = EndOfSnapshotMessageCode -> EncodeEndOfSnapshotMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] tag = HealthStatusMessageCode -> DecodeHealthStatusMessage(bytes)
              [] tag = TechnicalNotificationMessageCode -> DecodeTechnicalNotificationMessage(bytes)
              [] tag = MarketUpdateMessageCode -> DecodeMarketUpdateMessage(bytes)
              [] tag = OrderUpdateMessageCode -> DecodeOrderUpdateMessage(bytes)
              [] tag = PriceUpdateMessageCode -> DecodePriceUpdateMessage(bytes)
              [] tag = FullTradeInformationMessageCode -> DecodeFullTradeInformationMessage(bytes)
              [] tag = MarketStatusChangeMessageCode -> DecodeMarketStatusChangeMessage(bytes)
              [] tag = TimetableMessageCode -> DecodeTimetableMessage(bytes)
              [] tag = StandingDataMessageCode -> DecodeStandingDataMessage(bytes)
              [] tag = RealTimeIndexMessageCode -> DecodeRealTimeIndexMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = IndexSummaryMessageCode -> DecodeIndexSummaryMessage(bytes)
              [] tag = StrategyStandingDataMessageCode -> DecodeStrategyStandingDataMessage(bytes)
              [] tag = ContractStandingDataMessageCode -> DecodeContractStandingDataMessage(bytes)
              [] tag = OutrightStandingDataMessageCode -> DecodeOutrightStandingDataMessage(bytes)
              [] tag = LisPackageStructureMessageCode -> DecodeLisPackageStructureMessage(bytes)
              [] tag = ApaQuotesMessageCode -> DecodeApaQuotesMessage(bytes)
              [] tag = ApaStandingDataMessageCode -> DecodeApaStandingDataMessage(bytes)
              [] tag = ApaFullTradeInformationMessageCode -> DecodeApaFullTradeInformationMessage(bytes)
              [] tag = StartOfSnapshotMessageCode -> DecodeStartOfSnapshotMessage(bytes)
              [] tag = EndOfSnapshotMessageCode -> DecodeEndOfSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> EndOfDayMessageCode, body |-> one] : one \in CheckedEndOfDayMessage }
        \cup { [tag |-> HealthStatusMessageCode, body |-> one] : one \in CheckedHealthStatusMessage }
        \cup { [tag |-> TechnicalNotificationMessageCode, body |-> one] : one \in CheckedTechnicalNotificationMessage }
        \cup { [tag |-> MarketUpdateMessageCode, body |-> one] : one \in CheckedMarketUpdateMessage }
        \cup { [tag |-> OrderUpdateMessageCode, body |-> one] : one \in CheckedOrderUpdateMessage }
        \cup { [tag |-> PriceUpdateMessageCode, body |-> one] : one \in CheckedPriceUpdateMessage }
        \cup { [tag |-> FullTradeInformationMessageCode, body |-> one] : one \in CheckedFullTradeInformationMessage }
        \cup { [tag |-> MarketStatusChangeMessageCode, body |-> one] : one \in CheckedMarketStatusChangeMessage }
        \cup { [tag |-> TimetableMessageCode, body |-> one] : one \in CheckedTimetableMessage }
        \cup { [tag |-> StandingDataMessageCode, body |-> one] : one \in CheckedStandingDataMessage }
        \cup { [tag |-> RealTimeIndexMessageCode, body |-> one] : one \in CheckedRealTimeIndexMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> IndexSummaryMessageCode, body |-> one] : one \in CheckedIndexSummaryMessage }
        \cup { [tag |-> StrategyStandingDataMessageCode, body |-> one] : one \in CheckedStrategyStandingDataMessage }
        \cup { [tag |-> ContractStandingDataMessageCode, body |-> one] : one \in CheckedContractStandingDataMessage }
        \cup { [tag |-> OutrightStandingDataMessageCode, body |-> one] : one \in CheckedOutrightStandingDataMessage }
        \cup { [tag |-> LisPackageStructureMessageCode, body |-> one] : one \in CheckedLisPackageStructureMessage }
        \cup { [tag |-> ApaQuotesMessageCode, body |-> one] : one \in CheckedApaQuotesMessage }
        \cup { [tag |-> ApaStandingDataMessageCode, body |-> one] : one \in CheckedApaStandingDataMessage }
        \cup { [tag |-> ApaFullTradeInformationMessageCode, body |-> one] : one \in CheckedApaFullTradeInformationMessage }
        \cup { [tag |-> StartOfSnapshotMessageCode, body |-> one] : one \in CheckedStartOfSnapshotMessage }
        \cup { [tag |-> EndOfSnapshotMessageCode, body |-> one] : one \in CheckedEndOfSnapshotMessage }

(***************************************************************************)
(* Optiq Message, framed by Frame                                          *)
(***************************************************************************)

OptiqMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeOptiqMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Frame counts the bytes it frames, so it is written from them *)
EncodeOptiqMessage(message) ==
    LET body == EncodeOptiqMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeOptiqMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

DecodeOptiqMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeOptiqMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOptiqMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Optiq Message at zero, then each field in turn at the values it is checked at *)
CheckedOptiqMessage ==
    { ZeroOptiqMessage }
        \cup { [ZeroOptiqMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOptiqMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroOptiqMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroOptiqMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Optiq Message, selected by Compression                                  *)
(***************************************************************************)

(* Compression is the lowest bit of Packet Flags, read as the number that set is. *)
(* CompressionOf is the key, PacketFlagsBeyond the bits beside it, PacketFlagsWith the two together. *)
CompressionOf(packetFlags) == packetFlags % 2
PacketFlagsBeyond(packetFlags) == packetFlags - CompressionOf(packetFlags)
PacketFlagsWith(beyond, compression) == beyond + compression

OptiqMessageLz4Code == 1  \* 0x01
OptiqMessagePlainCode == 0  \* stands for every value no other case names

OptiqMessageBody2 ==
    [ tag : {OptiqMessageLz4Code}, body : OptiqMessageLz4 ]
        \cup [ tag : (0 .. 1) \ {OptiqMessageLz4Code}, body : OptiqMessage ]

EncodeOptiqMessageBody2(message) ==
    CASE message.tag = OptiqMessageLz4Code -> EncodeOptiqMessageLz4(message.body)
      [] OTHER -> EncodeOptiqMessage(message.body)

DecodeOptiqMessageBody2(tag, bytes) ==
    LET read ==
            CASE tag = OptiqMessageLz4Code -> DecodeOptiqMessageLz4(bytes)
              [] OTHER -> DecodeOptiqMessage(bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOptiqMessageBody2 == [tag |-> OptiqMessageLz4Code, body |-> ZeroOptiqMessageLz4]

(* Each Optiq Message in turn, at the values the message it names is checked at *)
CheckedOptiqMessageBody2 ==
    { [tag |-> OptiqMessageLz4Code, body |-> one] : one \in CheckedOptiqMessageLz4 }
        \cup [ tag : {0, 1} \ {OptiqMessageLz4Code}, body : CheckedOptiqMessage ]

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetTime           : Sample(8),
      packetSequenceNumber : Sample(4),
      packetFlagsBeyond    : { PacketFlagsBeyond(bits) : bits \in 0 .. 255 },
      channelId            : Sample(2),
      optiqMessage         : OptiqMessageBody2 ]

EncodePacket(message) ==
    message.packetTime
        \o message.packetSequenceNumber
        \o EncodeUIntLE(PacketFlagsWith(message.packetFlagsBeyond, message.optiqMessage.tag), 2)
        \o message.channelId
        \o EncodeOptiqMessageBody2(message.optiqMessage)

DecodePacket(bytes) ==
    LET packetTime == ReadBytes(bytes, 8) IN IF ~packetTime.ok THEN Fail ELSE
    LET packetSequenceNumber == ReadBytes(packetTime.rest, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET packetFlags == ReadUIntLE(packetSequenceNumber.rest, 2) IN IF ~packetFlags.ok THEN Fail ELSE
    LET channelId == ReadBytes(packetFlags.rest, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET optiqMessage == DecodeOptiqMessageBody2(CompressionOf(packetFlags.value), channelId.rest) IN IF ~optiqMessage.ok THEN Fail ELSE
    Ok([ packetTime           |-> packetTime.value,
         packetSequenceNumber |-> packetSequenceNumber.value,
         packetFlagsBeyond    |-> PacketFlagsBeyond(packetFlags.value),
         channelId            |-> channelId.value,
         optiqMessage         |-> optiqMessage.value ], optiqMessage.rest)

ZeroPacket ==
    [ packetTime           |-> [i \in 1 .. 8 |-> 0],
      packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      packetFlagsBeyond    |-> 0,
      channelId            |-> [i \in 1 .. 2 |-> 0],
      optiqMessage         |-> ZeroOptiqMessageBody2 ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.packetFlagsBeyond = one] : one \in { PacketFlagsBeyond(bits) : bits \in {0, 1, 255} } }
        \cup { [ZeroPacket EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.optiqMessage = one] : one \in CheckedOptiqMessageBody2 }

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

(* Every Optiq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptiqMessageLz4 ==
    \A message \in CheckedOptiqMessageLz4 :
        LET read == DecodeOptiqMessageLz4(EncodeOptiqMessageLz4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfDayMessage ==
    \A message \in CheckedStartOfDayMessage :
        LET read == DecodeStartOfDayMessage(EncodeStartOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayMessage ==
    \A message \in CheckedEndOfDayMessage :
        LET read == DecodeEndOfDayMessage(EncodeEndOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Health Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHealthStatusMessage ==
    \A message \in CheckedHealthStatusMessage :
        LET read == DecodeHealthStatusMessage(EncodeHealthStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Technical Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTechnicalNotificationMessage ==
    \A message \in CheckedTechnicalNotificationMessage :
        LET read == DecodeTechnicalNotificationMessage(EncodeTechnicalNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Updates Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketUpdatesGroup ==
    \A message \in CheckedMarketUpdatesGroup :
        LET read == DecodeMarketUpdatesGroup(EncodeMarketUpdatesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Updates Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketUpdatesGroups ==
    \A message \in CheckedMarketUpdatesGroups :
        LET read == DecodeMarketUpdatesGroups(EncodeMarketUpdatesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketUpdateMessage ==
    \A message \in CheckedMarketUpdateMessage :
        LET read == DecodeMarketUpdateMessage(EncodeMarketUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Updates Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderUpdatesGroup ==
    \A message \in CheckedOrderUpdatesGroup :
        LET read == DecodeOrderUpdatesGroup(EncodeOrderUpdatesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Updates Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderUpdatesGroups ==
    \A message \in CheckedOrderUpdatesGroups :
        LET read == DecodeOrderUpdatesGroups(EncodeOrderUpdatesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderUpdateMessage ==
    \A message \in CheckedOrderUpdateMessage :
        LET read == DecodeOrderUpdateMessage(EncodeOrderUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Updates Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceUpdatesGroup ==
    \A message \in CheckedPriceUpdatesGroup :
        LET read == DecodePriceUpdatesGroup(EncodePriceUpdatesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Updates Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceUpdatesGroups ==
    \A message \in CheckedPriceUpdatesGroups :
        LET read == DecodePriceUpdatesGroups(EncodePriceUpdatesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceUpdateMessage ==
    \A message \in CheckedPriceUpdateMessage :
        LET read == DecodePriceUpdateMessage(EncodePriceUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups ==
    \A message \in CheckedNotUsedGroups :
        LET read == DecodeNotUsedGroups(EncodeNotUsedGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Full Trade Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFullTradeInformationMessage ==
    \A message \in CheckedFullTradeInformationMessage :
        LET read == DecodeFullTradeInformationMessage(EncodeFullTradeInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market States Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatesGroup ==
    \A message \in CheckedMarketStatesGroup :
        LET read == DecodeMarketStatesGroup(EncodeMarketStatesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market States Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatesGroups ==
    \A message \in CheckedMarketStatesGroups :
        LET read == DecodeMarketStatesGroups(EncodeMarketStatesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Status Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatusChangeMessage ==
    \A message \in CheckedMarketStatusChangeMessage :
        LET read == DecodeMarketStatusChangeMessage(EncodeMarketStatusChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timetables Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTimetablesGroup ==
    \A message \in CheckedTimetablesGroup :
        LET read == DecodeTimetablesGroup(EncodeTimetablesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timetables Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTimetablesGroups ==
    \A message \in CheckedTimetablesGroups :
        LET read == DecodeTimetablesGroups(EncodeTimetablesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timetable Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimetableMessage ==
    \A message \in CheckedTimetableMessage :
        LET read == DecodeTimetableMessage(EncodeTimetableMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emm Pattern Rep Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEmmPatternRepGroup ==
    \A message \in CheckedEmmPatternRepGroup :
        LET read == DecodeEmmPatternRepGroup(EncodeEmmPatternRepGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Emm Pattern Rep Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEmmPatternRepGroups ==
    \A message \in CheckedEmmPatternRepGroups :
        LET read == DecodeEmmPatternRepGroups(EncodeEmmPatternRepGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Standing Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStandingDataMessage ==
    \A message \in CheckedStandingDataMessage :
        LET read == DecodeStandingDataMessage(EncodeStandingDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Real Time Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRealTimeIndexMessage ==
    \A message \in CheckedRealTimeIndexMessage :
        LET read == DecodeRealTimeIndexMessage(EncodeRealTimeIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Stats Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewStatsGroup ==
    \A message \in CheckedNewStatsGroup :
        LET read == DecodeNewStatsGroup(EncodeNewStatsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Stats Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNewStatsGroups ==
    \A message \in CheckedNewStatsGroups :
        LET read == DecodeNewStatsGroups(EncodeNewStatsGroups(message))
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

(* Every Index Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexSummaryMessage ==
    \A message \in CheckedIndexSummaryMessage :
        LET read == DecodeIndexSummaryMessage(EncodeIndexSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Standing Data Group decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyStandingDataGroup ==
    \A message \in CheckedStrategyStandingDataGroup :
        LET read == DecodeStrategyStandingDataGroup(EncodeStrategyStandingDataGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Standing Data Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyStandingDataGroups ==
    \A message \in CheckedStrategyStandingDataGroups :
        LET read == DecodeStrategyStandingDataGroups(EncodeStrategyStandingDataGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Standing Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyStandingDataMessage ==
    \A message \in CheckedStrategyStandingDataMessage :
        LET read == DecodeStrategyStandingDataMessage(EncodeStrategyStandingDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Emm Properties Group decodes back to what was encoded, and leaves nothing over *)
RoundTripContractEmmPropertiesGroup ==
    \A message \in CheckedContractEmmPropertiesGroup :
        LET read == DecodeContractEmmPropertiesGroup(EncodeContractEmmPropertiesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Emm Properties Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripContractEmmPropertiesGroups ==
    \A message \in CheckedContractEmmPropertiesGroups :
        LET read == DecodeContractEmmPropertiesGroups(EncodeContractEmmPropertiesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Standing Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripContractStandingDataMessage ==
    \A message \in CheckedContractStandingDataMessage :
        LET read == DecodeContractStandingDataMessage(EncodeContractStandingDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Rep Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightRepGroup ==
    \A message \in CheckedOutrightRepGroup :
        LET read == DecodeOutrightRepGroup(EncodeOutrightRepGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Rep Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightRepGroups ==
    \A message \in CheckedOutrightRepGroups :
        LET read == DecodeOutrightRepGroups(EncodeOutrightRepGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Standing Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightStandingDataMessage ==
    \A message \in CheckedOutrightStandingDataMessage :
        LET read == DecodeOutrightStandingDataMessage(EncodeOutrightStandingDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Package Components Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPackageComponentsGroup ==
    \A message \in CheckedPackageComponentsGroup :
        LET read == DecodePackageComponentsGroup(EncodePackageComponentsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Package Components Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPackageComponentsGroups ==
    \A message \in CheckedPackageComponentsGroups :
        LET read == DecodePackageComponentsGroups(EncodePackageComponentsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lis Package Structure Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLisPackageStructureMessage ==
    \A message \in CheckedLisPackageStructureMessage :
        LET read == DecodeLisPackageStructureMessage(EncodeLisPackageStructureMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Apa Quotes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApaQuotesMessage ==
    \A message \in CheckedApaQuotesMessage :
        LET read == DecodeApaQuotesMessage(EncodeApaQuotesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Apa Standing Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApaStandingDataMessage ==
    \A message \in CheckedApaStandingDataMessage :
        LET read == DecodeApaStandingDataMessage(EncodeApaStandingDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Apa Full Trade Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApaFullTradeInformationMessage ==
    \A message \in CheckedApaFullTradeInformationMessage :
        LET read == DecodeApaFullTradeInformationMessage(EncodeApaFullTradeInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfSnapshotMessage ==
    \A message \in CheckedStartOfSnapshotMessage :
        LET read == DecodeStartOfSnapshotMessage(EncodeStartOfSnapshotMessage(message))
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

(* Every Optiq Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptiqMessage ==
    \A message \in CheckedOptiqMessage :
        LET read == DecodeOptiqMessage(EncodeOptiqMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Optiq Message is selected by the Compression it is written under *)
SelectsOptiqMessageBody2 ==
    \A message \in CheckedOptiqMessageBody2 :
        LET sent == EncodeOptiqMessageBody2(message)
            read == DecodeOptiqMessageBody2(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Frame is written from the bytes it frames *)
FramesOptiqMessage ==
    \A message \in CheckedOptiqMessage :
        LET bytes == EncodeOptiqMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
