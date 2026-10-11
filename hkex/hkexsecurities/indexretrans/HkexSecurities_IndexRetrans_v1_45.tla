----------------- MODULE HkexSecurities_IndexRetrans_v1_45 -----------------
(***************************************************************************)
(* Hong Kong Exchanges and Clearing Orion Market Data Cash Index           *)
(* Retransmission v1.45                                                    *)
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
(* Disaster Recovery Signal Message: 4 bytes                               *)
(***************************************************************************)

DisasterRecoverySignalMessage ==
    [ drStatus : Sample(4) ]

EncodeDisasterRecoverySignalMessage(message) ==
    message.drStatus

DecodeDisasterRecoverySignalMessage(bytes) ==
    LET drStatus == ReadBytes(bytes, 4) IN IF ~drStatus.ok THEN Fail ELSE
    Ok([ drStatus |-> drStatus.value ], drStatus.rest)

ZeroDisasterRecoverySignalMessage ==
    [ drStatus |-> [i \in 1 .. 4 |-> 0] ]

(* Disaster Recovery Signal Message at zero, then each field in turn at the values it is checked at *)
CheckedDisasterRecoverySignalMessage ==
    { ZeroDisasterRecoverySignalMessage }
        \cup { [ZeroDisasterRecoverySignalMessage EXCEPT !.drStatus = one] : one \in Sample(4) }

(***************************************************************************)
(* Index Definition Message: 16 bytes                                      *)
(***************************************************************************)

IndexDefinitionMessage ==
    [ indexCode    : Sample(11),
      indexSource  : Sample(1),
      currencyCode : Sample(3),
      filler1      : Sample(1) ]

EncodeIndexDefinitionMessage(message) ==
    message.indexCode
        \o message.indexSource
        \o message.currencyCode
        \o message.filler1

DecodeIndexDefinitionMessage(bytes) ==
    LET indexCode == ReadBytes(bytes, 11) IN IF ~indexCode.ok THEN Fail ELSE
    LET indexSource == ReadBytes(indexCode.rest, 1) IN IF ~indexSource.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(indexSource.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET filler1 == ReadBytes(currencyCode.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ indexCode    |-> indexCode.value,
         indexSource  |-> indexSource.value,
         currencyCode |-> currencyCode.value,
         filler1      |-> filler1.value ], filler1.rest)

ZeroIndexDefinitionMessage ==
    [ indexCode    |-> [i \in 1 .. 11 |-> 0],
      indexSource  |-> [i \in 1 .. 1 |-> 0],
      currencyCode |-> [i \in 1 .. 3 |-> 0],
      filler1      |-> [i \in 1 .. 1 |-> 0] ]

(* Index Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexDefinitionMessage ==
    { ZeroIndexDefinitionMessage }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.indexCode = one] : one \in Sample(11) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.indexSource = one] : one \in Sample(1) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.filler1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Data Message: 108 bytes                                           *)
(***************************************************************************)

IndexDataMessage ==
    [ indexCode        : Sample(11),
      indexStatus      : Sample(1),
      indexTime        : Sample(8),
      indexValue       : Sample(8),
      netChgPrevDay    : Sample(8),
      highValue        : Sample(8),
      lowValue         : Sample(8),
      easValue         : Sample(8),
      indexTurnover    : Sample(8),
      openingValue     : Sample(8),
      closingValue     : Sample(8),
      previousSesClose : Sample(8),
      indexVolume      : Sample(8),
      netChgPrevDayPct : Sample(4),
      exception        : Sample(1),
      filler3          : Sample(3) ]

EncodeIndexDataMessage(message) ==
    message.indexCode
        \o message.indexStatus
        \o message.indexTime
        \o message.indexValue
        \o message.netChgPrevDay
        \o message.highValue
        \o message.lowValue
        \o message.easValue
        \o message.indexTurnover
        \o message.openingValue
        \o message.closingValue
        \o message.previousSesClose
        \o message.indexVolume
        \o message.netChgPrevDayPct
        \o message.exception
        \o message.filler3

DecodeIndexDataMessage(bytes) ==
    LET indexCode == ReadBytes(bytes, 11) IN IF ~indexCode.ok THEN Fail ELSE
    LET indexStatus == ReadBytes(indexCode.rest, 1) IN IF ~indexStatus.ok THEN Fail ELSE
    LET indexTime == ReadBytes(indexStatus.rest, 8) IN IF ~indexTime.ok THEN Fail ELSE
    LET indexValue == ReadBytes(indexTime.rest, 8) IN IF ~indexValue.ok THEN Fail ELSE
    LET netChgPrevDay == ReadBytes(indexValue.rest, 8) IN IF ~netChgPrevDay.ok THEN Fail ELSE
    LET highValue == ReadBytes(netChgPrevDay.rest, 8) IN IF ~highValue.ok THEN Fail ELSE
    LET lowValue == ReadBytes(highValue.rest, 8) IN IF ~lowValue.ok THEN Fail ELSE
    LET easValue == ReadBytes(lowValue.rest, 8) IN IF ~easValue.ok THEN Fail ELSE
    LET indexTurnover == ReadBytes(easValue.rest, 8) IN IF ~indexTurnover.ok THEN Fail ELSE
    LET openingValue == ReadBytes(indexTurnover.rest, 8) IN IF ~openingValue.ok THEN Fail ELSE
    LET closingValue == ReadBytes(openingValue.rest, 8) IN IF ~closingValue.ok THEN Fail ELSE
    LET previousSesClose == ReadBytes(closingValue.rest, 8) IN IF ~previousSesClose.ok THEN Fail ELSE
    LET indexVolume == ReadBytes(previousSesClose.rest, 8) IN IF ~indexVolume.ok THEN Fail ELSE
    LET netChgPrevDayPct == ReadBytes(indexVolume.rest, 4) IN IF ~netChgPrevDayPct.ok THEN Fail ELSE
    LET exception == ReadBytes(netChgPrevDayPct.rest, 1) IN IF ~exception.ok THEN Fail ELSE
    LET filler3 == ReadBytes(exception.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ indexCode        |-> indexCode.value,
         indexStatus      |-> indexStatus.value,
         indexTime        |-> indexTime.value,
         indexValue       |-> indexValue.value,
         netChgPrevDay    |-> netChgPrevDay.value,
         highValue        |-> highValue.value,
         lowValue         |-> lowValue.value,
         easValue         |-> easValue.value,
         indexTurnover    |-> indexTurnover.value,
         openingValue     |-> openingValue.value,
         closingValue     |-> closingValue.value,
         previousSesClose |-> previousSesClose.value,
         indexVolume      |-> indexVolume.value,
         netChgPrevDayPct |-> netChgPrevDayPct.value,
         exception        |-> exception.value,
         filler3          |-> filler3.value ], filler3.rest)

ZeroIndexDataMessage ==
    [ indexCode        |-> [i \in 1 .. 11 |-> 0],
      indexStatus      |-> [i \in 1 .. 1 |-> 0],
      indexTime        |-> [i \in 1 .. 8 |-> 0],
      indexValue       |-> [i \in 1 .. 8 |-> 0],
      netChgPrevDay    |-> [i \in 1 .. 8 |-> 0],
      highValue        |-> [i \in 1 .. 8 |-> 0],
      lowValue         |-> [i \in 1 .. 8 |-> 0],
      easValue         |-> [i \in 1 .. 8 |-> 0],
      indexTurnover    |-> [i \in 1 .. 8 |-> 0],
      openingValue     |-> [i \in 1 .. 8 |-> 0],
      closingValue     |-> [i \in 1 .. 8 |-> 0],
      previousSesClose |-> [i \in 1 .. 8 |-> 0],
      indexVolume      |-> [i \in 1 .. 8 |-> 0],
      netChgPrevDayPct |-> [i \in 1 .. 4 |-> 0],
      exception        |-> [i \in 1 .. 1 |-> 0],
      filler3          |-> [i \in 1 .. 3 |-> 0] ]

(* Index Data Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexDataMessage ==
    { ZeroIndexDataMessage }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexCode = one] : one \in Sample(11) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexStatus = one] : one \in Sample(1) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.netChgPrevDay = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.highValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.lowValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.easValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexTurnover = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.openingValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.closingValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.previousSesClose = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.indexVolume = one] : one \in Sample(8) }
        \cup { [ZeroIndexDataMessage EXCEPT !.netChgPrevDayPct = one] : one \in Sample(4) }
        \cup { [ZeroIndexDataMessage EXCEPT !.exception = one] : one \in Sample(1) }
        \cup { [ZeroIndexDataMessage EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Refresh Complete Message: 4 bytes                                       *)
(***************************************************************************)

RefreshCompleteMessage ==
    [ lastSeqNum : Sample(4) ]

EncodeRefreshCompleteMessage(message) ==
    message.lastSeqNum

DecodeRefreshCompleteMessage(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroRefreshCompleteMessage ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Refresh Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshCompleteMessage ==
    { ZeroRefreshCompleteMessage }
        \cup { [ZeroRefreshCompleteMessage EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Message: 12 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ username : Sample(12) ]

EncodeLogonMessage(message) ==
    message.username

DecodeLogonMessage(bytes) ==
    LET username == ReadBytes(bytes, 12) IN IF ~username.ok THEN Fail ELSE
    Ok([ username |-> username.value ], username.rest)

ZeroLogonMessage ==
    [ username |-> [i \in 1 .. 12 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.username = one] : one \in Sample(12) }

(***************************************************************************)
(* Logon Response Message: 4 bytes                                         *)
(***************************************************************************)

LogonResponseMessage ==
    [ sessionStatus : Sample(1),
      filler3       : Sample(3) ]

EncodeLogonResponseMessage(message) ==
    message.sessionStatus
        \o message.filler3

DecodeLogonResponseMessage(bytes) ==
    LET sessionStatus == ReadBytes(bytes, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET filler3 == ReadBytes(sessionStatus.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ sessionStatus |-> sessionStatus.value,
         filler3       |-> filler3.value ], filler3.rest)

ZeroLogonResponseMessage ==
    [ sessionStatus |-> [i \in 1 .. 1 |-> 0],
      filler3       |-> [i \in 1 .. 3 |-> 0] ]

(* Logon Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponseMessage ==
    { ZeroLogonResponseMessage }
        \cup { [ZeroLogonResponseMessage EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Retransmission Request Message: 12 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ channelId   : Sample(2),
      filler2     : Sample(2),
      beginSeqNum : Sample(4),
      endSeqNum   : Sample(4) ]

EncodeRetransmissionRequestMessage(message) ==
    message.channelId
        \o message.filler2
        \o message.beginSeqNum
        \o message.endSeqNum

DecodeRetransmissionRequestMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET filler2 == ReadBytes(channelId.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(filler2.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ channelId   |-> channelId.value,
         filler2     |-> filler2.value,
         beginSeqNum |-> beginSeqNum.value,
         endSeqNum   |-> endSeqNum.value ], endSeqNum.rest)

ZeroRetransmissionRequestMessage ==
    [ channelId   |-> [i \in 1 .. 2 |-> 0],
      filler2     |-> [i \in 1 .. 2 |-> 0],
      beginSeqNum |-> [i \in 1 .. 4 |-> 0],
      endSeqNum   |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmission Response Message: 12 bytes                               *)
(***************************************************************************)

RetransmissionResponseMessage ==
    [ channelId     : Sample(2),
      retransStatus : Sample(1),
      filler1       : Sample(1),
      beginSeqNum   : Sample(4),
      endSeqNum     : Sample(4) ]

EncodeRetransmissionResponseMessage(message) ==
    message.channelId
        \o message.retransStatus
        \o message.filler1
        \o message.beginSeqNum
        \o message.endSeqNum

DecodeRetransmissionResponseMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET retransStatus == ReadBytes(channelId.rest, 1) IN IF ~retransStatus.ok THEN Fail ELSE
    LET filler1 == ReadBytes(retransStatus.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(filler1.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ channelId     |-> channelId.value,
         retransStatus |-> retransStatus.value,
         filler1       |-> filler1.value,
         beginSeqNum   |-> beginSeqNum.value,
         endSeqNum     |-> endSeqNum.value ], endSeqNum.rest)

ZeroRetransmissionResponseMessage ==
    [ channelId     |-> [i \in 1 .. 2 |-> 0],
      retransStatus |-> [i \in 1 .. 1 |-> 0],
      filler1       |-> [i \in 1 .. 1 |-> 0],
      beginSeqNum   |-> [i \in 1 .. 4 |-> 0],
      endSeqNum     |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionResponseMessage ==
    { ZeroRetransmissionResponseMessage }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.retransStatus = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
DisasterRecoverySignalMessageCode == 105  \* 0x69
IndexDefinitionMessageCode == 70  \* 0x46
IndexDataMessageCode == 71  \* 0x47
RefreshCompleteMessageCode == 203  \* 0xcb
LogonMessageCode == 101  \* 0x65
LogonResponseMessageCode == 102  \* 0x66
RetransmissionRequestMessageCode == 201  \* 0xc9
RetransmissionResponseMessageCode == 202  \* 0xca

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {DisasterRecoverySignalMessageCode}, body : DisasterRecoverySignalMessage ]
        \cup [ tag : {IndexDefinitionMessageCode}, body : IndexDefinitionMessage ]
        \cup [ tag : {IndexDataMessageCode}, body : IndexDataMessage ]
        \cup [ tag : {RefreshCompleteMessageCode}, body : RefreshCompleteMessage ]
        \cup [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {RetransmissionResponseMessageCode}, body : RetransmissionResponseMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = DisasterRecoverySignalMessageCode -> EncodeDisasterRecoverySignalMessage(message.body)
      [] message.tag = IndexDefinitionMessageCode -> EncodeIndexDefinitionMessage(message.body)
      [] message.tag = IndexDataMessageCode -> EncodeIndexDataMessage(message.body)
      [] message.tag = RefreshCompleteMessageCode -> EncodeRefreshCompleteMessage(message.body)
      [] message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = RetransmissionResponseMessageCode -> EncodeRetransmissionResponseMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = DisasterRecoverySignalMessageCode -> DecodeDisasterRecoverySignalMessage(bytes)
              [] tag = IndexDefinitionMessageCode -> DecodeIndexDefinitionMessage(bytes)
              [] tag = IndexDataMessageCode -> DecodeIndexDataMessage(bytes)
              [] tag = RefreshCompleteMessageCode -> DecodeRefreshCompleteMessage(bytes)
              [] tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = RetransmissionResponseMessageCode -> DecodeRetransmissionResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> DisasterRecoverySignalMessageCode, body |-> one] : one \in CheckedDisasterRecoverySignalMessage }
        \cup { [tag |-> IndexDefinitionMessageCode, body |-> one] : one \in CheckedIndexDefinitionMessage }
        \cup { [tag |-> IndexDataMessageCode, body |-> one] : one \in CheckedIndexDataMessage }
        \cup { [tag |-> RefreshCompleteMessageCode, body |-> one] : one \in CheckedRefreshCompleteMessage }
        \cup { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> RetransmissionResponseMessageCode, body |-> one] : one \in CheckedRetransmissionResponseMessage }

(***************************************************************************)
(* Message, framed by Msg Size                                             *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Msg Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DisasterRecoverySignalMessageCode, body |-> ZeroDisasterRecoverySignalMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexDefinitionMessageCode, body |-> ZeroIndexDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexDataMessageCode, body |-> ZeroIndexDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RefreshCompleteMessageCode, body |-> ZeroRefreshCompleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionResponseMessageCode, body |-> ZeroRetransmissionResponseMessage]] }

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

(* Every Disaster Recovery Signal Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDisasterRecoverySignalMessage ==
    \A message \in CheckedDisasterRecoverySignalMessage :
        LET read == DecodeDisasterRecoverySignalMessage(EncodeDisasterRecoverySignalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexDefinitionMessage ==
    \A message \in CheckedIndexDefinitionMessage :
        LET read == DecodeIndexDefinitionMessage(EncodeIndexDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexDataMessage ==
    \A message \in CheckedIndexDataMessage :
        LET read == DecodeIndexDataMessage(EncodeIndexDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshCompleteMessage ==
    \A message \in CheckedRefreshCompleteMessage :
        LET read == DecodeRefreshCompleteMessage(EncodeRefreshCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonResponseMessage ==
    \A message \in CheckedLogonResponseMessage :
        LET read == DecodeLogonResponseMessage(EncodeLogonResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionResponseMessage ==
    \A message \in CheckedRetransmissionResponseMessage :
        LET read == DecodeRetransmissionResponseMessage(EncodeRetransmissionResponseMessage(message))
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

(* Msg Size is written from the bytes it frames *)
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
