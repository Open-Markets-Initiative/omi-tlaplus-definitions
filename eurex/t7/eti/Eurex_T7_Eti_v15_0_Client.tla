--------------------- MODULE Eurex_T7_Eti_v15_0_Client ---------------------
(***************************************************************************)
(* Eurex Exchange Enhanced Trading Interface v15.0                         *)
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
(* Note: Add Complex Instrument Request fills what is left of the frame    *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Add Flexible Instrument Request fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Add Scaled Simple Instrument Request fills what is left of the    *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Amend Basket Trade Request fills what is left of the frame Body   *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Approve Basket Trade Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Approve Reverse Tes Trade Request fills what is left of the frame *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Approve Tes Trade Request fills what is left of the frame Body    *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Basket Roll Request fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Cross Request fills what is left of the frame Body Len states,    *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Delete All Order Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete All Quote Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete Basket Trade Request fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Delete Clip Request fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete Order Request fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete Tes Trade Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Enter Basket Trade Request fills what is left of the frame Body   *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Enter Clip Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Enter Tes Trade Request fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Heartbeat fills what is left of the frame Body Len states, which  *)
(* is what it is read from.                                                *)
(*                                                                         *)
(* Note: Inquire Enrichment Rule Id List Request fills what is left of the *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Inquire Mm Parameter Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Inquire Margin Based Risk Limit Request fills what is left of the *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Inquire Pre Trade Risk Limits Request fills what is left of the   *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Inquire Session List Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Inquire User Request fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Logon Request fills what is left of the frame Body Len states,    *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Logon Request Encrypted fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Logout Request fills what is left of the frame Body Len states,   *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Mm Parameter Definition Request fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Mass Order fills what is left of the frame Body Len states, which *)
(* is what it is read from.                                                *)
(*                                                                         *)
(* Note: Mass Quote Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Modify Basket Trade Request fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Modify Order Request fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Modify Order Short Request fills what is left of the frame Body   *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Modify Tes Trade Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Request fills what is left of the frame Body Len        *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Short Request fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Ping Request fills what is left of the frame Body Len states,     *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Pre Trade Risk Limits Definition Request fills what is left of    *)
(* the frame Body Len states, which is what it is read from.               *)
(*                                                                         *)
(* Note: Quote Activation Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Rfq Request fills what is left of the frame Body Len states,      *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Retransmit Me Message Request fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Retransmit Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Reverse Tes Trade Request fills what is left of the frame Body    *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Srqs Enter Quote Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Srqs Hit Quote Request fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Srqs Inquire Smart Respondent Request fills what is left of the   *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Srqs Open Negotiation Request fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Srqs Quote Snapshot Request fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Srqs Quoting Status Request fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Srqs Update Deal Status Request fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Srqs Update Negotiation Request fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Subscribe Request fills what is left of the frame Body Len        *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Tes Inquire Boundary Prices Request fills what is left of the     *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Trading Action Request fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Unsubscribe Request fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Update Reference Price Request fills what is left of the frame    *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Update Remaining Risk Allowance Base Request fills what is left   *)
(* of the frame Body Len states, which is what it is read from.            *)
(*                                                                         *)
(* Note: Upload Tes Trade Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Login Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Login Request Encrypted fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: User Logout Request fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
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
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp ==
    { ZeroRequestHeaderComp }
        \cup { [ZeroRequestHeaderComp EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrmt Leg Grp Comp: 32 bytes                                          *)
(***************************************************************************)

InstrmtLegGrpComp ==
    [ legSecurityId   : Sample(8),
      legPrice        : Sample(8),
      legSymbol       : Sample(4),
      legRatioQty     : Sample(4),
      legSide         : Sample(1),
      legSecurityType : Sample(1),
      pad6            : Sample(6) ]

EncodeInstrmtLegGrpComp(message) ==
    message.legSecurityId
        \o message.legPrice
        \o message.legSymbol
        \o message.legRatioQty
        \o message.legSide
        \o message.legSecurityType
        \o message.pad6

DecodeInstrmtLegGrpComp(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSecurityId.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legPrice.rest, 4) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSymbol.rest, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legSide.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET pad6 == ReadBytes(legSecurityType.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId   |-> legSecurityId.value,
         legPrice        |-> legPrice.value,
         legSymbol       |-> legSymbol.value,
         legRatioQty     |-> legRatioQty.value,
         legSide         |-> legSide.value,
         legSecurityType |-> legSecurityType.value,
         pad6            |-> pad6.value ], pad6.rest)

ZeroInstrmtLegGrpComp ==
    [ legSecurityId   |-> [i \in 1 .. 8 |-> 0],
      legPrice        |-> [i \in 1 .. 8 |-> 0],
      legSymbol       |-> [i \in 1 .. 4 |-> 0],
      legRatioQty     |-> [i \in 1 .. 4 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0],
      pad6            |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmt Leg Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmtLegGrpComp ==
    { ZeroInstrmtLegGrpComp }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSymbol = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legRatioQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

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

(***************************************************************************)
(* Add Complex Instrument Request                                          *)
(***************************************************************************)

AddComplexInstrumentRequest ==
    [ networkMsgId               : Sample(8),
      pad2                       : Sample(2),
      requestHeaderComp          : RequestHeaderComp,
      relatedPx                  : Sample(8),
      marketSegmentId            : Sample(4),
      securitySubType            : Sample(4),
      quantityScalingFactor      : Sample(2),
      productComplex             : Sample(1),
      multilegModel              : Sample(1),
      enableCustomCommodityStrip : Sample(1),
      complianceText             : Sample(20),
      displayNameAlias           : Sample(190),
      periodAlias                : Sample(45),
      pad3                       : Sample(3),
      instrmtLegGrpComp          : SampleLists(OneInstrmtLegGrpComp) ]

EncodeAddComplexInstrumentRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp(message.requestHeaderComp)
        \o message.relatedPx
        \o message.marketSegmentId
        \o message.securitySubType
        \o message.quantityScalingFactor
        \o message.productComplex
        \o EncodeUIntBE(Len(message.instrmtLegGrpComp), 1)
        \o message.multilegModel
        \o message.enableCustomCommodityStrip
        \o message.complianceText
        \o message.displayNameAlias
        \o message.periodAlias
        \o message.pad3
        \o EncodeInstrmtLegGrpCompList(message.instrmtLegGrpComp)

DecodeAddComplexInstrumentRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET relatedPx == ReadBytes(requestHeaderComp.rest, 8) IN IF ~relatedPx.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(relatedPx.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(marketSegmentId.rest, 4) IN IF ~securitySubType.ok THEN Fail ELSE
    LET quantityScalingFactor == ReadBytes(securitySubType.rest, 2) IN IF ~quantityScalingFactor.ok THEN Fail ELSE
    LET productComplex == ReadBytes(quantityScalingFactor.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET noLegOnbooks == ReadUIntBE(productComplex.rest, 1) IN IF ~noLegOnbooks.ok THEN Fail ELSE
    LET multilegModel == ReadBytes(noLegOnbooks.rest, 1) IN IF ~multilegModel.ok THEN Fail ELSE
    LET enableCustomCommodityStrip == ReadBytes(multilegModel.rest, 1) IN IF ~enableCustomCommodityStrip.ok THEN Fail ELSE
    LET complianceText == ReadBytes(enableCustomCommodityStrip.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET displayNameAlias == ReadBytes(complianceText.rest, 190) IN IF ~displayNameAlias.ok THEN Fail ELSE
    LET periodAlias == ReadBytes(displayNameAlias.rest, 45) IN IF ~periodAlias.ok THEN Fail ELSE
    LET pad3 == ReadBytes(periodAlias.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET instrmtLegGrpComp == ReadInstrmtLegGrpCompList(pad3.rest, noLegOnbooks.value) IN IF ~instrmtLegGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId               |-> networkMsgId.value,
         pad2                       |-> pad2.value,
         requestHeaderComp          |-> requestHeaderComp.value,
         relatedPx                  |-> relatedPx.value,
         marketSegmentId            |-> marketSegmentId.value,
         securitySubType            |-> securitySubType.value,
         quantityScalingFactor      |-> quantityScalingFactor.value,
         productComplex             |-> productComplex.value,
         multilegModel              |-> multilegModel.value,
         enableCustomCommodityStrip |-> enableCustomCommodityStrip.value,
         complianceText             |-> complianceText.value,
         displayNameAlias           |-> displayNameAlias.value,
         periodAlias                |-> periodAlias.value,
         pad3                       |-> pad3.value,
         instrmtLegGrpComp          |-> instrmtLegGrpComp.value ], instrmtLegGrpComp.rest)

ZeroAddComplexInstrumentRequest ==
    [ networkMsgId               |-> [i \in 1 .. 8 |-> 0],
      pad2                       |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp          |-> ZeroRequestHeaderComp,
      relatedPx                  |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId            |-> [i \in 1 .. 4 |-> 0],
      securitySubType            |-> [i \in 1 .. 4 |-> 0],
      quantityScalingFactor      |-> [i \in 1 .. 2 |-> 0],
      productComplex             |-> [i \in 1 .. 1 |-> 0],
      multilegModel              |-> [i \in 1 .. 1 |-> 0],
      enableCustomCommodityStrip |-> [i \in 1 .. 1 |-> 0],
      complianceText             |-> [i \in 1 .. 20 |-> 0],
      displayNameAlias           |-> [i \in 1 .. 190 |-> 0],
      periodAlias                |-> [i \in 1 .. 45 |-> 0],
      pad3                       |-> [i \in 1 .. 3 |-> 0],
      instrmtLegGrpComp          |-> << >> ]

(* Add Complex Instrument Request at zero, then each field in turn at the values it is checked at *)
CheckedAddComplexInstrumentRequest ==
    { ZeroAddComplexInstrumentRequest }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.relatedPx = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.securitySubType = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.quantityScalingFactor = one] : one \in Sample(2) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.multilegModel = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.enableCustomCommodityStrip = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.displayNameAlias = one] : one \in Sample(190) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.periodAlias = one] : one \in Sample(45) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.instrmtLegGrpComp = one] : one \in SampleLists(OneInstrmtLegGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp2 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp2(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp2(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp2 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp2 ==
    { ZeroRequestHeaderComp2 }
        \cup { [ZeroRequestHeaderComp2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp2 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Flexible Instrument Request: 66 bytes                               *)
(***************************************************************************)

AddFlexibleInstrumentRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp2,
      strikePrice       : Sample(8),
      marketSegmentId   : Sample(4),
      maturityDate      : Sample(4),
      contractDate      : Sample(4),
      settlMethod       : Sample(1),
      optAttribute      : Sample(1),
      putOrCall         : Sample(1),
      exerciseStyle     : Sample(1),
      complianceText    : Sample(20),
      pad4              : Sample(4) ]

EncodeAddFlexibleInstrumentRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp2(message.requestHeaderComp)
        \o message.strikePrice
        \o message.marketSegmentId
        \o message.maturityDate
        \o message.contractDate
        \o message.settlMethod
        \o message.optAttribute
        \o message.putOrCall
        \o message.exerciseStyle
        \o message.complianceText
        \o message.pad4

DecodeAddFlexibleInstrumentRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp2(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(requestHeaderComp.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(strikePrice.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET contractDate == ReadBytes(maturityDate.rest, 4) IN IF ~contractDate.ok THEN Fail ELSE
    LET settlMethod == ReadBytes(contractDate.rest, 1) IN IF ~settlMethod.ok THEN Fail ELSE
    LET optAttribute == ReadBytes(settlMethod.rest, 1) IN IF ~optAttribute.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(optAttribute.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(putOrCall.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET complianceText == ReadBytes(exerciseStyle.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad4 == ReadBytes(complianceText.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         strikePrice       |-> strikePrice.value,
         marketSegmentId   |-> marketSegmentId.value,
         maturityDate      |-> maturityDate.value,
         contractDate      |-> contractDate.value,
         settlMethod       |-> settlMethod.value,
         optAttribute      |-> optAttribute.value,
         putOrCall         |-> putOrCall.value,
         exerciseStyle     |-> exerciseStyle.value,
         complianceText    |-> complianceText.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroAddFlexibleInstrumentRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp2,
      strikePrice       |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      maturityDate      |-> [i \in 1 .. 4 |-> 0],
      contractDate      |-> [i \in 1 .. 4 |-> 0],
      settlMethod       |-> [i \in 1 .. 1 |-> 0],
      optAttribute      |-> [i \in 1 .. 1 |-> 0],
      putOrCall         |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle     |-> [i \in 1 .. 1 |-> 0],
      complianceText    |-> [i \in 1 .. 20 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Add Flexible Instrument Request at zero, then each field in turn at the values it is checked at *)
CheckedAddFlexibleInstrumentRequest ==
    { ZeroAddFlexibleInstrumentRequest }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp2 }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.contractDate = one] : one \in Sample(4) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.settlMethod = one] : one \in Sample(1) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.optAttribute = one] : one \in Sample(1) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp3 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp3(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp3(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp3 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp3 ==
    { ZeroRequestHeaderComp3 }
        \cup { [ZeroRequestHeaderComp3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp3 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Scaled Simple Instrument Request: 274 bytes                         *)
(***************************************************************************)

AddScaledSimpleInstrumentRequest ==
    [ networkMsgId          : Sample(8),
      pad2                  : Sample(2),
      requestHeaderComp     : RequestHeaderComp3,
      relatedSecurityId     : Sample(8),
      marketSegmentId       : Sample(4),
      quantityScalingFactor : Sample(2),
      multilegModel         : Sample(1),
      displayNameAlias      : Sample(190),
      periodAlias           : Sample(45),
      pad6                  : Sample(6) ]

EncodeAddScaledSimpleInstrumentRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp3(message.requestHeaderComp)
        \o message.relatedSecurityId
        \o message.marketSegmentId
        \o message.quantityScalingFactor
        \o message.multilegModel
        \o message.displayNameAlias
        \o message.periodAlias
        \o message.pad6

DecodeAddScaledSimpleInstrumentRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp3(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET relatedSecurityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~relatedSecurityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(relatedSecurityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET quantityScalingFactor == ReadBytes(marketSegmentId.rest, 2) IN IF ~quantityScalingFactor.ok THEN Fail ELSE
    LET multilegModel == ReadBytes(quantityScalingFactor.rest, 1) IN IF ~multilegModel.ok THEN Fail ELSE
    LET displayNameAlias == ReadBytes(multilegModel.rest, 190) IN IF ~displayNameAlias.ok THEN Fail ELSE
    LET periodAlias == ReadBytes(displayNameAlias.rest, 45) IN IF ~periodAlias.ok THEN Fail ELSE
    LET pad6 == ReadBytes(periodAlias.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId          |-> networkMsgId.value,
         pad2                  |-> pad2.value,
         requestHeaderComp     |-> requestHeaderComp.value,
         relatedSecurityId     |-> relatedSecurityId.value,
         marketSegmentId       |-> marketSegmentId.value,
         quantityScalingFactor |-> quantityScalingFactor.value,
         multilegModel         |-> multilegModel.value,
         displayNameAlias      |-> displayNameAlias.value,
         periodAlias           |-> periodAlias.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroAddScaledSimpleInstrumentRequest ==
    [ networkMsgId          |-> [i \in 1 .. 8 |-> 0],
      pad2                  |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp     |-> ZeroRequestHeaderComp3,
      relatedSecurityId     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      quantityScalingFactor |-> [i \in 1 .. 2 |-> 0],
      multilegModel         |-> [i \in 1 .. 1 |-> 0],
      displayNameAlias      |-> [i \in 1 .. 190 |-> 0],
      periodAlias           |-> [i \in 1 .. 45 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Add Scaled Simple Instrument Request at zero, then each field in turn at the values it is checked at *)
CheckedAddScaledSimpleInstrumentRequest ==
    { ZeroAddScaledSimpleInstrumentRequest }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp3 }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.relatedSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.quantityScalingFactor = one] : one \in Sample(2) }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.multilegModel = one] : one \in Sample(1) }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.displayNameAlias = one] : one \in Sample(190) }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.periodAlias = one] : one \in Sample(45) }
        \cup { [ZeroAddScaledSimpleInstrumentRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp4 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp4(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp4(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp4 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp4 ==
    { ZeroRequestHeaderComp4 }
        \cup { [ZeroRequestHeaderComp4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp4 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Basket Root Party Grp Comp: 40 bytes                                    *)
(***************************************************************************)

BasketRootPartyGrpComp ==
    [ rootPartySubIdType      : Sample(2),
      rootPartyContraFirm     : Sample(5),
      rootPartyContraTrader   : Sample(6),
      basketSideTradeReportId : Sample(20),
      pad7                    : Sample(7) ]

EncodeBasketRootPartyGrpComp(message) ==
    message.rootPartySubIdType
        \o message.rootPartyContraFirm
        \o message.rootPartyContraTrader
        \o message.basketSideTradeReportId
        \o message.pad7

DecodeBasketRootPartyGrpComp(bytes) ==
    LET rootPartySubIdType == ReadBytes(bytes, 2) IN IF ~rootPartySubIdType.ok THEN Fail ELSE
    LET rootPartyContraFirm == ReadBytes(rootPartySubIdType.rest, 5) IN IF ~rootPartyContraFirm.ok THEN Fail ELSE
    LET rootPartyContraTrader == ReadBytes(rootPartyContraFirm.rest, 6) IN IF ~rootPartyContraTrader.ok THEN Fail ELSE
    LET basketSideTradeReportId == ReadBytes(rootPartyContraTrader.rest, 20) IN IF ~basketSideTradeReportId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(basketSideTradeReportId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ rootPartySubIdType      |-> rootPartySubIdType.value,
         rootPartyContraFirm     |-> rootPartyContraFirm.value,
         rootPartyContraTrader   |-> rootPartyContraTrader.value,
         basketSideTradeReportId |-> basketSideTradeReportId.value,
         pad7                    |-> pad7.value ], pad7.rest)

ZeroBasketRootPartyGrpComp ==
    [ rootPartySubIdType      |-> [i \in 1 .. 2 |-> 0],
      rootPartyContraFirm     |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraTrader   |-> [i \in 1 .. 6 |-> 0],
      basketSideTradeReportId |-> [i \in 1 .. 20 |-> 0],
      pad7                    |-> [i \in 1 .. 7 |-> 0] ]

(* Basket Root Party Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedBasketRootPartyGrpComp ==
    { ZeroBasketRootPartyGrpComp }
        \cup { [ZeroBasketRootPartyGrpComp EXCEPT !.rootPartySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroBasketRootPartyGrpComp EXCEPT !.rootPartyContraFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketRootPartyGrpComp EXCEPT !.rootPartyContraTrader = one] : one \in Sample(6) }
        \cup { [ZeroBasketRootPartyGrpComp EXCEPT !.basketSideTradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroBasketRootPartyGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Basket Root Party Grp Comp, written one after another *)
RECURSIVE EncodeBasketRootPartyGrpCompList(_)
EncodeBasketRootPartyGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBasketRootPartyGrpComp(Head(messages)) \o EncodeBasketRootPartyGrpCompList(Tail(messages))

(* As many Basket Root Party Grp Comp as the field that counts them says *)
RECURSIVE ReadBasketRootPartyGrpCompList(_, _)
ReadBasketRootPartyGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBasketRootPartyGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBasketRootPartyGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Basket Root Party Grp Comp of each kind, for the lists that carry them *)
OneBasketRootPartyGrpComp == { ZeroBasketRootPartyGrpComp }

(***************************************************************************)
(* Instrmt Match Side Grp Comp: 80 bytes                                   *)
(***************************************************************************)

InstrmtMatchSideGrpComp ==
    [ securityId            : Sample(8),
      lastPx                : Sample(8),
      transBkdTime          : Sample(8),
      relatedClosePrice     : Sample(8),
      clearingTradePrice    : Sample(8),
      packageId             : Sample(4),
      sideMarketSegmentId   : Sample(4),
      sideTrdSubTyp         : Sample(2),
      productComplex        : Sample(1),
      tradePublishIndicator : Sample(1),
      instrmtMatchSideId    : Sample(1),
      effectOnBasket        : Sample(1),
      tradeReportText       : Sample(20),
      pad6                  : Sample(6) ]

EncodeInstrmtMatchSideGrpComp(message) ==
    message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.relatedClosePrice
        \o message.clearingTradePrice
        \o message.packageId
        \o message.sideMarketSegmentId
        \o message.sideTrdSubTyp
        \o message.productComplex
        \o message.tradePublishIndicator
        \o message.instrmtMatchSideId
        \o message.effectOnBasket
        \o message.tradeReportText
        \o message.pad6

DecodeInstrmtMatchSideGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(transBkdTime.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET clearingTradePrice == ReadBytes(relatedClosePrice.rest, 8) IN IF ~clearingTradePrice.ok THEN Fail ELSE
    LET packageId == ReadBytes(clearingTradePrice.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET sideMarketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~sideMarketSegmentId.ok THEN Fail ELSE
    LET sideTrdSubTyp == ReadBytes(sideMarketSegmentId.rest, 2) IN IF ~sideTrdSubTyp.ok THEN Fail ELSE
    LET productComplex == ReadBytes(sideTrdSubTyp.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(productComplex.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(tradePublishIndicator.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET effectOnBasket == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~effectOnBasket.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(effectOnBasket.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET pad6 == ReadBytes(tradeReportText.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         lastPx                |-> lastPx.value,
         transBkdTime          |-> transBkdTime.value,
         relatedClosePrice     |-> relatedClosePrice.value,
         clearingTradePrice    |-> clearingTradePrice.value,
         packageId             |-> packageId.value,
         sideMarketSegmentId   |-> sideMarketSegmentId.value,
         sideTrdSubTyp         |-> sideTrdSubTyp.value,
         productComplex        |-> productComplex.value,
         tradePublishIndicator |-> tradePublishIndicator.value,
         instrmtMatchSideId    |-> instrmtMatchSideId.value,
         effectOnBasket        |-> effectOnBasket.value,
         tradeReportText       |-> tradeReportText.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroInstrmtMatchSideGrpComp ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      transBkdTime          |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice     |-> [i \in 1 .. 8 |-> 0],
      clearingTradePrice    |-> [i \in 1 .. 8 |-> 0],
      packageId             |-> [i \in 1 .. 4 |-> 0],
      sideMarketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      sideTrdSubTyp         |-> [i \in 1 .. 2 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId    |-> [i \in 1 .. 1 |-> 0],
      effectOnBasket        |-> [i \in 1 .. 1 |-> 0],
      tradeReportText       |-> [i \in 1 .. 20 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmt Match Side Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmtMatchSideGrpComp ==
    { ZeroInstrmtMatchSideGrpComp }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.clearingTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.sideMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.sideTrdSubTyp = one] : one \in Sample(2) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.effectOnBasket = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroInstrmtMatchSideGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmt Match Side Grp Comp, written one after another *)
RECURSIVE EncodeInstrmtMatchSideGrpCompList(_)
EncodeInstrmtMatchSideGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmtMatchSideGrpComp(Head(messages)) \o EncodeInstrmtMatchSideGrpCompList(Tail(messages))

(* As many Instrmt Match Side Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmtMatchSideGrpCompList(_, _)
ReadInstrmtMatchSideGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmtMatchSideGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmtMatchSideGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmt Match Side Grp Comp of each kind, for the lists that carry them *)
OneInstrmtMatchSideGrpComp == { ZeroInstrmtMatchSideGrpComp }

(***************************************************************************)
(* Basket Side Alloc Grp Comp: 32 bytes                                    *)
(***************************************************************************)

BasketSideAllocGrpComp ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      partySubIdType       : Sample(2),
      side                 : Sample(1),
      instrmtMatchSideId   : Sample(1),
      tradeAllocStatus     : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeBasketSideAllocGrpComp(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.partySubIdType
        \o message.side
        \o message.instrmtMatchSideId
        \o message.tradeAllocStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeBasketSideAllocGrpComp(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET partySubIdType == ReadBytes(individualAllocId.rest, 2) IN IF ~partySubIdType.ok THEN Fail ELSE
    LET side == ReadBytes(partySubIdType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(side.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tradeAllocStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         partySubIdType       |-> partySubIdType.value,
         side                 |-> side.value,
         instrmtMatchSideId   |-> instrmtMatchSideId.value,
         tradeAllocStatus     |-> tradeAllocStatus.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroBasketSideAllocGrpComp ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      partySubIdType       |-> [i \in 1 .. 2 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId   |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus     |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Basket Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedBasketSideAllocGrpComp ==
    { ZeroBasketSideAllocGrpComp }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.partySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroBasketSideAllocGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Basket Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeBasketSideAllocGrpCompList(_)
EncodeBasketSideAllocGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBasketSideAllocGrpComp(Head(messages)) \o EncodeBasketSideAllocGrpCompList(Tail(messages))

(* As many Basket Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadBasketSideAllocGrpCompList(_, _)
ReadBasketSideAllocGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBasketSideAllocGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBasketSideAllocGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Basket Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneBasketSideAllocGrpComp == { ZeroBasketSideAllocGrpComp }

(***************************************************************************)
(* Amend Basket Trade Request                                              *)
(***************************************************************************)

AmendBasketTradeRequest ==
    [ networkMsgId            : Sample(8),
      pad2                    : Sample(2),
      requestHeaderComp       : RequestHeaderComp4,
      basketTrdMatchId        : Sample(8),
      basketExecId            : Sample(4),
      marketSegmentId         : Sample(4),
      maturityMonthYear       : Sample(4),
      basketProfileId         : Sample(4),
      trdType                 : Sample(2),
      tradeReportType         : Sample(1),
      basketTradeReportType   : Sample(1),
      basketTradeReportText   : Sample(20),
      tradeReportId           : Sample(20),
      basketRootPartyGrpComp  : SampleLists(OneBasketRootPartyGrpComp),
      instrmtMatchSideGrpComp : SampleLists(OneInstrmtMatchSideGrpComp),
      basketSideAllocGrpComp  : SampleLists(OneBasketSideAllocGrpComp) ]

EncodeAmendBasketTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp4(message.requestHeaderComp)
        \o message.basketTrdMatchId
        \o message.basketExecId
        \o message.marketSegmentId
        \o message.maturityMonthYear
        \o message.basketProfileId
        \o message.trdType
        \o EncodeUIntLE(Len(message.basketSideAllocGrpComp), 2)
        \o message.tradeReportType
        \o message.basketTradeReportType
        \o EncodeUIntBE(Len(message.basketRootPartyGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrmtMatchSideGrpComp), 1)
        \o message.basketTradeReportText
        \o message.tradeReportId
        \o EncodeBasketRootPartyGrpCompList(message.basketRootPartyGrpComp)
        \o EncodeInstrmtMatchSideGrpCompList(message.instrmtMatchSideGrpComp)
        \o EncodeBasketSideAllocGrpCompList(message.basketSideAllocGrpComp)

DecodeAmendBasketTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp4(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET basketTrdMatchId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~basketTrdMatchId.ok THEN Fail ELSE
    LET basketExecId == ReadBytes(basketTrdMatchId.rest, 4) IN IF ~basketExecId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(basketExecId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(marketSegmentId.rest, 4) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET basketProfileId == ReadBytes(maturityMonthYear.rest, 4) IN IF ~basketProfileId.ok THEN Fail ELSE
    LET trdType == ReadBytes(basketProfileId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET noBasketSideAlloc == ReadUIntLE(trdType.rest, 2) IN IF ~noBasketSideAlloc.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(noBasketSideAlloc.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET basketTradeReportType == ReadBytes(tradeReportType.rest, 1) IN IF ~basketTradeReportType.ok THEN Fail ELSE
    LET noBasketRootPartyGrps == ReadUIntBE(basketTradeReportType.rest, 1) IN IF ~noBasketRootPartyGrps.ok THEN Fail ELSE
    LET noInstrmtMatchSides == ReadUIntBE(noBasketRootPartyGrps.rest, 1) IN IF ~noInstrmtMatchSides.ok THEN Fail ELSE
    LET basketTradeReportText == ReadBytes(noInstrmtMatchSides.rest, 20) IN IF ~basketTradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(basketTradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET basketRootPartyGrpComp == ReadBasketRootPartyGrpCompList(tradeReportId.rest, noBasketRootPartyGrps.value) IN IF ~basketRootPartyGrpComp.ok THEN Fail ELSE
    LET instrmtMatchSideGrpComp == ReadInstrmtMatchSideGrpCompList(basketRootPartyGrpComp.rest, noInstrmtMatchSides.value) IN IF ~instrmtMatchSideGrpComp.ok THEN Fail ELSE
    LET basketSideAllocGrpComp == ReadBasketSideAllocGrpCompList(instrmtMatchSideGrpComp.rest, noBasketSideAlloc.value) IN IF ~basketSideAllocGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId            |-> networkMsgId.value,
         pad2                    |-> pad2.value,
         requestHeaderComp       |-> requestHeaderComp.value,
         basketTrdMatchId        |-> basketTrdMatchId.value,
         basketExecId            |-> basketExecId.value,
         marketSegmentId         |-> marketSegmentId.value,
         maturityMonthYear       |-> maturityMonthYear.value,
         basketProfileId         |-> basketProfileId.value,
         trdType                 |-> trdType.value,
         tradeReportType         |-> tradeReportType.value,
         basketTradeReportType   |-> basketTradeReportType.value,
         basketTradeReportText   |-> basketTradeReportText.value,
         tradeReportId           |-> tradeReportId.value,
         basketRootPartyGrpComp  |-> basketRootPartyGrpComp.value,
         instrmtMatchSideGrpComp |-> instrmtMatchSideGrpComp.value,
         basketSideAllocGrpComp  |-> basketSideAllocGrpComp.value ], basketSideAllocGrpComp.rest)

ZeroAmendBasketTradeRequest ==
    [ networkMsgId            |-> [i \in 1 .. 8 |-> 0],
      pad2                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp       |-> ZeroRequestHeaderComp4,
      basketTrdMatchId        |-> [i \in 1 .. 8 |-> 0],
      basketExecId            |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId         |-> [i \in 1 .. 4 |-> 0],
      maturityMonthYear       |-> [i \in 1 .. 4 |-> 0],
      basketProfileId         |-> [i \in 1 .. 4 |-> 0],
      trdType                 |-> [i \in 1 .. 2 |-> 0],
      tradeReportType         |-> [i \in 1 .. 1 |-> 0],
      basketTradeReportType   |-> [i \in 1 .. 1 |-> 0],
      basketTradeReportText   |-> [i \in 1 .. 20 |-> 0],
      tradeReportId           |-> [i \in 1 .. 20 |-> 0],
      basketRootPartyGrpComp  |-> << >>,
      instrmtMatchSideGrpComp |-> << >>,
      basketSideAllocGrpComp  |-> << >> ]

(* Amend Basket Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedAmendBasketTradeRequest ==
    { ZeroAmendBasketTradeRequest }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp4 }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.basketTrdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.basketExecId = one] : one \in Sample(4) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.maturityMonthYear = one] : one \in Sample(4) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.basketProfileId = one] : one \in Sample(4) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.basketTradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.basketTradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.basketRootPartyGrpComp = one] : one \in SampleLists(OneBasketRootPartyGrpComp) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.instrmtMatchSideGrpComp = one] : one \in SampleLists(OneInstrmtMatchSideGrpComp) }
        \cup { [ZeroAmendBasketTradeRequest EXCEPT !.basketSideAllocGrpComp = one] : one \in SampleLists(OneBasketSideAllocGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp5 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp5(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp5(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp5 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp5 ==
    { ZeroRequestHeaderComp5 }
        \cup { [ZeroRequestHeaderComp5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp5 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Basket Side Alloc Ext Grp Comp: 184 bytes                               *)
(***************************************************************************)

BasketSideAllocExtGrpComp ==
    [ allocQty                                : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      packageId                               : Sample(4),
      sideMarketSegmentId                     : Sample(4),
      allocId                                 : Sample(4),
      side                                    : Sample(1),
      positionEffect                          : Sample(1),
      tradingCapacity                         : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      orderAttributeRiskReduction             : Sample(1),
      orderOrigination                        : Sample(1),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      account                                 : Sample(2),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      partyIdTakeUpTradingFirm                : Sample(5),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdBeneficiary                      : Sample(9),
      partyIdPositionAccount                  : Sample(32),
      partyIdLocationId                       : Sample(2),
      custOrderHandlingInst                   : Sample(1),
      complianceText                          : Sample(20),
      pad7                                    : Sample(7) ]

EncodeBasketSideAllocExtGrpComp(message) ==
    message.allocQty
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.packageId
        \o message.sideMarketSegmentId
        \o message.allocId
        \o message.side
        \o message.positionEffect
        \o message.tradingCapacity
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.orderAttributeRiskReduction
        \o message.orderOrigination
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.account
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.partyIdPositionAccount
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.pad7

DecodeBasketSideAllocExtGrpComp(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(allocQty.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET packageId == ReadBytes(executingTrader.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET sideMarketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~sideMarketSegmentId.ok THEN Fail ELSE
    LET allocId == ReadBytes(sideMarketSegmentId.rest, 4) IN IF ~allocId.ok THEN Fail ELSE
    LET side == ReadBytes(allocId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(side.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(positionEffect.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET orderAttributeRiskReduction == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~orderAttributeRiskReduction.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(orderAttributeRiskReduction.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(orderOrigination.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET account == ReadBytes(partyExecutingTrader.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(account.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(freeText3.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(partyIdBeneficiary.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(partyIdPositionAccount.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad7 == ReadBytes(complianceText.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ allocQty                                |-> allocQty.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         packageId                               |-> packageId.value,
         sideMarketSegmentId                     |-> sideMarketSegmentId.value,
         allocId                                 |-> allocId.value,
         side                                    |-> side.value,
         positionEffect                          |-> positionEffect.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         orderAttributeRiskReduction             |-> orderAttributeRiskReduction.value,
         orderOrigination                        |-> orderOrigination.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         account                                 |-> account.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         complianceText                          |-> complianceText.value,
         pad7                                    |-> pad7.value ], pad7.rest)

ZeroBasketSideAllocExtGrpComp ==
    [ allocQty                                |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      packageId                               |-> [i \in 1 .. 4 |-> 0],
      sideMarketSegmentId                     |-> [i \in 1 .. 4 |-> 0],
      allocId                                 |-> [i \in 1 .. 4 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      orderAttributeRiskReduction             |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      pad7                                    |-> [i \in 1 .. 7 |-> 0] ]

(* Basket Side Alloc Ext Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedBasketSideAllocExtGrpComp ==
    { ZeroBasketSideAllocExtGrpComp }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.sideMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.allocId = one] : one \in Sample(4) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.orderAttributeRiskReduction = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroBasketSideAllocExtGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Basket Side Alloc Ext Grp Comp, written one after another *)
RECURSIVE EncodeBasketSideAllocExtGrpCompList(_)
EncodeBasketSideAllocExtGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBasketSideAllocExtGrpComp(Head(messages)) \o EncodeBasketSideAllocExtGrpCompList(Tail(messages))

(* As many Basket Side Alloc Ext Grp Comp as the field that counts them says *)
RECURSIVE ReadBasketSideAllocExtGrpCompList(_, _)
ReadBasketSideAllocExtGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBasketSideAllocExtGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBasketSideAllocExtGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Basket Side Alloc Ext Grp Comp of each kind, for the lists that carry them *)
OneBasketSideAllocExtGrpComp == { ZeroBasketSideAllocExtGrpComp }

(***************************************************************************)
(* Approve Basket Trade Request                                            *)
(***************************************************************************)

ApproveBasketTradeRequest ==
    [ networkMsgId              : Sample(8),
      pad2                      : Sample(2),
      requestHeaderComp         : RequestHeaderComp5,
      basketTrdMatchId          : Sample(8),
      basketExecId              : Sample(4),
      marketSegmentId           : Sample(4),
      rootPartySubIdType        : Sample(2),
      trdType                   : Sample(2),
      tradeReportType           : Sample(1),
      basketTradeReportText     : Sample(20),
      tradeReportId             : Sample(20),
      basketSideTradeReportId   : Sample(20),
      pad5                      : Sample(5),
      basketSideAllocExtGrpComp : SampleLists(OneBasketSideAllocExtGrpComp) ]

EncodeApproveBasketTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp5(message.requestHeaderComp)
        \o message.basketTrdMatchId
        \o message.basketExecId
        \o message.marketSegmentId
        \o message.rootPartySubIdType
        \o EncodeUIntLE(Len(message.basketSideAllocExtGrpComp), 2)
        \o message.trdType
        \o message.tradeReportType
        \o message.basketTradeReportText
        \o message.tradeReportId
        \o message.basketSideTradeReportId
        \o message.pad5
        \o EncodeBasketSideAllocExtGrpCompList(message.basketSideAllocExtGrpComp)

DecodeApproveBasketTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp5(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET basketTrdMatchId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~basketTrdMatchId.ok THEN Fail ELSE
    LET basketExecId == ReadBytes(basketTrdMatchId.rest, 4) IN IF ~basketExecId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(basketExecId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET rootPartySubIdType == ReadBytes(marketSegmentId.rest, 2) IN IF ~rootPartySubIdType.ok THEN Fail ELSE
    LET noBasketSideAlloc == ReadUIntLE(rootPartySubIdType.rest, 2) IN IF ~noBasketSideAlloc.ok THEN Fail ELSE
    LET trdType == ReadBytes(noBasketSideAlloc.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET basketTradeReportText == ReadBytes(tradeReportType.rest, 20) IN IF ~basketTradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(basketTradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET basketSideTradeReportId == ReadBytes(tradeReportId.rest, 20) IN IF ~basketSideTradeReportId.ok THEN Fail ELSE
    LET pad5 == ReadBytes(basketSideTradeReportId.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    LET basketSideAllocExtGrpComp == ReadBasketSideAllocExtGrpCompList(pad5.rest, noBasketSideAlloc.value) IN IF ~basketSideAllocExtGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId              |-> networkMsgId.value,
         pad2                      |-> pad2.value,
         requestHeaderComp         |-> requestHeaderComp.value,
         basketTrdMatchId          |-> basketTrdMatchId.value,
         basketExecId              |-> basketExecId.value,
         marketSegmentId           |-> marketSegmentId.value,
         rootPartySubIdType        |-> rootPartySubIdType.value,
         trdType                   |-> trdType.value,
         tradeReportType           |-> tradeReportType.value,
         basketTradeReportText     |-> basketTradeReportText.value,
         tradeReportId             |-> tradeReportId.value,
         basketSideTradeReportId   |-> basketSideTradeReportId.value,
         pad5                      |-> pad5.value,
         basketSideAllocExtGrpComp |-> basketSideAllocExtGrpComp.value ], basketSideAllocExtGrpComp.rest)

ZeroApproveBasketTradeRequest ==
    [ networkMsgId              |-> [i \in 1 .. 8 |-> 0],
      pad2                      |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp         |-> ZeroRequestHeaderComp5,
      basketTrdMatchId          |-> [i \in 1 .. 8 |-> 0],
      basketExecId              |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId           |-> [i \in 1 .. 4 |-> 0],
      rootPartySubIdType        |-> [i \in 1 .. 2 |-> 0],
      trdType                   |-> [i \in 1 .. 2 |-> 0],
      tradeReportType           |-> [i \in 1 .. 1 |-> 0],
      basketTradeReportText     |-> [i \in 1 .. 20 |-> 0],
      tradeReportId             |-> [i \in 1 .. 20 |-> 0],
      basketSideTradeReportId   |-> [i \in 1 .. 20 |-> 0],
      pad5                      |-> [i \in 1 .. 5 |-> 0],
      basketSideAllocExtGrpComp |-> << >> ]

(* Approve Basket Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedApproveBasketTradeRequest ==
    { ZeroApproveBasketTradeRequest }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp5 }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.basketTrdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.basketExecId = one] : one \in Sample(4) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.rootPartySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.basketTradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.basketSideTradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.pad5 = one] : one \in Sample(5) }
        \cup { [ZeroApproveBasketTradeRequest EXCEPT !.basketSideAllocExtGrpComp = one] : one \in SampleLists(OneBasketSideAllocExtGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp6 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp6(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp6(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp6 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp6 ==
    { ZeroRequestHeaderComp6 }
        \cup { [ZeroRequestHeaderComp6 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp6 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Approve Reverse Tes Trade Request: 66 bytes                             *)
(***************************************************************************)

ApproveReverseTesTradeRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp6,
      marketSegmentId        : Sample(4),
      packageId              : Sample(4),
      allocId                : Sample(4),
      tesExecId              : Sample(4),
      relatedMarketSegmentId : Sample(4),
      trdType                : Sample(2),
      tradeReportId          : Sample(20),
      pad6                   : Sample(6) ]

EncodeApproveReverseTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp6(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.packageId
        \o message.allocId
        \o message.tesExecId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.tradeReportId
        \o message.pad6

DecodeApproveReverseTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp6(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET allocId == ReadBytes(packageId.rest, 4) IN IF ~allocId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(allocId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(trdType.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(tradeReportId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         marketSegmentId        |-> marketSegmentId.value,
         packageId              |-> packageId.value,
         allocId                |-> allocId.value,
         tesExecId              |-> tesExecId.value,
         relatedMarketSegmentId |-> relatedMarketSegmentId.value,
         trdType                |-> trdType.value,
         tradeReportId          |-> tradeReportId.value,
         pad6                   |-> pad6.value ], pad6.rest)

ZeroApproveReverseTesTradeRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp6,
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      packageId              |-> [i \in 1 .. 4 |-> 0],
      allocId                |-> [i \in 1 .. 4 |-> 0],
      tesExecId              |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId |-> [i \in 1 .. 4 |-> 0],
      trdType                |-> [i \in 1 .. 2 |-> 0],
      tradeReportId          |-> [i \in 1 .. 20 |-> 0],
      pad6                   |-> [i \in 1 .. 6 |-> 0] ]

(* Approve Reverse Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedApproveReverseTesTradeRequest ==
    { ZeroApproveReverseTesTradeRequest }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp6 }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.allocId = one] : one \in Sample(4) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroApproveReverseTesTradeRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp7 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp7(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp7(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp7 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp7 ==
    { ZeroRequestHeaderComp7 }
        \cup { [ZeroRequestHeaderComp7 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp7 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Approve Tes Trade Request: 250 bytes                                    *)
(***************************************************************************)

ApproveTesTradeRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp7,
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      allocQty                                : Sample(8),
      packageId                               : Sample(4),
      allocId                                 : Sample(4),
      tesExecId                               : Sample(4),
      marketSegmentId                         : Sample(4),
      relatedMarketSegmentId                  : Sample(4),
      trdType                                 : Sample(2),
      tradingCapacity                         : Sample(1),
      tradeReportType                         : Sample(1),
      side                                    : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      orderAttributeRiskReduction             : Sample(1),
      orderOrigination                        : Sample(1),
      tradeReportId                           : Sample(20),
      positionEffect                          : Sample(1),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      account                                 : Sample(2),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      partyIdTakeUpTradingFirm                : Sample(5),
      partyIdPositionAccount                  : Sample(32),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdBeneficiary                      : Sample(9),
      partyIdLocationId                       : Sample(2),
      custOrderHandlingInst                   : Sample(1),
      complianceText                          : Sample(20),
      partyEndClientIdentification            : Sample(20),
      pad4                                    : Sample(4) ]

EncodeApproveTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp7(message.requestHeaderComp)
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.allocQty
        \o message.packageId
        \o message.allocId
        \o message.tesExecId
        \o message.marketSegmentId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.tradingCapacity
        \o message.tradeReportType
        \o message.side
        \o message.orderAttributeLiquidityProvision
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.orderAttributeRiskReduction
        \o message.orderOrigination
        \o message.tradeReportId
        \o message.positionEffect
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.account
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdPositionAccount
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.partyEndClientIdentification
        \o message.pad4

DecodeApproveTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp7(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET allocQty == ReadBytes(executingTrader.rest, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET packageId == ReadBytes(allocQty.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET allocId == ReadBytes(packageId.rest, 4) IN IF ~allocId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(allocId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(marketSegmentId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(trdType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradingCapacity.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET side == ReadBytes(tradeReportType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(side.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET orderAttributeRiskReduction == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~orderAttributeRiskReduction.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(orderAttributeRiskReduction.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(orderOrigination.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(tradeReportId.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(positionEffect.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET account == ReadBytes(partyExecutingTrader.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(account.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(freeText3.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(partyIdTakeUpTradingFirm.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdPositionAccount.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(partyIdBeneficiary.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET partyEndClientIdentification == ReadBytes(complianceText.rest, 20) IN IF ~partyEndClientIdentification.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyEndClientIdentification.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         allocQty                                |-> allocQty.value,
         packageId                               |-> packageId.value,
         allocId                                 |-> allocId.value,
         tesExecId                               |-> tesExecId.value,
         marketSegmentId                         |-> marketSegmentId.value,
         relatedMarketSegmentId                  |-> relatedMarketSegmentId.value,
         trdType                                 |-> trdType.value,
         tradingCapacity                         |-> tradingCapacity.value,
         tradeReportType                         |-> tradeReportType.value,
         side                                    |-> side.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         orderAttributeRiskReduction             |-> orderAttributeRiskReduction.value,
         orderOrigination                        |-> orderOrigination.value,
         tradeReportId                           |-> tradeReportId.value,
         positionEffect                          |-> positionEffect.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         account                                 |-> account.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         complianceText                          |-> complianceText.value,
         partyEndClientIdentification            |-> partyEndClientIdentification.value,
         pad4                                    |-> pad4.value ], pad4.rest)

ZeroApproveTesTradeRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp7,
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      allocQty                                |-> [i \in 1 .. 8 |-> 0],
      packageId                               |-> [i \in 1 .. 4 |-> 0],
      allocId                                 |-> [i \in 1 .. 4 |-> 0],
      tesExecId                               |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId                  |-> [i \in 1 .. 4 |-> 0],
      trdType                                 |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      tradeReportType                         |-> [i \in 1 .. 1 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      orderAttributeRiskReduction             |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      tradeReportId                           |-> [i \in 1 .. 20 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      partyEndClientIdentification            |-> [i \in 1 .. 20 |-> 0],
      pad4                                    |-> [i \in 1 .. 4 |-> 0] ]

(* Approve Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedApproveTesTradeRequest ==
    { ZeroApproveTesTradeRequest }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp7 }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.allocId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.orderAttributeRiskReduction = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyEndClientIdentification = one] : one \in Sample(20) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp8 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp8(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp8(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp8 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp8 ==
    { ZeroRequestHeaderComp8 }
        \cup { [ZeroRequestHeaderComp8 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp8 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Old Basket Data Grp Comp: 64 bytes                                      *)
(***************************************************************************)

OldBasketDataGrpComp ==
    [ basketTrdMatchId      : Sample(8),
      basketExecId          : Sample(4),
      tradeReportId         : Sample(20),
      maturityMonthYear     : Sample(4),
      basketTradeReportType : Sample(1),
      basketTradeReportText : Sample(20),
      pad7                  : Sample(7) ]

EncodeOldBasketDataGrpComp(message) ==
    message.basketTrdMatchId
        \o message.basketExecId
        \o message.tradeReportId
        \o message.maturityMonthYear
        \o message.basketTradeReportType
        \o message.basketTradeReportText
        \o message.pad7

DecodeOldBasketDataGrpComp(bytes) ==
    LET basketTrdMatchId == ReadBytes(bytes, 8) IN IF ~basketTrdMatchId.ok THEN Fail ELSE
    LET basketExecId == ReadBytes(basketTrdMatchId.rest, 4) IN IF ~basketExecId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(basketExecId.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(tradeReportId.rest, 4) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET basketTradeReportType == ReadBytes(maturityMonthYear.rest, 1) IN IF ~basketTradeReportType.ok THEN Fail ELSE
    LET basketTradeReportText == ReadBytes(basketTradeReportType.rest, 20) IN IF ~basketTradeReportText.ok THEN Fail ELSE
    LET pad7 == ReadBytes(basketTradeReportText.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ basketTrdMatchId      |-> basketTrdMatchId.value,
         basketExecId          |-> basketExecId.value,
         tradeReportId         |-> tradeReportId.value,
         maturityMonthYear     |-> maturityMonthYear.value,
         basketTradeReportType |-> basketTradeReportType.value,
         basketTradeReportText |-> basketTradeReportText.value,
         pad7                  |-> pad7.value ], pad7.rest)

ZeroOldBasketDataGrpComp ==
    [ basketTrdMatchId      |-> [i \in 1 .. 8 |-> 0],
      basketExecId          |-> [i \in 1 .. 4 |-> 0],
      tradeReportId         |-> [i \in 1 .. 20 |-> 0],
      maturityMonthYear     |-> [i \in 1 .. 4 |-> 0],
      basketTradeReportType |-> [i \in 1 .. 1 |-> 0],
      basketTradeReportText |-> [i \in 1 .. 20 |-> 0],
      pad7                  |-> [i \in 1 .. 7 |-> 0] ]

(* Old Basket Data Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedOldBasketDataGrpComp ==
    { ZeroOldBasketDataGrpComp }
        \cup { [ZeroOldBasketDataGrpComp EXCEPT !.basketTrdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroOldBasketDataGrpComp EXCEPT !.basketExecId = one] : one \in Sample(4) }
        \cup { [ZeroOldBasketDataGrpComp EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroOldBasketDataGrpComp EXCEPT !.maturityMonthYear = one] : one \in Sample(4) }
        \cup { [ZeroOldBasketDataGrpComp EXCEPT !.basketTradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketDataGrpComp EXCEPT !.basketTradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroOldBasketDataGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* New Basket Data Grp Comp: 48 bytes                                      *)
(***************************************************************************)

NewBasketDataGrpComp ==
    [ tradeReportId         : Sample(20),
      maturityMonthYear     : Sample(4),
      basketTradeReportType : Sample(1),
      basketTradeReportText : Sample(20),
      pad3                  : Sample(3) ]

EncodeNewBasketDataGrpComp(message) ==
    message.tradeReportId
        \o message.maturityMonthYear
        \o message.basketTradeReportType
        \o message.basketTradeReportText
        \o message.pad3

DecodeNewBasketDataGrpComp(bytes) ==
    LET tradeReportId == ReadBytes(bytes, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(tradeReportId.rest, 4) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET basketTradeReportType == ReadBytes(maturityMonthYear.rest, 1) IN IF ~basketTradeReportType.ok THEN Fail ELSE
    LET basketTradeReportText == ReadBytes(basketTradeReportType.rest, 20) IN IF ~basketTradeReportText.ok THEN Fail ELSE
    LET pad3 == ReadBytes(basketTradeReportText.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ tradeReportId         |-> tradeReportId.value,
         maturityMonthYear     |-> maturityMonthYear.value,
         basketTradeReportType |-> basketTradeReportType.value,
         basketTradeReportText |-> basketTradeReportText.value,
         pad3                  |-> pad3.value ], pad3.rest)

ZeroNewBasketDataGrpComp ==
    [ tradeReportId         |-> [i \in 1 .. 20 |-> 0],
      maturityMonthYear     |-> [i \in 1 .. 4 |-> 0],
      basketTradeReportType |-> [i \in 1 .. 1 |-> 0],
      basketTradeReportText |-> [i \in 1 .. 20 |-> 0],
      pad3                  |-> [i \in 1 .. 3 |-> 0] ]

(* New Basket Data Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNewBasketDataGrpComp ==
    { ZeroNewBasketDataGrpComp }
        \cup { [ZeroNewBasketDataGrpComp EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroNewBasketDataGrpComp EXCEPT !.maturityMonthYear = one] : one \in Sample(4) }
        \cup { [ZeroNewBasketDataGrpComp EXCEPT !.basketTradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketDataGrpComp EXCEPT !.basketTradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroNewBasketDataGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Basket Root Party Grp Comp: 40 bytes                                    *)
(***************************************************************************)

BasketRootPartyGrpComp2 ==
    [ rootPartySubIdType      : Sample(2),
      rootPartyContraFirm     : Sample(5),
      rootPartyContraTrader   : Sample(6),
      basketSideTradeReportId : Sample(20),
      pad7                    : Sample(7) ]

EncodeBasketRootPartyGrpComp2(message) ==
    message.rootPartySubIdType
        \o message.rootPartyContraFirm
        \o message.rootPartyContraTrader
        \o message.basketSideTradeReportId
        \o message.pad7

DecodeBasketRootPartyGrpComp2(bytes) ==
    LET rootPartySubIdType == ReadBytes(bytes, 2) IN IF ~rootPartySubIdType.ok THEN Fail ELSE
    LET rootPartyContraFirm == ReadBytes(rootPartySubIdType.rest, 5) IN IF ~rootPartyContraFirm.ok THEN Fail ELSE
    LET rootPartyContraTrader == ReadBytes(rootPartyContraFirm.rest, 6) IN IF ~rootPartyContraTrader.ok THEN Fail ELSE
    LET basketSideTradeReportId == ReadBytes(rootPartyContraTrader.rest, 20) IN IF ~basketSideTradeReportId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(basketSideTradeReportId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ rootPartySubIdType      |-> rootPartySubIdType.value,
         rootPartyContraFirm     |-> rootPartyContraFirm.value,
         rootPartyContraTrader   |-> rootPartyContraTrader.value,
         basketSideTradeReportId |-> basketSideTradeReportId.value,
         pad7                    |-> pad7.value ], pad7.rest)

ZeroBasketRootPartyGrpComp2 ==
    [ rootPartySubIdType      |-> [i \in 1 .. 2 |-> 0],
      rootPartyContraFirm     |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraTrader   |-> [i \in 1 .. 6 |-> 0],
      basketSideTradeReportId |-> [i \in 1 .. 20 |-> 0],
      pad7                    |-> [i \in 1 .. 7 |-> 0] ]

(* Basket Root Party Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedBasketRootPartyGrpComp2 ==
    { ZeroBasketRootPartyGrpComp2 }
        \cup { [ZeroBasketRootPartyGrpComp2 EXCEPT !.rootPartySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroBasketRootPartyGrpComp2 EXCEPT !.rootPartyContraFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketRootPartyGrpComp2 EXCEPT !.rootPartyContraTrader = one] : one \in Sample(6) }
        \cup { [ZeroBasketRootPartyGrpComp2 EXCEPT !.basketSideTradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroBasketRootPartyGrpComp2 EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Basket Root Party Grp Comp, written one after another *)
RECURSIVE EncodeBasketRootPartyGrpComp2List(_)
EncodeBasketRootPartyGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBasketRootPartyGrpComp2(Head(messages)) \o EncodeBasketRootPartyGrpComp2List(Tail(messages))

(* As many Basket Root Party Grp Comp as the field that counts them says *)
RECURSIVE ReadBasketRootPartyGrpComp2List(_, _)
ReadBasketRootPartyGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBasketRootPartyGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBasketRootPartyGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Basket Root Party Grp Comp of each kind, for the lists that carry them *)
OneBasketRootPartyGrpComp2 == { ZeroBasketRootPartyGrpComp2 }

(***************************************************************************)
(* Old Basket Instrmt Match Side Grp Comp: 80 bytes                        *)
(***************************************************************************)

OldBasketInstrmtMatchSideGrpComp ==
    [ securityId            : Sample(8),
      lastPx                : Sample(8),
      transBkdTime          : Sample(8),
      relatedClosePrice     : Sample(8),
      clearingTradePrice    : Sample(8),
      packageId             : Sample(4),
      sideMarketSegmentId   : Sample(4),
      sideTrdSubTyp         : Sample(2),
      productComplex        : Sample(1),
      tradePublishIndicator : Sample(1),
      instrmtMatchSideId    : Sample(1),
      effectOnBasket        : Sample(1),
      tradeReportText       : Sample(20),
      pad6                  : Sample(6) ]

EncodeOldBasketInstrmtMatchSideGrpComp(message) ==
    message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.relatedClosePrice
        \o message.clearingTradePrice
        \o message.packageId
        \o message.sideMarketSegmentId
        \o message.sideTrdSubTyp
        \o message.productComplex
        \o message.tradePublishIndicator
        \o message.instrmtMatchSideId
        \o message.effectOnBasket
        \o message.tradeReportText
        \o message.pad6

DecodeOldBasketInstrmtMatchSideGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(transBkdTime.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET clearingTradePrice == ReadBytes(relatedClosePrice.rest, 8) IN IF ~clearingTradePrice.ok THEN Fail ELSE
    LET packageId == ReadBytes(clearingTradePrice.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET sideMarketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~sideMarketSegmentId.ok THEN Fail ELSE
    LET sideTrdSubTyp == ReadBytes(sideMarketSegmentId.rest, 2) IN IF ~sideTrdSubTyp.ok THEN Fail ELSE
    LET productComplex == ReadBytes(sideTrdSubTyp.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(productComplex.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(tradePublishIndicator.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET effectOnBasket == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~effectOnBasket.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(effectOnBasket.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET pad6 == ReadBytes(tradeReportText.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         lastPx                |-> lastPx.value,
         transBkdTime          |-> transBkdTime.value,
         relatedClosePrice     |-> relatedClosePrice.value,
         clearingTradePrice    |-> clearingTradePrice.value,
         packageId             |-> packageId.value,
         sideMarketSegmentId   |-> sideMarketSegmentId.value,
         sideTrdSubTyp         |-> sideTrdSubTyp.value,
         productComplex        |-> productComplex.value,
         tradePublishIndicator |-> tradePublishIndicator.value,
         instrmtMatchSideId    |-> instrmtMatchSideId.value,
         effectOnBasket        |-> effectOnBasket.value,
         tradeReportText       |-> tradeReportText.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroOldBasketInstrmtMatchSideGrpComp ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      transBkdTime          |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice     |-> [i \in 1 .. 8 |-> 0],
      clearingTradePrice    |-> [i \in 1 .. 8 |-> 0],
      packageId             |-> [i \in 1 .. 4 |-> 0],
      sideMarketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      sideTrdSubTyp         |-> [i \in 1 .. 2 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId    |-> [i \in 1 .. 1 |-> 0],
      effectOnBasket        |-> [i \in 1 .. 1 |-> 0],
      tradeReportText       |-> [i \in 1 .. 20 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Old Basket Instrmt Match Side Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedOldBasketInstrmtMatchSideGrpComp ==
    { ZeroOldBasketInstrmtMatchSideGrpComp }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.clearingTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.sideMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.sideTrdSubTyp = one] : one \in Sample(2) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.effectOnBasket = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroOldBasketInstrmtMatchSideGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Old Basket Instrmt Match Side Grp Comp, written one after another *)
RECURSIVE EncodeOldBasketInstrmtMatchSideGrpCompList(_)
EncodeOldBasketInstrmtMatchSideGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOldBasketInstrmtMatchSideGrpComp(Head(messages)) \o EncodeOldBasketInstrmtMatchSideGrpCompList(Tail(messages))

(* As many Old Basket Instrmt Match Side Grp Comp as the field that counts them says *)
RECURSIVE ReadOldBasketInstrmtMatchSideGrpCompList(_, _)
ReadOldBasketInstrmtMatchSideGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOldBasketInstrmtMatchSideGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOldBasketInstrmtMatchSideGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Old Basket Instrmt Match Side Grp Comp of each kind, for the lists that carry them *)
OneOldBasketInstrmtMatchSideGrpComp == { ZeroOldBasketInstrmtMatchSideGrpComp }

(***************************************************************************)
(* New Basket Instrmt Match Side Grp Comp: 80 bytes                        *)
(***************************************************************************)

NewBasketInstrmtMatchSideGrpComp ==
    [ securityId            : Sample(8),
      lastPx                : Sample(8),
      transBkdTime          : Sample(8),
      relatedClosePrice     : Sample(8),
      clearingTradePrice    : Sample(8),
      packageId             : Sample(4),
      sideMarketSegmentId   : Sample(4),
      sideTrdSubTyp         : Sample(2),
      productComplex        : Sample(1),
      tradePublishIndicator : Sample(1),
      instrmtMatchSideId    : Sample(1),
      effectOnBasket        : Sample(1),
      tradeReportText       : Sample(20),
      pad6                  : Sample(6) ]

EncodeNewBasketInstrmtMatchSideGrpComp(message) ==
    message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.relatedClosePrice
        \o message.clearingTradePrice
        \o message.packageId
        \o message.sideMarketSegmentId
        \o message.sideTrdSubTyp
        \o message.productComplex
        \o message.tradePublishIndicator
        \o message.instrmtMatchSideId
        \o message.effectOnBasket
        \o message.tradeReportText
        \o message.pad6

DecodeNewBasketInstrmtMatchSideGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(transBkdTime.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET clearingTradePrice == ReadBytes(relatedClosePrice.rest, 8) IN IF ~clearingTradePrice.ok THEN Fail ELSE
    LET packageId == ReadBytes(clearingTradePrice.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET sideMarketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~sideMarketSegmentId.ok THEN Fail ELSE
    LET sideTrdSubTyp == ReadBytes(sideMarketSegmentId.rest, 2) IN IF ~sideTrdSubTyp.ok THEN Fail ELSE
    LET productComplex == ReadBytes(sideTrdSubTyp.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(productComplex.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(tradePublishIndicator.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET effectOnBasket == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~effectOnBasket.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(effectOnBasket.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET pad6 == ReadBytes(tradeReportText.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         lastPx                |-> lastPx.value,
         transBkdTime          |-> transBkdTime.value,
         relatedClosePrice     |-> relatedClosePrice.value,
         clearingTradePrice    |-> clearingTradePrice.value,
         packageId             |-> packageId.value,
         sideMarketSegmentId   |-> sideMarketSegmentId.value,
         sideTrdSubTyp         |-> sideTrdSubTyp.value,
         productComplex        |-> productComplex.value,
         tradePublishIndicator |-> tradePublishIndicator.value,
         instrmtMatchSideId    |-> instrmtMatchSideId.value,
         effectOnBasket        |-> effectOnBasket.value,
         tradeReportText       |-> tradeReportText.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroNewBasketInstrmtMatchSideGrpComp ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      transBkdTime          |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice     |-> [i \in 1 .. 8 |-> 0],
      clearingTradePrice    |-> [i \in 1 .. 8 |-> 0],
      packageId             |-> [i \in 1 .. 4 |-> 0],
      sideMarketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      sideTrdSubTyp         |-> [i \in 1 .. 2 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId    |-> [i \in 1 .. 1 |-> 0],
      effectOnBasket        |-> [i \in 1 .. 1 |-> 0],
      tradeReportText       |-> [i \in 1 .. 20 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* New Basket Instrmt Match Side Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNewBasketInstrmtMatchSideGrpComp ==
    { ZeroNewBasketInstrmtMatchSideGrpComp }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.clearingTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.sideMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.sideTrdSubTyp = one] : one \in Sample(2) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.effectOnBasket = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroNewBasketInstrmtMatchSideGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of New Basket Instrmt Match Side Grp Comp, written one after another *)
RECURSIVE EncodeNewBasketInstrmtMatchSideGrpCompList(_)
EncodeNewBasketInstrmtMatchSideGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewBasketInstrmtMatchSideGrpComp(Head(messages)) \o EncodeNewBasketInstrmtMatchSideGrpCompList(Tail(messages))

(* As many New Basket Instrmt Match Side Grp Comp as the field that counts them says *)
RECURSIVE ReadNewBasketInstrmtMatchSideGrpCompList(_, _)
ReadNewBasketInstrmtMatchSideGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewBasketInstrmtMatchSideGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewBasketInstrmtMatchSideGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Basket Instrmt Match Side Grp Comp of each kind, for the lists that carry them *)
OneNewBasketInstrmtMatchSideGrpComp == { ZeroNewBasketInstrmtMatchSideGrpComp }

(***************************************************************************)
(* Old Basket Side Alloc Grp Comp: 32 bytes                                *)
(***************************************************************************)

OldBasketSideAllocGrpComp ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      partySubIdType       : Sample(2),
      side                 : Sample(1),
      positionEffect       : Sample(1),
      instrmtMatchSideId   : Sample(1),
      tradeAllocStatus     : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad3                 : Sample(3) ]

EncodeOldBasketSideAllocGrpComp(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.partySubIdType
        \o message.side
        \o message.positionEffect
        \o message.instrmtMatchSideId
        \o message.tradeAllocStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad3

DecodeOldBasketSideAllocGrpComp(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET partySubIdType == ReadBytes(individualAllocId.rest, 2) IN IF ~partySubIdType.ok THEN Fail ELSE
    LET side == ReadBytes(partySubIdType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(side.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(positionEffect.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tradeAllocStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad3 == ReadBytes(partyExecutingTrader.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         partySubIdType       |-> partySubIdType.value,
         side                 |-> side.value,
         positionEffect       |-> positionEffect.value,
         instrmtMatchSideId   |-> instrmtMatchSideId.value,
         tradeAllocStatus     |-> tradeAllocStatus.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad3                 |-> pad3.value ], pad3.rest)

ZeroOldBasketSideAllocGrpComp ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      partySubIdType       |-> [i \in 1 .. 2 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      positionEffect       |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId   |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus     |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad3                 |-> [i \in 1 .. 3 |-> 0] ]

(* Old Basket Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedOldBasketSideAllocGrpComp ==
    { ZeroOldBasketSideAllocGrpComp }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.partySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroOldBasketSideAllocGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Old Basket Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeOldBasketSideAllocGrpCompList(_)
EncodeOldBasketSideAllocGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOldBasketSideAllocGrpComp(Head(messages)) \o EncodeOldBasketSideAllocGrpCompList(Tail(messages))

(* As many Old Basket Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadOldBasketSideAllocGrpCompList(_, _)
ReadOldBasketSideAllocGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOldBasketSideAllocGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOldBasketSideAllocGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Old Basket Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneOldBasketSideAllocGrpComp == { ZeroOldBasketSideAllocGrpComp }

(***************************************************************************)
(* New Basket Side Alloc Grp Comp: 32 bytes                                *)
(***************************************************************************)

NewBasketSideAllocGrpComp ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      partySubIdType       : Sample(2),
      side                 : Sample(1),
      positionEffect       : Sample(1),
      instrmtMatchSideId   : Sample(1),
      tradeAllocStatus     : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad3                 : Sample(3) ]

EncodeNewBasketSideAllocGrpComp(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.partySubIdType
        \o message.side
        \o message.positionEffect
        \o message.instrmtMatchSideId
        \o message.tradeAllocStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad3

DecodeNewBasketSideAllocGrpComp(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET partySubIdType == ReadBytes(individualAllocId.rest, 2) IN IF ~partySubIdType.ok THEN Fail ELSE
    LET side == ReadBytes(partySubIdType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(side.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(positionEffect.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tradeAllocStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad3 == ReadBytes(partyExecutingTrader.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         partySubIdType       |-> partySubIdType.value,
         side                 |-> side.value,
         positionEffect       |-> positionEffect.value,
         instrmtMatchSideId   |-> instrmtMatchSideId.value,
         tradeAllocStatus     |-> tradeAllocStatus.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad3                 |-> pad3.value ], pad3.rest)

ZeroNewBasketSideAllocGrpComp ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      partySubIdType       |-> [i \in 1 .. 2 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      positionEffect       |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId   |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus     |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad3                 |-> [i \in 1 .. 3 |-> 0] ]

(* New Basket Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNewBasketSideAllocGrpComp ==
    { ZeroNewBasketSideAllocGrpComp }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.partySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroNewBasketSideAllocGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of New Basket Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeNewBasketSideAllocGrpCompList(_)
EncodeNewBasketSideAllocGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewBasketSideAllocGrpComp(Head(messages)) \o EncodeNewBasketSideAllocGrpCompList(Tail(messages))

(* As many New Basket Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadNewBasketSideAllocGrpCompList(_, _)
ReadNewBasketSideAllocGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewBasketSideAllocGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewBasketSideAllocGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Basket Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneNewBasketSideAllocGrpComp == { ZeroNewBasketSideAllocGrpComp }

(***************************************************************************)
(* Basket Roll Request                                                     *)
(***************************************************************************)

BasketRollRequest ==
    [ networkMsgId                     : Sample(8),
      pad2                             : Sample(2),
      requestHeaderComp                : RequestHeaderComp8,
      marketSegmentId                  : Sample(4),
      basketProfileId                  : Sample(4),
      trdType                          : Sample(2),
      tradeReportType                  : Sample(1),
      tradeReportId                    : Sample(20),
      pad2v2                           : Sample(2),
      oldBasketDataGrpComp             : OldBasketDataGrpComp,
      newBasketDataGrpComp             : NewBasketDataGrpComp,
      basketRootPartyGrpComp           : SampleLists(OneBasketRootPartyGrpComp2),
      oldBasketInstrmtMatchSideGrpComp : SampleLists(OneOldBasketInstrmtMatchSideGrpComp),
      newBasketInstrmtMatchSideGrpComp : SampleLists(OneNewBasketInstrmtMatchSideGrpComp),
      oldBasketSideAllocGrpComp        : SampleLists(OneOldBasketSideAllocGrpComp),
      newBasketSideAllocGrpComp        : SampleLists(OneNewBasketSideAllocGrpComp) ]

EncodeBasketRollRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp8(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.basketProfileId
        \o message.trdType
        \o EncodeUIntLE(Len(message.oldBasketSideAllocGrpComp), 2)
        \o EncodeUIntLE(Len(message.newBasketSideAllocGrpComp), 2)
        \o message.tradeReportType
        \o EncodeUIntBE(Len(message.basketRootPartyGrpComp), 1)
        \o EncodeUIntBE(Len(message.oldBasketInstrmtMatchSideGrpComp), 1)
        \o EncodeUIntBE(Len(message.newBasketInstrmtMatchSideGrpComp), 1)
        \o message.tradeReportId
        \o message.pad2v2
        \o EncodeOldBasketDataGrpComp(message.oldBasketDataGrpComp)
        \o EncodeNewBasketDataGrpComp(message.newBasketDataGrpComp)
        \o EncodeBasketRootPartyGrpComp2List(message.basketRootPartyGrpComp)
        \o EncodeOldBasketInstrmtMatchSideGrpCompList(message.oldBasketInstrmtMatchSideGrpComp)
        \o EncodeNewBasketInstrmtMatchSideGrpCompList(message.newBasketInstrmtMatchSideGrpComp)
        \o EncodeOldBasketSideAllocGrpCompList(message.oldBasketSideAllocGrpComp)
        \o EncodeNewBasketSideAllocGrpCompList(message.newBasketSideAllocGrpComp)

DecodeBasketRollRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp8(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET basketProfileId == ReadBytes(marketSegmentId.rest, 4) IN IF ~basketProfileId.ok THEN Fail ELSE
    LET trdType == ReadBytes(basketProfileId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET noOldBasketSideAlloc == ReadUIntLE(trdType.rest, 2) IN IF ~noOldBasketSideAlloc.ok THEN Fail ELSE
    LET noNewBasketSideAlloc == ReadUIntLE(noOldBasketSideAlloc.rest, 2) IN IF ~noNewBasketSideAlloc.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(noNewBasketSideAlloc.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET noBasketRootPartyGrps == ReadUIntBE(tradeReportType.rest, 1) IN IF ~noBasketRootPartyGrps.ok THEN Fail ELSE
    LET noOldBasketInstrmtMatchSides == ReadUIntBE(noBasketRootPartyGrps.rest, 1) IN IF ~noOldBasketInstrmtMatchSides.ok THEN Fail ELSE
    LET noNewBasketInstrmtMatchSides == ReadUIntBE(noOldBasketInstrmtMatchSides.rest, 1) IN IF ~noNewBasketInstrmtMatchSides.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(noNewBasketInstrmtMatchSides.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(tradeReportId.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET oldBasketDataGrpComp == DecodeOldBasketDataGrpComp(pad2v2.rest) IN IF ~oldBasketDataGrpComp.ok THEN Fail ELSE
    LET newBasketDataGrpComp == DecodeNewBasketDataGrpComp(oldBasketDataGrpComp.rest) IN IF ~newBasketDataGrpComp.ok THEN Fail ELSE
    LET basketRootPartyGrpComp == ReadBasketRootPartyGrpComp2List(newBasketDataGrpComp.rest, noBasketRootPartyGrps.value) IN IF ~basketRootPartyGrpComp.ok THEN Fail ELSE
    LET oldBasketInstrmtMatchSideGrpComp == ReadOldBasketInstrmtMatchSideGrpCompList(basketRootPartyGrpComp.rest, noOldBasketInstrmtMatchSides.value) IN IF ~oldBasketInstrmtMatchSideGrpComp.ok THEN Fail ELSE
    LET newBasketInstrmtMatchSideGrpComp == ReadNewBasketInstrmtMatchSideGrpCompList(oldBasketInstrmtMatchSideGrpComp.rest, noNewBasketInstrmtMatchSides.value) IN IF ~newBasketInstrmtMatchSideGrpComp.ok THEN Fail ELSE
    LET oldBasketSideAllocGrpComp == ReadOldBasketSideAllocGrpCompList(newBasketInstrmtMatchSideGrpComp.rest, noOldBasketSideAlloc.value) IN IF ~oldBasketSideAllocGrpComp.ok THEN Fail ELSE
    LET newBasketSideAllocGrpComp == ReadNewBasketSideAllocGrpCompList(oldBasketSideAllocGrpComp.rest, noNewBasketSideAlloc.value) IN IF ~newBasketSideAllocGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                     |-> networkMsgId.value,
         pad2                             |-> pad2.value,
         requestHeaderComp                |-> requestHeaderComp.value,
         marketSegmentId                  |-> marketSegmentId.value,
         basketProfileId                  |-> basketProfileId.value,
         trdType                          |-> trdType.value,
         tradeReportType                  |-> tradeReportType.value,
         tradeReportId                    |-> tradeReportId.value,
         pad2v2                           |-> pad2v2.value,
         oldBasketDataGrpComp             |-> oldBasketDataGrpComp.value,
         newBasketDataGrpComp             |-> newBasketDataGrpComp.value,
         basketRootPartyGrpComp           |-> basketRootPartyGrpComp.value,
         oldBasketInstrmtMatchSideGrpComp |-> oldBasketInstrmtMatchSideGrpComp.value,
         newBasketInstrmtMatchSideGrpComp |-> newBasketInstrmtMatchSideGrpComp.value,
         oldBasketSideAllocGrpComp        |-> oldBasketSideAllocGrpComp.value,
         newBasketSideAllocGrpComp        |-> newBasketSideAllocGrpComp.value ], newBasketSideAllocGrpComp.rest)

ZeroBasketRollRequest ==
    [ networkMsgId                     |-> [i \in 1 .. 8 |-> 0],
      pad2                             |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                |-> ZeroRequestHeaderComp8,
      marketSegmentId                  |-> [i \in 1 .. 4 |-> 0],
      basketProfileId                  |-> [i \in 1 .. 4 |-> 0],
      trdType                          |-> [i \in 1 .. 2 |-> 0],
      tradeReportType                  |-> [i \in 1 .. 1 |-> 0],
      tradeReportId                    |-> [i \in 1 .. 20 |-> 0],
      pad2v2                           |-> [i \in 1 .. 2 |-> 0],
      oldBasketDataGrpComp             |-> ZeroOldBasketDataGrpComp,
      newBasketDataGrpComp             |-> ZeroNewBasketDataGrpComp,
      basketRootPartyGrpComp           |-> << >>,
      oldBasketInstrmtMatchSideGrpComp |-> << >>,
      newBasketInstrmtMatchSideGrpComp |-> << >>,
      oldBasketSideAllocGrpComp        |-> << >>,
      newBasketSideAllocGrpComp        |-> << >> ]

(* Basket Roll Request at zero, then each field in turn at the values it is checked at *)
CheckedBasketRollRequest ==
    { ZeroBasketRollRequest }
        \cup { [ZeroBasketRollRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroBasketRollRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroBasketRollRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp8 }
        \cup { [ZeroBasketRollRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroBasketRollRequest EXCEPT !.basketProfileId = one] : one \in Sample(4) }
        \cup { [ZeroBasketRollRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroBasketRollRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroBasketRollRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroBasketRollRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroBasketRollRequest EXCEPT !.oldBasketDataGrpComp = one] : one \in CheckedOldBasketDataGrpComp }
        \cup { [ZeroBasketRollRequest EXCEPT !.newBasketDataGrpComp = one] : one \in CheckedNewBasketDataGrpComp }
        \cup { [ZeroBasketRollRequest EXCEPT !.basketRootPartyGrpComp = one] : one \in SampleLists(OneBasketRootPartyGrpComp2) }
        \cup { [ZeroBasketRollRequest EXCEPT !.oldBasketInstrmtMatchSideGrpComp = one] : one \in SampleLists(OneOldBasketInstrmtMatchSideGrpComp) }
        \cup { [ZeroBasketRollRequest EXCEPT !.newBasketInstrmtMatchSideGrpComp = one] : one \in SampleLists(OneNewBasketInstrmtMatchSideGrpComp) }
        \cup { [ZeroBasketRollRequest EXCEPT !.oldBasketSideAllocGrpComp = one] : one \in SampleLists(OneOldBasketSideAllocGrpComp) }
        \cup { [ZeroBasketRollRequest EXCEPT !.newBasketSideAllocGrpComp = one] : one \in SampleLists(OneNewBasketSideAllocGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp9 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp9(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp9(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp9 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp9 ==
    { ZeroRequestHeaderComp9 }
        \cup { [ZeroRequestHeaderComp9 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp9 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Cross Request: 58 bytes                                                 *)
(***************************************************************************)

CrossRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp9,
      securityId        : Sample(8),
      orderQty          : Sample(8),
      marketSegmentId   : Sample(4),
      complianceText    : Sample(20) ]

EncodeCrossRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp9(message.requestHeaderComp)
        \o message.securityId
        \o message.orderQty
        \o message.marketSegmentId
        \o message.complianceText

DecodeCrossRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp9(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET complianceText == ReadBytes(marketSegmentId.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         securityId        |-> securityId.value,
         orderQty          |-> orderQty.value,
         marketSegmentId   |-> marketSegmentId.value,
         complianceText    |-> complianceText.value ], complianceText.rest)

ZeroCrossRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp9,
      securityId        |-> [i \in 1 .. 8 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      complianceText    |-> [i \in 1 .. 20 |-> 0] ]

(* Cross Request at zero, then each field in turn at the values it is checked at *)
CheckedCrossRequest ==
    { ZeroCrossRequest }
        \cup { [ZeroCrossRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroCrossRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp9 }
        \cup { [ZeroCrossRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroCrossRequest EXCEPT !.complianceText = one] : one \in Sample(20) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp10 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp10(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp10(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp10 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp10 ==
    { ZeroRequestHeaderComp10 }
        \cup { [ZeroRequestHeaderComp10 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp10 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete All Order Request: 66 bytes                                      *)
(***************************************************************************)

DeleteAllOrderRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp10,
      securityId                              : Sample(8),
      price                                   : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      targetPartyIdExecutingTrader            : Sample(4),
      side                                    : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1) ]

EncodeDeleteAllOrderRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp10(message.requestHeaderComp)
        \o message.securityId
        \o message.price
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.targetPartyIdExecutingTrader
        \o message.side
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier

DecodeDeleteAllOrderRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp10(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(price.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET targetPartyIdExecutingTrader == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET side == ReadBytes(targetPartyIdExecutingTrader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(side.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         securityId                              |-> securityId.value,
         price                                   |-> price.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         targetPartyIdExecutingTrader            |-> targetPartyIdExecutingTrader.value,
         side                                    |-> side.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value ], executingTraderQualifier.rest)

ZeroDeleteAllOrderRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp10,
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingTrader            |-> [i \in 1 .. 4 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0] ]

(* Delete All Order Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderRequest ==
    { ZeroDeleteAllOrderRequest }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp10 }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp11 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp11(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp11(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp11 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp11 ==
    { ZeroRequestHeaderComp11 }
        \cup { [ZeroRequestHeaderComp11 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp11 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete All Quote Request: 50 bytes                                      *)
(***************************************************************************)

DeleteAllQuoteRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp11,
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      pad6                                    : Sample(6) ]

EncodeDeleteAllQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp11(message.requestHeaderComp)
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.pad6

DecodeDeleteAllQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp11(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(requestHeaderComp.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET pad6 == ReadBytes(executingTraderQualifier.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         pad6                                    |-> pad6.value ], pad6.rest)

ZeroDeleteAllQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp11,
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      pad6                                    |-> [i \in 1 .. 6 |-> 0] ]

(* Delete All Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllQuoteRequest ==
    { ZeroDeleteAllQuoteRequest }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp11 }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp12 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp12(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp12(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp12 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp12 ==
    { ZeroRequestHeaderComp12 }
        \cup { [ZeroRequestHeaderComp12 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp12 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Basket Trade Request: 58 bytes                                   *)
(***************************************************************************)

DeleteBasketTradeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp12,
      basketTrdMatchId  : Sample(8),
      basketExecId      : Sample(4),
      marketSegmentId   : Sample(4),
      trdType           : Sample(2),
      tradeReportType   : Sample(1),
      tradeReportId     : Sample(20),
      pad1              : Sample(1) ]

EncodeDeleteBasketTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp12(message.requestHeaderComp)
        \o message.basketTrdMatchId
        \o message.basketExecId
        \o message.marketSegmentId
        \o message.trdType
        \o message.tradeReportType
        \o message.tradeReportId
        \o message.pad1

DecodeDeleteBasketTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp12(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET basketTrdMatchId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~basketTrdMatchId.ok THEN Fail ELSE
    LET basketExecId == ReadBytes(basketTrdMatchId.rest, 4) IN IF ~basketExecId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(basketExecId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(marketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportType.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(tradeReportId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         basketTrdMatchId  |-> basketTrdMatchId.value,
         basketExecId      |-> basketExecId.value,
         marketSegmentId   |-> marketSegmentId.value,
         trdType           |-> trdType.value,
         tradeReportType   |-> tradeReportType.value,
         tradeReportId     |-> tradeReportId.value,
         pad1              |-> pad1.value ], pad1.rest)

ZeroDeleteBasketTradeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp12,
      basketTrdMatchId  |-> [i \in 1 .. 8 |-> 0],
      basketExecId      |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      trdType           |-> [i \in 1 .. 2 |-> 0],
      tradeReportType   |-> [i \in 1 .. 1 |-> 0],
      tradeReportId     |-> [i \in 1 .. 20 |-> 0],
      pad1              |-> [i \in 1 .. 1 |-> 0] ]

(* Delete Basket Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteBasketTradeRequest ==
    { ZeroDeleteBasketTradeRequest }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp12 }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.basketTrdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.basketExecId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteBasketTradeRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp13 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp13(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp13(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp13 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp13 ==
    { ZeroRequestHeaderComp13 }
        \cup { [ZeroRequestHeaderComp13 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp13 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Clip Request: 74 bytes                                           *)
(***************************************************************************)

DeleteClipRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp13,
      clOrdId                                 : Sample(8),
      orderId                                 : Sample(8),
      securityId                              : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      crossRequestId                          : Sample(4),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      pad6                                    : Sample(6) ]

EncodeDeleteClipRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp13(message.requestHeaderComp)
        \o message.clOrdId
        \o message.orderId
        \o message.securityId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.crossRequestId
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.pad6

DecodeDeleteClipRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp13(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clOrdId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(orderId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(securityId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET crossRequestId == ReadBytes(marketSegmentId.rest, 4) IN IF ~crossRequestId.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(crossRequestId.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         clOrdId                                 |-> clOrdId.value,
         orderId                                 |-> orderId.value,
         securityId                              |-> securityId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         crossRequestId                          |-> crossRequestId.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         pad6                                    |-> pad6.value ], pad6.rest)

ZeroDeleteClipRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp13,
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      orderId                                 |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      crossRequestId                          |-> [i \in 1 .. 4 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      pad6                                    |-> [i \in 1 .. 6 |-> 0] ]

(* Delete Clip Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteClipRequest ==
    { ZeroDeleteClipRequest }
        \cup { [ZeroDeleteClipRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp13 }
        \cup { [ZeroDeleteClipRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.crossRequestId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteClipRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp14 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp14(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp14(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp14 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp14 ==
    { ZeroRequestHeaderComp14 }
        \cup { [ZeroRequestHeaderComp14 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp14 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Order Request: 122 bytes                                         *)
(***************************************************************************)

DeleteOrderRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp14,
      orderId                                 : Sample(8),
      clOrdId                                 : Sample(8),
      origClOrdId                             : Sample(8),
      securityId                              : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      fixClOrdId                              : Sample(20),
      complianceText                          : Sample(20),
      pad5                                    : Sample(5) ]

EncodeDeleteOrderRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp14(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.fixClOrdId
        \o message.complianceText
        \o message.pad5

DecodeDeleteOrderRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp14(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(securityId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(executingTraderQualifier.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET complianceText == ReadBytes(fixClOrdId.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad5 == ReadBytes(complianceText.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         orderId                                 |-> orderId.value,
         clOrdId                                 |-> clOrdId.value,
         origClOrdId                             |-> origClOrdId.value,
         securityId                              |-> securityId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         fixClOrdId                              |-> fixClOrdId.value,
         complianceText                          |-> complianceText.value,
         pad5                                    |-> pad5.value ], pad5.rest)

ZeroDeleteOrderRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp14,
      orderId                                 |-> [i \in 1 .. 8 |-> 0],
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                             |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      fixClOrdId                              |-> [i \in 1 .. 20 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      pad5                                    |-> [i \in 1 .. 5 |-> 0] ]

(* Delete Order Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderRequest ==
    { ZeroDeleteOrderRequest }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp14 }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroDeleteOrderRequest EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp15 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp15(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp15(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp15 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp15 ==
    { ZeroRequestHeaderComp15 }
        \cup { [ZeroRequestHeaderComp15 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp15 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Tes Trade Request: 58 bytes                                      *)
(***************************************************************************)

DeleteTesTradeRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp15,
      packageId              : Sample(4),
      marketSegmentId        : Sample(4),
      tesExecId              : Sample(4),
      relatedMarketSegmentId : Sample(4),
      trdType                : Sample(2),
      tradeReportType        : Sample(1),
      tradeReportId          : Sample(20),
      pad1                   : Sample(1) ]

EncodeDeleteTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp15(message.requestHeaderComp)
        \o message.packageId
        \o message.marketSegmentId
        \o message.tesExecId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.tradeReportType
        \o message.tradeReportId
        \o message.pad1

DecodeDeleteTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp15(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET packageId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(marketSegmentId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportType.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(tradeReportId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         packageId              |-> packageId.value,
         marketSegmentId        |-> marketSegmentId.value,
         tesExecId              |-> tesExecId.value,
         relatedMarketSegmentId |-> relatedMarketSegmentId.value,
         trdType                |-> trdType.value,
         tradeReportType        |-> tradeReportType.value,
         tradeReportId          |-> tradeReportId.value,
         pad1                   |-> pad1.value ], pad1.rest)

ZeroDeleteTesTradeRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp15,
      packageId              |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      tesExecId              |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId |-> [i \in 1 .. 4 |-> 0],
      trdType                |-> [i \in 1 .. 2 |-> 0],
      tradeReportType        |-> [i \in 1 .. 1 |-> 0],
      tradeReportId          |-> [i \in 1 .. 20 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0] ]

(* Delete Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteTesTradeRequest ==
    { ZeroDeleteTesTradeRequest }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp15 }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp16 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp16(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp16(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp16 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp16 ==
    { ZeroRequestHeaderComp16 }
        \cup { [ZeroRequestHeaderComp16 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp16 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Basket Root Party Grp Comp: 40 bytes                                    *)
(***************************************************************************)

BasketRootPartyGrpComp3 ==
    [ rootPartySubIdType      : Sample(2),
      rootPartyContraFirm     : Sample(5),
      rootPartyContraTrader   : Sample(6),
      basketSideTradeReportId : Sample(20),
      pad7                    : Sample(7) ]

EncodeBasketRootPartyGrpComp3(message) ==
    message.rootPartySubIdType
        \o message.rootPartyContraFirm
        \o message.rootPartyContraTrader
        \o message.basketSideTradeReportId
        \o message.pad7

DecodeBasketRootPartyGrpComp3(bytes) ==
    LET rootPartySubIdType == ReadBytes(bytes, 2) IN IF ~rootPartySubIdType.ok THEN Fail ELSE
    LET rootPartyContraFirm == ReadBytes(rootPartySubIdType.rest, 5) IN IF ~rootPartyContraFirm.ok THEN Fail ELSE
    LET rootPartyContraTrader == ReadBytes(rootPartyContraFirm.rest, 6) IN IF ~rootPartyContraTrader.ok THEN Fail ELSE
    LET basketSideTradeReportId == ReadBytes(rootPartyContraTrader.rest, 20) IN IF ~basketSideTradeReportId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(basketSideTradeReportId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ rootPartySubIdType      |-> rootPartySubIdType.value,
         rootPartyContraFirm     |-> rootPartyContraFirm.value,
         rootPartyContraTrader   |-> rootPartyContraTrader.value,
         basketSideTradeReportId |-> basketSideTradeReportId.value,
         pad7                    |-> pad7.value ], pad7.rest)

ZeroBasketRootPartyGrpComp3 ==
    [ rootPartySubIdType      |-> [i \in 1 .. 2 |-> 0],
      rootPartyContraFirm     |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraTrader   |-> [i \in 1 .. 6 |-> 0],
      basketSideTradeReportId |-> [i \in 1 .. 20 |-> 0],
      pad7                    |-> [i \in 1 .. 7 |-> 0] ]

(* Basket Root Party Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedBasketRootPartyGrpComp3 ==
    { ZeroBasketRootPartyGrpComp3 }
        \cup { [ZeroBasketRootPartyGrpComp3 EXCEPT !.rootPartySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroBasketRootPartyGrpComp3 EXCEPT !.rootPartyContraFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketRootPartyGrpComp3 EXCEPT !.rootPartyContraTrader = one] : one \in Sample(6) }
        \cup { [ZeroBasketRootPartyGrpComp3 EXCEPT !.basketSideTradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroBasketRootPartyGrpComp3 EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Basket Root Party Grp Comp, written one after another *)
RECURSIVE EncodeBasketRootPartyGrpComp3List(_)
EncodeBasketRootPartyGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBasketRootPartyGrpComp3(Head(messages)) \o EncodeBasketRootPartyGrpComp3List(Tail(messages))

(* As many Basket Root Party Grp Comp as the field that counts them says *)
RECURSIVE ReadBasketRootPartyGrpComp3List(_, _)
ReadBasketRootPartyGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBasketRootPartyGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBasketRootPartyGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Basket Root Party Grp Comp of each kind, for the lists that carry them *)
OneBasketRootPartyGrpComp3 == { ZeroBasketRootPartyGrpComp3 }

(***************************************************************************)
(* Instrmt Match Side Grp Comp: 80 bytes                                   *)
(***************************************************************************)

InstrmtMatchSideGrpComp2 ==
    [ securityId            : Sample(8),
      lastPx                : Sample(8),
      transBkdTime          : Sample(8),
      relatedClosePrice     : Sample(8),
      clearingTradePrice    : Sample(8),
      packageId             : Sample(4),
      sideMarketSegmentId   : Sample(4),
      sideTrdSubTyp         : Sample(2),
      productComplex        : Sample(1),
      tradePublishIndicator : Sample(1),
      instrmtMatchSideId    : Sample(1),
      effectOnBasket        : Sample(1),
      tradeReportText       : Sample(20),
      pad6                  : Sample(6) ]

EncodeInstrmtMatchSideGrpComp2(message) ==
    message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.relatedClosePrice
        \o message.clearingTradePrice
        \o message.packageId
        \o message.sideMarketSegmentId
        \o message.sideTrdSubTyp
        \o message.productComplex
        \o message.tradePublishIndicator
        \o message.instrmtMatchSideId
        \o message.effectOnBasket
        \o message.tradeReportText
        \o message.pad6

DecodeInstrmtMatchSideGrpComp2(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(transBkdTime.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET clearingTradePrice == ReadBytes(relatedClosePrice.rest, 8) IN IF ~clearingTradePrice.ok THEN Fail ELSE
    LET packageId == ReadBytes(clearingTradePrice.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET sideMarketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~sideMarketSegmentId.ok THEN Fail ELSE
    LET sideTrdSubTyp == ReadBytes(sideMarketSegmentId.rest, 2) IN IF ~sideTrdSubTyp.ok THEN Fail ELSE
    LET productComplex == ReadBytes(sideTrdSubTyp.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(productComplex.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(tradePublishIndicator.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET effectOnBasket == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~effectOnBasket.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(effectOnBasket.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET pad6 == ReadBytes(tradeReportText.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         lastPx                |-> lastPx.value,
         transBkdTime          |-> transBkdTime.value,
         relatedClosePrice     |-> relatedClosePrice.value,
         clearingTradePrice    |-> clearingTradePrice.value,
         packageId             |-> packageId.value,
         sideMarketSegmentId   |-> sideMarketSegmentId.value,
         sideTrdSubTyp         |-> sideTrdSubTyp.value,
         productComplex        |-> productComplex.value,
         tradePublishIndicator |-> tradePublishIndicator.value,
         instrmtMatchSideId    |-> instrmtMatchSideId.value,
         effectOnBasket        |-> effectOnBasket.value,
         tradeReportText       |-> tradeReportText.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroInstrmtMatchSideGrpComp2 ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      transBkdTime          |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice     |-> [i \in 1 .. 8 |-> 0],
      clearingTradePrice    |-> [i \in 1 .. 8 |-> 0],
      packageId             |-> [i \in 1 .. 4 |-> 0],
      sideMarketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      sideTrdSubTyp         |-> [i \in 1 .. 2 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId    |-> [i \in 1 .. 1 |-> 0],
      effectOnBasket        |-> [i \in 1 .. 1 |-> 0],
      tradeReportText       |-> [i \in 1 .. 20 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmt Match Side Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmtMatchSideGrpComp2 ==
    { ZeroInstrmtMatchSideGrpComp2 }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.clearingTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.sideMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.sideTrdSubTyp = one] : one \in Sample(2) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.effectOnBasket = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroInstrmtMatchSideGrpComp2 EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmt Match Side Grp Comp, written one after another *)
RECURSIVE EncodeInstrmtMatchSideGrpComp2List(_)
EncodeInstrmtMatchSideGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmtMatchSideGrpComp2(Head(messages)) \o EncodeInstrmtMatchSideGrpComp2List(Tail(messages))

(* As many Instrmt Match Side Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmtMatchSideGrpComp2List(_, _)
ReadInstrmtMatchSideGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmtMatchSideGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmtMatchSideGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmt Match Side Grp Comp of each kind, for the lists that carry them *)
OneInstrmtMatchSideGrpComp2 == { ZeroInstrmtMatchSideGrpComp2 }

(***************************************************************************)
(* Basket Side Alloc Grp Comp: 32 bytes                                    *)
(***************************************************************************)

BasketSideAllocGrpComp2 ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      partySubIdType       : Sample(2),
      side                 : Sample(1),
      instrmtMatchSideId   : Sample(1),
      tradeAllocStatus     : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeBasketSideAllocGrpComp2(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.partySubIdType
        \o message.side
        \o message.instrmtMatchSideId
        \o message.tradeAllocStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeBasketSideAllocGrpComp2(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET partySubIdType == ReadBytes(individualAllocId.rest, 2) IN IF ~partySubIdType.ok THEN Fail ELSE
    LET side == ReadBytes(partySubIdType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(side.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tradeAllocStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         partySubIdType       |-> partySubIdType.value,
         side                 |-> side.value,
         instrmtMatchSideId   |-> instrmtMatchSideId.value,
         tradeAllocStatus     |-> tradeAllocStatus.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroBasketSideAllocGrpComp2 ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      partySubIdType       |-> [i \in 1 .. 2 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId   |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus     |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Basket Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedBasketSideAllocGrpComp2 ==
    { ZeroBasketSideAllocGrpComp2 }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.partySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroBasketSideAllocGrpComp2 EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Basket Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeBasketSideAllocGrpComp2List(_)
EncodeBasketSideAllocGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBasketSideAllocGrpComp2(Head(messages)) \o EncodeBasketSideAllocGrpComp2List(Tail(messages))

(* As many Basket Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadBasketSideAllocGrpComp2List(_, _)
ReadBasketSideAllocGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBasketSideAllocGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBasketSideAllocGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Basket Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneBasketSideAllocGrpComp2 == { ZeroBasketSideAllocGrpComp2 }

(***************************************************************************)
(* Enter Basket Trade Request                                              *)
(***************************************************************************)

EnterBasketTradeRequest ==
    [ networkMsgId                      : Sample(8),
      pad2                              : Sample(2),
      requestHeaderComp                 : RequestHeaderComp16,
      marketSegmentId                   : Sample(4),
      maturityMonthYear                 : Sample(4),
      basketProfileId                   : Sample(4),
      trdType                           : Sample(2),
      tradeReportType                   : Sample(1),
      basketTradeReportType             : Sample(1),
      optionalEarlyTerminationIndicator : Sample(1),
      basketAnonymity                   : Sample(1),
      basketTradeReportText             : Sample(20),
      tradeReportId                     : Sample(20),
      pad2v2                            : Sample(2),
      basketRootPartyGrpComp            : SampleLists(OneBasketRootPartyGrpComp3),
      instrmtMatchSideGrpComp           : SampleLists(OneInstrmtMatchSideGrpComp2),
      basketSideAllocGrpComp            : SampleLists(OneBasketSideAllocGrpComp2) ]

EncodeEnterBasketTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp16(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.maturityMonthYear
        \o message.basketProfileId
        \o message.trdType
        \o EncodeUIntLE(Len(message.basketSideAllocGrpComp), 2)
        \o message.tradeReportType
        \o message.basketTradeReportType
        \o message.optionalEarlyTerminationIndicator
        \o EncodeUIntBE(Len(message.basketRootPartyGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrmtMatchSideGrpComp), 1)
        \o message.basketAnonymity
        \o message.basketTradeReportText
        \o message.tradeReportId
        \o message.pad2v2
        \o EncodeBasketRootPartyGrpComp3List(message.basketRootPartyGrpComp)
        \o EncodeInstrmtMatchSideGrpComp2List(message.instrmtMatchSideGrpComp)
        \o EncodeBasketSideAllocGrpComp2List(message.basketSideAllocGrpComp)

DecodeEnterBasketTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp16(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(marketSegmentId.rest, 4) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET basketProfileId == ReadBytes(maturityMonthYear.rest, 4) IN IF ~basketProfileId.ok THEN Fail ELSE
    LET trdType == ReadBytes(basketProfileId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET noBasketSideAlloc == ReadUIntLE(trdType.rest, 2) IN IF ~noBasketSideAlloc.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(noBasketSideAlloc.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET basketTradeReportType == ReadBytes(tradeReportType.rest, 1) IN IF ~basketTradeReportType.ok THEN Fail ELSE
    LET optionalEarlyTerminationIndicator == ReadBytes(basketTradeReportType.rest, 1) IN IF ~optionalEarlyTerminationIndicator.ok THEN Fail ELSE
    LET noBasketRootPartyGrps == ReadUIntBE(optionalEarlyTerminationIndicator.rest, 1) IN IF ~noBasketRootPartyGrps.ok THEN Fail ELSE
    LET noInstrmtMatchSides == ReadUIntBE(noBasketRootPartyGrps.rest, 1) IN IF ~noInstrmtMatchSides.ok THEN Fail ELSE
    LET basketAnonymity == ReadBytes(noInstrmtMatchSides.rest, 1) IN IF ~basketAnonymity.ok THEN Fail ELSE
    LET basketTradeReportText == ReadBytes(basketAnonymity.rest, 20) IN IF ~basketTradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(basketTradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(tradeReportId.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET basketRootPartyGrpComp == ReadBasketRootPartyGrpComp3List(pad2v2.rest, noBasketRootPartyGrps.value) IN IF ~basketRootPartyGrpComp.ok THEN Fail ELSE
    LET instrmtMatchSideGrpComp == ReadInstrmtMatchSideGrpComp2List(basketRootPartyGrpComp.rest, noInstrmtMatchSides.value) IN IF ~instrmtMatchSideGrpComp.ok THEN Fail ELSE
    LET basketSideAllocGrpComp == ReadBasketSideAllocGrpComp2List(instrmtMatchSideGrpComp.rest, noBasketSideAlloc.value) IN IF ~basketSideAllocGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                      |-> networkMsgId.value,
         pad2                              |-> pad2.value,
         requestHeaderComp                 |-> requestHeaderComp.value,
         marketSegmentId                   |-> marketSegmentId.value,
         maturityMonthYear                 |-> maturityMonthYear.value,
         basketProfileId                   |-> basketProfileId.value,
         trdType                           |-> trdType.value,
         tradeReportType                   |-> tradeReportType.value,
         basketTradeReportType             |-> basketTradeReportType.value,
         optionalEarlyTerminationIndicator |-> optionalEarlyTerminationIndicator.value,
         basketAnonymity                   |-> basketAnonymity.value,
         basketTradeReportText             |-> basketTradeReportText.value,
         tradeReportId                     |-> tradeReportId.value,
         pad2v2                            |-> pad2v2.value,
         basketRootPartyGrpComp            |-> basketRootPartyGrpComp.value,
         instrmtMatchSideGrpComp           |-> instrmtMatchSideGrpComp.value,
         basketSideAllocGrpComp            |-> basketSideAllocGrpComp.value ], basketSideAllocGrpComp.rest)

ZeroEnterBasketTradeRequest ==
    [ networkMsgId                      |-> [i \in 1 .. 8 |-> 0],
      pad2                              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                 |-> ZeroRequestHeaderComp16,
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      maturityMonthYear                 |-> [i \in 1 .. 4 |-> 0],
      basketProfileId                   |-> [i \in 1 .. 4 |-> 0],
      trdType                           |-> [i \in 1 .. 2 |-> 0],
      tradeReportType                   |-> [i \in 1 .. 1 |-> 0],
      basketTradeReportType             |-> [i \in 1 .. 1 |-> 0],
      optionalEarlyTerminationIndicator |-> [i \in 1 .. 1 |-> 0],
      basketAnonymity                   |-> [i \in 1 .. 1 |-> 0],
      basketTradeReportText             |-> [i \in 1 .. 20 |-> 0],
      tradeReportId                     |-> [i \in 1 .. 20 |-> 0],
      pad2v2                            |-> [i \in 1 .. 2 |-> 0],
      basketRootPartyGrpComp            |-> << >>,
      instrmtMatchSideGrpComp           |-> << >>,
      basketSideAllocGrpComp            |-> << >> ]

(* Enter Basket Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedEnterBasketTradeRequest ==
    { ZeroEnterBasketTradeRequest }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp16 }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.maturityMonthYear = one] : one \in Sample(4) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.basketProfileId = one] : one \in Sample(4) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.basketTradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.optionalEarlyTerminationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.basketAnonymity = one] : one \in Sample(1) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.basketTradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.basketRootPartyGrpComp = one] : one \in SampleLists(OneBasketRootPartyGrpComp3) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.instrmtMatchSideGrpComp = one] : one \in SampleLists(OneInstrmtMatchSideGrpComp2) }
        \cup { [ZeroEnterBasketTradeRequest EXCEPT !.basketSideAllocGrpComp = one] : one \in SampleLists(OneBasketSideAllocGrpComp2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp17 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp17(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp17(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp17 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp17 ==
    { ZeroRequestHeaderComp17 }
        \cup { [ZeroRequestHeaderComp17 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp17 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Cross Request Side Grp Comp: 192 bytes                                  *)
(***************************************************************************)

CrossRequestSideGrpComp ==
    [ clOrdId                                 : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      maximumPrice                            : Sample(8),
      matchInstCrossId                        : Sample(4),
      inputSource                             : Sample(1),
      side                                    : Sample(1),
      selfMatchPreventionInstruction          : Sample(1),
      crossMatchInstruction                   : Sample(1),
      tradingCapacity                         : Sample(1),
      executingTraderQualifier                : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      orderAttributeRiskReduction             : Sample(1),
      orderOrigination                        : Sample(1),
      positionEffect                          : Sample(1),
      custOrderHandlingInst                   : Sample(1),
      account                                 : Sample(2),
      partyIdPositionAccount                  : Sample(32),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdBeneficiary                      : Sample(9),
      partyIdTakeUpTradingFirm                : Sample(5),
      sideComplianceText                      : Sample(20),
      partyIdLocationId                       : Sample(2),
      partyEndClientIdentification            : Sample(20),
      pad3                                    : Sample(3) ]

EncodeCrossRequestSideGrpComp(message) ==
    message.clOrdId
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.maximumPrice
        \o message.matchInstCrossId
        \o message.inputSource
        \o message.side
        \o message.selfMatchPreventionInstruction
        \o message.crossMatchInstruction
        \o message.tradingCapacity
        \o message.executingTraderQualifier
        \o message.orderAttributeLiquidityProvision
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.orderAttributeRiskReduction
        \o message.orderOrigination
        \o message.positionEffect
        \o message.custOrderHandlingInst
        \o message.account
        \o message.partyIdPositionAccount
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.partyIdTakeUpTradingFirm
        \o message.sideComplianceText
        \o message.partyIdLocationId
        \o message.partyEndClientIdentification
        \o message.pad3

DecodeCrossRequestSideGrpComp(bytes) ==
    LET clOrdId == ReadBytes(bytes, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(clOrdId.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET maximumPrice == ReadBytes(executingTrader.rest, 8) IN IF ~maximumPrice.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(maximumPrice.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET inputSource == ReadBytes(matchInstCrossId.rest, 1) IN IF ~inputSource.ok THEN Fail ELSE
    LET side == ReadBytes(inputSource.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(side.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET crossMatchInstruction == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~crossMatchInstruction.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(crossMatchInstruction.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(tradingCapacity.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET orderAttributeRiskReduction == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~orderAttributeRiskReduction.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(orderAttributeRiskReduction.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(orderOrigination.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(positionEffect.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET account == ReadBytes(custOrderHandlingInst.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(account.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyIdPositionAccount.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(freeText3.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(partyIdBeneficiary.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET sideComplianceText == ReadBytes(partyIdTakeUpTradingFirm.rest, 20) IN IF ~sideComplianceText.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(sideComplianceText.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET partyEndClientIdentification == ReadBytes(partyIdLocationId.rest, 20) IN IF ~partyEndClientIdentification.ok THEN Fail ELSE
    LET pad3 == ReadBytes(partyEndClientIdentification.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ clOrdId                                 |-> clOrdId.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         maximumPrice                            |-> maximumPrice.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         inputSource                             |-> inputSource.value,
         side                                    |-> side.value,
         selfMatchPreventionInstruction          |-> selfMatchPreventionInstruction.value,
         crossMatchInstruction                   |-> crossMatchInstruction.value,
         tradingCapacity                         |-> tradingCapacity.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         orderAttributeRiskReduction             |-> orderAttributeRiskReduction.value,
         orderOrigination                        |-> orderOrigination.value,
         positionEffect                          |-> positionEffect.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         account                                 |-> account.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         sideComplianceText                      |-> sideComplianceText.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         partyEndClientIdentification            |-> partyEndClientIdentification.value,
         pad3                                    |-> pad3.value ], pad3.rest)

ZeroCrossRequestSideGrpComp ==
    [ clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      maximumPrice                            |-> [i \in 1 .. 8 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      inputSource                             |-> [i \in 1 .. 1 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction          |-> [i \in 1 .. 1 |-> 0],
      crossMatchInstruction                   |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      orderAttributeRiskReduction             |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      sideComplianceText                      |-> [i \in 1 .. 20 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      partyEndClientIdentification            |-> [i \in 1 .. 20 |-> 0],
      pad3                                    |-> [i \in 1 .. 3 |-> 0] ]

(* Cross Request Side Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedCrossRequestSideGrpComp ==
    { ZeroCrossRequestSideGrpComp }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.maximumPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.inputSource = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.crossMatchInstruction = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.orderAttributeRiskReduction = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.sideComplianceText = one] : one \in Sample(20) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.partyEndClientIdentification = one] : one \in Sample(20) }
        \cup { [ZeroCrossRequestSideGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Cross Request Side Grp Comp, written one after another *)
RECURSIVE EncodeCrossRequestSideGrpCompList(_)
EncodeCrossRequestSideGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCrossRequestSideGrpComp(Head(messages)) \o EncodeCrossRequestSideGrpCompList(Tail(messages))

(* As many Cross Request Side Grp Comp as the field that counts them says *)
RECURSIVE ReadCrossRequestSideGrpCompList(_, _)
ReadCrossRequestSideGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCrossRequestSideGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCrossRequestSideGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cross Request Side Grp Comp of each kind, for the lists that carry them *)
OneCrossRequestSideGrpComp == { ZeroCrossRequestSideGrpComp }

(***************************************************************************)
(* Side Cross Leg Grp Comp: 8 bytes                                        *)
(***************************************************************************)

SideCrossLegGrpComp ==
    [ legInputSource    : Sample(1),
      legPositionEffect : Sample(1),
      legAccount        : Sample(2),
      pad4              : Sample(4) ]

EncodeSideCrossLegGrpComp(message) ==
    message.legInputSource
        \o message.legPositionEffect
        \o message.legAccount
        \o message.pad4

DecodeSideCrossLegGrpComp(bytes) ==
    LET legInputSource == ReadBytes(bytes, 1) IN IF ~legInputSource.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legInputSource.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    LET legAccount == ReadBytes(legPositionEffect.rest, 2) IN IF ~legAccount.ok THEN Fail ELSE
    LET pad4 == ReadBytes(legAccount.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ legInputSource    |-> legInputSource.value,
         legPositionEffect |-> legPositionEffect.value,
         legAccount        |-> legAccount.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroSideCrossLegGrpComp ==
    [ legInputSource    |-> [i \in 1 .. 1 |-> 0],
      legPositionEffect |-> [i \in 1 .. 1 |-> 0],
      legAccount        |-> [i \in 1 .. 2 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Side Cross Leg Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideCrossLegGrpComp ==
    { ZeroSideCrossLegGrpComp }
        \cup { [ZeroSideCrossLegGrpComp EXCEPT !.legInputSource = one] : one \in Sample(1) }
        \cup { [ZeroSideCrossLegGrpComp EXCEPT !.legPositionEffect = one] : one \in Sample(1) }
        \cup { [ZeroSideCrossLegGrpComp EXCEPT !.legAccount = one] : one \in Sample(2) }
        \cup { [ZeroSideCrossLegGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Side Cross Leg Grp Comp, written one after another *)
RECURSIVE EncodeSideCrossLegGrpCompList(_)
EncodeSideCrossLegGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSideCrossLegGrpComp(Head(messages)) \o EncodeSideCrossLegGrpCompList(Tail(messages))

(* As many Side Cross Leg Grp Comp as the field that counts them says *)
RECURSIVE ReadSideCrossLegGrpCompList(_, _)
ReadSideCrossLegGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSideCrossLegGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSideCrossLegGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Side Cross Leg Grp Comp of each kind, for the lists that carry them *)
OneSideCrossLegGrpComp == { ZeroSideCrossLegGrpComp }

(***************************************************************************)
(* Enter Clip Request                                                      *)
(***************************************************************************)

EnterClipRequest ==
    [ networkMsgId                  : Sample(8),
      pad2                          : Sample(2),
      requestHeaderComp             : RequestHeaderComp17,
      securityId                    : Sample(8),
      price                         : Sample(8),
      orderQty                      : Sample(8),
      marketSegmentId               : Sample(4),
      crossId                       : Sample(4),
      crossRequestId                : Sample(4),
      crossRequestType              : Sample(1),
      crossType                     : Sample(1),
      crossPrioritization           : Sample(1),
      sideDisclosureInstruction     : Sample(1),
      priceDisclosureInstruction    : Sample(1),
      orderQtyDisclosureInstruction : Sample(1),
      priceValidityCheckType        : Sample(1),
      valueCheckTypeValue           : Sample(1),
      rootPartyContraFirm           : Sample(5),
      rootPartyContraTrader         : Sample(6),
      pad7                          : Sample(7),
      crossRequestSideGrpComp       : SampleLists(OneCrossRequestSideGrpComp),
      sideCrossLegGrpComp           : SampleLists(OneSideCrossLegGrpComp) ]

EncodeEnterClipRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp17(message.requestHeaderComp)
        \o message.securityId
        \o message.price
        \o message.orderQty
        \o message.marketSegmentId
        \o message.crossId
        \o message.crossRequestId
        \o EncodeUIntBE(Len(message.crossRequestSideGrpComp), 1)
        \o EncodeUIntBE(Len(message.sideCrossLegGrpComp), 1)
        \o message.crossRequestType
        \o message.crossType
        \o message.crossPrioritization
        \o message.sideDisclosureInstruction
        \o message.priceDisclosureInstruction
        \o message.orderQtyDisclosureInstruction
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.rootPartyContraFirm
        \o message.rootPartyContraTrader
        \o message.pad7
        \o EncodeCrossRequestSideGrpCompList(message.crossRequestSideGrpComp)
        \o EncodeSideCrossLegGrpCompList(message.sideCrossLegGrpComp)

DecodeEnterClipRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp17(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET crossId == ReadBytes(marketSegmentId.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET crossRequestId == ReadBytes(crossId.rest, 4) IN IF ~crossRequestId.ok THEN Fail ELSE
    LET noSides == ReadUIntBE(crossRequestId.rest, 1) IN IF ~noSides.ok THEN Fail ELSE
    LET noCrossLegs == ReadUIntBE(noSides.rest, 1) IN IF ~noCrossLegs.ok THEN Fail ELSE
    LET crossRequestType == ReadBytes(noCrossLegs.rest, 1) IN IF ~crossRequestType.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossRequestType.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET crossPrioritization == ReadBytes(crossType.rest, 1) IN IF ~crossPrioritization.ok THEN Fail ELSE
    LET sideDisclosureInstruction == ReadBytes(crossPrioritization.rest, 1) IN IF ~sideDisclosureInstruction.ok THEN Fail ELSE
    LET priceDisclosureInstruction == ReadBytes(sideDisclosureInstruction.rest, 1) IN IF ~priceDisclosureInstruction.ok THEN Fail ELSE
    LET orderQtyDisclosureInstruction == ReadBytes(priceDisclosureInstruction.rest, 1) IN IF ~orderQtyDisclosureInstruction.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(orderQtyDisclosureInstruction.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET rootPartyContraFirm == ReadBytes(valueCheckTypeValue.rest, 5) IN IF ~rootPartyContraFirm.ok THEN Fail ELSE
    LET rootPartyContraTrader == ReadBytes(rootPartyContraFirm.rest, 6) IN IF ~rootPartyContraTrader.ok THEN Fail ELSE
    LET pad7 == ReadBytes(rootPartyContraTrader.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET crossRequestSideGrpComp == ReadCrossRequestSideGrpCompList(pad7.rest, noSides.value) IN IF ~crossRequestSideGrpComp.ok THEN Fail ELSE
    LET sideCrossLegGrpComp == ReadSideCrossLegGrpCompList(crossRequestSideGrpComp.rest, noCrossLegs.value) IN IF ~sideCrossLegGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                  |-> networkMsgId.value,
         pad2                          |-> pad2.value,
         requestHeaderComp             |-> requestHeaderComp.value,
         securityId                    |-> securityId.value,
         price                         |-> price.value,
         orderQty                      |-> orderQty.value,
         marketSegmentId               |-> marketSegmentId.value,
         crossId                       |-> crossId.value,
         crossRequestId                |-> crossRequestId.value,
         crossRequestType              |-> crossRequestType.value,
         crossType                     |-> crossType.value,
         crossPrioritization           |-> crossPrioritization.value,
         sideDisclosureInstruction     |-> sideDisclosureInstruction.value,
         priceDisclosureInstruction    |-> priceDisclosureInstruction.value,
         orderQtyDisclosureInstruction |-> orderQtyDisclosureInstruction.value,
         priceValidityCheckType        |-> priceValidityCheckType.value,
         valueCheckTypeValue           |-> valueCheckTypeValue.value,
         rootPartyContraFirm           |-> rootPartyContraFirm.value,
         rootPartyContraTrader         |-> rootPartyContraTrader.value,
         pad7                          |-> pad7.value,
         crossRequestSideGrpComp       |-> crossRequestSideGrpComp.value,
         sideCrossLegGrpComp           |-> sideCrossLegGrpComp.value ], sideCrossLegGrpComp.rest)

ZeroEnterClipRequest ==
    [ networkMsgId                  |-> [i \in 1 .. 8 |-> 0],
      pad2                          |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp             |-> ZeroRequestHeaderComp17,
      securityId                    |-> [i \in 1 .. 8 |-> 0],
      price                         |-> [i \in 1 .. 8 |-> 0],
      orderQty                      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId               |-> [i \in 1 .. 4 |-> 0],
      crossId                       |-> [i \in 1 .. 4 |-> 0],
      crossRequestId                |-> [i \in 1 .. 4 |-> 0],
      crossRequestType              |-> [i \in 1 .. 1 |-> 0],
      crossType                     |-> [i \in 1 .. 1 |-> 0],
      crossPrioritization           |-> [i \in 1 .. 1 |-> 0],
      sideDisclosureInstruction     |-> [i \in 1 .. 1 |-> 0],
      priceDisclosureInstruction    |-> [i \in 1 .. 1 |-> 0],
      orderQtyDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType        |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue           |-> [i \in 1 .. 1 |-> 0],
      rootPartyContraFirm           |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraTrader         |-> [i \in 1 .. 6 |-> 0],
      pad7                          |-> [i \in 1 .. 7 |-> 0],
      crossRequestSideGrpComp       |-> << >>,
      sideCrossLegGrpComp           |-> << >> ]

(* Enter Clip Request at zero, then each field in turn at the values it is checked at *)
CheckedEnterClipRequest ==
    { ZeroEnterClipRequest }
        \cup { [ZeroEnterClipRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroEnterClipRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroEnterClipRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp17 }
        \cup { [ZeroEnterClipRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroEnterClipRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroEnterClipRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroEnterClipRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroEnterClipRequest EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroEnterClipRequest EXCEPT !.crossRequestId = one] : one \in Sample(4) }
        \cup { [ZeroEnterClipRequest EXCEPT !.crossRequestType = one] : one \in Sample(1) }
        \cup { [ZeroEnterClipRequest EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroEnterClipRequest EXCEPT !.crossPrioritization = one] : one \in Sample(1) }
        \cup { [ZeroEnterClipRequest EXCEPT !.sideDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroEnterClipRequest EXCEPT !.priceDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroEnterClipRequest EXCEPT !.orderQtyDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroEnterClipRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroEnterClipRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroEnterClipRequest EXCEPT !.rootPartyContraFirm = one] : one \in Sample(5) }
        \cup { [ZeroEnterClipRequest EXCEPT !.rootPartyContraTrader = one] : one \in Sample(6) }
        \cup { [ZeroEnterClipRequest EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroEnterClipRequest EXCEPT !.crossRequestSideGrpComp = one] : one \in SampleLists(OneCrossRequestSideGrpComp) }
        \cup { [ZeroEnterClipRequest EXCEPT !.sideCrossLegGrpComp = one] : one \in SampleLists(OneSideCrossLegGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp18 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp18(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp18(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp18 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp18 ==
    { ZeroRequestHeaderComp18 }
        \cup { [ZeroRequestHeaderComp18 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp18 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Side Alloc Grp Comp: 32 bytes                                           *)
(***************************************************************************)

SideAllocGrpComp ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      tesEnrichmentRuleId  : Sample(4),
      side                 : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeSideAllocGrpComp(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.tesEnrichmentRuleId
        \o message.side
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeSideAllocGrpComp(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET tesEnrichmentRuleId == ReadBytes(individualAllocId.rest, 4) IN IF ~tesEnrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(tesEnrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         tesEnrichmentRuleId  |-> tesEnrichmentRuleId.value,
         side                 |-> side.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroSideAllocGrpComp ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      tesEnrichmentRuleId  |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocGrpComp ==
    { ZeroSideAllocGrpComp }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.tesEnrichmentRuleId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeSideAllocGrpCompList(_)
EncodeSideAllocGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSideAllocGrpComp(Head(messages)) \o EncodeSideAllocGrpCompList(Tail(messages))

(* As many Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadSideAllocGrpCompList(_, _)
ReadSideAllocGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSideAllocGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSideAllocGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneSideAllocGrpComp == { ZeroSideAllocGrpComp }

(***************************************************************************)
(* Trd Instrmnt Leg Grp Comp: 24 bytes                                     *)
(***************************************************************************)

TrdInstrmntLegGrpComp ==
    [ legSecurityId : Sample(8),
      legPrice      : Sample(8),
      legQty        : Sample(8) ]

EncodeTrdInstrmntLegGrpComp(message) ==
    message.legSecurityId
        \o message.legPrice
        \o message.legQty

DecodeTrdInstrmntLegGrpComp(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSecurityId.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legQty == ReadBytes(legPrice.rest, 8) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legPrice      |-> legPrice.value,
         legQty        |-> legQty.value ], legQty.rest)

ZeroTrdInstrmntLegGrpComp ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legPrice      |-> [i \in 1 .. 8 |-> 0],
      legQty        |-> [i \in 1 .. 8 |-> 0] ]

(* Trd Instrmnt Leg Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedTrdInstrmntLegGrpComp ==
    { ZeroTrdInstrmntLegGrpComp }
        \cup { [ZeroTrdInstrmntLegGrpComp EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroTrdInstrmntLegGrpComp EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroTrdInstrmntLegGrpComp EXCEPT !.legQty = one] : one \in Sample(8) }

(* A run of Trd Instrmnt Leg Grp Comp, written one after another *)
RECURSIVE EncodeTrdInstrmntLegGrpCompList(_)
EncodeTrdInstrmntLegGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTrdInstrmntLegGrpComp(Head(messages)) \o EncodeTrdInstrmntLegGrpCompList(Tail(messages))

(* As many Trd Instrmnt Leg Grp Comp as the field that counts them says *)
RECURSIVE ReadTrdInstrmntLegGrpCompList(_, _)
ReadTrdInstrmntLegGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTrdInstrmntLegGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTrdInstrmntLegGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trd Instrmnt Leg Grp Comp of each kind, for the lists that carry them *)
OneTrdInstrmntLegGrpComp == { ZeroTrdInstrmntLegGrpComp }

(***************************************************************************)
(* Instrument Event Grp Comp: 8 bytes                                      *)
(***************************************************************************)

InstrumentEventGrpComp ==
    [ eventDate : Sample(4),
      eventType : Sample(1),
      pad3      : Sample(3) ]

EncodeInstrumentEventGrpComp(message) ==
    message.eventDate
        \o message.eventType
        \o message.pad3

DecodeInstrumentEventGrpComp(bytes) ==
    LET eventDate == ReadBytes(bytes, 4) IN IF ~eventDate.ok THEN Fail ELSE
    LET eventType == ReadBytes(eventDate.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET pad3 == ReadBytes(eventType.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ eventDate |-> eventDate.value,
         eventType |-> eventType.value,
         pad3      |-> pad3.value ], pad3.rest)

ZeroInstrumentEventGrpComp ==
    [ eventDate |-> [i \in 1 .. 4 |-> 0],
      eventType |-> [i \in 1 .. 1 |-> 0],
      pad3      |-> [i \in 1 .. 3 |-> 0] ]

(* Instrument Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentEventGrpComp ==
    { ZeroInstrumentEventGrpComp }
        \cup { [ZeroInstrumentEventGrpComp EXCEPT !.eventDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentEventGrpComp EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentEventGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Instrument Event Grp Comp, written one after another *)
RECURSIVE EncodeInstrumentEventGrpCompList(_)
EncodeInstrumentEventGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentEventGrpComp(Head(messages)) \o EncodeInstrumentEventGrpCompList(Tail(messages))

(* As many Instrument Event Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrumentEventGrpCompList(_, _)
ReadInstrumentEventGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentEventGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentEventGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Event Grp Comp of each kind, for the lists that carry them *)
OneInstrumentEventGrpComp == { ZeroInstrumentEventGrpComp }

(***************************************************************************)
(* Instrument Attribute Grp Comp: 40 bytes                                 *)
(***************************************************************************)

InstrumentAttributeGrpComp ==
    [ instrAttribType  : Sample(1),
      instrAttribValue : Sample(32),
      pad7             : Sample(7) ]

EncodeInstrumentAttributeGrpComp(message) ==
    message.instrAttribType
        \o message.instrAttribValue
        \o message.pad7

DecodeInstrumentAttributeGrpComp(bytes) ==
    LET instrAttribType == ReadBytes(bytes, 1) IN IF ~instrAttribType.ok THEN Fail ELSE
    LET instrAttribValue == ReadBytes(instrAttribType.rest, 32) IN IF ~instrAttribValue.ok THEN Fail ELSE
    LET pad7 == ReadBytes(instrAttribValue.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ instrAttribType  |-> instrAttribType.value,
         instrAttribValue |-> instrAttribValue.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroInstrumentAttributeGrpComp ==
    [ instrAttribType  |-> [i \in 1 .. 1 |-> 0],
      instrAttribValue |-> [i \in 1 .. 32 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Instrument Attribute Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentAttributeGrpComp ==
    { ZeroInstrumentAttributeGrpComp }
        \cup { [ZeroInstrumentAttributeGrpComp EXCEPT !.instrAttribType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentAttributeGrpComp EXCEPT !.instrAttribValue = one] : one \in Sample(32) }
        \cup { [ZeroInstrumentAttributeGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Instrument Attribute Grp Comp, written one after another *)
RECURSIVE EncodeInstrumentAttributeGrpCompList(_)
EncodeInstrumentAttributeGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentAttributeGrpComp(Head(messages)) \o EncodeInstrumentAttributeGrpCompList(Tail(messages))

(* As many Instrument Attribute Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrumentAttributeGrpCompList(_, _)
ReadInstrumentAttributeGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentAttributeGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentAttributeGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Attribute Grp Comp of each kind, for the lists that carry them *)
OneInstrumentAttributeGrpComp == { ZeroInstrumentAttributeGrpComp }

(***************************************************************************)
(* Underlying Stip Grp Comp: 40 bytes                                      *)
(***************************************************************************)

UnderlyingStipGrpComp ==
    [ underlyingStipValue : Sample(32),
      underlyingStipType  : Sample(7),
      pad1                : Sample(1) ]

EncodeUnderlyingStipGrpComp(message) ==
    message.underlyingStipValue
        \o message.underlyingStipType
        \o message.pad1

DecodeUnderlyingStipGrpComp(bytes) ==
    LET underlyingStipValue == ReadBytes(bytes, 32) IN IF ~underlyingStipValue.ok THEN Fail ELSE
    LET underlyingStipType == ReadBytes(underlyingStipValue.rest, 7) IN IF ~underlyingStipType.ok THEN Fail ELSE
    LET pad1 == ReadBytes(underlyingStipType.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ underlyingStipValue |-> underlyingStipValue.value,
         underlyingStipType  |-> underlyingStipType.value,
         pad1                |-> pad1.value ], pad1.rest)

ZeroUnderlyingStipGrpComp ==
    [ underlyingStipValue |-> [i \in 1 .. 32 |-> 0],
      underlyingStipType  |-> [i \in 1 .. 7 |-> 0],
      pad1                |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Stip Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingStipGrpComp ==
    { ZeroUnderlyingStipGrpComp }
        \cup { [ZeroUnderlyingStipGrpComp EXCEPT !.underlyingStipValue = one] : one \in Sample(32) }
        \cup { [ZeroUnderlyingStipGrpComp EXCEPT !.underlyingStipType = one] : one \in Sample(7) }
        \cup { [ZeroUnderlyingStipGrpComp EXCEPT !.pad1 = one] : one \in Sample(1) }

(* A run of Underlying Stip Grp Comp, written one after another *)
RECURSIVE EncodeUnderlyingStipGrpCompList(_)
EncodeUnderlyingStipGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnderlyingStipGrpComp(Head(messages)) \o EncodeUnderlyingStipGrpCompList(Tail(messages))

(* As many Underlying Stip Grp Comp as the field that counts them says *)
RECURSIVE ReadUnderlyingStipGrpCompList(_, _)
ReadUnderlyingStipGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnderlyingStipGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnderlyingStipGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Underlying Stip Grp Comp of each kind, for the lists that carry them *)
OneUnderlyingStipGrpComp == { ZeroUnderlyingStipGrpComp }

(***************************************************************************)
(* Enter Tes Trade Request                                                 *)
(***************************************************************************)

EnterTesTradeRequest ==
    [ networkMsgId               : Sample(8),
      pad2                       : Sample(2),
      requestHeaderComp          : RequestHeaderComp18,
      securityId                 : Sample(8),
      lastPx                     : Sample(8),
      transBkdTime               : Sample(8),
      underlyingPx               : Sample(8),
      relatedClosePrice          : Sample(8),
      relatedTradeQuantity       : Sample(8),
      underlyingQty              : Sample(8),
      marketSegmentId            : Sample(4),
      underlyingSettlementDate   : Sample(4),
      underlyingMaturityDate     : Sample(4),
      relatedTradeId             : Sample(4),
      relatedMarketSegmentId     : Sample(4),
      trdType                    : Sample(2),
      productComplex             : Sample(1),
      tradeReportType            : Sample(1),
      tradePublishIndicator      : Sample(1),
      partyIdSettlementLocation  : Sample(1),
      hedgeType                  : Sample(1),
      swapClearer                : Sample(1),
      tradeReportText            : Sample(20),
      tradeReportId              : Sample(20),
      underlyingSecurityId       : Sample(12),
      underlyingSecurityDesc     : Sample(30),
      underlyingCurrency         : Sample(3),
      underlyingIssuer           : Sample(30),
      pad4                       : Sample(4),
      sideAllocGrpComp           : SampleLists(OneSideAllocGrpComp),
      trdInstrmntLegGrpComp      : SampleLists(OneTrdInstrmntLegGrpComp),
      instrumentEventGrpComp     : SampleLists(OneInstrumentEventGrpComp),
      instrumentAttributeGrpComp : SampleLists(OneInstrumentAttributeGrpComp),
      underlyingStipGrpComp      : SampleLists(OneUnderlyingStipGrpComp) ]

EncodeEnterTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp18(message.requestHeaderComp)
        \o message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.underlyingPx
        \o message.relatedClosePrice
        \o message.relatedTradeQuantity
        \o message.underlyingQty
        \o message.marketSegmentId
        \o message.underlyingSettlementDate
        \o message.underlyingMaturityDate
        \o message.relatedTradeId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.productComplex
        \o message.tradeReportType
        \o message.tradePublishIndicator
        \o EncodeUIntBE(Len(message.sideAllocGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrumentEventGrpComp), 1)
        \o EncodeUIntBE(Len(message.trdInstrmntLegGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrumentAttributeGrpComp), 1)
        \o EncodeUIntBE(Len(message.underlyingStipGrpComp), 1)
        \o message.partyIdSettlementLocation
        \o message.hedgeType
        \o message.swapClearer
        \o message.tradeReportText
        \o message.tradeReportId
        \o message.underlyingSecurityId
        \o message.underlyingSecurityDesc
        \o message.underlyingCurrency
        \o message.underlyingIssuer
        \o message.pad4
        \o EncodeSideAllocGrpCompList(message.sideAllocGrpComp)
        \o EncodeTrdInstrmntLegGrpCompList(message.trdInstrmntLegGrpComp)
        \o EncodeInstrumentEventGrpCompList(message.instrumentEventGrpComp)
        \o EncodeInstrumentAttributeGrpCompList(message.instrumentAttributeGrpComp)
        \o EncodeUnderlyingStipGrpCompList(message.underlyingStipGrpComp)

DecodeEnterTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp18(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET underlyingPx == ReadBytes(transBkdTime.rest, 8) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(underlyingPx.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET relatedTradeQuantity == ReadBytes(relatedClosePrice.rest, 8) IN IF ~relatedTradeQuantity.ok THEN Fail ELSE
    LET underlyingQty == ReadBytes(relatedTradeQuantity.rest, 8) IN IF ~underlyingQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(underlyingQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingSettlementDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~underlyingSettlementDate.ok THEN Fail ELSE
    LET underlyingMaturityDate == ReadBytes(underlyingSettlementDate.rest, 4) IN IF ~underlyingMaturityDate.ok THEN Fail ELSE
    LET relatedTradeId == ReadBytes(underlyingMaturityDate.rest, 4) IN IF ~relatedTradeId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(relatedTradeId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(trdType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(productComplex.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(tradeReportType.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradePublishIndicator.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET noEvents == ReadUIntBE(noSideAllocs.rest, 1) IN IF ~noEvents.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(noEvents.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET noInstrAttrib == ReadUIntBE(noLegs.rest, 1) IN IF ~noInstrAttrib.ok THEN Fail ELSE
    LET noUnderlyingStips == ReadUIntBE(noInstrAttrib.rest, 1) IN IF ~noUnderlyingStips.ok THEN Fail ELSE
    LET partyIdSettlementLocation == ReadBytes(noUnderlyingStips.rest, 1) IN IF ~partyIdSettlementLocation.ok THEN Fail ELSE
    LET hedgeType == ReadBytes(partyIdSettlementLocation.rest, 1) IN IF ~hedgeType.ok THEN Fail ELSE
    LET swapClearer == ReadBytes(hedgeType.rest, 1) IN IF ~swapClearer.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(swapClearer.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET underlyingSecurityId == ReadBytes(tradeReportId.rest, 12) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET underlyingSecurityDesc == ReadBytes(underlyingSecurityId.rest, 30) IN IF ~underlyingSecurityDesc.ok THEN Fail ELSE
    LET underlyingCurrency == ReadBytes(underlyingSecurityDesc.rest, 3) IN IF ~underlyingCurrency.ok THEN Fail ELSE
    LET underlyingIssuer == ReadBytes(underlyingCurrency.rest, 30) IN IF ~underlyingIssuer.ok THEN Fail ELSE
    LET pad4 == ReadBytes(underlyingIssuer.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET sideAllocGrpComp == ReadSideAllocGrpCompList(pad4.rest, noSideAllocs.value) IN IF ~sideAllocGrpComp.ok THEN Fail ELSE
    LET trdInstrmntLegGrpComp == ReadTrdInstrmntLegGrpCompList(sideAllocGrpComp.rest, noLegs.value) IN IF ~trdInstrmntLegGrpComp.ok THEN Fail ELSE
    LET instrumentEventGrpComp == ReadInstrumentEventGrpCompList(trdInstrmntLegGrpComp.rest, noEvents.value) IN IF ~instrumentEventGrpComp.ok THEN Fail ELSE
    LET instrumentAttributeGrpComp == ReadInstrumentAttributeGrpCompList(instrumentEventGrpComp.rest, noInstrAttrib.value) IN IF ~instrumentAttributeGrpComp.ok THEN Fail ELSE
    LET underlyingStipGrpComp == ReadUnderlyingStipGrpCompList(instrumentAttributeGrpComp.rest, noUnderlyingStips.value) IN IF ~underlyingStipGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId               |-> networkMsgId.value,
         pad2                       |-> pad2.value,
         requestHeaderComp          |-> requestHeaderComp.value,
         securityId                 |-> securityId.value,
         lastPx                     |-> lastPx.value,
         transBkdTime               |-> transBkdTime.value,
         underlyingPx               |-> underlyingPx.value,
         relatedClosePrice          |-> relatedClosePrice.value,
         relatedTradeQuantity       |-> relatedTradeQuantity.value,
         underlyingQty              |-> underlyingQty.value,
         marketSegmentId            |-> marketSegmentId.value,
         underlyingSettlementDate   |-> underlyingSettlementDate.value,
         underlyingMaturityDate     |-> underlyingMaturityDate.value,
         relatedTradeId             |-> relatedTradeId.value,
         relatedMarketSegmentId     |-> relatedMarketSegmentId.value,
         trdType                    |-> trdType.value,
         productComplex             |-> productComplex.value,
         tradeReportType            |-> tradeReportType.value,
         tradePublishIndicator      |-> tradePublishIndicator.value,
         partyIdSettlementLocation  |-> partyIdSettlementLocation.value,
         hedgeType                  |-> hedgeType.value,
         swapClearer                |-> swapClearer.value,
         tradeReportText            |-> tradeReportText.value,
         tradeReportId              |-> tradeReportId.value,
         underlyingSecurityId       |-> underlyingSecurityId.value,
         underlyingSecurityDesc     |-> underlyingSecurityDesc.value,
         underlyingCurrency         |-> underlyingCurrency.value,
         underlyingIssuer           |-> underlyingIssuer.value,
         pad4                       |-> pad4.value,
         sideAllocGrpComp           |-> sideAllocGrpComp.value,
         trdInstrmntLegGrpComp      |-> trdInstrmntLegGrpComp.value,
         instrumentEventGrpComp     |-> instrumentEventGrpComp.value,
         instrumentAttributeGrpComp |-> instrumentAttributeGrpComp.value,
         underlyingStipGrpComp      |-> underlyingStipGrpComp.value ], underlyingStipGrpComp.rest)

ZeroEnterTesTradeRequest ==
    [ networkMsgId               |-> [i \in 1 .. 8 |-> 0],
      pad2                       |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp          |-> ZeroRequestHeaderComp18,
      securityId                 |-> [i \in 1 .. 8 |-> 0],
      lastPx                     |-> [i \in 1 .. 8 |-> 0],
      transBkdTime               |-> [i \in 1 .. 8 |-> 0],
      underlyingPx               |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice          |-> [i \in 1 .. 8 |-> 0],
      relatedTradeQuantity       |-> [i \in 1 .. 8 |-> 0],
      underlyingQty              |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId            |-> [i \in 1 .. 4 |-> 0],
      underlyingSettlementDate   |-> [i \in 1 .. 4 |-> 0],
      underlyingMaturityDate     |-> [i \in 1 .. 4 |-> 0],
      relatedTradeId             |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId     |-> [i \in 1 .. 4 |-> 0],
      trdType                    |-> [i \in 1 .. 2 |-> 0],
      productComplex             |-> [i \in 1 .. 1 |-> 0],
      tradeReportType            |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator      |-> [i \in 1 .. 1 |-> 0],
      partyIdSettlementLocation  |-> [i \in 1 .. 1 |-> 0],
      hedgeType                  |-> [i \in 1 .. 1 |-> 0],
      swapClearer                |-> [i \in 1 .. 1 |-> 0],
      tradeReportText            |-> [i \in 1 .. 20 |-> 0],
      tradeReportId              |-> [i \in 1 .. 20 |-> 0],
      underlyingSecurityId       |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityDesc     |-> [i \in 1 .. 30 |-> 0],
      underlyingCurrency         |-> [i \in 1 .. 3 |-> 0],
      underlyingIssuer           |-> [i \in 1 .. 30 |-> 0],
      pad4                       |-> [i \in 1 .. 4 |-> 0],
      sideAllocGrpComp           |-> << >>,
      trdInstrmntLegGrpComp      |-> << >>,
      instrumentEventGrpComp     |-> << >>,
      instrumentAttributeGrpComp |-> << >>,
      underlyingStipGrpComp      |-> << >> ]

(* Enter Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedEnterTesTradeRequest ==
    { ZeroEnterTesTradeRequest }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp18 }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingPx = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.relatedTradeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingQty = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingSettlementDate = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingMaturityDate = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.relatedTradeId = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.partyIdSettlementLocation = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.hedgeType = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.swapClearer = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingSecurityId = one] : one \in Sample(12) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingSecurityDesc = one] : one \in Sample(30) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingIssuer = one] : one \in Sample(30) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.sideAllocGrpComp = one] : one \in SampleLists(OneSideAllocGrpComp) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.trdInstrmntLegGrpComp = one] : one \in SampleLists(OneTrdInstrmntLegGrpComp) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.instrumentEventGrpComp = one] : one \in SampleLists(OneInstrumentEventGrpComp) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.instrumentAttributeGrpComp = one] : one \in SampleLists(OneInstrumentAttributeGrpComp) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingStipGrpComp = one] : one \in SampleLists(OneUnderlyingStipGrpComp) }

(***************************************************************************)
(* Heartbeat: 10 bytes                                                     *)
(***************************************************************************)

Heartbeat ==
    [ networkMsgId : Sample(8),
      pad2         : Sample(2) ]

EncodeHeartbeat(message) ==
    message.networkMsgId
        \o message.pad2

DecodeHeartbeat(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ networkMsgId |-> networkMsgId.value,
         pad2         |-> pad2.value ], pad2.rest)

ZeroHeartbeat ==
    [ networkMsgId |-> [i \in 1 .. 8 |-> 0],
      pad2         |-> [i \in 1 .. 2 |-> 0] ]

(* Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeat ==
    { ZeroHeartbeat }
        \cup { [ZeroHeartbeat EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroHeartbeat EXCEPT !.pad2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp19 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp19(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp19(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp19 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp19 ==
    { ZeroRequestHeaderComp19 }
        \cup { [ZeroRequestHeaderComp19 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp19 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Inquire Enrichment Rule Id List Request: 34 bytes                       *)
(***************************************************************************)

InquireEnrichmentRuleIdListRequest ==
    [ networkMsgId        : Sample(8),
      pad2                : Sample(2),
      requestHeaderComp   : RequestHeaderComp19,
      lastEntityProcessed : Sample(16) ]

EncodeInquireEnrichmentRuleIdListRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp19(message.requestHeaderComp)
        \o message.lastEntityProcessed

DecodeInquireEnrichmentRuleIdListRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp19(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastEntityProcessed == ReadBytes(requestHeaderComp.rest, 16) IN IF ~lastEntityProcessed.ok THEN Fail ELSE
    Ok([ networkMsgId        |-> networkMsgId.value,
         pad2                |-> pad2.value,
         requestHeaderComp   |-> requestHeaderComp.value,
         lastEntityProcessed |-> lastEntityProcessed.value ], lastEntityProcessed.rest)

ZeroInquireEnrichmentRuleIdListRequest ==
    [ networkMsgId        |-> [i \in 1 .. 8 |-> 0],
      pad2                |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp   |-> ZeroRequestHeaderComp19,
      lastEntityProcessed |-> [i \in 1 .. 16 |-> 0] ]

(* Inquire Enrichment Rule Id List Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireEnrichmentRuleIdListRequest ==
    { ZeroInquireEnrichmentRuleIdListRequest }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp19 }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp20 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp20(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp20(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp20 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp20 ==
    { ZeroRequestHeaderComp20 }
        \cup { [ZeroRequestHeaderComp20 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp20 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Inquire Mm Parameter Request: 26 bytes                                  *)
(***************************************************************************)

InquireMmParameterRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp20,
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4) ]

EncodeInquireMmParameterRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp20(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId

DecodeInquireMmParameterRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp20(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value ], targetPartyIdSessionId.rest)

ZeroInquireMmParameterRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp20,
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Inquire Mm Parameter Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireMmParameterRequest ==
    { ZeroInquireMmParameterRequest }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp20 }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp21 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp21(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp21(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp21 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp21 ==
    { ZeroRequestHeaderComp21 }
        \cup { [ZeroRequestHeaderComp21 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp21 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Inquire Margin Based Risk Limit Request: 26 bytes                       *)
(***************************************************************************)

InquireMarginBasedRiskLimitRequest ==
    [ networkMsgId             : Sample(8),
      pad2                     : Sample(2),
      requestHeaderComp        : RequestHeaderComp21,
      partitionId              : Sample(2),
      partyDetailExecutingUnit : Sample(5),
      pad1                     : Sample(1) ]

EncodeInquireMarginBasedRiskLimitRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp21(message.requestHeaderComp)
        \o message.partitionId
        \o message.partyDetailExecutingUnit
        \o message.pad1

DecodeInquireMarginBasedRiskLimitRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp21(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partitionId == ReadBytes(requestHeaderComp.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET partyDetailExecutingUnit == ReadBytes(partitionId.rest, 5) IN IF ~partyDetailExecutingUnit.ok THEN Fail ELSE
    LET pad1 == ReadBytes(partyDetailExecutingUnit.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId             |-> networkMsgId.value,
         pad2                     |-> pad2.value,
         requestHeaderComp        |-> requestHeaderComp.value,
         partitionId              |-> partitionId.value,
         partyDetailExecutingUnit |-> partyDetailExecutingUnit.value,
         pad1                     |-> pad1.value ], pad1.rest)

ZeroInquireMarginBasedRiskLimitRequest ==
    [ networkMsgId             |-> [i \in 1 .. 8 |-> 0],
      pad2                     |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp        |-> ZeroRequestHeaderComp21,
      partitionId              |-> [i \in 1 .. 2 |-> 0],
      partyDetailExecutingUnit |-> [i \in 1 .. 5 |-> 0],
      pad1                     |-> [i \in 1 .. 1 |-> 0] ]

(* Inquire Margin Based Risk Limit Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireMarginBasedRiskLimitRequest ==
    { ZeroInquireMarginBasedRiskLimitRequest }
        \cup { [ZeroInquireMarginBasedRiskLimitRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireMarginBasedRiskLimitRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireMarginBasedRiskLimitRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp21 }
        \cup { [ZeroInquireMarginBasedRiskLimitRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroInquireMarginBasedRiskLimitRequest EXCEPT !.partyDetailExecutingUnit = one] : one \in Sample(5) }
        \cup { [ZeroInquireMarginBasedRiskLimitRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp22 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp22(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp22(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp22 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp22 ==
    { ZeroRequestHeaderComp22 }
        \cup { [ZeroRequestHeaderComp22 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp22 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Inquire Pre Trade Risk Limits Request: 34 bytes                         *)
(***************************************************************************)

InquirePreTradeRiskLimitsRequest ==
    [ networkMsgId       : Sample(8),
      pad2               : Sample(2),
      requestHeaderComp  : RequestHeaderComp22,
      marketSegmentId    : Sample(4),
      riskLimitPlatform  : Sample(1),
      partyExecutingUnit : Sample(5),
      riskLimitGroup     : Sample(3),
      pad3               : Sample(3) ]

EncodeInquirePreTradeRiskLimitsRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp22(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.riskLimitPlatform
        \o message.partyExecutingUnit
        \o message.riskLimitGroup
        \o message.pad3

DecodeInquirePreTradeRiskLimitsRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp22(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET riskLimitPlatform == ReadBytes(marketSegmentId.rest, 1) IN IF ~riskLimitPlatform.ok THEN Fail ELSE
    LET partyExecutingUnit == ReadBytes(riskLimitPlatform.rest, 5) IN IF ~partyExecutingUnit.ok THEN Fail ELSE
    LET riskLimitGroup == ReadBytes(partyExecutingUnit.rest, 3) IN IF ~riskLimitGroup.ok THEN Fail ELSE
    LET pad3 == ReadBytes(riskLimitGroup.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId       |-> networkMsgId.value,
         pad2               |-> pad2.value,
         requestHeaderComp  |-> requestHeaderComp.value,
         marketSegmentId    |-> marketSegmentId.value,
         riskLimitPlatform  |-> riskLimitPlatform.value,
         partyExecutingUnit |-> partyExecutingUnit.value,
         riskLimitGroup     |-> riskLimitGroup.value,
         pad3               |-> pad3.value ], pad3.rest)

ZeroInquirePreTradeRiskLimitsRequest ==
    [ networkMsgId       |-> [i \in 1 .. 8 |-> 0],
      pad2               |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp  |-> ZeroRequestHeaderComp22,
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      riskLimitPlatform  |-> [i \in 1 .. 1 |-> 0],
      partyExecutingUnit |-> [i \in 1 .. 5 |-> 0],
      riskLimitGroup     |-> [i \in 1 .. 3 |-> 0],
      pad3               |-> [i \in 1 .. 3 |-> 0] ]

(* Inquire Pre Trade Risk Limits Request at zero, then each field in turn at the values it is checked at *)
CheckedInquirePreTradeRiskLimitsRequest ==
    { ZeroInquirePreTradeRiskLimitsRequest }
        \cup { [ZeroInquirePreTradeRiskLimitsRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquirePreTradeRiskLimitsRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquirePreTradeRiskLimitsRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp22 }
        \cup { [ZeroInquirePreTradeRiskLimitsRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroInquirePreTradeRiskLimitsRequest EXCEPT !.riskLimitPlatform = one] : one \in Sample(1) }
        \cup { [ZeroInquirePreTradeRiskLimitsRequest EXCEPT !.partyExecutingUnit = one] : one \in Sample(5) }
        \cup { [ZeroInquirePreTradeRiskLimitsRequest EXCEPT !.riskLimitGroup = one] : one \in Sample(3) }
        \cup { [ZeroInquirePreTradeRiskLimitsRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp23 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp23(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp23(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp23 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp23 ==
    { ZeroRequestHeaderComp23 }
        \cup { [ZeroRequestHeaderComp23 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp23 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Inquire Session List Request: 18 bytes                                  *)
(***************************************************************************)

InquireSessionListRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp23 ]

EncodeInquireSessionListRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp23(message.requestHeaderComp)

DecodeInquireSessionListRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp23(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroInquireSessionListRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp23 ]

(* Inquire Session List Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireSessionListRequest ==
    { ZeroInquireSessionListRequest }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp23 }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp24 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp24(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp24(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp24 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp24 ==
    { ZeroRequestHeaderComp24 }
        \cup { [ZeroRequestHeaderComp24 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp24 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Inquire User Request: 34 bytes                                          *)
(***************************************************************************)

InquireUserRequest ==
    [ networkMsgId        : Sample(8),
      pad2                : Sample(2),
      requestHeaderComp   : RequestHeaderComp24,
      lastEntityProcessed : Sample(16) ]

EncodeInquireUserRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp24(message.requestHeaderComp)
        \o message.lastEntityProcessed

DecodeInquireUserRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp24(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastEntityProcessed == ReadBytes(requestHeaderComp.rest, 16) IN IF ~lastEntityProcessed.ok THEN Fail ELSE
    Ok([ networkMsgId        |-> networkMsgId.value,
         pad2                |-> pad2.value,
         requestHeaderComp   |-> requestHeaderComp.value,
         lastEntityProcessed |-> lastEntityProcessed.value ], lastEntityProcessed.rest)

ZeroInquireUserRequest ==
    [ networkMsgId        |-> [i \in 1 .. 8 |-> 0],
      pad2                |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp   |-> ZeroRequestHeaderComp24,
      lastEntityProcessed |-> [i \in 1 .. 16 |-> 0] ]

(* Inquire User Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireUserRequest ==
    { ZeroInquireUserRequest }
        \cup { [ZeroInquireUserRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireUserRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireUserRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp24 }
        \cup { [ZeroInquireUserRequest EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp25 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp25(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp25(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp25 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp25 ==
    { ZeroRequestHeaderComp25 }
        \cup { [ZeroRequestHeaderComp25 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp25 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Request: 90 bytes                                                 *)
(***************************************************************************)

LogonRequest ==
    [ networkMsgId         : Sample(8),
      pad2                 : Sample(2),
      requestHeaderComp    : RequestHeaderComp25,
      heartBtInt           : Sample(4),
      partyIdSessionId     : Sample(4),
      defaultCstmApplVerId : Sample(30),
      password             : Sample(32),
      pad2v2               : Sample(2) ]

EncodeLogonRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp25(message.requestHeaderComp)
        \o message.heartBtInt
        \o message.partyIdSessionId
        \o message.defaultCstmApplVerId
        \o message.password
        \o message.pad2v2

DecodeLogonRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp25(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(requestHeaderComp.rest, 4) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(heartBtInt.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET defaultCstmApplVerId == ReadBytes(partyIdSessionId.rest, 30) IN IF ~defaultCstmApplVerId.ok THEN Fail ELSE
    LET password == ReadBytes(defaultCstmApplVerId.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(password.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ networkMsgId         |-> networkMsgId.value,
         pad2                 |-> pad2.value,
         requestHeaderComp    |-> requestHeaderComp.value,
         heartBtInt           |-> heartBtInt.value,
         partyIdSessionId     |-> partyIdSessionId.value,
         defaultCstmApplVerId |-> defaultCstmApplVerId.value,
         password             |-> password.value,
         pad2v2               |-> pad2v2.value ], pad2v2.rest)

ZeroLogonRequest ==
    [ networkMsgId         |-> [i \in 1 .. 8 |-> 0],
      pad2                 |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp    |-> ZeroRequestHeaderComp25,
      heartBtInt           |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId     |-> [i \in 1 .. 4 |-> 0],
      defaultCstmApplVerId |-> [i \in 1 .. 30 |-> 0],
      password             |-> [i \in 1 .. 32 |-> 0],
      pad2v2               |-> [i \in 1 .. 2 |-> 0] ]

(* Logon Request at zero, then each field in turn at the values it is checked at *)
CheckedLogonRequest ==
    { ZeroLogonRequest }
        \cup { [ZeroLogonRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogonRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp25 }
        \cup { [ZeroLogonRequest EXCEPT !.heartBtInt = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequest EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequest EXCEPT !.defaultCstmApplVerId = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroLogonRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp26 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp26(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp26(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp26 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp26 ==
    { ZeroRequestHeaderComp26 }
        \cup { [ZeroRequestHeaderComp26 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp26 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Request Encrypted: 746 bytes                                      *)
(***************************************************************************)

LogonRequestEncrypted ==
    [ networkMsgId         : Sample(8),
      pad2                 : Sample(2),
      requestHeaderComp    : RequestHeaderComp26,
      heartBtInt           : Sample(4),
      partyIdSessionId     : Sample(4),
      defaultCstmApplVerId : Sample(30),
      encryptedPassword    : Sample(684),
      pad6                 : Sample(6) ]

EncodeLogonRequestEncrypted(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp26(message.requestHeaderComp)
        \o message.heartBtInt
        \o message.partyIdSessionId
        \o message.defaultCstmApplVerId
        \o message.encryptedPassword
        \o message.pad6

DecodeLogonRequestEncrypted(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp26(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(requestHeaderComp.rest, 4) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(heartBtInt.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET defaultCstmApplVerId == ReadBytes(partyIdSessionId.rest, 30) IN IF ~defaultCstmApplVerId.ok THEN Fail ELSE
    LET encryptedPassword == ReadBytes(defaultCstmApplVerId.rest, 684) IN IF ~encryptedPassword.ok THEN Fail ELSE
    LET pad6 == ReadBytes(encryptedPassword.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId         |-> networkMsgId.value,
         pad2                 |-> pad2.value,
         requestHeaderComp    |-> requestHeaderComp.value,
         heartBtInt           |-> heartBtInt.value,
         partyIdSessionId     |-> partyIdSessionId.value,
         defaultCstmApplVerId |-> defaultCstmApplVerId.value,
         encryptedPassword    |-> encryptedPassword.value,
         pad6                 |-> pad6.value ], pad6.rest)

ZeroLogonRequestEncrypted ==
    [ networkMsgId         |-> [i \in 1 .. 8 |-> 0],
      pad2                 |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp    |-> ZeroRequestHeaderComp26,
      heartBtInt           |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId     |-> [i \in 1 .. 4 |-> 0],
      defaultCstmApplVerId |-> [i \in 1 .. 30 |-> 0],
      encryptedPassword    |-> [i \in 1 .. 684 |-> 0],
      pad6                 |-> [i \in 1 .. 6 |-> 0] ]

(* Logon Request Encrypted at zero, then each field in turn at the values it is checked at *)
CheckedLogonRequestEncrypted ==
    { ZeroLogonRequestEncrypted }
        \cup { [ZeroLogonRequestEncrypted EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestEncrypted EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogonRequestEncrypted EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp26 }
        \cup { [ZeroLogonRequestEncrypted EXCEPT !.heartBtInt = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequestEncrypted EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequestEncrypted EXCEPT !.defaultCstmApplVerId = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequestEncrypted EXCEPT !.encryptedPassword = one] : one \in Sample(684) }
        \cup { [ZeroLogonRequestEncrypted EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp27 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp27(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp27(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp27 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp27 ==
    { ZeroRequestHeaderComp27 }
        \cup { [ZeroRequestHeaderComp27 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp27 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Request: 18 bytes                                                *)
(***************************************************************************)

LogoutRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp27 ]

EncodeLogoutRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp27(message.requestHeaderComp)

DecodeLogoutRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp27(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroLogoutRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp27 ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp27 }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp28 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp28(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp28(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp28 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp28 ==
    { ZeroRequestHeaderComp28 }
        \cup { [ZeroRequestHeaderComp28 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp28 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Mm Parameter Definition Request: 66 bytes                               *)
(***************************************************************************)

MmParameterDefinitionRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp28,
      exposureDuration       : Sample(8),
      cumQty                 : Sample(8),
      delta                  : Sample(8),
      vega                   : Sample(8),
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4),
      pctCount               : Sample(4),
      mmRiskLimitActionType  : Sample(1),
      pad3                   : Sample(3) ]

EncodeMmParameterDefinitionRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp28(message.requestHeaderComp)
        \o message.exposureDuration
        \o message.cumQty
        \o message.delta
        \o message.vega
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.pctCount
        \o message.mmRiskLimitActionType
        \o message.pad3

DecodeMmParameterDefinitionRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp28(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET exposureDuration == ReadBytes(requestHeaderComp.rest, 8) IN IF ~exposureDuration.ok THEN Fail ELSE
    LET cumQty == ReadBytes(exposureDuration.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET delta == ReadBytes(cumQty.rest, 8) IN IF ~delta.ok THEN Fail ELSE
    LET vega == ReadBytes(delta.rest, 8) IN IF ~vega.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(vega.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET pctCount == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~pctCount.ok THEN Fail ELSE
    LET mmRiskLimitActionType == ReadBytes(pctCount.rest, 1) IN IF ~mmRiskLimitActionType.ok THEN Fail ELSE
    LET pad3 == ReadBytes(mmRiskLimitActionType.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         exposureDuration       |-> exposureDuration.value,
         cumQty                 |-> cumQty.value,
         delta                  |-> delta.value,
         vega                   |-> vega.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value,
         pctCount               |-> pctCount.value,
         mmRiskLimitActionType  |-> mmRiskLimitActionType.value,
         pad3                   |-> pad3.value ], pad3.rest)

ZeroMmParameterDefinitionRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp28,
      exposureDuration       |-> [i \in 1 .. 8 |-> 0],
      cumQty                 |-> [i \in 1 .. 8 |-> 0],
      delta                  |-> [i \in 1 .. 8 |-> 0],
      vega                   |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      pctCount               |-> [i \in 1 .. 4 |-> 0],
      mmRiskLimitActionType  |-> [i \in 1 .. 1 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0] ]

(* Mm Parameter Definition Request at zero, then each field in turn at the values it is checked at *)
CheckedMmParameterDefinitionRequest ==
    { ZeroMmParameterDefinitionRequest }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp28 }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.exposureDuration = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.delta = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.vega = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.pctCount = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.mmRiskLimitActionType = one] : one \in Sample(1) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp29 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp29(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp29(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp29 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp29 ==
    { ZeroRequestHeaderComp29 }
        \cup { [ZeroRequestHeaderComp29 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp29 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Entry Grp Comp: 40 bytes                                          *)
(***************************************************************************)

OrderEntryGrpComp ==
    [ price           : Sample(8),
      orderQty        : Sample(8),
      marketSegmentId : Sample(4),
      pad4            : Sample(4),
      securityId      : Sample(8),
      side            : Sample(1),
      productComplex  : Sample(1),
      pad6            : Sample(6) ]

EncodeOrderEntryGrpComp(message) ==
    message.price
        \o message.orderQty
        \o message.marketSegmentId
        \o message.pad4
        \o message.securityId
        \o message.side
        \o message.productComplex
        \o message.pad6

DecodeOrderEntryGrpComp(bytes) ==
    LET price == ReadBytes(bytes, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(marketSegmentId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET securityId == ReadBytes(pad4.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET productComplex == ReadBytes(side.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET pad6 == ReadBytes(productComplex.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ price           |-> price.value,
         orderQty        |-> orderQty.value,
         marketSegmentId |-> marketSegmentId.value,
         pad4            |-> pad4.value,
         securityId      |-> securityId.value,
         side            |-> side.value,
         productComplex  |-> productComplex.value,
         pad6            |-> pad6.value ], pad6.rest)

ZeroOrderEntryGrpComp ==
    [ price           |-> [i \in 1 .. 8 |-> 0],
      orderQty        |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 4 |-> 0],
      pad4            |-> [i \in 1 .. 4 |-> 0],
      securityId      |-> [i \in 1 .. 8 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      productComplex  |-> [i \in 1 .. 1 |-> 0],
      pad6            |-> [i \in 1 .. 6 |-> 0] ]

(* Order Entry Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryGrpComp ==
    { ZeroOrderEntryGrpComp }
        \cup { [ZeroOrderEntryGrpComp EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryGrpComp EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryGrpComp EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryGrpComp EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Order Entry Grp Comp, written one after another *)
RECURSIVE EncodeOrderEntryGrpCompList(_)
EncodeOrderEntryGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderEntryGrpComp(Head(messages)) \o EncodeOrderEntryGrpCompList(Tail(messages))

(* As many Order Entry Grp Comp as the field that counts them says *)
RECURSIVE ReadOrderEntryGrpCompList(_, _)
ReadOrderEntryGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderEntryGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderEntryGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Entry Grp Comp of each kind, for the lists that carry them *)
OneOrderEntryGrpComp == { ZeroOrderEntryGrpComp }

(***************************************************************************)
(* Mass Order                                                              *)
(***************************************************************************)

MassOrder ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp29,
      massOrderRequestId                      : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      partyIdTakeUpTradingFirm                : Sample(5),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdBeneficiary                      : Sample(9),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      orderAttributeRiskReduction             : Sample(1),
      tradingSessionSubId                     : Sample(1),
      tradingCapacity                         : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      account                                 : Sample(2),
      partyIdPositionAccount                  : Sample(32),
      positionEffect                          : Sample(1),
      partyIdLocationId                       : Sample(2),
      custOrderHandlingInst                   : Sample(1),
      complianceText                          : Sample(20),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      partyEndClientIdentification            : Sample(20),
      pad7                                    : Sample(7),
      orderEntryGrpComp                       : SampleLists(OneOrderEntryGrpComp) ]

EncodeMassOrder(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp29(message.requestHeaderComp)
        \o message.massOrderRequestId
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.orderAttributeLiquidityProvision
        \o message.orderAttributeRiskReduction
        \o message.tradingSessionSubId
        \o message.tradingCapacity
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.account
        \o message.partyIdPositionAccount
        \o message.positionEffect
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.partyEndClientIdentification
        \o EncodeUIntBE(Len(message.orderEntryGrpComp), 1)
        \o message.pad7
        \o EncodeOrderEntryGrpCompList(message.orderEntryGrpComp)

DecodeMassOrder(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp29(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET massOrderRequestId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~massOrderRequestId.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(massOrderRequestId.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(executingTrader.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET orderAttributeRiskReduction == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~orderAttributeRiskReduction.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(orderAttributeRiskReduction.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET account == ReadBytes(executingTraderQualifier.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(account.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(partyIdPositionAccount.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(positionEffect.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(complianceText.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET partyEndClientIdentification == ReadBytes(freeText3.rest, 20) IN IF ~partyEndClientIdentification.ok THEN Fail ELSE
    LET noOrderEntries == ReadUIntBE(partyEndClientIdentification.rest, 1) IN IF ~noOrderEntries.ok THEN Fail ELSE
    LET pad7 == ReadBytes(noOrderEntries.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET orderEntryGrpComp == ReadOrderEntryGrpCompList(pad7.rest, noOrderEntries.value) IN IF ~orderEntryGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         massOrderRequestId                      |-> massOrderRequestId.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         orderAttributeRiskReduction             |-> orderAttributeRiskReduction.value,
         tradingSessionSubId                     |-> tradingSessionSubId.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         account                                 |-> account.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         positionEffect                          |-> positionEffect.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         complianceText                          |-> complianceText.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         partyEndClientIdentification            |-> partyEndClientIdentification.value,
         pad7                                    |-> pad7.value,
         orderEntryGrpComp                       |-> orderEntryGrpComp.value ], orderEntryGrpComp.rest)

ZeroMassOrder ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp29,
      massOrderRequestId                      |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      orderAttributeRiskReduction             |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId                     |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      partyEndClientIdentification            |-> [i \in 1 .. 20 |-> 0],
      pad7                                    |-> [i \in 1 .. 7 |-> 0],
      orderEntryGrpComp                       |-> << >> ]

(* Mass Order at zero, then each field in turn at the values it is checked at *)
CheckedMassOrder ==
    { ZeroMassOrder }
        \cup { [ZeroMassOrder EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroMassOrder EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMassOrder EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp29 }
        \cup { [ZeroMassOrder EXCEPT !.massOrderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroMassOrder EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroMassOrder EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroMassOrder EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroMassOrder EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroMassOrder EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroMassOrder EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroMassOrder EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.orderAttributeRiskReduction = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroMassOrder EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroMassOrder EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroMassOrder EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroMassOrder EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroMassOrder EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroMassOrder EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroMassOrder EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroMassOrder EXCEPT !.partyEndClientIdentification = one] : one \in Sample(20) }
        \cup { [ZeroMassOrder EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroMassOrder EXCEPT !.orderEntryGrpComp = one] : one \in SampleLists(OneOrderEntryGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp30 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp30(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp30(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp30 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp30 ==
    { ZeroRequestHeaderComp30 }
        \cup { [ZeroRequestHeaderComp30 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp30 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Entry Grp Comp: 40 bytes                                          *)
(***************************************************************************)

QuoteEntryGrpComp ==
    [ securityId : Sample(8),
      bidPx      : Sample(8),
      bidSize    : Sample(8),
      offerPx    : Sample(8),
      offerSize  : Sample(8) ]

EncodeQuoteEntryGrpComp(message) ==
    message.securityId
        \o message.bidPx
        \o message.bidSize
        \o message.offerPx
        \o message.offerSize

DecodeQuoteEntryGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPx.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         bidPx      |-> bidPx.value,
         bidSize    |-> bidSize.value,
         offerPx    |-> offerPx.value,
         offerSize  |-> offerSize.value ], offerSize.rest)

ZeroQuoteEntryGrpComp ==
    [ securityId |-> [i \in 1 .. 8 |-> 0],
      bidPx      |-> [i \in 1 .. 8 |-> 0],
      bidSize    |-> [i \in 1 .. 8 |-> 0],
      offerPx    |-> [i \in 1 .. 8 |-> 0],
      offerSize  |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Entry Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEntryGrpComp ==
    { ZeroQuoteEntryGrpComp }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.offerSize = one] : one \in Sample(8) }

(* A run of Quote Entry Grp Comp, written one after another *)
RECURSIVE EncodeQuoteEntryGrpCompList(_)
EncodeQuoteEntryGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteEntryGrpComp(Head(messages)) \o EncodeQuoteEntryGrpCompList(Tail(messages))

(* As many Quote Entry Grp Comp as the field that counts them says *)
RECURSIVE ReadQuoteEntryGrpCompList(_, _)
ReadQuoteEntryGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteEntryGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteEntryGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Entry Grp Comp of each kind, for the lists that carry them *)
OneQuoteEntryGrpComp == { ZeroQuoteEntryGrpComp }

(***************************************************************************)
(* Mass Quote Request                                                      *)
(***************************************************************************)

MassQuoteRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp30,
      quoteId                                 : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      matchInstCrossId                        : Sample(4),
      enrichmentRuleId                        : Sample(2),
      selfMatchPreventionInstruction          : Sample(1),
      crossMatchInstruction                   : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      quoteSizeType                           : Sample(1),
      quoteType                               : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      pad4                                    : Sample(4),
      quoteEntryGrpComp                       : SampleLists(OneQuoteEntryGrpComp) ]

EncodeMassQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp30(message.requestHeaderComp)
        \o message.quoteId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.matchInstCrossId
        \o message.enrichmentRuleId
        \o message.selfMatchPreventionInstruction
        \o message.crossMatchInstruction
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.quoteSizeType
        \o message.quoteType
        \o message.orderAttributeLiquidityProvision
        \o EncodeUIntBE(Len(message.quoteEntryGrpComp), 1)
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.pad4
        \o EncodeQuoteEntryGrpCompList(message.quoteEntryGrpComp)

DecodeMassQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp30(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(quoteId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(marketSegmentId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(matchInstCrossId.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET crossMatchInstruction == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~crossMatchInstruction.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(crossMatchInstruction.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET quoteSizeType == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~quoteSizeType.ok THEN Fail ELSE
    LET quoteType == ReadBytes(quoteSizeType.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(quoteType.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET noQuoteEntries == ReadUIntBE(orderAttributeLiquidityProvision.rest, 1) IN IF ~noQuoteEntries.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(noQuoteEntries.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET pad4 == ReadBytes(executingTraderQualifier.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET quoteEntryGrpComp == ReadQuoteEntryGrpCompList(pad4.rest, noQuoteEntries.value) IN IF ~quoteEntryGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         quoteId                                 |-> quoteId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         enrichmentRuleId                        |-> enrichmentRuleId.value,
         selfMatchPreventionInstruction          |-> selfMatchPreventionInstruction.value,
         crossMatchInstruction                   |-> crossMatchInstruction.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         quoteSizeType                           |-> quoteSizeType.value,
         quoteType                               |-> quoteType.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         pad4                                    |-> pad4.value,
         quoteEntryGrpComp                       |-> quoteEntryGrpComp.value ], quoteEntryGrpComp.rest)

ZeroMassQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp30,
      quoteId                                 |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      enrichmentRuleId                        |-> [i \in 1 .. 2 |-> 0],
      selfMatchPreventionInstruction          |-> [i \in 1 .. 1 |-> 0],
      crossMatchInstruction                   |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      quoteSizeType                           |-> [i \in 1 .. 1 |-> 0],
      quoteType                               |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      pad4                                    |-> [i \in 1 .. 4 |-> 0],
      quoteEntryGrpComp                       |-> << >> ]

(* Mass Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequest ==
    { ZeroMassQuoteRequest }
        \cup { [ZeroMassQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp30 }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.crossMatchInstruction = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteSizeType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteEntryGrpComp = one] : one \in SampleLists(OneQuoteEntryGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp31 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp31(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp31(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp31 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp31 ==
    { ZeroRequestHeaderComp31 }
        \cup { [ZeroRequestHeaderComp31 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp31 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Basket Root Party Grp Comp: 40 bytes                                    *)
(***************************************************************************)

BasketRootPartyGrpComp4 ==
    [ rootPartySubIdType      : Sample(2),
      rootPartyContraFirm     : Sample(5),
      rootPartyContraTrader   : Sample(6),
      basketSideTradeReportId : Sample(20),
      pad7                    : Sample(7) ]

EncodeBasketRootPartyGrpComp4(message) ==
    message.rootPartySubIdType
        \o message.rootPartyContraFirm
        \o message.rootPartyContraTrader
        \o message.basketSideTradeReportId
        \o message.pad7

DecodeBasketRootPartyGrpComp4(bytes) ==
    LET rootPartySubIdType == ReadBytes(bytes, 2) IN IF ~rootPartySubIdType.ok THEN Fail ELSE
    LET rootPartyContraFirm == ReadBytes(rootPartySubIdType.rest, 5) IN IF ~rootPartyContraFirm.ok THEN Fail ELSE
    LET rootPartyContraTrader == ReadBytes(rootPartyContraFirm.rest, 6) IN IF ~rootPartyContraTrader.ok THEN Fail ELSE
    LET basketSideTradeReportId == ReadBytes(rootPartyContraTrader.rest, 20) IN IF ~basketSideTradeReportId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(basketSideTradeReportId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ rootPartySubIdType      |-> rootPartySubIdType.value,
         rootPartyContraFirm     |-> rootPartyContraFirm.value,
         rootPartyContraTrader   |-> rootPartyContraTrader.value,
         basketSideTradeReportId |-> basketSideTradeReportId.value,
         pad7                    |-> pad7.value ], pad7.rest)

ZeroBasketRootPartyGrpComp4 ==
    [ rootPartySubIdType      |-> [i \in 1 .. 2 |-> 0],
      rootPartyContraFirm     |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraTrader   |-> [i \in 1 .. 6 |-> 0],
      basketSideTradeReportId |-> [i \in 1 .. 20 |-> 0],
      pad7                    |-> [i \in 1 .. 7 |-> 0] ]

(* Basket Root Party Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedBasketRootPartyGrpComp4 ==
    { ZeroBasketRootPartyGrpComp4 }
        \cup { [ZeroBasketRootPartyGrpComp4 EXCEPT !.rootPartySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroBasketRootPartyGrpComp4 EXCEPT !.rootPartyContraFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketRootPartyGrpComp4 EXCEPT !.rootPartyContraTrader = one] : one \in Sample(6) }
        \cup { [ZeroBasketRootPartyGrpComp4 EXCEPT !.basketSideTradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroBasketRootPartyGrpComp4 EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Basket Root Party Grp Comp, written one after another *)
RECURSIVE EncodeBasketRootPartyGrpComp4List(_)
EncodeBasketRootPartyGrpComp4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBasketRootPartyGrpComp4(Head(messages)) \o EncodeBasketRootPartyGrpComp4List(Tail(messages))

(* As many Basket Root Party Grp Comp as the field that counts them says *)
RECURSIVE ReadBasketRootPartyGrpComp4List(_, _)
ReadBasketRootPartyGrpComp4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBasketRootPartyGrpComp4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBasketRootPartyGrpComp4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Basket Root Party Grp Comp of each kind, for the lists that carry them *)
OneBasketRootPartyGrpComp4 == { ZeroBasketRootPartyGrpComp4 }

(***************************************************************************)
(* Instrmt Match Side Grp Comp: 80 bytes                                   *)
(***************************************************************************)

InstrmtMatchSideGrpComp3 ==
    [ securityId            : Sample(8),
      lastPx                : Sample(8),
      transBkdTime          : Sample(8),
      relatedClosePrice     : Sample(8),
      clearingTradePrice    : Sample(8),
      packageId             : Sample(4),
      sideMarketSegmentId   : Sample(4),
      sideTrdSubTyp         : Sample(2),
      productComplex        : Sample(1),
      tradePublishIndicator : Sample(1),
      instrmtMatchSideId    : Sample(1),
      effectOnBasket        : Sample(1),
      tradeReportText       : Sample(20),
      pad6                  : Sample(6) ]

EncodeInstrmtMatchSideGrpComp3(message) ==
    message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.relatedClosePrice
        \o message.clearingTradePrice
        \o message.packageId
        \o message.sideMarketSegmentId
        \o message.sideTrdSubTyp
        \o message.productComplex
        \o message.tradePublishIndicator
        \o message.instrmtMatchSideId
        \o message.effectOnBasket
        \o message.tradeReportText
        \o message.pad6

DecodeInstrmtMatchSideGrpComp3(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(transBkdTime.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET clearingTradePrice == ReadBytes(relatedClosePrice.rest, 8) IN IF ~clearingTradePrice.ok THEN Fail ELSE
    LET packageId == ReadBytes(clearingTradePrice.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET sideMarketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~sideMarketSegmentId.ok THEN Fail ELSE
    LET sideTrdSubTyp == ReadBytes(sideMarketSegmentId.rest, 2) IN IF ~sideTrdSubTyp.ok THEN Fail ELSE
    LET productComplex == ReadBytes(sideTrdSubTyp.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(productComplex.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(tradePublishIndicator.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET effectOnBasket == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~effectOnBasket.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(effectOnBasket.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET pad6 == ReadBytes(tradeReportText.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         lastPx                |-> lastPx.value,
         transBkdTime          |-> transBkdTime.value,
         relatedClosePrice     |-> relatedClosePrice.value,
         clearingTradePrice    |-> clearingTradePrice.value,
         packageId             |-> packageId.value,
         sideMarketSegmentId   |-> sideMarketSegmentId.value,
         sideTrdSubTyp         |-> sideTrdSubTyp.value,
         productComplex        |-> productComplex.value,
         tradePublishIndicator |-> tradePublishIndicator.value,
         instrmtMatchSideId    |-> instrmtMatchSideId.value,
         effectOnBasket        |-> effectOnBasket.value,
         tradeReportText       |-> tradeReportText.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroInstrmtMatchSideGrpComp3 ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      transBkdTime          |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice     |-> [i \in 1 .. 8 |-> 0],
      clearingTradePrice    |-> [i \in 1 .. 8 |-> 0],
      packageId             |-> [i \in 1 .. 4 |-> 0],
      sideMarketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      sideTrdSubTyp         |-> [i \in 1 .. 2 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId    |-> [i \in 1 .. 1 |-> 0],
      effectOnBasket        |-> [i \in 1 .. 1 |-> 0],
      tradeReportText       |-> [i \in 1 .. 20 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmt Match Side Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmtMatchSideGrpComp3 ==
    { ZeroInstrmtMatchSideGrpComp3 }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.clearingTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.sideMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.sideTrdSubTyp = one] : one \in Sample(2) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.effectOnBasket = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroInstrmtMatchSideGrpComp3 EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmt Match Side Grp Comp, written one after another *)
RECURSIVE EncodeInstrmtMatchSideGrpComp3List(_)
EncodeInstrmtMatchSideGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmtMatchSideGrpComp3(Head(messages)) \o EncodeInstrmtMatchSideGrpComp3List(Tail(messages))

(* As many Instrmt Match Side Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmtMatchSideGrpComp3List(_, _)
ReadInstrmtMatchSideGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmtMatchSideGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmtMatchSideGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmt Match Side Grp Comp of each kind, for the lists that carry them *)
OneInstrmtMatchSideGrpComp3 == { ZeroInstrmtMatchSideGrpComp3 }

(***************************************************************************)
(* Basket Side Alloc Grp Comp: 32 bytes                                    *)
(***************************************************************************)

BasketSideAllocGrpComp3 ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      partySubIdType       : Sample(2),
      side                 : Sample(1),
      instrmtMatchSideId   : Sample(1),
      tradeAllocStatus     : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeBasketSideAllocGrpComp3(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.partySubIdType
        \o message.side
        \o message.instrmtMatchSideId
        \o message.tradeAllocStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeBasketSideAllocGrpComp3(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET partySubIdType == ReadBytes(individualAllocId.rest, 2) IN IF ~partySubIdType.ok THEN Fail ELSE
    LET side == ReadBytes(partySubIdType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET instrmtMatchSideId == ReadBytes(side.rest, 1) IN IF ~instrmtMatchSideId.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(instrmtMatchSideId.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tradeAllocStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         partySubIdType       |-> partySubIdType.value,
         side                 |-> side.value,
         instrmtMatchSideId   |-> instrmtMatchSideId.value,
         tradeAllocStatus     |-> tradeAllocStatus.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroBasketSideAllocGrpComp3 ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      partySubIdType       |-> [i \in 1 .. 2 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      instrmtMatchSideId   |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus     |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Basket Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedBasketSideAllocGrpComp3 ==
    { ZeroBasketSideAllocGrpComp3 }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.partySubIdType = one] : one \in Sample(2) }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.instrmtMatchSideId = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroBasketSideAllocGrpComp3 EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Basket Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeBasketSideAllocGrpComp3List(_)
EncodeBasketSideAllocGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBasketSideAllocGrpComp3(Head(messages)) \o EncodeBasketSideAllocGrpComp3List(Tail(messages))

(* As many Basket Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadBasketSideAllocGrpComp3List(_, _)
ReadBasketSideAllocGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBasketSideAllocGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBasketSideAllocGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Basket Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneBasketSideAllocGrpComp3 == { ZeroBasketSideAllocGrpComp3 }

(***************************************************************************)
(* Modify Basket Trade Request                                             *)
(***************************************************************************)

ModifyBasketTradeRequest ==
    [ networkMsgId                      : Sample(8),
      pad2                              : Sample(2),
      requestHeaderComp                 : RequestHeaderComp31,
      basketTrdMatchId                  : Sample(8),
      basketExecId                      : Sample(4),
      marketSegmentId                   : Sample(4),
      maturityMonthYear                 : Sample(4),
      basketProfileId                   : Sample(4),
      trdType                           : Sample(2),
      tradeReportType                   : Sample(1),
      optionalEarlyTerminationIndicator : Sample(1),
      basketTradeReportText             : Sample(20),
      tradeReportId                     : Sample(20),
      basketRootPartyGrpComp            : SampleLists(OneBasketRootPartyGrpComp4),
      instrmtMatchSideGrpComp           : SampleLists(OneInstrmtMatchSideGrpComp3),
      basketSideAllocGrpComp            : SampleLists(OneBasketSideAllocGrpComp3) ]

EncodeModifyBasketTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp31(message.requestHeaderComp)
        \o message.basketTrdMatchId
        \o message.basketExecId
        \o message.marketSegmentId
        \o message.maturityMonthYear
        \o message.basketProfileId
        \o message.trdType
        \o EncodeUIntLE(Len(message.basketSideAllocGrpComp), 2)
        \o message.tradeReportType
        \o EncodeUIntBE(Len(message.basketRootPartyGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrmtMatchSideGrpComp), 1)
        \o message.optionalEarlyTerminationIndicator
        \o message.basketTradeReportText
        \o message.tradeReportId
        \o EncodeBasketRootPartyGrpComp4List(message.basketRootPartyGrpComp)
        \o EncodeInstrmtMatchSideGrpComp3List(message.instrmtMatchSideGrpComp)
        \o EncodeBasketSideAllocGrpComp3List(message.basketSideAllocGrpComp)

DecodeModifyBasketTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp31(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET basketTrdMatchId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~basketTrdMatchId.ok THEN Fail ELSE
    LET basketExecId == ReadBytes(basketTrdMatchId.rest, 4) IN IF ~basketExecId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(basketExecId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(marketSegmentId.rest, 4) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET basketProfileId == ReadBytes(maturityMonthYear.rest, 4) IN IF ~basketProfileId.ok THEN Fail ELSE
    LET trdType == ReadBytes(basketProfileId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET noBasketSideAlloc == ReadUIntLE(trdType.rest, 2) IN IF ~noBasketSideAlloc.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(noBasketSideAlloc.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET noBasketRootPartyGrps == ReadUIntBE(tradeReportType.rest, 1) IN IF ~noBasketRootPartyGrps.ok THEN Fail ELSE
    LET noInstrmtMatchSides == ReadUIntBE(noBasketRootPartyGrps.rest, 1) IN IF ~noInstrmtMatchSides.ok THEN Fail ELSE
    LET optionalEarlyTerminationIndicator == ReadBytes(noInstrmtMatchSides.rest, 1) IN IF ~optionalEarlyTerminationIndicator.ok THEN Fail ELSE
    LET basketTradeReportText == ReadBytes(optionalEarlyTerminationIndicator.rest, 20) IN IF ~basketTradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(basketTradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET basketRootPartyGrpComp == ReadBasketRootPartyGrpComp4List(tradeReportId.rest, noBasketRootPartyGrps.value) IN IF ~basketRootPartyGrpComp.ok THEN Fail ELSE
    LET instrmtMatchSideGrpComp == ReadInstrmtMatchSideGrpComp3List(basketRootPartyGrpComp.rest, noInstrmtMatchSides.value) IN IF ~instrmtMatchSideGrpComp.ok THEN Fail ELSE
    LET basketSideAllocGrpComp == ReadBasketSideAllocGrpComp3List(instrmtMatchSideGrpComp.rest, noBasketSideAlloc.value) IN IF ~basketSideAllocGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                      |-> networkMsgId.value,
         pad2                              |-> pad2.value,
         requestHeaderComp                 |-> requestHeaderComp.value,
         basketTrdMatchId                  |-> basketTrdMatchId.value,
         basketExecId                      |-> basketExecId.value,
         marketSegmentId                   |-> marketSegmentId.value,
         maturityMonthYear                 |-> maturityMonthYear.value,
         basketProfileId                   |-> basketProfileId.value,
         trdType                           |-> trdType.value,
         tradeReportType                   |-> tradeReportType.value,
         optionalEarlyTerminationIndicator |-> optionalEarlyTerminationIndicator.value,
         basketTradeReportText             |-> basketTradeReportText.value,
         tradeReportId                     |-> tradeReportId.value,
         basketRootPartyGrpComp            |-> basketRootPartyGrpComp.value,
         instrmtMatchSideGrpComp           |-> instrmtMatchSideGrpComp.value,
         basketSideAllocGrpComp            |-> basketSideAllocGrpComp.value ], basketSideAllocGrpComp.rest)

ZeroModifyBasketTradeRequest ==
    [ networkMsgId                      |-> [i \in 1 .. 8 |-> 0],
      pad2                              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                 |-> ZeroRequestHeaderComp31,
      basketTrdMatchId                  |-> [i \in 1 .. 8 |-> 0],
      basketExecId                      |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      maturityMonthYear                 |-> [i \in 1 .. 4 |-> 0],
      basketProfileId                   |-> [i \in 1 .. 4 |-> 0],
      trdType                           |-> [i \in 1 .. 2 |-> 0],
      tradeReportType                   |-> [i \in 1 .. 1 |-> 0],
      optionalEarlyTerminationIndicator |-> [i \in 1 .. 1 |-> 0],
      basketTradeReportText             |-> [i \in 1 .. 20 |-> 0],
      tradeReportId                     |-> [i \in 1 .. 20 |-> 0],
      basketRootPartyGrpComp            |-> << >>,
      instrmtMatchSideGrpComp           |-> << >>,
      basketSideAllocGrpComp            |-> << >> ]

(* Modify Basket Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyBasketTradeRequest ==
    { ZeroModifyBasketTradeRequest }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp31 }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.basketTrdMatchId = one] : one \in Sample(8) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.basketExecId = one] : one \in Sample(4) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.maturityMonthYear = one] : one \in Sample(4) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.basketProfileId = one] : one \in Sample(4) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.optionalEarlyTerminationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.basketTradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.basketRootPartyGrpComp = one] : one \in SampleLists(OneBasketRootPartyGrpComp4) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.instrmtMatchSideGrpComp = one] : one \in SampleLists(OneInstrmtMatchSideGrpComp3) }
        \cup { [ZeroModifyBasketTradeRequest EXCEPT !.basketSideAllocGrpComp = one] : one \in SampleLists(OneBasketSideAllocGrpComp3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp32 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp32(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp32(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp32 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp32 ==
    { ZeroRequestHeaderComp32 }
        \cup { [ZeroRequestHeaderComp32 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp32 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg Ord Grp Comp: 8 bytes                                               *)
(***************************************************************************)

LegOrdGrpComp ==
    [ legAccount        : Sample(2),
      legPositionEffect : Sample(1),
      pad5              : Sample(5) ]

EncodeLegOrdGrpComp(message) ==
    message.legAccount
        \o message.legPositionEffect
        \o message.pad5

DecodeLegOrdGrpComp(bytes) ==
    LET legAccount == ReadBytes(bytes, 2) IN IF ~legAccount.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legAccount.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    LET pad5 == ReadBytes(legPositionEffect.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ legAccount        |-> legAccount.value,
         legPositionEffect |-> legPositionEffect.value,
         pad5              |-> pad5.value ], pad5.rest)

ZeroLegOrdGrpComp ==
    [ legAccount        |-> [i \in 1 .. 2 |-> 0],
      legPositionEffect |-> [i \in 1 .. 1 |-> 0],
      pad5              |-> [i \in 1 .. 5 |-> 0] ]

(* Leg Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedLegOrdGrpComp ==
    { ZeroLegOrdGrpComp }
        \cup { [ZeroLegOrdGrpComp EXCEPT !.legAccount = one] : one \in Sample(2) }
        \cup { [ZeroLegOrdGrpComp EXCEPT !.legPositionEffect = one] : one \in Sample(1) }
        \cup { [ZeroLegOrdGrpComp EXCEPT !.pad5 = one] : one \in Sample(5) }

(* A run of Leg Ord Grp Comp, written one after another *)
RECURSIVE EncodeLegOrdGrpCompList(_)
EncodeLegOrdGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegOrdGrpComp(Head(messages)) \o EncodeLegOrdGrpCompList(Tail(messages))

(* As many Leg Ord Grp Comp as the field that counts them says *)
RECURSIVE ReadLegOrdGrpCompList(_, _)
ReadLegOrdGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegOrdGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegOrdGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Ord Grp Comp of each kind, for the lists that carry them *)
OneLegOrdGrpComp == { ZeroLegOrdGrpComp }

(***************************************************************************)
(* Modify Order Request                                                    *)
(***************************************************************************)

ModifyOrderRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp32,
      orderId                                 : Sample(8),
      clOrdId                                 : Sample(8),
      origClOrdId                             : Sample(8),
      stopPx                                  : Sample(8),
      partyIdClientId                         : Sample(8),
      executingTrader                         : Sample(8),
      matchInstCrossId                        : Sample(4),
      expireDate                              : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      tradingSessionSubId                     : Sample(1),
      ownershipIndicator                      : Sample(1),
      applSeqIndicator                        : Sample(1),
      ordType                                 : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdTakeUpTradingFirm                : Sample(5),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdBeneficiary                      : Sample(9),
      account                                 : Sample(2),
      partyIdPositionAccount                  : Sample(32),
      positionEffect                          : Sample(1),
      partyIdLocationId                       : Sample(2),
      custOrderHandlingInst                   : Sample(1),
      complianceText                          : Sample(20),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      fixClOrdId                              : Sample(20),
      partyEndClientIdentification            : Sample(20),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      partyIdInvestmentDecisionMaker          : Sample(8),
      orderAttributeLiquidityProvision        : Sample(1),
      tradingCapacity                         : Sample(1),
      productComplex                          : Sample(1),
      selfMatchPreventionInstruction          : Sample(1),
      crossMatchInstruction                   : Sample(1),
      pad2v1                                  : Sample(2),
      marketSegmentId                         : Sample(4),
      pad4                                    : Sample(4),
      securityId                              : Sample(8),
      orderQty                                : Sample(8),
      price                                   : Sample(8),
      side                                    : Sample(1),
      execInst                                : Sample(1),
      timeInForce                             : Sample(1),
      pad1v1                                  : Sample(1),
      checkSumCorrection                      : Sample(2),
      pad2v2                                  : Sample(2),
      legOrdGrpComp                           : SampleLists(OneLegOrdGrpComp) ]

EncodeModifyOrderRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp32(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.stopPx
        \o message.partyIdClientId
        \o message.executingTrader
        \o message.matchInstCrossId
        \o message.expireDate
        \o message.targetPartyIdSessionId
        \o message.tradingSessionSubId
        \o message.ownershipIndicator
        \o message.applSeqIndicator
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.orderOrigination
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.account
        \o message.partyIdPositionAccount
        \o message.positionEffect
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.fixClOrdId
        \o message.partyEndClientIdentification
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.partyIdInvestmentDecisionMaker
        \o message.orderAttributeLiquidityProvision
        \o message.tradingCapacity
        \o message.productComplex
        \o message.selfMatchPreventionInstruction
        \o message.crossMatchInstruction
        \o EncodeUIntBE(Len(message.legOrdGrpComp), 1)
        \o message.pad2v1
        \o message.marketSegmentId
        \o message.pad4
        \o message.securityId
        \o message.orderQty
        \o message.price
        \o message.side
        \o message.execInst
        \o message.timeInForce
        \o message.pad1v1
        \o message.checkSumCorrection
        \o message.pad2v2
        \o EncodeLegOrdGrpCompList(message.legOrdGrpComp)

DecodeModifyOrderRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp32(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(origClOrdId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(stopPx.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdClientId.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(executingTrader.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(matchInstCrossId.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(expireDate.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET ownershipIndicator == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~ownershipIndicator.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(ownershipIndicator.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET ordType == ReadBytes(applSeqIndicator.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(orderOrigination.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET account == ReadBytes(partyIdBeneficiary.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(account.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(partyIdPositionAccount.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(positionEffect.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(complianceText.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(freeText3.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET partyEndClientIdentification == ReadBytes(fixClOrdId.rest, 20) IN IF ~partyEndClientIdentification.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyEndClientIdentification.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(partyIdInvestmentDecisionMaker.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET productComplex == ReadBytes(tradingCapacity.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(productComplex.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET crossMatchInstruction == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~crossMatchInstruction.ok THEN Fail ELSE
    LET noLegOnbooks == ReadUIntBE(crossMatchInstruction.rest, 1) IN IF ~noLegOnbooks.ok THEN Fail ELSE
    LET pad2v1 == ReadBytes(noLegOnbooks.rest, 2) IN IF ~pad2v1.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(pad2v1.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(marketSegmentId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET securityId == ReadBytes(pad4.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET execInst == ReadBytes(side.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(execInst.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET pad1v1 == ReadBytes(timeInForce.rest, 1) IN IF ~pad1v1.ok THEN Fail ELSE
    LET checkSumCorrection == ReadBytes(pad1v1.rest, 2) IN IF ~checkSumCorrection.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(checkSumCorrection.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET legOrdGrpComp == ReadLegOrdGrpCompList(pad2v2.rest, noLegOnbooks.value) IN IF ~legOrdGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         orderId                                 |-> orderId.value,
         clOrdId                                 |-> clOrdId.value,
         origClOrdId                             |-> origClOrdId.value,
         stopPx                                  |-> stopPx.value,
         partyIdClientId                         |-> partyIdClientId.value,
         executingTrader                         |-> executingTrader.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         expireDate                              |-> expireDate.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         tradingSessionSubId                     |-> tradingSessionSubId.value,
         ownershipIndicator                      |-> ownershipIndicator.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         ordType                                 |-> ordType.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         account                                 |-> account.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         positionEffect                          |-> positionEffect.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         complianceText                          |-> complianceText.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         fixClOrdId                              |-> fixClOrdId.value,
         partyEndClientIdentification            |-> partyEndClientIdentification.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         tradingCapacity                         |-> tradingCapacity.value,
         productComplex                          |-> productComplex.value,
         selfMatchPreventionInstruction          |-> selfMatchPreventionInstruction.value,
         crossMatchInstruction                   |-> crossMatchInstruction.value,
         pad2v1                                  |-> pad2v1.value,
         marketSegmentId                         |-> marketSegmentId.value,
         pad4                                    |-> pad4.value,
         securityId                              |-> securityId.value,
         orderQty                                |-> orderQty.value,
         price                                   |-> price.value,
         side                                    |-> side.value,
         execInst                                |-> execInst.value,
         timeInForce                             |-> timeInForce.value,
         pad1v1                                  |-> pad1v1.value,
         checkSumCorrection                      |-> checkSumCorrection.value,
         pad2v2                                  |-> pad2v2.value,
         legOrdGrpComp                           |-> legOrdGrpComp.value ], legOrdGrpComp.rest)

ZeroModifyOrderRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp32,
      orderId                                 |-> [i \in 1 .. 8 |-> 0],
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                             |-> [i \in 1 .. 8 |-> 0],
      stopPx                                  |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      expireDate                              |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      tradingSessionSubId                     |-> [i \in 1 .. 1 |-> 0],
      ownershipIndicator                      |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      ordType                                 |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      fixClOrdId                              |-> [i \in 1 .. 20 |-> 0],
      partyEndClientIdentification            |-> [i \in 1 .. 20 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      productComplex                          |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction          |-> [i \in 1 .. 1 |-> 0],
      crossMatchInstruction                   |-> [i \in 1 .. 1 |-> 0],
      pad2v1                                  |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      pad4                                    |-> [i \in 1 .. 4 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      pad1v1                                  |-> [i \in 1 .. 1 |-> 0],
      checkSumCorrection                      |-> [i \in 1 .. 2 |-> 0],
      pad2v2                                  |-> [i \in 1 .. 2 |-> 0],
      legOrdGrpComp                           |-> << >> ]

(* Modify Order Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderRequest ==
    { ZeroModifyOrderRequest }
        \cup { [ZeroModifyOrderRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp32 }
        \cup { [ZeroModifyOrderRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.ownershipIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyEndClientIdentification = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.crossMatchInstruction = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.pad2v1 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.pad1v1 = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.checkSumCorrection = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderRequest EXCEPT !.legOrdGrpComp = one] : one \in SampleLists(OneLegOrdGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp33 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp33(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp33(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp33 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp33 ==
    { ZeroRequestHeaderComp33 }
        \cup { [ZeroRequestHeaderComp33 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp33 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Short Request: 138 bytes                                   *)
(***************************************************************************)

ModifyOrderShortRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp33,
      clOrdId                                 : Sample(8),
      origClOrdId                             : Sample(8),
      partyIdClientId                         : Sample(8),
      executingTrader                         : Sample(8),
      matchInstCrossId                        : Sample(4),
      applSeqIndicator                        : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      tradingCapacity                         : Sample(1),
      orderOrigination                        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      complianceText                          : Sample(20),
      pad1                                    : Sample(1),
      partyIdInvestmentDecisionMaker          : Sample(8),
      enrichmentRuleId                        : Sample(2),
      orderAttributeLiquidityProvision        : Sample(1),
      productComplex                          : Sample(1),
      selfMatchPreventionInstruction          : Sample(1),
      crossMatchInstruction                   : Sample(1),
      pad2v1                                  : Sample(2),
      marketSegmentId                         : Sample(4),
      pad4v1                                  : Sample(4),
      securityId                              : Sample(8),
      orderQty                                : Sample(8),
      price                                   : Sample(8),
      side                                    : Sample(1),
      execInst                                : Sample(1),
      timeInForce                             : Sample(1),
      pad1v1                                  : Sample(1),
      checkSumCorrection                      : Sample(2),
      pad2v2                                  : Sample(2) ]

EncodeModifyOrderShortRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp33(message.requestHeaderComp)
        \o message.clOrdId
        \o message.origClOrdId
        \o message.partyIdClientId
        \o message.executingTrader
        \o message.matchInstCrossId
        \o message.applSeqIndicator
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.tradingCapacity
        \o message.orderOrigination
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.complianceText
        \o message.pad1
        \o message.partyIdInvestmentDecisionMaker
        \o message.enrichmentRuleId
        \o message.orderAttributeLiquidityProvision
        \o message.productComplex
        \o message.selfMatchPreventionInstruction
        \o message.crossMatchInstruction
        \o message.pad2v1
        \o message.marketSegmentId
        \o message.pad4v1
        \o message.securityId
        \o message.orderQty
        \o message.price
        \o message.side
        \o message.execInst
        \o message.timeInForce
        \o message.pad1v1
        \o message.checkSumCorrection
        \o message.pad2v2

DecodeModifyOrderShortRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp33(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(origClOrdId.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdClientId.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(executingTrader.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(matchInstCrossId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(applSeqIndicator.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET complianceText == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad1 == ReadBytes(complianceText.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(pad1.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(partyIdInvestmentDecisionMaker.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET productComplex == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(productComplex.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET crossMatchInstruction == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~crossMatchInstruction.ok THEN Fail ELSE
    LET pad2v1 == ReadBytes(crossMatchInstruction.rest, 2) IN IF ~pad2v1.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(pad2v1.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET pad4v1 == ReadBytes(marketSegmentId.rest, 4) IN IF ~pad4v1.ok THEN Fail ELSE
    LET securityId == ReadBytes(pad4v1.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET execInst == ReadBytes(side.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(execInst.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET pad1v1 == ReadBytes(timeInForce.rest, 1) IN IF ~pad1v1.ok THEN Fail ELSE
    LET checkSumCorrection == ReadBytes(pad1v1.rest, 2) IN IF ~checkSumCorrection.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(checkSumCorrection.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         clOrdId                                 |-> clOrdId.value,
         origClOrdId                             |-> origClOrdId.value,
         partyIdClientId                         |-> partyIdClientId.value,
         executingTrader                         |-> executingTrader.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderOrigination                        |-> orderOrigination.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         complianceText                          |-> complianceText.value,
         pad1                                    |-> pad1.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         enrichmentRuleId                        |-> enrichmentRuleId.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         productComplex                          |-> productComplex.value,
         selfMatchPreventionInstruction          |-> selfMatchPreventionInstruction.value,
         crossMatchInstruction                   |-> crossMatchInstruction.value,
         pad2v1                                  |-> pad2v1.value,
         marketSegmentId                         |-> marketSegmentId.value,
         pad4v1                                  |-> pad4v1.value,
         securityId                              |-> securityId.value,
         orderQty                                |-> orderQty.value,
         price                                   |-> price.value,
         side                                    |-> side.value,
         execInst                                |-> execInst.value,
         timeInForce                             |-> timeInForce.value,
         pad1v1                                  |-> pad1v1.value,
         checkSumCorrection                      |-> checkSumCorrection.value,
         pad2v2                                  |-> pad2v2.value ], pad2v2.rest)

ZeroModifyOrderShortRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp33,
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                             |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      pad1                                    |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      enrichmentRuleId                        |-> [i \in 1 .. 2 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      productComplex                          |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction          |-> [i \in 1 .. 1 |-> 0],
      crossMatchInstruction                   |-> [i \in 1 .. 1 |-> 0],
      pad2v1                                  |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      pad4v1                                  |-> [i \in 1 .. 4 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      pad1v1                                  |-> [i \in 1 .. 1 |-> 0],
      checkSumCorrection                      |-> [i \in 1 .. 2 |-> 0],
      pad2v2                                  |-> [i \in 1 .. 2 |-> 0] ]

(* Modify Order Short Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderShortRequest ==
    { ZeroModifyOrderShortRequest }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp33 }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.crossMatchInstruction = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.pad2v1 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.pad4v1 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.pad1v1 = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.checkSumCorrection = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp34 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp34(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp34(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp34 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp34 ==
    { ZeroRequestHeaderComp34 }
        \cup { [ZeroRequestHeaderComp34 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp34 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Side Alloc Grp Comp: 32 bytes                                           *)
(***************************************************************************)

SideAllocGrpComp2 ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      tesEnrichmentRuleId  : Sample(4),
      side                 : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeSideAllocGrpComp2(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.tesEnrichmentRuleId
        \o message.side
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeSideAllocGrpComp2(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET tesEnrichmentRuleId == ReadBytes(individualAllocId.rest, 4) IN IF ~tesEnrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(tesEnrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         tesEnrichmentRuleId  |-> tesEnrichmentRuleId.value,
         side                 |-> side.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroSideAllocGrpComp2 ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      tesEnrichmentRuleId  |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocGrpComp2 ==
    { ZeroSideAllocGrpComp2 }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.tesEnrichmentRuleId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeSideAllocGrpComp2List(_)
EncodeSideAllocGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSideAllocGrpComp2(Head(messages)) \o EncodeSideAllocGrpComp2List(Tail(messages))

(* As many Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadSideAllocGrpComp2List(_, _)
ReadSideAllocGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSideAllocGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSideAllocGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneSideAllocGrpComp2 == { ZeroSideAllocGrpComp2 }

(***************************************************************************)
(* Trd Instrmnt Leg Grp Comp: 24 bytes                                     *)
(***************************************************************************)

TrdInstrmntLegGrpComp2 ==
    [ legSecurityId : Sample(8),
      legPrice      : Sample(8),
      legQty        : Sample(8) ]

EncodeTrdInstrmntLegGrpComp2(message) ==
    message.legSecurityId
        \o message.legPrice
        \o message.legQty

DecodeTrdInstrmntLegGrpComp2(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSecurityId.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legQty == ReadBytes(legPrice.rest, 8) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legPrice      |-> legPrice.value,
         legQty        |-> legQty.value ], legQty.rest)

ZeroTrdInstrmntLegGrpComp2 ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legPrice      |-> [i \in 1 .. 8 |-> 0],
      legQty        |-> [i \in 1 .. 8 |-> 0] ]

(* Trd Instrmnt Leg Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedTrdInstrmntLegGrpComp2 ==
    { ZeroTrdInstrmntLegGrpComp2 }
        \cup { [ZeroTrdInstrmntLegGrpComp2 EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroTrdInstrmntLegGrpComp2 EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroTrdInstrmntLegGrpComp2 EXCEPT !.legQty = one] : one \in Sample(8) }

(* A run of Trd Instrmnt Leg Grp Comp, written one after another *)
RECURSIVE EncodeTrdInstrmntLegGrpComp2List(_)
EncodeTrdInstrmntLegGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTrdInstrmntLegGrpComp2(Head(messages)) \o EncodeTrdInstrmntLegGrpComp2List(Tail(messages))

(* As many Trd Instrmnt Leg Grp Comp as the field that counts them says *)
RECURSIVE ReadTrdInstrmntLegGrpComp2List(_, _)
ReadTrdInstrmntLegGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTrdInstrmntLegGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTrdInstrmntLegGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trd Instrmnt Leg Grp Comp of each kind, for the lists that carry them *)
OneTrdInstrmntLegGrpComp2 == { ZeroTrdInstrmntLegGrpComp2 }

(***************************************************************************)
(* Modify Tes Trade Request                                                *)
(***************************************************************************)

ModifyTesTradeRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp34,
      lastPx                 : Sample(8),
      transBkdTime           : Sample(8),
      relatedClosePrice      : Sample(8),
      marketSegmentId        : Sample(4),
      packageId              : Sample(4),
      tesExecId              : Sample(4),
      relatedMarketSegmentId : Sample(4),
      trdType                : Sample(2),
      tradeReportType        : Sample(1),
      tradePublishIndicator  : Sample(1),
      swapClearer            : Sample(1),
      tradeReportText        : Sample(20),
      tradeReportId          : Sample(20),
      pad1                   : Sample(1),
      sideAllocGrpComp       : SampleLists(OneSideAllocGrpComp2),
      trdInstrmntLegGrpComp  : SampleLists(OneTrdInstrmntLegGrpComp2) ]

EncodeModifyTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp34(message.requestHeaderComp)
        \o message.lastPx
        \o message.transBkdTime
        \o message.relatedClosePrice
        \o message.marketSegmentId
        \o message.packageId
        \o message.tesExecId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.tradeReportType
        \o message.tradePublishIndicator
        \o EncodeUIntBE(Len(message.sideAllocGrpComp), 1)
        \o EncodeUIntBE(Len(message.trdInstrmntLegGrpComp), 1)
        \o message.swapClearer
        \o message.tradeReportText
        \o message.tradeReportId
        \o message.pad1
        \o EncodeSideAllocGrpComp2List(message.sideAllocGrpComp)
        \o EncodeTrdInstrmntLegGrpComp2List(message.trdInstrmntLegGrpComp)

DecodeModifyTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp34(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastPx == ReadBytes(requestHeaderComp.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(transBkdTime.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(relatedClosePrice.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(packageId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(tradeReportType.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradePublishIndicator.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(noSideAllocs.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET swapClearer == ReadBytes(noLegs.rest, 1) IN IF ~swapClearer.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(swapClearer.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(tradeReportId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET sideAllocGrpComp == ReadSideAllocGrpComp2List(pad1.rest, noSideAllocs.value) IN IF ~sideAllocGrpComp.ok THEN Fail ELSE
    LET trdInstrmntLegGrpComp == ReadTrdInstrmntLegGrpComp2List(sideAllocGrpComp.rest, noLegs.value) IN IF ~trdInstrmntLegGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         lastPx                 |-> lastPx.value,
         transBkdTime           |-> transBkdTime.value,
         relatedClosePrice      |-> relatedClosePrice.value,
         marketSegmentId        |-> marketSegmentId.value,
         packageId              |-> packageId.value,
         tesExecId              |-> tesExecId.value,
         relatedMarketSegmentId |-> relatedMarketSegmentId.value,
         trdType                |-> trdType.value,
         tradeReportType        |-> tradeReportType.value,
         tradePublishIndicator  |-> tradePublishIndicator.value,
         swapClearer            |-> swapClearer.value,
         tradeReportText        |-> tradeReportText.value,
         tradeReportId          |-> tradeReportId.value,
         pad1                   |-> pad1.value,
         sideAllocGrpComp       |-> sideAllocGrpComp.value,
         trdInstrmntLegGrpComp  |-> trdInstrmntLegGrpComp.value ], trdInstrmntLegGrpComp.rest)

ZeroModifyTesTradeRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp34,
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      transBkdTime           |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      packageId              |-> [i \in 1 .. 4 |-> 0],
      tesExecId              |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId |-> [i \in 1 .. 4 |-> 0],
      trdType                |-> [i \in 1 .. 2 |-> 0],
      tradeReportType        |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator  |-> [i \in 1 .. 1 |-> 0],
      swapClearer            |-> [i \in 1 .. 1 |-> 0],
      tradeReportText        |-> [i \in 1 .. 20 |-> 0],
      tradeReportId          |-> [i \in 1 .. 20 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0],
      sideAllocGrpComp       |-> << >>,
      trdInstrmntLegGrpComp  |-> << >> ]

(* Modify Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyTesTradeRequest ==
    { ZeroModifyTesTradeRequest }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp34 }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.swapClearer = one] : one \in Sample(1) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.sideAllocGrpComp = one] : one \in SampleLists(OneSideAllocGrpComp2) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.trdInstrmntLegGrpComp = one] : one \in SampleLists(OneTrdInstrmntLegGrpComp2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp35 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp35(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp35(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp35 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp35 ==
    { ZeroRequestHeaderComp35 }
        \cup { [ZeroRequestHeaderComp35 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp35 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg Ord Grp Comp: 8 bytes                                               *)
(***************************************************************************)

LegOrdGrpComp2 ==
    [ legAccount        : Sample(2),
      legPositionEffect : Sample(1),
      pad5              : Sample(5) ]

EncodeLegOrdGrpComp2(message) ==
    message.legAccount
        \o message.legPositionEffect
        \o message.pad5

DecodeLegOrdGrpComp2(bytes) ==
    LET legAccount == ReadBytes(bytes, 2) IN IF ~legAccount.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legAccount.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    LET pad5 == ReadBytes(legPositionEffect.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ legAccount        |-> legAccount.value,
         legPositionEffect |-> legPositionEffect.value,
         pad5              |-> pad5.value ], pad5.rest)

ZeroLegOrdGrpComp2 ==
    [ legAccount        |-> [i \in 1 .. 2 |-> 0],
      legPositionEffect |-> [i \in 1 .. 1 |-> 0],
      pad5              |-> [i \in 1 .. 5 |-> 0] ]

(* Leg Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedLegOrdGrpComp2 ==
    { ZeroLegOrdGrpComp2 }
        \cup { [ZeroLegOrdGrpComp2 EXCEPT !.legAccount = one] : one \in Sample(2) }
        \cup { [ZeroLegOrdGrpComp2 EXCEPT !.legPositionEffect = one] : one \in Sample(1) }
        \cup { [ZeroLegOrdGrpComp2 EXCEPT !.pad5 = one] : one \in Sample(5) }

(* A run of Leg Ord Grp Comp, written one after another *)
RECURSIVE EncodeLegOrdGrpComp2List(_)
EncodeLegOrdGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegOrdGrpComp2(Head(messages)) \o EncodeLegOrdGrpComp2List(Tail(messages))

(* As many Leg Ord Grp Comp as the field that counts them says *)
RECURSIVE ReadLegOrdGrpComp2List(_, _)
ReadLegOrdGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegOrdGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegOrdGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Ord Grp Comp of each kind, for the lists that carry them *)
OneLegOrdGrpComp2 == { ZeroLegOrdGrpComp2 }

(***************************************************************************)
(* New Order Request                                                       *)
(***************************************************************************)

NewOrderRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp35,
      clOrdId                                 : Sample(8),
      stopPx                                  : Sample(8),
      partyIdClientId                         : Sample(8),
      executingTrader                         : Sample(8),
      matchInstCrossId                        : Sample(4),
      expireDate                              : Sample(4),
      tradingSessionSubId                     : Sample(1),
      selfMatchPreventionInstruction          : Sample(1),
      crossMatchInstruction                   : Sample(1),
      applSeqIndicator                        : Sample(1),
      ordType                                 : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdTakeUpTradingFirm                : Sample(5),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdBeneficiary                      : Sample(9),
      account                                 : Sample(2),
      partyIdPositionAccount                  : Sample(32),
      positionEffect                          : Sample(1),
      partyIdLocationId                       : Sample(2),
      custOrderHandlingInst                   : Sample(1),
      complianceText                          : Sample(20),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      fixClOrdId                              : Sample(20),
      partyEndClientIdentification            : Sample(20),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      orderAttributeRiskReduction             : Sample(1),
      pad2v2                                  : Sample(2),
      partyIdInvestmentDecisionMaker          : Sample(8),
      orderAttributeLiquidityProvision        : Sample(1),
      tradingCapacity                         : Sample(1),
      productComplex                          : Sample(1),
      marketSegmentId                         : Sample(4),
      securityId                              : Sample(8),
      orderQty                                : Sample(8),
      price                                   : Sample(8),
      side                                    : Sample(1),
      execInst                                : Sample(1),
      timeInForce                             : Sample(1),
      pad1                                    : Sample(1),
      checkSumCorrection                      : Sample(2),
      pad2v3                                  : Sample(2),
      legOrdGrpComp                           : SampleLists(OneLegOrdGrpComp2) ]

EncodeNewOrderRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp35(message.requestHeaderComp)
        \o message.clOrdId
        \o message.stopPx
        \o message.partyIdClientId
        \o message.executingTrader
        \o message.matchInstCrossId
        \o message.expireDate
        \o message.tradingSessionSubId
        \o message.selfMatchPreventionInstruction
        \o message.crossMatchInstruction
        \o message.applSeqIndicator
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.orderOrigination
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.account
        \o message.partyIdPositionAccount
        \o message.positionEffect
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.fixClOrdId
        \o message.partyEndClientIdentification
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.orderAttributeRiskReduction
        \o message.pad2v2
        \o message.partyIdInvestmentDecisionMaker
        \o message.orderAttributeLiquidityProvision
        \o message.tradingCapacity
        \o message.productComplex
        \o EncodeUIntBE(Len(message.legOrdGrpComp), 1)
        \o message.marketSegmentId
        \o message.securityId
        \o message.orderQty
        \o message.price
        \o message.side
        \o message.execInst
        \o message.timeInForce
        \o message.pad1
        \o message.checkSumCorrection
        \o message.pad2v3
        \o EncodeLegOrdGrpComp2List(message.legOrdGrpComp)

DecodeNewOrderRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp35(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(clOrdId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(stopPx.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdClientId.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(executingTrader.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(matchInstCrossId.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(expireDate.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET crossMatchInstruction == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~crossMatchInstruction.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(crossMatchInstruction.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET ordType == ReadBytes(applSeqIndicator.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(orderOrigination.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET account == ReadBytes(partyIdBeneficiary.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(account.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(partyIdPositionAccount.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(positionEffect.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(complianceText.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(freeText3.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET partyEndClientIdentification == ReadBytes(fixClOrdId.rest, 20) IN IF ~partyEndClientIdentification.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyEndClientIdentification.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET orderAttributeRiskReduction == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~orderAttributeRiskReduction.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(orderAttributeRiskReduction.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(pad2v2.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(partyIdInvestmentDecisionMaker.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET productComplex == ReadBytes(tradingCapacity.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET noLegOnbooks == ReadUIntBE(productComplex.rest, 1) IN IF ~noLegOnbooks.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(noLegOnbooks.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET securityId == ReadBytes(marketSegmentId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET execInst == ReadBytes(side.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(execInst.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET pad1 == ReadBytes(timeInForce.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET checkSumCorrection == ReadBytes(pad1.rest, 2) IN IF ~checkSumCorrection.ok THEN Fail ELSE
    LET pad2v3 == ReadBytes(checkSumCorrection.rest, 2) IN IF ~pad2v3.ok THEN Fail ELSE
    LET legOrdGrpComp == ReadLegOrdGrpComp2List(pad2v3.rest, noLegOnbooks.value) IN IF ~legOrdGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         clOrdId                                 |-> clOrdId.value,
         stopPx                                  |-> stopPx.value,
         partyIdClientId                         |-> partyIdClientId.value,
         executingTrader                         |-> executingTrader.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         expireDate                              |-> expireDate.value,
         tradingSessionSubId                     |-> tradingSessionSubId.value,
         selfMatchPreventionInstruction          |-> selfMatchPreventionInstruction.value,
         crossMatchInstruction                   |-> crossMatchInstruction.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         ordType                                 |-> ordType.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         account                                 |-> account.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         positionEffect                          |-> positionEffect.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         complianceText                          |-> complianceText.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         fixClOrdId                              |-> fixClOrdId.value,
         partyEndClientIdentification            |-> partyEndClientIdentification.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         orderAttributeRiskReduction             |-> orderAttributeRiskReduction.value,
         pad2v2                                  |-> pad2v2.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         tradingCapacity                         |-> tradingCapacity.value,
         productComplex                          |-> productComplex.value,
         marketSegmentId                         |-> marketSegmentId.value,
         securityId                              |-> securityId.value,
         orderQty                                |-> orderQty.value,
         price                                   |-> price.value,
         side                                    |-> side.value,
         execInst                                |-> execInst.value,
         timeInForce                             |-> timeInForce.value,
         pad1                                    |-> pad1.value,
         checkSumCorrection                      |-> checkSumCorrection.value,
         pad2v3                                  |-> pad2v3.value,
         legOrdGrpComp                           |-> legOrdGrpComp.value ], legOrdGrpComp.rest)

ZeroNewOrderRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp35,
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      stopPx                                  |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      expireDate                              |-> [i \in 1 .. 4 |-> 0],
      tradingSessionSubId                     |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction          |-> [i \in 1 .. 1 |-> 0],
      crossMatchInstruction                   |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      ordType                                 |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      fixClOrdId                              |-> [i \in 1 .. 20 |-> 0],
      partyEndClientIdentification            |-> [i \in 1 .. 20 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      orderAttributeRiskReduction             |-> [i \in 1 .. 1 |-> 0],
      pad2v2                                  |-> [i \in 1 .. 2 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      productComplex                          |-> [i \in 1 .. 1 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      pad1                                    |-> [i \in 1 .. 1 |-> 0],
      checkSumCorrection                      |-> [i \in 1 .. 2 |-> 0],
      pad2v3                                  |-> [i \in 1 .. 2 |-> 0],
      legOrdGrpComp                           |-> << >> ]

(* New Order Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderRequest ==
    { ZeroNewOrderRequest }
        \cup { [ZeroNewOrderRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp35 }
        \cup { [ZeroNewOrderRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequest EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.crossMatchInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroNewOrderRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderRequest EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyEndClientIdentification = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.orderAttributeRiskReduction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequest EXCEPT !.checkSumCorrection = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequest EXCEPT !.pad2v3 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequest EXCEPT !.legOrdGrpComp = one] : one \in SampleLists(OneLegOrdGrpComp2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp36 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp36(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp36(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp36 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp36 ==
    { ZeroRequestHeaderComp36 }
        \cup { [ZeroRequestHeaderComp36 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp36 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* New Order Short Request: 130 bytes                                      *)
(***************************************************************************)

NewOrderShortRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp36,
      clOrdId                                 : Sample(8),
      partyIdClientId                         : Sample(8),
      executingTrader                         : Sample(8),
      matchInstCrossId                        : Sample(4),
      applSeqIndicator                        : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      tradingCapacity                         : Sample(1),
      orderOrigination                        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      complianceText                          : Sample(20),
      pad1                                    : Sample(1),
      partyIdInvestmentDecisionMaker          : Sample(8),
      enrichmentRuleId                        : Sample(2),
      orderAttributeLiquidityProvision        : Sample(1),
      productComplex                          : Sample(1),
      selfMatchPreventionInstruction          : Sample(1),
      crossMatchInstruction                   : Sample(1),
      pad2v1                                  : Sample(2),
      marketSegmentId                         : Sample(4),
      pad4v1                                  : Sample(4),
      securityId                              : Sample(8),
      orderQty                                : Sample(8),
      price                                   : Sample(8),
      side                                    : Sample(1),
      execInst                                : Sample(1),
      timeInForce                             : Sample(1),
      pad1v1                                  : Sample(1),
      checkSumCorrection                      : Sample(2),
      pad2v2                                  : Sample(2) ]

EncodeNewOrderShortRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp36(message.requestHeaderComp)
        \o message.clOrdId
        \o message.partyIdClientId
        \o message.executingTrader
        \o message.matchInstCrossId
        \o message.applSeqIndicator
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.tradingCapacity
        \o message.orderOrigination
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.complianceText
        \o message.pad1
        \o message.partyIdInvestmentDecisionMaker
        \o message.enrichmentRuleId
        \o message.orderAttributeLiquidityProvision
        \o message.productComplex
        \o message.selfMatchPreventionInstruction
        \o message.crossMatchInstruction
        \o message.pad2v1
        \o message.marketSegmentId
        \o message.pad4v1
        \o message.securityId
        \o message.orderQty
        \o message.price
        \o message.side
        \o message.execInst
        \o message.timeInForce
        \o message.pad1v1
        \o message.checkSumCorrection
        \o message.pad2v2

DecodeNewOrderShortRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp36(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(clOrdId.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdClientId.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(executingTrader.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(matchInstCrossId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(applSeqIndicator.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET complianceText == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad1 == ReadBytes(complianceText.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(pad1.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(partyIdInvestmentDecisionMaker.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET productComplex == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(productComplex.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET crossMatchInstruction == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~crossMatchInstruction.ok THEN Fail ELSE
    LET pad2v1 == ReadBytes(crossMatchInstruction.rest, 2) IN IF ~pad2v1.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(pad2v1.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET pad4v1 == ReadBytes(marketSegmentId.rest, 4) IN IF ~pad4v1.ok THEN Fail ELSE
    LET securityId == ReadBytes(pad4v1.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET execInst == ReadBytes(side.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(execInst.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET pad1v1 == ReadBytes(timeInForce.rest, 1) IN IF ~pad1v1.ok THEN Fail ELSE
    LET checkSumCorrection == ReadBytes(pad1v1.rest, 2) IN IF ~checkSumCorrection.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(checkSumCorrection.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         clOrdId                                 |-> clOrdId.value,
         partyIdClientId                         |-> partyIdClientId.value,
         executingTrader                         |-> executingTrader.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderOrigination                        |-> orderOrigination.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         complianceText                          |-> complianceText.value,
         pad1                                    |-> pad1.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         enrichmentRuleId                        |-> enrichmentRuleId.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         productComplex                          |-> productComplex.value,
         selfMatchPreventionInstruction          |-> selfMatchPreventionInstruction.value,
         crossMatchInstruction                   |-> crossMatchInstruction.value,
         pad2v1                                  |-> pad2v1.value,
         marketSegmentId                         |-> marketSegmentId.value,
         pad4v1                                  |-> pad4v1.value,
         securityId                              |-> securityId.value,
         orderQty                                |-> orderQty.value,
         price                                   |-> price.value,
         side                                    |-> side.value,
         execInst                                |-> execInst.value,
         timeInForce                             |-> timeInForce.value,
         pad1v1                                  |-> pad1v1.value,
         checkSumCorrection                      |-> checkSumCorrection.value,
         pad2v2                                  |-> pad2v2.value ], pad2v2.rest)

ZeroNewOrderShortRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp36,
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      pad1                                    |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      enrichmentRuleId                        |-> [i \in 1 .. 2 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      productComplex                          |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction          |-> [i \in 1 .. 1 |-> 0],
      crossMatchInstruction                   |-> [i \in 1 .. 1 |-> 0],
      pad2v1                                  |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      pad4v1                                  |-> [i \in 1 .. 4 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      pad1v1                                  |-> [i \in 1 .. 1 |-> 0],
      checkSumCorrection                      |-> [i \in 1 .. 2 |-> 0],
      pad2v2                                  |-> [i \in 1 .. 2 |-> 0] ]

(* New Order Short Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderShortRequest ==
    { ZeroNewOrderShortRequest }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp36 }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.crossMatchInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.pad2v1 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.pad4v1 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.pad1v1 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.checkSumCorrection = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderShortRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp37 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp37(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp37(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp37 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp37 ==
    { ZeroRequestHeaderComp37 }
        \cup { [ZeroRequestHeaderComp37 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp37 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Ping Request: 26 bytes                                                  *)
(***************************************************************************)

PingRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp37,
      partitionId       : Sample(2),
      pad6              : Sample(6) ]

EncodePingRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp37(message.requestHeaderComp)
        \o message.partitionId
        \o message.pad6

DecodePingRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp37(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partitionId == ReadBytes(requestHeaderComp.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partitionId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         partitionId       |-> partitionId.value,
         pad6              |-> pad6.value ], pad6.rest)

ZeroPingRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp37,
      partitionId       |-> [i \in 1 .. 2 |-> 0],
      pad6              |-> [i \in 1 .. 6 |-> 0] ]

(* Ping Request at zero, then each field in turn at the values it is checked at *)
CheckedPingRequest ==
    { ZeroPingRequest }
        \cup { [ZeroPingRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroPingRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroPingRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp37 }
        \cup { [ZeroPingRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroPingRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp38 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp38(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp38(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp38 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp38 ==
    { ZeroRequestHeaderComp38 }
        \cup { [ZeroRequestHeaderComp38 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp38 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Risk Limit Qty Grp Comp: 16 bytes                                       *)
(***************************************************************************)

RiskLimitQtyGrpComp ==
    [ riskLimitQty  : Sample(8),
      riskLimitType : Sample(1),
      pad7          : Sample(7) ]

EncodeRiskLimitQtyGrpComp(message) ==
    message.riskLimitQty
        \o message.riskLimitType
        \o message.pad7

DecodeRiskLimitQtyGrpComp(bytes) ==
    LET riskLimitQty == ReadBytes(bytes, 8) IN IF ~riskLimitQty.ok THEN Fail ELSE
    LET riskLimitType == ReadBytes(riskLimitQty.rest, 1) IN IF ~riskLimitType.ok THEN Fail ELSE
    LET pad7 == ReadBytes(riskLimitType.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ riskLimitQty  |-> riskLimitQty.value,
         riskLimitType |-> riskLimitType.value,
         pad7          |-> pad7.value ], pad7.rest)

ZeroRiskLimitQtyGrpComp ==
    [ riskLimitQty  |-> [i \in 1 .. 8 |-> 0],
      riskLimitType |-> [i \in 1 .. 1 |-> 0],
      pad7          |-> [i \in 1 .. 7 |-> 0] ]

(* Risk Limit Qty Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedRiskLimitQtyGrpComp ==
    { ZeroRiskLimitQtyGrpComp }
        \cup { [ZeroRiskLimitQtyGrpComp EXCEPT !.riskLimitQty = one] : one \in Sample(8) }
        \cup { [ZeroRiskLimitQtyGrpComp EXCEPT !.riskLimitType = one] : one \in Sample(1) }
        \cup { [ZeroRiskLimitQtyGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Risk Limit Qty Grp Comp, written one after another *)
RECURSIVE EncodeRiskLimitQtyGrpCompList(_)
EncodeRiskLimitQtyGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRiskLimitQtyGrpComp(Head(messages)) \o EncodeRiskLimitQtyGrpCompList(Tail(messages))

(* As many Risk Limit Qty Grp Comp as the field that counts them says *)
RECURSIVE ReadRiskLimitQtyGrpCompList(_, _)
ReadRiskLimitQtyGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRiskLimitQtyGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRiskLimitQtyGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Risk Limit Qty Grp Comp of each kind, for the lists that carry them *)
OneRiskLimitQtyGrpComp == { ZeroRiskLimitQtyGrpComp }

(***************************************************************************)
(* Pre Trade Risk Limits Definition Request                                *)
(***************************************************************************)

PreTradeRiskLimitsDefinitionRequest ==
    [ networkMsgId             : Sample(8),
      pad2                     : Sample(2),
      requestHeaderComp        : RequestHeaderComp38,
      nettingCoefficient       : Sample(8),
      marketSegmentId          : Sample(4),
      riskLimitPlatform        : Sample(1),
      partyDetailStatus        : Sample(1),
      riskLimitGroupStatus     : Sample(1),
      riskLimitGroup           : Sample(3),
      partyDetailExecutingUnit : Sample(5),
      riskLimitQtyGrpComp      : SampleLists(OneRiskLimitQtyGrpComp) ]

EncodePreTradeRiskLimitsDefinitionRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp38(message.requestHeaderComp)
        \o message.nettingCoefficient
        \o message.marketSegmentId
        \o message.riskLimitPlatform
        \o EncodeUIntBE(Len(message.riskLimitQtyGrpComp), 1)
        \o message.partyDetailStatus
        \o message.riskLimitGroupStatus
        \o message.riskLimitGroup
        \o message.partyDetailExecutingUnit
        \o EncodeRiskLimitQtyGrpCompList(message.riskLimitQtyGrpComp)

DecodePreTradeRiskLimitsDefinitionRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp38(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET nettingCoefficient == ReadBytes(requestHeaderComp.rest, 8) IN IF ~nettingCoefficient.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(nettingCoefficient.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET riskLimitPlatform == ReadBytes(marketSegmentId.rest, 1) IN IF ~riskLimitPlatform.ok THEN Fail ELSE
    LET noRiskLimitsQty == ReadUIntBE(riskLimitPlatform.rest, 1) IN IF ~noRiskLimitsQty.ok THEN Fail ELSE
    LET partyDetailStatus == ReadBytes(noRiskLimitsQty.rest, 1) IN IF ~partyDetailStatus.ok THEN Fail ELSE
    LET riskLimitGroupStatus == ReadBytes(partyDetailStatus.rest, 1) IN IF ~riskLimitGroupStatus.ok THEN Fail ELSE
    LET riskLimitGroup == ReadBytes(riskLimitGroupStatus.rest, 3) IN IF ~riskLimitGroup.ok THEN Fail ELSE
    LET partyDetailExecutingUnit == ReadBytes(riskLimitGroup.rest, 5) IN IF ~partyDetailExecutingUnit.ok THEN Fail ELSE
    LET riskLimitQtyGrpComp == ReadRiskLimitQtyGrpCompList(partyDetailExecutingUnit.rest, noRiskLimitsQty.value) IN IF ~riskLimitQtyGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId             |-> networkMsgId.value,
         pad2                     |-> pad2.value,
         requestHeaderComp        |-> requestHeaderComp.value,
         nettingCoefficient       |-> nettingCoefficient.value,
         marketSegmentId          |-> marketSegmentId.value,
         riskLimitPlatform        |-> riskLimitPlatform.value,
         partyDetailStatus        |-> partyDetailStatus.value,
         riskLimitGroupStatus     |-> riskLimitGroupStatus.value,
         riskLimitGroup           |-> riskLimitGroup.value,
         partyDetailExecutingUnit |-> partyDetailExecutingUnit.value,
         riskLimitQtyGrpComp      |-> riskLimitQtyGrpComp.value ], riskLimitQtyGrpComp.rest)

ZeroPreTradeRiskLimitsDefinitionRequest ==
    [ networkMsgId             |-> [i \in 1 .. 8 |-> 0],
      pad2                     |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp        |-> ZeroRequestHeaderComp38,
      nettingCoefficient       |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      riskLimitPlatform        |-> [i \in 1 .. 1 |-> 0],
      partyDetailStatus        |-> [i \in 1 .. 1 |-> 0],
      riskLimitGroupStatus     |-> [i \in 1 .. 1 |-> 0],
      riskLimitGroup           |-> [i \in 1 .. 3 |-> 0],
      partyDetailExecutingUnit |-> [i \in 1 .. 5 |-> 0],
      riskLimitQtyGrpComp      |-> << >> ]

(* Pre Trade Risk Limits Definition Request at zero, then each field in turn at the values it is checked at *)
CheckedPreTradeRiskLimitsDefinitionRequest ==
    { ZeroPreTradeRiskLimitsDefinitionRequest }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp38 }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.nettingCoefficient = one] : one \in Sample(8) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.riskLimitPlatform = one] : one \in Sample(1) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.partyDetailStatus = one] : one \in Sample(1) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.riskLimitGroupStatus = one] : one \in Sample(1) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.riskLimitGroup = one] : one \in Sample(3) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.partyDetailExecutingUnit = one] : one \in Sample(5) }
        \cup { [ZeroPreTradeRiskLimitsDefinitionRequest EXCEPT !.riskLimitQtyGrpComp = one] : one \in SampleLists(OneRiskLimitQtyGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp39 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp39(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp39(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp39 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp39 ==
    { ZeroRequestHeaderComp39 }
        \cup { [ZeroRequestHeaderComp39 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp39 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Activation Request: 50 bytes                                      *)
(***************************************************************************)

QuoteActivationRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp39,
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      massActionType                          : Sample(1),
      massActionSubType                       : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      pad4                                    : Sample(4) ]

EncodeQuoteActivationRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp39(message.requestHeaderComp)
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.massActionType
        \o message.massActionSubType
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.pad4

DecodeQuoteActivationRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp39(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(requestHeaderComp.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET massActionType == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~massActionType.ok THEN Fail ELSE
    LET massActionSubType == ReadBytes(massActionType.rest, 1) IN IF ~massActionSubType.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(massActionSubType.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET pad4 == ReadBytes(executingTraderQualifier.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         massActionType                          |-> massActionType.value,
         massActionSubType                       |-> massActionSubType.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         pad4                                    |-> pad4.value ], pad4.rest)

ZeroQuoteActivationRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp39,
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      massActionType                          |-> [i \in 1 .. 1 |-> 0],
      massActionSubType                       |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      pad4                                    |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Activation Request at zero, then each field in turn at the values it is checked at *)
CheckedQuoteActivationRequest ==
    { ZeroQuoteActivationRequest }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp39 }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.massActionType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.massActionSubType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp40 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp40(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp40(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp40 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp40 ==
    { ZeroRequestHeaderComp40 }
        \cup { [ZeroRequestHeaderComp40 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp40 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Rfq Request: 66 bytes                                                   *)
(***************************************************************************)

RfqRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp40,
      securityId        : Sample(8),
      orderQty          : Sample(8),
      marketSegmentId   : Sample(4),
      side              : Sample(1),
      complianceText    : Sample(20),
      pad7              : Sample(7) ]

EncodeRfqRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp40(message.requestHeaderComp)
        \o message.securityId
        \o message.orderQty
        \o message.marketSegmentId
        \o message.side
        \o message.complianceText
        \o message.pad7

DecodeRfqRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp40(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET side == ReadBytes(marketSegmentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET complianceText == ReadBytes(side.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad7 == ReadBytes(complianceText.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         securityId        |-> securityId.value,
         orderQty          |-> orderQty.value,
         marketSegmentId   |-> marketSegmentId.value,
         side              |-> side.value,
         complianceText    |-> complianceText.value,
         pad7              |-> pad7.value ], pad7.rest)

ZeroRfqRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp40,
      securityId        |-> [i \in 1 .. 8 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      complianceText    |-> [i \in 1 .. 20 |-> 0],
      pad7              |-> [i \in 1 .. 7 |-> 0] ]

(* Rfq Request at zero, then each field in turn at the values it is checked at *)
CheckedRfqRequest ==
    { ZeroRfqRequest }
        \cup { [ZeroRfqRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp40 }
        \cup { [ZeroRfqRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRfqRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroRfqRequest EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp41 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp41(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp41(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp41 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp41 ==
    { ZeroRequestHeaderComp41 }
        \cup { [ZeroRequestHeaderComp41 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp41 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Me Message Request: 58 bytes                                 *)
(***************************************************************************)

RetransmitMeMessageRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp41,
      subscriptionScope : Sample(4),
      partitionId       : Sample(2),
      refApplId         : Sample(1),
      applBegMsgId      : Sample(16),
      applEndMsgId      : Sample(16),
      pad1              : Sample(1) ]

EncodeRetransmitMeMessageRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp41(message.requestHeaderComp)
        \o message.subscriptionScope
        \o message.partitionId
        \o message.refApplId
        \o message.applBegMsgId
        \o message.applEndMsgId
        \o message.pad1

DecodeRetransmitMeMessageRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp41(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET subscriptionScope == ReadBytes(requestHeaderComp.rest, 4) IN IF ~subscriptionScope.ok THEN Fail ELSE
    LET partitionId == ReadBytes(subscriptionScope.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET refApplId == ReadBytes(partitionId.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET applBegMsgId == ReadBytes(refApplId.rest, 16) IN IF ~applBegMsgId.ok THEN Fail ELSE
    LET applEndMsgId == ReadBytes(applBegMsgId.rest, 16) IN IF ~applEndMsgId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(applEndMsgId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         subscriptionScope |-> subscriptionScope.value,
         partitionId       |-> partitionId.value,
         refApplId         |-> refApplId.value,
         applBegMsgId      |-> applBegMsgId.value,
         applEndMsgId      |-> applEndMsgId.value,
         pad1              |-> pad1.value ], pad1.rest)

ZeroRetransmitMeMessageRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp41,
      subscriptionScope |-> [i \in 1 .. 4 |-> 0],
      partitionId       |-> [i \in 1 .. 2 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      applBegMsgId      |-> [i \in 1 .. 16 |-> 0],
      applEndMsgId      |-> [i \in 1 .. 16 |-> 0],
      pad1              |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Me Message Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitMeMessageRequest ==
    { ZeroRetransmitMeMessageRequest }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp41 }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.applBegMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.applEndMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp42 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp42(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp42(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp42 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp42 ==
    { ZeroRequestHeaderComp42 }
        \cup { [ZeroRequestHeaderComp42 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp42 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Request: 42 bytes                                            *)
(***************************************************************************)

RetransmitRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp42,
      applBegSeqNum     : Sample(8),
      applEndSeqNum     : Sample(8),
      partitionId       : Sample(2),
      refApplId         : Sample(1),
      pad5              : Sample(5) ]

EncodeRetransmitRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp42(message.requestHeaderComp)
        \o message.applBegSeqNum
        \o message.applEndSeqNum
        \o message.partitionId
        \o message.refApplId
        \o message.pad5

DecodeRetransmitRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp42(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET applBegSeqNum == ReadBytes(requestHeaderComp.rest, 8) IN IF ~applBegSeqNum.ok THEN Fail ELSE
    LET applEndSeqNum == ReadBytes(applBegSeqNum.rest, 8) IN IF ~applEndSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applEndSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET refApplId == ReadBytes(partitionId.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET pad5 == ReadBytes(refApplId.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         applBegSeqNum     |-> applBegSeqNum.value,
         applEndSeqNum     |-> applEndSeqNum.value,
         partitionId       |-> partitionId.value,
         refApplId         |-> refApplId.value,
         pad5              |-> pad5.value ], pad5.rest)

ZeroRetransmitRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp42,
      applBegSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applEndSeqNum     |-> [i \in 1 .. 8 |-> 0],
      partitionId       |-> [i \in 1 .. 2 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      pad5              |-> [i \in 1 .. 5 |-> 0] ]

(* Retransmit Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRequest ==
    { ZeroRetransmitRequest }
        \cup { [ZeroRetransmitRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp42 }
        \cup { [ZeroRetransmitRequest EXCEPT !.applBegSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.applEndSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmitRequest EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp43 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp43(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp43(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp43 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp43 ==
    { ZeroRequestHeaderComp43 }
        \cup { [ZeroRequestHeaderComp43 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp43 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Reverse Tes Trade Request: 194 bytes                                    *)
(***************************************************************************)

ReverseTesTradeRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp43,
      marketSegmentId        : Sample(4),
      packageId              : Sample(4),
      tesExecId              : Sample(4),
      relatedMarketSegmentId : Sample(4),
      trdType                : Sample(2),
      tradeReportId          : Sample(20),
      reversalReasonText     : Sample(132),
      pad6                   : Sample(6) ]

EncodeReverseTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp43(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.packageId
        \o message.tesExecId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.tradeReportId
        \o message.reversalReasonText
        \o message.pad6

DecodeReverseTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp43(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(packageId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(trdType.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET reversalReasonText == ReadBytes(tradeReportId.rest, 132) IN IF ~reversalReasonText.ok THEN Fail ELSE
    LET pad6 == ReadBytes(reversalReasonText.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         marketSegmentId        |-> marketSegmentId.value,
         packageId              |-> packageId.value,
         tesExecId              |-> tesExecId.value,
         relatedMarketSegmentId |-> relatedMarketSegmentId.value,
         trdType                |-> trdType.value,
         tradeReportId          |-> tradeReportId.value,
         reversalReasonText     |-> reversalReasonText.value,
         pad6                   |-> pad6.value ], pad6.rest)

ZeroReverseTesTradeRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp43,
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      packageId              |-> [i \in 1 .. 4 |-> 0],
      tesExecId              |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId |-> [i \in 1 .. 4 |-> 0],
      trdType                |-> [i \in 1 .. 2 |-> 0],
      tradeReportId          |-> [i \in 1 .. 20 |-> 0],
      reversalReasonText     |-> [i \in 1 .. 132 |-> 0],
      pad6                   |-> [i \in 1 .. 6 |-> 0] ]

(* Reverse Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedReverseTesTradeRequest ==
    { ZeroReverseTesTradeRequest }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp43 }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.reversalReasonText = one] : one \in Sample(132) }
        \cup { [ZeroReverseTesTradeRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp44 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp44(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp44(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp44 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp44 ==
    { ZeroRequestHeaderComp44 }
        \cup { [ZeroRequestHeaderComp44 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp44 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Srqs Enter Quote Request: 370 bytes                                     *)
(***************************************************************************)

SrqsEnterQuoteRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp44,
      bidPx                                   : Sample(8),
      offerPx                                 : Sample(8),
      underlyingDeltaPercentage               : Sample(8),
      bidSize                                 : Sample(8),
      offerSize                               : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      quoteRefPrice                           : Sample(8),
      validUntilTime                          : Sample(8),
      marketSegmentId                         : Sample(4),
      negotiationId                           : Sample(4),
      orderAttributeLiquidityProvision        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      tradingCapacity                         : Sample(1),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      freeText5                               : Sample(132),
      positionEffect                          : Sample(1),
      account                                 : Sample(2),
      partyIdBeneficiary                      : Sample(9),
      custOrderHandlingInst                   : Sample(1),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdPositionAccount                  : Sample(32),
      partyIdLocationId                       : Sample(2),
      complianceText                          : Sample(20),
      partyIdTakeUpTradingFirm                : Sample(5),
      pad2v2                                  : Sample(2) ]

EncodeSrqsEnterQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp44(message.requestHeaderComp)
        \o message.bidPx
        \o message.offerPx
        \o message.underlyingDeltaPercentage
        \o message.bidSize
        \o message.offerSize
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.quoteRefPrice
        \o message.validUntilTime
        \o message.marketSegmentId
        \o message.negotiationId
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.tradingCapacity
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.freeText5
        \o message.positionEffect
        \o message.account
        \o message.partyIdBeneficiary
        \o message.custOrderHandlingInst
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdPositionAccount
        \o message.partyIdLocationId
        \o message.complianceText
        \o message.partyIdTakeUpTradingFirm
        \o message.pad2v2

DecodeSrqsEnterQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp44(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET bidPx == ReadBytes(requestHeaderComp.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET underlyingDeltaPercentage == ReadBytes(offerPx.rest, 8) IN IF ~underlyingDeltaPercentage.ok THEN Fail ELSE
    LET bidSize == ReadBytes(underlyingDeltaPercentage.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(offerSize.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET quoteRefPrice == ReadBytes(executingTrader.rest, 8) IN IF ~quoteRefPrice.ok THEN Fail ELSE
    LET validUntilTime == ReadBytes(quoteRefPrice.rest, 8) IN IF ~validUntilTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(validUntilTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(negotiationId.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tradingCapacity.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyExecutingTrader.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(freeText3.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(freeText5.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET account == ReadBytes(positionEffect.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(account.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(custOrderHandlingInst.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(partyIdOrderOriginationFirm.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(partyIdPositionAccount.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET complianceText == ReadBytes(partyIdLocationId.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(complianceText.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(partyIdTakeUpTradingFirm.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         bidPx                                   |-> bidPx.value,
         offerPx                                 |-> offerPx.value,
         underlyingDeltaPercentage               |-> underlyingDeltaPercentage.value,
         bidSize                                 |-> bidSize.value,
         offerSize                               |-> offerSize.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         quoteRefPrice                           |-> quoteRefPrice.value,
         validUntilTime                          |-> validUntilTime.value,
         marketSegmentId                         |-> marketSegmentId.value,
         negotiationId                           |-> negotiationId.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         tradingCapacity                         |-> tradingCapacity.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         freeText5                               |-> freeText5.value,
         positionEffect                          |-> positionEffect.value,
         account                                 |-> account.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         complianceText                          |-> complianceText.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         pad2v2                                  |-> pad2v2.value ], pad2v2.rest)

ZeroSrqsEnterQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp44,
      bidPx                                   |-> [i \in 1 .. 8 |-> 0],
      offerPx                                 |-> [i \in 1 .. 8 |-> 0],
      underlyingDeltaPercentage               |-> [i \in 1 .. 8 |-> 0],
      bidSize                                 |-> [i \in 1 .. 8 |-> 0],
      offerSize                               |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      quoteRefPrice                           |-> [i \in 1 .. 8 |-> 0],
      validUntilTime                          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      negotiationId                           |-> [i \in 1 .. 4 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      freeText5                               |-> [i \in 1 .. 132 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      pad2v2                                  |-> [i \in 1 .. 2 |-> 0] ]

(* Srqs Enter Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedSrqsEnterQuoteRequest ==
    { ZeroSrqsEnterQuoteRequest }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp44 }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.underlyingDeltaPercentage = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.quoteRefPrice = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.validUntilTime = one] : one \in Sample(8) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsEnterQuoteRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp45 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp45(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp45(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp45 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp45 ==
    { ZeroRequestHeaderComp45 }
        \cup { [ZeroRequestHeaderComp45 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp45 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Srqs Hit Quote Grp Comp: 32 bytes                                       *)
(***************************************************************************)

SrqsHitQuoteGrpComp ==
    [ orderQty : Sample(8),
      price    : Sample(8),
      quoteId  : Sample(8),
      side     : Sample(1),
      pad7     : Sample(7) ]

EncodeSrqsHitQuoteGrpComp(message) ==
    message.orderQty
        \o message.price
        \o message.quoteId
        \o message.side
        \o message.pad7

DecodeSrqsHitQuoteGrpComp(bytes) ==
    LET orderQty == ReadBytes(bytes, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quoteId == ReadBytes(price.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET side == ReadBytes(quoteId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad7 == ReadBytes(side.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ orderQty |-> orderQty.value,
         price    |-> price.value,
         quoteId  |-> quoteId.value,
         side     |-> side.value,
         pad7     |-> pad7.value ], pad7.rest)

ZeroSrqsHitQuoteGrpComp ==
    [ orderQty |-> [i \in 1 .. 8 |-> 0],
      price    |-> [i \in 1 .. 8 |-> 0],
      quoteId  |-> [i \in 1 .. 8 |-> 0],
      side     |-> [i \in 1 .. 1 |-> 0],
      pad7     |-> [i \in 1 .. 7 |-> 0] ]

(* Srqs Hit Quote Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSrqsHitQuoteGrpComp ==
    { ZeroSrqsHitQuoteGrpComp }
        \cup { [ZeroSrqsHitQuoteGrpComp EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteGrpComp EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteGrpComp EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Srqs Hit Quote Grp Comp, written one after another *)
RECURSIVE EncodeSrqsHitQuoteGrpCompList(_)
EncodeSrqsHitQuoteGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSrqsHitQuoteGrpComp(Head(messages)) \o EncodeSrqsHitQuoteGrpCompList(Tail(messages))

(* As many Srqs Hit Quote Grp Comp as the field that counts them says *)
RECURSIVE ReadSrqsHitQuoteGrpCompList(_, _)
ReadSrqsHitQuoteGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSrqsHitQuoteGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSrqsHitQuoteGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Srqs Hit Quote Grp Comp of each kind, for the lists that carry them *)
OneSrqsHitQuoteGrpComp == { ZeroSrqsHitQuoteGrpComp }

(***************************************************************************)
(* Srqs Hit Quote Request                                                  *)
(***************************************************************************)

SrqsHitQuoteRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp45,
      validUntilTime                          : Sample(8),
      underlyingQty                           : Sample(8),
      underlyingPriceStipValue                : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      negotiationId                           : Sample(4),
      orderAttributeLiquidityProvision        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      tradingCapacity                         : Sample(1),
      tradePublishIndicator                   : Sample(1),
      orderOrigination                        : Sample(1),
      hedgingInstruction                      : Sample(1),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      firmTradeId                             : Sample(20),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      freeText5                               : Sample(132),
      positionEffect                          : Sample(1),
      account                                 : Sample(2),
      partyIdBeneficiary                      : Sample(9),
      custOrderHandlingInst                   : Sample(1),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdPositionAccount                  : Sample(32),
      partyIdLocationId                       : Sample(2),
      complianceText                          : Sample(20),
      partyIdTakeUpTradingFirm                : Sample(5),
      partyEndClientIdentification            : Sample(20),
      pad6                                    : Sample(6),
      srqsHitQuoteGrpComp                     : SampleLists(OneSrqsHitQuoteGrpComp) ]

EncodeSrqsHitQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp45(message.requestHeaderComp)
        \o message.validUntilTime
        \o message.underlyingQty
        \o message.underlyingPriceStipValue
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.negotiationId
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.tradingCapacity
        \o message.tradePublishIndicator
        \o message.orderOrigination
        \o message.hedgingInstruction
        \o EncodeUIntBE(Len(message.srqsHitQuoteGrpComp), 1)
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.firmTradeId
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.freeText5
        \o message.positionEffect
        \o message.account
        \o message.partyIdBeneficiary
        \o message.custOrderHandlingInst
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdPositionAccount
        \o message.partyIdLocationId
        \o message.complianceText
        \o message.partyIdTakeUpTradingFirm
        \o message.partyEndClientIdentification
        \o message.pad6
        \o EncodeSrqsHitQuoteGrpCompList(message.srqsHitQuoteGrpComp)

DecodeSrqsHitQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp45(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET validUntilTime == ReadBytes(requestHeaderComp.rest, 8) IN IF ~validUntilTime.ok THEN Fail ELSE
    LET underlyingQty == ReadBytes(validUntilTime.rest, 8) IN IF ~underlyingQty.ok THEN Fail ELSE
    LET underlyingPriceStipValue == ReadBytes(underlyingQty.rest, 8) IN IF ~underlyingPriceStipValue.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(underlyingPriceStipValue.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(negotiationId.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(tradingCapacity.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(tradePublishIndicator.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET hedgingInstruction == ReadBytes(orderOrigination.rest, 1) IN IF ~hedgingInstruction.ok THEN Fail ELSE
    LET noSrqsQuoteGrps == ReadUIntBE(hedgingInstruction.rest, 1) IN IF ~noSrqsQuoteGrps.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(noSrqsQuoteGrps.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET firmTradeId == ReadBytes(partyExecutingTrader.rest, 20) IN IF ~firmTradeId.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(firmTradeId.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(freeText3.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(freeText5.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET account == ReadBytes(positionEffect.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(account.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(custOrderHandlingInst.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(partyIdOrderOriginationFirm.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(partyIdPositionAccount.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET complianceText == ReadBytes(partyIdLocationId.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(complianceText.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyEndClientIdentification == ReadBytes(partyIdTakeUpTradingFirm.rest, 20) IN IF ~partyEndClientIdentification.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyEndClientIdentification.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET srqsHitQuoteGrpComp == ReadSrqsHitQuoteGrpCompList(pad6.rest, noSrqsQuoteGrps.value) IN IF ~srqsHitQuoteGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         validUntilTime                          |-> validUntilTime.value,
         underlyingQty                           |-> underlyingQty.value,
         underlyingPriceStipValue                |-> underlyingPriceStipValue.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         negotiationId                           |-> negotiationId.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         tradingCapacity                         |-> tradingCapacity.value,
         tradePublishIndicator                   |-> tradePublishIndicator.value,
         orderOrigination                        |-> orderOrigination.value,
         hedgingInstruction                      |-> hedgingInstruction.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         firmTradeId                             |-> firmTradeId.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         freeText5                               |-> freeText5.value,
         positionEffect                          |-> positionEffect.value,
         account                                 |-> account.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         complianceText                          |-> complianceText.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         partyEndClientIdentification            |-> partyEndClientIdentification.value,
         pad6                                    |-> pad6.value,
         srqsHitQuoteGrpComp                     |-> srqsHitQuoteGrpComp.value ], srqsHitQuoteGrpComp.rest)

ZeroSrqsHitQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp45,
      validUntilTime                          |-> [i \in 1 .. 8 |-> 0],
      underlyingQty                           |-> [i \in 1 .. 8 |-> 0],
      underlyingPriceStipValue                |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      negotiationId                           |-> [i \in 1 .. 4 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator                   |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      hedgingInstruction                      |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      firmTradeId                             |-> [i \in 1 .. 20 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      freeText5                               |-> [i \in 1 .. 132 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyEndClientIdentification            |-> [i \in 1 .. 20 |-> 0],
      pad6                                    |-> [i \in 1 .. 6 |-> 0],
      srqsHitQuoteGrpComp                     |-> << >> ]

(* Srqs Hit Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedSrqsHitQuoteRequest ==
    { ZeroSrqsHitQuoteRequest }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp45 }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.validUntilTime = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.underlyingQty = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.underlyingPriceStipValue = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.hedgingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.firmTradeId = one] : one \in Sample(20) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.partyEndClientIdentification = one] : one \in Sample(20) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroSrqsHitQuoteRequest EXCEPT !.srqsHitQuoteGrpComp = one] : one \in SampleLists(OneSrqsHitQuoteGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp46 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp46(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp46(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp46 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp46 ==
    { ZeroRequestHeaderComp46 }
        \cup { [ZeroRequestHeaderComp46 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp46 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Srqs Inquire Smart Respondent Request: 26 bytes                         *)
(***************************************************************************)

SrqsInquireSmartRespondentRequest ==
    [ networkMsgId                 : Sample(8),
      pad2                         : Sample(2),
      requestHeaderComp            : RequestHeaderComp46,
      marketSegmentId              : Sample(4),
      eurexVolumeRanking           : Sample(1),
      enlightRfqAvgRespTimeRanking : Sample(1),
      enlightRfqAvgRespRateRanking : Sample(1),
      tradeToQuoteRatioRanking     : Sample(1) ]

EncodeSrqsInquireSmartRespondentRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp46(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.eurexVolumeRanking
        \o message.enlightRfqAvgRespTimeRanking
        \o message.enlightRfqAvgRespRateRanking
        \o message.tradeToQuoteRatioRanking

DecodeSrqsInquireSmartRespondentRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp46(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET eurexVolumeRanking == ReadBytes(marketSegmentId.rest, 1) IN IF ~eurexVolumeRanking.ok THEN Fail ELSE
    LET enlightRfqAvgRespTimeRanking == ReadBytes(eurexVolumeRanking.rest, 1) IN IF ~enlightRfqAvgRespTimeRanking.ok THEN Fail ELSE
    LET enlightRfqAvgRespRateRanking == ReadBytes(enlightRfqAvgRespTimeRanking.rest, 1) IN IF ~enlightRfqAvgRespRateRanking.ok THEN Fail ELSE
    LET tradeToQuoteRatioRanking == ReadBytes(enlightRfqAvgRespRateRanking.rest, 1) IN IF ~tradeToQuoteRatioRanking.ok THEN Fail ELSE
    Ok([ networkMsgId                 |-> networkMsgId.value,
         pad2                         |-> pad2.value,
         requestHeaderComp            |-> requestHeaderComp.value,
         marketSegmentId              |-> marketSegmentId.value,
         eurexVolumeRanking           |-> eurexVolumeRanking.value,
         enlightRfqAvgRespTimeRanking |-> enlightRfqAvgRespTimeRanking.value,
         enlightRfqAvgRespRateRanking |-> enlightRfqAvgRespRateRanking.value,
         tradeToQuoteRatioRanking     |-> tradeToQuoteRatioRanking.value ], tradeToQuoteRatioRanking.rest)

ZeroSrqsInquireSmartRespondentRequest ==
    [ networkMsgId                 |-> [i \in 1 .. 8 |-> 0],
      pad2                         |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp            |-> ZeroRequestHeaderComp46,
      marketSegmentId              |-> [i \in 1 .. 4 |-> 0],
      eurexVolumeRanking           |-> [i \in 1 .. 1 |-> 0],
      enlightRfqAvgRespTimeRanking |-> [i \in 1 .. 1 |-> 0],
      enlightRfqAvgRespRateRanking |-> [i \in 1 .. 1 |-> 0],
      tradeToQuoteRatioRanking     |-> [i \in 1 .. 1 |-> 0] ]

(* Srqs Inquire Smart Respondent Request at zero, then each field in turn at the values it is checked at *)
CheckedSrqsInquireSmartRespondentRequest ==
    { ZeroSrqsInquireSmartRespondentRequest }
        \cup { [ZeroSrqsInquireSmartRespondentRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsInquireSmartRespondentRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSrqsInquireSmartRespondentRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp46 }
        \cup { [ZeroSrqsInquireSmartRespondentRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsInquireSmartRespondentRequest EXCEPT !.eurexVolumeRanking = one] : one \in Sample(1) }
        \cup { [ZeroSrqsInquireSmartRespondentRequest EXCEPT !.enlightRfqAvgRespTimeRanking = one] : one \in Sample(1) }
        \cup { [ZeroSrqsInquireSmartRespondentRequest EXCEPT !.enlightRfqAvgRespRateRanking = one] : one \in Sample(1) }
        \cup { [ZeroSrqsInquireSmartRespondentRequest EXCEPT !.tradeToQuoteRatioRanking = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp47 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp47(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp47(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp47 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp47 ==
    { ZeroRequestHeaderComp47 }
        \cup { [ZeroRequestHeaderComp47 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp47 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Quot Req Legs Grp Comp: 24 bytes                                        *)
(***************************************************************************)

QuotReqLegsGrpComp ==
    [ legSecurityId   : Sample(8),
      legRatioQty     : Sample(4),
      legSymbol       : Sample(4),
      legSecurityType : Sample(1),
      legSide         : Sample(1),
      pad6            : Sample(6) ]

EncodeQuotReqLegsGrpComp(message) ==
    message.legSecurityId
        \o message.legRatioQty
        \o message.legSymbol
        \o message.legSecurityType
        \o message.legSide
        \o message.pad6

DecodeQuotReqLegsGrpComp(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSecurityId.rest, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legRatioQty.rest, 4) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legSymbol.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSecurityType.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET pad6 == ReadBytes(legSide.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId   |-> legSecurityId.value,
         legRatioQty     |-> legRatioQty.value,
         legSymbol       |-> legSymbol.value,
         legSecurityType |-> legSecurityType.value,
         legSide         |-> legSide.value,
         pad6            |-> pad6.value ], pad6.rest)

ZeroQuotReqLegsGrpComp ==
    [ legSecurityId   |-> [i \in 1 .. 8 |-> 0],
      legRatioQty     |-> [i \in 1 .. 4 |-> 0],
      legSymbol       |-> [i \in 1 .. 4 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      pad6            |-> [i \in 1 .. 6 |-> 0] ]

(* Quot Req Legs Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuotReqLegsGrpComp ==
    { ZeroQuotReqLegsGrpComp }
        \cup { [ZeroQuotReqLegsGrpComp EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroQuotReqLegsGrpComp EXCEPT !.legRatioQty = one] : one \in Sample(4) }
        \cup { [ZeroQuotReqLegsGrpComp EXCEPT !.legSymbol = one] : one \in Sample(4) }
        \cup { [ZeroQuotReqLegsGrpComp EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroQuotReqLegsGrpComp EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroQuotReqLegsGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Quot Req Legs Grp Comp, written one after another *)
RECURSIVE EncodeQuotReqLegsGrpCompList(_)
EncodeQuotReqLegsGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuotReqLegsGrpComp(Head(messages)) \o EncodeQuotReqLegsGrpCompList(Tail(messages))

(* As many Quot Req Legs Grp Comp as the field that counts them says *)
RECURSIVE ReadQuotReqLegsGrpCompList(_, _)
ReadQuotReqLegsGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuotReqLegsGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuotReqLegsGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quot Req Legs Grp Comp of each kind, for the lists that carry them *)
OneQuotReqLegsGrpComp == { ZeroQuotReqLegsGrpComp }

(***************************************************************************)
(* Target Parties Comp: 32 bytes                                           *)
(***************************************************************************)

TargetPartiesComp ==
    [ targetPartyIdExecutingTrader               : Sample(4),
      sideDisclosureInstruction                  : Sample(1),
      priceDisclosureInstruction                 : Sample(1),
      leavesQtyDisclosureInstruction             : Sample(1),
      lastPxDisclosureInstruction                : Sample(1),
      lastQtyDisclosureInstruction               : Sample(1),
      freeText5DisclosureInstruction             : Sample(1),
      partyOrderOriginationDisclosureInstruction : Sample(1),
      quoteInstruction                           : Sample(1),
      chargeIdDisclosureInstruction              : Sample(1),
      targetPartyExecutingFirm                   : Sample(5),
      targetPartyExecutingTrader                 : Sample(6),
      partyDetailStatus                          : Sample(1),
      partyDetailStatusInformation               : Sample(1),
      pad6                                       : Sample(6) ]

EncodeTargetPartiesComp(message) ==
    message.targetPartyIdExecutingTrader
        \o message.sideDisclosureInstruction
        \o message.priceDisclosureInstruction
        \o message.leavesQtyDisclosureInstruction
        \o message.lastPxDisclosureInstruction
        \o message.lastQtyDisclosureInstruction
        \o message.freeText5DisclosureInstruction
        \o message.partyOrderOriginationDisclosureInstruction
        \o message.quoteInstruction
        \o message.chargeIdDisclosureInstruction
        \o message.targetPartyExecutingFirm
        \o message.targetPartyExecutingTrader
        \o message.partyDetailStatus
        \o message.partyDetailStatusInformation
        \o message.pad6

DecodeTargetPartiesComp(bytes) ==
    LET targetPartyIdExecutingTrader == ReadBytes(bytes, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET sideDisclosureInstruction == ReadBytes(targetPartyIdExecutingTrader.rest, 1) IN IF ~sideDisclosureInstruction.ok THEN Fail ELSE
    LET priceDisclosureInstruction == ReadBytes(sideDisclosureInstruction.rest, 1) IN IF ~priceDisclosureInstruction.ok THEN Fail ELSE
    LET leavesQtyDisclosureInstruction == ReadBytes(priceDisclosureInstruction.rest, 1) IN IF ~leavesQtyDisclosureInstruction.ok THEN Fail ELSE
    LET lastPxDisclosureInstruction == ReadBytes(leavesQtyDisclosureInstruction.rest, 1) IN IF ~lastPxDisclosureInstruction.ok THEN Fail ELSE
    LET lastQtyDisclosureInstruction == ReadBytes(lastPxDisclosureInstruction.rest, 1) IN IF ~lastQtyDisclosureInstruction.ok THEN Fail ELSE
    LET freeText5DisclosureInstruction == ReadBytes(lastQtyDisclosureInstruction.rest, 1) IN IF ~freeText5DisclosureInstruction.ok THEN Fail ELSE
    LET partyOrderOriginationDisclosureInstruction == ReadBytes(freeText5DisclosureInstruction.rest, 1) IN IF ~partyOrderOriginationDisclosureInstruction.ok THEN Fail ELSE
    LET quoteInstruction == ReadBytes(partyOrderOriginationDisclosureInstruction.rest, 1) IN IF ~quoteInstruction.ok THEN Fail ELSE
    LET chargeIdDisclosureInstruction == ReadBytes(quoteInstruction.rest, 1) IN IF ~chargeIdDisclosureInstruction.ok THEN Fail ELSE
    LET targetPartyExecutingFirm == ReadBytes(chargeIdDisclosureInstruction.rest, 5) IN IF ~targetPartyExecutingFirm.ok THEN Fail ELSE
    LET targetPartyExecutingTrader == ReadBytes(targetPartyExecutingFirm.rest, 6) IN IF ~targetPartyExecutingTrader.ok THEN Fail ELSE
    LET partyDetailStatus == ReadBytes(targetPartyExecutingTrader.rest, 1) IN IF ~partyDetailStatus.ok THEN Fail ELSE
    LET partyDetailStatusInformation == ReadBytes(partyDetailStatus.rest, 1) IN IF ~partyDetailStatusInformation.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyDetailStatusInformation.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ targetPartyIdExecutingTrader               |-> targetPartyIdExecutingTrader.value,
         sideDisclosureInstruction                  |-> sideDisclosureInstruction.value,
         priceDisclosureInstruction                 |-> priceDisclosureInstruction.value,
         leavesQtyDisclosureInstruction             |-> leavesQtyDisclosureInstruction.value,
         lastPxDisclosureInstruction                |-> lastPxDisclosureInstruction.value,
         lastQtyDisclosureInstruction               |-> lastQtyDisclosureInstruction.value,
         freeText5DisclosureInstruction             |-> freeText5DisclosureInstruction.value,
         partyOrderOriginationDisclosureInstruction |-> partyOrderOriginationDisclosureInstruction.value,
         quoteInstruction                           |-> quoteInstruction.value,
         chargeIdDisclosureInstruction              |-> chargeIdDisclosureInstruction.value,
         targetPartyExecutingFirm                   |-> targetPartyExecutingFirm.value,
         targetPartyExecutingTrader                 |-> targetPartyExecutingTrader.value,
         partyDetailStatus                          |-> partyDetailStatus.value,
         partyDetailStatusInformation               |-> partyDetailStatusInformation.value,
         pad6                                       |-> pad6.value ], pad6.rest)

ZeroTargetPartiesComp ==
    [ targetPartyIdExecutingTrader               |-> [i \in 1 .. 4 |-> 0],
      sideDisclosureInstruction                  |-> [i \in 1 .. 1 |-> 0],
      priceDisclosureInstruction                 |-> [i \in 1 .. 1 |-> 0],
      leavesQtyDisclosureInstruction             |-> [i \in 1 .. 1 |-> 0],
      lastPxDisclosureInstruction                |-> [i \in 1 .. 1 |-> 0],
      lastQtyDisclosureInstruction               |-> [i \in 1 .. 1 |-> 0],
      freeText5DisclosureInstruction             |-> [i \in 1 .. 1 |-> 0],
      partyOrderOriginationDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      quoteInstruction                           |-> [i \in 1 .. 1 |-> 0],
      chargeIdDisclosureInstruction              |-> [i \in 1 .. 1 |-> 0],
      targetPartyExecutingFirm                   |-> [i \in 1 .. 5 |-> 0],
      targetPartyExecutingTrader                 |-> [i \in 1 .. 6 |-> 0],
      partyDetailStatus                          |-> [i \in 1 .. 1 |-> 0],
      partyDetailStatusInformation               |-> [i \in 1 .. 1 |-> 0],
      pad6                                       |-> [i \in 1 .. 6 |-> 0] ]

(* Target Parties Comp at zero, then each field in turn at the values it is checked at *)
CheckedTargetPartiesComp ==
    { ZeroTargetPartiesComp }
        \cup { [ZeroTargetPartiesComp EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.sideDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.priceDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.leavesQtyDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.lastPxDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.lastQtyDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.freeText5DisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.partyOrderOriginationDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.quoteInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.chargeIdDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.targetPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.targetPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.partyDetailStatus = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.partyDetailStatusInformation = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Target Parties Comp, written one after another *)
RECURSIVE EncodeTargetPartiesCompList(_)
EncodeTargetPartiesCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTargetPartiesComp(Head(messages)) \o EncodeTargetPartiesCompList(Tail(messages))

(* As many Target Parties Comp as the field that counts them says *)
RECURSIVE ReadTargetPartiesCompList(_, _)
ReadTargetPartiesCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTargetPartiesComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTargetPartiesCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Target Parties Comp of each kind, for the lists that carry them *)
OneTargetPartiesComp == { ZeroTargetPartiesComp }

(***************************************************************************)
(* Srqs Open Negotiation Request                                           *)
(***************************************************************************)

SrqsOpenNegotiationRequest ==
    [ networkMsgId                      : Sample(8),
      pad2                              : Sample(2),
      requestHeaderComp                 : RequestHeaderComp47,
      securityId                        : Sample(8),
      bidPx                             : Sample(8),
      offerPx                           : Sample(8),
      orderQty                          : Sample(8),
      quoteRefPrice                     : Sample(8),
      underlyingDeltaPercentage         : Sample(8),
      validUntilTime                    : Sample(8),
      marketSegmentId                   : Sample(4),
      securitySubType                   : Sample(4),
      quoteType                         : Sample(1),
      quoteSubType                      : Sample(1),
      numberOfRespDisclosureInstruction : Sample(1),
      side                              : Sample(1),
      productComplex                    : Sample(1),
      respondentType                    : Sample(1),
      showLastDealOnClosure             : Sample(1),
      bidPxIsLocked                     : Sample(1),
      offerPxIsLocked                   : Sample(1),
      sideIsLocked                      : Sample(1),
      orderQtyIsLocked                  : Sample(1),
      tradeAggregationTransType         : Sample(1),
      quoteCondition                    : Sample(1),
      partyExecutingFirm                : Sample(5),
      partyExecutingTrader              : Sample(6),
      freeText5                         : Sample(132),
      quoteReqId                        : Sample(20),
      partyOrderOriginationTrader       : Sample(132),
      chargeId                          : Sample(132),
      pad6                              : Sample(6),
      quotReqLegsGrpComp                : SampleLists(OneQuotReqLegsGrpComp),
      targetPartiesComp                 : SampleLists(OneTargetPartiesComp) ]

EncodeSrqsOpenNegotiationRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp47(message.requestHeaderComp)
        \o message.securityId
        \o message.bidPx
        \o message.offerPx
        \o message.orderQty
        \o message.quoteRefPrice
        \o message.underlyingDeltaPercentage
        \o message.validUntilTime
        \o message.marketSegmentId
        \o message.securitySubType
        \o message.quoteType
        \o message.quoteSubType
        \o EncodeUIntBE(Len(message.quotReqLegsGrpComp), 1)
        \o EncodeUIntBE(Len(message.targetPartiesComp), 1)
        \o message.numberOfRespDisclosureInstruction
        \o message.side
        \o message.productComplex
        \o message.respondentType
        \o message.showLastDealOnClosure
        \o message.bidPxIsLocked
        \o message.offerPxIsLocked
        \o message.sideIsLocked
        \o message.orderQtyIsLocked
        \o message.tradeAggregationTransType
        \o message.quoteCondition
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText5
        \o message.quoteReqId
        \o message.partyOrderOriginationTrader
        \o message.chargeId
        \o message.pad6
        \o EncodeQuotReqLegsGrpCompList(message.quotReqLegsGrpComp)
        \o EncodeTargetPartiesCompList(message.targetPartiesComp)

DecodeSrqsOpenNegotiationRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp47(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(offerPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET quoteRefPrice == ReadBytes(orderQty.rest, 8) IN IF ~quoteRefPrice.ok THEN Fail ELSE
    LET underlyingDeltaPercentage == ReadBytes(quoteRefPrice.rest, 8) IN IF ~underlyingDeltaPercentage.ok THEN Fail ELSE
    LET validUntilTime == ReadBytes(underlyingDeltaPercentage.rest, 8) IN IF ~validUntilTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(validUntilTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(marketSegmentId.rest, 4) IN IF ~securitySubType.ok THEN Fail ELSE
    LET quoteType == ReadBytes(securitySubType.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET quoteSubType == ReadBytes(quoteType.rest, 1) IN IF ~quoteSubType.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(quoteSubType.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET noTargetPartyIDs == ReadUIntBE(noLegs.rest, 1) IN IF ~noTargetPartyIDs.ok THEN Fail ELSE
    LET numberOfRespDisclosureInstruction == ReadBytes(noTargetPartyIDs.rest, 1) IN IF ~numberOfRespDisclosureInstruction.ok THEN Fail ELSE
    LET side == ReadBytes(numberOfRespDisclosureInstruction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET productComplex == ReadBytes(side.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET respondentType == ReadBytes(productComplex.rest, 1) IN IF ~respondentType.ok THEN Fail ELSE
    LET showLastDealOnClosure == ReadBytes(respondentType.rest, 1) IN IF ~showLastDealOnClosure.ok THEN Fail ELSE
    LET bidPxIsLocked == ReadBytes(showLastDealOnClosure.rest, 1) IN IF ~bidPxIsLocked.ok THEN Fail ELSE
    LET offerPxIsLocked == ReadBytes(bidPxIsLocked.rest, 1) IN IF ~offerPxIsLocked.ok THEN Fail ELSE
    LET sideIsLocked == ReadBytes(offerPxIsLocked.rest, 1) IN IF ~sideIsLocked.ok THEN Fail ELSE
    LET orderQtyIsLocked == ReadBytes(sideIsLocked.rest, 1) IN IF ~orderQtyIsLocked.ok THEN Fail ELSE
    LET tradeAggregationTransType == ReadBytes(orderQtyIsLocked.rest, 1) IN IF ~tradeAggregationTransType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(tradeAggregationTransType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quoteCondition.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(partyExecutingTrader.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(freeText5.rest, 20) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET partyOrderOriginationTrader == ReadBytes(quoteReqId.rest, 132) IN IF ~partyOrderOriginationTrader.ok THEN Fail ELSE
    LET chargeId == ReadBytes(partyOrderOriginationTrader.rest, 132) IN IF ~chargeId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(chargeId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET quotReqLegsGrpComp == ReadQuotReqLegsGrpCompList(pad6.rest, noLegs.value) IN IF ~quotReqLegsGrpComp.ok THEN Fail ELSE
    LET targetPartiesComp == ReadTargetPartiesCompList(quotReqLegsGrpComp.rest, noTargetPartyIDs.value) IN IF ~targetPartiesComp.ok THEN Fail ELSE
    Ok([ networkMsgId                      |-> networkMsgId.value,
         pad2                              |-> pad2.value,
         requestHeaderComp                 |-> requestHeaderComp.value,
         securityId                        |-> securityId.value,
         bidPx                             |-> bidPx.value,
         offerPx                           |-> offerPx.value,
         orderQty                          |-> orderQty.value,
         quoteRefPrice                     |-> quoteRefPrice.value,
         underlyingDeltaPercentage         |-> underlyingDeltaPercentage.value,
         validUntilTime                    |-> validUntilTime.value,
         marketSegmentId                   |-> marketSegmentId.value,
         securitySubType                   |-> securitySubType.value,
         quoteType                         |-> quoteType.value,
         quoteSubType                      |-> quoteSubType.value,
         numberOfRespDisclosureInstruction |-> numberOfRespDisclosureInstruction.value,
         side                              |-> side.value,
         productComplex                    |-> productComplex.value,
         respondentType                    |-> respondentType.value,
         showLastDealOnClosure             |-> showLastDealOnClosure.value,
         bidPxIsLocked                     |-> bidPxIsLocked.value,
         offerPxIsLocked                   |-> offerPxIsLocked.value,
         sideIsLocked                      |-> sideIsLocked.value,
         orderQtyIsLocked                  |-> orderQtyIsLocked.value,
         tradeAggregationTransType         |-> tradeAggregationTransType.value,
         quoteCondition                    |-> quoteCondition.value,
         partyExecutingFirm                |-> partyExecutingFirm.value,
         partyExecutingTrader              |-> partyExecutingTrader.value,
         freeText5                         |-> freeText5.value,
         quoteReqId                        |-> quoteReqId.value,
         partyOrderOriginationTrader       |-> partyOrderOriginationTrader.value,
         chargeId                          |-> chargeId.value,
         pad6                              |-> pad6.value,
         quotReqLegsGrpComp                |-> quotReqLegsGrpComp.value,
         targetPartiesComp                 |-> targetPartiesComp.value ], targetPartiesComp.rest)

ZeroSrqsOpenNegotiationRequest ==
    [ networkMsgId                      |-> [i \in 1 .. 8 |-> 0],
      pad2                              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                 |-> ZeroRequestHeaderComp47,
      securityId                        |-> [i \in 1 .. 8 |-> 0],
      bidPx                             |-> [i \in 1 .. 8 |-> 0],
      offerPx                           |-> [i \in 1 .. 8 |-> 0],
      orderQty                          |-> [i \in 1 .. 8 |-> 0],
      quoteRefPrice                     |-> [i \in 1 .. 8 |-> 0],
      underlyingDeltaPercentage         |-> [i \in 1 .. 8 |-> 0],
      validUntilTime                    |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      securitySubType                   |-> [i \in 1 .. 4 |-> 0],
      quoteType                         |-> [i \in 1 .. 1 |-> 0],
      quoteSubType                      |-> [i \in 1 .. 1 |-> 0],
      numberOfRespDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      productComplex                    |-> [i \in 1 .. 1 |-> 0],
      respondentType                    |-> [i \in 1 .. 1 |-> 0],
      showLastDealOnClosure             |-> [i \in 1 .. 1 |-> 0],
      bidPxIsLocked                     |-> [i \in 1 .. 1 |-> 0],
      offerPxIsLocked                   |-> [i \in 1 .. 1 |-> 0],
      sideIsLocked                      |-> [i \in 1 .. 1 |-> 0],
      orderQtyIsLocked                  |-> [i \in 1 .. 1 |-> 0],
      tradeAggregationTransType         |-> [i \in 1 .. 1 |-> 0],
      quoteCondition                    |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader              |-> [i \in 1 .. 6 |-> 0],
      freeText5                         |-> [i \in 1 .. 132 |-> 0],
      quoteReqId                        |-> [i \in 1 .. 20 |-> 0],
      partyOrderOriginationTrader       |-> [i \in 1 .. 132 |-> 0],
      chargeId                          |-> [i \in 1 .. 132 |-> 0],
      pad6                              |-> [i \in 1 .. 6 |-> 0],
      quotReqLegsGrpComp                |-> << >>,
      targetPartiesComp                 |-> << >> ]

(* Srqs Open Negotiation Request at zero, then each field in turn at the values it is checked at *)
CheckedSrqsOpenNegotiationRequest ==
    { ZeroSrqsOpenNegotiationRequest }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp47 }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.quoteRefPrice = one] : one \in Sample(8) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.underlyingDeltaPercentage = one] : one \in Sample(8) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.validUntilTime = one] : one \in Sample(8) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.securitySubType = one] : one \in Sample(4) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.quoteSubType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.numberOfRespDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.respondentType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.showLastDealOnClosure = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.bidPxIsLocked = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.offerPxIsLocked = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.sideIsLocked = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.orderQtyIsLocked = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.tradeAggregationTransType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.quoteReqId = one] : one \in Sample(20) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.partyOrderOriginationTrader = one] : one \in Sample(132) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.chargeId = one] : one \in Sample(132) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.quotReqLegsGrpComp = one] : one \in SampleLists(OneQuotReqLegsGrpComp) }
        \cup { [ZeroSrqsOpenNegotiationRequest EXCEPT !.targetPartiesComp = one] : one \in SampleLists(OneTargetPartiesComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp48 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp48(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp48(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp48 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp48 ==
    { ZeroRequestHeaderComp48 }
        \cup { [ZeroRequestHeaderComp48 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp48 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Srqs Quote Snapshot Request: 18 bytes                                   *)
(***************************************************************************)

SrqsQuoteSnapshotRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp48 ]

EncodeSrqsQuoteSnapshotRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp48(message.requestHeaderComp)

DecodeSrqsQuoteSnapshotRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp48(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroSrqsQuoteSnapshotRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp48 ]

(* Srqs Quote Snapshot Request at zero, then each field in turn at the values it is checked at *)
CheckedSrqsQuoteSnapshotRequest ==
    { ZeroSrqsQuoteSnapshotRequest }
        \cup { [ZeroSrqsQuoteSnapshotRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuoteSnapshotRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSrqsQuoteSnapshotRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp48 }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp49 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp49(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp49(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp49 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp49 ==
    { ZeroRequestHeaderComp49 }
        \cup { [ZeroRequestHeaderComp49 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp49 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Srqs Quoting Status Request: 170 bytes                                  *)
(***************************************************************************)

SrqsQuotingStatusRequest ==
    [ networkMsgId         : Sample(8),
      pad2                 : Sample(2),
      requestHeaderComp    : RequestHeaderComp49,
      marketSegmentId      : Sample(4),
      negotiationId        : Sample(4),
      quotingStatus        : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      freeText5            : Sample(132) ]

EncodeSrqsQuotingStatusRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp49(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.negotiationId
        \o message.quotingStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText5

DecodeSrqsQuotingStatusRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp49(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET quotingStatus == ReadBytes(negotiationId.rest, 1) IN IF ~quotingStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quotingStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(partyExecutingTrader.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    Ok([ networkMsgId         |-> networkMsgId.value,
         pad2                 |-> pad2.value,
         requestHeaderComp    |-> requestHeaderComp.value,
         marketSegmentId      |-> marketSegmentId.value,
         negotiationId        |-> negotiationId.value,
         quotingStatus        |-> quotingStatus.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         freeText5            |-> freeText5.value ], freeText5.rest)

ZeroSrqsQuotingStatusRequest ==
    [ networkMsgId         |-> [i \in 1 .. 8 |-> 0],
      pad2                 |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp    |-> ZeroRequestHeaderComp49,
      marketSegmentId      |-> [i \in 1 .. 4 |-> 0],
      negotiationId        |-> [i \in 1 .. 4 |-> 0],
      quotingStatus        |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      freeText5            |-> [i \in 1 .. 132 |-> 0] ]

(* Srqs Quoting Status Request at zero, then each field in turn at the values it is checked at *)
CheckedSrqsQuotingStatusRequest ==
    { ZeroSrqsQuotingStatusRequest }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp49 }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.quotingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSrqsQuotingStatusRequest EXCEPT !.freeText5 = one] : one \in Sample(132) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp50 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp50(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp50(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp50 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp50 ==
    { ZeroRequestHeaderComp50 }
        \cup { [ZeroRequestHeaderComp50 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp50 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Srqs Update Deal Status Request: 202 bytes                              *)
(***************************************************************************)

SrqsUpdateDealStatusRequest ==
    [ networkMsgId             : Sample(8),
      pad2                     : Sample(2),
      requestHeaderComp        : RequestHeaderComp50,
      underlyingPriceStipValue : Sample(8),
      underlyingPx             : Sample(8),
      lastQty                  : Sample(8),
      marketSegmentId          : Sample(4),
      negotiationId            : Sample(4),
      tradeId                  : Sample(4),
      tradeReportType          : Sample(1),
      trdRptStatus             : Sample(1),
      partyExecutingFirm       : Sample(5),
      partyExecutingTrader     : Sample(6),
      freeText5                : Sample(132),
      pad3                     : Sample(3) ]

EncodeSrqsUpdateDealStatusRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp50(message.requestHeaderComp)
        \o message.underlyingPriceStipValue
        \o message.underlyingPx
        \o message.lastQty
        \o message.marketSegmentId
        \o message.negotiationId
        \o message.tradeId
        \o message.tradeReportType
        \o message.trdRptStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText5
        \o message.pad3

DecodeSrqsUpdateDealStatusRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp50(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET underlyingPriceStipValue == ReadBytes(requestHeaderComp.rest, 8) IN IF ~underlyingPriceStipValue.ok THEN Fail ELSE
    LET underlyingPx == ReadBytes(underlyingPriceStipValue.rest, 8) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(underlyingPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(lastQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(negotiationId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET trdRptStatus == ReadBytes(tradeReportType.rest, 1) IN IF ~trdRptStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(trdRptStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(partyExecutingTrader.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET pad3 == ReadBytes(freeText5.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId             |-> networkMsgId.value,
         pad2                     |-> pad2.value,
         requestHeaderComp        |-> requestHeaderComp.value,
         underlyingPriceStipValue |-> underlyingPriceStipValue.value,
         underlyingPx             |-> underlyingPx.value,
         lastQty                  |-> lastQty.value,
         marketSegmentId          |-> marketSegmentId.value,
         negotiationId            |-> negotiationId.value,
         tradeId                  |-> tradeId.value,
         tradeReportType          |-> tradeReportType.value,
         trdRptStatus             |-> trdRptStatus.value,
         partyExecutingFirm       |-> partyExecutingFirm.value,
         partyExecutingTrader     |-> partyExecutingTrader.value,
         freeText5                |-> freeText5.value,
         pad3                     |-> pad3.value ], pad3.rest)

ZeroSrqsUpdateDealStatusRequest ==
    [ networkMsgId             |-> [i \in 1 .. 8 |-> 0],
      pad2                     |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp        |-> ZeroRequestHeaderComp50,
      underlyingPriceStipValue |-> [i \in 1 .. 8 |-> 0],
      underlyingPx             |-> [i \in 1 .. 8 |-> 0],
      lastQty                  |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      negotiationId            |-> [i \in 1 .. 4 |-> 0],
      tradeId                  |-> [i \in 1 .. 4 |-> 0],
      tradeReportType          |-> [i \in 1 .. 1 |-> 0],
      trdRptStatus             |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm       |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader     |-> [i \in 1 .. 6 |-> 0],
      freeText5                |-> [i \in 1 .. 132 |-> 0],
      pad3                     |-> [i \in 1 .. 3 |-> 0] ]

(* Srqs Update Deal Status Request at zero, then each field in turn at the values it is checked at *)
CheckedSrqsUpdateDealStatusRequest ==
    { ZeroSrqsUpdateDealStatusRequest }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp50 }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.underlyingPriceStipValue = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.underlyingPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.trdRptStatus = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroSrqsUpdateDealStatusRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp51 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp51(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp51(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp51 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp51 ==
    { ZeroRequestHeaderComp51 }
        \cup { [ZeroRequestHeaderComp51 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp51 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Target Parties Comp: 32 bytes                                           *)
(***************************************************************************)

TargetPartiesComp2 ==
    [ targetPartyIdExecutingTrader               : Sample(4),
      sideDisclosureInstruction                  : Sample(1),
      priceDisclosureInstruction                 : Sample(1),
      leavesQtyDisclosureInstruction             : Sample(1),
      lastPxDisclosureInstruction                : Sample(1),
      lastQtyDisclosureInstruction               : Sample(1),
      freeText5DisclosureInstruction             : Sample(1),
      partyOrderOriginationDisclosureInstruction : Sample(1),
      quoteInstruction                           : Sample(1),
      chargeIdDisclosureInstruction              : Sample(1),
      targetPartyExecutingFirm                   : Sample(5),
      targetPartyExecutingTrader                 : Sample(6),
      partyDetailStatus                          : Sample(1),
      partyDetailStatusInformation               : Sample(1),
      pad6                                       : Sample(6) ]

EncodeTargetPartiesComp2(message) ==
    message.targetPartyIdExecutingTrader
        \o message.sideDisclosureInstruction
        \o message.priceDisclosureInstruction
        \o message.leavesQtyDisclosureInstruction
        \o message.lastPxDisclosureInstruction
        \o message.lastQtyDisclosureInstruction
        \o message.freeText5DisclosureInstruction
        \o message.partyOrderOriginationDisclosureInstruction
        \o message.quoteInstruction
        \o message.chargeIdDisclosureInstruction
        \o message.targetPartyExecutingFirm
        \o message.targetPartyExecutingTrader
        \o message.partyDetailStatus
        \o message.partyDetailStatusInformation
        \o message.pad6

DecodeTargetPartiesComp2(bytes) ==
    LET targetPartyIdExecutingTrader == ReadBytes(bytes, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET sideDisclosureInstruction == ReadBytes(targetPartyIdExecutingTrader.rest, 1) IN IF ~sideDisclosureInstruction.ok THEN Fail ELSE
    LET priceDisclosureInstruction == ReadBytes(sideDisclosureInstruction.rest, 1) IN IF ~priceDisclosureInstruction.ok THEN Fail ELSE
    LET leavesQtyDisclosureInstruction == ReadBytes(priceDisclosureInstruction.rest, 1) IN IF ~leavesQtyDisclosureInstruction.ok THEN Fail ELSE
    LET lastPxDisclosureInstruction == ReadBytes(leavesQtyDisclosureInstruction.rest, 1) IN IF ~lastPxDisclosureInstruction.ok THEN Fail ELSE
    LET lastQtyDisclosureInstruction == ReadBytes(lastPxDisclosureInstruction.rest, 1) IN IF ~lastQtyDisclosureInstruction.ok THEN Fail ELSE
    LET freeText5DisclosureInstruction == ReadBytes(lastQtyDisclosureInstruction.rest, 1) IN IF ~freeText5DisclosureInstruction.ok THEN Fail ELSE
    LET partyOrderOriginationDisclosureInstruction == ReadBytes(freeText5DisclosureInstruction.rest, 1) IN IF ~partyOrderOriginationDisclosureInstruction.ok THEN Fail ELSE
    LET quoteInstruction == ReadBytes(partyOrderOriginationDisclosureInstruction.rest, 1) IN IF ~quoteInstruction.ok THEN Fail ELSE
    LET chargeIdDisclosureInstruction == ReadBytes(quoteInstruction.rest, 1) IN IF ~chargeIdDisclosureInstruction.ok THEN Fail ELSE
    LET targetPartyExecutingFirm == ReadBytes(chargeIdDisclosureInstruction.rest, 5) IN IF ~targetPartyExecutingFirm.ok THEN Fail ELSE
    LET targetPartyExecutingTrader == ReadBytes(targetPartyExecutingFirm.rest, 6) IN IF ~targetPartyExecutingTrader.ok THEN Fail ELSE
    LET partyDetailStatus == ReadBytes(targetPartyExecutingTrader.rest, 1) IN IF ~partyDetailStatus.ok THEN Fail ELSE
    LET partyDetailStatusInformation == ReadBytes(partyDetailStatus.rest, 1) IN IF ~partyDetailStatusInformation.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyDetailStatusInformation.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ targetPartyIdExecutingTrader               |-> targetPartyIdExecutingTrader.value,
         sideDisclosureInstruction                  |-> sideDisclosureInstruction.value,
         priceDisclosureInstruction                 |-> priceDisclosureInstruction.value,
         leavesQtyDisclosureInstruction             |-> leavesQtyDisclosureInstruction.value,
         lastPxDisclosureInstruction                |-> lastPxDisclosureInstruction.value,
         lastQtyDisclosureInstruction               |-> lastQtyDisclosureInstruction.value,
         freeText5DisclosureInstruction             |-> freeText5DisclosureInstruction.value,
         partyOrderOriginationDisclosureInstruction |-> partyOrderOriginationDisclosureInstruction.value,
         quoteInstruction                           |-> quoteInstruction.value,
         chargeIdDisclosureInstruction              |-> chargeIdDisclosureInstruction.value,
         targetPartyExecutingFirm                   |-> targetPartyExecutingFirm.value,
         targetPartyExecutingTrader                 |-> targetPartyExecutingTrader.value,
         partyDetailStatus                          |-> partyDetailStatus.value,
         partyDetailStatusInformation               |-> partyDetailStatusInformation.value,
         pad6                                       |-> pad6.value ], pad6.rest)

ZeroTargetPartiesComp2 ==
    [ targetPartyIdExecutingTrader               |-> [i \in 1 .. 4 |-> 0],
      sideDisclosureInstruction                  |-> [i \in 1 .. 1 |-> 0],
      priceDisclosureInstruction                 |-> [i \in 1 .. 1 |-> 0],
      leavesQtyDisclosureInstruction             |-> [i \in 1 .. 1 |-> 0],
      lastPxDisclosureInstruction                |-> [i \in 1 .. 1 |-> 0],
      lastQtyDisclosureInstruction               |-> [i \in 1 .. 1 |-> 0],
      freeText5DisclosureInstruction             |-> [i \in 1 .. 1 |-> 0],
      partyOrderOriginationDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      quoteInstruction                           |-> [i \in 1 .. 1 |-> 0],
      chargeIdDisclosureInstruction              |-> [i \in 1 .. 1 |-> 0],
      targetPartyExecutingFirm                   |-> [i \in 1 .. 5 |-> 0],
      targetPartyExecutingTrader                 |-> [i \in 1 .. 6 |-> 0],
      partyDetailStatus                          |-> [i \in 1 .. 1 |-> 0],
      partyDetailStatusInformation               |-> [i \in 1 .. 1 |-> 0],
      pad6                                       |-> [i \in 1 .. 6 |-> 0] ]

(* Target Parties Comp at zero, then each field in turn at the values it is checked at *)
CheckedTargetPartiesComp2 ==
    { ZeroTargetPartiesComp2 }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.sideDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.priceDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.leavesQtyDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.lastPxDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.lastQtyDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.freeText5DisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.partyOrderOriginationDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.quoteInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.chargeIdDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.targetPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.targetPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.partyDetailStatus = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.partyDetailStatusInformation = one] : one \in Sample(1) }
        \cup { [ZeroTargetPartiesComp2 EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Target Parties Comp, written one after another *)
RECURSIVE EncodeTargetPartiesComp2List(_)
EncodeTargetPartiesComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTargetPartiesComp2(Head(messages)) \o EncodeTargetPartiesComp2List(Tail(messages))

(* As many Target Parties Comp as the field that counts them says *)
RECURSIVE ReadTargetPartiesComp2List(_, _)
ReadTargetPartiesComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTargetPartiesComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTargetPartiesComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Target Parties Comp of each kind, for the lists that carry them *)
OneTargetPartiesComp2 == { ZeroTargetPartiesComp2 }

(***************************************************************************)
(* Srqs Update Negotiation Request                                         *)
(***************************************************************************)

SrqsUpdateNegotiationRequest ==
    [ networkMsgId                      : Sample(8),
      pad2                              : Sample(2),
      requestHeaderComp                 : RequestHeaderComp51,
      quoteRefPrice                     : Sample(8),
      underlyingDeltaPercentage         : Sample(8),
      bidPx                             : Sample(8),
      offerPx                           : Sample(8),
      orderQty                          : Sample(8),
      marketSegmentId                   : Sample(4),
      negotiationId                     : Sample(4),
      numberOfRespDisclosureInstruction : Sample(1),
      side                              : Sample(1),
      showLastDealOnClosure             : Sample(1),
      quoteType                         : Sample(1),
      quoteSubType                      : Sample(1),
      respondentType                    : Sample(1),
      tradeAggregationTransType         : Sample(1),
      quoteCondition                    : Sample(1),
      partyExecutingFirm                : Sample(5),
      partyExecutingTrader              : Sample(6),
      freeText5                         : Sample(132),
      partyOrderOriginationTrader       : Sample(132),
      chargeId                          : Sample(132),
      targetPartiesComp                 : SampleLists(OneTargetPartiesComp2) ]

EncodeSrqsUpdateNegotiationRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp51(message.requestHeaderComp)
        \o message.quoteRefPrice
        \o message.underlyingDeltaPercentage
        \o message.bidPx
        \o message.offerPx
        \o message.orderQty
        \o message.marketSegmentId
        \o message.negotiationId
        \o EncodeUIntBE(Len(message.targetPartiesComp), 1)
        \o message.numberOfRespDisclosureInstruction
        \o message.side
        \o message.showLastDealOnClosure
        \o message.quoteType
        \o message.quoteSubType
        \o message.respondentType
        \o message.tradeAggregationTransType
        \o message.quoteCondition
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText5
        \o message.partyOrderOriginationTrader
        \o message.chargeId
        \o EncodeTargetPartiesComp2List(message.targetPartiesComp)

DecodeSrqsUpdateNegotiationRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp51(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET quoteRefPrice == ReadBytes(requestHeaderComp.rest, 8) IN IF ~quoteRefPrice.ok THEN Fail ELSE
    LET underlyingDeltaPercentage == ReadBytes(quoteRefPrice.rest, 8) IN IF ~underlyingDeltaPercentage.ok THEN Fail ELSE
    LET bidPx == ReadBytes(underlyingDeltaPercentage.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(offerPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET noTargetPartyIDs == ReadUIntBE(negotiationId.rest, 1) IN IF ~noTargetPartyIDs.ok THEN Fail ELSE
    LET numberOfRespDisclosureInstruction == ReadBytes(noTargetPartyIDs.rest, 1) IN IF ~numberOfRespDisclosureInstruction.ok THEN Fail ELSE
    LET side == ReadBytes(numberOfRespDisclosureInstruction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET showLastDealOnClosure == ReadBytes(side.rest, 1) IN IF ~showLastDealOnClosure.ok THEN Fail ELSE
    LET quoteType == ReadBytes(showLastDealOnClosure.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET quoteSubType == ReadBytes(quoteType.rest, 1) IN IF ~quoteSubType.ok THEN Fail ELSE
    LET respondentType == ReadBytes(quoteSubType.rest, 1) IN IF ~respondentType.ok THEN Fail ELSE
    LET tradeAggregationTransType == ReadBytes(respondentType.rest, 1) IN IF ~tradeAggregationTransType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(tradeAggregationTransType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quoteCondition.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(partyExecutingTrader.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET partyOrderOriginationTrader == ReadBytes(freeText5.rest, 132) IN IF ~partyOrderOriginationTrader.ok THEN Fail ELSE
    LET chargeId == ReadBytes(partyOrderOriginationTrader.rest, 132) IN IF ~chargeId.ok THEN Fail ELSE
    LET targetPartiesComp == ReadTargetPartiesComp2List(chargeId.rest, noTargetPartyIDs.value) IN IF ~targetPartiesComp.ok THEN Fail ELSE
    Ok([ networkMsgId                      |-> networkMsgId.value,
         pad2                              |-> pad2.value,
         requestHeaderComp                 |-> requestHeaderComp.value,
         quoteRefPrice                     |-> quoteRefPrice.value,
         underlyingDeltaPercentage         |-> underlyingDeltaPercentage.value,
         bidPx                             |-> bidPx.value,
         offerPx                           |-> offerPx.value,
         orderQty                          |-> orderQty.value,
         marketSegmentId                   |-> marketSegmentId.value,
         negotiationId                     |-> negotiationId.value,
         numberOfRespDisclosureInstruction |-> numberOfRespDisclosureInstruction.value,
         side                              |-> side.value,
         showLastDealOnClosure             |-> showLastDealOnClosure.value,
         quoteType                         |-> quoteType.value,
         quoteSubType                      |-> quoteSubType.value,
         respondentType                    |-> respondentType.value,
         tradeAggregationTransType         |-> tradeAggregationTransType.value,
         quoteCondition                    |-> quoteCondition.value,
         partyExecutingFirm                |-> partyExecutingFirm.value,
         partyExecutingTrader              |-> partyExecutingTrader.value,
         freeText5                         |-> freeText5.value,
         partyOrderOriginationTrader       |-> partyOrderOriginationTrader.value,
         chargeId                          |-> chargeId.value,
         targetPartiesComp                 |-> targetPartiesComp.value ], targetPartiesComp.rest)

ZeroSrqsUpdateNegotiationRequest ==
    [ networkMsgId                      |-> [i \in 1 .. 8 |-> 0],
      pad2                              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                 |-> ZeroRequestHeaderComp51,
      quoteRefPrice                     |-> [i \in 1 .. 8 |-> 0],
      underlyingDeltaPercentage         |-> [i \in 1 .. 8 |-> 0],
      bidPx                             |-> [i \in 1 .. 8 |-> 0],
      offerPx                           |-> [i \in 1 .. 8 |-> 0],
      orderQty                          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      negotiationId                     |-> [i \in 1 .. 4 |-> 0],
      numberOfRespDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      showLastDealOnClosure             |-> [i \in 1 .. 1 |-> 0],
      quoteType                         |-> [i \in 1 .. 1 |-> 0],
      quoteSubType                      |-> [i \in 1 .. 1 |-> 0],
      respondentType                    |-> [i \in 1 .. 1 |-> 0],
      tradeAggregationTransType         |-> [i \in 1 .. 1 |-> 0],
      quoteCondition                    |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader              |-> [i \in 1 .. 6 |-> 0],
      freeText5                         |-> [i \in 1 .. 132 |-> 0],
      partyOrderOriginationTrader       |-> [i \in 1 .. 132 |-> 0],
      chargeId                          |-> [i \in 1 .. 132 |-> 0],
      targetPartiesComp                 |-> << >> ]

(* Srqs Update Negotiation Request at zero, then each field in turn at the values it is checked at *)
CheckedSrqsUpdateNegotiationRequest ==
    { ZeroSrqsUpdateNegotiationRequest }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp51 }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.quoteRefPrice = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.underlyingDeltaPercentage = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.numberOfRespDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.showLastDealOnClosure = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.quoteSubType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.respondentType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.tradeAggregationTransType = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.partyOrderOriginationTrader = one] : one \in Sample(132) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.chargeId = one] : one \in Sample(132) }
        \cup { [ZeroSrqsUpdateNegotiationRequest EXCEPT !.targetPartiesComp = one] : one \in SampleLists(OneTargetPartiesComp2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp52 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp52(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp52(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp52 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp52 ==
    { ZeroRequestHeaderComp52 }
        \cup { [ZeroRequestHeaderComp52 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp52 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Subscribe Request: 26 bytes                                             *)
(***************************************************************************)

SubscribeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp52,
      subscriptionScope : Sample(4),
      refApplId         : Sample(1),
      pad3              : Sample(3) ]

EncodeSubscribeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp52(message.requestHeaderComp)
        \o message.subscriptionScope
        \o message.refApplId
        \o message.pad3

DecodeSubscribeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp52(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET subscriptionScope == ReadBytes(requestHeaderComp.rest, 4) IN IF ~subscriptionScope.ok THEN Fail ELSE
    LET refApplId == ReadBytes(subscriptionScope.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET pad3 == ReadBytes(refApplId.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         subscriptionScope |-> subscriptionScope.value,
         refApplId         |-> refApplId.value,
         pad3              |-> pad3.value ], pad3.rest)

ZeroSubscribeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp52,
      subscriptionScope |-> [i \in 1 .. 4 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      pad3              |-> [i \in 1 .. 3 |-> 0] ]

(* Subscribe Request at zero, then each field in turn at the values it is checked at *)
CheckedSubscribeRequest ==
    { ZeroSubscribeRequest }
        \cup { [ZeroSubscribeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSubscribeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSubscribeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp52 }
        \cup { [ZeroSubscribeRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroSubscribeRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroSubscribeRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp53 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp53(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp53(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp53 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp53 ==
    { ZeroRequestHeaderComp53 }
        \cup { [ZeroRequestHeaderComp53 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp53 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Tes Inquire Boundary Prices Request: 34 bytes                           *)
(***************************************************************************)

TesInquireBoundaryPricesRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp53,
      securityId        : Sample(8),
      marketSegmentId   : Sample(4),
      trdType           : Sample(2),
      productComplex    : Sample(1),
      pad1              : Sample(1) ]

EncodeTesInquireBoundaryPricesRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp53(message.requestHeaderComp)
        \o message.securityId
        \o message.marketSegmentId
        \o message.trdType
        \o message.productComplex
        \o message.pad1

DecodeTesInquireBoundaryPricesRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp53(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(marketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(trdType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET pad1 == ReadBytes(productComplex.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         securityId        |-> securityId.value,
         marketSegmentId   |-> marketSegmentId.value,
         trdType           |-> trdType.value,
         productComplex    |-> productComplex.value,
         pad1              |-> pad1.value ], pad1.rest)

ZeroTesInquireBoundaryPricesRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp53,
      securityId        |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      trdType           |-> [i \in 1 .. 2 |-> 0],
      productComplex    |-> [i \in 1 .. 1 |-> 0],
      pad1              |-> [i \in 1 .. 1 |-> 0] ]

(* Tes Inquire Boundary Prices Request at zero, then each field in turn at the values it is checked at *)
CheckedTesInquireBoundaryPricesRequest ==
    { ZeroTesInquireBoundaryPricesRequest }
        \cup { [ZeroTesInquireBoundaryPricesRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroTesInquireBoundaryPricesRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTesInquireBoundaryPricesRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp53 }
        \cup { [ZeroTesInquireBoundaryPricesRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTesInquireBoundaryPricesRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTesInquireBoundaryPricesRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroTesInquireBoundaryPricesRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroTesInquireBoundaryPricesRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp54 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp54(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp54(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp54 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp54 ==
    { ZeroRequestHeaderComp54 }
        \cup { [ZeroRequestHeaderComp54 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp54 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Action Request: 34 bytes                                        *)
(***************************************************************************)

TradingActionRequest ==
    [ networkMsgId               : Sample(8),
      pad2                       : Sample(2),
      requestHeaderComp          : RequestHeaderComp54,
      riskLimitPlatform          : Sample(1),
      orderDeletionInstruction   : Sample(1),
      partyActionType            : Sample(1),
      pad1                       : Sample(1),
      partyIdExecutingUnit       : Sample(4),
      targetPartyIdExecutingUnit : Sample(4),
      pad4                       : Sample(4) ]

EncodeTradingActionRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp54(message.requestHeaderComp)
        \o message.riskLimitPlatform
        \o message.orderDeletionInstruction
        \o message.partyActionType
        \o message.pad1
        \o message.partyIdExecutingUnit
        \o message.targetPartyIdExecutingUnit
        \o message.pad4

DecodeTradingActionRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp54(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET riskLimitPlatform == ReadBytes(requestHeaderComp.rest, 1) IN IF ~riskLimitPlatform.ok THEN Fail ELSE
    LET orderDeletionInstruction == ReadBytes(riskLimitPlatform.rest, 1) IN IF ~orderDeletionInstruction.ok THEN Fail ELSE
    LET partyActionType == ReadBytes(orderDeletionInstruction.rest, 1) IN IF ~partyActionType.ok THEN Fail ELSE
    LET pad1 == ReadBytes(partyActionType.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(pad1.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET targetPartyIdExecutingUnit == ReadBytes(partyIdExecutingUnit.rest, 4) IN IF ~targetPartyIdExecutingUnit.ok THEN Fail ELSE
    LET pad4 == ReadBytes(targetPartyIdExecutingUnit.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId               |-> networkMsgId.value,
         pad2                       |-> pad2.value,
         requestHeaderComp          |-> requestHeaderComp.value,
         riskLimitPlatform          |-> riskLimitPlatform.value,
         orderDeletionInstruction   |-> orderDeletionInstruction.value,
         partyActionType            |-> partyActionType.value,
         pad1                       |-> pad1.value,
         partyIdExecutingUnit       |-> partyIdExecutingUnit.value,
         targetPartyIdExecutingUnit |-> targetPartyIdExecutingUnit.value,
         pad4                       |-> pad4.value ], pad4.rest)

ZeroTradingActionRequest ==
    [ networkMsgId               |-> [i \in 1 .. 8 |-> 0],
      pad2                       |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp          |-> ZeroRequestHeaderComp54,
      riskLimitPlatform          |-> [i \in 1 .. 1 |-> 0],
      orderDeletionInstruction   |-> [i \in 1 .. 1 |-> 0],
      partyActionType            |-> [i \in 1 .. 1 |-> 0],
      pad1                       |-> [i \in 1 .. 1 |-> 0],
      partyIdExecutingUnit       |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingUnit |-> [i \in 1 .. 4 |-> 0],
      pad4                       |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Action Request at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionRequest ==
    { ZeroTradingActionRequest }
        \cup { [ZeroTradingActionRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingActionRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp54 }
        \cup { [ZeroTradingActionRequest EXCEPT !.riskLimitPlatform = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionRequest EXCEPT !.orderDeletionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionRequest EXCEPT !.partyActionType = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingActionRequest EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionRequest EXCEPT !.targetPartyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp55 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp55(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp55(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp55 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp55 ==
    { ZeroRequestHeaderComp55 }
        \cup { [ZeroRequestHeaderComp55 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp55 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Unsubscribe Request: 26 bytes                                           *)
(***************************************************************************)

UnsubscribeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp55,
      refApplSubId      : Sample(4),
      pad4              : Sample(4) ]

EncodeUnsubscribeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp55(message.requestHeaderComp)
        \o message.refApplSubId
        \o message.pad4

DecodeUnsubscribeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp55(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET refApplSubId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~refApplSubId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(refApplSubId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         refApplSubId      |-> refApplSubId.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroUnsubscribeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp55,
      refApplSubId      |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Unsubscribe Request at zero, then each field in turn at the values it is checked at *)
CheckedUnsubscribeRequest ==
    { ZeroUnsubscribeRequest }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp55 }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.refApplSubId = one] : one \in Sample(4) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp56 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp56(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp56(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp56 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp56 ==
    { ZeroRequestHeaderComp56 }
        \cup { [ZeroRequestHeaderComp56 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp56 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Update Reference Price Request: 42 bytes                                *)
(***************************************************************************)

UpdateReferencePriceRequest ==
    [ networkMsgId          : Sample(8),
      pad2                  : Sample(2),
      requestHeaderComp     : RequestHeaderComp56,
      securityId            : Sample(8),
      tradingReferencePrice : Sample(8),
      marketSegmentId       : Sample(4),
      pad4                  : Sample(4) ]

EncodeUpdateReferencePriceRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp56(message.requestHeaderComp)
        \o message.securityId
        \o message.tradingReferencePrice
        \o message.marketSegmentId
        \o message.pad4

DecodeUpdateReferencePriceRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp56(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET tradingReferencePrice == ReadBytes(securityId.rest, 8) IN IF ~tradingReferencePrice.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(tradingReferencePrice.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(marketSegmentId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId          |-> networkMsgId.value,
         pad2                  |-> pad2.value,
         requestHeaderComp     |-> requestHeaderComp.value,
         securityId            |-> securityId.value,
         tradingReferencePrice |-> tradingReferencePrice.value,
         marketSegmentId       |-> marketSegmentId.value,
         pad4                  |-> pad4.value ], pad4.rest)

ZeroUpdateReferencePriceRequest ==
    [ networkMsgId          |-> [i \in 1 .. 8 |-> 0],
      pad2                  |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp     |-> ZeroRequestHeaderComp56,
      securityId            |-> [i \in 1 .. 8 |-> 0],
      tradingReferencePrice |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      pad4                  |-> [i \in 1 .. 4 |-> 0] ]

(* Update Reference Price Request at zero, then each field in turn at the values it is checked at *)
CheckedUpdateReferencePriceRequest ==
    { ZeroUpdateReferencePriceRequest }
        \cup { [ZeroUpdateReferencePriceRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUpdateReferencePriceRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUpdateReferencePriceRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp56 }
        \cup { [ZeroUpdateReferencePriceRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroUpdateReferencePriceRequest EXCEPT !.tradingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroUpdateReferencePriceRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroUpdateReferencePriceRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp57 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp57(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp57(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp57 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp57 ==
    { ZeroRequestHeaderComp57 }
        \cup { [ZeroRequestHeaderComp57 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp57 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Rra Update Base Party Grp Comp: 32 bytes                                *)
(***************************************************************************)

RraUpdateBasePartyGrpComp ==
    [ remainingRiskAllowanceBaseLong  : Sample(8),
      remainingRiskAllowanceBaseShort : Sample(8),
      riskLimitId                     : Sample(4),
      partyDetailExecutingUnit        : Sample(5),
      pad7                            : Sample(7) ]

EncodeRraUpdateBasePartyGrpComp(message) ==
    message.remainingRiskAllowanceBaseLong
        \o message.remainingRiskAllowanceBaseShort
        \o message.riskLimitId
        \o message.partyDetailExecutingUnit
        \o message.pad7

DecodeRraUpdateBasePartyGrpComp(bytes) ==
    LET remainingRiskAllowanceBaseLong == ReadBytes(bytes, 8) IN IF ~remainingRiskAllowanceBaseLong.ok THEN Fail ELSE
    LET remainingRiskAllowanceBaseShort == ReadBytes(remainingRiskAllowanceBaseLong.rest, 8) IN IF ~remainingRiskAllowanceBaseShort.ok THEN Fail ELSE
    LET riskLimitId == ReadBytes(remainingRiskAllowanceBaseShort.rest, 4) IN IF ~riskLimitId.ok THEN Fail ELSE
    LET partyDetailExecutingUnit == ReadBytes(riskLimitId.rest, 5) IN IF ~partyDetailExecutingUnit.ok THEN Fail ELSE
    LET pad7 == ReadBytes(partyDetailExecutingUnit.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ remainingRiskAllowanceBaseLong  |-> remainingRiskAllowanceBaseLong.value,
         remainingRiskAllowanceBaseShort |-> remainingRiskAllowanceBaseShort.value,
         riskLimitId                     |-> riskLimitId.value,
         partyDetailExecutingUnit        |-> partyDetailExecutingUnit.value,
         pad7                            |-> pad7.value ], pad7.rest)

ZeroRraUpdateBasePartyGrpComp ==
    [ remainingRiskAllowanceBaseLong  |-> [i \in 1 .. 8 |-> 0],
      remainingRiskAllowanceBaseShort |-> [i \in 1 .. 8 |-> 0],
      riskLimitId                     |-> [i \in 1 .. 4 |-> 0],
      partyDetailExecutingUnit        |-> [i \in 1 .. 5 |-> 0],
      pad7                            |-> [i \in 1 .. 7 |-> 0] ]

(* Rra Update Base Party Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedRraUpdateBasePartyGrpComp ==
    { ZeroRraUpdateBasePartyGrpComp }
        \cup { [ZeroRraUpdateBasePartyGrpComp EXCEPT !.remainingRiskAllowanceBaseLong = one] : one \in Sample(8) }
        \cup { [ZeroRraUpdateBasePartyGrpComp EXCEPT !.remainingRiskAllowanceBaseShort = one] : one \in Sample(8) }
        \cup { [ZeroRraUpdateBasePartyGrpComp EXCEPT !.riskLimitId = one] : one \in Sample(4) }
        \cup { [ZeroRraUpdateBasePartyGrpComp EXCEPT !.partyDetailExecutingUnit = one] : one \in Sample(5) }
        \cup { [ZeroRraUpdateBasePartyGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Rra Update Base Party Grp Comp, written one after another *)
RECURSIVE EncodeRraUpdateBasePartyGrpCompList(_)
EncodeRraUpdateBasePartyGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRraUpdateBasePartyGrpComp(Head(messages)) \o EncodeRraUpdateBasePartyGrpCompList(Tail(messages))

(* As many Rra Update Base Party Grp Comp as the field that counts them says *)
RECURSIVE ReadRraUpdateBasePartyGrpCompList(_, _)
ReadRraUpdateBasePartyGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRraUpdateBasePartyGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRraUpdateBasePartyGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Rra Update Base Party Grp Comp of each kind, for the lists that carry them *)
OneRraUpdateBasePartyGrpComp == { ZeroRraUpdateBasePartyGrpComp }

(***************************************************************************)
(* Update Remaining Risk Allowance Base Request                            *)
(***************************************************************************)

UpdateRemainingRiskAllowanceBaseRequest ==
    [ networkMsgId              : Sample(8),
      pad2                      : Sample(2),
      requestHeaderComp         : RequestHeaderComp57,
      partitionId               : Sample(2),
      pad4                      : Sample(4),
      rraUpdateBasePartyGrpComp : SampleLists(OneRraUpdateBasePartyGrpComp) ]

EncodeUpdateRemainingRiskAllowanceBaseRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp57(message.requestHeaderComp)
        \o message.partitionId
        \o EncodeUIntLE(Len(message.rraUpdateBasePartyGrpComp), 2)
        \o message.pad4
        \o EncodeRraUpdateBasePartyGrpCompList(message.rraUpdateBasePartyGrpComp)

DecodeUpdateRemainingRiskAllowanceBaseRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp57(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partitionId == ReadBytes(requestHeaderComp.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET noPartyRiskLimits == ReadUIntLE(partitionId.rest, 2) IN IF ~noPartyRiskLimits.ok THEN Fail ELSE
    LET pad4 == ReadBytes(noPartyRiskLimits.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET rraUpdateBasePartyGrpComp == ReadRraUpdateBasePartyGrpCompList(pad4.rest, noPartyRiskLimits.value) IN IF ~rraUpdateBasePartyGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId              |-> networkMsgId.value,
         pad2                      |-> pad2.value,
         requestHeaderComp         |-> requestHeaderComp.value,
         partitionId               |-> partitionId.value,
         pad4                      |-> pad4.value,
         rraUpdateBasePartyGrpComp |-> rraUpdateBasePartyGrpComp.value ], rraUpdateBasePartyGrpComp.rest)

ZeroUpdateRemainingRiskAllowanceBaseRequest ==
    [ networkMsgId              |-> [i \in 1 .. 8 |-> 0],
      pad2                      |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp         |-> ZeroRequestHeaderComp57,
      partitionId               |-> [i \in 1 .. 2 |-> 0],
      pad4                      |-> [i \in 1 .. 4 |-> 0],
      rraUpdateBasePartyGrpComp |-> << >> ]

(* Update Remaining Risk Allowance Base Request at zero, then each field in turn at the values it is checked at *)
CheckedUpdateRemainingRiskAllowanceBaseRequest ==
    { ZeroUpdateRemainingRiskAllowanceBaseRequest }
        \cup { [ZeroUpdateRemainingRiskAllowanceBaseRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUpdateRemainingRiskAllowanceBaseRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUpdateRemainingRiskAllowanceBaseRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp57 }
        \cup { [ZeroUpdateRemainingRiskAllowanceBaseRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroUpdateRemainingRiskAllowanceBaseRequest EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroUpdateRemainingRiskAllowanceBaseRequest EXCEPT !.rraUpdateBasePartyGrpComp = one] : one \in SampleLists(OneRraUpdateBasePartyGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp58 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp58(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp58(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp58 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp58 ==
    { ZeroRequestHeaderComp58 }
        \cup { [ZeroRequestHeaderComp58 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp58 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Side Alloc Ext Grp Comp: 200 bytes                                      *)
(***************************************************************************)

SideAllocExtGrpComp ==
    [ allocQty                                : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      individualAllocId                       : Sample(4),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      pad1                                    : Sample(1),
      tesEnrichmentRuleId                     : Sample(4),
      side                                    : Sample(1),
      tradeAllocStatus                        : Sample(1),
      tradingCapacity                         : Sample(1),
      positionEffect                          : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      orderAttributeRiskReduction             : Sample(1),
      orderOrigination                        : Sample(1),
      account                                 : Sample(2),
      partyIdPositionAccount                  : Sample(32),
      partyIdTakeUpTradingFirm                : Sample(5),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      partyIdOrderOriginationFirm             : Sample(7),
      partyIdBeneficiary                      : Sample(9),
      partyIdLocationId                       : Sample(2),
      custOrderHandlingInst                   : Sample(1),
      complianceText                          : Sample(20),
      partyEndClientIdentification            : Sample(20),
      pad5                                    : Sample(5) ]

EncodeSideAllocExtGrpComp(message) ==
    message.allocQty
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.individualAllocId
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad1
        \o message.tesEnrichmentRuleId
        \o message.side
        \o message.tradeAllocStatus
        \o message.tradingCapacity
        \o message.positionEffect
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.orderAttributeRiskReduction
        \o message.orderOrigination
        \o message.account
        \o message.partyIdPositionAccount
        \o message.partyIdTakeUpTradingFirm
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.partyEndClientIdentification
        \o message.pad5

DecodeSideAllocExtGrpComp(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(allocQty.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(executingTrader.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(individualAllocId.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad1 == ReadBytes(partyExecutingTrader.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET tesEnrichmentRuleId == ReadBytes(pad1.rest, 4) IN IF ~tesEnrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(tesEnrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(side.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradeAllocStatus.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(tradingCapacity.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(positionEffect.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET orderAttributeRiskReduction == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~orderAttributeRiskReduction.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(orderAttributeRiskReduction.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET account == ReadBytes(orderOrigination.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(account.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(partyIdPositionAccount.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyIdTakeUpTradingFirm.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(freeText3.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(partyIdBeneficiary.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET partyEndClientIdentification == ReadBytes(complianceText.rest, 20) IN IF ~partyEndClientIdentification.ok THEN Fail ELSE
    LET pad5 == ReadBytes(partyEndClientIdentification.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ allocQty                                |-> allocQty.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         individualAllocId                       |-> individualAllocId.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         pad1                                    |-> pad1.value,
         tesEnrichmentRuleId                     |-> tesEnrichmentRuleId.value,
         side                                    |-> side.value,
         tradeAllocStatus                        |-> tradeAllocStatus.value,
         tradingCapacity                         |-> tradingCapacity.value,
         positionEffect                          |-> positionEffect.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         orderAttributeRiskReduction             |-> orderAttributeRiskReduction.value,
         orderOrigination                        |-> orderOrigination.value,
         account                                 |-> account.value,
         partyIdPositionAccount                  |-> partyIdPositionAccount.value,
         partyIdTakeUpTradingFirm                |-> partyIdTakeUpTradingFirm.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         partyIdOrderOriginationFirm             |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary                      |-> partyIdBeneficiary.value,
         partyIdLocationId                       |-> partyIdLocationId.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         complianceText                          |-> complianceText.value,
         partyEndClientIdentification            |-> partyEndClientIdentification.value,
         pad5                                    |-> pad5.value ], pad5.rest)

ZeroSideAllocExtGrpComp ==
    [ allocQty                                |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      individualAllocId                       |-> [i \in 1 .. 4 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      pad1                                    |-> [i \in 1 .. 1 |-> 0],
      tesEnrichmentRuleId                     |-> [i \in 1 .. 4 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus                        |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      positionEffect                          |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      orderAttributeRiskReduction             |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      account                                 |-> [i \in 1 .. 2 |-> 0],
      partyIdPositionAccount                  |-> [i \in 1 .. 32 |-> 0],
      partyIdTakeUpTradingFirm                |-> [i \in 1 .. 5 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      partyIdOrderOriginationFirm             |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary                      |-> [i \in 1 .. 9 |-> 0],
      partyIdLocationId                       |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      complianceText                          |-> [i \in 1 .. 20 |-> 0],
      partyEndClientIdentification            |-> [i \in 1 .. 20 |-> 0],
      pad5                                    |-> [i \in 1 .. 5 |-> 0] ]

(* Side Alloc Ext Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocExtGrpComp ==
    { ZeroSideAllocExtGrpComp }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.tesEnrichmentRuleId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.orderAttributeRiskReduction = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyEndClientIdentification = one] : one \in Sample(20) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.pad5 = one] : one \in Sample(5) }

(* A run of Side Alloc Ext Grp Comp, written one after another *)
RECURSIVE EncodeSideAllocExtGrpCompList(_)
EncodeSideAllocExtGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSideAllocExtGrpComp(Head(messages)) \o EncodeSideAllocExtGrpCompList(Tail(messages))

(* As many Side Alloc Ext Grp Comp as the field that counts them says *)
RECURSIVE ReadSideAllocExtGrpCompList(_, _)
ReadSideAllocExtGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSideAllocExtGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSideAllocExtGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Side Alloc Ext Grp Comp of each kind, for the lists that carry them *)
OneSideAllocExtGrpComp == { ZeroSideAllocExtGrpComp }

(***************************************************************************)
(* Trd Instrmnt Leg Grp Comp: 24 bytes                                     *)
(***************************************************************************)

TrdInstrmntLegGrpComp3 ==
    [ legSecurityId : Sample(8),
      legPrice      : Sample(8),
      legQty        : Sample(8) ]

EncodeTrdInstrmntLegGrpComp3(message) ==
    message.legSecurityId
        \o message.legPrice
        \o message.legQty

DecodeTrdInstrmntLegGrpComp3(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSecurityId.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legQty == ReadBytes(legPrice.rest, 8) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legPrice      |-> legPrice.value,
         legQty        |-> legQty.value ], legQty.rest)

ZeroTrdInstrmntLegGrpComp3 ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legPrice      |-> [i \in 1 .. 8 |-> 0],
      legQty        |-> [i \in 1 .. 8 |-> 0] ]

(* Trd Instrmnt Leg Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedTrdInstrmntLegGrpComp3 ==
    { ZeroTrdInstrmntLegGrpComp3 }
        \cup { [ZeroTrdInstrmntLegGrpComp3 EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroTrdInstrmntLegGrpComp3 EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroTrdInstrmntLegGrpComp3 EXCEPT !.legQty = one] : one \in Sample(8) }

(* A run of Trd Instrmnt Leg Grp Comp, written one after another *)
RECURSIVE EncodeTrdInstrmntLegGrpComp3List(_)
EncodeTrdInstrmntLegGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTrdInstrmntLegGrpComp3(Head(messages)) \o EncodeTrdInstrmntLegGrpComp3List(Tail(messages))

(* As many Trd Instrmnt Leg Grp Comp as the field that counts them says *)
RECURSIVE ReadTrdInstrmntLegGrpComp3List(_, _)
ReadTrdInstrmntLegGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTrdInstrmntLegGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTrdInstrmntLegGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trd Instrmnt Leg Grp Comp of each kind, for the lists that carry them *)
OneTrdInstrmntLegGrpComp3 == { ZeroTrdInstrmntLegGrpComp3 }

(***************************************************************************)
(* Instrument Event Grp Comp: 8 bytes                                      *)
(***************************************************************************)

InstrumentEventGrpComp2 ==
    [ eventDate : Sample(4),
      eventType : Sample(1),
      pad3      : Sample(3) ]

EncodeInstrumentEventGrpComp2(message) ==
    message.eventDate
        \o message.eventType
        \o message.pad3

DecodeInstrumentEventGrpComp2(bytes) ==
    LET eventDate == ReadBytes(bytes, 4) IN IF ~eventDate.ok THEN Fail ELSE
    LET eventType == ReadBytes(eventDate.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET pad3 == ReadBytes(eventType.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ eventDate |-> eventDate.value,
         eventType |-> eventType.value,
         pad3      |-> pad3.value ], pad3.rest)

ZeroInstrumentEventGrpComp2 ==
    [ eventDate |-> [i \in 1 .. 4 |-> 0],
      eventType |-> [i \in 1 .. 1 |-> 0],
      pad3      |-> [i \in 1 .. 3 |-> 0] ]

(* Instrument Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentEventGrpComp2 ==
    { ZeroInstrumentEventGrpComp2 }
        \cup { [ZeroInstrumentEventGrpComp2 EXCEPT !.eventDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentEventGrpComp2 EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentEventGrpComp2 EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Instrument Event Grp Comp, written one after another *)
RECURSIVE EncodeInstrumentEventGrpComp2List(_)
EncodeInstrumentEventGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentEventGrpComp2(Head(messages)) \o EncodeInstrumentEventGrpComp2List(Tail(messages))

(* As many Instrument Event Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrumentEventGrpComp2List(_, _)
ReadInstrumentEventGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentEventGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentEventGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Event Grp Comp of each kind, for the lists that carry them *)
OneInstrumentEventGrpComp2 == { ZeroInstrumentEventGrpComp2 }

(***************************************************************************)
(* Instrument Attribute Grp Comp: 40 bytes                                 *)
(***************************************************************************)

InstrumentAttributeGrpComp2 ==
    [ instrAttribType  : Sample(1),
      instrAttribValue : Sample(32),
      pad7             : Sample(7) ]

EncodeInstrumentAttributeGrpComp2(message) ==
    message.instrAttribType
        \o message.instrAttribValue
        \o message.pad7

DecodeInstrumentAttributeGrpComp2(bytes) ==
    LET instrAttribType == ReadBytes(bytes, 1) IN IF ~instrAttribType.ok THEN Fail ELSE
    LET instrAttribValue == ReadBytes(instrAttribType.rest, 32) IN IF ~instrAttribValue.ok THEN Fail ELSE
    LET pad7 == ReadBytes(instrAttribValue.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ instrAttribType  |-> instrAttribType.value,
         instrAttribValue |-> instrAttribValue.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroInstrumentAttributeGrpComp2 ==
    [ instrAttribType  |-> [i \in 1 .. 1 |-> 0],
      instrAttribValue |-> [i \in 1 .. 32 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Instrument Attribute Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentAttributeGrpComp2 ==
    { ZeroInstrumentAttributeGrpComp2 }
        \cup { [ZeroInstrumentAttributeGrpComp2 EXCEPT !.instrAttribType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentAttributeGrpComp2 EXCEPT !.instrAttribValue = one] : one \in Sample(32) }
        \cup { [ZeroInstrumentAttributeGrpComp2 EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Instrument Attribute Grp Comp, written one after another *)
RECURSIVE EncodeInstrumentAttributeGrpComp2List(_)
EncodeInstrumentAttributeGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentAttributeGrpComp2(Head(messages)) \o EncodeInstrumentAttributeGrpComp2List(Tail(messages))

(* As many Instrument Attribute Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrumentAttributeGrpComp2List(_, _)
ReadInstrumentAttributeGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentAttributeGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentAttributeGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Attribute Grp Comp of each kind, for the lists that carry them *)
OneInstrumentAttributeGrpComp2 == { ZeroInstrumentAttributeGrpComp2 }

(***************************************************************************)
(* Underlying Stip Grp Comp: 40 bytes                                      *)
(***************************************************************************)

UnderlyingStipGrpComp2 ==
    [ underlyingStipValue : Sample(32),
      underlyingStipType  : Sample(7),
      pad1                : Sample(1) ]

EncodeUnderlyingStipGrpComp2(message) ==
    message.underlyingStipValue
        \o message.underlyingStipType
        \o message.pad1

DecodeUnderlyingStipGrpComp2(bytes) ==
    LET underlyingStipValue == ReadBytes(bytes, 32) IN IF ~underlyingStipValue.ok THEN Fail ELSE
    LET underlyingStipType == ReadBytes(underlyingStipValue.rest, 7) IN IF ~underlyingStipType.ok THEN Fail ELSE
    LET pad1 == ReadBytes(underlyingStipType.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ underlyingStipValue |-> underlyingStipValue.value,
         underlyingStipType  |-> underlyingStipType.value,
         pad1                |-> pad1.value ], pad1.rest)

ZeroUnderlyingStipGrpComp2 ==
    [ underlyingStipValue |-> [i \in 1 .. 32 |-> 0],
      underlyingStipType  |-> [i \in 1 .. 7 |-> 0],
      pad1                |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Stip Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingStipGrpComp2 ==
    { ZeroUnderlyingStipGrpComp2 }
        \cup { [ZeroUnderlyingStipGrpComp2 EXCEPT !.underlyingStipValue = one] : one \in Sample(32) }
        \cup { [ZeroUnderlyingStipGrpComp2 EXCEPT !.underlyingStipType = one] : one \in Sample(7) }
        \cup { [ZeroUnderlyingStipGrpComp2 EXCEPT !.pad1 = one] : one \in Sample(1) }

(* A run of Underlying Stip Grp Comp, written one after another *)
RECURSIVE EncodeUnderlyingStipGrpComp2List(_)
EncodeUnderlyingStipGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnderlyingStipGrpComp2(Head(messages)) \o EncodeUnderlyingStipGrpComp2List(Tail(messages))

(* As many Underlying Stip Grp Comp as the field that counts them says *)
RECURSIVE ReadUnderlyingStipGrpComp2List(_, _)
ReadUnderlyingStipGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnderlyingStipGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnderlyingStipGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Underlying Stip Grp Comp of each kind, for the lists that carry them *)
OneUnderlyingStipGrpComp2 == { ZeroUnderlyingStipGrpComp2 }

(***************************************************************************)
(* Upload Tes Trade Request                                                *)
(***************************************************************************)

UploadTesTradeRequest ==
    [ networkMsgId               : Sample(8),
      pad2                       : Sample(2),
      requestHeaderComp          : RequestHeaderComp58,
      securityId                 : Sample(8),
      lastPx                     : Sample(8),
      transBkdTime               : Sample(8),
      underlyingPx               : Sample(8),
      relatedClosePrice          : Sample(8),
      relatedTradeQuantity       : Sample(8),
      underlyingQty              : Sample(8),
      marketSegmentId            : Sample(4),
      underlyingSettlementDate   : Sample(4),
      underlyingMaturityDate     : Sample(4),
      relatedTradeId             : Sample(4),
      relatedMarketSegmentId     : Sample(4),
      trdType                    : Sample(2),
      productComplex             : Sample(1),
      tradeReportType            : Sample(1),
      tradePublishIndicator      : Sample(1),
      skipValidations            : Sample(1),
      trdRptStatus               : Sample(1),
      tradePlatform              : Sample(1),
      hedgeType                  : Sample(1),
      partyIdSettlementLocation  : Sample(1),
      valueCheckTypeMinLotSize   : Sample(1),
      tradeReportId              : Sample(20),
      tradeReportText            : Sample(20),
      underlyingSecurityId       : Sample(12),
      underlyingSecurityDesc     : Sample(30),
      underlyingCurrency         : Sample(3),
      underlyingIssuer           : Sample(30),
      swapClearer                : Sample(1),
      sideAllocExtGrpComp        : SampleLists(OneSideAllocExtGrpComp),
      trdInstrmntLegGrpComp      : SampleLists(OneTrdInstrmntLegGrpComp3),
      instrumentEventGrpComp     : SampleLists(OneInstrumentEventGrpComp2),
      instrumentAttributeGrpComp : SampleLists(OneInstrumentAttributeGrpComp2),
      underlyingStipGrpComp      : SampleLists(OneUnderlyingStipGrpComp2) ]

EncodeUploadTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp58(message.requestHeaderComp)
        \o message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.underlyingPx
        \o message.relatedClosePrice
        \o message.relatedTradeQuantity
        \o message.underlyingQty
        \o message.marketSegmentId
        \o message.underlyingSettlementDate
        \o message.underlyingMaturityDate
        \o message.relatedTradeId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.productComplex
        \o message.tradeReportType
        \o message.tradePublishIndicator
        \o EncodeUIntBE(Len(message.sideAllocExtGrpComp), 1)
        \o EncodeUIntBE(Len(message.trdInstrmntLegGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrumentEventGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrumentAttributeGrpComp), 1)
        \o EncodeUIntBE(Len(message.underlyingStipGrpComp), 1)
        \o message.skipValidations
        \o message.trdRptStatus
        \o message.tradePlatform
        \o message.hedgeType
        \o message.partyIdSettlementLocation
        \o message.valueCheckTypeMinLotSize
        \o message.tradeReportId
        \o message.tradeReportText
        \o message.underlyingSecurityId
        \o message.underlyingSecurityDesc
        \o message.underlyingCurrency
        \o message.underlyingIssuer
        \o message.swapClearer
        \o EncodeSideAllocExtGrpCompList(message.sideAllocExtGrpComp)
        \o EncodeTrdInstrmntLegGrpComp3List(message.trdInstrmntLegGrpComp)
        \o EncodeInstrumentEventGrpComp2List(message.instrumentEventGrpComp)
        \o EncodeInstrumentAttributeGrpComp2List(message.instrumentAttributeGrpComp)
        \o EncodeUnderlyingStipGrpComp2List(message.underlyingStipGrpComp)

DecodeUploadTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp58(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET underlyingPx == ReadBytes(transBkdTime.rest, 8) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(underlyingPx.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET relatedTradeQuantity == ReadBytes(relatedClosePrice.rest, 8) IN IF ~relatedTradeQuantity.ok THEN Fail ELSE
    LET underlyingQty == ReadBytes(relatedTradeQuantity.rest, 8) IN IF ~underlyingQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(underlyingQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingSettlementDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~underlyingSettlementDate.ok THEN Fail ELSE
    LET underlyingMaturityDate == ReadBytes(underlyingSettlementDate.rest, 4) IN IF ~underlyingMaturityDate.ok THEN Fail ELSE
    LET relatedTradeId == ReadBytes(underlyingMaturityDate.rest, 4) IN IF ~relatedTradeId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(relatedTradeId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(trdType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(productComplex.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(tradeReportType.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradePublishIndicator.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(noSideAllocs.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET noEvents == ReadUIntBE(noLegs.rest, 1) IN IF ~noEvents.ok THEN Fail ELSE
    LET noInstrAttrib == ReadUIntBE(noEvents.rest, 1) IN IF ~noInstrAttrib.ok THEN Fail ELSE
    LET noUnderlyingStips == ReadUIntBE(noInstrAttrib.rest, 1) IN IF ~noUnderlyingStips.ok THEN Fail ELSE
    LET skipValidations == ReadBytes(noUnderlyingStips.rest, 1) IN IF ~skipValidations.ok THEN Fail ELSE
    LET trdRptStatus == ReadBytes(skipValidations.rest, 1) IN IF ~trdRptStatus.ok THEN Fail ELSE
    LET tradePlatform == ReadBytes(trdRptStatus.rest, 1) IN IF ~tradePlatform.ok THEN Fail ELSE
    LET hedgeType == ReadBytes(tradePlatform.rest, 1) IN IF ~hedgeType.ok THEN Fail ELSE
    LET partyIdSettlementLocation == ReadBytes(hedgeType.rest, 1) IN IF ~partyIdSettlementLocation.ok THEN Fail ELSE
    LET valueCheckTypeMinLotSize == ReadBytes(partyIdSettlementLocation.rest, 1) IN IF ~valueCheckTypeMinLotSize.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(valueCheckTypeMinLotSize.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(tradeReportId.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET underlyingSecurityId == ReadBytes(tradeReportText.rest, 12) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET underlyingSecurityDesc == ReadBytes(underlyingSecurityId.rest, 30) IN IF ~underlyingSecurityDesc.ok THEN Fail ELSE
    LET underlyingCurrency == ReadBytes(underlyingSecurityDesc.rest, 3) IN IF ~underlyingCurrency.ok THEN Fail ELSE
    LET underlyingIssuer == ReadBytes(underlyingCurrency.rest, 30) IN IF ~underlyingIssuer.ok THEN Fail ELSE
    LET swapClearer == ReadBytes(underlyingIssuer.rest, 1) IN IF ~swapClearer.ok THEN Fail ELSE
    LET sideAllocExtGrpComp == ReadSideAllocExtGrpCompList(swapClearer.rest, noSideAllocs.value) IN IF ~sideAllocExtGrpComp.ok THEN Fail ELSE
    LET trdInstrmntLegGrpComp == ReadTrdInstrmntLegGrpComp3List(sideAllocExtGrpComp.rest, noLegs.value) IN IF ~trdInstrmntLegGrpComp.ok THEN Fail ELSE
    LET instrumentEventGrpComp == ReadInstrumentEventGrpComp2List(trdInstrmntLegGrpComp.rest, noEvents.value) IN IF ~instrumentEventGrpComp.ok THEN Fail ELSE
    LET instrumentAttributeGrpComp == ReadInstrumentAttributeGrpComp2List(instrumentEventGrpComp.rest, noInstrAttrib.value) IN IF ~instrumentAttributeGrpComp.ok THEN Fail ELSE
    LET underlyingStipGrpComp == ReadUnderlyingStipGrpComp2List(instrumentAttributeGrpComp.rest, noUnderlyingStips.value) IN IF ~underlyingStipGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId               |-> networkMsgId.value,
         pad2                       |-> pad2.value,
         requestHeaderComp          |-> requestHeaderComp.value,
         securityId                 |-> securityId.value,
         lastPx                     |-> lastPx.value,
         transBkdTime               |-> transBkdTime.value,
         underlyingPx               |-> underlyingPx.value,
         relatedClosePrice          |-> relatedClosePrice.value,
         relatedTradeQuantity       |-> relatedTradeQuantity.value,
         underlyingQty              |-> underlyingQty.value,
         marketSegmentId            |-> marketSegmentId.value,
         underlyingSettlementDate   |-> underlyingSettlementDate.value,
         underlyingMaturityDate     |-> underlyingMaturityDate.value,
         relatedTradeId             |-> relatedTradeId.value,
         relatedMarketSegmentId     |-> relatedMarketSegmentId.value,
         trdType                    |-> trdType.value,
         productComplex             |-> productComplex.value,
         tradeReportType            |-> tradeReportType.value,
         tradePublishIndicator      |-> tradePublishIndicator.value,
         skipValidations            |-> skipValidations.value,
         trdRptStatus               |-> trdRptStatus.value,
         tradePlatform              |-> tradePlatform.value,
         hedgeType                  |-> hedgeType.value,
         partyIdSettlementLocation  |-> partyIdSettlementLocation.value,
         valueCheckTypeMinLotSize   |-> valueCheckTypeMinLotSize.value,
         tradeReportId              |-> tradeReportId.value,
         tradeReportText            |-> tradeReportText.value,
         underlyingSecurityId       |-> underlyingSecurityId.value,
         underlyingSecurityDesc     |-> underlyingSecurityDesc.value,
         underlyingCurrency         |-> underlyingCurrency.value,
         underlyingIssuer           |-> underlyingIssuer.value,
         swapClearer                |-> swapClearer.value,
         sideAllocExtGrpComp        |-> sideAllocExtGrpComp.value,
         trdInstrmntLegGrpComp      |-> trdInstrmntLegGrpComp.value,
         instrumentEventGrpComp     |-> instrumentEventGrpComp.value,
         instrumentAttributeGrpComp |-> instrumentAttributeGrpComp.value,
         underlyingStipGrpComp      |-> underlyingStipGrpComp.value ], underlyingStipGrpComp.rest)

ZeroUploadTesTradeRequest ==
    [ networkMsgId               |-> [i \in 1 .. 8 |-> 0],
      pad2                       |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp          |-> ZeroRequestHeaderComp58,
      securityId                 |-> [i \in 1 .. 8 |-> 0],
      lastPx                     |-> [i \in 1 .. 8 |-> 0],
      transBkdTime               |-> [i \in 1 .. 8 |-> 0],
      underlyingPx               |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice          |-> [i \in 1 .. 8 |-> 0],
      relatedTradeQuantity       |-> [i \in 1 .. 8 |-> 0],
      underlyingQty              |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId            |-> [i \in 1 .. 4 |-> 0],
      underlyingSettlementDate   |-> [i \in 1 .. 4 |-> 0],
      underlyingMaturityDate     |-> [i \in 1 .. 4 |-> 0],
      relatedTradeId             |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId     |-> [i \in 1 .. 4 |-> 0],
      trdType                    |-> [i \in 1 .. 2 |-> 0],
      productComplex             |-> [i \in 1 .. 1 |-> 0],
      tradeReportType            |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator      |-> [i \in 1 .. 1 |-> 0],
      skipValidations            |-> [i \in 1 .. 1 |-> 0],
      trdRptStatus               |-> [i \in 1 .. 1 |-> 0],
      tradePlatform              |-> [i \in 1 .. 1 |-> 0],
      hedgeType                  |-> [i \in 1 .. 1 |-> 0],
      partyIdSettlementLocation  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeMinLotSize   |-> [i \in 1 .. 1 |-> 0],
      tradeReportId              |-> [i \in 1 .. 20 |-> 0],
      tradeReportText            |-> [i \in 1 .. 20 |-> 0],
      underlyingSecurityId       |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityDesc     |-> [i \in 1 .. 30 |-> 0],
      underlyingCurrency         |-> [i \in 1 .. 3 |-> 0],
      underlyingIssuer           |-> [i \in 1 .. 30 |-> 0],
      swapClearer                |-> [i \in 1 .. 1 |-> 0],
      sideAllocExtGrpComp        |-> << >>,
      trdInstrmntLegGrpComp      |-> << >>,
      instrumentEventGrpComp     |-> << >>,
      instrumentAttributeGrpComp |-> << >>,
      underlyingStipGrpComp      |-> << >> ]

(* Upload Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedUploadTesTradeRequest ==
    { ZeroUploadTesTradeRequest }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp58 }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingPx = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.relatedTradeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingQty = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingSettlementDate = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingMaturityDate = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.relatedTradeId = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.skipValidations = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.trdRptStatus = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradePlatform = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.hedgeType = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.partyIdSettlementLocation = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.valueCheckTypeMinLotSize = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingSecurityId = one] : one \in Sample(12) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingSecurityDesc = one] : one \in Sample(30) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingIssuer = one] : one \in Sample(30) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.swapClearer = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.sideAllocExtGrpComp = one] : one \in SampleLists(OneSideAllocExtGrpComp) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.trdInstrmntLegGrpComp = one] : one \in SampleLists(OneTrdInstrmntLegGrpComp3) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.instrumentEventGrpComp = one] : one \in SampleLists(OneInstrumentEventGrpComp2) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.instrumentAttributeGrpComp = one] : one \in SampleLists(OneInstrumentAttributeGrpComp2) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingStipGrpComp = one] : one \in SampleLists(OneUnderlyingStipGrpComp2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp59 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp59(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp59(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp59 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp59 ==
    { ZeroRequestHeaderComp59 }
        \cup { [ZeroRequestHeaderComp59 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp59 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* User Login Request: 58 bytes                                            *)
(***************************************************************************)

UserLoginRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp59,
      username          : Sample(4),
      password          : Sample(32),
      pad4              : Sample(4) ]

EncodeUserLoginRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp59(message.requestHeaderComp)
        \o message.username
        \o message.password
        \o message.pad4

DecodeUserLoginRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp59(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET username == ReadBytes(requestHeaderComp.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET pad4 == ReadBytes(password.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         username          |-> username.value,
         password          |-> password.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroUserLoginRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp59,
      username          |-> [i \in 1 .. 4 |-> 0],
      password          |-> [i \in 1 .. 32 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Login Request at zero, then each field in turn at the values it is checked at *)
CheckedUserLoginRequest ==
    { ZeroUserLoginRequest }
        \cup { [ZeroUserLoginRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLoginRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLoginRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp59 }
        \cup { [ZeroUserLoginRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLoginRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroUserLoginRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp60 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp60(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp60(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp60 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp60 ==
    { ZeroRequestHeaderComp60 }
        \cup { [ZeroRequestHeaderComp60 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp60 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* User Login Request Encrypted: 706 bytes                                 *)
(***************************************************************************)

UserLoginRequestEncrypted ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp60,
      username          : Sample(4),
      encryptedPassword : Sample(684) ]

EncodeUserLoginRequestEncrypted(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp60(message.requestHeaderComp)
        \o message.username
        \o message.encryptedPassword

DecodeUserLoginRequestEncrypted(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp60(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET username == ReadBytes(requestHeaderComp.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET encryptedPassword == ReadBytes(username.rest, 684) IN IF ~encryptedPassword.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         username          |-> username.value,
         encryptedPassword |-> encryptedPassword.value ], encryptedPassword.rest)

ZeroUserLoginRequestEncrypted ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp60,
      username          |-> [i \in 1 .. 4 |-> 0],
      encryptedPassword |-> [i \in 1 .. 684 |-> 0] ]

(* User Login Request Encrypted at zero, then each field in turn at the values it is checked at *)
CheckedUserLoginRequestEncrypted ==
    { ZeroUserLoginRequestEncrypted }
        \cup { [ZeroUserLoginRequestEncrypted EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLoginRequestEncrypted EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLoginRequestEncrypted EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp60 }
        \cup { [ZeroUserLoginRequestEncrypted EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLoginRequestEncrypted EXCEPT !.encryptedPassword = one] : one \in Sample(684) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp61 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp61(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp61(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp61 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp61 ==
    { ZeroRequestHeaderComp61 }
        \cup { [ZeroRequestHeaderComp61 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp61 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* User Logout Request: 26 bytes                                           *)
(***************************************************************************)

UserLogoutRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp61,
      username          : Sample(4),
      pad4              : Sample(4) ]

EncodeUserLogoutRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp61(message.requestHeaderComp)
        \o message.username
        \o message.pad4

DecodeUserLogoutRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp61(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET username == ReadBytes(requestHeaderComp.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET pad4 == ReadBytes(username.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         username          |-> username.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroUserLogoutRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp61,
      username          |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedUserLogoutRequest ==
    { ZeroUserLogoutRequest }
        \cup { [ZeroUserLogoutRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp61 }
        \cup { [ZeroUserLogoutRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

AddComplexInstrumentRequestCode == 10301  \* 0x283d
AddFlexibleInstrumentRequestCode == 10309  \* 0x2845
AddScaledSimpleInstrumentRequestCode == 10327  \* 0x2857
AmendBasketTradeRequestCode == 10629  \* 0x2985
ApproveBasketTradeRequestCode == 10623  \* 0x297f
ApproveReverseTesTradeRequestCode == 10631  \* 0x2987
ApproveTesTradeRequestCode == 10603  \* 0x296b
BasketRollRequestCode == 10633  \* 0x2989
CrossRequestCode == 10118  \* 0x2786
DeleteAllOrderRequestCode == 10120  \* 0x2788
DeleteAllQuoteRequestCode == 10408  \* 0x28a8
DeleteBasketTradeRequestCode == 10622  \* 0x297e
DeleteClipRequestCode == 10132  \* 0x2794
DeleteOrderRequestCode == 10142  \* 0x279e
DeleteTesTradeRequestCode == 10602  \* 0x296a
EnterBasketTradeRequestCode == 10620  \* 0x297c
EnterClipRequestCode == 10131  \* 0x2793
EnterTesTradeRequestCode == 10600  \* 0x2968
HeartbeatCode == 10011  \* 0x271b
InquireEnrichmentRuleIdListRequestCode == 10040  \* 0x2738
InquireMmParameterRequestCode == 10305  \* 0x2841
InquireMarginBasedRiskLimitRequestCode == 10323  \* 0x2853
InquirePreTradeRiskLimitsRequestCode == 10311  \* 0x2847
InquireSessionListRequestCode == 10035  \* 0x2733
InquireUserRequestCode == 10038  \* 0x2736
LogonRequestCode == 10000  \* 0x2710
LogonRequestEncryptedCode == 19000  \* 0x4a38
LogoutRequestCode == 10002  \* 0x2712
MmParameterDefinitionRequestCode == 10303  \* 0x283f
MassOrderCode == 10115  \* 0x2783
MassQuoteRequestCode == 10405  \* 0x28a5
ModifyBasketTradeRequestCode == 10621  \* 0x297d
ModifyOrderRequestCode == 10140  \* 0x279c
ModifyOrderShortRequestCode == 10141  \* 0x279d
ModifyTesTradeRequestCode == 10601  \* 0x2969
NewOrderRequestCode == 10138  \* 0x279a
NewOrderShortRequestCode == 10139  \* 0x279b
PingRequestCode == 10320  \* 0x2850
PreTradeRiskLimitsDefinitionRequestCode == 10312  \* 0x2848
QuoteActivationRequestCode == 10403  \* 0x28a3
RfqRequestCode == 10401  \* 0x28a1
RetransmitMeMessageRequestCode == 10026  \* 0x272a
RetransmitRequestCode == 10008  \* 0x2718
ReverseTesTradeRequestCode == 10630  \* 0x2986
SrqsEnterQuoteRequestCode == 10702  \* 0x29ce
SrqsHitQuoteRequestCode == 10704  \* 0x29d0
SrqsInquireSmartRespondentRequestCode == 10718  \* 0x29de
SrqsOpenNegotiationRequestCode == 10700  \* 0x29cc
SrqsQuoteSnapshotRequestCode == 10720  \* 0x29e0
SrqsQuotingStatusRequestCode == 10717  \* 0x29dd
SrqsUpdateDealStatusRequestCode == 10706  \* 0x29d2
SrqsUpdateNegotiationRequestCode == 10701  \* 0x29cd
SubscribeRequestCode == 10025  \* 0x2729
TesInquireBoundaryPricesRequestCode == 10329  \* 0x2859
TradingActionRequestCode == 10904  \* 0x2a98
UnsubscribeRequestCode == 10006  \* 0x2716
UpdateReferencePriceRequestCode == 10331  \* 0x285b
UpdateRemainingRiskAllowanceBaseRequestCode == 10325  \* 0x2855
UploadTesTradeRequestCode == 10612  \* 0x2974
UserLoginRequestCode == 10018  \* 0x2722
UserLoginRequestEncryptedCode == 19018  \* 0x4a4a
UserLogoutRequestCode == 10029  \* 0x272d

ClientPayload ==
    [ tag : {AddComplexInstrumentRequestCode}, body : AddComplexInstrumentRequest ]
        \cup [ tag : {AddFlexibleInstrumentRequestCode}, body : AddFlexibleInstrumentRequest ]
        \cup [ tag : {AddScaledSimpleInstrumentRequestCode}, body : AddScaledSimpleInstrumentRequest ]
        \cup [ tag : {AmendBasketTradeRequestCode}, body : AmendBasketTradeRequest ]
        \cup [ tag : {ApproveBasketTradeRequestCode}, body : ApproveBasketTradeRequest ]
        \cup [ tag : {ApproveReverseTesTradeRequestCode}, body : ApproveReverseTesTradeRequest ]
        \cup [ tag : {ApproveTesTradeRequestCode}, body : ApproveTesTradeRequest ]
        \cup [ tag : {BasketRollRequestCode}, body : BasketRollRequest ]
        \cup [ tag : {CrossRequestCode}, body : CrossRequest ]
        \cup [ tag : {DeleteAllOrderRequestCode}, body : DeleteAllOrderRequest ]
        \cup [ tag : {DeleteAllQuoteRequestCode}, body : DeleteAllQuoteRequest ]
        \cup [ tag : {DeleteBasketTradeRequestCode}, body : DeleteBasketTradeRequest ]
        \cup [ tag : {DeleteClipRequestCode}, body : DeleteClipRequest ]
        \cup [ tag : {DeleteOrderRequestCode}, body : DeleteOrderRequest ]
        \cup [ tag : {DeleteTesTradeRequestCode}, body : DeleteTesTradeRequest ]
        \cup [ tag : {EnterBasketTradeRequestCode}, body : EnterBasketTradeRequest ]
        \cup [ tag : {EnterClipRequestCode}, body : EnterClipRequest ]
        \cup [ tag : {EnterTesTradeRequestCode}, body : EnterTesTradeRequest ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {InquireEnrichmentRuleIdListRequestCode}, body : InquireEnrichmentRuleIdListRequest ]
        \cup [ tag : {InquireMmParameterRequestCode}, body : InquireMmParameterRequest ]
        \cup [ tag : {InquireMarginBasedRiskLimitRequestCode}, body : InquireMarginBasedRiskLimitRequest ]
        \cup [ tag : {InquirePreTradeRiskLimitsRequestCode}, body : InquirePreTradeRiskLimitsRequest ]
        \cup [ tag : {InquireSessionListRequestCode}, body : InquireSessionListRequest ]
        \cup [ tag : {InquireUserRequestCode}, body : InquireUserRequest ]
        \cup [ tag : {LogonRequestCode}, body : LogonRequest ]
        \cup [ tag : {LogonRequestEncryptedCode}, body : LogonRequestEncrypted ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {MmParameterDefinitionRequestCode}, body : MmParameterDefinitionRequest ]
        \cup [ tag : {MassOrderCode}, body : MassOrder ]
        \cup [ tag : {MassQuoteRequestCode}, body : MassQuoteRequest ]
        \cup [ tag : {ModifyBasketTradeRequestCode}, body : ModifyBasketTradeRequest ]
        \cup [ tag : {ModifyOrderRequestCode}, body : ModifyOrderRequest ]
        \cup [ tag : {ModifyOrderShortRequestCode}, body : ModifyOrderShortRequest ]
        \cup [ tag : {ModifyTesTradeRequestCode}, body : ModifyTesTradeRequest ]
        \cup [ tag : {NewOrderRequestCode}, body : NewOrderRequest ]
        \cup [ tag : {NewOrderShortRequestCode}, body : NewOrderShortRequest ]
        \cup [ tag : {PingRequestCode}, body : PingRequest ]
        \cup [ tag : {PreTradeRiskLimitsDefinitionRequestCode}, body : PreTradeRiskLimitsDefinitionRequest ]
        \cup [ tag : {QuoteActivationRequestCode}, body : QuoteActivationRequest ]
        \cup [ tag : {RfqRequestCode}, body : RfqRequest ]
        \cup [ tag : {RetransmitMeMessageRequestCode}, body : RetransmitMeMessageRequest ]
        \cup [ tag : {RetransmitRequestCode}, body : RetransmitRequest ]
        \cup [ tag : {ReverseTesTradeRequestCode}, body : ReverseTesTradeRequest ]
        \cup [ tag : {SrqsEnterQuoteRequestCode}, body : SrqsEnterQuoteRequest ]
        \cup [ tag : {SrqsHitQuoteRequestCode}, body : SrqsHitQuoteRequest ]
        \cup [ tag : {SrqsInquireSmartRespondentRequestCode}, body : SrqsInquireSmartRespondentRequest ]
        \cup [ tag : {SrqsOpenNegotiationRequestCode}, body : SrqsOpenNegotiationRequest ]
        \cup [ tag : {SrqsQuoteSnapshotRequestCode}, body : SrqsQuoteSnapshotRequest ]
        \cup [ tag : {SrqsQuotingStatusRequestCode}, body : SrqsQuotingStatusRequest ]
        \cup [ tag : {SrqsUpdateDealStatusRequestCode}, body : SrqsUpdateDealStatusRequest ]
        \cup [ tag : {SrqsUpdateNegotiationRequestCode}, body : SrqsUpdateNegotiationRequest ]
        \cup [ tag : {SubscribeRequestCode}, body : SubscribeRequest ]
        \cup [ tag : {TesInquireBoundaryPricesRequestCode}, body : TesInquireBoundaryPricesRequest ]
        \cup [ tag : {TradingActionRequestCode}, body : TradingActionRequest ]
        \cup [ tag : {UnsubscribeRequestCode}, body : UnsubscribeRequest ]
        \cup [ tag : {UpdateReferencePriceRequestCode}, body : UpdateReferencePriceRequest ]
        \cup [ tag : {UpdateRemainingRiskAllowanceBaseRequestCode}, body : UpdateRemainingRiskAllowanceBaseRequest ]
        \cup [ tag : {UploadTesTradeRequestCode}, body : UploadTesTradeRequest ]
        \cup [ tag : {UserLoginRequestCode}, body : UserLoginRequest ]
        \cup [ tag : {UserLoginRequestEncryptedCode}, body : UserLoginRequestEncrypted ]
        \cup [ tag : {UserLogoutRequestCode}, body : UserLogoutRequest ]

EncodeClientPayload(message) ==
    CASE message.tag = AddComplexInstrumentRequestCode -> EncodeAddComplexInstrumentRequest(message.body)
      [] message.tag = AddFlexibleInstrumentRequestCode -> EncodeAddFlexibleInstrumentRequest(message.body)
      [] message.tag = AddScaledSimpleInstrumentRequestCode -> EncodeAddScaledSimpleInstrumentRequest(message.body)
      [] message.tag = AmendBasketTradeRequestCode -> EncodeAmendBasketTradeRequest(message.body)
      [] message.tag = ApproveBasketTradeRequestCode -> EncodeApproveBasketTradeRequest(message.body)
      [] message.tag = ApproveReverseTesTradeRequestCode -> EncodeApproveReverseTesTradeRequest(message.body)
      [] message.tag = ApproveTesTradeRequestCode -> EncodeApproveTesTradeRequest(message.body)
      [] message.tag = BasketRollRequestCode -> EncodeBasketRollRequest(message.body)
      [] message.tag = CrossRequestCode -> EncodeCrossRequest(message.body)
      [] message.tag = DeleteAllOrderRequestCode -> EncodeDeleteAllOrderRequest(message.body)
      [] message.tag = DeleteAllQuoteRequestCode -> EncodeDeleteAllQuoteRequest(message.body)
      [] message.tag = DeleteBasketTradeRequestCode -> EncodeDeleteBasketTradeRequest(message.body)
      [] message.tag = DeleteClipRequestCode -> EncodeDeleteClipRequest(message.body)
      [] message.tag = DeleteOrderRequestCode -> EncodeDeleteOrderRequest(message.body)
      [] message.tag = DeleteTesTradeRequestCode -> EncodeDeleteTesTradeRequest(message.body)
      [] message.tag = EnterBasketTradeRequestCode -> EncodeEnterBasketTradeRequest(message.body)
      [] message.tag = EnterClipRequestCode -> EncodeEnterClipRequest(message.body)
      [] message.tag = EnterTesTradeRequestCode -> EncodeEnterTesTradeRequest(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = InquireEnrichmentRuleIdListRequestCode -> EncodeInquireEnrichmentRuleIdListRequest(message.body)
      [] message.tag = InquireMmParameterRequestCode -> EncodeInquireMmParameterRequest(message.body)
      [] message.tag = InquireMarginBasedRiskLimitRequestCode -> EncodeInquireMarginBasedRiskLimitRequest(message.body)
      [] message.tag = InquirePreTradeRiskLimitsRequestCode -> EncodeInquirePreTradeRiskLimitsRequest(message.body)
      [] message.tag = InquireSessionListRequestCode -> EncodeInquireSessionListRequest(message.body)
      [] message.tag = InquireUserRequestCode -> EncodeInquireUserRequest(message.body)
      [] message.tag = LogonRequestCode -> EncodeLogonRequest(message.body)
      [] message.tag = LogonRequestEncryptedCode -> EncodeLogonRequestEncrypted(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = MmParameterDefinitionRequestCode -> EncodeMmParameterDefinitionRequest(message.body)
      [] message.tag = MassOrderCode -> EncodeMassOrder(message.body)
      [] message.tag = MassQuoteRequestCode -> EncodeMassQuoteRequest(message.body)
      [] message.tag = ModifyBasketTradeRequestCode -> EncodeModifyBasketTradeRequest(message.body)
      [] message.tag = ModifyOrderRequestCode -> EncodeModifyOrderRequest(message.body)
      [] message.tag = ModifyOrderShortRequestCode -> EncodeModifyOrderShortRequest(message.body)
      [] message.tag = ModifyTesTradeRequestCode -> EncodeModifyTesTradeRequest(message.body)
      [] message.tag = NewOrderRequestCode -> EncodeNewOrderRequest(message.body)
      [] message.tag = NewOrderShortRequestCode -> EncodeNewOrderShortRequest(message.body)
      [] message.tag = PingRequestCode -> EncodePingRequest(message.body)
      [] message.tag = PreTradeRiskLimitsDefinitionRequestCode -> EncodePreTradeRiskLimitsDefinitionRequest(message.body)
      [] message.tag = QuoteActivationRequestCode -> EncodeQuoteActivationRequest(message.body)
      [] message.tag = RfqRequestCode -> EncodeRfqRequest(message.body)
      [] message.tag = RetransmitMeMessageRequestCode -> EncodeRetransmitMeMessageRequest(message.body)
      [] message.tag = RetransmitRequestCode -> EncodeRetransmitRequest(message.body)
      [] message.tag = ReverseTesTradeRequestCode -> EncodeReverseTesTradeRequest(message.body)
      [] message.tag = SrqsEnterQuoteRequestCode -> EncodeSrqsEnterQuoteRequest(message.body)
      [] message.tag = SrqsHitQuoteRequestCode -> EncodeSrqsHitQuoteRequest(message.body)
      [] message.tag = SrqsInquireSmartRespondentRequestCode -> EncodeSrqsInquireSmartRespondentRequest(message.body)
      [] message.tag = SrqsOpenNegotiationRequestCode -> EncodeSrqsOpenNegotiationRequest(message.body)
      [] message.tag = SrqsQuoteSnapshotRequestCode -> EncodeSrqsQuoteSnapshotRequest(message.body)
      [] message.tag = SrqsQuotingStatusRequestCode -> EncodeSrqsQuotingStatusRequest(message.body)
      [] message.tag = SrqsUpdateDealStatusRequestCode -> EncodeSrqsUpdateDealStatusRequest(message.body)
      [] message.tag = SrqsUpdateNegotiationRequestCode -> EncodeSrqsUpdateNegotiationRequest(message.body)
      [] message.tag = SubscribeRequestCode -> EncodeSubscribeRequest(message.body)
      [] message.tag = TesInquireBoundaryPricesRequestCode -> EncodeTesInquireBoundaryPricesRequest(message.body)
      [] message.tag = TradingActionRequestCode -> EncodeTradingActionRequest(message.body)
      [] message.tag = UnsubscribeRequestCode -> EncodeUnsubscribeRequest(message.body)
      [] message.tag = UpdateReferencePriceRequestCode -> EncodeUpdateReferencePriceRequest(message.body)
      [] message.tag = UpdateRemainingRiskAllowanceBaseRequestCode -> EncodeUpdateRemainingRiskAllowanceBaseRequest(message.body)
      [] message.tag = UploadTesTradeRequestCode -> EncodeUploadTesTradeRequest(message.body)
      [] message.tag = UserLoginRequestCode -> EncodeUserLoginRequest(message.body)
      [] message.tag = UserLoginRequestEncryptedCode -> EncodeUserLoginRequestEncrypted(message.body)
      [] message.tag = UserLogoutRequestCode -> EncodeUserLogoutRequest(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = AddComplexInstrumentRequestCode -> DecodeAddComplexInstrumentRequest(bytes)
              [] tag = AddFlexibleInstrumentRequestCode -> DecodeAddFlexibleInstrumentRequest(bytes)
              [] tag = AddScaledSimpleInstrumentRequestCode -> DecodeAddScaledSimpleInstrumentRequest(bytes)
              [] tag = AmendBasketTradeRequestCode -> DecodeAmendBasketTradeRequest(bytes)
              [] tag = ApproveBasketTradeRequestCode -> DecodeApproveBasketTradeRequest(bytes)
              [] tag = ApproveReverseTesTradeRequestCode -> DecodeApproveReverseTesTradeRequest(bytes)
              [] tag = ApproveTesTradeRequestCode -> DecodeApproveTesTradeRequest(bytes)
              [] tag = BasketRollRequestCode -> DecodeBasketRollRequest(bytes)
              [] tag = CrossRequestCode -> DecodeCrossRequest(bytes)
              [] tag = DeleteAllOrderRequestCode -> DecodeDeleteAllOrderRequest(bytes)
              [] tag = DeleteAllQuoteRequestCode -> DecodeDeleteAllQuoteRequest(bytes)
              [] tag = DeleteBasketTradeRequestCode -> DecodeDeleteBasketTradeRequest(bytes)
              [] tag = DeleteClipRequestCode -> DecodeDeleteClipRequest(bytes)
              [] tag = DeleteOrderRequestCode -> DecodeDeleteOrderRequest(bytes)
              [] tag = DeleteTesTradeRequestCode -> DecodeDeleteTesTradeRequest(bytes)
              [] tag = EnterBasketTradeRequestCode -> DecodeEnterBasketTradeRequest(bytes)
              [] tag = EnterClipRequestCode -> DecodeEnterClipRequest(bytes)
              [] tag = EnterTesTradeRequestCode -> DecodeEnterTesTradeRequest(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = InquireEnrichmentRuleIdListRequestCode -> DecodeInquireEnrichmentRuleIdListRequest(bytes)
              [] tag = InquireMmParameterRequestCode -> DecodeInquireMmParameterRequest(bytes)
              [] tag = InquireMarginBasedRiskLimitRequestCode -> DecodeInquireMarginBasedRiskLimitRequest(bytes)
              [] tag = InquirePreTradeRiskLimitsRequestCode -> DecodeInquirePreTradeRiskLimitsRequest(bytes)
              [] tag = InquireSessionListRequestCode -> DecodeInquireSessionListRequest(bytes)
              [] tag = InquireUserRequestCode -> DecodeInquireUserRequest(bytes)
              [] tag = LogonRequestCode -> DecodeLogonRequest(bytes)
              [] tag = LogonRequestEncryptedCode -> DecodeLogonRequestEncrypted(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = MmParameterDefinitionRequestCode -> DecodeMmParameterDefinitionRequest(bytes)
              [] tag = MassOrderCode -> DecodeMassOrder(bytes)
              [] tag = MassQuoteRequestCode -> DecodeMassQuoteRequest(bytes)
              [] tag = ModifyBasketTradeRequestCode -> DecodeModifyBasketTradeRequest(bytes)
              [] tag = ModifyOrderRequestCode -> DecodeModifyOrderRequest(bytes)
              [] tag = ModifyOrderShortRequestCode -> DecodeModifyOrderShortRequest(bytes)
              [] tag = ModifyTesTradeRequestCode -> DecodeModifyTesTradeRequest(bytes)
              [] tag = NewOrderRequestCode -> DecodeNewOrderRequest(bytes)
              [] tag = NewOrderShortRequestCode -> DecodeNewOrderShortRequest(bytes)
              [] tag = PingRequestCode -> DecodePingRequest(bytes)
              [] tag = PreTradeRiskLimitsDefinitionRequestCode -> DecodePreTradeRiskLimitsDefinitionRequest(bytes)
              [] tag = QuoteActivationRequestCode -> DecodeQuoteActivationRequest(bytes)
              [] tag = RfqRequestCode -> DecodeRfqRequest(bytes)
              [] tag = RetransmitMeMessageRequestCode -> DecodeRetransmitMeMessageRequest(bytes)
              [] tag = RetransmitRequestCode -> DecodeRetransmitRequest(bytes)
              [] tag = ReverseTesTradeRequestCode -> DecodeReverseTesTradeRequest(bytes)
              [] tag = SrqsEnterQuoteRequestCode -> DecodeSrqsEnterQuoteRequest(bytes)
              [] tag = SrqsHitQuoteRequestCode -> DecodeSrqsHitQuoteRequest(bytes)
              [] tag = SrqsInquireSmartRespondentRequestCode -> DecodeSrqsInquireSmartRespondentRequest(bytes)
              [] tag = SrqsOpenNegotiationRequestCode -> DecodeSrqsOpenNegotiationRequest(bytes)
              [] tag = SrqsQuoteSnapshotRequestCode -> DecodeSrqsQuoteSnapshotRequest(bytes)
              [] tag = SrqsQuotingStatusRequestCode -> DecodeSrqsQuotingStatusRequest(bytes)
              [] tag = SrqsUpdateDealStatusRequestCode -> DecodeSrqsUpdateDealStatusRequest(bytes)
              [] tag = SrqsUpdateNegotiationRequestCode -> DecodeSrqsUpdateNegotiationRequest(bytes)
              [] tag = SubscribeRequestCode -> DecodeSubscribeRequest(bytes)
              [] tag = TesInquireBoundaryPricesRequestCode -> DecodeTesInquireBoundaryPricesRequest(bytes)
              [] tag = TradingActionRequestCode -> DecodeTradingActionRequest(bytes)
              [] tag = UnsubscribeRequestCode -> DecodeUnsubscribeRequest(bytes)
              [] tag = UpdateReferencePriceRequestCode -> DecodeUpdateReferencePriceRequest(bytes)
              [] tag = UpdateRemainingRiskAllowanceBaseRequestCode -> DecodeUpdateRemainingRiskAllowanceBaseRequest(bytes)
              [] tag = UploadTesTradeRequestCode -> DecodeUploadTesTradeRequest(bytes)
              [] tag = UserLoginRequestCode -> DecodeUserLoginRequest(bytes)
              [] tag = UserLoginRequestEncryptedCode -> DecodeUserLoginRequestEncrypted(bytes)
              [] tag = UserLogoutRequestCode -> DecodeUserLogoutRequest(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> AddComplexInstrumentRequestCode, body |-> ZeroAddComplexInstrumentRequest]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> AddComplexInstrumentRequestCode, body |-> one] : one \in CheckedAddComplexInstrumentRequest }
        \cup { [tag |-> AddFlexibleInstrumentRequestCode, body |-> one] : one \in CheckedAddFlexibleInstrumentRequest }
        \cup { [tag |-> AddScaledSimpleInstrumentRequestCode, body |-> one] : one \in CheckedAddScaledSimpleInstrumentRequest }
        \cup { [tag |-> AmendBasketTradeRequestCode, body |-> one] : one \in CheckedAmendBasketTradeRequest }
        \cup { [tag |-> ApproveBasketTradeRequestCode, body |-> one] : one \in CheckedApproveBasketTradeRequest }
        \cup { [tag |-> ApproveReverseTesTradeRequestCode, body |-> one] : one \in CheckedApproveReverseTesTradeRequest }
        \cup { [tag |-> ApproveTesTradeRequestCode, body |-> one] : one \in CheckedApproveTesTradeRequest }
        \cup { [tag |-> BasketRollRequestCode, body |-> one] : one \in CheckedBasketRollRequest }
        \cup { [tag |-> CrossRequestCode, body |-> one] : one \in CheckedCrossRequest }
        \cup { [tag |-> DeleteAllOrderRequestCode, body |-> one] : one \in CheckedDeleteAllOrderRequest }
        \cup { [tag |-> DeleteAllQuoteRequestCode, body |-> one] : one \in CheckedDeleteAllQuoteRequest }
        \cup { [tag |-> DeleteBasketTradeRequestCode, body |-> one] : one \in CheckedDeleteBasketTradeRequest }
        \cup { [tag |-> DeleteClipRequestCode, body |-> one] : one \in CheckedDeleteClipRequest }
        \cup { [tag |-> DeleteOrderRequestCode, body |-> one] : one \in CheckedDeleteOrderRequest }
        \cup { [tag |-> DeleteTesTradeRequestCode, body |-> one] : one \in CheckedDeleteTesTradeRequest }
        \cup { [tag |-> EnterBasketTradeRequestCode, body |-> one] : one \in CheckedEnterBasketTradeRequest }
        \cup { [tag |-> EnterClipRequestCode, body |-> one] : one \in CheckedEnterClipRequest }
        \cup { [tag |-> EnterTesTradeRequestCode, body |-> one] : one \in CheckedEnterTesTradeRequest }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> InquireEnrichmentRuleIdListRequestCode, body |-> one] : one \in CheckedInquireEnrichmentRuleIdListRequest }
        \cup { [tag |-> InquireMmParameterRequestCode, body |-> one] : one \in CheckedInquireMmParameterRequest }
        \cup { [tag |-> InquireMarginBasedRiskLimitRequestCode, body |-> one] : one \in CheckedInquireMarginBasedRiskLimitRequest }
        \cup { [tag |-> InquirePreTradeRiskLimitsRequestCode, body |-> one] : one \in CheckedInquirePreTradeRiskLimitsRequest }
        \cup { [tag |-> InquireSessionListRequestCode, body |-> one] : one \in CheckedInquireSessionListRequest }
        \cup { [tag |-> InquireUserRequestCode, body |-> one] : one \in CheckedInquireUserRequest }
        \cup { [tag |-> LogonRequestCode, body |-> one] : one \in CheckedLogonRequest }
        \cup { [tag |-> LogonRequestEncryptedCode, body |-> one] : one \in CheckedLogonRequestEncrypted }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> MmParameterDefinitionRequestCode, body |-> one] : one \in CheckedMmParameterDefinitionRequest }
        \cup { [tag |-> MassOrderCode, body |-> one] : one \in CheckedMassOrder }
        \cup { [tag |-> MassQuoteRequestCode, body |-> one] : one \in CheckedMassQuoteRequest }
        \cup { [tag |-> ModifyBasketTradeRequestCode, body |-> one] : one \in CheckedModifyBasketTradeRequest }
        \cup { [tag |-> ModifyOrderRequestCode, body |-> one] : one \in CheckedModifyOrderRequest }
        \cup { [tag |-> ModifyOrderShortRequestCode, body |-> one] : one \in CheckedModifyOrderShortRequest }
        \cup { [tag |-> ModifyTesTradeRequestCode, body |-> one] : one \in CheckedModifyTesTradeRequest }
        \cup { [tag |-> NewOrderRequestCode, body |-> one] : one \in CheckedNewOrderRequest }
        \cup { [tag |-> NewOrderShortRequestCode, body |-> one] : one \in CheckedNewOrderShortRequest }
        \cup { [tag |-> PingRequestCode, body |-> one] : one \in CheckedPingRequest }
        \cup { [tag |-> PreTradeRiskLimitsDefinitionRequestCode, body |-> one] : one \in CheckedPreTradeRiskLimitsDefinitionRequest }
        \cup { [tag |-> QuoteActivationRequestCode, body |-> one] : one \in CheckedQuoteActivationRequest }
        \cup { [tag |-> RfqRequestCode, body |-> one] : one \in CheckedRfqRequest }
        \cup { [tag |-> RetransmitMeMessageRequestCode, body |-> one] : one \in CheckedRetransmitMeMessageRequest }
        \cup { [tag |-> RetransmitRequestCode, body |-> one] : one \in CheckedRetransmitRequest }
        \cup { [tag |-> ReverseTesTradeRequestCode, body |-> one] : one \in CheckedReverseTesTradeRequest }
        \cup { [tag |-> SrqsEnterQuoteRequestCode, body |-> one] : one \in CheckedSrqsEnterQuoteRequest }
        \cup { [tag |-> SrqsHitQuoteRequestCode, body |-> one] : one \in CheckedSrqsHitQuoteRequest }
        \cup { [tag |-> SrqsInquireSmartRespondentRequestCode, body |-> one] : one \in CheckedSrqsInquireSmartRespondentRequest }
        \cup { [tag |-> SrqsOpenNegotiationRequestCode, body |-> one] : one \in CheckedSrqsOpenNegotiationRequest }
        \cup { [tag |-> SrqsQuoteSnapshotRequestCode, body |-> one] : one \in CheckedSrqsQuoteSnapshotRequest }
        \cup { [tag |-> SrqsQuotingStatusRequestCode, body |-> one] : one \in CheckedSrqsQuotingStatusRequest }
        \cup { [tag |-> SrqsUpdateDealStatusRequestCode, body |-> one] : one \in CheckedSrqsUpdateDealStatusRequest }
        \cup { [tag |-> SrqsUpdateNegotiationRequestCode, body |-> one] : one \in CheckedSrqsUpdateNegotiationRequest }
        \cup { [tag |-> SubscribeRequestCode, body |-> one] : one \in CheckedSubscribeRequest }
        \cup { [tag |-> TesInquireBoundaryPricesRequestCode, body |-> one] : one \in CheckedTesInquireBoundaryPricesRequest }
        \cup { [tag |-> TradingActionRequestCode, body |-> one] : one \in CheckedTradingActionRequest }
        \cup { [tag |-> UnsubscribeRequestCode, body |-> one] : one \in CheckedUnsubscribeRequest }
        \cup { [tag |-> UpdateReferencePriceRequestCode, body |-> one] : one \in CheckedUpdateReferencePriceRequest }
        \cup { [tag |-> UpdateRemainingRiskAllowanceBaseRequestCode, body |-> one] : one \in CheckedUpdateRemainingRiskAllowanceBaseRequest }
        \cup { [tag |-> UploadTesTradeRequestCode, body |-> one] : one \in CheckedUploadTesTradeRequest }
        \cup { [tag |-> UserLoginRequestCode, body |-> one] : one \in CheckedUserLoginRequest }
        \cup { [tag |-> UserLoginRequestEncryptedCode, body |-> one] : one \in CheckedUserLoginRequestEncrypted }
        \cup { [tag |-> UserLogoutRequestCode, body |-> one] : one \in CheckedUserLogoutRequest }

(***************************************************************************)
(* Client Message, framed by Body Len                                      *)
(***************************************************************************)

ClientMessage ==
    [ clientPayload : ClientPayload ]

EncodeClientMessageBody(message) ==
    EncodeUIntLE(message.clientPayload.tag, 2)
        \o EncodeClientPayload(message.clientPayload)

(* Body Len counts the bytes it frames, so it is written from them *)
EncodeClientMessage(message) ==
    LET body == EncodeClientMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 4, 4) \o body

DecodeClientMessageBody(bytes) ==
    LET templateId == ReadUIntLE(bytes, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, templateId.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 4) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientMessage ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Message, written one after another *)
RECURSIVE EncodeClientMessageList(_)
EncodeClientMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientMessage(Head(messages)) \o EncodeClientMessageList(Tail(messages))

(* As many Client Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientMessageAll(_)
ReadClientMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Message of each kind, for the lists that carry them *)
OneClientMessage ==
    { [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> AddComplexInstrumentRequestCode, body |-> ZeroAddComplexInstrumentRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> AddFlexibleInstrumentRequestCode, body |-> ZeroAddFlexibleInstrumentRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> AddScaledSimpleInstrumentRequestCode, body |-> ZeroAddScaledSimpleInstrumentRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> AmendBasketTradeRequestCode, body |-> ZeroAmendBasketTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ApproveBasketTradeRequestCode, body |-> ZeroApproveBasketTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ApproveReverseTesTradeRequestCode, body |-> ZeroApproveReverseTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ApproveTesTradeRequestCode, body |-> ZeroApproveTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> BasketRollRequestCode, body |-> ZeroBasketRollRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> CrossRequestCode, body |-> ZeroCrossRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteAllOrderRequestCode, body |-> ZeroDeleteAllOrderRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteAllQuoteRequestCode, body |-> ZeroDeleteAllQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteBasketTradeRequestCode, body |-> ZeroDeleteBasketTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteClipRequestCode, body |-> ZeroDeleteClipRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteOrderRequestCode, body |-> ZeroDeleteOrderRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteTesTradeRequestCode, body |-> ZeroDeleteTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> EnterBasketTradeRequestCode, body |-> ZeroEnterBasketTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> EnterClipRequestCode, body |-> ZeroEnterClipRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> EnterTesTradeRequestCode, body |-> ZeroEnterTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> HeartbeatCode, body |-> ZeroHeartbeat]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireEnrichmentRuleIdListRequestCode, body |-> ZeroInquireEnrichmentRuleIdListRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireMmParameterRequestCode, body |-> ZeroInquireMmParameterRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireMarginBasedRiskLimitRequestCode, body |-> ZeroInquireMarginBasedRiskLimitRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquirePreTradeRiskLimitsRequestCode, body |-> ZeroInquirePreTradeRiskLimitsRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireSessionListRequestCode, body |-> ZeroInquireSessionListRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireUserRequestCode, body |-> ZeroInquireUserRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogonRequestCode, body |-> ZeroLogonRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogonRequestEncryptedCode, body |-> ZeroLogonRequestEncrypted]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> MmParameterDefinitionRequestCode, body |-> ZeroMmParameterDefinitionRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> MassOrderCode, body |-> ZeroMassOrder]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> MassQuoteRequestCode, body |-> ZeroMassQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyBasketTradeRequestCode, body |-> ZeroModifyBasketTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderRequestCode, body |-> ZeroModifyOrderRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderShortRequestCode, body |-> ZeroModifyOrderShortRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyTesTradeRequestCode, body |-> ZeroModifyTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderRequestCode, body |-> ZeroNewOrderRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderShortRequestCode, body |-> ZeroNewOrderShortRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> PingRequestCode, body |-> ZeroPingRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> PreTradeRiskLimitsDefinitionRequestCode, body |-> ZeroPreTradeRiskLimitsDefinitionRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> QuoteActivationRequestCode, body |-> ZeroQuoteActivationRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RfqRequestCode, body |-> ZeroRfqRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitMeMessageRequestCode, body |-> ZeroRetransmitMeMessageRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitRequestCode, body |-> ZeroRetransmitRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ReverseTesTradeRequestCode, body |-> ZeroReverseTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SrqsEnterQuoteRequestCode, body |-> ZeroSrqsEnterQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SrqsHitQuoteRequestCode, body |-> ZeroSrqsHitQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SrqsInquireSmartRespondentRequestCode, body |-> ZeroSrqsInquireSmartRespondentRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SrqsOpenNegotiationRequestCode, body |-> ZeroSrqsOpenNegotiationRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SrqsQuoteSnapshotRequestCode, body |-> ZeroSrqsQuoteSnapshotRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SrqsQuotingStatusRequestCode, body |-> ZeroSrqsQuotingStatusRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SrqsUpdateDealStatusRequestCode, body |-> ZeroSrqsUpdateDealStatusRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SrqsUpdateNegotiationRequestCode, body |-> ZeroSrqsUpdateNegotiationRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SubscribeRequestCode, body |-> ZeroSubscribeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> TesInquireBoundaryPricesRequestCode, body |-> ZeroTesInquireBoundaryPricesRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> TradingActionRequestCode, body |-> ZeroTradingActionRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UnsubscribeRequestCode, body |-> ZeroUnsubscribeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UpdateReferencePriceRequestCode, body |-> ZeroUpdateReferencePriceRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UpdateRemainingRiskAllowanceBaseRequestCode, body |-> ZeroUpdateRemainingRiskAllowanceBaseRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UploadTesTradeRequestCode, body |-> ZeroUploadTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLoginRequestCode, body |-> ZeroUserLoginRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLoginRequestEncryptedCode, body |-> ZeroUserLoginRequestEncrypted]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLogoutRequestCode, body |-> ZeroUserLogoutRequest]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientMessage : SampleLists(OneClientMessage) ]

EncodeClientPacket(message) ==
    EncodeClientMessageList(message.clientMessage)

DecodeClientPacket(bytes) ==
    LET clientMessage == ReadClientMessageAll(bytes) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPacket ==
    [ clientMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientMessage = one] : one \in SampleLists(OneClientMessage) }

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

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp ==
    \A message \in CheckedRequestHeaderComp :
        LET read == DecodeRequestHeaderComp(EncodeRequestHeaderComp(message))
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

(* Every Add Complex Instrument Request decodes back to what was encoded, and leaves nothing over *)
RoundTripAddComplexInstrumentRequest ==
    \A message \in CheckedAddComplexInstrumentRequest :
        LET read == DecodeAddComplexInstrumentRequest(EncodeAddComplexInstrumentRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp2 ==
    \A message \in CheckedRequestHeaderComp2 :
        LET read == DecodeRequestHeaderComp2(EncodeRequestHeaderComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Flexible Instrument Request decodes back to what was encoded, and leaves nothing over *)
RoundTripAddFlexibleInstrumentRequest ==
    \A message \in CheckedAddFlexibleInstrumentRequest :
        LET read == DecodeAddFlexibleInstrumentRequest(EncodeAddFlexibleInstrumentRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp3 ==
    \A message \in CheckedRequestHeaderComp3 :
        LET read == DecodeRequestHeaderComp3(EncodeRequestHeaderComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Scaled Simple Instrument Request decodes back to what was encoded, and leaves nothing over *)
RoundTripAddScaledSimpleInstrumentRequest ==
    \A message \in CheckedAddScaledSimpleInstrumentRequest :
        LET read == DecodeAddScaledSimpleInstrumentRequest(EncodeAddScaledSimpleInstrumentRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp4 ==
    \A message \in CheckedRequestHeaderComp4 :
        LET read == DecodeRequestHeaderComp4(EncodeRequestHeaderComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Root Party Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketRootPartyGrpComp ==
    \A message \in CheckedBasketRootPartyGrpComp :
        LET read == DecodeBasketRootPartyGrpComp(EncodeBasketRootPartyGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrmt Match Side Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmtMatchSideGrpComp ==
    \A message \in CheckedInstrmtMatchSideGrpComp :
        LET read == DecodeInstrmtMatchSideGrpComp(EncodeInstrmtMatchSideGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketSideAllocGrpComp ==
    \A message \in CheckedBasketSideAllocGrpComp :
        LET read == DecodeBasketSideAllocGrpComp(EncodeBasketSideAllocGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Amend Basket Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripAmendBasketTradeRequest ==
    \A message \in CheckedAmendBasketTradeRequest :
        LET read == DecodeAmendBasketTradeRequest(EncodeAmendBasketTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp5 ==
    \A message \in CheckedRequestHeaderComp5 :
        LET read == DecodeRequestHeaderComp5(EncodeRequestHeaderComp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Side Alloc Ext Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketSideAllocExtGrpComp ==
    \A message \in CheckedBasketSideAllocExtGrpComp :
        LET read == DecodeBasketSideAllocExtGrpComp(EncodeBasketSideAllocExtGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Approve Basket Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripApproveBasketTradeRequest ==
    \A message \in CheckedApproveBasketTradeRequest :
        LET read == DecodeApproveBasketTradeRequest(EncodeApproveBasketTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp6 ==
    \A message \in CheckedRequestHeaderComp6 :
        LET read == DecodeRequestHeaderComp6(EncodeRequestHeaderComp6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Approve Reverse Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripApproveReverseTesTradeRequest ==
    \A message \in CheckedApproveReverseTesTradeRequest :
        LET read == DecodeApproveReverseTesTradeRequest(EncodeApproveReverseTesTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp7 ==
    \A message \in CheckedRequestHeaderComp7 :
        LET read == DecodeRequestHeaderComp7(EncodeRequestHeaderComp7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Approve Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripApproveTesTradeRequest ==
    \A message \in CheckedApproveTesTradeRequest :
        LET read == DecodeApproveTesTradeRequest(EncodeApproveTesTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp8 ==
    \A message \in CheckedRequestHeaderComp8 :
        LET read == DecodeRequestHeaderComp8(EncodeRequestHeaderComp8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Old Basket Data Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOldBasketDataGrpComp ==
    \A message \in CheckedOldBasketDataGrpComp :
        LET read == DecodeOldBasketDataGrpComp(EncodeOldBasketDataGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Basket Data Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNewBasketDataGrpComp ==
    \A message \in CheckedNewBasketDataGrpComp :
        LET read == DecodeNewBasketDataGrpComp(EncodeNewBasketDataGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Root Party Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketRootPartyGrpComp2 ==
    \A message \in CheckedBasketRootPartyGrpComp2 :
        LET read == DecodeBasketRootPartyGrpComp2(EncodeBasketRootPartyGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Old Basket Instrmt Match Side Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOldBasketInstrmtMatchSideGrpComp ==
    \A message \in CheckedOldBasketInstrmtMatchSideGrpComp :
        LET read == DecodeOldBasketInstrmtMatchSideGrpComp(EncodeOldBasketInstrmtMatchSideGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Basket Instrmt Match Side Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNewBasketInstrmtMatchSideGrpComp ==
    \A message \in CheckedNewBasketInstrmtMatchSideGrpComp :
        LET read == DecodeNewBasketInstrmtMatchSideGrpComp(EncodeNewBasketInstrmtMatchSideGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Old Basket Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOldBasketSideAllocGrpComp ==
    \A message \in CheckedOldBasketSideAllocGrpComp :
        LET read == DecodeOldBasketSideAllocGrpComp(EncodeOldBasketSideAllocGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Basket Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNewBasketSideAllocGrpComp ==
    \A message \in CheckedNewBasketSideAllocGrpComp :
        LET read == DecodeNewBasketSideAllocGrpComp(EncodeNewBasketSideAllocGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Roll Request decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketRollRequest ==
    \A message \in CheckedBasketRollRequest :
        LET read == DecodeBasketRollRequest(EncodeBasketRollRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp9 ==
    \A message \in CheckedRequestHeaderComp9 :
        LET read == DecodeRequestHeaderComp9(EncodeRequestHeaderComp9(message))
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

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp10 ==
    \A message \in CheckedRequestHeaderComp10 :
        LET read == DecodeRequestHeaderComp10(EncodeRequestHeaderComp10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllOrderRequest ==
    \A message \in CheckedDeleteAllOrderRequest :
        LET read == DecodeDeleteAllOrderRequest(EncodeDeleteAllOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp11 ==
    \A message \in CheckedRequestHeaderComp11 :
        LET read == DecodeRequestHeaderComp11(EncodeRequestHeaderComp11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllQuoteRequest ==
    \A message \in CheckedDeleteAllQuoteRequest :
        LET read == DecodeDeleteAllQuoteRequest(EncodeDeleteAllQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp12 ==
    \A message \in CheckedRequestHeaderComp12 :
        LET read == DecodeRequestHeaderComp12(EncodeRequestHeaderComp12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Basket Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteBasketTradeRequest ==
    \A message \in CheckedDeleteBasketTradeRequest :
        LET read == DecodeDeleteBasketTradeRequest(EncodeDeleteBasketTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp13 ==
    \A message \in CheckedRequestHeaderComp13 :
        LET read == DecodeRequestHeaderComp13(EncodeRequestHeaderComp13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Clip Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteClipRequest ==
    \A message \in CheckedDeleteClipRequest :
        LET read == DecodeDeleteClipRequest(EncodeDeleteClipRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp14 ==
    \A message \in CheckedRequestHeaderComp14 :
        LET read == DecodeRequestHeaderComp14(EncodeRequestHeaderComp14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderRequest ==
    \A message \in CheckedDeleteOrderRequest :
        LET read == DecodeDeleteOrderRequest(EncodeDeleteOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp15 ==
    \A message \in CheckedRequestHeaderComp15 :
        LET read == DecodeRequestHeaderComp15(EncodeRequestHeaderComp15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteTesTradeRequest ==
    \A message \in CheckedDeleteTesTradeRequest :
        LET read == DecodeDeleteTesTradeRequest(EncodeDeleteTesTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp16 ==
    \A message \in CheckedRequestHeaderComp16 :
        LET read == DecodeRequestHeaderComp16(EncodeRequestHeaderComp16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Root Party Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketRootPartyGrpComp3 ==
    \A message \in CheckedBasketRootPartyGrpComp3 :
        LET read == DecodeBasketRootPartyGrpComp3(EncodeBasketRootPartyGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrmt Match Side Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmtMatchSideGrpComp2 ==
    \A message \in CheckedInstrmtMatchSideGrpComp2 :
        LET read == DecodeInstrmtMatchSideGrpComp2(EncodeInstrmtMatchSideGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketSideAllocGrpComp2 ==
    \A message \in CheckedBasketSideAllocGrpComp2 :
        LET read == DecodeBasketSideAllocGrpComp2(EncodeBasketSideAllocGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Basket Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterBasketTradeRequest ==
    \A message \in CheckedEnterBasketTradeRequest :
        LET read == DecodeEnterBasketTradeRequest(EncodeEnterBasketTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp17 ==
    \A message \in CheckedRequestHeaderComp17 :
        LET read == DecodeRequestHeaderComp17(EncodeRequestHeaderComp17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Request Side Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossRequestSideGrpComp ==
    \A message \in CheckedCrossRequestSideGrpComp :
        LET read == DecodeCrossRequestSideGrpComp(EncodeCrossRequestSideGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Side Cross Leg Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideCrossLegGrpComp ==
    \A message \in CheckedSideCrossLegGrpComp :
        LET read == DecodeSideCrossLegGrpComp(EncodeSideCrossLegGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Clip Request decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterClipRequest ==
    \A message \in CheckedEnterClipRequest :
        LET read == DecodeEnterClipRequest(EncodeEnterClipRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp18 ==
    \A message \in CheckedRequestHeaderComp18 :
        LET read == DecodeRequestHeaderComp18(EncodeRequestHeaderComp18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideAllocGrpComp ==
    \A message \in CheckedSideAllocGrpComp :
        LET read == DecodeSideAllocGrpComp(EncodeSideAllocGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Instrmnt Leg Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdInstrmntLegGrpComp ==
    \A message \in CheckedTrdInstrmntLegGrpComp :
        LET read == DecodeTrdInstrmntLegGrpComp(EncodeTrdInstrmntLegGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Event Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentEventGrpComp ==
    \A message \in CheckedInstrumentEventGrpComp :
        LET read == DecodeInstrumentEventGrpComp(EncodeInstrumentEventGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Attribute Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentAttributeGrpComp ==
    \A message \in CheckedInstrumentAttributeGrpComp :
        LET read == DecodeInstrumentAttributeGrpComp(EncodeInstrumentAttributeGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Stip Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingStipGrpComp ==
    \A message \in CheckedUnderlyingStipGrpComp :
        LET read == DecodeUnderlyingStipGrpComp(EncodeUnderlyingStipGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterTesTradeRequest ==
    \A message \in CheckedEnterTesTradeRequest :
        LET read == DecodeEnterTesTradeRequest(EncodeEnterTesTradeRequest(message))
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

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp19 ==
    \A message \in CheckedRequestHeaderComp19 :
        LET read == DecodeRequestHeaderComp19(EncodeRequestHeaderComp19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Enrichment Rule Id List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireEnrichmentRuleIdListRequest ==
    \A message \in CheckedInquireEnrichmentRuleIdListRequest :
        LET read == DecodeInquireEnrichmentRuleIdListRequest(EncodeInquireEnrichmentRuleIdListRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp20 ==
    \A message \in CheckedRequestHeaderComp20 :
        LET read == DecodeRequestHeaderComp20(EncodeRequestHeaderComp20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Mm Parameter Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireMmParameterRequest ==
    \A message \in CheckedInquireMmParameterRequest :
        LET read == DecodeInquireMmParameterRequest(EncodeInquireMmParameterRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp21 ==
    \A message \in CheckedRequestHeaderComp21 :
        LET read == DecodeRequestHeaderComp21(EncodeRequestHeaderComp21(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Margin Based Risk Limit Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireMarginBasedRiskLimitRequest ==
    \A message \in CheckedInquireMarginBasedRiskLimitRequest :
        LET read == DecodeInquireMarginBasedRiskLimitRequest(EncodeInquireMarginBasedRiskLimitRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp22 ==
    \A message \in CheckedRequestHeaderComp22 :
        LET read == DecodeRequestHeaderComp22(EncodeRequestHeaderComp22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Pre Trade Risk Limits Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquirePreTradeRiskLimitsRequest ==
    \A message \in CheckedInquirePreTradeRiskLimitsRequest :
        LET read == DecodeInquirePreTradeRiskLimitsRequest(EncodeInquirePreTradeRiskLimitsRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp23 ==
    \A message \in CheckedRequestHeaderComp23 :
        LET read == DecodeRequestHeaderComp23(EncodeRequestHeaderComp23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Session List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireSessionListRequest ==
    \A message \in CheckedInquireSessionListRequest :
        LET read == DecodeInquireSessionListRequest(EncodeInquireSessionListRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp24 ==
    \A message \in CheckedRequestHeaderComp24 :
        LET read == DecodeRequestHeaderComp24(EncodeRequestHeaderComp24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire User Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireUserRequest ==
    \A message \in CheckedInquireUserRequest :
        LET read == DecodeInquireUserRequest(EncodeInquireUserRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp25 ==
    \A message \in CheckedRequestHeaderComp25 :
        LET read == DecodeRequestHeaderComp25(EncodeRequestHeaderComp25(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequest ==
    \A message \in CheckedLogonRequest :
        LET read == DecodeLogonRequest(EncodeLogonRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp26 ==
    \A message \in CheckedRequestHeaderComp26 :
        LET read == DecodeRequestHeaderComp26(EncodeRequestHeaderComp26(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Request Encrypted decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequestEncrypted ==
    \A message \in CheckedLogonRequestEncrypted :
        LET read == DecodeLogonRequestEncrypted(EncodeLogonRequestEncrypted(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp27 ==
    \A message \in CheckedRequestHeaderComp27 :
        LET read == DecodeRequestHeaderComp27(EncodeRequestHeaderComp27(message))
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

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp28 ==
    \A message \in CheckedRequestHeaderComp28 :
        LET read == DecodeRequestHeaderComp28(EncodeRequestHeaderComp28(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Parameter Definition Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMmParameterDefinitionRequest ==
    \A message \in CheckedMmParameterDefinitionRequest :
        LET read == DecodeMmParameterDefinitionRequest(EncodeMmParameterDefinitionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp29 ==
    \A message \in CheckedRequestHeaderComp29 :
        LET read == DecodeRequestHeaderComp29(EncodeRequestHeaderComp29(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryGrpComp ==
    \A message \in CheckedOrderEntryGrpComp :
        LET read == DecodeOrderEntryGrpComp(EncodeOrderEntryGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Order decodes back to what was encoded, and leaves nothing over *)
RoundTripMassOrder ==
    \A message \in CheckedMassOrder :
        LET read == DecodeMassOrder(EncodeMassOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp30 ==
    \A message \in CheckedRequestHeaderComp30 :
        LET read == DecodeRequestHeaderComp30(EncodeRequestHeaderComp30(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Entry Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteEntryGrpComp ==
    \A message \in CheckedQuoteEntryGrpComp :
        LET read == DecodeQuoteEntryGrpComp(EncodeQuoteEntryGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRequest ==
    \A message \in CheckedMassQuoteRequest :
        LET read == DecodeMassQuoteRequest(EncodeMassQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp31 ==
    \A message \in CheckedRequestHeaderComp31 :
        LET read == DecodeRequestHeaderComp31(EncodeRequestHeaderComp31(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Root Party Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketRootPartyGrpComp4 ==
    \A message \in CheckedBasketRootPartyGrpComp4 :
        LET read == DecodeBasketRootPartyGrpComp4(EncodeBasketRootPartyGrpComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrmt Match Side Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmtMatchSideGrpComp3 ==
    \A message \in CheckedInstrmtMatchSideGrpComp3 :
        LET read == DecodeInstrmtMatchSideGrpComp3(EncodeInstrmtMatchSideGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketSideAllocGrpComp3 ==
    \A message \in CheckedBasketSideAllocGrpComp3 :
        LET read == DecodeBasketSideAllocGrpComp3(EncodeBasketSideAllocGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Basket Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyBasketTradeRequest ==
    \A message \in CheckedModifyBasketTradeRequest :
        LET read == DecodeModifyBasketTradeRequest(EncodeModifyBasketTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp32 ==
    \A message \in CheckedRequestHeaderComp32 :
        LET read == DecodeRequestHeaderComp32(EncodeRequestHeaderComp32(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Ord Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripLegOrdGrpComp ==
    \A message \in CheckedLegOrdGrpComp :
        LET read == DecodeLegOrdGrpComp(EncodeLegOrdGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderRequest ==
    \A message \in CheckedModifyOrderRequest :
        LET read == DecodeModifyOrderRequest(EncodeModifyOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp33 ==
    \A message \in CheckedRequestHeaderComp33 :
        LET read == DecodeRequestHeaderComp33(EncodeRequestHeaderComp33(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Short Request decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderShortRequest ==
    \A message \in CheckedModifyOrderShortRequest :
        LET read == DecodeModifyOrderShortRequest(EncodeModifyOrderShortRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp34 ==
    \A message \in CheckedRequestHeaderComp34 :
        LET read == DecodeRequestHeaderComp34(EncodeRequestHeaderComp34(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideAllocGrpComp2 ==
    \A message \in CheckedSideAllocGrpComp2 :
        LET read == DecodeSideAllocGrpComp2(EncodeSideAllocGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Instrmnt Leg Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdInstrmntLegGrpComp2 ==
    \A message \in CheckedTrdInstrmntLegGrpComp2 :
        LET read == DecodeTrdInstrmntLegGrpComp2(EncodeTrdInstrmntLegGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyTesTradeRequest ==
    \A message \in CheckedModifyTesTradeRequest :
        LET read == DecodeModifyTesTradeRequest(EncodeModifyTesTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp35 ==
    \A message \in CheckedRequestHeaderComp35 :
        LET read == DecodeRequestHeaderComp35(EncodeRequestHeaderComp35(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Ord Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripLegOrdGrpComp2 ==
    \A message \in CheckedLegOrdGrpComp2 :
        LET read == DecodeLegOrdGrpComp2(EncodeLegOrdGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderRequest ==
    \A message \in CheckedNewOrderRequest :
        LET read == DecodeNewOrderRequest(EncodeNewOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp36 ==
    \A message \in CheckedRequestHeaderComp36 :
        LET read == DecodeRequestHeaderComp36(EncodeRequestHeaderComp36(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Short Request decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderShortRequest ==
    \A message \in CheckedNewOrderShortRequest :
        LET read == DecodeNewOrderShortRequest(EncodeNewOrderShortRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp37 ==
    \A message \in CheckedRequestHeaderComp37 :
        LET read == DecodeRequestHeaderComp37(EncodeRequestHeaderComp37(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ping Request decodes back to what was encoded, and leaves nothing over *)
RoundTripPingRequest ==
    \A message \in CheckedPingRequest :
        LET read == DecodePingRequest(EncodePingRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp38 ==
    \A message \in CheckedRequestHeaderComp38 :
        LET read == DecodeRequestHeaderComp38(EncodeRequestHeaderComp38(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Limit Qty Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskLimitQtyGrpComp ==
    \A message \in CheckedRiskLimitQtyGrpComp :
        LET read == DecodeRiskLimitQtyGrpComp(EncodeRiskLimitQtyGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pre Trade Risk Limits Definition Request decodes back to what was encoded, and leaves nothing over *)
RoundTripPreTradeRiskLimitsDefinitionRequest ==
    \A message \in CheckedPreTradeRiskLimitsDefinitionRequest :
        LET read == DecodePreTradeRiskLimitsDefinitionRequest(EncodePreTradeRiskLimitsDefinitionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp39 ==
    \A message \in CheckedRequestHeaderComp39 :
        LET read == DecodeRequestHeaderComp39(EncodeRequestHeaderComp39(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Activation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteActivationRequest ==
    \A message \in CheckedQuoteActivationRequest :
        LET read == DecodeQuoteActivationRequest(EncodeQuoteActivationRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp40 ==
    \A message \in CheckedRequestHeaderComp40 :
        LET read == DecodeRequestHeaderComp40(EncodeRequestHeaderComp40(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqRequest ==
    \A message \in CheckedRfqRequest :
        LET read == DecodeRfqRequest(EncodeRfqRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp41 ==
    \A message \in CheckedRequestHeaderComp41 :
        LET read == DecodeRequestHeaderComp41(EncodeRequestHeaderComp41(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Me Message Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitMeMessageRequest ==
    \A message \in CheckedRetransmitMeMessageRequest :
        LET read == DecodeRetransmitMeMessageRequest(EncodeRetransmitMeMessageRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp42 ==
    \A message \in CheckedRequestHeaderComp42 :
        LET read == DecodeRequestHeaderComp42(EncodeRequestHeaderComp42(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRequest ==
    \A message \in CheckedRetransmitRequest :
        LET read == DecodeRetransmitRequest(EncodeRetransmitRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp43 ==
    \A message \in CheckedRequestHeaderComp43 :
        LET read == DecodeRequestHeaderComp43(EncodeRequestHeaderComp43(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reverse Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripReverseTesTradeRequest ==
    \A message \in CheckedReverseTesTradeRequest :
        LET read == DecodeReverseTesTradeRequest(EncodeReverseTesTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp44 ==
    \A message \in CheckedRequestHeaderComp44 :
        LET read == DecodeRequestHeaderComp44(EncodeRequestHeaderComp44(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Enter Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsEnterQuoteRequest ==
    \A message \in CheckedSrqsEnterQuoteRequest :
        LET read == DecodeSrqsEnterQuoteRequest(EncodeSrqsEnterQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp45 ==
    \A message \in CheckedRequestHeaderComp45 :
        LET read == DecodeRequestHeaderComp45(EncodeRequestHeaderComp45(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Hit Quote Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsHitQuoteGrpComp ==
    \A message \in CheckedSrqsHitQuoteGrpComp :
        LET read == DecodeSrqsHitQuoteGrpComp(EncodeSrqsHitQuoteGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Hit Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsHitQuoteRequest ==
    \A message \in CheckedSrqsHitQuoteRequest :
        LET read == DecodeSrqsHitQuoteRequest(EncodeSrqsHitQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp46 ==
    \A message \in CheckedRequestHeaderComp46 :
        LET read == DecodeRequestHeaderComp46(EncodeRequestHeaderComp46(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Inquire Smart Respondent Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsInquireSmartRespondentRequest ==
    \A message \in CheckedSrqsInquireSmartRespondentRequest :
        LET read == DecodeSrqsInquireSmartRespondentRequest(EncodeSrqsInquireSmartRespondentRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp47 ==
    \A message \in CheckedRequestHeaderComp47 :
        LET read == DecodeRequestHeaderComp47(EncodeRequestHeaderComp47(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quot Req Legs Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotReqLegsGrpComp ==
    \A message \in CheckedQuotReqLegsGrpComp :
        LET read == DecodeQuotReqLegsGrpComp(EncodeQuotReqLegsGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Target Parties Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripTargetPartiesComp ==
    \A message \in CheckedTargetPartiesComp :
        LET read == DecodeTargetPartiesComp(EncodeTargetPartiesComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Open Negotiation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsOpenNegotiationRequest ==
    \A message \in CheckedSrqsOpenNegotiationRequest :
        LET read == DecodeSrqsOpenNegotiationRequest(EncodeSrqsOpenNegotiationRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp48 ==
    \A message \in CheckedRequestHeaderComp48 :
        LET read == DecodeRequestHeaderComp48(EncodeRequestHeaderComp48(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Quote Snapshot Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsQuoteSnapshotRequest ==
    \A message \in CheckedSrqsQuoteSnapshotRequest :
        LET read == DecodeSrqsQuoteSnapshotRequest(EncodeSrqsQuoteSnapshotRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp49 ==
    \A message \in CheckedRequestHeaderComp49 :
        LET read == DecodeRequestHeaderComp49(EncodeRequestHeaderComp49(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Quoting Status Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsQuotingStatusRequest ==
    \A message \in CheckedSrqsQuotingStatusRequest :
        LET read == DecodeSrqsQuotingStatusRequest(EncodeSrqsQuotingStatusRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp50 ==
    \A message \in CheckedRequestHeaderComp50 :
        LET read == DecodeRequestHeaderComp50(EncodeRequestHeaderComp50(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Update Deal Status Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsUpdateDealStatusRequest ==
    \A message \in CheckedSrqsUpdateDealStatusRequest :
        LET read == DecodeSrqsUpdateDealStatusRequest(EncodeSrqsUpdateDealStatusRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp51 ==
    \A message \in CheckedRequestHeaderComp51 :
        LET read == DecodeRequestHeaderComp51(EncodeRequestHeaderComp51(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Target Parties Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripTargetPartiesComp2 ==
    \A message \in CheckedTargetPartiesComp2 :
        LET read == DecodeTargetPartiesComp2(EncodeTargetPartiesComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Update Negotiation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsUpdateNegotiationRequest ==
    \A message \in CheckedSrqsUpdateNegotiationRequest :
        LET read == DecodeSrqsUpdateNegotiationRequest(EncodeSrqsUpdateNegotiationRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp52 ==
    \A message \in CheckedRequestHeaderComp52 :
        LET read == DecodeRequestHeaderComp52(EncodeRequestHeaderComp52(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscribe Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscribeRequest ==
    \A message \in CheckedSubscribeRequest :
        LET read == DecodeSubscribeRequest(EncodeSubscribeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp53 ==
    \A message \in CheckedRequestHeaderComp53 :
        LET read == DecodeRequestHeaderComp53(EncodeRequestHeaderComp53(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tes Inquire Boundary Prices Request decodes back to what was encoded, and leaves nothing over *)
RoundTripTesInquireBoundaryPricesRequest ==
    \A message \in CheckedTesInquireBoundaryPricesRequest :
        LET read == DecodeTesInquireBoundaryPricesRequest(EncodeTesInquireBoundaryPricesRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp54 ==
    \A message \in CheckedRequestHeaderComp54 :
        LET read == DecodeRequestHeaderComp54(EncodeRequestHeaderComp54(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Action Request decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingActionRequest ==
    \A message \in CheckedTradingActionRequest :
        LET read == DecodeTradingActionRequest(EncodeTradingActionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp55 ==
    \A message \in CheckedRequestHeaderComp55 :
        LET read == DecodeRequestHeaderComp55(EncodeRequestHeaderComp55(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsubscribe Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsubscribeRequest ==
    \A message \in CheckedUnsubscribeRequest :
        LET read == DecodeUnsubscribeRequest(EncodeUnsubscribeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp56 ==
    \A message \in CheckedRequestHeaderComp56 :
        LET read == DecodeRequestHeaderComp56(EncodeRequestHeaderComp56(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Update Reference Price Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUpdateReferencePriceRequest ==
    \A message \in CheckedUpdateReferencePriceRequest :
        LET read == DecodeUpdateReferencePriceRequest(EncodeUpdateReferencePriceRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp57 ==
    \A message \in CheckedRequestHeaderComp57 :
        LET read == DecodeRequestHeaderComp57(EncodeRequestHeaderComp57(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rra Update Base Party Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRraUpdateBasePartyGrpComp ==
    \A message \in CheckedRraUpdateBasePartyGrpComp :
        LET read == DecodeRraUpdateBasePartyGrpComp(EncodeRraUpdateBasePartyGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Update Remaining Risk Allowance Base Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUpdateRemainingRiskAllowanceBaseRequest ==
    \A message \in CheckedUpdateRemainingRiskAllowanceBaseRequest :
        LET read == DecodeUpdateRemainingRiskAllowanceBaseRequest(EncodeUpdateRemainingRiskAllowanceBaseRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp58 ==
    \A message \in CheckedRequestHeaderComp58 :
        LET read == DecodeRequestHeaderComp58(EncodeRequestHeaderComp58(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Side Alloc Ext Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideAllocExtGrpComp ==
    \A message \in CheckedSideAllocExtGrpComp :
        LET read == DecodeSideAllocExtGrpComp(EncodeSideAllocExtGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Instrmnt Leg Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdInstrmntLegGrpComp3 ==
    \A message \in CheckedTrdInstrmntLegGrpComp3 :
        LET read == DecodeTrdInstrmntLegGrpComp3(EncodeTrdInstrmntLegGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Event Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentEventGrpComp2 ==
    \A message \in CheckedInstrumentEventGrpComp2 :
        LET read == DecodeInstrumentEventGrpComp2(EncodeInstrumentEventGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Attribute Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentAttributeGrpComp2 ==
    \A message \in CheckedInstrumentAttributeGrpComp2 :
        LET read == DecodeInstrumentAttributeGrpComp2(EncodeInstrumentAttributeGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Stip Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingStipGrpComp2 ==
    \A message \in CheckedUnderlyingStipGrpComp2 :
        LET read == DecodeUnderlyingStipGrpComp2(EncodeUnderlyingStipGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Upload Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUploadTesTradeRequest ==
    \A message \in CheckedUploadTesTradeRequest :
        LET read == DecodeUploadTesTradeRequest(EncodeUploadTesTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp59 ==
    \A message \in CheckedRequestHeaderComp59 :
        LET read == DecodeRequestHeaderComp59(EncodeRequestHeaderComp59(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLoginRequest ==
    \A message \in CheckedUserLoginRequest :
        LET read == DecodeUserLoginRequest(EncodeUserLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp60 ==
    \A message \in CheckedRequestHeaderComp60 :
        LET read == DecodeRequestHeaderComp60(EncodeRequestHeaderComp60(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Login Request Encrypted decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLoginRequestEncrypted ==
    \A message \in CheckedUserLoginRequestEncrypted :
        LET read == DecodeUserLoginRequestEncrypted(EncodeUserLoginRequestEncrypted(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp61 ==
    \A message \in CheckedRequestHeaderComp61 :
        LET read == DecodeRequestHeaderComp61(EncodeRequestHeaderComp61(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLogoutRequest ==
    \A message \in CheckedUserLogoutRequest :
        LET read == DecodeUserLogoutRequest(EncodeUserLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientMessage ==
    \A message \in CheckedClientMessage :
        LET read == DecodeClientMessage(EncodeClientMessage(message))
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

(* A Client Payload is selected by the Template Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Body Len is written from the bytes it frames *)
FramesClientMessage ==
    \A message \in CheckedClientMessage :
        LET bytes == EncodeClientMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
