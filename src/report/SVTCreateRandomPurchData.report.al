namespace ScriptumVita.CreateRandomSalesData;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
report 85101 "SVT Create Random Purch Data"
{
    Caption = 'SVT Create Random Sales Data';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(PostingDate; PurchPostingDate)
                    {
                        Caption = 'Posting Date';
                        ApplicationArea = All;

                    }
                    field(NoOfLoops; PuchNoOfLoops)
                    {
                        Caption = 'No Of Loops';
                        ApplicationArea = All;

                    }
                }
            }
        }
        trigger OnInit()
        begin
            PuchNoOfLoops := 1;
        end;

    }
    trigger OnInitReport()

    begin
        PurchPostingDate := DMY2Date(01, 01);
    end;

    trigger OnPreReport()
    var
        OrderPostingDate: Date;
        PostingStepInt: Integer;
        PostingStep: Code[10];
        Window: Dialog;
        NextDocNo: Code[10];
        LoopCounter: Integer;
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", '0000', '9999');

        if PurchaseHeader.FindLast() then
            NextDocNo := IncStr(PurchaseHeader."No.");

        Window.Open('Customer #1######### Item #2###########');

        for LoopCounter := 1 to PuchNoOfLoops do begin
            Clear(PurchaseHeader);
            Clear(PurchaseLine);
            Clear(Vendor);

            Vendor.SetRange(Blocked, Vendor.Blocked::" ");

            if Vendor.FindSet() then
                repeat
                    if Item.FindFirst() then
                        Item.Next(Random(100));

                    PostingStepInt := round(Random(300), 1);
                    PostingStep := Format(PostingStepInt) + 'D';
                    OrderPostingDate := CalcDate(PostingStep, PurchPostingDate);

                    PurchaseHeader.Init();
                    PurchaseHeader.SetHideValidationDialog(true);
                    PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
                    PurchaseHeader."No." := NextDocNo;

                    NextDocNo := IncStr(NextDocNo);

                    PurchaseHeader.Insert(true);

                    PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
                    PurchaseHeader.Validate("Posting Date", OrderPostingDate);
                    PurchaseHeader.Validate("Location Code", '');
                    PurchaseHeader.Modify();

                    PurchaseLine.Init();
                    //PurchaseLine.SetHideValidationDialog(true);
                    PurchaseLine."Document Type" := PurchaseHeader."Document Type";
                    PurchaseLine."Document No." := PurchaseHeader."No.";
                    PurchaseLine."Line No." := 10000;
                    PurchaseLine.Insert(true);

                    PurchaseLine.Type := PurchaseLine.Type::Item;
                    PurchaseLine.Validate("Location Code", PurchaseHeader."Location Code");
                    PurchaseLine.Validate("No.", Item."No.");
                    PurchaseLine.Validate(Quantity, Random(10));

                    if PurchaseLine."Unit Cost" = 0 then
                        PurchaseLine.Validate("Unit Cost", Random(100));
                    PurchaseLine.Modify();

                    Window.Update(1, Vendor."No.");
                    Window.Update(2, item."No.");

                    if PostInvoice(PurchaseHeader) then
                        commit();
                until Vendor.next() = 0;
        end;
    end;

    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchPostingDate: Date;
        PuchNoOfLoops: integer;

    [TryFunction]
    local procedure PostInvoice(var inPurchaseHeader: Record "Purchase Header")
    begin
        inPurchaseHeader.Ship := true;
        inPurchaseHeader.Invoice := true;
        Codeunit.Run(80, inPurchaseHeader);
    end;
}