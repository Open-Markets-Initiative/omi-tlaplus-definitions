------------------ MODULE LmeSelect_WarehouseStock_v4_18 -------------------
(***************************************************************************)
(* The London Metal Exchange LMEsource WarehouseStock v4.18                *)
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
(* Stock Records: 17 bytes                                                 *)
(***************************************************************************)

StockRecords ==
    [ productCode   : Sample(2),
      location      : Sample(4),
      gradeCode     : Sample(4),
      stockStatus   : Sample(3),
      stockQuantity : Sample(4) ]

EncodeStockRecords(message) ==
    message.productCode
        \o message.location
        \o message.gradeCode
        \o message.stockStatus
        \o message.stockQuantity

DecodeStockRecords(bytes) ==
    LET productCode == ReadBytes(bytes, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET location == ReadBytes(productCode.rest, 4) IN IF ~location.ok THEN Fail ELSE
    LET gradeCode == ReadBytes(location.rest, 4) IN IF ~gradeCode.ok THEN Fail ELSE
    LET stockStatus == ReadBytes(gradeCode.rest, 3) IN IF ~stockStatus.ok THEN Fail ELSE
    LET stockQuantity == ReadBytes(stockStatus.rest, 4) IN IF ~stockQuantity.ok THEN Fail ELSE
    Ok([ productCode   |-> productCode.value,
         location      |-> location.value,
         gradeCode     |-> gradeCode.value,
         stockStatus   |-> stockStatus.value,
         stockQuantity |-> stockQuantity.value ], stockQuantity.rest)

ZeroStockRecords ==
    [ productCode   |-> [i \in 1 .. 2 |-> 0],
      location      |-> [i \in 1 .. 4 |-> 0],
      gradeCode     |-> [i \in 1 .. 4 |-> 0],
      stockStatus   |-> [i \in 1 .. 3 |-> 0],
      stockQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Records at zero, then each field in turn at the values it is checked at *)
CheckedStockRecords ==
    { ZeroStockRecords }
        \cup { [ZeroStockRecords EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroStockRecords EXCEPT !.location = one] : one \in Sample(4) }
        \cup { [ZeroStockRecords EXCEPT !.gradeCode = one] : one \in Sample(4) }
        \cup { [ZeroStockRecords EXCEPT !.stockStatus = one] : one \in Sample(3) }
        \cup { [ZeroStockRecords EXCEPT !.stockQuantity = one] : one \in Sample(4) }

(* A run of Stock Records, written one after another *)
RECURSIVE EncodeStockRecordsList(_)
EncodeStockRecordsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStockRecords(Head(messages)) \o EncodeStockRecordsList(Tail(messages))

(* As many Stock Records as the field that counts them says *)
RECURSIVE ReadStockRecordsList(_, _)
ReadStockRecordsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStockRecords(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStockRecordsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Stock Records of each kind, for the lists that carry them *)
OneStockRecords == { ZeroStockRecords }

(***************************************************************************)
(* Warehouse Stock Movement Message                                        *)
(***************************************************************************)

WarehouseStockMovementMessage ==
    [ reportDate       : Sample(4),
      reportLevel      : Sample(12),
      remainingRecords : Sample(2),
      stockRecords     : SampleLists(OneStockRecords) ]

EncodeWarehouseStockMovementMessage(message) ==
    message.reportDate
        \o message.reportLevel
        \o message.remainingRecords
        \o EncodeUIntLE(Len(message.stockRecords), 2)
        \o EncodeStockRecordsList(message.stockRecords)

DecodeWarehouseStockMovementMessage(bytes) ==
    LET reportDate == ReadBytes(bytes, 4) IN IF ~reportDate.ok THEN Fail ELSE
    LET reportLevel == ReadBytes(reportDate.rest, 12) IN IF ~reportLevel.ok THEN Fail ELSE
    LET remainingRecords == ReadBytes(reportLevel.rest, 2) IN IF ~remainingRecords.ok THEN Fail ELSE
    LET recordCount == ReadUIntLE(remainingRecords.rest, 2) IN IF ~recordCount.ok THEN Fail ELSE
    LET stockRecords == ReadStockRecordsList(recordCount.rest, recordCount.value) IN IF ~stockRecords.ok THEN Fail ELSE
    Ok([ reportDate       |-> reportDate.value,
         reportLevel      |-> reportLevel.value,
         remainingRecords |-> remainingRecords.value,
         stockRecords     |-> stockRecords.value ], stockRecords.rest)

ZeroWarehouseStockMovementMessage ==
    [ reportDate       |-> [i \in 1 .. 4 |-> 0],
      reportLevel      |-> [i \in 1 .. 12 |-> 0],
      remainingRecords |-> [i \in 1 .. 2 |-> 0],
      stockRecords     |-> << >> ]

(* Warehouse Stock Movement Message at zero, then each field in turn at the values it is checked at *)
CheckedWarehouseStockMovementMessage ==
    { ZeroWarehouseStockMovementMessage }
        \cup { [ZeroWarehouseStockMovementMessage EXCEPT !.reportDate = one] : one \in Sample(4) }
        \cup { [ZeroWarehouseStockMovementMessage EXCEPT !.reportLevel = one] : one \in Sample(12) }
        \cup { [ZeroWarehouseStockMovementMessage EXCEPT !.remainingRecords = one] : one \in Sample(2) }
        \cup { [ZeroWarehouseStockMovementMessage EXCEPT !.stockRecords = one] : one \in SampleLists(OneStockRecords) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
WarehouseStockMovementMessageCode == 426  \* 0x1aa

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {WarehouseStockMovementMessageCode}, body : WarehouseStockMovementMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = WarehouseStockMovementMessageCode -> EncodeWarehouseStockMovementMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = WarehouseStockMovementMessageCode -> DecodeWarehouseStockMovementMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> WarehouseStockMovementMessageCode, body |-> one] : one \in CheckedWarehouseStockMovementMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ msgSize : 0 .. 255,
      payload : Payload ]

EncodeMessage(message) ==
    EncodeUIntLE(message.msgSize, 2)
        \o EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET msgSize == ReadUIntLE(bytes, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgType == ReadUIntLE(msgSize.rest, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSize |-> msgSize.value,
         payload |-> payload.value ], payload.rest)

ZeroMessage ==
    [ msgSize |-> 0,
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.msgSize = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> WarehouseStockMovementMessageCode, body |-> ZeroWarehouseStockMovementMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize  : Sample(2),
      filler   : Sample(1),
      seqNum   : Sample(4),
      sendTime : Sample(8),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.filler
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET filler == ReadBytes(msgCount.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET seqNum == ReadBytes(filler.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sendTime.rest, msgCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ pktSize  |-> pktSize.value,
         filler   |-> filler.value,
         seqNum   |-> seqNum.value,
         sendTime |-> sendTime.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ pktSize  |-> [i \in 1 .. 2 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0],
      seqNum   |-> [i \in 1 .. 4 |-> 0],
      sendTime |-> [i \in 1 .. 8 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
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

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Records decodes back to what was encoded, and leaves nothing over *)
RoundTripStockRecords ==
    \A message \in CheckedStockRecords :
        LET read == DecodeStockRecords(EncodeStockRecords(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Warehouse Stock Movement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWarehouseStockMovementMessage ==
    \A message \in CheckedWarehouseStockMovementMessage :
        LET read == DecodeWarehouseStockMovementMessage(EncodeWarehouseStockMovementMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
