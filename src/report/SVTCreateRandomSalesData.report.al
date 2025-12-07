namespace ScriptumVita.CreateRandomSalesData;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using Microsoft.Sales.Customer;
report 85100 "SVT Create Random Sales Data"
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
                    field(PostingDate; PostingDate)
                    {
                        Caption = 'Posting Date';
                        ApplicationArea = All;

                    }
                    field(NoOfLoops; NoOfLoops)
                    {
                        Caption = 'No Of Loops';
                        ApplicationArea = All;

                    }
                }
            }
        }
        trigger OnInit()
        begin
            NoOfLoops := 1;
        end;

    }
    trigger OnInitReport()

    begin
        PostingDate := DMY2Date(01, 01);
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
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", '0000', '9999');
        if SalesHeader.FindLast() then
            NextDocNo := IncStr(SalesHeader."No.");
        Window.Open('Customer #1######### Item #2###########');
        for LoopCounter := 1 to NoOfLoops do begin
            Clear(SalesHeader);
            Clear(SalesLine);
            Clear(Customer);
            Customer.SetRange(Blocked, Customer.Blocked::" ");
            if Customer.FindSet() then
                repeat
                    if Item.FindFirst() then
                        Item.Next(Random(100));
                    PostingStepInt := round(Random(300), 1);
                    PostingStep := Format(PostingStepInt) + 'D';
                    OrderPostingDate := CalcDate(PostingStep, PostingDate);
                    SalesHeader.Init();
                    SalesHeader.SetHideValidationDialog(true);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
                    SalesHeader."No." := NextDocNo;
                    NextDocNo := IncStr(NextDocNo);
                    SalesHeader.Insert(true);
                    SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
                    SalesHeader.Validate("Posting Date", OrderPostingDate);
                    SalesHeader.Validate("Location Code", '');
                    SalesHeader.Modify();
                    SalesLine.Init();
                    SalesLine.SetHideValidationDialog(true);
                    SalesLine."Document Type" := SalesHeader."Document Type";
                    SalesLine."Document No." := SalesHeader."No.";
                    SalesLine."Line No." := 10000;
                    SalesLine.Insert(true);
                    SalesLine.Type := SalesLine.Type::Item;
                    SalesLine.Validate("Location Code", SalesHeader."Location Code");
                    SalesLine.Validate("No.", Item."No.");
                    SalesLine.Validate(Quantity, Random(10));
                    if SalesLine."Unit Price" = 0 then
                        SalesLine.Validate("Unit Price", Random(100));
                    SalesLine.Modify();
                    Window.Update(1, Customer."No.");
                    Window.Update(2, item."No.");
                    if PostInvoice(SalesHeader) then
                        commit();
                until Customer.next() = 0;
        end;
    end;

    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostingDate: Date;
        NoOfLoops: integer;

    [TryFunction]
    local procedure PostInvoice(var inSalesHeader: Record "Sales Header")
    begin
        inSalesHeader.Ship := true;
        inSalesHeader.Invoice := true;
        Codeunit.Run(80, inSalesHeader);
    end;
}