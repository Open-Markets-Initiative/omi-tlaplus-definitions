---------------------- MODULE Siac_Cqs_Output_v2_10_a ----------------------
(***************************************************************************)
(* The Securities Industry Automation Corporation  v2.10.a                 *)
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
(* Note: a National Bbo Indicator of any value but 81 or 73 or 85 or 80 or *)
(* 72 or 84 carries none of them.                                          *)
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
(* SIP Block Timestamp: 8 bytes                                            *)
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

(* SIP Block Timestamp at zero, then each field in turn at the values it is checked at *)
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
(* Symbol Reference Data Message: 205 bytes                                *)
(***************************************************************************)

SymbolReferenceDataMessage ==
    [ participantId                            : Sample(1),
      timestamp1                               : Timestamp1,
      messageId                                : Sample(1),
      transactionId                            : Sample(4),
      participantReferenceNumber               : Sample(8),
      securitySymbol                           : Sample(11),
      priorSecuritySymbol                      : Sample(11),
      primaryListingMarketParticipantId        : Sample(1),
      primaryListingMarketPreviousClosingPrice : Sample(8),
      consolidatedClosingPrice                 : Sample(8),
      roundLotSize                             : Sample(2),
      reserved                                 : Sample(1),
      luldTier                                 : Sample(1),
      luldLeverageRatio                        : Sample(4),
      test                                     : Sample(1),
      ipo                                      : Sample(1),
      financialStatusIndicator                 : Sample(1),
      shortSaleRestrictionIndicator            : Sample(1),
      haltReason                               : Sample(1),
      instrumentType                           : Sample(1),
      secondReserved                           : Sample(1),
      thirdReserved                            : Sample(1),
      reserved128                              : Sample(128) ]

EncodeSymbolReferenceDataMessage(message) ==
    message.participantId
        \o EncodeTimestamp1(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.priorSecuritySymbol
        \o message.primaryListingMarketParticipantId
        \o message.primaryListingMarketPreviousClosingPrice
        \o message.consolidatedClosingPrice
        \o message.roundLotSize
        \o message.reserved
        \o message.luldTier
        \o message.luldLeverageRatio
        \o message.test
        \o message.ipo
        \o message.financialStatusIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.haltReason
        \o message.instrumentType
        \o message.secondReserved
        \o message.thirdReserved
        \o message.reserved128

DecodeSymbolReferenceDataMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp1(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET priorSecuritySymbol == ReadBytes(securitySymbol.rest, 11) IN IF ~priorSecuritySymbol.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(priorSecuritySymbol.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET primaryListingMarketPreviousClosingPrice == ReadBytes(primaryListingMarketParticipantId.rest, 8) IN IF ~primaryListingMarketPreviousClosingPrice.ok THEN Fail ELSE
    LET consolidatedClosingPrice == ReadBytes(primaryListingMarketPreviousClosingPrice.rest, 8) IN IF ~consolidatedClosingPrice.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(consolidatedClosingPrice.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET reserved == ReadBytes(roundLotSize.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET luldTier == ReadBytes(reserved.rest, 1) IN IF ~luldTier.ok THEN Fail ELSE
    LET luldLeverageRatio == ReadBytes(luldTier.rest, 4) IN IF ~luldLeverageRatio.ok THEN Fail ELSE
    LET test == ReadBytes(luldLeverageRatio.rest, 1) IN IF ~test.ok THEN Fail ELSE
    LET ipo == ReadBytes(test.rest, 1) IN IF ~ipo.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(ipo.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET haltReason == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(haltReason.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET secondReserved == ReadBytes(instrumentType.rest, 1) IN IF ~secondReserved.ok THEN Fail ELSE
    LET thirdReserved == ReadBytes(secondReserved.rest, 1) IN IF ~thirdReserved.ok THEN Fail ELSE
    LET reserved128 == ReadBytes(thirdReserved.rest, 128) IN IF ~reserved128.ok THEN Fail ELSE
    Ok([ participantId                            |-> participantId.value,
         timestamp1                               |-> timestamp1.value,
         messageId                                |-> messageId.value,
         transactionId                            |-> transactionId.value,
         participantReferenceNumber               |-> participantReferenceNumber.value,
         securitySymbol                           |-> securitySymbol.value,
         priorSecuritySymbol                      |-> priorSecuritySymbol.value,
         primaryListingMarketParticipantId        |-> primaryListingMarketParticipantId.value,
         primaryListingMarketPreviousClosingPrice |-> primaryListingMarketPreviousClosingPrice.value,
         consolidatedClosingPrice                 |-> consolidatedClosingPrice.value,
         roundLotSize                             |-> roundLotSize.value,
         reserved                                 |-> reserved.value,
         luldTier                                 |-> luldTier.value,
         luldLeverageRatio                        |-> luldLeverageRatio.value,
         test                                     |-> test.value,
         ipo                                      |-> ipo.value,
         financialStatusIndicator                 |-> financialStatusIndicator.value,
         shortSaleRestrictionIndicator            |-> shortSaleRestrictionIndicator.value,
         haltReason                               |-> haltReason.value,
         instrumentType                           |-> instrumentType.value,
         secondReserved                           |-> secondReserved.value,
         thirdReserved                            |-> thirdReserved.value,
         reserved128                              |-> reserved128.value ], reserved128.rest)

ZeroSymbolReferenceDataMessage ==
    [ participantId                            |-> [i \in 1 .. 1 |-> 0],
      timestamp1                               |-> ZeroTimestamp1,
      messageId                                |-> [i \in 1 .. 1 |-> 0],
      transactionId                            |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber               |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                           |-> [i \in 1 .. 11 |-> 0],
      priorSecuritySymbol                      |-> [i \in 1 .. 11 |-> 0],
      primaryListingMarketParticipantId        |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketPreviousClosingPrice |-> [i \in 1 .. 8 |-> 0],
      consolidatedClosingPrice                 |-> [i \in 1 .. 8 |-> 0],
      roundLotSize                             |-> [i \in 1 .. 2 |-> 0],
      reserved                                 |-> [i \in 1 .. 1 |-> 0],
      luldTier                                 |-> [i \in 1 .. 1 |-> 0],
      luldLeverageRatio                        |-> [i \in 1 .. 4 |-> 0],
      test                                     |-> [i \in 1 .. 1 |-> 0],
      ipo                                      |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator                 |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator            |-> [i \in 1 .. 1 |-> 0],
      haltReason                               |-> [i \in 1 .. 1 |-> 0],
      instrumentType                           |-> [i \in 1 .. 1 |-> 0],
      secondReserved                           |-> [i \in 1 .. 1 |-> 0],
      thirdReserved                            |-> [i \in 1 .. 1 |-> 0],
      reserved128                              |-> [i \in 1 .. 128 |-> 0] ]

(* Symbol Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolReferenceDataMessage ==
    { ZeroSymbolReferenceDataMessage }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp1 }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.priorSecuritySymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.primaryListingMarketPreviousClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.consolidatedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.roundLotSize = one] : one \in Sample(2) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.luldTier = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.luldLeverageRatio = one] : one \in Sample(4) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.test = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.ipo = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.secondReserved = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.thirdReserved = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.reserved128 = one] : one \in Sample(128) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

SymbolReferenceDataMessageCode == 83  \* "S"

AdministrativeMessagePayload ==
    [ tag : {SymbolReferenceDataMessageCode}, body : SymbolReferenceDataMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = SymbolReferenceDataMessageCode -> EncodeSymbolReferenceDataMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = SymbolReferenceDataMessageCode -> DecodeSymbolReferenceDataMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> SymbolReferenceDataMessageCode, body |-> ZeroSymbolReferenceDataMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> SymbolReferenceDataMessageCode, body |-> one] : one \in CheckedSymbolReferenceDataMessage }

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
(* Start Of Day Message: 22 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp12,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeStartOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp12(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeStartOfDayMessage(bytes) ==
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

ZeroStartOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp12,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp12 }
        \cup { [ZeroStartOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Finra Close Message: 22 bytes                                           *)
(***************************************************************************)

FinraCloseMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp13,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeFinraCloseMessage(message) ==
    message.participantId
        \o EncodeTimestamp13(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeFinraCloseMessage(bytes) ==
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

ZeroFinraCloseMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp13,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Finra Close Message at zero, then each field in turn at the values it is checked at *)
CheckedFinraCloseMessage ==
    { ZeroFinraCloseMessage }
        \cup { [ZeroFinraCloseMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFinraCloseMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp13 }
        \cup { [ZeroFinraCloseMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFinraCloseMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFinraCloseMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Reset Block Sequence Number Message: 22 bytes                           *)
(***************************************************************************)

ResetBlockSequenceNumberMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp14,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeResetBlockSequenceNumberMessage(message) ==
    message.participantId
        \o EncodeTimestamp14(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeResetBlockSequenceNumberMessage(bytes) ==
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

ZeroResetBlockSequenceNumberMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp14,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Reset Block Sequence Number Message at zero, then each field in turn at the values it is checked at *)
CheckedResetBlockSequenceNumberMessage ==
    { ZeroResetBlockSequenceNumberMessage }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp14 }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Finra Open Message: 22 bytes                                            *)
(***************************************************************************)

FinraOpenMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp15,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeFinraOpenMessage(message) ==
    message.participantId
        \o EncodeTimestamp15(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeFinraOpenMessage(bytes) ==
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

ZeroFinraOpenMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp15,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Finra Open Message at zero, then each field in turn at the values it is checked at *)
CheckedFinraOpenMessage ==
    { ZeroFinraOpenMessage }
        \cup { [ZeroFinraOpenMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFinraOpenMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp15 }
        \cup { [ZeroFinraOpenMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFinraOpenMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFinraOpenMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Disaster Recovery Data Center Activation Message: 22 bytes              *)
(***************************************************************************)

DisasterRecoveryDataCenterActivationMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp16,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeDisasterRecoveryDataCenterActivationMessage(message) ==
    message.participantId
        \o EncodeTimestamp16(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeDisasterRecoveryDataCenterActivationMessage(bytes) ==
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

ZeroDisasterRecoveryDataCenterActivationMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp16,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Disaster Recovery Data Center Activation Message at zero, then each field in turn at the values it is checked at *)
CheckedDisasterRecoveryDataCenterActivationMessage ==
    { ZeroDisasterRecoveryDataCenterActivationMessage }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp16 }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Line Integrity Message: 22 bytes                                        *)
(***************************************************************************)

LineIntegrityMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp17,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeLineIntegrityMessage(message) ==
    message.participantId
        \o EncodeTimestamp17(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeLineIntegrityMessage(bytes) ==
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

ZeroLineIntegrityMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp17,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Line Integrity Message at zero, then each field in turn at the values it is checked at *)
CheckedLineIntegrityMessage ==
    { ZeroLineIntegrityMessage }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp17 }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* End Of Day Message: 22 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp18,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeEndOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp18(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeEndOfDayMessage(bytes) ==
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

ZeroEndOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp18,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp18 }
        \cup { [ZeroEndOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 65  \* "A"
FinraCloseMessageCode == 67  \* "C"
ResetBlockSequenceNumberMessageCode == 76  \* "L"
FinraOpenMessageCode == 79  \* "O"
DisasterRecoveryDataCenterActivationMessageCode == 80  \* "P"
LineIntegrityMessageCode == 84  \* "T"
EndOfDayMessageCode == 90  \* "Z"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {FinraCloseMessageCode}, body : FinraCloseMessage ]
        \cup [ tag : {ResetBlockSequenceNumberMessageCode}, body : ResetBlockSequenceNumberMessage ]
        \cup [ tag : {FinraOpenMessageCode}, body : FinraOpenMessage ]
        \cup [ tag : {DisasterRecoveryDataCenterActivationMessageCode}, body : DisasterRecoveryDataCenterActivationMessage ]
        \cup [ tag : {LineIntegrityMessageCode}, body : LineIntegrityMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = FinraCloseMessageCode -> EncodeFinraCloseMessage(message.body)
      [] message.tag = ResetBlockSequenceNumberMessageCode -> EncodeResetBlockSequenceNumberMessage(message.body)
      [] message.tag = FinraOpenMessageCode -> EncodeFinraOpenMessage(message.body)
      [] message.tag = DisasterRecoveryDataCenterActivationMessageCode -> EncodeDisasterRecoveryDataCenterActivationMessage(message.body)
      [] message.tag = LineIntegrityMessageCode -> EncodeLineIntegrityMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = FinraCloseMessageCode -> DecodeFinraCloseMessage(bytes)
              [] tag = ResetBlockSequenceNumberMessageCode -> DecodeResetBlockSequenceNumberMessage(bytes)
              [] tag = FinraOpenMessageCode -> DecodeFinraOpenMessage(bytes)
              [] tag = DisasterRecoveryDataCenterActivationMessageCode -> DecodeDisasterRecoveryDataCenterActivationMessage(bytes)
              [] tag = LineIntegrityMessageCode -> DecodeLineIntegrityMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> FinraCloseMessageCode, body |-> one] : one \in CheckedFinraCloseMessage }
        \cup { [tag |-> ResetBlockSequenceNumberMessageCode, body |-> one] : one \in CheckedResetBlockSequenceNumberMessage }
        \cup { [tag |-> FinraOpenMessageCode, body |-> one] : one \in CheckedFinraOpenMessage }
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
(* Market Wide Circuit Breaker Decline Level Status Message: 47 bytes      *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelStatusMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp19,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      mwcbLevel1                 : Sample(8),
      mwcbLevel2                 : Sample(8),
      mwcbLevel3                 : Sample(8),
      reserved                   : Sample(1) ]

EncodeMarketWideCircuitBreakerDeclineLevelStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp19(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3
        \o message.reserved

DecodeMarketWideCircuitBreakerDeclineLevelStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp19(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                 |-> ZeroTimestamp19,
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
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp19 }
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
(* Market Wide Circuit Breaker Status Message: 24 bytes                    *)
(***************************************************************************)

MarketWideCircuitBreakerStatusMessage ==
    [ participantId                          : Sample(1),
      timestamp1                             : Timestamp110,
      messageId                              : Sample(1),
      transactionId                          : Sample(4),
      participantReferenceNumber             : Sample(8),
      marketWideCircuitBreakerLevelIndicator : Sample(1),
      reserved                               : Sample(1) ]

EncodeMarketWideCircuitBreakerStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp110(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.marketWideCircuitBreakerLevelIndicator
        \o message.reserved

DecodeMarketWideCircuitBreakerStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp110(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                             |-> ZeroTimestamp110,
      messageId                              |-> [i \in 1 .. 1 |-> 0],
      transactionId                          |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber             |-> [i \in 1 .. 8 |-> 0],
      marketWideCircuitBreakerLevelIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved                               |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerStatusMessage ==
    { ZeroMarketWideCircuitBreakerStatusMessage }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp110 }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.marketWideCircuitBreakerLevelIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.reserved = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Status Message Payload, selected by Market Status Message Type   *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelStatusMessageCode == 75  \* "K"
MarketWideCircuitBreakerStatusMessageCode == 76  \* "L"

MarketStatusMessagePayload ==
    [ tag : {MarketWideCircuitBreakerDeclineLevelStatusMessageCode}, body : MarketWideCircuitBreakerDeclineLevelStatusMessage ]
        \cup [ tag : {MarketWideCircuitBreakerStatusMessageCode}, body : MarketWideCircuitBreakerStatusMessage ]

EncodeMarketStatusMessagePayload(message) ==
    CASE message.tag = MarketWideCircuitBreakerDeclineLevelStatusMessageCode -> EncodeMarketWideCircuitBreakerDeclineLevelStatusMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerStatusMessageCode -> EncodeMarketWideCircuitBreakerStatusMessage(message.body)

DecodeMarketStatusMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = MarketWideCircuitBreakerDeclineLevelStatusMessageCode -> DecodeMarketWideCircuitBreakerDeclineLevelStatusMessage(bytes)
              [] tag = MarketWideCircuitBreakerStatusMessageCode -> DecodeMarketWideCircuitBreakerStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMarketStatusMessagePayload == [tag |-> MarketWideCircuitBreakerDeclineLevelStatusMessageCode, body |-> ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage]

(* Each Market Status Message Payload in turn, at the values the message it names is checked at *)
CheckedMarketStatusMessagePayload ==
    { [tag |-> MarketWideCircuitBreakerDeclineLevelStatusMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerDeclineLevelStatusMessage }
        \cup { [tag |-> MarketWideCircuitBreakerStatusMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerStatusMessage }

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
(* Auction Status Message: 124 bytes                                       *)
(***************************************************************************)

AuctionStatusMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp111,
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
      reserved62                        : Sample(62) ]

EncodeAuctionStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp111(message.timestamp1)
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
        \o message.reserved62

DecodeAuctionStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp111(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
    LET reserved62 == ReadBytes(financialStatusIndicator.rest, 62) IN IF ~reserved62.ok THEN Fail ELSE
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
         reserved62                        |-> reserved62.value ], reserved62.rest)

ZeroAuctionStatusMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      timestamp1                        |-> ZeroTimestamp111,
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
      reserved62                        |-> [i \in 1 .. 62 |-> 0] ]

(* Auction Status Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionStatusMessage ==
    { ZeroAuctionStatusMessage }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroAuctionStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp111 }
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
        \cup { [ZeroAuctionStatusMessage EXCEPT !.reserved62 = one] : one \in Sample(62) }

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
(* National Best Bid Long Appendage: 18 bytes                              *)
(***************************************************************************)

NationalBestBidLongAppendage ==
    [ bestBidParticipantId      : Sample(1),
      bestBidQuoteCondition     : Sample(1),
      bestBidPriceLong          : Sample(8),
      bestBidSizeLong           : Sample(4),
      finraBestBidMarketMakerId : Sample(4) ]

EncodeNationalBestBidLongAppendage(message) ==
    message.bestBidParticipantId
        \o message.bestBidQuoteCondition
        \o message.bestBidPriceLong
        \o message.bestBidSizeLong
        \o message.finraBestBidMarketMakerId

DecodeNationalBestBidLongAppendage(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidQuoteCondition == ReadBytes(bestBidParticipantId.rest, 1) IN IF ~bestBidQuoteCondition.ok THEN Fail ELSE
    LET bestBidPriceLong == ReadBytes(bestBidQuoteCondition.rest, 8) IN IF ~bestBidPriceLong.ok THEN Fail ELSE
    LET bestBidSizeLong == ReadBytes(bestBidPriceLong.rest, 4) IN IF ~bestBidSizeLong.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(bestBidSizeLong.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    Ok([ bestBidParticipantId      |-> bestBidParticipantId.value,
         bestBidQuoteCondition     |-> bestBidQuoteCondition.value,
         bestBidPriceLong          |-> bestBidPriceLong.value,
         bestBidSizeLong           |-> bestBidSizeLong.value,
         finraBestBidMarketMakerId |-> finraBestBidMarketMakerId.value ], finraBestBidMarketMakerId.rest)

ZeroNationalBestBidLongAppendage ==
    [ bestBidParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestBidQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestBidSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Bid Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidLongAppendage ==
    { ZeroNationalBestBidLongAppendage }
        \cup { [ZeroNationalBestBidLongAppendage EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidLongAppendage EXCEPT !.bestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidLongAppendage EXCEPT !.bestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidLongAppendage EXCEPT !.bestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidLongAppendage EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Offer Long Appendage: 18 bytes                            *)
(***************************************************************************)

NationalBestOfferLongAppendage ==
    [ bestOfferParticipantId      : Sample(1),
      bestOfferQuoteCondition     : Sample(1),
      bestOfferPriceLong          : Sample(8),
      bestOfferSizeLong           : Sample(4),
      finraBestOfferMarketMakerId : Sample(4) ]

EncodeNationalBestOfferLongAppendage(message) ==
    message.bestOfferParticipantId
        \o message.bestOfferQuoteCondition
        \o message.bestOfferPriceLong
        \o message.bestOfferSizeLong
        \o message.finraBestOfferMarketMakerId

DecodeNationalBestOfferLongAppendage(bytes) ==
    LET bestOfferParticipantId == ReadBytes(bytes, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferQuoteCondition == ReadBytes(bestOfferParticipantId.rest, 1) IN IF ~bestOfferQuoteCondition.ok THEN Fail ELSE
    LET bestOfferPriceLong == ReadBytes(bestOfferQuoteCondition.rest, 8) IN IF ~bestOfferPriceLong.ok THEN Fail ELSE
    LET bestOfferSizeLong == ReadBytes(bestOfferPriceLong.rest, 4) IN IF ~bestOfferSizeLong.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(bestOfferSizeLong.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    Ok([ bestOfferParticipantId      |-> bestOfferParticipantId.value,
         bestOfferQuoteCondition     |-> bestOfferQuoteCondition.value,
         bestOfferPriceLong          |-> bestOfferPriceLong.value,
         bestOfferSizeLong           |-> bestOfferSizeLong.value,
         finraBestOfferMarketMakerId |-> finraBestOfferMarketMakerId.value ], finraBestOfferMarketMakerId.rest)

ZeroNationalBestOfferLongAppendage ==
    [ bestOfferParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestOfferQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestOfferSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Offer Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestOfferLongAppendage ==
    { ZeroNationalBestOfferLongAppendage }
        \cup { [ZeroNationalBestOfferLongAppendage EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferLongAppendage EXCEPT !.bestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferLongAppendage EXCEPT !.bestOfferPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestOfferLongAppendage EXCEPT !.bestOfferSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestOfferLongAppendage EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Bid And Offer Long Appendage: 36 bytes                    *)
(***************************************************************************)

NationalBestBidAndOfferLongAppendage ==
    [ bestBidParticipantId        : Sample(1),
      bestBidQuoteCondition       : Sample(1),
      bestBidPriceLong            : Sample(8),
      bestBidSizeLong             : Sample(4),
      finraBestBidMarketMakerId   : Sample(4),
      bestOfferParticipantId      : Sample(1),
      bestOfferQuoteCondition     : Sample(1),
      bestOfferPriceLong          : Sample(8),
      bestOfferSizeLong           : Sample(4),
      finraBestOfferMarketMakerId : Sample(4) ]

EncodeNationalBestBidAndOfferLongAppendage(message) ==
    message.bestBidParticipantId
        \o message.bestBidQuoteCondition
        \o message.bestBidPriceLong
        \o message.bestBidSizeLong
        \o message.finraBestBidMarketMakerId
        \o message.bestOfferParticipantId
        \o message.bestOfferQuoteCondition
        \o message.bestOfferPriceLong
        \o message.bestOfferSizeLong
        \o message.finraBestOfferMarketMakerId

DecodeNationalBestBidAndOfferLongAppendage(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidQuoteCondition == ReadBytes(bestBidParticipantId.rest, 1) IN IF ~bestBidQuoteCondition.ok THEN Fail ELSE
    LET bestBidPriceLong == ReadBytes(bestBidQuoteCondition.rest, 8) IN IF ~bestBidPriceLong.ok THEN Fail ELSE
    LET bestBidSizeLong == ReadBytes(bestBidPriceLong.rest, 4) IN IF ~bestBidSizeLong.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(bestBidSizeLong.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    LET bestOfferParticipantId == ReadBytes(finraBestBidMarketMakerId.rest, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferQuoteCondition == ReadBytes(bestOfferParticipantId.rest, 1) IN IF ~bestOfferQuoteCondition.ok THEN Fail ELSE
    LET bestOfferPriceLong == ReadBytes(bestOfferQuoteCondition.rest, 8) IN IF ~bestOfferPriceLong.ok THEN Fail ELSE
    LET bestOfferSizeLong == ReadBytes(bestOfferPriceLong.rest, 4) IN IF ~bestOfferSizeLong.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(bestOfferSizeLong.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    Ok([ bestBidParticipantId        |-> bestBidParticipantId.value,
         bestBidQuoteCondition       |-> bestBidQuoteCondition.value,
         bestBidPriceLong            |-> bestBidPriceLong.value,
         bestBidSizeLong             |-> bestBidSizeLong.value,
         finraBestBidMarketMakerId   |-> finraBestBidMarketMakerId.value,
         bestOfferParticipantId      |-> bestOfferParticipantId.value,
         bestOfferQuoteCondition     |-> bestOfferQuoteCondition.value,
         bestOfferPriceLong          |-> bestOfferPriceLong.value,
         bestOfferSizeLong           |-> bestOfferSizeLong.value,
         finraBestOfferMarketMakerId |-> finraBestOfferMarketMakerId.value ], finraBestOfferMarketMakerId.rest)

ZeroNationalBestBidAndOfferLongAppendage ==
    [ bestBidParticipantId        |-> [i \in 1 .. 1 |-> 0],
      bestBidQuoteCondition       |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceLong            |-> [i \in 1 .. 8 |-> 0],
      bestBidSizeLong             |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId   |-> [i \in 1 .. 4 |-> 0],
      bestOfferParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestOfferQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestOfferSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Bid And Offer Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidAndOfferLongAppendage ==
    { ZeroNationalBestBidAndOfferLongAppendage }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.bestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.bestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.bestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.bestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.bestOfferPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.bestOfferSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Bid Short Appendage: 5 bytes                              *)
(***************************************************************************)

NationalBestBidShortAppendage ==
    [ bestBidParticipantId : Sample(1),
      bestBidPriceShort    : Sample(2),
      bestBidSizeShort     : Sample(2) ]

EncodeNationalBestBidShortAppendage(message) ==
    message.bestBidParticipantId
        \o message.bestBidPriceShort
        \o message.bestBidSizeShort

DecodeNationalBestBidShortAppendage(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidPriceShort == ReadBytes(bestBidParticipantId.rest, 2) IN IF ~bestBidPriceShort.ok THEN Fail ELSE
    LET bestBidSizeShort == ReadBytes(bestBidPriceShort.rest, 2) IN IF ~bestBidSizeShort.ok THEN Fail ELSE
    Ok([ bestBidParticipantId |-> bestBidParticipantId.value,
         bestBidPriceShort    |-> bestBidPriceShort.value,
         bestBidSizeShort     |-> bestBidSizeShort.value ], bestBidSizeShort.rest)

ZeroNationalBestBidShortAppendage ==
    [ bestBidParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestBidSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Bid Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidShortAppendage ==
    { ZeroNationalBestBidShortAppendage }
        \cup { [ZeroNationalBestBidShortAppendage EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidShortAppendage EXCEPT !.bestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidShortAppendage EXCEPT !.bestBidSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Best Offer Short Appendage: 5 bytes                            *)
(***************************************************************************)

NationalBestOfferShortAppendage ==
    [ bestOfferParticipantId : Sample(1),
      bestOfferPriceShort    : Sample(2),
      bestOfferSizeShort     : Sample(2) ]

EncodeNationalBestOfferShortAppendage(message) ==
    message.bestOfferParticipantId
        \o message.bestOfferPriceShort
        \o message.bestOfferSizeShort

DecodeNationalBestOfferShortAppendage(bytes) ==
    LET bestOfferParticipantId == ReadBytes(bytes, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferPriceShort == ReadBytes(bestOfferParticipantId.rest, 2) IN IF ~bestOfferPriceShort.ok THEN Fail ELSE
    LET bestOfferSizeShort == ReadBytes(bestOfferPriceShort.rest, 2) IN IF ~bestOfferSizeShort.ok THEN Fail ELSE
    Ok([ bestOfferParticipantId |-> bestOfferParticipantId.value,
         bestOfferPriceShort    |-> bestOfferPriceShort.value,
         bestOfferSizeShort     |-> bestOfferSizeShort.value ], bestOfferSizeShort.rest)

ZeroNationalBestOfferShortAppendage ==
    [ bestOfferParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestOfferSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Offer Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestOfferShortAppendage ==
    { ZeroNationalBestOfferShortAppendage }
        \cup { [ZeroNationalBestOfferShortAppendage EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferShortAppendage EXCEPT !.bestOfferPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestOfferShortAppendage EXCEPT !.bestOfferSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Best Bid And Offer Short Appendage: 10 bytes                   *)
(***************************************************************************)

NationalBestBidAndOfferShortAppendage ==
    [ bestBidParticipantId   : Sample(1),
      bestBidPriceShort      : Sample(2),
      bestBidSizeShort       : Sample(2),
      bestOfferParticipantId : Sample(1),
      bestOfferPriceShort    : Sample(2),
      bestOfferSizeShort     : Sample(2) ]

EncodeNationalBestBidAndOfferShortAppendage(message) ==
    message.bestBidParticipantId
        \o message.bestBidPriceShort
        \o message.bestBidSizeShort
        \o message.bestOfferParticipantId
        \o message.bestOfferPriceShort
        \o message.bestOfferSizeShort

DecodeNationalBestBidAndOfferShortAppendage(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidPriceShort == ReadBytes(bestBidParticipantId.rest, 2) IN IF ~bestBidPriceShort.ok THEN Fail ELSE
    LET bestBidSizeShort == ReadBytes(bestBidPriceShort.rest, 2) IN IF ~bestBidSizeShort.ok THEN Fail ELSE
    LET bestOfferParticipantId == ReadBytes(bestBidSizeShort.rest, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferPriceShort == ReadBytes(bestOfferParticipantId.rest, 2) IN IF ~bestOfferPriceShort.ok THEN Fail ELSE
    LET bestOfferSizeShort == ReadBytes(bestOfferPriceShort.rest, 2) IN IF ~bestOfferSizeShort.ok THEN Fail ELSE
    Ok([ bestBidParticipantId   |-> bestBidParticipantId.value,
         bestBidPriceShort      |-> bestBidPriceShort.value,
         bestBidSizeShort       |-> bestBidSizeShort.value,
         bestOfferParticipantId |-> bestOfferParticipantId.value,
         bestOfferPriceShort    |-> bestOfferPriceShort.value,
         bestOfferSizeShort     |-> bestOfferSizeShort.value ], bestOfferSizeShort.rest)

ZeroNationalBestBidAndOfferShortAppendage ==
    [ bestBidParticipantId   |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceShort      |-> [i \in 1 .. 2 |-> 0],
      bestBidSizeShort       |-> [i \in 1 .. 2 |-> 0],
      bestOfferParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestOfferSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Bid And Offer Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidAndOfferShortAppendage ==
    { ZeroNationalBestBidAndOfferShortAppendage }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage EXCEPT !.bestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage EXCEPT !.bestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage EXCEPT !.bestOfferPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage EXCEPT !.bestOfferSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* What National Bbo Indicator decides is present                          *)
(***************************************************************************)

NationalBestBidLongAppendageCode == 81  \* "Q"
NationalBestOfferLongAppendageCode == 73  \* "I"
NationalBestBidAndOfferLongAppendageCode == 85  \* "U"
NationalBestBidShortAppendageCode == 80  \* "P"
NationalBestOfferShortAppendageCode == 72  \* "H"
NationalBestBidAndOfferShortAppendageCode == 84  \* "T"
NationalBboIndicatorNoneCode == 0  \* 

NationalBboIndicatorChoice ==
    [ tag : {NationalBestBidLongAppendageCode}, body : NationalBestBidLongAppendage ]
        \cup [ tag : {NationalBestOfferLongAppendageCode}, body : NationalBestOfferLongAppendage ]
        \cup [ tag : {NationalBestBidAndOfferLongAppendageCode}, body : NationalBestBidAndOfferLongAppendage ]
        \cup [ tag : {NationalBestBidShortAppendageCode}, body : NationalBestBidShortAppendage ]
        \cup [ tag : {NationalBestOfferShortAppendageCode}, body : NationalBestOfferShortAppendage ]
        \cup [ tag : {NationalBestBidAndOfferShortAppendageCode}, body : NationalBestBidAndOfferShortAppendage ]
        \cup [ tag : {NationalBboIndicatorNoneCode}, body : {[empty |-> 0]} ]

EncodeNationalBboIndicatorChoice(message) ==
    CASE message.tag = NationalBestBidLongAppendageCode -> EncodeNationalBestBidLongAppendage(message.body)
      [] message.tag = NationalBestOfferLongAppendageCode -> EncodeNationalBestOfferLongAppendage(message.body)
      [] message.tag = NationalBestBidAndOfferLongAppendageCode -> EncodeNationalBestBidAndOfferLongAppendage(message.body)
      [] message.tag = NationalBestBidShortAppendageCode -> EncodeNationalBestBidShortAppendage(message.body)
      [] message.tag = NationalBestOfferShortAppendageCode -> EncodeNationalBestOfferShortAppendage(message.body)
      [] message.tag = NationalBestBidAndOfferShortAppendageCode -> EncodeNationalBestBidAndOfferShortAppendage(message.body)
      [] OTHER -> << >>

DecodeNationalBboIndicatorChoice(tag, bytes) ==
    LET read ==
            CASE tag = NationalBestBidLongAppendageCode -> DecodeNationalBestBidLongAppendage(bytes)
              [] tag = NationalBestOfferLongAppendageCode -> DecodeNationalBestOfferLongAppendage(bytes)
              [] tag = NationalBestBidAndOfferLongAppendageCode -> DecodeNationalBestBidAndOfferLongAppendage(bytes)
              [] tag = NationalBestBidShortAppendageCode -> DecodeNationalBestBidShortAppendage(bytes)
              [] tag = NationalBestOfferShortAppendageCode -> DecodeNationalBestOfferShortAppendage(bytes)
              [] tag = NationalBestBidAndOfferShortAppendageCode -> DecodeNationalBestBidAndOfferShortAppendage(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNationalBboIndicatorChoice == [tag |-> NationalBestBidLongAppendageCode, body |-> ZeroNationalBestBidLongAppendage]

(* Each National Bbo Indicator in turn, at the values the message it names is checked at *)
CheckedNationalBboIndicatorChoice ==
    { [tag |-> NationalBestBidLongAppendageCode, body |-> one] : one \in CheckedNationalBestBidLongAppendage }
        \cup { [tag |-> NationalBestOfferLongAppendageCode, body |-> one] : one \in CheckedNationalBestOfferLongAppendage }
        \cup { [tag |-> NationalBestBidAndOfferLongAppendageCode, body |-> one] : one \in CheckedNationalBestBidAndOfferLongAppendage }
        \cup { [tag |-> NationalBestBidShortAppendageCode, body |-> one] : one \in CheckedNationalBestBidShortAppendage }
        \cup { [tag |-> NationalBestOfferShortAppendageCode, body |-> one] : one \in CheckedNationalBestOfferShortAppendage }
        \cup { [tag |-> NationalBestBidAndOfferShortAppendageCode, body |-> one] : one \in CheckedNationalBestBidAndOfferShortAppendage }
        \cup { [tag |-> NationalBboIndicatorNoneCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Long Quote Message                                                      *)
(***************************************************************************)

LongQuoteMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp112,
      messageId                         : Sample(1),
      transactionId                     : Sample(4),
      participantReferenceNumber        : Sample(8),
      securitySymbol                    : Sample(11),
      instrumentType                    : Sample(1),
      quoteCondition                    : Sample(1),
      securityStatusIndicator           : Sample(1),
      bidPriceLowerLimitPriceBand       : Sample(8),
      bidSizeLong                       : Sample(4),
      offerPriceUpperLimitPriceBand     : Sample(8),
      offerSizeLong                     : Sample(4),
      retailInterestIndicator           : Sample(1),
      settlementCondition               : Sample(1),
      marketCondition                   : Sample(1),
      finraMarketMakerId                : Sample(4),
      finraBboIndicator                 : Sample(1),
      timestamp2                        : Timestamp2,
      shortSaleRestrictionIndicator     : Sample(1),
      primaryListingMarketParticipantId : Sample(1),
      financialStatusIndicator          : Sample(1),
      sipGeneratedMessageIdentifier     : Sample(1),
      limitUpLimitDownLuldIndicator     : Sample(1),
      nationalBboLuldIndicator          : Sample(1),
      nationalBboIndicatorChoice        : NationalBboIndicatorChoice ]

EncodeLongQuoteMessage(message) ==
    message.participantId
        \o EncodeTimestamp112(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.quoteCondition
        \o message.securityStatusIndicator
        \o message.bidPriceLowerLimitPriceBand
        \o message.bidSizeLong
        \o message.offerPriceUpperLimitPriceBand
        \o message.offerSizeLong
        \o message.retailInterestIndicator
        \o message.settlementCondition
        \o message.marketCondition
        \o message.finraMarketMakerId
        \o message.finraBboIndicator
        \o EncodeTimestamp2(message.timestamp2)
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.sipGeneratedMessageIdentifier
        \o message.limitUpLimitDownLuldIndicator
        \o message.nationalBboLuldIndicator
        \o EncodeUIntBE(message.nationalBboIndicatorChoice.tag, 1)
        \o EncodeNationalBboIndicatorChoice(message.nationalBboIndicatorChoice)

DecodeLongQuoteMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp112(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(instrumentType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET securityStatusIndicator == ReadBytes(quoteCondition.rest, 1) IN IF ~securityStatusIndicator.ok THEN Fail ELSE
    LET bidPriceLowerLimitPriceBand == ReadBytes(securityStatusIndicator.rest, 8) IN IF ~bidPriceLowerLimitPriceBand.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLowerLimitPriceBand.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET offerPriceUpperLimitPriceBand == ReadBytes(bidSizeLong.rest, 8) IN IF ~offerPriceUpperLimitPriceBand.ok THEN Fail ELSE
    LET offerSizeLong == ReadBytes(offerPriceUpperLimitPriceBand.rest, 4) IN IF ~offerSizeLong.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(offerSizeLong.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET settlementCondition == ReadBytes(retailInterestIndicator.rest, 1) IN IF ~settlementCondition.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(settlementCondition.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET finraMarketMakerId == ReadBytes(marketCondition.rest, 4) IN IF ~finraMarketMakerId.ok THEN Fail ELSE
    LET finraBboIndicator == ReadBytes(finraMarketMakerId.rest, 1) IN IF ~finraBboIndicator.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp2(finraBboIndicator.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(timestamp2.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET sipGeneratedMessageIdentifier == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~sipGeneratedMessageIdentifier.ok THEN Fail ELSE
    LET limitUpLimitDownLuldIndicator == ReadBytes(sipGeneratedMessageIdentifier.rest, 1) IN IF ~limitUpLimitDownLuldIndicator.ok THEN Fail ELSE
    LET nationalBboLuldIndicator == ReadBytes(limitUpLimitDownLuldIndicator.rest, 1) IN IF ~nationalBboLuldIndicator.ok THEN Fail ELSE
    LET nationalBboIndicator == ReadUIntBE(nationalBboLuldIndicator.rest, 1) IN IF ~nationalBboIndicator.ok THEN Fail ELSE
    LET nationalBboIndicatorChoice == DecodeNationalBboIndicatorChoice(nationalBboIndicator.value, nationalBboIndicator.rest) IN IF ~nationalBboIndicatorChoice.ok THEN Fail ELSE
    Ok([ participantId                     |-> participantId.value,
         timestamp1                        |-> timestamp1.value,
         messageId                         |-> messageId.value,
         transactionId                     |-> transactionId.value,
         participantReferenceNumber        |-> participantReferenceNumber.value,
         securitySymbol                    |-> securitySymbol.value,
         instrumentType                    |-> instrumentType.value,
         quoteCondition                    |-> quoteCondition.value,
         securityStatusIndicator           |-> securityStatusIndicator.value,
         bidPriceLowerLimitPriceBand       |-> bidPriceLowerLimitPriceBand.value,
         bidSizeLong                       |-> bidSizeLong.value,
         offerPriceUpperLimitPriceBand     |-> offerPriceUpperLimitPriceBand.value,
         offerSizeLong                     |-> offerSizeLong.value,
         retailInterestIndicator           |-> retailInterestIndicator.value,
         settlementCondition               |-> settlementCondition.value,
         marketCondition                   |-> marketCondition.value,
         finraMarketMakerId                |-> finraMarketMakerId.value,
         finraBboIndicator                 |-> finraBboIndicator.value,
         timestamp2                        |-> timestamp2.value,
         shortSaleRestrictionIndicator     |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator          |-> financialStatusIndicator.value,
         sipGeneratedMessageIdentifier     |-> sipGeneratedMessageIdentifier.value,
         limitUpLimitDownLuldIndicator     |-> limitUpLimitDownLuldIndicator.value,
         nationalBboLuldIndicator          |-> nationalBboLuldIndicator.value,
         nationalBboIndicatorChoice        |-> nationalBboIndicatorChoice.value ], nationalBboIndicatorChoice.rest)

ZeroLongQuoteMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      timestamp1                        |-> ZeroTimestamp112,
      messageId                         |-> [i \in 1 .. 1 |-> 0],
      transactionId                     |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      instrumentType                    |-> [i \in 1 .. 1 |-> 0],
      quoteCondition                    |-> [i \in 1 .. 1 |-> 0],
      securityStatusIndicator           |-> [i \in 1 .. 1 |-> 0],
      bidPriceLowerLimitPriceBand       |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong                       |-> [i \in 1 .. 4 |-> 0],
      offerPriceUpperLimitPriceBand     |-> [i \in 1 .. 8 |-> 0],
      offerSizeLong                     |-> [i \in 1 .. 4 |-> 0],
      retailInterestIndicator           |-> [i \in 1 .. 1 |-> 0],
      settlementCondition               |-> [i \in 1 .. 1 |-> 0],
      marketCondition                   |-> [i \in 1 .. 1 |-> 0],
      finraMarketMakerId                |-> [i \in 1 .. 4 |-> 0],
      finraBboIndicator                 |-> [i \in 1 .. 1 |-> 0],
      timestamp2                        |-> ZeroTimestamp2,
      shortSaleRestrictionIndicator     |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator          |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedMessageIdentifier     |-> [i \in 1 .. 1 |-> 0],
      limitUpLimitDownLuldIndicator     |-> [i \in 1 .. 1 |-> 0],
      nationalBboLuldIndicator          |-> [i \in 1 .. 1 |-> 0],
      nationalBboIndicatorChoice        |-> ZeroNationalBboIndicatorChoice ]

(* Long Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedLongQuoteMessage ==
    { ZeroLongQuoteMessage }
        \cup { [ZeroLongQuoteMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp112 }
        \cup { [ZeroLongQuoteMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.securityStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.bidPriceLowerLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.offerPriceUpperLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.offerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.settlementCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.finraMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.finraBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp2 }
        \cup { [ZeroLongQuoteMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.sipGeneratedMessageIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.limitUpLimitDownLuldIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.nationalBboLuldIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongQuoteMessage EXCEPT !.nationalBboIndicatorChoice = one] : one \in CheckedNationalBboIndicatorChoice }

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
(* National Best Bid Long Appendage: 18 bytes                              *)
(***************************************************************************)

NationalBestBidLongAppendage2 ==
    [ bestBidParticipantId      : Sample(1),
      bestBidQuoteCondition     : Sample(1),
      bestBidPriceLong          : Sample(8),
      bestBidSizeLong           : Sample(4),
      finraBestBidMarketMakerId : Sample(4) ]

EncodeNationalBestBidLongAppendage2(message) ==
    message.bestBidParticipantId
        \o message.bestBidQuoteCondition
        \o message.bestBidPriceLong
        \o message.bestBidSizeLong
        \o message.finraBestBidMarketMakerId

DecodeNationalBestBidLongAppendage2(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidQuoteCondition == ReadBytes(bestBidParticipantId.rest, 1) IN IF ~bestBidQuoteCondition.ok THEN Fail ELSE
    LET bestBidPriceLong == ReadBytes(bestBidQuoteCondition.rest, 8) IN IF ~bestBidPriceLong.ok THEN Fail ELSE
    LET bestBidSizeLong == ReadBytes(bestBidPriceLong.rest, 4) IN IF ~bestBidSizeLong.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(bestBidSizeLong.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    Ok([ bestBidParticipantId      |-> bestBidParticipantId.value,
         bestBidQuoteCondition     |-> bestBidQuoteCondition.value,
         bestBidPriceLong          |-> bestBidPriceLong.value,
         bestBidSizeLong           |-> bestBidSizeLong.value,
         finraBestBidMarketMakerId |-> finraBestBidMarketMakerId.value ], finraBestBidMarketMakerId.rest)

ZeroNationalBestBidLongAppendage2 ==
    [ bestBidParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestBidQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestBidSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Bid Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidLongAppendage2 ==
    { ZeroNationalBestBidLongAppendage2 }
        \cup { [ZeroNationalBestBidLongAppendage2 EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidLongAppendage2 EXCEPT !.bestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidLongAppendage2 EXCEPT !.bestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidLongAppendage2 EXCEPT !.bestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidLongAppendage2 EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Offer Long Appendage: 18 bytes                            *)
(***************************************************************************)

NationalBestOfferLongAppendage2 ==
    [ bestOfferParticipantId      : Sample(1),
      bestOfferQuoteCondition     : Sample(1),
      bestOfferPriceLong          : Sample(8),
      bestOfferSizeLong           : Sample(4),
      finraBestOfferMarketMakerId : Sample(4) ]

EncodeNationalBestOfferLongAppendage2(message) ==
    message.bestOfferParticipantId
        \o message.bestOfferQuoteCondition
        \o message.bestOfferPriceLong
        \o message.bestOfferSizeLong
        \o message.finraBestOfferMarketMakerId

DecodeNationalBestOfferLongAppendage2(bytes) ==
    LET bestOfferParticipantId == ReadBytes(bytes, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferQuoteCondition == ReadBytes(bestOfferParticipantId.rest, 1) IN IF ~bestOfferQuoteCondition.ok THEN Fail ELSE
    LET bestOfferPriceLong == ReadBytes(bestOfferQuoteCondition.rest, 8) IN IF ~bestOfferPriceLong.ok THEN Fail ELSE
    LET bestOfferSizeLong == ReadBytes(bestOfferPriceLong.rest, 4) IN IF ~bestOfferSizeLong.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(bestOfferSizeLong.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    Ok([ bestOfferParticipantId      |-> bestOfferParticipantId.value,
         bestOfferQuoteCondition     |-> bestOfferQuoteCondition.value,
         bestOfferPriceLong          |-> bestOfferPriceLong.value,
         bestOfferSizeLong           |-> bestOfferSizeLong.value,
         finraBestOfferMarketMakerId |-> finraBestOfferMarketMakerId.value ], finraBestOfferMarketMakerId.rest)

ZeroNationalBestOfferLongAppendage2 ==
    [ bestOfferParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestOfferQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestOfferSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Offer Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestOfferLongAppendage2 ==
    { ZeroNationalBestOfferLongAppendage2 }
        \cup { [ZeroNationalBestOfferLongAppendage2 EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferLongAppendage2 EXCEPT !.bestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferLongAppendage2 EXCEPT !.bestOfferPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestOfferLongAppendage2 EXCEPT !.bestOfferSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestOfferLongAppendage2 EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Bid And Offer Long Appendage: 36 bytes                    *)
(***************************************************************************)

NationalBestBidAndOfferLongAppendage2 ==
    [ bestBidParticipantId        : Sample(1),
      bestBidQuoteCondition       : Sample(1),
      bestBidPriceLong            : Sample(8),
      bestBidSizeLong             : Sample(4),
      finraBestBidMarketMakerId   : Sample(4),
      bestOfferParticipantId      : Sample(1),
      bestOfferQuoteCondition     : Sample(1),
      bestOfferPriceLong          : Sample(8),
      bestOfferSizeLong           : Sample(4),
      finraBestOfferMarketMakerId : Sample(4) ]

EncodeNationalBestBidAndOfferLongAppendage2(message) ==
    message.bestBidParticipantId
        \o message.bestBidQuoteCondition
        \o message.bestBidPriceLong
        \o message.bestBidSizeLong
        \o message.finraBestBidMarketMakerId
        \o message.bestOfferParticipantId
        \o message.bestOfferQuoteCondition
        \o message.bestOfferPriceLong
        \o message.bestOfferSizeLong
        \o message.finraBestOfferMarketMakerId

DecodeNationalBestBidAndOfferLongAppendage2(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidQuoteCondition == ReadBytes(bestBidParticipantId.rest, 1) IN IF ~bestBidQuoteCondition.ok THEN Fail ELSE
    LET bestBidPriceLong == ReadBytes(bestBidQuoteCondition.rest, 8) IN IF ~bestBidPriceLong.ok THEN Fail ELSE
    LET bestBidSizeLong == ReadBytes(bestBidPriceLong.rest, 4) IN IF ~bestBidSizeLong.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(bestBidSizeLong.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    LET bestOfferParticipantId == ReadBytes(finraBestBidMarketMakerId.rest, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferQuoteCondition == ReadBytes(bestOfferParticipantId.rest, 1) IN IF ~bestOfferQuoteCondition.ok THEN Fail ELSE
    LET bestOfferPriceLong == ReadBytes(bestOfferQuoteCondition.rest, 8) IN IF ~bestOfferPriceLong.ok THEN Fail ELSE
    LET bestOfferSizeLong == ReadBytes(bestOfferPriceLong.rest, 4) IN IF ~bestOfferSizeLong.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(bestOfferSizeLong.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    Ok([ bestBidParticipantId        |-> bestBidParticipantId.value,
         bestBidQuoteCondition       |-> bestBidQuoteCondition.value,
         bestBidPriceLong            |-> bestBidPriceLong.value,
         bestBidSizeLong             |-> bestBidSizeLong.value,
         finraBestBidMarketMakerId   |-> finraBestBidMarketMakerId.value,
         bestOfferParticipantId      |-> bestOfferParticipantId.value,
         bestOfferQuoteCondition     |-> bestOfferQuoteCondition.value,
         bestOfferPriceLong          |-> bestOfferPriceLong.value,
         bestOfferSizeLong           |-> bestOfferSizeLong.value,
         finraBestOfferMarketMakerId |-> finraBestOfferMarketMakerId.value ], finraBestOfferMarketMakerId.rest)

ZeroNationalBestBidAndOfferLongAppendage2 ==
    [ bestBidParticipantId        |-> [i \in 1 .. 1 |-> 0],
      bestBidQuoteCondition       |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceLong            |-> [i \in 1 .. 8 |-> 0],
      bestBidSizeLong             |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId   |-> [i \in 1 .. 4 |-> 0],
      bestOfferParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestOfferQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestOfferSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Bid And Offer Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidAndOfferLongAppendage2 ==
    { ZeroNationalBestBidAndOfferLongAppendage2 }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.bestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.bestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.bestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.bestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.bestOfferPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.bestOfferSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage2 EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Bid Short Appendage: 5 bytes                              *)
(***************************************************************************)

NationalBestBidShortAppendage2 ==
    [ bestBidParticipantId : Sample(1),
      bestBidPriceShort    : Sample(2),
      bestBidSizeShort     : Sample(2) ]

EncodeNationalBestBidShortAppendage2(message) ==
    message.bestBidParticipantId
        \o message.bestBidPriceShort
        \o message.bestBidSizeShort

DecodeNationalBestBidShortAppendage2(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidPriceShort == ReadBytes(bestBidParticipantId.rest, 2) IN IF ~bestBidPriceShort.ok THEN Fail ELSE
    LET bestBidSizeShort == ReadBytes(bestBidPriceShort.rest, 2) IN IF ~bestBidSizeShort.ok THEN Fail ELSE
    Ok([ bestBidParticipantId |-> bestBidParticipantId.value,
         bestBidPriceShort    |-> bestBidPriceShort.value,
         bestBidSizeShort     |-> bestBidSizeShort.value ], bestBidSizeShort.rest)

ZeroNationalBestBidShortAppendage2 ==
    [ bestBidParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestBidSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Bid Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidShortAppendage2 ==
    { ZeroNationalBestBidShortAppendage2 }
        \cup { [ZeroNationalBestBidShortAppendage2 EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidShortAppendage2 EXCEPT !.bestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidShortAppendage2 EXCEPT !.bestBidSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Best Offer Short Appendage: 5 bytes                            *)
(***************************************************************************)

NationalBestOfferShortAppendage2 ==
    [ bestOfferParticipantId : Sample(1),
      bestOfferPriceShort    : Sample(2),
      bestOfferSizeShort     : Sample(2) ]

EncodeNationalBestOfferShortAppendage2(message) ==
    message.bestOfferParticipantId
        \o message.bestOfferPriceShort
        \o message.bestOfferSizeShort

DecodeNationalBestOfferShortAppendage2(bytes) ==
    LET bestOfferParticipantId == ReadBytes(bytes, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferPriceShort == ReadBytes(bestOfferParticipantId.rest, 2) IN IF ~bestOfferPriceShort.ok THEN Fail ELSE
    LET bestOfferSizeShort == ReadBytes(bestOfferPriceShort.rest, 2) IN IF ~bestOfferSizeShort.ok THEN Fail ELSE
    Ok([ bestOfferParticipantId |-> bestOfferParticipantId.value,
         bestOfferPriceShort    |-> bestOfferPriceShort.value,
         bestOfferSizeShort     |-> bestOfferSizeShort.value ], bestOfferSizeShort.rest)

ZeroNationalBestOfferShortAppendage2 ==
    [ bestOfferParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestOfferSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Offer Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestOfferShortAppendage2 ==
    { ZeroNationalBestOfferShortAppendage2 }
        \cup { [ZeroNationalBestOfferShortAppendage2 EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferShortAppendage2 EXCEPT !.bestOfferPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestOfferShortAppendage2 EXCEPT !.bestOfferSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Best Bid And Offer Short Appendage: 10 bytes                   *)
(***************************************************************************)

NationalBestBidAndOfferShortAppendage2 ==
    [ bestBidParticipantId   : Sample(1),
      bestBidPriceShort      : Sample(2),
      bestBidSizeShort       : Sample(2),
      bestOfferParticipantId : Sample(1),
      bestOfferPriceShort    : Sample(2),
      bestOfferSizeShort     : Sample(2) ]

EncodeNationalBestBidAndOfferShortAppendage2(message) ==
    message.bestBidParticipantId
        \o message.bestBidPriceShort
        \o message.bestBidSizeShort
        \o message.bestOfferParticipantId
        \o message.bestOfferPriceShort
        \o message.bestOfferSizeShort

DecodeNationalBestBidAndOfferShortAppendage2(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidPriceShort == ReadBytes(bestBidParticipantId.rest, 2) IN IF ~bestBidPriceShort.ok THEN Fail ELSE
    LET bestBidSizeShort == ReadBytes(bestBidPriceShort.rest, 2) IN IF ~bestBidSizeShort.ok THEN Fail ELSE
    LET bestOfferParticipantId == ReadBytes(bestBidSizeShort.rest, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferPriceShort == ReadBytes(bestOfferParticipantId.rest, 2) IN IF ~bestOfferPriceShort.ok THEN Fail ELSE
    LET bestOfferSizeShort == ReadBytes(bestOfferPriceShort.rest, 2) IN IF ~bestOfferSizeShort.ok THEN Fail ELSE
    Ok([ bestBidParticipantId   |-> bestBidParticipantId.value,
         bestBidPriceShort      |-> bestBidPriceShort.value,
         bestBidSizeShort       |-> bestBidSizeShort.value,
         bestOfferParticipantId |-> bestOfferParticipantId.value,
         bestOfferPriceShort    |-> bestOfferPriceShort.value,
         bestOfferSizeShort     |-> bestOfferSizeShort.value ], bestOfferSizeShort.rest)

ZeroNationalBestBidAndOfferShortAppendage2 ==
    [ bestBidParticipantId   |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceShort      |-> [i \in 1 .. 2 |-> 0],
      bestBidSizeShort       |-> [i \in 1 .. 2 |-> 0],
      bestOfferParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestOfferSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Bid And Offer Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidAndOfferShortAppendage2 ==
    { ZeroNationalBestBidAndOfferShortAppendage2 }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage2 EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage2 EXCEPT !.bestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage2 EXCEPT !.bestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage2 EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage2 EXCEPT !.bestOfferPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage2 EXCEPT !.bestOfferSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* What National Bbo Indicator decides is present                          *)
(***************************************************************************)

NationalBestBidLongAppendageCode2 == 81  \* "Q"
NationalBestOfferLongAppendageCode2 == 73  \* "I"
NationalBestBidAndOfferLongAppendageCode2 == 85  \* "U"
NationalBestBidShortAppendageCode2 == 80  \* "P"
NationalBestOfferShortAppendageCode2 == 72  \* "H"
NationalBestBidAndOfferShortAppendageCode2 == 84  \* "T"
NationalBboIndicatorNoneCode2 == 0  \* 

NationalBboIndicatorChoice2 ==
    [ tag : {NationalBestBidLongAppendageCode2}, body : NationalBestBidLongAppendage2 ]
        \cup [ tag : {NationalBestOfferLongAppendageCode2}, body : NationalBestOfferLongAppendage2 ]
        \cup [ tag : {NationalBestBidAndOfferLongAppendageCode2}, body : NationalBestBidAndOfferLongAppendage2 ]
        \cup [ tag : {NationalBestBidShortAppendageCode2}, body : NationalBestBidShortAppendage2 ]
        \cup [ tag : {NationalBestOfferShortAppendageCode2}, body : NationalBestOfferShortAppendage2 ]
        \cup [ tag : {NationalBestBidAndOfferShortAppendageCode2}, body : NationalBestBidAndOfferShortAppendage2 ]
        \cup [ tag : {NationalBboIndicatorNoneCode2}, body : {[empty |-> 0]} ]

EncodeNationalBboIndicatorChoice2(message) ==
    CASE message.tag = NationalBestBidLongAppendageCode2 -> EncodeNationalBestBidLongAppendage2(message.body)
      [] message.tag = NationalBestOfferLongAppendageCode2 -> EncodeNationalBestOfferLongAppendage2(message.body)
      [] message.tag = NationalBestBidAndOfferLongAppendageCode2 -> EncodeNationalBestBidAndOfferLongAppendage2(message.body)
      [] message.tag = NationalBestBidShortAppendageCode2 -> EncodeNationalBestBidShortAppendage2(message.body)
      [] message.tag = NationalBestOfferShortAppendageCode2 -> EncodeNationalBestOfferShortAppendage2(message.body)
      [] message.tag = NationalBestBidAndOfferShortAppendageCode2 -> EncodeNationalBestBidAndOfferShortAppendage2(message.body)
      [] OTHER -> << >>

DecodeNationalBboIndicatorChoice2(tag, bytes) ==
    LET read ==
            CASE tag = NationalBestBidLongAppendageCode2 -> DecodeNationalBestBidLongAppendage2(bytes)
              [] tag = NationalBestOfferLongAppendageCode2 -> DecodeNationalBestOfferLongAppendage2(bytes)
              [] tag = NationalBestBidAndOfferLongAppendageCode2 -> DecodeNationalBestBidAndOfferLongAppendage2(bytes)
              [] tag = NationalBestBidShortAppendageCode2 -> DecodeNationalBestBidShortAppendage2(bytes)
              [] tag = NationalBestOfferShortAppendageCode2 -> DecodeNationalBestOfferShortAppendage2(bytes)
              [] tag = NationalBestBidAndOfferShortAppendageCode2 -> DecodeNationalBestBidAndOfferShortAppendage2(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNationalBboIndicatorChoice2 == [tag |-> NationalBestBidLongAppendageCode2, body |-> ZeroNationalBestBidLongAppendage2]

(* Each National Bbo Indicator in turn, at the values the message it names is checked at *)
CheckedNationalBboIndicatorChoice2 ==
    { [tag |-> NationalBestBidLongAppendageCode2, body |-> one] : one \in CheckedNationalBestBidLongAppendage2 }
        \cup { [tag |-> NationalBestOfferLongAppendageCode2, body |-> one] : one \in CheckedNationalBestOfferLongAppendage2 }
        \cup { [tag |-> NationalBestBidAndOfferLongAppendageCode2, body |-> one] : one \in CheckedNationalBestBidAndOfferLongAppendage2 }
        \cup { [tag |-> NationalBestBidShortAppendageCode2, body |-> one] : one \in CheckedNationalBestBidShortAppendage2 }
        \cup { [tag |-> NationalBestOfferShortAppendageCode2, body |-> one] : one \in CheckedNationalBestOfferShortAppendage2 }
        \cup { [tag |-> NationalBestBidAndOfferShortAppendageCode2, body |-> one] : one \in CheckedNationalBestBidAndOfferShortAppendage2 }
        \cup { [tag |-> NationalBboIndicatorNoneCode2, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Short Quote Message                                                     *)
(***************************************************************************)

ShortQuoteMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp113,
      messageId                         : Sample(1),
      transactionId                     : Sample(4),
      participantReferenceNumber        : Sample(8),
      securitySymbol                    : Sample(11),
      bidPriceShort                     : Sample(2),
      bidSizeShort                      : Sample(2),
      offerPriceShort                   : Sample(2),
      offerSizeShort                    : Sample(2),
      primaryListingMarketParticipantId : Sample(1),
      nationalBboIndicatorChoice        : NationalBboIndicatorChoice2 ]

EncodeShortQuoteMessage(message) ==
    message.participantId
        \o EncodeTimestamp113(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.offerPriceShort
        \o message.offerSizeShort
        \o message.primaryListingMarketParticipantId
        \o EncodeUIntBE(message.nationalBboIndicatorChoice.tag, 1)
        \o EncodeNationalBboIndicatorChoice2(message.nationalBboIndicatorChoice)

DecodeShortQuoteMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp113(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(securitySymbol.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET offerPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~offerPriceShort.ok THEN Fail ELSE
    LET offerSizeShort == ReadBytes(offerPriceShort.rest, 2) IN IF ~offerSizeShort.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(offerSizeShort.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET nationalBboIndicator == ReadUIntBE(primaryListingMarketParticipantId.rest, 1) IN IF ~nationalBboIndicator.ok THEN Fail ELSE
    LET nationalBboIndicatorChoice == DecodeNationalBboIndicatorChoice2(nationalBboIndicator.value, nationalBboIndicator.rest) IN IF ~nationalBboIndicatorChoice.ok THEN Fail ELSE
    Ok([ participantId                     |-> participantId.value,
         timestamp1                        |-> timestamp1.value,
         messageId                         |-> messageId.value,
         transactionId                     |-> transactionId.value,
         participantReferenceNumber        |-> participantReferenceNumber.value,
         securitySymbol                    |-> securitySymbol.value,
         bidPriceShort                     |-> bidPriceShort.value,
         bidSizeShort                      |-> bidSizeShort.value,
         offerPriceShort                   |-> offerPriceShort.value,
         offerSizeShort                    |-> offerSizeShort.value,
         primaryListingMarketParticipantId |-> primaryListingMarketParticipantId.value,
         nationalBboIndicatorChoice        |-> nationalBboIndicatorChoice.value ], nationalBboIndicatorChoice.rest)

ZeroShortQuoteMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      timestamp1                        |-> ZeroTimestamp113,
      messageId                         |-> [i \in 1 .. 1 |-> 0],
      transactionId                     |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      bidPriceShort                     |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort                      |-> [i \in 1 .. 2 |-> 0],
      offerPriceShort                   |-> [i \in 1 .. 2 |-> 0],
      offerSizeShort                    |-> [i \in 1 .. 2 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      nationalBboIndicatorChoice        |-> ZeroNationalBboIndicatorChoice2 ]

(* Short Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedShortQuoteMessage ==
    { ZeroShortQuoteMessage }
        \cup { [ZeroShortQuoteMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp113 }
        \cup { [ZeroShortQuoteMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.offerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroShortQuoteMessage EXCEPT !.nationalBboIndicatorChoice = one] : one \in CheckedNationalBboIndicatorChoice2 }

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
(* National Best Bid Long Appendage: 18 bytes                              *)
(***************************************************************************)

NationalBestBidLongAppendage3 ==
    [ bestBidParticipantId      : Sample(1),
      bestBidQuoteCondition     : Sample(1),
      bestBidPriceLong          : Sample(8),
      bestBidSizeLong           : Sample(4),
      finraBestBidMarketMakerId : Sample(4) ]

EncodeNationalBestBidLongAppendage3(message) ==
    message.bestBidParticipantId
        \o message.bestBidQuoteCondition
        \o message.bestBidPriceLong
        \o message.bestBidSizeLong
        \o message.finraBestBidMarketMakerId

DecodeNationalBestBidLongAppendage3(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidQuoteCondition == ReadBytes(bestBidParticipantId.rest, 1) IN IF ~bestBidQuoteCondition.ok THEN Fail ELSE
    LET bestBidPriceLong == ReadBytes(bestBidQuoteCondition.rest, 8) IN IF ~bestBidPriceLong.ok THEN Fail ELSE
    LET bestBidSizeLong == ReadBytes(bestBidPriceLong.rest, 4) IN IF ~bestBidSizeLong.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(bestBidSizeLong.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    Ok([ bestBidParticipantId      |-> bestBidParticipantId.value,
         bestBidQuoteCondition     |-> bestBidQuoteCondition.value,
         bestBidPriceLong          |-> bestBidPriceLong.value,
         bestBidSizeLong           |-> bestBidSizeLong.value,
         finraBestBidMarketMakerId |-> finraBestBidMarketMakerId.value ], finraBestBidMarketMakerId.rest)

ZeroNationalBestBidLongAppendage3 ==
    [ bestBidParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestBidQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestBidSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Bid Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidLongAppendage3 ==
    { ZeroNationalBestBidLongAppendage3 }
        \cup { [ZeroNationalBestBidLongAppendage3 EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidLongAppendage3 EXCEPT !.bestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidLongAppendage3 EXCEPT !.bestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidLongAppendage3 EXCEPT !.bestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidLongAppendage3 EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Offer Long Appendage: 18 bytes                            *)
(***************************************************************************)

NationalBestOfferLongAppendage3 ==
    [ bestOfferParticipantId      : Sample(1),
      bestOfferQuoteCondition     : Sample(1),
      bestOfferPriceLong          : Sample(8),
      bestOfferSizeLong           : Sample(4),
      finraBestOfferMarketMakerId : Sample(4) ]

EncodeNationalBestOfferLongAppendage3(message) ==
    message.bestOfferParticipantId
        \o message.bestOfferQuoteCondition
        \o message.bestOfferPriceLong
        \o message.bestOfferSizeLong
        \o message.finraBestOfferMarketMakerId

DecodeNationalBestOfferLongAppendage3(bytes) ==
    LET bestOfferParticipantId == ReadBytes(bytes, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferQuoteCondition == ReadBytes(bestOfferParticipantId.rest, 1) IN IF ~bestOfferQuoteCondition.ok THEN Fail ELSE
    LET bestOfferPriceLong == ReadBytes(bestOfferQuoteCondition.rest, 8) IN IF ~bestOfferPriceLong.ok THEN Fail ELSE
    LET bestOfferSizeLong == ReadBytes(bestOfferPriceLong.rest, 4) IN IF ~bestOfferSizeLong.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(bestOfferSizeLong.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    Ok([ bestOfferParticipantId      |-> bestOfferParticipantId.value,
         bestOfferQuoteCondition     |-> bestOfferQuoteCondition.value,
         bestOfferPriceLong          |-> bestOfferPriceLong.value,
         bestOfferSizeLong           |-> bestOfferSizeLong.value,
         finraBestOfferMarketMakerId |-> finraBestOfferMarketMakerId.value ], finraBestOfferMarketMakerId.rest)

ZeroNationalBestOfferLongAppendage3 ==
    [ bestOfferParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestOfferQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestOfferSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Offer Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestOfferLongAppendage3 ==
    { ZeroNationalBestOfferLongAppendage3 }
        \cup { [ZeroNationalBestOfferLongAppendage3 EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferLongAppendage3 EXCEPT !.bestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferLongAppendage3 EXCEPT !.bestOfferPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestOfferLongAppendage3 EXCEPT !.bestOfferSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestOfferLongAppendage3 EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Bid And Offer Long Appendage: 36 bytes                    *)
(***************************************************************************)

NationalBestBidAndOfferLongAppendage3 ==
    [ bestBidParticipantId        : Sample(1),
      bestBidQuoteCondition       : Sample(1),
      bestBidPriceLong            : Sample(8),
      bestBidSizeLong             : Sample(4),
      finraBestBidMarketMakerId   : Sample(4),
      bestOfferParticipantId      : Sample(1),
      bestOfferQuoteCondition     : Sample(1),
      bestOfferPriceLong          : Sample(8),
      bestOfferSizeLong           : Sample(4),
      finraBestOfferMarketMakerId : Sample(4) ]

EncodeNationalBestBidAndOfferLongAppendage3(message) ==
    message.bestBidParticipantId
        \o message.bestBidQuoteCondition
        \o message.bestBidPriceLong
        \o message.bestBidSizeLong
        \o message.finraBestBidMarketMakerId
        \o message.bestOfferParticipantId
        \o message.bestOfferQuoteCondition
        \o message.bestOfferPriceLong
        \o message.bestOfferSizeLong
        \o message.finraBestOfferMarketMakerId

DecodeNationalBestBidAndOfferLongAppendage3(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidQuoteCondition == ReadBytes(bestBidParticipantId.rest, 1) IN IF ~bestBidQuoteCondition.ok THEN Fail ELSE
    LET bestBidPriceLong == ReadBytes(bestBidQuoteCondition.rest, 8) IN IF ~bestBidPriceLong.ok THEN Fail ELSE
    LET bestBidSizeLong == ReadBytes(bestBidPriceLong.rest, 4) IN IF ~bestBidSizeLong.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(bestBidSizeLong.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    LET bestOfferParticipantId == ReadBytes(finraBestBidMarketMakerId.rest, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferQuoteCondition == ReadBytes(bestOfferParticipantId.rest, 1) IN IF ~bestOfferQuoteCondition.ok THEN Fail ELSE
    LET bestOfferPriceLong == ReadBytes(bestOfferQuoteCondition.rest, 8) IN IF ~bestOfferPriceLong.ok THEN Fail ELSE
    LET bestOfferSizeLong == ReadBytes(bestOfferPriceLong.rest, 4) IN IF ~bestOfferSizeLong.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(bestOfferSizeLong.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    Ok([ bestBidParticipantId        |-> bestBidParticipantId.value,
         bestBidQuoteCondition       |-> bestBidQuoteCondition.value,
         bestBidPriceLong            |-> bestBidPriceLong.value,
         bestBidSizeLong             |-> bestBidSizeLong.value,
         finraBestBidMarketMakerId   |-> finraBestBidMarketMakerId.value,
         bestOfferParticipantId      |-> bestOfferParticipantId.value,
         bestOfferQuoteCondition     |-> bestOfferQuoteCondition.value,
         bestOfferPriceLong          |-> bestOfferPriceLong.value,
         bestOfferSizeLong           |-> bestOfferSizeLong.value,
         finraBestOfferMarketMakerId |-> finraBestOfferMarketMakerId.value ], finraBestOfferMarketMakerId.rest)

ZeroNationalBestBidAndOfferLongAppendage3 ==
    [ bestBidParticipantId        |-> [i \in 1 .. 1 |-> 0],
      bestBidQuoteCondition       |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceLong            |-> [i \in 1 .. 8 |-> 0],
      bestBidSizeLong             |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId   |-> [i \in 1 .. 4 |-> 0],
      bestOfferParticipantId      |-> [i \in 1 .. 1 |-> 0],
      bestOfferQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceLong          |-> [i \in 1 .. 8 |-> 0],
      bestOfferSizeLong           |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId |-> [i \in 1 .. 4 |-> 0] ]

(* National Best Bid And Offer Long Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidAndOfferLongAppendage3 ==
    { ZeroNationalBestBidAndOfferLongAppendage3 }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.bestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.bestBidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.bestBidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.bestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.bestOfferPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.bestOfferSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroNationalBestBidAndOfferLongAppendage3 EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }

(***************************************************************************)
(* National Best Bid Short Appendage: 5 bytes                              *)
(***************************************************************************)

NationalBestBidShortAppendage3 ==
    [ bestBidParticipantId : Sample(1),
      bestBidPriceShort    : Sample(2),
      bestBidSizeShort     : Sample(2) ]

EncodeNationalBestBidShortAppendage3(message) ==
    message.bestBidParticipantId
        \o message.bestBidPriceShort
        \o message.bestBidSizeShort

DecodeNationalBestBidShortAppendage3(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidPriceShort == ReadBytes(bestBidParticipantId.rest, 2) IN IF ~bestBidPriceShort.ok THEN Fail ELSE
    LET bestBidSizeShort == ReadBytes(bestBidPriceShort.rest, 2) IN IF ~bestBidSizeShort.ok THEN Fail ELSE
    Ok([ bestBidParticipantId |-> bestBidParticipantId.value,
         bestBidPriceShort    |-> bestBidPriceShort.value,
         bestBidSizeShort     |-> bestBidSizeShort.value ], bestBidSizeShort.rest)

ZeroNationalBestBidShortAppendage3 ==
    [ bestBidParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestBidSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Bid Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidShortAppendage3 ==
    { ZeroNationalBestBidShortAppendage3 }
        \cup { [ZeroNationalBestBidShortAppendage3 EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidShortAppendage3 EXCEPT !.bestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidShortAppendage3 EXCEPT !.bestBidSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Best Offer Short Appendage: 5 bytes                            *)
(***************************************************************************)

NationalBestOfferShortAppendage3 ==
    [ bestOfferParticipantId : Sample(1),
      bestOfferPriceShort    : Sample(2),
      bestOfferSizeShort     : Sample(2) ]

EncodeNationalBestOfferShortAppendage3(message) ==
    message.bestOfferParticipantId
        \o message.bestOfferPriceShort
        \o message.bestOfferSizeShort

DecodeNationalBestOfferShortAppendage3(bytes) ==
    LET bestOfferParticipantId == ReadBytes(bytes, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferPriceShort == ReadBytes(bestOfferParticipantId.rest, 2) IN IF ~bestOfferPriceShort.ok THEN Fail ELSE
    LET bestOfferSizeShort == ReadBytes(bestOfferPriceShort.rest, 2) IN IF ~bestOfferSizeShort.ok THEN Fail ELSE
    Ok([ bestOfferParticipantId |-> bestOfferParticipantId.value,
         bestOfferPriceShort    |-> bestOfferPriceShort.value,
         bestOfferSizeShort     |-> bestOfferSizeShort.value ], bestOfferSizeShort.rest)

ZeroNationalBestOfferShortAppendage3 ==
    [ bestOfferParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestOfferSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Offer Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestOfferShortAppendage3 ==
    { ZeroNationalBestOfferShortAppendage3 }
        \cup { [ZeroNationalBestOfferShortAppendage3 EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestOfferShortAppendage3 EXCEPT !.bestOfferPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestOfferShortAppendage3 EXCEPT !.bestOfferSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* National Best Bid And Offer Short Appendage: 10 bytes                   *)
(***************************************************************************)

NationalBestBidAndOfferShortAppendage3 ==
    [ bestBidParticipantId   : Sample(1),
      bestBidPriceShort      : Sample(2),
      bestBidSizeShort       : Sample(2),
      bestOfferParticipantId : Sample(1),
      bestOfferPriceShort    : Sample(2),
      bestOfferSizeShort     : Sample(2) ]

EncodeNationalBestBidAndOfferShortAppendage3(message) ==
    message.bestBidParticipantId
        \o message.bestBidPriceShort
        \o message.bestBidSizeShort
        \o message.bestOfferParticipantId
        \o message.bestOfferPriceShort
        \o message.bestOfferSizeShort

DecodeNationalBestBidAndOfferShortAppendage3(bytes) ==
    LET bestBidParticipantId == ReadBytes(bytes, 1) IN IF ~bestBidParticipantId.ok THEN Fail ELSE
    LET bestBidPriceShort == ReadBytes(bestBidParticipantId.rest, 2) IN IF ~bestBidPriceShort.ok THEN Fail ELSE
    LET bestBidSizeShort == ReadBytes(bestBidPriceShort.rest, 2) IN IF ~bestBidSizeShort.ok THEN Fail ELSE
    LET bestOfferParticipantId == ReadBytes(bestBidSizeShort.rest, 1) IN IF ~bestOfferParticipantId.ok THEN Fail ELSE
    LET bestOfferPriceShort == ReadBytes(bestOfferParticipantId.rest, 2) IN IF ~bestOfferPriceShort.ok THEN Fail ELSE
    LET bestOfferSizeShort == ReadBytes(bestOfferPriceShort.rest, 2) IN IF ~bestOfferSizeShort.ok THEN Fail ELSE
    Ok([ bestBidParticipantId   |-> bestBidParticipantId.value,
         bestBidPriceShort      |-> bestBidPriceShort.value,
         bestBidSizeShort       |-> bestBidSizeShort.value,
         bestOfferParticipantId |-> bestOfferParticipantId.value,
         bestOfferPriceShort    |-> bestOfferPriceShort.value,
         bestOfferSizeShort     |-> bestOfferSizeShort.value ], bestOfferSizeShort.rest)

ZeroNationalBestBidAndOfferShortAppendage3 ==
    [ bestBidParticipantId   |-> [i \in 1 .. 1 |-> 0],
      bestBidPriceShort      |-> [i \in 1 .. 2 |-> 0],
      bestBidSizeShort       |-> [i \in 1 .. 2 |-> 0],
      bestOfferParticipantId |-> [i \in 1 .. 1 |-> 0],
      bestOfferPriceShort    |-> [i \in 1 .. 2 |-> 0],
      bestOfferSizeShort     |-> [i \in 1 .. 2 |-> 0] ]

(* National Best Bid And Offer Short Appendage at zero, then each field in turn at the values it is checked at *)
CheckedNationalBestBidAndOfferShortAppendage3 ==
    { ZeroNationalBestBidAndOfferShortAppendage3 }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage3 EXCEPT !.bestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage3 EXCEPT !.bestBidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage3 EXCEPT !.bestBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage3 EXCEPT !.bestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage3 EXCEPT !.bestOfferPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroNationalBestBidAndOfferShortAppendage3 EXCEPT !.bestOfferSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* What National Bbo Indicator decides is present                          *)
(***************************************************************************)

NationalBestBidLongAppendageCode3 == 81  \* "Q"
NationalBestOfferLongAppendageCode3 == 73  \* "I"
NationalBestBidAndOfferLongAppendageCode3 == 85  \* "U"
NationalBestBidShortAppendageCode3 == 80  \* "P"
NationalBestOfferShortAppendageCode3 == 72  \* "H"
NationalBestBidAndOfferShortAppendageCode3 == 84  \* "T"
NationalBboIndicatorNoneCode3 == 0  \* 

NationalBboIndicatorChoice3 ==
    [ tag : {NationalBestBidLongAppendageCode3}, body : NationalBestBidLongAppendage3 ]
        \cup [ tag : {NationalBestOfferLongAppendageCode3}, body : NationalBestOfferLongAppendage3 ]
        \cup [ tag : {NationalBestBidAndOfferLongAppendageCode3}, body : NationalBestBidAndOfferLongAppendage3 ]
        \cup [ tag : {NationalBestBidShortAppendageCode3}, body : NationalBestBidShortAppendage3 ]
        \cup [ tag : {NationalBestOfferShortAppendageCode3}, body : NationalBestOfferShortAppendage3 ]
        \cup [ tag : {NationalBestBidAndOfferShortAppendageCode3}, body : NationalBestBidAndOfferShortAppendage3 ]
        \cup [ tag : {NationalBboIndicatorNoneCode3}, body : {[empty |-> 0]} ]

EncodeNationalBboIndicatorChoice3(message) ==
    CASE message.tag = NationalBestBidLongAppendageCode3 -> EncodeNationalBestBidLongAppendage3(message.body)
      [] message.tag = NationalBestOfferLongAppendageCode3 -> EncodeNationalBestOfferLongAppendage3(message.body)
      [] message.tag = NationalBestBidAndOfferLongAppendageCode3 -> EncodeNationalBestBidAndOfferLongAppendage3(message.body)
      [] message.tag = NationalBestBidShortAppendageCode3 -> EncodeNationalBestBidShortAppendage3(message.body)
      [] message.tag = NationalBestOfferShortAppendageCode3 -> EncodeNationalBestOfferShortAppendage3(message.body)
      [] message.tag = NationalBestBidAndOfferShortAppendageCode3 -> EncodeNationalBestBidAndOfferShortAppendage3(message.body)
      [] OTHER -> << >>

DecodeNationalBboIndicatorChoice3(tag, bytes) ==
    LET read ==
            CASE tag = NationalBestBidLongAppendageCode3 -> DecodeNationalBestBidLongAppendage3(bytes)
              [] tag = NationalBestOfferLongAppendageCode3 -> DecodeNationalBestOfferLongAppendage3(bytes)
              [] tag = NationalBestBidAndOfferLongAppendageCode3 -> DecodeNationalBestBidAndOfferLongAppendage3(bytes)
              [] tag = NationalBestBidShortAppendageCode3 -> DecodeNationalBestBidShortAppendage3(bytes)
              [] tag = NationalBestOfferShortAppendageCode3 -> DecodeNationalBestOfferShortAppendage3(bytes)
              [] tag = NationalBestBidAndOfferShortAppendageCode3 -> DecodeNationalBestBidAndOfferShortAppendage3(bytes)
              [] OTHER -> Ok([empty |-> 0], bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroNationalBboIndicatorChoice3 == [tag |-> NationalBestBidLongAppendageCode3, body |-> ZeroNationalBestBidLongAppendage3]

(* Each National Bbo Indicator in turn, at the values the message it names is checked at *)
CheckedNationalBboIndicatorChoice3 ==
    { [tag |-> NationalBestBidLongAppendageCode3, body |-> one] : one \in CheckedNationalBestBidLongAppendage3 }
        \cup { [tag |-> NationalBestOfferLongAppendageCode3, body |-> one] : one \in CheckedNationalBestOfferLongAppendage3 }
        \cup { [tag |-> NationalBestBidAndOfferLongAppendageCode3, body |-> one] : one \in CheckedNationalBestBidAndOfferLongAppendage3 }
        \cup { [tag |-> NationalBestBidShortAppendageCode3, body |-> one] : one \in CheckedNationalBestBidShortAppendage3 }
        \cup { [tag |-> NationalBestOfferShortAppendageCode3, body |-> one] : one \in CheckedNationalBestOfferShortAppendage3 }
        \cup { [tag |-> NationalBestBidAndOfferShortAppendageCode3, body |-> one] : one \in CheckedNationalBestBidAndOfferShortAppendage3 }
        \cup { [tag |-> NationalBboIndicatorNoneCode3, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Special Long Quote Message                                              *)
(***************************************************************************)

SpecialLongQuoteMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp114,
      messageId                         : Sample(1),
      transactionId                     : Sample(4),
      participantReferenceNumber        : Sample(8),
      securitySymbol                    : Sample(11),
      instrumentType                    : Sample(1),
      quoteCondition                    : Sample(1),
      securityStatusIndicator           : Sample(1),
      bidPriceLong                      : Sample(8),
      bidSizeLong                       : Sample(4),
      offerPriceLong                    : Sample(8),
      offerSizeLong                     : Sample(4),
      retailInterestIndicator           : Sample(1),
      settlementCondition               : Sample(1),
      marketCondition                   : Sample(1),
      finraMarketMakerId                : Sample(4),
      finraBestBidQuoteCondition        : Sample(1),
      finraBestBidPrice                 : Sample(8),
      finraBestBidSize                  : Sample(4),
      finraBestBidMarketMakerId         : Sample(4),
      finraBestOfferQuoteCondition      : Sample(1),
      finraBestOfferPrice               : Sample(8),
      finraBestOfferSize                : Sample(4),
      finraBestOfferMarketMakerId       : Sample(4),
      timestamp2                        : Timestamp22,
      shortSaleRestrictionIndicator     : Sample(1),
      primaryListingMarketParticipantId : Sample(1),
      financialStatusIndicator          : Sample(1),
      sipGeneratedMessageIdentifier     : Sample(1),
      finraBboLuldIndicator             : Sample(1),
      nationalBboLuldIndicator          : Sample(1),
      nationalBboIndicatorChoice        : NationalBboIndicatorChoice3 ]

EncodeSpecialLongQuoteMessage(message) ==
    message.participantId
        \o EncodeTimestamp114(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.quoteCondition
        \o message.securityStatusIndicator
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.offerPriceLong
        \o message.offerSizeLong
        \o message.retailInterestIndicator
        \o message.settlementCondition
        \o message.marketCondition
        \o message.finraMarketMakerId
        \o message.finraBestBidQuoteCondition
        \o message.finraBestBidPrice
        \o message.finraBestBidSize
        \o message.finraBestBidMarketMakerId
        \o message.finraBestOfferQuoteCondition
        \o message.finraBestOfferPrice
        \o message.finraBestOfferSize
        \o message.finraBestOfferMarketMakerId
        \o EncodeTimestamp22(message.timestamp2)
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.sipGeneratedMessageIdentifier
        \o message.finraBboLuldIndicator
        \o message.nationalBboLuldIndicator
        \o EncodeUIntBE(message.nationalBboIndicatorChoice.tag, 1)
        \o EncodeNationalBboIndicatorChoice3(message.nationalBboIndicatorChoice)

DecodeSpecialLongQuoteMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp114(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(instrumentType.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET securityStatusIndicator == ReadBytes(quoteCondition.rest, 1) IN IF ~securityStatusIndicator.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(securityStatusIndicator.rest, 8) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET offerPriceLong == ReadBytes(bidSizeLong.rest, 8) IN IF ~offerPriceLong.ok THEN Fail ELSE
    LET offerSizeLong == ReadBytes(offerPriceLong.rest, 4) IN IF ~offerSizeLong.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(offerSizeLong.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET settlementCondition == ReadBytes(retailInterestIndicator.rest, 1) IN IF ~settlementCondition.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(settlementCondition.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET finraMarketMakerId == ReadBytes(marketCondition.rest, 4) IN IF ~finraMarketMakerId.ok THEN Fail ELSE
    LET finraBestBidQuoteCondition == ReadBytes(finraMarketMakerId.rest, 1) IN IF ~finraBestBidQuoteCondition.ok THEN Fail ELSE
    LET finraBestBidPrice == ReadBytes(finraBestBidQuoteCondition.rest, 8) IN IF ~finraBestBidPrice.ok THEN Fail ELSE
    LET finraBestBidSize == ReadBytes(finraBestBidPrice.rest, 4) IN IF ~finraBestBidSize.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(finraBestBidSize.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    LET finraBestOfferQuoteCondition == ReadBytes(finraBestBidMarketMakerId.rest, 1) IN IF ~finraBestOfferQuoteCondition.ok THEN Fail ELSE
    LET finraBestOfferPrice == ReadBytes(finraBestOfferQuoteCondition.rest, 8) IN IF ~finraBestOfferPrice.ok THEN Fail ELSE
    LET finraBestOfferSize == ReadBytes(finraBestOfferPrice.rest, 4) IN IF ~finraBestOfferSize.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(finraBestOfferSize.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp22(finraBestOfferMarketMakerId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(timestamp2.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET sipGeneratedMessageIdentifier == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~sipGeneratedMessageIdentifier.ok THEN Fail ELSE
    LET finraBboLuldIndicator == ReadBytes(sipGeneratedMessageIdentifier.rest, 1) IN IF ~finraBboLuldIndicator.ok THEN Fail ELSE
    LET nationalBboLuldIndicator == ReadBytes(finraBboLuldIndicator.rest, 1) IN IF ~nationalBboLuldIndicator.ok THEN Fail ELSE
    LET nationalBboIndicator == ReadUIntBE(nationalBboLuldIndicator.rest, 1) IN IF ~nationalBboIndicator.ok THEN Fail ELSE
    LET nationalBboIndicatorChoice == DecodeNationalBboIndicatorChoice3(nationalBboIndicator.value, nationalBboIndicator.rest) IN IF ~nationalBboIndicatorChoice.ok THEN Fail ELSE
    Ok([ participantId                     |-> participantId.value,
         timestamp1                        |-> timestamp1.value,
         messageId                         |-> messageId.value,
         transactionId                     |-> transactionId.value,
         participantReferenceNumber        |-> participantReferenceNumber.value,
         securitySymbol                    |-> securitySymbol.value,
         instrumentType                    |-> instrumentType.value,
         quoteCondition                    |-> quoteCondition.value,
         securityStatusIndicator           |-> securityStatusIndicator.value,
         bidPriceLong                      |-> bidPriceLong.value,
         bidSizeLong                       |-> bidSizeLong.value,
         offerPriceLong                    |-> offerPriceLong.value,
         offerSizeLong                     |-> offerSizeLong.value,
         retailInterestIndicator           |-> retailInterestIndicator.value,
         settlementCondition               |-> settlementCondition.value,
         marketCondition                   |-> marketCondition.value,
         finraMarketMakerId                |-> finraMarketMakerId.value,
         finraBestBidQuoteCondition        |-> finraBestBidQuoteCondition.value,
         finraBestBidPrice                 |-> finraBestBidPrice.value,
         finraBestBidSize                  |-> finraBestBidSize.value,
         finraBestBidMarketMakerId         |-> finraBestBidMarketMakerId.value,
         finraBestOfferQuoteCondition      |-> finraBestOfferQuoteCondition.value,
         finraBestOfferPrice               |-> finraBestOfferPrice.value,
         finraBestOfferSize                |-> finraBestOfferSize.value,
         finraBestOfferMarketMakerId       |-> finraBestOfferMarketMakerId.value,
         timestamp2                        |-> timestamp2.value,
         shortSaleRestrictionIndicator     |-> shortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator          |-> financialStatusIndicator.value,
         sipGeneratedMessageIdentifier     |-> sipGeneratedMessageIdentifier.value,
         finraBboLuldIndicator             |-> finraBboLuldIndicator.value,
         nationalBboLuldIndicator          |-> nationalBboLuldIndicator.value,
         nationalBboIndicatorChoice        |-> nationalBboIndicatorChoice.value ], nationalBboIndicatorChoice.rest)

ZeroSpecialLongQuoteMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      timestamp1                        |-> ZeroTimestamp114,
      messageId                         |-> [i \in 1 .. 1 |-> 0],
      transactionId                     |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      instrumentType                    |-> [i \in 1 .. 1 |-> 0],
      quoteCondition                    |-> [i \in 1 .. 1 |-> 0],
      securityStatusIndicator           |-> [i \in 1 .. 1 |-> 0],
      bidPriceLong                      |-> [i \in 1 .. 8 |-> 0],
      bidSizeLong                       |-> [i \in 1 .. 4 |-> 0],
      offerPriceLong                    |-> [i \in 1 .. 8 |-> 0],
      offerSizeLong                     |-> [i \in 1 .. 4 |-> 0],
      retailInterestIndicator           |-> [i \in 1 .. 1 |-> 0],
      settlementCondition               |-> [i \in 1 .. 1 |-> 0],
      marketCondition                   |-> [i \in 1 .. 1 |-> 0],
      finraMarketMakerId                |-> [i \in 1 .. 4 |-> 0],
      finraBestBidQuoteCondition        |-> [i \in 1 .. 1 |-> 0],
      finraBestBidPrice                 |-> [i \in 1 .. 8 |-> 0],
      finraBestBidSize                  |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId         |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferQuoteCondition      |-> [i \in 1 .. 1 |-> 0],
      finraBestOfferPrice               |-> [i \in 1 .. 8 |-> 0],
      finraBestOfferSize                |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId       |-> [i \in 1 .. 4 |-> 0],
      timestamp2                        |-> ZeroTimestamp22,
      shortSaleRestrictionIndicator     |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator          |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedMessageIdentifier     |-> [i \in 1 .. 1 |-> 0],
      finraBboLuldIndicator             |-> [i \in 1 .. 1 |-> 0],
      nationalBboLuldIndicator          |-> [i \in 1 .. 1 |-> 0],
      nationalBboIndicatorChoice        |-> ZeroNationalBboIndicatorChoice3 ]

(* Special Long Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedSpecialLongQuoteMessage ==
    { ZeroSpecialLongQuoteMessage }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp114 }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.securityStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.bidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.offerPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.offerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.settlementCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp22 }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.sipGeneratedMessageIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.finraBboLuldIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.nationalBboLuldIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialLongQuoteMessage EXCEPT !.nationalBboIndicatorChoice = one] : one \in CheckedNationalBboIndicatorChoice3 }

(***************************************************************************)
(* Quote Message Payload, selected by Quote Message Type                   *)
(***************************************************************************)

AuctionStatusMessageCode == 65  \* "A"
LongQuoteMessageCode == 76  \* "L"
ShortQuoteMessageCode == 81  \* "Q"
SpecialLongQuoteMessageCode == 83  \* "S"

QuoteMessagePayload ==
    [ tag : {AuctionStatusMessageCode}, body : AuctionStatusMessage ]
        \cup [ tag : {LongQuoteMessageCode}, body : LongQuoteMessage ]
        \cup [ tag : {ShortQuoteMessageCode}, body : ShortQuoteMessage ]
        \cup [ tag : {SpecialLongQuoteMessageCode}, body : SpecialLongQuoteMessage ]

EncodeQuoteMessagePayload(message) ==
    CASE message.tag = AuctionStatusMessageCode -> EncodeAuctionStatusMessage(message.body)
      [] message.tag = LongQuoteMessageCode -> EncodeLongQuoteMessage(message.body)
      [] message.tag = ShortQuoteMessageCode -> EncodeShortQuoteMessage(message.body)
      [] message.tag = SpecialLongQuoteMessageCode -> EncodeSpecialLongQuoteMessage(message.body)

DecodeQuoteMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = AuctionStatusMessageCode -> DecodeAuctionStatusMessage(bytes)
              [] tag = LongQuoteMessageCode -> DecodeLongQuoteMessage(bytes)
              [] tag = ShortQuoteMessageCode -> DecodeShortQuoteMessage(bytes)
              [] tag = SpecialLongQuoteMessageCode -> DecodeSpecialLongQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroQuoteMessagePayload == [tag |-> AuctionStatusMessageCode, body |-> ZeroAuctionStatusMessage]

(* Each Quote Message Payload in turn, at the values the message it names is checked at *)
CheckedQuoteMessagePayload ==
    { [tag |-> AuctionStatusMessageCode, body |-> one] : one \in CheckedAuctionStatusMessage }
        \cup { [tag |-> LongQuoteMessageCode, body |-> one] : one \in CheckedLongQuoteMessage }
        \cup { [tag |-> ShortQuoteMessageCode, body |-> one] : one \in CheckedShortQuoteMessage }
        \cup { [tag |-> SpecialLongQuoteMessageCode, body |-> one] : one \in CheckedSpecialLongQuoteMessage }

(***************************************************************************)
(* Quote Message                                                           *)
(***************************************************************************)

QuoteMessage ==
    [ quoteMessagePayload : QuoteMessagePayload ]

EncodeQuoteMessage(message) ==
    EncodeUIntBE(message.quoteMessagePayload.tag, 1)
        \o EncodeQuoteMessagePayload(message.quoteMessagePayload)

DecodeQuoteMessage(bytes) ==
    LET quoteMessageType == ReadUIntBE(bytes, 1) IN IF ~quoteMessageType.ok THEN Fail ELSE
    LET quoteMessagePayload == DecodeQuoteMessagePayload(quoteMessageType.value, quoteMessageType.rest) IN IF ~quoteMessagePayload.ok THEN Fail ELSE
    Ok([ quoteMessagePayload |-> quoteMessagePayload.value ], quoteMessagePayload.rest)

ZeroQuoteMessage ==
    [ quoteMessagePayload |-> ZeroQuoteMessagePayload ]

(* Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteMessage ==
    { ZeroQuoteMessage }
        \cup { [ZeroQuoteMessage EXCEPT !.quoteMessagePayload = one] : one \in CheckedQuoteMessagePayload }

(***************************************************************************)
(* Category Payload, selected by Message Category                          *)
(***************************************************************************)

AdministrativeMessageCode == 65  \* "A"
ControlMessageCode == 67  \* "C"
MarketStatusMessageCode == 77  \* "M"
QuoteMessageCode == 81  \* "Q"

CategoryPayload ==
    [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]
        \cup [ tag : {MarketStatusMessageCode}, body : MarketStatusMessage ]
        \cup [ tag : {QuoteMessageCode}, body : QuoteMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)
      [] message.tag = MarketStatusMessageCode -> EncodeMarketStatusMessage(message.body)
      [] message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] tag = MarketStatusMessageCode -> DecodeMarketStatusMessage(bytes)
              [] tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCategoryPayload == [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]

(* Each Category Payload in turn, at the values the message it names is checked at *)
CheckedCategoryPayload ==
    { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }
        \cup { [tag |-> MarketStatusMessageCode, body |-> one] : one \in CheckedMarketStatusMessage }
        \cup { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }

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
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> MarketStatusMessageCode, body |-> ZeroMarketStatusMessage]],
      [ZeroMessage EXCEPT !.categoryPayload = [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]] }

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

(* Every SIP Block Timestamp decodes back to what was encoded, and leaves nothing over *)
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

(* Every Symbol Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolReferenceDataMessage ==
    \A message \in CheckedSymbolReferenceDataMessage :
        LET read == DecodeSymbolReferenceDataMessage(EncodeSymbolReferenceDataMessage(message))
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
RoundTripTimestamp12 ==
    \A message \in CheckedTimestamp12 :
        LET read == DecodeTimestamp12(EncodeTimestamp12(message))
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
RoundTripTimestamp13 ==
    \A message \in CheckedTimestamp13 :
        LET read == DecodeTimestamp13(EncodeTimestamp13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Close Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraCloseMessage ==
    \A message \in CheckedFinraCloseMessage :
        LET read == DecodeFinraCloseMessage(EncodeFinraCloseMessage(message))
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

(* Every Reset Block Sequence Number Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetBlockSequenceNumberMessage ==
    \A message \in CheckedResetBlockSequenceNumberMessage :
        LET read == DecodeResetBlockSequenceNumberMessage(EncodeResetBlockSequenceNumberMessage(message))
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

(* Every Finra Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraOpenMessage ==
    \A message \in CheckedFinraOpenMessage :
        LET read == DecodeFinraOpenMessage(EncodeFinraOpenMessage(message))
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

(* Every Disaster Recovery Data Center Activation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDisasterRecoveryDataCenterActivationMessage ==
    \A message \in CheckedDisasterRecoveryDataCenterActivationMessage :
        LET read == DecodeDisasterRecoveryDataCenterActivationMessage(EncodeDisasterRecoveryDataCenterActivationMessage(message))
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

(* Every Line Integrity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLineIntegrityMessage ==
    \A message \in CheckedLineIntegrityMessage :
        LET read == DecodeLineIntegrityMessage(EncodeLineIntegrityMessage(message))
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
RoundTripTimestamp19 ==
    \A message \in CheckedTimestamp19 :
        LET read == DecodeTimestamp19(EncodeTimestamp19(message))
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
RoundTripTimestamp110 ==
    \A message \in CheckedTimestamp110 :
        LET read == DecodeTimestamp110(EncodeTimestamp110(message))
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

(* Every Market Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatusMessage ==
    \A message \in CheckedMarketStatusMessage :
        LET read == DecodeMarketStatusMessage(EncodeMarketStatusMessage(message))
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

(* Every Auction Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionStatusMessage ==
    \A message \in CheckedAuctionStatusMessage :
        LET read == DecodeAuctionStatusMessage(EncodeAuctionStatusMessage(message))
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

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp2 ==
    \A message \in CheckedTimestamp2 :
        LET read == DecodeTimestamp2(EncodeTimestamp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidLongAppendage ==
    \A message \in CheckedNationalBestBidLongAppendage :
        LET read == DecodeNationalBestBidLongAppendage(EncodeNationalBestBidLongAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Offer Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestOfferLongAppendage ==
    \A message \in CheckedNationalBestOfferLongAppendage :
        LET read == DecodeNationalBestOfferLongAppendage(EncodeNationalBestOfferLongAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid And Offer Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidAndOfferLongAppendage ==
    \A message \in CheckedNationalBestBidAndOfferLongAppendage :
        LET read == DecodeNationalBestBidAndOfferLongAppendage(EncodeNationalBestBidAndOfferLongAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidShortAppendage ==
    \A message \in CheckedNationalBestBidShortAppendage :
        LET read == DecodeNationalBestBidShortAppendage(EncodeNationalBestBidShortAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Offer Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestOfferShortAppendage ==
    \A message \in CheckedNationalBestOfferShortAppendage :
        LET read == DecodeNationalBestOfferShortAppendage(EncodeNationalBestOfferShortAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid And Offer Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidAndOfferShortAppendage ==
    \A message \in CheckedNationalBestBidAndOfferShortAppendage :
        LET read == DecodeNationalBestBidAndOfferShortAppendage(EncodeNationalBestBidAndOfferShortAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongQuoteMessage ==
    \A message \in CheckedLongQuoteMessage :
        LET read == DecodeLongQuoteMessage(EncodeLongQuoteMessage(message))
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

(* Every National Best Bid Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidLongAppendage2 ==
    \A message \in CheckedNationalBestBidLongAppendage2 :
        LET read == DecodeNationalBestBidLongAppendage2(EncodeNationalBestBidLongAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Offer Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestOfferLongAppendage2 ==
    \A message \in CheckedNationalBestOfferLongAppendage2 :
        LET read == DecodeNationalBestOfferLongAppendage2(EncodeNationalBestOfferLongAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid And Offer Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidAndOfferLongAppendage2 ==
    \A message \in CheckedNationalBestBidAndOfferLongAppendage2 :
        LET read == DecodeNationalBestBidAndOfferLongAppendage2(EncodeNationalBestBidAndOfferLongAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidShortAppendage2 ==
    \A message \in CheckedNationalBestBidShortAppendage2 :
        LET read == DecodeNationalBestBidShortAppendage2(EncodeNationalBestBidShortAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Offer Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestOfferShortAppendage2 ==
    \A message \in CheckedNationalBestOfferShortAppendage2 :
        LET read == DecodeNationalBestOfferShortAppendage2(EncodeNationalBestOfferShortAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid And Offer Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidAndOfferShortAppendage2 ==
    \A message \in CheckedNationalBestBidAndOfferShortAppendage2 :
        LET read == DecodeNationalBestBidAndOfferShortAppendage2(EncodeNationalBestBidAndOfferShortAppendage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortQuoteMessage ==
    \A message \in CheckedShortQuoteMessage :
        LET read == DecodeShortQuoteMessage(EncodeShortQuoteMessage(message))
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

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp22 ==
    \A message \in CheckedTimestamp22 :
        LET read == DecodeTimestamp22(EncodeTimestamp22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidLongAppendage3 ==
    \A message \in CheckedNationalBestBidLongAppendage3 :
        LET read == DecodeNationalBestBidLongAppendage3(EncodeNationalBestBidLongAppendage3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Offer Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestOfferLongAppendage3 ==
    \A message \in CheckedNationalBestOfferLongAppendage3 :
        LET read == DecodeNationalBestOfferLongAppendage3(EncodeNationalBestOfferLongAppendage3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid And Offer Long Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidAndOfferLongAppendage3 ==
    \A message \in CheckedNationalBestBidAndOfferLongAppendage3 :
        LET read == DecodeNationalBestBidAndOfferLongAppendage3(EncodeNationalBestBidAndOfferLongAppendage3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidShortAppendage3 ==
    \A message \in CheckedNationalBestBidShortAppendage3 :
        LET read == DecodeNationalBestBidShortAppendage3(EncodeNationalBestBidShortAppendage3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Offer Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestOfferShortAppendage3 ==
    \A message \in CheckedNationalBestOfferShortAppendage3 :
        LET read == DecodeNationalBestOfferShortAppendage3(EncodeNationalBestOfferShortAppendage3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every National Best Bid And Offer Short Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBestBidAndOfferShortAppendage3 ==
    \A message \in CheckedNationalBestBidAndOfferShortAppendage3 :
        LET read == DecodeNationalBestBidAndOfferShortAppendage3(EncodeNationalBestBidAndOfferShortAppendage3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Special Long Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialLongQuoteMessage ==
    \A message \in CheckedSpecialLongQuoteMessage :
        LET read == DecodeSpecialLongQuoteMessage(EncodeSpecialLongQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMessage ==
    \A message \in CheckedQuoteMessage :
        LET read == DecodeQuoteMessage(EncodeQuoteMessage(message))
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

(* A Market Status Message Payload is selected by the Market Status Message Type it is written under *)
SelectsMarketStatusMessagePayload ==
    \A message \in CheckedMarketStatusMessagePayload :
        LET read == DecodeMarketStatusMessagePayload(message.tag, EncodeMarketStatusMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A National Bbo Indicator is selected by the National Bbo Indicator it is written under *)
SelectsNationalBboIndicatorChoice ==
    \A message \in CheckedNationalBboIndicatorChoice :
        LET read == DecodeNationalBboIndicatorChoice(message.tag, EncodeNationalBboIndicatorChoice(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A National Bbo Indicator is selected by the National Bbo Indicator it is written under *)
SelectsNationalBboIndicatorChoice2 ==
    \A message \in CheckedNationalBboIndicatorChoice2 :
        LET read == DecodeNationalBboIndicatorChoice2(message.tag, EncodeNationalBboIndicatorChoice2(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A National Bbo Indicator is selected by the National Bbo Indicator it is written under *)
SelectsNationalBboIndicatorChoice3 ==
    \A message \in CheckedNationalBboIndicatorChoice3 :
        LET read == DecodeNationalBboIndicatorChoice3(message.tag, EncodeNationalBboIndicatorChoice3(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Quote Message Payload is selected by the Quote Message Type it is written under *)
SelectsQuoteMessagePayload ==
    \A message \in CheckedQuoteMessagePayload :
        LET read == DecodeQuoteMessagePayload(message.tag, EncodeQuoteMessagePayload(message))
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
