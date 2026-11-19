-------------- MODULE SapphireOptions_ClearingTradeDrop_v2_0 ---------------
(***************************************************************************)
(* Miami International Holdings Clearing Trade Drop v2.0                   *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Sesm Packet *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Unsequenced Data Packet fills what is left of the frame Sesm      *)
(* Packet Length states, which is what it is read from.                    *)
(*                                                                         *)
(* Note: a Sesm Tcp Packet that ends the session is the last of its        *)
(* Packet: nothing may follow it.                                          *)
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
(* System State: 21 bytes                                                  *)
(***************************************************************************)

SystemState ==
    [ notificationTime : Sample(8),
      ctdVersion       : Sample(8),
      tradingSessionId : Sample(4),
      systemStatus     : Sample(1) ]

EncodeSystemState(message) ==
    message.notificationTime
        \o message.ctdVersion
        \o message.tradingSessionId
        \o message.systemStatus

DecodeSystemState(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET ctdVersion == ReadBytes(notificationTime.rest, 8) IN IF ~ctdVersion.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(ctdVersion.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(tradingSessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ notificationTime |-> notificationTime.value,
         ctdVersion       |-> ctdVersion.value,
         tradingSessionId |-> tradingSessionId.value,
         systemStatus     |-> systemStatus.value ], systemStatus.rest)

ZeroSystemState ==
    [ notificationTime |-> [i \in 1 .. 8 |-> 0],
      ctdVersion       |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId |-> [i \in 1 .. 4 |-> 0],
      systemStatus     |-> [i \in 1 .. 1 |-> 0] ]

(* System State at zero, then each field in turn at the values it is checked at *)
CheckedSystemState ==
    { ZeroSystemState }
        \cup { [ZeroSystemState EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemState EXCEPT !.ctdVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemState EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroSystemState EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 318 bytes                                                *)
(***************************************************************************)

TradeMessage ==
    [ processingTime                       : Sample(8),
      tradeTime                            : Sample(8),
      tradeAsOfDate                        : Sample(4),
      tradeAction                          : Sample(1),
      tradeType                            : Sample(1),
      tradeId                              : Sample(4),
      executionId                          : Sample(8),
      correctionNumber                     : Sample(1),
      transactionId                        : Sample(4),
      referenceTradeTime                   : Sample(8),
      referenceTradeId                     : Sample(4),
      referenceCorrectionNumber            : Sample(1),
      correctionType                       : Sample(1),
      strategyId                           : Sample(4),
      reserved16                           : Sample(16),
      productId                            : Sample(4),
      underlyingSymbol                     : Sample(11),
      underlyingType                       : Sample(1),
      securitySymbol                       : Sample(6),
      expirationDate                       : Sample(4),
      strikePrice                          : Sample(4),
      callOrPut                            : Sample(1),
      reserved8                            : Sample(8),
      side                                 : Sample(1),
      price                                : Sample(4),
      size                                 : Sample(4),
      tradeCondition                       : Sample(1),
      secondReserved8                      : Sample(8),
      classFeeType                         : Sample(1),
      sapphireBboPostingIncrementIndicator : Sample(1),
      executionExchange                    : Sample(1),
      routedOrderQuantity                  : Sample(4),
      marketState                          : Sample(1),
      freeTradingCondition                 : Sample(1),
      stockExecutionDestination            : Sample(1),
      fixLiquidityRole                     : Sample(1),
      contraLiquidityType                  : Sample(1),
      contraFixLiquidityRole               : Sample(1),
      secondReserved16                     : Sample(16),
      executingMpid                        : Sample(4),
      orderDate                            : Sample(4),
      fixOrderId                           : Sample(30),
      clientOrderId                        : Sample(4),
      clientMessageId                      : Sample(4),
      bulkLiquidityIndex                   : Sample(1),
      openCloseIndicator                   : Sample(1),
      liquidityType                        : Sample(1),
      liquidityIndicator                   : Sample(1),
      timeInForce                          : Sample(1),
      legReferenceId                       : Sample(5),
      stockShortSellIndicator              : Sample(1),
      reserved14                           : Sample(14),
      clearingMpid                         : Sample(4),
      memberType                           : Sample(1),
      origin                               : Sample(1),
      clearingNumber                       : Sample(4),
      cmta                                 : Sample(4),
      multiAccount                         : Sample(5),
      accountId                            : Sample(10),
      supplementaryId                      : Sample(13),
      allocationId                         : Sample(4),
      orderCapacity                        : Sample(1),
      reserved11                           : Sample(11),
      mpid                                 : Sample(4),
      contraMemberType                     : Sample(1),
      contraOrigin                         : Sample(1),
      contraClearingNumber                 : Sample(4),
      contraCmta                           : Sample(4),
      contraTimeInForce                    : Sample(1),
      contraOrderCapacity                  : Sample(1),
      secondReserved14                     : Sample(14) ]

EncodeTradeMessage(message) ==
    message.processingTime
        \o message.tradeTime
        \o message.tradeAsOfDate
        \o message.tradeAction
        \o message.tradeType
        \o message.tradeId
        \o message.executionId
        \o message.correctionNumber
        \o message.transactionId
        \o message.referenceTradeTime
        \o message.referenceTradeId
        \o message.referenceCorrectionNumber
        \o message.correctionType
        \o message.strategyId
        \o message.reserved16
        \o message.productId
        \o message.underlyingSymbol
        \o message.underlyingType
        \o message.securitySymbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.callOrPut
        \o message.reserved8
        \o message.side
        \o message.price
        \o message.size
        \o message.tradeCondition
        \o message.secondReserved8
        \o message.classFeeType
        \o message.sapphireBboPostingIncrementIndicator
        \o message.executionExchange
        \o message.routedOrderQuantity
        \o message.marketState
        \o message.freeTradingCondition
        \o message.stockExecutionDestination
        \o message.fixLiquidityRole
        \o message.contraLiquidityType
        \o message.contraFixLiquidityRole
        \o message.secondReserved16
        \o message.executingMpid
        \o message.orderDate
        \o message.fixOrderId
        \o message.clientOrderId
        \o message.clientMessageId
        \o message.bulkLiquidityIndex
        \o message.openCloseIndicator
        \o message.liquidityType
        \o message.liquidityIndicator
        \o message.timeInForce
        \o message.legReferenceId
        \o message.stockShortSellIndicator
        \o message.reserved14
        \o message.clearingMpid
        \o message.memberType
        \o message.origin
        \o message.clearingNumber
        \o message.cmta
        \o message.multiAccount
        \o message.accountId
        \o message.supplementaryId
        \o message.allocationId
        \o message.orderCapacity
        \o message.reserved11
        \o message.mpid
        \o message.contraMemberType
        \o message.contraOrigin
        \o message.contraClearingNumber
        \o message.contraCmta
        \o message.contraTimeInForce
        \o message.contraOrderCapacity
        \o message.secondReserved14

DecodeTradeMessage(bytes) ==
    LET processingTime == ReadBytes(bytes, 8) IN IF ~processingTime.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(processingTime.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET tradeAsOfDate == ReadBytes(tradeTime.rest, 4) IN IF ~tradeAsOfDate.ok THEN Fail ELSE
    LET tradeAction == ReadBytes(tradeAsOfDate.rest, 1) IN IF ~tradeAction.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradeAction.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeType.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET executionId == ReadBytes(tradeId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(executionId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET transactionId == ReadBytes(correctionNumber.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET referenceTradeTime == ReadBytes(transactionId.rest, 8) IN IF ~referenceTradeTime.ok THEN Fail ELSE
    LET referenceTradeId == ReadBytes(referenceTradeTime.rest, 4) IN IF ~referenceTradeId.ok THEN Fail ELSE
    LET referenceCorrectionNumber == ReadBytes(referenceTradeId.rest, 1) IN IF ~referenceCorrectionNumber.ok THEN Fail ELSE
    LET correctionType == ReadBytes(referenceCorrectionNumber.rest, 1) IN IF ~correctionType.ok THEN Fail ELSE
    LET strategyId == ReadBytes(correctionType.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(strategyId.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET productId == ReadBytes(reserved16.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(productId.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~underlyingType.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(underlyingType.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(securitySymbol.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET callOrPut == ReadBytes(strikePrice.rest, 1) IN IF ~callOrPut.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(callOrPut.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET side == ReadBytes(reserved8.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(size.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(tradeCondition.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET classFeeType == ReadBytes(secondReserved8.rest, 1) IN IF ~classFeeType.ok THEN Fail ELSE
    LET sapphireBboPostingIncrementIndicator == ReadBytes(classFeeType.rest, 1) IN IF ~sapphireBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET executionExchange == ReadBytes(sapphireBboPostingIncrementIndicator.rest, 1) IN IF ~executionExchange.ok THEN Fail ELSE
    LET routedOrderQuantity == ReadBytes(executionExchange.rest, 4) IN IF ~routedOrderQuantity.ok THEN Fail ELSE
    LET marketState == ReadBytes(routedOrderQuantity.rest, 1) IN IF ~marketState.ok THEN Fail ELSE
    LET freeTradingCondition == ReadBytes(marketState.rest, 1) IN IF ~freeTradingCondition.ok THEN Fail ELSE
    LET stockExecutionDestination == ReadBytes(freeTradingCondition.rest, 1) IN IF ~stockExecutionDestination.ok THEN Fail ELSE
    LET fixLiquidityRole == ReadBytes(stockExecutionDestination.rest, 1) IN IF ~fixLiquidityRole.ok THEN Fail ELSE
    LET contraLiquidityType == ReadBytes(fixLiquidityRole.rest, 1) IN IF ~contraLiquidityType.ok THEN Fail ELSE
    LET contraFixLiquidityRole == ReadBytes(contraLiquidityType.rest, 1) IN IF ~contraFixLiquidityRole.ok THEN Fail ELSE
    LET secondReserved16 == ReadBytes(contraFixLiquidityRole.rest, 16) IN IF ~secondReserved16.ok THEN Fail ELSE
    LET executingMpid == ReadBytes(secondReserved16.rest, 4) IN IF ~executingMpid.ok THEN Fail ELSE
    LET orderDate == ReadBytes(executingMpid.rest, 4) IN IF ~orderDate.ok THEN Fail ELSE
    LET fixOrderId == ReadBytes(orderDate.rest, 30) IN IF ~fixOrderId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(fixOrderId.rest, 4) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMessageId == ReadBytes(clientOrderId.rest, 4) IN IF ~clientMessageId.ok THEN Fail ELSE
    LET bulkLiquidityIndex == ReadBytes(clientMessageId.rest, 1) IN IF ~bulkLiquidityIndex.ok THEN Fail ELSE
    LET openCloseIndicator == ReadBytes(bulkLiquidityIndex.rest, 1) IN IF ~openCloseIndicator.ok THEN Fail ELSE
    LET liquidityType == ReadBytes(openCloseIndicator.rest, 1) IN IF ~liquidityType.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(liquidityType.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(liquidityIndicator.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET legReferenceId == ReadBytes(timeInForce.rest, 5) IN IF ~legReferenceId.ok THEN Fail ELSE
    LET stockShortSellIndicator == ReadBytes(legReferenceId.rest, 1) IN IF ~stockShortSellIndicator.ok THEN Fail ELSE
    LET reserved14 == ReadBytes(stockShortSellIndicator.rest, 14) IN IF ~reserved14.ok THEN Fail ELSE
    LET clearingMpid == ReadBytes(reserved14.rest, 4) IN IF ~clearingMpid.ok THEN Fail ELSE
    LET memberType == ReadBytes(clearingMpid.rest, 1) IN IF ~memberType.ok THEN Fail ELSE
    LET origin == ReadBytes(memberType.rest, 1) IN IF ~origin.ok THEN Fail ELSE
    LET clearingNumber == ReadBytes(origin.rest, 4) IN IF ~clearingNumber.ok THEN Fail ELSE
    LET cmta == ReadBytes(clearingNumber.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET multiAccount == ReadBytes(cmta.rest, 5) IN IF ~multiAccount.ok THEN Fail ELSE
    LET accountId == ReadBytes(multiAccount.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET supplementaryId == ReadBytes(accountId.rest, 13) IN IF ~supplementaryId.ok THEN Fail ELSE
    LET allocationId == ReadBytes(supplementaryId.rest, 4) IN IF ~allocationId.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(allocationId.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET reserved11 == ReadBytes(orderCapacity.rest, 11) IN IF ~reserved11.ok THEN Fail ELSE
    LET mpid == ReadBytes(reserved11.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET contraMemberType == ReadBytes(mpid.rest, 1) IN IF ~contraMemberType.ok THEN Fail ELSE
    LET contraOrigin == ReadBytes(contraMemberType.rest, 1) IN IF ~contraOrigin.ok THEN Fail ELSE
    LET contraClearingNumber == ReadBytes(contraOrigin.rest, 4) IN IF ~contraClearingNumber.ok THEN Fail ELSE
    LET contraCmta == ReadBytes(contraClearingNumber.rest, 4) IN IF ~contraCmta.ok THEN Fail ELSE
    LET contraTimeInForce == ReadBytes(contraCmta.rest, 1) IN IF ~contraTimeInForce.ok THEN Fail ELSE
    LET contraOrderCapacity == ReadBytes(contraTimeInForce.rest, 1) IN IF ~contraOrderCapacity.ok THEN Fail ELSE
    LET secondReserved14 == ReadBytes(contraOrderCapacity.rest, 14) IN IF ~secondReserved14.ok THEN Fail ELSE
    Ok([ processingTime                       |-> processingTime.value,
         tradeTime                            |-> tradeTime.value,
         tradeAsOfDate                        |-> tradeAsOfDate.value,
         tradeAction                          |-> tradeAction.value,
         tradeType                            |-> tradeType.value,
         tradeId                              |-> tradeId.value,
         executionId                          |-> executionId.value,
         correctionNumber                     |-> correctionNumber.value,
         transactionId                        |-> transactionId.value,
         referenceTradeTime                   |-> referenceTradeTime.value,
         referenceTradeId                     |-> referenceTradeId.value,
         referenceCorrectionNumber            |-> referenceCorrectionNumber.value,
         correctionType                       |-> correctionType.value,
         strategyId                           |-> strategyId.value,
         reserved16                           |-> reserved16.value,
         productId                            |-> productId.value,
         underlyingSymbol                     |-> underlyingSymbol.value,
         underlyingType                       |-> underlyingType.value,
         securitySymbol                       |-> securitySymbol.value,
         expirationDate                       |-> expirationDate.value,
         strikePrice                          |-> strikePrice.value,
         callOrPut                            |-> callOrPut.value,
         reserved8                            |-> reserved8.value,
         side                                 |-> side.value,
         price                                |-> price.value,
         size                                 |-> size.value,
         tradeCondition                       |-> tradeCondition.value,
         secondReserved8                      |-> secondReserved8.value,
         classFeeType                         |-> classFeeType.value,
         sapphireBboPostingIncrementIndicator |-> sapphireBboPostingIncrementIndicator.value,
         executionExchange                    |-> executionExchange.value,
         routedOrderQuantity                  |-> routedOrderQuantity.value,
         marketState                          |-> marketState.value,
         freeTradingCondition                 |-> freeTradingCondition.value,
         stockExecutionDestination            |-> stockExecutionDestination.value,
         fixLiquidityRole                     |-> fixLiquidityRole.value,
         contraLiquidityType                  |-> contraLiquidityType.value,
         contraFixLiquidityRole               |-> contraFixLiquidityRole.value,
         secondReserved16                     |-> secondReserved16.value,
         executingMpid                        |-> executingMpid.value,
         orderDate                            |-> orderDate.value,
         fixOrderId                           |-> fixOrderId.value,
         clientOrderId                        |-> clientOrderId.value,
         clientMessageId                      |-> clientMessageId.value,
         bulkLiquidityIndex                   |-> bulkLiquidityIndex.value,
         openCloseIndicator                   |-> openCloseIndicator.value,
         liquidityType                        |-> liquidityType.value,
         liquidityIndicator                   |-> liquidityIndicator.value,
         timeInForce                          |-> timeInForce.value,
         legReferenceId                       |-> legReferenceId.value,
         stockShortSellIndicator              |-> stockShortSellIndicator.value,
         reserved14                           |-> reserved14.value,
         clearingMpid                         |-> clearingMpid.value,
         memberType                           |-> memberType.value,
         origin                               |-> origin.value,
         clearingNumber                       |-> clearingNumber.value,
         cmta                                 |-> cmta.value,
         multiAccount                         |-> multiAccount.value,
         accountId                            |-> accountId.value,
         supplementaryId                      |-> supplementaryId.value,
         allocationId                         |-> allocationId.value,
         orderCapacity                        |-> orderCapacity.value,
         reserved11                           |-> reserved11.value,
         mpid                                 |-> mpid.value,
         contraMemberType                     |-> contraMemberType.value,
         contraOrigin                         |-> contraOrigin.value,
         contraClearingNumber                 |-> contraClearingNumber.value,
         contraCmta                           |-> contraCmta.value,
         contraTimeInForce                    |-> contraTimeInForce.value,
         contraOrderCapacity                  |-> contraOrderCapacity.value,
         secondReserved14                     |-> secondReserved14.value ], secondReserved14.rest)

ZeroTradeMessage ==
    [ processingTime                       |-> [i \in 1 .. 8 |-> 0],
      tradeTime                            |-> [i \in 1 .. 8 |-> 0],
      tradeAsOfDate                        |-> [i \in 1 .. 4 |-> 0],
      tradeAction                          |-> [i \in 1 .. 1 |-> 0],
      tradeType                            |-> [i \in 1 .. 1 |-> 0],
      tradeId                              |-> [i \in 1 .. 4 |-> 0],
      executionId                          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                        |-> [i \in 1 .. 4 |-> 0],
      referenceTradeTime                   |-> [i \in 1 .. 8 |-> 0],
      referenceTradeId                     |-> [i \in 1 .. 4 |-> 0],
      referenceCorrectionNumber            |-> [i \in 1 .. 1 |-> 0],
      correctionType                       |-> [i \in 1 .. 1 |-> 0],
      strategyId                           |-> [i \in 1 .. 4 |-> 0],
      reserved16                           |-> [i \in 1 .. 16 |-> 0],
      productId                            |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol                     |-> [i \in 1 .. 11 |-> 0],
      underlyingType                       |-> [i \in 1 .. 1 |-> 0],
      securitySymbol                       |-> [i \in 1 .. 6 |-> 0],
      expirationDate                       |-> [i \in 1 .. 4 |-> 0],
      strikePrice                          |-> [i \in 1 .. 4 |-> 0],
      callOrPut                            |-> [i \in 1 .. 1 |-> 0],
      reserved8                            |-> [i \in 1 .. 8 |-> 0],
      side                                 |-> [i \in 1 .. 1 |-> 0],
      price                                |-> [i \in 1 .. 4 |-> 0],
      size                                 |-> [i \in 1 .. 4 |-> 0],
      tradeCondition                       |-> [i \in 1 .. 1 |-> 0],
      secondReserved8                      |-> [i \in 1 .. 8 |-> 0],
      classFeeType                         |-> [i \in 1 .. 1 |-> 0],
      sapphireBboPostingIncrementIndicator |-> [i \in 1 .. 1 |-> 0],
      executionExchange                    |-> [i \in 1 .. 1 |-> 0],
      routedOrderQuantity                  |-> [i \in 1 .. 4 |-> 0],
      marketState                          |-> [i \in 1 .. 1 |-> 0],
      freeTradingCondition                 |-> [i \in 1 .. 1 |-> 0],
      stockExecutionDestination            |-> [i \in 1 .. 1 |-> 0],
      fixLiquidityRole                     |-> [i \in 1 .. 1 |-> 0],
      contraLiquidityType                  |-> [i \in 1 .. 1 |-> 0],
      contraFixLiquidityRole               |-> [i \in 1 .. 1 |-> 0],
      secondReserved16                     |-> [i \in 1 .. 16 |-> 0],
      executingMpid                        |-> [i \in 1 .. 4 |-> 0],
      orderDate                            |-> [i \in 1 .. 4 |-> 0],
      fixOrderId                           |-> [i \in 1 .. 30 |-> 0],
      clientOrderId                        |-> [i \in 1 .. 4 |-> 0],
      clientMessageId                      |-> [i \in 1 .. 4 |-> 0],
      bulkLiquidityIndex                   |-> [i \in 1 .. 1 |-> 0],
      openCloseIndicator                   |-> [i \in 1 .. 1 |-> 0],
      liquidityType                        |-> [i \in 1 .. 1 |-> 0],
      liquidityIndicator                   |-> [i \in 1 .. 1 |-> 0],
      timeInForce                          |-> [i \in 1 .. 1 |-> 0],
      legReferenceId                       |-> [i \in 1 .. 5 |-> 0],
      stockShortSellIndicator              |-> [i \in 1 .. 1 |-> 0],
      reserved14                           |-> [i \in 1 .. 14 |-> 0],
      clearingMpid                         |-> [i \in 1 .. 4 |-> 0],
      memberType                           |-> [i \in 1 .. 1 |-> 0],
      origin                               |-> [i \in 1 .. 1 |-> 0],
      clearingNumber                       |-> [i \in 1 .. 4 |-> 0],
      cmta                                 |-> [i \in 1 .. 4 |-> 0],
      multiAccount                         |-> [i \in 1 .. 5 |-> 0],
      accountId                            |-> [i \in 1 .. 10 |-> 0],
      supplementaryId                      |-> [i \in 1 .. 13 |-> 0],
      allocationId                         |-> [i \in 1 .. 4 |-> 0],
      orderCapacity                        |-> [i \in 1 .. 1 |-> 0],
      reserved11                           |-> [i \in 1 .. 11 |-> 0],
      mpid                                 |-> [i \in 1 .. 4 |-> 0],
      contraMemberType                     |-> [i \in 1 .. 1 |-> 0],
      contraOrigin                         |-> [i \in 1 .. 1 |-> 0],
      contraClearingNumber                 |-> [i \in 1 .. 4 |-> 0],
      contraCmta                           |-> [i \in 1 .. 4 |-> 0],
      contraTimeInForce                    |-> [i \in 1 .. 1 |-> 0],
      contraOrderCapacity                  |-> [i \in 1 .. 1 |-> 0],
      secondReserved14                     |-> [i \in 1 .. 14 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.processingTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeAsOfDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeAction = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.referenceTradeTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.referenceTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.referenceCorrectionNumber = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.correctionType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroTradeMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeMessage EXCEPT !.underlyingType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.callOrPut = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.classFeeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.sapphireBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.executionExchange = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.routedOrderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.marketState = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.freeTradingCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.stockExecutionDestination = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.fixLiquidityRole = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.contraLiquidityType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.contraFixLiquidityRole = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.secondReserved16 = one] : one \in Sample(16) }
        \cup { [ZeroTradeMessage EXCEPT !.executingMpid = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.orderDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.fixOrderId = one] : one \in Sample(30) }
        \cup { [ZeroTradeMessage EXCEPT !.clientOrderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.clientMessageId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.bulkLiquidityIndex = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.openCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.liquidityType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.legReferenceId = one] : one \in Sample(5) }
        \cup { [ZeroTradeMessage EXCEPT !.stockShortSellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved14 = one] : one \in Sample(14) }
        \cup { [ZeroTradeMessage EXCEPT !.clearingMpid = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.memberType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.clearingNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.multiAccount = one] : one \in Sample(5) }
        \cup { [ZeroTradeMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroTradeMessage EXCEPT !.supplementaryId = one] : one \in Sample(13) }
        \cup { [ZeroTradeMessage EXCEPT !.allocationId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved11 = one] : one \in Sample(11) }
        \cup { [ZeroTradeMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraMemberType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.contraOrigin = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.contraClearingNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraCmta = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraTimeInForce = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.contraOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.secondReserved14 = one] : one \in Sample(14) }

(***************************************************************************)
(* Risk Notification Message: 160 bytes                                    *)
(***************************************************************************)

RiskNotificationMessage ==
    [ processingTime               : Sample(8),
      mpidGroupId                  : Sample(32),
      metricId                     : Sample(32),
      routeId                      : Sample(32),
      metricType                   : Sample(1),
      protectionType               : Sample(1),
      eventType                    : Sample(1),
      eventId                      : Sample(4),
      configuredCountingTimePeriod : Sample(4),
      configuredMaxQuantity        : Sample(4),
      currentQuantity              : Sample(4),
      maxPeakQuantity              : Sample(4),
      percentageLevel              : Sample(1),
      reserved32                   : Sample(32) ]

EncodeRiskNotificationMessage(message) ==
    message.processingTime
        \o message.mpidGroupId
        \o message.metricId
        \o message.routeId
        \o message.metricType
        \o message.protectionType
        \o message.eventType
        \o message.eventId
        \o message.configuredCountingTimePeriod
        \o message.configuredMaxQuantity
        \o message.currentQuantity
        \o message.maxPeakQuantity
        \o message.percentageLevel
        \o message.reserved32

DecodeRiskNotificationMessage(bytes) ==
    LET processingTime == ReadBytes(bytes, 8) IN IF ~processingTime.ok THEN Fail ELSE
    LET mpidGroupId == ReadBytes(processingTime.rest, 32) IN IF ~mpidGroupId.ok THEN Fail ELSE
    LET metricId == ReadBytes(mpidGroupId.rest, 32) IN IF ~metricId.ok THEN Fail ELSE
    LET routeId == ReadBytes(metricId.rest, 32) IN IF ~routeId.ok THEN Fail ELSE
    LET metricType == ReadBytes(routeId.rest, 1) IN IF ~metricType.ok THEN Fail ELSE
    LET protectionType == ReadBytes(metricType.rest, 1) IN IF ~protectionType.ok THEN Fail ELSE
    LET eventType == ReadBytes(protectionType.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eventType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET configuredCountingTimePeriod == ReadBytes(eventId.rest, 4) IN IF ~configuredCountingTimePeriod.ok THEN Fail ELSE
    LET configuredMaxQuantity == ReadBytes(configuredCountingTimePeriod.rest, 4) IN IF ~configuredMaxQuantity.ok THEN Fail ELSE
    LET currentQuantity == ReadBytes(configuredMaxQuantity.rest, 4) IN IF ~currentQuantity.ok THEN Fail ELSE
    LET maxPeakQuantity == ReadBytes(currentQuantity.rest, 4) IN IF ~maxPeakQuantity.ok THEN Fail ELSE
    LET percentageLevel == ReadBytes(maxPeakQuantity.rest, 1) IN IF ~percentageLevel.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(percentageLevel.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ processingTime               |-> processingTime.value,
         mpidGroupId                  |-> mpidGroupId.value,
         metricId                     |-> metricId.value,
         routeId                      |-> routeId.value,
         metricType                   |-> metricType.value,
         protectionType               |-> protectionType.value,
         eventType                    |-> eventType.value,
         eventId                      |-> eventId.value,
         configuredCountingTimePeriod |-> configuredCountingTimePeriod.value,
         configuredMaxQuantity        |-> configuredMaxQuantity.value,
         currentQuantity              |-> currentQuantity.value,
         maxPeakQuantity              |-> maxPeakQuantity.value,
         percentageLevel              |-> percentageLevel.value,
         reserved32                   |-> reserved32.value ], reserved32.rest)

ZeroRiskNotificationMessage ==
    [ processingTime               |-> [i \in 1 .. 8 |-> 0],
      mpidGroupId                  |-> [i \in 1 .. 32 |-> 0],
      metricId                     |-> [i \in 1 .. 32 |-> 0],
      routeId                      |-> [i \in 1 .. 32 |-> 0],
      metricType                   |-> [i \in 1 .. 1 |-> 0],
      protectionType               |-> [i \in 1 .. 1 |-> 0],
      eventType                    |-> [i \in 1 .. 1 |-> 0],
      eventId                      |-> [i \in 1 .. 4 |-> 0],
      configuredCountingTimePeriod |-> [i \in 1 .. 4 |-> 0],
      configuredMaxQuantity        |-> [i \in 1 .. 4 |-> 0],
      currentQuantity              |-> [i \in 1 .. 4 |-> 0],
      maxPeakQuantity              |-> [i \in 1 .. 4 |-> 0],
      percentageLevel              |-> [i \in 1 .. 1 |-> 0],
      reserved32                   |-> [i \in 1 .. 32 |-> 0] ]

(* Risk Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskNotificationMessage ==
    { ZeroRiskNotificationMessage }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.processingTime = one] : one \in Sample(8) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.mpidGroupId = one] : one \in Sample(32) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.metricId = one] : one \in Sample(32) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.routeId = one] : one \in Sample(32) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.metricType = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.protectionType = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.configuredCountingTimePeriod = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.configuredMaxQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.currentQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.maxPeakQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.percentageLevel = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationMessage EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemStateCode == 83  \* "S"
TradeMessageCode == 84  \* "T"
RiskNotificationMessageCode == 82  \* "R"

SequencedMessage ==
    [ tag : {SystemStateCode}, body : SystemState ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {RiskNotificationMessageCode}, body : RiskNotificationMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemStateCode -> EncodeSystemState(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = RiskNotificationMessageCode -> EncodeRiskNotificationMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemStateCode -> DecodeSystemState(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = RiskNotificationMessageCode -> DecodeRiskNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemStateCode, body |-> ZeroSystemState]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemStateCode, body |-> one] : one \in CheckedSystemState }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> RiskNotificationMessageCode, body |-> one] : one \in CheckedRiskNotificationMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequenceNumber   : Sample(8),
      sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    message.sequenceNumber
        \o EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sequencedMessageType == ReadUIntBE(sequenceNumber.rest, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequenceNumber   |-> sequenceNumber.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequenceNumber   |-> [i \in 1 .. 8 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Risk Notification Message: 160 bytes                                    *)
(***************************************************************************)

RiskNotificationMessage2 ==
    [ processingTime               : Sample(8),
      mpidGroupId                  : Sample(32),
      metricId                     : Sample(32),
      routeId                      : Sample(32),
      metricType                   : Sample(1),
      protectionType               : Sample(1),
      eventType                    : Sample(1),
      eventId                      : Sample(4),
      configuredCountingTimePeriod : Sample(4),
      configuredMaxQuantity        : Sample(4),
      currentQuantity              : Sample(4),
      maxPeakQuantity              : Sample(4),
      percentageLevel              : Sample(1),
      reserved32                   : Sample(32) ]

EncodeRiskNotificationMessage2(message) ==
    message.processingTime
        \o message.mpidGroupId
        \o message.metricId
        \o message.routeId
        \o message.metricType
        \o message.protectionType
        \o message.eventType
        \o message.eventId
        \o message.configuredCountingTimePeriod
        \o message.configuredMaxQuantity
        \o message.currentQuantity
        \o message.maxPeakQuantity
        \o message.percentageLevel
        \o message.reserved32

DecodeRiskNotificationMessage2(bytes) ==
    LET processingTime == ReadBytes(bytes, 8) IN IF ~processingTime.ok THEN Fail ELSE
    LET mpidGroupId == ReadBytes(processingTime.rest, 32) IN IF ~mpidGroupId.ok THEN Fail ELSE
    LET metricId == ReadBytes(mpidGroupId.rest, 32) IN IF ~metricId.ok THEN Fail ELSE
    LET routeId == ReadBytes(metricId.rest, 32) IN IF ~routeId.ok THEN Fail ELSE
    LET metricType == ReadBytes(routeId.rest, 1) IN IF ~metricType.ok THEN Fail ELSE
    LET protectionType == ReadBytes(metricType.rest, 1) IN IF ~protectionType.ok THEN Fail ELSE
    LET eventType == ReadBytes(protectionType.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eventType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET configuredCountingTimePeriod == ReadBytes(eventId.rest, 4) IN IF ~configuredCountingTimePeriod.ok THEN Fail ELSE
    LET configuredMaxQuantity == ReadBytes(configuredCountingTimePeriod.rest, 4) IN IF ~configuredMaxQuantity.ok THEN Fail ELSE
    LET currentQuantity == ReadBytes(configuredMaxQuantity.rest, 4) IN IF ~currentQuantity.ok THEN Fail ELSE
    LET maxPeakQuantity == ReadBytes(currentQuantity.rest, 4) IN IF ~maxPeakQuantity.ok THEN Fail ELSE
    LET percentageLevel == ReadBytes(maxPeakQuantity.rest, 1) IN IF ~percentageLevel.ok THEN Fail ELSE
    LET reserved32 == ReadBytes(percentageLevel.rest, 32) IN IF ~reserved32.ok THEN Fail ELSE
    Ok([ processingTime               |-> processingTime.value,
         mpidGroupId                  |-> mpidGroupId.value,
         metricId                     |-> metricId.value,
         routeId                      |-> routeId.value,
         metricType                   |-> metricType.value,
         protectionType               |-> protectionType.value,
         eventType                    |-> eventType.value,
         eventId                      |-> eventId.value,
         configuredCountingTimePeriod |-> configuredCountingTimePeriod.value,
         configuredMaxQuantity        |-> configuredMaxQuantity.value,
         currentQuantity              |-> currentQuantity.value,
         maxPeakQuantity              |-> maxPeakQuantity.value,
         percentageLevel              |-> percentageLevel.value,
         reserved32                   |-> reserved32.value ], reserved32.rest)

ZeroRiskNotificationMessage2 ==
    [ processingTime               |-> [i \in 1 .. 8 |-> 0],
      mpidGroupId                  |-> [i \in 1 .. 32 |-> 0],
      metricId                     |-> [i \in 1 .. 32 |-> 0],
      routeId                      |-> [i \in 1 .. 32 |-> 0],
      metricType                   |-> [i \in 1 .. 1 |-> 0],
      protectionType               |-> [i \in 1 .. 1 |-> 0],
      eventType                    |-> [i \in 1 .. 1 |-> 0],
      eventId                      |-> [i \in 1 .. 4 |-> 0],
      configuredCountingTimePeriod |-> [i \in 1 .. 4 |-> 0],
      configuredMaxQuantity        |-> [i \in 1 .. 4 |-> 0],
      currentQuantity              |-> [i \in 1 .. 4 |-> 0],
      maxPeakQuantity              |-> [i \in 1 .. 4 |-> 0],
      percentageLevel              |-> [i \in 1 .. 1 |-> 0],
      reserved32                   |-> [i \in 1 .. 32 |-> 0] ]

(* Risk Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedRiskNotificationMessage2 ==
    { ZeroRiskNotificationMessage2 }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.processingTime = one] : one \in Sample(8) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.mpidGroupId = one] : one \in Sample(32) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.metricId = one] : one \in Sample(32) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.routeId = one] : one \in Sample(32) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.metricType = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.protectionType = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.configuredCountingTimePeriod = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.configuredMaxQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.currentQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.maxPeakQuantity = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.percentageLevel = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationMessage2 EXCEPT !.reserved32 = one] : one \in Sample(32) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

RiskNotificationMessageCode2 == 82  \* "R"

UnsequencedMessage ==
    [ tag : {RiskNotificationMessageCode2}, body : RiskNotificationMessage2 ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = RiskNotificationMessageCode2 -> EncodeRiskNotificationMessage2(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = RiskNotificationMessageCode2 -> DecodeRiskNotificationMessage2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> RiskNotificationMessageCode2, body |-> ZeroRiskNotificationMessage2]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> RiskNotificationMessageCode2, body |-> one] : one \in CheckedRiskNotificationMessage2 }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Login Request: 35 bytes                                                 *)
(***************************************************************************)

LoginRequest ==
    [ sesmVersion             : Sample(5),
      username                : Sample(5),
      computerId              : Sample(8),
      applicationProtocol     : Sample(8),
      requestedSession        : Sample(1),
      requestedSequenceNumber : Sample(8) ]

EncodeLoginRequest(message) ==
    message.sesmVersion
        \o message.username
        \o message.computerId
        \o message.applicationProtocol
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequest(bytes) ==
    LET sesmVersion == ReadBytes(bytes, 5) IN IF ~sesmVersion.ok THEN Fail ELSE
    LET username == ReadBytes(sesmVersion.rest, 5) IN IF ~username.ok THEN Fail ELSE
    LET computerId == ReadBytes(username.rest, 8) IN IF ~computerId.ok THEN Fail ELSE
    LET applicationProtocol == ReadBytes(computerId.rest, 8) IN IF ~applicationProtocol.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(applicationProtocol.rest, 1) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 8) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ sesmVersion             |-> sesmVersion.value,
         username                |-> username.value,
         computerId              |-> computerId.value,
         applicationProtocol     |-> applicationProtocol.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequest ==
    [ sesmVersion             |-> [i \in 1 .. 5 |-> 0],
      username                |-> [i \in 1 .. 5 |-> 0],
      computerId              |-> [i \in 1 .. 8 |-> 0],
      applicationProtocol     |-> [i \in 1 .. 8 |-> 0],
      requestedSession        |-> [i \in 1 .. 1 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Request at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequest ==
    { ZeroLoginRequest }
        \cup { [ZeroLoginRequest EXCEPT !.sesmVersion = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.username = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.computerId = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.applicationProtocol = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSession = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Login Response: 10 bytes                                                *)
(***************************************************************************)

LoginResponse ==
    [ loginStatus           : Sample(1),
      sessionId             : Sample(1),
      highestSequenceNumber : Sample(8) ]

EncodeLoginResponse(message) ==
    message.loginStatus
        \o message.sessionId
        \o message.highestSequenceNumber

DecodeLoginResponse(bytes) ==
    LET loginStatus == ReadBytes(bytes, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    LET sessionId == ReadBytes(loginStatus.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET highestSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~highestSequenceNumber.ok THEN Fail ELSE
    Ok([ loginStatus           |-> loginStatus.value,
         sessionId             |-> sessionId.value,
         highestSequenceNumber |-> highestSequenceNumber.value ], highestSequenceNumber.rest)

ZeroLoginResponse ==
    [ loginStatus           |-> [i \in 1 .. 1 |-> 0],
      sessionId             |-> [i \in 1 .. 1 |-> 0],
      highestSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.loginStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.highestSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Retransmission Request: 16 bytes                                        *)
(***************************************************************************)

RetransmissionRequest ==
    [ startSequenceNumber : Sample(8),
      endSequenceNumber   : Sample(8) ]

EncodeRetransmissionRequest(message) ==
    message.startSequenceNumber
        \o message.endSequenceNumber

DecodeRetransmissionRequest(bytes) ==
    LET startSequenceNumber == ReadBytes(bytes, 8) IN IF ~startSequenceNumber.ok THEN Fail ELSE
    LET endSequenceNumber == ReadBytes(startSequenceNumber.rest, 8) IN IF ~endSequenceNumber.ok THEN Fail ELSE
    Ok([ startSequenceNumber |-> startSequenceNumber.value,
         endSequenceNumber   |-> endSequenceNumber.value ], endSequenceNumber.rest)

ZeroRetransmissionRequest ==
    [ startSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      endSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Retransmission Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequest ==
    { ZeroRetransmissionRequest }
        \cup { [ZeroRetransmissionRequest EXCEPT !.startSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionRequest EXCEPT !.endSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Logout Request                                                          *)
(***************************************************************************)

LogoutRequest ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeLogoutRequest(message) ==
    message.logoutReason
        \o message.logoutText

DecodeLogoutRequest(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroLogoutRequest ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Goodbye Packet                                                          *)
(***************************************************************************)

GoodbyePacket ==
    [ goodbyeReason : Sample(1),
      logoutText    : SampleBytes ]

EncodeGoodbyePacket(message) ==
    message.goodbyeReason
        \o message.logoutText

DecodeGoodbyePacket(bytes) ==
    LET goodbyeReason == ReadBytes(bytes, 1) IN IF ~goodbyeReason.ok THEN Fail ELSE
    LET logoutText == Ok(goodbyeReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ goodbyeReason |-> goodbyeReason.value,
         logoutText    |-> logoutText.value ], logoutText.rest)

ZeroGoodbyePacket ==
    [ goodbyeReason |-> [i \in 1 .. 1 |-> 0],
      logoutText    |-> << >> ]

(* Goodbye Packet at zero, then each field in turn at the values it is checked at *)
CheckedGoodbyePacket ==
    { ZeroGoodbyePacket }
        \cup { [ZeroGoodbyePacket EXCEPT !.goodbyeReason = one] : one \in Sample(1) }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Test Packet                                                             *)
(***************************************************************************)

TestPacket ==
    [ testText : SampleBytes ]

EncodeTestPacket(message) ==
    message.testText

DecodeTestPacket(bytes) ==
    LET testText == Ok(bytes, << >>) IN IF ~testText.ok THEN Fail ELSE
    Ok([ testText |-> testText.value ], testText.rest)

ZeroTestPacket ==
    [ testText |-> << >> ]

(* Test Packet at zero, then each field in turn at the values it is checked at *)
CheckedTestPacket ==
    { ZeroTestPacket }
        \cup { [ZeroTestPacket EXCEPT !.testText = one] : one \in SampleBytes }

(***************************************************************************)
(* Sesm Payload, selected by Sesm Packet Type                              *)
(***************************************************************************)

SequencedDataPacketCode == 83  \* "S"
UnsequencedDataPacketCode == 85  \* "U"
LoginRequestCode == 76  \* "L"
LoginResponseCode == 82  \* "R"
SynchronizationCompleteCode == 67  \* "C"
RetransmissionRequestCode == 65  \* "A"
LogoutRequestCode == 88  \* "X"
GoodbyePacketCode == 71  \* "G"
EndOfSessionCode == 69  \* "E"
ServerHeartbeatCode == 48  \* "0"
ClientHeartbeatCode == 49  \* "1"
TestPacketCode == 84  \* "T"

SesmPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {LoginRequestCode}, body : LoginRequest ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {SynchronizationCompleteCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RetransmissionRequestCode}, body : RetransmissionRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {GoodbyePacketCode}, body : GoodbyePacket ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestPacketCode}, body : TestPacket ]

EncodeSesmPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = LoginRequestCode -> EncodeLoginRequest(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = SynchronizationCompleteCode -> << >>
      [] message.tag = RetransmissionRequestCode -> EncodeRetransmissionRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = GoodbyePacketCode -> EncodeGoodbyePacket(message.body)
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = TestPacketCode -> EncodeTestPacket(message.body)

DecodeSesmPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = LoginRequestCode -> DecodeLoginRequest(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = SynchronizationCompleteCode -> Ok([empty |-> 0], bytes)
              [] tag = RetransmissionRequestCode -> DecodeRetransmissionRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = GoodbyePacketCode -> DecodeGoodbyePacket(bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = TestPacketCode -> DecodeTestPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSesmPayload == [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]

(* Each Sesm Payload in turn, at the values the message it names is checked at *)
CheckedSesmPayload ==
    { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> LoginRequestCode, body |-> one] : one \in CheckedLoginRequest }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> SynchronizationCompleteCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RetransmissionRequestCode, body |-> one] : one \in CheckedRetransmissionRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> GoodbyePacketCode, body |-> one] : one \in CheckedGoodbyePacket }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestPacketCode, body |-> one] : one \in CheckedTestPacket }

(***************************************************************************)
(* Sesm Tcp Packet, framed by Sesm Packet Length                           *)
(***************************************************************************)

SesmTcpPacket ==
    [ sesmPayload : SesmPayload ]

EncodeSesmTcpPacketBody(message) ==
    EncodeUIntBE(message.sesmPayload.tag, 1)
        \o EncodeSesmPayload(message.sesmPayload)

(* Sesm Packet Length counts the bytes it frames, so it is written from them *)
EncodeSesmTcpPacket(message) ==
    LET body == EncodeSesmTcpPacketBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeSesmTcpPacketBody(bytes) ==
    LET sesmPacketType == ReadUIntBE(bytes, 1) IN IF ~sesmPacketType.ok THEN Fail ELSE
    LET sesmPayload == DecodeSesmPayload(sesmPacketType.value, sesmPacketType.rest) IN IF ~sesmPayload.ok THEN Fail ELSE
    Ok([ sesmPayload |-> sesmPayload.value ], sesmPayload.rest)

DecodeSesmTcpPacket(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeSesmTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSesmTcpPacket ==
    [ sesmPayload |-> ZeroSesmPayload ]

(* Sesm Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedSesmTcpPacket ==
    { ZeroSesmTcpPacket }
        \cup { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = one] : one \in CheckedSesmPayload }

(* Does a Sesm Tcp Packet end the session? Nothing may follow one that does *)
EndsSessionSesmTcpPacket(message) == message.sesmPayload.tag \in {EndOfSessionCode}

(* A run of Sesm Tcp Packet, written one after another *)
RECURSIVE EncodeSesmTcpPacketList(_)
EncodeSesmTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSesmTcpPacket(Head(messages)) \o EncodeSesmTcpPacketList(Tail(messages))

(* As many Sesm Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
(* Only the last of them may end the session, so one that does with bytes left fails *)
RECURSIVE ReadSesmTcpPacketAll(_)
ReadSesmTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSesmTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE IF EndsSessionSesmTcpPacket(one.value) /\ one.rest # << >> THEN Fail
             ELSE LET more == ReadSesmTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sesm Tcp Packet of each kind, for the lists that carry them *)
OneSesmTcpPacket ==
    { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginRequestCode, body |-> ZeroLoginRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SynchronizationCompleteCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> RetransmissionRequestCode, body |-> ZeroRetransmissionRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> GoodbyePacketCode, body |-> ZeroGoodbyePacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> TestPacketCode, body |-> ZeroTestPacket]] }

(* The runs of Sesm Tcp Packet checked: none, one, two of a kind and each kind followed by *)
(* another, keeping those in which only the last may end the session *)
SampleSesmTcpPacketLists ==
    { run \in SampleLists(OneSesmTcpPacket) \cup { <<one, other>> : one \in OneSesmTcpPacket, other \in OneSesmTcpPacket } :
          \A at \in 1 .. Len(run) - 1 : ~EndsSessionSesmTcpPacket(run[at]) }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sesmTcpPacket : SampleSesmTcpPacketLists ]

EncodePacket(message) ==
    EncodeSesmTcpPacketList(message.sesmTcpPacket)

DecodePacket(bytes) ==
    LET sesmTcpPacket == ReadSesmTcpPacketAll(bytes) IN IF ~sesmTcpPacket.ok THEN Fail ELSE
    Ok([ sesmTcpPacket |-> sesmTcpPacket.value ], sesmTcpPacket.rest)

ZeroPacket ==
    [ sesmTcpPacket |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sesmTcpPacket = one] : one \in SampleSesmTcpPacketLists }

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

(* Every System State decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemState ==
    \A message \in CheckedSystemState :
        LET read == DecodeSystemState(EncodeSystemState(message))
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

(* Every Risk Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskNotificationMessage ==
    \A message \in CheckedRiskNotificationMessage :
        LET read == DecodeRiskNotificationMessage(EncodeRiskNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskNotificationMessage2 ==
    \A message \in CheckedRiskNotificationMessage2 :
        LET read == DecodeRiskNotificationMessage2(EncodeRiskNotificationMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequest ==
    \A message \in CheckedLoginRequest :
        LET read == DecodeLoginRequest(EncodeLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET read == DecodeLoginResponse(EncodeLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequest ==
    \A message \in CheckedRetransmissionRequest :
        LET read == DecodeRetransmissionRequest(EncodeRetransmissionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Goodbye Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripGoodbyePacket ==
    \A message \in CheckedGoodbyePacket :
        LET read == DecodeGoodbyePacket(EncodeGoodbyePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTestPacket ==
    \A message \in CheckedTestPacket :
        LET read == DecodeTestPacket(EncodeTestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sesm Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET read == DecodeSesmTcpPacket(EncodeSesmTcpPacket(message))
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

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET sent == EncodeSequencedMessage(message)
            read == DecodeSequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET sent == EncodeUnsequencedMessage(message)
            read == DecodeUnsequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sesm Payload is selected by the Sesm Packet Type it is written under *)
SelectsSesmPayload ==
    \A message \in CheckedSesmPayload :
        LET sent == EncodeSesmPayload(message)
            read == DecodeSesmPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Sesm Packet Length is written from the bytes it frames *)
FramesSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET bytes == EncodeSesmTcpPacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

(* A Sesm Tcp Packet that ends the session is the last of its Packet: a run with one after it does not decode *)
EndsSessionLastSesmTcpPacket ==
    \A last \in { one \in OneSesmTcpPacket : EndsSessionSesmTcpPacket(one) } :
        \A after \in OneSesmTcpPacket :
            ~ReadSesmTcpPacketAll(EncodeSesmTcpPacketList(<<last, after>>)).ok

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
