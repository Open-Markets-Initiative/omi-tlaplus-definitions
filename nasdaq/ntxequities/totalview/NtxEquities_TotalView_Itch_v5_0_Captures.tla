------------- MODULE NtxEquities_TotalView_Itch_v5_0_Captures --------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) TX TotalView Itch v5.0 packets, as the bytes they   *)
(* were captured as. Each one decodes, consumes the whole packet, and      *)
(* encodes back to exactly the bytes it was read from.                     *)
(***************************************************************************)
EXTENDS NtxEquities_TotalView_Itch_v5_0

AddOrderMpidAttributionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 2, 158, 0, 0, 31, 26, 207, 11, 192,
       40, 0, 0, 0, 0, 0, 23, 174, 93, 83, 0, 0, 0, 100, 65, 82,
       71, 84, 32, 32, 32, 32, 0, 7, 79, 124, 86, 73, 82, 84 >>

AddOrderMpidAttributionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 18, 43, 0, 0, 31, 26, 207, 133, 36,
       51, 0, 0, 0, 0, 0, 54, 29, 218, 66, 0, 0, 0, 100, 71, 88,
       67, 32, 32, 32, 32, 32, 0, 10, 93, 132, 86, 73, 82, 84 >>

AddOrderMpidAttributionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 36, 3, 0, 0, 31, 26, 207, 160, 139,
       15, 0, 0, 0, 0, 0, 78, 219, 200, 66, 0, 0, 0, 100, 83, 75,
       70, 32, 32, 32, 32, 32, 0, 2, 165, 188, 86, 73, 82, 84 >>

AddOrderMpidAttributionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 9, 134, 0, 0, 31, 26, 207, 204, 30,
       219, 0, 0, 0, 0, 0, 54, 34, 126, 83, 0, 0, 0, 100, 67, 84,
       83, 72, 32, 32, 32, 32, 0, 11, 27, 92, 86, 73, 82, 84 >>

AddOrderMpidAttributionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 17, 64, 0, 0, 31, 26, 207, 217, 206,
       178, 0, 0, 0, 0, 0, 54, 35, 118, 83, 0, 0, 0, 100, 71, 76,
       80, 73, 32, 32, 32, 32, 0, 7, 91, 152, 86, 73, 82, 84 >>

AddOrderNoMpidAttributionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 2, 12, 0, 0, 31, 26, 206, 208, 33,
       39, 0, 0, 0, 0, 0, 23, 171, 165, 66, 0, 0, 1, 44, 65, 77,
       90, 85, 32, 32, 32, 32, 0, 3, 180, 12 >>

AddOrderNoMpidAttributionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 16, 39, 0, 0, 31, 26, 206, 208, 138,
       147, 0, 0, 0, 0, 0, 54, 8, 210, 66, 0, 0, 7, 208, 70, 88,
       67, 32, 32, 32, 32, 32, 0, 11, 7, 112 >>

AddOrderNoMpidAttributionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 13, 188, 0, 0, 31, 26, 206, 208, 248,
       117, 0, 0, 0, 0, 0, 54, 8, 214, 66, 0, 0, 1, 244, 69, 87,
       90, 32, 32, 32, 32, 32, 0, 4, 176, 100 >>

AddOrderNoMpidAttributionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 16, 58, 0, 0, 31, 26, 206, 211, 180,
       230, 0, 0, 0, 0, 0, 54, 8, 246, 83, 0, 0, 7, 208, 70, 88,
       89, 32, 32, 32, 32, 32, 0, 9, 185, 116 >>

AddOrderNoMpidAttributionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 0, 36, 0, 0, 31, 26, 206, 220, 36,
       175, 0, 0, 0, 0, 0, 23, 171, 189, 66, 0, 0, 3, 32, 65, 65,
       88, 74, 32, 32, 32, 32, 0, 9, 189, 92 >>

NonCrossTradeMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 2, 11, 0, 2, 31, 26, 208, 245, 30,
       91, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 1, 65, 77,
       90, 78, 32, 32, 32, 32, 0, 20, 158, 232, 0, 0, 0, 0, 0, 0,
       107, 248 >>

NonCrossTradeMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 2, 11, 0, 6, 31, 26, 208, 245, 30,
       91, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 10, 65, 77,
       90, 78, 32, 32, 32, 32, 0, 20, 160, 20, 0, 0, 0, 0, 0, 0,
       107, 250 >>

NonCrossTradeMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 2, 11, 0, 8, 31, 26, 208, 245, 30,
       91, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 25, 65, 77,
       90, 78, 32, 32, 32, 32, 0, 20, 160, 20, 0, 0, 0, 0, 0, 0,
       107, 251 >>

NonCrossTradeMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 2, 11, 0, 2, 31, 26, 209, 155, 85,
       41, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 1, 65, 77,
       90, 78, 32, 32, 32, 32, 0, 20, 159, 76, 0, 0, 0, 0, 0, 0,
       107, 253 >>

NonCrossTradeMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 37, 32, 0, 2, 31, 26, 213, 21, 68,
       96, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 100, 83, 80,
       88, 83, 32, 32, 32, 32, 0, 2, 52, 226, 0, 0, 0, 0, 0, 0,
       108, 6 >>

OrderCancelMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 4, 227, 0, 0, 31, 26, 207, 75, 33,
       83, 0, 0, 0, 0, 0, 22, 89, 225, 0, 0, 3, 232 >>

OrderCancelMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 39, 237, 0, 0, 31, 26, 207, 101, 204,
       145, 0, 0, 0, 0, 0, 78, 187, 100, 0, 0, 1, 144 >>

OrderCancelMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 40, 47, 0, 0, 31, 26, 210, 16, 21,
       140, 0, 0, 0, 0, 0, 77, 219, 148, 0, 0, 3, 232 >>

OrderCancelMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 23, 115, 0, 0, 31, 26, 212, 43, 96,
       205, 0, 0, 0, 0, 0, 46, 97, 131, 0, 0, 0, 100 >>

OrderCancelMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 34, 231, 0, 0, 31, 26, 212, 109, 164,
       175, 0, 0, 0, 0, 0, 77, 75, 64, 0, 0, 0, 200 >>

OrderDeleteMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 16, 39, 0, 0, 31, 26, 206, 210, 174,
       211, 0, 0, 0, 0, 0, 44, 73, 58 >>

OrderDeleteMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 11, 138, 0, 0, 31, 26, 206, 224, 222,
       54, 0, 0, 0, 0, 0, 54, 9, 54 >>

OrderDeleteMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 37, 177, 0, 0, 31, 26, 206, 227, 64,
       12, 0, 0, 0, 0, 0, 78, 197, 212 >>

OrderDeleteMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 37, 37, 0, 0, 31, 26, 206, 229, 166,
       237, 0, 0, 0, 0, 0, 78, 203, 60 >>

OrderDeleteMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 37, 81, 0, 0, 31, 26, 206, 230, 2,
       203, 0, 0, 0, 0, 0, 78, 186, 196 >>

OrderExecutedMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 30, 85, 0, 2, 31, 26, 206, 235, 134,
       51, 0, 0, 0, 0, 0, 46, 10, 203, 0, 0, 0, 10, 0, 0, 0,
       0, 0, 0, 107, 236 >>

OrderExecutedMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 36, 199, 0, 2, 31, 26, 206, 239, 3,
       64, 0, 0, 0, 0, 0, 77, 104, 0, 0, 0, 0, 200, 0, 0, 0,
       0, 0, 0, 107, 237 >>

OrderExecutedMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 36, 199, 0, 4, 31, 26, 206, 239, 3,
       64, 0, 0, 0, 0, 0, 77, 229, 128, 0, 0, 0, 200, 0, 0, 0,
       0, 0, 0, 107, 238 >>

OrderExecutedMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 36, 199, 0, 6, 31, 26, 206, 239, 3,
       64, 0, 0, 0, 0, 0, 78, 52, 176, 0, 0, 0, 200, 0, 0, 0,
       0, 0, 0, 107, 239 >>

OrderExecutedMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 36, 199, 0, 8, 31, 26, 206, 239, 3,
       64, 0, 0, 0, 0, 0, 78, 140, 128, 0, 0, 0, 100, 0, 0, 0,
       0, 0, 0, 107, 240 >>

OrderExecutedWithPriceMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 29, 137, 0, 2, 31, 27, 24, 21, 165,
       90, 0, 0, 0, 0, 0, 48, 245, 67, 0, 0, 0, 5, 0, 0, 0,
       0, 0, 0, 109, 83, 89, 0, 17, 244, 124 >>

OrderExecutedWithPriceMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 17, 146, 0, 2, 31, 27, 50, 3, 124,
       46, 0, 0, 0, 0, 0, 57, 205, 18, 0, 0, 0, 100, 0, 0, 0,
       0, 0, 0, 109, 191, 89, 0, 19, 190, 76 >>

OrderExecutedWithPriceMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 17, 146, 0, 2, 31, 27, 50, 7, 109,
       192, 0, 0, 0, 0, 0, 57, 205, 30, 0, 0, 0, 74, 0, 0, 0,
       0, 0, 0, 109, 193, 89, 0, 19, 190, 76 >>

OrderExecutedWithPriceMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 17, 146, 0, 2, 31, 27, 50, 8, 52,
       207, 0, 0, 0, 0, 0, 57, 205, 30, 0, 0, 0, 26, 0, 0, 0,
       0, 0, 0, 109, 194, 89, 0, 19, 190, 76 >>

OrderExecutedWithPriceMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 40, 138, 0, 2, 31, 27, 84, 64, 150,
       127, 0, 0, 0, 0, 0, 82, 184, 32, 0, 0, 0, 1, 0, 0, 0,
       0, 0, 0, 110, 65, 89, 0, 2, 50, 128 >>

OrderReplaceMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 16, 50, 0, 0, 31, 26, 206, 207, 61,
       165, 0, 0, 0, 0, 0, 36, 219, 6, 0, 0, 0, 0, 0, 54, 8,
       198, 0, 0, 0, 100, 0, 13, 179, 208 >>

OrderReplaceMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 20, 50, 0, 0, 31, 26, 206, 207, 66,
       231, 0, 0, 0, 0, 0, 37, 0, 50, 0, 0, 0, 0, 0, 54, 8,
       202, 0, 0, 0, 100, 0, 4, 77, 244 >>

OrderReplaceMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 11, 92, 0, 0, 31, 26, 206, 212, 213,
       227, 0, 0, 0, 0, 0, 39, 130, 238, 0, 0, 0, 0, 0, 54, 8,
       254, 0, 0, 0, 100, 0, 8, 95, 192 >>

OrderReplaceMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 35, 140, 0, 0, 31, 26, 206, 213, 17,
       155, 0, 0, 0, 0, 0, 62, 60, 72, 0, 0, 0, 0, 0, 78, 202,
       156, 0, 0, 0, 100, 0, 1, 82, 172 >>

OrderReplaceMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 42, 114, 0, 0, 31, 26, 206, 227, 97,
       145, 0, 0, 0, 0, 0, 61, 253, 56, 0, 0, 0, 0, 0, 78, 203,
       72, 0, 0, 0, 100, 0, 2, 174, 184 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 36, 189, 0, 0, 31, 26, 213, 207, 92,
       215, 83, 79, 80, 65, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 8, 234, 0, 0, 31, 26, 215, 215, 69,
       172, 67, 80, 72, 73, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 9, 149, 0, 0, 31, 26, 216, 44, 188,
       153, 67, 85, 69, 78, 87, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 26, 150, 0, 0, 31, 26, 216, 48, 94,
       104, 77, 83, 71, 77, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 43, 195, 0, 0, 31, 26, 216, 124, 81,
       211, 89, 67, 66, 68, 45, 65, 32, 32, 49 >>

RetailInterestMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 78, 4, 234, 0, 0, 31, 26, 206, 206, 255,
       47, 66, 73, 90, 68, 32, 32, 32, 32, 78 >>

RetailInterestMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 78, 21, 80, 0, 0, 31, 26, 206, 207, 0,
       61, 73, 83, 67, 71, 32, 32, 32, 32, 78 >>

RetailInterestMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 78, 10, 182, 0, 0, 31, 26, 206, 207, 0,
       237, 68, 73, 71, 32, 32, 32, 32, 32, 78 >>

RetailInterestMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 78, 43, 43, 0, 0, 31, 26, 206, 207, 4,
       156, 88, 66, 73, 32, 32, 32, 32, 32, 83 >>

RetailInterestMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 78, 43, 160, 0, 0, 31, 26, 206, 207, 5,
       84, 88, 83, 76, 86, 32, 32, 32, 32, 78 >>

StockTradingActionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 44, 61, 0, 0, 31, 30, 112, 59, 153,
       232, 90, 88, 90, 90, 84, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 44, 56, 0, 0, 31, 30, 154, 138, 107,
       13, 90, 86, 90, 90, 84, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 6, 171, 0, 0, 31, 31, 154, 165, 91,
       253, 67, 65, 77, 76, 32, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 24, 141, 0, 0, 31, 36, 125, 104, 49,
       138, 76, 84, 82, 89, 32, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 9, 74, 0, 0, 31, 40, 249, 201, 157,
       131, 67, 83, 77, 68, 32, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

SystemEventMessageCapture ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 12, 83, 0, 0, 0, 0, 31, 26, 206, 219, 60,
       234, 81 >>

Captures == { AddOrderMpidAttributionMessageCapture1, AddOrderMpidAttributionMessageCapture2, AddOrderMpidAttributionMessageCapture3, AddOrderMpidAttributionMessageCapture4, AddOrderMpidAttributionMessageCapture5, AddOrderNoMpidAttributionMessageCapture1, AddOrderNoMpidAttributionMessageCapture2, AddOrderNoMpidAttributionMessageCapture3, AddOrderNoMpidAttributionMessageCapture4, AddOrderNoMpidAttributionMessageCapture5, NonCrossTradeMessageCapture1, NonCrossTradeMessageCapture2, NonCrossTradeMessageCapture3, NonCrossTradeMessageCapture4, NonCrossTradeMessageCapture5, OrderCancelMessageCapture1, OrderCancelMessageCapture2, OrderCancelMessageCapture3, OrderCancelMessageCapture4, OrderCancelMessageCapture5, OrderDeleteMessageCapture1, OrderDeleteMessageCapture2, OrderDeleteMessageCapture3, OrderDeleteMessageCapture4, OrderDeleteMessageCapture5, OrderExecutedMessageCapture1, OrderExecutedMessageCapture2, OrderExecutedMessageCapture3, OrderExecutedMessageCapture4, OrderExecutedMessageCapture5, OrderExecutedWithPriceMessageCapture1, OrderExecutedWithPriceMessageCapture2, OrderExecutedWithPriceMessageCapture3, OrderExecutedWithPriceMessageCapture4, OrderExecutedWithPriceMessageCapture5, OrderReplaceMessageCapture1, OrderReplaceMessageCapture2, OrderReplaceMessageCapture3, OrderReplaceMessageCapture4, OrderReplaceMessageCapture5, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture1, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture2, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture3, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture4, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture5, RetailInterestMessageCapture1, RetailInterestMessageCapture2, RetailInterestMessageCapture3, RetailInterestMessageCapture4, RetailInterestMessageCapture5, StockTradingActionMessageCapture1, StockTradingActionMessageCapture2, StockTradingActionMessageCapture3, StockTradingActionMessageCapture4, StockTradingActionMessageCapture5, SystemEventMessageCapture }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodePacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodePacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
