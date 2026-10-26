----------------------- MODULE Siac_Cts_Output_v2_10 -----------------------
(***************************************************************************)
(* The Securities Industry Automation Corporation Output v2.10             *)
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
(* Note: Block Pad Byte pads to a 2 byte boundary: it is read as the bytes *)
(* left to the end of the frame, and the frame's length is trusted to keep *)
(* that boundary.                                                          *)
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
(* Sip Block Timestamp: 8 bytes                                            *)
(***************************************************************************)

SipBlockTimestamp ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeSipBlockTimestamp(message) ==
    message.seconds
        \o message.nanoseconds

DecodeSipBlockTimestamp(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroSipBlockTimestamp ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Sip Block Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedSipBlockTimestamp ==
    { ZeroSipBlockTimestamp }
        \cup { [ZeroSipBlockTimestamp EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSipBlockTimestamp EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp1 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp1(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp1(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp1 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp1 ==
    { ZeroTimestamp1 }
        \cup { [ZeroTimestamp1 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp1 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Start Of End Of Day Message: 22 bytes                                   *)
(***************************************************************************)

StartOfEndOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp1,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeStartOfEndOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp1(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeStartOfEndOfDayMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp1(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroStartOfEndOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp1,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfEndOfDayMessage ==
    { ZeroStartOfEndOfDayMessage }
        \cup { [ZeroStartOfEndOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfEndOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp1 }
        \cup { [ZeroStartOfEndOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfEndOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfEndOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp12 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp12(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp12(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp12 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp12 ==
    { ZeroTimestamp12 }
        \cup { [ZeroTimestamp12 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp12 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of End Of Day Message: 22 bytes                                     *)
(***************************************************************************)

EndOfEndOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp12,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeEndOfEndOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp12(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeEndOfEndOfDayMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp12(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroEndOfEndOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp12,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* End Of End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfEndOfDayMessage ==
    { ZeroEndOfEndOfDayMessage }
        \cup { [ZeroEndOfEndOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfEndOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp12 }
        \cup { [ZeroEndOfEndOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfEndOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfEndOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp13 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp13(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp13(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp13 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp13 ==
    { ZeroTimestamp13 }
        \cup { [ZeroTimestamp13 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp13 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Start Of Start Of Day Message: 22 bytes                                 *)
(***************************************************************************)

StartOfStartOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp13,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeStartOfStartOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp13(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeStartOfStartOfDayMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp13(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroStartOfStartOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp13,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfStartOfDayMessage ==
    { ZeroStartOfStartOfDayMessage }
        \cup { [ZeroStartOfStartOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfStartOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp13 }
        \cup { [ZeroStartOfStartOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfStartOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfStartOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp14 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp14(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp14(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp14 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp14 ==
    { ZeroTimestamp14 }
        \cup { [ZeroTimestamp14 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp14 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Start Of Day Message: 22 bytes                                   *)
(***************************************************************************)

EndOfStartOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp14,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeEndOfStartOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp14(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeEndOfStartOfDayMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp14(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroEndOfStartOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp14,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfStartOfDayMessage ==
    { ZeroEndOfStartOfDayMessage }
        \cup { [ZeroEndOfStartOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfStartOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp14 }
        \cup { [ZeroEndOfStartOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfStartOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfStartOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

StartOfEndOfDayMessageCode == 65  \* "A"
EndOfEndOfDayMessageCode == 66  \* "B"
StartOfStartOfDayMessageCode == 67  \* "C"
EndOfStartOfDayMessageCode == 68  \* "D"

AdministrativeMessagePayload ==
    [ tag : {StartOfEndOfDayMessageCode}, body : StartOfEndOfDayMessage ]
        \cup [ tag : {EndOfEndOfDayMessageCode}, body : EndOfEndOfDayMessage ]
        \cup [ tag : {StartOfStartOfDayMessageCode}, body : StartOfStartOfDayMessage ]
        \cup [ tag : {EndOfStartOfDayMessageCode}, body : EndOfStartOfDayMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = StartOfEndOfDayMessageCode -> EncodeStartOfEndOfDayMessage(message.body)
      [] message.tag = EndOfEndOfDayMessageCode -> EncodeEndOfEndOfDayMessage(message.body)
      [] message.tag = StartOfStartOfDayMessageCode -> EncodeStartOfStartOfDayMessage(message.body)
      [] message.tag = EndOfStartOfDayMessageCode -> EncodeEndOfStartOfDayMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfEndOfDayMessageCode -> DecodeStartOfEndOfDayMessage(bytes)
              [] tag = EndOfEndOfDayMessageCode -> DecodeEndOfEndOfDayMessage(bytes)
              [] tag = StartOfStartOfDayMessageCode -> DecodeStartOfStartOfDayMessage(bytes)
              [] tag = EndOfStartOfDayMessageCode -> DecodeEndOfStartOfDayMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> StartOfEndOfDayMessageCode, body |-> ZeroStartOfEndOfDayMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> StartOfEndOfDayMessageCode, body |-> one] : one \in CheckedStartOfEndOfDayMessage }
        \cup { [tag |-> EndOfEndOfDayMessageCode, body |-> one] : one \in CheckedEndOfEndOfDayMessage }
        \cup { [tag |-> StartOfStartOfDayMessageCode, body |-> one] : one \in CheckedStartOfStartOfDayMessage }
        \cup { [tag |-> EndOfStartOfDayMessageCode, body |-> one] : one \in CheckedEndOfStartOfDayMessage }

(***************************************************************************)
(* Administrative Message                                                  *)
(***************************************************************************)

AdministrativeMessage ==
    [ administrativeMessagePayload : AdministrativeMessagePayload ]

EncodeAdministrativeMessage(message) ==
    EncodeUIntBE(message.administrativeMessagePayload.tag, 1)
        \o EncodeAdministrativeMessagePayload(message.administrativeMessagePayload)

DecodeAdministrativeMessage(bytes) ==
    LET administrativeMessageType == ReadUIntBE(bytes, 1) IN IF ~administrativeMessageType.ok THEN Fail ELSE
    LET administrativeMessagePayload == DecodeAdministrativeMessagePayload(administrativeMessageType.value, administrativeMessageType.rest) IN IF ~administrativeMessagePayload.ok THEN Fail ELSE
    Ok([ administrativeMessagePayload |-> administrativeMessagePayload.value ], administrativeMessagePayload.rest)

ZeroAdministrativeMessage ==
    [ administrativeMessagePayload |-> ZeroAdministrativeMessagePayload ]

(* Administrative Message at zero, then each field in turn at the values it is checked at *)
CheckedAdministrativeMessage ==
    { ZeroAdministrativeMessage }
        \cup { [ZeroAdministrativeMessage EXCEPT !.administrativeMessagePayload = one] : one \in CheckedAdministrativeMessagePayload }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp15 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp15(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp15(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp15 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp15 ==
    { ZeroTimestamp15 }
        \cup { [ZeroTimestamp15 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp15 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Start Of Day Message: 22 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp15,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeStartOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp15(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeStartOfDayMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp15(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroStartOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp15,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp15 }
        \cup { [ZeroStartOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp16 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp16(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp16(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp16 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp16 ==
    { ZeroTimestamp16 }
        \cup { [ZeroTimestamp16 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp16 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Reset Block Sequence Number Message: 22 bytes                           *)
(***************************************************************************)

ResetBlockSequenceNumberMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp16,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeResetBlockSequenceNumberMessage(message) ==
    message.participantId
        \o EncodeTimestamp16(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeResetBlockSequenceNumberMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp16(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroResetBlockSequenceNumberMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp16,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Reset Block Sequence Number Message at zero, then each field in turn at the values it is checked at *)
CheckedResetBlockSequenceNumberMessage ==
    { ZeroResetBlockSequenceNumberMessage }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp16 }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp17 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp17(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp17(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp17 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp17 ==
    { ZeroTimestamp17 }
        \cup { [ZeroTimestamp17 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp17 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Disaster Recovery Data Center Activation Message: 22 bytes              *)
(***************************************************************************)

DisasterRecoveryDataCenterActivationMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp17,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeDisasterRecoveryDataCenterActivationMessage(message) ==
    message.participantId
        \o EncodeTimestamp17(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeDisasterRecoveryDataCenterActivationMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp17(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroDisasterRecoveryDataCenterActivationMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp17,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Disaster Recovery Data Center Activation Message at zero, then each field in turn at the values it is checked at *)
CheckedDisasterRecoveryDataCenterActivationMessage ==
    { ZeroDisasterRecoveryDataCenterActivationMessage }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp17 }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp18 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp18(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp18(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp18 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp18 ==
    { ZeroTimestamp18 }
        \cup { [ZeroTimestamp18 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp18 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Line Integrity Message: 22 bytes                                        *)
(***************************************************************************)

LineIntegrityMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp18,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeLineIntegrityMessage(message) ==
    message.participantId
        \o EncodeTimestamp18(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeLineIntegrityMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp18(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroLineIntegrityMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp18,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Line Integrity Message at zero, then each field in turn at the values it is checked at *)
CheckedLineIntegrityMessage ==
    { ZeroLineIntegrityMessage }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp18 }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp19 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp19(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp19(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp19 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp19 ==
    { ZeroTimestamp19 }
        \cup { [ZeroTimestamp19 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp19 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Day Message: 22 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp19,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeEndOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp19(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeEndOfDayMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp19(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value ], participantReferenceNumber.rest)

ZeroEndOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp19,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp19 }
        \cup { [ZeroEndOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 65  \* "A"
ResetBlockSequenceNumberMessageCode == 76  \* "L"
DisasterRecoveryDataCenterActivationMessageCode == 80  \* "P"
LineIntegrityMessageCode == 84  \* "T"
EndOfDayMessageCode == 90  \* "Z"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {ResetBlockSequenceNumberMessageCode}, body : ResetBlockSequenceNumberMessage ]
        \cup [ tag : {DisasterRecoveryDataCenterActivationMessageCode}, body : DisasterRecoveryDataCenterActivationMessage ]
        \cup [ tag : {LineIntegrityMessageCode}, body : LineIntegrityMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = ResetBlockSequenceNumberMessageCode -> EncodeResetBlockSequenceNumberMessage(message.body)
      [] message.tag = DisasterRecoveryDataCenterActivationMessageCode -> EncodeDisasterRecoveryDataCenterActivationMessage(message.body)
      [] message.tag = LineIntegrityMessageCode -> EncodeLineIntegrityMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = ResetBlockSequenceNumberMessageCode -> DecodeResetBlockSequenceNumberMessage(bytes)
              [] tag = DisasterRecoveryDataCenterActivationMessageCode -> DecodeDisasterRecoveryDataCenterActivationMessage(bytes)
              [] tag = LineIntegrityMessageCode -> DecodeLineIntegrityMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> ResetBlockSequenceNumberMessageCode, body |-> one] : one \in CheckedResetBlockSequenceNumberMessage }
        \cup { [tag |-> DisasterRecoveryDataCenterActivationMessageCode, body |-> one] : one \in CheckedDisasterRecoveryDataCenterActivationMessage }
        \cup { [tag |-> LineIntegrityMessageCode, body |-> one] : one \in CheckedLineIntegrityMessage }
        \cup { [tag |-> EndOfDayMessageCode, body |-> one] : one \in CheckedEndOfDayMessage }

(***************************************************************************)
(* Control Message                                                         *)
(***************************************************************************)

ControlMessage ==
    [ controlMessagePayload : ControlMessagePayload ]

EncodeControlMessage(message) ==
    EncodeUIntBE(message.controlMessagePayload.tag, 1)
        \o EncodeControlMessagePayload(message.controlMessagePayload)

DecodeControlMessage(bytes) ==
    LET controlMessageType == ReadUIntBE(bytes, 1) IN IF ~controlMessageType.ok THEN Fail ELSE
    LET controlMessagePayload == DecodeControlMessagePayload(controlMessageType.value, controlMessageType.rest) IN IF ~controlMessagePayload.ok THEN Fail ELSE
    Ok([ controlMessagePayload |-> controlMessagePayload.value ], controlMessagePayload.rest)

ZeroControlMessage ==
    [ controlMessagePayload |-> ZeroControlMessagePayload ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.controlMessagePayload = one] : one \in CheckedControlMessagePayload }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp110 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp110(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp110(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp110 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp110 ==
    { ZeroTimestamp110 }
        \cup { [ZeroTimestamp110 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp110 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Index Message: 41 bytes                                                 *)
(***************************************************************************)

IndexMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp110,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      indexSymbol                : Sample(11),
      indexValue                 : Sample(8) ]

EncodeIndexMessage(message) ==
    message.participantId
        \o EncodeTimestamp110(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.indexSymbol
        \o message.indexValue

DecodeIndexMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp110(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET indexSymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~indexSymbol.ok THEN Fail ELSE
    LET indexValue == ReadBytes(indexSymbol.rest, 8) IN IF ~indexValue.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         indexSymbol                |-> indexSymbol.value,
         indexValue                 |-> indexValue.value ], indexValue.rest)

ZeroIndexMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp110,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      indexSymbol                |-> [i \in 1 .. 11 |-> 0],
      indexValue                 |-> [i \in 1 .. 8 |-> 0] ]

(* Index Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexMessage ==
    { ZeroIndexMessage }
        \cup { [ZeroIndexMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroIndexMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp110 }
        \cup { [ZeroIndexMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroIndexMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroIndexMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroIndexMessage EXCEPT !.indexSymbol = one] : one \in Sample(11) }
        \cup { [ZeroIndexMessage EXCEPT !.indexValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp111 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp111(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp111(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp111 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp111 ==
    { ZeroTimestamp111 }
        \cup { [ZeroTimestamp111 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp111 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Bid And Offer Index Message: 49 bytes                                   *)
(***************************************************************************)

BidAndOfferIndexMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp111,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      indexSymbol                : Sample(11),
      bidIndexValue              : Sample(8),
      offerIndexValue            : Sample(8) ]

EncodeBidAndOfferIndexMessage(message) ==
    message.participantId
        \o EncodeTimestamp111(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.indexSymbol
        \o message.bidIndexValue
        \o message.offerIndexValue

DecodeBidAndOfferIndexMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp111(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET indexSymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~indexSymbol.ok THEN Fail ELSE
    LET bidIndexValue == ReadBytes(indexSymbol.rest, 8) IN IF ~bidIndexValue.ok THEN Fail ELSE
    LET offerIndexValue == ReadBytes(bidIndexValue.rest, 8) IN IF ~offerIndexValue.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         indexSymbol                |-> indexSymbol.value,
         bidIndexValue              |-> bidIndexValue.value,
         offerIndexValue            |-> offerIndexValue.value ], offerIndexValue.rest)

ZeroBidAndOfferIndexMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp111,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      indexSymbol                |-> [i \in 1 .. 11 |-> 0],
      bidIndexValue              |-> [i \in 1 .. 8 |-> 0],
      offerIndexValue            |-> [i \in 1 .. 8 |-> 0] ]

(* Bid And Offer Index Message at zero, then each field in turn at the values it is checked at *)
CheckedBidAndOfferIndexMessage ==
    { ZeroBidAndOfferIndexMessage }
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp111 }
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.indexSymbol = one] : one \in Sample(11) }
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.bidIndexValue = one] : one \in Sample(8) }
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.offerIndexValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Indices Message Payload, selected by Indices Message Type               *)
(***************************************************************************)

IndexMessageCode == 73  \* "I"
BidAndOfferIndexMessageCode == 81  \* "Q"

IndicesMessagePayload ==
    [ tag : {IndexMessageCode}, body : IndexMessage ]
        \cup [ tag : {BidAndOfferIndexMessageCode}, body : BidAndOfferIndexMessage ]

EncodeIndicesMessagePayload(message) ==
    CASE message.tag = IndexMessageCode -> EncodeIndexMessage(message.body)
      [] message.tag = BidAndOfferIndexMessageCode -> EncodeBidAndOfferIndexMessage(message.body)

DecodeIndicesMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = IndexMessageCode -> DecodeIndexMessage(bytes)
              [] tag = BidAndOfferIndexMessageCode -> DecodeBidAndOfferIndexMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroIndicesMessagePayload == [tag |-> IndexMessageCode, body |-> ZeroIndexMessage]

(* Each Indices Message Payload in turn, at the values the message it names is checked at *)
CheckedIndicesMessagePayload ==
    { [tag |-> IndexMessageCode, body |-> one] : one \in CheckedIndexMessage }
        \cup { [tag |-> BidAndOfferIndexMessageCode, body |-> one] : one \in CheckedBidAndOfferIndexMessage }

(***************************************************************************)
(* Indices Message                                                         *)
(***************************************************************************)

IndicesMessage ==
    [ indicesMessagePayload : IndicesMessagePayload ]

EncodeIndicesMessage(message) ==
    EncodeUIntBE(message.indicesMessagePayload.tag, 1)
        \o EncodeIndicesMessagePayload(message.indicesMessagePayload)

DecodeIndicesMessage(bytes) ==
    LET indicesMessageType == ReadUIntBE(bytes, 1) IN IF ~indicesMessageType.ok THEN Fail ELSE
    LET indicesMessagePayload == DecodeIndicesMessagePayload(indicesMessageType.value, indicesMessageType.rest) IN IF ~indicesMessagePayload.ok THEN Fail ELSE
    Ok([ indicesMessagePayload |-> indicesMessagePayload.value ], indicesMessagePayload.rest)

ZeroIndicesMessage ==
    [ indicesMessagePayload |-> ZeroIndicesMessagePayload ]

(* Indices Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicesMessage ==
    { ZeroIndicesMessage }
        \cup { [ZeroIndicesMessage EXCEPT !.indicesMessagePayload = one] : one \in CheckedIndicesMessagePayload }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp112 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp112(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp112(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp112 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp112 ==
    { ZeroTimestamp112 }
        \cup { [ZeroTimestamp112 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp112 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Wide Circuit Breaker Decline Level Status Message: 47 bytes      *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelStatusMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp112,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      mwcbLevel1                 : Sample(8),
      mwcbLevel2                 : Sample(8),
      mwcbLevel3                 : Sample(8),
      reserved                   : Sample(1) ]

EncodeMarketWideCircuitBreakerDeclineLevelStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp112(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3
        \o message.reserved

DecodeMarketWideCircuitBreakerDeclineLevelStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp112(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET mwcbLevel1 == ReadBytes(participantReferenceNumber.rest, 8) IN IF ~mwcbLevel1.ok THEN Fail ELSE
    LET mwcbLevel2 == ReadBytes(mwcbLevel1.rest, 8) IN IF ~mwcbLevel2.ok THEN Fail ELSE
    LET mwcbLevel3 == ReadBytes(mwcbLevel2.rest, 8) IN IF ~mwcbLevel3.ok THEN Fail ELSE
    LET reserved == ReadBytes(mwcbLevel3.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         mwcbLevel1                 |-> mwcbLevel1.value,
         mwcbLevel2                 |-> mwcbLevel2.value,
         mwcbLevel3                 |-> mwcbLevel3.value,
         reserved                   |-> reserved.value ], reserved.rest)

ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp112,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel1                 |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel2                 |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel3                 |-> [i \in 1 .. 8 |-> 0],
      reserved                   |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Decline Level Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerDeclineLevelStatusMessage ==
    { ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp112 }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.mwcbLevel1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.mwcbLevel2 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.mwcbLevel3 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.reserved = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp113 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp113(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp113(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp113 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp113 ==
    { ZeroTimestamp113 }
        \cup { [ZeroTimestamp113 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp113 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Wide Circuit Breaker Status Message: 24 bytes                    *)
(***************************************************************************)

MarketWideCircuitBreakerStatusMessage ==
    [ participantId                          : Sample(1),
      timestamp1                             : Timestamp113,
      messageId                              : Sample(1),
      transactionId                          : Sample(4),
      participantReferenceNumber             : Sample(8),
      marketWideCircuitBreakerLevelIndicator : Sample(1),
      reserved                               : Sample(1) ]

EncodeMarketWideCircuitBreakerStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp113(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.marketWideCircuitBreakerLevelIndicator
        \o message.reserved

DecodeMarketWideCircuitBreakerStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp113(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET marketWideCircuitBreakerLevelIndicator == ReadBytes(participantReferenceNumber.rest, 1) IN IF ~marketWideCircuitBreakerLevelIndicator.ok THEN Fail ELSE
    LET reserved == ReadBytes(marketWideCircuitBreakerLevelIndicator.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    Ok([ participantId                          |-> participantId.value,
         timestamp1                             |-> timestamp1.value,
         messageId                              |-> messageId.value,
         transactionId                          |-> transactionId.value,
         participantReferenceNumber             |-> participantReferenceNumber.value,
         marketWideCircuitBreakerLevelIndicator |-> marketWideCircuitBreakerLevelIndicator.value,
         reserved                               |-> reserved.value ], reserved.rest)

ZeroMarketWideCircuitBreakerStatusMessage ==
    [ participantId                          |-> [i \in 1 .. 1 |-> 0],
      timestamp1                             |-> ZeroTimestamp113,
      messageId                              |-> [i \in 1 .. 1 |-> 0],
      transactionId                          |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber             |-> [i \in 1 .. 8 |-> 0],
      marketWideCircuitBreakerLevelIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved                               |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerStatusMessage ==
    { ZeroMarketWideCircuitBreakerStatusMessage }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp113 }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.marketWideCircuitBreakerLevelIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.reserved = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp114 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp114(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp114(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp114 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp114 ==
    { ZeroTimestamp114 }
        \cup { [ZeroTimestamp114 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp114 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Participants: 9 bytes                                                   *)
(***************************************************************************)

Participants ==
    [ participantId    : Sample(1),
      tradeTotalVolume : Sample(8) ]

EncodeParticipants(message) ==
    message.participantId
        \o message.tradeTotalVolume

DecodeParticipants(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET tradeTotalVolume == ReadBytes(participantId.rest, 8) IN IF ~tradeTotalVolume.ok THEN Fail ELSE
    Ok([ participantId    |-> participantId.value,
         tradeTotalVolume |-> tradeTotalVolume.value ], tradeTotalVolume.rest)

ZeroParticipants ==
    [ participantId    |-> [i \in 1 .. 1 |-> 0],
      tradeTotalVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Participants at zero, then each field in turn at the values it is checked at *)
CheckedParticipants ==
    { ZeroParticipants }
        \cup { [ZeroParticipants EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroParticipants EXCEPT !.tradeTotalVolume = one] : one \in Sample(8) }

(* A run of Participants, written one after another *)
RECURSIVE EncodeParticipantsList(_)
EncodeParticipantsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeParticipants(Head(messages)) \o EncodeParticipantsList(Tail(messages))

(* As many Participants as the field that counts them says *)
RECURSIVE ReadParticipantsList(_, _)
ReadParticipantsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeParticipants(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadParticipantsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Participants of each kind, for the lists that carry them *)
OneParticipants == { ZeroParticipants }

(***************************************************************************)
(* Approximate Adjusted Volume Market Center Message                       *)
(***************************************************************************)

ApproximateAdjustedVolumeMarketCenterMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp114,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      participants               : SampleLists(OneParticipants) ]

EncodeApproximateAdjustedVolumeMarketCenterMessage(message) ==
    message.participantId
        \o EncodeTimestamp114(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o EncodeUIntBE(Len(message.participants), 1)
        \o EncodeParticipantsList(message.participants)

DecodeApproximateAdjustedVolumeMarketCenterMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp114(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET numberOfParticipants == ReadUIntBE(participantReferenceNumber.rest, 1) IN IF ~numberOfParticipants.ok THEN Fail ELSE
    LET participants == ReadParticipantsList(numberOfParticipants.rest, numberOfParticipants.value) IN IF ~participants.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         participants               |-> participants.value ], participants.rest)

ZeroApproximateAdjustedVolumeMarketCenterMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp114,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      participants               |-> << >> ]

(* Approximate Adjusted Volume Market Center Message at zero, then each field in turn at the values it is checked at *)
CheckedApproximateAdjustedVolumeMarketCenterMessage ==
    { ZeroApproximateAdjustedVolumeMarketCenterMessage }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp114 }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participants = one] : one \in SampleLists(OneParticipants) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp115 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp115(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp115(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp115 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp115 ==
    { ZeroTimestamp115 }
        \cup { [ZeroTimestamp115 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp115 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Participants: 9 bytes                                        *)
(***************************************************************************)

FractionalParticipants ==
    [ participantId              : Sample(1),
      fractionalTradeTotalVolume : Sample(8) ]

EncodeFractionalParticipants(message) ==
    message.participantId
        \o message.fractionalTradeTotalVolume

DecodeFractionalParticipants(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET fractionalTradeTotalVolume == ReadBytes(participantId.rest, 8) IN IF ~fractionalTradeTotalVolume.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         fractionalTradeTotalVolume |-> fractionalTradeTotalVolume.value ], fractionalTradeTotalVolume.rest)

ZeroFractionalParticipants ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      fractionalTradeTotalVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional Participants at zero, then each field in turn at the values it is checked at *)
CheckedFractionalParticipants ==
    { ZeroFractionalParticipants }
        \cup { [ZeroFractionalParticipants EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalParticipants EXCEPT !.fractionalTradeTotalVolume = one] : one \in Sample(8) }

(* A run of Fractional Participants, written one after another *)
RECURSIVE EncodeFractionalParticipantsList(_)
EncodeFractionalParticipantsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFractionalParticipants(Head(messages)) \o EncodeFractionalParticipantsList(Tail(messages))

(* As many Fractional Participants as the field that counts them says *)
RECURSIVE ReadFractionalParticipantsList(_, _)
ReadFractionalParticipantsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFractionalParticipants(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFractionalParticipantsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fractional Participants of each kind, for the lists that carry them *)
OneFractionalParticipants == { ZeroFractionalParticipants }

(***************************************************************************)
(* Fractional Approximate Adjusted Volume Market Center Message            *)
(***************************************************************************)

FractionalApproximateAdjustedVolumeMarketCenterMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp115,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      fractionalParticipants     : SampleLists(OneFractionalParticipants) ]

EncodeFractionalApproximateAdjustedVolumeMarketCenterMessage(message) ==
    message.participantId
        \o EncodeTimestamp115(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o EncodeUIntBE(Len(message.fractionalParticipants), 1)
        \o EncodeFractionalParticipantsList(message.fractionalParticipants)

DecodeFractionalApproximateAdjustedVolumeMarketCenterMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp115(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET numberOfParticipants == ReadUIntBE(participantReferenceNumber.rest, 1) IN IF ~numberOfParticipants.ok THEN Fail ELSE
    LET fractionalParticipants == ReadFractionalParticipantsList(numberOfParticipants.rest, numberOfParticipants.value) IN IF ~fractionalParticipants.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         fractionalParticipants     |-> fractionalParticipants.value ], fractionalParticipants.rest)

ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp115,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      fractionalParticipants     |-> << >> ]

(* Fractional Approximate Adjusted Volume Market Center Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalApproximateAdjustedVolumeMarketCenterMessage ==
    { ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp115 }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.fractionalParticipants = one] : one \in SampleLists(OneFractionalParticipants) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp116 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp116(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp116(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp116 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp116 ==
    { ZeroTimestamp116 }
        \cup { [ZeroTimestamp116 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp116 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Approximate Trades And Total Dollar Value Message: 34 bytes             *)
(***************************************************************************)

ApproximateTradesAndTotalDollarValueMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp116,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      totalTrades                : Sample(4),
      dollarValue                : Sample(8) ]

EncodeApproximateTradesAndTotalDollarValueMessage(message) ==
    message.participantId
        \o EncodeTimestamp116(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.totalTrades
        \o message.dollarValue

DecodeApproximateTradesAndTotalDollarValueMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp116(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET totalTrades == ReadBytes(participantReferenceNumber.rest, 4) IN IF ~totalTrades.ok THEN Fail ELSE
    LET dollarValue == ReadBytes(totalTrades.rest, 8) IN IF ~dollarValue.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         totalTrades                |-> totalTrades.value,
         dollarValue                |-> dollarValue.value ], dollarValue.rest)

ZeroApproximateTradesAndTotalDollarValueMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp116,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      totalTrades                |-> [i \in 1 .. 4 |-> 0],
      dollarValue                |-> [i \in 1 .. 8 |-> 0] ]

(* Approximate Trades And Total Dollar Value Message at zero, then each field in turn at the values it is checked at *)
CheckedApproximateTradesAndTotalDollarValueMessage ==
    { ZeroApproximateTradesAndTotalDollarValueMessage }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp116 }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.totalTrades = one] : one \in Sample(4) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.dollarValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp117 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp117(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp117(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp117 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp117 ==
    { ZeroTimestamp117 }
        \cup { [ZeroTimestamp117 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp117 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Crossing Session Summary Message: 46 bytes                              *)
(***************************************************************************)

CrossingSessionSummaryMessage ==
    [ participantId                      : Sample(1),
      timestamp1                         : Timestamp117,
      messageId                          : Sample(1),
      transactionId                      : Sample(4),
      participantReferenceNumber         : Sample(8),
      crossingSessionITotalTradesVolume  : Sample(8),
      crossingSessionIiDollarValue       : Sample(8),
      crossingSessionIiTotalTradesVolume : Sample(8) ]

EncodeCrossingSessionSummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp117(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.crossingSessionITotalTradesVolume
        \o message.crossingSessionIiDollarValue
        \o message.crossingSessionIiTotalTradesVolume

DecodeCrossingSessionSummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp117(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET crossingSessionITotalTradesVolume == ReadBytes(participantReferenceNumber.rest, 8) IN IF ~crossingSessionITotalTradesVolume.ok THEN Fail ELSE
    LET crossingSessionIiDollarValue == ReadBytes(crossingSessionITotalTradesVolume.rest, 8) IN IF ~crossingSessionIiDollarValue.ok THEN Fail ELSE
    LET crossingSessionIiTotalTradesVolume == ReadBytes(crossingSessionIiDollarValue.rest, 8) IN IF ~crossingSessionIiTotalTradesVolume.ok THEN Fail ELSE
    Ok([ participantId                      |-> participantId.value,
         timestamp1                         |-> timestamp1.value,
         messageId                          |-> messageId.value,
         transactionId                      |-> transactionId.value,
         participantReferenceNumber         |-> participantReferenceNumber.value,
         crossingSessionITotalTradesVolume  |-> crossingSessionITotalTradesVolume.value,
         crossingSessionIiDollarValue       |-> crossingSessionIiDollarValue.value,
         crossingSessionIiTotalTradesVolume |-> crossingSessionIiTotalTradesVolume.value ], crossingSessionIiTotalTradesVolume.rest)

ZeroCrossingSessionSummaryMessage ==
    [ participantId                      |-> [i \in 1 .. 1 |-> 0],
      timestamp1                         |-> ZeroTimestamp117,
      messageId                          |-> [i \in 1 .. 1 |-> 0],
      transactionId                      |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      crossingSessionITotalTradesVolume  |-> [i \in 1 .. 8 |-> 0],
      crossingSessionIiDollarValue       |-> [i \in 1 .. 8 |-> 0],
      crossingSessionIiTotalTradesVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Crossing Session Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossingSessionSummaryMessage ==
    { ZeroCrossingSessionSummaryMessage }
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp117 }
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.crossingSessionITotalTradesVolume = one] : one \in Sample(8) }
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.crossingSessionIiDollarValue = one] : one \in Sample(8) }
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.crossingSessionIiTotalTradesVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Status Message Payload, selected by Market Status Message Type   *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelStatusMessageCode == 75  \* "K"
MarketWideCircuitBreakerStatusMessageCode == 76  \* "L"
ApproximateAdjustedVolumeMarketCenterMessageCode == 78  \* "N"
FractionalApproximateAdjustedVolumeMarketCenterMessageCode == 86  \* "V"
ApproximateTradesAndTotalDollarValueMessageCode == 79  \* "O"
CrossingSessionSummaryMessageCode == 80  \* "P"

MarketStatusMessagePayload ==
    [ tag : {MarketWideCircuitBreakerDeclineLevelStatusMessageCode}, body : MarketWideCircuitBreakerDeclineLevelStatusMessage ]
        \cup [ tag : {MarketWideCircuitBreakerStatusMessageCode}, body : MarketWideCircuitBreakerStatusMessage ]
        \cup [ tag : {ApproximateAdjustedVolumeMarketCenterMessageCode}, body : ApproximateAdjustedVolumeMarketCenterMessage ]
        \cup [ tag : {FractionalApproximateAdjustedVolumeMarketCenterMessageCode}, body : FractionalApproximateAdjustedVolumeMarketCenterMessage ]
        \cup [ tag : {ApproximateTradesAndTotalDollarValueMessageCode}, body : ApproximateTradesAndTotalDollarValueMessage ]
        \cup [ tag : {CrossingSessionSummaryMessageCode}, body : CrossingSessionSummaryMessage ]

EncodeMarketStatusMessagePayload(message) ==
    CASE message.tag = MarketWideCircuitBreakerDeclineLevelStatusMessageCode -> EncodeMarketWideCircuitBreakerDeclineLevelStatusMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerStatusMessageCode -> EncodeMarketWideCircuitBreakerStatusMessage(message.body)
      [] message.tag = ApproximateAdjustedVolumeMarketCenterMessageCode -> EncodeApproximateAdjustedVolumeMarketCenterMessage(message.body)
      [] message.tag = FractionalApproximateAdjustedVolumeMarketCenterMessageCode -> EncodeFractionalApproximateAdjustedVolumeMarketCenterMessage(message.body)
      [] message.tag = ApproximateTradesAndTotalDollarValueMessageCode -> EncodeApproximateTradesAndTotalDollarValueMessage(message.body)
      [] message.tag = CrossingSessionSummaryMessageCode -> EncodeCrossingSessionSummaryMessage(message.body)

DecodeMarketStatusMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = MarketWideCircuitBreakerDeclineLevelStatusMessageCode -> DecodeMarketWideCircuitBreakerDeclineLevelStatusMessage(bytes)
              [] tag = MarketWideCircuitBreakerStatusMessageCode -> DecodeMarketWideCircuitBreakerStatusMessage(bytes)
              [] tag = ApproximateAdjustedVolumeMarketCenterMessageCode -> DecodeApproximateAdjustedVolumeMarketCenterMessage(bytes)
              [] tag = FractionalApproximateAdjustedVolumeMarketCenterMessageCode -> DecodeFractionalApproximateAdjustedVolumeMarketCenterMessage(bytes)
              [] tag = ApproximateTradesAndTotalDollarValueMessageCode -> DecodeApproximateTradesAndTotalDollarValueMessage(bytes)
              [] tag = CrossingSessionSummaryMessageCode -> DecodeCrossingSessionSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMarketStatusMessagePayload == [tag |-> MarketWideCircuitBreakerDeclineLevelStatusMessageCode, body |-> ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage]

(* Each Market Status Message Payload in turn, at the values the message it names is checked at *)
CheckedMarketStatusMessagePayload ==
    { [tag |-> MarketWideCircuitBreakerDeclineLevelStatusMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerDeclineLevelStatusMessage }
        \cup { [tag |-> MarketWideCircuitBreakerStatusMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerStatusMessage }
        \cup { [tag |-> ApproximateAdjustedVolumeMarketCenterMessageCode, body |-> one] : one \in CheckedApproximateAdjustedVolumeMarketCenterMessage }
        \cup { [tag |-> FractionalApproximateAdjustedVolumeMarketCenterMessageCode, body |-> one] : one \in CheckedFractionalApproximateAdjustedVolumeMarketCenterMessage }
        \cup { [tag |-> ApproximateTradesAndTotalDollarValueMessageCode, body |-> one] : one \in CheckedApproximateTradesAndTotalDollarValueMessage }
        \cup { [tag |-> CrossingSessionSummaryMessageCode, body |-> one] : one \in CheckedCrossingSessionSummaryMessage }

(***************************************************************************)
(* Market Status Message                                                   *)
(***************************************************************************)

MarketStatusMessage ==
    [ marketStatusMessagePayload : MarketStatusMessagePayload ]

EncodeMarketStatusMessage(message) ==
    EncodeUIntBE(message.marketStatusMessagePayload.tag, 1)
        \o EncodeMarketStatusMessagePayload(message.marketStatusMessagePayload)

DecodeMarketStatusMessage(bytes) ==
    LET marketStatusMessageType == ReadUIntBE(bytes, 1) IN IF ~marketStatusMessageType.ok THEN Fail ELSE
    LET marketStatusMessagePayload == DecodeMarketStatusMessagePayload(marketStatusMessageType.value, marketStatusMessageType.rest) IN IF ~marketStatusMessagePayload.ok THEN Fail ELSE
    Ok([ marketStatusMessagePayload |-> marketStatusMessagePayload.value ], marketStatusMessagePayload.rest)

ZeroMarketStatusMessage ==
    [ marketStatusMessagePayload |-> ZeroMarketStatusMessagePayload ]

(* Market Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatusMessage ==
    { ZeroMarketStatusMessage }
        \cup { [ZeroMarketStatusMessage EXCEPT !.marketStatusMessagePayload = one] : one \in CheckedMarketStatusMessagePayload }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp118 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp118(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp118(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp118 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp118 ==
    { ZeroTimestamp118 }
        \cup { [ZeroTimestamp118 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp118 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions ==
    { ZeroSaleConditions }
        \cup { [ZeroSaleConditions EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date And Time: 8 bytes                                  *)
(***************************************************************************)

PriorDayTradeDateAndTime ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodePriorDayTradeDateAndTime(message) ==
    message.seconds
        \o message.nanoseconds

DecodePriorDayTradeDateAndTime(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroPriorDayTradeDateAndTime ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime ==
    { ZeroPriorDayTradeDateAndTime }
        \cup { [ZeroPriorDayTradeDateAndTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Prior Day Corrected Trade: 28 bytes                                     *)
(***************************************************************************)

PriorDayCorrectedTrade ==
    [ saleConditions                : SaleConditions,
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime ]

EncodePriorDayCorrectedTrade(message) ==
    EncodeSaleConditions(message.saleConditions)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o EncodePriorDayTradeDateAndTime(message.priorDayTradeDateAndTime)

DecodePriorDayCorrectedTrade(bytes) ==
    LET saleConditions == DecodeSaleConditions(bytes) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime(shortSaleRestrictionIndicator.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         tradeVolume                   |-> tradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroPriorDayCorrectedTrade ==
    [ saleConditions                |-> ZeroSaleConditions,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime ]

(* Prior Day Corrected Trade at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayCorrectedTrade ==
    { ZeroPriorDayCorrectedTrade }
        \cup { [ZeroPriorDayCorrectedTrade EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions }
        \cup { [ZeroPriorDayCorrectedTrade EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayCorrectedTrade EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayCorrectedTrade EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayCorrectedTrade EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayCorrectedTrade EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayCorrectedTrade EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayCorrectedTrade EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions2 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions2(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions2(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions2 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions2 ==
    { ZeroSaleConditions2 }
        \cup { [ZeroSaleConditions2 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions2 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions2 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions2 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date And Time: 8 bytes                                  *)
(***************************************************************************)

PriorDayTradeDateAndTime2 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodePriorDayTradeDateAndTime2(message) ==
    message.seconds
        \o message.nanoseconds

DecodePriorDayTradeDateAndTime2(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroPriorDayTradeDateAndTime2 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime2 ==
    { ZeroPriorDayTradeDateAndTime2 }
        \cup { [ZeroPriorDayTradeDateAndTime2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Prior Day Original Trade: 28 bytes                                      *)
(***************************************************************************)

PriorDayOriginalTrade ==
    [ saleConditions                : SaleConditions2,
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime2 ]

EncodePriorDayOriginalTrade(message) ==
    EncodeSaleConditions2(message.saleConditions)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o EncodePriorDayTradeDateAndTime2(message.priorDayTradeDateAndTime)

DecodePriorDayOriginalTrade(bytes) ==
    LET saleConditions == DecodeSaleConditions2(bytes) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime2(shortSaleRestrictionIndicator.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         tradeVolume                   |-> tradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroPriorDayOriginalTrade ==
    [ saleConditions                |-> ZeroSaleConditions2,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime2 ]

(* Prior Day Original Trade at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayOriginalTrade ==
    { ZeroPriorDayOriginalTrade }
        \cup { [ZeroPriorDayOriginalTrade EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions2 }
        \cup { [ZeroPriorDayOriginalTrade EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayOriginalTrade EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayOriginalTrade EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayOriginalTrade EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayOriginalTrade EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayOriginalTrade EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayOriginalTrade EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime2 }

(***************************************************************************)
(* Prior Day Trade Correction Message: 91 bytes                            *)
(***************************************************************************)

PriorDayTradeCorrectionMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp118,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      securitySymbol             : Sample(11),
      instrumentType             : Sample(1),
      priorDayCorrectedTrade     : PriorDayCorrectedTrade,
      tradeReportingFacilityId   : Sample(1),
      priorDayOriginalTrade      : PriorDayOriginalTrade ]

EncodePriorDayTradeCorrectionMessage(message) ==
    message.participantId
        \o EncodeTimestamp118(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodePriorDayCorrectedTrade(message.priorDayCorrectedTrade)
        \o message.tradeReportingFacilityId
        \o EncodePriorDayOriginalTrade(message.priorDayOriginalTrade)

DecodePriorDayTradeCorrectionMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp118(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET priorDayCorrectedTrade == DecodePriorDayCorrectedTrade(instrumentType.rest) IN IF ~priorDayCorrectedTrade.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(priorDayCorrectedTrade.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayOriginalTrade == DecodePriorDayOriginalTrade(tradeReportingFacilityId.rest) IN IF ~priorDayOriginalTrade.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         securitySymbol             |-> securitySymbol.value,
         instrumentType             |-> instrumentType.value,
         priorDayCorrectedTrade     |-> priorDayCorrectedTrade.value,
         tradeReportingFacilityId   |-> tradeReportingFacilityId.value,
         priorDayOriginalTrade      |-> priorDayOriginalTrade.value ], priorDayOriginalTrade.rest)

ZeroPriorDayTradeCorrectionMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp118,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      securitySymbol             |-> [i \in 1 .. 11 |-> 0],
      instrumentType             |-> [i \in 1 .. 1 |-> 0],
      priorDayCorrectedTrade     |-> ZeroPriorDayCorrectedTrade,
      tradeReportingFacilityId   |-> [i \in 1 .. 1 |-> 0],
      priorDayOriginalTrade      |-> ZeroPriorDayOriginalTrade ]

(* Prior Day Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeCorrectionMessage ==
    { ZeroPriorDayTradeCorrectionMessage }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp118 }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.priorDayCorrectedTrade = one] : one \in CheckedPriorDayCorrectedTrade }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.priorDayOriginalTrade = one] : one \in CheckedPriorDayOriginalTrade }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp119 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp119(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp119(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp119 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp119 ==
    { ZeroTimestamp119 }
        \cup { [ZeroTimestamp119 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp119 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions3 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions3(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions3(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions3 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions3 ==
    { ZeroSaleConditions3 }
        \cup { [ZeroSaleConditions3 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions3 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions3 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions3 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date And Time: 8 bytes                                  *)
(***************************************************************************)

PriorDayTradeDateAndTime3 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodePriorDayTradeDateAndTime3(message) ==
    message.seconds
        \o message.nanoseconds

DecodePriorDayTradeDateAndTime3(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroPriorDayTradeDateAndTime3 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime3 ==
    { ZeroPriorDayTradeDateAndTime3 }
        \cup { [ZeroPriorDayTradeDateAndTime3 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime3 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Prior Day Corrected Trade: 32 bytes                          *)
(***************************************************************************)

FractionalPriorDayCorrectedTrade ==
    [ saleConditions                : SaleConditions3,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime3 ]

EncodeFractionalPriorDayCorrectedTrade(message) ==
    EncodeSaleConditions3(message.saleConditions)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o EncodePriorDayTradeDateAndTime3(message.priorDayTradeDateAndTime)

DecodeFractionalPriorDayCorrectedTrade(bytes) ==
    LET saleConditions == DecodeSaleConditions3(bytes) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime3(shortSaleRestrictionIndicator.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         fractionalTradeVolume         |-> fractionalTradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroFractionalPriorDayCorrectedTrade ==
    [ saleConditions                |-> ZeroSaleConditions3,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime3 ]

(* Fractional Prior Day Corrected Trade at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayCorrectedTrade ==
    { ZeroFractionalPriorDayCorrectedTrade }
        \cup { [ZeroFractionalPriorDayCorrectedTrade EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions3 }
        \cup { [ZeroFractionalPriorDayCorrectedTrade EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayCorrectedTrade EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayCorrectedTrade EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayCorrectedTrade EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayCorrectedTrade EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayCorrectedTrade EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayCorrectedTrade EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime3 }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions4 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions4(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions4(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions4 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions4 ==
    { ZeroSaleConditions4 }
        \cup { [ZeroSaleConditions4 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions4 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions4 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions4 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date And Time: 8 bytes                                  *)
(***************************************************************************)

PriorDayTradeDateAndTime4 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodePriorDayTradeDateAndTime4(message) ==
    message.seconds
        \o message.nanoseconds

DecodePriorDayTradeDateAndTime4(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroPriorDayTradeDateAndTime4 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime4 ==
    { ZeroPriorDayTradeDateAndTime4 }
        \cup { [ZeroPriorDayTradeDateAndTime4 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime4 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Prior Day Original Trade: 32 bytes                           *)
(***************************************************************************)

FractionalPriorDayOriginalTrade ==
    [ saleConditions                : SaleConditions4,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime4 ]

EncodeFractionalPriorDayOriginalTrade(message) ==
    EncodeSaleConditions4(message.saleConditions)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o EncodePriorDayTradeDateAndTime4(message.priorDayTradeDateAndTime)

DecodeFractionalPriorDayOriginalTrade(bytes) ==
    LET saleConditions == DecodeSaleConditions4(bytes) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime4(shortSaleRestrictionIndicator.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         fractionalTradeVolume         |-> fractionalTradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroFractionalPriorDayOriginalTrade ==
    [ saleConditions                |-> ZeroSaleConditions4,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime4 ]

(* Fractional Prior Day Original Trade at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayOriginalTrade ==
    { ZeroFractionalPriorDayOriginalTrade }
        \cup { [ZeroFractionalPriorDayOriginalTrade EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions4 }
        \cup { [ZeroFractionalPriorDayOriginalTrade EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayOriginalTrade EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayOriginalTrade EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayOriginalTrade EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayOriginalTrade EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayOriginalTrade EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayOriginalTrade EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime4 }

(***************************************************************************)
(* Fractional Prior Day Trade Correction Message: 99 bytes                 *)
(***************************************************************************)

FractionalPriorDayTradeCorrectionMessage ==
    [ participantId                    : Sample(1),
      timestamp1                       : Timestamp119,
      messageId                        : Sample(1),
      transactionId                    : Sample(4),
      participantReferenceNumber       : Sample(8),
      securitySymbol                   : Sample(11),
      instrumentType                   : Sample(1),
      fractionalPriorDayCorrectedTrade : FractionalPriorDayCorrectedTrade,
      tradeReportingFacilityId         : Sample(1),
      fractionalPriorDayOriginalTrade  : FractionalPriorDayOriginalTrade ]

EncodeFractionalPriorDayTradeCorrectionMessage(message) ==
    message.participantId
        \o EncodeTimestamp119(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeFractionalPriorDayCorrectedTrade(message.fractionalPriorDayCorrectedTrade)
        \o message.tradeReportingFacilityId
        \o EncodeFractionalPriorDayOriginalTrade(message.fractionalPriorDayOriginalTrade)

DecodeFractionalPriorDayTradeCorrectionMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp119(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET fractionalPriorDayCorrectedTrade == DecodeFractionalPriorDayCorrectedTrade(instrumentType.rest) IN IF ~fractionalPriorDayCorrectedTrade.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(fractionalPriorDayCorrectedTrade.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET fractionalPriorDayOriginalTrade == DecodeFractionalPriorDayOriginalTrade(tradeReportingFacilityId.rest) IN IF ~fractionalPriorDayOriginalTrade.ok THEN Fail ELSE
    Ok([ participantId                    |-> participantId.value,
         timestamp1                       |-> timestamp1.value,
         messageId                        |-> messageId.value,
         transactionId                    |-> transactionId.value,
         participantReferenceNumber       |-> participantReferenceNumber.value,
         securitySymbol                   |-> securitySymbol.value,
         instrumentType                   |-> instrumentType.value,
         fractionalPriorDayCorrectedTrade |-> fractionalPriorDayCorrectedTrade.value,
         tradeReportingFacilityId         |-> tradeReportingFacilityId.value,
         fractionalPriorDayOriginalTrade  |-> fractionalPriorDayOriginalTrade.value ], fractionalPriorDayOriginalTrade.rest)

ZeroFractionalPriorDayTradeCorrectionMessage ==
    [ participantId                    |-> [i \in 1 .. 1 |-> 0],
      timestamp1                       |-> ZeroTimestamp119,
      messageId                        |-> [i \in 1 .. 1 |-> 0],
      transactionId                    |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber       |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                   |-> [i \in 1 .. 11 |-> 0],
      instrumentType                   |-> [i \in 1 .. 1 |-> 0],
      fractionalPriorDayCorrectedTrade |-> ZeroFractionalPriorDayCorrectedTrade,
      tradeReportingFacilityId         |-> [i \in 1 .. 1 |-> 0],
      fractionalPriorDayOriginalTrade  |-> ZeroFractionalPriorDayOriginalTrade ]

(* Fractional Prior Day Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeCorrectionMessage ==
    { ZeroFractionalPriorDayTradeCorrectionMessage }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp119 }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.fractionalPriorDayCorrectedTrade = one] : one \in CheckedFractionalPriorDayCorrectedTrade }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.fractionalPriorDayOriginalTrade = one] : one \in CheckedFractionalPriorDayOriginalTrade }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp120 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp120(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp120(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp120 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp120 ==
    { ZeroTimestamp120 }
        \cup { [ZeroTimestamp120 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp120 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions5 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions5(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions5(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions5 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions5 ==
    { ZeroSaleConditions5 }
        \cup { [ZeroSaleConditions5 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions5 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions5 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions5 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date And Time: 8 bytes                                  *)
(***************************************************************************)

PriorDayTradeDateAndTime5 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodePriorDayTradeDateAndTime5(message) ==
    message.seconds
        \o message.nanoseconds

DecodePriorDayTradeDateAndTime5(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroPriorDayTradeDateAndTime5 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime5 ==
    { ZeroPriorDayTradeDateAndTime5 }
        \cup { [ZeroPriorDayTradeDateAndTime5 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime5 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Prior Day Trade Message: 63 bytes                                       *)
(***************************************************************************)

PriorDayTradeMessage ==
    [ participantId                 : Sample(1),
      timestamp1                    : Timestamp120,
      messageId                     : Sample(1),
      transactionId                 : Sample(4),
      participantReferenceNumber    : Sample(8),
      securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleConditions                : SaleConditions5,
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime5 ]

EncodePriorDayTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp120(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleConditions5(message.saleConditions)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime5(message.priorDayTradeDateAndTime)

DecodePriorDayTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp120(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleConditions == DecodeSaleConditions5(instrumentType.rest) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime5(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         tradeVolume                   |-> tradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         tradeReportingFacilityId      |-> tradeReportingFacilityId.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroPriorDayTradeMessage ==
    [ participantId                 |-> [i \in 1 .. 1 |-> 0],
      timestamp1                    |-> ZeroTimestamp120,
      messageId                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                 |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber    |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleConditions                |-> ZeroSaleConditions5,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime5 ]

(* Prior Day Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeMessage ==
    { ZeroPriorDayTradeMessage }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp120 }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions5 }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime5 }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp121 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp121(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp121(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp121 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp121 ==
    { ZeroTimestamp121 }
        \cup { [ZeroTimestamp121 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp121 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions6 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions6(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions6(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions6 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions6 ==
    { ZeroSaleConditions6 }
        \cup { [ZeroSaleConditions6 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions6 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions6 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions6 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date And Time: 8 bytes                                  *)
(***************************************************************************)

PriorDayTradeDateAndTime6 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodePriorDayTradeDateAndTime6(message) ==
    message.seconds
        \o message.nanoseconds

DecodePriorDayTradeDateAndTime6(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroPriorDayTradeDateAndTime6 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime6 ==
    { ZeroPriorDayTradeDateAndTime6 }
        \cup { [ZeroPriorDayTradeDateAndTime6 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime6 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Prior Day Trade Message: 67 bytes                            *)
(***************************************************************************)

FractionalPriorDayTradeMessage ==
    [ participantId                 : Sample(1),
      timestamp1                    : Timestamp121,
      messageId                     : Sample(1),
      transactionId                 : Sample(4),
      participantReferenceNumber    : Sample(8),
      securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleConditions                : SaleConditions6,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime6 ]

EncodeFractionalPriorDayTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp121(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleConditions6(message.saleConditions)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime6(message.priorDayTradeDateAndTime)

DecodeFractionalPriorDayTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp121(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleConditions == DecodeSaleConditions6(instrumentType.rest) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime6(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         fractionalTradeVolume         |-> fractionalTradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         tradeReportingFacilityId      |-> tradeReportingFacilityId.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroFractionalPriorDayTradeMessage ==
    [ participantId                 |-> [i \in 1 .. 1 |-> 0],
      timestamp1                    |-> ZeroTimestamp121,
      messageId                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                 |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber    |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleConditions                |-> ZeroSaleConditions6,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime6 ]

(* Fractional Prior Day Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeMessage ==
    { ZeroFractionalPriorDayTradeMessage }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp121 }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions6 }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime6 }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp122 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp122(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp122(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp122 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp122 ==
    { ZeroTimestamp122 }
        \cup { [ZeroTimestamp122 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp122 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions7 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions7(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions7(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions7 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions7 ==
    { ZeroSaleConditions7 }
        \cup { [ZeroSaleConditions7 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions7 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions7 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions7 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date And Time: 8 bytes                                  *)
(***************************************************************************)

PriorDayTradeDateAndTime7 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodePriorDayTradeDateAndTime7(message) ==
    message.seconds
        \o message.nanoseconds

DecodePriorDayTradeDateAndTime7(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroPriorDayTradeDateAndTime7 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime7 ==
    { ZeroPriorDayTradeDateAndTime7 }
        \cup { [ZeroPriorDayTradeDateAndTime7 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime7 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Prior Day Trade Cancel Error Message: 64 bytes                          *)
(***************************************************************************)

PriorDayTradeCancelErrorMessage ==
    [ participantId                 : Sample(1),
      timestamp1                    : Timestamp122,
      messageId                     : Sample(1),
      transactionId                 : Sample(4),
      participantReferenceNumber    : Sample(8),
      securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleConditions                : SaleConditions7,
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime7,
      cancelErrorAction             : Sample(1) ]

EncodePriorDayTradeCancelErrorMessage(message) ==
    message.participantId
        \o EncodeTimestamp122(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleConditions7(message.saleConditions)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime7(message.priorDayTradeDateAndTime)
        \o message.cancelErrorAction

DecodePriorDayTradeCancelErrorMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp122(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleConditions == DecodeSaleConditions7(instrumentType.rest) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime7(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(priorDayTradeDateAndTime.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         tradeVolume                   |-> tradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         tradeReportingFacilityId      |-> tradeReportingFacilityId.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value,
         cancelErrorAction             |-> cancelErrorAction.value ], cancelErrorAction.rest)

ZeroPriorDayTradeCancelErrorMessage ==
    [ participantId                 |-> [i \in 1 .. 1 |-> 0],
      timestamp1                    |-> ZeroTimestamp122,
      messageId                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                 |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber    |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleConditions                |-> ZeroSaleConditions7,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime7,
      cancelErrorAction             |-> [i \in 1 .. 1 |-> 0] ]

(* Prior Day Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeCancelErrorMessage ==
    { ZeroPriorDayTradeCancelErrorMessage }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp122 }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions7 }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime7 }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp123 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp123(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp123(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp123 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp123 ==
    { ZeroTimestamp123 }
        \cup { [ZeroTimestamp123 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp123 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions8 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions8(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions8(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions8 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions8 ==
    { ZeroSaleConditions8 }
        \cup { [ZeroSaleConditions8 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions8 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions8 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions8 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date And Time: 8 bytes                                  *)
(***************************************************************************)

PriorDayTradeDateAndTime8 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodePriorDayTradeDateAndTime8(message) ==
    message.seconds
        \o message.nanoseconds

DecodePriorDayTradeDateAndTime8(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroPriorDayTradeDateAndTime8 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime8 ==
    { ZeroPriorDayTradeDateAndTime8 }
        \cup { [ZeroPriorDayTradeDateAndTime8 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime8 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Prior Day Trade Cancel Error Message: 68 bytes               *)
(***************************************************************************)

FractionalPriorDayTradeCancelErrorMessage ==
    [ participantId                 : Sample(1),
      timestamp1                    : Timestamp123,
      messageId                     : Sample(1),
      transactionId                 : Sample(4),
      participantReferenceNumber    : Sample(8),
      securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleConditions                : SaleConditions8,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime8,
      cancelErrorAction             : Sample(1) ]

EncodeFractionalPriorDayTradeCancelErrorMessage(message) ==
    message.participantId
        \o EncodeTimestamp123(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleConditions8(message.saleConditions)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime8(message.priorDayTradeDateAndTime)
        \o message.cancelErrorAction

DecodeFractionalPriorDayTradeCancelErrorMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp123(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleConditions == DecodeSaleConditions8(instrumentType.rest) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime8(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(priorDayTradeDateAndTime.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         fractionalTradeVolume         |-> fractionalTradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         tradeReportingFacilityId      |-> tradeReportingFacilityId.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value,
         cancelErrorAction             |-> cancelErrorAction.value ], cancelErrorAction.rest)

ZeroFractionalPriorDayTradeCancelErrorMessage ==
    [ participantId                 |-> [i \in 1 .. 1 |-> 0],
      timestamp1                    |-> ZeroTimestamp123,
      messageId                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                 |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber    |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleConditions                |-> ZeroSaleConditions8,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime8,
      cancelErrorAction             |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Prior Day Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeCancelErrorMessage ==
    { ZeroFractionalPriorDayTradeCancelErrorMessage }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp123 }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions8 }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime8 }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Message Payload, selected by Prior Day Message Type           *)
(***************************************************************************)

PriorDayTradeCorrectionMessageCode == 67  \* "C"
FractionalPriorDayTradeCorrectionMessageCode == 79  \* "O"
PriorDayTradeMessageCode == 84  \* "T"
FractionalPriorDayTradeMessageCode == 82  \* "R"
PriorDayTradeCancelErrorMessageCode == 88  \* "X"
FractionalPriorDayTradeCancelErrorMessageCode == 69  \* "E"

PriorDayMessagePayload ==
    [ tag : {PriorDayTradeCorrectionMessageCode}, body : PriorDayTradeCorrectionMessage ]
        \cup [ tag : {FractionalPriorDayTradeCorrectionMessageCode}, body : FractionalPriorDayTradeCorrectionMessage ]
        \cup [ tag : {PriorDayTradeMessageCode}, body : PriorDayTradeMessage ]
        \cup [ tag : {FractionalPriorDayTradeMessageCode}, body : FractionalPriorDayTradeMessage ]
        \cup [ tag : {PriorDayTradeCancelErrorMessageCode}, body : PriorDayTradeCancelErrorMessage ]
        \cup [ tag : {FractionalPriorDayTradeCancelErrorMessageCode}, body : FractionalPriorDayTradeCancelErrorMessage ]

EncodePriorDayMessagePayload(message) ==
    CASE message.tag = PriorDayTradeCorrectionMessageCode -> EncodePriorDayTradeCorrectionMessage(message.body)
      [] message.tag = FractionalPriorDayTradeCorrectionMessageCode -> EncodeFractionalPriorDayTradeCorrectionMessage(message.body)
      [] message.tag = PriorDayTradeMessageCode -> EncodePriorDayTradeMessage(message.body)
      [] message.tag = FractionalPriorDayTradeMessageCode -> EncodeFractionalPriorDayTradeMessage(message.body)
      [] message.tag = PriorDayTradeCancelErrorMessageCode -> EncodePriorDayTradeCancelErrorMessage(message.body)
      [] message.tag = FractionalPriorDayTradeCancelErrorMessageCode -> EncodeFractionalPriorDayTradeCancelErrorMessage(message.body)

DecodePriorDayMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = PriorDayTradeCorrectionMessageCode -> DecodePriorDayTradeCorrectionMessage(bytes)
              [] tag = FractionalPriorDayTradeCorrectionMessageCode -> DecodeFractionalPriorDayTradeCorrectionMessage(bytes)
              [] tag = PriorDayTradeMessageCode -> DecodePriorDayTradeMessage(bytes)
              [] tag = FractionalPriorDayTradeMessageCode -> DecodeFractionalPriorDayTradeMessage(bytes)
              [] tag = PriorDayTradeCancelErrorMessageCode -> DecodePriorDayTradeCancelErrorMessage(bytes)
              [] tag = FractionalPriorDayTradeCancelErrorMessageCode -> DecodeFractionalPriorDayTradeCancelErrorMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPriorDayMessagePayload == [tag |-> PriorDayTradeCorrectionMessageCode, body |-> ZeroPriorDayTradeCorrectionMessage]

(* Each Prior Day Message Payload in turn, at the values the message it names is checked at *)
CheckedPriorDayMessagePayload ==
    { [tag |-> PriorDayTradeCorrectionMessageCode, body |-> one] : one \in CheckedPriorDayTradeCorrectionMessage }
        \cup { [tag |-> FractionalPriorDayTradeCorrectionMessageCode, body |-> one] : one \in CheckedFractionalPriorDayTradeCorrectionMessage }
        \cup { [tag |-> PriorDayTradeMessageCode, body |-> one] : one \in CheckedPriorDayTradeMessage }
        \cup { [tag |-> FractionalPriorDayTradeMessageCode, body |-> one] : one \in CheckedFractionalPriorDayTradeMessage }
        \cup { [tag |-> PriorDayTradeCancelErrorMessageCode, body |-> one] : one \in CheckedPriorDayTradeCancelErrorMessage }
        \cup { [tag |-> FractionalPriorDayTradeCancelErrorMessageCode, body |-> one] : one \in CheckedFractionalPriorDayTradeCancelErrorMessage }

(***************************************************************************)
(* Prior Day Message                                                       *)
(***************************************************************************)

PriorDayMessage ==
    [ priorDayMessagePayload : PriorDayMessagePayload ]

EncodePriorDayMessage(message) ==
    EncodeUIntBE(message.priorDayMessagePayload.tag, 1)
        \o EncodePriorDayMessagePayload(message.priorDayMessagePayload)

DecodePriorDayMessage(bytes) ==
    LET priorDayMessageType == ReadUIntBE(bytes, 1) IN IF ~priorDayMessageType.ok THEN Fail ELSE
    LET priorDayMessagePayload == DecodePriorDayMessagePayload(priorDayMessageType.value, priorDayMessageType.rest) IN IF ~priorDayMessagePayload.ok THEN Fail ELSE
    Ok([ priorDayMessagePayload |-> priorDayMessagePayload.value ], priorDayMessagePayload.rest)

ZeroPriorDayMessage ==
    [ priorDayMessagePayload |-> ZeroPriorDayMessagePayload ]

(* Prior Day Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayMessage ==
    { ZeroPriorDayMessage }
        \cup { [ZeroPriorDayMessage EXCEPT !.priorDayMessagePayload = one] : one \in CheckedPriorDayMessagePayload }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp124 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp124(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp124(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp124 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp124 ==
    { ZeroTimestamp124 }
        \cup { [ZeroTimestamp124 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp124 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Consolidated Start Of Day Summary Message: 51 bytes                     *)
(***************************************************************************)

ConsolidatedStartOfDaySummaryMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp124,
      messageId                         : Sample(1),
      transactionId                     : Sample(4),
      participantReferenceNumber        : Sample(8),
      securitySymbol                    : Sample(11),
      instrumentType                    : Sample(1),
      summaryParticipantId              : Sample(1),
      previousClosePriceDate            : Sample(4),
      previousClosePrice                : Sample(8),
      shortSaleRestrictionIndicator     : Sample(1),
      primaryListingMarketParticipantId : Sample(1),
      financialStatusIndicator          : Sample(1),
      numberOfParticipants              : Sample(1) ]

EncodeConsolidatedStartOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp124(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.summaryParticipantId
        \o message.previousClosePriceDate
        \o message.previousClosePrice
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.numberOfParticipants

DecodeConsolidatedStartOfDaySummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp124(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET summaryParticipantId == ReadBytes(instrumentType.rest, 1) IN IF ~summaryParticipantId.ok THEN Fail ELSE
    LET previousClosePriceDate == ReadBytes(summaryParticipantId.rest, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET previousClosePrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~previousClosePrice.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(previousClosePrice.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET numberOfParticipants == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~numberOfParticipants.ok THEN Fail ELSE
    Ok([ participantId                     |-> participantId.value,
         timestamp1                        |-> timestamp1.value,
         messageId                         |-> messageId.value,
         transactionId                     |-> transactionId.value,
         participantReferenceNumber        |-> participantReferenceNumber.value,
         securitySymbol                    |-> securitySymbol.value,
         instrumentType                    |-> instrumentType.value,
         summaryParticipantId              |-> summaryParticipantId.value,
         previousClosePriceDate            |-> previousClosePriceDate.value,
         previousClosePrice                |-> previousClosePrice.value,
         shortSaleRestrictionIndicator     |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator          |-> financialStatusIndicator.value,
         numberOfParticipants              |-> numberOfParticipants.value ], numberOfParticipants.rest)

ZeroConsolidatedStartOfDaySummaryMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      timestamp1                        |-> ZeroTimestamp124,
      messageId                         |-> [i \in 1 .. 1 |-> 0],
      transactionId                     |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      instrumentType                    |-> [i \in 1 .. 1 |-> 0],
      summaryParticipantId              |-> [i \in 1 .. 1 |-> 0],
      previousClosePriceDate            |-> [i \in 1 .. 4 |-> 0],
      previousClosePrice                |-> [i \in 1 .. 8 |-> 0],
      shortSaleRestrictionIndicator     |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator          |-> [i \in 1 .. 1 |-> 0],
      numberOfParticipants              |-> [i \in 1 .. 1 |-> 0] ]

(* Consolidated Start Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedStartOfDaySummaryMessage ==
    { ZeroConsolidatedStartOfDaySummaryMessage }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp124 }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.summaryParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.previousClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.numberOfParticipants = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp125 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp125(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp125(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp125 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp125 ==
    { ZeroTimestamp125 }
        \cup { [ZeroTimestamp125 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp125 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Participant Start Of Day Summary Message: 47 bytes                      *)
(***************************************************************************)

ParticipantStartOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp125,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      securitySymbol             : Sample(11),
      instrumentType             : Sample(1),
      summaryParticipantId       : Sample(1),
      previousClosePriceDate     : Sample(4),
      previousClosePrice         : Sample(8) ]

EncodeParticipantStartOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp125(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.summaryParticipantId
        \o message.previousClosePriceDate
        \o message.previousClosePrice

DecodeParticipantStartOfDaySummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp125(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET summaryParticipantId == ReadBytes(instrumentType.rest, 1) IN IF ~summaryParticipantId.ok THEN Fail ELSE
    LET previousClosePriceDate == ReadBytes(summaryParticipantId.rest, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET previousClosePrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~previousClosePrice.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         securitySymbol             |-> securitySymbol.value,
         instrumentType             |-> instrumentType.value,
         summaryParticipantId       |-> summaryParticipantId.value,
         previousClosePriceDate     |-> previousClosePriceDate.value,
         previousClosePrice         |-> previousClosePrice.value ], previousClosePrice.rest)

ZeroParticipantStartOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp125,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      securitySymbol             |-> [i \in 1 .. 11 |-> 0],
      instrumentType             |-> [i \in 1 .. 1 |-> 0],
      summaryParticipantId       |-> [i \in 1 .. 1 |-> 0],
      previousClosePriceDate     |-> [i \in 1 .. 4 |-> 0],
      previousClosePrice         |-> [i \in 1 .. 8 |-> 0] ]

(* Participant Start Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedParticipantStartOfDaySummaryMessage ==
    { ZeroParticipantStartOfDaySummaryMessage }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp125 }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.summaryParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.previousClosePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp126 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp126(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp126(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp126 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp126 ==
    { ZeroTimestamp126 }
        \cup { [ZeroTimestamp126 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp126 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Consolidated End Of Day Summary Message: 75 bytes                       *)
(***************************************************************************)

ConsolidatedEndOfDaySummaryMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp126,
      messageId                         : Sample(1),
      transactionId                     : Sample(4),
      participantReferenceNumber        : Sample(8),
      securitySymbol                    : Sample(11),
      instrumentType                    : Sample(1),
      lastParticipantId                 : Sample(1),
      previousClosePriceDate            : Sample(4),
      lastPrice                         : Sample(8),
      highPrice                         : Sample(8),
      lowPrice                          : Sample(8),
      totalVolume                       : Sample(8),
      shortSaleRestrictionIndicator     : Sample(1),
      primaryListingMarketParticipantId : Sample(1),
      financialStatusIndicator          : Sample(1),
      numberOfParticipants              : Sample(1) ]

EncodeConsolidatedEndOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp126(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.lastParticipantId
        \o message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.totalVolume
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.numberOfParticipants

DecodeConsolidatedEndOfDaySummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp126(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET lastParticipantId == ReadBytes(instrumentType.rest, 1) IN IF ~lastParticipantId.ok THEN Fail ELSE
    LET previousClosePriceDate == ReadBytes(lastParticipantId.rest, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(lowPrice.rest, 8) IN IF ~totalVolume.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(totalVolume.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET numberOfParticipants == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~numberOfParticipants.ok THEN Fail ELSE
    Ok([ participantId                     |-> participantId.value,
         timestamp1                        |-> timestamp1.value,
         messageId                         |-> messageId.value,
         transactionId                     |-> transactionId.value,
         participantReferenceNumber        |-> participantReferenceNumber.value,
         securitySymbol                    |-> securitySymbol.value,
         instrumentType                    |-> instrumentType.value,
         lastParticipantId                 |-> lastParticipantId.value,
         previousClosePriceDate            |-> previousClosePriceDate.value,
         lastPrice                         |-> lastPrice.value,
         highPrice                         |-> highPrice.value,
         lowPrice                          |-> lowPrice.value,
         totalVolume                       |-> totalVolume.value,
         shortSaleRestrictionIndicator     |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator          |-> financialStatusIndicator.value,
         numberOfParticipants              |-> numberOfParticipants.value ], numberOfParticipants.rest)

ZeroConsolidatedEndOfDaySummaryMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      timestamp1                        |-> ZeroTimestamp126,
      messageId                         |-> [i \in 1 .. 1 |-> 0],
      transactionId                     |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      instrumentType                    |-> [i \in 1 .. 1 |-> 0],
      lastParticipantId                 |-> [i \in 1 .. 1 |-> 0],
      previousClosePriceDate            |-> [i \in 1 .. 4 |-> 0],
      lastPrice                         |-> [i \in 1 .. 8 |-> 0],
      highPrice                         |-> [i \in 1 .. 8 |-> 0],
      lowPrice                          |-> [i \in 1 .. 8 |-> 0],
      totalVolume                       |-> [i \in 1 .. 8 |-> 0],
      shortSaleRestrictionIndicator     |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator          |-> [i \in 1 .. 1 |-> 0],
      numberOfParticipants              |-> [i \in 1 .. 1 |-> 0] ]

(* Consolidated End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedEndOfDaySummaryMessage ==
    { ZeroConsolidatedEndOfDaySummaryMessage }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp126 }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.lastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.totalVolume = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.numberOfParticipants = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp127 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp127(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp127(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp127 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp127 ==
    { ZeroTimestamp127 }
        \cup { [ZeroTimestamp127 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp127 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Consolidated End Of Day Summary Message: 75 bytes            *)
(***************************************************************************)

FractionalConsolidatedEndOfDaySummaryMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp127,
      messageId                         : Sample(1),
      transactionId                     : Sample(4),
      participantReferenceNumber        : Sample(8),
      securitySymbol                    : Sample(11),
      instrumentType                    : Sample(1),
      lastParticipantId                 : Sample(1),
      previousClosePriceDate            : Sample(4),
      lastPrice                         : Sample(8),
      highPrice                         : Sample(8),
      lowPrice                          : Sample(8),
      fractionalTotalVolume             : Sample(8),
      shortSaleRestrictionIndicator     : Sample(1),
      primaryListingMarketParticipantId : Sample(1),
      financialStatusIndicator          : Sample(1),
      numberOfParticipants              : Sample(1) ]

EncodeFractionalConsolidatedEndOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp127(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.lastParticipantId
        \o message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.fractionalTotalVolume
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.numberOfParticipants

DecodeFractionalConsolidatedEndOfDaySummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp127(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET lastParticipantId == ReadBytes(instrumentType.rest, 1) IN IF ~lastParticipantId.ok THEN Fail ELSE
    LET previousClosePriceDate == ReadBytes(lastParticipantId.rest, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET fractionalTotalVolume == ReadBytes(lowPrice.rest, 8) IN IF ~fractionalTotalVolume.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(fractionalTotalVolume.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET numberOfParticipants == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~numberOfParticipants.ok THEN Fail ELSE
    Ok([ participantId                     |-> participantId.value,
         timestamp1                        |-> timestamp1.value,
         messageId                         |-> messageId.value,
         transactionId                     |-> transactionId.value,
         participantReferenceNumber        |-> participantReferenceNumber.value,
         securitySymbol                    |-> securitySymbol.value,
         instrumentType                    |-> instrumentType.value,
         lastParticipantId                 |-> lastParticipantId.value,
         previousClosePriceDate            |-> previousClosePriceDate.value,
         lastPrice                         |-> lastPrice.value,
         highPrice                         |-> highPrice.value,
         lowPrice                          |-> lowPrice.value,
         fractionalTotalVolume             |-> fractionalTotalVolume.value,
         shortSaleRestrictionIndicator     |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator          |-> financialStatusIndicator.value,
         numberOfParticipants              |-> numberOfParticipants.value ], numberOfParticipants.rest)

ZeroFractionalConsolidatedEndOfDaySummaryMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      timestamp1                        |-> ZeroTimestamp127,
      messageId                         |-> [i \in 1 .. 1 |-> 0],
      transactionId                     |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      instrumentType                    |-> [i \in 1 .. 1 |-> 0],
      lastParticipantId                 |-> [i \in 1 .. 1 |-> 0],
      previousClosePriceDate            |-> [i \in 1 .. 4 |-> 0],
      lastPrice                         |-> [i \in 1 .. 8 |-> 0],
      highPrice                         |-> [i \in 1 .. 8 |-> 0],
      lowPrice                          |-> [i \in 1 .. 8 |-> 0],
      fractionalTotalVolume             |-> [i \in 1 .. 8 |-> 0],
      shortSaleRestrictionIndicator     |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator          |-> [i \in 1 .. 1 |-> 0],
      numberOfParticipants              |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Consolidated End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalConsolidatedEndOfDaySummaryMessage ==
    { ZeroFractionalConsolidatedEndOfDaySummaryMessage }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp127 }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.lastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.fractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.numberOfParticipants = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp128 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp128(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp128(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp128 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp128 ==
    { ZeroTimestamp128 }
        \cup { [ZeroTimestamp128 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp128 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Participant End Of Day Summary Message: 80 bytes                        *)
(***************************************************************************)

ParticipantEndOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp128,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      securitySymbol             : Sample(11),
      instrumentType             : Sample(1),
      initiatingParticipantId    : Sample(1),
      previousClosePriceDate     : Sample(4),
      lastPrice                  : Sample(8),
      highPrice                  : Sample(8),
      lowPrice                   : Sample(8),
      openPrice                  : Sample(8),
      totalVolume                : Sample(8),
      tick                       : Sample(1) ]

EncodeParticipantEndOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp128(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.initiatingParticipantId
        \o message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.totalVolume
        \o message.tick

DecodeParticipantEndOfDaySummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp128(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET initiatingParticipantId == ReadBytes(instrumentType.rest, 1) IN IF ~initiatingParticipantId.ok THEN Fail ELSE
    LET previousClosePriceDate == ReadBytes(initiatingParticipantId.rest, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lowPrice.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(openPrice.rest, 8) IN IF ~totalVolume.ok THEN Fail ELSE
    LET tick == ReadBytes(totalVolume.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         securitySymbol             |-> securitySymbol.value,
         instrumentType             |-> instrumentType.value,
         initiatingParticipantId    |-> initiatingParticipantId.value,
         previousClosePriceDate     |-> previousClosePriceDate.value,
         lastPrice                  |-> lastPrice.value,
         highPrice                  |-> highPrice.value,
         lowPrice                   |-> lowPrice.value,
         openPrice                  |-> openPrice.value,
         totalVolume                |-> totalVolume.value,
         tick                       |-> tick.value ], tick.rest)

ZeroParticipantEndOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp128,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      securitySymbol             |-> [i \in 1 .. 11 |-> 0],
      instrumentType             |-> [i \in 1 .. 1 |-> 0],
      initiatingParticipantId    |-> [i \in 1 .. 1 |-> 0],
      previousClosePriceDate     |-> [i \in 1 .. 4 |-> 0],
      lastPrice                  |-> [i \in 1 .. 8 |-> 0],
      highPrice                  |-> [i \in 1 .. 8 |-> 0],
      lowPrice                   |-> [i \in 1 .. 8 |-> 0],
      openPrice                  |-> [i \in 1 .. 8 |-> 0],
      totalVolume                |-> [i \in 1 .. 8 |-> 0],
      tick                       |-> [i \in 1 .. 1 |-> 0] ]

(* Participant End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedParticipantEndOfDaySummaryMessage ==
    { ZeroParticipantEndOfDaySummaryMessage }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp128 }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.initiatingParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.totalVolume = one] : one \in Sample(8) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp129 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp129(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp129(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp129 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp129 ==
    { ZeroTimestamp129 }
        \cup { [ZeroTimestamp129 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp129 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Participant End Of Day Summary Message: 80 bytes             *)
(***************************************************************************)

FractionalParticipantEndOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp129,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      securitySymbol             : Sample(11),
      instrumentType             : Sample(1),
      initiatingParticipantId    : Sample(1),
      previousClosePriceDate     : Sample(4),
      lastPrice                  : Sample(8),
      highPrice                  : Sample(8),
      lowPrice                   : Sample(8),
      openPrice                  : Sample(8),
      fractionalTotalVolume      : Sample(8),
      tick                       : Sample(1) ]

EncodeFractionalParticipantEndOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp129(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.initiatingParticipantId
        \o message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.fractionalTotalVolume
        \o message.tick

DecodeFractionalParticipantEndOfDaySummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp129(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET initiatingParticipantId == ReadBytes(instrumentType.rest, 1) IN IF ~initiatingParticipantId.ok THEN Fail ELSE
    LET previousClosePriceDate == ReadBytes(initiatingParticipantId.rest, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lowPrice.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET fractionalTotalVolume == ReadBytes(openPrice.rest, 8) IN IF ~fractionalTotalVolume.ok THEN Fail ELSE
    LET tick == ReadBytes(fractionalTotalVolume.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         securitySymbol             |-> securitySymbol.value,
         instrumentType             |-> instrumentType.value,
         initiatingParticipantId    |-> initiatingParticipantId.value,
         previousClosePriceDate     |-> previousClosePriceDate.value,
         lastPrice                  |-> lastPrice.value,
         highPrice                  |-> highPrice.value,
         lowPrice                   |-> lowPrice.value,
         openPrice                  |-> openPrice.value,
         fractionalTotalVolume      |-> fractionalTotalVolume.value,
         tick                       |-> tick.value ], tick.rest)

ZeroFractionalParticipantEndOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp129,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      securitySymbol             |-> [i \in 1 .. 11 |-> 0],
      instrumentType             |-> [i \in 1 .. 1 |-> 0],
      initiatingParticipantId    |-> [i \in 1 .. 1 |-> 0],
      previousClosePriceDate     |-> [i \in 1 .. 4 |-> 0],
      lastPrice                  |-> [i \in 1 .. 8 |-> 0],
      highPrice                  |-> [i \in 1 .. 8 |-> 0],
      lowPrice                   |-> [i \in 1 .. 8 |-> 0],
      openPrice                  |-> [i \in 1 .. 8 |-> 0],
      fractionalTotalVolume      |-> [i \in 1 .. 8 |-> 0],
      tick                       |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Participant End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalParticipantEndOfDaySummaryMessage ==
    { ZeroFractionalParticipantEndOfDaySummaryMessage }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp129 }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.initiatingParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.fractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Summary Message Payload, selected by Summary Message Type               *)
(***************************************************************************)

ConsolidatedStartOfDaySummaryMessageCode == 65  \* "A"
ParticipantStartOfDaySummaryMessageCode == 66  \* "B"
ConsolidatedEndOfDaySummaryMessageCode == 67  \* "C"
FractionalConsolidatedEndOfDaySummaryMessageCode == 84  \* "T"
ParticipantEndOfDaySummaryMessageCode == 68  \* "D"
FractionalParticipantEndOfDaySummaryMessageCode == 80  \* "P"

SummaryMessagePayload ==
    [ tag : {ConsolidatedStartOfDaySummaryMessageCode}, body : ConsolidatedStartOfDaySummaryMessage ]
        \cup [ tag : {ParticipantStartOfDaySummaryMessageCode}, body : ParticipantStartOfDaySummaryMessage ]
        \cup [ tag : {ConsolidatedEndOfDaySummaryMessageCode}, body : ConsolidatedEndOfDaySummaryMessage ]
        \cup [ tag : {FractionalConsolidatedEndOfDaySummaryMessageCode}, body : FractionalConsolidatedEndOfDaySummaryMessage ]
        \cup [ tag : {ParticipantEndOfDaySummaryMessageCode}, body : ParticipantEndOfDaySummaryMessage ]
        \cup [ tag : {FractionalParticipantEndOfDaySummaryMessageCode}, body : FractionalParticipantEndOfDaySummaryMessage ]

EncodeSummaryMessagePayload(message) ==
    CASE message.tag = ConsolidatedStartOfDaySummaryMessageCode -> EncodeConsolidatedStartOfDaySummaryMessage(message.body)
      [] message.tag = ParticipantStartOfDaySummaryMessageCode -> EncodeParticipantStartOfDaySummaryMessage(message.body)
      [] message.tag = ConsolidatedEndOfDaySummaryMessageCode -> EncodeConsolidatedEndOfDaySummaryMessage(message.body)
      [] message.tag = FractionalConsolidatedEndOfDaySummaryMessageCode -> EncodeFractionalConsolidatedEndOfDaySummaryMessage(message.body)
      [] message.tag = ParticipantEndOfDaySummaryMessageCode -> EncodeParticipantEndOfDaySummaryMessage(message.body)
      [] message.tag = FractionalParticipantEndOfDaySummaryMessageCode -> EncodeFractionalParticipantEndOfDaySummaryMessage(message.body)

DecodeSummaryMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = ConsolidatedStartOfDaySummaryMessageCode -> DecodeConsolidatedStartOfDaySummaryMessage(bytes)
              [] tag = ParticipantStartOfDaySummaryMessageCode -> DecodeParticipantStartOfDaySummaryMessage(bytes)
              [] tag = ConsolidatedEndOfDaySummaryMessageCode -> DecodeConsolidatedEndOfDaySummaryMessage(bytes)
              [] tag = FractionalConsolidatedEndOfDaySummaryMessageCode -> DecodeFractionalConsolidatedEndOfDaySummaryMessage(bytes)
              [] tag = ParticipantEndOfDaySummaryMessageCode -> DecodeParticipantEndOfDaySummaryMessage(bytes)
              [] tag = FractionalParticipantEndOfDaySummaryMessageCode -> DecodeFractionalParticipantEndOfDaySummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSummaryMessagePayload == [tag |-> ConsolidatedStartOfDaySummaryMessageCode, body |-> ZeroConsolidatedStartOfDaySummaryMessage]

(* Each Summary Message Payload in turn, at the values the message it names is checked at *)
CheckedSummaryMessagePayload ==
    { [tag |-> ConsolidatedStartOfDaySummaryMessageCode, body |-> one] : one \in CheckedConsolidatedStartOfDaySummaryMessage }
        \cup { [tag |-> ParticipantStartOfDaySummaryMessageCode, body |-> one] : one \in CheckedParticipantStartOfDaySummaryMessage }
        \cup { [tag |-> ConsolidatedEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedConsolidatedEndOfDaySummaryMessage }
        \cup { [tag |-> FractionalConsolidatedEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedFractionalConsolidatedEndOfDaySummaryMessage }
        \cup { [tag |-> ParticipantEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedParticipantEndOfDaySummaryMessage }
        \cup { [tag |-> FractionalParticipantEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedFractionalParticipantEndOfDaySummaryMessage }

(***************************************************************************)
(* Summary Message                                                         *)
(***************************************************************************)

SummaryMessage ==
    [ summaryMessagePayload : SummaryMessagePayload ]

EncodeSummaryMessage(message) ==
    EncodeUIntBE(message.summaryMessagePayload.tag, 1)
        \o EncodeSummaryMessagePayload(message.summaryMessagePayload)

DecodeSummaryMessage(bytes) ==
    LET summaryMessageType == ReadUIntBE(bytes, 1) IN IF ~summaryMessageType.ok THEN Fail ELSE
    LET summaryMessagePayload == DecodeSummaryMessagePayload(summaryMessageType.value, summaryMessageType.rest) IN IF ~summaryMessagePayload.ok THEN Fail ELSE
    Ok([ summaryMessagePayload |-> summaryMessagePayload.value ], summaryMessagePayload.rest)

ZeroSummaryMessage ==
    [ summaryMessagePayload |-> ZeroSummaryMessagePayload ]

(* Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedSummaryMessage ==
    { ZeroSummaryMessage }
        \cup { [ZeroSummaryMessage EXCEPT !.summaryMessagePayload = one] : one \in CheckedSummaryMessagePayload }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp130 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp130(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp130(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp130 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp130 ==
    { ZeroTimestamp130 }
        \cup { [ZeroTimestamp130 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp130 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Status Message: 124 bytes                                       *)
(***************************************************************************)

AuctionStatusMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp130,
      messageId                         : Sample(1),
      transactionId                     : Sample(4),
      participantReferenceNumber        : Sample(8),
      securitySymbol                    : Sample(11),
      instrumentType                    : Sample(1),
      auctionCollarReferencePrice       : Sample(8),
      auctionCollarUpperThresholdPrice  : Sample(8),
      auctionCollarLowerThresholdPrice  : Sample(8),
      numberOfExtensions                : Sample(1),
      shortSaleRestrictionIndicator     : Sample(1),
      primaryListingMarketParticipantId : Sample(1),
      financialStatusIndicator          : Sample(1),
      futureUse                         : Sample(62) ]

EncodeAuctionStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp130(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.auctionCollarReferencePrice
        \o message.auctionCollarUpperThresholdPrice
        \o message.auctionCollarLowerThresholdPrice
        \o message.numberOfExtensions
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.futureUse

DecodeAuctionStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp130(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET auctionCollarReferencePrice == ReadBytes(instrumentType.rest, 8) IN IF ~auctionCollarReferencePrice.ok THEN Fail ELSE
    LET auctionCollarUpperThresholdPrice == ReadBytes(auctionCollarReferencePrice.rest, 8) IN IF ~auctionCollarUpperThresholdPrice.ok THEN Fail ELSE
    LET auctionCollarLowerThresholdPrice == ReadBytes(auctionCollarUpperThresholdPrice.rest, 8) IN IF ~auctionCollarLowerThresholdPrice.ok THEN Fail ELSE
    LET numberOfExtensions == ReadBytes(auctionCollarLowerThresholdPrice.rest, 1) IN IF ~numberOfExtensions.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(numberOfExtensions.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET futureUse == ReadBytes(financialStatusIndicator.rest, 62) IN IF ~futureUse.ok THEN Fail ELSE
    Ok([ participantId                     |-> participantId.value,
         timestamp1                        |-> timestamp1.value,
         messageId                         |-> messageId.value,
         transactionId                     |-> transactionId.value,
         participantReferenceNumber        |-> participantReferenceNumber.value,
         securitySymbol                    |-> securitySymbol.value,
         instrumentType                    |-> instrumentType.value,
         auctionCollarReferencePrice       |-> auctionCollarReferencePrice.value,
         auctionCollarUpperThresholdPrice  |-> auctionCollarUpperThresholdPrice.value,
         auctionCollarLowerThresholdPrice  |-> auctionCollarLowerThresholdPrice.value,
         numberOfExtensions                |-> numberOfExtensions.value,
         shortSaleRestrictionIndicator     |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator          |-> financialStatusIndicator.value,
         futureUse                         |-> futureUse.value ], futureUse.rest)

ZeroAuctionStatusMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      timestamp1                        |-> ZeroTimestamp130,
      messageId                         |-> [i \in 1 .. 1 |-> 0],
      transactionId                     |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      instrumentType                    |-> [i \in 1 .. 1 |-> 0],
      auctionCollarReferencePrice       |-> [i \in 1 .. 8 |-> 0],
      auctionCollarUpperThresholdPrice  |-> [i \in 1 .. 8 |-> 0],
      auctionCollarLowerThresholdPrice  |-> [i \in 1 .. 8 |-> 0],
      numberOfExtensions                |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator     |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator          |-> [i \in 1 .. 1 |-> 0],
      futureUse                         |-> [i \in 1 .. 62 |-> 0] ]

(* Auction Status Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionStatusMessage ==
    { ZeroAuctionStatusMessage }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp130 }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarUpperThresholdPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarLowerThresholdPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.numberOfExtensions = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.futureUse = one] : one \in Sample(62) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp131 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp131(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp131(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp131 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp131 ==
    { ZeroTimestamp131 }
        \cup { [ZeroTimestamp131 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp131 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions9 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions9(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions9(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions9 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions9 ==
    { ZeroSaleConditions9 }
        \cup { [ZeroSaleConditions9 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions9 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions9 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions9 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Corrected Trade: 20 bytes                                               *)
(***************************************************************************)

CorrectedTrade ==
    [ saleConditions                : SaleConditions9,
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1) ]

EncodeCorrectedTrade(message) ==
    EncodeSaleConditions9(message.saleConditions)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator

DecodeCorrectedTrade(bytes) ==
    LET saleConditions == DecodeSaleConditions9(bytes) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    Ok([ saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         tradeVolume                   |-> tradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value ], shortSaleRestrictionIndicator.rest)

ZeroCorrectedTrade ==
    [ saleConditions                |-> ZeroSaleConditions9,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Corrected Trade at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedTrade ==
    { ZeroCorrectedTrade }
        \cup { [ZeroCorrectedTrade EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions9 }
        \cup { [ZeroCorrectedTrade EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTrade EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedTrade EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTrade EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTrade EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedTrade EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp2 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp2(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp2(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp2 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp2 ==
    { ZeroTimestamp2 }
        \cup { [ZeroTimestamp2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions10 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions10(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions10(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions10 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions10 ==
    { ZeroSaleConditions10 }
        \cup { [ZeroSaleConditions10 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions10 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions10 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions10 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Original Trade: 20 bytes                                                *)
(***************************************************************************)

OriginalTrade ==
    [ saleConditions                : SaleConditions10,
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1) ]

EncodeOriginalTrade(message) ==
    EncodeSaleConditions10(message.saleConditions)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator

DecodeOriginalTrade(bytes) ==
    LET saleConditions == DecodeSaleConditions10(bytes) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    Ok([ saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         tradeVolume                   |-> tradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value ], shortSaleRestrictionIndicator.rest)

ZeroOriginalTrade ==
    [ saleConditions                |-> ZeroSaleConditions10,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Original Trade at zero, then each field in turn at the values it is checked at *)
CheckedOriginalTrade ==
    { ZeroOriginalTrade }
        \cup { [ZeroOriginalTrade EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions10 }
        \cup { [ZeroOriginalTrade EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroOriginalTrade EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroOriginalTrade EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTrade EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTrade EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOriginalTrade EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Consolidated Data: 34 bytes                                             *)
(***************************************************************************)

ConsolidatedData ==
    [ previousClosePriceDate : Sample(4),
      lastParticipantId      : Sample(1),
      lastPrice              : Sample(8),
      highPrice              : Sample(8),
      lowPrice               : Sample(8),
      totalVolumeShort       : Sample(4),
      tick                   : Sample(1) ]

EncodeConsolidatedData(message) ==
    message.previousClosePriceDate
        \o message.lastParticipantId
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.totalVolumeShort
        \o message.tick

DecodeConsolidatedData(bytes) ==
    LET previousClosePriceDate == ReadBytes(bytes, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastParticipantId == ReadBytes(previousClosePriceDate.rest, 1) IN IF ~lastParticipantId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lastParticipantId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET totalVolumeShort == ReadBytes(lowPrice.rest, 4) IN IF ~totalVolumeShort.ok THEN Fail ELSE
    LET tick == ReadBytes(totalVolumeShort.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ previousClosePriceDate |-> previousClosePriceDate.value,
         lastParticipantId      |-> lastParticipantId.value,
         lastPrice              |-> lastPrice.value,
         highPrice              |-> highPrice.value,
         lowPrice               |-> lowPrice.value,
         totalVolumeShort       |-> totalVolumeShort.value,
         tick                   |-> tick.value ], tick.rest)

ZeroConsolidatedData ==
    [ previousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      lastParticipantId      |-> [i \in 1 .. 1 |-> 0],
      lastPrice              |-> [i \in 1 .. 8 |-> 0],
      highPrice              |-> [i \in 1 .. 8 |-> 0],
      lowPrice               |-> [i \in 1 .. 8 |-> 0],
      totalVolumeShort       |-> [i \in 1 .. 4 |-> 0],
      tick                   |-> [i \in 1 .. 1 |-> 0] ]

(* Consolidated Data at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedData ==
    { ZeroConsolidatedData }
        \cup { [ZeroConsolidatedData EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedData EXCEPT !.lastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedData EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedData EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedData EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedData EXCEPT !.totalVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedData EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Participant Data: 41 bytes                                              *)
(***************************************************************************)

ParticipantData ==
    [ previousClosePriceDate : Sample(4),
      lastPrice              : Sample(8),
      highPrice              : Sample(8),
      lowPrice               : Sample(8),
      openPrice              : Sample(8),
      totalVolumeShort       : Sample(4),
      tick                   : Sample(1) ]

EncodeParticipantData(message) ==
    message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.totalVolumeShort
        \o message.tick

DecodeParticipantData(bytes) ==
    LET previousClosePriceDate == ReadBytes(bytes, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lowPrice.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET totalVolumeShort == ReadBytes(openPrice.rest, 4) IN IF ~totalVolumeShort.ok THEN Fail ELSE
    LET tick == ReadBytes(totalVolumeShort.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ previousClosePriceDate |-> previousClosePriceDate.value,
         lastPrice              |-> lastPrice.value,
         highPrice              |-> highPrice.value,
         lowPrice               |-> lowPrice.value,
         openPrice              |-> openPrice.value,
         totalVolumeShort       |-> totalVolumeShort.value,
         tick                   |-> tick.value ], tick.rest)

ZeroParticipantData ==
    [ previousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      lastPrice              |-> [i \in 1 .. 8 |-> 0],
      highPrice              |-> [i \in 1 .. 8 |-> 0],
      lowPrice               |-> [i \in 1 .. 8 |-> 0],
      openPrice              |-> [i \in 1 .. 8 |-> 0],
      totalVolumeShort       |-> [i \in 1 .. 4 |-> 0],
      tick                   |-> [i \in 1 .. 1 |-> 0] ]

(* Participant Data at zero, then each field in turn at the values it is checked at *)
CheckedParticipantData ==
    { ZeroParticipantData }
        \cup { [ZeroParticipantData EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroParticipantData EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantData EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantData EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantData EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantData EXCEPT !.totalVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroParticipantData EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correction Message: 168 bytes                                     *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ participantId                      : Sample(1),
      timestamp1                         : Timestamp131,
      messageId                          : Sample(1),
      transactionId                      : Sample(4),
      participantReferenceNumber         : Sample(8),
      securitySymbol                     : Sample(11),
      instrumentType                     : Sample(1),
      correctedTrade                     : CorrectedTrade,
      tradeReportingFacilityId           : Sample(1),
      timestamp2                         : Timestamp2,
      originalParticipantReferenceNumber : Sample(8),
      originalTrade                      : OriginalTrade,
      primaryListingMarketParticipantId  : Sample(1),
      financialStatusIndicator           : Sample(1),
      consolidatedData                   : ConsolidatedData,
      participantData                    : ParticipantData ]

EncodeTradeCorrectionMessage(message) ==
    message.participantId
        \o EncodeTimestamp131(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeCorrectedTrade(message.correctedTrade)
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp2(message.timestamp2)
        \o message.originalParticipantReferenceNumber
        \o EncodeOriginalTrade(message.originalTrade)
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o EncodeConsolidatedData(message.consolidatedData)
        \o EncodeParticipantData(message.participantData)

DecodeTradeCorrectionMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp131(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET correctedTrade == DecodeCorrectedTrade(instrumentType.rest) IN IF ~correctedTrade.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(correctedTrade.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp2(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(timestamp2.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    LET originalTrade == DecodeOriginalTrade(originalParticipantReferenceNumber.rest) IN IF ~originalTrade.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(originalTrade.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET consolidatedData == DecodeConsolidatedData(financialStatusIndicator.rest) IN IF ~consolidatedData.ok THEN Fail ELSE
    LET participantData == DecodeParticipantData(consolidatedData.rest) IN IF ~participantData.ok THEN Fail ELSE
    Ok([ participantId                      |-> participantId.value,
         timestamp1                         |-> timestamp1.value,
         messageId                          |-> messageId.value,
         transactionId                      |-> transactionId.value,
         participantReferenceNumber         |-> participantReferenceNumber.value,
         securitySymbol                     |-> securitySymbol.value,
         instrumentType                     |-> instrumentType.value,
         correctedTrade                     |-> correctedTrade.value,
         tradeReportingFacilityId           |-> tradeReportingFacilityId.value,
         timestamp2                         |-> timestamp2.value,
         originalParticipantReferenceNumber |-> originalParticipantReferenceNumber.value,
         originalTrade                      |-> originalTrade.value,
         primaryListingMarketParticipantId  |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator           |-> financialStatusIndicator.value,
         consolidatedData                   |-> consolidatedData.value,
         participantData                    |-> participantData.value ], participantData.rest)

ZeroTradeCorrectionMessage ==
    [ participantId                      |-> [i \in 1 .. 1 |-> 0],
      timestamp1                         |-> ZeroTimestamp131,
      messageId                          |-> [i \in 1 .. 1 |-> 0],
      transactionId                      |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                     |-> [i \in 1 .. 11 |-> 0],
      instrumentType                     |-> [i \in 1 .. 1 |-> 0],
      correctedTrade                     |-> ZeroCorrectedTrade,
      tradeReportingFacilityId           |-> [i \in 1 .. 1 |-> 0],
      timestamp2                         |-> ZeroTimestamp2,
      originalParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      originalTrade                      |-> ZeroOriginalTrade,
      primaryListingMarketParticipantId  |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator           |-> [i \in 1 .. 1 |-> 0],
      consolidatedData                   |-> ZeroConsolidatedData,
      participantData                    |-> ZeroParticipantData ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp131 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTrade = one] : one \in CheckedCorrectedTrade }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp2 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTrade = one] : one \in CheckedOriginalTrade }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedData = one] : one \in CheckedConsolidatedData }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantData = one] : one \in CheckedParticipantData }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp132 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp132(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp132(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp132 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp132 ==
    { ZeroTimestamp132 }
        \cup { [ZeroTimestamp132 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp132 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions11 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions11(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions11(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions11 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions11 ==
    { ZeroSaleConditions11 }
        \cup { [ZeroSaleConditions11 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions11 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions11 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions11 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Corrected Trade: 24 bytes                                    *)
(***************************************************************************)

FractionalCorrectedTrade ==
    [ saleConditions                : SaleConditions11,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1) ]

EncodeFractionalCorrectedTrade(message) ==
    EncodeSaleConditions11(message.saleConditions)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator

DecodeFractionalCorrectedTrade(bytes) ==
    LET saleConditions == DecodeSaleConditions11(bytes) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    Ok([ saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         fractionalTradeVolume         |-> fractionalTradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value ], shortSaleRestrictionIndicator.rest)

ZeroFractionalCorrectedTrade ==
    [ saleConditions                |-> ZeroSaleConditions11,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Corrected Trade at zero, then each field in turn at the values it is checked at *)
CheckedFractionalCorrectedTrade ==
    { ZeroFractionalCorrectedTrade }
        \cup { [ZeroFractionalCorrectedTrade EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions11 }
        \cup { [ZeroFractionalCorrectedTrade EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalCorrectedTrade EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalCorrectedTrade EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalCorrectedTrade EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalCorrectedTrade EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalCorrectedTrade EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp22 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp22(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp22(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp22 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp22 ==
    { ZeroTimestamp22 }
        \cup { [ZeroTimestamp22 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp22 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions12 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions12(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions12(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions12 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions12 ==
    { ZeroSaleConditions12 }
        \cup { [ZeroSaleConditions12 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions12 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions12 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions12 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Original Trade: 24 bytes                                     *)
(***************************************************************************)

FractionalOriginalTrade ==
    [ saleConditions                : SaleConditions12,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1) ]

EncodeFractionalOriginalTrade(message) ==
    EncodeSaleConditions12(message.saleConditions)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator

DecodeFractionalOriginalTrade(bytes) ==
    LET saleConditions == DecodeSaleConditions12(bytes) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    Ok([ saleConditions                |-> saleConditions.value,
         tradePrice                    |-> tradePrice.value,
         fractionalTradeVolume         |-> fractionalTradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value ], shortSaleRestrictionIndicator.rest)

ZeroFractionalOriginalTrade ==
    [ saleConditions                |-> ZeroSaleConditions12,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Original Trade at zero, then each field in turn at the values it is checked at *)
CheckedFractionalOriginalTrade ==
    { ZeroFractionalOriginalTrade }
        \cup { [ZeroFractionalOriginalTrade EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions12 }
        \cup { [ZeroFractionalOriginalTrade EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalOriginalTrade EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalOriginalTrade EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalOriginalTrade EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalOriginalTrade EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalOriginalTrade EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Consolidated Data: 38 bytes                                  *)
(***************************************************************************)

FractionalConsolidatedData ==
    [ previousClosePriceDate : Sample(4),
      lastParticipantId      : Sample(1),
      lastPrice              : Sample(8),
      highPrice              : Sample(8),
      lowPrice               : Sample(8),
      fractionalTotalVolume  : Sample(8),
      tick                   : Sample(1) ]

EncodeFractionalConsolidatedData(message) ==
    message.previousClosePriceDate
        \o message.lastParticipantId
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.fractionalTotalVolume
        \o message.tick

DecodeFractionalConsolidatedData(bytes) ==
    LET previousClosePriceDate == ReadBytes(bytes, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastParticipantId == ReadBytes(previousClosePriceDate.rest, 1) IN IF ~lastParticipantId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lastParticipantId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET fractionalTotalVolume == ReadBytes(lowPrice.rest, 8) IN IF ~fractionalTotalVolume.ok THEN Fail ELSE
    LET tick == ReadBytes(fractionalTotalVolume.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ previousClosePriceDate |-> previousClosePriceDate.value,
         lastParticipantId      |-> lastParticipantId.value,
         lastPrice              |-> lastPrice.value,
         highPrice              |-> highPrice.value,
         lowPrice               |-> lowPrice.value,
         fractionalTotalVolume  |-> fractionalTotalVolume.value,
         tick                   |-> tick.value ], tick.rest)

ZeroFractionalConsolidatedData ==
    [ previousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      lastParticipantId      |-> [i \in 1 .. 1 |-> 0],
      lastPrice              |-> [i \in 1 .. 8 |-> 0],
      highPrice              |-> [i \in 1 .. 8 |-> 0],
      lowPrice               |-> [i \in 1 .. 8 |-> 0],
      fractionalTotalVolume  |-> [i \in 1 .. 8 |-> 0],
      tick                   |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Consolidated Data at zero, then each field in turn at the values it is checked at *)
CheckedFractionalConsolidatedData ==
    { ZeroFractionalConsolidatedData }
        \cup { [ZeroFractionalConsolidatedData EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalConsolidatedData EXCEPT !.lastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedData EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedData EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedData EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedData EXCEPT !.fractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedData EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Participant Data: 45 bytes                                   *)
(***************************************************************************)

FractionalParticipantData ==
    [ previousClosePriceDate : Sample(4),
      lastPrice              : Sample(8),
      highPrice              : Sample(8),
      lowPrice               : Sample(8),
      openPrice              : Sample(8),
      fractionalTotalVolume  : Sample(8),
      tick                   : Sample(1) ]

EncodeFractionalParticipantData(message) ==
    message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.fractionalTotalVolume
        \o message.tick

DecodeFractionalParticipantData(bytes) ==
    LET previousClosePriceDate == ReadBytes(bytes, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lowPrice.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET fractionalTotalVolume == ReadBytes(openPrice.rest, 8) IN IF ~fractionalTotalVolume.ok THEN Fail ELSE
    LET tick == ReadBytes(fractionalTotalVolume.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ previousClosePriceDate |-> previousClosePriceDate.value,
         lastPrice              |-> lastPrice.value,
         highPrice              |-> highPrice.value,
         lowPrice               |-> lowPrice.value,
         openPrice              |-> openPrice.value,
         fractionalTotalVolume  |-> fractionalTotalVolume.value,
         tick                   |-> tick.value ], tick.rest)

ZeroFractionalParticipantData ==
    [ previousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      lastPrice              |-> [i \in 1 .. 8 |-> 0],
      highPrice              |-> [i \in 1 .. 8 |-> 0],
      lowPrice               |-> [i \in 1 .. 8 |-> 0],
      openPrice              |-> [i \in 1 .. 8 |-> 0],
      fractionalTotalVolume  |-> [i \in 1 .. 8 |-> 0],
      tick                   |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Participant Data at zero, then each field in turn at the values it is checked at *)
CheckedFractionalParticipantData ==
    { ZeroFractionalParticipantData }
        \cup { [ZeroFractionalParticipantData EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalParticipantData EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData EXCEPT !.fractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Trade Correction Message: 184 bytes                          *)
(***************************************************************************)

FractionalTradeCorrectionMessage ==
    [ participantId                      : Sample(1),
      timestamp1                         : Timestamp132,
      messageId                          : Sample(1),
      transactionId                      : Sample(4),
      participantReferenceNumber         : Sample(8),
      securitySymbol                     : Sample(11),
      instrumentType                     : Sample(1),
      fractionalCorrectedTrade           : FractionalCorrectedTrade,
      tradeReportingFacilityId           : Sample(1),
      timestamp2                         : Timestamp22,
      originalParticipantReferenceNumber : Sample(8),
      fractionalOriginalTrade            : FractionalOriginalTrade,
      primaryListingMarketParticipantId  : Sample(1),
      financialStatusIndicator           : Sample(1),
      fractionalConsolidatedData         : FractionalConsolidatedData,
      fractionalParticipantData          : FractionalParticipantData ]

EncodeFractionalTradeCorrectionMessage(message) ==
    message.participantId
        \o EncodeTimestamp132(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeFractionalCorrectedTrade(message.fractionalCorrectedTrade)
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp22(message.timestamp2)
        \o message.originalParticipantReferenceNumber
        \o EncodeFractionalOriginalTrade(message.fractionalOriginalTrade)
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o EncodeFractionalConsolidatedData(message.fractionalConsolidatedData)
        \o EncodeFractionalParticipantData(message.fractionalParticipantData)

DecodeFractionalTradeCorrectionMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp132(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET fractionalCorrectedTrade == DecodeFractionalCorrectedTrade(instrumentType.rest) IN IF ~fractionalCorrectedTrade.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(fractionalCorrectedTrade.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp22(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(timestamp2.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    LET fractionalOriginalTrade == DecodeFractionalOriginalTrade(originalParticipantReferenceNumber.rest) IN IF ~fractionalOriginalTrade.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(fractionalOriginalTrade.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET fractionalConsolidatedData == DecodeFractionalConsolidatedData(financialStatusIndicator.rest) IN IF ~fractionalConsolidatedData.ok THEN Fail ELSE
    LET fractionalParticipantData == DecodeFractionalParticipantData(fractionalConsolidatedData.rest) IN IF ~fractionalParticipantData.ok THEN Fail ELSE
    Ok([ participantId                      |-> participantId.value,
         timestamp1                         |-> timestamp1.value,
         messageId                          |-> messageId.value,
         transactionId                      |-> transactionId.value,
         participantReferenceNumber         |-> participantReferenceNumber.value,
         securitySymbol                     |-> securitySymbol.value,
         instrumentType                     |-> instrumentType.value,
         fractionalCorrectedTrade           |-> fractionalCorrectedTrade.value,
         tradeReportingFacilityId           |-> tradeReportingFacilityId.value,
         timestamp2                         |-> timestamp2.value,
         originalParticipantReferenceNumber |-> originalParticipantReferenceNumber.value,
         fractionalOriginalTrade            |-> fractionalOriginalTrade.value,
         primaryListingMarketParticipantId  |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator           |-> financialStatusIndicator.value,
         fractionalConsolidatedData         |-> fractionalConsolidatedData.value,
         fractionalParticipantData          |-> fractionalParticipantData.value ], fractionalParticipantData.rest)

ZeroFractionalTradeCorrectionMessage ==
    [ participantId                      |-> [i \in 1 .. 1 |-> 0],
      timestamp1                         |-> ZeroTimestamp132,
      messageId                          |-> [i \in 1 .. 1 |-> 0],
      transactionId                      |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                     |-> [i \in 1 .. 11 |-> 0],
      instrumentType                     |-> [i \in 1 .. 1 |-> 0],
      fractionalCorrectedTrade           |-> ZeroFractionalCorrectedTrade,
      tradeReportingFacilityId           |-> [i \in 1 .. 1 |-> 0],
      timestamp2                         |-> ZeroTimestamp22,
      originalParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      fractionalOriginalTrade            |-> ZeroFractionalOriginalTrade,
      primaryListingMarketParticipantId  |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator           |-> [i \in 1 .. 1 |-> 0],
      fractionalConsolidatedData         |-> ZeroFractionalConsolidatedData,
      fractionalParticipantData          |-> ZeroFractionalParticipantData ]

(* Fractional Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCorrectionMessage ==
    { ZeroFractionalTradeCorrectionMessage }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp132 }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.fractionalCorrectedTrade = one] : one \in CheckedFractionalCorrectedTrade }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp22 }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.fractionalOriginalTrade = one] : one \in CheckedFractionalOriginalTrade }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.fractionalConsolidatedData = one] : one \in CheckedFractionalConsolidatedData }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.fractionalParticipantData = one] : one \in CheckedFractionalParticipantData }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp133 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp133(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp133(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp133 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp133 ==
    { ZeroTimestamp133 }
        \cup { [ZeroTimestamp133 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp133 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions13 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions13(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions13(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions13 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions13 ==
    { ZeroSaleConditions13 }
        \cup { [ZeroSaleConditions13 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions13 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions13 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions13 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp23 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp23(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp23(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp23 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp23 ==
    { ZeroTimestamp23 }
        \cup { [ZeroTimestamp23 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp23 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Long Trade Message: 68 bytes                                            *)
(***************************************************************************)

LongTradeMessage ==
    [ participantId                       : Sample(1),
      timestamp1                          : Timestamp133,
      messageId                           : Sample(1),
      transactionId                       : Sample(4),
      participantReferenceNumber          : Sample(8),
      securitySymbol                      : Sample(11),
      instrumentType                      : Sample(1),
      saleConditions                      : SaleConditions13,
      tradePrice                          : Sample(8),
      tradeVolume                         : Sample(4),
      sellersSaleDays                     : Sample(1),
      stopStockIndicator                  : Sample(1),
      tradeThroughExemptIndicator         : Sample(1),
      tradeReportingFacilityId            : Sample(1),
      timestamp2                          : Timestamp23,
      shortSaleRestrictionIndicator       : Sample(1),
      primaryListingMarketParticipantId   : Sample(1),
      financialStatusIndicator            : Sample(1),
      heldTradeIndicator                  : Sample(1),
      consolidatedHighLowLastIndicator    : Sample(1),
      participantOpenHighLowLastIndicator : Sample(1) ]

EncodeLongTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp133(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleConditions13(message.saleConditions)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp23(message.timestamp2)
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.heldTradeIndicator
        \o message.consolidatedHighLowLastIndicator
        \o message.participantOpenHighLowLastIndicator

DecodeLongTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp133(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleConditions == DecodeSaleConditions13(instrumentType.rest) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp23(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(timestamp2.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET heldTradeIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~heldTradeIndicator.ok THEN Fail ELSE
    LET consolidatedHighLowLastIndicator == ReadBytes(heldTradeIndicator.rest, 1) IN IF ~consolidatedHighLowLastIndicator.ok THEN Fail ELSE
    LET participantOpenHighLowLastIndicator == ReadBytes(consolidatedHighLowLastIndicator.rest, 1) IN IF ~participantOpenHighLowLastIndicator.ok THEN Fail ELSE
    Ok([ participantId                       |-> participantId.value,
         timestamp1                          |-> timestamp1.value,
         messageId                           |-> messageId.value,
         transactionId                       |-> transactionId.value,
         participantReferenceNumber          |-> participantReferenceNumber.value,
         securitySymbol                      |-> securitySymbol.value,
         instrumentType                      |-> instrumentType.value,
         saleConditions                      |-> saleConditions.value,
         tradePrice                          |-> tradePrice.value,
         tradeVolume                         |-> tradeVolume.value,
         sellersSaleDays                     |-> sellersSaleDays.value,
         stopStockIndicator                  |-> stopStockIndicator.value,
         tradeThroughExemptIndicator         |-> tradeThroughExemptIndicator.value,
         tradeReportingFacilityId            |-> tradeReportingFacilityId.value,
         timestamp2                          |-> timestamp2.value,
         shortSaleRestrictionIndicator       |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId   |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator            |-> financialStatusIndicator.value,
         heldTradeIndicator                  |-> heldTradeIndicator.value,
         consolidatedHighLowLastIndicator    |-> consolidatedHighLowLastIndicator.value,
         participantOpenHighLowLastIndicator |-> participantOpenHighLowLastIndicator.value ], participantOpenHighLowLastIndicator.rest)

ZeroLongTradeMessage ==
    [ participantId                       |-> [i \in 1 .. 1 |-> 0],
      timestamp1                          |-> ZeroTimestamp133,
      messageId                           |-> [i \in 1 .. 1 |-> 0],
      transactionId                       |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber          |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                      |-> [i \in 1 .. 11 |-> 0],
      instrumentType                      |-> [i \in 1 .. 1 |-> 0],
      saleConditions                      |-> ZeroSaleConditions13,
      tradePrice                          |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                         |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays                     |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator                  |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator         |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId            |-> [i \in 1 .. 1 |-> 0],
      timestamp2                          |-> ZeroTimestamp23,
      shortSaleRestrictionIndicator       |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId   |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator            |-> [i \in 1 .. 1 |-> 0],
      heldTradeIndicator                  |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighLowLastIndicator    |-> [i \in 1 .. 1 |-> 0],
      participantOpenHighLowLastIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Long Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedLongTradeMessage ==
    { ZeroLongTradeMessage }
        \cup { [ZeroLongTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp133 }
        \cup { [ZeroLongTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroLongTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroLongTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroLongTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions13 }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroLongTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp23 }
        \cup { [ZeroLongTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.heldTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.consolidatedHighLowLastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.participantOpenHighLowLastIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp134 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp134(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp134(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp134 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp134 ==
    { ZeroTimestamp134 }
        \cup { [ZeroTimestamp134 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp134 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions14 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions14(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions14(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions14 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions14 ==
    { ZeroSaleConditions14 }
        \cup { [ZeroSaleConditions14 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions14 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions14 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions14 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp24 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp24(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp24(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp24 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp24 ==
    { ZeroTimestamp24 }
        \cup { [ZeroTimestamp24 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp24 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Long Trade Message: 72 bytes                                 *)
(***************************************************************************)

FractionalLongTradeMessage ==
    [ participantId                       : Sample(1),
      timestamp1                          : Timestamp134,
      messageId                           : Sample(1),
      transactionId                       : Sample(4),
      participantReferenceNumber          : Sample(8),
      securitySymbol                      : Sample(11),
      instrumentType                      : Sample(1),
      saleConditions                      : SaleConditions14,
      tradePrice                          : Sample(8),
      fractionalTradeVolume               : Sample(8),
      sellersSaleDays                     : Sample(1),
      stopStockIndicator                  : Sample(1),
      tradeThroughExemptIndicator         : Sample(1),
      tradeReportingFacilityId            : Sample(1),
      timestamp2                          : Timestamp24,
      shortSaleRestrictionIndicator       : Sample(1),
      primaryListingMarketParticipantId   : Sample(1),
      financialStatusIndicator            : Sample(1),
      heldTradeIndicator                  : Sample(1),
      consolidatedHighLowLastIndicator    : Sample(1),
      participantOpenHighLowLastIndicator : Sample(1) ]

EncodeFractionalLongTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp134(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleConditions14(message.saleConditions)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp24(message.timestamp2)
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.heldTradeIndicator
        \o message.consolidatedHighLowLastIndicator
        \o message.participantOpenHighLowLastIndicator

DecodeFractionalLongTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp134(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleConditions == DecodeSaleConditions14(instrumentType.rest) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp24(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(timestamp2.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET heldTradeIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~heldTradeIndicator.ok THEN Fail ELSE
    LET consolidatedHighLowLastIndicator == ReadBytes(heldTradeIndicator.rest, 1) IN IF ~consolidatedHighLowLastIndicator.ok THEN Fail ELSE
    LET participantOpenHighLowLastIndicator == ReadBytes(consolidatedHighLowLastIndicator.rest, 1) IN IF ~participantOpenHighLowLastIndicator.ok THEN Fail ELSE
    Ok([ participantId                       |-> participantId.value,
         timestamp1                          |-> timestamp1.value,
         messageId                           |-> messageId.value,
         transactionId                       |-> transactionId.value,
         participantReferenceNumber          |-> participantReferenceNumber.value,
         securitySymbol                      |-> securitySymbol.value,
         instrumentType                      |-> instrumentType.value,
         saleConditions                      |-> saleConditions.value,
         tradePrice                          |-> tradePrice.value,
         fractionalTradeVolume               |-> fractionalTradeVolume.value,
         sellersSaleDays                     |-> sellersSaleDays.value,
         stopStockIndicator                  |-> stopStockIndicator.value,
         tradeThroughExemptIndicator         |-> tradeThroughExemptIndicator.value,
         tradeReportingFacilityId            |-> tradeReportingFacilityId.value,
         timestamp2                          |-> timestamp2.value,
         shortSaleRestrictionIndicator       |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId   |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator            |-> financialStatusIndicator.value,
         heldTradeIndicator                  |-> heldTradeIndicator.value,
         consolidatedHighLowLastIndicator    |-> consolidatedHighLowLastIndicator.value,
         participantOpenHighLowLastIndicator |-> participantOpenHighLowLastIndicator.value ], participantOpenHighLowLastIndicator.rest)

ZeroFractionalLongTradeMessage ==
    [ participantId                       |-> [i \in 1 .. 1 |-> 0],
      timestamp1                          |-> ZeroTimestamp134,
      messageId                           |-> [i \in 1 .. 1 |-> 0],
      transactionId                       |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber          |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                      |-> [i \in 1 .. 11 |-> 0],
      instrumentType                      |-> [i \in 1 .. 1 |-> 0],
      saleConditions                      |-> ZeroSaleConditions14,
      tradePrice                          |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume               |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays                     |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator                  |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator         |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId            |-> [i \in 1 .. 1 |-> 0],
      timestamp2                          |-> ZeroTimestamp24,
      shortSaleRestrictionIndicator       |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId   |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator            |-> [i \in 1 .. 1 |-> 0],
      heldTradeIndicator                  |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighLowLastIndicator    |-> [i \in 1 .. 1 |-> 0],
      participantOpenHighLowLastIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Long Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalLongTradeMessage ==
    { ZeroFractionalLongTradeMessage }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp134 }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions14 }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp24 }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.heldTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.consolidatedHighLowLastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.participantOpenHighLowLastIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp135 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp135(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp135(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp135 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp135 ==
    { ZeroTimestamp135 }
        \cup { [ZeroTimestamp135 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp135 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 72 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ participantId                          : Sample(1),
      timestamp1                             : Timestamp135,
      messageId                              : Sample(1),
      transactionId                          : Sample(4),
      participantReferenceNumber             : Sample(8),
      securitySymbol                         : Sample(11),
      instrumentType                         : Sample(1),
      lastPrice                              : Sample(8),
      highIndicationPriceUpperLimitPriceBand : Sample(8),
      lowIndicationPriceLowerLimitPriceBand  : Sample(8),
      buyVolume                              : Sample(4),
      sellVolume                             : Sample(4),
      securityStatus                         : Sample(1),
      haltReason                             : Sample(1),
      shortSaleRestrictionIndicator          : Sample(1),
      primaryListingMarketParticipantId      : Sample(1),
      financialStatusIndicator               : Sample(1),
      limitUpLimitDownIndicator              : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp135(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.lastPrice
        \o message.highIndicationPriceUpperLimitPriceBand
        \o message.lowIndicationPriceLowerLimitPriceBand
        \o message.buyVolume
        \o message.sellVolume
        \o message.securityStatus
        \o message.haltReason
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.limitUpLimitDownIndicator

DecodeTradingStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp135(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(instrumentType.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highIndicationPriceUpperLimitPriceBand == ReadBytes(lastPrice.rest, 8) IN IF ~highIndicationPriceUpperLimitPriceBand.ok THEN Fail ELSE
    LET lowIndicationPriceLowerLimitPriceBand == ReadBytes(highIndicationPriceUpperLimitPriceBand.rest, 8) IN IF ~lowIndicationPriceLowerLimitPriceBand.ok THEN Fail ELSE
    LET buyVolume == ReadBytes(lowIndicationPriceLowerLimitPriceBand.rest, 4) IN IF ~buyVolume.ok THEN Fail ELSE
    LET sellVolume == ReadBytes(buyVolume.rest, 4) IN IF ~sellVolume.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(sellVolume.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET haltReason == ReadBytes(securityStatus.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(haltReason.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET limitUpLimitDownIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~limitUpLimitDownIndicator.ok THEN Fail ELSE
    Ok([ participantId                          |-> participantId.value,
         timestamp1                             |-> timestamp1.value,
         messageId                              |-> messageId.value,
         transactionId                          |-> transactionId.value,
         participantReferenceNumber             |-> participantReferenceNumber.value,
         securitySymbol                         |-> securitySymbol.value,
         instrumentType                         |-> instrumentType.value,
         lastPrice                              |-> lastPrice.value,
         highIndicationPriceUpperLimitPriceBand |-> highIndicationPriceUpperLimitPriceBand.value,
         lowIndicationPriceLowerLimitPriceBand  |-> lowIndicationPriceLowerLimitPriceBand.value,
         buyVolume                              |-> buyVolume.value,
         sellVolume                             |-> sellVolume.value,
         securityStatus                         |-> securityStatus.value,
         haltReason                             |-> haltReason.value,
         shortSaleRestrictionIndicator          |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId      |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator               |-> financialStatusIndicator.value,
         limitUpLimitDownIndicator              |-> limitUpLimitDownIndicator.value ], limitUpLimitDownIndicator.rest)

ZeroTradingStatusMessage ==
    [ participantId                          |-> [i \in 1 .. 1 |-> 0],
      timestamp1                             |-> ZeroTimestamp135,
      messageId                              |-> [i \in 1 .. 1 |-> 0],
      transactionId                          |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber             |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                         |-> [i \in 1 .. 11 |-> 0],
      instrumentType                         |-> [i \in 1 .. 1 |-> 0],
      lastPrice                              |-> [i \in 1 .. 8 |-> 0],
      highIndicationPriceUpperLimitPriceBand |-> [i \in 1 .. 8 |-> 0],
      lowIndicationPriceLowerLimitPriceBand  |-> [i \in 1 .. 8 |-> 0],
      buyVolume                              |-> [i \in 1 .. 4 |-> 0],
      sellVolume                             |-> [i \in 1 .. 4 |-> 0],
      securityStatus                         |-> [i \in 1 .. 1 |-> 0],
      haltReason                             |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator          |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId      |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator               |-> [i \in 1 .. 1 |-> 0],
      limitUpLimitDownIndicator              |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp135 }
        \cup { [ZeroTradingStatusMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.highIndicationPriceUpperLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.lowIndicationPriceLowerLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.buyVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.sellVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.limitUpLimitDownIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp136 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp136(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp136(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp136 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp136 ==
    { ZeroTimestamp136 }
        \cup { [ZeroTimestamp136 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp136 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Short Trade Message: 36 bytes                                           *)
(***************************************************************************)

ShortTradeMessage ==
    [ participantId                       : Sample(1),
      timestamp1                          : Timestamp136,
      messageId                           : Sample(1),
      transactionId                       : Sample(4),
      participantReferenceNumber          : Sample(8),
      securitySymbolShort                 : Sample(5),
      saleCondition                       : Sample(1),
      saleConditionCategory               : Sample(1),
      tradePriceShort                     : Sample(2),
      tradeVolumeShort                    : Sample(2),
      primaryListingMarketParticipantId   : Sample(1),
      consolidatedHighLowLastIndicator    : Sample(1),
      participantOpenHighLowLastIndicator : Sample(1) ]

EncodeShortTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp136(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbolShort
        \o message.saleCondition
        \o message.saleConditionCategory
        \o message.tradePriceShort
        \o message.tradeVolumeShort
        \o message.primaryListingMarketParticipantId
        \o message.consolidatedHighLowLastIndicator
        \o message.participantOpenHighLowLastIndicator

DecodeShortTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp136(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbolShort == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbolShort.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(securitySymbolShort.rest, 1) IN IF ~saleCondition.ok THEN Fail ELSE
    LET saleConditionCategory == ReadBytes(saleCondition.rest, 1) IN IF ~saleConditionCategory.ok THEN Fail ELSE
    LET tradePriceShort == ReadBytes(saleConditionCategory.rest, 2) IN IF ~tradePriceShort.ok THEN Fail ELSE
    LET tradeVolumeShort == ReadBytes(tradePriceShort.rest, 2) IN IF ~tradeVolumeShort.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(tradeVolumeShort.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET consolidatedHighLowLastIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~consolidatedHighLowLastIndicator.ok THEN Fail ELSE
    LET participantOpenHighLowLastIndicator == ReadBytes(consolidatedHighLowLastIndicator.rest, 1) IN IF ~participantOpenHighLowLastIndicator.ok THEN Fail ELSE
    Ok([ participantId                       |-> participantId.value,
         timestamp1                          |-> timestamp1.value,
         messageId                           |-> messageId.value,
         transactionId                       |-> transactionId.value,
         participantReferenceNumber          |-> participantReferenceNumber.value,
         securitySymbolShort                 |-> securitySymbolShort.value,
         saleCondition                       |-> saleCondition.value,
         saleConditionCategory               |-> saleConditionCategory.value,
         tradePriceShort                     |-> tradePriceShort.value,
         tradeVolumeShort                    |-> tradeVolumeShort.value,
         primaryListingMarketParticipantId   |-> primaryListingMarketParticipantId.value,
         consolidatedHighLowLastIndicator    |-> consolidatedHighLowLastIndicator.value,
         participantOpenHighLowLastIndicator |-> participantOpenHighLowLastIndicator.value ], participantOpenHighLowLastIndicator.rest)

ZeroShortTradeMessage ==
    [ participantId                       |-> [i \in 1 .. 1 |-> 0],
      timestamp1                          |-> ZeroTimestamp136,
      messageId                           |-> [i \in 1 .. 1 |-> 0],
      transactionId                       |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber          |-> [i \in 1 .. 8 |-> 0],
      securitySymbolShort                 |-> [i \in 1 .. 5 |-> 0],
      saleCondition                       |-> [i \in 1 .. 1 |-> 0],
      saleConditionCategory               |-> [i \in 1 .. 1 |-> 0],
      tradePriceShort                     |-> [i \in 1 .. 2 |-> 0],
      tradeVolumeShort                    |-> [i \in 1 .. 2 |-> 0],
      primaryListingMarketParticipantId   |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighLowLastIndicator    |-> [i \in 1 .. 1 |-> 0],
      participantOpenHighLowLastIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Short Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedShortTradeMessage ==
    { ZeroShortTradeMessage }
        \cup { [ZeroShortTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp136 }
        \cup { [ZeroShortTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroShortTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroShortTradeMessage EXCEPT !.securitySymbolShort = one] : one \in Sample(5) }
        \cup { [ZeroShortTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.saleConditionCategory = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.tradePriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortTradeMessage EXCEPT !.tradeVolumeShort = one] : one \in Sample(2) }
        \cup { [ZeroShortTradeMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.consolidatedHighLowLastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.participantOpenHighLowLastIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp137 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp137(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp137(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp137 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp137 ==
    { ZeroTimestamp137 }
        \cup { [ZeroTimestamp137 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp137 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Short Trade Message: 38 bytes                                *)
(***************************************************************************)

FractionalShortTradeMessage ==
    [ participantId                       : Sample(1),
      timestamp1                          : Timestamp137,
      messageId                           : Sample(1),
      transactionId                       : Sample(4),
      participantReferenceNumber          : Sample(8),
      securitySymbolShort                 : Sample(5),
      saleCondition                       : Sample(1),
      saleConditionCategory               : Sample(1),
      tradePriceShort                     : Sample(2),
      fractionalTradeVolumeShort          : Sample(4),
      primaryListingMarketParticipantId   : Sample(1),
      consolidatedHighLowLastIndicator    : Sample(1),
      participantOpenHighLowLastIndicator : Sample(1) ]

EncodeFractionalShortTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp137(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbolShort
        \o message.saleCondition
        \o message.saleConditionCategory
        \o message.tradePriceShort
        \o message.fractionalTradeVolumeShort
        \o message.primaryListingMarketParticipantId
        \o message.consolidatedHighLowLastIndicator
        \o message.participantOpenHighLowLastIndicator

DecodeFractionalShortTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp137(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbolShort == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbolShort.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(securitySymbolShort.rest, 1) IN IF ~saleCondition.ok THEN Fail ELSE
    LET saleConditionCategory == ReadBytes(saleCondition.rest, 1) IN IF ~saleConditionCategory.ok THEN Fail ELSE
    LET tradePriceShort == ReadBytes(saleConditionCategory.rest, 2) IN IF ~tradePriceShort.ok THEN Fail ELSE
    LET fractionalTradeVolumeShort == ReadBytes(tradePriceShort.rest, 4) IN IF ~fractionalTradeVolumeShort.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(fractionalTradeVolumeShort.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET consolidatedHighLowLastIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~consolidatedHighLowLastIndicator.ok THEN Fail ELSE
    LET participantOpenHighLowLastIndicator == ReadBytes(consolidatedHighLowLastIndicator.rest, 1) IN IF ~participantOpenHighLowLastIndicator.ok THEN Fail ELSE
    Ok([ participantId                       |-> participantId.value,
         timestamp1                          |-> timestamp1.value,
         messageId                           |-> messageId.value,
         transactionId                       |-> transactionId.value,
         participantReferenceNumber          |-> participantReferenceNumber.value,
         securitySymbolShort                 |-> securitySymbolShort.value,
         saleCondition                       |-> saleCondition.value,
         saleConditionCategory               |-> saleConditionCategory.value,
         tradePriceShort                     |-> tradePriceShort.value,
         fractionalTradeVolumeShort          |-> fractionalTradeVolumeShort.value,
         primaryListingMarketParticipantId   |-> primaryListingMarketParticipantId.value,
         consolidatedHighLowLastIndicator    |-> consolidatedHighLowLastIndicator.value,
         participantOpenHighLowLastIndicator |-> participantOpenHighLowLastIndicator.value ], participantOpenHighLowLastIndicator.rest)

ZeroFractionalShortTradeMessage ==
    [ participantId                       |-> [i \in 1 .. 1 |-> 0],
      timestamp1                          |-> ZeroTimestamp137,
      messageId                           |-> [i \in 1 .. 1 |-> 0],
      transactionId                       |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber          |-> [i \in 1 .. 8 |-> 0],
      securitySymbolShort                 |-> [i \in 1 .. 5 |-> 0],
      saleCondition                       |-> [i \in 1 .. 1 |-> 0],
      saleConditionCategory               |-> [i \in 1 .. 1 |-> 0],
      tradePriceShort                     |-> [i \in 1 .. 2 |-> 0],
      fractionalTradeVolumeShort          |-> [i \in 1 .. 4 |-> 0],
      primaryListingMarketParticipantId   |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighLowLastIndicator    |-> [i \in 1 .. 1 |-> 0],
      participantOpenHighLowLastIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Short Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalShortTradeMessage ==
    { ZeroFractionalShortTradeMessage }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp137 }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.securitySymbolShort = one] : one \in Sample(5) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.saleConditionCategory = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.tradePriceShort = one] : one \in Sample(2) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.fractionalTradeVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.consolidatedHighLowLastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.participantOpenHighLowLastIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp138 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp138(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp138(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp138 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp138 ==
    { ZeroTimestamp138 }
        \cup { [ZeroTimestamp138 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp138 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions15 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions15(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions15(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions15 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions15 ==
    { ZeroSaleConditions15 }
        \cup { [ZeroSaleConditions15 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions15 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions15 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions15 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp25 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp25(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp25(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp25 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp25 ==
    { ZeroTimestamp25 }
        \cup { [ZeroTimestamp25 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp25 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Consolidated Data: 34 bytes                                             *)
(***************************************************************************)

ConsolidatedData2 ==
    [ previousClosePriceDate : Sample(4),
      lastParticipantId      : Sample(1),
      lastPrice              : Sample(8),
      highPrice              : Sample(8),
      lowPrice               : Sample(8),
      totalVolumeShort       : Sample(4),
      tick                   : Sample(1) ]

EncodeConsolidatedData2(message) ==
    message.previousClosePriceDate
        \o message.lastParticipantId
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.totalVolumeShort
        \o message.tick

DecodeConsolidatedData2(bytes) ==
    LET previousClosePriceDate == ReadBytes(bytes, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastParticipantId == ReadBytes(previousClosePriceDate.rest, 1) IN IF ~lastParticipantId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lastParticipantId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET totalVolumeShort == ReadBytes(lowPrice.rest, 4) IN IF ~totalVolumeShort.ok THEN Fail ELSE
    LET tick == ReadBytes(totalVolumeShort.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ previousClosePriceDate |-> previousClosePriceDate.value,
         lastParticipantId      |-> lastParticipantId.value,
         lastPrice              |-> lastPrice.value,
         highPrice              |-> highPrice.value,
         lowPrice               |-> lowPrice.value,
         totalVolumeShort       |-> totalVolumeShort.value,
         tick                   |-> tick.value ], tick.rest)

ZeroConsolidatedData2 ==
    [ previousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      lastParticipantId      |-> [i \in 1 .. 1 |-> 0],
      lastPrice              |-> [i \in 1 .. 8 |-> 0],
      highPrice              |-> [i \in 1 .. 8 |-> 0],
      lowPrice               |-> [i \in 1 .. 8 |-> 0],
      totalVolumeShort       |-> [i \in 1 .. 4 |-> 0],
      tick                   |-> [i \in 1 .. 1 |-> 0] ]

(* Consolidated Data at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedData2 ==
    { ZeroConsolidatedData2 }
        \cup { [ZeroConsolidatedData2 EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedData2 EXCEPT !.lastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedData2 EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedData2 EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedData2 EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedData2 EXCEPT !.totalVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedData2 EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Participant Data: 41 bytes                                              *)
(***************************************************************************)

ParticipantData2 ==
    [ previousClosePriceDate : Sample(4),
      lastPrice              : Sample(8),
      highPrice              : Sample(8),
      lowPrice               : Sample(8),
      openPrice              : Sample(8),
      totalVolumeShort       : Sample(4),
      tick                   : Sample(1) ]

EncodeParticipantData2(message) ==
    message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.totalVolumeShort
        \o message.tick

DecodeParticipantData2(bytes) ==
    LET previousClosePriceDate == ReadBytes(bytes, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lowPrice.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET totalVolumeShort == ReadBytes(openPrice.rest, 4) IN IF ~totalVolumeShort.ok THEN Fail ELSE
    LET tick == ReadBytes(totalVolumeShort.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ previousClosePriceDate |-> previousClosePriceDate.value,
         lastPrice              |-> lastPrice.value,
         highPrice              |-> highPrice.value,
         lowPrice               |-> lowPrice.value,
         openPrice              |-> openPrice.value,
         totalVolumeShort       |-> totalVolumeShort.value,
         tick                   |-> tick.value ], tick.rest)

ZeroParticipantData2 ==
    [ previousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      lastPrice              |-> [i \in 1 .. 8 |-> 0],
      highPrice              |-> [i \in 1 .. 8 |-> 0],
      lowPrice               |-> [i \in 1 .. 8 |-> 0],
      openPrice              |-> [i \in 1 .. 8 |-> 0],
      totalVolumeShort       |-> [i \in 1 .. 4 |-> 0],
      tick                   |-> [i \in 1 .. 1 |-> 0] ]

(* Participant Data at zero, then each field in turn at the values it is checked at *)
CheckedParticipantData2 ==
    { ZeroParticipantData2 }
        \cup { [ZeroParticipantData2 EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroParticipantData2 EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantData2 EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantData2 EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantData2 EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantData2 EXCEPT !.totalVolumeShort = one] : one \in Sample(4) }
        \cup { [ZeroParticipantData2 EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Error Message: 149 bytes                                   *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ participantId                      : Sample(1),
      timestamp1                         : Timestamp138,
      messageId                          : Sample(1),
      transactionId                      : Sample(4),
      participantReferenceNumber         : Sample(8),
      securitySymbol                     : Sample(11),
      instrumentType                     : Sample(1),
      saleConditions                     : SaleConditions15,
      tradePrice                         : Sample(8),
      tradeVolume                        : Sample(4),
      sellersSaleDays                    : Sample(1),
      stopStockIndicator                 : Sample(1),
      tradeThroughExemptIndicator        : Sample(1),
      tradeReportingFacilityId           : Sample(1),
      originalParticipantReferenceNumber : Sample(8),
      timestamp2                         : Timestamp25,
      cancelErrorAction                  : Sample(1),
      shortSaleRestrictionIndicator      : Sample(1),
      primaryListingMarketParticipantId  : Sample(1),
      financialStatusIndicator           : Sample(1),
      consolidatedData                   : ConsolidatedData2,
      participantData                    : ParticipantData2 ]

EncodeTradeCancelErrorMessage(message) ==
    message.participantId
        \o EncodeTimestamp138(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleConditions15(message.saleConditions)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o message.originalParticipantReferenceNumber
        \o EncodeTimestamp25(message.timestamp2)
        \o message.cancelErrorAction
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o EncodeConsolidatedData2(message.consolidatedData)
        \o EncodeParticipantData2(message.participantData)

DecodeTradeCancelErrorMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp138(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleConditions == DecodeSaleConditions15(instrumentType.rest) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(tradeReportingFacilityId.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp25(originalParticipantReferenceNumber.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(timestamp2.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(cancelErrorAction.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET consolidatedData == DecodeConsolidatedData2(financialStatusIndicator.rest) IN IF ~consolidatedData.ok THEN Fail ELSE
    LET participantData == DecodeParticipantData2(consolidatedData.rest) IN IF ~participantData.ok THEN Fail ELSE
    Ok([ participantId                      |-> participantId.value,
         timestamp1                         |-> timestamp1.value,
         messageId                          |-> messageId.value,
         transactionId                      |-> transactionId.value,
         participantReferenceNumber         |-> participantReferenceNumber.value,
         securitySymbol                     |-> securitySymbol.value,
         instrumentType                     |-> instrumentType.value,
         saleConditions                     |-> saleConditions.value,
         tradePrice                         |-> tradePrice.value,
         tradeVolume                        |-> tradeVolume.value,
         sellersSaleDays                    |-> sellersSaleDays.value,
         stopStockIndicator                 |-> stopStockIndicator.value,
         tradeThroughExemptIndicator        |-> tradeThroughExemptIndicator.value,
         tradeReportingFacilityId           |-> tradeReportingFacilityId.value,
         originalParticipantReferenceNumber |-> originalParticipantReferenceNumber.value,
         timestamp2                         |-> timestamp2.value,
         cancelErrorAction                  |-> cancelErrorAction.value,
         shortSaleRestrictionIndicator      |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId  |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator           |-> financialStatusIndicator.value,
         consolidatedData                   |-> consolidatedData.value,
         participantData                    |-> participantData.value ], participantData.rest)

ZeroTradeCancelErrorMessage ==
    [ participantId                      |-> [i \in 1 .. 1 |-> 0],
      timestamp1                         |-> ZeroTimestamp138,
      messageId                          |-> [i \in 1 .. 1 |-> 0],
      transactionId                      |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                     |-> [i \in 1 .. 11 |-> 0],
      instrumentType                     |-> [i \in 1 .. 1 |-> 0],
      saleConditions                     |-> ZeroSaleConditions15,
      tradePrice                         |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                        |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays                    |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator                 |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator        |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId           |-> [i \in 1 .. 1 |-> 0],
      originalParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      timestamp2                         |-> ZeroTimestamp25,
      cancelErrorAction                  |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator      |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId  |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator           |-> [i \in 1 .. 1 |-> 0],
      consolidatedData                   |-> ZeroConsolidatedData2,
      participantData                    |-> ZeroParticipantData2 ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp138 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions15 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp25 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedData = one] : one \in CheckedConsolidatedData2 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantData = one] : one \in CheckedParticipantData2 }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp139 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp139(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp139(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp139 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp139 ==
    { ZeroTimestamp139 }
        \cup { [ZeroTimestamp139 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp139 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Conditions: 4 bytes                                                *)
(***************************************************************************)

SaleConditions16 ==
    [ settlementType              : Sample(1),
      tradeThroughExemptReason    : Sample(1),
      extendedHoursOrSequenceType : Sample(1),
      sroTradeDetail              : Sample(1) ]

EncodeSaleConditions16(message) ==
    message.settlementType
        \o message.tradeThroughExemptReason
        \o message.extendedHoursOrSequenceType
        \o message.sroTradeDetail

DecodeSaleConditions16(bytes) ==
    LET settlementType == ReadBytes(bytes, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET tradeThroughExemptReason == ReadBytes(settlementType.rest, 1) IN IF ~tradeThroughExemptReason.ok THEN Fail ELSE
    LET extendedHoursOrSequenceType == ReadBytes(tradeThroughExemptReason.rest, 1) IN IF ~extendedHoursOrSequenceType.ok THEN Fail ELSE
    LET sroTradeDetail == ReadBytes(extendedHoursOrSequenceType.rest, 1) IN IF ~sroTradeDetail.ok THEN Fail ELSE
    Ok([ settlementType              |-> settlementType.value,
         tradeThroughExemptReason    |-> tradeThroughExemptReason.value,
         extendedHoursOrSequenceType |-> extendedHoursOrSequenceType.value,
         sroTradeDetail              |-> sroTradeDetail.value ], sroTradeDetail.rest)

ZeroSaleConditions16 ==
    [ settlementType              |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptReason    |-> [i \in 1 .. 1 |-> 0],
      extendedHoursOrSequenceType |-> [i \in 1 .. 1 |-> 0],
      sroTradeDetail              |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Conditions at zero, then each field in turn at the values it is checked at *)
CheckedSaleConditions16 ==
    { ZeroSaleConditions16 }
        \cup { [ZeroSaleConditions16 EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions16 EXCEPT !.tradeThroughExemptReason = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions16 EXCEPT !.extendedHoursOrSequenceType = one] : one \in Sample(1) }
        \cup { [ZeroSaleConditions16 EXCEPT !.sroTradeDetail = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 2: 8 bytes                                                    *)
(***************************************************************************)

Timestamp26 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp26(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp26(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp26 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 2 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp26 ==
    { ZeroTimestamp26 }
        \cup { [ZeroTimestamp26 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp26 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Consolidated Data: 38 bytes                                  *)
(***************************************************************************)

FractionalConsolidatedData2 ==
    [ previousClosePriceDate : Sample(4),
      lastParticipantId      : Sample(1),
      lastPrice              : Sample(8),
      highPrice              : Sample(8),
      lowPrice               : Sample(8),
      fractionalTotalVolume  : Sample(8),
      tick                   : Sample(1) ]

EncodeFractionalConsolidatedData2(message) ==
    message.previousClosePriceDate
        \o message.lastParticipantId
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.fractionalTotalVolume
        \o message.tick

DecodeFractionalConsolidatedData2(bytes) ==
    LET previousClosePriceDate == ReadBytes(bytes, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastParticipantId == ReadBytes(previousClosePriceDate.rest, 1) IN IF ~lastParticipantId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lastParticipantId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET fractionalTotalVolume == ReadBytes(lowPrice.rest, 8) IN IF ~fractionalTotalVolume.ok THEN Fail ELSE
    LET tick == ReadBytes(fractionalTotalVolume.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ previousClosePriceDate |-> previousClosePriceDate.value,
         lastParticipantId      |-> lastParticipantId.value,
         lastPrice              |-> lastPrice.value,
         highPrice              |-> highPrice.value,
         lowPrice               |-> lowPrice.value,
         fractionalTotalVolume  |-> fractionalTotalVolume.value,
         tick                   |-> tick.value ], tick.rest)

ZeroFractionalConsolidatedData2 ==
    [ previousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      lastParticipantId      |-> [i \in 1 .. 1 |-> 0],
      lastPrice              |-> [i \in 1 .. 8 |-> 0],
      highPrice              |-> [i \in 1 .. 8 |-> 0],
      lowPrice               |-> [i \in 1 .. 8 |-> 0],
      fractionalTotalVolume  |-> [i \in 1 .. 8 |-> 0],
      tick                   |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Consolidated Data at zero, then each field in turn at the values it is checked at *)
CheckedFractionalConsolidatedData2 ==
    { ZeroFractionalConsolidatedData2 }
        \cup { [ZeroFractionalConsolidatedData2 EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalConsolidatedData2 EXCEPT !.lastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalConsolidatedData2 EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedData2 EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedData2 EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedData2 EXCEPT !.fractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalConsolidatedData2 EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Participant Data: 45 bytes                                   *)
(***************************************************************************)

FractionalParticipantData2 ==
    [ previousClosePriceDate : Sample(4),
      lastPrice              : Sample(8),
      highPrice              : Sample(8),
      lowPrice               : Sample(8),
      openPrice              : Sample(8),
      fractionalTotalVolume  : Sample(8),
      tick                   : Sample(1) ]

EncodeFractionalParticipantData2(message) ==
    message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.fractionalTotalVolume
        \o message.tick

DecodeFractionalParticipantData2(bytes) ==
    LET previousClosePriceDate == ReadBytes(bytes, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(previousClosePriceDate.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lastPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lowPrice.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET fractionalTotalVolume == ReadBytes(openPrice.rest, 8) IN IF ~fractionalTotalVolume.ok THEN Fail ELSE
    LET tick == ReadBytes(fractionalTotalVolume.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    Ok([ previousClosePriceDate |-> previousClosePriceDate.value,
         lastPrice              |-> lastPrice.value,
         highPrice              |-> highPrice.value,
         lowPrice               |-> lowPrice.value,
         openPrice              |-> openPrice.value,
         fractionalTotalVolume  |-> fractionalTotalVolume.value,
         tick                   |-> tick.value ], tick.rest)

ZeroFractionalParticipantData2 ==
    [ previousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      lastPrice              |-> [i \in 1 .. 8 |-> 0],
      highPrice              |-> [i \in 1 .. 8 |-> 0],
      lowPrice               |-> [i \in 1 .. 8 |-> 0],
      openPrice              |-> [i \in 1 .. 8 |-> 0],
      fractionalTotalVolume  |-> [i \in 1 .. 8 |-> 0],
      tick                   |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Participant Data at zero, then each field in turn at the values it is checked at *)
CheckedFractionalParticipantData2 ==
    { ZeroFractionalParticipantData2 }
        \cup { [ZeroFractionalParticipantData2 EXCEPT !.previousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalParticipantData2 EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData2 EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData2 EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData2 EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData2 EXCEPT !.fractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantData2 EXCEPT !.tick = one] : one \in Sample(1) }

(***************************************************************************)
(* Fractional Trade Cancel Error Message: 161 bytes                        *)
(***************************************************************************)

FractionalTradeCancelErrorMessage ==
    [ participantId                      : Sample(1),
      timestamp1                         : Timestamp139,
      messageId                          : Sample(1),
      transactionId                      : Sample(4),
      participantReferenceNumber         : Sample(8),
      securitySymbol                     : Sample(11),
      instrumentType                     : Sample(1),
      saleConditions                     : SaleConditions16,
      tradePrice                         : Sample(8),
      fractionalTradeVolume              : Sample(8),
      sellersSaleDays                    : Sample(1),
      stopStockIndicator                 : Sample(1),
      tradeThroughExemptIndicator        : Sample(1),
      tradeReportingFacilityId           : Sample(1),
      originalParticipantReferenceNumber : Sample(8),
      timestamp2                         : Timestamp26,
      cancelErrorAction                  : Sample(1),
      shortSaleRestrictionIndicator      : Sample(1),
      primaryListingMarketParticipantId  : Sample(1),
      financialStatusIndicator           : Sample(1),
      fractionalConsolidatedData         : FractionalConsolidatedData2,
      fractionalParticipantData          : FractionalParticipantData2 ]

EncodeFractionalTradeCancelErrorMessage(message) ==
    message.participantId
        \o EncodeTimestamp139(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleConditions16(message.saleConditions)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o message.originalParticipantReferenceNumber
        \o EncodeTimestamp26(message.timestamp2)
        \o message.cancelErrorAction
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o EncodeFractionalConsolidatedData2(message.fractionalConsolidatedData)
        \o EncodeFractionalParticipantData2(message.fractionalParticipantData)

DecodeFractionalTradeCancelErrorMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp139(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleConditions == DecodeSaleConditions16(instrumentType.rest) IN IF ~saleConditions.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditions.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(tradeReportingFacilityId.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp26(originalParticipantReferenceNumber.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(timestamp2.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(cancelErrorAction.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET fractionalConsolidatedData == DecodeFractionalConsolidatedData2(financialStatusIndicator.rest) IN IF ~fractionalConsolidatedData.ok THEN Fail ELSE
    LET fractionalParticipantData == DecodeFractionalParticipantData2(fractionalConsolidatedData.rest) IN IF ~fractionalParticipantData.ok THEN Fail ELSE
    Ok([ participantId                      |-> participantId.value,
         timestamp1                         |-> timestamp1.value,
         messageId                          |-> messageId.value,
         transactionId                      |-> transactionId.value,
         participantReferenceNumber         |-> participantReferenceNumber.value,
         securitySymbol                     |-> securitySymbol.value,
         instrumentType                     |-> instrumentType.value,
         saleConditions                     |-> saleConditions.value,
         tradePrice                         |-> tradePrice.value,
         fractionalTradeVolume              |-> fractionalTradeVolume.value,
         sellersSaleDays                    |-> sellersSaleDays.value,
         stopStockIndicator                 |-> stopStockIndicator.value,
         tradeThroughExemptIndicator        |-> tradeThroughExemptIndicator.value,
         tradeReportingFacilityId           |-> tradeReportingFacilityId.value,
         originalParticipantReferenceNumber |-> originalParticipantReferenceNumber.value,
         timestamp2                         |-> timestamp2.value,
         cancelErrorAction                  |-> cancelErrorAction.value,
         shortSaleRestrictionIndicator      |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId  |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator           |-> financialStatusIndicator.value,
         fractionalConsolidatedData         |-> fractionalConsolidatedData.value,
         fractionalParticipantData          |-> fractionalParticipantData.value ], fractionalParticipantData.rest)

ZeroFractionalTradeCancelErrorMessage ==
    [ participantId                      |-> [i \in 1 .. 1 |-> 0],
      timestamp1                         |-> ZeroTimestamp139,
      messageId                          |-> [i \in 1 .. 1 |-> 0],
      transactionId                      |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                     |-> [i \in 1 .. 11 |-> 0],
      instrumentType                     |-> [i \in 1 .. 1 |-> 0],
      saleConditions                     |-> ZeroSaleConditions16,
      tradePrice                         |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume              |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays                    |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator                 |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator        |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId           |-> [i \in 1 .. 1 |-> 0],
      originalParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      timestamp2                         |-> ZeroTimestamp26,
      cancelErrorAction                  |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator      |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId  |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator           |-> [i \in 1 .. 1 |-> 0],
      fractionalConsolidatedData         |-> ZeroFractionalConsolidatedData2,
      fractionalParticipantData          |-> ZeroFractionalParticipantData2 ]

(* Fractional Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCancelErrorMessage ==
    { ZeroFractionalTradeCancelErrorMessage }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp139 }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.saleConditions = one] : one \in CheckedSaleConditions16 }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp26 }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.fractionalConsolidatedData = one] : one \in CheckedFractionalConsolidatedData2 }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.fractionalParticipantData = one] : one \in CheckedFractionalParticipantData2 }

(***************************************************************************)
(* Trade Message Payload, selected by Trade Message Type                   *)
(***************************************************************************)

AuctionStatusMessageCode == 65  \* "A"
TradeCorrectionMessageCode == 67  \* "C"
FractionalTradeCorrectionMessageCode == 79  \* "O"
LongTradeMessageCode == 76  \* "L"
FractionalLongTradeMessageCode == 82  \* "R"
TradingStatusMessageCode == 83  \* "S"
ShortTradeMessageCode == 84  \* "T"
FractionalShortTradeMessageCode == 72  \* "H"
TradeCancelErrorMessageCode == 88  \* "X"
FractionalTradeCancelErrorMessageCode == 69  \* "E"

TradeMessagePayload ==
    [ tag : {AuctionStatusMessageCode}, body : AuctionStatusMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {FractionalTradeCorrectionMessageCode}, body : FractionalTradeCorrectionMessage ]
        \cup [ tag : {LongTradeMessageCode}, body : LongTradeMessage ]
        \cup [ tag : {FractionalLongTradeMessageCode}, body : FractionalLongTradeMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {ShortTradeMessageCode}, body : ShortTradeMessage ]
        \cup [ tag : {FractionalShortTradeMessageCode}, body : FractionalShortTradeMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {FractionalTradeCancelErrorMessageCode}, body : FractionalTradeCancelErrorMessage ]

EncodeTradeMessagePayload(message) ==
    CASE message.tag = AuctionStatusMessageCode -> EncodeAuctionStatusMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = FractionalTradeCorrectionMessageCode -> EncodeFractionalTradeCorrectionMessage(message.body)
      [] message.tag = LongTradeMessageCode -> EncodeLongTradeMessage(message.body)
      [] message.tag = FractionalLongTradeMessageCode -> EncodeFractionalLongTradeMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = ShortTradeMessageCode -> EncodeShortTradeMessage(message.body)
      [] message.tag = FractionalShortTradeMessageCode -> EncodeFractionalShortTradeMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = FractionalTradeCancelErrorMessageCode -> EncodeFractionalTradeCancelErrorMessage(message.body)

DecodeTradeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = AuctionStatusMessageCode -> DecodeAuctionStatusMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = FractionalTradeCorrectionMessageCode -> DecodeFractionalTradeCorrectionMessage(bytes)
              [] tag = LongTradeMessageCode -> DecodeLongTradeMessage(bytes)
              [] tag = FractionalLongTradeMessageCode -> DecodeFractionalLongTradeMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = ShortTradeMessageCode -> DecodeShortTradeMessage(bytes)
              [] tag = FractionalShortTradeMessageCode -> DecodeFractionalShortTradeMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = FractionalTradeCancelErrorMessageCode -> DecodeFractionalTradeCancelErrorMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTradeMessagePayload == [tag |-> AuctionStatusMessageCode, body |-> ZeroAuctionStatusMessage]

(* Each Trade Message Payload in turn, at the values the message it names is checked at *)
CheckedTradeMessagePayload ==
    { [tag |-> AuctionStatusMessageCode, body |-> one] : one \in CheckedAuctionStatusMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> FractionalTradeCorrectionMessageCode, body |-> one] : one \in CheckedFractionalTradeCorrectionMessage }
        \cup { [tag |-> LongTradeMessageCode, body |-> one] : one \in CheckedLongTradeMessage }
        \cup { [tag |-> FractionalLongTradeMessageCode, body |-> one] : one \in CheckedFractionalLongTradeMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> ShortTradeMessageCode, body |-> one] : one \in CheckedShortTradeMessage }
        \cup { [tag |-> FractionalShortTradeMessageCode, body |-> one] : one \in CheckedFractionalShortTradeMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> FractionalTradeCancelErrorMessageCode, body |-> one] : one \in CheckedFractionalTradeCancelErrorMessage }

(***************************************************************************)
(* Trade Message                                                           *)
(***************************************************************************)

TradeMessage ==
    [ tradeMessagePayload : TradeMessagePayload ]

EncodeTradeMessage(message) ==
    EncodeUIntBE(message.tradeMessagePayload.tag, 1)
        \o EncodeTradeMessagePayload(message.tradeMessagePayload)

DecodeTradeMessage(bytes) ==
    LET tradeMessageType == ReadUIntBE(bytes, 1) IN IF ~tradeMessageType.ok THEN Fail ELSE
    LET tradeMessagePayload == DecodeTradeMessagePayload(tradeMessageType.value, tradeMessageType.rest) IN IF ~tradeMessagePayload.ok THEN Fail ELSE
    Ok([ tradeMessagePayload |-> tradeMessagePayload.value ], tradeMessagePayload.rest)

ZeroTradeMessage ==
    [ tradeMessagePayload |-> ZeroTradeMessagePayload ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.tradeMessagePayload = one] : one \in CheckedTradeMessagePayload }

(***************************************************************************)
(* Category Payload, selected by Message Category                          *)
(***************************************************************************)

AdministrativeMessageCode == 65  \* "A"
ControlMessageCode == 67  \* "C"
IndicesMessageCode == 73  \* "I"
MarketStatusMessageCode == 77  \* "M"
PriorDayMessageCode == 80  \* "P"
SummaryMessageCode == 83  \* "S"
TradeMessageCode == 84  \* "T"

CategoryPayload ==
    [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]
        \cup [ tag : {IndicesMessageCode}, body : IndicesMessage ]
        \cup [ tag : {MarketStatusMessageCode}, body : MarketStatusMessage ]
        \cup [ tag : {PriorDayMessageCode}, body : PriorDayMessage ]
        \cup [ tag : {SummaryMessageCode}, body : SummaryMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)
      [] message.tag = IndicesMessageCode -> EncodeIndicesMessage(message.body)
      [] message.tag = MarketStatusMessageCode -> EncodeMarketStatusMessage(message.body)
      [] message.tag = PriorDayMessageCode -> EncodePriorDayMessage(message.body)
      [] message.tag = SummaryMessageCode -> EncodeSummaryMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] tag = IndicesMessageCode -> DecodeIndicesMessage(bytes)
              [] tag = MarketStatusMessageCode -> DecodeMarketStatusMessage(bytes)
              [] tag = PriorDayMessageCode -> DecodePriorDayMessage(bytes)
              [] tag = SummaryMessageCode -> DecodeSummaryMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCategoryPayload == [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]

(* Each Category Payload in turn, at the values the message it names is checked at *)
CheckedCategoryPayload ==
    { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }
        \cup { [tag |-> IndicesMessageCode, body |-> one] : one \in CheckedIndicesMessage }
        \cup { [tag |-> MarketStatusMessageCode, body |-> one] : one \in CheckedMarketStatusMessage }
        \cup { [tag |-> PriorDayMessageCode, body |-> one] : one \in CheckedPriorDayMessage }
        \cup { [tag |-> SummaryMessageCode, body |-> one] : one \in CheckedSummaryMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ categoryPayload : CategoryPayload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.categoryPayload.tag, 1)
        \o EncodeCategoryPayload(message.categoryPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageCategory == ReadUIntBE(bytes, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET categoryPayload == DecodeCategoryPayload(messageCategory.value, messageCategory.rest) IN IF ~categoryPayload.ok THEN Fail ELSE
    Ok([ categoryPayload |-> categoryPayload.value ], categoryPayload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ categoryPayload |-> ZeroCategoryPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.categoryPayload = one] : one \in CheckedCategoryPayload }

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
    { [ZeroMessage EXCEPT !.categoryPayload = [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> IndicesMessageCode, body |-> ZeroIndicesMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> MarketStatusMessageCode, body |-> ZeroMarketStatusMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> PriorDayMessageCode, body |-> ZeroPriorDayMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> SummaryMessageCode, body |-> ZeroSummaryMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version                 : Sample(1),
      blockSize               : Sample(2),
      dataFeedIndicator       : Sample(1),
      retransmissionIndicator : Sample(1),
      blockSequenceNumber     : Sample(4),
      sipBlockTimestamp       : SipBlockTimestamp,
      blockChecksum           : Sample(2),
      message                 : SampleLists(OneMessage),
      blockPadByte            : SampleBytes ]

EncodePacket(message) ==
    message.version
        \o message.blockSize
        \o message.dataFeedIndicator
        \o message.retransmissionIndicator
        \o message.blockSequenceNumber
        \o EncodeUIntBE(Len(message.message), 1)
        \o EncodeSipBlockTimestamp(message.sipBlockTimestamp)
        \o message.blockChecksum
        \o EncodeMessageList(message.message)
        \o message.blockPadByte

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET blockSize == ReadBytes(version.rest, 2) IN IF ~blockSize.ok THEN Fail ELSE
    LET dataFeedIndicator == ReadBytes(blockSize.rest, 1) IN IF ~dataFeedIndicator.ok THEN Fail ELSE
    LET retransmissionIndicator == ReadBytes(dataFeedIndicator.rest, 1) IN IF ~retransmissionIndicator.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(retransmissionIndicator.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET messagesInBlock == ReadUIntBE(blockSequenceNumber.rest, 1) IN IF ~messagesInBlock.ok THEN Fail ELSE
    LET sipBlockTimestamp == DecodeSipBlockTimestamp(messagesInBlock.rest) IN IF ~sipBlockTimestamp.ok THEN Fail ELSE
    LET blockChecksum == ReadBytes(sipBlockTimestamp.rest, 2) IN IF ~blockChecksum.ok THEN Fail ELSE
    LET message == ReadMessageList(blockChecksum.rest, messagesInBlock.value) IN IF ~message.ok THEN Fail ELSE
    LET blockPadByte == Ok(message.rest, << >>) IN IF ~blockPadByte.ok THEN Fail ELSE
    Ok([ version                 |-> version.value,
         blockSize               |-> blockSize.value,
         dataFeedIndicator       |-> dataFeedIndicator.value,
         retransmissionIndicator |-> retransmissionIndicator.value,
         blockSequenceNumber     |-> blockSequenceNumber.value,
         sipBlockTimestamp       |-> sipBlockTimestamp.value,
         blockChecksum           |-> blockChecksum.value,
         message                 |-> message.value,
         blockPadByte            |-> blockPadByte.value ], blockPadByte.rest)

ZeroPacket ==
    [ version                 |-> [i \in 1 .. 1 |-> 0],
      blockSize               |-> [i \in 1 .. 2 |-> 0],
      dataFeedIndicator       |-> [i \in 1 .. 1 |-> 0],
      retransmissionIndicator |-> [i \in 1 .. 1 |-> 0],
      blockSequenceNumber     |-> [i \in 1 .. 4 |-> 0],
      sipBlockTimestamp       |-> ZeroSipBlockTimestamp,
      blockChecksum           |-> [i \in 1 .. 2 |-> 0],
      message                 |-> << >>,
      blockPadByte            |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.dataFeedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.retransmissionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sipBlockTimestamp = one] : one \in CheckedSipBlockTimestamp }
        \cup { [ZeroPacket EXCEPT !.blockChecksum = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }
        \cup { [ZeroPacket EXCEPT !.blockPadByte = one] : one \in SampleBytes }

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

(* Every Sip Block Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripSipBlockTimestamp ==
    \A message \in CheckedSipBlockTimestamp :
        LET read == DecodeSipBlockTimestamp(EncodeSipBlockTimestamp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp1 ==
    \A message \in CheckedTimestamp1 :
        LET read == DecodeTimestamp1(EncodeTimestamp1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfEndOfDayMessage ==
    \A message \in CheckedStartOfEndOfDayMessage :
        LET read == DecodeStartOfEndOfDayMessage(EncodeStartOfEndOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp12 ==
    \A message \in CheckedTimestamp12 :
        LET read == DecodeTimestamp12(EncodeTimestamp12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfEndOfDayMessage ==
    \A message \in CheckedEndOfEndOfDayMessage :
        LET read == DecodeEndOfEndOfDayMessage(EncodeEndOfEndOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp13 ==
    \A message \in CheckedTimestamp13 :
        LET read == DecodeTimestamp13(EncodeTimestamp13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfStartOfDayMessage ==
    \A message \in CheckedStartOfStartOfDayMessage :
        LET read == DecodeStartOfStartOfDayMessage(EncodeStartOfStartOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp14 ==
    \A message \in CheckedTimestamp14 :
        LET read == DecodeTimestamp14(EncodeTimestamp14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfStartOfDayMessage ==
    \A message \in CheckedEndOfStartOfDayMessage :
        LET read == DecodeEndOfStartOfDayMessage(EncodeEndOfStartOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Administrative Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdministrativeMessage ==
    \A message \in CheckedAdministrativeMessage :
        LET read == DecodeAdministrativeMessage(EncodeAdministrativeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp15 ==
    \A message \in CheckedTimestamp15 :
        LET read == DecodeTimestamp15(EncodeTimestamp15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfDayMessage ==
    \A message \in CheckedStartOfDayMessage :
        LET read == DecodeStartOfDayMessage(EncodeStartOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp16 ==
    \A message \in CheckedTimestamp16 :
        LET read == DecodeTimestamp16(EncodeTimestamp16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset Block Sequence Number Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetBlockSequenceNumberMessage ==
    \A message \in CheckedResetBlockSequenceNumberMessage :
        LET read == DecodeResetBlockSequenceNumberMessage(EncodeResetBlockSequenceNumberMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp17 ==
    \A message \in CheckedTimestamp17 :
        LET read == DecodeTimestamp17(EncodeTimestamp17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disaster Recovery Data Center Activation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDisasterRecoveryDataCenterActivationMessage ==
    \A message \in CheckedDisasterRecoveryDataCenterActivationMessage :
        LET read == DecodeDisasterRecoveryDataCenterActivationMessage(EncodeDisasterRecoveryDataCenterActivationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp18 ==
    \A message \in CheckedTimestamp18 :
        LET read == DecodeTimestamp18(EncodeTimestamp18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Line Integrity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLineIntegrityMessage ==
    \A message \in CheckedLineIntegrityMessage :
        LET read == DecodeLineIntegrityMessage(EncodeLineIntegrityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp19 ==
    \A message \in CheckedTimestamp19 :
        LET read == DecodeTimestamp19(EncodeTimestamp19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayMessage ==
    \A message \in CheckedEndOfDayMessage :
        LET read == DecodeEndOfDayMessage(EncodeEndOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripControlMessage ==
    \A message \in CheckedControlMessage :
        LET read == DecodeControlMessage(EncodeControlMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp110 ==
    \A message \in CheckedTimestamp110 :
        LET read == DecodeTimestamp110(EncodeTimestamp110(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMessage ==
    \A message \in CheckedIndexMessage :
        LET read == DecodeIndexMessage(EncodeIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp111 ==
    \A message \in CheckedTimestamp111 :
        LET read == DecodeTimestamp111(EncodeTimestamp111(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid And Offer Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBidAndOfferIndexMessage ==
    \A message \in CheckedBidAndOfferIndexMessage :
        LET read == DecodeBidAndOfferIndexMessage(EncodeBidAndOfferIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicesMessage ==
    \A message \in CheckedIndicesMessage :
        LET read == DecodeIndicesMessage(EncodeIndicesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp112 ==
    \A message \in CheckedTimestamp112 :
        LET read == DecodeTimestamp112(EncodeTimestamp112(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Decline Level Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerDeclineLevelStatusMessage ==
    \A message \in CheckedMarketWideCircuitBreakerDeclineLevelStatusMessage :
        LET read == DecodeMarketWideCircuitBreakerDeclineLevelStatusMessage(EncodeMarketWideCircuitBreakerDeclineLevelStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp113 ==
    \A message \in CheckedTimestamp113 :
        LET read == DecodeTimestamp113(EncodeTimestamp113(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerStatusMessage ==
    \A message \in CheckedMarketWideCircuitBreakerStatusMessage :
        LET read == DecodeMarketWideCircuitBreakerStatusMessage(EncodeMarketWideCircuitBreakerStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp114 ==
    \A message \in CheckedTimestamp114 :
        LET read == DecodeTimestamp114(EncodeTimestamp114(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participants decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipants ==
    \A message \in CheckedParticipants :
        LET read == DecodeParticipants(EncodeParticipants(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Approximate Adjusted Volume Market Center Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApproximateAdjustedVolumeMarketCenterMessage ==
    \A message \in CheckedApproximateAdjustedVolumeMarketCenterMessage :
        LET read == DecodeApproximateAdjustedVolumeMarketCenterMessage(EncodeApproximateAdjustedVolumeMarketCenterMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp115 ==
    \A message \in CheckedTimestamp115 :
        LET read == DecodeTimestamp115(EncodeTimestamp115(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Participants decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalParticipants ==
    \A message \in CheckedFractionalParticipants :
        LET read == DecodeFractionalParticipants(EncodeFractionalParticipants(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Approximate Adjusted Volume Market Center Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalApproximateAdjustedVolumeMarketCenterMessage ==
    \A message \in CheckedFractionalApproximateAdjustedVolumeMarketCenterMessage :
        LET read == DecodeFractionalApproximateAdjustedVolumeMarketCenterMessage(EncodeFractionalApproximateAdjustedVolumeMarketCenterMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp116 ==
    \A message \in CheckedTimestamp116 :
        LET read == DecodeTimestamp116(EncodeTimestamp116(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Approximate Trades And Total Dollar Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApproximateTradesAndTotalDollarValueMessage ==
    \A message \in CheckedApproximateTradesAndTotalDollarValueMessage :
        LET read == DecodeApproximateTradesAndTotalDollarValueMessage(EncodeApproximateTradesAndTotalDollarValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp117 ==
    \A message \in CheckedTimestamp117 :
        LET read == DecodeTimestamp117(EncodeTimestamp117(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Crossing Session Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossingSessionSummaryMessage ==
    \A message \in CheckedCrossingSessionSummaryMessage :
        LET read == DecodeCrossingSessionSummaryMessage(EncodeCrossingSessionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatusMessage ==
    \A message \in CheckedMarketStatusMessage :
        LET read == DecodeMarketStatusMessage(EncodeMarketStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp118 ==
    \A message \in CheckedTimestamp118 :
        LET read == DecodeTimestamp118(EncodeTimestamp118(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions ==
    \A message \in CheckedSaleConditions :
        LET read == DecodeSaleConditions(EncodeSaleConditions(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime ==
    \A message \in CheckedPriorDayTradeDateAndTime :
        LET read == DecodePriorDayTradeDateAndTime(EncodePriorDayTradeDateAndTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Corrected Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayCorrectedTrade ==
    \A message \in CheckedPriorDayCorrectedTrade :
        LET read == DecodePriorDayCorrectedTrade(EncodePriorDayCorrectedTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions2 ==
    \A message \in CheckedSaleConditions2 :
        LET read == DecodeSaleConditions2(EncodeSaleConditions2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime2 ==
    \A message \in CheckedPriorDayTradeDateAndTime2 :
        LET read == DecodePriorDayTradeDateAndTime2(EncodePriorDayTradeDateAndTime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Original Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayOriginalTrade ==
    \A message \in CheckedPriorDayOriginalTrade :
        LET read == DecodePriorDayOriginalTrade(EncodePriorDayOriginalTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeCorrectionMessage ==
    \A message \in CheckedPriorDayTradeCorrectionMessage :
        LET read == DecodePriorDayTradeCorrectionMessage(EncodePriorDayTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp119 ==
    \A message \in CheckedTimestamp119 :
        LET read == DecodeTimestamp119(EncodeTimestamp119(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions3 ==
    \A message \in CheckedSaleConditions3 :
        LET read == DecodeSaleConditions3(EncodeSaleConditions3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime3 ==
    \A message \in CheckedPriorDayTradeDateAndTime3 :
        LET read == DecodePriorDayTradeDateAndTime3(EncodePriorDayTradeDateAndTime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Prior Day Corrected Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalPriorDayCorrectedTrade ==
    \A message \in CheckedFractionalPriorDayCorrectedTrade :
        LET read == DecodeFractionalPriorDayCorrectedTrade(EncodeFractionalPriorDayCorrectedTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions4 ==
    \A message \in CheckedSaleConditions4 :
        LET read == DecodeSaleConditions4(EncodeSaleConditions4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime4 ==
    \A message \in CheckedPriorDayTradeDateAndTime4 :
        LET read == DecodePriorDayTradeDateAndTime4(EncodePriorDayTradeDateAndTime4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Prior Day Original Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalPriorDayOriginalTrade ==
    \A message \in CheckedFractionalPriorDayOriginalTrade :
        LET read == DecodeFractionalPriorDayOriginalTrade(EncodeFractionalPriorDayOriginalTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Prior Day Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalPriorDayTradeCorrectionMessage ==
    \A message \in CheckedFractionalPriorDayTradeCorrectionMessage :
        LET read == DecodeFractionalPriorDayTradeCorrectionMessage(EncodeFractionalPriorDayTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp120 ==
    \A message \in CheckedTimestamp120 :
        LET read == DecodeTimestamp120(EncodeTimestamp120(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions5 ==
    \A message \in CheckedSaleConditions5 :
        LET read == DecodeSaleConditions5(EncodeSaleConditions5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime5 ==
    \A message \in CheckedPriorDayTradeDateAndTime5 :
        LET read == DecodePriorDayTradeDateAndTime5(EncodePriorDayTradeDateAndTime5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeMessage ==
    \A message \in CheckedPriorDayTradeMessage :
        LET read == DecodePriorDayTradeMessage(EncodePriorDayTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp121 ==
    \A message \in CheckedTimestamp121 :
        LET read == DecodeTimestamp121(EncodeTimestamp121(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions6 ==
    \A message \in CheckedSaleConditions6 :
        LET read == DecodeSaleConditions6(EncodeSaleConditions6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime6 ==
    \A message \in CheckedPriorDayTradeDateAndTime6 :
        LET read == DecodePriorDayTradeDateAndTime6(EncodePriorDayTradeDateAndTime6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Prior Day Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalPriorDayTradeMessage ==
    \A message \in CheckedFractionalPriorDayTradeMessage :
        LET read == DecodeFractionalPriorDayTradeMessage(EncodeFractionalPriorDayTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp122 ==
    \A message \in CheckedTimestamp122 :
        LET read == DecodeTimestamp122(EncodeTimestamp122(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions7 ==
    \A message \in CheckedSaleConditions7 :
        LET read == DecodeSaleConditions7(EncodeSaleConditions7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime7 ==
    \A message \in CheckedPriorDayTradeDateAndTime7 :
        LET read == DecodePriorDayTradeDateAndTime7(EncodePriorDayTradeDateAndTime7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeCancelErrorMessage ==
    \A message \in CheckedPriorDayTradeCancelErrorMessage :
        LET read == DecodePriorDayTradeCancelErrorMessage(EncodePriorDayTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp123 ==
    \A message \in CheckedTimestamp123 :
        LET read == DecodeTimestamp123(EncodeTimestamp123(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions8 ==
    \A message \in CheckedSaleConditions8 :
        LET read == DecodeSaleConditions8(EncodeSaleConditions8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime8 ==
    \A message \in CheckedPriorDayTradeDateAndTime8 :
        LET read == DecodePriorDayTradeDateAndTime8(EncodePriorDayTradeDateAndTime8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Prior Day Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalPriorDayTradeCancelErrorMessage ==
    \A message \in CheckedFractionalPriorDayTradeCancelErrorMessage :
        LET read == DecodeFractionalPriorDayTradeCancelErrorMessage(EncodeFractionalPriorDayTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayMessage ==
    \A message \in CheckedPriorDayMessage :
        LET read == DecodePriorDayMessage(EncodePriorDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp124 ==
    \A message \in CheckedTimestamp124 :
        LET read == DecodeTimestamp124(EncodeTimestamp124(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Start Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedStartOfDaySummaryMessage ==
    \A message \in CheckedConsolidatedStartOfDaySummaryMessage :
        LET read == DecodeConsolidatedStartOfDaySummaryMessage(EncodeConsolidatedStartOfDaySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp125 ==
    \A message \in CheckedTimestamp125 :
        LET read == DecodeTimestamp125(EncodeTimestamp125(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participant Start Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipantStartOfDaySummaryMessage ==
    \A message \in CheckedParticipantStartOfDaySummaryMessage :
        LET read == DecodeParticipantStartOfDaySummaryMessage(EncodeParticipantStartOfDaySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp126 ==
    \A message \in CheckedTimestamp126 :
        LET read == DecodeTimestamp126(EncodeTimestamp126(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedEndOfDaySummaryMessage ==
    \A message \in CheckedConsolidatedEndOfDaySummaryMessage :
        LET read == DecodeConsolidatedEndOfDaySummaryMessage(EncodeConsolidatedEndOfDaySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp127 ==
    \A message \in CheckedTimestamp127 :
        LET read == DecodeTimestamp127(EncodeTimestamp127(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Consolidated End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalConsolidatedEndOfDaySummaryMessage ==
    \A message \in CheckedFractionalConsolidatedEndOfDaySummaryMessage :
        LET read == DecodeFractionalConsolidatedEndOfDaySummaryMessage(EncodeFractionalConsolidatedEndOfDaySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp128 ==
    \A message \in CheckedTimestamp128 :
        LET read == DecodeTimestamp128(EncodeTimestamp128(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participant End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipantEndOfDaySummaryMessage ==
    \A message \in CheckedParticipantEndOfDaySummaryMessage :
        LET read == DecodeParticipantEndOfDaySummaryMessage(EncodeParticipantEndOfDaySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp129 ==
    \A message \in CheckedTimestamp129 :
        LET read == DecodeTimestamp129(EncodeTimestamp129(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Participant End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalParticipantEndOfDaySummaryMessage ==
    \A message \in CheckedFractionalParticipantEndOfDaySummaryMessage :
        LET read == DecodeFractionalParticipantEndOfDaySummaryMessage(EncodeFractionalParticipantEndOfDaySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSummaryMessage ==
    \A message \in CheckedSummaryMessage :
        LET read == DecodeSummaryMessage(EncodeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp130 ==
    \A message \in CheckedTimestamp130 :
        LET read == DecodeTimestamp130(EncodeTimestamp130(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionStatusMessage ==
    \A message \in CheckedAuctionStatusMessage :
        LET read == DecodeAuctionStatusMessage(EncodeAuctionStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp131 ==
    \A message \in CheckedTimestamp131 :
        LET read == DecodeTimestamp131(EncodeTimestamp131(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions9 ==
    \A message \in CheckedSaleConditions9 :
        LET read == DecodeSaleConditions9(EncodeSaleConditions9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedTrade ==
    \A message \in CheckedCorrectedTrade :
        LET read == DecodeCorrectedTrade(EncodeCorrectedTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp2 ==
    \A message \in CheckedTimestamp2 :
        LET read == DecodeTimestamp2(EncodeTimestamp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions10 ==
    \A message \in CheckedSaleConditions10 :
        LET read == DecodeSaleConditions10(EncodeSaleConditions10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalTrade ==
    \A message \in CheckedOriginalTrade :
        LET read == DecodeOriginalTrade(EncodeOriginalTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Data decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedData ==
    \A message \in CheckedConsolidatedData :
        LET read == DecodeConsolidatedData(EncodeConsolidatedData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participant Data decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipantData ==
    \A message \in CheckedParticipantData :
        LET read == DecodeParticipantData(EncodeParticipantData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp132 ==
    \A message \in CheckedTimestamp132 :
        LET read == DecodeTimestamp132(EncodeTimestamp132(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions11 ==
    \A message \in CheckedSaleConditions11 :
        LET read == DecodeSaleConditions11(EncodeSaleConditions11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Corrected Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalCorrectedTrade ==
    \A message \in CheckedFractionalCorrectedTrade :
        LET read == DecodeFractionalCorrectedTrade(EncodeFractionalCorrectedTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp22 ==
    \A message \in CheckedTimestamp22 :
        LET read == DecodeTimestamp22(EncodeTimestamp22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions12 ==
    \A message \in CheckedSaleConditions12 :
        LET read == DecodeSaleConditions12(EncodeSaleConditions12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Original Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalOriginalTrade ==
    \A message \in CheckedFractionalOriginalTrade :
        LET read == DecodeFractionalOriginalTrade(EncodeFractionalOriginalTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Consolidated Data decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalConsolidatedData ==
    \A message \in CheckedFractionalConsolidatedData :
        LET read == DecodeFractionalConsolidatedData(EncodeFractionalConsolidatedData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Participant Data decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalParticipantData ==
    \A message \in CheckedFractionalParticipantData :
        LET read == DecodeFractionalParticipantData(EncodeFractionalParticipantData(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeCorrectionMessage ==
    \A message \in CheckedFractionalTradeCorrectionMessage :
        LET read == DecodeFractionalTradeCorrectionMessage(EncodeFractionalTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp133 ==
    \A message \in CheckedTimestamp133 :
        LET read == DecodeTimestamp133(EncodeTimestamp133(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions13 ==
    \A message \in CheckedSaleConditions13 :
        LET read == DecodeSaleConditions13(EncodeSaleConditions13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp23 ==
    \A message \in CheckedTimestamp23 :
        LET read == DecodeTimestamp23(EncodeTimestamp23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongTradeMessage ==
    \A message \in CheckedLongTradeMessage :
        LET read == DecodeLongTradeMessage(EncodeLongTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp134 ==
    \A message \in CheckedTimestamp134 :
        LET read == DecodeTimestamp134(EncodeTimestamp134(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions14 ==
    \A message \in CheckedSaleConditions14 :
        LET read == DecodeSaleConditions14(EncodeSaleConditions14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp24 ==
    \A message \in CheckedTimestamp24 :
        LET read == DecodeTimestamp24(EncodeTimestamp24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Long Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalLongTradeMessage ==
    \A message \in CheckedFractionalLongTradeMessage :
        LET read == DecodeFractionalLongTradeMessage(EncodeFractionalLongTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp135 ==
    \A message \in CheckedTimestamp135 :
        LET read == DecodeTimestamp135(EncodeTimestamp135(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp136 ==
    \A message \in CheckedTimestamp136 :
        LET read == DecodeTimestamp136(EncodeTimestamp136(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortTradeMessage ==
    \A message \in CheckedShortTradeMessage :
        LET read == DecodeShortTradeMessage(EncodeShortTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp137 ==
    \A message \in CheckedTimestamp137 :
        LET read == DecodeTimestamp137(EncodeTimestamp137(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Short Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalShortTradeMessage ==
    \A message \in CheckedFractionalShortTradeMessage :
        LET read == DecodeFractionalShortTradeMessage(EncodeFractionalShortTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp138 ==
    \A message \in CheckedTimestamp138 :
        LET read == DecodeTimestamp138(EncodeTimestamp138(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions15 ==
    \A message \in CheckedSaleConditions15 :
        LET read == DecodeSaleConditions15(EncodeSaleConditions15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp25 ==
    \A message \in CheckedTimestamp25 :
        LET read == DecodeTimestamp25(EncodeTimestamp25(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Data decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedData2 ==
    \A message \in CheckedConsolidatedData2 :
        LET read == DecodeConsolidatedData2(EncodeConsolidatedData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participant Data decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipantData2 ==
    \A message \in CheckedParticipantData2 :
        LET read == DecodeParticipantData2(EncodeParticipantData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorMessage ==
    \A message \in CheckedTradeCancelErrorMessage :
        LET read == DecodeTradeCancelErrorMessage(EncodeTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp139 ==
    \A message \in CheckedTimestamp139 :
        LET read == DecodeTimestamp139(EncodeTimestamp139(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Conditions decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleConditions16 ==
    \A message \in CheckedSaleConditions16 :
        LET read == DecodeSaleConditions16(EncodeSaleConditions16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp26 ==
    \A message \in CheckedTimestamp26 :
        LET read == DecodeTimestamp26(EncodeTimestamp26(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Consolidated Data decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalConsolidatedData2 ==
    \A message \in CheckedFractionalConsolidatedData2 :
        LET read == DecodeFractionalConsolidatedData2(EncodeFractionalConsolidatedData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Participant Data decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalParticipantData2 ==
    \A message \in CheckedFractionalParticipantData2 :
        LET read == DecodeFractionalParticipantData2(EncodeFractionalParticipantData2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fractional Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeCancelErrorMessage ==
    \A message \in CheckedFractionalTradeCancelErrorMessage :
        LET read == DecodeFractionalTradeCancelErrorMessage(EncodeFractionalTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
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

(* A Administrative Message Payload is selected by the Administrative Message Type it is written under *)
SelectsAdministrativeMessagePayload ==
    \A message \in CheckedAdministrativeMessagePayload :
        LET read == DecodeAdministrativeMessagePayload(message.tag, EncodeAdministrativeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Control Message Payload is selected by the Control Message Type it is written under *)
SelectsControlMessagePayload ==
    \A message \in CheckedControlMessagePayload :
        LET read == DecodeControlMessagePayload(message.tag, EncodeControlMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Indices Message Payload is selected by the Indices Message Type it is written under *)
SelectsIndicesMessagePayload ==
    \A message \in CheckedIndicesMessagePayload :
        LET read == DecodeIndicesMessagePayload(message.tag, EncodeIndicesMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Market Status Message Payload is selected by the Market Status Message Type it is written under *)
SelectsMarketStatusMessagePayload ==
    \A message \in CheckedMarketStatusMessagePayload :
        LET read == DecodeMarketStatusMessagePayload(message.tag, EncodeMarketStatusMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Prior Day Message Payload is selected by the Prior Day Message Type it is written under *)
SelectsPriorDayMessagePayload ==
    \A message \in CheckedPriorDayMessagePayload :
        LET read == DecodePriorDayMessagePayload(message.tag, EncodePriorDayMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Summary Message Payload is selected by the Summary Message Type it is written under *)
SelectsSummaryMessagePayload ==
    \A message \in CheckedSummaryMessagePayload :
        LET read == DecodeSummaryMessagePayload(message.tag, EncodeSummaryMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Trade Message Payload is selected by the Trade Message Type it is written under *)
SelectsTradeMessagePayload ==
    \A message \in CheckedTradeMessagePayload :
        LET read == DecodeTradeMessagePayload(message.tag, EncodeTradeMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Category Payload is selected by the Message Category it is written under *)
SelectsCategoryPayload ==
    \A message \in CheckedCategoryPayload :
        LET read == DecodeCategoryPayload(message.tag, EncodeCategoryPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
