------------------------ MODULE Eurex_T7_Eobi_v10_0 ------------------------
(***************************************************************************)
(* Eurex Exchange Enhanced Order Book Interface v10.0                      *)
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
(* Note: Instrmt Leg Grp Comp is written as 20 slots, however many of them *)
(* No Legs says are in use.                                                *)
(*                                                                         *)
(* Note: Md Instrument Entry Grp Comp is written as 15 slots, however many *)
(* of them No Md Entries says are in use.                                  *)
(*                                                                         *)
(* Note: Sec Mass Stat Grp Comp is written as 24 slots, however many of    *)
(* them No Related Sym says are in use.                                    *)
(*                                                                         *)
(* Note: Md Trade Entry Grp Comp is written as 15 slots, however many of   *)
(* them No Md Entries says are in use.                                     *)
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
      dscp                  : Sample(1),
      pad4                  : Sample(4),
      transactTime          : Sample(8) ]

EncodePacketHeader(message) ==
    EncodeEobiHeader(message.eobiHeader)
        \o message.applSeqNum
        \o message.marketSegmentId
        \o message.partitionId
        \o message.completionIndicator
        \o message.applSeqResetIndicator
        \o message.dscp
        \o message.pad4
        \o message.transactTime

DecodePacketHeader(bytes) ==
    LET eobiHeader == DecodeEobiHeader(bytes) IN IF ~eobiHeader.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(eobiHeader.rest, 4) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(applSeqNum.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(marketSegmentId.rest, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET completionIndicator == ReadBytes(partitionId.rest, 1) IN IF ~completionIndicator.ok THEN Fail ELSE
    LET applSeqResetIndicator == ReadBytes(completionIndicator.rest, 1) IN IF ~applSeqResetIndicator.ok THEN Fail ELSE
    LET dscp == ReadBytes(applSeqResetIndicator.rest, 1) IN IF ~dscp.ok THEN Fail ELSE
    LET pad4 == ReadBytes(dscp.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET transactTime == ReadBytes(pad4.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ eobiHeader            |-> eobiHeader.value,
         applSeqNum            |-> applSeqNum.value,
         marketSegmentId       |-> marketSegmentId.value,
         partitionId           |-> partitionId.value,
         completionIndicator   |-> completionIndicator.value,
         applSeqResetIndicator |-> applSeqResetIndicator.value,
         dscp                  |-> dscp.value,
         pad4                  |-> pad4.value,
         transactTime          |-> transactTime.value ], transactTime.rest)

ZeroPacketHeader ==
    [ eobiHeader            |-> ZeroEobiHeader,
      applSeqNum            |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      partitionId           |-> [i \in 1 .. 1 |-> 0],
      completionIndicator   |-> [i \in 1 .. 1 |-> 0],
      applSeqResetIndicator |-> [i \in 1 .. 1 |-> 0],
      dscp                  |-> [i \in 1 .. 1 |-> 0],
      pad4                  |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroPacketHeader EXCEPT !.dscp = one] : one \in Sample(1) }
        \cup { [ZeroPacketHeader EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroPacketHeader EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrmt Leg Grp Comp: 32 bytes                                          *)
(***************************************************************************)

InstrmtLegGrpComp ==
    [ legSymbol       : Sample(4),
      pad4            : Sample(4),
      legSecurityId   : Sample(8),
      legPrice        : Sample(8),
      legRatioQty     : Sample(4),
      legSecurityType : Sample(1),
      legSide         : Sample(1),
      pad2            : Sample(2) ]

EncodeInstrmtLegGrpComp(message) ==
    message.legSymbol
        \o message.pad4
        \o message.legSecurityId
        \o message.legPrice
        \o message.legRatioQty
        \o message.legSecurityType
        \o message.legSide
        \o message.pad2

DecodeInstrmtLegGrpComp(bytes) ==
    LET legSymbol == ReadBytes(bytes, 4) IN IF ~legSymbol.ok THEN Fail ELSE
    LET pad4 == ReadBytes(legSymbol.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(pad4.rest, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSecurityId.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legPrice.rest, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legRatioQty.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSecurityType.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET pad2 == ReadBytes(legSide.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ legSymbol       |-> legSymbol.value,
         pad4            |-> pad4.value,
         legSecurityId   |-> legSecurityId.value,
         legPrice        |-> legPrice.value,
         legRatioQty     |-> legRatioQty.value,
         legSecurityType |-> legSecurityType.value,
         legSide         |-> legSide.value,
         pad2            |-> pad2.value ], pad2.rest)

ZeroInstrmtLegGrpComp ==
    [ legSymbol       |-> [i \in 1 .. 4 |-> 0],
      pad4            |-> [i \in 1 .. 4 |-> 0],
      legSecurityId   |-> [i \in 1 .. 8 |-> 0],
      legPrice        |-> [i \in 1 .. 8 |-> 0],
      legRatioQty     |-> [i \in 1 .. 4 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      pad2            |-> [i \in 1 .. 2 |-> 0] ]

(* Instrmt Leg Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmtLegGrpComp ==
    { ZeroInstrmtLegGrpComp }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSymbol = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legRatioQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.pad2 = one] : one \in Sample(2) }

(* A run of Instrmt Leg Grp Comp, written one after another *)
RECURSIVE EncodeInstrmtLegGrpCompList(_)
EncodeInstrmtLegGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmtLegGrpComp(Head(messages)) \o EncodeInstrmtLegGrpCompList(Tail(messages))

(* As many Instrmt Leg Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmtLegGrpCompList(_, _)
ReadInstrmtLegGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmtLegGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmtLegGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmt Leg Grp Comp of each kind, for the lists that carry them *)
OneInstrmtLegGrpComp == { ZeroInstrmtLegGrpComp }

(* The 20 slots a run of Instrmt Leg Grp Comp is written as, whatever the field beside it says are in use *)
SlotsInstrmtLegGrpComp == { [i \in 1 .. 20 |-> one] : one \in OneInstrmtLegGrpComp }

(***************************************************************************)
(* Add Complex Instrument                                                  *)
(***************************************************************************)

AddComplexInstrument ==
    [ securityId             : Sample(8),
      transactTime           : Sample(8),
      securitySubType        : Sample(4),
      productComplex         : Sample(1),
      impliedMarketIndicator : Sample(1),
      pad2                   : Sample(2),
      legRatioMultiplier     : Sample(4),
      noLegs                 : 0 .. 255,
      pad3                   : Sample(3),
      instrmtLegGrpComp      : SlotsInstrmtLegGrpComp ]

EncodeAddComplexInstrument(message) ==
    message.securityId
        \o message.transactTime
        \o message.securitySubType
        \o message.productComplex
        \o message.impliedMarketIndicator
        \o message.pad2
        \o message.legRatioMultiplier
        \o EncodeUIntBE(message.noLegs, 1)
        \o message.pad3
        \o EncodeInstrmtLegGrpCompList(message.instrmtLegGrpComp)

DecodeAddComplexInstrument(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(transactTime.rest, 4) IN IF ~securitySubType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(securitySubType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET impliedMarketIndicator == ReadBytes(productComplex.rest, 1) IN IF ~impliedMarketIndicator.ok THEN Fail ELSE
    LET pad2 == ReadBytes(impliedMarketIndicator.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET legRatioMultiplier == ReadBytes(pad2.rest, 4) IN IF ~legRatioMultiplier.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(legRatioMultiplier.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET pad3 == ReadBytes(noLegs.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET instrmtLegGrpComp == ReadInstrmtLegGrpCompList(pad3.rest, 20) IN IF ~instrmtLegGrpComp.ok THEN Fail ELSE
    Ok([ securityId             |-> securityId.value,
         transactTime           |-> transactTime.value,
         securitySubType        |-> securitySubType.value,
         productComplex         |-> productComplex.value,
         impliedMarketIndicator |-> impliedMarketIndicator.value,
         pad2                   |-> pad2.value,
         legRatioMultiplier     |-> legRatioMultiplier.value,
         noLegs                 |-> noLegs.value,
         pad3                   |-> pad3.value,
         instrmtLegGrpComp      |-> instrmtLegGrpComp.value ], instrmtLegGrpComp.rest)

ZeroAddComplexInstrument ==
    [ securityId             |-> [i \in 1 .. 8 |-> 0],
      transactTime           |-> [i \in 1 .. 8 |-> 0],
      securitySubType        |-> [i \in 1 .. 4 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      impliedMarketIndicator |-> [i \in 1 .. 1 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      legRatioMultiplier     |-> [i \in 1 .. 4 |-> 0],
      noLegs                 |-> 0,
      pad3                   |-> [i \in 1 .. 3 |-> 0],
      instrmtLegGrpComp      |-> [i \in 1 .. 20 |-> ZeroInstrmtLegGrpComp] ]

(* Add Complex Instrument at zero, then each field in turn at the values it is checked at *)
CheckedAddComplexInstrument ==
    { ZeroAddComplexInstrument }
        \cup { [ZeroAddComplexInstrument EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrument EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrument EXCEPT !.securitySubType = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrument EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrument EXCEPT !.impliedMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrument EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroAddComplexInstrument EXCEPT !.legRatioMultiplier = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrument EXCEPT !.noLegs = one] : one \in {0, 1, 255} }
        \cup { [ZeroAddComplexInstrument EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroAddComplexInstrument EXCEPT !.instrmtLegGrpComp = one] : one \in SlotsInstrmtLegGrpComp }

(***************************************************************************)
(* Auction Bbo: 56 bytes                                                   *)
(***************************************************************************)

AuctionBbo ==
    [ transactTime                  : Sample(8),
      securityId                    : Sample(8),
      bidPx                         : Sample(8),
      offerPx                       : Sample(8),
      bidSize                       : Sample(8),
      offerSize                     : Sample(8),
      potentialSecurityTradingEvent : Sample(1),
      bidOrdType                    : Sample(1),
      offerOrdType                  : Sample(1),
      pad5                          : Sample(5) ]

EncodeAuctionBbo(message) ==
    message.transactTime
        \o message.securityId
        \o message.bidPx
        \o message.offerPx
        \o message.bidSize
        \o message.offerSize
        \o message.potentialSecurityTradingEvent
        \o message.bidOrdType
        \o message.offerOrdType
        \o message.pad5

DecodeAuctionBbo(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(offerPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET potentialSecurityTradingEvent == ReadBytes(offerSize.rest, 1) IN IF ~potentialSecurityTradingEvent.ok THEN Fail ELSE
    LET bidOrdType == ReadBytes(potentialSecurityTradingEvent.rest, 1) IN IF ~bidOrdType.ok THEN Fail ELSE
    LET offerOrdType == ReadBytes(bidOrdType.rest, 1) IN IF ~offerOrdType.ok THEN Fail ELSE
    LET pad5 == ReadBytes(offerOrdType.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ transactTime                  |-> transactTime.value,
         securityId                    |-> securityId.value,
         bidPx                         |-> bidPx.value,
         offerPx                       |-> offerPx.value,
         bidSize                       |-> bidSize.value,
         offerSize                     |-> offerSize.value,
         potentialSecurityTradingEvent |-> potentialSecurityTradingEvent.value,
         bidOrdType                    |-> bidOrdType.value,
         offerOrdType                  |-> offerOrdType.value,
         pad5                          |-> pad5.value ], pad5.rest)

ZeroAuctionBbo ==
    [ transactTime                  |-> [i \in 1 .. 8 |-> 0],
      securityId                    |-> [i \in 1 .. 8 |-> 0],
      bidPx                         |-> [i \in 1 .. 8 |-> 0],
      offerPx                       |-> [i \in 1 .. 8 |-> 0],
      bidSize                       |-> [i \in 1 .. 8 |-> 0],
      offerSize                     |-> [i \in 1 .. 8 |-> 0],
      potentialSecurityTradingEvent |-> [i \in 1 .. 1 |-> 0],
      bidOrdType                    |-> [i \in 1 .. 1 |-> 0],
      offerOrdType                  |-> [i \in 1 .. 1 |-> 0],
      pad5                          |-> [i \in 1 .. 5 |-> 0] ]

(* Auction Bbo at zero, then each field in turn at the values it is checked at *)
CheckedAuctionBbo ==
    { ZeroAuctionBbo }
        \cup { [ZeroAuctionBbo EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBbo EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBbo EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBbo EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBbo EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBbo EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBbo EXCEPT !.potentialSecurityTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroAuctionBbo EXCEPT !.bidOrdType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionBbo EXCEPT !.offerOrdType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionBbo EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Auction Clearing Price: 48 bytes                                        *)
(***************************************************************************)

AuctionClearingPrice ==
    [ transactTime                  : Sample(8),
      securityId                    : Sample(8),
      lastPx                        : Sample(8),
      lastQty                       : Sample(8),
      imbalanceQty                  : Sample(8),
      securityTradingStatus         : Sample(1),
      potentialSecurityTradingEvent : Sample(1),
      pad6                          : Sample(6) ]

EncodeAuctionClearingPrice(message) ==
    message.transactTime
        \o message.securityId
        \o message.lastPx
        \o message.lastQty
        \o message.imbalanceQty
        \o message.securityTradingStatus
        \o message.potentialSecurityTradingEvent
        \o message.pad6

DecodeAuctionClearingPrice(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET imbalanceQty == ReadBytes(lastQty.rest, 8) IN IF ~imbalanceQty.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(imbalanceQty.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET potentialSecurityTradingEvent == ReadBytes(securityTradingStatus.rest, 1) IN IF ~potentialSecurityTradingEvent.ok THEN Fail ELSE
    LET pad6 == ReadBytes(potentialSecurityTradingEvent.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ transactTime                  |-> transactTime.value,
         securityId                    |-> securityId.value,
         lastPx                        |-> lastPx.value,
         lastQty                       |-> lastQty.value,
         imbalanceQty                  |-> imbalanceQty.value,
         securityTradingStatus         |-> securityTradingStatus.value,
         potentialSecurityTradingEvent |-> potentialSecurityTradingEvent.value,
         pad6                          |-> pad6.value ], pad6.rest)

ZeroAuctionClearingPrice ==
    [ transactTime                  |-> [i \in 1 .. 8 |-> 0],
      securityId                    |-> [i \in 1 .. 8 |-> 0],
      lastPx                        |-> [i \in 1 .. 8 |-> 0],
      lastQty                       |-> [i \in 1 .. 8 |-> 0],
      imbalanceQty                  |-> [i \in 1 .. 8 |-> 0],
      securityTradingStatus         |-> [i \in 1 .. 1 |-> 0],
      potentialSecurityTradingEvent |-> [i \in 1 .. 1 |-> 0],
      pad6                          |-> [i \in 1 .. 6 |-> 0] ]

(* Auction Clearing Price at zero, then each field in turn at the values it is checked at *)
CheckedAuctionClearingPrice ==
    { ZeroAuctionClearingPrice }
        \cup { [ZeroAuctionClearingPrice EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionClearingPrice EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionClearingPrice EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroAuctionClearingPrice EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroAuctionClearingPrice EXCEPT !.imbalanceQty = one] : one \in Sample(8) }
        \cup { [ZeroAuctionClearingPrice EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroAuctionClearingPrice EXCEPT !.potentialSecurityTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroAuctionClearingPrice EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Cross Request: 40 bytes                                                 *)
(***************************************************************************)

CrossRequest ==
    [ securityId       : Sample(8),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      side             : Sample(1),
      crossRequestType : Sample(1),
      inputSource      : Sample(1),
      pad5             : Sample(5),
      transactTime     : Sample(8) ]

EncodeCrossRequest(message) ==
    message.securityId
        \o message.lastPx
        \o message.lastQty
        \o message.side
        \o message.crossRequestType
        \o message.inputSource
        \o message.pad5
        \o message.transactTime

DecodeCrossRequest(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET side == ReadBytes(lastQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET crossRequestType == ReadBytes(side.rest, 1) IN IF ~crossRequestType.ok THEN Fail ELSE
    LET inputSource == ReadBytes(crossRequestType.rest, 1) IN IF ~inputSource.ok THEN Fail ELSE
    LET pad5 == ReadBytes(inputSource.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    LET transactTime == ReadBytes(pad5.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ securityId       |-> securityId.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         side             |-> side.value,
         crossRequestType |-> crossRequestType.value,
         inputSource      |-> inputSource.value,
         pad5             |-> pad5.value,
         transactTime     |-> transactTime.value ], transactTime.rest)

ZeroCrossRequest ==
    [ securityId       |-> [i \in 1 .. 8 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      crossRequestType |-> [i \in 1 .. 1 |-> 0],
      inputSource      |-> [i \in 1 .. 1 |-> 0],
      pad5             |-> [i \in 1 .. 5 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0] ]

(* Cross Request at zero, then each field in turn at the values it is checked at *)
CheckedCrossRequest ==
    { ZeroCrossRequest }
        \cup { [ZeroCrossRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequest EXCEPT !.crossRequestType = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequest EXCEPT !.inputSource = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequest EXCEPT !.pad5 = one] : one \in Sample(5) }
        \cup { [ZeroCrossRequest EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Summary: 72 bytes                                             *)
(***************************************************************************)

ExecutionSummary ==
    [ securityId       : Sample(8),
      aggressorTime    : Sample(8),
      requestTime      : Sample(8),
      execId           : Sample(8),
      lastQty          : Sample(8),
      aggressorSide    : Sample(1),
      pad1             : Sample(1),
      tradeCondition   : Sample(2),
      pad4             : Sample(4),
      lastPx           : Sample(8),
      restingHiddenQty : Sample(8),
      restingCxlQty    : Sample(8) ]

EncodeExecutionSummary(message) ==
    message.securityId
        \o message.aggressorTime
        \o message.requestTime
        \o message.execId
        \o message.lastQty
        \o message.aggressorSide
        \o message.pad1
        \o message.tradeCondition
        \o message.pad4
        \o message.lastPx
        \o message.restingHiddenQty
        \o message.restingCxlQty

DecodeExecutionSummary(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET aggressorTime == ReadBytes(securityId.rest, 8) IN IF ~aggressorTime.ok THEN Fail ELSE
    LET requestTime == ReadBytes(aggressorTime.rest, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET execId == ReadBytes(requestTime.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(execId.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(lastQty.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET pad1 == ReadBytes(aggressorSide.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(pad1.rest, 2) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET pad4 == ReadBytes(tradeCondition.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET lastPx == ReadBytes(pad4.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET restingHiddenQty == ReadBytes(lastPx.rest, 8) IN IF ~restingHiddenQty.ok THEN Fail ELSE
    LET restingCxlQty == ReadBytes(restingHiddenQty.rest, 8) IN IF ~restingCxlQty.ok THEN Fail ELSE
    Ok([ securityId       |-> securityId.value,
         aggressorTime    |-> aggressorTime.value,
         requestTime      |-> requestTime.value,
         execId           |-> execId.value,
         lastQty          |-> lastQty.value,
         aggressorSide    |-> aggressorSide.value,
         pad1             |-> pad1.value,
         tradeCondition   |-> tradeCondition.value,
         pad4             |-> pad4.value,
         lastPx           |-> lastPx.value,
         restingHiddenQty |-> restingHiddenQty.value,
         restingCxlQty    |-> restingCxlQty.value ], restingCxlQty.rest)

ZeroExecutionSummary ==
    [ securityId       |-> [i \in 1 .. 8 |-> 0],
      aggressorTime    |-> [i \in 1 .. 8 |-> 0],
      requestTime      |-> [i \in 1 .. 8 |-> 0],
      execId           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      aggressorSide    |-> [i \in 1 .. 1 |-> 0],
      pad1             |-> [i \in 1 .. 1 |-> 0],
      tradeCondition   |-> [i \in 1 .. 2 |-> 0],
      pad4             |-> [i \in 1 .. 4 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      restingHiddenQty |-> [i \in 1 .. 8 |-> 0],
      restingCxlQty    |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Summary at zero, then each field in turn at the values it is checked at *)
CheckedExecutionSummary ==
    { ZeroExecutionSummary }
        \cup { [ZeroExecutionSummary EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary EXCEPT !.aggressorTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionSummary EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionSummary EXCEPT !.tradeCondition = one] : one \in Sample(2) }
        \cup { [ZeroExecutionSummary EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummary EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary EXCEPT !.restingHiddenQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary EXCEPT !.restingCxlQty = one] : one \in Sample(8) }

(***************************************************************************)
(* Full Order Execution: 48 bytes                                          *)
(***************************************************************************)

FullOrderExecution ==
    [ side                      : Sample(1),
      ordType                   : Sample(1),
      algorithmicTradeIndicator : Sample(1),
      pad1                      : Sample(1),
      trdMatchId                : Sample(4),
      price                     : Sample(8),
      trdRegTsTimePriority      : Sample(8),
      securityId                : Sample(8),
      lastQty                   : Sample(8),
      lastPx                    : Sample(8) ]

EncodeFullOrderExecution(message) ==
    message.side
        \o message.ordType
        \o message.algorithmicTradeIndicator
        \o message.pad1
        \o message.trdMatchId
        \o message.price
        \o message.trdRegTsTimePriority
        \o message.securityId
        \o message.lastQty
        \o message.lastPx

DecodeFullOrderExecution(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(ordType.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET pad1 == ReadBytes(algorithmicTradeIndicator.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(pad1.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET price == ReadBytes(trdMatchId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(price.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET securityId == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(securityId.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    Ok([ side                      |-> side.value,
         ordType                   |-> ordType.value,
         algorithmicTradeIndicator |-> algorithmicTradeIndicator.value,
         pad1                      |-> pad1.value,
         trdMatchId                |-> trdMatchId.value,
         price                     |-> price.value,
         trdRegTsTimePriority      |-> trdRegTsTimePriority.value,
         securityId                |-> securityId.value,
         lastQty                   |-> lastQty.value,
         lastPx                    |-> lastPx.value ], lastPx.rest)

ZeroFullOrderExecution ==
    [ side                      |-> [i \in 1 .. 1 |-> 0],
      ordType                   |-> [i \in 1 .. 1 |-> 0],
      algorithmicTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      pad1                      |-> [i \in 1 .. 1 |-> 0],
      trdMatchId                |-> [i \in 1 .. 4 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority      |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      lastQty                   |-> [i \in 1 .. 8 |-> 0],
      lastPx                    |-> [i \in 1 .. 8 |-> 0] ]

(* Full Order Execution at zero, then each field in turn at the values it is checked at *)
CheckedFullOrderExecution ==
    { ZeroFullOrderExecution }
        \cup { [ZeroFullOrderExecution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFullOrderExecution EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroFullOrderExecution EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFullOrderExecution EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroFullOrderExecution EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFullOrderExecution EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroFullOrderExecution EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroFullOrderExecution EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroFullOrderExecution EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroFullOrderExecution EXCEPT !.lastPx = one] : one \in Sample(8) }

(***************************************************************************)
(* Heartbeat: 8 bytes                                                      *)
(***************************************************************************)

Heartbeat ==
    [ lastMsgSeqNumProcessed : Sample(4),
      pad4                   : Sample(4) ]

EncodeHeartbeat(message) ==
    message.lastMsgSeqNumProcessed
        \o message.pad4

DecodeHeartbeat(bytes) ==
    LET lastMsgSeqNumProcessed == ReadBytes(bytes, 4) IN IF ~lastMsgSeqNumProcessed.ok THEN Fail ELSE
    LET pad4 == ReadBytes(lastMsgSeqNumProcessed.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ lastMsgSeqNumProcessed |-> lastMsgSeqNumProcessed.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroHeartbeat ==
    [ lastMsgSeqNumProcessed |-> [i \in 1 .. 4 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeat ==
    { ZeroHeartbeat }
        \cup { [ZeroHeartbeat EXCEPT !.lastMsgSeqNumProcessed = one] : one \in Sample(4) }
        \cup { [ZeroHeartbeat EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument State Change: 40 bytes                                       *)
(***************************************************************************)

InstrumentStateChange ==
    [ securityId            : Sample(8),
      securityStatus        : Sample(1),
      securityTradingStatus : Sample(1),
      marketCondition       : Sample(1),
      fastMarketIndicator   : Sample(1),
      securityTradingEvent  : Sample(1),
      soldOutIndicator      : Sample(1),
      pad2                  : Sample(2),
      highPx                : Sample(8),
      lowPx                 : Sample(8),
      transactTime          : Sample(8) ]

EncodeInstrumentStateChange(message) ==
    message.securityId
        \o message.securityStatus
        \o message.securityTradingStatus
        \o message.marketCondition
        \o message.fastMarketIndicator
        \o message.securityTradingEvent
        \o message.soldOutIndicator
        \o message.pad2
        \o message.highPx
        \o message.lowPx
        \o message.transactTime

DecodeInstrumentStateChange(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(securityId.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityStatus.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(securityTradingStatus.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(marketCondition.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    LET securityTradingEvent == ReadBytes(fastMarketIndicator.rest, 1) IN IF ~securityTradingEvent.ok THEN Fail ELSE
    LET soldOutIndicator == ReadBytes(securityTradingEvent.rest, 1) IN IF ~soldOutIndicator.ok THEN Fail ELSE
    LET pad2 == ReadBytes(soldOutIndicator.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET highPx == ReadBytes(pad2.rest, 8) IN IF ~highPx.ok THEN Fail ELSE
    LET lowPx == ReadBytes(highPx.rest, 8) IN IF ~lowPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(lowPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         securityStatus        |-> securityStatus.value,
         securityTradingStatus |-> securityTradingStatus.value,
         marketCondition       |-> marketCondition.value,
         fastMarketIndicator   |-> fastMarketIndicator.value,
         securityTradingEvent  |-> securityTradingEvent.value,
         soldOutIndicator      |-> soldOutIndicator.value,
         pad2                  |-> pad2.value,
         highPx                |-> highPx.value,
         lowPx                 |-> lowPx.value,
         transactTime          |-> transactTime.value ], transactTime.rest)

ZeroInstrumentStateChange ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      securityStatus        |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketCondition       |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator   |-> [i \in 1 .. 1 |-> 0],
      securityTradingEvent  |-> [i \in 1 .. 1 |-> 0],
      soldOutIndicator      |-> [i \in 1 .. 1 |-> 0],
      pad2                  |-> [i \in 1 .. 2 |-> 0],
      highPx                |-> [i \in 1 .. 8 |-> 0],
      lowPx                 |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument State Change at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStateChange ==
    { ZeroInstrumentStateChange }
        \cup { [ZeroInstrumentStateChange EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.securityTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.soldOutIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.highPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.lowPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStateChange EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Md Instrument Entry Grp Comp: 24 bytes                                  *)
(***************************************************************************)

MdInstrumentEntryGrpComp ==
    [ mdEntryPx      : Sample(8),
      mdEntrySize    : Sample(8),
      mdEntryType    : Sample(1),
      pad1           : Sample(1),
      tradeCondition : Sample(2),
      pad4           : Sample(4) ]

EncodeMdInstrumentEntryGrpComp(message) ==
    message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdEntryType
        \o message.pad1
        \o message.tradeCondition
        \o message.pad4

DecodeMdInstrumentEntryGrpComp(bytes) ==
    LET mdEntryPx == ReadBytes(bytes, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdEntrySize.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET pad1 == ReadBytes(mdEntryType.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(pad1.rest, 2) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET pad4 == ReadBytes(tradeCondition.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ mdEntryPx      |-> mdEntryPx.value,
         mdEntrySize    |-> mdEntrySize.value,
         mdEntryType    |-> mdEntryType.value,
         pad1           |-> pad1.value,
         tradeCondition |-> tradeCondition.value,
         pad4           |-> pad4.value ], pad4.rest)

ZeroMdInstrumentEntryGrpComp ==
    [ mdEntryPx      |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize    |-> [i \in 1 .. 8 |-> 0],
      mdEntryType    |-> [i \in 1 .. 1 |-> 0],
      pad1           |-> [i \in 1 .. 1 |-> 0],
      tradeCondition |-> [i \in 1 .. 2 |-> 0],
      pad4           |-> [i \in 1 .. 4 |-> 0] ]

(* Md Instrument Entry Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentEntryGrpComp ==
    { ZeroMdInstrumentEntryGrpComp }
        \cup { [ZeroMdInstrumentEntryGrpComp EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentEntryGrpComp EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentEntryGrpComp EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentEntryGrpComp EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentEntryGrpComp EXCEPT !.tradeCondition = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentEntryGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Md Instrument Entry Grp Comp, written one after another *)
RECURSIVE EncodeMdInstrumentEntryGrpCompList(_)
EncodeMdInstrumentEntryGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdInstrumentEntryGrpComp(Head(messages)) \o EncodeMdInstrumentEntryGrpCompList(Tail(messages))

(* As many Md Instrument Entry Grp Comp as the field that counts them says *)
RECURSIVE ReadMdInstrumentEntryGrpCompList(_, _)
ReadMdInstrumentEntryGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdInstrumentEntryGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdInstrumentEntryGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Instrument Entry Grp Comp of each kind, for the lists that carry them *)
OneMdInstrumentEntryGrpComp == { ZeroMdInstrumentEntryGrpComp }

(* The 15 slots a run of Md Instrument Entry Grp Comp is written as, whatever the field beside it says are in use *)
SlotsMdInstrumentEntryGrpComp == { [i \in 1 .. 15 |-> one] : one \in OneMdInstrumentEntryGrpComp }

(***************************************************************************)
(* Instrument Summary                                                      *)
(***************************************************************************)

InstrumentSummary ==
    [ securityId               : Sample(8),
      lastUpdateTime           : Sample(8),
      trdRegTsExecutionTime    : Sample(8),
      totNoOrders              : Sample(2),
      securityStatus           : Sample(1),
      securityTradingStatus    : Sample(1),
      marketCondition          : Sample(1),
      fastMarketIndicator      : Sample(1),
      securityTradingEvent     : Sample(1),
      soldOutIndicator         : Sample(1),
      highPx                   : Sample(8),
      lowPx                    : Sample(8),
      productComplex           : Sample(1),
      noMdEntries              : 0 .. 255,
      pad6                     : Sample(6),
      mdInstrumentEntryGrpComp : SlotsMdInstrumentEntryGrpComp ]

EncodeInstrumentSummary(message) ==
    message.securityId
        \o message.lastUpdateTime
        \o message.trdRegTsExecutionTime
        \o message.totNoOrders
        \o message.securityStatus
        \o message.securityTradingStatus
        \o message.marketCondition
        \o message.fastMarketIndicator
        \o message.securityTradingEvent
        \o message.soldOutIndicator
        \o message.highPx
        \o message.lowPx
        \o message.productComplex
        \o EncodeUIntBE(message.noMdEntries, 1)
        \o message.pad6
        \o EncodeMdInstrumentEntryGrpCompList(message.mdInstrumentEntryGrpComp)

DecodeInstrumentSummary(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(securityId.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET trdRegTsExecutionTime == ReadBytes(lastUpdateTime.rest, 8) IN IF ~trdRegTsExecutionTime.ok THEN Fail ELSE
    LET totNoOrders == ReadBytes(trdRegTsExecutionTime.rest, 2) IN IF ~totNoOrders.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(totNoOrders.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityStatus.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(securityTradingStatus.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(marketCondition.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    LET securityTradingEvent == ReadBytes(fastMarketIndicator.rest, 1) IN IF ~securityTradingEvent.ok THEN Fail ELSE
    LET soldOutIndicator == ReadBytes(securityTradingEvent.rest, 1) IN IF ~soldOutIndicator.ok THEN Fail ELSE
    LET highPx == ReadBytes(soldOutIndicator.rest, 8) IN IF ~highPx.ok THEN Fail ELSE
    LET lowPx == ReadBytes(highPx.rest, 8) IN IF ~lowPx.ok THEN Fail ELSE
    LET productComplex == ReadBytes(lowPx.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(productComplex.rest, 1) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noMdEntries.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET mdInstrumentEntryGrpComp == ReadMdInstrumentEntryGrpCompList(pad6.rest, 15) IN IF ~mdInstrumentEntryGrpComp.ok THEN Fail ELSE
    Ok([ securityId               |-> securityId.value,
         lastUpdateTime           |-> lastUpdateTime.value,
         trdRegTsExecutionTime    |-> trdRegTsExecutionTime.value,
         totNoOrders              |-> totNoOrders.value,
         securityStatus           |-> securityStatus.value,
         securityTradingStatus    |-> securityTradingStatus.value,
         marketCondition          |-> marketCondition.value,
         fastMarketIndicator      |-> fastMarketIndicator.value,
         securityTradingEvent     |-> securityTradingEvent.value,
         soldOutIndicator         |-> soldOutIndicator.value,
         highPx                   |-> highPx.value,
         lowPx                    |-> lowPx.value,
         productComplex           |-> productComplex.value,
         noMdEntries              |-> noMdEntries.value,
         pad6                     |-> pad6.value,
         mdInstrumentEntryGrpComp |-> mdInstrumentEntryGrpComp.value ], mdInstrumentEntryGrpComp.rest)

ZeroInstrumentSummary ==
    [ securityId               |-> [i \in 1 .. 8 |-> 0],
      lastUpdateTime           |-> [i \in 1 .. 8 |-> 0],
      trdRegTsExecutionTime    |-> [i \in 1 .. 8 |-> 0],
      totNoOrders              |-> [i \in 1 .. 2 |-> 0],
      securityStatus           |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus    |-> [i \in 1 .. 1 |-> 0],
      marketCondition          |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator      |-> [i \in 1 .. 1 |-> 0],
      securityTradingEvent     |-> [i \in 1 .. 1 |-> 0],
      soldOutIndicator         |-> [i \in 1 .. 1 |-> 0],
      highPx                   |-> [i \in 1 .. 8 |-> 0],
      lowPx                    |-> [i \in 1 .. 8 |-> 0],
      productComplex           |-> [i \in 1 .. 1 |-> 0],
      noMdEntries              |-> 0,
      pad6                     |-> [i \in 1 .. 6 |-> 0],
      mdInstrumentEntryGrpComp |-> [i \in 1 .. 15 |-> ZeroMdInstrumentEntryGrpComp] ]

(* Instrument Summary at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentSummary ==
    { ZeroInstrumentSummary }
        \cup { [ZeroInstrumentSummary EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.trdRegTsExecutionTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.totNoOrders = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentSummary EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.securityTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.soldOutIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.highPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.lowPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.noMdEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroInstrumentSummary EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentSummary EXCEPT !.mdInstrumentEntryGrpComp = one] : one \in SlotsMdInstrumentEntryGrpComp }

(***************************************************************************)
(* Sec Mass Stat Grp Comp: 32 bytes                                        *)
(***************************************************************************)

SecMassStatGrpComp ==
    [ securityId            : Sample(8),
      highPx                : Sample(8),
      lowPx                 : Sample(8),
      securityStatus        : Sample(1),
      securityTradingStatus : Sample(1),
      marketCondition       : Sample(1),
      securityTradingEvent  : Sample(1),
      soldOutIndicator      : Sample(1),
      pad3                  : Sample(3) ]

EncodeSecMassStatGrpComp(message) ==
    message.securityId
        \o message.highPx
        \o message.lowPx
        \o message.securityStatus
        \o message.securityTradingStatus
        \o message.marketCondition
        \o message.securityTradingEvent
        \o message.soldOutIndicator
        \o message.pad3

DecodeSecMassStatGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET highPx == ReadBytes(securityId.rest, 8) IN IF ~highPx.ok THEN Fail ELSE
    LET lowPx == ReadBytes(highPx.rest, 8) IN IF ~lowPx.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(lowPx.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityStatus.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(securityTradingStatus.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET securityTradingEvent == ReadBytes(marketCondition.rest, 1) IN IF ~securityTradingEvent.ok THEN Fail ELSE
    LET soldOutIndicator == ReadBytes(securityTradingEvent.rest, 1) IN IF ~soldOutIndicator.ok THEN Fail ELSE
    LET pad3 == ReadBytes(soldOutIndicator.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         highPx                |-> highPx.value,
         lowPx                 |-> lowPx.value,
         securityStatus        |-> securityStatus.value,
         securityTradingStatus |-> securityTradingStatus.value,
         marketCondition       |-> marketCondition.value,
         securityTradingEvent  |-> securityTradingEvent.value,
         soldOutIndicator      |-> soldOutIndicator.value,
         pad3                  |-> pad3.value ], pad3.rest)

ZeroSecMassStatGrpComp ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      highPx                |-> [i \in 1 .. 8 |-> 0],
      lowPx                 |-> [i \in 1 .. 8 |-> 0],
      securityStatus        |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketCondition       |-> [i \in 1 .. 1 |-> 0],
      securityTradingEvent  |-> [i \in 1 .. 1 |-> 0],
      soldOutIndicator      |-> [i \in 1 .. 1 |-> 0],
      pad3                  |-> [i \in 1 .. 3 |-> 0] ]

(* Sec Mass Stat Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSecMassStatGrpComp ==
    { ZeroSecMassStatGrpComp }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.highPx = one] : one \in Sample(8) }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.lowPx = one] : one \in Sample(8) }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.securityTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.soldOutIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecMassStatGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Sec Mass Stat Grp Comp, written one after another *)
RECURSIVE EncodeSecMassStatGrpCompList(_)
EncodeSecMassStatGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecMassStatGrpComp(Head(messages)) \o EncodeSecMassStatGrpCompList(Tail(messages))

(* As many Sec Mass Stat Grp Comp as the field that counts them says *)
RECURSIVE ReadSecMassStatGrpCompList(_, _)
ReadSecMassStatGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecMassStatGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecMassStatGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sec Mass Stat Grp Comp of each kind, for the lists that carry them *)
OneSecMassStatGrpComp == { ZeroSecMassStatGrpComp }

(* The 24 slots a run of Sec Mass Stat Grp Comp is written as, whatever the field beside it says are in use *)
SlotsSecMassStatGrpComp == { [i \in 1 .. 24 |-> one] : one \in OneSecMassStatGrpComp }

(***************************************************************************)
(* Mass Instrument State Change                                            *)
(***************************************************************************)

MassInstrumentStateChange ==
    [ instrumentScopeProductComplex : Sample(1),
      securityMassStatus            : Sample(1),
      securityMassTradingStatus     : Sample(1),
      massMarketCondition           : Sample(1),
      fastMarketIndicator           : Sample(1),
      securityMassTradingEvent      : Sample(1),
      massSoldOutIndicator          : Sample(1),
      pad1                          : Sample(1),
      transactTime                  : Sample(8),
      lastFragment                  : Sample(1),
      noRelatedSym                  : 0 .. 255,
      pad6                          : Sample(6),
      secMassStatGrpComp            : SlotsSecMassStatGrpComp ]

EncodeMassInstrumentStateChange(message) ==
    message.instrumentScopeProductComplex
        \o message.securityMassStatus
        \o message.securityMassTradingStatus
        \o message.massMarketCondition
        \o message.fastMarketIndicator
        \o message.securityMassTradingEvent
        \o message.massSoldOutIndicator
        \o message.pad1
        \o message.transactTime
        \o message.lastFragment
        \o EncodeUIntBE(message.noRelatedSym, 1)
        \o message.pad6
        \o EncodeSecMassStatGrpCompList(message.secMassStatGrpComp)

DecodeMassInstrumentStateChange(bytes) ==
    LET instrumentScopeProductComplex == ReadBytes(bytes, 1) IN IF ~instrumentScopeProductComplex.ok THEN Fail ELSE
    LET securityMassStatus == ReadBytes(instrumentScopeProductComplex.rest, 1) IN IF ~securityMassStatus.ok THEN Fail ELSE
    LET securityMassTradingStatus == ReadBytes(securityMassStatus.rest, 1) IN IF ~securityMassTradingStatus.ok THEN Fail ELSE
    LET massMarketCondition == ReadBytes(securityMassTradingStatus.rest, 1) IN IF ~massMarketCondition.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(massMarketCondition.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    LET securityMassTradingEvent == ReadBytes(fastMarketIndicator.rest, 1) IN IF ~securityMassTradingEvent.ok THEN Fail ELSE
    LET massSoldOutIndicator == ReadBytes(securityMassTradingEvent.rest, 1) IN IF ~massSoldOutIndicator.ok THEN Fail ELSE
    LET pad1 == ReadBytes(massSoldOutIndicator.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET transactTime == ReadBytes(pad1.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(transactTime.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET noRelatedSym == ReadUIntBE(lastFragment.rest, 1) IN IF ~noRelatedSym.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noRelatedSym.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET secMassStatGrpComp == ReadSecMassStatGrpCompList(pad6.rest, 24) IN IF ~secMassStatGrpComp.ok THEN Fail ELSE
    Ok([ instrumentScopeProductComplex |-> instrumentScopeProductComplex.value,
         securityMassStatus            |-> securityMassStatus.value,
         securityMassTradingStatus     |-> securityMassTradingStatus.value,
         massMarketCondition           |-> massMarketCondition.value,
         fastMarketIndicator           |-> fastMarketIndicator.value,
         securityMassTradingEvent      |-> securityMassTradingEvent.value,
         massSoldOutIndicator          |-> massSoldOutIndicator.value,
         pad1                          |-> pad1.value,
         transactTime                  |-> transactTime.value,
         lastFragment                  |-> lastFragment.value,
         noRelatedSym                  |-> noRelatedSym.value,
         pad6                          |-> pad6.value,
         secMassStatGrpComp            |-> secMassStatGrpComp.value ], secMassStatGrpComp.rest)

ZeroMassInstrumentStateChange ==
    [ instrumentScopeProductComplex |-> [i \in 1 .. 1 |-> 0],
      securityMassStatus            |-> [i \in 1 .. 1 |-> 0],
      securityMassTradingStatus     |-> [i \in 1 .. 1 |-> 0],
      massMarketCondition           |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator           |-> [i \in 1 .. 1 |-> 0],
      securityMassTradingEvent      |-> [i \in 1 .. 1 |-> 0],
      massSoldOutIndicator          |-> [i \in 1 .. 1 |-> 0],
      pad1                          |-> [i \in 1 .. 1 |-> 0],
      transactTime                  |-> [i \in 1 .. 8 |-> 0],
      lastFragment                  |-> [i \in 1 .. 1 |-> 0],
      noRelatedSym                  |-> 0,
      pad6                          |-> [i \in 1 .. 6 |-> 0],
      secMassStatGrpComp            |-> [i \in 1 .. 24 |-> ZeroSecMassStatGrpComp] ]

(* Mass Instrument State Change at zero, then each field in turn at the values it is checked at *)
CheckedMassInstrumentStateChange ==
    { ZeroMassInstrumentStateChange }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.instrumentScopeProductComplex = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.securityMassStatus = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.securityMassTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.massMarketCondition = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.securityMassTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.massSoldOutIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.noRelatedSym = one] : one \in {0, 1, 255} }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroMassInstrumentStateChange EXCEPT !.secMassStatGrpComp = one] : one \in SlotsSecMassStatGrpComp }

(***************************************************************************)
(* Order Details Comp: 32 bytes                                            *)
(***************************************************************************)

OrderDetailsComp ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      ordType              : Sample(1),
      pad6                 : Sample(6),
      price                : Sample(8) ]

EncodeOrderDetailsComp(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.ordType
        \o message.pad6
        \o message.price

DecodeOrderDetailsComp(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET pad6 == ReadBytes(ordType.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET price == ReadBytes(pad6.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         ordType              |-> ordType.value,
         pad6                 |-> pad6.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetailsComp ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      pad6                 |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details Comp at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetailsComp ==
    { ZeroOrderDetailsComp }
        \cup { [ZeroOrderDetailsComp EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderDetailsComp EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Add: 48 bytes                                                     *)
(***************************************************************************)

OrderAdd ==
    [ trdRegTsTimeIn   : Sample(8),
      securityId       : Sample(8),
      orderDetailsComp : OrderDetailsComp ]

EncodeOrderAdd(message) ==
    message.trdRegTsTimeIn
        \o message.securityId
        \o EncodeOrderDetailsComp(message.orderDetailsComp)

DecodeOrderAdd(bytes) ==
    LET trdRegTsTimeIn == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET securityId == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderDetailsComp == DecodeOrderDetailsComp(securityId.rest) IN IF ~orderDetailsComp.ok THEN Fail ELSE
    Ok([ trdRegTsTimeIn   |-> trdRegTsTimeIn.value,
         securityId       |-> securityId.value,
         orderDetailsComp |-> orderDetailsComp.value ], orderDetailsComp.rest)

ZeroOrderAdd ==
    [ trdRegTsTimeIn   |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      orderDetailsComp |-> ZeroOrderDetailsComp ]

(* Order Add at zero, then each field in turn at the values it is checked at *)
CheckedOrderAdd ==
    { ZeroOrderAdd }
        \cup { [ZeroOrderAdd EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.orderDetailsComp = one] : one \in CheckedOrderDetailsComp }

(***************************************************************************)
(* Order Details Comp: 32 bytes                                            *)
(***************************************************************************)

OrderDetailsComp2 ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      ordType              : Sample(1),
      pad6                 : Sample(6),
      price                : Sample(8) ]

EncodeOrderDetailsComp2(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.ordType
        \o message.pad6
        \o message.price

DecodeOrderDetailsComp2(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET pad6 == ReadBytes(ordType.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET price == ReadBytes(pad6.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         ordType              |-> ordType.value,
         pad6                 |-> pad6.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetailsComp2 ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      pad6                 |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details Comp at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetailsComp2 ==
    { ZeroOrderDetailsComp2 }
        \cup { [ZeroOrderDetailsComp2 EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp2 EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp2 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp2 EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderDetailsComp2 EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Delete: 56 bytes                                                  *)
(***************************************************************************)

OrderDelete ==
    [ trdRegTsTimeIn   : Sample(8),
      transactTime     : Sample(8),
      securityId       : Sample(8),
      orderDetailsComp : OrderDetailsComp2 ]

EncodeOrderDelete(message) ==
    message.trdRegTsTimeIn
        \o message.transactTime
        \o message.securityId
        \o EncodeOrderDetailsComp2(message.orderDetailsComp)

DecodeOrderDelete(bytes) ==
    LET trdRegTsTimeIn == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET transactTime == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderDetailsComp == DecodeOrderDetailsComp2(securityId.rest) IN IF ~orderDetailsComp.ok THEN Fail ELSE
    Ok([ trdRegTsTimeIn   |-> trdRegTsTimeIn.value,
         transactTime     |-> transactTime.value,
         securityId       |-> securityId.value,
         orderDetailsComp |-> orderDetailsComp.value ], orderDetailsComp.rest)

ZeroOrderDelete ==
    [ trdRegTsTimeIn   |-> [i \in 1 .. 8 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      orderDetailsComp |-> ZeroOrderDetailsComp2 ]

(* Order Delete at zero, then each field in turn at the values it is checked at *)
CheckedOrderDelete ==
    { ZeroOrderDelete }
        \cup { [ZeroOrderDelete EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroOrderDelete EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderDelete EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderDelete EXCEPT !.orderDetailsComp = one] : one \in CheckedOrderDetailsComp2 }

(***************************************************************************)
(* Order Mass Delete: 16 bytes                                             *)
(***************************************************************************)

OrderMassDelete ==
    [ securityId   : Sample(8),
      transactTime : Sample(8) ]

EncodeOrderMassDelete(message) ==
    message.securityId
        \o message.transactTime

DecodeOrderMassDelete(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ securityId   |-> securityId.value,
         transactTime |-> transactTime.value ], transactTime.rest)

ZeroOrderMassDelete ==
    [ securityId   |-> [i \in 1 .. 8 |-> 0],
      transactTime |-> [i \in 1 .. 8 |-> 0] ]

(* Order Mass Delete at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassDelete ==
    { ZeroOrderMassDelete }
        \cup { [ZeroOrderMassDelete EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassDelete EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Details Comp: 32 bytes                                            *)
(***************************************************************************)

OrderDetailsComp3 ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      ordType              : Sample(1),
      pad6                 : Sample(6),
      price                : Sample(8) ]

EncodeOrderDetailsComp3(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.ordType
        \o message.pad6
        \o message.price

DecodeOrderDetailsComp3(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET pad6 == ReadBytes(ordType.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET price == ReadBytes(pad6.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         ordType              |-> ordType.value,
         pad6                 |-> pad6.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetailsComp3 ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      pad6                 |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details Comp at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetailsComp3 ==
    { ZeroOrderDetailsComp3 }
        \cup { [ZeroOrderDetailsComp3 EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp3 EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp3 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp3 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp3 EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderDetailsComp3 EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify: 72 bytes                                                  *)
(***************************************************************************)

OrderModify ==
    [ trdRegTsTimeIn           : Sample(8),
      trdRegTsPrevTimePriority : Sample(8),
      prevPrice                : Sample(8),
      prevDisplayQty           : Sample(8),
      securityId               : Sample(8),
      orderDetailsComp         : OrderDetailsComp3 ]

EncodeOrderModify(message) ==
    message.trdRegTsTimeIn
        \o message.trdRegTsPrevTimePriority
        \o message.prevPrice
        \o message.prevDisplayQty
        \o message.securityId
        \o EncodeOrderDetailsComp3(message.orderDetailsComp)

DecodeOrderModify(bytes) ==
    LET trdRegTsTimeIn == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsPrevTimePriority == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsPrevTimePriority.ok THEN Fail ELSE
    LET prevPrice == ReadBytes(trdRegTsPrevTimePriority.rest, 8) IN IF ~prevPrice.ok THEN Fail ELSE
    LET prevDisplayQty == ReadBytes(prevPrice.rest, 8) IN IF ~prevDisplayQty.ok THEN Fail ELSE
    LET securityId == ReadBytes(prevDisplayQty.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderDetailsComp == DecodeOrderDetailsComp3(securityId.rest) IN IF ~orderDetailsComp.ok THEN Fail ELSE
    Ok([ trdRegTsTimeIn           |-> trdRegTsTimeIn.value,
         trdRegTsPrevTimePriority |-> trdRegTsPrevTimePriority.value,
         prevPrice                |-> prevPrice.value,
         prevDisplayQty           |-> prevDisplayQty.value,
         securityId               |-> securityId.value,
         orderDetailsComp         |-> orderDetailsComp.value ], orderDetailsComp.rest)

ZeroOrderModify ==
    [ trdRegTsTimeIn           |-> [i \in 1 .. 8 |-> 0],
      trdRegTsPrevTimePriority |-> [i \in 1 .. 8 |-> 0],
      prevPrice                |-> [i \in 1 .. 8 |-> 0],
      prevDisplayQty           |-> [i \in 1 .. 8 |-> 0],
      securityId               |-> [i \in 1 .. 8 |-> 0],
      orderDetailsComp         |-> ZeroOrderDetailsComp3 ]

(* Order Modify at zero, then each field in turn at the values it is checked at *)
CheckedOrderModify ==
    { ZeroOrderModify }
        \cup { [ZeroOrderModify EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.trdRegTsPrevTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.prevPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.prevDisplayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.orderDetailsComp = one] : one \in CheckedOrderDetailsComp3 }

(***************************************************************************)
(* Order Details Comp: 32 bytes                                            *)
(***************************************************************************)

OrderDetailsComp4 ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      ordType              : Sample(1),
      pad6                 : Sample(6),
      price                : Sample(8) ]

EncodeOrderDetailsComp4(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.ordType
        \o message.pad6
        \o message.price

DecodeOrderDetailsComp4(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET pad6 == ReadBytes(ordType.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET price == ReadBytes(pad6.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         ordType              |-> ordType.value,
         pad6                 |-> pad6.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetailsComp4 ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      pad6                 |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details Comp at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetailsComp4 ==
    { ZeroOrderDetailsComp4 }
        \cup { [ZeroOrderDetailsComp4 EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp4 EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp4 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp4 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp4 EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderDetailsComp4 EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify Same Prio: 64 bytes                                        *)
(***************************************************************************)

OrderModifySamePrio ==
    [ trdRegTsTimeIn   : Sample(8),
      transactTime     : Sample(8),
      prevDisplayQty   : Sample(8),
      securityId       : Sample(8),
      orderDetailsComp : OrderDetailsComp4 ]

EncodeOrderModifySamePrio(message) ==
    message.trdRegTsTimeIn
        \o message.transactTime
        \o message.prevDisplayQty
        \o message.securityId
        \o EncodeOrderDetailsComp4(message.orderDetailsComp)

DecodeOrderModifySamePrio(bytes) ==
    LET trdRegTsTimeIn == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET transactTime == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET prevDisplayQty == ReadBytes(transactTime.rest, 8) IN IF ~prevDisplayQty.ok THEN Fail ELSE
    LET securityId == ReadBytes(prevDisplayQty.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderDetailsComp == DecodeOrderDetailsComp4(securityId.rest) IN IF ~orderDetailsComp.ok THEN Fail ELSE
    Ok([ trdRegTsTimeIn   |-> trdRegTsTimeIn.value,
         transactTime     |-> transactTime.value,
         prevDisplayQty   |-> prevDisplayQty.value,
         securityId       |-> securityId.value,
         orderDetailsComp |-> orderDetailsComp.value ], orderDetailsComp.rest)

ZeroOrderModifySamePrio ==
    [ trdRegTsTimeIn   |-> [i \in 1 .. 8 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      prevDisplayQty   |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      orderDetailsComp |-> ZeroOrderDetailsComp4 ]

(* Order Modify Same Prio at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifySamePrio ==
    { ZeroOrderModifySamePrio }
        \cup { [ZeroOrderModifySamePrio EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifySamePrio EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifySamePrio EXCEPT !.prevDisplayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifySamePrio EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifySamePrio EXCEPT !.orderDetailsComp = one] : one \in CheckedOrderDetailsComp4 }

(***************************************************************************)
(* Partial Order Execution: 48 bytes                                       *)
(***************************************************************************)

PartialOrderExecution ==
    [ side                      : Sample(1),
      ordType                   : Sample(1),
      algorithmicTradeIndicator : Sample(1),
      pad1                      : Sample(1),
      trdMatchId                : Sample(4),
      price                     : Sample(8),
      trdRegTsTimePriority      : Sample(8),
      securityId                : Sample(8),
      lastQty                   : Sample(8),
      lastPx                    : Sample(8) ]

EncodePartialOrderExecution(message) ==
    message.side
        \o message.ordType
        \o message.algorithmicTradeIndicator
        \o message.pad1
        \o message.trdMatchId
        \o message.price
        \o message.trdRegTsTimePriority
        \o message.securityId
        \o message.lastQty
        \o message.lastPx

DecodePartialOrderExecution(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(ordType.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET pad1 == ReadBytes(algorithmicTradeIndicator.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(pad1.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET price == ReadBytes(trdMatchId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(price.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET securityId == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(securityId.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    Ok([ side                      |-> side.value,
         ordType                   |-> ordType.value,
         algorithmicTradeIndicator |-> algorithmicTradeIndicator.value,
         pad1                      |-> pad1.value,
         trdMatchId                |-> trdMatchId.value,
         price                     |-> price.value,
         trdRegTsTimePriority      |-> trdRegTsTimePriority.value,
         securityId                |-> securityId.value,
         lastQty                   |-> lastQty.value,
         lastPx                    |-> lastPx.value ], lastPx.rest)

ZeroPartialOrderExecution ==
    [ side                      |-> [i \in 1 .. 1 |-> 0],
      ordType                   |-> [i \in 1 .. 1 |-> 0],
      algorithmicTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      pad1                      |-> [i \in 1 .. 1 |-> 0],
      trdMatchId                |-> [i \in 1 .. 4 |-> 0],
      price                     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority      |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      lastQty                   |-> [i \in 1 .. 8 |-> 0],
      lastPx                    |-> [i \in 1 .. 8 |-> 0] ]

(* Partial Order Execution at zero, then each field in turn at the values it is checked at *)
CheckedPartialOrderExecution ==
    { ZeroPartialOrderExecution }
        \cup { [ZeroPartialOrderExecution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroPartialOrderExecution EXCEPT !.lastPx = one] : one \in Sample(8) }

(***************************************************************************)
(* Product State Change: 16 bytes                                          *)
(***************************************************************************)

ProductStateChange ==
    [ tradingSessionId    : Sample(1),
      tradingSessionSubId : Sample(1),
      tradSesStatus       : Sample(1),
      marketCondition     : Sample(1),
      fastMarketIndicator : Sample(1),
      pad3                : Sample(3),
      transactTime        : Sample(8) ]

EncodeProductStateChange(message) ==
    message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.tradSesStatus
        \o message.marketCondition
        \o message.fastMarketIndicator
        \o message.pad3
        \o message.transactTime

DecodeProductStateChange(bytes) ==
    LET tradingSessionId == ReadBytes(bytes, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(tradSesStatus.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(marketCondition.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    LET pad3 == ReadBytes(fastMarketIndicator.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET transactTime == ReadBytes(pad3.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ tradingSessionId    |-> tradingSessionId.value,
         tradingSessionSubId |-> tradingSessionSubId.value,
         tradSesStatus       |-> tradSesStatus.value,
         marketCondition     |-> marketCondition.value,
         fastMarketIndicator |-> fastMarketIndicator.value,
         pad3                |-> pad3.value,
         transactTime        |-> transactTime.value ], transactTime.rest)

ZeroProductStateChange ==
    [ tradingSessionId    |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId |-> [i \in 1 .. 1 |-> 0],
      tradSesStatus       |-> [i \in 1 .. 1 |-> 0],
      marketCondition     |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator |-> [i \in 1 .. 1 |-> 0],
      pad3                |-> [i \in 1 .. 3 |-> 0],
      transactTime        |-> [i \in 1 .. 8 |-> 0] ]

(* Product State Change at zero, then each field in turn at the values it is checked at *)
CheckedProductStateChange ==
    { ZeroProductStateChange }
        \cup { [ZeroProductStateChange EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChange EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChange EXCEPT !.tradSesStatus = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChange EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChange EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroProductStateChange EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroProductStateChange EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Product Summary: 16 bytes                                               *)
(***************************************************************************)

ProductSummary ==
    [ lastMsgSeqNumProcessed : Sample(4),
      tradingSessionId       : Sample(1),
      tradingSessionSubId    : Sample(1),
      tradSesStatus          : Sample(1),
      marketCondition        : Sample(1),
      fastMarketIndicator    : Sample(1),
      pad7                   : Sample(7) ]

EncodeProductSummary(message) ==
    message.lastMsgSeqNumProcessed
        \o message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.tradSesStatus
        \o message.marketCondition
        \o message.fastMarketIndicator
        \o message.pad7

DecodeProductSummary(bytes) ==
    LET lastMsgSeqNumProcessed == ReadBytes(bytes, 4) IN IF ~lastMsgSeqNumProcessed.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(lastMsgSeqNumProcessed.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(tradSesStatus.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET fastMarketIndicator == ReadBytes(marketCondition.rest, 1) IN IF ~fastMarketIndicator.ok THEN Fail ELSE
    LET pad7 == ReadBytes(fastMarketIndicator.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ lastMsgSeqNumProcessed |-> lastMsgSeqNumProcessed.value,
         tradingSessionId       |-> tradingSessionId.value,
         tradingSessionSubId    |-> tradingSessionSubId.value,
         tradSesStatus          |-> tradSesStatus.value,
         marketCondition        |-> marketCondition.value,
         fastMarketIndicator    |-> fastMarketIndicator.value,
         pad7                   |-> pad7.value ], pad7.rest)

ZeroProductSummary ==
    [ lastMsgSeqNumProcessed |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId       |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId    |-> [i \in 1 .. 1 |-> 0],
      tradSesStatus          |-> [i \in 1 .. 1 |-> 0],
      marketCondition        |-> [i \in 1 .. 1 |-> 0],
      fastMarketIndicator    |-> [i \in 1 .. 1 |-> 0],
      pad7                   |-> [i \in 1 .. 7 |-> 0] ]

(* Product Summary at zero, then each field in turn at the values it is checked at *)
CheckedProductSummary ==
    { ZeroProductSummary }
        \cup { [ZeroProductSummary EXCEPT !.lastMsgSeqNumProcessed = one] : one \in Sample(4) }
        \cup { [ZeroProductSummary EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.tradSesStatus = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.fastMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Quote Request: 32 bytes                                                 *)
(***************************************************************************)

QuoteRequest ==
    [ securityId   : Sample(8),
      lastQty      : Sample(8),
      side         : Sample(1),
      pad7         : Sample(7),
      transactTime : Sample(8) ]

EncodeQuoteRequest(message) ==
    message.securityId
        \o message.lastQty
        \o message.side
        \o message.pad7
        \o message.transactTime

DecodeQuoteRequest(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(securityId.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET side == ReadBytes(lastQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET transactTime == ReadBytes(pad7.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ securityId   |-> securityId.value,
         lastQty      |-> lastQty.value,
         side         |-> side.value,
         pad7         |-> pad7.value,
         transactTime |-> transactTime.value ], transactTime.rest)

ZeroQuoteRequest ==
    [ securityId   |-> [i \in 1 .. 8 |-> 0],
      lastQty      |-> [i \in 1 .. 8 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      pad7         |-> [i \in 1 .. 7 |-> 0],
      transactTime |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequest ==
    { ZeroQuoteRequest }
        \cup { [ZeroQuoteRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequest EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequest EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroQuoteRequest EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Details Comp: 32 bytes                                            *)
(***************************************************************************)

OrderDetailsComp5 ==
    [ trdRegTsTimePriority : Sample(8),
      displayQty           : Sample(8),
      side                 : Sample(1),
      ordType              : Sample(1),
      pad6                 : Sample(6),
      price                : Sample(8) ]

EncodeOrderDetailsComp5(message) ==
    message.trdRegTsTimePriority
        \o message.displayQty
        \o message.side
        \o message.ordType
        \o message.pad6
        \o message.price

DecodeOrderDetailsComp5(bytes) ==
    LET trdRegTsTimePriority == ReadBytes(bytes, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET displayQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET side == ReadBytes(displayQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET pad6 == ReadBytes(ordType.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET price == ReadBytes(pad6.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ trdRegTsTimePriority |-> trdRegTsTimePriority.value,
         displayQty           |-> displayQty.value,
         side                 |-> side.value,
         ordType              |-> ordType.value,
         pad6                 |-> pad6.value,
         price                |-> price.value ], price.rest)

ZeroOrderDetailsComp5 ==
    [ trdRegTsTimePriority |-> [i \in 1 .. 8 |-> 0],
      displayQty           |-> [i \in 1 .. 8 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      pad6                 |-> [i \in 1 .. 6 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Order Details Comp at zero, then each field in turn at the values it is checked at *)
CheckedOrderDetailsComp5 ==
    { ZeroOrderDetailsComp5 }
        \cup { [ZeroOrderDetailsComp5 EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp5 EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderDetailsComp5 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp5 EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderDetailsComp5 EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderDetailsComp5 EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Snapshot Order: 32 bytes                                                *)
(***************************************************************************)

SnapshotOrder ==
    [ orderDetailsComp : OrderDetailsComp5 ]

EncodeSnapshotOrder(message) ==
    EncodeOrderDetailsComp5(message.orderDetailsComp)

DecodeSnapshotOrder(bytes) ==
    LET orderDetailsComp == DecodeOrderDetailsComp5(bytes) IN IF ~orderDetailsComp.ok THEN Fail ELSE
    Ok([ orderDetailsComp |-> orderDetailsComp.value ], orderDetailsComp.rest)

ZeroSnapshotOrder ==
    [ orderDetailsComp |-> ZeroOrderDetailsComp5 ]

(* Snapshot Order at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotOrder ==
    { ZeroSnapshotOrder }
        \cup { [ZeroSnapshotOrder EXCEPT !.orderDetailsComp = one] : one \in CheckedOrderDetailsComp5 }

(***************************************************************************)
(* Top Of Book: 56 bytes                                                   *)
(***************************************************************************)

TopOfBook ==
    [ transactTime       : Sample(8),
      securityId         : Sample(8),
      bidPx              : Sample(8),
      offerPx            : Sample(8),
      bidSize            : Sample(8),
      offerSize          : Sample(8),
      numberOfBuyOrders  : Sample(2),
      numberOfSellOrders : Sample(2),
      pad4               : Sample(4) ]

EncodeTopOfBook(message) ==
    message.transactTime
        \o message.securityId
        \o message.bidPx
        \o message.offerPx
        \o message.bidSize
        \o message.offerSize
        \o message.numberOfBuyOrders
        \o message.numberOfSellOrders
        \o message.pad4

DecodeTopOfBook(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(offerPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET numberOfBuyOrders == ReadBytes(offerSize.rest, 2) IN IF ~numberOfBuyOrders.ok THEN Fail ELSE
    LET numberOfSellOrders == ReadBytes(numberOfBuyOrders.rest, 2) IN IF ~numberOfSellOrders.ok THEN Fail ELSE
    LET pad4 == ReadBytes(numberOfSellOrders.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ transactTime       |-> transactTime.value,
         securityId         |-> securityId.value,
         bidPx              |-> bidPx.value,
         offerPx            |-> offerPx.value,
         bidSize            |-> bidSize.value,
         offerSize          |-> offerSize.value,
         numberOfBuyOrders  |-> numberOfBuyOrders.value,
         numberOfSellOrders |-> numberOfSellOrders.value,
         pad4               |-> pad4.value ], pad4.rest)

ZeroTopOfBook ==
    [ transactTime       |-> [i \in 1 .. 8 |-> 0],
      securityId         |-> [i \in 1 .. 8 |-> 0],
      bidPx              |-> [i \in 1 .. 8 |-> 0],
      offerPx            |-> [i \in 1 .. 8 |-> 0],
      bidSize            |-> [i \in 1 .. 8 |-> 0],
      offerSize          |-> [i \in 1 .. 8 |-> 0],
      numberOfBuyOrders  |-> [i \in 1 .. 2 |-> 0],
      numberOfSellOrders |-> [i \in 1 .. 2 |-> 0],
      pad4               |-> [i \in 1 .. 4 |-> 0] ]

(* Top Of Book at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBook ==
    { ZeroTopOfBook }
        \cup { [ZeroTopOfBook EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBook EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBook EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBook EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBook EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBook EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBook EXCEPT !.numberOfBuyOrders = one] : one \in Sample(2) }
        \cup { [ZeroTopOfBook EXCEPT !.numberOfSellOrders = one] : one \in Sample(2) }
        \cup { [ZeroTopOfBook EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Report: 48 bytes                                                  *)
(***************************************************************************)

TradeReport ==
    [ securityId                : Sample(8),
      transactTime              : Sample(8),
      lastQty                   : Sample(8),
      lastPx                    : Sample(8),
      trdMatchId                : Sample(4),
      matchType                 : Sample(1),
      matchSubType              : Sample(1),
      algorithmicTradeIndicator : Sample(1),
      pad1                      : Sample(1),
      tradeCondition            : Sample(2),
      pad6                      : Sample(6) ]

EncodeTradeReport(message) ==
    message.securityId
        \o message.transactTime
        \o message.lastQty
        \o message.lastPx
        \o message.trdMatchId
        \o message.matchType
        \o message.matchSubType
        \o message.algorithmicTradeIndicator
        \o message.pad1
        \o message.tradeCondition
        \o message.pad6

DecodeTradeReport(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastQty == ReadBytes(transactTime.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(lastPx.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET matchType == ReadBytes(trdMatchId.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET matchSubType == ReadBytes(matchType.rest, 1) IN IF ~matchSubType.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(matchSubType.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET pad1 == ReadBytes(algorithmicTradeIndicator.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(pad1.rest, 2) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET pad6 == ReadBytes(tradeCondition.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ securityId                |-> securityId.value,
         transactTime              |-> transactTime.value,
         lastQty                   |-> lastQty.value,
         lastPx                    |-> lastPx.value,
         trdMatchId                |-> trdMatchId.value,
         matchType                 |-> matchType.value,
         matchSubType              |-> matchSubType.value,
         algorithmicTradeIndicator |-> algorithmicTradeIndicator.value,
         pad1                      |-> pad1.value,
         tradeCondition            |-> tradeCondition.value,
         pad6                      |-> pad6.value ], pad6.rest)

ZeroTradeReport ==
    [ securityId                |-> [i \in 1 .. 8 |-> 0],
      transactTime              |-> [i \in 1 .. 8 |-> 0],
      lastQty                   |-> [i \in 1 .. 8 |-> 0],
      lastPx                    |-> [i \in 1 .. 8 |-> 0],
      trdMatchId                |-> [i \in 1 .. 4 |-> 0],
      matchType                 |-> [i \in 1 .. 1 |-> 0],
      matchSubType              |-> [i \in 1 .. 1 |-> 0],
      algorithmicTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      pad1                      |-> [i \in 1 .. 1 |-> 0],
      tradeCondition            |-> [i \in 1 .. 2 |-> 0],
      pad6                      |-> [i \in 1 .. 6 |-> 0] ]

(* Trade Report at zero, then each field in turn at the values it is checked at *)
CheckedTradeReport ==
    { ZeroTradeReport }
        \cup { [ZeroTradeReport EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReport EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeReport EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTradeReport EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeReport EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeReport EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroTradeReport EXCEPT !.matchSubType = one] : one \in Sample(1) }
        \cup { [ZeroTradeReport EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeReport EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeReport EXCEPT !.tradeCondition = one] : one \in Sample(2) }
        \cup { [ZeroTradeReport EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Md Trade Entry Grp Comp: 24 bytes                                       *)
(***************************************************************************)

MdTradeEntryGrpComp ==
    [ mdEntryPx   : Sample(8),
      mdEntrySize : Sample(8),
      mdEntryType : Sample(1),
      pad7        : Sample(7) ]

EncodeMdTradeEntryGrpComp(message) ==
    message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdEntryType
        \o message.pad7

DecodeMdTradeEntryGrpComp(bytes) ==
    LET mdEntryPx == ReadBytes(bytes, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdEntrySize.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET pad7 == ReadBytes(mdEntryType.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ mdEntryPx   |-> mdEntryPx.value,
         mdEntrySize |-> mdEntrySize.value,
         mdEntryType |-> mdEntryType.value,
         pad7        |-> pad7.value ], pad7.rest)

ZeroMdTradeEntryGrpComp ==
    [ mdEntryPx   |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize |-> [i \in 1 .. 8 |-> 0],
      mdEntryType |-> [i \in 1 .. 1 |-> 0],
      pad7        |-> [i \in 1 .. 7 |-> 0] ]

(* Md Trade Entry Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedMdTradeEntryGrpComp ==
    { ZeroMdTradeEntryGrpComp }
        \cup { [ZeroMdTradeEntryGrpComp EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroMdTradeEntryGrpComp EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroMdTradeEntryGrpComp EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdTradeEntryGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Md Trade Entry Grp Comp, written one after another *)
RECURSIVE EncodeMdTradeEntryGrpCompList(_)
EncodeMdTradeEntryGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdTradeEntryGrpComp(Head(messages)) \o EncodeMdTradeEntryGrpCompList(Tail(messages))

(* As many Md Trade Entry Grp Comp as the field that counts them says *)
RECURSIVE ReadMdTradeEntryGrpCompList(_, _)
ReadMdTradeEntryGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdTradeEntryGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdTradeEntryGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Trade Entry Grp Comp of each kind, for the lists that carry them *)
OneMdTradeEntryGrpComp == { ZeroMdTradeEntryGrpComp }

(* The 15 slots a run of Md Trade Entry Grp Comp is written as, whatever the field beside it says are in use *)
SlotsMdTradeEntryGrpComp == { [i \in 1 .. 15 |-> one] : one \in OneMdTradeEntryGrpComp }

(***************************************************************************)
(* Trade Reversal                                                          *)
(***************************************************************************)

TradeReversal ==
    [ securityId            : Sample(8),
      transactTime          : Sample(8),
      lastQty               : Sample(8),
      lastPx                : Sample(8),
      trdRegTsExecutionTime : Sample(8),
      trdMatchId            : Sample(4),
      tradeCondition        : Sample(2),
      pad2                  : Sample(2),
      noMdEntries           : 0 .. 255,
      pad7                  : Sample(7),
      mdTradeEntryGrpComp   : SlotsMdTradeEntryGrpComp ]

EncodeTradeReversal(message) ==
    message.securityId
        \o message.transactTime
        \o message.lastQty
        \o message.lastPx
        \o message.trdRegTsExecutionTime
        \o message.trdMatchId
        \o message.tradeCondition
        \o message.pad2
        \o EncodeUIntBE(message.noMdEntries, 1)
        \o message.pad7
        \o EncodeMdTradeEntryGrpCompList(message.mdTradeEntryGrpComp)

DecodeTradeReversal(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastQty == ReadBytes(transactTime.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(lastQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET trdRegTsExecutionTime == ReadBytes(lastPx.rest, 8) IN IF ~trdRegTsExecutionTime.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(trdRegTsExecutionTime.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(trdMatchId.rest, 2) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET pad2 == ReadBytes(tradeCondition.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(pad2.rest, 1) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET pad7 == ReadBytes(noMdEntries.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET mdTradeEntryGrpComp == ReadMdTradeEntryGrpCompList(pad7.rest, 15) IN IF ~mdTradeEntryGrpComp.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         transactTime          |-> transactTime.value,
         lastQty               |-> lastQty.value,
         lastPx                |-> lastPx.value,
         trdRegTsExecutionTime |-> trdRegTsExecutionTime.value,
         trdMatchId            |-> trdMatchId.value,
         tradeCondition        |-> tradeCondition.value,
         pad2                  |-> pad2.value,
         noMdEntries           |-> noMdEntries.value,
         pad7                  |-> pad7.value,
         mdTradeEntryGrpComp   |-> mdTradeEntryGrpComp.value ], mdTradeEntryGrpComp.rest)

ZeroTradeReversal ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsExecutionTime |-> [i \in 1 .. 8 |-> 0],
      trdMatchId            |-> [i \in 1 .. 4 |-> 0],
      tradeCondition        |-> [i \in 1 .. 2 |-> 0],
      pad2                  |-> [i \in 1 .. 2 |-> 0],
      noMdEntries           |-> 0,
      pad7                  |-> [i \in 1 .. 7 |-> 0],
      mdTradeEntryGrpComp   |-> [i \in 1 .. 15 |-> ZeroMdTradeEntryGrpComp] ]

(* Trade Reversal at zero, then each field in turn at the values it is checked at *)
CheckedTradeReversal ==
    { ZeroTradeReversal }
        \cup { [ZeroTradeReversal EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversal EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversal EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversal EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversal EXCEPT !.trdRegTsExecutionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeReversal EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeReversal EXCEPT !.tradeCondition = one] : one \in Sample(2) }
        \cup { [ZeroTradeReversal EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeReversal EXCEPT !.noMdEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroTradeReversal EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroTradeReversal EXCEPT !.mdTradeEntryGrpComp = one] : one \in SlotsMdTradeEntryGrpComp }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

AddComplexInstrumentCode == 13400  \* 0x3458
AuctionBboCode == 13500  \* 0x34bc
AuctionClearingPriceCode == 13501  \* 0x34bd
CrossRequestCode == 13502  \* 0x34be
ExecutionSummaryCode == 13202  \* 0x3392
FullOrderExecutionCode == 13104  \* 0x3330
HeartbeatCode == 13001  \* 0x32c9
InstrumentStateChangeCode == 13301  \* 0x33f5
InstrumentSummaryCode == 13601  \* 0x3521
MassInstrumentStateChangeCode == 13302  \* 0x33f6
OrderAddCode == 13100  \* 0x332c
OrderDeleteCode == 13102  \* 0x332e
OrderMassDeleteCode == 13103  \* 0x332f
OrderModifyCode == 13101  \* 0x332d
OrderModifySamePrioCode == 13106  \* 0x3332
PartialOrderExecutionCode == 13105  \* 0x3331
ProductStateChangeCode == 13300  \* 0x33f4
ProductSummaryCode == 13600  \* 0x3520
QuoteRequestCode == 13503  \* 0x34bf
SnapshotOrderCode == 13602  \* 0x3522
TopOfBookCode == 13504  \* 0x34c0
TradeReportCode == 13201  \* 0x3391
TradeReversalCode == 13200  \* 0x3390

Payload ==
    [ tag : {AddComplexInstrumentCode}, body : AddComplexInstrument ]
        \cup [ tag : {AuctionBboCode}, body : AuctionBbo ]
        \cup [ tag : {AuctionClearingPriceCode}, body : AuctionClearingPrice ]
        \cup [ tag : {CrossRequestCode}, body : CrossRequest ]
        \cup [ tag : {ExecutionSummaryCode}, body : ExecutionSummary ]
        \cup [ tag : {FullOrderExecutionCode}, body : FullOrderExecution ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {InstrumentStateChangeCode}, body : InstrumentStateChange ]
        \cup [ tag : {InstrumentSummaryCode}, body : InstrumentSummary ]
        \cup [ tag : {MassInstrumentStateChangeCode}, body : MassInstrumentStateChange ]
        \cup [ tag : {OrderAddCode}, body : OrderAdd ]
        \cup [ tag : {OrderDeleteCode}, body : OrderDelete ]
        \cup [ tag : {OrderMassDeleteCode}, body : OrderMassDelete ]
        \cup [ tag : {OrderModifyCode}, body : OrderModify ]
        \cup [ tag : {OrderModifySamePrioCode}, body : OrderModifySamePrio ]
        \cup [ tag : {PartialOrderExecutionCode}, body : PartialOrderExecution ]
        \cup [ tag : {ProductStateChangeCode}, body : ProductStateChange ]
        \cup [ tag : {ProductSummaryCode}, body : ProductSummary ]
        \cup [ tag : {QuoteRequestCode}, body : QuoteRequest ]
        \cup [ tag : {SnapshotOrderCode}, body : SnapshotOrder ]
        \cup [ tag : {TopOfBookCode}, body : TopOfBook ]
        \cup [ tag : {TradeReportCode}, body : TradeReport ]
        \cup [ tag : {TradeReversalCode}, body : TradeReversal ]

EncodePayload(message) ==
    CASE message.tag = AddComplexInstrumentCode -> EncodeAddComplexInstrument(message.body)
      [] message.tag = AuctionBboCode -> EncodeAuctionBbo(message.body)
      [] message.tag = AuctionClearingPriceCode -> EncodeAuctionClearingPrice(message.body)
      [] message.tag = CrossRequestCode -> EncodeCrossRequest(message.body)
      [] message.tag = ExecutionSummaryCode -> EncodeExecutionSummary(message.body)
      [] message.tag = FullOrderExecutionCode -> EncodeFullOrderExecution(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = InstrumentStateChangeCode -> EncodeInstrumentStateChange(message.body)
      [] message.tag = InstrumentSummaryCode -> EncodeInstrumentSummary(message.body)
      [] message.tag = MassInstrumentStateChangeCode -> EncodeMassInstrumentStateChange(message.body)
      [] message.tag = OrderAddCode -> EncodeOrderAdd(message.body)
      [] message.tag = OrderDeleteCode -> EncodeOrderDelete(message.body)
      [] message.tag = OrderMassDeleteCode -> EncodeOrderMassDelete(message.body)
      [] message.tag = OrderModifyCode -> EncodeOrderModify(message.body)
      [] message.tag = OrderModifySamePrioCode -> EncodeOrderModifySamePrio(message.body)
      [] message.tag = PartialOrderExecutionCode -> EncodePartialOrderExecution(message.body)
      [] message.tag = ProductStateChangeCode -> EncodeProductStateChange(message.body)
      [] message.tag = ProductSummaryCode -> EncodeProductSummary(message.body)
      [] message.tag = QuoteRequestCode -> EncodeQuoteRequest(message.body)
      [] message.tag = SnapshotOrderCode -> EncodeSnapshotOrder(message.body)
      [] message.tag = TopOfBookCode -> EncodeTopOfBook(message.body)
      [] message.tag = TradeReportCode -> EncodeTradeReport(message.body)
      [] message.tag = TradeReversalCode -> EncodeTradeReversal(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AddComplexInstrumentCode -> DecodeAddComplexInstrument(bytes)
              [] tag = AuctionBboCode -> DecodeAuctionBbo(bytes)
              [] tag = AuctionClearingPriceCode -> DecodeAuctionClearingPrice(bytes)
              [] tag = CrossRequestCode -> DecodeCrossRequest(bytes)
              [] tag = ExecutionSummaryCode -> DecodeExecutionSummary(bytes)
              [] tag = FullOrderExecutionCode -> DecodeFullOrderExecution(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = InstrumentStateChangeCode -> DecodeInstrumentStateChange(bytes)
              [] tag = InstrumentSummaryCode -> DecodeInstrumentSummary(bytes)
              [] tag = MassInstrumentStateChangeCode -> DecodeMassInstrumentStateChange(bytes)
              [] tag = OrderAddCode -> DecodeOrderAdd(bytes)
              [] tag = OrderDeleteCode -> DecodeOrderDelete(bytes)
              [] tag = OrderMassDeleteCode -> DecodeOrderMassDelete(bytes)
              [] tag = OrderModifyCode -> DecodeOrderModify(bytes)
              [] tag = OrderModifySamePrioCode -> DecodeOrderModifySamePrio(bytes)
              [] tag = PartialOrderExecutionCode -> DecodePartialOrderExecution(bytes)
              [] tag = ProductStateChangeCode -> DecodeProductStateChange(bytes)
              [] tag = ProductSummaryCode -> DecodeProductSummary(bytes)
              [] tag = QuoteRequestCode -> DecodeQuoteRequest(bytes)
              [] tag = SnapshotOrderCode -> DecodeSnapshotOrder(bytes)
              [] tag = TopOfBookCode -> DecodeTopOfBook(bytes)
              [] tag = TradeReportCode -> DecodeTradeReport(bytes)
              [] tag = TradeReversalCode -> DecodeTradeReversal(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AddComplexInstrumentCode, body |-> ZeroAddComplexInstrument]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AddComplexInstrumentCode, body |-> one] : one \in CheckedAddComplexInstrument }
        \cup { [tag |-> AuctionBboCode, body |-> one] : one \in CheckedAuctionBbo }
        \cup { [tag |-> AuctionClearingPriceCode, body |-> one] : one \in CheckedAuctionClearingPrice }
        \cup { [tag |-> CrossRequestCode, body |-> one] : one \in CheckedCrossRequest }
        \cup { [tag |-> ExecutionSummaryCode, body |-> one] : one \in CheckedExecutionSummary }
        \cup { [tag |-> FullOrderExecutionCode, body |-> one] : one \in CheckedFullOrderExecution }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> InstrumentStateChangeCode, body |-> one] : one \in CheckedInstrumentStateChange }
        \cup { [tag |-> InstrumentSummaryCode, body |-> one] : one \in CheckedInstrumentSummary }
        \cup { [tag |-> MassInstrumentStateChangeCode, body |-> one] : one \in CheckedMassInstrumentStateChange }
        \cup { [tag |-> OrderAddCode, body |-> one] : one \in CheckedOrderAdd }
        \cup { [tag |-> OrderDeleteCode, body |-> one] : one \in CheckedOrderDelete }
        \cup { [tag |-> OrderMassDeleteCode, body |-> one] : one \in CheckedOrderMassDelete }
        \cup { [tag |-> OrderModifyCode, body |-> one] : one \in CheckedOrderModify }
        \cup { [tag |-> OrderModifySamePrioCode, body |-> one] : one \in CheckedOrderModifySamePrio }
        \cup { [tag |-> PartialOrderExecutionCode, body |-> one] : one \in CheckedPartialOrderExecution }
        \cup { [tag |-> ProductStateChangeCode, body |-> one] : one \in CheckedProductStateChange }
        \cup { [tag |-> ProductSummaryCode, body |-> one] : one \in CheckedProductSummary }
        \cup { [tag |-> QuoteRequestCode, body |-> one] : one \in CheckedQuoteRequest }
        \cup { [tag |-> SnapshotOrderCode, body |-> one] : one \in CheckedSnapshotOrder }
        \cup { [tag |-> TopOfBookCode, body |-> one] : one \in CheckedTopOfBook }
        \cup { [tag |-> TradeReportCode, body |-> one] : one \in CheckedTradeReport }
        \cup { [tag |-> TradeReversalCode, body |-> one] : one \in CheckedTradeReversal }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AddComplexInstrumentCode, body |-> ZeroAddComplexInstrument]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionBboCode, body |-> ZeroAuctionBbo]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionClearingPriceCode, body |-> ZeroAuctionClearingPrice]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CrossRequestCode, body |-> ZeroCrossRequest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionSummaryCode, body |-> ZeroExecutionSummary]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FullOrderExecutionCode, body |-> ZeroFullOrderExecution]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> ZeroHeartbeat]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStateChangeCode, body |-> ZeroInstrumentStateChange]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentSummaryCode, body |-> ZeroInstrumentSummary]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassInstrumentStateChangeCode, body |-> ZeroMassInstrumentStateChange]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddCode, body |-> ZeroOrderAdd]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteCode, body |-> ZeroOrderDelete]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMassDeleteCode, body |-> ZeroOrderMassDelete]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyCode, body |-> ZeroOrderModify]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifySamePrioCode, body |-> ZeroOrderModifySamePrio]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PartialOrderExecutionCode, body |-> ZeroPartialOrderExecution]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ProductStateChangeCode, body |-> ZeroProductStateChange]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ProductSummaryCode, body |-> ZeroProductSummary]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestCode, body |-> ZeroQuoteRequest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotOrderCode, body |-> ZeroSnapshotOrder]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookCode, body |-> ZeroTopOfBook]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportCode, body |-> ZeroTradeReport]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReversalCode, body |-> ZeroTradeReversal]] }

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

(* Every Instrmt Leg Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmtLegGrpComp ==
    \A message \in CheckedInstrmtLegGrpComp :
        LET read == DecodeInstrmtLegGrpComp(EncodeInstrmtLegGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Complex Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripAddComplexInstrument ==
    \A message \in CheckedAddComplexInstrument :
        LET read == DecodeAddComplexInstrument(EncodeAddComplexInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Bbo decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionBbo ==
    \A message \in CheckedAuctionBbo :
        LET read == DecodeAuctionBbo(EncodeAuctionBbo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Clearing Price decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionClearingPrice ==
    \A message \in CheckedAuctionClearingPrice :
        LET read == DecodeAuctionClearingPrice(EncodeAuctionClearingPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Request decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossRequest ==
    \A message \in CheckedCrossRequest :
        LET read == DecodeCrossRequest(EncodeCrossRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionSummary ==
    \A message \in CheckedExecutionSummary :
        LET read == DecodeExecutionSummary(EncodeExecutionSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Full Order Execution decodes back to what was encoded, and leaves nothing over *)
RoundTripFullOrderExecution ==
    \A message \in CheckedFullOrderExecution :
        LET read == DecodeFullOrderExecution(EncodeFullOrderExecution(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET read == DecodeHeartbeat(EncodeHeartbeat(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument State Change decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStateChange ==
    \A message \in CheckedInstrumentStateChange :
        LET read == DecodeInstrumentStateChange(EncodeInstrumentStateChange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Instrument Entry Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentEntryGrpComp ==
    \A message \in CheckedMdInstrumentEntryGrpComp :
        LET read == DecodeMdInstrumentEntryGrpComp(EncodeMdInstrumentEntryGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentSummary ==
    \A message \in CheckedInstrumentSummary :
        LET read == DecodeInstrumentSummary(EncodeInstrumentSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sec Mass Stat Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSecMassStatGrpComp ==
    \A message \in CheckedSecMassStatGrpComp :
        LET read == DecodeSecMassStatGrpComp(EncodeSecMassStatGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Instrument State Change decodes back to what was encoded, and leaves nothing over *)
RoundTripMassInstrumentStateChange ==
    \A message \in CheckedMassInstrumentStateChange :
        LET read == DecodeMassInstrumentStateChange(EncodeMassInstrumentStateChange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Details Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetailsComp ==
    \A message \in CheckedOrderDetailsComp :
        LET read == DecodeOrderDetailsComp(EncodeOrderDetailsComp(message))
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

(* Every Order Details Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetailsComp2 ==
    \A message \in CheckedOrderDetailsComp2 :
        LET read == DecodeOrderDetailsComp2(EncodeOrderDetailsComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDelete ==
    \A message \in CheckedOrderDelete :
        LET read == DecodeOrderDelete(EncodeOrderDelete(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Delete decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassDelete ==
    \A message \in CheckedOrderMassDelete :
        LET read == DecodeOrderMassDelete(EncodeOrderMassDelete(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Details Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetailsComp3 ==
    \A message \in CheckedOrderDetailsComp3 :
        LET read == DecodeOrderDetailsComp3(EncodeOrderDetailsComp3(message))
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

(* Every Order Details Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetailsComp4 ==
    \A message \in CheckedOrderDetailsComp4 :
        LET read == DecodeOrderDetailsComp4(EncodeOrderDetailsComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Same Prio decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifySamePrio ==
    \A message \in CheckedOrderModifySamePrio :
        LET read == DecodeOrderModifySamePrio(EncodeOrderModifySamePrio(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partial Order Execution decodes back to what was encoded, and leaves nothing over *)
RoundTripPartialOrderExecution ==
    \A message \in CheckedPartialOrderExecution :
        LET read == DecodePartialOrderExecution(EncodePartialOrderExecution(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product State Change decodes back to what was encoded, and leaves nothing over *)
RoundTripProductStateChange ==
    \A message \in CheckedProductStateChange :
        LET read == DecodeProductStateChange(EncodeProductStateChange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripProductSummary ==
    \A message \in CheckedProductSummary :
        LET read == DecodeProductSummary(EncodeProductSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequest ==
    \A message \in CheckedQuoteRequest :
        LET read == DecodeQuoteRequest(EncodeQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Details Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDetailsComp5 ==
    \A message \in CheckedOrderDetailsComp5 :
        LET read == DecodeOrderDetailsComp5(EncodeOrderDetailsComp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Order decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotOrder ==
    \A message \in CheckedSnapshotOrder :
        LET read == DecodeSnapshotOrder(EncodeSnapshotOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Of Book decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfBook ==
    \A message \in CheckedTopOfBook :
        LET read == DecodeTopOfBook(EncodeTopOfBook(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReport ==
    \A message \in CheckedTradeReport :
        LET read == DecodeTradeReport(EncodeTradeReport(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Trade Entry Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripMdTradeEntryGrpComp ==
    \A message \in CheckedMdTradeEntryGrpComp :
        LET read == DecodeMdTradeEntryGrpComp(EncodeMdTradeEntryGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Reversal decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReversal ==
    \A message \in CheckedTradeReversal :
        LET read == DecodeTradeReversal(EncodeTradeReversal(message))
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
