------------------ MODULE BrokerTec_UsTreasury_v10_1_Tcp -------------------
(***************************************************************************)
(* CME Group Us Treasuries v10.1                                           *)
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
(* Technical Header: 14 bytes                                              *)
(***************************************************************************)

TechnicalHeader ==
    [ encodingType          : Sample(2),
      messageSequenceNumber : Sample(4),
      tcpSendingTime        : Sample(8) ]

EncodeTechnicalHeader(message) ==
    message.encodingType
        \o message.messageSequenceNumber
        \o message.tcpSendingTime

DecodeTechnicalHeader(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET messageSequenceNumber == ReadBytes(encodingType.rest, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET tcpSendingTime == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~tcpSendingTime.ok THEN Fail ELSE
    Ok([ encodingType          |-> encodingType.value,
         messageSequenceNumber |-> messageSequenceNumber.value,
         tcpSendingTime        |-> tcpSendingTime.value ], tcpSendingTime.rest)

ZeroTechnicalHeader ==
    [ encodingType          |-> [i \in 1 .. 2 |-> 0],
      messageSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      tcpSendingTime        |-> [i \in 1 .. 8 |-> 0] ]

(* Technical Header at zero, then each field in turn at the values it is checked at *)
CheckedTechnicalHeader ==
    { ZeroTechnicalHeader }
        \cup { [ZeroTechnicalHeader EXCEPT !.encodingType = one] : one \in Sample(2) }
        \cup { [ZeroTechnicalHeader EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTechnicalHeader EXCEPT !.tcpSendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Md Entry Px: 9 bytes                                                    *)
(***************************************************************************)

MdEntryPx ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMdEntryPx(message) ==
    message.mantissa
        \o message.exponent

DecodeMdEntryPx(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMdEntryPx ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx ==
    { ZeroMdEntryPx }
        \cup { [ZeroMdEntryPx EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntryPx EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Coupon Rate: 5 bytes                                                    *)
(***************************************************************************)

CouponRate ==
    [ mantissa32 : Sample(4),
      exponent   : Sample(1) ]

EncodeCouponRate(message) ==
    message.mantissa32
        \o message.exponent

DecodeCouponRate(bytes) ==
    LET mantissa32 == ReadBytes(bytes, 4) IN IF ~mantissa32.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa32.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa32 |-> mantissa32.value,
         exponent   |-> exponent.value ], exponent.rest)

ZeroCouponRate ==
    [ mantissa32 |-> [i \in 1 .. 4 |-> 0],
      exponent   |-> [i \in 1 .. 1 |-> 0] ]

(* Coupon Rate at zero, then each field in turn at the values it is checked at *)
CheckedCouponRate ==
    { ZeroCouponRate }
        \cup { [ZeroCouponRate EXCEPT !.mantissa32 = one] : one \in Sample(4) }
        \cup { [ZeroCouponRate EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Incremental Refresh Btec Group: 62 bytes                                *)
(***************************************************************************)

IncrementalRefreshBtecGroup ==
    [ mdUpdateAction      : Sample(1),
      mdEntryType         : Sample(1),
      mdEntryPx           : MdEntryPx,
      mdEntrySize         : Sample(4),
      mdPriceLevel        : Sample(1),
      tradeVolume         : Sample(4),
      symbol              : Sample(20),
      maturityDate        : Sample(2),
      securityAltId       : Sample(12),
      securityAltIdSource : Sample(1),
      couponRate          : CouponRate,
      tradeCondition      : Sample(1),
      priceType           : Sample(1) ]

EncodeIncrementalRefreshBtecGroup(message) ==
    message.mdUpdateAction
        \o message.mdEntryType
        \o EncodeMdEntryPx(message.mdEntryPx)
        \o message.mdEntrySize
        \o message.mdPriceLevel
        \o message.tradeVolume
        \o message.symbol
        \o message.maturityDate
        \o message.securityAltId
        \o message.securityAltIdSource
        \o EncodeCouponRate(message.couponRate)
        \o message.tradeCondition
        \o message.priceType

DecodeIncrementalRefreshBtecGroup(bytes) ==
    LET mdUpdateAction == ReadBytes(bytes, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 4) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdPriceLevel == ReadBytes(mdEntrySize.rest, 1) IN IF ~mdPriceLevel.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(mdPriceLevel.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET symbol == ReadBytes(tradeVolume.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(symbol.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET securityAltId == ReadBytes(maturityDate.rest, 12) IN IF ~securityAltId.ok THEN Fail ELSE
    LET securityAltIdSource == ReadBytes(securityAltId.rest, 1) IN IF ~securityAltIdSource.ok THEN Fail ELSE
    LET couponRate == DecodeCouponRate(securityAltIdSource.rest) IN IF ~couponRate.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(couponRate.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET priceType == ReadBytes(tradeCondition.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    Ok([ mdUpdateAction      |-> mdUpdateAction.value,
         mdEntryType         |-> mdEntryType.value,
         mdEntryPx           |-> mdEntryPx.value,
         mdEntrySize         |-> mdEntrySize.value,
         mdPriceLevel        |-> mdPriceLevel.value,
         tradeVolume         |-> tradeVolume.value,
         symbol              |-> symbol.value,
         maturityDate        |-> maturityDate.value,
         securityAltId       |-> securityAltId.value,
         securityAltIdSource |-> securityAltIdSource.value,
         couponRate          |-> couponRate.value,
         tradeCondition      |-> tradeCondition.value,
         priceType           |-> priceType.value ], priceType.rest)

ZeroIncrementalRefreshBtecGroup ==
    [ mdUpdateAction      |-> [i \in 1 .. 1 |-> 0],
      mdEntryType         |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx           |-> ZeroMdEntryPx,
      mdEntrySize         |-> [i \in 1 .. 4 |-> 0],
      mdPriceLevel        |-> [i \in 1 .. 1 |-> 0],
      tradeVolume         |-> [i \in 1 .. 4 |-> 0],
      symbol              |-> [i \in 1 .. 20 |-> 0],
      maturityDate        |-> [i \in 1 .. 2 |-> 0],
      securityAltId       |-> [i \in 1 .. 12 |-> 0],
      securityAltIdSource |-> [i \in 1 .. 1 |-> 0],
      couponRate          |-> ZeroCouponRate,
      tradeCondition      |-> [i \in 1 .. 1 |-> 0],
      priceType           |-> [i \in 1 .. 1 |-> 0] ]

(* Incremental Refresh Btec Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshBtecGroup ==
    { ZeroIncrementalRefreshBtecGroup }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.mdEntrySize = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.mdPriceLevel = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.securityAltId = one] : one \in Sample(12) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.securityAltIdSource = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.couponRate = one] : one \in CheckedCouponRate }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBtecGroup EXCEPT !.priceType = one] : one \in Sample(1) }

(* A run of Incremental Refresh Btec Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshBtecGroupList(_)
EncodeIncrementalRefreshBtecGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshBtecGroup(Head(messages)) \o EncodeIncrementalRefreshBtecGroupList(Tail(messages))

(* As many Incremental Refresh Btec Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshBtecGroupList(_, _)
ReadIncrementalRefreshBtecGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshBtecGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshBtecGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Btec Group of each kind, for the lists that carry them *)
OneIncrementalRefreshBtecGroup == { ZeroIncrementalRefreshBtecGroup }

(***************************************************************************)
(* Incremental Refresh Btec Groups                                         *)
(***************************************************************************)

IncrementalRefreshBtecGroups ==
    [ blockLength                 : Sample(2),
      incrementalRefreshBtecGroup : SampleLists(OneIncrementalRefreshBtecGroup) ]

EncodeIncrementalRefreshBtecGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshBtecGroup), 1)
        \o EncodeIncrementalRefreshBtecGroupList(message.incrementalRefreshBtecGroup)

DecodeIncrementalRefreshBtecGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshBtecGroup == ReadIncrementalRefreshBtecGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshBtecGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         incrementalRefreshBtecGroup |-> incrementalRefreshBtecGroup.value ], incrementalRefreshBtecGroup.rest)

ZeroIncrementalRefreshBtecGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshBtecGroup |-> << >> ]

(* Incremental Refresh Btec Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshBtecGroups ==
    { ZeroIncrementalRefreshBtecGroups }
        \cup { [ZeroIncrementalRefreshBtecGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshBtecGroups EXCEPT !.incrementalRefreshBtecGroup = one] : one \in SampleLists(OneIncrementalRefreshBtecGroup) }

(***************************************************************************)
(* Md Incremental Refresh Btec                                             *)
(***************************************************************************)

MdIncrementalRefreshBtec ==
    [ tradeDate                    : Sample(2),
      transactTime                 : Sample(8),
      incrementalRefreshBtecGroups : IncrementalRefreshBtecGroups ]

EncodeMdIncrementalRefreshBtec(message) ==
    message.tradeDate
        \o message.transactTime
        \o EncodeIncrementalRefreshBtecGroups(message.incrementalRefreshBtecGroups)

DecodeMdIncrementalRefreshBtec(bytes) ==
    LET tradeDate == ReadBytes(bytes, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tradeDate.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET incrementalRefreshBtecGroups == DecodeIncrementalRefreshBtecGroups(transactTime.rest) IN IF ~incrementalRefreshBtecGroups.ok THEN Fail ELSE
    Ok([ tradeDate                    |-> tradeDate.value,
         transactTime                 |-> transactTime.value,
         incrementalRefreshBtecGroups |-> incrementalRefreshBtecGroups.value ], incrementalRefreshBtecGroups.rest)

ZeroMdIncrementalRefreshBtec ==
    [ tradeDate                    |-> [i \in 1 .. 2 |-> 0],
      transactTime                 |-> [i \in 1 .. 8 |-> 0],
      incrementalRefreshBtecGroups |-> ZeroIncrementalRefreshBtecGroups ]

(* Md Incremental Refresh Btec at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshBtec ==
    { ZeroMdIncrementalRefreshBtec }
        \cup { [ZeroMdIncrementalRefreshBtec EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshBtec EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshBtec EXCEPT !.incrementalRefreshBtecGroups = one] : one \in CheckedIncrementalRefreshBtecGroups }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

MdIncrementalRefreshBtecCode == 405  \* 0x195
AdminHeartbeatCode == 411  \* 0x19b

Payload ==
    [ tag : {MdIncrementalRefreshBtecCode}, body : MdIncrementalRefreshBtec ]
        \cup [ tag : {AdminHeartbeatCode}, body : {[empty |-> 0]} ]

EncodePayload(message) ==
    CASE message.tag = MdIncrementalRefreshBtecCode -> EncodeMdIncrementalRefreshBtec(message.body)
      [] message.tag = AdminHeartbeatCode -> << >>

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = MdIncrementalRefreshBtecCode -> DecodeMdIncrementalRefreshBtec(bytes)
              [] tag = AdminHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> MdIncrementalRefreshBtecCode, body |-> ZeroMdIncrementalRefreshBtec]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> MdIncrementalRefreshBtecCode, body |-> one] : one \in CheckedMdIncrementalRefreshBtec }
        \cup { [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Tcp Frame, framed by Message Size                                       *)
(***************************************************************************)

TcpFrame ==
    [ technicalHeader : TechnicalHeader,
      blockLength     : Sample(2),
      schemaId        : Sample(2),
      version         : Sample(2),
      payload         : Payload ]

EncodeTcpFrameBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeTcpFrame(message) ==
    LET body == EncodeTcpFrameBody(message)
    IN  EncodeTechnicalHeader(message.technicalHeader) \o EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeTcpFrame(bytes) ==
    LET technicalHeader == DecodeTechnicalHeader(bytes) IN IF ~technicalHeader.ok THEN Fail ELSE
    LET length == ReadUIntLE(technicalHeader.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET blockLength == ReadBytes(framed, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ technicalHeader |-> technicalHeader.value,
         blockLength     |-> blockLength.value,
         schemaId        |-> schemaId.value,
         version         |-> version.value,
         payload         |-> payload.value ], beyond)

ZeroTcpFrame ==
    [ technicalHeader |-> ZeroTechnicalHeader,
      blockLength     |-> [i \in 1 .. 2 |-> 0],
      schemaId        |-> [i \in 1 .. 2 |-> 0],
      version         |-> [i \in 1 .. 2 |-> 0],
      payload         |-> ZeroPayload ]

(* Tcp Frame at zero, then each field in turn at the values it is checked at *)
CheckedTcpFrame ==
    { ZeroTcpFrame }
        \cup { [ZeroTcpFrame EXCEPT !.technicalHeader = one] : one \in CheckedTechnicalHeader }
        \cup { [ZeroTcpFrame EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTcpFrame EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroTcpFrame EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroTcpFrame EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Tcp Frame, written one after another *)
RECURSIVE EncodeTcpFrameList(_)
EncodeTcpFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTcpFrame(Head(messages)) \o EncodeTcpFrameList(Tail(messages))

(* As many Tcp Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTcpFrameAll(_)
ReadTcpFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTcpFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTcpFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tcp Frame of each kind, for the lists that carry them *)
OneTcpFrame ==
    { [ZeroTcpFrame EXCEPT !.payload = [tag |-> MdIncrementalRefreshBtecCode, body |-> ZeroMdIncrementalRefreshBtec]],
      [ZeroTcpFrame EXCEPT !.payload = [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Tcp Packet                                                              *)
(***************************************************************************)

TcpPacket ==
    [ tcpFrame : SampleLists(OneTcpFrame) ]

EncodeTcpPacket(message) ==
    EncodeTcpFrameList(message.tcpFrame)

DecodeTcpPacket(bytes) ==
    LET tcpFrame == ReadTcpFrameAll(bytes) IN IF ~tcpFrame.ok THEN Fail ELSE
    Ok([ tcpFrame |-> tcpFrame.value ], tcpFrame.rest)

ZeroTcpPacket ==
    [ tcpFrame |-> << >> ]

(* Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedTcpPacket ==
    { ZeroTcpPacket }
        \cup { [ZeroTcpPacket EXCEPT !.tcpFrame = one] : one \in SampleLists(OneTcpFrame) }

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

(* Every Technical Header decodes back to what was encoded, and leaves nothing over *)
RoundTripTechnicalHeader ==
    \A message \in CheckedTechnicalHeader :
        LET read == DecodeTechnicalHeader(EncodeTechnicalHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx ==
    \A message \in CheckedMdEntryPx :
        LET read == DecodeMdEntryPx(EncodeMdEntryPx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Coupon Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripCouponRate ==
    \A message \in CheckedCouponRate :
        LET read == DecodeCouponRate(EncodeCouponRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Btec Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshBtecGroup ==
    \A message \in CheckedIncrementalRefreshBtecGroup :
        LET read == DecodeIncrementalRefreshBtecGroup(EncodeIncrementalRefreshBtecGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Btec Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshBtecGroups ==
    \A message \in CheckedIncrementalRefreshBtecGroups :
        LET read == DecodeIncrementalRefreshBtecGroups(EncodeIncrementalRefreshBtecGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Btec decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshBtec ==
    \A message \in CheckedMdIncrementalRefreshBtec :
        LET read == DecodeMdIncrementalRefreshBtec(EncodeMdIncrementalRefreshBtec(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpFrame ==
    \A message \in CheckedTcpFrame :
        LET read == DecodeTcpFrame(EncodeTcpFrame(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpPacket ==
    \A message \in CheckedTcpPacket :
        LET read == DecodeTcpPacket(EncodeTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesTcpFrame ==
    \A message \in CheckedTcpFrame :
        LET bytes == EncodeTcpFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 15, 16)) = Len(bytes) - 14

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
