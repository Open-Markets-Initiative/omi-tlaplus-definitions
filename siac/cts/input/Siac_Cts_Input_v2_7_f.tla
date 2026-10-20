----------------------- MODULE Siac_Cts_Input_v2_7_f -----------------------
(***************************************************************************)
(* The Securities Industry Automation Corporation  v2.7.f                  *)
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
(* Rejection Message: 14 bytes                                             *)
(***************************************************************************)

RejectionMessage ==
    [ errorCode                  : Sample(1),
      blockSequenceNumber        : Sample(4),
      participantReferenceNumber : Sample(8),
      messageId                  : Sample(1) ]

EncodeRejectionMessage(message) ==
    message.errorCode
        \o message.blockSequenceNumber
        \o message.participantReferenceNumber
        \o message.messageId

DecodeRejectionMessage(bytes) ==
    LET errorCode == ReadBytes(bytes, 1) IN IF ~errorCode.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(errorCode.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(blockSequenceNumber.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET messageId == ReadBytes(participantReferenceNumber.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    Ok([ errorCode                  |-> errorCode.value,
         blockSequenceNumber        |-> blockSequenceNumber.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         messageId                  |-> messageId.value ], messageId.rest)

ZeroRejectionMessage ==
    [ errorCode                  |-> [i \in 1 .. 1 |-> 0],
      blockSequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      messageId                  |-> [i \in 1 .. 1 |-> 0] ]

(* Rejection Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectionMessage ==
    { ZeroRejectionMessage }
        \cup { [ZeroRejectionMessage EXCEPT !.errorCode = one] : one \in Sample(1) }
        \cup { [ZeroRejectionMessage EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRejectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRejectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }

(***************************************************************************)
(* Warning Message: 12 bytes                                               *)
(***************************************************************************)

WarningMessage ==
    [ previousBlockSequenceNumber        : Sample(4),
      previousParticipantReferenceNumber : Sample(8) ]

EncodeWarningMessage(message) ==
    message.previousBlockSequenceNumber
        \o message.previousParticipantReferenceNumber

DecodeWarningMessage(bytes) ==
    LET previousBlockSequenceNumber == ReadBytes(bytes, 4) IN IF ~previousBlockSequenceNumber.ok THEN Fail ELSE
    LET previousParticipantReferenceNumber == ReadBytes(previousBlockSequenceNumber.rest, 8) IN IF ~previousParticipantReferenceNumber.ok THEN Fail ELSE
    Ok([ previousBlockSequenceNumber        |-> previousBlockSequenceNumber.value,
         previousParticipantReferenceNumber |-> previousParticipantReferenceNumber.value ], previousParticipantReferenceNumber.rest)

ZeroWarningMessage ==
    [ previousBlockSequenceNumber        |-> [i \in 1 .. 4 |-> 0],
      previousParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Warning Message at zero, then each field in turn at the values it is checked at *)
CheckedWarningMessage ==
    { ZeroWarningMessage }
        \cup { [ZeroWarningMessage EXCEPT !.previousBlockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroWarningMessage EXCEPT !.previousParticipantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

RejectionMessageCode == 82  \* "R"
WarningMessageCode == 87  \* "W"

AdministrativeMessagePayload ==
    [ tag : {RejectionMessageCode}, body : RejectionMessage ]
        \cup [ tag : {WarningMessageCode}, body : WarningMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = RejectionMessageCode -> EncodeRejectionMessage(message.body)
      [] message.tag = WarningMessageCode -> EncodeWarningMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = RejectionMessageCode -> DecodeRejectionMessage(bytes)
              [] tag = WarningMessageCode -> DecodeWarningMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> RejectionMessageCode, body |-> ZeroRejectionMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> RejectionMessageCode, body |-> one] : one \in CheckedRejectionMessage }
        \cup { [tag |-> WarningMessageCode, body |-> one] : one \in CheckedWarningMessage }

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
(* Sequence Information And Message Count Response Message: 20 bytes       *)
(***************************************************************************)

SequenceInformationAndMessageCountResponseMessage ==
    [ currentBlockSequenceNumber     : Sample(4),
      lastParticipantReferenceNumber : Sample(8),
      messageCount                   : Sample(8) ]

EncodeSequenceInformationAndMessageCountResponseMessage(message) ==
    message.currentBlockSequenceNumber
        \o message.lastParticipantReferenceNumber
        \o message.messageCount

DecodeSequenceInformationAndMessageCountResponseMessage(bytes) ==
    LET currentBlockSequenceNumber == ReadBytes(bytes, 4) IN IF ~currentBlockSequenceNumber.ok THEN Fail ELSE
    LET lastParticipantReferenceNumber == ReadBytes(currentBlockSequenceNumber.rest, 8) IN IF ~lastParticipantReferenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadBytes(lastParticipantReferenceNumber.rest, 8) IN IF ~messageCount.ok THEN Fail ELSE
    Ok([ currentBlockSequenceNumber     |-> currentBlockSequenceNumber.value,
         lastParticipantReferenceNumber |-> lastParticipantReferenceNumber.value,
         messageCount                   |-> messageCount.value ], messageCount.rest)

ZeroSequenceInformationAndMessageCountResponseMessage ==
    [ currentBlockSequenceNumber     |-> [i \in 1 .. 4 |-> 0],
      lastParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      messageCount                   |-> [i \in 1 .. 8 |-> 0] ]

(* Sequence Information And Message Count Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceInformationAndMessageCountResponseMessage ==
    { ZeroSequenceInformationAndMessageCountResponseMessage }
        \cup { [ZeroSequenceInformationAndMessageCountResponseMessage EXCEPT !.currentBlockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSequenceInformationAndMessageCountResponseMessage EXCEPT !.lastParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequenceInformationAndMessageCountResponseMessage EXCEPT !.messageCount = one] : one \in Sample(8) }

(***************************************************************************)
(* Test Message: 256 bytes                                                 *)
(***************************************************************************)

TestMessage ==
    [ data : Sample(256) ]

EncodeTestMessage(message) ==
    message.data

DecodeTestMessage(bytes) ==
    LET data == ReadBytes(bytes, 256) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroTestMessage ==
    [ data |-> [i \in 1 .. 256 |-> 0] ]

(* Test Message at zero, then each field in turn at the values it is checked at *)
CheckedTestMessage ==
    { ZeroTestMessage }
        \cup { [ZeroTestMessage EXCEPT !.data = one] : one \in Sample(256) }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 65  \* "A"
SequenceInformationAndMessageCountInquiryMessageCode == 73  \* "I"
SequenceInformationAndMessageCountResponseMessageCode == 78  \* "N"
LineIntegrityMessageCode == 84  \* "T"
EndOfDayMessageCode == 90  \* "Z"
TestMessageCode == 53  \* "5"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceInformationAndMessageCountInquiryMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceInformationAndMessageCountResponseMessageCode}, body : SequenceInformationAndMessageCountResponseMessage ]
        \cup [ tag : {LineIntegrityMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfDayMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestMessageCode}, body : TestMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> << >>
      [] message.tag = SequenceInformationAndMessageCountInquiryMessageCode -> << >>
      [] message.tag = SequenceInformationAndMessageCountResponseMessageCode -> EncodeSequenceInformationAndMessageCountResponseMessage(message.body)
      [] message.tag = LineIntegrityMessageCode -> << >>
      [] message.tag = EndOfDayMessageCode -> << >>
      [] message.tag = TestMessageCode -> EncodeTestMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceInformationAndMessageCountInquiryMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceInformationAndMessageCountResponseMessageCode -> DecodeSequenceInformationAndMessageCountResponseMessage(bytes)
              [] tag = LineIntegrityMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfDayMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TestMessageCode -> DecodeTestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> [empty |-> 0]]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceInformationAndMessageCountInquiryMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceInformationAndMessageCountResponseMessageCode, body |-> one] : one \in CheckedSequenceInformationAndMessageCountResponseMessage }
        \cup { [tag |-> LineIntegrityMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfDayMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestMessageCode, body |-> one] : one \in CheckedTestMessage }

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
(* Index Message: 19 bytes                                                 *)
(***************************************************************************)

IndexMessage ==
    [ indexSymbol : Sample(11),
      indexValue  : Sample(8) ]

EncodeIndexMessage(message) ==
    message.indexSymbol
        \o message.indexValue

DecodeIndexMessage(bytes) ==
    LET indexSymbol == ReadBytes(bytes, 11) IN IF ~indexSymbol.ok THEN Fail ELSE
    LET indexValue == ReadBytes(indexSymbol.rest, 8) IN IF ~indexValue.ok THEN Fail ELSE
    Ok([ indexSymbol |-> indexSymbol.value,
         indexValue  |-> indexValue.value ], indexValue.rest)

ZeroIndexMessage ==
    [ indexSymbol |-> [i \in 1 .. 11 |-> 0],
      indexValue  |-> [i \in 1 .. 8 |-> 0] ]

(* Index Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexMessage ==
    { ZeroIndexMessage }
        \cup { [ZeroIndexMessage EXCEPT !.indexSymbol = one] : one \in Sample(11) }
        \cup { [ZeroIndexMessage EXCEPT !.indexValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Bid And Offer Index Message: 27 bytes                                   *)
(***************************************************************************)

BidAndOfferIndexMessage ==
    [ indexSymbol     : Sample(11),
      bidIndexValue   : Sample(8),
      offerIndexValue : Sample(8) ]

EncodeBidAndOfferIndexMessage(message) ==
    message.indexSymbol
        \o message.bidIndexValue
        \o message.offerIndexValue

DecodeBidAndOfferIndexMessage(bytes) ==
    LET indexSymbol == ReadBytes(bytes, 11) IN IF ~indexSymbol.ok THEN Fail ELSE
    LET bidIndexValue == ReadBytes(indexSymbol.rest, 8) IN IF ~bidIndexValue.ok THEN Fail ELSE
    LET offerIndexValue == ReadBytes(bidIndexValue.rest, 8) IN IF ~offerIndexValue.ok THEN Fail ELSE
    Ok([ indexSymbol     |-> indexSymbol.value,
         bidIndexValue   |-> bidIndexValue.value,
         offerIndexValue |-> offerIndexValue.value ], offerIndexValue.rest)

ZeroBidAndOfferIndexMessage ==
    [ indexSymbol     |-> [i \in 1 .. 11 |-> 0],
      bidIndexValue   |-> [i \in 1 .. 8 |-> 0],
      offerIndexValue |-> [i \in 1 .. 8 |-> 0] ]

(* Bid And Offer Index Message at zero, then each field in turn at the values it is checked at *)
CheckedBidAndOfferIndexMessage ==
    { ZeroBidAndOfferIndexMessage }
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
(* Approximate Trades And Total Dollar Value Message: 12 bytes             *)
(***************************************************************************)

ApproximateTradesAndTotalDollarValueMessage ==
    [ totalTrades : Sample(4),
      dollarValue : Sample(8) ]

EncodeApproximateTradesAndTotalDollarValueMessage(message) ==
    message.totalTrades
        \o message.dollarValue

DecodeApproximateTradesAndTotalDollarValueMessage(bytes) ==
    LET totalTrades == ReadBytes(bytes, 4) IN IF ~totalTrades.ok THEN Fail ELSE
    LET dollarValue == ReadBytes(totalTrades.rest, 8) IN IF ~dollarValue.ok THEN Fail ELSE
    Ok([ totalTrades |-> totalTrades.value,
         dollarValue |-> dollarValue.value ], dollarValue.rest)

ZeroApproximateTradesAndTotalDollarValueMessage ==
    [ totalTrades |-> [i \in 1 .. 4 |-> 0],
      dollarValue |-> [i \in 1 .. 8 |-> 0] ]

(* Approximate Trades And Total Dollar Value Message at zero, then each field in turn at the values it is checked at *)
CheckedApproximateTradesAndTotalDollarValueMessage ==
    { ZeroApproximateTradesAndTotalDollarValueMessage }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.totalTrades = one] : one \in Sample(4) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.dollarValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Crossing Session Message: 24 bytes                                      *)
(***************************************************************************)

CrossingSessionMessage ==
    [ crossingSessionITotalTradesVolume  : Sample(8),
      crossingSessionIiDollarValue       : Sample(8),
      crossingSessionIiTotalTradesVolume : Sample(8) ]

EncodeCrossingSessionMessage(message) ==
    message.crossingSessionITotalTradesVolume
        \o message.crossingSessionIiDollarValue
        \o message.crossingSessionIiTotalTradesVolume

DecodeCrossingSessionMessage(bytes) ==
    LET crossingSessionITotalTradesVolume == ReadBytes(bytes, 8) IN IF ~crossingSessionITotalTradesVolume.ok THEN Fail ELSE
    LET crossingSessionIiDollarValue == ReadBytes(crossingSessionITotalTradesVolume.rest, 8) IN IF ~crossingSessionIiDollarValue.ok THEN Fail ELSE
    LET crossingSessionIiTotalTradesVolume == ReadBytes(crossingSessionIiDollarValue.rest, 8) IN IF ~crossingSessionIiTotalTradesVolume.ok THEN Fail ELSE
    Ok([ crossingSessionITotalTradesVolume  |-> crossingSessionITotalTradesVolume.value,
         crossingSessionIiDollarValue       |-> crossingSessionIiDollarValue.value,
         crossingSessionIiTotalTradesVolume |-> crossingSessionIiTotalTradesVolume.value ], crossingSessionIiTotalTradesVolume.rest)

ZeroCrossingSessionMessage ==
    [ crossingSessionITotalTradesVolume  |-> [i \in 1 .. 8 |-> 0],
      crossingSessionIiDollarValue       |-> [i \in 1 .. 8 |-> 0],
      crossingSessionIiTotalTradesVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Crossing Session Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossingSessionMessage ==
    { ZeroCrossingSessionMessage }
        \cup { [ZeroCrossingSessionMessage EXCEPT !.crossingSessionITotalTradesVolume = one] : one \in Sample(8) }
        \cup { [ZeroCrossingSessionMessage EXCEPT !.crossingSessionIiDollarValue = one] : one \in Sample(8) }
        \cup { [ZeroCrossingSessionMessage EXCEPT !.crossingSessionIiTotalTradesVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Status Message Payload, selected by Market Status Message Type   *)
(***************************************************************************)

ApproximateTradesAndTotalDollarValueMessageCode == 79  \* "O"
CrossingSessionMessageCode == 80  \* "P"

MarketStatusMessagePayload ==
    [ tag : {ApproximateTradesAndTotalDollarValueMessageCode}, body : ApproximateTradesAndTotalDollarValueMessage ]
        \cup [ tag : {CrossingSessionMessageCode}, body : CrossingSessionMessage ]

EncodeMarketStatusMessagePayload(message) ==
    CASE message.tag = ApproximateTradesAndTotalDollarValueMessageCode -> EncodeApproximateTradesAndTotalDollarValueMessage(message.body)
      [] message.tag = CrossingSessionMessageCode -> EncodeCrossingSessionMessage(message.body)

DecodeMarketStatusMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = ApproximateTradesAndTotalDollarValueMessageCode -> DecodeApproximateTradesAndTotalDollarValueMessage(bytes)
              [] tag = CrossingSessionMessageCode -> DecodeCrossingSessionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMarketStatusMessagePayload == [tag |-> ApproximateTradesAndTotalDollarValueMessageCode, body |-> ZeroApproximateTradesAndTotalDollarValueMessage]

(* Each Market Status Message Payload in turn, at the values the message it names is checked at *)
CheckedMarketStatusMessagePayload ==
    { [tag |-> ApproximateTradesAndTotalDollarValueMessageCode, body |-> one] : one \in CheckedApproximateTradesAndTotalDollarValueMessage }
        \cup { [tag |-> CrossingSessionMessageCode, body |-> one] : one \in CheckedCrossingSessionMessage }

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
(* Corrected Prior Day Trade Date And Time: 8 bytes                        *)
(***************************************************************************)

CorrectedPriorDayTradeDateAndTime ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeCorrectedPriorDayTradeDateAndTime(message) ==
    message.seconds
        \o message.nanoseconds

DecodeCorrectedPriorDayTradeDateAndTime(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroCorrectedPriorDayTradeDateAndTime ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Corrected Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedPriorDayTradeDateAndTime ==
    { ZeroCorrectedPriorDayTradeDateAndTime }
        \cup { [ZeroCorrectedPriorDayTradeDateAndTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedPriorDayTradeDateAndTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Original Prior Day Trade Date And Time: 8 bytes                         *)
(***************************************************************************)

OriginalPriorDayTradeDateAndTime ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeOriginalPriorDayTradeDateAndTime(message) ==
    message.seconds
        \o message.nanoseconds

DecodeOriginalPriorDayTradeDateAndTime(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroOriginalPriorDayTradeDateAndTime ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Original Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedOriginalPriorDayTradeDateAndTime ==
    { ZeroOriginalPriorDayTradeDateAndTime }
        \cup { [ZeroOriginalPriorDayTradeDateAndTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroOriginalPriorDayTradeDateAndTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Prior Day Trade Correction Message: 69 bytes                            *)
(***************************************************************************)

PriorDayTradeCorrectionMessage ==
    [ securitySymbol                         : Sample(11),
      instrumentType                         : Sample(1),
      correctedSaleCondition                 : Sample(4),
      correctedTradePrice                    : Sample(8),
      correctedTradeVolume                   : Sample(4),
      correctedSellersSaleDays               : Sample(1),
      correctedStopStockIndicator            : Sample(1),
      correctedTradeThroughExemptIndicator   : Sample(1),
      correctedShortSaleRestrictionIndicator : Sample(1),
      correctedPriorDayTradeDateAndTime      : CorrectedPriorDayTradeDateAndTime,
      tradeReportingFacilityId               : Sample(1),
      originalSaleCondition                  : Sample(4),
      originalTradePrice                     : Sample(8),
      originalTradeVolume                    : Sample(4),
      originalSellersSaleDays                : Sample(1),
      originalStopStockIndicator             : Sample(1),
      originalTradeThroughExemptIndicator    : Sample(1),
      originalShortSaleRestrictionIndicator  : Sample(1),
      originalPriorDayTradeDateAndTime       : OriginalPriorDayTradeDateAndTime ]

EncodePriorDayTradeCorrectionMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.correctedSaleCondition
        \o message.correctedTradePrice
        \o message.correctedTradeVolume
        \o message.correctedSellersSaleDays
        \o message.correctedStopStockIndicator
        \o message.correctedTradeThroughExemptIndicator
        \o message.correctedShortSaleRestrictionIndicator
        \o EncodeCorrectedPriorDayTradeDateAndTime(message.correctedPriorDayTradeDateAndTime)
        \o message.tradeReportingFacilityId
        \o message.originalSaleCondition
        \o message.originalTradePrice
        \o message.originalTradeVolume
        \o message.originalSellersSaleDays
        \o message.originalStopStockIndicator
        \o message.originalTradeThroughExemptIndicator
        \o message.originalShortSaleRestrictionIndicator
        \o EncodeOriginalPriorDayTradeDateAndTime(message.originalPriorDayTradeDateAndTime)

DecodePriorDayTradeCorrectionMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET correctedSaleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~correctedSaleCondition.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedSaleCondition.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeVolume == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedTradeVolume.ok THEN Fail ELSE
    LET correctedSellersSaleDays == ReadBytes(correctedTradeVolume.rest, 1) IN IF ~correctedSellersSaleDays.ok THEN Fail ELSE
    LET correctedStopStockIndicator == ReadBytes(correctedSellersSaleDays.rest, 1) IN IF ~correctedStopStockIndicator.ok THEN Fail ELSE
    LET correctedTradeThroughExemptIndicator == ReadBytes(correctedStopStockIndicator.rest, 1) IN IF ~correctedTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET correctedShortSaleRestrictionIndicator == ReadBytes(correctedTradeThroughExemptIndicator.rest, 1) IN IF ~correctedShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET correctedPriorDayTradeDateAndTime == DecodeCorrectedPriorDayTradeDateAndTime(correctedShortSaleRestrictionIndicator.rest) IN IF ~correctedPriorDayTradeDateAndTime.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(correctedPriorDayTradeDateAndTime.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET originalSaleCondition == ReadBytes(tradeReportingFacilityId.rest, 4) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalSaleCondition.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeVolume == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeVolume.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalTradeVolume.rest, 1) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET originalStopStockIndicator == ReadBytes(originalSellersSaleDays.rest, 1) IN IF ~originalStopStockIndicator.ok THEN Fail ELSE
    LET originalTradeThroughExemptIndicator == ReadBytes(originalStopStockIndicator.rest, 1) IN IF ~originalTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET originalShortSaleRestrictionIndicator == ReadBytes(originalTradeThroughExemptIndicator.rest, 1) IN IF ~originalShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET originalPriorDayTradeDateAndTime == DecodeOriginalPriorDayTradeDateAndTime(originalShortSaleRestrictionIndicator.rest) IN IF ~originalPriorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ securitySymbol                         |-> securitySymbol.value,
         instrumentType                         |-> instrumentType.value,
         correctedSaleCondition                 |-> correctedSaleCondition.value,
         correctedTradePrice                    |-> correctedTradePrice.value,
         correctedTradeVolume                   |-> correctedTradeVolume.value,
         correctedSellersSaleDays               |-> correctedSellersSaleDays.value,
         correctedStopStockIndicator            |-> correctedStopStockIndicator.value,
         correctedTradeThroughExemptIndicator   |-> correctedTradeThroughExemptIndicator.value,
         correctedShortSaleRestrictionIndicator |-> correctedShortSaleRestrictionIndicator.value,
         correctedPriorDayTradeDateAndTime      |-> correctedPriorDayTradeDateAndTime.value,
         tradeReportingFacilityId               |-> tradeReportingFacilityId.value,
         originalSaleCondition                  |-> originalSaleCondition.value,
         originalTradePrice                     |-> originalTradePrice.value,
         originalTradeVolume                    |-> originalTradeVolume.value,
         originalSellersSaleDays                |-> originalSellersSaleDays.value,
         originalStopStockIndicator             |-> originalStopStockIndicator.value,
         originalTradeThroughExemptIndicator    |-> originalTradeThroughExemptIndicator.value,
         originalShortSaleRestrictionIndicator  |-> originalShortSaleRestrictionIndicator.value,
         originalPriorDayTradeDateAndTime       |-> originalPriorDayTradeDateAndTime.value ], originalPriorDayTradeDateAndTime.rest)

ZeroPriorDayTradeCorrectionMessage ==
    [ securitySymbol                         |-> [i \in 1 .. 11 |-> 0],
      instrumentType                         |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition                 |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice                    |-> [i \in 1 .. 8 |-> 0],
      correctedTradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      correctedSellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      correctedStopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      correctedTradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      correctedShortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      correctedPriorDayTradeDateAndTime      |-> ZeroCorrectedPriorDayTradeDateAndTime,
      tradeReportingFacilityId               |-> [i \in 1 .. 1 |-> 0],
      originalSaleCondition                  |-> [i \in 1 .. 4 |-> 0],
      originalTradePrice                     |-> [i \in 1 .. 8 |-> 0],
      originalTradeVolume                    |-> [i \in 1 .. 4 |-> 0],
      originalSellersSaleDays                |-> [i \in 1 .. 1 |-> 0],
      originalStopStockIndicator             |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemptIndicator    |-> [i \in 1 .. 1 |-> 0],
      originalShortSaleRestrictionIndicator  |-> [i \in 1 .. 1 |-> 0],
      originalPriorDayTradeDateAndTime       |-> ZeroOriginalPriorDayTradeDateAndTime ]

(* Prior Day Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeCorrectionMessage ==
    { ZeroPriorDayTradeCorrectionMessage }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.correctedSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.correctedTradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.correctedSellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.correctedStopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.correctedTradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.correctedShortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.correctedPriorDayTradeDateAndTime = one] : one \in CheckedCorrectedPriorDayTradeDateAndTime }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.originalSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.originalTradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.originalStopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.originalTradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.originalShortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.originalPriorDayTradeDateAndTime = one] : one \in CheckedOriginalPriorDayTradeDateAndTime }

(***************************************************************************)
(* Corrected Prior Day Trade Date And Time: 8 bytes                        *)
(***************************************************************************)

CorrectedPriorDayTradeDateAndTime2 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeCorrectedPriorDayTradeDateAndTime2(message) ==
    message.seconds
        \o message.nanoseconds

DecodeCorrectedPriorDayTradeDateAndTime2(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroCorrectedPriorDayTradeDateAndTime2 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Corrected Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedPriorDayTradeDateAndTime2 ==
    { ZeroCorrectedPriorDayTradeDateAndTime2 }
        \cup { [ZeroCorrectedPriorDayTradeDateAndTime2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedPriorDayTradeDateAndTime2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Original Prior Day Trade Date And Time: 8 bytes                         *)
(***************************************************************************)

OriginalPriorDayTradeDateAndTime2 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeOriginalPriorDayTradeDateAndTime2(message) ==
    message.seconds
        \o message.nanoseconds

DecodeOriginalPriorDayTradeDateAndTime2(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroOriginalPriorDayTradeDateAndTime2 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Original Prior Day Trade Date And Time at zero, then each field in turn at the values it is checked at *)
CheckedOriginalPriorDayTradeDateAndTime2 ==
    { ZeroOriginalPriorDayTradeDateAndTime2 }
        \cup { [ZeroOriginalPriorDayTradeDateAndTime2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroOriginalPriorDayTradeDateAndTime2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Prior Day Trade Correction Message: 77 bytes                 *)
(***************************************************************************)

FractionalPriorDayTradeCorrectionMessage ==
    [ securitySymbol                         : Sample(11),
      instrumentType                         : Sample(1),
      correctedSaleCondition                 : Sample(4),
      correctedTradePrice                    : Sample(8),
      correctedFractionalTradeVolume         : Sample(8),
      correctedSellersSaleDays               : Sample(1),
      correctedStopStockIndicator            : Sample(1),
      correctedTradeThroughExemptIndicator   : Sample(1),
      correctedShortSaleRestrictionIndicator : Sample(1),
      correctedPriorDayTradeDateAndTime      : CorrectedPriorDayTradeDateAndTime2,
      tradeReportingFacilityId               : Sample(1),
      originalSaleCondition                  : Sample(4),
      originalTradePrice                     : Sample(8),
      originalFractionalTradeVolume          : Sample(8),
      originalSellersSaleDays                : Sample(1),
      originalStopStockIndicator             : Sample(1),
      originalTradeThroughExemptIndicator    : Sample(1),
      originalShortSaleRestrictionIndicator  : Sample(1),
      originalPriorDayTradeDateAndTime       : OriginalPriorDayTradeDateAndTime2 ]

EncodeFractionalPriorDayTradeCorrectionMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.correctedSaleCondition
        \o message.correctedTradePrice
        \o message.correctedFractionalTradeVolume
        \o message.correctedSellersSaleDays
        \o message.correctedStopStockIndicator
        \o message.correctedTradeThroughExemptIndicator
        \o message.correctedShortSaleRestrictionIndicator
        \o EncodeCorrectedPriorDayTradeDateAndTime2(message.correctedPriorDayTradeDateAndTime)
        \o message.tradeReportingFacilityId
        \o message.originalSaleCondition
        \o message.originalTradePrice
        \o message.originalFractionalTradeVolume
        \o message.originalSellersSaleDays
        \o message.originalStopStockIndicator
        \o message.originalTradeThroughExemptIndicator
        \o message.originalShortSaleRestrictionIndicator
        \o EncodeOriginalPriorDayTradeDateAndTime2(message.originalPriorDayTradeDateAndTime)

DecodeFractionalPriorDayTradeCorrectionMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET correctedSaleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~correctedSaleCondition.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedSaleCondition.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedFractionalTradeVolume == ReadBytes(correctedTradePrice.rest, 8) IN IF ~correctedFractionalTradeVolume.ok THEN Fail ELSE
    LET correctedSellersSaleDays == ReadBytes(correctedFractionalTradeVolume.rest, 1) IN IF ~correctedSellersSaleDays.ok THEN Fail ELSE
    LET correctedStopStockIndicator == ReadBytes(correctedSellersSaleDays.rest, 1) IN IF ~correctedStopStockIndicator.ok THEN Fail ELSE
    LET correctedTradeThroughExemptIndicator == ReadBytes(correctedStopStockIndicator.rest, 1) IN IF ~correctedTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET correctedShortSaleRestrictionIndicator == ReadBytes(correctedTradeThroughExemptIndicator.rest, 1) IN IF ~correctedShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET correctedPriorDayTradeDateAndTime == DecodeCorrectedPriorDayTradeDateAndTime2(correctedShortSaleRestrictionIndicator.rest) IN IF ~correctedPriorDayTradeDateAndTime.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(correctedPriorDayTradeDateAndTime.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET originalSaleCondition == ReadBytes(tradeReportingFacilityId.rest, 4) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalSaleCondition.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalFractionalTradeVolume == ReadBytes(originalTradePrice.rest, 8) IN IF ~originalFractionalTradeVolume.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalFractionalTradeVolume.rest, 1) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET originalStopStockIndicator == ReadBytes(originalSellersSaleDays.rest, 1) IN IF ~originalStopStockIndicator.ok THEN Fail ELSE
    LET originalTradeThroughExemptIndicator == ReadBytes(originalStopStockIndicator.rest, 1) IN IF ~originalTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET originalShortSaleRestrictionIndicator == ReadBytes(originalTradeThroughExemptIndicator.rest, 1) IN IF ~originalShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET originalPriorDayTradeDateAndTime == DecodeOriginalPriorDayTradeDateAndTime2(originalShortSaleRestrictionIndicator.rest) IN IF ~originalPriorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ securitySymbol                         |-> securitySymbol.value,
         instrumentType                         |-> instrumentType.value,
         correctedSaleCondition                 |-> correctedSaleCondition.value,
         correctedTradePrice                    |-> correctedTradePrice.value,
         correctedFractionalTradeVolume         |-> correctedFractionalTradeVolume.value,
         correctedSellersSaleDays               |-> correctedSellersSaleDays.value,
         correctedStopStockIndicator            |-> correctedStopStockIndicator.value,
         correctedTradeThroughExemptIndicator   |-> correctedTradeThroughExemptIndicator.value,
         correctedShortSaleRestrictionIndicator |-> correctedShortSaleRestrictionIndicator.value,
         correctedPriorDayTradeDateAndTime      |-> correctedPriorDayTradeDateAndTime.value,
         tradeReportingFacilityId               |-> tradeReportingFacilityId.value,
         originalSaleCondition                  |-> originalSaleCondition.value,
         originalTradePrice                     |-> originalTradePrice.value,
         originalFractionalTradeVolume          |-> originalFractionalTradeVolume.value,
         originalSellersSaleDays                |-> originalSellersSaleDays.value,
         originalStopStockIndicator             |-> originalStopStockIndicator.value,
         originalTradeThroughExemptIndicator    |-> originalTradeThroughExemptIndicator.value,
         originalShortSaleRestrictionIndicator  |-> originalShortSaleRestrictionIndicator.value,
         originalPriorDayTradeDateAndTime       |-> originalPriorDayTradeDateAndTime.value ], originalPriorDayTradeDateAndTime.rest)

ZeroFractionalPriorDayTradeCorrectionMessage ==
    [ securitySymbol                         |-> [i \in 1 .. 11 |-> 0],
      instrumentType                         |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition                 |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice                    |-> [i \in 1 .. 8 |-> 0],
      correctedFractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      correctedSellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      correctedStopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      correctedTradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      correctedShortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      correctedPriorDayTradeDateAndTime      |-> ZeroCorrectedPriorDayTradeDateAndTime2,
      tradeReportingFacilityId               |-> [i \in 1 .. 1 |-> 0],
      originalSaleCondition                  |-> [i \in 1 .. 4 |-> 0],
      originalTradePrice                     |-> [i \in 1 .. 8 |-> 0],
      originalFractionalTradeVolume          |-> [i \in 1 .. 8 |-> 0],
      originalSellersSaleDays                |-> [i \in 1 .. 1 |-> 0],
      originalStopStockIndicator             |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemptIndicator    |-> [i \in 1 .. 1 |-> 0],
      originalShortSaleRestrictionIndicator  |-> [i \in 1 .. 1 |-> 0],
      originalPriorDayTradeDateAndTime       |-> ZeroOriginalPriorDayTradeDateAndTime2 ]

(* Fractional Prior Day Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeCorrectionMessage ==
    { ZeroFractionalPriorDayTradeCorrectionMessage }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.correctedSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.correctedFractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.correctedSellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.correctedStopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.correctedTradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.correctedShortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.correctedPriorDayTradeDateAndTime = one] : one \in CheckedCorrectedPriorDayTradeDateAndTime2 }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.originalSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.originalFractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.originalStopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.originalTradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.originalShortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.originalPriorDayTradeDateAndTime = one] : one \in CheckedOriginalPriorDayTradeDateAndTime2 }

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
(* Prior Day Trade Message: 41 bytes                                       *)
(***************************************************************************)

PriorDayTradeMessage ==
    [ securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleCondition                 : Sample(4),
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime ]

EncodePriorDayTradeMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.saleCondition
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime(message.priorDayTradeDateAndTime)

DecodePriorDayTradeMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition                 |-> saleCondition.value,
         tradePrice                    |-> tradePrice.value,
         tradeVolume                   |-> tradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         tradeReportingFacilityId      |-> tradeReportingFacilityId.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroPriorDayTradeMessage ==
    [ securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleCondition                 |-> [i \in 1 .. 4 |-> 0],
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime ]

(* Prior Day Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeMessage ==
    { ZeroPriorDayTradeMessage }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime }

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
(* Fractional Prior Day Trade Message: 45 bytes                            *)
(***************************************************************************)

FractionalPriorDayTradeMessage ==
    [ securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleCondition                 : Sample(4),
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime2 ]

EncodeFractionalPriorDayTradeMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.saleCondition
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime2(message.priorDayTradeDateAndTime)

DecodeFractionalPriorDayTradeMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime2(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition                 |-> saleCondition.value,
         tradePrice                    |-> tradePrice.value,
         fractionalTradeVolume         |-> fractionalTradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         tradeReportingFacilityId      |-> tradeReportingFacilityId.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroFractionalPriorDayTradeMessage ==
    [ securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleCondition                 |-> [i \in 1 .. 4 |-> 0],
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime2 ]

(* Fractional Prior Day Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeMessage ==
    { ZeroFractionalPriorDayTradeMessage }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime2 }

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
(* Prior Day Trade Cancel Error Message: 42 bytes                          *)
(***************************************************************************)

PriorDayTradeCancelErrorMessage ==
    [ securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleCondition                 : Sample(4),
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime3,
      cancelErrorAction             : Sample(1) ]

EncodePriorDayTradeCancelErrorMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.saleCondition
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime3(message.priorDayTradeDateAndTime)
        \o message.cancelErrorAction

DecodePriorDayTradeCancelErrorMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime3(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(priorDayTradeDateAndTime.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    Ok([ securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition                 |-> saleCondition.value,
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
    [ securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleCondition                 |-> [i \in 1 .. 4 |-> 0],
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime3,
      cancelErrorAction             |-> [i \in 1 .. 1 |-> 0] ]

(* Prior Day Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeCancelErrorMessage ==
    { ZeroPriorDayTradeCancelErrorMessage }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime3 }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }

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
(* Fractional Prior Day Trade Cancel Error Message: 46 bytes               *)
(***************************************************************************)

FractionalPriorDayTradeCancelErrorMessage ==
    [ securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleCondition                 : Sample(4),
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime4,
      cancelErrorAction             : Sample(1) ]

EncodeFractionalPriorDayTradeCancelErrorMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.saleCondition
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime4(message.priorDayTradeDateAndTime)
        \o message.cancelErrorAction

DecodeFractionalPriorDayTradeCancelErrorMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime4(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(priorDayTradeDateAndTime.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    Ok([ securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition                 |-> saleCondition.value,
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
    [ securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleCondition                 |-> [i \in 1 .. 4 |-> 0],
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime4,
      cancelErrorAction             |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Prior Day Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeCancelErrorMessage ==
    { ZeroFractionalPriorDayTradeCancelErrorMessage }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime4 }
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
(* Auction Status Message: 99 bytes                                        *)
(***************************************************************************)

AuctionStatusMessage ==
    [ securitySymbol                   : Sample(11),
      instrumentType                   : Sample(1),
      auctionCollarReferencePrice      : Sample(8),
      auctionCollarUpperThresholdPrice : Sample(8),
      auctionCollarLowerThresholdPrice : Sample(8),
      numberOfExtensions               : Sample(1),
      reserved62                       : Sample(62) ]

EncodeAuctionStatusMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.auctionCollarReferencePrice
        \o message.auctionCollarUpperThresholdPrice
        \o message.auctionCollarLowerThresholdPrice
        \o message.numberOfExtensions
        \o message.reserved62

DecodeAuctionStatusMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET auctionCollarReferencePrice == ReadBytes(instrumentType.rest, 8) IN IF ~auctionCollarReferencePrice.ok THEN Fail ELSE
    LET auctionCollarUpperThresholdPrice == ReadBytes(auctionCollarReferencePrice.rest, 8) IN IF ~auctionCollarUpperThresholdPrice.ok THEN Fail ELSE
    LET auctionCollarLowerThresholdPrice == ReadBytes(auctionCollarUpperThresholdPrice.rest, 8) IN IF ~auctionCollarLowerThresholdPrice.ok THEN Fail ELSE
    LET numberOfExtensions == ReadBytes(auctionCollarLowerThresholdPrice.rest, 1) IN IF ~numberOfExtensions.ok THEN Fail ELSE
    LET reserved62 == ReadBytes(numberOfExtensions.rest, 62) IN IF ~reserved62.ok THEN Fail ELSE
    Ok([ securitySymbol                   |-> securitySymbol.value,
         instrumentType                   |-> instrumentType.value,
         auctionCollarReferencePrice      |-> auctionCollarReferencePrice.value,
         auctionCollarUpperThresholdPrice |-> auctionCollarUpperThresholdPrice.value,
         auctionCollarLowerThresholdPrice |-> auctionCollarLowerThresholdPrice.value,
         numberOfExtensions               |-> numberOfExtensions.value,
         reserved62                       |-> reserved62.value ], reserved62.rest)

ZeroAuctionStatusMessage ==
    [ securitySymbol                   |-> [i \in 1 .. 11 |-> 0],
      instrumentType                   |-> [i \in 1 .. 1 |-> 0],
      auctionCollarReferencePrice      |-> [i \in 1 .. 8 |-> 0],
      auctionCollarUpperThresholdPrice |-> [i \in 1 .. 8 |-> 0],
      auctionCollarLowerThresholdPrice |-> [i \in 1 .. 8 |-> 0],
      numberOfExtensions               |-> [i \in 1 .. 1 |-> 0],
      reserved62                       |-> [i \in 1 .. 62 |-> 0] ]

(* Auction Status Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionStatusMessage ==
    { ZeroAuctionStatusMessage }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarUpperThresholdPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.auctionCollarLowerThresholdPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.numberOfExtensions = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.reserved62 = one] : one \in Sample(62) }

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
(* Trade Correction Message: 49 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ securitySymbol                         : Sample(11),
      instrumentType                         : Sample(1),
      correctedSaleCondition                 : Sample(4),
      correctedTradePrice                    : Sample(8),
      correctedTradeVolume                   : Sample(4),
      correctedSellersSaleDays               : Sample(1),
      correctedStopStockIndicator            : Sample(1),
      correctedTradeThroughExemptIndicator   : Sample(1),
      correctedShortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId               : Sample(1),
      timestamp2                             : Timestamp2,
      originalParticipantReferenceNumber     : Sample(8) ]

EncodeTradeCorrectionMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.correctedSaleCondition
        \o message.correctedTradePrice
        \o message.correctedTradeVolume
        \o message.correctedSellersSaleDays
        \o message.correctedStopStockIndicator
        \o message.correctedTradeThroughExemptIndicator
        \o message.correctedShortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp2(message.timestamp2)
        \o message.originalParticipantReferenceNumber

DecodeTradeCorrectionMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET correctedSaleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~correctedSaleCondition.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedSaleCondition.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeVolume == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedTradeVolume.ok THEN Fail ELSE
    LET correctedSellersSaleDays == ReadBytes(correctedTradeVolume.rest, 1) IN IF ~correctedSellersSaleDays.ok THEN Fail ELSE
    LET correctedStopStockIndicator == ReadBytes(correctedSellersSaleDays.rest, 1) IN IF ~correctedStopStockIndicator.ok THEN Fail ELSE
    LET correctedTradeThroughExemptIndicator == ReadBytes(correctedStopStockIndicator.rest, 1) IN IF ~correctedTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET correctedShortSaleRestrictionIndicator == ReadBytes(correctedTradeThroughExemptIndicator.rest, 1) IN IF ~correctedShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(correctedShortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp2(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(timestamp2.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    Ok([ securitySymbol                         |-> securitySymbol.value,
         instrumentType                         |-> instrumentType.value,
         correctedSaleCondition                 |-> correctedSaleCondition.value,
         correctedTradePrice                    |-> correctedTradePrice.value,
         correctedTradeVolume                   |-> correctedTradeVolume.value,
         correctedSellersSaleDays               |-> correctedSellersSaleDays.value,
         correctedStopStockIndicator            |-> correctedStopStockIndicator.value,
         correctedTradeThroughExemptIndicator   |-> correctedTradeThroughExemptIndicator.value,
         correctedShortSaleRestrictionIndicator |-> correctedShortSaleRestrictionIndicator.value,
         tradeReportingFacilityId               |-> tradeReportingFacilityId.value,
         timestamp2                             |-> timestamp2.value,
         originalParticipantReferenceNumber     |-> originalParticipantReferenceNumber.value ], originalParticipantReferenceNumber.rest)

ZeroTradeCorrectionMessage ==
    [ securitySymbol                         |-> [i \in 1 .. 11 |-> 0],
      instrumentType                         |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition                 |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice                    |-> [i \in 1 .. 8 |-> 0],
      correctedTradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      correctedSellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      correctedStopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      correctedTradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      correctedShortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId               |-> [i \in 1 .. 1 |-> 0],
      timestamp2                             |-> ZeroTimestamp2,
      originalParticipantReferenceNumber     |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedStopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedShortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp2 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }

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
(* Fractional Trade Correction Message: 53 bytes                           *)
(***************************************************************************)

FractionalTradeCorrectionMessage ==
    [ securitySymbol                         : Sample(11),
      instrumentType                         : Sample(1),
      correctedSaleCondition                 : Sample(4),
      correctedTradePrice                    : Sample(8),
      correctedFractionalTradeVolume         : Sample(8),
      correctedSellersSaleDays               : Sample(1),
      correctedStopStockIndicator            : Sample(1),
      correctedTradeThroughExemptIndicator   : Sample(1),
      correctedShortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId               : Sample(1),
      timestamp2                             : Timestamp22,
      originalParticipantReferenceNumber     : Sample(8) ]

EncodeFractionalTradeCorrectionMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.correctedSaleCondition
        \o message.correctedTradePrice
        \o message.correctedFractionalTradeVolume
        \o message.correctedSellersSaleDays
        \o message.correctedStopStockIndicator
        \o message.correctedTradeThroughExemptIndicator
        \o message.correctedShortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp22(message.timestamp2)
        \o message.originalParticipantReferenceNumber

DecodeFractionalTradeCorrectionMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET correctedSaleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~correctedSaleCondition.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedSaleCondition.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedFractionalTradeVolume == ReadBytes(correctedTradePrice.rest, 8) IN IF ~correctedFractionalTradeVolume.ok THEN Fail ELSE
    LET correctedSellersSaleDays == ReadBytes(correctedFractionalTradeVolume.rest, 1) IN IF ~correctedSellersSaleDays.ok THEN Fail ELSE
    LET correctedStopStockIndicator == ReadBytes(correctedSellersSaleDays.rest, 1) IN IF ~correctedStopStockIndicator.ok THEN Fail ELSE
    LET correctedTradeThroughExemptIndicator == ReadBytes(correctedStopStockIndicator.rest, 1) IN IF ~correctedTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET correctedShortSaleRestrictionIndicator == ReadBytes(correctedTradeThroughExemptIndicator.rest, 1) IN IF ~correctedShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(correctedShortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp22(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(timestamp2.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    Ok([ securitySymbol                         |-> securitySymbol.value,
         instrumentType                         |-> instrumentType.value,
         correctedSaleCondition                 |-> correctedSaleCondition.value,
         correctedTradePrice                    |-> correctedTradePrice.value,
         correctedFractionalTradeVolume         |-> correctedFractionalTradeVolume.value,
         correctedSellersSaleDays               |-> correctedSellersSaleDays.value,
         correctedStopStockIndicator            |-> correctedStopStockIndicator.value,
         correctedTradeThroughExemptIndicator   |-> correctedTradeThroughExemptIndicator.value,
         correctedShortSaleRestrictionIndicator |-> correctedShortSaleRestrictionIndicator.value,
         tradeReportingFacilityId               |-> tradeReportingFacilityId.value,
         timestamp2                             |-> timestamp2.value,
         originalParticipantReferenceNumber     |-> originalParticipantReferenceNumber.value ], originalParticipantReferenceNumber.rest)

ZeroFractionalTradeCorrectionMessage ==
    [ securitySymbol                         |-> [i \in 1 .. 11 |-> 0],
      instrumentType                         |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition                 |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice                    |-> [i \in 1 .. 8 |-> 0],
      correctedFractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      correctedSellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      correctedStopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      correctedTradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      correctedShortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId               |-> [i \in 1 .. 1 |-> 0],
      timestamp2                             |-> ZeroTimestamp22,
      originalParticipantReferenceNumber     |-> [i \in 1 .. 8 |-> 0] ]

(* Fractional Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCorrectionMessage ==
    { ZeroFractionalTradeCorrectionMessage }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedFractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedSellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedStopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedTradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.correctedShortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp22 }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }

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
(* Long Trade Message: 40 bytes                                            *)
(***************************************************************************)

LongTradeMessage ==
    [ securitySymbol              : Sample(11),
      instrumentType              : Sample(1),
      saleCondition               : Sample(4),
      tradePrice                  : Sample(8),
      tradeVolume                 : Sample(4),
      sellersSaleDays             : Sample(1),
      stopStockIndicator          : Sample(1),
      tradeThroughExemptIndicator : Sample(1),
      tradeReportingFacilityId    : Sample(1),
      timestamp2                  : Timestamp23 ]

EncodeLongTradeMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.saleCondition
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp23(message.timestamp2)

DecodeLongTradeMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp23(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    Ok([ securitySymbol              |-> securitySymbol.value,
         instrumentType              |-> instrumentType.value,
         saleCondition               |-> saleCondition.value,
         tradePrice                  |-> tradePrice.value,
         tradeVolume                 |-> tradeVolume.value,
         sellersSaleDays             |-> sellersSaleDays.value,
         stopStockIndicator          |-> stopStockIndicator.value,
         tradeThroughExemptIndicator |-> tradeThroughExemptIndicator.value,
         tradeReportingFacilityId    |-> tradeReportingFacilityId.value,
         timestamp2                  |-> timestamp2.value ], timestamp2.rest)

ZeroLongTradeMessage ==
    [ securitySymbol              |-> [i \in 1 .. 11 |-> 0],
      instrumentType              |-> [i \in 1 .. 1 |-> 0],
      saleCondition               |-> [i \in 1 .. 4 |-> 0],
      tradePrice                  |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                 |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays             |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator          |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId    |-> [i \in 1 .. 1 |-> 0],
      timestamp2                  |-> ZeroTimestamp23 ]

(* Long Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedLongTradeMessage ==
    { ZeroLongTradeMessage }
        \cup { [ZeroLongTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroLongTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroLongTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp23 }

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
(* Fractional Long Trade Message: 44 bytes                                 *)
(***************************************************************************)

FractionalLongTradeMessage ==
    [ securitySymbol              : Sample(11),
      instrumentType              : Sample(1),
      saleCondition               : Sample(4),
      tradePrice                  : Sample(8),
      fractionalTradeVolume       : Sample(8),
      sellersSaleDays             : Sample(1),
      stopStockIndicator          : Sample(1),
      tradeThroughExemptIndicator : Sample(1),
      tradeReportingFacilityId    : Sample(1),
      timestamp2                  : Timestamp24 ]

EncodeFractionalLongTradeMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.saleCondition
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp24(message.timestamp2)

DecodeFractionalLongTradeMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp24(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    Ok([ securitySymbol              |-> securitySymbol.value,
         instrumentType              |-> instrumentType.value,
         saleCondition               |-> saleCondition.value,
         tradePrice                  |-> tradePrice.value,
         fractionalTradeVolume       |-> fractionalTradeVolume.value,
         sellersSaleDays             |-> sellersSaleDays.value,
         stopStockIndicator          |-> stopStockIndicator.value,
         tradeThroughExemptIndicator |-> tradeThroughExemptIndicator.value,
         tradeReportingFacilityId    |-> tradeReportingFacilityId.value,
         timestamp2                  |-> timestamp2.value ], timestamp2.rest)

ZeroFractionalLongTradeMessage ==
    [ securitySymbol              |-> [i \in 1 .. 11 |-> 0],
      instrumentType              |-> [i \in 1 .. 1 |-> 0],
      saleCondition               |-> [i \in 1 .. 4 |-> 0],
      tradePrice                  |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume       |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays             |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator          |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId    |-> [i \in 1 .. 1 |-> 0],
      timestamp2                  |-> ZeroTimestamp24 ]

(* Fractional Long Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalLongTradeMessage ==
    { ZeroFractionalLongTradeMessage }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp24 }

(***************************************************************************)
(* Trading Status Message: 51 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ securitySymbol                              : Sample(11),
      instrumentType                              : Sample(1),
      lastPriceOpeningReopeningLuldReferencePrice : Sample(8),
      highIndicationPriceUpperLimitPriceBand      : Sample(8),
      lowIndicationPriceLowerLimitPriceBand       : Sample(8),
      buyVolume                                   : Sample(4),
      sellVolume                                  : Sample(4),
      securityStatus                              : Sample(1),
      haltReason                                  : Sample(1),
      shortSaleRestrictionIndicator               : Sample(1),
      tradingStatusId                             : Sample(4) ]

EncodeTradingStatusMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.lastPriceOpeningReopeningLuldReferencePrice
        \o message.highIndicationPriceUpperLimitPriceBand
        \o message.lowIndicationPriceLowerLimitPriceBand
        \o message.buyVolume
        \o message.sellVolume
        \o message.securityStatus
        \o message.haltReason
        \o message.shortSaleRestrictionIndicator
        \o message.tradingStatusId

DecodeTradingStatusMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET lastPriceOpeningReopeningLuldReferencePrice == ReadBytes(instrumentType.rest, 8) IN IF ~lastPriceOpeningReopeningLuldReferencePrice.ok THEN Fail ELSE
    LET highIndicationPriceUpperLimitPriceBand == ReadBytes(lastPriceOpeningReopeningLuldReferencePrice.rest, 8) IN IF ~highIndicationPriceUpperLimitPriceBand.ok THEN Fail ELSE
    LET lowIndicationPriceLowerLimitPriceBand == ReadBytes(highIndicationPriceUpperLimitPriceBand.rest, 8) IN IF ~lowIndicationPriceLowerLimitPriceBand.ok THEN Fail ELSE
    LET buyVolume == ReadBytes(lowIndicationPriceLowerLimitPriceBand.rest, 4) IN IF ~buyVolume.ok THEN Fail ELSE
    LET sellVolume == ReadBytes(buyVolume.rest, 4) IN IF ~sellVolume.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(sellVolume.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET haltReason == ReadBytes(securityStatus.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(haltReason.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradingStatusId == ReadBytes(shortSaleRestrictionIndicator.rest, 4) IN IF ~tradingStatusId.ok THEN Fail ELSE
    Ok([ securitySymbol                              |-> securitySymbol.value,
         instrumentType                              |-> instrumentType.value,
         lastPriceOpeningReopeningLuldReferencePrice |-> lastPriceOpeningReopeningLuldReferencePrice.value,
         highIndicationPriceUpperLimitPriceBand      |-> highIndicationPriceUpperLimitPriceBand.value,
         lowIndicationPriceLowerLimitPriceBand       |-> lowIndicationPriceLowerLimitPriceBand.value,
         buyVolume                                   |-> buyVolume.value,
         sellVolume                                  |-> sellVolume.value,
         securityStatus                              |-> securityStatus.value,
         haltReason                                  |-> haltReason.value,
         shortSaleRestrictionIndicator               |-> shortSaleRestrictionIndicator.value,
         tradingStatusId                             |-> tradingStatusId.value ], tradingStatusId.rest)

ZeroTradingStatusMessage ==
    [ securitySymbol                              |-> [i \in 1 .. 11 |-> 0],
      instrumentType                              |-> [i \in 1 .. 1 |-> 0],
      lastPriceOpeningReopeningLuldReferencePrice |-> [i \in 1 .. 8 |-> 0],
      highIndicationPriceUpperLimitPriceBand      |-> [i \in 1 .. 8 |-> 0],
      lowIndicationPriceLowerLimitPriceBand       |-> [i \in 1 .. 8 |-> 0],
      buyVolume                                   |-> [i \in 1 .. 4 |-> 0],
      sellVolume                                  |-> [i \in 1 .. 4 |-> 0],
      securityStatus                              |-> [i \in 1 .. 1 |-> 0],
      haltReason                                  |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator               |-> [i \in 1 .. 1 |-> 0],
      tradingStatusId                             |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.lastPriceOpeningReopeningLuldReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.highIndicationPriceUpperLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.lowIndicationPriceLowerLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.buyVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.sellVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatusId = one] : one \in Sample(4) }

(***************************************************************************)
(* Short Trade Message: 31 bytes                                           *)
(***************************************************************************)

ShortTradeMessage ==
    [ securitySymbol        : Sample(11),
      saleCondition         : Sample(4),
      saleConditionCategory : Sample(1),
      tradePrice            : Sample(8),
      tradeVolume           : Sample(4),
      reserved3             : Sample(3) ]

EncodeShortTradeMessage(message) ==
    message.securitySymbol
        \o message.saleCondition
        \o message.saleConditionCategory
        \o message.tradePrice
        \o message.tradeVolume
        \o message.reserved3

DecodeShortTradeMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(securitySymbol.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET saleConditionCategory == ReadBytes(saleCondition.rest, 1) IN IF ~saleConditionCategory.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditionCategory.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(tradeVolume.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ securitySymbol        |-> securitySymbol.value,
         saleCondition         |-> saleCondition.value,
         saleConditionCategory |-> saleConditionCategory.value,
         tradePrice            |-> tradePrice.value,
         tradeVolume           |-> tradeVolume.value,
         reserved3             |-> reserved3.value ], reserved3.rest)

ZeroShortTradeMessage ==
    [ securitySymbol        |-> [i \in 1 .. 11 |-> 0],
      saleCondition         |-> [i \in 1 .. 4 |-> 0],
      saleConditionCategory |-> [i \in 1 .. 1 |-> 0],
      tradePrice            |-> [i \in 1 .. 8 |-> 0],
      tradeVolume           |-> [i \in 1 .. 4 |-> 0],
      reserved3             |-> [i \in 1 .. 3 |-> 0] ]

(* Short Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedShortTradeMessage ==
    { ZeroShortTradeMessage }
        \cup { [ZeroShortTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroShortTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroShortTradeMessage EXCEPT !.saleConditionCategory = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroShortTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroShortTradeMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Fractional Short Trade Message: 35 bytes                                *)
(***************************************************************************)

FractionalShortTradeMessage ==
    [ securitySymbol        : Sample(11),
      saleCondition         : Sample(4),
      saleConditionCategory : Sample(1),
      tradePrice            : Sample(8),
      fractionalTradeVolume : Sample(8),
      reserved3             : Sample(3) ]

EncodeFractionalShortTradeMessage(message) ==
    message.securitySymbol
        \o message.saleCondition
        \o message.saleConditionCategory
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.reserved3

DecodeFractionalShortTradeMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET saleCondition == ReadBytes(securitySymbol.rest, 4) IN IF ~saleCondition.ok THEN Fail ELSE
    LET saleConditionCategory == ReadBytes(saleCondition.rest, 1) IN IF ~saleConditionCategory.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleConditionCategory.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(fractionalTradeVolume.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ securitySymbol        |-> securitySymbol.value,
         saleCondition         |-> saleCondition.value,
         saleConditionCategory |-> saleConditionCategory.value,
         tradePrice            |-> tradePrice.value,
         fractionalTradeVolume |-> fractionalTradeVolume.value,
         reserved3             |-> reserved3.value ], reserved3.rest)

ZeroFractionalShortTradeMessage ==
    [ securitySymbol        |-> [i \in 1 .. 11 |-> 0],
      saleCondition         |-> [i \in 1 .. 4 |-> 0],
      saleConditionCategory |-> [i \in 1 .. 1 |-> 0],
      tradePrice            |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume |-> [i \in 1 .. 8 |-> 0],
      reserved3             |-> [i \in 1 .. 3 |-> 0] ]

(* Fractional Short Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalShortTradeMessage ==
    { ZeroFractionalShortTradeMessage }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.saleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.saleConditionCategory = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

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
(* Trade Cancel Error Message: 31 bytes                                    *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ securitySymbol                     : Sample(11),
      instrumentType                     : Sample(1),
      tradeThroughExemptIndicator        : Sample(1),
      tradeReportingFacilityId           : Sample(1),
      originalParticipantReferenceNumber : Sample(8),
      timestamp2                         : Timestamp25,
      cancelErrorAction                  : Sample(1) ]

EncodeTradeCancelErrorMessage(message) ==
    message.securitySymbol
        \o message.instrumentType
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o message.originalParticipantReferenceNumber
        \o EncodeTimestamp25(message.timestamp2)
        \o message.cancelErrorAction

DecodeTradeCancelErrorMessage(bytes) ==
    LET securitySymbol == ReadBytes(bytes, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(instrumentType.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(tradeReportingFacilityId.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp25(originalParticipantReferenceNumber.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(timestamp2.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    Ok([ securitySymbol                     |-> securitySymbol.value,
         instrumentType                     |-> instrumentType.value,
         tradeThroughExemptIndicator        |-> tradeThroughExemptIndicator.value,
         tradeReportingFacilityId           |-> tradeReportingFacilityId.value,
         originalParticipantReferenceNumber |-> originalParticipantReferenceNumber.value,
         timestamp2                         |-> timestamp2.value,
         cancelErrorAction                  |-> cancelErrorAction.value ], cancelErrorAction.rest)

ZeroTradeCancelErrorMessage ==
    [ securitySymbol                     |-> [i \in 1 .. 11 |-> 0],
      instrumentType                     |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator        |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId           |-> [i \in 1 .. 1 |-> 0],
      originalParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      timestamp2                         |-> ZeroTimestamp25,
      cancelErrorAction                  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp25 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }

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
TradeMessageCode == 84  \* "T"

CategoryPayload ==
    [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]
        \cup [ tag : {IndicesMessageCode}, body : IndicesMessage ]
        \cup [ tag : {MarketStatusMessageCode}, body : MarketStatusMessage ]
        \cup [ tag : {PriorDayMessageCode}, body : PriorDayMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)
      [] message.tag = IndicesMessageCode -> EncodeIndicesMessage(message.body)
      [] message.tag = MarketStatusMessageCode -> EncodeMarketStatusMessage(message.body)
      [] message.tag = PriorDayMessageCode -> EncodePriorDayMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] tag = IndicesMessageCode -> DecodeIndicesMessage(bytes)
              [] tag = MarketStatusMessageCode -> DecodeMarketStatusMessage(bytes)
              [] tag = PriorDayMessageCode -> DecodePriorDayMessage(bytes)
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
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messageLength              : 0 .. 255,
      messageType                : Sample(1),
      participantId              : Sample(1),
      timestamp1                 : Timestamp1,
      messageId                  : Sample(1),
      reserved                   : Sample(4),
      participantReferenceNumber : Sample(8),
      categoryPayload            : CategoryPayload ]

EncodeMessage(message) ==
    EncodeUIntBE(message.messageLength, 2)
        \o EncodeUIntBE(message.categoryPayload.tag, 1)
        \o message.messageType
        \o message.participantId
        \o EncodeTimestamp1(message.timestamp1)
        \o message.messageId
        \o message.reserved
        \o message.participantReferenceNumber
        \o EncodeCategoryPayload(message.categoryPayload)

DecodeMessage(bytes) ==
    LET messageLength == ReadUIntBE(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(messageLength.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET messageType == ReadBytes(messageCategory.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET participantId == ReadBytes(messageType.rest, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp1(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET reserved == ReadBytes(messageId.rest, 4) IN IF ~reserved.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(reserved.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET categoryPayload == DecodeCategoryPayload(messageCategory.value, participantReferenceNumber.rest) IN IF ~categoryPayload.ok THEN Fail ELSE
    Ok([ messageLength              |-> messageLength.value,
         messageType                |-> messageType.value,
         participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         reserved                   |-> reserved.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         categoryPayload            |-> categoryPayload.value ], categoryPayload.rest)

ZeroMessage ==
    [ messageLength              |-> 0,
      messageType                |-> [i \in 1 .. 1 |-> 0],
      participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp1,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      reserved                   |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      categoryPayload            |-> ZeroCategoryPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp1 }
        \cup { [ZeroMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.reserved = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
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
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ blockSeparator      : Sample(2),
      version             : Sample(1),
      blockSize           : Sample(2),
      blockSequenceNumber : Sample(4),
      blockChecksum       : Sample(2),
      message             : SampleLists(OneMessage),
      blockPadByte        : SampleBytes ]

EncodePacket(message) ==
    message.blockSeparator
        \o message.version
        \o message.blockSize
        \o message.blockSequenceNumber
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.blockChecksum
        \o EncodeMessageList(message.message)
        \o message.blockPadByte

DecodePacket(bytes) ==
    LET blockSeparator == ReadBytes(bytes, 2) IN IF ~blockSeparator.ok THEN Fail ELSE
    LET version == ReadBytes(blockSeparator.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET blockSize == ReadBytes(version.rest, 2) IN IF ~blockSize.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(blockSize.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET messagesInBlock == ReadUIntBE(blockSequenceNumber.rest, 1) IN IF ~messagesInBlock.ok THEN Fail ELSE
    LET blockChecksum == ReadBytes(messagesInBlock.rest, 2) IN IF ~blockChecksum.ok THEN Fail ELSE
    LET message == ReadMessageList(blockChecksum.rest, messagesInBlock.value) IN IF ~message.ok THEN Fail ELSE
    LET blockPadByte == Ok(message.rest, << >>) IN IF ~blockPadByte.ok THEN Fail ELSE
    Ok([ blockSeparator      |-> blockSeparator.value,
         version             |-> version.value,
         blockSize           |-> blockSize.value,
         blockSequenceNumber |-> blockSequenceNumber.value,
         blockChecksum       |-> blockChecksum.value,
         message             |-> message.value,
         blockPadByte        |-> blockPadByte.value ], blockPadByte.rest)

ZeroPacket ==
    [ blockSeparator      |-> [i \in 1 .. 2 |-> 0],
      version             |-> [i \in 1 .. 1 |-> 0],
      blockSize           |-> [i \in 1 .. 2 |-> 0],
      blockSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      blockChecksum       |-> [i \in 1 .. 2 |-> 0],
      message             |-> << >>,
      blockPadByte        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.blockSeparator = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
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

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp1 ==
    \A message \in CheckedTimestamp1 :
        LET read == DecodeTimestamp1(EncodeTimestamp1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rejection Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectionMessage ==
    \A message \in CheckedRejectionMessage :
        LET read == DecodeRejectionMessage(EncodeRejectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Warning Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWarningMessage ==
    \A message \in CheckedWarningMessage :
        LET read == DecodeWarningMessage(EncodeWarningMessage(message))
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

(* Every Sequence Information And Message Count Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceInformationAndMessageCountResponseMessage ==
    \A message \in CheckedSequenceInformationAndMessageCountResponseMessage :
        LET read == DecodeSequenceInformationAndMessageCountResponseMessage(EncodeSequenceInformationAndMessageCountResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTestMessage ==
    \A message \in CheckedTestMessage :
        LET read == DecodeTestMessage(EncodeTestMessage(message))
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

(* Every Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMessage ==
    \A message \in CheckedIndexMessage :
        LET read == DecodeIndexMessage(EncodeIndexMessage(message))
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

(* Every Approximate Trades And Total Dollar Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApproximateTradesAndTotalDollarValueMessage ==
    \A message \in CheckedApproximateTradesAndTotalDollarValueMessage :
        LET read == DecodeApproximateTradesAndTotalDollarValueMessage(EncodeApproximateTradesAndTotalDollarValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Crossing Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossingSessionMessage ==
    \A message \in CheckedCrossingSessionMessage :
        LET read == DecodeCrossingSessionMessage(EncodeCrossingSessionMessage(message))
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

(* Every Corrected Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedPriorDayTradeDateAndTime ==
    \A message \in CheckedCorrectedPriorDayTradeDateAndTime :
        LET read == DecodeCorrectedPriorDayTradeDateAndTime(EncodeCorrectedPriorDayTradeDateAndTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalPriorDayTradeDateAndTime ==
    \A message \in CheckedOriginalPriorDayTradeDateAndTime :
        LET read == DecodeOriginalPriorDayTradeDateAndTime(EncodeOriginalPriorDayTradeDateAndTime(message))
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

(* Every Corrected Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedPriorDayTradeDateAndTime2 ==
    \A message \in CheckedCorrectedPriorDayTradeDateAndTime2 :
        LET read == DecodeCorrectedPriorDayTradeDateAndTime2(EncodeCorrectedPriorDayTradeDateAndTime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalPriorDayTradeDateAndTime2 ==
    \A message \in CheckedOriginalPriorDayTradeDateAndTime2 :
        LET read == DecodeOriginalPriorDayTradeDateAndTime2(EncodeOriginalPriorDayTradeDateAndTime2(message))
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

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime ==
    \A message \in CheckedPriorDayTradeDateAndTime :
        LET read == DecodePriorDayTradeDateAndTime(EncodePriorDayTradeDateAndTime(message))
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

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime2 ==
    \A message \in CheckedPriorDayTradeDateAndTime2 :
        LET read == DecodePriorDayTradeDateAndTime2(EncodePriorDayTradeDateAndTime2(message))
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

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime3 ==
    \A message \in CheckedPriorDayTradeDateAndTime3 :
        LET read == DecodePriorDayTradeDateAndTime3(EncodePriorDayTradeDateAndTime3(message))
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

(* Every Prior Day Trade Date And Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime4 ==
    \A message \in CheckedPriorDayTradeDateAndTime4 :
        LET read == DecodePriorDayTradeDateAndTime4(EncodePriorDayTradeDateAndTime4(message))
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

(* Every Auction Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionStatusMessage ==
    \A message \in CheckedAuctionStatusMessage :
        LET read == DecodeAuctionStatusMessage(EncodeAuctionStatusMessage(message))
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

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
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

(* Every Fractional Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalTradeCorrectionMessage ==
    \A message \in CheckedFractionalTradeCorrectionMessage :
        LET read == DecodeFractionalTradeCorrectionMessage(EncodeFractionalTradeCorrectionMessage(message))
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

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
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

(* Every Fractional Short Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalShortTradeMessage ==
    \A message \in CheckedFractionalShortTradeMessage :
        LET read == DecodeFractionalShortTradeMessage(EncodeFractionalShortTradeMessage(message))
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

(* Every Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorMessage ==
    \A message \in CheckedTradeCancelErrorMessage :
        LET read == DecodeTradeCancelErrorMessage(EncodeTradeCancelErrorMessage(message))
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

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
