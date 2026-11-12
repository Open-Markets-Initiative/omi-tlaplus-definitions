--------------- MODULE Spectra_OrdersLogIncremental_v9_12_0 ----------------
(***************************************************************************)
(* Moscow Exchange SIMBA Spectra Orders Log Incremental v9.12.0            *)
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
(* Note: Message is of no one width: each is read by its own fields, and   *)
(* since every reading of it takes at least 8 bytes off the reader the run *)
(* ends where the data does.                                               *)
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
(* Market Data Packet Header: 16 bytes                                     *)
(***************************************************************************)

MarketDataPacketHeader ==
    [ msgSeqNum   : Sample(4),
      msgSize     : Sample(2),
      msgFlags    : Sample(2),
      sendingTime : Sample(8) ]

EncodeMarketDataPacketHeader(message) ==
    message.msgSeqNum
        \o message.msgSize
        \o message.msgFlags
        \o message.sendingTime

DecodeMarketDataPacketHeader(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET msgSize == ReadBytes(msgSeqNum.rest, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgFlags == ReadBytes(msgSize.rest, 2) IN IF ~msgFlags.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgFlags.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         msgSize     |-> msgSize.value,
         msgFlags    |-> msgFlags.value,
         sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroMarketDataPacketHeader ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      msgSize     |-> [i \in 1 .. 2 |-> 0],
      msgFlags    |-> [i \in 1 .. 2 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Market Data Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataPacketHeader ==
    { ZeroMarketDataPacketHeader }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgSize = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgFlags = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Incremental Packet Header: 12 bytes                                     *)
(***************************************************************************)

IncrementalPacketHeader ==
    [ transactTime             : Sample(8),
      exchangeTradingSessionId : Sample(4) ]

EncodeIncrementalPacketHeader(message) ==
    message.transactTime
        \o message.exchangeTradingSessionId

DecodeIncrementalPacketHeader(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET exchangeTradingSessionId == ReadBytes(transactTime.rest, 4) IN IF ~exchangeTradingSessionId.ok THEN Fail ELSE
    Ok([ transactTime             |-> transactTime.value,
         exchangeTradingSessionId |-> exchangeTradingSessionId.value ], exchangeTradingSessionId.rest)

ZeroIncrementalPacketHeader ==
    [ transactTime             |-> [i \in 1 .. 8 |-> 0],
      exchangeTradingSessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Incremental Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalPacketHeader ==
    { ZeroIncrementalPacketHeader }
        \cup { [ZeroIncrementalPacketHeader EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalPacketHeader EXCEPT !.exchangeTradingSessionId = one] : one \in Sample(4) }

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
(* Best Prices Message No M D Entries Group: 36 bytes                      *)
(***************************************************************************)

BestPricesMessageNoMDEntriesGroup ==
    [ mktBidPx     : Sample(8),
      mktOfferPx   : Sample(8),
      mktBidSize   : Sample(8),
      mktOfferSize : Sample(8),
      securityId   : Sample(4) ]

EncodeBestPricesMessageNoMDEntriesGroup(message) ==
    message.mktBidPx
        \o message.mktOfferPx
        \o message.mktBidSize
        \o message.mktOfferSize
        \o message.securityId

DecodeBestPricesMessageNoMDEntriesGroup(bytes) ==
    LET mktBidPx == ReadBytes(bytes, 8) IN IF ~mktBidPx.ok THEN Fail ELSE
    LET mktOfferPx == ReadBytes(mktBidPx.rest, 8) IN IF ~mktOfferPx.ok THEN Fail ELSE
    LET mktBidSize == ReadBytes(mktOfferPx.rest, 8) IN IF ~mktBidSize.ok THEN Fail ELSE
    LET mktOfferSize == ReadBytes(mktBidSize.rest, 8) IN IF ~mktOfferSize.ok THEN Fail ELSE
    LET securityId == ReadBytes(mktOfferSize.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ mktBidPx     |-> mktBidPx.value,
         mktOfferPx   |-> mktOfferPx.value,
         mktBidSize   |-> mktBidSize.value,
         mktOfferSize |-> mktOfferSize.value,
         securityId   |-> securityId.value ], securityId.rest)

ZeroBestPricesMessageNoMDEntriesGroup ==
    [ mktBidPx     |-> [i \in 1 .. 8 |-> 0],
      mktOfferPx   |-> [i \in 1 .. 8 |-> 0],
      mktBidSize   |-> [i \in 1 .. 8 |-> 0],
      mktOfferSize |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 4 |-> 0] ]

(* Best Prices Message No M D Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedBestPricesMessageNoMDEntriesGroup ==
    { ZeroBestPricesMessageNoMDEntriesGroup }
        \cup { [ZeroBestPricesMessageNoMDEntriesGroup EXCEPT !.mktBidPx = one] : one \in Sample(8) }
        \cup { [ZeroBestPricesMessageNoMDEntriesGroup EXCEPT !.mktOfferPx = one] : one \in Sample(8) }
        \cup { [ZeroBestPricesMessageNoMDEntriesGroup EXCEPT !.mktBidSize = one] : one \in Sample(8) }
        \cup { [ZeroBestPricesMessageNoMDEntriesGroup EXCEPT !.mktOfferSize = one] : one \in Sample(8) }
        \cup { [ZeroBestPricesMessageNoMDEntriesGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Best Prices Message No M D Entries Group, written one after another *)
RECURSIVE EncodeBestPricesMessageNoMDEntriesGroupList(_)
EncodeBestPricesMessageNoMDEntriesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBestPricesMessageNoMDEntriesGroup(Head(messages)) \o EncodeBestPricesMessageNoMDEntriesGroupList(Tail(messages))

(* As many Best Prices Message No M D Entries Group as the field that counts them says *)
RECURSIVE ReadBestPricesMessageNoMDEntriesGroupList(_, _)
ReadBestPricesMessageNoMDEntriesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBestPricesMessageNoMDEntriesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBestPricesMessageNoMDEntriesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Best Prices Message No M D Entries Group of each kind, for the lists that carry them *)
OneBestPricesMessageNoMDEntriesGroup == { ZeroBestPricesMessageNoMDEntriesGroup }

(***************************************************************************)
(* Best Prices Message No M D Entries Groups                               *)
(***************************************************************************)

BestPricesMessageNoMDEntriesGroups ==
    [ blockLength                       : Sample(2),
      bestPricesMessageNoMDEntriesGroup : SampleLists(OneBestPricesMessageNoMDEntriesGroup) ]

EncodeBestPricesMessageNoMDEntriesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.bestPricesMessageNoMDEntriesGroup), 1)
        \o EncodeBestPricesMessageNoMDEntriesGroupList(message.bestPricesMessageNoMDEntriesGroup)

DecodeBestPricesMessageNoMDEntriesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET bestPricesMessageNoMDEntriesGroup == ReadBestPricesMessageNoMDEntriesGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~bestPricesMessageNoMDEntriesGroup.ok THEN Fail ELSE
    Ok([ blockLength                       |-> blockLength.value,
         bestPricesMessageNoMDEntriesGroup |-> bestPricesMessageNoMDEntriesGroup.value ], bestPricesMessageNoMDEntriesGroup.rest)

ZeroBestPricesMessageNoMDEntriesGroups ==
    [ blockLength                       |-> [i \in 1 .. 2 |-> 0],
      bestPricesMessageNoMDEntriesGroup |-> << >> ]

(* Best Prices Message No M D Entries Groups at zero, then each field in turn at the values it is checked at *)
CheckedBestPricesMessageNoMDEntriesGroups ==
    { ZeroBestPricesMessageNoMDEntriesGroups }
        \cup { [ZeroBestPricesMessageNoMDEntriesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroBestPricesMessageNoMDEntriesGroups EXCEPT !.bestPricesMessageNoMDEntriesGroup = one] : one \in SampleLists(OneBestPricesMessageNoMDEntriesGroup) }

(***************************************************************************)
(* Best Prices Message                                                     *)
(***************************************************************************)

BestPricesMessage ==
    [ bestPricesMessageNoMDEntriesGroups : BestPricesMessageNoMDEntriesGroups ]

EncodeBestPricesMessage(message) ==
    EncodeBestPricesMessageNoMDEntriesGroups(message.bestPricesMessageNoMDEntriesGroups)

DecodeBestPricesMessage(bytes) ==
    LET bestPricesMessageNoMDEntriesGroups == DecodeBestPricesMessageNoMDEntriesGroups(bytes) IN IF ~bestPricesMessageNoMDEntriesGroups.ok THEN Fail ELSE
    Ok([ bestPricesMessageNoMDEntriesGroups |-> bestPricesMessageNoMDEntriesGroups.value ], bestPricesMessageNoMDEntriesGroups.rest)

ZeroBestPricesMessage ==
    [ bestPricesMessageNoMDEntriesGroups |-> ZeroBestPricesMessageNoMDEntriesGroups ]

(* Best Prices Message at zero, then each field in turn at the values it is checked at *)
CheckedBestPricesMessage ==
    { ZeroBestPricesMessage }
        \cup { [ZeroBestPricesMessage EXCEPT !.bestPricesMessageNoMDEntriesGroups = one] : one \in CheckedBestPricesMessageNoMDEntriesGroups }

(***************************************************************************)
(* Empty Book Message: 4 bytes                                             *)
(***************************************************************************)

EmptyBookMessage ==
    [ lastMsgSeqNumProcessedUInt32NullOptional : Sample(4) ]

EncodeEmptyBookMessage(message) ==
    message.lastMsgSeqNumProcessedUInt32NullOptional

DecodeEmptyBookMessage(bytes) ==
    LET lastMsgSeqNumProcessedUInt32NullOptional == ReadBytes(bytes, 4) IN IF ~lastMsgSeqNumProcessedUInt32NullOptional.ok THEN Fail ELSE
    Ok([ lastMsgSeqNumProcessedUInt32NullOptional |-> lastMsgSeqNumProcessedUInt32NullOptional.value ], lastMsgSeqNumProcessedUInt32NullOptional.rest)

ZeroEmptyBookMessage ==
    [ lastMsgSeqNumProcessedUInt32NullOptional |-> [i \in 1 .. 4 |-> 0] ]

(* Empty Book Message at zero, then each field in turn at the values it is checked at *)
CheckedEmptyBookMessage ==
    { ZeroEmptyBookMessage }
        \cup { [ZeroEmptyBookMessage EXCEPT !.lastMsgSeqNumProcessedUInt32NullOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Update Message: 50 bytes                                          *)
(***************************************************************************)

OrderUpdateMessage ==
    [ mdEntryIdInt64    : Sample(8),
      mdEntryPxDecimal5 : Sample(8),
      mdEntrySizeInt64  : Sample(8),
      mdFlags           : Sample(8),
      mdFlags2          : Sample(8),
      securityId        : Sample(4),
      rptSeq            : Sample(4),
      mdUpdateAction    : Sample(1),
      mdEntryType       : Sample(1) ]

EncodeOrderUpdateMessage(message) ==
    message.mdEntryIdInt64
        \o message.mdEntryPxDecimal5
        \o message.mdEntrySizeInt64
        \o message.mdFlags
        \o message.mdFlags2
        \o message.securityId
        \o message.rptSeq
        \o message.mdUpdateAction
        \o message.mdEntryType

DecodeOrderUpdateMessage(bytes) ==
    LET mdEntryIdInt64 == ReadBytes(bytes, 8) IN IF ~mdEntryIdInt64.ok THEN Fail ELSE
    LET mdEntryPxDecimal5 == ReadBytes(mdEntryIdInt64.rest, 8) IN IF ~mdEntryPxDecimal5.ok THEN Fail ELSE
    LET mdEntrySizeInt64 == ReadBytes(mdEntryPxDecimal5.rest, 8) IN IF ~mdEntrySizeInt64.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(mdEntrySizeInt64.rest, 8) IN IF ~mdFlags.ok THEN Fail ELSE
    LET mdFlags2 == ReadBytes(mdFlags.rest, 8) IN IF ~mdFlags2.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdFlags2.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(rptSeq.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    Ok([ mdEntryIdInt64    |-> mdEntryIdInt64.value,
         mdEntryPxDecimal5 |-> mdEntryPxDecimal5.value,
         mdEntrySizeInt64  |-> mdEntrySizeInt64.value,
         mdFlags           |-> mdFlags.value,
         mdFlags2          |-> mdFlags2.value,
         securityId        |-> securityId.value,
         rptSeq            |-> rptSeq.value,
         mdUpdateAction    |-> mdUpdateAction.value,
         mdEntryType       |-> mdEntryType.value ], mdEntryType.rest)

ZeroOrderUpdateMessage ==
    [ mdEntryIdInt64    |-> [i \in 1 .. 8 |-> 0],
      mdEntryPxDecimal5 |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeInt64  |-> [i \in 1 .. 8 |-> 0],
      mdFlags           |-> [i \in 1 .. 8 |-> 0],
      mdFlags2          |-> [i \in 1 .. 8 |-> 0],
      securityId        |-> [i \in 1 .. 4 |-> 0],
      rptSeq            |-> [i \in 1 .. 4 |-> 0],
      mdUpdateAction    |-> [i \in 1 .. 1 |-> 0],
      mdEntryType       |-> [i \in 1 .. 1 |-> 0] ]

(* Order Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderUpdateMessage ==
    { ZeroOrderUpdateMessage }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdEntryIdInt64 = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdEntryPxDecimal5 = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdEntrySizeInt64 = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdFlags = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdFlags2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdEntryType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Execution Message: 74 bytes                                       *)
(***************************************************************************)

OrderExecutionMessage ==
    [ mdEntryIdInt64                : Sample(8),
      mdEntryPxDecimal5NullOptional : Sample(8),
      mdEntrySizeInt64NullOptional  : Sample(8),
      lastPx                        : Sample(8),
      lastQty                       : Sample(8),
      tradeIdInt64                  : Sample(8),
      mdFlags                       : Sample(8),
      mdFlags2                      : Sample(8),
      securityId                    : Sample(4),
      rptSeq                        : Sample(4),
      mdUpdateAction                : Sample(1),
      mdEntryType                   : Sample(1) ]

EncodeOrderExecutionMessage(message) ==
    message.mdEntryIdInt64
        \o message.mdEntryPxDecimal5NullOptional
        \o message.mdEntrySizeInt64NullOptional
        \o message.lastPx
        \o message.lastQty
        \o message.tradeIdInt64
        \o message.mdFlags
        \o message.mdFlags2
        \o message.securityId
        \o message.rptSeq
        \o message.mdUpdateAction
        \o message.mdEntryType

DecodeOrderExecutionMessage(bytes) ==
    LET mdEntryIdInt64 == ReadBytes(bytes, 8) IN IF ~mdEntryIdInt64.ok THEN Fail ELSE
    LET mdEntryPxDecimal5NullOptional == ReadBytes(mdEntryIdInt64.rest, 8) IN IF ~mdEntryPxDecimal5NullOptional.ok THEN Fail ELSE
    LET mdEntrySizeInt64NullOptional == ReadBytes(mdEntryPxDecimal5NullOptional.rest, 8) IN IF ~mdEntrySizeInt64NullOptional.ok THEN Fail ELSE
    LET lastPx == ReadBytes(mdEntrySizeInt64NullOptional.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET tradeIdInt64 == ReadBytes(lastQty.rest, 8) IN IF ~tradeIdInt64.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(tradeIdInt64.rest, 8) IN IF ~mdFlags.ok THEN Fail ELSE
    LET mdFlags2 == ReadBytes(mdFlags.rest, 8) IN IF ~mdFlags2.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdFlags2.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(rptSeq.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    Ok([ mdEntryIdInt64                |-> mdEntryIdInt64.value,
         mdEntryPxDecimal5NullOptional |-> mdEntryPxDecimal5NullOptional.value,
         mdEntrySizeInt64NullOptional  |-> mdEntrySizeInt64NullOptional.value,
         lastPx                        |-> lastPx.value,
         lastQty                       |-> lastQty.value,
         tradeIdInt64                  |-> tradeIdInt64.value,
         mdFlags                       |-> mdFlags.value,
         mdFlags2                      |-> mdFlags2.value,
         securityId                    |-> securityId.value,
         rptSeq                        |-> rptSeq.value,
         mdUpdateAction                |-> mdUpdateAction.value,
         mdEntryType                   |-> mdEntryType.value ], mdEntryType.rest)

ZeroOrderExecutionMessage ==
    [ mdEntryIdInt64                |-> [i \in 1 .. 8 |-> 0],
      mdEntryPxDecimal5NullOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeInt64NullOptional  |-> [i \in 1 .. 8 |-> 0],
      lastPx                        |-> [i \in 1 .. 8 |-> 0],
      lastQty                       |-> [i \in 1 .. 8 |-> 0],
      tradeIdInt64                  |-> [i \in 1 .. 8 |-> 0],
      mdFlags                       |-> [i \in 1 .. 8 |-> 0],
      mdFlags2                      |-> [i \in 1 .. 8 |-> 0],
      securityId                    |-> [i \in 1 .. 4 |-> 0],
      rptSeq                        |-> [i \in 1 .. 4 |-> 0],
      mdUpdateAction                |-> [i \in 1 .. 1 |-> 0],
      mdEntryType                   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdEntryIdInt64 = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdEntryPxDecimal5NullOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdEntrySizeInt64NullOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeIdInt64 = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdFlags = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdFlags2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdEntryType = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
SequenceResetMessageCode == 2  \* 0x02
BestPricesMessageCode == 14  \* 0x0e
EmptyBookMessageCode == 4  \* 0x04
OrderUpdateMessageCode == 15  \* 0x0f
OrderExecutionMessageCode == 16  \* 0x10

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {BestPricesMessageCode}, body : BestPricesMessage ]
        \cup [ tag : {EmptyBookMessageCode}, body : EmptyBookMessage ]
        \cup [ tag : {OrderUpdateMessageCode}, body : OrderUpdateMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = BestPricesMessageCode -> EncodeBestPricesMessage(message.body)
      [] message.tag = EmptyBookMessageCode -> EncodeEmptyBookMessage(message.body)
      [] message.tag = OrderUpdateMessageCode -> EncodeOrderUpdateMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = BestPricesMessageCode -> DecodeBestPricesMessage(bytes)
              [] tag = EmptyBookMessageCode -> DecodeEmptyBookMessage(bytes)
              [] tag = OrderUpdateMessageCode -> DecodeOrderUpdateMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> BestPricesMessageCode, body |-> one] : one \in CheckedBestPricesMessage }
        \cup { [tag |-> EmptyBookMessageCode, body |-> one] : one \in CheckedEmptyBookMessage }
        \cup { [tag |-> OrderUpdateMessageCode, body |-> one] : one \in CheckedOrderUpdateMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(2) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BestPricesMessageCode, body |-> ZeroBestPricesMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EmptyBookMessageCode, body |-> ZeroEmptyBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderUpdateMessageCode, body |-> ZeroOrderUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutionMessageCode, body |-> ZeroOrderExecutionMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ marketDataPacketHeader  : MarketDataPacketHeader,
      incrementalPacketHeader : IncrementalPacketHeader,
      message                 : SampleLists(OneMessage) ]

EncodeUdpPacket(message) ==
    EncodeMarketDataPacketHeader(message.marketDataPacketHeader)
        \o EncodeIncrementalPacketHeader(message.incrementalPacketHeader)
        \o EncodeMessageList(message.message)

DecodeUdpPacket(bytes) ==
    LET marketDataPacketHeader == DecodeMarketDataPacketHeader(bytes) IN IF ~marketDataPacketHeader.ok THEN Fail ELSE
    LET incrementalPacketHeader == DecodeIncrementalPacketHeader(marketDataPacketHeader.rest) IN IF ~incrementalPacketHeader.ok THEN Fail ELSE
    LET message == ReadMessageAll(incrementalPacketHeader.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ marketDataPacketHeader  |-> marketDataPacketHeader.value,
         incrementalPacketHeader |-> incrementalPacketHeader.value,
         message                 |-> message.value ], message.rest)

ZeroUdpPacket ==
    [ marketDataPacketHeader  |-> ZeroMarketDataPacketHeader,
      incrementalPacketHeader |-> ZeroIncrementalPacketHeader,
      message                 |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.marketDataPacketHeader = one] : one \in CheckedMarketDataPacketHeader }
        \cup { [ZeroUdpPacket EXCEPT !.incrementalPacketHeader = one] : one \in CheckedIncrementalPacketHeader }
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

(* Every Market Data Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataPacketHeader ==
    \A message \in CheckedMarketDataPacketHeader :
        LET read == DecodeMarketDataPacketHeader(EncodeMarketDataPacketHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalPacketHeader ==
    \A message \in CheckedIncrementalPacketHeader :
        LET read == DecodeIncrementalPacketHeader(EncodeIncrementalPacketHeader(message))
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

(* Every Best Prices Message No M D Entries Group decodes back to what was encoded, and leaves nothing over *)
RoundTripBestPricesMessageNoMDEntriesGroup ==
    \A message \in CheckedBestPricesMessageNoMDEntriesGroup :
        LET read == DecodeBestPricesMessageNoMDEntriesGroup(EncodeBestPricesMessageNoMDEntriesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Prices Message No M D Entries Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripBestPricesMessageNoMDEntriesGroups ==
    \A message \in CheckedBestPricesMessageNoMDEntriesGroups :
        LET read == DecodeBestPricesMessageNoMDEntriesGroups(EncodeBestPricesMessageNoMDEntriesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Prices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestPricesMessage ==
    \A message \in CheckedBestPricesMessage :
        LET read == DecodeBestPricesMessage(EncodeBestPricesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Empty Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmptyBookMessage ==
    \A message \in CheckedEmptyBookMessage :
        LET read == DecodeEmptyBookMessage(EncodeEmptyBookMessage(message))
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

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
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
