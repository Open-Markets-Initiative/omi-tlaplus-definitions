------------------------ MODULE Tsx_IndexFeed_v1_19 ------------------------
(***************************************************************************)
(* TMX Group Index Feed v1.19                                              *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* S And P Tsx Official Index Level Message: 122 bytes                     *)
(***************************************************************************)

SAndPTsxOfficialIndexLevelMessage ==
    [ time                : Sample(6),
      indexId             : Sample(4),
      lastLevel           : Sample(8),
      netChange           : Sample(7),
      volume              : Sample(11),
      value               : Sample(12),
      openLevel           : Sample(8),
      settlementValue     : Sample(8),
      specialOpeningQuote : Sample(8),
      percentTrading      : Sample(7),
      highLevel           : Sample(8),
      lowLevel            : Sample(8),
      pe                  : Sample(7),
      yield               : Sample(5),
      markers             : Sample(1),
      bidPrice            : Sample(7),
      askPrice            : Sample(7) ]

EncodeSAndPTsxOfficialIndexLevelMessage(message) ==
    message.time
        \o message.indexId
        \o message.lastLevel
        \o message.netChange
        \o message.volume
        \o message.value
        \o message.openLevel
        \o message.settlementValue
        \o message.specialOpeningQuote
        \o message.percentTrading
        \o message.highLevel
        \o message.lowLevel
        \o message.pe
        \o message.yield
        \o message.markers
        \o message.bidPrice
        \o message.askPrice

DecodeSAndPTsxOfficialIndexLevelMessage(bytes) ==
    LET time == ReadBytes(bytes, 6) IN IF ~time.ok THEN Fail ELSE
    LET indexId == ReadBytes(time.rest, 4) IN IF ~indexId.ok THEN Fail ELSE
    LET lastLevel == ReadBytes(indexId.rest, 8) IN IF ~lastLevel.ok THEN Fail ELSE
    LET netChange == ReadBytes(lastLevel.rest, 7) IN IF ~netChange.ok THEN Fail ELSE
    LET volume == ReadBytes(netChange.rest, 11) IN IF ~volume.ok THEN Fail ELSE
    LET value == ReadBytes(volume.rest, 12) IN IF ~value.ok THEN Fail ELSE
    LET openLevel == ReadBytes(value.rest, 8) IN IF ~openLevel.ok THEN Fail ELSE
    LET settlementValue == ReadBytes(openLevel.rest, 8) IN IF ~settlementValue.ok THEN Fail ELSE
    LET specialOpeningQuote == ReadBytes(settlementValue.rest, 8) IN IF ~specialOpeningQuote.ok THEN Fail ELSE
    LET percentTrading == ReadBytes(specialOpeningQuote.rest, 7) IN IF ~percentTrading.ok THEN Fail ELSE
    LET highLevel == ReadBytes(percentTrading.rest, 8) IN IF ~highLevel.ok THEN Fail ELSE
    LET lowLevel == ReadBytes(highLevel.rest, 8) IN IF ~lowLevel.ok THEN Fail ELSE
    LET pe == ReadBytes(lowLevel.rest, 7) IN IF ~pe.ok THEN Fail ELSE
    LET yield == ReadBytes(pe.rest, 5) IN IF ~yield.ok THEN Fail ELSE
    LET markers == ReadBytes(yield.rest, 1) IN IF ~markers.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(markers.rest, 7) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidPrice.rest, 7) IN IF ~askPrice.ok THEN Fail ELSE
    Ok([ time                |-> time.value,
         indexId             |-> indexId.value,
         lastLevel           |-> lastLevel.value,
         netChange           |-> netChange.value,
         volume              |-> volume.value,
         value               |-> value.value,
         openLevel           |-> openLevel.value,
         settlementValue     |-> settlementValue.value,
         specialOpeningQuote |-> specialOpeningQuote.value,
         percentTrading      |-> percentTrading.value,
         highLevel           |-> highLevel.value,
         lowLevel            |-> lowLevel.value,
         pe                  |-> pe.value,
         yield               |-> yield.value,
         markers             |-> markers.value,
         bidPrice            |-> bidPrice.value,
         askPrice            |-> askPrice.value ], askPrice.rest)

ZeroSAndPTsxOfficialIndexLevelMessage ==
    [ time                |-> [i \in 1 .. 6 |-> 0],
      indexId             |-> [i \in 1 .. 4 |-> 0],
      lastLevel           |-> [i \in 1 .. 8 |-> 0],
      netChange           |-> [i \in 1 .. 7 |-> 0],
      volume              |-> [i \in 1 .. 11 |-> 0],
      value               |-> [i \in 1 .. 12 |-> 0],
      openLevel           |-> [i \in 1 .. 8 |-> 0],
      settlementValue     |-> [i \in 1 .. 8 |-> 0],
      specialOpeningQuote |-> [i \in 1 .. 8 |-> 0],
      percentTrading      |-> [i \in 1 .. 7 |-> 0],
      highLevel           |-> [i \in 1 .. 8 |-> 0],
      lowLevel            |-> [i \in 1 .. 8 |-> 0],
      pe                  |-> [i \in 1 .. 7 |-> 0],
      yield               |-> [i \in 1 .. 5 |-> 0],
      markers             |-> [i \in 1 .. 1 |-> 0],
      bidPrice            |-> [i \in 1 .. 7 |-> 0],
      askPrice            |-> [i \in 1 .. 7 |-> 0] ]

(* S And P Tsx Official Index Level Message at zero, then each field in turn at the values it is checked at *)
CheckedSAndPTsxOfficialIndexLevelMessage ==
    { ZeroSAndPTsxOfficialIndexLevelMessage }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.time = one] : one \in Sample(6) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.indexId = one] : one \in Sample(4) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.lastLevel = one] : one \in Sample(8) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.netChange = one] : one \in Sample(7) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.volume = one] : one \in Sample(11) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.value = one] : one \in Sample(12) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.openLevel = one] : one \in Sample(8) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.settlementValue = one] : one \in Sample(8) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.specialOpeningQuote = one] : one \in Sample(8) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.percentTrading = one] : one \in Sample(7) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.highLevel = one] : one \in Sample(8) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.lowLevel = one] : one \in Sample(8) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.pe = one] : one \in Sample(7) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.yield = one] : one \in Sample(5) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.markers = one] : one \in Sample(1) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.bidPrice = one] : one \in Sample(7) }
        \cup { [ZeroSAndPTsxOfficialIndexLevelMessage EXCEPT !.askPrice = one] : one \in Sample(7) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

SAndPTsxOfficialIndexLevelMessageCode == 19232  \* "K "
BeginningOfIndexSummaryMessageCode == 20545  \* "PA"

MessageBody ==
    [ tag : {SAndPTsxOfficialIndexLevelMessageCode}, body : SAndPTsxOfficialIndexLevelMessage ]
        \cup [ tag : {BeginningOfIndexSummaryMessageCode}, body : {[empty |-> 0]} ]

EncodeMessageBody(message) ==
    CASE message.tag = SAndPTsxOfficialIndexLevelMessageCode -> EncodeSAndPTsxOfficialIndexLevelMessage(message.body)
      [] message.tag = BeginningOfIndexSummaryMessageCode -> << >>

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = SAndPTsxOfficialIndexLevelMessageCode -> DecodeSAndPTsxOfficialIndexLevelMessage(bytes)
              [] tag = BeginningOfIndexSummaryMessageCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> SAndPTsxOfficialIndexLevelMessageCode, body |-> ZeroSAndPTsxOfficialIndexLevelMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> SAndPTsxOfficialIndexLevelMessageCode, body |-> one] : one \in CheckedSAndPTsxOfficialIndexLevelMessage }
        \cup { [tag |-> BeginningOfIndexSummaryMessageCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ qrtmdStx                 : Sample(1),
      messageLength            : Sample(4),
      sequenceNumber           : Sample(9),
      serviceIdentifier        : Sample(3),
      retransmissionIdentifier : Sample(1),
      continuationIdentifier   : Sample(1),
      exchangeIdentifier       : Sample(2),
      messageBody              : MessageBody,
      qrtmdEtx                 : Sample(1) ]

EncodePacket(message) ==
    message.qrtmdStx
        \o message.messageLength
        \o message.sequenceNumber
        \o message.serviceIdentifier
        \o message.retransmissionIdentifier
        \o message.continuationIdentifier
        \o EncodeUIntBE(message.messageBody.tag, 2)
        \o message.exchangeIdentifier
        \o EncodeMessageBody(message.messageBody)
        \o message.qrtmdEtx

DecodePacket(bytes) ==
    LET qrtmdStx == ReadBytes(bytes, 1) IN IF ~qrtmdStx.ok THEN Fail ELSE
    LET messageLength == ReadBytes(qrtmdStx.rest, 4) IN IF ~messageLength.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(messageLength.rest, 9) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET serviceIdentifier == ReadBytes(sequenceNumber.rest, 3) IN IF ~serviceIdentifier.ok THEN Fail ELSE
    LET retransmissionIdentifier == ReadBytes(serviceIdentifier.rest, 1) IN IF ~retransmissionIdentifier.ok THEN Fail ELSE
    LET continuationIdentifier == ReadBytes(retransmissionIdentifier.rest, 1) IN IF ~continuationIdentifier.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(continuationIdentifier.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET exchangeIdentifier == ReadBytes(messageType.rest, 2) IN IF ~exchangeIdentifier.ok THEN Fail ELSE
    LET messageBody == DecodeMessageBody(messageType.value, exchangeIdentifier.rest) IN IF ~messageBody.ok THEN Fail ELSE
    LET qrtmdEtx == ReadBytes(messageBody.rest, 1) IN IF ~qrtmdEtx.ok THEN Fail ELSE
    Ok([ qrtmdStx                 |-> qrtmdStx.value,
         messageLength            |-> messageLength.value,
         sequenceNumber           |-> sequenceNumber.value,
         serviceIdentifier        |-> serviceIdentifier.value,
         retransmissionIdentifier |-> retransmissionIdentifier.value,
         continuationIdentifier   |-> continuationIdentifier.value,
         exchangeIdentifier       |-> exchangeIdentifier.value,
         messageBody              |-> messageBody.value,
         qrtmdEtx                 |-> qrtmdEtx.value ], qrtmdEtx.rest)

ZeroPacket ==
    [ qrtmdStx                 |-> [i \in 1 .. 1 |-> 0],
      messageLength            |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber           |-> [i \in 1 .. 9 |-> 0],
      serviceIdentifier        |-> [i \in 1 .. 3 |-> 0],
      retransmissionIdentifier |-> [i \in 1 .. 1 |-> 0],
      continuationIdentifier   |-> [i \in 1 .. 1 |-> 0],
      exchangeIdentifier       |-> [i \in 1 .. 2 |-> 0],
      messageBody              |-> ZeroMessageBody,
      qrtmdEtx                 |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.qrtmdStx = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.messageLength = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(9) }
        \cup { [ZeroPacket EXCEPT !.serviceIdentifier = one] : one \in Sample(3) }
        \cup { [ZeroPacket EXCEPT !.retransmissionIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.continuationIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.exchangeIdentifier = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroPacket EXCEPT !.qrtmdEtx = one] : one \in Sample(1) }

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

(* Every S And P Tsx Official Index Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSAndPTsxOfficialIndexLevelMessage ==
    \A message \in CheckedSAndPTsxOfficialIndexLevelMessage :
        LET read == DecodeSAndPTsxOfficialIndexLevelMessage(EncodeSAndPTsxOfficialIndexLevelMessage(message))
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

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET read == DecodeMessageBody(message.tag, EncodeMessageBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
