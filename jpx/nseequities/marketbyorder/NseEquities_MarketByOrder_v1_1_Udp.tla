---------------- MODULE NseEquities_MarketByOrder_v1_1_Udp -----------------
(***************************************************************************)
(* Japan Exchange Group Market By Order v1.1                               *)
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
(* Seconds Timestamp Message: 4 bytes                                      *)
(***************************************************************************)

SecondsTimestampMessage ==
    [ timeSeconds : Sample(4) ]

EncodeSecondsTimestampMessage(message) ==
    message.timeSeconds

DecodeSecondsTimestampMessage(bytes) ==
    LET timeSeconds == ReadBytes(bytes, 4) IN IF ~timeSeconds.ok THEN Fail ELSE
    Ok([ timeSeconds |-> timeSeconds.value ], timeSeconds.rest)

ZeroSecondsTimestampMessage ==
    [ timeSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Seconds Timestamp Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsTimestampMessage ==
    { ZeroSecondsTimestampMessage }
        \cup { [ZeroSecondsTimestampMessage EXCEPT !.timeSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 17 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeMicroseconds   : Sample(4),
      marketStatus       : Sample(1),
      statusFlag         : Sample(2),
      shortSellingStatus : Sample(1),
      pricingMethod      : Sample(1),
      bookCenterPrice    : Sample(8) ]

EncodeTradingStatusMessage(message) ==
    message.timeMicroseconds
        \o message.marketStatus
        \o message.statusFlag
        \o message.shortSellingStatus
        \o message.pricingMethod
        \o message.bookCenterPrice

DecodeTradingStatusMessage(bytes) ==
    LET timeMicroseconds == ReadBytes(bytes, 4) IN IF ~timeMicroseconds.ok THEN Fail ELSE
    LET marketStatus == ReadBytes(timeMicroseconds.rest, 1) IN IF ~marketStatus.ok THEN Fail ELSE
    LET statusFlag == ReadBytes(marketStatus.rest, 2) IN IF ~statusFlag.ok THEN Fail ELSE
    LET shortSellingStatus == ReadBytes(statusFlag.rest, 1) IN IF ~shortSellingStatus.ok THEN Fail ELSE
    LET pricingMethod == ReadBytes(shortSellingStatus.rest, 1) IN IF ~pricingMethod.ok THEN Fail ELSE
    LET bookCenterPrice == ReadBytes(pricingMethod.rest, 8) IN IF ~bookCenterPrice.ok THEN Fail ELSE
    Ok([ timeMicroseconds   |-> timeMicroseconds.value,
         marketStatus       |-> marketStatus.value,
         statusFlag         |-> statusFlag.value,
         shortSellingStatus |-> shortSellingStatus.value,
         pricingMethod      |-> pricingMethod.value,
         bookCenterPrice    |-> bookCenterPrice.value ], bookCenterPrice.rest)

ZeroTradingStatusMessage ==
    [ timeMicroseconds   |-> [i \in 1 .. 4 |-> 0],
      marketStatus       |-> [i \in 1 .. 1 |-> 0],
      statusFlag         |-> [i \in 1 .. 2 |-> 0],
      shortSellingStatus |-> [i \in 1 .. 1 |-> 0],
      pricingMethod      |-> [i \in 1 .. 1 |-> 0],
      bookCenterPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeMicroseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.marketStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.statusFlag = one] : one \in Sample(2) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.shortSellingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.pricingMethod = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.bookCenterPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Summary Message: 45 bytes                                     *)
(***************************************************************************)

ExecutionSummaryMessage ==
    [ timeMicroseconds  : Sample(4),
      triggeredSide     : Sample(1),
      totalVolume       : Sample(6),
      totalInvalidation : Sample(6),
      lastPrice         : Sample(8),
      matchId           : Sample(4),
      bestOffer         : Sample(8),
      bestBid           : Sample(8) ]

EncodeExecutionSummaryMessage(message) ==
    message.timeMicroseconds
        \o message.triggeredSide
        \o message.totalVolume
        \o message.totalInvalidation
        \o message.lastPrice
        \o message.matchId
        \o message.bestOffer
        \o message.bestBid

DecodeExecutionSummaryMessage(bytes) ==
    LET timeMicroseconds == ReadBytes(bytes, 4) IN IF ~timeMicroseconds.ok THEN Fail ELSE
    LET triggeredSide == ReadBytes(timeMicroseconds.rest, 1) IN IF ~triggeredSide.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(triggeredSide.rest, 6) IN IF ~totalVolume.ok THEN Fail ELSE
    LET totalInvalidation == ReadBytes(totalVolume.rest, 6) IN IF ~totalInvalidation.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(totalInvalidation.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET matchId == ReadBytes(lastPrice.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET bestOffer == ReadBytes(matchId.rest, 8) IN IF ~bestOffer.ok THEN Fail ELSE
    LET bestBid == ReadBytes(bestOffer.rest, 8) IN IF ~bestBid.ok THEN Fail ELSE
    Ok([ timeMicroseconds  |-> timeMicroseconds.value,
         triggeredSide     |-> triggeredSide.value,
         totalVolume       |-> totalVolume.value,
         totalInvalidation |-> totalInvalidation.value,
         lastPrice         |-> lastPrice.value,
         matchId           |-> matchId.value,
         bestOffer         |-> bestOffer.value,
         bestBid           |-> bestBid.value ], bestBid.rest)

ZeroExecutionSummaryMessage ==
    [ timeMicroseconds  |-> [i \in 1 .. 4 |-> 0],
      triggeredSide     |-> [i \in 1 .. 1 |-> 0],
      totalVolume       |-> [i \in 1 .. 6 |-> 0],
      totalInvalidation |-> [i \in 1 .. 6 |-> 0],
      lastPrice         |-> [i \in 1 .. 8 |-> 0],
      matchId           |-> [i \in 1 .. 4 |-> 0],
      bestOffer         |-> [i \in 1 .. 8 |-> 0],
      bestBid           |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionSummaryMessage ==
    { ZeroExecutionSummaryMessage }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.timeMicroseconds = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.triggeredSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.totalVolume = one] : one \in Sample(6) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.totalInvalidation = one] : one \in Sample(6) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.bestOffer = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.bestBid = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order Message: 25 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ timeMicroseconds : Sample(4),
      orderId          : Sample(4),
      side             : Sample(1),
      quantity         : Sample(6),
      price            : Sample(8),
      orderCondition   : Sample(1),
      modificationFlag : Sample(1) ]

EncodeAddOrderMessage(message) ==
    message.timeMicroseconds
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderCondition
        \o message.modificationFlag

DecodeAddOrderMessage(bytes) ==
    LET timeMicroseconds == ReadBytes(bytes, 4) IN IF ~timeMicroseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeMicroseconds.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 6) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderCondition == ReadBytes(price.rest, 1) IN IF ~orderCondition.ok THEN Fail ELSE
    LET modificationFlag == ReadBytes(orderCondition.rest, 1) IN IF ~modificationFlag.ok THEN Fail ELSE
    Ok([ timeMicroseconds |-> timeMicroseconds.value,
         orderId          |-> orderId.value,
         side             |-> side.value,
         quantity         |-> quantity.value,
         price            |-> price.value,
         orderCondition   |-> orderCondition.value,
         modificationFlag |-> modificationFlag.value ], modificationFlag.rest)

ZeroAddOrderMessage ==
    [ timeMicroseconds |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      quantity         |-> [i \in 1 .. 6 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderCondition   |-> [i \in 1 .. 1 |-> 0],
      modificationFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.timeMicroseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.quantity = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderCondition = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.modificationFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 19 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timeMicroseconds : Sample(4),
      orderId          : Sample(4),
      side             : Sample(1),
      volume           : Sample(6),
      matchId          : Sample(4) ]

EncodeOrderExecutedMessage(message) ==
    message.timeMicroseconds
        \o message.orderId
        \o message.side
        \o message.volume
        \o message.matchId

DecodeOrderExecutedMessage(bytes) ==
    LET timeMicroseconds == ReadBytes(bytes, 4) IN IF ~timeMicroseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeMicroseconds.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET volume == ReadBytes(side.rest, 6) IN IF ~volume.ok THEN Fail ELSE
    LET matchId == ReadBytes(volume.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    Ok([ timeMicroseconds |-> timeMicroseconds.value,
         orderId          |-> orderId.value,
         side             |-> side.value,
         volume           |-> volume.value,
         matchId          |-> matchId.value ], matchId.rest)

ZeroOrderExecutedMessage ==
    [ timeMicroseconds |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      volume           |-> [i \in 1 .. 6 |-> 0],
      matchId          |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timeMicroseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.volume = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed With Price Message: 28 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ timeMicroseconds     : Sample(4),
      orderId              : Sample(4),
      side                 : Sample(1),
      volume               : Sample(6),
      matchId              : Sample(4),
      executionPrice       : Sample(8),
      adoptedPricingMethod : Sample(1) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.timeMicroseconds
        \o message.orderId
        \o message.side
        \o message.volume
        \o message.matchId
        \o message.executionPrice
        \o message.adoptedPricingMethod

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET timeMicroseconds == ReadBytes(bytes, 4) IN IF ~timeMicroseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeMicroseconds.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET volume == ReadBytes(side.rest, 6) IN IF ~volume.ok THEN Fail ELSE
    LET matchId == ReadBytes(volume.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(matchId.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET adoptedPricingMethod == ReadBytes(executionPrice.rest, 1) IN IF ~adoptedPricingMethod.ok THEN Fail ELSE
    Ok([ timeMicroseconds     |-> timeMicroseconds.value,
         orderId              |-> orderId.value,
         side                 |-> side.value,
         volume               |-> volume.value,
         matchId              |-> matchId.value,
         executionPrice       |-> executionPrice.value,
         adoptedPricingMethod |-> adoptedPricingMethod.value ], adoptedPricingMethod.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ timeMicroseconds     |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      volume               |-> [i \in 1 .. 6 |-> 0],
      matchId              |-> [i \in 1 .. 4 |-> 0],
      executionPrice       |-> [i \in 1 .. 8 |-> 0],
      adoptedPricingMethod |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.timeMicroseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.volume = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.adoptedPricingMethod = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Delete Message: 10 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ timeMicroseconds : Sample(4),
      orderId          : Sample(4),
      side             : Sample(1),
      modificationFlag : Sample(1) ]

EncodeOrderDeleteMessage(message) ==
    message.timeMicroseconds
        \o message.orderId
        \o message.side
        \o message.modificationFlag

DecodeOrderDeleteMessage(bytes) ==
    LET timeMicroseconds == ReadBytes(bytes, 4) IN IF ~timeMicroseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeMicroseconds.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET modificationFlag == ReadBytes(side.rest, 1) IN IF ~modificationFlag.ok THEN Fail ELSE
    Ok([ timeMicroseconds |-> timeMicroseconds.value,
         orderId          |-> orderId.value,
         side             |-> side.value,
         modificationFlag |-> modificationFlag.value ], modificationFlag.rest)

ZeroOrderDeleteMessage ==
    [ timeMicroseconds |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      modificationFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timeMicroseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.modificationFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Reset Message: 1 bytes                                                  *)
(***************************************************************************)

ResetMessage ==
    [ resetStartEndFlag : Sample(1) ]

EncodeResetMessage(message) ==
    message.resetStartEndFlag

DecodeResetMessage(bytes) ==
    LET resetStartEndFlag == ReadBytes(bytes, 1) IN IF ~resetStartEndFlag.ok THEN Fail ELSE
    Ok([ resetStartEndFlag |-> resetStartEndFlag.value ], resetStartEndFlag.rest)

ZeroResetMessage ==
    [ resetStartEndFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedResetMessage ==
    { ZeroResetMessage }
        \cup { [ZeroResetMessage EXCEPT !.resetStartEndFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Communication Control Message: 2 bytes                                  *)
(***************************************************************************)

CommunicationControlMessage ==
    [ testModeFlag              : Sample(1),
      communicationStartEndFlag : Sample(1) ]

EncodeCommunicationControlMessage(message) ==
    message.testModeFlag
        \o message.communicationStartEndFlag

DecodeCommunicationControlMessage(bytes) ==
    LET testModeFlag == ReadBytes(bytes, 1) IN IF ~testModeFlag.ok THEN Fail ELSE
    LET communicationStartEndFlag == ReadBytes(testModeFlag.rest, 1) IN IF ~communicationStartEndFlag.ok THEN Fail ELSE
    Ok([ testModeFlag              |-> testModeFlag.value,
         communicationStartEndFlag |-> communicationStartEndFlag.value ], communicationStartEndFlag.rest)

ZeroCommunicationControlMessage ==
    [ testModeFlag              |-> [i \in 1 .. 1 |-> 0],
      communicationStartEndFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Communication Control Message at zero, then each field in turn at the values it is checked at *)
CheckedCommunicationControlMessage ==
    { ZeroCommunicationControlMessage }
        \cup { [ZeroCommunicationControlMessage EXCEPT !.testModeFlag = one] : one \in Sample(1) }
        \cup { [ZeroCommunicationControlMessage EXCEPT !.communicationStartEndFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsTimestampMessageCode == 84  \* "T"
TradingStatusMessageCode == 79  \* "O"
ExecutionSummaryMessageCode == 75  \* "K"
AddOrderMessageCode == 65  \* "A"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderDeleteMessageCode == 68  \* "D"
ResetMessageCode == 82  \* "R"
CommunicationControlMessageCode == 76  \* "L"

Payload ==
    [ tag : {SecondsTimestampMessageCode}, body : SecondsTimestampMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {ExecutionSummaryMessageCode}, body : ExecutionSummaryMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {ResetMessageCode}, body : ResetMessage ]
        \cup [ tag : {CommunicationControlMessageCode}, body : CommunicationControlMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsTimestampMessageCode -> EncodeSecondsTimestampMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = ExecutionSummaryMessageCode -> EncodeExecutionSummaryMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = ResetMessageCode -> EncodeResetMessage(message.body)
      [] message.tag = CommunicationControlMessageCode -> EncodeCommunicationControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsTimestampMessageCode -> DecodeSecondsTimestampMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = ExecutionSummaryMessageCode -> DecodeExecutionSummaryMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = ResetMessageCode -> DecodeResetMessage(bytes)
              [] tag = CommunicationControlMessageCode -> DecodeCommunicationControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsTimestampMessageCode, body |-> ZeroSecondsTimestampMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsTimestampMessageCode, body |-> one] : one \in CheckedSecondsTimestampMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> ExecutionSummaryMessageCode, body |-> one] : one \in CheckedExecutionSummaryMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> ResetMessageCode, body |-> one] : one \in CheckedResetMessage }
        \cup { [tag |-> CommunicationControlMessageCode, body |-> one] : one \in CheckedCommunicationControlMessage }

(***************************************************************************)
(* Message, framed by Tag Length                                           *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Tag Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SecondsTimestampMessageCode, body |-> ZeroSecondsTimestampMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionSummaryMessageCode, body |-> ZeroExecutionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceMessageCode, body |-> ZeroOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ResetMessageCode, body |-> ZeroResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CommunicationControlMessageCode, body |-> ZeroCommunicationControlMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ multicastGroupNumber  : Sample(1),
      numberOfSystemReboots : Sample(1),
      sequenceNumber        : Sample(4),
      issueCode             : Sample(12),
      updateNumber          : Sample(4),
      packetNumber          : Sample(1),
      totalNumberOfPackets  : Sample(1),
      utilityFlag           : Sample(1),
      message               : SampleLists(OneMessage) ]

EncodeUdpPacket(message) ==
    message.multicastGroupNumber
        \o message.numberOfSystemReboots
        \o message.sequenceNumber
        \o message.issueCode
        \o message.updateNumber
        \o message.packetNumber
        \o message.totalNumberOfPackets
        \o message.utilityFlag
        \o EncodeUIntBE(Len(message.message), 1)
        \o EncodeMessageList(message.message)

DecodeUdpPacket(bytes) ==
    LET multicastGroupNumber == ReadBytes(bytes, 1) IN IF ~multicastGroupNumber.ok THEN Fail ELSE
    LET numberOfSystemReboots == ReadBytes(multicastGroupNumber.rest, 1) IN IF ~numberOfSystemReboots.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(numberOfSystemReboots.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET issueCode == ReadBytes(sequenceNumber.rest, 12) IN IF ~issueCode.ok THEN Fail ELSE
    LET updateNumber == ReadBytes(issueCode.rest, 4) IN IF ~updateNumber.ok THEN Fail ELSE
    LET packetNumber == ReadBytes(updateNumber.rest, 1) IN IF ~packetNumber.ok THEN Fail ELSE
    LET totalNumberOfPackets == ReadBytes(packetNumber.rest, 1) IN IF ~totalNumberOfPackets.ok THEN Fail ELSE
    LET utilityFlag == ReadBytes(totalNumberOfPackets.rest, 1) IN IF ~utilityFlag.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(utilityFlag.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ multicastGroupNumber  |-> multicastGroupNumber.value,
         numberOfSystemReboots |-> numberOfSystemReboots.value,
         sequenceNumber        |-> sequenceNumber.value,
         issueCode             |-> issueCode.value,
         updateNumber          |-> updateNumber.value,
         packetNumber          |-> packetNumber.value,
         totalNumberOfPackets  |-> totalNumberOfPackets.value,
         utilityFlag           |-> utilityFlag.value,
         message               |-> message.value ], message.rest)

ZeroUdpPacket ==
    [ multicastGroupNumber  |-> [i \in 1 .. 1 |-> 0],
      numberOfSystemReboots |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      issueCode             |-> [i \in 1 .. 12 |-> 0],
      updateNumber          |-> [i \in 1 .. 4 |-> 0],
      packetNumber          |-> [i \in 1 .. 1 |-> 0],
      totalNumberOfPackets  |-> [i \in 1 .. 1 |-> 0],
      utilityFlag           |-> [i \in 1 .. 1 |-> 0],
      message               |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.multicastGroupNumber = one] : one \in Sample(1) }
        \cup { [ZeroUdpPacket EXCEPT !.numberOfSystemReboots = one] : one \in Sample(1) }
        \cup { [ZeroUdpPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroUdpPacket EXCEPT !.issueCode = one] : one \in Sample(12) }
        \cup { [ZeroUdpPacket EXCEPT !.updateNumber = one] : one \in Sample(4) }
        \cup { [ZeroUdpPacket EXCEPT !.packetNumber = one] : one \in Sample(1) }
        \cup { [ZeroUdpPacket EXCEPT !.totalNumberOfPackets = one] : one \in Sample(1) }
        \cup { [ZeroUdpPacket EXCEPT !.utilityFlag = one] : one \in Sample(1) }
        \cup { [ZeroUdpPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Seconds Timestamp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsTimestampMessage ==
    \A message \in CheckedSecondsTimestampMessage :
        LET read == DecodeSecondsTimestampMessage(EncodeSecondsTimestampMessage(message))
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

(* Every Execution Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionSummaryMessage ==
    \A message \in CheckedExecutionSummaryMessage :
        LET read == DecodeExecutionSummaryMessage(EncodeExecutionSummaryMessage(message))
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

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceMessage ==
    \A message \in CheckedOrderExecutedWithPriceMessage :
        LET read == DecodeOrderExecutedWithPriceMessage(EncodeOrderExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetMessage ==
    \A message \in CheckedResetMessage :
        LET read == DecodeResetMessage(EncodeResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Communication Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCommunicationControlMessage ==
    \A message \in CheckedCommunicationControlMessage :
        LET read == DecodeCommunicationControlMessage(EncodeCommunicationControlMessage(message))
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

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Tag Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
