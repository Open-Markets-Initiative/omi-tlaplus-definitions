--------------- MODULE Spectra_OrdersLogReplay_v8_0_0_Server ---------------
(***************************************************************************)
(* Moscow Exchange SIMBA Spectra Orders Log Historical Replay v8.0.0       *)
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
(* Note: Server Replay Message is of no one width: each is read by its own *)
(* fields, and since every reading of it takes at least 8 bytes off the    *)
(* reader the run ends where the data does.                                *)
(*                                                                         *)
(* Note: Server Replay fills what is left of the frame Msg Size states,    *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Incremental Packet is some bits of Msg Flags, which is read as    *)
(* the number it is: those bits say which Server Body follows, so they are *)
(* the choice's own, and the record keeps the rest of the set. The set is  *)
(* written from the two together, so every bit of it is stated once.       *)
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
(* Logout Message: 256 bytes                                               *)
(***************************************************************************)

LogoutMessage ==
    [ text : Sample(256) ]

EncodeLogoutMessage(message) ==
    message.text

DecodeLogoutMessage(bytes) ==
    LET text == ReadBytes(bytes, 256) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroLogoutMessage ==
    [ text |-> [i \in 1 .. 256 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.text = one] : one \in Sample(256) }

(***************************************************************************)
(* Server Session Payload, selected by Template Id                         *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
LogonMessageCode == 1000  \* 0x3e8
LogoutMessageCode == 1001  \* 0x3e9

ServerSessionPayload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogonMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]

EncodeServerSessionPayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = LogonMessageCode -> << >>
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)

DecodeServerSessionPayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogonMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerSessionPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Server Session Payload in turn, at the values the message it names is checked at *)
CheckedServerSessionPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogonMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }

(***************************************************************************)
(* Server Session                                                          *)
(***************************************************************************)

ServerSession ==
    [ blockLength          : Sample(2),
      schemaId             : Sample(2),
      version              : Sample(2),
      serverSessionPayload : ServerSessionPayload ]

EncodeServerSession(message) ==
    message.blockLength
        \o EncodeUIntLE(message.serverSessionPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeServerSessionPayload(message.serverSessionPayload)

DecodeServerSession(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET serverSessionPayload == DecodeServerSessionPayload(templateId.value, version.rest) IN IF ~serverSessionPayload.ok THEN Fail ELSE
    Ok([ blockLength          |-> blockLength.value,
         schemaId             |-> schemaId.value,
         version              |-> version.value,
         serverSessionPayload |-> serverSessionPayload.value ], serverSessionPayload.rest)

ZeroServerSession ==
    [ blockLength          |-> [i \in 1 .. 2 |-> 0],
      schemaId             |-> [i \in 1 .. 2 |-> 0],
      version              |-> [i \in 1 .. 2 |-> 0],
      serverSessionPayload |-> ZeroServerSessionPayload ]

(* Server Session at zero, then each field in turn at the values it is checked at *)
CheckedServerSession ==
    { ZeroServerSession }
        \cup { [ZeroServerSession EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroServerSession EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroServerSession EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroServerSession EXCEPT !.serverSessionPayload = one] : one \in CheckedServerSessionPayload }

(***************************************************************************)
(* Incremental Packet Header: 12 bytes                                     *)
(***************************************************************************)

IncrementalPacketHeader ==
    [ transactTime                     : Sample(8),
      exchangeTradingSessionIdOptional : Sample(4) ]

EncodeIncrementalPacketHeader(message) ==
    message.transactTime
        \o message.exchangeTradingSessionIdOptional

DecodeIncrementalPacketHeader(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET exchangeTradingSessionIdOptional == ReadBytes(transactTime.rest, 4) IN IF ~exchangeTradingSessionIdOptional.ok THEN Fail ELSE
    Ok([ transactTime                     |-> transactTime.value,
         exchangeTradingSessionIdOptional |-> exchangeTradingSessionIdOptional.value ], exchangeTradingSessionIdOptional.rest)

ZeroIncrementalPacketHeader ==
    [ transactTime                     |-> [i \in 1 .. 8 |-> 0],
      exchangeTradingSessionIdOptional |-> [i \in 1 .. 4 |-> 0] ]

(* Incremental Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalPacketHeader ==
    { ZeroIncrementalPacketHeader }
        \cup { [ZeroIncrementalPacketHeader EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalPacketHeader EXCEPT !.exchangeTradingSessionIdOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Best Prices Message No Md Entries Group: 36 bytes                       *)
(***************************************************************************)

BestPricesMessageNoMdEntriesGroup ==
    [ mktBidPx     : Sample(8),
      mktOfferPx   : Sample(8),
      mktBidSize   : Sample(8),
      mktOfferSize : Sample(8),
      securityId   : Sample(4) ]

EncodeBestPricesMessageNoMdEntriesGroup(message) ==
    message.mktBidPx
        \o message.mktOfferPx
        \o message.mktBidSize
        \o message.mktOfferSize
        \o message.securityId

DecodeBestPricesMessageNoMdEntriesGroup(bytes) ==
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

ZeroBestPricesMessageNoMdEntriesGroup ==
    [ mktBidPx     |-> [i \in 1 .. 8 |-> 0],
      mktOfferPx   |-> [i \in 1 .. 8 |-> 0],
      mktBidSize   |-> [i \in 1 .. 8 |-> 0],
      mktOfferSize |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 4 |-> 0] ]

(* Best Prices Message No Md Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedBestPricesMessageNoMdEntriesGroup ==
    { ZeroBestPricesMessageNoMdEntriesGroup }
        \cup { [ZeroBestPricesMessageNoMdEntriesGroup EXCEPT !.mktBidPx = one] : one \in Sample(8) }
        \cup { [ZeroBestPricesMessageNoMdEntriesGroup EXCEPT !.mktOfferPx = one] : one \in Sample(8) }
        \cup { [ZeroBestPricesMessageNoMdEntriesGroup EXCEPT !.mktBidSize = one] : one \in Sample(8) }
        \cup { [ZeroBestPricesMessageNoMdEntriesGroup EXCEPT !.mktOfferSize = one] : one \in Sample(8) }
        \cup { [ZeroBestPricesMessageNoMdEntriesGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Best Prices Message No Md Entries Group, written one after another *)
RECURSIVE EncodeBestPricesMessageNoMdEntriesGroupList(_)
EncodeBestPricesMessageNoMdEntriesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBestPricesMessageNoMdEntriesGroup(Head(messages)) \o EncodeBestPricesMessageNoMdEntriesGroupList(Tail(messages))

(* As many Best Prices Message No Md Entries Group as the field that counts them says *)
RECURSIVE ReadBestPricesMessageNoMdEntriesGroupList(_, _)
ReadBestPricesMessageNoMdEntriesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBestPricesMessageNoMdEntriesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBestPricesMessageNoMdEntriesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Best Prices Message No Md Entries Group of each kind, for the lists that carry them *)
OneBestPricesMessageNoMdEntriesGroup == { ZeroBestPricesMessageNoMdEntriesGroup }

(***************************************************************************)
(* Best Prices Message No Md Entries Groups                                *)
(***************************************************************************)

BestPricesMessageNoMdEntriesGroups ==
    [ blockLength                       : Sample(2),
      bestPricesMessageNoMdEntriesGroup : SampleLists(OneBestPricesMessageNoMdEntriesGroup) ]

EncodeBestPricesMessageNoMdEntriesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.bestPricesMessageNoMdEntriesGroup), 1)
        \o EncodeBestPricesMessageNoMdEntriesGroupList(message.bestPricesMessageNoMdEntriesGroup)

DecodeBestPricesMessageNoMdEntriesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET bestPricesMessageNoMdEntriesGroup == ReadBestPricesMessageNoMdEntriesGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~bestPricesMessageNoMdEntriesGroup.ok THEN Fail ELSE
    Ok([ blockLength                       |-> blockLength.value,
         bestPricesMessageNoMdEntriesGroup |-> bestPricesMessageNoMdEntriesGroup.value ], bestPricesMessageNoMdEntriesGroup.rest)

ZeroBestPricesMessageNoMdEntriesGroups ==
    [ blockLength                       |-> [i \in 1 .. 2 |-> 0],
      bestPricesMessageNoMdEntriesGroup |-> << >> ]

(* Best Prices Message No Md Entries Groups at zero, then each field in turn at the values it is checked at *)
CheckedBestPricesMessageNoMdEntriesGroups ==
    { ZeroBestPricesMessageNoMdEntriesGroups }
        \cup { [ZeroBestPricesMessageNoMdEntriesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroBestPricesMessageNoMdEntriesGroups EXCEPT !.bestPricesMessageNoMdEntriesGroup = one] : one \in SampleLists(OneBestPricesMessageNoMdEntriesGroup) }

(***************************************************************************)
(* Best Prices Message                                                     *)
(***************************************************************************)

BestPricesMessage ==
    [ bestPricesMessageNoMdEntriesGroups : BestPricesMessageNoMdEntriesGroups ]

EncodeBestPricesMessage(message) ==
    EncodeBestPricesMessageNoMdEntriesGroups(message.bestPricesMessageNoMdEntriesGroups)

DecodeBestPricesMessage(bytes) ==
    LET bestPricesMessageNoMdEntriesGroups == DecodeBestPricesMessageNoMdEntriesGroups(bytes) IN IF ~bestPricesMessageNoMdEntriesGroups.ok THEN Fail ELSE
    Ok([ bestPricesMessageNoMdEntriesGroups |-> bestPricesMessageNoMdEntriesGroups.value ], bestPricesMessageNoMdEntriesGroups.rest)

ZeroBestPricesMessage ==
    [ bestPricesMessageNoMdEntriesGroups |-> ZeroBestPricesMessageNoMdEntriesGroups ]

(* Best Prices Message at zero, then each field in turn at the values it is checked at *)
CheckedBestPricesMessage ==
    { ZeroBestPricesMessage }
        \cup { [ZeroBestPricesMessage EXCEPT !.bestPricesMessageNoMdEntriesGroups = one] : one \in CheckedBestPricesMessageNoMdEntriesGroups }

(***************************************************************************)
(* Empty Book Message: 4 bytes                                             *)
(***************************************************************************)

EmptyBookMessage ==
    [ lastMsgSeqNumProcessedOptional : Sample(4) ]

EncodeEmptyBookMessage(message) ==
    message.lastMsgSeqNumProcessedOptional

DecodeEmptyBookMessage(bytes) ==
    LET lastMsgSeqNumProcessedOptional == ReadBytes(bytes, 4) IN IF ~lastMsgSeqNumProcessedOptional.ok THEN Fail ELSE
    Ok([ lastMsgSeqNumProcessedOptional |-> lastMsgSeqNumProcessedOptional.value ], lastMsgSeqNumProcessedOptional.rest)

ZeroEmptyBookMessage ==
    [ lastMsgSeqNumProcessedOptional |-> [i \in 1 .. 4 |-> 0] ]

(* Empty Book Message at zero, then each field in turn at the values it is checked at *)
CheckedEmptyBookMessage ==
    { ZeroEmptyBookMessage }
        \cup { [ZeroEmptyBookMessage EXCEPT !.lastMsgSeqNumProcessedOptional = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Update Message: 50 bytes                                          *)
(***************************************************************************)

OrderUpdateMessage ==
    [ mdEntryId      : Sample(8),
      mdEntryPx      : Sample(8),
      mdEntrySize    : Sample(8),
      mdFlags        : Sample(8),
      mdFlags2       : Sample(8),
      securityId     : Sample(4),
      rptSeq         : Sample(4),
      mdUpdateAction : Sample(1),
      mdEntryType    : Sample(1) ]

EncodeOrderUpdateMessage(message) ==
    message.mdEntryId
        \o message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdFlags
        \o message.mdFlags2
        \o message.securityId
        \o message.rptSeq
        \o message.mdUpdateAction
        \o message.mdEntryType

DecodeOrderUpdateMessage(bytes) ==
    LET mdEntryId == ReadBytes(bytes, 8) IN IF ~mdEntryId.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryId.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(mdEntrySize.rest, 8) IN IF ~mdFlags.ok THEN Fail ELSE
    LET mdFlags2 == ReadBytes(mdFlags.rest, 8) IN IF ~mdFlags2.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdFlags2.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(rptSeq.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    Ok([ mdEntryId      |-> mdEntryId.value,
         mdEntryPx      |-> mdEntryPx.value,
         mdEntrySize    |-> mdEntrySize.value,
         mdFlags        |-> mdFlags.value,
         mdFlags2       |-> mdFlags2.value,
         securityId     |-> securityId.value,
         rptSeq         |-> rptSeq.value,
         mdUpdateAction |-> mdUpdateAction.value,
         mdEntryType    |-> mdEntryType.value ], mdEntryType.rest)

ZeroOrderUpdateMessage ==
    [ mdEntryId      |-> [i \in 1 .. 8 |-> 0],
      mdEntryPx      |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize    |-> [i \in 1 .. 8 |-> 0],
      mdFlags        |-> [i \in 1 .. 8 |-> 0],
      mdFlags2       |-> [i \in 1 .. 8 |-> 0],
      securityId     |-> [i \in 1 .. 4 |-> 0],
      rptSeq         |-> [i \in 1 .. 4 |-> 0],
      mdUpdateAction |-> [i \in 1 .. 1 |-> 0],
      mdEntryType    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderUpdateMessage ==
    { ZeroOrderUpdateMessage }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdEntryId = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderUpdateMessage EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
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
    [ mdEntryId           : Sample(8),
      mdEntryPxOptional   : Sample(8),
      mdEntrySizeOptional : Sample(8),
      lastPx              : Sample(8),
      lastQty             : Sample(8),
      tradeId             : Sample(8),
      mdFlags             : Sample(8),
      mdFlags2            : Sample(8),
      securityId          : Sample(4),
      rptSeq              : Sample(4),
      mdUpdateAction      : Sample(1),
      mdEntryType         : Sample(1) ]

EncodeOrderExecutionMessage(message) ==
    message.mdEntryId
        \o message.mdEntryPxOptional
        \o message.mdEntrySizeOptional
        \o message.lastPx
        \o message.lastQty
        \o message.tradeId
        \o message.mdFlags
        \o message.mdFlags2
        \o message.securityId
        \o message.rptSeq
        \o message.mdUpdateAction
        \o message.mdEntryType

DecodeOrderExecutionMessage(bytes) ==
    LET mdEntryId == ReadBytes(bytes, 8) IN IF ~mdEntryId.ok THEN Fail ELSE
    LET mdEntryPxOptional == ReadBytes(mdEntryId.rest, 8) IN IF ~mdEntryPxOptional.ok THEN Fail ELSE
    LET mdEntrySizeOptional == ReadBytes(mdEntryPxOptional.rest, 8) IN IF ~mdEntrySizeOptional.ok THEN Fail ELSE
    LET lastPx == ReadBytes(mdEntrySizeOptional.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET tradeId == ReadBytes(lastQty.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(tradeId.rest, 8) IN IF ~mdFlags.ok THEN Fail ELSE
    LET mdFlags2 == ReadBytes(mdFlags.rest, 8) IN IF ~mdFlags2.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdFlags2.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(rptSeq.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    Ok([ mdEntryId           |-> mdEntryId.value,
         mdEntryPxOptional   |-> mdEntryPxOptional.value,
         mdEntrySizeOptional |-> mdEntrySizeOptional.value,
         lastPx              |-> lastPx.value,
         lastQty             |-> lastQty.value,
         tradeId             |-> tradeId.value,
         mdFlags             |-> mdFlags.value,
         mdFlags2            |-> mdFlags2.value,
         securityId          |-> securityId.value,
         rptSeq              |-> rptSeq.value,
         mdUpdateAction      |-> mdUpdateAction.value,
         mdEntryType         |-> mdEntryType.value ], mdEntryType.rest)

ZeroOrderExecutionMessage ==
    [ mdEntryId           |-> [i \in 1 .. 8 |-> 0],
      mdEntryPxOptional   |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeOptional |-> [i \in 1 .. 8 |-> 0],
      lastPx              |-> [i \in 1 .. 8 |-> 0],
      lastQty             |-> [i \in 1 .. 8 |-> 0],
      tradeId             |-> [i \in 1 .. 8 |-> 0],
      mdFlags             |-> [i \in 1 .. 8 |-> 0],
      mdFlags2            |-> [i \in 1 .. 8 |-> 0],
      securityId          |-> [i \in 1 .. 4 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      mdUpdateAction      |-> [i \in 1 .. 1 |-> 0],
      mdEntryType         |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdEntryId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdEntryPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdEntrySizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdFlags = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdFlags2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.mdEntryType = one] : one \in Sample(1) }

(***************************************************************************)
(* Server Replay Payload, selected by Template Id                          *)
(***************************************************************************)

HeartbeatMessageCode2 == 1  \* 0x01
BestPricesMessageCode == 14  \* 0x0e
EmptyBookMessageCode == 4  \* 0x04
OrderUpdateMessageCode == 15  \* 0x0f
OrderExecutionMessageCode == 16  \* 0x10

ServerReplayPayload ==
    [ tag : {HeartbeatMessageCode2}, body : {[empty |-> 0]} ]
        \cup [ tag : {BestPricesMessageCode}, body : BestPricesMessage ]
        \cup [ tag : {EmptyBookMessageCode}, body : EmptyBookMessage ]
        \cup [ tag : {OrderUpdateMessageCode}, body : OrderUpdateMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]

EncodeServerReplayPayload(message) ==
    CASE message.tag = HeartbeatMessageCode2 -> << >>
      [] message.tag = BestPricesMessageCode -> EncodeBestPricesMessage(message.body)
      [] message.tag = EmptyBookMessageCode -> EncodeEmptyBookMessage(message.body)
      [] message.tag = OrderUpdateMessageCode -> EncodeOrderUpdateMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)

DecodeServerReplayPayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode2 -> Ok([empty |-> 0], bytes)
              [] tag = BestPricesMessageCode -> DecodeBestPricesMessage(bytes)
              [] tag = EmptyBookMessageCode -> DecodeEmptyBookMessage(bytes)
              [] tag = OrderUpdateMessageCode -> DecodeOrderUpdateMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerReplayPayload == [tag |-> HeartbeatMessageCode2, body |-> [empty |-> 0]]

(* Each Server Replay Payload in turn, at the values the message it names is checked at *)
CheckedServerReplayPayload ==
    { [tag |-> HeartbeatMessageCode2, body |-> [empty |-> 0]] }
        \cup { [tag |-> BestPricesMessageCode, body |-> one] : one \in CheckedBestPricesMessage }
        \cup { [tag |-> EmptyBookMessageCode, body |-> one] : one \in CheckedEmptyBookMessage }
        \cup { [tag |-> OrderUpdateMessageCode, body |-> one] : one \in CheckedOrderUpdateMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }

(***************************************************************************)
(* Server Replay Message                                                   *)
(***************************************************************************)

ServerReplayMessage ==
    [ blockLength         : Sample(2),
      schemaId            : Sample(2),
      version             : Sample(2),
      serverReplayPayload : ServerReplayPayload ]

EncodeServerReplayMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.serverReplayPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeServerReplayPayload(message.serverReplayPayload)

DecodeServerReplayMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET serverReplayPayload == DecodeServerReplayPayload(templateId.value, version.rest) IN IF ~serverReplayPayload.ok THEN Fail ELSE
    Ok([ blockLength         |-> blockLength.value,
         schemaId            |-> schemaId.value,
         version             |-> version.value,
         serverReplayPayload |-> serverReplayPayload.value ], serverReplayPayload.rest)

ZeroServerReplayMessage ==
    [ blockLength         |-> [i \in 1 .. 2 |-> 0],
      schemaId            |-> [i \in 1 .. 2 |-> 0],
      version             |-> [i \in 1 .. 2 |-> 0],
      serverReplayPayload |-> ZeroServerReplayPayload ]

(* Server Replay Message at zero, then each field in turn at the values it is checked at *)
CheckedServerReplayMessage ==
    { ZeroServerReplayMessage }
        \cup { [ZeroServerReplayMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroServerReplayMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroServerReplayMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroServerReplayMessage EXCEPT !.serverReplayPayload = one] : one \in CheckedServerReplayPayload }

(* A run of Server Replay Message, written one after another *)
RECURSIVE EncodeServerReplayMessageList(_)
EncodeServerReplayMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerReplayMessage(Head(messages)) \o EncodeServerReplayMessageList(Tail(messages))

(* As many Server Replay Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerReplayMessageAll(_)
ReadServerReplayMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerReplayMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerReplayMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Replay Message of each kind, for the lists that carry them *)
OneServerReplayMessage ==
    { [ZeroServerReplayMessage EXCEPT !.serverReplayPayload = [tag |-> HeartbeatMessageCode2, body |-> [empty |-> 0]]],
      [ZeroServerReplayMessage EXCEPT !.serverReplayPayload = [tag |-> BestPricesMessageCode, body |-> ZeroBestPricesMessage]],
      [ZeroServerReplayMessage EXCEPT !.serverReplayPayload = [tag |-> EmptyBookMessageCode, body |-> ZeroEmptyBookMessage]],
      [ZeroServerReplayMessage EXCEPT !.serverReplayPayload = [tag |-> OrderUpdateMessageCode, body |-> ZeroOrderUpdateMessage]],
      [ZeroServerReplayMessage EXCEPT !.serverReplayPayload = [tag |-> OrderExecutionMessageCode, body |-> ZeroOrderExecutionMessage]] }

(***************************************************************************)
(* Server Replay                                                           *)
(***************************************************************************)

ServerReplay ==
    [ incrementalPacketHeader : IncrementalPacketHeader,
      serverReplayMessage     : SampleLists(OneServerReplayMessage) ]

EncodeServerReplay(message) ==
    EncodeIncrementalPacketHeader(message.incrementalPacketHeader)
        \o EncodeServerReplayMessageList(message.serverReplayMessage)

DecodeServerReplay(bytes) ==
    LET incrementalPacketHeader == DecodeIncrementalPacketHeader(bytes) IN IF ~incrementalPacketHeader.ok THEN Fail ELSE
    LET serverReplayMessage == ReadServerReplayMessageAll(incrementalPacketHeader.rest) IN IF ~serverReplayMessage.ok THEN Fail ELSE
    Ok([ incrementalPacketHeader |-> incrementalPacketHeader.value,
         serverReplayMessage     |-> serverReplayMessage.value ], serverReplayMessage.rest)

ZeroServerReplay ==
    [ incrementalPacketHeader |-> ZeroIncrementalPacketHeader,
      serverReplayMessage     |-> << >> ]

(* Server Replay at zero, then each field in turn at the values it is checked at *)
CheckedServerReplay ==
    { ZeroServerReplay }
        \cup { [ZeroServerReplay EXCEPT !.incrementalPacketHeader = one] : one \in CheckedIncrementalPacketHeader }
        \cup { [ZeroServerReplay EXCEPT !.serverReplayMessage = one] : one \in SampleLists(OneServerReplayMessage) }

(***************************************************************************)
(* Server Body, selected by Incremental Packet                             *)
(***************************************************************************)

(* Incremental Packet is the bit worth 8 of Msg Flags, read as the number that set is. *)
(* IncrementalPacketOf is the key, MsgFlagsBeyond the bits beside it, MsgFlagsWith the two together. *)
IncrementalPacketOf(msgFlags) == (msgFlags \div 8) % 2
MsgFlagsBeyond(msgFlags) == msgFlags - IncrementalPacketOf(msgFlags) * 8
MsgFlagsWith(beyond, incrementalPacket) == beyond + incrementalPacket * 8

ServerSessionCode == 0  \* 0x00
ServerReplayCode == 1  \* 0x01

ServerBody ==
    [ tag : {ServerSessionCode}, body : ServerSession ]
        \cup [ tag : {ServerReplayCode}, body : ServerReplay ]

EncodeServerBody(message) ==
    CASE message.tag = ServerSessionCode -> EncodeServerSession(message.body)
      [] message.tag = ServerReplayCode -> EncodeServerReplay(message.body)

DecodeServerBody(tag, bytes) ==
    LET read ==
            CASE tag = ServerSessionCode -> DecodeServerSession(bytes)
              [] tag = ServerReplayCode -> DecodeServerReplay(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerBody == [tag |-> ServerSessionCode, body |-> ZeroServerSession]

(* Each Server Body in turn, at the values the message it names is checked at *)
CheckedServerBody ==
    { [tag |-> ServerSessionCode, body |-> one] : one \in CheckedServerSession }
        \cup { [tag |-> ServerReplayCode, body |-> one] : one \in CheckedServerReplay }

(***************************************************************************)
(* Server Frame, framed by Msg Size                                        *)
(***************************************************************************)

ServerFrame ==
    [ msgSeqNum      : Sample(4),
      msgFlagsBeyond : { MsgFlagsBeyond(bits) : bits \in 0 .. 255 },
      sendingTime    : Sample(8),
      serverBody     : ServerBody ]

EncodeServerFrameBody(message) ==
    EncodeUIntLE(MsgFlagsWith(message.msgFlagsBeyond, message.serverBody.tag), 2)
        \o message.sendingTime
        \o EncodeServerBody(message.serverBody)

(* Msg Size counts the bytes it frames, so it is written from them *)
EncodeServerFrame(message) ==
    LET body == EncodeServerFrameBody(message)
    IN  message.msgSeqNum \o EncodeUIntLE(Len(body) + 6, 2) \o body

DecodeServerFrame(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET length == ReadUIntLE(msgSeqNum.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 6 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET msgFlags == ReadUIntLE(framed, 2) IN IF ~msgFlags.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgFlags.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET serverBody == DecodeServerBody(IncrementalPacketOf(msgFlags.value), sendingTime.rest) IN IF ~serverBody.ok THEN Fail ELSE
    IF serverBody.rest # << >> THEN Fail ELSE
    Ok([ msgSeqNum      |-> msgSeqNum.value,
         msgFlagsBeyond |-> MsgFlagsBeyond(msgFlags.value),
         sendingTime    |-> sendingTime.value,
         serverBody     |-> serverBody.value ], beyond)

ZeroServerFrame ==
    [ msgSeqNum      |-> [i \in 1 .. 4 |-> 0],
      msgFlagsBeyond |-> 0,
      sendingTime    |-> [i \in 1 .. 8 |-> 0],
      serverBody     |-> ZeroServerBody ]

(* Server Frame at zero, then each field in turn at the values it is checked at *)
CheckedServerFrame ==
    { ZeroServerFrame }
        \cup { [ZeroServerFrame EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroServerFrame EXCEPT !.msgFlagsBeyond = one] : one \in { MsgFlagsBeyond(bits) : bits \in {0, 1, 255} } }
        \cup { [ZeroServerFrame EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroServerFrame EXCEPT !.serverBody = one] : one \in CheckedServerBody }

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
OneServerFrame ==
    { [ZeroServerFrame EXCEPT !.serverBody = [tag |-> ServerSessionCode, body |-> ZeroServerSession]],
      [ZeroServerFrame EXCEPT !.serverBody = [tag |-> ServerReplayCode, body |-> ZeroServerReplay]] }

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

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Session decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSession ==
    \A message \in CheckedServerSession :
        LET read == DecodeServerSession(EncodeServerSession(message))
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

(* Every Best Prices Message No Md Entries Group decodes back to what was encoded, and leaves nothing over *)
RoundTripBestPricesMessageNoMdEntriesGroup ==
    \A message \in CheckedBestPricesMessageNoMdEntriesGroup :
        LET read == DecodeBestPricesMessageNoMdEntriesGroup(EncodeBestPricesMessageNoMdEntriesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Prices Message No Md Entries Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripBestPricesMessageNoMdEntriesGroups ==
    \A message \in CheckedBestPricesMessageNoMdEntriesGroups :
        LET read == DecodeBestPricesMessageNoMdEntriesGroups(EncodeBestPricesMessageNoMdEntriesGroups(message))
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

(* Every Server Replay Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerReplayMessage ==
    \A message \in CheckedServerReplayMessage :
        LET read == DecodeServerReplayMessage(EncodeServerReplayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Replay decodes back to what was encoded, and leaves nothing over *)
RoundTripServerReplay ==
    \A message \in CheckedServerReplay :
        LET read == DecodeServerReplay(EncodeServerReplay(message))
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

(* A Server Session Payload is selected by the Template Id it is written under *)
SelectsServerSessionPayload ==
    \A message \in CheckedServerSessionPayload :
        LET sent == EncodeServerSessionPayload(message)
            read == DecodeServerSessionPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Replay Payload is selected by the Template Id it is written under *)
SelectsServerReplayPayload ==
    \A message \in CheckedServerReplayPayload :
        LET sent == EncodeServerReplayPayload(message)
            read == DecodeServerReplayPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Body is selected by the Incremental Packet it is written under *)
SelectsServerBody ==
    \A message \in CheckedServerBody :
        LET sent == EncodeServerBody(message)
            read == DecodeServerBody(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Size is written from the bytes it frames *)
FramesServerFrame ==
    \A message \in CheckedServerFrame :
        LET bytes == EncodeServerFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 5, 6)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
