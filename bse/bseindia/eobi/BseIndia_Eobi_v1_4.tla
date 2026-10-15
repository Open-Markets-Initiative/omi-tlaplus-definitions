------------------------ MODULE BseIndia_Eobi_v1_4 -------------------------
(***************************************************************************)
(* BSE Limited Enhanced Order Book Interface v1.4                          *)
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
(* Note: Md Instrument Entry Grp is written as 15 slots, however many of   *)
(* them No Md Entries says are in use.                                     *)
(*                                                                         *)
(* Note: Md Trade Entry Grp is written as 15 slots, however many of them   *)
(* No Md Entries says are in use.                                          *)
(*                                                                         *)
(* Note: Instrmt Leg Grp is written as 5 slots, however many of them No    *)
(* Legs says are in use.                                                   *)
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
(* Eobi Header: 8 bytes                                                    *)
(***************************************************************************)

EobiHeader ==
    [ bodyLen    : Sample(2),
      templateId : Sample(2),
      msgSeqNum  : Sample(4) ]

EncodeEobiHeader(message) ==
    message.bodyLen
        \o message.templateId
        \o message.msgSeqNum

DecodeEobiHeader(bytes) ==
    LET bodyLen == ReadBytes(bytes, 2) IN IF ~bodyLen.ok THEN Fail ELSE
    LET templateId == ReadBytes(bodyLen.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(templateId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    Ok([ bodyLen    |-> bodyLen.value,
         templateId |-> templateId.value,
         msgSeqNum  |-> msgSeqNum.value ], msgSeqNum.rest)

ZeroEobiHeader ==
    [ bodyLen    |-> [i \in 1 .. 2 |-> 0],
      templateId |-> [i \in 1 .. 2 |-> 0],
      msgSeqNum  |-> [i \in 1 .. 4 |-> 0] ]

(* Eobi Header at zero, then each field in turn at the values it is checked at *)
CheckedEobiHeader ==
    { ZeroEobiHeader }
        \cup { [ZeroEobiHeader EXCEPT !.bodyLen = one] : one \in Sample(2) }
        \cup { [ZeroEobiHeader EXCEPT !.templateId = one] : one \in Sample(2) }
        \cup { [ZeroEobiHeader EXCEPT !.msgSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Packet Header: 32 bytes                                                 *)
(***************************************************************************)

PacketHeader ==
    [ eobiHeader            : EobiHeader,
      applSeqNum            : Sample(4),
      marketSegmentId       : Sample(4),
      partitionId           : Sample(1),
      completionIndicator   : Sample(1),
      applSeqResetIndicator : Sample(1),
      pad5                  : Sample(5),
      transactTime          : Sample(8) ]

EncodePacketHeader(message) ==
    EncodeEobiHeader(message.eobiHeader)
        \o message.applSeqNum
        \o message.marketSegmentId
        \o message.partitionId
        \o message.completionIndicator
        \o message.applSeqResetIndicator
        \o message.pad5
        \o message.transactTime

DecodePacketHeader(bytes) ==
    LET eobiHeader == DecodeEobiHeader(bytes) IN IF ~eobiHeader.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(eobiHeader.rest, 4) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(applSeqNum.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(marketSegmentId.rest, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET completionIndicator == ReadBytes(partitionId.rest, 1) IN IF ~completionIndicator.ok THEN Fail ELSE
    LET applSeqResetIndicator == ReadBytes(completionIndicator.rest, 1) IN IF ~applSeqResetIndicator.ok THEN Fail ELSE
    LET pad5 == ReadBytes(applSeqResetIndicator.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    LET transactTime == ReadBytes(pad5.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ eobiHeader            |-> eobiHeader.value,
         applSeqNum            |-> applSeqNum.value,
         marketSegmentId       |-> marketSegmentId.value,
         partitionId           |-> partitionId.value,
         completionIndicator   |-> completionIndicator.value,
         applSeqResetIndicator |-> applSeqResetIndicator.value,
         pad5                  |-> pad5.value,
         transactTime          |-> transactTime.value ], transactTime.rest)

ZeroPacketHeader ==
    [ eobiHeader            |-> ZeroEobiHeader,
      applSeqNum            |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      partitionId           |-> [i \in 1 .. 1 |-> 0],
      completionIndicator   |-> [i \in 1 .. 1 |-> 0],
      applSeqResetIndicator |-> [i \in 1 .. 1 |-> 0],
      pad5                  |-> [i \in 1 .. 5 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0] ]

(* Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedPacketHeader ==
    { ZeroPacketHeader }
        \cup { [ZeroPacketHeader EXCEPT !.eobiHeader = one] : one \in CheckedEobiHeader }
        \cup { [ZeroPacketHeader EXCEPT !.applSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacketHeader EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroPacketHeader EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroPacketHeader EXCEPT !.completionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPacketHeader EXCEPT !.applSeqResetIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPacketHeader EXCEPT !.pad5 = one] : one \in Sample(5) }
        \cup { [ZeroPacketHeader EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Heartbeat Message: 8 bytes                                              *)
(***************************************************************************)

HeartbeatMessage ==
    [ lastMsgSeqNumProcessed : Sample(4),
      pad4                   : Sample(4) ]

EncodeHeartbeatMessage(message) ==
    message.lastMsgSeqNumProcessed
        \o message.pad4

DecodeHeartbeatMessage(bytes) ==
    LET lastMsgSeqNumProcessed == ReadBytes(bytes, 4) IN IF ~lastMsgSeqNumProcessed.ok THEN Fail ELSE
    LET pad4 == ReadBytes(lastMsgSeqNumProcessed.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ lastMsgSeqNumProcessed |-> lastMsgSeqNumProcessed.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroHeartbeatMessage ==
    [ lastMsgSeqNumProcessed |-> [i \in 1 .. 4 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatMessage ==
    { ZeroHeartbeatMessage }
        \cup { [ZeroHeartbeatMessage EXCEPT !.lastMsgSeqNumProcessed = one] : one \in Sample(4) }
        \cup { [ZeroHeartbeatMessage EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Product Summary Message: 8 bytes                                        *)
(***************************************************************************)

ProductSummaryMessage ==
    [ lastMsgSeqNumProcessed : Sample(4),
      tradingSessionId       : Sample(1),
      tradingSessionSubId    : Sample(1),
      tradSesStatus          : Sample(1),
      fastMarketIndicator    : Sample(1) ]

EncodeProductSummaryMessage(message) ==
    message.lastMsgSeqNumProcessed
        \o message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.tradSesStatus
        \o message.fastMarketIndicator

DecodeProductSummaryMessage(bytes) ==
    LET lastMsgSeqNumProcessed == ReadBytes(bytes, 4) IN IF ~lastMsgSeqNumProcessed.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(lastMsgSeqNumProcessed.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(tradSesStatus.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    Ok([ lastMsgSeqNumProcessed |-> lastMsgSeqNumProcessed.value,
         tradingSessionId       |-> tradingSessionId.value,
         tradingSessionSubId    |-> tradingSessionSubId.value,
         tradSesStatus          |-> tradSesStatus.value,
         fastMarketIndicator    |-> fastMarketIndicator.value ], fastMarketIndicator.rest)

ZeroProductSummaryMessage ==
    [ lastMsgSeqNumProcessed |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId       |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId    |-> [i \in 1 .. 1 |-> 0],
      tradSesStatus          |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Product Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedProductSummaryMessage ==
    { ZeroProductSummaryMessage }
        \cup { [ZeroProductSummaryMessage EXCEPT !.lastMsgSeqNumProcessed = one] : one \in Sample(4) }
        \cup { [ZeroProductSummaryMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroProductSummaryMessage EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroProductSummaryMessage EXCEPT !.tradSesStatus = one] : one \in Sample(1) }
        \cup { [ZeroProductSummaryMessage EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Details: 32 bytes                                                 *)
(***************************************************************************)

OrderDetails ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      pad7                 : Sample(7),
      price                : Sample(8) ]

EncodeOrderDetails(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.pad7
        \o message.price

DecodeOrderDetails(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET price == ReadBytes(pad7.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         pad7                 |-> pad7.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetails ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      pad7                 |-> [i \in 1 .. 7 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetails ==
    { ZeroOrderDetails }
        \cup { [ZeroOrderDetails EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetails EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroOrderDetails EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Snapshot Order Message: 32 bytes                                        *)
(***************************************************************************)

SnapshotOrderMessage ==
    [ orderDetails : OrderDetails ]

EncodeSnapshotOrderMessage(message) ==
    EncodeOrderDetails(message.orderDetails)

DecodeSnapshotOrderMessage(bytes) ==
    LET orderDetails == DecodeOrderDetails(bytes) IN IF ~orderDetails.ok THEN Fail ELSE
    Ok([ orderDetails |-> orderDetails.value ], orderDetails.rest)

ZeroSnapshotOrderMessage ==
    [ orderDetails |-> ZeroOrderDetails ]

(* Snapshot Order Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotOrderMessage ==
    { ZeroSnapshotOrderMessage }
        \cup { [ZeroSnapshotOrderMessage EXCEPT !.orderDetails = one] : one \in CheckedOrderDetails }

(***************************************************************************)
(* Md Instrument Entry Grp: 24 bytes                                       *)
(***************************************************************************)

MdInstrumentEntryGrp ==
    [ mdEntryPx   : Sample(8),
      mdEntrySize : Sample(8),
      mdEntryType : Sample(1),
      pad7        : Sample(7) ]

EncodeMdInstrumentEntryGrp(message) ==
    message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdEntryType
        \o message.pad7

DecodeMdInstrumentEntryGrp(bytes) ==
    LET mdEntryPx == ReadBytes(bytes, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdEntrySize.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET pad7 == ReadBytes(mdEntryType.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ mdEntryPx   |-> mdEntryPx.value,
         mdEntrySize |-> mdEntrySize.value,
         mdEntryType |-> mdEntryType.value,
         pad7        |-> pad7.value ], pad7.rest)

ZeroMdInstrumentEntryGrp ==
    [ mdEntryPx   |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize |-> [i \in 1 .. 8 |-> 0],
      mdEntryType |-> [i \in 1 .. 1 |-> 0],
      pad7        |-> [i \in 1 .. 7 |-> 0] ]

(* Md Instrument Entry Grp at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentEntryGrp ==
    { ZeroMdInstrumentEntryGrp }
        \cup { [ZeroMdInstrumentEntryGrp EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentEntryGrp EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentEntryGrp EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentEntryGrp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Md Instrument Entry Grp, written one after another *)
RECURSIVE EncodeMdInstrumentEntryGrpList(_)
EncodeMdInstrumentEntryGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdInstrumentEntryGrp(Head(messages)) \o EncodeMdInstrumentEntryGrpList(Tail(messages))

(* As many Md Instrument Entry Grp as the field that counts them says *)
RECURSIVE ReadMdInstrumentEntryGrpList(_, _)
ReadMdInstrumentEntryGrpList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdInstrumentEntryGrp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdInstrumentEntryGrpList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Instrument Entry Grp of each kind, for the lists that carry them *)
OneMdInstrumentEntryGrp == { ZeroMdInstrumentEntryGrp }

(* The 15 slots a run of Md Instrument Entry Grp is written as, whatever the field beside it says are in use *)
SlotsMdInstrumentEntryGrp == { [i \in 1 .. 15 |-> one] : one \in OneMdInstrumentEntryGrp }

(***************************************************************************)
(* Instrument Summary Message                                              *)
(***************************************************************************)

InstrumentSummaryMessage ==
    [ securityId            : Sample(8),
      lastUpdateTime        : Sample(8),
      trdRegTsExecutionTime : Sample(8),
      totNoOrders           : Sample(4),
      securityStatus        : Sample(1),
      securityTradingStatus : Sample(1),
      fastMarketIndicator   : Sample(1),
      noMdEntries           : 0 .. 255,
      tradeVolume           : Sample(8),
      noOfTrades            : Sample(4),
      pad4                  : Sample(4),
      mdInstrumentEntryGrp  : SlotsMdInstrumentEntryGrp ]

EncodeInstrumentSummaryMessage(message) ==
    message.securityId
        \o message.lastUpdateTime
        \o message.trdRegTsExecutionTime
        \o message.totNoOrders
        \o message.securityStatus
        \o message.securityTradingStatus
        \o message.fastMarketIndicator
        \o EncodeUIntLE(message.noMdEntries, 1)
        \o message.tradeVolume
        \o message.noOfTrades
        \o message.pad4
        \o EncodeMdInstrumentEntryGrpList(message.mdInstrumentEntryGrp)

DecodeInstrumentSummaryMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(securityId.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET trdRegTsExecutionTime == ReadBytes(lastUpdateTime.rest, 8) IN IF ~trdRegTsExecutionTime.ok THEN Fail ELSE
    LET totNoOrders == ReadBytes(trdRegTsExecutionTime.rest, 4) IN IF ~totNoOrders.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(totNoOrders.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityStatus.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(securityTradingStatus.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntLE(fastMarketIndicator.rest, 1) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(noMdEntries.rest, 8) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET noOfTrades == ReadBytes(tradeVolume.rest, 4) IN IF ~noOfTrades.ok THEN Fail ELSE
    LET pad4 == ReadBytes(noOfTrades.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET mdInstrumentEntryGrp == ReadMdInstrumentEntryGrpList(pad4.rest, 15) IN IF ~mdInstrumentEntryGrp.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         lastUpdateTime        |-> lastUpdateTime.value,
         trdRegTsExecutionTime |-> trdRegTsExecutionTime.value,
         totNoOrders           |-> totNoOrders.value,
         securityStatus        |-> securityStatus.value,
         securityTradingStatus |-> securityTradingStatus.value,
         fastMarketIndicator   |-> fastMarketIndicator.value,
         noMdEntries           |-> noMdEntries.value,
         tradeVolume           |-> tradeVolume.value,
         noOfTrades            |-> noOfTrades.value,
         pad4                  |-> pad4.value,
         mdInstrumentEntryGrp  |-> mdInstrumentEntryGrp.value ], mdInstrumentEntryGrp.rest)

ZeroInstrumentSummaryMessage ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      lastUpdateTime        |-> [i \in 1 .. 8 |-> 0],
      trdRegTsExecutionTime |-> [i \in 1 .. 8 |-> 0],
      totNoOrders           |-> [i \in 1 .. 4 |-> 0],
      securityStatus        |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator   |-> [i \in 1 .. 1 |-> 0],
      noMdEntries           |-> 0,
      tradeVolume           |-> [i \in 1 .. 8 |-> 0],
      noOfTrades            |-> [i \in 1 .. 4 |-> 0],
      pad4                  |-> [i \in 1 .. 4 |-> 0],
      mdInstrumentEntryGrp  |-> [i \in 1 .. 15 |-> ZeroMdInstrumentEntryGrp] ]

(* Instrument Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentSummaryMessage ==
    { ZeroInstrumentSummaryMessage }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.trdRegTsExecutionTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.totNoOrders = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.noMdEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.tradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.noOfTrades = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentSummaryMessage EXCEPT !.mdInstrumentEntryGrp = one] : one \in SlotsMdInstrumentEntryGrp }

(***************************************************************************)
(* Auction Best Bid Offer Message: 32 bytes                                *)
(***************************************************************************)

AuctionBestBidOfferMessage ==
    [ transactTime : Sample(8),
      securityId   : Sample(8),
      bidPx        : Sample(8),
      offerPx      : Sample(8) ]

EncodeAuctionBestBidOfferMessage(message) ==
    message.transactTime
        \o message.securityId
        \o message.bidPx
        \o message.offerPx

DecodeAuctionBestBidOfferMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         securityId   |-> securityId.value,
         bidPx        |-> bidPx.value,
         offerPx      |-> offerPx.value ], offerPx.rest)

ZeroAuctionBestBidOfferMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 8 |-> 0],
      bidPx        |-> [i \in 1 .. 8 |-> 0],
      offerPx      |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Best Bid Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionBestBidOfferMessage ==
    { ZeroAuctionBestBidOfferMessage }
        \cup { [ZeroAuctionBestBidOfferMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBestBidOfferMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBestBidOfferMessage EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBestBidOfferMessage EXCEPT !.offerPx = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Clearing Price Message: 32 bytes                                *)
(***************************************************************************)

AuctionClearingPriceMessage ==
    [ transactTime : Sample(8),
      securityId   : Sample(8),
      lastPx       : Sample(8),
      lastQty      : Sample(8) ]

EncodeAuctionClearingPriceMessage(message) ==
    message.transactTime
        \o message.securityId
        \o message.lastPx
        \o message.lastQty

DecodeAuctionClearingPriceMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         securityId   |-> securityId.value,
         lastPx       |-> lastPx.value,
         lastQty      |-> lastQty.value ], lastQty.rest)

ZeroAuctionClearingPriceMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 8 |-> 0],
      lastPx       |-> [i \in 1 .. 8 |-> 0],
      lastQty      |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Clearing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionClearingPriceMessage ==
    { ZeroAuctionClearingPriceMessage }
        \cup { [ZeroAuctionClearingPriceMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionClearingPriceMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionClearingPriceMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroAuctionClearingPriceMessage EXCEPT !.lastQty = one] : one \in Sample(8) }

(***************************************************************************)
(* Top Of Book Message: 32 bytes                                           *)
(***************************************************************************)

TopOfBookMessage ==
    [ transactTime : Sample(8),
      securityId   : Sample(8),
      bidPx        : Sample(8),
      offerPx      : Sample(8) ]

EncodeTopOfBookMessage(message) ==
    message.transactTime
        \o message.securityId
        \o message.bidPx
        \o message.offerPx

DecodeTopOfBookMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         securityId   |-> securityId.value,
         bidPx        |-> bidPx.value,
         offerPx      |-> offerPx.value ], offerPx.rest)

ZeroTopOfBookMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 8 |-> 0],
      bidPx        |-> [i \in 1 .. 8 |-> 0],
      offerPx      |-> [i \in 1 .. 8 |-> 0] ]

(* Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBookMessage ==
    { ZeroTopOfBookMessage }
        \cup { [ZeroTopOfBookMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.offerPx = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Details: 32 bytes                                                 *)
(***************************************************************************)

OrderDetails2 ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      pad7                 : Sample(7),
      price                : Sample(8) ]

EncodeOrderDetails2(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.pad7
        \o message.price

DecodeOrderDetails2(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET price == ReadBytes(pad7.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         pad7                 |-> pad7.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetails2 ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      pad7                 |-> [i \in 1 .. 7 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetails2 ==
    { ZeroOrderDetails2 }
        \cup { [ZeroOrderDetails2 EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails2 EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetails2 EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroOrderDetails2 EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Add Message: 48 bytes                                             *)
(***************************************************************************)

OrderAddMessage ==
    [ trdRegTsTimeIn : Sample(8),
      securityId     : Sample(8),
      orderDetails   : OrderDetails2 ]

EncodeOrderAddMessage(message) ==
    message.trdRegTsTimeIn
        \o message.securityId
        \o EncodeOrderDetails2(message.orderDetails)

DecodeOrderAddMessage(bytes) ==
    LET trdRegTsTimeIn == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET securityId == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderDetails == DecodeOrderDetails2(securityId.rest) IN IF ~orderDetails.ok THEN Fail ELSE
    Ok([ trdRegTsTimeIn |-> trdRegTsTimeIn.value,
         securityId     |-> securityId.value,
         orderDetails   |-> orderDetails.value ], orderDetails.rest)

ZeroOrderAddMessage ==
    [ trdRegTsTimeIn |-> [i \in 1 .. 8 |-> 0],
      securityId     |-> [i \in 1 .. 8 |-> 0],
      orderDetails   |-> ZeroOrderDetails2 ]

(* Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddMessage ==
    { ZeroOrderAddMessage }
        \cup { [ZeroOrderAddMessage EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderDetails = one] : one \in CheckedOrderDetails2 }

(***************************************************************************)
(* Order Details: 32 bytes                                                 *)
(***************************************************************************)

OrderDetails3 ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      pad7                 : Sample(7),
      price                : Sample(8) ]

EncodeOrderDetails3(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.pad7
        \o message.price

DecodeOrderDetails3(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET price == ReadBytes(pad7.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         pad7                 |-> pad7.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetails3 ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      pad7                 |-> [i \in 1 .. 7 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetails3 ==
    { ZeroOrderDetails3 }
        \cup { [ZeroOrderDetails3 EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails3 EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails3 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetails3 EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroOrderDetails3 EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify Message: 72 bytes                                          *)
(***************************************************************************)

OrderModifyMessage ==
    [ trdRegTsTimeIn           : Sample(8),
      trdRegTsPrevTimePriority : Sample(8),
      prevPrice                : Sample(8),
      prevDisplayQty           : Sample(8),
      securityId               : Sample(8),
      orderDetails             : OrderDetails3 ]

EncodeOrderModifyMessage(message) ==
    message.trdRegTsTimeIn
        \o message.trdRegTsPrevTimePriority
        \o message.prevPrice
        \o message.prevDisplayQty
        \o message.securityId
        \o EncodeOrderDetails3(message.orderDetails)

DecodeOrderModifyMessage(bytes) ==
    LET trdRegTsTimeIn == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsPrevTimePriority == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsPrevTimePriority.ok THEN Fail ELSE
    LET prevPrice == ReadBytes(trdRegTsPrevTimePriority.rest, 8) IN IF ~prevPrice.ok THEN Fail ELSE
    LET prevDisplayQty == ReadBytes(prevPrice.rest, 8) IN IF ~prevDisplayQty.ok THEN Fail ELSE
    LET securityId == ReadBytes(prevDisplayQty.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderDetails == DecodeOrderDetails3(securityId.rest) IN IF ~orderDetails.ok THEN Fail ELSE
    Ok([ trdRegTsTimeIn           |-> trdRegTsTimeIn.value,
         trdRegTsPrevTimePriority |-> trdRegTsPrevTimePriority.value,
         prevPrice                |-> prevPrice.value,
         prevDisplayQty           |-> prevDisplayQty.value,
         securityId               |-> securityId.value,
         orderDetails             |-> orderDetails.value ], orderDetails.rest)

ZeroOrderModifyMessage ==
    [ trdRegTsTimeIn           |-> [i \in 1 .. 8 |-> 0],
      trdRegTsPrevTimePriority |-> [i \in 1 .. 8 |-> 0],
      prevPrice                |-> [i \in 1 .. 8 |-> 0],
      prevDisplayQty           |-> [i \in 1 .. 8 |-> 0],
      securityId               |-> [i \in 1 .. 8 |-> 0],
      orderDetails             |-> ZeroOrderDetails3 ]

(* Order Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyMessage ==
    { ZeroOrderModifyMessage }
        \cup { [ZeroOrderModifyMessage EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.trdRegTsPrevTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.prevPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.prevDisplayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderDetails = one] : one \in CheckedOrderDetails3 }

(***************************************************************************)
(* Order Details: 32 bytes                                                 *)
(***************************************************************************)

OrderDetails4 ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      pad7                 : Sample(7),
      price                : Sample(8) ]

EncodeOrderDetails4(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.pad7
        \o message.price

DecodeOrderDetails4(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET price == ReadBytes(pad7.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         pad7                 |-> pad7.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetails4 ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      pad7                 |-> [i \in 1 .. 7 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetails4 ==
    { ZeroOrderDetails4 }
        \cup { [ZeroOrderDetails4 EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails4 EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails4 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetails4 EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroOrderDetails4 EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify Same Priority Message: 64 bytes                            *)
(***************************************************************************)

OrderModifySamePriorityMessage ==
    [ trdRegTsTimeIn : Sample(8),
      transactTime   : Sample(8),
      prevDisplayQty : Sample(8),
      securityId     : Sample(8),
      orderDetails   : OrderDetails4 ]

EncodeOrderModifySamePriorityMessage(message) ==
    message.trdRegTsTimeIn
        \o message.transactTime
        \o message.prevDisplayQty
        \o message.securityId
        \o EncodeOrderDetails4(message.orderDetails)

DecodeOrderModifySamePriorityMessage(bytes) ==
    LET trdRegTsTimeIn == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET transactTime == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET prevDisplayQty == ReadBytes(transactTime.rest, 8) IN IF ~prevDisplayQty.ok THEN Fail ELSE
    LET securityId == ReadBytes(prevDisplayQty.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderDetails == DecodeOrderDetails4(securityId.rest) IN IF ~orderDetails.ok THEN Fail ELSE
    Ok([ trdRegTsTimeIn |-> trdRegTsTimeIn.value,
         transactTime   |-> transactTime.value,
         prevDisplayQty |-> prevDisplayQty.value,
         securityId     |-> securityId.value,
         orderDetails   |-> orderDetails.value ], orderDetails.rest)

ZeroOrderModifySamePriorityMessage ==
    [ trdRegTsTimeIn |-> [i \in 1 .. 8 |-> 0],
      transactTime   |-> [i \in 1 .. 8 |-> 0],
      prevDisplayQty |-> [i \in 1 .. 8 |-> 0],
      securityId     |-> [i \in 1 .. 8 |-> 0],
      orderDetails   |-> ZeroOrderDetails4 ]

(* Order Modify Same Priority Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifySamePriorityMessage ==
    { ZeroOrderModifySamePriorityMessage }
        \cup { [ZeroOrderModifySamePriorityMessage EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifySamePriorityMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifySamePriorityMessage EXCEPT !.prevDisplayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifySamePriorityMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifySamePriorityMessage EXCEPT !.orderDetails = one] : one \in CheckedOrderDetails4 }

(***************************************************************************)
(* Order Details: 32 bytes                                                 *)
(***************************************************************************)

OrderDetails5 ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      pad7                 : Sample(7),
      price                : Sample(8) ]

EncodeOrderDetails5(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.pad7
        \o message.price

DecodeOrderDetails5(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET price == ReadBytes(pad7.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         pad7                 |-> pad7.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetails5 ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      pad7                 |-> [i \in 1 .. 7 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetails5 ==
    { ZeroOrderDetails5 }
        \cup { [ZeroOrderDetails5 EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails5 EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetails5 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetails5 EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroOrderDetails5 EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Delete Message: 56 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ trdRegTsTimeIn : Sample(8),
      transactTime   : Sample(8),
      securityId     : Sample(8),
      orderDetails   : OrderDetails5 ]

EncodeOrderDeleteMessage(message) ==
    message.trdRegTsTimeIn
        \o message.transactTime
        \o message.securityId
        \o EncodeOrderDetails5(message.orderDetails)

DecodeOrderDeleteMessage(bytes) ==
    LET trdRegTsTimeIn == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET transactTime == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderDetails == DecodeOrderDetails5(securityId.rest) IN IF ~orderDetails.ok THEN Fail ELSE
    Ok([ trdRegTsTimeIn |-> trdRegTsTimeIn.value,
         transactTime   |-> transactTime.value,
         securityId     |-> securityId.value,
         orderDetails   |-> orderDetails.value ], orderDetails.rest)

ZeroOrderDeleteMessage ==
    [ trdRegTsTimeIn |-> [i \in 1 .. 8 |-> 0],
      transactTime   |-> [i \in 1 .. 8 |-> 0],
      securityId     |-> [i \in 1 .. 8 |-> 0],
      orderDetails   |-> ZeroOrderDetails5 ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderDetails = one] : one \in CheckedOrderDetails5 }

(***************************************************************************)
(* Order Mass Delete Message: 16 bytes                                     *)
(***************************************************************************)

OrderMassDeleteMessage ==
    [ securityId   : Sample(8),
      transactTime : Sample(8) ]

EncodeOrderMassDeleteMessage(message) ==
    message.securityId
        \o message.transactTime

DecodeOrderMassDeleteMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ securityId   |-> securityId.value,
         transactTime |-> transactTime.value ], transactTime.rest)

ZeroOrderMassDeleteMessage ==
    [ securityId   |-> [i \in 1 .. 8 |-> 0],
      transactTime |-> [i \in 1 .. 8 |-> 0] ]

(* Order Mass Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassDeleteMessage ==
    { ZeroOrderMassDeleteMessage }
        \cup { [ZeroOrderMassDeleteMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassDeleteMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Partial Order Execution Message: 56 bytes                               *)
(***************************************************************************)

PartialOrderExecutionMessage ==
    [ side                 : Sample(1),
      pad7                 : Sample(7),
      price                : Sample(8),
      trdRegTsTimePriority : Sample(8),
      securityId           : Sample(8),
      trdMatchId           : Sample(4),
      pad4                 : Sample(4),
      lastQty              : Sample(8),
      lastPx               : Sample(8) ]

EncodePartialOrderExecutionMessage(message) ==
    message.side
        \o message.pad7
        \o message.price
        \o message.trdRegTsTimePriority
        \o message.securityId
        \o message.trdMatchId
        \o message.pad4
        \o message.lastQty
        \o message.lastPx

DecodePartialOrderExecutionMessage(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET price == ReadBytes(pad7.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(price.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET securityId == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(securityId.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(trdMatchId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET lastQty == ReadBytes(pad4.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    Ok([ side                 |-> side.value,
         pad7                 |-> pad7.value,
         price                |-> price.value,
         trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         securityId           |-> securityId.value,
         trdMatchId           |-> trdMatchId.value,
         pad4                 |-> pad4.value,
         lastQty              |-> lastQty.value,
         lastPx               |-> lastPx.value ], lastPx.rest)

ZeroPartialOrderExecutionMessage ==
    [ side                 |-> [i \in 1 .. 1 |-> 0],
      pad7                 |-> [i \in 1 .. 7 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      securityId           |-> [i \in 1 .. 8 |-> 0],
      trdMatchId           |-> [i \in 1 .. 4 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0],
      lastQty              |-> [i \in 1 .. 8 |-> 0],
      lastPx               |-> [i \in 1 .. 8 |-> 0] ]

(* Partial Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedPartialOrderExecutionMessage ==
    { ZeroPartialOrderExecutionMessage }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroPartialOrderExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }

(***************************************************************************)
(* Full Order Execution Message: 56 bytes                                  *)
(***************************************************************************)

FullOrderExecutionMessage ==
    [ side                 : Sample(1),
      pad7                 : Sample(7),
      price                : Sample(8),
      trdRegTsTimePriority : Sample(8),
      securityId           : Sample(8),
      trdMatchId           : Sample(4),
      pad4                 : Sample(4),
      lastQty              : Sample(8),
      lastPx               : Sample(8) ]

EncodeFullOrderExecutionMessage(message) ==
    message.side
        \o message.pad7
        \o message.price
        \o message.trdRegTsTimePriority
        \o message.securityId
        \o message.trdMatchId
        \o message.pad4
        \o message.lastQty
        \o message.lastPx

DecodeFullOrderExecutionMessage(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET price == ReadBytes(pad7.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(price.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET securityId == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(securityId.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(trdMatchId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET lastQty == ReadBytes(pad4.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    Ok([ side                 |-> side.value,
         pad7                 |-> pad7.value,
         price                |-> price.value,
         trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         securityId           |-> securityId.value,
         trdMatchId           |-> trdMatchId.value,
         pad4                 |-> pad4.value,
         lastQty              |-> lastQty.value,
         lastPx               |-> lastPx.value ], lastPx.rest)

ZeroFullOrderExecutionMessage ==
    [ side                 |-> [i \in 1 .. 1 |-> 0],
      pad7                 |-> [i \in 1 .. 7 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      securityId           |-> [i \in 1 .. 8 |-> 0],
      trdMatchId           |-> [i \in 1 .. 4 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0],
      lastQty              |-> [i \in 1 .. 8 |-> 0],
      lastPx               |-> [i \in 1 .. 8 |-> 0] ]

(* Full Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedFullOrderExecutionMessage ==
    { ZeroFullOrderExecutionMessage }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroFullOrderExecutionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }

(***************************************************************************)
(* Md Trade Entry Grp: 24 bytes                                            *)
(***************************************************************************)

MdTradeEntryGrp ==
    [ mdEntryPx   : Sample(8),
      mdEntrySize : Sample(8),
      mdEntryType : Sample(1),
      pad7        : Sample(7) ]

EncodeMdTradeEntryGrp(message) ==
    message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdEntryType
        \o message.pad7

DecodeMdTradeEntryGrp(bytes) ==
    LET mdEntryPx == ReadBytes(bytes, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdEntrySize.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET pad7 == ReadBytes(mdEntryType.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ mdEntryPx   |-> mdEntryPx.value,
         mdEntrySize |-> mdEntrySize.value,
         mdEntryType |-> mdEntryType.value,
         pad7        |-> pad7.value ], pad7.rest)

ZeroMdTradeEntryGrp ==
    [ mdEntryPx   |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize |-> [i \in 1 .. 8 |-> 0],
      mdEntryType |-> [i \in 1 .. 1 |-> 0],
      pad7        |-> [i \in 1 .. 7 |-> 0] ]

(* Md Trade Entry Grp at zero, then each field in turn at the values it is checked at *)
CheckedMdTradeEntryGrp ==
    { ZeroMdTradeEntryGrp }
        \cup { [ZeroMdTradeEntryGrp EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroMdTradeEntryGrp EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroMdTradeEntryGrp EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdTradeEntryGrp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Md Trade Entry Grp, written one after another *)
RECURSIVE EncodeMdTradeEntryGrpList(_)
EncodeMdTradeEntryGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdTradeEntryGrp(Head(messages)) \o EncodeMdTradeEntryGrpList(Tail(messages))

(* As many Md Trade Entry Grp as the field that counts them says *)
RECURSIVE ReadMdTradeEntryGrpList(_, _)
ReadMdTradeEntryGrpList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdTradeEntryGrp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdTradeEntryGrpList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Trade Entry Grp of each kind, for the lists that carry them *)
OneMdTradeEntryGrp == { ZeroMdTradeEntryGrp }

(* The 15 slots a run of Md Trade Entry Grp is written as, whatever the field beside it says are in use *)
SlotsMdTradeEntryGrp == { [i \in 1 .. 15 |-> one] : one \in OneMdTradeEntryGrp }

(***************************************************************************)
(* Trade Reversal Message                                                  *)
(***************************************************************************)

TradeReversalMessage ==
    [ securityId            : Sample(8),
      transactTime          : Sample(8),
      trdMatchId            : Sample(4),
      pad4                  : Sample(4),
      lastQty               : Sample(8),
      lastPx                : Sample(8),
      trdRegTsExecutionTime : Sample(8),
      noMdEntries           : 0 .. 255,
      pad7                  : Sample(7),
      mdTradeEntryGrp       : SlotsMdTradeEntryGrp ]

EncodeTradeReversalMessage(message) ==
    message.securityId
        \o message.transactTime
        \o message.trdMatchId
        \o message.pad4
        \o message.lastQty
        \o message.lastPx
        \o message.trdRegTsExecutionTime
        \o EncodeUIntLE(message.noMdEntries, 1)
        \o message.pad7
        \o EncodeMdTradeEntryGrpList(message.mdTradeEntryGrp)

DecodeTradeReversalMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(transactTime.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(trdMatchId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET lastQty == ReadBytes(pad4.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET trdRegTsExecutionTime == ReadBytes(lastPx.rest, 8) IN IF ~trdRegTsExecutionTime.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntLE(trdRegTsExecutionTime.rest, 1) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET pad7 == ReadBytes(noMdEntries.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET mdTradeEntryGrp == ReadMdTradeEntryGrpList(pad7.rest, 15) IN IF ~mdTradeEntryGrp.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         transactTime          |-> transactTime.value,
         trdMatchId            |-> trdMatchId.value,
         pad4                  |-> pad4.value,
         lastQty               |-> lastQty.value,
         lastPx                |-> lastPx.value,
         trdRegTsExecutionTime |-> trdRegTsExecutionTime.value,
         noMdEntries           |-> noMdEntries.value,
         pad7                  |-> pad7.value,
         mdTradeEntryGrp       |-> mdTradeEntryGrp.value ], mdTradeEntryGrp.rest)

ZeroTradeReversalMessage ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      trdMatchId            |-> [i \in 1 .. 4 |-> 0],
      pad4                  |-> [i \in 1 .. 4 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsExecutionTime |-> [i \in 1 .. 8 |-> 0],
      noMdEntries           |-> 0,
      pad7                  |-> [i \in 1 .. 7 |-> 0],
      mdTradeEntryGrp       |-> [i \in 1 .. 15 |-> ZeroMdTradeEntryGrp] ]

(* Trade Reversal Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReversalMessage ==
    { ZeroTradeReversalMessage }
        \cup { [ZeroTradeReversalMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversalMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversalMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeReversalMessage EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeReversalMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversalMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversalMessage EXCEPT !.trdRegTsExecutionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversalMessage EXCEPT !.noMdEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroTradeReversalMessage EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroTradeReversalMessage EXCEPT !.mdTradeEntryGrp = one] : one \in SlotsMdTradeEntryGrp }

(***************************************************************************)
(* Execution Summary Message: 56 bytes                                     *)
(***************************************************************************)

ExecutionSummaryMessage ==
    [ securityId         : Sample(8),
      aggressorTimestamp : Sample(8),
      execId             : Sample(8),
      lastQty            : Sample(8),
      aggressorSide      : Sample(1),
      tradeCondition     : Sample(1),
      pad6               : Sample(6),
      lastPx             : Sample(8),
      restingHiddenQty   : Sample(8) ]

EncodeExecutionSummaryMessage(message) ==
    message.securityId
        \o message.aggressorTimestamp
        \o message.execId
        \o message.lastQty
        \o message.aggressorSide
        \o message.tradeCondition
        \o message.pad6
        \o message.lastPx
        \o message.restingHiddenQty

DecodeExecutionSummaryMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET aggressorTimestamp == ReadBytes(securityId.rest, 8) IN IF ~aggressorTimestamp.ok THEN Fail ELSE
    LET execId == ReadBytes(aggressorTimestamp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(execId.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(lastQty.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(aggressorSide.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET pad6 == ReadBytes(tradeCondition.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET lastPx == ReadBytes(pad6.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET restingHiddenQty == ReadBytes(lastPx.rest, 8) IN IF ~restingHiddenQty.ok THEN Fail ELSE
    Ok([ securityId         |-> securityId.value,
         aggressorTimestamp |-> aggressorTimestamp.value,
         execId             |-> execId.value,
         lastQty            |-> lastQty.value,
         aggressorSide      |-> aggressorSide.value,
         tradeCondition     |-> tradeCondition.value,
         pad6               |-> pad6.value,
         lastPx             |-> lastPx.value,
         restingHiddenQty   |-> restingHiddenQty.value ], restingHiddenQty.rest)

ZeroExecutionSummaryMessage ==
    [ securityId         |-> [i \in 1 .. 8 |-> 0],
      aggressorTimestamp |-> [i \in 1 .. 8 |-> 0],
      execId             |-> [i \in 1 .. 8 |-> 0],
      lastQty            |-> [i \in 1 .. 8 |-> 0],
      aggressorSide      |-> [i \in 1 .. 1 |-> 0],
      tradeCondition     |-> [i \in 1 .. 1 |-> 0],
      pad6               |-> [i \in 1 .. 6 |-> 0],
      lastPx             |-> [i \in 1 .. 8 |-> 0],
      restingHiddenQty   |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionSummaryMessage ==
    { ZeroExecutionSummaryMessage }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.aggressorTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummaryMessage EXCEPT !.restingHiddenQty = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Info Message: 40 bytes                                       *)
(***************************************************************************)

InstrumentInfoMessage ==
    [ securityId     : Sample(8),
      closePrice     : Sample(8),
      prevClosePrice : Sample(8),
      upperCktLimit  : Sample(8),
      lowerCktLimit  : Sample(8) ]

EncodeInstrumentInfoMessage(message) ==
    message.securityId
        \o message.closePrice
        \o message.prevClosePrice
        \o message.upperCktLimit
        \o message.lowerCktLimit

DecodeInstrumentInfoMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET closePrice == ReadBytes(securityId.rest, 8) IN IF ~closePrice.ok THEN Fail ELSE
    LET prevClosePrice == ReadBytes(closePrice.rest, 8) IN IF ~prevClosePrice.ok THEN Fail ELSE
    LET upperCktLimit == ReadBytes(prevClosePrice.rest, 8) IN IF ~upperCktLimit.ok THEN Fail ELSE
    LET lowerCktLimit == ReadBytes(upperCktLimit.rest, 8) IN IF ~lowerCktLimit.ok THEN Fail ELSE
    Ok([ securityId     |-> securityId.value,
         closePrice     |-> closePrice.value,
         prevClosePrice |-> prevClosePrice.value,
         upperCktLimit  |-> upperCktLimit.value,
         lowerCktLimit  |-> lowerCktLimit.value ], lowerCktLimit.rest)

ZeroInstrumentInfoMessage ==
    [ securityId     |-> [i \in 1 .. 8 |-> 0],
      closePrice     |-> [i \in 1 .. 8 |-> 0],
      prevClosePrice |-> [i \in 1 .. 8 |-> 0],
      upperCktLimit  |-> [i \in 1 .. 8 |-> 0],
      lowerCktLimit  |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Info Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfoMessage ==
    { ZeroInstrumentInfoMessage }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.closePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.prevClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.upperCktLimit = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.lowerCktLimit = one] : one \in Sample(8) }

(***************************************************************************)
(* Lpp Range Message: 24 bytes                                             *)
(***************************************************************************)

LppRangeMessage ==
    [ securityId     : Sample(8),
      upperExecLimit : Sample(8),
      lowerExecLimit : Sample(8) ]

EncodeLppRangeMessage(message) ==
    message.securityId
        \o message.upperExecLimit
        \o message.lowerExecLimit

DecodeLppRangeMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET upperExecLimit == ReadBytes(securityId.rest, 8) IN IF ~upperExecLimit.ok THEN Fail ELSE
    LET lowerExecLimit == ReadBytes(upperExecLimit.rest, 8) IN IF ~lowerExecLimit.ok THEN Fail ELSE
    Ok([ securityId     |-> securityId.value,
         upperExecLimit |-> upperExecLimit.value,
         lowerExecLimit |-> lowerExecLimit.value ], lowerExecLimit.rest)

ZeroLppRangeMessage ==
    [ securityId     |-> [i \in 1 .. 8 |-> 0],
      upperExecLimit |-> [i \in 1 .. 8 |-> 0],
      lowerExecLimit |-> [i \in 1 .. 8 |-> 0] ]

(* Lpp Range Message at zero, then each field in turn at the values it is checked at *)
CheckedLppRangeMessage ==
    { ZeroLppRangeMessage }
        \cup { [ZeroLppRangeMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroLppRangeMessage EXCEPT !.upperExecLimit = one] : one \in Sample(8) }
        \cup { [ZeroLppRangeMessage EXCEPT !.lowerExecLimit = one] : one \in Sample(8) }

(***************************************************************************)
(* Product State Change Message: 16 bytes                                  *)
(***************************************************************************)

ProductStateChangeMessage ==
    [ tradingSessionId    : Sample(1),
      tradingSessionSubId : Sample(1),
      tradSesStatus       : Sample(1),
      fastMarketIndicator : Sample(1),
      pad4                : Sample(4),
      transactTime        : Sample(8) ]

EncodeProductStateChangeMessage(message) ==
    message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.tradSesStatus
        \o message.fastMarketIndicator
        \o message.pad4
        \o message.transactTime

DecodeProductStateChangeMessage(bytes) ==
    LET tradingSessionId == ReadBytes(bytes, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(tradSesStatus.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    LET pad4 == ReadBytes(fastMarketIndicator.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET transactTime == ReadBytes(pad4.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ tradingSessionId    |-> tradingSessionId.value,
         tradingSessionSubId |-> tradingSessionSubId.value,
         tradSesStatus       |-> tradSesStatus.value,
         fastMarketIndicator |-> fastMarketIndicator.value,
         pad4                |-> pad4.value,
         transactTime        |-> transactTime.value ], transactTime.rest)

ZeroProductStateChangeMessage ==
    [ tradingSessionId    |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId |-> [i \in 1 .. 1 |-> 0],
      tradSesStatus       |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator |-> [i \in 1 .. 1 |-> 0],
      pad4                |-> [i \in 1 .. 4 |-> 0],
      transactTime        |-> [i \in 1 .. 8 |-> 0] ]

(* Product State Change Message at zero, then each field in turn at the values it is checked at *)
CheckedProductStateChangeMessage ==
    { ZeroProductStateChangeMessage }
        \cup { [ZeroProductStateChangeMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChangeMessage EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChangeMessage EXCEPT !.tradSesStatus = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChangeMessage EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChangeMessage EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroProductStateChangeMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument State Change Message: 24 bytes                               *)
(***************************************************************************)

InstrumentStateChangeMessage ==
    [ securityId            : Sample(8),
      securityStatus        : Sample(1),
      securityTradingStatus : Sample(1),
      fastMarketIndicator   : Sample(1),
      pad5                  : Sample(5),
      transactTime          : Sample(8) ]

EncodeInstrumentStateChangeMessage(message) ==
    message.securityId
        \o message.securityStatus
        \o message.securityTradingStatus
        \o message.fastMarketIndicator
        \o message.pad5
        \o message.transactTime

DecodeInstrumentStateChangeMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(securityId.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityStatus.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(securityTradingStatus.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    LET pad5 == ReadBytes(fastMarketIndicator.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    LET transactTime == ReadBytes(pad5.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         securityStatus        |-> securityStatus.value,
         securityTradingStatus |-> securityTradingStatus.value,
         fastMarketIndicator   |-> fastMarketIndicator.value,
         pad5                  |-> pad5.value,
         transactTime          |-> transactTime.value ], transactTime.rest)

ZeroInstrumentStateChangeMessage ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      securityStatus        |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator   |-> [i \in 1 .. 1 |-> 0],
      pad5                  |-> [i \in 1 .. 5 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument State Change Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStateChangeMessage ==
    { ZeroInstrumentStateChangeMessage }
        \cup { [ZeroInstrumentStateChangeMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStateChangeMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChangeMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChangeMessage EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChangeMessage EXCEPT !.pad5 = one] : one \in Sample(5) }
        \cup { [ZeroInstrumentStateChangeMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrmt Leg Grp: 16 bytes                                               *)
(***************************************************************************)

InstrmtLegGrp ==
    [ legSecurityId : Sample(8),
      legRatioQty   : Sample(4),
      legSide       : Sample(1),
      pad3          : Sample(3) ]

EncodeInstrmtLegGrp(message) ==
    message.legSecurityId
        \o message.legRatioQty
        \o message.legSide
        \o message.pad3

DecodeInstrmtLegGrp(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSecurityId.rest, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET pad3 == ReadBytes(legSide.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legRatioQty   |-> legRatioQty.value,
         legSide       |-> legSide.value,
         pad3          |-> pad3.value ], pad3.rest)

ZeroInstrmtLegGrp ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legRatioQty   |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0],
      pad3          |-> [i \in 1 .. 3 |-> 0] ]

(* Instrmt Leg Grp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmtLegGrp ==
    { ZeroInstrmtLegGrp }
        \cup { [ZeroInstrmtLegGrp EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtLegGrp EXCEPT !.legRatioQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtLegGrp EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtLegGrp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Instrmt Leg Grp, written one after another *)
RECURSIVE EncodeInstrmtLegGrpList(_)
EncodeInstrmtLegGrpList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmtLegGrp(Head(messages)) \o EncodeInstrmtLegGrpList(Tail(messages))

(* As many Instrmt Leg Grp as the field that counts them says *)
RECURSIVE ReadInstrmtLegGrpList(_, _)
ReadInstrmtLegGrpList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmtLegGrp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmtLegGrpList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmt Leg Grp of each kind, for the lists that carry them *)
OneInstrmtLegGrp == { ZeroInstrmtLegGrp }

(* The 5 slots a run of Instrmt Leg Grp is written as, whatever the field beside it says are in use *)
SlotsInstrmtLegGrp == { [i \in 1 .. 5 |-> one] : one \in OneInstrmtLegGrp }

(***************************************************************************)
(* Add Complex Instrument Message                                          *)
(***************************************************************************)

AddComplexInstrumentMessage ==
    [ securityId             : Sample(8),
      transactTime           : Sample(8),
      securitySubType        : Sample(4),
      productComplex         : Sample(1),
      impliedMarketIndicator : Sample(1),
      noLegs                 : 0 .. 255,
      pad1                   : Sample(1),
      instrmtLegGrp          : SlotsInstrmtLegGrp ]

EncodeAddComplexInstrumentMessage(message) ==
    message.securityId
        \o message.transactTime
        \o message.securitySubType
        \o message.productComplex
        \o message.impliedMarketIndicator
        \o EncodeUIntLE(message.noLegs, 1)
        \o message.pad1
        \o EncodeInstrmtLegGrpList(message.instrmtLegGrp)

DecodeAddComplexInstrumentMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(transactTime.rest, 4) IN IF ~securitySubType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(securitySubType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET impliedMarketIndicator == ReadBytes(productComplex.rest, 1) IN IF ~impliedMarketIndicator.ok THEN Fail ELSE
    LET noLegs == ReadUIntLE(impliedMarketIndicator.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET pad1 == ReadBytes(noLegs.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET instrmtLegGrp == ReadInstrmtLegGrpList(pad1.rest, 5) IN IF ~instrmtLegGrp.ok THEN Fail ELSE
    Ok([ securityId             |-> securityId.value,
         transactTime           |-> transactTime.value,
         securitySubType        |-> securitySubType.value,
         productComplex         |-> productComplex.value,
         impliedMarketIndicator |-> impliedMarketIndicator.value,
         noLegs                 |-> noLegs.value,
         pad1                   |-> pad1.value,
         instrmtLegGrp          |-> instrmtLegGrp.value ], instrmtLegGrp.rest)

ZeroAddComplexInstrumentMessage ==
    [ securityId             |-> [i \in 1 .. 8 |-> 0],
      transactTime           |-> [i \in 1 .. 8 |-> 0],
      securitySubType        |-> [i \in 1 .. 4 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      impliedMarketIndicator |-> [i \in 1 .. 1 |-> 0],
      noLegs                 |-> 0,
      pad1                   |-> [i \in 1 .. 1 |-> 0],
      instrmtLegGrp          |-> [i \in 1 .. 5 |-> ZeroInstrmtLegGrp] ]

(* Add Complex Instrument Message at zero, then each field in turn at the values it is checked at *)
CheckedAddComplexInstrumentMessage ==
    { ZeroAddComplexInstrumentMessage }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.securitySubType = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.impliedMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.noLegs = one] : one \in {0, 1, 255} }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.instrmtLegGrp = one] : one \in SlotsInstrmtLegGrp }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

HeartbeatMessageCode == 13001  \* 0x32c9
ProductSummaryMessageCode == 13600  \* 0x3520
SnapshotOrderMessageCode == 13602  \* 0x3522
InstrumentSummaryMessageCode == 13601  \* 0x3521
AuctionBestBidOfferMessageCode == 13500  \* 0x34bc
AuctionClearingPriceMessageCode == 13501  \* 0x34bd
TopOfBookMessageCode == 13504  \* 0x34c0
OrderAddMessageCode == 13100  \* 0x332c
OrderModifyMessageCode == 13101  \* 0x332d
OrderModifySamePriorityMessageCode == 13106  \* 0x3332
OrderDeleteMessageCode == 13102  \* 0x332e
OrderMassDeleteMessageCode == 13103  \* 0x332f
PartialOrderExecutionMessageCode == 13105  \* 0x3331
FullOrderExecutionMessageCode == 13104  \* 0x3330
TradeReversalMessageCode == 13200  \* 0x3390
ExecutionSummaryMessageCode == 13202  \* 0x3392
InstrumentInfoMessageCode == 13203  \* 0x3393
LppRangeMessageCode == 13204  \* 0x3394
ProductStateChangeMessageCode == 13300  \* 0x33f4
InstrumentStateChangeMessageCode == 13301  \* 0x33f5
AddComplexInstrumentMessageCode == 13400  \* 0x3458

Payload ==
    [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {ProductSummaryMessageCode}, body : ProductSummaryMessage ]
        \cup [ tag : {SnapshotOrderMessageCode}, body : SnapshotOrderMessage ]
        \cup [ tag : {InstrumentSummaryMessageCode}, body : InstrumentSummaryMessage ]
        \cup [ tag : {AuctionBestBidOfferMessageCode}, body : AuctionBestBidOfferMessage ]
        \cup [ tag : {AuctionClearingPriceMessageCode}, body : AuctionClearingPriceMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]
        \cup [ tag : {OrderAddMessageCode}, body : OrderAddMessage ]
        \cup [ tag : {OrderModifyMessageCode}, body : OrderModifyMessage ]
        \cup [ tag : {OrderModifySamePriorityMessageCode}, body : OrderModifySamePriorityMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderMassDeleteMessageCode}, body : OrderMassDeleteMessage ]
        \cup [ tag : {PartialOrderExecutionMessageCode}, body : PartialOrderExecutionMessage ]
        \cup [ tag : {FullOrderExecutionMessageCode}, body : FullOrderExecutionMessage ]
        \cup [ tag : {TradeReversalMessageCode}, body : TradeReversalMessage ]
        \cup [ tag : {ExecutionSummaryMessageCode}, body : ExecutionSummaryMessage ]
        \cup [ tag : {InstrumentInfoMessageCode}, body : InstrumentInfoMessage ]
        \cup [ tag : {LppRangeMessageCode}, body : LppRangeMessage ]
        \cup [ tag : {ProductStateChangeMessageCode}, body : ProductStateChangeMessage ]
        \cup [ tag : {InstrumentStateChangeMessageCode}, body : InstrumentStateChangeMessage ]
        \cup [ tag : {AddComplexInstrumentMessageCode}, body : AddComplexInstrumentMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = ProductSummaryMessageCode -> EncodeProductSummaryMessage(message.body)
      [] message.tag = SnapshotOrderMessageCode -> EncodeSnapshotOrderMessage(message.body)
      [] message.tag = InstrumentSummaryMessageCode -> EncodeInstrumentSummaryMessage(message.body)
      [] message.tag = AuctionBestBidOfferMessageCode -> EncodeAuctionBestBidOfferMessage(message.body)
      [] message.tag = AuctionClearingPriceMessageCode -> EncodeAuctionClearingPriceMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)
      [] message.tag = OrderAddMessageCode -> EncodeOrderAddMessage(message.body)
      [] message.tag = OrderModifyMessageCode -> EncodeOrderModifyMessage(message.body)
      [] message.tag = OrderModifySamePriorityMessageCode -> EncodeOrderModifySamePriorityMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderMassDeleteMessageCode -> EncodeOrderMassDeleteMessage(message.body)
      [] message.tag = PartialOrderExecutionMessageCode -> EncodePartialOrderExecutionMessage(message.body)
      [] message.tag = FullOrderExecutionMessageCode -> EncodeFullOrderExecutionMessage(message.body)
      [] message.tag = TradeReversalMessageCode -> EncodeTradeReversalMessage(message.body)
      [] message.tag = ExecutionSummaryMessageCode -> EncodeExecutionSummaryMessage(message.body)
      [] message.tag = InstrumentInfoMessageCode -> EncodeInstrumentInfoMessage(message.body)
      [] message.tag = LppRangeMessageCode -> EncodeLppRangeMessage(message.body)
      [] message.tag = ProductStateChangeMessageCode -> EncodeProductStateChangeMessage(message.body)
      [] message.tag = InstrumentStateChangeMessageCode -> EncodeInstrumentStateChangeMessage(message.body)
      [] message.tag = AddComplexInstrumentMessageCode -> EncodeAddComplexInstrumentMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] tag = ProductSummaryMessageCode -> DecodeProductSummaryMessage(bytes)
              [] tag = SnapshotOrderMessageCode -> DecodeSnapshotOrderMessage(bytes)
              [] tag = InstrumentSummaryMessageCode -> DecodeInstrumentSummaryMessage(bytes)
              [] tag = AuctionBestBidOfferMessageCode -> DecodeAuctionBestBidOfferMessage(bytes)
              [] tag = AuctionClearingPriceMessageCode -> DecodeAuctionClearingPriceMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] tag = OrderAddMessageCode -> DecodeOrderAddMessage(bytes)
              [] tag = OrderModifyMessageCode -> DecodeOrderModifyMessage(bytes)
              [] tag = OrderModifySamePriorityMessageCode -> DecodeOrderModifySamePriorityMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderMassDeleteMessageCode -> DecodeOrderMassDeleteMessage(bytes)
              [] tag = PartialOrderExecutionMessageCode -> DecodePartialOrderExecutionMessage(bytes)
              [] tag = FullOrderExecutionMessageCode -> DecodeFullOrderExecutionMessage(bytes)
              [] tag = TradeReversalMessageCode -> DecodeTradeReversalMessage(bytes)
              [] tag = ExecutionSummaryMessageCode -> DecodeExecutionSummaryMessage(bytes)
              [] tag = InstrumentInfoMessageCode -> DecodeInstrumentInfoMessage(bytes)
              [] tag = LppRangeMessageCode -> DecodeLppRangeMessage(bytes)
              [] tag = ProductStateChangeMessageCode -> DecodeProductStateChangeMessage(bytes)
              [] tag = InstrumentStateChangeMessageCode -> DecodeInstrumentStateChangeMessage(bytes)
              [] tag = AddComplexInstrumentMessageCode -> DecodeAddComplexInstrumentMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> ZeroHeartbeatMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }
        \cup { [tag |-> ProductSummaryMessageCode, body |-> one] : one \in CheckedProductSummaryMessage }
        \cup { [tag |-> SnapshotOrderMessageCode, body |-> one] : one \in CheckedSnapshotOrderMessage }
        \cup { [tag |-> InstrumentSummaryMessageCode, body |-> one] : one \in CheckedInstrumentSummaryMessage }
        \cup { [tag |-> AuctionBestBidOfferMessageCode, body |-> one] : one \in CheckedAuctionBestBidOfferMessage }
        \cup { [tag |-> AuctionClearingPriceMessageCode, body |-> one] : one \in CheckedAuctionClearingPriceMessage }
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }
        \cup { [tag |-> OrderAddMessageCode, body |-> one] : one \in CheckedOrderAddMessage }
        \cup { [tag |-> OrderModifyMessageCode, body |-> one] : one \in CheckedOrderModifyMessage }
        \cup { [tag |-> OrderModifySamePriorityMessageCode, body |-> one] : one \in CheckedOrderModifySamePriorityMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderMassDeleteMessageCode, body |-> one] : one \in CheckedOrderMassDeleteMessage }
        \cup { [tag |-> PartialOrderExecutionMessageCode, body |-> one] : one \in CheckedPartialOrderExecutionMessage }
        \cup { [tag |-> FullOrderExecutionMessageCode, body |-> one] : one \in CheckedFullOrderExecutionMessage }
        \cup { [tag |-> TradeReversalMessageCode, body |-> one] : one \in CheckedTradeReversalMessage }
        \cup { [tag |-> ExecutionSummaryMessageCode, body |-> one] : one \in CheckedExecutionSummaryMessage }
        \cup { [tag |-> InstrumentInfoMessageCode, body |-> one] : one \in CheckedInstrumentInfoMessage }
        \cup { [tag |-> LppRangeMessageCode, body |-> one] : one \in CheckedLppRangeMessage }
        \cup { [tag |-> ProductStateChangeMessageCode, body |-> one] : one \in CheckedProductStateChangeMessage }
        \cup { [tag |-> InstrumentStateChangeMessageCode, body |-> one] : one \in CheckedInstrumentStateChangeMessage }
        \cup { [tag |-> AddComplexInstrumentMessageCode, body |-> one] : one \in CheckedAddComplexInstrumentMessage }

(***************************************************************************)
(* Message, framed by Body Len                                             *)
(***************************************************************************)

Message ==
    [ msgSeqNum : Sample(4),
      payload   : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o message.msgSeqNum
        \o EncodePayload(message.payload)

(* Body Len counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET templateId == ReadUIntLE(bytes, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(templateId.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, msgSeqNum.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSeqNum |-> msgSeqNum.value,
         payload   |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ msgSeqNum |-> [i \in 1 .. 4 |-> 0],
      payload   |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> ZeroHeartbeatMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ProductSummaryMessageCode, body |-> ZeroProductSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotOrderMessageCode, body |-> ZeroSnapshotOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentSummaryMessageCode, body |-> ZeroInstrumentSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionBestBidOfferMessageCode, body |-> ZeroAuctionBestBidOfferMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionClearingPriceMessageCode, body |-> ZeroAuctionClearingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddMessageCode, body |-> ZeroOrderAddMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyMessageCode, body |-> ZeroOrderModifyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifySamePriorityMessageCode, body |-> ZeroOrderModifySamePriorityMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMassDeleteMessageCode, body |-> ZeroOrderMassDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PartialOrderExecutionMessageCode, body |-> ZeroPartialOrderExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FullOrderExecutionMessageCode, body |-> ZeroFullOrderExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReversalMessageCode, body |-> ZeroTradeReversalMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionSummaryMessageCode, body |-> ZeroExecutionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentInfoMessageCode, body |-> ZeroInstrumentInfoMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LppRangeMessageCode, body |-> ZeroLppRangeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ProductStateChangeMessageCode, body |-> ZeroProductStateChangeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStateChangeMessageCode, body |-> ZeroInstrumentStateChangeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddComplexInstrumentMessageCode, body |-> ZeroAddComplexInstrumentMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetHeader : PacketHeader,
      message      : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodePacketHeader(message.packetHeader)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET packetHeader == DecodePacketHeader(bytes) IN IF ~packetHeader.ok THEN Fail ELSE
    LET message == ReadMessageAll(packetHeader.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ packetHeader |-> packetHeader.value,
         message      |-> message.value ], message.rest)

ZeroPacket ==
    [ packetHeader |-> ZeroPacketHeader,
      message      |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetHeader = one] : one \in CheckedPacketHeader }
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

(* Every Eobi Header decodes back to what was encoded, and leaves nothing over *)
RoundTripEobiHeader ==
    \A message \in CheckedEobiHeader :
        LET read == DecodeEobiHeader(EncodeEobiHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripPacketHeader ==
    \A message \in CheckedPacketHeader :
        LET read == DecodePacketHeader(EncodePacketHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatMessage ==
    \A message \in CheckedHeartbeatMessage :
        LET read == DecodeHeartbeatMessage(EncodeHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripProductSummaryMessage ==
    \A message \in CheckedProductSummaryMessage :
        LET read == DecodeProductSummaryMessage(EncodeProductSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Details decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetails ==
    \A message \in CheckedOrderDetails :
        LET read == DecodeOrderDetails(EncodeOrderDetails(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotOrderMessage ==
    \A message \in CheckedSnapshotOrderMessage :
        LET read == DecodeSnapshotOrderMessage(EncodeSnapshotOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Instrument Entry Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentEntryGrp ==
    \A message \in CheckedMdInstrumentEntryGrp :
        LET read == DecodeMdInstrumentEntryGrp(EncodeMdInstrumentEntryGrp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentSummaryMessage ==
    \A message \in CheckedInstrumentSummaryMessage :
        LET read == DecodeInstrumentSummaryMessage(EncodeInstrumentSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Best Bid Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionBestBidOfferMessage ==
    \A message \in CheckedAuctionBestBidOfferMessage :
        LET read == DecodeAuctionBestBidOfferMessage(EncodeAuctionBestBidOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Clearing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionClearingPriceMessage ==
    \A message \in CheckedAuctionClearingPriceMessage :
        LET read == DecodeAuctionClearingPriceMessage(EncodeAuctionClearingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Of Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfBookMessage ==
    \A message \in CheckedTopOfBookMessage :
        LET read == DecodeTopOfBookMessage(EncodeTopOfBookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Details decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetails2 ==
    \A message \in CheckedOrderDetails2 :
        LET read == DecodeOrderDetails2(EncodeOrderDetails2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddMessage ==
    \A message \in CheckedOrderAddMessage :
        LET read == DecodeOrderAddMessage(EncodeOrderAddMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Details decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetails3 ==
    \A message \in CheckedOrderDetails3 :
        LET read == DecodeOrderDetails3(EncodeOrderDetails3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyMessage ==
    \A message \in CheckedOrderModifyMessage :
        LET read == DecodeOrderModifyMessage(EncodeOrderModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Details decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetails4 ==
    \A message \in CheckedOrderDetails4 :
        LET read == DecodeOrderDetails4(EncodeOrderDetails4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Same Priority Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifySamePriorityMessage ==
    \A message \in CheckedOrderModifySamePriorityMessage :
        LET read == DecodeOrderModifySamePriorityMessage(EncodeOrderModifySamePriorityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Details decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetails5 ==
    \A message \in CheckedOrderDetails5 :
        LET read == DecodeOrderDetails5(EncodeOrderDetails5(message))
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

(* Every Order Mass Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassDeleteMessage ==
    \A message \in CheckedOrderMassDeleteMessage :
        LET read == DecodeOrderMassDeleteMessage(EncodeOrderMassDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialOrderExecutionMessage ==
    \A message \in CheckedPartialOrderExecutionMessage :
        LET read == DecodePartialOrderExecutionMessage(EncodePartialOrderExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Full Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFullOrderExecutionMessage ==
    \A message \in CheckedFullOrderExecutionMessage :
        LET read == DecodeFullOrderExecutionMessage(EncodeFullOrderExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Trade Entry Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripMdTradeEntryGrp ==
    \A message \in CheckedMdTradeEntryGrp :
        LET read == DecodeMdTradeEntryGrp(EncodeMdTradeEntryGrp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Reversal Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReversalMessage ==
    \A message \in CheckedTradeReversalMessage :
        LET read == DecodeTradeReversalMessage(EncodeTradeReversalMessage(message))
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

(* Every Instrument Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfoMessage ==
    \A message \in CheckedInstrumentInfoMessage :
        LET read == DecodeInstrumentInfoMessage(EncodeInstrumentInfoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lpp Range Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLppRangeMessage ==
    \A message \in CheckedLppRangeMessage :
        LET read == DecodeLppRangeMessage(EncodeLppRangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product State Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripProductStateChangeMessage ==
    \A message \in CheckedProductStateChangeMessage :
        LET read == DecodeProductStateChangeMessage(EncodeProductStateChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument State Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStateChangeMessage ==
    \A message \in CheckedInstrumentStateChangeMessage :
        LET read == DecodeInstrumentStateChangeMessage(EncodeInstrumentStateChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrmt Leg Grp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmtLegGrp ==
    \A message \in CheckedInstrmtLegGrp :
        LET read == DecodeInstrmtLegGrp(EncodeInstrmtLegGrp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Complex Instrument Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddComplexInstrumentMessage ==
    \A message \in CheckedAddComplexInstrumentMessage :
        LET read == DecodeAddComplexInstrumentMessage(EncodeAddComplexInstrumentMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Body Len is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
