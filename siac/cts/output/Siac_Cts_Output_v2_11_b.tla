---------------------- MODULE Siac_Cts_Output_v2_11_b ----------------------
(***************************************************************************)
(* The Securities Industry Automation Corporation  v2.11.b                 *)
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
(* Start Of End Of Day Summary Message: 22 bytes                           *)
(***************************************************************************)

StartOfEndOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp1,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeStartOfEndOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp1(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeStartOfEndOfDaySummaryMessage(bytes) ==
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

ZeroStartOfEndOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp1,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfEndOfDaySummaryMessage ==
    { ZeroStartOfEndOfDaySummaryMessage }
        \cup { [ZeroStartOfEndOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp1 }
        \cup { [ZeroStartOfEndOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfEndOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* End Of End Of Day Summary Message: 22 bytes                             *)
(***************************************************************************)

EndOfEndOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp12,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeEndOfEndOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp12(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeEndOfEndOfDaySummaryMessage(bytes) ==
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

ZeroEndOfEndOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp12,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* End Of End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfEndOfDaySummaryMessage ==
    { ZeroEndOfEndOfDaySummaryMessage }
        \cup { [ZeroEndOfEndOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp12 }
        \cup { [ZeroEndOfEndOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfEndOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Start Of Start Of Day Summary Message: 22 bytes                         *)
(***************************************************************************)

StartOfStartOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp13,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeStartOfStartOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp13(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeStartOfStartOfDaySummaryMessage(bytes) ==
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

ZeroStartOfStartOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp13,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Start Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfStartOfDaySummaryMessage ==
    { ZeroStartOfStartOfDaySummaryMessage }
        \cup { [ZeroStartOfStartOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfStartOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp13 }
        \cup { [ZeroStartOfStartOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfStartOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfStartOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* End Of Start Of Day Summary Message: 22 bytes                           *)
(***************************************************************************)

EndOfStartOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp14,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeEndOfStartOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp14(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeEndOfStartOfDaySummaryMessage(bytes) ==
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

ZeroEndOfStartOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp14,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Start Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfStartOfDaySummaryMessage ==
    { ZeroEndOfStartOfDaySummaryMessage }
        \cup { [ZeroEndOfStartOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfStartOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp14 }
        \cup { [ZeroEndOfStartOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfStartOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroEndOfStartOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Symbol Reference Data Message: 205 bytes                                *)
(***************************************************************************)

SymbolReferenceDataMessage ==
    [ participantId                            : Sample(1),
      timestamp1                               : Timestamp15,
      messageId                                : Sample(1),
      transactionId                            : Sample(4),
      participantReferenceNumber               : Sample(8),
      securitySymbol                           : Sample(11),
      priorSecuritySymbol                      : Sample(11),
      primaryListingMarketParticipantId        : Sample(1),
      primaryListingMarketPreviousClosingPrice : Sample(8),
      consolidatedClosingPrice                 : Sample(8),
      roundLotSize                             : Sample(2),
      minimumPriceIncrementIndicator           : Sample(1),
      luldTier                                 : Sample(1),
      luldLeverageRatio                        : Sample(4),
      test                                     : Sample(1),
      ipo                                      : Sample(1),
      financialStatusIndicator                 : Sample(1),
      shortSaleRestrictionIndicator            : Sample(1),
      haltReason                               : Sample(1),
      instrumentType                           : Sample(1),
      reserved                                 : Sample(1),
      secondReserved                           : Sample(1),
      reserved128                              : Sample(128) ]

EncodeSymbolReferenceDataMessage(message) ==
    message.participantId
        \o EncodeTimestamp15(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.priorSecuritySymbol
        \o message.primaryListingMarketParticipantId
        \o message.primaryListingMarketPreviousClosingPrice
        \o message.consolidatedClosingPrice
        \o message.roundLotSize
        \o message.minimumPriceIncrementIndicator
        \o message.luldTier
        \o message.luldLeverageRatio
        \o message.test
        \o message.ipo
        \o message.financialStatusIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.haltReason
        \o message.instrumentType
        \o message.reserved
        \o message.secondReserved
        \o message.reserved128

DecodeSymbolReferenceDataMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp15(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET priorSecuritySymbol == ReadBytes(securitySymbol.rest, 11) IN IF ~priorSecuritySymbol.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(priorSecuritySymbol.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET primaryListingMarketPreviousClosingPrice == ReadBytes(primaryListingMarketParticipantId.rest, 8) IN IF ~primaryListingMarketPreviousClosingPrice.ok THEN Fail ELSE
    LET consolidatedClosingPrice == ReadBytes(primaryListingMarketPreviousClosingPrice.rest, 8) IN IF ~consolidatedClosingPrice.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(consolidatedClosingPrice.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET minimumPriceIncrementIndicator == ReadBytes(roundLotSize.rest, 1) IN IF ~minimumPriceIncrementIndicator.ok THEN Fail ELSE
    LET luldTier == ReadBytes(minimumPriceIncrementIndicator.rest, 1) IN IF ~luldTier.ok THEN Fail ELSE
    LET luldLeverageRatio == ReadBytes(luldTier.rest, 4) IN IF ~luldLeverageRatio.ok THEN Fail ELSE
    LET test == ReadBytes(luldLeverageRatio.rest, 1) IN IF ~test.ok THEN Fail ELSE
    LET ipo == ReadBytes(test.rest, 1) IN IF ~ipo.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(ipo.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET haltReason == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(haltReason.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET reserved == ReadBytes(instrumentType.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET secondReserved == ReadBytes(reserved.rest, 1) IN IF ~secondReserved.ok THEN Fail ELSE
    LET reserved128 == ReadBytes(secondReserved.rest, 128) IN IF ~reserved128.ok THEN Fail ELSE
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
         minimumPriceIncrementIndicator           |-> minimumPriceIncrementIndicator.value,
         luldTier                                 |-> luldTier.value,
         luldLeverageRatio                        |-> luldLeverageRatio.value,
         test                                     |-> test.value,
         ipo                                      |-> ipo.value,
         financialStatusIndicator                 |-> financialStatusIndicator.value,
         shortSaleRestrictionIndicator            |-> shortSaleRestrictionIndicator.value,
         haltReason                               |-> haltReason.value,
         instrumentType                           |-> instrumentType.value,
         reserved                                 |-> reserved.value,
         secondReserved                           |-> secondReserved.value,
         reserved128                              |-> reserved128.value ], reserved128.rest)

ZeroSymbolReferenceDataMessage ==
    [ participantId                            |-> [i \in 1 .. 1 |-> 0],
      timestamp1                               |-> ZeroTimestamp15,
      messageId                                |-> [i \in 1 .. 1 |-> 0],
      transactionId                            |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber               |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                           |-> [i \in 1 .. 11 |-> 0],
      priorSecuritySymbol                      |-> [i \in 1 .. 11 |-> 0],
      primaryListingMarketParticipantId        |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketPreviousClosingPrice |-> [i \in 1 .. 8 |-> 0],
      consolidatedClosingPrice                 |-> [i \in 1 .. 8 |-> 0],
      roundLotSize                             |-> [i \in 1 .. 2 |-> 0],
      minimumPriceIncrementIndicator           |-> [i \in 1 .. 1 |-> 0],
      luldTier                                 |-> [i \in 1 .. 1 |-> 0],
      luldLeverageRatio                        |-> [i \in 1 .. 4 |-> 0],
      test                                     |-> [i \in 1 .. 1 |-> 0],
      ipo                                      |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator                 |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator            |-> [i \in 1 .. 1 |-> 0],
      haltReason                               |-> [i \in 1 .. 1 |-> 0],
      instrumentType                           |-> [i \in 1 .. 1 |-> 0],
      reserved                                 |-> [i \in 1 .. 1 |-> 0],
      secondReserved                           |-> [i \in 1 .. 1 |-> 0],
      reserved128                              |-> [i \in 1 .. 128 |-> 0] ]

(* Symbol Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolReferenceDataMessage ==
    { ZeroSymbolReferenceDataMessage }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp15 }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.priorSecuritySymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.primaryListingMarketPreviousClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.consolidatedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.roundLotSize = one] : one \in Sample(2) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.minimumPriceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.luldTier = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.luldLeverageRatio = one] : one \in Sample(4) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.test = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.ipo = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.secondReserved = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.reserved128 = one] : one \in Sample(128) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

StartOfEndOfDaySummaryMessageCode == 65  \* "A"
EndOfEndOfDaySummaryMessageCode == 66  \* "B"
StartOfStartOfDaySummaryMessageCode == 67  \* "C"
EndOfStartOfDaySummaryMessageCode == 68  \* "D"
SymbolReferenceDataMessageCode == 83  \* "S"

AdministrativeMessagePayload ==
    [ tag : {StartOfEndOfDaySummaryMessageCode}, body : StartOfEndOfDaySummaryMessage ]
        \cup [ tag : {EndOfEndOfDaySummaryMessageCode}, body : EndOfEndOfDaySummaryMessage ]
        \cup [ tag : {StartOfStartOfDaySummaryMessageCode}, body : StartOfStartOfDaySummaryMessage ]
        \cup [ tag : {EndOfStartOfDaySummaryMessageCode}, body : EndOfStartOfDaySummaryMessage ]
        \cup [ tag : {SymbolReferenceDataMessageCode}, body : SymbolReferenceDataMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = StartOfEndOfDaySummaryMessageCode -> EncodeStartOfEndOfDaySummaryMessage(message.body)
      [] message.tag = EndOfEndOfDaySummaryMessageCode -> EncodeEndOfEndOfDaySummaryMessage(message.body)
      [] message.tag = StartOfStartOfDaySummaryMessageCode -> EncodeStartOfStartOfDaySummaryMessage(message.body)
      [] message.tag = EndOfStartOfDaySummaryMessageCode -> EncodeEndOfStartOfDaySummaryMessage(message.body)
      [] message.tag = SymbolReferenceDataMessageCode -> EncodeSymbolReferenceDataMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfEndOfDaySummaryMessageCode -> DecodeStartOfEndOfDaySummaryMessage(bytes)
              [] tag = EndOfEndOfDaySummaryMessageCode -> DecodeEndOfEndOfDaySummaryMessage(bytes)
              [] tag = StartOfStartOfDaySummaryMessageCode -> DecodeStartOfStartOfDaySummaryMessage(bytes)
              [] tag = EndOfStartOfDaySummaryMessageCode -> DecodeEndOfStartOfDaySummaryMessage(bytes)
              [] tag = SymbolReferenceDataMessageCode -> DecodeSymbolReferenceDataMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> StartOfEndOfDaySummaryMessageCode, body |-> ZeroStartOfEndOfDaySummaryMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> StartOfEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedStartOfEndOfDaySummaryMessage }
        \cup { [tag |-> EndOfEndOfDaySummaryMessageCode, body |-> one] : one \in CheckedEndOfEndOfDaySummaryMessage }
        \cup { [tag |-> StartOfStartOfDaySummaryMessageCode, body |-> one] : one \in CheckedStartOfStartOfDaySummaryMessage }
        \cup { [tag |-> EndOfStartOfDaySummaryMessageCode, body |-> one] : one \in CheckedEndOfStartOfDaySummaryMessage }
        \cup { [tag |-> SymbolReferenceDataMessageCode, body |-> one] : one \in CheckedSymbolReferenceDataMessage }

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
(* Start Of Day Message: 22 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp16,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeStartOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp16(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeStartOfDayMessage(bytes) ==
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

ZeroStartOfDayMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp16,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp16 }
        \cup { [ZeroStartOfDayMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Reset Block Sequence Number Message: 22 bytes                           *)
(***************************************************************************)

ResetBlockSequenceNumberMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp17,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeResetBlockSequenceNumberMessage(message) ==
    message.participantId
        \o EncodeTimestamp17(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeResetBlockSequenceNumberMessage(bytes) ==
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

ZeroResetBlockSequenceNumberMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp17,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Reset Block Sequence Number Message at zero, then each field in turn at the values it is checked at *)
CheckedResetBlockSequenceNumberMessage ==
    { ZeroResetBlockSequenceNumberMessage }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp17 }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroResetBlockSequenceNumberMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Disaster Recovery Data Center Activation Message: 22 bytes              *)
(***************************************************************************)

DisasterRecoveryDataCenterActivationMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp18,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeDisasterRecoveryDataCenterActivationMessage(message) ==
    message.participantId
        \o EncodeTimestamp18(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeDisasterRecoveryDataCenterActivationMessage(bytes) ==
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

ZeroDisasterRecoveryDataCenterActivationMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp18,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Disaster Recovery Data Center Activation Message at zero, then each field in turn at the values it is checked at *)
CheckedDisasterRecoveryDataCenterActivationMessage ==
    { ZeroDisasterRecoveryDataCenterActivationMessage }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp18 }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroDisasterRecoveryDataCenterActivationMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* Line Integrity Message: 22 bytes                                        *)
(***************************************************************************)

LineIntegrityMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp19,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeLineIntegrityMessage(message) ==
    message.participantId
        \o EncodeTimestamp19(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeLineIntegrityMessage(bytes) ==
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

ZeroLineIntegrityMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp19,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Line Integrity Message at zero, then each field in turn at the values it is checked at *)
CheckedLineIntegrityMessage ==
    { ZeroLineIntegrityMessage }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp19 }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }

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
(* End Of Day Message: 22 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp110,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8) ]

EncodeEndOfDayMessage(message) ==
    message.participantId
        \o EncodeTimestamp110(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber

DecodeEndOfDayMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp110(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                 |-> ZeroTimestamp110,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp110 }
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
(* Index Message: 41 bytes                                                 *)
(***************************************************************************)

IndexMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp111,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      indexSymbol                : Sample(11),
      indexValue                 : Sample(8) ]

EncodeIndexMessage(message) ==
    message.participantId
        \o EncodeTimestamp111(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.indexSymbol
        \o message.indexValue

DecodeIndexMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp111(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                 |-> ZeroTimestamp111,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      indexSymbol                |-> [i \in 1 .. 11 |-> 0],
      indexValue                 |-> [i \in 1 .. 8 |-> 0] ]

(* Index Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexMessage ==
    { ZeroIndexMessage }
        \cup { [ZeroIndexMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroIndexMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp111 }
        \cup { [ZeroIndexMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroIndexMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroIndexMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroIndexMessage EXCEPT !.indexSymbol = one] : one \in Sample(11) }
        \cup { [ZeroIndexMessage EXCEPT !.indexValue = one] : one \in Sample(8) }

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
(* Bid And Offer Index Message: 49 bytes                                   *)
(***************************************************************************)

BidAndOfferIndexMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp112,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      indexSymbol                : Sample(11),
      bidIndexValue              : Sample(8),
      offerIndexValue            : Sample(8) ]

EncodeBidAndOfferIndexMessage(message) ==
    message.participantId
        \o EncodeTimestamp112(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.indexSymbol
        \o message.bidIndexValue
        \o message.offerIndexValue

DecodeBidAndOfferIndexMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp112(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                 |-> ZeroTimestamp112,
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
        \cup { [ZeroBidAndOfferIndexMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp112 }
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
(* Market Wide Circuit Breaker Decline Level Status Message: 47 bytes      *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelStatusMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp113,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      mwcbLevel1                 : Sample(8),
      mwcbLevel2                 : Sample(8),
      mwcbLevel3                 : Sample(8),
      reserved                   : Sample(1) ]

EncodeMarketWideCircuitBreakerDeclineLevelStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp113(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3
        \o message.reserved

DecodeMarketWideCircuitBreakerDeclineLevelStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp113(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                 |-> ZeroTimestamp113,
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
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp113 }
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
(* Market Wide Circuit Breaker Status Message: 24 bytes                    *)
(***************************************************************************)

MarketWideCircuitBreakerStatusMessage ==
    [ participantId                          : Sample(1),
      timestamp1                             : Timestamp114,
      messageId                              : Sample(1),
      transactionId                          : Sample(4),
      participantReferenceNumber             : Sample(8),
      marketWideCircuitBreakerLevelIndicator : Sample(1),
      reserved                               : Sample(1) ]

EncodeMarketWideCircuitBreakerStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp114(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.marketWideCircuitBreakerLevelIndicator
        \o message.reserved

DecodeMarketWideCircuitBreakerStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp114(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                             |-> ZeroTimestamp114,
      messageId                              |-> [i \in 1 .. 1 |-> 0],
      transactionId                          |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber             |-> [i \in 1 .. 8 |-> 0],
      marketWideCircuitBreakerLevelIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved                               |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerStatusMessage ==
    { ZeroMarketWideCircuitBreakerStatusMessage }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp114 }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.marketWideCircuitBreakerLevelIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerStatusMessage EXCEPT !.reserved = one] : one \in Sample(1) }

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
(* Approximate Volume Participant: 9 bytes                                 *)
(***************************************************************************)

ApproximateVolumeParticipant ==
    [ participantId    : Sample(1),
      tradeTotalVolume : Sample(8) ]

EncodeApproximateVolumeParticipant(message) ==
    message.participantId
        \o message.tradeTotalVolume

DecodeApproximateVolumeParticipant(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET tradeTotalVolume == ReadBytes(participantId.rest, 8) IN IF ~tradeTotalVolume.ok THEN Fail ELSE
    Ok([ participantId    |-> participantId.value,
         tradeTotalVolume |-> tradeTotalVolume.value ], tradeTotalVolume.rest)

ZeroApproximateVolumeParticipant ==
    [ participantId    |-> [i \in 1 .. 1 |-> 0],
      tradeTotalVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Approximate Volume Participant at zero, then each field in turn at the values it is checked at *)
CheckedApproximateVolumeParticipant ==
    { ZeroApproximateVolumeParticipant }
        \cup { [ZeroApproximateVolumeParticipant EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateVolumeParticipant EXCEPT !.tradeTotalVolume = one] : one \in Sample(8) }

(* A run of Approximate Volume Participant, written one after another *)
RECURSIVE EncodeApproximateVolumeParticipantList(_)
EncodeApproximateVolumeParticipantList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeApproximateVolumeParticipant(Head(messages)) \o EncodeApproximateVolumeParticipantList(Tail(messages))

(* As many Approximate Volume Participant as the field that counts them says *)
RECURSIVE ReadApproximateVolumeParticipantList(_, _)
ReadApproximateVolumeParticipantList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeApproximateVolumeParticipant(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadApproximateVolumeParticipantList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Approximate Volume Participant of each kind, for the lists that carry them *)
OneApproximateVolumeParticipant == { ZeroApproximateVolumeParticipant }

(***************************************************************************)
(* Approximate Adjusted Volume Market Center Message                       *)
(***************************************************************************)

ApproximateAdjustedVolumeMarketCenterMessage ==
    [ participantId                : Sample(1),
      timestamp1                   : Timestamp115,
      messageId                    : Sample(1),
      transactionId                : Sample(4),
      participantReferenceNumber   : Sample(8),
      approximateVolumeParticipant : SampleLists(OneApproximateVolumeParticipant) ]

EncodeApproximateAdjustedVolumeMarketCenterMessage(message) ==
    message.participantId
        \o EncodeTimestamp115(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o EncodeUIntBE(Len(message.approximateVolumeParticipant), 1)
        \o EncodeApproximateVolumeParticipantList(message.approximateVolumeParticipant)

DecodeApproximateAdjustedVolumeMarketCenterMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp115(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET numberOfParticipants == ReadUIntBE(participantReferenceNumber.rest, 1) IN IF ~numberOfParticipants.ok THEN Fail ELSE
    LET approximateVolumeParticipant == ReadApproximateVolumeParticipantList(numberOfParticipants.rest, numberOfParticipants.value) IN IF ~approximateVolumeParticipant.ok THEN Fail ELSE
    Ok([ participantId                |-> participantId.value,
         timestamp1                   |-> timestamp1.value,
         messageId                    |-> messageId.value,
         transactionId                |-> transactionId.value,
         participantReferenceNumber   |-> participantReferenceNumber.value,
         approximateVolumeParticipant |-> approximateVolumeParticipant.value ], approximateVolumeParticipant.rest)

ZeroApproximateAdjustedVolumeMarketCenterMessage ==
    [ participantId                |-> [i \in 1 .. 1 |-> 0],
      timestamp1                   |-> ZeroTimestamp115,
      messageId                    |-> [i \in 1 .. 1 |-> 0],
      transactionId                |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber   |-> [i \in 1 .. 8 |-> 0],
      approximateVolumeParticipant |-> << >> ]

(* Approximate Adjusted Volume Market Center Message at zero, then each field in turn at the values it is checked at *)
CheckedApproximateAdjustedVolumeMarketCenterMessage ==
    { ZeroApproximateAdjustedVolumeMarketCenterMessage }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp115 }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.approximateVolumeParticipant = one] : one \in SampleLists(OneApproximateVolumeParticipant) }

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
(* Participant: 9 bytes                                                    *)
(***************************************************************************)

Participant ==
    [ participantId              : Sample(1),
      fractionalTradeTotalVolume : Sample(8) ]

EncodeParticipant(message) ==
    message.participantId
        \o message.fractionalTradeTotalVolume

DecodeParticipant(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET fractionalTradeTotalVolume == ReadBytes(participantId.rest, 8) IN IF ~fractionalTradeTotalVolume.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         fractionalTradeTotalVolume |-> fractionalTradeTotalVolume.value ], fractionalTradeTotalVolume.rest)

ZeroParticipant ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      fractionalTradeTotalVolume |-> [i \in 1 .. 8 |-> 0] ]

(* Participant at zero, then each field in turn at the values it is checked at *)
CheckedParticipant ==
    { ZeroParticipant }
        \cup { [ZeroParticipant EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroParticipant EXCEPT !.fractionalTradeTotalVolume = one] : one \in Sample(8) }

(* A run of Participant, written one after another *)
RECURSIVE EncodeParticipantList(_)
EncodeParticipantList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeParticipant(Head(messages)) \o EncodeParticipantList(Tail(messages))

(* As many Participant as the field that counts them says *)
RECURSIVE ReadParticipantList(_, _)
ReadParticipantList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeParticipant(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadParticipantList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Participant of each kind, for the lists that carry them *)
OneParticipant == { ZeroParticipant }

(***************************************************************************)
(* Fractional Approximate Adjusted Volume Market Center Message            *)
(***************************************************************************)

FractionalApproximateAdjustedVolumeMarketCenterMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp116,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      participant                : SampleLists(OneParticipant) ]

EncodeFractionalApproximateAdjustedVolumeMarketCenterMessage(message) ==
    message.participantId
        \o EncodeTimestamp116(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o EncodeUIntBE(Len(message.participant), 1)
        \o EncodeParticipantList(message.participant)

DecodeFractionalApproximateAdjustedVolumeMarketCenterMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp116(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET numberOfParticipants == ReadUIntBE(participantReferenceNumber.rest, 1) IN IF ~numberOfParticipants.ok THEN Fail ELSE
    LET participant == ReadParticipantList(numberOfParticipants.rest, numberOfParticipants.value) IN IF ~participant.ok THEN Fail ELSE
    Ok([ participantId              |-> participantId.value,
         timestamp1                 |-> timestamp1.value,
         messageId                  |-> messageId.value,
         transactionId              |-> transactionId.value,
         participantReferenceNumber |-> participantReferenceNumber.value,
         participant                |-> participant.value ], participant.rest)

ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp116,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      participant                |-> << >> ]

(* Fractional Approximate Adjusted Volume Market Center Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalApproximateAdjustedVolumeMarketCenterMessage ==
    { ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp116 }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalApproximateAdjustedVolumeMarketCenterMessage EXCEPT !.participant = one] : one \in SampleLists(OneParticipant) }

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
(* Approximate Trades And Total Dollar Value Message: 34 bytes             *)
(***************************************************************************)

ApproximateTradesAndTotalDollarValueMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp117,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      totalTrades                : Sample(4),
      dollarValue                : Sample(8) ]

EncodeApproximateTradesAndTotalDollarValueMessage(message) ==
    message.participantId
        \o EncodeTimestamp117(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.totalTrades
        \o message.dollarValue

DecodeApproximateTradesAndTotalDollarValueMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp117(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                 |-> ZeroTimestamp117,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      totalTrades                |-> [i \in 1 .. 4 |-> 0],
      dollarValue                |-> [i \in 1 .. 8 |-> 0] ]

(* Approximate Trades And Total Dollar Value Message at zero, then each field in turn at the values it is checked at *)
CheckedApproximateTradesAndTotalDollarValueMessage ==
    { ZeroApproximateTradesAndTotalDollarValueMessage }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp117 }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.totalTrades = one] : one \in Sample(4) }
        \cup { [ZeroApproximateTradesAndTotalDollarValueMessage EXCEPT !.dollarValue = one] : one \in Sample(8) }

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
(* Crossing Session Summary Message: 46 bytes                              *)
(***************************************************************************)

CrossingSessionSummaryMessage ==
    [ participantId                      : Sample(1),
      timestamp1                         : Timestamp118,
      messageId                          : Sample(1),
      transactionId                      : Sample(4),
      participantReferenceNumber         : Sample(8),
      crossingSessionITotalTradesVolume  : Sample(8),
      crossingSessionIiDollarValue       : Sample(8),
      crossingSessionIiTotalTradesVolume : Sample(8) ]

EncodeCrossingSessionSummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp118(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.crossingSessionITotalTradesVolume
        \o message.crossingSessionIiDollarValue
        \o message.crossingSessionIiTotalTradesVolume

DecodeCrossingSessionSummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp118(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                         |-> ZeroTimestamp118,
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
        \cup { [ZeroCrossingSessionSummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp118 }
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
(* Corrected Prior Day Trade Date and Time: 8 bytes                        *)
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

(* Corrected Prior Day Trade Date and Time at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedPriorDayTradeDateAndTime ==
    { ZeroCorrectedPriorDayTradeDateAndTime }
        \cup { [ZeroCorrectedPriorDayTradeDateAndTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedPriorDayTradeDateAndTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Original Prior Day Trade Date and Time: 8 bytes                         *)
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

(* Original Prior Day Trade Date and Time at zero, then each field in turn at the values it is checked at *)
CheckedOriginalPriorDayTradeDateAndTime ==
    { ZeroOriginalPriorDayTradeDateAndTime }
        \cup { [ZeroOriginalPriorDayTradeDateAndTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroOriginalPriorDayTradeDateAndTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Prior Day Trade Correction Message: 91 bytes                            *)
(***************************************************************************)

PriorDayTradeCorrectionMessage ==
    [ participantId                          : Sample(1),
      timestamp1                             : Timestamp119,
      messageId                              : Sample(1),
      transactionId                          : Sample(4),
      participantReferenceNumber             : Sample(8),
      securitySymbol                         : Sample(11),
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
    message.participantId
        \o EncodeTimestamp119(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
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
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp119(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
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
    Ok([ participantId                          |-> participantId.value,
         timestamp1                             |-> timestamp1.value,
         messageId                              |-> messageId.value,
         transactionId                          |-> transactionId.value,
         participantReferenceNumber             |-> participantReferenceNumber.value,
         securitySymbol                         |-> securitySymbol.value,
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
    [ participantId                          |-> [i \in 1 .. 1 |-> 0],
      timestamp1                             |-> ZeroTimestamp119,
      messageId                              |-> [i \in 1 .. 1 |-> 0],
      transactionId                          |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber             |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                         |-> [i \in 1 .. 11 |-> 0],
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
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp119 }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCorrectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
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
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition4 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition4(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition4(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition4 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition4 ==
    { ZeroSaleCondition4 }
        \cup { [ZeroSaleCondition4 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition4 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition4 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition4 EXCEPT !.category4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date and Time: 8 bytes                                  *)
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

(* Prior Day Trade Date and Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime ==
    { ZeroPriorDayTradeDateAndTime }
        \cup { [ZeroPriorDayTradeDateAndTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

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
      saleCondition4                : SaleCondition4,
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime ]

EncodePriorDayTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp120(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleCondition4(message.saleCondition4)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime(message.priorDayTradeDateAndTime)

DecodePriorDayTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp120(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition4 == DecodeSaleCondition4(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition4                |-> saleCondition4.value,
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
      saleCondition4                |-> ZeroSaleCondition4,
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
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp120 }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition4 }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime }

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
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition42 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition42(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition42(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition42 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition42 ==
    { ZeroSaleCondition42 }
        \cup { [ZeroSaleCondition42 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition42 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition42 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition42 EXCEPT !.category4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date and Time: 8 bytes                                  *)
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

(* Prior Day Trade Date and Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime2 ==
    { ZeroPriorDayTradeDateAndTime2 }
        \cup { [ZeroPriorDayTradeDateAndTime2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Prior Day Trade Cancel Error Message: 64 bytes                          *)
(***************************************************************************)

PriorDayTradeCancelErrorMessage ==
    [ participantId                 : Sample(1),
      timestamp1                    : Timestamp121,
      messageId                     : Sample(1),
      transactionId                 : Sample(4),
      participantReferenceNumber    : Sample(8),
      securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleCondition4                : SaleCondition42,
      tradePrice                    : Sample(8),
      tradeVolume                   : Sample(4),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime2,
      cancelErrorAction             : Sample(1) ]

EncodePriorDayTradeCancelErrorMessage(message) ==
    message.participantId
        \o EncodeTimestamp121(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleCondition42(message.saleCondition4)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime2(message.priorDayTradeDateAndTime)
        \o message.cancelErrorAction

DecodePriorDayTradeCancelErrorMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp121(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition4 == DecodeSaleCondition42(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime2(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(priorDayTradeDateAndTime.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition4                |-> saleCondition4.value,
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
      timestamp1                    |-> ZeroTimestamp121,
      messageId                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                 |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber    |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleCondition4                |-> ZeroSaleCondition42,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                   |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime2,
      cancelErrorAction             |-> [i \in 1 .. 1 |-> 0] ]

(* Prior Day Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeCancelErrorMessage ==
    { ZeroPriorDayTradeCancelErrorMessage }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp121 }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition42 }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime2 }
        \cup { [ZeroPriorDayTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }

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
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition43 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition43(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition43(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition43 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition43 ==
    { ZeroSaleCondition43 }
        \cup { [ZeroSaleCondition43 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition43 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition43 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition43 EXCEPT !.category4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date and Time: 8 bytes                                  *)
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

(* Prior Day Trade Date and Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime3 ==
    { ZeroPriorDayTradeDateAndTime3 }
        \cup { [ZeroPriorDayTradeDateAndTime3 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime3 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Prior Day Trade Correction Message: 67 bytes                 *)
(***************************************************************************)

FractionalPriorDayTradeCorrectionMessage ==
    [ participantId                 : Sample(1),
      timestamp1                    : Timestamp122,
      messageId                     : Sample(1),
      transactionId                 : Sample(4),
      participantReferenceNumber    : Sample(8),
      securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleCondition4                : SaleCondition43,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime3 ]

EncodeFractionalPriorDayTradeCorrectionMessage(message) ==
    message.participantId
        \o EncodeTimestamp122(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleCondition43(message.saleCondition4)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime3(message.priorDayTradeDateAndTime)

DecodeFractionalPriorDayTradeCorrectionMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp122(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition4 == DecodeSaleCondition43(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime3(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition4                |-> saleCondition4.value,
         tradePrice                    |-> tradePrice.value,
         fractionalTradeVolume         |-> fractionalTradeVolume.value,
         sellersSaleDays               |-> sellersSaleDays.value,
         stopStockIndicator            |-> stopStockIndicator.value,
         tradeThroughExemptIndicator   |-> tradeThroughExemptIndicator.value,
         shortSaleRestrictionIndicator |-> shortSaleRestrictionIndicator.value,
         tradeReportingFacilityId      |-> tradeReportingFacilityId.value,
         priorDayTradeDateAndTime      |-> priorDayTradeDateAndTime.value ], priorDayTradeDateAndTime.rest)

ZeroFractionalPriorDayTradeCorrectionMessage ==
    [ participantId                 |-> [i \in 1 .. 1 |-> 0],
      timestamp1                    |-> ZeroTimestamp122,
      messageId                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                 |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber    |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleCondition4                |-> ZeroSaleCondition43,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime3 ]

(* Fractional Prior Day Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeCorrectionMessage ==
    { ZeroFractionalPriorDayTradeCorrectionMessage }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp122 }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition43 }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCorrectionMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime3 }

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
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition44 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition44(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition44(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition44 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition44 ==
    { ZeroSaleCondition44 }
        \cup { [ZeroSaleCondition44 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition44 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition44 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition44 EXCEPT !.category4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date and Time: 8 bytes                                  *)
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

(* Prior Day Trade Date and Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime4 ==
    { ZeroPriorDayTradeDateAndTime4 }
        \cup { [ZeroPriorDayTradeDateAndTime4 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime4 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Prior Day Trade Message: 67 bytes                            *)
(***************************************************************************)

FractionalPriorDayTradeMessage ==
    [ participantId                 : Sample(1),
      timestamp1                    : Timestamp123,
      messageId                     : Sample(1),
      transactionId                 : Sample(4),
      participantReferenceNumber    : Sample(8),
      securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleCondition4                : SaleCondition44,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime4 ]

EncodeFractionalPriorDayTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp123(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleCondition44(message.saleCondition4)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime4(message.priorDayTradeDateAndTime)

DecodeFractionalPriorDayTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp123(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition4 == DecodeSaleCondition44(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime4(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition4                |-> saleCondition4.value,
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
      timestamp1                    |-> ZeroTimestamp123,
      messageId                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                 |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber    |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleCondition4                |-> ZeroSaleCondition44,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime4 ]

(* Fractional Prior Day Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeMessage ==
    { ZeroFractionalPriorDayTradeMessage }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp123 }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition44 }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime4 }

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
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition45 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition45(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition45(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition45 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition45 ==
    { ZeroSaleCondition45 }
        \cup { [ZeroSaleCondition45 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition45 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition45 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition45 EXCEPT !.category4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Trade Date and Time: 8 bytes                                  *)
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

(* Prior Day Trade Date and Time at zero, then each field in turn at the values it is checked at *)
CheckedPriorDayTradeDateAndTime5 ==
    { ZeroPriorDayTradeDateAndTime5 }
        \cup { [ZeroPriorDayTradeDateAndTime5 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroPriorDayTradeDateAndTime5 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Fractional Prior Day Trade Cancel Error Message: 68 bytes               *)
(***************************************************************************)

FractionalPriorDayTradeCancelErrorMessage ==
    [ participantId                 : Sample(1),
      timestamp1                    : Timestamp124,
      messageId                     : Sample(1),
      transactionId                 : Sample(4),
      participantReferenceNumber    : Sample(8),
      securitySymbol                : Sample(11),
      instrumentType                : Sample(1),
      saleCondition4                : SaleCondition45,
      tradePrice                    : Sample(8),
      fractionalTradeVolume         : Sample(8),
      sellersSaleDays               : Sample(1),
      stopStockIndicator            : Sample(1),
      tradeThroughExemptIndicator   : Sample(1),
      shortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId      : Sample(1),
      priorDayTradeDateAndTime      : PriorDayTradeDateAndTime5,
      cancelErrorAction             : Sample(1) ]

EncodeFractionalPriorDayTradeCancelErrorMessage(message) ==
    message.participantId
        \o EncodeTimestamp124(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleCondition45(message.saleCondition4)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodePriorDayTradeDateAndTime5(message.priorDayTradeDateAndTime)
        \o message.cancelErrorAction

DecodeFractionalPriorDayTradeCancelErrorMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp124(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition4 == DecodeSaleCondition45(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET priorDayTradeDateAndTime == DecodePriorDayTradeDateAndTime5(tradeReportingFacilityId.rest) IN IF ~priorDayTradeDateAndTime.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(priorDayTradeDateAndTime.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         timestamp1                    |-> timestamp1.value,
         messageId                     |-> messageId.value,
         transactionId                 |-> transactionId.value,
         participantReferenceNumber    |-> participantReferenceNumber.value,
         securitySymbol                |-> securitySymbol.value,
         instrumentType                |-> instrumentType.value,
         saleCondition4                |-> saleCondition4.value,
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
      timestamp1                    |-> ZeroTimestamp124,
      messageId                     |-> [i \in 1 .. 1 |-> 0],
      transactionId                 |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber    |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      instrumentType                |-> [i \in 1 .. 1 |-> 0],
      saleCondition4                |-> ZeroSaleCondition45,
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId      |-> [i \in 1 .. 1 |-> 0],
      priorDayTradeDateAndTime      |-> ZeroPriorDayTradeDateAndTime5,
      cancelErrorAction             |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Prior Day Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalPriorDayTradeCancelErrorMessage ==
    { ZeroFractionalPriorDayTradeCancelErrorMessage }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp124 }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition45 }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.priorDayTradeDateAndTime = one] : one \in CheckedPriorDayTradeDateAndTime5 }
        \cup { [ZeroFractionalPriorDayTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Prior Day Message Payload, selected by Prior Day Message Type           *)
(***************************************************************************)

PriorDayTradeCorrectionMessageCode == 67  \* "C"
PriorDayTradeMessageCode == 84  \* "T"
PriorDayTradeCancelErrorMessageCode == 88  \* "X"
FractionalPriorDayTradeCorrectionMessageCode == 79  \* "O"
FractionalPriorDayTradeMessageCode == 82  \* "R"
FractionalPriorDayTradeCancelErrorMessageCode == 69  \* "E"

PriorDayMessagePayload ==
    [ tag : {PriorDayTradeCorrectionMessageCode}, body : PriorDayTradeCorrectionMessage ]
        \cup [ tag : {PriorDayTradeMessageCode}, body : PriorDayTradeMessage ]
        \cup [ tag : {PriorDayTradeCancelErrorMessageCode}, body : PriorDayTradeCancelErrorMessage ]
        \cup [ tag : {FractionalPriorDayTradeCorrectionMessageCode}, body : FractionalPriorDayTradeCorrectionMessage ]
        \cup [ tag : {FractionalPriorDayTradeMessageCode}, body : FractionalPriorDayTradeMessage ]
        \cup [ tag : {FractionalPriorDayTradeCancelErrorMessageCode}, body : FractionalPriorDayTradeCancelErrorMessage ]

EncodePriorDayMessagePayload(message) ==
    CASE message.tag = PriorDayTradeCorrectionMessageCode -> EncodePriorDayTradeCorrectionMessage(message.body)
      [] message.tag = PriorDayTradeMessageCode -> EncodePriorDayTradeMessage(message.body)
      [] message.tag = PriorDayTradeCancelErrorMessageCode -> EncodePriorDayTradeCancelErrorMessage(message.body)
      [] message.tag = FractionalPriorDayTradeCorrectionMessageCode -> EncodeFractionalPriorDayTradeCorrectionMessage(message.body)
      [] message.tag = FractionalPriorDayTradeMessageCode -> EncodeFractionalPriorDayTradeMessage(message.body)
      [] message.tag = FractionalPriorDayTradeCancelErrorMessageCode -> EncodeFractionalPriorDayTradeCancelErrorMessage(message.body)

DecodePriorDayMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = PriorDayTradeCorrectionMessageCode -> DecodePriorDayTradeCorrectionMessage(bytes)
              [] tag = PriorDayTradeMessageCode -> DecodePriorDayTradeMessage(bytes)
              [] tag = PriorDayTradeCancelErrorMessageCode -> DecodePriorDayTradeCancelErrorMessage(bytes)
              [] tag = FractionalPriorDayTradeCorrectionMessageCode -> DecodeFractionalPriorDayTradeCorrectionMessage(bytes)
              [] tag = FractionalPriorDayTradeMessageCode -> DecodeFractionalPriorDayTradeMessage(bytes)
              [] tag = FractionalPriorDayTradeCancelErrorMessageCode -> DecodeFractionalPriorDayTradeCancelErrorMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPriorDayMessagePayload == [tag |-> PriorDayTradeCorrectionMessageCode, body |-> ZeroPriorDayTradeCorrectionMessage]

(* Each Prior Day Message Payload in turn, at the values the message it names is checked at *)
CheckedPriorDayMessagePayload ==
    { [tag |-> PriorDayTradeCorrectionMessageCode, body |-> one] : one \in CheckedPriorDayTradeCorrectionMessage }
        \cup { [tag |-> PriorDayTradeMessageCode, body |-> one] : one \in CheckedPriorDayTradeMessage }
        \cup { [tag |-> PriorDayTradeCancelErrorMessageCode, body |-> one] : one \in CheckedPriorDayTradeCancelErrorMessage }
        \cup { [tag |-> FractionalPriorDayTradeCorrectionMessageCode, body |-> one] : one \in CheckedFractionalPriorDayTradeCorrectionMessage }
        \cup { [tag |-> FractionalPriorDayTradeMessageCode, body |-> one] : one \in CheckedFractionalPriorDayTradeMessage }
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
(* Consolidated Start Of Day Summary Message: 51 bytes                     *)
(***************************************************************************)

ConsolidatedStartOfDaySummaryMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp125,
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
        \o EncodeTimestamp125(message.timestamp1)
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
    LET timestamp1 == DecodeTimestamp125(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                        |-> ZeroTimestamp125,
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
        \cup { [ZeroConsolidatedStartOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp125 }
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
(* Participant Start Of Day Summary Message: 47 bytes                      *)
(***************************************************************************)

ParticipantStartOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp126,
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
        \o EncodeTimestamp126(message.timestamp1)
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
    LET timestamp1 == DecodeTimestamp126(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                 |-> ZeroTimestamp126,
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
        \cup { [ZeroParticipantStartOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp126 }
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
(* Consolidated End Of Day Summary Message: 75 bytes                       *)
(***************************************************************************)

ConsolidatedEndOfDaySummaryMessage ==
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
      totalVolume                       : Sample(8),
      shortSaleRestrictionIndicator     : Sample(1),
      primaryListingMarketParticipantId : Sample(1),
      financialStatusIndicator          : Sample(1),
      numberOfParticipants              : Sample(1) ]

EncodeConsolidatedEndOfDaySummaryMessage(message) ==
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
        \o message.totalVolume
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.numberOfParticipants

DecodeConsolidatedEndOfDaySummaryMessage(bytes) ==
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
      totalVolume                       |-> [i \in 1 .. 8 |-> 0],
      shortSaleRestrictionIndicator     |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator          |-> [i \in 1 .. 1 |-> 0],
      numberOfParticipants              |-> [i \in 1 .. 1 |-> 0] ]

(* Consolidated End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedEndOfDaySummaryMessage ==
    { ZeroConsolidatedEndOfDaySummaryMessage }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp127 }
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
(* Fractional Consolidated End Of Day Summary Message: 75 bytes            *)
(***************************************************************************)

FractionalConsolidatedEndOfDaySummaryMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp128,
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
        \o EncodeTimestamp128(message.timestamp1)
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
    LET timestamp1 == DecodeTimestamp128(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                        |-> ZeroTimestamp128,
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
        \cup { [ZeroFractionalConsolidatedEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp128 }
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
(* Participant End Of Day Summary Message: 80 bytes                        *)
(***************************************************************************)

ParticipantEndOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp129,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      securitySymbol             : Sample(11),
      instrumentType             : Sample(1),
      summaryParticipantId       : Sample(1),
      previousClosePriceDate     : Sample(4),
      lastPrice                  : Sample(8),
      highPrice                  : Sample(8),
      lowPrice                   : Sample(8),
      openPrice                  : Sample(8),
      totalVolume                : Sample(8),
      tick                       : Sample(1) ]

EncodeParticipantEndOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp129(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.summaryParticipantId
        \o message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.totalVolume
        \o message.tick

DecodeParticipantEndOfDaySummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp129(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET summaryParticipantId == ReadBytes(instrumentType.rest, 1) IN IF ~summaryParticipantId.ok THEN Fail ELSE
    LET previousClosePriceDate == ReadBytes(summaryParticipantId.rest, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
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
         summaryParticipantId       |-> summaryParticipantId.value,
         previousClosePriceDate     |-> previousClosePriceDate.value,
         lastPrice                  |-> lastPrice.value,
         highPrice                  |-> highPrice.value,
         lowPrice                   |-> lowPrice.value,
         openPrice                  |-> openPrice.value,
         totalVolume                |-> totalVolume.value,
         tick                       |-> tick.value ], tick.rest)

ZeroParticipantEndOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp129,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      securitySymbol             |-> [i \in 1 .. 11 |-> 0],
      instrumentType             |-> [i \in 1 .. 1 |-> 0],
      summaryParticipantId       |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp129 }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroParticipantEndOfDaySummaryMessage EXCEPT !.summaryParticipantId = one] : one \in Sample(1) }
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
(* Fractional Participant End Of Day Summary Message: 80 bytes             *)
(***************************************************************************)

FractionalParticipantEndOfDaySummaryMessage ==
    [ participantId              : Sample(1),
      timestamp1                 : Timestamp130,
      messageId                  : Sample(1),
      transactionId              : Sample(4),
      participantReferenceNumber : Sample(8),
      securitySymbol             : Sample(11),
      instrumentType             : Sample(1),
      summaryParticipantId       : Sample(1),
      previousClosePriceDate     : Sample(4),
      lastPrice                  : Sample(8),
      highPrice                  : Sample(8),
      lowPrice                   : Sample(8),
      openPrice                  : Sample(8),
      fractionalTotalVolume      : Sample(8),
      tick                       : Sample(1) ]

EncodeFractionalParticipantEndOfDaySummaryMessage(message) ==
    message.participantId
        \o EncodeTimestamp130(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.summaryParticipantId
        \o message.previousClosePriceDate
        \o message.lastPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.fractionalTotalVolume
        \o message.tick

DecodeFractionalParticipantEndOfDaySummaryMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp130(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET summaryParticipantId == ReadBytes(instrumentType.rest, 1) IN IF ~summaryParticipantId.ok THEN Fail ELSE
    LET previousClosePriceDate == ReadBytes(summaryParticipantId.rest, 4) IN IF ~previousClosePriceDate.ok THEN Fail ELSE
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
         summaryParticipantId       |-> summaryParticipantId.value,
         previousClosePriceDate     |-> previousClosePriceDate.value,
         lastPrice                  |-> lastPrice.value,
         highPrice                  |-> highPrice.value,
         lowPrice                   |-> lowPrice.value,
         openPrice                  |-> openPrice.value,
         fractionalTotalVolume      |-> fractionalTotalVolume.value,
         tick                       |-> tick.value ], tick.rest)

ZeroFractionalParticipantEndOfDaySummaryMessage ==
    [ participantId              |-> [i \in 1 .. 1 |-> 0],
      timestamp1                 |-> ZeroTimestamp130,
      messageId                  |-> [i \in 1 .. 1 |-> 0],
      transactionId              |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      securitySymbol             |-> [i \in 1 .. 11 |-> 0],
      instrumentType             |-> [i \in 1 .. 1 |-> 0],
      summaryParticipantId       |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp130 }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalParticipantEndOfDaySummaryMessage EXCEPT !.summaryParticipantId = one] : one \in Sample(1) }
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
(* Auction Status Message: 124 bytes                                       *)
(***************************************************************************)

AuctionStatusMessage ==
    [ participantId                     : Sample(1),
      timestamp1                        : Timestamp131,
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
        \o EncodeTimestamp131(message.timestamp1)
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
    LET timestamp1 == DecodeTimestamp131(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
      timestamp1                        |-> ZeroTimestamp131,
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
        \cup { [ZeroAuctionStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp131 }
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
(* Trade Correction Message: 168 bytes                                     *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ participantId                          : Sample(1),
      timestamp1                             : Timestamp132,
      messageId                              : Sample(1),
      transactionId                          : Sample(4),
      participantReferenceNumber             : Sample(8),
      securitySymbol                         : Sample(11),
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
      originalParticipantReferenceNumber     : Sample(8),
      originalSaleCondition                  : Sample(4),
      originalTradePrice                     : Sample(8),
      originalTradeVolume                    : Sample(4),
      originalSellersSaleDays                : Sample(1),
      originalStopStockIndicator             : Sample(1),
      originalTradeThroughExemptIndicator    : Sample(1),
      originalShortSaleRestrictionIndicator  : Sample(1),
      primaryListingMarketParticipantId      : Sample(1),
      financialStatusIndicator               : Sample(1),
      consolidatedPreviousClosePriceDate     : Sample(4),
      consolidatedLastParticipantId          : Sample(1),
      consolidatedLastPrice                  : Sample(8),
      consolidatedHighPrice                  : Sample(8),
      consolidatedLowPrice                   : Sample(8),
      consolidatedTotalVolume                : Sample(4),
      consolidatedTick                       : Sample(1),
      participantPreviousClosePriceDate      : Sample(4),
      participantLastPrice                   : Sample(8),
      participantHighPrice                   : Sample(8),
      participantLowPrice                    : Sample(8),
      participantOpenPrice                   : Sample(8),
      participantTotalVolume                 : Sample(4),
      participantTick                        : Sample(1) ]

EncodeTradeCorrectionMessage(message) ==
    message.participantId
        \o EncodeTimestamp132(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
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
        \o message.originalSaleCondition
        \o message.originalTradePrice
        \o message.originalTradeVolume
        \o message.originalSellersSaleDays
        \o message.originalStopStockIndicator
        \o message.originalTradeThroughExemptIndicator
        \o message.originalShortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.consolidatedPreviousClosePriceDate
        \o message.consolidatedLastParticipantId
        \o message.consolidatedLastPrice
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedTotalVolume
        \o message.consolidatedTick
        \o message.participantPreviousClosePriceDate
        \o message.participantLastPrice
        \o message.participantHighPrice
        \o message.participantLowPrice
        \o message.participantOpenPrice
        \o message.participantTotalVolume
        \o message.participantTick

DecodeTradeCorrectionMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp132(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
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
    LET originalSaleCondition == ReadBytes(originalParticipantReferenceNumber.rest, 4) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalSaleCondition.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeVolume == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeVolume.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalTradeVolume.rest, 1) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET originalStopStockIndicator == ReadBytes(originalSellersSaleDays.rest, 1) IN IF ~originalStopStockIndicator.ok THEN Fail ELSE
    LET originalTradeThroughExemptIndicator == ReadBytes(originalStopStockIndicator.rest, 1) IN IF ~originalTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET originalShortSaleRestrictionIndicator == ReadBytes(originalTradeThroughExemptIndicator.rest, 1) IN IF ~originalShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(originalShortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET consolidatedPreviousClosePriceDate == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~consolidatedPreviousClosePriceDate.ok THEN Fail ELSE
    LET consolidatedLastParticipantId == ReadBytes(consolidatedPreviousClosePriceDate.rest, 1) IN IF ~consolidatedLastParticipantId.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLastParticipantId.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedTotalVolume == ReadBytes(consolidatedLowPrice.rest, 4) IN IF ~consolidatedTotalVolume.ok THEN Fail ELSE
    LET consolidatedTick == ReadBytes(consolidatedTotalVolume.rest, 1) IN IF ~consolidatedTick.ok THEN Fail ELSE
    LET participantPreviousClosePriceDate == ReadBytes(consolidatedTick.rest, 4) IN IF ~participantPreviousClosePriceDate.ok THEN Fail ELSE
    LET participantLastPrice == ReadBytes(participantPreviousClosePriceDate.rest, 8) IN IF ~participantLastPrice.ok THEN Fail ELSE
    LET participantHighPrice == ReadBytes(participantLastPrice.rest, 8) IN IF ~participantHighPrice.ok THEN Fail ELSE
    LET participantLowPrice == ReadBytes(participantHighPrice.rest, 8) IN IF ~participantLowPrice.ok THEN Fail ELSE
    LET participantOpenPrice == ReadBytes(participantLowPrice.rest, 8) IN IF ~participantOpenPrice.ok THEN Fail ELSE
    LET participantTotalVolume == ReadBytes(participantOpenPrice.rest, 4) IN IF ~participantTotalVolume.ok THEN Fail ELSE
    LET participantTick == ReadBytes(participantTotalVolume.rest, 1) IN IF ~participantTick.ok THEN Fail ELSE
    Ok([ participantId                          |-> participantId.value,
         timestamp1                             |-> timestamp1.value,
         messageId                              |-> messageId.value,
         transactionId                          |-> transactionId.value,
         participantReferenceNumber             |-> participantReferenceNumber.value,
         securitySymbol                         |-> securitySymbol.value,
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
         originalParticipantReferenceNumber     |-> originalParticipantReferenceNumber.value,
         originalSaleCondition                  |-> originalSaleCondition.value,
         originalTradePrice                     |-> originalTradePrice.value,
         originalTradeVolume                    |-> originalTradeVolume.value,
         originalSellersSaleDays                |-> originalSellersSaleDays.value,
         originalStopStockIndicator             |-> originalStopStockIndicator.value,
         originalTradeThroughExemptIndicator    |-> originalTradeThroughExemptIndicator.value,
         originalShortSaleRestrictionIndicator  |-> originalShortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId      |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator               |-> financialStatusIndicator.value,
         consolidatedPreviousClosePriceDate     |-> consolidatedPreviousClosePriceDate.value,
         consolidatedLastParticipantId          |-> consolidatedLastParticipantId.value,
         consolidatedLastPrice                  |-> consolidatedLastPrice.value,
         consolidatedHighPrice                  |-> consolidatedHighPrice.value,
         consolidatedLowPrice                   |-> consolidatedLowPrice.value,
         consolidatedTotalVolume                |-> consolidatedTotalVolume.value,
         consolidatedTick                       |-> consolidatedTick.value,
         participantPreviousClosePriceDate      |-> participantPreviousClosePriceDate.value,
         participantLastPrice                   |-> participantLastPrice.value,
         participantHighPrice                   |-> participantHighPrice.value,
         participantLowPrice                    |-> participantLowPrice.value,
         participantOpenPrice                   |-> participantOpenPrice.value,
         participantTotalVolume                 |-> participantTotalVolume.value,
         participantTick                        |-> participantTick.value ], participantTick.rest)

ZeroTradeCorrectionMessage ==
    [ participantId                          |-> [i \in 1 .. 1 |-> 0],
      timestamp1                             |-> ZeroTimestamp132,
      messageId                              |-> [i \in 1 .. 1 |-> 0],
      transactionId                          |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber             |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                         |-> [i \in 1 .. 11 |-> 0],
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
      originalParticipantReferenceNumber     |-> [i \in 1 .. 8 |-> 0],
      originalSaleCondition                  |-> [i \in 1 .. 4 |-> 0],
      originalTradePrice                     |-> [i \in 1 .. 8 |-> 0],
      originalTradeVolume                    |-> [i \in 1 .. 4 |-> 0],
      originalSellersSaleDays                |-> [i \in 1 .. 1 |-> 0],
      originalStopStockIndicator             |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemptIndicator    |-> [i \in 1 .. 1 |-> 0],
      originalShortSaleRestrictionIndicator  |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId      |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator               |-> [i \in 1 .. 1 |-> 0],
      consolidatedPreviousClosePriceDate     |-> [i \in 1 .. 4 |-> 0],
      consolidatedLastParticipantId          |-> [i \in 1 .. 1 |-> 0],
      consolidatedLastPrice                  |-> [i \in 1 .. 8 |-> 0],
      consolidatedHighPrice                  |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice                   |-> [i \in 1 .. 8 |-> 0],
      consolidatedTotalVolume                |-> [i \in 1 .. 4 |-> 0],
      consolidatedTick                       |-> [i \in 1 .. 1 |-> 0],
      participantPreviousClosePriceDate      |-> [i \in 1 .. 4 |-> 0],
      participantLastPrice                   |-> [i \in 1 .. 8 |-> 0],
      participantHighPrice                   |-> [i \in 1 .. 8 |-> 0],
      participantLowPrice                    |-> [i \in 1 .. 8 |-> 0],
      participantOpenPrice                   |-> [i \in 1 .. 8 |-> 0],
      participantTotalVolume                 |-> [i \in 1 .. 4 |-> 0],
      participantTick                        |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp132 }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
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
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalStopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalShortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedPreviousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedLastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedTotalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedTick = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantPreviousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantTotalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.participantTick = one] : one \in Sample(1) }

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
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition46 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition46(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition46(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition46 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition46 ==
    { ZeroSaleCondition46 }
        \cup { [ZeroSaleCondition46 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition46 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition46 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition46 EXCEPT !.category4 = one] : one \in Sample(1) }

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
      saleCondition4                      : SaleCondition46,
      tradePrice                          : Sample(8),
      tradeVolume                         : Sample(4),
      sellersSaleDays                     : Sample(1),
      stopStockIndicator                  : Sample(1),
      tradeThroughExemptIndicator         : Sample(1),
      tradeReportingFacilityId            : Sample(1),
      timestamp2                          : Timestamp22,
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
        \o EncodeSaleCondition46(message.saleCondition4)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp22(message.timestamp2)
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
    LET saleCondition4 == DecodeSaleCondition46(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp22(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
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
         saleCondition4                      |-> saleCondition4.value,
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
      saleCondition4                      |-> ZeroSaleCondition46,
      tradePrice                          |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                         |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays                     |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator                  |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator         |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId            |-> [i \in 1 .. 1 |-> 0],
      timestamp2                          |-> ZeroTimestamp22,
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
        \cup { [ZeroLongTradeMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition46 }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroLongTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroLongTradeMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp22 }
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
(* Short Trade Message: 36 bytes                                           *)
(***************************************************************************)

ShortTradeMessage ==
    [ participantId                       : Sample(1),
      timestamp1                          : Timestamp134,
      messageId                           : Sample(1),
      transactionId                       : Sample(4),
      participantReferenceNumber          : Sample(8),
      securitySymbol5                     : Sample(5),
      saleCondition1                      : Sample(1),
      saleConditionCategory               : Sample(1),
      tradePrice2                         : Sample(2),
      tradeVolume2                        : Sample(2),
      primaryListingMarketParticipantId   : Sample(1),
      consolidatedHighLowLastIndicator    : Sample(1),
      participantOpenHighLowLastIndicator : Sample(1) ]

EncodeShortTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp134(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol5
        \o message.saleCondition1
        \o message.saleConditionCategory
        \o message.tradePrice2
        \o message.tradeVolume2
        \o message.primaryListingMarketParticipantId
        \o message.consolidatedHighLowLastIndicator
        \o message.participantOpenHighLowLastIndicator

DecodeShortTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp134(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol5 == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbol5.ok THEN Fail ELSE
    LET saleCondition1 == ReadBytes(securitySymbol5.rest, 1) IN IF ~saleCondition1.ok THEN Fail ELSE
    LET saleConditionCategory == ReadBytes(saleCondition1.rest, 1) IN IF ~saleConditionCategory.ok THEN Fail ELSE
    LET tradePrice2 == ReadBytes(saleConditionCategory.rest, 2) IN IF ~tradePrice2.ok THEN Fail ELSE
    LET tradeVolume2 == ReadBytes(tradePrice2.rest, 2) IN IF ~tradeVolume2.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(tradeVolume2.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET consolidatedHighLowLastIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~consolidatedHighLowLastIndicator.ok THEN Fail ELSE
    LET participantOpenHighLowLastIndicator == ReadBytes(consolidatedHighLowLastIndicator.rest, 1) IN IF ~participantOpenHighLowLastIndicator.ok THEN Fail ELSE
    Ok([ participantId                       |-> participantId.value,
         timestamp1                          |-> timestamp1.value,
         messageId                           |-> messageId.value,
         transactionId                       |-> transactionId.value,
         participantReferenceNumber          |-> participantReferenceNumber.value,
         securitySymbol5                     |-> securitySymbol5.value,
         saleCondition1                      |-> saleCondition1.value,
         saleConditionCategory               |-> saleConditionCategory.value,
         tradePrice2                         |-> tradePrice2.value,
         tradeVolume2                        |-> tradeVolume2.value,
         primaryListingMarketParticipantId   |-> primaryListingMarketParticipantId.value,
         consolidatedHighLowLastIndicator    |-> consolidatedHighLowLastIndicator.value,
         participantOpenHighLowLastIndicator |-> participantOpenHighLowLastIndicator.value ], participantOpenHighLowLastIndicator.rest)

ZeroShortTradeMessage ==
    [ participantId                       |-> [i \in 1 .. 1 |-> 0],
      timestamp1                          |-> ZeroTimestamp134,
      messageId                           |-> [i \in 1 .. 1 |-> 0],
      transactionId                       |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber          |-> [i \in 1 .. 8 |-> 0],
      securitySymbol5                     |-> [i \in 1 .. 5 |-> 0],
      saleCondition1                      |-> [i \in 1 .. 1 |-> 0],
      saleConditionCategory               |-> [i \in 1 .. 1 |-> 0],
      tradePrice2                         |-> [i \in 1 .. 2 |-> 0],
      tradeVolume2                        |-> [i \in 1 .. 2 |-> 0],
      primaryListingMarketParticipantId   |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighLowLastIndicator    |-> [i \in 1 .. 1 |-> 0],
      participantOpenHighLowLastIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Short Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedShortTradeMessage ==
    { ZeroShortTradeMessage }
        \cup { [ZeroShortTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp134 }
        \cup { [ZeroShortTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroShortTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroShortTradeMessage EXCEPT !.securitySymbol5 = one] : one \in Sample(5) }
        \cup { [ZeroShortTradeMessage EXCEPT !.saleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.saleConditionCategory = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.tradePrice2 = one] : one \in Sample(2) }
        \cup { [ZeroShortTradeMessage EXCEPT !.tradeVolume2 = one] : one \in Sample(2) }
        \cup { [ZeroShortTradeMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.consolidatedHighLowLastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroShortTradeMessage EXCEPT !.participantOpenHighLowLastIndicator = one] : one \in Sample(1) }

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
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition47 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition47(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition47(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition47 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition47 ==
    { ZeroSaleCondition47 }
        \cup { [ZeroSaleCondition47 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition47 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition47 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition47 EXCEPT !.category4 = one] : one \in Sample(1) }

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
(* Trade Cancel Error Message: 149 bytes                                   *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ participantId                      : Sample(1),
      timestamp1                         : Timestamp135,
      messageId                          : Sample(1),
      transactionId                      : Sample(4),
      participantReferenceNumber         : Sample(8),
      securitySymbol                     : Sample(11),
      instrumentType                     : Sample(1),
      saleCondition4                     : SaleCondition47,
      tradePrice                         : Sample(8),
      tradeVolume                        : Sample(4),
      sellersSaleDays                    : Sample(1),
      stopStockIndicator                 : Sample(1),
      tradeThroughExemptIndicator        : Sample(1),
      tradeReportingFacilityId           : Sample(1),
      originalParticipantReferenceNumber : Sample(8),
      timestamp2                         : Timestamp23,
      cancelErrorAction                  : Sample(1),
      shortSaleRestrictionIndicator      : Sample(1),
      primaryListingMarketParticipantId  : Sample(1),
      financialStatusIndicator           : Sample(1),
      consolidatedPreviousClosePriceDate : Sample(4),
      consolidatedLastParticipantId      : Sample(1),
      consolidatedLastPrice              : Sample(8),
      consolidatedHighPrice              : Sample(8),
      consolidatedLowPrice               : Sample(8),
      consolidatedTotalVolume            : Sample(4),
      consolidatedTick                   : Sample(1),
      participantPreviousClosePriceDate  : Sample(4),
      participantLastPrice               : Sample(8),
      participantHighPrice               : Sample(8),
      participantLowPrice                : Sample(8),
      participantOpenPrice               : Sample(8),
      participantTotalVolume             : Sample(4),
      participantTick                    : Sample(1) ]

EncodeTradeCancelErrorMessage(message) ==
    message.participantId
        \o EncodeTimestamp135(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleCondition47(message.saleCondition4)
        \o message.tradePrice
        \o message.tradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o message.originalParticipantReferenceNumber
        \o EncodeTimestamp23(message.timestamp2)
        \o message.cancelErrorAction
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.consolidatedPreviousClosePriceDate
        \o message.consolidatedLastParticipantId
        \o message.consolidatedLastPrice
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedTotalVolume
        \o message.consolidatedTick
        \o message.participantPreviousClosePriceDate
        \o message.participantLastPrice
        \o message.participantHighPrice
        \o message.participantLowPrice
        \o message.participantOpenPrice
        \o message.participantTotalVolume
        \o message.participantTick

DecodeTradeCancelErrorMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp135(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition4 == DecodeSaleCondition47(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradePrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(tradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(tradeReportingFacilityId.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp23(originalParticipantReferenceNumber.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET cancelErrorAction == ReadBytes(timestamp2.rest, 1) IN IF ~cancelErrorAction.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(cancelErrorAction.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET consolidatedPreviousClosePriceDate == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~consolidatedPreviousClosePriceDate.ok THEN Fail ELSE
    LET consolidatedLastParticipantId == ReadBytes(consolidatedPreviousClosePriceDate.rest, 1) IN IF ~consolidatedLastParticipantId.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLastParticipantId.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedTotalVolume == ReadBytes(consolidatedLowPrice.rest, 4) IN IF ~consolidatedTotalVolume.ok THEN Fail ELSE
    LET consolidatedTick == ReadBytes(consolidatedTotalVolume.rest, 1) IN IF ~consolidatedTick.ok THEN Fail ELSE
    LET participantPreviousClosePriceDate == ReadBytes(consolidatedTick.rest, 4) IN IF ~participantPreviousClosePriceDate.ok THEN Fail ELSE
    LET participantLastPrice == ReadBytes(participantPreviousClosePriceDate.rest, 8) IN IF ~participantLastPrice.ok THEN Fail ELSE
    LET participantHighPrice == ReadBytes(participantLastPrice.rest, 8) IN IF ~participantHighPrice.ok THEN Fail ELSE
    LET participantLowPrice == ReadBytes(participantHighPrice.rest, 8) IN IF ~participantLowPrice.ok THEN Fail ELSE
    LET participantOpenPrice == ReadBytes(participantLowPrice.rest, 8) IN IF ~participantOpenPrice.ok THEN Fail ELSE
    LET participantTotalVolume == ReadBytes(participantOpenPrice.rest, 4) IN IF ~participantTotalVolume.ok THEN Fail ELSE
    LET participantTick == ReadBytes(participantTotalVolume.rest, 1) IN IF ~participantTick.ok THEN Fail ELSE
    Ok([ participantId                      |-> participantId.value,
         timestamp1                         |-> timestamp1.value,
         messageId                          |-> messageId.value,
         transactionId                      |-> transactionId.value,
         participantReferenceNumber         |-> participantReferenceNumber.value,
         securitySymbol                     |-> securitySymbol.value,
         instrumentType                     |-> instrumentType.value,
         saleCondition4                     |-> saleCondition4.value,
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
         consolidatedPreviousClosePriceDate |-> consolidatedPreviousClosePriceDate.value,
         consolidatedLastParticipantId      |-> consolidatedLastParticipantId.value,
         consolidatedLastPrice              |-> consolidatedLastPrice.value,
         consolidatedHighPrice              |-> consolidatedHighPrice.value,
         consolidatedLowPrice               |-> consolidatedLowPrice.value,
         consolidatedTotalVolume            |-> consolidatedTotalVolume.value,
         consolidatedTick                   |-> consolidatedTick.value,
         participantPreviousClosePriceDate  |-> participantPreviousClosePriceDate.value,
         participantLastPrice               |-> participantLastPrice.value,
         participantHighPrice               |-> participantHighPrice.value,
         participantLowPrice                |-> participantLowPrice.value,
         participantOpenPrice               |-> participantOpenPrice.value,
         participantTotalVolume             |-> participantTotalVolume.value,
         participantTick                    |-> participantTick.value ], participantTick.rest)

ZeroTradeCancelErrorMessage ==
    [ participantId                      |-> [i \in 1 .. 1 |-> 0],
      timestamp1                         |-> ZeroTimestamp135,
      messageId                          |-> [i \in 1 .. 1 |-> 0],
      transactionId                      |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                     |-> [i \in 1 .. 11 |-> 0],
      instrumentType                     |-> [i \in 1 .. 1 |-> 0],
      saleCondition4                     |-> ZeroSaleCondition47,
      tradePrice                         |-> [i \in 1 .. 8 |-> 0],
      tradeVolume                        |-> [i \in 1 .. 4 |-> 0],
      sellersSaleDays                    |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator                 |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator        |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId           |-> [i \in 1 .. 1 |-> 0],
      originalParticipantReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      timestamp2                         |-> ZeroTimestamp23,
      cancelErrorAction                  |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator      |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId  |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator           |-> [i \in 1 .. 1 |-> 0],
      consolidatedPreviousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      consolidatedLastParticipantId      |-> [i \in 1 .. 1 |-> 0],
      consolidatedLastPrice              |-> [i \in 1 .. 8 |-> 0],
      consolidatedHighPrice              |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice               |-> [i \in 1 .. 8 |-> 0],
      consolidatedTotalVolume            |-> [i \in 1 .. 4 |-> 0],
      consolidatedTick                   |-> [i \in 1 .. 1 |-> 0],
      participantPreviousClosePriceDate  |-> [i \in 1 .. 4 |-> 0],
      participantLastPrice               |-> [i \in 1 .. 8 |-> 0],
      participantHighPrice               |-> [i \in 1 .. 8 |-> 0],
      participantLowPrice                |-> [i \in 1 .. 8 |-> 0],
      participantOpenPrice               |-> [i \in 1 .. 8 |-> 0],
      participantTotalVolume             |-> [i \in 1 .. 4 |-> 0],
      participantTick                    |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp135 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition47 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp23 }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.cancelErrorAction = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedPreviousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedLastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedTotalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedTick = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantPreviousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantTotalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.participantTick = one] : one \in Sample(1) }

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
(* Fractional Trade Correction Message: 184 bytes                          *)
(***************************************************************************)

FractionalTradeCorrectionMessage ==
    [ participantId                          : Sample(1),
      timestamp1                             : Timestamp136,
      messageId                              : Sample(1),
      transactionId                          : Sample(4),
      participantReferenceNumber             : Sample(8),
      securitySymbol                         : Sample(11),
      instrumentType                         : Sample(1),
      correctedSaleCondition                 : Sample(4),
      correctedTradePrice                    : Sample(8),
      correctedFractionalTradeVolume         : Sample(8),
      correctedSellersSaleDays               : Sample(1),
      correctedStopStockIndicator            : Sample(1),
      correctedTradeThroughExemptIndicator   : Sample(1),
      correctedShortSaleRestrictionIndicator : Sample(1),
      tradeReportingFacilityId               : Sample(1),
      timestamp2                             : Timestamp24,
      originalParticipantReferenceNumber     : Sample(8),
      originalSaleCondition                  : Sample(4),
      originalTradePrice                     : Sample(8),
      originalFractionalTradeVolume          : Sample(8),
      originalSellersSaleDays                : Sample(1),
      originalStopStockIndicator             : Sample(1),
      originalTradeThroughExemptIndicator    : Sample(1),
      originalShortSaleRestrictionIndicator  : Sample(1),
      primaryListingMarketParticipantId      : Sample(1),
      financialStatusIndicator               : Sample(1),
      consolidatedPreviousClosePriceDate     : Sample(4),
      consolidatedLastParticipantId          : Sample(1),
      consolidatedLastPrice                  : Sample(8),
      consolidatedHighPrice                  : Sample(8),
      consolidatedLowPrice                   : Sample(8),
      consolidatedFractionalTotalVolume      : Sample(8),
      consolidatedTick                       : Sample(1),
      participantPreviousClosePriceDate      : Sample(4),
      participantLastPrice                   : Sample(8),
      participantHighPrice                   : Sample(8),
      participantLowPrice                    : Sample(8),
      participantOpenPrice                   : Sample(8),
      participantFractionalTotalVolume       : Sample(8),
      participantTick                        : Sample(1) ]

EncodeFractionalTradeCorrectionMessage(message) ==
    message.participantId
        \o EncodeTimestamp136(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o message.correctedSaleCondition
        \o message.correctedTradePrice
        \o message.correctedFractionalTradeVolume
        \o message.correctedSellersSaleDays
        \o message.correctedStopStockIndicator
        \o message.correctedTradeThroughExemptIndicator
        \o message.correctedShortSaleRestrictionIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp24(message.timestamp2)
        \o message.originalParticipantReferenceNumber
        \o message.originalSaleCondition
        \o message.originalTradePrice
        \o message.originalFractionalTradeVolume
        \o message.originalSellersSaleDays
        \o message.originalStopStockIndicator
        \o message.originalTradeThroughExemptIndicator
        \o message.originalShortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.consolidatedPreviousClosePriceDate
        \o message.consolidatedLastParticipantId
        \o message.consolidatedLastPrice
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedFractionalTotalVolume
        \o message.consolidatedTick
        \o message.participantPreviousClosePriceDate
        \o message.participantLastPrice
        \o message.participantHighPrice
        \o message.participantLowPrice
        \o message.participantOpenPrice
        \o message.participantFractionalTotalVolume
        \o message.participantTick

DecodeFractionalTradeCorrectionMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp136(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET correctedSaleCondition == ReadBytes(instrumentType.rest, 4) IN IF ~correctedSaleCondition.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedSaleCondition.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedFractionalTradeVolume == ReadBytes(correctedTradePrice.rest, 8) IN IF ~correctedFractionalTradeVolume.ok THEN Fail ELSE
    LET correctedSellersSaleDays == ReadBytes(correctedFractionalTradeVolume.rest, 1) IN IF ~correctedSellersSaleDays.ok THEN Fail ELSE
    LET correctedStopStockIndicator == ReadBytes(correctedSellersSaleDays.rest, 1) IN IF ~correctedStopStockIndicator.ok THEN Fail ELSE
    LET correctedTradeThroughExemptIndicator == ReadBytes(correctedStopStockIndicator.rest, 1) IN IF ~correctedTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET correctedShortSaleRestrictionIndicator == ReadBytes(correctedTradeThroughExemptIndicator.rest, 1) IN IF ~correctedShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(correctedShortSaleRestrictionIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp24(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
    LET originalParticipantReferenceNumber == ReadBytes(timestamp2.rest, 8) IN IF ~originalParticipantReferenceNumber.ok THEN Fail ELSE
    LET originalSaleCondition == ReadBytes(originalParticipantReferenceNumber.rest, 4) IN IF ~originalSaleCondition.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalSaleCondition.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalFractionalTradeVolume == ReadBytes(originalTradePrice.rest, 8) IN IF ~originalFractionalTradeVolume.ok THEN Fail ELSE
    LET originalSellersSaleDays == ReadBytes(originalFractionalTradeVolume.rest, 1) IN IF ~originalSellersSaleDays.ok THEN Fail ELSE
    LET originalStopStockIndicator == ReadBytes(originalSellersSaleDays.rest, 1) IN IF ~originalStopStockIndicator.ok THEN Fail ELSE
    LET originalTradeThroughExemptIndicator == ReadBytes(originalStopStockIndicator.rest, 1) IN IF ~originalTradeThroughExemptIndicator.ok THEN Fail ELSE
    LET originalShortSaleRestrictionIndicator == ReadBytes(originalTradeThroughExemptIndicator.rest, 1) IN IF ~originalShortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(originalShortSaleRestrictionIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET consolidatedPreviousClosePriceDate == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~consolidatedPreviousClosePriceDate.ok THEN Fail ELSE
    LET consolidatedLastParticipantId == ReadBytes(consolidatedPreviousClosePriceDate.rest, 1) IN IF ~consolidatedLastParticipantId.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLastParticipantId.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedFractionalTotalVolume == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedFractionalTotalVolume.ok THEN Fail ELSE
    LET consolidatedTick == ReadBytes(consolidatedFractionalTotalVolume.rest, 1) IN IF ~consolidatedTick.ok THEN Fail ELSE
    LET participantPreviousClosePriceDate == ReadBytes(consolidatedTick.rest, 4) IN IF ~participantPreviousClosePriceDate.ok THEN Fail ELSE
    LET participantLastPrice == ReadBytes(participantPreviousClosePriceDate.rest, 8) IN IF ~participantLastPrice.ok THEN Fail ELSE
    LET participantHighPrice == ReadBytes(participantLastPrice.rest, 8) IN IF ~participantHighPrice.ok THEN Fail ELSE
    LET participantLowPrice == ReadBytes(participantHighPrice.rest, 8) IN IF ~participantLowPrice.ok THEN Fail ELSE
    LET participantOpenPrice == ReadBytes(participantLowPrice.rest, 8) IN IF ~participantOpenPrice.ok THEN Fail ELSE
    LET participantFractionalTotalVolume == ReadBytes(participantOpenPrice.rest, 8) IN IF ~participantFractionalTotalVolume.ok THEN Fail ELSE
    LET participantTick == ReadBytes(participantFractionalTotalVolume.rest, 1) IN IF ~participantTick.ok THEN Fail ELSE
    Ok([ participantId                          |-> participantId.value,
         timestamp1                             |-> timestamp1.value,
         messageId                              |-> messageId.value,
         transactionId                          |-> transactionId.value,
         participantReferenceNumber             |-> participantReferenceNumber.value,
         securitySymbol                         |-> securitySymbol.value,
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
         originalParticipantReferenceNumber     |-> originalParticipantReferenceNumber.value,
         originalSaleCondition                  |-> originalSaleCondition.value,
         originalTradePrice                     |-> originalTradePrice.value,
         originalFractionalTradeVolume          |-> originalFractionalTradeVolume.value,
         originalSellersSaleDays                |-> originalSellersSaleDays.value,
         originalStopStockIndicator             |-> originalStopStockIndicator.value,
         originalTradeThroughExemptIndicator    |-> originalTradeThroughExemptIndicator.value,
         originalShortSaleRestrictionIndicator  |-> originalShortSaleRestrictionIndicator.value,
         primaryListingMarketParticipantId      |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator               |-> financialStatusIndicator.value,
         consolidatedPreviousClosePriceDate     |-> consolidatedPreviousClosePriceDate.value,
         consolidatedLastParticipantId          |-> consolidatedLastParticipantId.value,
         consolidatedLastPrice                  |-> consolidatedLastPrice.value,
         consolidatedHighPrice                  |-> consolidatedHighPrice.value,
         consolidatedLowPrice                   |-> consolidatedLowPrice.value,
         consolidatedFractionalTotalVolume      |-> consolidatedFractionalTotalVolume.value,
         consolidatedTick                       |-> consolidatedTick.value,
         participantPreviousClosePriceDate      |-> participantPreviousClosePriceDate.value,
         participantLastPrice                   |-> participantLastPrice.value,
         participantHighPrice                   |-> participantHighPrice.value,
         participantLowPrice                    |-> participantLowPrice.value,
         participantOpenPrice                   |-> participantOpenPrice.value,
         participantFractionalTotalVolume       |-> participantFractionalTotalVolume.value,
         participantTick                        |-> participantTick.value ], participantTick.rest)

ZeroFractionalTradeCorrectionMessage ==
    [ participantId                          |-> [i \in 1 .. 1 |-> 0],
      timestamp1                             |-> ZeroTimestamp136,
      messageId                              |-> [i \in 1 .. 1 |-> 0],
      transactionId                          |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber             |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                         |-> [i \in 1 .. 11 |-> 0],
      instrumentType                         |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition                 |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice                    |-> [i \in 1 .. 8 |-> 0],
      correctedFractionalTradeVolume         |-> [i \in 1 .. 8 |-> 0],
      correctedSellersSaleDays               |-> [i \in 1 .. 1 |-> 0],
      correctedStopStockIndicator            |-> [i \in 1 .. 1 |-> 0],
      correctedTradeThroughExemptIndicator   |-> [i \in 1 .. 1 |-> 0],
      correctedShortSaleRestrictionIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId               |-> [i \in 1 .. 1 |-> 0],
      timestamp2                             |-> ZeroTimestamp24,
      originalParticipantReferenceNumber     |-> [i \in 1 .. 8 |-> 0],
      originalSaleCondition                  |-> [i \in 1 .. 4 |-> 0],
      originalTradePrice                     |-> [i \in 1 .. 8 |-> 0],
      originalFractionalTradeVolume          |-> [i \in 1 .. 8 |-> 0],
      originalSellersSaleDays                |-> [i \in 1 .. 1 |-> 0],
      originalStopStockIndicator             |-> [i \in 1 .. 1 |-> 0],
      originalTradeThroughExemptIndicator    |-> [i \in 1 .. 1 |-> 0],
      originalShortSaleRestrictionIndicator  |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId      |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator               |-> [i \in 1 .. 1 |-> 0],
      consolidatedPreviousClosePriceDate     |-> [i \in 1 .. 4 |-> 0],
      consolidatedLastParticipantId          |-> [i \in 1 .. 1 |-> 0],
      consolidatedLastPrice                  |-> [i \in 1 .. 8 |-> 0],
      consolidatedHighPrice                  |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice                   |-> [i \in 1 .. 8 |-> 0],
      consolidatedFractionalTotalVolume      |-> [i \in 1 .. 8 |-> 0],
      consolidatedTick                       |-> [i \in 1 .. 1 |-> 0],
      participantPreviousClosePriceDate      |-> [i \in 1 .. 4 |-> 0],
      participantLastPrice                   |-> [i \in 1 .. 8 |-> 0],
      participantHighPrice                   |-> [i \in 1 .. 8 |-> 0],
      participantLowPrice                    |-> [i \in 1 .. 8 |-> 0],
      participantOpenPrice                   |-> [i \in 1 .. 8 |-> 0],
      participantFractionalTotalVolume       |-> [i \in 1 .. 8 |-> 0],
      participantTick                        |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCorrectionMessage ==
    { ZeroFractionalTradeCorrectionMessage }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp136 }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
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
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp24 }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalParticipantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalSaleCondition = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalFractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalSellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalStopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalTradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.originalShortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedPreviousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedLastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedFractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.consolidatedTick = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantPreviousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantFractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCorrectionMessage EXCEPT !.participantTick = one] : one \in Sample(1) }

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
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition48 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition48(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition48(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition48 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition48 ==
    { ZeroSaleCondition48 }
        \cup { [ZeroSaleCondition48 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition48 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition48 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition48 EXCEPT !.category4 = one] : one \in Sample(1) }

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
(* Fractional Long Trade Message: 72 bytes                                 *)
(***************************************************************************)

FractionalLongTradeMessage ==
    [ participantId                       : Sample(1),
      timestamp1                          : Timestamp137,
      messageId                           : Sample(1),
      transactionId                       : Sample(4),
      participantReferenceNumber          : Sample(8),
      securitySymbol                      : Sample(11),
      instrumentType                      : Sample(1),
      saleCondition4                      : SaleCondition48,
      tradePrice                          : Sample(8),
      fractionalTradeVolume               : Sample(8),
      sellersSaleDays                     : Sample(1),
      stopStockIndicator                  : Sample(1),
      tradeThroughExemptIndicator         : Sample(1),
      tradeReportingFacilityId            : Sample(1),
      timestamp2                          : Timestamp25,
      shortSaleRestrictionIndicator       : Sample(1),
      primaryListingMarketParticipantId   : Sample(1),
      financialStatusIndicator            : Sample(1),
      heldTradeIndicator                  : Sample(1),
      consolidatedHighLowLastIndicator    : Sample(1),
      participantOpenHighLowLastIndicator : Sample(1) ]

EncodeFractionalLongTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp137(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleCondition48(message.saleCondition4)
        \o message.tradePrice
        \o message.fractionalTradeVolume
        \o message.sellersSaleDays
        \o message.stopStockIndicator
        \o message.tradeThroughExemptIndicator
        \o message.tradeReportingFacilityId
        \o EncodeTimestamp25(message.timestamp2)
        \o message.shortSaleRestrictionIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.heldTradeIndicator
        \o message.consolidatedHighLowLastIndicator
        \o message.participantOpenHighLowLastIndicator

DecodeFractionalLongTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp137(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition4 == DecodeSaleCondition48(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET fractionalTradeVolume == ReadBytes(tradePrice.rest, 8) IN IF ~fractionalTradeVolume.ok THEN Fail ELSE
    LET sellersSaleDays == ReadBytes(fractionalTradeVolume.rest, 1) IN IF ~sellersSaleDays.ok THEN Fail ELSE
    LET stopStockIndicator == ReadBytes(sellersSaleDays.rest, 1) IN IF ~stopStockIndicator.ok THEN Fail ELSE
    LET tradeThroughExemptIndicator == ReadBytes(stopStockIndicator.rest, 1) IN IF ~tradeThroughExemptIndicator.ok THEN Fail ELSE
    LET tradeReportingFacilityId == ReadBytes(tradeThroughExemptIndicator.rest, 1) IN IF ~tradeReportingFacilityId.ok THEN Fail ELSE
    LET timestamp2 == DecodeTimestamp25(tradeReportingFacilityId.rest) IN IF ~timestamp2.ok THEN Fail ELSE
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
         saleCondition4                      |-> saleCondition4.value,
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
      timestamp1                          |-> ZeroTimestamp137,
      messageId                           |-> [i \in 1 .. 1 |-> 0],
      transactionId                       |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber          |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                      |-> [i \in 1 .. 11 |-> 0],
      instrumentType                      |-> [i \in 1 .. 1 |-> 0],
      saleCondition4                      |-> ZeroSaleCondition48,
      tradePrice                          |-> [i \in 1 .. 8 |-> 0],
      fractionalTradeVolume               |-> [i \in 1 .. 8 |-> 0],
      sellersSaleDays                     |-> [i \in 1 .. 1 |-> 0],
      stopStockIndicator                  |-> [i \in 1 .. 1 |-> 0],
      tradeThroughExemptIndicator         |-> [i \in 1 .. 1 |-> 0],
      tradeReportingFacilityId            |-> [i \in 1 .. 1 |-> 0],
      timestamp2                          |-> ZeroTimestamp25,
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
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp137 }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition48 }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.fractionalTradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.sellersSaleDays = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.stopStockIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradeThroughExemptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.tradeReportingFacilityId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.timestamp2 = one] : one \in CheckedTimestamp25 }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.heldTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.consolidatedHighLowLastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalLongTradeMessage EXCEPT !.participantOpenHighLowLastIndicator = one] : one \in Sample(1) }

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
(* Trading Status Message: 72 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ participantId                          : Sample(1),
      timestamp1                             : Timestamp138,
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
      limitUpLimitDownLuldIndicator          : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.participantId
        \o EncodeTimestamp138(message.timestamp1)
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
        \o message.limitUpLimitDownLuldIndicator

DecodeTradingStatusMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp138(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
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
    LET limitUpLimitDownLuldIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~limitUpLimitDownLuldIndicator.ok THEN Fail ELSE
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
         limitUpLimitDownLuldIndicator          |-> limitUpLimitDownLuldIndicator.value ], limitUpLimitDownLuldIndicator.rest)

ZeroTradingStatusMessage ==
    [ participantId                          |-> [i \in 1 .. 1 |-> 0],
      timestamp1                             |-> ZeroTimestamp138,
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
      limitUpLimitDownLuldIndicator          |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp138 }
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
        \cup { [ZeroTradingStatusMessage EXCEPT !.limitUpLimitDownLuldIndicator = one] : one \in Sample(1) }

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
(* Fractional Short Trade Message: 38 bytes                                *)
(***************************************************************************)

FractionalShortTradeMessage ==
    [ participantId                       : Sample(1),
      timestamp1                          : Timestamp139,
      messageId                           : Sample(1),
      transactionId                       : Sample(4),
      participantReferenceNumber          : Sample(8),
      securitySymbol5                     : Sample(5),
      saleCondition1                      : Sample(1),
      saleConditionCategory               : Sample(1),
      tradePrice2                         : Sample(2),
      fractionalTradeVolume4              : Sample(4),
      primaryListingMarketParticipantId   : Sample(1),
      consolidatedHighLowLastIndicator    : Sample(1),
      participantOpenHighLowLastIndicator : Sample(1) ]

EncodeFractionalShortTradeMessage(message) ==
    message.participantId
        \o EncodeTimestamp139(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol5
        \o message.saleCondition1
        \o message.saleConditionCategory
        \o message.tradePrice2
        \o message.fractionalTradeVolume4
        \o message.primaryListingMarketParticipantId
        \o message.consolidatedHighLowLastIndicator
        \o message.participantOpenHighLowLastIndicator

DecodeFractionalShortTradeMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp139(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol5 == ReadBytes(participantReferenceNumber.rest, 5) IN IF ~securitySymbol5.ok THEN Fail ELSE
    LET saleCondition1 == ReadBytes(securitySymbol5.rest, 1) IN IF ~saleCondition1.ok THEN Fail ELSE
    LET saleConditionCategory == ReadBytes(saleCondition1.rest, 1) IN IF ~saleConditionCategory.ok THEN Fail ELSE
    LET tradePrice2 == ReadBytes(saleConditionCategory.rest, 2) IN IF ~tradePrice2.ok THEN Fail ELSE
    LET fractionalTradeVolume4 == ReadBytes(tradePrice2.rest, 4) IN IF ~fractionalTradeVolume4.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(fractionalTradeVolume4.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET consolidatedHighLowLastIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~consolidatedHighLowLastIndicator.ok THEN Fail ELSE
    LET participantOpenHighLowLastIndicator == ReadBytes(consolidatedHighLowLastIndicator.rest, 1) IN IF ~participantOpenHighLowLastIndicator.ok THEN Fail ELSE
    Ok([ participantId                       |-> participantId.value,
         timestamp1                          |-> timestamp1.value,
         messageId                           |-> messageId.value,
         transactionId                       |-> transactionId.value,
         participantReferenceNumber          |-> participantReferenceNumber.value,
         securitySymbol5                     |-> securitySymbol5.value,
         saleCondition1                      |-> saleCondition1.value,
         saleConditionCategory               |-> saleConditionCategory.value,
         tradePrice2                         |-> tradePrice2.value,
         fractionalTradeVolume4              |-> fractionalTradeVolume4.value,
         primaryListingMarketParticipantId   |-> primaryListingMarketParticipantId.value,
         consolidatedHighLowLastIndicator    |-> consolidatedHighLowLastIndicator.value,
         participantOpenHighLowLastIndicator |-> participantOpenHighLowLastIndicator.value ], participantOpenHighLowLastIndicator.rest)

ZeroFractionalShortTradeMessage ==
    [ participantId                       |-> [i \in 1 .. 1 |-> 0],
      timestamp1                          |-> ZeroTimestamp139,
      messageId                           |-> [i \in 1 .. 1 |-> 0],
      transactionId                       |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber          |-> [i \in 1 .. 8 |-> 0],
      securitySymbol5                     |-> [i \in 1 .. 5 |-> 0],
      saleCondition1                      |-> [i \in 1 .. 1 |-> 0],
      saleConditionCategory               |-> [i \in 1 .. 1 |-> 0],
      tradePrice2                         |-> [i \in 1 .. 2 |-> 0],
      fractionalTradeVolume4              |-> [i \in 1 .. 4 |-> 0],
      primaryListingMarketParticipantId   |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighLowLastIndicator    |-> [i \in 1 .. 1 |-> 0],
      participantOpenHighLowLastIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Short Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalShortTradeMessage ==
    { ZeroFractionalShortTradeMessage }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp139 }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.securitySymbol5 = one] : one \in Sample(5) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.saleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.saleConditionCategory = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.tradePrice2 = one] : one \in Sample(2) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.fractionalTradeVolume4 = one] : one \in Sample(4) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.consolidatedHighLowLastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFractionalShortTradeMessage EXCEPT !.participantOpenHighLowLastIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Timestamp 1: 8 bytes                                                    *)
(***************************************************************************)

Timestamp140 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTimestamp140(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTimestamp140(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTimestamp140 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Timestamp 1 at zero, then each field in turn at the values it is checked at *)
CheckedTimestamp140 ==
    { ZeroTimestamp140 }
        \cup { [ZeroTimestamp140 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTimestamp140 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Sale Condition 4: 4 bytes                                               *)
(***************************************************************************)

SaleCondition49 ==
    [ category1 : Sample(1),
      category2 : Sample(1),
      category3 : Sample(1),
      category4 : Sample(1) ]

EncodeSaleCondition49(message) ==
    message.category1
        \o message.category2
        \o message.category3
        \o message.category4

DecodeSaleCondition49(bytes) ==
    LET category1 == ReadBytes(bytes, 1) IN IF ~category1.ok THEN Fail ELSE
    LET category2 == ReadBytes(category1.rest, 1) IN IF ~category2.ok THEN Fail ELSE
    LET category3 == ReadBytes(category2.rest, 1) IN IF ~category3.ok THEN Fail ELSE
    LET category4 == ReadBytes(category3.rest, 1) IN IF ~category4.ok THEN Fail ELSE
    Ok([ category1 |-> category1.value,
         category2 |-> category2.value,
         category3 |-> category3.value,
         category4 |-> category4.value ], category4.rest)

ZeroSaleCondition49 ==
    [ category1 |-> [i \in 1 .. 1 |-> 0],
      category2 |-> [i \in 1 .. 1 |-> 0],
      category3 |-> [i \in 1 .. 1 |-> 0],
      category4 |-> [i \in 1 .. 1 |-> 0] ]

(* Sale Condition 4 at zero, then each field in turn at the values it is checked at *)
CheckedSaleCondition49 ==
    { ZeroSaleCondition49 }
        \cup { [ZeroSaleCondition49 EXCEPT !.category1 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition49 EXCEPT !.category2 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition49 EXCEPT !.category3 = one] : one \in Sample(1) }
        \cup { [ZeroSaleCondition49 EXCEPT !.category4 = one] : one \in Sample(1) }

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
(* Fractional Trade Cancel Error Message: 161 bytes                        *)
(***************************************************************************)

FractionalTradeCancelErrorMessage ==
    [ participantId                      : Sample(1),
      timestamp1                         : Timestamp140,
      messageId                          : Sample(1),
      transactionId                      : Sample(4),
      participantReferenceNumber         : Sample(8),
      securitySymbol                     : Sample(11),
      instrumentType                     : Sample(1),
      saleCondition4                     : SaleCondition49,
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
      consolidatedPreviousClosePriceDate : Sample(4),
      consolidatedLastParticipantId      : Sample(1),
      consolidatedLastPrice              : Sample(8),
      consolidatedHighPrice              : Sample(8),
      consolidatedLowPrice               : Sample(8),
      consolidatedFractionalTotalVolume  : Sample(8),
      consolidatedTick                   : Sample(1),
      participantPreviousClosePriceDate  : Sample(4),
      participantLastPrice               : Sample(8),
      participantHighPrice               : Sample(8),
      participantLowPrice                : Sample(8),
      participantOpenPrice               : Sample(8),
      participantFractionalTotalVolume   : Sample(8),
      participantTick                    : Sample(1) ]

EncodeFractionalTradeCancelErrorMessage(message) ==
    message.participantId
        \o EncodeTimestamp140(message.timestamp1)
        \o message.messageId
        \o message.transactionId
        \o message.participantReferenceNumber
        \o message.securitySymbol
        \o message.instrumentType
        \o EncodeSaleCondition49(message.saleCondition4)
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
        \o message.consolidatedPreviousClosePriceDate
        \o message.consolidatedLastParticipantId
        \o message.consolidatedLastPrice
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedFractionalTotalVolume
        \o message.consolidatedTick
        \o message.participantPreviousClosePriceDate
        \o message.participantLastPrice
        \o message.participantHighPrice
        \o message.participantLowPrice
        \o message.participantOpenPrice
        \o message.participantFractionalTotalVolume
        \o message.participantTick

DecodeFractionalTradeCancelErrorMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET timestamp1 == DecodeTimestamp140(participantId.rest) IN IF ~timestamp1.ok THEN Fail ELSE
    LET messageId == ReadBytes(timestamp1.rest, 1) IN IF ~messageId.ok THEN Fail ELSE
    LET transactionId == ReadBytes(messageId.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET participantReferenceNumber == ReadBytes(transactionId.rest, 8) IN IF ~participantReferenceNumber.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantReferenceNumber.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET saleCondition4 == DecodeSaleCondition49(instrumentType.rest) IN IF ~saleCondition4.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(saleCondition4.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
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
    LET consolidatedPreviousClosePriceDate == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~consolidatedPreviousClosePriceDate.ok THEN Fail ELSE
    LET consolidatedLastParticipantId == ReadBytes(consolidatedPreviousClosePriceDate.rest, 1) IN IF ~consolidatedLastParticipantId.ok THEN Fail ELSE
    LET consolidatedLastPrice == ReadBytes(consolidatedLastParticipantId.rest, 8) IN IF ~consolidatedLastPrice.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(consolidatedLastPrice.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedFractionalTotalVolume == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedFractionalTotalVolume.ok THEN Fail ELSE
    LET consolidatedTick == ReadBytes(consolidatedFractionalTotalVolume.rest, 1) IN IF ~consolidatedTick.ok THEN Fail ELSE
    LET participantPreviousClosePriceDate == ReadBytes(consolidatedTick.rest, 4) IN IF ~participantPreviousClosePriceDate.ok THEN Fail ELSE
    LET participantLastPrice == ReadBytes(participantPreviousClosePriceDate.rest, 8) IN IF ~participantLastPrice.ok THEN Fail ELSE
    LET participantHighPrice == ReadBytes(participantLastPrice.rest, 8) IN IF ~participantHighPrice.ok THEN Fail ELSE
    LET participantLowPrice == ReadBytes(participantHighPrice.rest, 8) IN IF ~participantLowPrice.ok THEN Fail ELSE
    LET participantOpenPrice == ReadBytes(participantLowPrice.rest, 8) IN IF ~participantOpenPrice.ok THEN Fail ELSE
    LET participantFractionalTotalVolume == ReadBytes(participantOpenPrice.rest, 8) IN IF ~participantFractionalTotalVolume.ok THEN Fail ELSE
    LET participantTick == ReadBytes(participantFractionalTotalVolume.rest, 1) IN IF ~participantTick.ok THEN Fail ELSE
    Ok([ participantId                      |-> participantId.value,
         timestamp1                         |-> timestamp1.value,
         messageId                          |-> messageId.value,
         transactionId                      |-> transactionId.value,
         participantReferenceNumber         |-> participantReferenceNumber.value,
         securitySymbol                     |-> securitySymbol.value,
         instrumentType                     |-> instrumentType.value,
         saleCondition4                     |-> saleCondition4.value,
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
         consolidatedPreviousClosePriceDate |-> consolidatedPreviousClosePriceDate.value,
         consolidatedLastParticipantId      |-> consolidatedLastParticipantId.value,
         consolidatedLastPrice              |-> consolidatedLastPrice.value,
         consolidatedHighPrice              |-> consolidatedHighPrice.value,
         consolidatedLowPrice               |-> consolidatedLowPrice.value,
         consolidatedFractionalTotalVolume  |-> consolidatedFractionalTotalVolume.value,
         consolidatedTick                   |-> consolidatedTick.value,
         participantPreviousClosePriceDate  |-> participantPreviousClosePriceDate.value,
         participantLastPrice               |-> participantLastPrice.value,
         participantHighPrice               |-> participantHighPrice.value,
         participantLowPrice                |-> participantLowPrice.value,
         participantOpenPrice               |-> participantOpenPrice.value,
         participantFractionalTotalVolume   |-> participantFractionalTotalVolume.value,
         participantTick                    |-> participantTick.value ], participantTick.rest)

ZeroFractionalTradeCancelErrorMessage ==
    [ participantId                      |-> [i \in 1 .. 1 |-> 0],
      timestamp1                         |-> ZeroTimestamp140,
      messageId                          |-> [i \in 1 .. 1 |-> 0],
      transactionId                      |-> [i \in 1 .. 4 |-> 0],
      participantReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      securitySymbol                     |-> [i \in 1 .. 11 |-> 0],
      instrumentType                     |-> [i \in 1 .. 1 |-> 0],
      saleCondition4                     |-> ZeroSaleCondition49,
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
      consolidatedPreviousClosePriceDate |-> [i \in 1 .. 4 |-> 0],
      consolidatedLastParticipantId      |-> [i \in 1 .. 1 |-> 0],
      consolidatedLastPrice              |-> [i \in 1 .. 8 |-> 0],
      consolidatedHighPrice              |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice               |-> [i \in 1 .. 8 |-> 0],
      consolidatedFractionalTotalVolume  |-> [i \in 1 .. 8 |-> 0],
      consolidatedTick                   |-> [i \in 1 .. 1 |-> 0],
      participantPreviousClosePriceDate  |-> [i \in 1 .. 4 |-> 0],
      participantLastPrice               |-> [i \in 1 .. 8 |-> 0],
      participantHighPrice               |-> [i \in 1 .. 8 |-> 0],
      participantLowPrice                |-> [i \in 1 .. 8 |-> 0],
      participantOpenPrice               |-> [i \in 1 .. 8 |-> 0],
      participantFractionalTotalVolume   |-> [i \in 1 .. 8 |-> 0],
      participantTick                    |-> [i \in 1 .. 1 |-> 0] ]

(* Fractional Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedFractionalTradeCancelErrorMessage ==
    { ZeroFractionalTradeCancelErrorMessage }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.timestamp1 = one] : one \in CheckedTimestamp140 }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.messageId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.saleCondition4 = one] : one \in CheckedSaleCondition49 }
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
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedPreviousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedLastParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedFractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.consolidatedTick = one] : one \in Sample(1) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantPreviousClosePriceDate = one] : one \in Sample(4) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantLastPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantFractionalTotalVolume = one] : one \in Sample(8) }
        \cup { [ZeroFractionalTradeCancelErrorMessage EXCEPT !.participantTick = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message Payload, selected by Trade Message Type                   *)
(***************************************************************************)

AuctionStatusMessageCode == 65  \* "A"
TradeCorrectionMessageCode == 67  \* "C"
LongTradeMessageCode == 76  \* "L"
ShortTradeMessageCode == 84  \* "T"
TradeCancelErrorMessageCode == 88  \* "X"
FractionalTradeCorrectionMessageCode == 79  \* "O"
FractionalLongTradeMessageCode == 82  \* "R"
TradingStatusMessageCode == 83  \* "S"
FractionalShortTradeMessageCode == 72  \* "H"
FractionalTradeCancelErrorMessageCode == 69  \* "E"

TradeMessagePayload ==
    [ tag : {AuctionStatusMessageCode}, body : AuctionStatusMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {LongTradeMessageCode}, body : LongTradeMessage ]
        \cup [ tag : {ShortTradeMessageCode}, body : ShortTradeMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {FractionalTradeCorrectionMessageCode}, body : FractionalTradeCorrectionMessage ]
        \cup [ tag : {FractionalLongTradeMessageCode}, body : FractionalLongTradeMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {FractionalShortTradeMessageCode}, body : FractionalShortTradeMessage ]
        \cup [ tag : {FractionalTradeCancelErrorMessageCode}, body : FractionalTradeCancelErrorMessage ]

EncodeTradeMessagePayload(message) ==
    CASE message.tag = AuctionStatusMessageCode -> EncodeAuctionStatusMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = LongTradeMessageCode -> EncodeLongTradeMessage(message.body)
      [] message.tag = ShortTradeMessageCode -> EncodeShortTradeMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = FractionalTradeCorrectionMessageCode -> EncodeFractionalTradeCorrectionMessage(message.body)
      [] message.tag = FractionalLongTradeMessageCode -> EncodeFractionalLongTradeMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = FractionalShortTradeMessageCode -> EncodeFractionalShortTradeMessage(message.body)
      [] message.tag = FractionalTradeCancelErrorMessageCode -> EncodeFractionalTradeCancelErrorMessage(message.body)

DecodeTradeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = AuctionStatusMessageCode -> DecodeAuctionStatusMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = LongTradeMessageCode -> DecodeLongTradeMessage(bytes)
              [] tag = ShortTradeMessageCode -> DecodeShortTradeMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = FractionalTradeCorrectionMessageCode -> DecodeFractionalTradeCorrectionMessage(bytes)
              [] tag = FractionalLongTradeMessageCode -> DecodeFractionalLongTradeMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = FractionalShortTradeMessageCode -> DecodeFractionalShortTradeMessage(bytes)
              [] tag = FractionalTradeCancelErrorMessageCode -> DecodeFractionalTradeCancelErrorMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroTradeMessagePayload == [tag |-> AuctionStatusMessageCode, body |-> ZeroAuctionStatusMessage]

(* Each Trade Message Payload in turn, at the values the message it names is checked at *)
CheckedTradeMessagePayload ==
    { [tag |-> AuctionStatusMessageCode, body |-> one] : one \in CheckedAuctionStatusMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> LongTradeMessageCode, body |-> one] : one \in CheckedLongTradeMessage }
        \cup { [tag |-> ShortTradeMessageCode, body |-> one] : one \in CheckedShortTradeMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> FractionalTradeCorrectionMessageCode, body |-> one] : one \in CheckedFractionalTradeCorrectionMessage }
        \cup { [tag |-> FractionalLongTradeMessageCode, body |-> one] : one \in CheckedFractionalLongTradeMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> FractionalShortTradeMessageCode, body |-> one] : one \in CheckedFractionalShortTradeMessage }
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

(* Every Start Of End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfEndOfDaySummaryMessage ==
    \A message \in CheckedStartOfEndOfDaySummaryMessage :
        LET read == DecodeStartOfEndOfDaySummaryMessage(EncodeStartOfEndOfDaySummaryMessage(message))
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

(* Every End Of End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfEndOfDaySummaryMessage ==
    \A message \in CheckedEndOfEndOfDaySummaryMessage :
        LET read == DecodeEndOfEndOfDaySummaryMessage(EncodeEndOfEndOfDaySummaryMessage(message))
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

(* Every Start Of Start Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfStartOfDaySummaryMessage ==
    \A message \in CheckedStartOfStartOfDaySummaryMessage :
        LET read == DecodeStartOfStartOfDaySummaryMessage(EncodeStartOfStartOfDaySummaryMessage(message))
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

(* Every End Of Start Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfStartOfDaySummaryMessage ==
    \A message \in CheckedEndOfStartOfDaySummaryMessage :
        LET read == DecodeEndOfStartOfDaySummaryMessage(EncodeEndOfStartOfDaySummaryMessage(message))
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
RoundTripTimestamp16 ==
    \A message \in CheckedTimestamp16 :
        LET read == DecodeTimestamp16(EncodeTimestamp16(message))
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
RoundTripTimestamp17 ==
    \A message \in CheckedTimestamp17 :
        LET read == DecodeTimestamp17(EncodeTimestamp17(message))
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
RoundTripTimestamp18 ==
    \A message \in CheckedTimestamp18 :
        LET read == DecodeTimestamp18(EncodeTimestamp18(message))
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
RoundTripTimestamp19 ==
    \A message \in CheckedTimestamp19 :
        LET read == DecodeTimestamp19(EncodeTimestamp19(message))
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
RoundTripTimestamp110 ==
    \A message \in CheckedTimestamp110 :
        LET read == DecodeTimestamp110(EncodeTimestamp110(message))
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
RoundTripTimestamp111 ==
    \A message \in CheckedTimestamp111 :
        LET read == DecodeTimestamp111(EncodeTimestamp111(message))
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
RoundTripTimestamp112 ==
    \A message \in CheckedTimestamp112 :
        LET read == DecodeTimestamp112(EncodeTimestamp112(message))
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
RoundTripTimestamp113 ==
    \A message \in CheckedTimestamp113 :
        LET read == DecodeTimestamp113(EncodeTimestamp113(message))
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
RoundTripTimestamp114 ==
    \A message \in CheckedTimestamp114 :
        LET read == DecodeTimestamp114(EncodeTimestamp114(message))
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
RoundTripTimestamp115 ==
    \A message \in CheckedTimestamp115 :
        LET read == DecodeTimestamp115(EncodeTimestamp115(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Approximate Volume Participant decodes back to what was encoded, and leaves nothing over *)
RoundTripApproximateVolumeParticipant ==
    \A message \in CheckedApproximateVolumeParticipant :
        LET read == DecodeApproximateVolumeParticipant(EncodeApproximateVolumeParticipant(message))
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
RoundTripTimestamp116 ==
    \A message \in CheckedTimestamp116 :
        LET read == DecodeTimestamp116(EncodeTimestamp116(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participant decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipant ==
    \A message \in CheckedParticipant :
        LET read == DecodeParticipant(EncodeParticipant(message))
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
RoundTripTimestamp117 ==
    \A message \in CheckedTimestamp117 :
        LET read == DecodeTimestamp117(EncodeTimestamp117(message))
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
RoundTripTimestamp118 ==
    \A message \in CheckedTimestamp118 :
        LET read == DecodeTimestamp118(EncodeTimestamp118(message))
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
RoundTripTimestamp119 ==
    \A message \in CheckedTimestamp119 :
        LET read == DecodeTimestamp119(EncodeTimestamp119(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Prior Day Trade Date and Time decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedPriorDayTradeDateAndTime ==
    \A message \in CheckedCorrectedPriorDayTradeDateAndTime :
        LET read == DecodeCorrectedPriorDayTradeDateAndTime(EncodeCorrectedPriorDayTradeDateAndTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Prior Day Trade Date and Time decodes back to what was encoded, and leaves nothing over *)
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

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp120 ==
    \A message \in CheckedTimestamp120 :
        LET read == DecodeTimestamp120(EncodeTimestamp120(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition4 ==
    \A message \in CheckedSaleCondition4 :
        LET read == DecodeSaleCondition4(EncodeSaleCondition4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date and Time decodes back to what was encoded, and leaves nothing over *)
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

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp121 ==
    \A message \in CheckedTimestamp121 :
        LET read == DecodeTimestamp121(EncodeTimestamp121(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition42 ==
    \A message \in CheckedSaleCondition42 :
        LET read == DecodeSaleCondition42(EncodeSaleCondition42(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date and Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime2 ==
    \A message \in CheckedPriorDayTradeDateAndTime2 :
        LET read == DecodePriorDayTradeDateAndTime2(EncodePriorDayTradeDateAndTime2(message))
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
RoundTripTimestamp122 ==
    \A message \in CheckedTimestamp122 :
        LET read == DecodeTimestamp122(EncodeTimestamp122(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition43 ==
    \A message \in CheckedSaleCondition43 :
        LET read == DecodeSaleCondition43(EncodeSaleCondition43(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date and Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime3 ==
    \A message \in CheckedPriorDayTradeDateAndTime3 :
        LET read == DecodePriorDayTradeDateAndTime3(EncodePriorDayTradeDateAndTime3(message))
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
RoundTripTimestamp123 ==
    \A message \in CheckedTimestamp123 :
        LET read == DecodeTimestamp123(EncodeTimestamp123(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition44 ==
    \A message \in CheckedSaleCondition44 :
        LET read == DecodeSaleCondition44(EncodeSaleCondition44(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date and Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime4 ==
    \A message \in CheckedPriorDayTradeDateAndTime4 :
        LET read == DecodePriorDayTradeDateAndTime4(EncodePriorDayTradeDateAndTime4(message))
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
RoundTripTimestamp124 ==
    \A message \in CheckedTimestamp124 :
        LET read == DecodeTimestamp124(EncodeTimestamp124(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition45 ==
    \A message \in CheckedSaleCondition45 :
        LET read == DecodeSaleCondition45(EncodeSaleCondition45(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prior Day Trade Date and Time decodes back to what was encoded, and leaves nothing over *)
RoundTripPriorDayTradeDateAndTime5 ==
    \A message \in CheckedPriorDayTradeDateAndTime5 :
        LET read == DecodePriorDayTradeDateAndTime5(EncodePriorDayTradeDateAndTime5(message))
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
RoundTripTimestamp125 ==
    \A message \in CheckedTimestamp125 :
        LET read == DecodeTimestamp125(EncodeTimestamp125(message))
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
RoundTripTimestamp126 ==
    \A message \in CheckedTimestamp126 :
        LET read == DecodeTimestamp126(EncodeTimestamp126(message))
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
RoundTripTimestamp127 ==
    \A message \in CheckedTimestamp127 :
        LET read == DecodeTimestamp127(EncodeTimestamp127(message))
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
RoundTripTimestamp128 ==
    \A message \in CheckedTimestamp128 :
        LET read == DecodeTimestamp128(EncodeTimestamp128(message))
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
RoundTripTimestamp129 ==
    \A message \in CheckedTimestamp129 :
        LET read == DecodeTimestamp129(EncodeTimestamp129(message))
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
RoundTripTimestamp130 ==
    \A message \in CheckedTimestamp130 :
        LET read == DecodeTimestamp130(EncodeTimestamp130(message))
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
RoundTripTimestamp131 ==
    \A message \in CheckedTimestamp131 :
        LET read == DecodeTimestamp131(EncodeTimestamp131(message))
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
RoundTripTimestamp132 ==
    \A message \in CheckedTimestamp132 :
        LET read == DecodeTimestamp132(EncodeTimestamp132(message))
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

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp133 ==
    \A message \in CheckedTimestamp133 :
        LET read == DecodeTimestamp133(EncodeTimestamp133(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition46 ==
    \A message \in CheckedSaleCondition46 :
        LET read == DecodeSaleCondition46(EncodeSaleCondition46(message))
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

(* Every Short Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortTradeMessage ==
    \A message \in CheckedShortTradeMessage :
        LET read == DecodeShortTradeMessage(EncodeShortTradeMessage(message))
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

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition47 ==
    \A message \in CheckedSaleCondition47 :
        LET read == DecodeSaleCondition47(EncodeSaleCondition47(message))
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

(* Every Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorMessage ==
    \A message \in CheckedTradeCancelErrorMessage :
        LET read == DecodeTradeCancelErrorMessage(EncodeTradeCancelErrorMessage(message))
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

(* Every Timestamp 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp24 ==
    \A message \in CheckedTimestamp24 :
        LET read == DecodeTimestamp24(EncodeTimestamp24(message))
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
RoundTripTimestamp137 ==
    \A message \in CheckedTimestamp137 :
        LET read == DecodeTimestamp137(EncodeTimestamp137(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition48 ==
    \A message \in CheckedSaleCondition48 :
        LET read == DecodeSaleCondition48(EncodeSaleCondition48(message))
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

(* Every Fractional Long Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalLongTradeMessage ==
    \A message \in CheckedFractionalLongTradeMessage :
        LET read == DecodeFractionalLongTradeMessage(EncodeFractionalLongTradeMessage(message))
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

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
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

(* Every Fractional Short Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFractionalShortTradeMessage ==
    \A message \in CheckedFractionalShortTradeMessage :
        LET read == DecodeFractionalShortTradeMessage(EncodeFractionalShortTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Timestamp 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripTimestamp140 ==
    \A message \in CheckedTimestamp140 :
        LET read == DecodeTimestamp140(EncodeTimestamp140(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sale Condition 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripSaleCondition49 ==
    \A message \in CheckedSaleCondition49 :
        LET read == DecodeSaleCondition49(EncodeSaleCondition49(message))
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
