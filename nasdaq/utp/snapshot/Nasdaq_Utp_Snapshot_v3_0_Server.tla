------------------ MODULE Nasdaq_Utp_Snapshot_v3_0_Server ------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Snapshot v3.0                                                  *)
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
(* Issue Symbol Directory Message: 87 bytes                                *)
(***************************************************************************)

IssueSymbolDirectoryMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbol                      : Sample(11),
      oldSymbol                   : Sample(11),
      issueName                   : Sample(30),
      issueType                   : Sample(1),
      issueSubtype                : Sample(2),
      marketTier                  : Sample(1),
      authenticity                : Sample(1),
      shortSaleThresholdIndicator : Sample(1),
      roundLotSize                : Sample(2),
      financialStatusIndicator    : Sample(1) ]

EncodeIssueSymbolDirectoryMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbol
        \o message.oldSymbol
        \o message.issueName
        \o message.issueType
        \o message.issueSubtype
        \o message.marketTier
        \o message.authenticity
        \o message.shortSaleThresholdIndicator
        \o message.roundLotSize
        \o message.financialStatusIndicator

DecodeIssueSymbolDirectoryMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbol == ReadBytes(participantToken.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET oldSymbol == ReadBytes(symbol.rest, 11) IN IF ~oldSymbol.ok THEN Fail ELSE
    LET issueName == ReadBytes(oldSymbol.rest, 30) IN IF ~issueName.ok THEN Fail ELSE
    LET issueType == ReadBytes(issueName.rest, 1) IN IF ~issueType.ok THEN Fail ELSE
    LET issueSubtype == ReadBytes(issueType.rest, 2) IN IF ~issueSubtype.ok THEN Fail ELSE
    LET marketTier == ReadBytes(issueSubtype.rest, 1) IN IF ~marketTier.ok THEN Fail ELSE
    LET authenticity == ReadBytes(marketTier.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(shortSaleThresholdIndicator.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(roundLotSize.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbol                      |-> symbol.value,
         oldSymbol                   |-> oldSymbol.value,
         issueName                   |-> issueName.value,
         issueType                   |-> issueType.value,
         issueSubtype                |-> issueSubtype.value,
         marketTier                  |-> marketTier.value,
         authenticity                |-> authenticity.value,
         shortSaleThresholdIndicator |-> shortSaleThresholdIndicator.value,
         roundLotSize                |-> roundLotSize.value,
         financialStatusIndicator    |-> financialStatusIndicator.value ], financialStatusIndicator.rest)

ZeroIssueSymbolDirectoryMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbol                      |-> [i \in 1 .. 11 |-> 0],
      oldSymbol                   |-> [i \in 1 .. 11 |-> 0],
      issueName                   |-> [i \in 1 .. 30 |-> 0],
      issueType                   |-> [i \in 1 .. 1 |-> 0],
      issueSubtype                |-> [i \in 1 .. 2 |-> 0],
      marketTier                  |-> [i \in 1 .. 1 |-> 0],
      authenticity                |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                |-> [i \in 1 .. 2 |-> 0],
      financialStatusIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Issue Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueSymbolDirectoryMessage ==
    { ZeroIssueSymbolDirectoryMessage }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.oldSymbol = one] : one \in Sample(11) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueName = one] : one \in Sample(30) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueType = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.issueSubtype = one] : one \in Sample(2) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.marketTier = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(2) }
        \cup { [ZeroIssueSymbolDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Enhanced Issue Symbol Directory Message: 114 bytes                      *)
(***************************************************************************)

EnhancedIssueSymbolDirectoryMessage ==
    [ marketCenterOriginator                  : Sample(1),
      subMarketCenterId                       : Sample(1),
      sipTimestamp                            : Sample(8),
      timestamp1                              : Sample(8),
      participantToken                        : Sample(8),
      symbol                                  : Sample(11),
      oldSymbol                               : Sample(11),
      issueName                               : Sample(30),
      issueType                               : Sample(1),
      issueSubtype                            : Sample(2),
      marketTier                              : Sample(1),
      authenticity                            : Sample(1),
      shortSaleThresholdIndicator             : Sample(1),
      roundLotSize                            : Sample(2),
      financialStatusIndicator                : Sample(1),
      etpIndicator                            : Sample(1),
      newIssueIndicator                       : Sample(1),
      mpiTick                                 : Sample(1),
      tradingState                            : Sample(1),
      haltReason                              : Sample(6),
      regShoAction                            : Sample(1),
      consolidatedPriorDayClosePrice          : Sample(8),
      listingMarketOfficialPriorDayClosePrice : Sample(8) ]

EncodeEnhancedIssueSymbolDirectoryMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbol
        \o message.oldSymbol
        \o message.issueName
        \o message.issueType
        \o message.issueSubtype
        \o message.marketTier
        \o message.authenticity
        \o message.shortSaleThresholdIndicator
        \o message.roundLotSize
        \o message.financialStatusIndicator
        \o message.etpIndicator
        \o message.newIssueIndicator
        \o message.mpiTick
        \o message.tradingState
        \o message.haltReason
        \o message.regShoAction
        \o message.consolidatedPriorDayClosePrice
        \o message.listingMarketOfficialPriorDayClosePrice

DecodeEnhancedIssueSymbolDirectoryMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbol == ReadBytes(participantToken.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET oldSymbol == ReadBytes(symbol.rest, 11) IN IF ~oldSymbol.ok THEN Fail ELSE
    LET issueName == ReadBytes(oldSymbol.rest, 30) IN IF ~issueName.ok THEN Fail ELSE
    LET issueType == ReadBytes(issueName.rest, 1) IN IF ~issueType.ok THEN Fail ELSE
    LET issueSubtype == ReadBytes(issueType.rest, 2) IN IF ~issueSubtype.ok THEN Fail ELSE
    LET marketTier == ReadBytes(issueSubtype.rest, 1) IN IF ~marketTier.ok THEN Fail ELSE
    LET authenticity == ReadBytes(marketTier.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(shortSaleThresholdIndicator.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(roundLotSize.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET etpIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~etpIndicator.ok THEN Fail ELSE
    LET newIssueIndicator == ReadBytes(etpIndicator.rest, 1) IN IF ~newIssueIndicator.ok THEN Fail ELSE
    LET mpiTick == ReadBytes(newIssueIndicator.rest, 1) IN IF ~mpiTick.ok THEN Fail ELSE
    LET tradingState == ReadBytes(mpiTick.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET haltReason == ReadBytes(tradingState.rest, 6) IN IF ~haltReason.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(haltReason.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    LET consolidatedPriorDayClosePrice == ReadBytes(regShoAction.rest, 8) IN IF ~consolidatedPriorDayClosePrice.ok THEN Fail ELSE
    LET listingMarketOfficialPriorDayClosePrice == ReadBytes(consolidatedPriorDayClosePrice.rest, 8) IN IF ~listingMarketOfficialPriorDayClosePrice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator                  |-> marketCenterOriginator.value,
         subMarketCenterId                       |-> subMarketCenterId.value,
         sipTimestamp                            |-> sipTimestamp.value,
         timestamp1                              |-> timestamp1.value,
         participantToken                        |-> participantToken.value,
         symbol                                  |-> symbol.value,
         oldSymbol                               |-> oldSymbol.value,
         issueName                               |-> issueName.value,
         issueType                               |-> issueType.value,
         issueSubtype                            |-> issueSubtype.value,
         marketTier                              |-> marketTier.value,
         authenticity                            |-> authenticity.value,
         shortSaleThresholdIndicator             |-> shortSaleThresholdIndicator.value,
         roundLotSize                            |-> roundLotSize.value,
         financialStatusIndicator                |-> financialStatusIndicator.value,
         etpIndicator                            |-> etpIndicator.value,
         newIssueIndicator                       |-> newIssueIndicator.value,
         mpiTick                                 |-> mpiTick.value,
         tradingState                            |-> tradingState.value,
         haltReason                              |-> haltReason.value,
         regShoAction                            |-> regShoAction.value,
         consolidatedPriorDayClosePrice          |-> consolidatedPriorDayClosePrice.value,
         listingMarketOfficialPriorDayClosePrice |-> listingMarketOfficialPriorDayClosePrice.value ], listingMarketOfficialPriorDayClosePrice.rest)

ZeroEnhancedIssueSymbolDirectoryMessage ==
    [ marketCenterOriginator                  |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId                       |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                            |-> [i \in 1 .. 8 |-> 0],
      timestamp1                              |-> [i \in 1 .. 8 |-> 0],
      participantToken                        |-> [i \in 1 .. 8 |-> 0],
      symbol                                  |-> [i \in 1 .. 11 |-> 0],
      oldSymbol                               |-> [i \in 1 .. 11 |-> 0],
      issueName                               |-> [i \in 1 .. 30 |-> 0],
      issueType                               |-> [i \in 1 .. 1 |-> 0],
      issueSubtype                            |-> [i \in 1 .. 2 |-> 0],
      marketTier                              |-> [i \in 1 .. 1 |-> 0],
      authenticity                            |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator             |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                            |-> [i \in 1 .. 2 |-> 0],
      financialStatusIndicator                |-> [i \in 1 .. 1 |-> 0],
      etpIndicator                            |-> [i \in 1 .. 1 |-> 0],
      newIssueIndicator                       |-> [i \in 1 .. 1 |-> 0],
      mpiTick                                 |-> [i \in 1 .. 1 |-> 0],
      tradingState                            |-> [i \in 1 .. 1 |-> 0],
      haltReason                              |-> [i \in 1 .. 6 |-> 0],
      regShoAction                            |-> [i \in 1 .. 1 |-> 0],
      consolidatedPriorDayClosePrice          |-> [i \in 1 .. 8 |-> 0],
      listingMarketOfficialPriorDayClosePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Enhanced Issue Symbol Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedEnhancedIssueSymbolDirectoryMessage ==
    { ZeroEnhancedIssueSymbolDirectoryMessage }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.oldSymbol = one] : one \in Sample(11) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.issueName = one] : one \in Sample(30) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.issueType = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.issueSubtype = one] : one \in Sample(2) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.marketTier = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(2) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.etpIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.newIssueIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.mpiTick = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.haltReason = one] : one \in Sample(6) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.consolidatedPriorDayClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroEnhancedIssueSymbolDirectoryMessage EXCEPT !.listingMarketOfficialPriorDayClosePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 38 bytes    *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      symbol                 : Sample(11),
      regShoAction           : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbol
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbol == ReadBytes(participantToken.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(symbol.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         symbol                 |-> symbol.value,
         regShoAction           |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 11 |-> 0],
      regShoAction           |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Cross Sro Trading Action Message: 56 bytes                              *)
(***************************************************************************)

CrossSroTradingActionMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbol                      : Sample(11),
      tradingActionCode           : Sample(1),
      tradingActionSequenceNumber : Sample(4),
      actionTime                  : Sample(8),
      reasonForTheTradingAction   : Sample(6) ]

EncodeCrossSroTradingActionMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbol
        \o message.tradingActionCode
        \o message.tradingActionSequenceNumber
        \o message.actionTime
        \o message.reasonForTheTradingAction

DecodeCrossSroTradingActionMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbol == ReadBytes(participantToken.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbol.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(tradingActionCode.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET actionTime == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    LET reasonForTheTradingAction == ReadBytes(actionTime.rest, 6) IN IF ~reasonForTheTradingAction.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbol                      |-> symbol.value,
         tradingActionCode           |-> tradingActionCode.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         actionTime                  |-> actionTime.value,
         reasonForTheTradingAction   |-> reasonForTheTradingAction.value ], reasonForTheTradingAction.rest)

ZeroCrossSroTradingActionMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbol                      |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode           |-> [i \in 1 .. 1 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      actionTime                  |-> [i \in 1 .. 8 |-> 0],
      reasonForTheTradingAction   |-> [i \in 1 .. 6 |-> 0] ]

(* Cross Sro Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossSroTradingActionMessage ==
    { ZeroCrossSroTradingActionMessage }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossSroTradingActionMessage EXCEPT !.reasonForTheTradingAction = one] : one \in Sample(6) }

(***************************************************************************)
(* Market Center Trading Action Message: 47 bytes                          *)
(***************************************************************************)

MarketCenterTradingActionMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      symbol                 : Sample(11),
      tradingActionCode      : Sample(1),
      actionTime             : Sample(8),
      marketCenterIdentifier : Sample(1) ]

EncodeMarketCenterTradingActionMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbol
        \o message.tradingActionCode
        \o message.actionTime
        \o message.marketCenterIdentifier

DecodeMarketCenterTradingActionMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbol == ReadBytes(participantToken.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingActionCode == ReadBytes(symbol.rest, 1) IN IF ~tradingActionCode.ok THEN Fail ELSE
    LET actionTime == ReadBytes(tradingActionCode.rest, 8) IN IF ~actionTime.ok THEN Fail ELSE
    LET marketCenterIdentifier == ReadBytes(actionTime.rest, 1) IN IF ~marketCenterIdentifier.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         symbol                 |-> symbol.value,
         tradingActionCode      |-> tradingActionCode.value,
         actionTime             |-> actionTime.value,
         marketCenterIdentifier |-> marketCenterIdentifier.value ], marketCenterIdentifier.rest)

ZeroMarketCenterTradingActionMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 11 |-> 0],
      tradingActionCode      |-> [i \in 1 .. 1 |-> 0],
      actionTime             |-> [i \in 1 .. 8 |-> 0],
      marketCenterIdentifier |-> [i \in 1 .. 1 |-> 0] ]

(* Market Center Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketCenterTradingActionMessage ==
    { ZeroMarketCenterTradingActionMessage }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.tradingActionCode = one] : one \in Sample(1) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.actionTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketCenterTradingActionMessage EXCEPT !.marketCenterIdentifier = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Wide Circuit Breaker Decline Level Message: 50 bytes             *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      mwcbLevel1             : Sample(8),
      mwcbLevel2             : Sample(8),
      mwcbLevel3             : Sample(8) ]

EncodeMarketWideCircuitBreakerDeclineLevelMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3

DecodeMarketWideCircuitBreakerDeclineLevelMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET mwcbLevel1 == ReadBytes(participantToken.rest, 8) IN IF ~mwcbLevel1.ok THEN Fail ELSE
    LET mwcbLevel2 == ReadBytes(mwcbLevel1.rest, 8) IN IF ~mwcbLevel2.ok THEN Fail ELSE
    LET mwcbLevel3 == ReadBytes(mwcbLevel2.rest, 8) IN IF ~mwcbLevel3.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         mwcbLevel1             |-> mwcbLevel1.value,
         mwcbLevel2             |-> mwcbLevel2.value,
         mwcbLevel3             |-> mwcbLevel3.value ], mwcbLevel3.rest)

ZeroMarketWideCircuitBreakerDeclineLevelMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel1             |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel2             |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel3             |-> [i \in 1 .. 8 |-> 0] ]

(* Market Wide Circuit Breaker Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerDeclineLevelMessage ==
    { ZeroMarketWideCircuitBreakerDeclineLevelMessage }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel2 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelMessage EXCEPT !.mwcbLevel3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Limit Up Limit Down Price Band Message: 62 bytes                        *)
(***************************************************************************)

LimitUpLimitDownPriceBandMessage ==
    [ marketCenterOriginator     : Sample(1),
      subMarketCenterId          : Sample(1),
      sipTimestamp               : Sample(8),
      timestamp1                 : Sample(8),
      participantToken           : Sample(8),
      symbol                     : Sample(11),
      luldPriceBandIndicator     : Sample(1),
      luldPriceBandEffectiveTime : Sample(8),
      limitDownPrice             : Sample(8),
      limitUpPrice               : Sample(8) ]

EncodeLimitUpLimitDownPriceBandMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbol
        \o message.luldPriceBandIndicator
        \o message.luldPriceBandEffectiveTime
        \o message.limitDownPrice
        \o message.limitUpPrice

DecodeLimitUpLimitDownPriceBandMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbol == ReadBytes(participantToken.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET luldPriceBandIndicator == ReadBytes(symbol.rest, 1) IN IF ~luldPriceBandIndicator.ok THEN Fail ELSE
    LET luldPriceBandEffectiveTime == ReadBytes(luldPriceBandIndicator.rest, 8) IN IF ~luldPriceBandEffectiveTime.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(luldPriceBandEffectiveTime.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    Ok([ marketCenterOriginator     |-> marketCenterOriginator.value,
         subMarketCenterId          |-> subMarketCenterId.value,
         sipTimestamp               |-> sipTimestamp.value,
         timestamp1                 |-> timestamp1.value,
         participantToken           |-> participantToken.value,
         symbol                     |-> symbol.value,
         luldPriceBandIndicator     |-> luldPriceBandIndicator.value,
         luldPriceBandEffectiveTime |-> luldPriceBandEffectiveTime.value,
         limitDownPrice             |-> limitDownPrice.value,
         limitUpPrice               |-> limitUpPrice.value ], limitUpPrice.rest)

ZeroLimitUpLimitDownPriceBandMessage ==
    [ marketCenterOriginator     |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId          |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp               |-> [i \in 1 .. 8 |-> 0],
      timestamp1                 |-> [i \in 1 .. 8 |-> 0],
      participantToken           |-> [i \in 1 .. 8 |-> 0],
      symbol                     |-> [i \in 1 .. 11 |-> 0],
      luldPriceBandIndicator     |-> [i \in 1 .. 1 |-> 0],
      luldPriceBandEffectiveTime |-> [i \in 1 .. 8 |-> 0],
      limitDownPrice             |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice               |-> [i \in 1 .. 8 |-> 0] ]

(* Limit Up Limit Down Price Band Message at zero, then each field in turn at the values it is checked at *)
CheckedLimitUpLimitDownPriceBandMessage ==
    { ZeroLimitUpLimitDownPriceBandMessage }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldPriceBandIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.luldPriceBandEffectiveTime = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroLimitUpLimitDownPriceBandMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Collar Message: 66 bytes                                        *)
(***************************************************************************)

AuctionCollarMessage ==
    [ marketCenterOriginator      : Sample(1),
      subMarketCenterId           : Sample(1),
      sipTimestamp                : Sample(8),
      timestamp1                  : Sample(8),
      participantToken            : Sample(8),
      symbol                      : Sample(11),
      tradingActionSequenceNumber : Sample(4),
      collarReferencePrice        : Sample(8),
      collarUpPrice               : Sample(8),
      collarDownPrice             : Sample(8),
      collarExtensionIndicator    : Sample(1) ]

EncodeAuctionCollarMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.symbol
        \o message.tradingActionSequenceNumber
        \o message.collarReferencePrice
        \o message.collarUpPrice
        \o message.collarDownPrice
        \o message.collarExtensionIndicator

DecodeAuctionCollarMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET symbol == ReadBytes(participantToken.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingActionSequenceNumber == ReadBytes(symbol.rest, 4) IN IF ~tradingActionSequenceNumber.ok THEN Fail ELSE
    LET collarReferencePrice == ReadBytes(tradingActionSequenceNumber.rest, 8) IN IF ~collarReferencePrice.ok THEN Fail ELSE
    LET collarUpPrice == ReadBytes(collarReferencePrice.rest, 8) IN IF ~collarUpPrice.ok THEN Fail ELSE
    LET collarDownPrice == ReadBytes(collarUpPrice.rest, 8) IN IF ~collarDownPrice.ok THEN Fail ELSE
    LET collarExtensionIndicator == ReadBytes(collarDownPrice.rest, 1) IN IF ~collarExtensionIndicator.ok THEN Fail ELSE
    Ok([ marketCenterOriginator      |-> marketCenterOriginator.value,
         subMarketCenterId           |-> subMarketCenterId.value,
         sipTimestamp                |-> sipTimestamp.value,
         timestamp1                  |-> timestamp1.value,
         participantToken            |-> participantToken.value,
         symbol                      |-> symbol.value,
         tradingActionSequenceNumber |-> tradingActionSequenceNumber.value,
         collarReferencePrice        |-> collarReferencePrice.value,
         collarUpPrice               |-> collarUpPrice.value,
         collarDownPrice             |-> collarDownPrice.value,
         collarExtensionIndicator    |-> collarExtensionIndicator.value ], collarExtensionIndicator.rest)

ZeroAuctionCollarMessage ==
    [ marketCenterOriginator      |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId           |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                |-> [i \in 1 .. 8 |-> 0],
      timestamp1                  |-> [i \in 1 .. 8 |-> 0],
      participantToken            |-> [i \in 1 .. 8 |-> 0],
      symbol                      |-> [i \in 1 .. 11 |-> 0],
      tradingActionSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      collarReferencePrice        |-> [i \in 1 .. 8 |-> 0],
      collarUpPrice               |-> [i \in 1 .. 8 |-> 0],
      collarDownPrice             |-> [i \in 1 .. 8 |-> 0],
      collarExtensionIndicator    |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Collar Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCollarMessage ==
    { ZeroAuctionCollarMessage }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.tradingActionSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionCollarMessage EXCEPT !.collarExtensionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Sequence Message: 34 bytes                                     *)
(***************************************************************************)

SnapshotSequenceMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      sequenceNumber         : Sample(8) ]

EncodeSnapshotSequenceMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.sequenceNumber

DecodeSnapshotSequenceMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(participantToken.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         sequenceNumber         |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroSnapshotSequenceMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      sequenceNumber         |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Sequence Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotSequenceMessage ==
    { ZeroSnapshotSequenceMessage }
        \cup { [ZeroSnapshotSequenceMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotSequenceMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotSequenceMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotSequenceMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotSequenceMessage EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotSequenceMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Administrative Message Payload, selected by Administrative Message Type *)
(***************************************************************************)

IssueSymbolDirectoryMessageCode == 66  \* "B"
EnhancedIssueSymbolDirectoryMessageCode == 70  \* "F"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 86  \* "V"
CrossSroTradingActionMessageCode == 72  \* "H"
MarketCenterTradingActionMessageCode == 75  \* "K"
MarketWideCircuitBreakerDeclineLevelMessageCode == 67  \* "C"
LimitUpLimitDownPriceBandMessageCode == 80  \* "P"
AuctionCollarMessageCode == 69  \* "E"
SnapshotSequenceMessageCode == 83  \* "S"

AdministrativeMessagePayload ==
    [ tag : {IssueSymbolDirectoryMessageCode}, body : IssueSymbolDirectoryMessage ]
        \cup [ tag : {EnhancedIssueSymbolDirectoryMessageCode}, body : EnhancedIssueSymbolDirectoryMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {CrossSroTradingActionMessageCode}, body : CrossSroTradingActionMessage ]
        \cup [ tag : {MarketCenterTradingActionMessageCode}, body : MarketCenterTradingActionMessage ]
        \cup [ tag : {MarketWideCircuitBreakerDeclineLevelMessageCode}, body : MarketWideCircuitBreakerDeclineLevelMessage ]
        \cup [ tag : {LimitUpLimitDownPriceBandMessageCode}, body : LimitUpLimitDownPriceBandMessage ]
        \cup [ tag : {AuctionCollarMessageCode}, body : AuctionCollarMessage ]
        \cup [ tag : {SnapshotSequenceMessageCode}, body : SnapshotSequenceMessage ]

EncodeAdministrativeMessagePayload(message) ==
    CASE message.tag = IssueSymbolDirectoryMessageCode -> EncodeIssueSymbolDirectoryMessage(message.body)
      [] message.tag = EnhancedIssueSymbolDirectoryMessageCode -> EncodeEnhancedIssueSymbolDirectoryMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = CrossSroTradingActionMessageCode -> EncodeCrossSroTradingActionMessage(message.body)
      [] message.tag = MarketCenterTradingActionMessageCode -> EncodeMarketCenterTradingActionMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerDeclineLevelMessageCode -> EncodeMarketWideCircuitBreakerDeclineLevelMessage(message.body)
      [] message.tag = LimitUpLimitDownPriceBandMessageCode -> EncodeLimitUpLimitDownPriceBandMessage(message.body)
      [] message.tag = AuctionCollarMessageCode -> EncodeAuctionCollarMessage(message.body)
      [] message.tag = SnapshotSequenceMessageCode -> EncodeSnapshotSequenceMessage(message.body)

DecodeAdministrativeMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = IssueSymbolDirectoryMessageCode -> DecodeIssueSymbolDirectoryMessage(bytes)
              [] tag = EnhancedIssueSymbolDirectoryMessageCode -> DecodeEnhancedIssueSymbolDirectoryMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = CrossSroTradingActionMessageCode -> DecodeCrossSroTradingActionMessage(bytes)
              [] tag = MarketCenterTradingActionMessageCode -> DecodeMarketCenterTradingActionMessage(bytes)
              [] tag = MarketWideCircuitBreakerDeclineLevelMessageCode -> DecodeMarketWideCircuitBreakerDeclineLevelMessage(bytes)
              [] tag = LimitUpLimitDownPriceBandMessageCode -> DecodeLimitUpLimitDownPriceBandMessage(bytes)
              [] tag = AuctionCollarMessageCode -> DecodeAuctionCollarMessage(bytes)
              [] tag = SnapshotSequenceMessageCode -> DecodeSnapshotSequenceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdministrativeMessagePayload == [tag |-> IssueSymbolDirectoryMessageCode, body |-> ZeroIssueSymbolDirectoryMessage]

(* Each Administrative Message Payload in turn, at the values the message it names is checked at *)
CheckedAdministrativeMessagePayload ==
    { [tag |-> IssueSymbolDirectoryMessageCode, body |-> one] : one \in CheckedIssueSymbolDirectoryMessage }
        \cup { [tag |-> EnhancedIssueSymbolDirectoryMessageCode, body |-> one] : one \in CheckedEnhancedIssueSymbolDirectoryMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> CrossSroTradingActionMessageCode, body |-> one] : one \in CheckedCrossSroTradingActionMessage }
        \cup { [tag |-> MarketCenterTradingActionMessageCode, body |-> one] : one \in CheckedMarketCenterTradingActionMessage }
        \cup { [tag |-> MarketWideCircuitBreakerDeclineLevelMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerDeclineLevelMessage }
        \cup { [tag |-> LimitUpLimitDownPriceBandMessageCode, body |-> one] : one \in CheckedLimitUpLimitDownPriceBandMessage }
        \cup { [tag |-> AuctionCollarMessageCode, body |-> one] : one \in CheckedAuctionCollarMessage }
        \cup { [tag |-> SnapshotSequenceMessageCode, body |-> one] : one \in CheckedSnapshotSequenceMessage }

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
(* Start Of Day Message: 26 bytes                                          *)
(***************************************************************************)

StartOfDayMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeStartOfDayMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeStartOfDayMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroStartOfDayMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Open Message: 26 bytes                                   *)
(***************************************************************************)

MarketSessionOpenMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeMarketSessionOpenMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeMarketSessionOpenMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroMarketSessionOpenMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Market Session Open Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionOpenMessage ==
    { ZeroMarketSessionOpenMessage }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionOpenMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Session Close Message: 26 bytes                                  *)
(***************************************************************************)

MarketSessionCloseMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeMarketSessionCloseMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeMarketSessionCloseMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroMarketSessionCloseMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* Market Session Close Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSessionCloseMessage ==
    { ZeroMarketSessionCloseMessage }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketSessionCloseMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Day Message: 26 bytes                                            *)
(***************************************************************************)

EndOfDayMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeEndOfDayMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeEndOfDayMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroEndOfDayMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayMessage ==
    { ZeroEndOfDayMessage }
        \cup { [ZeroEndOfDayMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Transmissions Message: 26 bytes                                  *)
(***************************************************************************)

EndOfTransmissionsMessage ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8) ]

EncodeEndOfTransmissionsMessage(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken

DecodeEndOfTransmissionsMessage(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value ], participantToken.rest)

ZeroEndOfTransmissionsMessage ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Transmissions Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionsMessage ==
    { ZeroEndOfTransmissionsMessage }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroEndOfTransmissionsMessage EXCEPT !.participantToken = one] : one \in Sample(8) }

(***************************************************************************)
(* Control Message Payload, selected by Control Message Type               *)
(***************************************************************************)

StartOfDayMessageCode == 73  \* "I"
MarketSessionOpenMessageCode == 79  \* "O"
MarketSessionCloseMessageCode == 67  \* "C"
EndOfDayMessageCode == 74  \* "J"
EndOfTransmissionsMessageCode == 90  \* "Z"

ControlMessagePayload ==
    [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]
        \cup [ tag : {MarketSessionOpenMessageCode}, body : MarketSessionOpenMessage ]
        \cup [ tag : {MarketSessionCloseMessageCode}, body : MarketSessionCloseMessage ]
        \cup [ tag : {EndOfDayMessageCode}, body : EndOfDayMessage ]
        \cup [ tag : {EndOfTransmissionsMessageCode}, body : EndOfTransmissionsMessage ]

EncodeControlMessagePayload(message) ==
    CASE message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)
      [] message.tag = MarketSessionOpenMessageCode -> EncodeMarketSessionOpenMessage(message.body)
      [] message.tag = MarketSessionCloseMessageCode -> EncodeMarketSessionCloseMessage(message.body)
      [] message.tag = EndOfDayMessageCode -> EncodeEndOfDayMessage(message.body)
      [] message.tag = EndOfTransmissionsMessageCode -> EncodeEndOfTransmissionsMessage(message.body)

DecodeControlMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] tag = MarketSessionOpenMessageCode -> DecodeMarketSessionOpenMessage(bytes)
              [] tag = MarketSessionCloseMessageCode -> DecodeMarketSessionCloseMessage(bytes)
              [] tag = EndOfDayMessageCode -> DecodeEndOfDayMessage(bytes)
              [] tag = EndOfTransmissionsMessageCode -> DecodeEndOfTransmissionsMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroControlMessagePayload == [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]

(* Each Control Message Payload in turn, at the values the message it names is checked at *)
CheckedControlMessagePayload ==
    { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }
        \cup { [tag |-> MarketSessionOpenMessageCode, body |-> one] : one \in CheckedMarketSessionOpenMessage }
        \cup { [tag |-> MarketSessionCloseMessageCode, body |-> one] : one \in CheckedMarketSessionCloseMessage }
        \cup { [tag |-> EndOfDayMessageCode, body |-> one] : one \in CheckedEndOfDayMessage }
        \cup { [tag |-> EndOfTransmissionsMessageCode, body |-> one] : one \in CheckedEndOfTransmissionsMessage }

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
(* National Bbo Appendage Longform: 27 bytes                               *)
(***************************************************************************)

NationalBboAppendageLongform ==
    [ nbboQuoteCondition          : Sample(1),
      nationalBestBidMarketCenter : Sample(1),
      nationalBestBidPrice        : Sample(8),
      nationalBestBidSize         : Sample(4),
      nationalBestAskMarketCenter : Sample(1),
      nationalBestAskPrice        : Sample(8),
      nationalBestAskSize         : Sample(4) ]

EncodeNationalBboAppendageLongform(message) ==
    message.nbboQuoteCondition
        \o message.nationalBestBidMarketCenter
        \o message.nationalBestBidPrice
        \o message.nationalBestBidSize
        \o message.nationalBestAskMarketCenter
        \o message.nationalBestAskPrice
        \o message.nationalBestAskSize

DecodeNationalBboAppendageLongform(bytes) ==
    LET nbboQuoteCondition == ReadBytes(bytes, 1) IN IF ~nbboQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidMarketCenter == ReadBytes(nbboQuoteCondition.rest, 1) IN IF ~nationalBestBidMarketCenter.ok THEN Fail ELSE
    LET nationalBestBidPrice == ReadBytes(nationalBestBidMarketCenter.rest, 8) IN IF ~nationalBestBidPrice.ok THEN Fail ELSE
    LET nationalBestBidSize == ReadBytes(nationalBestBidPrice.rest, 4) IN IF ~nationalBestBidSize.ok THEN Fail ELSE
    LET nationalBestAskMarketCenter == ReadBytes(nationalBestBidSize.rest, 1) IN IF ~nationalBestAskMarketCenter.ok THEN Fail ELSE
    LET nationalBestAskPrice == ReadBytes(nationalBestAskMarketCenter.rest, 8) IN IF ~nationalBestAskPrice.ok THEN Fail ELSE
    LET nationalBestAskSize == ReadBytes(nationalBestAskPrice.rest, 4) IN IF ~nationalBestAskSize.ok THEN Fail ELSE
    Ok([ nbboQuoteCondition          |-> nbboQuoteCondition.value,
         nationalBestBidMarketCenter |-> nationalBestBidMarketCenter.value,
         nationalBestBidPrice        |-> nationalBestBidPrice.value,
         nationalBestBidSize         |-> nationalBestBidSize.value,
         nationalBestAskMarketCenter |-> nationalBestAskMarketCenter.value,
         nationalBestAskPrice        |-> nationalBestAskPrice.value,
         nationalBestAskSize         |-> nationalBestAskSize.value ], nationalBestAskSize.rest)

ZeroNationalBboAppendageLongform ==
    [ nbboQuoteCondition          |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPrice        |-> [i \in 1 .. 8 |-> 0],
      nationalBestBidSize         |-> [i \in 1 .. 4 |-> 0],
      nationalBestAskMarketCenter |-> [i \in 1 .. 1 |-> 0],
      nationalBestAskPrice        |-> [i \in 1 .. 8 |-> 0],
      nationalBestAskSize         |-> [i \in 1 .. 4 |-> 0] ]

(* National Bbo Appendage Longform at zero, then each field in turn at the values it is checked at *)
CheckedNationalBboAppendageLongform ==
    { ZeroNationalBboAppendageLongform }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nbboQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroNationalBboAppendageLongform EXCEPT !.nationalBestAskSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Finra Adf Mpid Appendage: 8 bytes                                       *)
(***************************************************************************)

FinraAdfMpidAppendage ==
    [ bidAdfMpid : Sample(4),
      askAdfMpid : Sample(4) ]

EncodeFinraAdfMpidAppendage(message) ==
    message.bidAdfMpid
        \o message.askAdfMpid

DecodeFinraAdfMpidAppendage(bytes) ==
    LET bidAdfMpid == ReadBytes(bytes, 4) IN IF ~bidAdfMpid.ok THEN Fail ELSE
    LET askAdfMpid == ReadBytes(bidAdfMpid.rest, 4) IN IF ~askAdfMpid.ok THEN Fail ELSE
    Ok([ bidAdfMpid |-> bidAdfMpid.value,
         askAdfMpid |-> askAdfMpid.value ], askAdfMpid.rest)

ZeroFinraAdfMpidAppendage ==
    [ bidAdfMpid |-> [i \in 1 .. 4 |-> 0],
      askAdfMpid |-> [i \in 1 .. 4 |-> 0] ]

(* Finra Adf Mpid Appendage at zero, then each field in turn at the values it is checked at *)
CheckedFinraAdfMpidAppendage ==
    { ZeroFinraAdfMpidAppendage }
        \cup { [ZeroFinraAdfMpidAppendage EXCEPT !.bidAdfMpid = one] : one \in Sample(4) }
        \cup { [ZeroFinraAdfMpidAppendage EXCEPT !.askAdfMpid = one] : one \in Sample(4) }

(***************************************************************************)
(* Bolo Appendage Mpid Form: 30 bytes                                      *)
(***************************************************************************)

BoloAppendageMpidForm ==
    [ boloBestBidMarketCenter                : Sample(1),
      boloBidPrice                           : Sample(8),
      boloBidSize                            : Sample(2),
      boloBestAskMarketCenter                : Sample(1),
      boloAskPrice                           : Sample(8),
      boloAskSize                            : Sample(2),
      boloBestBidMarketParticipantIdentifier : Sample(4),
      boloBestAskMarketParticipantIdentifier : Sample(4) ]

EncodeBoloAppendageMpidForm(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPrice
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPrice
        \o message.boloAskSize
        \o message.boloBestBidMarketParticipantIdentifier
        \o message.boloBestAskMarketParticipantIdentifier

DecodeBoloAppendageMpidForm(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPrice == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPrice.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPrice.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPrice == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPrice.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPrice.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    LET boloBestBidMarketParticipantIdentifier == ReadBytes(boloAskSize.rest, 4) IN IF ~boloBestBidMarketParticipantIdentifier.ok THEN Fail ELSE
    LET boloBestAskMarketParticipantIdentifier == ReadBytes(boloBestBidMarketParticipantIdentifier.rest, 4) IN IF ~boloBestAskMarketParticipantIdentifier.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter                |-> boloBestBidMarketCenter.value,
         boloBidPrice                           |-> boloBidPrice.value,
         boloBidSize                            |-> boloBidSize.value,
         boloBestAskMarketCenter                |-> boloBestAskMarketCenter.value,
         boloAskPrice                           |-> boloAskPrice.value,
         boloAskSize                            |-> boloAskSize.value,
         boloBestBidMarketParticipantIdentifier |-> boloBestBidMarketParticipantIdentifier.value,
         boloBestAskMarketParticipantIdentifier |-> boloBestAskMarketParticipantIdentifier.value ], boloBestAskMarketParticipantIdentifier.rest)

ZeroBoloAppendageMpidForm ==
    [ boloBestBidMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloBidPrice                           |-> [i \in 1 .. 8 |-> 0],
      boloBidSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloAskPrice                           |-> [i \in 1 .. 8 |-> 0],
      boloAskSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestBidMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0],
      boloBestAskMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0] ]

(* Bolo Appendage Mpid Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageMpidForm ==
    { ZeroBoloAppendageMpidForm }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloAskSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBestBidMarketParticipantIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroBoloAppendageMpidForm EXCEPT !.boloBestAskMarketParticipantIdentifier = one] : one \in Sample(4) }

(***************************************************************************)
(* Utp Combined Quote Message Long Form: 145 bytes                         *)
(***************************************************************************)

UtpCombinedQuoteMessageLongForm ==
    [ marketCenterOriginator         : Sample(1),
      subMarketCenterId              : Sample(1),
      sipTimestamp                   : Sample(8),
      timestamp1                     : Sample(8),
      participantToken               : Sample(8),
      finraAdfTimestamp              : Sample(8),
      symbol                         : Sample(11),
      bidPrice                       : Sample(8),
      bidSize                        : Sample(4),
      askPrice                       : Sample(8),
      askSize                        : Sample(4),
      quoteCondition                 : Sample(1),
      sipGeneratedUpdateFlag         : Sample(1),
      luldBboIndicator               : Sample(1),
      retailInterestIndicator        : Sample(1),
      nbboAppendageIndicator         : Sample(1),
      luldNationalBboIndicator       : Sample(1),
      finraAdfMpidAppendageIndicator : Sample(1),
      boloAppendageIndicator         : Sample(1),
      oddLotAttachmentType           : Sample(1),
      oddLotAttachmentCount          : Sample(2),
      nationalBboAppendageLongform   : NationalBboAppendageLongform,
      finraAdfMpidAppendage          : FinraAdfMpidAppendage,
      boloAppendageMpidForm          : BoloAppendageMpidForm ]

EncodeUtpCombinedQuoteMessageLongForm(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.finraAdfTimestamp
        \o message.symbol
        \o message.bidPrice
        \o message.bidSize
        \o message.askPrice
        \o message.askSize
        \o message.quoteCondition
        \o message.sipGeneratedUpdateFlag
        \o message.luldBboIndicator
        \o message.retailInterestIndicator
        \o message.nbboAppendageIndicator
        \o message.luldNationalBboIndicator
        \o message.finraAdfMpidAppendageIndicator
        \o message.boloAppendageIndicator
        \o message.oddLotAttachmentType
        \o message.oddLotAttachmentCount
        \o EncodeNationalBboAppendageLongform(message.nationalBboAppendageLongform)
        \o EncodeFinraAdfMpidAppendage(message.finraAdfMpidAppendage)
        \o EncodeBoloAppendageMpidForm(message.boloAppendageMpidForm)

DecodeUtpCombinedQuoteMessageLongForm(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET finraAdfTimestamp == ReadBytes(participantToken.rest, 8) IN IF ~finraAdfTimestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(finraAdfTimestamp.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(symbol.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidSize.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(askSize.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET sipGeneratedUpdateFlag == ReadBytes(quoteCondition.rest, 1) IN IF ~sipGeneratedUpdateFlag.ok THEN Fail ELSE
    LET luldBboIndicator == ReadBytes(sipGeneratedUpdateFlag.rest, 1) IN IF ~luldBboIndicator.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(luldBboIndicator.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET nbboAppendageIndicator == ReadBytes(retailInterestIndicator.rest, 1) IN IF ~nbboAppendageIndicator.ok THEN Fail ELSE
    LET luldNationalBboIndicator == ReadBytes(nbboAppendageIndicator.rest, 1) IN IF ~luldNationalBboIndicator.ok THEN Fail ELSE
    LET finraAdfMpidAppendageIndicator == ReadBytes(luldNationalBboIndicator.rest, 1) IN IF ~finraAdfMpidAppendageIndicator.ok THEN Fail ELSE
    LET boloAppendageIndicator == ReadBytes(finraAdfMpidAppendageIndicator.rest, 1) IN IF ~boloAppendageIndicator.ok THEN Fail ELSE
    LET oddLotAttachmentType == ReadBytes(boloAppendageIndicator.rest, 1) IN IF ~oddLotAttachmentType.ok THEN Fail ELSE
    LET oddLotAttachmentCount == ReadBytes(oddLotAttachmentType.rest, 2) IN IF ~oddLotAttachmentCount.ok THEN Fail ELSE
    LET nationalBboAppendageLongform == DecodeNationalBboAppendageLongform(oddLotAttachmentCount.rest) IN IF ~nationalBboAppendageLongform.ok THEN Fail ELSE
    LET finraAdfMpidAppendage == DecodeFinraAdfMpidAppendage(nationalBboAppendageLongform.rest) IN IF ~finraAdfMpidAppendage.ok THEN Fail ELSE
    LET boloAppendageMpidForm == DecodeBoloAppendageMpidForm(finraAdfMpidAppendage.rest) IN IF ~boloAppendageMpidForm.ok THEN Fail ELSE
    Ok([ marketCenterOriginator         |-> marketCenterOriginator.value,
         subMarketCenterId              |-> subMarketCenterId.value,
         sipTimestamp                   |-> sipTimestamp.value,
         timestamp1                     |-> timestamp1.value,
         participantToken               |-> participantToken.value,
         finraAdfTimestamp              |-> finraAdfTimestamp.value,
         symbol                         |-> symbol.value,
         bidPrice                       |-> bidPrice.value,
         bidSize                        |-> bidSize.value,
         askPrice                       |-> askPrice.value,
         askSize                        |-> askSize.value,
         quoteCondition                 |-> quoteCondition.value,
         sipGeneratedUpdateFlag         |-> sipGeneratedUpdateFlag.value,
         luldBboIndicator               |-> luldBboIndicator.value,
         retailInterestIndicator        |-> retailInterestIndicator.value,
         nbboAppendageIndicator         |-> nbboAppendageIndicator.value,
         luldNationalBboIndicator       |-> luldNationalBboIndicator.value,
         finraAdfMpidAppendageIndicator |-> finraAdfMpidAppendageIndicator.value,
         boloAppendageIndicator         |-> boloAppendageIndicator.value,
         oddLotAttachmentType           |-> oddLotAttachmentType.value,
         oddLotAttachmentCount          |-> oddLotAttachmentCount.value,
         nationalBboAppendageLongform   |-> nationalBboAppendageLongform.value,
         finraAdfMpidAppendage          |-> finraAdfMpidAppendage.value,
         boloAppendageMpidForm          |-> boloAppendageMpidForm.value ], boloAppendageMpidForm.rest)

ZeroUtpCombinedQuoteMessageLongForm ==
    [ marketCenterOriginator         |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId              |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      timestamp1                     |-> [i \in 1 .. 8 |-> 0],
      participantToken               |-> [i \in 1 .. 8 |-> 0],
      finraAdfTimestamp              |-> [i \in 1 .. 8 |-> 0],
      symbol                         |-> [i \in 1 .. 11 |-> 0],
      bidPrice                       |-> [i \in 1 .. 8 |-> 0],
      bidSize                        |-> [i \in 1 .. 4 |-> 0],
      askPrice                       |-> [i \in 1 .. 8 |-> 0],
      askSize                        |-> [i \in 1 .. 4 |-> 0],
      quoteCondition                 |-> [i \in 1 .. 1 |-> 0],
      sipGeneratedUpdateFlag         |-> [i \in 1 .. 1 |-> 0],
      luldBboIndicator               |-> [i \in 1 .. 1 |-> 0],
      retailInterestIndicator        |-> [i \in 1 .. 1 |-> 0],
      nbboAppendageIndicator         |-> [i \in 1 .. 1 |-> 0],
      luldNationalBboIndicator       |-> [i \in 1 .. 1 |-> 0],
      finraAdfMpidAppendageIndicator |-> [i \in 1 .. 1 |-> 0],
      boloAppendageIndicator         |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentType           |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentCount          |-> [i \in 1 .. 2 |-> 0],
      nationalBboAppendageLongform   |-> ZeroNationalBboAppendageLongform,
      finraAdfMpidAppendage          |-> ZeroFinraAdfMpidAppendage,
      boloAppendageMpidForm          |-> ZeroBoloAppendageMpidForm ]

(* Utp Combined Quote Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedUtpCombinedQuoteMessageLongForm ==
    { ZeroUtpCombinedQuoteMessageLongForm }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.finraAdfTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.sipGeneratedUpdateFlag = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.luldBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.nbboAppendageIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.luldNationalBboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.finraAdfMpidAppendageIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.boloAppendageIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.oddLotAttachmentType = one] : one \in Sample(1) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.oddLotAttachmentCount = one] : one \in Sample(2) }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.nationalBboAppendageLongform = one] : one \in CheckedNationalBboAppendageLongform }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.finraAdfMpidAppendage = one] : one \in CheckedFinraAdfMpidAppendage }
        \cup { [ZeroUtpCombinedQuoteMessageLongForm EXCEPT !.boloAppendageMpidForm = one] : one \in CheckedBoloAppendageMpidForm }

(***************************************************************************)
(* Bolo Appendage Mpid Form: 30 bytes                                      *)
(***************************************************************************)

BoloAppendageMpidForm2 ==
    [ boloBestBidMarketCenter                : Sample(1),
      boloBidPrice                           : Sample(8),
      boloBidSize                            : Sample(2),
      boloBestAskMarketCenter                : Sample(1),
      boloAskPrice                           : Sample(8),
      boloAskSize                            : Sample(2),
      boloBestBidMarketParticipantIdentifier : Sample(4),
      boloBestAskMarketParticipantIdentifier : Sample(4) ]

EncodeBoloAppendageMpidForm2(message) ==
    message.boloBestBidMarketCenter
        \o message.boloBidPrice
        \o message.boloBidSize
        \o message.boloBestAskMarketCenter
        \o message.boloAskPrice
        \o message.boloAskSize
        \o message.boloBestBidMarketParticipantIdentifier
        \o message.boloBestAskMarketParticipantIdentifier

DecodeBoloAppendageMpidForm2(bytes) ==
    LET boloBestBidMarketCenter == ReadBytes(bytes, 1) IN IF ~boloBestBidMarketCenter.ok THEN Fail ELSE
    LET boloBidPrice == ReadBytes(boloBestBidMarketCenter.rest, 8) IN IF ~boloBidPrice.ok THEN Fail ELSE
    LET boloBidSize == ReadBytes(boloBidPrice.rest, 2) IN IF ~boloBidSize.ok THEN Fail ELSE
    LET boloBestAskMarketCenter == ReadBytes(boloBidSize.rest, 1) IN IF ~boloBestAskMarketCenter.ok THEN Fail ELSE
    LET boloAskPrice == ReadBytes(boloBestAskMarketCenter.rest, 8) IN IF ~boloAskPrice.ok THEN Fail ELSE
    LET boloAskSize == ReadBytes(boloAskPrice.rest, 2) IN IF ~boloAskSize.ok THEN Fail ELSE
    LET boloBestBidMarketParticipantIdentifier == ReadBytes(boloAskSize.rest, 4) IN IF ~boloBestBidMarketParticipantIdentifier.ok THEN Fail ELSE
    LET boloBestAskMarketParticipantIdentifier == ReadBytes(boloBestBidMarketParticipantIdentifier.rest, 4) IN IF ~boloBestAskMarketParticipantIdentifier.ok THEN Fail ELSE
    Ok([ boloBestBidMarketCenter                |-> boloBestBidMarketCenter.value,
         boloBidPrice                           |-> boloBidPrice.value,
         boloBidSize                            |-> boloBidSize.value,
         boloBestAskMarketCenter                |-> boloBestAskMarketCenter.value,
         boloAskPrice                           |-> boloAskPrice.value,
         boloAskSize                            |-> boloAskSize.value,
         boloBestBidMarketParticipantIdentifier |-> boloBestBidMarketParticipantIdentifier.value,
         boloBestAskMarketParticipantIdentifier |-> boloBestAskMarketParticipantIdentifier.value ], boloBestAskMarketParticipantIdentifier.rest)

ZeroBoloAppendageMpidForm2 ==
    [ boloBestBidMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloBidPrice                           |-> [i \in 1 .. 8 |-> 0],
      boloBidSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestAskMarketCenter                |-> [i \in 1 .. 1 |-> 0],
      boloAskPrice                           |-> [i \in 1 .. 8 |-> 0],
      boloAskSize                            |-> [i \in 1 .. 2 |-> 0],
      boloBestBidMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0],
      boloBestAskMarketParticipantIdentifier |-> [i \in 1 .. 4 |-> 0] ]

(* Bolo Appendage Mpid Form at zero, then each field in turn at the values it is checked at *)
CheckedBoloAppendageMpidForm2 ==
    { ZeroBoloAppendageMpidForm2 }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBestBidMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBidSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBestAskMarketCenter = one] : one \in Sample(1) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloAskSize = one] : one \in Sample(2) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBestBidMarketParticipantIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroBoloAppendageMpidForm2 EXCEPT !.boloBestAskMarketParticipantIdentifier = one] : one \in Sample(4) }

(***************************************************************************)
(* Odd Lot Quote Message Long Form: 80 bytes                               *)
(***************************************************************************)

OddLotQuoteMessageLongForm ==
    [ marketCenterOriginator : Sample(1),
      subMarketCenterId      : Sample(1),
      sipTimestamp           : Sample(8),
      timestamp1             : Sample(8),
      participantToken       : Sample(8),
      adfTimestamp           : Sample(8),
      symbol                 : Sample(11),
      sipGeneratedUpdateFlag : Sample(1),
      boloAppendageIndicator : Sample(1),
      oddLotAttachmentType   : Sample(1),
      oddLotAttachmentCount  : Sample(2),
      boloAppendageMpidForm  : BoloAppendageMpidForm2 ]

EncodeOddLotQuoteMessageLongForm(message) ==
    message.marketCenterOriginator
        \o message.subMarketCenterId
        \o message.sipTimestamp
        \o message.timestamp1
        \o message.participantToken
        \o message.adfTimestamp
        \o message.symbol
        \o message.sipGeneratedUpdateFlag
        \o message.boloAppendageIndicator
        \o message.oddLotAttachmentType
        \o message.oddLotAttachmentCount
        \o EncodeBoloAppendageMpidForm2(message.boloAppendageMpidForm)

DecodeOddLotQuoteMessageLongForm(bytes) ==
    LET marketCenterOriginator == ReadBytes(bytes, 1) IN IF ~marketCenterOriginator.ok THEN Fail ELSE
    LET subMarketCenterId == ReadBytes(marketCenterOriginator.rest, 1) IN IF ~subMarketCenterId.ok THEN Fail ELSE
    LET sipTimestamp == ReadBytes(subMarketCenterId.rest, 8) IN IF ~sipTimestamp.ok THEN Fail ELSE
    LET timestamp1 == ReadBytes(sipTimestamp.rest, 8) IN IF ~timestamp1.ok THEN Fail ELSE
    LET participantToken == ReadBytes(timestamp1.rest, 8) IN IF ~participantToken.ok THEN Fail ELSE
    LET adfTimestamp == ReadBytes(participantToken.rest, 8) IN IF ~adfTimestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(adfTimestamp.rest, 11) IN IF ~symbol.ok THEN Fail ELSE
    LET sipGeneratedUpdateFlag == ReadBytes(symbol.rest, 1) IN IF ~sipGeneratedUpdateFlag.ok THEN Fail ELSE
    LET boloAppendageIndicator == ReadBytes(sipGeneratedUpdateFlag.rest, 1) IN IF ~boloAppendageIndicator.ok THEN Fail ELSE
    LET oddLotAttachmentType == ReadBytes(boloAppendageIndicator.rest, 1) IN IF ~oddLotAttachmentType.ok THEN Fail ELSE
    LET oddLotAttachmentCount == ReadBytes(oddLotAttachmentType.rest, 2) IN IF ~oddLotAttachmentCount.ok THEN Fail ELSE
    LET boloAppendageMpidForm == DecodeBoloAppendageMpidForm2(oddLotAttachmentCount.rest) IN IF ~boloAppendageMpidForm.ok THEN Fail ELSE
    Ok([ marketCenterOriginator |-> marketCenterOriginator.value,
         subMarketCenterId      |-> subMarketCenterId.value,
         sipTimestamp           |-> sipTimestamp.value,
         timestamp1             |-> timestamp1.value,
         participantToken       |-> participantToken.value,
         adfTimestamp           |-> adfTimestamp.value,
         symbol                 |-> symbol.value,
         sipGeneratedUpdateFlag |-> sipGeneratedUpdateFlag.value,
         boloAppendageIndicator |-> boloAppendageIndicator.value,
         oddLotAttachmentType   |-> oddLotAttachmentType.value,
         oddLotAttachmentCount  |-> oddLotAttachmentCount.value,
         boloAppendageMpidForm  |-> boloAppendageMpidForm.value ], boloAppendageMpidForm.rest)

ZeroOddLotQuoteMessageLongForm ==
    [ marketCenterOriginator |-> [i \in 1 .. 1 |-> 0],
      subMarketCenterId      |-> [i \in 1 .. 1 |-> 0],
      sipTimestamp           |-> [i \in 1 .. 8 |-> 0],
      timestamp1             |-> [i \in 1 .. 8 |-> 0],
      participantToken       |-> [i \in 1 .. 8 |-> 0],
      adfTimestamp           |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 11 |-> 0],
      sipGeneratedUpdateFlag |-> [i \in 1 .. 1 |-> 0],
      boloAppendageIndicator |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentType   |-> [i \in 1 .. 1 |-> 0],
      oddLotAttachmentCount  |-> [i \in 1 .. 2 |-> 0],
      boloAppendageMpidForm  |-> ZeroBoloAppendageMpidForm2 ]

(* Odd Lot Quote Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedOddLotQuoteMessageLongForm ==
    { ZeroOddLotQuoteMessageLongForm }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.marketCenterOriginator = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.subMarketCenterId = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.sipTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.timestamp1 = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.participantToken = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.adfTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.symbol = one] : one \in Sample(11) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.sipGeneratedUpdateFlag = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.boloAppendageIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.oddLotAttachmentType = one] : one \in Sample(1) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.oddLotAttachmentCount = one] : one \in Sample(2) }
        \cup { [ZeroOddLotQuoteMessageLongForm EXCEPT !.boloAppendageMpidForm = one] : one \in CheckedBoloAppendageMpidForm2 }

(***************************************************************************)
(* Quote Message Payload, selected by Quote Message Type                   *)
(***************************************************************************)

UtpCombinedQuoteMessageLongFormCode == 68  \* "D"
OddLotQuoteMessageLongFormCode == 66  \* "B"

QuoteMessagePayload ==
    [ tag : {UtpCombinedQuoteMessageLongFormCode}, body : UtpCombinedQuoteMessageLongForm ]
        \cup [ tag : {OddLotQuoteMessageLongFormCode}, body : OddLotQuoteMessageLongForm ]

EncodeQuoteMessagePayload(message) ==
    CASE message.tag = UtpCombinedQuoteMessageLongFormCode -> EncodeUtpCombinedQuoteMessageLongForm(message.body)
      [] message.tag = OddLotQuoteMessageLongFormCode -> EncodeOddLotQuoteMessageLongForm(message.body)

DecodeQuoteMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = UtpCombinedQuoteMessageLongFormCode -> DecodeUtpCombinedQuoteMessageLongForm(bytes)
              [] tag = OddLotQuoteMessageLongFormCode -> DecodeOddLotQuoteMessageLongForm(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroQuoteMessagePayload == [tag |-> UtpCombinedQuoteMessageLongFormCode, body |-> ZeroUtpCombinedQuoteMessageLongForm]

(* Each Quote Message Payload in turn, at the values the message it names is checked at *)
CheckedQuoteMessagePayload ==
    { [tag |-> UtpCombinedQuoteMessageLongFormCode, body |-> one] : one \in CheckedUtpCombinedQuoteMessageLongForm }
        \cup { [tag |-> OddLotQuoteMessageLongFormCode, body |-> one] : one \in CheckedOddLotQuoteMessageLongForm }

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
QuoteMessageCode == 81  \* "Q"

CategoryPayload ==
    [ tag : {AdministrativeMessageCode}, body : AdministrativeMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]
        \cup [ tag : {QuoteMessageCode}, body : QuoteMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = AdministrativeMessageCode -> EncodeAdministrativeMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)
      [] message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = AdministrativeMessageCode -> DecodeAdministrativeMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCategoryPayload == [tag |-> AdministrativeMessageCode, body |-> ZeroAdministrativeMessage]

(* Each Category Payload in turn, at the values the message it names is checked at *)
CheckedCategoryPayload ==
    { [tag |-> AdministrativeMessageCode, body |-> one] : one \in CheckedAdministrativeMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }
        \cup { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ version         : Sample(1),
      categoryPayload : CategoryPayload ]

EncodeSequencedDataPacket(message) ==
    message.version
        \o EncodeUIntBE(message.categoryPayload.tag, 1)
        \o EncodeCategoryPayload(message.categoryPayload)

DecodeSequencedDataPacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET messageCategory == ReadUIntBE(version.rest, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET categoryPayload == DecodeCategoryPayload(messageCategory.value, messageCategory.rest) IN IF ~categoryPayload.ok THEN Fail ELSE
    Ok([ version         |-> version.value,
         categoryPayload |-> categoryPayload.value ], categoryPayload.rest)

ZeroSequencedDataPacket ==
    [ version         |-> [i \in 1 .. 1 |-> 0],
      categoryPayload |-> ZeroCategoryPayload ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.categoryPayload = one] : one \in CheckedCategoryPayload }

(***************************************************************************)
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ debugText : Sample(1) ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == ReadBytes(bytes, 1) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Server Tcp Payload, selected by Server Packet Type                      *)
(***************************************************************************)

SequencedDataPacketCode == 83  \* "S"
DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
ServerHeartbeatPacketCode == 72  \* "H"
EndOfSessionPacketCode == 90  \* "Z"

ServerTcpPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {ServerHeartbeatPacketCode}, body : {0} ]
        \cup [ tag : {EndOfSessionPacketCode}, body : {0} ]

EncodeServerTcpPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = ServerHeartbeatPacketCode -> << >>
      [] message.tag = EndOfSessionPacketCode -> << >>

DecodeServerTcpPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = ServerHeartbeatPacketCode -> Ok(0, bytes)
              [] tag = EndOfSessionPacketCode -> Ok(0, bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerTcpPayload == [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]

(* Each Server Tcp Payload in turn, at the values the message it names is checked at *)
CheckedServerTcpPayload ==
    { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> ServerHeartbeatPacketCode, body |-> 0] }
        \cup { [tag |-> EndOfSessionPacketCode, body |-> 0] }

(***************************************************************************)
(* Server Packet, framed by Packet Length                                  *)
(***************************************************************************)

ServerPacket ==
    [ serverTcpPayload : ServerTcpPayload ]

EncodeServerPacketBody(message) ==
    EncodeUIntBE(message.serverTcpPayload.tag, 1)
        \o EncodeServerTcpPayload(message.serverTcpPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerPacket(message) ==
    LET body == EncodeServerPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverTcpPayload == DecodeServerTcpPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverTcpPayload.ok THEN Fail ELSE
    Ok([ serverTcpPayload |-> serverTcpPayload.value ], serverTcpPayload.rest)

DecodeServerPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerPacket ==
    [ serverTcpPayload |-> ZeroServerTcpPayload ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverTcpPayload = one] : one \in CheckedServerTcpPayload }

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

(* Every Issue Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueSymbolDirectoryMessage ==
    \A message \in CheckedIssueSymbolDirectoryMessage :
        LET read == DecodeIssueSymbolDirectoryMessage(EncodeIssueSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enhanced Issue Symbol Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEnhancedIssueSymbolDirectoryMessage ==
    \A message \in CheckedEnhancedIssueSymbolDirectoryMessage :
        LET read == DecodeEnhancedIssueSymbolDirectoryMessage(EncodeEnhancedIssueSymbolDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reg Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Sro Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossSroTradingActionMessage ==
    \A message \in CheckedCrossSroTradingActionMessage :
        LET read == DecodeCrossSroTradingActionMessage(EncodeCrossSroTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Center Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketCenterTradingActionMessage ==
    \A message \in CheckedMarketCenterTradingActionMessage :
        LET read == DecodeMarketCenterTradingActionMessage(EncodeMarketCenterTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Decline Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerDeclineLevelMessage ==
    \A message \in CheckedMarketWideCircuitBreakerDeclineLevelMessage :
        LET read == DecodeMarketWideCircuitBreakerDeclineLevelMessage(EncodeMarketWideCircuitBreakerDeclineLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Limit Up Limit Down Price Band Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitUpLimitDownPriceBandMessage ==
    \A message \in CheckedLimitUpLimitDownPriceBandMessage :
        LET read == DecodeLimitUpLimitDownPriceBandMessage(EncodeLimitUpLimitDownPriceBandMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Collar Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionCollarMessage ==
    \A message \in CheckedAuctionCollarMessage :
        LET read == DecodeAuctionCollarMessage(EncodeAuctionCollarMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Sequence Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotSequenceMessage ==
    \A message \in CheckedSnapshotSequenceMessage :
        LET read == DecodeSnapshotSequenceMessage(EncodeSnapshotSequenceMessage(message))
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

(* Every Start Of Day Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfDayMessage ==
    \A message \in CheckedStartOfDayMessage :
        LET read == DecodeStartOfDayMessage(EncodeStartOfDayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Session Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionOpenMessage ==
    \A message \in CheckedMarketSessionOpenMessage :
        LET read == DecodeMarketSessionOpenMessage(EncodeMarketSessionOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Session Close Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSessionCloseMessage ==
    \A message \in CheckedMarketSessionCloseMessage :
        LET read == DecodeMarketSessionCloseMessage(EncodeMarketSessionCloseMessage(message))
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

(* Every End Of Transmissions Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmissionsMessage ==
    \A message \in CheckedEndOfTransmissionsMessage :
        LET read == DecodeEndOfTransmissionsMessage(EncodeEndOfTransmissionsMessage(message))
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

(* Every National Bbo Appendage Longform decodes back to what was encoded, and leaves nothing over *)
RoundTripNationalBboAppendageLongform ==
    \A message \in CheckedNationalBboAppendageLongform :
        LET read == DecodeNationalBboAppendageLongform(EncodeNationalBboAppendageLongform(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Adf Mpid Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraAdfMpidAppendage ==
    \A message \in CheckedFinraAdfMpidAppendage :
        LET read == DecodeFinraAdfMpidAppendage(EncodeFinraAdfMpidAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Mpid Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageMpidForm ==
    \A message \in CheckedBoloAppendageMpidForm :
        LET read == DecodeBoloAppendageMpidForm(EncodeBoloAppendageMpidForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Utp Combined Quote Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripUtpCombinedQuoteMessageLongForm ==
    \A message \in CheckedUtpCombinedQuoteMessageLongForm :
        LET read == DecodeUtpCombinedQuoteMessageLongForm(EncodeUtpCombinedQuoteMessageLongForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bolo Appendage Mpid Form decodes back to what was encoded, and leaves nothing over *)
RoundTripBoloAppendageMpidForm2 ==
    \A message \in CheckedBoloAppendageMpidForm2 :
        LET read == DecodeBoloAppendageMpidForm2(EncodeBoloAppendageMpidForm2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Odd Lot Quote Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripOddLotQuoteMessageLongForm ==
    \A message \in CheckedOddLotQuoteMessageLongForm :
        LET read == DecodeOddLotQuoteMessageLongForm(EncodeOddLotQuoteMessageLongForm(message))
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

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
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

(* A Server Tcp Payload is selected by the Server Packet Type it is written under *)
SelectsServerTcpPayload ==
    \A message \in CheckedServerTcpPayload :
        LET read == DecodeServerTcpPayload(message.tag, EncodeServerTcpPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerPacket ==
    \A message \in CheckedServerPacket :
        LET bytes == EncodeServerPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
