------------------- MODULE TxseEquities_Seed_v1_0_Server -------------------
(***************************************************************************)
(* Texas Stock Exchange Session Enabled Entry Daemon v1.0                  *)
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
(* Note: A field marked present by fields read before it is read only when *)
(* they say it is there, and the records checked hold it exactly where     *)
(* they do: one holding it anywhere else is no message the protocol sends. *)
(*                                                                         *)
(* Note: Listing Market and what follows it are read only when the message *)
(* runs on past what precedes them.                                        *)
(*                                                                         *)
(* Note: Liquidity Indicator and what follows it are read only when the    *)
(* message runs on past what precedes them.                                *)
(*                                                                         *)
(* Note: Tcp Sequenced Message fills what is left of the frame Message     *)
(* Length states, which is what it is read from.                           *)
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

(* A field there only when what was read before it says so: read when it is, and held *)
(* as a sequence of the one value it read, or of none when it is not there. *)
ReadWhen(holds, read, bytes) ==
    IF ~holds
    THEN Ok(<< >>, bytes)
    ELSE IF ~read.ok THEN Fail ELSE Ok(<<read.value>>, read.rest)

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
(* Debug Message                                                           *)
(***************************************************************************)

DebugMessage ==
    [ text : SampleBytes ]

EncodeDebugMessage(message) ==
    message.text

DecodeDebugMessage(bytes) ==
    LET text == Ok(bytes, << >>) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroDebugMessage ==
    [ text |-> << >> ]

(* Debug Message at zero, then each field in turn at the values it is checked at *)
CheckedDebugMessage ==
    { ZeroDebugMessage }
        \cup { [ZeroDebugMessage EXCEPT !.text = one] : one \in SampleBytes }

(***************************************************************************)
(* Logon Response Message: 30 bytes                                        *)
(***************************************************************************)

LogonResponseMessage ==
    [ session                    : Sample(8),
      nextSequenceNumber         : Sample(8),
      highestKnownSequenceNumber : Sample(8),
      logonResponseCode          : Sample(1),
      numberStreamIds            : Sample(1),
      instance                   : Sample(4) ]

EncodeLogonResponseMessage(message) ==
    message.session
        \o message.nextSequenceNumber
        \o message.highestKnownSequenceNumber
        \o message.logonResponseCode
        \o message.numberStreamIds
        \o message.instance

DecodeLogonResponseMessage(bytes) ==
    LET session == ReadBytes(bytes, 8) IN IF ~session.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(session.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    LET highestKnownSequenceNumber == ReadBytes(nextSequenceNumber.rest, 8) IN IF ~highestKnownSequenceNumber.ok THEN Fail ELSE
    LET logonResponseCode == ReadBytes(highestKnownSequenceNumber.rest, 1) IN IF ~logonResponseCode.ok THEN Fail ELSE
    LET numberStreamIds == ReadBytes(logonResponseCode.rest, 1) IN IF ~numberStreamIds.ok THEN Fail ELSE
    LET instance == ReadBytes(numberStreamIds.rest, 4) IN IF ~instance.ok THEN Fail ELSE
    Ok([ session                    |-> session.value,
         nextSequenceNumber         |-> nextSequenceNumber.value,
         highestKnownSequenceNumber |-> highestKnownSequenceNumber.value,
         logonResponseCode          |-> logonResponseCode.value,
         numberStreamIds            |-> numberStreamIds.value,
         instance                   |-> instance.value ], instance.rest)

ZeroLogonResponseMessage ==
    [ session                    |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber         |-> [i \in 1 .. 8 |-> 0],
      highestKnownSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      logonResponseCode          |-> [i \in 1 .. 1 |-> 0],
      numberStreamIds            |-> [i \in 1 .. 1 |-> 0],
      instance                   |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponseMessage ==
    { ZeroLogonResponseMessage }
        \cup { [ZeroLogonResponseMessage EXCEPT !.session = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.highestKnownSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.logonResponseCode = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.numberStreamIds = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.instance = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Session Status Message                                          *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ tradingSessionStatusPresenceBits          : 0 .. 255,
      transactTime                              : Sample(8),
      marketHoursState                          : Sample(1),
      sessionTradingState                       : Sample(1),
      tradingSessionStatusOperationalHaltReason : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradingSessionStatusRegulatoryHaltReason  : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradingSessionStatusMessage(message) ==
    EncodeUIntLE(message.tradingSessionStatusPresenceBits, 1)
        \o message.transactTime
        \o message.marketHoursState
        \o message.sessionTradingState
        \o (IF message.tradingSessionStatusOperationalHaltReason = << >> THEN << >> ELSE message.tradingSessionStatusOperationalHaltReason[1])
        \o (IF message.tradingSessionStatusRegulatoryHaltReason = << >> THEN << >> ELSE message.tradingSessionStatusRegulatoryHaltReason[1])

DecodeTradingSessionStatusMessage(bytes) ==
    LET tradingSessionStatusPresenceBits == ReadUIntLE(bytes, 1) IN IF ~tradingSessionStatusPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tradingSessionStatusPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketHoursState == ReadBytes(transactTime.rest, 1) IN IF ~marketHoursState.ok THEN Fail ELSE
    LET sessionTradingState == ReadBytes(marketHoursState.rest, 1) IN IF ~sessionTradingState.ok THEN Fail ELSE
    LET tradingSessionStatusOperationalHaltReason == ReadWhen(tradingSessionStatusPresenceBits.value % 2 = 1, ReadBytes(sessionTradingState.rest, 1), sessionTradingState.rest) IN IF ~tradingSessionStatusOperationalHaltReason.ok THEN Fail ELSE
    LET tradingSessionStatusRegulatoryHaltReason == ReadWhen((tradingSessionStatusPresenceBits.value \div 2) % 2 = 1, ReadBytes(tradingSessionStatusOperationalHaltReason.rest, 1), tradingSessionStatusOperationalHaltReason.rest) IN IF ~tradingSessionStatusRegulatoryHaltReason.ok THEN Fail ELSE
    Ok([ tradingSessionStatusPresenceBits          |-> tradingSessionStatusPresenceBits.value,
         transactTime                              |-> transactTime.value,
         marketHoursState                          |-> marketHoursState.value,
         sessionTradingState                       |-> sessionTradingState.value,
         tradingSessionStatusOperationalHaltReason |-> tradingSessionStatusOperationalHaltReason.value,
         tradingSessionStatusRegulatoryHaltReason  |-> tradingSessionStatusRegulatoryHaltReason.value ], tradingSessionStatusRegulatoryHaltReason.rest)

(* Trading Session Status Message with each field marked present by fields before it there exactly where they say *)
SettleTradingSessionStatusMessage(message) ==
    LET settled1 == [message EXCEPT !.tradingSessionStatusOperationalHaltReason = IF message.tradingSessionStatusPresenceBits % 2 = 1 THEN (IF message.tradingSessionStatusOperationalHaltReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.tradingSessionStatusOperationalHaltReason) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradingSessionStatusRegulatoryHaltReason = IF (settled1.tradingSessionStatusPresenceBits \div 2) % 2 = 1 THEN (IF settled1.tradingSessionStatusRegulatoryHaltReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.tradingSessionStatusRegulatoryHaltReason) ELSE << >>]
    IN  settled2

ZeroTradingSessionStatusMessage ==
    SettleTradingSessionStatusMessage([ tradingSessionStatusPresenceBits          |-> 0,
                                        transactTime                              |-> [i \in 1 .. 8 |-> 0],
                                        marketHoursState                          |-> [i \in 1 .. 1 |-> 0],
                                        sessionTradingState                       |-> [i \in 1 .. 1 |-> 0],
                                        tradingSessionStatusOperationalHaltReason |-> << >>,
                                        tradingSessionStatusRegulatoryHaltReason  |-> << >> ])

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionStatusPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.marketHoursState = one]) : one \in Sample(1) }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.sessionTradingState = one]) : one \in Sample(1) }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionStatusPresenceBits = 1, !.tradingSessionStatusOperationalHaltReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionStatusPresenceBits = 2, !.tradingSessionStatusRegulatoryHaltReason = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Define Symbol Message: 1 bytes                                          *)
(***************************************************************************)

DefineSymbolMessageTail ==
    [ listingMarket : Sample(1) ]

EncodeDefineSymbolMessageTail(message) ==
    message.listingMarket

DecodeDefineSymbolMessageTail(bytes) ==
    LET listingMarket == ReadBytes(bytes, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    Ok([ listingMarket |-> listingMarket.value ], listingMarket.rest)

ZeroDefineSymbolMessageTail ==
    [ listingMarket |-> [i \in 1 .. 1 |-> 0] ]

(* Define Symbol Message at zero, then each field in turn at the values it is checked at *)
CheckedDefineSymbolMessageTail ==
    { ZeroDefineSymbolMessageTail }
        \cup { [ZeroDefineSymbolMessageTail EXCEPT !.listingMarket = one] : one \in Sample(1) }

(* Define Symbol Message runs on only when bytes remain, so it is there or it is not *)
WithoutDefineSymbolMessageTail == [there |-> FALSE, value |-> ZeroDefineSymbolMessageTail]

MaybeDefineSymbolMessageTail ==
    { WithoutDefineSymbolMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedDefineSymbolMessageTail }

ReadDefineSymbolMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutDefineSymbolMessageTail, << >>)
    ELSE LET one == DecodeDefineSymbolMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Define Symbol Message                                                   *)
(***************************************************************************)

DefineSymbolMessage ==
    [ transactTime            : Sample(8),
      symbolId                : Sample(2),
      symbol                  : Sample(8),
      suffix                  : Sample(8),
      matchingEngineId        : Sample(1),
      defineSymbolBitFields   : Sample(1),
      lotSize                 : Sample(4),
      defineSymbolMessageTail : MaybeDefineSymbolMessageTail ]

EncodeDefineSymbolMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.symbol
        \o message.suffix
        \o message.matchingEngineId
        \o message.defineSymbolBitFields
        \o message.lotSize
        \o IF message.defineSymbolMessageTail.there THEN EncodeDefineSymbolMessageTail(message.defineSymbolMessageTail.value) ELSE << >>

DecodeDefineSymbolMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET symbol == ReadBytes(symbolId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET suffix == ReadBytes(symbol.rest, 8) IN IF ~suffix.ok THEN Fail ELSE
    LET matchingEngineId == ReadBytes(suffix.rest, 1) IN IF ~matchingEngineId.ok THEN Fail ELSE
    LET defineSymbolBitFields == ReadBytes(matchingEngineId.rest, 1) IN IF ~defineSymbolBitFields.ok THEN Fail ELSE
    LET lotSize == ReadBytes(defineSymbolBitFields.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET defineSymbolMessageTail == ReadDefineSymbolMessageTailMaybe(lotSize.rest) IN IF ~defineSymbolMessageTail.ok THEN Fail ELSE
    Ok([ transactTime            |-> transactTime.value,
         symbolId                |-> symbolId.value,
         symbol                  |-> symbol.value,
         suffix                  |-> suffix.value,
         matchingEngineId        |-> matchingEngineId.value,
         defineSymbolBitFields   |-> defineSymbolBitFields.value,
         lotSize                 |-> lotSize.value,
         defineSymbolMessageTail |-> defineSymbolMessageTail.value ], defineSymbolMessageTail.rest)

ZeroDefineSymbolMessage ==
    [ transactTime            |-> [i \in 1 .. 8 |-> 0],
      symbolId                |-> [i \in 1 .. 2 |-> 0],
      symbol                  |-> [i \in 1 .. 8 |-> 0],
      suffix                  |-> [i \in 1 .. 8 |-> 0],
      matchingEngineId        |-> [i \in 1 .. 1 |-> 0],
      defineSymbolBitFields   |-> [i \in 1 .. 1 |-> 0],
      lotSize                 |-> [i \in 1 .. 4 |-> 0],
      defineSymbolMessageTail |-> WithoutDefineSymbolMessageTail ]

(* Define Symbol Message at zero, then each field in turn at the values it is checked at *)
CheckedDefineSymbolMessage ==
    { ZeroDefineSymbolMessage }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.suffix = one] : one \in Sample(8) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.matchingEngineId = one] : one \in Sample(1) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.defineSymbolBitFields = one] : one \in Sample(1) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.defineSymbolMessageTail = one] : one \in MaybeDefineSymbolMessageTail }

(***************************************************************************)
(* Symbol Status Message                                                   *)
(***************************************************************************)

SymbolStatusMessage ==
    [ symbolStatusPresenceBits          : 0 .. 255,
      transactTime                      : Sample(8),
      symbolId                          : Sample(2),
      symbolTradingState                : Sample(1),
      shortSaleRestrictionState         : Sample(1),
      symbolStatusOperationalHaltReason : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolStatusRegulatoryHaltReason  : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeSymbolStatusMessage(message) ==
    EncodeUIntLE(message.symbolStatusPresenceBits, 1)
        \o message.transactTime
        \o message.symbolId
        \o message.symbolTradingState
        \o message.shortSaleRestrictionState
        \o (IF message.symbolStatusOperationalHaltReason = << >> THEN << >> ELSE message.symbolStatusOperationalHaltReason[1])
        \o (IF message.symbolStatusRegulatoryHaltReason = << >> THEN << >> ELSE message.symbolStatusRegulatoryHaltReason[1])

DecodeSymbolStatusMessage(bytes) ==
    LET symbolStatusPresenceBits == ReadUIntLE(bytes, 1) IN IF ~symbolStatusPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(symbolStatusPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET symbolTradingState == ReadBytes(symbolId.rest, 1) IN IF ~symbolTradingState.ok THEN Fail ELSE
    LET shortSaleRestrictionState == ReadBytes(symbolTradingState.rest, 1) IN IF ~shortSaleRestrictionState.ok THEN Fail ELSE
    LET symbolStatusOperationalHaltReason == ReadWhen(symbolStatusPresenceBits.value % 2 = 1, ReadBytes(shortSaleRestrictionState.rest, 1), shortSaleRestrictionState.rest) IN IF ~symbolStatusOperationalHaltReason.ok THEN Fail ELSE
    LET symbolStatusRegulatoryHaltReason == ReadWhen((symbolStatusPresenceBits.value \div 2) % 2 = 1, ReadBytes(symbolStatusOperationalHaltReason.rest, 1), symbolStatusOperationalHaltReason.rest) IN IF ~symbolStatusRegulatoryHaltReason.ok THEN Fail ELSE
    Ok([ symbolStatusPresenceBits          |-> symbolStatusPresenceBits.value,
         transactTime                      |-> transactTime.value,
         symbolId                          |-> symbolId.value,
         symbolTradingState                |-> symbolTradingState.value,
         shortSaleRestrictionState         |-> shortSaleRestrictionState.value,
         symbolStatusOperationalHaltReason |-> symbolStatusOperationalHaltReason.value,
         symbolStatusRegulatoryHaltReason  |-> symbolStatusRegulatoryHaltReason.value ], symbolStatusRegulatoryHaltReason.rest)

(* Symbol Status Message with each field marked present by fields before it there exactly where they say *)
SettleSymbolStatusMessage(message) ==
    LET settled1 == [message EXCEPT !.symbolStatusOperationalHaltReason = IF message.symbolStatusPresenceBits % 2 = 1 THEN (IF message.symbolStatusOperationalHaltReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.symbolStatusOperationalHaltReason) ELSE << >>]
        settled2 == [settled1 EXCEPT !.symbolStatusRegulatoryHaltReason = IF (settled1.symbolStatusPresenceBits \div 2) % 2 = 1 THEN (IF settled1.symbolStatusRegulatoryHaltReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.symbolStatusRegulatoryHaltReason) ELSE << >>]
    IN  settled2

ZeroSymbolStatusMessage ==
    SettleSymbolStatusMessage([ symbolStatusPresenceBits          |-> 0,
                                transactTime                      |-> [i \in 1 .. 8 |-> 0],
                                symbolId                          |-> [i \in 1 .. 2 |-> 0],
                                symbolTradingState                |-> [i \in 1 .. 1 |-> 0],
                                shortSaleRestrictionState         |-> [i \in 1 .. 1 |-> 0],
                                symbolStatusOperationalHaltReason |-> << >>,
                                symbolStatusRegulatoryHaltReason  |-> << >> ])

(* Symbol Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStatusMessage ==
    { ZeroSymbolStatusMessage }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolStatusPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolId = one]) : one \in Sample(2) }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolTradingState = one]) : one \in Sample(1) }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.shortSaleRestrictionState = one]) : one \in Sample(1) }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolStatusPresenceBits = 1, !.symbolStatusOperationalHaltReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolStatusPresenceBits = 2, !.symbolStatusRegulatoryHaltReason = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Limit Order Accepted Message                                            *)
(***************************************************************************)

LimitOrderAcceptedMessage ==
    [ limitOrderAcceptedPresenceBits          : 0 .. 255,
      transactTime                            : Sample(8),
      orderId                                 : Sample(8),
      clOrdId                                 : Sample(8),
      orderQty                                : Sample(4),
      limitOrderAcceptedBitFields             : Sample(4),
      symbolId                                : Sample(2),
      price                                   : Sample(8),
      limitOrderAcceptedSelfMatchScope        : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderAcceptedSelfMatchInstruction  : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderAcceptedPriceSlideInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderAcceptedMinQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderAcceptedMaxFloorQty           : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderAcceptedMaxReplenishQtyRange  : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderAcceptedMaxReplenishTimeRange : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderAcceptedReferencePriceTarget  : { << >> } \cup { <<held>> : held \in Sample(2) },
      limitOrderAcceptedExpireTime            : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderAcceptedUserData              : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderAcceptedMpid                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderAcceptedMemberGroup           : { << >> } \cup { <<held>> : held \in Sample(2) },
      limitOrderAcceptedLocateBroker          : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderAcceptedRankPrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderAcceptedDisplayPrice          : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeLimitOrderAcceptedMessage(message) ==
    EncodeUIntLE(message.limitOrderAcceptedPresenceBits, 4)
        \o message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.orderQty
        \o message.limitOrderAcceptedBitFields
        \o message.symbolId
        \o message.price
        \o (IF message.limitOrderAcceptedSelfMatchScope = << >> THEN << >> ELSE message.limitOrderAcceptedSelfMatchScope[1])
        \o (IF message.limitOrderAcceptedSelfMatchInstruction = << >> THEN << >> ELSE message.limitOrderAcceptedSelfMatchInstruction[1])
        \o (IF message.limitOrderAcceptedPriceSlideInstruction = << >> THEN << >> ELSE message.limitOrderAcceptedPriceSlideInstruction[1])
        \o (IF message.limitOrderAcceptedMinQty = << >> THEN << >> ELSE message.limitOrderAcceptedMinQty[1])
        \o (IF message.limitOrderAcceptedMaxFloorQty = << >> THEN << >> ELSE message.limitOrderAcceptedMaxFloorQty[1])
        \o (IF message.limitOrderAcceptedMaxReplenishQtyRange = << >> THEN << >> ELSE message.limitOrderAcceptedMaxReplenishQtyRange[1])
        \o (IF message.limitOrderAcceptedMaxReplenishTimeRange = << >> THEN << >> ELSE message.limitOrderAcceptedMaxReplenishTimeRange[1])
        \o (IF message.limitOrderAcceptedReferencePriceTarget = << >> THEN << >> ELSE message.limitOrderAcceptedReferencePriceTarget[1])
        \o (IF message.limitOrderAcceptedExpireTime = << >> THEN << >> ELSE message.limitOrderAcceptedExpireTime[1])
        \o (IF message.limitOrderAcceptedUserData = << >> THEN << >> ELSE message.limitOrderAcceptedUserData[1])
        \o (IF message.limitOrderAcceptedMpid = << >> THEN << >> ELSE message.limitOrderAcceptedMpid[1])
        \o (IF message.limitOrderAcceptedMemberGroup = << >> THEN << >> ELSE message.limitOrderAcceptedMemberGroup[1])
        \o (IF message.limitOrderAcceptedLocateBroker = << >> THEN << >> ELSE message.limitOrderAcceptedLocateBroker[1])
        \o (IF message.limitOrderAcceptedRankPrice = << >> THEN << >> ELSE message.limitOrderAcceptedRankPrice[1])
        \o (IF message.limitOrderAcceptedDisplayPrice = << >> THEN << >> ELSE message.limitOrderAcceptedDisplayPrice[1])

DecodeLimitOrderAcceptedMessage(bytes) ==
    LET limitOrderAcceptedPresenceBits == ReadUIntLE(bytes, 4) IN IF ~limitOrderAcceptedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(limitOrderAcceptedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET limitOrderAcceptedBitFields == ReadBytes(orderQty.rest, 4) IN IF ~limitOrderAcceptedBitFields.ok THEN Fail ELSE
    LET symbolId == ReadBytes(limitOrderAcceptedBitFields.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET price == ReadBytes(symbolId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET limitOrderAcceptedSelfMatchScope == ReadWhen(limitOrderAcceptedPresenceBits.value % 2 = 1, ReadBytes(price.rest, 1), price.rest) IN IF ~limitOrderAcceptedSelfMatchScope.ok THEN Fail ELSE
    LET limitOrderAcceptedSelfMatchInstruction == ReadWhen((limitOrderAcceptedPresenceBits.value \div 2) % 2 = 1, ReadBytes(limitOrderAcceptedSelfMatchScope.rest, 1), limitOrderAcceptedSelfMatchScope.rest) IN IF ~limitOrderAcceptedSelfMatchInstruction.ok THEN Fail ELSE
    LET limitOrderAcceptedPriceSlideInstruction == ReadWhen((limitOrderAcceptedPresenceBits.value \div 4) % 2 = 1, ReadBytes(limitOrderAcceptedSelfMatchInstruction.rest, 1), limitOrderAcceptedSelfMatchInstruction.rest) IN IF ~limitOrderAcceptedPriceSlideInstruction.ok THEN Fail ELSE
    LET limitOrderAcceptedMinQty == ReadWhen((limitOrderAcceptedPresenceBits.value \div 8) % 2 = 1, ReadBytes(limitOrderAcceptedPriceSlideInstruction.rest, 4), limitOrderAcceptedPriceSlideInstruction.rest) IN IF ~limitOrderAcceptedMinQty.ok THEN Fail ELSE
    LET limitOrderAcceptedMaxFloorQty == ReadWhen((limitOrderAcceptedPresenceBits.value \div 16) % 2 = 1, ReadBytes(limitOrderAcceptedMinQty.rest, 4), limitOrderAcceptedMinQty.rest) IN IF ~limitOrderAcceptedMaxFloorQty.ok THEN Fail ELSE
    LET limitOrderAcceptedMaxReplenishQtyRange == ReadWhen((limitOrderAcceptedPresenceBits.value \div 32) % 2 = 1, ReadBytes(limitOrderAcceptedMaxFloorQty.rest, 4), limitOrderAcceptedMaxFloorQty.rest) IN IF ~limitOrderAcceptedMaxReplenishQtyRange.ok THEN Fail ELSE
    LET limitOrderAcceptedMaxReplenishTimeRange == ReadWhen((limitOrderAcceptedPresenceBits.value \div 64) % 2 = 1, ReadBytes(limitOrderAcceptedMaxReplenishQtyRange.rest, 8), limitOrderAcceptedMaxReplenishQtyRange.rest) IN IF ~limitOrderAcceptedMaxReplenishTimeRange.ok THEN Fail ELSE
    LET limitOrderAcceptedReferencePriceTarget == ReadWhen((limitOrderAcceptedPresenceBits.value \div 128) % 2 = 1, ReadBytes(limitOrderAcceptedMaxReplenishTimeRange.rest, 2), limitOrderAcceptedMaxReplenishTimeRange.rest) IN IF ~limitOrderAcceptedReferencePriceTarget.ok THEN Fail ELSE
    LET limitOrderAcceptedExpireTime == ReadWhen((limitOrderAcceptedPresenceBits.value \div 256) % 2 = 1, ReadBytes(limitOrderAcceptedReferencePriceTarget.rest, 8), limitOrderAcceptedReferencePriceTarget.rest) IN IF ~limitOrderAcceptedExpireTime.ok THEN Fail ELSE
    LET limitOrderAcceptedUserData == ReadWhen((limitOrderAcceptedPresenceBits.value \div 512) % 2 = 1, ReadBytes(limitOrderAcceptedExpireTime.rest, 8), limitOrderAcceptedExpireTime.rest) IN IF ~limitOrderAcceptedUserData.ok THEN Fail ELSE
    LET limitOrderAcceptedMpid == ReadWhen((limitOrderAcceptedPresenceBits.value \div 1024) % 2 = 1, ReadBytes(limitOrderAcceptedUserData.rest, 4), limitOrderAcceptedUserData.rest) IN IF ~limitOrderAcceptedMpid.ok THEN Fail ELSE
    LET limitOrderAcceptedMemberGroup == ReadWhen((limitOrderAcceptedPresenceBits.value \div 2048) % 2 = 1, ReadBytes(limitOrderAcceptedMpid.rest, 2), limitOrderAcceptedMpid.rest) IN IF ~limitOrderAcceptedMemberGroup.ok THEN Fail ELSE
    LET limitOrderAcceptedLocateBroker == ReadWhen((limitOrderAcceptedPresenceBits.value \div 4096) % 2 = 1, ReadBytes(limitOrderAcceptedMemberGroup.rest, 4), limitOrderAcceptedMemberGroup.rest) IN IF ~limitOrderAcceptedLocateBroker.ok THEN Fail ELSE
    LET limitOrderAcceptedRankPrice == ReadWhen((limitOrderAcceptedPresenceBits.value \div 8192) % 2 = 1, ReadBytes(limitOrderAcceptedLocateBroker.rest, 8), limitOrderAcceptedLocateBroker.rest) IN IF ~limitOrderAcceptedRankPrice.ok THEN Fail ELSE
    LET limitOrderAcceptedDisplayPrice == ReadWhen((limitOrderAcceptedPresenceBits.value \div 16384) % 2 = 1, ReadBytes(limitOrderAcceptedRankPrice.rest, 8), limitOrderAcceptedRankPrice.rest) IN IF ~limitOrderAcceptedDisplayPrice.ok THEN Fail ELSE
    Ok([ limitOrderAcceptedPresenceBits          |-> limitOrderAcceptedPresenceBits.value,
         transactTime                            |-> transactTime.value,
         orderId                                 |-> orderId.value,
         clOrdId                                 |-> clOrdId.value,
         orderQty                                |-> orderQty.value,
         limitOrderAcceptedBitFields             |-> limitOrderAcceptedBitFields.value,
         symbolId                                |-> symbolId.value,
         price                                   |-> price.value,
         limitOrderAcceptedSelfMatchScope        |-> limitOrderAcceptedSelfMatchScope.value,
         limitOrderAcceptedSelfMatchInstruction  |-> limitOrderAcceptedSelfMatchInstruction.value,
         limitOrderAcceptedPriceSlideInstruction |-> limitOrderAcceptedPriceSlideInstruction.value,
         limitOrderAcceptedMinQty                |-> limitOrderAcceptedMinQty.value,
         limitOrderAcceptedMaxFloorQty           |-> limitOrderAcceptedMaxFloorQty.value,
         limitOrderAcceptedMaxReplenishQtyRange  |-> limitOrderAcceptedMaxReplenishQtyRange.value,
         limitOrderAcceptedMaxReplenishTimeRange |-> limitOrderAcceptedMaxReplenishTimeRange.value,
         limitOrderAcceptedReferencePriceTarget  |-> limitOrderAcceptedReferencePriceTarget.value,
         limitOrderAcceptedExpireTime            |-> limitOrderAcceptedExpireTime.value,
         limitOrderAcceptedUserData              |-> limitOrderAcceptedUserData.value,
         limitOrderAcceptedMpid                  |-> limitOrderAcceptedMpid.value,
         limitOrderAcceptedMemberGroup           |-> limitOrderAcceptedMemberGroup.value,
         limitOrderAcceptedLocateBroker          |-> limitOrderAcceptedLocateBroker.value,
         limitOrderAcceptedRankPrice             |-> limitOrderAcceptedRankPrice.value,
         limitOrderAcceptedDisplayPrice          |-> limitOrderAcceptedDisplayPrice.value ], limitOrderAcceptedDisplayPrice.rest)

(* Limit Order Accepted Message with each field marked present by fields before it there exactly where they say *)
SettleLimitOrderAcceptedMessage(message) ==
    LET settled1 == [message EXCEPT !.limitOrderAcceptedSelfMatchScope = IF message.limitOrderAcceptedPresenceBits % 2 = 1 THEN (IF message.limitOrderAcceptedSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.limitOrderAcceptedSelfMatchScope) ELSE << >>]
        settled2 == [settled1 EXCEPT !.limitOrderAcceptedSelfMatchInstruction = IF (settled1.limitOrderAcceptedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.limitOrderAcceptedSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.limitOrderAcceptedSelfMatchInstruction) ELSE << >>]
        settled3 == [settled2 EXCEPT !.limitOrderAcceptedPriceSlideInstruction = IF (settled2.limitOrderAcceptedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.limitOrderAcceptedPriceSlideInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.limitOrderAcceptedPriceSlideInstruction) ELSE << >>]
        settled4 == [settled3 EXCEPT !.limitOrderAcceptedMinQty = IF (settled3.limitOrderAcceptedPresenceBits \div 8) % 2 = 1 THEN (IF settled3.limitOrderAcceptedMinQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.limitOrderAcceptedMinQty) ELSE << >>]
        settled5 == [settled4 EXCEPT !.limitOrderAcceptedMaxFloorQty = IF (settled4.limitOrderAcceptedPresenceBits \div 16) % 2 = 1 THEN (IF settled4.limitOrderAcceptedMaxFloorQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled4.limitOrderAcceptedMaxFloorQty) ELSE << >>]
        settled6 == [settled5 EXCEPT !.limitOrderAcceptedMaxReplenishQtyRange = IF (settled5.limitOrderAcceptedPresenceBits \div 32) % 2 = 1 THEN (IF settled5.limitOrderAcceptedMaxReplenishQtyRange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled5.limitOrderAcceptedMaxReplenishQtyRange) ELSE << >>]
        settled7 == [settled6 EXCEPT !.limitOrderAcceptedMaxReplenishTimeRange = IF (settled6.limitOrderAcceptedPresenceBits \div 64) % 2 = 1 THEN (IF settled6.limitOrderAcceptedMaxReplenishTimeRange = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled6.limitOrderAcceptedMaxReplenishTimeRange) ELSE << >>]
        settled8 == [settled7 EXCEPT !.limitOrderAcceptedReferencePriceTarget = IF (settled7.limitOrderAcceptedPresenceBits \div 128) % 2 = 1 THEN (IF settled7.limitOrderAcceptedReferencePriceTarget = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled7.limitOrderAcceptedReferencePriceTarget) ELSE << >>]
        settled9 == [settled8 EXCEPT !.limitOrderAcceptedExpireTime = IF (settled8.limitOrderAcceptedPresenceBits \div 256) % 2 = 1 THEN (IF settled8.limitOrderAcceptedExpireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled8.limitOrderAcceptedExpireTime) ELSE << >>]
        settled10 == [settled9 EXCEPT !.limitOrderAcceptedUserData = IF (settled9.limitOrderAcceptedPresenceBits \div 512) % 2 = 1 THEN (IF settled9.limitOrderAcceptedUserData = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled9.limitOrderAcceptedUserData) ELSE << >>]
        settled11 == [settled10 EXCEPT !.limitOrderAcceptedMpid = IF (settled10.limitOrderAcceptedPresenceBits \div 1024) % 2 = 1 THEN (IF settled10.limitOrderAcceptedMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled10.limitOrderAcceptedMpid) ELSE << >>]
        settled12 == [settled11 EXCEPT !.limitOrderAcceptedMemberGroup = IF (settled11.limitOrderAcceptedPresenceBits \div 2048) % 2 = 1 THEN (IF settled11.limitOrderAcceptedMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled11.limitOrderAcceptedMemberGroup) ELSE << >>]
        settled13 == [settled12 EXCEPT !.limitOrderAcceptedLocateBroker = IF (settled12.limitOrderAcceptedPresenceBits \div 4096) % 2 = 1 THEN (IF settled12.limitOrderAcceptedLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled12.limitOrderAcceptedLocateBroker) ELSE << >>]
        settled14 == [settled13 EXCEPT !.limitOrderAcceptedRankPrice = IF (settled13.limitOrderAcceptedPresenceBits \div 8192) % 2 = 1 THEN (IF settled13.limitOrderAcceptedRankPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled13.limitOrderAcceptedRankPrice) ELSE << >>]
        settled15 == [settled14 EXCEPT !.limitOrderAcceptedDisplayPrice = IF (settled14.limitOrderAcceptedPresenceBits \div 16384) % 2 = 1 THEN (IF settled14.limitOrderAcceptedDisplayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled14.limitOrderAcceptedDisplayPrice) ELSE << >>]
    IN  settled15

ZeroLimitOrderAcceptedMessage ==
    SettleLimitOrderAcceptedMessage([ limitOrderAcceptedPresenceBits          |-> 0,
                                      transactTime                            |-> [i \in 1 .. 8 |-> 0],
                                      orderId                                 |-> [i \in 1 .. 8 |-> 0],
                                      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
                                      orderQty                                |-> [i \in 1 .. 4 |-> 0],
                                      limitOrderAcceptedBitFields             |-> [i \in 1 .. 4 |-> 0],
                                      symbolId                                |-> [i \in 1 .. 2 |-> 0],
                                      price                                   |-> [i \in 1 .. 8 |-> 0],
                                      limitOrderAcceptedSelfMatchScope        |-> << >>,
                                      limitOrderAcceptedSelfMatchInstruction  |-> << >>,
                                      limitOrderAcceptedPriceSlideInstruction |-> << >>,
                                      limitOrderAcceptedMinQty                |-> << >>,
                                      limitOrderAcceptedMaxFloorQty           |-> << >>,
                                      limitOrderAcceptedMaxReplenishQtyRange  |-> << >>,
                                      limitOrderAcceptedMaxReplenishTimeRange |-> << >>,
                                      limitOrderAcceptedReferencePriceTarget  |-> << >>,
                                      limitOrderAcceptedExpireTime            |-> << >>,
                                      limitOrderAcceptedUserData              |-> << >>,
                                      limitOrderAcceptedMpid                  |-> << >>,
                                      limitOrderAcceptedMemberGroup           |-> << >>,
                                      limitOrderAcceptedLocateBroker          |-> << >>,
                                      limitOrderAcceptedRankPrice             |-> << >>,
                                      limitOrderAcceptedDisplayPrice          |-> << >> ])

(* Limit Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitOrderAcceptedMessage ==
    { ZeroLimitOrderAcceptedMessage }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.orderQty = one]) : one \in Sample(4) }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedBitFields = one]) : one \in Sample(4) }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.symbolId = one]) : one \in Sample(2) }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.price = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 1, !.limitOrderAcceptedSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 2, !.limitOrderAcceptedSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 4, !.limitOrderAcceptedPriceSlideInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 8, !.limitOrderAcceptedMinQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 16, !.limitOrderAcceptedMaxFloorQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 32, !.limitOrderAcceptedMaxReplenishQtyRange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 64, !.limitOrderAcceptedMaxReplenishTimeRange = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 128, !.limitOrderAcceptedReferencePriceTarget = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 256, !.limitOrderAcceptedExpireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 512, !.limitOrderAcceptedUserData = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 1024, !.limitOrderAcceptedMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 2048, !.limitOrderAcceptedMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 4096, !.limitOrderAcceptedLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 8192, !.limitOrderAcceptedRankPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderAcceptedMessage([ZeroLimitOrderAcceptedMessage EXCEPT !.limitOrderAcceptedPresenceBits = 16384, !.limitOrderAcceptedDisplayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Limit Order Rejected Message                                            *)
(***************************************************************************)

LimitOrderRejectedMessage ==
    [ limitOrderRejectedPresenceBits          : 0 .. 255,
      transactTime                            : Sample(8),
      clOrdId                                 : Sample(8),
      orderQty                                : Sample(4),
      limitOrderRejectedBitFields             : Sample(4),
      symbolId                                : Sample(2),
      price                                   : Sample(8),
      limitOrderRejectedReason                : Sample(1),
      limitOrderRejectedSelfMatchScope        : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderRejectedSelfMatchInstruction  : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderRejectedPriceSlideInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderRejectedMinQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderRejectedMaxFloorQty           : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderRejectedMaxReplenishQtyRange  : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderRejectedMaxReplenishTimeRange : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderRejectedReferencePriceTarget  : { << >> } \cup { <<held>> : held \in Sample(2) },
      limitOrderRejectedExpireTime            : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderRejectedUserData              : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderRejectedMpid                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderRejectedMemberGroup           : { << >> } \cup { <<held>> : held \in Sample(2) },
      limitOrderRejectedLocateBroker          : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeLimitOrderRejectedMessage(message) ==
    EncodeUIntLE(message.limitOrderRejectedPresenceBits, 4)
        \o message.transactTime
        \o message.clOrdId
        \o message.orderQty
        \o message.limitOrderRejectedBitFields
        \o message.symbolId
        \o message.price
        \o message.limitOrderRejectedReason
        \o (IF message.limitOrderRejectedSelfMatchScope = << >> THEN << >> ELSE message.limitOrderRejectedSelfMatchScope[1])
        \o (IF message.limitOrderRejectedSelfMatchInstruction = << >> THEN << >> ELSE message.limitOrderRejectedSelfMatchInstruction[1])
        \o (IF message.limitOrderRejectedPriceSlideInstruction = << >> THEN << >> ELSE message.limitOrderRejectedPriceSlideInstruction[1])
        \o (IF message.limitOrderRejectedMinQty = << >> THEN << >> ELSE message.limitOrderRejectedMinQty[1])
        \o (IF message.limitOrderRejectedMaxFloorQty = << >> THEN << >> ELSE message.limitOrderRejectedMaxFloorQty[1])
        \o (IF message.limitOrderRejectedMaxReplenishQtyRange = << >> THEN << >> ELSE message.limitOrderRejectedMaxReplenishQtyRange[1])
        \o (IF message.limitOrderRejectedMaxReplenishTimeRange = << >> THEN << >> ELSE message.limitOrderRejectedMaxReplenishTimeRange[1])
        \o (IF message.limitOrderRejectedReferencePriceTarget = << >> THEN << >> ELSE message.limitOrderRejectedReferencePriceTarget[1])
        \o (IF message.limitOrderRejectedExpireTime = << >> THEN << >> ELSE message.limitOrderRejectedExpireTime[1])
        \o (IF message.limitOrderRejectedUserData = << >> THEN << >> ELSE message.limitOrderRejectedUserData[1])
        \o (IF message.limitOrderRejectedMpid = << >> THEN << >> ELSE message.limitOrderRejectedMpid[1])
        \o (IF message.limitOrderRejectedMemberGroup = << >> THEN << >> ELSE message.limitOrderRejectedMemberGroup[1])
        \o (IF message.limitOrderRejectedLocateBroker = << >> THEN << >> ELSE message.limitOrderRejectedLocateBroker[1])

DecodeLimitOrderRejectedMessage(bytes) ==
    LET limitOrderRejectedPresenceBits == ReadUIntLE(bytes, 4) IN IF ~limitOrderRejectedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(limitOrderRejectedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactTime.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET limitOrderRejectedBitFields == ReadBytes(orderQty.rest, 4) IN IF ~limitOrderRejectedBitFields.ok THEN Fail ELSE
    LET symbolId == ReadBytes(limitOrderRejectedBitFields.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET price == ReadBytes(symbolId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET limitOrderRejectedReason == ReadBytes(price.rest, 1) IN IF ~limitOrderRejectedReason.ok THEN Fail ELSE
    LET limitOrderRejectedSelfMatchScope == ReadWhen(limitOrderRejectedPresenceBits.value % 2 = 1, ReadBytes(limitOrderRejectedReason.rest, 1), limitOrderRejectedReason.rest) IN IF ~limitOrderRejectedSelfMatchScope.ok THEN Fail ELSE
    LET limitOrderRejectedSelfMatchInstruction == ReadWhen((limitOrderRejectedPresenceBits.value \div 2) % 2 = 1, ReadBytes(limitOrderRejectedSelfMatchScope.rest, 1), limitOrderRejectedSelfMatchScope.rest) IN IF ~limitOrderRejectedSelfMatchInstruction.ok THEN Fail ELSE
    LET limitOrderRejectedPriceSlideInstruction == ReadWhen((limitOrderRejectedPresenceBits.value \div 4) % 2 = 1, ReadBytes(limitOrderRejectedSelfMatchInstruction.rest, 1), limitOrderRejectedSelfMatchInstruction.rest) IN IF ~limitOrderRejectedPriceSlideInstruction.ok THEN Fail ELSE
    LET limitOrderRejectedMinQty == ReadWhen((limitOrderRejectedPresenceBits.value \div 8) % 2 = 1, ReadBytes(limitOrderRejectedPriceSlideInstruction.rest, 4), limitOrderRejectedPriceSlideInstruction.rest) IN IF ~limitOrderRejectedMinQty.ok THEN Fail ELSE
    LET limitOrderRejectedMaxFloorQty == ReadWhen((limitOrderRejectedPresenceBits.value \div 16) % 2 = 1, ReadBytes(limitOrderRejectedMinQty.rest, 4), limitOrderRejectedMinQty.rest) IN IF ~limitOrderRejectedMaxFloorQty.ok THEN Fail ELSE
    LET limitOrderRejectedMaxReplenishQtyRange == ReadWhen((limitOrderRejectedPresenceBits.value \div 32) % 2 = 1, ReadBytes(limitOrderRejectedMaxFloorQty.rest, 4), limitOrderRejectedMaxFloorQty.rest) IN IF ~limitOrderRejectedMaxReplenishQtyRange.ok THEN Fail ELSE
    LET limitOrderRejectedMaxReplenishTimeRange == ReadWhen((limitOrderRejectedPresenceBits.value \div 64) % 2 = 1, ReadBytes(limitOrderRejectedMaxReplenishQtyRange.rest, 8), limitOrderRejectedMaxReplenishQtyRange.rest) IN IF ~limitOrderRejectedMaxReplenishTimeRange.ok THEN Fail ELSE
    LET limitOrderRejectedReferencePriceTarget == ReadWhen((limitOrderRejectedPresenceBits.value \div 128) % 2 = 1, ReadBytes(limitOrderRejectedMaxReplenishTimeRange.rest, 2), limitOrderRejectedMaxReplenishTimeRange.rest) IN IF ~limitOrderRejectedReferencePriceTarget.ok THEN Fail ELSE
    LET limitOrderRejectedExpireTime == ReadWhen((limitOrderRejectedPresenceBits.value \div 256) % 2 = 1, ReadBytes(limitOrderRejectedReferencePriceTarget.rest, 8), limitOrderRejectedReferencePriceTarget.rest) IN IF ~limitOrderRejectedExpireTime.ok THEN Fail ELSE
    LET limitOrderRejectedUserData == ReadWhen((limitOrderRejectedPresenceBits.value \div 512) % 2 = 1, ReadBytes(limitOrderRejectedExpireTime.rest, 8), limitOrderRejectedExpireTime.rest) IN IF ~limitOrderRejectedUserData.ok THEN Fail ELSE
    LET limitOrderRejectedMpid == ReadWhen((limitOrderRejectedPresenceBits.value \div 1024) % 2 = 1, ReadBytes(limitOrderRejectedUserData.rest, 4), limitOrderRejectedUserData.rest) IN IF ~limitOrderRejectedMpid.ok THEN Fail ELSE
    LET limitOrderRejectedMemberGroup == ReadWhen((limitOrderRejectedPresenceBits.value \div 2048) % 2 = 1, ReadBytes(limitOrderRejectedMpid.rest, 2), limitOrderRejectedMpid.rest) IN IF ~limitOrderRejectedMemberGroup.ok THEN Fail ELSE
    LET limitOrderRejectedLocateBroker == ReadWhen((limitOrderRejectedPresenceBits.value \div 4096) % 2 = 1, ReadBytes(limitOrderRejectedMemberGroup.rest, 4), limitOrderRejectedMemberGroup.rest) IN IF ~limitOrderRejectedLocateBroker.ok THEN Fail ELSE
    Ok([ limitOrderRejectedPresenceBits          |-> limitOrderRejectedPresenceBits.value,
         transactTime                            |-> transactTime.value,
         clOrdId                                 |-> clOrdId.value,
         orderQty                                |-> orderQty.value,
         limitOrderRejectedBitFields             |-> limitOrderRejectedBitFields.value,
         symbolId                                |-> symbolId.value,
         price                                   |-> price.value,
         limitOrderRejectedReason                |-> limitOrderRejectedReason.value,
         limitOrderRejectedSelfMatchScope        |-> limitOrderRejectedSelfMatchScope.value,
         limitOrderRejectedSelfMatchInstruction  |-> limitOrderRejectedSelfMatchInstruction.value,
         limitOrderRejectedPriceSlideInstruction |-> limitOrderRejectedPriceSlideInstruction.value,
         limitOrderRejectedMinQty                |-> limitOrderRejectedMinQty.value,
         limitOrderRejectedMaxFloorQty           |-> limitOrderRejectedMaxFloorQty.value,
         limitOrderRejectedMaxReplenishQtyRange  |-> limitOrderRejectedMaxReplenishQtyRange.value,
         limitOrderRejectedMaxReplenishTimeRange |-> limitOrderRejectedMaxReplenishTimeRange.value,
         limitOrderRejectedReferencePriceTarget  |-> limitOrderRejectedReferencePriceTarget.value,
         limitOrderRejectedExpireTime            |-> limitOrderRejectedExpireTime.value,
         limitOrderRejectedUserData              |-> limitOrderRejectedUserData.value,
         limitOrderRejectedMpid                  |-> limitOrderRejectedMpid.value,
         limitOrderRejectedMemberGroup           |-> limitOrderRejectedMemberGroup.value,
         limitOrderRejectedLocateBroker          |-> limitOrderRejectedLocateBroker.value ], limitOrderRejectedLocateBroker.rest)

(* Limit Order Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleLimitOrderRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.limitOrderRejectedSelfMatchScope = IF message.limitOrderRejectedPresenceBits % 2 = 1 THEN (IF message.limitOrderRejectedSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.limitOrderRejectedSelfMatchScope) ELSE << >>]
        settled2 == [settled1 EXCEPT !.limitOrderRejectedSelfMatchInstruction = IF (settled1.limitOrderRejectedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.limitOrderRejectedSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.limitOrderRejectedSelfMatchInstruction) ELSE << >>]
        settled3 == [settled2 EXCEPT !.limitOrderRejectedPriceSlideInstruction = IF (settled2.limitOrderRejectedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.limitOrderRejectedPriceSlideInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.limitOrderRejectedPriceSlideInstruction) ELSE << >>]
        settled4 == [settled3 EXCEPT !.limitOrderRejectedMinQty = IF (settled3.limitOrderRejectedPresenceBits \div 8) % 2 = 1 THEN (IF settled3.limitOrderRejectedMinQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.limitOrderRejectedMinQty) ELSE << >>]
        settled5 == [settled4 EXCEPT !.limitOrderRejectedMaxFloorQty = IF (settled4.limitOrderRejectedPresenceBits \div 16) % 2 = 1 THEN (IF settled4.limitOrderRejectedMaxFloorQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled4.limitOrderRejectedMaxFloorQty) ELSE << >>]
        settled6 == [settled5 EXCEPT !.limitOrderRejectedMaxReplenishQtyRange = IF (settled5.limitOrderRejectedPresenceBits \div 32) % 2 = 1 THEN (IF settled5.limitOrderRejectedMaxReplenishQtyRange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled5.limitOrderRejectedMaxReplenishQtyRange) ELSE << >>]
        settled7 == [settled6 EXCEPT !.limitOrderRejectedMaxReplenishTimeRange = IF (settled6.limitOrderRejectedPresenceBits \div 64) % 2 = 1 THEN (IF settled6.limitOrderRejectedMaxReplenishTimeRange = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled6.limitOrderRejectedMaxReplenishTimeRange) ELSE << >>]
        settled8 == [settled7 EXCEPT !.limitOrderRejectedReferencePriceTarget = IF (settled7.limitOrderRejectedPresenceBits \div 128) % 2 = 1 THEN (IF settled7.limitOrderRejectedReferencePriceTarget = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled7.limitOrderRejectedReferencePriceTarget) ELSE << >>]
        settled9 == [settled8 EXCEPT !.limitOrderRejectedExpireTime = IF (settled8.limitOrderRejectedPresenceBits \div 256) % 2 = 1 THEN (IF settled8.limitOrderRejectedExpireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled8.limitOrderRejectedExpireTime) ELSE << >>]
        settled10 == [settled9 EXCEPT !.limitOrderRejectedUserData = IF (settled9.limitOrderRejectedPresenceBits \div 512) % 2 = 1 THEN (IF settled9.limitOrderRejectedUserData = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled9.limitOrderRejectedUserData) ELSE << >>]
        settled11 == [settled10 EXCEPT !.limitOrderRejectedMpid = IF (settled10.limitOrderRejectedPresenceBits \div 1024) % 2 = 1 THEN (IF settled10.limitOrderRejectedMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled10.limitOrderRejectedMpid) ELSE << >>]
        settled12 == [settled11 EXCEPT !.limitOrderRejectedMemberGroup = IF (settled11.limitOrderRejectedPresenceBits \div 2048) % 2 = 1 THEN (IF settled11.limitOrderRejectedMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled11.limitOrderRejectedMemberGroup) ELSE << >>]
        settled13 == [settled12 EXCEPT !.limitOrderRejectedLocateBroker = IF (settled12.limitOrderRejectedPresenceBits \div 4096) % 2 = 1 THEN (IF settled12.limitOrderRejectedLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled12.limitOrderRejectedLocateBroker) ELSE << >>]
    IN  settled13

ZeroLimitOrderRejectedMessage ==
    SettleLimitOrderRejectedMessage([ limitOrderRejectedPresenceBits          |-> 0,
                                      transactTime                            |-> [i \in 1 .. 8 |-> 0],
                                      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
                                      orderQty                                |-> [i \in 1 .. 4 |-> 0],
                                      limitOrderRejectedBitFields             |-> [i \in 1 .. 4 |-> 0],
                                      symbolId                                |-> [i \in 1 .. 2 |-> 0],
                                      price                                   |-> [i \in 1 .. 8 |-> 0],
                                      limitOrderRejectedReason                |-> [i \in 1 .. 1 |-> 0],
                                      limitOrderRejectedSelfMatchScope        |-> << >>,
                                      limitOrderRejectedSelfMatchInstruction  |-> << >>,
                                      limitOrderRejectedPriceSlideInstruction |-> << >>,
                                      limitOrderRejectedMinQty                |-> << >>,
                                      limitOrderRejectedMaxFloorQty           |-> << >>,
                                      limitOrderRejectedMaxReplenishQtyRange  |-> << >>,
                                      limitOrderRejectedMaxReplenishTimeRange |-> << >>,
                                      limitOrderRejectedReferencePriceTarget  |-> << >>,
                                      limitOrderRejectedExpireTime            |-> << >>,
                                      limitOrderRejectedUserData              |-> << >>,
                                      limitOrderRejectedMpid                  |-> << >>,
                                      limitOrderRejectedMemberGroup           |-> << >>,
                                      limitOrderRejectedLocateBroker          |-> << >> ])

(* Limit Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitOrderRejectedMessage ==
    { ZeroLimitOrderRejectedMessage }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.orderQty = one]) : one \in Sample(4) }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedBitFields = one]) : one \in Sample(4) }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.symbolId = one]) : one \in Sample(2) }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.price = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedReason = one]) : one \in Sample(1) }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 1, !.limitOrderRejectedSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 2, !.limitOrderRejectedSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 4, !.limitOrderRejectedPriceSlideInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 8, !.limitOrderRejectedMinQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 16, !.limitOrderRejectedMaxFloorQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 32, !.limitOrderRejectedMaxReplenishQtyRange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 64, !.limitOrderRejectedMaxReplenishTimeRange = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 128, !.limitOrderRejectedReferencePriceTarget = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 256, !.limitOrderRejectedExpireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 512, !.limitOrderRejectedUserData = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 1024, !.limitOrderRejectedMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 2048, !.limitOrderRejectedMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleLimitOrderRejectedMessage([ZeroLimitOrderRejectedMessage EXCEPT !.limitOrderRejectedPresenceBits = 4096, !.limitOrderRejectedLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Market Order Accepted Message                                           *)
(***************************************************************************)

MarketOrderAcceptedMessage ==
    [ marketOrderAcceptedPresenceBits         : 0 .. 255,
      transactTime                            : Sample(8),
      orderId                                 : Sample(8),
      clOrdId                                 : Sample(8),
      orderQty                                : Sample(4),
      marketOrderAcceptedBitFields            : Sample(2),
      symbolId                                : Sample(2),
      marketOrderAcceptedSelfMatchScope       : { << >> } \cup { <<held>> : held \in Sample(1) },
      marketOrderAcceptedSelfMatchInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      marketOrderAcceptedUserData             : { << >> } \cup { <<held>> : held \in Sample(8) },
      marketOrderAcceptedMpid                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      marketOrderAcceptedMemberGroup          : { << >> } \cup { <<held>> : held \in Sample(2) },
      marketOrderAcceptedLocateBroker         : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeMarketOrderAcceptedMessage(message) ==
    EncodeUIntLE(message.marketOrderAcceptedPresenceBits, 2)
        \o message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.orderQty
        \o message.marketOrderAcceptedBitFields
        \o message.symbolId
        \o (IF message.marketOrderAcceptedSelfMatchScope = << >> THEN << >> ELSE message.marketOrderAcceptedSelfMatchScope[1])
        \o (IF message.marketOrderAcceptedSelfMatchInstruction = << >> THEN << >> ELSE message.marketOrderAcceptedSelfMatchInstruction[1])
        \o (IF message.marketOrderAcceptedUserData = << >> THEN << >> ELSE message.marketOrderAcceptedUserData[1])
        \o (IF message.marketOrderAcceptedMpid = << >> THEN << >> ELSE message.marketOrderAcceptedMpid[1])
        \o (IF message.marketOrderAcceptedMemberGroup = << >> THEN << >> ELSE message.marketOrderAcceptedMemberGroup[1])
        \o (IF message.marketOrderAcceptedLocateBroker = << >> THEN << >> ELSE message.marketOrderAcceptedLocateBroker[1])

DecodeMarketOrderAcceptedMessage(bytes) ==
    LET marketOrderAcceptedPresenceBits == ReadUIntLE(bytes, 2) IN IF ~marketOrderAcceptedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(marketOrderAcceptedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketOrderAcceptedBitFields == ReadBytes(orderQty.rest, 2) IN IF ~marketOrderAcceptedBitFields.ok THEN Fail ELSE
    LET symbolId == ReadBytes(marketOrderAcceptedBitFields.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET marketOrderAcceptedSelfMatchScope == ReadWhen(marketOrderAcceptedPresenceBits.value % 2 = 1, ReadBytes(symbolId.rest, 1), symbolId.rest) IN IF ~marketOrderAcceptedSelfMatchScope.ok THEN Fail ELSE
    LET marketOrderAcceptedSelfMatchInstruction == ReadWhen((marketOrderAcceptedPresenceBits.value \div 2) % 2 = 1, ReadBytes(marketOrderAcceptedSelfMatchScope.rest, 1), marketOrderAcceptedSelfMatchScope.rest) IN IF ~marketOrderAcceptedSelfMatchInstruction.ok THEN Fail ELSE
    LET marketOrderAcceptedUserData == ReadWhen((marketOrderAcceptedPresenceBits.value \div 4) % 2 = 1, ReadBytes(marketOrderAcceptedSelfMatchInstruction.rest, 8), marketOrderAcceptedSelfMatchInstruction.rest) IN IF ~marketOrderAcceptedUserData.ok THEN Fail ELSE
    LET marketOrderAcceptedMpid == ReadWhen((marketOrderAcceptedPresenceBits.value \div 8) % 2 = 1, ReadBytes(marketOrderAcceptedUserData.rest, 4), marketOrderAcceptedUserData.rest) IN IF ~marketOrderAcceptedMpid.ok THEN Fail ELSE
    LET marketOrderAcceptedMemberGroup == ReadWhen((marketOrderAcceptedPresenceBits.value \div 16) % 2 = 1, ReadBytes(marketOrderAcceptedMpid.rest, 2), marketOrderAcceptedMpid.rest) IN IF ~marketOrderAcceptedMemberGroup.ok THEN Fail ELSE
    LET marketOrderAcceptedLocateBroker == ReadWhen((marketOrderAcceptedPresenceBits.value \div 32) % 2 = 1, ReadBytes(marketOrderAcceptedMemberGroup.rest, 4), marketOrderAcceptedMemberGroup.rest) IN IF ~marketOrderAcceptedLocateBroker.ok THEN Fail ELSE
    Ok([ marketOrderAcceptedPresenceBits         |-> marketOrderAcceptedPresenceBits.value,
         transactTime                            |-> transactTime.value,
         orderId                                 |-> orderId.value,
         clOrdId                                 |-> clOrdId.value,
         orderQty                                |-> orderQty.value,
         marketOrderAcceptedBitFields            |-> marketOrderAcceptedBitFields.value,
         symbolId                                |-> symbolId.value,
         marketOrderAcceptedSelfMatchScope       |-> marketOrderAcceptedSelfMatchScope.value,
         marketOrderAcceptedSelfMatchInstruction |-> marketOrderAcceptedSelfMatchInstruction.value,
         marketOrderAcceptedUserData             |-> marketOrderAcceptedUserData.value,
         marketOrderAcceptedMpid                 |-> marketOrderAcceptedMpid.value,
         marketOrderAcceptedMemberGroup          |-> marketOrderAcceptedMemberGroup.value,
         marketOrderAcceptedLocateBroker         |-> marketOrderAcceptedLocateBroker.value ], marketOrderAcceptedLocateBroker.rest)

(* Market Order Accepted Message with each field marked present by fields before it there exactly where they say *)
SettleMarketOrderAcceptedMessage(message) ==
    LET settled1 == [message EXCEPT !.marketOrderAcceptedSelfMatchScope = IF message.marketOrderAcceptedPresenceBits % 2 = 1 THEN (IF message.marketOrderAcceptedSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.marketOrderAcceptedSelfMatchScope) ELSE << >>]
        settled2 == [settled1 EXCEPT !.marketOrderAcceptedSelfMatchInstruction = IF (settled1.marketOrderAcceptedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.marketOrderAcceptedSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.marketOrderAcceptedSelfMatchInstruction) ELSE << >>]
        settled3 == [settled2 EXCEPT !.marketOrderAcceptedUserData = IF (settled2.marketOrderAcceptedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.marketOrderAcceptedUserData = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled2.marketOrderAcceptedUserData) ELSE << >>]
        settled4 == [settled3 EXCEPT !.marketOrderAcceptedMpid = IF (settled3.marketOrderAcceptedPresenceBits \div 8) % 2 = 1 THEN (IF settled3.marketOrderAcceptedMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.marketOrderAcceptedMpid) ELSE << >>]
        settled5 == [settled4 EXCEPT !.marketOrderAcceptedMemberGroup = IF (settled4.marketOrderAcceptedPresenceBits \div 16) % 2 = 1 THEN (IF settled4.marketOrderAcceptedMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled4.marketOrderAcceptedMemberGroup) ELSE << >>]
        settled6 == [settled5 EXCEPT !.marketOrderAcceptedLocateBroker = IF (settled5.marketOrderAcceptedPresenceBits \div 32) % 2 = 1 THEN (IF settled5.marketOrderAcceptedLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled5.marketOrderAcceptedLocateBroker) ELSE << >>]
    IN  settled6

ZeroMarketOrderAcceptedMessage ==
    SettleMarketOrderAcceptedMessage([ marketOrderAcceptedPresenceBits         |-> 0,
                                       transactTime                            |-> [i \in 1 .. 8 |-> 0],
                                       orderId                                 |-> [i \in 1 .. 8 |-> 0],
                                       clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
                                       orderQty                                |-> [i \in 1 .. 4 |-> 0],
                                       marketOrderAcceptedBitFields            |-> [i \in 1 .. 2 |-> 0],
                                       symbolId                                |-> [i \in 1 .. 2 |-> 0],
                                       marketOrderAcceptedSelfMatchScope       |-> << >>,
                                       marketOrderAcceptedSelfMatchInstruction |-> << >>,
                                       marketOrderAcceptedUserData             |-> << >>,
                                       marketOrderAcceptedMpid                 |-> << >>,
                                       marketOrderAcceptedMemberGroup          |-> << >>,
                                       marketOrderAcceptedLocateBroker         |-> << >> ])

(* Market Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOrderAcceptedMessage ==
    { ZeroMarketOrderAcceptedMessage }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.marketOrderAcceptedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.orderQty = one]) : one \in Sample(4) }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.marketOrderAcceptedBitFields = one]) : one \in Sample(2) }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.symbolId = one]) : one \in Sample(2) }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.marketOrderAcceptedPresenceBits = 1, !.marketOrderAcceptedSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.marketOrderAcceptedPresenceBits = 2, !.marketOrderAcceptedSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.marketOrderAcceptedPresenceBits = 4, !.marketOrderAcceptedUserData = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.marketOrderAcceptedPresenceBits = 8, !.marketOrderAcceptedMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.marketOrderAcceptedPresenceBits = 16, !.marketOrderAcceptedMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleMarketOrderAcceptedMessage([ZeroMarketOrderAcceptedMessage EXCEPT !.marketOrderAcceptedPresenceBits = 32, !.marketOrderAcceptedLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Market Order Rejected Message                                           *)
(***************************************************************************)

MarketOrderRejectedMessage ==
    [ marketOrderRejectedPresenceBits         : 0 .. 255,
      transactTime                            : Sample(8),
      clOrdId                                 : Sample(8),
      orderQty                                : Sample(4),
      marketOrderRejectedBitFields            : Sample(2),
      symbolId                                : Sample(2),
      marketOrderRejectedReason               : Sample(1),
      marketOrderRejectedSelfMatchScope       : { << >> } \cup { <<held>> : held \in Sample(1) },
      marketOrderRejectedSelfMatchInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      marketOrderRejectedUserData             : { << >> } \cup { <<held>> : held \in Sample(8) },
      marketOrderRejectedMpid                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      marketOrderRejectedMemberGroup          : { << >> } \cup { <<held>> : held \in Sample(2) },
      marketOrderRejectedLocateBroker         : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeMarketOrderRejectedMessage(message) ==
    EncodeUIntLE(message.marketOrderRejectedPresenceBits, 2)
        \o message.transactTime
        \o message.clOrdId
        \o message.orderQty
        \o message.marketOrderRejectedBitFields
        \o message.symbolId
        \o message.marketOrderRejectedReason
        \o (IF message.marketOrderRejectedSelfMatchScope = << >> THEN << >> ELSE message.marketOrderRejectedSelfMatchScope[1])
        \o (IF message.marketOrderRejectedSelfMatchInstruction = << >> THEN << >> ELSE message.marketOrderRejectedSelfMatchInstruction[1])
        \o (IF message.marketOrderRejectedUserData = << >> THEN << >> ELSE message.marketOrderRejectedUserData[1])
        \o (IF message.marketOrderRejectedMpid = << >> THEN << >> ELSE message.marketOrderRejectedMpid[1])
        \o (IF message.marketOrderRejectedMemberGroup = << >> THEN << >> ELSE message.marketOrderRejectedMemberGroup[1])
        \o (IF message.marketOrderRejectedLocateBroker = << >> THEN << >> ELSE message.marketOrderRejectedLocateBroker[1])

DecodeMarketOrderRejectedMessage(bytes) ==
    LET marketOrderRejectedPresenceBits == ReadUIntLE(bytes, 2) IN IF ~marketOrderRejectedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(marketOrderRejectedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactTime.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketOrderRejectedBitFields == ReadBytes(orderQty.rest, 2) IN IF ~marketOrderRejectedBitFields.ok THEN Fail ELSE
    LET symbolId == ReadBytes(marketOrderRejectedBitFields.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET marketOrderRejectedReason == ReadBytes(symbolId.rest, 1) IN IF ~marketOrderRejectedReason.ok THEN Fail ELSE
    LET marketOrderRejectedSelfMatchScope == ReadWhen(marketOrderRejectedPresenceBits.value % 2 = 1, ReadBytes(marketOrderRejectedReason.rest, 1), marketOrderRejectedReason.rest) IN IF ~marketOrderRejectedSelfMatchScope.ok THEN Fail ELSE
    LET marketOrderRejectedSelfMatchInstruction == ReadWhen((marketOrderRejectedPresenceBits.value \div 2) % 2 = 1, ReadBytes(marketOrderRejectedSelfMatchScope.rest, 1), marketOrderRejectedSelfMatchScope.rest) IN IF ~marketOrderRejectedSelfMatchInstruction.ok THEN Fail ELSE
    LET marketOrderRejectedUserData == ReadWhen((marketOrderRejectedPresenceBits.value \div 4) % 2 = 1, ReadBytes(marketOrderRejectedSelfMatchInstruction.rest, 8), marketOrderRejectedSelfMatchInstruction.rest) IN IF ~marketOrderRejectedUserData.ok THEN Fail ELSE
    LET marketOrderRejectedMpid == ReadWhen((marketOrderRejectedPresenceBits.value \div 8) % 2 = 1, ReadBytes(marketOrderRejectedUserData.rest, 4), marketOrderRejectedUserData.rest) IN IF ~marketOrderRejectedMpid.ok THEN Fail ELSE
    LET marketOrderRejectedMemberGroup == ReadWhen((marketOrderRejectedPresenceBits.value \div 16) % 2 = 1, ReadBytes(marketOrderRejectedMpid.rest, 2), marketOrderRejectedMpid.rest) IN IF ~marketOrderRejectedMemberGroup.ok THEN Fail ELSE
    LET marketOrderRejectedLocateBroker == ReadWhen((marketOrderRejectedPresenceBits.value \div 32) % 2 = 1, ReadBytes(marketOrderRejectedMemberGroup.rest, 4), marketOrderRejectedMemberGroup.rest) IN IF ~marketOrderRejectedLocateBroker.ok THEN Fail ELSE
    Ok([ marketOrderRejectedPresenceBits         |-> marketOrderRejectedPresenceBits.value,
         transactTime                            |-> transactTime.value,
         clOrdId                                 |-> clOrdId.value,
         orderQty                                |-> orderQty.value,
         marketOrderRejectedBitFields            |-> marketOrderRejectedBitFields.value,
         symbolId                                |-> symbolId.value,
         marketOrderRejectedReason               |-> marketOrderRejectedReason.value,
         marketOrderRejectedSelfMatchScope       |-> marketOrderRejectedSelfMatchScope.value,
         marketOrderRejectedSelfMatchInstruction |-> marketOrderRejectedSelfMatchInstruction.value,
         marketOrderRejectedUserData             |-> marketOrderRejectedUserData.value,
         marketOrderRejectedMpid                 |-> marketOrderRejectedMpid.value,
         marketOrderRejectedMemberGroup          |-> marketOrderRejectedMemberGroup.value,
         marketOrderRejectedLocateBroker         |-> marketOrderRejectedLocateBroker.value ], marketOrderRejectedLocateBroker.rest)

(* Market Order Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleMarketOrderRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.marketOrderRejectedSelfMatchScope = IF message.marketOrderRejectedPresenceBits % 2 = 1 THEN (IF message.marketOrderRejectedSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.marketOrderRejectedSelfMatchScope) ELSE << >>]
        settled2 == [settled1 EXCEPT !.marketOrderRejectedSelfMatchInstruction = IF (settled1.marketOrderRejectedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.marketOrderRejectedSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.marketOrderRejectedSelfMatchInstruction) ELSE << >>]
        settled3 == [settled2 EXCEPT !.marketOrderRejectedUserData = IF (settled2.marketOrderRejectedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.marketOrderRejectedUserData = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled2.marketOrderRejectedUserData) ELSE << >>]
        settled4 == [settled3 EXCEPT !.marketOrderRejectedMpid = IF (settled3.marketOrderRejectedPresenceBits \div 8) % 2 = 1 THEN (IF settled3.marketOrderRejectedMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.marketOrderRejectedMpid) ELSE << >>]
        settled5 == [settled4 EXCEPT !.marketOrderRejectedMemberGroup = IF (settled4.marketOrderRejectedPresenceBits \div 16) % 2 = 1 THEN (IF settled4.marketOrderRejectedMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled4.marketOrderRejectedMemberGroup) ELSE << >>]
        settled6 == [settled5 EXCEPT !.marketOrderRejectedLocateBroker = IF (settled5.marketOrderRejectedPresenceBits \div 32) % 2 = 1 THEN (IF settled5.marketOrderRejectedLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled5.marketOrderRejectedLocateBroker) ELSE << >>]
    IN  settled6

ZeroMarketOrderRejectedMessage ==
    SettleMarketOrderRejectedMessage([ marketOrderRejectedPresenceBits         |-> 0,
                                       transactTime                            |-> [i \in 1 .. 8 |-> 0],
                                       clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
                                       orderQty                                |-> [i \in 1 .. 4 |-> 0],
                                       marketOrderRejectedBitFields            |-> [i \in 1 .. 2 |-> 0],
                                       symbolId                                |-> [i \in 1 .. 2 |-> 0],
                                       marketOrderRejectedReason               |-> [i \in 1 .. 1 |-> 0],
                                       marketOrderRejectedSelfMatchScope       |-> << >>,
                                       marketOrderRejectedSelfMatchInstruction |-> << >>,
                                       marketOrderRejectedUserData             |-> << >>,
                                       marketOrderRejectedMpid                 |-> << >>,
                                       marketOrderRejectedMemberGroup          |-> << >>,
                                       marketOrderRejectedLocateBroker         |-> << >> ])

(* Market Order Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOrderRejectedMessage ==
    { ZeroMarketOrderRejectedMessage }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.orderQty = one]) : one \in Sample(4) }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedBitFields = one]) : one \in Sample(2) }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.symbolId = one]) : one \in Sample(2) }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedReason = one]) : one \in Sample(1) }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedPresenceBits = 1, !.marketOrderRejectedSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedPresenceBits = 2, !.marketOrderRejectedSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedPresenceBits = 4, !.marketOrderRejectedUserData = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedPresenceBits = 8, !.marketOrderRejectedMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedPresenceBits = 16, !.marketOrderRejectedMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleMarketOrderRejectedMessage([ZeroMarketOrderRejectedMessage EXCEPT !.marketOrderRejectedPresenceBits = 32, !.marketOrderRejectedLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Order Canceled Message: 25 bytes                                        *)
(***************************************************************************)

OrderCanceledMessage ==
    [ transactTime : Sample(8),
      orderId      : Sample(8),
      origClOrdId  : Sample(8),
      cancelReason : Sample(1) ]

EncodeOrderCanceledMessage(message) ==
    message.transactTime
        \o message.orderId
        \o message.origClOrdId
        \o message.cancelReason

DecodeOrderCanceledMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(origClOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         orderId      |-> orderId.value,
         origClOrdId  |-> origClOrdId.value,
         cancelReason |-> cancelReason.value ], cancelReason.rest)

ZeroOrderCanceledMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      origClOrdId  |-> [i \in 1 .. 8 |-> 0],
      cancelReason |-> [i \in 1 .. 1 |-> 0] ]

(* Order Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCanceledMessage ==
    { ZeroOrderCanceledMessage }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Rejected Message: 17 bytes                                       *)
(***************************************************************************)

CancelRejectedMessage ==
    [ transactTime         : Sample(8),
      origClOrdId          : Sample(8),
      cancelRejectedReason : Sample(1) ]

EncodeCancelRejectedMessage(message) ==
    message.transactTime
        \o message.origClOrdId
        \o message.cancelRejectedReason

DecodeCancelRejectedMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(transactTime.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET cancelRejectedReason == ReadBytes(origClOrdId.rest, 1) IN IF ~cancelRejectedReason.ok THEN Fail ELSE
    Ok([ transactTime         |-> transactTime.value,
         origClOrdId          |-> origClOrdId.value,
         cancelRejectedReason |-> cancelRejectedReason.value ], cancelRejectedReason.rest)

ZeroCancelRejectedMessage ==
    [ transactTime         |-> [i \in 1 .. 8 |-> 0],
      origClOrdId          |-> [i \in 1 .. 8 |-> 0],
      cancelRejectedReason |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedMessage ==
    { ZeroCancelRejectedMessage }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.cancelRejectedReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Modified Message                                                  *)
(***************************************************************************)

OrderModifiedMessage ==
    [ orderModifiedPresenceBits : 0 .. 255,
      transactTime              : Sample(8),
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      leavesQty                 : Sample(4),
      orderModifiedOrderQty     : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderModifiedBitFields    : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderModifiedLocateBroker : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeOrderModifiedMessage(message) ==
    EncodeUIntLE(message.orderModifiedPresenceBits, 1)
        \o message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.leavesQty
        \o (IF message.orderModifiedOrderQty = << >> THEN << >> ELSE message.orderModifiedOrderQty[1])
        \o (IF message.orderModifiedBitFields = << >> THEN << >> ELSE message.orderModifiedBitFields[1])
        \o (IF message.orderModifiedLocateBroker = << >> THEN << >> ELSE message.orderModifiedLocateBroker[1])

DecodeOrderModifiedMessage(bytes) ==
    LET orderModifiedPresenceBits == ReadUIntLE(bytes, 1) IN IF ~orderModifiedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(orderModifiedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(origClOrdId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET orderModifiedOrderQty == ReadWhen(orderModifiedPresenceBits.value % 2 = 1, ReadBytes(leavesQty.rest, 4), leavesQty.rest) IN IF ~orderModifiedOrderQty.ok THEN Fail ELSE
    LET orderModifiedBitFields == ReadWhen((orderModifiedPresenceBits.value \div 2) % 2 = 1, ReadBytes(orderModifiedOrderQty.rest, 1), orderModifiedOrderQty.rest) IN IF ~orderModifiedBitFields.ok THEN Fail ELSE
    LET orderModifiedLocateBroker == ReadWhen((orderModifiedPresenceBits.value \div 4) % 2 = 1, ReadBytes(orderModifiedBitFields.rest, 4), orderModifiedBitFields.rest) IN IF ~orderModifiedLocateBroker.ok THEN Fail ELSE
    Ok([ orderModifiedPresenceBits |-> orderModifiedPresenceBits.value,
         transactTime              |-> transactTime.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         leavesQty                 |-> leavesQty.value,
         orderModifiedOrderQty     |-> orderModifiedOrderQty.value,
         orderModifiedBitFields    |-> orderModifiedBitFields.value,
         orderModifiedLocateBroker |-> orderModifiedLocateBroker.value ], orderModifiedLocateBroker.rest)

(* Order Modified Message with each field marked present by fields before it there exactly where they say *)
SettleOrderModifiedMessage(message) ==
    LET settled1 == [message EXCEPT !.orderModifiedOrderQty = IF message.orderModifiedPresenceBits % 2 = 1 THEN (IF message.orderModifiedOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE message.orderModifiedOrderQty) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderModifiedBitFields = IF (settled1.orderModifiedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.orderModifiedBitFields = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.orderModifiedBitFields) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderModifiedLocateBroker = IF (settled2.orderModifiedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.orderModifiedLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.orderModifiedLocateBroker) ELSE << >>]
    IN  settled3

ZeroOrderModifiedMessage ==
    SettleOrderModifiedMessage([ orderModifiedPresenceBits |-> 0,
                                 transactTime              |-> [i \in 1 .. 8 |-> 0],
                                 orderId                   |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                   |-> [i \in 1 .. 8 |-> 0],
                                 origClOrdId               |-> [i \in 1 .. 8 |-> 0],
                                 leavesQty                 |-> [i \in 1 .. 4 |-> 0],
                                 orderModifiedOrderQty     |-> << >>,
                                 orderModifiedBitFields    |-> << >>,
                                 orderModifiedLocateBroker |-> << >> ])

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.orderModifiedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.origClOrdId = one]) : one \in Sample(8) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.leavesQty = one]) : one \in Sample(4) }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.orderModifiedPresenceBits = 1, !.orderModifiedOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.orderModifiedPresenceBits = 2, !.orderModifiedBitFields = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderModifiedMessage([ZeroOrderModifiedMessage EXCEPT !.orderModifiedPresenceBits = 4, !.orderModifiedLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Modify Rejected Message                                                 *)
(***************************************************************************)

ModifyRejectedMessage ==
    [ modifyRejectedPresenceBits : 0 .. 255,
      transactTime               : Sample(8),
      clOrdId                    : Sample(8),
      origClOrdId                : Sample(8),
      modifyRejectedReason       : Sample(1),
      modifyRejectedOrderQty     : { << >> } \cup { <<held>> : held \in Sample(4) },
      modifyRejectedBitFields    : { << >> } \cup { <<held>> : held \in Sample(1) },
      modifyRejectedLocateBroker : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeModifyRejectedMessage(message) ==
    EncodeUIntLE(message.modifyRejectedPresenceBits, 1)
        \o message.transactTime
        \o message.clOrdId
        \o message.origClOrdId
        \o message.modifyRejectedReason
        \o (IF message.modifyRejectedOrderQty = << >> THEN << >> ELSE message.modifyRejectedOrderQty[1])
        \o (IF message.modifyRejectedBitFields = << >> THEN << >> ELSE message.modifyRejectedBitFields[1])
        \o (IF message.modifyRejectedLocateBroker = << >> THEN << >> ELSE message.modifyRejectedLocateBroker[1])

DecodeModifyRejectedMessage(bytes) ==
    LET modifyRejectedPresenceBits == ReadUIntLE(bytes, 1) IN IF ~modifyRejectedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(modifyRejectedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactTime.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET modifyRejectedReason == ReadBytes(origClOrdId.rest, 1) IN IF ~modifyRejectedReason.ok THEN Fail ELSE
    LET modifyRejectedOrderQty == ReadWhen(modifyRejectedPresenceBits.value % 2 = 1, ReadBytes(modifyRejectedReason.rest, 4), modifyRejectedReason.rest) IN IF ~modifyRejectedOrderQty.ok THEN Fail ELSE
    LET modifyRejectedBitFields == ReadWhen((modifyRejectedPresenceBits.value \div 2) % 2 = 1, ReadBytes(modifyRejectedOrderQty.rest, 1), modifyRejectedOrderQty.rest) IN IF ~modifyRejectedBitFields.ok THEN Fail ELSE
    LET modifyRejectedLocateBroker == ReadWhen((modifyRejectedPresenceBits.value \div 4) % 2 = 1, ReadBytes(modifyRejectedBitFields.rest, 4), modifyRejectedBitFields.rest) IN IF ~modifyRejectedLocateBroker.ok THEN Fail ELSE
    Ok([ modifyRejectedPresenceBits |-> modifyRejectedPresenceBits.value,
         transactTime               |-> transactTime.value,
         clOrdId                    |-> clOrdId.value,
         origClOrdId                |-> origClOrdId.value,
         modifyRejectedReason       |-> modifyRejectedReason.value,
         modifyRejectedOrderQty     |-> modifyRejectedOrderQty.value,
         modifyRejectedBitFields    |-> modifyRejectedBitFields.value,
         modifyRejectedLocateBroker |-> modifyRejectedLocateBroker.value ], modifyRejectedLocateBroker.rest)

(* Modify Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleModifyRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.modifyRejectedOrderQty = IF message.modifyRejectedPresenceBits % 2 = 1 THEN (IF message.modifyRejectedOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE message.modifyRejectedOrderQty) ELSE << >>]
        settled2 == [settled1 EXCEPT !.modifyRejectedBitFields = IF (settled1.modifyRejectedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.modifyRejectedBitFields = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.modifyRejectedBitFields) ELSE << >>]
        settled3 == [settled2 EXCEPT !.modifyRejectedLocateBroker = IF (settled2.modifyRejectedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.modifyRejectedLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.modifyRejectedLocateBroker) ELSE << >>]
    IN  settled3

ZeroModifyRejectedMessage ==
    SettleModifyRejectedMessage([ modifyRejectedPresenceBits |-> 0,
                                  transactTime               |-> [i \in 1 .. 8 |-> 0],
                                  clOrdId                    |-> [i \in 1 .. 8 |-> 0],
                                  origClOrdId                |-> [i \in 1 .. 8 |-> 0],
                                  modifyRejectedReason       |-> [i \in 1 .. 1 |-> 0],
                                  modifyRejectedOrderQty     |-> << >>,
                                  modifyRejectedBitFields    |-> << >>,
                                  modifyRejectedLocateBroker |-> << >> ])

(* Modify Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyRejectedMessage ==
    { ZeroModifyRejectedMessage }
        \cup { SettleModifyRejectedMessage([ZeroModifyRejectedMessage EXCEPT !.modifyRejectedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleModifyRejectedMessage([ZeroModifyRejectedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleModifyRejectedMessage([ZeroModifyRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleModifyRejectedMessage([ZeroModifyRejectedMessage EXCEPT !.origClOrdId = one]) : one \in Sample(8) }
        \cup { SettleModifyRejectedMessage([ZeroModifyRejectedMessage EXCEPT !.modifyRejectedReason = one]) : one \in Sample(1) }
        \cup { SettleModifyRejectedMessage([ZeroModifyRejectedMessage EXCEPT !.modifyRejectedPresenceBits = 1, !.modifyRejectedOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyRejectedMessage([ZeroModifyRejectedMessage EXCEPT !.modifyRejectedPresenceBits = 2, !.modifyRejectedBitFields = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyRejectedMessage([ZeroModifyRejectedMessage EXCEPT !.modifyRejectedPresenceBits = 4, !.modifyRejectedLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Order Replaced Message                                                  *)
(***************************************************************************)

OrderReplacedMessage ==
    [ orderReplacedPresenceBits          : 0 .. 255,
      transactTime                       : Sample(8),
      orderId                            : Sample(8),
      clOrdId                            : Sample(8),
      origClOrdId                        : Sample(8),
      orderReplacedBitFields             : Sample(2),
      leavesQty                          : Sample(4),
      orderReplacedPrice                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      orderReplacedOrderQty              : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderReplacedMaxFloorQty           : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderReplacedSelfMatchScope        : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderReplacedSelfMatchInstruction  : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderReplacedPriceSlideInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      orderReplacedReferencePriceTarget  : { << >> } \cup { <<held>> : held \in Sample(2) },
      orderReplacedLocateBroker          : { << >> } \cup { <<held>> : held \in Sample(4) },
      orderReplacedRankPrice             : { << >> } \cup { <<held>> : held \in Sample(8) },
      orderReplacedDisplayPrice          : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeOrderReplacedMessage(message) ==
    EncodeUIntLE(message.orderReplacedPresenceBits, 2)
        \o message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.orderReplacedBitFields
        \o message.leavesQty
        \o (IF message.orderReplacedPrice = << >> THEN << >> ELSE message.orderReplacedPrice[1])
        \o (IF message.orderReplacedOrderQty = << >> THEN << >> ELSE message.orderReplacedOrderQty[1])
        \o (IF message.orderReplacedMaxFloorQty = << >> THEN << >> ELSE message.orderReplacedMaxFloorQty[1])
        \o (IF message.orderReplacedSelfMatchScope = << >> THEN << >> ELSE message.orderReplacedSelfMatchScope[1])
        \o (IF message.orderReplacedSelfMatchInstruction = << >> THEN << >> ELSE message.orderReplacedSelfMatchInstruction[1])
        \o (IF message.orderReplacedPriceSlideInstruction = << >> THEN << >> ELSE message.orderReplacedPriceSlideInstruction[1])
        \o (IF message.orderReplacedReferencePriceTarget = << >> THEN << >> ELSE message.orderReplacedReferencePriceTarget[1])
        \o (IF message.orderReplacedLocateBroker = << >> THEN << >> ELSE message.orderReplacedLocateBroker[1])
        \o (IF message.orderReplacedRankPrice = << >> THEN << >> ELSE message.orderReplacedRankPrice[1])
        \o (IF message.orderReplacedDisplayPrice = << >> THEN << >> ELSE message.orderReplacedDisplayPrice[1])

DecodeOrderReplacedMessage(bytes) ==
    LET orderReplacedPresenceBits == ReadUIntLE(bytes, 2) IN IF ~orderReplacedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(orderReplacedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET orderReplacedBitFields == ReadBytes(origClOrdId.rest, 2) IN IF ~orderReplacedBitFields.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderReplacedBitFields.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET orderReplacedPrice == ReadWhen(orderReplacedPresenceBits.value % 2 = 1, ReadBytes(leavesQty.rest, 8), leavesQty.rest) IN IF ~orderReplacedPrice.ok THEN Fail ELSE
    LET orderReplacedOrderQty == ReadWhen((orderReplacedPresenceBits.value \div 2) % 2 = 1, ReadBytes(orderReplacedPrice.rest, 4), orderReplacedPrice.rest) IN IF ~orderReplacedOrderQty.ok THEN Fail ELSE
    LET orderReplacedMaxFloorQty == ReadWhen((orderReplacedPresenceBits.value \div 4) % 2 = 1, ReadBytes(orderReplacedOrderQty.rest, 4), orderReplacedOrderQty.rest) IN IF ~orderReplacedMaxFloorQty.ok THEN Fail ELSE
    LET orderReplacedSelfMatchScope == ReadWhen((orderReplacedPresenceBits.value \div 8) % 2 = 1, ReadBytes(orderReplacedMaxFloorQty.rest, 1), orderReplacedMaxFloorQty.rest) IN IF ~orderReplacedSelfMatchScope.ok THEN Fail ELSE
    LET orderReplacedSelfMatchInstruction == ReadWhen((orderReplacedPresenceBits.value \div 16) % 2 = 1, ReadBytes(orderReplacedSelfMatchScope.rest, 1), orderReplacedSelfMatchScope.rest) IN IF ~orderReplacedSelfMatchInstruction.ok THEN Fail ELSE
    LET orderReplacedPriceSlideInstruction == ReadWhen((orderReplacedPresenceBits.value \div 32) % 2 = 1, ReadBytes(orderReplacedSelfMatchInstruction.rest, 1), orderReplacedSelfMatchInstruction.rest) IN IF ~orderReplacedPriceSlideInstruction.ok THEN Fail ELSE
    LET orderReplacedReferencePriceTarget == ReadWhen((orderReplacedPresenceBits.value \div 64) % 2 = 1, ReadBytes(orderReplacedPriceSlideInstruction.rest, 2), orderReplacedPriceSlideInstruction.rest) IN IF ~orderReplacedReferencePriceTarget.ok THEN Fail ELSE
    LET orderReplacedLocateBroker == ReadWhen((orderReplacedPresenceBits.value \div 128) % 2 = 1, ReadBytes(orderReplacedReferencePriceTarget.rest, 4), orderReplacedReferencePriceTarget.rest) IN IF ~orderReplacedLocateBroker.ok THEN Fail ELSE
    LET orderReplacedRankPrice == ReadWhen((orderReplacedPresenceBits.value \div 256) % 2 = 1, ReadBytes(orderReplacedLocateBroker.rest, 8), orderReplacedLocateBroker.rest) IN IF ~orderReplacedRankPrice.ok THEN Fail ELSE
    LET orderReplacedDisplayPrice == ReadWhen((orderReplacedPresenceBits.value \div 512) % 2 = 1, ReadBytes(orderReplacedRankPrice.rest, 8), orderReplacedRankPrice.rest) IN IF ~orderReplacedDisplayPrice.ok THEN Fail ELSE
    Ok([ orderReplacedPresenceBits          |-> orderReplacedPresenceBits.value,
         transactTime                       |-> transactTime.value,
         orderId                            |-> orderId.value,
         clOrdId                            |-> clOrdId.value,
         origClOrdId                        |-> origClOrdId.value,
         orderReplacedBitFields             |-> orderReplacedBitFields.value,
         leavesQty                          |-> leavesQty.value,
         orderReplacedPrice                 |-> orderReplacedPrice.value,
         orderReplacedOrderQty              |-> orderReplacedOrderQty.value,
         orderReplacedMaxFloorQty           |-> orderReplacedMaxFloorQty.value,
         orderReplacedSelfMatchScope        |-> orderReplacedSelfMatchScope.value,
         orderReplacedSelfMatchInstruction  |-> orderReplacedSelfMatchInstruction.value,
         orderReplacedPriceSlideInstruction |-> orderReplacedPriceSlideInstruction.value,
         orderReplacedReferencePriceTarget  |-> orderReplacedReferencePriceTarget.value,
         orderReplacedLocateBroker          |-> orderReplacedLocateBroker.value,
         orderReplacedRankPrice             |-> orderReplacedRankPrice.value,
         orderReplacedDisplayPrice          |-> orderReplacedDisplayPrice.value ], orderReplacedDisplayPrice.rest)

(* Order Replaced Message with each field marked present by fields before it there exactly where they say *)
SettleOrderReplacedMessage(message) ==
    LET settled1 == [message EXCEPT !.orderReplacedPrice = IF message.orderReplacedPresenceBits % 2 = 1 THEN (IF message.orderReplacedPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE message.orderReplacedPrice) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderReplacedOrderQty = IF (settled1.orderReplacedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.orderReplacedOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled1.orderReplacedOrderQty) ELSE << >>]
        settled3 == [settled2 EXCEPT !.orderReplacedMaxFloorQty = IF (settled2.orderReplacedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.orderReplacedMaxFloorQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.orderReplacedMaxFloorQty) ELSE << >>]
        settled4 == [settled3 EXCEPT !.orderReplacedSelfMatchScope = IF (settled3.orderReplacedPresenceBits \div 8) % 2 = 1 THEN (IF settled3.orderReplacedSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.orderReplacedSelfMatchScope) ELSE << >>]
        settled5 == [settled4 EXCEPT !.orderReplacedSelfMatchInstruction = IF (settled4.orderReplacedPresenceBits \div 16) % 2 = 1 THEN (IF settled4.orderReplacedSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.orderReplacedSelfMatchInstruction) ELSE << >>]
        settled6 == [settled5 EXCEPT !.orderReplacedPriceSlideInstruction = IF (settled5.orderReplacedPresenceBits \div 32) % 2 = 1 THEN (IF settled5.orderReplacedPriceSlideInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.orderReplacedPriceSlideInstruction) ELSE << >>]
        settled7 == [settled6 EXCEPT !.orderReplacedReferencePriceTarget = IF (settled6.orderReplacedPresenceBits \div 64) % 2 = 1 THEN (IF settled6.orderReplacedReferencePriceTarget = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled6.orderReplacedReferencePriceTarget) ELSE << >>]
        settled8 == [settled7 EXCEPT !.orderReplacedLocateBroker = IF (settled7.orderReplacedPresenceBits \div 128) % 2 = 1 THEN (IF settled7.orderReplacedLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled7.orderReplacedLocateBroker) ELSE << >>]
        settled9 == [settled8 EXCEPT !.orderReplacedRankPrice = IF (settled8.orderReplacedPresenceBits \div 256) % 2 = 1 THEN (IF settled8.orderReplacedRankPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled8.orderReplacedRankPrice) ELSE << >>]
        settled10 == [settled9 EXCEPT !.orderReplacedDisplayPrice = IF (settled9.orderReplacedPresenceBits \div 512) % 2 = 1 THEN (IF settled9.orderReplacedDisplayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled9.orderReplacedDisplayPrice) ELSE << >>]
    IN  settled10

ZeroOrderReplacedMessage ==
    SettleOrderReplacedMessage([ orderReplacedPresenceBits          |-> 0,
                                 transactTime                       |-> [i \in 1 .. 8 |-> 0],
                                 orderId                            |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                            |-> [i \in 1 .. 8 |-> 0],
                                 origClOrdId                        |-> [i \in 1 .. 8 |-> 0],
                                 orderReplacedBitFields             |-> [i \in 1 .. 2 |-> 0],
                                 leavesQty                          |-> [i \in 1 .. 4 |-> 0],
                                 orderReplacedPrice                 |-> << >>,
                                 orderReplacedOrderQty              |-> << >>,
                                 orderReplacedMaxFloorQty           |-> << >>,
                                 orderReplacedSelfMatchScope        |-> << >>,
                                 orderReplacedSelfMatchInstruction  |-> << >>,
                                 orderReplacedPriceSlideInstruction |-> << >>,
                                 orderReplacedReferencePriceTarget  |-> << >>,
                                 orderReplacedLocateBroker          |-> << >>,
                                 orderReplacedRankPrice             |-> << >>,
                                 orderReplacedDisplayPrice          |-> << >> ])

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.origClOrdId = one]) : one \in Sample(8) }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedBitFields = one]) : one \in Sample(2) }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.leavesQty = one]) : one \in Sample(4) }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 1, !.orderReplacedPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 2, !.orderReplacedOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 4, !.orderReplacedMaxFloorQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 8, !.orderReplacedSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 16, !.orderReplacedSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 32, !.orderReplacedPriceSlideInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 64, !.orderReplacedReferencePriceTarget = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 128, !.orderReplacedLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 256, !.orderReplacedRankPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderReplacedMessage([ZeroOrderReplacedMessage EXCEPT !.orderReplacedPresenceBits = 512, !.orderReplacedDisplayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Replace Rejected Message                                                *)
(***************************************************************************)

ReplaceRejectedMessage ==
    [ replaceRejectedPresenceBits          : 0 .. 255,
      transactTime                         : Sample(8),
      clOrdId                              : Sample(8),
      origClOrdId                          : Sample(8),
      replaceRejectedBitFields             : Sample(2),
      replaceRejectedReason                : Sample(1),
      replaceRejectedPrice                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      replaceRejectedOrderQty              : { << >> } \cup { <<held>> : held \in Sample(4) },
      replaceRejectedMaxFloorQty           : { << >> } \cup { <<held>> : held \in Sample(4) },
      replaceRejectedSelfMatchScope        : { << >> } \cup { <<held>> : held \in Sample(1) },
      replaceRejectedSelfMatchInstruction  : { << >> } \cup { <<held>> : held \in Sample(1) },
      replaceRejectedPriceSlideInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      replaceRejectedReferencePriceTarget  : { << >> } \cup { <<held>> : held \in Sample(2) },
      replaceRejectedLocateBroker          : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeReplaceRejectedMessage(message) ==
    EncodeUIntLE(message.replaceRejectedPresenceBits, 2)
        \o message.transactTime
        \o message.clOrdId
        \o message.origClOrdId
        \o message.replaceRejectedBitFields
        \o message.replaceRejectedReason
        \o (IF message.replaceRejectedPrice = << >> THEN << >> ELSE message.replaceRejectedPrice[1])
        \o (IF message.replaceRejectedOrderQty = << >> THEN << >> ELSE message.replaceRejectedOrderQty[1])
        \o (IF message.replaceRejectedMaxFloorQty = << >> THEN << >> ELSE message.replaceRejectedMaxFloorQty[1])
        \o (IF message.replaceRejectedSelfMatchScope = << >> THEN << >> ELSE message.replaceRejectedSelfMatchScope[1])
        \o (IF message.replaceRejectedSelfMatchInstruction = << >> THEN << >> ELSE message.replaceRejectedSelfMatchInstruction[1])
        \o (IF message.replaceRejectedPriceSlideInstruction = << >> THEN << >> ELSE message.replaceRejectedPriceSlideInstruction[1])
        \o (IF message.replaceRejectedReferencePriceTarget = << >> THEN << >> ELSE message.replaceRejectedReferencePriceTarget[1])
        \o (IF message.replaceRejectedLocateBroker = << >> THEN << >> ELSE message.replaceRejectedLocateBroker[1])

DecodeReplaceRejectedMessage(bytes) ==
    LET replaceRejectedPresenceBits == ReadUIntLE(bytes, 2) IN IF ~replaceRejectedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(replaceRejectedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(transactTime.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET replaceRejectedBitFields == ReadBytes(origClOrdId.rest, 2) IN IF ~replaceRejectedBitFields.ok THEN Fail ELSE
    LET replaceRejectedReason == ReadBytes(replaceRejectedBitFields.rest, 1) IN IF ~replaceRejectedReason.ok THEN Fail ELSE
    LET replaceRejectedPrice == ReadWhen(replaceRejectedPresenceBits.value % 2 = 1, ReadBytes(replaceRejectedReason.rest, 8), replaceRejectedReason.rest) IN IF ~replaceRejectedPrice.ok THEN Fail ELSE
    LET replaceRejectedOrderQty == ReadWhen((replaceRejectedPresenceBits.value \div 2) % 2 = 1, ReadBytes(replaceRejectedPrice.rest, 4), replaceRejectedPrice.rest) IN IF ~replaceRejectedOrderQty.ok THEN Fail ELSE
    LET replaceRejectedMaxFloorQty == ReadWhen((replaceRejectedPresenceBits.value \div 4) % 2 = 1, ReadBytes(replaceRejectedOrderQty.rest, 4), replaceRejectedOrderQty.rest) IN IF ~replaceRejectedMaxFloorQty.ok THEN Fail ELSE
    LET replaceRejectedSelfMatchScope == ReadWhen((replaceRejectedPresenceBits.value \div 8) % 2 = 1, ReadBytes(replaceRejectedMaxFloorQty.rest, 1), replaceRejectedMaxFloorQty.rest) IN IF ~replaceRejectedSelfMatchScope.ok THEN Fail ELSE
    LET replaceRejectedSelfMatchInstruction == ReadWhen((replaceRejectedPresenceBits.value \div 16) % 2 = 1, ReadBytes(replaceRejectedSelfMatchScope.rest, 1), replaceRejectedSelfMatchScope.rest) IN IF ~replaceRejectedSelfMatchInstruction.ok THEN Fail ELSE
    LET replaceRejectedPriceSlideInstruction == ReadWhen((replaceRejectedPresenceBits.value \div 32) % 2 = 1, ReadBytes(replaceRejectedSelfMatchInstruction.rest, 1), replaceRejectedSelfMatchInstruction.rest) IN IF ~replaceRejectedPriceSlideInstruction.ok THEN Fail ELSE
    LET replaceRejectedReferencePriceTarget == ReadWhen((replaceRejectedPresenceBits.value \div 64) % 2 = 1, ReadBytes(replaceRejectedPriceSlideInstruction.rest, 2), replaceRejectedPriceSlideInstruction.rest) IN IF ~replaceRejectedReferencePriceTarget.ok THEN Fail ELSE
    LET replaceRejectedLocateBroker == ReadWhen((replaceRejectedPresenceBits.value \div 128) % 2 = 1, ReadBytes(replaceRejectedReferencePriceTarget.rest, 4), replaceRejectedReferencePriceTarget.rest) IN IF ~replaceRejectedLocateBroker.ok THEN Fail ELSE
    Ok([ replaceRejectedPresenceBits          |-> replaceRejectedPresenceBits.value,
         transactTime                         |-> transactTime.value,
         clOrdId                              |-> clOrdId.value,
         origClOrdId                          |-> origClOrdId.value,
         replaceRejectedBitFields             |-> replaceRejectedBitFields.value,
         replaceRejectedReason                |-> replaceRejectedReason.value,
         replaceRejectedPrice                 |-> replaceRejectedPrice.value,
         replaceRejectedOrderQty              |-> replaceRejectedOrderQty.value,
         replaceRejectedMaxFloorQty           |-> replaceRejectedMaxFloorQty.value,
         replaceRejectedSelfMatchScope        |-> replaceRejectedSelfMatchScope.value,
         replaceRejectedSelfMatchInstruction  |-> replaceRejectedSelfMatchInstruction.value,
         replaceRejectedPriceSlideInstruction |-> replaceRejectedPriceSlideInstruction.value,
         replaceRejectedReferencePriceTarget  |-> replaceRejectedReferencePriceTarget.value,
         replaceRejectedLocateBroker          |-> replaceRejectedLocateBroker.value ], replaceRejectedLocateBroker.rest)

(* Replace Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleReplaceRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.replaceRejectedPrice = IF message.replaceRejectedPresenceBits % 2 = 1 THEN (IF message.replaceRejectedPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE message.replaceRejectedPrice) ELSE << >>]
        settled2 == [settled1 EXCEPT !.replaceRejectedOrderQty = IF (settled1.replaceRejectedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.replaceRejectedOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled1.replaceRejectedOrderQty) ELSE << >>]
        settled3 == [settled2 EXCEPT !.replaceRejectedMaxFloorQty = IF (settled2.replaceRejectedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.replaceRejectedMaxFloorQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.replaceRejectedMaxFloorQty) ELSE << >>]
        settled4 == [settled3 EXCEPT !.replaceRejectedSelfMatchScope = IF (settled3.replaceRejectedPresenceBits \div 8) % 2 = 1 THEN (IF settled3.replaceRejectedSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.replaceRejectedSelfMatchScope) ELSE << >>]
        settled5 == [settled4 EXCEPT !.replaceRejectedSelfMatchInstruction = IF (settled4.replaceRejectedPresenceBits \div 16) % 2 = 1 THEN (IF settled4.replaceRejectedSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.replaceRejectedSelfMatchInstruction) ELSE << >>]
        settled6 == [settled5 EXCEPT !.replaceRejectedPriceSlideInstruction = IF (settled5.replaceRejectedPresenceBits \div 32) % 2 = 1 THEN (IF settled5.replaceRejectedPriceSlideInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.replaceRejectedPriceSlideInstruction) ELSE << >>]
        settled7 == [settled6 EXCEPT !.replaceRejectedReferencePriceTarget = IF (settled6.replaceRejectedPresenceBits \div 64) % 2 = 1 THEN (IF settled6.replaceRejectedReferencePriceTarget = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled6.replaceRejectedReferencePriceTarget) ELSE << >>]
        settled8 == [settled7 EXCEPT !.replaceRejectedLocateBroker = IF (settled7.replaceRejectedPresenceBits \div 128) % 2 = 1 THEN (IF settled7.replaceRejectedLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled7.replaceRejectedLocateBroker) ELSE << >>]
    IN  settled8

ZeroReplaceRejectedMessage ==
    SettleReplaceRejectedMessage([ replaceRejectedPresenceBits          |-> 0,
                                   transactTime                         |-> [i \in 1 .. 8 |-> 0],
                                   clOrdId                              |-> [i \in 1 .. 8 |-> 0],
                                   origClOrdId                          |-> [i \in 1 .. 8 |-> 0],
                                   replaceRejectedBitFields             |-> [i \in 1 .. 2 |-> 0],
                                   replaceRejectedReason                |-> [i \in 1 .. 1 |-> 0],
                                   replaceRejectedPrice                 |-> << >>,
                                   replaceRejectedOrderQty              |-> << >>,
                                   replaceRejectedMaxFloorQty           |-> << >>,
                                   replaceRejectedSelfMatchScope        |-> << >>,
                                   replaceRejectedSelfMatchInstruction  |-> << >>,
                                   replaceRejectedPriceSlideInstruction |-> << >>,
                                   replaceRejectedReferencePriceTarget  |-> << >>,
                                   replaceRejectedLocateBroker          |-> << >> ])

(* Replace Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceRejectedMessage ==
    { ZeroReplaceRejectedMessage }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.origClOrdId = one]) : one \in Sample(8) }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedBitFields = one]) : one \in Sample(2) }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedReason = one]) : one \in Sample(1) }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = 1, !.replaceRejectedPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = 2, !.replaceRejectedOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = 4, !.replaceRejectedMaxFloorQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = 8, !.replaceRejectedSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = 16, !.replaceRejectedSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = 32, !.replaceRejectedPriceSlideInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = 64, !.replaceRejectedReferencePriceTarget = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleReplaceRejectedMessage([ZeroReplaceRejectedMessage EXCEPT !.replaceRejectedPresenceBits = 128, !.replaceRejectedLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Order Executed Message: 1 bytes                                         *)
(***************************************************************************)

OrderExecutedMessageTail ==
    [ liquidityIndicator : Sample(1) ]

EncodeOrderExecutedMessageTail(message) ==
    message.liquidityIndicator

DecodeOrderExecutedMessageTail(bytes) ==
    LET liquidityIndicator == ReadBytes(bytes, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    Ok([ liquidityIndicator |-> liquidityIndicator.value ], liquidityIndicator.rest)

ZeroOrderExecutedMessageTail ==
    [ liquidityIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessageTail ==
    { ZeroOrderExecutedMessageTail }
        \cup { [ZeroOrderExecutedMessageTail EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }

(* Order Executed Message runs on only when bytes remain, so it is there or it is not *)
WithoutOrderExecutedMessageTail == [there |-> FALSE, value |-> ZeroOrderExecutedMessageTail]

MaybeOrderExecutedMessageTail ==
    { WithoutOrderExecutedMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedOrderExecutedMessageTail }

ReadOrderExecutedMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutOrderExecutedMessageTail, << >>)
    ELSE LET one == DecodeOrderExecutedMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Order Executed Message                                                  *)
(***************************************************************************)

OrderExecutedMessage ==
    [ transactTime             : Sample(8),
      orderId                  : Sample(8),
      clOrdId                  : Sample(8),
      execPrice                : Sample(8),
      execId                   : Sample(8),
      execQty                  : Sample(4),
      leavesQty                : Sample(4),
      orderExecutedMessageTail : MaybeOrderExecutedMessageTail ]

EncodeOrderExecutedMessage(message) ==
    message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.execPrice
        \o message.execId
        \o message.execQty
        \o message.leavesQty
        \o IF message.orderExecutedMessageTail.there THEN EncodeOrderExecutedMessageTail(message.orderExecutedMessageTail.value) ELSE << >>

DecodeOrderExecutedMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execPrice == ReadBytes(clOrdId.rest, 8) IN IF ~execPrice.ok THEN Fail ELSE
    LET execId == ReadBytes(execPrice.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET execQty == ReadBytes(execId.rest, 4) IN IF ~execQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(execQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET orderExecutedMessageTail == ReadOrderExecutedMessageTailMaybe(leavesQty.rest) IN IF ~orderExecutedMessageTail.ok THEN Fail ELSE
    Ok([ transactTime             |-> transactTime.value,
         orderId                  |-> orderId.value,
         clOrdId                  |-> clOrdId.value,
         execPrice                |-> execPrice.value,
         execId                   |-> execId.value,
         execQty                  |-> execQty.value,
         leavesQty                |-> leavesQty.value,
         orderExecutedMessageTail |-> orderExecutedMessageTail.value ], orderExecutedMessageTail.rest)

ZeroOrderExecutedMessage ==
    [ transactTime             |-> [i \in 1 .. 8 |-> 0],
      orderId                  |-> [i \in 1 .. 8 |-> 0],
      clOrdId                  |-> [i \in 1 .. 8 |-> 0],
      execPrice                |-> [i \in 1 .. 8 |-> 0],
      execId                   |-> [i \in 1 .. 8 |-> 0],
      execQty                  |-> [i \in 1 .. 4 |-> 0],
      leavesQty                |-> [i \in 1 .. 4 |-> 0],
      orderExecutedMessageTail |-> WithoutOrderExecutedMessageTail ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.execPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.execQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderExecutedMessageTail = one] : one \in MaybeOrderExecutedMessageTail }

(***************************************************************************)
(* Order Restated Message                                                  *)
(***************************************************************************)

OrderRestatedMessage ==
    [ orderRestatedPresenceBits : 0 .. 255,
      transactTime              : Sample(8),
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      restatementReason         : Sample(1),
      orderRestatedRankPrice    : { << >> } \cup { <<held>> : held \in Sample(8) },
      orderRestatedDisplayPrice : { << >> } \cup { <<held>> : held \in Sample(8) },
      displayQty                : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeOrderRestatedMessage(message) ==
    EncodeUIntLE(message.orderRestatedPresenceBits, 1)
        \o message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.restatementReason
        \o (IF message.orderRestatedRankPrice = << >> THEN << >> ELSE message.orderRestatedRankPrice[1])
        \o (IF message.orderRestatedDisplayPrice = << >> THEN << >> ELSE message.orderRestatedDisplayPrice[1])
        \o (IF message.displayQty = << >> THEN << >> ELSE message.displayQty[1])

DecodeOrderRestatedMessage(bytes) ==
    LET orderRestatedPresenceBits == ReadUIntLE(bytes, 1) IN IF ~orderRestatedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(orderRestatedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET restatementReason == ReadBytes(clOrdId.rest, 1) IN IF ~restatementReason.ok THEN Fail ELSE
    LET orderRestatedRankPrice == ReadWhen(orderRestatedPresenceBits.value % 2 = 1, ReadBytes(restatementReason.rest, 8), restatementReason.rest) IN IF ~orderRestatedRankPrice.ok THEN Fail ELSE
    LET orderRestatedDisplayPrice == ReadWhen((orderRestatedPresenceBits.value \div 2) % 2 = 1, ReadBytes(orderRestatedRankPrice.rest, 8), orderRestatedRankPrice.rest) IN IF ~orderRestatedDisplayPrice.ok THEN Fail ELSE
    LET displayQty == ReadWhen((orderRestatedPresenceBits.value \div 4) % 2 = 1, ReadBytes(orderRestatedDisplayPrice.rest, 4), orderRestatedDisplayPrice.rest) IN IF ~displayQty.ok THEN Fail ELSE
    Ok([ orderRestatedPresenceBits |-> orderRestatedPresenceBits.value,
         transactTime              |-> transactTime.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         restatementReason         |-> restatementReason.value,
         orderRestatedRankPrice    |-> orderRestatedRankPrice.value,
         orderRestatedDisplayPrice |-> orderRestatedDisplayPrice.value,
         displayQty                |-> displayQty.value ], displayQty.rest)

(* Order Restated Message with each field marked present by fields before it there exactly where they say *)
SettleOrderRestatedMessage(message) ==
    LET settled1 == [message EXCEPT !.orderRestatedRankPrice = IF message.orderRestatedPresenceBits % 2 = 1 THEN (IF message.orderRestatedRankPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE message.orderRestatedRankPrice) ELSE << >>]
        settled2 == [settled1 EXCEPT !.orderRestatedDisplayPrice = IF (settled1.orderRestatedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.orderRestatedDisplayPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled1.orderRestatedDisplayPrice) ELSE << >>]
        settled3 == [settled2 EXCEPT !.displayQty = IF (settled2.orderRestatedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.displayQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.displayQty) ELSE << >>]
    IN  settled3

ZeroOrderRestatedMessage ==
    SettleOrderRestatedMessage([ orderRestatedPresenceBits |-> 0,
                                 transactTime              |-> [i \in 1 .. 8 |-> 0],
                                 orderId                   |-> [i \in 1 .. 8 |-> 0],
                                 clOrdId                   |-> [i \in 1 .. 8 |-> 0],
                                 restatementReason         |-> [i \in 1 .. 1 |-> 0],
                                 orderRestatedRankPrice    |-> << >>,
                                 orderRestatedDisplayPrice |-> << >>,
                                 displayQty                |-> << >> ])

(* Order Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedMessage ==
    { ZeroOrderRestatedMessage }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.orderRestatedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.orderId = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.restatementReason = one]) : one \in Sample(1) }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.orderRestatedPresenceBits = 1, !.orderRestatedRankPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.orderRestatedPresenceBits = 2, !.orderRestatedDisplayPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleOrderRestatedMessage([ZeroOrderRestatedMessage EXCEPT !.orderRestatedPresenceBits = 4, !.displayQty = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Self Match Prevented Message: 1 bytes                                   *)
(***************************************************************************)

SelfMatchPreventedMessageTail ==
    [ liquidityIndicator : Sample(1) ]

EncodeSelfMatchPreventedMessageTail(message) ==
    message.liquidityIndicator

DecodeSelfMatchPreventedMessageTail(bytes) ==
    LET liquidityIndicator == ReadBytes(bytes, 1) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    Ok([ liquidityIndicator |-> liquidityIndicator.value ], liquidityIndicator.rest)

ZeroSelfMatchPreventedMessageTail ==
    [ liquidityIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Self Match Prevented Message at zero, then each field in turn at the values it is checked at *)
CheckedSelfMatchPreventedMessageTail ==
    { ZeroSelfMatchPreventedMessageTail }
        \cup { [ZeroSelfMatchPreventedMessageTail EXCEPT !.liquidityIndicator = one] : one \in Sample(1) }

(* Self Match Prevented Message runs on only when bytes remain, so it is there or it is not *)
WithoutSelfMatchPreventedMessageTail == [there |-> FALSE, value |-> ZeroSelfMatchPreventedMessageTail]

MaybeSelfMatchPreventedMessageTail ==
    { WithoutSelfMatchPreventedMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedSelfMatchPreventedMessageTail }

ReadSelfMatchPreventedMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutSelfMatchPreventedMessageTail, << >>)
    ELSE LET one == DecodeSelfMatchPreventedMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Self Match Prevented Message                                            *)
(***************************************************************************)

SelfMatchPreventedMessage ==
    [ transactTime                  : Sample(8),
      orderId                       : Sample(8),
      clOrdId                       : Sample(8),
      execPrice                     : Sample(8),
      execId                        : Sample(8),
      execQty                       : Sample(4),
      canceledQty                   : Sample(4),
      leavesQty                     : Sample(4),
      selfMatchPreventedMessageTail : MaybeSelfMatchPreventedMessageTail ]

EncodeSelfMatchPreventedMessage(message) ==
    message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.execPrice
        \o message.execId
        \o message.execQty
        \o message.canceledQty
        \o message.leavesQty
        \o IF message.selfMatchPreventedMessageTail.there THEN EncodeSelfMatchPreventedMessageTail(message.selfMatchPreventedMessageTail.value) ELSE << >>

DecodeSelfMatchPreventedMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execPrice == ReadBytes(clOrdId.rest, 8) IN IF ~execPrice.ok THEN Fail ELSE
    LET execId == ReadBytes(execPrice.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET execQty == ReadBytes(execId.rest, 4) IN IF ~execQty.ok THEN Fail ELSE
    LET canceledQty == ReadBytes(execQty.rest, 4) IN IF ~canceledQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(canceledQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET selfMatchPreventedMessageTail == ReadSelfMatchPreventedMessageTailMaybe(leavesQty.rest) IN IF ~selfMatchPreventedMessageTail.ok THEN Fail ELSE
    Ok([ transactTime                  |-> transactTime.value,
         orderId                       |-> orderId.value,
         clOrdId                       |-> clOrdId.value,
         execPrice                     |-> execPrice.value,
         execId                        |-> execId.value,
         execQty                       |-> execQty.value,
         canceledQty                   |-> canceledQty.value,
         leavesQty                     |-> leavesQty.value,
         selfMatchPreventedMessageTail |-> selfMatchPreventedMessageTail.value ], selfMatchPreventedMessageTail.rest)

ZeroSelfMatchPreventedMessage ==
    [ transactTime                  |-> [i \in 1 .. 8 |-> 0],
      orderId                       |-> [i \in 1 .. 8 |-> 0],
      clOrdId                       |-> [i \in 1 .. 8 |-> 0],
      execPrice                     |-> [i \in 1 .. 8 |-> 0],
      execId                        |-> [i \in 1 .. 8 |-> 0],
      execQty                       |-> [i \in 1 .. 4 |-> 0],
      canceledQty                   |-> [i \in 1 .. 4 |-> 0],
      leavesQty                     |-> [i \in 1 .. 4 |-> 0],
      selfMatchPreventedMessageTail |-> WithoutSelfMatchPreventedMessageTail ]

(* Self Match Prevented Message at zero, then each field in turn at the values it is checked at *)
CheckedSelfMatchPreventedMessage ==
    { ZeroSelfMatchPreventedMessage }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.execPrice = one] : one \in Sample(8) }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.execQty = one] : one \in Sample(4) }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.canceledQty = one] : one \in Sample(4) }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroSelfMatchPreventedMessage EXCEPT !.selfMatchPreventedMessageTail = one] : one \in MaybeSelfMatchPreventedMessageTail }

(***************************************************************************)
(* Mass Cancel Accepted Message                                            *)
(***************************************************************************)

MassCancelAcceptedMessage ==
    [ massCancelAcceptedPresenceBits : 0 .. 255,
      transactTime                   : Sample(8),
      massCancelRequestId            : Sample(8),
      massCancelAcceptedScope        : Sample(1),
      massCancelAcceptedBitFields    : Sample(1),
      massCancelId                   : Sample(8),
      massCancelAcceptedMpid         : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelAcceptedSenderComp   : { << >> } \cup { <<held>> : held \in Sample(8) },
      massCancelAcceptedMemberGroup  : { << >> } \cup { <<held>> : held \in Sample(2) },
      massCancelAcceptedClOrdId      : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeMassCancelAcceptedMessage(message) ==
    EncodeUIntLE(message.massCancelAcceptedPresenceBits, 1)
        \o message.transactTime
        \o message.massCancelRequestId
        \o message.massCancelAcceptedScope
        \o message.massCancelAcceptedBitFields
        \o message.massCancelId
        \o (IF message.massCancelAcceptedMpid = << >> THEN << >> ELSE message.massCancelAcceptedMpid[1])
        \o (IF message.massCancelAcceptedSenderComp = << >> THEN << >> ELSE message.massCancelAcceptedSenderComp[1])
        \o (IF message.massCancelAcceptedMemberGroup = << >> THEN << >> ELSE message.massCancelAcceptedMemberGroup[1])
        \o (IF message.massCancelAcceptedClOrdId = << >> THEN << >> ELSE message.massCancelAcceptedClOrdId[1])

DecodeMassCancelAcceptedMessage(bytes) ==
    LET massCancelAcceptedPresenceBits == ReadUIntLE(bytes, 1) IN IF ~massCancelAcceptedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(massCancelAcceptedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET massCancelRequestId == ReadBytes(transactTime.rest, 8) IN IF ~massCancelRequestId.ok THEN Fail ELSE
    LET massCancelAcceptedScope == ReadBytes(massCancelRequestId.rest, 1) IN IF ~massCancelAcceptedScope.ok THEN Fail ELSE
    LET massCancelAcceptedBitFields == ReadBytes(massCancelAcceptedScope.rest, 1) IN IF ~massCancelAcceptedBitFields.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(massCancelAcceptedBitFields.rest, 8) IN IF ~massCancelId.ok THEN Fail ELSE
    LET massCancelAcceptedMpid == ReadWhen(massCancelAcceptedPresenceBits.value % 2 = 1, ReadBytes(massCancelId.rest, 4), massCancelId.rest) IN IF ~massCancelAcceptedMpid.ok THEN Fail ELSE
    LET massCancelAcceptedSenderComp == ReadWhen((massCancelAcceptedPresenceBits.value \div 2) % 2 = 1, ReadBytes(massCancelAcceptedMpid.rest, 8), massCancelAcceptedMpid.rest) IN IF ~massCancelAcceptedSenderComp.ok THEN Fail ELSE
    LET massCancelAcceptedMemberGroup == ReadWhen((massCancelAcceptedPresenceBits.value \div 4) % 2 = 1, ReadBytes(massCancelAcceptedSenderComp.rest, 2), massCancelAcceptedSenderComp.rest) IN IF ~massCancelAcceptedMemberGroup.ok THEN Fail ELSE
    LET massCancelAcceptedClOrdId == ReadWhen((massCancelAcceptedPresenceBits.value \div 8) % 2 = 1, ReadBytes(massCancelAcceptedMemberGroup.rest, 8), massCancelAcceptedMemberGroup.rest) IN IF ~massCancelAcceptedClOrdId.ok THEN Fail ELSE
    Ok([ massCancelAcceptedPresenceBits |-> massCancelAcceptedPresenceBits.value,
         transactTime                   |-> transactTime.value,
         massCancelRequestId            |-> massCancelRequestId.value,
         massCancelAcceptedScope        |-> massCancelAcceptedScope.value,
         massCancelAcceptedBitFields    |-> massCancelAcceptedBitFields.value,
         massCancelId                   |-> massCancelId.value,
         massCancelAcceptedMpid         |-> massCancelAcceptedMpid.value,
         massCancelAcceptedSenderComp   |-> massCancelAcceptedSenderComp.value,
         massCancelAcceptedMemberGroup  |-> massCancelAcceptedMemberGroup.value,
         massCancelAcceptedClOrdId      |-> massCancelAcceptedClOrdId.value ], massCancelAcceptedClOrdId.rest)

(* Mass Cancel Accepted Message with each field marked present by fields before it there exactly where they say *)
SettleMassCancelAcceptedMessage(message) ==
    LET settled1 == [message EXCEPT !.massCancelAcceptedMpid = IF message.massCancelAcceptedPresenceBits % 2 = 1 THEN (IF message.massCancelAcceptedMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE message.massCancelAcceptedMpid) ELSE << >>]
        settled2 == [settled1 EXCEPT !.massCancelAcceptedSenderComp = IF (settled1.massCancelAcceptedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.massCancelAcceptedSenderComp = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled1.massCancelAcceptedSenderComp) ELSE << >>]
        settled3 == [settled2 EXCEPT !.massCancelAcceptedMemberGroup = IF (settled2.massCancelAcceptedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.massCancelAcceptedMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled2.massCancelAcceptedMemberGroup) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelAcceptedClOrdId = IF (settled3.massCancelAcceptedPresenceBits \div 8) % 2 = 1 THEN (IF settled3.massCancelAcceptedClOrdId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled3.massCancelAcceptedClOrdId) ELSE << >>]
    IN  settled4

ZeroMassCancelAcceptedMessage ==
    SettleMassCancelAcceptedMessage([ massCancelAcceptedPresenceBits |-> 0,
                                      transactTime                   |-> [i \in 1 .. 8 |-> 0],
                                      massCancelRequestId            |-> [i \in 1 .. 8 |-> 0],
                                      massCancelAcceptedScope        |-> [i \in 1 .. 1 |-> 0],
                                      massCancelAcceptedBitFields    |-> [i \in 1 .. 1 |-> 0],
                                      massCancelId                   |-> [i \in 1 .. 8 |-> 0],
                                      massCancelAcceptedMpid         |-> << >>,
                                      massCancelAcceptedSenderComp   |-> << >>,
                                      massCancelAcceptedMemberGroup  |-> << >>,
                                      massCancelAcceptedClOrdId      |-> << >> ])

(* Mass Cancel Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelAcceptedMessage ==
    { ZeroMassCancelAcceptedMessage }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelAcceptedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelRequestId = one]) : one \in Sample(8) }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelAcceptedScope = one]) : one \in Sample(1) }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelAcceptedBitFields = one]) : one \in Sample(1) }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelId = one]) : one \in Sample(8) }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelAcceptedPresenceBits = 1, !.massCancelAcceptedMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelAcceptedPresenceBits = 2, !.massCancelAcceptedSenderComp = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelAcceptedPresenceBits = 4, !.massCancelAcceptedMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleMassCancelAcceptedMessage([ZeroMassCancelAcceptedMessage EXCEPT !.massCancelAcceptedPresenceBits = 8, !.massCancelAcceptedClOrdId = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Mass Cancel Rejected Message                                            *)
(***************************************************************************)

MassCancelRejectedMessage ==
    [ massCancelRejectedPresenceBits : 0 .. 255,
      transactTime                   : Sample(8),
      massCancelRequestId            : Sample(8),
      massCancelRejectedScope        : Sample(1),
      massCancelRejectedBitFields    : Sample(1),
      massCancelRejectedReason       : Sample(1),
      massCancelRejectedMpid         : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelRejectedSenderComp   : { << >> } \cup { <<held>> : held \in Sample(8) },
      massCancelRejectedMemberGroup  : { << >> } \cup { <<held>> : held \in Sample(2) },
      massCancelRejectedClOrdId      : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeMassCancelRejectedMessage(message) ==
    EncodeUIntLE(message.massCancelRejectedPresenceBits, 1)
        \o message.transactTime
        \o message.massCancelRequestId
        \o message.massCancelRejectedScope
        \o message.massCancelRejectedBitFields
        \o message.massCancelRejectedReason
        \o (IF message.massCancelRejectedMpid = << >> THEN << >> ELSE message.massCancelRejectedMpid[1])
        \o (IF message.massCancelRejectedSenderComp = << >> THEN << >> ELSE message.massCancelRejectedSenderComp[1])
        \o (IF message.massCancelRejectedMemberGroup = << >> THEN << >> ELSE message.massCancelRejectedMemberGroup[1])
        \o (IF message.massCancelRejectedClOrdId = << >> THEN << >> ELSE message.massCancelRejectedClOrdId[1])

DecodeMassCancelRejectedMessage(bytes) ==
    LET massCancelRejectedPresenceBits == ReadUIntLE(bytes, 1) IN IF ~massCancelRejectedPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(massCancelRejectedPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET massCancelRequestId == ReadBytes(transactTime.rest, 8) IN IF ~massCancelRequestId.ok THEN Fail ELSE
    LET massCancelRejectedScope == ReadBytes(massCancelRequestId.rest, 1) IN IF ~massCancelRejectedScope.ok THEN Fail ELSE
    LET massCancelRejectedBitFields == ReadBytes(massCancelRejectedScope.rest, 1) IN IF ~massCancelRejectedBitFields.ok THEN Fail ELSE
    LET massCancelRejectedReason == ReadBytes(massCancelRejectedBitFields.rest, 1) IN IF ~massCancelRejectedReason.ok THEN Fail ELSE
    LET massCancelRejectedMpid == ReadWhen(massCancelRejectedPresenceBits.value % 2 = 1, ReadBytes(massCancelRejectedReason.rest, 4), massCancelRejectedReason.rest) IN IF ~massCancelRejectedMpid.ok THEN Fail ELSE
    LET massCancelRejectedSenderComp == ReadWhen((massCancelRejectedPresenceBits.value \div 2) % 2 = 1, ReadBytes(massCancelRejectedMpid.rest, 8), massCancelRejectedMpid.rest) IN IF ~massCancelRejectedSenderComp.ok THEN Fail ELSE
    LET massCancelRejectedMemberGroup == ReadWhen((massCancelRejectedPresenceBits.value \div 4) % 2 = 1, ReadBytes(massCancelRejectedSenderComp.rest, 2), massCancelRejectedSenderComp.rest) IN IF ~massCancelRejectedMemberGroup.ok THEN Fail ELSE
    LET massCancelRejectedClOrdId == ReadWhen((massCancelRejectedPresenceBits.value \div 8) % 2 = 1, ReadBytes(massCancelRejectedMemberGroup.rest, 8), massCancelRejectedMemberGroup.rest) IN IF ~massCancelRejectedClOrdId.ok THEN Fail ELSE
    Ok([ massCancelRejectedPresenceBits |-> massCancelRejectedPresenceBits.value,
         transactTime                   |-> transactTime.value,
         massCancelRequestId            |-> massCancelRequestId.value,
         massCancelRejectedScope        |-> massCancelRejectedScope.value,
         massCancelRejectedBitFields    |-> massCancelRejectedBitFields.value,
         massCancelRejectedReason       |-> massCancelRejectedReason.value,
         massCancelRejectedMpid         |-> massCancelRejectedMpid.value,
         massCancelRejectedSenderComp   |-> massCancelRejectedSenderComp.value,
         massCancelRejectedMemberGroup  |-> massCancelRejectedMemberGroup.value,
         massCancelRejectedClOrdId      |-> massCancelRejectedClOrdId.value ], massCancelRejectedClOrdId.rest)

(* Mass Cancel Rejected Message with each field marked present by fields before it there exactly where they say *)
SettleMassCancelRejectedMessage(message) ==
    LET settled1 == [message EXCEPT !.massCancelRejectedMpid = IF message.massCancelRejectedPresenceBits % 2 = 1 THEN (IF message.massCancelRejectedMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE message.massCancelRejectedMpid) ELSE << >>]
        settled2 == [settled1 EXCEPT !.massCancelRejectedSenderComp = IF (settled1.massCancelRejectedPresenceBits \div 2) % 2 = 1 THEN (IF settled1.massCancelRejectedSenderComp = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled1.massCancelRejectedSenderComp) ELSE << >>]
        settled3 == [settled2 EXCEPT !.massCancelRejectedMemberGroup = IF (settled2.massCancelRejectedPresenceBits \div 4) % 2 = 1 THEN (IF settled2.massCancelRejectedMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled2.massCancelRejectedMemberGroup) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelRejectedClOrdId = IF (settled3.massCancelRejectedPresenceBits \div 8) % 2 = 1 THEN (IF settled3.massCancelRejectedClOrdId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled3.massCancelRejectedClOrdId) ELSE << >>]
    IN  settled4

ZeroMassCancelRejectedMessage ==
    SettleMassCancelRejectedMessage([ massCancelRejectedPresenceBits |-> 0,
                                      transactTime                   |-> [i \in 1 .. 8 |-> 0],
                                      massCancelRequestId            |-> [i \in 1 .. 8 |-> 0],
                                      massCancelRejectedScope        |-> [i \in 1 .. 1 |-> 0],
                                      massCancelRejectedBitFields    |-> [i \in 1 .. 1 |-> 0],
                                      massCancelRejectedReason       |-> [i \in 1 .. 1 |-> 0],
                                      massCancelRejectedMpid         |-> << >>,
                                      massCancelRejectedSenderComp   |-> << >>,
                                      massCancelRejectedMemberGroup  |-> << >>,
                                      massCancelRejectedClOrdId      |-> << >> ])

(* Mass Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRejectedMessage ==
    { ZeroMassCancelRejectedMessage }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectedPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRequestId = one]) : one \in Sample(8) }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectedScope = one]) : one \in Sample(1) }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectedBitFields = one]) : one \in Sample(1) }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectedReason = one]) : one \in Sample(1) }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectedPresenceBits = 1, !.massCancelRejectedMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectedPresenceBits = 2, !.massCancelRejectedSenderComp = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectedPresenceBits = 4, !.massCancelRejectedMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleMassCancelRejectedMessage([ZeroMassCancelRejectedMessage EXCEPT !.massCancelRejectedPresenceBits = 8, !.massCancelRejectedClOrdId = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Mass Cancel Result Message: 28 bytes                                    *)
(***************************************************************************)

MassCancelResultMessage ==
    [ transactTime        : Sample(8),
      massCancelRequestId : Sample(8),
      massCancelId        : Sample(8),
      canceledCount       : Sample(4) ]

EncodeMassCancelResultMessage(message) ==
    message.transactTime
        \o message.massCancelRequestId
        \o message.massCancelId
        \o message.canceledCount

DecodeMassCancelResultMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET massCancelRequestId == ReadBytes(transactTime.rest, 8) IN IF ~massCancelRequestId.ok THEN Fail ELSE
    LET massCancelId == ReadBytes(massCancelRequestId.rest, 8) IN IF ~massCancelId.ok THEN Fail ELSE
    LET canceledCount == ReadBytes(massCancelId.rest, 4) IN IF ~canceledCount.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         massCancelRequestId |-> massCancelRequestId.value,
         massCancelId        |-> massCancelId.value,
         canceledCount       |-> canceledCount.value ], canceledCount.rest)

ZeroMassCancelResultMessage ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      massCancelRequestId |-> [i \in 1 .. 8 |-> 0],
      massCancelId        |-> [i \in 1 .. 8 |-> 0],
      canceledCount       |-> [i \in 1 .. 4 |-> 0] ]

(* Mass Cancel Result Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelResultMessage ==
    { ZeroMassCancelResultMessage }
        \cup { [ZeroMassCancelResultMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResultMessage EXCEPT !.massCancelRequestId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResultMessage EXCEPT !.massCancelId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResultMessage EXCEPT !.canceledCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Sequenced Message, selected by Message Type                             *)
(***************************************************************************)

TradingSessionStatusMessageCode == 105  \* 0x69
DefineSymbolMessageCode == 115  \* 0x73
SymbolStatusMessageCode == 121  \* 0x79
LimitOrderAcceptedMessageCode == 73  \* 0x49
LimitOrderRejectedMessageCode == 85  \* 0x55
MarketOrderAcceptedMessageCode == 68  \* 0x44
MarketOrderRejectedMessageCode == 84  \* 0x54
OrderCanceledMessageCode == 88  \* 0x58
CancelRejectedMessageCode == 87  \* 0x57
OrderModifiedMessageCode == 89  \* 0x59
ModifyRejectedMessageCode == 78  \* 0x4e
OrderReplacedMessageCode == 74  \* 0x4a
ReplaceRejectedMessageCode == 75  \* 0x4b
OrderExecutedMessageCode == 69  \* 0x45
OrderRestatedMessageCode == 70  \* 0x46
SelfMatchPreventedMessageCode == 90  \* 0x5a
MassCancelAcceptedMessageCode == 79  \* 0x4f
MassCancelRejectedMessageCode == 80  \* 0x50
MassCancelResultMessageCode == 81  \* 0x51

SequencedMessage ==
    [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {DefineSymbolMessageCode}, body : DefineSymbolMessage ]
        \cup [ tag : {SymbolStatusMessageCode}, body : SymbolStatusMessage ]
        \cup [ tag : {LimitOrderAcceptedMessageCode}, body : LimitOrderAcceptedMessage ]
        \cup [ tag : {LimitOrderRejectedMessageCode}, body : LimitOrderRejectedMessage ]
        \cup [ tag : {MarketOrderAcceptedMessageCode}, body : MarketOrderAcceptedMessage ]
        \cup [ tag : {MarketOrderRejectedMessageCode}, body : MarketOrderRejectedMessage ]
        \cup [ tag : {OrderCanceledMessageCode}, body : OrderCanceledMessage ]
        \cup [ tag : {CancelRejectedMessageCode}, body : CancelRejectedMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {ModifyRejectedMessageCode}, body : ModifyRejectedMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {ReplaceRejectedMessageCode}, body : ReplaceRejectedMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderRestatedMessageCode}, body : OrderRestatedMessage ]
        \cup [ tag : {SelfMatchPreventedMessageCode}, body : SelfMatchPreventedMessage ]
        \cup [ tag : {MassCancelAcceptedMessageCode}, body : MassCancelAcceptedMessage ]
        \cup [ tag : {MassCancelRejectedMessageCode}, body : MassCancelRejectedMessage ]
        \cup [ tag : {MassCancelResultMessageCode}, body : MassCancelResultMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = DefineSymbolMessageCode -> EncodeDefineSymbolMessage(message.body)
      [] message.tag = SymbolStatusMessageCode -> EncodeSymbolStatusMessage(message.body)
      [] message.tag = LimitOrderAcceptedMessageCode -> EncodeLimitOrderAcceptedMessage(message.body)
      [] message.tag = LimitOrderRejectedMessageCode -> EncodeLimitOrderRejectedMessage(message.body)
      [] message.tag = MarketOrderAcceptedMessageCode -> EncodeMarketOrderAcceptedMessage(message.body)
      [] message.tag = MarketOrderRejectedMessageCode -> EncodeMarketOrderRejectedMessage(message.body)
      [] message.tag = OrderCanceledMessageCode -> EncodeOrderCanceledMessage(message.body)
      [] message.tag = CancelRejectedMessageCode -> EncodeCancelRejectedMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = ModifyRejectedMessageCode -> EncodeModifyRejectedMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = ReplaceRejectedMessageCode -> EncodeReplaceRejectedMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderRestatedMessageCode -> EncodeOrderRestatedMessage(message.body)
      [] message.tag = SelfMatchPreventedMessageCode -> EncodeSelfMatchPreventedMessage(message.body)
      [] message.tag = MassCancelAcceptedMessageCode -> EncodeMassCancelAcceptedMessage(message.body)
      [] message.tag = MassCancelRejectedMessageCode -> EncodeMassCancelRejectedMessage(message.body)
      [] message.tag = MassCancelResultMessageCode -> EncodeMassCancelResultMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = DefineSymbolMessageCode -> DecodeDefineSymbolMessage(bytes)
              [] tag = SymbolStatusMessageCode -> DecodeSymbolStatusMessage(bytes)
              [] tag = LimitOrderAcceptedMessageCode -> DecodeLimitOrderAcceptedMessage(bytes)
              [] tag = LimitOrderRejectedMessageCode -> DecodeLimitOrderRejectedMessage(bytes)
              [] tag = MarketOrderAcceptedMessageCode -> DecodeMarketOrderAcceptedMessage(bytes)
              [] tag = MarketOrderRejectedMessageCode -> DecodeMarketOrderRejectedMessage(bytes)
              [] tag = OrderCanceledMessageCode -> DecodeOrderCanceledMessage(bytes)
              [] tag = CancelRejectedMessageCode -> DecodeCancelRejectedMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = ModifyRejectedMessageCode -> DecodeModifyRejectedMessage(bytes)
              [] tag = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] tag = ReplaceRejectedMessageCode -> DecodeReplaceRejectedMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderRestatedMessageCode -> DecodeOrderRestatedMessage(bytes)
              [] tag = SelfMatchPreventedMessageCode -> DecodeSelfMatchPreventedMessage(bytes)
              [] tag = MassCancelAcceptedMessageCode -> DecodeMassCancelAcceptedMessage(bytes)
              [] tag = MassCancelRejectedMessageCode -> DecodeMassCancelRejectedMessage(bytes)
              [] tag = MassCancelResultMessageCode -> DecodeMassCancelResultMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> TradingSessionStatusMessageCode, body |-> ZeroTradingSessionStatusMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> DefineSymbolMessageCode, body |-> one] : one \in CheckedDefineSymbolMessage }
        \cup { [tag |-> SymbolStatusMessageCode, body |-> one] : one \in CheckedSymbolStatusMessage }
        \cup { [tag |-> LimitOrderAcceptedMessageCode, body |-> one] : one \in CheckedLimitOrderAcceptedMessage }
        \cup { [tag |-> LimitOrderRejectedMessageCode, body |-> one] : one \in CheckedLimitOrderRejectedMessage }
        \cup { [tag |-> MarketOrderAcceptedMessageCode, body |-> one] : one \in CheckedMarketOrderAcceptedMessage }
        \cup { [tag |-> MarketOrderRejectedMessageCode, body |-> one] : one \in CheckedMarketOrderRejectedMessage }
        \cup { [tag |-> OrderCanceledMessageCode, body |-> one] : one \in CheckedOrderCanceledMessage }
        \cup { [tag |-> CancelRejectedMessageCode, body |-> one] : one \in CheckedCancelRejectedMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> ModifyRejectedMessageCode, body |-> one] : one \in CheckedModifyRejectedMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> ReplaceRejectedMessageCode, body |-> one] : one \in CheckedReplaceRejectedMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderRestatedMessageCode, body |-> one] : one \in CheckedOrderRestatedMessage }
        \cup { [tag |-> SelfMatchPreventedMessageCode, body |-> one] : one \in CheckedSelfMatchPreventedMessage }
        \cup { [tag |-> MassCancelAcceptedMessageCode, body |-> one] : one \in CheckedMassCancelAcceptedMessage }
        \cup { [tag |-> MassCancelRejectedMessageCode, body |-> one] : one \in CheckedMassCancelRejectedMessage }
        \cup { [tag |-> MassCancelResultMessageCode, body |-> one] : one \in CheckedMassCancelResultMessage }

(***************************************************************************)
(* Tcp Sequenced Message                                                   *)
(***************************************************************************)

TcpSequencedMessage ==
    [ streamId         : Sample(1),
      sequencedMessage : SequencedMessage ]

EncodeTcpSequencedMessage(message) ==
    message.streamId
        \o EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeTcpSequencedMessage(bytes) ==
    LET streamId == ReadBytes(bytes, 1) IN IF ~streamId.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(streamId.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(messageType.value, messageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ streamId         |-> streamId.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroTcpSequencedMessage ==
    [ streamId         |-> [i \in 1 .. 1 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Tcp Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedTcpSequencedMessage ==
    { ZeroTcpSequencedMessage }
        \cup { [ZeroTcpSequencedMessage EXCEPT !.streamId = one] : one \in Sample(1) }
        \cup { [ZeroTcpSequencedMessage EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Packet Type                                 *)
(***************************************************************************)

DebugMessageCode == 48  \* 0x30
EndOfSessionMessageCode == 52  \* 0x34
LogonResponseMessageCode == 49  \* 0x31
TcpSequencedMessageCode == 50  \* 0x32

ServerPayload ==
    [ tag : {DebugMessageCode}, body : DebugMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {TcpSequencedMessageCode}, body : TcpSequencedMessage ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugMessageCode -> EncodeDebugMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> << >>
      [] message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = TcpSequencedMessageCode -> EncodeTcpSequencedMessage(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugMessageCode -> DecodeDebugMessage(bytes)
              [] tag = EndOfSessionMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = TcpSequencedMessageCode -> DecodeTcpSequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugMessageCode, body |-> ZeroDebugMessage]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugMessageCode, body |-> one] : one \in CheckedDebugMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> TcpSequencedMessageCode, body |-> one] : one \in CheckedTcpSequencedMessage }

(***************************************************************************)
(* Server Rake Tcp Message, framed by Message Length                       *)
(***************************************************************************)

ServerRakeTcpMessage ==
    [ serverPayload : ServerPayload ]

EncodeServerRakeTcpMessageBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeServerRakeTcpMessage(message) ==
    LET body == EncodeServerRakeTcpMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeServerRakeTcpMessageBody(bytes) ==
    LET packetType == ReadUIntBE(bytes, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(packetType.value, packetType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerRakeTcpMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerRakeTcpMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerRakeTcpMessage ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Rake Tcp Message at zero, then each field in turn at the values it is checked at *)
CheckedServerRakeTcpMessage ==
    { ZeroServerRakeTcpMessage }
        \cup { [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Rake Tcp Message, written one after another *)
RECURSIVE EncodeServerRakeTcpMessageList(_)
EncodeServerRakeTcpMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerRakeTcpMessage(Head(messages)) \o EncodeServerRakeTcpMessageList(Tail(messages))

(* As many Server Rake Tcp Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerRakeTcpMessageAll(_)
ReadServerRakeTcpMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerRakeTcpMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerRakeTcpMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Rake Tcp Message of each kind, for the lists that carry them *)
OneServerRakeTcpMessage ==
    { [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = [tag |-> DebugMessageCode, body |-> ZeroDebugMessage]],
      [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = [tag |-> EndOfSessionMessageCode, body |-> [empty |-> 0]]],
      [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]],
      [ZeroServerRakeTcpMessage EXCEPT !.serverPayload = [tag |-> TcpSequencedMessageCode, body |-> ZeroTcpSequencedMessage]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverRakeTcpMessage : SampleLists(OneServerRakeTcpMessage) ]

EncodeServerPacket(message) ==
    EncodeServerRakeTcpMessageList(message.serverRakeTcpMessage)

DecodeServerPacket(bytes) ==
    LET serverRakeTcpMessage == ReadServerRakeTcpMessageAll(bytes) IN IF ~serverRakeTcpMessage.ok THEN Fail ELSE
    Ok([ serverRakeTcpMessage |-> serverRakeTcpMessage.value ], serverRakeTcpMessage.rest)

ZeroServerPacket ==
    [ serverRakeTcpMessage |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverRakeTcpMessage = one] : one \in SampleLists(OneServerRakeTcpMessage) }

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

(* Every Debug Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugMessage ==
    \A message \in CheckedDebugMessage :
        LET read == DecodeDebugMessage(EncodeDebugMessage(message))
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

(* Every Trading Session Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusMessage ==
    \A message \in CheckedTradingSessionStatusMessage :
        LET read == DecodeTradingSessionStatusMessage(EncodeTradingSessionStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Define Symbol Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDefineSymbolMessageTail ==
    \A message \in CheckedDefineSymbolMessageTail :
        LET read == DecodeDefineSymbolMessageTail(EncodeDefineSymbolMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Define Symbol Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDefineSymbolMessage ==
    \A message \in CheckedDefineSymbolMessage :
        LET read == DecodeDefineSymbolMessage(EncodeDefineSymbolMessage(message))
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

(* Every Limit Order Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitOrderAcceptedMessage ==
    \A message \in CheckedLimitOrderAcceptedMessage :
        LET read == DecodeLimitOrderAcceptedMessage(EncodeLimitOrderAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Limit Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitOrderRejectedMessage ==
    \A message \in CheckedLimitOrderRejectedMessage :
        LET read == DecodeLimitOrderRejectedMessage(EncodeLimitOrderRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Order Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOrderAcceptedMessage ==
    \A message \in CheckedMarketOrderAcceptedMessage :
        LET read == DecodeMarketOrderAcceptedMessage(EncodeMarketOrderAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Order Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOrderRejectedMessage ==
    \A message \in CheckedMarketOrderRejectedMessage :
        LET read == DecodeMarketOrderRejectedMessage(EncodeMarketOrderRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCanceledMessage ==
    \A message \in CheckedOrderCanceledMessage :
        LET read == DecodeOrderCanceledMessage(EncodeOrderCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedMessage ==
    \A message \in CheckedCancelRejectedMessage :
        LET read == DecodeCancelRejectedMessage(EncodeCancelRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedMessage ==
    \A message \in CheckedOrderModifiedMessage :
        LET read == DecodeOrderModifiedMessage(EncodeOrderModifiedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyRejectedMessage ==
    \A message \in CheckedModifyRejectedMessage :
        LET read == DecodeModifyRejectedMessage(EncodeModifyRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedMessage ==
    \A message \in CheckedOrderReplacedMessage :
        LET read == DecodeOrderReplacedMessage(EncodeOrderReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replace Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceRejectedMessage ==
    \A message \in CheckedReplaceRejectedMessage :
        LET read == DecodeReplaceRejectedMessage(EncodeReplaceRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessageTail ==
    \A message \in CheckedOrderExecutedMessageTail :
        LET read == DecodeOrderExecutedMessageTail(EncodeOrderExecutedMessageTail(message))
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

(* Every Order Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedMessage ==
    \A message \in CheckedOrderRestatedMessage :
        LET read == DecodeOrderRestatedMessage(EncodeOrderRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Self Match Prevented Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSelfMatchPreventedMessageTail ==
    \A message \in CheckedSelfMatchPreventedMessageTail :
        LET read == DecodeSelfMatchPreventedMessageTail(EncodeSelfMatchPreventedMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Self Match Prevented Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSelfMatchPreventedMessage ==
    \A message \in CheckedSelfMatchPreventedMessage :
        LET read == DecodeSelfMatchPreventedMessage(EncodeSelfMatchPreventedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelAcceptedMessage ==
    \A message \in CheckedMassCancelAcceptedMessage :
        LET read == DecodeMassCancelAcceptedMessage(EncodeMassCancelAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRejectedMessage ==
    \A message \in CheckedMassCancelRejectedMessage :
        LET read == DecodeMassCancelRejectedMessage(EncodeMassCancelRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Result Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelResultMessage ==
    \A message \in CheckedMassCancelResultMessage :
        LET read == DecodeMassCancelResultMessage(EncodeMassCancelResultMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Sequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpSequencedMessage ==
    \A message \in CheckedTcpSequencedMessage :
        LET read == DecodeTcpSequencedMessage(EncodeTcpSequencedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Rake Tcp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerRakeTcpMessage ==
    \A message \in CheckedServerRakeTcpMessage :
        LET read == DecodeServerRakeTcpMessage(EncodeServerRakeTcpMessage(message))
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

(* A Sequenced Message is selected by the Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET sent == EncodeSequencedMessage(message)
            read == DecodeSequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET sent == EncodeServerPayload(message)
            read == DecodeServerPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesServerRakeTcpMessage ==
    \A message \in CheckedServerRakeTcpMessage :
        LET bytes == EncodeServerRakeTcpMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
