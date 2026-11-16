---------- MODULE TsxAlpha_QuantumFeedLevel1Recovery_v2_2_Server -----------
(***************************************************************************)
(* TMX Group Quantum Feed Level 1 Recovery v2.2                            *)
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
(* Note: Server Body is chosen by the Msg Type each of its messages begins *)
(* with: those 1 bytes are read at offset 2 before one is picked, and each *)
(* message states its own.                                                 *)
(*                                                                         *)
(* Note: Admin Body closes the bytes Msg Length frames, so it is read to   *)
(* the end of them rather than from Num Body, which this record does not   *)
(* read.                                                                   *)
(*                                                                         *)
(* Note: Body closes the bytes Msg Length frames, so it is read to the end *)
(* of them rather than from Num Body, which this record does not read.     *)
(*                                                                         *)
(* Note: Body Message is read where it lies, so the choice it carries is   *)
(* read in the record holding the field it is keyed on.                    *)
(*                                                                         *)
(* Note: Sequence Jump Record closes the bytes Msg Length frames, so it is *)
(* read to the end of them rather than from Num Body, which this record    *)
(* does not read.                                                          *)
(*                                                                         *)
(* Note: Rejected Business Header closes the bytes Msg Length frames, so   *)
(* it is read to the end of them rather than from Num Body, which this     *)
(* record does not read.                                                   *)
(*                                                                         *)
(* Note: Server Body and what follows it are read only when the message    *)
(* runs on past what precedes them.                                        *)
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
(* Admin Body: 8 bytes                                                     *)
(***************************************************************************)

AdminBody ==
    [ sourceId  : Sample(1),
      streamId  : Sample(2),
      sequence0 : Sample(1),
      sequence1 : Sample(4) ]

EncodeAdminBody(message) ==
    message.sourceId
        \o message.streamId
        \o message.sequence0
        \o message.sequence1

DecodeAdminBody(bytes) ==
    LET sourceId == ReadBytes(bytes, 1) IN IF ~sourceId.ok THEN Fail ELSE
    LET streamId == ReadBytes(sourceId.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET sequence0 == ReadBytes(streamId.rest, 1) IN IF ~sequence0.ok THEN Fail ELSE
    LET sequence1 == ReadBytes(sequence0.rest, 4) IN IF ~sequence1.ok THEN Fail ELSE
    Ok([ sourceId  |-> sourceId.value,
         streamId  |-> streamId.value,
         sequence0 |-> sequence0.value,
         sequence1 |-> sequence1.value ], sequence1.rest)

ZeroAdminBody ==
    [ sourceId  |-> [i \in 1 .. 1 |-> 0],
      streamId  |-> [i \in 1 .. 2 |-> 0],
      sequence0 |-> [i \in 1 .. 1 |-> 0],
      sequence1 |-> [i \in 1 .. 4 |-> 0] ]

(* Admin Body at zero, then each field in turn at the values it is checked at *)
CheckedAdminBody ==
    { ZeroAdminBody }
        \cup { [ZeroAdminBody EXCEPT !.sourceId = one] : one \in Sample(1) }
        \cup { [ZeroAdminBody EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroAdminBody EXCEPT !.sequence0 = one] : one \in Sample(1) }
        \cup { [ZeroAdminBody EXCEPT !.sequence1 = one] : one \in Sample(4) }

(* A run of Admin Body, written one after another *)
RECURSIVE EncodeAdminBodyList(_)
EncodeAdminBodyList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAdminBody(Head(messages)) \o EncodeAdminBodyList(Tail(messages))

(* As many Admin Body as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadAdminBodyAll(_)
ReadAdminBodyAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeAdminBody(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAdminBodyAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Admin Body of each kind, for the lists that carry them *)
OneAdminBody == { ZeroAdminBody }

(***************************************************************************)
(* Heartbeat Body, framed by Msg Length                                    *)
(***************************************************************************)

HeartbeatBody ==
    [ adminId    : Sample(1),
      hbInterval : Sample(2),
      adminBody  : SampleLists(OneAdminBody) ]

EncodeHeartbeatBodyBody(message) ==
    EncodeUIntBE(48, 1)
        \o message.adminId
        \o message.hbInterval
        \o EncodeAdminBodyList(message.adminBody)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeHeartbeatBody(message) ==
    LET body == EncodeHeartbeatBodyBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeHeartbeatBodyBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    LET hbInterval == ReadBytes(adminId.rest, 2) IN IF ~hbInterval.ok THEN Fail ELSE
    LET adminBody == ReadAdminBodyAll(hbInterval.rest) IN IF ~adminBody.ok THEN Fail ELSE
    Ok([ adminId    |-> adminId.value,
         hbInterval |-> hbInterval.value,
         adminBody  |-> adminBody.value ], adminBody.rest)

DecodeHeartbeatBody(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeHeartbeatBodyBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroHeartbeatBody ==
    [ adminId    |-> [i \in 1 .. 1 |-> 0],
      hbInterval |-> [i \in 1 .. 2 |-> 0],
      adminBody  |-> << >> ]

(* Heartbeat Body at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatBody ==
    { ZeroHeartbeatBody }
        \cup { [ZeroHeartbeatBody EXCEPT !.adminId = one] : one \in Sample(1) }
        \cup { [ZeroHeartbeatBody EXCEPT !.hbInterval = one] : one \in Sample(2) }
        \cup { [ZeroHeartbeatBody EXCEPT !.adminBody = one] : one \in SampleLists(OneAdminBody) }

(***************************************************************************)
(* Login Response, framed by Msg Length                                    *)
(***************************************************************************)

LoginResponse ==
    [ adminId       : Sample(1),
      hbInterval    : Sample(2),
      replayWinSize : Sample(2),
      replayWinNum  : Sample(2),
      replayWin     : Sample(1),
      credits       : Sample(2) ]

EncodeLoginResponseBody(message) ==
    EncodeUIntBE(50, 1)
        \o message.adminId
        \o message.hbInterval
        \o message.replayWinSize
        \o message.replayWinNum
        \o message.replayWin
        \o message.credits

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeLoginResponse(message) ==
    LET body == EncodeLoginResponseBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeLoginResponseBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    LET hbInterval == ReadBytes(adminId.rest, 2) IN IF ~hbInterval.ok THEN Fail ELSE
    LET replayWinSize == ReadBytes(hbInterval.rest, 2) IN IF ~replayWinSize.ok THEN Fail ELSE
    LET replayWinNum == ReadBytes(replayWinSize.rest, 2) IN IF ~replayWinNum.ok THEN Fail ELSE
    LET replayWin == ReadBytes(replayWinNum.rest, 1) IN IF ~replayWin.ok THEN Fail ELSE
    LET credits == ReadBytes(replayWin.rest, 2) IN IF ~credits.ok THEN Fail ELSE
    Ok([ adminId       |-> adminId.value,
         hbInterval    |-> hbInterval.value,
         replayWinSize |-> replayWinSize.value,
         replayWinNum  |-> replayWinNum.value,
         replayWin     |-> replayWin.value,
         credits       |-> credits.value ], credits.rest)

DecodeLoginResponse(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeLoginResponseBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroLoginResponse ==
    [ adminId       |-> [i \in 1 .. 1 |-> 0],
      hbInterval    |-> [i \in 1 .. 2 |-> 0],
      replayWinSize |-> [i \in 1 .. 2 |-> 0],
      replayWinNum  |-> [i \in 1 .. 2 |-> 0],
      replayWin     |-> [i \in 1 .. 1 |-> 0],
      credits       |-> [i \in 1 .. 2 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.adminId = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.hbInterval = one] : one \in Sample(2) }
        \cup { [ZeroLoginResponse EXCEPT !.replayWinSize = one] : one \in Sample(2) }
        \cup { [ZeroLoginResponse EXCEPT !.replayWinNum = one] : one \in Sample(2) }
        \cup { [ZeroLoginResponse EXCEPT !.replayWin = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.credits = one] : one \in Sample(2) }

(***************************************************************************)
(* Business Header: 9 bytes                                                *)
(***************************************************************************)

BusinessHeader ==
    [ msgVersion : Sample(1),
      sourceId   : Sample(1),
      streamId   : Sample(2),
      sequence0  : Sample(1),
      sequence1  : Sample(4) ]

EncodeBusinessHeader(message) ==
    message.msgVersion
        \o message.sourceId
        \o message.streamId
        \o message.sequence0
        \o message.sequence1

DecodeBusinessHeader(bytes) ==
    LET msgVersion == ReadBytes(bytes, 1) IN IF ~msgVersion.ok THEN Fail ELSE
    LET sourceId == ReadBytes(msgVersion.rest, 1) IN IF ~sourceId.ok THEN Fail ELSE
    LET streamId == ReadBytes(sourceId.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET sequence0 == ReadBytes(streamId.rest, 1) IN IF ~sequence0.ok THEN Fail ELSE
    LET sequence1 == ReadBytes(sequence0.rest, 4) IN IF ~sequence1.ok THEN Fail ELSE
    Ok([ msgVersion |-> msgVersion.value,
         sourceId   |-> sourceId.value,
         streamId   |-> streamId.value,
         sequence0  |-> sequence0.value,
         sequence1  |-> sequence1.value ], sequence1.rest)

ZeroBusinessHeader ==
    [ msgVersion |-> [i \in 1 .. 1 |-> 0],
      sourceId   |-> [i \in 1 .. 1 |-> 0],
      streamId   |-> [i \in 1 .. 2 |-> 0],
      sequence0  |-> [i \in 1 .. 1 |-> 0],
      sequence1  |-> [i \in 1 .. 4 |-> 0] ]

(* Business Header at zero, then each field in turn at the values it is checked at *)
CheckedBusinessHeader ==
    { ZeroBusinessHeader }
        \cup { [ZeroBusinessHeader EXCEPT !.msgVersion = one] : one \in Sample(1) }
        \cup { [ZeroBusinessHeader EXCEPT !.sourceId = one] : one \in Sample(1) }
        \cup { [ZeroBusinessHeader EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroBusinessHeader EXCEPT !.sequence0 = one] : one \in Sample(1) }
        \cup { [ZeroBusinessHeader EXCEPT !.sequence1 = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Status Message: 53 bytes                                         *)
(***************************************************************************)

SymbolStatusMessage ==
    [ symbol        : Sample(12),
      stockGroup    : Sample(1),
      listingMarket : Sample(1),
      productType   : Sample(1),
      cusip         : Sample(12),
      boardLot      : Sample(2),
      currency      : Sample(1),
      faceValue     : Sample(8),
      lastSale      : Sample(8),
      minPoQty      : Sample(4),
      stockState    : Sample(2),
      testSymbol    : Sample(1) ]

EncodeSymbolStatusMessage(message) ==
    message.symbol
        \o message.stockGroup
        \o message.listingMarket
        \o message.productType
        \o message.cusip
        \o message.boardLot
        \o message.currency
        \o message.faceValue
        \o message.lastSale
        \o message.minPoQty
        \o message.stockState
        \o message.testSymbol

DecodeSymbolStatusMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET stockGroup == ReadBytes(symbol.rest, 1) IN IF ~stockGroup.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(stockGroup.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    LET productType == ReadBytes(listingMarket.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET cusip == ReadBytes(productType.rest, 12) IN IF ~cusip.ok THEN Fail ELSE
    LET boardLot == ReadBytes(cusip.rest, 2) IN IF ~boardLot.ok THEN Fail ELSE
    LET currency == ReadBytes(boardLot.rest, 1) IN IF ~currency.ok THEN Fail ELSE
    LET faceValue == ReadBytes(currency.rest, 8) IN IF ~faceValue.ok THEN Fail ELSE
    LET lastSale == ReadBytes(faceValue.rest, 8) IN IF ~lastSale.ok THEN Fail ELSE
    LET minPoQty == ReadBytes(lastSale.rest, 4) IN IF ~minPoQty.ok THEN Fail ELSE
    LET stockState == ReadBytes(minPoQty.rest, 2) IN IF ~stockState.ok THEN Fail ELSE
    LET testSymbol == ReadBytes(stockState.rest, 1) IN IF ~testSymbol.ok THEN Fail ELSE
    Ok([ symbol        |-> symbol.value,
         stockGroup    |-> stockGroup.value,
         listingMarket |-> listingMarket.value,
         productType   |-> productType.value,
         cusip         |-> cusip.value,
         boardLot      |-> boardLot.value,
         currency      |-> currency.value,
         faceValue     |-> faceValue.value,
         lastSale      |-> lastSale.value,
         minPoQty      |-> minPoQty.value,
         stockState    |-> stockState.value,
         testSymbol    |-> testSymbol.value ], testSymbol.rest)

ZeroSymbolStatusMessage ==
    [ symbol        |-> [i \in 1 .. 12 |-> 0],
      stockGroup    |-> [i \in 1 .. 1 |-> 0],
      listingMarket |-> [i \in 1 .. 1 |-> 0],
      productType   |-> [i \in 1 .. 1 |-> 0],
      cusip         |-> [i \in 1 .. 12 |-> 0],
      boardLot      |-> [i \in 1 .. 2 |-> 0],
      currency      |-> [i \in 1 .. 1 |-> 0],
      faceValue     |-> [i \in 1 .. 8 |-> 0],
      lastSale      |-> [i \in 1 .. 8 |-> 0],
      minPoQty      |-> [i \in 1 .. 4 |-> 0],
      stockState    |-> [i \in 1 .. 2 |-> 0],
      testSymbol    |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStatusMessage ==
    { ZeroSymbolStatusMessage }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.stockGroup = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.cusip = one] : one \in Sample(12) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.boardLot = one] : one \in Sample(2) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.currency = one] : one \in Sample(1) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.faceValue = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.lastSale = one] : one \in Sample(8) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.minPoQty = one] : one \in Sample(4) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.stockState = one] : one \in Sample(2) }
        \cup { [ZeroSymbolStatusMessage EXCEPT !.testSymbol = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 57 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ symbol                 : Sample(12),
      price                  : Sample(8),
      volume                 : Sample(4),
      buyBrokerNumber        : Sample(2),
      sellBrokerNumber       : Sample(2),
      bypass                 : Sample(1),
      tradeTimeStamp         : Sample(4),
      settlementTerms        : Sample(1),
      crossType              : Sample(1),
      lastSale               : Sample(8),
      openingTrade           : Sample(1),
      isDark                 : Sample(1),
      tradeNumber            : Sample(4),
      tradingSystemTimeStamp : Sample(8) ]

EncodeTradeMessage(message) ==
    message.symbol
        \o message.price
        \o message.volume
        \o message.buyBrokerNumber
        \o message.sellBrokerNumber
        \o message.bypass
        \o message.tradeTimeStamp
        \o message.settlementTerms
        \o message.crossType
        \o message.lastSale
        \o message.openingTrade
        \o message.isDark
        \o message.tradeNumber
        \o message.tradingSystemTimeStamp

DecodeTradeMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET buyBrokerNumber == ReadBytes(volume.rest, 2) IN IF ~buyBrokerNumber.ok THEN Fail ELSE
    LET sellBrokerNumber == ReadBytes(buyBrokerNumber.rest, 2) IN IF ~sellBrokerNumber.ok THEN Fail ELSE
    LET bypass == ReadBytes(sellBrokerNumber.rest, 1) IN IF ~bypass.ok THEN Fail ELSE
    LET tradeTimeStamp == ReadBytes(bypass.rest, 4) IN IF ~tradeTimeStamp.ok THEN Fail ELSE
    LET settlementTerms == ReadBytes(tradeTimeStamp.rest, 1) IN IF ~settlementTerms.ok THEN Fail ELSE
    LET crossType == ReadBytes(settlementTerms.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET lastSale == ReadBytes(crossType.rest, 8) IN IF ~lastSale.ok THEN Fail ELSE
    LET openingTrade == ReadBytes(lastSale.rest, 1) IN IF ~openingTrade.ok THEN Fail ELSE
    LET isDark == ReadBytes(openingTrade.rest, 1) IN IF ~isDark.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(isDark.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(tradeNumber.rest, 8) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         price                  |-> price.value,
         volume                 |-> volume.value,
         buyBrokerNumber        |-> buyBrokerNumber.value,
         sellBrokerNumber       |-> sellBrokerNumber.value,
         bypass                 |-> bypass.value,
         tradeTimeStamp         |-> tradeTimeStamp.value,
         settlementTerms        |-> settlementTerms.value,
         crossType              |-> crossType.value,
         lastSale               |-> lastSale.value,
         openingTrade           |-> openingTrade.value,
         isDark                 |-> isDark.value,
         tradeNumber            |-> tradeNumber.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value ], tradingSystemTimeStamp.rest)

ZeroTradeMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      volume                 |-> [i \in 1 .. 4 |-> 0],
      buyBrokerNumber        |-> [i \in 1 .. 2 |-> 0],
      sellBrokerNumber       |-> [i \in 1 .. 2 |-> 0],
      bypass                 |-> [i \in 1 .. 1 |-> 0],
      tradeTimeStamp         |-> [i \in 1 .. 4 |-> 0],
      settlementTerms        |-> [i \in 1 .. 1 |-> 0],
      crossType              |-> [i \in 1 .. 1 |-> 0],
      lastSale               |-> [i \in 1 .. 8 |-> 0],
      openingTrade           |-> [i \in 1 .. 1 |-> 0],
      isDark                 |-> [i \in 1 .. 1 |-> 0],
      tradeNumber            |-> [i \in 1 .. 4 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.buyBrokerNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.sellBrokerNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeTimeStamp = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.settlementTerms = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.lastSale = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.openingTrade = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.isDark = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Cancelled Message: 52 bytes                                       *)
(***************************************************************************)

TradeCancelledMessage ==
    [ symbol                 : Sample(12),
      volume                 : Sample(4),
      price                  : Sample(8),
      buyBrokerNumber        : Sample(2),
      sellBrokerNumber       : Sample(2),
      tradeTimeStamp         : Sample(4),
      lastSale               : Sample(8),
      tradeNumber            : Sample(4),
      tradingSystemTimeStamp : Sample(8) ]

EncodeTradeCancelledMessage(message) ==
    message.symbol
        \o message.volume
        \o message.price
        \o message.buyBrokerNumber
        \o message.sellBrokerNumber
        \o message.tradeTimeStamp
        \o message.lastSale
        \o message.tradeNumber
        \o message.tradingSystemTimeStamp

DecodeTradeCancelledMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET buyBrokerNumber == ReadBytes(price.rest, 2) IN IF ~buyBrokerNumber.ok THEN Fail ELSE
    LET sellBrokerNumber == ReadBytes(buyBrokerNumber.rest, 2) IN IF ~sellBrokerNumber.ok THEN Fail ELSE
    LET tradeTimeStamp == ReadBytes(sellBrokerNumber.rest, 4) IN IF ~tradeTimeStamp.ok THEN Fail ELSE
    LET lastSale == ReadBytes(tradeTimeStamp.rest, 8) IN IF ~lastSale.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(lastSale.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(tradeNumber.rest, 8) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         volume                 |-> volume.value,
         price                  |-> price.value,
         buyBrokerNumber        |-> buyBrokerNumber.value,
         sellBrokerNumber       |-> sellBrokerNumber.value,
         tradeTimeStamp         |-> tradeTimeStamp.value,
         lastSale               |-> lastSale.value,
         tradeNumber            |-> tradeNumber.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value ], tradingSystemTimeStamp.rest)

ZeroTradeCancelledMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      volume                 |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      buyBrokerNumber        |-> [i \in 1 .. 2 |-> 0],
      sellBrokerNumber       |-> [i \in 1 .. 2 |-> 0],
      tradeTimeStamp         |-> [i \in 1 .. 4 |-> 0],
      lastSale               |-> [i \in 1 .. 8 |-> 0],
      tradeNumber            |-> [i \in 1 .. 4 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelledMessage ==
    { ZeroTradeCancelledMessage }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.buyBrokerNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.sellBrokerNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.tradeTimeStamp = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.lastSale = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelledMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Stock Status Message: 66 bytes                                          *)
(***************************************************************************)

StockStatusMessage ==
    [ symbol                 : Sample(12),
      comment                : Sample(40),
      stockState             : Sample(2),
      tradingSystemTimeStamp : Sample(8),
      resumeTradeTime        : Sample(4) ]

EncodeStockStatusMessage(message) ==
    message.symbol
        \o message.comment
        \o message.stockState
        \o message.tradingSystemTimeStamp
        \o message.resumeTradeTime

DecodeStockStatusMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET comment == ReadBytes(symbol.rest, 40) IN IF ~comment.ok THEN Fail ELSE
    LET stockState == ReadBytes(comment.rest, 2) IN IF ~stockState.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(stockState.rest, 8) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    LET resumeTradeTime == ReadBytes(tradingSystemTimeStamp.rest, 4) IN IF ~resumeTradeTime.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         comment                |-> comment.value,
         stockState             |-> stockState.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value,
         resumeTradeTime        |-> resumeTradeTime.value ], resumeTradeTime.rest)

ZeroStockStatusMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      comment                |-> [i \in 1 .. 40 |-> 0],
      stockState             |-> [i \in 1 .. 2 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 8 |-> 0],
      resumeTradeTime        |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Status Message at zero, then each field in turn at the values it is checked at *)
CheckedStockStatusMessage ==
    { ZeroStockStatusMessage }
        \cup { [ZeroStockStatusMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroStockStatusMessage EXCEPT !.comment = one] : one \in Sample(40) }
        \cup { [ZeroStockStatusMessage EXCEPT !.stockState = one] : one \in Sample(2) }
        \cup { [ZeroStockStatusMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(8) }
        \cup { [ZeroStockStatusMessage EXCEPT !.resumeTradeTime = one] : one \in Sample(4) }

(***************************************************************************)
(* Equity Quote Message: 44 bytes                                          *)
(***************************************************************************)

EquityQuoteMessage ==
    [ symbol                 : Sample(12),
      bidPrice               : Sample(8),
      bidSize                : Sample(4),
      askPrice               : Sample(8),
      askSize                : Sample(4),
      tradingSystemTimeStamp : Sample(8) ]

EncodeEquityQuoteMessage(message) ==
    message.symbol
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.tradingSystemTimeStamp

DecodeEquityQuoteMessage(bytes) ==
    LET symbol == ReadBytes(bytes, 12) IN IF ~symbol.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(symbol.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET tradingSystemTimeStamp == ReadBytes(askSize.rest, 8) IN IF ~tradingSystemTimeStamp.ok THEN Fail ELSE
    Ok([ symbol                 |-> symbol.value,
         bidPrice               |-> bidPrice.value,
         bidSize                |-> bidSize.value,
         askPrice               |-> askPrice.value,
         askSize                |-> askSize.value,
         tradingSystemTimeStamp |-> tradingSystemTimeStamp.value ], tradingSystemTimeStamp.rest)

ZeroEquityQuoteMessage ==
    [ symbol                 |-> [i \in 1 .. 12 |-> 0],
      bidPrice               |-> [i \in 1 .. 8 |-> 0],
      bidSize                |-> [i \in 1 .. 4 |-> 0],
      askPrice               |-> [i \in 1 .. 8 |-> 0],
      askSize                |-> [i \in 1 .. 4 |-> 0],
      tradingSystemTimeStamp |-> [i \in 1 .. 8 |-> 0] ]

(* Equity Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedEquityQuoteMessage ==
    { ZeroEquityQuoteMessage }
        \cup { [ZeroEquityQuoteMessage EXCEPT !.symbol = one] : one \in Sample(12) }
        \cup { [ZeroEquityQuoteMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquityQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroEquityQuoteMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquityQuoteMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroEquityQuoteMessage EXCEPT !.tradingSystemTimeStamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Business Message, selected by Msg Type                                  *)
(***************************************************************************)

SymbolStatusMessageCode == 74  \* "J"
TradeMessageCode == 115  \* "s"
TradeCancelledMessageCode == 116  \* "t"
StockStatusMessageCode == 118  \* "v"
EquityQuoteMessageCode == 119  \* "w"

BusinessMessage ==
    [ tag : {SymbolStatusMessageCode}, body : SymbolStatusMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeCancelledMessageCode}, body : TradeCancelledMessage ]
        \cup [ tag : {StockStatusMessageCode}, body : StockStatusMessage ]
        \cup [ tag : {EquityQuoteMessageCode}, body : EquityQuoteMessage ]

EncodeBusinessMessage(message) ==
    CASE message.tag = SymbolStatusMessageCode -> EncodeSymbolStatusMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeCancelledMessageCode -> EncodeTradeCancelledMessage(message.body)
      [] message.tag = StockStatusMessageCode -> EncodeStockStatusMessage(message.body)
      [] message.tag = EquityQuoteMessageCode -> EncodeEquityQuoteMessage(message.body)

DecodeBusinessMessage(tag, bytes) ==
    LET read ==
            CASE tag = SymbolStatusMessageCode -> DecodeSymbolStatusMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeCancelledMessageCode -> DecodeTradeCancelledMessage(bytes)
              [] tag = StockStatusMessageCode -> DecodeStockStatusMessage(bytes)
              [] tag = EquityQuoteMessageCode -> DecodeEquityQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroBusinessMessage == [tag |-> SymbolStatusMessageCode, body |-> ZeroSymbolStatusMessage]

(* Each Business Message in turn, at the values the message it names is checked at *)
CheckedBusinessMessage ==
    { [tag |-> SymbolStatusMessageCode, body |-> one] : one \in CheckedSymbolStatusMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeCancelledMessageCode, body |-> one] : one \in CheckedTradeCancelledMessage }
        \cup { [tag |-> StockStatusMessageCode, body |-> one] : one \in CheckedStockStatusMessage }
        \cup { [tag |-> EquityQuoteMessageCode, body |-> one] : one \in CheckedEquityQuoteMessage }

(***************************************************************************)
(* Body, framed by Msg Length                                              *)
(***************************************************************************)

Body ==
    [ businessHeader  : BusinessHeader,
      businessMessage : BusinessMessage ]

EncodeBodyBody(message) ==
    EncodeUIntBE(message.businessMessage.tag, 1)
        \o EncodeBusinessHeader(message.businessHeader)
        \o EncodeBusinessMessage(message.businessMessage)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeBody(message) ==
    LET body == EncodeBodyBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeBodyBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET businessHeader == DecodeBusinessHeader(msgType.rest) IN IF ~businessHeader.ok THEN Fail ELSE
    LET businessMessage == DecodeBusinessMessage(msgType.value, businessHeader.rest) IN IF ~businessMessage.ok THEN Fail ELSE
    Ok([ businessHeader  |-> businessHeader.value,
         businessMessage |-> businessMessage.value ], businessMessage.rest)

DecodeBody(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeBodyBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroBody ==
    [ businessHeader  |-> ZeroBusinessHeader,
      businessMessage |-> ZeroBusinessMessage ]

(* Body at zero, then each field in turn at the values it is checked at *)
CheckedBody ==
    { ZeroBody }
        \cup { [ZeroBody EXCEPT !.businessHeader = one] : one \in CheckedBusinessHeader }
        \cup { [ZeroBody EXCEPT !.businessMessage = one] : one \in CheckedBusinessMessage }

(* A run of Body, written one after another *)
RECURSIVE EncodeBodyList(_)
EncodeBodyList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBody(Head(messages)) \o EncodeBodyList(Tail(messages))

(* As many Body as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadBodyAll(_)
ReadBodyAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeBody(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBodyAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Body of each kind, for the lists that carry them *)
OneBody ==
    { [ZeroBody EXCEPT !.businessMessage = [tag |-> SymbolStatusMessageCode, body |-> ZeroSymbolStatusMessage]],
      [ZeroBody EXCEPT !.businessMessage = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroBody EXCEPT !.businessMessage = [tag |-> TradeCancelledMessageCode, body |-> ZeroTradeCancelledMessage]],
      [ZeroBody EXCEPT !.businessMessage = [tag |-> StockStatusMessageCode, body |-> ZeroStockStatusMessage]],
      [ZeroBody EXCEPT !.businessMessage = [tag |-> EquityQuoteMessageCode, body |-> ZeroEquityQuoteMessage]] }

(***************************************************************************)
(* Ack, framed by Msg Length                                               *)
(***************************************************************************)

Ack ==
    [ adminId : Sample(1),
      body    : SampleLists(OneBody) ]

EncodeAckBody(message) ==
    EncodeUIntBE(52, 1)
        \o message.adminId
        \o EncodeBodyList(message.body)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeAck(message) ==
    LET body == EncodeAckBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeAckBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    LET body == ReadBodyAll(adminId.rest) IN IF ~body.ok THEN Fail ELSE
    Ok([ adminId |-> adminId.value,
         body    |-> body.value ], body.rest)

DecodeAck(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeAckBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroAck ==
    [ adminId |-> [i \in 1 .. 1 |-> 0],
      body    |-> << >> ]

(* Ack at zero, then each field in turn at the values it is checked at *)
CheckedAck ==
    { ZeroAck }
        \cup { [ZeroAck EXCEPT !.adminId = one] : one \in Sample(1) }
        \cup { [ZeroAck EXCEPT !.body = one] : one \in SampleLists(OneBody) }

(***************************************************************************)
(* Sequence Jump Record: 12 bytes                                          *)
(***************************************************************************)

SequenceJumpRecord ==
    [ sourceId         : Sample(1),
      streamId         : Sample(2),
      sequence0        : Sample(1),
      sequence1Current : Sample(4),
      sequence1New     : Sample(4) ]

EncodeSequenceJumpRecord(message) ==
    message.sourceId
        \o message.streamId
        \o message.sequence0
        \o message.sequence1Current
        \o message.sequence1New

DecodeSequenceJumpRecord(bytes) ==
    LET sourceId == ReadBytes(bytes, 1) IN IF ~sourceId.ok THEN Fail ELSE
    LET streamId == ReadBytes(sourceId.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET sequence0 == ReadBytes(streamId.rest, 1) IN IF ~sequence0.ok THEN Fail ELSE
    LET sequence1Current == ReadBytes(sequence0.rest, 4) IN IF ~sequence1Current.ok THEN Fail ELSE
    LET sequence1New == ReadBytes(sequence1Current.rest, 4) IN IF ~sequence1New.ok THEN Fail ELSE
    Ok([ sourceId         |-> sourceId.value,
         streamId         |-> streamId.value,
         sequence0        |-> sequence0.value,
         sequence1Current |-> sequence1Current.value,
         sequence1New     |-> sequence1New.value ], sequence1New.rest)

ZeroSequenceJumpRecord ==
    [ sourceId         |-> [i \in 1 .. 1 |-> 0],
      streamId         |-> [i \in 1 .. 2 |-> 0],
      sequence0        |-> [i \in 1 .. 1 |-> 0],
      sequence1Current |-> [i \in 1 .. 4 |-> 0],
      sequence1New     |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Jump Record at zero, then each field in turn at the values it is checked at *)
CheckedSequenceJumpRecord ==
    { ZeroSequenceJumpRecord }
        \cup { [ZeroSequenceJumpRecord EXCEPT !.sourceId = one] : one \in Sample(1) }
        \cup { [ZeroSequenceJumpRecord EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroSequenceJumpRecord EXCEPT !.sequence0 = one] : one \in Sample(1) }
        \cup { [ZeroSequenceJumpRecord EXCEPT !.sequence1Current = one] : one \in Sample(4) }
        \cup { [ZeroSequenceJumpRecord EXCEPT !.sequence1New = one] : one \in Sample(4) }

(* A run of Sequence Jump Record, written one after another *)
RECURSIVE EncodeSequenceJumpRecordList(_)
EncodeSequenceJumpRecordList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSequenceJumpRecord(Head(messages)) \o EncodeSequenceJumpRecordList(Tail(messages))

(* As many Sequence Jump Record as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSequenceJumpRecordAll(_)
ReadSequenceJumpRecordAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSequenceJumpRecord(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSequenceJumpRecordAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sequence Jump Record of each kind, for the lists that carry them *)
OneSequenceJumpRecord == { ZeroSequenceJumpRecord }

(***************************************************************************)
(* Sequence Jump, framed by Msg Length                                     *)
(***************************************************************************)

SequenceJump ==
    [ adminId            : Sample(1),
      reasonCode         : Sample(1),
      sequenceJumpRecord : SampleLists(OneSequenceJumpRecord) ]

EncodeSequenceJumpBody(message) ==
    EncodeUIntBE(54, 1)
        \o message.adminId
        \o message.reasonCode
        \o EncodeSequenceJumpRecordList(message.sequenceJumpRecord)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeSequenceJump(message) ==
    LET body == EncodeSequenceJumpBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeSequenceJumpBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(adminId.rest, 1) IN IF ~reasonCode.ok THEN Fail ELSE
    LET sequenceJumpRecord == ReadSequenceJumpRecordAll(reasonCode.rest) IN IF ~sequenceJumpRecord.ok THEN Fail ELSE
    Ok([ adminId            |-> adminId.value,
         reasonCode         |-> reasonCode.value,
         sequenceJumpRecord |-> sequenceJumpRecord.value ], sequenceJumpRecord.rest)

DecodeSequenceJump(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSequenceJumpBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSequenceJump ==
    [ adminId            |-> [i \in 1 .. 1 |-> 0],
      reasonCode         |-> [i \in 1 .. 1 |-> 0],
      sequenceJumpRecord |-> << >> ]

(* Sequence Jump at zero, then each field in turn at the values it is checked at *)
CheckedSequenceJump ==
    { ZeroSequenceJump }
        \cup { [ZeroSequenceJump EXCEPT !.adminId = one] : one \in Sample(1) }
        \cup { [ZeroSequenceJump EXCEPT !.reasonCode = one] : one \in Sample(1) }
        \cup { [ZeroSequenceJump EXCEPT !.sequenceJumpRecord = one] : one \in SampleLists(OneSequenceJumpRecord) }

(***************************************************************************)
(* Rejected Business Header: 12 bytes                                      *)
(***************************************************************************)

RejectedBusinessHeader ==
    [ rejectedMsgLength : Sample(2),
      msgType           : Sample(1),
      msgVersion        : Sample(1),
      sourceId          : Sample(1),
      streamId          : Sample(2),
      sequence0         : Sample(1),
      rejectedSequence1 : Sample(4) ]

EncodeRejectedBusinessHeader(message) ==
    message.rejectedMsgLength
        \o message.msgType
        \o message.msgVersion
        \o message.sourceId
        \o message.streamId
        \o message.sequence0
        \o message.rejectedSequence1

DecodeRejectedBusinessHeader(bytes) ==
    LET rejectedMsgLength == ReadBytes(bytes, 2) IN IF ~rejectedMsgLength.ok THEN Fail ELSE
    LET msgType == ReadBytes(rejectedMsgLength.rest, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET msgVersion == ReadBytes(msgType.rest, 1) IN IF ~msgVersion.ok THEN Fail ELSE
    LET sourceId == ReadBytes(msgVersion.rest, 1) IN IF ~sourceId.ok THEN Fail ELSE
    LET streamId == ReadBytes(sourceId.rest, 2) IN IF ~streamId.ok THEN Fail ELSE
    LET sequence0 == ReadBytes(streamId.rest, 1) IN IF ~sequence0.ok THEN Fail ELSE
    LET rejectedSequence1 == ReadBytes(sequence0.rest, 4) IN IF ~rejectedSequence1.ok THEN Fail ELSE
    Ok([ rejectedMsgLength |-> rejectedMsgLength.value,
         msgType           |-> msgType.value,
         msgVersion        |-> msgVersion.value,
         sourceId          |-> sourceId.value,
         streamId          |-> streamId.value,
         sequence0         |-> sequence0.value,
         rejectedSequence1 |-> rejectedSequence1.value ], rejectedSequence1.rest)

ZeroRejectedBusinessHeader ==
    [ rejectedMsgLength |-> [i \in 1 .. 2 |-> 0],
      msgType           |-> [i \in 1 .. 1 |-> 0],
      msgVersion        |-> [i \in 1 .. 1 |-> 0],
      sourceId          |-> [i \in 1 .. 1 |-> 0],
      streamId          |-> [i \in 1 .. 2 |-> 0],
      sequence0         |-> [i \in 1 .. 1 |-> 0],
      rejectedSequence1 |-> [i \in 1 .. 4 |-> 0] ]

(* Rejected Business Header at zero, then each field in turn at the values it is checked at *)
CheckedRejectedBusinessHeader ==
    { ZeroRejectedBusinessHeader }
        \cup { [ZeroRejectedBusinessHeader EXCEPT !.rejectedMsgLength = one] : one \in Sample(2) }
        \cup { [ZeroRejectedBusinessHeader EXCEPT !.msgType = one] : one \in Sample(1) }
        \cup { [ZeroRejectedBusinessHeader EXCEPT !.msgVersion = one] : one \in Sample(1) }
        \cup { [ZeroRejectedBusinessHeader EXCEPT !.sourceId = one] : one \in Sample(1) }
        \cup { [ZeroRejectedBusinessHeader EXCEPT !.streamId = one] : one \in Sample(2) }
        \cup { [ZeroRejectedBusinessHeader EXCEPT !.sequence0 = one] : one \in Sample(1) }
        \cup { [ZeroRejectedBusinessHeader EXCEPT !.rejectedSequence1 = one] : one \in Sample(4) }

(* A run of Rejected Business Header, written one after another *)
RECURSIVE EncodeRejectedBusinessHeaderList(_)
EncodeRejectedBusinessHeaderList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRejectedBusinessHeader(Head(messages)) \o EncodeRejectedBusinessHeaderList(Tail(messages))

(* As many Rejected Business Header as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadRejectedBusinessHeaderAll(_)
ReadRejectedBusinessHeaderAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeRejectedBusinessHeader(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRejectedBusinessHeaderAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Rejected Business Header of each kind, for the lists that carry them *)
OneRejectedBusinessHeader == { ZeroRejectedBusinessHeader }

(***************************************************************************)
(* Reject, framed by Msg Length                                            *)
(***************************************************************************)

Reject ==
    [ adminId                : Sample(1),
      rejectCode             : Sample(1),
      rejectSubcode          : Sample(1),
      rejectMessage          : Sample(30),
      rejectedBusinessHeader : SampleLists(OneRejectedBusinessHeader) ]

EncodeRejectBody(message) ==
    EncodeUIntBE(57, 1)
        \o message.adminId
        \o message.rejectCode
        \o message.rejectSubcode
        \o message.rejectMessage
        \o EncodeRejectedBusinessHeaderList(message.rejectedBusinessHeader)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeReject(message) ==
    LET body == EncodeRejectBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeRejectBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET adminId == ReadBytes(msgType.rest, 1) IN IF ~adminId.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(adminId.rest, 1) IN IF ~rejectCode.ok THEN Fail ELSE
    LET rejectSubcode == ReadBytes(rejectCode.rest, 1) IN IF ~rejectSubcode.ok THEN Fail ELSE
    LET rejectMessage == ReadBytes(rejectSubcode.rest, 30) IN IF ~rejectMessage.ok THEN Fail ELSE
    LET rejectedBusinessHeader == ReadRejectedBusinessHeaderAll(rejectMessage.rest) IN IF ~rejectedBusinessHeader.ok THEN Fail ELSE
    Ok([ adminId                |-> adminId.value,
         rejectCode             |-> rejectCode.value,
         rejectSubcode          |-> rejectSubcode.value,
         rejectMessage          |-> rejectMessage.value,
         rejectedBusinessHeader |-> rejectedBusinessHeader.value ], rejectedBusinessHeader.rest)

DecodeReject(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeRejectBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroReject ==
    [ adminId                |-> [i \in 1 .. 1 |-> 0],
      rejectCode             |-> [i \in 1 .. 1 |-> 0],
      rejectSubcode          |-> [i \in 1 .. 1 |-> 0],
      rejectMessage          |-> [i \in 1 .. 30 |-> 0],
      rejectedBusinessHeader |-> << >> ]

(* Reject at zero, then each field in turn at the values it is checked at *)
CheckedReject ==
    { ZeroReject }
        \cup { [ZeroReject EXCEPT !.adminId = one] : one \in Sample(1) }
        \cup { [ZeroReject EXCEPT !.rejectCode = one] : one \in Sample(1) }
        \cup { [ZeroReject EXCEPT !.rejectSubcode = one] : one \in Sample(1) }
        \cup { [ZeroReject EXCEPT !.rejectMessage = one] : one \in Sample(30) }
        \cup { [ZeroReject EXCEPT !.rejectedBusinessHeader = one] : one \in SampleLists(OneRejectedBusinessHeader) }

(***************************************************************************)
(* Server Body, selected by Msg Type                                       *)
(***************************************************************************)

HeartbeatBodyCode == 48  \* "0"
LoginResponseCode == 50  \* "2"
AckCode == 52  \* "4"
SequenceJumpCode == 54  \* "6"
RejectCode == 57  \* "9"

ServerBody ==
    [ tag : {HeartbeatBodyCode}, body : HeartbeatBody ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {AckCode}, body : Ack ]
        \cup [ tag : {SequenceJumpCode}, body : SequenceJump ]
        \cup [ tag : {RejectCode}, body : Reject ]

EncodeServerBody(message) ==
    CASE message.tag = HeartbeatBodyCode -> EncodeHeartbeatBody(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = AckCode -> EncodeAck(message.body)
      [] message.tag = SequenceJumpCode -> EncodeSequenceJump(message.body)
      [] message.tag = RejectCode -> EncodeReject(message.body)

DecodeServerBody(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatBodyCode -> DecodeHeartbeatBody(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = AckCode -> DecodeAck(bytes)
              [] tag = SequenceJumpCode -> DecodeSequenceJump(bytes)
              [] tag = RejectCode -> DecodeReject(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerBody == [tag |-> HeartbeatBodyCode, body |-> ZeroHeartbeatBody]

(* Each Server Body in turn, at the values the message it names is checked at *)
CheckedServerBody ==
    { [tag |-> HeartbeatBodyCode, body |-> one] : one \in CheckedHeartbeatBody }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> AckCode, body |-> one] : one \in CheckedAck }
        \cup { [tag |-> SequenceJumpCode, body |-> one] : one \in CheckedSequenceJump }
        \cup { [tag |-> RejectCode, body |-> one] : one \in CheckedReject }

(***************************************************************************)
(* Server Frame                                                            *)
(***************************************************************************)

ServerFrameTail ==
    [ serverBody : ServerBody ]

EncodeServerFrameTail(message) ==
    EncodeServerBody(message.serverBody)

DecodeServerFrameTail(bytes) ==
    IF Len(bytes) < 3 THEN Fail ELSE
    LET serverBody == DecodeServerBody(DecodeUIntBE(SubSeq(bytes, 3, 3)), bytes) IN IF ~serverBody.ok THEN Fail ELSE
    Ok([ serverBody |-> serverBody.value ], serverBody.rest)

ZeroServerFrameTail ==
    [ serverBody |-> ZeroServerBody ]

(* Server Frame at zero, then each field in turn at the values it is checked at *)
CheckedServerFrameTail ==
    { ZeroServerFrameTail }
        \cup { [ZeroServerFrameTail EXCEPT !.serverBody = one] : one \in CheckedServerBody }

(* Server Frame runs on only when bytes remain, so it is there or it is not *)
WithoutServerFrameTail == [there |-> FALSE, value |-> ZeroServerFrameTail]

MaybeServerFrameTail ==
    { WithoutServerFrameTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedServerFrameTail }

ReadServerFrameTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutServerFrameTail, << >>)
    ELSE LET one == DecodeServerFrameTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Server Frame, framed by Message Length                                  *)
(***************************************************************************)

ServerFrame ==
    [ startOfFrame       : Sample(1),
      protocolName       : Sample(1),
      protocolVersion    : Sample(1),
      sessionId          : Sample(4),
      ackRequiredPossDup : Sample(1),
      numBody            : 0 .. 255,
      serverFrameTail    : MaybeServerFrameTail ]

EncodeServerFrameBody(message) ==
    message.sessionId
        \o message.ackRequiredPossDup
        \o EncodeUIntBE(message.numBody, 1)
        \o IF message.serverFrameTail.there THEN EncodeServerFrameTail(message.serverFrameTail.value) ELSE << >>

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeServerFrame(message) ==
    LET body == EncodeServerFrameBody(message)
    IN  message.startOfFrame \o message.protocolName \o message.protocolVersion \o EncodeUIntLE(Len(body), 2) \o body

DecodeServerFrame(bytes) ==
    LET startOfFrame == ReadBytes(bytes, 1) IN IF ~startOfFrame.ok THEN Fail ELSE
    LET protocolName == ReadBytes(startOfFrame.rest, 1) IN IF ~protocolName.ok THEN Fail ELSE
    LET protocolVersion == ReadBytes(protocolName.rest, 1) IN IF ~protocolVersion.ok THEN Fail ELSE
    LET length == ReadUIntLE(protocolVersion.rest, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
    IN
    LET sessionId == ReadBytes(framed, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET ackRequiredPossDup == ReadBytes(sessionId.rest, 1) IN IF ~ackRequiredPossDup.ok THEN Fail ELSE
    LET numBody == ReadUIntBE(ackRequiredPossDup.rest, 1) IN IF ~numBody.ok THEN Fail ELSE
    LET serverFrameTail == ReadServerFrameTailMaybe(numBody.rest) IN IF ~serverFrameTail.ok THEN Fail ELSE
    IF serverFrameTail.rest # << >> THEN Fail ELSE
    Ok([ startOfFrame       |-> startOfFrame.value,
         protocolName       |-> protocolName.value,
         protocolVersion    |-> protocolVersion.value,
         sessionId          |-> sessionId.value,
         ackRequiredPossDup |-> ackRequiredPossDup.value,
         numBody            |-> numBody.value,
         serverFrameTail    |-> serverFrameTail.value ], beyond)

ZeroServerFrame ==
    [ startOfFrame       |-> [i \in 1 .. 1 |-> 0],
      protocolName       |-> [i \in 1 .. 1 |-> 0],
      protocolVersion    |-> [i \in 1 .. 1 |-> 0],
      sessionId          |-> [i \in 1 .. 4 |-> 0],
      ackRequiredPossDup |-> [i \in 1 .. 1 |-> 0],
      numBody            |-> 0,
      serverFrameTail    |-> WithoutServerFrameTail ]

(* Server Frame at zero, then each field in turn at the values it is checked at *)
CheckedServerFrame ==
    { ZeroServerFrame }
        \cup { [ZeroServerFrame EXCEPT !.startOfFrame = one] : one \in Sample(1) }
        \cup { [ZeroServerFrame EXCEPT !.protocolName = one] : one \in Sample(1) }
        \cup { [ZeroServerFrame EXCEPT !.protocolVersion = one] : one \in Sample(1) }
        \cup { [ZeroServerFrame EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroServerFrame EXCEPT !.ackRequiredPossDup = one] : one \in Sample(1) }
        \cup { [ZeroServerFrame EXCEPT !.numBody = one] : one \in {0, 1, 255} }
        \cup { [ZeroServerFrame EXCEPT !.serverFrameTail = one] : one \in MaybeServerFrameTail }

(* A run of Server Frame, written one after another *)
RECURSIVE EncodeServerFrameList(_)
EncodeServerFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerFrame(Head(messages)) \o EncodeServerFrameList(Tail(messages))

(* As many Server Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerFrameAll(_)
ReadServerFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Frame of each kind, for the lists that carry them *)
OneServerFrame == { ZeroServerFrame }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverFrame : SampleLists(OneServerFrame) ]

EncodeServerPacket(message) ==
    EncodeServerFrameList(message.serverFrame)

DecodeServerPacket(bytes) ==
    LET serverFrame == ReadServerFrameAll(bytes) IN IF ~serverFrame.ok THEN Fail ELSE
    Ok([ serverFrame |-> serverFrame.value ], serverFrame.rest)

ZeroServerPacket ==
    [ serverFrame |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverFrame = one] : one \in SampleLists(OneServerFrame) }

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

(* Every Admin Body decodes back to what was encoded, and leaves nothing over *)
RoundTripAdminBody ==
    \A message \in CheckedAdminBody :
        LET read == DecodeAdminBody(EncodeAdminBody(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Body decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatBody ==
    \A message \in CheckedHeartbeatBody :
        LET read == DecodeHeartbeatBody(EncodeHeartbeatBody(message))
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

(* Every Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessHeader ==
    \A message \in CheckedBusinessHeader :
        LET read == DecodeBusinessHeader(EncodeBusinessHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStatusMessage ==
    \A message \in CheckedSymbolStatusMessage :
        LET read == DecodeSymbolStatusMessage(EncodeSymbolStatusMessage(message))
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

(* Every Trade Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelledMessage ==
    \A message \in CheckedTradeCancelledMessage :
        LET read == DecodeTradeCancelledMessage(EncodeTradeCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockStatusMessage ==
    \A message \in CheckedStockStatusMessage :
        LET read == DecodeStockStatusMessage(EncodeStockStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equity Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquityQuoteMessage ==
    \A message \in CheckedEquityQuoteMessage :
        LET read == DecodeEquityQuoteMessage(EncodeEquityQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Body decodes back to what was encoded, and leaves nothing over *)
RoundTripBody ==
    \A message \in CheckedBody :
        LET read == DecodeBody(EncodeBody(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripAck ==
    \A message \in CheckedAck :
        LET read == DecodeAck(EncodeAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Jump Record decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceJumpRecord ==
    \A message \in CheckedSequenceJumpRecord :
        LET read == DecodeSequenceJumpRecord(EncodeSequenceJumpRecord(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Jump decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceJump ==
    \A message \in CheckedSequenceJump :
        LET read == DecodeSequenceJump(EncodeSequenceJump(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rejected Business Header decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectedBusinessHeader ==
    \A message \in CheckedRejectedBusinessHeader :
        LET read == DecodeRejectedBusinessHeader(EncodeRejectedBusinessHeader(message))
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

(* Every Server Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripServerFrameTail ==
    \A message \in CheckedServerFrameTail :
        LET read == DecodeServerFrameTail(EncodeServerFrameTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripServerFrame ==
    \A message \in CheckedServerFrame :
        LET read == DecodeServerFrame(EncodeServerFrame(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Business Message is selected by the Msg Type it is written under *)
SelectsBusinessMessage ==
    \A message \in CheckedBusinessMessage :
        LET sent == EncodeBusinessMessage(message)
            read == DecodeBusinessMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Body written out and then looked at is selected by the Msg Type it wrote *)
SelectsServerBody ==
    \A message \in CheckedServerBody :
        LET sent == EncodeServerBody(message)
            read == DecodeServerBody(DecodeUIntBE(SubSeq(sent, 3, 3)), sent)
        IN  Len(sent) >= 3 /\ read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesHeartbeatBody ==
    \A message \in CheckedHeartbeatBody :
        LET bytes == EncodeHeartbeatBody(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET bytes == EncodeLoginResponse(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesBody ==
    \A message \in CheckedBody :
        LET bytes == EncodeBody(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesAck ==
    \A message \in CheckedAck :
        LET bytes == EncodeAck(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesSequenceJump ==
    \A message \in CheckedSequenceJump :
        LET bytes == EncodeSequenceJump(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Msg Length is written from the bytes it frames *)
FramesReject ==
    \A message \in CheckedReject :
        LET bytes == EncodeReject(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

(* Message Length is written from the bytes it frames *)
FramesServerFrame ==
    \A message \in CheckedServerFrame :
        LET bytes == EncodeServerFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 4, 5)) = Len(bytes) - 5

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
