-------------------------- MODULE Wse_Bonds_v6_8 ---------------------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie Warsaw Stock Exchange Bonds   *)
(* v6.8                                                                    *)
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
(* Note: a Delivery Flag of 16 to 255 says Message Buffer was transformed, *)
(* and one of 0 to 15 that it was not, so it is then read as it stands.    *)
(*                                                                         *)
(* Note: Accrued Interest Group is written as 31 slots, however many of    *)
(* them the count beside it says are in use.                               *)
(*                                                                         *)
(* Note: Message Buffer untransformed is as many Message as Number Msg     *)
(* Entries says, which is read beside the flag and handed to the choice:   *)
(* the count says how many the bytes hold, and transformed they hold a run *)
(* no reading of them states, so it is carried rather than written from    *)
(* the run.                                                                *)
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
(* Message Buffer                                                          *)
(***************************************************************************)

MessageBufferZlib ==
    [ transformed : SampleBytes ]

EncodeMessageBufferZlib(message) ==
    message.transformed

DecodeMessageBufferZlib(bytes) ==
    LET transformed == Ok(bytes, << >>) IN IF ~transformed.ok THEN Fail ELSE
    Ok([ transformed |-> transformed.value ], transformed.rest)

ZeroMessageBufferZlib ==
    [ transformed |-> << >> ]

(* Message Buffer at zero, then each field in turn at the values it is checked at *)
CheckedMessageBufferZlib ==
    { ZeroMessageBufferZlib }
        \cup { [ZeroMessageBufferZlib EXCEPT !.transformed = one] : one \in SampleBytes }

(***************************************************************************)
(* Accrued Interest Group: 8 bytes                                         *)
(***************************************************************************)

AccruedInterestGroup ==
    [ date            : Sample(4),
      accruedInterest : Sample(4) ]

EncodeAccruedInterestGroup(message) ==
    message.date
        \o message.accruedInterest

DecodeAccruedInterestGroup(bytes) ==
    LET date == ReadBytes(bytes, 4) IN IF ~date.ok THEN Fail ELSE
    LET accruedInterest == ReadBytes(date.rest, 4) IN IF ~accruedInterest.ok THEN Fail ELSE
    Ok([ date            |-> date.value,
         accruedInterest |-> accruedInterest.value ], accruedInterest.rest)

ZeroAccruedInterestGroup ==
    [ date            |-> [i \in 1 .. 4 |-> 0],
      accruedInterest |-> [i \in 1 .. 4 |-> 0] ]

(* Accrued Interest Group at zero, then each field in turn at the values it is checked at *)
CheckedAccruedInterestGroup ==
    { ZeroAccruedInterestGroup }
        \cup { [ZeroAccruedInterestGroup EXCEPT !.date = one] : one \in Sample(4) }
        \cup { [ZeroAccruedInterestGroup EXCEPT !.accruedInterest = one] : one \in Sample(4) }

(* A run of Accrued Interest Group, written one after another *)
RECURSIVE EncodeAccruedInterestGroupList(_)
EncodeAccruedInterestGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAccruedInterestGroup(Head(messages)) \o EncodeAccruedInterestGroupList(Tail(messages))

(* As many Accrued Interest Group as the field that counts them says *)
RECURSIVE ReadAccruedInterestGroupList(_, _)
ReadAccruedInterestGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAccruedInterestGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAccruedInterestGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Accrued Interest Group of each kind, for the lists that carry them *)
OneAccruedInterestGroup == { ZeroAccruedInterestGroup }

(* The 31 slots a run of Accrued Interest Group is written as, whatever the field beside it says are in use *)
SlotsAccruedInterestGroup == { [i \in 1 .. 31 |-> one] : one \in OneAccruedInterestGroup }

(***************************************************************************)
(* Accrued Interest Message                                                *)
(***************************************************************************)

AccruedInterestMessage ==
    [ symbolIndex              : Sample(4),
      sourceTime               : Sample(4),
      sourceSeqNum             : Sample(4),
      systemId                 : Sample(4),
      numberDays               : Sample(2),
      sourceTimeMicroSecs      : Sample(2),
      accruedInterestScaleCode : Sample(1),
      reserved3                : Sample(3),
      accruedInterestGroup     : SlotsAccruedInterestGroup ]

EncodeAccruedInterestMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.systemId
        \o message.numberDays
        \o message.sourceTimeMicroSecs
        \o message.accruedInterestScaleCode
        \o message.reserved3
        \o EncodeAccruedInterestGroupList(message.accruedInterestGroup)

DecodeAccruedInterestMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceSeqNum.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET numberDays == ReadBytes(systemId.rest, 2) IN IF ~numberDays.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(numberDays.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET accruedInterestScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~accruedInterestScaleCode.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(accruedInterestScaleCode.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    LET accruedInterestGroup == ReadAccruedInterestGroupList(reserved3.rest, 31) IN IF ~accruedInterestGroup.ok THEN Fail ELSE
    Ok([ symbolIndex              |-> symbolIndex.value,
         sourceTime               |-> sourceTime.value,
         sourceSeqNum             |-> sourceSeqNum.value,
         systemId                 |-> systemId.value,
         numberDays               |-> numberDays.value,
         sourceTimeMicroSecs      |-> sourceTimeMicroSecs.value,
         accruedInterestScaleCode |-> accruedInterestScaleCode.value,
         reserved3                |-> reserved3.value,
         accruedInterestGroup     |-> accruedInterestGroup.value ], accruedInterestGroup.rest)

ZeroAccruedInterestMessage ==
    [ symbolIndex              |-> [i \in 1 .. 4 |-> 0],
      sourceTime               |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum             |-> [i \in 1 .. 4 |-> 0],
      systemId                 |-> [i \in 1 .. 4 |-> 0],
      numberDays               |-> [i \in 1 .. 2 |-> 0],
      sourceTimeMicroSecs      |-> [i \in 1 .. 2 |-> 0],
      accruedInterestScaleCode |-> [i \in 1 .. 1 |-> 0],
      reserved3                |-> [i \in 1 .. 3 |-> 0],
      accruedInterestGroup     |-> [i \in 1 .. 31 |-> ZeroAccruedInterestGroup] ]

(* Accrued Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedAccruedInterestMessage ==
    { ZeroAccruedInterestMessage }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.numberDays = one] : one \in Sample(2) }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.accruedInterestScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }
        \cup { [ZeroAccruedInterestMessage EXCEPT !.accruedInterestGroup = one] : one \in SlotsAccruedInterestGroup }

(***************************************************************************)
(* Interest For Settlement Day Message: 40 bytes                           *)
(***************************************************************************)

InterestForSettlementDayMessage ==
    [ symbolIndex         : Sample(4),
      sourceTime          : Sample(4),
      sourceSeqNum        : Sample(4),
      systemId            : Sample(4),
      date                : Sample(4),
      settlementDate      : Sample(8),
      interest            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      currency            : Sample(3),
      interestScaleCode   : Sample(1),
      reserved2           : Sample(2) ]

EncodeInterestForSettlementDayMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.systemId
        \o message.date
        \o message.settlementDate
        \o message.interest
        \o message.sourceTimeMicroSecs
        \o message.currency
        \o message.interestScaleCode
        \o message.reserved2

DecodeInterestForSettlementDayMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceSeqNum.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET date == ReadBytes(systemId.rest, 4) IN IF ~date.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(date.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    LET interest == ReadBytes(settlementDate.rest, 4) IN IF ~interest.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(interest.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET currency == ReadBytes(sourceTimeMicroSecs.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET interestScaleCode == ReadBytes(currency.rest, 1) IN IF ~interestScaleCode.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(interestScaleCode.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceTime          |-> sourceTime.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         systemId            |-> systemId.value,
         date                |-> date.value,
         settlementDate      |-> settlementDate.value,
         interest            |-> interest.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         currency            |-> currency.value,
         interestScaleCode   |-> interestScaleCode.value,
         reserved2           |-> reserved2.value ], reserved2.rest)

ZeroInterestForSettlementDayMessage ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      date                |-> [i \in 1 .. 4 |-> 0],
      settlementDate      |-> [i \in 1 .. 8 |-> 0],
      interest            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      currency            |-> [i \in 1 .. 3 |-> 0],
      interestScaleCode   |-> [i \in 1 .. 1 |-> 0],
      reserved2           |-> [i \in 1 .. 2 |-> 0] ]

(* Interest For Settlement Day Message at zero, then each field in turn at the values it is checked at *)
CheckedInterestForSettlementDayMessage ==
    { ZeroInterestForSettlementDayMessage }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.date = one] : one \in Sample(4) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.settlementDate = one] : one \in Sample(8) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.interest = one] : one \in Sample(4) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.interestScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroInterestForSettlementDayMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

AccruedInterestMessageCode == 601  \* 0x259
InterestForSettlementDayMessageCode == 602  \* 0x25a

Payload ==
    [ tag : {AccruedInterestMessageCode}, body : AccruedInterestMessage ]
        \cup [ tag : {InterestForSettlementDayMessageCode}, body : InterestForSettlementDayMessage ]

EncodePayload(message) ==
    CASE message.tag = AccruedInterestMessageCode -> EncodeAccruedInterestMessage(message.body)
      [] message.tag = InterestForSettlementDayMessageCode -> EncodeInterestForSettlementDayMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AccruedInterestMessageCode -> DecodeAccruedInterestMessage(bytes)
              [] tag = InterestForSettlementDayMessageCode -> DecodeInterestForSettlementDayMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AccruedInterestMessageCode, body |-> ZeroAccruedInterestMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AccruedInterestMessageCode, body |-> one] : one \in CheckedAccruedInterestMessage }
        \cup { [tag |-> InterestForSettlementDayMessageCode, body |-> one] : one \in CheckedInterestForSettlementDayMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> AccruedInterestMessageCode, body |-> ZeroAccruedInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InterestForSettlementDayMessageCode, body |-> ZeroInterestForSettlementDayMessage]] }

(***************************************************************************)
(* Message Buffer, selected by Delivery Flag                               *)
(***************************************************************************)

MessageBufferZlibCode == 16  \* 0x10
MessageBufferPlainCode == 0  \* 0x00

MessageBufferBody ==
    [ tag : 16 .. 255, body : MessageBufferZlib ]
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

EncodeMessageBufferBody(message) ==
    CASE message.tag \in 16 .. 255 -> EncodeMessageBufferZlib(message.body)
      [] message.tag \in 0 .. 15 -> EncodeMessageList(message.body)

(* How many Message a Message Buffer holds, which is what Number Msg Entries states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountMessageBufferBody(choice, stated) ==
    CASE choice.tag \in 16 .. 255 -> stated
      [] choice.tag \in 0 .. 15 -> Len(choice.body)

DecodeMessageBufferBody(tag, count, bytes) ==
    LET read ==
            CASE tag \in 16 .. 255 -> DecodeMessageBufferZlib(bytes)
              [] tag \in 0 .. 15 -> ReadMessageList(bytes, count)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBufferBody == [tag |-> MessageBufferZlibCode, body |-> ZeroMessageBufferZlib]

(* Each Message Buffer in turn, at the values the message it names is checked at *)
CheckedMessageBufferBody ==
    { [tag |-> tag, body |-> one] : tag \in {16, 255}, one \in CheckedMessageBufferZlib }
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetLength         : Sample(2),
      packetType           : Sample(2),
      packetSequenceNumber : Sample(4),
      sendTime             : Sample(4),
      serviceId            : Sample(2),
      numberMsgEntries     : 0 .. 255,
      messageBuffer        : MessageBufferBody ]

EncodePacket(message) ==
    message.packetLength
        \o message.packetType
        \o message.packetSequenceNumber
        \o message.sendTime
        \o message.serviceId
        \o EncodeUIntBE(message.messageBuffer.tag, 1)
        \o EncodeUIntBE(message.numberMsgEntries, 1)
        \o EncodeMessageBufferBody(message.messageBuffer)

DecodePacket(bytes) ==
    LET packetLength == ReadBytes(bytes, 2) IN IF ~packetLength.ok THEN Fail ELSE
    LET packetType == ReadBytes(packetLength.rest, 2) IN IF ~packetType.ok THEN Fail ELSE
    LET packetSequenceNumber == ReadBytes(packetType.rest, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(packetSequenceNumber.rest, 4) IN IF ~sendTime.ok THEN Fail ELSE
    LET serviceId == ReadBytes(sendTime.rest, 2) IN IF ~serviceId.ok THEN Fail ELSE
    LET deliveryFlag == ReadUIntBE(serviceId.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgEntries == ReadUIntBE(deliveryFlag.rest, 1) IN IF ~numberMsgEntries.ok THEN Fail ELSE
    LET messageBuffer == DecodeMessageBufferBody(deliveryFlag.value, numberMsgEntries.value, numberMsgEntries.rest) IN IF ~messageBuffer.ok THEN Fail ELSE
    Ok([ packetLength         |-> packetLength.value,
         packetType           |-> packetType.value,
         packetSequenceNumber |-> packetSequenceNumber.value,
         sendTime             |-> sendTime.value,
         serviceId            |-> serviceId.value,
         numberMsgEntries     |-> numberMsgEntries.value,
         messageBuffer        |-> messageBuffer.value ], messageBuffer.rest)

ZeroPacket ==
    [ packetLength         |-> [i \in 1 .. 2 |-> 0],
      packetType           |-> [i \in 1 .. 2 |-> 0],
      packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime             |-> [i \in 1 .. 4 |-> 0],
      serviceId            |-> [i \in 1 .. 2 |-> 0],
      numberMsgEntries     |-> 0,
      messageBuffer        |-> ZeroMessageBufferBody ]

(* Packet at zero, then each field in turn at the values it is checked at *)
(* Number Msg Entries is varied with the Message Buffer it counts, which is read as many as it says *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetLength = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.serviceId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = CountMessageBufferBody(one, 0), !.messageBuffer = one] : one \in CheckedMessageBufferBody }

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

(* Every Message Buffer decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBufferZlib ==
    \A message \in CheckedMessageBufferZlib :
        LET read == DecodeMessageBufferZlib(EncodeMessageBufferZlib(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Accrued Interest Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAccruedInterestGroup ==
    \A message \in CheckedAccruedInterestGroup :
        LET read == DecodeAccruedInterestGroup(EncodeAccruedInterestGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Accrued Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccruedInterestMessage ==
    \A message \in CheckedAccruedInterestMessage :
        LET read == DecodeAccruedInterestMessage(EncodeAccruedInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Interest For Settlement Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInterestForSettlementDayMessage ==
    \A message \in CheckedInterestForSettlementDayMessage :
        LET read == DecodeInterestForSettlementDayMessage(EncodeInterestForSettlementDayMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Buffer is selected by the Delivery Flag it is written under *)
SelectsMessageBufferBody ==
    \A message \in CheckedMessageBufferBody :
        LET sent == EncodeMessageBufferBody(message)
            read == DecodeMessageBufferBody(message.tag, CountMessageBufferBody(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
