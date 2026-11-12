----------------- MODULE Spectra_OrdersLogSnapshot_v9_12_0 -----------------
(***************************************************************************)
(* Moscow Exchange SIMBA Spectra Orders Log Snapshot v9.12.0               *)
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
(* Order Book Snapshot Message No M D Entries Group: 57 bytes              *)
(***************************************************************************)

OrderBookSnapshotMessageNoMDEntriesGroup ==
    [ mdEntryIdInt64NullOptional    : Sample(8),
      transactTime                  : Sample(8),
      mdEntryPxDecimal5NullOptional : Sample(8),
      mdEntrySizeInt64NullOptional  : Sample(8),
      tradeIdInt64NullOptional      : Sample(8),
      mdFlags                       : Sample(8),
      mdFlags2                      : Sample(8),
      mdEntryType                   : Sample(1) ]

EncodeOrderBookSnapshotMessageNoMDEntriesGroup(message) ==
    message.mdEntryIdInt64NullOptional
        \o message.transactTime
        \o message.mdEntryPxDecimal5NullOptional
        \o message.mdEntrySizeInt64NullOptional
        \o message.tradeIdInt64NullOptional
        \o message.mdFlags
        \o message.mdFlags2
        \o message.mdEntryType

DecodeOrderBookSnapshotMessageNoMDEntriesGroup(bytes) ==
    LET mdEntryIdInt64NullOptional == ReadBytes(bytes, 8) IN IF ~mdEntryIdInt64NullOptional.ok THEN Fail ELSE
    LET transactTime == ReadBytes(mdEntryIdInt64NullOptional.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mdEntryPxDecimal5NullOptional == ReadBytes(transactTime.rest, 8) IN IF ~mdEntryPxDecimal5NullOptional.ok THEN Fail ELSE
    LET mdEntrySizeInt64NullOptional == ReadBytes(mdEntryPxDecimal5NullOptional.rest, 8) IN IF ~mdEntrySizeInt64NullOptional.ok THEN Fail ELSE
    LET tradeIdInt64NullOptional == ReadBytes(mdEntrySizeInt64NullOptional.rest, 8) IN IF ~tradeIdInt64NullOptional.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(tradeIdInt64NullOptional.rest, 8) IN IF ~mdFlags.ok THEN Fail ELSE
    LET mdFlags2 == ReadBytes(mdFlags.rest, 8) IN IF ~mdFlags2.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdFlags2.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    Ok([ mdEntryIdInt64NullOptional    |-> mdEntryIdInt64NullOptional.value,
         transactTime                  |-> transactTime.value,
         mdEntryPxDecimal5NullOptional |-> mdEntryPxDecimal5NullOptional.value,
         mdEntrySizeInt64NullOptional  |-> mdEntrySizeInt64NullOptional.value,
         tradeIdInt64NullOptional      |-> tradeIdInt64NullOptional.value,
         mdFlags                       |-> mdFlags.value,
         mdFlags2                      |-> mdFlags2.value,
         mdEntryType                   |-> mdEntryType.value ], mdEntryType.rest)

ZeroOrderBookSnapshotMessageNoMDEntriesGroup ==
    [ mdEntryIdInt64NullOptional    |-> [i \in 1 .. 8 |-> 0],
      transactTime                  |-> [i \in 1 .. 8 |-> 0],
      mdEntryPxDecimal5NullOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeInt64NullOptional  |-> [i \in 1 .. 8 |-> 0],
      tradeIdInt64NullOptional      |-> [i \in 1 .. 8 |-> 0],
      mdFlags                       |-> [i \in 1 .. 8 |-> 0],
      mdFlags2                      |-> [i \in 1 .. 8 |-> 0],
      mdEntryType                   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Snapshot Message No M D Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookSnapshotMessageNoMDEntriesGroup ==
    { ZeroOrderBookSnapshotMessageNoMDEntriesGroup }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroup EXCEPT !.mdEntryIdInt64NullOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroup EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroup EXCEPT !.mdEntryPxDecimal5NullOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroup EXCEPT !.mdEntrySizeInt64NullOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroup EXCEPT !.tradeIdInt64NullOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroup EXCEPT !.mdFlags = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroup EXCEPT !.mdFlags2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }

(* A run of Order Book Snapshot Message No M D Entries Group, written one after another *)
RECURSIVE EncodeOrderBookSnapshotMessageNoMDEntriesGroupList(_)
EncodeOrderBookSnapshotMessageNoMDEntriesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderBookSnapshotMessageNoMDEntriesGroup(Head(messages)) \o EncodeOrderBookSnapshotMessageNoMDEntriesGroupList(Tail(messages))

(* As many Order Book Snapshot Message No M D Entries Group as the field that counts them says *)
RECURSIVE ReadOrderBookSnapshotMessageNoMDEntriesGroupList(_, _)
ReadOrderBookSnapshotMessageNoMDEntriesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderBookSnapshotMessageNoMDEntriesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderBookSnapshotMessageNoMDEntriesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Book Snapshot Message No M D Entries Group of each kind, for the lists that carry them *)
OneOrderBookSnapshotMessageNoMDEntriesGroup == { ZeroOrderBookSnapshotMessageNoMDEntriesGroup }

(***************************************************************************)
(* Order Book Snapshot Message No M D Entries Groups                       *)
(***************************************************************************)

OrderBookSnapshotMessageNoMDEntriesGroups ==
    [ blockLength                              : Sample(2),
      orderBookSnapshotMessageNoMDEntriesGroup : SampleLists(OneOrderBookSnapshotMessageNoMDEntriesGroup) ]

EncodeOrderBookSnapshotMessageNoMDEntriesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.orderBookSnapshotMessageNoMDEntriesGroup), 1)
        \o EncodeOrderBookSnapshotMessageNoMDEntriesGroupList(message.orderBookSnapshotMessageNoMDEntriesGroup)

DecodeOrderBookSnapshotMessageNoMDEntriesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroupUint8.ok THEN Fail ELSE
    LET orderBookSnapshotMessageNoMDEntriesGroup == ReadOrderBookSnapshotMessageNoMDEntriesGroupList(numInGroupUint8.rest, numInGroupUint8.value) IN IF ~orderBookSnapshotMessageNoMDEntriesGroup.ok THEN Fail ELSE
    Ok([ blockLength                              |-> blockLength.value,
         orderBookSnapshotMessageNoMDEntriesGroup |-> orderBookSnapshotMessageNoMDEntriesGroup.value ], orderBookSnapshotMessageNoMDEntriesGroup.rest)

ZeroOrderBookSnapshotMessageNoMDEntriesGroups ==
    [ blockLength                              |-> [i \in 1 .. 2 |-> 0],
      orderBookSnapshotMessageNoMDEntriesGroup |-> << >> ]

(* Order Book Snapshot Message No M D Entries Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookSnapshotMessageNoMDEntriesGroups ==
    { ZeroOrderBookSnapshotMessageNoMDEntriesGroups }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookSnapshotMessageNoMDEntriesGroups EXCEPT !.orderBookSnapshotMessageNoMDEntriesGroup = one] : one \in SampleLists(OneOrderBookSnapshotMessageNoMDEntriesGroup) }

(***************************************************************************)
(* Order Book Snapshot Message                                             *)
(***************************************************************************)

OrderBookSnapshotMessage ==
    [ securityId                                : Sample(4),
      lastMsgSeqNumProcessedUInt32              : Sample(4),
      rptSeq                                    : Sample(4),
      exchangeTradingSessionId                  : Sample(4),
      orderBookSnapshotMessageNoMDEntriesGroups : OrderBookSnapshotMessageNoMDEntriesGroups ]

EncodeOrderBookSnapshotMessage(message) ==
    message.securityId
        \o message.lastMsgSeqNumProcessedUInt32
        \o message.rptSeq
        \o message.exchangeTradingSessionId
        \o EncodeOrderBookSnapshotMessageNoMDEntriesGroups(message.orderBookSnapshotMessageNoMDEntriesGroups)

DecodeOrderBookSnapshotMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET lastMsgSeqNumProcessedUInt32 == ReadBytes(securityId.rest, 4) IN IF ~lastMsgSeqNumProcessedUInt32.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(lastMsgSeqNumProcessedUInt32.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET exchangeTradingSessionId == ReadBytes(rptSeq.rest, 4) IN IF ~exchangeTradingSessionId.ok THEN Fail ELSE
    LET orderBookSnapshotMessageNoMDEntriesGroups == DecodeOrderBookSnapshotMessageNoMDEntriesGroups(exchangeTradingSessionId.rest) IN IF ~orderBookSnapshotMessageNoMDEntriesGroups.ok THEN Fail ELSE
    Ok([ securityId                                |-> securityId.value,
         lastMsgSeqNumProcessedUInt32              |-> lastMsgSeqNumProcessedUInt32.value,
         rptSeq                                    |-> rptSeq.value,
         exchangeTradingSessionId                  |-> exchangeTradingSessionId.value,
         orderBookSnapshotMessageNoMDEntriesGroups |-> orderBookSnapshotMessageNoMDEntriesGroups.value ], orderBookSnapshotMessageNoMDEntriesGroups.rest)

ZeroOrderBookSnapshotMessage ==
    [ securityId                                |-> [i \in 1 .. 4 |-> 0],
      lastMsgSeqNumProcessedUInt32              |-> [i \in 1 .. 4 |-> 0],
      rptSeq                                    |-> [i \in 1 .. 4 |-> 0],
      exchangeTradingSessionId                  |-> [i \in 1 .. 4 |-> 0],
      orderBookSnapshotMessageNoMDEntriesGroups |-> ZeroOrderBookSnapshotMessageNoMDEntriesGroups ]

(* Order Book Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookSnapshotMessage ==
    { ZeroOrderBookSnapshotMessage }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.lastMsgSeqNumProcessedUInt32 = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.exchangeTradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.orderBookSnapshotMessageNoMDEntriesGroups = one] : one \in CheckedOrderBookSnapshotMessageNoMDEntriesGroups }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
SequenceResetMessageCode == 2  \* 0x02
OrderBookSnapshotMessageCode == 17  \* 0x11

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {OrderBookSnapshotMessageCode}, body : OrderBookSnapshotMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = OrderBookSnapshotMessageCode -> EncodeOrderBookSnapshotMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = OrderBookSnapshotMessageCode -> DecodeOrderBookSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> OrderBookSnapshotMessageCode, body |-> one] : one \in CheckedOrderBookSnapshotMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookSnapshotMessageCode, body |-> ZeroOrderBookSnapshotMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ marketDataPacketHeader : MarketDataPacketHeader,
      message                : SampleLists(OneMessage) ]

EncodeUdpPacket(message) ==
    EncodeMarketDataPacketHeader(message.marketDataPacketHeader)
        \o EncodeMessageList(message.message)

DecodeUdpPacket(bytes) ==
    LET marketDataPacketHeader == DecodeMarketDataPacketHeader(bytes) IN IF ~marketDataPacketHeader.ok THEN Fail ELSE
    LET message == ReadMessageAll(marketDataPacketHeader.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ marketDataPacketHeader |-> marketDataPacketHeader.value,
         message                |-> message.value ], message.rest)

ZeroUdpPacket ==
    [ marketDataPacketHeader |-> ZeroMarketDataPacketHeader,
      message                |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.marketDataPacketHeader = one] : one \in CheckedMarketDataPacketHeader }
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

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Snapshot Message No M D Entries Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookSnapshotMessageNoMDEntriesGroup ==
    \A message \in CheckedOrderBookSnapshotMessageNoMDEntriesGroup :
        LET read == DecodeOrderBookSnapshotMessageNoMDEntriesGroup(EncodeOrderBookSnapshotMessageNoMDEntriesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Snapshot Message No M D Entries Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookSnapshotMessageNoMDEntriesGroups ==
    \A message \in CheckedOrderBookSnapshotMessageNoMDEntriesGroups :
        LET read == DecodeOrderBookSnapshotMessageNoMDEntriesGroups(EncodeOrderBookSnapshotMessageNoMDEntriesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookSnapshotMessage ==
    \A message \in CheckedOrderBookSnapshotMessage :
        LET read == DecodeOrderBookSnapshotMessage(EncodeOrderBookSnapshotMessage(message))
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
