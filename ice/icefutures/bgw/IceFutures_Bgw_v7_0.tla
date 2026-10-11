------------------------ MODULE IceFutures_Bgw_v7_0 ------------------------
(***************************************************************************)
(* Intercontinental Exchange Binary Order Gateway v7.0                     *)
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
(* Note: Header Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Order Modification Flags is a bit field set, checked as its 1     *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Trade Flags is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
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
(* Framing Header: 4 bytes                                                 *)
(***************************************************************************)

FramingHeader ==
    [ messageLength : Sample(2),
      encodingType  : Sample(2) ]

EncodeFramingHeader(message) ==
    message.messageLength
        \o message.encodingType

DecodeFramingHeader(bytes) ==
    LET messageLength == ReadBytes(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET encodingType == ReadBytes(messageLength.rest, 2) IN IF ~encodingType.ok THEN Fail ELSE
    Ok([ messageLength |-> messageLength.value,
         encodingType  |-> encodingType.value ], encodingType.rest)

ZeroFramingHeader ==
    [ messageLength |-> [i \in 1 .. 2 |-> 0],
      encodingType  |-> [i \in 1 .. 2 |-> 0] ]

(* Framing Header at zero, then each field in turn at the values it is checked at *)
CheckedFramingHeader ==
    { ZeroFramingHeader }
        \cup { [ZeroFramingHeader EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroFramingHeader EXCEPT !.encodingType = one] : one \in Sample(2) }

(***************************************************************************)
(* Simple Open Framing Header Message: 4 bytes                             *)
(***************************************************************************)

SimpleOpenFramingHeaderMessage ==
    [ framingHeader : FramingHeader ]

EncodeSimpleOpenFramingHeaderMessage(message) ==
    EncodeFramingHeader(message.framingHeader)

DecodeSimpleOpenFramingHeaderMessage(bytes) ==
    LET framingHeader == DecodeFramingHeader(bytes) IN IF ~framingHeader.ok THEN Fail ELSE
    Ok([ framingHeader |-> framingHeader.value ], framingHeader.rest)

ZeroSimpleOpenFramingHeaderMessage ==
    [ framingHeader |-> ZeroFramingHeader ]

(* Simple Open Framing Header Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleOpenFramingHeaderMessage ==
    { ZeroSimpleOpenFramingHeaderMessage }
        \cup { [ZeroSimpleOpenFramingHeaderMessage EXCEPT !.framingHeader = one] : one \in CheckedFramingHeader }

(***************************************************************************)
(* Logon Request Message: 236 bytes                                        *)
(***************************************************************************)

LogonRequestMessage ==
    [ userId             : Sample(20),
      clientId           : Sample(4),
      heartBeatInterval  : Sample(2),
      applicationName    : Sample(30),
      applicationVersion : Sample(50),
      applicationVendor  : Sample(30),
      rawData            : Sample(50),
      ipSessionToken     : Sample(50) ]

EncodeLogonRequestMessage(message) ==
    message.userId
        \o message.clientId
        \o message.heartBeatInterval
        \o message.applicationName
        \o message.applicationVersion
        \o message.applicationVendor
        \o message.rawData
        \o message.ipSessionToken

DecodeLogonRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET clientId == ReadBytes(userId.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET heartBeatInterval == ReadBytes(clientId.rest, 2) IN IF ~heartBeatInterval.ok THEN Fail ELSE
    LET applicationName == ReadBytes(heartBeatInterval.rest, 30) IN IF ~applicationName.ok THEN Fail ELSE
    LET applicationVersion == ReadBytes(applicationName.rest, 50) IN IF ~applicationVersion.ok THEN Fail ELSE
    LET applicationVendor == ReadBytes(applicationVersion.rest, 30) IN IF ~applicationVendor.ok THEN Fail ELSE
    LET rawData == ReadBytes(applicationVendor.rest, 50) IN IF ~rawData.ok THEN Fail ELSE
    LET ipSessionToken == ReadBytes(rawData.rest, 50) IN IF ~ipSessionToken.ok THEN Fail ELSE
    Ok([ userId             |-> userId.value,
         clientId           |-> clientId.value,
         heartBeatInterval  |-> heartBeatInterval.value,
         applicationName    |-> applicationName.value,
         applicationVersion |-> applicationVersion.value,
         applicationVendor  |-> applicationVendor.value,
         rawData            |-> rawData.value,
         ipSessionToken     |-> ipSessionToken.value ], ipSessionToken.rest)

ZeroLogonRequestMessage ==
    [ userId             |-> [i \in 1 .. 20 |-> 0],
      clientId           |-> [i \in 1 .. 4 |-> 0],
      heartBeatInterval  |-> [i \in 1 .. 2 |-> 0],
      applicationName    |-> [i \in 1 .. 30 |-> 0],
      applicationVersion |-> [i \in 1 .. 50 |-> 0],
      applicationVendor  |-> [i \in 1 .. 30 |-> 0],
      rawData            |-> [i \in 1 .. 50 |-> 0],
      ipSessionToken     |-> [i \in 1 .. 50 |-> 0] ]

(* Logon Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonRequestMessage ==
    { ZeroLogonRequestMessage }
        \cup { [ZeroLogonRequestMessage EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.heartBeatInterval = one] : one \in Sample(2) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.applicationName = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.applicationVersion = one] : one \in Sample(50) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.applicationVendor = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.rawData = one] : one \in Sample(50) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.ipSessionToken = one] : one \in Sample(50) }

(***************************************************************************)
(* Logon Report Message: 127 bytes                                         *)
(***************************************************************************)

LogonReportMessage ==
    [ userId            : Sample(20),
      heartBeatInterval : Sample(2),
      severityLevel     : Sample(1),
      exchangeCode      : Sample(4),
      text              : Sample(100) ]

EncodeLogonReportMessage(message) ==
    message.userId
        \o message.heartBeatInterval
        \o message.severityLevel
        \o message.exchangeCode
        \o message.text

DecodeLogonReportMessage(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET heartBeatInterval == ReadBytes(userId.rest, 2) IN IF ~heartBeatInterval.ok THEN Fail ELSE
    LET severityLevel == ReadBytes(heartBeatInterval.rest, 1) IN IF ~severityLevel.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(severityLevel.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ userId            |-> userId.value,
         heartBeatInterval |-> heartBeatInterval.value,
         severityLevel     |-> severityLevel.value,
         exchangeCode      |-> exchangeCode.value,
         text              |-> text.value ], text.rest)

ZeroLogonReportMessage ==
    [ userId            |-> [i \in 1 .. 20 |-> 0],
      heartBeatInterval |-> [i \in 1 .. 2 |-> 0],
      severityLevel     |-> [i \in 1 .. 1 |-> 0],
      exchangeCode      |-> [i \in 1 .. 4 |-> 0],
      text              |-> [i \in 1 .. 100 |-> 0] ]

(* Logon Report Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonReportMessage ==
    { ZeroLogonReportMessage }
        \cup { [ZeroLogonReportMessage EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogonReportMessage EXCEPT !.heartBeatInterval = one] : one \in Sample(2) }
        \cup { [ZeroLogonReportMessage EXCEPT !.severityLevel = one] : one \in Sample(1) }
        \cup { [ZeroLogonReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroLogonReportMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Logout Request Message: 20 bytes                                        *)
(***************************************************************************)

LogoutRequestMessage ==
    [ userId : Sample(20) ]

EncodeLogoutRequestMessage(message) ==
    message.userId

DecodeLogoutRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    Ok([ userId |-> userId.value ], userId.rest)

ZeroLogoutRequestMessage ==
    [ userId |-> [i \in 1 .. 20 |-> 0] ]

(* Logout Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequestMessage ==
    { ZeroLogoutRequestMessage }
        \cup { [ZeroLogoutRequestMessage EXCEPT !.userId = one] : one \in Sample(20) }

(***************************************************************************)
(* Logout Report Message: 124 bytes                                        *)
(***************************************************************************)

LogoutReportMessage ==
    [ userId       : Sample(20),
      exchangeCode : Sample(4),
      text         : Sample(100) ]

EncodeLogoutReportMessage(message) ==
    message.userId
        \o message.exchangeCode
        \o message.text

DecodeLogoutReportMessage(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(userId.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ userId       |-> userId.value,
         exchangeCode |-> exchangeCode.value,
         text         |-> text.value ], text.rest)

ZeroLogoutReportMessage ==
    [ userId       |-> [i \in 1 .. 20 |-> 0],
      exchangeCode |-> [i \in 1 .. 4 |-> 0],
      text         |-> [i \in 1 .. 100 |-> 0] ]

(* Logout Report Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutReportMessage ==
    { ZeroLogoutReportMessage }
        \cup { [ZeroLogoutReportMessage EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogoutReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroLogoutReportMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Error Message: 129 bytes                                                *)
(***************************************************************************)

ErrorMessage ==
    [ refSequenceId          : Sample(4),
      severityLevel          : Sample(1),
      supportedSchemaVersion : Sample(20),
      exchangeCode           : Sample(4),
      text                   : Sample(100) ]

EncodeErrorMessage(message) ==
    message.refSequenceId
        \o message.severityLevel
        \o message.supportedSchemaVersion
        \o message.exchangeCode
        \o message.text

DecodeErrorMessage(bytes) ==
    LET refSequenceId == ReadBytes(bytes, 4) IN IF ~refSequenceId.ok THEN Fail ELSE
    LET severityLevel == ReadBytes(refSequenceId.rest, 1) IN IF ~severityLevel.ok THEN Fail ELSE
    LET supportedSchemaVersion == ReadBytes(severityLevel.rest, 20) IN IF ~supportedSchemaVersion.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(supportedSchemaVersion.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ refSequenceId          |-> refSequenceId.value,
         severityLevel          |-> severityLevel.value,
         supportedSchemaVersion |-> supportedSchemaVersion.value,
         exchangeCode           |-> exchangeCode.value,
         text                   |-> text.value ], text.rest)

ZeroErrorMessage ==
    [ refSequenceId          |-> [i \in 1 .. 4 |-> 0],
      severityLevel          |-> [i \in 1 .. 1 |-> 0],
      supportedSchemaVersion |-> [i \in 1 .. 20 |-> 0],
      exchangeCode           |-> [i \in 1 .. 4 |-> 0],
      text                   |-> [i \in 1 .. 100 |-> 0] ]

(* Error Message at zero, then each field in turn at the values it is checked at *)
CheckedErrorMessage ==
    { ZeroErrorMessage }
        \cup { [ZeroErrorMessage EXCEPT !.refSequenceId = one] : one \in Sample(4) }
        \cup { [ZeroErrorMessage EXCEPT !.severityLevel = one] : one \in Sample(1) }
        \cup { [ZeroErrorMessage EXCEPT !.supportedSchemaVersion = one] : one \in Sample(20) }
        \cup { [ZeroErrorMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroErrorMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Text var String 16 Null                                                 *)
(***************************************************************************)

TextVarString16Null ==
    [ textData : SampleBytes ]

EncodeTextVarString16Null(message) ==
    EncodeUIntLE(Len(message.textData), 2)
        \o message.textData

DecodeTextVarString16Null(bytes) ==
    LET textLength == ReadUIntLE(bytes, 2) IN IF ~textLength.ok THEN Fail ELSE
    LET textData == ReadBytes(textLength.rest, textLength.value) IN IF ~textData.ok THEN Fail ELSE
    Ok([ textData |-> textData.value ], textData.rest)

ZeroTextVarString16Null ==
    [ textData |-> << >> ]

(* Text var String 16 Null at zero, then each field in turn at the values it is checked at *)
CheckedTextVarString16Null ==
    { ZeroTextVarString16Null }
        \cup { [ZeroTextVarString16Null EXCEPT !.textData = one] : one \in SampleBytes }

(***************************************************************************)
(* News Message                                                            *)
(***************************************************************************)

NewsMessage ==
    [ userId              : Sample(20),
      exchangeCode        : Sample(4),
      textVarString16Null : TextVarString16Null ]

EncodeNewsMessage(message) ==
    message.userId
        \o message.exchangeCode
        \o EncodeTextVarString16Null(message.textVarString16Null)

DecodeNewsMessage(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(userId.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET textVarString16Null == DecodeTextVarString16Null(exchangeCode.rest) IN IF ~textVarString16Null.ok THEN Fail ELSE
    Ok([ userId              |-> userId.value,
         exchangeCode        |-> exchangeCode.value,
         textVarString16Null |-> textVarString16Null.value ], textVarString16Null.rest)

ZeroNewsMessage ==
    [ userId              |-> [i \in 1 .. 20 |-> 0],
      exchangeCode        |-> [i \in 1 .. 4 |-> 0],
      textVarString16Null |-> ZeroTextVarString16Null ]

(* News Message at zero, then each field in turn at the values it is checked at *)
CheckedNewsMessage ==
    { ZeroNewsMessage }
        \cup { [ZeroNewsMessage EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroNewsMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroNewsMessage EXCEPT !.textVarString16Null = one] : one \in CheckedTextVarString16Null }

(***************************************************************************)
(* Security Definition Report Strategy Message no Block Details Group: 12  *)
(* bytes                                                                   *)
(***************************************************************************)

SecurityDefinitionReportStrategyMessageNoBlockDetailsGroup ==
    [ blockDetailsBlockType : Sample(1),
      blockDetailsTradeType : Sample(3),
      blockDetailsMinQty    : Sample(8) ]

EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup(message) ==
    message.blockDetailsBlockType
        \o message.blockDetailsTradeType
        \o message.blockDetailsMinQty

DecodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup(bytes) ==
    LET blockDetailsBlockType == ReadBytes(bytes, 1) IN IF ~blockDetailsBlockType.ok THEN Fail ELSE
    LET blockDetailsTradeType == ReadBytes(blockDetailsBlockType.rest, 3) IN IF ~blockDetailsTradeType.ok THEN Fail ELSE
    LET blockDetailsMinQty == ReadBytes(blockDetailsTradeType.rest, 8) IN IF ~blockDetailsMinQty.ok THEN Fail ELSE
    Ok([ blockDetailsBlockType |-> blockDetailsBlockType.value,
         blockDetailsTradeType |-> blockDetailsTradeType.value,
         blockDetailsMinQty    |-> blockDetailsMinQty.value ], blockDetailsMinQty.rest)

ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup ==
    [ blockDetailsBlockType |-> [i \in 1 .. 1 |-> 0],
      blockDetailsTradeType |-> [i \in 1 .. 3 |-> 0],
      blockDetailsMinQty    |-> [i \in 1 .. 8 |-> 0] ]

(* Security Definition Report Strategy Message no Block Details Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup ==
    { ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup EXCEPT !.blockDetailsBlockType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup EXCEPT !.blockDetailsTradeType = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup EXCEPT !.blockDetailsMinQty = one] : one \in Sample(8) }

(* A run of Security Definition Report Strategy Message no Block Details Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroupList(_)
EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup(Head(messages)) \o EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroupList(Tail(messages))

(* As many Security Definition Report Strategy Message no Block Details Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionReportStrategyMessageNoBlockDetailsGroupList(_, _)
ReadSecurityDefinitionReportStrategyMessageNoBlockDetailsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionReportStrategyMessageNoBlockDetailsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Report Strategy Message no Block Details Group of each kind, for the lists that carry them *)
OneSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup == { ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup }

(***************************************************************************)
(* Security Definition Report Strategy Message no Block Details Groups     *)
(***************************************************************************)

SecurityDefinitionReportStrategyMessageNoBlockDetailsGroups ==
    [ blockLength                                                : Sample(2),
      securityDefinitionReportStrategyMessageNoBlockDetailsGroup : SampleLists(OneSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup) ]

EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.securityDefinitionReportStrategyMessageNoBlockDetailsGroup), 2)
        \o EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroupList(message.securityDefinitionReportStrategyMessageNoBlockDetailsGroup)

DecodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityDefinitionReportStrategyMessageNoBlockDetailsGroup == ReadSecurityDefinitionReportStrategyMessageNoBlockDetailsGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityDefinitionReportStrategyMessageNoBlockDetailsGroup.ok THEN Fail ELSE
    Ok([ blockLength                                                |-> blockLength.value,
         securityDefinitionReportStrategyMessageNoBlockDetailsGroup |-> securityDefinitionReportStrategyMessageNoBlockDetailsGroup.value ], securityDefinitionReportStrategyMessageNoBlockDetailsGroup.rest)

ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups ==
    [ blockLength                                                |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionReportStrategyMessageNoBlockDetailsGroup |-> << >> ]

(* Security Definition Report Strategy Message no Block Details Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups ==
    { ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups EXCEPT !.securityDefinitionReportStrategyMessageNoBlockDetailsGroup = one] : one \in SampleLists(OneSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup) }

(***************************************************************************)
(* Security Definition Report Strategy Message no Security Alt I D Group:  *)
(* 33 bytes                                                                *)
(***************************************************************************)

SecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup ==
    [ securityAltId       : Sample(30),
      securityAltIdSource : Sample(3) ]

EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup(message) ==
    message.securityAltId
        \o message.securityAltIdSource

DecodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup(bytes) ==
    LET securityAltId == ReadBytes(bytes, 30) IN IF ~securityAltId.ok THEN Fail ELSE
    LET securityAltIdSource == ReadBytes(securityAltId.rest, 3) IN IF ~securityAltIdSource.ok THEN Fail ELSE
    Ok([ securityAltId       |-> securityAltId.value,
         securityAltIdSource |-> securityAltIdSource.value ], securityAltIdSource.rest)

ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup ==
    [ securityAltId       |-> [i \in 1 .. 30 |-> 0],
      securityAltIdSource |-> [i \in 1 .. 3 |-> 0] ]

(* Security Definition Report Strategy Message no Security Alt I D Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup ==
    { ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup EXCEPT !.securityAltId = one] : one \in Sample(30) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup EXCEPT !.securityAltIdSource = one] : one \in Sample(3) }

(* A run of Security Definition Report Strategy Message no Security Alt I D Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroupList(_)
EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup(Head(messages)) \o EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroupList(Tail(messages))

(* As many Security Definition Report Strategy Message no Security Alt I D Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroupList(_, _)
ReadSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Report Strategy Message no Security Alt I D Group of each kind, for the lists that carry them *)
OneSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup == { ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup }

(***************************************************************************)
(* Security Definition Report Strategy Message no Security Alt I D Groups  *)
(***************************************************************************)

SecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups ==
    [ blockLength                                                 : Sample(2),
      securityDefinitionReportStrategyMessageNoSecurityAltIDGroup : SampleLists(OneSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup) ]

EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.securityDefinitionReportStrategyMessageNoSecurityAltIDGroup), 2)
        \o EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroupList(message.securityDefinitionReportStrategyMessageNoSecurityAltIDGroup)

DecodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityDefinitionReportStrategyMessageNoSecurityAltIDGroup == ReadSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityDefinitionReportStrategyMessageNoSecurityAltIDGroup.ok THEN Fail ELSE
    Ok([ blockLength                                                 |-> blockLength.value,
         securityDefinitionReportStrategyMessageNoSecurityAltIDGroup |-> securityDefinitionReportStrategyMessageNoSecurityAltIDGroup.value ], securityDefinitionReportStrategyMessageNoSecurityAltIDGroup.rest)

ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups ==
    [ blockLength                                                 |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionReportStrategyMessageNoSecurityAltIDGroup |-> << >> ]

(* Security Definition Report Strategy Message no Security Alt I D Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups ==
    { ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups EXCEPT !.securityDefinitionReportStrategyMessageNoSecurityAltIDGroup = one] : one \in SampleLists(OneSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup) }

(***************************************************************************)
(* Security Definition Report Strategy Message no Legs Group: 28 bytes     *)
(***************************************************************************)

SecurityDefinitionReportStrategyMessageNoLegsGroup ==
    [ legSymbolInt32              : Sample(4),
      legSecurityType             : Sample(1),
      legSecuritySubType          : Sample(2),
      legSide                     : Sample(1),
      legPrice                    : Sample(8),
      legOptionDelta              : Sample(4),
      legRatioQtyDenominatorInt16 : Sample(2),
      legRatioQtyNumeratorInt16   : Sample(2),
      legRatioPriceDenominator    : Sample(2),
      legRatioPriceNumerator      : Sample(2) ]

EncodeSecurityDefinitionReportStrategyMessageNoLegsGroup(message) ==
    message.legSymbolInt32
        \o message.legSecurityType
        \o message.legSecuritySubType
        \o message.legSide
        \o message.legPrice
        \o message.legOptionDelta
        \o message.legRatioQtyDenominatorInt16
        \o message.legRatioQtyNumeratorInt16
        \o message.legRatioPriceDenominator
        \o message.legRatioPriceNumerator

DecodeSecurityDefinitionReportStrategyMessageNoLegsGroup(bytes) ==
    LET legSymbolInt32 == ReadBytes(bytes, 4) IN IF ~legSymbolInt32.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legSymbolInt32.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legSecuritySubType == ReadBytes(legSecurityType.rest, 2) IN IF ~legSecuritySubType.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSecuritySubType.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSide.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legOptionDelta == ReadBytes(legPrice.rest, 4) IN IF ~legOptionDelta.ok THEN Fail ELSE
    LET legRatioQtyDenominatorInt16 == ReadBytes(legOptionDelta.rest, 2) IN IF ~legRatioQtyDenominatorInt16.ok THEN Fail ELSE
    LET legRatioQtyNumeratorInt16 == ReadBytes(legRatioQtyDenominatorInt16.rest, 2) IN IF ~legRatioQtyNumeratorInt16.ok THEN Fail ELSE
    LET legRatioPriceDenominator == ReadBytes(legRatioQtyNumeratorInt16.rest, 2) IN IF ~legRatioPriceDenominator.ok THEN Fail ELSE
    LET legRatioPriceNumerator == ReadBytes(legRatioPriceDenominator.rest, 2) IN IF ~legRatioPriceNumerator.ok THEN Fail ELSE
    Ok([ legSymbolInt32              |-> legSymbolInt32.value,
         legSecurityType             |-> legSecurityType.value,
         legSecuritySubType          |-> legSecuritySubType.value,
         legSide                     |-> legSide.value,
         legPrice                    |-> legPrice.value,
         legOptionDelta              |-> legOptionDelta.value,
         legRatioQtyDenominatorInt16 |-> legRatioQtyDenominatorInt16.value,
         legRatioQtyNumeratorInt16   |-> legRatioQtyNumeratorInt16.value,
         legRatioPriceDenominator    |-> legRatioPriceDenominator.value,
         legRatioPriceNumerator      |-> legRatioPriceNumerator.value ], legRatioPriceNumerator.rest)

ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup ==
    [ legSymbolInt32              |-> [i \in 1 .. 4 |-> 0],
      legSecurityType             |-> [i \in 1 .. 1 |-> 0],
      legSecuritySubType          |-> [i \in 1 .. 2 |-> 0],
      legSide                     |-> [i \in 1 .. 1 |-> 0],
      legPrice                    |-> [i \in 1 .. 8 |-> 0],
      legOptionDelta              |-> [i \in 1 .. 4 |-> 0],
      legRatioQtyDenominatorInt16 |-> [i \in 1 .. 2 |-> 0],
      legRatioQtyNumeratorInt16   |-> [i \in 1 .. 2 |-> 0],
      legRatioPriceDenominator    |-> [i \in 1 .. 2 |-> 0],
      legRatioPriceNumerator      |-> [i \in 1 .. 2 |-> 0] ]

(* Security Definition Report Strategy Message no Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportStrategyMessageNoLegsGroup ==
    { ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legSymbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legSecuritySubType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legOptionDelta = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legRatioQtyDenominatorInt16 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legRatioQtyNumeratorInt16 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legRatioPriceDenominator = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup EXCEPT !.legRatioPriceNumerator = one] : one \in Sample(2) }

(* A run of Security Definition Report Strategy Message no Legs Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionReportStrategyMessageNoLegsGroupList(_)
EncodeSecurityDefinitionReportStrategyMessageNoLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionReportStrategyMessageNoLegsGroup(Head(messages)) \o EncodeSecurityDefinitionReportStrategyMessageNoLegsGroupList(Tail(messages))

(* As many Security Definition Report Strategy Message no Legs Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionReportStrategyMessageNoLegsGroupList(_, _)
ReadSecurityDefinitionReportStrategyMessageNoLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionReportStrategyMessageNoLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionReportStrategyMessageNoLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Report Strategy Message no Legs Group of each kind, for the lists that carry them *)
OneSecurityDefinitionReportStrategyMessageNoLegsGroup == { ZeroSecurityDefinitionReportStrategyMessageNoLegsGroup }

(***************************************************************************)
(* Security Definition Report Strategy Message no Legs Groups              *)
(***************************************************************************)

SecurityDefinitionReportStrategyMessageNoLegsGroups ==
    [ blockLength                                        : Sample(2),
      securityDefinitionReportStrategyMessageNoLegsGroup : SampleLists(OneSecurityDefinitionReportStrategyMessageNoLegsGroup) ]

EncodeSecurityDefinitionReportStrategyMessageNoLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.securityDefinitionReportStrategyMessageNoLegsGroup), 2)
        \o EncodeSecurityDefinitionReportStrategyMessageNoLegsGroupList(message.securityDefinitionReportStrategyMessageNoLegsGroup)

DecodeSecurityDefinitionReportStrategyMessageNoLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityDefinitionReportStrategyMessageNoLegsGroup == ReadSecurityDefinitionReportStrategyMessageNoLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityDefinitionReportStrategyMessageNoLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                                        |-> blockLength.value,
         securityDefinitionReportStrategyMessageNoLegsGroup |-> securityDefinitionReportStrategyMessageNoLegsGroup.value ], securityDefinitionReportStrategyMessageNoLegsGroup.rest)

ZeroSecurityDefinitionReportStrategyMessageNoLegsGroups ==
    [ blockLength                                        |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionReportStrategyMessageNoLegsGroup |-> << >> ]

(* Security Definition Report Strategy Message no Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportStrategyMessageNoLegsGroups ==
    { ZeroSecurityDefinitionReportStrategyMessageNoLegsGroups }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessageNoLegsGroups EXCEPT !.securityDefinitionReportStrategyMessageNoLegsGroup = one] : one \in SampleLists(OneSecurityDefinitionReportStrategyMessageNoLegsGroup) }

(***************************************************************************)
(* Security Id                                                             *)
(***************************************************************************)

SecurityId ==
    [ securityIdData : SampleBytes ]

EncodeSecurityId(message) ==
    EncodeUIntLE(Len(message.securityIdData), 2)
        \o message.securityIdData

DecodeSecurityId(bytes) ==
    LET securityIdLength == ReadUIntLE(bytes, 2) IN IF ~securityIdLength.ok THEN Fail ELSE
    LET securityIdData == ReadBytes(securityIdLength.rest, securityIdLength.value) IN IF ~securityIdData.ok THEN Fail ELSE
    Ok([ securityIdData |-> securityIdData.value ], securityIdData.rest)

ZeroSecurityId ==
    [ securityIdData |-> << >> ]

(* Security Id at zero, then each field in turn at the values it is checked at *)
CheckedSecurityId ==
    { ZeroSecurityId }
        \cup { [ZeroSecurityId EXCEPT !.securityIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Unit Of Measure                                                         *)
(***************************************************************************)

UnitOfMeasure ==
    [ unitOfMeasureData : SampleBytes ]

EncodeUnitOfMeasure(message) ==
    EncodeUIntLE(Len(message.unitOfMeasureData), 2)
        \o message.unitOfMeasureData

DecodeUnitOfMeasure(bytes) ==
    LET unitOfMeasureLength == ReadUIntLE(bytes, 2) IN IF ~unitOfMeasureLength.ok THEN Fail ELSE
    LET unitOfMeasureData == ReadBytes(unitOfMeasureLength.rest, unitOfMeasureLength.value) IN IF ~unitOfMeasureData.ok THEN Fail ELSE
    Ok([ unitOfMeasureData |-> unitOfMeasureData.value ], unitOfMeasureData.rest)

ZeroUnitOfMeasure ==
    [ unitOfMeasureData |-> << >> ]

(* Unit Of Measure at zero, then each field in turn at the values it is checked at *)
CheckedUnitOfMeasure ==
    { ZeroUnitOfMeasure }
        \cup { [ZeroUnitOfMeasure EXCEPT !.unitOfMeasureData = one] : one \in SampleBytes }

(***************************************************************************)
(* Price Denomination                                                      *)
(***************************************************************************)

PriceDenomination ==
    [ priceDenominationData : SampleBytes ]

EncodePriceDenomination(message) ==
    EncodeUIntLE(Len(message.priceDenominationData), 2)
        \o message.priceDenominationData

DecodePriceDenomination(bytes) ==
    LET priceDenominationLength == ReadUIntLE(bytes, 2) IN IF ~priceDenominationLength.ok THEN Fail ELSE
    LET priceDenominationData == ReadBytes(priceDenominationLength.rest, priceDenominationLength.value) IN IF ~priceDenominationData.ok THEN Fail ELSE
    Ok([ priceDenominationData |-> priceDenominationData.value ], priceDenominationData.rest)

ZeroPriceDenomination ==
    [ priceDenominationData |-> << >> ]

(* Price Denomination at zero, then each field in turn at the values it is checked at *)
CheckedPriceDenomination ==
    { ZeroPriceDenomination }
        \cup { [ZeroPriceDenomination EXCEPT !.priceDenominationData = one] : one \in SampleBytes }

(***************************************************************************)
(* Cleared Alias                                                           *)
(***************************************************************************)

ClearedAlias ==
    [ clearedAliasData : SampleBytes ]

EncodeClearedAlias(message) ==
    EncodeUIntLE(Len(message.clearedAliasData), 2)
        \o message.clearedAliasData

DecodeClearedAlias(bytes) ==
    LET clearedAliasLength == ReadUIntLE(bytes, 2) IN IF ~clearedAliasLength.ok THEN Fail ELSE
    LET clearedAliasData == ReadBytes(clearedAliasLength.rest, clearedAliasLength.value) IN IF ~clearedAliasData.ok THEN Fail ELSE
    Ok([ clearedAliasData |-> clearedAliasData.value ], clearedAliasData.rest)

ZeroClearedAlias ==
    [ clearedAliasData |-> << >> ]

(* Cleared Alias at zero, then each field in turn at the values it is checked at *)
CheckedClearedAlias ==
    { ZeroClearedAlias }
        \cup { [ZeroClearedAlias EXCEPT !.clearedAliasData = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Desc                                                           *)
(***************************************************************************)

SecurityDesc ==
    [ securityDescData : SampleBytes ]

EncodeSecurityDesc(message) ==
    EncodeUIntLE(Len(message.securityDescData), 2)
        \o message.securityDescData

DecodeSecurityDesc(bytes) ==
    LET securityDescLength == ReadUIntLE(bytes, 2) IN IF ~securityDescLength.ok THEN Fail ELSE
    LET securityDescData == ReadBytes(securityDescLength.rest, securityDescLength.value) IN IF ~securityDescData.ok THEN Fail ELSE
    Ok([ securityDescData |-> securityDescData.value ], securityDescData.rest)

ZeroSecurityDesc ==
    [ securityDescData |-> << >> ]

(* Security Desc at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDesc ==
    { ZeroSecurityDesc }
        \cup { [ZeroSecurityDesc EXCEPT !.securityDescData = one] : one \in SampleBytes }

(***************************************************************************)
(* Price Unit                                                              *)
(***************************************************************************)

PriceUnit ==
    [ priceUnitData : SampleBytes ]

EncodePriceUnit(message) ==
    EncodeUIntLE(Len(message.priceUnitData), 2)
        \o message.priceUnitData

DecodePriceUnit(bytes) ==
    LET priceUnitLength == ReadUIntLE(bytes, 2) IN IF ~priceUnitLength.ok THEN Fail ELSE
    LET priceUnitData == ReadBytes(priceUnitLength.rest, priceUnitLength.value) IN IF ~priceUnitData.ok THEN Fail ELSE
    Ok([ priceUnitData |-> priceUnitData.value ], priceUnitData.rest)

ZeroPriceUnit ==
    [ priceUnitData |-> << >> ]

(* Price Unit at zero, then each field in turn at the values it is checked at *)
CheckedPriceUnit ==
    { ZeroPriceUnit }
        \cup { [ZeroPriceUnit EXCEPT !.priceUnitData = one] : one \in SampleBytes }

(***************************************************************************)
(* Strip Name                                                              *)
(***************************************************************************)

StripName ==
    [ stripNameData : SampleBytes ]

EncodeStripName(message) ==
    EncodeUIntLE(Len(message.stripNameData), 2)
        \o message.stripNameData

DecodeStripName(bytes) ==
    LET stripNameLength == ReadUIntLE(bytes, 2) IN IF ~stripNameLength.ok THEN Fail ELSE
    LET stripNameData == ReadBytes(stripNameLength.rest, stripNameLength.value) IN IF ~stripNameData.ok THEN Fail ELSE
    Ok([ stripNameData |-> stripNameData.value ], stripNameData.rest)

ZeroStripName ==
    [ stripNameData |-> << >> ]

(* Strip Name at zero, then each field in turn at the values it is checked at *)
CheckedStripName ==
    { ZeroStripName }
        \cup { [ZeroStripName EXCEPT !.stripNameData = one] : one \in SampleBytes }

(***************************************************************************)
(* Hub Name                                                                *)
(***************************************************************************)

HubName ==
    [ hubNameData : SampleBytes ]

EncodeHubName(message) ==
    EncodeUIntLE(Len(message.hubNameData), 2)
        \o message.hubNameData

DecodeHubName(bytes) ==
    LET hubNameLength == ReadUIntLE(bytes, 2) IN IF ~hubNameLength.ok THEN Fail ELSE
    LET hubNameData == ReadBytes(hubNameLength.rest, hubNameLength.value) IN IF ~hubNameData.ok THEN Fail ELSE
    Ok([ hubNameData |-> hubNameData.value ], hubNameData.rest)

ZeroHubName ==
    [ hubNameData |-> << >> ]

(* Hub Name at zero, then each field in turn at the values it is checked at *)
CheckedHubName ==
    { ZeroHubName }
        \cup { [ZeroHubName EXCEPT !.hubNameData = one] : one \in SampleBytes }

(***************************************************************************)
(* Hub Alias                                                               *)
(***************************************************************************)

HubAlias ==
    [ hubAliasData : SampleBytes ]

EncodeHubAlias(message) ==
    EncodeUIntLE(Len(message.hubAliasData), 2)
        \o message.hubAliasData

DecodeHubAlias(bytes) ==
    LET hubAliasLength == ReadUIntLE(bytes, 2) IN IF ~hubAliasLength.ok THEN Fail ELSE
    LET hubAliasData == ReadBytes(hubAliasLength.rest, hubAliasLength.value) IN IF ~hubAliasData.ok THEN Fail ELSE
    Ok([ hubAliasData |-> hubAliasData.value ], hubAliasData.rest)

ZeroHubAlias ==
    [ hubAliasData |-> << >> ]

(* Hub Alias at zero, then each field in turn at the values it is checked at *)
CheckedHubAlias ==
    { ZeroHubAlias }
        \cup { [ZeroHubAlias EXCEPT !.hubAliasData = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Exchange                                                       *)
(***************************************************************************)

SecurityExchange ==
    [ securityExchangeData : SampleBytes ]

EncodeSecurityExchange(message) ==
    EncodeUIntLE(Len(message.securityExchangeData), 2)
        \o message.securityExchangeData

DecodeSecurityExchange(bytes) ==
    LET securityExchangeLength == ReadUIntLE(bytes, 2) IN IF ~securityExchangeLength.ok THEN Fail ELSE
    LET securityExchangeData == ReadBytes(securityExchangeLength.rest, securityExchangeLength.value) IN IF ~securityExchangeData.ok THEN Fail ELSE
    Ok([ securityExchangeData |-> securityExchangeData.value ], securityExchangeData.rest)

ZeroSecurityExchange ==
    [ securityExchangeData |-> << >> ]

(* Security Exchange at zero, then each field in turn at the values it is checked at *)
CheckedSecurityExchange ==
    { ZeroSecurityExchange }
        \cup { [ZeroSecurityExchange EXCEPT !.securityExchangeData = one] : one \in SampleBytes }

(***************************************************************************)
(* Strategy Security Id                                                    *)
(***************************************************************************)

StrategySecurityId ==
    [ strategySecurityIdData : SampleBytes ]

EncodeStrategySecurityId(message) ==
    EncodeUIntLE(Len(message.strategySecurityIdData), 2)
        \o message.strategySecurityIdData

DecodeStrategySecurityId(bytes) ==
    LET strategySecurityIdLength == ReadUIntLE(bytes, 2) IN IF ~strategySecurityIdLength.ok THEN Fail ELSE
    LET strategySecurityIdData == ReadBytes(strategySecurityIdLength.rest, strategySecurityIdLength.value) IN IF ~strategySecurityIdData.ok THEN Fail ELSE
    Ok([ strategySecurityIdData |-> strategySecurityIdData.value ], strategySecurityIdData.rest)

ZeroStrategySecurityId ==
    [ strategySecurityIdData |-> << >> ]

(* Strategy Security Id at zero, then each field in turn at the values it is checked at *)
CheckedStrategySecurityId ==
    { ZeroStrategySecurityId }
        \cup { [ZeroStrategySecurityId EXCEPT !.strategySecurityIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Physical Code                                                           *)
(***************************************************************************)

PhysicalCode ==
    [ physicalCodeData : SampleBytes ]

EncodePhysicalCode(message) ==
    EncodeUIntLE(Len(message.physicalCodeData), 2)
        \o message.physicalCodeData

DecodePhysicalCode(bytes) ==
    LET physicalCodeLength == ReadUIntLE(bytes, 2) IN IF ~physicalCodeLength.ok THEN Fail ELSE
    LET physicalCodeData == ReadBytes(physicalCodeLength.rest, physicalCodeLength.value) IN IF ~physicalCodeData.ok THEN Fail ELSE
    Ok([ physicalCodeData |-> physicalCodeData.value ], physicalCodeData.rest)

ZeroPhysicalCode ==
    [ physicalCodeData |-> << >> ]

(* Physical Code at zero, then each field in turn at the values it is checked at *)
CheckedPhysicalCode ==
    { ZeroPhysicalCode }
        \cup { [ZeroPhysicalCode EXCEPT !.physicalCodeData = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Definition Report Strategy Message                             *)
(***************************************************************************)

SecurityDefinitionReportStrategyMessage ==
    [ securityReqId                                                : Sample(4),
      securityResponseType                                         : Sample(1),
      securityResponseId                                           : Sample(4),
      marketTypeIDInt32                                            : Sample(4),
      noRpts                                                       : Sample(4),
      listSeqNo                                                    : Sample(4),
      symbolInt32                                                  : Sample(4),
      underlyingStrategySymbol                                     : Sample(4),
      maturityDate                                                 : Sample(2),
      securityTradingStatus                                        : Sample(1),
      securitySubTypeInt16                                         : Sample(2),
      exchangeSilo                                                 : Sample(1),
      transactTimeUtcTimestamp                                     : Sample(8),
      legDealsSuppressed                                           : Sample(1),
      incrementPrice                                               : Sample(8),
      incrementQty                                                 : Sample(8),
      minPrice                                                     : Sample(8),
      maxPrice                                                     : Sample(8),
      numOfDecimalPrice                                            : Sample(1),
      numOfDecimalQty                                              : Sample(1),
      productIDInt32                                               : Sample(4),
      baseNumLots                                                  : Sample(4),
      denominator                                                  : Sample(4),
      impliedType                                                  : Sample(1),
      offExchangeIncrementPriceDecimal9Null                        : Sample(8),
      offExchangeIncrementQtyDecimal9Null                          : Sample(8),
      numOfDecimalStrikePrice                                      : Sample(1),
      numOfCyclesInt16Null                                         : Sample(2),
      lotSizeMultiplierDecimal9Null                                : Sample(8),
      blockOnly                                                    : Sample(1),
      flexAllowed                                                  : Sample(1),
      gtAllowed                                                    : Sample(1),
      mifidRegulatedMarketBooleanEnum                              : Sample(1),
      stripType                                                    : Sample(2),
      hubId                                                        : Sample(4),
      overrideBlockMin                                             : Sample(1),
      testMarketIndicatorBooleanEnum                               : Sample(1),
      screenTickValue                                              : Sample(8),
      blockTickValue                                               : Sample(8),
      securityDefinitionReportStrategyMessageNoBlockDetailsGroups  : SecurityDefinitionReportStrategyMessageNoBlockDetailsGroups,
      securityDefinitionReportStrategyMessageNoSecurityAltIDGroups : SecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups,
      securityDefinitionReportStrategyMessageNoLegsGroups          : SecurityDefinitionReportStrategyMessageNoLegsGroups,
      securityId                                                   : SecurityId,
      unitOfMeasure                                                : UnitOfMeasure,
      priceDenomination                                            : PriceDenomination,
      clearedAlias                                                 : ClearedAlias,
      securityDesc                                                 : SecurityDesc,
      priceUnit                                                    : PriceUnit,
      stripName                                                    : StripName,
      hubName                                                      : HubName,
      hubAlias                                                     : HubAlias,
      securityExchange                                             : SecurityExchange,
      strategySecurityId                                           : StrategySecurityId,
      physicalCode                                                 : PhysicalCode ]

EncodeSecurityDefinitionReportStrategyMessage(message) ==
    message.securityReqId
        \o message.securityResponseType
        \o message.securityResponseId
        \o message.marketTypeIDInt32
        \o message.noRpts
        \o message.listSeqNo
        \o message.symbolInt32
        \o message.underlyingStrategySymbol
        \o message.maturityDate
        \o message.securityTradingStatus
        \o message.securitySubTypeInt16
        \o message.exchangeSilo
        \o message.transactTimeUtcTimestamp
        \o message.legDealsSuppressed
        \o message.incrementPrice
        \o message.incrementQty
        \o message.minPrice
        \o message.maxPrice
        \o message.numOfDecimalPrice
        \o message.numOfDecimalQty
        \o message.productIDInt32
        \o message.baseNumLots
        \o message.denominator
        \o message.impliedType
        \o message.offExchangeIncrementPriceDecimal9Null
        \o message.offExchangeIncrementQtyDecimal9Null
        \o message.numOfDecimalStrikePrice
        \o message.numOfCyclesInt16Null
        \o message.lotSizeMultiplierDecimal9Null
        \o message.blockOnly
        \o message.flexAllowed
        \o message.gtAllowed
        \o message.mifidRegulatedMarketBooleanEnum
        \o message.stripType
        \o message.hubId
        \o message.overrideBlockMin
        \o message.testMarketIndicatorBooleanEnum
        \o message.screenTickValue
        \o message.blockTickValue
        \o EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups(message.securityDefinitionReportStrategyMessageNoBlockDetailsGroups)
        \o EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups(message.securityDefinitionReportStrategyMessageNoSecurityAltIDGroups)
        \o EncodeSecurityDefinitionReportStrategyMessageNoLegsGroups(message.securityDefinitionReportStrategyMessageNoLegsGroups)
        \o EncodeSecurityId(message.securityId)
        \o EncodeUnitOfMeasure(message.unitOfMeasure)
        \o EncodePriceDenomination(message.priceDenomination)
        \o EncodeClearedAlias(message.clearedAlias)
        \o EncodeSecurityDesc(message.securityDesc)
        \o EncodePriceUnit(message.priceUnit)
        \o EncodeStripName(message.stripName)
        \o EncodeHubName(message.hubName)
        \o EncodeHubAlias(message.hubAlias)
        \o EncodeSecurityExchange(message.securityExchange)
        \o EncodeStrategySecurityId(message.strategySecurityId)
        \o EncodePhysicalCode(message.physicalCode)

DecodeSecurityDefinitionReportStrategyMessage(bytes) ==
    LET securityReqId == ReadBytes(bytes, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityResponseType == ReadBytes(securityReqId.rest, 1) IN IF ~securityResponseType.ok THEN Fail ELSE
    LET securityResponseId == ReadBytes(securityResponseType.rest, 4) IN IF ~securityResponseId.ok THEN Fail ELSE
    LET marketTypeIDInt32 == ReadBytes(securityResponseId.rest, 4) IN IF ~marketTypeIDInt32.ok THEN Fail ELSE
    LET noRpts == ReadBytes(marketTypeIDInt32.rest, 4) IN IF ~noRpts.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(noRpts.rest, 4) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(listSeqNo.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET underlyingStrategySymbol == ReadBytes(symbolInt32.rest, 4) IN IF ~underlyingStrategySymbol.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(underlyingStrategySymbol.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(maturityDate.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET securitySubTypeInt16 == ReadBytes(securityTradingStatus.rest, 2) IN IF ~securitySubTypeInt16.ok THEN Fail ELSE
    LET exchangeSilo == ReadBytes(securitySubTypeInt16.rest, 1) IN IF ~exchangeSilo.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(exchangeSilo.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    LET legDealsSuppressed == ReadBytes(transactTimeUtcTimestamp.rest, 1) IN IF ~legDealsSuppressed.ok THEN Fail ELSE
    LET incrementPrice == ReadBytes(legDealsSuppressed.rest, 8) IN IF ~incrementPrice.ok THEN Fail ELSE
    LET incrementQty == ReadBytes(incrementPrice.rest, 8) IN IF ~incrementQty.ok THEN Fail ELSE
    LET minPrice == ReadBytes(incrementQty.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(minPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET numOfDecimalPrice == ReadBytes(maxPrice.rest, 1) IN IF ~numOfDecimalPrice.ok THEN Fail ELSE
    LET numOfDecimalQty == ReadBytes(numOfDecimalPrice.rest, 1) IN IF ~numOfDecimalQty.ok THEN Fail ELSE
    LET productIDInt32 == ReadBytes(numOfDecimalQty.rest, 4) IN IF ~productIDInt32.ok THEN Fail ELSE
    LET baseNumLots == ReadBytes(productIDInt32.rest, 4) IN IF ~baseNumLots.ok THEN Fail ELSE
    LET denominator == ReadBytes(baseNumLots.rest, 4) IN IF ~denominator.ok THEN Fail ELSE
    LET impliedType == ReadBytes(denominator.rest, 1) IN IF ~impliedType.ok THEN Fail ELSE
    LET offExchangeIncrementPriceDecimal9Null == ReadBytes(impliedType.rest, 8) IN IF ~offExchangeIncrementPriceDecimal9Null.ok THEN Fail ELSE
    LET offExchangeIncrementQtyDecimal9Null == ReadBytes(offExchangeIncrementPriceDecimal9Null.rest, 8) IN IF ~offExchangeIncrementQtyDecimal9Null.ok THEN Fail ELSE
    LET numOfDecimalStrikePrice == ReadBytes(offExchangeIncrementQtyDecimal9Null.rest, 1) IN IF ~numOfDecimalStrikePrice.ok THEN Fail ELSE
    LET numOfCyclesInt16Null == ReadBytes(numOfDecimalStrikePrice.rest, 2) IN IF ~numOfCyclesInt16Null.ok THEN Fail ELSE
    LET lotSizeMultiplierDecimal9Null == ReadBytes(numOfCyclesInt16Null.rest, 8) IN IF ~lotSizeMultiplierDecimal9Null.ok THEN Fail ELSE
    LET blockOnly == ReadBytes(lotSizeMultiplierDecimal9Null.rest, 1) IN IF ~blockOnly.ok THEN Fail ELSE
    LET flexAllowed == ReadBytes(blockOnly.rest, 1) IN IF ~flexAllowed.ok THEN Fail ELSE
    LET gtAllowed == ReadBytes(flexAllowed.rest, 1) IN IF ~gtAllowed.ok THEN Fail ELSE
    LET mifidRegulatedMarketBooleanEnum == ReadBytes(gtAllowed.rest, 1) IN IF ~mifidRegulatedMarketBooleanEnum.ok THEN Fail ELSE
    LET stripType == ReadBytes(mifidRegulatedMarketBooleanEnum.rest, 2) IN IF ~stripType.ok THEN Fail ELSE
    LET hubId == ReadBytes(stripType.rest, 4) IN IF ~hubId.ok THEN Fail ELSE
    LET overrideBlockMin == ReadBytes(hubId.rest, 1) IN IF ~overrideBlockMin.ok THEN Fail ELSE
    LET testMarketIndicatorBooleanEnum == ReadBytes(overrideBlockMin.rest, 1) IN IF ~testMarketIndicatorBooleanEnum.ok THEN Fail ELSE
    LET screenTickValue == ReadBytes(testMarketIndicatorBooleanEnum.rest, 8) IN IF ~screenTickValue.ok THEN Fail ELSE
    LET blockTickValue == ReadBytes(screenTickValue.rest, 8) IN IF ~blockTickValue.ok THEN Fail ELSE
    LET securityDefinitionReportStrategyMessageNoBlockDetailsGroups == DecodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups(blockTickValue.rest) IN IF ~securityDefinitionReportStrategyMessageNoBlockDetailsGroups.ok THEN Fail ELSE
    LET securityDefinitionReportStrategyMessageNoSecurityAltIDGroups == DecodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups(securityDefinitionReportStrategyMessageNoBlockDetailsGroups.rest) IN IF ~securityDefinitionReportStrategyMessageNoSecurityAltIDGroups.ok THEN Fail ELSE
    LET securityDefinitionReportStrategyMessageNoLegsGroups == DecodeSecurityDefinitionReportStrategyMessageNoLegsGroups(securityDefinitionReportStrategyMessageNoSecurityAltIDGroups.rest) IN IF ~securityDefinitionReportStrategyMessageNoLegsGroups.ok THEN Fail ELSE
    LET securityId == DecodeSecurityId(securityDefinitionReportStrategyMessageNoLegsGroups.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET unitOfMeasure == DecodeUnitOfMeasure(securityId.rest) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET priceDenomination == DecodePriceDenomination(unitOfMeasure.rest) IN IF ~priceDenomination.ok THEN Fail ELSE
    LET clearedAlias == DecodeClearedAlias(priceDenomination.rest) IN IF ~clearedAlias.ok THEN Fail ELSE
    LET securityDesc == DecodeSecurityDesc(clearedAlias.rest) IN IF ~securityDesc.ok THEN Fail ELSE
    LET priceUnit == DecodePriceUnit(securityDesc.rest) IN IF ~priceUnit.ok THEN Fail ELSE
    LET stripName == DecodeStripName(priceUnit.rest) IN IF ~stripName.ok THEN Fail ELSE
    LET hubName == DecodeHubName(stripName.rest) IN IF ~hubName.ok THEN Fail ELSE
    LET hubAlias == DecodeHubAlias(hubName.rest) IN IF ~hubAlias.ok THEN Fail ELSE
    LET securityExchange == DecodeSecurityExchange(hubAlias.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET strategySecurityId == DecodeStrategySecurityId(securityExchange.rest) IN IF ~strategySecurityId.ok THEN Fail ELSE
    LET physicalCode == DecodePhysicalCode(strategySecurityId.rest) IN IF ~physicalCode.ok THEN Fail ELSE
    Ok([ securityReqId                                                |-> securityReqId.value,
         securityResponseType                                         |-> securityResponseType.value,
         securityResponseId                                           |-> securityResponseId.value,
         marketTypeIDInt32                                            |-> marketTypeIDInt32.value,
         noRpts                                                       |-> noRpts.value,
         listSeqNo                                                    |-> listSeqNo.value,
         symbolInt32                                                  |-> symbolInt32.value,
         underlyingStrategySymbol                                     |-> underlyingStrategySymbol.value,
         maturityDate                                                 |-> maturityDate.value,
         securityTradingStatus                                        |-> securityTradingStatus.value,
         securitySubTypeInt16                                         |-> securitySubTypeInt16.value,
         exchangeSilo                                                 |-> exchangeSilo.value,
         transactTimeUtcTimestamp                                     |-> transactTimeUtcTimestamp.value,
         legDealsSuppressed                                           |-> legDealsSuppressed.value,
         incrementPrice                                               |-> incrementPrice.value,
         incrementQty                                                 |-> incrementQty.value,
         minPrice                                                     |-> minPrice.value,
         maxPrice                                                     |-> maxPrice.value,
         numOfDecimalPrice                                            |-> numOfDecimalPrice.value,
         numOfDecimalQty                                              |-> numOfDecimalQty.value,
         productIDInt32                                               |-> productIDInt32.value,
         baseNumLots                                                  |-> baseNumLots.value,
         denominator                                                  |-> denominator.value,
         impliedType                                                  |-> impliedType.value,
         offExchangeIncrementPriceDecimal9Null                        |-> offExchangeIncrementPriceDecimal9Null.value,
         offExchangeIncrementQtyDecimal9Null                          |-> offExchangeIncrementQtyDecimal9Null.value,
         numOfDecimalStrikePrice                                      |-> numOfDecimalStrikePrice.value,
         numOfCyclesInt16Null                                         |-> numOfCyclesInt16Null.value,
         lotSizeMultiplierDecimal9Null                                |-> lotSizeMultiplierDecimal9Null.value,
         blockOnly                                                    |-> blockOnly.value,
         flexAllowed                                                  |-> flexAllowed.value,
         gtAllowed                                                    |-> gtAllowed.value,
         mifidRegulatedMarketBooleanEnum                              |-> mifidRegulatedMarketBooleanEnum.value,
         stripType                                                    |-> stripType.value,
         hubId                                                        |-> hubId.value,
         overrideBlockMin                                             |-> overrideBlockMin.value,
         testMarketIndicatorBooleanEnum                               |-> testMarketIndicatorBooleanEnum.value,
         screenTickValue                                              |-> screenTickValue.value,
         blockTickValue                                               |-> blockTickValue.value,
         securityDefinitionReportStrategyMessageNoBlockDetailsGroups  |-> securityDefinitionReportStrategyMessageNoBlockDetailsGroups.value,
         securityDefinitionReportStrategyMessageNoSecurityAltIDGroups |-> securityDefinitionReportStrategyMessageNoSecurityAltIDGroups.value,
         securityDefinitionReportStrategyMessageNoLegsGroups          |-> securityDefinitionReportStrategyMessageNoLegsGroups.value,
         securityId                                                   |-> securityId.value,
         unitOfMeasure                                                |-> unitOfMeasure.value,
         priceDenomination                                            |-> priceDenomination.value,
         clearedAlias                                                 |-> clearedAlias.value,
         securityDesc                                                 |-> securityDesc.value,
         priceUnit                                                    |-> priceUnit.value,
         stripName                                                    |-> stripName.value,
         hubName                                                      |-> hubName.value,
         hubAlias                                                     |-> hubAlias.value,
         securityExchange                                             |-> securityExchange.value,
         strategySecurityId                                           |-> strategySecurityId.value,
         physicalCode                                                 |-> physicalCode.value ], physicalCode.rest)

ZeroSecurityDefinitionReportStrategyMessage ==
    [ securityReqId                                                |-> [i \in 1 .. 4 |-> 0],
      securityResponseType                                         |-> [i \in 1 .. 1 |-> 0],
      securityResponseId                                           |-> [i \in 1 .. 4 |-> 0],
      marketTypeIDInt32                                            |-> [i \in 1 .. 4 |-> 0],
      noRpts                                                       |-> [i \in 1 .. 4 |-> 0],
      listSeqNo                                                    |-> [i \in 1 .. 4 |-> 0],
      symbolInt32                                                  |-> [i \in 1 .. 4 |-> 0],
      underlyingStrategySymbol                                     |-> [i \in 1 .. 4 |-> 0],
      maturityDate                                                 |-> [i \in 1 .. 2 |-> 0],
      securityTradingStatus                                        |-> [i \in 1 .. 1 |-> 0],
      securitySubTypeInt16                                         |-> [i \in 1 .. 2 |-> 0],
      exchangeSilo                                                 |-> [i \in 1 .. 1 |-> 0],
      transactTimeUtcTimestamp                                     |-> [i \in 1 .. 8 |-> 0],
      legDealsSuppressed                                           |-> [i \in 1 .. 1 |-> 0],
      incrementPrice                                               |-> [i \in 1 .. 8 |-> 0],
      incrementQty                                                 |-> [i \in 1 .. 8 |-> 0],
      minPrice                                                     |-> [i \in 1 .. 8 |-> 0],
      maxPrice                                                     |-> [i \in 1 .. 8 |-> 0],
      numOfDecimalPrice                                            |-> [i \in 1 .. 1 |-> 0],
      numOfDecimalQty                                              |-> [i \in 1 .. 1 |-> 0],
      productIDInt32                                               |-> [i \in 1 .. 4 |-> 0],
      baseNumLots                                                  |-> [i \in 1 .. 4 |-> 0],
      denominator                                                  |-> [i \in 1 .. 4 |-> 0],
      impliedType                                                  |-> [i \in 1 .. 1 |-> 0],
      offExchangeIncrementPriceDecimal9Null                        |-> [i \in 1 .. 8 |-> 0],
      offExchangeIncrementQtyDecimal9Null                          |-> [i \in 1 .. 8 |-> 0],
      numOfDecimalStrikePrice                                      |-> [i \in 1 .. 1 |-> 0],
      numOfCyclesInt16Null                                         |-> [i \in 1 .. 2 |-> 0],
      lotSizeMultiplierDecimal9Null                                |-> [i \in 1 .. 8 |-> 0],
      blockOnly                                                    |-> [i \in 1 .. 1 |-> 0],
      flexAllowed                                                  |-> [i \in 1 .. 1 |-> 0],
      gtAllowed                                                    |-> [i \in 1 .. 1 |-> 0],
      mifidRegulatedMarketBooleanEnum                              |-> [i \in 1 .. 1 |-> 0],
      stripType                                                    |-> [i \in 1 .. 2 |-> 0],
      hubId                                                        |-> [i \in 1 .. 4 |-> 0],
      overrideBlockMin                                             |-> [i \in 1 .. 1 |-> 0],
      testMarketIndicatorBooleanEnum                               |-> [i \in 1 .. 1 |-> 0],
      screenTickValue                                              |-> [i \in 1 .. 8 |-> 0],
      blockTickValue                                               |-> [i \in 1 .. 8 |-> 0],
      securityDefinitionReportStrategyMessageNoBlockDetailsGroups  |-> ZeroSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups,
      securityDefinitionReportStrategyMessageNoSecurityAltIDGroups |-> ZeroSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups,
      securityDefinitionReportStrategyMessageNoLegsGroups          |-> ZeroSecurityDefinitionReportStrategyMessageNoLegsGroups,
      securityId                                                   |-> ZeroSecurityId,
      unitOfMeasure                                                |-> ZeroUnitOfMeasure,
      priceDenomination                                            |-> ZeroPriceDenomination,
      clearedAlias                                                 |-> ZeroClearedAlias,
      securityDesc                                                 |-> ZeroSecurityDesc,
      priceUnit                                                    |-> ZeroPriceUnit,
      stripName                                                    |-> ZeroStripName,
      hubName                                                      |-> ZeroHubName,
      hubAlias                                                     |-> ZeroHubAlias,
      securityExchange                                             |-> ZeroSecurityExchange,
      strategySecurityId                                           |-> ZeroStrategySecurityId,
      physicalCode                                                 |-> ZeroPhysicalCode ]

(* Security Definition Report Strategy Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportStrategyMessage ==
    { ZeroSecurityDefinitionReportStrategyMessage }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityResponseType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityResponseId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.marketTypeIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.noRpts = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.listSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.underlyingStrategySymbol = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securitySubTypeInt16 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.exchangeSilo = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.legDealsSuppressed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.incrementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.incrementQty = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.numOfDecimalPrice = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.numOfDecimalQty = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.productIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.baseNumLots = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.denominator = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.impliedType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.offExchangeIncrementPriceDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.offExchangeIncrementQtyDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.numOfDecimalStrikePrice = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.numOfCyclesInt16Null = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.lotSizeMultiplierDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.blockOnly = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.flexAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.gtAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.mifidRegulatedMarketBooleanEnum = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.stripType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.hubId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.overrideBlockMin = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.testMarketIndicatorBooleanEnum = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.screenTickValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.blockTickValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityDefinitionReportStrategyMessageNoBlockDetailsGroups = one] : one \in CheckedSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityDefinitionReportStrategyMessageNoSecurityAltIDGroups = one] : one \in CheckedSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityDefinitionReportStrategyMessageNoLegsGroups = one] : one \in CheckedSecurityDefinitionReportStrategyMessageNoLegsGroups }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityId = one] : one \in CheckedSecurityId }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.unitOfMeasure = one] : one \in CheckedUnitOfMeasure }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.priceDenomination = one] : one \in CheckedPriceDenomination }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.clearedAlias = one] : one \in CheckedClearedAlias }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityDesc = one] : one \in CheckedSecurityDesc }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.priceUnit = one] : one \in CheckedPriceUnit }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.stripName = one] : one \in CheckedStripName }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.hubName = one] : one \in CheckedHubName }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.hubAlias = one] : one \in CheckedHubAlias }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.securityExchange = one] : one \in CheckedSecurityExchange }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.strategySecurityId = one] : one \in CheckedStrategySecurityId }
        \cup { [ZeroSecurityDefinitionReportStrategyMessage EXCEPT !.physicalCode = one] : one \in CheckedPhysicalCode }

(***************************************************************************)
(* Security Definition Report Message no Block Details Group: 12 bytes     *)
(***************************************************************************)

SecurityDefinitionReportMessageNoBlockDetailsGroup ==
    [ blockDetailsBlockType : Sample(1),
      blockDetailsTradeType : Sample(3),
      blockDetailsMinQty    : Sample(8) ]

EncodeSecurityDefinitionReportMessageNoBlockDetailsGroup(message) ==
    message.blockDetailsBlockType
        \o message.blockDetailsTradeType
        \o message.blockDetailsMinQty

DecodeSecurityDefinitionReportMessageNoBlockDetailsGroup(bytes) ==
    LET blockDetailsBlockType == ReadBytes(bytes, 1) IN IF ~blockDetailsBlockType.ok THEN Fail ELSE
    LET blockDetailsTradeType == ReadBytes(blockDetailsBlockType.rest, 3) IN IF ~blockDetailsTradeType.ok THEN Fail ELSE
    LET blockDetailsMinQty == ReadBytes(blockDetailsTradeType.rest, 8) IN IF ~blockDetailsMinQty.ok THEN Fail ELSE
    Ok([ blockDetailsBlockType |-> blockDetailsBlockType.value,
         blockDetailsTradeType |-> blockDetailsTradeType.value,
         blockDetailsMinQty    |-> blockDetailsMinQty.value ], blockDetailsMinQty.rest)

ZeroSecurityDefinitionReportMessageNoBlockDetailsGroup ==
    [ blockDetailsBlockType |-> [i \in 1 .. 1 |-> 0],
      blockDetailsTradeType |-> [i \in 1 .. 3 |-> 0],
      blockDetailsMinQty    |-> [i \in 1 .. 8 |-> 0] ]

(* Security Definition Report Message no Block Details Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportMessageNoBlockDetailsGroup ==
    { ZeroSecurityDefinitionReportMessageNoBlockDetailsGroup }
        \cup { [ZeroSecurityDefinitionReportMessageNoBlockDetailsGroup EXCEPT !.blockDetailsBlockType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessageNoBlockDetailsGroup EXCEPT !.blockDetailsTradeType = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionReportMessageNoBlockDetailsGroup EXCEPT !.blockDetailsMinQty = one] : one \in Sample(8) }

(* A run of Security Definition Report Message no Block Details Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionReportMessageNoBlockDetailsGroupList(_)
EncodeSecurityDefinitionReportMessageNoBlockDetailsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionReportMessageNoBlockDetailsGroup(Head(messages)) \o EncodeSecurityDefinitionReportMessageNoBlockDetailsGroupList(Tail(messages))

(* As many Security Definition Report Message no Block Details Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionReportMessageNoBlockDetailsGroupList(_, _)
ReadSecurityDefinitionReportMessageNoBlockDetailsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionReportMessageNoBlockDetailsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionReportMessageNoBlockDetailsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Report Message no Block Details Group of each kind, for the lists that carry them *)
OneSecurityDefinitionReportMessageNoBlockDetailsGroup == { ZeroSecurityDefinitionReportMessageNoBlockDetailsGroup }

(***************************************************************************)
(* Security Definition Report Message no Block Details Groups              *)
(***************************************************************************)

SecurityDefinitionReportMessageNoBlockDetailsGroups ==
    [ blockLength                                        : Sample(2),
      securityDefinitionReportMessageNoBlockDetailsGroup : SampleLists(OneSecurityDefinitionReportMessageNoBlockDetailsGroup) ]

EncodeSecurityDefinitionReportMessageNoBlockDetailsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.securityDefinitionReportMessageNoBlockDetailsGroup), 2)
        \o EncodeSecurityDefinitionReportMessageNoBlockDetailsGroupList(message.securityDefinitionReportMessageNoBlockDetailsGroup)

DecodeSecurityDefinitionReportMessageNoBlockDetailsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityDefinitionReportMessageNoBlockDetailsGroup == ReadSecurityDefinitionReportMessageNoBlockDetailsGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityDefinitionReportMessageNoBlockDetailsGroup.ok THEN Fail ELSE
    Ok([ blockLength                                        |-> blockLength.value,
         securityDefinitionReportMessageNoBlockDetailsGroup |-> securityDefinitionReportMessageNoBlockDetailsGroup.value ], securityDefinitionReportMessageNoBlockDetailsGroup.rest)

ZeroSecurityDefinitionReportMessageNoBlockDetailsGroups ==
    [ blockLength                                        |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionReportMessageNoBlockDetailsGroup |-> << >> ]

(* Security Definition Report Message no Block Details Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportMessageNoBlockDetailsGroups ==
    { ZeroSecurityDefinitionReportMessageNoBlockDetailsGroups }
        \cup { [ZeroSecurityDefinitionReportMessageNoBlockDetailsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessageNoBlockDetailsGroups EXCEPT !.securityDefinitionReportMessageNoBlockDetailsGroup = one] : one \in SampleLists(OneSecurityDefinitionReportMessageNoBlockDetailsGroup) }

(***************************************************************************)
(* Security Definition Report Message no Security Alt I D Group: 33 bytes  *)
(***************************************************************************)

SecurityDefinitionReportMessageNoSecurityAltIDGroup ==
    [ securityAltId       : Sample(30),
      securityAltIdSource : Sample(3) ]

EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroup(message) ==
    message.securityAltId
        \o message.securityAltIdSource

DecodeSecurityDefinitionReportMessageNoSecurityAltIDGroup(bytes) ==
    LET securityAltId == ReadBytes(bytes, 30) IN IF ~securityAltId.ok THEN Fail ELSE
    LET securityAltIdSource == ReadBytes(securityAltId.rest, 3) IN IF ~securityAltIdSource.ok THEN Fail ELSE
    Ok([ securityAltId       |-> securityAltId.value,
         securityAltIdSource |-> securityAltIdSource.value ], securityAltIdSource.rest)

ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroup ==
    [ securityAltId       |-> [i \in 1 .. 30 |-> 0],
      securityAltIdSource |-> [i \in 1 .. 3 |-> 0] ]

(* Security Definition Report Message no Security Alt I D Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportMessageNoSecurityAltIDGroup ==
    { ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroup }
        \cup { [ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroup EXCEPT !.securityAltId = one] : one \in Sample(30) }
        \cup { [ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroup EXCEPT !.securityAltIdSource = one] : one \in Sample(3) }

(* A run of Security Definition Report Message no Security Alt I D Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroupList(_)
EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroup(Head(messages)) \o EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroupList(Tail(messages))

(* As many Security Definition Report Message no Security Alt I D Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionReportMessageNoSecurityAltIDGroupList(_, _)
ReadSecurityDefinitionReportMessageNoSecurityAltIDGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionReportMessageNoSecurityAltIDGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionReportMessageNoSecurityAltIDGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Report Message no Security Alt I D Group of each kind, for the lists that carry them *)
OneSecurityDefinitionReportMessageNoSecurityAltIDGroup == { ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroup }

(***************************************************************************)
(* Security Definition Report Message no Security Alt I D Groups           *)
(***************************************************************************)

SecurityDefinitionReportMessageNoSecurityAltIDGroups ==
    [ blockLength                                         : Sample(2),
      securityDefinitionReportMessageNoSecurityAltIDGroup : SampleLists(OneSecurityDefinitionReportMessageNoSecurityAltIDGroup) ]

EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.securityDefinitionReportMessageNoSecurityAltIDGroup), 2)
        \o EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroupList(message.securityDefinitionReportMessageNoSecurityAltIDGroup)

DecodeSecurityDefinitionReportMessageNoSecurityAltIDGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityDefinitionReportMessageNoSecurityAltIDGroup == ReadSecurityDefinitionReportMessageNoSecurityAltIDGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityDefinitionReportMessageNoSecurityAltIDGroup.ok THEN Fail ELSE
    Ok([ blockLength                                         |-> blockLength.value,
         securityDefinitionReportMessageNoSecurityAltIDGroup |-> securityDefinitionReportMessageNoSecurityAltIDGroup.value ], securityDefinitionReportMessageNoSecurityAltIDGroup.rest)

ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroups ==
    [ blockLength                                         |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionReportMessageNoSecurityAltIDGroup |-> << >> ]

(* Security Definition Report Message no Security Alt I D Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportMessageNoSecurityAltIDGroups ==
    { ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroups }
        \cup { [ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroups EXCEPT !.securityDefinitionReportMessageNoSecurityAltIDGroup = one] : one \in SampleLists(OneSecurityDefinitionReportMessageNoSecurityAltIDGroup) }

(***************************************************************************)
(* Security Id                                                             *)
(***************************************************************************)

SecurityId2 ==
    [ securityIdData : SampleBytes ]

EncodeSecurityId2(message) ==
    EncodeUIntLE(Len(message.securityIdData), 2)
        \o message.securityIdData

DecodeSecurityId2(bytes) ==
    LET securityIdLength == ReadUIntLE(bytes, 2) IN IF ~securityIdLength.ok THEN Fail ELSE
    LET securityIdData == ReadBytes(securityIdLength.rest, securityIdLength.value) IN IF ~securityIdData.ok THEN Fail ELSE
    Ok([ securityIdData |-> securityIdData.value ], securityIdData.rest)

ZeroSecurityId2 ==
    [ securityIdData |-> << >> ]

(* Security Id at zero, then each field in turn at the values it is checked at *)
CheckedSecurityId2 ==
    { ZeroSecurityId2 }
        \cup { [ZeroSecurityId2 EXCEPT !.securityIdData = one] : one \in SampleBytes }

(***************************************************************************)
(* Unit Of Measure                                                         *)
(***************************************************************************)

UnitOfMeasure2 ==
    [ unitOfMeasureData : SampleBytes ]

EncodeUnitOfMeasure2(message) ==
    EncodeUIntLE(Len(message.unitOfMeasureData), 2)
        \o message.unitOfMeasureData

DecodeUnitOfMeasure2(bytes) ==
    LET unitOfMeasureLength == ReadUIntLE(bytes, 2) IN IF ~unitOfMeasureLength.ok THEN Fail ELSE
    LET unitOfMeasureData == ReadBytes(unitOfMeasureLength.rest, unitOfMeasureLength.value) IN IF ~unitOfMeasureData.ok THEN Fail ELSE
    Ok([ unitOfMeasureData |-> unitOfMeasureData.value ], unitOfMeasureData.rest)

ZeroUnitOfMeasure2 ==
    [ unitOfMeasureData |-> << >> ]

(* Unit Of Measure at zero, then each field in turn at the values it is checked at *)
CheckedUnitOfMeasure2 ==
    { ZeroUnitOfMeasure2 }
        \cup { [ZeroUnitOfMeasure2 EXCEPT !.unitOfMeasureData = one] : one \in SampleBytes }

(***************************************************************************)
(* Price Denomination                                                      *)
(***************************************************************************)

PriceDenomination2 ==
    [ priceDenominationData : SampleBytes ]

EncodePriceDenomination2(message) ==
    EncodeUIntLE(Len(message.priceDenominationData), 2)
        \o message.priceDenominationData

DecodePriceDenomination2(bytes) ==
    LET priceDenominationLength == ReadUIntLE(bytes, 2) IN IF ~priceDenominationLength.ok THEN Fail ELSE
    LET priceDenominationData == ReadBytes(priceDenominationLength.rest, priceDenominationLength.value) IN IF ~priceDenominationData.ok THEN Fail ELSE
    Ok([ priceDenominationData |-> priceDenominationData.value ], priceDenominationData.rest)

ZeroPriceDenomination2 ==
    [ priceDenominationData |-> << >> ]

(* Price Denomination at zero, then each field in turn at the values it is checked at *)
CheckedPriceDenomination2 ==
    { ZeroPriceDenomination2 }
        \cup { [ZeroPriceDenomination2 EXCEPT !.priceDenominationData = one] : one \in SampleBytes }

(***************************************************************************)
(* Cleared Alias                                                           *)
(***************************************************************************)

ClearedAlias2 ==
    [ clearedAliasData : SampleBytes ]

EncodeClearedAlias2(message) ==
    EncodeUIntLE(Len(message.clearedAliasData), 2)
        \o message.clearedAliasData

DecodeClearedAlias2(bytes) ==
    LET clearedAliasLength == ReadUIntLE(bytes, 2) IN IF ~clearedAliasLength.ok THEN Fail ELSE
    LET clearedAliasData == ReadBytes(clearedAliasLength.rest, clearedAliasLength.value) IN IF ~clearedAliasData.ok THEN Fail ELSE
    Ok([ clearedAliasData |-> clearedAliasData.value ], clearedAliasData.rest)

ZeroClearedAlias2 ==
    [ clearedAliasData |-> << >> ]

(* Cleared Alias at zero, then each field in turn at the values it is checked at *)
CheckedClearedAlias2 ==
    { ZeroClearedAlias2 }
        \cup { [ZeroClearedAlias2 EXCEPT !.clearedAliasData = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Desc                                                           *)
(***************************************************************************)

SecurityDesc2 ==
    [ securityDescData : SampleBytes ]

EncodeSecurityDesc2(message) ==
    EncodeUIntLE(Len(message.securityDescData), 2)
        \o message.securityDescData

DecodeSecurityDesc2(bytes) ==
    LET securityDescLength == ReadUIntLE(bytes, 2) IN IF ~securityDescLength.ok THEN Fail ELSE
    LET securityDescData == ReadBytes(securityDescLength.rest, securityDescLength.value) IN IF ~securityDescData.ok THEN Fail ELSE
    Ok([ securityDescData |-> securityDescData.value ], securityDescData.rest)

ZeroSecurityDesc2 ==
    [ securityDescData |-> << >> ]

(* Security Desc at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDesc2 ==
    { ZeroSecurityDesc2 }
        \cup { [ZeroSecurityDesc2 EXCEPT !.securityDescData = one] : one \in SampleBytes }

(***************************************************************************)
(* Price Unit                                                              *)
(***************************************************************************)

PriceUnit2 ==
    [ priceUnitData : SampleBytes ]

EncodePriceUnit2(message) ==
    EncodeUIntLE(Len(message.priceUnitData), 2)
        \o message.priceUnitData

DecodePriceUnit2(bytes) ==
    LET priceUnitLength == ReadUIntLE(bytes, 2) IN IF ~priceUnitLength.ok THEN Fail ELSE
    LET priceUnitData == ReadBytes(priceUnitLength.rest, priceUnitLength.value) IN IF ~priceUnitData.ok THEN Fail ELSE
    Ok([ priceUnitData |-> priceUnitData.value ], priceUnitData.rest)

ZeroPriceUnit2 ==
    [ priceUnitData |-> << >> ]

(* Price Unit at zero, then each field in turn at the values it is checked at *)
CheckedPriceUnit2 ==
    { ZeroPriceUnit2 }
        \cup { [ZeroPriceUnit2 EXCEPT !.priceUnitData = one] : one \in SampleBytes }

(***************************************************************************)
(* Strip Name                                                              *)
(***************************************************************************)

StripName2 ==
    [ stripNameData : SampleBytes ]

EncodeStripName2(message) ==
    EncodeUIntLE(Len(message.stripNameData), 2)
        \o message.stripNameData

DecodeStripName2(bytes) ==
    LET stripNameLength == ReadUIntLE(bytes, 2) IN IF ~stripNameLength.ok THEN Fail ELSE
    LET stripNameData == ReadBytes(stripNameLength.rest, stripNameLength.value) IN IF ~stripNameData.ok THEN Fail ELSE
    Ok([ stripNameData |-> stripNameData.value ], stripNameData.rest)

ZeroStripName2 ==
    [ stripNameData |-> << >> ]

(* Strip Name at zero, then each field in turn at the values it is checked at *)
CheckedStripName2 ==
    { ZeroStripName2 }
        \cup { [ZeroStripName2 EXCEPT !.stripNameData = one] : one \in SampleBytes }

(***************************************************************************)
(* Hub Name                                                                *)
(***************************************************************************)

HubName2 ==
    [ hubNameData : SampleBytes ]

EncodeHubName2(message) ==
    EncodeUIntLE(Len(message.hubNameData), 2)
        \o message.hubNameData

DecodeHubName2(bytes) ==
    LET hubNameLength == ReadUIntLE(bytes, 2) IN IF ~hubNameLength.ok THEN Fail ELSE
    LET hubNameData == ReadBytes(hubNameLength.rest, hubNameLength.value) IN IF ~hubNameData.ok THEN Fail ELSE
    Ok([ hubNameData |-> hubNameData.value ], hubNameData.rest)

ZeroHubName2 ==
    [ hubNameData |-> << >> ]

(* Hub Name at zero, then each field in turn at the values it is checked at *)
CheckedHubName2 ==
    { ZeroHubName2 }
        \cup { [ZeroHubName2 EXCEPT !.hubNameData = one] : one \in SampleBytes }

(***************************************************************************)
(* Hub Alias                                                               *)
(***************************************************************************)

HubAlias2 ==
    [ hubAliasData : SampleBytes ]

EncodeHubAlias2(message) ==
    EncodeUIntLE(Len(message.hubAliasData), 2)
        \o message.hubAliasData

DecodeHubAlias2(bytes) ==
    LET hubAliasLength == ReadUIntLE(bytes, 2) IN IF ~hubAliasLength.ok THEN Fail ELSE
    LET hubAliasData == ReadBytes(hubAliasLength.rest, hubAliasLength.value) IN IF ~hubAliasData.ok THEN Fail ELSE
    Ok([ hubAliasData |-> hubAliasData.value ], hubAliasData.rest)

ZeroHubAlias2 ==
    [ hubAliasData |-> << >> ]

(* Hub Alias at zero, then each field in turn at the values it is checked at *)
CheckedHubAlias2 ==
    { ZeroHubAlias2 }
        \cup { [ZeroHubAlias2 EXCEPT !.hubAliasData = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Exchange                                                       *)
(***************************************************************************)

SecurityExchange2 ==
    [ securityExchangeData : SampleBytes ]

EncodeSecurityExchange2(message) ==
    EncodeUIntLE(Len(message.securityExchangeData), 2)
        \o message.securityExchangeData

DecodeSecurityExchange2(bytes) ==
    LET securityExchangeLength == ReadUIntLE(bytes, 2) IN IF ~securityExchangeLength.ok THEN Fail ELSE
    LET securityExchangeData == ReadBytes(securityExchangeLength.rest, securityExchangeLength.value) IN IF ~securityExchangeData.ok THEN Fail ELSE
    Ok([ securityExchangeData |-> securityExchangeData.value ], securityExchangeData.rest)

ZeroSecurityExchange2 ==
    [ securityExchangeData |-> << >> ]

(* Security Exchange at zero, then each field in turn at the values it is checked at *)
CheckedSecurityExchange2 ==
    { ZeroSecurityExchange2 }
        \cup { [ZeroSecurityExchange2 EXCEPT !.securityExchangeData = one] : one \in SampleBytes }

(***************************************************************************)
(* Physical Code                                                           *)
(***************************************************************************)

PhysicalCode2 ==
    [ physicalCodeData : SampleBytes ]

EncodePhysicalCode2(message) ==
    EncodeUIntLE(Len(message.physicalCodeData), 2)
        \o message.physicalCodeData

DecodePhysicalCode2(bytes) ==
    LET physicalCodeLength == ReadUIntLE(bytes, 2) IN IF ~physicalCodeLength.ok THEN Fail ELSE
    LET physicalCodeData == ReadBytes(physicalCodeLength.rest, physicalCodeLength.value) IN IF ~physicalCodeData.ok THEN Fail ELSE
    Ok([ physicalCodeData |-> physicalCodeData.value ], physicalCodeData.rest)

ZeroPhysicalCode2 ==
    [ physicalCodeData |-> << >> ]

(* Physical Code at zero, then each field in turn at the values it is checked at *)
CheckedPhysicalCode2 ==
    { ZeroPhysicalCode2 }
        \cup { [ZeroPhysicalCode2 EXCEPT !.physicalCodeData = one] : one \in SampleBytes }

(***************************************************************************)
(* Home Exchange                                                           *)
(***************************************************************************)

HomeExchange ==
    [ homeExchangeData : SampleBytes ]

EncodeHomeExchange(message) ==
    EncodeUIntLE(Len(message.homeExchangeData), 2)
        \o message.homeExchangeData

DecodeHomeExchange(bytes) ==
    LET homeExchangeLength == ReadUIntLE(bytes, 2) IN IF ~homeExchangeLength.ok THEN Fail ELSE
    LET homeExchangeData == ReadBytes(homeExchangeLength.rest, homeExchangeLength.value) IN IF ~homeExchangeData.ok THEN Fail ELSE
    Ok([ homeExchangeData |-> homeExchangeData.value ], homeExchangeData.rest)

ZeroHomeExchange ==
    [ homeExchangeData |-> << >> ]

(* Home Exchange at zero, then each field in turn at the values it is checked at *)
CheckedHomeExchange ==
    { ZeroHomeExchange }
        \cup { [ZeroHomeExchange EXCEPT !.homeExchangeData = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Definition Report Message                                      *)
(***************************************************************************)

SecurityDefinitionReportMessage ==
    [ securityReqId                                        : Sample(4),
      securityResponseType                                 : Sample(1),
      securityResponseId                                   : Sample(4),
      marketTypeIDInt32                                    : Sample(4),
      symbolInt32                                          : Sample(4),
      exchangeSilo                                         : Sample(1),
      noRpts                                               : Sample(4),
      listSeqNo                                            : Sample(4),
      underlyingSymbolInt32                                : Sample(4),
      cfiCode                                              : Sample(12),
      securitySubTypeInt16Null                             : Sample(2),
      maturityDate                                         : Sample(2),
      screenLastTradeDate                                  : Sample(2),
      contractMultiplier                                   : Sample(4),
      startDate                                            : Sample(2),
      endDate                                              : Sample(2),
      putOrCall                                            : Sample(1),
      strikePrice                                          : Sample(8),
      securityTradingStatus                                : Sample(1),
      currency                                             : Sample(12),
      settlMethod                                          : Sample(1),
      strikeExerciseStyle                                  : Sample(1),
      incrementQty                                         : Sample(8),
      incrementPrice                                       : Sample(8),
      minPrice                                             : Sample(8),
      maxPrice                                             : Sample(8),
      offExchangeIncrementPriceDecimal9                    : Sample(8),
      offExchangeIncrementQtyDecimal9                      : Sample(8),
      screenTickValue                                      : Sample(8),
      blockTickValue                                       : Sample(8),
      lotSize                                              : Sample(4),
      contractSize                                         : Sample(4),
      numOfDecimalPrice                                    : Sample(1),
      numOfDecimalQty                                      : Sample(1),
      granularity                                          : Sample(12),
      baseNumLots                                          : Sample(4),
      tickValue                                            : Sample(8),
      productIDInt32                                       : Sample(4),
      clearable                                            : Sample(1),
      hedgeProductId                                       : Sample(4),
      hedgeMarketId                                        : Sample(4),
      hedgeOnly                                            : Sample(1),
      isDividendAdjusted                                   : Sample(1),
      denominator                                          : Sample(4),
      initialMargin                                        : Sample(4),
      impliedType                                          : Sample(1),
      numOfDecimalStrikePrice                              : Sample(1),
      numOfCyclesInt16                                     : Sample(2),
      lotSizeMultiplierDecimal9                            : Sample(8),
      stripType                                            : Sample(2),
      stripId                                              : Sample(4),
      blockOnly                                            : Sample(1),
      flexAllowed                                          : Sample(1),
      gtAllowed                                            : Sample(1),
      aonAllowed                                           : Sample(1),
      mifidRegulatedMarketBooleanEnumNull                  : Sample(1),
      flexStrikeAllowed                                    : Sample(1),
      hubId                                                : Sample(4),
      overrideBlockMin                                     : Sample(1),
      testMarketIndicatorBooleanEnumNull                   : Sample(1),
      refSprdProductId                                     : Sample(4),
      marketTransparencyType                               : Sample(1),
      nonCommoditizedMarket                                : Sample(1),
      securityDefinitionReportMessageNoBlockDetailsGroups  : SecurityDefinitionReportMessageNoBlockDetailsGroups,
      securityDefinitionReportMessageNoSecurityAltIDGroups : SecurityDefinitionReportMessageNoSecurityAltIDGroups,
      securityId                                           : SecurityId2,
      unitOfMeasure                                        : UnitOfMeasure2,
      priceDenomination                                    : PriceDenomination2,
      clearedAlias                                         : ClearedAlias2,
      securityDesc                                         : SecurityDesc2,
      priceUnit                                            : PriceUnit2,
      stripName                                            : StripName2,
      hubName                                              : HubName2,
      hubAlias                                             : HubAlias2,
      securityExchange                                     : SecurityExchange2,
      physicalCode                                         : PhysicalCode2,
      homeExchange                                         : HomeExchange ]

EncodeSecurityDefinitionReportMessage(message) ==
    message.securityReqId
        \o message.securityResponseType
        \o message.securityResponseId
        \o message.marketTypeIDInt32
        \o message.symbolInt32
        \o message.exchangeSilo
        \o message.noRpts
        \o message.listSeqNo
        \o message.underlyingSymbolInt32
        \o message.cfiCode
        \o message.securitySubTypeInt16Null
        \o message.maturityDate
        \o message.screenLastTradeDate
        \o message.contractMultiplier
        \o message.startDate
        \o message.endDate
        \o message.putOrCall
        \o message.strikePrice
        \o message.securityTradingStatus
        \o message.currency
        \o message.settlMethod
        \o message.strikeExerciseStyle
        \o message.incrementQty
        \o message.incrementPrice
        \o message.minPrice
        \o message.maxPrice
        \o message.offExchangeIncrementPriceDecimal9
        \o message.offExchangeIncrementQtyDecimal9
        \o message.screenTickValue
        \o message.blockTickValue
        \o message.lotSize
        \o message.contractSize
        \o message.numOfDecimalPrice
        \o message.numOfDecimalQty
        \o message.granularity
        \o message.baseNumLots
        \o message.tickValue
        \o message.productIDInt32
        \o message.clearable
        \o message.hedgeProductId
        \o message.hedgeMarketId
        \o message.hedgeOnly
        \o message.isDividendAdjusted
        \o message.denominator
        \o message.initialMargin
        \o message.impliedType
        \o message.numOfDecimalStrikePrice
        \o message.numOfCyclesInt16
        \o message.lotSizeMultiplierDecimal9
        \o message.stripType
        \o message.stripId
        \o message.blockOnly
        \o message.flexAllowed
        \o message.gtAllowed
        \o message.aonAllowed
        \o message.mifidRegulatedMarketBooleanEnumNull
        \o message.flexStrikeAllowed
        \o message.hubId
        \o message.overrideBlockMin
        \o message.testMarketIndicatorBooleanEnumNull
        \o message.refSprdProductId
        \o message.marketTransparencyType
        \o message.nonCommoditizedMarket
        \o EncodeSecurityDefinitionReportMessageNoBlockDetailsGroups(message.securityDefinitionReportMessageNoBlockDetailsGroups)
        \o EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroups(message.securityDefinitionReportMessageNoSecurityAltIDGroups)
        \o EncodeSecurityId2(message.securityId)
        \o EncodeUnitOfMeasure2(message.unitOfMeasure)
        \o EncodePriceDenomination2(message.priceDenomination)
        \o EncodeClearedAlias2(message.clearedAlias)
        \o EncodeSecurityDesc2(message.securityDesc)
        \o EncodePriceUnit2(message.priceUnit)
        \o EncodeStripName2(message.stripName)
        \o EncodeHubName2(message.hubName)
        \o EncodeHubAlias2(message.hubAlias)
        \o EncodeSecurityExchange2(message.securityExchange)
        \o EncodePhysicalCode2(message.physicalCode)
        \o EncodeHomeExchange(message.homeExchange)

DecodeSecurityDefinitionReportMessage(bytes) ==
    LET securityReqId == ReadBytes(bytes, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityResponseType == ReadBytes(securityReqId.rest, 1) IN IF ~securityResponseType.ok THEN Fail ELSE
    LET securityResponseId == ReadBytes(securityResponseType.rest, 4) IN IF ~securityResponseId.ok THEN Fail ELSE
    LET marketTypeIDInt32 == ReadBytes(securityResponseId.rest, 4) IN IF ~marketTypeIDInt32.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(marketTypeIDInt32.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET exchangeSilo == ReadBytes(symbolInt32.rest, 1) IN IF ~exchangeSilo.ok THEN Fail ELSE
    LET noRpts == ReadBytes(exchangeSilo.rest, 4) IN IF ~noRpts.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(noRpts.rest, 4) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET underlyingSymbolInt32 == ReadBytes(listSeqNo.rest, 4) IN IF ~underlyingSymbolInt32.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(underlyingSymbolInt32.rest, 12) IN IF ~cfiCode.ok THEN Fail ELSE
    LET securitySubTypeInt16Null == ReadBytes(cfiCode.rest, 2) IN IF ~securitySubTypeInt16Null.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securitySubTypeInt16Null.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET screenLastTradeDate == ReadBytes(maturityDate.rest, 2) IN IF ~screenLastTradeDate.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(screenLastTradeDate.rest, 4) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET startDate == ReadBytes(contractMultiplier.rest, 2) IN IF ~startDate.ok THEN Fail ELSE
    LET endDate == ReadBytes(startDate.rest, 2) IN IF ~endDate.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(endDate.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(strikePrice.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET currency == ReadBytes(securityTradingStatus.rest, 12) IN IF ~currency.ok THEN Fail ELSE
    LET settlMethod == ReadBytes(currency.rest, 1) IN IF ~settlMethod.ok THEN Fail ELSE
    LET strikeExerciseStyle == ReadBytes(settlMethod.rest, 1) IN IF ~strikeExerciseStyle.ok THEN Fail ELSE
    LET incrementQty == ReadBytes(strikeExerciseStyle.rest, 8) IN IF ~incrementQty.ok THEN Fail ELSE
    LET incrementPrice == ReadBytes(incrementQty.rest, 8) IN IF ~incrementPrice.ok THEN Fail ELSE
    LET minPrice == ReadBytes(incrementPrice.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(minPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET offExchangeIncrementPriceDecimal9 == ReadBytes(maxPrice.rest, 8) IN IF ~offExchangeIncrementPriceDecimal9.ok THEN Fail ELSE
    LET offExchangeIncrementQtyDecimal9 == ReadBytes(offExchangeIncrementPriceDecimal9.rest, 8) IN IF ~offExchangeIncrementQtyDecimal9.ok THEN Fail ELSE
    LET screenTickValue == ReadBytes(offExchangeIncrementQtyDecimal9.rest, 8) IN IF ~screenTickValue.ok THEN Fail ELSE
    LET blockTickValue == ReadBytes(screenTickValue.rest, 8) IN IF ~blockTickValue.ok THEN Fail ELSE
    LET lotSize == ReadBytes(blockTickValue.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET contractSize == ReadBytes(lotSize.rest, 4) IN IF ~contractSize.ok THEN Fail ELSE
    LET numOfDecimalPrice == ReadBytes(contractSize.rest, 1) IN IF ~numOfDecimalPrice.ok THEN Fail ELSE
    LET numOfDecimalQty == ReadBytes(numOfDecimalPrice.rest, 1) IN IF ~numOfDecimalQty.ok THEN Fail ELSE
    LET granularity == ReadBytes(numOfDecimalQty.rest, 12) IN IF ~granularity.ok THEN Fail ELSE
    LET baseNumLots == ReadBytes(granularity.rest, 4) IN IF ~baseNumLots.ok THEN Fail ELSE
    LET tickValue == ReadBytes(baseNumLots.rest, 8) IN IF ~tickValue.ok THEN Fail ELSE
    LET productIDInt32 == ReadBytes(tickValue.rest, 4) IN IF ~productIDInt32.ok THEN Fail ELSE
    LET clearable == ReadBytes(productIDInt32.rest, 1) IN IF ~clearable.ok THEN Fail ELSE
    LET hedgeProductId == ReadBytes(clearable.rest, 4) IN IF ~hedgeProductId.ok THEN Fail ELSE
    LET hedgeMarketId == ReadBytes(hedgeProductId.rest, 4) IN IF ~hedgeMarketId.ok THEN Fail ELSE
    LET hedgeOnly == ReadBytes(hedgeMarketId.rest, 1) IN IF ~hedgeOnly.ok THEN Fail ELSE
    LET isDividendAdjusted == ReadBytes(hedgeOnly.rest, 1) IN IF ~isDividendAdjusted.ok THEN Fail ELSE
    LET denominator == ReadBytes(isDividendAdjusted.rest, 4) IN IF ~denominator.ok THEN Fail ELSE
    LET initialMargin == ReadBytes(denominator.rest, 4) IN IF ~initialMargin.ok THEN Fail ELSE
    LET impliedType == ReadBytes(initialMargin.rest, 1) IN IF ~impliedType.ok THEN Fail ELSE
    LET numOfDecimalStrikePrice == ReadBytes(impliedType.rest, 1) IN IF ~numOfDecimalStrikePrice.ok THEN Fail ELSE
    LET numOfCyclesInt16 == ReadBytes(numOfDecimalStrikePrice.rest, 2) IN IF ~numOfCyclesInt16.ok THEN Fail ELSE
    LET lotSizeMultiplierDecimal9 == ReadBytes(numOfCyclesInt16.rest, 8) IN IF ~lotSizeMultiplierDecimal9.ok THEN Fail ELSE
    LET stripType == ReadBytes(lotSizeMultiplierDecimal9.rest, 2) IN IF ~stripType.ok THEN Fail ELSE
    LET stripId == ReadBytes(stripType.rest, 4) IN IF ~stripId.ok THEN Fail ELSE
    LET blockOnly == ReadBytes(stripId.rest, 1) IN IF ~blockOnly.ok THEN Fail ELSE
    LET flexAllowed == ReadBytes(blockOnly.rest, 1) IN IF ~flexAllowed.ok THEN Fail ELSE
    LET gtAllowed == ReadBytes(flexAllowed.rest, 1) IN IF ~gtAllowed.ok THEN Fail ELSE
    LET aonAllowed == ReadBytes(gtAllowed.rest, 1) IN IF ~aonAllowed.ok THEN Fail ELSE
    LET mifidRegulatedMarketBooleanEnumNull == ReadBytes(aonAllowed.rest, 1) IN IF ~mifidRegulatedMarketBooleanEnumNull.ok THEN Fail ELSE
    LET flexStrikeAllowed == ReadBytes(mifidRegulatedMarketBooleanEnumNull.rest, 1) IN IF ~flexStrikeAllowed.ok THEN Fail ELSE
    LET hubId == ReadBytes(flexStrikeAllowed.rest, 4) IN IF ~hubId.ok THEN Fail ELSE
    LET overrideBlockMin == ReadBytes(hubId.rest, 1) IN IF ~overrideBlockMin.ok THEN Fail ELSE
    LET testMarketIndicatorBooleanEnumNull == ReadBytes(overrideBlockMin.rest, 1) IN IF ~testMarketIndicatorBooleanEnumNull.ok THEN Fail ELSE
    LET refSprdProductId == ReadBytes(testMarketIndicatorBooleanEnumNull.rest, 4) IN IF ~refSprdProductId.ok THEN Fail ELSE
    LET marketTransparencyType == ReadBytes(refSprdProductId.rest, 1) IN IF ~marketTransparencyType.ok THEN Fail ELSE
    LET nonCommoditizedMarket == ReadBytes(marketTransparencyType.rest, 1) IN IF ~nonCommoditizedMarket.ok THEN Fail ELSE
    LET securityDefinitionReportMessageNoBlockDetailsGroups == DecodeSecurityDefinitionReportMessageNoBlockDetailsGroups(nonCommoditizedMarket.rest) IN IF ~securityDefinitionReportMessageNoBlockDetailsGroups.ok THEN Fail ELSE
    LET securityDefinitionReportMessageNoSecurityAltIDGroups == DecodeSecurityDefinitionReportMessageNoSecurityAltIDGroups(securityDefinitionReportMessageNoBlockDetailsGroups.rest) IN IF ~securityDefinitionReportMessageNoSecurityAltIDGroups.ok THEN Fail ELSE
    LET securityId == DecodeSecurityId2(securityDefinitionReportMessageNoSecurityAltIDGroups.rest) IN IF ~securityId.ok THEN Fail ELSE
    LET unitOfMeasure == DecodeUnitOfMeasure2(securityId.rest) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET priceDenomination == DecodePriceDenomination2(unitOfMeasure.rest) IN IF ~priceDenomination.ok THEN Fail ELSE
    LET clearedAlias == DecodeClearedAlias2(priceDenomination.rest) IN IF ~clearedAlias.ok THEN Fail ELSE
    LET securityDesc == DecodeSecurityDesc2(clearedAlias.rest) IN IF ~securityDesc.ok THEN Fail ELSE
    LET priceUnit == DecodePriceUnit2(securityDesc.rest) IN IF ~priceUnit.ok THEN Fail ELSE
    LET stripName == DecodeStripName2(priceUnit.rest) IN IF ~stripName.ok THEN Fail ELSE
    LET hubName == DecodeHubName2(stripName.rest) IN IF ~hubName.ok THEN Fail ELSE
    LET hubAlias == DecodeHubAlias2(hubName.rest) IN IF ~hubAlias.ok THEN Fail ELSE
    LET securityExchange == DecodeSecurityExchange2(hubAlias.rest) IN IF ~securityExchange.ok THEN Fail ELSE
    LET physicalCode == DecodePhysicalCode2(securityExchange.rest) IN IF ~physicalCode.ok THEN Fail ELSE
    LET homeExchange == DecodeHomeExchange(physicalCode.rest) IN IF ~homeExchange.ok THEN Fail ELSE
    Ok([ securityReqId                                        |-> securityReqId.value,
         securityResponseType                                 |-> securityResponseType.value,
         securityResponseId                                   |-> securityResponseId.value,
         marketTypeIDInt32                                    |-> marketTypeIDInt32.value,
         symbolInt32                                          |-> symbolInt32.value,
         exchangeSilo                                         |-> exchangeSilo.value,
         noRpts                                               |-> noRpts.value,
         listSeqNo                                            |-> listSeqNo.value,
         underlyingSymbolInt32                                |-> underlyingSymbolInt32.value,
         cfiCode                                              |-> cfiCode.value,
         securitySubTypeInt16Null                             |-> securitySubTypeInt16Null.value,
         maturityDate                                         |-> maturityDate.value,
         screenLastTradeDate                                  |-> screenLastTradeDate.value,
         contractMultiplier                                   |-> contractMultiplier.value,
         startDate                                            |-> startDate.value,
         endDate                                              |-> endDate.value,
         putOrCall                                            |-> putOrCall.value,
         strikePrice                                          |-> strikePrice.value,
         securityTradingStatus                                |-> securityTradingStatus.value,
         currency                                             |-> currency.value,
         settlMethod                                          |-> settlMethod.value,
         strikeExerciseStyle                                  |-> strikeExerciseStyle.value,
         incrementQty                                         |-> incrementQty.value,
         incrementPrice                                       |-> incrementPrice.value,
         minPrice                                             |-> minPrice.value,
         maxPrice                                             |-> maxPrice.value,
         offExchangeIncrementPriceDecimal9                    |-> offExchangeIncrementPriceDecimal9.value,
         offExchangeIncrementQtyDecimal9                      |-> offExchangeIncrementQtyDecimal9.value,
         screenTickValue                                      |-> screenTickValue.value,
         blockTickValue                                       |-> blockTickValue.value,
         lotSize                                              |-> lotSize.value,
         contractSize                                         |-> contractSize.value,
         numOfDecimalPrice                                    |-> numOfDecimalPrice.value,
         numOfDecimalQty                                      |-> numOfDecimalQty.value,
         granularity                                          |-> granularity.value,
         baseNumLots                                          |-> baseNumLots.value,
         tickValue                                            |-> tickValue.value,
         productIDInt32                                       |-> productIDInt32.value,
         clearable                                            |-> clearable.value,
         hedgeProductId                                       |-> hedgeProductId.value,
         hedgeMarketId                                        |-> hedgeMarketId.value,
         hedgeOnly                                            |-> hedgeOnly.value,
         isDividendAdjusted                                   |-> isDividendAdjusted.value,
         denominator                                          |-> denominator.value,
         initialMargin                                        |-> initialMargin.value,
         impliedType                                          |-> impliedType.value,
         numOfDecimalStrikePrice                              |-> numOfDecimalStrikePrice.value,
         numOfCyclesInt16                                     |-> numOfCyclesInt16.value,
         lotSizeMultiplierDecimal9                            |-> lotSizeMultiplierDecimal9.value,
         stripType                                            |-> stripType.value,
         stripId                                              |-> stripId.value,
         blockOnly                                            |-> blockOnly.value,
         flexAllowed                                          |-> flexAllowed.value,
         gtAllowed                                            |-> gtAllowed.value,
         aonAllowed                                           |-> aonAllowed.value,
         mifidRegulatedMarketBooleanEnumNull                  |-> mifidRegulatedMarketBooleanEnumNull.value,
         flexStrikeAllowed                                    |-> flexStrikeAllowed.value,
         hubId                                                |-> hubId.value,
         overrideBlockMin                                     |-> overrideBlockMin.value,
         testMarketIndicatorBooleanEnumNull                   |-> testMarketIndicatorBooleanEnumNull.value,
         refSprdProductId                                     |-> refSprdProductId.value,
         marketTransparencyType                               |-> marketTransparencyType.value,
         nonCommoditizedMarket                                |-> nonCommoditizedMarket.value,
         securityDefinitionReportMessageNoBlockDetailsGroups  |-> securityDefinitionReportMessageNoBlockDetailsGroups.value,
         securityDefinitionReportMessageNoSecurityAltIDGroups |-> securityDefinitionReportMessageNoSecurityAltIDGroups.value,
         securityId                                           |-> securityId.value,
         unitOfMeasure                                        |-> unitOfMeasure.value,
         priceDenomination                                    |-> priceDenomination.value,
         clearedAlias                                         |-> clearedAlias.value,
         securityDesc                                         |-> securityDesc.value,
         priceUnit                                            |-> priceUnit.value,
         stripName                                            |-> stripName.value,
         hubName                                              |-> hubName.value,
         hubAlias                                             |-> hubAlias.value,
         securityExchange                                     |-> securityExchange.value,
         physicalCode                                         |-> physicalCode.value,
         homeExchange                                         |-> homeExchange.value ], homeExchange.rest)

ZeroSecurityDefinitionReportMessage ==
    [ securityReqId                                        |-> [i \in 1 .. 4 |-> 0],
      securityResponseType                                 |-> [i \in 1 .. 1 |-> 0],
      securityResponseId                                   |-> [i \in 1 .. 4 |-> 0],
      marketTypeIDInt32                                    |-> [i \in 1 .. 4 |-> 0],
      symbolInt32                                          |-> [i \in 1 .. 4 |-> 0],
      exchangeSilo                                         |-> [i \in 1 .. 1 |-> 0],
      noRpts                                               |-> [i \in 1 .. 4 |-> 0],
      listSeqNo                                            |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbolInt32                                |-> [i \in 1 .. 4 |-> 0],
      cfiCode                                              |-> [i \in 1 .. 12 |-> 0],
      securitySubTypeInt16Null                             |-> [i \in 1 .. 2 |-> 0],
      maturityDate                                         |-> [i \in 1 .. 2 |-> 0],
      screenLastTradeDate                                  |-> [i \in 1 .. 2 |-> 0],
      contractMultiplier                                   |-> [i \in 1 .. 4 |-> 0],
      startDate                                            |-> [i \in 1 .. 2 |-> 0],
      endDate                                              |-> [i \in 1 .. 2 |-> 0],
      putOrCall                                            |-> [i \in 1 .. 1 |-> 0],
      strikePrice                                          |-> [i \in 1 .. 8 |-> 0],
      securityTradingStatus                                |-> [i \in 1 .. 1 |-> 0],
      currency                                             |-> [i \in 1 .. 12 |-> 0],
      settlMethod                                          |-> [i \in 1 .. 1 |-> 0],
      strikeExerciseStyle                                  |-> [i \in 1 .. 1 |-> 0],
      incrementQty                                         |-> [i \in 1 .. 8 |-> 0],
      incrementPrice                                       |-> [i \in 1 .. 8 |-> 0],
      minPrice                                             |-> [i \in 1 .. 8 |-> 0],
      maxPrice                                             |-> [i \in 1 .. 8 |-> 0],
      offExchangeIncrementPriceDecimal9                    |-> [i \in 1 .. 8 |-> 0],
      offExchangeIncrementQtyDecimal9                      |-> [i \in 1 .. 8 |-> 0],
      screenTickValue                                      |-> [i \in 1 .. 8 |-> 0],
      blockTickValue                                       |-> [i \in 1 .. 8 |-> 0],
      lotSize                                              |-> [i \in 1 .. 4 |-> 0],
      contractSize                                         |-> [i \in 1 .. 4 |-> 0],
      numOfDecimalPrice                                    |-> [i \in 1 .. 1 |-> 0],
      numOfDecimalQty                                      |-> [i \in 1 .. 1 |-> 0],
      granularity                                          |-> [i \in 1 .. 12 |-> 0],
      baseNumLots                                          |-> [i \in 1 .. 4 |-> 0],
      tickValue                                            |-> [i \in 1 .. 8 |-> 0],
      productIDInt32                                       |-> [i \in 1 .. 4 |-> 0],
      clearable                                            |-> [i \in 1 .. 1 |-> 0],
      hedgeProductId                                       |-> [i \in 1 .. 4 |-> 0],
      hedgeMarketId                                        |-> [i \in 1 .. 4 |-> 0],
      hedgeOnly                                            |-> [i \in 1 .. 1 |-> 0],
      isDividendAdjusted                                   |-> [i \in 1 .. 1 |-> 0],
      denominator                                          |-> [i \in 1 .. 4 |-> 0],
      initialMargin                                        |-> [i \in 1 .. 4 |-> 0],
      impliedType                                          |-> [i \in 1 .. 1 |-> 0],
      numOfDecimalStrikePrice                              |-> [i \in 1 .. 1 |-> 0],
      numOfCyclesInt16                                     |-> [i \in 1 .. 2 |-> 0],
      lotSizeMultiplierDecimal9                            |-> [i \in 1 .. 8 |-> 0],
      stripType                                            |-> [i \in 1 .. 2 |-> 0],
      stripId                                              |-> [i \in 1 .. 4 |-> 0],
      blockOnly                                            |-> [i \in 1 .. 1 |-> 0],
      flexAllowed                                          |-> [i \in 1 .. 1 |-> 0],
      gtAllowed                                            |-> [i \in 1 .. 1 |-> 0],
      aonAllowed                                           |-> [i \in 1 .. 1 |-> 0],
      mifidRegulatedMarketBooleanEnumNull                  |-> [i \in 1 .. 1 |-> 0],
      flexStrikeAllowed                                    |-> [i \in 1 .. 1 |-> 0],
      hubId                                                |-> [i \in 1 .. 4 |-> 0],
      overrideBlockMin                                     |-> [i \in 1 .. 1 |-> 0],
      testMarketIndicatorBooleanEnumNull                   |-> [i \in 1 .. 1 |-> 0],
      refSprdProductId                                     |-> [i \in 1 .. 4 |-> 0],
      marketTransparencyType                               |-> [i \in 1 .. 1 |-> 0],
      nonCommoditizedMarket                                |-> [i \in 1 .. 1 |-> 0],
      securityDefinitionReportMessageNoBlockDetailsGroups  |-> ZeroSecurityDefinitionReportMessageNoBlockDetailsGroups,
      securityDefinitionReportMessageNoSecurityAltIDGroups |-> ZeroSecurityDefinitionReportMessageNoSecurityAltIDGroups,
      securityId                                           |-> ZeroSecurityId2,
      unitOfMeasure                                        |-> ZeroUnitOfMeasure2,
      priceDenomination                                    |-> ZeroPriceDenomination2,
      clearedAlias                                         |-> ZeroClearedAlias2,
      securityDesc                                         |-> ZeroSecurityDesc2,
      priceUnit                                            |-> ZeroPriceUnit2,
      stripName                                            |-> ZeroStripName2,
      hubName                                              |-> ZeroHubName2,
      hubAlias                                             |-> ZeroHubAlias2,
      securityExchange                                     |-> ZeroSecurityExchange2,
      physicalCode                                         |-> ZeroPhysicalCode2,
      homeExchange                                         |-> ZeroHomeExchange ]

(* Security Definition Report Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportMessage ==
    { ZeroSecurityDefinitionReportMessage }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityResponseType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityResponseId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.marketTypeIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.exchangeSilo = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.noRpts = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.listSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.underlyingSymbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.cfiCode = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securitySubTypeInt16Null = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.screenLastTradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.contractMultiplier = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.startDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.endDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.currency = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.settlMethod = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.strikeExerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.incrementQty = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.incrementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.offExchangeIncrementPriceDecimal9 = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.offExchangeIncrementQtyDecimal9 = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.screenTickValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.blockTickValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.contractSize = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.numOfDecimalPrice = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.numOfDecimalQty = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.granularity = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.baseNumLots = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.tickValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.productIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.clearable = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.hedgeProductId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.hedgeMarketId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.hedgeOnly = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.isDividendAdjusted = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.denominator = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.initialMargin = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.impliedType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.numOfDecimalStrikePrice = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.numOfCyclesInt16 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.lotSizeMultiplierDecimal9 = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.stripType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.stripId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.blockOnly = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.flexAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.gtAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.aonAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.mifidRegulatedMarketBooleanEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.flexStrikeAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.hubId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.overrideBlockMin = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.testMarketIndicatorBooleanEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.refSprdProductId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.marketTransparencyType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.nonCommoditizedMarket = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityDefinitionReportMessageNoBlockDetailsGroups = one] : one \in CheckedSecurityDefinitionReportMessageNoBlockDetailsGroups }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityDefinitionReportMessageNoSecurityAltIDGroups = one] : one \in CheckedSecurityDefinitionReportMessageNoSecurityAltIDGroups }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityId = one] : one \in CheckedSecurityId2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.unitOfMeasure = one] : one \in CheckedUnitOfMeasure2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.priceDenomination = one] : one \in CheckedPriceDenomination2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.clearedAlias = one] : one \in CheckedClearedAlias2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityDesc = one] : one \in CheckedSecurityDesc2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.priceUnit = one] : one \in CheckedPriceUnit2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.stripName = one] : one \in CheckedStripName2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.hubName = one] : one \in CheckedHubName2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.hubAlias = one] : one \in CheckedHubAlias2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.securityExchange = one] : one \in CheckedSecurityExchange2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.physicalCode = one] : one \in CheckedPhysicalCode2 }
        \cup { [ZeroSecurityDefinitionReportMessage EXCEPT !.homeExchange = one] : one \in CheckedHomeExchange }

(***************************************************************************)
(* Security Definition Reject Message: 115 bytes                           *)
(***************************************************************************)

SecurityDefinitionRejectMessage ==
    [ securityReqId                    : Sample(4),
      securityResponseType             : Sample(1),
      securityRequestType              : Sample(1),
      marketTypeIDInt32                : Sample(4),
      securityTypeSecurityTypeEnumNull : Sample(1),
      exchangeCode                     : Sample(4),
      text                             : Sample(100) ]

EncodeSecurityDefinitionRejectMessage(message) ==
    message.securityReqId
        \o message.securityResponseType
        \o message.securityRequestType
        \o message.marketTypeIDInt32
        \o message.securityTypeSecurityTypeEnumNull
        \o message.exchangeCode
        \o message.text

DecodeSecurityDefinitionRejectMessage(bytes) ==
    LET securityReqId == ReadBytes(bytes, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityResponseType == ReadBytes(securityReqId.rest, 1) IN IF ~securityResponseType.ok THEN Fail ELSE
    LET securityRequestType == ReadBytes(securityResponseType.rest, 1) IN IF ~securityRequestType.ok THEN Fail ELSE
    LET marketTypeIDInt32 == ReadBytes(securityRequestType.rest, 4) IN IF ~marketTypeIDInt32.ok THEN Fail ELSE
    LET securityTypeSecurityTypeEnumNull == ReadBytes(marketTypeIDInt32.rest, 1) IN IF ~securityTypeSecurityTypeEnumNull.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(securityTypeSecurityTypeEnumNull.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ securityReqId                    |-> securityReqId.value,
         securityResponseType             |-> securityResponseType.value,
         securityRequestType              |-> securityRequestType.value,
         marketTypeIDInt32                |-> marketTypeIDInt32.value,
         securityTypeSecurityTypeEnumNull |-> securityTypeSecurityTypeEnumNull.value,
         exchangeCode                     |-> exchangeCode.value,
         text                             |-> text.value ], text.rest)

ZeroSecurityDefinitionRejectMessage ==
    [ securityReqId                    |-> [i \in 1 .. 4 |-> 0],
      securityResponseType             |-> [i \in 1 .. 1 |-> 0],
      securityRequestType              |-> [i \in 1 .. 1 |-> 0],
      marketTypeIDInt32                |-> [i \in 1 .. 4 |-> 0],
      securityTypeSecurityTypeEnumNull |-> [i \in 1 .. 1 |-> 0],
      exchangeCode                     |-> [i \in 1 .. 4 |-> 0],
      text                             |-> [i \in 1 .. 100 |-> 0] ]

(* Security Definition Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRejectMessage ==
    { ZeroSecurityDefinitionRejectMessage }
        \cup { [ZeroSecurityDefinitionRejectMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRejectMessage EXCEPT !.securityResponseType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRejectMessage EXCEPT !.securityRequestType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRejectMessage EXCEPT !.marketTypeIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRejectMessage EXCEPT !.securityTypeSecurityTypeEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRejectMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRejectMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Security Definition Request Message: 9 bytes                            *)
(***************************************************************************)

SecurityDefinitionRequestMessage ==
    [ securityReqId       : Sample(4),
      securityRequestType : Sample(1),
      marketTypeIDInt32   : Sample(4) ]

EncodeSecurityDefinitionRequestMessage(message) ==
    message.securityReqId
        \o message.securityRequestType
        \o message.marketTypeIDInt32

DecodeSecurityDefinitionRequestMessage(bytes) ==
    LET securityReqId == ReadBytes(bytes, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityRequestType == ReadBytes(securityReqId.rest, 1) IN IF ~securityRequestType.ok THEN Fail ELSE
    LET marketTypeIDInt32 == ReadBytes(securityRequestType.rest, 4) IN IF ~marketTypeIDInt32.ok THEN Fail ELSE
    Ok([ securityReqId       |-> securityReqId.value,
         securityRequestType |-> securityRequestType.value,
         marketTypeIDInt32   |-> marketTypeIDInt32.value ], marketTypeIDInt32.rest)

ZeroSecurityDefinitionRequestMessage ==
    [ securityReqId       |-> [i \in 1 .. 4 |-> 0],
      securityRequestType |-> [i \in 1 .. 1 |-> 0],
      marketTypeIDInt32   |-> [i \in 1 .. 4 |-> 0] ]

(* Security Definition Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRequestMessage ==
    { ZeroSecurityDefinitionRequestMessage }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.securityRequestType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.marketTypeIDInt32 = one] : one \in Sample(4) }

(***************************************************************************)
(* Product Name                                                            *)
(***************************************************************************)

ProductName ==
    [ productNameData : SampleBytes ]

EncodeProductName(message) ==
    EncodeUIntLE(Len(message.productNameData), 2)
        \o message.productNameData

DecodeProductName(bytes) ==
    LET productNameLength == ReadUIntLE(bytes, 2) IN IF ~productNameLength.ok THEN Fail ELSE
    LET productNameData == ReadBytes(productNameLength.rest, productNameLength.value) IN IF ~productNameData.ok THEN Fail ELSE
    Ok([ productNameData |-> productNameData.value ], productNameData.rest)

ZeroProductName ==
    [ productNameData |-> << >> ]

(* Product Name at zero, then each field in turn at the values it is checked at *)
CheckedProductName ==
    { ZeroProductName }
        \cup { [ZeroProductName EXCEPT !.productNameData = one] : one \in SampleBytes }

(***************************************************************************)
(* Product Desc                                                            *)
(***************************************************************************)

ProductDesc ==
    [ productDescData : SampleBytes ]

EncodeProductDesc(message) ==
    EncodeUIntLE(Len(message.productDescData), 2)
        \o message.productDescData

DecodeProductDesc(bytes) ==
    LET productDescLength == ReadUIntLE(bytes, 2) IN IF ~productDescLength.ok THEN Fail ELSE
    LET productDescData == ReadBytes(productDescLength.rest, productDescLength.value) IN IF ~productDescData.ok THEN Fail ELSE
    Ok([ productDescData |-> productDescData.value ], productDescData.rest)

ZeroProductDesc ==
    [ productDescData |-> << >> ]

(* Product Desc at zero, then each field in turn at the values it is checked at *)
CheckedProductDesc ==
    { ZeroProductDesc }
        \cup { [ZeroProductDesc EXCEPT !.productDescData = one] : one \in SampleBytes }

(***************************************************************************)
(* Product Group                                                           *)
(***************************************************************************)

ProductGroup ==
    [ productGroupData : SampleBytes ]

EncodeProductGroup(message) ==
    EncodeUIntLE(Len(message.productGroupData), 2)
        \o message.productGroupData

DecodeProductGroup(bytes) ==
    LET productGroupLength == ReadUIntLE(bytes, 2) IN IF ~productGroupLength.ok THEN Fail ELSE
    LET productGroupData == ReadBytes(productGroupLength.rest, productGroupLength.value) IN IF ~productGroupData.ok THEN Fail ELSE
    Ok([ productGroupData |-> productGroupData.value ], productGroupData.rest)

ZeroProductGroup ==
    [ productGroupData |-> << >> ]

(* Product Group at zero, then each field in turn at the values it is checked at *)
CheckedProductGroup ==
    { ZeroProductGroup }
        \cup { [ZeroProductGroup EXCEPT !.productGroupData = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Definition Report Product Message                              *)
(***************************************************************************)

SecurityDefinitionReportProductMessage ==
    [ securityReqId                   : Sample(4),
      securityResponseType            : Sample(1),
      securityResponseId              : Sample(4),
      marketTypeIDInt32               : Sample(4),
      noRpts                          : Sample(4),
      listSeqNo                       : Sample(4),
      productIDInt32                  : Sample(4),
      productType                     : Sample(12),
      mifidRegulatedMarketBooleanEnum : Sample(1),
      testMarketIndicatorBooleanEnum  : Sample(1),
      stopsAllowed                    : Sample(1),
      optionsAllowed                  : Sample(1),
      udsOptionsAllowed               : Sample(1),
      udsFuturesAllowed               : Sample(1),
      massQuotesAllowed               : Sample(1),
      rfqFuturesAllowed               : Sample(1),
      rfqOptionsAllowed               : Sample(1),
      crossingOrderFuturesAllowed     : Sample(1),
      crossingOrderOptionsAllowed     : Sample(1),
      selfBlockAllowed                : Sample(1),
      productName                     : ProductName,
      productDesc                     : ProductDesc,
      productGroup                    : ProductGroup ]

EncodeSecurityDefinitionReportProductMessage(message) ==
    message.securityReqId
        \o message.securityResponseType
        \o message.securityResponseId
        \o message.marketTypeIDInt32
        \o message.noRpts
        \o message.listSeqNo
        \o message.productIDInt32
        \o message.productType
        \o message.mifidRegulatedMarketBooleanEnum
        \o message.testMarketIndicatorBooleanEnum
        \o message.stopsAllowed
        \o message.optionsAllowed
        \o message.udsOptionsAllowed
        \o message.udsFuturesAllowed
        \o message.massQuotesAllowed
        \o message.rfqFuturesAllowed
        \o message.rfqOptionsAllowed
        \o message.crossingOrderFuturesAllowed
        \o message.crossingOrderOptionsAllowed
        \o message.selfBlockAllowed
        \o EncodeProductName(message.productName)
        \o EncodeProductDesc(message.productDesc)
        \o EncodeProductGroup(message.productGroup)

DecodeSecurityDefinitionReportProductMessage(bytes) ==
    LET securityReqId == ReadBytes(bytes, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityResponseType == ReadBytes(securityReqId.rest, 1) IN IF ~securityResponseType.ok THEN Fail ELSE
    LET securityResponseId == ReadBytes(securityResponseType.rest, 4) IN IF ~securityResponseId.ok THEN Fail ELSE
    LET marketTypeIDInt32 == ReadBytes(securityResponseId.rest, 4) IN IF ~marketTypeIDInt32.ok THEN Fail ELSE
    LET noRpts == ReadBytes(marketTypeIDInt32.rest, 4) IN IF ~noRpts.ok THEN Fail ELSE
    LET listSeqNo == ReadBytes(noRpts.rest, 4) IN IF ~listSeqNo.ok THEN Fail ELSE
    LET productIDInt32 == ReadBytes(listSeqNo.rest, 4) IN IF ~productIDInt32.ok THEN Fail ELSE
    LET productType == ReadBytes(productIDInt32.rest, 12) IN IF ~productType.ok THEN Fail ELSE
    LET mifidRegulatedMarketBooleanEnum == ReadBytes(productType.rest, 1) IN IF ~mifidRegulatedMarketBooleanEnum.ok THEN Fail ELSE
    LET testMarketIndicatorBooleanEnum == ReadBytes(mifidRegulatedMarketBooleanEnum.rest, 1) IN IF ~testMarketIndicatorBooleanEnum.ok THEN Fail ELSE
    LET stopsAllowed == ReadBytes(testMarketIndicatorBooleanEnum.rest, 1) IN IF ~stopsAllowed.ok THEN Fail ELSE
    LET optionsAllowed == ReadBytes(stopsAllowed.rest, 1) IN IF ~optionsAllowed.ok THEN Fail ELSE
    LET udsOptionsAllowed == ReadBytes(optionsAllowed.rest, 1) IN IF ~udsOptionsAllowed.ok THEN Fail ELSE
    LET udsFuturesAllowed == ReadBytes(udsOptionsAllowed.rest, 1) IN IF ~udsFuturesAllowed.ok THEN Fail ELSE
    LET massQuotesAllowed == ReadBytes(udsFuturesAllowed.rest, 1) IN IF ~massQuotesAllowed.ok THEN Fail ELSE
    LET rfqFuturesAllowed == ReadBytes(massQuotesAllowed.rest, 1) IN IF ~rfqFuturesAllowed.ok THEN Fail ELSE
    LET rfqOptionsAllowed == ReadBytes(rfqFuturesAllowed.rest, 1) IN IF ~rfqOptionsAllowed.ok THEN Fail ELSE
    LET crossingOrderFuturesAllowed == ReadBytes(rfqOptionsAllowed.rest, 1) IN IF ~crossingOrderFuturesAllowed.ok THEN Fail ELSE
    LET crossingOrderOptionsAllowed == ReadBytes(crossingOrderFuturesAllowed.rest, 1) IN IF ~crossingOrderOptionsAllowed.ok THEN Fail ELSE
    LET selfBlockAllowed == ReadBytes(crossingOrderOptionsAllowed.rest, 1) IN IF ~selfBlockAllowed.ok THEN Fail ELSE
    LET productName == DecodeProductName(selfBlockAllowed.rest) IN IF ~productName.ok THEN Fail ELSE
    LET productDesc == DecodeProductDesc(productName.rest) IN IF ~productDesc.ok THEN Fail ELSE
    LET productGroup == DecodeProductGroup(productDesc.rest) IN IF ~productGroup.ok THEN Fail ELSE
    Ok([ securityReqId                   |-> securityReqId.value,
         securityResponseType            |-> securityResponseType.value,
         securityResponseId              |-> securityResponseId.value,
         marketTypeIDInt32               |-> marketTypeIDInt32.value,
         noRpts                          |-> noRpts.value,
         listSeqNo                       |-> listSeqNo.value,
         productIDInt32                  |-> productIDInt32.value,
         productType                     |-> productType.value,
         mifidRegulatedMarketBooleanEnum |-> mifidRegulatedMarketBooleanEnum.value,
         testMarketIndicatorBooleanEnum  |-> testMarketIndicatorBooleanEnum.value,
         stopsAllowed                    |-> stopsAllowed.value,
         optionsAllowed                  |-> optionsAllowed.value,
         udsOptionsAllowed               |-> udsOptionsAllowed.value,
         udsFuturesAllowed               |-> udsFuturesAllowed.value,
         massQuotesAllowed               |-> massQuotesAllowed.value,
         rfqFuturesAllowed               |-> rfqFuturesAllowed.value,
         rfqOptionsAllowed               |-> rfqOptionsAllowed.value,
         crossingOrderFuturesAllowed     |-> crossingOrderFuturesAllowed.value,
         crossingOrderOptionsAllowed     |-> crossingOrderOptionsAllowed.value,
         selfBlockAllowed                |-> selfBlockAllowed.value,
         productName                     |-> productName.value,
         productDesc                     |-> productDesc.value,
         productGroup                    |-> productGroup.value ], productGroup.rest)

ZeroSecurityDefinitionReportProductMessage ==
    [ securityReqId                   |-> [i \in 1 .. 4 |-> 0],
      securityResponseType            |-> [i \in 1 .. 1 |-> 0],
      securityResponseId              |-> [i \in 1 .. 4 |-> 0],
      marketTypeIDInt32               |-> [i \in 1 .. 4 |-> 0],
      noRpts                          |-> [i \in 1 .. 4 |-> 0],
      listSeqNo                       |-> [i \in 1 .. 4 |-> 0],
      productIDInt32                  |-> [i \in 1 .. 4 |-> 0],
      productType                     |-> [i \in 1 .. 12 |-> 0],
      mifidRegulatedMarketBooleanEnum |-> [i \in 1 .. 1 |-> 0],
      testMarketIndicatorBooleanEnum  |-> [i \in 1 .. 1 |-> 0],
      stopsAllowed                    |-> [i \in 1 .. 1 |-> 0],
      optionsAllowed                  |-> [i \in 1 .. 1 |-> 0],
      udsOptionsAllowed               |-> [i \in 1 .. 1 |-> 0],
      udsFuturesAllowed               |-> [i \in 1 .. 1 |-> 0],
      massQuotesAllowed               |-> [i \in 1 .. 1 |-> 0],
      rfqFuturesAllowed               |-> [i \in 1 .. 1 |-> 0],
      rfqOptionsAllowed               |-> [i \in 1 .. 1 |-> 0],
      crossingOrderFuturesAllowed     |-> [i \in 1 .. 1 |-> 0],
      crossingOrderOptionsAllowed     |-> [i \in 1 .. 1 |-> 0],
      selfBlockAllowed                |-> [i \in 1 .. 1 |-> 0],
      productName                     |-> ZeroProductName,
      productDesc                     |-> ZeroProductDesc,
      productGroup                    |-> ZeroProductGroup ]

(* Security Definition Report Product Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionReportProductMessage ==
    { ZeroSecurityDefinitionReportProductMessage }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.securityResponseType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.securityResponseId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.marketTypeIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.noRpts = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.listSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.productIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.productType = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.mifidRegulatedMarketBooleanEnum = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.testMarketIndicatorBooleanEnum = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.stopsAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.optionsAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.udsOptionsAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.udsFuturesAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.massQuotesAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.rfqFuturesAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.rfqOptionsAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.crossingOrderFuturesAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.crossingOrderOptionsAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.selfBlockAllowed = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.productName = one] : one \in CheckedProductName }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.productDesc = one] : one \in CheckedProductDesc }
        \cup { [ZeroSecurityDefinitionReportProductMessage EXCEPT !.productGroup = one] : one \in CheckedProductGroup }

(***************************************************************************)
(* I P Request Message no Users Group: 20 bytes                            *)
(***************************************************************************)

IPRequestMessageNoUsersGroup ==
    [ userId : Sample(20) ]

EncodeIPRequestMessageNoUsersGroup(message) ==
    message.userId

DecodeIPRequestMessageNoUsersGroup(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    Ok([ userId |-> userId.value ], userId.rest)

ZeroIPRequestMessageNoUsersGroup ==
    [ userId |-> [i \in 1 .. 20 |-> 0] ]

(* I P Request Message no Users Group at zero, then each field in turn at the values it is checked at *)
CheckedIPRequestMessageNoUsersGroup ==
    { ZeroIPRequestMessageNoUsersGroup }
        \cup { [ZeroIPRequestMessageNoUsersGroup EXCEPT !.userId = one] : one \in Sample(20) }

(* A run of I P Request Message no Users Group, written one after another *)
RECURSIVE EncodeIPRequestMessageNoUsersGroupList(_)
EncodeIPRequestMessageNoUsersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIPRequestMessageNoUsersGroup(Head(messages)) \o EncodeIPRequestMessageNoUsersGroupList(Tail(messages))

(* As many I P Request Message no Users Group as the field that counts them says *)
RECURSIVE ReadIPRequestMessageNoUsersGroupList(_, _)
ReadIPRequestMessageNoUsersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIPRequestMessageNoUsersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIPRequestMessageNoUsersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One I P Request Message no Users Group of each kind, for the lists that carry them *)
OneIPRequestMessageNoUsersGroup == { ZeroIPRequestMessageNoUsersGroup }

(***************************************************************************)
(* I P Request Message no Users Groups                                     *)
(***************************************************************************)

IPRequestMessageNoUsersGroups ==
    [ blockLength                  : Sample(2),
      iPRequestMessageNoUsersGroup : SampleLists(OneIPRequestMessageNoUsersGroup) ]

EncodeIPRequestMessageNoUsersGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.iPRequestMessageNoUsersGroup), 2)
        \o EncodeIPRequestMessageNoUsersGroupList(message.iPRequestMessageNoUsersGroup)

DecodeIPRequestMessageNoUsersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET iPRequestMessageNoUsersGroup == ReadIPRequestMessageNoUsersGroupList(numInGroup.rest, numInGroup.value) IN IF ~iPRequestMessageNoUsersGroup.ok THEN Fail ELSE
    Ok([ blockLength                  |-> blockLength.value,
         iPRequestMessageNoUsersGroup |-> iPRequestMessageNoUsersGroup.value ], iPRequestMessageNoUsersGroup.rest)

ZeroIPRequestMessageNoUsersGroups ==
    [ blockLength                  |-> [i \in 1 .. 2 |-> 0],
      iPRequestMessageNoUsersGroup |-> << >> ]

(* I P Request Message no Users Groups at zero, then each field in turn at the values it is checked at *)
CheckedIPRequestMessageNoUsersGroups ==
    { ZeroIPRequestMessageNoUsersGroups }
        \cup { [ZeroIPRequestMessageNoUsersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIPRequestMessageNoUsersGroups EXCEPT !.iPRequestMessageNoUsersGroup = one] : one \in SampleLists(OneIPRequestMessageNoUsersGroup) }

(***************************************************************************)
(* Ip Request Message                                                      *)
(***************************************************************************)

IpRequestMessage ==
    [ clientId                      : Sample(4),
      iPRequestMessageNoUsersGroups : IPRequestMessageNoUsersGroups ]

EncodeIpRequestMessage(message) ==
    message.clientId
        \o EncodeIPRequestMessageNoUsersGroups(message.iPRequestMessageNoUsersGroups)

DecodeIpRequestMessage(bytes) ==
    LET clientId == ReadBytes(bytes, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET iPRequestMessageNoUsersGroups == DecodeIPRequestMessageNoUsersGroups(clientId.rest) IN IF ~iPRequestMessageNoUsersGroups.ok THEN Fail ELSE
    Ok([ clientId                      |-> clientId.value,
         iPRequestMessageNoUsersGroups |-> iPRequestMessageNoUsersGroups.value ], iPRequestMessageNoUsersGroups.rest)

ZeroIpRequestMessage ==
    [ clientId                      |-> [i \in 1 .. 4 |-> 0],
      iPRequestMessageNoUsersGroups |-> ZeroIPRequestMessageNoUsersGroups ]

(* Ip Request Message at zero, then each field in turn at the values it is checked at *)
CheckedIpRequestMessage ==
    { ZeroIpRequestMessage }
        \cup { [ZeroIpRequestMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroIpRequestMessage EXCEPT !.iPRequestMessageNoUsersGroups = one] : one \in CheckedIPRequestMessageNoUsersGroups }

(***************************************************************************)
(* I P Report Message no Users Group: 88 bytes                             *)
(***************************************************************************)

IPReportMessageNoUsersGroup ==
    [ userId         : Sample(20),
      success        : Sample(1),
      ipAddress      : Sample(15),
      port           : Sample(2),
      ipSessionToken : Sample(50) ]

EncodeIPReportMessageNoUsersGroup(message) ==
    message.userId
        \o message.success
        \o message.ipAddress
        \o message.port
        \o message.ipSessionToken

DecodeIPReportMessageNoUsersGroup(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET success == ReadBytes(userId.rest, 1) IN IF ~success.ok THEN Fail ELSE
    LET ipAddress == ReadBytes(success.rest, 15) IN IF ~ipAddress.ok THEN Fail ELSE
    LET port == ReadBytes(ipAddress.rest, 2) IN IF ~port.ok THEN Fail ELSE
    LET ipSessionToken == ReadBytes(port.rest, 50) IN IF ~ipSessionToken.ok THEN Fail ELSE
    Ok([ userId         |-> userId.value,
         success        |-> success.value,
         ipAddress      |-> ipAddress.value,
         port           |-> port.value,
         ipSessionToken |-> ipSessionToken.value ], ipSessionToken.rest)

ZeroIPReportMessageNoUsersGroup ==
    [ userId         |-> [i \in 1 .. 20 |-> 0],
      success        |-> [i \in 1 .. 1 |-> 0],
      ipAddress      |-> [i \in 1 .. 15 |-> 0],
      port           |-> [i \in 1 .. 2 |-> 0],
      ipSessionToken |-> [i \in 1 .. 50 |-> 0] ]

(* I P Report Message no Users Group at zero, then each field in turn at the values it is checked at *)
CheckedIPReportMessageNoUsersGroup ==
    { ZeroIPReportMessageNoUsersGroup }
        \cup { [ZeroIPReportMessageNoUsersGroup EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroIPReportMessageNoUsersGroup EXCEPT !.success = one] : one \in Sample(1) }
        \cup { [ZeroIPReportMessageNoUsersGroup EXCEPT !.ipAddress = one] : one \in Sample(15) }
        \cup { [ZeroIPReportMessageNoUsersGroup EXCEPT !.port = one] : one \in Sample(2) }
        \cup { [ZeroIPReportMessageNoUsersGroup EXCEPT !.ipSessionToken = one] : one \in Sample(50) }

(* A run of I P Report Message no Users Group, written one after another *)
RECURSIVE EncodeIPReportMessageNoUsersGroupList(_)
EncodeIPReportMessageNoUsersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIPReportMessageNoUsersGroup(Head(messages)) \o EncodeIPReportMessageNoUsersGroupList(Tail(messages))

(* As many I P Report Message no Users Group as the field that counts them says *)
RECURSIVE ReadIPReportMessageNoUsersGroupList(_, _)
ReadIPReportMessageNoUsersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIPReportMessageNoUsersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIPReportMessageNoUsersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One I P Report Message no Users Group of each kind, for the lists that carry them *)
OneIPReportMessageNoUsersGroup == { ZeroIPReportMessageNoUsersGroup }

(***************************************************************************)
(* I P Report Message no Users Groups                                      *)
(***************************************************************************)

IPReportMessageNoUsersGroups ==
    [ blockLength                 : Sample(2),
      iPReportMessageNoUsersGroup : SampleLists(OneIPReportMessageNoUsersGroup) ]

EncodeIPReportMessageNoUsersGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.iPReportMessageNoUsersGroup), 2)
        \o EncodeIPReportMessageNoUsersGroupList(message.iPReportMessageNoUsersGroup)

DecodeIPReportMessageNoUsersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET iPReportMessageNoUsersGroup == ReadIPReportMessageNoUsersGroupList(numInGroup.rest, numInGroup.value) IN IF ~iPReportMessageNoUsersGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         iPReportMessageNoUsersGroup |-> iPReportMessageNoUsersGroup.value ], iPReportMessageNoUsersGroup.rest)

ZeroIPReportMessageNoUsersGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      iPReportMessageNoUsersGroup |-> << >> ]

(* I P Report Message no Users Groups at zero, then each field in turn at the values it is checked at *)
CheckedIPReportMessageNoUsersGroups ==
    { ZeroIPReportMessageNoUsersGroups }
        \cup { [ZeroIPReportMessageNoUsersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIPReportMessageNoUsersGroups EXCEPT !.iPReportMessageNoUsersGroup = one] : one \in SampleLists(OneIPReportMessageNoUsersGroup) }

(***************************************************************************)
(* Ip Report Message                                                       *)
(***************************************************************************)

IpReportMessage ==
    [ exchangeCode                 : Sample(4),
      text                         : Sample(100),
      iPReportMessageNoUsersGroups : IPReportMessageNoUsersGroups ]

EncodeIpReportMessage(message) ==
    message.exchangeCode
        \o message.text
        \o EncodeIPReportMessageNoUsersGroups(message.iPReportMessageNoUsersGroups)

DecodeIpReportMessage(bytes) ==
    LET exchangeCode == ReadBytes(bytes, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    LET iPReportMessageNoUsersGroups == DecodeIPReportMessageNoUsersGroups(text.rest) IN IF ~iPReportMessageNoUsersGroups.ok THEN Fail ELSE
    Ok([ exchangeCode                 |-> exchangeCode.value,
         text                         |-> text.value,
         iPReportMessageNoUsersGroups |-> iPReportMessageNoUsersGroups.value ], iPReportMessageNoUsersGroups.rest)

ZeroIpReportMessage ==
    [ exchangeCode                 |-> [i \in 1 .. 4 |-> 0],
      text                         |-> [i \in 1 .. 100 |-> 0],
      iPReportMessageNoUsersGroups |-> ZeroIPReportMessageNoUsersGroups ]

(* Ip Report Message at zero, then each field in turn at the values it is checked at *)
CheckedIpReportMessage ==
    { ZeroIpReportMessage }
        \cup { [ZeroIpReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroIpReportMessage EXCEPT !.text = one] : one \in Sample(100) }
        \cup { [ZeroIpReportMessage EXCEPT !.iPReportMessageNoUsersGroups = one] : one \in CheckedIPReportMessageNoUsersGroups }

(***************************************************************************)
(* Trader Logon Request Message: 106 bytes                                 *)
(***************************************************************************)

TraderLogonRequestMessage ==
    [ originatorUserId        : Sample(20),
      directElectronicAccess  : Sample(1),
      tradingCapacity         : Sample(1),
      liquidityProvision      : Sample(1),
      commodityDerivIndicator : Sample(1),
      investmentDecision      : Sample(8),
      executionDecision       : Sample(8),
      clientIdCode            : Sample(8),
      mifidId                 : Sample(8),
      rawData                 : Sample(50) ]

EncodeTraderLogonRequestMessage(message) ==
    message.originatorUserId
        \o message.directElectronicAccess
        \o message.tradingCapacity
        \o message.liquidityProvision
        \o message.commodityDerivIndicator
        \o message.investmentDecision
        \o message.executionDecision
        \o message.clientIdCode
        \o message.mifidId
        \o message.rawData

DecodeTraderLogonRequestMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET directElectronicAccess == ReadBytes(originatorUserId.rest, 1) IN IF ~directElectronicAccess.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(directElectronicAccess.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET liquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET commodityDerivIndicator == ReadBytes(liquidityProvision.rest, 1) IN IF ~commodityDerivIndicator.ok THEN Fail ELSE
    LET investmentDecision == ReadBytes(commodityDerivIndicator.rest, 8) IN IF ~investmentDecision.ok THEN Fail ELSE
    LET executionDecision == ReadBytes(investmentDecision.rest, 8) IN IF ~executionDecision.ok THEN Fail ELSE
    LET clientIdCode == ReadBytes(executionDecision.rest, 8) IN IF ~clientIdCode.ok THEN Fail ELSE
    LET mifidId == ReadBytes(clientIdCode.rest, 8) IN IF ~mifidId.ok THEN Fail ELSE
    LET rawData == ReadBytes(mifidId.rest, 50) IN IF ~rawData.ok THEN Fail ELSE
    Ok([ originatorUserId        |-> originatorUserId.value,
         directElectronicAccess  |-> directElectronicAccess.value,
         tradingCapacity         |-> tradingCapacity.value,
         liquidityProvision      |-> liquidityProvision.value,
         commodityDerivIndicator |-> commodityDerivIndicator.value,
         investmentDecision      |-> investmentDecision.value,
         executionDecision       |-> executionDecision.value,
         clientIdCode            |-> clientIdCode.value,
         mifidId                 |-> mifidId.value,
         rawData                 |-> rawData.value ], rawData.rest)

ZeroTraderLogonRequestMessage ==
    [ originatorUserId        |-> [i \in 1 .. 20 |-> 0],
      directElectronicAccess  |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity         |-> [i \in 1 .. 1 |-> 0],
      liquidityProvision      |-> [i \in 1 .. 1 |-> 0],
      commodityDerivIndicator |-> [i \in 1 .. 1 |-> 0],
      investmentDecision      |-> [i \in 1 .. 8 |-> 0],
      executionDecision       |-> [i \in 1 .. 8 |-> 0],
      clientIdCode            |-> [i \in 1 .. 8 |-> 0],
      mifidId                 |-> [i \in 1 .. 8 |-> 0],
      rawData                 |-> [i \in 1 .. 50 |-> 0] ]

(* Trader Logon Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTraderLogonRequestMessage ==
    { ZeroTraderLogonRequestMessage }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.directElectronicAccess = one] : one \in Sample(1) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.liquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.commodityDerivIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.investmentDecision = one] : one \in Sample(8) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.executionDecision = one] : one \in Sample(8) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.clientIdCode = one] : one \in Sample(8) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.mifidId = one] : one \in Sample(8) }
        \cup { [ZeroTraderLogonRequestMessage EXCEPT !.rawData = one] : one \in Sample(50) }

(***************************************************************************)
(* Trader Logon Report Message: 128 bytes                                  *)
(***************************************************************************)

TraderLogonReportMessage ==
    [ originatorUserId : Sample(20),
      clientId         : Sample(4),
      exchangeCode     : Sample(4),
      text             : Sample(100) ]

EncodeTraderLogonReportMessage(message) ==
    message.originatorUserId
        \o message.clientId
        \o message.exchangeCode
        \o message.text

DecodeTraderLogonReportMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET clientId == ReadBytes(originatorUserId.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(clientId.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ originatorUserId |-> originatorUserId.value,
         clientId         |-> clientId.value,
         exchangeCode     |-> exchangeCode.value,
         text             |-> text.value ], text.rest)

ZeroTraderLogonReportMessage ==
    [ originatorUserId |-> [i \in 1 .. 20 |-> 0],
      clientId         |-> [i \in 1 .. 4 |-> 0],
      exchangeCode     |-> [i \in 1 .. 4 |-> 0],
      text             |-> [i \in 1 .. 100 |-> 0] ]

(* Trader Logon Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTraderLogonReportMessage ==
    { ZeroTraderLogonReportMessage }
        \cup { [ZeroTraderLogonReportMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroTraderLogonReportMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroTraderLogonReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroTraderLogonReportMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Trader Logout Request Message: 20 bytes                                 *)
(***************************************************************************)

TraderLogoutRequestMessage ==
    [ originatorUserId : Sample(20) ]

EncodeTraderLogoutRequestMessage(message) ==
    message.originatorUserId

DecodeTraderLogoutRequestMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    Ok([ originatorUserId |-> originatorUserId.value ], originatorUserId.rest)

ZeroTraderLogoutRequestMessage ==
    [ originatorUserId |-> [i \in 1 .. 20 |-> 0] ]

(* Trader Logout Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTraderLogoutRequestMessage ==
    { ZeroTraderLogoutRequestMessage }
        \cup { [ZeroTraderLogoutRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }

(***************************************************************************)
(* Trader Logout Report Message: 124 bytes                                 *)
(***************************************************************************)

TraderLogoutReportMessage ==
    [ originatorUserId : Sample(20),
      exchangeCode     : Sample(4),
      text             : Sample(100) ]

EncodeTraderLogoutReportMessage(message) ==
    message.originatorUserId
        \o message.exchangeCode
        \o message.text

DecodeTraderLogoutReportMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(originatorUserId.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ originatorUserId |-> originatorUserId.value,
         exchangeCode     |-> exchangeCode.value,
         text             |-> text.value ], text.rest)

ZeroTraderLogoutReportMessage ==
    [ originatorUserId |-> [i \in 1 .. 20 |-> 0],
      exchangeCode     |-> [i \in 1 .. 4 |-> 0],
      text             |-> [i \in 1 .. 100 |-> 0] ]

(* Trader Logout Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTraderLogoutReportMessage ==
    { ZeroTraderLogoutReportMessage }
        \cup { [ZeroTraderLogoutReportMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroTraderLogoutReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroTraderLogoutReportMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* New Order Request Message: 327 bytes                                    *)
(***************************************************************************)

NewOrderRequestMessage ==
    [ priceDecimal9Null              : Sample(8),
      orderQtyDecimal9               : Sample(8),
      symbolInt32                    : Sample(4),
      timeInForceTimeInForceEnum     : Sample(1),
      sideSideEnum                   : Sample(1),
      originatorUserId               : Sample(20),
      ordTypeOrderTypeEnum           : Sample(1),
      manualOrderIndicator           : Sample(1),
      clOrdId                        : Sample(8),
      maxShow                        : Sample(8),
      stopPx                         : Sample(8),
      giveUpClearingFirm             : Sample(4),
      clearingFirmInt32              : Sample(4),
      selfMatchPreventionId          : Sample(8),
      expireDate                     : Sample(2),
      selfMatchPreventionInstruction : Sample(1),
      execInst                       : Sample(1),
      directElectronicAccess         : Sample(1),
      tradingCapacity                : Sample(1),
      liquidityProvision             : Sample(1),
      commodityDerivIndicator        : Sample(1),
      investmentDecision             : Sample(8),
      executionDecision              : Sample(8),
      clientIdCode                   : Sample(8),
      mifidId                        : Sample(8),
      custOrderHandlingInst          : Sample(1),
      positionEffect                 : Sample(1),
      allocHandlInst                 : Sample(1),
      priceType                      : Sample(1),
      clearingAccountString14        : Sample(14),
      customerAccountRefId           : Sample(12),
      memo                           : Sample(30),
      allocationAccount              : Sample(20),
      onBehalfOfCompId               : Sample(41),
      onBehalfOfSubIDString41        : Sample(41),
      onBehalfOfLocationIDString41   : Sample(41) ]

EncodeNewOrderRequestMessage(message) ==
    message.priceDecimal9Null
        \o message.orderQtyDecimal9
        \o message.symbolInt32
        \o message.timeInForceTimeInForceEnum
        \o message.sideSideEnum
        \o message.originatorUserId
        \o message.ordTypeOrderTypeEnum
        \o message.manualOrderIndicator
        \o message.clOrdId
        \o message.maxShow
        \o message.stopPx
        \o message.giveUpClearingFirm
        \o message.clearingFirmInt32
        \o message.selfMatchPreventionId
        \o message.expireDate
        \o message.selfMatchPreventionInstruction
        \o message.execInst
        \o message.directElectronicAccess
        \o message.tradingCapacity
        \o message.liquidityProvision
        \o message.commodityDerivIndicator
        \o message.investmentDecision
        \o message.executionDecision
        \o message.clientIdCode
        \o message.mifidId
        \o message.custOrderHandlingInst
        \o message.positionEffect
        \o message.allocHandlInst
        \o message.priceType
        \o message.clearingAccountString14
        \o message.customerAccountRefId
        \o message.memo
        \o message.allocationAccount
        \o message.onBehalfOfCompId
        \o message.onBehalfOfSubIDString41
        \o message.onBehalfOfLocationIDString41

DecodeNewOrderRequestMessage(bytes) ==
    LET priceDecimal9Null == ReadBytes(bytes, 8) IN IF ~priceDecimal9Null.ok THEN Fail ELSE
    LET orderQtyDecimal9 == ReadBytes(priceDecimal9Null.rest, 8) IN IF ~orderQtyDecimal9.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(orderQtyDecimal9.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET timeInForceTimeInForceEnum == ReadBytes(symbolInt32.rest, 1) IN IF ~timeInForceTimeInForceEnum.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(timeInForceTimeInForceEnum.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET originatorUserId == ReadBytes(sideSideEnum.rest, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnum == ReadBytes(originatorUserId.rest, 1) IN IF ~ordTypeOrderTypeEnum.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ordTypeOrderTypeEnum.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(manualOrderIndicator.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET maxShow == ReadBytes(clOrdId.rest, 8) IN IF ~maxShow.ok THEN Fail ELSE
    LET stopPx == ReadBytes(maxShow.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET giveUpClearingFirm == ReadBytes(stopPx.rest, 4) IN IF ~giveUpClearingFirm.ok THEN Fail ELSE
    LET clearingFirmInt32 == ReadBytes(giveUpClearingFirm.rest, 4) IN IF ~clearingFirmInt32.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(clearingFirmInt32.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(selfMatchPreventionId.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(expireDate.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET execInst == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET directElectronicAccess == ReadBytes(execInst.rest, 1) IN IF ~directElectronicAccess.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(directElectronicAccess.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET liquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET commodityDerivIndicator == ReadBytes(liquidityProvision.rest, 1) IN IF ~commodityDerivIndicator.ok THEN Fail ELSE
    LET investmentDecision == ReadBytes(commodityDerivIndicator.rest, 8) IN IF ~investmentDecision.ok THEN Fail ELSE
    LET executionDecision == ReadBytes(investmentDecision.rest, 8) IN IF ~executionDecision.ok THEN Fail ELSE
    LET clientIdCode == ReadBytes(executionDecision.rest, 8) IN IF ~clientIdCode.ok THEN Fail ELSE
    LET mifidId == ReadBytes(clientIdCode.rest, 8) IN IF ~mifidId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(mifidId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(custOrderHandlingInst.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET allocHandlInst == ReadBytes(positionEffect.rest, 1) IN IF ~allocHandlInst.ok THEN Fail ELSE
    LET priceType == ReadBytes(allocHandlInst.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET clearingAccountString14 == ReadBytes(priceType.rest, 14) IN IF ~clearingAccountString14.ok THEN Fail ELSE
    LET customerAccountRefId == ReadBytes(clearingAccountString14.rest, 12) IN IF ~customerAccountRefId.ok THEN Fail ELSE
    LET memo == ReadBytes(customerAccountRefId.rest, 30) IN IF ~memo.ok THEN Fail ELSE
    LET allocationAccount == ReadBytes(memo.rest, 20) IN IF ~allocationAccount.ok THEN Fail ELSE
    LET onBehalfOfCompId == ReadBytes(allocationAccount.rest, 41) IN IF ~onBehalfOfCompId.ok THEN Fail ELSE
    LET onBehalfOfSubIDString41 == ReadBytes(onBehalfOfCompId.rest, 41) IN IF ~onBehalfOfSubIDString41.ok THEN Fail ELSE
    LET onBehalfOfLocationIDString41 == ReadBytes(onBehalfOfSubIDString41.rest, 41) IN IF ~onBehalfOfLocationIDString41.ok THEN Fail ELSE
    Ok([ priceDecimal9Null              |-> priceDecimal9Null.value,
         orderQtyDecimal9               |-> orderQtyDecimal9.value,
         symbolInt32                    |-> symbolInt32.value,
         timeInForceTimeInForceEnum     |-> timeInForceTimeInForceEnum.value,
         sideSideEnum                   |-> sideSideEnum.value,
         originatorUserId               |-> originatorUserId.value,
         ordTypeOrderTypeEnum           |-> ordTypeOrderTypeEnum.value,
         manualOrderIndicator           |-> manualOrderIndicator.value,
         clOrdId                        |-> clOrdId.value,
         maxShow                        |-> maxShow.value,
         stopPx                         |-> stopPx.value,
         giveUpClearingFirm             |-> giveUpClearingFirm.value,
         clearingFirmInt32              |-> clearingFirmInt32.value,
         selfMatchPreventionId          |-> selfMatchPreventionId.value,
         expireDate                     |-> expireDate.value,
         selfMatchPreventionInstruction |-> selfMatchPreventionInstruction.value,
         execInst                       |-> execInst.value,
         directElectronicAccess         |-> directElectronicAccess.value,
         tradingCapacity                |-> tradingCapacity.value,
         liquidityProvision             |-> liquidityProvision.value,
         commodityDerivIndicator        |-> commodityDerivIndicator.value,
         investmentDecision             |-> investmentDecision.value,
         executionDecision              |-> executionDecision.value,
         clientIdCode                   |-> clientIdCode.value,
         mifidId                        |-> mifidId.value,
         custOrderHandlingInst          |-> custOrderHandlingInst.value,
         positionEffect                 |-> positionEffect.value,
         allocHandlInst                 |-> allocHandlInst.value,
         priceType                      |-> priceType.value,
         clearingAccountString14        |-> clearingAccountString14.value,
         customerAccountRefId           |-> customerAccountRefId.value,
         memo                           |-> memo.value,
         allocationAccount              |-> allocationAccount.value,
         onBehalfOfCompId               |-> onBehalfOfCompId.value,
         onBehalfOfSubIDString41        |-> onBehalfOfSubIDString41.value,
         onBehalfOfLocationIDString41   |-> onBehalfOfLocationIDString41.value ], onBehalfOfLocationIDString41.rest)

ZeroNewOrderRequestMessage ==
    [ priceDecimal9Null              |-> [i \in 1 .. 8 |-> 0],
      orderQtyDecimal9               |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                    |-> [i \in 1 .. 4 |-> 0],
      timeInForceTimeInForceEnum     |-> [i \in 1 .. 1 |-> 0],
      sideSideEnum                   |-> [i \in 1 .. 1 |-> 0],
      originatorUserId               |-> [i \in 1 .. 20 |-> 0],
      ordTypeOrderTypeEnum           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator           |-> [i \in 1 .. 1 |-> 0],
      clOrdId                        |-> [i \in 1 .. 8 |-> 0],
      maxShow                        |-> [i \in 1 .. 8 |-> 0],
      stopPx                         |-> [i \in 1 .. 8 |-> 0],
      giveUpClearingFirm             |-> [i \in 1 .. 4 |-> 0],
      clearingFirmInt32              |-> [i \in 1 .. 4 |-> 0],
      selfMatchPreventionId          |-> [i \in 1 .. 8 |-> 0],
      expireDate                     |-> [i \in 1 .. 2 |-> 0],
      selfMatchPreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      execInst                       |-> [i \in 1 .. 1 |-> 0],
      directElectronicAccess         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                |-> [i \in 1 .. 1 |-> 0],
      liquidityProvision             |-> [i \in 1 .. 1 |-> 0],
      commodityDerivIndicator        |-> [i \in 1 .. 1 |-> 0],
      investmentDecision             |-> [i \in 1 .. 8 |-> 0],
      executionDecision              |-> [i \in 1 .. 8 |-> 0],
      clientIdCode                   |-> [i \in 1 .. 8 |-> 0],
      mifidId                        |-> [i \in 1 .. 8 |-> 0],
      custOrderHandlingInst          |-> [i \in 1 .. 1 |-> 0],
      positionEffect                 |-> [i \in 1 .. 1 |-> 0],
      allocHandlInst                 |-> [i \in 1 .. 1 |-> 0],
      priceType                      |-> [i \in 1 .. 1 |-> 0],
      clearingAccountString14        |-> [i \in 1 .. 14 |-> 0],
      customerAccountRefId           |-> [i \in 1 .. 12 |-> 0],
      memo                           |-> [i \in 1 .. 30 |-> 0],
      allocationAccount              |-> [i \in 1 .. 20 |-> 0],
      onBehalfOfCompId               |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfSubIDString41        |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfLocationIDString41   |-> [i \in 1 .. 41 |-> 0] ]

(* New Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderRequestMessage ==
    { ZeroNewOrderRequestMessage }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.priceDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.orderQtyDecimal9 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.timeInForceTimeInForceEnum = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.ordTypeOrderTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.maxShow = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.giveUpClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clearingFirmInt32 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.directElectronicAccess = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.liquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.commodityDerivIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.investmentDecision = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.executionDecision = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clientIdCode = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.mifidId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.allocHandlInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clearingAccountString14 = one] : one \in Sample(14) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.customerAccountRefId = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.memo = one] : one \in Sample(30) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.allocationAccount = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.onBehalfOfCompId = one] : one \in Sample(41) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.onBehalfOfSubIDString41 = one] : one \in Sample(41) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.onBehalfOfLocationIDString41 = one] : one \in Sample(41) }

(***************************************************************************)
(* Cancel Replace Request Message: 333 bytes                               *)
(***************************************************************************)

CancelReplaceRequestMessage ==
    [ priceDecimal9Null              : Sample(8),
      orderQtyDecimal9               : Sample(8),
      symbolInt32                    : Sample(4),
      timeInForceTimeInForceEnum     : Sample(1),
      sideSideEnum                   : Sample(1),
      originatorUserId               : Sample(20),
      ordTypeOrderTypeEnum           : Sample(1),
      manualOrderIndicator           : Sample(1),
      clOrdId                        : Sample(8),
      origClOrdIDInt64               : Sample(8),
      maxShow                        : Sample(8),
      stopPx                         : Sample(8),
      giveUpClearingFirm             : Sample(4),
      clearingFirmInt32              : Sample(4),
      selfMatchPreventionId          : Sample(8),
      expireDate                     : Sample(2),
      selfMatchPreventionInstruction : Sample(1),
      execInst                       : Sample(1),
      directElectronicAccess         : Sample(1),
      tradingCapacity                : Sample(1),
      liquidityProvision             : Sample(1),
      commodityDerivIndicator        : Sample(1),
      investmentDecision             : Sample(8),
      executionDecision              : Sample(8),
      clientIdCode                   : Sample(8),
      mifidId                        : Sample(8),
      allocHandlInst                 : Sample(1),
      priceType                      : Sample(1),
      clearingAccountString14        : Sample(14),
      customerAccountRefId           : Sample(12),
      memo                           : Sample(30),
      allocationAccount              : Sample(20),
      onBehalfOfCompId               : Sample(41),
      onBehalfOfSubIDString41        : Sample(41),
      onBehalfOfLocationIDString41   : Sample(41) ]

EncodeCancelReplaceRequestMessage(message) ==
    message.priceDecimal9Null
        \o message.orderQtyDecimal9
        \o message.symbolInt32
        \o message.timeInForceTimeInForceEnum
        \o message.sideSideEnum
        \o message.originatorUserId
        \o message.ordTypeOrderTypeEnum
        \o message.manualOrderIndicator
        \o message.clOrdId
        \o message.origClOrdIDInt64
        \o message.maxShow
        \o message.stopPx
        \o message.giveUpClearingFirm
        \o message.clearingFirmInt32
        \o message.selfMatchPreventionId
        \o message.expireDate
        \o message.selfMatchPreventionInstruction
        \o message.execInst
        \o message.directElectronicAccess
        \o message.tradingCapacity
        \o message.liquidityProvision
        \o message.commodityDerivIndicator
        \o message.investmentDecision
        \o message.executionDecision
        \o message.clientIdCode
        \o message.mifidId
        \o message.allocHandlInst
        \o message.priceType
        \o message.clearingAccountString14
        \o message.customerAccountRefId
        \o message.memo
        \o message.allocationAccount
        \o message.onBehalfOfCompId
        \o message.onBehalfOfSubIDString41
        \o message.onBehalfOfLocationIDString41

DecodeCancelReplaceRequestMessage(bytes) ==
    LET priceDecimal9Null == ReadBytes(bytes, 8) IN IF ~priceDecimal9Null.ok THEN Fail ELSE
    LET orderQtyDecimal9 == ReadBytes(priceDecimal9Null.rest, 8) IN IF ~orderQtyDecimal9.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(orderQtyDecimal9.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET timeInForceTimeInForceEnum == ReadBytes(symbolInt32.rest, 1) IN IF ~timeInForceTimeInForceEnum.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(timeInForceTimeInForceEnum.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET originatorUserId == ReadBytes(sideSideEnum.rest, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnum == ReadBytes(originatorUserId.rest, 1) IN IF ~ordTypeOrderTypeEnum.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ordTypeOrderTypeEnum.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(manualOrderIndicator.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdIDInt64 == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdIDInt64.ok THEN Fail ELSE
    LET maxShow == ReadBytes(origClOrdIDInt64.rest, 8) IN IF ~maxShow.ok THEN Fail ELSE
    LET stopPx == ReadBytes(maxShow.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET giveUpClearingFirm == ReadBytes(stopPx.rest, 4) IN IF ~giveUpClearingFirm.ok THEN Fail ELSE
    LET clearingFirmInt32 == ReadBytes(giveUpClearingFirm.rest, 4) IN IF ~clearingFirmInt32.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(clearingFirmInt32.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(selfMatchPreventionId.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(expireDate.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET execInst == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET directElectronicAccess == ReadBytes(execInst.rest, 1) IN IF ~directElectronicAccess.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(directElectronicAccess.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET liquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET commodityDerivIndicator == ReadBytes(liquidityProvision.rest, 1) IN IF ~commodityDerivIndicator.ok THEN Fail ELSE
    LET investmentDecision == ReadBytes(commodityDerivIndicator.rest, 8) IN IF ~investmentDecision.ok THEN Fail ELSE
    LET executionDecision == ReadBytes(investmentDecision.rest, 8) IN IF ~executionDecision.ok THEN Fail ELSE
    LET clientIdCode == ReadBytes(executionDecision.rest, 8) IN IF ~clientIdCode.ok THEN Fail ELSE
    LET mifidId == ReadBytes(clientIdCode.rest, 8) IN IF ~mifidId.ok THEN Fail ELSE
    LET allocHandlInst == ReadBytes(mifidId.rest, 1) IN IF ~allocHandlInst.ok THEN Fail ELSE
    LET priceType == ReadBytes(allocHandlInst.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET clearingAccountString14 == ReadBytes(priceType.rest, 14) IN IF ~clearingAccountString14.ok THEN Fail ELSE
    LET customerAccountRefId == ReadBytes(clearingAccountString14.rest, 12) IN IF ~customerAccountRefId.ok THEN Fail ELSE
    LET memo == ReadBytes(customerAccountRefId.rest, 30) IN IF ~memo.ok THEN Fail ELSE
    LET allocationAccount == ReadBytes(memo.rest, 20) IN IF ~allocationAccount.ok THEN Fail ELSE
    LET onBehalfOfCompId == ReadBytes(allocationAccount.rest, 41) IN IF ~onBehalfOfCompId.ok THEN Fail ELSE
    LET onBehalfOfSubIDString41 == ReadBytes(onBehalfOfCompId.rest, 41) IN IF ~onBehalfOfSubIDString41.ok THEN Fail ELSE
    LET onBehalfOfLocationIDString41 == ReadBytes(onBehalfOfSubIDString41.rest, 41) IN IF ~onBehalfOfLocationIDString41.ok THEN Fail ELSE
    Ok([ priceDecimal9Null              |-> priceDecimal9Null.value,
         orderQtyDecimal9               |-> orderQtyDecimal9.value,
         symbolInt32                    |-> symbolInt32.value,
         timeInForceTimeInForceEnum     |-> timeInForceTimeInForceEnum.value,
         sideSideEnum                   |-> sideSideEnum.value,
         originatorUserId               |-> originatorUserId.value,
         ordTypeOrderTypeEnum           |-> ordTypeOrderTypeEnum.value,
         manualOrderIndicator           |-> manualOrderIndicator.value,
         clOrdId                        |-> clOrdId.value,
         origClOrdIDInt64               |-> origClOrdIDInt64.value,
         maxShow                        |-> maxShow.value,
         stopPx                         |-> stopPx.value,
         giveUpClearingFirm             |-> giveUpClearingFirm.value,
         clearingFirmInt32              |-> clearingFirmInt32.value,
         selfMatchPreventionId          |-> selfMatchPreventionId.value,
         expireDate                     |-> expireDate.value,
         selfMatchPreventionInstruction |-> selfMatchPreventionInstruction.value,
         execInst                       |-> execInst.value,
         directElectronicAccess         |-> directElectronicAccess.value,
         tradingCapacity                |-> tradingCapacity.value,
         liquidityProvision             |-> liquidityProvision.value,
         commodityDerivIndicator        |-> commodityDerivIndicator.value,
         investmentDecision             |-> investmentDecision.value,
         executionDecision              |-> executionDecision.value,
         clientIdCode                   |-> clientIdCode.value,
         mifidId                        |-> mifidId.value,
         allocHandlInst                 |-> allocHandlInst.value,
         priceType                      |-> priceType.value,
         clearingAccountString14        |-> clearingAccountString14.value,
         customerAccountRefId           |-> customerAccountRefId.value,
         memo                           |-> memo.value,
         allocationAccount              |-> allocationAccount.value,
         onBehalfOfCompId               |-> onBehalfOfCompId.value,
         onBehalfOfSubIDString41        |-> onBehalfOfSubIDString41.value,
         onBehalfOfLocationIDString41   |-> onBehalfOfLocationIDString41.value ], onBehalfOfLocationIDString41.rest)

ZeroCancelReplaceRequestMessage ==
    [ priceDecimal9Null              |-> [i \in 1 .. 8 |-> 0],
      orderQtyDecimal9               |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                    |-> [i \in 1 .. 4 |-> 0],
      timeInForceTimeInForceEnum     |-> [i \in 1 .. 1 |-> 0],
      sideSideEnum                   |-> [i \in 1 .. 1 |-> 0],
      originatorUserId               |-> [i \in 1 .. 20 |-> 0],
      ordTypeOrderTypeEnum           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator           |-> [i \in 1 .. 1 |-> 0],
      clOrdId                        |-> [i \in 1 .. 8 |-> 0],
      origClOrdIDInt64               |-> [i \in 1 .. 8 |-> 0],
      maxShow                        |-> [i \in 1 .. 8 |-> 0],
      stopPx                         |-> [i \in 1 .. 8 |-> 0],
      giveUpClearingFirm             |-> [i \in 1 .. 4 |-> 0],
      clearingFirmInt32              |-> [i \in 1 .. 4 |-> 0],
      selfMatchPreventionId          |-> [i \in 1 .. 8 |-> 0],
      expireDate                     |-> [i \in 1 .. 2 |-> 0],
      selfMatchPreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      execInst                       |-> [i \in 1 .. 1 |-> 0],
      directElectronicAccess         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                |-> [i \in 1 .. 1 |-> 0],
      liquidityProvision             |-> [i \in 1 .. 1 |-> 0],
      commodityDerivIndicator        |-> [i \in 1 .. 1 |-> 0],
      investmentDecision             |-> [i \in 1 .. 8 |-> 0],
      executionDecision              |-> [i \in 1 .. 8 |-> 0],
      clientIdCode                   |-> [i \in 1 .. 8 |-> 0],
      mifidId                        |-> [i \in 1 .. 8 |-> 0],
      allocHandlInst                 |-> [i \in 1 .. 1 |-> 0],
      priceType                      |-> [i \in 1 .. 1 |-> 0],
      clearingAccountString14        |-> [i \in 1 .. 14 |-> 0],
      customerAccountRefId           |-> [i \in 1 .. 12 |-> 0],
      memo                           |-> [i \in 1 .. 30 |-> 0],
      allocationAccount              |-> [i \in 1 .. 20 |-> 0],
      onBehalfOfCompId               |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfSubIDString41        |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfLocationIDString41   |-> [i \in 1 .. 41 |-> 0] ]

(* Cancel Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelReplaceRequestMessage ==
    { ZeroCancelReplaceRequestMessage }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.priceDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.orderQtyDecimal9 = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.timeInForceTimeInForceEnum = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.ordTypeOrderTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.origClOrdIDInt64 = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.maxShow = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.giveUpClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.clearingFirmInt32 = one] : one \in Sample(4) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.directElectronicAccess = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.liquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.commodityDerivIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.investmentDecision = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.executionDecision = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.clientIdCode = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.mifidId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.allocHandlInst = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.clearingAccountString14 = one] : one \in Sample(14) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.customerAccountRefId = one] : one \in Sample(12) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.memo = one] : one \in Sample(30) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.allocationAccount = one] : one \in Sample(20) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.onBehalfOfCompId = one] : one \in Sample(41) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.onBehalfOfSubIDString41 = one] : one \in Sample(41) }
        \cup { [ZeroCancelReplaceRequestMessage EXCEPT !.onBehalfOfLocationIDString41 = one] : one \in Sample(41) }

(***************************************************************************)
(* Cancel Request Message: 41 bytes                                        *)
(***************************************************************************)

CancelRequestMessage ==
    [ symbolInt32      : Sample(4),
      originatorUserId : Sample(20),
      clOrdId          : Sample(8),
      origClOrdIDInt64 : Sample(8),
      sideSideEnum     : Sample(1) ]

EncodeCancelRequestMessage(message) ==
    message.symbolInt32
        \o message.originatorUserId
        \o message.clOrdId
        \o message.origClOrdIDInt64
        \o message.sideSideEnum

DecodeCancelRequestMessage(bytes) ==
    LET symbolInt32 == ReadBytes(bytes, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET originatorUserId == ReadBytes(symbolInt32.rest, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(originatorUserId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdIDInt64 == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdIDInt64.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(origClOrdIDInt64.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    Ok([ symbolInt32      |-> symbolInt32.value,
         originatorUserId |-> originatorUserId.value,
         clOrdId          |-> clOrdId.value,
         origClOrdIDInt64 |-> origClOrdIDInt64.value,
         sideSideEnum     |-> sideSideEnum.value ], sideSideEnum.rest)

ZeroCancelRequestMessage ==
    [ symbolInt32      |-> [i \in 1 .. 4 |-> 0],
      originatorUserId |-> [i \in 1 .. 20 |-> 0],
      clOrdId          |-> [i \in 1 .. 8 |-> 0],
      origClOrdIDInt64 |-> [i \in 1 .. 8 |-> 0],
      sideSideEnum     |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRequestMessage ==
    { ZeroCancelRequestMessage }
        \cup { [ZeroCancelRequestMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.origClOrdIDInt64 = one] : one \in Sample(8) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Request Message: 182 bytes                                        *)
(***************************************************************************)

QuoteRequestMessage ==
    [ originatorUserId             : Sample(20),
      sideSideEnumNull             : Sample(1),
      orderQtyDecimal9Null         : Sample(8),
      rfqReqId                     : Sample(8),
      symbolInt32                  : Sample(4),
      clearingFirmInt32Null        : Sample(4),
      clearingAccountString14Null  : Sample(14),
      onBehalfOfCompId             : Sample(41),
      onBehalfOfSubIDString41      : Sample(41),
      onBehalfOfLocationIDString41 : Sample(41) ]

EncodeQuoteRequestMessage(message) ==
    message.originatorUserId
        \o message.sideSideEnumNull
        \o message.orderQtyDecimal9Null
        \o message.rfqReqId
        \o message.symbolInt32
        \o message.clearingFirmInt32Null
        \o message.clearingAccountString14Null
        \o message.onBehalfOfCompId
        \o message.onBehalfOfSubIDString41
        \o message.onBehalfOfLocationIDString41

DecodeQuoteRequestMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET sideSideEnumNull == ReadBytes(originatorUserId.rest, 1) IN IF ~sideSideEnumNull.ok THEN Fail ELSE
    LET orderQtyDecimal9Null == ReadBytes(sideSideEnumNull.rest, 8) IN IF ~orderQtyDecimal9Null.ok THEN Fail ELSE
    LET rfqReqId == ReadBytes(orderQtyDecimal9Null.rest, 8) IN IF ~rfqReqId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(rfqReqId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET clearingFirmInt32Null == ReadBytes(symbolInt32.rest, 4) IN IF ~clearingFirmInt32Null.ok THEN Fail ELSE
    LET clearingAccountString14Null == ReadBytes(clearingFirmInt32Null.rest, 14) IN IF ~clearingAccountString14Null.ok THEN Fail ELSE
    LET onBehalfOfCompId == ReadBytes(clearingAccountString14Null.rest, 41) IN IF ~onBehalfOfCompId.ok THEN Fail ELSE
    LET onBehalfOfSubIDString41 == ReadBytes(onBehalfOfCompId.rest, 41) IN IF ~onBehalfOfSubIDString41.ok THEN Fail ELSE
    LET onBehalfOfLocationIDString41 == ReadBytes(onBehalfOfSubIDString41.rest, 41) IN IF ~onBehalfOfLocationIDString41.ok THEN Fail ELSE
    Ok([ originatorUserId             |-> originatorUserId.value,
         sideSideEnumNull             |-> sideSideEnumNull.value,
         orderQtyDecimal9Null         |-> orderQtyDecimal9Null.value,
         rfqReqId                     |-> rfqReqId.value,
         symbolInt32                  |-> symbolInt32.value,
         clearingFirmInt32Null        |-> clearingFirmInt32Null.value,
         clearingAccountString14Null  |-> clearingAccountString14Null.value,
         onBehalfOfCompId             |-> onBehalfOfCompId.value,
         onBehalfOfSubIDString41      |-> onBehalfOfSubIDString41.value,
         onBehalfOfLocationIDString41 |-> onBehalfOfLocationIDString41.value ], onBehalfOfLocationIDString41.rest)

ZeroQuoteRequestMessage ==
    [ originatorUserId             |-> [i \in 1 .. 20 |-> 0],
      sideSideEnumNull             |-> [i \in 1 .. 1 |-> 0],
      orderQtyDecimal9Null         |-> [i \in 1 .. 8 |-> 0],
      rfqReqId                     |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                  |-> [i \in 1 .. 4 |-> 0],
      clearingFirmInt32Null        |-> [i \in 1 .. 4 |-> 0],
      clearingAccountString14Null  |-> [i \in 1 .. 14 |-> 0],
      onBehalfOfCompId             |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfSubIDString41      |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfLocationIDString41 |-> [i \in 1 .. 41 |-> 0] ]

(* Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestMessage ==
    { ZeroQuoteRequestMessage }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.sideSideEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.orderQtyDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.rfqReqId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.clearingFirmInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.clearingAccountString14Null = one] : one \in Sample(14) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.onBehalfOfCompId = one] : one \in Sample(41) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.onBehalfOfSubIDString41 = one] : one \in Sample(41) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.onBehalfOfLocationIDString41 = one] : one \in Sample(41) }

(***************************************************************************)
(* New Order Cross Request Message no Sides Group: 265 bytes               *)
(***************************************************************************)

NewOrderCrossRequestMessageNoSidesGroup ==
    [ sideSideEnum                   : Sample(1),
      clOrdId                        : Sample(8),
      giveUpClearingFirm             : Sample(4),
      clearingFirmInt32              : Sample(4),
      directElectronicAccess         : Sample(1),
      tradingCapacity                : Sample(1),
      liquidityProvision             : Sample(1),
      commodityDerivIndicator        : Sample(1),
      investmentDecision             : Sample(8),
      executionDecision              : Sample(8),
      clientIdCode                   : Sample(8),
      mifidId                        : Sample(8),
      selfMatchPreventionId          : Sample(8),
      selfMatchPreventionInstruction : Sample(1),
      manualOrderIndicator           : Sample(1),
      custOrderHandlingInst          : Sample(1),
      positionEffect                 : Sample(1),
      allocHandlInst                 : Sample(1),
      clearingAccountString14        : Sample(14),
      customerAccountRefId           : Sample(12),
      memo                           : Sample(30),
      allocationAccount              : Sample(20),
      onBehalfOfCompId               : Sample(41),
      onBehalfOfSubIDString41        : Sample(41),
      onBehalfOfLocationIDString41   : Sample(41) ]

EncodeNewOrderCrossRequestMessageNoSidesGroup(message) ==
    message.sideSideEnum
        \o message.clOrdId
        \o message.giveUpClearingFirm
        \o message.clearingFirmInt32
        \o message.directElectronicAccess
        \o message.tradingCapacity
        \o message.liquidityProvision
        \o message.commodityDerivIndicator
        \o message.investmentDecision
        \o message.executionDecision
        \o message.clientIdCode
        \o message.mifidId
        \o message.selfMatchPreventionId
        \o message.selfMatchPreventionInstruction
        \o message.manualOrderIndicator
        \o message.custOrderHandlingInst
        \o message.positionEffect
        \o message.allocHandlInst
        \o message.clearingAccountString14
        \o message.customerAccountRefId
        \o message.memo
        \o message.allocationAccount
        \o message.onBehalfOfCompId
        \o message.onBehalfOfSubIDString41
        \o message.onBehalfOfLocationIDString41

DecodeNewOrderCrossRequestMessageNoSidesGroup(bytes) ==
    LET sideSideEnum == ReadBytes(bytes, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(sideSideEnum.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET giveUpClearingFirm == ReadBytes(clOrdId.rest, 4) IN IF ~giveUpClearingFirm.ok THEN Fail ELSE
    LET clearingFirmInt32 == ReadBytes(giveUpClearingFirm.rest, 4) IN IF ~clearingFirmInt32.ok THEN Fail ELSE
    LET directElectronicAccess == ReadBytes(clearingFirmInt32.rest, 1) IN IF ~directElectronicAccess.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(directElectronicAccess.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET liquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET commodityDerivIndicator == ReadBytes(liquidityProvision.rest, 1) IN IF ~commodityDerivIndicator.ok THEN Fail ELSE
    LET investmentDecision == ReadBytes(commodityDerivIndicator.rest, 8) IN IF ~investmentDecision.ok THEN Fail ELSE
    LET executionDecision == ReadBytes(investmentDecision.rest, 8) IN IF ~executionDecision.ok THEN Fail ELSE
    LET clientIdCode == ReadBytes(executionDecision.rest, 8) IN IF ~clientIdCode.ok THEN Fail ELSE
    LET mifidId == ReadBytes(clientIdCode.rest, 8) IN IF ~mifidId.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(mifidId.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(selfMatchPreventionId.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(custOrderHandlingInst.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET allocHandlInst == ReadBytes(positionEffect.rest, 1) IN IF ~allocHandlInst.ok THEN Fail ELSE
    LET clearingAccountString14 == ReadBytes(allocHandlInst.rest, 14) IN IF ~clearingAccountString14.ok THEN Fail ELSE
    LET customerAccountRefId == ReadBytes(clearingAccountString14.rest, 12) IN IF ~customerAccountRefId.ok THEN Fail ELSE
    LET memo == ReadBytes(customerAccountRefId.rest, 30) IN IF ~memo.ok THEN Fail ELSE
    LET allocationAccount == ReadBytes(memo.rest, 20) IN IF ~allocationAccount.ok THEN Fail ELSE
    LET onBehalfOfCompId == ReadBytes(allocationAccount.rest, 41) IN IF ~onBehalfOfCompId.ok THEN Fail ELSE
    LET onBehalfOfSubIDString41 == ReadBytes(onBehalfOfCompId.rest, 41) IN IF ~onBehalfOfSubIDString41.ok THEN Fail ELSE
    LET onBehalfOfLocationIDString41 == ReadBytes(onBehalfOfSubIDString41.rest, 41) IN IF ~onBehalfOfLocationIDString41.ok THEN Fail ELSE
    Ok([ sideSideEnum                   |-> sideSideEnum.value,
         clOrdId                        |-> clOrdId.value,
         giveUpClearingFirm             |-> giveUpClearingFirm.value,
         clearingFirmInt32              |-> clearingFirmInt32.value,
         directElectronicAccess         |-> directElectronicAccess.value,
         tradingCapacity                |-> tradingCapacity.value,
         liquidityProvision             |-> liquidityProvision.value,
         commodityDerivIndicator        |-> commodityDerivIndicator.value,
         investmentDecision             |-> investmentDecision.value,
         executionDecision              |-> executionDecision.value,
         clientIdCode                   |-> clientIdCode.value,
         mifidId                        |-> mifidId.value,
         selfMatchPreventionId          |-> selfMatchPreventionId.value,
         selfMatchPreventionInstruction |-> selfMatchPreventionInstruction.value,
         manualOrderIndicator           |-> manualOrderIndicator.value,
         custOrderHandlingInst          |-> custOrderHandlingInst.value,
         positionEffect                 |-> positionEffect.value,
         allocHandlInst                 |-> allocHandlInst.value,
         clearingAccountString14        |-> clearingAccountString14.value,
         customerAccountRefId           |-> customerAccountRefId.value,
         memo                           |-> memo.value,
         allocationAccount              |-> allocationAccount.value,
         onBehalfOfCompId               |-> onBehalfOfCompId.value,
         onBehalfOfSubIDString41        |-> onBehalfOfSubIDString41.value,
         onBehalfOfLocationIDString41   |-> onBehalfOfLocationIDString41.value ], onBehalfOfLocationIDString41.rest)

ZeroNewOrderCrossRequestMessageNoSidesGroup ==
    [ sideSideEnum                   |-> [i \in 1 .. 1 |-> 0],
      clOrdId                        |-> [i \in 1 .. 8 |-> 0],
      giveUpClearingFirm             |-> [i \in 1 .. 4 |-> 0],
      clearingFirmInt32              |-> [i \in 1 .. 4 |-> 0],
      directElectronicAccess         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                |-> [i \in 1 .. 1 |-> 0],
      liquidityProvision             |-> [i \in 1 .. 1 |-> 0],
      commodityDerivIndicator        |-> [i \in 1 .. 1 |-> 0],
      investmentDecision             |-> [i \in 1 .. 8 |-> 0],
      executionDecision              |-> [i \in 1 .. 8 |-> 0],
      clientIdCode                   |-> [i \in 1 .. 8 |-> 0],
      mifidId                        |-> [i \in 1 .. 8 |-> 0],
      selfMatchPreventionId          |-> [i \in 1 .. 8 |-> 0],
      selfMatchPreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator           |-> [i \in 1 .. 1 |-> 0],
      custOrderHandlingInst          |-> [i \in 1 .. 1 |-> 0],
      positionEffect                 |-> [i \in 1 .. 1 |-> 0],
      allocHandlInst                 |-> [i \in 1 .. 1 |-> 0],
      clearingAccountString14        |-> [i \in 1 .. 14 |-> 0],
      customerAccountRefId           |-> [i \in 1 .. 12 |-> 0],
      memo                           |-> [i \in 1 .. 30 |-> 0],
      allocationAccount              |-> [i \in 1 .. 20 |-> 0],
      onBehalfOfCompId               |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfSubIDString41        |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfLocationIDString41   |-> [i \in 1 .. 41 |-> 0] ]

(* New Order Cross Request Message no Sides Group at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossRequestMessageNoSidesGroup ==
    { ZeroNewOrderCrossRequestMessageNoSidesGroup }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.giveUpClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.clearingFirmInt32 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.directElectronicAccess = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.liquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.commodityDerivIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.investmentDecision = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.executionDecision = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.clientIdCode = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.mifidId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.allocHandlInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.clearingAccountString14 = one] : one \in Sample(14) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.customerAccountRefId = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.memo = one] : one \in Sample(30) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.allocationAccount = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.onBehalfOfCompId = one] : one \in Sample(41) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.onBehalfOfSubIDString41 = one] : one \in Sample(41) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroup EXCEPT !.onBehalfOfLocationIDString41 = one] : one \in Sample(41) }

(* A run of New Order Cross Request Message no Sides Group, written one after another *)
RECURSIVE EncodeNewOrderCrossRequestMessageNoSidesGroupList(_)
EncodeNewOrderCrossRequestMessageNoSidesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewOrderCrossRequestMessageNoSidesGroup(Head(messages)) \o EncodeNewOrderCrossRequestMessageNoSidesGroupList(Tail(messages))

(* As many New Order Cross Request Message no Sides Group as the field that counts them says *)
RECURSIVE ReadNewOrderCrossRequestMessageNoSidesGroupList(_, _)
ReadNewOrderCrossRequestMessageNoSidesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewOrderCrossRequestMessageNoSidesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewOrderCrossRequestMessageNoSidesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Order Cross Request Message no Sides Group of each kind, for the lists that carry them *)
OneNewOrderCrossRequestMessageNoSidesGroup == { ZeroNewOrderCrossRequestMessageNoSidesGroup }

(***************************************************************************)
(* New Order Cross Request Message no Sides Groups                         *)
(***************************************************************************)

NewOrderCrossRequestMessageNoSidesGroups ==
    [ blockLength                             : Sample(2),
      newOrderCrossRequestMessageNoSidesGroup : SampleLists(OneNewOrderCrossRequestMessageNoSidesGroup) ]

EncodeNewOrderCrossRequestMessageNoSidesGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.newOrderCrossRequestMessageNoSidesGroup), 2)
        \o EncodeNewOrderCrossRequestMessageNoSidesGroupList(message.newOrderCrossRequestMessageNoSidesGroup)

DecodeNewOrderCrossRequestMessageNoSidesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newOrderCrossRequestMessageNoSidesGroup == ReadNewOrderCrossRequestMessageNoSidesGroupList(numInGroup.rest, numInGroup.value) IN IF ~newOrderCrossRequestMessageNoSidesGroup.ok THEN Fail ELSE
    Ok([ blockLength                             |-> blockLength.value,
         newOrderCrossRequestMessageNoSidesGroup |-> newOrderCrossRequestMessageNoSidesGroup.value ], newOrderCrossRequestMessageNoSidesGroup.rest)

ZeroNewOrderCrossRequestMessageNoSidesGroups ==
    [ blockLength                             |-> [i \in 1 .. 2 |-> 0],
      newOrderCrossRequestMessageNoSidesGroup |-> << >> ]

(* New Order Cross Request Message no Sides Groups at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossRequestMessageNoSidesGroups ==
    { ZeroNewOrderCrossRequestMessageNoSidesGroups }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossRequestMessageNoSidesGroups EXCEPT !.newOrderCrossRequestMessageNoSidesGroup = one] : one \in SampleLists(OneNewOrderCrossRequestMessageNoSidesGroup) }

(***************************************************************************)
(* New Order Cross Request Message no Legs Group: 113 bytes                *)
(***************************************************************************)

NewOrderCrossRequestMessageNoLegsGroup ==
    [ legSymbolInt32Null  : Sample(4),
      legSecurityIdSource : Sample(1),
      legOptAttribute     : Sample(4),
      legQty              : Sample(8),
      legPrice            : Sample(8),
      legSecurityType     : Sample(1),
      legMemoField        : Sample(12),
      legSecurityId       : Sample(75) ]

EncodeNewOrderCrossRequestMessageNoLegsGroup(message) ==
    message.legSymbolInt32Null
        \o message.legSecurityIdSource
        \o message.legOptAttribute
        \o message.legQty
        \o message.legPrice
        \o message.legSecurityType
        \o message.legMemoField
        \o message.legSecurityId

DecodeNewOrderCrossRequestMessageNoLegsGroup(bytes) ==
    LET legSymbolInt32Null == ReadBytes(bytes, 4) IN IF ~legSymbolInt32Null.ok THEN Fail ELSE
    LET legSecurityIdSource == ReadBytes(legSymbolInt32Null.rest, 1) IN IF ~legSecurityIdSource.ok THEN Fail ELSE
    LET legOptAttribute == ReadBytes(legSecurityIdSource.rest, 4) IN IF ~legOptAttribute.ok THEN Fail ELSE
    LET legQty == ReadBytes(legOptAttribute.rest, 8) IN IF ~legQty.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legQty.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legPrice.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legMemoField == ReadBytes(legSecurityType.rest, 12) IN IF ~legMemoField.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legMemoField.rest, 75) IN IF ~legSecurityId.ok THEN Fail ELSE
    Ok([ legSymbolInt32Null  |-> legSymbolInt32Null.value,
         legSecurityIdSource |-> legSecurityIdSource.value,
         legOptAttribute     |-> legOptAttribute.value,
         legQty              |-> legQty.value,
         legPrice            |-> legPrice.value,
         legSecurityType     |-> legSecurityType.value,
         legMemoField        |-> legMemoField.value,
         legSecurityId       |-> legSecurityId.value ], legSecurityId.rest)

ZeroNewOrderCrossRequestMessageNoLegsGroup ==
    [ legSymbolInt32Null  |-> [i \in 1 .. 4 |-> 0],
      legSecurityIdSource |-> [i \in 1 .. 1 |-> 0],
      legOptAttribute     |-> [i \in 1 .. 4 |-> 0],
      legQty              |-> [i \in 1 .. 8 |-> 0],
      legPrice            |-> [i \in 1 .. 8 |-> 0],
      legSecurityType     |-> [i \in 1 .. 1 |-> 0],
      legMemoField        |-> [i \in 1 .. 12 |-> 0],
      legSecurityId       |-> [i \in 1 .. 75 |-> 0] ]

(* New Order Cross Request Message no Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossRequestMessageNoLegsGroup ==
    { ZeroNewOrderCrossRequestMessageNoLegsGroup }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroup EXCEPT !.legSymbolInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroup EXCEPT !.legSecurityIdSource = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroup EXCEPT !.legOptAttribute = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroup EXCEPT !.legQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroup EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroup EXCEPT !.legMemoField = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(75) }

(* A run of New Order Cross Request Message no Legs Group, written one after another *)
RECURSIVE EncodeNewOrderCrossRequestMessageNoLegsGroupList(_)
EncodeNewOrderCrossRequestMessageNoLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewOrderCrossRequestMessageNoLegsGroup(Head(messages)) \o EncodeNewOrderCrossRequestMessageNoLegsGroupList(Tail(messages))

(* As many New Order Cross Request Message no Legs Group as the field that counts them says *)
RECURSIVE ReadNewOrderCrossRequestMessageNoLegsGroupList(_, _)
ReadNewOrderCrossRequestMessageNoLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewOrderCrossRequestMessageNoLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewOrderCrossRequestMessageNoLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Order Cross Request Message no Legs Group of each kind, for the lists that carry them *)
OneNewOrderCrossRequestMessageNoLegsGroup == { ZeroNewOrderCrossRequestMessageNoLegsGroup }

(***************************************************************************)
(* New Order Cross Request Message no Legs Groups                          *)
(***************************************************************************)

NewOrderCrossRequestMessageNoLegsGroups ==
    [ blockLength                            : Sample(2),
      newOrderCrossRequestMessageNoLegsGroup : SampleLists(OneNewOrderCrossRequestMessageNoLegsGroup) ]

EncodeNewOrderCrossRequestMessageNoLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.newOrderCrossRequestMessageNoLegsGroup), 2)
        \o EncodeNewOrderCrossRequestMessageNoLegsGroupList(message.newOrderCrossRequestMessageNoLegsGroup)

DecodeNewOrderCrossRequestMessageNoLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newOrderCrossRequestMessageNoLegsGroup == ReadNewOrderCrossRequestMessageNoLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~newOrderCrossRequestMessageNoLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                            |-> blockLength.value,
         newOrderCrossRequestMessageNoLegsGroup |-> newOrderCrossRequestMessageNoLegsGroup.value ], newOrderCrossRequestMessageNoLegsGroup.rest)

ZeroNewOrderCrossRequestMessageNoLegsGroups ==
    [ blockLength                            |-> [i \in 1 .. 2 |-> 0],
      newOrderCrossRequestMessageNoLegsGroup |-> << >> ]

(* New Order Cross Request Message no Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossRequestMessageNoLegsGroups ==
    { ZeroNewOrderCrossRequestMessageNoLegsGroups }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderCrossRequestMessageNoLegsGroups EXCEPT !.newOrderCrossRequestMessageNoLegsGroup = one] : one \in SampleLists(OneNewOrderCrossRequestMessageNoLegsGroup) }

(***************************************************************************)
(* New Order Cross Request Message                                         *)
(***************************************************************************)

NewOrderCrossRequestMessage ==
    [ priceDecimal9                            : Sample(8),
      orderQtyDecimal9                         : Sample(8),
      symbolInt32                              : Sample(4),
      originatorUserId                         : Sample(20),
      ordTypeOrderTypeEnum                     : Sample(1),
      crossIDInt64                             : Sample(8),
      crossTypeCrossTypeEnum                   : Sample(1),
      tradeType                                : Sample(3),
      execInst                                 : Sample(1),
      priceType                                : Sample(1),
      bypassMqr                                : Sample(1),
      hedgeOnly                                : Sample(1),
      benchmarkPrice                           : Sample(8),
      benchMarkPriceType                       : Sample(1),
      timeInForceTimeInForceEnum               : Sample(1),
      transactDetails                          : Sample(100),
      transactTimeUtcTimestamp                 : Sample(8),
      newOrderCrossRequestMessageNoSidesGroups : NewOrderCrossRequestMessageNoSidesGroups,
      newOrderCrossRequestMessageNoLegsGroups  : NewOrderCrossRequestMessageNoLegsGroups ]

EncodeNewOrderCrossRequestMessage(message) ==
    message.priceDecimal9
        \o message.orderQtyDecimal9
        \o message.symbolInt32
        \o message.originatorUserId
        \o message.ordTypeOrderTypeEnum
        \o message.crossIDInt64
        \o message.crossTypeCrossTypeEnum
        \o message.tradeType
        \o message.execInst
        \o message.priceType
        \o message.bypassMqr
        \o message.hedgeOnly
        \o message.benchmarkPrice
        \o message.benchMarkPriceType
        \o message.timeInForceTimeInForceEnum
        \o message.transactDetails
        \o message.transactTimeUtcTimestamp
        \o EncodeNewOrderCrossRequestMessageNoSidesGroups(message.newOrderCrossRequestMessageNoSidesGroups)
        \o EncodeNewOrderCrossRequestMessageNoLegsGroups(message.newOrderCrossRequestMessageNoLegsGroups)

DecodeNewOrderCrossRequestMessage(bytes) ==
    LET priceDecimal9 == ReadBytes(bytes, 8) IN IF ~priceDecimal9.ok THEN Fail ELSE
    LET orderQtyDecimal9 == ReadBytes(priceDecimal9.rest, 8) IN IF ~orderQtyDecimal9.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(orderQtyDecimal9.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET originatorUserId == ReadBytes(symbolInt32.rest, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnum == ReadBytes(originatorUserId.rest, 1) IN IF ~ordTypeOrderTypeEnum.ok THEN Fail ELSE
    LET crossIDInt64 == ReadBytes(ordTypeOrderTypeEnum.rest, 8) IN IF ~crossIDInt64.ok THEN Fail ELSE
    LET crossTypeCrossTypeEnum == ReadBytes(crossIDInt64.rest, 1) IN IF ~crossTypeCrossTypeEnum.ok THEN Fail ELSE
    LET tradeType == ReadBytes(crossTypeCrossTypeEnum.rest, 3) IN IF ~tradeType.ok THEN Fail ELSE
    LET execInst == ReadBytes(tradeType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET priceType == ReadBytes(execInst.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET bypassMqr == ReadBytes(priceType.rest, 1) IN IF ~bypassMqr.ok THEN Fail ELSE
    LET hedgeOnly == ReadBytes(bypassMqr.rest, 1) IN IF ~hedgeOnly.ok THEN Fail ELSE
    LET benchmarkPrice == ReadBytes(hedgeOnly.rest, 8) IN IF ~benchmarkPrice.ok THEN Fail ELSE
    LET benchMarkPriceType == ReadBytes(benchmarkPrice.rest, 1) IN IF ~benchMarkPriceType.ok THEN Fail ELSE
    LET timeInForceTimeInForceEnum == ReadBytes(benchMarkPriceType.rest, 1) IN IF ~timeInForceTimeInForceEnum.ok THEN Fail ELSE
    LET transactDetails == ReadBytes(timeInForceTimeInForceEnum.rest, 100) IN IF ~transactDetails.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(transactDetails.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    LET newOrderCrossRequestMessageNoSidesGroups == DecodeNewOrderCrossRequestMessageNoSidesGroups(transactTimeUtcTimestamp.rest) IN IF ~newOrderCrossRequestMessageNoSidesGroups.ok THEN Fail ELSE
    LET newOrderCrossRequestMessageNoLegsGroups == DecodeNewOrderCrossRequestMessageNoLegsGroups(newOrderCrossRequestMessageNoSidesGroups.rest) IN IF ~newOrderCrossRequestMessageNoLegsGroups.ok THEN Fail ELSE
    Ok([ priceDecimal9                            |-> priceDecimal9.value,
         orderQtyDecimal9                         |-> orderQtyDecimal9.value,
         symbolInt32                              |-> symbolInt32.value,
         originatorUserId                         |-> originatorUserId.value,
         ordTypeOrderTypeEnum                     |-> ordTypeOrderTypeEnum.value,
         crossIDInt64                             |-> crossIDInt64.value,
         crossTypeCrossTypeEnum                   |-> crossTypeCrossTypeEnum.value,
         tradeType                                |-> tradeType.value,
         execInst                                 |-> execInst.value,
         priceType                                |-> priceType.value,
         bypassMqr                                |-> bypassMqr.value,
         hedgeOnly                                |-> hedgeOnly.value,
         benchmarkPrice                           |-> benchmarkPrice.value,
         benchMarkPriceType                       |-> benchMarkPriceType.value,
         timeInForceTimeInForceEnum               |-> timeInForceTimeInForceEnum.value,
         transactDetails                          |-> transactDetails.value,
         transactTimeUtcTimestamp                 |-> transactTimeUtcTimestamp.value,
         newOrderCrossRequestMessageNoSidesGroups |-> newOrderCrossRequestMessageNoSidesGroups.value,
         newOrderCrossRequestMessageNoLegsGroups  |-> newOrderCrossRequestMessageNoLegsGroups.value ], newOrderCrossRequestMessageNoLegsGroups.rest)

ZeroNewOrderCrossRequestMessage ==
    [ priceDecimal9                            |-> [i \in 1 .. 8 |-> 0],
      orderQtyDecimal9                         |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                              |-> [i \in 1 .. 4 |-> 0],
      originatorUserId                         |-> [i \in 1 .. 20 |-> 0],
      ordTypeOrderTypeEnum                     |-> [i \in 1 .. 1 |-> 0],
      crossIDInt64                             |-> [i \in 1 .. 8 |-> 0],
      crossTypeCrossTypeEnum                   |-> [i \in 1 .. 1 |-> 0],
      tradeType                                |-> [i \in 1 .. 3 |-> 0],
      execInst                                 |-> [i \in 1 .. 1 |-> 0],
      priceType                                |-> [i \in 1 .. 1 |-> 0],
      bypassMqr                                |-> [i \in 1 .. 1 |-> 0],
      hedgeOnly                                |-> [i \in 1 .. 1 |-> 0],
      benchmarkPrice                           |-> [i \in 1 .. 8 |-> 0],
      benchMarkPriceType                       |-> [i \in 1 .. 1 |-> 0],
      timeInForceTimeInForceEnum               |-> [i \in 1 .. 1 |-> 0],
      transactDetails                          |-> [i \in 1 .. 100 |-> 0],
      transactTimeUtcTimestamp                 |-> [i \in 1 .. 8 |-> 0],
      newOrderCrossRequestMessageNoSidesGroups |-> ZeroNewOrderCrossRequestMessageNoSidesGroups,
      newOrderCrossRequestMessageNoLegsGroups  |-> ZeroNewOrderCrossRequestMessageNoLegsGroups ]

(* New Order Cross Request Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossRequestMessage ==
    { ZeroNewOrderCrossRequestMessage }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.priceDecimal9 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.orderQtyDecimal9 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.ordTypeOrderTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.crossIDInt64 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.crossTypeCrossTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.tradeType = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.bypassMqr = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.hedgeOnly = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.benchmarkPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.benchMarkPriceType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.timeInForceTimeInForceEnum = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.transactDetails = one] : one \in Sample(100) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.newOrderCrossRequestMessageNoSidesGroups = one] : one \in CheckedNewOrderCrossRequestMessageNoSidesGroups }
        \cup { [ZeroNewOrderCrossRequestMessage EXCEPT !.newOrderCrossRequestMessageNoLegsGroups = one] : one \in CheckedNewOrderCrossRequestMessageNoLegsGroups }

(***************************************************************************)
(* Order Mass Cancel Request Message: 89 bytes                             *)
(***************************************************************************)

OrderMassCancelRequestMessage ==
    [ originatorUserId               : Sample(20),
      ordTypeOrderTypeEnumNull       : Sample(1),
      sideSideEnumNull               : Sample(1),
      symbolInt32Null                : Sample(4),
      clOrdId                        : Sample(8),
      marketTypeIDInt32Null          : Sample(4),
      priceDecimal9Null              : Sample(8),
      massCancelRequestType          : Sample(1),
      timeInForceTimeInForceEnumNull : Sample(1),
      onBehalfOfSubIDString41Null    : Sample(41) ]

EncodeOrderMassCancelRequestMessage(message) ==
    message.originatorUserId
        \o message.ordTypeOrderTypeEnumNull
        \o message.sideSideEnumNull
        \o message.symbolInt32Null
        \o message.clOrdId
        \o message.marketTypeIDInt32Null
        \o message.priceDecimal9Null
        \o message.massCancelRequestType
        \o message.timeInForceTimeInForceEnumNull
        \o message.onBehalfOfSubIDString41Null

DecodeOrderMassCancelRequestMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnumNull == ReadBytes(originatorUserId.rest, 1) IN IF ~ordTypeOrderTypeEnumNull.ok THEN Fail ELSE
    LET sideSideEnumNull == ReadBytes(ordTypeOrderTypeEnumNull.rest, 1) IN IF ~sideSideEnumNull.ok THEN Fail ELSE
    LET symbolInt32Null == ReadBytes(sideSideEnumNull.rest, 4) IN IF ~symbolInt32Null.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(symbolInt32Null.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET marketTypeIDInt32Null == ReadBytes(clOrdId.rest, 4) IN IF ~marketTypeIDInt32Null.ok THEN Fail ELSE
    LET priceDecimal9Null == ReadBytes(marketTypeIDInt32Null.rest, 8) IN IF ~priceDecimal9Null.ok THEN Fail ELSE
    LET massCancelRequestType == ReadBytes(priceDecimal9Null.rest, 1) IN IF ~massCancelRequestType.ok THEN Fail ELSE
    LET timeInForceTimeInForceEnumNull == ReadBytes(massCancelRequestType.rest, 1) IN IF ~timeInForceTimeInForceEnumNull.ok THEN Fail ELSE
    LET onBehalfOfSubIDString41Null == ReadBytes(timeInForceTimeInForceEnumNull.rest, 41) IN IF ~onBehalfOfSubIDString41Null.ok THEN Fail ELSE
    Ok([ originatorUserId               |-> originatorUserId.value,
         ordTypeOrderTypeEnumNull       |-> ordTypeOrderTypeEnumNull.value,
         sideSideEnumNull               |-> sideSideEnumNull.value,
         symbolInt32Null                |-> symbolInt32Null.value,
         clOrdId                        |-> clOrdId.value,
         marketTypeIDInt32Null          |-> marketTypeIDInt32Null.value,
         priceDecimal9Null              |-> priceDecimal9Null.value,
         massCancelRequestType          |-> massCancelRequestType.value,
         timeInForceTimeInForceEnumNull |-> timeInForceTimeInForceEnumNull.value,
         onBehalfOfSubIDString41Null    |-> onBehalfOfSubIDString41Null.value ], onBehalfOfSubIDString41Null.rest)

ZeroOrderMassCancelRequestMessage ==
    [ originatorUserId               |-> [i \in 1 .. 20 |-> 0],
      ordTypeOrderTypeEnumNull       |-> [i \in 1 .. 1 |-> 0],
      sideSideEnumNull               |-> [i \in 1 .. 1 |-> 0],
      symbolInt32Null                |-> [i \in 1 .. 4 |-> 0],
      clOrdId                        |-> [i \in 1 .. 8 |-> 0],
      marketTypeIDInt32Null          |-> [i \in 1 .. 4 |-> 0],
      priceDecimal9Null              |-> [i \in 1 .. 8 |-> 0],
      massCancelRequestType          |-> [i \in 1 .. 1 |-> 0],
      timeInForceTimeInForceEnumNull |-> [i \in 1 .. 1 |-> 0],
      onBehalfOfSubIDString41Null    |-> [i \in 1 .. 41 |-> 0] ]

(* Order Mass Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelRequestMessage ==
    { ZeroOrderMassCancelRequestMessage }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.ordTypeOrderTypeEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.sideSideEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.symbolInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.marketTypeIDInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.priceDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.massCancelRequestType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.timeInForceTimeInForceEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.onBehalfOfSubIDString41Null = one] : one \in Sample(41) }

(***************************************************************************)
(* Mass Quote Request Message no Quote Sets Group: 48 bytes                *)
(***************************************************************************)

MassQuoteRequestMessageNoQuoteSetsGroup ==
    [ quoteSetId            : Sample(4),
      underlyingSymbolInt32 : Sample(4),
      quoteEntryId          : Sample(4),
      symbolInt32           : Sample(4),
      bidPx                 : Sample(8),
      offerPx               : Sample(8),
      bidSz                 : Sample(8),
      offerSz               : Sample(8) ]

EncodeMassQuoteRequestMessageNoQuoteSetsGroup(message) ==
    message.quoteSetId
        \o message.underlyingSymbolInt32
        \o message.quoteEntryId
        \o message.symbolInt32
        \o message.bidPx
        \o message.offerPx
        \o message.bidSz
        \o message.offerSz

DecodeMassQuoteRequestMessageNoQuoteSetsGroup(bytes) ==
    LET quoteSetId == ReadBytes(bytes, 4) IN IF ~quoteSetId.ok THEN Fail ELSE
    LET underlyingSymbolInt32 == ReadBytes(quoteSetId.rest, 4) IN IF ~underlyingSymbolInt32.ok THEN Fail ELSE
    LET quoteEntryId == ReadBytes(underlyingSymbolInt32.rest, 4) IN IF ~quoteEntryId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(quoteEntryId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET bidPx == ReadBytes(symbolInt32.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSz == ReadBytes(offerPx.rest, 8) IN IF ~bidSz.ok THEN Fail ELSE
    LET offerSz == ReadBytes(bidSz.rest, 8) IN IF ~offerSz.ok THEN Fail ELSE
    Ok([ quoteSetId            |-> quoteSetId.value,
         underlyingSymbolInt32 |-> underlyingSymbolInt32.value,
         quoteEntryId          |-> quoteEntryId.value,
         symbolInt32           |-> symbolInt32.value,
         bidPx                 |-> bidPx.value,
         offerPx               |-> offerPx.value,
         bidSz                 |-> bidSz.value,
         offerSz               |-> offerSz.value ], offerSz.rest)

ZeroMassQuoteRequestMessageNoQuoteSetsGroup ==
    [ quoteSetId            |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbolInt32 |-> [i \in 1 .. 4 |-> 0],
      quoteEntryId          |-> [i \in 1 .. 4 |-> 0],
      symbolInt32           |-> [i \in 1 .. 4 |-> 0],
      bidPx                 |-> [i \in 1 .. 8 |-> 0],
      offerPx               |-> [i \in 1 .. 8 |-> 0],
      bidSz                 |-> [i \in 1 .. 8 |-> 0],
      offerSz               |-> [i \in 1 .. 8 |-> 0] ]

(* Mass Quote Request Message no Quote Sets Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequestMessageNoQuoteSetsGroup ==
    { ZeroMassQuoteRequestMessageNoQuoteSetsGroup }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroup EXCEPT !.quoteSetId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroup EXCEPT !.underlyingSymbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroup EXCEPT !.quoteEntryId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroup EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroup EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroup EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroup EXCEPT !.bidSz = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroup EXCEPT !.offerSz = one] : one \in Sample(8) }

(* A run of Mass Quote Request Message no Quote Sets Group, written one after another *)
RECURSIVE EncodeMassQuoteRequestMessageNoQuoteSetsGroupList(_)
EncodeMassQuoteRequestMessageNoQuoteSetsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteRequestMessageNoQuoteSetsGroup(Head(messages)) \o EncodeMassQuoteRequestMessageNoQuoteSetsGroupList(Tail(messages))

(* As many Mass Quote Request Message no Quote Sets Group as the field that counts them says *)
RECURSIVE ReadMassQuoteRequestMessageNoQuoteSetsGroupList(_, _)
ReadMassQuoteRequestMessageNoQuoteSetsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteRequestMessageNoQuoteSetsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteRequestMessageNoQuoteSetsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Request Message no Quote Sets Group of each kind, for the lists that carry them *)
OneMassQuoteRequestMessageNoQuoteSetsGroup == { ZeroMassQuoteRequestMessageNoQuoteSetsGroup }

(***************************************************************************)
(* Mass Quote Request Message no Quote Sets Groups                         *)
(***************************************************************************)

MassQuoteRequestMessageNoQuoteSetsGroups ==
    [ blockLength                             : Sample(2),
      massQuoteRequestMessageNoQuoteSetsGroup : SampleLists(OneMassQuoteRequestMessageNoQuoteSetsGroup) ]

EncodeMassQuoteRequestMessageNoQuoteSetsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteRequestMessageNoQuoteSetsGroup), 2)
        \o EncodeMassQuoteRequestMessageNoQuoteSetsGroupList(message.massQuoteRequestMessageNoQuoteSetsGroup)

DecodeMassQuoteRequestMessageNoQuoteSetsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteRequestMessageNoQuoteSetsGroup == ReadMassQuoteRequestMessageNoQuoteSetsGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteRequestMessageNoQuoteSetsGroup.ok THEN Fail ELSE
    Ok([ blockLength                             |-> blockLength.value,
         massQuoteRequestMessageNoQuoteSetsGroup |-> massQuoteRequestMessageNoQuoteSetsGroup.value ], massQuoteRequestMessageNoQuoteSetsGroup.rest)

ZeroMassQuoteRequestMessageNoQuoteSetsGroups ==
    [ blockLength                             |-> [i \in 1 .. 2 |-> 0],
      massQuoteRequestMessageNoQuoteSetsGroup |-> << >> ]

(* Mass Quote Request Message no Quote Sets Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequestMessageNoQuoteSetsGroups ==
    { ZeroMassQuoteRequestMessageNoQuoteSetsGroups }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequestMessageNoQuoteSetsGroups EXCEPT !.massQuoteRequestMessageNoQuoteSetsGroup = one] : one \in SampleLists(OneMassQuoteRequestMessageNoQuoteSetsGroup) }

(***************************************************************************)
(* Mass Quote Request Message                                              *)
(***************************************************************************)

MassQuoteRequestMessage ==
    [ quoteId                                  : Sample(8),
      riskProtectionReset                      : Sample(1),
      selfMatchPreventionId                    : Sample(8),
      selfMatchPreventionInstruction           : Sample(1),
      originatorUserId                         : Sample(20),
      directElectronicAccess                   : Sample(1),
      tradingCapacity                          : Sample(1),
      liquidityProvision                       : Sample(1),
      commodityDerivIndicator                  : Sample(1),
      investmentDecision                       : Sample(8),
      executionDecision                        : Sample(8),
      clientIdCode                             : Sample(8),
      mifidId                                  : Sample(8),
      massQuoteRequestMessageNoQuoteSetsGroups : MassQuoteRequestMessageNoQuoteSetsGroups ]

EncodeMassQuoteRequestMessage(message) ==
    message.quoteId
        \o message.riskProtectionReset
        \o message.selfMatchPreventionId
        \o message.selfMatchPreventionInstruction
        \o message.originatorUserId
        \o message.directElectronicAccess
        \o message.tradingCapacity
        \o message.liquidityProvision
        \o message.commodityDerivIndicator
        \o message.investmentDecision
        \o message.executionDecision
        \o message.clientIdCode
        \o message.mifidId
        \o EncodeMassQuoteRequestMessageNoQuoteSetsGroups(message.massQuoteRequestMessageNoQuoteSetsGroups)

DecodeMassQuoteRequestMessage(bytes) ==
    LET quoteId == ReadBytes(bytes, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET riskProtectionReset == ReadBytes(quoteId.rest, 1) IN IF ~riskProtectionReset.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(riskProtectionReset.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(selfMatchPreventionId.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET originatorUserId == ReadBytes(selfMatchPreventionInstruction.rest, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET directElectronicAccess == ReadBytes(originatorUserId.rest, 1) IN IF ~directElectronicAccess.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(directElectronicAccess.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET liquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET commodityDerivIndicator == ReadBytes(liquidityProvision.rest, 1) IN IF ~commodityDerivIndicator.ok THEN Fail ELSE
    LET investmentDecision == ReadBytes(commodityDerivIndicator.rest, 8) IN IF ~investmentDecision.ok THEN Fail ELSE
    LET executionDecision == ReadBytes(investmentDecision.rest, 8) IN IF ~executionDecision.ok THEN Fail ELSE
    LET clientIdCode == ReadBytes(executionDecision.rest, 8) IN IF ~clientIdCode.ok THEN Fail ELSE
    LET mifidId == ReadBytes(clientIdCode.rest, 8) IN IF ~mifidId.ok THEN Fail ELSE
    LET massQuoteRequestMessageNoQuoteSetsGroups == DecodeMassQuoteRequestMessageNoQuoteSetsGroups(mifidId.rest) IN IF ~massQuoteRequestMessageNoQuoteSetsGroups.ok THEN Fail ELSE
    Ok([ quoteId                                  |-> quoteId.value,
         riskProtectionReset                      |-> riskProtectionReset.value,
         selfMatchPreventionId                    |-> selfMatchPreventionId.value,
         selfMatchPreventionInstruction           |-> selfMatchPreventionInstruction.value,
         originatorUserId                         |-> originatorUserId.value,
         directElectronicAccess                   |-> directElectronicAccess.value,
         tradingCapacity                          |-> tradingCapacity.value,
         liquidityProvision                       |-> liquidityProvision.value,
         commodityDerivIndicator                  |-> commodityDerivIndicator.value,
         investmentDecision                       |-> investmentDecision.value,
         executionDecision                        |-> executionDecision.value,
         clientIdCode                             |-> clientIdCode.value,
         mifidId                                  |-> mifidId.value,
         massQuoteRequestMessageNoQuoteSetsGroups |-> massQuoteRequestMessageNoQuoteSetsGroups.value ], massQuoteRequestMessageNoQuoteSetsGroups.rest)

ZeroMassQuoteRequestMessage ==
    [ quoteId                                  |-> [i \in 1 .. 8 |-> 0],
      riskProtectionReset                      |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionId                    |-> [i \in 1 .. 8 |-> 0],
      selfMatchPreventionInstruction           |-> [i \in 1 .. 1 |-> 0],
      originatorUserId                         |-> [i \in 1 .. 20 |-> 0],
      directElectronicAccess                   |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                          |-> [i \in 1 .. 1 |-> 0],
      liquidityProvision                       |-> [i \in 1 .. 1 |-> 0],
      commodityDerivIndicator                  |-> [i \in 1 .. 1 |-> 0],
      investmentDecision                       |-> [i \in 1 .. 8 |-> 0],
      executionDecision                        |-> [i \in 1 .. 8 |-> 0],
      clientIdCode                             |-> [i \in 1 .. 8 |-> 0],
      mifidId                                  |-> [i \in 1 .. 8 |-> 0],
      massQuoteRequestMessageNoQuoteSetsGroups |-> ZeroMassQuoteRequestMessageNoQuoteSetsGroups ]

(* Mass Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequestMessage ==
    { ZeroMassQuoteRequestMessage }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.riskProtectionReset = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.directElectronicAccess = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.liquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.commodityDerivIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.investmentDecision = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.executionDecision = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.clientIdCode = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.mifidId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequestMessage EXCEPT !.massQuoteRequestMessageNoQuoteSetsGroups = one] : one \in CheckedMassQuoteRequestMessageNoQuoteSetsGroups }

(***************************************************************************)
(* Quote Cancel Request Message no Quote Entries Group: 12 bytes           *)
(***************************************************************************)

QuoteCancelRequestMessageNoQuoteEntriesGroup ==
    [ underlyingSymbolInt32Null : Sample(4),
      underlyingSecurityId      : Sample(4),
      underlyingProduct         : Sample(4) ]

EncodeQuoteCancelRequestMessageNoQuoteEntriesGroup(message) ==
    message.underlyingSymbolInt32Null
        \o message.underlyingSecurityId
        \o message.underlyingProduct

DecodeQuoteCancelRequestMessageNoQuoteEntriesGroup(bytes) ==
    LET underlyingSymbolInt32Null == ReadBytes(bytes, 4) IN IF ~underlyingSymbolInt32Null.ok THEN Fail ELSE
    LET underlyingSecurityId == ReadBytes(underlyingSymbolInt32Null.rest, 4) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET underlyingProduct == ReadBytes(underlyingSecurityId.rest, 4) IN IF ~underlyingProduct.ok THEN Fail ELSE
    Ok([ underlyingSymbolInt32Null |-> underlyingSymbolInt32Null.value,
         underlyingSecurityId      |-> underlyingSecurityId.value,
         underlyingProduct         |-> underlyingProduct.value ], underlyingProduct.rest)

ZeroQuoteCancelRequestMessageNoQuoteEntriesGroup ==
    [ underlyingSymbolInt32Null |-> [i \in 1 .. 4 |-> 0],
      underlyingSecurityId      |-> [i \in 1 .. 4 |-> 0],
      underlyingProduct         |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Cancel Request Message no Quote Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelRequestMessageNoQuoteEntriesGroup ==
    { ZeroQuoteCancelRequestMessageNoQuoteEntriesGroup }
        \cup { [ZeroQuoteCancelRequestMessageNoQuoteEntriesGroup EXCEPT !.underlyingSymbolInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelRequestMessageNoQuoteEntriesGroup EXCEPT !.underlyingSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelRequestMessageNoQuoteEntriesGroup EXCEPT !.underlyingProduct = one] : one \in Sample(4) }

(* A run of Quote Cancel Request Message no Quote Entries Group, written one after another *)
RECURSIVE EncodeQuoteCancelRequestMessageNoQuoteEntriesGroupList(_)
EncodeQuoteCancelRequestMessageNoQuoteEntriesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteCancelRequestMessageNoQuoteEntriesGroup(Head(messages)) \o EncodeQuoteCancelRequestMessageNoQuoteEntriesGroupList(Tail(messages))

(* As many Quote Cancel Request Message no Quote Entries Group as the field that counts them says *)
RECURSIVE ReadQuoteCancelRequestMessageNoQuoteEntriesGroupList(_, _)
ReadQuoteCancelRequestMessageNoQuoteEntriesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteCancelRequestMessageNoQuoteEntriesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteCancelRequestMessageNoQuoteEntriesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Cancel Request Message no Quote Entries Group of each kind, for the lists that carry them *)
OneQuoteCancelRequestMessageNoQuoteEntriesGroup == { ZeroQuoteCancelRequestMessageNoQuoteEntriesGroup }

(***************************************************************************)
(* Quote Cancel Request Message no Quote Entries Groups                    *)
(***************************************************************************)

QuoteCancelRequestMessageNoQuoteEntriesGroups ==
    [ blockLength                                  : Sample(2),
      quoteCancelRequestMessageNoQuoteEntriesGroup : SampleLists(OneQuoteCancelRequestMessageNoQuoteEntriesGroup) ]

EncodeQuoteCancelRequestMessageNoQuoteEntriesGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.quoteCancelRequestMessageNoQuoteEntriesGroup), 2)
        \o EncodeQuoteCancelRequestMessageNoQuoteEntriesGroupList(message.quoteCancelRequestMessageNoQuoteEntriesGroup)

DecodeQuoteCancelRequestMessageNoQuoteEntriesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET quoteCancelRequestMessageNoQuoteEntriesGroup == ReadQuoteCancelRequestMessageNoQuoteEntriesGroupList(numInGroup.rest, numInGroup.value) IN IF ~quoteCancelRequestMessageNoQuoteEntriesGroup.ok THEN Fail ELSE
    Ok([ blockLength                                  |-> blockLength.value,
         quoteCancelRequestMessageNoQuoteEntriesGroup |-> quoteCancelRequestMessageNoQuoteEntriesGroup.value ], quoteCancelRequestMessageNoQuoteEntriesGroup.rest)

ZeroQuoteCancelRequestMessageNoQuoteEntriesGroups ==
    [ blockLength                                  |-> [i \in 1 .. 2 |-> 0],
      quoteCancelRequestMessageNoQuoteEntriesGroup |-> << >> ]

(* Quote Cancel Request Message no Quote Entries Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelRequestMessageNoQuoteEntriesGroups ==
    { ZeroQuoteCancelRequestMessageNoQuoteEntriesGroups }
        \cup { [ZeroQuoteCancelRequestMessageNoQuoteEntriesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelRequestMessageNoQuoteEntriesGroups EXCEPT !.quoteCancelRequestMessageNoQuoteEntriesGroup = one] : one \in SampleLists(OneQuoteCancelRequestMessageNoQuoteEntriesGroup) }

(***************************************************************************)
(* Quote Cancel Request Message                                            *)
(***************************************************************************)

QuoteCancelRequestMessage ==
    [ quoteId                                       : Sample(8),
      quoteCancelType                               : Sample(1),
      originatorUserId                              : Sample(20),
      quoteCancelRequestMessageNoQuoteEntriesGroups : QuoteCancelRequestMessageNoQuoteEntriesGroups ]

EncodeQuoteCancelRequestMessage(message) ==
    message.quoteId
        \o message.quoteCancelType
        \o message.originatorUserId
        \o EncodeQuoteCancelRequestMessageNoQuoteEntriesGroups(message.quoteCancelRequestMessageNoQuoteEntriesGroups)

DecodeQuoteCancelRequestMessage(bytes) ==
    LET quoteId == ReadBytes(bytes, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteCancelType == ReadBytes(quoteId.rest, 1) IN IF ~quoteCancelType.ok THEN Fail ELSE
    LET originatorUserId == ReadBytes(quoteCancelType.rest, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET quoteCancelRequestMessageNoQuoteEntriesGroups == DecodeQuoteCancelRequestMessageNoQuoteEntriesGroups(originatorUserId.rest) IN IF ~quoteCancelRequestMessageNoQuoteEntriesGroups.ok THEN Fail ELSE
    Ok([ quoteId                                       |-> quoteId.value,
         quoteCancelType                               |-> quoteCancelType.value,
         originatorUserId                              |-> originatorUserId.value,
         quoteCancelRequestMessageNoQuoteEntriesGroups |-> quoteCancelRequestMessageNoQuoteEntriesGroups.value ], quoteCancelRequestMessageNoQuoteEntriesGroups.rest)

ZeroQuoteCancelRequestMessage ==
    [ quoteId                                       |-> [i \in 1 .. 8 |-> 0],
      quoteCancelType                               |-> [i \in 1 .. 1 |-> 0],
      originatorUserId                              |-> [i \in 1 .. 20 |-> 0],
      quoteCancelRequestMessageNoQuoteEntriesGroups |-> ZeroQuoteCancelRequestMessageNoQuoteEntriesGroups ]

(* Quote Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelRequestMessage ==
    { ZeroQuoteCancelRequestMessage }
        \cup { [ZeroQuoteCancelRequestMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelRequestMessage EXCEPT !.quoteCancelType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancelRequestMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroQuoteCancelRequestMessage EXCEPT !.quoteCancelRequestMessageNoQuoteEntriesGroups = one] : one \in CheckedQuoteCancelRequestMessageNoQuoteEntriesGroups }

(***************************************************************************)
(* Security Definition Request Create Strategy Message no Legs Group: 22   *)
(* bytes                                                                   *)
(***************************************************************************)

SecurityDefinitionRequestCreateStrategyMessageNoLegsGroup ==
    [ legSymbolInt32                  : Sample(4),
      legSecurityType                 : Sample(1),
      legSide                         : Sample(1),
      legRatioQtyDenominatorInt16Null : Sample(2),
      legRatioQtyNumeratorInt16Null   : Sample(2),
      legPrice                        : Sample(8),
      legOptionDelta                  : Sample(4) ]

EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup(message) ==
    message.legSymbolInt32
        \o message.legSecurityType
        \o message.legSide
        \o message.legRatioQtyDenominatorInt16Null
        \o message.legRatioQtyNumeratorInt16Null
        \o message.legPrice
        \o message.legOptionDelta

DecodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup(bytes) ==
    LET legSymbolInt32 == ReadBytes(bytes, 4) IN IF ~legSymbolInt32.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legSymbolInt32.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSecurityType.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatioQtyDenominatorInt16Null == ReadBytes(legSide.rest, 2) IN IF ~legRatioQtyDenominatorInt16Null.ok THEN Fail ELSE
    LET legRatioQtyNumeratorInt16Null == ReadBytes(legRatioQtyDenominatorInt16Null.rest, 2) IN IF ~legRatioQtyNumeratorInt16Null.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legRatioQtyNumeratorInt16Null.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legOptionDelta == ReadBytes(legPrice.rest, 4) IN IF ~legOptionDelta.ok THEN Fail ELSE
    Ok([ legSymbolInt32                  |-> legSymbolInt32.value,
         legSecurityType                 |-> legSecurityType.value,
         legSide                         |-> legSide.value,
         legRatioQtyDenominatorInt16Null |-> legRatioQtyDenominatorInt16Null.value,
         legRatioQtyNumeratorInt16Null   |-> legRatioQtyNumeratorInt16Null.value,
         legPrice                        |-> legPrice.value,
         legOptionDelta                  |-> legOptionDelta.value ], legOptionDelta.rest)

ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup ==
    [ legSymbolInt32                  |-> [i \in 1 .. 4 |-> 0],
      legSecurityType                 |-> [i \in 1 .. 1 |-> 0],
      legSide                         |-> [i \in 1 .. 1 |-> 0],
      legRatioQtyDenominatorInt16Null |-> [i \in 1 .. 2 |-> 0],
      legRatioQtyNumeratorInt16Null   |-> [i \in 1 .. 2 |-> 0],
      legPrice                        |-> [i \in 1 .. 8 |-> 0],
      legOptionDelta                  |-> [i \in 1 .. 4 |-> 0] ]

(* Security Definition Request Create Strategy Message no Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup ==
    { ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup EXCEPT !.legSymbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup EXCEPT !.legRatioQtyDenominatorInt16Null = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup EXCEPT !.legRatioQtyNumeratorInt16Null = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup EXCEPT !.legOptionDelta = one] : one \in Sample(4) }

(* A run of Security Definition Request Create Strategy Message no Legs Group, written one after another *)
RECURSIVE EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroupList(_)
EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup(Head(messages)) \o EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroupList(Tail(messages))

(* As many Security Definition Request Create Strategy Message no Legs Group as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionRequestCreateStrategyMessageNoLegsGroupList(_, _)
ReadSecurityDefinitionRequestCreateStrategyMessageNoLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionRequestCreateStrategyMessageNoLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Request Create Strategy Message no Legs Group of each kind, for the lists that carry them *)
OneSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup == { ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup }

(***************************************************************************)
(* Security Definition Request Create Strategy Message no Legs Groups      *)
(***************************************************************************)

SecurityDefinitionRequestCreateStrategyMessageNoLegsGroups ==
    [ blockLength                                               : Sample(2),
      securityDefinitionRequestCreateStrategyMessageNoLegsGroup : SampleLists(OneSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup) ]

EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.securityDefinitionRequestCreateStrategyMessageNoLegsGroup), 2)
        \o EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroupList(message.securityDefinitionRequestCreateStrategyMessageNoLegsGroup)

DecodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityDefinitionRequestCreateStrategyMessageNoLegsGroup == ReadSecurityDefinitionRequestCreateStrategyMessageNoLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityDefinitionRequestCreateStrategyMessageNoLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                                               |-> blockLength.value,
         securityDefinitionRequestCreateStrategyMessageNoLegsGroup |-> securityDefinitionRequestCreateStrategyMessageNoLegsGroup.value ], securityDefinitionRequestCreateStrategyMessageNoLegsGroup.rest)

ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups ==
    [ blockLength                                               |-> [i \in 1 .. 2 |-> 0],
      securityDefinitionRequestCreateStrategyMessageNoLegsGroup |-> << >> ]

(* Security Definition Request Create Strategy Message no Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups ==
    { ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups EXCEPT !.securityDefinitionRequestCreateStrategyMessageNoLegsGroup = one] : one \in SampleLists(OneSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup) }

(***************************************************************************)
(* Security Definition Request Create Strategy Message                     *)
(***************************************************************************)

SecurityDefinitionRequestCreateStrategyMessage ==
    [ securityReqId                                              : Sample(4),
      securityRequestType                                        : Sample(1),
      marketTypeIDInt32                                          : Sample(4),
      securitySubTypeInt16Null                                   : Sample(2),
      productIDInt32Null                                         : Sample(4),
      startDate                                                  : Sample(2),
      endDate                                                    : Sample(2),
      securityTypeSecurityTypeEnum                               : Sample(1),
      securityDefinitionRequestCreateStrategyMessageNoLegsGroups : SecurityDefinitionRequestCreateStrategyMessageNoLegsGroups ]

EncodeSecurityDefinitionRequestCreateStrategyMessage(message) ==
    message.securityReqId
        \o message.securityRequestType
        \o message.marketTypeIDInt32
        \o message.securitySubTypeInt16Null
        \o message.productIDInt32Null
        \o message.startDate
        \o message.endDate
        \o message.securityTypeSecurityTypeEnum
        \o EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups(message.securityDefinitionRequestCreateStrategyMessageNoLegsGroups)

DecodeSecurityDefinitionRequestCreateStrategyMessage(bytes) ==
    LET securityReqId == ReadBytes(bytes, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityRequestType == ReadBytes(securityReqId.rest, 1) IN IF ~securityRequestType.ok THEN Fail ELSE
    LET marketTypeIDInt32 == ReadBytes(securityRequestType.rest, 4) IN IF ~marketTypeIDInt32.ok THEN Fail ELSE
    LET securitySubTypeInt16Null == ReadBytes(marketTypeIDInt32.rest, 2) IN IF ~securitySubTypeInt16Null.ok THEN Fail ELSE
    LET productIDInt32Null == ReadBytes(securitySubTypeInt16Null.rest, 4) IN IF ~productIDInt32Null.ok THEN Fail ELSE
    LET startDate == ReadBytes(productIDInt32Null.rest, 2) IN IF ~startDate.ok THEN Fail ELSE
    LET endDate == ReadBytes(startDate.rest, 2) IN IF ~endDate.ok THEN Fail ELSE
    LET securityTypeSecurityTypeEnum == ReadBytes(endDate.rest, 1) IN IF ~securityTypeSecurityTypeEnum.ok THEN Fail ELSE
    LET securityDefinitionRequestCreateStrategyMessageNoLegsGroups == DecodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups(securityTypeSecurityTypeEnum.rest) IN IF ~securityDefinitionRequestCreateStrategyMessageNoLegsGroups.ok THEN Fail ELSE
    Ok([ securityReqId                                              |-> securityReqId.value,
         securityRequestType                                        |-> securityRequestType.value,
         marketTypeIDInt32                                          |-> marketTypeIDInt32.value,
         securitySubTypeInt16Null                                   |-> securitySubTypeInt16Null.value,
         productIDInt32Null                                         |-> productIDInt32Null.value,
         startDate                                                  |-> startDate.value,
         endDate                                                    |-> endDate.value,
         securityTypeSecurityTypeEnum                               |-> securityTypeSecurityTypeEnum.value,
         securityDefinitionRequestCreateStrategyMessageNoLegsGroups |-> securityDefinitionRequestCreateStrategyMessageNoLegsGroups.value ], securityDefinitionRequestCreateStrategyMessageNoLegsGroups.rest)

ZeroSecurityDefinitionRequestCreateStrategyMessage ==
    [ securityReqId                                              |-> [i \in 1 .. 4 |-> 0],
      securityRequestType                                        |-> [i \in 1 .. 1 |-> 0],
      marketTypeIDInt32                                          |-> [i \in 1 .. 4 |-> 0],
      securitySubTypeInt16Null                                   |-> [i \in 1 .. 2 |-> 0],
      productIDInt32Null                                         |-> [i \in 1 .. 4 |-> 0],
      startDate                                                  |-> [i \in 1 .. 2 |-> 0],
      endDate                                                    |-> [i \in 1 .. 2 |-> 0],
      securityTypeSecurityTypeEnum                               |-> [i \in 1 .. 1 |-> 0],
      securityDefinitionRequestCreateStrategyMessageNoLegsGroups |-> ZeroSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups ]

(* Security Definition Request Create Strategy Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRequestCreateStrategyMessage ==
    { ZeroSecurityDefinitionRequestCreateStrategyMessage }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.securityRequestType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.marketTypeIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.securitySubTypeInt16Null = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.productIDInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.startDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.endDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.securityTypeSecurityTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequestCreateStrategyMessage EXCEPT !.securityDefinitionRequestCreateStrategyMessageNoLegsGroups = one] : one \in CheckedSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups }

(***************************************************************************)
(* Security Definition Request Create Flex Message: 28 bytes               *)
(***************************************************************************)

SecurityDefinitionRequestCreateFlexMessage ==
    [ securityReqId                : Sample(4),
      securityRequestType          : Sample(1),
      marketTypeIDInt32            : Sample(4),
      securityTypeSecurityTypeEnum : Sample(1),
      maturityDate                 : Sample(2),
      productIDInt32Null           : Sample(4),
      symbolInt32Null              : Sample(4),
      strikePrice                  : Sample(8) ]

EncodeSecurityDefinitionRequestCreateFlexMessage(message) ==
    message.securityReqId
        \o message.securityRequestType
        \o message.marketTypeIDInt32
        \o message.securityTypeSecurityTypeEnum
        \o message.maturityDate
        \o message.productIDInt32Null
        \o message.symbolInt32Null
        \o message.strikePrice

DecodeSecurityDefinitionRequestCreateFlexMessage(bytes) ==
    LET securityReqId == ReadBytes(bytes, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET securityRequestType == ReadBytes(securityReqId.rest, 1) IN IF ~securityRequestType.ok THEN Fail ELSE
    LET marketTypeIDInt32 == ReadBytes(securityRequestType.rest, 4) IN IF ~marketTypeIDInt32.ok THEN Fail ELSE
    LET securityTypeSecurityTypeEnum == ReadBytes(marketTypeIDInt32.rest, 1) IN IF ~securityTypeSecurityTypeEnum.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityTypeSecurityTypeEnum.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET productIDInt32Null == ReadBytes(maturityDate.rest, 4) IN IF ~productIDInt32Null.ok THEN Fail ELSE
    LET symbolInt32Null == ReadBytes(productIDInt32Null.rest, 4) IN IF ~symbolInt32Null.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(symbolInt32Null.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    Ok([ securityReqId                |-> securityReqId.value,
         securityRequestType          |-> securityRequestType.value,
         marketTypeIDInt32            |-> marketTypeIDInt32.value,
         securityTypeSecurityTypeEnum |-> securityTypeSecurityTypeEnum.value,
         maturityDate                 |-> maturityDate.value,
         productIDInt32Null           |-> productIDInt32Null.value,
         symbolInt32Null              |-> symbolInt32Null.value,
         strikePrice                  |-> strikePrice.value ], strikePrice.rest)

ZeroSecurityDefinitionRequestCreateFlexMessage ==
    [ securityReqId                |-> [i \in 1 .. 4 |-> 0],
      securityRequestType          |-> [i \in 1 .. 1 |-> 0],
      marketTypeIDInt32            |-> [i \in 1 .. 4 |-> 0],
      securityTypeSecurityTypeEnum |-> [i \in 1 .. 1 |-> 0],
      maturityDate                 |-> [i \in 1 .. 2 |-> 0],
      productIDInt32Null           |-> [i \in 1 .. 4 |-> 0],
      symbolInt32Null              |-> [i \in 1 .. 4 |-> 0],
      strikePrice                  |-> [i \in 1 .. 8 |-> 0] ]

(* Security Definition Request Create Flex Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRequestCreateFlexMessage ==
    { ZeroSecurityDefinitionRequestCreateFlexMessage }
        \cup { [ZeroSecurityDefinitionRequestCreateFlexMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestCreateFlexMessage EXCEPT !.securityRequestType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequestCreateFlexMessage EXCEPT !.marketTypeIDInt32 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestCreateFlexMessage EXCEPT !.securityTypeSecurityTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequestCreateFlexMessage EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequestCreateFlexMessage EXCEPT !.productIDInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestCreateFlexMessage EXCEPT !.symbolInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestCreateFlexMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Exec I D order Exec Id: 20 bytes                                        *)
(***************************************************************************)

ExecIDOrderExecId ==
    [ systemId                 : Sample(8),
      systemSequenceId         : Sample(4),
      transactTimeUtcTimestamp : Sample(8) ]

EncodeExecIDOrderExecId(message) ==
    message.systemId
        \o message.systemSequenceId
        \o message.transactTimeUtcTimestamp

DecodeExecIDOrderExecId(bytes) ==
    LET systemId == ReadBytes(bytes, 8) IN IF ~systemId.ok THEN Fail ELSE
    LET systemSequenceId == ReadBytes(systemId.rest, 4) IN IF ~systemSequenceId.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(systemSequenceId.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    Ok([ systemId                 |-> systemId.value,
         systemSequenceId         |-> systemSequenceId.value,
         transactTimeUtcTimestamp |-> transactTimeUtcTimestamp.value ], transactTimeUtcTimestamp.rest)

ZeroExecIDOrderExecId ==
    [ systemId                 |-> [i \in 1 .. 8 |-> 0],
      systemSequenceId         |-> [i \in 1 .. 4 |-> 0],
      transactTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Exec I D order Exec Id at zero, then each field in turn at the values it is checked at *)
CheckedExecIDOrderExecId ==
    { ZeroExecIDOrderExecId }
        \cup { [ZeroExecIDOrderExecId EXCEPT !.systemId = one] : one \in Sample(8) }
        \cup { [ZeroExecIDOrderExecId EXCEPT !.systemSequenceId = one] : one \in Sample(4) }
        \cup { [ZeroExecIDOrderExecId EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Orig Order Id: 16 bytes                                                 *)
(***************************************************************************)

OrigOrderId ==
    [ originalSystemId          : Sample(8),
      originalCreationTimestamp : Sample(8) ]

EncodeOrigOrderId(message) ==
    message.originalSystemId
        \o message.originalCreationTimestamp

DecodeOrigOrderId(bytes) ==
    LET originalSystemId == ReadBytes(bytes, 8) IN IF ~originalSystemId.ok THEN Fail ELSE
    LET originalCreationTimestamp == ReadBytes(originalSystemId.rest, 8) IN IF ~originalCreationTimestamp.ok THEN Fail ELSE
    Ok([ originalSystemId          |-> originalSystemId.value,
         originalCreationTimestamp |-> originalCreationTimestamp.value ], originalCreationTimestamp.rest)

ZeroOrigOrderId ==
    [ originalSystemId          |-> [i \in 1 .. 8 |-> 0],
      originalCreationTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Orig Order Id at zero, then each field in turn at the values it is checked at *)
CheckedOrigOrderId ==
    { ZeroOrigOrderId }
        \cup { [ZeroOrigOrderId EXCEPT !.originalSystemId = one] : one \in Sample(8) }
        \cup { [ZeroOrigOrderId EXCEPT !.originalCreationTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report New Message: 133 bytes                                 *)
(***************************************************************************)

ExecutionReportNewMessage ==
    [ originatorUserId             : Sample(20),
      execIDOrderExecId            : ExecIDOrderExecId,
      clOrdId                      : Sample(8),
      symbolInt32                  : Sample(4),
      ordTypeOrderTypeEnum         : Sample(1),
      sideSideEnum                 : Sample(1),
      origOrderId                  : OrigOrderId,
      leavesQty                    : Sample(8),
      priceDecimal9Null            : Sample(8),
      meAcceptanceTimeUtcTimestamp : Sample(8),
      timePriority                 : Sample(8),
      orderStatus                  : Sample(1),
      memo                         : Sample(30) ]

EncodeExecutionReportNewMessage(message) ==
    message.originatorUserId
        \o EncodeExecIDOrderExecId(message.execIDOrderExecId)
        \o message.clOrdId
        \o message.symbolInt32
        \o message.ordTypeOrderTypeEnum
        \o message.sideSideEnum
        \o EncodeOrigOrderId(message.origOrderId)
        \o message.leavesQty
        \o message.priceDecimal9Null
        \o message.meAcceptanceTimeUtcTimestamp
        \o message.timePriority
        \o message.orderStatus
        \o message.memo

DecodeExecutionReportNewMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET execIDOrderExecId == DecodeExecIDOrderExecId(originatorUserId.rest) IN IF ~execIDOrderExecId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(execIDOrderExecId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(clOrdId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnum == ReadBytes(symbolInt32.rest, 1) IN IF ~ordTypeOrderTypeEnum.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(ordTypeOrderTypeEnum.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET origOrderId == DecodeOrigOrderId(sideSideEnum.rest) IN IF ~origOrderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(origOrderId.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET priceDecimal9Null == ReadBytes(leavesQty.rest, 8) IN IF ~priceDecimal9Null.ok THEN Fail ELSE
    LET meAcceptanceTimeUtcTimestamp == ReadBytes(priceDecimal9Null.rest, 8) IN IF ~meAcceptanceTimeUtcTimestamp.ok THEN Fail ELSE
    LET timePriority == ReadBytes(meAcceptanceTimeUtcTimestamp.rest, 8) IN IF ~timePriority.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(timePriority.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET memo == ReadBytes(orderStatus.rest, 30) IN IF ~memo.ok THEN Fail ELSE
    Ok([ originatorUserId             |-> originatorUserId.value,
         execIDOrderExecId            |-> execIDOrderExecId.value,
         clOrdId                      |-> clOrdId.value,
         symbolInt32                  |-> symbolInt32.value,
         ordTypeOrderTypeEnum         |-> ordTypeOrderTypeEnum.value,
         sideSideEnum                 |-> sideSideEnum.value,
         origOrderId                  |-> origOrderId.value,
         leavesQty                    |-> leavesQty.value,
         priceDecimal9Null            |-> priceDecimal9Null.value,
         meAcceptanceTimeUtcTimestamp |-> meAcceptanceTimeUtcTimestamp.value,
         timePriority                 |-> timePriority.value,
         orderStatus                  |-> orderStatus.value,
         memo                         |-> memo.value ], memo.rest)

ZeroExecutionReportNewMessage ==
    [ originatorUserId             |-> [i \in 1 .. 20 |-> 0],
      execIDOrderExecId            |-> ZeroExecIDOrderExecId,
      clOrdId                      |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                  |-> [i \in 1 .. 4 |-> 0],
      ordTypeOrderTypeEnum         |-> [i \in 1 .. 1 |-> 0],
      sideSideEnum                 |-> [i \in 1 .. 1 |-> 0],
      origOrderId                  |-> ZeroOrigOrderId,
      leavesQty                    |-> [i \in 1 .. 8 |-> 0],
      priceDecimal9Null            |-> [i \in 1 .. 8 |-> 0],
      meAcceptanceTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0],
      timePriority                 |-> [i \in 1 .. 8 |-> 0],
      orderStatus                  |-> [i \in 1 .. 1 |-> 0],
      memo                         |-> [i \in 1 .. 30 |-> 0] ]

(* Execution Report New Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportNewMessage ==
    { ZeroExecutionReportNewMessage }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.execIDOrderExecId = one] : one \in CheckedExecIDOrderExecId }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.ordTypeOrderTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.origOrderId = one] : one \in CheckedOrigOrderId }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.priceDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.meAcceptanceTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.timePriority = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportNewMessage EXCEPT !.memo = one] : one \in Sample(30) }

(***************************************************************************)
(* Exec I D order Exec Id: 20 bytes                                        *)
(***************************************************************************)

ExecIDOrderExecId2 ==
    [ systemId                 : Sample(8),
      systemSequenceId         : Sample(4),
      transactTimeUtcTimestamp : Sample(8) ]

EncodeExecIDOrderExecId2(message) ==
    message.systemId
        \o message.systemSequenceId
        \o message.transactTimeUtcTimestamp

DecodeExecIDOrderExecId2(bytes) ==
    LET systemId == ReadBytes(bytes, 8) IN IF ~systemId.ok THEN Fail ELSE
    LET systemSequenceId == ReadBytes(systemId.rest, 4) IN IF ~systemSequenceId.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(systemSequenceId.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    Ok([ systemId                 |-> systemId.value,
         systemSequenceId         |-> systemSequenceId.value,
         transactTimeUtcTimestamp |-> transactTimeUtcTimestamp.value ], transactTimeUtcTimestamp.rest)

ZeroExecIDOrderExecId2 ==
    [ systemId                 |-> [i \in 1 .. 8 |-> 0],
      systemSequenceId         |-> [i \in 1 .. 4 |-> 0],
      transactTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Exec I D order Exec Id at zero, then each field in turn at the values it is checked at *)
CheckedExecIDOrderExecId2 ==
    { ZeroExecIDOrderExecId2 }
        \cup { [ZeroExecIDOrderExecId2 EXCEPT !.systemId = one] : one \in Sample(8) }
        \cup { [ZeroExecIDOrderExecId2 EXCEPT !.systemSequenceId = one] : one \in Sample(4) }
        \cup { [ZeroExecIDOrderExecId2 EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Orig Order Id: 16 bytes                                                 *)
(***************************************************************************)

OrigOrderId2 ==
    [ originalSystemId          : Sample(8),
      originalCreationTimestamp : Sample(8) ]

EncodeOrigOrderId2(message) ==
    message.originalSystemId
        \o message.originalCreationTimestamp

DecodeOrigOrderId2(bytes) ==
    LET originalSystemId == ReadBytes(bytes, 8) IN IF ~originalSystemId.ok THEN Fail ELSE
    LET originalCreationTimestamp == ReadBytes(originalSystemId.rest, 8) IN IF ~originalCreationTimestamp.ok THEN Fail ELSE
    Ok([ originalSystemId          |-> originalSystemId.value,
         originalCreationTimestamp |-> originalCreationTimestamp.value ], originalCreationTimestamp.rest)

ZeroOrigOrderId2 ==
    [ originalSystemId          |-> [i \in 1 .. 8 |-> 0],
      originalCreationTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Orig Order Id at zero, then each field in turn at the values it is checked at *)
CheckedOrigOrderId2 ==
    { ZeroOrigOrderId2 }
        \cup { [ZeroOrigOrderId2 EXCEPT !.originalSystemId = one] : one \in Sample(8) }
        \cup { [ZeroOrigOrderId2 EXCEPT !.originalCreationTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Modify Message: 153 bytes                              *)
(***************************************************************************)

ExecutionReportModifyMessage ==
    [ originatorUserId             : Sample(20),
      execIDOrderExecId            : ExecIDOrderExecId2,
      clOrdId                      : Sample(8),
      symbolInt32                  : Sample(4),
      ordTypeOrderTypeEnum         : Sample(1),
      sideSideEnum                 : Sample(1),
      origOrderId                  : OrigOrderId2,
      origClOrdIDInt64Null         : Sample(8),
      leavesQty                    : Sample(8),
      cumQty                       : Sample(8),
      priceDecimal9Null            : Sample(8),
      meAcceptanceTimeUtcTimestamp : Sample(8),
      timePriority                 : Sample(8),
      execType                     : Sample(1),
      orderStatus                  : Sample(1),
      orderState                   : Sample(1),
      execRestatementReason        : Sample(1),
      orderModificationFlags       : Sample(1),
      memo                         : Sample(30) ]

EncodeExecutionReportModifyMessage(message) ==
    message.originatorUserId
        \o EncodeExecIDOrderExecId2(message.execIDOrderExecId)
        \o message.clOrdId
        \o message.symbolInt32
        \o message.ordTypeOrderTypeEnum
        \o message.sideSideEnum
        \o EncodeOrigOrderId2(message.origOrderId)
        \o message.origClOrdIDInt64Null
        \o message.leavesQty
        \o message.cumQty
        \o message.priceDecimal9Null
        \o message.meAcceptanceTimeUtcTimestamp
        \o message.timePriority
        \o message.execType
        \o message.orderStatus
        \o message.orderState
        \o message.execRestatementReason
        \o message.orderModificationFlags
        \o message.memo

DecodeExecutionReportModifyMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET execIDOrderExecId == DecodeExecIDOrderExecId2(originatorUserId.rest) IN IF ~execIDOrderExecId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(execIDOrderExecId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(clOrdId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnum == ReadBytes(symbolInt32.rest, 1) IN IF ~ordTypeOrderTypeEnum.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(ordTypeOrderTypeEnum.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET origOrderId == DecodeOrigOrderId2(sideSideEnum.rest) IN IF ~origOrderId.ok THEN Fail ELSE
    LET origClOrdIDInt64Null == ReadBytes(origOrderId.rest, 8) IN IF ~origClOrdIDInt64Null.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(origClOrdIDInt64Null.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET priceDecimal9Null == ReadBytes(cumQty.rest, 8) IN IF ~priceDecimal9Null.ok THEN Fail ELSE
    LET meAcceptanceTimeUtcTimestamp == ReadBytes(priceDecimal9Null.rest, 8) IN IF ~meAcceptanceTimeUtcTimestamp.ok THEN Fail ELSE
    LET timePriority == ReadBytes(meAcceptanceTimeUtcTimestamp.rest, 8) IN IF ~timePriority.ok THEN Fail ELSE
    LET execType == ReadBytes(timePriority.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(execType.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET orderState == ReadBytes(orderStatus.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(orderState.rest, 1) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET orderModificationFlags == ReadBytes(execRestatementReason.rest, 1) IN IF ~orderModificationFlags.ok THEN Fail ELSE
    LET memo == ReadBytes(orderModificationFlags.rest, 30) IN IF ~memo.ok THEN Fail ELSE
    Ok([ originatorUserId             |-> originatorUserId.value,
         execIDOrderExecId            |-> execIDOrderExecId.value,
         clOrdId                      |-> clOrdId.value,
         symbolInt32                  |-> symbolInt32.value,
         ordTypeOrderTypeEnum         |-> ordTypeOrderTypeEnum.value,
         sideSideEnum                 |-> sideSideEnum.value,
         origOrderId                  |-> origOrderId.value,
         origClOrdIDInt64Null         |-> origClOrdIDInt64Null.value,
         leavesQty                    |-> leavesQty.value,
         cumQty                       |-> cumQty.value,
         priceDecimal9Null            |-> priceDecimal9Null.value,
         meAcceptanceTimeUtcTimestamp |-> meAcceptanceTimeUtcTimestamp.value,
         timePriority                 |-> timePriority.value,
         execType                     |-> execType.value,
         orderStatus                  |-> orderStatus.value,
         orderState                   |-> orderState.value,
         execRestatementReason        |-> execRestatementReason.value,
         orderModificationFlags       |-> orderModificationFlags.value,
         memo                         |-> memo.value ], memo.rest)

ZeroExecutionReportModifyMessage ==
    [ originatorUserId             |-> [i \in 1 .. 20 |-> 0],
      execIDOrderExecId            |-> ZeroExecIDOrderExecId2,
      clOrdId                      |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                  |-> [i \in 1 .. 4 |-> 0],
      ordTypeOrderTypeEnum         |-> [i \in 1 .. 1 |-> 0],
      sideSideEnum                 |-> [i \in 1 .. 1 |-> 0],
      origOrderId                  |-> ZeroOrigOrderId2,
      origClOrdIDInt64Null         |-> [i \in 1 .. 8 |-> 0],
      leavesQty                    |-> [i \in 1 .. 8 |-> 0],
      cumQty                       |-> [i \in 1 .. 8 |-> 0],
      priceDecimal9Null            |-> [i \in 1 .. 8 |-> 0],
      meAcceptanceTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0],
      timePriority                 |-> [i \in 1 .. 8 |-> 0],
      execType                     |-> [i \in 1 .. 1 |-> 0],
      orderStatus                  |-> [i \in 1 .. 1 |-> 0],
      orderState                   |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason        |-> [i \in 1 .. 1 |-> 0],
      orderModificationFlags       |-> [i \in 1 .. 1 |-> 0],
      memo                         |-> [i \in 1 .. 30 |-> 0] ]

(* Execution Report Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportModifyMessage ==
    { ZeroExecutionReportModifyMessage }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.execIDOrderExecId = one] : one \in CheckedExecIDOrderExecId2 }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.ordTypeOrderTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.origOrderId = one] : one \in CheckedOrigOrderId2 }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.origClOrdIDInt64Null = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.priceDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.meAcceptanceTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.timePriority = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.execRestatementReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.orderModificationFlags = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportModifyMessage EXCEPT !.memo = one] : one \in Sample(30) }

(***************************************************************************)
(* Exec I D order Exec Id: 20 bytes                                        *)
(***************************************************************************)

ExecIDOrderExecId3 ==
    [ systemId                 : Sample(8),
      systemSequenceId         : Sample(4),
      transactTimeUtcTimestamp : Sample(8) ]

EncodeExecIDOrderExecId3(message) ==
    message.systemId
        \o message.systemSequenceId
        \o message.transactTimeUtcTimestamp

DecodeExecIDOrderExecId3(bytes) ==
    LET systemId == ReadBytes(bytes, 8) IN IF ~systemId.ok THEN Fail ELSE
    LET systemSequenceId == ReadBytes(systemId.rest, 4) IN IF ~systemSequenceId.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(systemSequenceId.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    Ok([ systemId                 |-> systemId.value,
         systemSequenceId         |-> systemSequenceId.value,
         transactTimeUtcTimestamp |-> transactTimeUtcTimestamp.value ], transactTimeUtcTimestamp.rest)

ZeroExecIDOrderExecId3 ==
    [ systemId                 |-> [i \in 1 .. 8 |-> 0],
      systemSequenceId         |-> [i \in 1 .. 4 |-> 0],
      transactTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Exec I D order Exec Id at zero, then each field in turn at the values it is checked at *)
CheckedExecIDOrderExecId3 ==
    { ZeroExecIDOrderExecId3 }
        \cup { [ZeroExecIDOrderExecId3 EXCEPT !.systemId = one] : one \in Sample(8) }
        \cup { [ZeroExecIDOrderExecId3 EXCEPT !.systemSequenceId = one] : one \in Sample(4) }
        \cup { [ZeroExecIDOrderExecId3 EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Orig Order Id: 16 bytes                                                 *)
(***************************************************************************)

OrigOrderId3 ==
    [ originalSystemId          : Sample(8),
      originalCreationTimestamp : Sample(8) ]

EncodeOrigOrderId3(message) ==
    message.originalSystemId
        \o message.originalCreationTimestamp

DecodeOrigOrderId3(bytes) ==
    LET originalSystemId == ReadBytes(bytes, 8) IN IF ~originalSystemId.ok THEN Fail ELSE
    LET originalCreationTimestamp == ReadBytes(originalSystemId.rest, 8) IN IF ~originalCreationTimestamp.ok THEN Fail ELSE
    Ok([ originalSystemId          |-> originalSystemId.value,
         originalCreationTimestamp |-> originalCreationTimestamp.value ], originalCreationTimestamp.rest)

ZeroOrigOrderId3 ==
    [ originalSystemId          |-> [i \in 1 .. 8 |-> 0],
      originalCreationTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Orig Order Id at zero, then each field in turn at the values it is checked at *)
CheckedOrigOrderId3 ==
    { ZeroOrigOrderId3 }
        \cup { [ZeroOrigOrderId3 EXCEPT !.originalSystemId = one] : one \in Sample(8) }
        \cup { [ZeroOrigOrderId3 EXCEPT !.originalCreationTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Cancel Message: 199 bytes                              *)
(***************************************************************************)

ExecutionReportCancelMessage ==
    [ originatorUserId             : Sample(20),
      execIDOrderExecId            : ExecIDOrderExecId3,
      clOrdId                      : Sample(8),
      symbolInt32                  : Sample(4),
      ordTypeOrderTypeEnum         : Sample(1),
      sideSideEnum                 : Sample(1),
      origOrderId                  : OrigOrderId3,
      origClOrdIDInt64Null         : Sample(8),
      meAcceptanceTimeUtcTimestamp : Sample(8),
      exchangeCode                 : Sample(4),
      cancelReason                 : Sample(1),
      crossIDInt64Null             : Sample(8),
      text                         : Sample(100) ]

EncodeExecutionReportCancelMessage(message) ==
    message.originatorUserId
        \o EncodeExecIDOrderExecId3(message.execIDOrderExecId)
        \o message.clOrdId
        \o message.symbolInt32
        \o message.ordTypeOrderTypeEnum
        \o message.sideSideEnum
        \o EncodeOrigOrderId3(message.origOrderId)
        \o message.origClOrdIDInt64Null
        \o message.meAcceptanceTimeUtcTimestamp
        \o message.exchangeCode
        \o message.cancelReason
        \o message.crossIDInt64Null
        \o message.text

DecodeExecutionReportCancelMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET execIDOrderExecId == DecodeExecIDOrderExecId3(originatorUserId.rest) IN IF ~execIDOrderExecId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(execIDOrderExecId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(clOrdId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnum == ReadBytes(symbolInt32.rest, 1) IN IF ~ordTypeOrderTypeEnum.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(ordTypeOrderTypeEnum.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET origOrderId == DecodeOrigOrderId3(sideSideEnum.rest) IN IF ~origOrderId.ok THEN Fail ELSE
    LET origClOrdIDInt64Null == ReadBytes(origOrderId.rest, 8) IN IF ~origClOrdIDInt64Null.ok THEN Fail ELSE
    LET meAcceptanceTimeUtcTimestamp == ReadBytes(origClOrdIDInt64Null.rest, 8) IN IF ~meAcceptanceTimeUtcTimestamp.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(meAcceptanceTimeUtcTimestamp.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(exchangeCode.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET crossIDInt64Null == ReadBytes(cancelReason.rest, 8) IN IF ~crossIDInt64Null.ok THEN Fail ELSE
    LET text == ReadBytes(crossIDInt64Null.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ originatorUserId             |-> originatorUserId.value,
         execIDOrderExecId            |-> execIDOrderExecId.value,
         clOrdId                      |-> clOrdId.value,
         symbolInt32                  |-> symbolInt32.value,
         ordTypeOrderTypeEnum         |-> ordTypeOrderTypeEnum.value,
         sideSideEnum                 |-> sideSideEnum.value,
         origOrderId                  |-> origOrderId.value,
         origClOrdIDInt64Null         |-> origClOrdIDInt64Null.value,
         meAcceptanceTimeUtcTimestamp |-> meAcceptanceTimeUtcTimestamp.value,
         exchangeCode                 |-> exchangeCode.value,
         cancelReason                 |-> cancelReason.value,
         crossIDInt64Null             |-> crossIDInt64Null.value,
         text                         |-> text.value ], text.rest)

ZeroExecutionReportCancelMessage ==
    [ originatorUserId             |-> [i \in 1 .. 20 |-> 0],
      execIDOrderExecId            |-> ZeroExecIDOrderExecId3,
      clOrdId                      |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                  |-> [i \in 1 .. 4 |-> 0],
      ordTypeOrderTypeEnum         |-> [i \in 1 .. 1 |-> 0],
      sideSideEnum                 |-> [i \in 1 .. 1 |-> 0],
      origOrderId                  |-> ZeroOrigOrderId3,
      origClOrdIDInt64Null         |-> [i \in 1 .. 8 |-> 0],
      meAcceptanceTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0],
      exchangeCode                 |-> [i \in 1 .. 4 |-> 0],
      cancelReason                 |-> [i \in 1 .. 1 |-> 0],
      crossIDInt64Null             |-> [i \in 1 .. 8 |-> 0],
      text                         |-> [i \in 1 .. 100 |-> 0] ]

(* Execution Report Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportCancelMessage ==
    { ZeroExecutionReportCancelMessage }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.execIDOrderExecId = one] : one \in CheckedExecIDOrderExecId3 }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.ordTypeOrderTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.origOrderId = one] : one \in CheckedOrigOrderId3 }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.origClOrdIDInt64Null = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.meAcceptanceTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.crossIDInt64Null = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportCancelMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Exec I D order Exec Id: 20 bytes                                        *)
(***************************************************************************)

ExecIDOrderExecId4 ==
    [ systemId                 : Sample(8),
      systemSequenceId         : Sample(4),
      transactTimeUtcTimestamp : Sample(8) ]

EncodeExecIDOrderExecId4(message) ==
    message.systemId
        \o message.systemSequenceId
        \o message.transactTimeUtcTimestamp

DecodeExecIDOrderExecId4(bytes) ==
    LET systemId == ReadBytes(bytes, 8) IN IF ~systemId.ok THEN Fail ELSE
    LET systemSequenceId == ReadBytes(systemId.rest, 4) IN IF ~systemSequenceId.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(systemSequenceId.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    Ok([ systemId                 |-> systemId.value,
         systemSequenceId         |-> systemSequenceId.value,
         transactTimeUtcTimestamp |-> transactTimeUtcTimestamp.value ], transactTimeUtcTimestamp.rest)

ZeroExecIDOrderExecId4 ==
    [ systemId                 |-> [i \in 1 .. 8 |-> 0],
      systemSequenceId         |-> [i \in 1 .. 4 |-> 0],
      transactTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Exec I D order Exec Id at zero, then each field in turn at the values it is checked at *)
CheckedExecIDOrderExecId4 ==
    { ZeroExecIDOrderExecId4 }
        \cup { [ZeroExecIDOrderExecId4 EXCEPT !.systemId = one] : one \in Sample(8) }
        \cup { [ZeroExecIDOrderExecId4 EXCEPT !.systemSequenceId = one] : one \in Sample(4) }
        \cup { [ZeroExecIDOrderExecId4 EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Orig Order Id: 16 bytes                                                 *)
(***************************************************************************)

OrigOrderId4 ==
    [ originalSystemId          : Sample(8),
      originalCreationTimestamp : Sample(8) ]

EncodeOrigOrderId4(message) ==
    message.originalSystemId
        \o message.originalCreationTimestamp

DecodeOrigOrderId4(bytes) ==
    LET originalSystemId == ReadBytes(bytes, 8) IN IF ~originalSystemId.ok THEN Fail ELSE
    LET originalCreationTimestamp == ReadBytes(originalSystemId.rest, 8) IN IF ~originalCreationTimestamp.ok THEN Fail ELSE
    Ok([ originalSystemId          |-> originalSystemId.value,
         originalCreationTimestamp |-> originalCreationTimestamp.value ], originalCreationTimestamp.rest)

ZeroOrigOrderId4 ==
    [ originalSystemId          |-> [i \in 1 .. 8 |-> 0],
      originalCreationTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Orig Order Id at zero, then each field in turn at the values it is checked at *)
CheckedOrigOrderId4 ==
    { ZeroOrigOrderId4 }
        \cup { [ZeroOrigOrderId4 EXCEPT !.originalSystemId = one] : one \in Sample(8) }
        \cup { [ZeroOrigOrderId4 EXCEPT !.originalCreationTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Reject Message: 215 bytes                              *)
(***************************************************************************)

ExecutionReportRejectMessage ==
    [ originatorUserId         : Sample(20),
      execIDOrderExecId        : ExecIDOrderExecId4,
      clOrdId                  : Sample(8),
      symbolInt32              : Sample(4),
      ordTypeOrderTypeEnumNull : Sample(1),
      sideSideEnum             : Sample(1),
      origOrderId              : OrigOrderId4,
      origClOrdIDInt64Null     : Sample(8),
      orderStatus              : Sample(1),
      rejectResponseTo         : Sample(1),
      rejectReason             : Sample(1),
      exchangeCode             : Sample(4),
      memo                     : Sample(30),
      text                     : Sample(100) ]

EncodeExecutionReportRejectMessage(message) ==
    message.originatorUserId
        \o EncodeExecIDOrderExecId4(message.execIDOrderExecId)
        \o message.clOrdId
        \o message.symbolInt32
        \o message.ordTypeOrderTypeEnumNull
        \o message.sideSideEnum
        \o EncodeOrigOrderId4(message.origOrderId)
        \o message.origClOrdIDInt64Null
        \o message.orderStatus
        \o message.rejectResponseTo
        \o message.rejectReason
        \o message.exchangeCode
        \o message.memo
        \o message.text

DecodeExecutionReportRejectMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET execIDOrderExecId == DecodeExecIDOrderExecId4(originatorUserId.rest) IN IF ~execIDOrderExecId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(execIDOrderExecId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(clOrdId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnumNull == ReadBytes(symbolInt32.rest, 1) IN IF ~ordTypeOrderTypeEnumNull.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(ordTypeOrderTypeEnumNull.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET origOrderId == DecodeOrigOrderId4(sideSideEnum.rest) IN IF ~origOrderId.ok THEN Fail ELSE
    LET origClOrdIDInt64Null == ReadBytes(origOrderId.rest, 8) IN IF ~origClOrdIDInt64Null.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(origClOrdIDInt64Null.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET rejectResponseTo == ReadBytes(orderStatus.rest, 1) IN IF ~rejectResponseTo.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(rejectResponseTo.rest, 1) IN IF ~rejectReason.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(rejectReason.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET memo == ReadBytes(exchangeCode.rest, 30) IN IF ~memo.ok THEN Fail ELSE
    LET text == ReadBytes(memo.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ originatorUserId         |-> originatorUserId.value,
         execIDOrderExecId        |-> execIDOrderExecId.value,
         clOrdId                  |-> clOrdId.value,
         symbolInt32              |-> symbolInt32.value,
         ordTypeOrderTypeEnumNull |-> ordTypeOrderTypeEnumNull.value,
         sideSideEnum             |-> sideSideEnum.value,
         origOrderId              |-> origOrderId.value,
         origClOrdIDInt64Null     |-> origClOrdIDInt64Null.value,
         orderStatus              |-> orderStatus.value,
         rejectResponseTo         |-> rejectResponseTo.value,
         rejectReason             |-> rejectReason.value,
         exchangeCode             |-> exchangeCode.value,
         memo                     |-> memo.value,
         text                     |-> text.value ], text.rest)

ZeroExecutionReportRejectMessage ==
    [ originatorUserId         |-> [i \in 1 .. 20 |-> 0],
      execIDOrderExecId        |-> ZeroExecIDOrderExecId4,
      clOrdId                  |-> [i \in 1 .. 8 |-> 0],
      symbolInt32              |-> [i \in 1 .. 4 |-> 0],
      ordTypeOrderTypeEnumNull |-> [i \in 1 .. 1 |-> 0],
      sideSideEnum             |-> [i \in 1 .. 1 |-> 0],
      origOrderId              |-> ZeroOrigOrderId4,
      origClOrdIDInt64Null     |-> [i \in 1 .. 8 |-> 0],
      orderStatus              |-> [i \in 1 .. 1 |-> 0],
      rejectResponseTo         |-> [i \in 1 .. 1 |-> 0],
      rejectReason             |-> [i \in 1 .. 1 |-> 0],
      exchangeCode             |-> [i \in 1 .. 4 |-> 0],
      memo                     |-> [i \in 1 .. 30 |-> 0],
      text                     |-> [i \in 1 .. 100 |-> 0] ]

(* Execution Report Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportRejectMessage ==
    { ZeroExecutionReportRejectMessage }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.execIDOrderExecId = one] : one \in CheckedExecIDOrderExecId4 }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.ordTypeOrderTypeEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.origOrderId = one] : one \in CheckedOrigOrderId4 }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.origClOrdIDInt64Null = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.rejectResponseTo = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.rejectReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.memo = one] : one \in Sample(30) }
        \cup { [ZeroExecutionReportRejectMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Exec I D order Exec Id: 20 bytes                                        *)
(***************************************************************************)

ExecIDOrderExecId5 ==
    [ systemId                 : Sample(8),
      systemSequenceId         : Sample(4),
      transactTimeUtcTimestamp : Sample(8) ]

EncodeExecIDOrderExecId5(message) ==
    message.systemId
        \o message.systemSequenceId
        \o message.transactTimeUtcTimestamp

DecodeExecIDOrderExecId5(bytes) ==
    LET systemId == ReadBytes(bytes, 8) IN IF ~systemId.ok THEN Fail ELSE
    LET systemSequenceId == ReadBytes(systemId.rest, 4) IN IF ~systemSequenceId.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(systemSequenceId.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    Ok([ systemId                 |-> systemId.value,
         systemSequenceId         |-> systemSequenceId.value,
         transactTimeUtcTimestamp |-> transactTimeUtcTimestamp.value ], transactTimeUtcTimestamp.rest)

ZeroExecIDOrderExecId5 ==
    [ systemId                 |-> [i \in 1 .. 8 |-> 0],
      systemSequenceId         |-> [i \in 1 .. 4 |-> 0],
      transactTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Exec I D order Exec Id at zero, then each field in turn at the values it is checked at *)
CheckedExecIDOrderExecId5 ==
    { ZeroExecIDOrderExecId5 }
        \cup { [ZeroExecIDOrderExecId5 EXCEPT !.systemId = one] : one \in Sample(8) }
        \cup { [ZeroExecIDOrderExecId5 EXCEPT !.systemSequenceId = one] : one \in Sample(4) }
        \cup { [ZeroExecIDOrderExecId5 EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Orig Order Id: 16 bytes                                                 *)
(***************************************************************************)

OrigOrderId5 ==
    [ originalSystemId          : Sample(8),
      originalCreationTimestamp : Sample(8) ]

EncodeOrigOrderId5(message) ==
    message.originalSystemId
        \o message.originalCreationTimestamp

DecodeOrigOrderId5(bytes) ==
    LET originalSystemId == ReadBytes(bytes, 8) IN IF ~originalSystemId.ok THEN Fail ELSE
    LET originalCreationTimestamp == ReadBytes(originalSystemId.rest, 8) IN IF ~originalCreationTimestamp.ok THEN Fail ELSE
    Ok([ originalSystemId          |-> originalSystemId.value,
         originalCreationTimestamp |-> originalCreationTimestamp.value ], originalCreationTimestamp.rest)

ZeroOrigOrderId5 ==
    [ originalSystemId          |-> [i \in 1 .. 8 |-> 0],
      originalCreationTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Orig Order Id at zero, then each field in turn at the values it is checked at *)
CheckedOrigOrderId5 ==
    { ZeroOrigOrderId5 }
        \cup { [ZeroOrigOrderId5 EXCEPT !.originalSystemId = one] : one \in Sample(8) }
        \cup { [ZeroOrigOrderId5 EXCEPT !.originalCreationTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Snapshot Message: 380 bytes                            *)
(***************************************************************************)

ExecutionReportSnapshotMessage ==
    [ originatorUserId                 : Sample(20),
      execIDOrderExecId                : ExecIDOrderExecId5,
      clOrdId                          : Sample(8),
      symbolInt32                      : Sample(4),
      ordTypeOrderTypeEnum             : Sample(1),
      sideSideEnum                     : Sample(1),
      origOrderId                      : OrigOrderId5,
      maxShow                          : Sample(8),
      leavesQty                        : Sample(8),
      cumQty                           : Sample(8),
      priceDecimal9Null                : Sample(8),
      stopPx                           : Sample(8),
      expireDate                       : Sample(2),
      timePriority                     : Sample(8),
      timeInForceTimeInForceEnum       : Sample(1),
      orderStatus                      : Sample(1),
      orderState                       : Sample(1),
      giveUpClearingFirm               : Sample(4),
      clearingFirmInt32Null            : Sample(4),
      directElectronicAccess           : Sample(1),
      tradingCapacity                  : Sample(1),
      liquidityProvision               : Sample(1),
      commodityDerivIndicator          : Sample(1),
      investmentDecision               : Sample(8),
      executionDecision                : Sample(8),
      clientIdCode                     : Sample(8),
      mifidId                          : Sample(8),
      selfMatchPreventionId            : Sample(8),
      selfMatchPreventionInstruction   : Sample(1),
      manualOrderIndicator             : Sample(1),
      execInst                         : Sample(1),
      custOrderHandlingInst            : Sample(1),
      positionEffect                   : Sample(1),
      allocHandlInst                   : Sample(1),
      clearingAccountString14Null      : Sample(14),
      customerAccountRefId             : Sample(12),
      memo                             : Sample(30),
      allocationAccount                : Sample(20),
      onBehalfOfCompId                 : Sample(41),
      onBehalfOfSubIDString41Null      : Sample(41),
      onBehalfOfLocationIDString41Null : Sample(41) ]

EncodeExecutionReportSnapshotMessage(message) ==
    message.originatorUserId
        \o EncodeExecIDOrderExecId5(message.execIDOrderExecId)
        \o message.clOrdId
        \o message.symbolInt32
        \o message.ordTypeOrderTypeEnum
        \o message.sideSideEnum
        \o EncodeOrigOrderId5(message.origOrderId)
        \o message.maxShow
        \o message.leavesQty
        \o message.cumQty
        \o message.priceDecimal9Null
        \o message.stopPx
        \o message.expireDate
        \o message.timePriority
        \o message.timeInForceTimeInForceEnum
        \o message.orderStatus
        \o message.orderState
        \o message.giveUpClearingFirm
        \o message.clearingFirmInt32Null
        \o message.directElectronicAccess
        \o message.tradingCapacity
        \o message.liquidityProvision
        \o message.commodityDerivIndicator
        \o message.investmentDecision
        \o message.executionDecision
        \o message.clientIdCode
        \o message.mifidId
        \o message.selfMatchPreventionId
        \o message.selfMatchPreventionInstruction
        \o message.manualOrderIndicator
        \o message.execInst
        \o message.custOrderHandlingInst
        \o message.positionEffect
        \o message.allocHandlInst
        \o message.clearingAccountString14Null
        \o message.customerAccountRefId
        \o message.memo
        \o message.allocationAccount
        \o message.onBehalfOfCompId
        \o message.onBehalfOfSubIDString41Null
        \o message.onBehalfOfLocationIDString41Null

DecodeExecutionReportSnapshotMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET execIDOrderExecId == DecodeExecIDOrderExecId5(originatorUserId.rest) IN IF ~execIDOrderExecId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(execIDOrderExecId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(clOrdId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnum == ReadBytes(symbolInt32.rest, 1) IN IF ~ordTypeOrderTypeEnum.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(ordTypeOrderTypeEnum.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET origOrderId == DecodeOrigOrderId5(sideSideEnum.rest) IN IF ~origOrderId.ok THEN Fail ELSE
    LET maxShow == ReadBytes(origOrderId.rest, 8) IN IF ~maxShow.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(maxShow.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET priceDecimal9Null == ReadBytes(cumQty.rest, 8) IN IF ~priceDecimal9Null.ok THEN Fail ELSE
    LET stopPx == ReadBytes(priceDecimal9Null.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET expireDate == ReadBytes(stopPx.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET timePriority == ReadBytes(expireDate.rest, 8) IN IF ~timePriority.ok THEN Fail ELSE
    LET timeInForceTimeInForceEnum == ReadBytes(timePriority.rest, 1) IN IF ~timeInForceTimeInForceEnum.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(timeInForceTimeInForceEnum.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET orderState == ReadBytes(orderStatus.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET giveUpClearingFirm == ReadBytes(orderState.rest, 4) IN IF ~giveUpClearingFirm.ok THEN Fail ELSE
    LET clearingFirmInt32Null == ReadBytes(giveUpClearingFirm.rest, 4) IN IF ~clearingFirmInt32Null.ok THEN Fail ELSE
    LET directElectronicAccess == ReadBytes(clearingFirmInt32Null.rest, 1) IN IF ~directElectronicAccess.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(directElectronicAccess.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET liquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~liquidityProvision.ok THEN Fail ELSE
    LET commodityDerivIndicator == ReadBytes(liquidityProvision.rest, 1) IN IF ~commodityDerivIndicator.ok THEN Fail ELSE
    LET investmentDecision == ReadBytes(commodityDerivIndicator.rest, 8) IN IF ~investmentDecision.ok THEN Fail ELSE
    LET executionDecision == ReadBytes(investmentDecision.rest, 8) IN IF ~executionDecision.ok THEN Fail ELSE
    LET clientIdCode == ReadBytes(executionDecision.rest, 8) IN IF ~clientIdCode.ok THEN Fail ELSE
    LET mifidId == ReadBytes(clientIdCode.rest, 8) IN IF ~mifidId.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(mifidId.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(selfMatchPreventionId.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET execInst == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(execInst.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(custOrderHandlingInst.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET allocHandlInst == ReadBytes(positionEffect.rest, 1) IN IF ~allocHandlInst.ok THEN Fail ELSE
    LET clearingAccountString14Null == ReadBytes(allocHandlInst.rest, 14) IN IF ~clearingAccountString14Null.ok THEN Fail ELSE
    LET customerAccountRefId == ReadBytes(clearingAccountString14Null.rest, 12) IN IF ~customerAccountRefId.ok THEN Fail ELSE
    LET memo == ReadBytes(customerAccountRefId.rest, 30) IN IF ~memo.ok THEN Fail ELSE
    LET allocationAccount == ReadBytes(memo.rest, 20) IN IF ~allocationAccount.ok THEN Fail ELSE
    LET onBehalfOfCompId == ReadBytes(allocationAccount.rest, 41) IN IF ~onBehalfOfCompId.ok THEN Fail ELSE
    LET onBehalfOfSubIDString41Null == ReadBytes(onBehalfOfCompId.rest, 41) IN IF ~onBehalfOfSubIDString41Null.ok THEN Fail ELSE
    LET onBehalfOfLocationIDString41Null == ReadBytes(onBehalfOfSubIDString41Null.rest, 41) IN IF ~onBehalfOfLocationIDString41Null.ok THEN Fail ELSE
    Ok([ originatorUserId                 |-> originatorUserId.value,
         execIDOrderExecId                |-> execIDOrderExecId.value,
         clOrdId                          |-> clOrdId.value,
         symbolInt32                      |-> symbolInt32.value,
         ordTypeOrderTypeEnum             |-> ordTypeOrderTypeEnum.value,
         sideSideEnum                     |-> sideSideEnum.value,
         origOrderId                      |-> origOrderId.value,
         maxShow                          |-> maxShow.value,
         leavesQty                        |-> leavesQty.value,
         cumQty                           |-> cumQty.value,
         priceDecimal9Null                |-> priceDecimal9Null.value,
         stopPx                           |-> stopPx.value,
         expireDate                       |-> expireDate.value,
         timePriority                     |-> timePriority.value,
         timeInForceTimeInForceEnum       |-> timeInForceTimeInForceEnum.value,
         orderStatus                      |-> orderStatus.value,
         orderState                       |-> orderState.value,
         giveUpClearingFirm               |-> giveUpClearingFirm.value,
         clearingFirmInt32Null            |-> clearingFirmInt32Null.value,
         directElectronicAccess           |-> directElectronicAccess.value,
         tradingCapacity                  |-> tradingCapacity.value,
         liquidityProvision               |-> liquidityProvision.value,
         commodityDerivIndicator          |-> commodityDerivIndicator.value,
         investmentDecision               |-> investmentDecision.value,
         executionDecision                |-> executionDecision.value,
         clientIdCode                     |-> clientIdCode.value,
         mifidId                          |-> mifidId.value,
         selfMatchPreventionId            |-> selfMatchPreventionId.value,
         selfMatchPreventionInstruction   |-> selfMatchPreventionInstruction.value,
         manualOrderIndicator             |-> manualOrderIndicator.value,
         execInst                         |-> execInst.value,
         custOrderHandlingInst            |-> custOrderHandlingInst.value,
         positionEffect                   |-> positionEffect.value,
         allocHandlInst                   |-> allocHandlInst.value,
         clearingAccountString14Null      |-> clearingAccountString14Null.value,
         customerAccountRefId             |-> customerAccountRefId.value,
         memo                             |-> memo.value,
         allocationAccount                |-> allocationAccount.value,
         onBehalfOfCompId                 |-> onBehalfOfCompId.value,
         onBehalfOfSubIDString41Null      |-> onBehalfOfSubIDString41Null.value,
         onBehalfOfLocationIDString41Null |-> onBehalfOfLocationIDString41Null.value ], onBehalfOfLocationIDString41Null.rest)

ZeroExecutionReportSnapshotMessage ==
    [ originatorUserId                 |-> [i \in 1 .. 20 |-> 0],
      execIDOrderExecId                |-> ZeroExecIDOrderExecId5,
      clOrdId                          |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                      |-> [i \in 1 .. 4 |-> 0],
      ordTypeOrderTypeEnum             |-> [i \in 1 .. 1 |-> 0],
      sideSideEnum                     |-> [i \in 1 .. 1 |-> 0],
      origOrderId                      |-> ZeroOrigOrderId5,
      maxShow                          |-> [i \in 1 .. 8 |-> 0],
      leavesQty                        |-> [i \in 1 .. 8 |-> 0],
      cumQty                           |-> [i \in 1 .. 8 |-> 0],
      priceDecimal9Null                |-> [i \in 1 .. 8 |-> 0],
      stopPx                           |-> [i \in 1 .. 8 |-> 0],
      expireDate                       |-> [i \in 1 .. 2 |-> 0],
      timePriority                     |-> [i \in 1 .. 8 |-> 0],
      timeInForceTimeInForceEnum       |-> [i \in 1 .. 1 |-> 0],
      orderStatus                      |-> [i \in 1 .. 1 |-> 0],
      orderState                       |-> [i \in 1 .. 1 |-> 0],
      giveUpClearingFirm               |-> [i \in 1 .. 4 |-> 0],
      clearingFirmInt32Null            |-> [i \in 1 .. 4 |-> 0],
      directElectronicAccess           |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                  |-> [i \in 1 .. 1 |-> 0],
      liquidityProvision               |-> [i \in 1 .. 1 |-> 0],
      commodityDerivIndicator          |-> [i \in 1 .. 1 |-> 0],
      investmentDecision               |-> [i \in 1 .. 8 |-> 0],
      executionDecision                |-> [i \in 1 .. 8 |-> 0],
      clientIdCode                     |-> [i \in 1 .. 8 |-> 0],
      mifidId                          |-> [i \in 1 .. 8 |-> 0],
      selfMatchPreventionId            |-> [i \in 1 .. 8 |-> 0],
      selfMatchPreventionInstruction   |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator             |-> [i \in 1 .. 1 |-> 0],
      execInst                         |-> [i \in 1 .. 1 |-> 0],
      custOrderHandlingInst            |-> [i \in 1 .. 1 |-> 0],
      positionEffect                   |-> [i \in 1 .. 1 |-> 0],
      allocHandlInst                   |-> [i \in 1 .. 1 |-> 0],
      clearingAccountString14Null      |-> [i \in 1 .. 14 |-> 0],
      customerAccountRefId             |-> [i \in 1 .. 12 |-> 0],
      memo                             |-> [i \in 1 .. 30 |-> 0],
      allocationAccount                |-> [i \in 1 .. 20 |-> 0],
      onBehalfOfCompId                 |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfSubIDString41Null      |-> [i \in 1 .. 41 |-> 0],
      onBehalfOfLocationIDString41Null |-> [i \in 1 .. 41 |-> 0] ]

(* Execution Report Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportSnapshotMessage ==
    { ZeroExecutionReportSnapshotMessage }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.execIDOrderExecId = one] : one \in CheckedExecIDOrderExecId5 }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.ordTypeOrderTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.origOrderId = one] : one \in CheckedOrigOrderId5 }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.maxShow = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.priceDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.timePriority = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.timeInForceTimeInForceEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.giveUpClearingFirm = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.clearingFirmInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.directElectronicAccess = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.liquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.commodityDerivIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.investmentDecision = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.executionDecision = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.clientIdCode = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.mifidId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.allocHandlInst = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.clearingAccountString14Null = one] : one \in Sample(14) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.customerAccountRefId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.memo = one] : one \in Sample(30) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.allocationAccount = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.onBehalfOfCompId = one] : one \in Sample(41) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.onBehalfOfSubIDString41Null = one] : one \in Sample(41) }
        \cup { [ZeroExecutionReportSnapshotMessage EXCEPT !.onBehalfOfLocationIDString41Null = one] : one \in Sample(41) }

(***************************************************************************)
(* Orig Order Id: 16 bytes                                                 *)
(***************************************************************************)

OrigOrderId6 ==
    [ originalSystemId          : Sample(8),
      originalCreationTimestamp : Sample(8) ]

EncodeOrigOrderId6(message) ==
    message.originalSystemId
        \o message.originalCreationTimestamp

DecodeOrigOrderId6(bytes) ==
    LET originalSystemId == ReadBytes(bytes, 8) IN IF ~originalSystemId.ok THEN Fail ELSE
    LET originalCreationTimestamp == ReadBytes(originalSystemId.rest, 8) IN IF ~originalCreationTimestamp.ok THEN Fail ELSE
    Ok([ originalSystemId          |-> originalSystemId.value,
         originalCreationTimestamp |-> originalCreationTimestamp.value ], originalCreationTimestamp.rest)

ZeroOrigOrderId6 ==
    [ originalSystemId          |-> [i \in 1 .. 8 |-> 0],
      originalCreationTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Orig Order Id at zero, then each field in turn at the values it is checked at *)
CheckedOrigOrderId6 ==
    { ZeroOrigOrderId6 }
        \cup { [ZeroOrigOrderId6 EXCEPT !.originalSystemId = one] : one \in Sample(8) }
        \cup { [ZeroOrigOrderId6 EXCEPT !.originalCreationTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Report Trade Message: 227 bytes                               *)
(***************************************************************************)

ExecutionReportTradeMessage ==
    [ originatorUserId            : Sample(20),
      execIDInt64                 : Sample(8),
      clOrdId                     : Sample(8),
      symbolInt32                 : Sample(4),
      ordTypeOrderTypeEnum        : Sample(1),
      sideSideEnum                : Sample(1),
      orderId                     : Sample(8),
      origOrderId                 : OrigOrderId6,
      leavesQty                   : Sample(8),
      cumQty                      : Sample(8),
      lastPx                      : Sample(8),
      lastShares                  : Sample(8),
      transactTimeUtcTimestamp    : Sample(8),
      numOfLots                   : Sample(8),
      execType                    : Sample(1),
      tradeFlags                  : Sample(1),
      clearingFirmInt32Null       : Sample(4),
      clearingAccountString14Null : Sample(14),
      memo                        : Sample(30),
      execRefId                   : Sample(8),
      noLegExecutions             : Sample(2),
      secondaryExecId             : Sample(8),
      linkExecId                  : Sample(8),
      lastParPx                   : Sample(8),
      deliveryStartDate           : Sample(8),
      deliveryEndDate             : Sample(8),
      crossIDInt64Null            : Sample(8),
      crossTypeCrossTypeEnumNull  : Sample(1),
      waiverIndicator             : Sample(1),
      tradeType                   : Sample(3) ]

EncodeExecutionReportTradeMessage(message) ==
    message.originatorUserId
        \o message.execIDInt64
        \o message.clOrdId
        \o message.symbolInt32
        \o message.ordTypeOrderTypeEnum
        \o message.sideSideEnum
        \o message.orderId
        \o EncodeOrigOrderId6(message.origOrderId)
        \o message.leavesQty
        \o message.cumQty
        \o message.lastPx
        \o message.lastShares
        \o message.transactTimeUtcTimestamp
        \o message.numOfLots
        \o message.execType
        \o message.tradeFlags
        \o message.clearingFirmInt32Null
        \o message.clearingAccountString14Null
        \o message.memo
        \o message.execRefId
        \o message.noLegExecutions
        \o message.secondaryExecId
        \o message.linkExecId
        \o message.lastParPx
        \o message.deliveryStartDate
        \o message.deliveryEndDate
        \o message.crossIDInt64Null
        \o message.crossTypeCrossTypeEnumNull
        \o message.waiverIndicator
        \o message.tradeType

DecodeExecutionReportTradeMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET execIDInt64 == ReadBytes(originatorUserId.rest, 8) IN IF ~execIDInt64.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(execIDInt64.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(clOrdId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET ordTypeOrderTypeEnum == ReadBytes(symbolInt32.rest, 1) IN IF ~ordTypeOrderTypeEnum.ok THEN Fail ELSE
    LET sideSideEnum == ReadBytes(ordTypeOrderTypeEnum.rest, 1) IN IF ~sideSideEnum.ok THEN Fail ELSE
    LET orderId == ReadBytes(sideSideEnum.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET origOrderId == DecodeOrigOrderId6(orderId.rest) IN IF ~origOrderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(origOrderId.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(cumQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastPx.rest, 8) IN IF ~lastShares.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(lastShares.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    LET numOfLots == ReadBytes(transactTimeUtcTimestamp.rest, 8) IN IF ~numOfLots.ok THEN Fail ELSE
    LET execType == ReadBytes(numOfLots.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(execType.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    LET clearingFirmInt32Null == ReadBytes(tradeFlags.rest, 4) IN IF ~clearingFirmInt32Null.ok THEN Fail ELSE
    LET clearingAccountString14Null == ReadBytes(clearingFirmInt32Null.rest, 14) IN IF ~clearingAccountString14Null.ok THEN Fail ELSE
    LET memo == ReadBytes(clearingAccountString14Null.rest, 30) IN IF ~memo.ok THEN Fail ELSE
    LET execRefId == ReadBytes(memo.rest, 8) IN IF ~execRefId.ok THEN Fail ELSE
    LET noLegExecutions == ReadBytes(execRefId.rest, 2) IN IF ~noLegExecutions.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(noLegExecutions.rest, 8) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET linkExecId == ReadBytes(secondaryExecId.rest, 8) IN IF ~linkExecId.ok THEN Fail ELSE
    LET lastParPx == ReadBytes(linkExecId.rest, 8) IN IF ~lastParPx.ok THEN Fail ELSE
    LET deliveryStartDate == ReadBytes(lastParPx.rest, 8) IN IF ~deliveryStartDate.ok THEN Fail ELSE
    LET deliveryEndDate == ReadBytes(deliveryStartDate.rest, 8) IN IF ~deliveryEndDate.ok THEN Fail ELSE
    LET crossIDInt64Null == ReadBytes(deliveryEndDate.rest, 8) IN IF ~crossIDInt64Null.ok THEN Fail ELSE
    LET crossTypeCrossTypeEnumNull == ReadBytes(crossIDInt64Null.rest, 1) IN IF ~crossTypeCrossTypeEnumNull.ok THEN Fail ELSE
    LET waiverIndicator == ReadBytes(crossTypeCrossTypeEnumNull.rest, 1) IN IF ~waiverIndicator.ok THEN Fail ELSE
    LET tradeType == ReadBytes(waiverIndicator.rest, 3) IN IF ~tradeType.ok THEN Fail ELSE
    Ok([ originatorUserId            |-> originatorUserId.value,
         execIDInt64                 |-> execIDInt64.value,
         clOrdId                     |-> clOrdId.value,
         symbolInt32                 |-> symbolInt32.value,
         ordTypeOrderTypeEnum        |-> ordTypeOrderTypeEnum.value,
         sideSideEnum                |-> sideSideEnum.value,
         orderId                     |-> orderId.value,
         origOrderId                 |-> origOrderId.value,
         leavesQty                   |-> leavesQty.value,
         cumQty                      |-> cumQty.value,
         lastPx                      |-> lastPx.value,
         lastShares                  |-> lastShares.value,
         transactTimeUtcTimestamp    |-> transactTimeUtcTimestamp.value,
         numOfLots                   |-> numOfLots.value,
         execType                    |-> execType.value,
         tradeFlags                  |-> tradeFlags.value,
         clearingFirmInt32Null       |-> clearingFirmInt32Null.value,
         clearingAccountString14Null |-> clearingAccountString14Null.value,
         memo                        |-> memo.value,
         execRefId                   |-> execRefId.value,
         noLegExecutions             |-> noLegExecutions.value,
         secondaryExecId             |-> secondaryExecId.value,
         linkExecId                  |-> linkExecId.value,
         lastParPx                   |-> lastParPx.value,
         deliveryStartDate           |-> deliveryStartDate.value,
         deliveryEndDate             |-> deliveryEndDate.value,
         crossIDInt64Null            |-> crossIDInt64Null.value,
         crossTypeCrossTypeEnumNull  |-> crossTypeCrossTypeEnumNull.value,
         waiverIndicator             |-> waiverIndicator.value,
         tradeType                   |-> tradeType.value ], tradeType.rest)

ZeroExecutionReportTradeMessage ==
    [ originatorUserId            |-> [i \in 1 .. 20 |-> 0],
      execIDInt64                 |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      symbolInt32                 |-> [i \in 1 .. 4 |-> 0],
      ordTypeOrderTypeEnum        |-> [i \in 1 .. 1 |-> 0],
      sideSideEnum                |-> [i \in 1 .. 1 |-> 0],
      orderId                     |-> [i \in 1 .. 8 |-> 0],
      origOrderId                 |-> ZeroOrigOrderId6,
      leavesQty                   |-> [i \in 1 .. 8 |-> 0],
      cumQty                      |-> [i \in 1 .. 8 |-> 0],
      lastPx                      |-> [i \in 1 .. 8 |-> 0],
      lastShares                  |-> [i \in 1 .. 8 |-> 0],
      transactTimeUtcTimestamp    |-> [i \in 1 .. 8 |-> 0],
      numOfLots                   |-> [i \in 1 .. 8 |-> 0],
      execType                    |-> [i \in 1 .. 1 |-> 0],
      tradeFlags                  |-> [i \in 1 .. 1 |-> 0],
      clearingFirmInt32Null       |-> [i \in 1 .. 4 |-> 0],
      clearingAccountString14Null |-> [i \in 1 .. 14 |-> 0],
      memo                        |-> [i \in 1 .. 30 |-> 0],
      execRefId                   |-> [i \in 1 .. 8 |-> 0],
      noLegExecutions             |-> [i \in 1 .. 2 |-> 0],
      secondaryExecId             |-> [i \in 1 .. 8 |-> 0],
      linkExecId                  |-> [i \in 1 .. 8 |-> 0],
      lastParPx                   |-> [i \in 1 .. 8 |-> 0],
      deliveryStartDate           |-> [i \in 1 .. 8 |-> 0],
      deliveryEndDate             |-> [i \in 1 .. 8 |-> 0],
      crossIDInt64Null            |-> [i \in 1 .. 8 |-> 0],
      crossTypeCrossTypeEnumNull  |-> [i \in 1 .. 1 |-> 0],
      waiverIndicator             |-> [i \in 1 .. 1 |-> 0],
      tradeType                   |-> [i \in 1 .. 3 |-> 0] ]

(* Execution Report Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportTradeMessage ==
    { ZeroExecutionReportTradeMessage }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.execIDInt64 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.ordTypeOrderTypeEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.sideSideEnum = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.origOrderId = one] : one \in CheckedOrigOrderId6 }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastShares = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.numOfLots = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.clearingFirmInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.clearingAccountString14Null = one] : one \in Sample(14) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.memo = one] : one \in Sample(30) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.execRefId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.noLegExecutions = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.secondaryExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.linkExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.lastParPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.deliveryStartDate = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.deliveryEndDate = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.crossIDInt64Null = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.crossTypeCrossTypeEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.waiverIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportTradeMessage EXCEPT !.tradeType = one] : one \in Sample(3) }

(***************************************************************************)
(* Quote Report Message: 60 bytes                                          *)
(***************************************************************************)

QuoteReportMessage ==
    [ originatorUserId         : Sample(20),
      sideSideEnumNull         : Sample(1),
      symbolInt32              : Sample(4),
      rfqReqId                 : Sample(8),
      rfqSystemId              : Sample(8),
      transactTimeUtcTimestamp : Sample(8),
      orderQtyDecimal9Null     : Sample(8),
      quoteAckStatus           : Sample(2),
      quoteRejectReason        : Sample(1) ]

EncodeQuoteReportMessage(message) ==
    message.originatorUserId
        \o message.sideSideEnumNull
        \o message.symbolInt32
        \o message.rfqReqId
        \o message.rfqSystemId
        \o message.transactTimeUtcTimestamp
        \o message.orderQtyDecimal9Null
        \o message.quoteAckStatus
        \o message.quoteRejectReason

DecodeQuoteReportMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET sideSideEnumNull == ReadBytes(originatorUserId.rest, 1) IN IF ~sideSideEnumNull.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(sideSideEnumNull.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET rfqReqId == ReadBytes(symbolInt32.rest, 8) IN IF ~rfqReqId.ok THEN Fail ELSE
    LET rfqSystemId == ReadBytes(rfqReqId.rest, 8) IN IF ~rfqSystemId.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(rfqSystemId.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    LET orderQtyDecimal9Null == ReadBytes(transactTimeUtcTimestamp.rest, 8) IN IF ~orderQtyDecimal9Null.ok THEN Fail ELSE
    LET quoteAckStatus == ReadBytes(orderQtyDecimal9Null.rest, 2) IN IF ~quoteAckStatus.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteAckStatus.rest, 1) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    Ok([ originatorUserId         |-> originatorUserId.value,
         sideSideEnumNull         |-> sideSideEnumNull.value,
         symbolInt32              |-> symbolInt32.value,
         rfqReqId                 |-> rfqReqId.value,
         rfqSystemId              |-> rfqSystemId.value,
         transactTimeUtcTimestamp |-> transactTimeUtcTimestamp.value,
         orderQtyDecimal9Null     |-> orderQtyDecimal9Null.value,
         quoteAckStatus           |-> quoteAckStatus.value,
         quoteRejectReason        |-> quoteRejectReason.value ], quoteRejectReason.rest)

ZeroQuoteReportMessage ==
    [ originatorUserId         |-> [i \in 1 .. 20 |-> 0],
      sideSideEnumNull         |-> [i \in 1 .. 1 |-> 0],
      symbolInt32              |-> [i \in 1 .. 4 |-> 0],
      rfqReqId                 |-> [i \in 1 .. 8 |-> 0],
      rfqSystemId              |-> [i \in 1 .. 8 |-> 0],
      transactTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0],
      orderQtyDecimal9Null     |-> [i \in 1 .. 8 |-> 0],
      quoteAckStatus           |-> [i \in 1 .. 2 |-> 0],
      quoteRejectReason        |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Report Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReportMessage ==
    { ZeroQuoteReportMessage }
        \cup { [ZeroQuoteReportMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroQuoteReportMessage EXCEPT !.sideSideEnumNull = one] : one \in Sample(1) }
        \cup { [ZeroQuoteReportMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReportMessage EXCEPT !.rfqReqId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReportMessage EXCEPT !.rfqSystemId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReportMessage EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReportMessage EXCEPT !.orderQtyDecimal9Null = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReportMessage EXCEPT !.quoteAckStatus = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReportMessage EXCEPT !.quoteRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Cross Report Message: 145 bytes                               *)
(***************************************************************************)

NewOrderCrossReportMessage ==
    [ originatorUserId         : Sample(20),
      symbolInt32              : Sample(4),
      crossIDInt64             : Sample(8),
      transactTimeUtcTimestamp : Sample(8),
      rfcStatus                : Sample(1),
      exchangeCode             : Sample(4),
      text                     : Sample(100) ]

EncodeNewOrderCrossReportMessage(message) ==
    message.originatorUserId
        \o message.symbolInt32
        \o message.crossIDInt64
        \o message.transactTimeUtcTimestamp
        \o message.rfcStatus
        \o message.exchangeCode
        \o message.text

DecodeNewOrderCrossReportMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(originatorUserId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET crossIDInt64 == ReadBytes(symbolInt32.rest, 8) IN IF ~crossIDInt64.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(crossIDInt64.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    LET rfcStatus == ReadBytes(transactTimeUtcTimestamp.rest, 1) IN IF ~rfcStatus.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(rfcStatus.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ originatorUserId         |-> originatorUserId.value,
         symbolInt32              |-> symbolInt32.value,
         crossIDInt64             |-> crossIDInt64.value,
         transactTimeUtcTimestamp |-> transactTimeUtcTimestamp.value,
         rfcStatus                |-> rfcStatus.value,
         exchangeCode             |-> exchangeCode.value,
         text                     |-> text.value ], text.rest)

ZeroNewOrderCrossReportMessage ==
    [ originatorUserId         |-> [i \in 1 .. 20 |-> 0],
      symbolInt32              |-> [i \in 1 .. 4 |-> 0],
      crossIDInt64             |-> [i \in 1 .. 8 |-> 0],
      transactTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0],
      rfcStatus                |-> [i \in 1 .. 1 |-> 0],
      exchangeCode             |-> [i \in 1 .. 4 |-> 0],
      text                     |-> [i \in 1 .. 100 |-> 0] ]

(* New Order Cross Report Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCrossReportMessage ==
    { ZeroNewOrderCrossReportMessage }
        \cup { [ZeroNewOrderCrossReportMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCrossReportMessage EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossReportMessage EXCEPT !.crossIDInt64 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossReportMessage EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCrossReportMessage EXCEPT !.rfcStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCrossReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCrossReportMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Order Mass Cancel Report Message: 151 bytes                             *)
(***************************************************************************)

OrderMassCancelReportMessage ==
    [ originatorUserId         : Sample(20),
      symbolInt32Null          : Sample(4),
      clOrdId                  : Sample(8),
      transactTimeUtcTimestamp : Sample(8),
      marketTypeIDInt32Null    : Sample(4),
      massCancelRequestType    : Sample(1),
      massCancelResponse       : Sample(1),
      massCancelRejectReason   : Sample(1),
      exchangeCode             : Sample(4),
      text                     : Sample(100) ]

EncodeOrderMassCancelReportMessage(message) ==
    message.originatorUserId
        \o message.symbolInt32Null
        \o message.clOrdId
        \o message.transactTimeUtcTimestamp
        \o message.marketTypeIDInt32Null
        \o message.massCancelRequestType
        \o message.massCancelResponse
        \o message.massCancelRejectReason
        \o message.exchangeCode
        \o message.text

DecodeOrderMassCancelReportMessage(bytes) ==
    LET originatorUserId == ReadBytes(bytes, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET symbolInt32Null == ReadBytes(originatorUserId.rest, 4) IN IF ~symbolInt32Null.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(symbolInt32Null.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET transactTimeUtcTimestamp == ReadBytes(clOrdId.rest, 8) IN IF ~transactTimeUtcTimestamp.ok THEN Fail ELSE
    LET marketTypeIDInt32Null == ReadBytes(transactTimeUtcTimestamp.rest, 4) IN IF ~marketTypeIDInt32Null.ok THEN Fail ELSE
    LET massCancelRequestType == ReadBytes(marketTypeIDInt32Null.rest, 1) IN IF ~massCancelRequestType.ok THEN Fail ELSE
    LET massCancelResponse == ReadBytes(massCancelRequestType.rest, 1) IN IF ~massCancelResponse.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(massCancelResponse.rest, 1) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(massCancelRejectReason.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ originatorUserId         |-> originatorUserId.value,
         symbolInt32Null          |-> symbolInt32Null.value,
         clOrdId                  |-> clOrdId.value,
         transactTimeUtcTimestamp |-> transactTimeUtcTimestamp.value,
         marketTypeIDInt32Null    |-> marketTypeIDInt32Null.value,
         massCancelRequestType    |-> massCancelRequestType.value,
         massCancelResponse       |-> massCancelResponse.value,
         massCancelRejectReason   |-> massCancelRejectReason.value,
         exchangeCode             |-> exchangeCode.value,
         text                     |-> text.value ], text.rest)

ZeroOrderMassCancelReportMessage ==
    [ originatorUserId         |-> [i \in 1 .. 20 |-> 0],
      symbolInt32Null          |-> [i \in 1 .. 4 |-> 0],
      clOrdId                  |-> [i \in 1 .. 8 |-> 0],
      transactTimeUtcTimestamp |-> [i \in 1 .. 8 |-> 0],
      marketTypeIDInt32Null    |-> [i \in 1 .. 4 |-> 0],
      massCancelRequestType    |-> [i \in 1 .. 1 |-> 0],
      massCancelResponse       |-> [i \in 1 .. 1 |-> 0],
      massCancelRejectReason   |-> [i \in 1 .. 1 |-> 0],
      exchangeCode             |-> [i \in 1 .. 4 |-> 0],
      text                     |-> [i \in 1 .. 100 |-> 0] ]

(* Order Mass Cancel Report Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelReportMessage ==
    { ZeroOrderMassCancelReportMessage }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.symbolInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.transactTimeUtcTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.marketTypeIDInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.massCancelRequestType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.massCancelResponse = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.massCancelRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Mass Quote Report Message no Quote Sets Group: 121 bytes                *)
(***************************************************************************)

MassQuoteReportMessageNoQuoteSetsGroup ==
    [ quoteSetId                 : Sample(4),
      underlyingSymbolInt32      : Sample(4),
      quoteEntryId               : Sample(4),
      symbolInt32                : Sample(4),
      quoteEntryRejectReason     : Sample(1),
      quoteEntryExchangeCode     : Sample(4),
      quoteEntryRejectReasonText : Sample(100) ]

EncodeMassQuoteReportMessageNoQuoteSetsGroup(message) ==
    message.quoteSetId
        \o message.underlyingSymbolInt32
        \o message.quoteEntryId
        \o message.symbolInt32
        \o message.quoteEntryRejectReason
        \o message.quoteEntryExchangeCode
        \o message.quoteEntryRejectReasonText

DecodeMassQuoteReportMessageNoQuoteSetsGroup(bytes) ==
    LET quoteSetId == ReadBytes(bytes, 4) IN IF ~quoteSetId.ok THEN Fail ELSE
    LET underlyingSymbolInt32 == ReadBytes(quoteSetId.rest, 4) IN IF ~underlyingSymbolInt32.ok THEN Fail ELSE
    LET quoteEntryId == ReadBytes(underlyingSymbolInt32.rest, 4) IN IF ~quoteEntryId.ok THEN Fail ELSE
    LET symbolInt32 == ReadBytes(quoteEntryId.rest, 4) IN IF ~symbolInt32.ok THEN Fail ELSE
    LET quoteEntryRejectReason == ReadBytes(symbolInt32.rest, 1) IN IF ~quoteEntryRejectReason.ok THEN Fail ELSE
    LET quoteEntryExchangeCode == ReadBytes(quoteEntryRejectReason.rest, 4) IN IF ~quoteEntryExchangeCode.ok THEN Fail ELSE
    LET quoteEntryRejectReasonText == ReadBytes(quoteEntryExchangeCode.rest, 100) IN IF ~quoteEntryRejectReasonText.ok THEN Fail ELSE
    Ok([ quoteSetId                 |-> quoteSetId.value,
         underlyingSymbolInt32      |-> underlyingSymbolInt32.value,
         quoteEntryId               |-> quoteEntryId.value,
         symbolInt32                |-> symbolInt32.value,
         quoteEntryRejectReason     |-> quoteEntryRejectReason.value,
         quoteEntryExchangeCode     |-> quoteEntryExchangeCode.value,
         quoteEntryRejectReasonText |-> quoteEntryRejectReasonText.value ], quoteEntryRejectReasonText.rest)

ZeroMassQuoteReportMessageNoQuoteSetsGroup ==
    [ quoteSetId                 |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbolInt32      |-> [i \in 1 .. 4 |-> 0],
      quoteEntryId               |-> [i \in 1 .. 4 |-> 0],
      symbolInt32                |-> [i \in 1 .. 4 |-> 0],
      quoteEntryRejectReason     |-> [i \in 1 .. 1 |-> 0],
      quoteEntryExchangeCode     |-> [i \in 1 .. 4 |-> 0],
      quoteEntryRejectReasonText |-> [i \in 1 .. 100 |-> 0] ]

(* Mass Quote Report Message no Quote Sets Group at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteReportMessageNoQuoteSetsGroup ==
    { ZeroMassQuoteReportMessageNoQuoteSetsGroup }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroup EXCEPT !.quoteSetId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroup EXCEPT !.underlyingSymbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroup EXCEPT !.quoteEntryId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroup EXCEPT !.symbolInt32 = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroup EXCEPT !.quoteEntryRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroup EXCEPT !.quoteEntryExchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroup EXCEPT !.quoteEntryRejectReasonText = one] : one \in Sample(100) }

(* A run of Mass Quote Report Message no Quote Sets Group, written one after another *)
RECURSIVE EncodeMassQuoteReportMessageNoQuoteSetsGroupList(_)
EncodeMassQuoteReportMessageNoQuoteSetsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassQuoteReportMessageNoQuoteSetsGroup(Head(messages)) \o EncodeMassQuoteReportMessageNoQuoteSetsGroupList(Tail(messages))

(* As many Mass Quote Report Message no Quote Sets Group as the field that counts them says *)
RECURSIVE ReadMassQuoteReportMessageNoQuoteSetsGroupList(_, _)
ReadMassQuoteReportMessageNoQuoteSetsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMassQuoteReportMessageNoQuoteSetsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassQuoteReportMessageNoQuoteSetsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Quote Report Message no Quote Sets Group of each kind, for the lists that carry them *)
OneMassQuoteReportMessageNoQuoteSetsGroup == { ZeroMassQuoteReportMessageNoQuoteSetsGroup }

(***************************************************************************)
(* Mass Quote Report Message no Quote Sets Groups                          *)
(***************************************************************************)

MassQuoteReportMessageNoQuoteSetsGroups ==
    [ blockLength                            : Sample(2),
      massQuoteReportMessageNoQuoteSetsGroup : SampleLists(OneMassQuoteReportMessageNoQuoteSetsGroup) ]

EncodeMassQuoteReportMessageNoQuoteSetsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.massQuoteReportMessageNoQuoteSetsGroup), 2)
        \o EncodeMassQuoteReportMessageNoQuoteSetsGroupList(message.massQuoteReportMessageNoQuoteSetsGroup)

DecodeMassQuoteReportMessageNoQuoteSetsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET massQuoteReportMessageNoQuoteSetsGroup == ReadMassQuoteReportMessageNoQuoteSetsGroupList(numInGroup.rest, numInGroup.value) IN IF ~massQuoteReportMessageNoQuoteSetsGroup.ok THEN Fail ELSE
    Ok([ blockLength                            |-> blockLength.value,
         massQuoteReportMessageNoQuoteSetsGroup |-> massQuoteReportMessageNoQuoteSetsGroup.value ], massQuoteReportMessageNoQuoteSetsGroup.rest)

ZeroMassQuoteReportMessageNoQuoteSetsGroups ==
    [ blockLength                            |-> [i \in 1 .. 2 |-> 0],
      massQuoteReportMessageNoQuoteSetsGroup |-> << >> ]

(* Mass Quote Report Message no Quote Sets Groups at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteReportMessageNoQuoteSetsGroups ==
    { ZeroMassQuoteReportMessageNoQuoteSetsGroups }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteReportMessageNoQuoteSetsGroups EXCEPT !.massQuoteReportMessageNoQuoteSetsGroup = one] : one \in SampleLists(OneMassQuoteReportMessageNoQuoteSetsGroup) }

(***************************************************************************)
(* Mass Quote Report Message                                               *)
(***************************************************************************)

MassQuoteReportMessage ==
    [ quoteId                                 : Sample(8),
      originatorUserId                        : Sample(20),
      riskProtectionReset                     : Sample(1),
      quoteAckStatus                          : Sample(2),
      quoteRejectReason                       : Sample(1),
      transactTimeUtcTimestampNull            : Sample(8),
      meAcceptanceTimeUtcTimestampNull        : Sample(8),
      exchangeCode                            : Sample(4),
      text                                    : Sample(100),
      massQuoteReportMessageNoQuoteSetsGroups : MassQuoteReportMessageNoQuoteSetsGroups ]

EncodeMassQuoteReportMessage(message) ==
    message.quoteId
        \o message.originatorUserId
        \o message.riskProtectionReset
        \o message.quoteAckStatus
        \o message.quoteRejectReason
        \o message.transactTimeUtcTimestampNull
        \o message.meAcceptanceTimeUtcTimestampNull
        \o message.exchangeCode
        \o message.text
        \o EncodeMassQuoteReportMessageNoQuoteSetsGroups(message.massQuoteReportMessageNoQuoteSetsGroups)

DecodeMassQuoteReportMessage(bytes) ==
    LET quoteId == ReadBytes(bytes, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET originatorUserId == ReadBytes(quoteId.rest, 20) IN IF ~originatorUserId.ok THEN Fail ELSE
    LET riskProtectionReset == ReadBytes(originatorUserId.rest, 1) IN IF ~riskProtectionReset.ok THEN Fail ELSE
    LET quoteAckStatus == ReadBytes(riskProtectionReset.rest, 2) IN IF ~quoteAckStatus.ok THEN Fail ELSE
    LET quoteRejectReason == ReadBytes(quoteAckStatus.rest, 1) IN IF ~quoteRejectReason.ok THEN Fail ELSE
    LET transactTimeUtcTimestampNull == ReadBytes(quoteRejectReason.rest, 8) IN IF ~transactTimeUtcTimestampNull.ok THEN Fail ELSE
    LET meAcceptanceTimeUtcTimestampNull == ReadBytes(transactTimeUtcTimestampNull.rest, 8) IN IF ~meAcceptanceTimeUtcTimestampNull.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(meAcceptanceTimeUtcTimestampNull.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    LET massQuoteReportMessageNoQuoteSetsGroups == DecodeMassQuoteReportMessageNoQuoteSetsGroups(text.rest) IN IF ~massQuoteReportMessageNoQuoteSetsGroups.ok THEN Fail ELSE
    Ok([ quoteId                                 |-> quoteId.value,
         originatorUserId                        |-> originatorUserId.value,
         riskProtectionReset                     |-> riskProtectionReset.value,
         quoteAckStatus                          |-> quoteAckStatus.value,
         quoteRejectReason                       |-> quoteRejectReason.value,
         transactTimeUtcTimestampNull            |-> transactTimeUtcTimestampNull.value,
         meAcceptanceTimeUtcTimestampNull        |-> meAcceptanceTimeUtcTimestampNull.value,
         exchangeCode                            |-> exchangeCode.value,
         text                                    |-> text.value,
         massQuoteReportMessageNoQuoteSetsGroups |-> massQuoteReportMessageNoQuoteSetsGroups.value ], massQuoteReportMessageNoQuoteSetsGroups.rest)

ZeroMassQuoteReportMessage ==
    [ quoteId                                 |-> [i \in 1 .. 8 |-> 0],
      originatorUserId                        |-> [i \in 1 .. 20 |-> 0],
      riskProtectionReset                     |-> [i \in 1 .. 1 |-> 0],
      quoteAckStatus                          |-> [i \in 1 .. 2 |-> 0],
      quoteRejectReason                       |-> [i \in 1 .. 1 |-> 0],
      transactTimeUtcTimestampNull            |-> [i \in 1 .. 8 |-> 0],
      meAcceptanceTimeUtcTimestampNull        |-> [i \in 1 .. 8 |-> 0],
      exchangeCode                            |-> [i \in 1 .. 4 |-> 0],
      text                                    |-> [i \in 1 .. 100 |-> 0],
      massQuoteReportMessageNoQuoteSetsGroups |-> ZeroMassQuoteReportMessageNoQuoteSetsGroups ]

(* Mass Quote Report Message at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteReportMessage ==
    { ZeroMassQuoteReportMessage }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.originatorUserId = one] : one \in Sample(20) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.riskProtectionReset = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.quoteAckStatus = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.quoteRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.transactTimeUtcTimestampNull = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.meAcceptanceTimeUtcTimestampNull = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.text = one] : one \in Sample(100) }
        \cup { [ZeroMassQuoteReportMessage EXCEPT !.massQuoteReportMessageNoQuoteSetsGroups = one] : one \in CheckedMassQuoteReportMessageNoQuoteSetsGroups }

(***************************************************************************)
(* Resend Request Message: 8 bytes                                         *)
(***************************************************************************)

ResendRequestMessage ==
    [ beginSeqNo : Sample(4),
      endSeqNo   : Sample(4) ]

EncodeResendRequestMessage(message) ==
    message.beginSeqNo
        \o message.endSeqNo

DecodeResendRequestMessage(bytes) ==
    LET beginSeqNo == ReadBytes(bytes, 4) IN IF ~beginSeqNo.ok THEN Fail ELSE
    LET endSeqNo == ReadBytes(beginSeqNo.rest, 4) IN IF ~endSeqNo.ok THEN Fail ELSE
    Ok([ beginSeqNo |-> beginSeqNo.value,
         endSeqNo   |-> endSeqNo.value ], endSeqNo.rest)

ZeroResendRequestMessage ==
    [ beginSeqNo |-> [i \in 1 .. 4 |-> 0],
      endSeqNo   |-> [i \in 1 .. 4 |-> 0] ]

(* Resend Request Message at zero, then each field in turn at the values it is checked at *)
CheckedResendRequestMessage ==
    { ZeroResendRequestMessage }
        \cup { [ZeroResendRequestMessage EXCEPT !.beginSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroResendRequestMessage EXCEPT !.endSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Resend Report Message: 113 bytes                                        *)
(***************************************************************************)

ResendReportMessage ==
    [ beginSeqNo   : Sample(4),
      endSeqNo     : Sample(4),
      status       : Sample(1),
      exchangeCode : Sample(4),
      text         : Sample(100) ]

EncodeResendReportMessage(message) ==
    message.beginSeqNo
        \o message.endSeqNo
        \o message.status
        \o message.exchangeCode
        \o message.text

DecodeResendReportMessage(bytes) ==
    LET beginSeqNo == ReadBytes(bytes, 4) IN IF ~beginSeqNo.ok THEN Fail ELSE
    LET endSeqNo == ReadBytes(beginSeqNo.rest, 4) IN IF ~endSeqNo.ok THEN Fail ELSE
    LET status == ReadBytes(endSeqNo.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(status.rest, 4) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET text == ReadBytes(exchangeCode.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ beginSeqNo   |-> beginSeqNo.value,
         endSeqNo     |-> endSeqNo.value,
         status       |-> status.value,
         exchangeCode |-> exchangeCode.value,
         text         |-> text.value ], text.rest)

ZeroResendReportMessage ==
    [ beginSeqNo   |-> [i \in 1 .. 4 |-> 0],
      endSeqNo     |-> [i \in 1 .. 4 |-> 0],
      status       |-> [i \in 1 .. 1 |-> 0],
      exchangeCode |-> [i \in 1 .. 4 |-> 0],
      text         |-> [i \in 1 .. 100 |-> 0] ]

(* Resend Report Message at zero, then each field in turn at the values it is checked at *)
CheckedResendReportMessage ==
    { ZeroResendReportMessage }
        \cup { [ZeroResendReportMessage EXCEPT !.beginSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroResendReportMessage EXCEPT !.endSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroResendReportMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroResendReportMessage EXCEPT !.exchangeCode = one] : one \in Sample(4) }
        \cup { [ZeroResendReportMessage EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Sequence Reset Message: 5 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo    : Sample(4),
      gapFillFlag : Sample(1) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo
        \o message.gapFillFlag

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    LET gapFillFlag == ReadBytes(newSeqNo.rest, 1) IN IF ~gapFillFlag.ok THEN Fail ELSE
    Ok([ newSeqNo    |-> newSeqNo.value,
         gapFillFlag |-> gapFillFlag.value ], gapFillFlag.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo    |-> [i \in 1 .. 4 |-> 0],
      gapFillFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSequenceResetMessage EXCEPT !.gapFillFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

SimpleOpenFramingHeaderMessageCode == 0  \* 0x00
LogonRequestMessageCode == 1  \* 0x01
LogonReportMessageCode == 101  \* 0x65
LogoutRequestMessageCode == 13  \* 0x0d
LogoutReportMessageCode == 113  \* 0x71
HeartBeatMessageCode == 51  \* 0x33
ErrorMessageCode == 114  \* 0x72
NewsMessageCode == 116  \* 0x74
SecurityDefinitionReportStrategyMessageCode == 112  \* 0x70
SecurityDefinitionReportMessageCode == 115  \* 0x73
SecurityDefinitionRejectMessageCode == 155  \* 0x9b
SecurityDefinitionRequestMessageCode == 15  \* 0x0f
SecurityDefinitionReportProductMessageCode == 154  \* 0x9a
IpRequestMessageCode == 2001  \* 0x7d1
IpReportMessageCode == 2002  \* 0x7d2
TraderLogonRequestMessageCode == 2  \* 0x02
TraderLogonReportMessageCode == 102  \* 0x66
TraderLogoutRequestMessageCode == 3  \* 0x03
TraderLogoutReportMessageCode == 103  \* 0x67
NewOrderRequestMessageCode == 4  \* 0x04
CancelReplaceRequestMessageCode == 5  \* 0x05
CancelRequestMessageCode == 6  \* 0x06
QuoteRequestMessageCode == 7  \* 0x07
NewOrderCrossRequestMessageCode == 8  \* 0x08
OrderMassCancelRequestMessageCode == 9  \* 0x09
MassQuoteRequestMessageCode == 10  \* 0x0a
QuoteCancelRequestMessageCode == 11  \* 0x0b
SecurityDefinitionRequestCreateStrategyMessageCode == 12  \* 0x0c
SecurityDefinitionRequestCreateFlexMessageCode == 14  \* 0x0e
ExecutionReportNewMessageCode == 104  \* 0x68
ExecutionReportModifyMessageCode == 105  \* 0x69
ExecutionReportCancelMessageCode == 106  \* 0x6a
ExecutionReportRejectMessageCode == 151  \* 0x97
ExecutionReportSnapshotMessageCode == 152  \* 0x98
ExecutionReportTradeMessageCode == 153  \* 0x99
QuoteReportMessageCode == 107  \* 0x6b
NewOrderCrossReportMessageCode == 108  \* 0x6c
OrderMassCancelReportMessageCode == 109  \* 0x6d
MassQuoteReportMessageCode == 110  \* 0x6e
ResendRequestMessageCode == 16  \* 0x10
ResendReportMessageCode == 117  \* 0x75
SequenceResetMessageCode == 111  \* 0x6f

Payload ==
    [ tag : {SimpleOpenFramingHeaderMessageCode}, body : SimpleOpenFramingHeaderMessage ]
        \cup [ tag : {LogonRequestMessageCode}, body : LogonRequestMessage ]
        \cup [ tag : {LogonReportMessageCode}, body : LogonReportMessage ]
        \cup [ tag : {LogoutRequestMessageCode}, body : LogoutRequestMessage ]
        \cup [ tag : {LogoutReportMessageCode}, body : LogoutReportMessage ]
        \cup [ tag : {HeartBeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ErrorMessageCode}, body : ErrorMessage ]
        \cup [ tag : {NewsMessageCode}, body : NewsMessage ]
        \cup [ tag : {SecurityDefinitionReportStrategyMessageCode}, body : SecurityDefinitionReportStrategyMessage ]
        \cup [ tag : {SecurityDefinitionReportMessageCode}, body : SecurityDefinitionReportMessage ]
        \cup [ tag : {SecurityDefinitionRejectMessageCode}, body : SecurityDefinitionRejectMessage ]
        \cup [ tag : {SecurityDefinitionRequestMessageCode}, body : SecurityDefinitionRequestMessage ]
        \cup [ tag : {SecurityDefinitionReportProductMessageCode}, body : SecurityDefinitionReportProductMessage ]
        \cup [ tag : {IpRequestMessageCode}, body : IpRequestMessage ]
        \cup [ tag : {IpReportMessageCode}, body : IpReportMessage ]
        \cup [ tag : {TraderLogonRequestMessageCode}, body : TraderLogonRequestMessage ]
        \cup [ tag : {TraderLogonReportMessageCode}, body : TraderLogonReportMessage ]
        \cup [ tag : {TraderLogoutRequestMessageCode}, body : TraderLogoutRequestMessage ]
        \cup [ tag : {TraderLogoutReportMessageCode}, body : TraderLogoutReportMessage ]
        \cup [ tag : {NewOrderRequestMessageCode}, body : NewOrderRequestMessage ]
        \cup [ tag : {CancelReplaceRequestMessageCode}, body : CancelReplaceRequestMessage ]
        \cup [ tag : {CancelRequestMessageCode}, body : CancelRequestMessage ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]
        \cup [ tag : {NewOrderCrossRequestMessageCode}, body : NewOrderCrossRequestMessage ]
        \cup [ tag : {OrderMassCancelRequestMessageCode}, body : OrderMassCancelRequestMessage ]
        \cup [ tag : {MassQuoteRequestMessageCode}, body : MassQuoteRequestMessage ]
        \cup [ tag : {QuoteCancelRequestMessageCode}, body : QuoteCancelRequestMessage ]
        \cup [ tag : {SecurityDefinitionRequestCreateStrategyMessageCode}, body : SecurityDefinitionRequestCreateStrategyMessage ]
        \cup [ tag : {SecurityDefinitionRequestCreateFlexMessageCode}, body : SecurityDefinitionRequestCreateFlexMessage ]
        \cup [ tag : {ExecutionReportNewMessageCode}, body : ExecutionReportNewMessage ]
        \cup [ tag : {ExecutionReportModifyMessageCode}, body : ExecutionReportModifyMessage ]
        \cup [ tag : {ExecutionReportCancelMessageCode}, body : ExecutionReportCancelMessage ]
        \cup [ tag : {ExecutionReportRejectMessageCode}, body : ExecutionReportRejectMessage ]
        \cup [ tag : {ExecutionReportSnapshotMessageCode}, body : ExecutionReportSnapshotMessage ]
        \cup [ tag : {ExecutionReportTradeMessageCode}, body : ExecutionReportTradeMessage ]
        \cup [ tag : {QuoteReportMessageCode}, body : QuoteReportMessage ]
        \cup [ tag : {NewOrderCrossReportMessageCode}, body : NewOrderCrossReportMessage ]
        \cup [ tag : {OrderMassCancelReportMessageCode}, body : OrderMassCancelReportMessage ]
        \cup [ tag : {MassQuoteReportMessageCode}, body : MassQuoteReportMessage ]
        \cup [ tag : {ResendRequestMessageCode}, body : ResendRequestMessage ]
        \cup [ tag : {ResendReportMessageCode}, body : ResendReportMessage ]
        \cup [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]

EncodePayload(message) ==
    CASE message.tag = SimpleOpenFramingHeaderMessageCode -> EncodeSimpleOpenFramingHeaderMessage(message.body)
      [] message.tag = LogonRequestMessageCode -> EncodeLogonRequestMessage(message.body)
      [] message.tag = LogonReportMessageCode -> EncodeLogonReportMessage(message.body)
      [] message.tag = LogoutRequestMessageCode -> EncodeLogoutRequestMessage(message.body)
      [] message.tag = LogoutReportMessageCode -> EncodeLogoutReportMessage(message.body)
      [] message.tag = HeartBeatMessageCode -> << >>
      [] message.tag = ErrorMessageCode -> EncodeErrorMessage(message.body)
      [] message.tag = NewsMessageCode -> EncodeNewsMessage(message.body)
      [] message.tag = SecurityDefinitionReportStrategyMessageCode -> EncodeSecurityDefinitionReportStrategyMessage(message.body)
      [] message.tag = SecurityDefinitionReportMessageCode -> EncodeSecurityDefinitionReportMessage(message.body)
      [] message.tag = SecurityDefinitionRejectMessageCode -> EncodeSecurityDefinitionRejectMessage(message.body)
      [] message.tag = SecurityDefinitionRequestMessageCode -> EncodeSecurityDefinitionRequestMessage(message.body)
      [] message.tag = SecurityDefinitionReportProductMessageCode -> EncodeSecurityDefinitionReportProductMessage(message.body)
      [] message.tag = IpRequestMessageCode -> EncodeIpRequestMessage(message.body)
      [] message.tag = IpReportMessageCode -> EncodeIpReportMessage(message.body)
      [] message.tag = TraderLogonRequestMessageCode -> EncodeTraderLogonRequestMessage(message.body)
      [] message.tag = TraderLogonReportMessageCode -> EncodeTraderLogonReportMessage(message.body)
      [] message.tag = TraderLogoutRequestMessageCode -> EncodeTraderLogoutRequestMessage(message.body)
      [] message.tag = TraderLogoutReportMessageCode -> EncodeTraderLogoutReportMessage(message.body)
      [] message.tag = NewOrderRequestMessageCode -> EncodeNewOrderRequestMessage(message.body)
      [] message.tag = CancelReplaceRequestMessageCode -> EncodeCancelReplaceRequestMessage(message.body)
      [] message.tag = CancelRequestMessageCode -> EncodeCancelRequestMessage(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)
      [] message.tag = NewOrderCrossRequestMessageCode -> EncodeNewOrderCrossRequestMessage(message.body)
      [] message.tag = OrderMassCancelRequestMessageCode -> EncodeOrderMassCancelRequestMessage(message.body)
      [] message.tag = MassQuoteRequestMessageCode -> EncodeMassQuoteRequestMessage(message.body)
      [] message.tag = QuoteCancelRequestMessageCode -> EncodeQuoteCancelRequestMessage(message.body)
      [] message.tag = SecurityDefinitionRequestCreateStrategyMessageCode -> EncodeSecurityDefinitionRequestCreateStrategyMessage(message.body)
      [] message.tag = SecurityDefinitionRequestCreateFlexMessageCode -> EncodeSecurityDefinitionRequestCreateFlexMessage(message.body)
      [] message.tag = ExecutionReportNewMessageCode -> EncodeExecutionReportNewMessage(message.body)
      [] message.tag = ExecutionReportModifyMessageCode -> EncodeExecutionReportModifyMessage(message.body)
      [] message.tag = ExecutionReportCancelMessageCode -> EncodeExecutionReportCancelMessage(message.body)
      [] message.tag = ExecutionReportRejectMessageCode -> EncodeExecutionReportRejectMessage(message.body)
      [] message.tag = ExecutionReportSnapshotMessageCode -> EncodeExecutionReportSnapshotMessage(message.body)
      [] message.tag = ExecutionReportTradeMessageCode -> EncodeExecutionReportTradeMessage(message.body)
      [] message.tag = QuoteReportMessageCode -> EncodeQuoteReportMessage(message.body)
      [] message.tag = NewOrderCrossReportMessageCode -> EncodeNewOrderCrossReportMessage(message.body)
      [] message.tag = OrderMassCancelReportMessageCode -> EncodeOrderMassCancelReportMessage(message.body)
      [] message.tag = MassQuoteReportMessageCode -> EncodeMassQuoteReportMessage(message.body)
      [] message.tag = ResendRequestMessageCode -> EncodeResendRequestMessage(message.body)
      [] message.tag = ResendReportMessageCode -> EncodeResendReportMessage(message.body)
      [] message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SimpleOpenFramingHeaderMessageCode -> DecodeSimpleOpenFramingHeaderMessage(bytes)
              [] tag = LogonRequestMessageCode -> DecodeLogonRequestMessage(bytes)
              [] tag = LogonReportMessageCode -> DecodeLogonReportMessage(bytes)
              [] tag = LogoutRequestMessageCode -> DecodeLogoutRequestMessage(bytes)
              [] tag = LogoutReportMessageCode -> DecodeLogoutReportMessage(bytes)
              [] tag = HeartBeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ErrorMessageCode -> DecodeErrorMessage(bytes)
              [] tag = NewsMessageCode -> DecodeNewsMessage(bytes)
              [] tag = SecurityDefinitionReportStrategyMessageCode -> DecodeSecurityDefinitionReportStrategyMessage(bytes)
              [] tag = SecurityDefinitionReportMessageCode -> DecodeSecurityDefinitionReportMessage(bytes)
              [] tag = SecurityDefinitionRejectMessageCode -> DecodeSecurityDefinitionRejectMessage(bytes)
              [] tag = SecurityDefinitionRequestMessageCode -> DecodeSecurityDefinitionRequestMessage(bytes)
              [] tag = SecurityDefinitionReportProductMessageCode -> DecodeSecurityDefinitionReportProductMessage(bytes)
              [] tag = IpRequestMessageCode -> DecodeIpRequestMessage(bytes)
              [] tag = IpReportMessageCode -> DecodeIpReportMessage(bytes)
              [] tag = TraderLogonRequestMessageCode -> DecodeTraderLogonRequestMessage(bytes)
              [] tag = TraderLogonReportMessageCode -> DecodeTraderLogonReportMessage(bytes)
              [] tag = TraderLogoutRequestMessageCode -> DecodeTraderLogoutRequestMessage(bytes)
              [] tag = TraderLogoutReportMessageCode -> DecodeTraderLogoutReportMessage(bytes)
              [] tag = NewOrderRequestMessageCode -> DecodeNewOrderRequestMessage(bytes)
              [] tag = CancelReplaceRequestMessageCode -> DecodeCancelReplaceRequestMessage(bytes)
              [] tag = CancelRequestMessageCode -> DecodeCancelRequestMessage(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] tag = NewOrderCrossRequestMessageCode -> DecodeNewOrderCrossRequestMessage(bytes)
              [] tag = OrderMassCancelRequestMessageCode -> DecodeOrderMassCancelRequestMessage(bytes)
              [] tag = MassQuoteRequestMessageCode -> DecodeMassQuoteRequestMessage(bytes)
              [] tag = QuoteCancelRequestMessageCode -> DecodeQuoteCancelRequestMessage(bytes)
              [] tag = SecurityDefinitionRequestCreateStrategyMessageCode -> DecodeSecurityDefinitionRequestCreateStrategyMessage(bytes)
              [] tag = SecurityDefinitionRequestCreateFlexMessageCode -> DecodeSecurityDefinitionRequestCreateFlexMessage(bytes)
              [] tag = ExecutionReportNewMessageCode -> DecodeExecutionReportNewMessage(bytes)
              [] tag = ExecutionReportModifyMessageCode -> DecodeExecutionReportModifyMessage(bytes)
              [] tag = ExecutionReportCancelMessageCode -> DecodeExecutionReportCancelMessage(bytes)
              [] tag = ExecutionReportRejectMessageCode -> DecodeExecutionReportRejectMessage(bytes)
              [] tag = ExecutionReportSnapshotMessageCode -> DecodeExecutionReportSnapshotMessage(bytes)
              [] tag = ExecutionReportTradeMessageCode -> DecodeExecutionReportTradeMessage(bytes)
              [] tag = QuoteReportMessageCode -> DecodeQuoteReportMessage(bytes)
              [] tag = NewOrderCrossReportMessageCode -> DecodeNewOrderCrossReportMessage(bytes)
              [] tag = OrderMassCancelReportMessageCode -> DecodeOrderMassCancelReportMessage(bytes)
              [] tag = MassQuoteReportMessageCode -> DecodeMassQuoteReportMessage(bytes)
              [] tag = ResendRequestMessageCode -> DecodeResendRequestMessage(bytes)
              [] tag = ResendReportMessageCode -> DecodeResendReportMessage(bytes)
              [] tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SimpleOpenFramingHeaderMessageCode, body |-> ZeroSimpleOpenFramingHeaderMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SimpleOpenFramingHeaderMessageCode, body |-> one] : one \in CheckedSimpleOpenFramingHeaderMessage }
        \cup { [tag |-> LogonRequestMessageCode, body |-> one] : one \in CheckedLogonRequestMessage }
        \cup { [tag |-> LogonReportMessageCode, body |-> one] : one \in CheckedLogonReportMessage }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> one] : one \in CheckedLogoutRequestMessage }
        \cup { [tag |-> LogoutReportMessageCode, body |-> one] : one \in CheckedLogoutReportMessage }
        \cup { [tag |-> HeartBeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ErrorMessageCode, body |-> one] : one \in CheckedErrorMessage }
        \cup { [tag |-> NewsMessageCode, body |-> one] : one \in CheckedNewsMessage }
        \cup { [tag |-> SecurityDefinitionReportStrategyMessageCode, body |-> one] : one \in CheckedSecurityDefinitionReportStrategyMessage }
        \cup { [tag |-> SecurityDefinitionReportMessageCode, body |-> one] : one \in CheckedSecurityDefinitionReportMessage }
        \cup { [tag |-> SecurityDefinitionRejectMessageCode, body |-> one] : one \in CheckedSecurityDefinitionRejectMessage }
        \cup { [tag |-> SecurityDefinitionRequestMessageCode, body |-> one] : one \in CheckedSecurityDefinitionRequestMessage }
        \cup { [tag |-> SecurityDefinitionReportProductMessageCode, body |-> one] : one \in CheckedSecurityDefinitionReportProductMessage }
        \cup { [tag |-> IpRequestMessageCode, body |-> one] : one \in CheckedIpRequestMessage }
        \cup { [tag |-> IpReportMessageCode, body |-> one] : one \in CheckedIpReportMessage }
        \cup { [tag |-> TraderLogonRequestMessageCode, body |-> one] : one \in CheckedTraderLogonRequestMessage }
        \cup { [tag |-> TraderLogonReportMessageCode, body |-> one] : one \in CheckedTraderLogonReportMessage }
        \cup { [tag |-> TraderLogoutRequestMessageCode, body |-> one] : one \in CheckedTraderLogoutRequestMessage }
        \cup { [tag |-> TraderLogoutReportMessageCode, body |-> one] : one \in CheckedTraderLogoutReportMessage }
        \cup { [tag |-> NewOrderRequestMessageCode, body |-> one] : one \in CheckedNewOrderRequestMessage }
        \cup { [tag |-> CancelReplaceRequestMessageCode, body |-> one] : one \in CheckedCancelReplaceRequestMessage }
        \cup { [tag |-> CancelRequestMessageCode, body |-> one] : one \in CheckedCancelRequestMessage }
        \cup { [tag |-> QuoteRequestMessageCode, body |-> one] : one \in CheckedQuoteRequestMessage }
        \cup { [tag |-> NewOrderCrossRequestMessageCode, body |-> one] : one \in CheckedNewOrderCrossRequestMessage }
        \cup { [tag |-> OrderMassCancelRequestMessageCode, body |-> one] : one \in CheckedOrderMassCancelRequestMessage }
        \cup { [tag |-> MassQuoteRequestMessageCode, body |-> one] : one \in CheckedMassQuoteRequestMessage }
        \cup { [tag |-> QuoteCancelRequestMessageCode, body |-> one] : one \in CheckedQuoteCancelRequestMessage }
        \cup { [tag |-> SecurityDefinitionRequestCreateStrategyMessageCode, body |-> one] : one \in CheckedSecurityDefinitionRequestCreateStrategyMessage }
        \cup { [tag |-> SecurityDefinitionRequestCreateFlexMessageCode, body |-> one] : one \in CheckedSecurityDefinitionRequestCreateFlexMessage }
        \cup { [tag |-> ExecutionReportNewMessageCode, body |-> one] : one \in CheckedExecutionReportNewMessage }
        \cup { [tag |-> ExecutionReportModifyMessageCode, body |-> one] : one \in CheckedExecutionReportModifyMessage }
        \cup { [tag |-> ExecutionReportCancelMessageCode, body |-> one] : one \in CheckedExecutionReportCancelMessage }
        \cup { [tag |-> ExecutionReportRejectMessageCode, body |-> one] : one \in CheckedExecutionReportRejectMessage }
        \cup { [tag |-> ExecutionReportSnapshotMessageCode, body |-> one] : one \in CheckedExecutionReportSnapshotMessage }
        \cup { [tag |-> ExecutionReportTradeMessageCode, body |-> one] : one \in CheckedExecutionReportTradeMessage }
        \cup { [tag |-> QuoteReportMessageCode, body |-> one] : one \in CheckedQuoteReportMessage }
        \cup { [tag |-> NewOrderCrossReportMessageCode, body |-> one] : one \in CheckedNewOrderCrossReportMessage }
        \cup { [tag |-> OrderMassCancelReportMessageCode, body |-> one] : one \in CheckedOrderMassCancelReportMessage }
        \cup { [tag |-> MassQuoteReportMessageCode, body |-> one] : one \in CheckedMassQuoteReportMessage }
        \cup { [tag |-> ResendRequestMessageCode, body |-> one] : one \in CheckedResendRequestMessage }
        \cup { [tag |-> ResendReportMessageCode, body |-> one] : one \in CheckedResendReportMessage }
        \cup { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }

(***************************************************************************)
(* Simple Open Frame, framed by Message Length                             *)
(***************************************************************************)

SimpleOpenFrame ==
    [ encodingType : Sample(2),
      blockLength  : Sample(2),
      schemaId     : Sample(2),
      version      : Sample(2),
      sequenceId   : Sample(4),
      sendTime     : Sample(8),
      headerFlags  : Sample(1),
      payload      : Payload ]

EncodeSimpleOpenFrameBody(message) ==
    message.encodingType
        \o message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o message.sequenceId
        \o message.sendTime
        \o message.headerFlags
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeSimpleOpenFrame(message) ==
    LET body == EncodeSimpleOpenFrameBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeSimpleOpenFrameBody(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET blockLength == ReadBytes(encodingType.rest, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET sequenceId == ReadBytes(version.rest, 4) IN IF ~sequenceId.ok THEN Fail ELSE
    LET sendTime == ReadBytes(sequenceId.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET headerFlags == ReadBytes(sendTime.rest, 1) IN IF ~headerFlags.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, headerFlags.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ encodingType |-> encodingType.value,
         blockLength  |-> blockLength.value,
         schemaId     |-> schemaId.value,
         version      |-> version.value,
         sequenceId   |-> sequenceId.value,
         sendTime     |-> sendTime.value,
         headerFlags  |-> headerFlags.value,
         payload      |-> payload.value ], payload.rest)

DecodeSimpleOpenFrame(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSimpleOpenFrameBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSimpleOpenFrame ==
    [ encodingType |-> [i \in 1 .. 2 |-> 0],
      blockLength  |-> [i \in 1 .. 2 |-> 0],
      schemaId     |-> [i \in 1 .. 2 |-> 0],
      version      |-> [i \in 1 .. 2 |-> 0],
      sequenceId   |-> [i \in 1 .. 4 |-> 0],
      sendTime     |-> [i \in 1 .. 8 |-> 0],
      headerFlags  |-> [i \in 1 .. 1 |-> 0],
      payload      |-> ZeroPayload ]

(* Simple Open Frame at zero, then each field in turn at the values it is checked at *)
CheckedSimpleOpenFrame ==
    { ZeroSimpleOpenFrame }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.encodingType = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.sequenceId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.headerFlags = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOpenFrame EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Simple Open Frame, written one after another *)
RECURSIVE EncodeSimpleOpenFrameList(_)
EncodeSimpleOpenFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSimpleOpenFrame(Head(messages)) \o EncodeSimpleOpenFrameList(Tail(messages))

(* As many Simple Open Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSimpleOpenFrameAll(_)
ReadSimpleOpenFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSimpleOpenFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSimpleOpenFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Simple Open Frame of each kind, for the lists that carry them *)
OneSimpleOpenFrame ==
    { [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SimpleOpenFramingHeaderMessageCode, body |-> ZeroSimpleOpenFramingHeaderMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> LogonRequestMessageCode, body |-> ZeroLogonRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> LogonReportMessageCode, body |-> ZeroLogonReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> LogoutRequestMessageCode, body |-> ZeroLogoutRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> LogoutReportMessageCode, body |-> ZeroLogoutReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> HeartBeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ErrorMessageCode, body |-> ZeroErrorMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NewsMessageCode, body |-> ZeroNewsMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionReportStrategyMessageCode, body |-> ZeroSecurityDefinitionReportStrategyMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionReportMessageCode, body |-> ZeroSecurityDefinitionReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionRejectMessageCode, body |-> ZeroSecurityDefinitionRejectMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionRequestMessageCode, body |-> ZeroSecurityDefinitionRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionReportProductMessageCode, body |-> ZeroSecurityDefinitionReportProductMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> IpRequestMessageCode, body |-> ZeroIpRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> IpReportMessageCode, body |-> ZeroIpReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> TraderLogonRequestMessageCode, body |-> ZeroTraderLogonRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> TraderLogonReportMessageCode, body |-> ZeroTraderLogonReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> TraderLogoutRequestMessageCode, body |-> ZeroTraderLogoutRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> TraderLogoutReportMessageCode, body |-> ZeroTraderLogoutReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NewOrderRequestMessageCode, body |-> ZeroNewOrderRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> CancelReplaceRequestMessageCode, body |-> ZeroCancelReplaceRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> CancelRequestMessageCode, body |-> ZeroCancelRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NewOrderCrossRequestMessageCode, body |-> ZeroNewOrderCrossRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> OrderMassCancelRequestMessageCode, body |-> ZeroOrderMassCancelRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> MassQuoteRequestMessageCode, body |-> ZeroMassQuoteRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> QuoteCancelRequestMessageCode, body |-> ZeroQuoteCancelRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionRequestCreateStrategyMessageCode, body |-> ZeroSecurityDefinitionRequestCreateStrategyMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SecurityDefinitionRequestCreateFlexMessageCode, body |-> ZeroSecurityDefinitionRequestCreateFlexMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportNewMessageCode, body |-> ZeroExecutionReportNewMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportModifyMessageCode, body |-> ZeroExecutionReportModifyMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportCancelMessageCode, body |-> ZeroExecutionReportCancelMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportRejectMessageCode, body |-> ZeroExecutionReportRejectMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportSnapshotMessageCode, body |-> ZeroExecutionReportSnapshotMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ExecutionReportTradeMessageCode, body |-> ZeroExecutionReportTradeMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> QuoteReportMessageCode, body |-> ZeroQuoteReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> NewOrderCrossReportMessageCode, body |-> ZeroNewOrderCrossReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> OrderMassCancelReportMessageCode, body |-> ZeroOrderMassCancelReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> MassQuoteReportMessageCode, body |-> ZeroMassQuoteReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ResendRequestMessageCode, body |-> ZeroResendRequestMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> ResendReportMessageCode, body |-> ZeroResendReportMessage]],
      [ZeroSimpleOpenFrame EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ simpleOpenFrame : SampleLists(OneSimpleOpenFrame) ]

EncodePacket(message) ==
    EncodeSimpleOpenFrameList(message.simpleOpenFrame)

DecodePacket(bytes) ==
    LET simpleOpenFrame == ReadSimpleOpenFrameAll(bytes) IN IF ~simpleOpenFrame.ok THEN Fail ELSE
    Ok([ simpleOpenFrame |-> simpleOpenFrame.value ], simpleOpenFrame.rest)

ZeroPacket ==
    [ simpleOpenFrame |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.simpleOpenFrame = one] : one \in SampleLists(OneSimpleOpenFrame) }

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

(* Every Framing Header decodes back to what was encoded, and leaves nothing over *)
RoundTripFramingHeader ==
    \A message \in CheckedFramingHeader :
        LET read == DecodeFramingHeader(EncodeFramingHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Open Framing Header Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleOpenFramingHeaderMessage ==
    \A message \in CheckedSimpleOpenFramingHeaderMessage :
        LET read == DecodeSimpleOpenFramingHeaderMessage(EncodeSimpleOpenFramingHeaderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequestMessage ==
    \A message \in CheckedLogonRequestMessage :
        LET read == DecodeLogonRequestMessage(EncodeLogonRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonReportMessage ==
    \A message \in CheckedLogonReportMessage :
        LET read == DecodeLogonReportMessage(EncodeLogonReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequestMessage ==
    \A message \in CheckedLogoutRequestMessage :
        LET read == DecodeLogoutRequestMessage(EncodeLogoutRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutReportMessage ==
    \A message \in CheckedLogoutReportMessage :
        LET read == DecodeLogoutReportMessage(EncodeLogoutReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripErrorMessage ==
    \A message \in CheckedErrorMessage :
        LET read == DecodeErrorMessage(EncodeErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text var String 16 Null decodes back to what was encoded, and leaves nothing over *)
RoundTripTextVarString16Null ==
    \A message \in CheckedTextVarString16Null :
        LET read == DecodeTextVarString16Null(EncodeTextVarString16Null(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsMessage ==
    \A message \in CheckedNewsMessage :
        LET read == DecodeNewsMessage(EncodeNewsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Strategy Message no Block Details Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup ==
    \A message \in CheckedSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup :
        LET read == DecodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup(EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Strategy Message no Block Details Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups ==
    \A message \in CheckedSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups :
        LET read == DecodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups(EncodeSecurityDefinitionReportStrategyMessageNoBlockDetailsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Strategy Message no Security Alt I D Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup ==
    \A message \in CheckedSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup :
        LET read == DecodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup(EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Strategy Message no Security Alt I D Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups ==
    \A message \in CheckedSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups :
        LET read == DecodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups(EncodeSecurityDefinitionReportStrategyMessageNoSecurityAltIDGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Strategy Message no Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportStrategyMessageNoLegsGroup ==
    \A message \in CheckedSecurityDefinitionReportStrategyMessageNoLegsGroup :
        LET read == DecodeSecurityDefinitionReportStrategyMessageNoLegsGroup(EncodeSecurityDefinitionReportStrategyMessageNoLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Strategy Message no Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportStrategyMessageNoLegsGroups ==
    \A message \in CheckedSecurityDefinitionReportStrategyMessageNoLegsGroups :
        LET read == DecodeSecurityDefinitionReportStrategyMessageNoLegsGroups(EncodeSecurityDefinitionReportStrategyMessageNoLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Id decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityId ==
    \A message \in CheckedSecurityId :
        LET read == DecodeSecurityId(EncodeSecurityId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Of Measure decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitOfMeasure ==
    \A message \in CheckedUnitOfMeasure :
        LET read == DecodeUnitOfMeasure(EncodeUnitOfMeasure(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Denomination decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceDenomination ==
    \A message \in CheckedPriceDenomination :
        LET read == DecodePriceDenomination(EncodePriceDenomination(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cleared Alias decodes back to what was encoded, and leaves nothing over *)
RoundTripClearedAlias ==
    \A message \in CheckedClearedAlias :
        LET read == DecodeClearedAlias(EncodeClearedAlias(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDesc ==
    \A message \in CheckedSecurityDesc :
        LET read == DecodeSecurityDesc(EncodeSecurityDesc(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Unit decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceUnit ==
    \A message \in CheckedPriceUnit :
        LET read == DecodePriceUnit(EncodePriceUnit(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strip Name decodes back to what was encoded, and leaves nothing over *)
RoundTripStripName ==
    \A message \in CheckedStripName :
        LET read == DecodeStripName(EncodeStripName(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Hub Name decodes back to what was encoded, and leaves nothing over *)
RoundTripHubName ==
    \A message \in CheckedHubName :
        LET read == DecodeHubName(EncodeHubName(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Hub Alias decodes back to what was encoded, and leaves nothing over *)
RoundTripHubAlias ==
    \A message \in CheckedHubAlias :
        LET read == DecodeHubAlias(EncodeHubAlias(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Exchange decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityExchange ==
    \A message \in CheckedSecurityExchange :
        LET read == DecodeSecurityExchange(EncodeSecurityExchange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Security Id decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategySecurityId ==
    \A message \in CheckedStrategySecurityId :
        LET read == DecodeStrategySecurityId(EncodeStrategySecurityId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Physical Code decodes back to what was encoded, and leaves nothing over *)
RoundTripPhysicalCode ==
    \A message \in CheckedPhysicalCode :
        LET read == DecodePhysicalCode(EncodePhysicalCode(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Strategy Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportStrategyMessage ==
    \A message \in CheckedSecurityDefinitionReportStrategyMessage :
        LET read == DecodeSecurityDefinitionReportStrategyMessage(EncodeSecurityDefinitionReportStrategyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Message no Block Details Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportMessageNoBlockDetailsGroup ==
    \A message \in CheckedSecurityDefinitionReportMessageNoBlockDetailsGroup :
        LET read == DecodeSecurityDefinitionReportMessageNoBlockDetailsGroup(EncodeSecurityDefinitionReportMessageNoBlockDetailsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Message no Block Details Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportMessageNoBlockDetailsGroups ==
    \A message \in CheckedSecurityDefinitionReportMessageNoBlockDetailsGroups :
        LET read == DecodeSecurityDefinitionReportMessageNoBlockDetailsGroups(EncodeSecurityDefinitionReportMessageNoBlockDetailsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Message no Security Alt I D Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportMessageNoSecurityAltIDGroup ==
    \A message \in CheckedSecurityDefinitionReportMessageNoSecurityAltIDGroup :
        LET read == DecodeSecurityDefinitionReportMessageNoSecurityAltIDGroup(EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Message no Security Alt I D Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportMessageNoSecurityAltIDGroups ==
    \A message \in CheckedSecurityDefinitionReportMessageNoSecurityAltIDGroups :
        LET read == DecodeSecurityDefinitionReportMessageNoSecurityAltIDGroups(EncodeSecurityDefinitionReportMessageNoSecurityAltIDGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Id decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityId2 ==
    \A message \in CheckedSecurityId2 :
        LET read == DecodeSecurityId2(EncodeSecurityId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Of Measure decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitOfMeasure2 ==
    \A message \in CheckedUnitOfMeasure2 :
        LET read == DecodeUnitOfMeasure2(EncodeUnitOfMeasure2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Denomination decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceDenomination2 ==
    \A message \in CheckedPriceDenomination2 :
        LET read == DecodePriceDenomination2(EncodePriceDenomination2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cleared Alias decodes back to what was encoded, and leaves nothing over *)
RoundTripClearedAlias2 ==
    \A message \in CheckedClearedAlias2 :
        LET read == DecodeClearedAlias2(EncodeClearedAlias2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDesc2 ==
    \A message \in CheckedSecurityDesc2 :
        LET read == DecodeSecurityDesc2(EncodeSecurityDesc2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Unit decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceUnit2 ==
    \A message \in CheckedPriceUnit2 :
        LET read == DecodePriceUnit2(EncodePriceUnit2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strip Name decodes back to what was encoded, and leaves nothing over *)
RoundTripStripName2 ==
    \A message \in CheckedStripName2 :
        LET read == DecodeStripName2(EncodeStripName2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Hub Name decodes back to what was encoded, and leaves nothing over *)
RoundTripHubName2 ==
    \A message \in CheckedHubName2 :
        LET read == DecodeHubName2(EncodeHubName2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Hub Alias decodes back to what was encoded, and leaves nothing over *)
RoundTripHubAlias2 ==
    \A message \in CheckedHubAlias2 :
        LET read == DecodeHubAlias2(EncodeHubAlias2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Exchange decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityExchange2 ==
    \A message \in CheckedSecurityExchange2 :
        LET read == DecodeSecurityExchange2(EncodeSecurityExchange2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Physical Code decodes back to what was encoded, and leaves nothing over *)
RoundTripPhysicalCode2 ==
    \A message \in CheckedPhysicalCode2 :
        LET read == DecodePhysicalCode2(EncodePhysicalCode2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Home Exchange decodes back to what was encoded, and leaves nothing over *)
RoundTripHomeExchange ==
    \A message \in CheckedHomeExchange :
        LET read == DecodeHomeExchange(EncodeHomeExchange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportMessage ==
    \A message \in CheckedSecurityDefinitionReportMessage :
        LET read == DecodeSecurityDefinitionReportMessage(EncodeSecurityDefinitionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRejectMessage ==
    \A message \in CheckedSecurityDefinitionRejectMessage :
        LET read == DecodeSecurityDefinitionRejectMessage(EncodeSecurityDefinitionRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRequestMessage ==
    \A message \in CheckedSecurityDefinitionRequestMessage :
        LET read == DecodeSecurityDefinitionRequestMessage(EncodeSecurityDefinitionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product Name decodes back to what was encoded, and leaves nothing over *)
RoundTripProductName ==
    \A message \in CheckedProductName :
        LET read == DecodeProductName(EncodeProductName(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripProductDesc ==
    \A message \in CheckedProductDesc :
        LET read == DecodeProductDesc(EncodeProductDesc(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product Group decodes back to what was encoded, and leaves nothing over *)
RoundTripProductGroup ==
    \A message \in CheckedProductGroup :
        LET read == DecodeProductGroup(EncodeProductGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Report Product Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionReportProductMessage ==
    \A message \in CheckedSecurityDefinitionReportProductMessage :
        LET read == DecodeSecurityDefinitionReportProductMessage(EncodeSecurityDefinitionReportProductMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every I P Request Message no Users Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIPRequestMessageNoUsersGroup ==
    \A message \in CheckedIPRequestMessageNoUsersGroup :
        LET read == DecodeIPRequestMessageNoUsersGroup(EncodeIPRequestMessageNoUsersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every I P Request Message no Users Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIPRequestMessageNoUsersGroups ==
    \A message \in CheckedIPRequestMessageNoUsersGroups :
        LET read == DecodeIPRequestMessageNoUsersGroups(EncodeIPRequestMessageNoUsersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ip Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIpRequestMessage ==
    \A message \in CheckedIpRequestMessage :
        LET read == DecodeIpRequestMessage(EncodeIpRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every I P Report Message no Users Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIPReportMessageNoUsersGroup ==
    \A message \in CheckedIPReportMessageNoUsersGroup :
        LET read == DecodeIPReportMessageNoUsersGroup(EncodeIPReportMessageNoUsersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every I P Report Message no Users Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIPReportMessageNoUsersGroups ==
    \A message \in CheckedIPReportMessageNoUsersGroups :
        LET read == DecodeIPReportMessageNoUsersGroups(EncodeIPReportMessageNoUsersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ip Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIpReportMessage ==
    \A message \in CheckedIpReportMessage :
        LET read == DecodeIpReportMessage(EncodeIpReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trader Logon Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTraderLogonRequestMessage ==
    \A message \in CheckedTraderLogonRequestMessage :
        LET read == DecodeTraderLogonRequestMessage(EncodeTraderLogonRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trader Logon Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTraderLogonReportMessage ==
    \A message \in CheckedTraderLogonReportMessage :
        LET read == DecodeTraderLogonReportMessage(EncodeTraderLogonReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trader Logout Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTraderLogoutRequestMessage ==
    \A message \in CheckedTraderLogoutRequestMessage :
        LET read == DecodeTraderLogoutRequestMessage(EncodeTraderLogoutRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trader Logout Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTraderLogoutReportMessage ==
    \A message \in CheckedTraderLogoutReportMessage :
        LET read == DecodeTraderLogoutReportMessage(EncodeTraderLogoutReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderRequestMessage ==
    \A message \in CheckedNewOrderRequestMessage :
        LET read == DecodeNewOrderRequestMessage(EncodeNewOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Replace Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelReplaceRequestMessage ==
    \A message \in CheckedCancelReplaceRequestMessage :
        LET read == DecodeCancelReplaceRequestMessage(EncodeCancelReplaceRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRequestMessage ==
    \A message \in CheckedCancelRequestMessage :
        LET read == DecodeCancelRequestMessage(EncodeCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestMessage ==
    \A message \in CheckedQuoteRequestMessage :
        LET read == DecodeQuoteRequestMessage(EncodeQuoteRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Request Message no Sides Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossRequestMessageNoSidesGroup ==
    \A message \in CheckedNewOrderCrossRequestMessageNoSidesGroup :
        LET read == DecodeNewOrderCrossRequestMessageNoSidesGroup(EncodeNewOrderCrossRequestMessageNoSidesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Request Message no Sides Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossRequestMessageNoSidesGroups ==
    \A message \in CheckedNewOrderCrossRequestMessageNoSidesGroups :
        LET read == DecodeNewOrderCrossRequestMessageNoSidesGroups(EncodeNewOrderCrossRequestMessageNoSidesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Request Message no Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossRequestMessageNoLegsGroup ==
    \A message \in CheckedNewOrderCrossRequestMessageNoLegsGroup :
        LET read == DecodeNewOrderCrossRequestMessageNoLegsGroup(EncodeNewOrderCrossRequestMessageNoLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Request Message no Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossRequestMessageNoLegsGroups ==
    \A message \in CheckedNewOrderCrossRequestMessageNoLegsGroups :
        LET read == DecodeNewOrderCrossRequestMessageNoLegsGroups(EncodeNewOrderCrossRequestMessageNoLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossRequestMessage ==
    \A message \in CheckedNewOrderCrossRequestMessage :
        LET read == DecodeNewOrderCrossRequestMessage(EncodeNewOrderCrossRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelRequestMessage ==
    \A message \in CheckedOrderMassCancelRequestMessage :
        LET read == DecodeOrderMassCancelRequestMessage(EncodeOrderMassCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Request Message no Quote Sets Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRequestMessageNoQuoteSetsGroup ==
    \A message \in CheckedMassQuoteRequestMessageNoQuoteSetsGroup :
        LET read == DecodeMassQuoteRequestMessageNoQuoteSetsGroup(EncodeMassQuoteRequestMessageNoQuoteSetsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Request Message no Quote Sets Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRequestMessageNoQuoteSetsGroups ==
    \A message \in CheckedMassQuoteRequestMessageNoQuoteSetsGroups :
        LET read == DecodeMassQuoteRequestMessageNoQuoteSetsGroups(EncodeMassQuoteRequestMessageNoQuoteSetsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRequestMessage ==
    \A message \in CheckedMassQuoteRequestMessage :
        LET read == DecodeMassQuoteRequestMessage(EncodeMassQuoteRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Request Message no Quote Entries Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelRequestMessageNoQuoteEntriesGroup ==
    \A message \in CheckedQuoteCancelRequestMessageNoQuoteEntriesGroup :
        LET read == DecodeQuoteCancelRequestMessageNoQuoteEntriesGroup(EncodeQuoteCancelRequestMessageNoQuoteEntriesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Request Message no Quote Entries Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelRequestMessageNoQuoteEntriesGroups ==
    \A message \in CheckedQuoteCancelRequestMessageNoQuoteEntriesGroups :
        LET read == DecodeQuoteCancelRequestMessageNoQuoteEntriesGroups(EncodeQuoteCancelRequestMessageNoQuoteEntriesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelRequestMessage ==
    \A message \in CheckedQuoteCancelRequestMessage :
        LET read == DecodeQuoteCancelRequestMessage(EncodeQuoteCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Request Create Strategy Message no Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup ==
    \A message \in CheckedSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup :
        LET read == DecodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup(EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Request Create Strategy Message no Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups ==
    \A message \in CheckedSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups :
        LET read == DecodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups(EncodeSecurityDefinitionRequestCreateStrategyMessageNoLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Request Create Strategy Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRequestCreateStrategyMessage ==
    \A message \in CheckedSecurityDefinitionRequestCreateStrategyMessage :
        LET read == DecodeSecurityDefinitionRequestCreateStrategyMessage(EncodeSecurityDefinitionRequestCreateStrategyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Request Create Flex Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRequestCreateFlexMessage ==
    \A message \in CheckedSecurityDefinitionRequestCreateFlexMessage :
        LET read == DecodeSecurityDefinitionRequestCreateFlexMessage(EncodeSecurityDefinitionRequestCreateFlexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exec I D order Exec Id decodes back to what was encoded, and leaves nothing over *)
RoundTripExecIDOrderExecId ==
    \A message \in CheckedExecIDOrderExecId :
        LET read == DecodeExecIDOrderExecId(EncodeExecIDOrderExecId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orig Order Id decodes back to what was encoded, and leaves nothing over *)
RoundTripOrigOrderId ==
    \A message \in CheckedOrigOrderId :
        LET read == DecodeOrigOrderId(EncodeOrigOrderId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report New Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportNewMessage ==
    \A message \in CheckedExecutionReportNewMessage :
        LET read == DecodeExecutionReportNewMessage(EncodeExecutionReportNewMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exec I D order Exec Id decodes back to what was encoded, and leaves nothing over *)
RoundTripExecIDOrderExecId2 ==
    \A message \in CheckedExecIDOrderExecId2 :
        LET read == DecodeExecIDOrderExecId2(EncodeExecIDOrderExecId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orig Order Id decodes back to what was encoded, and leaves nothing over *)
RoundTripOrigOrderId2 ==
    \A message \in CheckedOrigOrderId2 :
        LET read == DecodeOrigOrderId2(EncodeOrigOrderId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportModifyMessage ==
    \A message \in CheckedExecutionReportModifyMessage :
        LET read == DecodeExecutionReportModifyMessage(EncodeExecutionReportModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exec I D order Exec Id decodes back to what was encoded, and leaves nothing over *)
RoundTripExecIDOrderExecId3 ==
    \A message \in CheckedExecIDOrderExecId3 :
        LET read == DecodeExecIDOrderExecId3(EncodeExecIDOrderExecId3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orig Order Id decodes back to what was encoded, and leaves nothing over *)
RoundTripOrigOrderId3 ==
    \A message \in CheckedOrigOrderId3 :
        LET read == DecodeOrigOrderId3(EncodeOrigOrderId3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportCancelMessage ==
    \A message \in CheckedExecutionReportCancelMessage :
        LET read == DecodeExecutionReportCancelMessage(EncodeExecutionReportCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exec I D order Exec Id decodes back to what was encoded, and leaves nothing over *)
RoundTripExecIDOrderExecId4 ==
    \A message \in CheckedExecIDOrderExecId4 :
        LET read == DecodeExecIDOrderExecId4(EncodeExecIDOrderExecId4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orig Order Id decodes back to what was encoded, and leaves nothing over *)
RoundTripOrigOrderId4 ==
    \A message \in CheckedOrigOrderId4 :
        LET read == DecodeOrigOrderId4(EncodeOrigOrderId4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportRejectMessage ==
    \A message \in CheckedExecutionReportRejectMessage :
        LET read == DecodeExecutionReportRejectMessage(EncodeExecutionReportRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exec I D order Exec Id decodes back to what was encoded, and leaves nothing over *)
RoundTripExecIDOrderExecId5 ==
    \A message \in CheckedExecIDOrderExecId5 :
        LET read == DecodeExecIDOrderExecId5(EncodeExecIDOrderExecId5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orig Order Id decodes back to what was encoded, and leaves nothing over *)
RoundTripOrigOrderId5 ==
    \A message \in CheckedOrigOrderId5 :
        LET read == DecodeOrigOrderId5(EncodeOrigOrderId5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportSnapshotMessage ==
    \A message \in CheckedExecutionReportSnapshotMessage :
        LET read == DecodeExecutionReportSnapshotMessage(EncodeExecutionReportSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orig Order Id decodes back to what was encoded, and leaves nothing over *)
RoundTripOrigOrderId6 ==
    \A message \in CheckedOrigOrderId6 :
        LET read == DecodeOrigOrderId6(EncodeOrigOrderId6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportTradeMessage ==
    \A message \in CheckedExecutionReportTradeMessage :
        LET read == DecodeExecutionReportTradeMessage(EncodeExecutionReportTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReportMessage ==
    \A message \in CheckedQuoteReportMessage :
        LET read == DecodeQuoteReportMessage(EncodeQuoteReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCrossReportMessage ==
    \A message \in CheckedNewOrderCrossReportMessage :
        LET read == DecodeNewOrderCrossReportMessage(EncodeNewOrderCrossReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelReportMessage ==
    \A message \in CheckedOrderMassCancelReportMessage :
        LET read == DecodeOrderMassCancelReportMessage(EncodeOrderMassCancelReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Report Message no Quote Sets Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteReportMessageNoQuoteSetsGroup ==
    \A message \in CheckedMassQuoteReportMessageNoQuoteSetsGroup :
        LET read == DecodeMassQuoteReportMessageNoQuoteSetsGroup(EncodeMassQuoteReportMessageNoQuoteSetsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Report Message no Quote Sets Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteReportMessageNoQuoteSetsGroups ==
    \A message \in CheckedMassQuoteReportMessageNoQuoteSetsGroups :
        LET read == DecodeMassQuoteReportMessageNoQuoteSetsGroups(EncodeMassQuoteReportMessageNoQuoteSetsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteReportMessage ==
    \A message \in CheckedMassQuoteReportMessage :
        LET read == DecodeMassQuoteReportMessage(EncodeMassQuoteReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Resend Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResendRequestMessage ==
    \A message \in CheckedResendRequestMessage :
        LET read == DecodeResendRequestMessage(EncodeResendRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Resend Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResendReportMessage ==
    \A message \in CheckedResendReportMessage :
        LET read == DecodeResendReportMessage(EncodeResendReportMessage(message))
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

(* Every Simple Open Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleOpenFrame ==
    \A message \in CheckedSimpleOpenFrame :
        LET read == DecodeSimpleOpenFrame(EncodeSimpleOpenFrame(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesSimpleOpenFrame ==
    \A message \in CheckedSimpleOpenFrame :
        LET bytes == EncodeSimpleOpenFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
