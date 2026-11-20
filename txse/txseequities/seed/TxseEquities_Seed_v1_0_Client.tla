------------------- MODULE TxseEquities_Seed_v1_0_Client -------------------
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
(* Note: Tcp Unsequenced Message fills what is left of the frame Message   *)
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
(* Logon Request Packet: 32 bytes                                          *)
(***************************************************************************)

LogonRequestPacket ==
    [ session            : Sample(8),
      senderComp         : Sample(8),
      token              : Sample(8),
      nextSequenceNumber : Sample(8) ]

EncodeLogonRequestPacket(message) ==
    message.session
        \o message.senderComp
        \o message.token
        \o message.nextSequenceNumber

DecodeLogonRequestPacket(bytes) ==
    LET session == ReadBytes(bytes, 8) IN IF ~session.ok THEN Fail ELSE
    LET senderComp == ReadBytes(session.rest, 8) IN IF ~senderComp.ok THEN Fail ELSE
    LET token == ReadBytes(senderComp.rest, 8) IN IF ~token.ok THEN Fail ELSE
    LET nextSequenceNumber == ReadBytes(token.rest, 8) IN IF ~nextSequenceNumber.ok THEN Fail ELSE
    Ok([ session            |-> session.value,
         senderComp         |-> senderComp.value,
         token              |-> token.value,
         nextSequenceNumber |-> nextSequenceNumber.value ], nextSequenceNumber.rest)

ZeroLogonRequestPacket ==
    [ session            |-> [i \in 1 .. 8 |-> 0],
      senderComp         |-> [i \in 1 .. 8 |-> 0],
      token              |-> [i \in 1 .. 8 |-> 0],
      nextSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Logon Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLogonRequestPacket ==
    { ZeroLogonRequestPacket }
        \cup { [ZeroLogonRequestPacket EXCEPT !.session = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestPacket EXCEPT !.senderComp = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestPacket EXCEPT !.token = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestPacket EXCEPT !.nextSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Limit Order Message                                                     *)
(***************************************************************************)

LimitOrderMessage ==
    [ limitOrderPresenceBits          : 0 .. 255,
      clOrdId                         : Sample(8),
      orderQty                        : Sample(4),
      limitOrderBitFields             : Sample(4),
      symbolId                        : Sample(2),
      price                           : Sample(8),
      limitOrderSelfMatchScope        : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderSelfMatchInstruction  : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderPriceSlideInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      limitOrderMinQty                : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderMaxFloorQty           : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderMaxReplenishQtyRange  : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderMaxReplenishTimeRange : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderReferencePriceTarget  : { << >> } \cup { <<held>> : held \in Sample(2) },
      limitOrderExpireTime            : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderUserData              : { << >> } \cup { <<held>> : held \in Sample(8) },
      limitOrderMpid                  : { << >> } \cup { <<held>> : held \in Sample(4) },
      limitOrderMemberGroup           : { << >> } \cup { <<held>> : held \in Sample(2) },
      limitOrderLocateBroker          : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeLimitOrderMessage(message) ==
    EncodeUIntLE(message.limitOrderPresenceBits, 4)
        \o message.clOrdId
        \o message.orderQty
        \o message.limitOrderBitFields
        \o message.symbolId
        \o message.price
        \o (IF message.limitOrderSelfMatchScope = << >> THEN << >> ELSE message.limitOrderSelfMatchScope[1])
        \o (IF message.limitOrderSelfMatchInstruction = << >> THEN << >> ELSE message.limitOrderSelfMatchInstruction[1])
        \o (IF message.limitOrderPriceSlideInstruction = << >> THEN << >> ELSE message.limitOrderPriceSlideInstruction[1])
        \o (IF message.limitOrderMinQty = << >> THEN << >> ELSE message.limitOrderMinQty[1])
        \o (IF message.limitOrderMaxFloorQty = << >> THEN << >> ELSE message.limitOrderMaxFloorQty[1])
        \o (IF message.limitOrderMaxReplenishQtyRange = << >> THEN << >> ELSE message.limitOrderMaxReplenishQtyRange[1])
        \o (IF message.limitOrderMaxReplenishTimeRange = << >> THEN << >> ELSE message.limitOrderMaxReplenishTimeRange[1])
        \o (IF message.limitOrderReferencePriceTarget = << >> THEN << >> ELSE message.limitOrderReferencePriceTarget[1])
        \o (IF message.limitOrderExpireTime = << >> THEN << >> ELSE message.limitOrderExpireTime[1])
        \o (IF message.limitOrderUserData = << >> THEN << >> ELSE message.limitOrderUserData[1])
        \o (IF message.limitOrderMpid = << >> THEN << >> ELSE message.limitOrderMpid[1])
        \o (IF message.limitOrderMemberGroup = << >> THEN << >> ELSE message.limitOrderMemberGroup[1])
        \o (IF message.limitOrderLocateBroker = << >> THEN << >> ELSE message.limitOrderLocateBroker[1])

DecodeLimitOrderMessage(bytes) ==
    LET limitOrderPresenceBits == ReadUIntLE(bytes, 4) IN IF ~limitOrderPresenceBits.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(limitOrderPresenceBits.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET limitOrderBitFields == ReadBytes(orderQty.rest, 4) IN IF ~limitOrderBitFields.ok THEN Fail ELSE
    LET symbolId == ReadBytes(limitOrderBitFields.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET price == ReadBytes(symbolId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET limitOrderSelfMatchScope == ReadWhen(limitOrderPresenceBits.value % 2 = 1, ReadBytes(price.rest, 1), price.rest) IN IF ~limitOrderSelfMatchScope.ok THEN Fail ELSE
    LET limitOrderSelfMatchInstruction == ReadWhen((limitOrderPresenceBits.value \div 2) % 2 = 1, ReadBytes(limitOrderSelfMatchScope.rest, 1), limitOrderSelfMatchScope.rest) IN IF ~limitOrderSelfMatchInstruction.ok THEN Fail ELSE
    LET limitOrderPriceSlideInstruction == ReadWhen((limitOrderPresenceBits.value \div 4) % 2 = 1, ReadBytes(limitOrderSelfMatchInstruction.rest, 1), limitOrderSelfMatchInstruction.rest) IN IF ~limitOrderPriceSlideInstruction.ok THEN Fail ELSE
    LET limitOrderMinQty == ReadWhen((limitOrderPresenceBits.value \div 8) % 2 = 1, ReadBytes(limitOrderPriceSlideInstruction.rest, 4), limitOrderPriceSlideInstruction.rest) IN IF ~limitOrderMinQty.ok THEN Fail ELSE
    LET limitOrderMaxFloorQty == ReadWhen((limitOrderPresenceBits.value \div 16) % 2 = 1, ReadBytes(limitOrderMinQty.rest, 4), limitOrderMinQty.rest) IN IF ~limitOrderMaxFloorQty.ok THEN Fail ELSE
    LET limitOrderMaxReplenishQtyRange == ReadWhen((limitOrderPresenceBits.value \div 32) % 2 = 1, ReadBytes(limitOrderMaxFloorQty.rest, 4), limitOrderMaxFloorQty.rest) IN IF ~limitOrderMaxReplenishQtyRange.ok THEN Fail ELSE
    LET limitOrderMaxReplenishTimeRange == ReadWhen((limitOrderPresenceBits.value \div 64) % 2 = 1, ReadBytes(limitOrderMaxReplenishQtyRange.rest, 8), limitOrderMaxReplenishQtyRange.rest) IN IF ~limitOrderMaxReplenishTimeRange.ok THEN Fail ELSE
    LET limitOrderReferencePriceTarget == ReadWhen((limitOrderPresenceBits.value \div 128) % 2 = 1, ReadBytes(limitOrderMaxReplenishTimeRange.rest, 2), limitOrderMaxReplenishTimeRange.rest) IN IF ~limitOrderReferencePriceTarget.ok THEN Fail ELSE
    LET limitOrderExpireTime == ReadWhen((limitOrderPresenceBits.value \div 256) % 2 = 1, ReadBytes(limitOrderReferencePriceTarget.rest, 8), limitOrderReferencePriceTarget.rest) IN IF ~limitOrderExpireTime.ok THEN Fail ELSE
    LET limitOrderUserData == ReadWhen((limitOrderPresenceBits.value \div 512) % 2 = 1, ReadBytes(limitOrderExpireTime.rest, 8), limitOrderExpireTime.rest) IN IF ~limitOrderUserData.ok THEN Fail ELSE
    LET limitOrderMpid == ReadWhen((limitOrderPresenceBits.value \div 1024) % 2 = 1, ReadBytes(limitOrderUserData.rest, 4), limitOrderUserData.rest) IN IF ~limitOrderMpid.ok THEN Fail ELSE
    LET limitOrderMemberGroup == ReadWhen((limitOrderPresenceBits.value \div 2048) % 2 = 1, ReadBytes(limitOrderMpid.rest, 2), limitOrderMpid.rest) IN IF ~limitOrderMemberGroup.ok THEN Fail ELSE
    LET limitOrderLocateBroker == ReadWhen((limitOrderPresenceBits.value \div 4096) % 2 = 1, ReadBytes(limitOrderMemberGroup.rest, 4), limitOrderMemberGroup.rest) IN IF ~limitOrderLocateBroker.ok THEN Fail ELSE
    Ok([ limitOrderPresenceBits          |-> limitOrderPresenceBits.value,
         clOrdId                         |-> clOrdId.value,
         orderQty                        |-> orderQty.value,
         limitOrderBitFields             |-> limitOrderBitFields.value,
         symbolId                        |-> symbolId.value,
         price                           |-> price.value,
         limitOrderSelfMatchScope        |-> limitOrderSelfMatchScope.value,
         limitOrderSelfMatchInstruction  |-> limitOrderSelfMatchInstruction.value,
         limitOrderPriceSlideInstruction |-> limitOrderPriceSlideInstruction.value,
         limitOrderMinQty                |-> limitOrderMinQty.value,
         limitOrderMaxFloorQty           |-> limitOrderMaxFloorQty.value,
         limitOrderMaxReplenishQtyRange  |-> limitOrderMaxReplenishQtyRange.value,
         limitOrderMaxReplenishTimeRange |-> limitOrderMaxReplenishTimeRange.value,
         limitOrderReferencePriceTarget  |-> limitOrderReferencePriceTarget.value,
         limitOrderExpireTime            |-> limitOrderExpireTime.value,
         limitOrderUserData              |-> limitOrderUserData.value,
         limitOrderMpid                  |-> limitOrderMpid.value,
         limitOrderMemberGroup           |-> limitOrderMemberGroup.value,
         limitOrderLocateBroker          |-> limitOrderLocateBroker.value ], limitOrderLocateBroker.rest)

(* Limit Order Message with each field marked present by fields before it there exactly where they say *)
SettleLimitOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.limitOrderSelfMatchScope = IF message.limitOrderPresenceBits % 2 = 1 THEN (IF message.limitOrderSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.limitOrderSelfMatchScope) ELSE << >>]
        settled2 == [settled1 EXCEPT !.limitOrderSelfMatchInstruction = IF (settled1.limitOrderPresenceBits \div 2) % 2 = 1 THEN (IF settled1.limitOrderSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.limitOrderSelfMatchInstruction) ELSE << >>]
        settled3 == [settled2 EXCEPT !.limitOrderPriceSlideInstruction = IF (settled2.limitOrderPresenceBits \div 4) % 2 = 1 THEN (IF settled2.limitOrderPriceSlideInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled2.limitOrderPriceSlideInstruction) ELSE << >>]
        settled4 == [settled3 EXCEPT !.limitOrderMinQty = IF (settled3.limitOrderPresenceBits \div 8) % 2 = 1 THEN (IF settled3.limitOrderMinQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.limitOrderMinQty) ELSE << >>]
        settled5 == [settled4 EXCEPT !.limitOrderMaxFloorQty = IF (settled4.limitOrderPresenceBits \div 16) % 2 = 1 THEN (IF settled4.limitOrderMaxFloorQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled4.limitOrderMaxFloorQty) ELSE << >>]
        settled6 == [settled5 EXCEPT !.limitOrderMaxReplenishQtyRange = IF (settled5.limitOrderPresenceBits \div 32) % 2 = 1 THEN (IF settled5.limitOrderMaxReplenishQtyRange = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled5.limitOrderMaxReplenishQtyRange) ELSE << >>]
        settled7 == [settled6 EXCEPT !.limitOrderMaxReplenishTimeRange = IF (settled6.limitOrderPresenceBits \div 64) % 2 = 1 THEN (IF settled6.limitOrderMaxReplenishTimeRange = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled6.limitOrderMaxReplenishTimeRange) ELSE << >>]
        settled8 == [settled7 EXCEPT !.limitOrderReferencePriceTarget = IF (settled7.limitOrderPresenceBits \div 128) % 2 = 1 THEN (IF settled7.limitOrderReferencePriceTarget = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled7.limitOrderReferencePriceTarget) ELSE << >>]
        settled9 == [settled8 EXCEPT !.limitOrderExpireTime = IF (settled8.limitOrderPresenceBits \div 256) % 2 = 1 THEN (IF settled8.limitOrderExpireTime = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled8.limitOrderExpireTime) ELSE << >>]
        settled10 == [settled9 EXCEPT !.limitOrderUserData = IF (settled9.limitOrderPresenceBits \div 512) % 2 = 1 THEN (IF settled9.limitOrderUserData = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled9.limitOrderUserData) ELSE << >>]
        settled11 == [settled10 EXCEPT !.limitOrderMpid = IF (settled10.limitOrderPresenceBits \div 1024) % 2 = 1 THEN (IF settled10.limitOrderMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled10.limitOrderMpid) ELSE << >>]
        settled12 == [settled11 EXCEPT !.limitOrderMemberGroup = IF (settled11.limitOrderPresenceBits \div 2048) % 2 = 1 THEN (IF settled11.limitOrderMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled11.limitOrderMemberGroup) ELSE << >>]
        settled13 == [settled12 EXCEPT !.limitOrderLocateBroker = IF (settled12.limitOrderPresenceBits \div 4096) % 2 = 1 THEN (IF settled12.limitOrderLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled12.limitOrderLocateBroker) ELSE << >>]
    IN  settled13

ZeroLimitOrderMessage ==
    SettleLimitOrderMessage([ limitOrderPresenceBits          |-> 0,
                              clOrdId                         |-> [i \in 1 .. 8 |-> 0],
                              orderQty                        |-> [i \in 1 .. 4 |-> 0],
                              limitOrderBitFields             |-> [i \in 1 .. 4 |-> 0],
                              symbolId                        |-> [i \in 1 .. 2 |-> 0],
                              price                           |-> [i \in 1 .. 8 |-> 0],
                              limitOrderSelfMatchScope        |-> << >>,
                              limitOrderSelfMatchInstruction  |-> << >>,
                              limitOrderPriceSlideInstruction |-> << >>,
                              limitOrderMinQty                |-> << >>,
                              limitOrderMaxFloorQty           |-> << >>,
                              limitOrderMaxReplenishQtyRange  |-> << >>,
                              limitOrderMaxReplenishTimeRange |-> << >>,
                              limitOrderReferencePriceTarget  |-> << >>,
                              limitOrderExpireTime            |-> << >>,
                              limitOrderUserData              |-> << >>,
                              limitOrderMpid                  |-> << >>,
                              limitOrderMemberGroup           |-> << >>,
                              limitOrderLocateBroker          |-> << >> ])

(* Limit Order Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitOrderMessage ==
    { ZeroLimitOrderMessage }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.orderQty = one]) : one \in Sample(4) }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderBitFields = one]) : one \in Sample(4) }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.symbolId = one]) : one \in Sample(2) }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.price = one]) : one \in Sample(8) }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 1, !.limitOrderSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 2, !.limitOrderSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 4, !.limitOrderPriceSlideInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 8, !.limitOrderMinQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 16, !.limitOrderMaxFloorQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 32, !.limitOrderMaxReplenishQtyRange = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 64, !.limitOrderMaxReplenishTimeRange = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 128, !.limitOrderReferencePriceTarget = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 256, !.limitOrderExpireTime = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 512, !.limitOrderUserData = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 1024, !.limitOrderMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 2048, !.limitOrderMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleLimitOrderMessage([ZeroLimitOrderMessage EXCEPT !.limitOrderPresenceBits = 4096, !.limitOrderLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Market Order Message                                                    *)
(***************************************************************************)

MarketOrderMessage ==
    [ marketOrderPresenceBits         : 0 .. 255,
      clOrdId                         : Sample(8),
      orderQty                        : Sample(4),
      marketOrderBitFields            : Sample(2),
      symbolId                        : Sample(2),
      marketOrderSelfMatchScope       : { << >> } \cup { <<held>> : held \in Sample(1) },
      marketOrderSelfMatchInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      marketOrderUserData             : { << >> } \cup { <<held>> : held \in Sample(8) },
      marketOrderMpid                 : { << >> } \cup { <<held>> : held \in Sample(4) },
      marketOrderMemberGroup          : { << >> } \cup { <<held>> : held \in Sample(2) },
      marketOrderLocateBroker         : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeMarketOrderMessage(message) ==
    EncodeUIntLE(message.marketOrderPresenceBits, 2)
        \o message.clOrdId
        \o message.orderQty
        \o message.marketOrderBitFields
        \o message.symbolId
        \o (IF message.marketOrderSelfMatchScope = << >> THEN << >> ELSE message.marketOrderSelfMatchScope[1])
        \o (IF message.marketOrderSelfMatchInstruction = << >> THEN << >> ELSE message.marketOrderSelfMatchInstruction[1])
        \o (IF message.marketOrderUserData = << >> THEN << >> ELSE message.marketOrderUserData[1])
        \o (IF message.marketOrderMpid = << >> THEN << >> ELSE message.marketOrderMpid[1])
        \o (IF message.marketOrderMemberGroup = << >> THEN << >> ELSE message.marketOrderMemberGroup[1])
        \o (IF message.marketOrderLocateBroker = << >> THEN << >> ELSE message.marketOrderLocateBroker[1])

DecodeMarketOrderMessage(bytes) ==
    LET marketOrderPresenceBits == ReadUIntLE(bytes, 2) IN IF ~marketOrderPresenceBits.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(marketOrderPresenceBits.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketOrderBitFields == ReadBytes(orderQty.rest, 2) IN IF ~marketOrderBitFields.ok THEN Fail ELSE
    LET symbolId == ReadBytes(marketOrderBitFields.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET marketOrderSelfMatchScope == ReadWhen(marketOrderPresenceBits.value % 2 = 1, ReadBytes(symbolId.rest, 1), symbolId.rest) IN IF ~marketOrderSelfMatchScope.ok THEN Fail ELSE
    LET marketOrderSelfMatchInstruction == ReadWhen((marketOrderPresenceBits.value \div 2) % 2 = 1, ReadBytes(marketOrderSelfMatchScope.rest, 1), marketOrderSelfMatchScope.rest) IN IF ~marketOrderSelfMatchInstruction.ok THEN Fail ELSE
    LET marketOrderUserData == ReadWhen((marketOrderPresenceBits.value \div 4) % 2 = 1, ReadBytes(marketOrderSelfMatchInstruction.rest, 8), marketOrderSelfMatchInstruction.rest) IN IF ~marketOrderUserData.ok THEN Fail ELSE
    LET marketOrderMpid == ReadWhen((marketOrderPresenceBits.value \div 8) % 2 = 1, ReadBytes(marketOrderUserData.rest, 4), marketOrderUserData.rest) IN IF ~marketOrderMpid.ok THEN Fail ELSE
    LET marketOrderMemberGroup == ReadWhen((marketOrderPresenceBits.value \div 16) % 2 = 1, ReadBytes(marketOrderMpid.rest, 2), marketOrderMpid.rest) IN IF ~marketOrderMemberGroup.ok THEN Fail ELSE
    LET marketOrderLocateBroker == ReadWhen((marketOrderPresenceBits.value \div 32) % 2 = 1, ReadBytes(marketOrderMemberGroup.rest, 4), marketOrderMemberGroup.rest) IN IF ~marketOrderLocateBroker.ok THEN Fail ELSE
    Ok([ marketOrderPresenceBits         |-> marketOrderPresenceBits.value,
         clOrdId                         |-> clOrdId.value,
         orderQty                        |-> orderQty.value,
         marketOrderBitFields            |-> marketOrderBitFields.value,
         symbolId                        |-> symbolId.value,
         marketOrderSelfMatchScope       |-> marketOrderSelfMatchScope.value,
         marketOrderSelfMatchInstruction |-> marketOrderSelfMatchInstruction.value,
         marketOrderUserData             |-> marketOrderUserData.value,
         marketOrderMpid                 |-> marketOrderMpid.value,
         marketOrderMemberGroup          |-> marketOrderMemberGroup.value,
         marketOrderLocateBroker         |-> marketOrderLocateBroker.value ], marketOrderLocateBroker.rest)

(* Market Order Message with each field marked present by fields before it there exactly where they say *)
SettleMarketOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.marketOrderSelfMatchScope = IF message.marketOrderPresenceBits % 2 = 1 THEN (IF message.marketOrderSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.marketOrderSelfMatchScope) ELSE << >>]
        settled2 == [settled1 EXCEPT !.marketOrderSelfMatchInstruction = IF (settled1.marketOrderPresenceBits \div 2) % 2 = 1 THEN (IF settled1.marketOrderSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.marketOrderSelfMatchInstruction) ELSE << >>]
        settled3 == [settled2 EXCEPT !.marketOrderUserData = IF (settled2.marketOrderPresenceBits \div 4) % 2 = 1 THEN (IF settled2.marketOrderUserData = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled2.marketOrderUserData) ELSE << >>]
        settled4 == [settled3 EXCEPT !.marketOrderMpid = IF (settled3.marketOrderPresenceBits \div 8) % 2 = 1 THEN (IF settled3.marketOrderMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled3.marketOrderMpid) ELSE << >>]
        settled5 == [settled4 EXCEPT !.marketOrderMemberGroup = IF (settled4.marketOrderPresenceBits \div 16) % 2 = 1 THEN (IF settled4.marketOrderMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled4.marketOrderMemberGroup) ELSE << >>]
        settled6 == [settled5 EXCEPT !.marketOrderLocateBroker = IF (settled5.marketOrderPresenceBits \div 32) % 2 = 1 THEN (IF settled5.marketOrderLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled5.marketOrderLocateBroker) ELSE << >>]
    IN  settled6

ZeroMarketOrderMessage ==
    SettleMarketOrderMessage([ marketOrderPresenceBits         |-> 0,
                               clOrdId                         |-> [i \in 1 .. 8 |-> 0],
                               orderQty                        |-> [i \in 1 .. 4 |-> 0],
                               marketOrderBitFields            |-> [i \in 1 .. 2 |-> 0],
                               symbolId                        |-> [i \in 1 .. 2 |-> 0],
                               marketOrderSelfMatchScope       |-> << >>,
                               marketOrderSelfMatchInstruction |-> << >>,
                               marketOrderUserData             |-> << >>,
                               marketOrderMpid                 |-> << >>,
                               marketOrderMemberGroup          |-> << >>,
                               marketOrderLocateBroker         |-> << >> ])

(* Market Order Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOrderMessage ==
    { ZeroMarketOrderMessage }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.marketOrderPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.orderQty = one]) : one \in Sample(4) }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.marketOrderBitFields = one]) : one \in Sample(2) }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.symbolId = one]) : one \in Sample(2) }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.marketOrderPresenceBits = 1, !.marketOrderSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.marketOrderPresenceBits = 2, !.marketOrderSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.marketOrderPresenceBits = 4, !.marketOrderUserData = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.marketOrderPresenceBits = 8, !.marketOrderMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.marketOrderPresenceBits = 16, !.marketOrderMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleMarketOrderMessage([ZeroMarketOrderMessage EXCEPT !.marketOrderPresenceBits = 32, !.marketOrderLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Cancel Order Message: 8 bytes                                           *)
(***************************************************************************)

CancelOrderMessage ==
    [ origClOrdId : Sample(8) ]

EncodeCancelOrderMessage(message) ==
    message.origClOrdId

DecodeCancelOrderMessage(bytes) ==
    LET origClOrdId == ReadBytes(bytes, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    Ok([ origClOrdId |-> origClOrdId.value ], origClOrdId.rest)

ZeroCancelOrderMessage ==
    [ origClOrdId |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.origClOrdId = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Order Message                                                    *)
(***************************************************************************)

ModifyOrderMessage ==
    [ modifyOrderPresenceBits : 0 .. 255,
      clOrdId                 : Sample(8),
      origClOrdId             : Sample(8),
      modifyOrderOrderQty     : { << >> } \cup { <<held>> : held \in Sample(4) },
      modifyOrderBitFields    : { << >> } \cup { <<held>> : held \in Sample(1) },
      modifyOrderLocateBroker : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeModifyOrderMessage(message) ==
    EncodeUIntLE(message.modifyOrderPresenceBits, 1)
        \o message.clOrdId
        \o message.origClOrdId
        \o (IF message.modifyOrderOrderQty = << >> THEN << >> ELSE message.modifyOrderOrderQty[1])
        \o (IF message.modifyOrderBitFields = << >> THEN << >> ELSE message.modifyOrderBitFields[1])
        \o (IF message.modifyOrderLocateBroker = << >> THEN << >> ELSE message.modifyOrderLocateBroker[1])

DecodeModifyOrderMessage(bytes) ==
    LET modifyOrderPresenceBits == ReadUIntLE(bytes, 1) IN IF ~modifyOrderPresenceBits.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(modifyOrderPresenceBits.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET modifyOrderOrderQty == ReadWhen(modifyOrderPresenceBits.value % 2 = 1, ReadBytes(origClOrdId.rest, 4), origClOrdId.rest) IN IF ~modifyOrderOrderQty.ok THEN Fail ELSE
    LET modifyOrderBitFields == ReadWhen((modifyOrderPresenceBits.value \div 2) % 2 = 1, ReadBytes(modifyOrderOrderQty.rest, 1), modifyOrderOrderQty.rest) IN IF ~modifyOrderBitFields.ok THEN Fail ELSE
    LET modifyOrderLocateBroker == ReadWhen((modifyOrderPresenceBits.value \div 4) % 2 = 1, ReadBytes(modifyOrderBitFields.rest, 4), modifyOrderBitFields.rest) IN IF ~modifyOrderLocateBroker.ok THEN Fail ELSE
    Ok([ modifyOrderPresenceBits |-> modifyOrderPresenceBits.value,
         clOrdId                 |-> clOrdId.value,
         origClOrdId             |-> origClOrdId.value,
         modifyOrderOrderQty     |-> modifyOrderOrderQty.value,
         modifyOrderBitFields    |-> modifyOrderBitFields.value,
         modifyOrderLocateBroker |-> modifyOrderLocateBroker.value ], modifyOrderLocateBroker.rest)

(* Modify Order Message with each field marked present by fields before it there exactly where they say *)
SettleModifyOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.modifyOrderOrderQty = IF message.modifyOrderPresenceBits % 2 = 1 THEN (IF message.modifyOrderOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE message.modifyOrderOrderQty) ELSE << >>]
        settled2 == [settled1 EXCEPT !.modifyOrderBitFields = IF (settled1.modifyOrderPresenceBits \div 2) % 2 = 1 THEN (IF settled1.modifyOrderBitFields = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.modifyOrderBitFields) ELSE << >>]
        settled3 == [settled2 EXCEPT !.modifyOrderLocateBroker = IF (settled2.modifyOrderPresenceBits \div 4) % 2 = 1 THEN (IF settled2.modifyOrderLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.modifyOrderLocateBroker) ELSE << >>]
    IN  settled3

ZeroModifyOrderMessage ==
    SettleModifyOrderMessage([ modifyOrderPresenceBits |-> 0,
                               clOrdId                 |-> [i \in 1 .. 8 |-> 0],
                               origClOrdId             |-> [i \in 1 .. 8 |-> 0],
                               modifyOrderOrderQty     |-> << >>,
                               modifyOrderBitFields    |-> << >>,
                               modifyOrderLocateBroker |-> << >> ])

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.modifyOrderPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.origClOrdId = one]) : one \in Sample(8) }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.modifyOrderPresenceBits = 1, !.modifyOrderOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.modifyOrderPresenceBits = 2, !.modifyOrderBitFields = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleModifyOrderMessage([ZeroModifyOrderMessage EXCEPT !.modifyOrderPresenceBits = 4, !.modifyOrderLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Replace Order Message                                                   *)
(***************************************************************************)

ReplaceOrderMessage ==
    [ replaceOrderPresenceBits          : 0 .. 255,
      clOrdId                           : Sample(8),
      origClOrdId                       : Sample(8),
      replaceOrderBitFields             : Sample(2),
      replaceOrderPrice                 : { << >> } \cup { <<held>> : held \in Sample(8) },
      replaceOrderOrderQty              : { << >> } \cup { <<held>> : held \in Sample(4) },
      replaceOrderMaxFloorQty           : { << >> } \cup { <<held>> : held \in Sample(4) },
      replaceOrderSelfMatchScope        : { << >> } \cup { <<held>> : held \in Sample(1) },
      replaceOrderSelfMatchInstruction  : { << >> } \cup { <<held>> : held \in Sample(1) },
      replaceOrderPriceSlideInstruction : { << >> } \cup { <<held>> : held \in Sample(1) },
      replaceOrderReferencePriceTarget  : { << >> } \cup { <<held>> : held \in Sample(2) },
      replaceOrderLocateBroker          : { << >> } \cup { <<held>> : held \in Sample(4) } ]

EncodeReplaceOrderMessage(message) ==
    EncodeUIntLE(message.replaceOrderPresenceBits, 2)
        \o message.clOrdId
        \o message.origClOrdId
        \o message.replaceOrderBitFields
        \o (IF message.replaceOrderPrice = << >> THEN << >> ELSE message.replaceOrderPrice[1])
        \o (IF message.replaceOrderOrderQty = << >> THEN << >> ELSE message.replaceOrderOrderQty[1])
        \o (IF message.replaceOrderMaxFloorQty = << >> THEN << >> ELSE message.replaceOrderMaxFloorQty[1])
        \o (IF message.replaceOrderSelfMatchScope = << >> THEN << >> ELSE message.replaceOrderSelfMatchScope[1])
        \o (IF message.replaceOrderSelfMatchInstruction = << >> THEN << >> ELSE message.replaceOrderSelfMatchInstruction[1])
        \o (IF message.replaceOrderPriceSlideInstruction = << >> THEN << >> ELSE message.replaceOrderPriceSlideInstruction[1])
        \o (IF message.replaceOrderReferencePriceTarget = << >> THEN << >> ELSE message.replaceOrderReferencePriceTarget[1])
        \o (IF message.replaceOrderLocateBroker = << >> THEN << >> ELSE message.replaceOrderLocateBroker[1])

DecodeReplaceOrderMessage(bytes) ==
    LET replaceOrderPresenceBits == ReadUIntLE(bytes, 2) IN IF ~replaceOrderPresenceBits.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(replaceOrderPresenceBits.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET replaceOrderBitFields == ReadBytes(origClOrdId.rest, 2) IN IF ~replaceOrderBitFields.ok THEN Fail ELSE
    LET replaceOrderPrice == ReadWhen(replaceOrderPresenceBits.value % 2 = 1, ReadBytes(replaceOrderBitFields.rest, 8), replaceOrderBitFields.rest) IN IF ~replaceOrderPrice.ok THEN Fail ELSE
    LET replaceOrderOrderQty == ReadWhen((replaceOrderPresenceBits.value \div 2) % 2 = 1, ReadBytes(replaceOrderPrice.rest, 4), replaceOrderPrice.rest) IN IF ~replaceOrderOrderQty.ok THEN Fail ELSE
    LET replaceOrderMaxFloorQty == ReadWhen((replaceOrderPresenceBits.value \div 4) % 2 = 1, ReadBytes(replaceOrderOrderQty.rest, 4), replaceOrderOrderQty.rest) IN IF ~replaceOrderMaxFloorQty.ok THEN Fail ELSE
    LET replaceOrderSelfMatchScope == ReadWhen((replaceOrderPresenceBits.value \div 8) % 2 = 1, ReadBytes(replaceOrderMaxFloorQty.rest, 1), replaceOrderMaxFloorQty.rest) IN IF ~replaceOrderSelfMatchScope.ok THEN Fail ELSE
    LET replaceOrderSelfMatchInstruction == ReadWhen((replaceOrderPresenceBits.value \div 16) % 2 = 1, ReadBytes(replaceOrderSelfMatchScope.rest, 1), replaceOrderSelfMatchScope.rest) IN IF ~replaceOrderSelfMatchInstruction.ok THEN Fail ELSE
    LET replaceOrderPriceSlideInstruction == ReadWhen((replaceOrderPresenceBits.value \div 32) % 2 = 1, ReadBytes(replaceOrderSelfMatchInstruction.rest, 1), replaceOrderSelfMatchInstruction.rest) IN IF ~replaceOrderPriceSlideInstruction.ok THEN Fail ELSE
    LET replaceOrderReferencePriceTarget == ReadWhen((replaceOrderPresenceBits.value \div 64) % 2 = 1, ReadBytes(replaceOrderPriceSlideInstruction.rest, 2), replaceOrderPriceSlideInstruction.rest) IN IF ~replaceOrderReferencePriceTarget.ok THEN Fail ELSE
    LET replaceOrderLocateBroker == ReadWhen((replaceOrderPresenceBits.value \div 128) % 2 = 1, ReadBytes(replaceOrderReferencePriceTarget.rest, 4), replaceOrderReferencePriceTarget.rest) IN IF ~replaceOrderLocateBroker.ok THEN Fail ELSE
    Ok([ replaceOrderPresenceBits          |-> replaceOrderPresenceBits.value,
         clOrdId                           |-> clOrdId.value,
         origClOrdId                       |-> origClOrdId.value,
         replaceOrderBitFields             |-> replaceOrderBitFields.value,
         replaceOrderPrice                 |-> replaceOrderPrice.value,
         replaceOrderOrderQty              |-> replaceOrderOrderQty.value,
         replaceOrderMaxFloorQty           |-> replaceOrderMaxFloorQty.value,
         replaceOrderSelfMatchScope        |-> replaceOrderSelfMatchScope.value,
         replaceOrderSelfMatchInstruction  |-> replaceOrderSelfMatchInstruction.value,
         replaceOrderPriceSlideInstruction |-> replaceOrderPriceSlideInstruction.value,
         replaceOrderReferencePriceTarget  |-> replaceOrderReferencePriceTarget.value,
         replaceOrderLocateBroker          |-> replaceOrderLocateBroker.value ], replaceOrderLocateBroker.rest)

(* Replace Order Message with each field marked present by fields before it there exactly where they say *)
SettleReplaceOrderMessage(message) ==
    LET settled1 == [message EXCEPT !.replaceOrderPrice = IF message.replaceOrderPresenceBits % 2 = 1 THEN (IF message.replaceOrderPrice = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE message.replaceOrderPrice) ELSE << >>]
        settled2 == [settled1 EXCEPT !.replaceOrderOrderQty = IF (settled1.replaceOrderPresenceBits \div 2) % 2 = 1 THEN (IF settled1.replaceOrderOrderQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled1.replaceOrderOrderQty) ELSE << >>]
        settled3 == [settled2 EXCEPT !.replaceOrderMaxFloorQty = IF (settled2.replaceOrderPresenceBits \div 4) % 2 = 1 THEN (IF settled2.replaceOrderMaxFloorQty = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled2.replaceOrderMaxFloorQty) ELSE << >>]
        settled4 == [settled3 EXCEPT !.replaceOrderSelfMatchScope = IF (settled3.replaceOrderPresenceBits \div 8) % 2 = 1 THEN (IF settled3.replaceOrderSelfMatchScope = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled3.replaceOrderSelfMatchScope) ELSE << >>]
        settled5 == [settled4 EXCEPT !.replaceOrderSelfMatchInstruction = IF (settled4.replaceOrderPresenceBits \div 16) % 2 = 1 THEN (IF settled4.replaceOrderSelfMatchInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled4.replaceOrderSelfMatchInstruction) ELSE << >>]
        settled6 == [settled5 EXCEPT !.replaceOrderPriceSlideInstruction = IF (settled5.replaceOrderPresenceBits \div 32) % 2 = 1 THEN (IF settled5.replaceOrderPriceSlideInstruction = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled5.replaceOrderPriceSlideInstruction) ELSE << >>]
        settled7 == [settled6 EXCEPT !.replaceOrderReferencePriceTarget = IF (settled6.replaceOrderPresenceBits \div 64) % 2 = 1 THEN (IF settled6.replaceOrderReferencePriceTarget = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled6.replaceOrderReferencePriceTarget) ELSE << >>]
        settled8 == [settled7 EXCEPT !.replaceOrderLocateBroker = IF (settled7.replaceOrderPresenceBits \div 128) % 2 = 1 THEN (IF settled7.replaceOrderLocateBroker = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE settled7.replaceOrderLocateBroker) ELSE << >>]
    IN  settled8

ZeroReplaceOrderMessage ==
    SettleReplaceOrderMessage([ replaceOrderPresenceBits          |-> 0,
                                clOrdId                           |-> [i \in 1 .. 8 |-> 0],
                                origClOrdId                       |-> [i \in 1 .. 8 |-> 0],
                                replaceOrderBitFields             |-> [i \in 1 .. 2 |-> 0],
                                replaceOrderPrice                 |-> << >>,
                                replaceOrderOrderQty              |-> << >>,
                                replaceOrderMaxFloorQty           |-> << >>,
                                replaceOrderSelfMatchScope        |-> << >>,
                                replaceOrderSelfMatchInstruction  |-> << >>,
                                replaceOrderPriceSlideInstruction |-> << >>,
                                replaceOrderReferencePriceTarget  |-> << >>,
                                replaceOrderLocateBroker          |-> << >> ])

(* Replace Order Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderMessage ==
    { ZeroReplaceOrderMessage }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.clOrdId = one]) : one \in Sample(8) }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.origClOrdId = one]) : one \in Sample(8) }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderBitFields = one]) : one \in Sample(2) }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = 1, !.replaceOrderPrice = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = 2, !.replaceOrderOrderQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = 4, !.replaceOrderMaxFloorQty = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = 8, !.replaceOrderSelfMatchScope = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = 16, !.replaceOrderSelfMatchInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = 32, !.replaceOrderPriceSlideInstruction = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = 64, !.replaceOrderReferencePriceTarget = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleReplaceOrderMessage([ZeroReplaceOrderMessage EXCEPT !.replaceOrderPresenceBits = 128, !.replaceOrderLocateBroker = one]) : one \in { <<held>> : held \in Sample(4) } }

(***************************************************************************)
(* Mass Cancel Message                                                     *)
(***************************************************************************)

MassCancelMessage ==
    [ massCancelPresenceBits : 0 .. 255,
      massCancelRequestId    : Sample(8),
      massCancelScope        : Sample(1),
      massCancelBitFields    : Sample(1),
      massCancelMpid         : { << >> } \cup { <<held>> : held \in Sample(4) },
      massCancelSenderComp   : { << >> } \cup { <<held>> : held \in Sample(8) },
      massCancelMemberGroup  : { << >> } \cup { <<held>> : held \in Sample(2) },
      massCancelClOrdId      : { << >> } \cup { <<held>> : held \in Sample(8) } ]

EncodeMassCancelMessage(message) ==
    EncodeUIntLE(message.massCancelPresenceBits, 1)
        \o message.massCancelRequestId
        \o message.massCancelScope
        \o message.massCancelBitFields
        \o (IF message.massCancelMpid = << >> THEN << >> ELSE message.massCancelMpid[1])
        \o (IF message.massCancelSenderComp = << >> THEN << >> ELSE message.massCancelSenderComp[1])
        \o (IF message.massCancelMemberGroup = << >> THEN << >> ELSE message.massCancelMemberGroup[1])
        \o (IF message.massCancelClOrdId = << >> THEN << >> ELSE message.massCancelClOrdId[1])

DecodeMassCancelMessage(bytes) ==
    LET massCancelPresenceBits == ReadUIntLE(bytes, 1) IN IF ~massCancelPresenceBits.ok THEN Fail ELSE
    LET massCancelRequestId == ReadBytes(massCancelPresenceBits.rest, 8) IN IF ~massCancelRequestId.ok THEN Fail ELSE
    LET massCancelScope == ReadBytes(massCancelRequestId.rest, 1) IN IF ~massCancelScope.ok THEN Fail ELSE
    LET massCancelBitFields == ReadBytes(massCancelScope.rest, 1) IN IF ~massCancelBitFields.ok THEN Fail ELSE
    LET massCancelMpid == ReadWhen(massCancelPresenceBits.value % 2 = 1, ReadBytes(massCancelBitFields.rest, 4), massCancelBitFields.rest) IN IF ~massCancelMpid.ok THEN Fail ELSE
    LET massCancelSenderComp == ReadWhen((massCancelPresenceBits.value \div 2) % 2 = 1, ReadBytes(massCancelMpid.rest, 8), massCancelMpid.rest) IN IF ~massCancelSenderComp.ok THEN Fail ELSE
    LET massCancelMemberGroup == ReadWhen((massCancelPresenceBits.value \div 4) % 2 = 1, ReadBytes(massCancelSenderComp.rest, 2), massCancelSenderComp.rest) IN IF ~massCancelMemberGroup.ok THEN Fail ELSE
    LET massCancelClOrdId == ReadWhen((massCancelPresenceBits.value \div 8) % 2 = 1, ReadBytes(massCancelMemberGroup.rest, 8), massCancelMemberGroup.rest) IN IF ~massCancelClOrdId.ok THEN Fail ELSE
    Ok([ massCancelPresenceBits |-> massCancelPresenceBits.value,
         massCancelRequestId    |-> massCancelRequestId.value,
         massCancelScope        |-> massCancelScope.value,
         massCancelBitFields    |-> massCancelBitFields.value,
         massCancelMpid         |-> massCancelMpid.value,
         massCancelSenderComp   |-> massCancelSenderComp.value,
         massCancelMemberGroup  |-> massCancelMemberGroup.value,
         massCancelClOrdId      |-> massCancelClOrdId.value ], massCancelClOrdId.rest)

(* Mass Cancel Message with each field marked present by fields before it there exactly where they say *)
SettleMassCancelMessage(message) ==
    LET settled1 == [message EXCEPT !.massCancelMpid = IF message.massCancelPresenceBits % 2 = 1 THEN (IF message.massCancelMpid = << >> THEN <<[i \in 1 .. 4 |-> 0]>> ELSE message.massCancelMpid) ELSE << >>]
        settled2 == [settled1 EXCEPT !.massCancelSenderComp = IF (settled1.massCancelPresenceBits \div 2) % 2 = 1 THEN (IF settled1.massCancelSenderComp = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled1.massCancelSenderComp) ELSE << >>]
        settled3 == [settled2 EXCEPT !.massCancelMemberGroup = IF (settled2.massCancelPresenceBits \div 4) % 2 = 1 THEN (IF settled2.massCancelMemberGroup = << >> THEN <<[i \in 1 .. 2 |-> 0]>> ELSE settled2.massCancelMemberGroup) ELSE << >>]
        settled4 == [settled3 EXCEPT !.massCancelClOrdId = IF (settled3.massCancelPresenceBits \div 8) % 2 = 1 THEN (IF settled3.massCancelClOrdId = << >> THEN <<[i \in 1 .. 8 |-> 0]>> ELSE settled3.massCancelClOrdId) ELSE << >>]
    IN  settled4

ZeroMassCancelMessage ==
    SettleMassCancelMessage([ massCancelPresenceBits |-> 0,
                              massCancelRequestId    |-> [i \in 1 .. 8 |-> 0],
                              massCancelScope        |-> [i \in 1 .. 1 |-> 0],
                              massCancelBitFields    |-> [i \in 1 .. 1 |-> 0],
                              massCancelMpid         |-> << >>,
                              massCancelSenderComp   |-> << >>,
                              massCancelMemberGroup  |-> << >>,
                              massCancelClOrdId      |-> << >> ])

(* Mass Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelMessage ==
    { ZeroMassCancelMessage }
        \cup { SettleMassCancelMessage([ZeroMassCancelMessage EXCEPT !.massCancelPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleMassCancelMessage([ZeroMassCancelMessage EXCEPT !.massCancelRequestId = one]) : one \in Sample(8) }
        \cup { SettleMassCancelMessage([ZeroMassCancelMessage EXCEPT !.massCancelScope = one]) : one \in Sample(1) }
        \cup { SettleMassCancelMessage([ZeroMassCancelMessage EXCEPT !.massCancelBitFields = one]) : one \in Sample(1) }
        \cup { SettleMassCancelMessage([ZeroMassCancelMessage EXCEPT !.massCancelPresenceBits = 1, !.massCancelMpid = one]) : one \in { <<held>> : held \in Sample(4) } }
        \cup { SettleMassCancelMessage([ZeroMassCancelMessage EXCEPT !.massCancelPresenceBits = 2, !.massCancelSenderComp = one]) : one \in { <<held>> : held \in Sample(8) } }
        \cup { SettleMassCancelMessage([ZeroMassCancelMessage EXCEPT !.massCancelPresenceBits = 4, !.massCancelMemberGroup = one]) : one \in { <<held>> : held \in Sample(2) } }
        \cup { SettleMassCancelMessage([ZeroMassCancelMessage EXCEPT !.massCancelPresenceBits = 8, !.massCancelClOrdId = one]) : one \in { <<held>> : held \in Sample(8) } }

(***************************************************************************)
(* Unsequenced Message, selected by Message Type                           *)
(***************************************************************************)

LimitOrderMessageCode == 76  \* 0x4c
MarketOrderMessageCode == 65  \* 0x41
CancelOrderMessageCode == 67  \* 0x43
ModifyOrderMessageCode == 77  \* 0x4d
ReplaceOrderMessageCode == 82  \* 0x52
MassCancelMessageCode == 86  \* 0x56

UnsequencedMessage ==
    [ tag : {LimitOrderMessageCode}, body : LimitOrderMessage ]
        \cup [ tag : {MarketOrderMessageCode}, body : MarketOrderMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {ReplaceOrderMessageCode}, body : ReplaceOrderMessage ]
        \cup [ tag : {MassCancelMessageCode}, body : MassCancelMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = LimitOrderMessageCode -> EncodeLimitOrderMessage(message.body)
      [] message.tag = MarketOrderMessageCode -> EncodeMarketOrderMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = ReplaceOrderMessageCode -> EncodeReplaceOrderMessage(message.body)
      [] message.tag = MassCancelMessageCode -> EncodeMassCancelMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = LimitOrderMessageCode -> DecodeLimitOrderMessage(bytes)
              [] tag = MarketOrderMessageCode -> DecodeMarketOrderMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = ReplaceOrderMessageCode -> DecodeReplaceOrderMessage(bytes)
              [] tag = MassCancelMessageCode -> DecodeMassCancelMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> LimitOrderMessageCode, body |-> ZeroLimitOrderMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> LimitOrderMessageCode, body |-> one] : one \in CheckedLimitOrderMessage }
        \cup { [tag |-> MarketOrderMessageCode, body |-> one] : one \in CheckedMarketOrderMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> ReplaceOrderMessageCode, body |-> one] : one \in CheckedReplaceOrderMessage }
        \cup { [tag |-> MassCancelMessageCode, body |-> one] : one \in CheckedMassCancelMessage }

(***************************************************************************)
(* Tcp Unsequenced Message                                                 *)
(***************************************************************************)

TcpUnsequencedMessage ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeTcpUnsequencedMessage(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeTcpUnsequencedMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(messageType.value, messageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroTcpUnsequencedMessage ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Tcp Unsequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedTcpUnsequencedMessage ==
    { ZeroTcpUnsequencedMessage }
        \cup { [ZeroTcpUnsequencedMessage EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Payload, selected by Packet Type                                 *)
(***************************************************************************)

LogonRequestPacketCode == 53  \* 0x35
TcpUnsequencedMessageCode == 54  \* 0x36

ClientPayload ==
    [ tag : {LogonRequestPacketCode}, body : LogonRequestPacket ]
        \cup [ tag : {TcpUnsequencedMessageCode}, body : TcpUnsequencedMessage ]

EncodeClientPayload(message) ==
    CASE message.tag = LogonRequestPacketCode -> EncodeLogonRequestPacket(message.body)
      [] message.tag = TcpUnsequencedMessageCode -> EncodeTcpUnsequencedMessage(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonRequestPacketCode -> DecodeLogonRequestPacket(bytes)
              [] tag = TcpUnsequencedMessageCode -> DecodeTcpUnsequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> LogonRequestPacketCode, body |-> ZeroLogonRequestPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> LogonRequestPacketCode, body |-> one] : one \in CheckedLogonRequestPacket }
        \cup { [tag |-> TcpUnsequencedMessageCode, body |-> one] : one \in CheckedTcpUnsequencedMessage }

(***************************************************************************)
(* Client Rake Tcp Message, framed by Message Length                       *)
(***************************************************************************)

ClientRakeTcpMessage ==
    [ clientPayload : ClientPayload ]

EncodeClientRakeTcpMessageBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeClientRakeTcpMessage(message) ==
    LET body == EncodeClientRakeTcpMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeClientRakeTcpMessageBody(bytes) ==
    LET packetType == ReadUIntBE(bytes, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(packetType.value, packetType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientRakeTcpMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientRakeTcpMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientRakeTcpMessage ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Rake Tcp Message at zero, then each field in turn at the values it is checked at *)
CheckedClientRakeTcpMessage ==
    { ZeroClientRakeTcpMessage }
        \cup { [ZeroClientRakeTcpMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Rake Tcp Message, written one after another *)
RECURSIVE EncodeClientRakeTcpMessageList(_)
EncodeClientRakeTcpMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientRakeTcpMessage(Head(messages)) \o EncodeClientRakeTcpMessageList(Tail(messages))

(* As many Client Rake Tcp Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientRakeTcpMessageAll(_)
ReadClientRakeTcpMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientRakeTcpMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientRakeTcpMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Rake Tcp Message of each kind, for the lists that carry them *)
OneClientRakeTcpMessage ==
    { [ZeroClientRakeTcpMessage EXCEPT !.clientPayload = [tag |-> LogonRequestPacketCode, body |-> ZeroLogonRequestPacket]],
      [ZeroClientRakeTcpMessage EXCEPT !.clientPayload = [tag |-> TcpUnsequencedMessageCode, body |-> ZeroTcpUnsequencedMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientRakeTcpMessage : SampleLists(OneClientRakeTcpMessage) ]

EncodeClientPacket(message) ==
    EncodeClientRakeTcpMessageList(message.clientRakeTcpMessage)

DecodeClientPacket(bytes) ==
    LET clientRakeTcpMessage == ReadClientRakeTcpMessageAll(bytes) IN IF ~clientRakeTcpMessage.ok THEN Fail ELSE
    Ok([ clientRakeTcpMessage |-> clientRakeTcpMessage.value ], clientRakeTcpMessage.rest)

ZeroClientPacket ==
    [ clientRakeTcpMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientRakeTcpMessage = one] : one \in SampleLists(OneClientRakeTcpMessage) }

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

(* Every Logon Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequestPacket ==
    \A message \in CheckedLogonRequestPacket :
        LET read == DecodeLogonRequestPacket(EncodeLogonRequestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Limit Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitOrderMessage ==
    \A message \in CheckedLimitOrderMessage :
        LET read == DecodeLimitOrderMessage(EncodeLimitOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOrderMessage ==
    \A message \in CheckedMarketOrderMessage :
        LET read == DecodeMarketOrderMessage(EncodeMarketOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderMessage ==
    \A message \in CheckedCancelOrderMessage :
        LET read == DecodeCancelOrderMessage(EncodeCancelOrderMessage(message))
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

(* Every Replace Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrderMessage ==
    \A message \in CheckedReplaceOrderMessage :
        LET read == DecodeReplaceOrderMessage(EncodeReplaceOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelMessage ==
    \A message \in CheckedMassCancelMessage :
        LET read == DecodeMassCancelMessage(EncodeMassCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Unsequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpUnsequencedMessage ==
    \A message \in CheckedTcpUnsequencedMessage :
        LET read == DecodeTcpUnsequencedMessage(EncodeTcpUnsequencedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Rake Tcp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientRakeTcpMessage ==
    \A message \in CheckedClientRakeTcpMessage :
        LET read == DecodeClientRakeTcpMessage(EncodeClientRakeTcpMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Unsequenced Message is selected by the Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET sent == EncodeUnsequencedMessage(message)
            read == DecodeUnsequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Payload is selected by the Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET sent == EncodeClientPayload(message)
            read == DecodeClientPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesClientRakeTcpMessage ==
    \A message \in CheckedClientRakeTcpMessage :
        LET bytes == EncodeClientRakeTcpMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
