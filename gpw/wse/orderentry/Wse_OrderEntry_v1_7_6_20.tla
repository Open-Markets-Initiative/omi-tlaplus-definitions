--------------------- MODULE Wse_OrderEntry_v1_7_6_20 ----------------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie Warsaw Stock Exchange Native  *)
(* Order Gateway v1.7.6                                                    *)
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
(* Note: Items Quotes Array is written as 30 slots, however many of them   *)
(* the count beside it says are in use.                                    *)
(*                                                                         *)
(* Note: Items Quote Order Response Array is written as 30 slots, however  *)
(* many of them the count beside it says are in use.                       *)
(*                                                                         *)
(* Note: Message is of no one width: each is read by its own fields, and   *)
(* since every reading of it takes at least 24 bytes off the reader the    *)
(* run ends where the data does.                                           *)
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
(* Login: 20 bytes                                                         *)
(***************************************************************************)

Login ==
    [ version            : Sample(2),
      token              : Sample(8),
      connectionId       : Sample(2),
      nextExpectedSeqNum : Sample(4),
      lastSentSeqNum     : Sample(4) ]

EncodeLogin(message) ==
    message.version
        \o message.token
        \o message.connectionId
        \o message.nextExpectedSeqNum
        \o message.lastSentSeqNum

DecodeLogin(bytes) ==
    LET version == ReadBytes(bytes, 2) IN IF ~version.ok THEN Fail ELSE
    LET token == ReadBytes(version.rest, 8) IN IF ~token.ok THEN Fail ELSE
    LET connectionId == ReadBytes(token.rest, 2) IN IF ~connectionId.ok THEN Fail ELSE
    LET nextExpectedSeqNum == ReadBytes(connectionId.rest, 4) IN IF ~nextExpectedSeqNum.ok THEN Fail ELSE
    LET lastSentSeqNum == ReadBytes(nextExpectedSeqNum.rest, 4) IN IF ~lastSentSeqNum.ok THEN Fail ELSE
    Ok([ version            |-> version.value,
         token              |-> token.value,
         connectionId       |-> connectionId.value,
         nextExpectedSeqNum |-> nextExpectedSeqNum.value,
         lastSentSeqNum     |-> lastSentSeqNum.value ], lastSentSeqNum.rest)

ZeroLogin ==
    [ version            |-> [i \in 1 .. 2 |-> 0],
      token              |-> [i \in 1 .. 8 |-> 0],
      connectionId       |-> [i \in 1 .. 2 |-> 0],
      nextExpectedSeqNum |-> [i \in 1 .. 4 |-> 0],
      lastSentSeqNum     |-> [i \in 1 .. 4 |-> 0] ]

(* Login at zero, then each field in turn at the values it is checked at *)
CheckedLogin ==
    { ZeroLogin }
        \cup { [ZeroLogin EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroLogin EXCEPT !.token = one] : one \in Sample(8) }
        \cup { [ZeroLogin EXCEPT !.connectionId = one] : one \in Sample(2) }
        \cup { [ZeroLogin EXCEPT !.nextExpectedSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroLogin EXCEPT !.lastSentSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Login Response: 11 bytes                                                *)
(***************************************************************************)

LoginResponse ==
    [ resultLoginResult  : Sample(1),
      nextExpectedSeqNum : Sample(4),
      lastReplaySeqNum   : Sample(4),
      sessionId          : Sample(2) ]

EncodeLoginResponse(message) ==
    message.resultLoginResult
        \o message.nextExpectedSeqNum
        \o message.lastReplaySeqNum
        \o message.sessionId

DecodeLoginResponse(bytes) ==
    LET resultLoginResult == ReadBytes(bytes, 1) IN IF ~resultLoginResult.ok THEN Fail ELSE
    LET nextExpectedSeqNum == ReadBytes(resultLoginResult.rest, 4) IN IF ~nextExpectedSeqNum.ok THEN Fail ELSE
    LET lastReplaySeqNum == ReadBytes(nextExpectedSeqNum.rest, 4) IN IF ~lastReplaySeqNum.ok THEN Fail ELSE
    LET sessionId == ReadBytes(lastReplaySeqNum.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ resultLoginResult  |-> resultLoginResult.value,
         nextExpectedSeqNum |-> nextExpectedSeqNum.value,
         lastReplaySeqNum   |-> lastReplaySeqNum.value,
         sessionId          |-> sessionId.value ], sessionId.rest)

ZeroLoginResponse ==
    [ resultLoginResult  |-> [i \in 1 .. 1 |-> 0],
      nextExpectedSeqNum |-> [i \in 1 .. 4 |-> 0],
      lastReplaySeqNum   |-> [i \in 1 .. 4 |-> 0],
      sessionId          |-> [i \in 1 .. 2 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.resultLoginResult = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.nextExpectedSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroLoginResponse EXCEPT !.lastReplaySeqNum = one] : one \in Sample(4) }
        \cup { [ZeroLoginResponse EXCEPT !.sessionId = one] : one \in Sample(2) }

(***************************************************************************)
(* Connection Close: 1 bytes                                               *)
(***************************************************************************)

ConnectionClose ==
    [ reasonConnectionCloseReason : Sample(1) ]

EncodeConnectionClose(message) ==
    message.reasonConnectionCloseReason

DecodeConnectionClose(bytes) ==
    LET reasonConnectionCloseReason == ReadBytes(bytes, 1) IN IF ~reasonConnectionCloseReason.ok THEN Fail ELSE
    Ok([ reasonConnectionCloseReason |-> reasonConnectionCloseReason.value ], reasonConnectionCloseReason.rest)

ZeroConnectionClose ==
    [ reasonConnectionCloseReason |-> [i \in 1 .. 1 |-> 0] ]

(* Connection Close at zero, then each field in turn at the values it is checked at *)
CheckedConnectionClose ==
    { ZeroConnectionClose }
        \cup { [ZeroConnectionClose EXCEPT !.reasonConnectionCloseReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Reject: 5 bytes                                                         *)
(***************************************************************************)

Reject ==
    [ refSeqNum    : Sample(4),
      rejectReason : Sample(1) ]

EncodeReject(message) ==
    message.refSeqNum
        \o message.rejectReason

DecodeReject(bytes) ==
    LET refSeqNum == ReadBytes(bytes, 4) IN IF ~refSeqNum.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(refSeqNum.rest, 1) IN IF ~rejectReason.ok THEN Fail ELSE
    Ok([ refSeqNum    |-> refSeqNum.value,
         rejectReason |-> rejectReason.value ], rejectReason.rest)

ZeroReject ==
    [ refSeqNum    |-> [i \in 1 .. 4 |-> 0],
      rejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Reject at zero, then each field in turn at the values it is checked at *)
CheckedReject ==
    { ZeroReject }
        \cup { [ZeroReject EXCEPT !.refSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroReject EXCEPT !.rejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Test: 8 bytes                                                           *)
(***************************************************************************)

Test ==
    [ targetTimestamp : Sample(8) ]

EncodeTest(message) ==
    message.targetTimestamp

DecodeTest(bytes) ==
    LET targetTimestamp == ReadBytes(bytes, 8) IN IF ~targetTimestamp.ok THEN Fail ELSE
    Ok([ targetTimestamp |-> targetTimestamp.value ], targetTimestamp.rest)

ZeroTest ==
    [ targetTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Test at zero, then each field in turn at the values it is checked at *)
CheckedTest ==
    { ZeroTest }
        \cup { [ZeroTest EXCEPT !.targetTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Test Event: 201 bytes                                                   *)
(***************************************************************************)

TestEvent ==
    [ scenarioName : Sample(200),
      eventType    : Sample(1) ]

EncodeTestEvent(message) ==
    message.scenarioName
        \o message.eventType

DecodeTestEvent(bytes) ==
    LET scenarioName == ReadBytes(bytes, 200) IN IF ~scenarioName.ok THEN Fail ELSE
    LET eventType == ReadBytes(scenarioName.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    Ok([ scenarioName |-> scenarioName.value,
         eventType    |-> eventType.value ], eventType.rest)

ZeroTestEvent ==
    [ scenarioName |-> [i \in 1 .. 200 |-> 0],
      eventType    |-> [i \in 1 .. 1 |-> 0] ]

(* Test Event at zero, then each field in turn at the values it is checked at *)
CheckedTestEvent ==
    { ZeroTestEvent }
        \cup { [ZeroTestEvent EXCEPT !.scenarioName = one] : one \in Sample(200) }
        \cup { [ZeroTestEvent EXCEPT !.eventType = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Session Status: 9 bytes                                         *)
(***************************************************************************)

TradingSessionStatus ==
    [ marketId            : Sample(4),
      date                : Sample(4),
      tradingSessionEvent : Sample(1) ]

EncodeTradingSessionStatus(message) ==
    message.marketId
        \o message.date
        \o message.tradingSessionEvent

DecodeTradingSessionStatus(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET date == ReadBytes(marketId.rest, 4) IN IF ~date.ok THEN Fail ELSE
    LET tradingSessionEvent == ReadBytes(date.rest, 1) IN IF ~tradingSessionEvent.ok THEN Fail ELSE
    Ok([ marketId            |-> marketId.value,
         date                |-> date.value,
         tradingSessionEvent |-> tradingSessionEvent.value ], tradingSessionEvent.rest)

ZeroTradingSessionStatus ==
    [ marketId            |-> [i \in 1 .. 4 |-> 0],
      date                |-> [i \in 1 .. 4 |-> 0],
      tradingSessionEvent |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Session Status at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatus ==
    { ZeroTradingSessionStatus }
        \cup { [ZeroTradingSessionStatus EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatus EXCEPT !.date = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatus EXCEPT !.tradingSessionEvent = one] : one \in Sample(1) }

(***************************************************************************)
(* Client: 5 bytes                                                         *)
(***************************************************************************)

Client ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeClient(message) ==
    message.shortCode
        \o message.qualifier

DecodeClient(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroClient ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Client at zero, then each field in turn at the values it is checked at *)
CheckedClient ==
    { ZeroClient }
        \cup { [ZeroClient EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroClient EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Executing Trader: 5 bytes                                               *)
(***************************************************************************)

ExecutingTrader ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeExecutingTrader(message) ==
    message.shortCode
        \o message.qualifier

DecodeExecutingTrader(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroExecutingTrader ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Executing Trader at zero, then each field in turn at the values it is checked at *)
CheckedExecutingTrader ==
    { ZeroExecutingTrader }
        \cup { [ZeroExecutingTrader EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutingTrader EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Investment Decision Maker: 5 bytes                                      *)
(***************************************************************************)

InvestmentDecisionMaker ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeInvestmentDecisionMaker(message) ==
    message.shortCode
        \o message.qualifier

DecodeInvestmentDecisionMaker(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroInvestmentDecisionMaker ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Investment Decision Maker at zero, then each field in turn at the values it is checked at *)
CheckedInvestmentDecisionMaker ==
    { ZeroInvestmentDecisionMaker }
        \cup { [ZeroInvestmentDecisionMaker EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestmentDecisionMaker EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Fields: 15 bytes                                                  *)
(***************************************************************************)

MifidFields ==
    [ client                  : Client,
      executingTrader         : ExecutingTrader,
      investmentDecisionMaker : InvestmentDecisionMaker ]

EncodeMifidFields(message) ==
    EncodeClient(message.client)
        \o EncodeExecutingTrader(message.executingTrader)
        \o EncodeInvestmentDecisionMaker(message.investmentDecisionMaker)

DecodeMifidFields(bytes) ==
    LET client == DecodeClient(bytes) IN IF ~client.ok THEN Fail ELSE
    LET executingTrader == DecodeExecutingTrader(client.rest) IN IF ~executingTrader.ok THEN Fail ELSE
    LET investmentDecisionMaker == DecodeInvestmentDecisionMaker(executingTrader.rest) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    Ok([ client                  |-> client.value,
         executingTrader         |-> executingTrader.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value ], investmentDecisionMaker.rest)

ZeroMifidFields ==
    [ client                  |-> ZeroClient,
      executingTrader         |-> ZeroExecutingTrader,
      investmentDecisionMaker |-> ZeroInvestmentDecisionMaker ]

(* Mifid Fields at zero, then each field in turn at the values it is checked at *)
CheckedMifidFields ==
    { ZeroMifidFields }
        \cup { [ZeroMifidFields EXCEPT !.client = one] : one \in CheckedClient }
        \cup { [ZeroMifidFields EXCEPT !.executingTrader = one] : one \in CheckedExecutingTrader }
        \cup { [ZeroMifidFields EXCEPT !.investmentDecisionMaker = one] : one \in CheckedInvestmentDecisionMaker }

(***************************************************************************)
(* Order Add: 151 bytes                                                    *)
(***************************************************************************)

OrderAdd ==
    [ stpId                            : Sample(1),
      instrumentId                     : Sample(4),
      orderType                        : Sample(1),
      timeInForce                      : Sample(1),
      side                             : Sample(1),
      price                            : Sample(8),
      triggerPrice                     : Sample(8),
      quantity                         : Sample(8),
      displayQty                       : Sample(8),
      capacity                         : Sample(1),
      account                          : Sample(16),
      accountType                      : Sample(1),
      flags                            : Sample(1),
      mifidFields                      : MifidFields,
      expire                           : Sample(8),
      memo                             : Sample(18),
      clientOrderId                    : Sample(20),
      clearingMemberCode               : Sample(20),
      clearingMemberClearingIdentifier : Sample(1),
      execInst                         : Sample(1),
      feeStructureId                   : Sample(1),
      interestedParty                  : Sample(8) ]

EncodeOrderAdd(message) ==
    message.stpId
        \o message.instrumentId
        \o message.orderType
        \o message.timeInForce
        \o message.side
        \o message.price
        \o message.triggerPrice
        \o message.quantity
        \o message.displayQty
        \o message.capacity
        \o message.account
        \o message.accountType
        \o message.flags
        \o EncodeMifidFields(message.mifidFields)
        \o message.expire
        \o message.memo
        \o message.clientOrderId
        \o message.clearingMemberCode
        \o message.clearingMemberClearingIdentifier
        \o message.execInst
        \o message.feeStructureId
        \o message.interestedParty

DecodeOrderAdd(bytes) ==
    LET stpId == ReadBytes(bytes, 1) IN IF ~stpId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(stpId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderType == ReadBytes(instrumentId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET side == ReadBytes(timeInForce.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 8) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET quantity == ReadBytes(triggerPrice.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET displayQty == ReadBytes(quantity.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET capacity == ReadBytes(displayQty.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET accountType == ReadBytes(account.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET flags == ReadBytes(accountType.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET mifidFields == DecodeMifidFields(flags.rest) IN IF ~mifidFields.ok THEN Fail ELSE
    LET expire == ReadBytes(mifidFields.rest, 8) IN IF ~expire.ok THEN Fail ELSE
    LET memo == ReadBytes(expire.rest, 18) IN IF ~memo.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(memo.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clearingMemberCode == ReadBytes(clientOrderId.rest, 20) IN IF ~clearingMemberCode.ok THEN Fail ELSE
    LET clearingMemberClearingIdentifier == ReadBytes(clearingMemberCode.rest, 1) IN IF ~clearingMemberClearingIdentifier.ok THEN Fail ELSE
    LET execInst == ReadBytes(clearingMemberClearingIdentifier.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET feeStructureId == ReadBytes(execInst.rest, 1) IN IF ~feeStructureId.ok THEN Fail ELSE
    LET interestedParty == ReadBytes(feeStructureId.rest, 8) IN IF ~interestedParty.ok THEN Fail ELSE
    Ok([ stpId                            |-> stpId.value,
         instrumentId                     |-> instrumentId.value,
         orderType                        |-> orderType.value,
         timeInForce                      |-> timeInForce.value,
         side                             |-> side.value,
         price                            |-> price.value,
         triggerPrice                     |-> triggerPrice.value,
         quantity                         |-> quantity.value,
         displayQty                       |-> displayQty.value,
         capacity                         |-> capacity.value,
         account                          |-> account.value,
         accountType                      |-> accountType.value,
         flags                            |-> flags.value,
         mifidFields                      |-> mifidFields.value,
         expire                           |-> expire.value,
         memo                             |-> memo.value,
         clientOrderId                    |-> clientOrderId.value,
         clearingMemberCode               |-> clearingMemberCode.value,
         clearingMemberClearingIdentifier |-> clearingMemberClearingIdentifier.value,
         execInst                         |-> execInst.value,
         feeStructureId                   |-> feeStructureId.value,
         interestedParty                  |-> interestedParty.value ], interestedParty.rest)

ZeroOrderAdd ==
    [ stpId                            |-> [i \in 1 .. 1 |-> 0],
      instrumentId                     |-> [i \in 1 .. 4 |-> 0],
      orderType                        |-> [i \in 1 .. 1 |-> 0],
      timeInForce                      |-> [i \in 1 .. 1 |-> 0],
      side                             |-> [i \in 1 .. 1 |-> 0],
      price                            |-> [i \in 1 .. 8 |-> 0],
      triggerPrice                     |-> [i \in 1 .. 8 |-> 0],
      quantity                         |-> [i \in 1 .. 8 |-> 0],
      displayQty                       |-> [i \in 1 .. 8 |-> 0],
      capacity                         |-> [i \in 1 .. 1 |-> 0],
      account                          |-> [i \in 1 .. 16 |-> 0],
      accountType                      |-> [i \in 1 .. 1 |-> 0],
      flags                            |-> [i \in 1 .. 1 |-> 0],
      mifidFields                      |-> ZeroMifidFields,
      expire                           |-> [i \in 1 .. 8 |-> 0],
      memo                             |-> [i \in 1 .. 18 |-> 0],
      clientOrderId                    |-> [i \in 1 .. 20 |-> 0],
      clearingMemberCode               |-> [i \in 1 .. 20 |-> 0],
      clearingMemberClearingIdentifier |-> [i \in 1 .. 1 |-> 0],
      execInst                         |-> [i \in 1 .. 1 |-> 0],
      feeStructureId                   |-> [i \in 1 .. 1 |-> 0],
      interestedParty                  |-> [i \in 1 .. 8 |-> 0] ]

(* Order Add at zero, then each field in turn at the values it is checked at *)
CheckedOrderAdd ==
    { ZeroOrderAdd }
        \cup { [ZeroOrderAdd EXCEPT !.stpId = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAdd EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.triggerPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroOrderAdd EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.mifidFields = one] : one \in CheckedMifidFields }
        \cup { [ZeroOrderAdd EXCEPT !.expire = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.memo = one] : one \in Sample(18) }
        \cup { [ZeroOrderAdd EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderAdd EXCEPT !.clearingMemberCode = one] : one \in Sample(20) }
        \cup { [ZeroOrderAdd EXCEPT !.clearingMemberClearingIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.feeStructureId = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.interestedParty = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Add Response: 56 bytes                                            *)
(***************************************************************************)

OrderAddResponse ==
    [ orderId                    : Sample(8),
      publicOrderId              : Sample(8),
      displayQty                 : Sample(8),
      filled                     : Sample(8),
      statusOrderStatus          : Sample(1),
      reasonOrderRejectionReason : Sample(2),
      execTypeReason             : Sample(1),
      clientOrderId              : Sample(20) ]

EncodeOrderAddResponse(message) ==
    message.orderId
        \o message.publicOrderId
        \o message.displayQty
        \o message.filled
        \o message.statusOrderStatus
        \o message.reasonOrderRejectionReason
        \o message.execTypeReason
        \o message.clientOrderId

DecodeOrderAddResponse(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET publicOrderId == ReadBytes(orderId.rest, 8) IN IF ~publicOrderId.ok THEN Fail ELSE
    LET displayQty == ReadBytes(publicOrderId.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET filled == ReadBytes(displayQty.rest, 8) IN IF ~filled.ok THEN Fail ELSE
    LET statusOrderStatus == ReadBytes(filled.rest, 1) IN IF ~statusOrderStatus.ok THEN Fail ELSE
    LET reasonOrderRejectionReason == ReadBytes(statusOrderStatus.rest, 2) IN IF ~reasonOrderRejectionReason.ok THEN Fail ELSE
    LET execTypeReason == ReadBytes(reasonOrderRejectionReason.rest, 1) IN IF ~execTypeReason.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execTypeReason.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ orderId                    |-> orderId.value,
         publicOrderId              |-> publicOrderId.value,
         displayQty                 |-> displayQty.value,
         filled                     |-> filled.value,
         statusOrderStatus          |-> statusOrderStatus.value,
         reasonOrderRejectionReason |-> reasonOrderRejectionReason.value,
         execTypeReason             |-> execTypeReason.value,
         clientOrderId              |-> clientOrderId.value ], clientOrderId.rest)

ZeroOrderAddResponse ==
    [ orderId                    |-> [i \in 1 .. 8 |-> 0],
      publicOrderId              |-> [i \in 1 .. 8 |-> 0],
      displayQty                 |-> [i \in 1 .. 8 |-> 0],
      filled                     |-> [i \in 1 .. 8 |-> 0],
      statusOrderStatus          |-> [i \in 1 .. 1 |-> 0],
      reasonOrderRejectionReason |-> [i \in 1 .. 2 |-> 0],
      execTypeReason             |-> [i \in 1 .. 1 |-> 0],
      clientOrderId              |-> [i \in 1 .. 20 |-> 0] ]

(* Order Add Response at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddResponse ==
    { ZeroOrderAddResponse }
        \cup { [ZeroOrderAddResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddResponse EXCEPT !.publicOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddResponse EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddResponse EXCEPT !.filled = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddResponse EXCEPT !.statusOrderStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddResponse EXCEPT !.reasonOrderRejectionReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddResponse EXCEPT !.execTypeReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Client: 5 bytes                                                         *)
(***************************************************************************)

Client2 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeClient2(message) ==
    message.shortCode
        \o message.qualifier

DecodeClient2(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroClient2 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Client at zero, then each field in turn at the values it is checked at *)
CheckedClient2 ==
    { ZeroClient2 }
        \cup { [ZeroClient2 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroClient2 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Executing Trader: 5 bytes                                               *)
(***************************************************************************)

ExecutingTrader2 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeExecutingTrader2(message) ==
    message.shortCode
        \o message.qualifier

DecodeExecutingTrader2(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroExecutingTrader2 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Executing Trader at zero, then each field in turn at the values it is checked at *)
CheckedExecutingTrader2 ==
    { ZeroExecutingTrader2 }
        \cup { [ZeroExecutingTrader2 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutingTrader2 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Investment Decision Maker: 5 bytes                                      *)
(***************************************************************************)

InvestmentDecisionMaker2 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeInvestmentDecisionMaker2(message) ==
    message.shortCode
        \o message.qualifier

DecodeInvestmentDecisionMaker2(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroInvestmentDecisionMaker2 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Investment Decision Maker at zero, then each field in turn at the values it is checked at *)
CheckedInvestmentDecisionMaker2 ==
    { ZeroInvestmentDecisionMaker2 }
        \cup { [ZeroInvestmentDecisionMaker2 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestmentDecisionMaker2 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Fields: 15 bytes                                                  *)
(***************************************************************************)

MifidFields2 ==
    [ client                  : Client2,
      executingTrader         : ExecutingTrader2,
      investmentDecisionMaker : InvestmentDecisionMaker2 ]

EncodeMifidFields2(message) ==
    EncodeClient2(message.client)
        \o EncodeExecutingTrader2(message.executingTrader)
        \o EncodeInvestmentDecisionMaker2(message.investmentDecisionMaker)

DecodeMifidFields2(bytes) ==
    LET client == DecodeClient2(bytes) IN IF ~client.ok THEN Fail ELSE
    LET executingTrader == DecodeExecutingTrader2(client.rest) IN IF ~executingTrader.ok THEN Fail ELSE
    LET investmentDecisionMaker == DecodeInvestmentDecisionMaker2(executingTrader.rest) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    Ok([ client                  |-> client.value,
         executingTrader         |-> executingTrader.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value ], investmentDecisionMaker.rest)

ZeroMifidFields2 ==
    [ client                  |-> ZeroClient2,
      executingTrader         |-> ZeroExecutingTrader2,
      investmentDecisionMaker |-> ZeroInvestmentDecisionMaker2 ]

(* Mifid Fields at zero, then each field in turn at the values it is checked at *)
CheckedMifidFields2 ==
    { ZeroMifidFields2 }
        \cup { [ZeroMifidFields2 EXCEPT !.client = one] : one \in CheckedClient2 }
        \cup { [ZeroMifidFields2 EXCEPT !.executingTrader = one] : one \in CheckedExecutingTrader2 }
        \cup { [ZeroMifidFields2 EXCEPT !.investmentDecisionMaker = one] : one \in CheckedInvestmentDecisionMaker2 }

(***************************************************************************)
(* Order Cancel: 43 bytes                                                  *)
(***************************************************************************)

OrderCancel ==
    [ orderId       : Sample(8),
      mifidFields   : MifidFields2,
      clientOrderId : Sample(20) ]

EncodeOrderCancel(message) ==
    message.orderId
        \o EncodeMifidFields2(message.mifidFields)
        \o message.clientOrderId

DecodeOrderCancel(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET mifidFields == DecodeMifidFields2(orderId.rest) IN IF ~mifidFields.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mifidFields.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         mifidFields   |-> mifidFields.value,
         clientOrderId |-> clientOrderId.value ], clientOrderId.rest)

ZeroOrderCancel ==
    [ orderId       |-> [i \in 1 .. 8 |-> 0],
      mifidFields   |-> ZeroMifidFields2,
      clientOrderId |-> [i \in 1 .. 20 |-> 0] ]

(* Order Cancel at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancel ==
    { ZeroOrderCancel }
        \cup { [ZeroOrderCancel EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancel EXCEPT !.mifidFields = one] : one \in CheckedMifidFields2 }
        \cup { [ZeroOrderCancel EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Order Cancel Response: 32 bytes                                         *)
(***************************************************************************)

OrderCancelResponse ==
    [ orderId                    : Sample(8),
      statusOrderStatus          : Sample(1),
      reasonOrderRejectionReason : Sample(2),
      execTypeReason             : Sample(1),
      clientOrderId              : Sample(20) ]

EncodeOrderCancelResponse(message) ==
    message.orderId
        \o message.statusOrderStatus
        \o message.reasonOrderRejectionReason
        \o message.execTypeReason
        \o message.clientOrderId

DecodeOrderCancelResponse(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET statusOrderStatus == ReadBytes(orderId.rest, 1) IN IF ~statusOrderStatus.ok THEN Fail ELSE
    LET reasonOrderRejectionReason == ReadBytes(statusOrderStatus.rest, 2) IN IF ~reasonOrderRejectionReason.ok THEN Fail ELSE
    LET execTypeReason == ReadBytes(reasonOrderRejectionReason.rest, 1) IN IF ~execTypeReason.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(execTypeReason.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ orderId                    |-> orderId.value,
         statusOrderStatus          |-> statusOrderStatus.value,
         reasonOrderRejectionReason |-> reasonOrderRejectionReason.value,
         execTypeReason             |-> execTypeReason.value,
         clientOrderId              |-> clientOrderId.value ], clientOrderId.rest)

ZeroOrderCancelResponse ==
    [ orderId                    |-> [i \in 1 .. 8 |-> 0],
      statusOrderStatus          |-> [i \in 1 .. 1 |-> 0],
      reasonOrderRejectionReason |-> [i \in 1 .. 2 |-> 0],
      execTypeReason             |-> [i \in 1 .. 1 |-> 0],
      clientOrderId              |-> [i \in 1 .. 20 |-> 0] ]

(* Order Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelResponse ==
    { ZeroOrderCancelResponse }
        \cup { [ZeroOrderCancelResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponse EXCEPT !.statusOrderStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelResponse EXCEPT !.reasonOrderRejectionReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelResponse EXCEPT !.execTypeReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Client: 5 bytes                                                         *)
(***************************************************************************)

Client3 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeClient3(message) ==
    message.shortCode
        \o message.qualifier

DecodeClient3(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroClient3 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Client at zero, then each field in turn at the values it is checked at *)
CheckedClient3 ==
    { ZeroClient3 }
        \cup { [ZeroClient3 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroClient3 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Executing Trader: 5 bytes                                               *)
(***************************************************************************)

ExecutingTrader3 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeExecutingTrader3(message) ==
    message.shortCode
        \o message.qualifier

DecodeExecutingTrader3(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroExecutingTrader3 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Executing Trader at zero, then each field in turn at the values it is checked at *)
CheckedExecutingTrader3 ==
    { ZeroExecutingTrader3 }
        \cup { [ZeroExecutingTrader3 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutingTrader3 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Investment Decision Maker: 5 bytes                                      *)
(***************************************************************************)

InvestmentDecisionMaker3 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeInvestmentDecisionMaker3(message) ==
    message.shortCode
        \o message.qualifier

DecodeInvestmentDecisionMaker3(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroInvestmentDecisionMaker3 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Investment Decision Maker at zero, then each field in turn at the values it is checked at *)
CheckedInvestmentDecisionMaker3 ==
    { ZeroInvestmentDecisionMaker3 }
        \cup { [ZeroInvestmentDecisionMaker3 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestmentDecisionMaker3 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Fields: 15 bytes                                                  *)
(***************************************************************************)

MifidFields3 ==
    [ client                  : Client3,
      executingTrader         : ExecutingTrader3,
      investmentDecisionMaker : InvestmentDecisionMaker3 ]

EncodeMifidFields3(message) ==
    EncodeClient3(message.client)
        \o EncodeExecutingTrader3(message.executingTrader)
        \o EncodeInvestmentDecisionMaker3(message.investmentDecisionMaker)

DecodeMifidFields3(bytes) ==
    LET client == DecodeClient3(bytes) IN IF ~client.ok THEN Fail ELSE
    LET executingTrader == DecodeExecutingTrader3(client.rest) IN IF ~executingTrader.ok THEN Fail ELSE
    LET investmentDecisionMaker == DecodeInvestmentDecisionMaker3(executingTrader.rest) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    Ok([ client                  |-> client.value,
         executingTrader         |-> executingTrader.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value ], investmentDecisionMaker.rest)

ZeroMifidFields3 ==
    [ client                  |-> ZeroClient3,
      executingTrader         |-> ZeroExecutingTrader3,
      investmentDecisionMaker |-> ZeroInvestmentDecisionMaker3 ]

(* Mifid Fields at zero, then each field in turn at the values it is checked at *)
CheckedMifidFields3 ==
    { ZeroMifidFields3 }
        \cup { [ZeroMifidFields3 EXCEPT !.client = one] : one \in CheckedClient3 }
        \cup { [ZeroMifidFields3 EXCEPT !.executingTrader = one] : one \in CheckedExecutingTrader3 }
        \cup { [ZeroMifidFields3 EXCEPT !.investmentDecisionMaker = one] : one \in CheckedInvestmentDecisionMaker3 }

(***************************************************************************)
(* Order Modify: 83 bytes                                                  *)
(***************************************************************************)

OrderModify ==
    [ orderId       : Sample(8),
      price         : Sample(8),
      triggerPrice  : Sample(8),
      quantity      : Sample(8),
      displayQty    : Sample(8),
      expire        : Sample(8),
      mifidFields   : MifidFields3,
      clientOrderId : Sample(20) ]

EncodeOrderModify(message) ==
    message.orderId
        \o message.price
        \o message.triggerPrice
        \o message.quantity
        \o message.displayQty
        \o message.expire
        \o EncodeMifidFields3(message.mifidFields)
        \o message.clientOrderId

DecodeOrderModify(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 8) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET quantity == ReadBytes(triggerPrice.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET displayQty == ReadBytes(quantity.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET expire == ReadBytes(displayQty.rest, 8) IN IF ~expire.ok THEN Fail ELSE
    LET mifidFields == DecodeMifidFields3(expire.rest) IN IF ~mifidFields.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mifidFields.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ orderId       |-> orderId.value,
         price         |-> price.value,
         triggerPrice  |-> triggerPrice.value,
         quantity      |-> quantity.value,
         displayQty    |-> displayQty.value,
         expire        |-> expire.value,
         mifidFields   |-> mifidFields.value,
         clientOrderId |-> clientOrderId.value ], clientOrderId.rest)

ZeroOrderModify ==
    [ orderId       |-> [i \in 1 .. 8 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      triggerPrice  |-> [i \in 1 .. 8 |-> 0],
      quantity      |-> [i \in 1 .. 8 |-> 0],
      displayQty    |-> [i \in 1 .. 8 |-> 0],
      expire        |-> [i \in 1 .. 8 |-> 0],
      mifidFields   |-> ZeroMifidFields3,
      clientOrderId |-> [i \in 1 .. 20 |-> 0] ]

(* Order Modify at zero, then each field in turn at the values it is checked at *)
CheckedOrderModify ==
    { ZeroOrderModify }
        \cup { [ZeroOrderModify EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.triggerPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.expire = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.mifidFields = one] : one \in CheckedMifidFields3 }
        \cup { [ZeroOrderModify EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Order Modify Response: 40 bytes                                         *)
(***************************************************************************)

OrderModifyResponse ==
    [ orderId                    : Sample(8),
      filled                     : Sample(8),
      statusOrderStatus          : Sample(1),
      priorityFlag               : Sample(1),
      reasonOrderRejectionReason : Sample(2),
      clientOrderId              : Sample(20) ]

EncodeOrderModifyResponse(message) ==
    message.orderId
        \o message.filled
        \o message.statusOrderStatus
        \o message.priorityFlag
        \o message.reasonOrderRejectionReason
        \o message.clientOrderId

DecodeOrderModifyResponse(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET filled == ReadBytes(orderId.rest, 8) IN IF ~filled.ok THEN Fail ELSE
    LET statusOrderStatus == ReadBytes(filled.rest, 1) IN IF ~statusOrderStatus.ok THEN Fail ELSE
    LET priorityFlag == ReadBytes(statusOrderStatus.rest, 1) IN IF ~priorityFlag.ok THEN Fail ELSE
    LET reasonOrderRejectionReason == ReadBytes(priorityFlag.rest, 2) IN IF ~reasonOrderRejectionReason.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(reasonOrderRejectionReason.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ orderId                    |-> orderId.value,
         filled                     |-> filled.value,
         statusOrderStatus          |-> statusOrderStatus.value,
         priorityFlag               |-> priorityFlag.value,
         reasonOrderRejectionReason |-> reasonOrderRejectionReason.value,
         clientOrderId              |-> clientOrderId.value ], clientOrderId.rest)

ZeroOrderModifyResponse ==
    [ orderId                    |-> [i \in 1 .. 8 |-> 0],
      filled                     |-> [i \in 1 .. 8 |-> 0],
      statusOrderStatus          |-> [i \in 1 .. 1 |-> 0],
      priorityFlag               |-> [i \in 1 .. 1 |-> 0],
      reasonOrderRejectionReason |-> [i \in 1 .. 2 |-> 0],
      clientOrderId              |-> [i \in 1 .. 20 |-> 0] ]

(* Order Modify Response at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyResponse ==
    { ZeroOrderModifyResponse }
        \cup { [ZeroOrderModifyResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyResponse EXCEPT !.filled = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyResponse EXCEPT !.statusOrderStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyResponse EXCEPT !.priorityFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyResponse EXCEPT !.reasonOrderRejectionReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Executing Trader: 5 bytes                                               *)
(***************************************************************************)

ExecutingTrader4 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeExecutingTrader4(message) ==
    message.shortCode
        \o message.qualifier

DecodeExecutingTrader4(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroExecutingTrader4 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Executing Trader at zero, then each field in turn at the values it is checked at *)
CheckedExecutingTrader4 ==
    { ZeroExecutingTrader4 }
        \cup { [ZeroExecutingTrader4 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutingTrader4 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Mass Cancel: 39 bytes                                             *)
(***************************************************************************)

OrderMassCancel ==
    [ massCancelRequestType : Sample(1),
      targetPartyRole       : Sample(1),
      targetPartyId         : Sample(4),
      marketSegmentId       : Sample(4),
      instrumentId          : Sample(4),
      executingTrader       : ExecutingTrader4,
      clientOrderId         : Sample(20) ]

EncodeOrderMassCancel(message) ==
    message.massCancelRequestType
        \o message.targetPartyRole
        \o message.targetPartyId
        \o message.marketSegmentId
        \o message.instrumentId
        \o EncodeExecutingTrader4(message.executingTrader)
        \o message.clientOrderId

DecodeOrderMassCancel(bytes) ==
    LET massCancelRequestType == ReadBytes(bytes, 1) IN IF ~massCancelRequestType.ok THEN Fail ELSE
    LET targetPartyRole == ReadBytes(massCancelRequestType.rest, 1) IN IF ~targetPartyRole.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(targetPartyRole.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(targetPartyId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(marketSegmentId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET executingTrader == DecodeExecutingTrader4(instrumentId.rest) IN IF ~executingTrader.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(executingTrader.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ massCancelRequestType |-> massCancelRequestType.value,
         targetPartyRole       |-> targetPartyRole.value,
         targetPartyId         |-> targetPartyId.value,
         marketSegmentId       |-> marketSegmentId.value,
         instrumentId          |-> instrumentId.value,
         executingTrader       |-> executingTrader.value,
         clientOrderId         |-> clientOrderId.value ], clientOrderId.rest)

ZeroOrderMassCancel ==
    [ massCancelRequestType |-> [i \in 1 .. 1 |-> 0],
      targetPartyRole       |-> [i \in 1 .. 1 |-> 0],
      targetPartyId         |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      instrumentId          |-> [i \in 1 .. 4 |-> 0],
      executingTrader       |-> ZeroExecutingTrader4,
      clientOrderId         |-> [i \in 1 .. 20 |-> 0] ]

(* Order Mass Cancel at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancel ==
    { ZeroOrderMassCancel }
        \cup { [ZeroOrderMassCancel EXCEPT !.massCancelRequestType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancel EXCEPT !.targetPartyRole = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancel EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancel EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancel EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancel EXCEPT !.executingTrader = one] : one \in CheckedExecutingTrader4 }
        \cup { [ZeroOrderMassCancel EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Order Mass Cancel Response: 48 bytes                                    *)
(***************************************************************************)

OrderMassCancelResponse ==
    [ totalAffectedOrders             : Sample(8),
      massCancelRequestType           : Sample(1),
      massCancelId                    : Sample(8),
      targetPartyRole                 : Sample(1),
      targetPartyId                   : Sample(4),
      marketSegmentId                 : Sample(4),
      reasonMassCancelRejectionReason : Sample(2),
      clientOrderId                   : Sample(20) ]

EncodeOrderMassCancelResponse(message) ==
    message.totalAffectedOrders
        \o message.massCancelRequestType
        \o message.massCancelId
        \o message.targetPartyRole
        \o message.targetPartyId
        \o message.marketSegmentId
        \o message.reasonMassCancelRejectionReason
        \o message.clientOrderId

DecodeOrderMassCancelResponse(bytes) ==
    LET totalAffectedOrders == ReadBytes(bytes, 8) IN IF ~totalAffectedOrders.ok THEN Fail ELSE
    LET massCancelRequestType == ReadBytes(totalAffectedOrders.rest, 1) IN IF ~massCancelRequestType.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(massCancelRequestType.rest, 8) IN IF ~massCancelId.ok THEN Fail ELSE
    LET targetPartyRole == ReadBytes(massCancelId.rest, 1) IN IF ~targetPartyRole.ok THEN Fail ELSE
    LET targetPartyId == ReadBytes(targetPartyRole.rest, 4) IN IF ~targetPartyId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(targetPartyId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET reasonMassCancelRejectionReason == ReadBytes(marketSegmentId.rest, 2) IN IF ~reasonMassCancelRejectionReason.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(reasonMassCancelRejectionReason.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ totalAffectedOrders             |-> totalAffectedOrders.value,
         massCancelRequestType           |-> massCancelRequestType.value,
         massCancelId                    |-> massCancelId.value,
         targetPartyRole                 |-> targetPartyRole.value,
         targetPartyId                   |-> targetPartyId.value,
         marketSegmentId                 |-> marketSegmentId.value,
         reasonMassCancelRejectionReason |-> reasonMassCancelRejectionReason.value,
         clientOrderId                   |-> clientOrderId.value ], clientOrderId.rest)

ZeroOrderMassCancelResponse ==
    [ totalAffectedOrders             |-> [i \in 1 .. 8 |-> 0],
      massCancelRequestType           |-> [i \in 1 .. 1 |-> 0],
      massCancelId                    |-> [i \in 1 .. 8 |-> 0],
      targetPartyRole                 |-> [i \in 1 .. 1 |-> 0],
      targetPartyId                   |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                 |-> [i \in 1 .. 4 |-> 0],
      reasonMassCancelRejectionReason |-> [i \in 1 .. 2 |-> 0],
      clientOrderId                   |-> [i \in 1 .. 20 |-> 0] ]

(* Order Mass Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelResponse ==
    { ZeroOrderMassCancelResponse }
        \cup { [ZeroOrderMassCancelResponse EXCEPT !.totalAffectedOrders = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelResponse EXCEPT !.massCancelRequestType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelResponse EXCEPT !.massCancelId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelResponse EXCEPT !.targetPartyRole = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelResponse EXCEPT !.targetPartyId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelResponse EXCEPT !.reasonMassCancelRejectionReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderMassCancelResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Order Execute: 64 bytes                                                 *)
(***************************************************************************)

OrderExecute ==
    [ instrumentId       : Sample(4),
      orderId            : Sample(8),
      tradeId            : Sample(4),
      price              : Sample(8),
      quantity           : Sample(8),
      leavesQty          : Sample(8),
      liquidityIndicator : Sample(1),
      currency           : Sample(2),
      side               : Sample(1),
      clientOrderId      : Sample(20) ]

EncodeOrderExecute(message) ==
    message.instrumentId
        \o message.orderId
        \o message.tradeId
        \o message.price
        \o message.quantity
        \o message.leavesQty
        \o message.liquidityIndicator
        \o message.currency
        \o message.side
        \o message.clientOrderId

DecodeOrderExecute(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(orderId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(quantity.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(leavesQty.rest, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET currency == ReadBytes(liquidityIndicator.rest, 2) IN IF ~currency.ok THEN Fail ELSE
    LET side == ReadBytes(currency.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(side.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ instrumentId       |-> instrumentId.value,
         orderId            |-> orderId.value,
         tradeId            |-> tradeId.value,
         price              |-> price.value,
         quantity           |-> quantity.value,
         leavesQty          |-> leavesQty.value,
         liquidityIndicator |-> liquidityIndicator.value,
         currency           |-> currency.value,
         side               |-> side.value,
         clientOrderId      |-> clientOrderId.value ], clientOrderId.rest)

ZeroOrderExecute ==
    [ instrumentId       |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantity           |-> [i \in 1 .. 8 |-> 0],
      leavesQty          |-> [i \in 1 .. 8 |-> 0],
      liquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      currency           |-> [i \in 1 .. 2 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0] ]

(* Order Execute at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecute ==
    { ZeroOrderExecute }
        \cup { [ZeroOrderExecute EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecute EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecute EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecute EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecute EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecute EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecute EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecute EXCEPT !.currency = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecute EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecute EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Client: 5 bytes                                                         *)
(***************************************************************************)

Client4 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeClient4(message) ==
    message.shortCode
        \o message.qualifier

DecodeClient4(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroClient4 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Client at zero, then each field in turn at the values it is checked at *)
CheckedClient4 ==
    { ZeroClient4 }
        \cup { [ZeroClient4 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroClient4 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Executing Trader: 5 bytes                                               *)
(***************************************************************************)

ExecutingTrader5 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeExecutingTrader5(message) ==
    message.shortCode
        \o message.qualifier

DecodeExecutingTrader5(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroExecutingTrader5 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Executing Trader at zero, then each field in turn at the values it is checked at *)
CheckedExecutingTrader5 ==
    { ZeroExecutingTrader5 }
        \cup { [ZeroExecutingTrader5 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutingTrader5 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Investment Decision Maker: 5 bytes                                      *)
(***************************************************************************)

InvestmentDecisionMaker4 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeInvestmentDecisionMaker4(message) ==
    message.shortCode
        \o message.qualifier

DecodeInvestmentDecisionMaker4(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroInvestmentDecisionMaker4 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Investment Decision Maker at zero, then each field in turn at the values it is checked at *)
CheckedInvestmentDecisionMaker4 ==
    { ZeroInvestmentDecisionMaker4 }
        \cup { [ZeroInvestmentDecisionMaker4 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestmentDecisionMaker4 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Fields: 15 bytes                                                  *)
(***************************************************************************)

MifidFields4 ==
    [ client                  : Client4,
      executingTrader         : ExecutingTrader5,
      investmentDecisionMaker : InvestmentDecisionMaker4 ]

EncodeMifidFields4(message) ==
    EncodeClient4(message.client)
        \o EncodeExecutingTrader5(message.executingTrader)
        \o EncodeInvestmentDecisionMaker4(message.investmentDecisionMaker)

DecodeMifidFields4(bytes) ==
    LET client == DecodeClient4(bytes) IN IF ~client.ok THEN Fail ELSE
    LET executingTrader == DecodeExecutingTrader5(client.rest) IN IF ~executingTrader.ok THEN Fail ELSE
    LET investmentDecisionMaker == DecodeInvestmentDecisionMaker4(executingTrader.rest) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    Ok([ client                  |-> client.value,
         executingTrader         |-> executingTrader.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value ], investmentDecisionMaker.rest)

ZeroMifidFields4 ==
    [ client                  |-> ZeroClient4,
      executingTrader         |-> ZeroExecutingTrader5,
      investmentDecisionMaker |-> ZeroInvestmentDecisionMaker4 ]

(* Mifid Fields at zero, then each field in turn at the values it is checked at *)
CheckedMifidFields4 ==
    { ZeroMifidFields4 }
        \cup { [ZeroMifidFields4 EXCEPT !.client = one] : one \in CheckedClient4 }
        \cup { [ZeroMifidFields4 EXCEPT !.executingTrader = one] : one \in CheckedExecutingTrader5 }
        \cup { [ZeroMifidFields4 EXCEPT !.investmentDecisionMaker = one] : one \in CheckedInvestmentDecisionMaker4 }

(***************************************************************************)
(* Bid: 16 bytes                                                           *)
(***************************************************************************)

Bid ==
    [ price    : Sample(8),
      quantity : Sample(8) ]

EncodeBid(message) ==
    message.price
        \o message.quantity

DecodeBid(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ price    |-> price.value,
         quantity |-> quantity.value ], quantity.rest)

ZeroBid ==
    [ price    |-> [i \in 1 .. 8 |-> 0],
      quantity |-> [i \in 1 .. 8 |-> 0] ]

(* Bid at zero, then each field in turn at the values it is checked at *)
CheckedBid ==
    { ZeroBid }
        \cup { [ZeroBid EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroBid EXCEPT !.quantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Ask: 16 bytes                                                           *)
(***************************************************************************)

Ask ==
    [ price    : Sample(8),
      quantity : Sample(8) ]

EncodeAsk(message) ==
    message.price
        \o message.quantity

DecodeAsk(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ price    |-> price.value,
         quantity |-> quantity.value ], quantity.rest)

ZeroAsk ==
    [ price    |-> [i \in 1 .. 8 |-> 0],
      quantity |-> [i \in 1 .. 8 |-> 0] ]

(* Ask at zero, then each field in turn at the values it is checked at *)
CheckedAsk ==
    { ZeroAsk }
        \cup { [ZeroAsk EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAsk EXCEPT !.quantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote: 36 bytes                                                         *)
(***************************************************************************)

Quote ==
    [ instrumentId : Sample(4),
      bid          : Bid,
      ask          : Ask ]

EncodeQuote(message) ==
    message.instrumentId
        \o EncodeBid(message.bid)
        \o EncodeAsk(message.ask)

DecodeQuote(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bid == DecodeBid(instrumentId.rest) IN IF ~bid.ok THEN Fail ELSE
    LET ask == DecodeAsk(bid.rest) IN IF ~ask.ok THEN Fail ELSE
    Ok([ instrumentId |-> instrumentId.value,
         bid          |-> bid.value,
         ask          |-> ask.value ], ask.rest)

ZeroQuote ==
    [ instrumentId |-> [i \in 1 .. 4 |-> 0],
      bid          |-> ZeroBid,
      ask          |-> ZeroAsk ]

(* Quote at zero, then each field in turn at the values it is checked at *)
CheckedQuote ==
    { ZeroQuote }
        \cup { [ZeroQuote EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuote EXCEPT !.bid = one] : one \in CheckedBid }
        \cup { [ZeroQuote EXCEPT !.ask = one] : one \in CheckedAsk }

(***************************************************************************)
(* Items Quotes Array: 36 bytes                                            *)
(***************************************************************************)

ItemsQuotesArray ==
    [ quote : Quote ]

EncodeItemsQuotesArray(message) ==
    EncodeQuote(message.quote)

DecodeItemsQuotesArray(bytes) ==
    LET quote == DecodeQuote(bytes) IN IF ~quote.ok THEN Fail ELSE
    Ok([ quote |-> quote.value ], quote.rest)

ZeroItemsQuotesArray ==
    [ quote |-> ZeroQuote ]

(* Items Quotes Array at zero, then each field in turn at the values it is checked at *)
CheckedItemsQuotesArray ==
    { ZeroItemsQuotesArray }
        \cup { [ZeroItemsQuotesArray EXCEPT !.quote = one] : one \in CheckedQuote }

(* A run of Items Quotes Array, written one after another *)
RECURSIVE EncodeItemsQuotesArrayList(_)
EncodeItemsQuotesArrayList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeItemsQuotesArray(Head(messages)) \o EncodeItemsQuotesArrayList(Tail(messages))

(* As many Items Quotes Array as the field that counts them says *)
RECURSIVE ReadItemsQuotesArrayList(_, _)
ReadItemsQuotesArrayList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeItemsQuotesArray(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadItemsQuotesArrayList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Items Quotes Array of each kind, for the lists that carry them *)
OneItemsQuotesArray == { ZeroItemsQuotesArray }

(* The 30 slots a run of Items Quotes Array is written as, whatever the field beside it says are in use *)
SlotsItemsQuotesArray == { [i \in 1 .. 30 |-> one] : one \in OneItemsQuotesArray }

(***************************************************************************)
(* Quotes                                                                  *)
(***************************************************************************)

Quotes ==
    [ count            : Sample(1),
      itemsQuotesArray : SlotsItemsQuotesArray ]

EncodeQuotes(message) ==
    message.count
        \o EncodeItemsQuotesArrayList(message.itemsQuotesArray)

DecodeQuotes(bytes) ==
    LET count == ReadBytes(bytes, 1) IN IF ~count.ok THEN Fail ELSE
    LET itemsQuotesArray == ReadItemsQuotesArrayList(count.rest, 30) IN IF ~itemsQuotesArray.ok THEN Fail ELSE
    Ok([ count            |-> count.value,
         itemsQuotesArray |-> itemsQuotesArray.value ], itemsQuotesArray.rest)

ZeroQuotes ==
    [ count            |-> [i \in 1 .. 1 |-> 0],
      itemsQuotesArray |-> [i \in 1 .. 30 |-> ZeroItemsQuotesArray] ]

(* Quotes at zero, then each field in turn at the values it is checked at *)
CheckedQuotes ==
    { ZeroQuotes }
        \cup { [ZeroQuotes EXCEPT !.count = one] : one \in Sample(1) }
        \cup { [ZeroQuotes EXCEPT !.itemsQuotesArray = one] : one \in SlotsItemsQuotesArray }

(***************************************************************************)
(* Mass Quote                                                              *)
(***************************************************************************)

MassQuote ==
    [ stpId                            : Sample(1),
      capacity                         : Sample(1),
      account                          : Sample(16),
      accountType                      : Sample(1),
      flags                            : Sample(1),
      mifidFields                      : MifidFields4,
      memo                             : Sample(18),
      clearingMemberCode               : Sample(20),
      clearingMemberClearingIdentifier : Sample(1),
      quotes                           : Quotes,
      feeStructureId                   : Sample(1),
      interestedParty                  : Sample(8),
      quoteId                          : Sample(20) ]

EncodeMassQuote(message) ==
    message.stpId
        \o message.capacity
        \o message.account
        \o message.accountType
        \o message.flags
        \o EncodeMifidFields4(message.mifidFields)
        \o message.memo
        \o message.clearingMemberCode
        \o message.clearingMemberClearingIdentifier
        \o EncodeQuotes(message.quotes)
        \o message.feeStructureId
        \o message.interestedParty
        \o message.quoteId

DecodeMassQuote(bytes) ==
    LET stpId == ReadBytes(bytes, 1) IN IF ~stpId.ok THEN Fail ELSE
    LET capacity == ReadBytes(stpId.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET accountType == ReadBytes(account.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET flags == ReadBytes(accountType.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET mifidFields == DecodeMifidFields4(flags.rest) IN IF ~mifidFields.ok THEN Fail ELSE
    LET memo == ReadBytes(mifidFields.rest, 18) IN IF ~memo.ok THEN Fail ELSE
    LET clearingMemberCode == ReadBytes(memo.rest, 20) IN IF ~clearingMemberCode.ok THEN Fail ELSE
    LET clearingMemberClearingIdentifier == ReadBytes(clearingMemberCode.rest, 1) IN IF ~clearingMemberClearingIdentifier.ok THEN Fail ELSE
    LET quotes == DecodeQuotes(clearingMemberClearingIdentifier.rest) IN IF ~quotes.ok THEN Fail ELSE
    LET feeStructureId == ReadBytes(quotes.rest, 1) IN IF ~feeStructureId.ok THEN Fail ELSE
    LET interestedParty == ReadBytes(feeStructureId.rest, 8) IN IF ~interestedParty.ok THEN Fail ELSE
    LET quoteId == ReadBytes(interestedParty.rest, 20) IN IF ~quoteId.ok THEN Fail ELSE
    Ok([ stpId                            |-> stpId.value,
         capacity                         |-> capacity.value,
         account                          |-> account.value,
         accountType                      |-> accountType.value,
         flags                            |-> flags.value,
         mifidFields                      |-> mifidFields.value,
         memo                             |-> memo.value,
         clearingMemberCode               |-> clearingMemberCode.value,
         clearingMemberClearingIdentifier |-> clearingMemberClearingIdentifier.value,
         quotes                           |-> quotes.value,
         feeStructureId                   |-> feeStructureId.value,
         interestedParty                  |-> interestedParty.value,
         quoteId                          |-> quoteId.value ], quoteId.rest)

ZeroMassQuote ==
    [ stpId                            |-> [i \in 1 .. 1 |-> 0],
      capacity                         |-> [i \in 1 .. 1 |-> 0],
      account                          |-> [i \in 1 .. 16 |-> 0],
      accountType                      |-> [i \in 1 .. 1 |-> 0],
      flags                            |-> [i \in 1 .. 1 |-> 0],
      mifidFields                      |-> ZeroMifidFields4,
      memo                             |-> [i \in 1 .. 18 |-> 0],
      clearingMemberCode               |-> [i \in 1 .. 20 |-> 0],
      clearingMemberClearingIdentifier |-> [i \in 1 .. 1 |-> 0],
      quotes                           |-> ZeroQuotes,
      feeStructureId                   |-> [i \in 1 .. 1 |-> 0],
      interestedParty                  |-> [i \in 1 .. 8 |-> 0],
      quoteId                          |-> [i \in 1 .. 20 |-> 0] ]

(* Mass Quote at zero, then each field in turn at the values it is checked at *)
CheckedMassQuote ==
    { ZeroMassQuote }
        \cup { [ZeroMassQuote EXCEPT !.stpId = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroMassQuote EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.mifidFields = one] : one \in CheckedMifidFields4 }
        \cup { [ZeroMassQuote EXCEPT !.memo = one] : one \in Sample(18) }
        \cup { [ZeroMassQuote EXCEPT !.clearingMemberCode = one] : one \in Sample(20) }
        \cup { [ZeroMassQuote EXCEPT !.clearingMemberClearingIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.quotes = one] : one \in CheckedQuotes }
        \cup { [ZeroMassQuote EXCEPT !.feeStructureId = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.interestedParty = one] : one \in Sample(8) }
        \cup { [ZeroMassQuote EXCEPT !.quoteId = one] : one \in Sample(20) }

(***************************************************************************)
(* Quote Order Response: 23 bytes                                          *)
(***************************************************************************)

QuoteOrderResponse ==
    [ instrumentId               : Sample(4),
      bidOrderId                 : Sample(8),
      askOrderId                 : Sample(8),
      statusOrderStatus          : Sample(1),
      reasonOrderRejectionReason : Sample(2) ]

EncodeQuoteOrderResponse(message) ==
    message.instrumentId
        \o message.bidOrderId
        \o message.askOrderId
        \o message.statusOrderStatus
        \o message.reasonOrderRejectionReason

DecodeQuoteOrderResponse(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidOrderId == ReadBytes(instrumentId.rest, 8) IN IF ~bidOrderId.ok THEN Fail ELSE
    LET askOrderId == ReadBytes(bidOrderId.rest, 8) IN IF ~askOrderId.ok THEN Fail ELSE
    LET statusOrderStatus == ReadBytes(askOrderId.rest, 1) IN IF ~statusOrderStatus.ok THEN Fail ELSE
    LET reasonOrderRejectionReason == ReadBytes(statusOrderStatus.rest, 2) IN IF ~reasonOrderRejectionReason.ok THEN Fail ELSE
    Ok([ instrumentId               |-> instrumentId.value,
         bidOrderId                 |-> bidOrderId.value,
         askOrderId                 |-> askOrderId.value,
         statusOrderStatus          |-> statusOrderStatus.value,
         reasonOrderRejectionReason |-> reasonOrderRejectionReason.value ], reasonOrderRejectionReason.rest)

ZeroQuoteOrderResponse ==
    [ instrumentId               |-> [i \in 1 .. 4 |-> 0],
      bidOrderId                 |-> [i \in 1 .. 8 |-> 0],
      askOrderId                 |-> [i \in 1 .. 8 |-> 0],
      statusOrderStatus          |-> [i \in 1 .. 1 |-> 0],
      reasonOrderRejectionReason |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Order Response at zero, then each field in turn at the values it is checked at *)
CheckedQuoteOrderResponse ==
    { ZeroQuoteOrderResponse }
        \cup { [ZeroQuoteOrderResponse EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteOrderResponse EXCEPT !.bidOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteOrderResponse EXCEPT !.askOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteOrderResponse EXCEPT !.statusOrderStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteOrderResponse EXCEPT !.reasonOrderRejectionReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Items Quote Order Response Array: 23 bytes                              *)
(***************************************************************************)

ItemsQuoteOrderResponseArray ==
    [ quoteOrderResponse : QuoteOrderResponse ]

EncodeItemsQuoteOrderResponseArray(message) ==
    EncodeQuoteOrderResponse(message.quoteOrderResponse)

DecodeItemsQuoteOrderResponseArray(bytes) ==
    LET quoteOrderResponse == DecodeQuoteOrderResponse(bytes) IN IF ~quoteOrderResponse.ok THEN Fail ELSE
    Ok([ quoteOrderResponse |-> quoteOrderResponse.value ], quoteOrderResponse.rest)

ZeroItemsQuoteOrderResponseArray ==
    [ quoteOrderResponse |-> ZeroQuoteOrderResponse ]

(* Items Quote Order Response Array at zero, then each field in turn at the values it is checked at *)
CheckedItemsQuoteOrderResponseArray ==
    { ZeroItemsQuoteOrderResponseArray }
        \cup { [ZeroItemsQuoteOrderResponseArray EXCEPT !.quoteOrderResponse = one] : one \in CheckedQuoteOrderResponse }

(* A run of Items Quote Order Response Array, written one after another *)
RECURSIVE EncodeItemsQuoteOrderResponseArrayList(_)
EncodeItemsQuoteOrderResponseArrayList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeItemsQuoteOrderResponseArray(Head(messages)) \o EncodeItemsQuoteOrderResponseArrayList(Tail(messages))

(* As many Items Quote Order Response Array as the field that counts them says *)
RECURSIVE ReadItemsQuoteOrderResponseArrayList(_, _)
ReadItemsQuoteOrderResponseArrayList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeItemsQuoteOrderResponseArray(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadItemsQuoteOrderResponseArrayList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Items Quote Order Response Array of each kind, for the lists that carry them *)
OneItemsQuoteOrderResponseArray == { ZeroItemsQuoteOrderResponseArray }

(* The 30 slots a run of Items Quote Order Response Array is written as, whatever the field beside it says are in use *)
SlotsItemsQuoteOrderResponseArray == { [i \in 1 .. 30 |-> one] : one \in OneItemsQuoteOrderResponseArray }

(***************************************************************************)
(* Responses                                                               *)
(***************************************************************************)

Responses ==
    [ count                        : Sample(1),
      itemsQuoteOrderResponseArray : SlotsItemsQuoteOrderResponseArray ]

EncodeResponses(message) ==
    message.count
        \o EncodeItemsQuoteOrderResponseArrayList(message.itemsQuoteOrderResponseArray)

DecodeResponses(bytes) ==
    LET count == ReadBytes(bytes, 1) IN IF ~count.ok THEN Fail ELSE
    LET itemsQuoteOrderResponseArray == ReadItemsQuoteOrderResponseArrayList(count.rest, 30) IN IF ~itemsQuoteOrderResponseArray.ok THEN Fail ELSE
    Ok([ count                        |-> count.value,
         itemsQuoteOrderResponseArray |-> itemsQuoteOrderResponseArray.value ], itemsQuoteOrderResponseArray.rest)

ZeroResponses ==
    [ count                        |-> [i \in 1 .. 1 |-> 0],
      itemsQuoteOrderResponseArray |-> [i \in 1 .. 30 |-> ZeroItemsQuoteOrderResponseArray] ]

(* Responses at zero, then each field in turn at the values it is checked at *)
CheckedResponses ==
    { ZeroResponses }
        \cup { [ZeroResponses EXCEPT !.count = one] : one \in Sample(1) }
        \cup { [ZeroResponses EXCEPT !.itemsQuoteOrderResponseArray = one] : one \in SlotsItemsQuoteOrderResponseArray }

(***************************************************************************)
(* Mass Quote Response                                                     *)
(***************************************************************************)

MassQuoteResponse ==
    [ massQuoteId                    : Sample(8),
      responses                      : Responses,
      statusMassQuoteStatus          : Sample(1),
      reasonMassQuoteRejectionReason : Sample(2),
      feeStructureId                 : Sample(1) ]

EncodeMassQuoteResponse(message) ==
    message.massQuoteId
        \o EncodeResponses(message.responses)
        \o message.statusMassQuoteStatus
        \o message.reasonMassQuoteRejectionReason
        \o message.feeStructureId

DecodeMassQuoteResponse(bytes) ==
    LET massQuoteId == ReadBytes(bytes, 8) IN IF ~massQuoteId.ok THEN Fail ELSE
    LET responses == DecodeResponses(massQuoteId.rest) IN IF ~responses.ok THEN Fail ELSE
    LET statusMassQuoteStatus == ReadBytes(responses.rest, 1) IN IF ~statusMassQuoteStatus.ok THEN Fail ELSE
    LET reasonMassQuoteRejectionReason == ReadBytes(statusMassQuoteStatus.rest, 2) IN IF ~reasonMassQuoteRejectionReason.ok THEN Fail ELSE
    LET feeStructureId == ReadBytes(reasonMassQuoteRejectionReason.rest, 1) IN IF ~feeStructureId.ok THEN Fail ELSE
    Ok([ massQuoteId                    |-> massQuoteId.value,
         responses                      |-> responses.value,
         statusMassQuoteStatus          |-> statusMassQuoteStatus.value,
         reasonMassQuoteRejectionReason |-> reasonMassQuoteRejectionReason.value,
         feeStructureId                 |-> feeStructureId.value ], feeStructureId.rest)

ZeroMassQuoteResponse ==
    [ massQuoteId                    |-> [i \in 1 .. 8 |-> 0],
      responses                      |-> ZeroResponses,
      statusMassQuoteStatus          |-> [i \in 1 .. 1 |-> 0],
      reasonMassQuoteRejectionReason |-> [i \in 1 .. 2 |-> 0],
      feeStructureId                 |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponse ==
    { ZeroMassQuoteResponse }
        \cup { [ZeroMassQuoteResponse EXCEPT !.massQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.responses = one] : one \in CheckedResponses }
        \cup { [ZeroMassQuoteResponse EXCEPT !.statusMassQuoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.reasonMassQuoteRejectionReason = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.feeStructureId = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Maker Command: 5 bytes                                           *)
(***************************************************************************)

MarketMakerCommand ==
    [ instrumentId : Sample(4),
      action       : Sample(1) ]

EncodeMarketMakerCommand(message) ==
    message.instrumentId
        \o message.action

DecodeMarketMakerCommand(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET action == ReadBytes(instrumentId.rest, 1) IN IF ~action.ok THEN Fail ELSE
    Ok([ instrumentId |-> instrumentId.value,
         action       |-> action.value ], action.rest)

ZeroMarketMakerCommand ==
    [ instrumentId |-> [i \in 1 .. 4 |-> 0],
      action       |-> [i \in 1 .. 1 |-> 0] ]

(* Market Maker Command at zero, then each field in turn at the values it is checked at *)
CheckedMarketMakerCommand ==
    { ZeroMarketMakerCommand }
        \cup { [ZeroMarketMakerCommand EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakerCommand EXCEPT !.action = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Maker Command Response: 7 bytes                                  *)
(***************************************************************************)

MarketMakerCommandResponse ==
    [ refId               : Sample(4),
      resultCommandResult : Sample(1),
      rejectionCode       : Sample(2) ]

EncodeMarketMakerCommandResponse(message) ==
    message.refId
        \o message.resultCommandResult
        \o message.rejectionCode

DecodeMarketMakerCommandResponse(bytes) ==
    LET refId == ReadBytes(bytes, 4) IN IF ~refId.ok THEN Fail ELSE
    LET resultCommandResult == ReadBytes(refId.rest, 1) IN IF ~resultCommandResult.ok THEN Fail ELSE
    LET rejectionCode == ReadBytes(resultCommandResult.rest, 2) IN IF ~rejectionCode.ok THEN Fail ELSE
    Ok([ refId               |-> refId.value,
         resultCommandResult |-> resultCommandResult.value,
         rejectionCode       |-> rejectionCode.value ], rejectionCode.rest)

ZeroMarketMakerCommandResponse ==
    [ refId               |-> [i \in 1 .. 4 |-> 0],
      resultCommandResult |-> [i \in 1 .. 1 |-> 0],
      rejectionCode       |-> [i \in 1 .. 2 |-> 0] ]

(* Market Maker Command Response at zero, then each field in turn at the values it is checked at *)
CheckedMarketMakerCommandResponse ==
    { ZeroMarketMakerCommandResponse }
        \cup { [ZeroMarketMakerCommandResponse EXCEPT !.refId = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakerCommandResponse EXCEPT !.resultCommandResult = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakerCommandResponse EXCEPT !.rejectionCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Request For Execution: 5 bytes                                          *)
(***************************************************************************)

RequestForExecution ==
    [ instrumentId                    : Sample(4),
      reasonRequestForExecutionReason : Sample(1) ]

EncodeRequestForExecution(message) ==
    message.instrumentId
        \o message.reasonRequestForExecutionReason

DecodeRequestForExecution(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reasonRequestForExecutionReason == ReadBytes(instrumentId.rest, 1) IN IF ~reasonRequestForExecutionReason.ok THEN Fail ELSE
    Ok([ instrumentId                    |-> instrumentId.value,
         reasonRequestForExecutionReason |-> reasonRequestForExecutionReason.value ], reasonRequestForExecutionReason.rest)

ZeroRequestForExecution ==
    [ instrumentId                    |-> [i \in 1 .. 4 |-> 0],
      reasonRequestForExecutionReason |-> [i \in 1 .. 1 |-> 0] ]

(* Request For Execution at zero, then each field in turn at the values it is checked at *)
CheckedRequestForExecution ==
    { ZeroRequestForExecution }
        \cup { [ZeroRequestForExecution EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroRequestForExecution EXCEPT !.reasonRequestForExecutionReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Offer Update: 29 bytes                                              *)
(***************************************************************************)

BidOfferUpdate ==
    [ instrumentId   : Sample(4),
      updateType     : Sample(1),
      totalBidSize   : Sample(8),
      totalOfferSize : Sample(8),
      bidOrders      : Sample(4),
      offerOrders    : Sample(4) ]

EncodeBidOfferUpdate(message) ==
    message.instrumentId
        \o message.updateType
        \o message.totalBidSize
        \o message.totalOfferSize
        \o message.bidOrders
        \o message.offerOrders

DecodeBidOfferUpdate(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET updateType == ReadBytes(instrumentId.rest, 1) IN IF ~updateType.ok THEN Fail ELSE
    LET totalBidSize == ReadBytes(updateType.rest, 8) IN IF ~totalBidSize.ok THEN Fail ELSE
    LET totalOfferSize == ReadBytes(totalBidSize.rest, 8) IN IF ~totalOfferSize.ok THEN Fail ELSE
    LET bidOrders == ReadBytes(totalOfferSize.rest, 4) IN IF ~bidOrders.ok THEN Fail ELSE
    LET offerOrders == ReadBytes(bidOrders.rest, 4) IN IF ~offerOrders.ok THEN Fail ELSE
    Ok([ instrumentId   |-> instrumentId.value,
         updateType     |-> updateType.value,
         totalBidSize   |-> totalBidSize.value,
         totalOfferSize |-> totalOfferSize.value,
         bidOrders      |-> bidOrders.value,
         offerOrders    |-> offerOrders.value ], offerOrders.rest)

ZeroBidOfferUpdate ==
    [ instrumentId   |-> [i \in 1 .. 4 |-> 0],
      updateType     |-> [i \in 1 .. 1 |-> 0],
      totalBidSize   |-> [i \in 1 .. 8 |-> 0],
      totalOfferSize |-> [i \in 1 .. 8 |-> 0],
      bidOrders      |-> [i \in 1 .. 4 |-> 0],
      offerOrders    |-> [i \in 1 .. 4 |-> 0] ]

(* Bid Offer Update at zero, then each field in turn at the values it is checked at *)
CheckedBidOfferUpdate ==
    { ZeroBidOfferUpdate }
        \cup { [ZeroBidOfferUpdate EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBidOfferUpdate EXCEPT !.updateType = one] : one \in Sample(1) }
        \cup { [ZeroBidOfferUpdate EXCEPT !.totalBidSize = one] : one \in Sample(8) }
        \cup { [ZeroBidOfferUpdate EXCEPT !.totalOfferSize = one] : one \in Sample(8) }
        \cup { [ZeroBidOfferUpdate EXCEPT !.bidOrders = one] : one \in Sample(4) }
        \cup { [ZeroBidOfferUpdate EXCEPT !.offerOrders = one] : one \in Sample(4) }

(***************************************************************************)
(* Client: 5 bytes                                                         *)
(***************************************************************************)

Client5 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeClient5(message) ==
    message.shortCode
        \o message.qualifier

DecodeClient5(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroClient5 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Client at zero, then each field in turn at the values it is checked at *)
CheckedClient5 ==
    { ZeroClient5 }
        \cup { [ZeroClient5 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroClient5 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Executing Trader: 5 bytes                                               *)
(***************************************************************************)

ExecutingTrader6 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeExecutingTrader6(message) ==
    message.shortCode
        \o message.qualifier

DecodeExecutingTrader6(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroExecutingTrader6 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Executing Trader at zero, then each field in turn at the values it is checked at *)
CheckedExecutingTrader6 ==
    { ZeroExecutingTrader6 }
        \cup { [ZeroExecutingTrader6 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutingTrader6 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Investment Decision Maker: 5 bytes                                      *)
(***************************************************************************)

InvestmentDecisionMaker5 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeInvestmentDecisionMaker5(message) ==
    message.shortCode
        \o message.qualifier

DecodeInvestmentDecisionMaker5(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroInvestmentDecisionMaker5 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Investment Decision Maker at zero, then each field in turn at the values it is checked at *)
CheckedInvestmentDecisionMaker5 ==
    { ZeroInvestmentDecisionMaker5 }
        \cup { [ZeroInvestmentDecisionMaker5 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestmentDecisionMaker5 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Fields: 15 bytes                                                  *)
(***************************************************************************)

MifidFields5 ==
    [ client                  : Client5,
      executingTrader         : ExecutingTrader6,
      investmentDecisionMaker : InvestmentDecisionMaker5 ]

EncodeMifidFields5(message) ==
    EncodeClient5(message.client)
        \o EncodeExecutingTrader6(message.executingTrader)
        \o EncodeInvestmentDecisionMaker5(message.investmentDecisionMaker)

DecodeMifidFields5(bytes) ==
    LET client == DecodeClient5(bytes) IN IF ~client.ok THEN Fail ELSE
    LET executingTrader == DecodeExecutingTrader6(client.rest) IN IF ~executingTrader.ok THEN Fail ELSE
    LET investmentDecisionMaker == DecodeInvestmentDecisionMaker5(executingTrader.rest) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    Ok([ client                  |-> client.value,
         executingTrader         |-> executingTrader.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value ], investmentDecisionMaker.rest)

ZeroMifidFields5 ==
    [ client                  |-> ZeroClient5,
      executingTrader         |-> ZeroExecutingTrader6,
      investmentDecisionMaker |-> ZeroInvestmentDecisionMaker5 ]

(* Mifid Fields at zero, then each field in turn at the values it is checked at *)
CheckedMifidFields5 ==
    { ZeroMifidFields5 }
        \cup { [ZeroMifidFields5 EXCEPT !.client = one] : one \in CheckedClient5 }
        \cup { [ZeroMifidFields5 EXCEPT !.executingTrader = one] : one \in CheckedExecutingTrader6 }
        \cup { [ZeroMifidFields5 EXCEPT !.investmentDecisionMaker = one] : one \in CheckedInvestmentDecisionMaker5 }

(***************************************************************************)
(* Tcr Party: 82 bytes                                                     *)
(***************************************************************************)

TcrParty ==
    [ flags                            : Sample(1),
      mifidFields                      : MifidFields5,
      clearingMemberCode               : Sample(20),
      clearingMemberClearingIdentifier : Sample(1),
      account                          : Sample(16),
      accountType                      : Sample(1),
      orderCapacity                    : Sample(1),
      feeStructureId                   : Sample(1),
      interestedParty                  : Sample(8),
      memo                             : Sample(18) ]

EncodeTcrParty(message) ==
    message.flags
        \o EncodeMifidFields5(message.mifidFields)
        \o message.clearingMemberCode
        \o message.clearingMemberClearingIdentifier
        \o message.account
        \o message.accountType
        \o message.orderCapacity
        \o message.feeStructureId
        \o message.interestedParty
        \o message.memo

DecodeTcrParty(bytes) ==
    LET flags == ReadBytes(bytes, 1) IN IF ~flags.ok THEN Fail ELSE
    LET mifidFields == DecodeMifidFields5(flags.rest) IN IF ~mifidFields.ok THEN Fail ELSE
    LET clearingMemberCode == ReadBytes(mifidFields.rest, 20) IN IF ~clearingMemberCode.ok THEN Fail ELSE
    LET clearingMemberClearingIdentifier == ReadBytes(clearingMemberCode.rest, 1) IN IF ~clearingMemberClearingIdentifier.ok THEN Fail ELSE
    LET account == ReadBytes(clearingMemberClearingIdentifier.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET accountType == ReadBytes(account.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(accountType.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET feeStructureId == ReadBytes(orderCapacity.rest, 1) IN IF ~feeStructureId.ok THEN Fail ELSE
    LET interestedParty == ReadBytes(feeStructureId.rest, 8) IN IF ~interestedParty.ok THEN Fail ELSE
    LET memo == ReadBytes(interestedParty.rest, 18) IN IF ~memo.ok THEN Fail ELSE
    Ok([ flags                            |-> flags.value,
         mifidFields                      |-> mifidFields.value,
         clearingMemberCode               |-> clearingMemberCode.value,
         clearingMemberClearingIdentifier |-> clearingMemberClearingIdentifier.value,
         account                          |-> account.value,
         accountType                      |-> accountType.value,
         orderCapacity                    |-> orderCapacity.value,
         feeStructureId                   |-> feeStructureId.value,
         interestedParty                  |-> interestedParty.value,
         memo                             |-> memo.value ], memo.rest)

ZeroTcrParty ==
    [ flags                            |-> [i \in 1 .. 1 |-> 0],
      mifidFields                      |-> ZeroMifidFields5,
      clearingMemberCode               |-> [i \in 1 .. 20 |-> 0],
      clearingMemberClearingIdentifier |-> [i \in 1 .. 1 |-> 0],
      account                          |-> [i \in 1 .. 16 |-> 0],
      accountType                      |-> [i \in 1 .. 1 |-> 0],
      orderCapacity                    |-> [i \in 1 .. 1 |-> 0],
      feeStructureId                   |-> [i \in 1 .. 1 |-> 0],
      interestedParty                  |-> [i \in 1 .. 8 |-> 0],
      memo                             |-> [i \in 1 .. 18 |-> 0] ]

(* Tcr Party at zero, then each field in turn at the values it is checked at *)
CheckedTcrParty ==
    { ZeroTcrParty }
        \cup { [ZeroTcrParty EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroTcrParty EXCEPT !.mifidFields = one] : one \in CheckedMifidFields5 }
        \cup { [ZeroTcrParty EXCEPT !.clearingMemberCode = one] : one \in Sample(20) }
        \cup { [ZeroTcrParty EXCEPT !.clearingMemberClearingIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTcrParty EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroTcrParty EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroTcrParty EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTcrParty EXCEPT !.feeStructureId = one] : one \in Sample(1) }
        \cup { [ZeroTcrParty EXCEPT !.interestedParty = one] : one \in Sample(8) }
        \cup { [ZeroTcrParty EXCEPT !.memo = one] : one \in Sample(18) }

(***************************************************************************)
(* Trade Capture Report Single: 182 bytes                                  *)
(***************************************************************************)

TradeCaptureReportSingle ==
    [ instrumentId              : Sample(4),
      tradeReportId             : Sample(21),
      secondaryTradeReportId    : Sample(8),
      tradeId                   : Sample(4),
      tradeReportTransType      : Sample(1),
      tradeReportType           : Sample(1),
      tradeType                 : Sample(1),
      algorithmicTradeIndicator : Sample(1),
      execType                  : Sample(1),
      tradeReportRefId          : Sample(21),
      lastQty                   : Sample(8),
      lastPx                    : Sample(8),
      settlementDate            : Sample(4),
      side                      : Sample(1),
      counterpartyCode          : Sample(16),
      tcrParty                  : TcrParty ]

EncodeTradeCaptureReportSingle(message) ==
    message.instrumentId
        \o message.tradeReportId
        \o message.secondaryTradeReportId
        \o message.tradeId
        \o message.tradeReportTransType
        \o message.tradeReportType
        \o message.tradeType
        \o message.algorithmicTradeIndicator
        \o message.execType
        \o message.tradeReportRefId
        \o message.lastQty
        \o message.lastPx
        \o message.settlementDate
        \o message.side
        \o message.counterpartyCode
        \o EncodeTcrParty(message.tcrParty)

DecodeTradeCaptureReportSingle(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(instrumentId.rest, 21) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET secondaryTradeReportId == ReadBytes(tradeReportId.rest, 8) IN IF ~secondaryTradeReportId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(secondaryTradeReportId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeId.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(tradeType.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET execType == ReadBytes(algorithmicTradeIndicator.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(execType.rest, 21) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(tradeReportRefId.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(lastPx.rest, 4) IN IF ~settlementDate.ok THEN Fail ELSE
    LET side == ReadBytes(settlementDate.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET counterpartyCode == ReadBytes(side.rest, 16) IN IF ~counterpartyCode.ok THEN Fail ELSE
    LET tcrParty == DecodeTcrParty(counterpartyCode.rest) IN IF ~tcrParty.ok THEN Fail ELSE
    Ok([ instrumentId              |-> instrumentId.value,
         tradeReportId             |-> tradeReportId.value,
         secondaryTradeReportId    |-> secondaryTradeReportId.value,
         tradeId                   |-> tradeId.value,
         tradeReportTransType      |-> tradeReportTransType.value,
         tradeReportType           |-> tradeReportType.value,
         tradeType                 |-> tradeType.value,
         algorithmicTradeIndicator |-> algorithmicTradeIndicator.value,
         execType                  |-> execType.value,
         tradeReportRefId          |-> tradeReportRefId.value,
         lastQty                   |-> lastQty.value,
         lastPx                    |-> lastPx.value,
         settlementDate            |-> settlementDate.value,
         side                      |-> side.value,
         counterpartyCode          |-> counterpartyCode.value,
         tcrParty                  |-> tcrParty.value ], tcrParty.rest)

ZeroTradeCaptureReportSingle ==
    [ instrumentId              |-> [i \in 1 .. 4 |-> 0],
      tradeReportId             |-> [i \in 1 .. 21 |-> 0],
      secondaryTradeReportId    |-> [i \in 1 .. 8 |-> 0],
      tradeId                   |-> [i \in 1 .. 4 |-> 0],
      tradeReportTransType      |-> [i \in 1 .. 1 |-> 0],
      tradeReportType           |-> [i \in 1 .. 1 |-> 0],
      tradeType                 |-> [i \in 1 .. 1 |-> 0],
      algorithmicTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId          |-> [i \in 1 .. 21 |-> 0],
      lastQty                   |-> [i \in 1 .. 8 |-> 0],
      lastPx                    |-> [i \in 1 .. 8 |-> 0],
      settlementDate            |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      counterpartyCode          |-> [i \in 1 .. 16 |-> 0],
      tcrParty                  |-> ZeroTcrParty ]

(* Trade Capture Report Single at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportSingle ==
    { ZeroTradeCaptureReportSingle }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.tradeReportId = one] : one \in Sample(21) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.secondaryTradeReportId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.tradeReportRefId = one] : one \in Sample(21) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.settlementDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.counterpartyCode = one] : one \in Sample(16) }
        \cup { [ZeroTradeCaptureReportSingle EXCEPT !.tcrParty = one] : one \in CheckedTcrParty }

(***************************************************************************)
(* Client: 5 bytes                                                         *)
(***************************************************************************)

Client6 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeClient6(message) ==
    message.shortCode
        \o message.qualifier

DecodeClient6(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroClient6 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Client at zero, then each field in turn at the values it is checked at *)
CheckedClient6 ==
    { ZeroClient6 }
        \cup { [ZeroClient6 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroClient6 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Executing Trader: 5 bytes                                               *)
(***************************************************************************)

ExecutingTrader7 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeExecutingTrader7(message) ==
    message.shortCode
        \o message.qualifier

DecodeExecutingTrader7(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroExecutingTrader7 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Executing Trader at zero, then each field in turn at the values it is checked at *)
CheckedExecutingTrader7 ==
    { ZeroExecutingTrader7 }
        \cup { [ZeroExecutingTrader7 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutingTrader7 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Investment Decision Maker: 5 bytes                                      *)
(***************************************************************************)

InvestmentDecisionMaker6 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeInvestmentDecisionMaker6(message) ==
    message.shortCode
        \o message.qualifier

DecodeInvestmentDecisionMaker6(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroInvestmentDecisionMaker6 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Investment Decision Maker at zero, then each field in turn at the values it is checked at *)
CheckedInvestmentDecisionMaker6 ==
    { ZeroInvestmentDecisionMaker6 }
        \cup { [ZeroInvestmentDecisionMaker6 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestmentDecisionMaker6 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Fields: 15 bytes                                                  *)
(***************************************************************************)

MifidFields6 ==
    [ client                  : Client6,
      executingTrader         : ExecutingTrader7,
      investmentDecisionMaker : InvestmentDecisionMaker6 ]

EncodeMifidFields6(message) ==
    EncodeClient6(message.client)
        \o EncodeExecutingTrader7(message.executingTrader)
        \o EncodeInvestmentDecisionMaker6(message.investmentDecisionMaker)

DecodeMifidFields6(bytes) ==
    LET client == DecodeClient6(bytes) IN IF ~client.ok THEN Fail ELSE
    LET executingTrader == DecodeExecutingTrader7(client.rest) IN IF ~executingTrader.ok THEN Fail ELSE
    LET investmentDecisionMaker == DecodeInvestmentDecisionMaker6(executingTrader.rest) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    Ok([ client                  |-> client.value,
         executingTrader         |-> executingTrader.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value ], investmentDecisionMaker.rest)

ZeroMifidFields6 ==
    [ client                  |-> ZeroClient6,
      executingTrader         |-> ZeroExecutingTrader7,
      investmentDecisionMaker |-> ZeroInvestmentDecisionMaker6 ]

(* Mifid Fields at zero, then each field in turn at the values it is checked at *)
CheckedMifidFields6 ==
    { ZeroMifidFields6 }
        \cup { [ZeroMifidFields6 EXCEPT !.client = one] : one \in CheckedClient6 }
        \cup { [ZeroMifidFields6 EXCEPT !.executingTrader = one] : one \in CheckedExecutingTrader7 }
        \cup { [ZeroMifidFields6 EXCEPT !.investmentDecisionMaker = one] : one \in CheckedInvestmentDecisionMaker6 }

(***************************************************************************)
(* Tcr Party Buy: 82 bytes                                                 *)
(***************************************************************************)

TcrPartyBuy ==
    [ flags                            : Sample(1),
      mifidFields                      : MifidFields6,
      clearingMemberCode               : Sample(20),
      clearingMemberClearingIdentifier : Sample(1),
      account                          : Sample(16),
      accountType                      : Sample(1),
      orderCapacity                    : Sample(1),
      feeStructureId                   : Sample(1),
      interestedParty                  : Sample(8),
      memo                             : Sample(18) ]

EncodeTcrPartyBuy(message) ==
    message.flags
        \o EncodeMifidFields6(message.mifidFields)
        \o message.clearingMemberCode
        \o message.clearingMemberClearingIdentifier
        \o message.account
        \o message.accountType
        \o message.orderCapacity
        \o message.feeStructureId
        \o message.interestedParty
        \o message.memo

DecodeTcrPartyBuy(bytes) ==
    LET flags == ReadBytes(bytes, 1) IN IF ~flags.ok THEN Fail ELSE
    LET mifidFields == DecodeMifidFields6(flags.rest) IN IF ~mifidFields.ok THEN Fail ELSE
    LET clearingMemberCode == ReadBytes(mifidFields.rest, 20) IN IF ~clearingMemberCode.ok THEN Fail ELSE
    LET clearingMemberClearingIdentifier == ReadBytes(clearingMemberCode.rest, 1) IN IF ~clearingMemberClearingIdentifier.ok THEN Fail ELSE
    LET account == ReadBytes(clearingMemberClearingIdentifier.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET accountType == ReadBytes(account.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(accountType.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET feeStructureId == ReadBytes(orderCapacity.rest, 1) IN IF ~feeStructureId.ok THEN Fail ELSE
    LET interestedParty == ReadBytes(feeStructureId.rest, 8) IN IF ~interestedParty.ok THEN Fail ELSE
    LET memo == ReadBytes(interestedParty.rest, 18) IN IF ~memo.ok THEN Fail ELSE
    Ok([ flags                            |-> flags.value,
         mifidFields                      |-> mifidFields.value,
         clearingMemberCode               |-> clearingMemberCode.value,
         clearingMemberClearingIdentifier |-> clearingMemberClearingIdentifier.value,
         account                          |-> account.value,
         accountType                      |-> accountType.value,
         orderCapacity                    |-> orderCapacity.value,
         feeStructureId                   |-> feeStructureId.value,
         interestedParty                  |-> interestedParty.value,
         memo                             |-> memo.value ], memo.rest)

ZeroTcrPartyBuy ==
    [ flags                            |-> [i \in 1 .. 1 |-> 0],
      mifidFields                      |-> ZeroMifidFields6,
      clearingMemberCode               |-> [i \in 1 .. 20 |-> 0],
      clearingMemberClearingIdentifier |-> [i \in 1 .. 1 |-> 0],
      account                          |-> [i \in 1 .. 16 |-> 0],
      accountType                      |-> [i \in 1 .. 1 |-> 0],
      orderCapacity                    |-> [i \in 1 .. 1 |-> 0],
      feeStructureId                   |-> [i \in 1 .. 1 |-> 0],
      interestedParty                  |-> [i \in 1 .. 8 |-> 0],
      memo                             |-> [i \in 1 .. 18 |-> 0] ]

(* Tcr Party Buy at zero, then each field in turn at the values it is checked at *)
CheckedTcrPartyBuy ==
    { ZeroTcrPartyBuy }
        \cup { [ZeroTcrPartyBuy EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartyBuy EXCEPT !.mifidFields = one] : one \in CheckedMifidFields6 }
        \cup { [ZeroTcrPartyBuy EXCEPT !.clearingMemberCode = one] : one \in Sample(20) }
        \cup { [ZeroTcrPartyBuy EXCEPT !.clearingMemberClearingIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartyBuy EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroTcrPartyBuy EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartyBuy EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartyBuy EXCEPT !.feeStructureId = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartyBuy EXCEPT !.interestedParty = one] : one \in Sample(8) }
        \cup { [ZeroTcrPartyBuy EXCEPT !.memo = one] : one \in Sample(18) }

(***************************************************************************)
(* Client: 5 bytes                                                         *)
(***************************************************************************)

Client7 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeClient7(message) ==
    message.shortCode
        \o message.qualifier

DecodeClient7(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroClient7 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Client at zero, then each field in turn at the values it is checked at *)
CheckedClient7 ==
    { ZeroClient7 }
        \cup { [ZeroClient7 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroClient7 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Executing Trader: 5 bytes                                               *)
(***************************************************************************)

ExecutingTrader8 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeExecutingTrader8(message) ==
    message.shortCode
        \o message.qualifier

DecodeExecutingTrader8(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroExecutingTrader8 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Executing Trader at zero, then each field in turn at the values it is checked at *)
CheckedExecutingTrader8 ==
    { ZeroExecutingTrader8 }
        \cup { [ZeroExecutingTrader8 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutingTrader8 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Investment Decision Maker: 5 bytes                                      *)
(***************************************************************************)

InvestmentDecisionMaker7 ==
    [ shortCode : Sample(4),
      qualifier : Sample(1) ]

EncodeInvestmentDecisionMaker7(message) ==
    message.shortCode
        \o message.qualifier

DecodeInvestmentDecisionMaker7(bytes) ==
    LET shortCode == ReadBytes(bytes, 4) IN IF ~shortCode.ok THEN Fail ELSE
    LET qualifier == ReadBytes(shortCode.rest, 1) IN IF ~qualifier.ok THEN Fail ELSE
    Ok([ shortCode |-> shortCode.value,
         qualifier |-> qualifier.value ], qualifier.rest)

ZeroInvestmentDecisionMaker7 ==
    [ shortCode |-> [i \in 1 .. 4 |-> 0],
      qualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Investment Decision Maker at zero, then each field in turn at the values it is checked at *)
CheckedInvestmentDecisionMaker7 ==
    { ZeroInvestmentDecisionMaker7 }
        \cup { [ZeroInvestmentDecisionMaker7 EXCEPT !.shortCode = one] : one \in Sample(4) }
        \cup { [ZeroInvestmentDecisionMaker7 EXCEPT !.qualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Fields: 15 bytes                                                  *)
(***************************************************************************)

MifidFields7 ==
    [ client                  : Client7,
      executingTrader         : ExecutingTrader8,
      investmentDecisionMaker : InvestmentDecisionMaker7 ]

EncodeMifidFields7(message) ==
    EncodeClient7(message.client)
        \o EncodeExecutingTrader8(message.executingTrader)
        \o EncodeInvestmentDecisionMaker7(message.investmentDecisionMaker)

DecodeMifidFields7(bytes) ==
    LET client == DecodeClient7(bytes) IN IF ~client.ok THEN Fail ELSE
    LET executingTrader == DecodeExecutingTrader8(client.rest) IN IF ~executingTrader.ok THEN Fail ELSE
    LET investmentDecisionMaker == DecodeInvestmentDecisionMaker7(executingTrader.rest) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    Ok([ client                  |-> client.value,
         executingTrader         |-> executingTrader.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value ], investmentDecisionMaker.rest)

ZeroMifidFields7 ==
    [ client                  |-> ZeroClient7,
      executingTrader         |-> ZeroExecutingTrader8,
      investmentDecisionMaker |-> ZeroInvestmentDecisionMaker7 ]

(* Mifid Fields at zero, then each field in turn at the values it is checked at *)
CheckedMifidFields7 ==
    { ZeroMifidFields7 }
        \cup { [ZeroMifidFields7 EXCEPT !.client = one] : one \in CheckedClient7 }
        \cup { [ZeroMifidFields7 EXCEPT !.executingTrader = one] : one \in CheckedExecutingTrader8 }
        \cup { [ZeroMifidFields7 EXCEPT !.investmentDecisionMaker = one] : one \in CheckedInvestmentDecisionMaker7 }

(***************************************************************************)
(* Tcr Party Sell: 82 bytes                                                *)
(***************************************************************************)

TcrPartySell ==
    [ flags                            : Sample(1),
      mifidFields                      : MifidFields7,
      clearingMemberCode               : Sample(20),
      clearingMemberClearingIdentifier : Sample(1),
      account                          : Sample(16),
      accountType                      : Sample(1),
      orderCapacity                    : Sample(1),
      feeStructureId                   : Sample(1),
      interestedParty                  : Sample(8),
      memo                             : Sample(18) ]

EncodeTcrPartySell(message) ==
    message.flags
        \o EncodeMifidFields7(message.mifidFields)
        \o message.clearingMemberCode
        \o message.clearingMemberClearingIdentifier
        \o message.account
        \o message.accountType
        \o message.orderCapacity
        \o message.feeStructureId
        \o message.interestedParty
        \o message.memo

DecodeTcrPartySell(bytes) ==
    LET flags == ReadBytes(bytes, 1) IN IF ~flags.ok THEN Fail ELSE
    LET mifidFields == DecodeMifidFields7(flags.rest) IN IF ~mifidFields.ok THEN Fail ELSE
    LET clearingMemberCode == ReadBytes(mifidFields.rest, 20) IN IF ~clearingMemberCode.ok THEN Fail ELSE
    LET clearingMemberClearingIdentifier == ReadBytes(clearingMemberCode.rest, 1) IN IF ~clearingMemberClearingIdentifier.ok THEN Fail ELSE
    LET account == ReadBytes(clearingMemberClearingIdentifier.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET accountType == ReadBytes(account.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(accountType.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET feeStructureId == ReadBytes(orderCapacity.rest, 1) IN IF ~feeStructureId.ok THEN Fail ELSE
    LET interestedParty == ReadBytes(feeStructureId.rest, 8) IN IF ~interestedParty.ok THEN Fail ELSE
    LET memo == ReadBytes(interestedParty.rest, 18) IN IF ~memo.ok THEN Fail ELSE
    Ok([ flags                            |-> flags.value,
         mifidFields                      |-> mifidFields.value,
         clearingMemberCode               |-> clearingMemberCode.value,
         clearingMemberClearingIdentifier |-> clearingMemberClearingIdentifier.value,
         account                          |-> account.value,
         accountType                      |-> accountType.value,
         orderCapacity                    |-> orderCapacity.value,
         feeStructureId                   |-> feeStructureId.value,
         interestedParty                  |-> interestedParty.value,
         memo                             |-> memo.value ], memo.rest)

ZeroTcrPartySell ==
    [ flags                            |-> [i \in 1 .. 1 |-> 0],
      mifidFields                      |-> ZeroMifidFields7,
      clearingMemberCode               |-> [i \in 1 .. 20 |-> 0],
      clearingMemberClearingIdentifier |-> [i \in 1 .. 1 |-> 0],
      account                          |-> [i \in 1 .. 16 |-> 0],
      accountType                      |-> [i \in 1 .. 1 |-> 0],
      orderCapacity                    |-> [i \in 1 .. 1 |-> 0],
      feeStructureId                   |-> [i \in 1 .. 1 |-> 0],
      interestedParty                  |-> [i \in 1 .. 8 |-> 0],
      memo                             |-> [i \in 1 .. 18 |-> 0] ]

(* Tcr Party Sell at zero, then each field in turn at the values it is checked at *)
CheckedTcrPartySell ==
    { ZeroTcrPartySell }
        \cup { [ZeroTcrPartySell EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartySell EXCEPT !.mifidFields = one] : one \in CheckedMifidFields7 }
        \cup { [ZeroTcrPartySell EXCEPT !.clearingMemberCode = one] : one \in Sample(20) }
        \cup { [ZeroTcrPartySell EXCEPT !.clearingMemberClearingIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartySell EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroTcrPartySell EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartySell EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartySell EXCEPT !.feeStructureId = one] : one \in Sample(1) }
        \cup { [ZeroTcrPartySell EXCEPT !.interestedParty = one] : one \in Sample(8) }
        \cup { [ZeroTcrPartySell EXCEPT !.memo = one] : one \in Sample(18) }

(***************************************************************************)
(* Trade Capture Report Dual: 247 bytes                                    *)
(***************************************************************************)

TradeCaptureReportDual ==
    [ instrumentId              : Sample(4),
      tradeReportId             : Sample(21),
      secondaryTradeReportId    : Sample(8),
      tradeId                   : Sample(4),
      tradeReportTransType      : Sample(1),
      tradeReportType           : Sample(1),
      tradeType                 : Sample(1),
      algorithmicTradeIndicator : Sample(1),
      execType                  : Sample(1),
      tradeReportRefId          : Sample(21),
      lastQty                   : Sample(8),
      lastPx                    : Sample(8),
      settlementDate            : Sample(4),
      tcrPartyBuy               : TcrPartyBuy,
      tcrPartySell              : TcrPartySell ]

EncodeTradeCaptureReportDual(message) ==
    message.instrumentId
        \o message.tradeReportId
        \o message.secondaryTradeReportId
        \o message.tradeId
        \o message.tradeReportTransType
        \o message.tradeReportType
        \o message.tradeType
        \o message.algorithmicTradeIndicator
        \o message.execType
        \o message.tradeReportRefId
        \o message.lastQty
        \o message.lastPx
        \o message.settlementDate
        \o EncodeTcrPartyBuy(message.tcrPartyBuy)
        \o EncodeTcrPartySell(message.tcrPartySell)

DecodeTradeCaptureReportDual(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(instrumentId.rest, 21) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET secondaryTradeReportId == ReadBytes(tradeReportId.rest, 8) IN IF ~secondaryTradeReportId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(secondaryTradeReportId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeId.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(tradeType.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET execType == ReadBytes(algorithmicTradeIndicator.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(execType.rest, 21) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(tradeReportRefId.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(lastPx.rest, 4) IN IF ~settlementDate.ok THEN Fail ELSE
    LET tcrPartyBuy == DecodeTcrPartyBuy(settlementDate.rest) IN IF ~tcrPartyBuy.ok THEN Fail ELSE
    LET tcrPartySell == DecodeTcrPartySell(tcrPartyBuy.rest) IN IF ~tcrPartySell.ok THEN Fail ELSE
    Ok([ instrumentId              |-> instrumentId.value,
         tradeReportId             |-> tradeReportId.value,
         secondaryTradeReportId    |-> secondaryTradeReportId.value,
         tradeId                   |-> tradeId.value,
         tradeReportTransType      |-> tradeReportTransType.value,
         tradeReportType           |-> tradeReportType.value,
         tradeType                 |-> tradeType.value,
         algorithmicTradeIndicator |-> algorithmicTradeIndicator.value,
         execType                  |-> execType.value,
         tradeReportRefId          |-> tradeReportRefId.value,
         lastQty                   |-> lastQty.value,
         lastPx                    |-> lastPx.value,
         settlementDate            |-> settlementDate.value,
         tcrPartyBuy               |-> tcrPartyBuy.value,
         tcrPartySell              |-> tcrPartySell.value ], tcrPartySell.rest)

ZeroTradeCaptureReportDual ==
    [ instrumentId              |-> [i \in 1 .. 4 |-> 0],
      tradeReportId             |-> [i \in 1 .. 21 |-> 0],
      secondaryTradeReportId    |-> [i \in 1 .. 8 |-> 0],
      tradeId                   |-> [i \in 1 .. 4 |-> 0],
      tradeReportTransType      |-> [i \in 1 .. 1 |-> 0],
      tradeReportType           |-> [i \in 1 .. 1 |-> 0],
      tradeType                 |-> [i \in 1 .. 1 |-> 0],
      algorithmicTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId          |-> [i \in 1 .. 21 |-> 0],
      lastQty                   |-> [i \in 1 .. 8 |-> 0],
      lastPx                    |-> [i \in 1 .. 8 |-> 0],
      settlementDate            |-> [i \in 1 .. 4 |-> 0],
      tcrPartyBuy               |-> ZeroTcrPartyBuy,
      tcrPartySell              |-> ZeroTcrPartySell ]

(* Trade Capture Report Dual at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportDual ==
    { ZeroTradeCaptureReportDual }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.tradeReportId = one] : one \in Sample(21) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.secondaryTradeReportId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.tradeReportRefId = one] : one \in Sample(21) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.settlementDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.tcrPartyBuy = one] : one \in CheckedTcrPartyBuy }
        \cup { [ZeroTradeCaptureReportDual EXCEPT !.tcrPartySell = one] : one \in CheckedTcrPartySell }

(***************************************************************************)
(* Trade Capture Report Response: 40 bytes                                 *)
(***************************************************************************)

TradeCaptureReportResponse ==
    [ instrumentId             : Sample(4),
      tradeId                  : Sample(4),
      tradeReportId            : Sample(21),
      secondaryTradeReportId   : Sample(8),
      statusTcrStatus          : Sample(1),
      reasonTcrRejectionReason : Sample(2) ]

EncodeTradeCaptureReportResponse(message) ==
    message.instrumentId
        \o message.tradeId
        \o message.tradeReportId
        \o message.secondaryTradeReportId
        \o message.statusTcrStatus
        \o message.reasonTcrRejectionReason

DecodeTradeCaptureReportResponse(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(instrumentId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 21) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET secondaryTradeReportId == ReadBytes(tradeReportId.rest, 8) IN IF ~secondaryTradeReportId.ok THEN Fail ELSE
    LET statusTcrStatus == ReadBytes(secondaryTradeReportId.rest, 1) IN IF ~statusTcrStatus.ok THEN Fail ELSE
    LET reasonTcrRejectionReason == ReadBytes(statusTcrStatus.rest, 2) IN IF ~reasonTcrRejectionReason.ok THEN Fail ELSE
    Ok([ instrumentId             |-> instrumentId.value,
         tradeId                  |-> tradeId.value,
         tradeReportId            |-> tradeReportId.value,
         secondaryTradeReportId   |-> secondaryTradeReportId.value,
         statusTcrStatus          |-> statusTcrStatus.value,
         reasonTcrRejectionReason |-> reasonTcrRejectionReason.value ], reasonTcrRejectionReason.rest)

ZeroTradeCaptureReportResponse ==
    [ instrumentId             |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 4 |-> 0],
      tradeReportId            |-> [i \in 1 .. 21 |-> 0],
      secondaryTradeReportId   |-> [i \in 1 .. 8 |-> 0],
      statusTcrStatus          |-> [i \in 1 .. 1 |-> 0],
      reasonTcrRejectionReason |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Capture Report Response at zero, then each field in turn at the values it is checked at *)
CheckedTradeCaptureReportResponse ==
    { ZeroTradeCaptureReportResponse }
        \cup { [ZeroTradeCaptureReportResponse EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCaptureReportResponse EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCaptureReportResponse EXCEPT !.tradeReportId = one] : one \in Sample(21) }
        \cup { [ZeroTradeCaptureReportResponse EXCEPT !.secondaryTradeReportId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCaptureReportResponse EXCEPT !.statusTcrStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradeCaptureReportResponse EXCEPT !.reasonTcrRejectionReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Bust: 4 bytes                                                     *)
(***************************************************************************)

TradeBust ==
    [ tradeId : Sample(4) ]

EncodeTradeBust(message) ==
    message.tradeId

DecodeTradeBust(bytes) ==
    LET tradeId == ReadBytes(bytes, 4) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ tradeId |-> tradeId.value ], tradeId.rest)

ZeroTradeBust ==
    [ tradeId |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Bust at zero, then each field in turn at the values it is checked at *)
CheckedTradeBust ==
    { ZeroTradeBust }
        \cup { [ZeroTradeBust EXCEPT !.tradeId = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LoginCode == 2  \* 0x02
LoginResponseCode == 3  \* 0x03
LogoutCode == 11  \* 0x0b
LogoutResponseCode == 14  \* 0x0e
ConnectionCloseCode == 12  \* 0x0c
HeartbeatCode == 13  \* 0x0d
RejectCode == 15  \* 0x0f
GapFillCode == 34  \* 0x22
TestCode == 1  \* 0x01
TestEventCode == 255  \* 0xff
TradingSessionStatusCode == 35  \* 0x23
OrderAddCode == 4  \* 0x04
OrderAddResponseCode == 5  \* 0x05
OrderCancelCode == 6  \* 0x06
OrderCancelResponseCode == 7  \* 0x07
OrderModifyCode == 8  \* 0x08
OrderModifyResponseCode == 9  \* 0x09
OrderMassCancelCode == 29  \* 0x1d
OrderMassCancelResponseCode == 30  \* 0x1e
OrderExecuteCode == 10  \* 0x0a
MassQuoteCode == 24  \* 0x18
MassQuoteResponseCode == 25  \* 0x19
MarketMakerCommandCode == 32  \* 0x20
MarketMakerCommandResponseCode == 33  \* 0x21
RequestForExecutionCode == 28  \* 0x1c
BidOfferUpdateCode == 31  \* 0x1f
TradeCaptureReportSingleCode == 18  \* 0x12
TradeCaptureReportDualCode == 19  \* 0x13
TradeCaptureReportResponseCode == 20  \* 0x14
TradeBustCode == 23  \* 0x17

Payload ==
    [ tag : {LoginCode}, body : Login ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {LogoutCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutResponseCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ConnectionCloseCode}, body : ConnectionClose ]
        \cup [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RejectCode}, body : Reject ]
        \cup [ tag : {GapFillCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestCode}, body : Test ]
        \cup [ tag : {TestEventCode}, body : TestEvent ]
        \cup [ tag : {TradingSessionStatusCode}, body : TradingSessionStatus ]
        \cup [ tag : {OrderAddCode}, body : OrderAdd ]
        \cup [ tag : {OrderAddResponseCode}, body : OrderAddResponse ]
        \cup [ tag : {OrderCancelCode}, body : OrderCancel ]
        \cup [ tag : {OrderCancelResponseCode}, body : OrderCancelResponse ]
        \cup [ tag : {OrderModifyCode}, body : OrderModify ]
        \cup [ tag : {OrderModifyResponseCode}, body : OrderModifyResponse ]
        \cup [ tag : {OrderMassCancelCode}, body : OrderMassCancel ]
        \cup [ tag : {OrderMassCancelResponseCode}, body : OrderMassCancelResponse ]
        \cup [ tag : {OrderExecuteCode}, body : OrderExecute ]
        \cup [ tag : {MassQuoteCode}, body : MassQuote ]
        \cup [ tag : {MassQuoteResponseCode}, body : MassQuoteResponse ]
        \cup [ tag : {MarketMakerCommandCode}, body : MarketMakerCommand ]
        \cup [ tag : {MarketMakerCommandResponseCode}, body : MarketMakerCommandResponse ]
        \cup [ tag : {RequestForExecutionCode}, body : RequestForExecution ]
        \cup [ tag : {BidOfferUpdateCode}, body : BidOfferUpdate ]
        \cup [ tag : {TradeCaptureReportSingleCode}, body : TradeCaptureReportSingle ]
        \cup [ tag : {TradeCaptureReportDualCode}, body : TradeCaptureReportDual ]
        \cup [ tag : {TradeCaptureReportResponseCode}, body : TradeCaptureReportResponse ]
        \cup [ tag : {TradeBustCode}, body : TradeBust ]

EncodePayload(message) ==
    CASE message.tag = LoginCode -> EncodeLogin(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = LogoutCode -> << >>
      [] message.tag = LogoutResponseCode -> << >>
      [] message.tag = ConnectionCloseCode -> EncodeConnectionClose(message.body)
      [] message.tag = HeartbeatCode -> << >>
      [] message.tag = RejectCode -> EncodeReject(message.body)
      [] message.tag = GapFillCode -> << >>
      [] message.tag = TestCode -> EncodeTest(message.body)
      [] message.tag = TestEventCode -> EncodeTestEvent(message.body)
      [] message.tag = TradingSessionStatusCode -> EncodeTradingSessionStatus(message.body)
      [] message.tag = OrderAddCode -> EncodeOrderAdd(message.body)
      [] message.tag = OrderAddResponseCode -> EncodeOrderAddResponse(message.body)
      [] message.tag = OrderCancelCode -> EncodeOrderCancel(message.body)
      [] message.tag = OrderCancelResponseCode -> EncodeOrderCancelResponse(message.body)
      [] message.tag = OrderModifyCode -> EncodeOrderModify(message.body)
      [] message.tag = OrderModifyResponseCode -> EncodeOrderModifyResponse(message.body)
      [] message.tag = OrderMassCancelCode -> EncodeOrderMassCancel(message.body)
      [] message.tag = OrderMassCancelResponseCode -> EncodeOrderMassCancelResponse(message.body)
      [] message.tag = OrderExecuteCode -> EncodeOrderExecute(message.body)
      [] message.tag = MassQuoteCode -> EncodeMassQuote(message.body)
      [] message.tag = MassQuoteResponseCode -> EncodeMassQuoteResponse(message.body)
      [] message.tag = MarketMakerCommandCode -> EncodeMarketMakerCommand(message.body)
      [] message.tag = MarketMakerCommandResponseCode -> EncodeMarketMakerCommandResponse(message.body)
      [] message.tag = RequestForExecutionCode -> EncodeRequestForExecution(message.body)
      [] message.tag = BidOfferUpdateCode -> EncodeBidOfferUpdate(message.body)
      [] message.tag = TradeCaptureReportSingleCode -> EncodeTradeCaptureReportSingle(message.body)
      [] message.tag = TradeCaptureReportDualCode -> EncodeTradeCaptureReportDual(message.body)
      [] message.tag = TradeCaptureReportResponseCode -> EncodeTradeCaptureReportResponse(message.body)
      [] message.tag = TradeBustCode -> EncodeTradeBust(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginCode -> DecodeLogin(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = LogoutCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutResponseCode -> Ok([empty |-> 0], bytes)
              [] tag = ConnectionCloseCode -> DecodeConnectionClose(bytes)
              [] tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = RejectCode -> DecodeReject(bytes)
              [] tag = GapFillCode -> Ok([empty |-> 0], bytes)
              [] tag = TestCode -> DecodeTest(bytes)
              [] tag = TestEventCode -> DecodeTestEvent(bytes)
              [] tag = TradingSessionStatusCode -> DecodeTradingSessionStatus(bytes)
              [] tag = OrderAddCode -> DecodeOrderAdd(bytes)
              [] tag = OrderAddResponseCode -> DecodeOrderAddResponse(bytes)
              [] tag = OrderCancelCode -> DecodeOrderCancel(bytes)
              [] tag = OrderCancelResponseCode -> DecodeOrderCancelResponse(bytes)
              [] tag = OrderModifyCode -> DecodeOrderModify(bytes)
              [] tag = OrderModifyResponseCode -> DecodeOrderModifyResponse(bytes)
              [] tag = OrderMassCancelCode -> DecodeOrderMassCancel(bytes)
              [] tag = OrderMassCancelResponseCode -> DecodeOrderMassCancelResponse(bytes)
              [] tag = OrderExecuteCode -> DecodeOrderExecute(bytes)
              [] tag = MassQuoteCode -> DecodeMassQuote(bytes)
              [] tag = MassQuoteResponseCode -> DecodeMassQuoteResponse(bytes)
              [] tag = MarketMakerCommandCode -> DecodeMarketMakerCommand(bytes)
              [] tag = MarketMakerCommandResponseCode -> DecodeMarketMakerCommandResponse(bytes)
              [] tag = RequestForExecutionCode -> DecodeRequestForExecution(bytes)
              [] tag = BidOfferUpdateCode -> DecodeBidOfferUpdate(bytes)
              [] tag = TradeCaptureReportSingleCode -> DecodeTradeCaptureReportSingle(bytes)
              [] tag = TradeCaptureReportDualCode -> DecodeTradeCaptureReportDual(bytes)
              [] tag = TradeCaptureReportResponseCode -> DecodeTradeCaptureReportResponse(bytes)
              [] tag = TradeBustCode -> DecodeTradeBust(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginCode, body |-> ZeroLogin]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginCode, body |-> one] : one \in CheckedLogin }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> LogoutCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutResponseCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ConnectionCloseCode, body |-> one] : one \in CheckedConnectionClose }
        \cup { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RejectCode, body |-> one] : one \in CheckedReject }
        \cup { [tag |-> GapFillCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestCode, body |-> one] : one \in CheckedTest }
        \cup { [tag |-> TestEventCode, body |-> one] : one \in CheckedTestEvent }
        \cup { [tag |-> TradingSessionStatusCode, body |-> one] : one \in CheckedTradingSessionStatus }
        \cup { [tag |-> OrderAddCode, body |-> one] : one \in CheckedOrderAdd }
        \cup { [tag |-> OrderAddResponseCode, body |-> one] : one \in CheckedOrderAddResponse }
        \cup { [tag |-> OrderCancelCode, body |-> one] : one \in CheckedOrderCancel }
        \cup { [tag |-> OrderCancelResponseCode, body |-> one] : one \in CheckedOrderCancelResponse }
        \cup { [tag |-> OrderModifyCode, body |-> one] : one \in CheckedOrderModify }
        \cup { [tag |-> OrderModifyResponseCode, body |-> one] : one \in CheckedOrderModifyResponse }
        \cup { [tag |-> OrderMassCancelCode, body |-> one] : one \in CheckedOrderMassCancel }
        \cup { [tag |-> OrderMassCancelResponseCode, body |-> one] : one \in CheckedOrderMassCancelResponse }
        \cup { [tag |-> OrderExecuteCode, body |-> one] : one \in CheckedOrderExecute }
        \cup { [tag |-> MassQuoteCode, body |-> one] : one \in CheckedMassQuote }
        \cup { [tag |-> MassQuoteResponseCode, body |-> one] : one \in CheckedMassQuoteResponse }
        \cup { [tag |-> MarketMakerCommandCode, body |-> one] : one \in CheckedMarketMakerCommand }
        \cup { [tag |-> MarketMakerCommandResponseCode, body |-> one] : one \in CheckedMarketMakerCommandResponse }
        \cup { [tag |-> RequestForExecutionCode, body |-> one] : one \in CheckedRequestForExecution }
        \cup { [tag |-> BidOfferUpdateCode, body |-> one] : one \in CheckedBidOfferUpdate }
        \cup { [tag |-> TradeCaptureReportSingleCode, body |-> one] : one \in CheckedTradeCaptureReportSingle }
        \cup { [tag |-> TradeCaptureReportDualCode, body |-> one] : one \in CheckedTradeCaptureReportDual }
        \cup { [tag |-> TradeCaptureReportResponseCode, body |-> one] : one \in CheckedTradeCaptureReportResponse }
        \cup { [tag |-> TradeBustCode, body |-> one] : one \in CheckedTradeBust }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messageLength   : 0 .. 255,
      sequenceNumber  : Sample(4),
      timestamp       : Sample(8),
      sourceTimestamp : Sample(8),
      payload         : Payload ]

EncodeMessage(message) ==
    EncodeUIntLE(message.messageLength, 2)
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.sequenceNumber
        \o message.timestamp
        \o message.sourceTimestamp
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET messageLength == ReadUIntLE(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageType == ReadUIntLE(messageLength.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(messageType.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sequenceNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET sourceTimestamp == ReadBytes(timestamp.rest, 8) IN IF ~sourceTimestamp.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, sourceTimestamp.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ messageLength   |-> messageLength.value,
         sequenceNumber  |-> sequenceNumber.value,
         timestamp       |-> timestamp.value,
         sourceTimestamp |-> sourceTimestamp.value,
         payload         |-> payload.value ], payload.rest)

ZeroMessage ==
    [ messageLength   |-> 0,
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      sourceTimestamp |-> [i \in 1 .. 8 |-> 0],
      payload         |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessage EXCEPT !.sourceTimestamp = one] : one \in Sample(8) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> LoginCode, body |-> ZeroLogin]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutResponseCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ConnectionCloseCode, body |-> ZeroConnectionClose]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RejectCode, body |-> ZeroReject]],
      [ZeroMessage EXCEPT !.payload = [tag |-> GapFillCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TestCode, body |-> ZeroTest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TestEventCode, body |-> ZeroTestEvent]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingSessionStatusCode, body |-> ZeroTradingSessionStatus]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddCode, body |-> ZeroOrderAdd]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddResponseCode, body |-> ZeroOrderAddResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelCode, body |-> ZeroOrderCancel]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelResponseCode, body |-> ZeroOrderCancelResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyCode, body |-> ZeroOrderModify]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyResponseCode, body |-> ZeroOrderModifyResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMassCancelCode, body |-> ZeroOrderMassCancel]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMassCancelResponseCode, body |-> ZeroOrderMassCancelResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecuteCode, body |-> ZeroOrderExecute]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassQuoteCode, body |-> ZeroMassQuote]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassQuoteResponseCode, body |-> ZeroMassQuoteResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketMakerCommandCode, body |-> ZeroMarketMakerCommand]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketMakerCommandResponseCode, body |-> ZeroMarketMakerCommandResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestForExecutionCode, body |-> ZeroRequestForExecution]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BidOfferUpdateCode, body |-> ZeroBidOfferUpdate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCaptureReportSingleCode, body |-> ZeroTradeCaptureReportSingle]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCaptureReportDualCode, body |-> ZeroTradeCaptureReportDual]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCaptureReportResponseCode, body |-> ZeroTradeCaptureReportResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustCode, body |-> ZeroTradeBust]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
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

(* Every Login decodes back to what was encoded, and leaves nothing over *)
RoundTripLogin ==
    \A message \in CheckedLogin :
        LET read == DecodeLogin(EncodeLogin(message))
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

(* Every Connection Close decodes back to what was encoded, and leaves nothing over *)
RoundTripConnectionClose ==
    \A message \in CheckedConnectionClose :
        LET read == DecodeConnectionClose(EncodeConnectionClose(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripReject ==
    \A message \in CheckedReject :
        LET read == DecodeReject(EncodeReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test decodes back to what was encoded, and leaves nothing over *)
RoundTripTest ==
    \A message \in CheckedTest :
        LET read == DecodeTest(EncodeTest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Event decodes back to what was encoded, and leaves nothing over *)
RoundTripTestEvent ==
    \A message \in CheckedTestEvent :
        LET read == DecodeTestEvent(EncodeTestEvent(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Status decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatus ==
    \A message \in CheckedTradingSessionStatus :
        LET read == DecodeTradingSessionStatus(EncodeTradingSessionStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client decodes back to what was encoded, and leaves nothing over *)
RoundTripClient ==
    \A message \in CheckedClient :
        LET read == DecodeClient(EncodeClient(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executing Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutingTrader ==
    \A message \in CheckedExecutingTrader :
        LET read == DecodeExecutingTrader(EncodeExecutingTrader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investment Decision Maker decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestmentDecisionMaker ==
    \A message \in CheckedInvestmentDecisionMaker :
        LET read == DecodeInvestmentDecisionMaker(EncodeInvestmentDecisionMaker(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFields ==
    \A message \in CheckedMifidFields :
        LET read == DecodeMifidFields(EncodeMifidFields(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Add decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAdd ==
    \A message \in CheckedOrderAdd :
        LET read == DecodeOrderAdd(EncodeOrderAdd(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Add Response decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddResponse ==
    \A message \in CheckedOrderAddResponse :
        LET read == DecodeOrderAddResponse(EncodeOrderAddResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client decodes back to what was encoded, and leaves nothing over *)
RoundTripClient2 ==
    \A message \in CheckedClient2 :
        LET read == DecodeClient2(EncodeClient2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executing Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutingTrader2 ==
    \A message \in CheckedExecutingTrader2 :
        LET read == DecodeExecutingTrader2(EncodeExecutingTrader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investment Decision Maker decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestmentDecisionMaker2 ==
    \A message \in CheckedInvestmentDecisionMaker2 :
        LET read == DecodeInvestmentDecisionMaker2(EncodeInvestmentDecisionMaker2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFields2 ==
    \A message \in CheckedMifidFields2 :
        LET read == DecodeMifidFields2(EncodeMifidFields2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancel ==
    \A message \in CheckedOrderCancel :
        LET read == DecodeOrderCancel(EncodeOrderCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelResponse ==
    \A message \in CheckedOrderCancelResponse :
        LET read == DecodeOrderCancelResponse(EncodeOrderCancelResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client decodes back to what was encoded, and leaves nothing over *)
RoundTripClient3 ==
    \A message \in CheckedClient3 :
        LET read == DecodeClient3(EncodeClient3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executing Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutingTrader3 ==
    \A message \in CheckedExecutingTrader3 :
        LET read == DecodeExecutingTrader3(EncodeExecutingTrader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investment Decision Maker decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestmentDecisionMaker3 ==
    \A message \in CheckedInvestmentDecisionMaker3 :
        LET read == DecodeInvestmentDecisionMaker3(EncodeInvestmentDecisionMaker3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFields3 ==
    \A message \in CheckedMifidFields3 :
        LET read == DecodeMifidFields3(EncodeMifidFields3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModify ==
    \A message \in CheckedOrderModify :
        LET read == DecodeOrderModify(EncodeOrderModify(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Response decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyResponse ==
    \A message \in CheckedOrderModifyResponse :
        LET read == DecodeOrderModifyResponse(EncodeOrderModifyResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executing Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutingTrader4 ==
    \A message \in CheckedExecutingTrader4 :
        LET read == DecodeExecutingTrader4(EncodeExecutingTrader4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancel ==
    \A message \in CheckedOrderMassCancel :
        LET read == DecodeOrderMassCancel(EncodeOrderMassCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelResponse ==
    \A message \in CheckedOrderMassCancelResponse :
        LET read == DecodeOrderMassCancelResponse(EncodeOrderMassCancelResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execute decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecute ==
    \A message \in CheckedOrderExecute :
        LET read == DecodeOrderExecute(EncodeOrderExecute(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client decodes back to what was encoded, and leaves nothing over *)
RoundTripClient4 ==
    \A message \in CheckedClient4 :
        LET read == DecodeClient4(EncodeClient4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executing Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutingTrader5 ==
    \A message \in CheckedExecutingTrader5 :
        LET read == DecodeExecutingTrader5(EncodeExecutingTrader5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investment Decision Maker decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestmentDecisionMaker4 ==
    \A message \in CheckedInvestmentDecisionMaker4 :
        LET read == DecodeInvestmentDecisionMaker4(EncodeInvestmentDecisionMaker4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFields4 ==
    \A message \in CheckedMifidFields4 :
        LET read == DecodeMifidFields4(EncodeMifidFields4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid decodes back to what was encoded, and leaves nothing over *)
RoundTripBid ==
    \A message \in CheckedBid :
        LET read == DecodeBid(EncodeBid(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask decodes back to what was encoded, and leaves nothing over *)
RoundTripAsk ==
    \A message \in CheckedAsk :
        LET read == DecodeAsk(EncodeAsk(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote ==
    \A message \in CheckedQuote :
        LET read == DecodeQuote(EncodeQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Items Quotes Array decodes back to what was encoded, and leaves nothing over *)
RoundTripItemsQuotesArray ==
    \A message \in CheckedItemsQuotesArray :
        LET read == DecodeItemsQuotesArray(EncodeItemsQuotesArray(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quotes decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotes ==
    \A message \in CheckedQuotes :
        LET read == DecodeQuotes(EncodeQuotes(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuote ==
    \A message \in CheckedMassQuote :
        LET read == DecodeMassQuote(EncodeMassQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteOrderResponse ==
    \A message \in CheckedQuoteOrderResponse :
        LET read == DecodeQuoteOrderResponse(EncodeQuoteOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Items Quote Order Response Array decodes back to what was encoded, and leaves nothing over *)
RoundTripItemsQuoteOrderResponseArray ==
    \A message \in CheckedItemsQuoteOrderResponseArray :
        LET read == DecodeItemsQuoteOrderResponseArray(EncodeItemsQuoteOrderResponseArray(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Responses decodes back to what was encoded, and leaves nothing over *)
RoundTripResponses ==
    \A message \in CheckedResponses :
        LET read == DecodeResponses(EncodeResponses(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponse ==
    \A message \in CheckedMassQuoteResponse :
        LET read == DecodeMassQuoteResponse(EncodeMassQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Maker Command decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketMakerCommand ==
    \A message \in CheckedMarketMakerCommand :
        LET read == DecodeMarketMakerCommand(EncodeMarketMakerCommand(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Maker Command Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketMakerCommandResponse ==
    \A message \in CheckedMarketMakerCommandResponse :
        LET read == DecodeMarketMakerCommandResponse(EncodeMarketMakerCommandResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Execution decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForExecution ==
    \A message \in CheckedRequestForExecution :
        LET read == DecodeRequestForExecution(EncodeRequestForExecution(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Offer Update decodes back to what was encoded, and leaves nothing over *)
RoundTripBidOfferUpdate ==
    \A message \in CheckedBidOfferUpdate :
        LET read == DecodeBidOfferUpdate(EncodeBidOfferUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client decodes back to what was encoded, and leaves nothing over *)
RoundTripClient5 ==
    \A message \in CheckedClient5 :
        LET read == DecodeClient5(EncodeClient5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executing Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutingTrader6 ==
    \A message \in CheckedExecutingTrader6 :
        LET read == DecodeExecutingTrader6(EncodeExecutingTrader6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investment Decision Maker decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestmentDecisionMaker5 ==
    \A message \in CheckedInvestmentDecisionMaker5 :
        LET read == DecodeInvestmentDecisionMaker5(EncodeInvestmentDecisionMaker5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFields5 ==
    \A message \in CheckedMifidFields5 :
        LET read == DecodeMifidFields5(EncodeMifidFields5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcr Party decodes back to what was encoded, and leaves nothing over *)
RoundTripTcrParty ==
    \A message \in CheckedTcrParty :
        LET read == DecodeTcrParty(EncodeTcrParty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Capture Report Single decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportSingle ==
    \A message \in CheckedTradeCaptureReportSingle :
        LET read == DecodeTradeCaptureReportSingle(EncodeTradeCaptureReportSingle(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client decodes back to what was encoded, and leaves nothing over *)
RoundTripClient6 ==
    \A message \in CheckedClient6 :
        LET read == DecodeClient6(EncodeClient6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executing Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutingTrader7 ==
    \A message \in CheckedExecutingTrader7 :
        LET read == DecodeExecutingTrader7(EncodeExecutingTrader7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investment Decision Maker decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestmentDecisionMaker6 ==
    \A message \in CheckedInvestmentDecisionMaker6 :
        LET read == DecodeInvestmentDecisionMaker6(EncodeInvestmentDecisionMaker6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFields6 ==
    \A message \in CheckedMifidFields6 :
        LET read == DecodeMifidFields6(EncodeMifidFields6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcr Party Buy decodes back to what was encoded, and leaves nothing over *)
RoundTripTcrPartyBuy ==
    \A message \in CheckedTcrPartyBuy :
        LET read == DecodeTcrPartyBuy(EncodeTcrPartyBuy(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client decodes back to what was encoded, and leaves nothing over *)
RoundTripClient7 ==
    \A message \in CheckedClient7 :
        LET read == DecodeClient7(EncodeClient7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executing Trader decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutingTrader8 ==
    \A message \in CheckedExecutingTrader8 :
        LET read == DecodeExecutingTrader8(EncodeExecutingTrader8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Investment Decision Maker decodes back to what was encoded, and leaves nothing over *)
RoundTripInvestmentDecisionMaker7 ==
    \A message \in CheckedInvestmentDecisionMaker7 :
        LET read == DecodeInvestmentDecisionMaker7(EncodeInvestmentDecisionMaker7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFields7 ==
    \A message \in CheckedMifidFields7 :
        LET read == DecodeMifidFields7(EncodeMifidFields7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcr Party Sell decodes back to what was encoded, and leaves nothing over *)
RoundTripTcrPartySell ==
    \A message \in CheckedTcrPartySell :
        LET read == DecodeTcrPartySell(EncodeTcrPartySell(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Capture Report Dual decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportDual ==
    \A message \in CheckedTradeCaptureReportDual :
        LET read == DecodeTradeCaptureReportDual(EncodeTradeCaptureReportDual(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Capture Report Response decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCaptureReportResponse ==
    \A message \in CheckedTradeCaptureReportResponse :
        LET read == DecodeTradeCaptureReportResponse(EncodeTradeCaptureReportResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBust ==
    \A message \in CheckedTradeBust :
        LET read == DecodeTradeBust(EncodeTradeBust(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
